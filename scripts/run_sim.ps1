# Local simulation helper (Windows PowerShell)
# Requires Icarus Verilog on PATH (iverilog / vvp)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

New-Item -ItemType Directory -Force sim | Out-Null

$rtl = @(
  'rtl/aes_core.v',
  'rtl/aes_mmio.v',
  'rtl/cryptocore_top.v'
)

iverilog -g2001 -o sim/tb_aes.vvp @rtl tb/tb_aes.v
Push-Location sim
vvp tb_aes.vvp
Pop-Location
