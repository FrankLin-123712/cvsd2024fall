// -----------------------------------------------------------------------------
// Simulation: HW3
// -----------------------------------------------------------------------------

// testbench
// -----------------------------------------------------------------------------
../00_TESTBED/testbench_sv.v

// memory file
// -----------------------------------------------------------------------------
//../sram_256x8/sram_256x8.v
../sram_512x8/sram_512x8.v
// ../sram_4096x8/sram_4096x8.v


// design files
// -----------------------------------------------------------------------------
./core.v
./system_controller.v
./sram_4banks.v
./sram_bank_controller.v
./conv_engine.v
./sobel_nms_engine.v
./median_filter_engine.v
./four2oneMux.v
// ./components/define.v