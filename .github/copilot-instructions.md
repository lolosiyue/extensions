# Copilot Instructions for This Repository

## Project context
- This repository is a **QSanguosha/Lua extension codebase** with two main development areas:
  - `extensions/`: card/general/skill gameplay implementation files (e.g. `scarlet.lua`, `year_review.lua`)
  - `ai/`: AI behavior files, usually paired as `*-ai.lua`
- Most code is legacy-style Lua; prioritize **compatibility, stability, and minimal diffs**.
- Documentation exists in both Chinese and English. Keep existing language style in each file.

## Core development rules
- Prefer **surgical edits**: modify only the requested skill/module; do not refactor unrelated large blocks.
- Preserve existing naming conventions and prefixes (e.g. `s4_`, `#skill_buff`, `skill&`).
- Do not rename public/general/skill identifiers unless explicitly requested.
- Keep Lua code compatible with engine expectations (legacy Lua style, no modern-only syntax assumptions).
- Follow existing indentation/style in the target file.

## Skills and gameplay changes
When adding or editing a skill in `extensions/*.lua`:
1. Keep the standard structure:
   - `sgs.Create*Skill` / `sgs.CreateSkillCard`
   - `general:addSkill(...)`
   - `extension:insertRelatedSkills(...)` when applicable
   - `sgs.LoadTranslationTable { ... }` entries
2. Ensure event handling is explicit and safe:
   - Check `event` branches clearly
   - Guard nil objects (`player`, `target`, `damage.from`, card objects)
   - Return values should match engine expectations (`true/false` where required)
3. Avoid changing unrelated trigger timing or global marks.

## AI synchronization rules
- If gameplay behavior is changed in `extensions/`, verify whether matching logic in `ai/*-ai.lua` must be updated.
- Keep AI updates minimal and aligned with existing patterns in neighboring skills.
- Do not invent complex AI heuristics unless requested; prefer stable, conservative behavior.

## Translation and text rules
- Any new general/skill/card should include matching translation keys in `sgs.LoadTranslationTable`.
- Keep wording concise and consistent with existing Chinese terminology.
- Do not mass-rewrite existing translation text unless asked.

## Safety and robustness
- Prefer defensive checks to prevent common runtime errors in legacy AI/game scripts:
  - nil access
  - dead/non-existent player objects
  - empty card collections
- Reuse existing helper patterns already present in this repository before introducing new abstractions.

## Scope control
- Implement only what the task asks.
- Do not add new systems, UI, docs, or broad cleanup unless explicitly requested.
- If requirements are ambiguous, choose the simplest behavior that matches current code style.

## Validation checklist before finishing
- Confirm syntax consistency in edited Lua blocks.
- Confirm related translation keys exist for new/renamed identifiers.
- Confirm related skill registration calls are complete.
- If AI-impacting change was made, confirm corresponding `ai/*-ai.lua` handling was reviewed/updated.