# Original Hegemony AI bundle

来源：`TODO/QSanguosha-For-Hegemony-xxyheaven`，固定 revision `cf61c15dd6772584f350d0f5254eb8ff2d61c0a8`。每个策略文件保留来源说明及原有版权头。本文描述源码移植检查点，不代表运行验收通过。

| 内容 | 接线 |
| --- | --- |
| 基础策略 | 标准牌、军争、观星、魏蜀吴群、明置、阵、势、势备，合并现有 V2 回覆适配。 |
| 新版策略 | transformation、power、manoeuvre、newsgs、mol、overseas、lord_ex。 |
| SmartAI | 保留现有 Room VM、初始化、事件派送与 mode policy；common 仅补决策 helper、公开知识查询与静态技能/武将价值表。 |
| 私有资料 | 实际武将只读当前 AI 的持有者；他人只读明置及持有者的原生 KnownBoth 知识。私有知识由原生动作写入，AI 不从广播事件复制暗将，也不使用 donor recorder/忠诚度表。 |
| 名称 | 差异技能及武将使用 `heg_`；共用技能沿用原生 ID；独立牌及 SkillCard 类别使用 `H...`，共用牌沿用原生类。 |
| Baseline mapping | Donor callbacks retain their source IDs; the loader mirrors registered callbacks to native HEG baseline IDs. Sunce/Zhouyu `yingzi` and Sunjian/Sunce `yinghun` map to distinct variants; producers remain behind the existing V2 availability/source gate. |
| V2 | 标记行动走 ActiveSkillCard；珠联璧合/野心家救援使用普通 Peach；灭吴/鬼术回覆使用带技能名和素材的普通转换牌。 |
| 明置 | 沿用原生 HegemonyReveal，不发出不存在的 donor ShowHeadCard/ShowDeputyCard。 |

20 个 Lua 文件必须全部在 `package_ai` 声明，`heg-loader-ai.lua` 最后声明。其它文件的顶层 gate 保持独立声明无副作用；loader 仅在 EnableHegemony 下开启策略。新增七个文件为 `heg-transformation-ai.lua`、`heg-power-ai.lua`、`heg-manoeuvre-ai.lua`、`heg-newsgs-ai.lua`、`heg-mol-ai.lua`、`heg-overseas-ai.lua`、`heg-lord_ex-ai.lua`。

此 bundle 仍为 LegacyAdapted gameplay VM 策略。结构解析与命名/依赖静态核对已进行；Lua 执行、原生建置、完整对局和 CI 均未运行。原生 API/SWIG、各技能私有询问和实际牌效果须随整体国战检查点验收，不能从策略文件齐全推定规则或 AI parity 已通过。
