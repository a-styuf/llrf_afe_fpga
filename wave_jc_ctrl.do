onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end -color green -radix hexadecimal  sim:/jc_ctrl_tb/clk
add wave -position end -color green -radix hexadecimal  sim:/jc_ctrl_tb/reset
add wave -position end -color green -radix hexadecimal  sim:/jc_ctrl_tb/start
add wave -position end -color green -radix hexadecimal  sim:/jc_ctrl_tb/active
add wave -position end -color green -radix hexadecimal  sim:/jc_ctrl_tb/ready

add wave -position end -color green -divider "SPI_OUT"
add wave -position end -color yellow -radix hexadecimal  sim:/jc_ctrl_tb/int_dds_pll_cs
add wave -position end -color yellow -radix hexadecimal  sim:/jc_ctrl_tb/int_dds_pll_sclk
add wave -position end -color yellow -radix hexadecimal  sim:/jc_ctrl_tb/int_dds_pll_sdi
add wave -position end -color yellow -radix hexadecimal  sim:/jc_ctrl_tb/int_dds_pll_sdo

add wave -position end -color white -divider "Internal var"
add wave -position end -color white -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/transaction_start
add wave -position end -color white -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/transaction_busy
add wave -position end -color white -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/transaction_stop
add wave -position end -color white -radix decimal  sim:/jc_ctrl_tb/jc_ctrl_0/transaction_num
add wave -position end -color white -radix decimal  sim:/jc_ctrl_tb/jc_ctrl_0/data_byte_cnter
add wave -position end -color white -radix decimal  sim:/jc_ctrl_tb/jc_ctrl_0/total_data_leng
add wave -position end -color white -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/ctrl_word

add wave -position end -color "Green Yellow" -divider "SPI module"
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_rst
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_enable
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_load
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_data_in
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_data_out
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_busy
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_dre
add wave -position end -color "Green Yellow" -radix hexadecimal  sim:/jc_ctrl_tb/jc_ctrl_0/spi_stc

add wave -position end -color cyan -divider "Jitter Cleaner"
add wave -position end -color cyan -radix hexadecimal  sim:/jc_ctrl_tb/int_dds_pll_reset
add wave -position end -color cyan -radix hexadecimal  sim:/jc_ctrl_tb/int_dds_pll_ref_sel
add wave -position end -color cyan -radix hexadecimal  sim:/jc_ctrl_tb/int_status_0
add wave -position end -color cyan -radix hexadecimal  sim:/jc_ctrl_tb/int_status_1


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
