# GU diyba fix report

Fix commit: 283202f (branch qs-claude/gu-diyba-20261015, not pushed)

Both files load under lupa (Lua 5.4). `luac -p` (5.1) rejects offline.lua at line 2802 (`&` operator) — pre-existing at HEAD, unrelated.

## Fixed (5)

- diyba_xj_dengfang (邓方): Option 1 is offered only if the target has 2+ cards (no free exemption), colour limit now forbids every colour (red/black/colourless) not among the given cards, option 2 triggers after each card the owner uses this turn.
- diyba_xj_zhuyi (朱异): 更狩 end-phase check now tracks ids of cards obtained this Play phase and only allows the Slash if none of them is still in hand; removed the used-up mark logic.
- diyba_10j_zhangti (张悌): 逆势改为严格手牌最少（小于其他角色最小值）才先摸牌至多一张；覆江原实现已为获得者手牌时由张悌弃置/造成伤害，保持不变。
- diyba_10j_zhugejing (诸葛靓): 三思取消对装备区牌的限制，装备区牌亦可重铸；竭忠流程（回复至1、转换、再判①失血/③重置）与原文一致，保持不变。
- diyba_15j_dingfei (丁斐): Option 2 now only forbids using cards on other players (prohibit skill with mark), option 1 text corrected, discard of four hand cards chosen by the target.

## Skipped / removed (26)

- diyba_14j_lie (李娥): 巧锻 needs unrealistic tracking, 冶身 needs real bottom-of-pile reveal, a true recast and a hard target-count cap; none expressible literally, so removed.
- diyba_14j_zhangcheng (张承): 聚贤 (per-option-once, zone swap with colour-conditional chaining to another target) not literally implementable; 隽轨 per-suit forced discard and end-of-turn suit record also approximate, so removed.
- diyba_14j_baoxin (鲍信): 先觉 X must count cards that actually cause damage and the extra phases after the X count are not literally expressible with the engine's phase API, so removed.
- diyba_10j_liuhong (刘宏): 党锢「弃牌阶段连环角色装备区牌视为手牌」需引擎级手牌/装备转换，无法字面实现；失兴只能靠事件刷新动态增删技能模拟，故整体移除。
- diyba_12j_sunhe (孙和): 命也「使用时取消此牌、不计次数」无法在引擎中可靠字面实现（CardUsed取消及次数回退不可验证），干净移除（含党乎及轮次记录技能）。
- diyba_12j_zhouchu (周处): 侠横末句「删除【】中的内容」原文无任何可指代对象，无法字面实现，故移除。
- diyba_15j_zhangjuzhangchun (张举&张纯): Health cards (flip, per-card gouyu, excluded from max HP) cannot be expressed literally; previous mark simulation was an approximation.
- diyba_xj_pangyu (庞淯): Fenzhong depends on Guozhan-only concepts (ambitious, small kingdom, besieged) that do not exist in identity mode; only approximations possible.
- diyba_re0_dongxuelian (东雪莲): 藕节铸骨/碧血丹心 need a real 重整 state, 一轮结束时 timing and 使用红色牌仅受目标数限制 rules which the engine cannot express literally; previous code was a simulation, so the general was removed cleanly.
- diyba_xj_yanxing (阎行): 叛约 needs custom 勠力同心 targeting (targets must include self plus others), actual-draw detection and undefined slash target; cannot be literal.
- diyba_17j_jiangxu (姜叙): 峙围 shown-cards-in-yishi and 恪义 exclusive restriction/duel-on-self cannot be expressed literally with current engine hooks.
- diyba_17j_mazhong (马忠): 威绥 needs draw-pile-bottom placement, all-zone moves and correct recover which are not reliably supported; clean skip.
- diyba_10j_xuelingyun (薛灵芸): 暗织「最近进入并在弃牌堆的牌」边界不明且无法精确追踪，整牌对目标无效与涟洏无点数虚拟牌的处理无法字面实现，故整体移除。
- diyba_10j_luoxian (罗宪): 示烈需要常态「明置」手牌及复合响应场景（决斗等）的使用时机，引擎无法字面表达，故移除。
- diyba_14j_yuanxi (袁熙): Replacing phases with exact use-two-cards/same-type tracking and forced targeting of the virtual tricks cannot be expressed literally; removed.
- diyba_15j_qinlang (秦朗): The four-stage chained conversion tied to cards obtained from prior uses is not implemented literally and not feasible; removed.
- diyba_15j_xumiao (徐邈): 绘骨 has no timing restriction in the text (usable at response timings, Collateral/multi-target cards) and 清贤 depends on MarkChanged tracking; cannot be made literal, so removed.
- diyba_15j_yangxi (杨戏): 妙锦 must support Collateral and multi-target cards (unsupported by the helper) so a literal implementation is not feasible; removed with 弛衡.
- diyba_re0_lihuowang (李火旺): 登长阶 extra target for the next card cannot be literally implemented for Collateral/fixed-target cards; removed whole general.
- diyba_17j_lihui (李恢): 推己 extra give/discard of arbitrary cards and 复定 viewing as 闪 (plus hand-adjust/reveal chain) cannot be implemented literally in the engine.
- diyba_17j_jiangqin (蒋钦): 蓄矢 deferred multi-turn slash scheduling with extra targets who lost cards, and 尚义 per-round per-item last-damage-source tracking, are only approximable.
- diyba_17j_heji (何姬): 恤遗 triggers on any hand-less character at any time and hand-to-limit draw semantics cannot be matched literally; 序仪 depends on it.
- diyba_17j_weifeng (魏讽): 荧谈 (round-wide discard-phase pickup, uncounterable via revealed hand) and 掖反 (repeat flow with instant-card use) not expressible literally; prior code was an approximation.
- diyba_xj_kebineng (轲比能): Lord skill 附义 depends on the reward/punishment (奖惩) system and 枭行's weapon-slot abolition plus 狼志's show/replace semantics cannot be expressed literally; clean skip.
- diyba_xj_zhangkai (张闿): 限定技 劫行 requires replacing other players' HP recovery and equipment placement with skill-count reset; the engine has no literal hook for this, so skipped along with 拜泪.
- diyba_19j_yanzhenqing (颜真卿): 玄文 needs card-name character-count selection, flexible X and trigger-value shifting, and multi-target tricks, which cannot be implemented literally; skipped.

Notes: fixed generals were not runtime-tested (e.g. recast of equipped cards for 诸葛靓, colourless card limitation pattern for 邓方). 张悌 覆江 and 竭忠 were judged already literal and left unchanged.
