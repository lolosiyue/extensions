# GU huanle fix 20261015 — hlxg_simayi, hlxg_jiangwei3

## Original text
hlxg_simayi (jilue.md:1331, 手杀神司马懿):
- 忍戒：锁定技，当你于弃牌阶段弃牌后或当你受到伤害后，你获得X枚“忍”标记（X为弃牌数或伤害值）。
- 连破：你杀死其他角色后，此回合结束后，你执行一个额外的回合。
- 极略：你可以弃置1枚“忍”标记，然后发动“鬼才”、“放逐”、“集智”、“完杀”（、“制衡”）。
- HL translation in repo: 极略 "你可以弃1枚“忍”，发动下列一项技能：〖鬼才〗、〖放逐〗、〖集智〗或〖完杀〗…"

hlxg_jiangwei3 (newgenerals.lua keolranji, OL谋姜维, nearest source):
- 燃己：限定技，结束阶段，若你本回合使用过牌的阶段数：不小于体力值，你可以获得“困奋”；不大于体力值，你可以获得“诈降”。…
- 逐日 matches keolzhuri. Original 困奋/诈降 standalone text not found in repo.

## What changed (extensions/offline.lua only)
- simayi: 完杀/放逐/集智/鬼才 are no longer general skills. A hidden `#hlxg_jilve_react` (owned only with 极略 and ≥1 忍) offers 放逐 (on Damaged), 集智 (on non-transformed normal trick use), 鬼才 (on AskForRetrial); each costs 1 忍 via 极略 (c203_jilve). 完杀 is obtained for the turn via active 极略 (mark `hlxg_jilve_wansha-Clear`), which `#hlxg_wansha_simayi_limit` now checks. Removed the standalone 完杀 trigger and skill objects.
- jiangwei3: 困奋 and 诈降 (+ #mod) are only registered via extension_hl:addSkills, not added to the general; 燃己 grants them with acquireSkill (unchanged).
- Not touched: ai/, translations, .staging, other generals.

## Unverified
- luac (5.1) cannot parse the whole file (preexisting Lua 5.3 `&` at line 2802); only the edited simayi block was syntax-checked. Not run in game.
- Whether acquireSkill works for skills registered only via extension:addSkills (relied on same pattern as ranji_record); #zhaxiang_mod acquired via related-skill link needs in-game check.
- 制衡 option from original 极略 is absent (HL text omits it); original 鬼才/放逐/集智/完杀 literal text not in materials.
- AI keys (@hlxg_guicai, hlxg_fangzhu_simayi, hlxg_jizhi_simayi) still used as reason strings; the AI for the new trigger is unverified.
