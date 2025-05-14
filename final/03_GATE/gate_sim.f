// -----------------------------------------------------------------------------
// Simulation: CVSD 2024 Spring Final Project
// -----------------------------------------------------------------------------

// Simulation Settings
// -----------------------------------------------------------------------------
+v2k 
-debug_access+all 
-P /usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/novas.tab
/usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/pli.a
-sverilog 
-diag=sdf:verbose
+maxdelays
-negdelay
+neg_tchk

// Simulation Files
// -----------------------------------------------------------------------------
../00_TESTBED/testbed.sv
./ed25519_syn.v
-v /home/raid7_2/course/cvsd/CBDK_IC_Contest/CIC/Verilog/tsmc13_neg.v

// =============================================================================
//                  Your Can Only Modify The Below Part
// =============================================================================

// Define Flags
// -----------------------------------------------------------------------------
+define+GATE
