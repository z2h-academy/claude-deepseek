# claude-deepseek

> Run [Claude Code](https://claude.com/claude-code) on DeepSeek's Anthropic-compatible endpoint, without touching a login you may already have.

One command installs three small helpers in `~/.local/bin`:

| Command | What it does |
|---|---|
| `claude-deepseek` | starts Claude Code pointed at DeepSeek |
| `deepseek-key` | stores the API key with `600` permissions |
| `deepseek-check` | checks the key against the API (no Claude Code involved) |

Supported: **Linux** and **macOS**, with bash, zsh or fish.

---

## Install

### One line

```bash
curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash
```

### From a clone (recommended for review)

```bash
git clone https://github.com/z2h-academy/claude-deepseek.git
cd claude-deepseek
less install.sh          # read it first
bash install.sh
```

### Pin a version

```bash
curl -fsSLO https://github.com/z2h-academy/claude-deepseek/releases/download/v1.0.0/install.sh
curl -fsSLO https://github.com/z2h-academy/claude-deepseek/releases/download/v1.0.0/install.sh.sha256
sha256sum -c install.sh.sha256    # macOS: shasum -a 256 -c install.sh.sha256
bash install.sh
```

Already installed? See [Updating](#updating).

## Updating

Rerun the installer. It preserves the key and rewrites the wrapper:

```bash
curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash
```

An open session keeps the environment it started with, so start a new
`claude-deepseek` session to use the updated wrapper. To confirm the installed
version without reinstalling:

```bash
curl -fsSL https://raw.githubusercontent.com/z2h-academy/claude-deepseek/main/install.sh | bash -s -- --check
```

From a clone, `bash install.sh --check` shows the same result. The first launch
after upgrading may migrate existing DeepSeek sessions into `~/.claude/projects`
(with a `projects.bak.<timestamp>` backup). From 1.1.1, `/effort` can change the
effort level during the session.

## Configure

```bash
deepseek-key      # paste the key when prompted (input is hidden)
deepseek-check    # must answer OK with HTTP 200
claude-deepseek   # start a session
```

Get a key at <https://platform.deepseek.com/api_keys>. The key is written to
`~/.config/deepseek/claude-code.env` with mode `600` and is never printed.

If the commands are not found, reload the shell (`exec $SHELL -l`) or call the
full path: `~/.local/bin/claude-deepseek`.

## What it sets

The wrapper exports these variables only in its own process:

```text
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=<your key>
ANTHROPIC_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-flash
CLAUDE_CODE_AUTO_COMPACT_WINDOW=786432
CLAUDE_CONFIG_DIR=~/.config/claude-deepseek
```

Effort starts at `DEEPSEEK_EFFORT_LEVEL` (default `max`) through the
`--effort` flag. The wrapper does not export `CLAUDE_CODE_EFFORT_LEVEL`, so
`/effort` can raise or lower the level during the session.

`CLAUDE_CONFIG_DIR` is what avoids the "Both ANTHROPIC_AUTH_TOKEN and /login
managed key set" warning: the DeepSeek session keeps its own settings and
plugins, and your Anthropic login stays untouched. Sessions are shared by
default; see [Sessions](#sessions).

To share the **entire** config with your normal Claude Code installation,
including auth and MCP servers:

```bash
DEEPSEEK_SHARED_CONFIG=1 claude-deepseek
```

That is not needed for sharing sessions, and it exposes your Anthropic login to
the DeepSeek-launched process.

## Sessions

Both profiles share conversation transcripts by default:

```text
~/.config/claude-deepseek/projects -> ~/.claude/projects
```

`claude --resume` and `claude-deepseek --resume` list the same sessions in
either direction. Only `projects/` is shared: auth, settings, MCP servers,
plugins and history files stay isolated.

On the first run after upgrading, sessions that already exist in the DeepSeek
profile are merged into `~/.claude/projects` and the old directory is kept as
`projects.bak.<timestamp>`. The migration waits if another `claude-deepseek`
session is running, and retries on the next launch.

To go back to isolated profiles:

```bash
DEEPSEEK_SHARE_SESSIONS=0 claude-deepseek
```

If the sharing symlink already exists, the next launch removes it. The
transcripts stay in `~/.claude/projects` and the DeepSeek profile starts with an
empty history; the pre-migration sessions remain in `projects.bak.<timestamp>`
if that backup was created.

Caveats:

- Resuming a session under DeepSeek sends its full history to DeepSeek.
- Do not resume the same session in both profiles at the same time.
- A resumed session uses the MCP servers, plugins and settings of the profile
  that opened it.
- If the DeepSeek endpoint rejects a transcript that contains
  provider-specific blocks, continue that session with `claude`.

## Customise

Put overrides in `~/.config/deepseek/claude-code.env`:

```bash
DEEPSEEK_MODEL=deepseek-v4-pro
DEEPSEEK_FAST_MODEL=deepseek-flash
DEEPSEEK_BASE_URL=https://api.deepseek.com/anthropic
DEEPSEEK_EFFORT_LEVEL=high   # initial effort; /effort can change it
DEEPSEEK_SHARE_SESSIONS=0   # keep sessions isolated
```

## Going back to Anthropic

```bash
claude
```

The wrapper never changes your shell: exports live inside the `claude-deepseek`
process only.

## Options

```bash
bash install.sh --prefix ~/bin      # install elsewhere
bash install.sh --no-path           # do not touch shell rc files
bash install.sh --force             # rewrite the key file (empties it)
bash install.sh --check             # report what is installed
bash install.sh --uninstall         # remove binaries and the key file
```

## Requirements

- Claude Code installed (`curl -fsSL https://claude.ai/install.sh | bash`).
  The installer warns if it is missing; the wrapper refuses to run without it.
- `curl` for `deepseek-check`. `jq` is optional and only prettifies the output.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `falta DEEPSEEK_API_KEY` | key not stored | `deepseek-key` |
| `HTTP 401` | key invalid or revoked | create a new key |
| `HTTP 402` | no balance | top up the DeepSeek account |
| `HTTP 400` | wrong model name | use `deepseek-flash` |
| `zsh: no matches found` | `[1m]` unquoted | keep `DEEPSEEK_MODEL='deepseek-flash[1m]'` |
| `/effort` does not change the level | older wrapper exported `CLAUDE_CODE_EFFORT_LEVEL` | rerun the installer (1.1.1+) |
| Warning about two credentials | shared Claude config | leave `CLAUDE_CONFIG_DIR` as set, or `claude /logout` |
| Sessions not listed in `claude-deepseek --resume` | profile created before 1.1.0 | rerun the installer and launch once; the profile is migrated |
| Commands not found after install | shell not reloaded | `exec $SHELL -l` |

## Uninstall

```bash
bash install.sh --uninstall
```

Then remove the `~/.local/bin` lines from your shell rc files if you want a full
cleanup.

## Tests

```bash
bash tests/run-tests.sh
```

No network and no real key required: a fake `claude` binary is used.

## Related

`scripts/install-claude-deepseek.sh` in
[z2h-academy/tutor-internal](https://github.com/z2h-academy/tutor-internal) is
the internal copy used by the Z2H Academy container. This repository is the
public, standalone version.

## License

MIT
