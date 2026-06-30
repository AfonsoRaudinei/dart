#!/usr/bin/env bash
# =============================================================================
# tool/coverage_by_module.sh — Coverage segmentado por módulo (Fase 0)
#
# Lê coverage/lcov.info e gera relatório por bounded context.
#
# Uso:
#   flutter test --coverage
#   ./tool/coverage_by_module.sh
#   ./tool/coverage_by_module.sh coverage/lcov.info docs/01_BASELINE/coverage_by_module_fase0.md
# =============================================================================

set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
OUTPUT_MD="${2:-coverage/coverage_by_module.md}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Arquivo lcov não encontrado: $LCOV_FILE" >&2
  echo "Execute: flutter test --coverage" >&2
  exit 1
fi

python3 - "$LCOV_FILE" "$OUTPUT_MD" << 'PY'
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path
from typing import Optional

lcov_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])

files = {}  # type: dict[str, tuple[int, int]]
current = None  # type: Optional[str]
lf = lh = 0

for raw in lcov_path.read_text(encoding="utf-8", errors="replace").splitlines():
    line = raw.strip()
    if line.startswith("SF:"):
        if current is not None:
            files[current] = (lf, lh)
        current = line[3:]
        lf = lh = 0
    elif line == "end_of_record":
        if current is not None:
            files[current] = (lf, lh)
        current = None
        lf = lh = 0
    elif line.startswith("LF:"):
        lf = int(line[3:])
    elif line.startswith("LH:"):
        lh = int(line[3:])

def bucket(path: str) -> str:
    p = path.replace("\\", "/")
    if "lib/modules/" in p:
        return "modules/" + p.split("lib/modules/")[1].split("/")[0]
    if "lib/core/" in p:
        return "core"
    if "lib/ui/" in p:
        return "ui"
    if "lib/app/" in p:
        return "app"
    return "other"

groups: dict[str, list[tuple[int, int]]] = defaultdict(list)
for path, (total, hit) in files.items():
    if total == 0:
        continue
    groups[bucket(path)].append((total, hit))

rows = []
global_total = global_hit = 0
for name in sorted(groups):
    total = sum(t for t, _ in groups[name])
    hit = sum(h for _, h in groups[name])
    global_total += total
    global_hit += hit
    pct = (hit / total * 100) if total else 0.0
    rows.append((name, hit, total, pct))

global_pct = (global_hit / global_total * 100) if global_total else 0.0

lines = [
    "# Coverage por Módulo — SoloForte",
    "",
    f"**Gerado:** {date.today().isoformat()}  ",
    f"**Fonte:** `{lcov_path}`  ",
    f"**Coverage global:** {global_pct:.2f}% ({global_hit}/{global_total} linhas)",
    "",
    "| Setor | Linhas cobertas | Linhas instrumentáveis | % |",
    "|---|---:|---:|---:|",
]

for name, hit, total, pct in rows:
    lines.append(f"| `{name}` | {hit} | {total} | {pct:.1f}% |")

lines.extend(
    [
        "",
        "## Leitura rápida (Fase 5)",
        "",
        "| Setor | Prioridade | Piso coverage | Mín. arquivos teste |",
        "|---|---|---:|---:|",
        "| `modules/consultoria` | P0 | 35% | 15 |",
        "| `modules/marketing` | P0 | 25% | 2 |",
        "| `modules/carteira` | P0 | 70% | 3 |",
        "| `modules/public` | P1 | 15% | 1 |",
        "",
        "- **Gate:** `./tool/test_matrix_gate.sh` (warning-only; `STRICT=1` no CI futuro).",
        "- **CI gate global:** ≥ 36,46% (`tool/coverage_gate.sh`).",
        "- **Alvo holístico Fase 5:** global ≥ 45%; meta v1.3 ≥ 55%.",
        "",
    ]
)

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text("\n".join(lines), encoding="utf-8")

print(f"Coverage global: {global_pct:.2f}% ({global_hit}/{global_total})")
print("")
print(f"{'Setor':<22} {'%':>7}  {'Hit/Total':>12}")
print("-" * 44)
for name, hit, total, pct in rows:
    print(f"{name:<22} {pct:6.1f}%  {hit:>5}/{total:<5}")
print("")
print(f"Relatório salvo em: {output_path}")
PY
