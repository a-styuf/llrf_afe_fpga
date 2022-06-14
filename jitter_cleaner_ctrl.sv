//jitter_cleaner_ctrl.sv

//! AD9524 jitter cleaner ctrl module
//!
//! Work cyclogramma for 1 MHz frequency (0х0147AEB8):
//! { signal: 
//! }
//!

`timescale 1ns/10ps

// Module
module jitter_cleaner_ctrl
#( 
    parameter CMD_NUMBER        = 64, 
    parameter CPOL              = 1,
    parameter DATA_WIDTH        = 8,
    parameter RESET_PULSE       = 1000,
    parameter RESET_INCATIVE    = 1000,
    parameter BAUD_RATE         = 1, 
    parameter REF_A_B_CHOISE    = 0 // REF_A - default
)
(
    //
    input logic clk,                        //! тактовый сигнал
    input logic reset,                      //! сброс всех переменных в значение по умолчанию
    input logic start,                      //! запуск работы модуля
    output logic active,                    //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
    output logic ready,                     //! 1 - сигнал окончания работы
    // spi to AD9524
    output logic int_dds_pll_reset,
    output logic int_dds_pll_sclk,
    output logic int_dds_pll_sdi,
    input logic int_dds_pll_sdo,
    output logic int_dds_pll_cs,
    output logic int_dds_pll_ref_sel,
    input logic int_status_0,
    input logic int_status_1
);

localparam SPI_WR = 1'h0;
localparam SPI_RD = 1'h1;

// types
typedef struct{
    logic wr_rd;
    logic [ 1:0] wr_bits;  //! 0 - 1B, 1 - 2B, 2 - 3B, 3 - Streaming mode 
    logic [12:0] address;
    logic [ 3:0][7:0] data_in;
    logic [ 3:0][7:0] data_out;
} spi_transaction;

// settings sequence
spi_transaction set_mode [CMD_NUMBER-1:0];
spi_transaction set_mode_reverse [CMD_NUMBER-1:0];

// variables
integer i = 0, j = 0;
integer total_data_leng = 0;
integer data_byte_cnter = 0;
integer transaction_num = 0;
integer reset_pulse_cnt = 0;
integer reset_inactive_cnt = 0;
//
logic transaction_start;
logic transaction_busy;
logic transaction_stop;
logic reset_occured = 1'h0;
//
logic spi_clk;
logic spi_rst;
logic spi_enable;
logic spi_load, pre_spi_load;
logic [ 7:0] spi_data_in;
logic [ 7:0] spi_data_out;
logic spi_busy;
logic spi_dre;
logic spi_stc;
logic [15:0] ctrl_word;
logic SCK, MOSI, MISO;
//
logic high = 1'h1, low = 1'h0;

//used modules
spi #(.BAUD_RATE(BAUD_RATE), .CPOL(CPOL)) spi_jc (
    //----------------------------------
    //
    //    External interface
    //
    .SCK (SCK),       // serial clock
    .MOSI(MOSI),      // serial data output
    .MISO(MISO),      // serial data input
    //----------------------------------
    //
    //    Internal interface
    //
    .clk(spi_clk),       // system clock
    .rst(spi_rst),       // system reset
    
    .enable(spi_enable),    // enable processing
    .load(spi_load),      // load data for shift out
    .data_in(spi_data_in),   // data to write out to output shift register
    .data_out(spi_data_out),  // received data from serial input
    
    .busy(spi_busy),      // data register not empty or serial transfer is active
    .dre(spi_dre),       // data register empty
    .stc(spi_stc)        // serial transfer is completed
);

always_comb begin
    spi_clk = clk;
    //
    int_dds_pll_sclk = SCK;
    int_dds_pll_sdi = MOSI;
    MISO = int_dds_pll_sdo;
    // int_dds_pll_reset = reset;
    //
end

always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        active <= 0;
        ready <= 0;
        //
        transaction_num <= 0;
        transaction_start <= 0;
        reset_occured <= 1'h0;
        //Serial Port Configuration
        set_mode_reverse =  '{    
            '{SPI_WR, 2'h0, 13'h000, '{8'h00, 8'h00, 8'h00, 8'h81}, '{8'h00, 8'h00, 8'h00, 8'h00}},  //0x00  // SPI settings
            //Input PLL
            '{SPI_WR, 2'h1, 13'h010, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},  //0x10 - 0x11 // REFA R-devider
            '{SPI_WR, 2'h1, 13'h012, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},  //0x12 - 0x13 // REFB R-devider
            '{SPI_WR, 2'h1, 13'h016, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},  //0x16 - 0x17 // REFB N1-devider
            '{SPI_WR, 2'h2, 13'h018, '{8'h00, 8'h78, 8'h03, 8'h3F}, '{8'h00, 8'h00, 8'h00, 8'h00}},  //0x18 - 0x1A // PLL1 Charge Pump current: 0x7F - 65.5uA
            '{SPI_WR, 2'h2, 13'h01B, '{8'h00, 8'h00, 8'hC0, 8'h30}, '{8'h00, 8'h00, 8'h00, 8'h00}},  //0x1B - 0x1D // Rzero=833 кOhm //0x1B - zero_delay enabled, FB from ch_0
            //Ouput PLL
            '{SPI_WR, 2'h0, 13'h0F0, '{8'h00, 8'h00, 8'h00, 8'h7F}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // PLL2 Charge Pump current: 0x7F - 444.5uA
            '{SPI_WR, 2'h0, 13'h0F1, '{8'h00, 8'h00, 8'h00, 8'h0A}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // N2 = 40 = (4*10) + 0 -> A=0, B=10 //38 =(4x9)+2 -> A=2, B=9 
            '{SPI_WR, 2'h0, 13'h0F2, '{8'h00, 8'h00, 8'h00, 8'h03}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_WR, 2'h0, 13'h0F3, '{8'h00, 8'h00, 8'h00, 8'h02}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // VCO calibrationn start
            '{SPI_WR, 2'h0, 13'h0F4, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // M1 - 10
            '{SPI_WR, 2'h0, 13'h0F5, '{8'h00, 8'h00, 8'h00, 8'h03}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_WR, 2'h0, 13'h0F6, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            // Reserved register
            '{SPI_WR, 2'h0, 13'h190, '{8'h00, 8'h00, 8'h00, 8'h20}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            // Clock distribution
            //PLL0-5
            '{SPI_WR, 2'h2, 13'h196, '{8'h00, 8'h00, 8'h04, 8'h42}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 0   // 200MHz_DDS_DAC_0-1// 18 - is divided by 19
            '{SPI_WR, 2'h2, 13'h199, '{8'h00, 8'h00, 8'h04, 8'h42}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 1   // 200MHz_DDS_DAC_2-3
            '{SPI_WR, 2'h2, 13'h19C, '{8'h00, 8'h00, 8'h09, 8'h42}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 2   // 100MHz_FPGA 
            '{SPI_WR, 2'h2, 13'h19F, '{8'h00, 8'h00, 8'h04, 8'h42}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 3   // 200MHz_DDS
            '{SPI_WR, 2'h2, 13'h1AE, '{8'h00, 8'h00, 8'h04, 8'h42}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 4   // reserved
            '{SPI_WR, 2'h2, 13'h1B1, '{8'h00, 8'h00, 8'h04, 8'h62}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 5       // NU
            //PLL1 Output Control & PLL1 Output Channel Control
            '{SPI_WR, 2'h1, 13'h1BA, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            //ReadBack
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            //Status 0 & 1
            '{SPI_WR, 2'h1, 13'h230, '{8'h00, 8'h00, 8'h03, 8'h02}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 0x230 - 0x231
            // Sync and PowerCtrl
            '{SPI_WR, 2'h1, 13'h232, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 0x232 - 0x233
            // Update Registers
            '{SPI_WR, 2'h0, 13'h234, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            // //
            // '{SPI_WR, 2'h0, 13'h0F3, '{8'h00, 8'h00, 8'h00, 8'h02}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // VCO calibrationn start
            // // Update Registers
            // '{SPI_WR, 2'h0, 13'h234, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            //
            // '{SPI_WR, 2'h1, 13'h232, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},  // 0x232 - 0x233
            // // Update Registers
            // '{SPI_WR, 2'h0, 13'h234, '{8'h00, 8'h00, 8'h00, 8'h01}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            //Read map
            '{SPI_RD, 2'h0, 13'h000, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h010, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h012, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h016, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h018, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},  
            '{SPI_RD, 2'h2, 13'h01B, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h196, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h199, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h19C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h19F, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h1AE, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h2, 13'h1B1, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h1BA, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            // gap
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}},
            '{SPI_RD, 2'h1, 13'h22C, '{8'h00, 8'h00, 8'h00, 8'h00}, '{8'h00, 8'h00, 8'h00, 8'h00}}
            };
        //
        for (i=0; i<CMD_NUMBER; i=i+1) begin
            set_mode[i] = set_mode_reverse[CMD_NUMBER - i - 1];
        end
    end
    else begin
        if ((start == 1'h1) & (active == 0)) begin
            active <= 1;
            ready <= 0;
            reset_pulse_cnt <= 0;
            reset_inactive_cnt <= 0;
            int_dds_pll_reset <= 1;
            transaction_num <= 0;
            int_dds_pll_ref_sel <= REF_A_B_CHOISE;
        end
        else if(active == 1) begin
            if (reset_occured == 1'h0) begin
                if (reset_pulse_cnt < RESET_PULSE) begin
                    int_dds_pll_reset <= 1'h0;
                    reset_pulse_cnt <= reset_pulse_cnt + 1;
                end
                else if (reset_inactive_cnt < RESET_INCATIVE) begin
                    int_dds_pll_reset <= 1'h1;
                    reset_inactive_cnt <= reset_inactive_cnt + 1;
                end
                else begin
                    reset_occured <= 1'h1;
                end
            end
            else if (transaction_num <= CMD_NUMBER) begin
                if ((transaction_busy == 0) & (transaction_start == 1'h0)) begin
                    transaction_start <= 1;
                end
                else if (transaction_start == 1'h1) begin
                    transaction_start <= 0;
                end
                //
                if (transaction_stop == 1) begin
                    transaction_num <= transaction_num + 1;
                end
            end
            else begin
                active <= 0;
                ready <= 1;
            end
        end
        else begin 
            active <= 0;
            ready <= 0;
        end
    end
end

always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        transaction_stop <= 0;
        transaction_busy <= 0;
        int_dds_pll_cs <= 1;
        //
        spi_data_in <= 8'h00;
        spi_enable <= 1'h0;
        spi_load <= 1'h0;
        pre_spi_load <= 1'h0;
        //
        ctrl_word <= 0;
        //
        spi_rst <= 1;
    end
    else begin
        // определение nCS0
        int_dds_pll_cs <= ~transaction_busy;
        //
        if (transaction_start == 1) begin
            total_data_leng <= 2 + set_mode[transaction_num].wr_bits;
            ctrl_word <= {set_mode[transaction_num].wr_rd, set_mode[transaction_num].wr_bits, set_mode[transaction_num].address + set_mode[transaction_num].wr_bits};
            transaction_busy <= 1'h1;
            int_dds_pll_cs <= 1;
            pre_spi_load <= 1'h0;
            //
            spi_enable <= 1'h1;
            spi_load <= 1'h0;
            spi_rst <= 1'h1;  // плановый ресет для реализации логики работы черех spi_cts
            //
            data_byte_cnter <= 1'h0;
        end
        else if(transaction_busy == 1) begin
            // сбрасываем spi_rst для генерации первого сигнала spi_trc
            spi_rst <= 0;
            int_dds_pll_cs <= 0;
            //
            if (data_byte_cnter <= total_data_leng + 1) begin
                if (spi_stc == 1'h1) begin
                    // выбор источника данных
                    if (data_byte_cnter == 0) begin
                        spi_data_in <= ctrl_word[15:8];
                    end
                    else if (data_byte_cnter == 1) begin
                        spi_data_in <= ctrl_word[7:0];
                    end
                    else begin
                        spi_data_in <= set_mode[transaction_num].data_in[total_data_leng - data_byte_cnter];
                    end
                    // загружаем данные, если не последний шаг
                    if (data_byte_cnter <= total_data_leng) begin
                        spi_load <= 1;
                    end
                    //
                    data_byte_cnter <= data_byte_cnter + 1;
                end
                else begin
                    spi_load <= 0;
                end
            end
            else begin
                transaction_stop <= 1;
                transaction_busy <= 0;
                spi_enable <= 0;
                pre_spi_load <= 0;
                data_byte_cnter <= 0;
                int_dds_pll_cs <= 1;
            end
            //
        end
        else begin 
            transaction_stop <= 0;
            transaction_busy <= 0;
            spi_load <= 0;
            pre_spi_load <= 0;
            spi_enable <= 0;
            int_dds_pll_cs <= 1;
            data_byte_cnter <= 0;
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

module jc_ctrl_tb();

logic clk, reset, start, active, ready;
logic int_dds_pll_reset;
logic int_dds_pll_sclk;
logic int_dds_pll_sdi;
logic int_dds_pll_sdo;
logic int_dds_pll_cs;
logic int_dds_pll_ref_sel;
logic int_status_0;
logic int_status_1;

jitter_cleaner_ctrl #(.BAUD_RATE(50), .RESET_PULSE(10), .RESET_INCATIVE(10)) jc_ctrl_0(
    .clk(clk),                          //! тактовый сигнал
    .reset(reset),                      //! сброс всех переменных в значение по умолчанию
    .start(start),                      //! запуск работы модуля
    .active(active),                    //! состояние работы модуля: 0 - модуль не запущен, 1 - модуль в активном состоянии
    .ready(ready),                      //! 1 - сигнал окончания работы
    // spi to AD9524
    .int_dds_pll_reset(int_dds_pll_reset),
    .int_dds_pll_sclk(int_dds_pll_sclk),
    .int_dds_pll_sdi(int_dds_pll_sdi),
    .int_dds_pll_sdo(int_dds_pll_sdo),
    .int_dds_pll_cs(int_dds_pll_cs),
    .int_dds_pll_ref_sel(int_dds_pll_ref_sel),
    .int_status_0(int_status_0),
    .int_status_1(int_status_1)
);

// имитация сигналов
initial begin
    clk = 0;
    reset = 0;
    start = 0;
    //
    $display("Start\n____________");
end

// тактовая частота
always begin
    clk = ~clk; 
    #2.5;
end

always begin
    #(1*`TICK);
    reset = 1;
    #(1*`TICK);
    reset = 0;
    #(1*`TICK);
    start = 1;
    #(1*`TICK);
    start = 0;
    //
    while ((active == 1) || (start == 1)) begin
        #(1*`TICK);
    end
    #(100*`TICK);
    $display("Finish");
    // $stop;
end

endmodule
