//llrf_afe

`define DEBUG
`define DDS_CLOCK_190M
//`define DDS_CLOCK_200M

import llrf_afe_package::*;

module llrf_afe(
    // ** internal ** //
    // DDS
    output dds_bus int_dds[1:0],
    input logic[3:0] int_dds_fb,
    input logic dds_sync,
    input logic int_dds_clk_in,
    //
    output logic[7:0] int_rio_out,
    input logic[7:0] int_rio_in,
    //
    // DDS PLL
    output logic int_dds_pll_ref_sel, int_dds_pll_sclk, int_dds_pll_sdi, int_dds_pll_cs, int_dds_pll_reset,
    input logic int_dds_pll_sdo,
    input logic int_status_0, int_status_1,
    // MFM
    output logic int_mfm_b_ref, int_mfm_b_p, int_mfm_b_m, 
    output logic int_mfm_a0, int_mfm_a1,
    output logic int_mfm_sdo, int_mfm_sck, int_mfm_busy, int_mfm_cnv,
    // ** external ** //
    // DDS
    output logic[7:0] ext_rio_in,
    input logic[7:0] ext_rio_out,
    // ** system ** //
    // I2C
    input logic i2c_sda, i2c_scl, i2c_alert,
    // UART
    input logic fpga_rx,
    output logic fpga_tx,
    // SPI
    input logic[3:0] spi_mosi,
    output logic[3:0] spi_miso,
    input logic spi_sclk, spi_cs,
    // CLK
    output logic out_clk_100MHz,
    input logic sys_clk, in_clk_100MHz,
    //
    input logic[3:0] reserve_lvds,
    output logic[7:0] reserve_3v3,
    input logic[7:0] reserve_2v5,
	output logic[3:0] led
	//
);

//*** _____________Variables____________________________________ ***//

//
localparam REF_A = 0, REF_B = 1, DEF_REF = REF_B;
`ifdef DDS_CLOCK_200M
    localparam FREQ_10kHz_VAL   = 32'h00003730;
    localparam FREQ_100kHz_VAL  = 32'h00227E1D;
    localparam FREQ_1MHz_VAL    = 32'h0158ED23;
`elsif DDS_CLOCK_190M
    localparam FREQ_10kHz_VAL   = 32'h000346DC;
    localparam FREQ_100kHz_VAL  = 32'h0020C49B;
    localparam FREQ_1MHz_VAL    = 32'h0147AE14;
