#!/usr/bin/env bash
set -euo pipefail

LLVM_MCA=/tmp/aditipandey/ascalon-vector-work/llvm-project/build/bin/llvm-mca
BASE=/tmp/aditipandey/RISC-V-CodeGen-aditi

declare -A VL
VL[dotprod_]=8
VL[relu_]=8
VL[softmax_]=8
VL[gemm_]=8
VL[vector_mac]=8
VL[gather_op]=1
VL[spmv_csr]=8          # fixed to use gather VL=8
VL[reduction_loop]=1    # effectively scalar after fixes
VL[tridiag_solve]=1
VL[montecarlo_pi]=1     # effectively scalar after fixes

kernels="dotprod_ relu_ softmax_ gemm_ vector_mac gather_op spmv_csr reduction_loop tridiag_solve montecarlo_pi"

echo "Kernel,ScalarCycles,VecCycles,VL,VecCycles_per_elem,Speedup"

for K in $kernels; do
  cd "$BASE/$K"

  scalar_s=test_rv64gc.s
  vector_s=test_riscv.s

  "$LLVM_MCA" -mtriple=riscv64-unknown-elf -mcpu=tt-ascalon-x \
    "$scalar_s" > core_scalar.mca.txt

  "$LLVM_MCA" -mtriple=riscv64-unknown-elf -mcpu=tt-ascalon-x \
    "$vector_s" > core_vec.mca.txt

  scalar=$(grep "Total Cycles" core_scalar.mca.txt | awk '{print $3}')
  vec=$(grep "Total Cycles" core_vec.mca.txt    | awk '{print $3}')
  vl=${VL[$K]}

  vec_per_elem=$(echo "scale=6; $vec/$vl" | bc -l)
  speedup=$(echo "scale=4; $scalar/$vec_per_elem" | bc -l)

  echo "$K,$scalar,$vec,$vl,$vec_per_elem,$speedup"
done
