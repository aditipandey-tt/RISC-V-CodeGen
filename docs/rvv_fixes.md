# RVV and llvm-mca Analysis on tt-ascalon-x

We use the core loop assembly files `test_rv64gc.s` (scalar) and
`test_riscv.s` (vector) from each kernel directory, and run llvm-mca
with:

- `-mtriple=riscv64-unknown-elf`
- `-mcpu=tt-ascalon-x`

For each kernel we record:

- ScalarCycles   = Total Cycles from scalar core loop
- VecCycles      = Total Cycles from vector core loop
- VL             = vector length in FP32 elements (from `vsetvli`)
- VecCycles/VL   = VecCycles / VL
- Speedup        = ScalarCycles / (VecCycles / VL)

## Kernels with additional fixes

- **spmv_csr**  
  Original code-gen fell back to VL=1 and did not use RVV gather. We
  applied fixes (e.g., `restrict` pointers, `-ffast-math`) so that Clang
  generates a VL=8 loop using gather instructions. With the fixed loop:
  - Scalar: 313 cycles
  - Vector: 3812 cycles, VL=8
  - VecCycles/VL = 3812 / 8 = 476.5
  - Speedup = 313 / (3812/8) ≈ 0.65, close to HAPS (~0.77×).

- **reduction_loop** and **montecarlo_pi**  
  We cleaned up the core loops, but auto-vectorization remains
  effectively scalar for these patterns. In the llvm-mca analysis we
  treat both with VL=1 and observe < 1× speedup, which matches the HAPS
  behavior qualitatively.

## Loop-only timing (HAPS)

Separately, we use small `main` wrappers with a cycle counter on HAPS to
measure only the loop body in ns/call for scalar and vector binaries.
These are used for the HAPS table in the paper and do not affect the
llvm-mca analysis.
