//dds_slave_core.sv

//! The DDS-module with self testbench.
//!
//! Work cyclogramma for 1 MHz frequency (0х0147AEB8):
//! { signal: 
//!    [
//!         ['Input',
//!             { name: "clk",                  wave: 'p......', period: 2},
//!             { name: "reset",                wave: '0.1.0.........' },
//!             { name: "freq[31:0]",           wave: '=.............', data: "0х0147AEB8" },
//!         ],
//!         ['Output',
//!             { name: 'phase[31:0]',          wave: 'x.=.=.=.=.=.=.', data: ["0x0000..", "0x0147..", "0x028F..", "0x03D7..", "0x051E..", "0x0666.."]},
//!             { name: 'dac_signal[15:0]',     wave: 'x.....=.=.=.=.', data: ["0x0", "0x3ED", "0x7D9", "0xBC3"]},
//!             {                               node: '..A.....B.....' },
//!         ]
//!   ],
//!   foot: {tock:-2},
//!   edge: ['A<->B Delay: 2 clk cycles'],
//!   config: { hscale: 1},
//! }
//!

`timescale 1ns/10ps

// Module
module dds_slave_core(
    input logic[31:0] freq,                 //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
    input logic[31:0] freq_add,             //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
    input logic reset,                      //! перезапуск модуля DDS
    input logic clk,                        //! тактовый сигнал модуля DDS
    //
    output logic[15:0] dac_signal,          //! выход данных ЦАП
    output logic[31:0] phase                //! значение фазы в момент запроса значения
);

//variables
logic[31:0] phase_accum = 32'h000;                    //! аккумулятор фазы для DDS
logic[9:0] sin_addr = 10'h000;                        //! адрес выборки значения из памяти периода гармонического сигнала
// lpm_add_sub (las) signals
logic [31:0] las_data_a = 32'h0;
logic [31:0] las_data_b;
logic [31:0] las_result = 32'h0;
//
logic [31:0] dac_signal_mem;
logic [31:0] freq_work;

// ip-modules
lpm_add_sub_32	lpm_add_sub_32_main (
    .dataa ( las_data_a ),
    .datab ( las_data_b ),
    .result ( las_result )
    );

lpm_add_sub_32	lpm_add_sub_32_add (
    .dataa ( freq ),
    .datab ( freq_add ),
    .result ( freq_work )
    );

always_comb begin
    las_data_b = freq_work;
end

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        phase_accum <= 32'H00000000;
        sin_addr <= 10'H000;
        las_data_a <= 0;
        //las_data_b <= 0;
        dac_signal <= 0;
    end
    else begin
        //phase_accum <= phase_accum + freq;
        las_data_a <= las_result;
        //las_data_b <= freq_work;
        phase_accum <= las_result;
        sin_addr <= phase_accum[31:22];
        dac_signal <= dac_signal_mem;
    end
end

assign phase = phase_accum;

// dds mem with sin-period
dds_sin_mem	dds_sin_mem_inst (
	.address ( sin_addr ),
	.clock  ( clk ),
	.q ( dac_signal_mem )
	);
endmodule


///***_______testbench_______***///

module dds_slave_core_tb();

reg clk;
reg reset;
reg [31:0] freq;
reg [31:0] phase;
reg [15:0] dac_signal;

dds_slave_core dds_0(
    .freq(freq),
    .reset(reset),
    .clk(clk),
    //
    .dac_signal(dac_signal),
    .phase(phase)
);

// имитация сигналов
initial begin
    clk = 0;
    reset = 0;
    freq = 32'h0147AEB8;  //1MHz
    //
    #5;
    reset = 1;
    #5;
    reset = 0;
    #50;
    reset = 1;
    #5;
    reset = 0;
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

endmodule
