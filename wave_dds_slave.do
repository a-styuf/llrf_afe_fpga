onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -color green -radix hexadecimal  sim:/dds_slave_tb/clk
add wave -position end -color green -radix hexadecimal  sim:/dds_slave_tb/reset
add wave -position end -color green -radix hexadecimal  sim:/dds_slave_tb/synch

add wave -position end -color green -divider "Freq_In"
add wave -position end -color green -radix hexadecimal  {/dds_slave_tb/freq[0]}
add wave -position end -color green -radix hexadecimal  {/dds_slave_tb/freq[1]}
add wave -position end -color green -radix hexadecimal  {/dds_slave_tb/dds_gen[0]/dds_inst/dds_core/freq}
add wave -position end -color green -radix hexadecimal  {/dds_slave_tb/dds_gen[0]/dds_inst/dds_core/freq_add}
add wave -position end -color green -radix hexadecimal  {/dds_slave_tb/dds_gen[1]/dds_inst/dds_core/freq}
add wave -position end -color green -radix hexadecimal  {/dds_slave_tb/dds_gen[1]/dds_inst/dds_core/freq_add}


add wave -position end -color "Green Yellow" -divider "Phase_Adj"
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/dds_slave_tb/ph_adj_start
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/dds_slave_tb/desired_phase
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/dds_slave_tb/delay_time
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/dds_slave_tb/work_time
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/dds_slave_tb/ph_adj_ready

add wave -position end -color cyan -divider "Output_Data"
add wave -position end -color cyan -radix hexadecimal  sim:/dds_slave_tb/dac_signal
add wave -noupdate -color cyan -format Analog-Step -height 74 -max 32767.0 -min -32767.0 {/dds_slave_tb/phase[0]}
add wave -noupdate -color cyan -format Analog-Step -height 74 -max 32767.0 -min -32767.0 {/dds_slave_tb/phase[1]}
add wave -noupdate -color cyan -format Analog-Step -height 74 -max 4294967296 -min 0 {/dds_slave_tb/dac_signal[0]}
add wave -noupdate -color cyan -format Analog-Step -height 74 -max 4294967296 -min 0 {/dds_slave_tb/dac_signal[1]}

add wave -position end -color cyan -divider "Devider"
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/denominator}
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/numerator}
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/quotient}
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/remain}
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/conveer_state}
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/w_t}
add wave -position end  {/dds_slave_tb/dds_gen[0]/dds_inst/phase_adj_inst/d_t}

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {1000 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 429
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {10000 ns}


do restart.do
