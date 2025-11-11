module("extensions.biaofengold", package.seeall)
extension = sgs.Package("biaofengold")

--require("bit")

sgs.LoadTranslationTable {
	["biaofengold"] = "标风重铸怀旧包",

	--------------------------------------------5.0武将-------------------------------------------------
	-----------------------------------------------魏---------------------------------------------------

	-----------------------------------------------蜀---------------------------------------------------

	-----------------------------------------------吴---------------------------------------------------

	["ZhouYu_Five"] = "5.0旧周瑜",
	["&ZhouYu_Five"] = "旧周瑜",
	["#ZhouYu_Five"] = "大都督",
	["designer:ZhouYu_Five"] = "锦衣祭司",
	["cv:ZhouYu_Five"] = "暂无",
	["illustrator:ZhouYu_Five"] = "略  模板设计:赛宁",

	["FiveFanjian"] = "反间",
	[":FiveFanjian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张红桃手牌交给一名其他角色，令该角色与你指定的另一名有手牌的角色拼点，视为拼点赢的角色对没赢的角色使用一张【杀】。",
	["FiveFanjian_Card"] = "反间",
	["fivefanjian_"] = "反间",

	["FiveYingzhan"] = "迎战",
	[":FiveYingzhan"] = "觉醒技，回合结束阶段开始时，若你此回合内曾造成火焰伤害（以你为伤害来源），你须减1点体力上限，并获得技能“反间”（<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张红桃手牌交给一名其他角色，令该角色与你指定的另一名有手牌的角色拼点，视为拼点赢的角色对没赢的角色使用一张【杀】）。",
	["#FiveYingzhan"] = "%from 在本回合内造成了火焰伤害，触发“%arg”",
	["$FiveYingzhan"] = "技能 迎战 的觉醒台词（求建议）",

	-----------------------------------------------群---------------------------------------------------

	["ZhangJiaoA_Five"] = "5.0旧张角2",
	["&ZhangJiaoA_Five"] = "旧张角",
	["#ZhangJiaoA_Five"] = "天公将军",
	["designer:ZhangJiaoA_Five"] = "战地129",
	["cv:ZhangJiaoA_Five"] = "暂无",
	["illustrator:ZhangJiaoA_Five"] = "略  模板设计:赛宁",

	["FiveGuidaoA"] = "鬼道",
	[":FiveGuidaoA"] = "你的回合外，当你失去牌时，你可以摸一张牌并将此牌置于你的武将牌上，称为“道”，你以此法失去的牌不能发动“鬼道”，且你的武将牌上最多可以有五张“道”；出牌阶段，你可以将三张“道”置入弃牌堆，对一名角色造成2点雷电伤害。",
	["FiveGuidaoA_Card"] = "鬼道",
	["fiveguidaoa_"] = "鬼道",
	["dao"] = "道",

	["FiveHuangtianA"] = "黄天",
	[":FiveHuangtianA"] = "主公技，<font color=\"green\"><b>其他群势力角色的出牌阶段限一次，</b></font> 其可以交给你一张红色手牌。",
	["FiveHuangtianA_Card"] = "黄天送牌",
	["fivehuangtiana_"] = "黄天送牌",
	["FiveHuangtianA_Qun"] = "黄天送牌",
	[":FiveHuangtianA_Qun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以交给张角一张红色手牌。",
	----------------------------------------------------------------------------------------------------
	["ZhangJiaoB_Five"] = "5.0旧张角3",
	["&ZhangJiaoB_Five"] = "旧张角",
	["#ZhangJiaoB_Five"] = "天公将军",
	["designer:ZhangJiaoB_Five"] = "与他一勃",
	["cv:ZhangJiaoB_Five"] = "暂无",
	["illustrator:ZhangJiaoB_Five"] = "略  模板设计:赛宁",

	["FiveGuidaoB"] = "鬼道",
	[":FiveGuidaoB"] = "其他角色的回合开始阶段开始时，你可以令该角色横置或重置其武将牌，然后该角色可以弃置你的一张手牌。",
	["FiveGuidaoB_Chain"] = "横置",
	["FiveGuidaoB_Reset"] = "重置",
	["#FiveGuidaoB"] = "%from %arg 了 %to 的武将牌",

	["FiveLeiji"] = "雷击",
	[":FiveLeiji"] = "你的回合外，当你失去牌时，你可以令一名角色摸一张牌，然后你对其造成1点雷电伤害。",
	["@FiveLeiji"] = "你可以发动【雷击】",
	["~FiveLeiji"] = "选择一名角色→点击确定",
	["FiveLeiji_Card"] = "雷击",
	["fiveleiji_"] = "雷击",

	["FiveHuangtianB"] = "黄天",
	[":FiveHuangtianB"] = "主公技，其他群雄角色的回合结束阶段开始时，若其处于连环状态，该角色可以令你摸一张牌。",



	--------------------------------------------4.0武将-------------------------------------------------
	-----------------------------------------------魏---------------------------------------------------

	["CaoCao_Four"] = "4.0曹操",
	["&CaoCao_Four"] = "旧曹操",
	["#CaoCao_Four"] = "超世之英杰",
	["designer:CaoCao_Four"] = "锦衣祭司",
	["cv:CaoCao_Four"] = "暂无",
	["illustrator:CaoCao_Four"] = "略  模板设计:赛宁",

	["FourJianxiong"] = "奸雄",
	[":FourJianxiong"] = "每当你受到一次伤害后，你可以选择一项：1.获得对你造成伤害的牌。2.弃置一张牌（无牌则不弃），然后摸X张牌（X为你已损失的体力值）。你即将造成伤害时，可以弃置一张黑桃手牌并指定一名其他角色，然后视为由该角色造成此伤害。",
	["FourJianxiong_choice1"] = "获得对你造成伤害的牌",
	["FourJianxiong_choice2"] = "弃置一张牌，然后摸X张牌（X为你已损失的体力值）",
	["FourJianxiong_cancel"] = "不发动",
	["#FourJianxiong1"] = "%from 发动了技能“%arg①”",
	["#FourJianxiong2"] = "%from 发动了技能“%arg②”",
	["FourJianxiong_Card"] = "奸雄",
	["fourjianxiong_"] = "奸雄",
	["@FourJianxiong"] = "你可以弃置一张黑桃手牌发动【奸雄】",
	["~FourJianxiong"] = "选择一张黑桃手牌→选择一名其他角色→点击确定",
	["#FourJianxiong_msg"] = "%from 指定了 %to 造成此伤害",

	["FourJiaozhao"] = "矫诏",
	[":FourJiaozhao"] = "限定技，出牌阶段，若你不是主公，且主公身份角色拥有主公技，你可以交给该角色一张【桃】，然后获得其一项主公技。",
	["@jiaozhao"] = "矫诏",
	["fourjiaozhao_"] = "矫诏",
	["FourJiaozhao_Card"] = "矫诏",
	["$FourJiaozhao"] = "技能 矫诏 的技能台词（求建议）",
	----------------------------------------------------------------------------------------------------
	["XiaHouDun_Four"] = "4.0夏侯惇",
	["&XiaHouDun_Four"] = "旧夏侯惇",
	["#XiaHouDun_Four"] = "独眼的罗刹",
	["designer:XiaHouDun_Four"] = "小A",
	["cv:XiaHouDun_Four"] = "暂无",
	["illustrator:XiaHouDun_Four"] = "略  模板设计:赛宁",

	["FourFenyong"] = "愤勇",
	[":FourFenyong"] = "锁定技，每当你受到一次伤害后，你须将你的武将牌翻至背面朝上。当你的武将牌背面朝上时，防止你受到的所有伤害。",
	["#FourFenyongAvoid"] = "%from 的“%arg”被触发，防止了本次伤害",

	["FourXuehen"] = "雪恨",
	[":FourXuehen"] = "其他角色的回合结束阶段开始时，若你的武将牌背面朝上，你可以将其翻面并摸一张牌，视为对当前回合角色使用一张【杀】。",
	----------------------------------------------------------------------------------------------------
	["XuHuang_Four"] = "4.0徐晃",
	["&XuHuang_Four"] = "旧徐晃",
	["#XuHuang_Four"] = "周亚夫之风",
	["designer:XuHuang_Four"] = "锦衣祭司",
	["cv:XuHuang_Four"] = "暂无",
	["illustrator:XuHuang_Four"] = "Tuu.  模板设计:赛宁",

	["FourDuanliang"] = "断粮",
	[":FourDuanliang"] = "出牌阶段，你可以将一张黑色牌当【兵粮寸断】使用，此牌必须为基本牌或装备牌；你可以对距离2以内的一名其他角色使用【兵粮寸断】；在与你距离2以内的一名其他角色的【兵粮寸断】判定牌生效后，若此牌不为梅花，你可以摸一张牌然后弃一张牌。",
	["#FourDuanliang_Get"] = "断粮",

	-----------------------------------------------蜀---------------------------------------------------

	["GuanYu_Four"] = "4.0关羽",
	["&GuanYu_Four"] = "旧关羽",
	["#GuanYu_Four"] = "忠义双全",
	["designer:GuanYu_Four"] = "锦衣祭司",
	["cv:GuanYu_Four"] = "暂无",
	["illustrator:GuanYu_Four"] = "略  模板设计:赛宁",

	["FourWusheng"] = "武圣",
	[":FourWusheng"] = "你可以将一张红色牌当【杀】使用或打出，将一张黑色牌当【酒】使用。",
	["FourYijue"] = "义绝",
	[":FourYijue"] = "锁定技，每当其他角色令你回复1点体力时，该角色回复1点体力；你的回合外，每当你获得两张或更多的牌时，你须弃置当前回合角色攻击范围内一名角色区域内的一张牌。",
	["#FourYijue_Recover"] = "%from 触发【%arg2】，令其恢复 %arg 点体力的角色 %to 回复 %arg 点体力",
	----------------------------------------------------------------------------------------------------
	["WoLongZhuGeLiang_Four"] = "4.0卧龙诸葛亮",
	["&WoLongZhuGeLiang_Four"] = "旧诸葛亮",
	["#WoLongZhuGeLiang_Four"] = "卧龙",
	["designer:WoLongZhuGeLiang_Four"] = "锦衣祭司",
	["cv:WoLongZhuGeLiang_Four"] = "暂无",
	["illustrator:WoLongZhuGeLiang_Four"] = "北  模板设计:赛宁",

	["FourHuoji"] = "火计",
	[":FourHuoji"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示一张红色手牌并指定一名角色，然后视为你对其使用一张【火攻】。",
	["FourHuoji_Card"] = "火计",
	["fourhuoji_"] = "火计",
	----------------------------------------------------------------------------------------------------
	["PangTong_Four"] = "4.0庞统",
	["&PangTong_Four"] = "旧庞统",
	["#PangTong_Four"] = "凤雏",
	["designer:PangTong_Four"] = "玉面",
	["cv:PangTong_Four"] = "暂无",
	["illustrator:PangTong_Four"] = "略  模板设计:赛宁",

	["FourNiepan"] = "涅槃",
	[":FourNiepan"] = "限定技，当你处于濒死状态时，你可以：弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至体力上限。然后你可以对一名处于连环状态的角色造成1点火属性伤害。",
	["@Four_nirvana"] = "涅槃",
	["$FourNiepan"] = "技能 涅槃 的技能台词（求建议）",
	["@FourNiepan"] = "你可以对一名处于连环状态的角色造成1点火属性伤害",
	["~FourNiepan"] = "选择一名角色→点击确定",
	["FourNiepan_Card"] = "涅槃",
	["fourniepan_"] = "涅槃",

	-----------------------------------------------吴---------------------------------------------------

	["ZhouYu_Four"] = "4.0周瑜",
	["&ZhouYu_Four"] = "旧周瑜",
	["#ZhouYu_Four"] = "大都督",
	["designer:ZhouYu_Four"] = "玉面",
	["cv:ZhouYu_Four"] = "暂无",
	["illustrator:ZhouYu_Four"] = "略  模板设计:赛宁",

	["FourYingzi"] = "英姿",
	[":FourYingzi"] = "摸牌阶段摸牌时，你可以额外摸一张牌；弃牌阶段弃牌时，你可以少弃一张牌。",
	["FourYingzi_Prompt"] = "请弃掉 %arg 或 %dest 张手牌",
	["~FourYingzi"] = "",

	["FourFanjian"] = "反间",
	[":FourFanjian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择一张手牌，令一名其他角色选择一种花色后展示并获得之，若此牌与所选花色不同，则该角色流失1点体力。",
	["FourFanjian_Card"] = "反间",
	["fourfanjian_"] = "反间",
	----------------------------------------------------------------------------------------------------
	["GanNing_Four"] = "4.0甘宁",
	["&GanNing_Four"] = "旧甘宁",
	["#GanNing_Four"] = "佩铃的游侠",
	["designer:GanNing_Four"] = "小A",
	["cv:GanNing_Four"] = "暂无",
	["illustrator:GanNing_Four"] = "略  模板设计:赛宁",

	["FourQixi"] = "奇袭",
	[":FourQixi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张黑色牌当【过河拆桥】使用。",
	["FourJinfan"] = "锦帆",
	[":FourJinfan"] = "若你使用【过河拆桥】弃置一名角色装备区里的牌，在该装备牌置入弃牌堆时，你可以用一张红色手牌替换之，<font color=\"green\"><b>每阶段限一次</b></font>",
	["@FourJinfan_prompt"] = "你可以用一张红色手牌替换被弃置的牌",
	----------------------------------------------------------------------------------------------------
	["GanNingA_Four"] = "4.0甘宁1",
	["&GanNingA_Four"] = "旧甘宁",
	["#GanNingA_Four"] = "佩铃的游侠",
	["designer:GanNingA_Four"] = "玉面",
	["cv:GanNingA_Four"] = "暂无",
	["illustrator:GanNingA_Four"] = "略  模板设计:赛宁",

	["FourQixiA"] = "奇袭",
	[":FourQixiA"] = "你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌，然后将一张黑色牌置于你的武将牌上，称为“骑”，你的武将牌上最多可以有四张“骑”；出牌阶段，你可以将一张“骑”当【过河拆桥】使用。",
	["horseA"] = "骑",
	["@FourQixiA_Exchange"] = "请将 %arg 张黑色牌置于武将牌上",
	----------------------------------------------------------------------------------------------------
	["GanNingB_Four"] = "4.0甘宁2",
	["&GanNingB_Four"] = "旧甘宁",
	["#GanNingB_Four"] = "佩铃的游侠",
	["designer:GanNingB_Four"] = "玉面",
	["cv:GanNingB_Four"] = "暂无",
	["illustrator:GanNingB_Four"] = "略  模板设计:赛宁",

	["FourQixiB"] = "奇袭",
	[":FourQixiB"] = "以下两种时机，你可以摸一张牌：\
1、当你失去装备区里的牌时。\
2、回合结束阶段开始时，若你于弃牌阶段内弃置了两张或更多的手牌。\
然后你可以将一张黑色牌置于你的武将牌上（此牌不能为装备牌），称为“骑”，你的武将牌上最多可以有四张“骑”；出牌阶段，你可以将一张“骑”当【过河拆桥】使用。",
	["horseB"] = "骑",
	["@FourQixiB_Exchange"] = "请将 %arg 张黑色牌置于武将牌上（此牌不能为装备牌）",
	----------------------------------------------------------------------------------------------------
	["XiaoQiaoA_Four"] = "4.0小乔1",
	["&XiaoQiaoA_Four"] = "旧小乔",
	["#XiaoQiaoA_Four"] = "矫情之花",
	["designer:XiaoQiaoA_Four"] = "吹风奈奈",
	["cv:XiaoQiaoA_Four"] = "暂无",
	["illustrator:XiaoQiaoA_Four"] = "略  模板设计:赛宁",

	["FourTianxiang"] = "天香",
	[":FourTianxiang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名其他角色并选择一项：1.弃置一张红桃手牌，对其造成1点伤害，然后该角色摸X张牌（X为该角色当前已损失的体力值）。2.交给该角色一张红桃手牌，然后你回复1点体力。",
	["FourTianxiang_Damage"] = "弃置此牌，对其造成1点伤害，然后该角色摸X张牌（X为该角色当前已损失的体力值）",
	["FourTianxiang_Recover"] = "将此牌交给该角色，然后回复1点体力",
	["FourTianxiang_Card"] = "天香",
	["fourtianxiang_"] = "天香",

	-----------------------------------------------群---------------------------------------------------

	["ZhangJiao_Four"] = "4.0张角",
	["&ZhangJiao_Four"] = "旧张角",
	["#ZhangJiao_Four"] = "天公将军",
	["designer:ZhangJiao_Four"] = "玉面",
	["cv:ZhangJiao_Four"] = "暂无",
	["illustrator:ZhangJiao_Four"] = "略  模板设计:赛宁",

	["FourGuidao"] = "鬼道",
	--[":FourGuidao"] = "在一名角色的判定牌生效前，你可以用一张黑色牌替换之。然后你可以在判定牌生效后展示牌堆顶的一张牌，若此牌为黑色则将其置于你的武将牌上，称为“符”，你的武将牌上最多可以有三张“符”；若此牌为红色或你不能这样做，则弃置之。每当其他角色的判定开始前，你可以获得一张“符”。",
	[":FourGuidao"] = "在一名角色的判定牌生效前，你可以用一张黑色牌替换之。然后你可以在判定牌生效后展示牌堆顶的一张牌，将其置于你的武将牌上，称为“符”，你的武将牌上最多可以有三张“符”；若你不能这样做，则弃置之。每当其他角色的判定开始前，你可以获得一张“符”。",
	["symbol"] = "符",
	["~FourGuidao"] = "选择一张黑色牌→点击确定",

	["FourDedao"] = "得道",
	[":FourDedao"] = "觉醒技，回合开始阶段开始时，若“符”的数量达到3，你须减1点体力上限，并获得技能“雷击”。",
	["#FourDedao"] = "%from 的符的数量达到 %arg 个，触发“%arg2”",
	["$FourDedao"] = "技能 得道 的觉醒台词（求建议）",
	----------------------------------------------------------------------------------------------------
	["YuJi_Four"] = "4.0于吉",
	["&YuJi_Four"] = "旧于吉",
	["#YuJi_Four"] = "太平道人",
	["designer:YuJi_Four"] = "锦衣祭司",
	["cv:YuJi_Four"] = "暂无",
	["illustrator:YuJi_Four"] = "略  模板设计:赛宁",

	["FourTaiping"] = "太平",
	[":FourTaiping"] = "<font color=\"green\"><b>其他角色的出牌阶段限一次，</b></font>其可以交给你一张红桃手牌。",
	["FourTaiping_Card"] = "太平送牌",
	["FourTaiping_Others"] = "太平送牌",
	[":FourTaiping_Others"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以交给于吉一张红桃手牌。",



	--------------------------------------------DIY武将-------------------------------------------------
	----------------------------------------------5.0---------------------------------------------------
	["XiaHouBa_Diy"] = "DIY夏侯霸",
	["&XiaHouBa_Diy"] = "夏侯霸",
	["#XiaHouBa_Diy"] = "棘途壮志",
	["designer:XiaHouBa_Diy"] = "一品海之蓝",
	["cv:XiaHouBa_Diy"] = "暂无",
	["illustrator:XiaHouBa_Diy"] = "熊猫探员  模板设计:赛宁",

	["DiyJisu"] = "疾速",
	[":DiyJisu"] = "回合开始阶段开始时，你可以进行两次判定，若其中至少一次判定的结果为黑色，你获得技能“神速”直到回合结束，并将黑色的判定牌置于你的武将牌上，称为“变”；你可以将一张“变”当【酒】使用。",
	["DiyJisu_Card"] = "疾速",
	["turn"] = "变",

	["DiyBaobian"] = "豹变",
	[":DiyBaobian"] = "觉醒技，当你发动“疾速”判定结束后，若“变”的数量达到3或更多，你须减1点体力上限，失去技能“疾速”，将势力改为蜀，并获得技能“挑衅”、“咆哮”和“棘途”（<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张“变”置入弃牌堆，然后观看一名其他角色的手牌）。",
	["#DiyBaobian"] = "%from 的变的数量达到 %arg 个，触发“%arg2”",
	["$DiyBaobian"] = "技能 豹变 的觉醒台词（求建议）",
	["#DiyBaobian_Kingdom"] = "%from 将势力改为 %arg",

	["DiyXX"] = "棘途",
	[":DiyXX"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张“变”置入弃牌堆，然后观看一名其他角色的手牌。",
	["DiyXX_Card"] = "棘途",
	["diyxx_"] = "棘途",

	----------------------------------------------4.0---------------------------------------------------
}

----------------------------------------------------------------------------------------------------

--                                          5.0武将

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--                                             魏
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
--                                             蜀
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
--                                             吴
----------------------------------------------------------------------------------------------------


--[[ WU 002 旧周瑜（5.0旧版）
	武将：ZhouYu_Five
	武将名：旧周瑜
	称号：大都督
	国籍：吴
	体力上限：4
	武将技能：
		英姿：摸牌阶段摸牌时，你可以额外摸一张牌。
		迎战(FiveYingzhan)：觉醒技，回合结束阶段开始时，若你此回合内曾造成火焰伤害（以你为伤害来源），你须减1点体力上限，并获得技能“反间”（出牌阶段，你可以将一张红桃手牌交给一名其他角色，令该角色与你指定的另一名有手牌的角色拼点，视为拼点赢的角色对没赢的角色使用一张【杀】。每阶段限一次）。
		（反间）(FiveFanjian)：出牌阶段，你可以将一张红桃手牌交给一名其他角色，令该角色与你指定的另一名有手牌的角色拼点，视为拼点赢的角色对没赢的角色使用一张【杀】。每阶段限一次。
	技能设计：锦衣祭司
	状态：验证通过
]]
   --

ZhouYu_Five = sgs.General(extension, "ZhouYu_Five", "wu", 4, true)

--[[
	技能：yingzi
	技能名：英姿
	描述：摸牌阶段摸牌时，你可以额外摸一张牌。
	状态：原有技能
]]
   --
ZhouYu_Five:addSkill("yingzi")

--[[
	技能：FiveYingzhan
	附加技能：FiveYingzhan_Count, FiveYingzhan_Clear
	技能名：迎战
	描述：觉醒技，回合结束阶段开始时，若你此回合内曾造成火焰伤害（以你为伤害来源），你须减1点体力上限，并获得技能“反间”（出牌阶段，你可以将一张红桃手牌交给一名其他角色，令该角色与你指定的另一名有手牌的角色拼点，视为拼点赢的角色对没赢的角色使用一张【杀】。每阶段限一次）。
	状态：验证通过
]]
   --
FiveYingzhan_Count = sgs.CreateTriggerSkill {
	name = "#FiveYingzhan_Count",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DamageDone },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		if damage.nature == sgs.DamageStruct_Fire then
			if source and source:isAlive() then
				if source:objectName() == room:getCurrent():objectName() then
					if source:getMark("FiveYingzhan") == 0 and source:hasSkill("FiveYingzhan") then
						room:setPlayerFlag(source, "FiveYingzhan_Damage")
						room:setPlayerMark(source, "&FiveYingzhan", 1)
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
FiveYingzhan = sgs.CreateTriggerSkill {
	name = "FiveYingzhan",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		msg.type = "#FiveYingzhan"
		msg.from = player
		msg.arg = self:objectName()
		room:sendLog(msg)
		room:broadcastInvoke("animate", "lightbox:$FiveYingzhan:3000")
		room:getThread():delay(4000)
		player:addMark("FiveYingzhan")
		if room:changeMaxHpForAwakenSkill(player, -1) then
			room:handleAcquireDetachSkills(player, "FiveFanjian")
		end
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Finish or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		if player:hasFlag("FiveYingzhan_Damage") then
			return true
		end
		return false
	end
}

ZhouYu_Five:addSkill(FiveYingzhan)
ZhouYu_Five:addSkill(FiveYingzhan_Count)
extension:insertRelatedSkills("FiveYingzhan", "#FiveYingzhan_Count")

--[[
	技能：FiveFanjian
	技能名：反间 （默认隐藏）
	描述：出牌阶段，你可以将一张红桃手牌交给一名其他角色，令该角色与你指定的另一名有手牌的角色拼点，视为拼点赢的角色对没赢的角色使用一张【杀】。每阶段限一次。
	状态：验证通过
]]
   --
FiveFanjian_Card = sgs.CreateSkillCard {
	name = "FiveFanjian_Card",
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
		target:obtainCard(effect.card)
		local room = source:getRoom()
		local targets = sgs.SPlayerList()
		local others = room:getOtherPlayers(target)
		for _, p in sgs.qlist(others) do
			if target:canPindian(p) then
				targets:append(p)
			end
		end
		if not target:isKongcheng() then
			if not targets:isEmpty() then
				local dest = room:askForPlayerChosen(source, targets, "FiveFanjian")
				room:setPlayerFlag(dest, "FiveFanjianPindianTarget")
				target:pindian(dest, "FiveFanjian", nil)
				room:setPlayerFlag(dest, "-FiveFanjianPindianTarget")
				local winner
				local loser
				if target:hasFlag("FiveFanjian_Winner") then
					winner = target
					loser = dest
				elseif dest:hasFlag("FiveFanjian_Winner") then
					winner = dest
					loser = target
				end
				if winner:canSlash(loser, nil, false) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:deleteLater()
					slash:setSkillName("FiveFanjian")
					local card_use = sgs.CardUseStruct()
					card_use.from = winner
					card_use.to:append(loser)
					card_use.card = slash
					room:useCard(card_use, false)
				end
			end
		end
	end
}
FiveFanjian_VS = sgs.CreateViewAsSkill {
	name = "FiveFanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FiveFanjian_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#FiveFanjian_Card")
		end
		return false
	end
}
FiveFanjian = sgs.CreateTriggerSkill {
	name = "FiveFanjian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Pindian },
	view_as_skill = FiveFanjian_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local fromNumber = pindian.from_card:getNumber()
			local toNumber = pindian.to_card:getNumber()
			if fromNumber ~= toNumber then
				local winner
				local loser
				if fromNumber > toNumber then
					winner = pindian.from
					loser = pindian.to
				elseif fromNumber < toNumber then
					winner = pindian.to
					loser = pindian.from
				end
				room:setPlayerFlag(winner, "FiveFanjian_Winner")
				room:setPlayerFlag(loser, "FiveFanjian_Loser")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -1
}
local skill = sgs.Sanguosha:getSkill("FiveFanjian")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(FiveFanjian)
	sgs.Sanguosha:addSkills(skillList)
end

ZhouYu_Five:addRelateSkill("FiveFanjian")

----------------------------------------------------------------------------------------------------
--                                             群
----------------------------------------------------------------------------------------------------


--[[ QUN 004 旧张角2（5.0征稿落选，战地129）
	武将：ZhangJiaoA_Five
	武将名：旧张角
	称号：天公将军
	国籍：群
	体力上限：4
	武将技能：
		鬼道(FiveGuidaoA)：你的回合外，当你失去牌时，你可以摸一张牌并将此牌置于你的武将牌上，称为“道”，你以此法失去的牌不能发动“鬼道”，且你的武将牌上最多可以有五张“道”；出牌阶段，你可以将三张“道”置入弃牌堆，对一名角色造成2点雷电伤害。
		黄天(FiveHuangtianA)：主公技，其他群雄角色可以在他们各自的出牌阶段交给你一张红色手牌。每阶段限一次。
	技能设计：战地129
	状态：验证通过
]]
   --

ZhangJiaoA_Five = sgs.General(extension, "ZhangJiaoA_Five$", "qun", 4, true)

--[[
	技能：FiveGuidaoA
	技能名：鬼道
	描述：你的回合外，当你失去牌时，你可以摸一张牌并将此牌置于你的武将牌上，称为“道”，你以此法失去的牌不能发动“鬼道”，且你的武将牌上最多可以有五张“道”；出牌阶段，你可以将三张“道”置入弃牌堆，对一名角色造成2点雷电伤害。
	状态：验证通过
]]
   --
FiveGuidaoA_Card = sgs.CreateSkillCard {
	name = "FiveGuidaoA_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local dao = source:getPile("dao")
		--[[local n = 3
		while n > 0 do
			room:fillAG(dao, source)
			local card_id = room:askForAG(source, dao, false, self:objectName())
			if card_id == -1 then
				break
			end
			room:throwCard(card_id, nil, nil)
			dao:removeOne(card_id)
			n = n - 1
			source:invoke("clearAG")
		end]]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "FiveGuidaoA", "")
		room:throwCard(self, reason, nil)
		local damage = sgs.DamageStruct()
		damage.card = nil
		damage.damage = 2
		damage.from = source
		damage.to = target
		damage.nature = sgs.DamageStruct_Thunder
		room:damage(damage)
	end
}
FiveGuidaoA_VS = sgs.CreateViewAsSkill {
	name = "FiveGuidaoA",
	n = 3,
	expand_pile = "dao",
	view_filter = function(self, selected, to_select)
		return sgs.Self:getPile("dao"):contains(to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local acard = FiveGuidaoA_Card:clone()
			for _, c in ipairs(cards) do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			if #cards == 3 then
				return acard
			end
		end
	end,
	enabled_at_play = function(self, player)
		local daos = player:getPile("dao")
		return daos:length() >= 3
	end
}
FiveGuidaoA = sgs.CreateTriggerSkill {
	name = "FiveGuidaoA",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventLoseSkill },
	view_as_skill = FiveGuidaoA_VS,
	on_trigger = function(self, event, player, data)
		if player:isAlive() then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_NotActive then
					local move = data:toMoveOneTime()
					local source = move.from
					if source and source:objectName() == player:objectName() then
						local places = move.from_places
						local room = player:getRoom()
						if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
							local move_cardid = move.card_ids:first()
							local move_card = sgs.Sanguosha:getCard(move_cardid)
							if not move_card:hasFlag("FiveGuidaoA_Dao") then
								local daos = player:getPile("dao")
								if daos:length() < 5 then
									if player:askForSkillInvoke(self:objectName(), data) then
										local card_id = room:getNCards(1):first()
										local card = sgs.Sanguosha:getCard(card_id)
										room:setCardFlag(card, "FiveGuidaoA_Dao")
										room:obtainCard(player, card_id, false)
										player:addToPile("dao", card_id)
									end
								end
							else
								room:setCardFlag(move_card, "-FiveGuidaoA_Dao")
							end
						end
					end
				end
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				player:removePileByName("dao")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhangJiaoA_Five:addSkill(FiveGuidaoA)

--[[
	技能：FiveHuangtianA
	附加技能：FiveHuangtianA_Qun
	技能名：黄天
	描述：主公技，其他群雄角色可以在他们各自的出牌阶段交给你一张红色手牌。每阶段限一次。
	状态：验证通过
]]
   --
FiveHuangtianA_Card = sgs.CreateSkillCard {
	name = "FiveHuangtianA_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasLordSkill("FiveHuangtianA") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					return not to_select:hasFlag("FiveHuangtianAInvoked")
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("FiveHuangtianA") then
			room:setPlayerFlag(zhangjiao, "FiveHuangtianAInvoked")
			zhangjiao:obtainCard(self)
			local subcards = self:getSubcards()
			for _, card_id in sgs.qlist(subcards) do
				room:setCardFlag(card_id, "visible")
			end
			room:setEmotion(zhangjiao, "good")
			local zhangjiaos = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _, p in sgs.qlist(players) do
				if p:hasLordSkill("FiveHuangtianA") then
					if not p:hasFlag("FiveHuangtianAInvoked") then
						zhangjiaos:append(p)
					end
				end
			end
			if zhangjiaos:length() == 0 then
				room:setPlayerFlag(source, "ForbidFiveHuangtianA")
			end
		end
	end
}
FiveHuangtianA_Qun = sgs.CreateViewAsSkill {
	name = "FiveHuangtianA_Qun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FiveHuangtianA_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "qun" then
			return not player:hasFlag("ForbidFiveHuangtianA")
		end
		return false
	end
}
FiveHuangtianA = sgs.CreateTriggerSkill {
	name = "FiveHuangtianA$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasLordSkill(self:objectName()) then
			local others = room:getOtherPlayers(player)
			for _, p in sgs.qlist(others) do
				if not p:hasSkill("FiveHuangtianA_Qun") then
					room:attachSkillToPlayer(p, "FiveHuangtianA_Qun")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("ForbidFiveHuangtianA") then
					room:setPlayerFlag(player, "-ForbidFiveHuangtianA")
				end
				local players = room:getOtherPlayers(player)
				for _, p in sgs.qlist(players) do
					if p:hasFlag("FiveHuangtianAInvoked") then
						room:setPlayerFlag(p, "-FiveHuangtianAInvoked")
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
ZhangJiaoA_Five:addSkill(FiveHuangtianA)
local skill = sgs.Sanguosha:getSkill("FiveHuangtianA_Qun")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(FiveHuangtianA_Qun)
	sgs.Sanguosha:addSkills(skillList)
end

----------------------------------------------------------------------------------------------------

--[[ QUN 004 旧张角3（5.0征稿落选，与他一勃）
	武将：ZhangJiaoB_Five
	武将名：旧张角
	称号：天公将军
	国籍：群
	体力上限：3
	武将技能：
		鬼道(FiveGuidaoB)：其他角色的回合开始阶段开始时，你可以令该角色横置或重置其武将牌，然后该角色可以弃置你的一张手牌。
		雷击(FiveLeiji)：你的回合外，当你失去牌时，你可以令一名角色摸一张牌，然后你对其造成1点雷电伤害。
		黄天(FiveHuangtianB)：主公技，其他群雄角色的回合结束阶段开始时，若其处于连环状态，该角色可以令你摸一张牌。
	技能设计：与他一勃
	状态：尚未完成
]]
   --

ZhangJiaoB_Five = sgs.General(extension, "ZhangJiaoB_Five$", "qun", 3, true)

--[[
	技能：FiveGuidaoB
	技能名：鬼道
	描述：其他角色的回合开始阶段开始时，你可以令该角色横置或重置其武将牌，然后该角色可以弃置你的一张手牌。
	状态：验证通过
]]
   --
FiveGuidaoB = sgs.CreateTriggerSkill {
	name = "FiveGuidaoB",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local zhangjiaos = room:findPlayersBySkillName(self:objectName())
			for _, zhangjiao in sgs.qlist(zhangjiaos) do
				if zhangjiao and zhangjiao:objectName() ~= player:objectName() then
					if room:askForSkillInvoke(zhangjiao, self:objectName(), data) then
						local choice = room:askForChoice(zhangjiao, self:objectName(),
							"FiveGuidaoB_Chain+FiveGuidaoB_Reset")
						local msg = sgs.LogMessage()
						msg.type = "#FiveGuidaoB"
						msg.from = zhangjiao
						msg.to:append(player)
						msg.arg = choice
						room:sendLog(msg)
						if choice == "FiveGuidaoB_Chain" then
							room:setPlayerProperty(player, "chained", sgs.QVariant(true))
						elseif choice == "FiveGuidaoB_Reset" then
							room:setPlayerProperty(player, "chained", sgs.QVariant(false))
						end
						if player:canDiscard(zhangjiao, "h") then
							local dest = sgs.QVariant()
							dest:setValue(zhangjiao)
							if room:askForSkillInvoke(player, self:objectName(), dest) then
								local disc = room:askForCardChosen(player, zhangjiao, "h", self:objectName())
								room:throwCard(disc, zhangjiao, player)
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
ZhangJiaoB_Five:addSkill(FiveGuidaoB)

--[[
	技能：FiveLeiji
	技能名：雷击
	描述：你的回合外，当你失去牌时，你可以令一名角色摸一张牌，然后你对其造成1点雷电伤害。
	状态：验证通过
]]
   --
FiveLeiji_Card = sgs.CreateSkillCard {
	name = "FiveLeiji_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:drawCards(target, 1, "FiveLeiji")
		local damage = sgs.DamageStruct()
		damage.card = nil
		damage.damage = 1
		damage.from = source
		damage.to = target
		damage.nature = sgs.DamageStruct_Thunder
		room:damage(damage)
	end
}
FiveLeiji_VS = sgs.CreateViewAsSkill {
	name = "FiveLeiji_VS",
	n = 0,
	view_as = function(self, cards)
		return FiveLeiji_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@FiveLeiji"
	end
}
FiveLeiji = sgs.CreateTriggerSkill {
	name = "FiveLeiji",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventLoseSkill },
	view_as_skill = FiveLeiji_VS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local places = move.from_places
				local room = player:getRoom()
				if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
					room:askForUseCard(player, "@FiveLeiji", "@FiveLeiji")
				end
			end
		end
		return false
	end
}
ZhangJiaoB_Five:addSkill(FiveLeiji)

--[[
	技能：FiveHuangtianB
	技能名：黄天
	描述：主公技，其他群雄角色的回合结束阶段开始时，若其处于连环状态，该角色可以令你摸一张牌。
	状态：验证通过
]]
   --
FiveHuangtianB = sgs.CreateTriggerSkill {
	name = "FiveHuangtianB$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:isChained() then
				local targets = room:getOtherPlayers(player)
				local zhangjiaos = sgs.SPlayerList()
				for _, p in sgs.qlist(targets) do
					if p:hasLordSkill(self:objectName()) then
						zhangjiaos:append(p)
					end
				end
				local flag = true
				local target
				while not zhangjiaos:isEmpty() and flag do
					flag = false
					--if room:askForSkillInvoke(player, self:objectName()) then
					target = room:askForPlayerChosen(player, zhangjiaos, self:objectName(), "FiveHuangtianB-invoke", true,
						true)
					if target then
						local msg = sgs.LogMessage()
						msg.type = "#InvokeOthersSkill"
						msg.from = player
						msg.to:append(target)
						msg.arg = self:objectName()
						room:sendLog(msg)
						target:drawCards(1)
						target:setFlags("FiveHuangtianB_Used")
						zhangjiaos:removeOne(target)
						flag = true
					else
						break
					end
					--end
				end
				for _, p in sgs.qlist(zhangjiaos) do
					if p:hasFlag("FiveHuangtianB_Used") then
						p:setFlags("-FiveHuangtianB_Used")
					end
				end
			end
			return false
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:getKingdom() == "qun"
		end
		return false
	end
}
ZhangJiaoB_Five:addSkill(FiveHuangtianB)



----------------------------------------------------------------------------------------------------

--                                          4.0武将

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--                                             魏
----------------------------------------------------------------------------------------------------


--[[ WEI 001 曹操（4.0）
	武将：CaoCao_Four
	武将名：曹操
	称号：超世之英杰
	国籍：魏
	体力上限：4
	武将技能：
		奸雄(FourJianxiong)：每当你受到一次伤害后，你可以选择一项：1.获得对你造成伤害的牌。2.弃置一张牌（无牌则不弃），然后摸X张牌（X为你已损失的体力值）。你即将造成伤害时，可以弃置一张黑桃手牌并指定一名其他角色，然后视为由该角色造成此伤害。
		矫诏(FourJiaozhao)：限定技，出牌阶段，若你不是主公，且主公身份角色拥有主公技，你可以交给该角色一张【桃】，然后获得其一项主公技。
		护驾：主公技，当你需要使用或打出一张【闪】时，你可令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	技能设计：锦衣祭司
	状态：验证通过
]]
   --

CaoCao_Four = sgs.General(extension, "CaoCao_Four$", "wei", 4, true)

--[[
	技能：FourJianxiong
	技能名：奸雄
	描述：每当你受到一次伤害后，你可以选择一项：1.获得对你造成伤害的牌。2.弃置一张牌（无牌则不弃），然后摸X张牌（X为你已损失的体力值）。你即将造成伤害时，可以弃置一张黑桃手牌并指定一名其他角色，然后视为由该角色造成此伤害。
	状态：验证通过
]]
   --
FourJianxiong_Card = sgs.CreateSkillCard {
	name = "FourJianxiong_Card",
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
		msg.type = "#FourJianxiong_msg"
		msg.from = source
		msg.to:append(target)
		room:sendLog(msg)
		room:setPlayerFlag(target, "FourJianxiong_Victim")
	end,
}
FourJianxiong_VS = sgs.CreateViewAsSkill {
	name = "FourJianxiong_VS",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getSuit() == sgs.Card_Spade
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FourJianxiong_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@FourJianxiong"
	end
}
FourJianxiong = sgs.CreateTriggerSkill {
	name = "FourJianxiong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.ConfirmDamage, sgs.Predamage },
	view_as_skill = FourJianxiong_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				local card = damage.card
				local prompt = "FourJianxiong_choice2+FourJianxiong_cancel"
				if card then
					local id = card:getEffectiveId()
					if room:getCardPlace(id) == sgs.Player_PlaceTable then
						prompt = "FourJianxiong_choice1+" .. prompt
					end
				end
				local choice = room:askForChoice(player, self:objectName(), prompt, data)
				local msg = sgs.LogMessage()
				if choice == "FourJianxiong_choice1" then --获得造成伤害的牌
					msg.type = "#FourJianxiong1"
					msg.from = player
					msg.arg = self:objectName()
					room:sendLog(msg)
					player:obtainCard(card)
				elseif choice == "FourJianxiong_choice2" then --弃1张牌然后摸X张牌
					msg.type = "#FourJianxiong2"
					msg.from = player
					msg.arg = self:objectName()
					room:sendLog(msg)
					room:askForDiscard(player, self:objectName(), 1, 1, false, true)
					local lostHp = player:getLostHp()
					room:drawCards(player, lostHp, self:objectName())
				end
			end
		elseif event == sgs.ConfirmDamage then --奸雄目标跳过ConfirmDamage时机
			if player:hasFlag("FourJianxiong_Victim") then
				room:setPlayerFlag(player, "-FourJianxiong_Victim")
				--return true
			end
		elseif event == sgs.Predamage then
			if player:hasSkill(self:objectName()) then
				if not player:isKongcheng() then
					local damage = data:toDamage()
					room:setTag("CurrentDamageStruct", data)
					if room:askForUseCard(player, "@FourJianxiong", "@FourJianxiong") then
						for _, victim in sgs.qlist(room:getAlivePlayers()) do
							if victim:hasFlag("FourJianxiong_Victim") then --防止原伤害，更换伤害来源，然后重新结算新伤害，这样保证发动时机为Predamage
								--room:setPlayerFlag(victim, "-FourJianxiong_Victim")
								damage.from = victim
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
CaoCao_Four:addSkill(FourJianxiong)

--[[
	技能：FourJiaozhao
	附加技能：FourJiaozhao_wakeOtherSkills, FourJiaozhao_wakeRuoyu
	技能名：矫诏
	描述：限定技，出牌阶段，若你不是主公，且主公身份角色拥有主公技，你可以交给该角色一张【桃】，然后获得其一项主公技。
	状态：验证通过
	注：个别时候，发动矫诏会失败（扣标记但是无法给牌）或造成游戏崩溃；
		若主公为玩家添加的其他lua，有主公技且为觉醒技，获得之后觉醒会获得激将。
	（由于此技能过于奇葩，且日神杀对主公技的支持有某些问题，所以测试还不太全面，谢谢大家帮忙找BUG哈~）
]]
   --
FourJiaozhao_Card = sgs.CreateSkillCard {
	name = "FourJiaozhao_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select:getRole() ~= "lord" then
			return false
		end
		local LordSkill = false
		for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
			if skill:isLordSkill() then
				LordSkill = true
			end
		end
		return LordSkill and #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		room:broadcastInvoke("animate", "lightbox:$FourJiaozhao:3000")
		room:getThread():delay(4000)
		source:loseMark("@jiaozhao", 1)
		room:obtainCard(dest, self)
		local LordSkills = {}
		for _, skill in sgs.qlist(dest:getVisibleSkillList()) do
			if skill:isLordSkill() then
				table.insert(LordSkills, skill:objectName())
			end
		end
		local choice = room:askForChoice(source, self:objectName(), table.concat(LordSkills, "+"))
		local skill = sgs.Sanguosha:getSkill(choice)
		room:handleAcquireDetachSkills(source, choice)
		room:setPlayerMark(source, "&FourJiaozhao+" .. choice, 1)
		local jiemingEX = sgs.Sanguosha:getTriggerSkill(choice)
		if choice ~= "songwei" and choice ~= "ruoyu" then
			--jiemingEX:trigger(sgs.GameStart, room, source, sgs.QVariant())
		end
	end,
}
FourJiaozhao_VS = sgs.CreateViewAsSkill {
	name = "FourJiaozhao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Peach")
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = FourJiaozhao_Card:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@jiaozhao") == 0 then
			return false
		end
		return player:getRole() ~= "lord"
	end,
}
FourJiaozhao = sgs.CreateTriggerSkill {
	name = "FourJiaozhao",
	frequency = sgs.Skill_Limited,
	events = { sgs.GameStart },
	view_as_skill = FourJiaozhao_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@jiaozhao", 1)
		room:setTag("FourJiaozhao_wake", sgs.QVariant(0)) --防止在若愚触发前其他觉醒技先触发
		room:setTag("FourJiaozhao_wakeOther", sgs.QVariant(0))
	end,
}
FourJiaozhao_wakeOtherSkills = sgs.CreateTriggerSkill {
	name = "#FourJiaozhao_wakeOtherSkills",
	ferquency = sgs.Skill_Compulsory,
	events = { sgs.EventAcquireSkill, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local marksPre = room:getTag("FourJiaozhao_wake"):toInt() --上次获得/失去技能时的觉醒标记数
		local marksNow = player:getMark("@waked")           --当前觉醒标记数
		if marksNow > marksPre then                         --觉醒标记数增加，包括：获得技能的觉醒技触发，失去技能的觉醒技触发（如武继）；不包括断肠失去技能
			local marksGained = room:getTag("FourJiaozhao_wakeOther"):toInt()
			room:removeTag("FourJiaozhao_wakeOther")
			room:setTag("FourJiaozhao_wakeOther", sgs.QVariant(marksGained + 1)) --正常获得的觉醒标记数（即正常发动的觉醒技数量）+1
			room:removeTag("FourJiaozhao_wake")
			room:setTag("FourJiaozhao_wake", sgs.QVariant(marksNow)) --更新觉醒标记数
		end
	end,
}
FourJiaozhao_wakeRuoyu = sgs.CreateTriggerSkill {
	name = "#FourJiaozhao_wakeRuoyu",
	frequency = sgs.Skill_Frequent, --由于锁定技的priority问题被迫设置为Frequent
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Start then
			--if player:getMark("@duanchang") == 0 then
			local marks = player:getMark("@waked")
			local marksGained = room:getTag("FourJiaozhao_wakeOther"):toInt()

			if marks > marksGained then                                 --如果觉醒技数<当前标记数，说明至少一个觉醒技未获得技能，即若愚
				local marksPre = room:getTag("FourJiaozhao_wake"):toInt()
				if marksPre == marks then                               --防止若愚和其他觉醒技一起触发的情况，此时如果第二个觉醒技后触发，marksPre=marksNow，需要手动处理，否则在acquireSkill处理即可
					room:removeTag("FourJiaozhao_wakeOther")
					room:setTag("FourJiaozhao_wakeOther", sgs.QVariant(marksGained + 1)) --正常获得的觉醒标记数（即正常发动的觉醒技数量）+1
					room:removeTag("FourJiaozhao_wake")
					room:setTag("FourJiaozhao_wake", sgs.QVariant(marksNow)) --更新觉醒标记数
				end
				room:acquireSkill(player, "jijiang")
			end
			--end
		end
	end,
}
--[[
	由于太阳神三国杀中，若愚发动时在获得激将之前会检查当前角色是否为主公，因此曹操获得若愚后发动时，只能增加体力上限等，无法获得激将。
	袁术和倚天包魏武帝的代码解决了这个问题，但是是通过源码实现的，lua显然无法用这样简单的方式实现。
	理论上的解决方法很简单，增加一个隐藏技能，在若愚发动完毕后，获得技能激将。但是很遗憾，太阳神三国杀没有“技能发动完毕”这个触发技触发时机。
	于是只能退一步，通过检查觉醒标记来确定若愚是否发动。但是又遇到了双将的问题……
	然后就出现了以上2个技能：FourJiaozhao_wakeOtherSkills，和FourJiaozhao_wakeRuoyu。
	
	具体流程主要是靠2个标签实现的：
	FourJiaozhao_wake 记录当前觉醒标记的数量，在获得或失去技能时，记录的是这之前的觉醒标记数量。
	FourJiaozhao_wakeOther 记录除获得的若愚之外，正常发动的觉醒技数量，即正常获得的觉醒标记数量。
	原理是这样：觉醒技在获得或失去技能之前，会获得一个觉醒标记，表示这个觉醒技已发动。而发动矫诏获得的若愚，也会获得一个觉醒标记，但是没有获得技能。
	也就是说，我们记录一下当前的觉醒标记数（可以直接从游戏中读取，那个标签的用处下面解释），和正常获得的觉醒标记数，就可以发现是否有觉醒标记非正常获得（若愚）。
	
	FourJiaozhao_wakeOtherSkills 这个技能的作用是，在获得或失去技能时，如果是觉醒技造成的，更新正常的觉醒标记数（FourJiaozhao_wakeOther）。
	由于FourJiaozhao_wake是在此技能发动的结尾更新，因此当技能发动时，这个标签存储的是上次获得或失去技能时的觉醒标记数。和现在的对比一下，就能判断这之间是否发动了觉醒技。
	确定这是觉醒技造成的之后，不管是获得技能还是失去技能（如武继），FourJiaozhao_wakeOther加1。然后维护FourJiaozhao_wake。
	由于此技能发动时必须获得或失去了技能，因此若愚发动后此技能不会触发，FourJiaozhao_wakeOther不会增加。这就表示这个觉醒标记是非正常获得的。
	
	然后FourJiaozhao_wakeRuoyu在回合开始阶段，觉醒技发动后发动。它用来检查当前的觉醒标记和正常获得的标记是否一致。
	如果不一致，说明在这个回合开始阶段发动了若愚。于是可以获得技能激将。
	然后将FourJiaozhao_wakeOther加1，因为这个若愚结算完毕，已经和正常觉醒技的效果相同。因此下次发动觉醒技就会一切正常。
	
	这样的问题在于：当前的官方主公技只有若愚一个是觉醒技，但是如果有其它lua包中有主公技觉醒技（谁这么无聊）或者有了类似的官方武将，我们无法确定获得的技能是否为激将。
	并且，若2个觉醒技在同一回合开始阶段发动，且若愚先发动，则在第二个觉醒技发动之后才会显示获得激将。（目前还未发现这种情况）
	
	PS.所以说觉醒技是一个非常麻烦的东西……代码长度长了一半
]]
CaoCao_Four:addSkill(FourJiaozhao)
CaoCao_Four:addSkill(FourJiaozhao_wakeOtherSkills)
CaoCao_Four:addSkill(FourJiaozhao_wakeRuoyu)
extension:insertRelatedSkills("FourJiaozhao", "#FourJiaozhao_wakeOtherSkills")
extension:insertRelatedSkills("FourJiaozhao", "#FourJiaozhao_wakeRuoyu")
--[[
	技能：hujia
	技能名：护驾
	描述：主公技，当你需要使用或打出一张【闪】时，你可令其他魏势力角色打出一张【闪】（视为由你使用或打出）。
	状态：原有技能
]]
   --
CaoCao_Four:addSkill("hujia")

----------------------------------------------------------------------------------------------------

--[[ WEI 004 夏侯惇（4.0）
	武将：XiaHouDun_Four
	武将名：夏侯惇
	称号：独眼的罗刹
	国籍：魏
	体力上限：4
	武将技能：
		愤勇(FourFenyong)：锁定技，每当你受到一次伤害后，你须将你的武将牌翻至背面朝上。当你的武将牌背面朝上时，防止你受到的所有伤害。
		雪恨(FourXuehen)：其他角色的回合结束阶段开始时，若你的武将牌背面朝上，你可以将其翻面并摸一张牌，视为对当前回合角色使用一张【杀】。
	技能设计：小A
	状态：验证通过
]]
   --

XiaHouDun_Four = sgs.General(extension, "XiaHouDun_Four", "wei", 4, true)

--[[
	技能：FourFenyong
	技能名：愤勇
	描述：锁定技，每当你受到一次伤害后，你须将你的武将牌翻至背面朝上。当你的武将牌背面朝上时，防止你受到的所有伤害。
	状态：验证通过
]]
   --
FourFenyong = sgs.CreateTriggerSkill {
	name = "FourFenyong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:faceUp() then
				local msg = sgs.LogMessage()
				msg.type = "#TriggerSkill"
				msg.from = player
				msg.arg = self:objectName()
				room:sendLog(msg)
				player:turnOver()
			end
		elseif event == sgs.DamageInflicted then
			if not player:faceUp() then
				local msg = sgs.LogMessage()
				msg.type = "#FourFenyongAvoid"
				msg.from = player
				msg.arg = self:objectName()
				room:sendLog(msg)
				return true
			end
		end
		return false
	end,
}
XiaHouDun_Four:addSkill(FourFenyong)

--[[
	技能：FourXuehen
	技能名：雪恨
	描述：其他角色的回合结束阶段开始时，若你的武将牌背面朝上，你可以将其翻面并摸一张牌，视为对当前回合角色使用一张【杀】。
	状态：验证通过
	注：关于未确定细节，等待FAQ中：
		1.空城诸葛的回合结束阶段开始时，是否能发动雪恨：目前暂定为可以，能够翻面并摸牌，但是不能使用杀。
]]
   --
FourXuehen = sgs.CreateTriggerSkill {
	name = "FourXuehen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xiahous = room:findPlayersBySkillName(self:objectName())
		for _, xiahou in sgs.qlist(xiahous) do
			if player:getPhase() == sgs.Player_Finish then
				if not xiahou:faceUp() and xiahou:objectName() ~= player:objectName() then
					if room:askForSkillInvoke(xiahou, self:objectName()) then
						xiahou:turnOver()
						room:drawCards(xiahou, 1, self:objectName())
						if xiahou:canSlash(player, nil, false) then
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:deleteLater()
							slash:setSkillName(self:objectName())
							local card_use = sgs.CardUseStruct()
							card_use.from = xiahou
							card_use.to:append(player)
							card_use.card = slash
							room:useCard(card_use, false)
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
XiaHouDun_Four:addSkill(FourXuehen)

----------------------------------------------------------------------------------------------------

--[[ WEI 010 徐晃（4.0）
	武将：XuHuang_Four
	武将名：徐晃
	称号：周亚夫之风
	国籍：魏
	体力上限：4
	武将技能：
		断粮(FourDuanliang)：出牌阶段，你可以将一张黑色牌当【兵粮寸断】使用，此牌必须为基本牌或装备牌；你可以对距离2以内的一名其他角色使用【兵粮寸断】；在与你距离2以内的一名其他角色的【兵粮寸断】判定牌生效后，若此牌不为梅花，你可以摸一张牌然后弃一张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
   --

--XuHuang_Four = sgs.General(extension, "XuHuang_Four", "wei", 4, true)

--[[
	技能：FourDuanliang
	附加技能：FourDuanliang_TargetMod, FourDuanliang_Get
	技能名：断粮
	描述：出牌阶段，你可以将一张黑色牌当【兵粮寸断】使用，此牌必须为基本牌或装备牌；你可以对距离2以内的一名其他角色使用【兵粮寸断】；在与你距离2以内的一名其他角色的【兵粮寸断】判定牌生效后，若此牌不为梅花，你可以摸一张牌然后弃一张牌。
	状态：验证通过
]]
   --
--[[FourDuanliang = sgs.CreateViewAsSkill{
	name = "FourDuanliang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isBlack() then
			if not to_select:isKindOf("TrickCard") then
				return true
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local shortage = sgs.Sanguosha:cloneCard("supply_shortage", suit, point)
			shortage:setSkillName(self:objectName())
			shortage:addSubcard(card)
			return shortage
		end
	end
}
FourDuanliang_TargetMod = sgs.CreateTargetModSkill{
	name = "#FourDuanliang_TargetMod",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}
FourDuanliang_Get = sgs.CreateTriggerSkill{
	name = "#FourDuanliang_Get",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xuhuang = room:findPlayerBySkillName(self:objectName())
		if xuhuang and xuhuang:objectName() ~= player:objectName() then
			if xuhuang:distanceTo(player) <= 2 then
				local judge = data:toJudge()
				local card = judge.card
				if judge.reason == "supply_shortage" and card:getSuit() ~= sgs.Card_Club then
					if room:askForSkillInvoke(xuhuang, self:objectName(), data) then
						room:drawCards(xuhuang, 1, self:objectName())
						room:askForDiscard(xuhuang, self:objectName(), 1, 1, false, true)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
XuHuang_Four:addSkill(FourDuanliang)
XuHuang_Four:addSkill(FourDuanliang_TargetMod)
XuHuang_Four:addSkill(FourDuanliang_Get)
]]

----------------------------------------------------------------------------------------------------
--                                             蜀
----------------------------------------------------------------------------------------------------


--[[ SHU 003 关羽（4.0）
	武将：GuanYu_Four
	武将名：关羽
	称号：忠义双全
	国籍：蜀
	体力上限：4
	武将技能：
		武圣(FourWusheng)：你可以将一张红色牌当【杀】使用或打出，将一张黑色牌当【酒】使用。
		义绝(FourYijue)：锁定技，每当其他角色令你回复1点体力时，该角色回复1点体力；你的回合外，每当你获得两张或更多的牌时，你须弃置当前回合角色攻击范围内一名角色区域内的一张牌。
	技能设计：锦衣祭司
	状态：验证通过
]]
   --

GuanYu_Four = sgs.General(extension, "GuanYu_Four", "shu", 4, true)

--[[
	技能：FourWusheng
	技能名：武圣
	描述：你可以将一张红色牌当【杀】使用或打出，将一张黑色牌当【酒】使用。
	状态：验证通过
]]
   --
sgs.FourWusheng_State = { "" }
FourWusheng = sgs.CreateViewAsSkill {
	name = "FourWusheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		local state = sgs.FourWusheng_State[1]
		if state == "use" then
			if to_select:isRed() then
				if sgs.Slash_IsAvailable(sgs.Self) then
					if to_select:objectName() == "Crossbow" and to_select:isEquipped() then
						return sgs.Self:canSlashWithoutCrossbow()
					end
					return true
				end
			elseif to_select:isBlack() then
				return not sgs.Self:hasUsed("Analeptic")
			end
			return false
		else
			if state == "slash" and to_select:isRed() then
				return true
			elseif string.find(state, "analeptic") and to_select:isBlack() then
				return true
			end
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			if card:isRed() then
				local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
				slash:addSubcard(card:getId())
				slash:setSkillName(self:objectName())
				return slash
			else
				local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
				analeptic:addSubcard(card:getId())
				analeptic:setSkillName(self:objectName())
				return analeptic
			end
		end
	end,
	enabled_at_play = function(self, player)
		sgs.FourWusheng_State = { "use" }
		return sgs.Slash_IsAvailable(player) or not player:hasUsed("Analeptic")
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" or string.find(pattern, "analeptic") then
			sgs.FourWusheng_State = { pattern }
			return true
		end
		return false
	end,
}
GuanYu_Four:addSkill(FourWusheng)

--[[
	技能：FourYijue
	技能名：义绝
	描述：锁定技，每当其他角色令你回复1点体力时，该角色回复1点体力；你的回合外，每当你获得两张或更多的牌时，你须弃置当前回合角色攻击范围内一名角色区域内的一张牌。
	状态：验证通过
	注：小型场景模式下，关羽开局摸牌时会要求弃牌。
]]
   --
FourYijue = sgs.CreateTriggerSkill {
	name = "FourYijue",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpRecover, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			local recover = data:toRecover()
			local source = recover.who
			local count = recover.recover
			if source then
				if source:objectName() ~= player:objectName() then
					local msg = sgs.LogMessage()
					msg.type = "#FourYijue_Recover"
					msg.from = player
					msg.to:append(source)
					msg.arg = count
					msg.arg2 = self:objectName()
					room:sendLog(msg)
					local new_recover = sgs.RecoverStruct()
					new_recover.recover = count
					new_recover.who = player
					room:recover(source, new_recover)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_NotActive then
				local move = data:toMoveOneTime()
				local dest = move.to
				if dest then
					if dest:objectName() == player:objectName() then
						local cards = move.card_ids
						local count = cards:length()
						if count > 1 then
							local current = room:getCurrent()
							if current then
								local targets = sgs.SPlayerList()
								for _, p in sgs.qlist(room:getAllPlayers()) do
									if current:inMyAttackRange(p) then
										if not p:isAllNude() then
											targets:append(p)
										end
									end
								end
								if not targets:isEmpty() then
									local msg = sgs.LogMessage()
									msg.type = "#TriggerSkill"
									msg.from = player
									msg.arg = self:objectName()
									room:sendLog(msg)
									local to_dismantle = room:askForPlayerChosen(player, targets, self:objectName())
									local card_id = room:askForCardChosen(player, to_dismantle, "hej", self:objectName())
									local to_throw = sgs.Sanguosha:getCard(card_id)
									room:throwCard(to_throw, to_dismantle, player)
								end
							end
						end
					end
				end
			end
		end
	end
}
GuanYu_Four:addSkill(FourYijue)

----------------------------------------------------------------------------------------------------

--[[ SHU 010 卧龙诸葛亮（4.0）
	武将：WoLongZhuGeLiang_Four
	武将名：卧龙诸葛亮
	称号：卧龙
	国籍：蜀
	体力上限：3
	武将技能：
		看破：你可以将一张黑色手牌当【无懈可击】使用。
		火计(FourHuoji)：出牌阶段，你可以展示一张红色手牌并指定一名角色，然后视为你对其使用一张【火攻】。每阶段限一次。
		八阵：锁定技，若你的装备区没有防具牌，视为你装备着【八卦阵】。
	技能设计：锦衣祭司
	状态：验证通过
]]
   --

WoLongZhuGeLiang_Four = sgs.General(extension, "WoLongZhuGeLiang_Four", "shu", 3, true)

--[[
	技能：kanpo
	技能名：看破
	描述：你可以将一张黑色手牌当【无懈可击】使用。
	状态：原有技能
]]
   --
WoLongZhuGeLiang_Four:addSkill("kanpo")

--[[
	技能：FourHuoji
	技能名：火计
	描述：出牌阶段，你可以展示一张红色手牌并指定一名角色，然后视为你对其使用一张【火攻】。每阶段限一次。
	状态：验证通过
]]
   --
FourHuoji_Card = sgs.CreateSkillCard {
	name = "FourHuoji_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				local fire_attack = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
				fire_attack:deleteLater()
				return not sgs.Self:isProhibited(to_select, fire_attack)
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = target:getRoom()
		local card_id = effect.card:getEffectiveId()
		room:showCard(source, card_id)
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
		fireattack:deleteLater()
		fireattack:setSkillName("FourHuoji")
		local use = sgs.CardUseStruct()
		use.card = fireattack
		use.from = source
		use.to:append(target)
		room:useCard(use)
	end
}
FourHuoji = sgs.CreateViewAsSkill {
	name = "FourHuoji",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isRed() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FourHuoji_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#FourHuoji_Card")
	end
}
WoLongZhuGeLiang_Four:addSkill(FourHuoji)

--[[
	技能：bazhen
	技能名：八阵
	描述：锁定技，若你的装备区没有防具牌，视为你装备着【八卦阵】。
	状态：原有技能
]]
   --
WoLongZhuGeLiang_Four:addSkill("bazhen")

----------------------------------------------------------------------------------------------------

--[[ SHU 011 庞统（4.0）
	武将：PangTong_Four
	武将名：庞统
	称号：凤雏
	国籍：蜀
	体力上限：3
	武将技能：
		连环: 你可以将一张梅花手牌当【铁索连环】使用或重铸。
		涅槃(FourNiepan): 限定技，当你处于濒死状态时，你可以：弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至体力上限。然后你可以对一名处于连环状态的角色造成1点火属性伤害。
	技能设计：玉面
	状态：验证通过
]]
   --

PangTong_Four = sgs.General(extension, "PangTong_Four", "shu", 3, true)

--[[
	技能：lianhuan
	技能名：连环
	描述：你可以将一张梅花手牌当【铁索连环】使用或重铸。
	状态：原有技能
]]
   --
PangTong_Four:addSkill("lianhuan")

--[[
	技能：FourNiepan
	技能名：涅槃
	描述：限定技，当你处于濒死状态时，你可以：弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至体力上限。然后你可以对一名处于连环状态的角色造成1点火属性伤害。
	状态：验证通过
]]
   --
FourNiepan_Card = sgs.CreateSkillCard {
	name = "FourNiepan_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:isChained()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = target:getRoom()
		local damage = sgs.DamageStruct()
		damage.card = nil
		damage.damage = 1
		damage.from = source
		damage.to = target
		damage.nature = sgs.DamageStruct_Fire
		room:damage(damage)
	end
}
FourNiepan_VS = sgs.CreateViewAsSkill {
	name = "FourNiepan_VS",
	n = 0,
	view_as = function(self, cards)
		return FourNiepan_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@FourNiepan"
	end
}
FourNiepan = sgs.CreateTriggerSkill {
	name = "FourNiepan",
	frequency = sgs.Skill_Limited,
	events = { sgs.AskForPeaches },
	view_as_skill = FourNiepan_VS,
	limit_mark = "@Four_nirvana",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastInvoke("animate", "lightbox:$FourNiepan:3000")
				room:getThread():delay(4000)
				player:loseMark("@Four_nirvana")
				player:throwAllCards()
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
				player:drawCards(3)
				local maxhp = player:getMaxHp()
				room:setPlayerProperty(player, "hp", sgs.QVariant(maxhp))
				room:askForUseCard(player, "@FourNiepan", "@FourNiepan")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@Four_nirvana") > 0
				end
			end
		end
		return false
	end
}

PangTong_Four:addSkill(FourNiepan)



----------------------------------------------------------------------------------------------------
--                                             吴
----------------------------------------------------------------------------------------------------


--[[ WU 002 周瑜（4.0）
	武将：ZhouYu_Four
	武将名：周瑜
	称号：大都督
	国籍：吴
	体力上限：3
	武将技能：
		英姿(FourYingzi)：摸牌阶段摸牌时，你可以额外摸一张牌；弃牌阶段弃牌时，你可以少弃一张牌。
		反间(FourFanjian)：出牌阶段，你可以选择一张手牌，令一名其他角色选择一种花色后展示并获得之，若此牌与所选花色不同，则该角色流失1点体力。每阶段限一次。
	技能设计：玉面
	状态：验证通过
]]
   --

ZhouYu_Four = sgs.General(extension, "ZhouYu_Four", "wu", 3, true)

--[[
	技能：FourYingzi
	附加技能：FourYingzi_Keep
	技能名：英姿
	描述：摸牌阶段摸牌时，你可以额外摸一张牌；弃牌阶段弃牌时，你可以少弃一张牌。
	状态：验证通过
	注：关于未确定细节，等待FAQ中：
		1.弃牌时，手牌中被鸡肋的牌数为正常手牌上限+1时是否展示：目前暂定为弃置至手牌上限+1，然后不展示。（这样成了锁定技了……）
	注：个别时候英姿按钮会弹起，下次摸牌阶段时会询问是否发动英姿而不是自动发动；
		周瑜/神周瑜双将，弃置2张牌后琴音失去体力，然后如果手牌数为体力值+1，不能弃1张牌。（再次成为锁定技，不过估计没人这样）
]]
   --
--[[
FourYingzi_DummyCard = sgs.CreateSkillCard{
	name = "FourYingzi_DummyCard",
}
FourYingzi_VS = sgs.CreateViewAsSkill{
	name = "FourYingzi_VS",
	n = 999,
	view_filter = function(self, selected, to_select)
		local player = sgs.Self
		local total = player:getMark("FourYingzi")
		return #selected < total and not sgs.Self:isJilei(to_select) and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local player = sgs.Self
		local total = player:getMark("FourYingzi")
		if #cards >= total - 1 or #cards >= 1 then  --多次弃牌
			local card = FourYingzi_DummyCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@FourYingzi"
	end,
}
FourYingzi = sgs.CreateTriggerSkill{
	name = "FourYingzi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards, sgs.EventPhaseStart, sgs.EventPhaseEnd},
	view_as_skill = FourYingzi_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = data:toInt() + 1
				data:setValue(count)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then  --在真正的弃牌时机前加一个技能弃牌，然后修改手牌上限，跳过真正的弃牌
			local total = player:getHandcardNum() - player:getMaxCards()
			local need = false
			if total >= 1 then
				need = true
			end
			while need do  --处理多次弃牌的情况，新神杀可以多次弃牌；顺便处理神周瑜
				local jilei_cards = {}
				local handcards = player:getHandcards()
				for _,card in sgs.qlist(handcards) do
					if player:isJilei(card) then
						table.insert(jilei_cards, card)
					end
				end
				if player:hasFlag("jilei") and #jilei_cards > player:getMaxCards() then
					local dummy_card = FourYingzi_DummyCard:clone()
					for _,card in pairs(jilei_cards) do
						if handcards:contains(card) then
							handcards:removeOne(card)
						end
					end
					local count = 0
					for _,card in sgs.qlist(handcards) do
						dummy_card:addSubcard(card)
						count = count + 1
					end
					if count > 0 then
						room:throwCard(dummy_card, player)
					end
				else
					local prompt = string.format("FourYingzi_Prompt::%d:%d", total, total - 1)  --%src,%dest,%arg
					--if total ~= 1 then
					--	room:askForDiscard(player, self:objectName(), total, total-1, false, false, prompt)  --此处prompt无法显示
					--else
						room:setPlayerMark(player, "FourYingzi", total)
						if total ~= 1 then
							room:askForCard(player, "@FourYingzi", prompt, data, sgs.Card_MethodDiscard)
						else
							local card = room:askForCard(player, "@FourYingzi", prompt, data, sgs.Card_MethodNone)
							if card:subcardsLength() > 0 then
								room:throwCard(card, player)
							end
						end
					--end
				end
				total = player:getHandcardNum() - player:getMaxCards()
				need = total > 1
			end
			room:setPlayerFlag(player, "FourYingzi")
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			room:setPlayerFlag(player, "-FourYingzi")
		end
	end
}
FourYingzi_Keep = sgs.CreateMaxCardsSkill{
	name = "#FourYingzi_Keep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			if target:hasFlag("FourYingzi") then
				return 1
			end
		end
	end
}
ZhouYu_Four:addSkill(FourYingzi)
ZhouYu_Four:addSkill(FourYingzi_Keep)
]]

--[[FourYingzi = sgs.CreateTriggerSkill {
	name = "FourYingzi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				draw.num = draw.num + 1
				data:setValue(draw)
			end
		else
			local n = room:getTag("DiscardNum"):toInt()

			if event == sgs.AskForGameruleDiscard then
				--room:setPlayerCardLimitation(player, "discard", "Slash|.|.|hand", true)
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				if room:askForSkillInvoke(player, self:objectName(), data) then
					n = n - 1
				end
			else
				--room:removePlayerCardLimitation(player, "discard", "Slash|.|.|hand$1")
			end
			room:setTag("DiscardNum", sgs.QVariant(n))
		end
		return false
	end,
}]]
FourYingzi = sgs.CreateTriggerSkill {
	name = "FourYingzi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				draw.num = draw.num + 1
				data:setValue(draw)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Discard then return false end
			room:addMaxCards(player, 1, true)
		end
		return false
	end,
}
ZhouYu_Four:addSkill(FourYingzi)


--[[
	技能：FourFanjian
	技能名：反间
	描述：出牌阶段，你可以选择一张手牌，令一名其他角色选择一种花色后展示并获得之，若此牌与所选花色不同，则该角色流失1点体力。每阶段限一次。
	状态：验证通过
]]
   --
FourFanjian_Card = sgs.CreateSkillCard {
	name = "FourFanjian_Card",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "FourFanjian")
		local msg = sgs.LogMessage()
		msg.type = "#ChooseSuit"
		msg.from = target
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
		target:obtainCard(self)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			room:loseHp(target)
		end
	end
}
FourFanjian = sgs.CreateViewAsSkill {
	name = "FourFanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FourFanjian_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#FourFanjian_Card")
		end
		return false
	end
}
ZhouYu_Four:addSkill(FourFanjian)

----------------------------------------------------------------------------------------------------

--[[ WU 005 甘宁（4.0第一版）
	武将：GanNing_Four
	武将名：甘宁
	称号：佩铃的游侠
	国籍：吴
	体力上限：4
	武将技能：
		奇袭(FourQixi)：出牌阶段，你可以将一张黑色牌当【过河拆桥】使用。每阶段限一次。
		锦帆(FourJinfan)：若你使用【过河拆桥】弃置一名角色装备区里的牌，在该装备牌置入弃牌堆时，你可以用一张红色手牌替换之。每阶段限一次。
	技能设计：小A
	状态：验证通过
]]
   --

GanNing_Four = sgs.General(extension, "GanNing_Four", "wu", 4, true)

--[[
	技能：FourQixi
	技能名：奇袭
	描述：出牌阶段，你可以将一张黑色牌当【过河拆桥】使用。每阶段限一次。
	状态：验证通过
]]
   --
FourQixi_VS = sgs.CreateViewAsSkill {
	name = "FourQixi",
	n = 1,
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
		return not player:hasFlag("FourQixi_used")
	end
}
FourQixi = sgs.CreateTriggerSkill {
	name = "FourQixi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.EventPhaseChanging },
	view_as_skill = FourQixi_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Dismantlement") and use.card:getSkillName() == self:objectName() then
				room:setPlayerFlag(use.from, "FourQixi_used")
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("FourQixi_used") then
					room:setPlayerFlag(player, "-FourQixi_used")
				end
			end
		end
		return false
	end
}
GanNing_Four:addSkill(FourQixi)

--[[
	技能：FourJinfan
	技能名：锦帆
	描述：若你使用【过河拆桥】弃置一名角色装备区里的牌，在该装备牌置入弃牌堆时，你可以用一张红色手牌替换之。每阶段限一次。
	状态：验证通过
]]
   --
--[[FourJinfan = sgs.CreateTriggerSkill{
	name = "FourJinfan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardsMoveOneTime, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Dismantlement") then
				room:setPlayerFlag(use.from, "FourJinfan")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source then
				if move.to_place == sgs.Player_DiscardPile then
					if move.reason.m_playerId == player:objectName() and player:hasFlag("FourJinfan") then
						local reason = move.reason.m_reason
						if bit:_and(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
							local card_id = move.card_ids:first()
							local card = sgs.Sanguosha:getCard(card_id)
							if move.from_places:first() == sgs.Player_PlaceEquip then
								if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
									local replace = room:askForCard(player, ".red", "@FourJinfan_prompt", data, sgs.Card_MethodNone)
									if replace then
										local move1 = sgs.CardsMoveStruct()
										move1.card_ids:append(replace:getEffectiveId())
										move1.to = player
										move1.to_place = sgs.Player_DiscardPile
										move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RESPONSE, player:objectName())
										local move2 = sgs.CardsMoveStruct()
										move2.card_ids:append(card_id)
										move2.to = player
										move2.to_place = sgs.Player_PlaceHand
										move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE, player:objectName())
										local moves = sgs.CardsMoveList()
										moves:append(move1)
										moves:append(move2)
										room:moveCardsAtomic(moves, true)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			room:setPlayerFlag(player, "-FourJinfan")
		end
		return false
	end
}
]]
listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
FourJinfan = sgs.CreateTriggerSkill {
	name = "FourJinfan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.BeforeCardsMove, sgs.EventPhaseChanging },
	view_as_skill = PlusQixiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Dismantlement") then
				room:setPlayerFlag(use.from, "FourJinfan")
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local source = move.from
			if source then
				if move.to_place == sgs.Player_DiscardPile then
					if move.reason.m_playerId == player:objectName() and player:hasFlag("FourJinfan") and not player:hasFlag("FourJinfan_used") then
						local reason = move.reason.m_reason
						if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
							if event == sgs.BeforeCardsMove then
								if player:hasFlag("FourJinfan") then
									room:setPlayerFlag(player, "-FourJinfan")
									local card_id = move.card_ids:first()
									local card = sgs.Sanguosha:getCard(card_id)
									if card:isKindOf("EquipCard") then
										if move.from_places:contains(sgs.Player_PlaceEquip) then
											local replace = room:askForCard(player, ".red", "@FourJinfan_prompt", data,
												sgs.Card_MethodDiscard)
											if replace then
												room:setPlayerFlag(player, "FourJinfan_used")
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
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("FourJinfan_used") then
					room:setPlayerFlag(player, "-FourJinfan_used")
				end
			end
		end
		return false
	end
}



GanNing_Four:addSkill(FourJinfan)

----------------------------------------------------------------------------------------------------

--[[ WU 005 甘宁1（4.0第二版）
	武将：GanNingA_Four
	武将名：甘宁
	称号：佩铃的游侠
	国籍：吴
	体力上限：4
	武将技能：
		奇袭(FourQixiA)：你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌，然后可以将一张黑色牌置于你的武将牌上，称为“骑”，你的武将牌上最多可以有四张“骑”；出牌阶段，你可以将一张“骑”当【过河拆桥】使用。
	技能设计：玉面
	状态：验证通过
]]
   --

GanNingA_Four = sgs.General(extension, "GanNingA_Four", "wu", 4, true)

--[[
	技能：FourQixiA
	技能名：奇袭
	描述：你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌，然后可以将一张黑色牌置于你的武将牌上，称为“骑”，你的武将牌上最多可以有四张“骑”；出牌阶段，你可以将一张“骑”当【过河拆桥】使用。
	状态：验证通过
]]
   --
--[[
FourQixiA_Card = sgs.CreateSkillCard{
	name = "FourQixiA_Card",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local horse = source:getPile("horse")
		local count = horse:length()
		local id
		if count == 0 then
			return
		elseif count == 1 then
			id = horse:first()
		else
			room:fillAG(horse, source)
			id = room:askForAG(source, horse, false, self:objectName())
			source:invoke("clearAG")
			if id == -1 then
				return
			end
		end
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local dismantlement = sgs.Sanguosha:cloneCard("Dismantlement", suit, point)
		dismantlement:setSkillName("FourQixiA")
		dismantlement:addSubcard(id)
		local list = room:getAlivePlayers()
		local targets = sgs.SPlayerList()
		local emptylist = sgs.PlayerList()
		for _,p in sgs.qlist(list) do
			if dismantlement:targetFilter(emptylist, p, source) then
				if not source:isProhibited(p, dismantlement) then
					targets:append(p)
				end
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(source, targets, self:objectName())
			local use = sgs.CardUseStruct()
			use.card = dismantlement
			use.from = source
			use.to:append(target)
			room:useCard(use)
		end
	end
}
]]
FourQixiA_VS = sgs.CreateOneCardViewAsSkill {
	name = "FourQixiA",
	filter_pattern = ".|.|.|horseA",
	expand_pile = "horseA",
	view_as = function(self, originalCard)
		local Dismantlement = sgs.Sanguosha:cloneCard("Dismantlement", originalCard:getSuit(), originalCard:getNumber())
		Dismantlement:addSubcard(originalCard:getId())
		Dismantlement:setSkillName(self:objectName())
		return Dismantlement
	end,
	enabled_at_play = function(self, player)
		return not player:getPile("horseA"):isEmpty()
	end
}

--[[
FourQixiA_VS = sgs.CreateViewAsSkill{
	name = "FourQixiA",
	n = 0,
	view_as = function(self, cards)
		return FourQixiA_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getPile("horse"):length() > 0
	end
}]]
GetHorseA = function(ganning)
	local room = ganning:getRoom()
	if ganning:getPile("horseA"):length() < 4 then
		if room:askForSkillInvoke(ganning, "FourQixiA") then
			room:drawCards(ganning, 1, "FourQixiA")
			if not ganning:isKongcheng() then
				local card_id = -1
				local prompt = string.format("@FourQixiA_Exchange:::%d", 1)
				local card = room:askForCard(ganning, ".|black", prompt, sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					card_id = card:getEffectiveId()
					ganning:addToPile("horseA", card_id)
				end
			end
			return true
		end
	end
	return false
end
FourQixiA = sgs.CreateTriggerSkill {
	name = "FourQixiA",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	view_as_skill = FourQixiA_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() ~= sgs.Player_NotActive then
				return false
			end
			local move = data:toMoveOneTime()
			local reason = move.reason.m_reason
			local basic = bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if move.from and move.from:objectName() == player:objectName() then
				if basic == sgs.CardMoveReason_S_REASON_DISCARD or basic == sgs.CardMoveReason_S_REASON_RESPONSE or basic == sgs.CardMoveReason_S_REASON_USE then
					local i = 0
					for _, card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:isRed() then
							local places = move.from_places:at(i)
							if places == sgs.Player_PlaceHand or places == sgs.Player_PlaceEquip then
								if not GetHorseA(player) then
									break
								end
							end
						end
						i = i + 1
					end
				end
			end
		end
		return false
	end,
}
GanNingA_Four:addSkill(FourQixiA)

----------------------------------------------------------------------------------------------------

--[[ WU 005 甘宁2（4.0第三版）
	武将：GanNingB_Four
	武将名：甘宁
	称号：佩铃的游侠
	国籍：吴
	体力上限：4
	武将技能：
		奇袭(FourQixiB)：以下两种时机，你可以摸一张牌：
		1、当你失去装备区里的牌时。
		2、回合结束阶段开始时，若你于弃牌阶段内弃置了两张或更多的手牌。
		然后你可以将一张黑色牌置于你的武将牌上（此牌不能为装备牌），称为“骑”，你的武将牌上最多可以有四张“骑”；出牌阶段，你可以将一张“骑”当【过河拆桥】使用。
	技能设计：玉面
	状态：验证通过
]]
   --

GanNingB_Four = sgs.General(extension, "GanNingB_Four", "wu", 4, true)

--[[
	技能：FourQixiB
	技能名：奇袭
	描述：以下两种时机，你可以摸一张牌：
		1、当你失去装备区里的牌时。
		2、回合结束阶段开始时，若你于弃牌阶段内弃置了两张或更多的手牌。
		然后你可以将一张黑色牌置于你的武将牌上（此牌不能为装备牌），称为“骑”，你的武将牌上最多可以有四张“骑”；出牌阶段，你可以将一张“骑”当【过河拆桥】使用。
	状态：验证通过
]]
   --
--[[
FourQixiB_Card = sgs.CreateSkillCard{
	name = "FourQixiB_Card",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local horse = source:getPile("horseB")
		local count = horse:length()
		local id
		if count == 0 then
			return
		elseif count == 1 then
			id = horse:first()
		else
			room:fillAG(horse, source)
			id = room:askForAG(source, horse, false, self:objectName())
			source:invoke("clearAG")
			if id == -1 then
				return
			end
		end
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local dismantlement = sgs.Sanguosha:cloneCard("Dismantlement", suit, point)
		dismantlement:setSkillName("FourQixiB")
		dismantlement:addSubcard(id)
		local list = room:getAlivePlayers()
		local targets = sgs.SPlayerList()
		local emptylist = sgs.PlayerList()
		for _,p in sgs.qlist(list) do
			if dismantlement:targetFilter(emptylist, p, source) then
				if not source:isProhibited(p, dismantlement) then
					targets:append(p)
				end
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(source, targets, self:objectName())
			local use = sgs.CardUseStruct()
			use.card = dismantlement
			use.from = source
			use.to:append(target)
			room:useCard(use)
		end
	end
}
FourQixiB_VS = sgs.CreateViewAsSkill{
	name = "FourQixiB",
	n = 0,
	view_as = function(self, cards)
		return FourQixiB_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getPile("horseB"):length() > 0
	end
}]]

FourQixiB_VS = sgs.CreateOneCardViewAsSkill {
	name = "FourQixiB",
	filter_pattern = ".|.|.|horseB",
	expand_pile = "horseB",
	view_as = function(self, originalCard)
		local Dismantlement = sgs.Sanguosha:cloneCard("Dismantlement", originalCard:getSuit(), originalCard:getNumber())
		Dismantlement:addSubcard(originalCard:getId())
		Dismantlement:setSkillName(self:objectName())
		return Dismantlement
	end,
	enabled_at_play = function(self, player)
		return not player:getPile("horseB"):isEmpty()
	end
}

GetHorseB = function(ganning)
	local room = ganning:getRoom()
	if ganning:getPile("horseB"):length() < 4 then
		if room:askForSkillInvoke(ganning, "FourQixiB") then
			room:drawCards(ganning, 1, "FourQixiB")
			if not ganning:isKongcheng() then
				local card_id = -1
				local prompt = string.format("@FourQixiB_Exchange:::%d", 1)
				local card = room:askForCard(ganning, "BasicCard,TrickCard|.|.|.|black", prompt, sgs.QVariant(),
					sgs.Card_MethodNone)
				if card then
					card_id = card:getEffectiveId()
					ganning:addToPile("horseB", card_id)
				end
			end
			return true
		end
	end
	return false
end
FourQixiB = sgs.CreateTriggerSkill {
	name = "FourQixiB",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	view_as_skill = FourQixiB_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("FourQixiB") >= 2 then
					GetHorseB(player)
				end
				player:setMark("FourQixiB", 0)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local room = player:getRoom()
				local markcount = player:getMark("FourQixiB")
				if move.to_place == sgs.Player_DiscardPile then
					if player:getPhase() == sgs.Player_Discard then
						room:setPlayerMark(player, "FourQixiB", markcount + move.card_ids:length())
					end
				end
				if move.from_places:contains(sgs.Player_PlaceEquip) then
					GetHorseB(player)
				end
			end
		end
	end
}
GanNingB_Four:addSkill(FourQixiB)

----------------------------------------------------------------------------------------------------

--[[ WU 009 小乔1（4.0征稿落选，吹风奈奈）
	武将：XiaoQiaoA_Four
	武将名：小乔
	称号：矫情之花
	国籍：吴
	体力上限：3
	武将技能：
		天香(FourTianxiang)：出牌阶段，你可以指定一名其他角色并选择一项：1.弃置一张红桃手牌，对其造成1点伤害，然后该角色摸X张牌（X为该角色当前已损失的体力值）。2.交给该角色一张红桃手牌，然后你回复1点体力。每阶段限一次。
		红颜：锁定技，你的黑桃牌均视为红桃牌。
	技能设计：吹风奈奈
	状态：验证通过
]]
   --

XiaoQiaoA_Four = sgs.General(extension, "XiaoQiaoA_Four", "wu", 3, false)

--[[
	技能：FourTianxiang
	技能名：天香
	描述：出牌阶段，你可以指定一名其他角色并选择一项：1.弃置一张红桃手牌，对其造成1点伤害，然后该角色摸X张牌（X为该角色当前已损失的体力值）。2.交给该角色一张红桃手牌，然后你回复1点体力。每阶段限一次。
	状态：验证通过
]]
   --
FourTianxiang_Card = sgs.CreateSkillCard {
	name = "FourTianxiang_Card",
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
		local room = source:getRoom()
		local dest = sgs.QVariant()
		dest:setValue(target)
		room:setPlayerFlag(target, "FourTianxiang")
		local choice = room:askForChoice(source, "FourTianxiang", "FourTianxiang_Damage+FourTianxiang_Recover", dest)
		room:setPlayerFlag(target, "-FourTianxiang")
		if choice == "FourTianxiang_Damage" then
			room:throwCard(effect.card, source)
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			room:damage(damage)
			if target:isAlive() then
				local count = target:getLostHp()
				target:drawCards(count)
			end
		elseif choice == "FourTianxiang_Recover" then
			room:obtainCard(target, effect.card)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	end
}
FourTianxiang = sgs.CreateViewAsSkill {
	name = "FourTianxiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:getSuit() == sgs.Card_Heart
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local tianxiangCard = FourTianxiang_Card:clone()
			tianxiangCard:addSubcard(cards[1])
			return tianxiangCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#FourTianxiang_Card")
	end
}
XiaoQiaoA_Four:addSkill(FourTianxiang)

--[[
	技能：hongyan
	技能名：红颜
	描述：锁定技，你的黑桃牌均视为红桃牌。
	状态：原有技能
]]
   --
XiaoQiaoA_Four:addSkill("hongyan")


----------------------------------------------------------------------------------------------------
--                                             群
----------------------------------------------------------------------------------------------------


--[[ QUN 004 张角（4.0）
	武将：ZhangJiao_Four
	武将名：张角
	称号：天公将军
	国籍：群
	体力上限：4
	武将技能：
		鬼道(FourGuidao)：在一名角色的判定牌生效前，你可以用一张黑色牌替换之。然后你可以在判定牌生效后展示牌堆顶的一张牌，若此牌为黑色则将其置于你的武将牌上，称为“符”，你的武将牌上最多可以有三张“符”；若此牌为红色或你不能这样做，则弃置之。每当其他角色的判定开始前，你可以获得一张“符”。
		得道(FourDedao)：觉醒技，回合开始阶段开始时，若“符”的数量达到3，你须减1点体力上限，并获得技能“雷击”。
		黄天：主公技，群雄角色可以在他们各自的出牌阶段交给你一张【闪】或【闪电】。每阶段限一次。
	技能设计：玉面
	状态：验证通过
]]
   --

ZhangJiao_Four = sgs.General(extension, "ZhangJiao_Four$", "qun", 4, true)

--[[
	技能：FourGuidao
	技能名：鬼道
	描述：在一名角色的判定牌生效前，你可以用一张黑色牌替换之。然后你可以在判定牌生效后展示牌堆顶的一张牌，若此牌为黑色则将其置于你的武将牌上，称为“符”，你的武将牌上最多可以有三张“符”；若此牌为红色或你不能这样做，则弃置之。每当其他角色的判定开始前，你可以获得一张“符”。
	状态：验证通过
	注：若判定中出现嵌套判定，在判定牌生效后的效果发动时机会不准确。
]]
   --
FourGuidao_Card = sgs.CreateSkillCard {
	name = "FourGuidao_Card",
	target_fixed = true,
	will_throw = false,
}
FourGuidao_VS = sgs.CreateViewAsSkill {
	name = "FourGuidao",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isBlack()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FourGuidao_Card:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@FourGuidao"
	end
}
FourGuidao = sgs.CreateTriggerSkill {
	name = "FourGuidao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForRetrial, sgs.FinishJudge, sgs.StartJudge },
	view_as_skill = FourGuidao_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				if not player:isNude() then
					local judge = data:toJudge()
					local prompt = string.format("@FourGuidao-card:%s:%s:%s", judge.who:objectName(), self:objectName(),
						judge.reason)
					local card = room:askForCard(player, "@FourGuidao", prompt, data, sgs.Card_MethodResponse, nil, true)
					if card then
						room:setPlayerFlag(player, "FourGuidao_Retrial")
						room:retrial(card, player, judge, self:objectName(), true)
					end
					return false
				end
			end
		elseif event == sgs.FinishJudge then
			local zhangjiaos = room:findPlayersBySkillName(self:objectName())
			for _, zhangjiao in sgs.qlist(zhangjiaos) do
				if zhangjiao:hasFlag("FourGuidao_Retrial") then
					room:setPlayerFlag(zhangjiao, "-FourGuidao_Retrial")
					if zhangjiao:askForSkillInvoke(self:objectName(), data) then
						local ids = room:getNCards(1, false)
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = zhangjiao
						move.to_place = sgs.Player_PlaceTable
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, zhangjiao:objectName(),
							self:objectName(), nil)
						room:moveCardsAtomic(move, true)
						room:getThread():delay()
						local id = ids:first()
						local card = sgs.Sanguosha:getCard(id)
						local flag = false
						--if card:isBlack() then
						if zhangjiao:getPile("symbol"):length() < 3 then
							zhangjiao:addToPile("symbol", id)
							flag = true
						end
						--end
						if not flag then
							room:throwCard(card, nil, nil)
						end
					end
				end
			end
		elseif event == sgs.StartJudge then
			local zhangjiaos = room:findPlayersBySkillName(self:objectName())
			for _, zhangjiao in sgs.qlist(zhangjiaos) do
				if zhangjiao:getPile("symbol"):length() > 0 then
					if zhangjiao:askForSkillInvoke(self:objectName() .. "take", data) then
						local symbols = zhangjiao:getPile("symbol")
						local count = symbols:length()
						local id
						if count == 0 then
							continue
						elseif count == 1 then
							id = symbols:first()
						else
							room:fillAG(symbols, zhangjiao)
							id = room:askForAG(zhangjiao, symbols, false, self:objectName())
							--zhangjiao:invoke("clearAG")
							room:clearAG()
							if id == -1 then
								return
							end
						end
						room:obtainCard(zhangjiao, id)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
ZhangJiao_Four:addSkill(FourGuidao)

--[[
	技能：FourDedao
	技能名：得道
	描述：觉醒技，回合开始阶段开始时，若“符”的数量达到3，你须减1点体力上限，并获得技能“雷击”。
	状态：验证通过
]]
   --
FourDedao = sgs.CreateTriggerSkill {
	name = "FourDedao",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		msg.type = "#FourDedao"
		msg.from = player
		msg.arg = player:getPile("symbol"):length()
		msg.arg2 = self:objectName()
		room:sendLog(msg)
		room:broadcastInvoke("animate", "lightbox:$FourDedao:3000")
		room:getThread():delay(4000)

		--player:gainMark("@waked")
		if room:changeMaxHpForAwakenSkill(player) then
			room:setPlayerMark(player, "FourDedao", 1)
			room:handleAcquireDetachSkills(player, "leiji")
		end
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		local symbol = player:getPile("symbol")
		if symbol:length() >= 3 then
			return true
		end
		return false
	end
}
ZhangJiao_Four:addSkill(FourDedao)

--[[
	技能：huangtian
	技能名：黄天
	描述：主公技，群雄角色可以在他们各自的出牌阶段交给你一张【闪】或【闪电】。每阶段限一次。
	状态：原有技能
]]
   --
ZhangJiao_Four:addSkill("huangtian")

ZhangJiao_Four:addRelateSkill("leiji")

----------------------------------------------------------------------------------------------------

--[[ QUN 005 于吉（4.0）
	武将：YuJi_Four
	武将名：于吉
	称号：太平道人
	国籍：群
	体力上限：3
	武将技能：
		蛊惑：你可以说出任何一种基本牌或非延时类锦囊牌，并正面朝下使用或打出一张手牌。若无人质疑，则该牌按你所述之牌结算。若有人质疑则亮出验明：若为真，质疑者各失去1点体力：若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真时，该牌仍然可以进行结算，否则无论真假，将该牌置入弃牌堆。
		太平(FourTaiping)：其他角色可以在他们各自的出牌阶段交给你一张红桃手牌。每阶段限一次。
	技能设计：锦衣祭司
	状态：验证通过
]]
   --

--YuJi_Four = sgs.General(extension, "YuJi_Four", "qun", 3, true)

--[[
	技能：guhuo
	技能名：蛊惑
	描述：你可以说出任何一种基本牌或非延时类锦囊牌，并正面朝下使用或打出一张手牌。若无人质疑，则该牌按你所述之牌结算。若有人质疑则亮出验明：若为真，质疑者各失去1点体力：若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真时，该牌仍然可以进行结算，否则无论真假，将该牌置入弃牌堆。
	状态：原有技能
]]
   --
--YuJi_Four:addSkill("guhuo")

--[[
	技能：FourTaiping
	技能名：太平
	描述：其他角色可以在他们各自的出牌阶段交给你一张红桃手牌。每阶段限一次。
	状态：验证通过
]]
   --
FourTaiping_Card = sgs.CreateSkillCard {
	name = "FourTaiping_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasSkill("FourTaiping") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					return not to_select:hasFlag("FourTaipingInvoked")
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local yuji = targets[1]
		if yuji:hasSkill("FourTaiping") then
			room:setPlayerFlag(yuji, "FourTaipingInvoked")
			yuji:obtainCard(self)
			local subcards = self:getSubcards()
			for _, card_id in sgs.qlist(subcards) do
				room:setCardFlag(card_id, "visible")
			end
			room:setEmotion(yuji, "good")
			local yujis = sgs.SPlayerList()
			local players = room:getOtherPlayers(source)
			for _, p in sgs.qlist(players) do
				if p:hasSkill("FourTaiping") then
					if not p:hasFlag("FourTaipingInvoked") then
						yujis:append(p)
					end
				end
			end
			if yujis:length() == 0 then
				room:setPlayerFlag(source, "ForbidFourTaiping")
			end
		end
	end
}
FourTaiping_Others = sgs.CreateViewAsSkill {
	name = "FourTaiping_Others",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FourTaiping_Card:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("ForbidFourTaiping")
	end
}
FourTaiping = sgs.CreateTriggerSkill {
	name = "FourTaiping",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasSkill(self:objectName()) then
			local others = room:getOtherPlayers(player)
			for _, p in sgs.qlist(others) do
				if not p:hasSkill("FourTaiping_Others") then
					room:attachSkillToPlayer(p, "FourTaiping_Others")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local phase_change = data:toPhaseChange()
			if phase_change.from == sgs.Player_Play then
				if player:hasFlag("ForbidFourTaiping") then
					room:setPlayerFlag(player, "-ForbidFourTaiping")
				end
				local players = room:getOtherPlayers(player)
				for _, p in sgs.qlist(players) do
					if p:hasFlag("FourTaipingInvoked") then
						room:setPlayerFlag(p, "-FourTaipingInvoked")
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
--YuJi_Four:addSkill(FourTaiping)
local skill = sgs.Sanguosha:getSkill("FourTaiping_Others")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(FourTaiping_Others)
	sgs.Sanguosha:addSkills(skillList)
end



----------------------------------------------------------------------------------------------------

--                                          DIY武将

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--                                            5.0
----------------------------------------------------------------------------------------------------


--[[ DIY 501 夏侯霸（4.0）
	武将：XiaHouBa_Diy
	武将名：夏侯霸
	称号：棘途壮志
	国籍：魏
	体力上限：4
	武将技能：
		疾速(DiyJisu)：回合开始阶段开始时，你可以进行两次判定，若其中至少一次判定的结果为黑色，你获得技能“神速”直到回合结束，并将黑色的判定牌置于你的武将牌上，称为“变”；你可以将一张“变”当【酒】使用。
		豹变(DiyBaobian)：觉醒技，当你发动“疾速”判定结束后，若“变”的数量达到3或更多，你须减1点体力上限，失去技能“疾速”，将势力改为蜀，并获得技能“挑衅”、“咆哮”和“XX”（出牌阶段，你可以将一张“变”置入弃牌堆，然后观看一名其他角色的手牌。每阶段限一次）。
		（XX）(DiyXX)：出牌阶段，你可以将一张“变”置入弃牌堆，然后观看一名其他角色的手牌。每阶段限一次。
	技能设计：一品海之蓝
	状态：验证通过
]]
   --

XiaHouBa_Diy = sgs.General(extension, "XiaHouBa_Diy", "wei", 4, true)

--[[
	技能：DiyJisu
	附加技能：DiyJisu_Get, DiyJisu_Clear
	技能名：疾速
	描述：回合开始阶段开始时，你可以进行两次判定，若其中至少一次判定的结果为黑色，你获得技能“神速”直到回合结束，并将黑色的判定牌置于你的武将牌上，称为“变”；你可以将一张“变”当【酒】使用。
	状态：验证通过
	注：夏侯霸/原版夏侯渊双将判定为黑色后，回合结束阶段会失去神速；
		
]]
   --
--[[
DiyJisu_Card = sgs.CreateSkillCard{
	name = "DiyJisu_Card",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local turns = source:getPile("turn")
		local count = turns:length()
		local id
		if count == 0 then
			return
		elseif count == 1 then
			id = turns:first()
		else
			room:fillAG(turns, source)
			id = room:askForAG(source, turns, false, self:objectName())
			source:invoke("clearAG")
			if id == -1 then
				return
			end
		end
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local analeptic = sgs.Sanguosha:cloneCard("Analeptic", suit, point)
		analeptic:setSkillName(self:objectName())
		analeptic:addSubcard(id)
		local use = sgs.CardUseStruct()
		use.card = analeptic
		use.from = source
		room:useCard(use)
	end
}
DiyJisu_VS = sgs.CreateViewAsSkill{
	name = "DiyJisu",
	n = 0,
	view_as = function(self, cards)
		return DiyJisu_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getPile("turn"):length() > 0 and not player:hasUsed("Analeptic")
	end,
	enabled_at_response = function(self, player, pattern)
		return player:getPile("turn"):length() > 0 and string.find(pattern, "analeptic")
	end
}]]
DiyJisu_VS = sgs.CreateOneCardViewAsSkill {
	name = "DiyJisu",
	filter_pattern = ".|.|.|turn",
	expand_pile = "turn",
	view_as = function(self, originalCard)
		local snatch = sgs.Sanguosha:cloneCard("analeptic", originalCard:getSuit(), originalCard:getNumber())
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end,
	enabled_at_play = function(self, player)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic")
		return not player:getPile("turn"):isEmpty() and analeptic:isAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return player:getPile("turn"):length() > 0 and string.find(pattern, "analeptic")
	end
}



DiyJisu = sgs.CreateTriggerSkill {
	name = "DiyJisu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.FinishJudge },
	view_as_skill = DiyJisu_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:askForSkillInvoke(self:objectName()) then
					local judge1 = sgs.JudgeStruct()
					judge1.pattern = ".|black"
					judge1.good = true
					judge1.reason = self:objectName()
					judge1.who = player
					judge1.time_consuming = true
					room:judge(judge1)
					room:getThread():delay()
					local judge2 = sgs.JudgeStruct()
					judge2.pattern = ".|black"
					judge2.good = true
					judge2.reason = self:objectName()
					judge2.who = player
					judge2.time_consuming = true
					room:judge(judge2)
				end
			end
		end
		return false
	end
}
DiyJisu_Get = sgs.CreateTriggerSkill { --与主技能分开，是为了保证发动豹变后第二次判定依然有效
	name = "#DiyJisu_Get",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if judge.reason == "DiyJisu" then
			local card = judge.card
			if card:isBlack() then
				if not player:hasSkill("shensu") and player:getMark("DiyJisu_Success") == 0 then
					room:handleAcquireDetachSkills(player, "shensu")
					room:setPlayerMark(player, "DiyJisu_Success", 1)
				end
				player:addToPile("turn", card, true)
			end
		end
		return false
	end
}
DiyJisu_Clear = sgs.CreateTriggerSkill { --与主技能分开，是为了在发动豹变后失去最后一次获得的神速
	name = "#DiyJisu_Clear",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("DiyJisu_Success") > 0 then
					room:detachSkillFromPlayer(player, "shensu")
					player:removeMark("DiyJisu_Success")
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == "DiyJisu" and not player:hasFlag("DiyBaobian_Process") then
				room:detachSkillFromPlayer(player, "shensu")
				player:removeMark("DiyJisu_Success")
			end
		end
		return false
	end
}
XiaHouBa_Diy:addSkill(DiyJisu)
XiaHouBa_Diy:addSkill(DiyJisu_Get)
XiaHouBa_Diy:addSkill(DiyJisu_Clear)
extension:insertRelatedSkills("DiyJisu", "#DiyJisu_Get")
extension:insertRelatedSkills("DiyJisu", "#DiyJisu_Clear")

--[[
	技能：DiyBaobian
	附加技能：DiyBaobian_Clear
	技能名：豹变
	描述：觉醒技，当你发动“疾速”判定结束后，若“变”的数量达到3或更多，你须减1点体力上限，失去技能“疾速”，将势力改为蜀，并获得技能“挑衅”、“咆哮”和“XX”（出牌阶段，你可以将一张“变”置入弃牌堆，然后观看一名其他角色的手牌。每阶段限一次）。
	状态：验证通过
]]
   --
DiyBaobian = sgs.CreateTriggerSkill {
	name = "DiyBaobian",
	frequency = sgs.Skill_Wake,
	events = { sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if judge.reason == "DiyJisu" then
			local msg = sgs.LogMessage()
			msg.type = "#DiyBaobian"
			msg.from = player
			msg.arg = player:getPile("turn"):length()
			msg.arg2 = self:objectName()
			room:sendLog(msg)
			room:broadcastInvoke("animate", "lightbox:$DiyBaobian:3000")
			room:getThread():delay(4000)
			room:setPlayerMark(player, "DiyBaobian", 1)
			--player:gainMark("@waked")
			--room:loseMaxHp(player)
			if room:changeMaxHpForAwakenSkill(player) then
				room:setPlayerFlag(player, "DiyBaobian_Process") --防止失去疾速时失去神速
				room:handleAcquireDetachSkills(player, "-DiyJisu")
				room:setPlayerFlag(player, "-DiyBaobian_Process")
				local msg = sgs.LogMessage()
				msg.type = "#DiyBaobian_Kingdom"
				msg.from = player
				msg.arg = "shu"
				room:sendLog(msg)
				room:setPlayerProperty(player, "kingdom", sgs.QVariant("shu"))
				room:handleAcquireDetachSkills(player, "tiaoxin")
				room:handleAcquireDetachSkills(player, "paoxiao")
				room:handleAcquireDetachSkills(player, "DiyXX")
			end

			return false
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		local turn = player:getPile("turn")
		if turn:length() >= 3 then
			return true
		end
		return false
	end
}
DiyBaobian_Clear = sgs.CreateTriggerSkill {
	name = "#DiyBaobian_Clear",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if data:toString() == "DiyBaobian" then
			if player:hasSkill("DiyXX") then
				room:detachSkillFromPlayer(player, "DiyXX")
			end
			if player:hasSkill("tiaoxin") then
				room:detachSkillFromPlayer(player, "tiaoxin")
			end
			if player:hasSkill("paoxiao") then
				room:detachSkillFromPlayer(player, "paoxiao")
			end
		end
		return false
	end
}
XiaHouBa_Diy:addSkill(DiyBaobian)
XiaHouBa_Diy:addSkill(DiyBaobian_Clear)
extension:insertRelatedSkills("DiyBaobian", "#DiyBaobian_Clear")

--[[
	技能：DiyXX
	技能名：XX
	描述：出牌阶段，你可以将一张“变”置入弃牌堆，然后观看一名其他角色的手牌。每阶段限一次。
	状态：验证通过
]]
   --
DiyXX_Card = sgs.CreateSkillCard {
	name = "DiyXX_Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		--[[
		local turns = source:getPile("turn")
		if turns:length() > 0 then
			local id
			if turns:length() == 1 then
				id = turns:first()
			else
				room:fillAG(turns, source)
				id = room:askForAG(source, turns, false, self:objectName())
				source:invoke("clearAG")
			end
			if id ~= -1 then
				local card = sgs.Sanguosha:getCard(id)
				room:throwCard(card, nil, nil)
				if not target:isKongcheng() then
					local ids = target:handCards()
					room:fillAG(ids, source)
					local card_id = room:askForAG(source, ids, true, "DiyXX")  --确保可以点击确定
					source:invoke("clearAG")
				end
			end
		end
        ]]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
		room:throwCard(self, reason, nil)
		room:showAllCards(targets[1], source)
		room:addPlayerMark(target, "DiyXX_Play")
	end
}
--[[
DiyXX = sgs.CreateViewAsSkill{
	name = "DiyXX",
	n = 0,
	view_as = function(self, cards)
		return DiyXX_Card:clone()
	end,
	enabled_at_play = function(self, player)
		local turns = player:getPile("turn")
		if not turns:isEmpty() then
			return not player:hasUsed("#DiyXX_Card")
		end
		return false
	end
}]]

DiyXX = sgs.CreateOneCardViewAsSkill {
	name = "DiyXX",
	filter_pattern = ".|.|.|turn",
	expand_pile = "turn",
	view_as = function(self, originalCard)
		local snatch = DiyXX_Card:clone()
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#DiyXX_Card")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}




local skill = sgs.Sanguosha:getSkill("DiyXX")
if not skill then
	local skillList = sgs.SkillList()
	skillList:append(DiyXX)
	sgs.Sanguosha:addSkills(skillList)
end

XiaHouBa_Diy:addRelateSkill("DiyXX")


----------------------------------------------------------------------------------------------------
--                                            4.0
----------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------
--[[灵雎
LingJu_Plus = sgs.General(extension, "LingJu_Plus", "qun", 3, false)
LingJu_Plus:addSkill("jieyuan")
--焚心：限定技，当你杀死一名角色时，在其翻开身份牌之前，你可以与该角色交换武将牌。（BUG：体力上限也会交换）
PlusFenxin = sgs.CreateTriggerSkill{
	name = "PlusFenxin",
	frequency = sgs.Skill_Limited,
	events = {sgs.BeforeGameOverJudge, sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeGameOverJudge then
			local damage = data:toDamageStar()
			if damage then
				local killer = damage.from
				if killer and player then
					if killer:hasSkill(self:objectName()) and killer:getMark("@burnheart") > 0 then
						room:setPlayerFlag(player, "FenxinTarget")						
						local ai_data = sgs.QVariant()
						ai_data:setValue(player)
						if room:askForSkillInvoke(killer, self:objectName(), ai_data) then
							room:broadcastInvoke("animate", "lightbox:$FenxinAnimate")
							room:getThread():delay(1500)
							killer:loseMark("@burnheart")
							local killer_name = killer:getGeneralName()
							local player_name = player:getGeneralName()
							room:changeHero(killer, player_name, false, true, false, true)
							room:changeHero(player, killer_name, false, true, false, true)
							local killer_name2 = killer:getGeneral2Name()
							if killer_name2 ~= "" then
								local player_name2 = player:getGeneral2Name()
								if player_name2 ~= "" then
									room:changeHero(killer, player_name2, false, true, true, true)
									room:changeHero(player, killer_name2, false, true, true, true)
								end
							end
						end										
						room:setPlayerFlag(player, "-FenxinTarget")	
					end
				end
			end
		end			
		if (event == sgs.GameStart and player:hasSkill(self:objectName())) then
			player:gainMark("@burnheart", 1)
			return
		end						
	end,			
	can_trigger = function(self, target)
		return target
	end,	
}
LingJu_Plus:addSkill(PlusFenxin)]]

--[[失败的傲才
ZhuGeKe = sgs.General(extension, "ZhuGeKe", "wu", 3, true)
--【傲才】当你的回合外需要使用或打出一张基本牌时，你可以观看牌堆顶两张牌，若你观看的牌中有此牌，你可以使用或打出之。
sgs.Aocai_Temp = {"Slash", "Jink", "Peach", "Analeptic"}
sgs.Aocai_Pattern = {"false", "false", "false", "false"}
doAocai = function(zhugeke, state, targets)
	local room = zhugeke:getRoom()
	local cards = room:getNCards(2, false)
	local useful = sgs.IntList()
	for _,card_id in sgs.qlist(cards) do
		local card = sgs.Sanguosha:getCard(card_id)
		for i = 1, 4, 1 do
			if card:isKindOf(sgs.Aocai_Temp[i]) and sgs.Aocai_Pattern[i] == "true" then
				useful:append(card_id)
			end
		end
	end
	if useful:length() > 0 then
		room:fillAG(cards, zhugeke)
		local card_id = room:askForAG(zhugeke, useful, true, "Aocai")
		if card_id ~= -1 then
			if useful:contains(card_id) then
				useful:removeOne(card_id)
				cards:removeOne(card_id)
				zhugeke:invoke("clearAG")
				if cards:length() > 0 then
					room:askForGuanxing(zhugeke, cards, true)
				end
				local card = sgs.Sanguosha:getCard(card_id)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, zhugeke:objectName(), "", "Aocai", "")
				room:moveCardTo(card, zhugeke, sgs.Player_PlaceTable, reason, true)
				if state == "response" then
					room:provide(card)
				elseif state == "use" then
					local target_list = sgs.SPlayerList()
					for i = 1, #targets, 1 do
						target_list:append(targets[i])
					end
					local use = sgs.CardUseStruct()
					use.card = card
					use.from = zhugeke
					use.to = target_list
					room:useCard(use)
				end
				return true
			end
		end
		zhugeke:invoke("clearAG")
	end
	if cards:length() > 0 then
		room:askForGuanxing(zhugeke, cards, true)
	end
	return false
end
Aocai_Card = sgs.CreateSkillCard{
	name = "Aocai_Card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		for i = 1, 4, 1 do
			if sgs.Aocai_Pattern[i] == "true" then
				local card = sgs.Sanguosha:cloneCard(string.lower(sgs.Aocai_Temp[i]), sgs.Card_NoSuit, 0)
				local players = sgs.PlayerList()
				if #targets > 0 then
					for _,p in pairs(targets) do
						players:append(p)
					end
				end
				return card:targetFilter(players, to_select, sgs.Self)
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		if not doAocai(source, "use", targets) then
			room:setPlayerFlag(player, "jijiang_failed")
		end
	end
}
Aocai_VS = sgs.CreateViewAsSkill{
	name = "Aocai",
	n = 0,
	view_as = function(self, cards)
		return Aocai_Card:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() == sgs.Player_NotActive then
			local flag = false
			sgs.Aocai_Pattern = {"false", "false", "false", "false"}
			for i = 1, 4, 1 do
				if string.find(pattern, string.lower(sgs.Aocai_Temp[i])) then
					sgs.Aocai_Pattern[i] = "true"
					flag = true
				end
			end
			if flag then
				--if not sgs.ClientInstance:hasNoTargetResponsing() then
					return not player:hasFlag("jijiang_failed")
				--end
			end
		end
		return false
	end
}
Aocai = sgs.CreateTriggerSkill{
	name = "Aocai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardAsked, sgs.CardFinished},
	view_as_skill = Aocai_VS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked then
			if player:getPhase() == sgs.Player_NotActive then
				local pattern = data:toString()
				local flag = false
				sgs.Aocai_Pattern = {"false", "false", "false", "false"}
				for i = 1, 4, 1 do
					if string.find(pattern, string.lower(sgs.Aocai_Temp[i])) then
						sgs.Aocai_Pattern[i] = "true"
						flag = true
					end
				end
				if flag then
					if room:askForSkillInvoke(player, self:objectName()) then
						doAocai(player, "response")
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if not card:getName() == "Aocai_Card" then
				room:setPlayerFlag(player, "-jijiang_failed")
			end
		end
		return false
	end
}
ZhuGeKe:addSkill(Aocai)
]]
