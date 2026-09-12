# asic-flow-lab — AES-128 开源 ASIC 全流程

把已验证的 **AES-128 迭代加解密核** 用开源工具链从 **RTL 跑通到 GDSII** 的作品集项目。

设计源与 [rv32i-cryptocore](https://github.com/beginnerof/rv32i-cryptocore) 同源（本仓自包含拷贝，便于单独投递）。

> 本地仿真：`make test` 输出 `ENCRYPT PASS` / `DECRYPT PASS` / `PASS`（NIST FIPS-197 C.1）。  
> 开源 ASIC 全流程（LibreLane + sky130A）已在 GitHub Actions **成功跑通 RTL→GDS**（约 1h06m）：  
> https://github.com/beginnerof/asic-flow-lab/actions/runs/34697562747

## English Abstract

A portfolio **open-source ASIC flow lab** hardening an iterative AES-128 encrypt/decrypt core (same RTL family as `rv32i-cryptocore`) from RTL to GDSII. Functional simulation uses Icarus Verilog with a self-checking NIST FIPS-197 C.1 testbench. The full LibreLane (successor of OpenLane 2) / sky130A flow (Yosys synthesis, OpenROAD place-and-route, Magic/KLayout DRC, GDS) run in GitHub Actions; local machines only need Icarus for the fast regression. The top-level `aes_asic_top` exposes a flat 32-bit MMIO interface for pin placement. Clock target starts at 25 MHz for first-pass closure; metrics and GDS are published as workflow artifacts.

### Resume bullets (replace numbers after CI)

1. Hardened an iterative AES-128 encrypt/decrypt core through an open-source ASIC flow (Icarus sim → LibreLane/Yosys/OpenROAD + sky130A) from RTL to GDSII; FIPS-197 C.1 encrypt/decrypt self-check passes.
2. Built `aes_asic_top` with a flat MMIO pin map, clock constraints, and automated report extraction (`metrics.json` → area / DRC / timing summary) in GitHub Actions.
3. Separated a three-layer flow: local Icarus regression, push-time lint/sim CI, and manual-trigger full RTL-to-GDS run with uploaded GDS and metrics artifacts.

---

## 1. 流程分层

| 层 | 内容 | 工具 | 跑在哪 |
|----|------|------|--------|
| L0 | AES FIPS-197 功能仿真 | Icarus Verilog | **本机**（Windows/Linux） |
| L1 | 回归 + Lint | iverilog / verilator | **GitHub Actions**（每次 push） |
| L2 | 综合 → P&R → DRC → GDS | LibreLane + sky130A | **Actions 手动触发** 或本机 Docker |

```text
RTL (aes_asic_top)
   │
   ├─ L0  iverilog + tb_aes.v          → PASS
   ├─ L1  verilator --lint-only        → CI
   └─ L2  LibreLane Classic
            Yosys 综合
            OpenROAD 布局 / CTS / 布线
            Magic + KLayout DRC / LVS
            → GDS + metrics
```

## 2. 目录

```text
rtl/          AES 核 + MMIO + aes_asic_top
tb/           FIPS-197 自检 testbench
openlane/     config.json + pin_order.cfg
scripts/      run_sim.ps1 / run_sim.sh / extract_reports.py
docs/         flow.md  metrics_summary.md
.github/      sim.yml  openlane.yml
```

## 3. 本地仿真（L0）

依赖：Icarus Verilog ≥ 11。

```bash
make test
```

Windows PowerShell：

```powershell
.\scripts\run_sim.ps1
```

预期：

```text
ENCRYPT PASS
DECRYPT PASS
PASS
```

## 4. CI（L1）

推送后 `sim.yml` 会安装 iverilog 并执行 `make test`，必须打出 `PASS`。

可选本地 lint（需 Verilator）：

```bash
make lint
```

## 5. LibreLane 全流程（L2）

### GitHub Actions（推荐，本机零安装）

1. Fork / 推送本仓库  
2. Actions → **openlane** → **Run workflow**  
3. 可改 `clock_period`（默认 40 ns ≈ 25 MHz）  
4. 结束后下载 artifact：`metrics-summary`（小，优先）或 `openlane-asic-flow-lab`（含 GDS，较大）  
5. 把 `docs/metrics_summary.md` 里的真实数字写回 README

### 本机 Docker（可选）

需要 Docker Desktop。示例：

```bash
python3 -m pip install --upgrade librelane
python3 -m librelane --dockerized openlane/config.json
```

LibreLane 会自动拉镜像并首次下载 sky130A PDK，请预留磁盘与时间。

### 配置要点

| 项 | 值 | 说明 |
|----|-----|------|
| DESIGN_NAME | `aes_asic_top` | 顶层 |
| CLOCK_PORT | `clk` | |
| CLOCK_PERIOD | 40.0 ns | 25 MHz，优先收敛；结果见 metrics |
| PDK | sky130A | |
| STD_CELL_LIBRARY | sky130_fd_sc_hd | |

## 6. 寄存器图（与 cryptocore 一致）

| 偏移 | 名称 | 属性 | 说明 |
|------|------|------|------|
| 0x00 | CTRL | WO | [0] start（自清） [1] decrypt |
| 0x04 | STATUS | RW | [0] busy [1] done（写 1 清） |
| 0x08..0x14 | KEY0..3 | RW | KEY0 = 密钥高 32 位 |
| 0x18..0x24 | DIN0..3 | RW | 明文/密文 |
| 0x28..0x34 | DOUT0..3 | RO | 结果 |
| 0x38 | VERSION | RO | `0x0001_0000` |

字节序与 FIPS-197 一致：128-bit 字最高字节为 FIPS byte 0。

## 7. 结果怎么读

见 [docs/flow.md](docs/flow.md) 与 CI 生成的 [docs/metrics_summary.md](docs/metrics_summary.md)。

面试常问：

1. 迭代 AES vs 全展开：面积 / 吞吐 / 频率折中  
2. 为何先低频（40 ns）再提频：保证 P&R 收敛，再优化关键路径  
3. LibreLane 里综合、布局、CTS、布线分别解决什么问题  
4. DRC/LVS 失败和时序失败处理方式不同  
5. sky130 教学 PDK 与工业 PDK 的差距（库特性、工具、签核深度）

## 8. 与其它仓库的关系

```text
rv32i-minisoc     系统级 SoC
axi4lite-regip    标准总线从机
rv32i-cryptocore  AES 协处理器功能验证
asic-flow-lab     同源 AES 的 ASIC 流程硬化（本仓）
```

## 9. License

MIT — 见 [LICENSE](LICENSE)。

RTL 起源自本人 `rv32i-cryptocore`（MIT）。
