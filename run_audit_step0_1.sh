echo "=== STEP 0: ARQUIVOS CRÍTICOS ==="
find lib/ -name "private_map_screen.dart"
find lib/ -name "private_map_sheets.dart"
find lib/ -name "app_shell.dart"
find lib/ -name "smart_button.dart"

echo "=== MÓDULO AGENDA ==="
find lib/ -path "*/agenda*" -name "*.dart" | sort || true

echo "=== MÓDULOS DE RELATÓRIO ==="
find lib/ -path "*/relatorio*" -name "*.dart" | sort || true

echo "=== CONTROLLERS ==="
find lib/ -name "*controller*.dart" -o -name "*Controller*.dart" | sort || true

echo "=== IMPRESSÕES DE DEPURAÇÃO ==="
grep -rn "^\s*print(" lib/ --include="*.dart" | head -20 || true
