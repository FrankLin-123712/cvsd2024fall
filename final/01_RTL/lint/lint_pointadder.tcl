read_file -type verilog {PointAdder.v}
set_option top PointAdder
current_goal Design_Read -top PointAdder
link_design -force
current_goal lint/lint_rtl -top PointAdder 
run_goal
current_goal lint/lint_rtl_enhanced -top PointAdder
run_goal

