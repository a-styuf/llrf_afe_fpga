//dds_slave.sv

//! The DDS-slave module with self testbench.
//!
//! Work cyclogramma for 1-50 MHz frequency sweep (0х0147AEB8 - 1 MHz):
//! { signal: 
//!    [
//!         ['Input',
//!             { name: "clk",                  wave: 'p.......', period: 2},
//!             { name: "reset",                wave: '0.1.0...........'},
//!             { name: "synch",                wave: '0.....1.0.......', node: "......a........."},
//!             { name: "freq[31:0]",           wave: '=...............', data: "0х0147AEB8" },
//!         ],
//!         ['Output',
//!             { name: 'phase[31:0]',          wave: 'x.=...=.=.=.=.=.', data: ["0x0000", "0x0000", "0x0147", "0x028F", "0x03D7", "0x051E"],   node: "......b........."},
//!             { name: 'dac_signal[15:0]',     wave: 'x.=.........=.=.', data: ["0x0000", "0x0000", "0x03ED", "0x07D9", "0x0BC3"],             node: "............c..."},
//!             {                               node: '......A.....B...' },
//!         ]
//!   ],
//!   foot: {tock:-2},
//!   edge: ['A<->B Delay: 2 clk cycles', 'a~>b', 'b~>c'],
//!   config: { hscale: 1},
//! }
//!

`timescale 1ns/10ps

// Module
module dds_slave(
    //
    input logic clk,                        //! тактовый сигнал
    input logic reset,                      //! сброс в значение по умолчанию
    input logic synch,                      //! сигнал для актуализации частоты
    input logic[31:0] freq,                 //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
    //
    input logic ph_adj_start,               //! запуск работы модуля
    input logic[31:0] desired_phase,        //! необходимая фаза к окончанию работы модуля
    input logic[31:0] delay_time,           //! время ожидания до начала подстройки фазы
    input logic[31:0] work_time,            //! время подстройки частоты
    output logic ph_adj_ready,              //! 1 - сигнал окончания работы
    //
    output logic[15:0] dac_signal,         //! выход данных ЦАП
    output logic[31:0] phase               //! выход фазы сигнала DDS: 2^32 - 360°C
);

//variables
reg[31:0] freq_val = 32'h00000000; //! внутренняя переменная частоты, защелкивающий частоту
//
logic[31:0] dds_current_phase;
logic signed [31:0] dds_freq_add;
logic dds_reset = 1'h0;
logic phadj_rest = 1'h0;
logic phadj_active = 1'h0;

dds_slave_core dds_core(
    .freq(freq_val),
    .freq_add(dds_freq_add),
    .reset(reset),
    .clk(clk),
    //
    .dac_signal(dac_signal),
    .phase(phase)
);

phase_adj phase_adj_inst(
    //
    .clk(clk),                                  //! тактовый сигнал
    .reset(reset),                              //! сброс всех переменных в значение по умолчанию
    .start(ph_adj_start),                       //! запуск работы модуля
    .freq(freq_val),                            //! рабочая частота сигнала для подстройки фазы
    .current_phase(phase),                      //! необходимая фаза к окончанию работы модуля
    .desired_phase(desired_phase),				//! необходимая фаза к окончанию работы модуля
    .delay_time(delay_time),                    //! время ожидания до начала подстройки фазы
    .work_time(work_time),                      //! время работы модуля
    //
    .freq_add(dds_freq_add),                    //! добавок к частоте
    .active(phadj_active),                      //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
    .ready(ph_adj_ready)                        //! 1 - сигнал окончания работы
);

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        freq_val <= 32'h00000000;
    end
    else begin
        if (synch == 1) begin
            freq_val <= freq;
        end
    end
end

endmodule


///***_______testbench_______***///

`define CLK                     (190_000_000)
`define TICK                    (1_000_000_000/190_000_000)

module dds_slave_tb();
//
localparam us_clk_val = (`CLK) / 1000000;
localparam us_clk_tick = us_clk_val/`TICK;
localparam ms_clk_val = (`CLK) / 1000;
localparam ms_clk_tick = ms_clk_val/`TICK;
localparam s_clk_val = (`CLK) / 1;
localparam s_clk_tick = s_clk_val/`TICK;
localparam freq_kHz_val = 32'h53E2;
localparam freq_MHz_val = 32'h147AE14;
localparam phase_deg_val = (32'hFFFF_FFFF * 1) / 360;
localparam delay_tyme_ms = 0;
localparam work_time_ms = 0;
//
integer i = 0;
reg clk;
reg synch, reset;
reg [1:0][31:0] freq;
reg [1:0][15:0] dac_signal;
reg [1:0][31:0] phase;
//
logic [31:0] phase_diff;
//
logic ph_adj_start = 1'h0;
logic ph_adj_ready = 1'h0;
logic [1:0][31:0] desired_phase;
logic [1:0][31:0] delay_time;
logic [1:0][31:0] work_time;

genvar j;
generate
    for (j=0; j<2; j=j+1) begin: dds_gen
        dds_slave dds_inst(
            .clk(clk),                              //! тактовый сигнал
            .reset(reset),                          //! сброс в значение по умолчанию
            .synch(synch),                          //! сигнал для актуализации частоты
            .freq(freq[j]),                         //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
            //
            .ph_adj_start(ph_adj_start),            //! запуск работы модуля
            .desired_phase(desired_phase[j]),       //! необходимая фаза к окончанию работы модуля
            .delay_time(delay_time[j]),             //! время ожидания до начала подстройки фазы
            .work_time(work_time[j]),               //! время подстройки частоты
            .ph_adj_ready(ph_adj_ready),            //! 1 - сигнал окончания работы
            //
            .dac_signal(dac_signal[j]),             //! выход данных ЦАП
            .phase(phase[j])                        //! выход фазы сигнала DDS: 2^32 - 360°C
        );
    end
endgenerate



// имитация сигналов
initial begin
    clk = 0;
    synch = 0;
    freq[0] = freq_MHz_val;
    freq[1] = freq_MHz_val;
    desired_phase[0] = 32'h0;
    desired_phase[1] = 32'h0;
    phase_diff = 32'h0;
    reset = 0;
    #`TICK;
    reset = 1;
    #`TICK;
    reset = 0;
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

// тактовая частота
always begin
    #(1 * `TICK);
    synch = 0;
    #(5 * `TICK);
    synch = 1;
end

// тактовая частота
always begin
    $display("Start\n____________");
    while(1) begin
        #(25 * `TICK);
        desired_phase[0] <= desired_phase[0] + 180*phase_deg_val;
        desired_phase[1] <= 0*phase_deg_val;
        delay_time[0] <= 0;
        delay_time[1] <= 0;
        work_time[0] <= 2000;
        work_time[1] <= 2000;
        #(1*`TICK);
        ph_adj_start <= 1'h1;
        #(1*`TICK);
        ph_adj_start <= 1'h0;
        #(1*`TICK);
        //
        while (ph_adj_ready == 32'h0) begin
            phase_diff <= phase[1] - phase[0];
            #(111*`TICK);
        end
    end
    //
    $display("____________\nFinish");
    $stop;
end

endmodule
