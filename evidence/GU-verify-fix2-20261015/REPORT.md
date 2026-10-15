# GU-verify-fix2-20261015 REPORT

## Task 1 — 三設 kingdom qun -> jin (done)
extensions/offline.lua, only the General constructor lines changed ("qun" -> "jin", same value other Jin generals use, e.g. NyarzFirst.lua `hfsimayi`, AIgeneral.lua `wenxinyiyan`):
- sj7_malong (马隆)
- sj9_renkai (任恺)
- sj9_shichong (石崇)

Syntax: `luac5.1 -p` rejects offline.lua line 2802 (`&` bitwise operator, Lua 5.3+ syntax). Identical error on HEAD before my edit, so pre-existing and not from this change; the engine runs a 5.3+ interpreter. No other syntax errors reported before that line (luac stops at first error, so the rest of the file is unchecked by 5.1).

## Task 2 — AI never plays for 诸葛靓 / nuyan_xiahoudun / sk_bianfuren (investigated, NOT fixed)
Observation (from qs-command-code-REPORT.md): with offline.lua at 705360f, the three start with 0 Lua errors but AI plays no cards; no GameOver in 700s. One nuyan_xiahoudun game did finish (Winner rebel, 02:40), so it is not deterministic for that general.

Findings:
- The three generals live in three different files (cdiy.lua, nuyan.lua, sk.lua), not offline.lua; offline.lua is not a plausible cause of their behaviour beyond loading.
- 705360f -> HEAD: nuyan.lua (+4524) and sk.lua (+11725) are huge additions, so the test mixed an old offline.lua with new extension files / a 02:37 build; the run is not a clean comparison.
- AI coverage: diyba_sansi / diyba_jiezhong have entries in ai/cdiy-ai.lua. nuyan_ganglie has no AI file at all; sk_huage / sk_muyi have no entries in ai/sk-ai.lua. Missing skill AI normally falls back to default AI behaviour, so this alone does not explain "AI plays nothing" for all three.
- No CardLimit/Prohibit/view-as hijack was identified by grep in the skills inspected (not read exhaustively).

Hypotheses (unverified, ranked):
1. Environmental: stale/mismatched server binary or engine lua/ vs extension build (see known blocker: server binary 2026-10-09, sgs_ex.lua calling sgs.LuaProhibitSkillV2). Stalling across three unrelated generals in three files points to a common engine/AI-level cause, not per-general code.
2. 1v2 (03_1v2) mode AI path stalls (ai role/handler issue) independent of general — would reproduce with any general; suggest running a vanilla general in 03_1v2 as control.
3. Skill-level AI loops (sk_muyi / sk_huage trigger asks) — needs a live run with logs.

Not verified: no game was run (no usable server binary in this session; engine checkout read-only). No code changed for Task 2.
