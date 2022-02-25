onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -radix hexadecimal  sim:/dds_slave_tb/clk
add wave -position end -radix hexadecimal  sim:/dds_slave_tb/synch
add wave -position end -radix hexadecimal  sim:/dds_slave_tb/reset
add wave -position end -radix hexadecimal  sim:/dds_slave_tb/freq
add wave -noupdate -radix hexadecimal -format Analog-Step -height 100 -max 1200000000 -min 0 /dds_slave_tb/freq
add wave -position end -radix hexadecimal  sim:/dds_slave_tb/dac_signal
add wave -noupdate -format Analog-Step -height 100 -max 32767 -min -32768.0 /dds_slave_tb/dac_signal
add wave -position end -radix hexadecimal  sim:/dds_slave_tb/phase


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {1000000 ps} 0}
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
