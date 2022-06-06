onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -color green -radix hexadecimal  sim:/reg_interface_tb/clk
add wave -position end -color green -radix hexadecimal  sim:/reg_interface_tb/av_clk
add wave -position end -color green -radix hexadecimal  sim:/reg_interface_tb/reset
add wave -position end -color green -radix hexadecimal  sim:/reg_interface_tb/avm_if_0
add wave -position end -color green -radix hexadecimal  sim:/reg_interface_tb/dds_freq

add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/clock_a_sig
add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/aclr_a_sig
add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/address_a_sig
add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/data_a_sig
add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/rden_a_sig
add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/wren_a_sig
add wave -position end -color yellow -radix hexadecimal sim:/reg_interface_tb/reg_interface_0/q_a_sig



TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {1000000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 429
configure wave -valuecolwidth 64
configure wave -justifyvalue left
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
