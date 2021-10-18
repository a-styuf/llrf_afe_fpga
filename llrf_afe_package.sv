//llrf_afe_package.sv

package llrf_afe_package;
    typedef struct{
        logic [13:0] data;
        logic dis;
        logic slp;
    } dds_bus;

endpackage
