#!/usr/bin/env bash
# claude-deepseek — instala Claude Code configurado con DeepSeek.
#
# Uso local (clone):
#   bash install.sh
#
# Uso remoto:
#   curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash
#
# Opciones:
#   --prefix DIR      donde instalar los binarios (default: ~/.local/bin)
#   --no-path         no modificar los rc del shell
#   --force           reescribe el archivo de la key aunque exista
#   --check           solo verifica el entorno, no instala
#   --uninstall       quita los binarios y el archivo de la key
#   -h, --help        esta ayuda
set -euo pipefail

VERSION="1.0.0"
BASE_URL_DEFAULT="https://api.deepseek.com/anthropic"
MODEL_DEFAULT="deepseek-flash[1m]"
FAST_MODEL_DEFAULT="deepseek-flash"

PREFIX="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/deepseek"
ENV_FILE="${CONFIG_DIR}/claude-code.env"

WRITE_PATH=1
FORCE=0
MODE="install"

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

info() { printf '  %s\n' "$1"; }
ok()   { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
warn() { printf '  \033[33mWARN\033[0m %s\n' "$1"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)    PREFIX="${2:?falta el directorio}"; shift 2 ;;
    --no-path)   WRITE_PATH=0; shift ;;
    --force)     FORCE=1; shift ;;
    --check)     MODE="check"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "opción desconocida: $1 (usa --help)" ;;
  esac
done

# ---------------------------------------------------------------- entorno
detect_os() {
  case "$(uname -s)" in
    Linux)  echo "linux" ;;
    Darwin) echo "macos" ;;
    *)      echo "unknown" ;;
  esac
}

check_environment() {
  local os
  os="$(detect_os)"
  case "$os" in
    linux|macos) ok "sistema operativo soportado: $os" ;;
    *)           die "sistema no soportado: $(uname -s). Solo Linux y macOS." ;;
  esac

  if command -v claude >/dev/null 2>&1; then
    ok "claude disponible: $(claude --version 2>/dev/null | head -1)"
  else
    warn "claude no está en el PATH"
    info "instálalo con: curl -fsSL https://claude.ai/install.sh | bash"
  fi

  for tool in curl jq; do
    if command -v "$tool" >/dev/null 2>&1; then
      ok "$tool disponible"
    else
      warn "$tool no está disponible (necesario para deepseek-check)"
    fi
  done
}

# ---------------------------------------------------------------- archivos
write_wrapper() {
  cat > "${PREFIX}/claude-deepseek" <<'WRAPPER'
#!/usr/bin/env bash
# Lanza Claude Code contra el endpoint Anthropic de DeepSeek.
# La key se lee de ~/.config/deepseek/claude-code.env (modo 600).
#
# Variables opcionales (en el archivo de la key o en el entorno):
#   DEEPSEEK_API_KEY        obligatoria
#   DEEPSEEK_BASE_URL       default https://api.deepseek.com/anthropic
#   DEEPSEEK_MODEL          default deepseek-flash[1m]
#   DEEPSEEK_FAST_MODEL     default deepseek-flash
#   DEEPSEEK_EFFORT_LEVEL   default max
#   DEEPSEEK_CONFIG_DIR     default ~/.config/claude-deepseek
set -euo pipefail

CONFIG_DIR="${DEEPSEEK_CONFIG_DIR:-$HOME/.config/claude-deepseek}"
ENV_FILE="${DEEPSEEK_ENV_FILE:-$HOME/.config/deepseek/claude-code.env}"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  cat >&2 <<'EOF'
falta DEEPSEEK_API_KEY.

Guárdala una vez con:

  deepseek-key

o escríbela en ~/.config/deepseek/claude-code.env:

  DEEPSEEK_API_KEY=sk-...

El archivo debe tener permisos 600.
EOF
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "error: falta el CLI claude. Instálalo con:" >&2
  echo "  curl -fsSL https://claude.ai/install.sh | bash" >&2
  exit 1
fi

MODEL="${DEEPSEEK_MODEL:-deepseek-flash[1m]}"
FAST_MODEL="${DEEPSEEK_FAST_MODEL:-deepseek-flash}"

export ANTHROPIC_BASE_URL="${DEEPSEEK_BASE_URL:-https://api.deepseek.com/anthropic}"
export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
export ANTHROPIC_MODEL="$MODEL"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL"
export ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$FAST_MODEL"
export CLAUDE_CODE_SUBAGENT_MODEL="$FAST_MODEL"
export CLAUDE_CODE_EFFORT_LEVEL="${DEEPSEEK_EFFORT_LEVEL:-max}"
export CLAUDE_CODE_AUTO_COMPACT_WINDOW="${DEEPSEEK_AUTO_COMPACT_WINDOW:-786432}"

# El token de DeepSeek debe ganar sobre una key de Anthropic heredada.
unset ANTHROPIC_API_KEY

# Configuración propia: evita el conflicto con el login guardado en ~/.claude.
if [ "${DEEPSEEK_SHARED_CONFIG:-0}" != "1" ]; then
  export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$CONFIG_DIR}"
  mkdir -p "$CLAUDE_CONFIG_DIR"
