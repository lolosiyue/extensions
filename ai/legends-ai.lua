-- sgs.ai_chaofeng.Ashe = 3
-- sgs.ai_chaofeng.Nasus = 2
-- sgs.ai_chaofeng.Katarina = 3
-- sgs.ai_chaofeng.Talon = 4
-- sgs.ai_chaofeng.JarvanIV = 2
-- sgs.ai_chaofeng.Darius = 2
-- sgs.ai_chaofeng.Caitlyn = 3
-- sgs.ai_chaofeng.Irelia = 2

sgs.ai_skill_invoke.lvdong = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local from = damage.from
	if self:isFriend(target) then
		return false
	elseif self:cantDamageMore(from,target) then
		return false
	elseif target:hasArmorEffect("SilverLion") or target:hasArmorEffect("xieshen") then
		return false
	elseif target:hasArmorEffect("jingji") and from:getHp() <= 2 then
		return false
	elseif target:hasArmorEffect("zhongya") and (not target:faceUp()) then
		return false
	end
	return true
end
sgs.ai_choicemade_filter.skillInvoke.lvdong = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.to then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, damage.to, 80)
		end
	end
end

sgs.ai_ajustdamage_from.lvdong = function(self,from,to,card,nature)
	if to:getMark("@lvdong") == 0 and not beFriend(to,from)
	then return 1 end
end
sgs.ai_skill_playerchosen.tulong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() and self:canDraw(target, self.player) then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.tulong = -40

sgs.ai_cardneed.lol_zhiming = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|lol_zhiming"
sgs.ai_canliegong_skill.lol_zhiming = function(self, from, to)
	return to:getHp() < from:getHp() and from:distanceTo(to) <= 1
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|yongqi"


local lol_zhengyi_skill = {}
lol_zhengyi_skill.name= "lol_zhengyi"
table.insert(sgs.ai_skills,lol_zhengyi_skill)
lol_zhengyi_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#lol_zhengyiCard:.:")
end

