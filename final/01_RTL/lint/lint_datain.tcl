read_file -type verilog {DataIn.v}
set_option top DataIn
current_goal Design_Read -top DataIn
link_design -force
current_goal lint/lint_rtl -top DataIn
run_goal
current_goal lint/lint_rtl_enhanced -top DataIn
run_goal

