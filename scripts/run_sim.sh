#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p sim
iverilog -g2001 -o sim/tb_aes.vvp \
  rtl/aes_core.v rtl/aes_mmio.v rtl/cryptocore_top.v tb/tb_aes.v
cd sim && vvp tb_aes.vvp
