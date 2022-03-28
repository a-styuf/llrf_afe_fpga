transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/dds_sin_mem.v}
vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/sqrt_int_64.v}
vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/divide_32.v}
vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/mult_64.v}
vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/sys_pll.v}
vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/divide_32_signed.v}
vlog -vlog01compat -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/db {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/db/sys_pll_altpll.v}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/phase_shift_calculation.sv}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/b_to_f.sv}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/dds_slave_core.sv}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/dds_slave.sv}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/llrf_afe_package.sv}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/phase_adj.sv}
vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/llrf_afe.sv}

vlog -sv -work work +incdir+D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe {D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/phase_adj.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  phase_adj_tb

do D:/YandexDisk/Work/Quartus/Cycone_4/llrf_afe/wave_dds_phase_adj.do
