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

¿Ya está instalado? Ver [Actualización](#actualización).

## Actualización

Repetir el instalador es suficiente. Conserva la key y reescribe el wrapper:

```bash
curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash
```

Una sesión abierta conserva el entorno con el que arrancó, así que hay que
abrir una sesión nueva de `claude-deepseek` para usar el wrapper actualizado.
Para confirmar la versión instalada sin reinstalar:

```bash
curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash -s -- --check
```

Desde un clon, `bash install.sh --check` muestra lo mismo. El primer arranque
tras actualizar puede migrar las sesiones existentes de DeepSeek a
`~/.claude/projects` (con respaldo `projects.bak.<timestamp>`). Desde 1.1.1,
`/effort` puede cambiar el nivel de esfuerzo durante la sesión.

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
CLAUDE_CODE_AUTO_COMPACT_WINDOW=786432
CLAUDE_CONFIG_DIR=~/.config/claude-deepseek
```

El esfuerzo inicial se toma de `DEEPSEEK_EFFORT_LEVEL` (default `max`) y se
pasa con el flag `--effort`. El wrapper no exporta `CLAUDE_CODE_EFFORT_LEVEL`,
así que `/effort` puede subirlo o bajarlo durante la sesión.

`CLAUDE_CONFIG_DIR` es lo que evita el aviso "Both ANTHROPIC_AUTH_TOKEN and
/login managed key set": la sesión de DeepSeek tiene su propia configuración y
plugins, y tu login de Anthropic queda intacto. Las sesiones se comparten por
defecto; ver [Sesiones](#sesiones).

Para compartir la configuración **completa** con tu Claude Code normal,
incluida la autenticación y los MCP:

```bash
DEEPSEEK_SHARED_CONFIG=1 claude-deepseek
```

No hace falta para compartir sesiones, y expone tu login de Anthropic al
proceso lanzado por DeepSeek.

## Sesiones

Ambos perfiles comparten los transcripts por defecto:

```text
~/.config/claude-deepseek/projects -> ~/.claude/projects
```

`claude --resume` y `claude-deepseek --resume` listan las mismas sesiones en
ambas direcciones. Solo se comparte `projects/`: auth, settings, servidores
MCP, plugins e historial de prompts quedan aislados.

En el primer arranque tras actualizar, las sesiones que ya existen en el perfil
DeepSeek se fusionan en `~/.claude/projects` y el directorio anterior se
conserva como `projects.bak.<timestamp>`. La migración espera si hay otra sesión
de `claude-deepseek` activa y se reintenta en el siguiente arranque.

Para volver a perfiles aislados:

```bash
DEEPSEEK_SHARE_SESSIONS=0 claude-deepseek
```

Si el symlink de compartición ya existe, el siguiente arranque lo retira. Los
transcripts quedan en `~/.claude/projects` y el perfil DeepSeek empieza con el
historial vacío; las sesiones previas a la migración siguen en
`projects.bak.<timestamp>` si ese respaldo se creó.

Advertencias:

- Al reanudar una sesión bajo DeepSeek, todo su historial se envía a DeepSeek.
- No conviene reanudar la misma sesión en ambos perfiles al mismo tiempo.
- La sesión reanudada usa los MCP, plugins y settings del perfil que la abre.
- Si el endpoint de DeepSeek rechaza un transcript con bloques específicos del
  proveedor, esa sesión se puede continuar con `claude`.

## Personalización

Los cambios van en `~/.config/deepseek/claude-code.env`:

```bash
DEEPSEEK_MODEL=deepseek-v4-pro
DEEPSEEK_FAST_MODEL=deepseek-flash
DEEPSEEK_BASE_URL=https://api.deepseek.com/anthropic
DEEPSEEK_EFFORT_LEVEL=high   # esfuerzo inicial; /effort puede cambiarlo
DEEPSEEK_SHARE_SESSIONS=0   # aislar las sesiones
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
| `/effort` no cambia el nivel | wrapper anterior exportaba `CLAUDE_CODE_EFFORT_LEVEL` | reinstalar (1.1.1+) |
| Aviso de dos credenciales | configuración compartida | dejar `CLAUDE_CONFIG_DIR` como está, o `claude /logout` |
| Las sesiones no aparecen en `claude-deepseek --resume` | perfil creado antes de 1.1.0 | reinstalar y arrancar una vez; el perfil se migra |
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
