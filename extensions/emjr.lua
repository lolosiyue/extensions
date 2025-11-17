--[[
E鸣惊人扩展包 v1.0
制作：天气真好(QQ:114534941)
首发：天气真好的三国杀主页（http://gltjk.com/sgs）
鸣谢：Paracel_007、女王受·虫
版权：马峰窝工作室（http://www.mafengwoo.com）
技能来源：Excel杀E鸣惊人武将DIY大赛
适用版本：太阳神三国杀V2版0610（http://tieba.baidu.com/p/2384878594）
使用方法：将所有文件解压缩到QSanguosha-0610目录里即可。
更新记录：
	20131110 根据最新修改的牌面更改【危城】【护武】【持内】【急思】【傲才】，增加【强辩】，张皇后改名张星彩
	20131020 更新【危城】描述和结算
	20130627 修复数个bug，调整描述。
	20130626 修复陆抗【堰守】少摸一张牌的问题
	20130625 紧急修复刘璋【图守】不能正常防止伤害的bug
	20130625 补全所有配音，坑爹程昱独立成补丁
	20130623 增加触发技的技能配音代码（虽然配音还没全）
	20130621 诸葛恪和刘璋的台词补全，增加【傲才】发动时的全屏信息
	20130618 陆抗和诸葛恪制作完毕
	20130617 周仓和张皇后制作完毕，修复刘璋的一处bug
	20130616 王允和刘璋制作完毕
	20130614 李典制作完毕，附赠坑爹程昱
	20130613 程昱制作完毕
常见问题：
	Q: AI李典为啥会乱发动【郄縠】？
	A: 貌似0610的AI碰到了askForCard就不出牌不舒服斯基……等李典的AI写好了应该没问题吧。
	
	Q: 关羽发动【武圣】将【桃】当【杀】对曹操和1体力的A使用，曹操受到伤害后发动【奸雄】获得【桃】，再对濒死的A使用，【杀】结算后周仓仍能拿到弃牌堆里的【桃】……
	A: 因神杀架构不同，周仓发动【护武】的时机比牌置入弃牌堆后更晚，目前仅通过判断弃牌堆里是否有相应的牌决定是否发动。在BeforeCardsMove时机加标记或许可行？反正我没试出来= =
	
	Q：角色在其出牌阶段非空闲时间点使用红【杀】，也能发动【护武】？
	A：暂时没想出消灭这个bug的方法。
	
	Q: 诸葛恪【强辩】怎么不会触发？
	A: 我不知道怎么写……貌似找不到合适的时机= = 等我问para吧。
	
	Q: 诸葛恪在武将一览界面里无法显示【专权】的台词（同时保证左边的技能描述里不出现单独的专权）。
	A: 据传LUA法无解，等我问para吧。
	
	Q: 诸葛恪和刘璋的技能肿么这么眼熟……如虎添翼包？！
	A: （表面回答）这两个武将都是从E鸣惊人武将比赛投稿里选出来的，并未找到侵权的证据，也尚未有人来宣称版权，因而判断投稿有效。
	A：（真实回答）看看他们的技能设计是谁吧……你懂的……
	
	Q: 插画坑爹，配音生硬，有些台词的播放没按照技能的具体情况来……
	A: 插画临时找的，配音合成的，我一个人多辛苦啊……大家帮忙吧！之所以有些配音放乱了是因为视为技的特定配音没法用lua实现……
	
	Q: 这个lua包里怎么还有lua目录，里面竟然有神杀自带的文件sgs_ex.lua，不会是破坏神杀的吧？
	A: 因为0610里那个文件略有问题，第157行“card.”被错写成了“card_”，导致【急思】实现不了……现在改过来了，没动其他地方。
	
	Q: 为啥有不懂的问题都去问para……
	A: 因为他是神将啊……就是这样，喵~
	
本人为神杀LUA初学者，欢迎交流探讨！
程序有很多冗余代码（以及各种bug），希望大家一起优化！
]]
--

module("extensions.emjr", package.seeall)
extension = sgs.Package("emjr")

--程昱
echengyu = sgs.General(extension, "echengyu", "wei", "3")
--程昱【伏杀】
--出牌阶段限一次，你可以将一张手牌背面朝上移出游戏并选择一名其他角色，
--若如此做，该角色的回合开始时，其选择一种花色后将此牌置入弃牌堆，
--若此牌的花色与其所选的不同，你视为对其使用一张【杀】。
efushaCard = sgs.CreateSkillCard {
	name = "efusha",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local efushalist = to_select:getPile("efusha")
			if efushalist:isEmpty() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local cards = self:getSubcards()
		for _, id in sgs.qlist(cards) do
			local keystr = string.format("EFushaSource%d", id)
			local tag = sgs.QVariant()
			tag:setValue(source)
			room:setTag(keystr, tag)
			target:addToPile("efusha", id, false)
		end
	end
}
efushaVS = sgs.CreateViewAsSkill {
	name = "efusha",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local acard = efushaCard:clone()
			for _, card in pairs(cards) do
				acard:addSubcard(card)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#efusha")
	end
}
efusha = sgs.CreateTriggerSkill {
	name = "efusha",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = efushaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			local efusha_list = player:getPile("efusha")
			if efusha_list:length() > 0 then
				if player:getGeneralName() == "yuanshao" then
					room:broadcastSkillInvoke(self:objectName(), 3)
				else
					room:broadcastSkillInvoke(self:objectName(), 2)
				end
				while not efusha_list:isEmpty() do
					local card_id = efusha_list:first()
					local keystr = string.format("EFushaSource%d", card_id)
					local tag = room:getTag(keystr)
					local chengyu = tag:toPlayer()
					local cd = sgs.Sanguosha:getCard(card_id)
					local suit = room:askForSuit(player, self:objectName())
					local suit_str = { "spade", "club", "heart", "diamond" }
					local log = sgs.LogMessage()
					log.type = "#efusha"
					log.from = player
					log.arg = self:objectName()
					log.arg2 = suit_str[suit + 1]
					room:sendLog(log)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(),
						"")
					room:throwCard(cd, reason, nil)
					if cd:getSuit() ~= suit then
						if chengyu:canSlash(player, nil, false) then
							local room = player:getRoom()
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:setSkillName("_efusha")
							local card_use = sgs.CardUseStruct()
							card_use.from = chengyu
							card_use.to:append(player)
							card_use.card = slash
							room:useCard(card_use, false)
							slash:deleteLater()
						end
					end
					efusha_list:removeOne(card_id)
					room:removeTag(keystr)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--程昱【危城】
