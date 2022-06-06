//avalon_mm_package.sv

interface avalon_mm_bus(input logic clock);
    // fundamental signals
    logic [15:0] address;
    logic [31:0] byteenable; //!NU
    logic [31:0] read;
    logic [1:0] responce; 
    logic write;
    logic [31:0] writedata;
    // wait-state signals
    logic waitrequest;
    // pipeline signals
    logic readdatavalid;
    logic writeresponsevalid;
    // burst signals
    logic [10:0] burstcount;
    logic beginbursttransfer;

    modport master(
        // fundamental signals
        logic [15:0] address;
        logic [31:0] byteenable; //!NU
        logic [31:0] read;
        logic [1:0] responce; 
        logic write;
        logic [31:0] writedata;
        // wait-state signals
        logic waitrequest;
        // pipeline signals
        logic readdatavalid;
        logic writeresponsevalid;
        // burst signals
        logic [10:0] burstcount;
        logic beginbursttransfer;
    );

    modport slave(
        // fundamental signals
        logic [15:0] address;
        logic [31:0] byteenable; //!NU
        logic [31:0] read;
        logic [1:0] responce; 
        logic write;
        logic [31:0] writedata;
        // wait-state signals
        logic waitrequest;
        // pipeline signals
        logic readdatavalid;
        logic writeresponsevalid;
        // burst signals
        logic [10:0] burstcount;
        logic beginbursttransfer;        
    );
endinterface

