onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end  -radix decimal sim:/b_to_f_tb/b_field
add wave -position end  -radix decimal sim:/b_to_f_tb/a_coeff
add wave -position end  -radix decimal sim:/b_to_f_tb/b_coeff
add wave -position end  -radix decimal sim:/b_to_f_tb/c_coeff
add wave -position end  -radix decimal sim:/b_to_f_tb/k_coeff
add wave -position end  sim:/b_to_f_tb/reset
add wave -position end  sim:/b_to_f_tb/clk
add wave -position end  sim:/b_to_f_tb/start
add wave -position end  -radix decimal sim:/b_to_f_tb/freq
add wave -position end  sim:/b_to_f_tb/ready
add wave -position end  sim:/b_to_f_tb/i
add wave -position end  sim:/b_to_f_tb/b_to_f_0/active
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/process_state
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/b_f
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/a_c
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/b_c
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/c_c
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/k_c
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/numerator_coeff
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/numerator
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/denominator
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/quotient
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/radical
add wave -position end  -radix decimal sim:/b_to_f_tb/b_to_f_0/sqrt_result


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
WaveRestoreZoom {0 ps} {1155 ns}

do restart.do
