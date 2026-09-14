
function SmartAI:getMostWeakEnemyToDamage(self, targets, nature)
	local min = 100
	local target
	if not nature then nature = sgs.DamageStruct_Normal end
	for _,p in sgs.list(targets) do
		if self:isEnemy(p) and self:damageIsEffective(p, nature) and p:getHp() * 2 + p:getHandcardNum() < min then
			target = p
			min =  p:getHp() * 2 + p:getHandcardNum()
		end
	end
	return target
end

sgs.ai_skill_invoke.inovation_huanxing = function(self, data)
	local use = data:toCardUse()
	if not use or not use.from then return false end
	if self:isEnemy(use.from) then return true end
	return false
end

sgs.ai_skill_invoke.fushang = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.to then return false end
	if self:isFriend(damage.to) then
		local num = damage.to:getMark("@fushang")
		local last = damage.to:getMark("@fushang_time")
		if last == 1 then
			if self:isWeak(damage.to) and self:getCardsNum("Peach") == 0 then return false end
			if num >= damage.to:getLostHp() - 1 then return false end
			return true
		else
			return true
		end
	end
	return false
end

--skill guangyu
sgs.ai_skill_use["@@guangyu"] = function(self)
	local ids = self.player:property("guangyu"):toString():split("+")
	for _, id in ipairs(ids) do
		local card = sgs.Sanguosha:getCard(id)
		if not self.player:isCardLimited(card, sgs.Card_MethodUse) then
			local card_str = ("key_trick:guangyu[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), id)
			local ss = sgs.Card_Parse(card_str)
			local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
			self:useCardKeyTrick(ss, dummy_use)
			if dummy_use.card and not dummy_use.to:isEmpty() then
				return card_str .. "->" .. dummy_use.to:first():objectName()
			end
		end
	end
	return "."
end
sgs.ai_skill_invoke.guangyu = function(self, data)
	if self:isFriend(self.room:getCurrent()) then return true end
	return false
end

--skill xiyuan
sgs.ai_skill_invoke.xiyuan = function(self, data)
	if #self.friends_noself == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen.xiyuan = function(self, targets)
	for _,p in ipairs(self.friends_noself) do
		if not p:getGeneral2() and self:isWeak(p) then return p end
		if p:hasSkill("se_diangong") then return p end
	end
	return self.friends_noself[1]
end

--skill dingxin
sgs.ai_skill_choice["dingxin"] = function(self, choices, data)
	if self:getCardsNum("Peach") == 0 then return "dingxin_recover" end
	for _,p in sgs.list(self.room:getPlayers()) do
		if (p:getGeneralName() == "inovation_Nagisa" or p:getGeneral2Name() == "inovation_Nagisa") and (self.player:getRole() == p:getRole() or (self.player:getRole() == "lord" and p:getRole() == "loyalist")) then return "dingxin_revive" end
	end
	return "dingxin_recover"
end



--麻婆豆腐
function SmartAI:useCardMapoTofu(card, use) --need help 这个锦囊太复杂了。。。。。
	local targets = {}
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) <= 1 then table.insert(targets, p) end
	end
	if #targets == 0 then return end
	local f_target
	for _,target in ipairs(targets) do
		if self:isFriend(target) then
			if target:hasSkills(sgs.masochism_by_self_skill) then f_target = target end
			if target:hasSkills("inovation_Tianhuo") and target:getLostHp() > 0 then return target end
			local touma = self.room:findPlayerBySkillName("Huansha")
			local shirayuki = self.room:findPlayerBySkillName("SE_Zhandan")
			if ((touma and self:isFriend(touma)) or (shirayuki and self:isFriend(shirayuki))) and target:getLostHp() > 0 then return target end
		else
			if self.player:hasSkills(sgs.weak_killer_skill) and target:getLostHp() == 0 then f_target = target end
		end
	end
	if not f_target then
		for _,target in ipairs(targets) do
			if self:isFriend(target) and target:getLostHp() > 0 then
				f_target = target
			end
		end
	end
	if self.player:hasSkill("se_shouren") then
		for _,target in ipairs(targets) do
			if self:isEnemy(target) then
				f_target = target
			end
		end
	end
	if f_target then
		for _,v in ipairs(self.enemies) do
			if v:objectName() ~= f_target:objectName() then
				use.card = card
				if use.to and not (self.room:isProhibited(self.player, v, card) or self.room:isinovation_Akarin(self.player, v)) then use.to:append(v) end
				return
			end
		end
	end
end
sgs.ai_use_priority.MapoTofu = 10
sgs.ai_use_value.MapoTofu = 8
sgs.ai_keep_value.MapoTofu = 1.0
sgs.ai_card_intention.MapoTofu = 0

--KEY

function SmartAI:useCardKeyTrick(card, use)
	for _,v in ipairs(self.friends) do
		if v:getLostHp() > 0 and not v:containsTrick("key_trick") and not (self.room:isProhibited(self.player, v, card) or self.room:isinovation_Akarin(self.player, v)) then
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
	for _,v in ipairs(self.friends) do
		if not v:containsTrick("key_trick") and not (self.room:isProhibited(self.player, v, card) or self.room:isinovation_Akarin(self.player, v)) then
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
end
sgs.ai_use_priority.KeyTrick = 3
sgs.ai_use_value.KeyTrick = 2
sgs.ai_keep_value.KeyTrick = 2
sgs.ai_card_intention.KeyTrick = -50

--冈崎朋也
se_inovation_zhuren_skill={}
se_inovation_zhuren_skill.name="inovation_zhuren"
table.insert(sgs.ai_skills,se_inovation_zhuren_skill)
se_inovation_zhuren_skill.getTurnUseCard=function(self,inclusive)
	if #self.friends <= 1 then return end
	local source = self.player
	if source:isKongcheng() then return end
	if source:hasUsed("InovationZhurenCard") then return end
	return sgs.Card_Parse("@InovationZhurenCard=.")
end

sgs.ai_skill_use_func.InovationZhurenCard = function(card,use,self)
	local target
	local source = self.player
	local keys = 0
	for _,card in sgs.qlist(source:getJudgingArea()) do
		if card:isKindOf("KeyTrick") then
			keys = keys + 1
		end
	end
	local max_num = source:getMaxHp() - source:getHp() + keys
	local max_x = 0
	for _,friend in ipairs(self.friends) do
		local x = 5 - friend:getHandcardNum()

		if x > max_x and friend:objectName() ~= source:objectName() then
			max_x = x
			target = friend
		end
	end
	local cards=sgs.QList2Table(self.player:getHandcards())
	local needed = {}
	for _,acard in ipairs(cards) do
		if #needed < max_num then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if target and needed then
		use.card = sgs.Card_Parse("@InovationZhurenCard="..table.concat(needed,"+"))
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.InovationZhurenCard = 4
sgs.ai_use_priority.InovationZhurenCard  = 2.4
sgs.ai_card_intention.InovationZhurenCard  = -60

sgs.ai_skill_invoke.inovation_zhuren = function(self, data)
	return true
end

sgs.ai_skill_choice.inovation_Daolu = function(self, choices, data)
	local lord = self.room:getLord()
	if self.player:getRole() == "lord" then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) and friend:objectName() ~= self.player:objectName() then
				return "Fuko_summoner"
			end
		end
		return "inovation_Nagisa_Protector"
	elseif self.player:getRole() == "loyalist" then
		return "Tomoyo_Couple"
	elseif self.player:getRole() == "rebel" then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) and self.player:getHp() > 2 and friend:objectName() ~= self.player:objectName() then
				if #self.friends > #self.enemies then
					return "Fuko_summoner"
				end
			end
			--TODO
		end
		return "inovation_Nagisa_Protector"
	elseif self.player:getRole() == "renegade" then
		if lord and lord:getHp() <= 2 then
			return "Fuko_summoner"
		end
		return "inovation_Nagisa_Protector"
	end
end

sgs.ai_skill_playerchosen.inovation_Daolu = function(self, targets)
	local lord = self.room:getLord()
	if lord and self.player:getRole() == "loyalist" then return lord end
	if lord and self.player:getRole() == "rebel" then
		for _,friend in ipairs(self.friends) do
			if not friend:objectName()~=self.player:objectName() and self:isWeak(friend) and self.player:getHp() > 2 then
				target = friend
			end
		end
	end
	if target then return target end
	for _,friend in ipairs(self.friends) do
		if not friend:objectName()~=self.player:objectName() then
			target = friend
		end
	end
	return target
