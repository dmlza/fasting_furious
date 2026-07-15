# Memories — Fasting Furious

Cross-session memory for the Fasting Furious project.

## 2026-07-15 — Established project workflow system

- context: User wanted to move from "fix things as they come up" to a structured build process
- insight: The codebase is solid architecturally — the messiness was process, not code. Commits were "kitchen sink" (20 files, 2500+ lines) instead of focused (1 file, 30 lines)
- action: Created AGENTS.md with 6 workflow rules (one task per commit, read before write, no kitchen-sink commits, write message first, verify before moving on, write it down). Created BACKLOG.md for task tracking.
- edge: User has a nursing background, not CS. The care plan framework (goal → intervention → evaluation) maps directly to coding tasks.

## 2026-07-15 — Created reusable master_prompts system

- context: User wants to apply the same workflow to future projects
- action: Built ~/Desktop/master_prompts/ with templates, prompts, and rules. Merged global behavior rules (from opencodememories) with project workflow rules into one enhanced AGENTS.md template.
- insight: The global AGENTS.md (behavior) and project AGENTS.md (workflow) serve different purposes but belong in one file. Behavior rules = how to act. Workflow rules = how to structure work.

## 2026-07-15 — Current project state

- context: App is functional with core features complete
- key code: CreatePostScreen is in main.dart (350+ lines) — should be moved to lib/screens/create_post_screen.dart
- pending: Backend work coming soon — user needs to learn Supabase patterns
- architecture: Flutter + Supabase + Riverpod + glassmorphism UI
