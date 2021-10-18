//dds_slave.sv

//! The DDS-module with self testbench.
//!
//! Todo: add wavedrom description for main modes of operations.

`timescale 1ns/10ps

// Module
module dds_slave(
    input logic[31:0] freq,                 //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
    input logic reset,                      //! сброс в значение по умолчанию
    input logic clk,                        //! тактовый сигнал
    input logic synch,                      //! сигнал для актуализации частоты
    //
    output logic[15:0] dac_signal          //! выход данных ЦАП
);

//variables
reg[31:0] freq_val = 32'h00000000;

dds_slave_core dds_core(
    .freq(freq_val),
    .reset(reset),
    .clk(clk),
    //
    .dac_signal(dac_signal),
    .phase()  //пока не используется
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

module dds_slave_tb();

integer i = 0;
reg clk;
reg synch, reset;
reg [31:0] freq;
reg [31:0] freq_increment = 32'h0147AEB8;  //1MHz;
reg [31:0] phase;
reg [15:0] dac_signal;

dds_slave dds_0(
    .freq(freq),                 
    .reset(reset),               
    .clk(clk),                   
    .synch(synch),               
    //
    .dac_signal(dac_signal)
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
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

// тактовая частота
always begin
    #5;
    i=i+1;
    freq = (i%50)*freq_increment;

    synch = 1;
    #195; 
    synch = 0;
end

endmodule