`endif
localparam PHASE_DEG_VAL = (32'hFFFF_FFFF * 1) / 360;

//variables
int i;
int debug_state = 1;
int debug_cnter = 0;
// dds logic
logic[31:0] dds_freq[3:0];
logic[15:0] dds_data[3:0];
logic[31:0] dds_current_phase[3:0];
logic[31:0] dds_freq_add[3:0];
logic dds_reset = 1'h0;
logic phadj_rest = 1'h0;
logic dds_sync_internal = 1'h0, dds_sync_dbg = 1'h0;
logic[31:0] dds_dbg_cnter;
// jc logic
logic jc_clk, jc_reset, jc_start = 1'h0;
logic jc_active, jc_ready; 
//clock
logic internal_clk_200MHz;
logic internal_clk_100MHz;
logic internal_dds_clock;
logic sys_pll_reset = 1'h0;
//sys_reset
logic sys_reset, dbg_reset = 1'h0;
//startup reset
logic startup_reset = 1'h1;
logic [31:0] startup_counter = 1'h0;

//tmp
reg[31:0] b_field = 32'hFF;              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
reg[31:0] a_coeff = 32'h01;              //! a - коэффициент формулы
reg[31:0] b_coeff = 32'h02;              //! b - коэффициент формулы
reg[31:0] c_coeff = 32'h03;              //! c - коэффициент формулы
reg[7:0] k_coeff = 8'h01;                //! Номер рабочей гармоники ВЧ
reg start = 1'h1;                        //! запуск подсчета
reg b2f_reset = 1'h0;                        //! запуск подсчета

// phase adjust variables
logic ph_adj_start[3:0], ph_adj_ready[3:0];
logic [31:0] ph_adj_desired_phase[3:0];
logic [31:0] ph_adj_delay_time[3:0], ph_adj_work_time[3:0];

//
reg[31:0] freq[3:0], freq_min[3:0], freq_max[3:0];     //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
reg ready;                      				        //! 

// led
logic [3:0][7:0] led_mode   = {8'h0, 8'h0, 8'h0, 8'h1};
logic [3:0] led_start       = {1'h0, 1'h0, 1'h0, 1'h1};
logic [3:0] led_stop        = {1'h0, 1'h0, 1'h0, 1'h0};
logic led_reset;

// external interface
avmm_if #(.AW(12), .DW(32)) avmm_if_0();

//init
logic init_reset = 1'h0;
logic llrf_init = 1'h0, llrf_init_active = 1'h0;
int llrf_init_step = 0, llrf_init_step_max = 8;

//*** _____________Generation_____________ ***//

// Register Interface
reg_interface #(.AW(12), .DW(32)) reg_interface_0 
(
    .reset(sys_reset),                          //! асинхронный сброс всех переменных в значение по умолчанию
    .clk(clk),                              //! тактовый сигнал
    .av_clk(spi_sclk),                      //! тактовый сигнал шины авалон
    // external interface
    .avmm_if_port(avmm_if_0.slave),                
    // interface to internal logic
    .dds0_freq()                //! добавок к частоте
);

// 4 DDS
genvar j;
generate
    for (j=0; j<4; j=j+1) begin: dds_gen
			//создание модулей DDS
        dds_slave dds_inst(
            .clk(internal_dds_clock),                              //! тактовый сигнал
            .reset(dds_reset),                          //! сброс в значение по умолчанию
            .synch(dds_sync_internal),                          //! сигнал для актуализации частоты
            .freq(dds_freq[j]),                         //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
            //
            .ph_adj_start(ph_adj_start[j]),            //! запуск работы модуля
            .desired_phase(ph_adj_desired_phase[j]),       //! необходимая фаза к окончанию работы модуля
            .delay_time(ph_adj_delay_time[j]),             //! время ожидания до начала подстройки фазы
            .work_time(ph_adj_work_time[j]),               //! время подстройки частоты
            .ph_adj_ready(ph_adj_ready[j]),            //! 1 - сигнал окончания работы
            //
            .dac_signal(dds_data[j]),             //! выход данных ЦАП
            .phase(dds_current_phase[j])                        //! выход фазы сигнала DDS: 2^32 - 360°C
        );
    end
endgenerate

b_to_f b_to_f_0(
    .b_field(b_field),                      //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
    .a_coeff(a_coeff),                      //! a - коэффициент формулы
    .b_coeff(b_coeff),                      //! b - коэффициент формулы
    .c_coeff(c_coeff),                      //! c - коэффициент формулы
    .k_coeff(k_coeff),                      //! Номер рабочей гармоники ВЧ
    .reset(b2f_reset),                          //! сброс в значение по умолчанию
    .clk(internal_clk_200MHz),              //! тактовый сигнал
    .start(start),                          //! запуск подсчета
    //
    .freq(),                            //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
    .ready(ready)                           //! сигнал готовностси значения частоты
);

led_processor led_processor_0(
    .clk(sys_clk),
	.reset(led_reset),
    .mode(led_mode),
    .start(led_start),
    .stop(led_stop),
    //
    .led_out(led)
);

// pll - c0 is a based clk, c1 is a 200 MHz clock for DDS-logiс
sys_pll	sys_pll_inst (
	.areset (1'h0),
	.inclk0 (sys_clk),
    //
	.phasecounterselect (1'b0),
	.phasestep (1'b0),
	.phaseupdown (1'b0),
	.phasedone ( ),
    //
	.scanclk ( scanclk_sig ),
	.c0 ( internal_clk_100MHz ),
	.c1 ( internal_clk_200MHz ),
	.locked ( locked_sig )
	);

jitter_cleaner_ctrl #(.REF_A_B_CHOISE(DEF_REF)) jc_ctrl_0 (  //для отладки используем REF_B
    //
    .clk                    (jc_clk),           //! тактовый сигнал
    .reset                  (jc_reset),         //! сброс всех переменных в значение по умолчанию
    .start                  (jc_start),         //! запуск работы модуля
    .active                 (jc_active),        //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
    .ready                  (jc_ready),         //! 1 - сигнал окончания работы
    // spi to AD9524
    .int_dds_pll_reset      (int_dds_pll_reset),
    .int_dds_pll_sclk       (int_dds_pll_sclk),
    .int_dds_pll_sdi        (int_dds_pll_sdi),
    .int_dds_pll_sdo        (int_dds_pll_sdo),
    .int_dds_pll_cs         (int_dds_pll_cs),
    .int_dds_pll_ref_sel    (int_dds_pll_ref_sel),
    .int_status_0           (int_status_0),
    .int_status_1           (int_status_1)
);

//*** ____________Description____________________________________ ***//

initial begin
    for (i = 0; i < 2; i=i+1) begin
        int_dds[i].slp <= 1'h0; //
        int_dds[i].rst <= 1'h1;
        int_dds[i].data_0 <= 14'h0000;
        int_dds[i].data_1 <= 14'h0000;
    end
    //
    for (i = 0; i < 4; i=i+1) begin
        if (i == 0) begin
            freq[i] <= FREQ_1MHz_VAL;
        end
        else if (i == 1) begin
            freq[i] <= FREQ_1MHz_VAL;
        end
        else begin
            freq[i] <= FREQ_1MHz_VAL;
        end
        freq_min[i] <= FREQ_100kHz_VAL;
        freq_max[i] <= 50*FREQ_1MHz_VAL;
    end
    //
    for (i = 0; i < 4; i=i+1) begin
        ph_adj_start[i] = 1'h0; 
        ph_adj_desired_phase[i] = 32'h0;
        ph_adj_delay_time[i] = 32'h0;
        ph_adj_work_time[i] = 32'h0;
    end
end

always_comb begin : CLK_choosing
    //
    internal_dds_clock = int_dds_clk_in;
    
    out_clk_100MHz = internal_clk_100MHz;
    //
    jc_clk = sys_clk;
    jc_reset = startup_reset;
    led_reset = startup_reset;
    b2f_reset = startup_reset;
    dds_reset = startup_reset;
    phadj_rest = startup_reset;
    init_reset = startup_reset;
    sys_reset = startup_reset;
    sys_pll_reset = 1'h0;
    //
    reserve_3v3[0] = int_dds_pll_cs;
    reserve_3v3[2] = int_dds_pll_sclk;
    reserve_3v3[4] = int_dds_pll_sdi;
    reserve_3v3[6] = int_dds_pll_sdo;
    //
    dds_sync_internal = dds_sync | dds_sync_dbg;
end : CLK_choosing

// startup reset
always @(posedge dbg_reset, posedge sys_clk)
begin
    if (dbg_reset == 1) begin
        //startup_reset <= 1'h1;
        //startup_counter <= 32'h0;
    end
    else begin
        if ((startup_reset == 1'h1) & (~(&startup_counter[9:0]))) begin
            startup_counter <= startup_counter + 1;
        end
        else begin
            startup_reset <= 1'h0;
        end
    end
end

// 4 DDS control
always @(posedge internal_dds_clock, posedge init_reset)
begin : DDS_control
    if (init_reset == 1) begin
        for (i = 0; i < 2; i=i+1) begin
            int_dds[i].data_0 <= 14'h0001;
            int_dds[i].data_1 <= 14'h0001;
            int_dds[i].rst <= 1'h1;
            int_dds[i].slp <= 1'h0;
            //
            dds_freq[2*i+0] <= freq_min[2*i+0];
            dds_freq[2*i+1] <= freq_min[2*i+1];
        end
    end
    else begin
        for (i = 0; i < 2; i=i+1) begin
            int_dds[i].rst <= 1'h0;
            int_dds[i].slp <= 1'h1;
            int_dds[i].data_0 <= dds_data[2*i+0][15:2];
            int_dds[i].data_1 <= dds_data[2*i+1][15:2];
            //
            dds_freq[2*i+0] <= freq[2*i+0];
            dds_freq[2*i+1] <= freq[2*i+1];
        end
    end
end : DDS_control

//! модуль инициализации блока
always @(posedge sys_clk, posedge init_reset) begin
    if (init_reset == 1) begin
        llrf_init <= 1'h1;
        llrf_init_step <= 0;
    end
    else begin
        if (llrf_init == 1'h1) begin
            if (llrf_init_step == 0) begin
                if((jc_active == 0) & (jc_start == 0) & (llrf_init_active == 1'h0)) begin
                    jc_start <= 1;
                    llrf_init_active <= 1'h1;
                end
                else if (jc_start == 1) jc_start <= 0;
                else if (jc_ready == 1) begin
                    llrf_init_step <= llrf_init_step + 1;
                    llrf_init_active <= 1'h0;
                end
            end
            else if (llrf_init_step >= llrf_init_step_max) begin
                llrf_init <= 1'h0;
                llrf_init_step <= 0;
            end
            else begin  // пробегаем неиспользованные шаги инициализации
                llrf_init_step <= llrf_init_step + 1;
            end
        end
    end
end

//! dbg-модуль генерации синхронный с sys_clk
always @(posedge sys_clk) begin
    debug_cnter <= debug_cnter + 1;
    //
    dbg_reset <= &debug_cnter[28:0];
    dds_sync_dbg <= &debug_cnter[15:0];
    //
    if (dbg_reset == 1) begin
        led_start[1] <= 1'h1;
    end
    else if (led[1] == 1'h1) begin 
        led_start[1] <= 1'h0;
    end
    //
end

//! dbg-модуль генерации синхронный с 100 МГц от jitter_cleaner
always @(posedge in_clk_100MHz) begin
    dds_dbg_cnter <= dds_dbg_cnter + 1;
    //
    // dds control
    if(&dds_dbg_cnter[11:0]) begin
        for (i = 2; i < 3; i=i+1) begin
            if (freq[i] <= freq_max[i]) begin
                freq[i] <= freq[i] + {16'h0, freq[i][31:16]};
            end
            else begin
                freq[i] <= freq_min[i];
            end
        end
    end
    // phase adjust
    if((&dds_dbg_cnter[27:1]) && (dds_dbg_cnter[0] == 0)) begin
        if (ph_adj_desired_phase[1] == 32'h0) begin
            ph_adj_desired_phase[0] <= 32'h0000_0000;
            ph_adj_desired_phase[1] <= 32'h7FFF_FFFF;
        end
        else begin
            ph_adj_desired_phase[0] <= 0;
            ph_adj_desired_phase[1] <= 0;
        end
        ph_adj_work_time[0] <= 32'h0FFF_FFFF;
        ph_adj_work_time[1] <= 32'h0FFF_FFFF;
    end
    //
    ph_adj_start[0] <= (&dds_dbg_cnter[27:0]);
    ph_adj_start[1] <= (&dds_dbg_cnter[27:0]);
    led_start[2] <= ph_adj_ready[1];
    led_start[3] <= (&dds_dbg_cnter[27:0]);
end

endmodule
