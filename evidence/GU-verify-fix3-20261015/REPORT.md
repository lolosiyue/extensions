# GU verify fix3 report

Source list: qs-command-code-REPORT.md (FAIL rows, extracted by Haiku). Branch qs-claude/gu-verify-fix2-20261015.
fixed=1 skipped=19. The 13 Bilibili-summary-only generals were not touched.

## 怒焰 (extensions/nuyan.lua)
| General / skill | Result | Reason |
|---|---|---|
| nuyan_jd_diaochan 离魂 | FIXED | 经典 original has no 不能换将 clause; nuyan_no_switch-Clear mark is now set only when not classic (常规 keeps it). |
| nuyan_machao 铁骑 | SKIPPED | Original: 无视其防具和防御系符石; engine has no 防御系符石 mechanism, Armor_Nullified is the most achievable. |
| nuyan_liuxie 天命 | SKIPPED | Not a defect: askForDiscard(o,id,2,2,false,true) already has include_equip=true; the finding misread arg order. |
| nuyan_xizhicai 常规 筹策 | SKIPPED | Not a defect: delta>0 already returns for 常规; matches 体力减少. |
| nuyan_jd_xizhicai 经典 筹策 | SKIPPED | Not a defect: original says 体力变化 (both directions), no 先辅 clause in 经典; code matches. |
| nuyan_chengyu 设伏 | SKIPPED | 触发的技能符石失效 until turn end cannot be matched; no per-trigger 符石 invalidation mechanism in engine. |
| nuyan_zhugeliang 祭天 | SKIPPED | Not a defect: math.huge is the per-phase use limit (original has none); target count is already 1. |
| nuyan_yuji 蛊惑 | SKIPPED | Not a defect: code matches original (same-suit response restriction; +1 on 杀 if no same-suit 闪). |

## 極略 (12 items) — all SKIPPED: out of allowed edit scope
Code for these generals lives in extensions/sk.lua (sgkgodsunce in extensions/hunlie.lua), not offline.lua; the rules allow editing only offline.lua/nuyan.lua and their AI files. Original text was not verified against code either (not in scope).
- sk_buzhi 折节 (timing: 弃牌阶段结束时)
- sk_caojie 怀璧 (use-source check)
- sk_guanxing 武志 (loseHp vs damage)
- sk_qiaozhou 星卜 (杀-only +1)
- sk_qinmi 谏征 (empty-hand condition)
- sgkgodsunce 冯河 (isNDTrick vs basic)
- sk_wanglang 劝降 (kingdom qun -> wei)
- sk_wuxian 贺春 (extra wounded condition)
- sk_wuyi 制敌 (missing ignore armor)
- sk_zhuzhi 安国 (weapon/奇门 branches)
- sk_zuoci 千幻 (skill pool mechanics)
- sk_zhugeguo 羽化/登仙 (extra condition, translation)
Needs a follow-up job with sk.lua/hunlie.lua (and sk-ai/hunlie-ai) in scope.
