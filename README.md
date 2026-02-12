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

## Creating Good PRD and Progress Files

The quality of your autonomous run depends entirely on how well you define the work. Lucy reads `prd.json` and `progress.txt` to understand what to do and what's already done.

### prd.json

Structure your PRD as JSON with a `passes` field for each task:

```json
{
  "title": "My Feature",
  "branchName": "lucy/my-feature",
  "stories": [
    {
      "id": "1",
      "title": "Setup database schema",
      "description": "Create tables for users and sessions",
      "acceptanceCriteria": "Migrations run successfully, tables exist",
      "passes": false
    },
    {
      "id": "2", 
      "title": "Add API endpoints",
      "description": "REST endpoints for user CRUD",
      "acceptanceCriteria": "All endpoints return correct status codes",
      "passes": false
    },
    {
      "id": "3",
      "title": "Fix low-priority SonarQube issue",
      "description": "Refactor legacy module to remove code smell",
      "acceptanceCriteria": "SonarQube issue resolved",
      "passes": false,
      "rejected": {
        "timestamp": "2024-01-16T10:30:00Z",
        "reason": "Refactoring this module would require changes to 15+ dependent files with high regression risk. The code smell has no functional impact. Risk accepted."
      }
    }
  ]
}
```

Task states:
- `passes: false` — Not yet completed
- `passes: true` — Completed successfully  
- `rejected` — Task intentionally skipped with timestamp and reason (e.g., risk accepted, low priority vs. high effort, would cause more problems than it solves)

Tips for good PRD items:
- **Atomic**: One logical unit of work per task
- **Verifiable**: Clear acceptance criteria Lucy can check
- **Ordered**: Respect dependencies (setup before features)
- **Small**: Prefer many small tasks over few large ones — smaller tasks mean tighter feedback loops and less context rot

### progress.txt

Lucy appends to this file after each iteration. It serves as memory between fresh contexts:

```
# Progress Log
Started: 2024-01-15

---
## Iteration 1
- Completed: Story 1 - Setup database schema
- Created migrations in db/migrations/
- Ran `npm run migrate` successfully
- Committed: abc123

## Iteration 2
- Completed: Story 2 - Add API endpoints
- Added routes in src/routes/users.ts
- All tests passing
- Committed: def456
```

What to track:
- Tasks completed with PRD reference
- Key decisions and reasoning
- Files changed
- Blockers or notes for next iteration

### Best Practices

1. **Define "done" explicitly** — vague tasks lead to shortcuts or infinite loops
2. **Prioritize risky tasks first** — architectural decisions and integrations before polish
3. **Use feedback loops** — types, tests, and linting catch issues between iterations
4. **Start with HITL** — watch the first few iterations before going fully autonomous
5. **Keep scope tight** — Ralph/Lucy works best for proof of concepts with clear boundaries

For more tips, see [Tips for AI Coding with Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) and the [Ralph Loop Quickstart](https://github.com/coleam00/ralph-loop-quickstart).

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

## Future Ideas

- **PostgreSQL backend** — Store PRD and progress in a database for concurrent workers, with task locking (timestamp-based) and release, and timestamps for pass/fail status
- **Progress UI** — Web interface to visualize iteration progress, task status, and logs
- **Orchestrator mode** — Use a local kiro-cli instance to coordinate multiple worker containers
- **Specialized agents** — Agent configs and prompts tailored for specific task types (testing, refactoring, documentation, etc.)
- **Network isolation** — Additional security features to restrict container network access
