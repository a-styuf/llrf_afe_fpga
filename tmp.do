onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dds_slave_core_tb/dds_0/reset
add wave -noupdate -radix hexadecimal /dds_slave_core_tb/dds_0/freq
add wave -noupdate -radix hexadecimal /dds_slave_core_tb/dds_0/phase
add wave -noupdate -radix hexadecimal /dds_slave_core_tb/dds_0/phase_accum
add wave -noupdate -radix hexadecimal /dds_slave_core_tb/dds_0/sin_addr
add wave -noupdate -radix hexadecimal /dds_slave_core_tb/dds_0/dac_signal
add wave -noupdate -format Analog-Step -height 100 -max 32767.0 -min -32768.0 -radix hexadecimal /dds_slave_core_tb/dds_0/dac_signal
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {84723 ps} 0}
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
WaveRestoreZoom {0 ps} {84723 ps}
