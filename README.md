# 50-first-contexts

Run the [Ralph](https://github.com/snarktank/ralph) autonomous loop using kiro-cli inside ephemeral Docker containers. Each iteration starts from a completely fresh context — no memory, no hidden state — with progress persisted only through Git and the PRD. Every run is like the first run.

Named after the movie *50 First Dates* — Lucy wakes up each morning with no memory of the day before, yet still makes progress through external artifacts left for her future self.

## Quick Start

```bash
# Build the image
./build.sh

# Run the loop
./lucy.sh
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LUCY_IMAGE` | `fifty-first-contexts:latest` | Docker image |
| `LUCY_AGENT` | (none) | Kiro agent name |
| `LUCY_PROMPT` | `prompt.md` | Prompt file |
| `MAX_ITERATIONS` | `10` | Max loop iterations |
| `WORK_DIR` | `$(pwd)` | Repo to mount |
| `GIT_AUTHOR_NAME` | `Lucy Whitmore` | Git commit author |
| `GIT_AUTHOR_EMAIL` | `lucy@whitmore.local` | Git commit email |
| `AUTH_DIR` | OS-specific | Kiro auth directory |
| `KIRO_DIR` | `~/.kiro` | Kiro config directory |
| `SSH_DIR` | `~/.ssh` | SSH keys (fallback) |

## SSH Authentication

**Option A: Agent forwarding (preferred)**
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
./lucy.sh  # SSH_AUTH_SOCK is auto-detected
```

**Option B: Key mount (fallback)**
```bash
export SSH_DIR="$HOME/.ssh"
./lucy.sh
```

## How It Works

1. Each iteration runs `kiro-cli chat --no-interactive --trust-all-tools` in a fresh container
2. A unique Docker volume isolates kiro state per iteration
3. Auth tokens are synced from host via SQLite
4. The loop checks for `<promise>COMPLETE</promise>` to exit early
5. Volume is cleaned up after each iteration

## Files

- `lucy.sh` - Main loop script
- `entrypoint.sh` - Container entrypoint (auth sync, git config)
- `prompt.md` - Default prompt for iterations
- `Dockerfile` - Container image with kiro-cli + dev tools
- `build.sh` - Image build script

## Docker Image Contents

- kiro-cli, git, bash, sqlite3, jq, curl, openssh-client
- Node.js 22, npm, pnpm, yarn
- Go 1.23
- Java 21 (Temurin), Maven, Gradle
- kubectl, jf (JFrog CLI)

## Testing

```bash
cd test
./run.sh
```
