#PrimeTime Script
set power_enable_analysis TRUE
set power_analysis_mode time_based

read_file -format verilog  ../02_SYN/Netlist/IOTDF_syn.v
current_design IOTDF
link

read_sdf -load_delay net ../02_SYN/Netlist/IOTDF_syn.sdf


## Measure  power
#report_switching_activity -list_not_annotated -show_pin

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_p1_F1.fsdb
update_power
report_power 
report_power > F1_5.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_p1_F2.fsdb
update_power
report_power
report_power >> F1_5.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_p1_F3.fsdb
update_power
report_power
report_power >> F1_5.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_p1_F4.fsdb
update_power
report_power
report_power >> F1_5.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_p1_F5.fsdb
update_power
report_power
report_power >> F1_5.power



