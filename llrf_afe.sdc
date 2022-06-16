# system clock setup variable

# увеличение уменьшает запас по tsu
# tsu-
set JC_FPGA_CLK_delay_max 0.461
# th+
set JC_FPGA_CLK_delay_min 0.461

# tsu-
set FPGA_DDS_DATA_delay_max 0.252
# th+
set FPGA_DDS_DATA_delay_min 0.117

# th-
set JC_DDS_CLK_delay_max 0.830
# tsu+
set JC_DDS_CLK_delay_min 0.830

set JX_DDS_CLK_period_ns        5
set JX_DDS_CHANNELS_phase_deg   0
set JX_DDS_CHANNELS_phase_ns    [expr {($JX_DDS_CHANNELS_phase_deg/360.0)*($JX_DDS_CLK_period_ns)}]

set DDS_CLOCK_tSU 0.4
set DDS_CLOCK_tH  1.2

set CYC4_CLOCK_tSU 1.1
set CYC4_CLOCK_tH -0.6

# derive_clock_uncertainty
derive_clock_uncertainty
# create_clock
# virtual
create_clock -name ext_dds_clk_in_v -period $JX_DDS_CLK_period_ns
# 
create_clock -name int_dds_clk_in -period $JX_DDS_CLK_period_ns [get_ports int_dds_clk_in]
create_clock -name sys_clk -period 10 -waveform {0 5} [get_ports sys_clk]
create_clock -name in_clk_100MHz -period 10 [get_ports in_clk_100MHz]
create_clock -name spi_sclk -period 10 [get_ports spi_sclk]
# output create_generated_clock

# derive_pll_clocks
derive_pll_clocks
set internal_clk_100MHz sys_pll_inst|altpll_component|auto_generated|pll1|clk[0]
set internal_clk_200MHz sys_pll_inst|altpll_component|auto_generated|pll1|clk[1]
# set_clock_groups
set_clock_groups -exclusive     -group  {sys_clk \
                                        out_clk_100MHz
                                        } \
                                -group {int_dds_clk_in \
                                        ext_dds_clk_in_v \
                                        in_clk_100MHz \
                                        } \
                                -group {spi_sclk \
                                        }
# multipath
set_multicycle_path -from [get_clocks {int_dds_clk_in}] -to [get_clocks {ext_dds_clk_in_v}] -setup 2
set_multicycle_path -from [get_clocks {int_dds_clk_in}] -to [get_clocks {ext_dds_clk_in_v}] -hold 1
# latency
set_clock_latency -source $JX_DDS_CHANNELS_phase_ns [get_clocks ext_dds_clk_in_v]
# setup delay
set_output_delay -clock [get_clocks ext_dds_clk_in_v] -max [expr        $JC_FPGA_CLK_delay_max + \
                                                                        $DDS_CLOCK_tSU + \
                                                                        $FPGA_DDS_DATA_delay_max - \
                                                                        $JC_DDS_CLK_delay_min] \
                                                                        [get_ports {int_dds[*].data_0[*] int_dds[*].data_1[*]}]
set_output_delay -clock [get_clocks ext_dds_clk_in_v] -min [expr        $JC_FPGA_CLK_delay_min - \
                                                                        $DDS_CLOCK_tH + \
                                                                        $FPGA_DDS_DATA_delay_min - \
                                                                        $JC_DDS_CLK_delay_max] \
                                                                        [get_ports {int_dds[*].data_0[*] int_dds[*].data_1[*]}]

set_input_delay  -clock in_clk_100MHz -max 1.2 [get_ports ext_rio_out[*]]
set_input_delay  -clock in_clk_100MHz -min -0.6 [get_ports ext_rio_out[*]]

set_input_delay  -clock in_clk_100MHz -max 1.2 [get_ports int_rio_in[*]]
set_input_delay  -clock in_clk_100MHz -min -0.6 [get_ports int_rio_in[*]]

# set_output_delay -clock [get_clocks in_clk_100MHz] -max [expr $CYC5_CLOCK_tSU] [get_ports ext_rio_in[*]]
# set_output_delay -clock [get_clocks in_clk_100MHz] -min [expr $CYC5_CLOCK_tH] [get_ports ext_rio_in[*]]
# report_path

# console outputs
puts "JX_DDS_CHANNELS_phase_ns $JX_DDS_CHANNELS_phase_ns"