--每当你成为其他角色使用的【杀】或非延时类锦囊牌的目标后，若你有手牌，
--你可以依次弃置该角色的X张牌（X为你已损失的体力值且至少为1）。
eweichengDummyCard = sgs.CreateSkillCard {
	name = "eweichengDummyCard"
}
eweicheng = sgs.CreateTriggerSkill {
	name = "eweicheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if card:isKindOf("Slash") or card:isNDTrick() then
			for _, chengyu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local source = use.from
				if source and source:objectName() ~= chengyu:objectName() then
					local targets = use.to
					if targets and targets:contains(chengyu) and not chengyu:isKongcheng() then
						if chengyu:canDiscard(source, "he") then
							local dest = sgs.QVariant()
							dest:setValue(source)
							if chengyu:askForSkillInvoke(self:objectName(), dest) then
								if source:getGeneralName() == "yuanshao" then
									room:broadcastSkillInvoke(self:objectName(), 2)
								else
									room:broadcastSkillInvoke(self:objectName(), 1)
								end
								local losthp = math.max(chengyu:getLostHp(), 1)
								local count = 0
								while (count < losthp and chengyu:canDiscard(source, "he")) do
									local to_throw = room:askForCardChosen(chengyu, source, "he", self:objectName(), false, sgs.Card_MethodDiscard)
									local card = sgs.Sanguosha:getCard(to_throw)
									room:throwCard(card, source, chengyu);
									count = count + 1
								end
							end
						end
					end
				end
			end
		end
	end
}
echengyu:addSkill(efusha)
echengyu:addSkill(eweicheng)

