//dds_slave_core.sv

//! The DDS-module with self testbench.
//!
//! Todo: add wavedrom description for main modes of operations.

`timescale 1ns/10ps

// Module
module dds_slave_core(
    input logic[31:0] freq,                 //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
    input logic reset,                      //! перезапуск модуля DDS
    input logic clk,                        //! тактовый сигнал модуля DDS
    //
    output logic[15:0] dac_signal,          //! выход данных ЦАП
    output logic[31:0] phase                //! значение фазы в момент запроса значения
);

//variables
logic[31:0] phase_accum;                    //! аккумулятор фазы для DDS
logic[9:0] sin_addr;                        //! адрес выборки значения из памяти периода гармонического сигнала

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        phase_accum <= 32'H00000000;
        sin_addr <= 10'H000;
        phase <= 32'H00000000;
    end
    else begin
        phase_accum <= phase_accum + freq;
        sin_addr <= phase_accum[31:22];
        phase <= phase_accum;
    end
end

// dds mem with sin-period
dds_sin_mem	dds_sin_mem_inst (
	.address ( sin_addr ),
	.clock  ( clk ),
	.q ( dac_signal )
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
