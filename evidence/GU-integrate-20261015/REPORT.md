# GU-integrate-20261015 REPORT
Branch qs-command-code/gu-integrate-20261015, base b5648a5. Executor qs-command-code (Command Code CLI, deepseek/deepseek-v4.1-flash, off-peak).

## Source commits
| source | result | note |
|---|---|---|
| 422c173 nuyan | integrated (78a27ea) | clean |
| 3bccb50 jilue squash | integrated (c9c498a) | conflicts hunlie.lua (kept HEAD #sgkgodfeiying prohibit; not redefined by 3bccb50), srkill.lua (took incoming sr_youxia rewrite, dropped commented-out old copy, kept #sr_youxiaPro) |
| 93ab175 (parent of 48ae5f2, diyba branch) | integrated (8f0d86d) | WeChat mini-program AI variants |
| 48ae5f2 diyba 33 | integrated (2b69c85) | clean |
| 72f9784 diyba REPORT | integrated (156e634) | docs only |
| f0dfe71 shikong | already present | V2-migrated in main; cherry-pick resolves empty; all skill names present |
| 4c514d1 wuming (+1a01b74) | already present | resolved empty against main; 8/8 names present |
| b79e2d1 guanzheng (19 commits) | already present | 25/25 names present; HEAD..tip diff only V1-era leftovers |
| 2f2e667 diyba-2013 (16 commits) | already present | 36/36 names present |
| 51da650 sheji (5 commits) | already present | 11/11 names present |

## Duplicates removed (cdiy.lua vs offline.lua, source diyba.md)

| 武將 | 保留檔案 | 移除檔案 | 理由 |
|------|----------|----------|------|
| diyba_10j_xuelingyun（薛灵芸） | extensions/offline.lua | extensions/cdiy.lua | 雙方同為 wei／3 血／女性，技能「涟洏」「暗织」描述一致；對照 diyba.md（3 体力，涟洏／暗织）無差異，平手 → 依規則偏好 offline。 |
| diyba_10j_zhangti（张悌） | extensions/offline.lua | extensions/cdiy.lua | 雙方同為 wu／3 血，技能「逆势」「覆江」一致；對照 diyba.md（3 体力）無差異，平手 → 偏好 offline。 |
| diyba_10j_zhugejing（诸葛靓） | extensions/cdiy.lua | extensions/offline.lua | cdiy 勢力為 wu（吳），符合諸葛靚仕吳之史實；offline 為 wei，且其移植報告自承「kingdom not in excerpt, set to wei」為推測。diyba.md 未載勢力，但 wu 為較佳（正確）對應 → 保留 cdiy。 |
| diyba_12j_qianzhao（牵招） | extensions/offline.lua | extensions/cdiy.lua | 雙方同為 wei／4 血，技能「远振」「制戎」一致；對照 diyba.md（4 体力）無差異，平手 → 偏好 offline。 |
| diyba_12j_sunhe（孙和） | extensions/offline.lua | extensions/cdiy.lua | 雙方同為 wu／3 血，技能「命也」「党乎」一致；對照 diyba.md（3 体力）無差異，平手 → 偏好 offline。 |
| diyba_15j_budugen（步度根） | extensions/offline.lua | extensions/cdiy.lua | diyba.md 明載群／四勾玉，雙方同為 qun／4 血，技能「扰掠」一致；無差異，平手 → 偏好 offline。 |

Same-file repeated `name =` (sk.lua, srkill.lua, etc.) are ViewAs+Trigger pairs, not duplicates.

## Checks
- sv2_syntax (engine Lua parser) on all changed .lua: all OK
- sv2_lint on changed extensions: TOTAL_ERRORS 0
- No new duplicate sgs.General names vs b5648a5
- headless/server smoke: NOT RUN (not required by brief)

## Follow-up 2026-10-15 (管家)
### qs-claude/gu-diyba-20261015 b6bb63d (merge commit c23c6e0)
- Merged; conflicts in extensions/offline.lua, ai/offline-ai.lua resolved by taking b6bb63d versions (replaces old 2b69c85 diyba content; net 7 diyba generals in offline.lua: zhangti, dingfei, budugen, dengfang, zhuyi, qianzhao + zhugejing).
- diyba_10j_zhugejing: b6bb63d still has kingdom wei (not explicitly settled) -> per 管家 decision kept cdiy.lua 吳 version, removed offline copy (skills diyba_sansi/diyba_jiezhong collided) + its AI hook.
- diyba_10j_xuelingyun, diyba_12j_sunhe: dropped by b6bb63d and earlier removed from cdiy.lua by 871b781 dedup, so they existed nowhere -> restored main's (b5648a5) cdiy.lua/cdiy-ai.lua blocks verbatim.
- zhangti/qianzhao/budugen remain only in offline.lua.
### sheji 25f6352 (merge commit, see tip)
- Append/append conflicts in offline.lua / offline-ai.lua: kept both (diyba then sheji), single final return incl. extension_sj.
- 5 sheji generals duplicated olddiy.lua (main): sj2_haigelisi, sj2_lisailiu, sj2_hannibal, sj5_eleanor, sj7_sunba -> kept olddiy, removed offline copies + AI. 13 sheji generals kept. Details: dedup-sheji.md.
### Checks
- sv2_syntax OK on cdiy/offline/cdiy-ai/offline-ai; sv2_lint TOTAL_ERRORS 0; no new duplicate sgs.General names vs b5648a5.
