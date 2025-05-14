read_file -type verilog {ed25519.v}
set_option top ed25519
current_goal Design_Read -top ed25519
link_design -force
current_goal lint/lint_rtl -top ed25519 
run_goal
current_goal lint/lint_rtl_enhanced -top ed25519
run_goal