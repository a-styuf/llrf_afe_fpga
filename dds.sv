//dds.sv

module dds(
    input logic[31:0] freq,
    input logic[31:0] additional_freq,
    input logic lock,
    input logic enable,
    input logic reset,
    input logic clk,
    //
    output logic[16:0] dac_signal,
    output logic[31:0] phase
);

//variables
logic[32:0] phase_accum;
logic[9:0] sin_addr;

//
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        phase_accum <= 32'H00000000;
    end
    else begin
        phase_accum <= phase_accum + freq;
        sin_addr <= phase_accum[31:22];
        phase <= phase_accum;
    end
end

// dds mem with sin-period
dds_sin_mem	dds_sin_mem_inst (
	.address ( sin_addr ),
	.clock ( clk ),
	.data ( 16'HAAAA),
	.q ( dac_signal )
	);

endmodule
