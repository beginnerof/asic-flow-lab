#!/usr/bin/env python3
"""Extract a short metrics summary from OpenLane run directories."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def find_latest_run(runs_root: Path) -> Path | None:
    if not runs_root.exists():
        return None
    candidates = [p for p in runs_root.iterdir() if p.is_dir()]
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def load_metrics(run_dir: Path) -> dict:
    for name in ("metrics.json", "final/metrics.json", "reports/metrics.json"):
        p = run_dir / name
        if p.is_file():
            try:
                return json.loads(p.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
    # fallback: merge any metrics*.json under the run
    merged = {}
    for p in run_dir.rglob("metrics*.json"):
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                merged.update(data)
        except json.JSONDecodeError:
            continue
    return merged


def fmt(val) -> str:
    if val is None:
        return "n/a"
    if isinstance(val, float):
        return f"{val:.3f}"
    return str(val)


def main() -> int:
    runs_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("openlane/runs")
    run_dir = find_latest_run(runs_root)
    out = Path("docs/metrics_summary.md")
    out.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        "# OpenLane metrics summary",
        "",
        f"- runs root: `{runs_root}`",
        f"- latest run: `{run_dir if run_dir else 'not found'}`",
        "",
    ]

    if run_dir is None:
        lines.append("_No OpenLane run found. Trigger the `openlane` workflow or run locally._")
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(out.read_text())
        return 0

    m = load_metrics(run_dir)
    keys = [
        "design__instance__utilization",
        "design__instance__count",
        "design__instance__area",
        "timing__setup__ws",
        "timing__setup__tns",
        "timing__hold__ws",
        "route__drc_errors",
        "magic__drc_error",
        "magic__illegal_overlap",
        "klayout__drc_error",
        "design__die__area",
        "design__core__area",
    ]
    lines += ["| metric | value |", "|--------|-------|"]
    if m:
        for k in keys:
            if k in m:
                lines.append(f"| `{k}` | {fmt(m[k])} |")
        # dump a few more timing-related keys if present
        for k in sorted(m):
            if k.startswith("timing__") and k not in keys:
                lines.append(f"| `{k}` | {fmt(m[k])} |")
    else:
        lines.append("| _metrics.json_ | empty |")

    gds = list(run_dir.rglob("*.gds")) + list(run_dir.rglob("*.gds.gz"))
    lines += ["", "## GDS files", ""]
    if gds:
        for g in gds[:10]:
            lines.append(f"- `{g}`")
    else:
        lines.append("_No GDS found in this run._")

    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(out.read_text())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
