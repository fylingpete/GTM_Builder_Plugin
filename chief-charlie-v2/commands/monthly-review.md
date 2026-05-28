---
description: Run the monthly review for the user's Founder OS path. Path-milestone tracking, decision log audit, learning consolidation.
---

# /monthly-review

Monthly review — heavier than the weekly check-in. Available for GTM and Scale paths (PMF uses weekly + quarterly only).

1. Read `.founder-os/dashboard_data.json` → `current_path`. If `current_path == "pmf"`, tell the user there is no monthly review in PMF — offer `/weekly-checkin` or `/quarterly-rebuild` instead.

2. Load and follow the canonical workflow:
   - **GTM:** `skills/founder-os/paths/gtm/operations/monthly-review.md`
   - **Scale:** `skills/founder-os/paths/scale/operations/monthly-review.md` (refreshes Cross-Step KPIs: Rule of 40, NDR, LH-Score)

3. Standard sections to cover:
   - **Path milestone progress** — distance to next phase transition
   - **KPI trend** — vs. last month, not just current value
   - **Decision log audit** — read the last 30 days of `decisions_learnings.jsonl`. Which decisions worked? Which need reversing? (Look for `reverse_if:` conditions.)
   - **Learning consolidation** — group learnings by category, identify patterns
   - **Cross-step KPIs (Scale only)** — refresh Rule of 40, NDR, LH-Score; append to `cross_kpi_log.template.jsonl`
   - **Next month's focus** — 1–3 priorities

4. After completion:
   - Update `path_state.cadences.next_monthly_due` to today + 30 days
   - Append a row to `monthly_review_log.template.jsonl`
   - If a phase transition is warranted, mention it but do NOT auto-trigger — phase changes require explicit user confirmation via `/founder-os`

5. **Dual-write to mem0 (long-term memory).** If the `chief-charlie` MCP tools are available this session (load via ToolSearch if not yet loaded — see `CLAUDE.md` → "Long-term memory"), persist the review:

   - For **each decision being reversed** (from the decision-log audit) → `add_memory(content="Reversed decision ({path}, {date}): {original_decision}. Reason: {why_reversed}.", category="decision")`
   - For **each pattern surfaced** in learning consolidation → `add_memory(content="Pattern ({path}, {date}, {category}): {pattern_summary}.", category="learning")`
   - For **each KPI with a notable trend** (significant up/down vs. last month) → `add_memory(content="KPI trend ({path}, {date}): {kpi_name} {last_month_value} → {this_month_value}.", category="fact")`
   - For **next month's 1–3 priorities** → `add_memory(content="Next month priorities ({path}, {date}): {priorities_list}.", category="decision")`
   - One **summary** memory → `add_memory(content="Monthly review {date} ({path}): {one_paragraph_summary}.", category="fact")`

   Skip silently if MCP isn't connected. Do NOT duplicate-write items already pushed via `/log-decision` or `/log-learning` during the same conversation.
