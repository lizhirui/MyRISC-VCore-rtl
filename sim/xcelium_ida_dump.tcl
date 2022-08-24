ida_database -open -name="ida.db"
ida_probe -log -sv_flow -uvm_reg -log_objects -sv_modules -wave -wave_probe_args= "top -all -depth all –memories"
run
exit