# Dedup 3 — sheji (3S) merge deduplication (2026-10-15)

Scope: after resolving the `extensions/offline.lua` / `ai/offline-ai.lua` merge that appended the sheji package (`extension_sj`, the "三设" 3S generals) to the existing offline package, check the sheji generals against the 3S generals already present in `extensions/olddiy.lua` and against every general ID / skill object name in `extensions/*.lua`.

Policy: for a true duplicate, keep the `olddiy.lua` copy (already in `main`) and remove the `offline.lua` sheji copy completely — its `sgs.General`, skill objects, `addSkill` calls, translation entries, and its AI in `ai/offline-ai.lua`.

## Method
- Enumerated every `sgs.General(extension, "sj...")` in the sheji section of `extensions/offline.lua` (18 generals).
- Enumerated every `sgs.General` in `extensions/olddiy.lua`.
- Compared by identical general ID, identical display/short name, and identical skill object names.
- Grepped every remaining sheji general ID and skill object name across all `extensions/*.lua` to confirm no residual collision.

## Duplicates found and removed (5)

| sheji General (offline.lua) | display | olddiy.lua line | skills | decision |
|---|---|---|---|---|
| sj2_haigelisi | 海格力斯[三设2] | 2366 | sj2_shiershilian, sj2_shenyizhiqu | remove offline copy; keep olddiy |
| sj2_lisailiu | 黎塞留[三设2] | 2435 | sj2_quanjue, sj2_cewai | remove offline copy; keep olddiy |
| sj2_hannibal | 汉尼拔·巴卡[三设2] | 2649 | sj2_zhanwuchangfa (+Card/VS) | remove offline copy; keep olddiy |
| sj5_eleanor | 阿基坦的埃莉诺[三设5] | 2801 | sj5_fengying (+Card/VS), sj5_wangting | remove offline copy; keep olddiy |
| sj7_sunba | 孙霸[三设7] | 2900 | sj7_xiangjian, sj7_chaoai | remove offline copy; keep olddiy |

Each pair is the same design: identical general ID, identical skill object names, and identical `:skill` translation text. They were therefore registered twice (once by `olddiy`, once by `offline`).

### Removed from extensions/offline.lua
The whole first sheji block `-- ===== sheji done =====` (`do ... end`, original lines 7929–8484): the five generals, their skills, helper locals (`sj2_move_targets`, `sj5_wangting_block`, `sj5_wangting_exchange`, `sj7_discard_suit`), `addSkill` calls and translation tables.

### Removed from ai/offline-ai.lua
The matching `-- ===== sheji done =====` AI block (original lines 614–740): hooks for sj2_shiershilian, sj2_shenyizhiqu, sj2_cewai, sj2_quanjue, sj2_zhanwuchangfa(Card), sj5_fengying(Card)/sj5_ban_ids, sj5_wangting(_reset), sj7_xiangjian(_turn), sj7_chaoai_fangzhu.

## Kept sheji generals (13) — no duplicate
sj2_yalishanda (亚历山大), sj2_keliaobateluo (克利奥帕特拉七世), sj5_beiduofen (贝多芬), sj9_caoxiu (曹休), sj9_luoxian (罗宪), sj9_chengpu (程普), sj9_hansui (韩遂), sj9_renkai (任恺), sj9_shichong (石崇), sj7_dengyangdingmi (邓飏丁谧), sj7_ruanxian (阮咸), sj7_malong (马隆), sj11_maohuanghou (毛皇后).

- None of these characters appear in `olddiy.lua`.
- Every kept general ID and every kept skill object name (sj2_jizhengzhe, sj2_tuotujun, sj2_faolaozhishe, sj2_seyou, sj5_junbuzhisong, sj5_yikuyile, sj9_qingshi, sj9_lixian, sj9_tongzheng, sj9_yaopan, sj9_mashu, sj9_qinke, sj9_pengzheng, sj9_yiyi, sj7_fuguang, sj7_yongyi, sj7_sixian, sj7_qingtan, sj7_qingtanCard, sj7_jizhen, sj7_pianxiang, sj11_chaomian, sj11_xiti, plus their `#`-prefixed related skills) occurs in any other `extensions/*.lua` file — verified by grep.

## Result
- `extensions/offline.lua`: 5 duplicated sheji generals and their skills, addSkill calls and translations removed; 13 sheji generals retained in `extension_sj`.
- `ai/offline-ai.lua`: corresponding AI block removed.
- No `sgs.General` ID and no skill object name introduced by the sheji merge now collides with `olddiy.lua` or any other `extensions/*.lua` file.