sgs.ai_skill_use_func["#lol_zhengyiCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and not self:cantDamageMore(self.player,enemy) and enemy:getLostHp() > 0 then
			use.card = sgs.Card_Parse("#lol_zhengyiCard:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_value.lol_zhengyiCard = 2.5
sgs.ai_card_intention.lol_zhengyiCard = 80
sgs.dynamic_value.damage_card.lol_zhengyiCard = true


sgs.ai_skill_invoke.xinyan = function(self, data)
	local use = data:toCardUse()
	local from = use.from
	local max_card = self:getMaxCard()
	if not max_card then return end
	if max_card:getNumber() > 10 and self:isFriend(from) then
		if from:getHandcardNum() == 1 and self:needKongcheng(from) then return true end
		if self:getOverflow(from) > 2 then return true end
		if not self:hasLoseHandcardEffective(from) then return true end
	end
	if self:isFriend(from) then return false end
	if max_card:getNumber() > 10 
		or (self.player:getHp() > 2 and self.player:getHandcardNum() > 2 and max_card:getNumber() > 4)
		or (self.player:getHp() > 1 and self.player:getHandcardNum() > 1 and max_card:getNumber() > 7)
		or (from:getHandcardNum() <= 2 and max_card:getNumber() > 2) 
		or (from:getHandcardNum() == 1 and self:hasLoseHandcardEffective(from) and not self:needKongcheng(from))
		or self:getOverflow() > 2 then
		return true
	end
end

sgs.ai_choicemade_filter.skillInvoke.xinyan = function(self, player, promptlist)
	local use = self.room:getTag("xinyan"):toCardUse()
	if use.from and promptlist[3] == "yes" then
		local target = use.from
		local intention = 10
		if target:getHandcardNum() == 1 and self:needKongcheng(target) then intention = 0 end
		if self:getOverflow(target) > 2 then intention = 0 end
		if not self:hasLoseHandcardEffective(target) then intention = 0 end
		sgs.updateIntention(player, target, intention)
	end
end

function sgs.ai_skill_pindian.xinyan(minusecard, self, requestor)
	local maxcard = self:getMaxCard()	
	return self:isFriend(requestor) and minusecard or ( maxcard:getNumber() < 6 and minusecard or maxcard )
end

sgs.ai_cardneed.xinyan = sgs.ai_cardneed.bignumber
sgs.ai_ajustdamage_to.daren = function(self, from, to, card, nature)
	if card and card:isKindOf("Duel")
	then
		return -99
	end
end

sgs.ai_cardneed.jianwu = sgs.ai_cardneed.slash


function getSkillTarget(self, trick, targets)
	local enemies = {}
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			if trick:targetFilter(sgs.PlayerList(), p, self.player) then
				table.insert(enemies, p)
			end
		end
	end
	if #enemies == 0 then
		return nil
	end
	local ZhangHe = self.room:findPlayerBySkillName("qiaobian")
	local ZhangHeSeat = 0
	local ZhangHeRound = 0
	if ZhangHe and ZhangHe:faceUp() then
		if not ZhangHe:isKongcheng() then
			if not self:isFriend(ZhangHe) then
				ZhangHeSeat = ZhangHe:getSeat()
				ZhangHeRound = self:playerGetRound(ZhangHe)
			end
		end
	end
	local DaQiao = self.room:findPlayerBySkillName("yanxiao")
	local YanXiao = false
	local DaQiaoRound = 0
	if DaQiao and DaQiao:faceUp() then
		if not self:isFriend(DaQiao) then
			if getKnownCard(DaQiao, self.player, "diamond", nil, "he") > 0 then
				YanXiao = true
			elseif DaQiao:containsTrick("YanxiaoCard") then
				YanXiao = true
			else
				local num = DaQiao:getHandcardNum()
				local skills = DaQiao:getVisibleSkillList(true)
				local draw = self:ImitateResult_DrawNCards(DaQiao, skills)
				if num + draw > 3 then
					YanXiao = true
				end
			end
			if YanXiao then
				DaQiaoRound = self:playerGetRound(DaQiao)
			end
		end
	end
	local getIndulgenceValue = function(enemy)
		if enemy:containsTrick("indulgence") or enemy:containsTrick("YanxiaoCard") then 
			return -100 
		end
		if enemy:hasSkill("qiaobian") then
			if not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence") then 
				return -100 
			end
		end
		local round = self:playerGetRound(enemy)
		if ZhangHeSeat > 0 then
			if ZhangHeRound <= round and self:enemiesContainsTrick() <= 1 or not enemy:faceUp() then
				return -100 
			end
		end
		if YanXiao then
			if DaQiaoRound <= round and self:enemiesContainsTrick(true) <= 1 or not enemy:faceUp() then
				return -100 
			end
		end
		local value = enemy:getHandcardNum() - enemy:getHp()
		local skills = "noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|"
		skills = skills .. "anxu|yongsi|zhiheng|manjuan|nosrende|rende|qixi|jixi"
		if enemy:hasSkills(skills) then 
			value = value + 10 
		end
		skills = "houyuan|qice|guose|duanliang|yanxiao|nosjujian|luoshen|nosjizhi|jizhi|mengyan|wansha|mingce|sizhan"
		if enemy:hasSkills(skills) then 
			value = value + 5 
		end
		skills = "guzheng|shenyanng|xiliang|guixin|lihun|yinling|yingyan|shenfen|ganlu|duoshi|jueji|zhenggong"
		if enemy:hasSkills(skills) then 
			value = value + 3 
		end
		if self:isWeak(enemy) then 
			value = value + 3 
		end
		if enemy:isLord() then 
			value = value + 3 
		end
		if self:objectiveLevel(enemy) < 3 then 
			value = value - 10 
		end
		if not enemy:faceUp() then 
			value = value - 10 
		end
		if enemy:hasSkills("keji|shensu|conghui") then 
			value = value - enemy:getHandcardNum() 
		end
		if enemy:hasSkills("guanxing|xiuluo") then 
			value = value - 5 
		end
		if enemy:hasSkills("lirang|longluo") then 
			value = value - 5 
		end
		if enemy:hasSkills("tuxi|noszhenlie|guanxing|juewang|zongshi|tiandu") then 
			value = value - 3 
		end
		if enemy:hasSkill("conghui") then 
			value = value - 20 
		end
		if self:needBear(enemy) then 
			value = value - 20 
		end
		if not self:isGoodTarget(enemy, self.enemies) then 
			value = value - 1 
		end
		if getKnownCard(enemy, self.player, "Dismantlement", true) > 0 then 
			value = value + 2 
		end
		value = value + (self.room:alivePlayerCount() - round) / 2
		return value
	end
	local getSupplyShortageValue = function(enemy)
		if enemy:containsTrick("supply_shortage") or enemy:containsTrick("YanxiaoCard") then 
			return -100 
		end
		if enemy:getMark("juao") > 0 then 
			return -100 
		end
		if enemy:hasSkill("qiaobian") then
			if not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence") then 
				return -100 
			end
		end
		local round = self:playerGetRound(enemy)
		if ZhangHeSeat > 0 then
			if ZhangHeRound <= round and self:enemiesContainsTrick() <= 1 or not enemy:faceUp() then
				return - 100 
			end
		end
		if YanXiao then
			if DaQiaoRound <= round and self:enemiesContainsTrick(true) <= 1 or not enemy:faceUp() then
				return -100 
			end
		end
		local value = 0 - enemy:getHandcardNum()
		local skills = "yongsi|haoshi|tuxi|noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|manjuan|beige"
		if self:hasSkills(skills, enemy) then
			value = value + 10
		elseif enemy:hasSkill("zaiqi") and enemy:getLostHp() > 1 then
			value = value + 10
		end
		skills = "zhaolie|tianxiang|juewang|yanxiao|zhaoxin|zhouchu|renjie"
		if self:hasSkills(sgs.cardneed_skill, enemy) then
			value = value + 5
		elseif self:hasSkills(skills, enemy) then
			value = value + 5
		end
		skills = "yingzi|shelie|xuanhuo|buyi|jujian|jiangchi|mizhao|hongyuan|chongzhen|duoshi"
		if self:hasSkills(skills, enemy) then 
			value = value + 1 
		end
		if enemy:hasSkill("zishou") then 
			value = value + enemy:getLostHp() 
		end
		if self:isWeak(enemy) then 
			value = value + 5 
		end
		if enemy:isLord() then 
			value = value + 3 
		end
		if self:objectiveLevel(enemy) < 3 then 
			value = value - 10 
		end
		if not enemy:faceUp() then 
			value = value - 10 
		end
		if self:hasSkills("keji|shensu|qingyi", enemy) then 
			value = value - enemy:getHandcardNum() 
		end
		if self:hasSkills("guanxing|xiuluo|tiandu|guidao|noszhenlie", enemy) then 
			value = value - 5 
		end
		if not self:isGoodTarget(enemy, self.enemies) then 
			value = value - 1 
		end
		if self:needKongcheng(enemy) then 
			value = value - 1 
		end
		if enemy:getMark("@kuiwei") > 0 then 
			value = value - 2 
		end
		return value
	end
	local values = {}
	local getValue = nil
	if trick:isKindOf("Indulgence") then
		getValue = getIndulgenceValue
	elseif trick:isKindOf("SupplyShortage") then
		getValue = getSupplyShortageValue
	end
	if type(getValue) == "function" then
		for _,enemy in ipairs(enemies) do
			values[enemy:objectName()] = getValue(enemy)
		end
	end
	local compare_func = function(a, b)
		local valueA = values[a:objectName()] or 0
		local valueB = values[b:objectName()] or 0
		return valueA > valueB
	end
	table.sort(enemies, compare_func)
	local target = enemies[1]
	local value = values[target:objectName()] or -100
	if value > -100 then
		return target
	end
	return nil
end

--[[
	技能：技能
	描述：出牌阶段，你可以将你的红色手牌当【乐不思蜀】或黑色手牌当【兵粮寸断】对体力值不小于你的角色使用。
]]--
--junhengCard
local skill_skill = {
	name = "junheng",
	getTurnUseCard = function(self, inclusive)
		if self.player:isKongcheng() then
			return nil
		end
		return sgs.Card_Parse("#junhengCard:.:")
	end,
}
table.insert(sgs.ai_skills, skill_skill)
sgs.ai_skill_use_func["#junhengCard"] = function(card, use, self)
	local others = self.room:getAlivePlayers()
	local targets = {}
	local hp = self.player:getHp()
	for _,p in sgs.qlist(others) do
		if p:getHp() >= hp then
			table.insert(targets, p)
		end
	end
	if #targets == 0 then
		return 
	end
	local handcards = self.player:getHandcards()
	local reds, blacks = {}, {}
	for _,c in sgs.qlist(handcards) do
		if c:isRed() then
			table.insert(reds, c)
		elseif c:isBlack() then
			table.insert(blacks, c)
		end
	end
	if #reds > 0 then
		local to_use = nil
		self:sortByUseValue(reds, true)
		for _,red in ipairs(reds) do
			local dummy_use = self:aiUseCard(red, dummy())
			if not dummy_use.card then
				to_use = red
				break
			end
		end
		if to_use then
			local suit = to_use:getSuit()
			local point = to_use:getNumber()
			local indulgence = sgs.Sanguosha:cloneCard("indulgence", suit, point)
			indulgence:deleteLater()
			local target = getSkillTarget(self, indulgence, targets)
			if target then
				local card_str = "#junhengCard:"..to_use:getEffectiveId()..":->"..target:objectName()
				local acard = sgs.Card_Parse(card_str)
				assert(acard)
				use.card = acard
				if use.to then
					use.to:append(target)
				end
				return 
			end
		end
	end
	if #blacks > 0 then
		local to_use = nil
		self:sortByUseValue(blacks, true)
		for _,black in ipairs(blacks) do
			local dummy_use = self:aiUseCard(black, dummy())
			if not dummy_use.card then
				to_use = black
				break
			end
		end
		if to_use then
			local suit = to_use:getSuit()
			local point = to_use:getNumber()
			local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage", suit, point)
			supply_shortage:deleteLater()
			local target = getSkillTarget(self, supply_shortage, targets)
			if target then
				local card_str = "#junhengCard:"..to_use:getEffectiveId()..":->"..target:objectName()
				local acard = sgs.Card_Parse(card_str)
				assert(acard)
				use.card = acard
				if use.to then
					use.to:append(target)
				end
				return 
			end
		end
	end
end
--相关信息
sgs.ai_use_value["junhengCard"] = 4
sgs.ai_use_priority["junhengCard"] = 9
sgs.ai_card_intention["junhengCard"] = 70

sgs.need_equip_skill = sgs.need_equip_skill .. "|zhizun"
function sgs.ai_cardneed.zhizun(to,card,self)
	if not self:willSkipPlayPhase(to) and to:getMark("zhizun") == 0 then
		return card:isKindOf("EquipCard")
	end
end

local lol_liren_skill = {
	name = "lol_liren",
	getTurnUseCard = function(self, inclusive)
		if self.player:isKongcheng() then
			return nil
		elseif self.player:hasUsed("#lol_lirenCard") then
			return nil
		end
		return sgs.Card_Parse("#lol_lirenCard:.:")
	end,
}
table.insert(sgs.ai_skills, lol_liren_skill)
sgs.ai_skill_use_func["#lol_lirenCard"] = function(card, use, self)
	local target = nil
	self:sort(self.enemies, "defense")
	if self:getCardsNum("Slash") > 0 then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card then
			for _, p in sgs.qlist(dummy_use.to) do
				if not p:isKongcheng() or p:getArmor() or self:getOverflow() > 0 then
					target = p
					break
				end
			end
		end
	end
	if not target then
		if self:getCardsNum("ArcheryAttack", self.player) > 0 then
			local aa = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_Heart, 0)
			aa:deleteLater()
			local dummy_use = self:aiUseCard(aa, dummy())

			if dummy_use.card then
				for _,enemy in ipairs(self.enemies) do
					if enemy:hasArmorEffect("Vine") then
						target = enemy
						break
					end
				end
				if not target then
					for _,enemy in ipairs(self.enemies) do
						if getCardsNum("Jink", enemy) > 0 then
							target = enemy
							break
						end
					end
				end
			end
		end
	end
	if not target then
		if self:getCardsNum("SavageAssault", self.player) > 0 then
			local sa = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_Spade, 0)
			sa:deleteLater()
			local dummy_use = self:aiUseCard(sa, dummy())
			if dummy_use.card then
				for _,enemy in ipairs(self.enemies) do
					if enemy:hasArmorEffect("Vine") then
						target = enemy
						break
					end
				end
			end
		end
	end
	if target then
		local handcards = self.player:getHandcards()
		handcards = sgs.QList2Table(handcards)
		self:sortByUseValue(handcards, true)
		local card_id = nil
		for _,c in ipairs(handcards) do
			if not c:isKindOf("Peach") then
				if not c:isKindOf("AOE") then
					if c:isKindOf("Slash") then
						if self:getCardsNum("Slash") > 1 then
							card_id = c:getEffectiveId()
							break
						end
					else
						card_id = c:getEffectiveId()
						break
					end
				end
			end
		end
		if card_id then
			local card_str = "#lol_lirenCard:"..card_id..":->"..target:objectName()
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
--相关信息
sgs.ai_use_value["lol_lirenCard"] = 4
sgs.ai_use_priority["lol_lirenCard"] = 9
sgs.ai_card_intention["lol_lirenCard"] = 80

