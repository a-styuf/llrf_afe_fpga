onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -color green -radix hexadecimal  sim:/led_processor_tb/clk
add wave -position end -color green -radix hexadecimal  sim:/led_processor_tb/reset
add wave -position end -color green -radix hexadecimal -expand sim:/led_processor_tb/led_mode
add wave -position end -color green -radix hexadecimal -expand sim:/led_processor_tb/led_start
add wave -position end -color green -radix hexadecimal -expand sim:/led_processor_tb/led_stop
add wave -position end -color green -radix hexadecimal -expand sim:/led_processor_tb/led_out
add wave -position end -color green -radix decimal -expand sim:/led_processor_tb/led_processor_0/counter



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