--李典
elidian = sgs.General(extension, "elidian", "wei", "4")
--李典【郄縠】
--其他角色的摸牌阶段结束后，你可以弃置一张基本牌，令该角色摸两张牌；
--其他角色的弃牌阶段结束后，你可以弃置一张非基本牌，令该角色弃置两张牌。
eqiehu = sgs.CreateTriggerSkill {
	name = "eqiehu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		if not player:isDead() then
			local room = player:getRoom()
			local lidians = room:findPlayersBySkillName(self:objectName())
			for _, lidian in sgs.qlist(lidians) do
				if not lidian:isNude() then
					local change = data:toPhaseChange()
					if change.from == sgs.Player_Draw then
						local prompt = string.format("@eqiehu1:%s", player:objectName())
						if room:askForCard(lidian, "BasicCard", prompt, data, "eqiehu") then
							if player:getGeneralName() == "zhangliao" or player:getGeneralName() == "kof_zhangliao" then
								room:broadcastSkillInvoke(self:objectName(), 2)
							else
								room:broadcastSkillInvoke(self:objectName(), 1)
							end
							room:drawCards(player, 2, "eqiehu")
						end
					elseif change.from == sgs.Player_Discard then
						local prompt = string.format("@eqiehu2:%s", player:objectName())
						if room:askForCard(lidian, "EquipCard,TrickCard", prompt, data, "eqiehu") then
							if player:getGeneralName() == "sunquan" or player:getGeneralName() == "zhiba_sunquan" then
								room:broadcastSkillInvoke(self:objectName(), 4)
							else
								room:broadcastSkillInvoke(self:objectName(), 3)
							end
							room:askForDiscard(player, "eqiehu", 2, 2, false, true)
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
elidian:addSkill(eqiehu)

--周仓
ezhoucang = sgs.General(extension, "ezhoucang", "shu", "4")
--周仓【护武】
--护武——每当其他角色主动使用的红色的【杀】和红色非延时类锦囊牌结算结束后，你可以进行判定，
--若判定结果不为红桃，你选择一项：1.获得处理区里的此牌；2.令该角色摸一张牌。
ehuwu = sgs.CreateTriggerSkill {
	name = "ehuwu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local zhoucangs = room:findPlayersBySkillName(self:objectName())
		local use = data:toCardUse()
		local card = use.card
		for _, zhoucang in sgs.qlist(zhoucangs) do
			if event == sgs.CardUsed then
				if player:getPhase() == sgs.Player_Play then
					if card:isRed() then
						if card:isKindOf("Slash") or card:isNDTrick() then
							if not card:isKindOf("Nullification") then
								room:setCardFlag(card, "ehuwuable")
							end
						end
					end
				end
			elseif event == sgs.CardFinished then
				if card:hasFlag("ehuwuable") then
					if room:askForSkillInvoke(zhoucang, self:objectName(), data) then
						local userName = player:getGeneralName()
						if userName == "guanyu" or userName == "sp_guanyu" or userName == "shenguanyu" or userName == "neo_guanyu" then
							room:broadcastSkillInvoke(self:objectName(), 3)
						elseif card:isNDTrick() then
							room:broadcastSkillInvoke(self:objectName(), 2)
						else
							room:broadcastSkillInvoke(self:objectName(), 1)
						end
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|heart"
						judge.good = false
						judge.reason = self:objectName()
						judge.who = zhoucang
						room:judge(judge)
						if judge:isGood() then
							local id = card:getEffectiveId()
							local choice
							if not (room:getCardPlace(id) ~= sgs.Player_DiscardPile or player:isDead()) then
								choice = room:askForChoice(zhoucang, self:objectName(),
									"ehuwu1=" .. card:objectName() .. "+ehuwu2=" .. player:objectName(), data)
							elseif player:isDead() then
								choice = "ehuwu1=" .. card:objectName()
							else
								choice = "ehuwu2=" .. player:objectName()
							end
							if choice:startsWith("ehuwu1") then
								zhoucang:obtainCard(card);
							elseif choice:startsWith("ehuwu2") then
								player:drawCards(1)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return not target:hasSkill(self:objectName())
	end
}
ezhoucang:addSkill(ehuwu)

--张星彩
ezhangxingcai = sgs.General(extension, "ezhangxingcai", "shu", "3", false)
--张星彩【持内】
--摸牌阶段，若你已受伤，你可以少摸一张牌，亮出牌堆顶的X+1张牌（X为你已损失的体力值），
--你将其中任意数量的牌交给一名其他角色，然后获得其余的牌。
echineiGive = sgs.CreateTriggerSkill {
	name = "#echineiGive",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasFlag("echinei") then
			player:setFlags("-echinei")
			local x = player:getLostHp() + 1
			local card_ids = room:getNCards(x)
			room:fillAG(card_ids)
			local to_give = sgs.IntList()
			while true do
				if card_ids:isEmpty() then break end
				local card_id = room:askForAG(player, card_ids, true, "echinei")
				if card_id == -1 then break end
				card_ids:removeOne(card_id)
				to_give:append(card_id)
				room:takeAG(player, card_id, false)
				if card_ids:isEmpty() then break end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_give:isEmpty() then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "echinei")
				for _, id in sgs.qlist(to_give) do
					dummy:addSubcard(id)
				end
				target:obtainCard(dummy)
			end
			dummy:clearSubcards()
			if not card_ids:isEmpty() then
				for _, id in sgs.qlist(card_ids) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy)
			end
			dummy:deleteLater()
			room:clearAG()
		end
	end
}
echinei = sgs.CreateTriggerSkill {
	name = "echinei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	view_as_skill = echineiVS,
	on_trigger = function(self, event, player, data)
		if player:isWounded() then
			local room = player:getRoom()
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			if draw.num > 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					draw.num = draw.num - 1
					player:setFlags(self:objectName())
					data:setValue(draw)
				end
			end
		end
	end
}
--张星彩【攘外】
--一名角色的结束阶段开始时，若该角色于此回合内未使用过基本牌和锦囊牌，
--你可以弃置一张基本牌，视为对其攻击范围内的另一名其他角色使用一张【杀】。
erangwaiCard = sgs.CreateSkillCard {
	name = "erangwaiCard",
	filter = function(self, targets, to_select)
		local player = sgs.Self
		local players = player:getSiblings()
		local current
		players:append(player)
		for _, p in sgs.qlist(players) do
			if p:getPhase() ~= sgs.Player_NotActive then
				current = p
				break
			end
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("erangwai")
		local extra = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, slash) + 1
		slash:deleteLater()
		return sgs.Self:canSlash(to_select, slash, false) and #targets < extra and
			current:distanceTo(to_select) <= current:getAttackRange() and current:distanceTo(to_select) > 0
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local change = sgs.SPlayerList()
		slash:setSkillName("_erangwai")
		for _, play in ipairs(targets) do
			change:append(play)
		end
		local use = sgs.CardUseStruct()
		use.card = slash
		use.to = change
		use.from = source
		local current = room:getCurrent()
		if current:getGeneralName() == "liushan" then
			room:broadcastSkillInvoke("erangwai", 3)
		else
			room:broadcastSkillInvoke("erangwai", math.random(1, 2))
		end
		slash:deleteLater()
		room:useCard(use)
	end,
}
erangwaiVS = sgs.CreateViewAsSkill {
	name = "erangwai",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = erangwaiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@erangwai" and sgs.Slash_IsAvailable(player)
	end,
}
erangwai = sgs.CreateTriggerSkill {
	name = "erangwai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	view_as_skill = erangwaiVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardUsed then
			use = data:toCardUse()
			local card = use.card
			if card:isKindOf("BasicCard") or card:isKindOf("TrickCard") then
				if player:getPhase() ~= sgs.Player_NotActive then
					player:setFlags("erangwai")
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if not player:hasFlag("erangwai") then
					local room = player:getRoom()
					local zhangxingcais = room:findPlayersBySkillName(self:objectName())
					for _, zhangxingcai in sgs.qlist(zhangxingcais) do
						room:askForUseCard(zhangxingcai, "@@erangwai", "@erangwai", -1, sgs.Card_MethodDiscard)
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
ezhangxingcai:addSkill(echinei)
ezhangxingcai:addSkill(echineiGive)
extension:insertRelatedSkills("echinei", "#echineiGive")
ezhangxingcai:addSkill(erangwai)

--陆抗
elukang = sgs.General(extension, "elukang", "wu", "3")
--陆抗【堰守】
--出牌阶段限一次，你可以令一名角色弃置其装备区里的所有牌，然后该角色摸X+1张牌（X为其以此法弃置的装备牌数量）。
eyanshouCard = sgs.CreateSkillCard {
	name = "eyanshouCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < 1
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local equips = target:getEquips()
		local x = equips:length()
		target:throwAllEquips()
		target:drawCards(x + 1)
	end
}
eyanshou = sgs.CreateViewAsSkill {
	name = "eyanshou",
	n = 0,
	view_as = function(self, cards)
		local card = eyanshouCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#eyanshouCard")
	end,
}
--陆抗【克构】
--若有其他角色手牌不比你少，你可以跳过你的弃牌阶段。
ekegou = sgs.CreateTriggerSkill {
	name = "ekegou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then
			local room = player:getRoom()
			local players = room:getOtherPlayers(player)
			local ekegou_able = false
			for _, p in sgs.qlist(players) do
				if p:getHandcardNum() >= player:getHandcardNum() then
					ekegou_able = true
					break
				end
			end
			if ekegou_able then
				if player:askForSkillInvoke(self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					player:skip(sgs.Player_Discard)
				end
			end
		end
	end
}
elukang:addSkill(eyanshou)
elukang:addSkill(ekegou)

--诸葛恪
ezhugeke = sgs.General(extension, "ezhugeke", "wu", "4")
--诸葛恪【急思】
--每当你需要使用【无懈可击】时，你可以与当前回合角色拼点。若你赢，你视为使用一张【无懈可击】。每回合限一次。
ejisiCard = sgs.CreateSkillCard {
	name = "ejisiCard",
	target_fixed = true,
	will_throw = false,
	on_validate_in_response = function(self, player)
		local room = player:getRoom()
		local target = room:getCurrent()
		room:setPlayerFlag(player, "ejisiUsed")
		if target and player:pindian(target, "ejisi", nil) then
			room:broadcastSkillInvoke("ejisi", math.random(2, 3))
			local nullification = sgs.Sanguosha:cloneCard("nullification", sgs.Card_NoSuit, 0)
			nullification:toTrick():setCancelable(false)
			nullification:setSkillName("_ejisi")
			return nullification
		else
			room:broadcastSkillInvoke("ejisi", 4)
		end
		return nil
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local target = room:getCurrent()
		room:setPlayerFlag(player, "ejisiUsed")
		if target and player:pindian(target, "ejisi", nil) then
			room:broadcastSkillInvoke("ejisi", math.random(2, 3))
			local nullification = sgs.Sanguosha:cloneCard("nullification", sgs.Card_NoSuit, 0)
			nullification:toTrick():setCancelable(false)
			nullification:setSkillName("_ejisi")
			return nullification
		else
			room:broadcastSkillInvoke("ejisi", 4)
		end
		return nil
	end,
}
ejisiVS = sgs.CreateViewAsSkill {
	name = "ejisi",
	n = 0,
	view_as = function(self, cards)
		local card = ejisiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		for _,target in sgs.list(player:getAliveSiblings())do
			if target:hasFlag("CurrentPlayer") and target:getPhase() ~= sgs.Player_NotActive then 
				if player:canPindian(target) then
					if target:objectName() ~= player:objectName() then
						return not player:hasFlag("ejisiUsed") and pattern == "nullification"
					end
				end
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		local room = player:getRoom()
		local target = room:getCurrent()
		if not target or target:isDead() or target:getPhase() == sgs.Player_NotActive then return false end
		if player:canPindian(target) then
			if target:objectName() ~= player:objectName() then
				return not player:hasFlag("ejisiUsed")
			end
		end
		return false
	end
}
ejisi = sgs.CreateTriggerSkill {
	name = "ejisi",
	events = { sgs.EventPhaseChanging },
	view_as_skill = ejisiVS,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("ejisiUsed") then
					room:setPlayerFlag(p, "-ejisiUsed")
				end
			end
		end
		return false
	end
}
--诸葛恪【强辩】
--锁定技，每当你与一名角色拼点时，你令该角色用你选择的其一张手牌拼点。
--[[eqiangbian = sgs.CreateTriggerSkill{
	name = "eqiangbian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
		
	end
}]]

eqiangbian = sgs.CreateTriggerSkill {
	name = "eqiangbian",
	events = { sgs.AskforPindianCard },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskforPindianCard then
			local pindian = data:toPindian()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if ((pindian.from:objectName() ~= p:objectName()) and (pindian.to:objectName() ~= p:objectName())) then continue end
				if not p:hasSkill(self) then continue end
				if (pindian.from:objectName() == p:objectName()) then
					if pindian.to_card then continue end
					if pindian.to:isDead() or pindian.to:isKongcheng() then continue end
					if not p:askForSkillInvoke(self, pindian.to) then continue end
					room:sendCompulsoryTriggerLog(p, self:objectName())
					pindian.to_card = pindian.to:getRandomHandCard();
				end
				if (pindian.to:objectName() == p:objectName()) then
					if pindian.from_card then continue end
					if pindian.from:isDead() or pindian.from:isKongcheng() then continue end
					if not p:askForSkillInvoke(self, pindian.from) then continue end
					room:sendCompulsoryTriggerLog(p, self:objectName())
					pindian.from_card = pindian.from:getRandomHandCard();
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}





--诸葛恪【傲才】
--限定技，回合结束时，你可以令手牌比你多的所有角色各选择一项：1.交给你一张牌；2.弃置两张牌。然后你获得技能“专权”（其他角色的弃牌阶段开始时，你可以弃置该角色的X张手牌（X为其超过手牌上限的手牌张数））。
eaocai = sgs.CreateTriggerSkill {
	name = "eaocai",
	frequency = sgs.Skill_Limited,
	events = { sgs.EventPhaseChanging },
	limit_mark = "@talent",
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local nextphase = change.to
		if nextphase == sgs.Player_NotActive then
			if player:askForSkillInvoke(self:objectName(), data) then
				local room = player:getRoom()
				local players = room:getOtherPlayers(player)
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(players) do
					if p:getHandcardNum() > player:getHandcardNum() then
						targets:append(p)
					end
				end
				room:broadcastSkillInvoke(self:objectName())
				room:broadcastInvoke("animate", "lightbox:$eaocai:5000")
				player:loseMark("@talent")
				for _, p in sgs.qlist(targets) do
					local choice
					local equips = p:getEquips()
					local cardsNum = p:getHandcardNum() + equips:length()
					if cardsNum >= 2 then
						if not room:askForDiscard(p, self:objectName(), 2, 2, true, true) then
							if not p:isKongcheng() then
								local id = room:askForCardChosen(p, p, "he", "eaocai")
								local card = sgs.Sanguosha:getCard(id)
								room:moveCardTo(card, player, sgs.Player_PlaceHand, false)
							end
						end
					else
						if not p:isKongcheng() then
							local id = room:askForCardChosen(p, p, "he", "eaocai")
							local card = sgs.Sanguosha:getCard(id)
							room:moveCardTo(card, player, sgs.Player_PlaceHand, false)
						end
					end
				end
				room:acquireSkill(player, "ezhuanquan")
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@talent") > 0
				end
			end
		end
		return false
	end
}
--[[
eaocaiStart = sgs.CreateTriggerSkill{
	name = "#eaocaiStart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@talent")
	end
}]]
--诸葛恪【专权】
--其他角色的弃牌阶段开始时，你可以弃置其X张手牌（X为其超过手牌上限的手牌张数）。
ezhuanquanDummyCard = sgs.CreateSkillCard {
	name = "ezhuanquanDummyCard"
}
ezhuanquan = sgs.CreateTriggerSkill {
	name = "ezhuanquan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Discard then
			local room = player:getRoom()

			local zhugekes = room:findPlayersBySkillName(self:objectName())
			for _, zhugeke in sgs.qlist(zhugekes) do
				local x = player:getHandcardNum() - player:getMaxCards()
				if x > 0 then
					if room:askForSkillInvoke(zhugeke, self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerFlag(player, "ezhuanquanTarget_InTempMoving")
						local dummy = ezhuanquanDummyCard:clone()
						local card_ids = {}
						local original_places = {}
						local count = 0
						for i = 1, x, 1 do
							local id = room:askForCardChosen(zhugeke, player, "h", self:objectName())
							table.insert(card_ids, id)
							local place = room:getCardPlace(id)
							table.insert(original_places, place)
							dummy:addSubcard(id)
							zhugeke:addToPile("#ezhuanquan", id, false)
							count = count + 1
						end
						for i = 1, count, 1 do
							local card = sgs.Sanguosha:getCard(card_ids[i])
							room:moveCardTo(card, player, original_places[i], false)
						end
						room:setPlayerFlag(player, "-ezhuanquanTarget_InTempMoving")
						if count > 0 then
							room:throwCard(dummy, player, zhugeke)
						end
					end
				else
					break
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
ezhuanquanAvoidTriggeringCardsMove = sgs.CreateTriggerSkill {
	name = "#ezhuanquanAvoidTriggeringCardsMove",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = room:getAllPlayers()
		for _, p in sgs.qlist(targets) do
			if p:hasFlag("ezhuanquanTarget_InTempMoving") then
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
ezhugeke:addSkill(ejisi)
ezhugeke:addSkill(eqiangbian)
ezhugeke:addSkill(eaocai)
--ezhugeke:addSkill(eaocaiStart)
--extension:insertRelatedSkills("eaocai","#eaocaiStart")
ezhugeke_0 = sgs.General(extension, "ezhugeke_f", "wu", "4", true, true, true)
ezhugeke_0:addSkill(ezhuanquan)
ezhugeke:addSkill(ezhuanquanAvoidTriggeringCardsMove)
extension:insertRelatedSkills("ezhuanquan", "#ezhuanquanAvoidTriggeringCardsMove")
ezhugeke:addRelateSkill("ezhuanquan")

--刘璋
eliuzhang = sgs.General(extension, "eliuzhang", "qun", "4")
--刘璋【图守】
--准备阶段开始时，你可以选择一项：1.将一张手牌交给当前的体力值最大的一名其他角色，
--若如此做，你将你拥有的牌补至X张（X为你的体力上限），且每当你于此回合内造成伤害时，你防止此伤害；
--2.弃置两张牌，若如此做，你回复1点体力，且每当你于此回合内受到伤害时，你防止此伤害。
etushou = sgs.CreateTriggerSkill {
	name = "etushou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local equips = player:getEquips()
			local cardsNum = player:getHandcardNum() + equips:length()
			if not (player:isKongcheng() and cardsNum < 2) then
				local choice
				if cardsNum < 2 then
					choice = room:askForChoice(player, self:objectName(), "etushou1+cancel")
				elseif player:isKongcheng() then
					choice = room:askForChoice(player, self:objectName(), "etushou2+cancel")
				else
					choice = room:askForChoice(player, self:objectName(), "etushou1+etushou2+cancel")
				end
				if choice == "etushou1" then
					room:addPlayerMark(player, "&" .. self:objectName() .. "+etushou_damageCause-Clear")
					room:broadcastSkillInvoke(self:objectName(), 1)
					local maxHp = -1000
					local to_givelist0 = room:getOtherPlayers(player)
					for _, p in sgs.qlist(to_givelist0) do
						if p:getHp() > maxHp then
							maxHp = p:getHp()
						end
					end
					local to_givelist = sgs.SPlayerList()
					for _, p in sgs.qlist(to_givelist0) do
						if p:getHp() == maxHp then
							to_givelist:append(p)
						end
					end
					local to_give = room:askForPlayerChosen(player, to_givelist, self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName())
					reason.m_playerId = to_give:objectName()
					local id = room:askForCardChosen(player, player, "h", self:objectName())
					local card = sgs.Sanguosha:getCard(id)
					room:moveCardTo(card, to_give, sgs.Player_PlaceHand, false)
					equips = player:getEquips()
					cardsNum = player:getHandcardNum() + equips:length()
					local x = player:getMaxHp() - cardsNum
					if x > 0 then
						player:drawCards(x)
					end
					room:setPlayerFlag(player, "etushou1")
				elseif choice == "etushou2" then
					room:addPlayerMark(player, "&" .. self:objectName() .. "+etushou_damageInflicte-Clear")
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:askForDiscard(player, self:objectName(), 2, 2, false, true);
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
					room:setPlayerFlag(player, "etushou2")
				end
			end
		end
	end
}
etushouEffect = sgs.CreateTriggerSkill {
	name = "#etushouEffect",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			if player:hasFlag("etushou2") then
				room:broadcastSkillInvoke("etushou", 4)
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
		if event == sgs.DamageCaused then
			local source = damage.from
			if source then
				if source:isAlive() then
					if source:hasFlag("etushou1") then
						room:broadcastSkillInvoke("etushou", 3)
						damage.prevented = true
						data:setValue(damage)
						return true
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
--刘璋【宗室】
--锁定技，你的手牌上限+X（X为现存势力数）。
eliuzhang:addSkill(etushou)
eliuzhang:addSkill(etushouEffect)
extension:insertRelatedSkills("etushou", "#etushouEffect")
eliuzhang:addSkill("zongshi")

--王允
ewangyun = sgs.General(extension, "ewangyun", "qun", "3")
--王允【挑拨】
--出牌阶段限一次，你可以令两名其他角色同时展示一张手牌。
--若花色不同，其中手牌少的角色视为对手牌多的角色使用一张【杀】；若花色相同，你失去1点体力。
etiaoboCard = sgs.CreateSkillCard {
	name = "etiaoboCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets < 2 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				if not to_select:isKongcheng() then
					return true
				end
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
		local id1 = room:askForCardChosen(playerA, playerA, "h", self:objectName())
		local card1 = sgs.Sanguosha:getCard(id1)
		local id2 = room:askForCardChosen(playerB, playerB, "h", self:objectName())
		local card2 = sgs.Sanguosha:getCard(id2)
		room:showCard(playerA, id1)
		room:showCard(playerB, id2)
		if card1:getSuit() ~= card2:getSuit() then
			if playerA:getHandcardNum() ~= playerB:getHandcardNum() then
				local from
				local to
				if playerA:getHandcardNum() < playerB:getHandcardNum() then
					from = playerA
					to = playerB
				else
					from = playerB
					to = playerA
				end
				if from:canSlash(to, nil, false) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_etiaobo")
					slash:deleteLater()
					local card_use = sgs.CardUseStruct()
					card_use.from = from
					card_use.to:append(to)
					card_use.card = slash
					room:setPlayerFlag(from, "ZenhuiUser_"..slash:toString())
					room:useCard(card_use, false)
					room:setPlayerFlag(from, "-ZenhuiUser_"..slash:toString())
				end
			end
		else
			room:loseHp(source, 1, true, source, self:objectName())
		end
	end
}
etiaobo = sgs.CreateViewAsSkill {
	name = "etiaobo",
	n = 0,
	view_as = function(self, cards)
		local card = etiaoboCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#etiaoboCard")
	end,
}
--王允【持重】
--每当你扣减或回复体力后，你可以摸一张牌。
echizhong = sgs.CreateTriggerSkill {
	name = "echizhong",
	frequency = sgs.Skill_Frequent,
	events = { sgs.HpChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:drawCards(player, 1, "echizhong")
		end
	end
}
ewangyun:addSkill(etiaobo)
ewangyun:addSkill(echizhong)

--文字信息显示
sgs.LoadTranslationTable {
	["emjr"] = "E鸣惊人",

	["echengyu"] = "程昱",
	["&echengyu"] = "程昱",
	["#echengyu"] = "狠戾的谋士",
	["designer:echengyu"] = "小A",
	["cv:echengyu"] = "NeoSpeech Liang",
	["illustrator:echengyu"] = "三国在线",
	["efusha"] = "伏杀",
	[":efusha"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌背面朝上移出游戏并选择一名其他角色，若如此做，该角色的回合开始时，其选择一种花色后将此牌置入弃牌堆，若此牌的花色与其所选的不同，你视为对其使用一张【杀】。",
	["#efusha"] = "%from执行了“%arg”的效果，选择了花色%arg2",
	["eweicheng"] = "危城",
	[":eweicheng"] = "每当你成为其他角色使用的【杀】或非延时类锦囊牌的目标后，若你有手牌，你可以依次弃置该角色的X张牌（X为你已损失的体力值且至少为1）。",
	-- ["$efusha1"] = "十面埋伏，定能重创敌军。", --发动
	-- ["$efusha2"] = "前无去路，诸军何不死战？", --执行效果
	-- ["$efusha3"] = "决一死战，生擒袁绍！", --袁绍执行效果
	-- ["$eweicheng1"] = "今汝见吾兵少，必轻易不来攻。",
	-- ["$eweicheng2"] = "四世三公也就这点胆量。", --对袁绍
	-- ["~echengyu"] = "知足不辱，吾可以退矣。",

	["elidian"] = "李典",
	["&elidian"] = "李典",
	["#elidian"] = "恂恂之风",
	["designer:elidian"] = "llmoon",
	["cv:elidian"] = "NeoSpeech Liang",
	["illustrator:elidian"] = "真三国无双7",
	["eqiehu"] = "郄縠",
	[":eqiehu"] = "其他角色的摸牌阶段结束后，你可以弃置一张基本牌，令该角色摸两张牌；其他角色的弃牌阶段结束后，你可以弃置一张非基本牌，令该角色弃置两张牌。",
	["@eqiehu1"] = "你可以弃置一张基本牌发动“郄縠”，令 %src 摸两张牌",
	["@eqiehu2"] = "你可以弃置一张非基本牌发动“郄縠”，令 %src 弃置两张牌",
	-- ["$eqiehu1"] = "典岂敢以私憾而忘公义乎？", --前半段
	-- ["$eqiehu2"] = "文远兄，我来助你！", --前半段，对张辽
	-- ["$eqiehu3"] = "苟利国家，专之可也，宜亟击之。", --后半段
	-- ["$eqiehu4"] = "活捉孙权，当在今日！", --后半段，对孙权
	-- ["~elidian"] = "可惜看不到曹魏大军横扫江东了。",

	["ezhoucang"] = "周仓",
	["&ezhoucang"] = "周仓",
	["#ezhoucang"] = "武圣护卫",
	["designer:ezhoucang"] = "金皆居士",
	["cv:ezhoucang"] = "NeoSpeech Liang",
	["illustrator:ezhoucang"] = "三国智",
	["ehuwu"] = "护武",
	[":ehuwu"] = "每当其他角色主动使用的红色的【杀】和红色非延时类锦囊牌结算结束后，你可以进行判定，若判定结果不为红桃，你选择一项：1.获得处理区里的此牌；2.令该角色摸一张牌。",
	["ehuwu:ehuwu1"] = "获得处理区里的 %src",
	["ehuwu:ehuwu2"] = "令 %src 摸一张牌",
	-- ["$ehuwu1"] = "好刀法！", --红杀
	-- ["$ehuwu2"] = "好计策！", --红锦囊
	-- ["$ehuwu3"] = "仓跟随将军，虽万里不辞也。", --对关羽
	-- ["~ezhoucang"] = "关将军已死，仓岂能独生……",

	["ezhangxingcai"] = "张星彩",
	["&ezhangxingcai"] = "张星彩",
	["#ezhangxingcai"] = "敬哀皇后",
	["designer:ezhangxingcai"] = "惘ワ記",
	["cv:ezhangxingcai"] = "Microsoft Huihui",
	["illustrator:ezhangxingcai"] = "地狱许",
	["echinei"] = "持内",
	[":echinei"] = "摸牌阶段，若你已受伤，你可以少摸一张牌，亮出牌堆顶的X+1张牌（X为你已损失的体力值），你将其中任意数量的牌交给一名其他角色，然后获得其余的牌。",
	["erangwai"] = "攘外",
	[":erangwai"] = "一名角色的结束阶段开始时，若该角色于此回合内未使用过基本牌和锦囊牌，你可以弃置一张基本牌，视为对其攻击范围内的另一名其他角色使用一张【杀】。",
	["@erangwai"] = "你可以弃置一张基本牌发动“攘外”",
	["~erangwai"] = "选择一张基本牌→选择【杀】的目标角色→点击确定",
	-- ["$echinei1"] = "以我微薄之力，免除陛下后顾之忧。",
	-- ["$echinei2"] = "攘外必先安内。",
	-- ["$erangwai1"] = "车骑将军之女在此，何人敢犯我蜀境？！",
	-- ["$erangwai2"] = "蜀中无大将，女子上战场。",
	-- ["$erangwai3"] = "臣妾愿为陛下而战！", --对刘禅
	-- ["~ezhangxingcai"] = "只愿陛下与蜀汉平安……",

	["elukang"] = "陆抗",
	["&elukang"] = "陆抗",
	["#elukang"] = "镇军之将",
	["designer:elukang"] = "雪寂人心",
	["cv:elukang"] = "NeoSpeech Liang",
	["illustrator:elukang"] = "三国志12",
	["eyanshou"] = "堰守",
	[":eyanshou"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名角色弃置其装备区里的所有牌，然后该角色摸X+1张牌（X为其以此法弃置的装备牌数量）。",
	["ekegou"] = "克构",
	[":ekegou"] = "若有其他角色手牌不比你少，你可以跳过你的弃牌阶段。",
	-- ["$eyanshou1"] = "筑此堰，可淹敌军。",
	-- ["$eyanshou2"] = "毁此堰，可断敌粮。",
	-- ["$ekegou1"] = "父亲，我不会辜负江东陆家的荣耀。",
	-- ["$ekegou2"] = "隐忍克己，静待时机，此伐晋之道。",
	-- ["~elukang"] = "抗存则吴存，抗亡则吴亡……",

	["ezhugeke_f"] = "诸葛恪",
	["&ezhugeke_f"] = "诸葛恪",
	["#ezhugeke_f"] = "矜己陵人",
	["designer:ezhugeke_f"] = "大道岂可修",
	["cv:ezhugeke_f"] = "NeoSpeech Liang",
	["illustrator:ezhugeke_f"] = "LiuHeng",

	["ezhugeke"] = "诸葛恪",
	["&ezhugeke"] = "诸葛恪",
	["#ezhugeke"] = "矜己陵人",
	["designer:ezhugeke"] = "大道岂可修",
	["cv:ezhugeke"] = "NeoSpeech Liang",
	["illustrator:ezhugeke"] = "LiuHeng",
	["ejisi"] = "急思",
	[":ejisi"] = "每当你需要使用【无懈可击】时，你可以与当前回合角色拼点，若你赢，你视为使用一张【无懈可击】。每回合限一次。",
	["eqiangbian"] = "强辩",
	[":eqiangbian"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你与一名角色拼点时，你令该角色用你选择的其一张手牌拼点。",
	["eaocai"] = "傲才",
	[":eaocai"] = "<font color=\"red\"><b>限定技，</b></font>回合结束时，你可以令手牌比你多的所有角色各选择一项：1.交给你一张牌；2.弃置两张手牌。然后你获得技能“专权”（其他角色的弃牌阶段开始时，你可以弃置其X张手牌（X为其超过手牌上限的手牌张数））。",
	["@talent"] = "傲才",
	["ezhuanquan"] = "专权",
	[":ezhuanquan"] = "其他角色的弃牌阶段开始时，你可以弃置其X张手牌（X为其超过手牌上限的手牌张数）。",
	-- ["$ejisi1"] = "爰植梧桐，以待凤皇。", --发动
	-- ["$ejisi2"] = "有何燕雀，自称来翔？", --拼点赢1
	-- ["$ejisi3"] = "此乃诸葛子瑜之驴。", --拼点赢2
	-- ["$ejisi4"] = "竟能难倒我！", --拼点没赢
	-- ["$eaocai"] = "父亲，你看到了么，我就要超越叔父了。",
	-- ["$ezhuanquan1"] = "汝等休要妄为！",
	-- ["$ezhuanquan2"] = "这事我说了算！",
	-- ["~ezhugeke"] = "父亲的预言竟然成真了。",

	["eliuzhang"] = "刘璋",
	["&eliuzhang"] = "刘璋",
	["#eliuzhang"] = "蹯踞西川",
	["designer:eliuzhang"] = "小猪翼么么哒",
	["cv:eliuzhang"] = "NeoSpeech Liang",
	["illustrator:eliuzhang"] = "三国志12",
	["etushou"] = "图守",
	[":etushou"] = "准备阶段开始时，你可以选择一项：1.将一张手牌交给当前的体力值最大的一名其他角色，若如此做，你将你拥有的牌补至X张（X为你的体力上限），且每当你于此回合内造成伤害时，你防止此伤害；2.弃置两张牌，若如此做，你回复1点体力，且每当你于此回合内受到伤害时，你防止此伤害。",
	["etushou:etushou1"] = "将一张手牌交给当前的体力值最大的一名其他角色",
	["etushou:etushou2"] = "弃置两张牌",
	["etushou_damageInflicte"] = "防止受到伤害",
	["etushou_damageCause"] = "防止造成伤害",
	-- ["$etushou1"] = "速搬救兵！", --给牌
	-- ["$etushou2"] = "只有如此方可保全西川百姓。", --弃牌
	-- ["$etushou3"] = "此非鸿门会，何用舞剑？", --效果1防止伤害
	-- ["$etushou4"] = "我等同为汉臣，公等勿虑也。", --效果2防止伤害
	-- ["~eliuzhang"] = "望玄德公以西川百姓为重！",

	["ewangyun"] = "王允",
	["&ewangyun"] = "王允",
	["#ewangyun"] = "除暴卫汉",
	["designer:ewangyun"] = "LcDreamer",
	["cv:ewangyun"] = "NeoSpeech Liang",
	["illustrator:ewangyun"] = "三国志12",
	["etiaobo"] = "挑拨",
	[":etiaobo"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令两名其他角色同时展示一张手牌。若花色不同，其中手牌少的角色视为对手牌多的角色使用一张【杀】；若花色相同，你失去1点体力。",
	["echizhong"] = "持重",
	[":echizhong"] = "每当你扣减或回复体力后，你可以摸一张牌。",
	-- ["$etiaobo1"] = "此计可化百姓倒悬之危，解君臣累卵之急。",
	-- ["$etiaobo2"] = "反贼至此，武士何在？",
	-- ["$echizhong1"] = "事若泄漏，我灭门矣！",
	-- ["$echizhong2"] = "但恐事或不成，反招大祸。",
	-- ["~ewangyun"] = "臣本为社稷计，事已至此……",
}

--[[ 武将：郝昭（群，4体力）
技能：
【死守】【锁定技】：若你的装备区里没有防具牌，红色的杀（含火杀）对你无效，每当你受到一次杀的伤害，你摸一张牌。
【破计】在你的回合外，当你成为非延时锦囊的目标时，你可以弃置一张与此锦囊相同花色的手牌令其无效。
==========================================================
武将：张翼（蜀，4体力）
技能：
【廷争】其他角色于其回合内使用第一张【杀】时，你可以与其拼点：若你赢，取消此【杀】，你获得双方拼点的牌，其摸两张牌；若你没赢，其获得双方拼点的牌，于此【杀】结算结束后你视为对相同目标使用【杀】。每轮限一次。 ]]
