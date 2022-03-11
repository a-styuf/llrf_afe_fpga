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

reg[31:0] f = 32'h00;
reg[31:0] des_ph = 32'h00;
reg[31:0] cur_ph = 32'h00;
reg[31:0] d_t = 32'h00;
reg[31:0] w_t = 32'h00;

reg[63:0] normalizator = 64'h00; //! w_t*w_t - нормировачное значение для формулы подсчета фазы phase_step = j * (delta_phase/w_t*w_t)
reg[31:0] conveer_step= 32'h00, j = 32'h00;  //! номер шага в рабочем режиме
reg[31:0] phase_step = 32'h00;  //!  базовый шаг поф азе
reg[63:0] remain_accumulator = 64'h00;  //! накопитель остатков при делении
logic conveer_flag = 0, conveer_ready = 0;

//variables for phase_shift_calculation-module
logic phsh_start = 1'h1;
logic [31:0] phsh_freq = 32'hFEFE_FEFE;
logic [31:0] phsh_current_phase = 32'hFEFE_FEFE;
logic [31:0] phsh_desired_phase = 32'hFEFE_FEFE;
logic [31:0] phsh_time_from_start = 32'hFEFE_FEFE;
//
logic [31:0] phsh_phase_shift;
logic phsh_ready;
//
logic [31:0] phase_shift;

//variables for IP-blocks
//64-bits devider
reg[63:0] numerator = 64'h00;             //! числитель
reg[63:0] denominator = 64'h00;           //! знаменатель
reg[63:0] quotient = 64'h00;              //! частно
reg[63:0] remain = 64'h00;                //! остаток
reg[7:0] devider_pipeline = 8'h03;       //! pipeline модуля деления

//! переменные для общего использования умножителя
reg[1:0][63:0] mult_a;
reg[1:0][63:0] mult_b;
reg[1:0][127:0] mult_q;

// Others modules
phase_shift_calculation  phase_shift_calculation_0(
    //
    .clk(clk),                               //! тактовый сигнал
    .reset(reset),                           //! сброс всех переменных в значение по умолчанию
    .start(phsh_start),                      //! запуск работы модуля
    .freq(phsh_freq),                        //! рабочая частота сигнала для подстройки фазы
    .current_phase(phsh_current_phase),      //! текущая фаза сигнала
    .desired_phase(phsh_desired_phase),      //! желаемая фаза к окончанию фремени time_from_start
    .time_from_start(phsh_time_from_start),  //! время в тактах clk через которое устанавливается desired_phase
    //
    .phase_shift(phsh_phase_shift),               //! результирующая свдижка фазы (знаковый!)
    .ready(phsh_ready)                       //! 1 - сигнал окончания работы (сбрасываеься в 0 сигралами reset и start)
);

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
        ready <= 0;
        // internal variables
        active = 0;
        step_number = 0;
        normalizator = 0;
        //
        phsh_start <= 0;
        //
        f <= 32'h00;
        des_ph <= 32'h00;
        cur_ph <= 32'h00;
        d_t <= 32'h00;
        w_t <= 32'h00;
    end
    else begin
        if ((start == 1'h1) && (active == 0)) begin
            //переписывание в теневые регистры
            f <= freq;
            des_ph <= desired_phase;
            cur_ph <= current_phase;
            d_t <= delay_time;
            w_t <= work_time;
            //
            active <= 1'h1;
            step_number = 1;
        end
        else if(active == 1) begin
            if (step_number == 1) begin // предподготовка переменных
                //
                phsh_freq <= f;
                phsh_current_phase <= cur_ph;
                phsh_desired_phase <= des_ph;
                phsh_time_from_start <= d_t + w_t;
                phsh_start <= 1;
                //
                step_number <= step_number + 8'h1;
            end
            else if (step_number == 2) begin // цикл подсчета доабвка к фазе
                phsh_start <= 0;
                if(phsh_ready == 1'h1) begin
                    phase_shift <= phsh_phase_shift;
                    //
                    normalizator <= w_t*w_t;
                    //
                    step_number <= step_number + 8'h1;
                end
            end
            else if (step_number == 3) begin // цикл подсчета доабвка к частоте
                //
                if (conveer_ready == 1) begin
                    step_number <= step_number + 8'h1;
                end
            end
            else if (step_number == 4) begin // финиширование
                step_number <= 0;
                active <= 0;
                ready <= 1;
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
        conveer_ready <= 1'h0;
        conveer_state <= 1'h0;
        conveer_step <= 0;
        j <= 0;
        freq_add <= 32'h0;
    end
    else begin
        if((conveer_flag == 0) && (step_number == 3)) begin
            conveer_flag <= 1'h1;
            conveer_state <= 1'h1;
            conveer_ready <= 1'h0;
            freq_add <= 32'h0;
            j <= 0;
        end
        //
        else if (conveer_flag == 1'h1) begin
            conveer_step = conveer_step + 1;
            //определение коэффициента линейного роста, падения
            if (conveer_step < d_t) begin
                j <= 0;
            end
            else if ((conveer_step >= d_t) && (conveer_step < (d_t + {1'h0,w_t[31:1]}))) begin
                j <= j + 1;
            end
            else if ((conveer_step >= (d_t + {1'h0,w_t[31:1]})) && (j > 0)) begin
                j <= j - 1;
            end
            else begin
                j <= 0;
            end
            //
            if (conveer_state == 1) begin // skip delay
                //
                if (conveer_step >= d_t) begin
                    conveer_state <= 2;
                end
            end
            else if (conveer_state == 2) begin // режим до получения первого ответа от делителя с пайплайном
                // входные данные
                numerator <= {j, 2'h0}*phase_shift;
                denominator <= normalizator;
                //
                //
                if (conveer_step >= d_t + devider_pipeline) begin
                    conveer_state <= 3;
                end
            end
            else if (conveer_state == 3) begin // базовый режим
                // входные данные
                numerator <= {j, 2'h0}*phase_shift;
                denominator <= normalizator;
                // выходные данные
                remain_accumulator <= remain_accumulator + remain;
                freq_add <= quotient[31:0];
                //
                if (conveer_step >= w_t + d_t) begin
                        conveer_state <= 4;
                end
            end
            else if (conveer_state == 4) begin // режим ожидания оставшихся одсчетов модулей с pipeline
                //
                // выходные данные
                remain_accumulator = remain_accumulator + remain;
                freq_add = quotient[31:0];
                //
                if (conveer_step >= w_t + d_t + devider_pipeline) begin
                        conveer_state <= 5;
                        conveer_ready <= 1;
                        conveer_flag <= 0;
                end
            end
            else if (conveer_state == 5) begin // финиширование
                freq_add = 32'h0;
                conveer_state <= 0;
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
`define CURRENT_PHASE_INT       32'h4000_0000    // 90°
`define DSIRED_PHASE_INT        32'h0000_0000    // 0°

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
    current_phase <= `CURRENT_PHASE_INT;
    desired_phase <= `DSIRED_PHASE_INT;
    delay_time <= `DELAY_TIME_TICK;
    work_time <= `WORK_TIME_TICK;
    $display("Start");
    #(1*`TICK);
    reset = 1;
    #(1*`TICK);
    reset = 0;
    #(1*`TICK);
    start = 1;
    #(1*`TICK);
    start = 0;
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

// запуск и проверка результатов
always begin
    #(1*`TICK);
    if (ready == 1) begin
        #(1*`TICK);
        $display("Finish");
        $stop;
    end
end

endmodule
