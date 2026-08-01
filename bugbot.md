# Bugbot — relatório de bugs

**Data:** 2026-08-01  
**Escopo:** security + bugbot fixes  
**Resultado:** corrigidos

| Severity | Location | Finding | Status |
|---|---|---|---|
| low | `append_rules.py:1` | Script truncado/corrompido | corrigido (deletado) |
| low | `marketing_antes_depois.html:637` | `onerror` apagava label Antes/Depois | corrigido |
| medium | `marketing_html_renderer.dart` | XSS em URLs de foto exportadas | corrigido (`sanitizePhotoSrc`) |
