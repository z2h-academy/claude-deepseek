#!/usr/bin/env bash
# Pruebas del instalador. No requieren red ni una key real.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILS=0
ok()   { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILS=$((FAILS + 1)); }

export HOME="$TMP/home"
PREFIX="$TMP/prefix"
mkdir -p "$HOME" "$PREFIX"

# claude falso: el instalador y el wrapper solo necesitan que exista.
mkdir -p "$TMP/fakebin"
cat > "$TMP/fakebin/claude" <<'FAKE'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then echo "9.9.9 (Claude Code fake)"; else echo "fake claude $*"; fi
FAKE
chmod +x "$TMP/fakebin/claude"
export PATH="$TMP/fakebin:$PATH"

echo "== tests del instalador"

# 1. sintaxis
if bash -n "$REPO/install.sh"; then ok "sintaxis del instalador"; else fail "sintaxis"; fi

# 2. instalación
OUT="$(bash "$REPO/install.sh" --prefix "$PREFIX" --no-path 2>&1)"
[ -x "$PREFIX/claude-deepseek" ] && ok "instala claude-deepseek" || fail "falta claude-deepseek"
[ -x "$PREFIX/deepseek-key" ] && ok "instala deepseek-key" || fail "falta deepseek-key"
[ -x "$PREFIX/deepseek-check" ] && ok "instala deepseek-check" || fail "falta deepseek-check"
echo "$OUT" | grep -q "v1.0.0" && ok "muestra la versión" || fail "sin versión"

# 3. archivo de la key con permisos 600
ENVFILE="$HOME/.config/deepseek/claude-code.env"
[ -f "$ENVFILE" ] && ok "crea el archivo de la key" || fail "sin archivo de la key"
[ "$(stat -c '%a' "$ENVFILE" 2>/dev/null || stat -f '%Lp' "$ENVFILE")" = "600" ] \
  && ok "el archivo de la key tiene permisos 600" || fail "permisos del archivo de la key"

# 4. guardar la key
printf 'sk-fake-test\n' | "$PREFIX/deepseek-key" >/dev/null
grep -q "^DEEPSEEK_API_KEY=sk-fake-test$" "$ENVFILE" && ok "deepseek-key guarda la key" || fail "deepseek-key"

# 5. reinstalar conserva la key
bash "$REPO/install.sh" --prefix "$PREFIX" --no-path >/dev/null 2>&1
grep -q "^DEEPSEEK_API_KEY=sk-fake-test$" "$ENVFILE" && ok "reinstalar conserva la key" || fail "reinstalar borra la key"

# 6. --force reescribe vacío
bash "$REPO/install.sh" --prefix "$PREFIX" --no-path --force >/dev/null 2>&1
grep -q "^DEEPSEEK_API_KEY=$" "$ENVFILE" && ok "--force limpia la key" || fail "--force"

# 7. wrapper sin key falla con mensaje claro
OUT="$("$PREFIX/claude-deepseek" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "wrapper sin key falla" || fail "wrapper sin key no falla"
echo "$OUT" | grep -q "falta DEEPSEEK_API_KEY" && ok "mensaje de key faltante" || fail "mensaje de key faltante"

# 8. wrapper con key invoca claude con el entorno correcto
printf 'DEEPSEEK_API_KEY=sk-fake-test\n' > "$ENVFILE"
OUT="$(ANTHROPIC_API_KEY=sk-anthropic "$PREFIX/claude-deepseek" hola 2>&1)"
echo "$OUT" | grep -q "fake claude hola" && ok "wrapper ejecuta claude" || fail "wrapper no ejecuta claude"

# 9. el wrapper aísla la config de Claude Code
OUT="$(printf 'DEEPSEEK_API_KEY=sk-fake-test\n' > "$ENVFILE"; \
  cat > "$TMP/fakebin/claude" <<'FAKE2'
#!/usr/bin/env bash
echo "base=${ANTHROPIC_BASE_URL:-}"
echo "token_set=$([ -n "${ANTHROPIC_AUTH_TOKEN:-}" ] && echo si || echo no)"
echo "api_key_set=$([ -n "${ANTHROPIC_API_KEY:-}" ] && echo si || echo no)"
echo "config_dir=${CLAUDE_CONFIG_DIR:-}"
FAKE2
chmod +x "$TMP/fakebin/claude"
ANTHROPIC_API_KEY=sk-anthropic "$PREFIX/claude-deepseek" 2>&1)"
echo "$OUT" | grep -q "base=https://api.deepseek.com/anthropic" && ok "usa la base de DeepSeek" || fail "base URL"
echo "$OUT" | grep -q "token_set=si" && ok "exporta el token" || fail "token"
echo "$OUT" | grep -q "api_key_set=no" && ok "elimina ANTHROPIC_API_KEY" || fail "ANTHROPIC_API_KEY"
echo "$OUT" | grep -q "config_dir=$HOME/.config/claude-deepseek" && ok "aísla CLAUDE_CONFIG_DIR" || fail "CLAUDE_CONFIG_DIR"

# 10. script descargado y ejecutado por stdin (simula curl | bash)
OUT="$(cat "$REPO/install.sh" | bash -s -- --prefix "$TMP/prefix2" --no-path 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "funciona por stdin (curl | bash)" || fail "modo stdin (exit $RC)"
[ -x "$TMP/prefix2/claude-deepseek" ] && ok "instala en --prefix alternativo" || fail "prefix alternativo"

# 11. --check
bash "$REPO/install.sh" --prefix "$PREFIX" --no-path --check >/dev/null 2>&1 \
  && ok "--check sale con 0" || fail "--check"

# 12. --uninstall
bash "$REPO/install.sh" --prefix "$PREFIX" --uninstall >/dev/null 2>&1
[ ! -e "$PREFIX/claude-deepseek" ] && ok "--uninstall quita los binarios" || fail "--uninstall"
[ ! -e "$ENVFILE" ] && ok "--uninstall quita el archivo de la key" || fail "--uninstall key"

# 13. opción inválida
bash "$REPO/install.sh" --no-existe >/dev/null 2>&1 && fail "acepta opción inválida" || ok "rechaza opción inválida"

echo
[ "$FAILS" -eq 0 ] && { echo "tests verde"; exit 0; } || { echo "$FAILS fallas"; exit 1; }
