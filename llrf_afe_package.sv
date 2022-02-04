//llrf_afe_package.sv

package llrf_afe_package;
    typedef struct{
        logic[13:0] data_0;
        logic[13:0] data_1;
        logic rst;
        logic slp;
    } dds_bus;

endpackage
