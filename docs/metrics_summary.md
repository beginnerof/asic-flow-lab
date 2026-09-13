# OpenLane metrics summary

Source run: [34697562747](https://github.com/beginnerof/asic-flow-lab/actions/runs/34697562747)  
Run dir: `RUN_2026-09-12_13-53-58` · LibreLane 3.0.14 · sky130A · `CLOCK_PERIOD=40 ns` · wall ~1h06m

## Headline

| metric | value |
|--------|-------|
| Die area | 695436 µm²（约 0.695 mm²，828.6 × 839.3 µm） |
| Core area | 667015 µm² |
| Utilization | 60.0 % |
| Stdcell count | 71057（含 fill/tap/antenna 前的逻辑规模） |
| Sequential cells | 1939 |
| Combinational cells | 18086 |
| Setup worst slack | +5.684 ns（period 40 ns → 约 29 MHz 仍正裕量） |
| Setup WNS / TNS | 0 / 0（无 setup 违例） |
| Hold worst slack | +0.110 ns |
| Hold violations | 0 |
| Route DRC errors | 0 |
| Magic DRC / KLayout DRC | 0 / 0 |
| LVS errors | 0 |
| Antenna violations | 0 |
| GDS | `final/gds/aes_asic_top.gds` |

## 说明

- `design__instance__count=152707` 含 fill/tap/antenna 单元，简历请用 **stdcell 71057** 或 **逻辑组合+时序单元数**。
- Setup 裕量在 40 ns 约束下很充足；若提频可把 `CLOCK_PERIOD` 降到约 34 ns 再跑一轮观察。
- 完整 corner 表与 GDS 见 Actions artifact `openlane-asic-flow-lab`。
