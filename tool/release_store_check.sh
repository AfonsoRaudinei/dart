#!/usr/bin/env bash
# =============================================================================
# tool/release_store_check.sh — SoloForte Store Release Preflight
#
# Valida artefatos de privacidade iOS e permissão Android SCHEDULE_EXACT_ALARM
# antes de archive IPA ou upload Play Console.
#
# Uso:
#   ./tool/release_store_check.sh
#   ./tool/release_store_check.sh path/to/app.ipa
#
# Exit 0 → preflight conforme
# Exit 1 → bloqueador detectado
# =============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VIOLATIONS=0
WARNINGS=0

pass() { echo -e "  ${GREEN}✅ PASS${NC}  $1"; }
fail() { echo -e "  ${RED}❌ FAIL${NC}  $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
warn() { echo -e "  ${YELLOW}⚠️  WARN${NC}  $1"; WARNINGS=$((WARNINGS + 1)); }
info() { echo -e "  ${CYAN}ℹ️  INFO${NC}  $1"; }

# macOS: plutil. Linux/CI: plistlib (plutil ausente — falso FAIL em Cloud Agent).
sf_plutil_lint() {
  local f="$1"
  if command -v plutil >/dev/null 2>&1; then
    plutil -lint "$f" >/dev/null 2>&1
    return $?
  fi
  python3 -c "import plistlib,sys; plistlib.load(open(sys.argv[1],'rb'))" "$f" >/dev/null 2>&1
}

sf_plutil_extract_raw() {
  local f="$1"
  local key="$2"
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$key" raw -o - "$f" 2>/dev/null || echo "MISSING"
    return 0
  fi
  python3 - <<'PY' "$f" "$key"
import plistlib, sys
path, key = sys.argv[1], sys.argv[2]
try:
    data = plistlib.load(open(path, "rb"))
except OSError:
    print("MISSING")
    raise SystemExit
val = data.get(key, "MISSING")
if val is True:
    print("true")
elif val is False:
    print("false")
else:
    print(val)
PY
}

sf_plutil_json_contains() {
  local f="$1"
  local plist_key="$2"
  local needle="$3"
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$plist_key" json -o - "$f" 2>/dev/null | rg -q "$needle"
    return $?
  fi
  python3 - <<'PY' "$f" "$plist_key" "$needle"
import json, plistlib, sys
path, plist_key, needle = sys.argv[1], sys.argv[2], sys.argv[3]
data = plistlib.load(open(path, "rb"))
blob = json.dumps(data.get(plist_key, []))
sys.exit(0 if needle in blob else 1)
PY
}

sf_plutil_has_key() {
  local f="$1"
  local key="$2"
  if command -v plutil >/dev/null 2>&1; then
    plutil -extract "$key" raw -o - "$f" >/dev/null 2>&1
    return $?
  fi
  python3 - <<'PY' "$f" "$key"
import plistlib, sys
data = plistlib.load(open(sys.argv[1], "rb"))
raise SystemExit(0 if sys.argv[2] in data else 1)
PY
}

PRIVACY_MANIFEST="$ROOT/ios/Runner/PrivacyInfo.xcprivacy"
INFO_PLIST="$ROOT/ios/Runner/Info.plist"
PBXPROJ="$ROOT/ios/Runner.xcodeproj/project.pbxproj"
ANDROID_MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
AGENDA_NOTIFICATION="$ROOT/lib/modules/agenda/data/services/agenda_notification_service.dart"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SoloForte — Store Release Preflight (Privacy + Alarm)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

# ── iOS: PrivacyInfo.xcprivacy ───────────────────────────────────────────────
echo ""
echo -e "── ${CYAN}iOS${NC} PrivacyInfo.xcprivacy ─────────────────────────────────"

if [[ ! -f "$PRIVACY_MANIFEST" ]]; then
  fail "Arquivo ausente: ios/Runner/PrivacyInfo.xcprivacy"
else
  pass "Arquivo presente"
  if sf_plutil_lint "$PRIVACY_MANIFEST"; then
    pass "plist lint PrivacyInfo.xcprivacy"
  else
    fail "plist lint PrivacyInfo.xcprivacy"
  fi
fi

if [[ -f "$PBXPROJ" ]] && rg -q "PrivacyInfo.xcprivacy in Resources" "$PBXPROJ"; then
  pass "PrivacyInfo incluído no target Runner (Resources)"
else
  fail "PrivacyInfo.xcprivacy não está em Copy Bundle Resources do Runner"
fi

if [[ -f "$PRIVACY_MANIFEST" ]]; then
  if [[ "$(sf_plutil_extract_raw "$PRIVACY_MANIFEST" NSPrivacyTracking)" == "false" ]]; then
    pass "NSPrivacyTracking = false"
  else
    fail "NSPrivacyTracking deve ser false"
  fi

  if sf_plutil_json_contains "$PRIVACY_MANIFEST" NSPrivacyAccessedAPITypes NSPrivacyAccessedAPICategoryUserDefaults; then
    pass "Required Reason API: UserDefaults (CA92.1)"
  else
    fail "NSPrivacyAccessedAPITypes sem UserDefaults — revisar CA92.1"
  fi

  if sf_plutil_json_contains "$PRIVACY_MANIFEST" NSPrivacyAccessedAPITypes NSPrivacyAccessedAPICategoryFileTimestamp; then
    pass "Required Reason API: FileTimestamp (C617.1)"
  else
    fail "NSPrivacyAccessedAPITypes sem FileTimestamp — revisar C617.1"
  fi

  COLLECTED_COUNT=$(python3 - <<'PY' "$PRIVACY_MANIFEST"
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    data = plistlib.load(f)
print(len(data.get("NSPrivacyCollectedDataTypes", [])))
PY
)
  if [[ "${COLLECTED_COUNT:-0}" -ge 5 ]]; then
    pass "NSPrivacyCollectedDataTypes declarados ($COLLECTED_COUNT entradas)"
  else
    warn "NSPrivacyCollectedDataTypes com poucas entradas — alinhar com docs/store/APP_PRIVACY_APPLE.md"
  fi
fi

# ── iOS: Info.plist ───────────────────────────────────────────────────────────
echo ""
echo -e "── ${CYAN}iOS${NC} Info.plist ───────────────────────────────────────────────"

if [[ ! -f "$INFO_PLIST" ]]; then
  fail "Info.plist ausente"
else
  if sf_plutil_lint "$INFO_PLIST"; then
    pass "plist lint Info.plist"
  else
    fail "plist lint Info.plist"
  fi

  ENCRYPTION=$(sf_plutil_extract_raw "$INFO_PLIST" ITSAppUsesNonExemptEncryption)
  if [[ "$ENCRYPTION" == "false" ]]; then
    pass "ITSAppUsesNonExemptEncryption = false"
  else
    fail "ITSAppUsesNonExemptEncryption deve ser false (valor: $ENCRYPTION)"
  fi

  for KEY in NSLocationWhenInUseUsageDescription NSCameraUsageDescription NSPhotoLibraryUsageDescription; do
    if sf_plutil_has_key "$INFO_PLIST" "$KEY"; then
      pass "Usage description: $KEY"
    else
      warn "Usage description ausente: $KEY"
    fi
  done
fi

# ── Android: SCHEDULE_EXACT_ALARM ────────────────────────────────────────────
echo ""
echo -e "── ${CYAN}Android${NC} SCHEDULE_EXACT_ALARM ─────────────────────────────────"

if [[ ! -f "$ANDROID_MANIFEST" ]]; then
  fail "AndroidManifest.xml ausente"
elif rg -q 'android:name="android.permission.SCHEDULE_EXACT_ALARM"' "$ANDROID_MANIFEST"; then
  pass "Permissão SCHEDULE_EXACT_ALARM declarada no manifest"
else
  fail "SCHEDULE_EXACT_ALARM ausente em android/app/src/main/AndroidManifest.xml"
fi

if [[ -f "$AGENDA_NOTIFICATION" ]]; then
  if rg -q "inexactAllowWhileIdle" "$AGENDA_NOTIFICATION"; then
    pass "AgendaNotificationService: fallback inexactAllowWhileIdle"
  else
    fail "AgendaNotificationService sem fallback inexact — revisar _androidScheduleMode()"
  fi

  if rg -q "canScheduleExactNotifications" "$AGENDA_NOTIFICATION"; then
    pass "AgendaNotificationService: checagem canScheduleExactNotifications()"
  else
    fail "AgendaNotificationService sem checagem de exact alarms"
  fi
else
  fail "AgendaNotificationService não encontrado"
fi

if [[ -f "$ROOT/docs/android/SCHEDULE_EXACT_ALARM_PLAY_CONSOLE.md" ]]; then
  pass "Documentação Play Console presente"
else
  warn "docs/android/SCHEDULE_EXACT_ALARM_PLAY_CONSOLE.md ausente"
fi

# ── IPA opcional ─────────────────────────────────────────────────────────────
IPA_PATH="${1:-}"
if [[ -n "$IPA_PATH" ]]; then
  echo ""
  echo -e "── ${CYAN}IPA${NC} bundle check ────────────────────────────────────────────"

  if [[ ! -f "$IPA_PATH" ]]; then
    fail "IPA não encontrado: $IPA_PATH"
  else
    IPA_TMP=$(mktemp -d)
    trap 'rm -rf "$IPA_TMP"' EXIT
    unzip -q "$IPA_PATH" -d "$IPA_TMP"

    IPA_PRIVACY=$(find "$IPA_TMP/Payload" -name "PrivacyInfo.xcprivacy" -print -quit)
    if [[ -n "$IPA_PRIVACY" ]]; then
      pass "PrivacyInfo.xcprivacy presente no bundle IPA"
      if sf_plutil_lint "$IPA_PRIVACY"; then
        pass "plist lint PrivacyInfo no IPA"
      else
        fail "PrivacyInfo no IPA inválido"
      fi
    else
      fail "PrivacyInfo.xcprivacy ausente no bundle IPA"
    fi

    IPA_INFO=$(find "$IPA_TMP/Payload" -name "Info.plist" -path "*/Runner.app/Info.plist" -print -quit)
    if [[ -n "$IPA_INFO" ]]; then
      IPA_ENC=$(sf_plutil_extract_raw "$IPA_INFO" ITSAppUsesNonExemptEncryption)
      if [[ "$IPA_ENC" == "false" ]]; then
        pass "IPA ITSAppUsesNonExemptEncryption = false"
      else
        fail "IPA ITSAppUsesNonExemptEncryption incorreto ($IPA_ENC)"
      fi
    fi
  fi
fi

# ── Resumo ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
if [[ "$VIOLATIONS" -eq 0 ]]; then
  echo -e "${GREEN}  ✅ APROVADO — Store preflight conforme${NC}"
  if [[ "$WARNINGS" -gt 0 ]]; then
    info "$WARNINGS aviso(s) — revisar antes do upload"
  fi
  echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
  exit 0
fi

echo -e "${RED}  ❌ REPROVADO — $VIOLATIONS bloqueador(es)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
exit 1
