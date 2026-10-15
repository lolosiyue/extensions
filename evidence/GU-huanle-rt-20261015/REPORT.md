# GU huanle runtime-error fix (offline.lua)

Evidence: evidence/GU-verify-20261015/qs-antigravity-REPORT.md

| # | Location | Cause | Fix |
|---|----------|-------|-----|
| 1 | `#hlxg_wushen_mod` (~5142) | `CorrectSkillContext` has no `getFrom()`; the getter is `getPrimary()` (Distance/TargetMod: `from`). Returned nil, errored every query. | `ctx:getFrom()` -> `ctx:getPrimary()` |
| 2 | `#hlxg_wansha_simayi_limit` (~7743) | `p:getRoom()` on the Player handed to CardLimitSkill callbacks is nil (not a ServerPlayer). | `sgs.Sanguosha:currentRoom()` (already used elsewhere in the file) with nil guard on room |
| 3 | `hlxg_zishou_prohibit` (~6636), `hljx_zongshi_slash` (~6654) | `CorrectSkillGate::setAtoms` (src/core/skill.cpp) only accepts `[secondary.]mark|flag|pile|skill:` and `card_skill|card_flag:`; `primary.` is invalid -> "invalid gate atom", file fails to load. Unprefixed atoms already target primary. | `primary.mark:X` -> `mark:X` |

Only these 4 lines were edited; /workspace/Qsanguosha-sijyu untouched.

## Unverified
- `luac -p` is Lua 5.1 and fails on the pre-existing `&` operator at line 2802 (same on HEAD), so syntax was not fully checked by luac; the edits are trivial.
- Not run in the engine: load success, absence of getFrom/getRoom errors in headless games, and hlxg_wushen heart-slash distance / hlxg_simayi Peach limit behaviour are unconfirmed.
- `sgs.Sanguosha:currentRoom()` availability in the CardLimit callback context is assumed from other use in this file (~5865).
