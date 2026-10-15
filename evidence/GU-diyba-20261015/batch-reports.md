### b01
b01 report (luac/lua not installed; syntax check not run)
- 薛灵芸 diyba_10j_xuelingyun: done. kingdom not in excerpt, set to wei (female). 涟洏 limit uses card-limitation "use" pattern .|.|n~13 until turn end; virtual cards limit skipped when number 0. 暗织 "latest entered batch" approximated as the last CardsMoveOneTime into the discard pile, filtered to cards still there.
- 罗宪 diyba_10j_luoxian: done. kingdom not in excerpt, set to shu. 示烈 approximated: hand cards only, must pick cards whose number sum >= X; play-phase slash and slash/jink response.
- 张悌 diyba_10j_zhangti: done. kingdom not in excerpt, set to wu. 逆势 "least hand" treated as <= every other player. 称号 RE not encoded (only the 玉壶-style title #name used).
- 诸葛靓 diyba_10j_zhugejing: done. kingdom not in excerpt, set to wei. 三思 switches state on use (①->②->③->①); 重铸 hand cards only; state held in mark diyba_sansi_state. 竭忠 reset on ③ clears the per-round used mark.

### b02
b02 report (no luac/lua in environment; syntax NOT machine-checked)
- 7 刘宏 (3D10J 007): done (partial). Kingdom not in excerpt; used 群 (consistent with 党锢 text). Name diyba_10j_liuhong, skills diyba_shixing / diyba_dangu.
  - 失兴: approximated by granting/detaching xiangle/jiushi/zhiheng via handleAcquireDetachSkills, refreshed on CardUsed / round start / Death. Trick-used flag kept in a room tag.
  - 党锢: end-phase chaining implemented; the part "other players' discard phase, chained -> equip counts as hand cards" NOT implemented (no safe API). Note: "回合结束时" implemented as the Finish phase of any holder's own turn.
  - Translation: 失兴 text prefixed with 锁定技 literally per excerpt; title/designer from excerpt (称号 RE not emitted as title since #name = 乱既损何 from excerpt header).
- 8 黄祖 (3D10J 008): skipped. 屯守 needs face-down cards on the general card with per-card flip and effect replacement; implementation impossible with available V2 API.
- 1 牵招: skipped. No 3DxxJ code in excerpt, so general name cannot be derived; kingdom also missing.
- 2 娄圭: skipped. No 3DxxJ code; also 防具栏 "凝备" card and 轮次 effects not implementable.
Counts: done 1, skipped 3.

### b03
b03 (3D12J; excerpt gave no 3DxxJ code or kingdom -- code 12j taken from diyba.md §4.3 grouping, kingdom = historical, not in source)
- 廖立 騧足难踏: skipped -- 忿论 needs "card was responded by a card" tracking plus multi-player pindian (no safe API); 弃才 depends on per-round pindian-loss counter
- 胡济 忠荩之效: skipped -- 渐军 relies on explicit/hidden hand-card (明置/暗置) mechanic absent from the engine
- 孙和 季子绝途: done (diyba_12j_sunhe, wu, 3hp) -- approximations: kingdom wu assumed; "cancel the card" implemented by returning true from on_effect on CardUsed and refunding history (-1); per-round tracking via an upvalue round counter on RoundStart; 党乎 grant removed at next RoundStart; the 命也 give option reuses an skill-invoke prompt
- 周处 云蛟何惧: done (diyba_12j_zhouchu, wu, 5hp) -- approximations: kingdom wu assumed; "删除【】中的内容" has no defined content in source, not implemented
- Syntax check: no lua/luac available in environment; files not compiled

### b04
- 轲比能 diyba_xj_kebineng: done (partial). No 3DxxJ code, edition tag 'x'. Kingdom qun inferred from 附义 text. 枭行 range/maxcards +3 implemented; the dying clause (round > 1, weapon, abolish slot, lose skill) NOT implemented. 狼志 implemented approximately (shown cards chosen via AG; replace = swap with equal owner cards). 附义 skipped: no 奖惩 mechanism available.
- 张闿 diyba_xj_zhangkai: done (partial). Code 'x'. Kingdom assumed qun (not in excerpt); "3/4体力" taken as 4. 拜泪 implemented; 劫行 skipped (intercepting recover / equip placement and skill-count reset not feasible).
- 王忠 diyba_14j_wangzhong: skipped. 谄徇/造王 need identity-card swap and win-condition rewriting; 噉骨 alone is not a faithful port.
- 陈祗 diyba_14j_chenzhi: skipped. 异术 requires cancelling and redirecting another player's card use with per-card tracking; not implementable safely.
Syntax check: luac/lua not available in environment; files not compiled.

### b05
b05 report (no luac/lua in environment; syntax NOT machine-checked)
- 4 阎宇 (3D14J004): skipped. 励镇 needs post-resolution-of-all-targets hook on physical cards, per-card-name once-per-turn tracking, damage prevention with hand-reveal comparison and arbitrary reforge; not implementable reliably with V2 API.
- 5 李娥 (3D14J005): done (partial). Name diyba_14j_lie, wu, 3 hp, female. 冶身 implemented (pile-bottom reveal via getDrawPile, chosen card used as virtual iron_chain with target cap = name length of the real card, else recast approximated as discard + draw 1, counter in mark diyba_yeshen_x, reset + 1 fire damage). Approximations: draw-pile bottom taken as last ids of getDrawPile; revealed rest returned to top via moveCardTo; chain use with a pile card may not resolve in every engine build. 巧锻 NOT implemented (no chain-state-change event hook known).
- 6 张承 (3D14J006): done (partial). Name diyba_14j_zhangcheng, wu, 3 hp. 隽轨 implemented (draw 2, show hand, discard one per distinct suit, optional regain of discard-pile cards matching suits used by owner this turn; suits tracked by hidden rule skill #diyba_jungui_record, reset at RoundStart). Approximation: "其中" read as the target's whole hand after drawing. 聚贤 NOT implemented (complex dual-option sequence with ownerless zones).
- 7 鲍信 (3D14J007): done (partial). Name diyba_14j_baoxin, qun, 4 hp. 先觉 implemented: skip Judge/Draw/Play/Discard/Finish via player:skip; prep phase views top 5 with AG, obtains and tries askForUseCard on id pattern (may be unreliable); extra phases approximated as the first X of Judge/Draw/Play/Discard/Finish run via player:play with a tag bypassing the skip. Damage-card kinds: Slash, Duel, FireAttack, ArcheryAttack, SavageAssault, Lightning.
Counts: done 3 (all partial), skipped 1.

### b06
b06 report (luac/lua not installed; syntax check not run)
- 袁熙 diyba_14j_yuanxi: done (纨纨/然然/凛凛). Replace-phase done by returning true on EventPhaseStart (skip body) then insertPhase for the extra phase. 然然 "same type" tracked via CardUsed record during two askForUseCard prompts; 纨纨 recasts via room:recastCards. 以逸待劳 name tried as await_exhausted then heg_await_exhausted.
- 神袁绍 diyba_14j_shenyuanshao: skipped. 迭王 (carries across games / pre-role-assignment) and 累业 (retiming 乱武 to next play phase, conditional 积阀 transfer) not implementable; 积阀 per-round-per-item multi-phase logic not ported alone to avoid a half-general.
- 丁斐 diyba_15j_dingfei: done. 3勾玉 -> 3 hp, wei. 畜突 "its target cannot use cards on others" approximated via use-card limitation (all cards, whole turn); option 2 picks via AG. 坦婪 exchange is hand-card swap if target gives >= X cards.
- 秦朗 diyba_15j_qinlang: done (partial). 4勾玉 -> 4 hp, wei. 征云 only implements first stage (damage card as 逐近弃远); the chained 无中生有/增兵减灶/ordered-trick stages approximated away (impossible to track card acquisition safely). Damage-card set: Slash, Duel, FireAttack, ArcheryAttack, SavageAssault. Card name zhujinqiyuan taken from existing ai file.

### b07
b07 report (luac/lua not installed; syntax check not run)
- 徐邈 diyba_15j_xumiao: done. kingdom not in excerpt, set to wei. 3体力 from 三勾玉. 绘骨: "drank" mark is treated as 酒 state; instant cards that entered the discard pile this turn are tracked via CardsMoveOneTime; single target chosen via askForPlayerChosen (Collateral unsupported). 清贤: item events approximated by CardFinished (use), draw-reason CardsMoveOneTime (draw), MarkChanged on "drank" (enter/leave); "use a card" via askForUseCard.
- 霍弋 diyba_15j_huoyi: skipped, 御境/望陵 depend on card "path length" relative to player and lord with swappable object clauses; no engine primitive, implementation impossible without inventing semantics.
- 郭攸之 diyba_15j_guoyouzhi: skipped, 广和 needs 议事 with opinion cards/majority-minority/proposer mechanics and 裨阙 is its partner; no yishi API found in offline package.
- 杨戏 diyba_15j_yangxi: done. kingdom not in excerpt, set to shu. 妙锦: counts physical (non-virtual) basic/non-delayed-trick uses, any two consecutively; choose which card supplies suit/number; candidate names scanned from engine card pool by exact suit+number; single target. 弛衡: fires at other players' Finish phase; round-limit reset on RoundStart; penalty applies on next 妙锦 use of different type (type stored as tag).

### b08
- 7 徐琨 (diyba_15j_xukun): skipped - "冰冻伤害" distribution / forced discard-effect / nested 无懈可击 and 随机应变 conversion has no engine primitive; implementation impossible without inventing mechanics.
- 8 张布 (diyba_15j_zhangbu): skipped - "柄" cards hidden under specific hand cards with positional linkage; not implementable.
- 9 潘濬 (diyba_15j_panjun): skipped - ordered "毫末" pair-grid with parity/suit/type bonus tracking and replacement; not implementable.
- 10 步度根 (diyba_15j_budugen): done. Approximations: "结算后" is done synchronously after room:useCard returns; swap choice by target via askForChoice (swap/noswap); "再次发动" re-runs the effect directly (no extra once-per-phase count), requires same target and not prohibited; draw/re-invoke are asked via askForSkillInvoke.
- Syntax check: luac/lua not available; not run.

### b09
b09 report (luac/lua not installed; syntax check not run)
- 张举&张纯 diyba_15j_zhangjuzhangchun: done. 7勾玉 -> hp 7; kingdom 群. Health cards approximated with marks: random 3/4 split (sum 7); flip = value -1 (face-down) / +1 (back); 举乱 odd/even check and 南蛮入侵 implemented; 虏略 converts single-target non-delayed tricks to 杀 at CardUsed and draws+turns over when 弥天 first hits 0; "不再计入体力上限" is not modelled (hp/maxhp not reduced).
- 庞淯 diyba_xj_pangyu: done. No 3DxxJ code, tag 'x'; kingdom missing, set to qun; hp 2. 奋忠: 野心家=renegade role, 小势力=kingdom count below the largest, 被围攻 approximated as both neighbours sharing a different kingdom. 铭烈: exchange n-for-n hand cards; end-of-turn slash via askForUseSlashTo.
- 司马芝: skipped, 体力上限1.5 (non-integer hp).
- 邓方 diyba_xj_dengfang: done. No code, tag 'x'; kingdom missing, set to qun; hp 2. 果毅 option 1 limits the user (邓方) to the colours of the two given cards (no limit if both colours); option 2 asks to discard a card of the target after each of 邓方's uses.

### b10
- 廖立 (鸠雀攀凰, 技能设计 静谦): skipped, 体力1.5.
- 刘基 (玉络风行, 技能设计 小菲德): skipped, 体力1.5.
- 朱异 diyba_xj_zhuyi (大节巉天, 猪): done. Edition tag 'xj' (no 3DxxJ code). Kingdom 'wu' not in excerpt (historical assumption). 更狩: each candidate chooses draw/discard/cancel per Damage; "no card obtained in Play phase" tracked by a record skill (mark diyba_gengshou_got).
- 阎行 diyba_xj_yanxing (贰心顾瞻, 静谦): done. Kingdom 'qun' not in excerpt (assumption). 叛约 approximations: card name "fight_together" (fallback "heg_fight_together"); owner is used as faction representative so targets include self; "摸牌" approximated as owner being chained before use; slash used by the other target is aimed at a target of their choice (excerpt gives no victim); if multiple other targets, owner picks one; if slash not in discard pile after resolution, nothing happens.
- luac/lua not installed; syntax unchecked.

### b11
b11 report (luac/lua not installed; syntax check not run)
- 成公英 (成公英 呈何共盈, no 3DxxJ code): skipped, hp 1.5 not supported per brief.
- 姜叙 diyba_17j_jiangxu: done (wei 4, 3D17J 001). 峙围 approximated: X counts alive players (incl. self) whose attack range covers you, min 1; targets must have hand cards; self always participates; red = each participant may discard a card then draw 1, black = may use one hand card (askForUseCard) then draw 1; the "展示至多X张同色手牌" clause not implemented; result passed via YishiResultConfirmed record skill. 恪义 approximated as a view-as of the last hand card to ex_nihilo (play phase) or peach (otherwise); the "only" restriction and the duel-on-self rule are not enforced.
- 焦彝 diyba_17j_jiaoyi: skipped. 理棼/揆势 depend on the derived skill 急攻, whose text is not in the excerpt (cannot invent it).
- 马忠 diyba_17j_mazhong: done (shu 4, 3D17J 003). 威绥 combo = damage card followed by non-damage card within one turn (Slash/Duel/SavageAssault/ArcheryAttack/FireAttack counted as damage cards); other-area count covers draw pile, all equip/judge areas, other players' hands; option 1 uses repeated invoke prompts; option 2 puts cards to draw pile bottom via moveCardsToEndOfDrawpile (fallback: top).

### b12
b12 (3D17J)
- 李恢 diyba_17j_lihui: done. 蜀, hp 3. 推己 extra give/discard cards not modelled; 复定 闪 option approximated by 杀 (闪 cannot be used actively), hand adjusted to 1 by discard/draw.
- 蒋钦 diyba_17j_jiangqin: done. 吴, hp 4. 蓄矢 queues n turn-ends via tag and uses 杀 with extra targets that lost cards that turn (mark-based); 尚义 last damager tracked via room tag, per-round options via marks.
- 何姬 diyba_17j_heji: done. 吴, hp 3. 恤遗 offered at dying or play-phase start of hand-less characters (no real "any time" hook); 序仪 nullification with all hand cards, once per hand count (tag), +1 hand limit via mark MaxCards.
- 魏讽 diyba_17j_weifeng: done. 群, hp 3. 荧谈 takes the first 杀 in the discard pile; 不可被抵消 via no_respond_list. 掖反 uses pattern "BasicCard,TrickCard|.|.|hand" (delayed tricks not excluded), unlimited use via flag + TargetMod; repeat/next-target flow approximated.
Syntax check: luac/lua not installed; not run. Note 蓄矢 once-per-phase approximated as once per turn (mark -Clear).

### b13
- 董白 (diyba_17j_dongbai): skipped - 猫眼 needs per-player card visibility/use-from-pile-bottom of other players' obtained cards, 享恶 depends on an undefined "崩坏" skill, 织乱 needs replacing weapon-acquisition with a three-party card exchange; not implementable with SkillV2 without inventing behaviour.
- 神·董卓 (diyba_17j_shendongzhuo): skipped - 揽娇 draws female generals from the general pile to replace 勾玉 and borrows neighbours' skills by seat; 献艳 swaps generals and changes gender; engine support absent.
- 神·萧衍 (diyba_18_shenxiaoyan): skipped - 皆识 requires picking limit skills from a pool and binding to round numbers; 尽空 carries skills into the next game; not implementable.
- 魔·高洋 (diyba_18_mogaoyang): skipped - 隐匿技 with player-defined X, 反贼/忠臣 death-count rounds and deferred kingdom choice; not implementable.
Syntax check: skills.lua / ai.lua contain only comments (trivially valid).

### b14
# b14 report (edition tag 18j; no 3DxxJ code needed)
- 朱由校 (3D18 003): skipped - three interlocking skills (per-round shared trigger on Slash/Peach participation, conditional discard branches, end-of-turn HP loss, self-removal into Wuzhong, extra-target attack-range tracking, lord-skill limited retrieval that rewires another skill); no faithful V2 implementation without inventing rules.
- 上官婉儿 (3D18 004): skipped - 玉秤 needs a persistent pile of cards on the general card, per-round recast hooks and end-of-round "use pile cards" on all participants; 用晦 needs per-phase deferred draw/discard and club-card-to-discard-pile value bump. Text too underspecified ("其中一项数值") to implement without inventing.
- 李牧 (3D18 005): skipped - 雁守 text is garbled/ambiguous ("若你仅以:技能耗尽所有次数时", unclear quota accounting and "令此技能发动次数-1"); cannot implement without inventing.
- 妇好 (3D18 006): skipped - 平夷 requires restarting the play phase; 卜尊 requires using the max-range weapon / sole armor from other players' areas as a free use; not cleanly doable in V2 and no partial approximation made.
No approximations made. skills.lua and ai.lua are comment-only.

### b15
# b15 report
- 扶苏 (3D18 007): skipped - 干城 rewrites multi-target card targets mid-use with per-target attack-range draws; 嵩泣 needs multi-phase Slash bans, round-scoped basic-card conversions and an end-of-round conditional lose-HP; no faithful V2 implementation without inventing rules.
- 李隆基 (3D19J 001): skipped - 昂扬技 state conversion, 兴歇 hand-size comparison with "整个手牌上限", 遽盛 doubled draw/discard with cancel-next-draw debt, 统寰 temporary skill loss and refresh of another's skills; not implementable cleanly.
- 安禄山 (3D19J 002): skipped - 肥舞 seat swapping by point vs seat number, 横势 extra turn/flip choice at original seat, 僭窃 shared skill grants; seat-order mutation and extra turns not safely doable in V2.
- 史思明 (3D19J 003): skipped - 狈奸 three-round cooldowns with unique-max conditions, response by chaining and cooldown rewind; 旋势 state-dependent cross-name use/response; too underspecified to implement without inventing.
No approximations made. skills.lua and ai.lua are comment-only.

### b16
# b16 report (edition tag 19j, from 3D19J)
- 杨国忠 (3D19J 004): skipped - 织涌 needs replacing the draw phase with a board-card move plus Collateral use, re-running the whole turn on damage, and turning on-demand conversions on; 掩涛 has per-round per-option once-limits, three variable draw targets and an exhaustion-triggered re-fire. Not implementable in V2 without inventing rules.
- 郭子仪 (3D19J 005): skipped - 振义 needs "明置" (revealed) card state, using other players' revealed Slash, and a second settlement for targets in both ranges; 忠旌 needs first/last rebel death tracking and handing an effect to another player. No faithful V2 implementation.
- 李光弼 (3D19J 006): skipped - 简战 needs a custom pile on the general card, suit-distinct selection, and three heterogeneous deferred effects (next draw count, round attack range, all hand cards) copied from a chosen target. Not implementable without inventing.
- 张巡 (3D19J 007): skipped - excerpt text truncated mid-sentence (遏势 ends at "可以视为使用一张本"); 奋羸 also needs per-round single-target damage tracking with conditional unresponsive/draw sub-effects. Never invent text.
No approximations made. skills.lua and ai.lua are comment-only (luac not run; files contain only comments).

### b17
b17 report
- 颜真卿 (diyba_19j_yanzhenqing): done. Kingdom 唐 is not a valid kingdom, used "qun"; hp 3. Approximations: 玄文 picks card names from a fixed list of ~20 basic/trick names by translated char count, single target only; "flexible" rule: black more -> X+-1, red more -> also trigger from value 1; field cards counted as equip+judge area. 苍骨 marks are cleared as specified (on dealing damage / on recovering); marks persist if owner dies.
- 李泌 (3D19J 009): skipped. 扫蚁/梳龙 need forced showing/use of Slash by others with neighbour-based draw/damage tracking and chained hand adjustment, implementation impossible without invention.
- 杨玉环 (3D19J 010): skipped. 奢荔/享国 require multi-player simultaneous hand exchange with card-to-peach/ex_nihilo conversion and per-turn tracking; implementation impossible reliably.
- 王守仁 (3DRE0 001): skipped. 彻知/著疆 depend on tracking quota turns per round, extra turns at round end, and multi-pindian rewrite of Slash user/targets; implementation impossible.
- luac/lua not run (not available in environment).

### b18
2 张献忠 (3DRE0 002): skipped - 大厦倾 needs shuffling a general card into the draw pile as a restricted ♠7 thunder slash; not implementable. 义军起 also unreliable.
3 钱德拉·鲍斯 (3DRE0 003): skipped - 议事 colour-gated modify/execute of 歧路行, and 虚位 seat-order rewriting, not implementable safely.
4 迈克尔·柯林斯 (3DRE0 004): skipped - 难国事 grants modified variants of other skills to others; not implementable.
5 李火旺 (3DRE0 005): done as diyba_re0_lihuowang, hp 4. Approximations: kingdom not in excerpt -> qun; 转化牌 = virtual card with subcards, 虚拟牌 = any virtual non-skill card; 坠真假 target excludes self; 登长阶 "reset one skill" resets 登长阶 history plus the other two skills' per-turn marks; extra target applies to the next non-登长阶 card used this turn (mark is not cleared at turn end, so it may carry over); 修实虚 recast via RECAST move + draw, revealed = new hand cards.

### b19
- 6 后藤独 (re0j): skipped - 四色狂想 depends on the per-suit effects of "悲歌" which the excerpt does not define for this general, plus dynamic invalidation of 自我拉扯 clause and per-phase range/use-limit scaling; cannot port without inventing behavior.
- 7 早川秋 (re0j): skipped - 剑心 needs engine-level changes (suppress kill reward/penalty, allow Jink to answer Duel) not covered by SkillV2 pattern samples; implementing only part would misrepresent the skill.
- 8 星野爱 (re0j): skipped - 溯爱 (per-suit target restriction on Peach, removable suits, view-as non-basic) and 谎织 (active skill usable by other injured players, with multi-branch chains) too intricate to implement reliably without testing.
- 9 嘉然 (re0j): skipped - 共筑高塔 option-tracking with conditional reset and 嘉心糖 declaration/permanent 粉籍 removal are undefined in engine; implementation impossible.
Edition tag derived from 3DRE0 -> re0. No approximations; luac not needed (comment-only files).

### b20
- 东雪莲 diyba_re0_dongxuelian (玉池莲绽, 三勾玉 -> hp 3, 设计 秦心): done. Code 3DRE0 -> tag 're0'. Kingdom 'qun' not in excerpt (assumption).
  - 花海赤途: any red card's damage (DamageCaused) or recovery (PreHpRecover) can be +1; skips queued in mark and applied at the next own RoundStart, in order draw -> play -> discard (max 3 queued).
  - 藕节铸骨: implemented as an extra askForSkillInvoke inside 花海赤途 resolution (skill itself has no events); requires own turn and wounded; 重整 approximated as skipping all phases of own turns and recovering 1 hp per own turn until full (no engine 重整 state).
  - 碧血丹心: "一轮结束时" approximated by sgs.RoundStart of the next round (first round ignored); "未执行完整回合" = Finish phase not reached or phases skipped via 花海赤途/重整; 涉猎 re-implemented (5 cards, one per suit), then a discard-down-to-maxcards. Extra turn via gainAnExtraTurn when leaving 重整; red cards ignore distance/residue limit via TargetModSkillV2 marks (target count unaffected).
- luac/lua not installed; syntax unchecked.

### b21
- diyba_12j_qianzhao 牵招 (wei, 4hp): done. diyba_yuanzhen, diyba_zhirong.
  - Approximation: 制戎 "出牌阶段限开始时" implemented as start of own Play phase, once; equip moved via moveCardTo (replaces existing equip in slot); 过河拆桥 skipped if prohibited or target has no cards; to-target AI picks via shared playerchosen hook.
  - 远振 requires card use with exactly one target; draw-only if target has no cards.
