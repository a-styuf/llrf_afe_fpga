//llrf_afe

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
    output logic int_status_0, int_status_1,
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
    input logic reserve_lvds[4],
    input logic reserve_3v3[8],
    input logic reserve_2v5[8],
	output logic led[4]
	 //
);

//*** _____________Variables____________________________________ ***//

//variables
int i;
//logic
logic[31:0] dds_freq[3:0];
logic[15:0] dds_data[3:0];
logic[31:0] dds_current_phase[3:0];
logic[31:0] dds_freq_add[3:0];
//clock
logic clk_200MHz;
//reset
logic reset;

//tmp
reg[31:0] b_field = 32'hFF;              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
reg[31:0] a_coeff = 32'h01;              //! a - коэффициент формулы
reg[31:0] b_coeff = 32'h02;              //! b - коэффициент формулы
reg[31:0] c_coeff = 32'h03;              //! c - коэффициент формулы
reg[7:0] k_coeff = 8'h01;                //! Номер рабочей гармоники ВЧ
reg start = 1'h1;                        //! запуск подсчета

//
reg[31:0] freq;                 				//! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
reg ready;                      				//! 

//*** _____________Generation____________________________________ ***//
// 4 DDS
genvar j;
generate
    for (j=0; j<4; j=j+1) begin: dds_gen
			//создание модулей DDS
        dds_slave dds_inst(
            .clk (int_dds_clk_in),
            .reset (reset),
            .synch (1'h1),
            .freq (dds_freq[j]),
            //
            .dac_signal(dds_data[j]),
            .phase(dds_current_phase[j])
        );
		  //создание модулей пдстройки фазы
        phase_adj phase_adj_inst(
            //
            .clk(int_dds_clk_in),               //! тактовый сигнал
            .reset(reset),                      //! сброс всех переменных в значение по умолчанию
            .start(start),                      //! запуск работы модуля
            .freq(freq),                        //! рабочая частота сигнала для подстройки фазы
            .current_phase(dds_current_phase[j]),      //! необходимая фаза к окончанию работы модуля
            .desired_phase(32'h00),					 //! необходимая фаза к окончанию работы модуля
            .delay_time(32'h0A),            //! время ожидания до начала подстройки фазы
            .work_time(32'd1000_0000),              //! время работы модуля
            //
            .freq_add(dds_freq_add[j]),                //! добавок к частоте
            .active(),                    //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
            .ready()                       //! 1 - сигнал окончания работы
        );
    end
endgenerate

b_to_f b_to_f_0(
    .b_field(b_field),              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
    .a_coeff(a_coeff),              //! a - коэффициент формулы
    .b_coeff(b_coeff),              //! b - коэффициент формулы
    .c_coeff(c_coeff),              //! c - коэффициент формулы
    .k_coeff(k_coeff),               //! Номер рабочей гармоники ВЧ
    .reset(reset),                      //! сброс в значение по умолчанию
    .clk(clk_200MHz),                        //! тактовый сигнал
    .start(start),                      //! запуск подсчета
    //
    .freq(freq),                //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
    .ready(ready)                      //! сигнал готовностси значения частоты
);

//*** ____________Description____________________________________ ***//

initial begin
    for (i = 0; i < 2; i=i+1) begin
            int_dds[i].slp <= 1'h0;
            int_dds[i].rst <= 1'h0;
			int_dds[i].data_0 <= 14'h0000;
			int_dds[i].data_1 <= 14'h0000;
        end
end

// 4 DDS control
always @(posedge int_dds_clk_in, posedge reset)
begin
    if (reset == 1) begin
        for (i = 0; i < 2; i=i+1) begin
            int_dds[i].data_0 <= 14'h0000;
            int_dds[i].data_1 <= 14'h0000;
            int_dds[i].slp <= 1'h0;
            int_dds[i].rst <= 1'h0;
            // dds_freq[i] <= 16'HAAAA;
            dds_freq[2*i+0] <= freq;
            dds_freq[2*i+1] <= freq;
        end
    end
    else begin
        for (i = 0; i < 2; i=i+1) begin
            int_dds[i].data_0 <= dds_data[2*i+0][15:2];
            int_dds[i].data_1 <= dds_data[2*i+1][15:2];
        end

    end
end

// pll - c0 is a based clk, c1 is a 200 MHz clock for DDS-logiс
sys_pll	sys_pll_inst (
	.areset (1'b0),
	.inclk0 (sys_clk ),
    //
	.phasecounterselect (1'b0),
	.phasestep (1'b0),
	.phaseupdown (1'b0),
	.phasedone ( ),
    //
	.scanclk ( scanclk_sig ),
	.c0 ( out_clk_100MHz ),
	.c1 ( clk_200MHz ),
	.locked ( locked_sig )
	);

endmodule
