//phase_adj.sv

//! The Phase Adjusting module with self testbench.


`timescale 1ns/10ps

// Module
module led_processor
#(
    parameter LED_NUM = 4,
    parameter SYSCLK_RATE = 100, 
    parameter BLINK_DURATION_MS = 100, 
    parameter BLINK_PERIOD_MS = 1000 
)
(
    //
    input logic clk,                                //! тактовый сигнал
	input logic reset,                             //! сброс параметров на значение по умолчанию
    input logic [LED_NUM-1:0][7:0] mode,            //! режим работы светодиода
    input logic [LED_NUM-1:0] start,            //! режим работы светодиода
    input logic [LED_NUM-1:0] stop,            //! режим работы светодиода
    //
    output logic [LED_NUM-1:0] led_out            //! состояние светодиода
);

//localparam
localparam ms_clk_cnter = SYSCLK_RATE * 1000;
//variables
int led_num = 0;
logic [LED_NUM-1:0] state 	= {1'h0, 1'h0, 1'h0, 1'h0};   //! макс 21,47 секунды на 200 МГц
int counter[LED_NUM-1:0] 	= '{0, 0, 0, 0};   //! макс 21,47 секунды на 200 МГц
int counter_blink = ms_clk_cnter*BLINK_DURATION_MS;   //! 100 ms
int counter_period = ms_clk_cnter*BLINK_PERIOD_MS;   //! 1 s

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        for (led_num = 0; led_num < LED_NUM; led_num = led_num + 1) begin
            state[led_num] <= 0;
            counter[led_num] <= 0;
            led_out[led_num] <= 0;
        end
        
    end
    else begin
        for (led_num = 0; led_num < LED_NUM; led_num = led_num + 1) begin
            case (mode[led_num])
                0: begin //single 100 ms shot
                    if (start[led_num] == 1 & state[led_num] == 0) begin
                        state[led_num] <= 1;
                        counter[led_num] <= 0;
                    end
                    else if(stop[led_num] == 1 & state[led_num] == 1) begin
                        counter[led_num] <= counter_blink;
                    end
                    //
                    if (state[led_num] == 1) begin
                        counter[led_num] <= counter[led_num] + 1;
                        if (counter[led_num] < counter_blink) begin
                            led_out[led_num] <= 1;
                        end
                        else begin
                            led_out[led_num] <= 1;
                            counter[led_num] <= 0;
                            state[led_num] <= 0;
                        end
                    end
                    else begin 
                        counter[led_num] <= 0;
                        led_out[led_num] <= 0;
                    end
                end
                1: begin //blink 1s/100ms
                    if (start[led_num] == 1 & state[led_num] == 0) begin
                        state[led_num] <= 1;
                        counter[led_num] <= 0;
                    end
                    else if(stop[led_num] == 1 & state[led_num] == 1) begin
                        state[led_num] <= 0;
                        counter[led_num] <= 0;
                    end
                    //
                    if (state[led_num] == 1) begin
                        counter[led_num] <= counter[led_num] + 1;
                        if (counter[led_num] < counter_blink) begin
                            led_out[led_num] <= 1;
                        end
                        else if (counter[led_num] < counter_period) begin
                            led_out[led_num] <= 0;
                        end
                        else begin
                            counter[led_num] <= 0;
                        end
                    end
                    else begin 
                        counter[led_num] <= 0;
                        led_out[led_num] <= 0;
                    end
                end
            endcase
        end
    end
end

endmodule

///***_______testbench_______***///

//! параметры для задания магнитного поля

module led_processor_tb();

`define TICK                    (1_000_000_000/100_000_000)

int i = 0;

logic clk, reset;
// led
logic [3:0][7:0] led_mode   = {8'h0, 8'h0, 8'h0, 8'h1};
logic [3:0] led_start       = {1'h0, 1'h0, 1'h0, 1'h0};
logic [3:0] led_stop        = {1'h0, 1'h0, 1'h0, 1'h0};
logic [3:0] led_out;

led_processor #(.BLINK_DURATION_MS(1), .BLINK_PERIOD_MS(2)) led_processor_0(
    .clk(clk),
	.reset(reset),
    .mode(led_mode),
    .start(led_start),
    .stop(led_stop),
    //
    .led_out(led_out)
);

// имитация сигналов
initial begin
    clk = 0;
    reset = 0;
    //
    $display("Start\n____________");
end

// тактовая частота
always begin
    clk = ~clk; 
    #5;
end

always begin
    #(1000*`TICK);
    reset = 1;
    #(1*`TICK);
    reset = 0;
    #(10000*`TICK);
    //
    led_start = {1'h0, 1'h0, 1'h0, 1'h1};
    #(1*`TICK);
    led_start = {1'h0, 1'h0, 1'h0, 1'h0};
    #(50000*`TICK);
    led_start = {1'h0, 1'h0, 1'h1, 1'h0};
    #(1*`TICK);
    led_start = {1'h0, 1'h0, 1'h0, 1'h0};
    #(1000000*`TICK);
    //
    $display("Finish");
    // $stop;
end

endmodule
