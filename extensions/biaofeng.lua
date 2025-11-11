-- Date 2013.5.24
--module("extensions.biaofeng", package.seeall)
extension = sgs.Package("biaofeng", sgs.Package_GeneralPack)
extension_six = sgs.Package("biaofeng_six", sgs.Package_GeneralPack)


sgs.LoadTranslationTable {
	["biaofeng"] = "标风重铸5.0",

	-----------------------------------------------魏---------------------------------------------------

	["CaoCao_Plus"] = "5.0曹操",
	["&CaoCao_Plus"] = "曹操",
	["#CaoCao_Plus"] = "超世之英杰",
	["designer:CaoCao_Plus"] = "锦衣祭司",
	["cv:CaoCao_Plus"] = "官方",
	["illustrator:CaoCao_Plus"] = "略  模板设计:赛宁",

	["PlusJianxiong"] = "奸雄",
	[":PlusJianxiong"] = "你即将造成伤害时，可以弃置一张黑色手牌并指定一名其他角色，然后视为由该角色造成此伤害。",
	["PlusJianxiong_Card"] = "奸雄",
	["#PlusJianxiong"] = "你可以弃置一张黑色手牌发动【奸雄】",
	["~PlusJianxiong"] = "选择一张黑色手牌→选择一名其他角色→点击确定",
	["#PlusJianxiong_msg"] = "%from 指定了 %to 造成此伤害",
	["plusjianxiong_"] = "奸雄",

	["PlusWulve"] = "武略",
	[":PlusWulve"] = "每当你受到一次伤害后，你可以选择一项：1.获得对你造成伤害的牌。2.弃置一张牌（无牌则不弃），然后摸X张牌（X为你已损失的体力值）。",
	["PlusWulve_choice1"] = "获得 %src",
	["PlusWulve_choice2"] = "弃置一张牌，然后摸 %src 张牌",
	["PlusWulve_cancel"] = "不发动",
	["#PlusWulve1"] = "%from 发动了技能“%arg①”",
	["#PlusWulve2"] = "%from 发动了技能“%arg②”",
	----------------------------------------------------------------------------------------------------
	["SiMaYi_Plus"] = "5.0司马懿",
	["&SiMaYi_Plus"] = "司马懿",
	["#SiMaYi_Plus"] = "狼顾之鬼",
	["designer:SiMaYi_Plus"] = "锦衣祭司",
	["cv:SiMaYi_Plus"] = "官方",
	["illustrator:SiMaYi_Plus"] = "略  模板设计:赛宁",

	["PlusLangmou"] = "狼谋",
	[":PlusLangmou"] = "每当你受到1点伤害后，你可以获得伤害来源的一张牌。",

	["PlusGuicai"] = "鬼才",
	[":PlusGuicai"] = "在一名角色的判定牌或拼点牌（限其中一名角色）生效前，你可以打出一张手牌代替之。",
	["PlusGuicai_Card"] = "鬼才",
	["@PlusGuicai_Pindian"] = "你可以发动【%dest】来修改一名角色的 %arg 拼点牌",
	["~PlusGuicai"] = "选择一张手牌→点击确定",
	["$PlusGuicai_PindianOne"] = "%from 发动 “%arg”把 %to 的拼点牌改为 %card",
	["$PlusGuicai_PindianFinal"] = "%from 最终的拼点牌为 %card",
	["plusguicai_"] = "鬼才",
	["@PlusGuicai-card"] = "请发动“%dest”来修改 %src 的“%arg”判定",

	["PlusTaohui"] = "韬晦",
	[":PlusTaohui"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的手牌数不大于你的体力上限，当其他角色使用非延时类锦囊牌指定你为目标时，需弃置一张手牌，否则此非延时类锦囊牌对你无效。",
	["@PlusTaohui"] = "%src 的【%dest】被触发，你需弃置一张手牌，否则此 %arg 对其无效",
	["#PlusTaohui_Discard"] = "%from 受到“%arg”的影响，弃置了一张手牌使【%arg2】对 %to 生效",
	----------------------------------------------------------------------------------------------------
	["GuoJia_Plus"] = "5.0郭嘉",
	["&GuoJia_Plus"] = "郭嘉",
	["#GuoJia_Plus"] = "早终的先知",
	["designer:GuoJia_Plus"] = "玉面",
	["cv:GuoJia_Plus"] = "官方",
	["illustrator:GuoJia_Plus"] = "略  模板设计:赛宁",

	["PlusTiandu"] = "天妒",
	[":PlusTiandu"] = "在你的判定牌或拼点牌生效后，你可以获得此牌。",

	["PlusYiji"] = "遗计",
	[":PlusYiji"] = "每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张放置在合理的位置，然后将另一张放置在合理的位置。\
◆“合理的位置”包括：牌堆顶、弃牌堆、一名角色的手牌区、装备区（若此牌为装备）、判定区（若此牌为延时类锦囊牌）。",
	["PlusYiji_Card"] = "遗计",
	["#PlusYiji"] = "请将 %arg 张牌放置在合理的位置\n（放置在牌堆顶或弃牌堆请不要选择角色，否则请选择目标角色；放置在弃牌堆或手牌可以选择2张牌）",
	["PlusYiji_hand"] = "手牌区",
	["PlusYiji_equip"] = "装备区",
	["PlusYiji_delayedTrick"] = "判定区",
	["PlusYiji_drawPile"] = "牌堆顶",
	["PlusYiji_discardPile"] = "弃牌堆",
	["$PlusYiji_Equip"] = "%from 将 %card 置于 %to 的装备区内",
	["$PlusYiji_DelayedTrick"] = "%from 将 %card 置于 %to 的判定区内",
	["#PlusYiji_DrawPile"] = "%from 将 %arg 张牌置于牌堆顶",
	["~PlusYiji"] = "选择一至两张牌→选择0至1名目标角色→点击确定",
	["plusyiji_"] = "遗计",
	----------------------------------------------------------------------------------------------------
	["XiaHouDun_Plus"] = "5.0夏侯惇",
	["&XiaHouDun_Plus"] = "夏侯惇",
	["#XiaHouDun_Plus"] = "独目的苍狼",
	["designer:XiaHouDun_Plus"] = "吹风奈奈",
	["cv:XiaHouDun_Plus"] = "官方",
	["illustrator:XiaHouDun_Plus"] = "略  模板设计:赛宁",

	["PlusGanglie"] = "刚烈",
	[":PlusGanglie"] = "当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标时，你可以失去1点体力，然后选择一项：\
1.令此牌对你无效，然后你获得此牌。\
2.令该角色也成为此牌的目标，然后你摸一张牌。\
◆你发动【刚烈②】之后依然为此牌的目标。",
	["PlusGanglie_choice1"] = "失去1点体力，令此牌对你无效",
	["PlusGanglie_choice2"] = "失去1点体力，令该角色成为此牌的目标",
	["PlusGanglie_cancel"] = "不发动",
	["#PlusGanglie1"] = "%from 发动了技能“%arg①”",
	["#PlusGanglie2"] = "%from 发动了技能“%arg②”，%to 成为【%arg2】的目标",
	----------------------------------------------------------------------------------------------------
	["ZhangLiao_Plus"] = "5.0张辽",
	["&ZhangLiao_Plus"] = "张辽",
	["#ZhangLiao_Plus"] = "古之召虎",
	["designer:ZhangLiao_Plus"] = "小A",
	["cv:ZhangLiao_Plus"] = "官方",
	["illustrator:ZhangLiao_Plus"] = "略  模板设计:赛宁",

	["PlusTuxi"] = "突袭",
	[":PlusTuxi"] = "摸牌阶段摸牌时，你可以少摸X张牌，然后获得X名其他角色的各一张手牌。",
	["PlusTuxi_Card"] = "突袭",
	["#PlusTuxi"] = "你可以发动【%dest】选择至多 %arg 名角色",
	["~PlusTuxi"] = "选择若干名角色→点击确定",
	["plustuxi_"] = "突袭",
	----------------------------------------------------------------------------------------------------
	["XuChu_Plus"] = "5.0许褚",
	["&XuChu_Plus"] = "许褚",
	["#XuChu_Plus"] = "虎痴",
	["designer:XuChu_Plus"] = "吹风奈奈",
	["cv:XuChu_Plus"] = "官方",
	["illustrator:XuChu_Plus"] = "略  模板设计:赛宁",

	["PlusLuoyi"] = "裸衣",
	[":PlusLuoyi"] = "你可以跳过你的摸牌阶段，然后获得以下技能直到回合结束：你可以将装备区里的一张装备牌当【决斗】或【杀】使用或打出；若你的装备区没有牌，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1。",
	["PlusLuoyi_Card"] = "裸衣",
	["@PlusLuoyi"] = "你可以将装备区里的一张牌当选择的牌使用",
	["@@PlusLuoyi"] = "你可以将装备区里的一张牌当选择的牌使用",
	["~PlusLuoyi"] = "选择一张装备区里的牌→点击确定",
	["#PlusLuoyi_Buff"] = "%from 的“裸衣”技能被触发，伤害从 %arg 点上升至 %arg2 点",
	["PlusLuoyi-new"] = "裸衣",
	["plusluoyi_select"] = "裸衣",

	["PlusHuwei"] = "虎卫",
	[":PlusHuwei"] = "当你需要使用或打出一张【闪】时，你可以失去1点体力，视为你使用或打出了一张【闪】。",
	----------------------------------------------------------------------------------------------------
	["XiaHouYuan_Plus"] = "5.0夏侯渊",
	["&XiaHouYuan_Plus"] = "夏侯渊",
	["#XiaHouYuan_Plus"] = "疾行的猎豹",
	["designer:XiaHouYuan_Plus"] = "锦衣祭司",
	["cv:XiaHouYuan_Plus"] = "官方",
	["illustrator:XiaHouYuan_Plus"] = "略  模板设计:赛宁",

	["PlusShensu"] = "神速",
	[":PlusShensu"] = "你可以选择一至两项：\
1.弃置一张装备牌并跳过你的判定阶段。\
2.弃置一张红色手牌并跳过你的出牌阶段。\
你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。",
	["@PlusShensu1"] = "弃置一张装备牌并跳过判定阶段，视为对一名其他角色使用一张【杀】",
	["@PlusShensu2"] = "弃置一张红色手牌并跳过出牌阶段，视为对一名其他角色使用一张【杀】",
	["~PlusShensu"] = "选择一张牌→点击确定",
	["PlusShensu_Card"] = "神速",
	["~PlusShensu1"] = "你可以弃置一张装备牌并跳过你的判定阶段。",
	["~PlusShensu2"] = "你可以弃置一张红色手牌并跳过你的出牌阶段。",
	["plusshensu_"] = "神速",
	----------------------------------------------------------------------------------------------------
	["CaoRen_Plus"] = "5.0曹仁",
	["&CaoRen_Plus"] = "曹仁",
	["#CaoRen_Plus"] = "险不辞难",
	["designer:CaoRen_Plus"] = "锦衣祭司",
	["cv:CaoRen_Plus"] = "官方，喵小林",
	["illustrator:CaoRen_Plus"] = "张帅  模板设计:赛宁",

	["PlusJushou"] = "据守",
	[":PlusJushou"] = "回合结束阶段开始时，你可以摸2+X张牌（X为存活角色的数量），保留等同于你体力上限值的手牌，将其余的手牌置于你的武将牌上，称为“守”，然后将你的武将牌翻面。当你的武将牌上有“守”时，其他角色计算与你的距离+1。",
	["defense"] = "守",

	["PlusKuiwei"] = "溃围",
	[":PlusKuiwei"] = "<font color=\"blue\"><b>锁定技，</b></font>其他角色的回合结束阶段开始时，若你的武将牌背面朝上，你须将一张“守”置入弃牌堆。回合开始阶段开始时，你获得你的武将牌上的所有“守”。",
	["$PlusKuiwei_Get"] = "%from 获得了全部的“守” %card",
	----------------------------------------------------------------------------------------------------
	["YuJin_Plus"] = "5.0于禁",
	["&YuJin_Plus"] = "于禁",
	["#YuJin_Plus"] = "魏武之刚",
	["designer:YuJin_Plus"] = "玉面",
	["cv:YuJin_Plus"] = "官方",
	["illustrator:YuJin_Plus"] = "Yi章  模板设计:赛宁",

	["PlusYizhong"] = "毅重",
	[":PlusYizhong"] = "当距离2以内的一名角色成为黑色的【杀】的目标后，你可以弃置一张手牌令此【杀】对其无效，若你弃置的牌为非基本牌，你可以摸一张牌。",
	["PlusYizhong_Card"] = "毅重",
	["@PlusYizhong"] = "你可以弃置一张手牌，令此【杀】对 %src 无效",
	["~PlusYizhong"] = "选择一张手牌→点击确定",
	["plusyizhong_"] = "毅重",
	----------------------------------------------------------------------------------------------------
	["YangXiu_Plus"] = "5.0杨修",
	["&YangXiu_Plus"] = "杨修",
	["#YangXiu_Plus"] = "恃才放旷",
	["designer:YangXiu_Plus"] = "小A",
	["cv:YangXiu_Plus"] = "幻象迷宫",
	["illustrator:YangXiu_Plus"] = "略  模板设计:赛宁",

	["PlusJilei"] = "鸡肋",
	[":PlusJilei"] = "每当你受到一次伤害时，你可以选择一种花色，然后令伤害来源展示其手牌，若其手牌有你所选择的花色，则该角色须弃置所有此花色的手牌，否则你弃一张牌。",
	----------------------------------------------------------------------------------------------------
	["LiDian_Plus"] = "5.0李典",
	["&LiDian_Plus"] = "李典",
	["#LiDian_Plus"] = "长者之风",
	["designer:LiDian_Plus"] = "玉面",
	["cv:LiDian_Plus"] = "暂无",
	["illustrator:LiDian_Plus"] = "略  模板设计:赛宁",

	["PlusJiangcai"] = "将才",
	[":PlusJiangcai"] = "你可以弃置一张基本牌并跳过你的出牌阶段和弃牌阶段，然后你可以依次获得至多三名其他角色的各一张手牌，再依次交给这些角色一张手牌。",
	["PlusJiangcai_Card"] = "将才",
	["plusjiangcai_"] = "将才",
	["@PlusJiangcai"] = "你可以弃置一张基本牌发动【将才】",
	["~PlusJiangcai"] = "选择一张基本牌→选择至多三名其他角色→点击确定",
	["@PlusJiangcai_Exchange"] = "请交给目标角色 %arg 张手牌",
	----------------------------------------------------------------------------------------------------
	["ChengYu_Plus"] = "5.0程昱",
	["&ChengYu_Plus"] = "程昱",
	["#ChengYu_Plus"] = "世之奇才",
	["designer:ChengYu_Plus"] = "锦衣祭司",
	["cv:ChengYu_Plus"] = "暂无",
	["illustrator:ChengYu_Plus"] = "略  模板设计:赛宁",

	["PlusYuanmou"] = "远谋",
	[":PlusYuanmou"] = "每当你受到一次伤害后，你可以弃置一张手牌，然后你可以令一名角色获得对你造成伤害的牌。",
	["PlusYuanmou_Card"] = "远谋",
	["plusyuanmou_"] = "远谋",
	["@PlusYuanmou"] = "你可以弃置一张手牌发动【远谋】",
	["~PlusYuanmou"] = "选择一张手牌→选择至多一名角色→点击确定",

	["PlusDanji"] = "胆计",
	[":PlusDanji"] = "当其他角色使用【杀】或非延时类锦囊牌即将对你造成伤害时，若其手牌数大于你的手牌数，你可以令此伤害-1。",
	["#PlusDanji_Decrease"] = "%from 发动了技能“胆计”，伤害点数从 %arg 点减少至 %arg2 点",

	-----------------------------------------------蜀---------------------------------------------------

	["ZhiGuoZhuGeLiang_Plus"] = "5.0治国诸葛亮",
	["&ZhiGuoZhuGeLiang_Plus"] = "诸葛亮",
	["#ZhiGuoZhuGeLiang_Plus"] = "固国安邦",
	["designer:ZhiGuoZhuGeLiang_Plus"] = "锦衣祭司",
	["cv:ZhiGuoZhuGeLiang_Plus"] = "暂无",
	["illustrator:ZhiGuoZhuGeLiang_Plus"] = "略  模板设计:赛宁",

	["PlusZhiguo"] = "治国",
	[":PlusZhiguo"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌并选择X名角色（X为此牌的点数，且最多为存活角色数），然后选择一项：令这些角色各摸一张牌，或各弃一张牌。",
	["PlusZhiguo_Card"] = "治国",
	["pluszhiguo_"] = "治国",
	["PlusZhiguo_Draw"] = "摸牌",
	["PlusZhiguo_Discard"] = "弃牌",

	["PlusFuzheng"] = "辅政",
	[":PlusFuzheng"] = "其他角色的摸牌阶段开始时，你可以弃置一张红色手牌令其摸牌时额外摸两张牌，然后你可以获得该角色此回合弃牌阶段所弃置的牌。",
	["PlusFuzheng_Card"] = "辅政",
	["plusfuzheng_"] = "辅政",
	["#PlusFuzheng"] = "你可以弃置一张红色手牌发动【辅政】",
	["~PlusFuzheng"] = "选择一张红色手牌→点击确定",

	["PlusPingluan"] = "平乱",
	[":PlusPingluan"] = "<font color=\"blue\"><b>锁定技，</b></font>【南蛮入侵】和【万箭齐发】对你无效。",
	----------------------------------------------------------------------------------------------------
	["LiuBei_Plus"] = "5.0刘备",
	["&LiuBei_Plus"] = "刘备",
	["#LiuBei_Plus"] = "乱世的枭雄",
	["designer:LiuBei_Plus"] = "玉面",
	["cv:LiuBei_Plus"] = "官方",
	["illustrator:LiuBei_Plus"] = "略  模板设计:赛宁",

	["PlusRende"] = "仁德",
	[":PlusRende"] = "出牌阶段，你可以将任意数量的手牌交给其他角色，若此阶段你给出的牌张数达到两张或更多，回合结束阶段开始时，你可以选择一项：\
1.你回复1点体力。\
2.令此回合你发动【仁德】指定的目标依次交给你一张牌。\
3.弃置一张红桃手牌，视为你使用一张【桃园结义】（此选项每局限一次）。",
	["PlusRende_Card"] = "仁德",
	["plusrende_"] = "仁德",
	["@rende"] = "仁德",
	["PlusRende_choice1"] = "回复1点体力",
	["PlusRende_choice2"] = "令此回合获得过你的牌的角色依次交给你一张牌",
	["PlusRende_choice3"] = "弃置一张红桃手牌，视为你使用一张【桃园结义】",
	["PlusRende_cancel"] = "不发动",
	["#PlusRende1"] = "%from 发动了技能“%arg①”",
	["#PlusRende2"] = "%from 发动了技能“%arg②”",
	["#PlusRende3"] = "%from 发动了技能“%arg③”",
	["@PlusRende_Return"] = "请交给目标角色 %arg 张牌",
	["#PlusRende_Salvation"] = "请弃置一张红桃手牌，视为使用一张【桃园结义】",
	["$PlusRende_Animation"] = "技能 仁德 的技能台词（求建议）",
	----------------------------------------------------------------------------------------------------
	["ZhuGeLiang_Plus"] = "6.0诸葛亮",
	["&ZhuGeLiang_Plus"] = "诸葛亮",
	["#ZhuGeLiang_Plus"] = "迟暮的丞相",
	["designer:ZhuGeLiang_Plus"] = "玉面",
	["cv:ZhuGeLiang_Plus"] = "官方",
	["illustrator:ZhuGeLiang_Plus"] = "木美人  模板设计:赛宁",

	["PlusGuanxing"] = "观星",
	[":PlusGuanxing"] = "回合开始阶段或回合结束阶段开始时，你可以观看牌堆顶的X张牌（X为存活角色的数量且最多为5），将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。每回合限一次。\
◆你在回合内只能发动一次【观星】，若在回合开始阶段发动，则回合结束阶段不能发动。",
	["PlusKongcheng"] = "空城",
	[":PlusKongcheng"] = "当你成为【杀】或【决斗】的目标时，你可以将所有手牌（至少0张）交给一名其他角色，然后你回复1点体力，且此【杀】或【决斗】对你无效。\
◆若你没有手牌，你依然可以发动【空城】，并且无需将手牌交给一名其他角色。",
	["PlusKongcheng_Card"] = "空城",
	["pluskongcheng_"] = "空城",
	["@PlusKongcheng"] = "你可以发动【空城】",
	["PlusKongcheng-invoke"] = "你可以发动【空城】",
	["~PlusKongcheng"] = "选择所有手牌→选择一名其他角色→点击确定",
	----------------------------------------------------------------------------------------------------
	["GuanYu_Plus"] = "7.0关羽",
	["&GuanYu_Plus"] = "关羽",
	["#GuanYu_Plus"] = "忠义双全",
	["designer:GuanYu_Plus"] = "锦衣祭司",
	["cv:GuanYu_Plus"] = "官方",
	["illustrator:GuanYu_Plus"] = "略  模板设计:赛宁",

	["PlusWusheng"] = "武圣",
	[":PlusWusheng"] = "你可以将一张牌当【杀】使用或打出，当你以此法使用的【杀】结算结束后，若其造成过伤害，你弃置一张牌；锁定技，你使用【杀】时按下列规则获得效果：红桃【杀】无距离限制；方块【杀】造成伤害时此伤害+1；梅花【杀】不计入出牌阶段限制的使用次数；黑桃【杀】无视目标角色的防具。",
	["#PlusWusheng_Diamond"] = "%from 的“武圣”技能被触发，伤害从 %arg 点上升至 %arg2 点",
	----------------------------------------------------------------------------------------------------
	["ZhangFei_Plus"] = "5.0张飞",
	["&ZhangFei_Plus"] = "张飞",
	["#ZhangFei_Plus"] = "万夫莫当",
	["designer:ZhangFei_Plus"] = "锦衣祭司",
	["cv:ZhangFei_Plus"] = "官方",
	["illustrator:ZhangFei_Plus"] = "略  模板设计:赛宁",

	["PlusPaoxiao"] = "咆哮",
	[":PlusPaoxiao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择并获得一项技能直到回合结束：你使用【杀】时可以额外指定X名目标，或你可以额外使用X张【杀】（X为你已损失的体力值且最多为2）。",
	["PlusPaoxiao_Card"] = "咆哮",
	["pluspaoxiao_"] = "咆哮",
	["PlusPaoxiao_choice1"] = "使用【杀】时可以额外指定 %src 名目标",
	["PlusPaoxiao_choice2"] = "可以额外使用 %src 张【杀】",
	["#PlusPaoxiao1"] = "%from 发动了技能“%arg①”，使用【杀】时可以额外指定 %arg2 名目标",
	["#PlusPaoxiao2"] = "%from 发动了技能“%arg②”，可以额外使用 %arg2 张【杀】",
	["PlusPaoxiao_extra"] = "额外使用【杀】",
	["PlusPaoxiao_extratarget"] = "额外目标",

	["PlusJie"] = "嫉恶",
	[":PlusJie"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的黑色【杀】攻击范围+1，你使用的红色【杀】造成的伤害+1。",
	["#PlusJie"] = "%from 的“嫉恶”技能被触发，伤害从 %arg 点上升至 %arg2 点",
	----------------------------------------------------------------------------------------------------
	["ZhaoYun_Plus"] = "5.0赵云",
	["&ZhaoYun_Plus"] = "赵云",
	["#ZhaoYun_Plus"] = "常胜将军",
	["designer:ZhaoYun_Plus"] = "小A&锦衣祭司",
	["cv:ZhaoYun_Plus"] = "官方",
	["illustrator:ZhaoYun_Plus"] = "略  模板设计:赛宁",

	["PlusLongdan"] = "龙胆",
	[":PlusLongdan"] = "你可以将同花色的X张牌按下列规则使用或打出：红桃当【酒】，方块当【杀】，梅花当【闪】，黑桃当【无懈可击】（若你当前的体力值大于2，X为2；若你当前的体力值小于或等于2，X为1）。",
	["PlusChangsheng"] = "常胜",
	[":PlusChangsheng"] = "你的回合外，若你已受伤，每当你发动【龙胆】使用或打出一张牌时，你可以摸一张牌。",
	----------------------------------------------------------------------------------------------------
	["MaChao_Plus"] = "5.0马超",
	["&MaChao_Plus"] = "马超",
	["#MaChao_Plus"] = "一骑当千",
	["designer:MaChao_Plus"] = "玉面",
	["cv:MaChao_Plus"] = "烈の流星",
	["illustrator:MaChao_Plus"] = "略  模板设计:赛宁",

	["PlusTieji"] = "铁骑",
	[":PlusTieji"] = "当你使用【杀】指定一名角色为目标后，你可以与其拼点，若你赢，此【杀】不可被【闪】响应，且在此【杀】结算后你可以弃置其装备区里的一张牌。",
	----------------------------------------------------------------------------------------------------
	["HuangYueYing_Plus"] = "5.0黄月英",
	["&HuangYueYing_Plus"] = "黄月英",
	["#HuangYueYing_Plus"] = "归隐的杰女",
	["designer:HuangYueYing_Plus"] = "锦衣祭司",
	["cv:HuangYueYing_Plus"] = "官方",
	["illustrator:HuangYueYing_Plus"] = "木美人  模板设计:赛宁",

	["PlusJizhi"] = "集智",
	[":PlusJizhi"] = "当你使用一张非延时类锦囊牌时，你可以摸一张牌；当其他角色使用非延时类锦囊牌指定你为目标时，你可以弃置其一张手牌。",
	----------------------------------------------------------------------------------------------------
	["HuangZhong_Plus"] = "5.0黄忠",
	["&HuangZhong_Plus"] = "黄忠",
	["#HuangZhong_Plus"] = "老当益壮",
	["designer:HuangZhong_Plus"] = "吹风奈奈",
	["cv:HuangZhong_Plus"] = "官方",
	["illustrator:HuangZhong_Plus"] = "KayaK  模板设计:赛宁",

	["PlusYongyi"] = "勇毅",
	[":PlusYongyi"] = "当你在出牌阶段内使用【杀】指定一名角色为目标后，以下两种情况，你可以令其不可以使用【闪】对此【杀】进行响应：\
1.目标角色的手牌数大于或等于你的体力值。\
2.目标角色的手牌数小于或等于你的攻击范围。",

	["PlusLiegong"] = "烈弓",
	[":PlusLiegong"] = "你可以对攻击范围之外的角色使用【杀】，你以此法使用【杀】指定目标后，在攻击范围之外的目标可以弃置你的一张手牌。",
	----------------------------------------------------------------------------------------------------
	["WeiYan_Plus"] = "5.0魏延",
	["&WeiYan_Plus"] = "魏延",
	["#WeiYan_Plus"] = "嗜血的独狼",
	["designer:WeiYan_Plus"] = "锦衣祭司",
	["cv:WeiYan_Plus"] = "官方",
	["illustrator:WeiYan_Plus"] = "略  模板设计:赛宁",

	["PlusQimou"] = "奇谋",
	[":PlusQimou"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令一名角色选择是否将所有手牌交给你（该角色可以拒绝）。然后你获得以下技能直到回合结束：你每造成一次伤害后，你可以额外使用一张【杀】；你计算与其他角色的距离视为1。",
	["PlusQimou_Card"] = "奇谋",
	["plusqimou_"] = "奇谋",
	["PlusQimou_Give"] = "将所有手牌交给 %src",
	["PlusQimou_Refuse"] = "拒绝",
	["@stratagem"] = "奇谋",
	["$PlusQimou_Animation"] = "技能 奇谋 的技能台词（求建议）",
	----------------------------------------------------------------------------------------------------
	["MengHuo_Plus"] = "5.0孟获",
	["&MengHuo_Plus"] = "孟获",
	["#MengHuo_Plus"] = "南蛮王",
	["designer:MengHuo_Plus"] = "玉面",
	["cv:MengHuo_Plus"] = "墨染の飞猫",
	["illustrator:MengHuo_Plus"] = "略  模板设计:赛宁",

	["PlusZaiqi"] = "再起",
	["PlusZaiqi_ss"] = "再起",
	[":PlusZaiqi"] = "摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。然后你可以弃置所有手牌并跳过你的出牌阶段，视为你使用了一张【南蛮入侵】。",
	----------------------------------------------------------------------------------------------------
	["MaSu_Plus"] = "5.0马谡",
	["&MaSu_Plus"] = "马谡",
	["#MaSu_Plus"] = "怀才自负",
	["designer:MaSu_Plus"] = "小A",
	["cv:MaSu_Plus"] = "暂无",
	["illustrator:MaSu_Plus"] = "张帅  模板设计:赛宁",

	["PlusTanbing"] = "谈兵",
	[":PlusTanbing"] = "回合开始阶段开始时，你可以进行一次判定，若结果为红色，则摸牌阶段摸牌时，你可以额外摸一张牌。",
	----------------------------------------------------------------------------------------------------
	["ChenDao_Plus"] = "5.0陈到",
	["&ChenDao_Plus"] = "陈到",
	["#ChenDao_Plus"] = "征西将军",
	["designer:ChenDao_Plus"] = "锦衣祭司",
	["cv:ChenDao_Plus"] = "暂无",
	["illustrator:ChenDao_Plus"] = "略  模板设计:赛宁",

	["PlusZhongyong"] = "忠勇",
	[":PlusZhongyong"] = "出牌阶段开始时，你可以与一名其他角色拼点，若你赢，你可以弃置一张红色手牌视为你对其使用一张【杀】（不计入出牌阶段内的使用次数限制），此【杀】造成伤害后，你可以令一名距离2以内的其他角色将手牌补至X张（X为该角色的体力上限且最多为5）。若你没赢，你结束出牌阶段。",
	["PlusZhongyong_Card"] = "忠勇",
	["pluszhongyong_"] = "忠勇",
	["@PlusZhongyong_Pindian"] = "你可以发动【忠勇】与一名其他角色拼点",
	["~PlusZhongyong"] = "选择一张手牌→选择一名其他角色→点击确定",
	["@PlusZhongyong_Slash"] = "你可以弃置一张红色手牌，视为对其使用【杀】",
	["PlusZhongyong-invoke"] = "你可以发动“忠勇”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	----------------------------------------------------------------------------------------------------
	["JiangWan_Plus"] = "5.0蒋琬",
	["&JiangWan_Plus"] = "蒋琬",
	["#JiangWan_Plus"] = "后蜀丞相",
	["designer:JiangWan_Plus"] = "锦衣祭司",
	["cv:JiangWan_Plus"] = "暂无",
	["illustrator:JiangWan_Plus"] = "略  模板设计:赛宁",

	["pluschenggui"] = "筹援",
	["PlusChouyuan"] = "筹援",
	[":PlusChouyuan"] = "每当一名角色成为【杀】或非延时类锦囊牌的目标后，若其没有手牌，你可以令其摸一张牌并展示之，若此牌不为红桃，则此【杀】或非延时类锦囊牌该角色无效。",
	["PlusChenggui"] = "承规",
	[":PlusChenggui"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌置于牌堆顶，然后令一名其他角色获得牌堆底的一张牌并展示之，若此牌为装备牌，则该角色可以将此牌置于装备区里。",
	["PlusChenggui_Card"] = "承规",
	["pluschenggui_"] = "承规",

	-----------------------------------------------吴---------------------------------------------------

	["SunQuan_Plus"] = "5.0孙权",
	["&SunQuan_Plus"] = "孙权",
	["#SunQuan_Plus"] = "年轻的贤君",
	["designer:SunQuan_Plus"] = "锦衣祭司",
	["cv:SunQuan_Plus"] = "官方，宇文天启",
	["illustrator:SunQuan_Plus"] = "KayaK  模板设计:赛宁",

	["PlusZhiheng"] = "制衡",
	[":PlusZhiheng"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置任意数量的牌，然后摸等量的牌。若你以此法弃置的牌不少于三张，你可以令场上手牌数最少的一名其他角色获得场上手牌数最多的另一名其他角色的一张牌。",
	["PlusZhiheng_Card"] = "制衡",
	["pluszhiheng_"] = "制衡",
	["PlusZhiheng_ok"] = "令手牌最少的其他角色获得手牌最多的其他角色的一张牌",
	["PlusZhiheng_cancel"] = "不发动",
	["#PlusZhiheng_from"] = "制衡（手牌最少角色）",
	["#PlusZhiheng_to"] = "制衡（手牌最多角色）",
	----------------------------------------------------------------------------------------------------
	["ZhouYu_Plus"] = "5.0周瑜",
	["&ZhouYu_Plus"] = "周瑜",
	["#ZhouYu_Plus"] = "大都督",
	["designer:ZhouYu_Plus"] = "锦衣祭司&array88",
	["cv:ZhouYu_Plus"] = "官方",
	["illustrator:ZhouYu_Plus"] = "略  模板设计:赛宁",

	["PlusFanjian"] = "反间",
	[":PlusFanjian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并选择两名手牌数不相等的角色，视为其中手牌多的角色对手牌少的角色使用一张【杀】。此【杀】若被【闪】抵消，在此【杀】结算后，使用此【杀】的角色须失去1点体力。",
	["PlusFanjian_Card"] = "反间",
	["plusfanjian_"] = "反间",
	----------------------------------------------------------------------------------------------------
	["LvMeng_Plus"] = "5.0吕蒙",
	["&LvMeng_Plus"] = "吕蒙",
	["#LvMeng_Plus"] = "取鳞探虎",
	["designer:LvMeng_Plus"] = "小A",
	["cv:LvMeng_Plus"] = "官方，腾讯英雄杀勾践",
	["illustrator:LvMeng_Plus"] = "略  模板设计:赛宁",

	["PlusKeji"] = "克己",
	[":PlusKeji"] = "弃牌阶段弃牌时，若你于出牌阶段未使用或打出过【杀】，你可以将你弃置的牌置于你的武将牌上，称为“懈”；当你成为【杀】或【决斗】的目标后，你可以将一张“懈”置入弃牌堆，令此牌对你无效。",
	["slack"] = "懈",
	["PlusKeji_Jink"] = "克己",
	["#PlusKeji_Jink"] = "克己",

	["PlusDujiang"] = "渡江",
	[":PlusDujiang"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段开始时，若“懈”的数量达到4或更多，你须减1点体力上限，摸两张牌，并获得技能“夺城”（出牌阶段，你可以将一张“懈”置入弃牌堆并指定一名其他角色，然后弃置X张手牌并指定该角色装备区里的X张牌，你获得其中一张牌，再将其余的牌依次弃置。每阶段限一次）。",
	["#PlusDujiang"] = "%from 的懈的数量达到 %arg 个，触发“%arg2”",
	["$PlusDujiang_Animation"] = "技能 渡江 的觉醒台词（求建议）",

	["PlusDuocheng"] = "夺城",
	[":PlusDuocheng"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张“懈”置入弃牌堆并指定一名其他角色，然后弃置X张手牌并指定该角色装备区里的X张牌，你获得其中一张牌，再将其余的牌依次弃置。",
	["PlusDuocheng_Card"] = "夺城",
	["plusduocheng_"] = "夺城",
	["#PlusDuocheng"] = "请弃置不大于目标角色装备数的手牌",
	----------------------------------------------------------------------------------------------------
	["LuXun_Plus"] = "6.0陆逊",
	["&LuXun_Plus"] = "陆逊",
	["#LuXun_Plus"] = "儒生雄才",
	["designer:LuXun_Plus"] = "锦衣祭司",
	["cv:LuXun_Plus"] = "官方",
	["illustrator:LuXun_Plus"] = "略  模板设计:赛宁",

	["PlusCuorui"] = "挫锐",
	[":PlusCuorui"] = "当一名角色使用【顺手牵羊】或【乐不思蜀】指定你攻击范围内的一名角色为目标时，你可以弃置一张手牌，使该角色不再成为此牌的目标。",
	["PlusCuorui_DummyCard"] = "挫锐",
	["@PlusCuorui"] = "你可以弃置一张手牌，取消对 %src 使用的锦囊 %arg",
	["~PlusCuorui"] = "选择一张手牌→点击确定",
	["#PlusCuorui"] = "%from 发动了“%arg”，%to 不再成为【%arg2】的目标",
	["pluscuorui_dummy"] = "挫锐",

	["PlusDuoshi"] = "度势",
	[":PlusDuoshi"] = "每当一名角色失去最后的手牌时，你可以摸一张牌，然后若你的手牌数大于现存势力数，你弃置一张牌。",
	----------------------------------------------------------------------------------------------------
	["GanNing_Plus"] = "5.0甘宁",
	["&GanNing_Plus"] = "甘宁",
	["#GanNing_Plus"] = "佩铃的游侠",
	["designer:GanNing_Plus"] = "曹小瞒back",
	["cv:GanNing_Plus"] = "官方",
	["illustrator:GanNing_Plus"] = "略  模板设计:赛宁",

	["PlusQixi"] = "奇袭",
	[":PlusQixi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张黑色牌当【过河拆桥】使用。若此牌为梅花，你可以额外指定一个目标或额外弃置目标角色区域内的一张牌；若此牌为黑桃且所弃置的牌为装备牌，你可以在此牌置入弃牌堆时，用一张手牌替换之。",
	["@PlusQixi_prompt"] = "你可以用一张手牌替换被弃置的装备牌",
	----------------------------------------------------------------------------------------------------
	["HuangGai_Plus"] = "5.0黄盖",
	["&HuangGai_Plus"] = "黄盖",
	["#HuangGai_Plus"] = "轻身为国",
	["designer:HuangGai_Plus"] = "锦衣祭司",
	["cv:HuangGai_Plus"] = "官方",
	["illustrator:HuangGai_Plus"] = "略  模板设计:赛宁",

	["PlusKurou"] = "苦肉",
	[":PlusKurou"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以失去1点体力，然后选择一项：1.令一名手牌数不大于你的手牌数的角色摸两张牌。2.令一名手牌数不小于你的手牌数的角色弃两张牌。",
	["PlusKurou_Card"] = "苦肉",
	["pluskurou_"] = "苦肉",
	["PlusKurou_Draw"] = "摸牌",
	["PlusKurou_Discard"] = "弃牌",

	["PlusZhaxiang"] = "诈降",
	[":PlusZhaxiang"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，若你当前的体力值不大于1，你可以横置你的武将牌，然后你受到1点火属性伤害。",
	["PlusZhaxiang_Card"] = "诈降",
	["pluszhaxiang_"] = "诈降",
	["@surrender"] = "诈降",
	["$PlusZhaxiang_Animation"] = "技能 诈降 的技能台词（求建议）",
	----------------------------------------------------------------------------------------------------
	["DaQiao_Plus"] = "5.0大乔",
	["&DaQiao_Plus"] = "大乔",
	["#DaQiao_Plus"] = "矜持之花",
	["designer:DaQiao_Plus"] = "锦衣祭司",
	["cv:DaQiao_Plus"] = "官方",
	["illustrator:DaQiao_Plus"] = "略  模板设计:赛宁",

	["PlusLiuli"] = "流离",
	[":PlusLiuli"] = "当你成为【杀】或【决斗】的目标时，你可以弃置一张牌，并将此【杀】或【决斗】转移给一名距离2以内的男性角色，该男性角色不得是该牌的使用者。",
	["@PlusLiuli"] = "你可以弃置一张牌发动【流离】，将此牌转移给距离2以内的除 %src 以外的一名男性角色",
	["~PlusLiuli"] = "选择一张牌→选择一名角色→点击确定",
	["PlusLiuli_Card"] = "流离",
	----------------------------------------------------------------------------------------------------
	["SunShangXiang_Plus"] = "7.0孙尚香",
	["&SunShangXiang_Plus"] = "孙尚香",
	["#SunShangXiang_Plus"] = "弓腰姬",
	["designer:SunShangXiang_Plus"] = "锦衣祭司",
	["cv:SunShangXiang_Plus"] = "官方，背碗卤粉",
	["illustrator:SunShangXiang_Plus"] = "略  模板设计:赛宁",

	["PlusLiangyuan"] = "良缘",
	[":PlusLiangyuan"] = "<font color=\"red\"><b>限定技，</b></font>回合开始阶段开始时，你可以指定一名已受伤或手牌数最少的男性角色，该男性角色获得1枚“良缘”标记。然后你须减1点体力上限，摸两张牌，然后将你的势力改变为该男性角色的势力，并获得技能“结姻”（<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置两张手牌，然后你与拥有“良缘”标记的男性角色各回复1点体力。）和“姻礼”（当你/拥有“良缘”标记的男性角色的装备牌于其回合外置入弃牌堆时，拥有“良缘”标记的男性角色/你可以获得其中任意数量的牌）。",
	["PlusLiangyuan_Card"] = "良缘",
	["plusliangyuan_"] = "良缘",
	["@love"] = "寻缘",
	["@match"] = "良缘",
	["@PlusLiangyuan"] = "你可以发动【良缘】",
	["~PlusLiangyuan"] = "选择一名角色→点击确定",
	["$PlusLiangyuan_Animation"] = "技能 良缘 的技能台词（求建议）",
	["#PlusLiangyuan_Kingdom"] = "%from 将势力改为 %arg",

	["PlusJieyin"] = "结姻",
	[":PlusJieyin"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置两张手牌，然后你与拥有“良缘”标记的男性角色各回复1点体力。",
	["PlusJieyin_Card"] = "结姻",
	["plusjieyin_"] = "结姻",

	["PlusYinli"] = "姻礼",
	[":PlusYinli"] = "当你/拥有“良缘”标记的男性角色的装备牌于其回合外置入弃牌堆时，拥有“良缘”标记的男性角色/你可以获得其中任意数量的牌。\
★操作提示：在弹出的窗口中双击选择不希望获得的牌，然后点击确定，获得剩余的牌。",

	----------------------------------------------------------------------------------------------------
	["XiaoQiao_Plus"] = "6.0小乔",
	["&XiaoQiao_Plus"] = "小乔",
	["#XiaoQiao_Plus"] = "矫情之花",
	["designer:XiaoQiao_Plus"] = "cryaciccl",
	["cv:XiaoQiao_Plus"] = "官方",
	["illustrator:XiaoQiao_Plus"] = "略  模板设计:赛宁",

	["PlusTianxiang"] = "天香",
	[":PlusTianxiang"] = "回合结束时，你可以弃置一张红桃手牌，令一名角色执行一个额外的摸牌阶段或弃牌阶段。若该角色在该摸牌阶段获得多于两张的牌，你可以获得其一张牌；若该角色在该弃牌阶段弃置多于两张的牌，你须弃置一张牌。",
	["@PlusTianxiang"] = "你可以弃置一张红桃手牌发动【天香】",
	["~PlusTianxiang"] = "选择一张红桃手牌→选择一名角色→点击确定",
	["PlusTianxiang_Draw"] = "一个额外的摸牌阶段",
	["PlusTianxiang_Discard"] = "一个额外的弃牌阶段",
	["PlusTianxiang_Card"] = "天香",
	["plustianxiang_"] = "天香",

	["PlusHongyan"] = "红颜",
	[":PlusHongyan"] = "每当一张红桃牌于一名男性角色的弃牌阶段内因该角色的弃、置而置入弃牌堆时，其可以将此牌交给你。\
★操作提示：在弹出的窗口中双击选择不希望交给小乔的牌，然后点击确定，将剩余的牌交给小乔。",

	----------------------------------------------------------------------------------------------------
	["ZhouTai_Plus"] = "5.0周泰",
	["&ZhouTai_Plus"] = "周泰",
	["#ZhouTai_Plus"] = "历战之躯",
	["designer:ZhouTai_Plus"] = "玉面",
	["cv:ZhouTai_Plus"] = "官方",
	["illustrator:ZhouTai_Plus"] = "KayaK  模板设计:赛宁",

	["PlusBuqu"] = "不屈",
	[":PlusBuqu"] = "每当你扣减1点体力时，若你当前体力为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，称为“伤”，若“伤”的点数都不同，你不会死亡；若出现相同点数的“伤”，你进入濒死状态。每有三张“伤”，你的手牌上限就+1。",
	["Plushurt"] = "伤",
	["#PlusBuqu_Duplicate"] = "%from 时运不济啊，“伤”中有 %arg 重复点数",
	["#PlusBuqu_DuplicateGroup"] = "第 %arg 组重复点数为 %arg2",
	["$PlusBuqu_DuplicateItem"] = "“伤”重复牌: %card",
	["$PlusBuqu_Remove"] = "%from 移除了“伤”：%card",

	["PlusHuzhu"] = "护主",
	[":PlusHuzhu"] = "当距离1以内的一名其他角色进入濒死状态时，你可以对自己造成1点伤害，视为你对该角色使用了一张【桃】。",
	----------------------------------------------------------------------------------------------------
	["SunJian_Plus"] = "5.0孙坚",
	["&SunJian_Plus"] = "孙坚",
	["#SunJian_Plus"] = "武烈帝",
	["designer:SunJian_Plus"] = "锦衣祭司",
	["cv:SunJian_Plus"] = "暂无",
	["illustrator:SunJian_Plus"] = "LiuHeng  模板设计:赛宁",

	["PlusBiyou"] = "庇佑",
	[":PlusBiyou"] = "<font color=\"orange\"><b>主公技，</b></font>当一名吴势力角色进入濒死状态时，其他体力值大于1的吴势力角色可以失去1点体力令其回复1点体力。",
	----------------------------------------------------------------------------------------------------
	["GuYong_Plus"] = "5.0顾雍",
	["&GuYong_Plus"] = "顾雍",
	["#GuYong_Plus"] = "一代名相",
	["designer:GuYong_Plus"] = "锦衣祭司",
	["cv:GuYong_Plus"] = "暂无",
	["illustrator:GuYong_Plus"] = "略  模板设计:赛宁",

	["PlusLiangjie"] = "亮节",
	[":PlusLiangjie"] = "出牌阶段开始时，你可以展示所有手牌直到出牌阶段结束，然后你可以跳过你的弃牌阶段，并在回合结束阶段开始时摸一张牌。",
	["PlusQiaojian"] = "巧谏",
	[":PlusQiaojian"] = "一名角色的回合开始阶段开始时，若其判定区里有牌，你可以令其展示一张手牌，然后你可以弃置一张与此牌花色相同的手牌令该角色跳过判定阶段。",
	["@PlusQiaojian_Prompt"] = "%src 展示的牌的花色为 %arg，请弃置相同花色的牌",
	----------------------------------------------------------------------------------------------------
	["SunLuBan_Plus"] = "5.0孙鲁班",
	["&SunLuBan_Plus"] = "孙鲁班",
	["#SunLuBan_Plus"] = "吴全公主",
	["designer:SunLuBan_Plus"] = "小A",
	["cv:SunLuBan_Plus"] = "暂无",
	["illustrator:SunLuBan_Plus"] = "略  模板设计:赛宁",

	["PlusZenhui"] = "谮毁",
	[":PlusZenhui"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择两名体力值不相等的其他角色并将一张黑桃手牌交给其中体力值小的角色，然后其中体力值大的角色须选择一项：对体力值小的角色造成1点伤害，或弃置其两张手牌。",
	["PlusZenhui_Card"] = "谮毁",
	["pluszenhui_"] = "谮毁",
	["PlusZenhui_Damage"] = "造成1点伤害",
	["PlusZenhui_Discard"] = "弃置两张手牌",

	["PlusJiahuo"] = "嫁祸",
	[":PlusJiahuo"] = "当你成为【杀】的目标时，你可以将此【杀】转移给你攻击范围内的一名其他角色，该角色不得是此【杀】的使用者。此【杀】造成伤害后，你须将武将牌翻面。",
	["PlusJiahuo_Card"] = "嫁祸",
	["plusjiahuo_"] = "嫁祸",
	["@PlusJiahuo"] = "你可以发动【嫁祸】，将此牌转移给你攻击范围内的除 %src 以外的一名其他角色",
	["~PlusJiahuo"] = "选择一名其他角色→点击确定",

	-----------------------------------------------群---------------------------------------------------

	["LvBu_Plus"] = "5.0吕布",
	["&LvBu_Plus"] = "吕布",
	["#LvBu_Plus"] = "飞将",
	["designer:LvBu_Plus"] = "锦衣祭司",
	["cv:LvBu_Plus"] = "暂无",
	["illustrator:LvBu_Plus"] = "略  模板设计:赛宁",

	["PlusSheji"] = "射戟",
	[":PlusSheji"] = "你可以将所有手牌当【杀】使用或打出，且此【杀】具有以下效果：无距离限制；不计入出牌阶段内的使用次数限制；可以额外指定一个目标。",
	----------------------------------------------------------------------------------------------------
	["DiaoChan_Plus"] = "5.0貂蝉",
	["&DiaoChan_Plus"] = "貂蝉",
	["#DiaoChan_Plus"] = "绝世的舞姬",
	["designer:DiaoChan_Plus"] = "官方",
	["cv:DiaoChan_Plus"] = "官方",
	["illustrator:DiaoChan_Plus"] = "LiuHeng  模板设计:赛宁",
	----------------------------------------------------------------------------------------------------
	["HuaTuo_Plus"] = "5.0华佗",
	["&HuaTuo_Plus"] = "华佗",
	["#HuaTuo_Plus"] = "乱世神医",
	["designer:HuaTuo_Plus"] = "路西法",
	["cv:HuaTuo_Plus"] = "官方",
	["illustrator:HuaTuo_Plus"] = "略  模板设计:赛宁",

	["PlusMafei"] = "麻沸",
	[":PlusMafei"] = "当一名角色进入濒死状态时，你可以弃置一张红色牌，令其回复1点体力，然后【杀】或非延时类锦囊牌对该角色无效，直到该回合结束。\
◆你在一名角色进入濒死状态时可以多次发动【麻沸】，直到该角色的体力回复至1点为止。",
	["@PlusMafei_Prompt"] = "你可以弃置一张红色牌发动【麻沸】",
	["#PlusMafei_Damaged"] = "%from 受到【%arg】的影响，本回合内【杀】和非延时锦囊都将对其无效",
	["#PlusMafei_Avoid"] = "%from 受到【%arg】的影响，【杀】和非延时锦囊对其无效",
	["~PlusMafei"] = "选择一张红色牌→点击确定",

	["PlusXuanhu"] = "悬壶",
	[":PlusXuanhu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌，令一名已受伤的角色回复1点体力。",
	["PlusXuanhu_Card"] = "悬壶",
	["plusxuanhu_"] = "悬壶",

	["PlusQingnang"] = "青囊",
	[":PlusQingnang"] = "你的回合外，当你死亡时，你可以令一名你死亡前距离为1的角色（杀死你的角色除外）选择一项：加1点体力上限，或失去1点体力并获得技能“悬壶”。",
	["PlusQingnang-invoke"] = "你可以发动“青囊”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["PlusQingnang_choice1"] = "加1点体力上限",
	["PlusQingnang_choice2"] = "失去体力获得“悬壶”",
	["#PlusQingnang_MaxHp"] = "%from 加 %arg 点体力上限",
	----------------------------------------------------------------------------------------------------
	["ZhangJiao_Plus"] = "5.0张角",
	["&ZhangJiao_Plus"] = "张角",
	["#ZhangJiao_Plus"] = "天公将军",
	["designer:ZhangJiao_Plus"] = "一品海之蓝",
	["cv:ZhangJiao_Plus"] = "官方",
	["illustrator:ZhangJiao_Plus"] = "略  模板设计:赛宁",

	["PlusGuidao"] = "鬼道",
	[":PlusGuidao"] = "在一名角色的判定牌或拼点牌（限其中一名角色）生效前，你可以用一张黑色牌替换之。",
	["~PlusGuidao"] = "选择一张黑色牌→点击确定",

	["PlusLeiji"] = "雷击",
	[":PlusLeiji"] = "你的回合外，当你因使用、打出或弃置而失去一张【闪】时，可令一名角色判定，若结果为黑桃，你对该角色造成2点雷电伤害。",
	["PlusLeiji_Card"] = "雷击",
	["plusleiji_"] = "雷击",
	["@PlusLeiji"] = "令一名角色判定，若为黑桃，你对该角色造成2点雷电伤害",
	["~PlusLeiji"] = "选择一名角色→点击确定",

	["PlusHuangtian"] = "黄天",
	[":PlusHuangtian"] = "<font color=\"orange\"><b>主公技，</b></font>其他群雄角色可以在他们各自的出牌阶段内交给你一张【闪】、【闪电】或雷【杀】。每阶段限一次。",
	["PlusHuangtian_Card"] = "黄天送牌",
	["plushuangtian_"] = "黄天送牌",
	["PlusHuangtianQun"] = "黄天送牌",
	[":PlusHuangtianQun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以交给张角一张【闪】、【闪电】或雷【杀】。",
	----------------------------------------------------------------------------------------------------
	["YuJi_Plus"] = "5.0于吉",
	["&YuJi_Plus"] = "于吉",
	["#YuJi_Plus"] = "太平道人",
	["designer:YuJi_Plus"] = "dismalance",
	["cv:YuJi_Plus"] = "官方",
	["illustrator:YuJi_Plus"] = "略  模板设计:赛宁",

	["PlusHunzhou"] = "魂咒",
	[":PlusHunzhou"] = "<font color=\"blue\"><b>锁定技，</b></font>当你死亡时，杀死你的角色减1点体力上限。",
	["#PlusHunzhou"] = "%from 触发“%arg”，杀死 %from 的角色 %to 减 1 点体力上限",
	----------------------------------------------------------------------------------------------------
	["GongSunZan_Plus"] = "5.0公孙瓒",
	["&GongSunZan_Plus"] = "公孙瓒",
	["#GongSunZan_Plus"] = "白马将军",
	["designer:GongSunZan_Plus"] = "小A",
	["cv:GongSunZan_Plus"] = "官方",
	["illustrator:GongSunZan_Plus"] = "略  模板设计:赛宁",

	["PlusYicong"] = "义从",
	[":PlusYicong"] = "<font color=\"blue\"><b>锁定技，</b></font>若你当前的体力值大于2，你计算的与其他角色的距离-X；若你当前的体力值小于或等于2，其他角色计算的与你的距离+X。（X为场上装备区内的坐骑牌的数量+1，且最多为4）",
	----------------------------------------------------------------------------------------------------
	["HuaXiong_Plus"] = "5.0华雄",
	["&HuaXiong_Plus"] = "华雄",
	["#HuaXiong_Plus"] = "魔将",
	["designer:HuaXiong_Plus"] = "锦衣祭司",
	["cv:HuaXiong_Plus"] = "玉皇贰弟",
	["illustrator:HuaXiong_Plus"] = "略  模板设计:赛宁",

	["PlusShiyong"] = "恃勇",
	[":PlusShiyong"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你须摸一张牌，然后弃置两张牌。",
	----------------------------------------------------------------------------------------------------
	["LiuXie_Plus"] = "5.0刘协",
	["&LiuXie_Plus"] = "刘协",
	["#LiuXie_Plus"] = "汉献帝",
	["designer:LiuXie_Plus"] = "锦衣祭司",
	["cv:LiuXie_Plus"] = "风叹息",
	["illustrator:LiuXie_Plus"] = "略  模板设计:赛宁",

	["PlusMizhao"] = "密诏",
	[":PlusMizhao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将至少三张牌交给一名其他角色，该角色选择一项：1. 视为对其攻击范围内你选择的另一名角色使用一张【杀】，若该【杀】被【闪】抵消，其须失去1点体力。2. 摸一张牌然后将其武将牌翻面。\
◆你在将牌交给目标角色之后，先选择一名其攻击范围内的角色作为【杀】的目标，然后该角色再进行选择。",
	["PlusMizhao_Card"] = "密诏",
	["plusmizhao_"] = "密诏",
	["PlusMizhao_Use"] = "视为对刘协选择的角色使用一张【杀】",
	["PlusMizhao_Draw"] = "摸一张牌然后将武将牌翻面",

	["PlusZhengtong"] = "正统",
	[":PlusZhengtong"] = "回合开始阶段开始时，你可以弃置一张红色牌并声明一项其他武将的主公技（限定技、觉醒技除外），你视为拥有该技能，直到你的下回合开始。",
	["@PlusZhengtong"] = "你可以弃置一张红色牌发动【正统】",
	["~PlusZhengtong"] = "选择一张红色牌→点击确定",
	["PlusZhengtong_Card"] = "正统",
	["pluszhengtong_"] = "正统",

	["PlusXiejia"] = "挟驾",
	[":PlusXiejia"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段开始时，若此时场上手牌数最多的角色仅有一名且不是你，你须放弃摸牌，改为该角色摸两张牌，再将两张牌交给你。",
	["@PlusXiejia_Exchange"] = "请交给目标角色 %arg 张牌",
	----------------------------------------------------------------------------------------------------
	["ZhangXiu_Plus"] = "5.0张绣",
	["&ZhangXiu_Plus"] = "张绣",
	["#ZhangXiu_Plus"] = "北地枪王",
	["designer:ZhangXiu_Plus"] = "玉面",
	["cv:ZhangXiu_Plus"] = "暂无",
	["illustrator:ZhangXiu_Plus"] = "略  模板设计:赛宁",

	["PlusAnxi"] = "暗袭",
	[":PlusAnxi"] = "其他角色的回合开始阶段开始时，若其手牌数大于你的手牌数，你可以与其拼点。若你赢，你对其造成1点伤害。若你没赢，该角色可以令你对你攻击范围内其指定的的一名角色造成1点伤害。",
	----------------------------------------------------------------------------------------------------
	["WangYun_Plus"] = "5.0王允",
	["&WangYun_Plus"] = "王允",
	["#WangYun_Plus"] = "国之栋梁",
	["designer:WangYun_Plus"] = "锦衣祭司",
	["cv:WangYun_Plus"] = "暂无",
	["illustrator:WangYun_Plus"] = "略  模板设计:赛宁",

	["PlusZhuni"] = "诛逆",
	[":PlusZhuni"] = "你可以将一张黑色牌当【借刀杀人】使用，若目标角色使用【杀】响应你以此法使用的【借刀杀人】，当此【杀】造成伤害后，其可以弃置一张装备牌，令你失去1点体力。",
	["@PlusZhuni"] = "你可以弃置一张装备牌，令 %src 失去1点体力",

	["PlusKuangjun"] = "匡君",
	[":PlusKuangjun"] = "每当你扣减1点体力后，你可以令一名其他角色回复1点体力并摸一张牌。",
	["PlusKuangjun_Card"] = "匡君",
	["pluskuangjun_"] = "匡君",
	["@PlusKuangjun"] = "你可以发动【匡君】",
	["~PlusKuangjun"] = "选择一名其他角色→点击确定",
	----------------------------------------------------------------------------------------------------
	["SiMaHui_Plus"] = "5.0司马徽",
	["&SiMaHui_Plus"] = "司马徽",
	["#SiMaHui_Plus"] = "水镜先生",
	["designer:SiMaHui_Plus"] = "锦衣祭司",
	["cv:SiMaHui_Plus"] = "暂无",
	["illustrator:SiMaHui_Plus"] = "略  模板设计:赛宁",

	["PlusZhiren"] = "知人",
	[":PlusZhiren"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名角色的手牌，然后你可以展示其中一张牌，若此牌为基本牌，该角色回复1点体力，否则其摸两张牌。",
	["PlusZhiren_Card"] = "知人",
	["pluszhiren_"] = "知人",

	["PlusChenghao"] = "称好",
	[":PlusChenghao"] = "你的回合外，当你失去牌时，你可以令当前正进行回合的角色和你各摸一张牌。",


	----------------------------------------------------------------------------------------------------
	--6.0
	["biaofeng_six"] = "标风重铸6.0",

	-----------------------------------------------魏---------------------------------------------------
	["CaoCao_six"] = "6.0曹操",
	["&CaoCao_six"] = "曹操",
	["#CaoCao_six"] = "超世之英杰",
	["designer:CaoCao_six"] = "锦衣祭司",
	["cv:CaoCao_six"] = "官方",
	["illustrator:CaoCao_six"] = "略",

	["SixWulve"] = "武略",
	[":SixWulve"] = "每当你受到一次伤害后，你可以选择一项：1.摸两张牌。2.将对你造成伤害的牌置于你的武将牌上，称为“略”。一名角色的结束阶段开始时，你可以将一张“略”置入弃牌堆，视为该角色使用此牌。\
★已知BUG：该角色视为使用此牌时，如果需要指定目标，可以拒绝。",
	["SixWulveDraw"] = "摸两张牌",
	["SixWulveGet"] = "将造成伤害的牌置于武将牌上",
	["SixWulveCancel"] = "不发动",
	["strategy"] = "略",
	["#SixWulve1"] = "%from 发动了“%arg”，摸两张牌",
	["#SixWulve2"] = "%from 发动了“%arg”，将造成伤害的牌置于武将牌上",
	["SixWulveOthers"] = "武略",
	["@SixWulve"] = "请选择【%arg】的目标",
	["~SixWulveOthers"] = "选择若干名角色→点击确定",


	----------------------------------------------------------------------------------------------------
	["SiMaYi_Six"] = "6.0司马懿",
	["&SiMaYi_Six"] = "司马懿",
	["#SiMaYi_Six"] = "狼顾之鬼",
	["designer:SiMaYi_Six"] = "锦衣祭司",
	["cv:SiMaYi_Six"] = "官方",
	["illustrator:SiMaYi_Six"] = "略",

	["SixLangmou"] = "狼谋",
	[":SixLangmou"] = "每当你受到一次伤害后，你可以观看伤害来源的手牌，并获得其一张牌。",
	["SixGuicai"] = "鬼才",
	[":SixGuicai"] = "在一名角色的判定牌生效前，或一名角色拼点的牌亮出后（每次拼点限其中一名角色），你可以弃置一张手牌并选择一种花色和点数，若如此做，此判定牌或拼点的牌视为此花色和点数。\
★已知BUG：修改判定牌时会出现多余的提示信息。（不影响技能效果）",
	["SixGuicaipindian"] = "鬼才",
	["sixguicai"] = "鬼才",
	["sixguicaicard"] = "鬼才",
	["@SixGuicai"] = "你可以发动“%dest”",
	["~SixGuicai"] = "选择一张手牌→点击确定",
	["~SixGuicai2"] = "选择一张手牌→选择一名角色→点击确定",
	["$SixGuicaiJudgeOne"] = "%from 令 %to 的判定牌视为 %arg %arg2",
	["$SixGuicaiPindianOne"] = "%from 令 %to 拼点的牌视为 %arg %arg2",
	["SixGuicaiFilter"] = "鬼才改判",

	["SixTaohui"] = "韬晦",
	[":SixTaohui"] = "结束阶段开始时，你可以将装备区里任意数量的牌置入手牌。",
	["sixtaohui"] = "韬晦",
	["@SixTaohui"] = "你可以发动“韬晦”",
	["~SixTaohui"] = "选择装备区里任意数量的牌→点击确定",
	----------------------------------------------------------------------------------------------------
	["GuoJia_Six"] = "6.0郭嘉",
	["&GuoJia_Six"] = "郭嘉",
	["#GuoJia_Six"] = "早终的先知",
	["designer:GuoJia_Six"] = "言笑符乔",
	["cv:GuoJia_Six"] = "官方",
	["illustrator:GuoJia_Six"] = "略",

	["SixTiandu"] = "天妒",
	[":SixTiandu"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，你进行一次判定。在判定牌生效后，你获得此牌，然后若判定结果为黑桃2~9，你受到1点伤害。",
	----------------------------------------------------------------------------------------------------
	["XuChu_Six"] = "6.0许褚",
	["&XuChu_Six"] = "许褚",
	["#XuChu_Six"] = "虎痴",
	["designer:XuChu_Six"] = "锦衣祭司",
	["cv:XuChu_Six"] = "官方",
	["illustrator:XuChu_Six"] = "略",

	["SixHuwei"] = "虎卫",
	[":SixHuwei"] = "<font color=\"blue\"><b>锁定技，</b></font>当其他角色使用【杀】选择目标后，若你的装备区里没有防具牌，且其与目标角色的距离不小于其与你的距离，其选择一项：弃置一张装备牌，或令你摸一张牌。",
	["@SixHuwei"] = "你需弃置一张装备牌，否则 %src 摸一张牌",
	----------------------------------------------------------------------------------------------------
	["CaoRen_Six"] = "6.0曹仁",
	["&CaoRen_Six"] = "曹仁",
	["#CaoRen_Six"] = "险不辞难",
	["designer:CaoRen_Six"] = "吹风奈奈",
	["cv:CaoRen_Six"] = "官方",
	["illustrator:CaoRen_Six"] = "略",

	["SixJushou"] = "据守",
	[":SixJushou"] = "结束阶段开始时，若你在弃牌阶段弃置了至少一张手牌，你可以选择至多一名攻击范围内含有你，且武将牌正面朝上的其他角色，令你与其各摸X张牌（X为你在弃牌阶段弃置的手牌数量且至多为4）并将武将牌翻面。",
	["@SixJushou"] = "你可以选择至多一名其他角色",
	----------------------------------------------------------------------------------------------------
	["ChengYu_Six"] = "6.0程昱",
	["&ChengYu_Six"] = "程昱",
	["#ChengYu_Six"] = "世之奇才",
	["designer:ChengYu_Six"] = "锦衣祭司",
	["cv:ChengYu_Six"] = "暂无",
	["illustrator:ChengYu_Six"] = "略",

	["SixMingduan"] = "明断",
	[":SixMingduan"] = "其他角色的出牌阶段开始时，你可以交给其一张黑色手牌并选择其攻击范围内的另一名角色，令其不能对除你选择的角色以外的角色使用【杀】，直到回合结束。",
	["sixmingduan"] = "明断",
	["@SixMingduan"] = "你可以发动“明断”",
	["~SixMingduan"] = "选择一张黑色手牌→点击确定",
	["@SixMingduanChoose"] = "请选择 %src 攻击范围内的另一名角色",
	["#SixMingduan"] = "%from 受到“%arg”的影响，本回合不能对除 %to 以外的角色使用【<font color=\"yellow\"><b>杀</b></font>】",

	----------------------------------------------------------------------------------------------------
	["LiuYe_Six"] = "6.0刘晔",
	["&LiuYe_Six"] = "刘晔",
	["#LiuYe_Six"] = "三朝元老",
	["designer:LiuYe_Six"] = "小A",
	["cv:LiuYe_Six"] = "暂无",
	["illustrator:LiuYe_Six"] = "略",

	["SixQiaoxie"] = "巧械",
	[":SixQiaoxie"] = "一名角色的出牌阶段开始时，其可以令你选择是否弃置一张黑色手牌并令其攻击范围无限直到回合结束。\
◆你可以选择不弃置，但是若如此做，不能令该角色攻击范围无限。",
	["#SixQiaoxieReject"] = "%from 拒绝 %to 发动“%arg”",
	["@SixQiaoxie"] = "你可以弃置一张黑色手牌，令 %src 本回合攻击范围无限",

	["SixZhidi"] = "知敌",
	[":SixZhidi"] = "结束阶段开始时，若你的武将牌上没有牌，你可以将一张手牌背面朝上置于你的武将牌上，称为“知”；当你成为其他角色使用的牌的目标时，你可以展示一张与此牌颜色相同的“知”并将其置于弃牌堆，令此牌对你无效，然后你摸两张牌。",
	["sixzhidi"] = "知敌",
	["@SixZhidi"] = "你可以发动“知敌”",
	["~SixZhidi"] = "选择一张手牌→点击确定",
	["know"] = "知",
	["#SixZhidiNullify"] = "%from 的“%arg”效果被触发，【%arg2】对其无效",
	----------------------------------------------------------------------------------------------------
	["DongZhao_Six"] = "6.0董昭",
	["&DongZhao_Six"] = "董昭",
	["#DongZhao_Six"] = "开国元勋",
	["designer:DongZhao_Six"] = "玉面",
	["cv:DongZhao_Six"] = "暂无",
	["illustrator:DongZhao_Six"] = "略",

	["SixChouzuan"] = "筹纂",
	[":SixChouzuan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一名其他角色，弃置等同于其攻击范围的手牌并将你的武将牌翻面，若如此做，该角色攻击范围内的所有其他角色须选择一项：令该角色摸一张牌，或受到该角色对其造成的1点伤害。",
	["sixchouzuan"] = "筹纂",
	["SixChouzuanDraw"] = "令该角色摸一张牌",
	["SixChouzuanDamage"] = "受到1点伤害",

	["SixYinmou"] = "阴谋",
	--[":SixYinmou"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到一次伤害后，你摸一张牌，然后若你的武将牌背面朝上，你将你的武将牌翻面。",
	[":SixYinmou"] = "每当你的手牌数大于你当前的体力值时，若你的武将牌背面朝上，你可以将你的武将牌翻面，然后摸一张牌。",
	----------------------------------------------------------------------------------------------------
	["CaoAng_Six"] = "6.0曹昂",
	["&CaoAng_Six"] = "曹昂",
	["#CaoAng_Six"] = "曹氏之哀",
	["designer:CaoAng_Six"] = "锦衣祭司",
	["cv:CaoAng_Six"] = "暂无",
	["illustrator:CaoAng_Six"] = "略",

	["SixWeiyuan"] = "危援",
	[":SixWeiyuan"] = "每当你受到一次伤害后，你可以将你的武将牌翻面并选择一名其他角色，交换你与其装备区里的牌。",
	["@SixWeiyuan"] = "请选择“危援”的目标角色",
	----------------------------------------------------------------------------------------------------
	["PangDe_Six"] = "6.0庞德",
	["&PangDe_Six"] = "庞德",
	["#PangDe_Six"] = "周苛之节",
	["designer:PangDe_Six"] = "array88",
	["cv:PangDe_Six"] = "官方",
	["illustrator:PangDe_Six"] = "略",

	["SixTaichen"] = "抬榇",
	[":SixTaichen"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张【杀】并选择你攻击范围内的一名其他角色，令其选择一项：对你使用一张红色【杀】，或受到你造成的1点伤害。",
	["sixtaichen"] = "抬榇",
	["@SixTaichen"] = "%src 对你发动“抬榇”，请对其使用一张红色【杀】",
	-----------------------------------------------蜀---------------------------------------------------

	["LiuBei_Six"] = "6.0刘备",
	["&LiuBei_Six"] = "刘备",
	["#LiuBei_Six"] = "乱世的枭雄",
	["designer:LiuBei_Six"] = "玉面",
	["cv:LiuBei_Six"] = "官方",
	["illustrator:LiuBei_Six"] = "略",

	["SixRende"] = "仁德",
	[":SixRende"] = "出牌阶段，你可以将任意数量的手牌交给其他角色，若此阶段你以此法给出了两张或更多的手牌，弃牌阶段开始时，你可以回复1点体力，或摸两张牌。",
	["sixrende"] = "仁德",
	["SixRendeRecover"] = "回复1点体力",
	["SixRendeDraw"] = "摸两张牌",
	["SixRendeCancel"] = "取消",
	["#SixRende1"] = "%from 发动了“%arg”，回复1点体力",
	["#SixRende2"] = "%from 发动了“%arg”，摸两张牌",
	----------------------------------------------------------------------------------------------------
	["ZhangFei_Six"] = "6.0张飞",
	["&ZhangFei_Six"] = "张飞",
	["#ZhangFei_Six"] = "万夫莫当",
	["designer:ZhangFei_Six"] = "蝶翼斩",
	["cv:ZhangFei_Six"] = "官方",
	["illustrator:ZhangFei_Six"] = "略",

	["SixPaoxiao"] = "咆哮",
	[":SixPaoxiao"] = "出牌阶段，当你需要对一名角色使用【杀】时，你可以令其摸一张牌，然后你视为对其使用一张【杀】，此【杀】若造成伤害，其不计入出牌阶段限制的使用次数。若目标角色因你使用此【杀】造成的伤害而进入濒死状态，你不能发动“咆哮”，直到回合结束。\
◆若你在出牌阶段内不能使用【杀】（超过了使用次数限制），你不能发动【咆哮】。 （注：即装备诸葛连弩时使用一次杀，或咆哮未造成伤害后，就不能继续发动）",
	["sixpaoxiao"] = "咆哮",
	----------------------------------------------------------------------------------------------------
	["ZhaoYun_Six"] = "6.0赵云",
	["&ZhaoYun_Six"] = "赵云",
	["#ZhaoYun_Six"] = "七进七出",
	["designer:ZhaoYun_Six"] = "锦衣祭司",
	["cv:ZhaoYun_Six"] = "官方",
	["illustrator:ZhaoYun_Six"] = "略",

	["SixLongdan"] = "龙胆",
	[":SixLongdan"] = "每当你攻击范围内的一名角色成为【杀】的目标后，你可以弃置一张基本牌并将你的武将牌翻面，令此【杀】对其无效；当你的武将牌翻转至正面朝上时，你摸一张牌，然后可以视为对一名其他角色使用一张【杀】（无距离限制）。",
	["sixlongdan"] = "龙胆",
	["sixlongdanslash"] = "龙胆",
	["@SixLongdan"] = "你可以发动“龙胆”，令此【杀】对 %src 无效",
	["@SixLongdanSlash"] = "你可以视为对一名其他角色使用一张【杀】",
	["~SixLongdan1"] = "选择一张基本牌→点击确定",
	["~SixLongdan2"] = "选择【杀】的目标角色→点击确定",
	["#SixLongdanNullify"] = "%from 的“%arg”效果被触发，【%arg2】对其无效",
	----------------------------------------------------------------------------------------------------
	["PangTong_Six"] = "6.0庞统",
	["&PangTong_Six"] = "庞统",
	["#PangTong_Six"] = "凤雏",
	["designer:PangTong_Six"] = "锦衣祭司",
	["cv:PangTong_Six"] = "暂无",
	["illustrator:PangTong_Six"] = "略",

	["SixQucai"] = "屈才",
	[":SixQucai"] = "结束阶段开始时，你可以摸2X张牌（X为你在弃牌阶段弃置的锦囊牌数量）。",
	["SixSance"] = "三策",
	[":SixSance"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示三张不同花色的手牌，令一名其他角色选择其中一张并获得之，然后将其余两张置入弃牌堆。若该角色选择的牌花色为：黑桃，其摸两张牌；红桃，其回复1点体力；梅花，你摸两张牌；方块，你回复1点体力。",
	["sixsance"] = "三策",
	----------------------------------------------------------------------------------------------------
	["ChenDao_Six"] = "6.0陈到",
	["&ChenDao_Six"] = "陈到",
	["#ChenDao_Six"] = "征西将军",
	["designer:ChenDao_Six"] = "锦衣祭司",
	["cv:ChenDao_Six"] = "暂无",
	["illustrator:ChenDao_Six"] = "略",

	["SixZhongyong"] = "忠勇",
	[":SixZhongyong"] = "每当你攻击范围内的一名其他角色成为【杀】或【决斗】的目标时，若其手牌数小于你的手牌数，你可以摸一张牌，将此【杀】或【决斗】转移给你。",
	----------------------------------------------------------------------------------------------------
	["JiangWan_Six"] = "6.0蒋琬",
	["&JiangWan_Six"] = "蒋琬",
	["#JiangWan_Six"] = "后蜀丞相",
	["designer:JiangWan_Six"] = "锦衣祭司",
	["cv:JiangWan_Six"] = "暂无",
	["illustrator:JiangWan_Six"] = "略",

	["SixChouyuan"] = "筹援",
	[":SixChouyuan"] = "结束阶段开始时，你可以选择一名已受伤的角色，令其摸两张牌，再弃置等同于其体力值的手牌，然后回复1点体力。",
	["sixchouyuan"] = "筹援",
	["@SixChouyuan"] = "你可以发动“筹援”",
	["~SixChouyuan"] = "选择一名已受伤的角色→点击确定",

	----------------------------------------------------------------------------------------------------
	["LiYan_Six"] = "6.0李严",
	["&LiYan_Six"] = "李严",
	["#LiYan_Six"] = "托孤重臣",
	["designer:LiYan_Six"] = "小A",
	["cv:LiYan_Six"] = "暂无",
	["illustrator:LiYan_Six"] = "略",

	["SixWujun"] = "误军",
	[":SixWujun"] = "其他角色的摸牌阶段摸牌时，若你的装备区里没有坐骑牌，你可以令其少摸一张牌，然后该角色可以弃置一张手牌，视为对你使用一张【杀】（无距离限制）。",
	["@SixWujun"] = "你可以弃置一张手牌，视为对 %src 使用一张【杀】",
	----------------------------------------------------------------------------------------------------
	["WangPing_Six"] = "6.0王平",
	["&WangPing_Six"] = "王平",
	["#WangPing_Six"] = "所向无前",
	["designer:WangPing_Six"] = "锦衣祭司",
	["cv:WangPing_Six"] = "暂无",
	["illustrator:WangPing_Six"] = "略",

	["SixWuzhi"] = "武治",
	[":SixWuzhi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张【杀】交给一名角色，然后你可以获得其区域内的一张牌，或弃置其两张手牌。",
	["sixwuzhi"] = "武治",
	["SixWuzhiGet"] = "获得其区域内的一张牌",
	["SixWuzhiDiscard"] = "弃置其两张手牌",
	["SixWuzhiCancel"] = "取消",
	----------------------------------------------------------------------------------------------------
	["MiFuRen_Six"] = "6.0糜夫人",
	["&MiFuRen_Six"] = "糜夫人",
	["#MiFuRen_Six"] = "舍身存嗣",
	["designer:MiFuRen_Six"] = "5D_lan",
	["cv:MiFuRen_Six"] = "暂无",
	["illustrator:MiFuRen_Six"] = "略",

	["SixHusi"] = "护嗣",
	[":SixHusi"] = "当距离1以内的角色的牌于其回合外被除其之外的其他角色获得或弃置前，你可以终止当前移动牌的结算，再摸一张牌，然后失去1点体力。\
◆你距离1以内的角色的牌被除其之外的其他角色置入处理区满足发动【护嗣】的条件。（如【突袭】、【缔盟】）\
★已知BUG：被置入处理区时无法发动（突袭缔盟等）；\
由于太阳神三国杀的程序问题，实际效果为：此牌在被移动后移回原处，中间不会触发技能。（不影响技能效果）",
	["SixToujing"] = "投井",
	[":SixToujing"] = "<font color=\"blue\"><b>锁定技，</b></font>当你死亡时，伤害来源为自己或沒有伤害来源，你需将所有牌交给一名其他角色，然后令其回复2点体力。",
	["@SixToujing"] = "请选择“投井”的目标角色",


	----------------------------------------------------------------------------------------------------
	["SunCe_Plus"] = "7.0孙策",
	["&SunCe_Plus"] = "孙策",
	["#SunCe_Plus"] = "江东小霸王",
	["designer:SunCe_Plus"] = "小A",
	["cv:SunCe_Plus"] = "官方",
	["illustrator:SunCe_Plus"] = "略",

	["PlusYingwu"] = "英武",
	[":PlusYingwu"] = "回合开始时，你可以弃置一张牌或失去1点体力，声明并拥有“英姿”或“英魂”中的一项技能，直到回合结束。",
	["@PlusYingwu"] = "你可以弃置一张牌，否则失去1点体力",


	----------------------------------------------------------------------------------------------------
	["GuYong_Six"]               = "6.0顾雍",
	["&GuYong_Six"]              = "顾雍",
	["#GuYong_Six"]              = "一代名相",
	["designer:GuYong_Six"]      = "锦衣祭司",
	["cv:GuYong_Six"]            = "暂无",
	["illustrator:GuYong_Six"]   = "略",

	["SixLiangjie"]              = "亮节",
	[":SixLiangjie"]             = "每当你成为【杀】的目标时，若你有手牌，你可以展示所有手牌，若颜色均相同，你可以摸两张牌。",
	["SixLiangjieDraw:draw"]     = "你可以摸两张牌",
	----------------------------------------------------------------------------------------------------
	["SunLuBan_Six"]             = "7.0孙鲁班",
	["&SunLuBan_Six"]            = "孙鲁班",
	["#SunLuBan_Six"]            = "吴全公主",
	["designer:SunLuBan_Six"]    = "锦衣祭司",
	["cv:SunLuBan_Six"]          = "暂无",
	["illustrator:SunLuBan_Six"] = "略",

	["SixZenhui"]                = "谮毁",
	[":SixZenhui"]               = "其他角色的结束阶段开始时，若其于出牌阶段内使用【杀】造成了伤害，你可以弃置一张黑桃牌，令其攻击范围内你选择的另一名其他角色获得其一张手牌。",
	["@SixZenhui"]               = "你可以弃置一张黑桃牌发动“谮毁”<br/> <b>操作提示</b>: 选择一张黑桃牌→点击确定<br/>",
	["@SixZenhuiPlayer"]         = "请选择 %src 攻击范围内的另一名其他角色，令其获得 %src 的一张手牌",
	["SixJiahuo"]                = "嫁祸",
	[":SixJiahuo"]               = "每当你进入濒死状态时，你可以弃置一名其他角色的一至两张手牌，然后若其中有红桃基本牌，你回复1点体力。",
	["@SixJiahuo"]               = "你可以发动“嫁祸”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["SixJiahuoSecond:second"]   = "你可以点击确定弃置其两张牌，或点击取消弃置其一张牌",
	----------------------------------------------------------------------------------------------------
	["ChengPu_Six"]              = "7.0程普",
	["&ChengPu_Six"]             = "程普",
	["#ChengPu_Six"]             = "三朝虎臣",
	["designer:ChengPu_Six"]     = "5D_lan",
	["cv:ChengPu_Six"]           = "官方",
	["illustrator:ChengPu_Six"]  = "略",

	["SixChunlao"]               = "醇醪",
	[":SixChunlao"]              = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并选择一种花色，获得一名有手牌的其他角色的一张手牌，然后展示之，若此牌的花色与你所选的不同，你将此牌置于你的武将牌上，称为“醇”；每当一名角色处于濒死状态时，你可以将两张花色相同的“醇”置入弃牌堆，令该角色视为使用一张【酒】。",
	["sixchunlao"]               = "醇醪",
	["sixchunlaowine"]               = "醇醪",
	["beer"]                     = "醇",
	----------------------------------------------------------------------------------------------------
	["liuxie_Seven"]             = "7.5刘协",
	["&liuxie_Seven"]            = "刘协",
	["#liuxie_Seven"]            = "汉献帝",
	["designer:liuxie_Seven"]    = "锦衣祭司",
	["cv:liuxie_Seven"]          = "官方",
	["illustrator:liuxie_Seven"] = "略",

	["SevenMizhao"]              = "密诏",
	[":SevenMizhao"]             = "你可以跳过出牌阶段和弃牌阶段，然后若你是手牌数最多的角色，你将所有手牌交给一名其他角色。",
	["SevenMizhao-invoke"]       = "你可以发动“密诏”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["SevenJiujia"]              = "救驾",
	[":SevenJiujia"]             = "每当你于回合外需要使用或打出基本牌时，你可以令其他角色选择是否打出一张此基本牌（视为由你使用或打出），若一名角色如此做，你令其摸两张牌。",
	["SevenJiujiapeach"]         = "是否响应救驾打出一张【桃】",
	["SevenJiujiajink"]          = "是否响应救驾打出一张【闪】",
	["SevenJiujiaslash"]         = "是否响应救驾打出一张【杀】",
	["sevenjiujia"]         = "救驾",
	["@@SevenJiujia"]            = "是否响应救驾使用或打出一张 %src",
	----------------------------------------------------------------------------------------------------
	["WangZiFu_Six"]             = "6.0王子服",
	["&WangZiFu_Six"]            = "王子服",
	["#WangZiFu_Six"]            = "王室之狼",
	["designer:WangZiFu_Six"]    = "小A",
	["cv:WangZiFu_Six"]          = "官方",
	["illustrator:WangZiFu_Six"] = "略",

	["SixMiBian"]                = "密变",
	[":SixMiBian"]               = "出牌阶段限一次，若你的手牌数大于你的体力上限，你可以弃置任意张不同花色的手牌并选择你攻击范围内的一名其他角色，令攻击范围内含有该角色的所有角色（该角色除外）各选择是否展示一张与你弃置的一张牌花色相同的手牌，如此做的角色视为对其使用一张【杀】。",
	["sixmibian"]                = "密变",
	["@SixMiBian"]               = "你可以展示一张花色相同的手牌，视为对 %src 使用一张【杀】",

	----------------------------------------------------------------------------------------------------
	["LiuZhang_Six"]             = "6.0刘璋",
	["&LiuZhang_Six"]            = "刘璋",
	["#LiuZhang_Six"]            = "暗弱不武",
	["designer:LiuZhang_Six"]    = "array88",
	["cv:LiuZhang_Six"]          = "官方",
	["illustrator:LiuZhang_Six"] = "略",

	["SixYinLang"]               = "引狼",
	[":SixYinLang"]              = "锁定技，准备阶段开始时，若你的手牌数大于你当前的体力值，你失去1点体力。",
	["SixZuoBao"]                = "坐保",
	[":SixZuoBao"]               = "你的回合外，你可以将一张牌当一张与此牌字数相同的牌使用或打出。",

	----------------------------------------------------------------------------------------------------
	["JuShou_Six"]               = "6.0沮授",
	["&JuShou_Six"]              = "沮授",
	["#JuShou_Six"]              = "河北俊杰",
	["designer:JuShou_Six"]      = "玉面",
	["cv:JuShou_Six"]            = "官方",
	["illustrator:JuShou_Six"]   = "略",

	["SixShouLue"]               = "守略",
	[":SixShouLue"]              = "锁定技，你的手牌上限+X（X为你装备区里的牌数+2）。",
	["SixJianCe"]                = "谏策",
	[":SixJianCe"]               = "其他角色的出牌阶段开始时，你可以令其摸一张牌，然后与其拼点。若你赢，你可以获得其所有手牌，若如此做，将等量的手牌交给该角色。若你没赢，你失去1点体力。",

	----------------------------------------------------------------------------------------------------
	["HeJin_Six"]                = "6.0何进",
	["&HeJin_Six"]               = "何进",
	["#HeJin_Six"]               = "谋诛宦竖",
	["designer:HeJin_Six"]       = "玉面",
	["cv:HeJin_Six"]             = "官方",
	["illustrator:HeJin_Six"]    = "略",


	["SixYangShi"] = "养仕",
	[":SixYangShi"] = "摸牌阶段开始时，你可以放弃摸牌，令其他角色各摸一张牌，然后令其他角色各将一张手牌交给你，最后若你是手牌数最多的角色，你不能使用【杀】，直到回合结束。",
	["@SixYangShiGive"] = "交给 %src 一张手牌",

	----------------------------------------------------------------------------------------------------

	["LiuBei_Seven"] = "7.0刘备",
	["&LiuBei_Seven"] = "刘备",
	["#LiuBei_Seven"] = "乱世的枭雄",
	["designer:LiuBei_Seven"] = "玉面",
	["cv:LiuBei_Seven"] = "官方",
	["illustrator:LiuBei_Seven"] = "略",

	["SevenRenDe"] = "仁德",
	[":SevenRenDe"] = "弃牌阶段开始时，你可以将手牌数补至X张（X为全场角色数），然后回复1点体力，最后依次将至少一张手牌交给所有其他角色。",
	["@SevenRenDe"] = "交给 %src 一张手牌",

	----------------------------------------------------------------------------------------------------

	["WeiYan_Seven"] = "7.0魏延",
	["&WeiYan_Seven"] = "魏延",
	["#WeiYan_Seven"] = "镇守汉中",
	["designer:WeiYan_Seven"] = "锦衣祭司",
	["cv:WeiYan_Seven"] = "官方",
	["illustrator:WeiYan_Seven"] = "略",

	["SevenJuDi"] = "拒敌",
	[":SevenJuDi"] = "结束阶段开始时，你可以将你的武将牌翻面，依次弃置一至三名其他角色的共计三张牌，当你以此法弃置的一张牌置入弃牌堆时，若此牌为【闪】，你可以获得之。",
	["@SevenJuDi-card"] = "你可以弃置一至三名其他角色的共计三张牌",
	["~SevenJuDi"] = "选择一至三名其他角色→点击确定",
	["sevenjudi"] = "拒敌",

	----------------------------------------------------------------------------------------------------

	["MaZhong_Seven"] = "7.0马忠",
	["&MaZhong_Seven"] = "马忠",
	["#MaZhong_Seven"] = "镇蜀之南",
	["designer:MaZhong_Seven"] = "玉面",
	["cv:MaZhong_Seven"] = "官方",
	["illustrator:MaZhong_Seven"] = "略",

	["SevenKanLuan"] = "戡乱",
	["sevenkanluan"] = "戡乱",
	[":SevenKanLuan"] = "出牌阶段开始时，若你的手牌数大于你当前的体力值，你可以弃置X张手牌（X为你的手牌数与你当前的体力值的差），视为使用一张【杀】，然后若X不小于你当前的体力值，你可以获得此【杀】的目标角色装备区里的一张牌。",
	["@SevenKanLuan"] = "请弃置若干张牌",
	["~SevenKanLuan"] = "选择若干张牌（若有）→点击确定",


	----------------------------------------------------------------------------------------------------

	["MaLiang_Seven"]              = "7.0马良",
	["&MaLiang_Seven"]             = "马良",
	["#MaLiang_Seven"]             = "白眉令士",
	["designer:MaLiang_Seven"]     = "array88",
	["cv:MaLiang_Seven"]           = "官方",
	["illustrator:MaLiang_Seven"]  = "略",

	["sevenzhaoxiang"]             = "招降",
	["SevenZhaoXiang"]             = "招降",
	[":SevenZhaoXiang"]            = "出牌阶段限一次，你可以获得一名其他角色装备区里的一张牌，若如此做，你令其摸两张牌。",
	["SevenZhenShi"]               = "贞实",
	[":SevenZhenShi"]              = "弃牌阶段开始时，若你的手牌数大于你的体力上限，你可以将至少两张手牌交给一名其他角色，回复1点体力。",
	["SevenZhenShi-invoke"]        = "你可以发动“贞实”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["@SevenZhenShi"]              = "将至少两张手牌交给一名其他角色",

	----------------------------------------------------------------------------------------------------
	["SiMaYi_Seven"]               = "7.0司马懿",
	["&SiMaYi_Seven"]              = "司马懿",
	["#SiMaYi_Seven"]              = "狼顾之鬼",
	["designer:SiMaYi_Seven"]      = "锦衣祭司",
	["cv:SiMaYi_Seven"]            = "官方",
	["illustrator:SiMaYi_Seven"]   = "略",

	["SevenTaoHui"]                = "韬晦",
	[":SevenTaoHui"]               = "每当你受到伤害后，你可以将你的武将牌翻面，然后摸两张牌。",
	["SevenLangMou"]               = "狼谋",
	[":SevenLangMou"]              = "每当你的武将牌翻面后，若你的武将牌正面朝上，你可以进行判定，当判定牌生效后，你获得此牌。",
	["SevenQuanBian"]              = "权变",
	[":SevenQuanBian"]             = "每当一名角色的判定牌生效前，你可以打出一张手牌代替之，若如此做，你可以根据此牌的颜色令所有角色各执行相应效果：黑色，失去1点体力；红色，回复1点体力。",
	["@SevenQuanBian-card"]        = "请发动“%dest”来修改 %src 的“%arg”判定",
	["~SevenQuanBian"]             = "选择一张手牌→点击确定",

	----------------------------------------------------------------------------------------------------
	["LiuYe_Seven"]                = "7.0刘晔",
	["&LiuYe_Seven"]               = "刘晔",
	["#LiuYe_Seven"]               = "三朝元老",
	["designer:LiuYe_Seven"]       = "array88",
	["cv:LiuYe_Seven"]             = "官方",
	["illustrator:LiuYe_Seven"]    = "略",

	["SevenZhiDi"]                 = "知敌",
	--[":SevenZhiDi"] = "其他角色的出牌阶段开始时，你可以声明一张非基本牌的名称，令其不能使用或打出此牌，直到回合结束。",
	[":SevenZhiDi"]                = "其他角色的出牌阶段开始时，你可以声明一张普通锦囊牌的名称，令其不能使用或打出此牌，直到回合结束。",
	["SevenChuaiYi"]               = "揣意",
	[":SevenChuaiYi"]              = "每当你受到伤害时，若来源与你均有手牌，你可以令来源与你同时展示一张手牌，若两张牌的花色不同，此伤害-1，否则你弃置你展示的手牌。",
	["@SevenChuaiYi-show"]         = "揣意<br>选择一张手牌→点击确定",
	["#SevenChuaiYiDecrease"]      = "%from 发动了“<font color=\"yellow\"><b>揣意</b></font>”，伤害点数从 %arg 点减少至 %arg2 点",

	----------------------------------------------------------------------------------------------------
	["CaoAng_Seven"]               = "7.0曹昂",
	["&CaoAng_Seven"]              = "曹昂",
	["#CaoAng_Seven"]              = "曹氏之哀",
	["designer:CaoAng_Seven"]      = "锦衣祭司",
	["cv:CaoAng_Seven"]            = "官方",
	["illustrator:CaoAng_Seven"]   = "略",

	["sevenweiyuan"]               = "危援",
	["SevenWeiYuan"]               = "危援",
	[":SevenWeiYuan"]              = "每当一名其他角色进入濒死状态时，你可以选择一项：\
1.失去1点体力，获得其一张牌；\
2.将一张装备牌置于其装备区里。\
若如此做，你令该角色回复1点体力。",
	----------------------------------------------------------------------------------------------------
	["XuYou_Seven"]                = "7.0许攸",
	["&XuYou_Seven"]               = "许攸",
	["#XuYou_Seven"]               = "官渡功臣",
	["designer:XuYou_Seven"]       = "锦衣祭司",
	["cv:XuYou_Seven"]             = "官方",
	["illustrator:XuYou_Seven"]    = "略",

	["SevenJuGong"]                = "居功",
	[":SevenJuGong"]               = "锁定技，摸牌阶段，你额外摸X张牌（X为你已损失的体力值），然后若你是手牌数最多的角色，你选择一项：1.失去1点体力；2.弃置X张牌。",
	["sevenfenliang"]              = "焚粮",
	["SevenFenLiang"]              = "焚粮",
	[":SevenFenLiang"]             = "限定技，出牌阶段，你可以选择一名手牌数大于其当前的体力值的角色并弃置X张牌（X为你与该角色的距离），令该角色弃置其所有手牌，然后你对其造成1点伤害。",

	----------------------------------------------------------------------------------------------------
	["ZhuGeDan_Seven"]             = "7.0诸葛诞",
	["&ZhuGeDan_Seven"]            = "诸葛诞",
	["#ZhuGeDan_Seven"]            = "逼反的功臣",
	["designer:ZhuGeDan_Seven"]    = "锦衣祭司",
	["cv:ZhuGeDan_Seven"]          = "官方",
	["illustrator:ZhuGeDan_Seven"] = "略",

	["SevenPingPan"]               = "平叛",
	[":SevenPingPan"]              = "每当一名非主公的其他角色因你造成的伤害而进入濒死状态时，你可以亮出你与其的身份牌，然后你可以先摸三张牌，再将该角色的身份改变为与你阵营相同且非主公的一种身份。",
	["SevenHuBei"]                 = "狐悲",
	--[":SevenHuBei"] = "每当与你阵营相同的角色受到伤害后，你可以弃置一张牌，摸两张牌。", tooweak
	[":SevenHuBei"]                = "每当一名角色受到伤害后，其可以令你选择是否弃置一张牌，摸两张牌。",
	["@SevenHuBei"]                = "狐悲<br>选择一张牌→点击确定",
	----------------------------------------------------------------------------------------------------
	["CaoZhen_Seven"]              = "7.0曹真",
	["&CaoZhen_Seven"]             = "曹真",
	["#CaoZhen_Seven"]             = "元侯",
	["designer:CaoZhen_Seven"]     = "锦衣祭司",
	["cv:CaoZhen_Seven"]           = "官方",
	["illustrator:CaoZhen_Seven"]  = "略",

	["SevenXiaoRui"]               = "骁锐",
	[":SevenXiaoRui"]              = "出牌阶段，你使用【杀】无距离限制且选择目标的个数上限+X（X为你已损失的体力值），若如此做，当此【杀】被目标角色使用的【闪】抵消时，你将你的武将牌翻面。",

	----------------------------------------------------------------------------------------------------
	["ZhongYao_Seven"]             = "7.0钟繇",
	["&ZhongYao_Seven"]            = "钟繇",
	["#ZhongYao_Seven"]            = "佐命立勋",
	["designer:ZhongYao_Seven"]    = "锦衣祭司",
	["cv:ZhongYao_Seven"]          = "官方",
	["illustrator:ZhongYao_Seven"] = "略",

	["SevenKaiJue"]                = "楷绝",
	[":SevenKaiJue"]               = "每当一张非延时类锦囊牌因使用而置入弃牌堆后，你可以弃置一张牌，进行一次判定，若结果为红色，你可以用一张非基本牌替换此非延时类锦囊牌，若结果为黑色，你可以将一张基本牌当此牌使用。", --????
	["SevenShuXi"]                 = "戍西",
	[":SevenShuXi"]                = "锁定技，其他角色与你的距离+1。",

	----------------------------------------------------------------------------------------------------
	["SunYi_Seven"]                = "7.0孙翊",
	["&SunYi_Seven"]               = "孙翊",
	["#SunYi_Seven"]               = "骁悍果烈",
	--["designer:SunYi_Seven"] = "锦衣祭司",
	["cv:SunYi_Seven"]             = "官方",
	["illustrator:SunYi_Seven"]    = "略",

	["sevenyingyong"]              = "英勇",
	["SevenYingYong"]              = "英勇",
	[":SevenYingYong"]             = "结束阶段开始时，若你于弃牌阶段内弃置的手牌数不小于2，你可以摸一张牌，然后视为使用一张【决斗】。",
	["@SevenYingYong"]             = "你可以发动“英勇”",
	["~SevenYingYong"]             = "选择目标角色→点击确定",

	----------------------------------------------------------------------------------------------------
	["ZhuZhi_Seven"]               = "7.0朱治",
	["&ZhuZhi_Seven"]              = "朱治",
	["#ZhuZhi_Seven"]              = "毗陵侯",
	--["designer:ZhuZhi_Seven"] = "锦衣祭司",
	["cv:ZhuZhi_Seven"]            = "官方",
	["illustrator:ZhuZhi_Seven"]   = "略",

	["SevenFuTui"]                 = "辅退",
	[":SevenFuTui"]                = "每当其他角色于其出牌阶段内造成伤害后，你可以弃置一张手牌，令其结束此阶段。",

	----------------------------------------------------------------------------------------------------
	["ZuMao_Seven"]                = "7.0祖茂",
	["&ZuMao_Seven"]               = "祖茂",
	["#ZuMao_Seven"]               = "虎之心腹",
	--["designer:ZuMao_Seven"] = "锦衣祭司",
	["cv:ZuMao_Seven"]             = "官方",
	["illustrator:ZuMao_Seven"]    = "略",

	["SevenYiZe"]                  = "易帻",
	[":SevenYiZe"]                 = "结束阶段开始时，你可以将手牌数补至等同于你当前的体力值，然后获得一名其他角色装备区里的一张牌。",
	["SevenYinBing"]               = "引兵",
	[":SevenYinBing"]              = "锁定技，若你的手牌数大于你当前的体力值，装备区里没有牌的角色（你除外）不是其他角色使用【杀】的合法目标。",

	----------------------------------------------------------------------------------------------------
	["SunJun_Seven"]               = "7.0孙峻",
	["&SunJun_Seven"]              = "孙峻",
	["#SunJun_Seven"]              = "乱政的阴谋家",
	--["designer:SunJun_Seven"] = "锦衣祭司",
	["cv:SunJun_Seven"]            = "官方",
	["illustrator:SunJun_Seven"]   = "略",

	["sevenzhengbian"]             = "政变",
	["SevenZhengBian"]             = "政变",
	[":SevenZhengBian"]            = "出牌阶段限一次，你可以弃置一张装备牌并选择一名其他角色，选择一项：\
1.令其于此回合内不能使用或打出基本牌；\
2.获得其装备区里的一张牌。",
	["SevenLanQuan"]               = "揽权",
	[":SevenLanQuan"]              = "其他角色的结束阶段开始时，若其没有牌于其出牌阶段内因使用而置入弃牌堆，你可以摸两张牌。",
	["SevenZhengBian_limit"]       = "令其于此回合内不能使用或打出基本牌",
	["SevenZhengBian_equip"]       = "获得其装备区里的一张牌",

	----------------------------------------------------------------------------------------------------
	["ZhouYu_Seven"]               = "7.0周瑜",
	["&ZhouYu_Seven"]              = "周瑜",
	["#ZhouYu_Seven"]              = "美周郎",
	--["designer:ZhouYu_Seven"] = "锦衣祭司",
	["cv:ZhouYu_Seven"]            = "官方",
	["illustrator:ZhouYu_Seven"]   = "略",

	["SevenQuGao"]                 = "曲高",
	[":SevenQuGao"]                = "每当一名角色成为一张非延时类锦囊牌的唯一目标后，你可以弃置一张与此牌花色相同的手牌，选择一项：1.令此次对其结算的此牌对其无效；2.令此牌对该角色进行两次使用结算。",
	["SevenQuGao_double"]          = "令此牌对该角色进行两次使用结算",
	["SevenQuGao_invalid"]         = "令此次对其结算的此牌对其无效",
	["@SevenQuGao-discard"]        = "你可以弃置一张 %src 令 %arg 结算两次或对其无效 ",






	----------------------------------------------------------------------------------------------------
	["ShiChangShi_Seven"] = "7.0十常侍",
	["&ShiChangShi_Seven"] = "十常侍",
	["#ShiChangShi_Seven"] = "祸国殃民",
	--["designer:ShiChangShi_Seven"] = "锦衣祭司",
	["cv:ShiChangShi_Seven"] = "官方",
	["illustrator:ShiChangShi_Seven"] = "略",

	["SevenBaChao"] = "把朝",
	[":SevenBaChao"] = "锁定技，每当你使用非延时类锦囊牌时，你须选择失去1点体力或失去1点体力上限，然后所有角色不能使用【无懈可击】响应此牌。",
	["SevenLuanZheng"] = "乱政",
	["sevenluanzheng"] = "乱政",
	[":SevenLuanZheng"] = "出牌阶段限一次，你可以令所有角色各获得其上家的一张手牌。",

	----------------------------------------------------------------------------------------------------
	["XiLu_Seven"] = "7.0郗虑",
	["&XiLu_Seven"] = "郗虑",
	["#XiLu_Seven"] = "虎之饰品",
	--["designer:XiLu_Seven"] = "锦衣祭司",
	["cv:XiLu_Seven"] = "官方",
	["illustrator:XiLu_Seven"] = "略",

	["SevenBeiJie"] = "悲节",
	[":SevenBeiJie"] = "锁定技，你的红色牌视为点数为Q的牌，你的黑色牌视为点数为2的牌。",
	["SevenJieMing"] = "借名",
	[":SevenJieMing"] = "锁定技，每当你受到伤害时，来源需将一张手牌交给你，否则此伤害-1。",
	["SevenTaDao"] = "他刀",
	[":SevenTaDao"] = "其他角色的出牌阶段结束时，若其未于此阶段内使用过【杀】，其可以与你拼点。若你赢，其对你造成1点伤害。若你没赢，你对其攻击范围内其选择的另一名角色造成1点伤害。",

	----------------------------------------------------------------------------------------------------
	["ZhangLu_Seven"] = "7.0张鲁",
	["&ZhangLu_Seven"] = "张鲁",
	["#ZhangLu_Seven"] = "世袭天师",
	["designer:ZhangLu_Seven"] = "锦衣祭司",
	["cv:ZhangLu_Seven"] = "官方",
	["illustrator:ZhangLu_Seven"] = "略",

	["sevenchuanjiao"] = "传教",
	["SevenChuanJiao"] = "传教",
	[":SevenChuanJiao"] = "出牌阶段限一次，你可以令所有角色各展示一张手牌，然后你选择一种颜色，令展示此颜色手牌的角色各摸一张牌。",
	["SevenMiDao"] = "米道",
	[":SevenMiDao"] = "若其他角色使用点数不大于5的牌仅选择一名目标角色后，其与目标角色的距离不小于其与你的距离，当此牌结算结束后，你可以获得之。",
	----------------------------------------------------------------------------------------------------
	["XuShaoXuQian_Seven"] = "7.0许劭&许虔",
	["&XuShaoXuQian_Seven"] = "许劭许虔",
	["#XuShaoXuQian_Seven"] = "平舆二龙",
	["designer:XuShaoXuQian_Seven"] = "玉面",
	["cv:XuShaoXuQian_Seven"] = "官方",
	["illustrator:XuShaoXuQian_Seven"] = "略",

	["sevenfengping"] = "风评",
	["SevenFengPing"] = "风评",
	[":SevenFengPing"] = "出牌阶段限一次，你可以选择一名其他角色，令除其之外的角色各选择是否弃置一张红色/黑色手牌，然后其摸/弃置X张牌（X为这些角色以此法弃置的手牌数）。",
	["SevenYueDan"] = "月旦",
	[":SevenYueDan"] = "每当“风评”结算结束后，你可以获得因此技能而弃置的基本牌，然后将你的武将牌翻面，结束当前回合。",
	["@SevenFengPing"] = "<b>风评</b>角色为 %dest <br>  选择是否弃置一张 %src 手牌",
	["@SevenFengPing_Throw"] = "<b>风评</b><br>弃置 %src 张牌",










	----------------------------------------------其他--------------------------------------------------

	["#ChangeToPlus"] = "变身为标风重铸武将",

	----------------------------------------------音效--------------------------------------------------
	--技能音效
	--魏
	["$PlusJianxiong"] = "宁教我负天下人,休教天下人负我",
	["$PlusLangmou"] = "下次注意点",
	["$PlusGuicai"] = "天命？哈哈哈哈～",
	["$PlusTiandu"] = "就这样吧",
	["$PlusYiji"] = "也好……",
	["$PlusGanglie"] = "鼠辈，竟敢伤我！",
	["$PlusTuxi"] = "没想到吧",
	["$PlusLuoyi1"] = "谁来与我大战三百回合",
	["$PlusLuoyi2"] = "破！",
	["$PlusShensu1"] = "吾善于千里袭人",
	["$PlusShensu2"] = "取汝首级犹如探囊取物",
	["$PlusJushou1"] = "我先休息一会",
	["$PlusJushou2"] = "尽管来吧",
	["$PlusKuiwei"] = "熬过此战，可见胜机！",
	["$PlusYizhong1"] = "不先为备，何以待敌",
	["$PlusYizhong2"] = "稳重行军，百战不殆！",
	["$PlusJilei"] = "食之无味，弃之可惜",

	--蜀
	["$PlusRende1"] = "惟贤惟德，仁服于人",
	["$PlusRende2"] = "以德服人",
	["$PlusGuanxing1"] = "知天易,逆天难",
	["$PlusGuanxing2"] = "观今夜天象,知天下大事",
	["$PlusKongcheng1"] = "（抚琴声）",
	["$PlusKongcheng2"] = "（抚琴声）",
	["$PlusWusheng1"] = "关羽在此，尔等受死",
	["$PlusWusheng2"] = "看尔乃插标卖首",
	["$PlusPaoxiao"] = "啊～",
	["$PlusJie1"] = "杂碎，也敢在爷爷面前叫嚣！",
	["$PlusJie2"] = "三姓家奴，吃我一矛！",
	["$PlusLongdan1"] = "能进能退乃真正法器",
	["$PlusLongdan2"] = "喝~",
	["$PlusTieji"] = "全军突击！",
	["$PlusJizhi"] = "哼",
	["$PlusYongyi"] = "中！",
	["$PlusLiegong"] = "百步穿杨",
	["$PlusZaiqi1"] = "吾不服也",
	["$PlusZaiqi2"] = "孔明，汝计穷也",
	["$PlusZaiqi3"] = "敌军势大，吾先退避",

	--吴
	["$PlusZhiheng"] = "容我三思",
	["$PlusFanjian1"] = "挣扎吧，在血和暗的深渊里",
	["$PlusFanjian2"] = "痛苦吧，在仇与恨的地狱中",
	["$PlusKeji1"] = "我忍",
	["$PlusKeji2"] = "君子藏器于身，待时而动",
	["$PlusDuoshi"] = "牌不是万能的，但是没牌是万万不能的",
	["$PlusQixi1"] = "接招吧",
	["$PlusQixi2"] = "你的牌太多啦",
	["$PlusKurou"] = "请鞭挞我吧，公瑾！",
	["$PlusLiuli1"] = "交给你了",
	["$PlusLiuli2"] = "你来嘛～",
	["$PlusJieyin1"] = "夫君,身体要紧",
	["$PlusJieyin2"] = "他好，我也好",
	["$PlusJieyin3"] = "贤弟脸似花含露，玉树流光照后庭", -- 攻
	["$PlusJieyin4"] = "愿为西南风,长逝入君怀", -- 受
	["$PlusJieyin5"] = "我有嘉宾，鼓瑟吹箫", -- 自己
	["$PlusTianxiang1"] = "替我挡着",
	["$PlusTianxiang2"] = "接着哦",
	["$PlusBuqu1"] = "还不够！",
	["$PlusBuqu2"] = "我绝不会倒下！",

	--群
	["$PlusMafei1"] = "别紧张，有老夫呢",
	["$PlusMafei2"] = "救人一命，胜造七级浮屠",
	["$PlusXuanhu1"] = "早睡早起,方能养生",
	["$PlusXuanhu2"] = "越老越要补啊",
	["$PlusGuidao1"] = "天下大势，为我所控",
	["$PlusGuidao2"] = "哼哼哼~",
	["$PlusLeiji1"] = "以我之真气，合天地之造化",
	["$PlusLeiji2"] = "雷公助我",
	["$PlusHuangtian1"] = "苍天已死，黄天当立",
	["$PlusHuangtian2"] = "岁在甲子，天下大吉",
	["$PlusYicong1"] = "冲啊！",
	["$PlusYicong2"] = "众将听令，摆好阵势，御敌！",
	["$PlusShiyong1"] = "都是小伤，不必理会！",
	["$PlusShiyong2"] = "这厮好大的力气！",
	["$PlusShiyong3"] = "唉，这厮不易对付！", --关羽
	["$PlusMizhao1"] = "铲除奸党，全赖爱卿了。",
	["$PlusMizhao2"] = "皇叔，救我！",

	--阵亡音效
	["~CaoCao_Plus"] = "霸业未成，未成啊……",
	["~SiMaYi_Plus"] = "难道真是天命难违？",
	["~GuoJia_Plus"] = "咳，咳……",
	["~XiaHouDun_Plus"] = "两边都看不见啦……",
	["~ZhangLiao_Plus"] = "真没想到",
	["~XuChu_Plus"] = "冷，好冷啊……",
	["~ZhenJi_Plus"] = "悼良会之永绝兮，哀一逝而异乡。",
	["~XiaHouYuan_Plus"] = "竟然比我还……快……",
	["~CaoRen_Plus"] = "实在是守不住了……",
	["~YuJin_Plus"] = "我……无颜面对丞相了……",
	["~YangXiu_Plus"] = "恃才傲物，方有此命",

	["~LiuBei_Plus"] = "这就是桃园吗？",
	["~ZhuGeLiang_Plus"] = "将星陨落，天命难违",
	["~GuanYu_Plus"] = "什么？此地叫麦城？",
	["~ZhangFei_Plus"] = "实在是杀不动啦……",
	["~ZhaoYun_Plus"] = "这就是失败的滋味吗？",
	["~MaChao_Plus"] = "(马蹄声……)",
	["~HuangYueYing_Plus"] = "亮",
	["~HuangZhong_Plus"] = "不得不服老了……",
	["~WeiYan_Plus"] = "谁敢杀我！啊……",
	["~MengHuo_Plus"] = "粳民之地，再无主矣",

	["~SunQuan_Plus"] = "父亲，大哥，仲谋溃矣……",
	["~ZhouYu_Plus"] = "既生瑜，何生……",
	["~LvMeng_Plus"] = "呃，被看穿了吗？",
	["~LuXun_Plus"] = "我还是太年轻了……",
	["~GanNing_Plus"] = "二十年后，又是一条好汉。",
	["~HuangGai_Plus"] = "失血过多了……",
	["~DaQiao_Plus"] = "伯符，我去了",
	["~SunShangXiang_Plus"] = "不！还不可以死！",
	["~XiaoQiao_Plus"] = "公瑾……我先走一步……",
	["~ZhouTai_Plus"] = "已经尽力了……",
	["~SunJian_Plus"] = "死去何愁无勇将，英魂依旧卫江东",

	["~LvBu_Plus"] = "不可能！",
	["~DiaoChan_Plus"] = "父亲大人，对不起",
	["~HuaTuo_Plus"] = "医者不能自医啊",
	["~ZhangJiao_Plus"] = "黄天…也死了……",
	["~YuJi_Plus"] = "竟然被猜到了",
	["~GongSunZan_Plus"] = "我军将败，我已无颜苟活于世",
	["~HuaXiong_Plus"] = "太自负了么……",
	["~LiuXie_Plus"] = "大汉江山断于我手，可恨啊……",
}
--注：将prompt信息改为@；检查关于Flag的技能


----------------------------------------------------------------------------------------------------
--                                             魏
----------------------------------------------------------------------------------------------------


--[[ WEI 001 曹操
	武将：CaoCao_Plus
	武将名：曹操
	称号：超世之英杰
	国籍：魏
	体力上限：4
	武将技能：
		奸雄(PlusJianxiong)：你即将造成伤害时，可以弃置一张黑色手牌并指定一名其他角色，然后视为由该角色造成此伤害。
		武略(PlusWulve)：每当你受到一次伤害后，你可以选择一项：1.获得对你造成伤害的牌。2.弃置一张牌（无牌则不弃），然后摸X张牌（X为你已损失的体力值）。
		护驾：主公技，当你需要使用或打出一张【闪】时，你可令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	技能设计：锦衣祭司
	状态：尚未完成
]]
--

CaoCao_Plus = sgs.General(extension, "CaoCao_Plus$", "wei", 4, true)

--[[
	技能：PlusJianxiong
	技能名：奸雄
	描述：你即将造成伤害时，可以弃置一张黑色手牌并指定一名其他角色，然后视为由该角色造成此伤害。
	状态：验证通过
]]
--
PlusJianxiong_Card = sgs.CreateSkillCard {
	name = "PlusJianxiong_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:objectName() ~= sgs.Self:objectName() then
			return #targets == 0
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local msg = sgs.LogMessage()
		msg.type = "#PlusJianxiong_msg"
		msg.from = source
		msg.to:append(target)
		room:sendLog(msg)
		room:setPlayerFlag(target, "PlusJianxiong_Victim")
	end,
}
PlusJianxiongVS = sgs.CreateViewAsSkill {
	name = "PlusJianxiong",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:isBlack()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusJianxiong_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusJianxiong"
	end
}
PlusJianxiong = sgs.CreateTriggerSkill {
	name = "PlusJianxiong",
	events = { sgs.ConfirmDamage, sgs.Predamage },
	view_as_skill = PlusJianxiongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then --奸雄目标跳过ConfirmDamage时机
			if player:hasFlag("PlusJianxiong_Victim") then
				room:setPlayerFlag(player, "-PlusJianxiong_Victim")
				return true
			end
		elseif event == sgs.Predamage then
			if player:hasSkill(self:objectName()) then
				if not player:isKongcheng() then
					local damage = data:toDamage()
					room:setTag("CurrentDamageStruct", data)
					if room:askForUseCard(player, "@PlusJianxiong", "#PlusJianxiong") then
						room:broadcastSkillInvoke(self:objectName())
						for _, victim in sgs.qlist(room:getAlivePlayers()) do
							if victim:hasFlag("PlusJianxiong_Victim") then --防止原伤害，更换伤害来源，然后重新结算新伤害，这样保证发动时机为Predamage
								--room:setPlayerFlag(victim, "-PlusJianxiong_Victim")
								damage.from = victim  --此行之后原有取消酒的代码，现删去
								room:damage(damage)
								return true
							end
						end
					end
					room:removeTag("CurrentDamageStruct")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
CaoCao_Plus:addSkill(PlusJianxiong)

--[[
	技能：PlusWulve
	技能名：武略
	描述：每当你受到一次伤害后，你可以选择一项：1.获得对你造成伤害的牌。2.弃置一张牌（无牌则不弃），然后摸X张牌（X为你已损失的体力值）。
	状态：验证通过
]]
--
PlusWulve = sgs.CreateTriggerSkill {
	name = "PlusWulve",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		local lostHp = player:getLostHp()
		local prompt = "PlusWulve_choice2=" .. lostHp .. "+PlusWulve_cancel"
		if card then
			local id = card:getEffectiveId()
			if room:getCardPlace(id) == sgs.Player_PlaceTable then
				prompt = "PlusWulve_choice1=" .. sgs.Sanguosha:getCard(id):objectName() .. "+ " .. prompt
			end
		end
		local choice = room:askForChoice(player, self:objectName(), prompt, data)
		local msg = sgs.LogMessage()
		if string.startsWith(choice, "PlusWulve_choice1") then --获得造成伤害的牌
			msg.type = "#PlusWulve1"
			msg.from = player
			msg.arg = self:objectName()
			room:sendLog(msg)
			player:obtainCard(card)
		elseif string.startsWith(choice, "PlusWulve_choice2") then --弃1张牌然后摸X张牌
			msg.type = "#PlusWulve2"
			msg.from = player
			msg.arg = self:objectName()
			room:sendLog(msg)
			room:askForDiscard(player, self:objectName(), 1, 1, false, true)

			room:drawCards(player, lostHp, self:objectName())
		end
	end,
}
CaoCao_Plus:addSkill(PlusWulve)

--[[
	技能：hujia
	技能名：护驾
	描述：主公技，当你需要使用或打出一张【闪】时，你可令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	状态：原有技能
]]
--
CaoCao_Plus:addSkill("hujia")

----------------------------------------------------------------------------------------------------

--[[ WEI 002 司马懿
	武将：SiMaYi_Plus
	武将名：司马懿
	称号：狼顾之鬼
	国籍：魏
	体力上限：3
	武将技能：
		狼谋(PlusLangmou)：每当你受到1点伤害后，你可以获得伤害来源的一张牌。
		鬼才(PlusGuicai)：在一名角色的判定牌或拼点牌（限其中一名角色）生效前，你可以打出一张手牌代替之。
		韬晦(PlusTaohui)：锁定技，若你的手牌数不大于你的体力上限，当其他角色使用非延时类锦囊牌指定你为目标时，需弃置一张手牌，否则此非延时类锦囊牌对你无效。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

SiMaYi_Plus = sgs.General(extension, "SiMaYi_Plus", "wei", 3, true)

--[[
	技能：PlusLangmou
	技能名：狼谋
	描述：每当你受到1点伤害后，你可以获得伤害来源的一张牌。
	状态：验证通过
]]
--
PlusLangmou = sgs.CreateTriggerSkill {
	name = "PlusLangmou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local source_data = sgs.QVariant()
		source_data:setValue(source)
		if source then
			local count = damage.damage
			for i = 1, count, 1 do
				if not source:isNude() then
					if room:askForSkillInvoke(player, self:objectName(), source_data) then
						room:broadcastSkillInvoke(self:objectName())
						local card_id = room:askForCardChosen(player, source, "he", self:objectName())
						room:obtainCard(player, card_id)
					else
						break
					end
				else
					break
				end
			end
		end
	end,
}
SiMaYi_Plus:addSkill(PlusLangmou)

--[[
	技能：PlusGuicai
	技能名：鬼才
	描述：在一名角色的判定牌或拼点牌（限其中一名角色）生效前，你可以打出一张手牌代替之。
	状态：验证通过
]]
--
sgs.PlusGuicai_Pattern = "pattern"
PlusGuicai_DummyCard = sgs.CreateSkillCard {
	name = "PlusGuicai_DummyCard",
	target_fixed = true,
	will_throw = false,
}
PlusGuicai_Card = sgs.CreateSkillCard {
	name = "PlusGuicai_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:hasFlag("PlusGuicai_Source") or to_select:hasFlag("PlusGuicai_Target")
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setPlayerFlag(target, "PlusGuicai_Modify")
		local card_id = effect.card:getSubcards():first()
		room:setTag("PlusGuicai_Card", sgs.QVariant(card_id))
	end,
}
PlusGuicai_VS = sgs.CreateViewAsSkill {
	name = "PlusGuicai",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = nil
		if sgs.PlusGuicai_Pattern == "@PlusGuicai1" then
			card = PlusGuicai_DummyCard:clone()
		elseif sgs.PlusGuicai_Pattern == "@PlusGuicai2" then
			card = PlusGuicai_Card:clone()
		end
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		sgs.PlusGuicai_Pattern = pattern
		return pattern == "@PlusGuicai1" or pattern == "@PlusGuicai2"
	end
}
PlusGuicai = sgs.CreateTriggerSkill {
	name = "PlusGuicai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial, sgs.PindianVerifying },
	view_as_skill = PlusGuicai_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				if not player:isKongcheng() then
					local judge = data:toJudge()
					local prompt = string.format("@PlusGuicai-card:%s:%s:%s", judge.who:objectName(), self:objectName(),
						judge.reason) --%src,%dest,%arg
					local card = room:askForCard(player, "@PlusGuicai1", prompt, data, sgs.Card_MethodResponse, nil, true)
					if card then
						room:broadcastSkillInvoke(self:objectName())
						room:retrial(card, player, judge, self:objectName())
					end
					return false
				end
			end
		elseif event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			local room = player:getRoom()
			local simayis = room:findPlayersBySkillName(self:objectName())
			if simayis:isEmpty() then return false end
			for _, simayi in sgs.qlist(simayis) do
				if not simayi:isKongcheng() then
					local source = pindian.from
					local target = pindian.to
					room:setPlayerFlag(source, "PlusGuicai_Source")
					room:setPlayerFlag(target, "PlusGuicai_Target")
					room:setTag("CurrentPindianStruct", data)
					local prompt = string.format("@PlusGuicai_Pindian::%s:%s", self:objectName(), pindian.reason)
					local use = room:askForUseCard(simayi, "@PlusGuicai2", prompt)
					room:removeTag("CurrentPindianStruct")
					room:setPlayerFlag(source, "-PlusGuicai_Source")
					room:setPlayerFlag(target, "-PlusGuicai_Target")
					local card_id = room:getTag("PlusGuicai_Card"):toInt()
					local card = sgs.Sanguosha:getCard(card_id)
					if use and card then
						room:broadcastSkillInvoke(self:objectName())
						local dest
						local oldcard
						if source:hasFlag("PlusGuicai_Modify") then
							dest = source
							oldcard = pindian.from_card
							pindian.from_card = card
							pindian.from_number = card:getNumber()
						elseif target:hasFlag("PlusGuicai_Modify") then
							dest = target
							oldcard = pindian.to_card
							pindian.to_card = card
							pindian.to_number = card:getNumber()
						end

						local move = sgs.CardsMoveStruct()
						move.card_ids:append(card_id)
						move.to = dest
						move.to_place = sgs.Player_PlaceTable
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RESPONSE, simayi:objectName())
						local move2 = sgs.CardsMoveStruct()
						move2.card_ids:append(oldcard:getEffectiveId())
						move2.to = nil
						move2.to_place = sgs.Player_DiscardPile
						move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, simayi:objectName())
						local moves = sgs.CardsMoveList()
						moves:append(move)
						moves:append(move2)
						room:moveCardsAtomic(moves, true)

						local msg = sgs.LogMessage()
						msg.type = "$PlusGuicai_PindianOne"
						msg.from = simayi
						msg.to:append(dest)
						msg.arg = self:objectName()
						msg.card_str = card:toString()
						room:sendLog(msg)
						data:setValue(pindian)
						local msg = sgs.LogMessage()
						msg.type = "$PlusGuicai_PindianFinal"
						msg.from = source
						msg.card_str = pindian.from_card:toString()
						room:sendLog(msg)
						msg.from = target
						msg.card_str = pindian.to_card:toString()
						room:sendLog(msg)
					end
					room:removeTag("PlusGuicai_Card")
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
SiMaYi_Plus:addSkill(PlusGuicai)

--[[
	技能：PlusTaohui
	技能名：韬晦
	描述：锁定技，若你的手牌数不大于你的体力上限，当其他角色使用非延时类锦囊牌指定你为目标时，需弃置一张手牌，否则此非延时类锦囊牌对你无效。
	状态：验证通过
]]
--
PlusTaohui = sgs.CreateTriggerSkill {
	name = "PlusTaohui",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local source = use.from
			local targets = use.to
			local card = use.card
			if source and source:objectName() ~= player:objectName() then
				if player:getHandcardNum() <= player:getMaxHp() then
					if targets:contains(player) then
						if card:isNDTrick() then
							for _, p in sgs.qlist(targets) do
								if p:hasSkill(self:objectName()) then
									room:setPlayerMark(p, self:objectName() .. "-Clear", 1)
									--local ai_data = sgs.QVariant()
									--ai_data:setValue(player)
									local prompt = string.format("@PlusTaohui:%s:%s:%s", p:objectName(),
										self:objectName(), card:objectName()) --%src,%dest,%arg
									if not room:askForCard(source, ".|.|.|hand", prompt, data, sgs.Card_MethodDiscard) then
										room:setCardFlag(card, "PlusTaohui")
										p:addMark("PlusTaohui")
									else
										local msg = sgs.LogMessage()
										msg.type = "#PlusTaohui_Discard"
										msg.from = source
										msg.to:append(p)
										msg.arg = self:objectName()
										msg.arg2 = card:objectName()
										room:sendLog(msg)
									end
									room:setPlayerMark(p, self:objectName() .. "-Clear", 0)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:hasFlag("PlusTaohui") then
				if player:getMark("PlusTaohui") > 0 then
					local count = player:getMark("PlusTaohui") - 1
					player:setMark("PlusTaohui", count)
					if count == 0 then
						room:setCardFlag(card, "-PlusTaohui")
					end
					local msg = sgs.LogMessage()
					msg.type = "#SkillNullify"
					msg.from = player
					msg.arg = self:objectName()
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		end
	end,
}
SiMaYi_Plus:addSkill(PlusTaohui)

----------------------------------------------------------------------------------------------------

--[[ WEI 003 郭嘉
	武将：GuoJia_Plus
	武将名：郭嘉
	称号：早终的先知
	国籍：魏
	体力上限：3
	武将技能：
		天妒(PlusTiandu)：在你的判定牌或拼点牌生效后，你可以获得此牌。
		遗计(PlusYiji)：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张放置在合理的位置，然后将另一张放置在合理的位置。
	技能设计：玉面
	状态：验证失败（遗计出现BUG）
]]
--

GuoJia_Plus = sgs.General(extension, "GuoJia_Plus", "wei", 3, true)

--[[
	技能：PlusTiandu
	技能名：天妒
	描述：在你的判定牌或拼点牌生效后，你可以获得此牌。
	状态：验证通过
	注：若☆SP张飞与郭嘉拼点赢，☆SP张飞会从郭嘉的手牌中收回拼点牌。（大概要加一个BeforeCardsMove的时机）
]]
--
PlusTiandu = sgs.CreateTriggerSkill {
	name = "PlusTiandu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.FinishJudge, sgs.Pindian },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.FinishJudge then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local judge = data:toJudge()
				local card = judge.card
				local card_data = sgs.QVariant()
				card_data:setValue(card)
				if room:askForSkillInvoke(player, self:objectName(), card_data) then
					room:broadcastSkillInvoke(self:objectName())
					player:obtainCard(card)
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			local guojia = room:findPlayerBySkillName(self:objectName())
			local source = pindian.from
			local target = pindian.to
			if guojia and source:objectName() == guojia:objectName() then
				local id = pindian.from_card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					local card_data = sgs.QVariant()
					card_data:setValue(pindian.from_card)
					if room:askForSkillInvoke(guojia, self:objectName(), card_data) then
						room:broadcastSkillInvoke(self:objectName())
						guojia:obtainCard(pindian.from_card)
					end
				end
			elseif guojia and target:objectName() == guojia:objectName() then
				local id = pindian.to_card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					local card_data = sgs.QVariant()
					card_data:setValue(pindian.to_card)
					if room:askForSkillInvoke(guojia, self:objectName(), card_data) then
						room:broadcastSkillInvoke(self:objectName())
						guojia:obtainCard(pindian.to_card)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
GuoJia_Plus:addSkill(PlusTiandu)

--[[
	技能：PlusYiji
	技能名：遗计
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张放置在合理的位置，然后将另一张放置在合理的位置。
	状态：验证通过
	BUG：放在牌堆顶的牌会被展示。
	注：为了方便操作，可以选择2张牌交给一名角色或者弃置，但是是一张张结算的，即实际相当于2次操作（暂不支持2张牌一起放到牌堆顶，会出现BUG）；
		若郭嘉将闪电放置于其他角色的判定区内，会显示“闪电由郭嘉移动到XXX”；
		个别时候遗计按钮会弹起；
		个别时候，郭嘉遗计置于牌堆顶之后，屏幕中央会有异常显示的牌，不会消失。
]]
--
PlusYiji_DummyCard = sgs.CreateSkillCard {
	name = "PlusYiji_DummyCard",
}
PlusYiji_Card = sgs.CreateSkillCard {
	name = "PlusYiji_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		local subcards = self:getSubcards()
		local cards = sgs.CardList()
		for _, card_id in sgs.qlist(subcards) do
			room:setCardFlag(card_id, "-PlusYiji")
			cards:append(sgs.Sanguosha:getCard(card_id))
		end
		local target = targets[1]
		local placeStr = {}
		local card = cards:first()
		if #targets ~= 0 then
			table.insert(placeStr, "PlusYiji_hand")
		end
		if cards:length() == 1 and #targets ~= 0 then                                                                                                                                                                                                                  --选择1张
			if card:isKindOf("EquipCard") then
				if (card:isKindOf("Weapon") and not target:getWeapon()) or (card:isKindOf("Armor") and not target:getArmor()) or (card:isKindOf("DefensiveHorse") and not target:getDefensiveHorse()) or (card:isKindOf("OffensiveHorse") and not target:getOffensiveHorse()) then --判断目标是否已经有此类装备（即是否替换）
					table.insert(placeStr, "PlusYiji_equip")
				end
			end
			if card:isKindOf("TrickCard") and not card:isNDTrick() then
				if not target:containsTrick(card:objectName()) then
					table.insert(placeStr, "PlusYiji_delayedTrick")
				end
			end
		end
		if #targets == 0 then
			if cards:length() == 1 then
				table.insert(placeStr, "PlusYiji_drawPile")
			end
			table.insert(placeStr, "PlusYiji_discardPile")
		end
		local dest = sgs.QVariant()
		dest:setValue(target)
		local place = room:askForChoice(source, "PlusYiji", table.concat(placeStr, "+"), dest) --以上代码为处理选择窗口
		if place == "PlusYiji_hand" then                                                 --手牌区
			for _, card in sgs.qlist(cards) do
				room:obtainCard(target, card, false)
			end
		elseif place == "PlusYiji_equip" then --装备区
			local card = cards:first()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, "", "PlusYiji", "")
			local msg = sgs.LogMessage()
			msg.type = "$PlusYiji_Equip"
			msg.from = source
			msg.to:append(target)
			msg.card_str = card:toString()
			room:sendLog(msg)
			room:moveCardTo(card, nil, target, sgs.Player_PlaceEquip, reason)
		elseif place == "PlusYiji_delayedTrick" then --判定区
			local card = cards:first()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, "", "PlusYiji", "")
			local msg = sgs.LogMessage()
			msg.type = "$PlusYiji_DelayedTrick"
			msg.from = source
			msg.to:append(target)
			msg.card_str = card:toString()
			room:sendLog(msg)
			room:moveCardTo(card, nil, target, sgs.Player_PlaceDelayedTrick, reason)
		elseif place == "PlusYiji_discardPile" then --弃牌堆
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "PlusYiji", "")
			for _, card in sgs.qlist(cards) do
				room:throwCard(card, reason, nil)
			end
		elseif place == "PlusYiji_drawPile" then --牌堆顶
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, "", "", "PlusYiji", "")
			room:setCardFlag(card, "-PlusYiji")
			room:moveCardTo(card, source, nil, sgs.Player_DrawPile,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "PlusYiji", ""), true)
		end
	end,
}
PlusYijiVS = sgs.CreateViewAsSkill {
	name = "PlusYiji",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:hasFlag("PlusYiji")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = PlusYiji_Card:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusYiji"
	end
}
PlusYiji = sgs.CreateTriggerSkill {
	name = "PlusYiji",
	events = { sgs.Damaged },
	view_as_skill = PlusYijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		for i = 0, x - 1, 1 do
			if room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				--local move = sgs.CardsMoveStruct()
				--local cardA = room:drawCard()  --id
				--move.card_ids:append(cardA)
				--room:setCardFlag(cardA, "PlusYiji")
				--local cardB = room:drawCard()
				--move.card_ids:append(cardB)
				--room:setCardFlag(cardB, "PlusYiji")
				--move.to = player
				--move.to_place = sgs.Player_PlaceHand
				--move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), self:objectName(), nil)
				--move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil)
				--room:moveCards(move, false)
				local _guojia = sgs.SPlayerList()
				_guojia:append(player)
				local yiji_cards = room:getNCards(2, false)
				for _, id in sgs.qlist(yiji_cards) do
					room:setCardFlag(id, "PlusYiji")
				end
				local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				local origin_yiji = sgs.IntList()
				for _, id in sgs.qlist(yiji_cards) do
					origin_yiji:append(id)
				end

				local tag = room:getTag("PlusYiji")
				local guanxuToGet = tag:toString()
				if guanxuToGet == nil then
					guanxuToGet = ""
				end
				for _, card_id in sgs.qlist(yiji_cards) do
					if guanxuToGet == "" then
						guanxuToGet = tostring(card_id)
					else
						guanxuToGet = guanxuToGet .. "+" .. tostring(card_id)
					end
				end
				room:setTag("PlusYiji", sgs.QVariant(guanxuToGet))
				if not move.card_ids:isEmpty() then
					while room:askForUseCard(player, "@PlusYiji", string.format("#PlusYiji:::%d", move.card_ids:length())) do
						local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand,
							sgs.Player_PlaceTable,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(),
								self:objectName(), nil))
						for _, id in sgs.qlist(origin_yiji) do
							if not sgs.Sanguosha:getCard(id):hasFlag("PlusYiji") then
								move.card_ids:append(id)
								yiji_cards:removeOne(id)
							end
						end
						origin_yiji = sgs.IntList()
						for _, id in sgs.qlist(yiji_cards) do
							origin_yiji:append(id)
						end
						room:setTag("PlusYiji", sgs.QVariant())
						local tag = room:getTag("PlusYiji")
						local guanxuToGet = tag:toString()
						if guanxuToGet == nil then
							guanxuToGet = ""
						end
						for _, card_id in sgs.qlist(yiji_cards) do
							if guanxuToGet == "" then
								guanxuToGet = tostring(card_id)
							else
								guanxuToGet = guanxuToGet .. "+" .. tostring(card_id)
							end
						end
						room:setTag("PlusYiji", sgs.QVariant(guanxuToGet))
						local moves = sgs.CardsMoveList()
						moves:append(move)
						room:notifyMoveCards(true, moves, false, _guojia)
						room:notifyMoveCards(false, moves, false, _guojia)
						if not player:isAlive() then return end
						if origin_yiji:isEmpty() then break end
					end
					if not yiji_cards:isEmpty() then
						local move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand,
							sgs.Player_PlaceTable,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(),
								self:objectName(), nil))
						local moves = sgs.CardsMoveList()
						moves:append(move)
						room:notifyMoveCards(true, moves, false, _guojia)
						room:notifyMoveCards(false, moves, false, _guojia)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in sgs.qlist(yiji_cards) do
							dummy:addSubcard(id)
							room:setCardFlag(id, "-PlusYiji")
						end
						dummy:deleteLater()
						player:obtainCard(dummy, false)
					end
					room:setTag("PlusYiji", sgs.QVariant())
				end
			end
		end
	end
}
GuoJia_Plus:addSkill(PlusYiji)

----------------------------------------------------------------------------------------------------

--[[ WEI 004 夏侯惇
	武将：XiaHouDun_Plus
	武将名：夏侯惇
	称号：独目的苍狼
	国籍：魏
	体力上限：4
	武将技能：
		刚烈(PlusGanglie)：当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标时，你可以失去1点体力，然后选择一项：
		1.令此牌对你无效，然后你获得此牌。
		2.令该角色也成为此牌的目标，然后你摸一张牌。
	技能设计：吹风奈奈
	状态：验证通过
]]
--

XiaHouDun_Plus = sgs.General(extension, "XiaHouDun_Plus", "wei", 4, true)

--[[
	技能：PlusGanglie
	技能名：刚烈
	描述：当你成为一名其他角色使用的【杀】或非延时类锦囊牌的目标时，你可以失去1点体力，然后选择一项：
		1.令此牌对你无效，然后你获得此牌。
		2.令该角色也成为此牌的目标，然后你摸一张牌。
	状态：验证通过
	小BUG：由于五谷丰登的BUG，目前技能修改为若此牌为五谷丰登，发动刚烈①后在结算至夏侯惇时获得它；
	注：若此牌为借刀杀人，刚烈2会出现BUG；
		大乔对夏侯惇使用杀，夏侯惇令大乔成为目标，大乔无法发动流离。
]]
--
function targetsTable2QList(thetable)
	local theqlist = sgs.PlayerList()
	for _, p in ipairs(thetable) do
		theqlist:append(p)
	end
	return theqlist
end

LuaExtraCollateralCard = sgs.CreateSkillCard {
	name = "LuaExtraCollateralCard",
	filter = function(self, targets, to_select)
		local coll = sgs.Card_Parse(sgs.Self:property("extra_collateral"):toString())
		if (not coll) then return false end
		local tos = sgs.Self:property("extra_collateral_current_targets"):toString():split("+")
		if (#targets == 0) then
			return (not table.contains(tos, to_select:objectName()))
				and (not sgs.Self:isProhibited(to_select, coll)) and
				coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
		else
			return coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
		end
	end,
	about_to_use = function(self, room, cardUse)
		local killer = cardUse.to:first()
		local victim = cardUse.to:last()
		killer:setFlags("ExtraCollateralTarget")
		local _data = sgs.QVariant()
		_data:setValue(victim)
		killer:setTag("collateralVictim", _data)
	end
}
PlusGanglieVS = sgs.CreateZeroCardViewAsSkill {
	name = "PlusGanglie",
	response_pattern = "@@PlusGanglie",
	view_as = function()
		return LuaExtraCollateralCard:clone()
	end
}
PlusGanglie = sgs.CreateTriggerSkill {
	name = "PlusGanglie",
	events = { sgs.TargetConfirming, sgs.CardEffected },
	view_as_skill = PlusGanglieVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or use.card:isNDTrick() then
				if use.from:objectName() ~= player:objectName() then
					if use.to:contains(player) then
						local canadd = false
						local from = use.from
						if from:isAlive() then
							if not use.to:contains(from) then
								if not room:isProhibited(from, from, use.card) then
									canadd = true
								end
							end
						end
						local choice = ""
						if canadd then
							choice = room:askForChoice(player, self:objectName(),
								"PlusGanglie_choice1+PlusGanglie_choice2+PlusGanglie_cancel", data)
						else
							choice = room:askForChoice(player, self:objectName(),
								"PlusGanglie_choice1+PlusGanglie_cancel", data)
						end
						local msg = sgs.LogMessage()
						if choice == "PlusGanglie_choice1" then
							room:broadcastSkillInvoke(self:objectName())
							msg.type = "#PlusGanglie1"
							msg.from = player
							msg.arg = self:objectName()
							room:sendLog(msg)
							room:loseHp(player)
							if player:isAlive() then
								local card = use.card
								if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable and not card:isKindOf("AmazingGrace") then --五谷丰登的BUG
									player:obtainCard(card)
								end
								room:setCardFlag(card, "PlusGanglie")
								player:addMark("PlusGanglie")
							end
						elseif choice == "PlusGanglie_choice2" then
							room:broadcastSkillInvoke(self:objectName())
							if not use.card:isKindOf("Collateral") then
								msg.type = "#PlusGanglie2"
								msg.from = player
								msg.to:append(from)
								msg.arg = self:objectName()
								msg.arg2 = use.card:objectName()
								room:sendLog(msg)
								room:loseHp(player)
								if player:isAlive() then
									local new_targets = sgs.SPlayerList()
									new_targets:append(from)
									for _, t in sgs.qlist(use.to) do
										new_targets:append(t)
									end
									room:sortByActionOrder(new_targets)
									room:getThread():trigger(sgs.TargetConfirming, room, from, data)
									use.to = new_targets
									data:setValue(use)
									room:drawCards(player, 1, self:objectName())
								end
							else
								for _, p in sgs.qlist(room:getAlivePlayers()) do
									if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
									if use.card:targetFilter(sgs.PlayerList(), p, player) then
										targets:append(p)
									end
								end
								if (targets:isEmpty()) then return false end
								local tos = {}
								for _, t in sgs.qlist(use.to) do
									table.insert(tos, t:objectName())
								end
								room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
								room:setPlayerProperty(player, "extra_collateral_current_targets",
									sgs.QVariant(table.concat(tos, "+")))
								local used = room:askForUseCard(player, "@@PlusGanglie", "@qiaoshui-add:::collateral")
								room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(""))
								room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant("+"))
								if not used then return false end
								for _, p in sgs.qlist(room:getOtherPlayers(player)) do
									if p:hasFlag("ExtraCollateralTarget") then
										p:setFlags("-ExtraColllateralTarget")
										extra = p
										break
									end
								end
								use.to:append(extra)
								room:sortByActionOrder(use.to)
								data:setValue(use)
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:hasFlag("PlusGanglie") then
				if player:getMark("PlusGanglie") > 0 then
					local count = player:getMark("PlusGanglie") - 1
					player:setMark("PlusGanglie", count)
					if count == 0 then
						room:setCardFlag(card, "-PlusGanglie")
					end
					local msg = sgs.LogMessage()
					msg.type = "#SkillNullify"
					msg.from = player
					msg.arg = self:objectName()
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					if card:isKindOf("AmazingGrace") then
						player:obtainCard(card)
					end
					return true
				end
			end
			return false
		end
	end,
}
XiaHouDun_Plus:addSkill(PlusGanglie)

----------------------------------------------------------------------------------------------------

--[[ WEI 005 张辽
	武将：ZhangLiao_Plus
	武将名：张辽
	称号：古之召虎
	国籍：魏
	体力上限：4
	武将技能：
		突袭(PlusTuxi)：摸牌阶段摸牌时，你可以少摸X张牌，然后获得X名其他角色的各一张手牌。
	技能设计：小A
	状态：验证通过
]]
--

----------------------------------------------------------------------------------------------------

--[[ WEI 006 许褚
	武将：XuChu_Plus
	武将名：许褚
	称号：虎痴
	国籍：魏
	体力上限：4
	武将技能：
		裸衣(PlusLuoyi)：你可以跳过你的摸牌阶段，然后获得以下技能直到回合结束：你可以将装备区里的一张牌当【决斗】或【杀】使用或打出；若你的装备区里没有牌，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1。
		虎卫(PlusHuwei)：当你需要使用或打出一张【闪】时，你可以失去1点体力，视为你使用或打出了一张【闪】。
	技能设计：吹风奈奈
	状态：验证通过
]]
--

XuChu_Plus = sgs.General(extension, "XuChu_Plus", "wei", 4, true)

--[[
	技能：PlusLuoyi
	附加技能：PlusLuoyi_Buff, PlusLuoyi_Clear
	技能名：裸衣
	描述：你可以跳过你的摸牌阶段，然后获得以下技能直到回合结束：你可以将装备区里的一张牌当【决斗】或【杀】使用或打出；若你的装备区里没有牌，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1。
	状态：验证通过
]]
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local patterns = { "slash", "duel" }
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end

local pos = 0
PlusLuoyi_select = sgs.CreateSkillCard {
	name = "PlusLuoyi_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local pattern = {}
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			card:deleteLater()
			if card then
				if card:isAvailable(source) then
					table.insert(pattern, cd)
				end
			end
		end
		table.insert(pattern, "cancel")
		local pattern = room:askForChoice(source, "PlusLuoyi", table.concat(pattern, "+"))
		if pattern then
			pos = getPos(patterns, pattern)
			room:setPlayerMark(source, "PlusLuoyiPos", pos)
			local prompt = string.format("@@PlusLuoyi:%s", pattern)
			room:askForUseCard(source, "@PlusLuoyi", prompt)
		end
	end,
}

PlusLuoyiCard = sgs.CreateSkillCard {
	name = "PlusLuoyi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@PlusLuoyi" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("PlusLuoyi")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and
				not sgs.Self:isProhibited(to_select, card, qtargets)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local pattern = patterns[player:getMark("PlusLuoyiPos")]
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("PlusLuoyi")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@PlusLuoyi" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local pattern = patterns[player:getMark("PlusLuoyiPos")]
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@PlusLuoyi" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("PlusLuoyi")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local pattern = patterns[sgs.Self:getMark("PlusLuoyiPos")]
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("PlusLuoyi")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()
		local to_guhuo = self:getUserString()
		local subcards = self:getSubcards()
		local card = sgs.Sanguosha:getCard(subcards:first())
		local user_str = to_guhuo
		local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
		use_card:setSkillName("PlusLuoyi")
		use_card:addSubcard(card)
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		local to_guhuo
		to_guhuo = self:getUserString()
		local subcards = self:getSubcards()
		local card = sgs.Sanguosha:getCard(subcards:first())
		local user_str = to_guhuo
		local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
		use_card:setSkillName("PlusLuoyi")
		use_card:addSubcard(subcards:first())
		use_card:deleteLater()
		return use_card
	end
}

PlusLuoyiVS = sgs.CreateViewAsSkill {
	name = "PlusLuoyi",
	n = 1,
	enabled_at_response = function(self, player, pattern)
		if player:hasFlag("PlusLuoyi") then
			if pattern == "@PlusLuoyi" then
				return player:hasEquip()
			end
			return (pattern == "slash")
		end
	end,
	view_filter = function(self, selected, to_select)
		return to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@PlusLuoyi" then
				local pattern = patterns[sgs.Self:getMark("PlusLuoyiPos")]
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
				if c and #cards == 1 then
					c:deleteLater()
					local card = PlusLuoyiCard:clone()
					card:setUserString(c:objectName())
					card:addSubcard(cards[1])
					return card
				else
					return nil
				end
			elseif #cards == 1 then
				local card = PlusLuoyiCard:clone()
				card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				card:addSubcard(cards[1])
				return card
			else
				return nil
			end
		else
			local cd = PlusLuoyi_select:clone()
			return cd
		end
	end,
	enabled_at_play = function(self, player)
		if player:hasFlag("PlusLuoyi") and player:hasEquip() then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			return (sgs.Slash_IsAvailable(player) or duel:isAvailable(player))
		end
	end,
}
PlusLuoyi_Buff = sgs.CreateTriggerSkill { --伤害+1
	name = "#PlusLuoyi_Buff",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
				local msg = sgs.LogMessage()
				msg.type = "#PlusLuoyi_Buff"
				msg.from = player
				--msg.to:append(damage.to)
				msg.arg = damage.damage
				msg.arg2 = damage.damage + 1
				room:sendLog(msg)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target and target:hasSkill(self:objectName()) then
			if target:hasFlag("PlusLuoyi") then
				if not target:hasEquip() then
					return target:isAlive()
				end
			end
		end
		return false
	end
}
PlusLuoyi = sgs.CreateTriggerSkill {
	name = "PlusLuoyi",
	events = { sgs.EventPhaseChanging },
	view_as_skill = PlusLuoyiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Draw then
				if not player:isSkipped(sgs.Player_Draw) then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:skip(sgs.Player_Draw)
						room:setPlayerFlag(player, "PlusLuoyi")
						room:addPlayerMark(player, "&" .. self:objectName() .. "-Clear")
					end
				end
			end
		end
		return false
	end
}
PlusLuoyi_Clear = sgs.CreateTriggerSkill {
	name = "#PlusLuoyi_Clear",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if data:toString() == "PlusLuoyi" then
			room:setPlayerFlag(player, "-PlusLuoyi")
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasFlag("PlusLuoyi")
		end
		return false
	end
}
XuChu_Plus:addSkill(PlusLuoyi)
XuChu_Plus:addSkill(PlusLuoyi_Buff)
XuChu_Plus:addSkill(PlusLuoyi_Clear)
extension:insertRelatedSkills("PlusLuoyi", "#PlusLuoyi_Buff")
extension:insertRelatedSkills("PlusLuoyi", "#PlusLuoyi_Clear")
--[[
	第四版的裸衣虽然较容易操作，但是太麻烦并且可能存在BUG。
	第五版的裸衣，简化了第四版的结算，但是操作略有点麻烦，游戏体验感欠佳。
	0514更新的裸衣增加了少量代码，解决了游戏体验感的问题。
	
	与第四版不同，PlusLuoyi_VS是这个技能中视为部分的核心。此技能主要根据数组中提供的数据来决定提供哪一种类型的卡牌。
	最简单的情况是许褚在响应时使用或打出【杀】，此时在enabled_at_response部分记下当前的状态为响应，之后直接视为一张杀结束。
	对于在出牌阶段选择使用哪一种牌的情况，第一次发动时暂时不提供卡牌，只视为使用一个技能卡。
	这个技能卡PlusLuoyi_Card令玩家选择使用杀还是使用决斗，然后将结果保存在数组里。					（以下为0514的内容）
	注意：如果将此时的pattern直接要求打出，那么就可以直接点击按钮将装备区里的牌打出了。但是这样太麻烦。
	为了能够自动发动视为技，我们需要再回到触发技中。
	于是在技能卡中只要求打出一张虚拟的卡牌，以此触发PlusLuoyi中的CardAsked时机。
	在此时机中真正要求玩家使用装备区的牌。此处视为技可以直接被加载并发动，因此直接使用askForUseCard要求使用。
	回到PlusLuoyi_VS，在enabled_at_response中识别pattern，发动视为技。
	由于需要使用的牌已经被记录在全局数组sgs.PlusLuoyi_Pattern[1]中，可以直接读取在技能卡中选择的卡牌并真正将其使用。
	再回来看触发技，此时卡牌使用结算完毕，但是依然在CardAsked时机。我们生成一张虚拟的卡牌并返回，使得技能卡的结算结束。
	整个发动过程的流程：点击按钮 -> PlusLuoyi_VS（生成技能卡）-> PlusLuoyi_Card（选择需要使用的卡牌）
								 -> PlusLuoyi（令玩家使用需要的卡牌）-> PlusLuoyi_VS（选择装备区里的卡牌）-> 使用卡牌。
]]

--[[
	技能：PlusHuwei
	技能名：虎卫
	描述：当你需要使用或打出一张【闪】时，你可以失去1点体力，视为你使用或打出了一张【闪】。
	状态：验证通过
]]
--
PlusHuwei = sgs.CreateTriggerSkill {
	name = "PlusHuwei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardAsked },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		if pattern == "jink" then
			if player:getHp() > 1 and room:askForSkillInvoke(player, self:objectName()) then
				room:loseHp(player, 1)
				if player:isAlive() then
					local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
					jink:setSkillName(self:objectName())
					jink:deleteLater()
					room:provide(jink)
					return true
				end
			end
		end
	end
}
XuChu_Plus:addSkill(PlusHuwei)


----------------------------------------------------------------------------------------------------

--[[ WEI 008 夏侯渊
	武将：XiaHouYuan_Plus
	武将名：夏侯渊
	称号：疾行的猎豹
	国籍：魏
	体力上限：4
	武将技能：
		神速(PlusShensu)：你可以选择一至两项：
		1.弃置一张装备牌并跳过你的判定阶段。
		2.弃置一张红色手牌并跳过你的出牌阶段。
		你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

XiaHouYuan_Plus = sgs.General(extension, "XiaHouYuan_Plus", "wei", 4, true)

--[[
	技能：PlusShensu
	技能名：神速
	描述：你可以选择一至两项：
		1.弃置一张装备牌并跳过你的判定阶段。
		2.弃置一张红色手牌并跳过你的出牌阶段。
		你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	状态：验证通过
]]
--
sgs.PlusShensu_Pattern = "pattern"
PlusShensu_Card = sgs.CreateSkillCard {
	name = "PlusShensu_Card",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("PlusShensu")
		local extra = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, slash) + 1
		return sgs.Self:canSlash(to_select, slash, false) and #targets < extra
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("PlusShensu")
		slash:deleteLater()
		local dests = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			dests:append(p)
		end
		local use = sgs.CardUseStruct()
		use.card = slash
		use.to = dests
		use.from = source
		room:useCard(use, true)
	end,
}
PlusShensu_VS = sgs.CreateViewAsSkill {
	name = "PlusShensu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.PlusShensu_Pattern == "@PlusShensu1" then
			return #selected == 0 and to_select:isKindOf("EquipCard")
		else
			return #selected == 0 and to_select:isRed() and not to_select:isEquipped()
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusShensu_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		sgs.PlusShensu_Pattern = pattern
		return pattern == "@PlusShensu1" or pattern == "@PlusShensu2"
	end,
}
PlusShensu = sgs.CreateTriggerSkill {
	name = "PlusShensu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	view_as_skill = PlusShensu_VS,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
		if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) then
			if room:askForUseCard(player, "@PlusShensu1", "@PlusShensu1", 1, sgs.Card_MethodDiscard) then
				room:broadcastSkillInvoke(self:objectName())
				player:skip(sgs.Player_Judge)
			end
		elseif change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
			if room:askForUseCard(player, "@PlusShensu2", "@PlusShensu2", 2, sgs.Card_MethodDiscard) then
				room:broadcastSkillInvoke(self:objectName())
				player:skip(sgs.Player_Play)
			end
		end
		return false
	end,
}
XiaHouYuan_Plus:addSkill(PlusShensu)

----------------------------------------------------------------------------------------------------

--[[ WEI 009 曹仁
	武将：CaoRen_Plus
	武将名：曹仁
	称号：险不辞难
	国籍：魏
	体力上限：4
	武将技能：
		据守(PlusJushou)：回合结束阶段开始时，你可以摸2+X张牌（X为存活角色的数量），保留等同于你体力上限值的手牌，将其余的手牌置于你的武将牌上，称为“守”，然后将你的武将牌翻面。当你的武将牌上有“守”时，其他角色计算与你的距离+1。
		溃围(PlusKuiwei)：锁定技，其他角色的回合结束阶段开始时，若你的武将牌背面朝上，你须将一张“守”置入弃牌堆。回合开始阶段开始时，你获得你的武将牌上的所有“守”。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

CaoRen_Plus = sgs.General(extension, "CaoRen_Plus", "wei", 4, true)

--[[
	技能：PlusJushou
	附加技能：PlusJushou_Dist
	技能名：据守
	描述：回合结束阶段开始时，你可以摸2+X张牌（X为存活角色的数量），保留等同于你体力上限值的手牌，将其余的手牌置于你的武将牌上，称为“守”，然后将你的武将牌翻面。当你的武将牌上有“守”时，其他角色计算与你的距离+1。
	状态：验证通过
]]
--
PlusJushou = sgs.CreateTriggerSkill {
	name = "PlusJushou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			local room = player:getRoom()
			local num = 2
			local players = room:getAlivePlayers()
			for _, p in sgs.qlist(players) do
				num = num + 1
			end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, num, self:objectName())
				local hand = player:getHandcardNum()
				local maxHp = player:getMaxHp()
				local a = hand - maxHp
				if a > 0 then
					local cards = room:askForExchange(player, self:objectName(), a, a, false, "QuanjiPush")
					local card_ids = cards:getSubcards()
					player:addToPile("defense", card_ids)
				end
				player:turnOver()
			end
		end
	end
}
PlusJushou_Dist = sgs.CreateDistanceSkill {
	name = "#PlusJushou_Dist",
	correct_func = function(self, from, to)
		if to:hasSkill("PlusJushou") and from:objectName() ~= to:objectName() then
			local defense = to:getPile("defense")
			local count = defense:length()
			if count > 0 then
				return 1
			end
		end
	end
}
CaoRen_Plus:addSkill(PlusJushou)
CaoRen_Plus:addSkill(PlusJushou_Dist)
extension:insertRelatedSkills("PlusJushou", "#PlusJushou_Dist")

--[[
	技能：PlusKuiwei
	技能名：溃围
	描述：锁定技，其他角色的回合结束阶段开始时，若你的武将牌背面朝上，你须将一张“守”置入弃牌堆。回合开始阶段开始时，你获得你的武将牌上的所有“守”。
	状态：验证通过
]]
--
PlusKuiwei = sgs.CreateTriggerSkill {
	name = "PlusKuiwei",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local caorens = room:findPlayersBySkillName(self:objectName())
		for _, caoren in sgs.qlist(caorens) do
			if player:getPhase() == sgs.Player_Finish and caoren:objectName() ~= player:objectName() then
				if not caoren:faceUp() then
					local defense = caoren:getPile("defense")
					if defense:length() > 0 then
						local msg = sgs.LogMessage()
						msg.type = "#TriggerSkill"
						msg.from = caoren
						msg.arg = self:objectName()
						room:sendLog(msg)
						room:broadcastSkillInvoke(self:objectName())
						room:fillAG(defense, caoren)
						local card_id = room:askForAG(caoren, defense, false, self:objectName())
						--local card = sgs.Sanguosha:getCard(card_id)
						--room:throwCard(card, nil, nil)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "PlusKuiwei",
							"");
						room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
						room:clearAG()
					end
				end
			elseif player:getPhase() == sgs.Player_Start and caoren:objectName() == player:objectName() then
				local defense = caoren:getPile("defense")
				if defense:length() > 0 then
					local defense_str = {}
					for _, card_id in sgs.qlist(defense) do
						table.insert(defense_str, sgs.Sanguosha:getCard(card_id):toString())
					end
					local msg = sgs.LogMessage()
					msg.type = "$PlusKuiwei_Get"
					msg.from = caoren
					msg.card_str = table.concat(defense_str, "+")
					room:sendLog(msg)
					room:broadcastSkillInvoke(self:objectName())
				end
				--[[for _,card_id in sgs.qlist(defense) do
					room:obtainCard(caoren, card_id)
				end		]]
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(caoren:getPile("defense"))
				dummy:deleteLater()
				room:obtainCard(player, dummy)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
CaoRen_Plus:addSkill(PlusKuiwei)

----------------------------------------------------------------------------------------------------

--[[ WEI 010 于禁
	武将：YuJin_Plus
	武将名：于禁
	称号：魏武之刚
	国籍：魏
	体力上限：4
	武将技能：
		毅重(PlusYizhong)：当距离2以内的一名角色成为黑色的【杀】的目标后，你可以弃置一张手牌令此【杀】对其无效，若你弃置的牌为非基本牌，你可以摸一张牌。
	技能设计：玉面
	状态：验证通过
]]
--

YuJin_Plus = sgs.General(extension, "YuJin_Plus", "wei", 4, true)

--[[
	技能：PlusYizhong
	技能名：毅重
	描述：当距离2以内的一名角色成为黑色的【杀】的目标后，你可以弃置一张手牌令此【杀】对其无效，若你弃置的牌为非基本牌，你可以摸一张牌。
	状态：验证通过
	注：若有与毅重发动时机相同的技能，并不是按照行动顺序发动，而是按照太阳神三国杀中的顺序发动。
]]
--
PlusYizhong_Card = sgs.CreateSkillCard {
	name = "PlusYizhong_Card",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if not card:isKindOf("BasicCard") then
			if room:askForSkillInvoke(source, "PlusYizhong") then
				room:drawCards(source, 1, "PlusYizhong")
			end
		end
	end,
}
PlusYizhongVS = sgs.CreateViewAsSkill {
	name = "PlusYizhong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusYizhong_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusYizhong"
	end,
}
PlusYizhong = sgs.CreateTriggerSkill {
	name = "PlusYizhong",
	events = { sgs.TargetConfirmed, sgs.CardEffected, sgs.CardFinished },
	view_as_skill = PlusYizhongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local yujins = room:findPlayersBySkillName(self:objectName())
			for _, yujin in sgs.qlist(yujins) do
				local use = data:toCardUse()
				for _, p in sgs.qlist(use.to) do
					if yujin:distanceTo(p) <= 2 and p:objectName() == player:objectName() then
						local slash = use.card
						if slash and slash:isKindOf("Slash") and slash:isBlack() then
							local prompt = string.format("@PlusYizhong:%s", p:objectName())
							room:addPlayerMark(p, self:objectName())
							room:setTag("CurrentUseStruct", data)
							if room:askForUseCard(yujin, "@PlusYizhong", prompt) then
								room:broadcastSkillInvoke(self:objectName())
								room:setCardFlag(slash, "PlusYizhong")
								p:addMark("PlusYizhong_Slash")
							end
							room:setPlayerMark(p, self:objectName(), 0)
							room:removeTag("CurrentUseStruct")
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card and card:isKindOf("Slash") and card:hasFlag("PlusYizhong") then
				if card:isKindOf("Slash") and player:getMark("PlusYizhong_Slash") > 0 then
					local count = player:getMark("PlusYizhong_Slash") - 1
					player:setMark("PlusYizhong_Slash", count)
					local msg = sgs.LogMessage()
					msg.type = "#SkillNullify"
					msg.from = player
					msg.arg = self:objectName()
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") and card:hasFlag("PlusYizhong") then
				for _, p in sgs.qlist(use.to) do
					p:removeMark("PlusYizhong_Slash")
				end
				room:setCardFlag(card, "-PlusYizhong")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
YuJin_Plus:addSkill(PlusYizhong)

----------------------------------------------------------------------------------------------------

--[[ WEI 011 杨修
	武将：YangXiu_Plus
	武将名：杨修
	称号：恃才放旷
	国籍：魏
	体力上限：3
	武将技能：
		鸡肋(PlusJilei): 每当你受到一次伤害时，你可以选择一种花色，然后令伤害来源展示其手牌，若其手牌有你所选择的花色，则该角色须弃置所有此花色的手牌，否则你弃一张牌。
		啖酪: 当一张锦囊牌指定包括你在内的多名目标后，你可以摸一张牌，若如此做，此锦囊牌对你无效。
	技能设计：小A
	状态：验证通过
]]
--

YangXiu_Plus = sgs.General(extension, "YangXiu_Plus", "wei", 3, true)

--[[
	技能：PlusJilei
	技能名：鸡肋
	描述：每当你受到一次伤害时，你可以选择一种花色，然后令伤害来源展示其手牌，若其手牌有你所选择的花色，则该角色须弃置所有此花色的手牌，否则你弃一张牌。
	状态：验证通过
]]
--
PlusJilei_DummyCard = sgs.CreateSkillCard {
	name = "PlusJilei_DummyCard",
}
PlusJilei = sgs.CreateTriggerSkill {
	name = "PlusJilei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		if source then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(source, self:objectName())
				local suit = room:askForSuit(player, self:objectName())
				room:setPlayerMark(source, self:objectName(), 0)
				local msg = sgs.LogMessage()
				msg.type = "#ChooseSuit"
				msg.from = player
				if suit == sgs.Card_Club then
					msg.arg = "club"
				elseif suit == sgs.Card_Spade then
					msg.arg = "spade"
				elseif suit == sgs.Card_Diamond then
					msg.arg = "diamond"
				elseif suit == sgs.Card_Heart then
					msg.arg = "heart"
				end
				room:sendLog(msg)
				room:getThread():delay()
				if not source:isKongcheng() then
					room:showAllCards(source)
				end
				local hand = source:getHandcards()
				local guess = sgs.CardList()
				for _, card in sgs.qlist(hand) do
					if card:getSuit() == suit then
						guess:append(card)
					end
				end
				if not guess:isEmpty() then
					local discard = PlusJilei_DummyCard:clone()
					for _, card in sgs.qlist(guess) do
						if not source:isJilei(card) then
							discard:addSubcard(card)
						end
					end
					room:throwCard(discard, source)
				else
					room:askForDiscard(player, self:objectName(), 1, 1, false, true)
				end
			end
		end
	end
}
YangXiu_Plus:addSkill(PlusJilei)

--[[
	技能：danlao
	技能名：啖酪
	描述：当一张锦囊牌指定包括你在内的多名目标后，你可以摸一张牌，若如此做，此锦囊牌对你无效。
	状态：原有技能
]]
--
YangXiu_Plus:addSkill("danlao")

----------------------------------------------------------------------------------------------------

--[[ WEI 012 李典
	武将：LiDian_Plus
	武将名：李典
	称号：长者之风
	国籍：魏
	体力上限：4
	武将技能：
		将才(PlusJiangcai)：你可以弃置一张基本牌并跳过你的出牌阶段和弃牌阶段，然后你可以依次获得至多三名其他角色的各一张手牌，再依次交给这些角色一张手牌。
	技能设计：玉面
	状态：验证通过
]]
--

LiDian_Plus = sgs.General(extension, "LiDian_Plus", "wei", 4, true)

--[[  注：关于Exchange的提示信息会在下次更新时修改
	技能：PlusJiangcai
	技能名：将才
	描述：你可以弃置一张基本牌并跳过你的出牌阶段和弃牌阶段，然后你可以依次获得至多三名其他角色的各一张手牌，再依次交给这些角色一张手牌。
	状态：验证通过
]]
--
PlusJiangcai_Card = sgs.CreateSkillCard {
	name = "PlusJiangcai_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if #targets < 3 then
			if to_select:objectName() ~= player:objectName() then
				return not to_select:isKongcheng()
			end
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets <= 3
	end,
	on_use = function(self, room, source, targets)
		local id
		local target
		--for i = 1, #targets, 1 do
		--	target = targets[i]
		for _, target in ipairs(targets) do
			if not target:isKongcheng() then
				id = room:askForCardChosen(source, target, "h", "PlusJiangcai")
				card = sgs.Sanguosha:getCard(id)
				room:moveCardTo(card, source, sgs.Player_PlaceHand, false)
			end
		end
		local card
		--for i = 1, #targets, 1 do
		--	target = targets[i]
		for _, target in ipairs(targets) do
			if not source:isKongcheng() and target:isAlive() then
				room:setPlayerMark(target, "PlusJiangcai", 1)
				card = room:askForExchange(source, "PlusJiangcai", 1, 1, false, "@PlusJiangcai_Exchange", false)
				if card then
					room:moveCardTo(card, target, sgs.Player_PlaceHand, false)
				end
				room:setPlayerMark(target, "PlusJiangcai", 0)
			end
		end
	end,
}
PlusJiangcaiVS = sgs.CreateViewAsSkill {
	name = "PlusJiangcai",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusJiangcai_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusJiangcai"
	end,
}
PlusJiangcai = sgs.CreateTriggerSkill {
	name = "PlusJiangcai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	view_as_skill = PlusJiangcaiVS,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
		if change.to == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) and not player:isSkipped(sgs.Player_Discard) then
				if room:askForUseCard(player, "@PlusJiangcai", "@PlusJiangcai") then
					player:skip(sgs.Player_Play)
					player:skip(sgs.Player_Discard)
				end
			end
		end
		return false
	end,
}
LiDian_Plus:addSkill(PlusJiangcai)

----------------------------------------------------------------------------------------------------

--[[ WEI 013 程昱
	武将：ChengYu_Plus
	武将名：程昱
	称号：世之奇才
	国籍：魏
	体力上限：3
	武将技能：
		远谋(PlusYuanmou)：每当你受到一次伤害后，你可以弃置一张手牌，然后你可以令一名角色获得对你造成伤害的牌。
		胆计(PlusDanji)：当其他角色使用【杀】或非延时类锦囊牌即将对你造成伤害时，若其手牌数大于你的手牌数，你可以令此伤害-1。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

ChengYu_Plus = sgs.General(extension, "ChengYu_Plus", "wei", 3, true)

--[[
	技能：PlusYuanmou
	技能名：远谋
	描述：每当你受到一次伤害后，你可以弃置一张手牌，然后你可以令一名角色获得对你造成伤害的牌。
	状态：验证通过
]]
--
PlusYuanmou_Card = sgs.CreateSkillCard {
	name = "PlusYuanmou_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	feasible = function(self, targets)
		return #targets <= 1
	end,
	on_use = function(self, room, source, targets)
		if #targets == 1 then
			local card_data = room:getTag("PlusYuanmou_Damage")
			local card = card_data:toCard()
			targets[1]:obtainCard(card)
		end
	end,
}
PlusYuanmouVS = sgs.CreateViewAsSkill {
	name = "PlusYuanmou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusYuanmou_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusYuanmou"
	end,
}
PlusYuanmou = sgs.CreateTriggerSkill {
	name = "PlusYuanmou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	view_as_skill = PlusYuanmouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			local id = card:getEffectiveId()
			if room:getCardPlace(id) == sgs.Player_PlaceTable then
				local card_data = sgs.QVariant()
				card_data:setValue(card)
				room:setTag("PlusYuanmou_Damage", card_data)
				room:askForUseCard(player, "@PlusYuanmou", "@PlusYuanmou")
			end
		end
	end
}
ChengYu_Plus:addSkill(PlusYuanmou)

--[[
	技能：PlusDanji
	技能名：胆计
	描述：当其他角色使用【杀】或非延时类锦囊牌即将对你造成伤害时，若其手牌数大于你的手牌数，你可以令此伤害-1。
	状态：验证通过
	注：若有与胆计发动时机相同的技能，并不是按照行动顺序发动，而是按照太阳神三国杀中的顺序发动。
]]
--
PlusDanji = sgs.CreateTriggerSkill {
	name = "PlusDanji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.DamageCaused, sgs.CardFinished, sgs.DamageComplete },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local source = damage.from
			local target = damage.to
			if damage.to:hasSkill(self:objectName()) and not damage.to:hasFlag("PlusDanji_Target") then --防止再次发动胆计
				if source and source:objectName() ~= target:objectName() then
					local card = damage.card
					if card and not card:hasFlag("PlusDanji_Own") then
						if card:isKindOf("Slash") or card:isNDTrick() then
							if source:getHandcardNum() > target:getHandcardNum() then
								if room:askForSkillInvoke(target, self:objectName(), data) then
									room:setPlayerFlag(target, "PlusDanji_Target")
									local msg = sgs.LogMessage()
									msg.type = "#PlusDanji_Decrease"
									msg.from = target
									msg.arg = damage.damage
									msg.arg2 = damage.damage - 1
									room:sendLog(msg)
									damage.damage = damage.damage - 1
									data:setValue(damage)
									room:setPlayerFlag(target, "-PlusDanji_Target")
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardUsed or event == sgs.CardFinished then --确保是其他角色使用的牌
			if player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				local card = use.card
				if card:isKindOf("Slash") or card:isNDTrick() then
					if event == sgs.CardUsed then
						room:setCardFlag(card, "PlusDanji_Own")
					else
						room:setCardFlag(card, "-PlusDanji_Own")
					end
				end
			end
		elseif event == sgs.DamageComplete then
			if player:hasFlag("PlusDanji_Target") then
				room:setPlayerFlag(player, "-PlusDanji_Target")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
ChengYu_Plus:addSkill(PlusDanji)


----------------------------------------------------------------------------------------------------
--                                             蜀
----------------------------------------------------------------------------------------------------


--[[ SHU ※ 治国诸葛亮
	武将：ZhiGuoZhuGeLiang_Plus
	武将名：诸葛亮
	称号：固国安邦
	国籍：蜀
	体力上限：3
	武将技能：
		治国(PlusZhiguo)：出牌阶段，你可以弃置一张手牌并选择X名角色（X为此牌的点数，且最多为存活角色数），然后选择一项：令这些角色各摸一张牌，或各弃一张牌。每阶段限一次。
		辅政(PlusFuzheng)：其他角色的摸牌阶段开始时，你可以弃置一张红色手牌令其摸牌时额外摸两张牌，然后你可以获得该角色此回合弃牌阶段所弃置的牌。
		平乱(PlusPingluan)：锁定技，【南蛮入侵】和【万箭齐发】对你无效。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

ZhiGuoZhuGeLiang_Plus = sgs.General(extension, "ZhiGuoZhuGeLiang_Plus", "shu", 3, true)

--[[
	技能：PlusZhiguo
	技能名：治国
	描述：出牌阶段，你可以弃置一张手牌并选择X名角色（X为此牌的点数，且最多为存活角色数），然后选择一项：令这些角色各摸一张牌，或各弃一张牌。每阶段限一次。
	状态：验证通过
	注：如果有令角色复活的技能，那么X最多只能为存活角色数-1，直到下一名角色死亡。
]]
--
PlusZhiguo_Card = sgs.CreateSkillCard {
	name = "PlusZhiguo_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local card_id = self:getSubcards():first()
		local number = sgs.Sanguosha:getCard(card_id):getNumber()
		return #targets < number
	end,
	feasible = function(self, targets)
		local card_id = self:getSubcards():first()
		local number = sgs.Sanguosha:getCard(card_id):getNumber()
		local players = sgs.Self:getAliveSiblings():length() + 1
		if number > players then
			number = players
		end
		return #targets == number
	end,
	on_use = function(self, room, source, targets)
		local choice = room:askForChoice(source, "PlusZhiguo", "PlusZhiguo_Draw+PlusZhiguo_Discard")
		for _, target in ipairs(targets) do
			if choice == "PlusZhiguo_Draw" then
				room:drawCards(target, 1, "PlusZhiguo")
			elseif choice == "PlusZhiguo_Discard" then
				room:askForDiscard(target, "PlusZhiguo", 1, 1, false, true)
			end
		end
	end,
}
PlusZhiguo = sgs.CreateViewAsSkill {
	name = "PlusZhiguo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusZhiguo_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#PlusZhiguo_Card")
		end
		return false
	end
}
--[[PlusZhiguo = sgs.CreateTriggerSkill{  --手动维护存活角色数
	name = "PlusZhiguo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.Death},
	view_as_skill = PlusZhiguoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:alivePlayerCount()
		local zhuge = room:findPlayerBySkillName(self:objectName())
		if zhuge then
			room:setPlayerMark(zhuge, "PlusZhiguo", players)
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}]]
ZhiGuoZhuGeLiang_Plus:addSkill(PlusZhiguo)

--[[
	技能：PlusFuzheng
	技能名：辅政
	描述：其他角色的摸牌阶段开始时，你可以弃置一张红色手牌令其摸牌时额外摸两张牌，然后你可以获得该角色此回合弃牌阶段所弃置的牌。
	状态：验证通过
]]
--
PlusFuzheng_Card = sgs.CreateSkillCard {
	name = "PlusFuzheng_Card",
	target_fixed = true,
}
PlusFuzhengVS = sgs.CreateViewAsSkill {
	name = "PlusFuzheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusFuzheng_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusFuzheng"
	end,
}
PlusFuzheng = sgs.CreateTriggerSkill {
	name = "PlusFuzheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards, sgs.CardsMoveOneTime },
	view_as_skill = PlusFuzhengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local zhuges = room:findPlayersBySkillName(self:objectName())
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			for _, zhuge in sgs.qlist(zhuges) do
				if zhuge and not zhuge:isKongcheng() then
					if room:askForUseCard(zhuge, "@PlusFuzheng", "#PlusFuzheng") then
						room:setPlayerFlag(player, "PlusFuzheng")
						room:setPlayerMark(zhuge, "PlusFuzheng-Clear", 1)
						room:addPlayerMark(zhuge, "&PlusFuzheng-Clear")
						draw.num = draw.num + 2
						data:setValue(draw)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime and player:getPhase() == sgs.Player_Discard then
			for _, zhuge in sgs.qlist(zhuges) do
				if player:hasFlag("PlusFuzheng") and zhuge:getMark("PlusFuzheng-Clear") > 0 then
					local move = data:toMoveOneTime()
					local source = move.from
					if source and source:objectName() == player:objectName() then
						if move.to_place == sgs.Player_DiscardPile then
							local reason = move.reason.m_reason
							if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
								local FuzhengMove = sgs.CardsMoveStruct()
								FuzhengMove.to = zhuge
								FuzhengMove.to_place = sgs.Player_PlaceHand
								local ids = sgs.QList2Table(move.card_ids)
								local places = move.from_places
								for i = 1, #ids, 1 do
									local id = ids[i]
									local place = places[i]
									if place ~= sgs.Player_PlaceDelayedTrick then
										if place ~= sgs.Player_PlaceSpecial then
											if room:getCardPlace(id) == sgs.Player_DiscardPile then
												FuzhengMove.card_ids:append(id)
											end
										end
									end
								end
								if not FuzhengMove.card_ids:isEmpty() then
									if room:askForSkillInvoke(zhuge, self:objectName(), data) then
										room:moveCardsAtomic(FuzhengMove, true)
									end
								end
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end,
	priority = 3,
}
ZhiGuoZhuGeLiang_Plus:addSkill(PlusFuzheng)

--[[
	技能：PlusPingluan
	技能名：平乱
	描述：锁定技，【南蛮入侵】和【万箭齐发】对你无效。
	状态：验证通过
]]
--
PlusPingluan = sgs.CreateTriggerSkill {
	name = "PlusPingluan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") or effect.card:isKindOf("ArcheryAttack") then
			local msg = sgs.LogMessage()
			msg.type = "#SkillNullify"
			msg.from = player
			msg.arg = self:objectName()
			msg.arg2 = effect.card:objectName()
			room:sendLog(msg)
			return true
		end
	end
}
ZhiGuoZhuGeLiang_Plus:addSkill(PlusPingluan)

----------------------------------------------------------------------------------------------------

--[[ SHU 001 刘备
	武将：LiuBei_Plus
	武将名：刘备
	称号：乱世的枭雄
	国籍：蜀
	体力上限：4
	武将技能：
		仁德(PlusRende)：出牌阶段，你可以将任意数量的手牌交给其他角色，若此阶段你给出的牌张数达到两张或更多，回合结束阶段开始时，你可以选择一项：
		1.你回复1点体力。
		2.令此回合你发动【仁德】指定的目标依次交给你一张牌。
		3.弃置一张红桃手牌，视为你使用一张【桃园结义】（此选项每局限一次）。
		激将：主公技，当你需要使用或打出一张【杀】时，你可令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	技能设计：玉面
	状态：验证通过
]]
--

LiuBei_Plus = sgs.General(extension, "LiuBei_Plus$", "shu", 4, true)

--[[
	技能：PlusRende
	技能名：仁德
	描述：出牌阶段，你可以将任意数量的手牌交给其他角色，若此阶段你给出的牌张数达到两张或更多，回合结束阶段开始时，你可以选择一项：
		1.你回复1点体力。
		2.令此回合你发动【仁德】指定的目标依次交给你一张牌。
		3.弃置一张红桃手牌，视为你使用一张【桃园结义】（此选项每局限一次）。
	状态：验证通过
]]
--
PlusRende_Card = sgs.CreateSkillCard {
	name = "PlusRende_Card",
	target_fixed = false,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local target
		if #targets == 0 then
			local list = room:getAlivePlayers()
			for _, player in sgs.qlist(list) do
				if player:objectName() ~= source:objectName() then
					target = player
					break
				end
			end
		else
			target = targets[1]
		end
		room:broadcastSkillInvoke("PlusRende")
		room:obtainCard(target, self, false)
		room:setPlayerFlag(target, "PlusRende_target")
		local subcards = self:getSubcards()
		local old_value = source:getMark("PlusRende")
		local new_value = old_value + subcards:length()
		room:setPlayerMark(source, "PlusRende", new_value)
		room:setPlayerMark(target, "&PlusRende+to+#" .. source:objectName() .. "-Clear", 1)
		if (new_value > 2) then
			room:setPlayerMark(source, "&PlusRende-Clear", 1)
		end
	end
}
PlusRendeVS = sgs.CreateViewAsSkill {
	name = "PlusRende",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local rende_card = PlusRende_Card:clone()
			for i = 1, #cards, 1 do
				local id = cards[i]:getId()
				rende_card:addSubcard(id)
			end
			return rende_card
		end
	end,
}
PlusRende = sgs.CreateTriggerSkill {
	name = "PlusRende",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.EventPhaseStart, sgs.EventAcquireSkill },
	view_as_skill = PlusRendeVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
			player:gainMark("@rende")
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player, "PlusRende", 0)
				return false
			elseif player:getPhase() == sgs.Player_Finish then
				local total = player:getMark("PlusRende")
				if total >= 2 then
					local choicelist = "PlusRende_cancel"
					if player:isWounded() then
						choicelist = string.format("%s+%s", choicelist, "PlusRende_choice1")
					end
					if player:getMark("@rende") > 0 then
						choicelist = string.format("%s+%s", choicelist, "PlusRende_choice3")
					end
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:hasFlag("PlusRende_target") and not p:isNude() then
							choicelist = string.format("%s+%s", choicelist, "PlusRende_choice2")
							break
						end
					end
					local choice = room:askForChoice(player, self:objectName(), choicelist)
					local msg = sgs.LogMessage()
					if choice == "PlusRende_choice1" then
						msg.type = "#PlusRende1"
						msg.from = player
						msg.arg = self:objectName()
						room:sendLog(msg)
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					elseif choice == "PlusRende_choice2" then
						msg.type = "#PlusRende2"
						msg.from = player
						msg.arg = self:objectName()
						room:sendLog(msg)
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:hasFlag("PlusRende_target") and not p:isNude() then
								local card = room:askForExchange(p, self:objectName(), 1, 1, true, "@PlusRende_Return",
									false)
								if card then
									room:moveCardTo(card, player, sgs.Player_PlaceHand)
								end
							end
						end
					elseif choice == "PlusRende_choice3" then
						if room:askForCard(player, ".|heart", "#PlusRende_Salvation", data, sgs.Card_MethodDiscard) then
							msg.type = "#PlusRende3"
							msg.from = player
							msg.arg = self:objectName()
							room:sendLog(msg)
							room:broadcastInvoke("animate", "lightbox:$PlusRende_Animation:3000")
							room:getThread():delay(4000)
							player:loseMark("@rende")
							local card = sgs.Sanguosha:cloneCard("god_salvation", sgs.Card_NoSuit, 0)
							card:deleteLater()
							card:setSkillName(self:objectName())
							local use = sgs.CardUseStruct()
							use.card = card
							use.from = player
							room:useCard(use)
						end
					end
				end
			end
		end
	end,
}
LiuBei_Plus:addSkill(PlusRende)

--[[
	技能：jijiang
	技能名：激将
	描述：主公技，当你需要使用或打出一张【杀】时，你可令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：原有技能
]]
--
LiuBei_Plus:addSkill("jijiang")

----------------------------------------------------------------------------------------------------

--[[ SHU 002 诸葛亮
	武将：ZhuGeLiang_Plus
	武将名：诸葛亮
	称号：迟暮的丞相
	国籍：蜀
	体力上限：3
	武将技能：
		观星(PlusGuanxing)：回合开始阶段或回合结束阶段开始时，你可以观看牌堆顶的X张牌（X为存活角色的数量且最多为5），将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。每回合限一次。
		空城(PlusKongcheng)：当你成为【杀】或【决斗】的目标时，你可以将所有手牌（至少0张）交给一名其他角色，然后此【杀】或【决斗】对你无效。
	技能设计：玉面
	状态：验证通过
]]
--

ZhuGeLiang_Plus = sgs.General(extension, "ZhuGeLiang_Plus", "shu", 3, true)

--[[
	技能：PlusGuanxing
	技能名：观星
	描述：回合开始阶段或回合结束阶段开始时，你可以观看牌堆顶的X张牌（X为存活角色的数量且最多为5），将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。每回合限一次。
	状态：验证通过
]]
--
PlusGuanxing = sgs.CreateTriggerSkill {
	name = "PlusGuanxing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			if not player:hasFlag("PlusGuanxing") then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerFlag(player, "PlusGuanxing")
					local count = room:alivePlayerCount()
					if count > 5 then
						count = 5
					end
					local cards = room:getNCards(count, false)
					room:askForGuanxing(player, cards)
				end
			end
		end
	end
}
ZhuGeLiang_Plus:addSkill(PlusGuanxing)

--[[
	技能：PlusKongcheng
	技能名：空城
	描述：当你成为【杀】或【决斗】的目标时，你可以将所有手牌（至少0张）交给一名其他角色，然后此【杀】或【决斗】对你无效。
	状态：验证通过
]]
--
--[[PlusKongcheng_Card = sgs.CreateSkillCard{
	name = "PlusKongcheng_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		if effect.card:subcardsLength() ~= 0 then
			target:obtainCard(effect.card, false)
		end
	end
}
PlusKongchengVS = sgs.CreateViewAsSkill{
	name = "PlusKongcheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local count = sgs.Self:getHandcardNum()
		if #cards == count then
			local card = PlusKongcheng_Card:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusKongcheng"
	end
}]]
PlusKongcheng = sgs.CreateTriggerSkill {
	name = "PlusKongcheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming, sgs.CardEffected },
	--view_as_skill = PlusKongchengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local source = use.from
			local targets = use.to
			local card = use.card
			if source:objectName() ~= player:objectName() then
				if targets:contains(player) then
					if card:isKindOf("Slash") or card:isKindOf("Duel") then
						local flag = false
						if player:isKongcheng() then
							flag = room:askForSkillInvoke(player, self:objectName(), data)
						else
							--flag = room:askForUseCard(player, "@PlusKongcheng", "@PlusKongcheng")
							local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(),
								"PlusKongcheng-invoke", true, true)
							if target then
								flag = true
								room:obtainCard(target, player:wholeHandCards())
							end
						end
						if flag then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
							room:broadcastSkillInvoke(self:objectName())
							room:setCardFlag(card, "PlusKongcheng")
							player:addMark("PlusKongcheng")
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:hasFlag("PlusKongcheng") then
				if player:getMark("PlusKongcheng") > 0 then
					local count = player:getMark("PlusKongcheng") - 1
					player:setMark("PlusKongcheng", count)
					if count == 0 then
						room:setCardFlag(card, "-PlusKongcheng")
					end
					local msg = sgs.LogMessage()
					msg.type = "#SkillNullify"
					msg.from = player
					msg.arg = self:objectName()
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		end
	end,
}
ZhuGeLiang_Plus:addSkill(PlusKongcheng)

----------------------------------------------------------------------------------------------------

--[[ SHU 003 关羽
	武将：GuanYu_Plus
	武将名：关羽
	称号：忠义双全
	国籍：蜀
	体力上限：4
	武将技能：
		武圣(PlusWusheng)：你可以将一张牌当【杀】使用或打出，且该【杀】按下列规则拥有相应的效果：红桃【杀】无视距离；方块【杀】造成的伤害+1；梅花【杀】不计入回合使用次数；黑桃【杀】无视防具。若以此法使用的【杀】造成伤害，在此【杀】结算后你须弃置一张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

GuanYu_Plus = sgs.General(extension, "GuanYu_Plus", "shu", 4, true)

--[[  PreDamageDone
	技能：PlusWusheng
	附加技能：PlusWusheng_Target
	技能名：武圣
	描述：你可以将一张牌当【杀】使用或打出，且该【杀】按下列规则拥有相应的效果：红桃【杀】无视距离；方块【杀】造成的伤害+1；梅花【杀】不计入出牌阶段内的使用次数限制；黑桃【杀】无视防具。若以此法使用的【杀】造成伤害，在此【杀】结算后你须弃置一张牌。
	状态：验证通过
]]
--
sgs.PlusWusheng_State = { "" }
PlusWushengVS = sgs.CreateViewAsSkill {
	name = "PlusWusheng",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local state = sgs.PlusWusheng_State[1]
		if state == "use" then
			if sgs.Slash_IsAvailable(sgs.Self) then
				if to_select:objectName() == "Crossbow" and to_select:isEquipped() then
					return sgs.Self:canSlashWithoutCrossbow()
				end
				return true
			else
				return to_select:getSuit() == sgs.Card_Club
			end
		elseif state == "response" then
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card:getId())
			slash:setSkillName(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		sgs.PlusWusheng_State = { "use" }
		local canSlash = false
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isBlack() then
				canSlash = true
				break
			end
		end
		return sgs.Slash_IsAvailable(player) or canSlash
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			sgs.PlusWusheng_State = { "response" }
			return true
		end
		return false
	end,
}
PlusWusheng_Target = sgs.CreateTargetModSkill { --红桃无视距离
	name = "#PlusWusheng_Target",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("PlusWusheng") and card:getSuit() == sgs.Card_Heart then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, player, card)
		if player:hasSkill("PlusWusheng") and card:getSuit() == sgs.Card_Club then
			return 999
		end
	end,
}
PlusWusheng = sgs.CreateTriggerSkill {
	name = "PlusWusheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused, sgs.CardUsed, sgs.TargetConfirmed, sgs.CardFinished, sgs.PreDamageDone },
	view_as_skill = PlusWushengVS,
	priority = 5,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from and use.from:hasSkill(self:objectName()) and RIGHT(self, player) then
				room:setCardFlag(use.card, "PlusWusheng_Slash")
				if use.card:getSuit() == sgs.Card_Club then --梅花不计使用次数
					if (use.m_addHistory) then
						room:addPlayerHistory(player, use.card:getClassName(), -1)
						room:sendCompulsoryTriggerLog(player, self:objectName(), true)
						use.m_addHistory = false
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.TargetConfirmed then --为后来指定的目标补齐防具无效效果
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") and card:hasFlag("PlusWusheng_Slash") and RIGHT(self, player) then
				if card:getSuit() == sgs.Card_Spade then --黑桃无视防具
					for _, p in sgs.qlist(use.to) do
						if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then
							p:addQinggangTag(use.card)
						end
					end
					room:setEmotion(use.from, "weapon/qinggang_sword")
				end
			end
		elseif event == sgs.DamageCaused then --方块伤害+1（按照FAQ将时机改为造成伤害时）
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") and card:hasFlag("PlusWusheng_Slash") and RIGHT(self, player) then
					if card:getSuit() == sgs.Card_Diamond then
						if not damage.chain and not damage.transfer then
							local hurt = damage.damage
							damage.damage = hurt + 1
							data:setValue(damage)
							local msg = sgs.LogMessage()
							msg.type = "#PlusWusheng_Diamond"
							msg.from = player
							msg.arg = hurt
							msg.arg2 = hurt + 1
							room:sendLog(msg)
						end
					end
				end
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") and card:hasFlag("PlusWusheng_Slash") and card:getSkillName() == self:objectName() and RIGHT(self, player) then
				if card:hasFlag("PlusWusheng_Damaged") then
					room:setCardFlag(card, "-PlusWusheng_Damaged")
					if not use.from:isNude() then
						room:askForDiscard(use.from, self:objectName(), 1, 1, false, true)
					end
				end
				room:setCardFlag(use.card, "-PlusWusheng_Slash")
			end
		elseif event == sgs.PreDamageDone then
			local damage = data:toDamage()
			local source = damage.from
			local target = damage.to
			if source then
				if source:hasSkill(self:objectName()) then
					local card = damage.card
					if card and card:isKindOf("Slash") and card:hasFlag("PlusWusheng_Slash") then
						room:setCardFlag(card, "PlusWusheng_Damaged")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end

}
GuanYu_Plus:addSkill(PlusWusheng)
GuanYu_Plus:addSkill(PlusWusheng_Target)
extension:insertRelatedSkills("PlusWusheng", "#PlusWusheng_Target")

----------------------------------------------------------------------------------------------------

--[[ SHU 004 张飞
	武将：ZhangFei_Plus
	武将名：张飞
	称号：万夫莫当
	国籍：蜀
	体力上限：4
	武将技能：
		咆哮(PlusPaoxiao)：出牌阶段，你可以选择并获得一项技能直到回合结束：你使用【杀】时可以额外指定X名目标，或你可以额外使用X张【杀】（X为你已损失的体力值且最多为2）。每阶段限一次。
		嫉恶(PlusJie)：锁定技，你使用的黑色【杀】攻击范围+1，你使用的红色【杀】造成的伤害+1。
	技能设计：锦衣祭司
	状态：验证失败（嫉恶出现BUG）
]]
--

ZhangFei_Plus = sgs.General(extension, "ZhangFei_Plus", "shu", 4, true)

--[[
	技能：PlusPaoxiao
	附加技能：PlusPaoxiao_TargetMod
	技能名：咆哮
	描述：出牌阶段，你可以选择并获得一项技能直到回合结束：你使用【杀】时可以额外指定X名目标，或你可以额外使用X张【杀】（X为你已损失的体力值且最多为2）。每阶段限一次。
	状态：验证通过
]]
--
PlusPaoxiao_Card = sgs.CreateSkillCard {
	name = "PlusPaoxiao_Card",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local x = math.min(source:getLostHp(), 2)
		local choice = room:askForChoice(source, self:objectName(),
			"PlusPaoxiao_choice1=" .. x .. "+PlusPaoxiao_choice2=" .. x)
		if choice:startsWith("PlusPaoxiao_choice1") then
			room:broadcastSkillInvoke("PlusPaoxiao")
			room:setPlayerMark(source, "PlusPaoxiao1", x)
			local msg = sgs.LogMessage()
			msg.type = "#PlusPaoxiao1"
			msg.from = source
			msg.arg = self:objectName()
			msg.arg2 = x
			room:sendLog(msg)
			room:addPlayerMark(source, "&PlusPaoxiao+PlusPaoxiao_extratarget+-Clear")
		elseif choice:startsWith("PlusPaoxiao_choice2") then
			room:broadcastSkillInvoke("PlusPaoxiao")
			room:setPlayerMark(source, "PlusPaoxiao2", x)
			local msg = sgs.LogMessage()
			msg.type = "#PlusPaoxiao2"
			msg.from = source
			msg.arg = self:objectName()
			msg.arg2 = x
			room:sendLog(msg)
			room:addPlayerMark(source, "&PlusPaoxiao+PlusPaoxiao_extra+-Clear")
		end
	end
}
PlusPaoxiaoVS = sgs.CreateViewAsSkill {
	name = "PlusPaoxiao",
	n = 0,
	view_as = function(self, cards)
		return PlusPaoxiao_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getLostHp() > 0 and not player:hasUsed("#PlusPaoxiao_Card")
	end
}
PlusPaoxiao = sgs.CreateTriggerSkill {
	name = "PlusPaoxiao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventLoseSkill },
	view_as_skill = PlusPaoxiaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				room:setPlayerMark(player, "PlusPaoxiao1", 0)
				room:setPlayerMark(player, "PlusPaoxiao2", 0)
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				room:setPlayerMark(player, "PlusPaoxiao1", 0)
				room:setPlayerMark(player, "PlusPaoxiao2", 0)
			end
			return false
		end
	end
}
PlusPaoxiao_TargetMod = sgs.CreateTargetModSkill {
	name = "#PlusPaoxiao_TargetMod",
	pattern = "Slash",
	extra_target_func = function(self, player)
		local num = player:getMark("PlusPaoxiao1")
		if player:hasSkill("PlusPaoxiao") then
			return num
		end
	end,
	residue_func = function(self, player)
		local num = player:getMark("PlusPaoxiao2")
		if player:hasSkill("PlusPaoxiao") then
			return num
		end
	end,
}
ZhangFei_Plus:addSkill(PlusPaoxiao)
ZhangFei_Plus:addSkill(PlusPaoxiao_TargetMod)
extension:insertRelatedSkills("PlusPaoxiao", "#PlusPaoxiao_TargetMod")
--[[
	技能：PlusJie
	附加技能：PlusJie_TargetMod
	技能名：嫉恶
	描述：锁定技，你使用的黑色【杀】攻击范围+1，你使用的红色【杀】造成的伤害+1。
	状态：验证失败
	BUG：黑色杀的攻击范围无法+1。（0224版TargetMod的问题，下个版本可修复）
]]
--
PlusJie = sgs.CreateTriggerSkill {
	name = "PlusJie",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") and card:isRed() then
				if not damage.chain and not damage.transfer then
					local index = 1
					if string.find(damage.to:getGeneralName(), "lvbu") or string.find(damage.to:getGeneralName(), "LvBu_Plus") then
						index = 2
					end
					room:broadcastSkillInvoke(self:objectName(), index)
					local hurt = damage.damage
					damage.damage = hurt + 1
					data:setValue(damage)
					local msg = sgs.LogMessage()
					msg.type = "#PlusJie"
					msg.from = player
					msg.arg = hurt
					msg.arg2 = hurt + 1
					room:sendLog(msg)
				end
			end
		end
		return false
	end
}


PlusJie_TargetMod = sgs.CreateTargetModSkill {
	name = "#PlusJie_TargetMod",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("PlusJie") and (card:isBlack()) then
			return 1
		else
			return 0
		end
	end
}

ZhangFei_Plus:addSkill(PlusJie)
ZhangFei_Plus:addSkill(PlusJie_TargetMod)
extension:insertRelatedSkills("PlusJie", "#PlusJie_TargetMod")
----------------------------------------------------------------------------------------------------

--[[ SHU 005 赵云
	武将：ZhaoYun_Plus
	武将名：赵云
	称号：常胜将军
	国籍：蜀
	体力上限：4
	武将技能：
		龙胆(PlusLongdan)：你可以将同花色的X张牌按下列规则使用或打出：红桃当【酒】，方块当【杀】，梅花当【闪】，黑桃当【无懈可击】（若你当前的体力值大于2，X为2；若你当前的体力值小于或等于2，X为1）。
		常胜(PlusChangsheng)：你的回合外，若你已受伤，每当你发动【龙胆】使用或打出一张牌时，你可以摸一张牌，然后弃一张牌。
	技能设计：小A&锦衣祭司
	状态：验证通过
]]
--

ZhaoYun_Plus = sgs.General(extension, "ZhaoYun_Plus", "shu", 4, true)

--[[
	技能：PlusLongdan
	技能名：龙胆
	--描述：你可以将同花色的X张牌按下列规则使用或打出：红桃当【酒】，方块当【杀】，梅花当【闪】，黑桃当【无懈可击】（若你当前的体力值大于2，X为2；若你当前的体力值小于或等于2，X为1）。
	描述：你可以将一张基本牌或锦囊牌当与此牌字数相同的基本牌或非延时类锦囊牌使用或打出。每回合限一次。
	状态：验证通过
	注：被杨修鸡肋锦囊牌之后，赵云选择转化的牌时依然能选择铁索连环，但是无效果；
		龙胆可以当铁索连环重铸。
]]
--
sgs.PlusLongdan_Pattern = { "spade", "heart", "club", "diamond" }
PlusLongdan = sgs.CreateViewAsSkill {
	name = "PlusLongdan",
	n = 999,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local hp = sgs.Self:getHp()
		local n = 1
		if hp > 2 then
			n = 2
		end
		if #selected < n then
			if n > 1 then
				if #selected > 0 then
					local suit = selected[1]:getSuit()
					return to_select:getSuit() == suit
				end
			end
			local suit = to_select:getSuit()
			if sgs.PlusLongdan_Pattern[1] == "true" and suit == sgs.Card_Spade then
				return true
			elseif sgs.PlusLongdan_Pattern[2] == "true" and suit == sgs.Card_Heart then
				return true
			elseif sgs.PlusLongdan_Pattern[3] == "true" and suit == sgs.Card_Club then
				return true
			elseif sgs.PlusLongdan_Pattern[4] == "true" and suit == sgs.Card_Diamond then
				return true
			end
		end
		return false
	end,
	view_as = function(self, cards)
		local hp = sgs.Self:getHp()
		local n = 1
		if hp > 2 then
			n = 2
		end
		if #cards == n then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = 0
			if #cards == 1 then
				number = card:getNumber()
			end
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("analeptic", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				for _, cd in pairs(cards) do
					new_card:addSubcard(cd)
				end
			end
			return new_card
		end
	end,
	enabled_at_play = function(self, player)
		sgs.PlusLongdan_Pattern = { "false", "false", "false", "false" }
		local flag = false
		if not player:hasUsed("Analeptic") then
			sgs.PlusLongdan_Pattern[2] = "true"
			flag = true
		end
		if sgs.Slash_IsAvailable(player) then
			sgs.PlusLongdan_Pattern[4] = "true"
			flag = true
		end
		return flag
	end,
	enabled_at_response = function(self, player, pattern)
		sgs.PlusLongdan_Pattern = { "false", "false", "false", "false" }
		if pattern == "slash" then
			sgs.PlusLongdan_Pattern[4] = "true"
			return true
		elseif pattern == "jink" then
			sgs.PlusLongdan_Pattern[3] = "true"
			return true
		elseif string.find(pattern, "analeptic") then
			sgs.PlusLongdan_Pattern[2] = "true"
			return true
		elseif pattern == "nullification" then
			sgs.PlusLongdan_Pattern[1] = "true"
			return true
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		sgs.PlusLongdan_Pattern = { "true", "false", "false", "false" }
		local hp = player:getHp()
		local n = 1
		if hp > 2 then
			n = 2
		end
		local count = 0
		local cards = player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		cards = player:getEquips()
		for _, card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		return count >= n
	end
}
ZhaoYun_Plus:addSkill(PlusLongdan)
--[[
	sgs.PlusLongdan_Pattern = {"pattern", "state"}
getLength = function(card_name)
	if card_name == "fire_slash" or card_name == "thunder_slash" then
		card_name = "slash"
	end
	local translate = sgs.Sanguosha:translate(card_name)
	return string.len(translate) / 2
end
PlusLongdan_DummyCard = sgs.CreateSkillCard{
	name = "PlusLongdan_DummyCard",
}
PlusLongdan_Card = sgs.CreateSkillCard{
	name = "PlusLongdan_Card",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local choices = "cancel"
		if sgs.PlusLongdan_Pattern[2] == "use" then
			local card = nil
			local n = 0
			local new = false
			local choicetable = {}
			for cardid = 0, 165, 1 do
				card = nil
				card = sgs.Sanguosha:getCard(cardid)
				if card and (card:isKindOf("BasicCard") or card:isNDTrick()) and not (card:isKindOf("Nullification") or card:isKindOf("Jink") or (card:isKindOf("Peach") and source:getLostHp() == 0)) then
					if card:isAvailable(source) then
						choicetable = {}
						choicetable = choices:split("+");
						n = #choicetable
						new = true
						for var = 1, n, 1 do
							if choicetable[var] == card:objectName() then new = false end
						end
						if new then choices = choices.."+"..card:objectName() end
					end
				end
			end
		elseif sgs.PlusLongdan_Pattern[2] == "response" then
			choices = choices .. "+" .. sgs.PlusLongdan_Pattern[1]
		end
		local choice = room:askForChoice(source, "PlusLongdan", choices)
		if choice ~= "cancel" then
			sgs.PlusLongdan_Pattern = {choice, sgs.PlusLongdan_Pattern[2]}
			room:askForCard(source, "@PlusLongdan_DummyCard", "", sgs.QVariant(), sgs.Card_MethodResponse)
		end
	end,
}
PlusLongdan_VS = sgs.CreateViewAsSkill{
	name = "PlusLongdan",
	n = 1,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.PlusLongdan_Pattern[1]
		if pattern == "choose" or string.find(pattern, "+") then
			return false
		end
		if #selected == 0 then
			if to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard") then
				if getLength(to_select:objectName()) == getLength(pattern) then
					local state = sgs.PlusLongdan_Pattern[2]
					if state == "use" then
						local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
						return card:isAvailable(sgs.Self)
					elseif state == "response" then
						return true
					end
				end
			end
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.PlusLongdan_Pattern[1]
		if pattern == "choose" or string.find(pattern, "+") then
			return PlusLongdan_Card:clone()
		end
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local newcard = sgs.Sanguosha:cloneCard(pattern, suit, point)
			newcard:addSubcard(card)
			newcard:setSkillName(self:objectName())
			return newcard
		end
	end,
	enabled_at_play = function(self, player)
		if not player:hasFlag("PlusLongdan_Used") then
			sgs.PlusLongdan_Pattern = {"choose", "use"}
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if not player:hasFlag("PlusLongdan_Used") then
			if pattern ~= "@PlusLongdan" then
				sgs.PlusLongdan_Pattern = {pattern, "response"}
				return true
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		if not player:hasFlag("PlusLongdan_Used") then
			sgs.PlusLongdan_Pattern = {"nullification", "response"}
			local cards = player:getHandcards()
			for _,card in sgs.qlist(cards) do
				if card:isKindOf("BasicCard") or card:isKindOf("TrickCard") then
					if getLength(card:objectName()) == getLength("nullification") then
						return true
					end
				end
			end
		end
		return false
	end
}
PlusLongdan = sgs.CreateTriggerSkill{
	name = "PlusLongdan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponsed, sgs.CardAsked, sgs.EventPhaseStart},
	view_as_skill = PlusLongdan_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
				room:setPlayerFlag(use.from, "PlusLongdan_Used")
			end
		elseif event == sgs.CardResponsed then
			local response = data:toResponsed()
			if response.m_card:getSkillName() == self:objectName() then
				room:setPlayerFlag(response.m_who, "PlusLongdan_Used")
			end
		elseif event == sgs.CardAsked then
			if data:toString() == "@PlusLongdan_DummyCard" then
				local pattern = sgs.PlusLongdan_Pattern[1]
				room:askForUseCard(player, "@PlusLongdan", "@PlusLongdan")
				local dummy = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
				room:provide(dummy)
				return true
			end
			return false
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				local zhaoyun = room:findPlayerBySkillName(self:objectName())
				if zhaoyun then
					room:setPlayerFlag(zhaoyun, "-PlusLongdan_Used")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhaoYun_Plus:addSkill(PlusLongdan)]]

--[[
	技能：PlusChangsheng
	技能名：常胜
	描述：你的回合外，若你已受伤，每当你发动【龙胆】使用或打出一张牌时，你可以摸一张牌。
	状态：验证通过
]]
--
--[[
PlusChangsheng = sgs.CreateTriggerSkill{
	name = "PlusChangsheng",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardResponded, sgs.TargetConfirmed, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive and player:isWounded() then
			if event == sgs.CardResponded then
				local resp = data:toCardResponse()
				local card = resp.m_card
				if card:getSkillName() == "PlusLongdan" then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:drawCards(player, 1, "PlusLongdan")
					end
				end
			elseif event == sgs.CardUsed then
				local use = data:toCardUse()
				if use.card:getSkillName() == "PlusLongdan" then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:drawCards(player, 1, "PlusLongdan")
					end
				end
			end
		end
		return false
	end
}]]

PlusChangsheng = sgs.CreateTriggerSkill {
	name = "PlusChangsheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and not card:isKindOf("SkillCard") and player:isWounded() and card:getSkillName() == "PlusLongdan" then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:drawCards(player, 1, "PlusLongdan")
			end
		end
		return false
	end
}


ZhaoYun_Plus:addSkill(PlusChangsheng)

----------------------------------------------------------------------------------------------------

--[[ SHU 006 马超
	武将：MaChao_Plus
	武将名：马超
	称号：一骑当千
	国籍：蜀
	体力上限：4
	武将技能：
		马术：锁定技，当你计算与其他角色的距离时，始终-1。
		铁骑(PlusTieji)：当你使用【杀】指定一名角色为目标后，你可以与其拼点，若你赢，此【杀】不可被【闪】响应，且在此【杀】结算后你可以弃置其装备区里的一张牌。
	技能设计：玉面
	状态：验证通过
]]
--

MaChao_Plus = sgs.General(extension, "MaChao_Plus", "shu", 4, true)

--[[
	技能：mashu
	技能名：马术
	描述：锁定技，当你计算与其他角色的距离时，始终-1。
	状态：原有技能
]]
--
MaChao_Plus:addSkill("mashu")

--[[
	技能：PlusTieji
	技能名：铁骑
	描述：当你使用【杀】指定一名角色为目标后，你可以与其拼点，若你赢，此【杀】不可被【闪】响应，且在此【杀】结算后你可以弃置其装备区里的一张牌。
	状态：验证通过
]]
--
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
PlusTieji = sgs.CreateTriggerSkill {
	name = "PlusTieji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") then
				if use.from:objectName() == player:objectName() then
					room:setCardFlag(card, "PlusTieji_Slash")
					local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					local targets = use.to
					for _, target in sgs.qlist(targets) do
						if player:canPindian(target) then
							if not target:isKongcheng() then
								local dest = sgs.QVariant()
								dest:setValue(target)
								if room:askForSkillInvoke(player, self:objectName(), dest) then
									room:broadcastSkillInvoke(self:objectName())
									local success = player:pindian(target, self:objectName(), nil)
									if success then
										local log = sgs.LogMessage()
										log.type = "#skill_cant_jink"
										log.from = player
										log.to:append(target)
										log.arg = self:objectName()
										room:sendLog(log)
										jink_table[index] = 0
										room:setPlayerFlag(target, "PlusTieji_Target")
									end
								end
							end
						end
						index = index + 1
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_" .. use.card:toString(), jink_data)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local source = use.from
			if source and source:objectName() == player:objectName() then
				if use.card:hasFlag("PlusTieji_Slash") then
					room:setCardFlag(use.card, "-PlusTieji_Slash")
					local targets = use.to
					for _, target in sgs.qlist(targets) do
						if target:isAlive() and target:hasFlag("PlusTieji_Target") then
							room:setPlayerFlag(target, "-PlusTieji_Target")
							if source:canDiscard(target, "e") then
								local dest = sgs.QVariant()
								dest:setValue(target)
								if room:askForSkillInvoke(player, self:objectName(), dest) then
									local to_throw = room:askForCardChosen(player, target, "e", self:objectName())
									local card = sgs.Sanguosha:getCard(to_throw)
									room:throwCard(card, target, player)
								end
							end
						end
					end
				end
			end
			return false
		end
	end
}
MaChao_Plus:addSkill(PlusTieji)

----------------------------------------------------------------------------------------------------

--[[ SHU 007 黄月英
	武将：HuangYueYing_Plus
	武将名：黄月英
	称号：归隐的杰女
	国籍：蜀
	体力上限：3
	武将技能：
		集智(PlusJizhi)：当你使用一张非延时类锦囊牌时，你可以摸一张牌；当其他角色使用非延时类锦囊牌指定你为目标时，你可以弃置其一张手牌。
		奇才：锁定技，你使用任何锦囊无距离限制。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

HuangYueYing_Plus = sgs.General(extension, "HuangYueYing_Plus", "shu", 3, false)

--[[
	技能：PlusJizhi
	技能名：集智
	描述：当你使用一张非延时类锦囊牌时，你可以摸一张牌；当其他角色使用非延时类锦囊牌指定你为目标时，你可以弃置其一张手牌。
	状态：验证通过
]]
--
PlusJizhi = sgs.CreateTriggerSkill {
	name = "PlusJizhi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardUsed, sgs.CardResponded, sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed or event == sgs.CardResponded then
			if event == sgs.CardUsed then
				use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponded then
				local response = data:toCardResponse()
				card = response.m_card
			end
			if card:isNDTrick() then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			card = use.card
			local source = use.from
			local targets = use.to
			if card and card:isNDTrick() then
				if targets:contains(player) then
					if source:objectName() ~= player:objectName() then
						if player:canDiscard(source, "h") then
							local dest = sgs.QVariant()
							dest:setValue(source)
							if room:askForSkillInvoke(player, self:objectName(), dest) then
								room:broadcastSkillInvoke(self:objectName())
								local chosen = room:askForCardChosen(player, source, "h", self:objectName())
								room:throwCard(chosen, source, player)
							end
						end
					end
				end
			end
		end
		return false
	end
}
HuangYueYing_Plus:addSkill(PlusJizhi)

--[[
	技能：qicai
	技能名：奇才
	描述：锁定技，你使用任何锦囊无距离限制。
	状态：原有技能
]]
--
HuangYueYing_Plus:addSkill("qicai")

----------------------------------------------------------------------------------------------------

--[[ SHU 008 黄忠
	武将：HuangZhong_Plus
	武将名：黄忠
	称号：老当益壮
	国籍：蜀
	体力上限：4
	武将技能：
		勇毅(PlusYongyi)：当你在出牌阶段内使用【杀】指定一名角色为目标后，以下两种情况，你可以令其不可以使用【闪】对此【杀】进行响应：
		1.目标角色的手牌数大于或等于你的体力值。
		2.目标角色的手牌数小于或等于你的攻击范围。
		烈弓(PlusLiegong)：你可以对攻击范围之外的角色使用【杀】，你以此法使用【杀】指定目标后，在攻击范围之外的目标可以弃置你的一张手牌。
	技能设计：吹风奈奈
	状态：验证通过
]]
--

HuangZhong_Plus = sgs.General(extension, "HuangZhong_Plus", "shu", 4, true)

--[[
	技能：PlusYongyi
	技能名：勇毅
	描述：当你在出牌阶段内使用【杀】指定一名角色为目标后，以下两种情况，你可以令其不可以使用【闪】对此【杀】进行响应：
		1.目标角色的手牌数大于或等于你的体力值。
		2.目标角色的手牌数小于或等于你的攻击范围。
	状态：验证通过
]]
--
PlusYongyi = sgs.CreateTriggerSkill {
	name = "PlusYongyi",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (player:getPhase() ~= sgs.Player_Play) or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local handcardnum = p:getHandcardNum()
			if (player:getHp() <= handcardnum) or (player:getAttackRange() >= handcardnum) then
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local log = sgs.LogMessage()
					log.type = "#skill_cant_jink"
					log.from = player
					log.to:append(p)
					log.arg = self:objectName()
					room:sendLog(log)
					jink_table[index] = 0
				end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
HuangZhong_Plus:addSkill(PlusYongyi)

--[[
	技能：PlusLiegong
	附加技能：PlusLiegong_Target
	技能名：烈弓
	描述：你可以对攻击范围之外的角色使用【杀】，你以此法使用【杀】指定目标后，在攻击范围之外的目标可以弃置你的一张手牌。
	状态：验证通过
	注：个别时候，使用杀后会闪退；
		黄忠与其他使用杀时无距离限制的武将组成双将，攻击范围外的目标依然可以弃牌。（以后再修）
]]
--

PlusLiegong_Target = sgs.CreateTargetModSkill {
	name = "#PlusLiegong_Target",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("PlusLiegong") then
			return 1000
		end
	end,
}

PlusLiegong = sgs.CreateTriggerSkill {
	name = "PlusLiegong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local source = use.from
		local targets = use.to
		if source:objectName() == player:objectName() then
			local card = use.card
			if card:isKindOf("Slash") then
				for _, target in sgs.qlist(targets) do
					if not player:inMyAttackRange(target) then
						if target:canDiscard(player, "h") then
							if room:askForSkillInvoke(target, self:objectName(), data) then
								local card_id = room:askForCardChosen(target, player, "h", self:objectName())
								room:throwCard(card_id, player, target)
							end
						end
					end
				end
			end
		end
	end
}


HuangZhong_Plus:addSkill(PlusLiegong)
HuangZhong_Plus:addSkill(PlusLiegong_Target)
extension:insertRelatedSkills("PlusLiegong", "#PlusLiegong_Target")

----------------------------------------------------------------------------------------------------

--[[ SHU 009 魏延
	武将：WeiYan_Plus
	武将名：魏延
	称号：嗜血的独狼
	国籍：蜀
	体力上限：4
	武将技能：
		狂骨：锁定技，每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。
		奇谋(PlusQimou)：限定技，出牌阶段，你可以令一名角色选择是否将所有手牌交给你（该角色可以拒绝）。然后你获得以下技能直到回合结束：你每造成一次伤害后，你可以额外使用一张【杀】；你计算与其他角色的距离视为1。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

WeiYan_Plus = sgs.General(extension, "WeiYan_Plus", "shu", 4, true)

--[[
	技能：kuanggu
	技能名：狂骨
	描述：锁定技，每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。
	状态：原有技能
]]
--
WeiYan_Plus:addSkill("tenyearkuanggu")

--[[
	技能：PlusQimou
	附加技能：PlusLiegong_Target, PlusQimou_Remove
	技能名：奇谋
	描述：限定技，出牌阶段，你可以令一名角色选择是否将所有手牌交给你（该角色可以拒绝）。然后你获得以下技能直到回合结束：你每造成一次伤害后，你可以额外使用一张【杀】；你计算与其他角色的距离视为1。
	状态：验证通过
]]
--
PlusQimou_Card = sgs.CreateSkillCard {
	name = "PlusQimou_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:broadcastInvoke("animate", "lightbox:$PlusQimou_Animation:3000")
		room:getThread():delay(4000)
		source:loseMark("@stratagem")
		room:addPlayerMark(source, "&PlusQimou-Clear")
		local target = targets[1]
		if not target:isKongcheng() then
			local dest = sgs.QVariant()
			dest:setValue(source)
			local choice = room:askForChoice(target, "PlusQimou",
				"PlusQimou_Give=" .. source:objectName() .. "+PlusQimou_Refuse", dest)
			if choice:startsWith("PlusQimou_Give") then
				local card = target:wholeHandCards()
				room:obtainCard(source, card)
			end
		end
		room:setPlayerFlag(source, "PlusQimou")
		room:setPlayerMark(source, "PlusQimou_Extra", 0)
		local others = room:getOtherPlayers(source)
		for _, p in sgs.qlist(others) do
			room:setFixedDistance(source, p, 1)
		end
	end
}
PlusQimouVS = sgs.CreateViewAsSkill {
	name = "PlusQimou",
	n = 0,
	view_as = function(self, cards)
		return PlusQimou_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@stratagem") >= 1
	end
}
PlusQimou = sgs.CreateTriggerSkill {
	name = "PlusQimou",
	frequency = sgs.Skill_Limited,
	events = { sgs.Damage },
	limit_mark = "@stratagem",
	view_as_skill = PlusQimouVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.Damage then
			local room = player:getRoom()
			if player:hasFlag("PlusQimou") then
				--player:addMark("PlusQimou_Extra")  不明原因此句无效
				room:setPlayerMark(player, "PlusQimou_Extra", player:getMark("PlusQimou_Extra") + 1)
			end
		end
	end
}
PlusQimou_Target = sgs.CreateTargetModSkill {
	name = "#PlusQimou_Target",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("PlusQimou") then
			return player:getMark("PlusQimou_Extra")
		end
	end,
}
PlusQimou_Remove = sgs.CreateTriggerSkill {
	name = "#PlusQimou_Remove",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local flag = false
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
			flag = true
		elseif event == sgs.EventLoseSkill and data:toString() == "PlusQimou" then
			flag = true
		end
		if flag then
			room:setPlayerFlag(player, "-PlusQimou")
			room:setPlayerMark(player, "PlusQimou_Extra", 0)
			local others = room:getOtherPlayers(player)
			for _, p in sgs.qlist(others) do
				room:removeFixedDistance(player, p, 1)
			end
		end
		return false
	end
}
WeiYan_Plus:addSkill(PlusQimou)
WeiYan_Plus:addSkill(PlusQimou_Target)
WeiYan_Plus:addSkill(PlusQimou_Remove)
extension:insertRelatedSkills("PlusQimou", "#PlusQimou_Target")
extension:insertRelatedSkills("PlusQimou", "#PlusQimou_Remove")

----------------------------------------------------------------------------------------------------

--[[ SHU 010 孟获
	武将：MengHuo_Plus
	武将名：孟获
	称号：南蛮王
	国籍：蜀
	体力上限：4
	武将技能：
		祸首: 锁定技，【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
		再起(PlusZaiqi): 摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。然后你可以弃置所有手牌并跳过你的出牌阶段，视为你使用了一张【南蛮入侵】。
	技能设计：玉面
	状态：验证通过
]]
--

MengHuo_Plus = sgs.General(extension, "MengHuo_Plus", "shu", 4, true)

--[[
	技能：huoshou
	技能名：祸首
	描述：锁定技，【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你是该【南蛮入侵】造成伤害的来源。
	状态：原有技能
]]
--
MengHuo_Plus:addSkill("huoshou")

--[[
	技能：PlusZaiqi
	技能名：再起
	描述：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中红桃牌数量的体力，然后将这些红桃牌置入弃牌堆，并获得其余的牌。然后你可以弃置所有手牌并跳过你的出牌阶段，视为你使用了一张【南蛮入侵】。
	状态：验证通过
]]
--
PlusZaiqi = sgs.CreateTriggerSkill {
	name = "PlusZaiqi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if player:isWounded() then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName(), 1)
					local x = player:getLostHp()
					local has_heart = false
					local ids = room:getNCards(x, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
						self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					room:getThread():delay(1000)
					local card_to_throw = {}
					local card_to_gotback = {}
					for i = 0, x - 1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						local suit = card:getSuit()
						if suit == sgs.Card_Heart then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end
					end
					if #card_to_throw > 0 then
						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = #card_to_throw
						room:recover(player, recover)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
							self:objectName(), nil)
						for _, card in pairs(card_to_throw) do
							room:throwCard(card, nil, nil)
						end
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName())
						for _, card in pairs(card_to_gotback) do
							room:obtainCard(player, card, true)
						end
					end
					if has_heart then
						room:broadcastSkillInvoke(self:objectName(), 2)
					else
						room:broadcastSkillInvoke(self:objectName(), 3)
					end
					if not player:isSkipped(sgs.Player_Play) then
						if not player:hasFlag("PlusTianxiang_Draw") then --防止天香
							if room:askForSkillInvoke(player, "PlusZaiqi_ss") then
								player:throwAllHandCards()
								player:skip(sgs.Player_Play)
								local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
								savage_assault:setSkillName(self:objectName())
								savage_assault:deleteLater()
								local card_use = sgs.CardUseStruct()
								card_use.from = player
								card_use.card = savage_assault
								room:useCard(card_use)
							end
						end
					end
					return true
				end
			end
		end
		return false
	end
}
MengHuo_Plus:addSkill(PlusZaiqi)

----------------------------------------------------------------------------------------------------

--[[ SHU 011 马谡
	武将：MaSu_Plus
	武将名：马谡
	称号：怀才自负
	国籍：蜀
	体力上限：3
	武将技能：
		心战：出牌阶段，若你的手牌数大于你的体力上限，你可以：观看牌堆顶的三张牌，然后亮出其中任意数量的红桃牌并获得之，其余以任意顺序置于牌堆顶。每阶段限一次。
		谈兵(PlusTanbing)：回合开始阶段开始时，你可以进行一次判定，若结果为红色，则摸牌阶段摸牌时，你可以额外摸一张牌。
		挥泪：锁定技，当你被其他角色杀死时，该角色弃置其所有的牌。
	技能设计：小A
	状态：验证通过
]]
--

MaSu_Plus = sgs.General(extension, "MaSu_Plus", "shu", 3, true)

--[[
	技能：xinzhan
	技能名：心战
	描述：出牌阶段，若你的手牌数大于你的体力上限，你可以：观看牌堆顶的三张牌，然后亮出其中任意数量的红桃牌并获得之，其余以任意顺序置于牌堆顶。每阶段限一次。
	状态：原有技能
]]
--
MaSu_Plus:addSkill("xinzhan")

--[[
	技能：PlusTanbing
	技能名：谈兵
	描述：回合开始阶段开始时，你可以进行一次判定，若结果为红色，则摸牌阶段摸牌时，你可以额外摸一张牌。
	状态：验证通过
]]
--
PlusTanbing = sgs.CreateTriggerSkill {
	name = "PlusTanbing",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:askForSkillInvoke(self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|red"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isGood() then
						room:setPlayerFlag(player, "PlusTanbing")
						room:addPlayerMark(player, "&PlusTanbing-Clear")
					end
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag("PlusTanbing") then
				if player:askForSkillInvoke(self:objectName()) then
					draw.num = draw.num + 1
					data:setValue(draw)
				end
			end
		end
		return false
	end
}
MaSu_Plus:addSkill(PlusTanbing)

--[[
	技能：huilei
	技能名：挥泪
	描述：锁定技，当你被其他角色杀死时，该角色弃置其所有的牌。
	状态：原有技能
]]
--
MaSu_Plus:addSkill("huilei")

----------------------------------------------------------------------------------------------------

--[[ SHU 012 陈到
	武将：ChenDao_Plus
	武将名：陈到
	称号：征西将军
	国籍：蜀
	体力上限：4
	武将技能：
		忠勇(PlusZhongyong)：出牌阶段开始时，你可以与一名其他角色拼点，若你赢，你可以弃置一张红色手牌视为你对其使用一张【杀】（不计入出牌阶段内的使用次数限制），此【杀】造成伤害后，你可以令一名距离2以内的其他角色将手牌补至X张（X为该角色的体力上限且最多为5）。若你没赢，你结束出牌阶段。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

ChenDao_Plus = sgs.General(extension, "ChenDao_Plus", "shu", 4, true)

--[[  askForPlayerChosen:optional  PreCardUsed(can use skillName)
	技能：PlusZhongyong
	技能名：忠勇
	描述：出牌阶段开始时，你可以与一名其他角色拼点，若你赢，你可以弃置一张红色手牌视为你对其使用一张【杀】（不计入出牌阶段内的使用次数限制），此【杀】造成伤害后，你可以令一名距离2以内的其他角色将手牌补至X张（X为该角色的体力上限且最多为5）。若你没赢，你结束出牌阶段。
	状态：验证通过
]]
--
PlusZhongyong_Card = sgs.CreateSkillCard {
	name = "PlusZhongyong_Card",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if sgs.Self:canPindian(to_select) then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "PlusZhongyong", self)
		if success then
			local source = effect.from
			local target = effect.to
			if source:canSlash(target, nil, false) then
				if source:canDiscard(source, "he") then
					if room:askForCard(source, ".red", "@PlusZhongyong_Slash", sgs.QVariant(), sgs.Card_MethodDiscard) then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("PlusZhongyong")
						slash:deleteLater()
						room:setPlayerFlag(source, "PlusZhongyong_Used")
						local card_use = sgs.CardUseStruct()
						card_use.card = slash
						card_use.from = source
						card_use.to:append(target)
						room:useCard(card_use, false)
					end
				end
			end
		else
			room:setPlayerFlag(effect.from, "SkipPlay")
		end
	end
}
PlusZhongyongVS = sgs.CreateViewAsSkill {
	name = "PlusZhongyong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusZhongyong_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusZhongyong"
	end
}
PlusZhongyong = sgs.CreateTriggerSkill {
	name = "PlusZhongyong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.CardUsed, sgs.Damage },
	view_as_skill = PlusZhongyongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local can_invoke = false
				local other_players = room:getOtherPlayers(player)
				for _, p in sgs.qlist(other_players) do
					if player:canPindian(p) then
						can_invoke = true
						break
					end
				end
				if can_invoke then
					room:askForUseCard(player, "@PlusZhongyong", "@PlusZhongyong_Pindian", -1, sgs.Card_MethodPindian)
				end
				if player:hasFlag("SkipPlay") then
					return true
				end
			end
			return false
		elseif event == sgs.CardUsed then
			if player:hasFlag("PlusZhongyong_Used") then
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") then
					room:setPlayerFlag(player, "-PlusZhongyong_Used")
					room:setCardFlag(use.card, "PlusZhongyong_Slash")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local slash = damage.card
			if slash then
				if slash:isKindOf("Slash") and slash:hasFlag("PlusZhongyong_Slash") then
					room:setCardFlag(slash, "-PlusZhongyong_Slash")
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:distanceTo(p) <= 2 then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						local dest = room:askForPlayerChosen(player, targets, self:objectName(), "PlusZhongyong-invoke",
							true, true)
						if dest then
							local toCount = dest:getMaxHp()
							if toCount > 5 then
								toCount = 5
							end
							local hasCount = dest:getHandcardNum()
							local count = toCount - hasCount
							if count > 0 then
								room:drawCards(dest, count, self:objectName())
							end
						end
					end
				end
			end
			return false
		end
	end
}
ChenDao_Plus:addSkill(PlusZhongyong)

----------------------------------------------------------------------------------------------------

--[[ SHU 013 蒋琬
	武将：JiangWan_Plus
	武将名：蒋琬
	称号：后蜀丞相
	国籍：蜀
	体力上限：3
	武将技能：
		筹援(PlusChouyuan)：每当一名角色成为【杀】或非延时类锦囊牌的目标后，若其没有手牌，你可以令其摸一张牌并展示之，若此牌不为红桃，则此【杀】或非延时类锦囊牌该角色无效。
		承规(PlusChenggui)：出牌阶段，你可以将一张手牌置于牌堆顶，然后令一名其他角色获得牌堆底的一张牌并展示之，若此牌为装备牌，则该角色可以将此牌置于装备区里。每阶段限一次。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

JiangWan_Plus = sgs.General(extension, "JiangWan_Plus", "shu", 3, true)

--[[
	技能：PlusChouyuan
	技能名：筹援
	描述：每当一名角色成为【杀】或非延时类锦囊牌的目标后，若其没有手牌，你可以令其摸一张牌并展示之，若此牌不为红桃，则此【杀】或非延时类锦囊牌该角色无效。
	状态：验证通过
]]
--
PlusChouyuan = sgs.CreateTriggerSkill {
	name = "PlusChouyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.CardEffected, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local jiangwans = room:findPlayersBySkillName(self:objectName())
			local use = data:toCardUse()
			for _, jiangwan in sgs.qlist(jiangwans) do
				local card = use.card
				if card then
					if card:isKindOf("Slash") or card:isNDTrick() then
						if use.to and use.to:contains(player) and player:isKongcheng() then
							room:setPlayerMark(player, "PlusChouyuan_target", 1)
							if room:askForSkillInvoke(jiangwan, self:objectName(), data) then
								local id = room:getNCards(1):first()
								local chouyuan_card = sgs.Sanguosha:getCard(id)
								room:obtainCard(player, chouyuan_card)
								if room:getCardPlace(id) == sgs.Player_PlaceHand then
									room:showCard(player, id)
									if chouyuan_card:getSuit() ~= sgs.Card_Heart then
										room:setCardFlag(card, "PlusChouyuan")
										player:addMark("PlusChouyuan")
									end
								end
							end
							room:setPlayerMark(player, "PlusChouyuan_target", 0)
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:hasFlag("PlusChouyuan") then
				if player:getMark("PlusChouyuan") > 0 then
					local count = player:getMark("PlusChouyuan") - 1
					player:setMark("PlusChouyuan", count)
					local msg = sgs.LogMessage()
					msg.type = "#SkillNullify"
					msg.from = player
					msg.arg = self:objectName()
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:hasFlag("PlusChouyuan") then
				for _, p in sgs.qlist(use.to) do
					p:removeMark("PlusChouyuan")
				end
				room:setCardFlag(card, "-PlusChouyuan")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
JiangWan_Plus:addSkill(PlusChouyuan)

--[[
	技能：PlusChenggui
	技能名：承规
	描述：出牌阶段，你可以将一张手牌置于牌堆顶，然后令一名其他角色获得牌堆底的一张牌并展示之，若此牌为装备牌，则该角色可以将此牌置于装备区里。每阶段限一次。
	状态：验证通过
	注：放在牌堆顶的牌会被展示。
]]
--
PlusChenggui_Card = sgs.CreateSkillCard {
	name = "PlusChenggui",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "", "PlusChenggui", "")
		room:moveCardTo(self, source, nil, sgs.Player_DrawPile, reason, true)
		local drawPile = room:getDrawPile()
		local id = drawPile:last()
		room:obtainCard(target, id)
		room:showCard(target, id)
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("EquipCard") then
			local cdata = sgs.QVariant()
			cdata:setValue(card)
			room:setTag("PlusChenggui_card", cdata)
			if room:askForSkillInvoke(target, "PlusChenggui") then
				local msg = sgs.LogMessage()
				msg.type = "$Install"
				msg.from = target
				msg.card_str = card:toString()
				room:sendLog(msg)
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, target:objectName(), "PlusChenggui", "")
				room:moveCardTo(card, target, target, sgs.Player_PlaceEquip, reason)
			end
			room:removeTag("PlusChenggui_card")
		end
	end
}
PlusChenggui = sgs.CreateViewAsSkill {
	name = "PlusChenggui",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusChenggui_Card:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusChenggui")
	end
}
JiangWan_Plus:addSkill(PlusChenggui)


----------------------------------------------------------------------------------------------------
--                                             吴
----------------------------------------------------------------------------------------------------


--[[ WU 001 孙权
	武将：SunQuan_Plus
	武将名：孙权
	称号：年轻的贤君
	国籍：吴
	体力上限：4
	武将技能：
		制衡(PlusZhiheng)：出牌阶段，你可以弃置任意数量的牌，然后摸等量的牌。若你以此法弃置的牌不少于三张，你可以令场上手牌数最少的一名其他角色获得场上手牌数最多的另一名其他角色的一张牌。每阶段限一次。
		救援：主公技，锁定技，当其它吴势力角色在你濒死状态下对你使用【桃】时，你额外回复1点体力。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

SunQuan_Plus = sgs.General(extension, "SunQuan_Plus$", "wu", 4, true)

--[[
	技能：PlusZhiheng
	技能名：制衡
	描述：出牌阶段，你可以弃置任意数量的牌，然后摸等量的牌。若你以此法弃置的牌不少于三张，你可以令场上手牌数最少的一名其他角色获得场上手牌数最多的另一名其他角色的一张牌。每阶段限一次。
	状态：验证通过
]]
--
PlusZhiheng_Card = sgs.CreateSkillCard {
	name = "PlusZhiheng_Card",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("PlusZhiheng")
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count, "PlusZhiheng")
			if count >= 3 then
				local others = room:getOtherPlayers(source)
				local minp = sgs.SPlayerList()
				local minnum = 999
				local maxp = sgs.SPlayerList()
				local maxnum = 0

				for _, p in sgs.qlist(others) do
					minnum = math.min(minnum, p:getHandcardNum())
					maxnum = math.max(maxnum, p:getHandcardNum())
				end
				local minpp = {}
				local maxpp = {}
				for _, p in sgs.qlist(others) do
					if p:getHandcardNum() == maxnum and not (p:isKongcheng() and not p:hasEquip()) then
						maxp:append(p)
						table.insert(maxpp, p:objectName())
					end
				end
				for _, p in sgs.qlist(others) do
					if p:getHandcardNum() == minnum and not (#maxpp == 1 and maxpp[1] == p:objectName()) then
						minp:append(p)
						table.insert(minpp, p:objectName())
					end
				end
				if #maxpp ~= 0 and #minpp ~= 0 then
					if room:askForChoice(source, "PlusZhiheng", "PlusZhiheng_cancel+PlusZhiheng_ok") == "PlusZhiheng_ok" then
						local less = room:askForPlayerChosen(source, minp, "#PlusZhiheng_from")
						local maxList = sgs.SPlayerList()
						for _, p in sgs.qlist(maxp) do
							if p:objectName() ~= less:objectName() then
								maxList:append(p)
							end
						end
						local more = room:askForPlayerChosen(source, maxList, "#PlusZhiheng_to")
						local id = room:askForCardChosen(less, more, "he", "PlusZhiheng")
						local card = sgs.Sanguosha:getCard(id)
						room:obtainCard(less, card, false)
					end
				end
			end
		end
	end
}
PlusZhiheng = sgs.CreateViewAsSkill {
	name = "PlusZhiheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local zhiheng_card = PlusZhiheng_Card:clone()
			for _, card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusZhiheng_Card")
	end
}
SunQuan_Plus:addSkill(PlusZhiheng)

--[[
	技能：jiuyuan
	技能名：救援
	描述：主公技，锁定技，当其它吴势力角色在你濒死状态下对你使用【桃】时，你额外回复1点体力。
	状态：原有技能
]]
--
SunQuan_Plus:addSkill("jiuyuan")

----------------------------------------------------------------------------------------------------

--[[ WU 002 周瑜
	武将：ZhouYu_Plus
	武将名：周瑜
	称号：大都督
	国籍：吴
	体力上限：4
	武将技能：
		英姿：摸牌阶段摸牌时，你可以额外摸一张牌。
		反间(PlusFanjian)：出牌阶段，你可以弃置一张牌并选择两名手牌数不相等的角色，视为其中手牌多的角色对手牌少的角色使用一张【杀】。此【杀】若被【闪】抵消，在此【杀】结算后，使用此【杀】的角色须失去1点体力。每阶段限一次。
	技能设计：锦衣祭司&array88
	状态：验证通过
]]
--

ZhouYu_Plus = sgs.General(extension, "ZhouYu_Plus", "wu", 3, true)

--[[
	技能：yingzi
	技能名：英姿
	描述：摸牌阶段摸牌时，你可以额外摸一张牌。
	状态：原有技能
]]
--
ZhouYu_Plus:addSkill("yingzi")

--[[
	技能：PlusFanjian
	技能名：反间
	描述：出牌阶段，你可以弃置一张牌并选择两名手牌数不相等的角色，视为其中手牌多的角色对手牌少的角色使用一张【杀】。此【杀】若被【闪】抵消，在此【杀】结算后，使用此【杀】的角色须失去1点体力。每阶段限一次。
	状态：验证通过
	小BUG：若手牌少的角色使用【闪】之后死亡，使用【杀】的角色不会失去体力。
	注：个别时候，发动反间会出现闪退；
]]
--
PlusFanjian_Card = sgs.CreateSkillCard {
	name = "PlusFanjian_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local first = targets[1]
			local first_hand = first:getHandcardNum()
			if first:objectName() == sgs.Self:objectName() and not card:isEquipped() then
				first_hand = first_hand - 1
			end
			local second_hand = to_select:getHandcardNum()
			if to_select:objectName() == sgs.Self:objectName() and not card:isEquipped() then
				second_hand = second_hand - 1
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if first_hand > second_hand then
				return not sgs.Self:isProhibited(to_select, slash)
			elseif first_hand < second_hand then
				return not sgs.Self:isProhibited(first, slash)
			end
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local playerA = targets[1]
		local playerB = targets[2]
		local from = nil
		local to = nil
		if playerA:getHandcardNum() > playerB:getHandcardNum() then
			from = playerA
			to = playerB
		elseif playerA:getHandcardNum() < playerB:getHandcardNum() then
			from = playerB
			to = playerA
		else
			return nil
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("PlusFanjian")
		room:setPlayerFlag(from, "PlusFanjian_Used")
		local card_use = sgs.CardUseStruct()
		card_use.from = from
		card_use.to:append(to)
		card_use.card = slash
		room:useCard(card_use, false)
		slash:deleteLater()
	end
}
PlusFanjianVS = sgs.CreateViewAsSkill {
	name = "PlusFanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusFanjian_Card:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusFanjian_Card")
	end
}
PlusFanjian = sgs.CreateTriggerSkill {
	name = "PlusFanjian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset, sgs.CardFinished, sgs.CardUsed },
	view_as_skill = PlusFanjianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.card:hasFlag("PlusFanjian_Slash") then
				room:setCardFlag(effect.card, "PlusFanjian_Missed")
				room:setCardFlag(effect.card, "-PlusFanjian_Slash")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasFlag("PlusFanjian_Missed") then
				if use.from:isAlive() then
					room:loseHp(use.from)
					room:setCardFlag(use.card, "-PlusFanjian_Missed")
				end
			end
		elseif event == sgs.CardUsed then
			if player:hasFlag("PlusFanjian_Used") then
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") then
					room:setPlayerFlag(player, "-PlusFanjian_Used")
					room:setCardFlag(use.card, "PlusFanjian_Slash")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
ZhouYu_Plus:addSkill(PlusFanjian)

----------------------------------------------------------------------------------------------------

--[[ WU 003 吕蒙
	武将：LvMeng_Plus
	武将名：吕蒙
	称号：取鳞探虎
	国籍：吴
	体力上限：4
	武将技能：
		克已(PlusKeji)：弃牌阶段弃牌时，若你于出牌阶段未使用或打出过【杀】，你可以将你弃置的牌置于你的武将牌上，称为“懈”；当你成为【杀】或【决斗】的目标后，你可以将一张“懈”置入弃牌堆，令此牌对你无效。
		渡江(PlusDujiang)：觉醒技，回合开始阶段开始时，若“懈”的数量达到4或更多，你须减1点体力上限，摸两张牌，并获得技能“夺城”（出牌阶段，你可以将一张“懈”置入弃牌堆并指定一名其他角色，然后弃置X张手牌并指定该角色装备区里的X张牌，你获得其中一张牌，再将其余的牌依次弃置。每阶段限一次）。
		（夺城）(PlusDuocheng)：出牌阶段，你可以将一张“懈”置入弃牌堆并指定一名其他角色，然后弃置X张手牌并指定该角色装备区里的X张牌，你获得其中一张牌，再将其余的牌依次弃置。每阶段限一次。
	技能设计：小A
	状态：验证通过
]]
--

LvMeng_Plus = sgs.General(extension, "LvMeng_Plus", "wu", 4, true)

--[[
	技能：PlusKeji
	附加技能：PlusKeji_Jink
	技能名：克己
	描述：弃牌阶段弃牌时，若你于出牌阶段未使用或打出过【杀】，你可以将你弃置的牌置于你的武将牌上，称为“懈”；当你成为【杀】或【决斗】的目标后，你可以将一张“懈”置入弃牌堆，令此牌对你无效。
	状态：验证通过
]]
--

PlusKeji = sgs.CreateTriggerSkill {
	name = "PlusKeji",
	frequency = sgs.Skill_Frequent,
	events = { sgs.PreCardUsed, sgs.CardResponded, sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			if player:getPhase() == sgs.Player_Play then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card
				end
				if card:isKindOf("Slash") then
					player:setFlags("PlusKejiSlashInPlayPhase")
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if not move.from or move.from:objectName() ~= player:objectName() then return false end
			if player:getPhase() ~= sgs.Player_Discard then return false end
			if player:hasFlag("PlusKejiSlashInPlayPhase") then
				player:setFlags("-PlusKejiSlashInPlayPhase")
				return false
			end
			if move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local dummy = sgs.Sanguosha:cloneCard("jink")
				for i = 0, move.card_ids:length() - 1, 1 do
					local id = move.card_ids:at(i)
					if move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
						dummy:addSubcard(id)
					end
				end
				if dummy:subcardsLength() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
					for _, id in sgs.qlist(dummy:getSubcards()) do
						move.from_places:removeAt(move.card_ids:indexOf(id, 0))
						move.card_ids:removeOne(id)
					end
					data:setValue(move)
					player:addToPile("slack", dummy)
				end
				dummy:deleteLater()
			end
		end
		return false
	end
}

RemoveSlack = function(lvmeng)
	local slack = lvmeng:getPile("slack")
	if slack:length() > 0 then
		local room = lvmeng:getRoom()
		room:fillAG(slack, lvmeng)
		local card_id = room:askForAG(lvmeng, slack, false, "PlusKeji")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "PlusKeji", "")
		room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
		slack:removeOne(card_id)
		room:clearAG()
		return true
	end
	return false
end
PlusKeji_Jink = sgs.CreateTriggerSkill {
	name = "#PlusKeji_Jink",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local source = use.from
			local targets = use.to
			local card = use.card
			if source and source:objectName() ~= player:objectName() then
				local times = 0
				for _, p in sgs.qlist(targets) do
					if p:objectName() == player:objectName() then
						times = times + 1
					end
				end
				if times > 0 then
					if card:isKindOf("Slash") or card:isKindOf("Duel") then
						for i = 1, times, 1 do
							if player:getPile("slack"):length() > 0 then
								if room:askForSkillInvoke(player, self:objectName(), data) then
									if RemoveSlack(player) then
										room:setCardFlag(card, "PlusKeji_Jink")
										player:addMark("PlusKeji")
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:hasFlag("PlusKeji_Jink") then
				if player:getMark("PlusKeji") > 0 then
					local count = player:getMark("PlusKeji") - 1
					player:setMark("PlusKeji", count)
					if count == 0 then
						room:setCardFlag(card, "-PlusKeji_Jink")
					end
					local msg = sgs.LogMessage()
					msg.type = "#SkillNullify"
					msg.from = player
					msg.arg = "PlusKeji"
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		end
	end,
}
LvMeng_Plus:addSkill(PlusKeji)
LvMeng_Plus:addSkill(PlusKeji_Jink)
extension:insertRelatedSkills("PlusKeji", "#PlusKeji_Jink")

--[[
	技能：PlusDujiang
	附加技能：PlusDujiang_Clear
	技能名：渡江
	描述：觉醒技，回合开始阶段开始时，若“懈”的数量达到4或更多，你须减1点体力上限，摸两张牌，并获得技能“夺城”（出牌阶段，你可以将一张“懈”置入弃牌堆并指定一名其他角色，然后弃置X张手牌并指定该角色装备区里的X张牌，你获得其中一张牌，再将其余的牌依次弃置。每阶段限一次）。
	状态：验证通过
]]
--
PlusDujiang = sgs.CreateTriggerSkill {
	name = "PlusDujiang",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		msg.type = "#PlusDujiang"
		msg.from = player
		msg.arg = player:getPile("slack"):length()
		msg.arg2 = self:objectName()
		room:sendLog(msg)
		room:broadcastInvoke("animate", "lightbox:$PlusDujiang_Animation:3000")
		room:getThread():delay(4000)
		room:setPlayerMark(player, "PlusDujiang", 1)
		if room:changeMaxHpForAwakenSkill(player) then
			room:drawCards(player, 2, self:objectName())
			room:handleAcquireDetachSkills(player, "PlusDuocheng")
		end
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local slack = player:getPile("slack"):length()
		if slack < 4 then
			return false
		end
		return true
	end,
}
LvMeng_Plus:addSkill(PlusDujiang)

--[[
	技能：PlusDuocheng
	技能名：夺城
	描述：出牌阶段，你可以将一张“懈”置入弃牌堆并指定一名其他角色，然后弃置X张手牌并指定该角色装备区里的X张牌，你获得其中一张牌，再将其余的牌依次弃置。每阶段限一次。
	状态：验证通过
]]
--
PlusDuocheng_Card = sgs.CreateSkillCard {
	name = "PlusDuocheng_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
		room:throwCard(self, reason, nil)
		local target = targets[1]
		local slack = source:getPile("slack")
		room:setPlayerFlag(source, "PlusDuocheng_source")
		room:setPlayerFlag(target, "PlusDuocheng_target")
		local equips = target:getEquips()
		local length = equips:length()
		room:askForDiscard(source, "PlusDuocheng", length, 1, true, false, "#PlusDuocheng")
	end
}
PlusDuochengVS = sgs.CreateOneCardViewAsSkill {
	name = "PlusDuocheng",
	filter_pattern = ".|.|.|slack",
	expand_pile = "slack",
	view_as = function(self, card)
		local liuli_card = PlusDuocheng_Card:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end,
	enabled_at_play = function(self, player)
		local slack = player:getPile("slack")
		if not slack:isEmpty() then
			return not player:hasUsed("#PlusDuocheng_Card")
		end
		return false
	end
}
PlusDuocheng = sgs.CreateTriggerSkill {
	name = "PlusDuocheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	view_as_skill = PlusDuochengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName() then
			if move.to_place == sgs.Player_DiscardPile then
				if player:hasFlag("PlusDuocheng_source") then
					room:setPlayerFlag(player, "-PlusDuocheng_source")
					local x = move.card_ids:length()
					local targets = room:getOtherPlayers(player)
					for _, target in sgs.qlist(targets) do
						if target:hasFlag("PlusDuocheng_target") then
							room:setPlayerFlag(target, "-PlusDuocheng_target")
							if target:hasEquip() or target:getJudgingArea():length() > 0 then
								local card_id = room:askForCardChosen(player, target, "e", self:objectName())
								if card_id then
									room:obtainCard(player, card_id)
									if x > 1 then
										for i = 1, x - 1, 1 do
											if player:canDiscard(target, "e") then
												card_id = room:askForCardChosen(player, target, "e", self:objectName())
												if card_id then
													room:throwCard(card_id, target, player)
												else
													break
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = -1
}
local skill = sgs.Sanguosha:getSkill("PlusDuocheng")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(PlusDuocheng)
	sgs.Sanguosha:addSkills(skillList)
end
LvMeng_Plus:addRelateSkill("PlusDuocheng")

----------------------------------------------------------------------------------------------------

--[[ WU 004 陆逊
	武将：LuXun_Plus
	武将名：陆逊
	称号：儒生雄才
	国籍：吴
	体力上限：3
	武将技能：
		挫锐(PlusCuorui)：当一名角色使用【顺手牵羊】或【乐不思蜀】指定你攻击范围内的一名角色为目标时，你可以弃置一张手牌，使该角色不再成为此牌的目标。
		度势(PlusDuoshi)：每当一名角色失去最后的手牌时，你可以摸一张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

LuXun_Plus = sgs.General(extension, "LuXun_Plus", "wu", 3, true)

--[[
	技能：PlusCuorui
	附加技能：PlusCuorui_Jump
	技能名：挫锐
	描述：当一名角色使用【顺手牵羊】或【乐不思蜀】指定你攻击范围内的一名角色为目标时，你可以弃置一张手牌，使该角色不再成为此牌的目标。
	状态：验证通过
	注：由于没有合适的时机，取消乐不思蜀时，先将乐不思蜀放置在使用者的判定区，再将其置入弃牌堆；
		若有与挫锐发动时机相同的技能，并不是按照行动顺序发动，而是按照太阳神三国杀中的顺序发动。
]]
--
PlusCuorui_DummyCard = sgs.CreateSkillCard {
	name = "PlusCuorui_DummyCard",
	target_fixed = true,
	will_throw = true,
}
PlusCuoruiVS = sgs.CreateViewAsSkill {
	name = "PlusCuorui",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and not to_select:hasFlag("PlusCuorui_Temp")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusCuorui_DummyCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusCuorui"
	end
}
PlusCuorui = sgs.CreateTriggerSkill {
	name = "PlusCuorui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming },
	view_as_skill = PlusCuoruiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local luxuns = room:findPlayersBySkillName(self:objectName())
		for _, luxun in sgs.qlist(luxuns) do
			local use = data:toCardUse()
			local source = use.from
			local targets = use.to
			local card = use.card
			if targets:contains(player) then
				if luxun:inMyAttackRange(player) or player:objectName() == luxun:objectName() then
					if card:isKindOf("Snatch") or card:isKindOf("Indulgence") then
						local prompt = string.format("@PlusCuorui:%s::%s", player:objectName(), card:objectName())
						room:setCardFlag(card, "PlusCuorui_Temp")
						local dest = sgs.QVariant()
						dest:setValue(player)
						room:setTag("PlusCuorui", dest)
						if room:askForUseCard(luxun, "@PlusCuorui", prompt) then
							local msg = sgs.LogMessage()
							msg.type = "#PlusCuorui"
							msg.from = luxun
							msg.to:append(player)
							msg.arg = self:objectName()
							msg.arg2 = card:objectName()
							room:sendLog(msg)
							if card:isKindOf("Indulgence") then
								targets:removeOne(player)
							end
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
							room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
							room:removeTag("PlusCuorui")
							break
						end
						room:removeTag("PlusCuorui")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}


LuXun_Plus:addSkill(PlusCuorui)


--[[
	技能：PlusDuoshi
	技能名：度势
	描述：每当一名角色失去最后的手牌时，你可以摸一张牌。
	状态：验证通过
	注：若一名角色将所有手牌和一些装备区里的牌转化后使用或打出，陆逊依然可以摸牌。
]]
--
PlusDuoshiGetKingdoms = function(player)
	local kingdoms = {}
	local room = player:getRoom()
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		local flag = true
		for _, k in ipairs(kingdoms) do
			if p:getKingdom() == k then
				flag = false
				break
			end
		end
		if flag then
			table.insert(kingdoms, p:getKingdom())
		end
	end
	return #kingdoms
end
PlusDuoshi = sgs.CreateTriggerSkill {
	name = "PlusDuoshi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, luxun, data)
		local room = luxun:getRoom()
		local luxuns = room:findPlayersBySkillName(self:objectName())
		for _, luxun in sgs.qlist(luxuns) do
			local move = data:toMoveOneTime()
			if move.from and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
				if room:askForSkillInvoke(luxun, self:objectName(), data) then
					luxun:drawCards(1, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					if luxun:getHandcardNum() > PlusDuoshiGetKingdoms(luxun) then
						room:askForDiscard(luxun, self:objectName(), 1, 1, false, true)
					end
				end
			end
		end
		return false
	end,
}
LuXun_Plus:addSkill(PlusDuoshi)

----------------------------------------------------------------------------------------------------

--[[ WU 005 甘宁
	武将：GanNing_Plus
	武将名：甘宁
	称号：佩铃的游侠
	国籍：吴
	体力上限：4
	武将技能：
		奇袭(PlusQixi)：出牌阶段，你可以将一张黑色牌当【过河拆桥】使用。若此牌为梅花，你可以额外指定一个目标或额外弃置目标角色区域内的一张牌；若此牌为黑桃且所弃置的牌为装备牌，你可以在此牌置入弃牌堆时，用一张手牌替换之。每阶段限一次。
	技能设计：曹小瞒back
	状态：验证通过
]]
--

GanNing_Plus = sgs.General(extension, "GanNing_Plus", "wu", 4, true)

--[[
	技能：PlusQixi
	附加技能：PlusQixi_Target
	技能名：奇袭
	描述：出牌阶段，你可以将一张黑色牌当【过河拆桥】使用。若此牌为梅花，你可以额外指定一个目标或额外弃置目标角色区域内的一张牌；若此牌为黑桃且所弃置的牌为装备牌，你可以在此牌置入弃牌堆时，用一张手牌替换之。每阶段限一次。
	状态：验证通过
	注：若甘宁与能够修改过河拆桥目标个数的武将（例如李儒；简雍需等待三将正式公布，因为目前虫妹的lua中是先CardUsed再修改目标个数的）组成双将，梅花的第二个效果无法实现。
]]
--
listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
PlusQixiVS = sgs.CreateViewAsSkill {
	name = "PlusQixi",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		if #cards == 1 then
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("PlusQixi_used")
	end
}
PlusQixi = sgs.CreateTriggerSkill {
	name = "PlusQixi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.CardFinished, sgs.EventPhaseChanging },
	view_as_skill = PlusQixiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Dismantlement") and use.card:getSkillName() == self:objectName() then
				room:setPlayerFlag(use.from, "PlusQixi_used")
				local extra = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, use.from, use.card) +
					1                    --最多可选目标数
				if use.to:length() <= extra - 1 then --此处等待使用correctTargetMod修改
					room:setPlayerFlag(use.from, "PlusQixi_single")
				end
				if use.card:getSuit() == sgs.Card_Club then
					room:setPlayerFlag(use.from, "PlusQixi_club")
				elseif use.card:getSuit() == sgs.Card_Spade then
					room:setPlayerFlag(use.from, "PlusQixi_spade")
				end
			end
		elseif event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source then
				if move.to_place == sgs.Player_DiscardPile then
					if move.reason.m_playerId == player:objectName() and (player:hasFlag("PlusQixi_club") or player:hasFlag("PlusQixi_spade")) then
						local reason = move.reason.m_reason
						if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
							if event == sgs.CardsMoveOneTime then
								if player:hasFlag("PlusQixi_club") and player:hasFlag("PlusQixi_single") then
									if player:hasFlag("PlusQixi_second") then --防止额外弃的牌触发奇袭
										room:setPlayerFlag(player, "-PlusQixi_second")
									else
										if not move.from:isAllNude() then
											local dest = nil --move.from为Player，但是askForCardChosen要求ServerPlayer
											for _, p in sgs.qlist(room:getAlivePlayers()) do
												if p:objectName() == move.from:objectName() then
													dest = p
												end
											end
											local qqqq = sgs.QVariant()
											qqqq:setValue(dest)
											if room:askForSkillInvoke(player, self:objectName(), qqqq) then
												room:setPlayerFlag(player, "PlusQixi_second")
												if player:canDiscard(dest, "hej") then
													local chosen = room:askForCardChosen(player, dest, "hej",
														"dismantlement")
													room:throwCard(chosen, dest, player)
												end
											end
										end
									end
								end
							elseif event == sgs.BeforeCardsMove then
								if player:hasFlag("PlusQixi_spade") then
									local card_id = move.card_ids:first()
									local card = sgs.Sanguosha:getCard(card_id)
									if card:isKindOf("EquipCard") then
										if move.from_places:contains(sgs.Player_PlaceEquip) then
											local replace = room:askForCard(player, ".", "@PlusQixi_prompt", data,
												sgs.Card_MethodDiscard)
											if replace then
												local move2 = sgs.CardsMoveStruct()
												move2.card_ids:append(card_id)
												move2.to = player
												move2.to_place = sgs.Player_PlaceHand
												move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE,
													player:objectName())
												local moves = sgs.CardsMoveList()
												moves:append(move2)
												room:moveCardsAtomic(moves, true)

												move.from_places:removeAt(listIndexOf(move.card_ids, card_id))
												move.card_ids:removeOne(card_id)
												data:setValue(move)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			room:setPlayerFlag(player, "-PlusQixi_club")
			room:setPlayerFlag(player, "-PlusQixi_spade")
			room:setPlayerFlag(player, "-PlusQixi_second")
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("PlusQixi_used") then
					room:setPlayerFlag(player, "-PlusQixi_used")
				end
			end
		end
		return false
	end
}
PlusQixi_Target = sgs.CreateTargetModSkill {
	name = "#PlusQixi_Target",
	pattern = "Dismantlement",
	extra_target_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and card:getSuit() == sgs.Card_Club and card:getSkillName() == "PlusQixi" then
			return 1
		end
	end,
}
GanNing_Plus:addSkill(PlusQixi)
GanNing_Plus:addSkill(PlusQixi_Target)
extension:insertRelatedSkills("PlusQixi", "#PlusQixi_Target")
----------------------------------------------------------------------------------------------------

--[[ WU 006 黄盖
	武将：HuangGai_Plus
	武将名：黄盖
	称号：轻身为国
	国籍：吴
	体力上限：4
	武将技能：
		苦肉(PlusKurou)：出牌阶段，你可以失去1点体力，然后选择一项：1.令一名手牌数不大于你的手牌数的角色摸两张牌。2.令一名手牌数不小于你的手牌数的角色弃两张牌。每阶段限一次。
		诈降(PlusZhaxiang)：限定技，出牌阶段，若你当前的体力值不大于1，你可以横置你的武将牌，然后你受到1点火属性伤害。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

HuangGai_Plus = sgs.General(extension, "HuangGai_Plus", "wu", 4, true)

--[[
	技能：PlusKurou
	技能名：苦肉
	描述：出牌阶段，你可以失去1点体力，然后选择一项：1.令一名手牌数不大于你的手牌数的角色摸两张牌。2.令一名手牌数不小于你的手牌数的角色弃两张牌。每阶段限一次。
	状态：验证通过
]]
--
PlusKurou_Card = sgs.CreateSkillCard {
	name = "PlusKurou_Card",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("PlusKurou")
		room:loseHp(source, 1)
		if source:isAlive() then
			local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "PlusKurou")
			local target_hand = target:getHandcardNum()
			local source_hand = source:getHandcardNum()
			local choice
			if target_hand < source_hand then
				choice = "PlusKurou_Draw"
			elseif target_hand > source_hand then
				choice = "PlusKurou_Discard"
			else
				choice = room:askForChoice(source, "PlusKurou", "PlusKurou_Draw+PlusKurou_Discard")
			end
			if choice == "PlusKurou_Draw" then
				room:drawCards(target, 2, "PlusKurou")
			elseif choice == "PlusKurou_Discard" then
				room:askForDiscard(target, self:objectName(), 2, 2, false, true)
			end
		end
	end
}
PlusKurou = sgs.CreateViewAsSkill {
	name = "PlusKurou",
	n = 0,
	view_as = function(self, cards)
		return PlusKurou_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusKurou_Card")
	end
}
HuangGai_Plus:addSkill(PlusKurou)

--[[
	技能：PlusZhaxiang
	技能名：诈降
	描述：限定技，出牌阶段，若你当前的体力值不大于1，你可以横置你的武将牌，然后你受到1点火属性伤害。
	状态：验证通过
]]
--
PlusZhaxiang_Card = sgs.CreateSkillCard {
	name = "PlusZhaxiang_Card",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastInvoke("animate", "lightbox:$PlusZhaxiang_Animation:3000")
		room:getThread():delay(4000)
		source:loseMark("@surrender")
		if not source:isChained() then
			room:setPlayerProperty(source, "chained", sgs.QVariant(true))
		end
		local damage = sgs.DamageStruct()
		damage.card = nil
		damage.from = nil
		damage.to = source
		damage.nature = sgs.DamageStruct_Fire
		room:damage(damage)
	end
}
PlusZhaxiangVS = sgs.CreateViewAsSkill {
	name = "PlusZhaxiang",
	n = 0,
	view_as = function(self, cards)
		return PlusZhaxiang_Card:clone()
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@surrender") >= 1 then
			return player:getHp() <= 1
		end
		return false
	end
}
PlusZhaxiang = sgs.CreateTriggerSkill {
	name = "PlusZhaxiang",
	frequency = sgs.Skill_Limited,
	events = {},
	limit_mark = "@surrender",
	view_as_skill = PlusZhaxiangVS,
	on_trigger = function(self, event, player, data)
	end
}
HuangGai_Plus:addSkill(PlusZhaxiang)

----------------------------------------------------------------------------------------------------

--[[ WU 007 大乔
	武将：DaQiao_Plus
	武将名：大乔
	称号：矜持之花
	国籍：吴
	体力上限：3
	武将技能：
		国色：出牌阶段，你可以将你的一张方片花色的牌当【乐不思蜀】使用。
		流离(PlusLiuli)：当你成为【杀】或【决斗】的目标时，你可以弃置一张牌，并将此【杀】或【决斗】转移给一名距离2以内的男性角色，该男性角色不得是该牌的使用者。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

DaQiao_Plus = sgs.General(extension, "DaQiao_Plus", "wu", 3, false)

--[[
	技能：guose
	技能名：国色
	描述：出牌阶段，你可以将你的一张方片花色的牌当【乐不思蜀】使用。
	状态：原有技能
]]
--
DaQiao_Plus:addSkill("guose")

--[[
	技能：PlusLiuli
	技能名：流离
	描述：当你成为【杀】或【决斗】的目标时，你可以弃置一张牌，并将此【杀】或【决斗】转移给一名距离2以内的男性角色，该男性角色不得是该牌的使用者。
	状态：验证通过
	注：由于技能描述中为“男性角色”，而不是“其他男性角色”，因此双将下主将为男性角色、副将为大乔时是可以流离自己的，然后会无限循环。。
]]
--
sgs.LiuliPattern = { 0 }
PlusLiuli_Card = sgs.CreateSkillCard {
	name = "PlusLiuli_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isMale() and not to_select:hasFlag("PlusLiuli_Forbid") then
				local slash = sgs.Sanguosha:getCard(sgs.LiuliPattern[1])
				if sgs.Self:distanceTo(to_select) <= 2 then
					local cards = self:getSubcards()
					local card_id = cards:at(0)
					local horse = sgs.Self:getOffensiveHorse()
					if horse and horse:getId() == card_id then
						return sgs.Self:distanceTo(to_select, 1) <= 2
					else
						return true
					end
				end
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room = target:getRoom()
		room:setPlayerFlag(target, "PlusLiuli_Target")
	end
}
PlusLiuliVS = sgs.CreateViewAsSkill {
	name = "PlusLiuli",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local liuli_card = PlusLiuli_Card:clone()
			liuli_card:addSubcard(cards[1])
			return liuli_card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusLiuli"
	end
}
PlusLiuli = sgs.CreateTriggerSkill {
	name = "PlusLiuli",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming },
	view_as_skill = PlusLiuliVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local slash = use.card
		local source = use.from
		local targets = use.to
		if slash and (slash:isKindOf("Slash") or slash:isKindOf("Duel")) then
			if targets:contains(player) then
				if not player:isNude() then
					local room = player:getRoom()
					local players = room:getAllPlayers()
					players:removeOne(source)
					room:setPlayerFlag(source, "LiuliSlashSource")
					local can_invoke = false
					for _, p in sgs.qlist(players) do
						if p:isMale() then
							if player:distanceTo(p) <= 2 then
								if slash:isKindOf("Slash") then
									if source:canSlash(p, slash, false) then
										can_invoke = true
									else
										room:setPlayerFlag(p, "PlusLiuli_Forbid")
									end
								elseif slash:isKindOf("Duel") then
									if not sgs.Sanguosha:isProhibited(source, p, slash) then
										can_invoke = true
									else
										room:setPlayerFlag(p, "PlusLiuli_Forbid")
									end
								end
							end
						end
					end
					if can_invoke then
						local cdata = sgs.QVariant()
						cdata:setValue(slash)
						room:setTag("liuli-card", cdata)
						local prompt = string.format("@PlusLiuli:%s", source:objectName())
						room:setPlayerFlag(source, "PlusLiuli_Forbid")
						sgs.LiuliPattern = { slash:getId() }
						if room:askForUseCard(player, "@PlusLiuli", prompt) then
							room:broadcastSkillInvoke(self:objectName())
							for _, p in sgs.qlist(room:getAllPlayers()) do
								room:setPlayerFlag(p, "-PlusLiuli_Forbid")
							end
							for _, p in sgs.qlist(players) do
								if p:hasFlag("PlusLiuli_Target") then
									local new_targets = sgs.SPlayerList()
									for _, t in sgs.qlist(targets) do
										if t:objectName() == player:objectName() then
											new_targets:append(p)
										else
											new_targets:append(t)
										end
									end
									use.from = source
									use.to = new_targets
									use.card = slash
									data:setValue(use)
									room:setPlayerFlag(p, "-PlusLiuli_Target")
									return true
								end
							end
						end
						room:removeTag("liuli-card")
						for _, p in sgs.qlist(room:getAllPlayers()) do
							room:setPlayerFlag(p, "-PlusLiuli_Forbid")
						end
					end
					room:setPlayerFlag(source, "-LiuliSlashSource")
				end
			end
		end
		return false
	end
}
DaQiao_Plus:addSkill(PlusLiuli)

----------------------------------------------------------------------------------------------------

--[[ WU 008 孙尚香
	武将：SunShangXiang_Plus
	武将名：孙尚香
	称号：弓腰姬
	国籍：吴
	体力上限：4
	武将技能：
		良缘(PlusLiangyuan)：限定技，回合开始阶段开始时，你可以指定一名已受伤或手牌数最少的男性角色，该男性角色获得1枚“良缘”标记。然后你须减1点体力上限，摸两张牌，然后将你的势力改变为该男性角色的势力，并获得技能“结姻”（出牌阶段，你可以弃置两张手牌，然后你与拥有“良缘”标记的男性角色各回复1点体力。每阶段限一次）。
		（结姻）(PlusJieyin)：出牌阶段，你可以弃置两张手牌，然后你与拥有“良缘”标记的男性角色各回复1点体力。每阶段限一次。
		枭姬：当你失去装备区里的一张牌时，你可以摸两张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

SunShangXiang_Plus = sgs.General(extension, "SunShangXiang_Plus", "wu", 4, false)

--[[
	技能：PlusLiangyuan
	附加技能：PlusLiangyuan_Mark, PlusLiangyuan_Clear
	技能名：良缘
	描述：限定技，回合开始阶段开始时，你可以指定一名已受伤或手牌数最少的男性角色，该男性角色获得1枚“良缘”标记。然后你须减1点体力上限，摸两张牌，然后将你的势力改变为该男性角色的势力，并获得技能“结姻”（出牌阶段，你可以弃置两张手牌，然后你与拥有“良缘”标记的男性角色各回复1点体力。每阶段限一次）。+1。
	状态：验证通过
	注：孙尚香为主公时，在第一个回合开始阶段开始时询问是否发动良缘，此时屏幕显示异常；
		个别时候，发动后无效果。
]]
--
PlusLiangyuan_Card = sgs.CreateSkillCard {
	name = "PlusLiangyuan_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isMale() then
				return to_select:isWounded() or to_select:getHandcardNum() == sgs.Self:getMark("PlusLiangyuan_Least")
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		if #targets == 1 then
			room:broadcastInvoke("animate", "lightbox:$PlusLiangyuan_Animation:3000")
			room:getThread():delay(4000)
			source:loseMark("@love")
			local target = targets[1]
			target:gainMark("@match")
			room:addPlayerMark(target, "&PlusLiangyuan+to+#" .. source:objectName())
			room:loseMaxHp(source)
			room:drawCards(source, 2, "PlusLiangyuan")
			local kingdom = target:getKingdom()
			if source:getKingdom() ~= kingdom then
				local msg = sgs.LogMessage()
				msg.type = "#PlusLiangyuan_Kingdom"
				msg.from = source
				msg.arg = kingdom
				room:sendLog(msg)
				room:setPlayerProperty(source, "kingdom", sgs.QVariant(kingdom))
			end
			room:handleAcquireDetachSkills(source, "PlusJieyin")
			room:handleAcquireDetachSkills(source, "PlusYinli")
		end
	end
}
PlusLiangyuanVS = sgs.CreateViewAsSkill {
	name = "PlusLiangyuan",
	view_as = function(self, cards)
		return PlusLiangyuan_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusLiangyuan"
	end
}
PlusLiangyuan = sgs.CreateTriggerSkill {
	name = "PlusLiangyuan",
	frequency = sgs.Skill_Limited,
	events = { sgs.EventPhaseStart },
	view_as_skill = PlusLiangyuanVS,
	limit_mark = "@love",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("@love") > 0 then
				local players = room:getAllPlayers()
				local least = 1000
				for _, p in sgs.qlist(players) do
					least = math.min(p:getHandcardNum(), least)
				end
				room:setPlayerMark(player, "PlusLiangyuan_Least", least)
				local can_invoke = false
				for _, p in sgs.qlist(players) do
					if p:isMale() and (p:isWounded() or p:getHandcardNum() == least) then
						can_invoke = true
						break
					end
				end
				if can_invoke then
					room:askForUseCard(player, "@PlusLiangyuan", "@PlusLiangyuan")
				end
				room:setPlayerMark(player, "PlusLiangyuan_Least", 0)
			end
		end
	end
}
PlusLiangyuan_Clear = sgs.CreateTriggerSkill {
	name = "#PlusLiangyuan_Clear",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill, sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Death and data:toDeath().who:objectName() == player:objectName()) or (event == sgs.EventLoseSkill and data:toString() == "PlusLiangyuan") then
			if player:hasSkill("PlusJieyin") then
				room:detachSkillFromPlayer(player, "PlusJieyin")
			end
			if player:getMark("@love") > 0 then
				player:loseMark("@love")
			else
				local players = room:getAllPlayers()
				for _, p in sgs.qlist(players) do
					if p:getMark("@match") > 0 then
						p:loseMark("@match")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
SunShangXiang_Plus:addSkill(PlusLiangyuan)
SunShangXiang_Plus:addSkill(PlusLiangyuan_Clear)
extension:insertRelatedSkills("PlusLiangyuan", "#PlusLiangyuan_Clear")
--[[
	技能：PlusJieyin
	技能名：结姻
	描述：出牌阶段，你可以弃置两张手牌，然后你与拥有“良缘”标记的男性角色各回复1点体力。每阶段限一次。
	状态：验证通过
]]
--
PlusJieyin_Card = sgs.CreateSkillCard {
	name = "PlusJieyin_Card",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
		local index
		if player:isMale() then
			if player:getMark("@match") > 0 then
				index = 5
			else
				index = 3
				local players = room:getAllPlayers()
				for _, dest in sgs.qlist(players) do
					if dest:isMale() and dest:getMark("@match") > 0 then
						if player:getHp() >= dest:getHp() then
							index = 3
						else
							index = 4
						end
					end
				end
			end
		else
			index = math.random(0, 1) + 1
		end
		room:broadcastSkillInvoke("PlusJieyin", index)
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = player
		room:recover(player, recover, true)
		local players = room:getAllPlayers()
		for _, dest in sgs.qlist(players) do
			if dest:isMale() and dest:getMark("@match") > 0 and dest:getMark("&PlusLiangyuan+to+#" .. player:objectName()) > 0 then
				room:recover(dest, recover, true)
			end
		end
	end
}
PlusJieyin = sgs.CreateViewAsSkill {
	name = "PlusJieyin",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected < 2 then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = PlusJieyin_Card:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		end
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#PlusJieyin_Card")
	end
}
local skill = sgs.Sanguosha:getSkill("PlusJieyin")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(PlusJieyin)
	sgs.Sanguosha:addSkills(skillList)
end

--[[
	技能：xiaoji
	技能名：枭姬
	描述：当你失去装备区里的一张牌时，你可以摸两张牌。
	状态：原有技能
]]
--
SunShangXiang_Plus:addSkill("xiaoji")

--[[
	技能：PlusYinli
	技能名：姻礼
	描述：当你/拥有“良缘”标记的男性角色的装备牌于其回合外置入弃牌堆时，拥有“良缘”标记的男性角色/你可以获得其中任意数量的牌。
	状态：验证通过
]]
--
PlusYinliDummyCard = sgs.CreateSkillCard {
	name = "PlusYinliDummyCard",
}
PlusYinli = sgs.CreateTriggerSkill {
	name = "PlusYinli",
	frequency = sgs.Skill_Frequent,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if move.from and move.from:getPhase() == sgs.Player_NotActive and move.to_place == sgs.Player_DiscardPile then
			local flag = false
			if (player:hasSkill(self:objectName()) or player:getMark("PlusLiangyuanFemale") > 0) and (move.from:isMale() and move.from:getMark("@match") > 0) then --男性角色的装备牌置入弃牌堆，孙尚香获得
				flag = true
			elseif (player:isMale() and player:getMark("@match") > 0) and (move.from:hasSkill(self:objectName()) or move.from:getMark("PlusLiangyuanFemale") > 0) then --孙尚香的装备牌置入弃牌堆，男性角色获得
				flag = true
			end
			if flag then
				local room = player:getRoom()
				local card_ids = sgs.IntList()
				local card_ids_forAG = sgs.IntList()
				for i, card_id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(card_id):isKindOf("EquipCard") and room:getCardOwner(card_id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
						card_ids:append(card_id)
						card_ids_forAG:append(card_id)
					end
				end
				if card_ids:isEmpty() then
					return false
				elseif room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					if not (player:hasSkill(self:objectName()) or player:getMark("PlusLiangyuanFemale") > 0) then
						local msg = sgs.LogMessage()
						msg.type = "#InvokeOthersSkill"
						msg.from = player
						msg.to:append(room:findPlayer(move.from:getGeneralName(), true))
						msg.arg = self:objectName()
						room:sendLog(msg)
					end
					local card_ids_discard = sgs.IntList()
					while not card_ids:isEmpty() do
						room:fillAG(card_ids_forAG, player, card_ids_discard)
						local id = room:askForAG(player, card_ids, true, self:objectName())
						if id == -1 then
							room:clearAG(player)
							break
						end
						card_ids:removeOne(id)
						card_ids_discard:append(id)
						room:clearAG(player)
					end
					if not card_ids:isEmpty() then
						local card = PlusYinliDummyCard:clone()
						for _, id in sgs.qlist(card_ids) do
							if move.card_ids:contains(id) then
								move.from_places:removeAt(listIndexOf(move.card_ids, id))
								move.card_ids:removeOne(id)
								data:setValue(move)
							end
							card:addSubcard(id)
						end
						room:moveCardTo(card, player, sgs.Player_PlaceHand, move.reason, true)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return (target:hasSkill(self:objectName()) or target:getMark("PlusLiangyuanFemale") > 0) or
				(target:isMale() and target:getMark("@match") > 0)
		end
	end,
}
local skill = sgs.Sanguosha:getSkill("PlusYinli")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(PlusYinli)
	sgs.Sanguosha:addSkills(skillList)
end

SunShangXiang_Plus:addRelateSkill("PlusJieyin")
SunShangXiang_Plus:addRelateSkill("PlusYinli")

----------------------------------------------------------------------------------------------------

--[[ WU 009 小乔
	武将：XiaoQiao_Plus
	武将名：小乔
	称号：矫情之花
	国籍：吴
	体力上限：3
	武将技能：
		天香(PlusTianxiang)：回合结束时，你可以弃置一张红桃手牌，令一名角色执行一个额外的摸牌阶段或弃牌阶段。若该角色在该摸牌阶段获得多于两张的牌，你可以获得其一张牌；若该角色在该弃牌阶段弃置多于两张的牌，你须弃置一张牌。
		红颜：锁定技，你的黑桃牌均视为红桃牌。
	技能设计：cryaciccl
	状态：验证通过
]]
--

XiaoQiao_Plus = sgs.General(extension, "XiaoQiao_Plus", "wu", 3, false)

--[[
	技能：PlusTianxiang
	附加技能：PlusTianxiang_Skip
	技能名：天香
	描述：回合结束时，你可以弃置一张红桃手牌，令一名角色执行一个额外的摸牌阶段或弃牌阶段。若该角色在该摸牌阶段获得多于两张的牌，你可以获得其一张牌；若该角色在该弃牌阶段弃置多于两张的牌，你须弃置一张牌。
	状态：验证通过
	注：其他角色无法判断此额外阶段是否在小乔的回合内（如屯田）；
		跳过其他阶段的效果依然能执行（如自守，虽然自守即使跳过了出牌阶段也可以摸牌）。
]]
--
PlusTianxiang_Card = sgs.CreateSkillCard {
	name = "PlusTianxiang_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = target:getRoom()
		local dest = sgs.QVariant()
		dest:setValue(target)
		local choice = room:askForChoice(source, "PlusTianxiang", "PlusTianxiang_Draw+PlusTianxiang_Discard", dest)
		room:setPlayerFlag(target, choice)
	end
}
PlusTianxiangVS = sgs.CreateViewAsSkill {
	name = "PlusTianxiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getSuit() == sgs.Card_Heart
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local tianxiangCard = PlusTianxiang_Card:clone()
			tianxiangCard:addSubcard(cards[1])
			return tianxiangCard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusTianxiang"
	end
}
PlusTianxiang = sgs.CreateTriggerSkill {
	name = "PlusTianxiang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
	view_as_skill = PlusTianxiangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			if player and player:hasSkill(self:objectName()) then
				local change = data:toPhaseChange()
				local nextphase = change.to
				if nextphase == sgs.Player_NotActive then
					if not player:isKongcheng() then
						if not (player:hasFlag("PlusTianxiang_Draw") or player:hasFlag("PlusTianxiang_Discard")) then --防止给自己额外阶段再触发一次
							if room:askForUseCard(player, "@PlusTianxiang", "@PlusTianxiang") then
								room:broadcastSkillInvoke(self:objectName())
								if player:hasFlag("PlusTianxiang_Draw") or player:hasFlag("PlusTianxiang_Discard") then --给自己的话直接在回合内添加阶段
									if player:hasFlag("PlusTianxiang_Draw") then
										change.to = sgs.Player_Draw
										data:setValue(change)
										player:insertPhase(sgs.Player_Draw)
									elseif player:hasFlag("PlusTianxiang_Discard") then
										change.to = sgs.Player_Discard
										data:setValue(change)
										player:insertPhase(sgs.Player_Discard)
									end
								else --其他玩家的话在回合结束时插入额外阶段
									for _, target in sgs.qlist(room:getAllPlayers()) do
										if target:hasFlag("PlusTianxiang_Draw") then
											target:setMark("PlusTianxiang_Draw", 0)
											local phases = sgs.PhaseList()
											phases:append(sgs.Player_Draw)
											target:play(phases)
											room:setPlayerFlag(target, "-PlusTianxiang_Draw")
											--room:drawCards(player, target:getMark("PlusTianxiang_Draw"))
											if target:getMark("PlusTianxiang_Draw") > 2 then
												if room:askForSkillInvoke(player, self:objectName()) then
													local card_id = room:askForCardChosen(player, target, "he",
														self:objectName())
													room:obtainCard(player, card_id)
												end
											end
										elseif target:hasFlag("PlusTianxiang_Discard") then
											target:setMark("PlusTianxiang_Discard", 0)
											local phases = sgs.PhaseList()
											phases:append(sgs.Player_Discard)
											target:play(phases)
											room:setPlayerFlag(target, "-PlusTianxiang_Discard")
											if target:getMark("PlusTianxiang_Discard") > 2 then
												room:askForDiscard(player, self:objectName(), 1, 1, false, true)
											end
										end
									end
								end
							end
						else --对自己发动时去除标志，执行后续效果
							room:setPlayerFlag(player, "-PlusTianxiang_Draw")
							room:setPlayerFlag(player, "-PlusTianxiang_Discard")
							if player:getMark("PlusTianxiang_Draw") > 2 then
								if room:askForSkillInvoke(player, self:objectName()) then
									local card_id = room:askForCardChosen(player, player, "he", self:objectName())
									room:obtainCard(player, card_id)
								end
							end
							if player:getMark("PlusTianxiang_Discard") > 2 then
								room:askForDiscard(player, self:objectName(), 1, 1, false, true)
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then --记录获得牌数和弃置牌数
			local move = data:toMoveOneTime()
			local target = move.to
			local place = move.to_place
			if player:hasFlag("PlusTianxiang_Draw") then
				if target and target:objectName() == player:objectName() then
					if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
						local count = 0
						if not move.from or move.from:objectName() ~= player:objectName() then --从其他玩家或牌堆
							count = move.card_ids:length()
						else                                                 --从自己的区域
							local places = move.from_places
							for _, pl in sgs.qlist(places) do
								if pl ~= sgs.Player_PlaceHand and pl ~= sgs.Player_PlaceEquip then
									count = count + 1
								end
							end
						end
						local now = player:getMark("PlusTianxiang_Draw")
						room:setPlayerMark(player, "PlusTianxiang_Draw", now + count)
					end
				end
			end
			if player:hasFlag("PlusTianxiang_Discard") then
				if place == sgs.Player_DiscardPile then
					local reason = move.reason
					if reason.m_playerId == player:objectName() then
						local basic = bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
						if basic == sgs.CardMoveReason_S_REASON_DISCARD then
							local now = player:getMark("PlusTianxiang_Discard")
							room:setPlayerMark(player, "PlusTianxiang_Discard", now + move.card_ids:length())
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
PlusTianxiang_Skip = sgs.CreateTriggerSkill { --跳过阶段之间时间点
	name = "#PlusTianxiang_Skip",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
	view_as_skill = PlusTianxiangVS,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("PlusTianxiang_Draw") or player:hasFlag("PlusTianxiang_Discard") then
			local room = player:getRoom()
			if event == sgs.EventPhaseChanging then --在额外阶段开始前，即阶段之间的时间点，令该角色技能无效
				local change = data:toPhaseChange()
				local nextphase = change.to
				if (player:hasFlag("PlusTianxiang_Draw") and nextphase == sgs.Player_Draw) or (player:hasFlag("PlusTianxiang_Discard") and nextphase == sgs.Player_Discard) then
					local skill_list = {}
					local skills = player:getVisibleSkillList()
					for _, skill in sgs.qlist(skills) do
						if not table.contains(skill_list, skill:objectName()) then
							if not skill:inherits("SPConvertSkill") then
								if not skill:isAttachedLordSkill() then
									table.insert(skill_list, skill:objectName())
								end
							end
						end
					end
					if #skill_list ~= 0 then
						local card_id = table.concat(skill_list, "+")
						player:setTag("QingchengList", sgs.QVariant(card_id))
						for _, id in ipairs(skill_list) do
							local mark = "Qingcheng" .. id
							room:setPlayerMark(player, mark, 1)
						end
						local cards = player:getCards("he")
						room:filterCards(player, cards, true)
					end
				end
			elseif event == sgs.EventPhaseStart then --恢复技能
				local phase = player:getPhase()
				if (player:hasFlag("PlusTianxiang_Draw") and phase == sgs.Player_Draw) or (player:hasFlag("PlusTianxiang_Discard") and phase == sgs.Player_Discard) then
					local guzhu_list = player:getTag("QingchengList"):toString()
					guzhu_list = guzhu_list:split("+")
					for _, id in ipairs(guzhu_list) do
						local mark = "Qingcheng" .. id
						room:setPlayerMark(player, mark, 0)
					end
					player:setTag("QingchengList", sgs.QVariant())
					local cards = player:getCards("he")
					room:filterCards(player, cards, false)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 4
}
XiaoQiao_Plus:addSkill(PlusTianxiang)
XiaoQiao_Plus:addSkill(PlusTianxiang_Skip)
extension:insertRelatedSkills("PlusTianxiang", "#PlusTianxiang_Skip")

--[[
	技能：PlusHongyan
	技能名：红颜
	描述：每当一张红桃牌于一名男性角色的弃牌阶段内因该角色的弃置而置入弃牌堆时，其可以将此牌交给你。
	状态：验证通过
]]
--

PlusHongyanDummyCard = sgs.CreateSkillCard {
	name = "PlusHongyanDummyCard",
}
PlusHongyan = sgs.CreateTriggerSkill {
	name = "PlusHongyan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if move.to_place == sgs.Player_DiscardPile and move.reason.m_playerId == player:objectName() and player:getPhase() == sgs.Player_Discard then
			local room = player:getRoom()
			local xiaoqiaos = room:findPlayersBySkillName(self:objectName())
			local card_ids = sgs.IntList()
			local card_ids_forAG = sgs.IntList()
			for i, card_id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Heart then
					card_ids:append(card_id)
					card_ids_forAG:append(card_id)
				end
			end
			for _, xiaoqiao in sgs.qlist(xiaoqiaos) do
				local dest = sgs.QVariant()
				dest:setValue(xiaoqiao)
				if card_ids:isEmpty() then
					return false
				elseif room:askForSkillInvoke(player, self:objectName(), dest) then
					room:broadcastSkillInvoke(self:objectName())
					if not player:hasSkill(self:objectName()) then
						local msg = sgs.LogMessage()
						msg.type = "#InvokeOthersSkill"
						msg.from = player
						msg.to:append(xiaoqiao)
						msg.arg = self:objectName()
						room:sendLog(msg)
					end
					local card_ids_discard = sgs.IntList()
					while not card_ids:isEmpty() do
						room:fillAG(card_ids_forAG, player, card_ids_discard)
						local id = room:askForAG(player, card_ids, true, self:objectName())
						if id == -1 then
							room:clearAG(player)
							break
						end
						card_ids:removeOne(id)
						card_ids_discard:append(id)
						room:clearAG(player)
					end
					if not card_ids:isEmpty() then
						for _, id in sgs.qlist(card_ids) do
							if move.card_ids:contains(id) then
								move.from_places:removeAt(listIndexOf(move.card_ids, id))
								move.card_ids:removeOne(id)
								data:setValue(move)
							end
							room:moveCardTo(sgs.Sanguosha:getCard(id), xiaoqiao, sgs.Player_PlaceHand, move.reason, true)
							if not player:isAlive() then break end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:isMale()
		end
	end,
}
XiaoQiao_Plus:addSkill(PlusHongyan)



--XiaoQiao_Plus:addSkill("hongyan")

----------------------------------------------------------------------------------------------------

--[[ WU 010 周泰
	武将：ZhouTai_Plus
	武将名：周泰
	称号：历战之躯
	国籍：吴
	体力上限：4
	武将技能：
		不屈(PlusBuqu)：每当你扣减1点体力时，若你当前体力为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，称为“伤”，若“伤”的点数都不同，你不会死亡；若出现相同点数的“伤”，你进入濒死状态。每有三张“伤”，你的手牌上限就+1。
		护主(PlusHuzhu)：当距离1以内的一名其他角色进入濒死状态时，你可以对自己造成1点伤害，视为你对该角色使用了一张【桃】。
	技能设计：玉面
	状态：验证通过
]]
--

ZhouTai_Plus = sgs.General(extension, "ZhouTai_Plus", "wu", 4, true)

--[[
	技能：PlusBuqu
	附加技能：PlusBuqu_Remove, PlusBuqu_Keep
	技能名：不屈
	描述：每当你扣减1点体力时，若你当前体力为0：你可以从牌堆顶亮出一张牌置于你的武将牌上，称为“伤”，若“伤”的点数都不同，你不会死亡；若出现相同点数的“伤”，你进入濒死状态。每有三张“伤”，你的手牌上限就+1。
	状态：验证通过
]]
--
function Remove(SP)
	local room = SP:getRoom()
	local card_ids = SP:getPile("Plushurt")
	local re = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "PlusBuqu", "")
	local lack = 1 - SP:getHp()
	if lack <= 0 then
		local msg = sgs.LogMessage()
		msg.type = "$PlusBuqu_Remove"
		msg.from = SP
		for _, id in sgs.qlist(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			msg.card_str = card:toString()
			room:sendLog(msg)
			room:throwCard(card, re, nil)
		end
	else
		local to_remove = card_ids:length() - lack
		local msg = sgs.LogMessage()
		msg.type = "$PlusBuqu_Remove"
		msg.from = SP
		for var = 1, to_remove do
			if not card_ids:isEmpty() then
				room:fillAG(card_ids)
				local card_id = room:askForAG(SP, card_ids, false, "PlusBuqu")
				if card_id ~= -1 then
					msg.card_str = sgs.Sanguosha:getCard(card_id):toString()
					room:sendLog(msg)
					card_ids:removeOne(card_id)
					room:throwCard(sgs.Sanguosha:getCard(card_id), re, nil)
				end
				room:clearAG()
			end
		end
	end
end

PlusBuqu = sgs.CreateTriggerSkill {
	name = "PlusBuqu",
	events = { sgs.HpChanged, sgs.AskForPeachesDone },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() < 1 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					room:setTag(self:objectName(), sgs.QVariant(player:objectName()))
					local buqu = player:getPile("Plushurt")
					local lack = 1 - player:getHp()
					local n = lack - buqu:length()
					if n > 0 then
						local CAS = room:getNCards(n, false)
						for _, id in sgs.qlist(CAS) do
							player:addToPile("Plushurt", id)
						end
					end
					local buqun = player:getPile("Plushurt")
					local duplicate_numbers = sgs.IntList()
					local nub = {}
					for _, id in sgs.qlist(buqun) do
						local card = sgs.Sanguosha:getCard(id)
						local Nm = card:getNumber()
						if table.contains(nub, Nm) then
							duplicate_numbers:append(Nm)
						else
							table.insert(nub, Nm)
						end
					end
					if duplicate_numbers:isEmpty() then
						room:setTag(self:objectName(), sgs.QVariant())
						return true
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local buqun = player:getPile("Plushurt")
			if player:getHp() > 0 then
				return
			end
			if room:getTag(self:objectName()):toString() ~= player:objectName() then
				return
			end
			local duplicate_numbers = sgs.IntList()
			local nub = {}
			for _, id in sgs.qlist(buqun) do
				local card = sgs.Sanguosha:getCard(id)
				local Nm = card:getNumber()
				if table.contains(nub, Nm) and not duplicate_numbers:contains(Nm) then
					duplicate_numbers:append(Nm)
				else
					table.insert(nub, Nm)
				end
			end
			if duplicate_numbers:isEmpty() then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(player, "-dying")
				room:setPlayerFlag(player, "-Global_Dying")
				return true
			else
				local msg = sgs.LogMessage()
				msg.type = "#PlusBuqu_Duplicate"
				msg.from = player
				msg.arg = duplicate_numbers:length()
				room:sendLog(msg)
				local msg2 = sgs.LogMessage()
				msg2.type = "$PlusBuqu_DuplicateItem"
				local i = 0
				for _, num in sgs.qlist(duplicate_numbers) do
					i = i + 1
					msg.type = "#PlusBuqu_DuplicateGroup"
					msg.arg = i
					msg.arg2 = num
					room:sendLog(msg)
					for _, id in sgs.qlist(buqun) do
						if sgs.Sanguosha:getCard(id):getNumber() == num then
							msg2.card_str = sgs.Sanguosha:getCard(id):toString()
							room:sendLog(msg2)
						end
					end
				end
			end
		end
	end
}
PlusBuqu_Remove = sgs.CreateTriggerSkill {
	name = "#PlusBuqu_Remove",
	events = { sgs.HpRecover, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			if player:hasSkill("PlusBuqu") then
				if player:getPile("Plushurt"):length() > 0 then
					local recover = data:toRecover()
					local count = recover.recover
					for i = 1, count, 1 do
						Remove(player)
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == "PlusBuqu" then
				player:removePileByName("PlusBuqu")
				if player:getHp() <= 0 then
					room:enterDying(player, nil)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
PlusBuqu_Keep = sgs.CreateMaxCardsSkill {
	name = "#PlusBuqu_Keep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			local buqu = target:getPile("Plushurt")
			return (buqu:length() - 1) / 3
		end
	end
}
ZhouTai_Plus:addSkill(PlusBuqu)
ZhouTai_Plus:addSkill(PlusBuqu_Remove)
ZhouTai_Plus:addSkill(PlusBuqu_Keep)
extension:insertRelatedSkills("PlusBuqu", "#PlusBuqu_Remove")
extension:insertRelatedSkills("PlusBuqu", "#PlusBuqu_Keep")

--[[
	技能：PlusHuzhu
	附加技能：PlusHuzhu_Effect
	技能名：护主
	描述：当距离1以内的一名其他角色进入濒死状态时，你可以对自己造成1点伤害，视为你对该角色使用了一张【桃】。
	状态：验证通过
]]
--
PlusHuzhu = sgs.CreateTriggerSkill {
	name = "PlusHuzhu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local target = dying.who
		if target:getHp() <= 0 then
			if player:distanceTo(target) <= 1 and target:objectName() ~= player:objectName() then
				while target:getHp() <= 0 and room:askForSkillInvoke(player, self:objectName(), data) do
					local damage = sgs.DamageStruct()
					damage.card = nil
					damage.from = player
					damage.to = player
					room:damage(damage)
					if player:isAlive() then
						local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
						peach:setSkillName(self:objectName())
						peach:deleteLater()
						local use = sgs.CardUseStruct()
						use.card = peach
						use.from = player
						use.to:append(target)
						local jiaxu = room:getCurrent()
						if not (jiaxu:hasSkill("wansha") and target:objectName() ~= jiaxu:objectName()) then
							room:useCard(use)
						end
						if not target:hasFlag("PlusHuzhu_Succeed") then
							break
						end
						room:setPlayerFlag(target, "-PlusHuzhu_Succeed")
					else
						break
					end
				end
				return false
			end
		end
	end,
}
PlusHuzhu_Effect = sgs.CreateTriggerSkill {
	name = "#PlusHuzhu_Effect",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local target = effect.to
		local card = effect.card
		if target then
			if card:isKindOf("Peach") then
				if card:getSkillName() == "PlusHuzhu" then
					room:setPlayerFlag(target, "PlusHuzhu_Succeed")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -1
}
ZhouTai_Plus:addSkill(PlusHuzhu)
ZhouTai_Plus:addSkill(PlusHuzhu_Effect)
extension:insertRelatedSkills("PlusHuzhu", "#PlusHuzhu_Effect")

----------------------------------------------------------------------------------------------------

--[[ WU 011 孙坚
	武将：SunJian_Plus
	武将名：孙坚
	称号：武烈帝
	国籍：吴
	体力上限：4
	武将技能：
		英魂: 回合开始阶段开始时，若你已受伤，你可以选择一项：令一名其他角色摸X张牌，然后弃置一张牌；或令一名其他角色摸一张牌，然后弃置X张牌（X为你已损失的体力值）。
		庇佑(PlusBiyou)：主公技，当一名吴势力角色进入濒死状态时，其他体力值大于1的吴势力角色可以失去1点体力令其回复1点体力。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

SunJian_Plus = sgs.General(extension, "SunJian_Plus$", "wu", 4, true)

--[[
	技能：yinghun
	技能名：英魂
	描述：回合开始阶段开始时，若你已受伤，你可以选择一项：令一名其他角色摸X张牌，然后弃置一张牌；或令一名其他角色摸一张牌，然后弃置X张牌（X为你已损失的体力值）。
	状态：原有技能
]]
--
SunJian_Plus:addSkill("yinghun")

--[[
	技能：PlusBiyou
	技能名：庇佑
	描述：主公技，当一名吴势力角色进入濒死状态时，其他体力值大于1的吴势力角色可以失去1点体力令其回复1点体力。
	状态：验证通过
]]
--
PlusBiyou = sgs.CreateTriggerSkill {
	name = "PlusBiyou$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local target = dying.who
		if target:getKingdom() == "wu" and target:objectName() ~= player:objectName() then
			local dest = sgs.QVariant()
			dest:setValue(target)
			while target:getHp() <= 0 and player:getHp() > 1 do
				if room:askForSkillInvoke(player, self:objectName(), dest) then
					room:loseHp(player, 1)
					if player:isAlive() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(target, recover)
						if target:getHp() > 0 then
							return true
						end
					end
				else
					return false
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:getKingdom() == "wu"
		end
		return false
	end
}
SunJian_Plus:addSkill(PlusBiyou)

----------------------------------------------------------------------------------------------------

--[[ WU 012 顾雍
	武将：GuYong_Plus
	武将名：顾雍
	称号：一代名相
	国籍：吴
	体力上限：3
	武将技能：
		亮节(PlusLiangjie)：出牌阶段开始时，你可以展示所有手牌直到出牌阶段结束，然后你可以跳过你的弃牌阶段，并在回合结束阶段开始时摸一张牌。
		巧谏(PlusQiaojian)：一名角色的回合开始阶段开始时，若其判定区里有牌，你可以令其展示一张手牌，然后你可以弃置一张与此牌花色相同的手牌令该角色跳过判定阶段。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

GuYong_Plus = sgs.General(extension, "GuYong_Plus", "wu", 3, true)

--[[
	技能：PlusLiangjie
	技能名：亮节
	描述：出牌阶段开始时，你可以展示所有手牌直到出牌阶段结束，然后你可以跳过你的弃牌阶段，并在回合结束阶段开始时摸一张牌。
	状态：验证通过
	注：关于展示手牌（此处和倚天包贾文和不同），目前的处理方式：在出牌阶段开始时展示一次，之后每次获得牌或者背面朝上失去牌时再展示一次；
		发动亮节后，其他角色会获得技能洞察，此过程不会记入历史记录，且在出牌阶段结束时会失去。
]]
--
PlusLiangjie = sgs.CreateTriggerSkill {
	name = "PlusLiangjie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseChanging,
		sgs.Death },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if phase == sgs.Player_Play then
				if player:askForSkillInvoke(self:objectName()) then
					room:addPlayerMark(player, "&PlusLiangjie-Clear")
					room:setPlayerFlag(player, "PlusLiangjie")
					room:setPlayerFlag(player, "dongchaee")
					local tag = sgs.QVariant()
					tag:setValue(player)
					room:setTag("Dongchaee", tag)
					local players = room:getOtherPlayers(player)
					for _, p in sgs.qlist(players) do
						room:setPlayerFlag(p, "dongchaer")
						if not p:hasSkill("dongcha") then
							room:attachSkillToPlayer(p, "dongcha")
						else
							room:setPlayerFlag(p, "PlusLiangjie_Jiawenhe")
						end
						tag:setValue(p)
						room:setTag("Dongchaer", tag)
					end
					room:showAllCards(player)
				end
			elseif phase == sgs.Player_Finish then
				if player:hasFlag("PlusLiangjie") then
					room:drawCards(player, 1, self:objectName())
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if phase == sgs.Player_Play then
				if player:hasFlag("dongchaee") then
					room:setPlayerFlag(player, "-dongchaee")
					room:setTag("Dongchaee", sgs.QVariant())
					room:clearAG()
					room:setTag("Dongchaer", sgs.QVariant())
					local players = room:getOtherPlayers(player)
					for _, p in sgs.qlist(players) do
						room:clearAG()
						if not p:hasFlag("PlusLiangjie_Jiawenhe") then
							room:detachSkillFromPlayer(p, "dongcha", true)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_Discard then
				if player:hasFlag("PlusLiangjie") then
					if player:askForSkillInvoke(self:objectName()) then
						player:skip(sgs.Player_Discard)
					end
				else
					room:setPlayerFlag(player, "-PlusLiangjie")
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				if player:hasFlag("dongchaee") then
					room:setPlayerFlag(player, "-dongchaee")
					room:setTag("Dongchaee", sgs.QVariant())
					room:clearAG()
					room:setTag("Dongchaer", sgs.QVariant())
					local players = room:getOtherPlayers(player)
					for _, p in sgs.qlist(players) do
						room:clearAG()
						if not p:hasFlag("PlusLiangjie_Jiawenhe") then
							room:detachSkillFromPlayer(p, "dongcha", true)
						end
					end
				end
			end
		else
			if phase == sgs.Player_Play then
				if player:hasFlag("dongchaee") then
					local move = data:toMoveOneTime()
					if event == sgs.BeforeCardsMove then
						if move.from and move.from:objectName() == player:objectName() then
							if not move.open and move.to_place ~= sgs.Player_DiscardPile and move.to_place ~= sgs.Player_PlaceTable and move.to_place ~= sgs.Player_PlaceEquip then
								local card_ids = move.card_ids
								for _, card_id in sgs.qlist(card_ids) do
									if room:getCardPlace(card_id) == sgs.Player_PlaceHand then
										room:showCard(player, card_id)
									end
								end
							end
						end
					elseif event == sgs.CardsMoveOneTime then
						if move.to and move.to:objectName() == player:objectName() then
							if move.to_place == sgs.Player_PlaceHand then
								local card_ids = move.card_ids
								for _, card_id in sgs.qlist(card_ids) do
									room:showCard(player, card_id)
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
GuYong_Plus:addSkill(PlusLiangjie)

--[[
	技能：PlusQiaojian
	技能名：巧谏
	描述：一名角色的回合开始阶段开始时，若其判定区里有牌，你可以令其展示一张手牌，然后你可以弃置一张与此牌花色相同的手牌令该角色跳过判定阶段。
	状态：验证通过
]]
--
PlusQiaojian = sgs.CreateTriggerSkill {
	name = "PlusQiaojian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and not player:isKongcheng() then
			local guyongs = room:findPlayersBySkillName(self:objectName())
			for _, guyong in sgs.qlist(guyongs) do
				if room:askForSkillInvoke(guyong, self:objectName()) then
					local card = room:askForCardShow(player, guyong, self:objectName())
					local card_id = card:getEffectiveId()
					room:showCard(player, card_id)
					local suit = card:getSuitString()
					local prompt = string.format("@PlusQiaojian_Prompt:%s::%s", player:objectName(), suit)
					local pattern = string.format(".|%s|.|hand|.", suit)
					if room:askForCard(guyong, pattern, prompt, data, sgs.Card_MethodDiscard) then
						if not player:isSkipped(sgs.Player_Judge) then
							player:skip(sgs.Player_Judge)
						end
						break
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getJudgingArea():length() > 0
		end
		return false
	end
}
GuYong_Plus:addSkill(PlusQiaojian)

----------------------------------------------------------------------------------------------------

--[[ WU 013 孙鲁班
	武将：SunLuBan_Plus
	武将名：孙鲁班
	称号：吴全公主
	国籍：吴
	体力上限：3
	武将技能：
		谮毁(PlusZenhui)：出牌阶段，你可以选择两名体力值不相等的其他角色并将一张黑桃手牌交给其中体力值小的角色，然后其中体力值大的角色须选择一项：对体力值小的角色造成1点伤害，或弃置其两张手牌。每阶段限一次。
		嫁祸(PlusJiahuo)：当你成为【杀】的目标时，你可以将此【杀】转移给你攻击范围内的一名其他角色，该角色不得是此【杀】的使用者。此【杀】造成伤害后，你须将武将牌翻面。
	技能设计：小A
	状态：验证通过
]]
--

SunLuBan_Plus = sgs.General(extension, "SunLuBan_Plus", "wu", 3, false)

--[[
	技能：PlusZenhui
	技能名：谮毁
	描述：出牌阶段，你可以选择两名体力值不相等的其他角色并将一张黑桃手牌交给其中体力值小的角色，然后其中体力值大的角色须选择一项：对体力值小的角色造成1点伤害，或弃置其两张手牌。每阶段限一次。
	状态：验证通过
]]
--
PlusZenhui_DummyCard = sgs.CreateSkillCard {
	name = "PlusZenhui_DummyCard",
}
PlusZenhui_Card = sgs.CreateSkillCard {
	name = "PlusZenhui_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select == sgs.Self then
			return false
		elseif #targets == 0 then
			return true
		elseif #targets == 1 then
			local first = targets[1]
			return to_select:getHp() ~= first:getHp()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local playerA = targets[1]
		local playerB = targets[2]
		local from
		local to
		if playerA:getHp() > playerB:getHp() then
			from = playerA
			to = playerB
		else
			from = playerB
			to = playerA
		end
		to:obtainCard(self)
		local dest = sgs.QVariant()
		dest:setValue(to)
		local choice = room:askForChoice(from, "PlusZenhui", "PlusZenhui_Damage+PlusZenhui_Discard", dest)
		if choice == "PlusZenhui_Damage" then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = from
			damage.to = to
			room:damage(damage)
		elseif choice == "PlusZenhui_Discard" then
			local dummy = PlusZenhui_DummyCard:clone()
			if to:getHandcardNum() <= 2 then
				local handcards = to:getHandcards()
				for _, card in sgs.qlist(handcards) do
					dummy:addSubcard(card)
				end
			else
				local first = -1
				for i = 1, 2, 1 do
					local id = room:askForCardChosen(from, to, "h", self:objectName())
					while id == first do
						id = room:askForCardChosen(from, to, "h", self:objectName())
					end
					dummy:addSubcard(sgs.Sanguosha:getCard(id))
					first = id
				end
			end
			if dummy:subcardsLength() ~= 0 then
				room:throwCard(dummy, to, from)
			end
		end
	end
}
PlusZenhui = sgs.CreateViewAsSkill {
	name = "PlusZenhui",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusZenhui_Card:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusZenhui_Card")
	end
}
SunLuBan_Plus:addSkill(PlusZenhui)

--[[
	技能：PlusJiahuo
	技能名：嫁祸
	描述：当你成为【杀】的目标时，你可以将此【杀】转移给你攻击范围内的一名其他角色，该角色不得是此【杀】的使用者。此【杀】造成伤害后，你须将武将牌翻面。
	状态：验证通过
]]
--
PlusJiahuo_Card = sgs.CreateSkillCard {
	name = "PlusJiahuo_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("PlusJiahuo_Forbid") then
				if sgs.Self:inMyAttackRange(to_select) then
					return true
				end
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room = target:getRoom()
		room:setPlayerFlag(target, "PlusJiahuo_Target")
	end
}
PlusJiahuoVS = sgs.CreateViewAsSkill {
	name = "PlusJiahuo",
	n = 0,
	view_as = function(self, cards)
		return PlusJiahuo_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusJiahuo"
	end
}
PlusJiahuo = sgs.CreateTriggerSkill {
	name = "PlusJiahuo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming, sgs.Damage },
	view_as_skill = PlusJiahuoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				local slash = use.card
				local source = use.from
				local targets = use.to
				if slash and slash:isKindOf("Slash") then
					if targets:contains(player) then
						local players = room:getOtherPlayers(player)
						players:removeOne(source)
						room:setPlayerFlag(source, "LiuliSlashSource")
						local can_invoke = false
						room:setPlayerFlag(source, "PlusJiahuo_Forbid")
						for _, p in sgs.qlist(players) do
							if player:inMyAttackRange(p) then
								if source:canSlash(p, slash, false) then
									can_invoke = true
								else
									room:setPlayerFlag(p, "PlusJiahuo_Forbid")
								end
							end
						end
						if can_invoke then
							local cdata = sgs.QVariant()
							cdata:setValue(slash)

							room:setTag("liuli-card", cdata)
							local prompt = string.format("@PlusJiahuo:%s", source:objectName())
							if room:askForUseCard(player, "@PlusJiahuo", prompt) then
								for _, p in sgs.qlist(room:getAllPlayers()) do
									room:setPlayerFlag(p, "-PlusJiahuo_Forbid")
								end
								for _, p in sgs.qlist(players) do
									if p:hasFlag("PlusJiahuo_Target") then
										local new_targets = sgs.SPlayerList()
										for _, t in sgs.qlist(targets) do
											if t:objectName() == player:objectName() then
												new_targets:append(p)
											else
												new_targets:append(t)
											end
										end
										use.from = source
										use.to = new_targets
										use.card = slash
										data:setValue(use)
										room:setCardFlag(slash, "PlusJiahuo_Slash")
										room:setCardFlag(slash, "PlusJiahuo_Slash" ..
											player:objectName() .. p:objectName())
										room:setPlayerFlag(p, "-PlusJiahuo_Target")
										return true
									end
								end
							end
							room:removeTag("liuli-card")
						end
						room:setPlayerFlag(source, "-LiuliSlashSource")
						for _, p in sgs.qlist(room:getAllPlayers()) do
							room:setPlayerFlag(p, "-PlusJiahuo_Forbid")
						end
					end
				end
				return false
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local card = damage.card
			if card and card:hasFlag("PlusJiahuo_Slash") then
				for _, sunluban in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if card:hasFlag("PlusJiahuo_Slash" .. sunluban:objectName() .. p:objectName()) then
							sunluban:turnOver()
						end
					end
				end
				room:setCardFlag(card, "-PlusJiahuo_Slash")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
SunLuBan_Plus:addSkill(PlusJiahuo)


----------------------------------------------------------------------------------------------------
--                                             群
----------------------------------------------------------------------------------------------------


--[[ QUN 001 吕布
	武将：LvBu_Plus
	武将名：吕布
	称号：飞将
	国籍：群
	体力上限：4
	武将技能：
		无双：锁定技，当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
		射戟(PlusSheji)：你可以将所有手牌当【杀】使用或打出，且此【杀】具有以下效果：无距离限制；不计入出牌阶段内的使用次数限制；可以额外指定一个目标。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

LvBu_Plus = sgs.General(extension, "LvBu_Plus", "qun", 4, true)

--[[
	技能：wushuang
	技能名：无双
	描述：锁定技，当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
	状态：原有技能
]]
--
LvBu_Plus:addSkill("wushuang")

--[[
	技能：PlusSheji
	技能名：射戟
	描述：你可以将所有手牌当【杀】使用或打出，且此【杀】具有以下效果：无距离限制；不计入出牌阶段内的使用次数限制；可以额外指定一个目标。
	状态：验证通过
	注：若吕布发动射戟之后，关平发动龙吟，则杀的使用次数-1。由于关平尚未定稿，因此暂时不算做BUG；
		个别时候，此技能无法发动。
]]
--
PlusShejiVS = sgs.CreateViewAsSkill {
	name = "PlusSheji",
	n = 0,
	view_as = function(self, cards)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:isKongcheng()
	end
}
PlusSheji = sgs.CreateTriggerSkill {
	name = "PlusSheji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.PreCardUsed },
	view_as_skill = PlusShejiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				if use.card:getSkillName() == self:objectName() then
					if (use.m_addHistory) then
						room:addPlayerHistory(player, use.card:getClassName(), -1)
						room:sendCompulsoryTriggerLog(player, self:objectName(), true)
						use.m_addHistory = false
						data:setValue(use)
					end
				end
			end
		end
	end,
}
PlusSheji_Target = sgs.CreateTargetModSkill {
	name = "#PlusSheji_Target",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "PlusSheji" then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player, card)
		if card:getSkillName() == "PlusSheji" then
			return 1
		else
			return 0
		end
	end,
	residue_func = function(self, player, card)
		if player:hasSkill("PlusSheji") and card:getSkillName() == "PlusSheji" then
			return 999
		end
	end,
}
LvBu_Plus:addSkill(PlusSheji)
LvBu_Plus:addSkill(PlusSheji_Target)
extension:insertRelatedSkills("PlusSheji", "#PlusSheji_Target")

----------------------------------------------------------------------------------------------------

--[[ QUN 002 貂蝉
	武将：DiaoChan_Plus
	武将名：貂蝉
	称号：绝世的舞姬
	国籍：群
	体力上限：3
	武将技能：
		离间：出牌阶段，你可以弃置一张牌并选择两名男性角色，视为其中一名男性角色对另一名男性角色使用一张【决斗】。此【决斗】不能被【无懈可击】响应。每阶段限一次。
		闭月：回合结束阶段开始时，你可以摸一张牌。
	技能设计：官方
	状态：验证通过
]]
--



--[[
	技能：lijian
	技能名：离间
	描述：出牌阶段，你可以弃置一张牌并选择两名男性角色，视为其中一名男性角色对另一名男性角色使用一张【决斗】。此【决斗】不能被【无懈可击】响应。每阶段限一次。
	状态：原有技能
]]
--


--[[
	技能：biyue
	技能名：闭月
	描述：回合结束阶段开始时，你可以摸一张牌。
	状态：原有技能
]]
--


----------------------------------------------------------------------------------------------------

--[[ QUN 003 华佗
	武将：HuaTuo_Plus
	武将名：华佗
	称号：乱世神医
	国籍：群
	体力上限：3
	武将技能：
		麻沸(PlusMafei)：当一名角色进入濒死状态时，你可以弃置一张红色牌，令其回复1点体力，然后【杀】或非延时类锦囊牌对该角色无效，直到该回合结束。
		悬壶(PlusXuanhu)：出牌阶段，你可以弃置一张手牌，令一名已受伤的角色回复1点体力。每阶段限一次。
		青囊(PlusQingnang)：你的回合外，当你死亡时，你可以令一名你死亡前距离为1的角色（杀死你的角色除外）选择一项：加1点体力上限，或失去1点体力并获得技能“悬壶”。
	技能设计：路西法
	状态：验证通过
]]
--

HuaTuo_Plus = sgs.General(extension, "HuaTuo_Plus", "qun", 3, true)

--[[  askForCard优化
	技能：PlusMafei
	技能名：麻沸
	描述：当一名角色进入濒死状态时，你可以弃置一张红色牌，令其回复1点体力，然后【杀】或非延时类锦囊牌对该角色无效，直到该回合结束。
	状态：验证通过
]]
--
PlusMafei_Card = sgs.CreateSkillCard {
	name = "PlusMafei_Card",
	target_fixed = true,
	will_throw = true,
}
PlusMafeiVS = sgs.CreateViewAsSkill {
	name = "PlusMafei",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusMafei_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusMafei"
	end
}
PlusMafei = sgs.CreateTriggerSkill {
	name = "PlusMafei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying, sgs.CardEffected, sgs.EventPhaseStart },
	view_as_skill = PlusMafeiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local dying = data:toDying()
				local target = dying.who
				while target:getHp() <= 0 do
					if not player:isNude() then
						local card = room:askForCard(player, "@PlusMafei", "@PlusMafei_Prompt", data,
							sgs.Card_MethodDiscard)
						if card then
							room:broadcastSkillInvoke(self:objectName())
							local msg = sgs.LogMessage()
							msg.type = "#InvokeSkill"
							msg.from = player
							msg.arg = self:objectName()
							room:sendLog(msg)
							local recover = sgs.RecoverStruct()
							recover.card = card
							recover.who = player
							room:recover(target, recover)
							local current = room:getCurrent() --保证在一名角色的回合内
							if current and not current:isDead() then
								msg.type = "#PlusMafei_Damaged"
								msg.from = target
								msg.arg = self:objectName()
								room:sendLog(msg)
								room:setPlayerFlag(target, "PlusMafei")
								room:setPlayerMark(target, "&PlusMafei+to+#" .. player:objectName() .. "-Clear", 1)
							end
						else
							break
						end
					else
						break
					end
				end
			end
		elseif event == sgs.CardEffected then
			if player:hasFlag("PlusMafei") then
				local effect = data:toCardEffect()
				local card = effect.card
				if card:isKindOf("Slash") or card:isNDTrick() then
					local msg = sgs.LogMessage()
					msg.type = "#PlusMafei_Avoid"
					msg.from = player
					msg.arg = self:objectName()
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("PlusMafei") then
						room:setPlayerFlag(p, "-PlusMafei")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
HuaTuo_Plus:addSkill(PlusMafei)

--[[
	技能：PlusXuanhu
	技能名：悬壶
	描述：出牌阶段，你可以弃置一张手牌，令一名已受伤的角色回复1点体力。每阶段限一次。
	状态：验证通过
]]
--
PlusXuanhu_Card = sgs.CreateSkillCard {
	name = "PlusXuanhu_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:isWounded()
		end
		return false
	end,
	feasible = function(self, targets)
		if #targets == 1 then
			return targets[1]:isWounded()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local effect = sgs.CardEffectStruct()
		effect.card = self
		effect.from = source
		effect.to = target
		room:cardEffect(effect)
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		local room = dest:getRoom()
		room:broadcastSkillInvoke("PlusXuanhu")
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(dest, recover)
	end
}
PlusXuanhu = sgs.CreateViewAsSkill {
	name = "PlusXuanhu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local qn_card = PlusXuanhu_Card:clone()
			qn_card:addSubcard(card)
			return qn_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusXuanhu_Card")
	end
}
HuaTuo_Plus:addSkill(PlusXuanhu)

--[[
	技能：PlusQingnang
	技能名：青囊
	描述：你的回合外，当你死亡时，你可以令一名你死亡前距离为1的角色（杀死你的角色除外）选择一项：加1点体力上限，或失去1点体力并获得技能“悬壶”。
	状态：验证通过
]]
--
--[[QingnangDistance = function(alive, huatuo, target)  此函数由于未知原因无效
	if huatuo:objectName() == target:objectName() then
		return 0
	end
	local huatuo_no = huatuo:getSeat()
	local target_no = target:getSeat()
	if target_no >= huatuo_no then
		target_no = target_no + 1
	end
	local total = alive + 1
	if target_no <= huatuo_no then
		local left_dis = math.abs(huatuo_no - total - target_no)
	else
		local left_dis = math.abs(huatuo_no + total - target_no)
	end
	local right_dis = math.abs(huatuo_no - target_no)
	local basic_dis = math.min(left_dis, right_dis)
	local final_dis = basic_dis + sgs.Sanguosha:correctDistance(huatuo, target)
	return math.max(1, final_dis)
end]]
PlusQingnang = sgs.CreateTriggerSkill {
	name = "PlusQingnang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				local damage = death.damage
				local targets = sgs.SPlayerList()
				local killer = nil
				if damage then
					killer = damage.from
				end
				local msg = sgs.LogMessage()
				local alive = room:alivePlayerCount()
				local huatuo_no = 0
				local target_no = 0
				local total = alive + 1
				local left_dis = 0
				local right_dis = 0
				local basic_dis = 0
				local final_dis = 0

				for _, t in sgs.qlist(room:getAlivePlayers()) do
					huatuo_no = player:getSeat()
					target_no = t:getSeat()
					if target_no >= huatuo_no then
						target_no = target_no + 1
					end
					if target_no <= huatuo_no then
						left_dis = huatuo_no - total - target_no
					else
						left_dis = huatuo_no + total - target_no
					end
					left_dis = math.abs(left_dis)
					right_dis = huatuo_no - target_no
					left_dis = math.min(left_dis, math.abs(right_dis))
					final_dis = math.max(1, left_dis + sgs.Sanguosha:correctDistance(player, t))
					if final_dis == 1 and (not killer or t:objectName() ~= killer:objectName()) then
						targets:append(t)
					end
				end
				if targets:length() > 0 then
					--if player:askForSkillInvoke(self:objectName(), data) then
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "PlusQingnang-invoke",
						true, true)
					if target then
						local dest = sgs.QVariant()
						dest:setValue(target)
						local choice = room:askForChoice(target, self:objectName(),
							"PlusQingnang_choice1+PlusQingnang_choice2", dest)
						if choice == "PlusQingnang_choice1" then
							local maxhp = target:getMaxHp()
							local value = sgs.QVariant(maxhp + 1)
							room:setPlayerProperty(target, "maxhp", value)
							local msg = sgs.LogMessage()
							msg.type = "#PlusQingnang_MaxHp"
							msg.from = target
							msg.arg = 1
							room:sendLog(msg)
						elseif choice == "PlusQingnang_choice2" then
							room:loseHp(target, 1)
							if target:isAlive() then
								room:acquireSkill(target, "PlusXuanhu")
							end
						end
						return false
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
HuaTuo_Plus:addSkill(PlusQingnang)
--[[
	青囊计算距离的方法说明：
	死亡结算一旦开始，角色即死亡，不再参与到距离结算中。
	具体到太阳神三国杀，3号位华佗死亡，4号位角色的座位编号改为3，以此类推。此时3号位华佗到原5号位角色的距离变为1,4号位角色到原5号位角色的距离为1.
	但是这给青囊的距离结算带来了麻烦，在Death中得到的距离实际是华佗下家的距离。（无视华佗下家的技能，但是考虑华佗的技能和马）
	
	于是我们写了一段很长的代码计算华佗到其它角色的距离。
	在这段代码中，模拟实际计算距离的过程，先找出华佗和目标角色的位置编号。
	若目标角色的位置编号>=华佗，则其编号+1。
	然后参考距离计算，找出左右距离，加上距离修正，最后得出结果。
]]
--

----------------------------------------------------------------------------------------------------

--[[ QUN 004 张角
	武将：ZhangJiao_Plus
	武将名：张角
	称号：天公将军
	国籍：群
	体力上限：3
	武将技能：
		鬼道(PlusGuidao)：在一名角色的判定牌或拼点牌（限其中一名角色）生效前，你可以用一张黑色牌替换之。
		雷击(PlusLeiji)：你的回合外，当你因使用、打出或弃置而失去一张【闪】时，可令一名角色判定，若结果为黑桃，你对该角色造成2点雷电伤害。
		黄天(PlusHuangtian)：主公技，其他群雄角色可以在他们各自的出牌阶段内交给你一张【闪】、【闪电】或雷【杀】。每阶段限一次。
	技能设计：一品海之蓝
	状态：验证通过
]]
--

ZhangJiao_Plus = sgs.General(extension, "ZhangJiao_Plus$", "qun", 3, true)

--[[
	技能：PlusGuidao
	技能名：鬼道
	描述：在一名角色的判定牌或拼点牌（限其中一名角色）生效前，你可以用一张黑色牌替换之。
	状态：验证通过
]]
--
sgs.PlusGuidao_Pattern = "pattern"
PlusGuidao_DummyCard = sgs.CreateSkillCard {
	name = "PlusGuidao_DummyCard",
	target_fixed = true,
	will_throw = false,
}
PlusGuidao_Card = sgs.CreateSkillCard {
	name = "PlusGuidao_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:hasFlag("PlusGuidao_Source") or to_select:hasFlag("PlusGuidao_Target")
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setPlayerFlag(target, "PlusGuidao_Modify")
		local card_id = effect.card:getSubcards():first()
		room:setTag("PlusGuidao_Card", sgs.QVariant(card_id))
	end,
}
PlusGuidaoVS = sgs.CreateViewAsSkill {
	name = "PlusGuidao",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isBlack()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = nil
		if sgs.PlusGuidao_Pattern == "@PlusGuidao1" then
			card = PlusGuidao_DummyCard:clone()
		elseif sgs.PlusGuidao_Pattern == "@PlusGuidao2" then
			card = PlusGuidao_Card:clone()
		end
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		sgs.PlusGuidao_Pattern = pattern
		return pattern == "@PlusGuidao1" or pattern == "@PlusGuidao2"
	end
}
PlusGuidao = sgs.CreateTriggerSkill {
	name = "PlusGuidao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial, sgs.PindianVerifying },
	view_as_skill = PlusGuidaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				if not player:isNude() then
					local judge = data:toJudge()
					local prompt = string.format("@PlusGuidao-card:%s:%s:%s", judge.who:objectName(), self:objectName(),
						judge.reason) --%src,%dest,%arg
					local card = room:askForCard(player, "@PlusGuidao1", prompt, data, sgs.Card_MethodResponse, nil, true)
					if card then
						room:broadcastSkillInvoke(self:objectName())
						room:retrial(card, player, judge, self:objectName(), true)
					end
					return false
				end
			end
		elseif event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			local room = player:getRoom()
			local zhangjiao = room:findPlayerBySkillName(self:objectName())
			if zhangjiao then
				if not zhangjiao:isNude() then
					local source = pindian.from
					local target = pindian.to
					room:setTag("CurrentPindianStruct", data)
					room:setPlayerFlag(source, "PlusGuidao_Source")
					room:setPlayerFlag(target, "PlusGuidao_Target")
					local prompt = string.format("@PlusGuicai_Pindian::%s:%s", self:objectName(), pindian.reason)
					room:askForUseCard(zhangjiao, "@PlusGuidao2", prompt)
					room:setPlayerFlag(source, "-PlusGuidao_Source")
					room:setPlayerFlag(target, "-PlusGuidao_Target")
					room:removeTag("CurrentPindianStruct")
					local card_id = room:getTag("PlusGuidao_Card"):toInt()
					local card = sgs.Sanguosha:getCard(card_id)
					if card then
						room:broadcastSkillInvoke(self:objectName())
						local dest
						local oldcard
						if source:hasFlag("PlusGuidao_Modify") then
							dest = source
							oldcard = pindian.from_card
							pindian.from_card = card
							pindian.from_number = card:getNumber()
						elseif target:hasFlag("PlusGuidao_Modify") then
							dest = target
							oldcard = pindian.to_card
							pindian.to_card = card
							pindian.to_number = card:getNumber()
						else 
							return
						end

						local move = sgs.CardsMoveStruct()
						move.card_ids:append(card_id)
						move.to = dest
						move.to_place = sgs.Player_PlaceTable
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RESPONSE, zhangjiao:objectName())
						local move2 = sgs.CardsMoveStruct()
						move2.card_ids:append(oldcard:getEffectiveId())
						move2.to = zhangjiao
						move2.to_place = sgs.Player_PlaceHand
						move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE, zhangjiao:objectName())
						local moves = sgs.CardsMoveList()
						moves:append(move)
						moves:append(move2)
						room:moveCardsAtomic(moves, true)

						local msg = sgs.LogMessage()
						msg.type = "$PlusGuicai_PindianOne"
						msg.from = zhangjiao
						msg.to:append(dest)
						msg.arg = self:objectName()
						msg.card_str = card:toString()
						room:sendLog(msg)
						data:setValue(pindian)
						local msg = sgs.LogMessage()
						msg.type = "$PlusGuicai_PindianFinal"
						msg.from = source
						msg.card_str = pindian.from_card:toString()
						room:sendLog(msg)
						msg.from = target
						msg.card_str = pindian.to_card:toString()
						room:sendLog(msg)
					end
					room:removeTag("PlusGuidao_Card")
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
ZhangJiao_Plus:addSkill(PlusGuidao)

--[[
	技能：PlusLeiji
	技能名：雷击
	描述：你的回合外，当你因使用、打出或弃置而失去一张【闪】时，可令一名角色判定，若结果为黑桃，你对该角色造成2点雷电伤害。
	状态：验证通过
]]
--
PlusLeiji_Card = sgs.CreateSkillCard {
	name = "PlusLeiji_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:broadcastSkillInvoke("PlusLeiji")
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|spade"
		judge.good = false
		judge.reason = self:objectName()
		judge.who = target
		judge.play_animation = true
		judge.negative = true
		room:judge(judge)
		if judge:isBad() then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.damage = 2
			damage.from = source
			damage.to = target
			damage.nature = sgs.DamageStruct_Thunder
			room:damage(damage)
		else
			room:setEmotion(source, "bad")
		end
	end
}
PlusLeijiVS = sgs.CreateViewAsSkill {
	name = "PlusLeiji",
	n = 0,
	view_as = function(self, cards)
		return PlusLeiji_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusLeiji"
	end
}
PlusLeiji = sgs.CreateTriggerSkill {
	name = "PlusLeiji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.CardResponded, sgs.CardFinished, sgs.CardUsed },
	view_as_skill = PlusLeijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() ~= sgs.Player_NotActive then
				return false
			end
			if event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() then
					if event == sgs.BeforeCardsMove then
						local reason = move.reason
						local basic = bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
						--local flag = (basic == sgs.CardMoveReason_S_REASON_USE)
						--flag = flag or (basic == sgs.CardMoveReason_S_REASON_DISCARD)
						--flag = flag or (basic == sgs.CardMoveReason_S_REASON_RESPONSE)
						--if flag then
						if basic == sgs.CardMoveReason_S_REASON_DISCARD then
							local card
							local i = 0
							for _, card_id in sgs.qlist(move.card_ids) do
								card = sgs.Sanguosha:getCard(card_id)
								if card:isKindOf("Jink") then
									local places = move.from_places:at(i)
									if places == sgs.Player_PlaceHand or places == sgs.Player_PlaceEquip then
										player:addMark(self:objectName())
									end
								end
								i = i + 1
							end
						elseif basic == sgs.CardMoveReason_S_REASON_RESPONSE or basic == sgs.CardMoveReason_S_REASON_USE then --确保此牌来自手牌
							local i = 0
							for _, card_id in sgs.qlist(move.card_ids) do
								local card = sgs.Sanguosha:getCard(card_id)
								local places = move.from_places:at(i)
								if places == sgs.Player_PlaceHand or places == sgs.Player_PlaceEquip then
									player:addMark("PlusLeiji_Lose")
								end
								i = i + 1
							end
						end
					else
						local count = player:getMark(self:objectName())
						for i = 1, count, 1 do
							if not room:askForUseCard(player, "@PlusLeiji", "@PlusLeiji") then
								break
							end
						end
						player:setMark(self:objectName(), 0)
					end
				end
			elseif (event == sgs.CardResponded or event == sgs.CardUsed) then
				local card
				if event == sgs.CardResponded then
					card = data:toCardResponse().m_card
				elseif event == sgs.CardUsed then
					card = data:toCardUse().card
				end
				if card and card:isKindOf("Jink") and player:getMark("PlusLeiji_Lose") > 0 then
					room:askForUseCard(player, "@PlusLeiji", "@PlusLeiji")
				end
				player:setMark("PlusLeiji_Lose", 0)
				return false
			end
		end
		if event == sgs.CardFinished then
			player:setMark("PlusLeiji_Lose", 0)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 3
}
ZhangJiao_Plus:addSkill(PlusLeiji)

--[[
	技能：PlusHuangtian
	附加技能：PlusHuangtianQun
	技能名：黄天
	描述：主公技，其他群雄角色可以在他们各自的出牌阶段内交给你一张【闪】、【闪电】或雷【杀】。每阶段限一次。
	状态：验证通过
]]
--
PlusHuangtian_Card = sgs.CreateSkillCard {
	name = "PlusHuangtian_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasLordSkill("PlusHuangtian") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					return not to_select:hasFlag("PlusHuangtianInvoked")
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("PlusHuangtian") then
			room:setPlayerFlag(zhangjiao, "PlusHuangtianInvoked")
			room:broadcastSkillInvoke("PlusHuangtian")
			zhangjiao:obtainCard(self)
			local subcards = self:getSubcards()
			for _, card_id in sgs.qlist(subcards) do
				room:setCardFlag(card_id, "visible")
			end
			room:setEmotion(zhangjiao, "good")
			local zhangjiaos = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _, p in sgs.qlist(players) do
				if p:hasLordSkill("PlusHuangtian") then
					if not p:hasFlag("PlusHuangtianInvoked") then
						zhangjiaos:append(p)
					end
				end
			end
			if zhangjiaos:length() == 0 then
				room:setPlayerFlag(source, "ForbidPlusHuangtian")
			end
		end
	end
}
PlusHuangtianQun = sgs.CreateViewAsSkill {
	name = "PlusHuangtianQun&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "jink" or to_select:objectName() == "lightning" or
			to_select:objectName() == "thunder_slash"
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusHuangtian_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "qun" then
			return not player:hasFlag("ForbidPlusHuangtian")
		end
		return false
	end
}
PlusHuangtian = sgs.CreateTriggerSkill {
	name = "PlusHuangtian$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasLordSkill(self:objectName()) then
			local others = room:getOtherPlayers(player)
			for _, p in sgs.qlist(others) do
				if not p:hasSkill("PlusHuangtianQun") then
					room:attachSkillToPlayer(p, "PlusHuangtianQun")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("ForbidPlusHuangtian") then
					room:setPlayerFlag(player, "-ForbidPlusHuangtian")
				end
				local players = room:getOtherPlayers(player)
				for _, p in sgs.qlist(players) do
					if p:hasFlag("PlusHuangtianInvoked") then
						room:setPlayerFlag(p, "-PlusHuangtianInvoked")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhangJiao_Plus:addSkill(PlusHuangtian)
local skill = sgs.Sanguosha:getSkill("PlusHuangtianQun")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(PlusHuangtianQun)
	sgs.Sanguosha:addSkills(skillList)
end

----------------------------------------------------------------------------------------------------

--[[ QUN 005 于吉
	武将：YuJi_Plus
	武将名：于吉
	称号：太平道人
	国籍：群
	体力上限：3
	武将技能：
		蛊惑：你可以说出任何一种基本牌或非延时类锦囊牌，并正面朝下使用或打出一张手牌。若无人质疑，则该牌按你所述之牌结算。若有人质疑则亮出验明：若为真，质疑者各失去1点体力：若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真时，该牌仍然可以进行结算，否则无论真假，将该牌置入弃牌堆。
		魂咒(PlusHunzhou)：锁定技，当你死亡时，杀死你的角色减1点体力上限。
	技能设计：dismalance
	状态：验证通过
]]
--

YuJi_Plus = sgs.General(extension, "YuJi_Plus", "qun", 3, true)

--[[
	技能：guhuo
	技能名：蛊惑
	描述：你可以说出任何一种基本牌或非延时类锦囊牌，并正面朝下使用或打出一张手牌。若无人质疑，则该牌按你所述之牌结算。若有人质疑则亮出验明：若为真，质疑者各失去1点体力：若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真时，该牌仍然可以进行结算，否则无论真假，将该牌置入弃牌堆。
	状态：原有技能
]]
--
YuJi_Plus:addSkill("guhuo")

--[[
	技能：PlusHunzhou
	技能名：魂咒
	描述：锁定技，当你死亡时，杀死你的角色减1点体力上限。
	状态：验证通过
]]
--
PlusHunzhou = sgs.CreateTriggerSkill {
	name = "PlusHunzhou",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local damage = death.damage
			if damage then
				local murderer = damage.from
				if murderer then
					local room = player:getRoom()
					local msg = sgs.LogMessage()
					msg.type = "#PlusHunzhou"
					msg.from = player
					msg.to:append(murderer)
					msg.arg = self:objectName()
					room:sendLog(msg)
					room:loseMaxHp(murderer)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
YuJi_Plus:addSkill(PlusHunzhou)

----------------------------------------------------------------------------------------------------

--[[ QUN 006 公孙瓒
	武将：GongSunZan_Plus
	武将名：公孙瓒
	称号：白马将军
	国籍：群
	体力上限：4
	武将技能：
		义从(PlusYicong)：锁定技，若你当前的体力值大于2，你计算的与其他角色的距离-X；若你当前的体力值小于或等于2，其他角色计算的与你的距离+X。（X为场上装备区内的坐骑牌的数量+1，且最多为4）
	技能设计：小A
	状态：验证通过
]]
--

GongSunZan_Plus = sgs.General(extension, "GongSunZan_Plus", "qun", 4, true)

--[[
	技能：PlusYicong
	技能名：义从
	描述：锁定技，若你当前的体力值大于2，你计算的与其他角色的距离-X；若你当前的体力值小于或等于2，其他角色计算的与你的距离+X。（X为场上装备区内的坐骑牌的数量+1，且最多为4）
	状态：验证通过
	注：由于循环次数较多，个别时候可能会导致运行缓慢；
		一名角色使用、打出或弃置坐骑牌选择目标时，X依然会包括这张坐骑牌；
		小型场景模式开始时，若设置了初始装备，其中的坐骑牌在刚开始不会被算入X中。
]]
--
PlusYicong = sgs.CreateDistanceSkill {
	name = "PlusYicong",
	correct_func = function(self, from, to)
		local room = sgs.Sanguosha:currentRoom()
		if from:hasSkill(self:objectName()) then
			if from:getHp() > 2 then
				return -(from:getMark("&PlusYicong"))
			end
		end
		if to:hasSkill(self:objectName()) then
			if to:getHp() <= 2 then
				return to:getMark("&PlusYicong")
			end
		end
		return 0
	end
}
PlusYicong_Count = sgs.CreateTriggerSkill {
	name = "#PlusYicong_Count",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip) or move.to_place == sgs.Player_PlaceEquip then
			local count = 0
			local players = room:getAllPlayers()
			for _, p in sgs.qlist(players) do
				if p:getDefensiveHorse() then
					count = count + 1
				end
				if p:getOffensiveHorse() then
					count = count + 1
				end
			end
			if count ~= player:getMark("&PlusYicong") then
				local index
				if player:getHp() > 2 then
					index = 1
				else
					index = 2
				end
				room:broadcastSkillInvoke("PlusYicong", index)
			end
			room:setPlayerMark(player, "&PlusYicong", math.min(count, 3) + 1) --本来想用全局变量。。又失败了
		end
	end
}
PlusYicong_Audio = sgs.CreateTriggerSkill {
	name = "#PlusYicong_Audio",
	events = { sgs.PreHpReduced, sgs.PreHpLost, sgs.PostHpReduced, sgs.HpRecover },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreHpReduced or event == sgs.PreHpLost then
			local lost = 0
			if event == sgs.PreHpReduced then
				lost = data:toDamage().damage
			else
				lost = data:toInt()
			end
			room:setPlayerMark(player, "PlusYicong_Lost", lost)
		else
			local hp = player:getHp()
			local index = 0
			if event == sgs.HpRecover then
				local recover = data.toRecover()
				if hp > 2 and hp - recover.recover <= 2 then
					index = 1
				end
			elseif event == sgs.PostHpReduced then
				local lost = player:getMark("PlusYicong_Lost")
				if lost > 0 then
					room:setPlayerMark(player, "PlusYicong_Lost", 0)
					if hp <= 2 and hp + lost > 2 then
						index = 2
					end
				end
			end
			if index > 0 then
				room:broadcastSkillInvoke("PlusYicong", index)
			end
			return false
		end
	end
}
GongSunZan_Plus:addSkill(PlusYicong)
GongSunZan_Plus:addSkill(PlusYicong_Count)
GongSunZan_Plus:addSkill(PlusYicong_Audio)
extension:insertRelatedSkills("PlusYicong", "#PlusYicong_Count")
extension:insertRelatedSkills("PlusYicong", "#PlusYicong_Audio")

----------------------------------------------------------------------------------------------------

--[[ QUN 007 华雄
	武将：HuaXiong_Plus
	武将名：华雄
	称号：魔将
	国籍：群
	体力上限：6
	武将技能：
		恃勇(PlusShiyong)：锁定技，每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你须摸一张牌，然后弃置两张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

HuaXiong_Plus = sgs.General(extension, "HuaXiong_Plus", "qun", 6, true)

--[[
	技能：PlusShiyong
	技能名：恃勇
	描述：锁定技，每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你须摸一张牌，然后弃置两张牌。
	状态：验证通过
]]
--
PlusShiyong = sgs.CreateTriggerSkill {
	name = "PlusShiyong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local slash = damage.card
		if slash then
			if slash:isKindOf("Slash") then
				if slash:isRed() or slash:hasFlag("drank") then
					local room = player:getRoom()
					local index = 1
					if string.find(damage.to:getGeneralName(), "guanyu") or string.find(damage.to:getGeneralName(), "GuanYu_Plus") then
						index = 3
					elseif slash:hasFlag("drank") then
						index = 2
					end
					room:broadcastSkillInvoke(self:objectName(), index)
					local msg = sgs.LogMessage()
					msg.type = "#TriggerSkill"
					msg.from = player
					msg.arg = self:objectName()
					room:sendLog(msg)
					room:drawCards(player, 1, self:objectName())
					room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				end
			end
		end
		return false
	end
}
HuaXiong_Plus:addSkill(PlusShiyong)

----------------------------------------------------------------------------------------------------

--[[ QUN 008 刘协
	武将：LiuXie_Plus
	武将名：刘协
	称号：汉献帝
	国籍：群
	体力上限：3
	武将技能：
		密诏(PlusMizhao)：出牌阶段，你可以将至少三张牌交给一名其他角色，该角色选择一项：1. 视为对其攻击范围内你选择的另一名角色使用一张【杀】，若该【杀】被【闪】抵消，其须失去1点体力。2. 摸一张牌然后将其武将牌翻面。每阶段限一次。
		正统(PlusZhengtong)：回合开始阶段开始时，你可以弃置一张红色牌并声明一项其他武将的主公技（限定技、觉醒技除外），你视为拥有该技能，直到你的下回合开始。
		挟驾(PlusXiejia)：锁定技，摸牌阶段开始时，若此时场上手牌数最多的角色仅有一名且不是你，你须放弃摸牌，改为该角色摸两张牌，再将两张牌交给你。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

LiuXie_Plus = sgs.General(extension, "LiuXie_Plus$", "qun", 3, true)

--[[
	技能：PlusMizhao
	技能名：密诏
	描述：出牌阶段，你可以将至少三张牌交给一名其他角色，该角色选择一项：1. 视为对其攻击范围内你选择的另一名角色使用一张【杀】，若该【杀】被【闪】抵消，其须失去1点体力。2. 摸一张牌然后将其武将牌翻面。每阶段限一次。
	状态：验证通过
]]
--
PlusMizhao_Card = sgs.CreateSkillCard {
	name = "PlusMizhao_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		local source = effect.from
		source:obtainCard(self) --防止卡牌被选择时出现的崩溃
		local room = dest:getRoom()
		local index = 1
		if string.find(effect.to:getGeneralName(), "liubei") or string.find(effect.to:getGeneralName(), "LiuBei_Plus") then
			index = 2
		end
		room:broadcastSkillInvoke("PlusMizhao", index)
		local can_use = false
		local targets = sgs.SPlayerList()
		local list = room:getOtherPlayers(dest)
		for _, p in sgs.qlist(list) do
			if dest:canSlash(p) then
				targets:append(p)
				can_use = true
			end
		end
		local target
		local choicelist = {}
		table.insert(choicelist, "PlusMizhao_Draw")
		local victim = sgs.QVariant()
		if can_use then
			target = room:askForPlayerChosen(source, targets, self:objectName())
			victim:setValue(target)
			table.insert(choicelist, "PlusMizhao_Use")
			local msg = sgs.LogMessage()
			msg.type = "#CollateralSlash"
			msg.from = source
			msg.to:append(target)
			room:sendLog(msg)
		end
		dest:obtainCard(self)
		local choice
		if #choicelist > 1 then
			choice = room:askForChoice(dest, self:objectName(), "PlusMizhao_Use+PlusMizhao_Draw", victim)
		else
			choice = choicelist[1]
		end
		if choice == "PlusMizhao_Use" then
			if source:isAlive() then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("PlusMizhao")
				room:setPlayerFlag(dest, "PlusMizhao_Used")
				local card_use = sgs.CardUseStruct()
				card_use.from = dest
				card_use.to:append(target)
				card_use.card = slash
				room:useCard(card_use, false)
			end
		elseif choice == "PlusMizhao_Draw" then
			dest:drawCards(1)
			dest:turnOver()
		end
	end
}
PlusMizhaoVS = sgs.CreateViewAsSkill {
	name = "PlusMizhao",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards >= 3 then
			local card = PlusMizhao_Card:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#PlusMizhao_Card")
		end
		return false
	end
}
PlusMizhao = sgs.CreateTriggerSkill {
	name = "PlusMizhao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset, sgs.CardUsed },
	view_as_skill = PlusMizhaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.card:hasFlag("PlusMizhao_Slash") then
				room:loseHp(effect.from)
				room:setCardFlag(effect.card, "-PlusMizhao_Slash")
			end
		elseif event == sgs.CardUsed then
			if player:hasFlag("PlusMizhao_Used") then
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") then
					room:setPlayerFlag(player, "-PlusMizhao_Used")
					room:setCardFlag(use.card, "PlusMizhao_Slash")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LiuXie_Plus:addSkill(PlusMizhao)

--[[
	技能：PlusZhengtong
	技能名：正统
	描述：回合开始阶段开始时，你可以弃置一张红色牌并声明一项其他武将的主公技（限定技、觉醒技除外），你视为拥有该技能，直到你的下回合开始。
	状态：验证通过
	注：失去黄天和制霸以后，其他角色依然会保留黄天送牌和制霸拼点的技能，但是没有可选目标。
]]
--
PlusZhengtong_Card = sgs.CreateSkillCard {
	name = "PlusZhengtong_Card",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local lords = sgs.Sanguosha:getLords()
		local lord_skills = {}
		for _, lord in ipairs(lords) do
			local general = sgs.Sanguosha:getGeneral(lord)
			local skills = general:getSkillList()
			for _, skill in sgs.qlist(skills) do
				if skill:isLordSkill() then
					if not table.contains(lord_skills, skill:objectName()) then
						if not source:hasSkill(skill:objectName()) then
							if skill:getFrequency() ~= sgs.Skill_Limited then
								if skill:getFrequency() ~= sgs.Skill_Wake then
									table.insert(lord_skills, skill:objectName())
								end
							end
						end
					end
				end
			end
		end
		if #lord_skills > 0 then
			local choices = table.concat(lord_skills, "+")
			local skill_name = room:askForChoice(source, self:objectName(), choices)
			local skill = sgs.Sanguosha:getSkill(skill_name)
			room:handleAcquireDetachSkills(source, skill_name)
			source:setTag("PlusZhengtong_Skill", sgs.QVariant(skill_name))
			--local jiemingEX = sgs.Sanguosha:getTriggerSkill(skill:objectName())
			---if skill_name ~= "songwei" then  --颂威自动闪退
			--	jiemingEX:trigger(sgs.GameStart, room, source, sgs.QVariant())
			--end
		end
	end,
}
PlusZhengtongVS = sgs.CreateViewAsSkill {
	name = "PlusZhengtong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = PlusZhengtong_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusZhengtong"
	end,
}
PlusZhengtong = sgs.CreateTriggerSkill {
	name = "PlusZhengtong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventLoseSkill },
	view_as_skill = PlusZhengtongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Start then
					room:askForUseCard(player, "@PlusZhengtong", "@PlusZhengtong")
				elseif player:getPhase() == sgs.Player_RoundStart then
					local old_skill = player:getTag("PlusZhengtong_Skill"):toString()
					if old_skill and player:hasSkill(old_skill) then
						room:detachSkillFromPlayer(player, old_skill)
					end
					player:setTag("PlusZhengtong_Skill", sgs.QVariant())
				end
			end
		elseif event == sgs.EventLoseSkill then
			local name = data:toString()
			if name == self:objectName() then
				local old_skill = player:getTag("PlusZhengtong_Skill"):toString()
				if old_skill and player:hasSkill(old_skill) then
					room:detachSkillFromPlayer(player, old_skill)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
LiuXie_Plus:addSkill(PlusZhengtong)

--[[
	技能：PlusXiejia
	技能名：挟驾
	描述：锁定技，摸牌阶段开始时，若此时场上手牌数最多的角色仅有一名且不是你，你须放弃摸牌，改为该角色摸两张牌，再将两张牌交给你。
	状态：验证通过
]]
--
PlusXiejia_DummyCard = sgs.CreateSkillCard {
	name = "PlusXiejia_DummyCard",
}
PlusXiejia = sgs.CreateTriggerSkill {
	name = "PlusXiejia",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local other_players = room:getOtherPlayers(player)
			local max = player:getHandcardNum()
			local unique = false
			local target
			for _, p in sgs.qlist(other_players) do
				if p:getHandcardNum() > max then
					max = p:getHandcardNum()
					target = p
					unique = true
				elseif p:getHandcardNum() == max then
					unique = false
				end
			end
			if unique and target:objectName() ~= player:objectName() then
				local msg = sgs.LogMessage()
				msg.type = "#TriggerSkill"
				msg.from = player
				msg.arg = self:objectName()
				room:sendLog(msg)
				room:drawCards(target, 2, "PlusXiejia")
				local to_exchange
				if target:getCards("he"):length() <= 2 then
					to_exchange = PlusXiejia_DummyCard:clone()
					if target:getCards("he"):length() > 0 then
						for _, card in sgs.qlist(target:getHandcards()) do
							to_exchange:addSubcard(card)
						end
						local equips = target:getEquips()
						for _, equip in sgs.qlist(equips) do
							to_exchange:addSubcard(equip)
						end
					end
				else
					to_exchange = room:askForExchange(target, self:objectName(), 2, 2, true, "@PlusXiejia_Exchange")
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(),
					player:objectName(), self:objectName(), "")
				reason.m_playerId = player:objectName()
				room:moveCardTo(to_exchange, target, player, sgs.Player_PlaceHand, reason)
				return true
			end
		end
	end
}
LiuXie_Plus:addSkill(PlusXiejia)

----------------------------------------------------------------------------------------------------

--[[ QUN 009 张绣
	武将：ZhangXiu_Plus
	武将名：张绣
	称号：北地枪王
	国籍：群
	体力上限：4
	武将技能：
		暗袭(PlusAnxi)：其他角色的回合开始阶段开始时，若其手牌数大于你的手牌数，你可以与其拼点。若你赢，你对其造成1点伤害。若你没赢，该角色可以令你对你攻击范围内其指定的的一名角色造成1点伤害。
	技能设计：玉面
	状态：验证通过
]]
--

ZhangXiu_Plus = sgs.General(extension, "ZhangXiu_Plus", "qun", 4, true)

--[[
	技能：PlusAnxi
	技能名：暗袭
	描述：其他角色的回合开始阶段开始时，若其手牌数大于你的手牌数，你可以与其拼点。若你赢，你对其造成1点伤害。若你没赢，该角色可以令你对你攻击范围内其指定的的一名角色造成1点伤害。
	状态：验证通过
]]
--
PlusAnxi = sgs.CreateTriggerSkill {
	name = "PlusAnxi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local zhangxius = room:findPlayersBySkillName(self:objectName())
			for _, zhangxiu in sgs.qlist(zhangxius) do
				if player:objectName() ~= zhangxiu:objectName() then
					if not zhangxiu:isKongcheng() then
						if player:getHandcardNum() > zhangxiu:getHandcardNum() and zhangxiu:canPindian(player) then
							local dest = sgs.QVariant()
							dest:setValue(player)
							if room:askForSkillInvoke(zhangxiu, self:objectName(), dest) then
								local success = zhangxiu:pindian(player, self:objectName(), nil)
								if zhangxiu:isAlive() then
									if success then
										local damage = sgs.DamageStruct()
										damage.from = zhangxiu
										damage.to = player
										room:damage(damage)
									else
										if room:askForSkillInvoke(player, self:objectName() .. "damage", data) then
											local players = room:getAlivePlayers()
											local wolves = sgs.SPlayerList()
											for _, p in sgs.qlist(players) do
												if zhangxiu:inMyAttackRange(p) then
													wolves:append(p)
												end
											end
											if wolves:isEmpty() then
												return
											end
											local wolf = room:askForPlayerChosen(player, wolves, self:objectName())
											local damage = sgs.DamageStruct()
											damage.from = zhangxiu
											damage.to = wolf
											room:damage(damage)
										end
									end
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhangXiu_Plus:addSkill(PlusAnxi)

----------------------------------------------------------------------------------------------------

--[[ QUN 010 王允
	武将：WangYun_Plus
	武将名：王允
	称号：国之栋梁
	国籍：群
	体力上限：3
	武将技能：
		诛逆(PlusZhuni)：你可以将一张黑色牌当【借刀杀人】使用。若目标角色使用【杀】响应你以此法使用的【借刀杀人】而造成伤害，你须失去1点体力。
		匡君(PlusKuangjun)：每当你扣减1点体力后，你可以令一名其他角色回复1点体力并摸一张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

WangYun_Plus = sgs.General(extension, "WangYun_Plus", "qun", 3, true)

--[[
	技能：PlusZhuni
	技能名：诛逆
	描述：你可以将一张黑色牌当【借刀杀人】使用，若目标角色使用【杀】响应你以此法使用的【借刀杀人】，当此【杀】造成伤害后，其可以弃置一张装备牌，令你失去1点体力。
	状态：验证通过
	注：个别时候，发动诛逆后一段时间会闪退。
]]
--
PlusZhuniVS = sgs.CreateViewAsSkill {
	name = "PlusZhuni",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		if #cards == 1 then
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber())
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName()) --建议使用Flag，但是目前对Flag的支持有问题
			return acard
		end
	end
}
PlusZhuni = sgs.CreateTriggerSkill {
	name = "PlusZhuni",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.Damage, sgs.CardFinished },
	view_as_skill = PlusZhuniVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if use.from:hasSkill(self:objectName()) then --王允使用借刀杀人时
				if card:isKindOf("Collateral") and card:getSkillName() == self:objectName() then
					room:setPlayerFlag(use.to:first(), "PlusZhuni_Killer")
					room:setPlayerFlag(use.from, "PlusZhuni")
				end
			end
			if card:isKindOf("Slash") then --目标响应时
				local killer = use.from
				if killer:hasFlag("PlusZhuni_Killer") then
					room:setCardFlag(card, "PlusZhuni_Slash")
				end
			end
			return false
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local slash = damage.card
			if slash then
				if slash:isKindOf("Slash") then
					if slash:hasFlag("PlusZhuni_Slash") then
						local target
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:hasFlag("PlusZhuni_Killer") then
								room:setPlayerFlag(p, "-PlusZhuni_Killer")
								target = p
							end
						end
						room:setCardFlag(slash, "-PlusZhuni_Slash")
						local wangyuns = room:findPlayersBySkillName(self:objectName())
						for _, wangyun in sgs.qlist(wangyuns) do
							if wangyun:hasFlag("PlusZhuni") then
								local dest = sgs.QVariant()
								dest:setValue(wangyun)
								local prompt = string.format("@PlusZhuni:%s", wangyun:objectName())
								if target and room:askForCard(target, ".Equip", prompt, dest, sgs.Card_MethodDiscard) then
									room:loseHp(wangyun)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if use.from:hasSkill(self:objectName()) then
				if card:isKindOf("Collateral") and card:getSkillName() == self:objectName() then
					room:setPlayerFlag(use.to:first(), "-PlusZhuni_Killer")
					room:setPlayerFlag(use.from, "-PlusZhuni")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
WangYun_Plus:addSkill(PlusZhuni)

--[[
	技能：PlusKuangjun
	技能名：匡君
	描述：每当你扣减1点体力后，你可以令一名其他角色回复1点体力并摸一张牌。
	状态：验证通过
]]
--
PlusKuangjun_Card = sgs.CreateSkillCard {
	name = "PlusKuangjun_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(target, recover)
		room:drawCards(target, 1, "PlusKuangjun")
	end
}
PlusKuangjunVS = sgs.CreateViewAsSkill {
	name = "PlusKuangjun",
	n = 0,
	view_as = function(self, cards)
		return PlusKuangjun_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@PlusKuangjun"
	end
}
PlusKuangjun = sgs.CreateTriggerSkill {
	name = "PlusKuangjun",
	events = { sgs.HpChanged, sgs.PreHpLost, sgs.DamageDone },
	frequency = sgs.Skill_Frequent,
	view_as_skill = PlusKuangjunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone or event == sgs.PreHpLost then
			local lost = 0
			if event == sgs.DamageDone then
				lost = data:toDamage().damage
			elseif event == sgs.PreHpLost then
				lost = data:toInt()
			end
			room:setPlayerMark(player, "PlusKuangjun", lost)
		elseif event == sgs.HpChanged then
			local lost = player:getMark("PlusKuangjun")
			room:setPlayerMark(player, "PlusKuangjun", 0)
			if lost > 0 then
				for i = 1, lost, 1 do
					if not room:askForUseCard(player, "@PlusKuangjun", "@PlusKuangjun") then
						break
					end
				end
			end
		end
	end,
	priority = -1,
}
WangYun_Plus:addSkill(PlusKuangjun)

----------------------------------------------------------------------------------------------------

--[[ QUN 011 司马徽
	武将：SiMaHui_Plus
	武将名：司马徽
	称号：水镜先生
	国籍：群
	体力上限：3
	武将技能：
		知人(PlusZhiren)：出牌阶段，你可以观看一名角色的手牌，并可以展示其中一张基本牌，若如此做，回合结束阶段开始时，该角色摸一张牌。每阶段限一次。
		称好(PlusChenghao)：你的回合外，当你失去牌时，你可以令当前正进行回合的角色和你各摸一张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
--

SiMaHui_Plus = sgs.General(extension, "SiMaHui_Plus", "qun", 3, true)

--[[
	技能：PlusZhiren
	技能名：知人
	描述：出牌阶段限一次，你可以观看一名角色的手牌，然后你可以展示其中一张牌，若此牌为基本牌，该角色回复1点体力，否则其摸两张牌。
	状态：验证通过
]]
--
PlusZhiren_Card = sgs.CreateSkillCard {
	name = "PlusZhiren_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:isKongcheng() then
			local ids = target:handCards()
			room:fillAG(ids, source)
			room:setPlayerFlag(target, "PlusZhiren")
			local card_id = room:askForAG(source, ids, true, "PlusZhiren")
			room:setPlayerFlag(target, "-PlusZhiren")
			if card_id ~= -1 then
				local card = sgs.Sanguosha:getCard(card_id)
				room:showCard(target, card_id)
				if card:isKindOf("BasicCard") then
					local recover = sgs.RecoverStruct()
					recover.who = source
					room:recover(target, recover)
				else
					target:drawCards(2)
				end
			end
			room:clearAG()
		end
	end
}
PlusZhiren = sgs.CreateViewAsSkill {
	name = "PlusZhiren",
	n = 0,
	view_as = function(self, cards)
		local card = PlusZhiren_Card:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#PlusZhiren_Card")
	end
}

SiMaHui_Plus:addSkill(PlusZhiren)

--[[
	技能：PlusChenghao
	技能名：称好
	描述：你的回合外，当你失去牌时，你可以令当前正进行回合的角色和你各摸一张牌。
	状态：验证通过
]]
--
PlusChenghao = sgs.CreateTriggerSkill {
	name = "PlusChenghao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local places = move.from_places
				if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
					if player:askForSkillInvoke(self:objectName(), data) then
						local current = room:getCurrent()
						if current and not current:isDead() then
							room:drawCards(current, 1, self:objectName())
						end
						room:drawCards(player, 1, self:objectName())
					end
				end
			end
		end
		return false
	end
}
SiMaHui_Plus:addSkill(PlusChenghao)

----------------------------------------6.0------------------------------------------------------------


----------------------------------------------------------------------------------------------------
--                                             魏
----------------------------------------------------------------------------------------------------


--[[ 魏 001 曹操
	武将：CaoCao_six
	武将名：曹操
	体力上限：4
	武将技能：
		武略(SixWulve)：每当你受到一次伤害后，你可以选择一项：1.摸两张牌。2.将对你造成伤害的牌置于你的武将牌上，称为“略”。一名角色的结束阶段开始时，你可以将一张“略”置入弃牌堆，视为该角色使用此牌。
		护驾：主公技，当你需要使用或打出一张【闪】时，你可令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	状态：验证通过
]]
--
CaoCao_six = sgs.General(extension_six, "CaoCao_six$", "wei", 4, true)

--[[
	技能名：武略
	技能：SixWulve, SixWulveUse, SixWulveRemove, (SixWulveOthers)
	描述：每当你受到一次伤害后，你可以选择一项：1.摸两张牌。2.将对你造成伤害的牌置于你的武将牌上，称为“略”。一名角色的结束阶段开始时，你可以将一张“略”置入弃牌堆，视为该角色使用此牌。
	状态：验证通过
	注：由于某些问题，选择第二项时将牌依次置于弃牌堆上；
		如果lua扩展包中有这样的牌：可以选择2个目标，其中第二个目标并非真正的目标，只是为了操作简便（如借刀杀人），那么选择第二个目标时会检验合法性；
		当前正进行回合的角色视为使用此牌时，可以取消（并且由于AI还没写会导致总是取消）；
		当前正进行回合的角色视为使用此牌时，界面上会出现一个空按钮。
]]
--
SixWulve = sgs.CreateTriggerSkill {
	name = "SixWulve",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local choices = {}
		table.insert(choices, "SixWulveDraw")
		local damage = data:toDamage()
		local card = damage.card
		if card then
			local id = card:getEffectiveId()
			if room:getCardPlace(id) == sgs.Player_PlaceTable then
				table.insert(choices, "SixWulveGet")
			end
		end
		table.insert(choices, "SixWulveCancel")
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
		if choice ~= "SixWulveCancel" then
			local msg = sgs.LogMessage()
			if choice == "SixWulveDraw" then --获得造成伤害的牌
				msg.type = "#SixWulve1"
				msg.from = player
				msg.arg = self:objectName()
				room:sendLog(msg)
				room:drawCards(player, 2, self:objectName())
			elseif choice == "SixWulveGet" then --弃1张牌然后摸X张牌
				msg.type = "#SixWulve2"
				msg.from = player
				msg.arg = self:objectName()
				room:sendLog(msg)
				local card = damage.card
				for _, id in sgs.qlist(card:getSubcards()) do
					player:addToPile("strategy", id)
				end
				--player:addToPile("strategy", card:getEffectiveId())
			end
		end
	end
}
getAvailableTargets = function(player, card, tot_selected, selected)
	--返回：player使用card，在已经选择了selected的情况下，选择后能够使此牌可以使用的角色。
	local room = player:getRoom() --todo:用getSiblings替换room
	local results = sgs.PlayerList()
	local targets = sgs.PlayerList()
	if not selected:isEmpty() then
		targets = selected
	end
	for _, p in sgs.qlist(room:getAllPlayers()) do                                                         --枚举每个目标
		if not selected:contains(p) then                                                                   --防止重复选择
			if card:targetFilter(targets, p, player) then
				if (not player:isProhibited(p, card)) or (not selected:isEmpty() and card:isKindOf("Collateral")) then --第二个或若干目标可以不检测是否被禁止（有待修改，这是针对借刀）
					targets:append(p)
					if card:targetsFeasible(targets, player) then                                          --选择此目标后可以使用
						results:append(targets:at(tot_selected))
					else                                                                                   --可以选择此目标，但是无法使用，需要继续选择目标，递归
						local more_targets = getAvailableTargets(player, card, tot_selected + 1, targets)
						if not more_targets:isEmpty() then
							results:append(targets:at(tot_selected))
						end
					end
					targets:removeOne(p)
				end
			end
		end
	end
	return results
end
SixWulveVS = sgs.CreateViewAsSkill {
	name = "SixWulveOthers",
	n = 0,
	view_as = function(self, cards)
		--local card = sgs.Sanguosha:cloneCard(sgs.Self:property("SixWulveCard"):getName(),sgs.Card_NoSuit,0)
		local card = sgs.Card_Parse(sgs.Self:property("SixWulveCard"):toString()) --通过视为技视为使用此牌
		card:setSkillName("SixWulve")

		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@SixWulveOthers!"
	end
}
SixWulveOthers = sgs.CreateTriggerSkill {
	name = "SixWulveOthers&",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.NonTrigger }, --只需要让目标角色使用牌即可
	view_as_skill = SixWulveVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = sgs.Card_Parse(player:property("SixWulveCard"):toString())
		local prompt = string.format("@SixWulve:::%s", card:objectName())
		room:askForUseCard(player, "@@SixWulveOthers!", prompt)
	end
}
SixWulveUse = sgs.CreateTriggerSkill {
	name = "#SixWulveUse",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.PreCardUsed },
	--view_as_skill = SixWulveVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local caocaos = room:findPlayersBySkillName("SixWulve")
			for _, caocao in sgs.qlist(caocaos) do
				if player:getPhase() == sgs.Player_Finish then
					local strategy = caocao:getPile("strategy")
					if strategy:length() > 0 then
						local available_ids = sgs.IntList()
						local not_available_ids = sgs.IntList()
						for _, id in sgs.qlist(strategy) do
							local card = sgs.Sanguosha:getCard(id)
							if card:isAvailable(player) then --最后换回player
								if card:targetFixed() then --固定目标
									available_ids:append(id)
									--[[elseif not card:isKindOf("Collateral") then
									local targets = sgs.PlayerList()
									for _,p in sgs.qlist(room:getAllPlayers()) do
										if card:targetFilter(targets, p, player) then
											if not player:isProhibited(p, card) then
												targets:append(p)
												if card:targetsFeasible(targets, player) then  --防止可能出现的需要选择2名角色的情况
													available_ids:append(id)
													break
												end
											end
										end
									end
								elseif card:isKindOf("Collateral") then
									local targets = sgs.PlayerList()
									local found = false
									for _,p in sgs.qlist(room:getAllPlayers()) do
										if card:targetFilter(targets, p, player) then
											if not player:isProhibited(p, card) then
												targets:append(p)
												for _,q in sgs.qlist(room:getAllPlayers()) do
													if card:targetFilter(targets, q, player) then
														targets:append(q)
														if card:targetsFeasible(targets, player) then
															available_ids:append(id)
															found = true
															break
														end
														targets:removeOne(q)
													end
												end
												if found then
													break
												end
												targets:removeOne(p)
											end
										end
									end]]
								elseif card:targetsFeasible(sgs.PlayerList(), player) and not card:isKindOf("IronChain") then --不需要目标就可以使用（供lua使用，非铁索连环）
									available_ids:append(id)
								elseif not getAvailableTargets(player, card, 0, sgs.PlayerList()):isEmpty() then --有可以使用的目标，此处不考虑重铸
									available_ids:append(id)
								else
									not_available_ids:append(id)
								end
							else
								not_available_ids:append(id)
							end
						end
						if not available_ids:isEmpty() then
							if room:askForSkillInvoke(caocao, "SixWulve") then
								room:fillAG(strategy, nil, not_available_ids)
								local card_id = room:askForAG(caocao, available_ids, false, "SixWulve")
								room:clearAG()
								if card_id ~= -1 and available_ids:contains(card_id) then
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "",
										"SixWulve", "")
									local card = sgs.Sanguosha:getCard(card_id)
									room:throwCard(card, reason, nil)
									--视为使用此牌
									if card:targetFixed() then --固定目标
										local use = sgs.CardUseStruct() --使用装备牌似乎不能直接定义？
										use.m_isOwnerUse = false
										local new_card = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
										new_card:setSkillName("SixWulve")
										use.card = new_card
										--use.card = card
										use.from = player
										room:useCard(use)
									else --通过视为技使用此牌
										room:setPlayerProperty(player, "SixWulveCard", sgs.QVariant(card:toString()))
										room:attachSkillToPlayer(player, "SixWulveOthers")
										local jiemingEX = sgs.Sanguosha:getTriggerSkill("SixWulveOthers")
										jiemingEX:trigger(sgs.NonTrigger, room, player, sgs.QVariant()) --通过隐藏技能触发askForUseCard。。话说很奇怪为什么不能隐藏
										room:detachSkillFromPlayer(player, "SixWulveOthers", true)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.PreCardUsed then --非自己使用
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.card:getSkillName() == "SixWulve" then
				use.m_isOwnerUse = false
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
SixWulveRemove = sgs.CreateTriggerSkill {
	name = "#SixWulveRemove",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local name = data:toString()
		if name == "SixWulve" then
			player:removePileByName("strategy")
		end
		return false
	end,
	can_trigger = function(self, target)
		return (target ~= nil)
	end
}
CaoCao_six:addSkill(SixWulve)
CaoCao_six:addSkill(SixWulveUse)
CaoCao_six:addSkill(SixWulveRemove)
local skill = sgs.Sanguosha:getSkill("SixWulveOthers")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(SixWulveOthers)
	sgs.Sanguosha:addSkills(skillList)
end
extension_six.insertRelatedSkills(extension_six, "SixWulve", "#SixWulveUse")
extension_six.insertRelatedSkills(extension_six, "SixWulve", "#SixWulveRemove")

--[[
	技能名：护驾
	技能：hujia
	描述：主公技，当你需要使用或打出一张【闪】时，你可令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	状态：原有技能
]]
--
CaoCao_six:addSkill("hujia")

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------

--[[ 魏 002 司马懿
	武将：SiMaYi_Six
	武将名：司马懿
	体力上限：3
	武将技能：
		狼谋(SixLangmou)：每当你受到一次伤害后，你可以观看伤害来源的手牌，并获得其一张牌。
		鬼才(SixGuicai)：在一名角色的判定牌生效前，或一名角色拼点的牌亮出后（每次拼点限其中一名角色），你可以弃置一张手牌并选择一种花色和点数，若如此做，此判定牌或拼点的牌视为此花色和点数。
		韬晦(SixTaohui)：结束阶段开始时，你可以将装备区里任意数量的牌置入手牌。
	状态：验证通过
]]
--
SiMaYi_Six = sgs.General(extension_six, "SiMaYi_Six", "wei", 3, true)

--[[
	技能名：狼谋
	技能：SixLangmou
	描述：每当你受到一次伤害后，你可以观看伤害来源的手牌，并获得其一张牌。
	状态：验证通过
]]
--
SixLangmou = sgs.CreateTriggerSkill {
	name = "SixLangmou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local source_data = sgs.QVariant()
		source_data:setValue(source)
		if source then
			if not source:isNude() then
				-- room:setTag("CurrentDamageStruct", data)
				if room:askForSkillInvoke(player, self:objectName(), source_data) then
					room:broadcastSkillInvoke(self:objectName())
					local card_id = room:askForCardChosen(player, source, "he", self:objectName(), true)
					room:obtainCard(player, card_id)
				end
				-- room:removeTag("CurrentDamageStruct")
			end
		end
	end
}
SiMaYi_Six:addSkill(SixLangmou)

--[[
	技能名：鬼才
	技能：SixGuicai, (SixGuicaiFilter)
	描述：在一名角色的判定牌生效前，或一名角色拼点的牌亮出后（每次拼点限其中一名角色），你可以弃置一张手牌并选择一种花色和点数，若如此做，此判定牌或拼点的牌视为此花色和点数。
	状态：验证通过
	注：修改拼点牌时，由于显示原因，并未真正视为对应的花色和点数，只是修改了点数，因此在弹出的小窗口中看到的是原拼点牌；
		修改判定牌时，会出现很多多余的提示信息；
		循环判定中（个别双将）无法正常改判。
]]
--
SixGuicaiDummyCard = sgs.CreateSkillCard {
	name = "SixGuicaiDummyCard",
	target_fixed = true,
	will_throw = true,
}
SixGuicaiCard = sgs.CreateSkillCard {
	name = "SixGuicaiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:hasFlag("SixGuicaiSource") or to_select:hasFlag("SixGuicaiTarget")
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:setPlayerFlag(target, "SixGuicaiModify")
		--local card_id = effect.card:getSubcards():first()
		--room:setTag("SixGuicaiCard", sgs.QVariant(card_id))
	end,
}
SixGuicaiVS = sgs.CreateViewAsSkill {
	name = "SixGuicai",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = nil
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@SixGuicai1" then
			card = SixGuicaiDummyCard:clone()
		elseif sgs.Sanguosha:getCurrentCardUsePattern() == "@@SixGuicai2" then
			card = SixGuicaiCard:clone()
		end
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@SixGuicai1" or pattern == "@@SixGuicai2"
	end
}
SixGuicai = sgs.CreateTriggerSkill { --todo:用QVariant对花色优化
	name = "SixGuicai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial, sgs.PindianVerifying },
	view_as_skill = SixGuicaiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:canDiscard(player, "h") then
				local judge = data:toJudge()
				local old_card = judge.card
				local prompt = string.format("@SixGuicai::%s", self:objectName())
				local discard = room:askForCard(player, "@@SixGuicai1", prompt, data, sgs.Card_MethodDiscard)
				if discard then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:setTag("CurrentJudgeStruct", data)
					local suit = room:askForSuit(player, self:objectName())
					local point = room:askForChoice(player, self:objectName(), "1+2+3+4+5+6+7+8+9+10+11+12+13", data)
					room:removeTag("CurrentJudgeStruct")
					local new_card = sgs.Sanguosha:cloneCard(old_card:objectName(), suit, tonumber(point)) --for log only
					new_card:setSkillName(self:objectName())
					--[[local vs_card = sgs.Sanguosha:getWrappedCard(old_card:getId())
					vs_card:takeOver(new_card)
					room:broadcastUpdateCard(room:getPlayers(), vs_card:getId(), vs_card)]]
					--judge:updateResult()  此行lua不可用
					room:setCardFlag(old_card, "SixGuicaiModified")
					--room:setTag("SixGuicaiSuit", sgs.QVariant(suit))  --todo:setValue
					if suit == sgs.Card_Spade then
						room:setTag("SixGuicaiSuit", sgs.QVariant("spade"))
					elseif suit == sgs.Card_Club then
						room:setTag("SixGuicaiSuit", sgs.QVariant("club"))
					elseif suit == sgs.Card_Heart then
						room:setTag("SixGuicaiSuit", sgs.QVariant("heart"))
					elseif suit == sgs.Card_Diamond then
						room:setTag("SixGuicaiSuit", sgs.QVariant("diamond"))
					end
					room:setTag("SixGuicaiNumber", sgs.QVariant(tonumber(point)))
					if not judge.who:hasSkill("SixGuicaiFilter") then
						room:attachSkillToPlayer(judge.who, "SixGuicaiFilter")
					end
					room:retrial(discard, player, judge, self:objectName())
					room:retrial(old_card, player, judge, self:objectName())

					local msg = sgs.LogMessage()
					msg.type = "$SixGuicaiJudgeOne"
					msg.from = player
					msg.to:append(judge.who)
					msg.arg = new_card:getSuitString()
					if point == "10" then
						msg.arg2 = "10"
					else
						local str = "A23456789-JQK"
						msg.arg2 = string.sub(str, point, point)
					end
					room:sendLog(msg)
					room:setCardFlag(old_card, "-SixGuicaiModified")
					room:removeTag("SixGuicaiSuit")
					room:removeTag("SixGuicaiNumber")
					room:detachSkillFromPlayer(judge.who, "SixGuicaiFilter", true)
				end
				return false
			end
		elseif event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			local simayis = room:findPlayersBySkillName(self:objectName())
			for _, simayi in sgs.qlist(simayis) do
				if simayi:canDiscard(simayi, "h") then
					local source = pindian.from
					local target = pindian.to
					room:setPlayerFlag(source, "SixGuicaiSource")
					room:setPlayerFlag(target, "SixGuicaiTarget")
					local prompt = string.format("@SixGuicai::%s", self:objectName())
					room:setTag("CurrentPindianStruct", data)
					if room:askForUseCard(simayi, "@@SixGuicai2", prompt, 2) then
						room:broadcastSkillInvoke(self:objectName())
						room:notifySkillInvoked(simayi, self:objectName())
						local suit = room:askForSuit(simayi, self:objectName() .. "pindian")
						local point = room:askForChoice(simayi, self:objectName() .. "pindian",
							"1+2+3+4+5+6+7+8+9+10+11+12+13")
						local dest
						local old_card
						if source:hasFlag("SixGuicaiModify") then
							room:setPlayerFlag(source, "-SixGuicaiModify")
							old_card = pindian.from_card
							dest = source
							pindian.from_number = tonumber(point)
						elseif target:hasFlag("SixGuicaiModify") then
							room:setPlayerFlag(target, "-SixGuicaiModify")
							old_card = pindian.to_card
							dest = target
							pindian.to_number = tonumber(point)
						end

						local new_card = sgs.Sanguosha:cloneCard(old_card:objectName(), suit, tonumber(point))
						new_card:setSkillName(self:objectName())
						--[[local vs_card = sgs.Sanguosha:getWrappedCard(old_card:getId())
						vs_card:takeOver(new_card)
						room:broadcastUpdateCard(room:getPlayers(), vs_card:getId(), vs_card)]]
						--这些代码会出现崩溃BUG
						data:setValue(pindian)

						local msg = sgs.LogMessage()
						msg.type = "$SixGuicaiPindianOne"
						msg.from = simayi
						msg.to:append(dest)
						msg.arg = new_card:getSuitString()
						if point == "10" then
							msg.arg2 = "10"
						else
							local str = "A23456789-JQK"
							msg.arg2 = string.sub(str, point, point)
						end
						room:sendLog(msg)
					end
					room:removeTag("CurrentPindianStruct")
					room:setPlayerFlag(source, "-SixGuicaiSource")
					room:setPlayerFlag(target, "-SixGuicaiTarget")
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
SixGuicaiFilter = sgs.CreateFilterSkill { --暂时性的锁定视为，实现将判定牌视为的效果
	name = "SixGuicaiFilter",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		if place == sgs.Player_PlaceJudge then
			return to_select:hasFlag("SixGuicaiModified")
		end
		return false
	end,
	view_as = function(self, card)
		local room = sgs.Sanguosha:currentRoom()
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		local suit = room:getTag("SixGuicaiSuit"):toString()
		if suit == "spade" then
			new_card:setSuit(sgs.Card_Spade)
		elseif suit == "club" then
			new_card:setSuit(sgs.Card_Club)
		elseif suit == "heart" then
			new_card:setSuit(sgs.Card_Heart)
		elseif suit == "diamond" then
			new_card:setSuit(sgs.Card_Diamond)
		end
		new_card:setNumber(room:getTag("SixGuicaiNumber"):toInt())
		new_card:setModified(true)
		return new_card
	end
}
SiMaYi_Six:addSkill(SixGuicai)
local skill = sgs.Sanguosha:getSkill("SixGuicaiFilter")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(SixGuicaiFilter)
	sgs.Sanguosha:addSkills(skillList)
end

--[[
	技能名：韬晦
	技能：SixTaohui
	描述：结束阶段开始时，你可以将装备区里任意数量的牌置入手牌。
	状态：验证通过
]]
--
SixTaohuiCard = sgs.CreateSkillCard {
	name = "SixTaohuiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "SixTaohui")
		local move = sgs.CardsMoveStruct()
		move.card_ids = self:getSubcards()
		move.to = source
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, false)
	end
}
SixTaohuiVS = sgs.CreateViewAsSkill {
	name = "SixTaohui",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = SixTaohuiCard:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@SixTaohui"
	end
}
SixTaohui = sgs.CreateTriggerSkill {
	name = "SixTaohui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = SixTaohuiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			if player:hasEquip() then
				room:askForUseCard(player, "@SixTaohui", "@SixTaohui")
			end
		end
		return false
	end
}
SiMaYi_Six:addSkill(SixTaohui)


----------------------------------------------------------------------------------------------------

--[[ 魏 003 郭嘉
	武将：GuoJia_Six
	武将名：郭嘉
	体力上限：3
	武将技能：
		天妒(SixTiandu)：锁定技，结束阶段开始时，你进行一次判定。在判定牌生效后，你获得此牌，然后若判定结果为黑桃2~9，你受到1点伤害。
		遗计：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张交给一名角色，然后将另一张交给一名角色。
	状态：验证通过
]]
--
GuoJia_Six = sgs.General(extension_six, "GuoJia_Six", "wei", 3, true)

--[[
	技能名：天妒
	技能：SixTiandu
	描述：锁定技，结束阶段开始时，你进行一次判定。在判定牌生效后，你获得此牌，然后若判定结果为黑桃2~9，你受到1点伤害。
	状态：验证通过
]]
--
SixTiandu = sgs.CreateTriggerSkill {
	name = "SixTiandu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local room = player:getRoom()
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				local msg = sgs.LogMessage()
				msg.type = "#TriggerSkill"
				msg.from = player
				msg.arg = self:objectName()
				room:sendLog(msg)
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade|2~9"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				judge.play_animation = true
				room:judge(judge)
				if judge:isBad() then
					local damage = sgs.DamageStruct()
					damage.to = player
					room:damage(damage)
				end
			end
		elseif event == sgs.FinishJudge then
			local room = player:getRoom()
			local judge = data:toJudge()
			local card = judge.card
			if judge.reason == self:objectName() then
				player:obtainCard(card)
			end
		end
	end
}
GuoJia_Six:addSkill(SixTiandu)

--[[
	技能名：遗计
	技能：yiji
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，将其中一张交给一名角色，然后将另一张交给一名角色。
	状态：原有技能
]]
--
GuoJia_Six:addSkill("yiji")

----------------------------------------------------------------------------------------------------

--[[ 魏 006 许褚
	武将：XuChu_Six
	武将名：许褚
	体力上限：4
	武将技能：
		虎卫(SixHuwei)：锁定技，当其他角色使用【杀】选择目标后，若你的装备区里没有防具牌，且其与目标角色的距离不小于其与你的距离，其选择一项：弃置一张装备牌，或令你摸一张牌。
	状态：验证通过
]]
--
XuChu_Six = sgs.General(extension_six, "XuChu_Six", "wei", 4, true)

--[[
	技能名：虎卫
	技能：SixHuwei
	描述：锁定技，当其他角色使用【杀】选择目标后，若你的装备区里没有防具牌，且其与目标角色的距离不小于其与你的距离，其选择一项：弃置一张装备牌，或令你摸一张牌。
	状态：验证通过
]]
--
SixHuwei = sgs.CreateTriggerSkill {
	name = "SixHuwei",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local card = use.card
		local source = use.from
		local targets = use.to
		local room = player:getRoom()
		if card:isKindOf("Slash") then
			--if not source:hasSkill(self:objectName()) then
			local xuchus = room:findPlayersBySkillName(self:objectName())
			for _, xuchu in sgs.qlist(xuchus) do
				if xuchu:objectName() == use.from:objectName() then continue end
				for _, target in sgs.qlist(targets) do
					if xuchu:isAlive() and not xuchu:getEquip(1) then
						if source:distanceTo(target) >= source:distanceTo(xuchu) then
							local msg = sgs.LogMessage()
							msg.type = "#TriggerSkill"
							msg.from = xuchu
							msg.arg = self:objectName()
							room:sendLog(msg)
							room:notifySkillInvoked(xuchu, self:objectName())
							local prompt = string.format("@SixHuwei:%s", xuchu:objectName())
							local dest = sgs.QVariant()
							dest:setValue(xuchu)
							if not (source:canDiscard(source, "he") and room:askForCard(source, ".Equip", prompt, dest)) then
								room:drawCards(xuchu, 1, self:objectName())
							end
						end
					end
				end
			end
			--end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
XuChu_Six:addSkill(SixHuwei)

----------------------------------------------------------------------------------------------------

--[[ 魏 009 曹仁
	武将：CaoRen_Six
	武将名：曹仁
	体力上限：4
	武将技能：
		据守(SixJushou)：结束阶段开始时，若你在弃牌阶段弃置了至少一张手牌，你可以选择至多一名攻击范围内含有你，且武将牌正面朝上的其他角色，令你与其各摸X张牌（X为你在弃牌阶段弃置的手牌数量且至多为4）并将武将牌翻面。
	状态：验证通过
]]
--
CaoRen_Six = sgs.General(extension_six, "CaoRen_Six", "wei", 4, true)

--[[
	技能名：据守
	技能：SixJushou
	描述：结束阶段开始时，若你在弃牌阶段弃置了至少一张手牌，你可以选择至多一名攻击范围内含有你，且武将牌正面朝上的其他角色，令你与其各摸X张牌（X为你在弃牌阶段弃置的手牌数量且至多为4）并将武将牌翻面。
	状态：验证通过
]]
--
SixJushou = sgs.CreateTriggerSkill {
	name = "SixJushou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("SixJushou") >= 1 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:inMyAttackRange(player) and p:faceUp() then
								targets:append(p)
							end
						end
						local target = room:askForPlayerChosen(player, targets, self:objectName(), "@SixJushou", true,
							true)
						local x = math.min(player:getMark("SixJushou"), 4)
						room:drawCards(player, x, self:objectName())
						player:turnOver()
						if target then
							room:drawCards(target, x, self:objectName())
							target:turnOver()
						end
					end
				end
			end
			player:setMark("SixJushou", 0) --todo:检查根据天香清空Mark（以及屈才）
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local reason = move.reason.m_reason
				if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					if player:getPhase() == sgs.Player_Discard then
						local markcount = player:getMark("SixJushou")
						room:setPlayerMark(player, "SixJushou", markcount + move.card_ids:length())
					end
				end
			end
		end
	end
}
CaoRen_Six:addSkill(SixJushou)

----------------------------------------------------------------------------------------------------

--[[ 魏 012 程昱
	武将：ChengYu_Six
	武将名：程昱
	体力上限：3
	武将技能：
		明断(SixMingduan)：其他角色的出牌阶段开始时，你可以交给其一张黑色手牌并选择其攻击范围内的另一名角色，令其不能对除你选择的角色以外的角色使用【杀】，直到回合结束。
		胆计(SixDanji)：锁定技，当其他角色使用【杀】或非延时类锦囊牌即将对你造成伤害时，若其手牌数大于你的手牌数，此伤害-1。
	状态：验证失败（明断）
]]
--
ChengYu_Six = sgs.General(extension_six, "ChengYu_Six", "wei", 3, true)

--[[
	技能名：明断
	技能：SixMingduan, SixMingduan0610
	描述：其他角色的出牌阶段开始时，你可以交给其一张黑色手牌并选择其攻击范围内的另一名角色，令其不能对除你选择的角色以外的角色使用【杀】，直到回合结束。
	状态：验证失败（0610中ProhibitSkill无法使用，现改为：“若如此做，其使用【杀】选择目标后，若目标角色中有除你选择的角色以外的角色，取消此牌。”导致依然可以使用杀但是无效）
	注：发现可以对其他角色使用杀的情况，具体不明。
]]
--
SixMingduanCard = sgs.CreateSkillCard {
	name = "SixMingduanCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local current = room:getTag("SixMingduanCurrent"):toPlayer()
		room:removeTag("SixMingduanCurrent")
		local dests = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(current)) do
			if current:inMyAttackRange(p) then
				dests:append(p)
			end
		end
		local prompt = string.format("@SixMingduanChoose:%s", current:objectName())
		local dest = room:askForPlayerChosen(source, dests, "SixMingduan", prompt)
		room:notifySkillInvoked(source, "SixMingduan")
		room:obtainCard(current, self)
		room:setPlayerFlag(current, "SixMingduanSource")
		room:setPlayerFlag(dest, "SixMingduanTarget")
		room:addPlayerMark(dest, "&SixMingduan+to+#"..current:objectName().."-Clear")
		local msg = sgs.LogMessage()
		msg.type = "#SixMingduan"
		msg.from = current
		msg.to:append(dest)
		msg.arg = "SixMingduan"
		room:sendLog(msg)
	end
}
SixMingduanVS = sgs.CreateViewAsSkill {
	name = "SixMingduan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = SixMingduanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@SixMingduan"
	end
}
SixMingduan = sgs.CreateTriggerSkill {
	name = "SixMingduan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = SixMingduanVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local chengyus = room:findPlayersBySkillName(self:objectName())
			for _, chengyu in sgs.qlist(chengyus) do
				--if chengyu and chengyu:objectName() ~= player:objectName() then
				if not chengyu:isKongcheng() and chengyu:objectName() ~= player:objectName() then
					local can = false
					for _, target in sgs.qlist(room:getOtherPlayers(player)) do
						if player:inMyAttackRange(target) then
							can = true
						end
					end
					if can then
						local tag = sgs.QVariant()
						tag:setValue(player)
						room:setTag("SixMingduanCurrent", tag) --防止今后可能出现的“执行一个额外的出牌阶段”的情况
						room:askForUseCard(chengyu, "@@SixMingduan", "@SixMingduan")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
SixMingduanPro = sgs.CreateProhibitSkill { --Prohibit的BUG
	name = "#SixMingduanPro",
	is_prohibited = function(self, from, to, card)
		if card:isKindOf("Slash") then
			if from:hasFlag("SixMingduanSource") and not to:hasFlag("SixMingduanTarget") then
				return true
			end
		end
		return false
	end
}
ChengYu_Six:addSkill(SixMingduan)
ChengYu_Six:addSkill(SixMingduanPro)
extension_six:insertRelatedSkills("SixMingduan", "#SixMingduanPro")

ChengYu_Six:addSkill("PlusDanji")

----------------------------------------------------------------------------------------------------

--[[ 魏 013 刘晔
	武将：LiuYe_Six
	武将名：刘晔
	体力上限：3
	武将技能：
		巧械(SixQiaoxie)：一名角色的出牌阶段开始时，其可以令你选择是否弃置一张黑色手牌并令其攻击范围无限直到回合结束。
		知敌(SixZhidi)：结束阶段开始时，若你的武将牌上没有牌，你可以将一张手牌背面朝上置于你的武将牌上，称为“知”；当你成为其他角色使用的牌的目标时，你可以展示一张与此牌颜色相同的“知”并将其置于弃牌堆，令此牌对你无效，然后你摸两张牌。
	状态：验证通过
]]
--
LiuYe_Six = sgs.General(extension_six, "LiuYe_Six", "wei", 3, true)

--[[
	技能名：巧械
	技能：SixQiaoxie
	描述：一名角色的出牌阶段开始时，其可以令你选择是否弃置一张黑色手牌并令其攻击范围无限直到回合结束。
	状态：验证通过
]]
--
SixQiaoxie = sgs.CreateTriggerSkill {
	name = "SixQiaoxie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local liuyes = room:findPlayersBySkillName(self:objectName())
			for _, liuye in sgs.qlist(liuyes) do
				if liuye:canDiscard(liuye, "h") then
					local dest = sgs.QVariant()
					dest:setValue(liuye)
					if room:askForSkillInvoke(player, self:objectName(), dest) then
						local msg = sgs.LogMessage()
						msg.type = "#InvokeOthersSkill"
						msg.from = player
						msg.to:append(liuye)
						msg.arg = self:objectName()
						room:sendLog(msg)
						local prompt = string.format("@SixQiaoxie:%s", player:objectName())
						if room:askForCard(liuye, ".black", prompt, data, sgs.Card_MethodDiscard) then
							room:setPlayerFlag(player, "InfinityAttackRange")
							room:addPlayerMark(player, "&SixQiaoxie+to+#" .. liuye:objectName() .. "-Clear")
						else
							local msg = sgs.LogMessage()
							msg.type = "#SixQiaoxieReject"
							msg.from = liuye
							msg.to:append(player)
							msg.arg = self:objectName()
							room:sendLog(msg)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LiuYe_Six:addSkill(SixQiaoxie)

--[[
	技能名：知敌
	技能：SixZhidi, SixZhidiProtect
	描述：结束阶段开始时，若你的武将牌上没有牌，你可以将一张手牌背面朝上置于你的武将牌上，称为“知”；当你成为其他角色使用的牌的目标时，你可以展示一张与此牌颜色相同的“知”并将其置于弃牌堆，令此牌对你无效，然后你摸两张牌。
	状态：验证通过
]]
--
SixZhidiCard = sgs.CreateSkillCard {
	name = "SixZhidiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "SixZhidi")
		local id = self:getSubcards():first()
		source:addToPile("know", id, false)
	end
}
SixZhidiVS = sgs.CreateViewAsSkill {
	name = "SixZhidi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local acard = SixZhidiCard:clone()
			acard:addSubcard(cards[1])
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@SixZhidi"
	end
}
SixZhidi = sgs.CreateTriggerSkill {
	name = "SixZhidi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.TargetConfirming },
	view_as_skill = SixZhidiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if not player:isKongcheng() then
					if player:getPile("know"):length() == 0 then
						room:askForUseCard(player, "@@SixZhidi", "@SixZhidi")
					end
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() then
				if use.to:contains(player) then
					local card = use.card
					local knows = player:getPile("know")
					if knows:length() > 0 then
						local same_color = sgs.IntList()
						local different_color = sgs.IntList()
						for _, cid in sgs.qlist(knows) do
							if sgs.Sanguosha:getCard(cid):sameColorWith(card) then
								same_color:append(cid)
							else
								different_color:append(cid)
							end
						end
						if same_color:length() > 0 then
							if room:askForSkillInvoke(player, self:objectName(), data) then
								room:fillAG(knows, player, different_color)
								local card_id = room:askForAG(player, same_color, false, self:objectName())
								room:clearAG()
								if card_id ~= -1 and knows:contains(card_id) then
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "",
										self:objectName(), "")
									local cd = sgs.Sanguosha:getCard(card_id)
									room:throwCard(cd, reason, nil)
									room:setCardFlag(card, "SixZhidi")
									player:addMark("SixZhidi")
									room:drawCards(player, 2, self:objectName())
								end
							end
						end
					end
				end
			end
		end
		return false
	end
}
SixZhidiProtect = sgs.CreateTriggerSkill {
	name = "#SixZhidiProtect",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardEffected, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:hasFlag("SixZhidi") then
				if player:getMark("SixZhidi") > 0 then
					local count = player:getMark("SixZhidi") - 1
					player:setMark("SixZhidi", count)
					local msg = sgs.LogMessage()
					msg.type = "#SixZhidiNullify"
					msg.from = player
					msg.arg = "SixZhidi"
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:hasFlag("SixZhidi") then
				for _, p in sgs.qlist(use.to) do
					p:removeMark("SixZhidi")
				end
				room:setCardFlag(card, "-SixZhidi")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
LiuYe_Six:addSkill(SixZhidi)
LiuYe_Six:addSkill(SixZhidiProtect)
extension_six:insertRelatedSkills("SixZhidi", "#SixZhidiProtect")

----------------------------------------------------------------------------------------------------

--[[ 魏 014 董昭
	武将：DongZhao_Six
	武将名：董昭
	体力上限：3
	武将技能：
		筹纂(SixChouzuan)：出牌阶段限一次，你可以选择一名其他角色，弃置等同于其攻击范围的手牌并将你的武将牌翻面，若如此做，该角色攻击范围内的所有其他角色须选择一项：令该角色摸一张牌，或受到该角色对其造成的1点伤害。
		阴谋(SixYinmou)：锁定技，每当你受到一次伤害后，你摸一张牌，然后若你的武将牌背面朝上，你将你的武将牌翻面。old
        阴谋：每当你的手牌数大于你当前的体力值时，若你的武将牌背面朝上，你可以将你的武将牌翻面，然后摸一张牌。

	状态：验证通过
]]
--
DongZhao_Six = sgs.General(extension_six, "DongZhao_Six", "wei", 3, true)

--[[
	技能名：筹纂
	技能：SixChouzuan
	描述：出牌阶段限一次，你可以选择一名其他角色，弃置等同于其攻击范围的手牌并将你的武将牌翻面，若如此做，该角色攻击范围内的所有其他角色须选择一项：令该角色摸一张牌，或受到该角色对其造成的1点伤害。
	状态：验证通过
	注：如果有自带攻击范围无限的角色，董昭需要弃置10000张手牌。
]]
--
SixChouzuanDummyCard = sgs.CreateSkillCard {
	name = "SixChouzuanDummyCard",
}
SixChouzuanCard = sgs.CreateSkillCard {
	name = "SixChouzuanCard",
	target_fixed = false,
	will_discard = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				local dummy = SixChouzuanDummyCard:clone()
				local handcards = sgs.Self:getHandcards()
				for _, card in sgs.qlist(handcards) do
					if not sgs.Self:isJilei(card) then
						dummy:addSubcard(card)
					end
				end
				return dummy:subcardsLength() >= to_select:getAttackRange()
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local source = effect.from
		local dest = effect.to
		room:notifySkillInvoked(source, "SixChouzuan")
		room:askForDiscard(source, "SixChouzuan", dest:getAttackRange(), dest:getAttackRange(), false, false)
		source:turnOver()
		for _, target in sgs.qlist(room:getOtherPlayers(dest)) do
			if dest:inMyAttackRange(target) then
				local choice = room:askForChoice(target, "SixChouzuan", "SixChouzuanDraw+SixChouzuanDamage")
				if choice == "SixChouzuanDraw" then
					room:drawCards(dest, 1, "SixChouzuan")
				elseif choice == "SixChouzuanDamage" then
					room:damage(sgs.DamageStruct("SixChouzuan", dest, target))
				end
			end
		end
	end
}
SixChouzuan = sgs.CreateViewAsSkill {
	name = "SixChouzuan",
	n = 0,
	view_as = function()
		return SixChouzuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		if not player:hasUsed("#SixChouzuanCard") then
			local dummy = SixChouzuanDummyCard:clone() --防鸡肋
			local handcards = player:getHandcards()
			for _, card in sgs.qlist(handcards) do
				if not player:isJilei(card) then
					dummy:addSubcard(card)
				end
			end
			return dummy:subcardsLength() > 0
		end
	end
}
DongZhao_Six:addSkill(SixChouzuan)

--[[
	技能名：阴谋
	技能：SixYinmou
	描述：锁定技，每当你受到一次伤害后，你摸一张牌，然后若你的武将牌背面朝上，你将你的武将牌翻面。
	状态：验证通过
]]
--
--[[
SixYinmou = sgs.CreateTriggerSkill{
	name = "SixYinmou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		msg.type = "#TriggerSkill"
		msg.from = player
		msg.arg = self:objectName()
		room:sendLog(msg)
		room:notifySkillInvoked(player, self:objectName())
		room:drawCards(player, 1, self:objectName())
		if not player:faceUp() then
			player:turnOver()
		end
	end
}
DongZhao_Six:addSkill(SixYinmou)
]]

SixYinmou = sgs.CreateTriggerSkill {
	name = "SixYinmou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.BeforeCardsMove, sgs.HpChanged },
	on_trigger = function(self, event, player, data, room)
		if not player:faceUp() and player:hasSkill(self:objectName()) and player:getHandcardNum() > player:getHp() and room:askForSkillInvoke(player, self:objectName()) then
			player:turnOver()
			local msg = sgs.LogMessage()
			msg.type = "#TriggerSkill"
			msg.from = player
			msg.arg = self:objectName()
			room:sendLog(msg)
			room:notifySkillInvoked(player, self:objectName())
			room:drawCards(player, 1, self:objectName())
		end
	end
}
DongZhao_Six:addSkill(SixYinmou)

----------------------------------------------------------------------------------------------------

--[[ 魏 015 曹昂
	武将：CaoAng_Six
	武将名：曹昂
	体力上限：4
	武将技能：
		危援(SixWeiyuan)：每当你受到一次伤害后，你可以将你的武将牌翻面并选择一名其他角色，交换你与其装备区里的牌。
	状态：验证通过
]]
--
CaoAng_Six = sgs.General(extension_six, "CaoAng_Six", "wei", 4, true)

--[[
	技能名：危援
	技能：SixWeiyuan
	描述：每当你受到一次伤害后，你可以将你的武将牌翻面并选择一名其他角色，交换你与其装备区里的牌。
	状态：验证通过
]]
--
swapEquip = function(first, second) --todo：去掉PlaceTable
	local room = first:getRoom()
	local equips1 = sgs.IntList()
	local equips2 = sgs.IntList()
	for _, equip in sgs.qlist(first:getEquips()) do
		equips1:append(equip:getId())
	end
	for _, equip in sgs.qlist(second:getEquips()) do
		equips2:append(equip:getId())
	end
	--根据FAQ重写移动顺序，未采用源代码
	local exchangeMove1 = sgs.CardsMoveList()
	local move1 = sgs.CardsMoveStruct()
	move1.card_ids = equips1
	move1.to_place = sgs.Player_PlaceTable
	local move2 = sgs.CardsMoveStruct()
	move2.card_ids = equips2
	move2.to_place = sgs.Player_PlaceTable
	exchangeMove1:append(move1)
	exchangeMove1:append(move2)
	room:moveCardsAtomic(exchangeMove1, false)
	local exchangeMove2 = sgs.CardsMoveList()
	local move3 = sgs.CardsMoveStruct()
	move3.card_ids = equips1
	move3.to = second
	move3.to_place = sgs.Player_PlaceEquip
	local move4 = sgs.CardsMoveStruct()
	move4.card_ids = equips2
	move4.to = first
	move4.to_place = sgs.Player_PlaceEquip
	exchangeMove2:append(move3)
	exchangeMove2:append(move4)
	room:moveCardsAtomic(exchangeMove2, false)
end
SixWeiyuan = sgs.CreateTriggerSkill {
	name = "SixWeiyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@SixWeiyuan",
			true, true)
		if target then
			player:turnOver()
			swapEquip(player, target)
		end
	end
}
CaoAng_Six:addSkill(SixWeiyuan)

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------

--[[ 魏 016 庞德
	武将：PangDe_Six
	武将名：庞德
	体力上限：4
	武将技能：
		抬榇(SixTaichen)：出牌阶段限一次，你可以弃置一张【杀】并选择你攻击范围内的一名其他角色，令其选择一项：对你使用一张红色【杀】，或受到你造成的1点伤害。
		马术：锁定技，当你计算与其他角色的距离时，始终-1。
	状态：验证通过
]]
--
PangDe_Six = sgs.General(extension_six, "PangDe_Six", "wei", 4, true)

--[[
	技能名：抬榇
	技能：SixTaichen
	描述：出牌阶段限一次，你可以弃置一张【杀】并选择你攻击范围内的一名其他角色，令其选择一项：对你使用一张红色【杀】，或受到你造成的1点伤害。
	状态：验证通过
]]
--
SixTaichenCard = sgs.CreateSkillCard {
	name = "SixTaichenCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and sgs.Self:inMyAttackRange(to_select) and
			(to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:broadcastSkillInvoke("SixTaichen")
		room:notifySkillInvoked(effect.from, "SixTaichen")
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			--use_slash = room:askForUseSlashTo(effect.to, effect.from, "prompt", true, false, true, "Slash|.|.|.|red")
			room:setPlayerCardLimitation(effect.to, "use", "Slash|.|.|.|black", false)
			room:setPlayerCardLimitation(effect.to, "use", "Slash|.|.|.|colorless", false)
			room:setPlayerFlag(effect.to, "SixTaichenRed")
			local prompt = string.format("@SixTaichen:%s", effect.from:objectName())
			use_slash = room:askForUseSlashTo(effect.to, effect.from, prompt, true, false, true)
			if effect.to:hasFlag("SixTaichenRed") then
				room:removePlayerCardLimitation(effect.to, "use", "Slash|.|.|.|black")
				room:removePlayerCardLimitation(effect.to, "use", "Slash|.|.|.|colorless")
			end
		end
		if not use_slash then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
		end
	end
}
SixTaichenVS = sgs.CreateViewAsSkill {
	name = "SixTaichen",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash") and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local vs_card = SixTaichenCard:clone()
			vs_card:addSubcard(card)
			return vs_card
		end
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and not player:hasUsed("#SixTaichenCard")
	end
}
SixTaichen = sgs.CreateTriggerSkill {
	name = "SixTaichen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.PreCardUsed },
	view_as_skill = SixTaichenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from:hasFlag("SixTaichenRed") then
			--room:removePlayerFlag(use.from, "SixTaichenRed")
			room:setPlayerFlag(use.from, "-SixTaichenRed")
			room:removePlayerCardLimitation(use.from, "use", "Slash|.|.|.|black")
			room:removePlayerCardLimitation(use.from, "use", "Slash|.|.|.|colorless")
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
PangDe_Six:addSkill(SixTaichen)

--[[
	技能名：马术
	技能：mashu
	描述：锁定技，当你计算与其他角色的距离时，始终-1。
	状态：原有技能
]]
--
PangDe_Six:addSkill("mashu")


----------------------------------------------------------------------------------------------------
--                                             蜀
----------------------------------------------------------------------------------------------------


--[[ 蜀 001 刘备
	武将：LiuBei_Six
	武将名：刘备
	体力上限：4
	武将技能：
		仁德(SixRende)：出牌阶段，你可以将任意数量的手牌交给其他角色，若此阶段你以此法给出了两张或更多的手牌，弃牌阶段开始时，你可以回复1点体力，或摸两张牌。
		激将：主公技，当你需要使用或打出一张【杀】时，你可令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：验证通过
]]
--
LiuBei_Six = sgs.General(extension_six, "LiuBei_Six$", "shu", 4, true)

--[[
	技能名：仁德
	技能：SixRende
	描述：出牌阶段，你可以将任意数量的手牌交给其他角色，若此阶段你以此法给出了两张或更多的手牌，弃牌阶段开始时，你可以回复1点体力，或摸两张牌。
	状态：验证通过
	注：个别时候，其他角色死亡时会闪退。
]]
--
SixRendeCard = sgs.CreateSkillCard {
	name = "SixRendeCard",
	target_fixed = false,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local target
		if #targets == 0 then --todo:删除此段
			local list = room:getAlivePlayers()
			for _, player in sgs.qlist(list) do
				if player:objectName() ~= source:objectName() then
					target = player
					break
				end
			end
		else
			target = targets[1]
		end
		room:broadcastSkillInvoke("SixRende")
		room:notifySkillInvoked(source, "SixRende")
		room:obtainCard(target, self, false)
		local subcards = self:getSubcards()
		local old_value = source:getMark("SixRende")
		local new_value = old_value + subcards:length()
		room:setPlayerMark(source, "SixRende", new_value)
	end
}
SixRendeVS = sgs.CreateViewAsSkill {
	name = "SixRende",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local rende_card = SixRendeCard:clone()
			for i = 1, #cards, 1 do
				local id = cards[i]:getId()
				rende_card:addSubcard(id)
			end
			return rende_card
		end
	end,
}
SixRende = sgs.CreateTriggerSkill {
	name = "SixRende",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = SixRendeVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player, "SixRende", 0)
			return false
		elseif player:getPhase() == sgs.Player_Discard then
			local total = player:getMark("SixRende")
			if total >= 2 then
				local choice = room:askForChoice(player, self:objectName(), "SixRendeRecover+SixRendeDraw+SixRendeCancel")
				local msg = sgs.LogMessage()
				if choice == "SixRendeRecover" then
					msg.type = "#SixRende1"
					msg.from = player
					msg.arg = self:objectName()
					room:sendLog(msg)
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				elseif choice == "SixRendeDraw" then
					msg.type = "#SixRende2"
					msg.from = player
					msg.arg = self:objectName()
					room:sendLog(msg)
					room:drawCards(player, 2)
				end
			end
		end
	end,
}
LiuBei_Six:addSkill(SixRende)

--[[
	技能名：激将
	技能：jijiang
	描述：主公技，当你需要使用或打出一张【杀】时，你可令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。
	状态：原有技能
]]
--
LiuBei_Six:addSkill("jijiang")

----------------------------------------------------------------------------------------------------

--[[ 蜀 004 张飞
	武将：ZhangFei_Six
	武将名：张飞
	体力上限：4
	武将技能：
		咆哮(SixPaoxiao)：出牌阶段，当你需要对一名角色使用【杀】时，你可以令其摸一张牌，然后你视为对其使用一张【杀】，此【杀】若造成伤害，其不计入出牌阶段限制的使用次数。若目标角色因你使用此【杀】造成的伤害而进入濒死状态，你不能发动“咆哮”，直到回合结束。
	状态：验证通过
]]
--
ZhangFei_Six = sgs.General(extension_six, "ZhangFei_Six", "shu", 4, true)

--[[  todo:留到韩遂时对此技能进行检查
	技能名：咆哮
	技能：SixPaoxiao
	描述：出牌阶段，当你需要对一名角色使用【杀】时，你可以令其摸一张牌，然后你视为对其使用一张【杀】，此【杀】若造成伤害，其不计入出牌阶段限制的使用次数。若目标角色因你使用此【杀】造成的伤害而进入濒死状态，你不能发动“咆哮”，直到回合结束。
	状态：验证通过
	注：发动后若关平发动龙吟，然后造成伤害，使用次数会-2。
]]
--
SixPaoxiaoCard = sgs.CreateSkillCard {
	name = "SixPaoxiaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local plist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("SixPaoxiao")
		room:notifySkillInvoked(source, "SixPaoxiao")
		local tarlist = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			tarlist:append(p)
		end
		for _, target in sgs.qlist(tarlist) do
			room:drawCards(target, 1, "SixPaoxiao")
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("SixPaoxiao")
		room:setCardFlag(slash, "SixPaoxiaoSlash")
		room:useCard(sgs.CardUseStruct(slash, source, tarlist), true)
	end
}
SixPaoxiaoVS = sgs.CreateViewAsSkill {
	name = "SixPaoxiao",
	n = 0,
	view_as = function()
		return SixPaoxiaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) and not player:hasFlag("SixPaoxiaoForbidden") then
			if player:canSlashWithoutCrossbow() then --隐藏牌面
				return true
			end
		end
		return false
	end
}
SixPaoxiao = sgs.CreateTriggerSkill {
	name = "SixPaoxiao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused, sgs.Dying },
	view_as_skill = SixPaoxiaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") and card:hasFlag("SixPaoxiaoSlash") and not card:hasFlag("SixPaoxiaoCounted") then
					local zhangfeis = room:findPlayersBySkillName(self:objectName())
					for _, zhangfei in sgs.qlist(zhangfeis) do
						if zhangfei and zhangfei:isAlive() and zhangfei:objectName() == damage.from:objectName() then
							room:addPlayerHistory(zhangfei, card:getClassName(), -1)
							room:setCardFlag(card, "SixPaoxiaoCounted") --多名目标
						end
					end
				end
			end
			return false
		elseif event == sgs.Dying then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local dying = data:toDying()
				local damage = dying.damage
				if damage then
					local card = damage.card
					if card and card:isKindOf("Slash") and card:hasFlag("SixPaoxiaoSlash") and damage.by_user then --张飞造成伤害
						room:setPlayerFlag(player, "SixPaoxiaoForbidden")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhangFei_Six:addSkill(SixPaoxiao)

----------------------------------------------------------------------------------------------------

--[[ 蜀 005 赵云
	武将：ZhaoYun_Six
	武将名：赵云
	体力上限：4
	武将技能：
		龙胆(SixLongdan)：每当你攻击范围内的一名角色成为【杀】的目标后，你可以弃置一张基本牌并将你的武将牌翻面，令此【杀】对其无效；当你的武将牌翻转至正面朝上时，你摸一张牌，然后可以视为对一名其他角色使用一张【杀】（无距离限制）。
	状态：验证通过
]]
--
ZhaoYun_Six = sgs.General(extension_six, "ZhaoYun_Six", "shu", 4, true)

--[[
	技能名：龙胆
	技能：SixLongdan, SixLongdanProtect, SixLongdanNDL
	描述：每当你攻击范围内的一名角色成为【杀】的目标后，你可以弃置一张基本牌并将你的武将牌翻面，令此【杀】对其无效；当你的武将牌翻转至正面朝上时，你摸一张牌，然后可以视为对一名其他角色使用一张【杀】（无距离限制）。
	状态：验证通过
]]
--
SixLongdanCard = sgs.CreateSkillCard {
	name = "SixLongdanCard",
	target_fixed = true,
	will_throw = true,
}
SixLongdanSlashCard = sgs.CreateSkillCard {
	name = "SixLongdanSlashCard",
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("SixLongdan")
		local tarlist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			tarlist:append(targets[i])
		end
		return slash:targetFilter(tarlist, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local tarlist = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			tarlist:append(p)
		end
		for _, p in sgs.qlist(tarlist) do
			if not source:canSlash(p, nil, false) then
				tarlist:removeOne(p)
			end
		end
		if tarlist:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("SixLongdan")
			room:useCard(sgs.CardUseStruct(slash, source, tarlist), false)
		end
	end
}
SixLongdanVS = sgs.CreateViewAsSkill {
	name = "SixLongdan",
	n = 1,
	view_filter = function(self, selected, to_select)
		if string.find(sgs.Sanguosha:getCurrentCardUsePattern(), "2") then
			return false
		else
			return #selected == 0 and to_select:isKindOf("BasicCard") and not sgs.Self:isJilei(to_select)
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@SixLongdan1" then
			if #cards == 1 then
				local card = SixLongdanCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		elseif sgs.Sanguosha:getCurrentCardUsePattern() == "@@SixLongdan2" then
			if #cards == 0 then
				return SixLongdanSlashCard:clone()
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@SixLongdan")
	end,
}
SixLongdan = sgs.CreateTriggerSkill {
	name = "SixLongdan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.TurnedOver },
	view_as_skill = SixLongdanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local zhaoyuns = room:findPlayersBySkillName(self:objectName())
			for _, zhaoyun in sgs.qlist(zhaoyuns) do
				local use = data:toCardUse()
				local slash = use.card
				if slash and slash:isKindOf("Slash") then
					local times = 0
					for _, p in sgs.qlist(use.to) do
						if p:objectName() == player:objectName() then
							times = times + 1
						end
					end
					if times > 0 then
						local prompt = string.format("@SixLongdan:%s", player:objectName())
						for i = 1, times, 1 do
							if zhaoyun:inMyAttackRange(player) then
								if zhaoyun:canDiscard(zhaoyun, "h") then
									room:setPlayerFlag(player, "SixLongdan_Target")
									room:setTag("CurrentUseStruct", data)
									if room:askForUseCard(zhaoyun, "@@SixLongdan1", prompt, 1, sgs.Card_MethodDiscard) then
										room:broadcastSkillInvoke(self:objectName())
										room:notifySkillInvoked(zhaoyun, self:objectName())
										zhaoyun:turnOver()
										room:setCardFlag(slash, "SixLongdan")
										player:addMark("SixLongdan")
									end
									room:removeTag("CurrentUseStruct")
									room:setPlayerFlag(player, "-SixLongdan_Target")
								end
							end
						end
					end
				end
			end
		elseif event == sgs.TurnedOver then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				if player:faceUp() then
					room:drawCards(player, 1, self:objectName())
					room:addPlayerMark(player, "SixLongdan_using", 1)
					room:askForUseCard(player, "@@SixLongdan2", "@SixLongdanSlash", 2)
					room:setPlayerMark(player, "SixLongdan_using", 0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
SixLongdanProtect = sgs.CreateTriggerSkill {
	name = "#SixLongdanProtect",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardEffected, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local card = effect.card
			if card:isKindOf("Slash") and card:hasFlag("SixLongdan") then
				if player:getMark("SixLongdan") > 0 then
					local count = player:getMark("SixLongdan") - 1
					player:setMark("SixLongdan", count)
					local msg = sgs.LogMessage()
					msg.type = "#SixLongdanNullify"
					msg.from = player
					msg.arg = "SixLongdan"
					msg.arg2 = card:objectName()
					room:sendLog(msg)
					return true
				end
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card:hasFlag("SixLongdan") then
				for _, p in sgs.qlist(use.to) do
					p:removeMark("SixLongdan")
				end
				room:setCardFlag(card, "-SixLongdan")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
SixLongdanNDL = sgs.CreateTargetModSkill {
	name = "#SixLongdan-slash-ndl",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("SixLongdan") and (card:getSkillName() == "SixLongdan") then
			return 1000
		else
			return 0
		end
	end
}
ZhaoYun_Six:addSkill(SixLongdan)
ZhaoYun_Six:addSkill(SixLongdanProtect)
ZhaoYun_Six:addSkill(SixLongdanNDL)
extension_six:insertRelatedSkills("SixLongdan", "#SixLongdanProtect")
extension_six:insertRelatedSkills("SixLongdan", "#SixLongdan-slash-ndl")

----------------------------------------------------------------------------------------------------

--[[ 蜀 011 庞统
	武将：PangTong_Six
	武将名：庞统
	体力上限：3
	武将技能：
		屈才(SixQucai)：结束阶段开始时，你可以摸2X张牌（X为你在弃牌阶段弃置的锦囊牌数量）。
		三策(SixSance)：出牌阶段限一次，你可以展示三张不同花色的手牌，令一名其他角色选择其中一张并获得之，然后将其余两张置入弃牌堆。若该角色选择的牌花色为：黑桃，其摸两张牌；红桃，其回复1点体力；梅花，你摸两张牌；方块，你回复1点体力。
	状态：验证通过
]]
--
PangTong_Six = sgs.General(extension_six, "PangTong_Six", "shu", 3, true)

--[[
	技能名：屈才
	技能：SixQucai
	描述：结束阶段开始时，你可以摸2X张牌（X为你在弃牌阶段弃置的锦囊牌数量）。
	状态：验证通过
]]
--
SixQucai = sgs.CreateTriggerSkill {
	name = "SixQucai",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("SixQucai") >= 1 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:drawCards(player, player:getMark("SixQucai") * 2, self:objectName())
					end
				end
			end
			player:setMark("SixQucai", 0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local reason = move.reason.m_reason
				if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					if player:getPhase() == sgs.Player_Discard then
						local tricks = 0
						local card
						for _, id in sgs.qlist(move.card_ids) do
							card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("TrickCard") then
								tricks = tricks + 1
							end
						end
						local markcount = player:getMark("SixQucai")
						room:setPlayerMark(player, "SixQucai", markcount + tricks)
					end
				end
			end
		end
	end
}
PangTong_Six:addSkill(SixQucai)

--[[
	技能名：三策
	技能：SixSance
	描述：出牌阶段限一次，你可以展示三张不同花色的手牌，令一名其他角色选择其中一张并获得之，然后将其余两张置入弃牌堆。若该角色选择的牌花色为：黑桃，其摸两张牌；红桃，其回复1点体力；梅花，你摸两张牌；方块，你回复1点体力。
	状态：验证通过
	注：个别时候，发动此技能会闪退。
]]
--
SixSanceCard = sgs.CreateSkillCard {
	name = "SixSanceCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subcard = self:getSubcards()
		for _, id in sgs.qlist(subcard) do
			room:showCard(source, id)
		end
		room:fillAG(subcard)
		room:setPlayerFlag(source, "SixSance_from")
		local get = room:askForAG(target, subcard, false, "SixSance")
		room:setPlayerFlag(source, "-SixSance_from")
		subcard:removeOne(get)
		local suit = sgs.Sanguosha:getCard(get):getSuit()
		room:obtainCard(target, get, true)
		room:clearAG()

		local move = sgs.CardsMoveStruct()
		move.card_ids = subcard
		move.to_place = sgs.Player_DiscardPile
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), "SixSance", nil)
		room:moveCardsAtomic(move, true)
		local throw_str = {}
		for _, card_id in sgs.qlist(subcard) do
			table.insert(throw_str, sgs.Sanguosha:getCard(card_id):toString())
		end
		local msg = sgs.LogMessage()
		msg.type = "$MoveToDiscardPile"
		msg.from = source
		msg.card_str = table.concat(throw_str, "+")
		room:sendLog(msg)

		if suit == sgs.Card_Spade then
			room:drawCards(target, 2, self:objectName())
		elseif suit == sgs.Card_Heart then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(target, recover)
		elseif suit == sgs.Card_Club then
			room:drawCards(source, 2, self:objectName())
		elseif suit == sgs.Card_Diamond then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	end
}
SixSance = sgs.CreateViewAsSkill {
	name = "SixSance",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected <= 2 then
			local card
			for i = 1, #selected, 1 do
				card = selected[i]
				if card:getSuit() == to_select:getSuit() then
					return false
				end
			end
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 3 then
			local card = SixSanceCard:clone()
			for i = 1, #cards, 1 do
				card:addSubcard(cards[i])
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getHandcardNum() >= 3 and not player:hasUsed("#SixSanceCard")
	end
}
PangTong_Six:addSkill(SixSance)

----------------------------------------------------------------------------------------------------

--[[ 蜀 012 陈到
	武将：ChenDao_Six
	武将名：陈到
	体力上限：4
	武将技能：
		忠勇(SixZhongyong)：每当你攻击范围内的一名其他角色成为【杀】或【决斗】的目标时，若其手牌数小于你的手牌数，你可以摸一张牌，将此【杀】或【决斗】转移给你。
	状态：验证通过
]]
--
ChenDao_Six = sgs.General(extension_six, "ChenDao_Six", "shu", 4, true)

--[[
	技能名：忠勇
	技能：SixZhongyong
	描述：每当你攻击范围内的一名其他角色成为【杀】或【决斗】的目标时，若其手牌数小于你的手牌数，你可以摸一张牌，将此【杀】或【决斗】转移给你。
	状态：验证通过（todo:验证转移目标型的技能关系）
]]
--
SixZhongyong = sgs.CreateTriggerSkill {
	name = "SixZhongyong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card then
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:contains(player) then
				local chendaos = room:findPlayersBySkillName(self:objectName())
				for _, chendao in sgs.qlist(chendaos) do
					local others = sgs.PlayerList()
					for _, p in sgs.qlist(use.to) do
						if p:objectName() ~= player:objectName() then
							others:append(p)
						end
					end
					if chendao:inMyAttackRange(player) and not use.from:isProhibited(chendao, use.card, others) and chendao:objectName() ~= use.from:objectName() then
						if player:getHandcardNum() < chendao:getHandcardNum() then
							local dest = sgs.QVariant()
							dest:setValue(player)
							room:setTag("CurrentUseStruct", data)
							if room:askForSkillInvoke(chendao, self:objectName(), dest) then
								room:drawCards(chendao, 1, self:objectName())
								use.to:removeOne(player)
								use.to:append(chendao)
								room:sortByActionOrder(use.to)
								data:setValue(use)
								room:getThread():trigger(sgs.TargetConfirming, room, chendao, data)
								return false
							end
							room:removeTag("CurrentUseStruct")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
ChenDao_Six:addSkill(SixZhongyong)

----------------------------------------------------------------------------------------------------

--[[ 蜀 013 蒋琬
	武将：JiangWan_Six
	武将名：蒋琬
	体力上限：3
	武将技能：
		筹援(SixChouyuan)：结束阶段开始时，你可以选择一名已受伤的角色，令其摸两张牌，再弃置等同于其体力值的手牌，然后回复1点体力。

	状态：验证通过
]]
--
JiangWan_Six = sgs.General(extension_six, "JiangWan_Six", "shu", 3, true)

--[[
	技能名：筹援
	技能：SixChouyuan
	描述：结束阶段开始时，你可以选择一名已受伤的角色，令其摸两张牌，再弃置等同于其体力值的手牌，然后回复1点体力。
	状态：验证通过
]]
--
SixChouyuanCard = sgs.CreateSkillCard {
	name = "SixChouyuanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:isWounded()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local source = effect.from
		local dest = effect.to
		room:notifySkillInvoked(source, "SixChouyuan")
		room:drawCards(dest, 2, "SixChouyuan")
		room:askForDiscard(dest, "SixChouyuan", dest:getHp(), dest:getHp(), false, false)
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(dest, recover)
	end
}
SixChouyuanVS = sgs.CreateViewAsSkill {
	name = "SixChouyuan",
	n = 0,
	view_as = function(self, cards)
		return SixChouyuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@SixChouyuan"
	end
}
SixChouyuan = sgs.CreateTriggerSkill {
	name = "SixChouyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = SixChouyuanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			room:askForUseCard(player, "@@SixChouyuan", "@SixChouyuan")
		end
		return false
	end
}
JiangWan_Six:addSkill(SixChouyuan)
JiangWan_Six:addSkill("PlusChenggui")

----------------------------------------------------------------------------------------------------

--[[ 蜀 014 李严
	武将：LiYan_Six
	武将名：李严
	体力上限：4
	武将技能：
		误军(SixWujun)：其他角色的摸牌阶段摸牌时，若你的装备区里没有坐骑牌，你可以令其少摸一张牌，然后该角色可以弃置一张手牌，视为对你使用一张【杀】（无距离限制）。
	状态：验证通过
]]
--
LiYan_Six = sgs.General(extension_six, "LiYan_Six", "shu", 4, true)

--[[
	技能名：误军
	技能：SixWujun
	描述：其他角色的摸牌阶段摸牌时，若你的装备区里没有坐骑牌，你可以令其少摸一张牌，然后该角色可以弃置一张手牌，视为对你使用一张【杀】（无距离限制）。
	状态：验证通过
]]
--
SixWujun = sgs.CreateTriggerSkill {
	name = "SixWujun",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards, sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local liyans = room:findPlayersBySkillName(self:objectName())
		for _, liyan in sgs.qlist(liyans) do
			if event == sgs.DrawNCards then
				if draw.num > 0 then
					if liyan then
						if not (liyan:getEquip(2) or liyan:getEquip(3)) then
							if room:askForSkillInvoke(liyan, self:objectName(), data) then
								room:addPlayerMark(liyan, self:objectName() .. "-Clear")
								room:setPlayerFlag(player, "SixWujun")
								draw.num = draw.num - 1
								data:setValue(draw)
							end
						end
					end
				end
			elseif event == sgs.AfterDrawNCards then
				if liyan and liyan:getMark(self:objectName() .. "-Clear") > 0 then
					if player:hasFlag("SixWujun") and player:canDiscard(player, "h") then
						if player:canSlash(liyan, nil, false) then
							local prompt = string.format("@SixWujun:%s", liyan:objectName())
							if room:askForCard(player, ".", prompt, data, self:objectName()) then
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:deleteLater()
								slash:setSkillName("SixWujun")
								room:useCard(sgs.CardUseStruct(slash, player, liyan), false)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end
}
LiYan_Six:addSkill(SixWujun)

----------------------------------------------------------------------------------------------------

--[[ 蜀 015 王平
	武将：WangPing_Six
	武将名：王平
	体力上限：4
	武将技能：
		武治(SixWuzhi)：出牌阶段限一次，你可以将一张【杀】交给一名角色，然后你可以获得其区域内的一张牌，或弃置其两张手牌。
	状态：验证通过
]]
--
WangPing_Six = sgs.General(extension_six, "WangPing_Six", "shu", 4, true)

--[[
	技能名：武治
	技能：SixWuzhi, SixWuzhiFakeMove
	描述：出牌阶段限一次，你可以将一张【杀】交给一名角色，然后你可以获得其区域内的一张牌，或弃置其两张手牌。
	状态：验证通过
]]
--
SixWuzhiCard = sgs.CreateSkillCard {
	name = "SixWuzhiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	handling_method = sgs.Card_MethodNone,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local source = effect.from
		local target = effect.to
		room:notifySkillInvoked(source, "SixWuzhi")
		target:obtainCard(self)
		local choicelist = {}
		if not target:isAllNude() then
			table.insert(choicelist, "SixWuzhiGet")
		end
		if source:canDiscard(target, "h") then
			table.insert(choicelist, "SixWuzhiDiscard")
		end
		table.insert(choicelist, "SixWuzhiCancel")
		local dest = sgs.QVariant()
		dest:setValue(target)
		local choice = room:askForChoice(source, "SixWuzhi", table.concat(choicelist, "+"), dest)
		if choice == "SixWuzhiGet" then
			local card_id = room:askForCardChosen(source, target, "hej", self:objectName())
			room:obtainCard(source, card_id)
		elseif choice == "SixWuzhiDiscard" then
			room:setPlayerFlag(source, "SixWuzhi_InTempMoving")
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			local card_ids = sgs.IntList()
			local original_places = sgs.IntList()
			for i = 0, 1, 1 do
				if not source:canDiscard(target, "h") then break end
				card_ids:append(room:askForCardChosen(source, target, "h", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i)))
				dummy:addSubcard(card_ids:at(i))
				target:addToPile("#SixWuzhi", card_ids:at(i), false)
			end
			if dummy:subcardsLength() > 0 then
				for i = 0, dummy:subcardsLength() - 1, 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), target, original_places:at(i), false)
				end
			end
			room:setPlayerFlag(source, "-SixWuzhi_InTempMoving")
			if dummy:subcardsLength() > 0 then
				room:throwCard(dummy, target, source)
			end
		end
	end
}
SixWuzhi = sgs.CreateViewAsSkill {
	name = "SixWuzhi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = SixWuzhiCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SixWuzhiCard")
	end
}
SixWuzhiFakeMove = sgs.CreateTriggerSkill {
	name = "#SixWuzhi-fake-move",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("SixWuzhi_InTempMoving") then
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
WangPing_Six:addSkill(SixWuzhi)
WangPing_Six:addSkill(SixWuzhiFakeMove)
extension_six:insertRelatedSkills("SixWuzhi", "#SixWuzhi-fake-move")

----------------------------------------------------------------------------------------------------

--[[ 蜀 016 糜夫人
	武将：MiFuRen_Six
	武将名：糜夫人
	体力上限：3
	武将技能：
		护嗣(SixHusi)：当距离1以内的角色的牌于其回合外被除其之外的其他角色获得或弃置前，你可以终止当前移动牌的结算，再摸一张牌，然后失去1点体力。
		投井(SixToujing)：锁定技，当你死亡时，伤害来源为自己，且你需将所有牌交给一名其他角色，然后令其回复2点体力。
	状态：验证失败（护嗣）
]]
--
MiFuRen_Six = sgs.General(extension_six, "MiFuRen_Six", "shu", 3, false)

--[[
	技能名：护嗣
	技能：SixHusi, SixHusiReturn, SixHusiFakeMove
	描述：当距离1以内的角色的牌于其回合外被除其之外的其他角色获得或弃置前，你可以终止当前移动牌的结算，再摸一张牌，然后失去1点体力。
	状态：验证失败（置入处理区时无法发动）
	注：由于太阳神三国杀的原因，此技能中“终止当前移动牌的结算”的效果实际为：该角色在被弃置或获得牌后，立刻重新获得此牌，中间不会触发技能；
		被弃置牌时，即将被弃置的牌会显示；
		被获得牌时，在获得方的客户端，获得的牌会显示。
]]
--
SixHusiCardIds = sgs.IntList()
SixHusiOriginal = sgs.IntList()
SixHusi = sgs.CreateTriggerSkill {
	name = "SixHusi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		local target = move.to
		if source and source:isAlive() and player:distanceTo(source) <= 1 and source:getPhase() == sgs.Player_NotActive then
			local reason = move.reason
			if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
				local flag = false
				if move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD --弃置
					and (reason.m_playerId ~= nil and reason.m_playerId ~= source:objectName() and reason.m_playerId ~= player:objectName()) then                  --被其他角色弃置
					flag = true
				end
				if (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_GOTCARD and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) --获得
					and (source:objectName() ~= target:objectName() and player:objectName() ~= target:objectName()) then                                                                                                                                                           --被其他角色获得
					flag = true
				end
				--[[if move.to_place == sgs.Player_PlaceTable  --置入处理区（突袭缔盟）
					and (reason.m_playerId ~= nil and reason.m_playerId ~= source:objectName() and reason.m_playerId ~= player:objectName()) then  --被其他角色置入处理区
					flag = true
				end]]
				--todo:研究moveCards的机构
				if flag then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local Ssource
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:objectName() == source:objectName() then
								Ssource = p
								break
							end
						end
						local original_places = sgs.IntList()
						--room:setPlayerFlag(Ssource, "SixHusi_InTempMoving")
						room:setPlayerMark(Ssource, "SixHusi_InTempMoving", source:aliveCount())
						room:setPlayerFlag(Ssource, "-SixHusiReturned")
						for _, id in sgs.qlist(move.card_ids) do
							original_places:append(room:getCardPlace(id))
							--room:moveCardTo(sgs.Sanguosha:getCard(id), Other, sgs.Player_PlaceSpecial, false)
							--Other:addToPile("SixHusi", id, false)
						end
						SixHusiCardIds = move.card_ids
						SixHusiOriginal = original_places

						room:drawCards(player, 1, self:objectName())
						room:loseHp(player)
					end
				end
			end
		end
		return false
	end,
	priority = 10, --模拟移动前
}
SixHusiReturn = sgs.CreateTriggerSkill {
	name = "#SixHusiReturn",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:getMark("SixHusi_InTempMoving") > 0 then
			local Ssource
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:objectName() == source:objectName() then
					Ssource = p
					break
				end
			end
			if not Ssource:hasFlag("SixHusiReturned") then
				for i = 0, SixHusiCardIds:length() - 1, 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(SixHusiCardIds:at(i)), Ssource, SixHusiOriginal:at(i), false)
				end
				room:setPlayerFlag(Ssource, "SixHusiReturned")
			end
			room:setPlayerMark(Ssource, "SixHusi_InTempMoving", source:getMark("SixHusi_InTempMoving") - 1) --标志数量与玩家数量相同，保证每个玩家都能阻止后面的技能
			return true
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	priority = 10,
}
SixHusiFakeMove = sgs.CreateTriggerSkill {
	name = "#SixHusi-fake-move",
	events = { sgs.BeforeCardsMove },
	priority = 10,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("SixHusi_InTempMoving") then
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
MiFuRen_Six:addSkill(SixHusi)
MiFuRen_Six:addSkill(SixHusiReturn)
MiFuRen_Six:addSkill(SixHusiFakeMove)
extension_six:insertRelatedSkills("SixHusi", "#SixHusiReturn")
extension_six:insertRelatedSkills("SixHusi", "#SixHusi-fake-move")

--[[
	技能名：投井
	技能：SixToujing
	描述：锁定技，当你死亡时，伤害来源为自己，且你需将所有牌交给一名其他角色，然后令其回复2点体力。
	状态：验证通过
]]
--
SixToujing = sgs.CreateTriggerSkill {
	name = "SixToujing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local msg = sgs.LogMessage()
			msg.type = "#TriggerSkill"
			msg.from = player
			msg.arg = self:objectName()
			room:sendLog(msg)
			local damage = death.damage
			if damage then
				if damage.from and damage.from:objectName() ~= player:objectName() then
					damage.from = player
				end
			else
				damage = sgs.DamageStruct()
				damage.to = player
				damage.from = player
			end
			death.damage = damage
			data:setValue(death)

			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@SixToujing",
				false)
			if target then
				local handcard = player:wholeHandCards()
				room:obtainCard(target, handcard, false)
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 2
				room:recover(target, recover, true)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
MiFuRen_Six:addSkill(SixToujing)


----------------------------------------------------------------------------------------------------

--[[ 吴 012 孙策
	武将：SunCe_Plus
	武将名：孙策
	体力上限：4
	武将技能：
		英武(PlusYingwu)：回合开始时，你可以弃置一张牌或失去1点体力，声明并拥有“英姿”或“英魂”中的一项技能，直到回合结束。
		制霸(PlusZhiba)：主公技，其他吴势力角色的出牌阶段限一次，该角色可以与你拼点，你可以拒绝此拼点。若其没赢，你可以获得两张拼点的牌。
	状态：验证通过
]]
--
SunCe_Plus = sgs.General(extension_six, "SunCe_Plus$", "wu", 4, true)

--[[
	技能：PlusYingwu, PlusYingwuClear
	技能名：英武
	描述：回合开始时，你可以弃置一张牌或失去1点体力，声明并拥有“英姿”或“英魂”中的一项技能，直到回合结束。
	状态：验证通过
	注：若孙策在发动英武后获得了选择的技能，此技能在回合结束后会失去。
]]
--
PlusYingwu = sgs.CreateTriggerSkill {
	name = "PlusYingwu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
			if player:canDiscard(player, "he") or player:getHp() > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					if not (player:canDiscard(player, "he") and room:askForCard(player, ".|.|.|.|.", "@PlusYingwu", data, self:objectName())) then
						if player:getHp() > 0 then
							room:loseHp(player)
						else
							return false
						end
					end
					if player:isAlive() then
						room:broadcastSkillInvoke(self:objectName())
						local choice = room:askForChoice(player, self:objectName(), "yingzi+yinghun")
						if player:hasSkill(choice) then
							room:setPlayerFlag(player, "PlusYingwu_" .. choice)
						end
						room:handleAcquireDetachSkills(player, choice) --异常错误
						--room:acquireSkill(player, choice)
						room:setPlayerFlag(player, "PlusYingwu")
					end
				end
			end
		end
		return false
	end
}
PlusYingwuClear = sgs.CreateTriggerSkill {
	name = "#PlusYingwuClear",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:hasFlag("PlusYingwu") then
			local skills = { "yingzi", "yinghun" }
			local skills_detached = {}
			for _, skill in ipairs(skills) do
				if not player:hasFlag("PlusYingwu_" .. skill) then
					table.insert(skills_detached, --[["-" .. ]] skill)
				end
			end
			if #skills_detached > 0 then
				--room:handleAcquireDetachSkills(player, table.concat(skills_detached, "|"))  --异常错误
				for _, skill in ipairs(skills_detached) do
					room:detachSkillFromPlayer(player, skill)
				end
			end
		end
	end,
	priority = 1
}
SunCe_Plus:addSkill(PlusYingwu)
SunCe_Plus:addSkill(PlusYingwuClear)
SunCe_Plus:addRelateSkill("yingzi")
SunCe_Plus:addRelateSkill("yinghun")
extension:insertRelatedSkills("PlusYingwu", "#PlusYingwuClear")

SunCe_Plus:addSkill("zhiba")

----------------------------------------------------------------------------------------------------

--[[ 吴 013 顾雍
	武将：GuYong_Six
	武将名：顾雍
	体力上限：3
	武将技能：
		亮节(SixLiangjie)：每当你成为【杀】的目标时，若你有手牌，你可以展示所有手牌，若颜色均相同，你可以摸两张牌。
		巧谏(SixQiaojian)：其他角色的判定阶段开始前，你可以令其展示一张手牌，若如此做，你可以弃置一张与此牌花色相同的牌，令该角色跳过此阶段。
	状态：验证通过
]]
--
GuYong_Six = sgs.General(extension_six, "GuYong_Six", "wu", 3, true)

--[[
	技能：SixLiangjie
	技能名：亮节
	描述：每当你成为【杀】的目标时，若你有手牌，你可以展示所有手牌，若颜色均相同，你可以摸两张牌。
	状态：验证通过
]]
--
SixLiangjie = sgs.CreateTriggerSkill {
	name = "SixLiangjie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			if use.to:contains(player) and not player:isKongcheng() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:showAllCards(player)
					if player:wholeHandCards():isBlack() or player:wholeHandCards():isRed() then
						if room:askForSkillInvoke(player, "SixLiangjieDraw", sgs.QVariant("draw")) then
							room:broadcastSkillInvoke(self:objectName())
							room:drawCards(player, 2, self:objectName())
						end
					end
				end
			end
		end
	end
}
GuYong_Six:addSkill(SixLiangjie)

GuYong_Six:addSkill("PlusQiaojian")



----------------------------------------------------------------------------------------------------

--[[ 吴 014 孙鲁班
	武将：SunLuBan_Six
	武将名：孙鲁班
	体力上限：3
	武将技能：
		谮毁(SixZenhui)：其他角色的结束阶段开始时，若其于出牌阶段内使用【杀】造成了伤害，你可以弃置一张黑桃牌，令其攻击范围内你选择的另一名其他角色获得其一张手牌。
		嫁祸(SixJiahuo)：每当你进入濒死状态时，你可以弃置一名其他角色的一至两张手牌，然后若其中有红桃基本牌，你回复1点体力。
	状态：验证通过
]]
--
SunLuBan_Six = sgs.General(extension_six, "SunLuBan_Six", "wu", 3, false)

--[[
	技能：SixZenhui
	技能名：谮毁
	描述：其他角色的结束阶段开始时，若其于出牌阶段内使用【杀】造成了伤害，你可以弃置一张黑桃牌，令其攻击范围内你选择的另一名其他角色获得其一张手牌。
	状态：验证通过
]]
--
SixZenhui = sgs.CreateTriggerSkill {
	name = "SixZenhui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageDone, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			if damage.from and not damage.from:hasSkill(self:objectName()) and damage.from:getPhase() == sgs.Player_Play then
				local card = damage.card
				if card and card:isKindOf("Slash") and damage.by_user then
					room:setPlayerFlag(damage.from, "SixZenhuiDamaged")
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and not player:hasSkill(self:objectName()) then
			if player:hasFlag("SixZenhuiDamaged") then
				room:setPlayerFlag(player, "-SixZenhuiDamaged")
				local sunlubans = room:findPlayersBySkillName(self:objectName())
				for _, sunluban in sgs.qlist(sunlubans) do
					if sunluban and sunluban:canDiscard(sunluban, "he") then
						if room:askForCard(sunluban, ".|spade", "@SixZenhui", data, self:objectName()) then
							room:broadcastSkillInvoke(self:objectName())
							if not player:isKongcheng() then
								local targets = sgs.SPlayerList()
								for _, p in sgs.qlist(room:getOtherPlayers(sunluban)) do
									if p:objectName() ~= player:objectName() and player:inMyAttackRange(p) then
										targets:append(p)
									end
								end
								if not targets:isEmpty() then
									local target = room:askForPlayerChosen(sunluban, targets, self:objectName(),
										"@SixZenhuiPlayer:" .. player:objectName())
									local card_id = room:askForCardChosen(target, player, "h", self:objectName())
									room:obtainCard(target, card_id, false)
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
SunLuBan_Six:addSkill(SixZenhui)

--[[
	技能：SixJiahuo
	技能名：嫁祸
	描述：每当你进入濒死状态时，你可以弃置一名其他角色的一至两张手牌，然后若其中有红桃基本牌，你回复1点体力。
	状态：验证通过
]]
--
SixJiahuoDummyCard = sgs.CreateSkillCard {
	name = "SixJiahuoDummyCard",
}
SixJiahuo = sgs.CreateTriggerSkill {
	name = "SixJiahuo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canDiscard(p, "h") then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@SixJiahuo", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerFlag(target, "SixJiahuo_InTempMoving")
					local dummy = SixJiahuoDummyCard:clone()
					local card_ids = {}
					local original_places = {}
					local count = 0
					for i = 1, 2, 1 do
						if player:canDiscard(target, "h") then
							if i == 2 then
								if not room:askForSkillInvoke(player, "SixJiahuoSecond", sgs.QVariant("second")) then
									break
								end
							end
							local id = room:askForCardChosen(player, target, "h", self:objectName())
							table.insert(card_ids, id)
							local place = room:getCardPlace(id)
							table.insert(original_places, place)
							dummy:addSubcard(id)
							target:addToPile("#SixJiahuo", id, false)
							count = count + 1
						end
					end
					for i = 1, count, 1 do
						local card = sgs.Sanguosha:getCard(card_ids[i])
						room:moveCardTo(card, target, original_places[i], false)
					end
					room:setPlayerFlag(target, "-SixJiahuo_InTempMoving")
					if count > 0 then
						room:throwCard(dummy, target, player)
					end
					for i = 1, count, 1 do
						local card = sgs.Sanguosha:getCard(card_ids[i])
						if card:getSuit() == sgs.Card_Heart and card:isKindOf("BasicCard") then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
							if player:getHp() > 0 then
								return true
							end
							break
						end
					end
				end
			end
		end
	end
}
SixJiahuoAvoidTriggeringCardsMove = sgs.CreateTriggerSkill {
	name = "#SixJiahuoAvoidTriggeringCardsMove",
	frequency = sgs.Skill_Frequent,
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = room:getAllPlayers()
		for _, p in sgs.qlist(targets) do
			if p:hasFlag("SixJiahuo_InTempMoving") then
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 10
}
SunLuBan_Six:addSkill(SixJiahuo)
SunLuBan_Six:addSkill(SixJiahuoAvoidTriggeringCardsMove)
extension_six:insertRelatedSkills("SixJiahuo", "#SixJiahuoAvoidTriggeringCardsMove")

----------------------------------------------------------------------------------------------------



--[[ 吴 016 程普
	武将：ChengPu_Six
	武将名：程普
	体力上限：4
	武将技能：
		醇醪(SixChunlao)：出牌阶段限一次，你可以弃置一张牌并选择一种花色，获得一名有手牌的其他角色的一张手牌，然后展示之，若此牌的花色与你所选的不同，你将此牌置于你的武将牌上，称为“醇”；每当一名角色处于濒死状态时，你可以将两张花色相同的“醇”置入弃牌堆，令该角色视为使用一张【酒】。
	状态：验证通过
]]
--
ChengPu_Six = sgs.General(extension_six, "ChengPu_Six", "wu", 4, true)

--[[
	技能：SixChunlao
	技能名：醇醪
	描述：出牌阶段限一次，你可以弃置一张牌并选择一种花色，获得一名有手牌的其他角色的一张手牌，然后展示之，若此牌的花色与你所选的不同，你将此牌置于你的武将牌上，称为“醇”；每当一名角色处于濒死状态时，你可以将两张花色相同的“醇”置入弃牌堆，令该角色视为使用一张【酒】。
	状态：验证通过
]]
--
SixChunlaoCard = sgs.CreateSkillCard {
	name = "SixChunlaoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local source = effect.from
		local target = effect.to
		room:broadcastSkillInvoke("SixChunlao")
		room:notifySkillInvoked(source, "SixChunlao")
		local suit = room:askForSuit(source, "SixChunlao")
		local msg = sgs.LogMessage()
		msg.type = "#ChooseSuit"
		msg.from = source
		msg.arg = sgs.Card_Suit2String(suit)
		room:sendLog(msg)
		local card_id = room:askForCardChosen(source, target, "h", "SixChunlao")
		room:obtainCard(source, card_id, true)
		if room:getCardPlace(card_id) == sgs.Player_PlaceHand and room:getCardOwner(card_id):objectName() == source:objectName() then
			room:showCard(source, card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			if card:getSuit() ~= suit then
				source:addToPile("beer", card_id)
			end
		end
	end
}
SixChunlaoDummyCard = sgs.CreateSkillCard {
	name = "SixChunlaoDummyCard",
}
SixChunlaoWineCard = sgs.CreateSkillCard {
	name = "SixChunlaoWineCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local who = room:getCurrentDyingPlayer()
		if not who then
			return
		end
		room:broadcastSkillInvoke("SixChunlao")
		room:notifySkillInvoked(source, "SixChunlao")
		local beer = source:getPile("beer")
		local beer_available = sgs.IntList()
		local beer_not_available = sgs.IntList()
		local suit_table = {}
		local duplicate_suit_table = {}
		for _, id in sgs.qlist(beer) do
			if table.contains(suit_table, sgs.Sanguosha:getCard(id):getSuitString()) then
				table.insert(duplicate_suit_table, sgs.Sanguosha:getCard(id):getSuitString())
			else
				table.insert(suit_table, sgs.Sanguosha:getCard(id):getSuitString())
			end
		end
		for _, id in sgs.qlist(beer) do
			if table.contains(duplicate_suit_table, sgs.Sanguosha:getCard(id):getSuitString()) then
				beer_available:append(id)
			else
				beer_not_available:append(id)
			end
		end
		local beer_taken = sgs.IntList()
		room:fillAG(beer, source, beer_not_available) --第一张
		local first_id = room:askForAG(source, beer_available, false, self:objectName())
		if first_id == -1 then
			room:clearAG(source)
			return
		end
		beer_available:removeOne(first_id)
		beer_not_available:append(first_id)
		for _, id in sgs.qlist(beer_available) do
			if sgs.Sanguosha:getCard(id):getSuit() ~= sgs.Sanguosha:getCard(first_id):getSuit() then
				beer_available:removeOne(id)
				beer_not_available:append(id)
			end
		end
		room:clearAG(source)
		room:fillAG(beer, source, beer_not_available) --第二张
		local second_id = room:askForAG(source, beer_available, false, self:objectName())
		if second_id == -1 then
			room:clearAG(source)
			return
		end
		room:clearAG(source)
		local dummy = SixChunlaoDummyCard:clone()
		dummy:addSubcard(first_id)
		dummy:addSubcard(second_id)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "SixChunlao", nil)
		room:throwCard(dummy, reason, nil)
		local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName("_SixChunlao")
		if analeptic:isAvailable(who) then
			room:useCard(sgs.CardUseStruct(analeptic, who, who, false))
		end
	end
}
SixChunlao = sgs.CreateViewAsSkill {
	name = "SixChunlao",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not sgs.Self:isJilei(to_select)
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local card = SixChunlaoCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		else
			return SixChunlaoWineCard:clone()
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SixChunlaoCard") and player:canDiscard(player, "he")
	end,
	enabled_at_response = function(self, player, pattern)
		if string.find(pattern, "peach") then
			local beer = player:getPile("beer")
			if beer:length() >= 2 then
				local suit_table = {}
				for _, id in sgs.qlist(player:getPile("beer")) do
					if table.contains(suit_table, sgs.Sanguosha:getCard(id):getSuitString()) then
						return true
					else
						table.insert(suit_table, sgs.Sanguosha:getCard(id):getSuitString())
					end
				end
			end
		end
		return false
	end
}
ChengPu_Six:addSkill(SixChunlao)

----------------------------------------------------------------------------------------------------



--[[ 吴 016 刘协
	武将：ChengPu_Six
	武将名：刘协
	体力上限：3
	武将技能：
		【密诏】：你可以跳过出牌阶段和弃牌阶段，然后若你是手牌数最多的角色，你将所有手牌交给一名其他角色。
        【救驾】：每当你于回合外需要使用或打出基本牌时，你可以令其他角色选择是否打出一张此基本牌（视为由你使用或打出），若一名角色如此做，你令其摸两张牌。
	状态：验证通过
]]
--
liuxie_Seven = sgs.General(extension_six, "liuxie_Seven", "qun", 3, true)

--[[
	技能：SevenMizhao
	技能名：密诏
	描述：你可以跳过出牌阶段和弃牌阶段，然后若你是手牌数最多的角色，你将所有手牌交给一名其他角色。
	状态：验证通过
]]
--


SevenMizhao = sgs.CreateTriggerSkill {
	name = "SevenMizhao",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play and player:isAlive() and player:hasSkill(self:objectName()) then
				if player:askForSkillInvoke(self:objectName()) then
					player:skip(sgs.Player_Play)
					player:skip(sgs.Player_Discard)
					local max = 0
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						max = math.max(max, p:getHandcardNum())
					end
					if max == player:getHandcardNum() then
						local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
							"SevenMizhao-invoke", true, true)
						if target then
							target:obtainCard(player:wholeHandCards(), false)
						end
					end
				end
			end
		end
		return false
	end
}

liuxie_Seven:addSkill(SevenMizhao)
--[[
	技能：SevenJiujia
	技能名：救驾
	描述：每当你于回合外需要使用或打出基本牌时，你可以令其他角色选择是否打出一张此基本牌（视为由你使用或打出），若一名角色如此做，你令其摸两张牌。
	状态：验证通过
]]
--


SevenJiujiaCard = sgs.CreateSkillCard {
	name = "SevenJiujiaCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local other_players = room:getOtherPlayers(user)
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		for _, p in sgs.qlist(other_players) do
			local prompt = string.format("@@SevenJiujia:%s", self:getUserString():split("+")[1])
			local dt = sgs.QVariant()
			dt:setValue(user)
			local card = room:askForCard(p, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse, p);
			if card then
				p:drawCards(2, self:objectName())
				return card
			end
		end
		room:setPlayerFlag(user, "Global_SevenJiujiaFailed")
		return nil
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local other_players = room:getOtherPlayers(user)
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		for _, p in sgs.qlist(other_players) do
			local prompt = string.format("@@SevenJiujia:%s", self:getUserString():split("+")[1])
			local dt = sgs.QVariant()
			dt:setValue(user)
			local card = room:askForCard(p, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse, p);
			if card then
				p:drawCards(2, self:objectName())
				return card
			end
		end
		room:setPlayerFlag(user, "Global_SevenJiujiaFailed")
		return nil
	end
}

SevenJiujiaVS = sgs.CreateZeroCardViewAsSkill {
	name = "SevenJiujia",
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_SevenJiujiaFailed") then return end
		if pattern == "slash" then
			return true
		elseif pattern == "peach" then
			return not player:hasFlag("Global_PreventPeach")
		elseif string.find(pattern, "analeptic") then
			return true
		end
		return false
	end,
	view_as = function(self)
		local acard = SevenJiujiaCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
			pattern = "analeptic"
		end
		acard:setUserString(pattern)
		return acard
	end
}


SevenJiujia = sgs.CreateTriggerSkill
	{
		name = "SevenJiujia",
		events = { sgs.CardAsked },
		view_as_skill = SevenJiujiaVS,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.CardAsked and player:getPhase() == sgs.Player_NotActive then
				local pattern = data:toStringList()[1]
				if (pattern ~= "jink"
						and pattern ~= "slash"
						and not string.find(pattern, "peach")
					) then
					return false
				end
				local asktext = pattern
				if string.find(pattern, "peach") then
					asktext = "peach"
				end
				if not player:askForSkillInvoke(self:objectName(), data) then return false end
				local dest = sgs.QVariant()
				dest:setValue(player)
				room:setTag("SevenJiujia", dest)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					local dt = sgs.QVariant(0)
					local supplycard = 0
					dt:setValue(player)
					if asktext == "slash" then
						supplycard = room:askForCard(p, asktext, "SevenJiujiaslash", dt, sgs.Card_MethodResponse, p);
					elseif asktext == "jink" then
						supplycard = room:askForCard(p, asktext, "SevenJiujiajink", dt, sgs.Card_MethodResponse, p);
					elseif asktext == "peach" then
						supplycard = room:askForCard(p, asktext, "SevenJiujiapeach", dt, sgs.Card_MethodResponse, p);
					end
					if (supplycard) then
						p:drawCards(2, self:objectName())
						room:provide(supplycard)
						return true
					end
				end
				room:removeTag("SevenJiujia")
			end
		end,
	}

liuxie_Seven:addSkill(SevenJiujia)

----------------------------------------------------------------------------------------------------



--[[ 群 012 王子服
	武将：WangZiFu_Six
	武将名：王子服
	体力上限：4
	武将技能：
	【密变】：出牌阶段限一次，若你的手牌数大于你的体力上限，你可以弃置任意张不同花色的手牌并选择你攻击范围内的一名其他角色，令攻击范围内含有该角色的所有角色（该角色除外）各选择是否展示一张与你弃置的一张牌花色相同的手牌，如此做的角色视为对其使用一张【杀】。
	状态：验证通过
]]
--
WangZiFu_Six = sgs.General(extension_six, "WangZiFu_Six", "qun", 4, true)

SixMiBianCard = sgs.CreateSkillCard {
	name = "SixMiBian",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if targets[1] then
			room:broadcastSkillInvoke(self:objectName())
			for _, p in sgs.qlist(room:getOtherPlayers(targets[1])) do
				if p:inMyAttackRange(targets[1]) then
					local extra = ""
					for _, card in sgs.qlist(self:getSubcards()) do
						if extra ~= "" then extra = extra .. "," end
						extra = extra .. sgs.Sanguosha:getCard(card):getSuitString()
					end
					local dest = sgs.QVariant()
					dest:setValue(targets[1])
					local prompt = string.format("@SixMiBian:%s", targets[1]:objectName())
					local card = room:askForCard(p, ".|" .. extra .. "|.|hand", prompt, dest, sgs.Card_MethodNone)
					if card then
						room:showCard(p, card:getEffectiveId())
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName(self:objectName())
						slash:deleteLater()
						local use = sgs.CardUseStruct()
						use.from = p
						use.to:append(targets[1])
						use.card = slash
						room:useCard(use, false)
						if not targets[1]:isAlive() then
							break
						end
					end
				end
			end
		end
	end
}
SixMiBian = sgs.CreateViewAsSkill {
	name = "SixMiBian",
	n = 4,
	view_filter = function(self, selected, to_select)
		for _, c in sgs.list(selected) do
			if c:getSuit() == to_select:getSuit() then return false end
		end
		return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local skillcard = SixMiBianCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		end
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#SixMiBian")
	end,
}

WangZiFu_Six:addSkill(SixMiBian)






--[[ 群 012 沮授
	武将：WangZiFu_Six
	武将名：沮授
	体力上限：4
	武将技能：
	【谏策】：其他角色的出牌阶段开始时，你可以令其摸一张牌，然后与其拼点。若你赢，你可以获得其所有手牌，若如此做，将等量的手牌交给该角色。若你没赢，你失去1点体力。
	【守略】：锁定技，你的手牌上限+X（X为你装备区里的牌数+2）。
	状态：验证通过
]]
--
JuShou_Six = sgs.General(extension_six, "JuShou_Six", "qun", 3, true)


SixJianCe = sgs.CreatePhaseChangeSkill {
	name = "SixJianCe",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local dest = sgs.QVariant()
			dest:setValue(player)
			if p and p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName(), dest) then
				player:drawCards(1)
				if p:canPindian(player) then
					local success = p:pindian(player, self:objectName(), nil)
					if success then
						local x = player:getHandcardNum()
						local to_exchange = player:wholeHandCards()
						room:moveCardTo(to_exchange, p, sgs.Player_PlaceHand, false)
						to_exchange = room:askForExchange(p, "SixJianCe", x, x)
						room:moveCardTo(to_exchange, player, sgs.Player_PlaceHand, false)
					else
						room:loseHp(p)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Play
	end
}

SixShouLue = sgs.CreateMaxCardsSkill {
	name = "SixShouLue",
	extra_func = function(self, target, player)
		if target:hasSkill(self:objectName()) then
			return target:getEquips():length() + 2
		end
	end
}

JuShou_Six:addSkill(SixJianCe)
JuShou_Six:addSkill(SixShouLue)


HeJin_Six = sgs.General(extension_six, "HeJin_Six", "qun", 4, true)


SixYangShi = sgs.CreateTriggerSkill {
	name = "SixYangShi",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then
			return false
		end
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName()) then
			return false
		end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			p:drawCards(1)
		end
		local card
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then
				card = room:askForExchange(p, self:objectName(), 1, 1, false, "@SixYangShiGive:" .. player:objectName(),
					false)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(),
					"SixYangShi", nil)
				reason.m_playerId = player:objectName()
				room:moveCardTo(card, p, player, sgs.Player_PlaceHand, reason)
			end
		end
		local max = 0
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() > max then
				max = p:getHandcardNum()
			end
		end
		if player:getHandcardNum() > max then
			room:setPlayerCardLimitation(player, "use", "Slash", true)
		end
		return true
	end
}

HeJin_Six:addSkill(SixYangShi)




LiuBei_Seven = sgs.General(extension_six, "LiuBei_Seven$", "shu", 4, true)

SevenRenDe = sgs.CreateTriggerSkill {
	name = "SevenRenDe",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard then
			if player:askForSkillInvoke(self:objectName()) then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastInvoke(self:objectName())
				if player:getHandcardNum() < room:getAlivePlayers():length() then
					player:drawCards(room:getAlivePlayers():length() - player:getHandcardNum())
				end
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover, true)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					local card = nil
					if player:getHandcardNum() > 1 then
						local dest = sgs.QVariant()
						dest:setValue(p)
						card = room:askForCard(player, ".!", "@SevenRenDe:" .. p:objectName(), dest, sgs.Card_MethodNone)
						if not card then
							card = player:getHandcards():at(math.random(0, player:getHandcardNum() - 1))
						end
					else
						card = player:getHandcards():first()
					end
					p:obtainCard(card)
				end
			end
		end
	end
}


LiuBei_Seven:addSkill(SevenRenDe)
LiuBei_Seven:addSkill("jijiang")



WeiYan_Seven = sgs.General(extension_six, "WeiYan_Seven", "shu", 4, true)



SevenJuDiCard = sgs.CreateSkillCard {
	name = "SevenJuDi",
	filter = function(self, targets, to_select)
		if #targets >= 3 then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		return sgs.Self:canDiscard(to_select, "he")
	end,
	on_use = function(self, room, source, targets)
		source:turnOver()
		local map = {}
		local totaltarget = 0
		for _, sp in ipairs(targets) do
			map[sp] = 1
		end
		totaltarget = #targets
		if totaltarget == 1 then
			for _, sp in ipairs(targets) do
				map[sp] = map[sp] + 2
			end
		end

		if totaltarget == 2 then
			local victim = sgs.SPlayerList()
			victim:append(targets[1])
			victim:append(targets[2])
			if not victim:isEmpty() then
				local target = room:askForPlayerChosen(source, victim, self:objectName())
				for _, sp in ipairs(targets) do
					if sp:objectName() == target:objectName() then
						map[sp] = map[sp] + 1
					end
				end
			end
		end

		local dummy = sgs.Sanguosha:cloneCard("slash")
		for _, sp in ipairs(targets) do
			while map[sp] > 0 do
				if source:isAlive() and sp:isAlive() and source:canDiscard(sp, "he") then
					local card_id = room:askForCardChosen(source, sp, "he", self:objectName(), false,
						sgs.Card_MethodDiscard)
					room:throwCard(card_id, sp, source)
					if sgs.Sanguosha:getCard(card_id):isKindOf("Jink") then
						dummy:addSubcard(sgs.Sanguosha:getCard(card_id))
					end
				end
				map[sp] = map[sp] - 1
			end
		end
		if dummy:subcardsLength() > 0 and source:askForSkillInvoke(self:objectName()) then
			source:obtainCard(dummy)
		end
		dummy:deleteLater()
	end
}
SevenJuDiVS = sgs.CreateViewAsSkill {
	name = "SevenJuDi",
	n = 0,
	view_as = function()
		return SevenJuDiCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@SevenJuDi"
	end
}
SevenJuDi = sgs.CreatePhaseChangeSkill {
	name = "SevenJuDi",
	view_as_skill = SevenJuDiVS,
	on_phasechange = function(self, target)
		local room = target:getRoom()
		if target:getPhase() == sgs.Player_Finish then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(target)) do
				if target:canDiscard(p, "he") then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			if room:askForUseCard(target, "@@SevenJuDi", "@SevenJuDi-card") then
			end
		end
	end
}

WeiYan_Seven:addSkill(SevenJuDi)


MaZhong_Seven = sgs.General(extension_six, "MaZhong_Seven", "shu", 4, true)


SevenKanLuanCard = sgs.CreateSkillCard {
	name = "SevenKanLuan",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end

		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		for _, cd in sgs.qlist(self:getSubcards()) do
			slash:addSubcard(cd)
		end
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
			slash:deleteLater()
			if self:subcardsLength() >= source:getHp() then
				for _, target in ipairs(targets) do
					if target:getEquips():length() > 0 then
						local card_id = room:askForCardChosen(source, target, "e", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
						room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
					end
				end
			end
		end
	end
}
SevenKanLuanVS = sgs.CreateViewAsSkill {
	name = "SevenKanLuan",
	n = 999,
	view_filter = function(self, selected, to_select)
		local x = sgs.Self:getHandcardNum() - sgs.Self:getHp()
		return #selected < x and not sgs.Self:isJilei(to_select) and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local x = sgs.Self:getHandcardNum() - sgs.Self:getHp()
		if #cards ~= x then return nil end
		local card = SevenKanLuanCard:clone()
		for _, cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@SevenKanLuan")
	end
}
SevenKanLuan = sgs.CreateTriggerSkill {
	name = "SevenKanLuan",
	view_as_skill = SevenKanLuanVS,
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			if player:getHandcardNum() > player:getHp() then
				room:askForUseCard(player, "@@SevenKanLuan", "@SevenKanLuan", -1, sgs.Card_MethodNone)
			end
		end
		return false
	end
}



MaZhong_Seven:addSkill(SevenKanLuan)


MaLiang_Seven = sgs.General(extension_six, "MaLiang_Seven", "shu", 3, true)


SevenZhaoXiangCard = sgs.CreateSkillCard {
	name = "SevenZhaoXiang",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getEquips():length() > 0
	end,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		local target = targets[1]
		if target:getEquips():length() > 0 then
			local card_id = room:askForCardChosen(source, target, "e", self:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
			room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
			target:drawCards(2)
		end
	end,
}
SevenZhaoXiang = sgs.CreateZeroCardViewAsSkill {
	name = "SevenZhaoXiang",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		local card = SevenZhaoXiangCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SevenZhaoXiang")
	end,
}



SevenZhenShi = sgs.CreateTriggerSkill {
	name = "SevenZhenShi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard then
			if player:getHandcardNum() > player:getHp() then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"SevenZhenShi-invoke", true, true)
				if target then
					room:setPlayerFlag(target, "SevenZhenShi")
					local to_exchange = room:askForExchange(player, "SevenZhenShi", 2, player:getHandcardNum(), true,
						"@SevenZhenShi")
					room:setPlayerFlag(target, "-SevenZhenShi")
					room:moveCardTo(to_exchange, target, sgs.Player_PlaceHand, false)

					room:notifySkillInvoked(player, self:objectName())
					room:broadcastInvoke(self:objectName())

					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover, true)
				end
			end
		end
	end
}


MaLiang_Seven:addSkill(SevenZhaoXiang)
MaLiang_Seven:addSkill(SevenZhenShi)



SiMaYi_Seven = sgs.General(extension_six, "SiMaYi_Seven", "wei", 3, true)



SevenTaoHui = sgs.CreateTriggerSkill {
	name = "SevenTaoHui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()

		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			player:turnOver()
			room:drawCards(player, 2, self:objectName())
		end
	end,
}

SevenLangMou = sgs.CreateTriggerSkill {
	name = "SevenLangMou",
	events = { sgs.TurnedOver, sgs.FinishJudge },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnedOver then
			if not player:faceUp() or not room:askForSkillInvoke(player, self:objectName()) then return false end
			local judge = sgs.JudgeStruct()
			judge.reason = self:objectName()
			judge.play_animation = false
			judge.who = player
			room:judge(judge)
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				player:obtainCard(judge.card)
			end
		end
		return false
	end
}


SevenQuanBian = sgs.CreateTriggerSkill {
	name = "SevenQuanBian",
	events = { sgs.AskForRetrial },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isKongcheng() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@SevenQuanBian-card",
			judge.who:objectName(),
			self:objectName(),
			judge.reason,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName())
			local cdata = sgs.QVariant()
			cdata:setValue(card)
			if room:askForSkillInvoke(player, self:objectName(), cdata) then
				if card:isRed() then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:recover(p, sgs.RecoverStruct(player))
					end
				elseif card:isBlack() then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:loseHp(p)
					end
				end
			end
		end
		return false
	end
}










SiMaYi_Seven:addSkill(SevenTaoHui)
SiMaYi_Seven:addSkill(SevenLangMou)
SiMaYi_Seven:addSkill(SevenQuanBian)



LiuYe_Seven = sgs.General(extension_six, "LiuYe_Seven", "wei", 3, true)





local function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end



SevenZhiDi = sgs.CreateTriggerSkill
	{
		name = "SevenZhiDi",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.EventPhaseStart },
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Play then
					local target = sgs.QVariant()
					target:setValue(player)
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if (p and p:objectName() ~= player:objectName()) then
							local choices = {}
							for i = 0, 10000 do
								local card = sgs.Sanguosha:getEngineCard(i)
								if card == nil then break end
								if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
									if card:isAvailable(player) and card:isNDTrick() then
										table.insert(choices, card:objectName())
									end
								end
							end
							if next(choices) ~= nil and room:askForSkillInvoke(p, self:objectName(), target) then
								local pattern = room:askForChoice(p, self:objectName(), table.concat(choices, "+"),
									target)
								if pattern and pattern ~= "cancel" then
									ChoiceLog(p, pattern)
									room:addPlayerMark(player, "&SevenZhiDi+" .. pattern .. "+-Clear")
									local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
									poi:deleteLater()
									room:setPlayerCardLimitation(player, "use, response", poi:objectName(), true)
								end
							end
						end
					end
				end
			end
			return false
		end,
		can_trigger = function(self, target)
			return target
		end,
	}

SevenChuaiYi = sgs.CreateTriggerSkill {
	name = "SevenChuaiYi",
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and not damage.from:isKongcheng() and not player:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				local card = room:askForCard(damage.from, ".!", "@SevenChuaiYi-show", data, sgs.Card_MethodNone)
				local carda = room:askForCard(damage.to, ".!", "@SevenChuaiYi-show", data, sgs.Card_MethodNone)
				room:showCard(damage.to, carda:getEffectiveId())
				room:showCard(damage.from, card:getEffectiveId())
				if card:getSuit() ~= carda:getSuit() then
					local log = sgs.LogMessage()
					log.type = "#SevenChuaiYiDecrease"
					log.from = player
					log.arg = damage.damage
					log.arg2 = damage.damage - 1
					room:sendLog(log)
					damage.damage = damage.damage - 1
					data:setValue(damage)
					if damage.damage <= 0 then
						damage.prevented = true
						data:setValue(damage)
						return true
					end
				else
					room:throwCard(carda, damage.to, damage.to)
				end
			end
		end
		return false
	end
}

LiuYe_Seven:addSkill(SevenZhiDi)
LiuYe_Seven:addSkill(SevenChuaiYi)

CaoAng_Seven = sgs.General(extension_six, "CaoAng_Seven", "wei", 4, true)

SevenWeiYuanCard = sgs.CreateSkillCard {
	name = "SevenWeiYuan",
	target_fixed = true,
	on_use = function(self, room, player, targets)
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		if self:getSubcards():isEmpty() then
			room:loseHp(player)
			if not who:isNude() then
				local id = room:askForCardChosen(player, who, "he", self:objectName())
				if id ~= -1 then
					room:obtainCard(player, id, false)
				end
			end
		else
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			if card:isKindOf("EquipCard") and card:isAvailable(who) then
				room:useCard(sgs.CardUseStruct(card, who, who))
			end
		end
		if player:isAlive() then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(who, recover)
		end
	end
}
SevenWeiYuan = sgs.CreateViewAsSkill {
	name = "SevenWeiYuan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("EquipCard")
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern ~= "peach" or not player:canDiscard(player, "he") or player:getHp() <= 1 then return false end
		local dyingobj = player:property("currentdying"):toString()
		local who = nil
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:objectName() == dyingobj then
				who = p
				break
			end
		end
		if not who then return false end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 or #cards == 0 then
			local card = SevenWeiYuanCard:clone()
			if #cards == 1 then
				card:addSubcard(cards[1])
			end
			return card
		end
		return nil
	end
}


CaoAng_Seven:addSkill(SevenWeiYuan)

XuYou_Seven = sgs.General(extension_six, "XuYou_Seven", "wei", 3, true)


SevenJuGong = sgs.CreateTriggerSkill {
	name = "SevenJuGong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards, sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if event == sgs.DrawNCards then
			draw.num = draw.num + player:getLostHp()
			room:broadcastInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			data:setValue(draw)
		elseif event == sgs.AfterDrawNCards then
			local max = 0
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() > max then
					max = p:getHandcardNum()
				end
			end
			if player:getHandcardNum() > max then
				local choice = room:askForChoice(player, self:objectName(), "loseHp+discard")
				if choice == "loseHp" then
					room:loseHp(player)
				elseif choice == "discard" then
					room:askForDiscard(player, self:objectName(), player:getLostHp(), player:getLostHp(), false, true)
				end
			end
		end
	end
}

SevenFenLiangCard = sgs.CreateSkillCard {
	name = "SevenFenLiang",
	will_throw = true,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
			to_select:getHandcardNum() > to_select:getHp() and sgs.Self:getCardCount() >= sgs.Self:distanceTo(to_select)
	end,

	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@SevenFenLiang")
		local target = targets[1]
		room:askForDiscard(source, self:objectName(), source:distanceTo(target), source:distanceTo(target), false, true)
		target:throwAllHandCards()
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = target
		damage.damage = 1
		room:damage(damage)
	end
}

SevenFenLiangVS = sgs.CreateViewAsSkill {
	name = "SevenFenLiang",
	n = 0,
	view_as = function(self, cards)
		return SevenFenLiangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@SevenFenLiang") >= 1
	end
}
SevenFenLiang = sgs.CreateTriggerSkill {
	name = "SevenFenLiang",
	frequency = sgs.Skill_Limited,
	events = {},
	limit_mark = "@SevenFenLiang",
	view_as_skill = SevenFenLiangVS,
	on_trigger = function(self, event, player, data)
	end
}







XuYou_Seven:addSkill(SevenJuGong)
XuYou_Seven:addSkill(SevenFenLiang)


ZhuGeDan_Seven = sgs.General(extension_six, "ZhuGeDan_Seven", "wei", 3, true)


SevenPingPan = sgs.CreateTriggerSkill {
	name = "SevenPingPan",
	events = { sgs.Dying, sgs.BuryVictim },
	on_trigger = function(self, event, player, data, room)
		local target = nil
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.damage and dying.damage.from then
				target = dying.damage.from
			end
			if (dying.who:objectName() ~= player:objectName()) and target and target:objectName() == player:objectName() and not dying.who:isLord() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastProperty(player, "role", player:getRole())
					room:broadcastProperty(dying.who, "role", dying.who:getRole())
					player:drawCards(3)
					if not player:isLord() then
						room:setPlayerProperty(dying.who, "role", sgs.QVariant(player:getRole()))
					else
						room:setPlayerProperty(dying.who, "role", sgs.QVariant("loyalist"))
					end
					room:broadcastProperty(dying.who, "role", dying.who:getRole())

					--checkgameover
				end
			end
		elseif event == sgs.BuryVictim then
			local right = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "rebel" or p:getRole() == "renegade" then
					right = false
				end
			end
			if right then
				room:gameOver("lord+loyalist")
			end
		end
		return false
	end
}




SevenHuBei = sgs.CreateTriggerSkill {
	name = "SevenHuBei",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:isDead() then
				return false
			end
			for _, zhugedan in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not zhugedan or zhugedan:isDead() then continue end
				local dest = sgs.QVariant()
				dest:setValue(zhugedan)
				if zhugedan:canDiscard(zhugedan, "he") and room:askForSkillInvoke(damage.to, self:objectName(), dest) and room:askForCard(zhugedan, "..", "@SevenHuBei", data, self:objectName()) then
					zhugedan:drawCards(2)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}





ZhuGeDan_Seven:addSkill(SevenPingPan)
ZhuGeDan_Seven:addSkill(SevenHuBei)


CaoZhen_Seven = sgs.General(extension_six, "CaoZhen_Seven", "wei", 4, true)

SevenXiaoRui = sgs.CreateTargetModSkill {
	name = "SevenXiaoRui",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and from:getPhase() == sgs.Player_Play then
			return from:getLostHp()
		end
	end
}



SevenXiaoRui_Tr = sgs.CreateTriggerSkill {
	name = "#SevenXiaoRui_Tr",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			local dest = effect.to
			if effect.card and effect.card:isKindOf("Slash") and effect.card:hasFlag("SevenXiaoRui") then
				room:sendCompulsoryTriggerLog(effect.from, "SevenXiaoRui")
				effect.from:turnOver()
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			if player:getPhase() ~= sgs.Player_Play then return false end
			local invoke = false
			for _, p in sgs.qlist(use.to) do
				if not player:inMyAttackRange(p) then
					invoke = true
					break
				end
			end

			if invoke or (use.to:length() > 1 and use.from:getLostHp() > 0) then
				room:setCardFlag(use.card, "SevenXiaoRui")
				room:broadcastInvoke("SevenXiaoRui")
				room:sendCompulsoryTriggerLog(use.from, "SevenXiaoRui")
			end
		end
		return false
	end,
	priority = -1
}


CaoZhen_Seven:addSkill(SevenXiaoRui)
CaoZhen_Seven:addSkill(SevenXiaoRui_Tr)
extension_six:insertRelatedSkills("SevenXiaoRui", "#SevenXiaoRui_Tr")



SunYi_Seven = sgs.General(extension_six, "SunYi_Seven", "wu", 4, true)


SevenYingYongCard = sgs.CreateSkillCard {
	name = "SevenYingYong",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		slash:setSkillName("SevenYingYong")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		local slash = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		slash:setSkillName("SevenYingYong")
		slash:deleteLater()
		for _, target in ipairs(targets) do
			if not source:isProhibited(target, slash) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			source:drawCards(1)
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
SevenYingYongVS = sgs.CreateViewAsSkill {
	name = "SevenYingYong",
	n = 0,
	view_as = function(self, cards)
		return #cards == 0 and SevenYingYongCard:clone() or nil
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@SevenYingYong")
	end
}

SevenYingYong = sgs.CreateTriggerSkill {
	name = "SevenYingYong",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	view_as_skill = SevenYingYongVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			player:setMark("SevenYingYong", 0)
			if player:getPhase() == sgs.Player_Finish and player:hasFlag(self:objectName()) then
				room:askForUseCard(player, "@@SevenYingYong", "@SevenYingYong")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard)
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:setMark("SevenYingYong", player:getMark("SevenYingYong") + move.card_ids:length())
			end
			if (player:getMark("SevenYingYong") >= 2) then
				room:setPlayerFlag(player, self:objectName())
			end
		end
		return false
	end
}



SunYi_Seven:addSkill(SevenYingYong)


ZhuZhi_Seven = sgs.General(extension_six, "ZhuZhi_Seven", "wu", 4, true)



SevenFuTui = sgs.CreateTriggerSkill {
	name = "SevenFuTui",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:isDead() then
				return false
			end
			local from = damage.from
			for _, zhugedan in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not zhugedan or zhugedan:isDead() or zhugedan:isKongcheng() then continue end

				if from and from:getPhase() == sgs.Player_Play and room:askForCard(zhugedan, "..", "@SevenFuTui", data, self:objectName()) then
					if (not from) or from:isDead() then return end
					room:setPlayerFlag(from, "Global_PlayPhaseTerminated")
					break
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

ZhuZhi_Seven:addSkill(SevenFuTui)


ZuMao_Seven = sgs.General(extension_six, "ZuMao_Seven", "wu", 4, true)

SevenYiZe = sgs.CreateTriggerSkill {
	name = "SevenYiZe",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getHandcardNum() < player:getHp() and room:askForSkillInvoke(player, self:objectName()) then
					player:drawCards(player:getHp() - player:getHandcardNum())
					room:notifySkillInvoked(player, self:objectName())
				end
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getEquips():length() > 0 then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "SevenYiZe-invoke", true,
						true)
					if not target then return false end
					local card_id = room:askForCardChosen(player, target, "e", self:objectName())
					local card = sgs.Sanguosha:getCard(card_id)
					player:obtainCard(card)
				end
			end
		end
	end
}

SevenYinBing = sgs.CreateProhibitSkill {
	name = "SevenYinBing",
	is_prohibited = function(self, from, to, card)
		if card:isKindOf("Slash") then
			local rangefix = 0
			--[[if card:isVirtualCard() then
				local subcards = card:getSubcards()
				if from:getWeapon() and subcards:contains(from:getWeapon():getId()) then
					local weapon = from:getWeapon():getRealCard():toWeapon()
					rangefix = rangefix + weapon:getRange() - 1
				end
				if from:getOffensiveHorse() and subcards:contains(self:getOffensiveHorse():getId()) then
					rangefix = rangefix + 1
				end
			end]]
			for _, p in sgs.qlist(from:getAliveSiblings()) do
				if p:hasSkill(self:objectName()) and (p:objectName() ~= to:objectName() and to:getEquips():isEmpty()) and (p:getHandcardNum() > p:getHp())
					and (from:distanceTo(p, rangefix) <= from:getAttackRange()) then
					return true
				end
			end
		end
		return false
	end
}


ZuMao_Seven:addSkill(SevenYiZe)
ZuMao_Seven:addSkill(SevenYinBing)


SunJun_Seven = sgs.General(extension_six, "SunJun_Seven", "wu", 3, true)



SevenZhengBianCard = sgs.CreateSkillCard {
	name = "SevenZhengBian",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:hasEquip() then
			room:setPlayerCardLimitation(target, "use,response", "BasicCard", true)
			return false
		end
		local dest = sgs.QVariant()
		dest:setValue(target)
		local choice = room:askForChoice(source, self:objectName(), "SevenZhengBian_limit+SevenZhengBian_equip", dest)
		if choice == "SevenZhengBian_equip" then
			local card_id = room:askForCardChosen(source, target, "e", self:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
			room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
		else
			room:addPlayerMark(target, "&SevenZhengBian+SevenZhengBian_limit+-Clear")
			room:setPlayerCardLimitation(target, "use,response", "BasicCard", true)
		end
	end,
}
SevenZhengBian = sgs.CreateViewAsSkill {
	name = "SevenZhengBian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = SevenZhengBianCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SevenZhengBian")
	end,
}



SevenLanQuan = sgs.CreateTriggerSkill {
	name = "SevenLanQuan",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			player:setMark("SevenLanQuan", 0)
			if player:getPhase() == sgs.Player_Finish and not player:hasFlag(self:objectName()) then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName()) then
						room:notifySkillInvoked(p, self:objectName())
						p:drawCards(2)
						room:broadcastInvoke(self:objectName())
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Play)
				and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE)) then
				player:setMark("SevenLanQuan", player:getMark("SevenLanQuan") + move.card_ids:length())
			end
			if (player:getMark("SevenLanQuan") > 0) then
				room:setPlayerFlag(player, self:objectName())
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player ~= nil
	end,
}

SunJun_Seven:addSkill(SevenZhengBian)
SunJun_Seven:addSkill(SevenLanQuan)

ZhouYu_Seven = sgs.General(extension_six, "ZhouYu_Seven", "wu", 4, true)


SevenQuGao = sgs.CreateTriggerSkill {
	name = "SevenQuGao",
	events = { sgs.TargetConfirmed, sgs.CardEffected },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.card:isNDTrick() then return false end
			if use.card:hasFlag(self:objectName()) then return false end
			if use.to:length() ~= 1 then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:canDiscard(p, "h") and p:objectName() == player:objectName() then
					local typee = use.card:getSuitString()
					local card = room:askForCard(p, ".|" .. typee .. "|.|hand",
						"@SevenQuGao-discard:" .. use.card:getSuitString() .. "::" .. use.card:objectName(), data,
						self:objectName())
					if card then
						room:broadcastSkillInvoke(self:objectName())
						room:setCardFlag(use.card, self:objectName())
						local choice = room:askForChoice(p, self:objectName(), "SevenQuGao_double+SevenQuGao_invalid",
							data)
						if choice == "SevenQuGao_double" then
							room:setCardFlag(use.card, "SevenQuGao_double")
						else
							room:setPlayerFlag(use.to:first(), self:objectName() .. use.card:getEffectiveId())
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			if (not player:isAlive()) then return false end
			local effect = data:toCardEffect()
			if player:hasFlag(self:objectName() .. effect.card:getEffectiveId()) then
				room:setPlayerFlag(player, "-" .. self:objectName() .. effect.card:getEffectiveId())
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end

		return false
	end,
	can_trigger = function(self, player)
		return player ~= nil
	end,
}

SevenQuGaoDouble = sgs.CreateTriggerSkill {
	name = "#SevenQuGaoDouble",
	events = sgs.CardFinished,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not use.card:isNDTrick() then return false end
		if not use.card:hasFlag("SevenQuGao_double") then return false end
		room:setCardFlag(use.card, "-SevenQuGao_double")
		room:useCard(use, false)
		return false
	end
}

ZhouYu_Seven:addSkill(SevenQuGao)
ZhouYu_Seven:addSkill(SevenQuGaoDouble)
extension_six:insertRelatedSkills("SevenQuGao", "#SevenQuGaoDouble")





ShiChangShi_Seven = sgs.General(extension_six, "ShiChangShi_Seven", "qun", 6, true)

SevenBaChao = sgs.CreateTriggerSkill {
	name = "SevenBaChao",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TrickCardCanceling, sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if RIGHT(self, effect.from) and effect.card:hasFlag(self:objectName()) then
				room:broadcastInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(effect.from, self:objectName())
				return true
			end
		elseif ((event == sgs.CardUsed) or (event == sgs.CardResponded)) then
			local card
			local target
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
				target = use.from
			elseif event == sgs.CardResponded then
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
					target = player
				end
			end
			if card and card:isNDTrick() and target and RIGHT(self, target) then
				local result = room:askForChoice(player, self:objectName(), "hp+maxhp")
				if result == "hp" then
					room:loseHp(player)
				else
					room:loseMaxHp(player)
				end
				room:setCardFlag(card, self:objectName())
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

SevenLuanZhengCard = sgs.CreateSkillCard {
	name = "SevenLuanZheng",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local players = room:getAllPlayers()
		for _, player in sgs.qlist(players) do
			if player:isAlive() then
				room:cardEffect(self, source, player)
			end
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
			if p:getNextAlive():objectName() == effect.to:objectName() then
				if p:getHandcardNum() > 0 then
					local id = room:askForCardChosen(effect.to, p, "h", self:objectName())
					local cd = sgs.Sanguosha:getCard(id)
					effect.to:obtainCard(cd, false)
				end
			end
		end
	end
}
SevenLuanZheng = sgs.CreateViewAsSkill {
	name = "SevenLuanZheng",
	n = 0,
	view_as = function()
		return SevenLuanZhengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SevenLuanZheng")
	end
}

ShiChangShi_Seven:addSkill(SevenBaChao)
ShiChangShi_Seven:addSkill(SevenLuanZheng)

XiLu_Seven = sgs.General(extension_six, "XiLu_Seven", "qun", 3, true)

SevenBeiJie = sgs.CreateFilterSkill {
	name = "SevenBeiJie",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return not (to_select:getColor() == "nosuitcolor") and place == sgs.Player_PlaceHand
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		if card:isRed() then
			new_card:setNumber(12)
		elseif card:isBlack() then
			new_card:setNumber(2)
		end
		new_card:setModified(true)
		return new_card
	end,
}

SevenJieMing = sgs.CreateTriggerSkill {
	name = "SevenJieMing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from then
			room:broadcastInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if not damage.from:isKongcheng() then
				local card = room:askForCard(damage.from, "..", "@SevenJieMing", data, self:objectName())
				if card then
					player:obtainCard(card)
				else
					damage.damage = damage.damage - 1
				end
			end
		else
			damage.damage = damage.damage - 1
		end
		damage.prevented = damage.damage < 1

		data:setValue(damage)
		if damage.damage < 1 then
			return true
		end
		return false
	end
}

SevenTaDao = sgs.CreateTriggerSkill {
	name = "SevenTaDao",
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getMark("used_slash_Play") == 0 then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:canPindian(p) then
					local dest = sgs.QVariant()
					dest:setValue(p)
					if room:askForSkillInvoke(player, self:objectName(), dest) then
						local success = p:pindian(player, self:objectName(), nil)
						if (success) then
							room:damage(sgs.DamageStruct(self:objectName(), player, p, 1))
						else
							local targets = sgs.SPlayerList()
							for _, q in sgs.qlist(room:getOtherPlayers(p)) do
								if player:inMyAttackRange(q) then
									targets:append(q)
								end
							end
							if not targets:isEmpty() then
								local target = room:askForPlayerChosen(player, targets, self:objectName())
								room:damage(sgs.DamageStruct(self:objectName(), p, target, 1))
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end

}

XiLu_Seven:addSkill(SevenBeiJie)
XiLu_Seven:addSkill(SevenJieMing)
XiLu_Seven:addSkill(SevenTaDao)

ZhangLu_Seven = sgs.General(extension_six, "ZhangLu_Seven", "qun", 3, true)

SevenChuanJiaoCard = sgs.CreateSkillCard {
	name = "SevenChuanJiao",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local players = room:getAllPlayers()
		local red_targets, black_targets = sgs.SPlayerList(), sgs.SPlayerList()
		for _, player in sgs.qlist(players) do
			if player:isAlive() and not player:isKongcheng() then
				local card_id = room:askForCardChosen(player, player, "h", self:objectName())
				room:showCard(player, card_id)
				if sgs.Sanguosha:getCard(card_id):isRed() then
					red_targets:append(player)
					room:setPlayerFlag(player, "SevenChuanJiaored")
				elseif sgs.Sanguosha:getCard(card_id):isBlack() then
					black_targets:append(player)
					room:setPlayerFlag(player, "SevenChuanJiaoblack")
				end
			end
		end

		local choice = room:askForChoice(source, self:objectName(), "red+black")
		local target
		if choice == "red" then
			target = red_targets
		elseif choice == "black" then
			target = black_targets
		end
		room:drawCards(target, 1)
		for _, player in sgs.qlist(room:getAlivePlayers()) do
			room:setPlayerFlag(player, "-SevenChuanJiaoblack")
			room:setPlayerFlag(player, "-SevenChuanJiaored")
		end
	end,
}
SevenChuanJiao = sgs.CreateViewAsSkill {
	name = "SevenChuanJiao",
	n = 0,
	view_as = function()
		return SevenChuanJiaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SevenChuanJiao")
	end
}

SevenMiDao = sgs.CreateTriggerSkill {
	name = "SevenMiDao",
	events = { sgs.CardFinished, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if use.card and use.card:hasFlag(self:objectName() .. use.from:objectName() .. p:objectName()) then
					local ids = sgs.IntList()
					if use.card:isVirtualCard() then
						ids = use.card:getSubcards()
					else
						ids:append(use.card:getEffectiveId())
					end
					if ids:length() > 0 then
						local all_place_table = true
						for _, id in sgs.qlist(ids) do
							if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
								all_place_table = false
								break
							end
						end
						if all_place_table then
							if room:askForSkillInvoke(p, self:objectName()) then
								p:obtainCard(use.card)
							end
						end
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.card:getNumber() <= 5 and not use.card:isKindOf("SkillCard") and use.to and use.to:length() == 1 then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() ~= use.from:objectName() and use.from:distanceTo(use.to:first()) >= use.from:distanceTo(p) then
						room:setCardFlag(use.card, self:objectName() .. use.from:objectName() .. p:objectName())
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

ZhangLu_Seven:addSkill(SevenChuanJiao)
ZhangLu_Seven:addSkill(SevenMiDao)

XuShaoXuQian_Seven = sgs.General(extension_six, "XuShaoXuQian_Seven", "qun", 3, true)

SevenFengPingCard = sgs.CreateSkillCard {
	name = "SevenFengPing",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:removeTag("SevenFengPing")

		local target = targets[1]
		local dest = sgs.QVariant()
		dest:setValue(target)
		room:setTag("SevenFengPing", dest)
		local choice = room:askForChoice(source, self:objectName(), "red+black", dest)
		local ids = {}
		for _, player in sgs.qlist(room:getOtherPlayers(target)) do
			local prompt = string.format("@SevenFengPing:%s:%s", target:objectName(), choice)
			local card = room:askForCard(player, ".|" .. choice .. "", "@SevenFengPing", dest, self:objectName())
			if card then
				table.insert(ids, card:getEffectiveId())
			end
		end
		room:removeTag("SevenFengPing")
		if #ids > 0 then
			if choice == "red" then
				target:drawCards(#ids)
			elseif choice == "black" and target:canDiscard(target, "he") then
				local prompt = string.format("@SevenFengPing_Throw:%s", #ids)
				local card_ex = room:askForExchange(target, self:objectName(), #ids, #ids, true, "@SevenFengPing_Throw",
					false)
				room:throwCard(card_ex, target)
				for _, id in sgs.qlist(card_ex:getSubcards()) do
					table.insert(ids, id)
				end
			end
			room:setTag("SevenFengPing", sgs.QVariant(table.concat(ids, "+")))
			room:addPlayerMark(source, "SevenFengPing_Play")
		end
	end,
}
SevenFengPing = sgs.CreateViewAsSkill {
	name = "SevenFengPing",
	n = 0,
	view_as = function(self, cards)
		local card = SevenFengPingCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SevenFengPing")
	end
}

SevenYueDan = sgs.CreateTriggerSkill {
	name = "SevenYueDan",
	events = { sgs.MarkChanged },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "SevenFengPing_Play" and mark.who:hasSkill("SevenFengPing") and mark.who:getMark("SevenFengPing_Play") > 0 then
				local ids = room:getTag("SevenFengPing"):toString():split("+") or {}
				if #ids == 0 then return false end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in pairs(ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and room:getCardPlace(id) == sgs.Player_DiscardPile then
						dummy:addSubcard(id)
					end
				end
				dummy:deleteLater()
				if dummy:subcardsLength() > 0 and room:askForSkillInvoke(player, self:objectName()) then
					player:turnOver()
					room:obtainCard(player, dummy)
					room:addPlayerMark(player, self:objectName())
					player:setAlive(false)
					room:broadcastProperty(player, "alive")
				end
			end
		end
		return false
	end,
}



SevenYueDanback = sgs.CreateTriggerSkill {
	name = "#SevenYueDanback",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getPlayers()) do
				if p:getMark("SevenYueDan") > 0 and p:getHp() > 0 then
					room:setPlayerMark(p, "SevenYueDan", 0)
					p:setAlive(true)
					room:broadcastProperty(p, "alive")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 9
}


XuShaoXuQian_Seven:addSkill(SevenFengPing)
XuShaoXuQian_Seven:addSkill(SevenYueDan)
XuShaoXuQian_Seven:addSkill(SevenYueDanback)
extension_six:insertRelatedSkills("SevenYueDan", "#SevenYueDanback")































----------------------------------------------------------------------------------------------------
--                                            其他
----------------------------------------------------------------------------------------------------

-- 变身
--BUG：SP武将无法发动；--（已修复，但是需要验证）开局时标记会获得2个。
--[[
dofile "lua/config.lua"
local change_table = {}
function initTable()  --变身列表
	table.insert(change_table, {"caocao", "CaoCao_Plus"})					--WEI001 曹操
	table.insert(change_table, {"ass_caocao", "CaoCao_Plus"})
	table.insert(change_table, {"simayi", "SiMaYi_Plus"})					--WEI002 司马懿
	table.insert(change_table, {"guojia", "GuoJia_Plus"})					--WEI003 郭嘉
	table.insert(change_table, {"xiahoudun", "XiaHouDun_Plus"})				--WEI004 夏侯惇
	table.insert(change_table, {"zhangliao", "ZhangLiao_Plus"})				--WEI005 张辽
	table.insert(change_table, {"xuchu", "XuChu_Plus"})						--WEI006 许褚
	table.insert(change_table, {"xiahouyuan", "XiaHouYuan_Plus"})			--WEI008 夏侯渊
	table.insert(change_table, {"caoren", "CaoRen_Plus"})					--WEI009 曹仁
	table.insert(change_table, {"yujin", "YuJin_Plus"})						--WEI010 于禁
	table.insert(change_table, {"yangxiu", "YangXiu_Plus"})					--WEI011 杨修

	table.insert(change_table, {"liubei", "LiuBei_Plus"})					--SHU001 刘备
	table.insert(change_table, {"zhugeliang", "ZhuGeLiang_Plus"})			--SHU002 诸葛亮
	table.insert(change_table, {"heg_zhugeliang", "ZhuGeLiang_Plus"})
	table.insert(change_table, {"guanyu", "GuanYu_Plus"})					--SHU003 关羽
	table.insert(change_table, {"sp_guanyu", "GuanYu_Plus"})
	table.insert(change_table, {"zhangfei", "ZhangFei_Plus"})				--SHU004 张飞
	table.insert(change_table, {"zhaoyun", "ZhaoYun_Plus"})					--SHU005 赵云
	table.insert(change_table, {"machao", "MaChao_Plus"})					--SHU006 马超
	table.insert(change_table, {"sp_machao", "MaChao_Plus"})
	table.insert(change_table, {"huangyueying", "HuangYueYing_Plus"})		--SHU007 黄月英
	table.insert(change_table, {"heg_huangyueying", "HuangYueYing_Plus"})
	table.insert(change_table, {"huangzhong", "HuangZhong_Plus"})			--SHU008 黄忠
	table.insert(change_table, {"weiyan", "WeiYan_Plus"})					--SHU009 魏延
	table.insert(change_table, {"menghuo", "MengHuo_Plus"})					--SHU010 孟获
	table.insert(change_table, {"masu", "MaSu_Plus"})						--SHU011 马谡

	table.insert(change_table, {"sunquan", "SunQuan_Plus"})					--WU001 孙权
	table.insert(change_table, {"zhouyu", "ZhouYu_Plus"})					--WU002 周瑜
	table.insert(change_table, {"heg_zhouyu", "ZhouYu_Plus"})
	table.insert(change_table, {"sp_heg_zhouyu", "ZhouYu_Plus"})
	table.insert(change_table, {"lvmeng", "LvMeng_Plus"})					--WU003 吕蒙
	table.insert(change_table, {"luxun", "LuXun_Plus"})						--WU004 陆逊
	table.insert(change_table, {"ganning", "GanNing_Plus"})					--WU005 甘宁
	table.insert(change_table, {"huanggai", "HuangGai_Plus"})				--WU006 黄盖
	table.insert(change_table, {"daqiao", "DaQiao_Plus"})					--WU007 大乔
	table.insert(change_table, {"sunshangxiang", "SunShangXiang_Plus"})		--WU008 孙尚香
	table.insert(change_table, {"sp_sunshangxiang", "SunShangXiang_Plus"})
	table.insert(change_table, {"xiaoqiao", "XiaoQiao_Plus"})				--WU009 小乔
	table.insert(change_table, {"heg_xiaoqiao", "XiaoQiao_Plus"})
	table.insert(change_table, {"zhoutai", "ZhouTai_Plus"})					--WU010 周泰
	table.insert(change_table, {"sunjian", "SunJian_Plus"})					--WU011 孙坚

	table.insert(change_table, {"lvbu", "LvBu_Plus"})						--QUN001 吕布
	table.insert(change_table, {"heg_lvbu", "LvBu_Plus"})
	table.insert(change_table, {"huatuo", "HuaTuo_Plus"})					--QUN003 华佗
	table.insert(change_table, {"zhangjiao", "ZhangJiao_Plus"})				--QUN004 张角
	table.insert(change_table, {"yuji", "YuJi_Plus"})						--QUN005 于吉
	table.insert(change_table, {"gongsunzan", "GongSunZan_Plus"})			--QUN006 公孙瓒
	table.insert(change_table, {"huaxiong", "HuaXiong_Plus"})				--QUN007 华雄
	table.insert(change_table, {"hanxiandi", "LiuXie_Plus"})				--QUN008 刘协
end
ChangeToPlus = sgs.CreateTriggerSkill{
	name = "#ChangeToPlus",
	frequency = sgs.Skill_NotFrequent,
	events ={sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local name = player:getGeneralName()
		local can_list = {}
		for _,group in ipairs(change_table) do
			if group[1] == name then
				table.insert(can_list, group[2])
			end
		end
		if #can_list ~= 0 then
			if room:askForSkillInvoke(player, self:objectName()) then
				local new_general = room:askForChoice(player, self:objectName(), table.concat(can_list, "+"))
				room:changeHero(player, new_general, true, false, false, true)
			end
		end
	end,
	priority = 6
}
function initChange()
	local generalnames=sgs.Sanguosha:getLimitedGeneralNames()
	for _, generalname in ipairs(generalnames) do
		local general = sgs.Sanguosha:getGeneral(generalname)
		if general then
			general:addSkill("#ChangeToPlus")			
		end
	end
end
local skill = sgs.Sanguosha:getSkill("#ChangeToPlus")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(ChangeToPlus)
	sgs.Sanguosha:addSkills(skillList)
end
initTable()
initChange()]]

return { extension, extension_six }
