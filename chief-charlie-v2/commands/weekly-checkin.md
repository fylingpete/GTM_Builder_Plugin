---
description: Run the weekly check-in for the user's current Founder OS path. Reviews progress, updates KPIs, captures decisions and learnings.
---

# /weekly-checkin

Run the weekly check-in. The exact workflow depends on the current path.

1. Read `01_command_center/dashboards/dashboard_data.json` → `current_path`.

2. Load and follow the canonical workflow:
   - **PMF:** `skills/founder-os/paths/pmf/operations/weekly-checkin.md`
   - **GTM:** `skills/founder-os/paths/gtm/operations/weekly-checkin-review.md`
   - **Scale:** `skills/founder-os/paths/scale/operations/weekly-checkin.md` (auto-toggles to L10™ Mode at sub-phase 3.2+)

3. The check-in always covers:
   - **KPI review** — pull each row from `kpis.rows[]`, ask the user for current values, update the file
   - **Bottleneck** — confirm or change the current bottleneck
   - **Wins / losses** — at least 1 of each
   - **Decisions made this week** — append each one to `01_command_center/logs/decisions_learnings.jsonl` with the schema from the master SKILL.md
   - **Learnings** — same: append to `01_command_center/logs/decisions_learnings.jsonl`
   - **Next One Thing** — the single most important thing for next week

4. After completion:
   - Update `path_state.cadences.next_checkin_due` to today + 7 days
   - Append a summary row to `01_command_center/logs/weekly_checkin_log.jsonl` (using the schema from `paths/{current_path}/templates/weekly_checkin_log.template.jsonl`)
   - Save the file
   - Confirm to the user that the check-in is logged

5. **Dual-write to mem0 (long-term memory).** If the `chief-charlie` MCP tools are available this session (load via ToolSearch if not yet loaded — see `CLAUDE.md` → "Long-term memory"), persist the check-in to mem0:

   - For **each** decision captured in step 3 → `add_memory(content="Decision ({path}, {date}): ...", category="decision")`
   - For **each** learning captured in step 3 → `add_memory(content="Learning ({path}, {date}): ...", category="learning")`
   - If the **bottleneck changed** → `add_memory(content="Bottleneck change ({path}, {date}): from {old} to {new}.", category="fact")`
   - For the **Next One Thing** → `add_memory(content="Next One Thing (week of {date}, {path}): {next_one_thing}.", category="decision")`
   - One **summary** memory → `add_memory(content="Weekly check-in {date} ({path}): KPIs {kpi_summary}. Top win: {win}. Top loss: {loss}.", category="fact")`

   Skip silently if MCP isn't connected — the local JSONL + dashboard remain source of truth. Do NOT duplicate-write items the user already pushed via `/log-decision` or `/log-learning` during the same conversation.

6. If the user is in Scale phase 3.2+, follow the **L10™ structure**: Segue → Scorecard™ → Rock™ Review → Customer/Employee Headlines → To-Do List → IDS (Identify, Discuss, Solve) → Conclude.
