//phase_shift_calculation.sv

//! The Phase Adjusting module with self testbench.
//!
//! Work cyclogramma for 1 MHz frequency (0х0147AEB8):
//! { signal: 
//!    [
//!         ['Input',
//!             { name: "clk",                  wave: 'p......', period: 2},
//!             { name: "reset",                wave: '0.1.0.........' },
//!             { name: "start",                wave: '0.....1.0.....' },
//!             { name: "freq[31:0]",           wave: '=.............', data: "0х0147AEB8" },
//!             { name: "current_phase[31:0]",  wave: '=.............', data: "0х0147AEB8" },
//!             { name: "desired_phase[31:0]",  wave: '=.............', data: "0х0147AEB8" },
//!             { name: "time_from_start[31:0]",wave: '=.............', data: "0х0147AEB8" },
//!         ],
//!         ['Output',
//!             { name: "ready",                wave: '0.1.0.........' },
//!             { name: 'phase_shift[31:0]',    wave: 'x.=.=.=.=.=.=.', data: ["0x0000..", "0x0147..", "0x028F..", "0x03D7..", "0x051E..", "0x0666.."]}
//!         ]
//!   ],
//!   foot: {tock:-2},
//!   edge: ['A<->B Delay: 2 clk cycles'],
//!   config: { hscale: 1},
//! }
//!

`timescale 1ns/10ps

// Module
module phase_shift_calculation (
    //
    input logic clk,                        //! тактовый сигнал
    input logic reset,                      //! сброс всех переменных в значение по умолчанию
    input logic start,                      //! запуск работы модуля
    input logic[31:0] freq,                 //! рабочая частота сигнала для подстройки фазы
    input logic[31:0] current_phase,        //! текущая фаза сигнала
    input logic[31:0] desired_phase,        //! желаемая фаза к окончанию фремени time_from_start
    input logic[31:0] time_from_start,      //! время в тактах clk через которое устанавливается desired_phase
    //
    output logic[31:0] phase_shift,         //! результирующая свдижка фазы
    output logic ready                      //! 1 - сигнал окончания работы (сбрасываеься в 0 сигралами reset и start)
);

//variables
integer state = 0, step_number = 0;
integer conveer_state = 0;


logic[63:0] future_phase = 0;
logic[63:0] phase_increase = 0;


//variables for IP-blocks

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        ready <= 1'h0;
        future_phase <= 32'h0;
        phase_shift <= 32'h0;
        state <= 0;
        step_number <= 0;
    end
    else begin
        if ((start == 1'h1) && (state == 0)) begin
            ready <= 1'h0;
            future_phase <= 32'h0;
            phase_shift <= 32'h0;
            //
            state <= 1;
            step_number <= 0;
        end
        else if(state == 1) begin
            step_number = step_number + 1;
            if (step_number == 1) begin
                phase_increase <= freq * time_from_start;
            end
            else if (step_number == 2) begin // цикл подсчета доабвка к частоте
                future_phase <= current_phase + phase_increase[31:0];
            end
            else if (step_number == 3) begin // финиширование
                phase_shift <= desired_phase - future_phase[31:0];
				//
                state <= 0;
                ready <= 1'h1;
            end
        end
    end
end

endmodule

///***_______testbench_______***///

//! параметры для задания магнитного поля
`define CLK                     (200_000_000)
`define TICK                    (1_000_000_000/200_000_000)
`define FREQ                    (1_000_000)
`define TIME_FROM_START_TICK    (200)
//
`define FREQ_INT                32'h0147_AE14   // 1 MHz
`define CURRENT_PHASE_INT       32'hC000_0000    // 270°
`define DESIRED_PHASE_INT       32'h0000_0000    // 0°

module phase_shift_calculation_tb();

reg clk;
reg reset;
reg start;
reg [31:0] freq;
reg [31:0] current_phase;
reg [31:0] desired_phase;
reg [31:0] time_from_start;
//
reg [31:0] phase_shift;
reg ready;

integer i = 0, phase=0;

// Module
phase_shift_calculation phase_sh_calc_0(
    //
    .clk(clk),                          //! тактовый сигнал
    .reset(reset),                      //! сброс всех переменных в значение по умолчанию
    .start(start),                      //! запуск работы модуля
    .freq(freq),                        //! рабочая частота сигнала для подстройки фазы
    .current_phase(current_phase),      //! текущая фаза сигнала
    .desired_phase(desired_phase),      //! желаемая фаза к окончанию фремени time_from_start
    .time_from_start(time_from_start),  //! время в тактах clk через которое устанавливается desired_phase
    //
    .phase_shift(phase_shift),          //! результирующая свдижка фазы
    .ready(ready)                       //! 1 - сигнал окончания работы (сбрасываеься в 0 сигралами reset и start)
);

// имитация сигналов
initial begin
    clk = 0;
    reset = 0;
    start = 0;
    freq = `FREQ_INT;
    current_phase = `CURRENT_PHASE_INT;
    time_from_start = `TIME_FROM_START_TICK;
    $display("Start");
    #(2*`TICK);
    reset = 1;
    #(1*`TICK);
    reset = 0;
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

// запуск и проверка результатов
always begin
    #(4*`TICK)
    for (i=0; i<12; i=i+1) begin
        phase = ((32'hFFFF_FFFF)/12);
        desired_phase = phase*i;
        #(2*`TICK);
        start = 1;
        #(1*`TICK);
        start = 0;
        #(5*`TICK);
        $display("%d: des_ph: 0x%08X ph_shift: 0x%08X", i, desired_phase, phase_shift);
    end
    if (ready == 1) begin
        $display("Finish");
        $stop;
    end
end

endmodule
