//avalonMM_to_RAM.sv

`timescale 1ns/10ps



// Module
module avalonMM_to_RAM
#(
    parameter AW = 12,  //! memory address width
    parameter DW = 32,  //! memory data width
    parameter PL = 2   //! memory access pipeline
)
(
    // 
    input logic reset,                      //! асинхронный сброс всех переменных в значение по умолчанию
    input logic clk,                        //! тактовая частота работ блока
    // avalon interface
    // fundamental signals
    avmm_if.slave avmm_if_0,
    // interface to ram
    output logic mem_aclr,
    output logic mem_clock,
    output logic mem_rden,
    output logic mem_wren,
    output logic [AW-1:0] mem_address,
    output logic [DW-1:0] mem_data,
    input logic [DW-1:0] mem_q
);

assign mem_clock = clk;
assign mem_aclr = reset;

always_comb begin
    mem_address = avmm_if_0.address;
    mem_data = avmm_if_0.writedata;
    avmm_if_0.readdata = mem_q;
    //
    mem_wren = avmm_if_0.write;
    mem_rden = avmm_if_0.read;
end

//! обработка данных в тактовом домене внешнего интерфейса
always @(posedge reset, posedge clk)
begin
    if (reset == 1) begin
        avmm_if_0.waitrequest <= 0;
    end
    else begin
        //обработка waitrequest
    end
end

//! обработка данных в тактовом домене ПЛИС
always @(posedge clk, posedge reset)
begin
    if (reset == 1) begin
        //
    end
    else  begin
        //
    end
end
endmodule
