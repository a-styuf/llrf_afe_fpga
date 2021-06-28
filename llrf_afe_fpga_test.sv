//llrf_afe_fpga_test

import llrf_afe_package::*;

module llrf_afe_fpga_test(
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
    input logic reserve_2v5[8]
);

//variables
int i;
//clock
logic clk_200MHz;
logic locked_sig;
//
logic[15:0] dds_freq[3:0];
logic[15:0] dds_data[3:0];
logic[7:0] rio_in;
logic[7:0] rio_out;
logic[4:0] spi_data_mosi;
//
logic reset;
dds_bus dds_b[3:0];
//
logic[31:0] cnt;
//
genvar j;
generate
    for (j=0; j<4; j=j+1) begin: dds_gen
        dds dds_inst(
            .freq (dds_freq[j]),
            .additional_freq (16'H0000),
            .lock (1'b1),
            .enable (1'b1),
            .reset (reset),
            .clk (int_dds_clk_in),
            //
            .dac_signal(dds_data[j]),
            .phase()
        );
    end
endgenerate
//
assign reset = locked_sig;
//
always @(posedge int_dds_clk_in, posedge reset)
begin
    if (reset == 1) begin
        for (i = 0; i < 4; i=i+1) begin
            dds_b[i].data <= 14'h0000;
            dds_b[i].slp <= 1'h0;
            dds_b[i].dis <= 1'h0;
            dds_freq[i] <= 16'HAAAA;
        end
    end
    else begin
        for (i = 0; i < 4; i=i+1) begin
            int_dds[i].data <= dds_data[i][15:2];
        end

    end
end

always @(posedge int_dds_clk_in, posedge reset)
begin
    if (reset == 1) begin
        for (i = 0; i < 8; i=i+1) begin
            ext_rio_in[i] <= 1'b0;
            int_rio_out[i] <= 1'b0;
        end
    end
    else begin
        for (i = 0; i < 8; i=i+1) begin
            //
            rio_out[i] <= ext_rio_out[i];
            int_rio_out[i] <= rio_out[i];
            //
            rio_in[i] <= int_rio_in[i];
            ext_rio_in[i] <= rio_in[i];
        end
    end
end

always @(posedge spi_sclk, posedge reset)
begin
    if (reset == 1) begin
        for (i = 0; i < 8; i=i+1) begin
            spi_miso[3:0] <= 4'b1;
        end
    end
    else if (spi_cs == 0) begin
        spi_data_mosi[3:0] <= spi_miso[3:0];
    end
end

// pll - c0 is a based clk, c1 is a 200 MHz clock for DDS-logiс
sys_pll	sys_pll_inst (
	.areset (1'b0),
	.inclk0 (sys_clk ),
    //
	.phasecounterselect (1'b0),
	.phasestep (1'b0),
	.phaseupdown (1'b0),
	.phasedone ( ),
    //
	.scanclk ( scanclk_sig ),
	.c0 ( out_clk_100MHz ),
	.c1 ( clk_200MHz ),
	.locked ( locked_sig )
	);

endmodule
