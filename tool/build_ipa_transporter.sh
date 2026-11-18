#!/usr/bin/env bash
# SoloForte — archive iOS + cópia nomeada para o Transporter (~/Desktop).
# Uso: ./tool/build_ipa_transporter.sh [build_number]
# Ex.: ./tool/build_ipa_transporter.sh 339
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ ERRO: archive IPA exige macOS + Xcode (ambiente: $(uname -s))."
  exit 1
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

BUILD_NUM="${1:-}"
if [[ -z "$BUILD_NUM" ]]; then
  BUILD_NUM="$(grep '^version:' "$ROOT/pubspec.yaml" | sed 's/.*+//')"
fi

PUB_BUILD="$(grep '^version:' "$ROOT/pubspec.yaml" | sed 's/.*+//')"
if [[ "$PUB_BUILD" != "$BUILD_NUM" ]]; then
  echo "❌ pubspec build ($PUB_BUILD) ≠ solicitado ($BUILD_NUM). Ajuste pubspec ou argumento."
  exit 1
fi

if [[ ! -f "$ROOT/.env.local.json" ]]; then
  echo "❌ .env.local.json ausente na raiz do projeto."
  exit 1
fi

echo "📦 Train 1.36.0+$BUILD_NUM — sync + archive..."
git fetch origin
git checkout main
git pull origin main
flutter pub get

./tool/arch_check.sh
./build_testflight.sh

IPA_SRC="$ROOT/build/ios/ipa/soloforte_app.ipa"
if [[ ! -f "$IPA_SRC" ]]; then
  IPA_SRC="$(find "$ROOT/build/ios/ipa" -maxdepth 1 -name '*.ipa' | head -n 1)"
fi
if [[ -z "$IPA_SRC" || ! -f "$IPA_SRC" ]]; then
  echo "❌ IPA não encontrado em build/ios/ipa/"
  exit 1
fi

./tool/release_store_check.sh "$IPA_SRC"

DESKTOP_IPA="$HOME/Desktop/soloforte_app_${BUILD_NUM}.ipa"
cp "$IPA_SRC" "$DESKTOP_IPA"

VERIFY_DIR="$(mktemp -d)"
unzip -q "$DESKTOP_IPA" -d "$VERIFY_DIR"
RUNNER_PLIST="$VERIFY_DIR/Payload/Runner.app/Info.plist"
SHORT_VER="$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$RUNNER_PLIST")"
BUNDLE_VER="$(/usr/bin/plutil -extract CFBundleVersion raw -o - "$RUNNER_PLIST")"
rm -rf "$VERIFY_DIR"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ IPA pronto para o Transporter"
echo "   Arquivo : $DESKTOP_IPA"
echo "   Versão  : ${SHORT_VER}+${BUNDLE_VER}"
echo "   Projeto : $IPA_SRC"
echo ""
echo "   App Store Connect → Transporter → enviar soloforte_app_${BUILD_NUM}.ipa"
echo "   (403 = contratos Apple pendentes — ver AGENTIPA.md)"
echo "═══════════════════════════════════════════════════════════════"