end

sgs.ai_playerchosen_intention.inovation_Daolu = function(from, to)
	local intention = -100
	sgs.updateIntention(from, to, intention)
end

local se_diangong_skill={}
se_diangong_skill.name="diangong"
table.insert(sgs.ai_skills,se_diangong_skill)
se_diangong_skill.getTurnUseCard=function(self,inclusive)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	for _,enemy in ipairs(self.enemies) do
		if enemy:hasSkills("se_qidian|guangyu") then return end
	end
	for _,acard in ipairs(cards) do
		if self:getKeepValue(acard)<5 and acard:isBlack() then
			return sgs.Card_Parse("@DiangongCard=.")
		end
	end
end

sgs.ai_skill_use_func.DiangongCard = function(card,use,self)
	local target
	for _,enemy in sgs.list(self.room:getAlivePlayers()) do
		local pl = false
		for _,card in sgs.list(enemy:getJudgingArea()) do
			if card:isKindOf("Lightning") then
				pl = true
			end
		end
		if pl then
			target = enemy
		end
	end
	local needed
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _,acard in ipairs(cards) do
		if self:getKeepValue(acard)<5 and acard:isBlack() then
			needed = acard
		end
	end
	if target and needed then
		use.card = sgs.Card_Parse("@DiangongCard="..needed:getEffectiveId())
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.inovation_huanxing = function(self, data)
	local use = data:toCardUse()
	if not use or not use.from then return false end
	if self:isEnemy(use.from) then return true end
	return false
end

sgs.ai_use_value.DiangongCard = 8
sgs.ai_use_priority.DiangongCard = 2.5

sgs.ai_skill_invoke.diangongDamage = function(self, data)
	local damage = data:toDamage()
	return self:isFriend(damage.to)
end

sgs.ai_skill_playerchosen.diangong = function(self, targets)
	local hp_min = 100
	local target
	for _, ap in sgs.qlist(targets) do
		if self:isFriend(ap) and ap:getHp() < hp_min then
			target = ap
			hp_min = ap:getHp()
		end
	end
	if target then return target end
	return targets:first()
end


sgs.ai_skill_invoke.inovation_haixing = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	if self:isFriend(source) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.tanyan = function(self, data)
	return self:isFriend(self.room:getCurrent())
end

--枣铃
sgs.ai_need_damaged.inovation_SE_Maoqun = function (self, attacker)
	return self.player:getHp()>10
end

sgs.inovation_SE_Maoqun_keep_value =
{
    Peach 		= 9,
    Analeptic 	= 8,
    Jink 		= 9,
}


--to better
se_zhiling_skill={}
se_zhiling_skill.name="zhiling"
table.insert(sgs.ai_skills,se_zhiling_skill)
se_zhiling_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies == 0 then return end
	if self.player:getPile("Neko"):length() == 0 then return end
	local can = false
	for _,enemy in ipairs(self.enemies) do
		if (enemy:getMark("@Neko_S") == 0 or enemy:getMark("@Neko_C") == 0 or (enemy:getMark("@Neko_D") == 0 and not enemy:hasSkill("Huansha")) or enemy:getMark("@Neko_H") == 0) and not enemy:hasFlag("Can_not") then
			can = true
		end
	end
	if self.player:getRole() =="renegade" then
		if #self.enemies - #self.friends <= 0 then
			can = false
		end
		if  self.player:getPile("Neko"):length() <=8 and #self.enemies - #self.friends <= 1 then
			can = false
		end
		if  self.player:getPile("Neko"):length() <=3 and #self.enemies - #self.friends <= 2 then
			can = false
		end
	end
	if not can then return end
	return sgs.Card_Parse("@ZhilingCard=.")
end

sgs.ai_skill_use_func.ZhilingCard = function(card,use,self)
	local target
	local lord = self.room:getLord()
	for _,enemy in ipairs(self.enemies) do
		if (enemy:getMark("@Neko_S") == 0 or enemy:getMark("@Neko_C") == 0 or (enemy:getMark("@Neko_D") == 0 and not enemy:hasSkill("Huansha")) or enemy:getMark("@Neko_H") == 0) and not enemy:hasFlag("Can_not") then
			target = enemy
		end
	end
	if self.player:getRole() =="rebel" then
		if (lord and (lord:getMark("@Neko_S") == 0 or lord:getMark("@Neko_C") == 0 or (lord:getMark("@Neko_D") == 0 and not lord:hasSkill("Huansha")) or lord:getMark("@Neko_H") == 0) and not lord:hasFlag("Can_not")) then
			target = lord
		end
	end
	if target then
		use.card = sgs.Card_Parse("@ZhilingCard=.")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.ZhilingCard = 9
sgs.ai_use_priority.ZhilingCard = 9.8
sgs.ai_card_intention.ZhilingCard  = 50

sgs.ai_skill_invoke.inovation_SE_Zhixing = function(self, data)
	local source = data:toPlayer()
	if self:isFriend(source) then return true end
	return false
end

sgs.ai_skill_playerchosen.inovation_SE_Zhixing = function(self, targets)
	for _,p in ipairs(self.friends) do
		if p:getJudgingArea():length() > 0 then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if p:getEquips():length() > 0 then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if not p:isNude() then
			return p
		end
	end
	return self.enemies[1]
end

