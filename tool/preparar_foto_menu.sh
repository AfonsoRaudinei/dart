#!/bin/bash
# Prepara uma foto (HEIC/JPG/PNG) como foto do dia no cabeçalho do menu.
#
# Uso: ./tool/preparar_foto_menu.sh "<arquivo>" <seg|ter|qua|qui|sex|sab|dom> [offset_topo_%]
#   offset_topo_%: onde começa o recorte na vertical (0 = topo, 50 = meio).
#                  Padrão 35 — pega céu + horizonte + lavoura.
# Saída: assets/images/menu/dia_<dia>.jpg (900 px de largura, faixa 5:3, ~100-200 KB)
set -euo pipefail

SRC="${1:?informe o arquivo}"
DIA="${2:?informe o dia: seg|ter|qua|qui|sex|sab|dom}"
OFFSET="${3:-35}"
case "$DIA" in seg|ter|qua|qui|sex|sab|dom) ;; *) echo "dia inválido: $DIA"; exit 1;; esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -t fotomenu).jpg"
# HEIC → JPEG (sips é nativo do macOS)
sips -s format jpeg -Z 2400 "$SRC" --out "$TMP" >/dev/null

python3 - "$TMP" "$ROOT/assets/images/menu/dia_${DIA}.jpg" "$OFFSET" <<'PY'
import sys
from PIL import Image, ImageOps
src, dst, off = sys.argv[1], sys.argv[2], float(sys.argv[3]) / 100
im = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
w, h = im.size
ch = int(w * 0.60)                      # faixa 5:3
top = int(max(0, min(h - ch, (h - ch) * off)))
im = im.crop((0, top, w, top + ch)).resize((900, int(900 * ch / w)))
im.save(dst, "JPEG", quality=72, optimize=True)
print(f"ok: {dst} ({im.size[0]}x{im.size[1]})")
PY
rm -f "$TMP"