fi

exec claude "$@"
WRAPPER

  cat > "${PREFIX}/deepseek-key" <<'SAVEKEY'
#!/usr/bin/env bash
# Guarda la API key de DeepSeek en un archivo con permisos 600.
# Nunca imprime la key.
set -euo pipefail

CONFIG_DIR="$HOME/.config/deepseek"
ENV_FILE="${DEEPSEEK_ENV_FILE:-$CONFIG_DIR/claude-code.env}"
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if [ -t 0 ]; then
  read -rsp "DeepSeek API key: " KEY
  echo
else
  read -r KEY
fi

if [ -z "$KEY" ]; then
  echo "key vacía: no se guardó nada" >&2
  exit 1
fi

umask 077
printf 'DEEPSEEK_API_KEY=%s\n' "$KEY" > "$ENV_FILE"
chmod 600 "$ENV_FILE"
unset KEY

echo "guardada en $ENV_FILE (permisos 600)"
echo "verifícala con: deepseek-check"
SAVEKEY

  cat > "${PREFIX}/deepseek-check" <<'CHECK'
#!/usr/bin/env bash
# Verifica la key y el endpoint de DeepSeek sin arrancar Claude Code.
set -euo pipefail

ENV_FILE="${DEEPSEEK_ENV_FILE:-$HOME/.config/deepseek/claude-code.env}"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  echo "falta DEEPSEEK_API_KEY: ejecuta deepseek-key" >&2
  exit 1
fi

BASE="${DEEPSEEK_BASE_URL:-https://api.deepseek.com/anthropic}"
MODEL="${DEEPSEEK_CHECK_MODEL:-deepseek-flash}"
TIMEOUT="${DEEPSEEK_TIMEOUT:-30}"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

HTTP="$(curl -sS --max-time "$TIMEOUT" -o "$TMP" -w '%{http_code}' "$BASE/v1/messages" \
  -H "x-api-key: $DEEPSEEK_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{\"model\":\"$MODEL\",\"max_tokens\":32,\"messages\":[{\"role\":\"user\",\"content\":\"Responde solo OK\"}]}")" || {
  echo "error: no se pudo conectar con $BASE" >&2
  exit 1
}

if [ "$HTTP" = "200" ]; then
  echo "OK: DeepSeek responde 200"
  if command -v jq >/dev/null 2>&1; then
    jq -r '"modelo: " + (.model // "?") + "\nrespuesta: " + ((.content[]? | select(.type=="text") | .text) // "(sin texto)")' "$TMP" 2>/dev/null || cat "$TMP"
  else
    cat "$TMP"
  fi
  exit 0
fi

case "$HTTP" in
  401|403) echo "FAIL: HTTP $HTTP — la key es inválida o fue revocada" >&2 ;;
  402)     echo "FAIL: HTTP 402 — la cuenta de DeepSeek no tiene saldo" >&2 ;;
  429)     echo "FAIL: HTTP 429 — límite de tasa alcanzado" >&2 ;;
  400)     echo "FAIL: HTTP 400 — nombre de modelo inválido (prueba deepseek-flash)" >&2 ;;
  *)       echo "FAIL: HTTP $HTTP" >&2 ;;
