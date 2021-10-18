//b_to_f.sv

//! @title F(B) calculator
//! 
//! @brief Calculation of F by using formula: F(b)=k*(a*B)/(sqrt(b+c*B^2))
//!
//! Pipeline: XXX. 
//!
//! This is a **Wavedrom** example:
//! { signal: [
//!   { name: "clk",        wave: 'p..........' },
//!   { name: "reset",      wave: '010........' },
//!   { name: "start",      wave: '0..10......' },
//!   { name: "b_field",    wave: 'x..=x......', data: "0x00" },
//!   { name: "a_coeff",    wave: 'x..=x......', data: "0x00" },
//!   { name: "b_coeff",    wave: 'x..=x......', data: "0x00" },
//!   { name: "c_coeff",    wave: 'x..=x......', data: "0x00" },
//!   { name: "k_coeff",    wave: 'x..=x......', data: "0x00" },
//!   {},
//!   { name: 'ready',      wave: '0....1.....' },
//!   { name: 'freq',       wave: 'x....=x....', data: "0x00" },
//!   ],
//!   config: { hscale: 1}
//! }

`timescale 1ns/10ps

///***_______module_______***///
module b_to_f(
    input logic[31:0] b_field,              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
    input logic[31:0] a_coeff,              //! a - коэффициент формулы
    input logic[31:0] b_coeff,              //! b - коэффициент формулы
    input logic[31:0] c_coeff,              //! c - коэффициент формулы
    input logic[7:0] k_coeff,               //! Номер рабочей гармоники ВЧ
    input logic reset,                      //! сброс в значение по умолчанию
    input logic clk,                        //! тактовый сигнал
    input logic start,                      //! запуск подсчета
    //
    output logic[31:0] freq,                //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
    output logic ready                      //! сигнал готовностси значения частоты
);


//! внутренние переменные
reg[63:0] numerator = 64'h00;             //! числитель
reg[31:0] denominator = 32'h00;           //! знаменатель
reg[63:0] quotient = 64'h00;              //! результат деления
reg[63:0] radical = 64'h00;               //! исходные данные для взятия квадратного корня
reg[31:0] sqrt_result = 32'h00;           //! результат взятия квадратного корня
reg[31:0] freq_result = 32'h00;           //! результат взятия квадратного корня

reg[31:0] b_f = 32'h0;
reg[31:0] a_c = 32'h0;
reg[31:0] b_c = 32'h0;
reg[31:0] c_c = 32'h0;
reg[31:0] k_c = 32'h0;

reg[63:0] numerator_coeff = 64'h0;
reg[31:0] b_f_pow_2 = 32'h0;

reg[7:0] process_state = 8'h0;                      //! отслеживание конвеера подсчета
reg active = 0;                                     //! состояние работы: 1 - процесс подсчета, 0 - ожидание запуска

//! 64-bit sqrt with 1-clk pipeline
sqrt_int_64 sqrt_int_64_0 (
	.aclr(1'h0),
	.clk(clk),
	.ena(1'h1),
	.radical(radical),
	.q(sqrt_result),
	.remainder()
);

//! 32-bits divider with 1-clk pipeline
divide_32 divide_32_0 (
	.aclr(1'h0),
	.clken(1'h1),
	.clock(clk),
	.denom(denominator),
	.numer(numerator),
	.quotient(quotient),
	.remain()
);

always @(posedge clk, posedge reset)
begin
    if(reset) begin
        numerator <= 64'h00;
        numerator_coeff <= 64'h00;
        denominator <= 32'h00;
        freq_result <= 32'h00;
        freq <= 32'h00;
        active <= 1'h0;
        process_state <= 8'h00;
        ready <= 1'h0;
    end
    else begin
        if ((start == 1'h1) && (active == 0)) begin
            process_state <= 8'h00;
            active <= 1'h1;
            numerator <= 64'h00;
            numerator_coeff <= 64'h00;
            freq_result <= 32'h00;
            denominator <= 32'h00;
            ready <= 1'h0;
            //
            b_f <= b_field;
            a_c <= a_coeff;
            b_c <= b_coeff;
            c_c <= c_coeff;
            k_c <= k_coeff;
        end
        else if (active == 1) begin
            process_state = process_state + 8'h1;
            if (process_state == 0) begin
                numerator_coeff <= 64'hFF; //k_c*a_c;
                b_f_pow_2 <= b_f*b_f;
            end
            else if (process_state == 1) begin
                numerator <= numerator_coeff*b_f;
                radical <= c_c*b_f_pow_2;
            end
            else if (process_state == 2) begin
                radical <= b_c + radical;
            end
            else if (process_state == 5) begin
                denominator <= sqrt_result;
            end
            else if (process_state == 8) begin
                freq_result <= quotient[62:32];
            end
            else if (process_state >= 9) begin
                freq <= freq_result;
                ready <= 1'h1;
                active <= 0;
                process_state <= 8'h00;
            end
            else begin
                //
            end
        end 
    end
end

endmodule


///***_______testbench_______***///

//! параметры для задания магнитного поля
`define B_QUANT (128/(4294967295))
`define B_START_T 0.01
`define B_STEP_T  0.01
`define B_START_Q 335544    //~10mT (`B_START_T/`B_QUANT)
`define B_STEP_Q 335544     //~10mT (`B_STEP_T/`B_QUANT)
//! коэффициенты пересчета для Бустера NICA
`define A (937546000)  
`define B (867339)
`define C (436224)
`define K (1)

module b_to_f_tb();

//testbench defines
//
integer i=0;

reg[31:0] b_field;              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
reg[31:0] a_coeff;              //! a - коэффициент формулы
reg[31:0] b_coeff;              //! b - коэффициент формулы
reg[31:0] c_coeff;              //! c - коэффициент формулы
reg[7:0] k_coeff;               //! Номер рабочей гармоники ВЧ
reg reset;                      //! сброс в значение по умолчанию
reg clk;                        //! тактовый сигнал
reg start;                      //! запуск подсчета
//
reg[31:0] freq;                 //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
reg ready;                      //! 

b_to_f b_to_f_0(
    .b_field(b_field),              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
    .a_coeff(a_coeff),              //! a - коэффициент формулы
    .b_coeff(b_coeff),              //! b - коэффициент формулы
    .c_coeff(c_coeff),              //! c - коэффициент формулы
    .k_coeff(k_coeff),               //! Номер рабочей гармоники ВЧ
    .reset(reset),                      //! сброс в значение по умолчанию
    .clk(clk),                        //! тактовый сигнал
    .start(start),                      //! запуск подсчета
    //
    .freq(freq),                //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
    .ready(ready)                      //! сигнал готовностси значения частоты
);



// имитация сигналов
initial begin
    b_field = `B_START_Q;
    a_coeff = `A;
    b_coeff = `B;
    c_coeff = `C;
    k_coeff = `K;
    start = 0;
    reset = 0;
    clk = 0;
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

// подстановка значений магнитного поля
always begin
    #50;
    for(i=0; i<1000; i=i+1) begin
        b_field = b_field + `B_STEP_Q;
        start =1'h1;
        #5;
        start =1'h0;
        #95;
    end
end

endmodule