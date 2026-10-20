
# Meme — Project Rules

## 1. General
- Inspect existing code before making changes.
- Preserve existing architecture and behavior.
- Do not invent files, APIs, models, or dependencies.
- Keep changes limited to the requested scope.
- Ask before introducing a new dependency or changing architecture.

## 2. UI/UX
- Follow the existing Meme design system and theme.
- Reuse existing widgets, tokens, and components.
- Support loading, empty, error, and success states.
- Consider responsive layouts and accessibility.
- Do not change unrelated screens.

## 3. Flutter/Dart
- Follow current project conventions.
- Keep business logic separate from presentation where appropriate.
- Handle asynchronous operations and widget lifecycle safely.
- Avoid unnecessary rebuilds and duplicated logic.
- Run dart format, flutter analyze, and relevant tests.

## 4. Security
- Never expose service-account credentials or private keys.
- Never trust client-side authorization alone.
- Validate user input and enforce access through backend rules.
- Review Firestore and Storage Security Rules when changing data access.
- Do not deploy or modify production resources without approval.

## 5. Completion
- Summarize changed files and behavior.
- Report commands and tests actually executed.
- Disclose remaining failures and unverified assumptions.