esac
if [ "${DEEPSEEK_DEBUG:-0}" = "1" ]; then
  cat "$TMP" >&2
fi
exit 1
CHECK
}

write_env_file() {
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
  if [ "$FORCE" -eq 1 ] || [ ! -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" <<'ENVFILE'
# Clave de la API de DeepSeek para Claude Code.
# Guárdala con:  deepseek-key
# Este archivo debe tener permisos 600.
DEEPSEEK_API_KEY=

# Opcionales (descomenta para cambiar el default):
# DEEPSEEK_MODEL=deepseek-flash[1m]
# DEEPSEEK_FAST_MODEL=deepseek-flash
# DEEPSEEK_BASE_URL=https://api.deepseek.com/anthropic
# DEEPSEEK_EFFORT_LEVEL=max
ENVFILE
    info "escrito $ENV_FILE (falta la key)"
  else
    info "conservado $ENV_FILE"
  fi
  chmod 600 "$ENV_FILE"
}

configure_path() {
  [ "$WRITE_PATH" -eq 1 ] || { info "PATH no modificado (--no-path)"; return; }

  for rc in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
    [ -e "$rc" ] || [ "$rc" = "$HOME/.profile" ] || continue
    if ! grep -q "HOME/.local/bin" "$rc" 2>/dev/null; then
      cat >> "$rc" <<'RC'

# ~/.local/bin (claude-deepseek, deepseek-key, deepseek-check)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
RC
      info "PATH agregado a $rc"
    fi
  done

  if command -v fish >/dev/null 2>&1; then
    local fish_conf="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$fish_conf")"
    if ! grep -q "fish_add_path.*\.local/bin" "$fish_conf" 2>/dev/null; then
      printf '\n# ~/.local/bin (claude-deepseek, deepseek-key, deepseek-check)\nfish_add_path --prepend $HOME/.local/bin\n' >> "$fish_conf"
      info "PATH agregado a $fish_conf"
    fi
  fi
}

do_install() {
  echo "== claude-deepseek v${VERSION}"
  echo
  echo "== entorno"
  check_environment
  echo
  echo "== instalación"
  mkdir -p "$PREFIX"
  write_wrapper
  chmod 755 "${PREFIX}/claude-deepseek" "${PREFIX}/deepseek-key" "${PREFIX}/deepseek-check"
  ok "binarios en $PREFIX"
  write_env_file
  configure_path
  echo
  echo "== siguiente paso"
  echo "  1. deepseek-key      # pega la key una sola vez"
  echo "  2. deepseek-check    # debe responder OK con HTTP 200"
  echo "  3. claude-deepseek   # sesión contra DeepSeek"
  echo
  info "para volver a Anthropic usa claude; el wrapper no toca el shell"
  info "recarga el shell si los comandos no aparecen: exec \$SHELL -l"
}

do_check() {
  echo "== claude-deepseek v${VERSION} — verificación"
  echo
  echo "== entorno"
  check_environment
  echo
  echo "== instalación"
  for cmd in claude-deepseek deepseek-key deepseek-check; do
    if [ -x "${PREFIX}/${cmd}" ]; then
      ok "$cmd instalado"
    else
      warn "$cmd no está en $PREFIX"
    fi
  done
  if [ -s "$ENV_FILE" ] && grep -qE '^DEEPSEEK_API_KEY=.+' "$ENV_FILE" 2>/dev/null; then
    ok "key presente en $ENV_FILE"
  else
    warn "falta la key: ejecuta deepseek-key"
  fi
}

do_uninstall() {
  echo "== desinstalación"
  for cmd in claude-deepseek deepseek-key deepseek-check; do
    if [ -e "${PREFIX}/${cmd}" ]; then
      rm -f "${PREFIX}/${cmd}"
      info "eliminado ${PREFIX}/${cmd}"
    fi
  done
  if [ -f "$ENV_FILE" ]; then
    rm -f "$ENV_FILE"
    info "eliminado $ENV_FILE"
  fi
  info "las líneas de PATH en los rc quedan; bórralas a mano si quieres limpiar del todo"
}

case "$MODE" in
  install)   do_install ;;
  check)     do_check ;;
  uninstall) do_uninstall ;;
esac
