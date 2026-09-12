# 开源 ASIC 流程说明（本项目对应关系）

## 阶段一览

| # | 阶段 | 输入 | 输出 | 工具（本项目） |
|---|------|------|------|----------------|
| 1 | 功能仿真 | RTL + TB | PASS/FAIL、VCD | Icarus Verilog |
| 2 | Lint | RTL | 警告/错误列表 | Verilator `--lint-only` |
| 3 | 逻辑综合 | RTL + 时钟约束 | 门级网表、面积 | Yosys（OpenLane） |
| 4 | STA | 网表 + 库 | setup/hold 近似 | OpenROAD |
| 5 | 布局 | 网表 | 单元坐标 | OpenROAD |
| 6 | CTS | 布局结果 | 时钟树 | OpenROAD |
| 7 | 布线 | 布局+CTS | 金属连线 | OpenROAD Tritoroute |
| 8 | 提取/签核 | 版图 | DRC/LVS | Magic / Netgen / KLayout |
| 9 | 流片格式 | 版图 | GDSII | Magic/KLayout stream-out |

## 在本仓库里对应什么

- **RTL 顶层**：`rtl/aes_asic_top.v`（引脚扁平，便于 IO 约束）
- **功能对错**：`tb/tb_aes.v`（FIPS-197 C.1 加解密）
- **综合与后端配置**：`openlane/config.json`
- **引脚顺序**：`openlane/pin_order.cfg`
- **CI 轻流程**：`.github/workflows/sim.yml`
- **CI 全流程**：`.github/workflows/openlane.yml`
- **结果摘要脚本**：`scripts/extract_reports.py`

## 为什么要分层

| 层 | 目的 |
|----|------|
| L0 本机仿真 | 改 RTL 立刻知道功能有没有坏 |
| L1 push CI | 防止「只有我电脑上能过」 |
| L2 手动全流程 | GDS 很重；需要时再跑，artifacts 可给面试官看 |

## 读 metrics 时看什么

- `design__instance__count` / `area`：综合与实现后规模  
- `timing__setup__ws`（WNS）：最差 setup 松弛，负值=违例  
- `route__drc_errors` / magic DRC：版图是否干净  
- GDS 文件：最终版图数据

## 和工业流程的差距（面试诚实说法）

- sky130 是**教学开源 PDK**，不是量产工艺  
- 无完整 sign-off 工具链（PrimeTime / Calibre 等）  
- 无 DFT（scan/ATPG）、无低功耗 UPF 流程  
- 本项目证明的是：**RTL→网表→P&R→GDS 的方法学走通**，以及你会拆阶段、看报告、用 CI 做回归
