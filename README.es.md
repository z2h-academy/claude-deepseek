# claude-deepseek

> Ejecuta [Claude Code](https://claude.com/claude-code) contra el endpoint
> compatible con Anthropic de DeepSeek, sin tocar el login que ya tengas.

Un solo comando instala tres ayudantes en `~/.local/bin`:

| Comando | Qué hace |
|---|---|
| `claude-deepseek` | abre Claude Code apuntando a DeepSeek |
| `deepseek-key` | guarda la API key con permisos `600` |
| `deepseek-check` | verifica la key contra la API, sin abrir Claude Code |

Soportado: **Linux** y **macOS**, con bash, zsh o fish.

---

## Instalación

### Una línea

```bash
curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash
```

### Desde un clon (recomendado para revisar)

```bash
git clone https://github.com/z2h-academy/claude-deepseek.git
cd claude-deepseek
less install.sh          # léelo primero
bash install.sh
```

### Fijar una versión

```bash
curl -fsSLO https://github.com/z2h-academy/claude-deepseek/releases/download/v1.0.0/install.sh
curl -fsSLO https://github.com/z2h-academy/claude-deepseek/releases/download/v1.0.0/install.sh.sha256
sha256sum -c install.sh.sha256    # macOS: shasum -a 256 -c install.sh.sha256
bash install.sh
```

## Configuración

```bash
deepseek-key      # pega la key cuando la pida (la entrada no se muestra)
deepseek-check    # debe responder OK con HTTP 200
claude-deepseek   # abre una sesión
```

Consigue una key en <https://platform.deepseek.com/api_keys>. Se guarda en
`~/.config/deepseek/claude-code.env` con permisos `600` y nunca se imprime.

Si los comandos no aparecen, recarga el shell (`exec $SHELL -l`) o usa la ruta
completa: `~/.local/bin/claude-deepseek`.

## Qué configura

El wrapper exporta estas variables solo en su propio proceso:

```text
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=<tu key>
ANTHROPIC_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-flash
CLAUDE_CODE_EFFORT_LEVEL=max
CLAUDE_CODE_AUTO_COMPACT_WINDOW=786432
CLAUDE_CONFIG_DIR=~/.config/claude-deepseek
```

`CLAUDE_CONFIG_DIR` es lo que evita el aviso "Both ANTHROPIC_AUTH_TOKEN and
/login managed key set": la sesión de DeepSeek tiene su propia configuración,
historial y plugins, y tu login de Anthropic queda intacto.

Para compartir la configuración con tu Claude Code normal:

```bash
DEEPSEEK_SHARED_CONFIG=1 claude-deepseek
```

## Personalización

Los cambios van en `~/.config/deepseek/claude-code.env`:

```bash
DEEPSEEK_MODEL=deepseek-v4-pro
DEEPSEEK_FAST_MODEL=deepseek-flash
DEEPSEEK_BASE_URL=https://api.deepseek.com/anthropic
DEEPSEEK_EFFORT_LEVEL=high
```

## Volver a Anthropic

```bash
claude
```

El wrapper no modifica el shell: las variables viven solo dentro del proceso de
`claude-deepseek`.

## Opciones

```bash
bash install.sh --prefix ~/bin      # instalar en otro directorio
bash install.sh --no-path           # no tocar los archivos de inicio del shell
bash install.sh --force             # reescribir el archivo de la key (lo vacía)
bash install.sh --check             # informar qué está instalado
bash install.sh --uninstall         # quitar binarios y archivo de la key
```

## Requisitos

- Claude Code instalado (`curl -fsSL https://claude.ai/install.sh | bash`).
  El instalador avisa si falta; el wrapper no arranca sin él.
- `curl` para `deepseek-check`. `jq` es opcional y solo embellece la salida.

## Problemas frecuentes

| Síntoma | Causa | Arreglo |
|---|---|---|
| `falta DEEPSEEK_API_KEY` | no se guardó la key | `deepseek-key` |
| `HTTP 401` | key inválida o revocada | crear una key nueva |
| `HTTP 402` | sin saldo | recargar la cuenta de DeepSeek |
| `HTTP 400` | nombre de modelo incorrecto | usar `deepseek-flash` |
| `zsh: no matches found` | `[1m]` sin comillas | mantener `DEEPSEEK_MODEL='deepseek-flash[1m]'` |
| Aviso de dos credenciales | configuración compartida | dejar `CLAUDE_CONFIG_DIR` como está, o `claude /logout` |
| Los comandos no aparecen | shell sin recargar | `exec $SHELL -l` |

## Desinstalación

```bash
bash install.sh --uninstall
```

Después, borra las líneas de `~/.local/bin` de los archivos de inicio del shell
si quieres una limpieza completa.

## Pruebas

```bash
bash tests/run-tests.sh
```

No necesitan red ni una key real: usan un binario `claude` falso.

## Relación con otros repos

`scripts/install-claude-deepseek.sh` en
[z2h-academy/tutor-internal](https://github.com/z2h-academy/tutor-internal) es
la copia interna que usa el contenedor de Z2H Academy. Este repositorio es la
versión pública e independiente.

## Licencia

MIT