--藤林杏
sgs.ai_view_as.touzhi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getPhase() ~= sgs.Player_Play then return end
	if card:isKindOf("TrickCard") and not card:isKindOf("AOE") and not card:isKindOf("GodSalvation") and not card:isKindOf("AmazingGrace")  and not card:isKindOf("Collateral") then
		return ("slash:touzhi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

touzhi_skill={}
touzhi_skill.name="touzhi"
table.insert(sgs.ai_skills,touzhi_skill)
touzhi_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	local cardToUse
	for _,card in sgs.list(self.player:getHandcards()) do
		if card:isKindOf("TrickCard") and not card:isKindOf("AOE") and not card:isKindOf("GodSalvation") and not card:isKindOf("AmazingGrace")  and not card:isKindOf("Collateral") then
			cardToUse = card
		end
	end
	if not cardToUse then
		return
	end
	local suit = cardToUse:getSuitString()
	local number = cardToUse:getNumberString()
	local card_id = cardToUse:getEffectiveId()
	local card_str = ("slash:touzhi[%s:%s]=%d"):format(suit, number, card_id)
	return sgs.Card_Parse(card_str)
end

-- 舊版 anime AI 的 sgs.ai_use_priority_slash_remake["touzhi"] = 8：有投擲時殺的使用優先度覆寫為 8。
-- 現行 smart-ai 無此表，改用 adjustUsePriority 的技能回呼（回傳值累加到 v），回傳 8-v 等同覆寫。
sgs.ai_card_priority.touzhi = function(self,card,v)
	if card:isKindOf("Slash") then return 8-v end
end

sgs.ai_skill_use["@@youjiao"] = function(self, prompt, method)
	local cardToUse
	for _,card in sgs.list(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") and not card:isKindOf("Peach") then
			cardToUse = card
		end
	end
	if cardToUse then
		local suit = cardToUse:getSuitString()
		local number = cardToUse:getNumberString()
		local card_id = cardToUse:getEffectiveId()
		local card_str = ("key_trick:youjiao[%s:%s]=%d"):format(suit, number, card_id)
		local ss = sgs.Card_Parse(card_str)
		local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
		self:useCardKeyTrick(ss, dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			return card_str .. "->" .. dummy_use.to:first():objectName()
		end
	end
end

--间宫明里
sgs.ai_skill_invoke.Takamakuri = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.to then return false end
	if self:isEnemy(damage.to) and not damage.to:hasSkills(sgs.lose_equip_skill) then return true end
	return false
end

sgs.ai_skill_invoke.Tobiugachi = function(self, data)
	if self:isFriend(self.room:getCurrent()) then
		if self.player:getHandcardNum() - self.player:getHp() + 1 <= 3 and (self:isWeak() or self:getCardsNum("Jink") == 0) then return true end
		return false
	end
	if self.player:getHandcardNum() - self.player:getHp() + 1 <= 5 then return true end
	return false
end

sgs.ai_skill_playerchosen.Tobiugachi = function(self, targets)
	local target = self:findPlayerToDiscard()
	if target then return target end
	return self.enemies[1]
end


sgs.ai_skill_invoke.FukurouzaTobi = function(self, data)
	if self:isEnemy(self.room:getCurrent()) and not self.room:getCurrent():hasSkills(sgs.immune_skill) then return true end
	return false
end

sgs.ai_skill_invoke.FukurouzaTaka = true

--天江衣
sgs.ai_skill_invoke.kongdi = function(self, data)
	local move = data:toMoveOneTime()
	if move.to and not self:isFriend(move.to) then return true end
	return false
end

--加贺
sgs.ai_skill_invoke.kuisi = function(self, data)
	local death = data:toDeath()
	if self:isEnemy(death.damage.from) then return true end
	return false
end

sgs.ai_skill_invoke.youer = function(self, data)
	local dying = data:toDying()
	if self:isEnemy(dying.damage.from) then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 then
			return false
		end
		return true
	end
	return false
end

--大傻
nuequ_skill={}
sgs.ai_skill_invoke.baonu = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return false end
	if self.player:getLostHp() == 0 and self.player:getHandcardNum() > 4 then return false end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self.player:inMyAttackRange(p) and not p:isNude() then return true end
	end
	return false
end


--has bug TODO
jizhanshiz_skill={}
jizhanshiz_skill.name="jizhanshiz"
table.insert(sgs.ai_skills,jizhanshiz_skill)
jizhanshiz_skill.getTurnUseCard=function(self, inclusive)
	if self.player:hasUsed("JizhanCard") then return end
	if self.player:getMark("@Baonu") == 0 then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self.player:inMyAttackRange(p) and not p:isNude() then
		 	return sgs.Card_Parse("@JizhanCard=.")
		end
	end
end

sgs.ai_skill_use_func.JizhanCard = function(card,use,self)
	local target
	if #self.enemies > 1 then
		for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
			if self.player:inMyAttackRange(p) and not p:isNude() and self:isEnemy(p) then
				target = p
				if p:getEquips():length() > 0 then break end
			end
		end
		if not target then
			for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
				if self.player:inMyAttackRange(p) and not p:isNude()  then
					target = p
					break
				end
			end
		end
	else
		for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
			if self.player:inMyAttackRange(p) and not p:isNude() and not self:isEnemy(p) then
				target = p
				if p:getEquips():length() > 0 then break end
			end
		end
	end
	if target then
		use.card = card
		self.room:writeToConsole("here???")
		use.to = sgs.SPlayerList()
		use.to:append(target)
		-- if use.to then
		-- 	self.room:writeToConsole("target???? "..target:getGeneralName())
		-- 	use.to:append(target)
		-- end
		return
	end
end



sgs.ai_skill_playerchosen.jizhanshiz = function(self, targets)
	return self:getMostWeakEnemyToDamage(self, targets)
end

sgs.ai_use_value["JizhanCard"] = 5
sgs.ai_use_priority["JizhanCard"]  = 5
sgs.ai_card_intention["JizhanCard"] = 0


--3000
sgs.ai_skill_invoke.yuzhai = true
sgs.ai_skill_playerchosen.yuzhai = function(self, targets)
	return self:findPlayerToDiscard("he", false, true)
end

--无名
sgs.ai_skill_invoke.kangfen = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return false end
	if self.player:getEquips():length() == 0 and self.player:getHp() <= 3 then return false end
	return true
end

xiedou_skill={}
xiedou_skill.name="xiedou"
table.insert(sgs.ai_skills,xiedou_skill)
xiedou_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	if self.player:getEquips():length() == 0 then return end
	if self.player:hasFlag("XiedouUsed") then return end

	local needNum = self.player:getHandcardNum() - self.player:getEquips():length()

	if needNum <= 0 then return end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	local cardToUses = {table.unpack (cards , 1 , needNum)}

	local suit = cardToUses[1]:getSuitString()
	local number = cardToUses[1]:getNumberString()
	local card_str = ("duel:xiedou[%s:%s]="):format(suit, number)
	for _, card in ipairs(cardToUses) do
		card_str = card_str..card:getEffectiveId().."+"
	end
	card_str = string.sub(card_str, 1, -2)
	return sgs.Card_Parse(card_str)
end

--凌波
taxian_skill={}
taxian_skill.name="taxian"
table.insert(sgs.ai_skills,taxian_skill)
taxian_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("TaxianCard") then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) and not p:inMyAttackRange(self.player) then return sgs.Card_Parse("@TaxianCard=.") end
	end
	if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) then return sgs.Card_Parse("@TaxianCard=.") end
	end
end

sgs.ai_skill_use_func.TaxianCard = function(card,use,self)
	local targets = sgs.SPlayerList()
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) then
			--TODO if friend need maixie
			if not p:inMyAttackRange(self.player) then
				targets:append(p)
			elseif p:getHandcardNum() < 2 then
				targets:append(p)
			elseif self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 then
				targets:append(p)
			elseif #targets == 2 then
				targets:append(p)
			end
		end
	end

	if targets:length() > 0 then
		use.card = sgs.Card_Parse("@TaxianCard=.")
		use.to = targets
		return
	end
end

sgs.ai_use_value["TaxianCard"] = 8
sgs.ai_use_priority["TaxianCard"]  = 1
sgs.ai_card_intention["TaxianCard"] = 100

--最上（ceshi)
sgs.ai_skill_invoke.jianjin = function(self, data)
	local damage = data:toDamage()

	if not self:isFriend(damage.from) and not self:isFriend(damage.to) then return false end
	local current = self.room:getCurrent()
	if current:objectName() == self.player:objectName() or current:getNextAlive():objectName() == self.player:objectName() then
		if self.player:getMark("@Jianjin_damage_recovery") > 2 then return true end
		if self.player:getLostHp() > 0 and self:getCardsNum("Peach") > 0 then return false end
		if self.player:hasWeapon("crossbow") and self:getCardsNum("Slash") > 0 then return false end
		return true
	else
		if self.player:getMark("@Jianjin_damage_recovery") > 2 then return true end
		if self.player:getMark("@Jianjin_damage_recovery") == 2 then
			if self:isFriend(damage.from) and self:isWeak(damage.from) then return true end
			if self:isFriend(damage.to) and self:isWeak(damage.to) then return true end
		end
	end
end

sgs.ai_skill_playerchosen.jianjin = function(self, targets)

	for _,p in sgs.list(targets) do
		if self:isFriend(p) then return p end
	end
	return targets:first()
end

sgs.ai_skill_invoke.faka = function(self, data)
	local move = data:toMoveOneTime()
	local value = move.card_ids:length()
	if move.from then
		if not self:isEnemy(self.room:getCurrent()) and not self:isEnemy(move.from) then return false end
	else
		if not self:isEnemy(self.room:getCurrent()) then return false end
	end


	for _,id in sgs.list(move.card_ids) do
		if sgs.Sanguosha:getCard(id):isKindOf("Peach") then
			value = value - 2
		end
		if sgs.Sanguosha:getCard(id):isKindOf("Analeptic") then
			value = value - 1.5
		end
	end
	if value >= 1 then return true end
	return false
end

sgs.ai_skill_playerchosen.faka = function(self, targets)

	for _,p in sgs.list(targets) do
		if self:isEnemy(p) then return p end
	end
	for _,p in sgs.list(targets) do
		if not self:isFriend(p) then return p end
	end
	return targets:first()
end


