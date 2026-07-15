# AGENTS.md — Fasting Furious

## What This App Is

Flutter social fitness & intermittent fasting tracker. Supabase backend, Riverpod state, glassmorphism UI.

## How We Work

### Rule 1: One task per commit

Before writing code, state the task in one sentence. If you catch yourself writing "and also" — commit what you have first, then start the new thing.

### Rule 2: Read before you write

Before editing any file, read it. Understand imports, existing patterns, and what's already there. Most bugs come from changing something without understanding what depends on it.

### Rule 3: No kitchen-sink commits

Bad: `Fix bugs, add smoking tracker, improve UI, update seed data`
Good: `feat: add smoking log screen with craving intensity slider`

If a commit message has more than one comma-separated feature, it should be multiple commits.

### Rule 4: Write the commit message first

Before coding, write the commit message. If you can't describe the change in one sentence, the scope is too big. Break it down.

### Rule 5: Verify before moving on

After each change, run the app and test the specific thing you changed. Don't stack 5 changes and then test — you won't know which one broke.

### Rule 6: When you spot something else, write it down

Keep a running list of things to fix. Don't fix them mid-task. This prevents scope creep.

### Rule 7: Commit everything together

Code changes and backlog updates for the same task go in one commit. One task = one commit.

## Code Conventions

- **State management:** Riverpod (`StateNotifierProvider` pattern)
- **File structure:** One screen per file in `lib/screens/`, one widget per file in `lib/widgets/`
- **Services:** All Supabase calls go through `lib/services/supabase_service.dart`
- **Models:** Centralized in `lib/models/models.dart`
- **Theme:** Colors, gradients, and styles in `lib/config/theme.dart`
- **Naming:** snake_case files, PascalCase classes, camelCase variables
- **No comments** unless explaining why something non-obvious exists
- **No `print()` or `debugPrint()`** in committed code — use `assert()` or remove
- **Silent catch blocks** (`catch (_) {}`) are tech debt — log or surface the error

## File Structure Rules

```
lib/
├── config/       # Theme, page transitions, constants
├── models/       # Data classes with fromMap/toMap
├── providers/    # Riverpod StateNotifiers
├── screens/      # One screen per file
├── services/     # Supabase API calls only
└── widgets/      # Reusable UI components
```

Do NOT put screen logic in `main.dart`. `CreatePostScreen` should be moved to `lib/screens/create_post_screen.dart`.

## Backend Work (Supabase)

### Before touching the database:
1. Read the existing migration in `sql/` first
2. Understand the current RLS policies
3. Check if the table already has what you need

### Supabase patterns:
- Always use `.maybeSingle()` for optional single-row fetches
- Always use `.select()` with explicit columns, not `select('*')` when possible
- Use `onConflict` for upserts
- RLS policies must be added for every new table
- Never expose user emails in queries

### Migration file naming:
```
sql/YYYYMMDD_description.sql
```

### When adding a new feature that needs a table:
1. Write the SQL migration first
2. Add the table to `supabase_service.dart`
3. Add the model if needed
4. Create the provider
5. Create the screen
6. Test the full flow

## Testing

- Run `flutter test` after changes
- If you break an existing test, fix it before moving on
- Test edge cases: null data, empty states, network errors

## What NOT to Do

- Don't add dependencies without checking if the codebase already has something similar
- Don't use `setState()` when Riverpod should manage the state
- Don't hardcode strings — if it's user-facing, it belongs in a const
- Don't commit `.env` or credentials (they're gitignored for a reason)
- Don't refactor code that's working unless asked to
- Don't add TODO comments unless you plan to fix them in the same session

## Commit Message Format

```
type: short description

type: feat | fix | refactor | style | docs | test | chore

Examples:
feat: add water intake tracking with daily goal
fix: timer not pausing when app goes to background
refactor: move CreatePostScreen out of main.dart
chore: remove unused imports from profile_screen.dart
```

## When Starting a Session

1. Read this file (AGENTS.md)
2. Check if there's a task list or backlog
3. Pick ONE task
4. Read the relevant files before coding
5. Make the change
6. Test it
7. Commit with a clear message
8. Move to next task or stop
