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
    input logic clk,                        //! тактовый сигнал
    input logic reset,                      //! сброс в значение по умолчанию
    input logic synch,                      //! сигнал для актуализации частоты
    input logic[31:0] freq,                 //! задаваемая частота: Freq[Hz]*(2^32)/(F_clk)
    //
    output logic[15:0] dac_signal,         //! выход данных ЦАП
    output logic[31:0] phase               //! выход фазы сигнала DDS: 2^32 - 360°C
);

//variables
reg[31:0] freq_val = 32'h00000000; //! внутренняя переменная частоты, защелкивающий частоту

dds_slave_core dds_core(
    .freq(freq_val),
    .reset(reset),
    .clk(clk),
    //
    .dac_signal(dac_signal),
    .phase(phase)
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
    .dac_signal(dac_signal),
    .phase(phase)
);

// имитация сигналов
initial begin
    clk = 0;
    synch = 0;
    freq = 32'h0147AEB8;  //1MHz
    reset = 0;
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
    #15;
    i=i+1;
    freq = (i%50)*freq_increment;

    synch = 1;
    #5; 
    synch = 0;
    #190;
end

endmodule