--七海千秋
ningju_skill={}
ningju_skill.name="ningju"
table.insert(sgs.ai_skills,ningju_skill)
ningju_skill.getTurnUseCard=function(self,inclusive)
	if self.player:usedTimes("NingjuCard") >= 3 then return end
	if #self.enemies == 0 then return end
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	for _,p in ipairs(self.enemies) do
		if not self:slashProhibit(card, p) and self:slashIsEffective(card, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then return sgs.Card_Parse("@NingjuCard=.") end
	end
	return sgs.Card_Parse("@NingjuCard=.")
end

sgs.ai_skill_use_func.NingjuCard = function(card,use,self)
	local target
	if self.player:getMark("@waked") == 1 then
		for _,p in ipairs(self.enemies) do
			if not self:slashProhibit(card, p) and self:slashIsEffective(card, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
				target = p
				if self:isWeak(p) then
					break
				end
			end
		end
	else

		local max_effect_num = -200
		for _,p in ipairs(self.enemies) do
			if not self:slashProhibit(card, p) and self:slashIsEffective(card, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
				local effective_num = 0
				local ava_num = 0
				for _, q in sgs.list(self.room:getAlivePlayers()) do
					if q:inMyAttackRange(p) then

						if self:isFriend(q) then effective_num = effective_num + 1 end
						if self:isEnemy(q) then effective_num = effective_num - 3 end
						-- more?
						ava_num = ava_num + 1
					end
				end
				if ava_num == 1 then effective_num = 2.8 end
				if max_effect_num < effective_num then
					max_effect_num = effective_num
					target = p
				end
			end
		end
	end

	if target then
		use.card = sgs.Card_Parse("@NingjuCard=.")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_cardchosen.ningju = function(self, who, flags)
	local status = self.room:getTag("ningju_color"):toString()
	if not status then return nil end
	local need = "Red"
	if status == "None" or status == "Mix" then return nil end
	local chiaki = self.room:findPlayerBySkillName("ningju")
	if not chiaki then return nil end
	if (self:isEnemy(chiaki) and status == "Red") or (not self:isEnemy(chiaki) and status == "Black") then
		need = "Black"
	end
	local cards = self.player:getHandcards()
	for _,c in sgs.list(self.player:getEquips()) do
		cards:append(c)
	end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	if need == "Red" then
		self.room:writeToConsole(self.player:getGeneralName().." need to use red")
		for _, card in ipairs(cards) do
			if card:isRed() then return card:getEffectiveId() end
		end
	else
		self.room:writeToConsole(self.player:getGeneralName().." need to use black")
		for _, card in ipairs(cards) do
			if card:isBlack() then return card:getEffectiveId() end
		end
	end
	return nil
end

sgs.ai_use_value["NingjuCard"] = 8
sgs.ai_use_priority["NingjuCard"]  = 2
sgs.ai_card_intention["NingjuCard"] = 100


--朝潮
fanqian_skill={}
sgs.ai_skill_invoke.xingjian = true
sgs.ai_skill_choice["xingjian"] = function(self, choices, data)
	local ranka = self.room:findPlayerBySkillName("xingjian")
	if not self:isEnemy(ranka) then return "xingjian_skip" end
	if self.player:hasSkills(sgs.need_equip_skill) then return "xingjian_skip" end
	if self.player:hasSkills(sgs.lose_equip_skill) then return "xingjian_throw" end
	if self.player:hasSkills(sgs.cardneed_skill) then return "xingjian_throw" end
	if self:getCardsNum("Slash") == 0 then return "xingjian_throw" end
	return "xingjian_skip"
end

sgs.ai_skill_invoke.goutong =  function(self, data)
	move = data:toMoveOneTime()
	if self.player:objectName() == move.to:objectName() then
		if move.from and not self:isEnemy(move.from) then return true end
		if move.from then
			if self:isWeak(self.player) and not self:isWeak(move.from) and move.from:getLostHp() == 0 then return true end
		end
	else
		if move.to and not self:isEnemy(move.to) then return true end
		if move.to then
			if self:isWeak(self.player) and not self:isWeak(move.to) and move.to:getLostHp() == 0 then return true end
		end
	end
	return false
end

--小鸟
sgs.ai_skill_playerchosen.jianshi = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() == 0 then return friend end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() <=2 and friend:isLord() then return friend end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then return friend end
	end
end

sgs.ai_skill_invoke.qiyue = function(self, data)
	local dying = data:toDying()
	if not self:isFriend(dying.who) then return false end

	if self.player:objectName() == dying.who:objectName() then return true end
	local aggregate_num = 0
	for i=1, self.player:getMaxHp() do
		aggregate_num = aggregate_num + (5 - i) * self.room:getAlivePlayers():length()
	end
	if aggregate_num >= self.room:getDrawPile():length() then return true end

	if dying.who:isLord() then return true end

	if self.player:getMaxHp() >= 3 then return true end
	if self:getCardsNum("Jink") > 0 or self:getCardsNum("Analeptic") > 0 and self.player:getMaxHp() >= 2 then return true end


	return false
end

--玛茵
sgs.ai_skill_invoke.inovation_jixian = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getLostHp() == 1 then return true end
	if self.player:getLostHp() > 1 then
		if self.player:getRole() == "rebel" and self:isWeak(self.room:getLord()) then return true end
		if self.room:getAlivePlayers():length() == 2 then return true end
		if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return true end
	end
	for _,p in ipairs(self.friends) do
		if p:hasSkills("SE_Shuanglang|SE_Mengfeng")then return true end
	end
	for _,p in ipairs(self.enemies) do
		if p:getHp() == 1 and self:isWeak(p) and p:getRole() == "rebel" then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.inovation_jixian = function(self, targets)
	return self:getPriorTarget()
end

sgs.ai_skill_choice.nangua = function(self, choices, data)
	if self.player:faceUp() then return "nangua_recover" end
	if self.player:getHp() < 1 then return "nangua_recover" end
	return "nangua_turnover"
end

--诚哥
sgs.ai_skill_invoke.lunpo_inturn = function(self, data)
	if #self.enemies == 0 then return false end
	local min = 100
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if p:getHp() < min then min = p:getHp() end
	end
	local num = self.player:getPile("Yandan"):length()
	if min == 1 and num >= 3 then return true end
	if min <= 2 then
		local toFight = self:getPriorTarget()
		if toFight:getHp() <= 1 then return true end
		if toFight:hasSkills(sgs.masochism_skill) then return true end
		if toFight:hasSkill("Lichang") then return true end
	end
	return false
end

sgs.ai_skill_invoke.lunpo = function(self, data)
	local use = data:toCardUse()
	if self:isEnemy(use.from) then
		if use.card:isKindOf("SingleTargetTrick") and use.to:length() > 0 and self:isFriend(use.to:at(0)) then
			if use.card:isKindOf("Snatch") or use.card:isKindOf("Duel") then return true end
			--if use.card:isKindOf("Dismantlement") and use.to:at(0):getEquips():length() > 0 then return true end
			if use.card:isKindOf("DelayedTrick") and not use.card:isKindOf("KeyTrick") then return true end
		end
		if use.card:isKindOf("Slash") and self:isWeak(use.to:at(0)) and self:isFriend(use.to:at(0)) then return true end
		if use.card:isKindOf("Jink") or use.card:isKindOf("Peach") then return true end
		if use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect") then
			for _,p in ipairs(self.friends) do
				if self:isWeak(p) then
					return true
				end
			end
		end
	end

	return false
end

--菲娅
jiguan_skill={}
jiguan_skill.name="jiguan"
table.insert(sgs.ai_skills,jiguan_skill)
jiguan_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("JiguanCard") then return end
	 return sgs.Card_Parse("@JiguanCard=.")
end

sgs.ai_skill_use_func.JiguanCard = function(card,use,self)
	use.card = card
	return
end

sgs.ai_use_value["JiguanCard"] = 5
sgs.ai_use_priority["JiguanCard"]  = 8
sgs.ai_card_intention["JiguanCard"] = 0

sgs.ai_skill_choice["jiguan"] = "jiguan_put"

sgs.ai_skill_invoke.jiguan = function(self, data)
	if #self.enemies == 0 then return false end
	local use = data:toCardUse()
	if use.from:objectName() == self.player:objectName() then return true end
	if self:isEnemy(use.from) then
		if use.from:getHp() == 1 then return true end
		local num = 0
		for _, id in sgs.list(self.player:getPile("jiguan")) do
			if sgs.Sanguosha:getCard(id):getNumber() == use.card:getNumber() then
				num = num + 1
			end
		end
		if num > 1 then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.jiguan = function(self, targets)
	return self:getPriorTarget()
end

--炮姐
sgs.ai_skill_invoke.paoji = true
sgs.ai_skill_playerchosen.paoji = function(self, targets)
	local target = self:getPriorTarget()
	if target and not target:hasSkill("se_nitian") then return target end
	if #self.enemies > 0 then
		for _,p in ipairs(self.enemies) do
			if p:isChained() and self:isWeak(p) and not target:hasSkill("se_nitian") then return p end
		end
		return self.enemies[1]
	end
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if not self:isFriend(p) then return p end
	end
end

sgs.ai_skill_choice["paoji"] = function(self, choices, data)
	local target = self:getPriorTarget()
	for _,p in ipairs(self.friends) do
		if p:hasSkills("guicai|se_qidian") then return "4" end
	end
	if target and self:isWeak(target) then return "1" end
	for _,p in ipairs(self.enemies) do
		if p:hasSkills("guicai|se_qidian") then return "1" end
	end
	return "4"
end

sgs.ai_skill_invoke.inovation_dianci = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen.inovation_dianci = function(self, targets)
	if self:getPriorTarget() and not self:getPriorTarget():isChained() then return self:getPriorTarget() end
	if #self.enemies > 0 then
		for _,p in ipairs(self.enemies) do
			if not p:isChained() and self:isWeak(p) then return p end
		end
		return self.enemies[1]
	end
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if not self:isFriend(p) then return p end
	end
end

sgs.ai_skill_invoke.xinyang = true

sgs.ai_skill_invoke.xinyang_judge = function(self, data)
	local judge = data:toJudge()

	if self:needRetrial(judge) then
		if self.player:getPile("xinyang"):length() == 0 then return false end
		local cards_ids = sgs.QList2Table(self.player:getPile("xinyang"))
		local newList = {}
		for _,card_id in ipairs(cards_ids) do
			table.insert(newList, sgs.Sanguosha:getCard(card_id))
		end
		local card_id = self:getRetrialCardId(newList, judge)

		if card_id ~= -1 then
			self.room:setTag("xinyang_judge_card",sgs.QVariant(card_id))
			return true
		end
	end

	return false
end

sgs.ai_skill_askforag.xinyang = function(self, card_ids)
	local card_id = self.room:getTag("xinyang_judge_card"):toInt()
	self.room:setTag("xinyang_judge_card",sgs.QVariant(-1))
	if card_id ~= -1 then return card_id end
	for _, id in sgs.list(card_ids) do
		if card_id == id then return card_id end
	end

	return card_ids[1]
end


sgs.ai_cardsview_valuable.inovation_fengzhu = function(self, class_name, player)
    local pattern = nil
    if class_name == "Slash" and not player:hasFlag("inovation_fengzhu_used") then
        pattern = "slash"
    elseif class_name == "Jink" and not player:hasFlag("inovation_fengzhu_used") then
        pattern = "jink"
    elseif class_name == "Peach" and not player:hasFlag("inovation_fengzhu_used") then
        pattern = "peach"
    elseif class_name == "Analeptic" and not player:hasFlag("inovation_fengzhu_used") then
        pattern = "analeptic"
    end
    if pattern then
	    local card_str = "@InovationFengzhuCard=.:"..pattern
	    return card_str
	end
end

inovation_fengzhu_skill = {name = "inovation_fengzhu"}
table.insert(sgs.ai_skills, inovation_fengzhu_skill)
inovation_fengzhu_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then
		return
	end
    if not self.player:hasFlag("inovation_fengzhu_used") and self.player:getLostHp() > 0 then
        return sgs.Card_Parse("@InovationFengzhuCard=.:peach")
    elseif not self.player:hasFlag("inovation_fengzhu_used") and self:getCardsNum("Slash") > 0 and sgs.Analeptic_IsAvailable(self.player) then
        return sgs.Card_Parse("@InovationFengzhuCard=.:analeptic")
    elseif not self.player:hasFlag("inovation_fengzhu_used") and sgs.Slash_IsAvailable(self.player) and self:getCardsNum("Slash") == 0 then
        return sgs.Card_Parse("@InovationFengzhuCard=.:slash")
    elseif not self.player:hasFlag("inovation_fengzhu_used") then
        return sgs.Card_Parse("@InovationFengzhuCard=.:tacos")
    end
end

sgs.ai_skill_use_func.InovationFengzhuCard = function(card, use, self)

    local pattern = nil

    if not self.player:hasFlag("inovation_fengzhu_used") then
        if self.player:getLostHp() > 0 and self:isWeak() then
             pattern = "peach"
        end
    end

    if not pattern and not self.player:hasFlag("inovation_fengzhu_used") then
        if sgs.Analeptic_IsAvailable(self.player) and self:getCardsNum("Slash") > 0 then
            pattern = "analeptic"
        end
    end

    if not to_use and not self.player:hasFlag("inovation_fengzhu_used") then
        if sgs.Slash_IsAvailable(self.player) and self:getCardsNum("Slash") == 0 then
            pattern = "slash"
        end
    end

    if not to_use and not self.player:hasFlag("inovation_fengzhu_used") then
        pattern = "tacos"
    end

    if to_use and pattern then
        local card_str = "@InovationFengzhuCard=.:"..pattern
        local acard = sgs.Card_Parse(card_str)
        use.card = acard
    end
end
sgs.ai_use_value["InovationFengzhuCard"] = 6
sgs.ai_use_priority["InovationFengzhuCard"] = 3.5

sgs.ai_skill_discard["shuji"] = function(self, discard_num, min_num, optional, include_equip)
	local card_id = self.room:getTag("shuji-card"):toInt()
	if not card_id or card_id == -1 then return end

	if self.player:getHandcardNum() == 0 then return end

	--土豪
	if self.player:getHandcardNum() == 1 and not self:isWeak() and self.player:getMark("@waked") == 0 then return self:askForDiscard("discard", discard_num, min_num, false, include_equip) end
	if self.player:getPile("huanshu"):length() <= 3 and self.player:getHandcardNum() >= 2 then return self:askForDiscard("discard", discard_num, min_num, false, include_equip) end

	-- 达利安需要考虑的一些情况： 1.尽可能收束需要的锦囊花色  2.依据类型而定，最有价值的主要是顺手牵羊 无中生有 无懈可击 3.根据情况而怂，比如自己快死了
	if self:isWeak() and self.player:getHandcardNum() <= 1 and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Jink") > 0 or self:getCardsNum("Analeptic") > 0) then return end


	local rcard = sgs.Sanguosha:getCard(card_id)

	if self:getUseValue(rcard) >= 6 then return self:askForDiscard("discard", discard_num, min_num, false, include_equip) end

	local same = 0
	for _, id in sgs.list(self.player:getPile("huanshu")) do
		local card = sgs.Sanguosha:getCard(id)
		if card:getSuit() == rcard:getSuit() then same = same + 1 end
	end

	if same >= 1 then return self:askForDiscard("discard", discard_num, min_num, false, include_equip) end

	return
end

sgs.ai_skill_choice["jicheng"] = function(self, choices, data)
	if self:isWeak() and self:getCardsNum("Peach") == 0 and self.player:getHp() == 1 then return "jicheng_recover" end
	return "jicheng_draw"
end


sgs.ai_skill_invoke.shoushi = function(self, data)
	local use = data:toCardUse()
	return not use.card:isKindOf("ExNihilo") and not use.card:isKindOf("AmazingGrace") and not use.card:isKindOf("GodSalvation")
end

sgs.ai_skill_choice.shoushi = function(self, choices, data)
	local use = data:toCardUse()
	if use.card:isKindOf("ExNihilo") then
		local friend = self:findPlayerToDraw(false, 2)
		if friend then
			self.shoushi_extra_target = friend
			return "add"
		end
	elseif use.card:isKindOf("GodSalvation") then
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if enemy:isWounded() and self:hasTrickEffective(use.card, enemy, self.player) then
				self.shoushi_remove_target = enemy
				return "remove"
			end
		end
	elseif use.card:isKindOf("AmazingGrace") then
		self:sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if self:hasTrickEffective(use.card, enemy, self.player) and not hasManjuanEffect(enemy)
				and not self:needKongcheng(enemy, true) then
				self.shoushi_remove_target = enemy
				return "remove"
			end
		end
	elseif use.card:isKindOf("AOE") then
		self:sort(self.friends_noself)
		local lord = self.room:getLord()
		if lord and lord:objectName() ~= self.player:objectName() and self:isFriend(lord) and self:isWeak(lord) then
			self.shoushi_remove_target = lord
			return "remove"
		end
		for _, friend in ipairs(self.friends_noself) do
			if self:hasTrickEffective(use.card, friend, self.player) then
				self.shoushi_remove_target = friend
				return "remove"
			end
		end
	elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
		local trick = sgs.Sanguosha:cloneCard(use.card:objectName(), use.card:getSuit(), use.card:getNumber())
		trick:setSkillName("shoushi")
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.list(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardSnatchOrDismantlement(trick, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			self.shoushi_extra_target = dummy_use.to:first()
			return "add"
		end
	elseif use.card:isKindOf("Slash") then
		local slash = sgs.Sanguosha:cloneCard(use.card:objectName(), use.card:getSuit(), use.card:getNumber())
		slash:setSkillName("shoushi")
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.list(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardSlash(slash, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			self.shoushi_extra_target = dummy_use.to:first()
			return "add"
		end
	else
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.list(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardByClassName(use.card, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			self.shoushi_extra_target = dummy_use.to:first()
			return "add"
		end
	end
	self.shoushi_extra_target = nil
	self.shoushi_remove_target = nil
	return "cancel"
end

sgs.ai_skill_playerchosen.shoushi = function(self, targets)
	if not self.shoushi_extra_target and not self.shoushi_remove_target then self.room:writeToConsole("shoushi player chosen error!!") end
	return self.shoushi_extra_target or self.shoushi_remove_target
end


sgs.kaiqi_ag_type = ""
sgs.ai_skill_discard["kaiqi"] = function(self, discard_num, min_num, optional, include_equip)
	--先测评一下有没有人要给

	--开启的一些逻辑
	--尽量保证剩余的书里有3个的花色
	--可以把一些其他的花色的牌分给队友
	--如果是红桃且有队友的话自己拿无中生有的效果很好
	--如果黑桃且队友基本没有的情况下可以考虑拿顺手牵羊
	local heart, diamond, spade, club = 0,0,0,0
	local ex, sn, need = nil, nil, nil, nil, nil, nil

	for _, id in sgs.list(self.player:getPile("huanshu")) do
		local card = sgs.Sanguosha:getCard(id)
		if card:getSuit() == sgs.Card_Heart then heart = heart + 1 end
		if card:getSuit() == sgs.Card_Diamond then diamond = diamond + 1 end
		if card:getSuit() == sgs.Card_Spade then spade = spade + 1 end
		if card:getSuit() == sgs.Card_Club then club = club + 1 end
		if card:isKindOf("ExNihilo") then ex = card end
		if card:isKindOf("Snatch") then sn = card end
		if self:getUseValue(card) >= 6 then need = card end
	end

	if not self.player:hasFlag("kaiqi_self_used") then
		if heart > 3 then
			sgs.kaiqi_ag_type = "heart"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if diamond > 3 then
			sgs.kaiqi_ag_type = "diamond"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if spade > 3 then
			sgs.kaiqi_ag_type = "spade"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if club > 3 then
			sgs.kaiqi_ag_type = "club"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if heart > 2 and ((ex and ex:getSuit() == sgs.Card_Heart) or (need and need:getSuit() == sgs.Card_Heart)) then
			sgs.kaiqi_ag_type = "heart"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if diamond > 2 and need and need:getSuit() == sgs.Card_Diamond then
			sgs.kaiqi_ag_type = "diamond"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if spade > 2 and need and need:getSuit() == sgs.Card_Spade then
			sgs.kaiqi_ag_type = "spade"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
		if club > 2 and need and need:getSuit() == sgs.Card_Club then
			sgs.kaiqi_ag_type = "club"
			return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
		end
	else
		--是否有人可送
		local has = false
		for _,p in ipairs(self.friends_noself) do
			if not p:hasFlag("kaiqi_used") then has = true end
		end

		if has then
			if self:isWeak() or self.player:getPile("huanshu"):length() <= 5 or self.player:getHandcardNum() < 2 then return "." end
			if heart > 3 then
				sgs.kaiqi_ag_type = "heart"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
			if diamond > 3 then
				sgs.kaiqi_ag_type = "diamond"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
			if spade > 3 then
				sgs.kaiqi_ag_type = "spade"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
			if club > 3 then
				sgs.kaiqi_ag_type = "club"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
			if diamond == 1 then
				sgs.kaiqi_ag_type = "diamond"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
			if spade == 1 then
				sgs.kaiqi_ag_type = "spade"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
			if club == 1 then
				sgs.kaiqi_ag_type = "club"
				return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
			end
		end
	end
	return {}
end

--get AG
sgs.ai_skill_askforag.kaiqi = function(self, card_ids)
	local sel = {}
	for _,card_id in sgs.list(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		if card:getSuitString() == sgs.kaiqi_ag_type then
			if card:isKindOf("ExNihilo") then return card_id end
			table.insert(sel, card)
		end
	end

	self:sortByUseValue(sel)
	if #sel > 0 then return sel[1]:getId() end
	return card_ids[1]
end



sgs.ai_skill_playerchosen.kaiqi = function(self, targets)
	if not self.player:hasFlag("kaiqi_self_used") then
		self.player:setFlags("kaiqi_self_used")
		return self.player
	end
	for _, target in sgs.list(targets) do
		if self:isFriend(target) and not self:isWeak(target) then
			target:setFlags("kaiqi_used")
			return target
		end
	end

	for _, target in sgs.list(targets) do
		if self:isFriend(target) then
			target:setFlags("kaiqi_used")
			return target
		end
	end
end



function SmartAI:willSkipPlayPhase(player, NotContains_Null)
	local player = player or self.player

	if player:isSkipped(sgs.Player_Play) then return true end

	local fuhuanghou = self.room:findPlayerBySkillName("noszhuikong")
	if fuhuanghou and fuhuanghou:objectName() ~= player:objectName() and self:isEnemy(player, fuhuanghou)
		and fuhuanghou:isWounded() and fuhuanghou:getHandcardNum() > 1 and not player:isKongcheng() and not self:isWeak(fuhuanghou) then
		local max_card = self:getMaxCard(fuhuanghou)
		local player_max_card = self:getMaxCard(player)
		if (max_card and player_max_card and max_card:getNumber() > player_max_card:getNumber()) or (max_card and max_card:getNumber() >= 12) then return true end
	end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.Sanguosha:cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:hasTrickEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if player:containsTrick("Indulgence") then
		if player:containsTrick("YanxiaoCard") or self:hasSkills("keji|conghui",player) or (player:hasSkill("qiaobian") and not player:isKongcheng()) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

function SmartAI:willSkipDrawPhase(player, NotContains_Null)
	local player = player or self.player
	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.Sanguosha:cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:hasTrickEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if player:containsTrick("supply_shortage") then
		if player:containsTrick("YanxiaoCard") or self:hasSkills("shensu|jisu", player) or (player:hasSkill("qiaobian") and not player:isKongcheng()) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

function SmartAI:resetCards(cards, except)
	local result = {}
	for _, c in ipairs(cards) do
		if c:getEffectiveId() ~= except:getEffectiveId() then
			table.insert(result, c)
		end
	end
	return result
end

function SmartAI:shouldUseRende()
	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange and sgs.isGoodTarget(enemy, self.enemies, self) then
				local slashs = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashs) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return false end
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:canSlash(self.player) and not self:slashProhibit(nil, self.player, enemy) then
			if enemy:hasWeapon("guding_blade") and self.player:getHandcardNum() == 1 and getCardsNum("Slash", enemy) >= 1 then
				return
			elseif self:hasCrossbowEffect(enemy) and getCardsNum("Slash", enemy) > 1 and self:getOverflow() <= 0 then
				return
			end
		end
	end
	for _, player in ipairs(self.friends_noself) do
		if (player:hasSkill("haoshi") and not player:containsTrick("supply_shortage")) or player:hasSkill("jijiu") then
			return true
		end
	end
	local keepNum = 1
	if self.player:getMark("rende") == 0 and self.player:getMark("nosrende") == 0 then
		if self.player:getHandcardNum() == 3 then
			keepNum = 0
		end
		if self.player:getHandcardNum() > 3 then
			keepNum = 3
		end
	end
	if self.player:hasSkill("kongcheng") then
		keepNum = 0
	end
	if self:getOverflow() > 0  then
		return true
	end
	if self.player:getHandcardNum() > keepNum  then
		return true
	end
	if self.player:getMark("rende") ~= 0 and self.player:getMark("rende") < 2
		and (2 - self.player:getMark("rende")) >=  (self.player:getHandcardNum() - keepNum) then
		return true
	end
	if self.player:getMark("nosrende") ~= 0 and self.player:getMark("nosrende") < 2
		and (2 - self.player:getMark("nosrende")) >=  (self.player:getHandcardNum() - keepNum) then
		return true
	end
end

function SmartAI:getJijiangSlashNum(player)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	if not player:hasLordSkill("jijiang") then return 0 end
	local slashs = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:getKingdom() == "shu" and ((sgs.turncount <= 1 and sgs.ai_role[p:objectName()] == "neutral") or self:isFriend(player, p)) then
			slashs = slashs + getCardsNum("Slash", p, self.player)
		end
	end
	return slashs
end


function SmartAI:isValuableCard(card, player)
	player = player or self.player
	if (isCard("Peach", card, player) and getCardsNum("Peach", player, self.player) <= 2)
		or (self:isWeak(player) and isCard("Analeptic", card, player))
		or (player:getPhase() ~= sgs.Player_Play
			and ((isCard("Nullification", card, player) and getCardsNum("Nullification", player, self.player) < 2 and player:hasSkills("jizhi|nosjizhi|jilve"))
				or (isCard("Jink", card, player) and getCardsNum("Jink", player, self.player) < 2)))
		or (player:getPhase() == sgs.Player_Play and isCard("ExNihilo", card, player) and not player:isLocked(card)) then
		return true
	end
	local dangerous = self:getDangerousCard(player)
	if dangerous and card:getEffectiveId() == dangerous then return true end
	local valuable = self:getValuableCard(player)
	if valuable and card:getEffectiveId() == valuable then return true end
end

function SmartAI:getWoundedFriend(maleOnly, include_self)
	local friends = include_self and self.friends or self.friends_noself
	self:sort(friends, "hp")
	local list1 = {}    -- need help
	local list2 = {}    -- do not need help
	local addToList = function(p,index)
		if ( (not maleOnly) or (maleOnly and p:isMale()) ) and p:isWounded() then
			table.insert(index ==1 and list1 or list2, p)
		end
	end

	local getCmpHp = function(p)
		local hp = p:getHp()
		if p:isLord() and self:isWeak(p) then hp = hp - 10 end
		if p:objectName() == self.player:objectName() and self:isWeak(p) and p:hasSkill("qingnang") then hp = hp - 5 end
		if p:hasSkill("buqu") and p:getPile("buqu"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("buqu"):length()) end
		if p:hasSkill("nosbuqu") and p:getPile("nosbuqu"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("nosbuqu"):length()) end
		if p:hasSkills("nosrende|rende|kuanggu|kofkuanggu|zaiqi") and p:getHp() >= 2 then hp = hp + 5 end
		return hp
	end


	local cmp = function (a, b)
		if getCmpHp(a) == getCmpHp(b) then
			return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
		else
			return getCmpHp(a) < getCmpHp(b)
		end
	end

	for _, friend in ipairs(friends) do
		if friend:isLord() then
			if friend:getMark("hunzi") == 0 and friend:hasSkill("hunzi")
					and self:getEnemyNumBySeat(self.player,friend) <= (friend:getHp()>= 2 and 1 or 0) then
				addToList(friend, 2)
			elseif self:needToLoseHp(friend, nil, nil, true, true) then
				addToList(friend, 2)
			elseif not sgs.isLordHealthy() then
				addToList(friend, 1)
			end
		else
			if self:needToLoseHp(friend, nil, nil, nil, true) or (self:hasSkills("rende|kuanggu|zaiqi", friend) and friend:getHp() >= 2) then
				addToList(friend, 2)
			else
				addToList(friend, 1)
			end
		end
	end
	if #list2 > 0 then
		for _, p in ipairs(list2) do
			if table.contains(list1, p) then
				table.removeOne(list2, p)
			end
		end
	end
	table.sort(list1, cmp)
	table.sort(list2, cmp)
	return list1, list2
end

function SmartAI:hasLiyuEffect(target, slash)
	local upperlimit = tonumber(self.player:hasSkill("wushuang") and 2 or 1)
	if #self.friends_noself == 0 or self.player:hasSkill("jueqing") then return false end
	if not self:slashIsEffective(slash, target, self.player) then return false end

	local targets = { target }
	if not self.player:hasSkill("jueqing") and target:isChained() and slash:isKindOf("NatureSlash") then
		for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
			if p:isChained() and p:objectName() ~= self.player:objectName() then table.insert(targets, p) end
		end
	end
	local unsafe = false
	for _, p in ipairs(targets) do
		if self:isEnemy(target) and not target:isNude() then
			unsafe = true
			break
		end
	end
	if not unsafe then return false end

	local duel = sgs.Sanguosha:cloneCard("Duel")
	if self.player:isLocked(duel) then return false end

	local enemy_null = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p, self.player) end
		if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p, self.player) end
	end
	enemy_null = enemy_null - self:getCardsNum("Nullification")
	if enemy_null <= -1 then return false end

	local prior_friends = getPriorFriendsOfLiyu(self)
	if #prior_friends == 0 then return false end
	for _, friend in ipairs(prior_friends) do
		if self:hasTrickEffective(duel, friend, self.player) and self:isWeak(friend) and (getCardsNum("Slash", friend, self.player) < upperlimit or self:isWeak()) then
			return true
		end
	end

	if sgs.isJinkAvailable(self.player, target, slash) and getCardsNum("Jink", target, self.player) >= upperlimit
		and not self:needToLoseHp(target, self.player, true) and not self:getDamagedEffects(target, self.player, true) then return false end
	if slash:hasFlag("AIGlobal_KillOff") or (target:getHp() == 1 and self:isWeak(target) and self:getSaveNum() < 1) then return false end

	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") == 0 and (self:isWeak() or not self.player:hasSkill("zhaxiang")) then return true end
	if self.player:hasSkills("jizhi|nosjizhi") or (self.player:hasSkill("jilve") and self.player:getMark("@bear") > 0) then return false end
	if not string.startsWith(self.room:getMode(), "06_") and not sgs.GetConfig("EnableHegemony", false) and self.role ~= "rebel" then
		for _, friend in ipairs(self.friends_noself) do
			if self:hasTrickEffective(duel, friend, self.player) and self:isWeak(friend) and (getCardsNum("Slash", friend, self.player) < upperlimit or self:isWeak())
				and self:getSaveNum(true) < 1 then
				return true
			end
		end
	end
	return false
end

function SmartAI:getLijianCard()
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end

function SmartAI:findLijianTarget(card_name, use)
	local lord = self.room:getLord()
	local duel = sgs.Sanguosha:cloneCard("duel")

	local findFriend_maxSlash = function(self, first)
		self:log("Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng, fazheng
		for _, friend in ipairs(self.friends_noself) do
			if friend:isMale() and self:hasTrickEffective(duel, first, friend) then
				if friend:hasSkill("nosenyuan") and friend:getHp() > 1 then nos_fazheng = friend end
				if friend:hasSkill("enyuan") and friend:getHp() > 1 then fazheng = friend end
				if (getCardsNum("Slash", friend) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan", first) and not self:hasSkills("wuyan|noswuyan", first) then
				if (first:getHp() <= 1 and first:getHandcardNum() == 0) then safe = true end
			elseif (getCardsNum("Slash", friend_maxSlash) >= getCardsNum("Slash", first)) then safe = true end
			if safe then return friend_maxSlash end
		else self:log("unfound")
		end
		if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
		return nil
	end

	if self.role == "rebel" or (self.role == "renegade" and sgs.current_mode_players["loyalist"] + 1 > sgs.current_mode_players["rebel"]) then

		if lord and lord:isMale() and not lord:isNude() and lord:objectName() ~= self.player:objectName() then      -- 优先离间1血忠和主
			self:sort(self.enemies, "handcard")
			local e_peaches = 0
			local loyalist

			for _, enemy in ipairs(self.enemies) do
				e_peaches = e_peaches + getCardsNum("Peach", enemy)
				if enemy:getHp() == 1 and self:hasTrickEffective(duel, enemy, lord) and enemy:objectName() ~= lord:objectName()
				and enemy:isMale() and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches < 1 then return loyalist, lord end
		end

		if #self.friends_noself >= 2 and self:getAllPeachNum() < 1 then     --收友方反
			local nextplayerIsEnemy
			local nextp = self.player:getNextAlive()
			for i = 1, self.room:alivePlayerCount() do
				if not self:willSkipPlayPhase(nextp) then
					if not self:isFriend(nextp) then nextplayerIsEnemy = true end
					break
				else
					nextp = nextp:getNextAlive()
				end
			end
			if nextplayerIsEnemy then
				local round = 50
				local to_die, nextfriend
				self:sort(self.enemies, "hp")

				for _, a_friend in ipairs(self.friends_noself) do   -- 目标1：寻找1血友方
					if a_friend:getHp() == 1 and a_friend:isKongcheng() and not self:hasSkills("kongcheng|yuwen", a_friend) and a_friend:isMale() then
						for _, b_friend in ipairs(self.friends_noself) do       --目标2：寻找位于我之后，离我最近的友方
							if b_friend:objectName() ~= a_friend:objectName() and b_friend:isMale() and self:playerGetRound(b_friend) < round
							and self:hasTrickEffective(duel, a_friend, b_friend) then

								round = self:playerGetRound(b_friend)
								to_die = a_friend
								nextfriend = b_friend

							end
						end
						if to_die and nextfriend then break end
					end
				end

				if to_die and nextfriend then return to_die, nextfriend end
			end
		end
	end

	if lord and self:isFriend(lord) and lord:hasSkill("hunzi") and lord:getHp() == 2 and lord:getMark("hunzi") == 0 and lord:objectName() ~= self.player:objectName() then
		local enemycount = self:getEnemyNumBySeat(self.player, lord)
		local peaches = self:getAllPeachNum()
		if peaches >= enemycount then
			local f_target, e_target
			for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if ap:objectName() ~= lord:objectName() and ap:isMale() and self:hasTrickEffective(duel, lord, ap) then
					if self:hasSkills("jiang|nosjizhi|jizhi", ap) and self:isFriend(ap) and not ap:isLocked(duel) then
						if not use.isDummy then lord:setFlags("AIGlobal_NeedToWake") end
						return lord, ap
					elseif self:isFriend(ap) then
						f_target = ap
					else
						e_target = ap
					end
				end
			end
			if f_target or e_target then
				local target
				if f_target and not f_target:isLocked(duel) then
					target = f_target
				elseif e_target and not e_target:isLocked(duel) then
					target = e_target
				end
				if target then
					if not use.isDummy then lord:setFlags("AIGlobal_NeedToWake") end
					return lord, target
				end
			end
		end
	end

	local shenguanyu = self.room:findPlayerBySkillName("wuhun")
	if shenguanyu and shenguanyu:isMale() and shenguanyu:objectName() ~= self.player:objectName() then
		if self.role == "rebel" and lord and lord:isMale() and lord:objectName() ~= self.player:objectName() and not lord:hasSkill("jueqing") and self:hasTrickEffective(duel, shenguanyu, lord) then
			return shenguanyu, lord
		elseif self:isEnemy(shenguanyu) and #self.enemies >= 2 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:objectName() ~= shenguanyu:objectName() and enemy:isMale() and not enemy:isLocked(duel)
					and self:hasTrickEffective(duel, shenguanyu, enemy) then
					return shenguanyu, enemy
				end
			end
		end
	end

	if not self.player:hasUsed(card_name) then
		self:sort(self.enemies, "defense")
		local males, others = {}, {}
		local first, second
		local zhugeliang_kongcheng, xunyu

		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() and not enemy:hasSkills("wuyan|noswuyan") then
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasSkill("jieming") then xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:hasTrickEffective(duel, enemy, anotherenemy) then
								if not (enemy:hasSkill("hunzi") and enemy:getMark("hunzi") < 1 and enemy:getHp() == 2) then
									table.insert(males, enemy)
								else
									table.insert(others, enemy)
								end
							end
							if #males == 1 and self:hasTrickEffective(duel, males[1], anotherenemy) then
								if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				end
				if #males >= 2 then break end
			end
		end

		if #males >= 1 and sgs.ai_role[males[1]:objectName()] == "rebel" and males[1]:getHp() == 1 then
			if lord and self:isFriend(lord) and lord:isMale() and lord:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel, males[1], lord)
				and not lord:isLocked(duel) and lord:objectName() ~= self.player:objectName() and lord:isAlive()
				and (getCardsNum("Slash", males[1]) < 1
					or getCardsNum("Slash", males[1]) < getCardsNum("Slash", lord)
					or self:getKnownNum(males[1]) == males[1]:getHandcardNum() and getKnownCard(males[1], self.player, "Slash", true, "he") == 0)
				then
				return males[1], lord
			end

			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
		end

		if #males == 1 then
			if isLord(males[1]) and sgs.turncount <= 1 and self.role == "rebel" and self.player:aliveCount() >= 3 then
				local p_slash, max_p, max_pp = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if p:isMale() and not self:isFriend(p) and p:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel, males[1], p) and not p:isLocked(duel)
						and p_slash < getCardsNum("Slash", p) then
						if p:getKingdom() == males[1]:getKingdom() then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males, max_p) end
				if max_pp and #males == 1 then table.insert(males, max_pp) end
			end
		end

		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			elseif xunyu and not xunyu:isLocked(duel) then
				if getCardsNum("Slash", males[1]) < 1 then
					table.insert(males, xunyu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.enemies) do
						local x = enemy:getMaxHp() > enemy:getHandcardNum() and math.min(5, enemy:getMaxHp() - enemy:getHandcardNum()) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, xunyu)
					end
				end
			end
		end

		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:hasTrickEffective(duel, first, zhugeliang_kongcheng) then
				table.insert(males, zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then table.insert(males, friend_maxSlash) end
			end
		end

		if #males >= 2 then
			first = males[1]
			second = males[2]
			if lord and first:getHp() <= 1 then
				if self.player:isLord() or sgs.isRolePredictable() then
					local friend_maxSlash = findFriend_maxSlash(self, first)
					if friend_maxSlash then second = friend_maxSlash end
				elseif lord:isMale() and not self:hasSkills("wuyan|noswuyan", lord) then
					if self.role=="rebel" and not first:isLord() and self:hasTrickEffective(duel, first, lord) then
						second = lord
					else
						if ( (self.role == "loyalist" or self.role == "renegade") and not self:hasSkills("ganglie|enyuan|neoganglie|nosenyuan", first) )
							and ( getCardsNum("Slash", first) <= getCardsNum("Slash", second) ) then
							second = lord
						end
					end
				end
			end

			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

function SmartAI:canUseJieyuanDecrease(damage_from, player)
	if not damage_from then return false end
	local player = player or self.player
	if player:hasSkill("jieyuan") and damage_from:getHp() >= player:getHp() then
		for _, card in sgs.qlist(player:getHandcards()) do
			local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), player:objectName())
			if player:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
				if card:isRed() and not isCard("Peach", card, player) then return true end
			end
		end
	end
	return false
end

function SmartAI:getSaveNum(isFriend)
	local num = 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if (isFriend and self:isFriend(player)) or (not isFriend and self:isEnemy(player)) then
			if not self.player:hasSkill("wansha") or player:objectName() == self.player:objectName() then
				if player:hasSkill("jijiu") then
					num = num + self:getSuitNum("heart", true, player)
					num = num + self:getSuitNum("diamond", true, player)
					num = num + player:getHandcardNum() * 0.4
				end
				if player:hasSkill("nosjiefan") and getCardsNum("Slash", player, self.player) > 0 then
					if self:isFriend(player) or self:getCardsNum("Jink") == 0 then num = num + getCardsNum("Slash", player, self.player) end
				end
				num = num + getCardsNum("Peach", player, self.player)
			end
			if player:hasSkill("buyi") and not player:isKongcheng() then num = num + 0.3 end
			if player:hasSkill("chunlao") and not player:getPile("wine"):isEmpty() then num = num + player:getPile("wine"):length() end
			if player:hasSkill("jiuzhu") and player:getHp() > 1 and not player:isNude() then
				num = num + 0.9 * math.max(0, math.min(player:getHp() - 1, player:getCardCount(true)))
			end
			if player:hasSkill("renxin") and player:objectName() ~= self.player:objectName() and not player:isKongcheng() then num = num + 1 end
		end
	end
	return num
end
