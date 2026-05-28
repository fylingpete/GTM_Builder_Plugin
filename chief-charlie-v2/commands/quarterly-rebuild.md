---
description: Run the quarterly rebuild. Strategic pivot assessment, KPI target adjustment, people/org changes. In Scale 3.2+, this is Wickman Quarterly Rocks™ Planning.
---

# /quarterly-rebuild

The heaviest cadence — a real "stop and rebuild" session, not a check-in.

1. Read `01_command_center/dashboards/dashboard_data.json` → `current_path`.

2. Load and follow the canonical workflow:
   - **PMF:** `skills/founder-os/paths/pmf/operations/quarterly-rebuild.md`
   - **GTM:** `skills/founder-os/paths/gtm/operations/quarterly-rebuild.md`
   - **Scale:** `skills/founder-os/paths/scale/operations/quarterly-rebuild.md` (at 3.2+, this IS Wickman Quarterly Rocks™ Planning — different structure)

3. Sections (general — Scale 3.2+ overrides with Rocks™ format):
   - **Quarter retro** — what worked, what didn't, what surprised
   - **Strategic pivot assessment** — does the current path/phase still make sense?
   - **KPI target adjustment** — recalibrate targets based on reality
   - **People / org changes** — hires planned, exits, role changes
   - **Risk register** — top 3 risks for next quarter
   - **Next quarter's 3 Rocks™ (Scale)** or **next quarter's 3 priorities (PMF/GTM)**

4. After completion:
   - Update `path_state.cadences.next_quarterly_due` to today + 90 days
   - Append a row to `01_command_center/logs/quarterly_rebuild_log.jsonl`
   - In Scale 3.2+: log each Rock™ to `01_command_center/logs/rocks_completion_log.jsonl` with binary scoring at quarter end
   - If a phase transition is warranted, surface the recommendation but require explicit user confirmation

5. **Dual-write to mem0 (long-term memory).** If the `chief-charlie` MCP tools are available this session (load via ToolSearch if not yet loaded — see `CLAUDE.md` → "Long-term memory"), persist the rebuild:

   - One **quarter retro** memory → `add_memory(content="Quarter retro {date} ({path}): worked={...}, didnt_work={...}, surprised={...}.", category="learning")`
   - For the **strategic pivot assessment** → `add_memory(content="Strategic assessment ({path}, {date}): {keep_or_pivot_summary}.", category="decision")`
   - For **each adjusted KPI target** → `add_memory(content="KPI target reset ({path}, {date}): {kpi_name} {old_target} → {new_target}. Reason: {reason}.", category="decision")`
   - For **each people/org change** → `add_memory(content="Org change ({path}, {date}): {change_description}.", category="fact")`
   - One **risk register** memory → `add_memory(content="Top 3 risks next quarter ({path}, {date}): {risks_list}.", category="fact")`
   - For **each Rock™ / priority for next quarter** → `add_memory(content="Q-Rock/Priority ({path}, quarter starting {date}): {rock_or_priority}.", category="decision")`
   - If a **phase transition was recommended** (even if not yet confirmed) → `add_memory(content="Phase transition recommended ({path}, {date}): from {current_phase} to {next_phase}. Rationale: {why}.", category="decision")`

   Skip silently if MCP isn't connected. Do NOT duplicate-write items already pushed via `/log-decision` or `/log-learning` during the same conversation.
