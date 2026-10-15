# GU verify fix4 report (極略 12 items, sk.lua / hunlie.lua)

Source list: fix3 REPORT 極略 section + qs-command-code-REPORT.md. Original text: .gu-jilue/jilue.md (品质 list = per-general skill text; Bilibili summaries = secondary text).
Rule applied: fix only where the code violates an original text and no other original text contradicts it; where original texts conflict and the code matches one literally -> not-a-bug. No AI file changes needed (no AI keyed to the changed behaviour). The 13 Bilibili-summary-only generals untouched.

| General / skill | Result | Detail |
|---|---|---|
| sk_caojie 怀璧 | FIXED | 品质 text: 其他角色使用的 same-suit 杀/非延时锦囊 无效; added CardEffect.from ~= owner check; translation updated. |
| sk_qiaozhou 星卜 | FIXED | +1 damage only when damage.card is 杀 (ConfirmDamage). |
| sk_qinmi 谏征 | FIXED | Original: 天辩 拼点牌 still needs 手牌 to start 拼点; can_trigger now requires owner non-empty hand. |
| sk_wanglang kingdom | FIXED | 品质 list: 王朗（魏）; kingdom qun -> wei. |
| sk_wuyi 制敌 | FIXED | effect 2 now also 无视防具 (addQinggangTag on targets) per 品质 text; description updated. |
| sgkgodsunce 冯河 | FIXED | Literal original: 【杀】或普通基本牌; trigger now Slash or BasicCard (was isNDTrick); description/translation updated. |
| sk_buzhi 折节 | NOT-A-BUG | 品质 list says 弃牌阶段结束时, but two other original texts say 结束阶段; code matches the latter. Sources conflict. |
| sk_guanxing 武志 | NOT-A-BUG | 品质 list: 受到1点伤害; detailed text: 失去1点体力 (code). Sources conflict. |
| sk_wuxian 贺春 | NOT-A-BUG | Detailed text: 红色且已受伤才回复 (code); 品质 list omits it. Conflicting; code matches one literal text. |
| sk_zhugeguo 羽化/登仙 | NOT-A-BUG | Detailed text: 若手牌上限大于0才-1 and 登仙 改为额外摸牌/出牌阶段 (code matches); 品质 list differs; unconditional -1 would break 登仙's limit==0 check. |
| sk_zhuzhi 安国 | NOT-A-BUG | Both original texts: 武器 -> 你摸X, 防具 -> 其回复1点, 坐骑 repeat; code matches. No 奇门牌 branch in original text. |
| sk_zuoci 千幻 | NOT-A-BUG | 品质 list (keep ≤2, +2 new, exclude 限定/觉醒) conflicts with detailed text (lose any, refill to two, 限定/觉醒 allowed); code matches the latter. Sources conflict; rewrite would be a guess. |

Verification: `luac -p` on extensions/sk.lua OK (hunlie.lua has a pre-existing parse error under stock luac at line 9251, identical on HEAD; engine not run).

fixed=6 skipped=0 notbug=6
