# Agent Rules

## Graphify Rules
- **NEVER** run `graphify vscode-build`, `graphify build`, or standard `graphify update` during active coding or analysis sessions.
- **ONLY** trigger/run Graphify update commands (e.g., `graphify update`) when code is committed to Git (either manually immediately after a Git commit, or automatically via a post-commit Git hook).
