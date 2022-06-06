//reg_interface.sv

//! The Register Interface module with self testbench.

`timescale 1ns/10ps

// import avmm_iface::*;

// Module
module reg_interface
#(
    parameter AW = 11,
    parameter DW = 32
)
(
    // 
    input logic reset,                      //! асинхронный сброс всех переменных в значение по умолчанию
    input logic clk,                        //! тактовый сигнал
    input logic av_clk,                     //! тактовый сигнал шины авалон
    // external interface
    avmm_if.slave avmm_if_port,                
    // interface to internal logic
    output logic [31:0] dds0_freq           //! добавок к частоте
);



//variables
logic mem_wr_a_bkock = 1'h0, mem_rd_a_bkock = 1'h0, mem_gen_bkock = 1'h0, mem_access_bkocked = 1'h0;  //! переменные, блокирующие доступ к памяти

// Others modules

// modulse variables
logic clock_a_sig, clock_b_sig;
logic aclr_a_sig, aclr_b_sig;
logic [AW-1:0] address_a_sig, address_b_sig; 
logic [DW-1:0] data_a_sig, address_b_data_b_sigsig; 
logic rden_a_sig, rden_b_sig; 
logic wren_a_sig, wren_b_sig; 
logic [DW-1:0] q_a_sig, q_b_sig;

// avalonMM to RAM module
avalonMM_to_RAM  #(.AW(12), .DW(32), .PL(2)) avalonMM_to_RAM_0
(
    // 
    .reset(reset),                    //! асинхронный сброс всех переменных в значение по умолчанию
    .clk(clk),                        //! внутренняя тактовая частота работ блока
    // avalon interface
    // fundamental signals
    .avmm_if_0(avmm_if_port),
    // interface to ram
    .mem_aclr(aclr_a_sig),
	.mem_clock(clock_a_sig),
	.mem_rden(rden_a_sig),
	.mem_wren(wren_a_sig),
	.mem_address(address_a_sig),
	.mem_data(data_a_sig),
	.mem_q(q_a_sig)
);

//! 2-port RAM
ram_2p_2kB_32b	ram_2p_2kB_32b_inst (
	.aclr_a ( aclr_a_sig ),
	.aclr_b ( aclr_b_sig ),
	.address_a ( address_a_sig ),
	.address_b ( address_b_sig ),
	.clock_a ( clock_a_sig ),
	.clock_b ( clock_b_sig ),
	.data_a ( data_a_sig ),
	.data_b ( data_b_sig ),
	.rden_a ( rden_a_sig ),
	.rden_b ( rden_b_sig ),
	.wren_a ( wren_a_sig ),
	.wren_b ( wren_b_sig ),
	.q_a ( q_a_sig ),
	.q_b ( q_b_sig )
	);

//! обработка данных в тактовом домене внешнего интерфейса

always @(posedge av_clk, posedge reset)
begin
    if (reset == 1) begin
        mem_access_bkocked <= 0;
    end
    else begin

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

///***_______testbench_______***///
`define CLK                     (200_000_000)
`define TICK                    (1_000_000_000/200_000_000)

module reg_interface_tb();

logic reset;                            //! асинхронный сброс всех переменных в значение по умолчанию
logic clk;                              //! тактовый сигнал
logic av_clk;                           //! тактовый сигнал шины авалон
// external interface
avmm_if #(.AW(12), .DW(32)) avmm_if_0();
// interface to internal logic
logic [31:0] dds0_freq;                 //! частота


reg_interface #(.AW(11), .DW(32)) reg_interface_0
(
    // 
    .reset(reset),                      //! асинхронный сброс всех переменных в значение по умолчанию
    .clk(clk),                          //! тактовый сигнал
    .av_clk(av_clk),                    //! тактовый сигнал шины авалон
    // external interface
    .avmm_if(avmm_if_0.slave),                
    // interface to internal logic
    .dds0_freq(dds0_freq)               //! добавок к частоте
);

// имитация сигналов
initial begin
    clk = 0;
    av_clk = 0;
    reset = 1;
    //
    avmm_if_0.address = 12'h0000;
    avmm_if_0.read = 1'h0;
    avmm_if_0.write = 1'h0;
    avmm_if_0.burstcount = 1'h0;
    avmm_if_0.writedata = 32'h0000;
    avmm_if_0.byteenable = 4'h0;
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
    #(1*`TICK);
end

// тактовая частота шины avalon
always begin
    av_clk = ~av_clk; 
    #(1*`TICK);
end

// запись данных через avalonMM
always begin
    #(1*`TICK);
    if (reset == 1'h0) begin
        #(1*`TICK);
        avmm_if_0.address = 12'h0000;
        avmm_if_0.write = 1'h1;
        avmm_if_0.writedata = 32'hFEFE;
        avmm_if_0.byteenable = 4'hF;
        while (avmm_if_0.write) begin
            if (avmm_if_0.waitrequest == 1'h1) begin
                //
                #(1*`TICK);
            end
            else begin
                avmm_if_0.write = 1'h0;
                avmm_if_0.writedata = 32'h0000;
                //
                #(1*`TICK);
            end
        end
        #(10*`TICK);
        $display("Finish");
        $stop;
    end
end

endmodule
