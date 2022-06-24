//phase_adj.sv

//! The Phase Adjusting module with self testbench.
//!
//! Work cyclogramma for 1 MHz frequency (0х0147AEB8):
//! { signal: 
//!    [
//!         ['Input',
//!             { name: "clk",                  wave: 'p.........', period: 2},
//!             { name: "reset",                wave: '0.1.0....|.....|....' },
//!             { name: "start",                wave: '0.....1.0|.....|....' },
//!             { name: "freq[31:0]",           wave: 'x.....=..|.....|....', data: "0х0147_AEB8(1MHz)" },
//!             { name: "current_phase[31:0]",  wave: 'x.....=..|.....|....', data: "0х1998_E667(36°)" },
//!             { name: "desired_phase[31:0]",  wave: 'x.....=..|.....|....', data: "0x0000_0000(0°)" },
//!             { name: "delay_time[31:0]",     wave: 'x.....=..|.....|....', data: "0x0000_0002(10ns)" },
//!             { name: "work_time[31:0]",      wave: 'x.....=..|.....|....', data: "0x0000_07D0(10us)" },
//!         ],
//!         ['Output',
//!             { name: 'freq_add[31:0]',       wave: 'x.=......|=.=.=|=.=.', data: ["0x0000", "0x0000", "0x0F19", "0x01E33", "0x0F1A", "0x0000"]},
//!             { name: 'phase_shift[31:0]',    wave: 'x.=......|=....|....', data: ["0x0000", "0xE6671D59(324°)"]},
//!             { name: 'active',               wave: 'x.0.....1|.....|..0.'},
//!             { name: 'ready',                wave: 'x.0......|.....|..1.'},
//!             {                               node: '......A...B......C..' },
//!         ]
//!   ],
//!   foot: {tock:-6},
//!   edge: ['A<->B 10 + delay_time', 'B<->C work_time + 5'],
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
    input logic[31:0] current_phase,        //! фаза сигнала на момент подачи сигнала старт
    input logic[31:0] desired_phase,        //! необходимая фаза к окончанию работы модуля
    input logic[31:0] delay_time,           //! время ожидания до начала подстройки фазы
    input logic[31:0] work_time,            //! время подстройки частоты
    //
    output logic signed [31:0] freq_add,    //! добавок к частоте
    output logic signed [31:0] phase_shift, //! добавок к фазе (информационный, на основе этого параметра считается freq_add)
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
reg signed [71:0] neg_normalizator = 72'h00; //! w_t*w_t - нормировачное значение для формулы подсчета фазы phase_step = j * (delta_phase/w_t*w_t)
reg[31:0] conveer_step= 32'h00, j = 32'h00;  //! номер шага в рабочем режиме
reg[31:0] phase_step = 32'h00;  //!  базовый шаг поф азе
reg signed [71:0] remain_accumulator = 72'h00;  //! накопитель остатков при делении
reg signed [31:0] remain_add = 32'h00;  //! добавок к частоте от накопления остатка
logic conveer_flag = 0, conveer_ready = 0;

//variables for phase_shift_calculation-module
logic phsh_start = 1'h1;
logic [31:0] phsh_freq = 32'hFEFE_FEFE;
logic [31:0] phsh_current_phase = 32'hFEFE_FEFE;
logic [31:0] phsh_desired_phase = 32'hFEFE_FEFE;
logic [31:0] phsh_time_from_start = 32'hFEFE_FEFE;
//
logic signed[31:0] phsh_phase_shift;
logic phsh_ready;
//
logic signed[31:0] phase_shift_int;

