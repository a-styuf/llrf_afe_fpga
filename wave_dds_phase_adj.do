onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/clk
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/reset
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/start
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/freq
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/current_phase
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/desired_phase
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/delay_time
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/work_time

add wave -position end -color yellow -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/phsh_start
add wave -position end -color yellow -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/phsh_ready
add wave -position end -color yellow -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/phase_shift
add wave -position end -color yellow -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/step_number

add wave -position end -color white -radix decimal  sim:/phase_adj_tb/phase_adj_0/j
add wave -position end -color white -radix decimal -format Analog-Step -height 50 /phase_adj_tb/phase_adj_0/j
add wave -position end -color white -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/conveer_step
add wave -position end -color white -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/conveer_flag
add wave -position end -color white -radix decimal  sim:/phase_adj_tb/phase_adj_0/conveer_state
add wave -position end -color white -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/conveer_ready
add wave -position end -color white -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/remain_accumulator

add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/active
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/ready
add wave -position end -radix hexadecimal  sim:/phase_adj_tb/phase_adj_0/freq_add
add wave -position end -radix decimal -format Analog-Step -height 100 /phase_adj_tb/phase_adj_0/freq_add


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
