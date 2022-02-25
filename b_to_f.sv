//b_to_f.sv

//! @title F(B) calculator
//! 
//! @brief Calculation of F by using formula: F(b)=k*(a*B)/(sqrt(b+c*B^2))
//!
//! Pipeline: 11 - clock cycles. 
//!
//! Work cyclogramma (B[T]=0.2 NICA-Buster example):
//! { signal: 
//!    [
//!         ['Input',
//!             { name: "clk",                    wave: 'p.......|...' },
//!             { name: "reset",                  wave: '010.....|...' },
//!             { name: "start",                  wave: '0..10...|...' },
//!             { name: "b_field[31:0]",          wave: 'x..=....|x..', data: "67108866" },
//!             { name: "a_coeff[31:0]",          wave: 'x..=....|x..', data: "937546000" },
//!             { name: "b_coeff[31:0]",          wave: 'x..=....|x..', data: "867339" },
//!             { name: "c_coeff[31:0]",          wave: 'x..=....|x..', data: "436224" },
//!             { name: "k_coeff[7:0]",           wave: 'x..=....|x..', data: "1" },
//!         ],
//!         ['Output',
//!             {                                 node: '...A.....B..' },
//!             { name: 'ready',                  wave: 'z0......|1..' },
//!             { name: 'freq[31:0]',             wave: 'x=......|=..', data: ["0", "864614"] },
//!         ]
//!   ],
//!   foot: {tock:-3},
//!   edge: ['A<->B Delay: 110 ns'],
//!   config: { hscale: 1},
//! }
//!
//!

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
reg[63:0] denominator = 64'h00;           //! знаменатель
reg[63:0] quotient = 64'h00;              //! результат деления
reg[127:0] radical = 128'h00;             //! исходные данные для взятия квадратного корня
reg[63:0] sqrt_result = 64'h00;           //! результат взятия квадратного корня

reg[31:0] b_f = 32'h0;
reg[31:0] a_c = 32'h0;
reg[31:0] b_c = 32'h0;
reg[31:0] c_c = 32'h0;
reg[31:0] k_c = 32'h0;

reg[7:0] process_state = 8'h0;                      //! отслеживание конвеера подсчета
reg active = 0;                                     //! состояние работы: 1 - процесс подсчета, 0 - ожидание запуска

//! переменные для общего использования умножителя
reg[1:0][63:0] mult_a;
reg[1:0][63:0] mult_b;
reg[1:0][127:0] mult_q;

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

//! 64-bits multipler with 1-clk pipeline
genvar j;
generate
    for (j=0; j<2; j=j+1) begin: mult_gen
        mult_64 mult_64_0 (
            .clock(clk),
            .dataa(mult_a[j]),
            .datab(mult_b[j]),
            .result(mult_q[j])
        );
    end
endgenerate

//! calculate process
always @(posedge clk, posedge reset)
begin
    if(reset) begin
        numerator <= 64'h00;
        denominator <= 64'h00;
        freq <= 32'h00;
        active <= 1'h0;
        process_state <= 8'h00;
        ready <= 1'h0;
        b_f <= 0;
        a_c <= 0;
        b_c <= 0;
        c_c <= 0;
        k_c <= 0;
        mult_a[0] = 64'h00; mult_b[0] = 64'h00;
        mult_a[1] = 64'h00; mult_b[1] = 64'h00;
    end
    else begin
        if ((start == 1'h1) && (active == 0)) begin
            process_state <= 8'h00;
            active <= 1'h1;
            numerator <= 64'h00;
            denominator <= 64'h00;
            ready <= 1'h0;
            //
            b_f <= b_field;
            a_c <= a_coeff;
            b_c <= b_coeff;
            c_c <= c_coeff;
            k_c <= k_coeff;
            //        
            mult_a[0] = 64'h00; mult_b[0] = 64'h00;
            mult_a[1] = 64'h00; mult_b[1] = 64'h00;
        end
        else if (active == 1) begin
            process_state <= process_state + 8'h1;
            // step 1
            if (process_state == 0) begin
                //"*"
                mult_a[0] <= c_c; 
                mult_b[0] <= 32'h1 << (7+7); 
                //"*"
                mult_a[1] <= b_f; 
                mult_b[1] <= b_f;
                //"/"
                numerator = (a_c << 7);  //128*a
                denominator = 100_000_000;  //100*(10^6)
            end
            else if (process_state == 1) begin
                // pipeline
            end
            else if (process_state == 2) begin
                // pipeline
            end
            // step 2
            else if (process_state == 3) begin
                //"*"
                mult_a[0] <= mult_q[0][63:0];
                mult_b[0] <= mult_q[1][63:0];
                //"*"
                mult_a[1] <= quotient;
                mult_b[1] <= b_f;
            end
            else if (process_state == 4) begin
                // pipeline
            end
            else if (process_state == 5) begin
                // pipeline
            end
            // step 3
            else if (process_state == 6) begin
                //"*"
                mult_a[1] <= mult_q[1];
                mult_b[1] <= k_c;
                //"sqrt"
                radical <= {b_c[31:0], 32'h0000} + mult_q[0][95:32];
            end
            else if (process_state == 7) begin
                // pipeline
            end
            else if (process_state == 8) begin
                // pipeline
            end
            // step 4
            else if (process_state == 9) begin
                //"/"
                numerator <= {mult_q[1], 16'h0000};
                denominator <= sqrt_result;
            end
            else if (process_state == 10) begin
                //
            end
            else if (process_state == 11) begin
                //
            end
            else if (process_state >= 12) begin
                freq <= quotient[31:0];
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
`define B_START_T 0.02
`define B_STEP_T  0.01
`define B_STOP_T  10.0
`define B_START_Q 671088    //~20mT (`B_START_T/`B_QUANT)
`define B_STEP_Q 335544     //~10mT (`B_STEP_T/`B_QUANT)
`define B_STOP_Q 335544320  //~10T (`B_START_T/`B_QUANT)
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
        start =1'h1;
        #5;
        start =1'h0;
        #95;
        b_field = b_field + `B_STEP_Q;
        if (b_field > `B_STOP_Q) begin
            b_field = `B_START_Q;
        end
    end
end

endmodule