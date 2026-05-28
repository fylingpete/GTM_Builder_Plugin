# Chief Charlie — Founder OS Plugin

The Chief Charlie plugin turns Claude into a Founder Operating System. See the [repo README](../README.md) for install instructions and overview.

## Plugin contents

| Type | What |
|---|---|
| Commands | `/onboarding`, `/founder-os`, `/weekly-checkin`, `/monthly-review`, `/quarterly-rebuild`, `/log-decision`, `/log-learning` |
| Skills | `founder-os` (master), `memory-search`, `decision-logging`, `kpi-tracking` |
| Agents | `research`, `market-report` |
| Hooks | `SessionStart` — injects current dashboard snapshot · `UserPromptSubmit` — context refresh · `PostToolUse` (Write/Edit) — auto-sync workspace files to chiefcharlie |
| MCP | `chief-charlie` HTTP server at `https://api.chiefcharlie.ai/mcp/` (memory + workspace + WhatsApp tools) |

## How it works

1. **CLAUDE.md** sets the persona and security rules (always loaded when the plugin is active in a workspace).
2. **SessionStart hook** reads `01_command_center/dashboards/dashboard_data.json` from the workspace and injects a current snapshot (path, phase, bottleneck, overdue cadences) into the system context — so Claude doesn't have to re-read the file on every turn.
3. **`founder-os` skill** is the master operating system: 3 paths × 14 steps × deliverable templates × knowledge library, all checked into `skills/founder-os/`.
4. **Slash commands** are thin entry points that load the relevant skill content and execute path-specific workflows.
5. **Helper skills** (`memory-search`, `decision-logging`, `kpi-tracking`) auto-trigger when relevant — no explicit invocation needed.

## State files in the user's workspace

After `/onboarding`:

```
~/ChiefCharlie/
├── 00_configuration/
│   ├── founder_harness.md          # personalized harness rules (also inlined into CLAUDE.md)
│   └── schema.md                   # data-file reference
├── 01_command_center/
│   ├── index.md                    # snapshot + quick links
│   ├── dashboards/
│   │   ├── dashboard_data.json     # primary state (single source of truth)
│   │   ├── roadmap_data.json       # per-step rich content (lazy-loaded)
│   │   └── home.json / roadmap.json / projects.json / tasks.json / kpis.json  (canvas pills)
│   └── logs/
│       ├── decisions_learnings.jsonl   # append-only log (decisions + learnings)
│       ├── weekly_checkin_log.jsonl
│       └── (monthly_review / quarterly_rebuild / pmf_* logs as needed)
├── .chiefcharlie/                  # sync anchor (auth.json + project.json — gitignored)
└── CLAUDE.md                       # identity block + inlined founder_harness content
```

## File Sync (v0.6.0+)

The `PostToolUse` hook automatically syncs every Write/Edit in your workspace to chiefcharlie so:

- The WhatsApp heartbeat picks up your latest `dashboard_data.json` within seconds
- A second device (Electron app, web) sees the changes
- Embeddings stay fresh for `search_workspace_files`

**First time in a workspace,** ask the assistant to run setup. It will call the `init_workspace` MCP tool and write two files into `<workspace>/.chiefcharlie/`:

- `auth.json` — your per-workspace device token (chmod 600)
- `project.json` — the project this workspace maps to

Both should be in your `.gitignore` — the assistant adds the entry for you when the workspace is a git repo.

**Per-workspace tokens** are individually revocable: a leaked or unused workspace token can be revoked in your account settings on chiefcharlie.app without affecting any other workspace.

## Customizing

- **Edit the persona:** modify `CLAUDE.md`
- **Change Founder OS rules:** edit `skills/founder-os/SKILL.md` and path files under `skills/founder-os/paths/`
- **Add connectors:** add MCP servers to `.mcp.json`
- **Add commands:** drop new `.md` files in `commands/` with the standard frontmatter

## License

MIT.
