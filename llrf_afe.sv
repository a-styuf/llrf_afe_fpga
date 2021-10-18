//llrf_afe

import llrf_afe_package::*;

module llrf_afe(
    // ** internal ** //
    // DDS
    output dds_bus int_dds[3:0],
    input logic[3:0] int_dds_fb,
    input logic dds_sync,
    input logic int_dds_clk_in,
    //
    output logic[7:0] int_rio_out,
    input logic[7:0] int_rio_in,
    //
    // DDS PLL
    output logic int_dds_pll_ref_sel, int_dds_pll_sclk, int_dds_pll_sdi, int_dds_pll_cs, int_dds_pll_reset,
    input logic int_dds_pll_sdo,
    output logic int_status_0, int_status_1,
    // MFM
    output logic int_mfm_b_ref, int_mfm_b_p, int_mfm_b_m, 
    output logic int_mfm_a0, int_mfm_a1,
    output logic int_mfm_sdo, int_mfm_sck, int_mfm_busy, int_mfm_cnv,
    // ** external ** //
    // DDS
    output logic[7:0] ext_rio_in,
    input logic[7:0] ext_rio_out,
    // ** system ** //
    // I2C
    input logic i2c_sda, i2c_scl, i2c_alert,
    // UART
    input logic fpga_rx,
    output logic fpga_tx,
    // SPI
    input logic[3:0] spi_mosi,
    output logic[3:0] spi_miso,
    input logic spi_sclk, spi_cs,
    // CLK
    output logic out_clk_100MHz,
    input logic sys_clk, in_clk_100MHz,
    //
    input logic reserve_lvds[4],
    input logic reserve_3v3[8],
    input logic reserve_2v5[8],
	output logic led[4]
	 //
);

//*** _____________Variables____________________________________ ***//

//variables
int i;
//logic
logic[15:0] dds_freq[3:0];
logic[15:0] dds_data[3:0];
//clock
logic clk_200MHz;
//reset
logic reset;

//tmp
reg[31:0] b_field = 32'hFF;              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
reg[31:0] a_coeff = 32'hFF;              //! a - коэффициент формулы
reg[31:0] b_coeff = 32'hFF;              //! b - коэффициент формулы
reg[31:0] c_coeff = 32'hFF;              //! c - коэффициент формулы
reg[7:0] k_coeff = 8'hFF;               //! Номер рабочей гармоники ВЧ
reg start = 1'h1;                      //! запуск подсчета
//
reg[31:0] freq;                 //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
reg ready;                      //! 

//*** _____________Generation____________________________________ ***//
// 4 DDS
genvar j;
generate
    for (j=0; j<4; j=j+1) begin: dds_gen
        dds_slave dds_inst(
            .freq (dds_freq[j]),
            .reset (reset),
            .clk (int_dds_clk_in),
            .synch (1'h1),
            //
            .dac_signal(dds_data[j])
        );
    end
endgenerate

b_to_f b_to_f_0(
    .b_field(b_field),              //! значение магнитного поля: максимальное значение 128 T, квант ~29.8 нТ
    .a_coeff(a_coeff),              //! a - коэффициент формулы
    .b_coeff(b_coeff),              //! b - коэффициент формулы
    .c_coeff(c_coeff),              //! c - коэффициент формулы
    .k_coeff(k_coeff),               //! Номер рабочей гармоники ВЧ
    .reset(reset),                      //! сброс в значение по умолчанию
    .clk(clk_200MHz),                        //! тактовый сигнал
    .start(start),                      //! запуск подсчета
    //
    .freq(freq),                //! реузьлтат подсчета частоты: Freq[Hz]*(2^32)/(F_clk)
    .ready(ready)                      //! сигнал готовностси значения частоты
);

//*** ____________Description____________________________________ ***//

initial begin
    for (i = 0; i < 4; i=i+1) begin
            int_dds[i].slp <= 1'h0;
            int_dds[i].dis <= 1'h0;
				int_dds[i].data <= 14'h0000;
        end
end

// 4 DDS control
always @(posedge int_dds_clk_in, posedge reset)
begin
    if (reset == 1) begin
        for (i = 0; i < 4; i=i+1) begin
            int_dds[i].data <= 14'h0000;
            int_dds[i].slp <= 1'h0;
            int_dds[i].dis <= 1'h0;
            // dds_freq[i] <= 16'HAAAA;
            dds_freq[i] <= freq;
        end
    end
    else begin
        for (i = 0; i < 4; i=i+1) begin
            int_dds[i].data <= dds_data[i][15:2];
        end

    end
end

endmodule
