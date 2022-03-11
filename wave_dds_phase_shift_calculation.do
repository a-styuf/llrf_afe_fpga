onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/clk
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/reset
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/start
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/freq
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/current_phase
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/desired_phase
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/time_from_start

add wave -position end -color yellow sim:/phase_shift_calculation_tb/phase_sh_calc_0/state
add wave -position end -color yellow sim:/phase_shift_calculation_tb/phase_sh_calc_0/step_number
add wave -position end -radix hexadecimal -color yellow sim:/phase_shift_calculation_tb/phase_sh_calc_0/phase_increase
add wave -position end -radix hexadecimal -color yellow sim:/phase_shift_calculation_tb/phase_sh_calc_0/future_phase

add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/ready
add wave -position end -radix hexadecimal  sim:/phase_shift_calculation_tb/phase_sh_calc_0/phase_shift

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
