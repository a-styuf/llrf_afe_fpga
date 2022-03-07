//phase_adj.sv

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
//!             { name: "work_time[31:0]",      wave: '=.............', data: "0х0147AEB8" },
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
module phase_adj(
    //
    input logic clk,                        //! тактовый сигнал
    input logic reset,                      //! сброс всех переменных в значение по умолчанию
    input logic start,                      //! запуск работы модуля
    input logic[31:0] freq,                 //! рабочая частота сигнала для подстройки фазы
    input logic[31:0] current_phase,        //! необходимая фаза к окончанию работы модуля
    input logic[31:0] desired_phase,        //! необходимая фаза к окончанию работы модуля
    input logic[31:0] delay_time,           //! время ожидания до начала подстройки фазы
    input logic[31:0] work_time,            //! время работы модуля
    //
    output logic[31:0] freq_add,            //! добавок к частоте
    output logic active,                    //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
    output logic ready                      //! 1 - сигнал окончания работы
);

//variables
integer state = 0, step_number = 0;
integer conveer_state = 0;


reg[31:0] delta_phase = 32'h00;
reg[7:0] process_state = 8'h00;
reg[31:0] d_t = 32'h00;
reg[31:0] w_t = 32'h00;
reg[63:0] normalizator = 64'h00; //! w_t*w_t - нормировачное значение для формулы подсчета фазы phase_step = j * (delta_phase/w_t*w_t)
reg[31:0] j = 32'h00;  //! номер шага в рабочем режиме
reg[31:0] phase_step = 32'h00;  //!  базовый шаг поф азе
reg[63:0] remain_accumulator = 64'h00;  //! накопитель остатков при делении
logic conveer_flag = 0;


//variables for IP-blocks
//64-bits devider
reg[63:0] numerator = 64'h00;             //! числитель
reg[63:0] denominator = 64'h00;           //! знаменатель
reg[63:0] quotient = 64'h00;              //! частно
reg[63:0] remain = 64'h00;                //! остаток
reg[7:0] devider_pipeline = 8'h02;       //! pipeline модуля деления

//! переменные для общего использования умножителя
reg[1:0][63:0] mult_a;
reg[1:0][63:0] mult_b;
reg[1:0][127:0] mult_q;

//Quartus IP-blocks
//! 64-bits divider with 1-clk pipeline
divide_32 divide_32_0 (
	.aclr(1'h0),
	.clken(1'h1),
	.clock(clk),
	.denom(denominator),
	.numer(numerator),
	.quotient(quotient),
	.remain(remain)
);

//! 64-bits multipler with 1-clk pipeline
genvar num;
generate
    for (num=0; num<2; num=num+1) begin: mult_gen
        mult_64 mult_64_0 (
            .clock(clk),
            .dataa(mult_a[num]),
            .datab(mult_b[num]),
            .result(mult_q[num])
        );
    end
endgenerate

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        // output_reset
        state = 0;
        // internal variables
        delta_phase = 32'h00;
        active = 0;
        step_number = 0;
        d_t = 32'h00;
        w_t = 32'h00;
        normalizator = 0;
    end
    else begin
        if ((start == 1'h1) && (active == 0)) begin
            process_state <= 8'h00;
            active <= 1'h1;
            step_number = 0;
        end
        else if(active == 1) begin
            if (process_state == 1) begin // предподготовка переменных
                phase_step <= delta_phase/work_time;
                normalizator <= w_t*w_t;
                process_state <= process_state + 8'h1;
            end
            else if (process_state == 2) begin // цикл подсчета доабвка к частоте
                process_state <= process_state + 8'h1;
            end
            else if (process_state == 3) begin // финиширование
                process_state <= 0;
                active <= 0;
            end
        end
    end
end

//! конвеер подсчета добавка к частоте
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        conveer_state <= 0;
        remain_accumulator = 64'h00;
        conveer_flag <= 1'h0;
        j = 0;
    end
    else begin
        if((active == 1) && (process_state == 2)) begin
            conveer_flag <= 1'h1;
        end
        //
        if (conveer_flag == 1'h1) begin
            j = j + 1;
            if (conveer_state == 1) begin // режим до получения первого ответа от делителя с пайплайном
                // входные данные
                numerator = j*delta_phase;
                denominator = normalizator;
                //
                //
                if (j >= devider_pipeline) begin
                    conveer_state <= 2;
                end
            end
            else if (conveer_state == 2) begin // базовый режим
                // входные данные
                numerator = j*delta_phase;
                denominator = normalizator;
                // выходные данные
                remain_accumulator = remain_accumulator + remain;
                freq_add = quotient[31:0];
                //
                if (j > w_t) begin
                        conveer_state <= 3;
                end
            end
            else if (conveer_state == 3) begin // режим ожидания оставшихся одсчетов модулей с pipeline
                //
                // выходные данные
                remain_accumulator = remain_accumulator + remain;
                freq_add = quotient[31:0];
                //
                if (j > w_t) begin
                        conveer_state <= 0;
                end
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
`define DELAY_TIME_TICK         (5)
`define WORK_TIME_TICK          (100)
//
`define FREQ_INT                32'h0147_AE14   // 1 MHz
`define CURRENT_PHASE_INT       32'4000_0000    // 90°
`define DSIRED_PHASE_INT        32'0000_0000    // 0°

module phase_adj_tb();

reg clk;
reg reset;
reg start;
reg [31:0] freq;
reg [31:0] current_phase;
reg [31:0] desired_phase;
reg [31:0] delay_time;
reg [31:0] work_time;
//
reg [31:0] freq_add;
reg active;
reg ready;

phase_adj phase_adj_0(
    //
    .clk(clk),                          //! тактовый сигнал
    .reset(reset),                      //! сброс всех переменных в значение по умолчанию
    .start(start),                      //! запуск работы модуля
    .freq(freq),                        //! рабочая частота сигнала для подстройки фазы
    .current_phase(current_phase),      //! необходимая фаза к окончанию работы модуля
    .desired_phase(desired_phase),      //! необходимая фаза к окончанию работы модуля
    .delay_time(delay_time),            //! время ожидания до начала подстройки фазы
    .work_time(work_time),              //! время работы модуля
    //
    .freq_add(freq_add),                //! добавок к частоте
    .active(active),                    //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
    .ready(ready)                       //! 1 - сигнал окончания работы
);

// имитация сигналов
initial begin
    clk = 0;
    reset = 0;
    start = 0;
    freq = `FREQ_INT;
    $display("Start");
    #(2*`TICK);
    reset = 1;
    #(1*`TICK);
    reset = 0;
    #(10*`TICK);
    start = 1;
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

// запуск и проверка результатов
always begin
    #5
    if (ready == 1) begin
        #10 $stop;
        $display("Finish");
    end
end

endmodule
