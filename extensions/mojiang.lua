local extension = sgs.Package("mojiang", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
	["mojiang"] = "极略魔武将",
}

do
    require  "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	        table.insert(kingdoms, "sgk_magic")
	config.kingdom_colors["sgk_magic"] = "#642222"
end


sgs.LoadTranslationTable{
	["sgk_magic"] = "魔",
}

sy_quanqing_USECARD = sgs.CreateTriggerSkill{
    name = "sy_quanqing_USECARD",
	events = {},
	on_trigger = function()
	end
}

function Nil2Int(nil_value)
	if nil_value == false or nil_value == nil or nil_value == "" or nil_value == 0 or nil_value == "0" then
		return 0
	else
		return nil_value
	end
end




sy_old_clear = sgs.CreateTriggerSkill{
	name = "#sy_old_clear",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if room:getCurrent():getPhase() == sgs.Player_Start then
				local who = room:getCurrent()
				if not who:getPile("you"):isEmpty() then
					local you = who:getPile("you")
					local younum = you:length()
					local idx = -1
					if younum > 0 then
						idx = you:first()
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, who:objectName(), "sy_tianyou","")
						local card = sgs.Sanguosha:getCard(idx)
						room:throwCard(card, reason, nil)
						younum = you:length()
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			local sk = data:toString()
			if sk == "sy_tianyou" then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					if not pe:getPile("you"):isEmpty() then
						local you = pe:getPile("you")
						local younum = you:length()
						local idx = -1
						if younum > 0 then
							idx = you:first()
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, pe:objectName(), "sy_tianyou","")
							local card = sgs.Sanguosha:getCard(idx)
							room:throwCard(card, reason, nil)
							younum = you:length()
						end
					end
				end
			end
		end
		return false
	end
}