//variables for IP-blocks
//64-bits devider
reg signed [63:0] numerator = 64'h00;             //! числитель
reg signed [63:0] denominator = 64'h00;           //! знаменатель
reg signed [63:0] quotient = 64'h00;              //! частно
reg signed [63:0] remain = 64'h00;                //! остаток
reg[7:0] devider_pipeline = 8'h04;       //! pipeline модуля деления

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
divide_32_signed divide_signed_32_0 (
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
        neg_normalizator = 0;
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
            //
            phase_shift <= 32'h0;
            //
            ready <= 0;
        end
        else if(active == 1) begin
            if (step_number == 1) begin // предподготовка переменных
                //
                phsh_freq <= f;
                phsh_current_phase <= cur_ph;
                phsh_desired_phase <= des_ph;
                phsh_time_from_start <= w_t;
                phsh_start <= 1;
                //
                step_number <= step_number + 8'h1;
            end
            else if (step_number == 2) begin // цикл подсчета доабвка к фазе
                phsh_start <= 0;
                if(phsh_ready == 1'h1) begin
                    phase_shift_int <= phsh_phase_shift;
                    //
                    normalizator <= w_t*w_t;
                    neg_normalizator <= -(w_t*w_t);
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
                phase_shift <= phase_shift_int;
                ready <= 1;
            end
        end
    end
end

//! конвеер подсчета добавка к частоте
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        remain_accumulator = 72'h00;
        conveer_flag <= 1'h0;
        conveer_ready <= 1'h0;
        conveer_state <= 1'h0;
        conveer_step <= 0;
        j <= 0;
        freq_add <= 32'h0;
    end
    else if (start == 1'h1) begin
        conveer_step <= 0;
        conveer_ready <= 1'h0;
        freq_add <= 32'h0;
        conveer_flag <= 1'h0;
        conveer_state <= 1'h0;
        remain_accumulator = 72'h00;

    end
    else begin
        if((conveer_flag == 0) && (step_number == 3) && (conveer_ready == 1'h0)) begin
            conveer_flag <= 1'h1;
            //
            if (w_t != 0) begin 
                conveer_state <= 1'h1;
            end
            else begin
                conveer_state <= 1'h5;
            end
            //
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
                freq_add <= 32'h0;
            end
            else if (conveer_state == 2) begin // режим до получения первого ответа от делителя с пайплайном
                // входные данные
                numerator <= {j, 2'h0}*phase_shift_int;
                denominator <= normalizator;
                //
                //
                if (conveer_step >= d_t + devider_pipeline) begin
                    conveer_state <= 3;
                end
                freq_add <= 32'h0;
            end
            else if (conveer_state == 3) begin // базовый режим
                // входные данные
                numerator <= {j, 2'h0}*phase_shift_int;
                denominator <= normalizator;
                //учет остатка: исходим из того, что remain никогда не больше 2^16
                if (remain_accumulator >= {8'h00, normalizator}) begin
                    remain_accumulator <= remain_accumulator + remain - normalizator;
                    remain_add <= 1;
                end
                else if (remain_accumulator <= neg_normalizator) begin
                    remain_accumulator <= remain_accumulator + remain + normalizator;
                    remain_add <= -1;
                end
                else begin
                    remain_accumulator <= remain_accumulator + remain;
                    remain_add <= 0;
                end
                // выходные данные
                freq_add <= quotient[31:0] + remain_add;
                //
                if (conveer_step >= w_t + d_t) begin
                        conveer_state <= 4;
                end
            end
            else if (conveer_state == 4) begin // режим ожидания оставшихся одсчетов модулей с pipeline
                //учет остатка: исходим из того, что remain никогда не больше 2^16
                if (remain_accumulator >= {8'h00, normalizator}) begin
                    remain_accumulator <= remain_accumulator + remain - normalizator;
                    remain_add <= 1;
                end
                else if (remain_accumulator <= neg_normalizator) begin
                    remain_accumulator <= remain_accumulator + remain + normalizator;
                    remain_add <= -1;
                end
                else begin
                    remain_accumulator <= remain_accumulator + remain;
                    remain_add <= 0;
                end
                // выходные данные
                freq_add <= quotient[31:0] + remain_add;
                //
                if (conveer_step >= w_t + d_t + devider_pipeline) begin
                        conveer_state <= 5;
                    end
                end
                else if (conveer_state == 5) begin // финиширование
                    freq_add <= 32'h0;
                    conveer_state <= 0;
                    conveer_ready <= 1;
                    conveer_flag <= 0;
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
`define DELAY_TIME_TICK         (2)
`define WORK_TIME_TICK          (2_000)
//
`define FREQ_INT                32'h0147_AE14       // 1.0 MHz
`define CURRENT_PHASE_INT       32'hFC71_C71C       // 0.0°
`define DSIRED_PHASE_INT        32'hF8E3_8E38       // 0.05°

module phase_adj_tb();
real start_phase_deg = 0;
real future_phase_deg = 0;
real desired_phase_deg = 0;
real phase_addition_deg = 0;
real phase_error_deg = 0;
//
reg clk;
reg reset;
reg start;
reg [31:0] freq;
reg [31:0] current_phase;
reg [31:0] desired_phase;
reg [31:0] delay_time;
reg [31:0] work_time;
reg [63:0] temp_reg;
//
reg signed [31:0] freq_add;
reg active;
reg ready;
//
reg signed [63:0] freq_add_integral = 64'h0000_0000;
//
integer i = 0, j = 0, des_ph=0, curr_ph=0;

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
    reset = 1;
    start = 0;
    freq = `FREQ_INT;
    //
    delay_time = `DELAY_TIME_TICK;
    work_time = `WORK_TIME_TICK;
    //
    current_phase = `CURRENT_PHASE_INT;
    start_phase_deg = ($itor(current_phase[31:16])*360.0)/($itor(2**16));
    desired_phase = `DSIRED_PHASE_INT;
    desired_phase_deg = ($itor(desired_phase[31:16])*360.0)/($itor(2**16));
    //
    $display("Start\n____________");
    #(1*`TICK);
    reset <= 1;
    
    #(1*`TICK);
    reset <= 0;
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

// запуск и проверка результатов
always begin
    #(1*`TICK);
    if (reset == 1'h0) begin
        #(1*`TICK);
        for (i=0; i<10; i++) begin
            des_ph = (16'hFFFF * i)/10;
            desired_phase = des_ph*(16'hFFFF);
            desired_phase_deg = ($itor(desired_phase[31:16])*360.0)/($itor(2**16));
            //
            for (j=0; j<10; j++) begin
                curr_ph = (16'hFFFF * j)/10;
                current_phase = curr_ph*(16'hFFFF);
                start_phase_deg = ($itor(current_phase[31:16])*360.0)/($itor(2**16));
                //
                start <= 1;
                #(1*`TICK);
                freq_add_integral <= 0;
                //
                while ((active == 1) || (start == 1)) begin
                    start <= 0;
                    #(1*`TICK);
                    //
                    if ((active == 1) || (ready == 1))  begin
                        //
                        temp_reg = (current_phase + (freq*work_time));
                        future_phase_deg = ($itor(temp_reg[31:16]) % (2**16)) * (360.0/(2**16));
                        //
                        freq_add_integral = freq_add_integral + freq_add;
                        phase_addition_deg = $itor(freq_add_integral[31:16])*360.0/(2**16) % 360;
                        //
                        if (ready == 1) begin
                            #(1*`TICK);
                            $display("Report (deg): \tstart: %.3f \tdesir: %.3f \treslt: %.3f \terror: %.3f", start_phase_deg, desired_phase_deg, $itor(future_phase_deg + phase_addition_deg) % 360, future_phase_deg + phase_addition_deg - desired_phase_deg);
                            #(1*`TICK);
                            reset <= 1'h1;
                            #(1*`TICK);
                            reset <= 1'h0;
                            #(1*`TICK);
                        end;
                    end
                end
            end
        end
        $display("Finish");
        $stop;
    end
end

endmodule
