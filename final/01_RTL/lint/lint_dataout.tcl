read_file -type verilog {DataOut.v}
set_option top DataOut
current_goal Design_Read -top DataOut
link_design -force
current_goal lint/lint_rtl -top DataOut
run_goal
current_goal lint/lint_rtl_enhanced -top DataOut
run_goal