--防止成为目标（天佑）
sy_pro = sgs.CreateProhibitSkill{
    name = "#sy_pro",
	is_prohibited = function(self, from, to, card)
		local you = to:getPile("you")
		local X = you:length()
		if X > 0 then
			local youid = you:first()
			local youcard = sgs.Sanguosha:getCard(youid)
			return (to:objectName() ~= from:objectName()) and card:sameColorWith(youcard) 
					and (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic"))
					and card:getTypeId() ~= sgs.Card_TypeSkill and to:getPhase() == sgs.Player_NotActive
		else
			return false
		end
	end
}

--全局摸牌
sy_global_draw = sgs.CreateDrawCardsSkill{
	name = "#sy_global_draw",
	global = true,
	draw_num_func = function(self, player, n)
		local x = 0
		for _, _name in sgs.list(player:getMarkNames()) do
			if string.find(_name, "mcc_phasedraw_num_") then x = x - player:getMark(_name) end
		end
		if Nil2Int(player:getTag("mcc_phasedraw_num"):toInt()) > 0 then x = x + Nil2Int(player:getTag("mcc_phasedraw_num"):toInt()) - 2 end
		return n + x
	end
}


--全局出杀
sy_global_targetMod = sgs.CreateTargetModSkill{
	name = "#sy_global_targetMod",
	pattern = ".",
	residue_func = function(self, from, card, to)
		local n = 0
		if card:isKindOf("Slash") then
			n = n - from:getMark("mcc_defaultslash_num_")
			if from:hasSkill("sy_duzun") or from:hasSkill("sy_longbian") then
				n = n + from:getMark("mcc_defaultslash_num")
			end
		end
		return n
	end
}



local sy_hiddenskills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_old_clear") then sy_hiddenskills:append(sy_old_clear) end
if not sgs.Sanguosha:getSkill("#sy_pro") then sy_hiddenskills:append(sy_pro) end
if not sgs.Sanguosha:getSkill("sy_quanqing_USECARD") then sy_hiddenskills:append(sy_quanqing_USECARD) end
if not sgs.Sanguosha:getSkill("#sy_global_draw") then sy_hiddenskills:append(sy_global_draw) end
if not sgs.Sanguosha:getSkill("#sy_global_targetMod") then sy_hiddenskills:append(sy_global_targetMod) end
sgs.Sanguosha:addSkills(sy_hiddenskills)


sgs.LoadTranslationTable{
	["sy_quanqing_USECARD"] = "权倾",
	["#sy_second_stage"] = "%from 暴怒了！即将进入<font color = \"yellow\"><b>三英</b></font>·<font color = \"pink\"><b>第二阶段</b></font>！",
}


--魔吕布
mo_lvbu = sgs.General(extension, "mo_lvbu", "sgk_magic", 4, true)

--[[
	技能名：神威
	相关武将：魔吕布
	技能描述：锁定技，你攻击范围内的所有其他角色手牌上限-1。
	引用：sy_shenwei
]]--

--[[
	技能名：修罗
	相关武将：魔吕布
	技能描述：当你成为【杀】或非延时锦囊的唯一目标时，你可摸一张牌，若此牌不为【决斗】，则将此牌的效果改为【决斗】。
	引用：sy_xiuluo
]]--



--[[
	技能名：神戟
	相关武将：魔吕布
	技能描述：锁定技，你使用的【杀】目标上限数+2。
	引用：sy_shenji
]]--


mo_lvbu:addSkill("sy_wushuang")
mo_lvbu:addSkill("mashu")
mo_lvbu:addSkill("sy_xiuluo")
mo_lvbu:addSkill("sy_shenwei")
mo_lvbu:addSkill("sy_shenji")
mo_lvbu:addSkill("sy_shenjiAudio")


sgs.LoadTranslationTable{
    ["mo_lvbu"] = "魔吕布",
	["#mo_lvbu"] = "暴怒战神",
	["~mo_lvbu"] = "我在地狱等着你们！",
	["sy_shenwei"] = "神威",
	["#sy_shenwei"] = "神威",
	["$sy_shenwei"] = "唔唔唔唔唔唔——！！！",
	[":sy_shenwei"] = "锁定技，你攻击范围内的所有其他角色手牌上限-1。",
	["sy_wushuang"] = "无双",
	["$sy_wushuang1"] = "你的人头，我要定了！",
	["$sy_wushuang2"] = "这就让你去死！",
	[":sy_wushuang"] = "锁定技，你使用点数为奇数的牌对其他角色造成的伤害为3点。",
	["sy_shenji"] = "神戟",
	["$sy_shenji"] = "战神之力，开！",
	[":sy_shenji"] = "锁定技，你使用【杀】的目标上限+2。",
	["sy_xiuluo"] = "修罗",
	["$sy_xiuluo"] = "不可饶恕，不可饶恕！",
	[":sy_xiuluo"] = "当你成为【杀】或非延时锦囊的唯一目标时，你可摸一张牌，若此牌不为【决斗】，则将此牌的效果改为【决斗】。",
	["#XiuluoDuel"] = "由于 %from 的“%arg”效果，%to 对 %from 使用的 %card 的效果被改为 <font color = \"yellow\"><b>决斗</b></font>",
	["designer:mo_lvbu"] = "极略三国",
	["illustrator:mo_lvbu"] = "极略三国",
	["cv:mo_lvbu"] = "极略三国",
}


--魔董卓
mo_dongzhuo = sgs.General(extension, "mo_dongzhuo", "sgk_magic", 4, true)


--[[
	技能名：纵欲
	相关武将：魔董卓
	技能描述：锁定技，出牌阶段，当你使用锦囊牌后，你视为使用【酒】。
	引用：sy_zongyu
]]--



mo_dongzhuo:addSkill("sy_zongyu")


--[[
	技能名：凌虐
	相关武将：魔董卓
	技能描述：当你造成不小于2点伤害时，你可以摸两张牌并加1点体力上限。
	引用：sy_lingnue
]]--



mo_dongzhuo:addSkill("sy_lingnue")


--[[
	技能名：暴政
	相关武将：魔董卓
	技能描述：锁定技，其他角色摸牌阶段结束时，其选择一项：交给你一张锦囊牌，或视为你对其使用【杀】。
	引用：sy_baozheng
]]--



mo_dongzhuo:addSkill("sy_baozheng")


--[[
	技能名：逆施
	相关武将：魔董卓
	技能描述：锁定技，当你受到其他角色造成的伤害后，其选择一项：弃置装备区里的所有牌，或视为你对其使用【杀】。
	引用：sy_nishi
]]--



mo_dongzhuo:addSkill("sy_nishi")


--[[
	技能名：横行
	相关武将：魔董卓
	技能描述：锁定技，当你于出牌阶段外造成伤害时，你令此伤害+1。
	引用：sy_hengxing
]]--



mo_dongzhuo:addSkill("sy_hengxing")


sgs.LoadTranslationTable{
    ["mo_dongzhuo"] = "魔董卓",
	["#mo_dongzhuo"] = "狱魔王",
	["~mo_dongzhuo"] = "那酒池肉林……都是我的……",
	["sy_zongyu"] = "纵欲",
	["$sy_zongyu"] = "呃……好酒！再来一壶！",
	[":sy_zongyu"] = "锁定技，出牌阶段，当你使用锦囊牌后，你视为使用【酒】。",
	["sy_lingnue"] = "凌虐",
	["$sy_lingnue"] = "来人！活捉了他！斩首祭旗！",
	[":sy_lingnue"] = "当你造成不小于2点伤害时，你可以摸两张牌并加1点体力上限。",
	["sy_baozheng"] = "暴政",
	["$sy_baozheng"] = "顺我者昌，逆我者亡！",
	[":sy_baozheng"] = "锁定技，其他角色摸牌阶段结束时，其选择一项：交给你一张锦囊牌，或视为你对其使用【杀】。",
	["@baozheng"] = "【暴政】效果触发，请交给%src一张锦囊牌，否则视为%src对你使用【杀】。",
	["sy_nishi"] = "逆施",
	["$sy_nishi"] = "看我不活剐了你们！",
	[":sy_nishi"] = "锁定技，当你受到其他角色造成的伤害后，其选择一项：弃置装备区里的所有牌，或视为你对其使用【杀】。",
	["clearEquipArea"] = "弃置装备区内的所有牌",
	["sy_nishi:ViewAsUseSlash"] = "视为%src对你使用【杀】",
	["sy_hengxing"] = "横行",
	["$sy_hengxing"] = "都被我踏平吧！哈哈哈哈哈哈哈哈！",
	[":sy_hengxing"] = "锁定技，当你于出牌阶段外造成伤害时，你令此伤害+1。",
	["designer:mo_dongzhuo"] = "极略三国",
	["illustrator:mo_dongzhuo"] = "极略三国",
	["cv:mo_dongzhuo"] = "极略三国",
}


--魔张角
mo_zhangjiao = sgs.General(extension, "mo_zhangjiao", "sgk_magic", 4, true)


--[[
	技能名：布教
	相关武将：魔张角
	技能描述：其他角色的准备阶段，你可令其摸1张牌并获得1个“太平”标记。其他角色的手牌上限-X（X为其“太平”标记数）。
	引用：sy_bujiao
]]--



--[[
	技能名：太平
	相关武将：魔张角
	技能描述：准备阶段，你可以弃置所有其他角色的“太平”标记并摸等量的牌，然后若你的手牌数大于其他角色的手牌数之和，你可以对其他角色各造成1点伤害。
	引用：sy_taiping
]]--



--[[
	技能名：妖惑
	相关武将：魔张角
	技能描述：出牌阶段限一次，你选择一名其他角色，然后选择一项：①弃置等同于其手牌数的牌，获得其所有手牌；②弃置等同于其技能数的牌，然后偷取其所有技能，直至其下个回合开始或死亡。
	引用：sy_yaohuo
]]--



--[[
	技能名：三治
	相关武将：魔张角
	技能描述：每当你使用3种不同类型的牌后，你可令所有其他角色获得1个“太平”标记。
	引用：sy_sanzhi
]]--



mo_zhangjiao:addSkill("sy_bujiao")
mo_zhangjiao:addSkill("sy_taiping")
mo_zhangjiao:addSkill("sy_yaohuo")
mo_zhangjiao:addSkill("sy_sanzhi")


sgs.LoadTranslationTable{	
	["mo_zhangjiao"] = "魔张角",
	["#mo_zhangjiao"] = "大贤良师",
	["~mo_zhangjiao"] = "逆道者，必遭天谴而亡！",
	["sy_bujiao"] = "布教",
	["$sy_bujiao"] = "众星熠熠，不若一日之明。",
	[":sy_bujiao"] = "其他角色的准备阶段，你可令其摸1张牌并获得1个“太平”标记。其他角色的手牌上限-X（X为其“太平”标记数）。",
	["sy_taiping"] = "太平",
	["taiping_damage"] = "对所有其他角色造成1点伤害",
	["$sy_taiping"] = "行大舜之道，救苍生万民。",
	[":sy_taiping"] = "准备阶段，你可以弃置所有其他角色的“太平”标记并摸等量的牌，然后若你的手牌数大于其他角色的手牌数之和，你可以对其他角色各造成1点伤害。",
	["sy_yaohuo"] = "妖惑",
	["sy_yaohuoCard"] = "妖惑",
	["$sy_yaohuo"] = "存恶害义，善必诛之！",
	[":sy_yaohuo"] = "出牌阶段限一次，你选择一名其他角色，然后选择一项：①弃置等同于其手牌数的牌，获得其所有手牌；②弃置等同于其技能数的牌，然后偷取其所有技能"..
	"，直至其下个回合开始或死亡。",
	["yaohuo_card"] = "获得其所有手牌",
	["yaohuo_skill"] = "获得其所有技能且其失去所有技能",
	["sy_sanzhi"] = "三治",
	["$sy_sanzhi"] = "三气集，万物治！",
	[":sy_sanzhi"] = "当你使用3种不同类型的牌后，你可令所有其他角色获得1个“太平”标记。",
	["designer:mo_zhangjiao"] = "极略三国",
	["illustrator:mo_zhangjiao"] = "极略三国",
	["cv:mo_zhangjiao"] = "极略三国",
}


--魔张让
mo_zhangrang = sgs.General(extension, "mo_zhangrang", "sgk_magic", 4, true)


--[[
	技能名：谗陷
	相关武将：魔张让
	技能描述：出牌阶段限一次，你可以移动一名角色区域里的一张牌，若如此做，视为失去牌的角色对获得牌的角色使用【决斗】，然后你获得受到此【决斗】伤害的角色的
	一张牌。
	引用：sy_chanxian
]]--



--[[
	技能名：残掠
	相关武将：魔张让
	技能描述：每当你从其他角色处获得1张牌时，你可对其造成1点伤害。每当其他角色从你处获得1张牌时，须弃置1张牌。
	引用：sy_canlue
]]--


--[[
	技能名：乱政
	相关武将：魔张让
	技能描述：每回合限一次，一名角色使用基本牌或非延时锦囊牌指定唯一目标时，你可令另一名角色也成为此牌的目标。
	引用：sy_luanzheng
]]--



mo_zhangrang:addSkill("sy_chanxian")
mo_zhangrang:addSkill("sy_luanzheng")
mo_zhangrang:addSkill("sy_canlue")


sgs.LoadTranslationTable{	
	["mo_zhangrang"] = "魔张让",
	["~mo_zhangrang"] = "小的怕是活不成了，陛下，保重……",
	["#mo_zhangrang"] = "祸乱之源",
	["sy_chanxian"] = "谗陷",
	["sy_chanxianCard"] = "谗陷",
	["@chanxian_to"] = "请选择获得此%src[%dest%arg]的角色",
	["sy_chanxianeCard"] = "谗陷",
	["$sy_chanxian1"] = "懂不懂宫里的规矩？",
	["$sy_chanxian2"] = "活得不耐烦了吧？",
	[":sy_chanxian"] = "出牌阶段限一次，你可以移动一名角色区域里的一张牌，若如此做，视为失去牌的角色对获得牌的角色使用【决斗】，然后你获得受到此【决斗】伤害的角色的一张牌。",
	["sy_canlue"] = "残掠",
	["$sy_canlue"] = "没钱？没钱，就拿命来抵吧！",
	[":sy_canlue"] = "当你从其他角色处获得一张牌后，你可对其造成1点伤害。当其他角色获得你的一张牌时，你令其弃置1张牌。",
	["sy_luanzheng"] = "乱政",
	["#LuanzhengExTarget"] = "%from 令 %to 成为 %card 的额外目标",
	["$sy_luanzheng1"] = "陛下，都、都是他们干的！",
	["$sy_luanzheng2"] = "大、大、大事不好！有人造反了！",
	[":sy_luanzheng"] = "每回合限一次，一名角色使用基本牌或非延时锦囊牌指定唯一目标时，你可令另一名角色也成为此牌的目标。",
	["@luanzheng-extra"] = "你可以发动【乱政】为此%src[%dest%arg]选择一名其他角色作为额外目标",
	["designer:mo_zhangrang"] = "极略三国",
	["illustrator:mo_zhangrang"] = "极略三国",
	["cv:mo_zhangrang"] = "极略三国",
}


--魔魏延
mo_weiyan = sgs.General(extension, "mo_weiyan", "sgk_magic", 4, true)


--[[
	技能名：恃傲
	相关武将：魔魏延
	技能描述：准备阶段或回合结束阶段开始时，你可以视为对一名其他角色使用一张【杀】（不计次、无距离限制）。
	引用：sy_shiao
]]--



--[[
	技能名：反骨
	相关武将：魔魏延
	技能描述：锁定技，当你受到的伤害结算完毕后，你令当前回合结束，然后你进行一个额外的回合。
	引用：sy_fangu
]]--


--[[
	技能名：狂袭
	相关武将：魔魏延
	技能描述：当你使用的指定其他角色为目标的锦囊牌结算完毕后，你可以视为对这些目标使用一张【杀】（不计入出牌阶段使用次数限制）。若以此法使用的【杀】未造成伤害，你失去1点体力。
	引用：sy_kuangxi
]]--



mo_weiyan:addSkill("sy_shiao")
mo_weiyan:addSkill("sy_fangu")
mo_weiyan:addSkill("sy_kuangxi")


sgs.LoadTranslationTable{	
	["mo_weiyan"] = "魔魏延",
	["#mo_weiyan"] = "嗜血狂狼",
	["~mo_weiyan"] = "这……就是老子追求的东西吗？",
	["sy_shiao"] = "恃傲",
	["@shiao-tar"] = "你可以发动“恃傲”视为对一名其他角色使用一张【杀】<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["shiao-slash"] = "恃傲",
	["$sy_shiao1"] = "靠手里的家伙来说话吧。",
	["$sy_shiao2"] = "少废话！真有本事就来打！",
	[":sy_shiao"] = "准备阶段或回合结束阶段开始时，你可以视为对一名其他角色使用一张【杀】（不计次、无距离限制）。",
	["sy_fangu"] = "反骨",
	["$sy_fangu"] = "一群胆小之辈，成天坏我大事！",
	["#fanguExTurn"] = "%from 的“%arg”被触发，由于 %from 受到了伤害，当前回合将结束，并且 %from 将在此回合结束后立即进行一个额外的回合",
	[":sy_fangu"] = "锁定技，当你受到的伤害结算完毕后，你令当前回合结束，然后你进行一个额外的回合。",
	["sy_kuangxi"] = "狂袭",
	["$sy_kuangxi1"] = "敢挑战老子，你就后悔去吧！",
	["$sy_kuangxi2"] = "凭你们，是阻止不了老子的！",
	[":sy_kuangxi"] = "当你使用锦囊牌指定其他角色为目标后，你可以视为对这些目标使用一张【杀】（不计入出牌阶段使用次数限制）。若以此法使用的【杀】未造成伤害，你失去1点体力。",
	["designer:mo_weiyan"] = "极略三国",
	["illustrator:mo_weiyan"] = "极略三国",
	["cv:mo_weiyan"] = "极略三国",
}


--魔孙皓
mo_sunhao = sgs.General(extension, "mo_sunhao", "sgk_magic", 4, true)


--[[
	技能名：明政
	相关武将：魔孙皓
	技能描述：锁定技，其他角色/你的摸牌阶段摸牌数+1/+2。当你受到伤害后，你摸X张牌（X为已进行的回合数）并失去“明政”，然后获得“嗜杀”。
	引用：sy_mingzheng
]]--



--[[
	技能名：荒淫
	相关武将：魔孙皓
	技能描述：当你弃置其他角色的牌时，你可以从这些牌里随机获得一张牌。
	引用：sy_huangyin
]]--



--[[
	技能名：醉酒
	相关武将：魔孙皓
	技能描述：出牌阶段，你可以随机弃置X张手牌（X为你于本阶段内再次发动“醉酒”的次数），然后视为随机使用【酒】或【杀】，且以此法使用的牌不计入次数限制。
	引用：sy_zuijiu
]]--

--[[
	技能名：归命
	相关武将：魔孙皓
	技能描述：限定技，当你进入濒死状态时，你可以回复体力至X点，然后你依次弃置所有其他角色随机X张牌（X为存活角色数）。
	引用：sy_guiming
]]--



mo_sunhao:addSkill("sy_mingzheng")
mo_sunhao:addRelateSkill("sy_shisha")
mo_sunhao:addSkill("sy_huangyin")
mo_sunhao:addSkill("sy_zuijiu")
mo_sunhao:addSkill("sy_guiming")


sgs.LoadTranslationTable{	
	["mo_sunhao"] = "魔孙皓",
	["#mo_sunhao"] = "末世暴君",
	["~mo_sunhao"] = "乱臣贼子，不得好死！",
	["sy_mingzheng"] = "明政",
	[":sy_mingzheng"] = "锁定技，其他角色/你的摸牌阶段摸牌数+1/+2。当你受到伤害后，你摸X张牌（X为已进行的回合数）并失去“明政”，然后获得“嗜杀”。",
	["$sy_mingzheng"] = "开仓放粮，赈济百姓！",
	["sy_shisha"] = "嗜杀",
	[":sy_shisha"] = "锁定技，当你使用【杀】指定目标后，你随机弃置目标角色1-3张牌。",
	["$sy_shisha"] = "净是些碍眼的家伙，都杀！都杀！",
	["sy_zuijiu"] = "醉酒",
	["$sy_zuijiu"] = "酒……酒呢！拿酒来！",
	["sy_zuijiunormalslash"] = "醉酒",
	["sy_zuijiuNormalSlashCard"] = "醉酒",
	["@sy_zuijiuNormalSlash"] = "你可以视为对一名其他角色使用不计入次数限制的【杀】",
	["~sy_zuijiuNormalSlash"] = "选择目标角色，点击“确定”",
	[":sy_zuijiu"] = "出牌阶段，你可以随机弃置X张手牌（X为你于本阶段内再次发动“醉酒”的次数），然后视为随机使用【酒】或【杀】，以此法使用的牌不计入次数限制。",
	["sy_huangyin"] = "荒淫",
	["$sy_huangyin"] = "美人儿来来来，让朕瞧瞧！",
	[":sy_huangyin"] = "当你弃置其他角色的牌时，你可以从这些牌里随机获得一张牌。",
	["sy_guiming"] = "归命",
	["@guiming"] = "归命",
	["$sy_guiming"] = "你们！难道忘了朝廷之恩吗！",
	[":sy_guiming"] = "限定技，当你进入濒死状态时，你可以回复体力至X点，然后你依次弃置所有其他角色随机X张牌（X为存活角色数）。",
	["designer:mo_sunhao"] = "极略三国",
	["illustrator:mo_sunhao"] = "极略三国",
	["cv:mo_sunhao"] = "极略三国",
}


--魔蔡夫人
mo_caifuren = sgs.General(extension, "mo_caifuren", "sgk_magic", 4, false)


--[[
	技能名：诋毁
	相关武将：魔蔡夫人
	技能描述：出牌阶段限一次，你可以令一名角色对另一名体力较少的角色造成1点伤害。若你不是伤害来源，你回复1点体力。
	引用：sy_dihui
]]--



--[[
	技能名：乱嗣
	相关武将：魔蔡夫人
	技能描述：出牌阶段限一次，你可以令两名有手牌的角色拼点：当一名角色没赢后，你弃置其两张牌。若拼点赢的角色不是你，你摸两张牌。
	引用：sy_luansi
]]--



--[[
	技能名：祸心
	相关武将：魔蔡夫人
	技能描述：锁定技，当你即将受到伤害时，伤害来源选择一项：①令你获得其区域里各一张牌；②防止此伤害，其失去1点体力。
	引用：sy_huoxin
]]--



mo_caifuren:addSkill("sy_dihui")
mo_caifuren:addSkill("sy_luansi")
mo_caifuren:addSkill("sy_huoxin")


sgs.LoadTranslationTable{	
	["mo_caifuren"] = "魔蔡夫人",
	["#mo_caifuren"] = "蛇蝎美人",
	["~mo_caifuren"] = "做鬼也不会放过你的！",
	["sy_dihui"] = "诋毁",
	["$sy_dihui1"] = "夫君，此人留不得！",
	["$sy_dihui2"] = "养虎为患，须尽早除之！",
	["$sy_luansi1"] = "教你见识一下我的手段！",
	["$sy_luansi2"] = "求饶？呵呵……晚了！",
	[":sy_dihui"] = "出牌阶段限一次，你可以令一名角色对另一名体力较少的角色造成1点伤害。若你不是伤害来源，你回复1点体力。",
	["dihuiothers-choose"] = "请选择因“诋毁”受到伤害的另一名其他角色。",
	["sy_luansi"] = "乱嗣",
	[":sy_luansi"] = "出牌阶段限一次，你可以令两名有手牌的角色拼点：当一名角色没赢后，你弃置其两张牌。若拼点赢的角色不是你，你摸两张牌。",
	["sy_huoxin"] = "祸心",
	["$sy_huoxin"] = "别敬酒不吃吃罚酒！",
	[":sy_huoxin"] = "锁定技，当你即将受到伤害时，伤害来源选择一项：①令你获得其区域里各一张牌；②失去1点体力，然后防止此伤害。",
	["obtain_equip"] = "该角色获得你每个区域各一张牌",
	["lose_hp"] = "防止此伤害，然后失去一点体力",
	["designer:mo_caifuren"] = "极略三国",
	["illustrator:mo_caifuren"] = "极略三国",
	["cv:mo_caifuren"] = "极略三国",
}


--魔司马懿
mo_simayi = sgs.General(extension, "mo_simayi", "sgk_magic", 4, true)

--[[
	技能名：博略
	相关武将：魔司马懿
	技能描述：锁定技，回合开始前，你随机获得你一个你拥有的魏/蜀/吴势力的技能，直至下个回合开始。
	引用：sy_bolue
]]--


--[[
	技能名：忍忌
	相关武将：魔司马懿
	技能描述：当你受到伤害后，你可以摸一张牌，则你发动“博略”时额外随机获得一个你拥有的与来源势力相同的技能。
	引用：sy_renji
]]--


--[[
	技能名：变天
	相关武将：魔司马懿
	技能描述：锁定技，其他角色的判定阶段，须进行一次额外的【闪电】判定。
	引用：sy_biantian
]]--



--[[
	技能名：天佑
	相关武将：魔司马懿
	技能描述：锁定技，回合结束阶段，若没有角色受到过【闪电】伤害，你回复1点体力，否则你摸X张牌（X为全场所有角色受到的【闪电】伤害次数）。
	引用：sy_tianyou
]]--



mo_simayi:addSkill("sy_bolue")
mo_simayi:addSkill("sy_renji")
mo_simayi:addSkill("sy_biantian")
mo_simayi:addSkill("sy_tianyou")


sgs.LoadTranslationTable{		
	["mo_simayi"] = "魔司马懿",
	["~mo_simayi"] = "呃哦……呃啊……",
	["#mo_simayi"] = "三分归晋",
	["sy_bolue"] = "博略",
	["$sy_bolue1"] = "老夫，想到一些有趣之事。",
	["$sy_bolue2"] = "无用之物，老夫毫无兴趣。",
	["$sy_bolue3"] = "杀人伎俩，偶尔一用无妨。",
	["$sy_bolue4"] = "此种事态，老夫早有准备。",
	[":sy_bolue"] = "锁定技，回合开始前，你随机获得你一个你拥有的魏/蜀/吴势力的技能，直至下个回合开始。",
	["sy_renji"] = "忍忌",
	["$sy_renji1"] = "老夫也不得不认真起来了。",
	["$sy_renji2"] = "你们，是要置老夫于死地吗？",
	["$sy_renji3"] = "休要聒噪，吵得老夫头疼！",
	[":sy_renji"] = "当你受到伤害后，你可以摸一张牌，则你发动“博略”时额外随机获得一个你拥有的与来源势力相同的技能。",
	["#RenjiRecNew"] = "%from 记录了 %arg 势力，共计 %arg2 个",
	["#RenjiRec"] = "%from 记录了 %arg 势力，共计 %arg2 个",
	["sy_biantian"] = "变天",
	["$sy_biantian"] = "雷起！喝！",
	[":sy_biantian"] = "锁定技，其他角色的判定阶段，你令其进行【闪电】判定。",
	["sy_tianyou"] = "天佑",
	["$sy_tianyou"] = "好好看着吧！",
	["#TianyouDraw"] = "%from 的“%arg”被触发，本局游戏中【<font color=\"gold\"><b>闪电</b></font>】已一共造成了 %arg2 次伤害，将摸 %arg2 张牌",
	[":sy_tianyou"] = "锁定技，回合结束阶段，若没有角色受到过【闪电】伤害，你回复1点体力，否则你摸X张牌（X为全场所有角色受到的【闪电】伤害次数）。",
	["designer:mo_simayi"] = "极略三国",
	["illustrator:mo_simayi"] = "极略三国",
	["cv:mo_simayi"] = "极略三国",
}


--魔袁绍
mo_yuanshao = sgs.General(extension, "mo_yuanshao", "sgk_magic", 4, true)


--[[
	技能名：魔箭
	相关武将：魔袁绍
	技能描述：锁定技，准备阶段，你视为使用【万箭齐发】，若有角色打出【闪】响应此牌，回合结束阶段，你视为使用【万箭齐发】。
	引用：sy_mojian
]]--



--[[
	技能名：主宰
	相关武将：魔袁绍
	技能描述：锁定技，你受到锦囊牌造成的伤害-1，以你为来源的锦囊牌造成的伤害+1。
	引用：sy_zhuzai
]]--


--[[
	技能名：夺冀
	相关武将：魔袁绍
	技能描述：锁定技，当你杀死其他角色时，你获得其所有手牌和武将技能。
	引用：sy_duoji
]]--



mo_yuanshao:addSkill("sy_mojian")
mo_yuanshao:addSkill("sy_zhuzai")
mo_yuanshao:addSkill("sy_duoji")


sgs.LoadTranslationTable{		
	["mo_yuanshao"] = "魔袁绍",
	["#mo_yuanshao"] = "魔君",
	["~mo_yuanshao"] = "我不甘心！我不甘心啊！！！",
	["sy_mojian"] = "魔箭",
	["$sy_mojian1"] = "血肉之躯，怎可挡我万箭穿心！",
	["$sy_mojian2"] = "全都去死，去死吧！",
	["mojian_jink"] = "魔箭被闪响应",
	[":sy_mojian"] = "锁定技，准备阶段，你视为使用【万箭齐发】，若有角色打出【闪】响应此牌，回合结束阶段，你视为使用【万箭齐发】。",
	["sy_zhuzai"] = "主宰",
	["$sy_zhuzai1"] = "天命在我，尔等凡人还不跪拜！",
	["$sy_zhuzai2"] = "四世三公，名动天下！",
	[":sy_zhuzai"] = "锁定技，你受到锦囊牌造成的伤害-1，以你为来源的锦囊牌造成的伤害+1。",
	["sy_duoji"] = "夺冀",
	["$sy_duoji1"] = "冀州已得，这天下迟早是我的！",
	["$sy_duoji2"] = "属于我的东西，不如趁早双手奉上！",
	[":sy_duoji"] = "锁定技，当你杀死其他角色时，你获得其所有手牌和武将技能。",
	["designer:mo_yuanshao"] = "极略三国",
	["illustrator:mo_yuanshao"] = "极略三国",
	["cv:mo_yuanshao"] = "极略三国",
}


--魔曹操
mo_caocao = sgs.General(extension, "mo_caocao", "sgk_magic", 4, true)


--[[
	技能名：魏武
	相关武将：魔曹操
	技能描述：当你受到伤害后，你可以摸两张牌，然后若造成此伤害的渠道为实体【杀】或普通锦囊牌，你可获得此牌和弃牌堆里所有同名牌。
	引用：sy_weiwu
]]--
sy_weiwu = sgs.CreateTriggerSkill{
	name = "sy_weiwu",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.damage > 0 then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
				if damage.card then
					local ids = sgs.IntList()
					if damage.card:isVirtualCard() then
						ids = damage.card:getSubcards()
					else
						ids:append(damage.card:getEffectiveId())
					end
					if ids:isEmpty() then return end
					for _, id in sgs.qlist(ids) do
						if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
					end
					player:obtainCard(damage.card)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
					dummy:deleteLater()
					if not room:getDiscardPile():isEmpty() then
						for _, id in sgs.qlist(room:getDiscardPile()) do
							if sgs.Sanguosha:getCard(id):objectName() == damage.card:objectName() then dummy:addSubcard(id) end
						end
					end
					if dummy:subcardsLength() > 0 then player:obtainCard(dummy) end
				end
			end
		end
	end
}


mo_caocao:addSkill(sy_weiwu)


--[[
	技能名：独尊
	相关武将：魔曹操
	技能描述：锁定技，每名角色限两次，其他角色的准备阶段，其须选择大于0的一项基础值-1且令你的相同项+1：每回合使用【杀】次数上限，摸牌阶段摸牌数，体力上限。
	引用：sy_duzun
]]--
function updateMCCvalue(mcc, mcc_skill)
	local room = sgs.Sanguosha:currentRoom()
	local s, d, m = Nil2Int(mcc:getTag("mcc_defaultslash_num"):toInt()), Nil2Int(mcc:getTag("mcc_phasedraw_num"):toInt()), mcc:getMaxHp()
	if s == 0 then s = s + 1 end
	if d == 0 then d = d + 2 end
	s = s - mcc:getMark("mcc_defaultslash_num_")
	d = d - mcc:getMark("mcc_phasedraw_num_")
	mcc:setSkillDescriptionSwap(mcc_skill, "%arg1", math.max(0, s))
	mcc:setTag("mcc_defaultslash_num", sgs.QVariant(math.max(0, s)))
	mcc:setSkillDescriptionSwap(mcc_skill, "%arg2", math.max(0, d))
	mcc:setTag("mcc_phasedraw_num", sgs.QVariant(math.max(0, d)))
	mcc:setSkillDescriptionSwap(mcc_skill, "%arg3", m)
	room:changeTranslation(mcc, mcc_skill)
end

sy_duzun = sgs.CreateTriggerSkill{
	name = "sy_duzun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill, sgs.MaxHpChanged},
	can_trigger = function(self, target)
		return target and target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		if event == sgs.EventPhaseStart then
			for _, cc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:objectName() ~= cc:objectName() and player:getTag(self:objectName()):toInt() < 2 and player:isAlive() and player:getPhase() == sgs.Player_Start then
					local items = {"mcc_defaultslash_num", "mcc_phasedraw_num", "mcc_maxhp"}
					local x = Nil2Int(player:getTag(self:objectName()):toInt())
					local y = player:getMark("mcc_phasedraw_num_")
					player:setTag(self:objectName(), sgs.QVariant(x+1))
					room:sendCompulsoryTriggerLog(cc, self:objectName(), true, true)
					if player:getMark("mcc_defaultslash_num_") >= 1 then table.removeOne(items, "mcc_defaultslash_num") end
					if y >= 2 then table.removeOne(items, "mcc_phasedraw_num") end
					local to_lose = room:askForChoice(player, self:objectName(), table.concat(items, "+"), data)
					local msg = sgs.LogMessage()
					msg.from = player
					msg.type = "#duzunLose"
					msg.arg = to_lose
					room:sendLog(msg)
					if to_lose == "mcc_defaultslash_num" then
						room:addPlayerMark(player, to_lose.."_")
						local s = 0
						if Nil2Int(cc:getTag(to_lose):toInt()) == 0 then
							s = s + 1
						else
							s = s + Nil2Int(cc:getTag(to_lose):toInt())
						end --杀次数基础值：1
						s = s - cc:getMark("mcc_defaultslash_num_")
						updateMCCvalue(cc, self:objectName())
						if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
						cc:setTag(to_lose, sgs.QVariant(s+1))
						room:setPlayerMark(cc, to_lose, s)
						updateMCCvalue(cc, self:objectName())
						if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
					elseif to_lose == "mcc_phasedraw_num" then
						room:addPlayerMark(player, to_lose.."_")
						local k = 0
						if Nil2Int(cc:getTag(to_lose):toInt()) == 0 then
							k = k + 2
						else
							k = k + Nil2Int(cc:getTag(to_lose):toInt())
						end  --摸牌阶段摸牌基础值：2
						k = k - cc:getMark("mcc_phasedraw_num_")
						updateMCCvalue(cc, self:objectName())
						if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
						cc:setTag(to_lose, sgs.QVariant(k+1))
						updateMCCvalue(cc, self:objectName())
						if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
					elseif to_lose == "mcc_maxhp" then
						updateMCCvalue(cc, self:objectName())
						if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
						room:loseMaxHp(player, 1)
						room:gainMaxHp(cc, 1)
						updateMCCvalue(cc, self:objectName())
						if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
					end
					room:changeTranslation(cc, "sy_duzun")
					if cc:hasSkill("sy_longbian") then room:changeTranslation(cc, "sy_longbian") end
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				for _, cc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getSeat() == cc:getSeat() then
						for _, pe in sgs.qlist(room:getAllPlayers(true)) do
							room:setPlayerMark(pe, "mcc_defaultslash_num_", 0)
							pe:removeTag("mcc_phasedraw_num")
							room:setPlayerMark(pe, "mcc_phasedraw_num_", 0)
							pe:removeTag("mcc_defaultslash_num")
						end
					end
				end
			end
		elseif event == sgs.MaxHpChanged then
			local change = data:toMaxHp()
			for _, cc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if change.who:objectName() == cc:objectName() then
					updateMCCvalue(cc, self:objectName())
					room:changeTranslation(cc, "sy_duzun")
					if cc:hasSkill("sy_longbian") then updateMCCvalue(cc, "sy_longbian") end
				end
			end
		end
		return false
	end
}


mo_caocao:addSkill(sy_duzun)


--[[
	技能名：龙变
	相关武将：魔曹操
	技能描述：准备阶段，你可以令你以下三项基础值中的两项互换，然后剩下的一项的数值+1：每回合使用【杀】次数上限，摸牌阶段摸牌数，体力上限。
	引用：sy_longbian
]]--
sy_longbian = sgs.CreateTriggerSkill{
	name = "sy_longbian",
	events = {sgs.EventPhaseStart, sgs.MaxHpChanged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					--注意：摸牌数、杀的次数记录的都是基础值，在转换成对应的增益时，需要减去基础值（如：记录的摸牌数为3，则增益值为3-2=1；记录的【杀】次数为3，则可额外出【杀】次数为3-1=2）
					local items = {"mcc_defaultslash_num", "mcc_phasedraw_num", "mcc_maxhp"}
					local x = 0 --【杀】可用次数
					local y = 0  --摸牌阶段摸牌数
					if (not player:getTag("mcc_phasedraw_count"):toInt()) or player:getTag("mcc_phasedraw_count"):toInt() == 0 then
						if Nil2Int(player:getTag("mcc_phasedraw_num"):toInt()) == 0 then y = y + 2 else y = y + player:getTag("mcc_phasedraw_num"):toInt() end
					else
						if player:getTag("mcc_phasedraw_count"):toInt() then y = y + player:getTag("mcc_phasedraw_count"):toInt() end
					end
					local z = player:getMaxHp()  --体力上限
					if Nil2Int(player:getTag("mcc_defaultslash_num"):toInt()) == 0 then x = x + 1 else x = x + player:getTag("mcc_defaultslash_num"):toInt() end
					room:setPlayerMark(player, "mcc_defaultslash_num", x-1)
					local msg = sgs.LogMessage()
					msg.from = player
					msg.type = "#longbianData"
					msg.arg = tostring(x)
					msg.arg2 = tostring(y)
					msg.arg3 = tostring(z)
					room:sendLog(msg)
					local new_slashnum, new_drawnum = 0, 0
					local to_add = room:askForChoice(player, self:objectName(), table.concat(items, "+"), data)
					if to_add == "mcc_maxhp" then  --交换【杀】使用次数和摸牌数，体力上限+1
						new_slashnum = y
						new_drawnum = x
						room:gainMaxHp(player, 1)
					elseif to_add == "mcc_defaultslash_num" then  --交换体力上限和摸牌数，【杀】使用次数（x）+1
						new_slashnum = x + 1
						new_drawnum = z
						local dif1 = math.abs(y-z)
						if y > z then
							room:gainMaxHp(player, dif1)
						elseif y < z then
							room:loseMaxHp(player, dif1)
						end
					elseif to_add == "mcc_phasedraw_num" then --交换体力上限和【杀】使用次数，摸牌数（y）+1
						new_drawnum = y + 1
						new_slashnum = z
						local dif2 = math.abs(x-z)
						if x > z then
							room:gainMaxHp(player, dif2)
						elseif x < z then
							room:loseMaxHp(player, dif2)
						end
					end
					player:setTag("mcc_defaultslash_num", sgs.QVariant(new_slashnum))
					player:setTag("mcc_phasedraw_num", sgs.QVariant(new_drawnum))
					room:setPlayerMark(player, "mcc_defaultslash_num", new_slashnum-1)
					if player:hasSkill("sy_duzun") then
						updateMCCvalue(player, "sy_duzun")
						room:changeTranslation(player, "sy_duzun")
					end
					updateMCCvalue(player, self:objectName())
					room:changeTranslation(player, self:objectName())
					local msg2 = sgs.LogMessage()
					msg2.from = player
					msg2.type = "#longbianUpdate"
					msg2.arg = to_add
					msg2.arg2 = tostring(new_slashnum)
					msg2.arg3 = tostring(new_drawnum)
					msg2.arg4 = tostring(player:getMaxHp())
					room:sendLog(msg2)
				end
			end
		elseif event == sgs.MaxHpChanged then
			updateMCCvalue(player, "sy_duzun")
			room:changeTranslation(player, "sy_duzun")
			updateMCCvalue(player, self:objectName())
			room:changeTranslation(player, self:objectName())
		end
		return false
	end
}


mo_caocao:addSkill(sy_longbian)


sgs.LoadTranslationTable{		
	["mo_caocao"] = "魔曹操",
	["#mo_caocao"] = "黯世权龙",
	["~mo_caocao"] = "孤不嫌世，世却不容孤！",
	["sy_weiwu"] = "魏武",
	["$sy_weiwu1"] = "国家无有孤，不知几人称帝，几人称王！",
	["$sy_weiwu2"] = "燕雀安知鸿鹄之志！",
	[":sy_weiwu"] = "当你受到伤害后，你可以摸两张牌，然后若造成此伤害的渠道为实体【杀】或普通锦囊牌，你可获得此牌和弃牌堆里所有同名牌。",
	["sy_duzun"] = "独尊",
	["$sy_duzun1"] = "天下人的命，不及孤之霸业！",
	["$sy_duzun2"] = "世人皆蝼蚁，无奸不成雄！",
	[":sy_duzun"] = "锁定技，每名角色限两次，其他角色的准备阶段，其须选择大于0的一项基础值-1且令你的相同项+1：每回合使用【杀】次数上限，摸牌阶段摸牌数，体力上限。",
	[":sy_duzun1"] = "锁定技，每名角色限两次，其他角色的准备阶段，其须选择大于0的一项基础值-1且令你的相同项+1：每回合使用【杀】次数上限，摸牌阶段摸牌数，体力上限。\
	<font color=\"#00BFFF\">当前基础值：每回合可用【%arg1】次【杀】，摸牌阶段摸【%arg2】张牌，体力上限【%arg3】点</font>",
	["mcc_defaultslash_num"] = "每回合【杀】使用次数",
	["mcc_phasedraw_num"] = "摸牌阶段摸牌数",
	["mcc_maxhp"] = "体力上限",
	["#duzunLose"] = "%from 选择了令自己的 %arg 的数值-1",
	["sy_longbian"] = "龙变",
	["#longbianData"] = "%from 当前各项目的基础数值：每回合可使用 %arg 次【杀】，摸牌阶段摸 %arg2 张牌，体力上限 %arg3 点",
	["$sy_longbian1"] = "飞腾于宇宙之间，潜伏于波涛之内。",
	["$sy_longbian2"] = "兴云吐雾，隐介藏形，犹人得志，纵横四海。",
	[":sy_longbian"] = "准备阶段，你可以令你以下三项基础值中的两项互换，然后剩下的一项的数值+1：每回合使用【杀】次数上限，摸牌阶段摸牌数，体力上限。\
	<font color=\"#9932CC\">操作方法：弹窗中选择的那一项是你接下来基础数值+1的，没选的那两项将互换。</font>",
	[":sy_longbian1"] = "准备阶段，你可以令你以下三项基础值中的两项互换，然后剩下的一项的数值+1：每回合使用【杀】次数上限，摸牌阶段摸牌数，体力上限。\
	<font color=\"#00BFFF\">当前基础值：每回合可用【%arg1】次【杀】，摸牌阶段摸【%arg2】张牌，体力上限【%arg3】点</font>\
	<font color=\"#9932CC\">操作方法：弹窗中选择的那一项是你接下来基础数值+1的，没选的那两项将互换。</font>",
	["#longbianUpdate"] = "%from 选择令自己 %arg 的数值+1，交换了其余两项，目前基础数值属性：每回合可使用 %arg2 次【杀】，摸牌阶段摸 %arg3 张牌，体力上限 %arg4 点",
	["designer:mo_caocao"] = "极略三国",
	["illustrator:mo_caocao"] = "极略三国",
	["cv:mo_caocao"] = "极略三国",
}


--魔邹氏
mo_zoushi = sgs.General(extension, "mo_zoushi", "sgk_magic", 4, false)


--[[
	技能名：祸世
	相关武将：魔邹氏
	技能描述：锁定技，当其他角色使用基本牌或非延时锦囊牌指定目标时，你令随机一名不是此牌目标的角色也成为此牌的目标。
	引用：sy_huoshi
]]--
sy_huoshi = sgs.CreateTriggerSkill{
	name = "sy_huoshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming, sgs.CardFinished},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		local zoushi = room:findPlayerBySkillName(self:objectName())
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.from and use.card and use.from:objectName() ~= zoushi:objectName() and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and use.to:length() > 0 then
				local others = sgs.SPlayerList()
				for _, t in sgs.qlist(room:getAlivePlayers()) do
					if not use.to:contains(t) and (not sgs.Sanguosha:isProhibited(use.from, t, use.card)) then others:append(t) end
				end
				if others:isEmpty() then return false end
				if zoushi:getMark("huoshi_extarget"..use.card:toString()) > 0 then return false end
				zoushi:addMark("huoshi_extarget"..use.card:toString())
				others = sgs.QList2Table(others)
				local exone = others[math.random(1, #others)]
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, use.from:objectName(), exone:objectName())
				local msg = sgs.LogMessage()
				msg.from = zoushi
				msg.arg = self:objectName()
				msg.type = "#HuoshiExTarget"
				msg.to:append(exone)
				msg.card_str = use.card:toString()
				room:sendLog(msg)
				use.to:append(exone)
				room:sortByActionOrder(use.to)
				data:setValue(use)
				room:setPlayerFlag(use.from, "ZenhuiUser_" .. use.card:toString())
				room:getThread():trigger(sgs.TargetConfirming, room, exone, data)
				return false
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if zoushi:getMark("huoshi_extarget"..use.card:toString()) > 0 then
				zoushi:setMark("huoshi_extarget"..use.card:toString(), 0)
			end
		end
		return false
	end
}


mo_zoushi:addSkill(sy_huoshi)


--[[
	技能名：淫恣
	相关武将：魔邹氏
	技能描述：锁定技，每回合每名角色各限一次，当其他角色于回合外获得牌/回复体力后，你回复1点体力/摸两张牌。
	引用：sy_yinzi
]]--
sy_yinzi = sgs.CreateTriggerSkill{
	name = "sy_yinzi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill, sgs.HpRecover, sgs.CardsMoveOneTime},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:removeTag("yinzi_obtaincard")
					pe:removeTag("yinzi_hprecover")
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			death.who:removeTag("yinzi_obtaincard")
			death.who:removeTag("yinzi_hprecover")
			if death.who:hasSkill(self:objectName()) then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:removeTag("yinzi_obtaincard")
					pe:removeTag("yinzi_hprecover")
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				for _, pe in sgs.qlist(room:getAlivePlayers()) do
					pe:removeTag("yinzi_obtaincard")
					pe:removeTag("yinzi_hprecover")
				end
			end
		elseif event == sgs.HpRecover then
			if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
			local zoushi = room:findPlayerBySkillName(self:objectName())
			if player:getSeat() ~= zoushi:getSeat() and player:getPhase() == sgs.Player_NotActive and not player:getTag("yinzi_hprecover"):toBool() then
				player:setTag("yinzi_hprecover", sgs.QVariant(true))
				room:broadcastSkillInvoke(self:objectName())
				local msg1 = sgs.LogMessage()
				msg1.from = zoushi
				msg1.arg = self:objectName()
				msg1.to:append(player)
				msg1.type = "#yinziRecover"
				msg1.arg2 = tostring(2)
				room:sendLog(msg1)
				zoushi:drawCards(2, self:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
			local zoushi = room:findPlayerBySkillName(self:objectName())
			local move = data:toMoveOneTime()
			if move.to and move.to_place == sgs.Player_PlaceHand then
				local _to = -1
				for _, t in sgs.qlist(room:getAlivePlayers()) do
					if move.to:objectName() == t:objectName() then
						_to = t
						break
					end
				end
				if _to ~= -1 then
					if _to:getPhase() == sgs.Player_NotActive and (not _to:getTag("yinzi_obtaincard"):toBool())
						and _to:getSeat() ~= zoushi:getSeat() and zoushi:isWounded() then
						_to:setTag("yinzi_obtaincard", sgs.QVariant(true))
						room:broadcastSkillInvoke(self:objectName())
						local msg2 = sgs.LogMessage()
						msg2.from = zoushi
						msg2.arg = self:objectName()
						msg2.to:append(_to)
						msg2.type = "#yinziObtain"
						msg2.arg2 = tostring(1)
						room:sendLog(msg2)
						room:recover(zoushi, sgs.RecoverStruct(zoushi, nil, 1))
					end
				end
			end
		end
		return false
	end
}


mo_zoushi:addSkill(sy_yinzi)


--[[
	技能名：魔舞
	相关武将：魔邹氏
	技能描述：当其他角色对你/你对其他角色使用基本牌或非延时锦囊牌后，你可令此牌的使用者和所有目标各摸一张牌，若如此做，此牌额外结算一次。
	引用：sy_mowu
]]--
sy_mowu = sgs.CreateTriggerSkill{
	name = "sy_mowu",
	events = {sgs.TargetConfirmed, sgs.CardFinished},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		for _, zoushi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.TargetConfirmed then
				local use = data:toCardUse()
				if not use.from or not use.card then return false end
				if use.to:isEmpty() then return false end
				if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return false end
				if use.from:objectName() ~= zoushi:objectName() and use.to:contains(zoushi) and not use.card:getTag("mowu_twice"):toBool() then
					use.card:setTag("mowu_twice", sgs.QVariant(true))
				else
					if use.from:objectName() == zoushi:objectName() then
						local contains_others = false
						for _, t in sgs.qlist(use.to) do
							if t:objectName() ~= zoushi:objectName() then
								contains_others = true
								break
							end
						end
						if contains_others and not use.card:getTag("mowu_twice"):toBool() then
							use.card:setTag("mowu_twice", sgs.QVariant(true))
						end
					end
				end
			elseif event == sgs.CardFinished then
				local use = data:toCardUse()
				if use.card and use.card:getTag("mowu_twice"):toBool() then
					for _, t in sgs.qlist(use.to) do
						if t:isDead() then use.to:removeOne(t) end
					end
					if not use.to:isEmpty() and zoushi:askForSkillInvoke(self:objectName(), data) then
						use.card:setTag("mowu_twice", sgs.QVariant(false))
						use.card:removeTag("mowu_twice")
						room:broadcastSkillInvoke(self:objectName())
						local draws = sgs.SPlayerList()
						if not draws:contains(use.from) then draws:append(use.from) end
						for _, t in sgs.qlist(use.to) do
							if not draws:contains(t) then draws:append(t) end
						end
						for _, pe in sgs.qlist(draws) do
							room:doAnimate(1, zoushi:objectName(), pe:objectName())
						end
						for _, pe in sgs.qlist(draws) do
							pe:drawCards(1, self:objectName())
						end
						local msg = sgs.LogMessage()
						msg.from = zoushi
						msg.type = "#mowuTwice"
						msg.card_str = use.card:toString()
						msg.to = use.to
						room:sendLog(msg)
						use.card:use(room, use.from, use.to)
						return false
					end
					use.card:setTag("mowu_twice", sgs.QVariant(false))
					use.card:removeTag("mowu_twice")
				end
			end
		end
		return false
	end
}


mo_zoushi:addSkill(sy_mowu)


sgs.LoadTranslationTable{		
	["mo_zoushi"] = "魔邹氏",
	["#mo_zoushi"] = "妖媚之殃",
	["~mo_zoushi"] = "嗯……真不懂得怜香惜爱……",
	["sy_huoshi"] = "祸世",
	["$sy_huoshi1"] = "男人管不住自己的眼睛，与我何干？",
	["$sy_huoshi2"] = "祸水又如何？难道，你不是心甘情愿吗？",
	[":sy_huoshi"] = "锁定技，当其他角色使用基本牌或非延时锦囊牌指定目标时，你令随机一名不是此牌目标的角色也成为此牌的目标。",
	["#HuoshiExTarget"] = "%from 的“%arg”被触发，令 %to 也成为了 %card 的目标",
	["sy_yinzi"] = "淫恣",
	["$sy_yinzi1"] = "将军与妾身，甚是投缘呐~",
	["$sy_yinzi2"] = "春宵苦短，将军还等什么？",
	[":sy_yinzi"] = "锁定技，每回合每名角色各限一次，当其他角色于回合外获得牌/回复体力后，你回复1点体力（若你已受伤）/摸两张牌。",
	["#yinziRecover"] = "%from 的“%arg”被触发，由于 %to 在其回合外回复了体力，%from 将摸 %arg2 张牌",
	["#yinziObtain"] = "%from 的“%arg”被触发，由于 %to 在其回合外获得了牌，%from 将回复 %arg2 点体力",
	["sy_mowu"] = "魔舞",
	["$sy_mowu1"] = "这一舞的代价，将军愿付出什么呢？",
	["$sy_mowu2"] = "沉溺于此，走向你的末路吧！",
	[":sy_mowu"] = "当其他角色对你/你对其他角色使用基本牌或非延时锦囊牌后，你可令此牌的使用者和所有目标各摸一张牌，若如此做，此牌额外结算一次。",
	["#mowuTwice"] = "%from 令此 %card 对 %to 再额外结算一次",
	["designer:mo_zoushi"] = "极略三国",
	["illustrator:mo_zoushi"] = "极略三国",
	["cv:mo_zoushi"] = "极略三国",
}


--魔孙鲁班
mo_sunluban = sgs.General(extension, "mo_sunluban", "sgk_magic", 4, false)


--[[
	技能名：权倾
	相关武将：魔孙鲁班
	技能描述：出牌阶段每名角色限一次，你可以展示一张本阶段内未以此法展示过的手牌并选择一名其他角色，除非其弃置一张点数大于此牌的牌，否则你令其视为使用目标由你选择
	的任意基本牌或非延时锦囊牌，然后你回复1点体力。
	引用：sy_quanqing
]]--
function getFixedTargets(user, card)
	local tos = sgs.SPlayerList()
	local room = sgs.Sanguosha:currentRoom()
	if (card:isKindOf("ExNihilo") or card:isKindOf("Dongzhuxianji") or card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
		tos:append(user)
	elseif (card:isKindOf("AmazingGrace") or card:isKindOf("GoldSalvation")) then
		tos = room:getAlivePlayers()
	elseif (card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssult")) then
		tos = room:getOtherPlayers(user)
	end
	return tos
end

sy_quanqingCard = sgs.CreateSkillCard{
	name = "sy_quanqingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
		and to_select:getMark("sy_quanqingTarget-PlayClear") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local cid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cid)
		room:addPlayerMark(effect.from, "sy_quanqing"..cid.."-PlayClear")
		room:addPlayerMark(effect.to, "sy_quanqingTarget-PlayClear")
		room:showCard(effect.from, cid)
		local num = card:getNumber()
		local prompt = string.format("@sy_quanqing:%s:%s", effect.from:objectName(), card:getNumberString())
		local to_throw = nil
		local n = sgs.QVariant()
		n:setValue(num)
		if num <= 12 then to_throw = room:askForCard(effect.to, ".|.|" .. tostring(num+1) .. "~" .. "13|.", prompt, n, sgs.Card_MethodNone) end
		if to_throw ~= nil then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, effect.to:objectName(), "sy_quanqing","")
			room:throwCard(to_throw, reason, nil)
		else
			local bnd_warehouse, bnd_cards = {}, sgs.IntList()
			for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
				local cd = sgs.Sanguosha:getEngineCard(id)
				if (cd:isKindOf("BasicCard") or cd:isNDTrick()) and not table.contains(bnd_warehouse, cd:objectName()) and (not cd:isKindOf("Jink")) and (not cd:isKindOf("Suijiyingbian")) and (not cd:isKindOf("Nullification")) then
					table.insert(bnd_warehouse, cd:objectName())
					bnd_cards:append(id)
				end
			end
			room:fillAG(bnd_cards, effect.from)
			local _q = sgs.QVariant()
			_q:setValue(effect.to)
			effect.from:setTag("sy_quanqing_target", _q)
			local use_id = room:askForAG(effect.from, bnd_cards, false, "sy_quanqing", "@quanqing_viewas:"..effect.to:objectName())
			room:clearAG(effect.from)
			local name = sgs.Sanguosha:getEngineCard(use_id):objectName()
			local qq_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
			qq_card:setSkillName("sy_quanqing_USECARD")
			qq_card:deleteLater()
			if qq_card:targetFixed() then
				room:useCard(sgs.CardUseStruct(qq_card, effect.to, getFixedTargets(effect.to, qq_card)))
			else
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if not effect.to:isProhibited(p, qq_card) then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(effect.from, targets, "sy_quanqing", "sy_quanqing-playerchosen:"..name)
					room:setPlayerFlag(effect.to, "sy_quanqingFrom")
					room:setPlayerFlag(target, "sy_quanqingTo")
					room:useCard(sgs.CardUseStruct(qq_card, effect.to, target))
					if effect.to:isAlive() then room:setPlayerFlag(effect.to, "-sy_quanqingFrom") end
					if target:isAlive() then room:setPlayerFlag(target, "-sy_quanqingTo") end
				end
			end
			effect.from:removeTag("sy_quanqing_target")
			if effect.from:isWounded() then
				room:recover(effect.from, sgs.RecoverStruct(effect.from), true)
			end
		end
	end,
}

sy_quanqing = sgs.CreateOneCardViewAsSkill{
	name = "sy_quanqing",
	view_filter = function(self, to_select)
		local id = to_select:getEffectiveId()
		return not to_select:isEquipped() and sgs.Self:getMark("sy_quanqing"..id.."-PlayClear") == 0
	end,
	view_as = function(self, card)
		local showtime = sy_quanqingCard:clone()
		showtime:addSubcard(card:getId())
		showtime:setSkillName(self:objectName())
		return showtime
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}


mo_sunluban:addSkill(sy_quanqing)


--[[
	技能名：扰梦
	相关武将：魔孙鲁班
	技能描述：锁定技，其他角色的判定阶段开始时，若其判定区内没有牌，你令其进行【乐不思蜀】判定。
	引用：sy_raomeng
]]--
sy_raomeng = sgs.CreateTriggerSkill{
	name = "sy_raomeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		for _, mslb in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if mslb:objectName() == player:objectName() then continue end
			room:sendCompulsoryTriggerLog(mslb, self:objectName(), true, true)
			room:doAnimate(1, mslb:objectName(), player:objectName())
			local indulgence = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0)
			local effect = sgs.CardEffectStruct()
			effect.from = nil
			effect.to = player
			effect.card = indulgence
			indulgence:onEffect(effect)
		end
	end,
	can_trigger = function(self, player)
		return player and player:getPhase() == sgs.Player_Judge and player:getJudgingArea():isEmpty()
	end,
}


mo_sunluban:addSkill(sy_raomeng)


--[[
	技能名：永劫
	相关武将：魔孙鲁班
	技能描述：回合结束阶段，你可以选择至少一名对你造成过伤害的其他角色，除非其弃置X张牌（X为其对你造成过伤害的次数），否则你令其减1点体力上限。
	引用：sy_yongjie
]]--
sy_yongjie = sgs.CreateTriggerSkill{
	name = "sy_yongjie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() then
				room:addPlayerMark(damage.from, "sy_yongjie_DamageTimes")
			end
		else
			if player:getPhase() == sgs.Player_Finish then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("sy_yongjie_DamageTimes") > 0 then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					for _, nl in sgs.qlist(targets) do
						room:setPlayerMark(nl, "&yongjie_tome_damagetimes", nl:getMark("sy_yongjie_DamageTimes"))
					end
					if not player:askForSkillInvoke(self:objectName(), data) then
						for _, nl in sgs.qlist(targets) do
							room:setPlayerMark(nl, "&yongjie_tome_damagetimes", 0)
						end
						return false
					end
					local nulis = room:askForPlayersChosen(player, targets, self:objectName(), 1, targets:length(), "@sy_yongjie-playerschosen")
					for _, nl in sgs.qlist(targets) do
						room:setPlayerMark(nl, "&yongjie_tome_damagetimes", 0)
					end
					room:broadcastSkillInvoke(self:objectName())
					for _, nl in sgs.qlist(nulis) do
						room:doAnimate(1, player:objectName(), nl:objectName())
					end
					for _, nl in sgs.qlist(nulis) do
						local n = nl:getMark("sy_yongjie_DamageTimes")
						if nl:getCards("he"):length() < n then
							room:loseMaxHp(nl, 1, self:objectName())
						else
							local prompt = string.format("@sy_yongjie_discard:%s:%s", player:objectName(), n)
							local dis = room:askForDiscard(nl, self:objectName(), n, n, true, true, prompt)
							if not dis then room:loseMaxHp(nl, 1, self:objectName()) end
						end
					end
				end
			end
		end
	end,
}


mo_sunluban:addSkill(sy_yongjie)


sgs.LoadTranslationTable{		
	["mo_sunluban"] = "魔孙鲁班",
	["#mo_sunluban"] = "梦魇",
	["~mo_sunluban"] = "我可是公主！你竟敢？！……",
	["sy_quanqing"] = "权倾",
	["$sy_quanqing1"] = "本公主说你忤逆了，就是忤逆了。",
	["$sy_quanqing2"] = "你可知，与本宫作对的下场？",
	[":sy_quanqing"] = "出牌阶段每名角色限一次，你可以展示一张本阶段内未以此法展示过的手牌并选择一名其他角色，除非其弃置一张点数大于此牌的牌，否则"..
	"你令其视为使用目标由你选择的任意基本牌或非延时锦囊牌，然后你回复1点体力。",
	["@quanqing_viewas"] = "请选择一张牌，令%src视为使用之",
	["@sy_quanqing"] = "请弃置一张点数大于%dest的牌，否则%src将令你视为使用一张基本牌或非延时锦囊牌，且目标由%src选择。",
	["sy_quanqing-playerchosen"] = "【权倾】你令其视为使用一张【<font color='yellow'><b>%src</b></font>】，请选择此牌的目标",
	["sy_raomeng"] = "扰梦",
	["$sy_raomeng1"] = "睡着了，就再也不要醒过来了。",
	["$sy_raomeng2"] = "梦里多好，别再给本宫添乱了。",
	[":sy_raomeng"] = "锁定技，其他角色的判定阶段开始时，若其判定区内没有牌，你令其进行【乐不思蜀】判定。",
	["sy_yongjie"] = "永劫",
	["yongjie_tome_damagetimes"] = "[永劫]伤害次数",
	["$sy_yongjie1"] = "事到如今，求死，可没有那么简单。",
	["$sy_yongjie2"] = "站错了边，等待你的，可是万劫不复。",
	[":sy_yongjie"] = "回合结束阶段，你可以选择至少一名对你造成过伤害的其他角色，除非其弃置X张牌（X为其对你造成过伤害的次数），否则你令其减1点体力上限。",
	["@sy_yongjie_discard"] = "你对%src总共造成了%dest次伤害，你须弃置%dest张牌（包括装备），否则%src令你减1点体力上限。",
	["@sy_yongjie-playerschosen"] = "【永劫】请选择至少一名对你造成过伤害的其他角色",
	["designer:mo_sunluban"] = "极略三国",
	["illustrator:mo_sunluban"] = "极略三国",
	["cv:mo_sunluban"] = "极略三国",
}


--魔孟获
mo_menghuo = sgs.General(extension, "mo_menghuo", "sgk_magic", 4, true)


--[[
	技能名：酋首
	相关武将：魔孟获
	技能描述：锁定技，当你/其他角色使用非延时锦囊指定其他角色/你为目标时，除非对方打出一张【杀】，否则你对其造成1点伤害。
	引用：sy_qiushou
]]--
sy_qiushou = sgs.CreateTriggerSkill{
	name = "sy_qiushou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.from and use.from:isAlive() and use.card and use.card:isNDTrick() then
			if use.from:objectName() == player:objectName() then
				local contains_others = false
				for _, t in sgs.qlist(use.to) do
					if t:objectName() ~= player:objectName() then
						contains_others = true
						break
					end
				end
				if contains_others then
					room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
					for _, t in sgs.qlist(use.to) do
						if t:objectName() ~= player:objectName() then
							local slash = room:askForCard(t, "slash", "@qiushou-slash:"..player:objectName(), data, sgs.Card_MethodResponse, player)
							if not slash then room:damage(sgs.DamageStruct(self:objectName(), player, t, 1)) end
						end
					end
				end
			elseif use.from:objectName() ~= player:objectName() then
				if use.to:contains(player) then
					room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
					local slash = room:askForCard(use.from, "slash", "@qiushou-slash:"..player:objectName(), data, sgs.Card_MethodResponse, player)
					if not slash then room:damage(sgs.DamageStruct(self:objectName(), player, use.from, 1)) end
				end
			end
		end
	end
}


mo_menghuo:addSkill(sy_qiushou)


--[[
	技能名：魔兽
	相关武将：魔孟获
	技能描述：锁定技，准备阶段，你随机获得一项未拥有的效果并移除其他效果，然后摸X张牌（X为你获得当前效果的次数）：
	象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面；
	虎-令其他角色的非锁定技和装备技能于其下个回合结束前无效；
	熊-你防止其他角色施加的除属性伤害以外的负面效果。
	引用：sy_moshou, sy_moshouBuff_elephant, sy_moshouBuff_tiger, sy_moshouBuff_bear
]]--
function activateAllSkills(vic)
	local room = vic:getRoom()
	local Qingchenglist = vic:getTag("Qingcheng"):toString():split("+")
	if #Qingchenglist > 0 then
		for _, name in ipairs(Qingchenglist) do
			room:setPlayerMark(vic, "Qingcheng"..name, 0)
		end
		vic:removeTag("Qingcheng")
		for _, t in sgs.qlist(room:getAllPlayers()) do
			room:filterCards(t, t:getCards("he"), true)
		end
	end
	room:setPlayerMark(vic, "moshou_tiger_invalid", 0)
	room:setPlayerMark(vic, "Armor_Nullified", 0)
	room:setPlayerMark(vic, "Equips_Nullified_to_Yourself", 0)
end

function doMoshouTiger(vic)
	local room = vic:getRoom()
	room:addPlayerMark(vic, "moshou_tiger_invalid")
	local skill_list = {}
	for _, sk in sgs.qlist(vic:getSkillList(true, true)) do
		if not table.contains(skill_list, sk:objectName()) then 
			if sk:getFrequency() ~= sgs.Skill_Compulsory and sk:getFrequency() ~= sgs.Skill_Wake then
				table.insert(skill_list, sk:objectName())
			end
			if sgs.Sanguosha:getViewAsEquipSkill(sk:objectName()) then
				table.insert(skill_list, sk:objectName())
			end
		end
	end
	if not vic:getEquips():isEmpty() then
		for _, eq in sgs.qlist(vic:getEquips()) do
			if vic:hasEquipSkill(eq:objectName()) then
				table.insert(skill_list, eq:objectName())
			end
		end
	end
	room:addPlayerMark(vic, "Armor_Nullified")
	room:addPlayerMark(vic, "Equips_Nullified_to_Yourself")
	if #skill_list > 0 then
		vic:setTag("Qingcheng", sgs.QVariant(table.concat(skill_list, "+")))
		for _, skill_qc in ipairs(skill_list) do
			room:addPlayerMark(vic, "Qingcheng"..skill_qc)
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:filterCards(p, p:getCards("he"), true)
			end
		end
	end
end

sy_moshou = sgs.CreateTriggerSkill{
	name = "sy_moshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start then return false end
		local beasts = {"sy_moshou_elephant", "sy_moshou_tiger", "sy_moshou_bear"}
		local current_beast = -1
		if player:getTag("sy_moshou_beast"):toString():startsWith("sy_moshou_") then
			current_beast = player:getTag("sy_moshou_beast"):toString()
		end
		if current_beast ~= -1 then
			table.removeOne(beasts, current_beast)
			room:setPlayerMark(player, "&"..current_beast.."_Current", 0)
			if current_beast == "sy_moshou_tiger" then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					activateAllSkills(p)
					room:setPlayerMark(p, "moshou_tiger_invalid", 0)
				end
			end
		end
		local beast = beasts[math.random(1, #beasts)]
		player:setTag("sy_moshou_beast", sgs.QVariant(beast))
		room:addPlayerMark(player, beast)
		if beast == "sy_moshou_elephant" then
			room:broadcastSkillInvoke(self:objectName(), 1)
		elseif beast == "sy_moshou_tiger" then
			room:broadcastSkillInvoke(self:objectName(), 2)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				doMoshouTiger(p)
			end
		elseif beast == "sy_moshou_bear" then
			room:broadcastSkillInvoke(self:objectName(), 3)
		end
		local msg = sgs.LogMessage()
		msg.from = player
		msg.arg = self:objectName()
		msg.type = "#MoshouBeastBuff"
		msg.arg2 = beast
		room:sendLog(msg)
		player:setSkillDescriptionSwap("sy_moshou", "%beast", beast)
		room:changeTranslation(player, "sy_moshou")
		room:setPlayerMark(player, "&"..beast.."_Current", player:getMark(beast))
		player:drawCards(player:getMark(beast), self:objectName())
	end
}

sy_moshouBuff_elephant = sgs.CreateTriggerSkill{
	name = "#sy_moshouBuff_elephant",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_elephant" then
			if damage.damage > 0 and damage.to:objectName() ~= player:objectName() and damage.to:isAlive() then
				room:broadcastSkillInvoke("sy_moshou", 1)
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#MoshouElephantBuff"
				msg.to:append(damage.to)
				msg.arg = "sy_moshou"
				room:sendLog(msg)
				throwRandomCards(true, player, damage.to, 1, "he", "sy_moshou")
				damage.to:turnOver()
			end
		end
	end
}

sy_moshouBuff_tiger = sgs.CreateTriggerSkill{
	name = "#sy_moshouBuff_tiger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish and player:getMark("moshou_tiger_invalid") > 0 then
			room:setPlayerMark(player, "moshou_tiger_invalid", 0)
			activateAllSkills(player)
		end
	end
}

sy_moshouBuff_bear = sgs.CreateTriggerSkill{
	name = "#sy_moshouBuff_bear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.PreHpLost, sgs.MaxHpChange, sgs.BeforeCardsMove, sgs.MarkChange, sgs.ChainStateChange, sgs.TurnOver, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventDamage"
					msg.arg2 = tostring(damage.damage)
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.PreHpLost then
			local lose = data:toHpLost()
			if lose.from and lose.from:objectName() ~= player:objectName() then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventLoseHp"
					msg.arg2 = tostring(lose.lose)
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.MaxHpChange then
			local change = data:toMaxHp()
			if change.change < 0 then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventLoseMaxhp"
					msg.arg2 = tostring(math.abs(change.change))
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local x = move.card_ids:length()
			if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand)
				or move.from_places:contains(sgs.Player_PlaceEquip)) and not move.from_places:contains(sgs.Player_PlaceDelayedTrick) and 
				bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and x > 0 then
				if (move.reason.m_playerId and move.reason.m_playerId ~= player:objectName()) or player:getPhase() == sgs.Player_NotActive then
					if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
						local msg = sgs.LogMessage()
						msg.from = player
						msg.arg = "sy_moshou"
						msg.type = "#MoshouBearPreventDiscard"
						room:sendLog(msg)
						move.card_ids = sgs.IntList()
						data:setValue(move)
					end
				end
			end
		elseif event == sgs.MarkChange then
			local mark = data:toMark()
			if player:getTag("hunlie_global_resist_invalid"):toBool() then return true end
			if mark.gain > 0 and (string.find(mark.name, "Qingcheng") or string.find(mark.name, "skill_invalidity") or string.find(mark.name, "fangzhu")) then
				if not player:getTag("hunlie_global_resist_invalid"):toBool() then
					if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
						local msg = sgs.LogMessage()
						msg.from = player
						msg.arg = "sy_moshou"
						msg.type = "#MoshouBearPreventInvalidity"
						room:sendLog(msg)
						return true
					end
				end
			end
		elseif event == sgs.ChainStateChange then
			if not player:isChained() then
				if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
					local msg = sgs.LogMessage()
					msg.from = player
					msg.arg = "sy_moshou"
					msg.type = "#MoshouBearPreventChain"
					room:sendLog(msg)
					return true
				end
			end
		elseif event == sgs.TurnOver then
			if player:faceUp() and player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = "sy_moshou"
				msg.type = "#MoshouBearPreventTurnOver"
				room:sendLog(msg)
				return true
			end
		elseif event == sgs.EventLoseSkill then
			if player:getTag("sy_moshou_beast"):toString() == "sy_moshou_bear" then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = "sy_moshou"
				msg.type = "#MoshouBearPreventLoseSkill"
				msg.arg2 = data:toString()
				room:sendLog(msg)
				player:setTag("hunliesp_global_resistSkill", sgs.QVariant(true))
				room:addPlayerMark(player, data:toString().."_temp_skill")
				room:handleAcquireDetachSkills(player, data:toString())
				room:setPlayerMark(player, data:toString().."_temp_skill", 0)
			end
		end
		return false
	end
}


mo_menghuo:addSkill(sy_moshou)
mo_menghuo:addSkill(sy_moshouBuff_elephant)
mo_menghuo:addSkill(sy_moshouBuff_tiger)
mo_menghuo:addSkill(sy_moshouBuff_bear)
extension:insertRelatedSkills("sy_moshou", "#sy_moshouBuff_elephant")
extension:insertRelatedSkills("sy_moshou", "#sy_moshouBuff_tiger")
extension:insertRelatedSkills("sy_moshou", "#sy_moshouBuff_bear")


sgs.LoadTranslationTable{		
	["mo_menghuo"] = "魔孟获",
	["#mo_menghuo"] = "南中魔兽",
	["~mo_menghuo"] = "他是何人！",
	["sy_qiushou"] = "酋首",
	["$sy_qiushou1"] = "南中之首，岂可向蜀汉称臣！",
	["$sy_qiushou2"] = "一介书生，敢染指我的地界！",
	[":sy_qiushou"] = "锁定技，当你/其他角色使用非延时锦囊指定其他角色/你为目标时，除非对方打出一张【杀】，否则你对其造成1点伤害。",
	["@qiushou-slash"] = "%src的【酋首】被触发，请打出一张【杀】，否则%src对你造成1点伤害",
	["sy_moshou"] = "魔兽",
	["$sy_moshou1"] = "巨象之力，踏平敌阵！",
	["$sy_moshou2"] = "猛虎之威，百兽颤栗！",
	["$sy_moshou3"] = "战熊之躯，刀枪不入！",
	["sy_moshou_elephant"] = "象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面。",
	["sy_moshou_tiger"] = "虎-令其他角色的非锁定技和装备技能于其下个回合结束前无效。",
	["sy_moshou_bear"] = "熊-你防止其他角色施加的除属性伤害以外的负面效果。",
	["sy_moshou_elephant_Current"] = "魔兽-象",
	["sy_moshou_tiger_Current"] = "魔兽-虎",
	["sy_moshou_bear_Current"] = "魔兽-熊",
	[":sy_moshou"] = "锁定技，准备阶段，你随机获得一项未拥有的效果并移除其他效果，然后摸X张牌（X为你获得当前效果的次数）：\
	象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面；\
	虎-令其他角色的非锁定技和装备技能于其下个回合结束前无效；\
	熊-你防止其他角色施加的除属性伤害以外的负面效果。",
	[":sy_moshou1"] = "锁定技，准备阶段，你随机获得一项未拥有的效果并移除其他效果，然后摸X张牌（X为你获得当前效果的次数）：\
	象-当你对其他角色造成伤害后，你令其随机弃置一张牌并翻面；\
	虎-令其他角色的非锁定技和装备技能于其下个回合结束前无效；\
	熊-你防止其他角色施加的除属性伤害以外的负面效果。\
	当前“魔兽”生效效果：<font color=\"#FF4500\">%beast</font>",
	["#MoshouBeastBuff"] = "%from 的“%arg”被触发，本轮的“%arg”生效的效果是：%arg2",
	["#MoshouElephantBuff"] = "%from 的“%arg”被触发，%to 受到伤害后将被随机弃置一张牌并翻面",
	["#MoshouBearPreventDamage"] = "%from 的“%arg”被触发，防止了 %arg2 点伤害",
	["#MoshouBearPreventLoseHp"] = "%from 的“%arg”被触发，防止失去了 %arg2 点体力",
	["#MoshouBearPreventLoseMaxhp"] = "%from 的“%arg”被触发，防止失去了 %arg2 点体力上限",
	["#MoshouBearPreventDiscard"] = "%from 的“%arg”被触发，弃置牌的效果被无效",
	["#MoshouBearPreventTurnOver"] = "%from 的“%arg”被触发，翻面的效果被无效",
	["#MoshouBearPreventLoseSkill"] = "%from 的“%arg”被触发，失去技能“%arg2”的效果被无效",
	["#MoshouBearPreventInvalidity"] = "%from 的“%arg”被触发，其技能无效的效果被无效",
	["#MoshouBearPreventChain"] = "%from 的“%arg”被触发，其被横置的骁果被无效",
	["designer:mo_menghuo"] = "极略三国",
	["illustrator:mo_menghuo"] = "极略三国",
	["cv:mo_menghuo"] = "极略三国",
}


--魔张春华
mo_zhangchunhua = sgs.General(extension, "mo_zhangchunhua", "sgk_magic", 4, false)


--[[
	技能名：凋零
	相关武将：魔张春华
	技能描述：每回合限一次，当其他角色于弃牌阶段外弃置牌时，你可以改为令其失去等量的体力。
	引用：sy_diaoling
]]--
sy_diaoling = sgs.CreateTriggerSkill{
	name = "sy_diaoling",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			local _from
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == move.from:objectName() then
					_from = p
					break
				end
			end
			local x = move.card_ids:length()
			if player:hasSkill(self:objectName()) and player:getMark(self:objectName().."-Clear") == 0 and _from:getPhase() ~= sgs.Player_Discard and player:objectName() ~= _from:objectName() then
				local prompt = string.format("diaoling_discard:%s:%s", _from:objectName(), tostring(x))
				local _q1, _q2 = sgs.QVariant(), sgs.QVariant()
				_q1:setValue(_from)
				_q2:setValue(move)
				player:setTag("sy_diaoling_target", _q1)
				player:setTag("sy_diaoling_move", _q2)
				if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
					room:addPlayerMark(player, self:objectName().."-Clear")
					room:broadcastSkillInvoke(self:objectName())
					move.card_ids = sgs.IntList()
					data:setValue(move)
					room:loseHp(_from, x, true, player, self:objectName())
				end
				player:removeTag("sy_diaoling_target")
				player:removeTag("sy_diaoling_move")
			end
		end
	end
}


mo_zhangchunhua:addSkill(sy_diaoling)


--[[
	技能名：扼绝
	相关武将：魔张春华
	技能描述：出牌阶段限一次，或当你受到伤害后，你可以摸两张牌并弃置其中一张，然后令所有其他角色弃置点数小于此牌的所有同类型的牌，然后你从弃牌堆中随机获得每名角色以此法弃置的各一张牌。
	引用：sy_ejue
]]--
sy_ejueCard = sgs.CreateSkillCard{
	name = "sy_ejueCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern():startsWith("@@sy_ejue") then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), "sy_ejue","")
			room:throwCard(self, reason, nil)
			for _, p in sgs.qlist(room:getPlayers()) do
				for _, c in sgs.qlist(p:getCards("hej")) do
					if c:hasFlag("sy_ejue_draw") then room:setCardFlag(c, "-sy_ejue_draw") end
				end
			end
			local acard = sgs.Sanguosha:getCard(self:getSubcards():first())
			local ctype, number = acard:getTypeId(), acard:getNumber()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				room:doAnimate(1, source:objectName(), p:objectName())
			end
			local dummy1 = sgs.Sanguosha:cloneCard("slash")
			dummy1:deleteLater()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				local dummy2 = sgs.Sanguosha:cloneCard("jink")
				dummy2:deleteLater()
				for _, c in sgs.qlist(p:getCards("he")) do
					if c:getTypeId() == ctype and c:getNumber() < number then
						dummy2:addSubcard(c)
					end
				end
				if dummy2:subcardsLength() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, p:objectName(), nil, "sy_ejue", nil)
					room:throwCard(dummy2, reason, p, source)
					local to_gain = {}
					for _, id in sgs.qlist(dummy2:getSubcards()) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then table.insert(to_gain, id) end
					end
					if #to_gain > 0 then dummy1:addSubcard(to_gain[math.random(1, #to_gain)]) end
				end
			end
			if dummy1:subcardsLength() > 0 then source:obtainCard(dummy1) end
		else
			room:broadcastSkillInvoke("sy_ejue")
			source:drawCards(2, "sy_ejue")
			local can_ejue = false
			for _, c in sgs.qlist(source:getCards("h")) do
				if c:hasFlag("sy_ejue_draw") then
					can_ejue = true
					break
				end
			end
			if can_ejue then
				room:askForUseCard(source, "@@sy_ejue!", "@sy_ejue")
				for _, p in sgs.qlist(room:getPlayers()) do
					for _, c in sgs.qlist(p:getCards("hej")) do
						if c:hasFlag("sy_ejue_draw") then room:setCardFlag(c, "-sy_ejue_draw") end
					end
				end
			end
		end
	end
}

sy_ejueVS = sgs.CreateViewAsSkill{
	name = "sy_ejue",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern():startsWith("@@sy_ejue") then
			if #selected >= 1 then return false end
			return (not sgs.Self:isJilei(to_select)) and to_select:hasFlag("sy_ejue_draw")
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern():startsWith("@@sy_ejue") then
			if #cards == 0 then return false end
			local c = sy_ejueCard:clone()
			for _, card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		else
			if #cards ~= 0 then return nil end
			return sy_ejueCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sy_ejueCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@sy_ejue")
	end
}

sy_ejue = sgs.CreateTriggerSkill{
	name = "sy_ejue",
	view_as_skill = sy_ejueVS,
	events = {sgs.AfterDrawNCards, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason == self:objectName() and draw.who:objectName() == player:objectName() then
				if draw.card_ids:length() > 0 then
					for _, id in sgs.qlist(draw.card_ids) do
						if room:getCardPlace(id) == sgs.Player_PlaceHand then room:setCardFlag(sgs.Sanguosha:getCard(id), "sy_ejue_draw") end
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
				local can_ejue = false
				for _, c in sgs.qlist(player:getCards("h")) do
					if c:hasFlag("sy_ejue_draw") then
						can_ejue = true
						break
					end
				end
				if can_ejue then
					room:askForUseCard(player, "@@sy_ejue!", "@sy_ejue")
					for _, p in sgs.qlist(room:getPlayers()) do
						for _, c in sgs.qlist(p:getCards("hej")) do
							if c:hasFlag("sy_ejue_draw") then room:setCardFlag(c, "-sy_ejue_draw") end
						end
					end
				end
			end
		end
	end
}


mo_zhangchunhua:addSkill(sy_ejue)


--[[
	技能名：翦灭
	相关武将：魔张春华
	技能描述：锁定技，你对手牌数少于你的角色使用的【杀】视为【火杀】且不计入次数限制，这些角色于你的回合内跳过濒死状态。
	引用：sy_jianmie
]]--
sy_jianmie = sgs.CreateTriggerSkill{
	name = "sy_jianmie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ChangeSlash, sgs.EnterDying},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.ChangeSlash then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName() and player:hasSkill(self) then
				local will_change = false
				for _, t in sgs.qlist(use.to) do
					if t:getHandcardNum() < player:getHandcardNum() then
						will_change = true
						break
					end
				end
				if will_change then
					room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
					if not use.card:isKindOf("FireSlash") then
						local jianmie_fire = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
						jianmie_fire:addSubcard(use.card:getEffectiveId())
						jianmie_fire:setSkillName("_sy_jianmie")
						jianmie_fire:deleteLater()
						use.changeCard(use, jianmie_fire)
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.EnterDying then
			local dying = data:toDying()
			local current = room:getCurrent()
			if current and current:hasFlag("CurrentPlayer") and current:hasSkill(self) then
				if dying.who:getSeat() ~= current:getSeat() and current:getHandcardNum() > dying.who:getHandcardNum() then
					local msg = sgs.LogMessage()
					msg.from = current
					msg.type = "#JianmieDie"
					msg.to:append(dying.who)
					msg.arg = self:objectName()
					room:sendLog(msg)
					room:broadcastSkillInvoke(self:objectName())
					if dying.damage then room:killPlayer(dying.who, dying.damage) else room:killPlayer(dying.who) end
				end
			end
		end
		return false
	end
}


mo_zhangchunhua:addSkill(sy_jianmie)


sgs.LoadTranslationTable{
	["mo_zhangchunhua"] = "魔张春华",
	["#mo_zhangchunhua"] = "万魂归寂",
	["~mo_zhangchunhua"] = "血色尽染，终归绝情……",
	["sy_diaoling"] = "凋零",
	["$sy_diaoling1"] = "芳华散尽，万物同朽。",
	["$sy_diaoling2"] = "命若游丝，何苦挣扎？",
	[":sy_diaoling"] = "每回合限一次，当其他角色于弃牌阶段外弃置牌时，你可以改为令其失去等量的体力。",
	["sy_diaoling:diaoling_discard"] = "%src即将弃置%dest张牌，是否对%src发动“凋零”？（若如此做，%src本次将不再弃置%dest张牌，而是改为失去%dest点体力）",
	["sy_ejue"] = "扼绝",
	["$sy_ejue1"] = "生机已了，黄泉路近！",
	["$sy_ejue2"] = "三魂七魄，尽入我彀！",
	[":sy_ejue"] = "出牌阶段限一次，或当你受到伤害后，你可以摸两张牌并弃置其中一张，然后令所有其他角色弃置点数小于此牌的所有同类型的牌，然后你从弃牌堆中"..
	"随机获得每名角色以此法弃置的各一张牌。",
	["@sy_ejue"] = "请选择一张牌并弃置，若如此做，所有其他角色将弃置点数小于此牌的所有同类型的牌",
	["sy_jianmie"] = "翦灭",
	["$sy_jianmie1"] = "幽冥业火，焚尽痴妄！",
	["$sy_jianmie2"] = "九州烬冷，万象归无！",
	[":sy_jianmie"] = "锁定技，你对手牌数少于你的角色使用的【杀】视为【火杀】且不计入次数限制，这些角色于你的回合内跳过濒死状态。",
	["#JianmieDie"] = "%from 的“%arg”被触发，由于 %to 的手牌数少于 %from 的手牌数，%to 将直接死亡",
	["designer:mo_zhangchunhua"] = "极略三国",
	["illustrator:mo_zhangchunhua"] = "极略三国",
	["cv:mo_zhangchunhua"] = "极略三国",
}

fcmk_jlsg_modiaochan = sgs.General(extension, "fcmk_jlsg_modiaochan", "sgk_magic", 3, false)

fcmk_jlsg_meihuoCard = sgs.CreateSkillCard{
	name = "fcmk_jlsg_meihuoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:isMale()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:obtainCard(effect.to, self, false)
		local targets, others = sgs.SPlayerList(), room:getOtherPlayers(effect.to)
		if effect.from:getState() == "online" then
			targets = room:askForPlayersChosen(effect.from, others, "fcmk_jlsg_meihuo", 1, others:length(), "fcmk_jlsg_meihuo-playerschosen")
		else
			local target = room:askForPlayerChosen(effect.from, others, "fcmk_jlsg_meihuo")
			targets:append(target)
			others:removeOne(target)
			while not others:isEmpty() do
				local target = room:askForPlayerChosen(effect.from, others, "fcmk_jlsg_meihuo", "", true, true)
				if not target then break end
				targets:append(target)
				others:removeOne(target)
			end
		end
		if not effect.to:hasFlag("fcmk_jlsg_meihuoATKfrom") then
			room:setPlayerFlag(effect.to, "fcmk_jlsg_meihuoATKfrom")
		end
		for _, p in sgs.qlist(targets) do
			if not p:hasFlag("fcmk_jlsg_meihuoATKto") then
				room:setPlayerFlag(p, "fcmk_jlsg_meihuoATKto")
			end
		end
		while not effect.to:isKongcheng() do
			local asn = {}
			for _, cd in sgs.qlist(effect.to:getHandcards()) do
				if cd:isKindOf("Slash") or (cd:isNDTrick() and not cd:isKindOf("Collateral") and not cd:isKindOf("Nullification")) then
					table.insert(asn, cd)
				end
			end
			if #asn == 0 then break end
			local atk_card = asn[math.random(1, #asn)]
			room:useCard(sgs.CardUseStruct(atk_card, effect.to, targets))
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("fcmk_jlsg_meihuoATKfrom") then
				room:setPlayerFlag(p, "-fcmk_jlsg_meihuoATKfrom")
			end
			if p:hasFlag("fcmk_jlsg_meihuoATKto") then
				room:setPlayerFlag(p, "-fcmk_jlsg_meihuoATKto")
			end
		end
	end,
}
fcmk_jlsg_meihuoVS = sgs.CreateViewAsSkill{
	name = "fcmk_jlsg_meihuo",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards >= 1 then
			local mh_card = fcmk_jlsg_meihuoCard:clone()
			for _, c in ipairs(cards) do
				mh_card:addSubcard(c)
			end
			return mh_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fcmk_jlsg_meihuoCard") and not player:isKongcheng()
	end,
}
fcmk_jlsg_meihuo = sgs.CreateTriggerSkill{ --手动筛除多余目标（专为AOE和全体增益锦囊准备）
	name = "fcmk_jlsg_meihuo",
	events = {sgs.PreCardUsed},
	view_as_skill = fcmk_jlsg_meihuoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.from:objectName() == player:objectName() and use.card and (use.card:isKindOf("Slash")
		or (use.card:isNDTrick() and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification"))) then
			local useto = sgs.SPlayerList()
			for _, p in sgs.qlist(use.to) do
				if p:hasFlag("fcmk_jlsg_meihuoATKto") then
					useto:append(p)
				end
			end
			use.to = useto
			data:setValue(use)
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasFlag("fcmk_jlsg_meihuoATKfrom")
	end,
}
fcmk_jlsg_modiaochan:addSkill(fcmk_jlsg_meihuo)

fcmk_jlsg_yaoyan = sgs.CreateTriggerSkill{
	name = "fcmk_jlsg_yaoyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player)
		and use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and not use.card:isKindOf("Collateral") then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			use.to:append(use.from)
			data:setValue(use)
		end
	end,
}
fcmk_jlsg_modiaochan:addSkill(fcmk_jlsg_yaoyan)

fcmk_jlsg_miluan = sgs.CreateTriggerSkill{
	name = "fcmk_jlsg_miluan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName()
		and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isKongcheng() then continue end
				dummy:addSubcards(p:getHandcards())
				room:obtainCard(player, dummy, false)
				dummy:clearSubcards()
			end
			dummy:deleteLater()
			local n
			local n1 = player:getHandcardNum() / 2
			local n2 = player:getHandcardNum() - n1
			if n1 <= n2 then n = n1
			else n = n2 end
			--local dummi = sgs.Sanguosha:cloneCard("jink")
			while n > 0 do
				local give_ids = {}
				for _, id in sgs.qlist(player:handCards()) do
					table.insert(give_ids, id)
				end
				--local g = math.random(1, n) --实测太夸张了，很容易一边倒，上限必须控
				--[[local gg = g
				while g > 0 do]]
					local give_id = give_ids[math.random(1, #give_ids)]
					--[[dummi:addSubcard(give_id)
					table.removeOne(give_ids, give_id)
					g = g - 1
				end]]
				local people = {}
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					table.insert(people, p)
				end
				local person = people[math.random(1, #people)]
				--[[room:obtainCard(person, dummi, false)
				dummi:clearSubcards()
				n = n - gg]]
				local give_card = sgs.Sanguosha:getCard(give_id)
				room:obtainCard(person, give_card, false)
				n = n - 1
			end
			--dummi:deleteLater()
		end
	end,
}
fcmk_jlsg_modiaochan:addSkill(fcmk_jlsg_miluan)
sgs.LoadTranslationTable{
    --魔貂蝉
	["fcmk_jlsg_modiaochan"] = "魔貂蝉[极略三国]",
	["&fcmk_jlsg_modiaochan"] = "魔貂蝉",
	["#fcmk_jlsg_modiaochan"] = "狐妖的诱惑",
	["designer:fcmk_jlsg_modiaochan"] = "[极略三国-三英挑战兑换]",
	["cv:fcmk_jlsg_modiaochan"] = "极略三国",
	["illustrator:fcmk_jlsg_modiaochan"] = "极略三国",
	  --魅惑
	["fcmk_jlsg_meihuo"] = "魅惑",
	[":fcmk_jlsg_meihuo"] = "出牌阶段限一次，你可以将至少一张手牌交给一名男性角色，然后选择至少一名除该角色外的角色，若如此做，此男性角色以这些角色为目标随机使用当前手牌中的" ..
	"【杀】和普通锦囊牌（【借刀杀人】、【无懈可击】除外）。",
	["fcmk_jlsg_meihuo-playerschosen"] = "[魅惑]请选择至少一名除该角色外的角色，令该角色“攻击”你选择的这些角色",
	--["fcmk_jlsg_mhbe"] = "被魅了",
	["$fcmk_jlsg_meihuo1"] = "只有赢家，才能与妾身...共度良宵哦~",
	["$fcmk_jlsg_meihuo2"] = "将军，妾身可是受委屈了~",
	  --妖颜
	["fcmk_jlsg_yaoyan"] = "妖颜",
	[":fcmk_jlsg_yaoyan"] = "<font color='red'><s>变身技，</s></font>锁定技，当其他角色使用基本牌或普通锦囊牌指定你为目标时（【借刀杀人】除外），你令其也成为此牌的目标。",
	["$fcmk_jlsg_yaoyan1"] = "狐妖之魄，蚀骨销魂。",
	["$fcmk_jlsg_yaoyan2"] = "看着我的眼睛，可不要眨眼哦~",
	  --迷乱
	["fcmk_jlsg_miluan"] = "迷乱",
	[":fcmk_jlsg_miluan"] = "<font color='red'><s>变身技，</s></font>当你受到伤害后，你可以获得所有其他角色的手牌，然后将一半数量（向下取整）的手牌随机分配给其他角色" ..
	"<font color='red'><b>(注:为避免给牌“一边倒”,每次给一张)</b></font>。",
	["$fcmk_jlsg_miluan1"] = "是虚情假意，还是逢场作戏呢？",
	["$fcmk_jlsg_miluan2"] = "哼~男人的嘴，妾身可不会轻易相信~",
	  --☠️阵亡
	["~fcmk_jlsg_modiaochan"] = "修罗夜叉，共坠轮回！......",
	
}





return {extension}