sgs.ai_skill_invoke.zhican = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local from = damage.from
	if self:isFriend(target) then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@zhicandis"] = function(self,data,pattern)
	local damage = data:toDamage()
	if damage.from and (not damage.from:hasSkill("duantou") or  damage.from:getMark("@duantou") == 0) then return "." end
	if(self:ajustDamage(damage.from,self.player,self.player:getMark("@blood"),nil)<2
	and self:needToLoseHp(self.player,damage.from,nil)) then return "." end
	if self:ajustDamage(damage.from,self.player,self.player:getMark("@blood"),nil) + self:getCardsNum("Peach")>0 then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if not card:isRed() or (not self:isWeak() and (self:getKeepValue(card)>8 or self:isValuableCard(card))) then continue end
		return "$"..card:getEffectiveId()
	end
end

local duantou_skill = {}
duantou_skill.name= "duantou"
table.insert(sgs.ai_skills,duantou_skill)
duantou_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#duantouCard:.:")
end

sgs.ai_skill_use_func["#duantouCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and enemy:getMark("@blood")>=enemy:getHp() and not self:cantDamageMore(self.player,enemy)
		then
			use.card = sgs.Card_Parse("#duantouCard:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_value["duantouCard"] = 2.5
sgs.ai_card_intention["duantouCard"] = 80
sgs.dynamic_value.damage_card["duantouCard"] = true

sgs.ai_skill_invoke.tieshou = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local from = damage.from
	if self:isFriend(target) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.buxiang = function(self, from, to, card, nature)
	return to:getMark("@buxiang")
end

--[[
	技能：割喉
	描述：出牌阶段开始时，你可以和一名角色拼点：若你赢，该角色不能使用手牌且你对其造成的伤害+1，直到回合结束；若你没赢，你结束出牌阶段。
]]--
--source:pindian(target, "gehou", self)
--room:askForUseCard(player, "@@gehou", "@gehou")
sgs.ai_skill_use["@@gehou"] = function(self, prompt, method)
	if #self.enemies > 0 then
		local mymaxcard = self:getMaxCard()
		if mymaxcard then
			local mymaxpoint = mymaxcard:getNumber()
			self:sort(self.enemies, "handcard")
			self.enemies = sgs.reverse(self.enemies)
			local targets = {}
			for _,enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					local maxcard = self:getMaxCard(enemy)
					local maxpoint = maxcard and maxcard:getNumber() or 10
					if mymaxpoint > maxpoint then
						table.insert(targets, enemy)
					end
				end
			end
			local target = nil
			if #targets > 0 then
				for _,enemy in ipairs(targets) do
					if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
						if not self:cantbeHurt(enemy) then
							target = enemy
							break
						end
					end
				end
				target = target or self.enemies[#self.enemies]
			end
			if target then
				local card_str = "#gehouCard:"..mymaxcard:getEffectiveId()..":->"..target:objectName()
				return card_str
			end
		end
	end
	return "."
end
sgs.ai_cardneed.gehou = sgs.ai_cardneed.bignumber


sgs.ai_ajustdamage_from.gehou = function(self, from, to, card, nature)
	if to and to:objectName() == from:getTag("GehouTarget"):toString() then
		return 1
	end
end
sgs.ai_ajustdamage_from.lianmin = function(self, from, to, card, nature)
	if (not to:getJudgingArea():isEmpty()) or (not (to:faceUp())) then
		return 1
	end
end
--[[
	技能：傀儡（限定技）
	描述：若你于出牌阶段至少杀死一名角色，在此回合结束后你可以执行一个额外的回合，且该回合你获得你杀死角色的所有技能，直到该回合结束。
]]--
--player:askForSkillInvoke("kuilei", data)
sgs.ai_skill_invoke["kuilei"] = function(self, data)
	local record = self.player:getTag("KuileiSkills"):toString()
	local skillnames = record:split("+")
	local value = 0
	for _,skillname in ipairs(skillnames) do
		if skillname == "benghuai" then
			value = value - 10
		elseif skillname == "wumou" then
			value = value - 6
		elseif string.find("shiyong|yaowu|wuyan|noswuyan", skillname) then
			value = value - 1
		elseif string.find(sgs.priority_skill, skillname) then
			value = value + 4
		else
			for _,skill in ipairs(sgs.ai_skills) do
				if skill.name == skillname then
					value = value + 1
					break
				end
			end
		end
	end
	return value > 0
end

sgs.ai_ajustdamage_from.jihun = function(self, from, to, card, nature)
	if card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
	then
		return from:getMark("@hun")
	end
end

sgs.ai_chaofeng["Mordekaiser"] = 1

local jianshen_skill = {}
jianshen_skill.name = "jianshen"
table.insert(sgs.ai_skills, jianshen_skill)
jianshen_skill.getTurnUseCard = function(self,inclusive)
	if self.player:getMark("Forbidjianshen-PlayClear") > 0 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	
	local slash_card
	
	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("Slash") then
			local shouldUse = true

			if shouldUse then
				slash_card = card
				break
			end
			
		end
	end

	if slash_card then
		local suit = slash_card:getSuitString()
		local number = slash_card:getNumberString()
		local card_id = slash_card:getEffectiveId()
		local card_str = ("archery_attack:jianshen[%s:%s]=%d"):format(suit, number, card_id)
		local archery_attack = sgs.Card_Parse(card_str)
		
		assert(archery_attack)

		return archery_attack
	end
end
sgs.ai_card_priority.jianshen = function(self,card,v)
	if card:isKindOf("ArcheryAttack")
	then return 6 end
end

sgs.jianshen_keep_value = {
	Slash = 4.2,
}

function sgs.ai_cardneed.jianshen(to, card)
	return card:isKindOf("Slash")
end

sgs.ai_skill_use["@@zhuanzhu"] = function(self, prompt)
	local card = self.player:getTag("zhuanzhu"):toCardUse().card
	local targets = {}
	local players = sgs.QList2Table(self.room:getAllPlayers())
	self:sort(players, "defense")
	for _, player in ipairs(players) do
		if player:hasFlag("zhuanzhu") then
			if self:aoeIsEffective(card,player,self.player) and self:isFriend(player) and not self:needToLoseHp(player, self.player, card) then
				table.insert(targets, player:objectName())
			end
			if #targets >= self.player:getHp() then
				break
			end
		end
	end
	if #targets == 0 then return "." end
	return string.format("#zhuanzhuCard:.:->%s", table.concat(targets, "+"))
end

sgs.ai_card_intention.zhuanzhuCard = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		local intention = -80
		sgs.updateIntention(from, to, intention)
	end
end



local yingyan_skill = {}
yingyan_skill.name = "yingyan"
table.insert(sgs.ai_skills, yingyan_skill)
yingyan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if not self.player:hasUsed("#yingyanCard") then
		return sgs.Card_Parse("#yingyanCard:.:")
	end
end

sgs.ai_skill_use_func["#yingyanCard"] = function(card, use, self)
	self:updatePlayers()
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	local acard = sgs.Card_Parse("#yingyanCard:.:")
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["yingyanCard"] = 3
sgs.ai_use_value["yingyanCard"] = 1
sgs.ai_card_intention["yingyanCard"] = 40

sgs.ai_skill_choice.Mohe = function(self, choices)
	local choices_table = choices:split("+")
	return choices_table[math.random(1, #choices_table)]
end

local Zhongli_skill = {}
Zhongli_skill.name = "Zhongli"
table.insert(sgs.ai_skills, Zhongli_skill)
Zhongli_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if not self.player:hasUsed("#ZhongliCard") then
		return sgs.Card_Parse("#ZhongliCard:.:")
	end
end

sgs.ai_skill_use_func["#ZhongliCard"] = function(card, use, self)
	self:updatePlayers()
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	if slashcount>0 then
		local slash = self:getCard("Slash")
		if slash then
			local dummy_use = self:aiUseCard(slash, dummy(true))
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					for _, card in ipairs(cards) do
						if self:getCardsNum("Slash") > 1 then
							use.card = sgs.Card_Parse("#ZhongliCard:" .. card:getId() .. ":")
							if use.to then
								use.to:append(p)
							end
							return
						elseif not card:isKindOf("Slash") then
							use.card = sgs.Card_Parse("#ZhongliCard:" .. card:getId() .. ":")
							if use.to then
								use.to:append(p)
							end
							return
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_priority["ZhongliCard"] = 3
sgs.ai_use_value["ZhongliCard"] = 1
sgs.ai_card_intention["ZhongliCard"] = 40
sgs.ai_use_priority["ZhongliCard"] = sgs.ai_use_priority.Slash + 1

sgs.ai_ajustdamage_from.baotou = function(self, from, to, card, nature)
	if from and card and card:isKindOf("Slash") and not beFriend(to, from)
	then
		return 1
	end
end

sgs.ai_skill_cardask["@baotou-hur"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then return "." end
	if self:cantDamageMore(self.player,target) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then return "$" .. card:getEffectiveId() end
	end
	return "."
end
sgs.ai_cardneed.baotou = sgs.ai_cardneed.slash
sgs.ai_cardneed.juji = sgs.ai_cardneed.slash
sgs.juji_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5.2,	
}
sgs.ai_canliegong_skill.juji = function(self, from, to)
	return not to:inMyAttackRange(from)
end

sgs.ai_cardneed.qiangpao = sgs.ai_cardneed.slash
function sgs.ai_skill_invoke.jiaohuo(self, data)
	local damage = data:toDamage()
	local enemynum = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(damage.to)) do
		if damage.to:distanceTo(p) <= 1 and self:isEnemy(p) then
			enemynum = enemynum + 1
		end
	end
	if enemynum < 1 then return false end
	return true
end

sgs.ai_skill_playerchosen.jiaohuo = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then table.insert(tos, target) end
	end 
	
	if #tos > 0 then
		tos = self:SortByAtomDamageCount(tos, self.player, sgs.DamageStruct_Fire, nil)
		return tos[1]
	end
end

sgs.ai_playerchosen_intention.jiaohuo = function(self, from, to)
	sgs.jiaohuo_target = to
	sgs.updateIntention(from, to , 10)
end

sgs.ai_view_as.wujijian = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:wujijian[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local wujijian_skill = {}
wujijian_skill.name = "wujijian"
table.insert(sgs.ai_skills, wujijian_skill)
wujijian_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local tc_card
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard")
			and not isCard("ExNihilo", card, self.player)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
			tc_card = card
			break
		end
	end

	if tc_card then
		local suit = tc_card:getSuitString()
		local number = tc_card:getNumberString()
		local card_id = tc_card:getEffectiveId()
		local card_str = ("slash:wujijian[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.wujijian(to, card)
	return to:getHandcardNum() < 3 and card:isKindOf("TrickCard")
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|wujijian"


local mingxiang_skill = {}
mingxiang_skill.name = "mingxiang"
table.insert(sgs.ai_skills,mingxiang_skill)
mingxiang_skill.getTurnUseCard = function(self)
	if #self.enemies<=0 then return end
	return sgs.Card_Parse("#mingxiangCard:.:")
end

sgs.ai_skill_use_func["#mingxiangCard"] = function(card,use,self)
	local slashcount = self:getCardsNum("Slash")-1
	if slashcount<=0 then return end
	local slash = self:getCard("Slash")
	if not slash then return end
	local dummy_use = dummy()
	if slash then self:useBasicCard(slash,dummy_use) end
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
end
sgs.ai_use_priority["mingxiangCard"] = sgs.ai_use_priority.Slash+0.1
local huangwu_skill={}
huangwu_skill.name="huangwu"
table.insert(sgs.ai_skills,huangwu_skill)
huangwu_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards) do
		if acard:isKindOf("Slash") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
			if self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = self:aiUseCard(acard, dummy(true))
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack + 0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("fire_attack:huangwu[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.huangwu = function(to, card, self)
	return to:getHandcardNum() >= 2 and card:isKindOf("Slash")
end

sgs.ai_skill_invoke.lol_lingti = function(self, data)
	if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() >= 1) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_to.lol_lingti = function(self, from, to, card, nature)
	if to:getMark("bsyz") > 0
	then
		return -99
	end
end


sgs.ai_skill_invoke.nuhuo = function(self, data)
	if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() >= 1) then
		return false
	end
	return true
end
local shenghua_skill = {}
shenghua_skill.name = "shenghua"
table.insert(sgs.ai_skills, shenghua_skill)
shenghua_skill.getTurnUseCard = function(self)
	if self.player:hasFlag("shenghuaBC") and self.player:hasFlag("shenghuaEC") and self.player:hasFlag("shenghuaTC") then return end
	return sgs.Card_Parse("#shenghuaCard:.:")
end

sgs.ai_skill_use_func["#shenghuaCard"] = function(card, use, self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	if slashcount>0 then
		local slash = self:getCard("Slash")
		if slash then
			self.player:setFlags("slashNoDistanceLimit")
			local dummy_use = self:aiUseCard(slash, dummy(true))
			self.player:setFlags("-slashNoDistanceLimit")
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if not self.player:hasFlag("shenghuaBC") and not self.player:inMyAttackRange(p) then
						for _, card in ipairs(cards) do
							if card:isKindOf("BasicCard") then
								if self:getCardsNum("Slash") > 1 then
									use.card = sgs.Card_Parse("#shenghuaCard:" .. card:getId() .. ":")
									return
								elseif not card:isKindOf("Slash") then
									use.card = sgs.Card_Parse("#shenghuaCard:" .. card:getId() .. ":")
									return
								end
							end
						end
					end
				end

				if not self.player:hasFlag("shenghuaTC") then
					for _, card in ipairs(cards) do
						if card:isKindOf("TrickCard") then
							use.card = sgs.Card_Parse("#shenghuaCard:" .. card:getId() .. ":")
							return
						end
					end
				end
				
				for _, p in sgs.qlist(dummy_use.to) do
					if self:isEnemy(p) and not self:cantDamageMore(self.player, p) then
						for _, card in ipairs(cards) do
							if card:isKindOf("EquipCard") then
								use.card = sgs.Card_Parse("#shenghuaCard:" .. card:getId() .. ":")
								return
							end
						end
					end
				end
			end
		end
	end
end
sgs.ai_use_priority["shenghuaCard"] = sgs.ai_use_priority.Slash + 1

sgs.ai_canliegong_skill.shenghua = function(self, from, to)
	return from:hasFlag("shenghuaTCdww")
end

sgs.hit_skill = sgs.hit_skill .. "|shenghua"
sgs.ai_cardneed.shenghua = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.shenghua = function(self, from, to, card, nature)
	if from and card and (card:isKindOf("Slash")) and from:hasFlag("shenghuaEC")
	then
		return 1
	end
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|jingxi"
 
sgs.ai_skill_playerchosen.jingxi = function(self, targets)
	local first, second
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _, enemy in ipairs(targets) do
		if not self:isFriend(enemy) and enemy:isAlive() then
			if sgs.ai_role[enemy:objectName()] == "renegade" then second = enemy
			elseif sgs.ai_role[enemy:objectName()] ~= "renegade" and not first then first = enemy
			end
		end
	end
	return first or second
end

sgs.ai_skill_invoke.lol_fushi = function(self, data)
	local damage = data:toDamage()
	local target = nil
	if self.player:objectName() == damage.from:objectName() then
		target = damage.to
	elseif self.player:objectName() == damage.to:objectName() then
		target = damage.from
	end
	if self:isFriend(target) then
		return false
	elseif target:getHandcardNum() == 0 then
		return false
	end
	return true
end
sgs.ai_use_revises.shenyan = function(self,card,use)
	if card:isKindOf("Slash") and self.player:hasFlag("shenyantar") then
		card:setFlags("Qinggang")
	end
end
sgs.ai_skill_invoke.shenyan = function(self, data)
	if self.player:isSkipped(sgs.Player_Play) then return false end
	if self:needBear() then return false end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	self:sort(self.enemies,"hp")
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and self:isGoodTarget(enemy, self.enemies, card) then
					if getCardsNum("Jink", enemy) < 1 or self.player:getCards("he"):length() > 4 then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
	end		
	if (slashtarget) > 0 then
		self:speak("shenyan")
		return true
	end
	return false
end

function sgs.ai_cardneed.shenyan(to, card, self)
	local slash_num = 0
	local target
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	local cards = to:getHandcards()
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end	  
		end
	end
	
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if to:canSlash(enemy) and not self:slashProhibit(slash ,enemy) and self:slashIsEffective(slash, enemy) and self:getDefenseSlash(enemy) <= 2 then
			target = enemy
			break
		end
	end
	
	if need_slash and target and isCard("Slash", card, to) then return true end  
end

sgs.ai_skill_use["@@bihu"] = function(self, prompt)
	self:sort(self.friends_noself, "handcard")
	local cards = sgs.QList2Table(self.player:getCards("he"))

	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	local ecards = self.player:getCards("e")
	ecards = sgs.QList2Table(ecards)

	for _, ecard in ipairs(ecards) do
		if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
			table.insert(equips, ecard)
		end
	end

	if #equips == 0 then return "." end

	local target
	self:sort(self.friends,"defense")
	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and not sgs.isLordHealthy() and not self.player:isLord() and not hasBuquEffect(lord)
		and not (lord:getHp() >= getBestHp(lord) and lord:getHp() > 1) then 
			target = lord
	else
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend) and not hasBuquEffect(friend) then
				target = friend
				break 
			end
		end	
	end

	if target then
		return "#bihuCard:" .. equips[1]:getId() .. ":->" .. target:objectName()
	end
	return "."
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|bihu"
sgs.ai_cardneed.bihu = sgs.ai_cardneed.equip


sgs.ai_ajustdamage_to["@bihu"] = function(self, from, to, card, nature)
	if to:getMark("@bihu") > 0
	then
		return -99
	end
end
sgs.ai_ajustdamage_from.langke = function(self, from, to, card, nature)
	if from:getMark("@lang") >= 4 and not beFriend(to,from)
	then
		return 1
	end
end



sgs.ai_skill_invoke["langkea"] = true
sgs.ai_skill_invoke["langkeb"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local from = damage.from
	if self:isFriend(target) then
		return false
	elseif self:cantDamageMore(from,target) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.fengbi = function(self, from, to, card, nature)
	if (from:getMark("feng") > 0 or (card and card:hasFlag("fengbiSlash")))
	then
		return 1
	end
end
sgs.ai_cardneed.fengbi = sgs.ai_cardneed.slash

function sgs.ai_cardsview.chongfeng(self,class_name,player)
	local slash = dummyCard("slash")
	slash:setSkillName("chongfeng")
	local newcards = {}
	for _,c in sgs.list(sgs.ais[player:objectName()]:addHandPile())do
		if isCard("ExNihilo",c,player) and player:getPhase()<=sgs.Player_Play
		or isCard("Peach",c,player) then continue end
		if isCard("Slash",c,player) then return end
		table.insert(newcards,c)
	end
	sgs.ais[player:objectName()]:sortByKeepValue(newcards,nil,true)
	local use_cards = {}
	for _,h in sgs.list(newcards)do
		for _,h2 in sgs.list(newcards)do
			if h:getEffectiveId() == h2:getEffectiveId() or table.contains(use_cards, h:getEffectiveId())  then continue end
			if h:getSuit() == h2:getSuit() then
				if slash:subcardsLength()<2	then
					table.insert(use_cards,h:getEffectiveId())
					slash:addSubcard(h) 
				end
			end
		end
	end
	if slash:subcardsLength()>=2
	then return slash:toString() end
end
local chongfeng_skill = {}
chongfeng_skill.name = "chongfeng"
table.insert(sgs.ai_skills, chongfeng_skill)
chongfeng_skill.getTurnUseCard = function(self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player)) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player)) then

						local card_str = ("slash:chongfeng[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local slash = sgs.Card_Parse(card_str)
						local dummy_use = self:aiUseCard(slash, dummy())
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("slash:chongfeng[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
			
		return slash
	end
end

sgs.ai_skill_invoke.wuwei = function(self, data)
	local damage = data:toDamage()
	local target = nil
	if self.player:objectName() == damage.from:objectName() then
		target = damage.to
	elseif self.player:objectName() == damage.to:objectName() then
		target = damage.from
	end
	if self:isFriend(target) then
		return false
	elseif target:hasSkill("wushuang") or target:hasSkill("wuyan") or target:hasSkill("noswuyan") then
		return false
	elseif target:hasSkill("wujijian") or target:hasSkill("wuhun") or target:hasSkill("duanchang") then
		return false
	elseif self:getCardsNum("Slash", self.player) <= 1 then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@wuweidis"] = function(self, data, pattern)
	local target = data:toPlayer()
	if not target then return "." end
	local hcards = self.player:getCards("h")
	hcards = sgs.QList2Table(hcards)
	self:sortByUseValue(hcards, true)
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("wuwei")
		duel:deleteLater()
	for _, hcard in ipairs(hcards) do
		local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use.to:contains(target) then
			return "$" .. hcard:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_use["@@zhouchu"] = function(self, prompt)
	local zhouchu_target = nil
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(p, nil, false) and self.player:inMyAttackRange(p) then
			targets:append(p)
		end
	end
	if targets:length() == 0 then return "." end
	zhouchu_target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
	if not zhouchu_target then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) and self:isFriend(zhouchu_target)) then
			return "#zhouchuCard:" .. card:getEffectiveId() .. ":->" .. zhouchu_target:objectName()
		end
	end
	return "."
end

sgs.ai_card_intention.zhouchuCard = sgs.ai_card_intention.Slash

sgs.ai_need_damaged.zhouchu = function(self, attacker, player)
	if not player:hasSkill("zhouchu") then return false end
	local peaches = getCardsNum("Peach", player)
	if peaches >= player:getLostHp() and peaches > 0 then return true end
	if self.player:objectName() == player:objectName() and player:getHp() > 1 then
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		for _, target in ipairs(self.enemies) do
			if self:isEnemy(target) and self:slashIsEffective(slash, target) and not self:needToLoseHp(target, self.player,slash)
				and getCardsNum("Jink", target, self.player) < 1 and (target:getHp() == 1 or self:hasHeavyDamage(player, slash, target) and target:getHp() == 2) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.juewang = function(self, data)
	self:sort(self.friends, "hp")
	self:sort(self.enemies, "hp")
	local up = 0
	local down = 0
	
	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (friend:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			if friend:isWounded() then up = up + 5 end
		end
		if self:needToLoseHp(friend, nil, nil, true) then down = down + 5 end
		if self:needToLoseHp(friend, nil, nil, true, true) and friend:isWounded() then up = up - 5 end
		
		if self:isWeak(friend) then
			if friend:isWounded() then up = up + 10 + (friend:isLord() and 20 or 0) end
			down = down - 10 - (friend:isLord() and 40 or 0)
			if friend:getHp() <= 1 and not friend:hasSkill("buqu") or friend:getPile("buqu"):length() > 4 then
				down = down - 20 - (friend:isLord() and 40 or 0)
			end
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (enemy:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then 
			down = down + 10
			if enemy:isWounded() then up = up - 10 end
		end
		if self:needToLoseHp(enemy, nil, nil, true) then down = down - 5 end
		if self:needToLoseHp(enemy, nil, nil, true, true) and enemy:isWounded() then up = up - 5 end
		
		if self:isWeak(enemy) then
			if enemy:isWounded() then up = up - 10 end
			down = down + 10
			if enemy:getHp() <= 1 and not enemy:hasSkill("buqu") then
				down = down + 10 + ((enemy:isLord() and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 then 
		return true
	elseif up > 0 then
		return false
	end
	return true
end
sgs.ai_skill_cardask["@juewangdis"] = function(self, data, pattern, target)
	if hasZhaxiangEffect(self.player) then return "." end
	if not self:needToLoseHp(self.player, nil, nil, true) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_invoke.shihuo = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local from = damage.from
	if self:isFriend(target) then
		return false
	elseif not damage.to:faceUp() then
		return false
	elseif self:damageIsEffective(damage.to, sgs.DamageStruct_Fire) then
		return not self:cantDamageMore(self.player, damage.to) and self:toTurnOver(damage.to,0,"shihuo")
	end
	return false
end
sgs.ai_ajustdamage_from.shihuo = function(self, from, to, card, nature)
	if from:getMark("@huo") >= 4 and not beFriend(to, from)
	then
		return 1
	end
end
function sgs.ai_cardneed.shihuo(to,card)
	return card:getTypeId()==sgs.Card_TypeTrick
end

sgs.ai_view_as.quexie = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:getSuit() == sgs.Card_Diamond and not card:hasFlag("using") then
		return ("slash:quexie[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local quexie_skill = {}
quexie_skill.name = "quexie"
table.insert(sgs.ai_skills, quexie_skill)
quexie_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local tc_card
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive) then
			tc_card = card
			break
		end
	end

	if tc_card then
		local suit = tc_card:getSuitString()
		local number = tc_card:getNumberString()
		local card_id = tc_card:getEffectiveId()
		local card_str = ("slash:quexie[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

sgs.ai_skill_playerchosen.quexie     = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if friend:getHp() < getBestHp(friend) then
				return friend
			end
		end
	end


	return nil
end

sgs.ai_card_priority.quexie = function(self,card)
	if card:getSkillName()=="quexie"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end
function sgs.ai_cardneed.quexie(to, card)
	return to:getHandcardNum() < 3 and card:getSuit() == sgs.Card_Diamond
end

local xieli_skill = {}
xieli_skill.name = "xieli"
table.insert(sgs.ai_skills,xieli_skill)
xieli_skill.getTurnUseCard = function(self)
	if #self.friends_noself<=0 then return end
	return sgs.Card_Parse("#xieliCard:.:")
end

sgs.ai_skill_use_func["#xieliCard"] = function(card,use,self)
	local target
	self:sort(self.friends,"defense")
	local AssistTarget = self:AssistTarget()
	if AssistTarget then target = AssistTarget end
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			target = friend
			break
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_invoke.xieli = function(self, data)
	local asked = data:toStringList()
	if sgs.xielisource then return false end
	return true
end

sgs.ai_choicemade_filter.skillInvoke.xieli = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.xielisource = player
	end
end


sgs.ai_choicemade_filter.cardResponded["@xieli-jink"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		sgs.updateIntention(player, sgs.xielisource, -80)
		sgs.xielisource = nil
	end
end

sgs.ai_skill_cardask["@xieli-jink"] = function(self)
	if not self.room:getLord() then return "." end
	if not sgs.xielisource then return "." end
	if not self:isFriend(sgs.xielisource) then return "." end
	if self:needBear() then return "." end
	local bgm_zhangfei = self.room:findPlayerBySkillName("dahe")
	if bgm_zhangfei and bgm_zhangfei:isAlive() and sgs.xielisource:hasFlag("dahe") then
		for _, card in ipairs(self:getCards("Jink")) do
			if card:getSuit() == sgs.Card_Heart then
				return card:toString()
			end
		end
		return "."
	end
	return self:getCardId("Jink") or "."
end

sgs.ai_choicemade_filter.cardResponded["@xieli-slash"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		sgs.updateIntention(player, sgs.xielisource, -80)
		sgs.xielisource = nil
	end
end

sgs.ai_skill_cardask["@xieli-slash"] = function(self, data)
	if not sgs.xielisource or not self:isFriend(sgs.xielisource) then return "." end
	if self:needBear() then return "." end

	local xielitargets = {}
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:getMark("@xieli") > 0 then
			if self:isFriend(player) and not (self:needToLoseHp(player, sgs.xielisource, nil)) then return "." end
			table.insert(xielitargets, player)
		end
	end

	if #xielitargets == 0 then
		return self:getCardId("Slash") or "."
	end

	self:sort(xielitargets, "defenseSlash")
	local slashes = self:getCards("Slash")
	for _, slash in ipairs(slashes) do
		for _, target in ipairs(xielitargets) do
			if not self:slashProhibit(slash, target, sgs.xielisource) and self:slashIsEffective(slash, target, sgs.xielisource) then
				return slash:toString()
			end
		end
	end
	return "."
end

function sgs.ai_cardsview_valuable.xielidest(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if player:hasFlag("xieli_using") then return end
	if player:hasFlag("Global_xieliFailed") then return end
	return "#xielidestCard:.:"..name
end
sgs.ai_choicemade_filter["xielidestCard"] = function(self,player,carduse)
	sgs.xielisource = player
end

sgs.ai_skill_cardask["@@xieli"] = function(self, data, pattern)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
        local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,h in sgs.list(cards)do
            if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
            then return h:getEffectiveId() end
            if h:isKindOf(pattern)
            then return h:getEffectiveId() end
        end
        return self:getCardId(pattern)
    end
    return "."
end

sgs.ai_choicemade_filter.cardResponded["@@xieli"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		if not sgs.xielisource then return end
		sgs.updateIntention(player, sgs.xielisource, -80)
		sgs.xielisource = nil
	end
end

sgs.ai_ajustdamage_from.cangfei  = function(self, from, to, card, nature)
	if to and to:getMark("@fei") > 0 and card and card:isKindOf("Slash") then
		return 1
	end
end
local huanyin_skill = {}
huanyin_skill.name = "huanyin"
table.insert(sgs.ai_skills, huanyin_skill)
huanyin_skill.getTurnUseCard = function(self, inclusive)
	local target
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	local dummy = self:aiUseCard(duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end

	if target then
		return sgs.Card_Parse("#huanyinCard:.:")
	else
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		local dummy = self:aiUseCard(slash)
		if dummy.card and dummy.to
			then
			for _,enemy in sgs.list(dummy.to)do
				target = enemy
				break
			end
		end
		if target then
			return sgs.Card_Parse("#huanyinCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#huanyinCard"] = function(card, use, self)
	local target
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	local dummy = self:aiUseCard(duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	else
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		local dummy = self:aiUseCard(slash)
		if dummy.card and dummy.to
			then
			for _,enemy in sgs.list(dummy.to)do
				target = enemy
				break
			end
		end
		if target then
			use.card = card
			if use.to then
				use.to:append(target)
			end
		end
	end
end
sgs.ai_skill_choice.huanyinCard = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "duel") then
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) and target:getMark("@cang") > 0 and self.player:hasSkill("cangfei") then
			return "duel"
		end
	end
	if table.contains(items, "slash") then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		local dummy_use = self:aiUseCard(slash, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) and target:getMark("@fei") > 0 and self.player:hasSkill("cangfei") then
			return "slash"
		end
	end
	if table.contains(items, "duel") then
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return "duel"
		end
	end
	if table.contains(items, "slash") then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		local dummy_use = self:aiUseCard(slash, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return "slash"
		end
	end
	return items[math.random(1, #items)]
end


local shixue_skill = {}
shixue_skill.name= "shixue"
table.insert(sgs.ai_skills,shixue_skill)
shixue_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("shixueCard") then
		return sgs.Card_Parse("#shixueCard:.:")
	end
end
sgs.ai_skill_use_func["#shixueCard"] = function(card, use, self)
	local spadecard, cards
	cards = self.player:getCards("he")
	for _, card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Spade then
			spadecard = card
			break
		end
	end
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			if spadecard then
				use.card = sgs.Card_Parse("#shixueCard:" .. spadecard:getId().. ":")
				if use.to then
					use.to:append(enemy)
				end
				break
			end
		end
	end
end
sgs.ai_use_value["shixueCard"] = 5.5
sgs.ai_card_intention["shixueCard"] = 80
sgs.dynamic_value.damage_card["shixueCard"] = true
sgs.shixue_keep_value = {
	Peach = 6,
	Jink = 5.1,
	OffensiveHorse = 5
}
sgs.shixue_suit_value = {
	spade = 5,
}

sgs.ai_ajustdamage_from.ningshi = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and not beFriend(to, from)
	then
		return 1
	end
end
sgs.ai_skill_invoke.ningshi = function(self, data)
	local damage = data:toDamage()
	if damage and damage.to and self:isEnemy(damage.to) then
		if self:isWeak(self.player) then return false end
		if self:damageIsEffective(damage.to, sgs.card_damage_nature[damage.card:getClassName()]) then
			return not self:cantDamageMore(self.player, damage.to)
		end
		if self:isWeak(damage.to) then return true end
		if self.player:getHp() > getBestHp(self.player) then return true end
	end
	return false
end
sgs.ai_cardneed.ningshi = sgs.ai_cardneed.slash

local yongbao_skill = {}
yongbao_skill.name= "yongbao"
table.insert(sgs.ai_skills,yongbao_skill)
yongbao_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#yongbaoCard:.:")
end

sgs.ai_skill_use_func["#yongbaoCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self.player:getMark("@yongbao")>=enemy:getHp() and not self:cantDamageMore(self.player,enemy)
		then
			use.card = sgs.Card_Parse("#yongbaoCard:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_value["yongbaoCard"] = 2.5
sgs.ai_card_intention["yongbaoCard"] = 80
sgs.dynamic_value.damage_card["yongbaoCard"] = true

local cannue_skill = {}
cannue_skill.name = "cannue"
table.insert(sgs.ai_skills, cannue_skill)
cannue_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#cannueCard:.:")
end

sgs.ai_skill_use_func["#cannueCard"] = function(card, use, self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	if slashcount>0 then
		local slash = self:getCard("Slash")
		if slash then
			local dummy_use = self:aiUseCard(slash, dummy(true))
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if self:isEnemy(p) and not self:cantDamageMore(self.player, p) and (getCardsNum("Jink", p, self.player) < 1 or self:canLiegong(p, self.player)) then
						local to_use = {}
						for _, card in ipairs(cards) do
							if self:getUseValue(card) < 5 then
								table.insert(to_use, card:getId())
								
							end
						end
						if self:needToThrowArmor(self.player) then table.insert(to_use, self.player:getArmor():getId()) end
						if #to_use > 0 then
							use.card = sgs.Card_Parse("#cannueCard:"..table.concat(to_use, "+") ..":")
							return
						end
					end
				end
			end
		end
	end
end
sgs.ai_use_priority["cannueCard"] = sgs.ai_use_priority.Slash + 1
sgs.ai_ajustdamage_from.cannue = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash")
	then
		return from:getMark("cannue")
	end
end
sgs.ai_skill_playerchosen.manheng = sgs.ai_skill_playerchosen.zero_card_as_slash

local lumang_skill = {}
lumang_skill.name= "lumang"
table.insert(sgs.ai_skills,lumang_skill)
lumang_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("lumangCard") then
		return sgs.Card_Parse("#lumangCard:.:")
	end
end
sgs.ai_skill_use_func["#lumangCard"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			if self.player:distanceTo(enemy) <= self.player:getAttackRange() and self.player:getHp() <= enemy:getHp() and self.player:getHp() > 1 and (not self:cantDamageMore(self.player, enemy) or self.player:getMark("huanghun") == 0) then
				use.card = sgs.Card_Parse("#lumangCard:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			if self.player:distanceTo(enemy) <= self.player:getAttackRange() and self.player:getHp() <= enemy:getHp() and self.player:getHp() > 1 then
				use.card = sgs.Card_Parse("#lumangCard:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			if self.player:distanceTo(enemy) <= self.player:getAttackRange() and self.player:getHp() > 1 then
				use.card = sgs.Card_Parse("#lumangCard:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end
sgs.ai_use_value["lumangCard"] = 2.5
sgs.ai_card_intention["lumangCard"] = 80
sgs.dynamic_value.damage_card.lumangCard = true
sgs.lumang_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 4
}

sgs.ai_skill_invoke.huanghun = function(self, data)
	if self.player:getJudgingArea():length() > 1 or self:isWeak() then return true end
	if ((self.player:containsTrick("supply_shortage") and self.player:getHp() > self.player:getHandcardNum() and self.player:getHp() <= 2) or
		(self.player:containsTrick("indulgence") and self.player:getHandcardNum() > self.player:getHp()-1)) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.Thornmail = function(self, data)
	local mode = self.room:getMode()
	if mode:find("_mini_41") or mode:find("_mini_46") then return true end
	local damage = data:toDamage()
	if self:needToLoseHp(damage.from, self.player,nil) then
		if self:isFriend(damage.from) then
			sgs.ai_Thornmail_effect = string.format("%s_%s_%d", self.player:objectName(), damage.from:objectName(), sgs.turncount)
			return true
		end
		return false
	end
	return not self:isFriend(damage.from) and self:canAttack(damage.from)
end

-- sgs.ai_need_damaged.Thornmail = function(self, attacker, player)
-- 	if not attacker then return end
-- 	if not attacker:getArmor():isKindOf("Thornmail") and self:getDamagedEffects(attacker, player) then return self:isFriend(attacker, player) end
-- 	if self:isEnemy(attacker) and attacker:getHp() + attacker:getHandcardNum() <= 3
-- 		and not (self:hasSkills(sgs.need_kongcheng .. "|buqu", attacker) and attacker:getHandcardNum() > 1) and self:isGoodTarget(attacker, self:getEnemies(attacker)) then
-- 		return true
-- 	end
-- 	return false
-- end

function Thornmail_discard(self, discard_num, min_num, optional, include_equip, skillName)
	local Thornmail = self.room:getArmor():isKindOf("Thornmail")
	if Thornmail and (not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, Thornmail)) then return {} end
	if Thornmail and self:needToLoseHp(self.player, Thornmail) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return {} end
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == 2 then break end
		end
	end
	if #to_discard < 2 then return {}
	else
		return to_discard
	end
end

sgs.ai_skill_discard.Thornmail = function(self, discard_num, min_num, optional, include_equip)
	return Thornmail_discard(self, discard_num, min_num, optional, include_equip, "Thornmail")
end

-- function sgs.ai_slash_prohibit.Thornmail(self, from, to)
-- 	if self:isFriend(from, to) then return false end
-- 	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
-- 	if from:hasFlag("NosJiefanUsed") then return false end
-- 	return from:getHandcardNum() + from:getHp() < 4
-- end

sgs.ai_choicemade_filter.skillInvoke.Thornmail = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not self:needToLoseHp(damage.from, player) then
				sgs.updateIntention(damage.to, damage.from, 40)
			end
		elseif self:canAttack(damage.from) then
			sgs.updateIntention(damage.to, damage.from, -40)
		end
	end
end

sgs.ai_skill_invoke.WarmongArmor = function(self, data)
	if self.player:getHp() > 2 and self.player:getHandcardNum() < 2 then
		return false
	end
	return true
end

sgs.ai_skill_invoke.zhimang = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local from = damage.from
	if self:isFriend(target) then
		return false
	end
	return true
end
mogu_skill = {}
mogu_skill.name = "mogu"
table.insert(sgs.ai_skills, mogu_skill)
mogu_skill.getTurnUseCard          = function(self, inclusive)
	local source = self.player
	if not (source:getHandcardNum() >= 2 or source:getHandcardNum() > source:getHp()) then return end
	--if self:getOverflow() <= 0 and not source:isWounded() then return end
	if source:hasUsed("#moguCard") then return end
	return sgs.Card_Parse("#moguCard:.:")
end

sgs.ai_skill_use_func["#moguCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local needed = {}
	local suit = {}
	for _, acard in ipairs(cards) do
		if self.player:getPile("muthroom"):length() > 0 then
			for _,card_id in sgs.qlist(self.player:getPile("muthroom")) do
				if acard:getSuit() == sgs.Sanguosha:getCard(card_id):getSuit() or table.contains(suit, acard:getSuitString()) then continue end
				table.insert(needed, acard:getEffectiveId())
				table.insert(suit, acard:getSuitString())
			end
		else
			if table.contains(suit, acard:getSuitString()) then continue end
			table.insert(needed, acard:getEffectiveId())
			table.insert(suit, acard:getSuitString())
		end
	end
	if #needed > 0 then
		use.card = sgs.Card_Parse("#moguCard:" .. table.concat(needed, "+") .. ":")
		return
	end
end
sgs.ai_skill_invoke["moguhit"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return false
	end
	return (self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(target, self.player)) and self:canDamage(target,self.player,nil)
end
sgs.ai_cardneed.tengyun = sgs.ai_cardneed.slash
sgs.ai_cardneed.jingang = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.jingang = function(self, data)
	local damage = data:toDamage()
	if self:hasSkills(sgs.lose_equip_skill, damage.to) then
		return self:isFriend(damage.to) and not self:isWeak(damage.to)
	end
	local benefit = (damage.to:getArmor() and self:needToThrowArmor(damage.to))
	if self:isFriend(damage.to) then return benefit end
	return not benefit
end
sgs.ai_skill_choice.jingang = function(self, choices)
	return "movearmor"
end

sgs.ai_cardneed.moying = sgs.ai_cardneed.bignumber
sgs.ai_skill_use["@@moying"] = function(self, prompt, method)
	if #self.enemies > 0 then
		local mymaxcard = self:getMaxCard()
		if mymaxcard then
			local mymaxpoint = mymaxcard:getNumber()
			self:sort(self.enemies, "handcard")
			self.enemies = sgs.reverse(self.enemies)
			local targets = {}
			for _,enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					local maxcard = self:getMaxCard(enemy)
					local maxpoint = maxcard and maxcard:getNumber() or 4
					if mymaxpoint > maxpoint then
						table.insert(targets, enemy)
					end
				end
			end
			local target = nil
			if #targets > 0 then
				for _,enemy in ipairs(targets) do
					if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
						if not self:cantbeHurt(enemy) then
							target = enemy
							break
						end
					end
				end
				target = target or self.enemies[#self.enemies]
			end
			if target then
				local card_str = "#moyingCard:"..mymaxcard:getEffectiveId()..":->"..target:objectName()
				return card_str
			end
		end
	end
	return "."
end

local mengyan_skill = {}
mengyan_skill.name = "mengyan"
table.insert(sgs.ai_skills, mengyan_skill)
mengyan_skill.getTurnUseCard = function(self)
	if self.player:getMark("@mengyan") < 1 then return end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(enemy, 1) > 0
			and #self.enemies > 1 then
			sgs.ai_use_priority.mengyanCard = 8
			return sgs.Card_Parse("#mengyanCard:.:")
		end
	end
end
sgs.ai_skill_use_func["#mengyanCard"]=function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["mengyanCard"] = sgs.ai_use_priority.Slash + 0.1
local lol_jiushu_skill = {}
lol_jiushu_skill.name= "lol_jiushu"
table.insert(sgs.ai_skills,lol_jiushu_skill)
lol_jiushu_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("lol_jiushuCard") then
		return sgs.Card_Parse("#lol_jiushuCard:.:")
	end
end
sgs.ai_skill_use_func["#lol_jiushuCard"] = function(card, use, self)
	self:sort(self.friends_noself, "hp")
	for _,friend in ipairs(self.friends_noself) do
		if self.player:getHp() > friend:getHp() and self.player:getHp() > 1 then
			use.card = sgs.Card_Parse("#lol_jiushuCard:.:")
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
end
sgs.ai_use_value["lol_jiushuCard"] = 2.5
sgs.ai_card_intention["lol_jiushuCard"] = -80
sgs.ai_use_priority["lol_jiushuCard"] = 3
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lol_jiushu"
local guanzhu_skill = {}
guanzhu_skill.name= "guanzhu"
table.insert(sgs.ai_skills,guanzhu_skill)
guanzhu_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("guanzhuCard") then
		return sgs.Card_Parse("#guanzhuCard:.:")
	end
end
sgs.ai_skill_use_func["#guanzhuCard"] = function(card, use, self)
	self:sort(self.friends_noself, "hp")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local card
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Heart then
			card = c
			break
		end
	end
	if card then
		for _,friend in ipairs(self.friends_noself) do
			if self:canDraw(friend, self.player) then
				use.card = sgs.Card_Parse("#guanzhuCard:".. card:getId()..":")
				if use.to then
					use.to:append(friend)
				end
				return
			end
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Spade then
			card = c
			break
		end
	end
	if card and card:getSuit() == sgs.Card_Spade then
		for _,enemy in ipairs(self.enemies) do
			if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(enemy) and self:objectiveLevel(enemy) > 3  and self:canDamage(enemy,self.player,nil) then
				use.card = sgs.Card_Parse("#guanzhuCard:".. card:getId()..":")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	if self:getOverflow() > 0 then
		for _, c in ipairs(cards) do
			for _,friend in ipairs(self.friends_noself) do
				if self:canDraw(friend, self.player) then
					use.card = sgs.Card_Parse("#guanzhuCard:".. c:getId()..":")
					if use.to then
						use.to:append(friend)
					end
					return
				end
			end
		end
	end
end
sgs.ai_use_priority["guanzhuCard"] = 2
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|guanzhu"
lol_qiyuan_skill = {}
lol_qiyuan_skill.name = "lol_qiyuan"
table.insert(sgs.ai_skills, lol_qiyuan_skill)
lol_qiyuan_skill.getTurnUseCard = function(self)
	if self.player:getMark("@lol_qiyuan_l") < 1 then return end
	if (#self.friends <= #self.enemies and sgs.turncount > 2 and self.player:getLostHp() > 0) or (sgs.turncount > 1 and self:isWeak()) then
		return sgs.Card_Parse("#lol_qiyuanCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_qiyuanCard"] = function(card, use, self)
	use.card = card
	for i = 1, #self.friends do
		if use.to then use.to:append(self.friends[i]) end
	end
end
sgs.ai_card_intention["lol_qiyuanCard"] = -80
sgs.ai_use_priority["lol_qiyuanCard"] = 9.31
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lol_qiyuan"


sgs.ai_skill_invoke.lol_nuhuo = function(self, data)
	local peaches = 1 - self.player:getHp()

	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end
sgs.ai_can_damagehp.lol_nuhuo = function(self, from, card, to)
	if to:getMark("wjnh") > 0 and self:canLoseHp(from, card, to) then return true end
end

sgs.ai_getBestHp_skill.lol_nuhuo = function(owner)
	if owner:getMark("wjnh") > 0 and owner:getPhase() == sgs.Player_NotActive then
		return 0
	end
end

sgs.ai_cardneed.kuangnu = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.kuangnu = function(self, from, to, card, nature)
	if from:getLostHp() >= 3  and card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
	then
		return 1
	end
end
sgs.ai_canliegong_skill.kuangnu = function(self, from, to)
	return from:getLostHp() >= 4
end

sgs.ai_getBestHp_skill.kuangnu = function(owner)
	return owner:getMaxHp() - 1
end


shabing_skill = {}
shabing_skill.name = "shabing"
table.insert(sgs.ai_skills, shabing_skill)
shabing_skill.getTurnUseCard          = function(self, inclusive)
	local source = self.player
	if not (source:getHandcardNum() >= 2 or source:getHandcardNum() > source:getHp()) then return end
	--if self:getOverflow() <= 0 and not source:isWounded() then return end
	if source:hasUsed("#shabingCard") then return end
	return sgs.Card_Parse("#shabingCard:.:")
end

sgs.ai_skill_use_func["#shabingCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local needed = {}
	local suit = {}
	for _,card_id in sgs.qlist(self.player:getPile("soldier")) do
		if table.contains(suit, sgs.Sanguosha:getCard(card_id):getSuitString()) then continue end
		table.insert(suit, sgs.Sanguosha:getCard(card_id):getSuitString())
	end
	for _, acard in ipairs(cards) do
		if table.contains(suit, acard:getSuitString()) then continue end
		table.insert(needed, acard:getEffectiveId())
		table.insert(suit, acard:getSuitString())
	end
	if #needed > 0 then
		use.card = sgs.Card_Parse("#shabingCard:" .. table.concat(needed, "+") .. ":")
		return
	end
end


sgs.ai_skill_invoke.jinjun = true

function sgs.ai_cardsview_valuable.jinjun(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return nil end
	if player:getPhase() ~= sgs.Player_NotActive then return nil end
	if player:getPile("soldier"):isEmpty() then return nil end
	if player:hasFlag("Global_jinjunFailed") then return nil end
	return "#jinjunCard:.:"..name
end


sgs.ai_skill_playerchosen.liusha = function(self, targets)
	targets = sgs.QList2Table(targets)
	local target
	for _,enemy in ipairs(targets) do
		if enemy and self:isEnemy(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and enemy:faceUp() and self:toTurnOver(enemy, 0) then
			target= enemy
			break
		end
	end
	if target and math.random()<0.3 and not self:isWeak() then
		return target
	end
	return nil
end

sgs.ai_cardneed.xuechang = sgs.ai_cardneed.slash

sgs.ai_skill_choice.xuechang = function(self, choices, data)
	local damage = data:toDamage()
	local items = choices:split("+")
	if table.contains(items, "hurt") then
		if self:isEnemy(damage.to) and not self:isWeak() and self:damageIsEffective(damage.to, sgs.card_damage_nature[damage.card:getClassName()]) and not self:cantDamageMore(self.player, damage.to) then
			return "hurt"
		end
	end
	if table.contains(items, "reco") then
		if self:isWeak() or self.player:getHp() < getBestHp(self.player) or not self:damageIsEffective(damage.to, sgs.card_damage_nature[damage.card:getClassName()]) then
			return "reco"
		end
	end
	return "cancel"
end

sgs.ai_ajustdamage_from.InfinityEdge = function(self,from,to,slash,nature)
	if slash and slash:isKindOf("Slash") 
	then return 1 end
end
sgs.ai_ajustdamage_from.Deathcap = function(self,from,to,card,nature)
	if card and card:isKindOf("TrickCard") 
	then return 1 end
end