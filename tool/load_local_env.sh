#!/usr/bin/env bash
# Carrega credenciais locais para flutter run / dev scripts.
#
# Ordem (sem commitar segredos):
#   1. .env.local.json  — fonte preferida (mesma do build_testflight.sh)
#   2. .env.local       — fallback legado
#
# Uso: source "$(dirname "$0")/load_local_env.sh" && soloforte_load_local_env "$ROOT"

soloforte_load_local_env() {
  local root="${1:?root directory required}"
  local json_file="$root/.env.local.json"
  local env_file="$root/.env.local"

  SUPABASE_URL=""
  SUPABASE_ANON_KEY=""
  STADIA_API_KEY=""
  MAPTILER_API_KEY=""
  GOOGLE_WEATHER_API_KEY=""
  ENV="${ENV:-development}"

  if [ -f "$json_file" ]; then
    SUPABASE_URL="$(
      python3 -c "import json; print(json.load(open('$json_file')).get('SUPABASE_URL',''))"
    )"
    SUPABASE_ANON_KEY="$(
      python3 -c "import json; print(json.load(open('$json_file')).get('SUPABASE_ANON_KEY',''))"
    )"
    STADIA_API_KEY="$(
      python3 -c "import json; print(json.load(open('$json_file')).get('STADIA_API_KEY',''))"
    )"
    MAPTILER_API_KEY="$(
      python3 -c "import json; print(json.load(open('$json_file')).get('MAPTILER_API_KEY',''))"
    )"
    GOOGLE_WEATHER_API_KEY="$(
      python3 -c "import json; print(json.load(open('$json_file')).get('GOOGLE_WEATHER_API_KEY',''))"
    )"
    ENV="$(
      python3 -c "import json; print(json.load(open('$json_file')).get('ENV','development'))"
    )"
    echo "✅ Credenciais carregadas de .env.local.json"
  elif [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
    echo "⚠️  .env.local.json ausente — usando .env.local"
  else
    echo "❌ ERRO: crie .env.local.json (recomendado) ou .env.local em $root"
    return 1
  fi

  if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ ERRO: SUPABASE_URL ou SUPABASE_ANON_KEY vazios."
    return 1
  fi

  if [[ "$SUPABASE_URL" == *"seu-projeto.supabase.co"* ]] \
    || [[ "$SUPABASE_URL" == *"example.supabase.co"* ]]; then
    echo "❌ ERRO: SUPABASE_URL ainda é placeholder."
    echo "   Preencha .env.local.json com o projeto real (pyoejhhkjlrjijiviryq)."
    return 1
  fi

  if [[ "$SUPABASE_ANON_KEY" == *"sua-chave"* ]] \
    || [[ "$SUPABASE_ANON_KEY" == *"your-anon-key"* ]]; then
    echo "❌ ERRO: SUPABASE_ANON_KEY ainda é placeholder."
    return 1
  fi

  export SUPABASE_URL SUPABASE_ANON_KEY STADIA_API_KEY MAPTILER_API_KEY
  export GOOGLE_WEATHER_API_KEY ENV
  return 0
}
