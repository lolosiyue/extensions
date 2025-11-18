sgs.ai_skillInvoke_intention = {}
sgs.ai_skillChoice_intention = {}

sgs.ai_choicemade_filter.skillInvoke.general = function(self, from, promptlist)
	local reason = string.gsub(promptlist[2], "%-", "_")
	local to = global_room:getCurrent()
	local callback = sgs.ai_skillInvoke_intention[reason]
	if callback then
		if type(callback) == "number" and promptlist[#promptlist] == "yes" and to:objectName() ~= from:objectName() then
			sgs.updateIntention(from, to, sgs.ai_skillInvoke_intention[reason])
		elseif type(callback) == "function" then
			local yesorno = promptlist[#promptlist]
			callback(from, to, yesorno, self)
		end
	end
end

sgs.ai_choicemade_filter.skillChoice.general = function(self, from, promptlist)
	local reason = string.gsub(promptlist[2], "%-", "_")
	local callback = sgs.ai_skillChoice_intention[reason]
	local to = global_room:getCurrent()
	if callback and to then
		if type(callback) == "number" and to:objectName() ~= from:objectName() then
			sgs.updateIntention(from, to, sgs.ai_skillChoice_intention[reason])
		elseif type(callback) == "function" then
			local answer = promptlist[3]
			callback(from, to, answer, self)
		end
	end
end

sgs.ai_compare_funcs.morehp = function(a, b)
	return a:getHp() > b:getHp()
end
sgs.ai_compare_funcs.morehcard = function(a, b)
	return a:getHandcardNum() > b:getHandcardNum()
end
sgs.ai_compare_funcs.morehecard = function(a, b)
	local c1 = a:getCardCount()
	local c2 = b:getCardCount()
	if c1 == c2 then
		return sgs.getDefense(a, self) > sgs.getDefense(b, self)
	else
		return c1 > c2
	end
end
sgs.ai_compare_funcs.moredef = function(a, b)
	return self:getDefenseSlash(a) > self:getDefenseSlash(b)
end

function SmartAI:hasYongyefan(target)
	if not target then return false end
	if target:hasSkill("TH_yongyefan") then
		local current = self.room:getCurrent()
		if current:hasFlag("isExtraTurn") then return end
		if target and target:hasFlag("isExtraTurn") then return end
		if not target:isWounded() then return true end
		local enemy_num = self:getEnemyNumBySeat(current, target, target)
		if enemy_num < self.player:getHp() then return true end
	end
	return false
end

function SmartAI:hasSameEquip(card, player)
	player = player or self.player
	if not card then global_room:writeToConsole(debug.traceback()) return end

	if card:isKindOf("Weapon") and player:getWeapon() then return true
	elseif card:isKindOf("Armor") and player:getArmor() then return true
	elseif card:isKindOf("DefensiveHorse") and player:getDefensiveHorse() then return true
	elseif card:isKindOf("OffensiveHorse") and player:getOffensiveHorse() then return true end

	local weapon, armor, defhorse, offhorse
	for _, c in sgs.qlist(player:getHandcards()) do
		if card:isKindOf("Weapon") and c:isKindOf("Weapon") then
			if weapon then return true else weapon = true end
		elseif card:isKindOf("Armor") and c:isKindOf("Armor") then
			if armor then return true else armor = true end
		elseif card:isKindOf("DefensiveHorse") and c:isKindOf("DefensiveHorse") then
			if defhorse then return true else defhorse = true end
		elseif card:isKindOf("OffensiveHorse") and c:isKindOf("OffensiveHorse") then
			if offhorse then return true else offhorse = true end
		end
	end
	return false
end

function SmartAI:playercount(player, all)
	player = player or self.player
	local n = 0
	for _,p in sgs.qlist(self.room:getPlayers()) do
		n = n + 1
		if p:objectName() == player:objectName() then
			break
		end
	end
	return n
end

function SmartAI:GoodChaintoRecover(who)
	who = who or self.player

	local ChainedFriends, ChainedEnemies = {}, {}
	local hasQED = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasSkill("TH_qed") then hasQED = hasQED + (self:isFriend(p) and 1 or -1) end
		if p:isChained() and p:isWounded() then
			if self:isFriend(p) then table.insert(ChainedFriends, p)
			else table.insert(ChainedEnemies, p) end
		end
	end

	local good = #ChainedFriends - #ChainedEnemies

	for _, friend in ipairs(ChainedFriends) do
		if friend:getRole() == "lord" then good=good + 1 end
		if friend:getHp() <= 2 then good = good + 1 end
		if friend:hasSkill("TH_tianjiedetaozi") and friend:getLostHp() > 1 then good = good + 1 end
	end
	for _, enemy in ipairs(ChainedEnemies) do
		if enemy:getRole() == "lord" and not self.player:getRole() == "renegade" then good = good - 1 end
		if enemy:getHp() == 1 then good = good - 1 end
		if enemy:hasSkill("TH_tianjiedetaozi") and enemy:getLostHp() > 1 then good = good - 1 end
	end
	return good + hasQED >= 0
end

function SmartAI:TheWuhun(player, onlylord, damage)
	player = player or self.player
	damage = damage or 1
	if player:hasSkill("wuhun") and player:getHp() <= damage and not isLord(player) then
		local lastone = true
		if (self.role == "lord" or self.role == "loyalist") and sgs.playerRoles["rebel"] + sgs.playerRoles["renegade"] > 0 then
			lastone = false
		elseif self.role == "renegade" and self.player:aliveCount() > 2 then
			lastone = false
		elseif self.role == "rebel" and sgs.playerRoles["loyalist"]  + sgs.playerRoles["renegade"] > 0 then
			lastone = false
		end
		if not lastone then
			local maxnightmare = 0
			local nightmareplayer = {}
			for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
				maxnightmare = math.max(ap:getMark("@nightmare"), maxnightmare)
			end
			if maxnightmare == 0 then return 0 end
			for _, np in sgs.qlist(self.room:getAlivePlayers()) do
				if np:getMark("@nightmare") == maxnightmare then
					table.insert(nightmareplayer, np)
				end
			end
			if #nightmareplayer == 0 then return 0 end
			local isfriendlord, isfriend, isenemy, isenemylord
			for _, p in ipairs(nightmareplayer) do
				if p:isLord() then
					if self:isFriend(p) then isfriendlord = true
					elseif self.role == "renegade" then isfriendlord = true
					else isenemylord = true end
				else
					if self:isFriend(p) then isfriend = true
					else isenemy = true end
				end
			end
			if self:isFriend(player) then
				if isenemylord then return 2
				elseif isenemy then return 1
				elseif isfriend then return -1
				elseif isfriendlord then return -2
				else return 0 end
			else
				if isenemylord then return 2 end
				if isenemy then return 1 end
				if isfriend then return -1 end
				if isfriendlord then return -2 end
			end
		end
	end
	return 0
end

function SmartAI:maixueplayer(player)
	player = player or self.player
	if player:getHp() > 1 and (self:hasSkills("yiji|jieming|guixin",player) or (player:hasSkill("TH_huanlongyueni") and player:getEquips():length()>1)) then
		return true
	end
	return
end

function SmartAI:saveplayer(player)
	player = player or self.player
	if player:hasSkills("jijiu|buyi|jiefan")  and player:getHandcardNum() > 0  then return true end
	if player:hasSkill("chunlao") and player:getPile("wine"):length() > 0 then return true end
	if player:hasSkill("TH_chihuo") and player:getCardCount(true) > 0 then return true end
	return
end

function SmartAI:undeadplayer(player)
	player = player or self.player
	if (player:hasSkill("longhun") and player:getHp()==1) or
		(player:hasSkill("niepan") and player:getMark("@nirvana") > 0 and player:getHp()==1) or
		(player:hasSkill("fuli") and player:getMark("@laoji") > 0 and player:getHp()==1) or
		(player:hasSkill("TH_Phoenixrevive") and player:getMark("Phoenixrevive")<1 and player:getHp()==1) then
		return true
	end
	return
end


function SmartAI:UseAoeSkillValue(element, players, card)
	element = element or sgs.DamageStruct_Normal
	local friends = {}
	local enemies = {}
	local good = 0

	players = players or sgs.QList2Table(self.room:getOtherPlayers(self.player))

	for _, ap in ipairs(players) do
		if self:isFriend(ap) then table.insert(friends, ap)
		else table.insert(enemies, ap) end
	end

	good = (#enemies - #friends) * 2
	if #enemies == 0 then return -100 end
	if element == sgs.DamageStruct_Thunder then
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:hasSkill("TH_yuyiruokong") then
				if self:isFriend(ap) then good = good + ap:getCardCount(true)
				else good = good - ap:getCardCount(true)
				end
			end
		end
	end
	if element == sgs.DamageStruct_Fire then
		for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:hasSkill("TH_Meltdown") then
				for _, friend in ipairs(friends) do
					if friend:getHandcardNum() > 0 then good = good - 0.5 end
				end
				for _, enemy in ipairs(enemies) do
					if enemy:getHandcardNum() > 0 then good = good + 0.5 end
				end
			end
		end
	end




	if self.player:hasSkill("TH_hongsehuanxiangxiang") then good = good + 1 end

	if self.player:getRole() == "renegade" then good = good + 0.5 end
	if self.player:getRole() == "rebel" then good = good + 0.8 end

	local who
	for _, player in ipairs(players) do
		if player:isChained() and self:damageIsEffective(player, element) and not who then who = player end
		local value = 0
		if player:getRole() == "lord" then value = value - 0.5 end
		if not self:damageIsEffective(player, element) then
			value = value + 1
			if self:isEnemy(player) and #enemies == 1 or self:isFriend(player) and #friends == 1 then value = value + 100 end
		end
		if player:getHp() == 1 and self:getAllPeachNum() == 0 then
			if player:getRole() == "lord" then value = value - 100 else value = value - 2 end
		end
		if self:needToLoseHp(player, self.player) then value = value + 0.5 end
		if self:undeadplayer(player) then value = value + 0.5 end
		if self:saveplayer(player) then value = value + 0.5 end

		if self:isFriend(player) then good = good + value else good = good - value end
	end





	if who and not self.player:hasSkill("jueqing") and (element == sgs.DamageStruct_Thunder or element == sgs.DamageStruct_Fire) then
		-- local damage = {}
		-- damage.from = self.player
		-- damage.to = who
		-- damage.nature = element
		-- damage.card = card
		-- damage.damage = 1
		-- good = good + self:isGoodChain(damage)
		if self:isGoodChainTarget(who, element, self.player, 1) then
		good = good + 1
		end
	end
	return good
end

function SmartAI:pleaseSme()
	if self:getAllPeachNum() > 0 then return true end
	for _,friend in ipairs(self.friends) do
		if self:saveplayer(friend) then
			return true
		end
	end
	return
end

function SmartAI:CanUseAttackSkill(player)
	if not player then global_room:writeToConsole(debug.traceback()) return end
	if player:hasSkills("huashen|gongxin|mingce|ganlu|anxu|TH_SpearTheGungnir|TH_wugufengdeng|TH_Miracle_GodsWind|TH_Wonder_NwOBNS|TH_rengui|TH_nanti|"..
	"TH_LifeGame|TH_thethiefmarisa|TH_BadFortune|TH_Hypnosis|TH_TerribleSouvenir|TH_liandemaihuo|TH_GreatestCaution|TH_GalacticIllusion|"..
	"TH_CosmicMarionnette|TH_PhilosophersStone|TH_MoreUnscientific") then return true end
	if player:hasSkill("shuangxiong") and player:getMark("shuangxiong") > 0 and player:getHandcardNum() > 3 then return true end
	if player:hasSkills("rende|nosrende|jieyin|zhiheng|nosguose|guhuo|quhu|tianyi|dimeng|shenji|manjuan|dahe|TH_wenwenxinwen|TH_MasterSpark") and player:getHandcardNum() > 1 then return true end
	if player:hasSkills("fanjian|nosfanjian|qingnang|noslijian|lijian|qice|TH_huaidiao|TH_shengyusi|TH_Unscientific|TH_Science") and player:getHandcardNum() > 0 then return true end
	if player:hasSkills("luanji|paoxiao|jizhi|qixi|xianzhen|yinling") and player:getHandcardNum() > 3 then return true end
	if player:hasSkills("juejing|fuluan|TH_chihuo") and player:getCards("he"):length() > 2 then return true end
	if player:hasSkill("TH_fengyitianxiang") and getCardsNum("FireSlash", player, self.player) > 1 then return true end

	if player:hasSkill("TH_huanzang") and getCardsNum("Slash", player, self.player) > 0 then
		for _,friend in ipairs(self.friends) do
			if player:canSlash(friend, nil, true) and player:distanceTo(friend) == 1 then
				return true
			end
		end
	end
	if player:hasSkill("TH_GreatestTreasure") and player:getHandcardNum() > 1 then
		for _,friend in ipairs(self.friends) do
			if player:distanceTo(friend) == 1 then return true end
		end
	end
	if player:hasSkills("tieji|wushuang|liegong|mengjin|lieren|tiaoxin|pojun|nosqianxi|TH_Eternal|TH_aoyi_sanbubisha|TH_hengong") and player:getHandcardNum() > 1 then
		for _,friend in ipairs(self.friends) do
			if player:canSlash(friend, nil, true) then
				return true
			end
		end
	end
	if player:hasSkill("lihun") then
		for _,friend in ipairs(self.friends) do
			if friend:getHandcardNum() > 4 and friend:isMale() then
				return true
			end
		end
	end
	if (player:hasSkill("TH_moshenfusong") and player:getMark("@TH_moshenfusong") > 0) or player:hasSkill("TH_jiushizhiguang") then
		for _,enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 then
				return true
			end
		end
		return
	end
	if player:hasSkill("yanxiao") then
		local yanxiao_on
		for _,enemy in ipairs(self.enemies) do
			if enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage") then
				yanxiao_on = true
			end
		end
		if yanxiao_on then
			for _, card in sgs.qlist(player:getCards("he")) do
				if card:getSuit() == 3 then return true end
			end
		end
		return
	end
	if player:hasSkill("nosguose") and self:hasSuit("diamond", true, player) then return true end
	if player:hasSkill("duanliang") and self:hasSuit("club", true, player) then return true end
	if (player:hasSkill("wansha") and player:getMark("@chaos") > 0) or (player:hasSkill("shenfen") and player:getMark("@wrath") > 5) then
		for _, p in ipairs(self.friends) do
			if p:getHp() == 1 then return true end
		end
	end

	if player:hasSkill("jilve") and player:getMark("@bear") > 3 and player:getMark("@waked") > 0 then return true end
	if player:hasSkill("TH_fanhundie") and player:getMark("@TH_fhdonce") > 0 then return true end
	if player:hasSkill("jixi") and player:getPile("field"):length() > 1 and player:getMark("@waked") > 0 then return true end
	if player:hasSkill("paiyi") and player:getPile("power"):length() > 1 and player:getMark("@waked") > 0 then return true end
	if player:hasSkill("yinling") and player:getPile("junwei_equip"):length() < 5 then return true end
	if player:hasSkill("qixing") and player:getPile("stars"):length() > 0 then return true end
	if player:hasSkill("TH_yinhexi") and player:getPile("TH_yinhexi_pile"):length() > 6 then return true end
	if player:hasSkills("kurou") and player:getHp() > 2 then return true end
	if player:hasSkills("nosshangshi|shangshi") and player:getLostHp() > 2 then return true end
	if player:hasSkill("qiangxi") and (player:getHp() > 2 or player:getWeapon()) then return true end
	if player:hasSkill("TH_menghuanpaoying") and player:getLostHp() > 0 then return true end
	if player:hasSkill("TH_huaimiepaohou") and player:hasFlag("TH_huaimiepaohou_on") then return true end
	if player:hasSkill("TH_Nuclear") and player:getMark("@TH_nuclear") > 9 then return true end
	if player:hasSkill("TH_ZombieFairy") and self.room:getAlivePlayers():length() ~= self.room:getPlayers():length() then return true end
	if player:hasSkill("TH_guanglongzhitanxi") and player:getMark("@TH_yuyi") > 1 then return true end
	if player:hasSkill("TH_suiyue") and player:getMark("@TH_suiyue") > 0 then return true end

	return
end

function SmartAI:damageprohibit(player, dare, num)
	player = player or self.player
	dare = dare or "all"
	num = num or 1
	if dare == "all" then
		if sgs.ai_slash_prohibit.TH_Guilty(self, self.player, player, card) or sgs.ai_slash_prohibit.TH_brokencharm(self, self.player, player, card) then
			return true
		end
	elseif dare == "G" then
		if sgs.ai_slash_prohibit.TH_Guilty(self, self.player, player, card) or self.player:getHandcardNum() < num then return true end
	end
end


function SmartAI:getMaster(player)
	player = player or self.player
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:getMark("TH_ZombieFairy_Slave" .. player:objectName()) > 0 then return p end
	end
	return
end
----------------------------------------------
----------------------------------------------
----------------------------------------------

local TH_death_skill = {}
TH_death_skill.name = "TH_death"
table.insert(sgs.ai_skills, TH_death_skill)
TH_death_skill.getTurnUseCard = function(self, inclusive)
	local TH_skillcard = sgs.Card_Parse("#TH_deathCard:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_deathCard"] = function(card, use, self)
	for _,enemy in ipairs(self.enemies) do
		use.card = card
		if use.to then use.to:append(enemy) end
		return
	end
end

sgs.ai_skill_cardask["TH_Weapon_BailouLouguan_first"] = function(self, data, pattern, target, target2, arg)
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if self:canUseJieyuanDecrease(target) then return "." end
	if sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) == "." then return "." end
	if self:getCardsNum("Jink") < 2 and self:hasLoseHandcardEffective() then return "." end
	local jinks = self:getCards("Jink")
	-- global_room:writeToConsole("TH_bllg-jinks:" .. #jinks)
	for _, card1 in ipairs(jinks) do
		self.room:setCardFlag(card1, "AI_dummyUse")
		local isEffect = not self.room:isJinkEffected(self.player, card1)
		self.room:setCardFlag(card1, "-AI_dummyUse")
		if isEffect then
			for _, card2 in ipairs(jinks) do
				if card1:getSuit() == card2:getSuit() then continue end
				self.room:setCardFlag(card2, "AI_dummyUse")
				local isEffect = not self.room:isJinkEffected(self.player, card2)
				self.room:setCardFlag(card2, "-AI_dummyUse")
				if not isEffect then continue end
				if card1:getEffectiveId() == card2:getEffectiveId() then
					if card1:getEffectiveId() == -1 and card1:getSkillName() ~= card2:getSkillName() then return card1:toString() end
					continue
				end
				if card1:getSuit() ~= card2:getSuit() then return card1:toString() end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["TH_Weapon_BailouLouguan_second"] = function(self, data, pattern, target)
	local function getJink()
		for _, card in ipairs(self:getCards("Jink")) do
			self.room:setCardFlag(card, "AI_dummyUse")
			local isEffect = self.room:isJinkEffected(self.player, card)
			self.room:setCardFlag(card, "-AI_dummyUse")
			if isEffect then return card:toString() end
		end
		return "."
	end

	return getJink()
end

----******************************************************************************************************--
---------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------FlandreScarlet
local TH_ForbiddenFruits_skill = {}
TH_ForbiddenFruits_skill.name = "TH_ForbiddenFruits"
table.insert(sgs.ai_skills, TH_ForbiddenFruits_skill)
TH_ForbiddenFruits_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_ForbiddenFruitsCARD") then return end
	local TH_skillcard = sgs.Card_Parse("#TH_ForbiddenFruitsCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_ForbiddenFruitsCARD"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	for _, friend in ipairs(self.friends) do
		local id = self:askForCardChosen(friend, "hej", "dummy")
		if id ~= -1 then
			use.card = card
			if use.to then
				use.to:append(friend)
				if use.to:length() >= 3 then return end
			end
		end
	end

	function canChosen(to)
		if to:hasSkills("jieyin+xiaoji") and (to:getDefensiveHorse() or to:hasEquip("SilverLion")) then return true end
		if not to:hasEquip() and to:getJudgingAreaID():isEmpty() and to:getHandcardNum() == 1 and self:needKongcheng(to) then return false
		elseif to:getJudgingAreaID():isEmpty() and to:isKongcheng()
			and (self:hasSkills(sgs.lose_equip_skill, to) or to:getEquips():length() == 1 and self:needToThrowArmor(to)) then return false
		elseif not to:hasEquip() and to:isKongcheng() and to:getJudgingAreaID():length() == 1
			and (to:containsTrick("indulgence")
				or to:containsTrick("supply_shortage")
				or to:containsTrick("lightning") and self:getFinalRetrial(to, "lightning") ~= 1) then
			return false
		end
		return true
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:isAllNude() and canChosen(enemy) then
			use.card = card
			if use.to then
				use.to:append(enemy)
				if use.to:length() >= 3 then return end
			end
		end
	end
end

sgs.ai_use_priority.TH_ForbiddenFruitsCARD = 9
sgs.ai_choicemade_filter.cardChosen.TH_ForbiddenFruits = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_playerchosen.TH_Catadioptric = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return end
	self:sort(enemies, "hp")
	local da = self.room:getTag("TH_Catadioptric_DamageStruct"):toDamage()
	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, da.nature, da.from)
			and not self:needToLoseHp(enemy,da.from,da.card) then
			return enemy
		end
	end

	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, da.nature, da.from) then
			return enemy
		end
	end

	for _, enemy in ipairs(enemies) do
		return enemy
	end
	return
end
sgs.ai_target_revises.TH_Catadioptric = function(to,card,self,use)
    if card:isKindOf("IronChain") and ((self:isFriend(to) and to:isChained()) or (self:isEnemy(to) and not to:isChained())) then return true end
end
-- sgs.ai_use_revises.TH_Catadioptric = function(self,card,use)
-- 	if card:isKindOf("IronChain")
-- 	and not self.player:isChained()
-- 	then use.card = card 
-- 	use.to:append(self.player) end
-- end
sgs.ai_useto_revises.TH_Catadioptric = function(self, card, use, p)
	if card:isKindOf("IronChain")
	then
		if self:isFriend(p) and not p:isChained() then
			use.card = card
			use.to:append(p)
			return
		end
		return false
	end
end


sgs.ai_skill_playerchosen.TH_StarbowBreak = function(self, targets)
	local da = self.room:getTag("TH_StarbowBreak_DamageStruct"):toDamage()
	if da.to:hasSkill("TH_Catadioptric") and da.to:isChained() then return "." end

	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end

	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, da.nature, da.from)
			and not self:getDamagedEffects(enemy, self.player, da.card and da.card:isKindOf("Slash")) then
			return enemy
		end
	end

	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, da.nature, da.from) then
			return enemy
		end
	end

	for _, enemy in ipairs(enemies) do
		return enemy
	end
	return
end

local TH_Sosite_skill = {}
TH_Sosite_skill.name = "TH_Sosite"
table.insert(sgs.ai_skills, TH_Sosite_skill)
TH_Sosite_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_SositeCARD") then return end
	local TH_skillcard = sgs.Card_Parse("#TH_SositeCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_SositeCARD"] = function(card, use, self)
	sgs.ai_use_priority.TH_SositeCARD = 0

	local sb, toUse
	local slashs = self:getCards("Slash")
	if #slashs > 0 then
		for _, slash in ipairs(slashs) do
			local dummy_use = self:aiUseCard(slash, dummy())
			if dummy_use.card and dummy_use.to:length() > 0 then
				for _, t in sgs.qlist(dummy_use.to) do
					if t:getCardCount() == 1 and t:hasArmorEffect("SilverLion") and t:isWounded() then continue end
					if t:isNude() or self:getLeastHandcardNum(t) > 0 then continue end
					sgs.ai_use_priority.TH_SositeCARD = 3
					sb = t
					toUse = slash
					break
				end
			end
		end
	end

	if not sb and self:getOverflow() >= 0 then
		local to_dis = self:getOverflow()
		self:sort(self.enemies, "morehecard")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getCardCount() == 1 and enemy:hasArmorEffect("SilverLion") and enemy:isWounded() then continue end
			if self:getLeastHandcardNum(enemy) > 0 then continue end
			if enemy:getCardCount() > 0 and enemy:getCardCount() - 1 <= to_dis then
				sb = enemy
				break
			end
		end
	end

	if sb then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		local worthless = {}
		for _, c in ipairs(cards) do
			if (not toUse or c:getEffectiveId() ~= toUse:getEffectiveId())
				and (not self:isValuableCard(c) or (#self.enemies == 1 and self.player:aliveCount() < self.room:getPlayers():length())) then
				table.insert(worthless, c:getEffectiveId())
			end
		end
		if sb:getCardCount() == 1 then
			use.card = card
			if use.to then use.to:append(sb) end
			return
		elseif #worthless > 0 then
			if sb:getCardCount() - 1 >= #worthless then
				use.card = sgs.Card_Parse("#TH_SositeCARD:" .. table.concat(worthless, "+") .. ":")
				if use.to then use.to:append(sb) end
				return
			else
				local ids
				for i = 1, sb:getCardCount() - 1 do
					if not ids then ids = worthless[i] else ids = ids .. "+" .. worthless[i] end
				end
				use.card = sgs.Card_Parse("#TH_SositeCARD:" .. ids .. ":")
				if use.to then use.to:append(sb) end
				return
			end
		else
			use.card = card
			if use.to then use.to:append(sb) end
			return
		end
	end
end

sgs.ai_use_priority.TH_SositeCARD = 0
sgs.ai_card_intention.TH_SositeCARD = 30

-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------FlandreScarlet_Nos
local TH_huaidiao_skill = {}
TH_huaidiao_skill.name = "TH_huaidiao"
table.insert(sgs.ai_skills, TH_huaidiao_skill)
TH_huaidiao_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#TH_huaidiaoCARD") then
		local TH_skillcard = sgs.Card_Parse("#TH_huaidiaoCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_huaidiaoCARD"] = function(card, use, self)
	local duel = sgs.Sanguosha:cloneCard("duel")
	duel:deleteLater()

	local cmp = function(a, b)
		local v1 = getCardsNum("Slash", a) + a:getHp()
		local v2 = getCardsNum("Slash", b) + b:getHp()

		if self:needToLoseHp(a,self.player,duel) then v1 = v1 + 20 end
		if self:needToLoseHp(b,self.player,duel) then v2 = v2 + 20 end

		if not self:isWeak(a) and a:hasSkill("jianxiong") and not self.player:hasSkill("jueqing") then v1 = v1 + 10 end
		if not self:isWeak(b) and b:hasSkill("jianxiong") and not self.player:hasSkill("jueqing") then v2 = v2 + 10 end

		if not self:isWeak(a) and a:hasSkill("nosjianxiong") and not self.player:hasSkill("jueqing") then v1 = v1 + 10 end
		if not self:isWeak(b) and b:hasSkill("nosjianxiong") and not self.player:hasSkill("jueqing") then v2 = v2 + 10 end

		if self:needToLoseHp(a) then v1 = v1 + 5 end
		if self:needToLoseHp(b) then v2 = v2 + 5 end

		if self:hasSkills(sgs.masochism_skill, a) then v1 = v1 + 5 end
		if self:hasSkills(sgs.masochism_skill, b) then v2 = v2 + 5 end

		if not self:isWeak(a) and a:hasSkill("jiang") then v1 = v1 + 5 end
		if not self:isWeak(b) and b:hasSkill("jiang") then v2 = v2 + 5 end

		if a:hasLordSkill("jijiang") then v1 = v1 + self:getJijiangSlashNum(a) * 2 end
		if b:hasLordSkill("jijiang") then v2 = v2 + self:getJijiangSlashNum(b) * 2 end

		if v1 == v2 then return self:getDefenseSlash(a) < self:getDefenseSlash(b) end

		return v1 < v2
	end

	table.sort(self.enemies, cmp)

	local enemies = {}
	local forbidden = {}
	self:sort(self.enemies, "defenseSlash")
	for _, t in ipairs(self.enemies) do
		if not self:needToLoseHp(t,self.player,duel) then
			table.insert(enemies, t)
		else table.insert(forbidden, t) end
	end
	if #enemies == 0 and #forbidden > 0 then enemies = forbidden end

	local target
	for _, enemy in ipairs(enemies) do
		local canuse
		local slash2 = getCardsNum("Slash", enemy)
		canuse = self:getCardsNum("Slash") >= slash2
					or self:needToLoseHp(self.player, enemy, duel)
					or self:needToLoseHp(enemy,self.player,duel)
					or (slash2 < 1 and sgs.isGoodHp(self.player))
					or not self:hasTrickEffective(duel, self.player, enemy)

		if self:objectiveLevel(enemy) > 3 and not self.room:isProhibited(enemy, self.player, duel) and canuse
			and self:isGoodTarget(enemy, enemies, duel) and self:damageIsEffective(enemy) then
			target = enemy
			break
		end
	end

	if target then
		local godsalvation = self:getCard("GodSalvation")
		if godsalvation and self:willUseGodSalvation(godsalvation) and not use.isDummy
			and (not target:isWounded() or not self:hasTrickEffective(godsalvation, target, self.player)) then
			use.card = godsalvation
			return
		end

		use.card = card
		if use.to then use.to:append(target) end
		return
	end

	self:sort(self.enemies, "handcard")
	for _,enemy in ipairs(self.enemies) do
		if not self:hasTrickEffective(duel, self.player, enemy) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end

end

sgs.ai_use_priority.TH_huaidiaoCARD = 7.2

sgs.ai_card_intention["TH_huaidiaoCARD"]  = 88

sgs.ai_use_revises.TH_Laevatein = function(self, card, use)
	if card:isKindOf("Slash") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")
	then
		card:setFlags("Qinggang")
	end
end
----------------------------------------------------------
sgs.ai_skill_invoke.TH_qed = true
sgs.ai_skill_invoke.TH_cranberry = true

sgs.ai_need_damaged.TH_cranberry = function(self, attacker, player)
	if player:getHp() > 1 then return true end
	if getKnownCard(player, self.player, "Peach|Analeptic", true, "he") > 0 then return true end
	return false
end
sgs.ai_can_damagehp.TH_cranberry = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return (self:isEnemy(from) and from:faceUp()) or (self:isFriend(from) and not from:faceUp())
	end
end

sgs.ai_skill_invoke.TH_sichongcunzai = function(self, data)
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if (ap:hasSkill("TH_liandemaihuo") or ap:hasSkill("TH_Hypnosis")) and self:isEnemy(ap)
			and self:playerGetRound(ap) < self:playerGetRound(self.player) then
			return true
		end
	end

	if self.player:getLostHp() == 0 and #self.friends > #self.enemies then return false end
	local damage = data:toDamage()
	if self.player:getHp() > damage.damage or self.player:getHp() + self:getCardsNum("Peach") > damage.damage then
		if damage.from and damage.from:isLord() and self:isEnemy(damage.from) and self:isWeak(damage.from) then return false end
		if damage.from and self:isFriend(damage.from) and not damage.from:faceUp() then return false end
		if damage.damage >= 2 then return false end
		if self.player:getMark("TH_huanyue_wake") then return false end
		for _, p1 in sgs.qlist(self.room:getAlivePlayers()) do
			if p1:hasSkill("TH_wuwuweizhong") then
				for _, p2 in sgs.qlist(self.room:getAlivePlayers()) do
					if p2:isWeak() and self:isFriend(p1, p2) then return false end
				end
			end
		end
	end
	return true
end


sgs.ai_skill_invoke.TH_cranberry_turnover = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isFriend(damage.from) and not damage.from:faceUp() then return true
	else return damage.from:faceUp()
	end
end

sgs.ai_need_damaged.TH_sichongcunzai = function(self, attacker, player)
	if not player:hasSkill("TH_sichongcunzai") then return false end
	if self:getFinalRetrial() ~= 2 or player:getHp() > 1 then return true end
	return false
end
sgs.ai_can_damagehp.TH_sichongcunzai = function(self,from,card,to)
	if to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return to:hasSkill("TH_huanyue") and to:getMark("TH_huanyue_wake") == 0
	end
end

sgs.ai_cardneed.TH_scarlet = function(to, card)
	return card:isRed() and isCard("Slash", card, to)
end
sgs.ai_suit_priority.TH_scarlet = "club|spade|diamond|heart"
sgs.ai_ajustdamage_from.TH_scarlet = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:isRed() then
		return 1
	end
end
--------------------------------------------------------------------
-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------remiliascarlet
local TH_HeartBreak_skill = {}
TH_HeartBreak_skill.name = "TH_HeartBreak"
table.insert(sgs.ai_skills, TH_HeartBreak_skill)
TH_HeartBreak_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_HeartBreakCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_HeartBreakCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_HeartBreakCARD"] = function(card, use, self)
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slashes = self:getCards("Slash")
		for _,slash in sgs.list(slashes)do
			local dummy_use = self:aiUseCard(slash, dummy())
			if dummy_use.card then
				for _,p in sgs.qlist(dummy_use.to)do
					if p and self:isEnemy(p) then
						use.card = sgs.Card_Parse("#TH_HeartBreakCARD:.:")
						if use.to then use.to:append(p) end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.TH_HeartBreakCARD = 30
sgs.ai_use_priority.TH_HeartBreakCARD = 8

local TH_ScarletShoot_skill = {}
TH_ScarletShoot_skill.name = "TH_ScarletShoot"
table.insert(sgs.ai_skills, TH_ScarletShoot_skill)
TH_ScarletShoot_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_ScarletShootCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_ScarletShootCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_ScarletShootCARD"] = function(card, use, self)
	self:sort(self.enemies, 'morehcard')
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			use.card = card
			if use.to then use.to:append(enemy) return end
		end
	end
end

sgs.ai_card_intention.TH_ScarletShootCARD = 30
sgs.ai_use_priority.TH_ScarletShootCARD = 8

-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------remiliascarlet_nos

local TH_xingtai_skill = {}
TH_xingtai_skill.name = "TH_xingtai"
table.insert(sgs.ai_skills, TH_xingtai_skill)
TH_xingtai_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_xingtaiCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_xingtaiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_xingtaiCARD"] = function(card, use, self)
	if self:isWeak() and self.player:getMark("TH_xingtai1") == 0 then
		use.card = card
		return
	end
	if not self:isWeak() and self.player:getMark("TH_xingtai2") == 0 then
		use.card = card
		return
	end
end


sgs.ai_use_value.TH_xingtaiCARD = 9
sgs.ai_use_priority.TH_xingtaiCARD = 9.1

local TH_SpearTheGungnir_skill = {}
TH_SpearTheGungnir_skill.name = "TH_SpearTheGungnir"
table.insert(sgs.ai_skills, TH_SpearTheGungnir_skill)
TH_SpearTheGungnir_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_SpearTheGungnirCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_SpearTheGungnirCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_SpearTheGungnirCARD"] = function(card, use, self)

	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(enemy) and not enemy:hasSkill("TH_SpearTheGungnir") then
		use.card = card
		if use.to then use.to:append(enemy) end
			return
		end
	end
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) > 1 and not enemy:hasSkill("TH_SpearTheGungnir") then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasSkill("TH_SpearTheGungnir") then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_priority.TH_SpearTheGungnirCARD = 9
sgs.ai_card_intention.TH_SpearTheGungnirCARD = 74

sgs.ai_skill_cardask.TH_RemiliaStalker_discard = function(self, data, pattern, target)
	local effect = data:toCardEffect()
	local can
	if self:isFriend(effect.to) then
		if self:doDisCard(effect.to, "he") then can = true end
		if effect.to:hasSkill("kongcheng") and effect.to:getHandcardNum() == 1 then can = true end
	else
		if effect.to:getCardCount(true) > 0 and self:doDisCard(effect.to, "he") then can = true end
	end
	if can then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, true)
		return cards[1]:getEffectiveId()
	end
end

-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------izayoisakuya
local TH_TheWorld_skill = {}
TH_TheWorld_skill.name = "TH_TheWorld"
table.insert(sgs.ai_skills, TH_TheWorld_skill)
TH_TheWorld_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_theworld") == 0 then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_TheWorldCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_TheWorldCARD"] = function(card, use, self)
	if self.player:getHp() < 2 or self.player:getHandcardNum() == 0 then
		use.card = card
	end

	self:sort(self.enemies,"defense")
	if self:getCardsNum("Slash") == 0 then return end

	local slashs = self:getCards("Slash")
	if #slashs == 0 then return end
	for _, slash in ipairs(slashs) do
		for _,enemy in ipairs(self.enemies) do
			if not self:damageprohibit(enemy) and self:TheWuhun(enemy) >= 0 and self:damageIsEffective(enemy) and self.player:distanceTo(enemy) == 1
				and self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, self.player)
				and not enemy:hasArmorEffect("SilverLion") and self:hasCrossbowEffect() then
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.TH_TheWorldCARD = 9
sgs.ai_use_priority.TH_TheWorldCARD = 9
-----------------------------------------------------------------------------
sgs.ai_skill_invoke.TH_Eternal = function(self, data)
	local damage = data:toDamage()
	local to = damage.to

	if to:isChained() and self:isGoodChainTarget(to, damage.card, self.player, damage.damage) then return end
	if self:TheWuhun(to) < 0 then return true end

	local dmg = self:ajustDamage(self.player,to, 1, damage.card)
	if self:isFriend(to) then
		if not to:faceUp() then return true end
		if dmg > 1 or damage.damage > 1 or damage.damage > to:getHp() then return true end
	else
		if dmg > 1 or dmg > to:getHp() then return end
		if damage.damage > 1 or damage.damage > to:getHp() then return end

		if to:faceUp() then
			if self:isWeak() then return true end
			if to:getCardCount(false) >= 5 then return true end
			if (#self.enemies <= #self.friends and to:getHp() > 2) or (#self.enemies > #self.friends and to:getHp() > 2) then
				local sha = 0
				for _,friend in ipairs(self.friends_noself) do
					for _,enemy in ipairs(self.enemies) do
						if friend:canSlash(enemy, nil, true) then
							sha = sha + 1
							break
						end
					end
				end
				if sha > 1 then return true end
			end
		end
	end

	return
end

sgs.ai_canliegong_skill.TH_huanzang = function(self, from, to)
	return from:distanceTo(to) <= 1
end

sgs.ai_skill_cardask.TH_Sakuya = function(self, data)
	local da = data:toDamage()
	local needtodiscard = true
	if not self:damageIsEffective(self.player, da.nature, da.from)
		or self:needToLoseHp(self.player,da.from,da.card)
		or self.player:getMark("@TH_exileddoll") > 0
		then
		needtodiscard = false
	end
	if needtodiscard then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		if da.from and da.from:isMale() then
			for _, c in ipairs(cards) do
				if c:isBlack() then return c:getEffectiveId() end
			end
		elseif da.from and da.from:isFemale() then
			for _, c in ipairs(cards) do
				if c:isRed() then return c:getEffectiveId() end
			end
		else
			return cards[1]:getEffectiveId()
		end
	end
	return "."
end

function sgs.ai_cardneed.TH_Eternal(to, card, self)
	if not to:containsTrick("indulgence") and not to:getOffensiveHorse() then
		return card:isKindOf("OffensiveHorse") or card:isKindOf("Crossbow")
	end
end

sgs.TH_TheWorld_keep_value = {
	Jink = 2,
	Crossbow = 6,
}
sgs.ai_ajustdamage_from.TH_theworld = function(self, from, to, card, nature)
	if to and not to:faceUp() then
		return 1
	end
end

-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------hakureireimu
local TH_nafeng_skill = {}
TH_nafeng_skill.name = "TH_nafeng"
table.insert(sgs.ai_skills, TH_nafeng_skill)
TH_nafeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_nafeng") == 0 then return end
	if self.player:isLord() and sgs.turncount == 0 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_nafengCARD:.:")
	assert(TH_skillcard)
	if self:isWeak() then return TH_skillcard end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getWeapon() and enemy:getWeapon():isKindOf("Crossbow") and self:getCardsNum("Slash") > 0 then return TH_skillcard
		elseif self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") and self.player:inMyAttackRange(enemy)
			and self.player:canSlash(enemy, nil, true) and self:getCardsNum("Slash") > 0 then
			return TH_skillcard
		end
	end
end
sgs.ai_skill_use_func["#TH_nafengCARD"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_cardchosen.TH_nafengCARD = function(self, who, flags, method)
	if not self:hasCrossbowEffect() and self:getCardsNum("Crossbow") == 0 and who:hasWeapon("Crossbow") then return who:getWeapon() end
end

sgs.ai_use_priority.TH_nafengCARD = 8.8

---------------------------------------
sgs.ai_skill_invoke.TH_wujiecao = true
-------------------------------------

sgs.ai_need_damaged["#TH_bianshen_MagakiReimu"] = function(self, attacker, player)
	if not player:hasSkill("#TH_bianshen_MagakiReimu") then return false end
	if player:hasSkills("#TH_sishen|TH_shenji|TH_huanghuo|TH_zhongduotian") then return false end
	if player:aliveCount() == self.room:getPlayers():length() then return true end
	return false
end

sgs.TH_wujiecao_keep_value = { Crossbow = 7 }

-----------------------------------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@-------------kotiyasanae
local TH_wugufengdeng_skill = {}
TH_wugufengdeng_skill.name = "TH_wugufengdeng"
table.insert(sgs.ai_skills, TH_wugufengdeng_skill)
TH_wugufengdeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_wugufengdengCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_wugufengdengCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_wugufengdengCARD"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	targets:append(self.player)
	for _,ff in ipairs(self.friends_noself) do
		targets:append(ff)
		if targets:length() >= 5 then break end
	end
	use.card = card
	if use.to then use.to = targets end
	return
end

sgs.ai_skill_askforag.TH_wugufengdengCARD = function(self, card_ids)
	local NextPlayerCanUse
	local NextPlayer = self.player:getNextAlive()
	local np = NextPlayer
	while true do
		if self:isFriend(np) then
			if not self:willSkipPlayPhase(np) then
				NextPlayerCanUse = true
			end
			break
		else
			np = np:getNextAlive()
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if NextPlayerCanUse and enemy:hasSkill("lihun") and enemy:faceUp() and NextPlayer:getHandcardNum() > 4 and NextPlayer:isMale()
			and (not NextPlayer:faceUp() or self:playerGetRound(NextPlayer) > self:playerGetRound(enemy)) then
			NextPlayerCanUse = false
		end
	end

	local cards = {}
	local trickcard = {}
	for _, card_id in ipairs(card_ids) do
		local acard = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, acard)
		if acard:isKindOf("TrickCard") then
			table.insert(trickcard , acard)
		end
	end

	local nextfriend_num = 0
	local aplayer = self.player:getNextAlive()
	for i =1, self.player:aliveCount() do
		if self:isFriend(aplayer) then
			aplayer = aplayer:getNextAlive()
			nextfriend_num = nextfriend_num + 1
		else
			break
		end
	end

	local SelfisCurrent = true

---------------

	local needbuyi
	for _, friend in ipairs(self.friends) do
		if friend:hasSkill("buyi") and self.player:getHp() == 1 then
			needbuyi = true
		end
	end
	if needbuyi then
		local maxvaluecard, minvaluecard
		local maxvalue, minvalue = -100, 100
		for _, bycard in ipairs(cards) do
			if not bycard:isKindOf("BasicCard") then
				local value = self:getUseValue(bycard)
				if value > maxvalue then
					maxvalue = value
					maxvaluecard = bycard
				end
				if value < minvalue then
					minvalue = value
					minvaluecard = bycard
				end
			end
		end
		if minvaluecard and NextPlayerCanUse then
			return minvaluecard:getEffectiveId()
		end
		if maxvaluecard then
			return maxvaluecard:getEffectiveId()
		end
	end

	local friendneedpeach, peach
	local peachnum, jinknum = 0, 0
	if NextPlayerCanUse then
		if (not self.player:isWounded() and NextPlayer:isWounded()) or
			(self.player:getLostHp() < self:getCardsNum("Peach")) or
			(not SelfisCurrent and self:willSkipPlayPhase() and self.player:getHandcardNum() + 2 > self.player:getMaxCards()) then
			friendneedpeach = true
		end
	end
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			peach = card:getEffectiveId()
			peachnum = peachnum + 1
		end
		if card:isKindOf("Jink") then jinknum = jinknum + 1 end
	end
	if (not friendneedpeach and peach) or peachnum > 1 then return peach end

	local exnihilo, jink, analeptic, nullification, snatch, dismantlement, indulgence, yjjg
	for _, card in ipairs(cards) do
		if isCard("ExNihilo", card, self.player) then
			if not NextPlayerCanUse or (not self:willSkipPlayPhase() and (self:hasSkills("jizhi|zhiheng|rende|nosrende") or not self:hasSkills("jizhi|zhiheng", NextPlayer))) then
				exnihilo = card:getEffectiveId()
			end
		elseif isCard("EXCard_YJJG", card, self.player) then
			if not NextPlayerCanUse or (not self:willSkipPlayPhase() and (self.player:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende") or not NextPlayer:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende"))) then
				yjjg = card:getEffectiveId()
			end
		elseif isCard("Jink", card, self.player) then
			jink = card:getEffectiveId()
		elseif isCard("Analeptic", card, self.player) then
			analeptic = card:getEffectiveId()
		elseif isCard("Nullification", card, self.player) then
			nullification = card:getEffectiveId()
		elseif isCard("Snatch", card, self.player) then
			snatch = card
		elseif isCard("Dismantlement", card, self.player) then
			dismantlement = card
		elseif isCard("Indulgence", card, self.player) then
			indulgence = card
		end

	end

	for _, target in sgs.qlist(self.room:getAlivePlayers()) do
		if self:willSkipPlayPhase(target) or self:willSkipDrawPhase(target) then
			if nullification then return nullification
			elseif self:isFriend(target) and snatch and self:hasTrickEffective(snatch, target, self.player) and
				not self:willSkipPlayPhase() and self.player:distanceTo(target) == 1 then
				return snatch:getEffectiveId()
			elseif self:isFriend(target) and dismantlement and self:hasTrickEffective(dismantlement, target, self.player) and
				not self:willSkipPlayPhase() and self.player:objectName() ~= target:objectName() then
				return dismantlement:getEffectiveId()
			end
		end
	end

	if SelfisCurrent then
		if yjjg or exnihilo then return yjjg or exnihilo end
		if (jink or analeptic) and (self:getCardsNum("Jink") == 0 or (self:isWeak() and self:getOverflow() <= 0)) then
			return jink or analeptic
		end
		if indulgence then return indulgence end
	else
		local CP = self.room:getCurrent()
		local possible_attack = 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:inMyAttackRange(self.player) and self:playerGetRound(CP, enemy) < self:playerGetRound(CP, self.player) then
				possible_attack = possible_attack + 1
			end
		end
		if possible_attack > self:getCardsNum("Jink") and self:getCardsNum("Jink") <= 2 and self:getDefenseSlash(self.player) <= 2 then
			if jink or analeptic or yjjg or exnihilo then return jink or analeptic or yjjg or exnihilo end
		elseif yjjg or exnihilo or indulgence then return yjjg or exnihilo or indulgence
		end
	end

	if nullification and (self:getCardsNum("Nullification") < 2 or not NextPlayerCanUse) then
		return nullification
	end

	if jinknum == 1 and jink and self:isEnemy(NextPlayer) and (NextPlayer:isKongcheng() or getCardsNum("Jink", NextPlayer, self.player) < 1) then
		return jink
	end

	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		for _, skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			local callback = sgs.ai_cardneed[skill:objectName()]
			if type(callback) == "function" and callback(self.player, card, self) then
				return card:getEffectiveId()
			end
		end
	end

	local eightdiagram, silverlion, Vine, renwang, DefHorse, OffHorse
	local weapon, crossbow, halberd, double, qinggang, axe, gudingdao
	local stg, bllg, lwt, zafkiel, plyz, fxj
	for _, card in ipairs(cards) do
		if card:isKindOf("EightDiagram") then eightdiagram = card:getEffectiveId()
		elseif card:isKindOf("SilverLion") then silverlion = card:getEffectiveId()
		elseif card:isKindOf("Vine") then Vine = card:getEffectiveId()
		elseif card:isKindOf("RenwangShield") then renwang = card:getEffectiveId()

		elseif card:isKindOf("DefensiveHorse") and not self:getSameEquip(card) then DefHorse = card:getEffectiveId()
		elseif card:isKindOf("OffensiveHorse") and not self:getSameEquip(card) then OffHorse = card:getEffectiveId()

		elseif card:isKindOf("Crossbow") then crossbow = card
		elseif card:isKindOf("DoubleSword") then double = card:getEffectiveId()
		elseif card:isKindOf("QinggangSword") then qinggang = card:getEffectiveId()
		elseif card:isKindOf("Halberd") then halberd = card:getEffectiveId()
		elseif card:isKindOf("GudingBlade") then gudingdao = card:getEffectiveId()
		elseif card:isKindOf("TH_Weapon_Penglaiyuzhi") then plyz = card:getEffectiveId()
		elseif card:isKindOf("dal_Weapon_Zafkiel") then zafkiel = card:getEffectiveId()
		elseif card:isKindOf("TH_Weapon_Laevatein") then lwt = card:getEffectiveId()
		elseif card:isKindOf("TH_Weapon_Feixiangjian") then fxj = card:getEffectiveId()
		elseif card:isKindOf("TH_Weapon_BailouLouguan") then bllg = card:getEffectiveId()
		elseif card:isKindOf("Axe") then axe = card:getEffectiveId()
		elseif card:isKindOf("TH_Weapon_SpearTheGungnir") then stg = card:getEffectiveId() end

		if card:isKindOf("Weapon") then weapon = card:getEffectiveId() end
	end

	if eightdiagram then
		local lord = getLord(self.player)
		if not self:hasSkills("yizhong|bazhen") and self:hasSkills("tiandu|leiji|noszhenlie|gushou|hongyan") and not self:getSameEquip(card) then
			return eightdiagram
		end
		if NextPlayerisEnemy and self:hasSkills("tiandu|leiji|noszhenlie|gushou|hongyan", NextPlayer) and not self:getSameEquip(card, NextPlayer) then
			return eightdiagram
		end
		if self.role == "loyalist" and self.player:getKingdom()=="wei" and not self.player:hasSkill("bazhen") and
			lord and lord:hasLordSkill("hujia") and (lord:objectName() ~= NextPlayer:objectName() and NextPlayerisEnemy or lord:getArmor()) then
			return eightdiagram
		end
	end

	if silverlion then
		local lightning, canRetrial
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if aplayer:hasSkill("leiji") and self:isEnemy(aplayer) then
				return silverlion
			end
			if aplayer:containsTrick("lightning") then
				lightning = true
			end
			if self:hasSkills("guicai|guidao", aplayer) and self:isEnemy(aplayer) then
				canRetrial = true
			end
		end
		if lightning and canRetrial then return silverlion end
		if self.player:isChained() then
			for _, friend in ipairs(self.friends) do
				if friend:hasArmorEffect("Vine") and friend:isChained() then
					return silverlion
				end
			end
		end
		if self.player:isWounded() then return silverlion end
	end

	if Vine then
		if sgs.ai_armor_value.Vine(self.player, self) > 0 and self.room:alivePlayerCount() <= 3 then
			return Vine
		end
	end

	if renwang then
		if self:getCardsNum("Jink") == 0 then return renwang end
	end

	if DefHorse and (not self.player:hasSkill("leiji") or self:getCardsNum("Jink") == 0) then
		local before_num, after_num = 0, 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:canSlash(self.player, nil, true) then
				before_num = before_num + 1
			end
			if enemy:canSlash(self.player, nil, true, 1) then
				after_num = after_num + 1
			end
		end
		if before_num > after_num and (self:isWeak() or self:getCardsNum("Jink") == 0) then return DefHorse end
	end

	if analeptic then
		local slashs = self:getCards("Slash")
		for _, enemy in ipairs(self.enemies) do
			local hit_num = 0
			for _, slash in ipairs(slashs) do
				if self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash) and self:slashIsAvailable() then
					hit_num = hit_num + 1
					if getCardsNum("Jink", enemy) < 1
						or enemy:isKongcheng()
						or self.player:hasSkills("tieji|wushuang|dahe|qianxi")
						or self.player:hasSkill("roulin") and enemy:isFemale()
						or (self.player:hasWeapon("Axe") or self:getCardsNum("Axe") > 0) and self.player:getCards("he"):length() > 4
						then
						return analeptic
					end
				end
			end
			if (self.player:hasWeapon("Blade") or self:getCardsNum("Blade") > 0) and getCardsNum("Jink", enemy) <= hit_num then return analeptic end
			if self:hasCrossbowEffect(self.player) and hit_num >= 2 then return analeptic end
		end
	end

	if weapon and (self:getCardsNum("Slash") > 0 and self:slashIsAvailable() or not SelfisCurrent) then

		local current_range = self.player:getAttackRange()
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash")
		local slash = SelfisCurrent and self:getCard("Slash") or nosuit_slash

		self:sort(self.enemies, "defense")

		if crossbow then
			if self:getCardsNum("Slash") > 1 or self.player:hasSkills("kurou|keji")
				or (self.player:hasSkills("luoshen|yongsi|luoying|guzheng") and not SelfisCurrent and self.room:alivePlayerCount() >= 4) then
				return crossbow:getEffectiveId()
			end
			if self.player:hasSkill("guixin") and self.room:alivePlayerCount() >= 6 and (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0) then
				return crossbow:getEffectiveId()
			end
			if self.player:hasSkill("nosrende|rende") then
				for _, friend in ipairs(self.friends_noself) do
					if getCardsNum("Slash", friend) > 1 then
						return crossbow:getEffectiveId()
					end
				end
			end
			if self:isEnemy(NextPlayer) then
				local CanSave, huanggai, zhenji
				for _, enemy in ipairs(self.enemies) do
					if enemy:hasSkill("buyi") then CanSave = true end
					if enemy:hasSkill("jijiu") and getKnownCard(enemy, self.player, "red", nil, "he") > 1 then CanSave = true end
					if enemy:hasSkill("chunlao") and enemy:getPile("wine"):length() > 1 then CanSave = true end
					if enemy:hasSkill("kurou") then huanggai = enemy end
					if enemy:hasSkill("keji") then return crossbow:getEffectiveId() end
					if enemy:hasSkills("luoshen|yongsi|guzheng") then return crossbow:getEffectiveId() end
					if enemy:hasSkill("luoying") and card:getSuit() ~= sgs.Card_Club then return crossbow:getEffectiveId() end
				end
				if huanggai then
					if huanggai:getHp() > 2 then return crossbow:getEffectiveId() end
					if CanSave then return crossbow:getEffectiveId() end
				end
				if getCardsNum("Slash", NextPlayer) >= 3 and NextPlayerisEnemy then return crossbow:getEffectiveId() end
			end
		end

		if halberd then
			if self.player:hasSkills("nosrende|rende") and self:findFriendsByType(sgs.Friend_Draw) then return halberd end
			if SelfisCurrent and self:getCardsNum("Slash") == 1 and self.player:getHandcardNum() == 1 then return halberd end
		end

		if gudingdao then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and enemy:isKongcheng() and not enemy:hasSkill("tianming") and
				(not SelfisCurrent or (self:getCardsNum("Dismantlement") > 0 or (self:getCardsNum("Snatch") > 0 and self.player:distanceTo(enemy) == 1))) then
					return gudingdao
				end
			end
		end

		if double then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:getGender() ~= enemy:getGender() and self.player:canSlash(enemy, nil, true, range_fix) then
					return double
				end
			end
		end

		if stg then return stg end
		if bllg then return bllg end
		if fxj then return fxj end

		if axe then
			local range_fix = current_range - 3
			local FFFslash = self:getCard("FireSlash")
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasArmorEffect("Vine") and FFFslash and self:slashIsEffective(FFFslash, enemy) and
					self.player:getCardCount() >= 3 and self.player:canSlash(enemy, FFFslash, true, range_fix) then
					return axe
				elseif self:getCardsNum("Analeptic") > 0 and self.player:getCardCount() >= 4 and
					self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash, true, range_fix) then
					return axe
				end
			end
		end

		if qinggang or lwt then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and self:slashIsEffective(slash, enemy, self.player, true) and enemy:getArmor() then
					return lwt or qinggang
				end
			end
		end

		if zafkiel then
			local range_fix = current_range - 3
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and self:slashIsEffective(slash, enemy, self.player, true) and enemy:getHp() == 1 then
					return zafkiel
				end
			end
		end

		if plyz then
			local willuse = false
			if self.player:hasSkill("paoxiao") then willuse = true end
			if not willuse and not self.player:getWeapon() and sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash) > 0 then willuse = true end
			local range_fix = current_range - 1
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and self:slashIsEffective(slash, enemy, self.player, true) then
					return plyz
				end
			end
		end

	end

	local snatch, dismantlement, indulgence, supplyshortage, collateral, duel, aoe, godsalvation, fireattack
	local new_enemies = {}
	if #self.enemies > 0 then new_enemies = self.enemies
	else
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if sgs.ai_role[aplayer:objectName()] == "neutral" then
				table.insert(new_enemies, aplayer)
			end
		end
	end
	for _, card in ipairs(cards) do
		for _, enemy in ipairs(new_enemies) do
			if card:isKindOf("Snatch") and self:hasTrickEffective(card, enemy, self.player) and self.player:distanceTo(enemy) == 1 and not enemy:isNude() then
				snatch = card:getEffectiveId()
			elseif not enemy:isNude() and card:isKindOf("Dismantlement") and self:hasTrickEffective(card, enemy, self.player) then
				dismantlement = card:getEffectiveId()
			elseif card:isKindOf("Indulgence") and self:hasTrickEffective(card, enemy, self.player) and not enemy:containsTrick("indulgence") then
				indulgence = card:getEffectiveId()
			elseif card:isKindOf("SupplyShortage")	and self:hasTrickEffective(card, enemy, self.player) and not enemy:containsTrick("supply_shortage") then
				supplyshortage = card:getEffectiveId()
			elseif card:isKindOf("Collateral") and self:hasTrickEffective(card, enemy, self.player) and enemy:getWeapon() then
				collateral = card:getEffectiveId()
			elseif card:isKindOf("Duel") and self:hasTrickEffective(card, enemy, self.player) and
					(self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) or self.player:getHandcardNum() > 4) then
				duel = card:getEffectiveId()
			elseif card:isKindOf("AOE") then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					aoe = card:getEffectiveId()
				end
			elseif card:isKindOf("FireAttack") and self:hasTrickEffective(card, enemy, self.player) then
				local FFF
				local jinxuandi = self.room:findPlayerBySkillName("wuling")
				if jinxuandi and jinxuandi:getMark("@fire") > 0 then FFF = true end
				if self.player:hasSkill("shaoying") then FFF = true end
				if enemy:getHp() == 1 or enemy:hasArmorEffect("Vine") or enemy:getMark("@gale") > 0 then FFF = true end
				if FFF then
					local suits= {}
					local suitnum = 0
					for _, hcard in sgs.qlist(self.player:getHandcards()) do
						if hcard:getSuit() == sgs.Card_Spade then
							suits.spade = true
						elseif hcard:getSuit() == sgs.Card_Heart then
							suits.heart = true
						elseif hcard:getSuit() == sgs.Card_Club then
							suits.club = true
						elseif hcard:getSuit() == sgs.Card_Diamond then
							suits.diamond = true
						end
					end
					for k, hassuit in pairs(suits) do
						if hassuit then suitnum = suitnum + 1 end
					end
					if suitnum >=3 or (suitnum >= 2 and enemy:getHandcardNum() == 1 ) then
						fireattack = card:getEffectiveId()
					end
				end
			elseif card:isKindOf("GodSalvation") and self:willUseGodSalvation(card) then
				godsalvation = card:getEffectiveId()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if (self:hasTrickEffective(card, friend) and (self:willSkipPlayPhase(friend, true) or self:willSkipDrawPhase(friend, true))) or
				self:needToThrowArmor(friend) then
				if isCard("Snatch", card, self.player) and self.player:distanceTo(friend) == 1 then
					snatch = card:getEffectiveId()
				elseif isCard("Dismantlement", card, self.player) then
					dismantlement = card:getEffectiveId()
				end
			end
		end
	end

	if snatch or dismantlement or indulgence or supplyshortage or collateral or duel or aoe or godsalvation or fireattack then
		if not self:willSkipPlayPhase() or not NextPlayerCanUse then
			return snatch or dismantlement or indulgence or supplyshortage or collateral or duel or aoe or godsalvation or fireattack
		end
		if #trickcard > nextfriend_num + 1 and NextPlayerCanUse then
			return fireattack or godsalvation or aoe or duel or collateral or supplyshortage or indulgence or dismantlement or snatch
		end
	end

	if weapon and not self.player:getWeapon() and self:getCardsNum("Slash") > 0 and (self:slashIsAvailable() or not SelfisCurrent) then
		local inAttackRange
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				inAttackRange = true
				break
			end
		end
		if not inAttackRange then return weapon end
	end

	self:sortByCardNeed(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("TrickCard") and not card:isKindOf("Peach") then
			return card:getEffectiveId()
		end
	end

	return cards[1]:getEffectiveId()
end

sgs.ai_use_priority.TH_wugufengdengCARD = 9
sgs.ai_card_intention.TH_wugufengdengCARD = -85

local TH_Wonder_NwOBNS_skill = {}
TH_Wonder_NwOBNS_skill.name = "TH_Wonder_NwOBNS"
table.insert(sgs.ai_skills, TH_Wonder_NwOBNS_skill)
TH_Wonder_NwOBNS_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_Wonder_NwOBNSCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_Wonder_NwOBNSCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_Wonder_NwOBNSCARD"] = function(card, use, self)

	local friends = {}
	for _, p in ipairs(self.friends) do
		if p:getMark("TH_nwobns") == 0 then table.insert(friends, p) end
	end

	local arr1, arr2 = self:getWoundedFriend(nil, friends)
	for _, t in ipairs(arr1) do
		if self:isWeak(t) and not self:needToLoseHp(t, nil, nil, nil, true) then
			use.card = card
			if use.to then use.to:append(t) end
			return
		end
	end

	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 and enemy:getMark("@TH_nwobns") < 1 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end

	use.card = card
	if use.to then use.to:append(self.player) end
	return
end

sgs.ai_skill_choice.TH_Wonder_NwOBNS = function(self, choices)
	local target = self.room:getCurrent()
	if self:isFriend(target) then return "recoversb"
	else
		return "damagesb"
	end
end

sgs.ai_skillChoice_intention.TH_Wonder_NwOBNS = function(from, to, answer, self)
	if answer == "recoversb" then
		sgs.updateIntention(from, to, -103)
	elseif answer == "damagesb" then
		sgs.updateIntention(from, to, 103)
	end
end

sgs.ai_use_priority.TH_Wonder_NwOBNSCARD = 0.1
 ---------------------------------------------------
local TH_Miracle_GodsWind_skill = {}
TH_Miracle_GodsWind_skill.name = "TH_Miracle_GodsWind"
table.insert(sgs.ai_skills, TH_Miracle_GodsWind_skill)
TH_Miracle_GodsWind_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_Miracle_GodsWindCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_Miracle_GodsWindCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_Miracle_GodsWindCARD"] = function(card, use, self)

	if (self.role == "loayalist" or self.role == "lord") and sgs.gameProcess():match("loyalist")
		or self.role == "rebel" and sgs.gameProcess():match("rebel") then
		local targets = sgs.SPlayerList()
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHandcardNum() > 1 and enemy:getMark("@TH_godswind") == 0 and self:isWeak(enemy) then
				targets:append(enemy)
			end
		end
		if targets:length() > 0 then
			local target = self:findPlayerToDiscard("h", nil, true, targets)
			if target then
				use.card = card
				if use.to then use.to:append(target) end
				return
			end
		end
	end

	local friend = self:findPlayerToDraw(true, 2)
	if friend and friend:getMark("@TH_godswind") == 0 then
		use.card = card
		if use.to then use.to:append(friend) end
		return
	end

	self:sort(self.friends, "handcard")
	for _, ap in ipairs(self.friends) do
		if not ap:hasSkill("manjuan") and ap:getMark("@TH_godswind") == 0 then
			use.card = card
			if use.to then use.to:append(ap) end
			return
		end
	end

end

sgs.ai_skill_choice.TH_Miracle_GodsWind = function(self, choices)
	local target = self.room:getCurrent()
	if self:isFriend(target) then return "drawsb"
	else
		return "dissb"
	end
end

sgs.ai_skillChoice_intention.TH_Miracle_GodsWind = function(from, to, answer, self)
	if answer == "drawsb" then
		sgs.updateIntention(from, to, -103)
	elseif answer == "dissb" then
		sgs.updateIntention(from, to, 103)
	end
end

sgs.ai_use_priority.TH_Miracle_GodsWindCARD = 0.1
-----------------------------------------------------------------------------------------------------------------------------------------------------saigyoujiyuyuko
local TH_chihuo_skill = {}
TH_chihuo_skill.name = "TH_chihuo"
table.insert(sgs.ai_skills, TH_chihuo_skill)
TH_chihuo_skill.getTurnUseCard = function(self, inclusive)
	local cards=sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards) do
		if not card:isKindOf("BasicCard") and self.player:isWounded() then
			return sgs.Card_Parse(("peach:TH_chihuo[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
		end
	end
end
sgs.ai_view_as.TH_chihuo = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if not card:isKindOf("BasicCard") and (card_place == sgs.Player_PlaceEquip or card_place == sgs.Player_PlaceHand ) then
		return ("peach:TH_chihuo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value.TH_chihuo = 7
sgs.ai_use_priority.TH_chihuo = 1.5

local TH_fanhundie_skill = {}
TH_fanhundie_skill.name = "TH_fanhundie"
table.insert(sgs.ai_skills, TH_fanhundie_skill)
TH_fanhundie_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_fhdonce") == 0 then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_fanhundieCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_fanhundieCARD"] = function(card, use, self)

	local lord = self.room:getLord()
	if self:isEnemy(lord) and lord:getMark("@TH_fanhundie") == 0 and (self.role ~= "renegade" or self.player:aliveCount() == 2) then
		use.card = card
		if use.to then use.to:append(lord) end
		return
	end

	self:sort(self.enemies, "moredef")
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 and self:TheWuhun(enemy) >= 0 and self:damageIsEffective(enemy) and enemy:getMark("@TH_fanhundie") == 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_priority.TH_fanhundieCARD = 0.21
sgs.ai_card_intention.TH_fanhundieCARD = 180

local TH_xixingyao_skill = {}
TH_xixingyao_skill.name = "TH_xixingyao"
table.insert(sgs.ai_skills, TH_xixingyao_skill)
TH_xixingyao_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("TH_xixingyao1") > 0 or self.player:getMark("TH_xixingyao2") > 0
		or self.player:getMark("TH_xixingyao3") > 0 or self.player:getMark("TH_xixingyao4") > 0 then
		local TH_skillcard = sgs.Card_Parse("#TH_xixingyaoCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_xixingyaoCARD"] = function(card, use, self)
	if self.player:getHandcardNum() <= 2 and (self.player:getMark("TH_xixingyao1") > 0 or self.player:getMark("TH_xixingyao2") > 0) then
		use.card = card
	end
	if self.player:getLostHp() > 0 and (self.player:getMark("TH_xixingyao3") > 0 or self.player:getMark("TH_xixingyao4") > 0) then
		use.card = card
	end
end
sgs.ai_skill_invoke.TH_xixingyao=true

sgs.TH_chihuo_keep_value = {
	ThunderSlash = 1.51,
	FireSlash = 1.52,
	Analeptic = 4.5,
	Slash = 1.5,
	Peach = 5,
	Jink = 2.1,
	Nullification = 3,
	AmazingGrace = 2,
	Duel = 1.7,
	ExNihilo = 3.6,
	Indulgence = 1.5,
	Lightning = 2,
	Crossbow = 5,
	Blade = 5,
	Spear = 5,
	DoubleSword = 5,
	QinggangSword= 5,
	Axe = 5,
	KylinBow = 5,
	Halberd = 5,
	IceSword = 5,
	Fan = 5,
	MoonSpear = 5,
	GudingBlade = 5,
	DefensiveHorse = 5,
	OffensiveHorse = 5,
}

sgs.ai_use_priority.TH_xixingyaoCARD = 7

-----------------------------------------------------------------------------------------------------------------------------------------------------KonpakuYoumu
local TH_rengui_skill = {}--�˹�δ������ն
TH_rengui_skill.name = "TH_rengui"
table.insert(sgs.ai_skills, TH_rengui_skill)
TH_rengui_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_renguiCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_renguiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end

sgs.ai_skill_use_func["#TH_renguiCARD"] = function(card, use, self)
	self:sort(self.enemies,"hp")
	local terriblesouvenir, target
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 then
			if enemy:getMark("@TH_terriblesouvenir")>0 then
				terriblesouvenir = enemy
				break
			end
			if not target then
				target = enemy
			end
		end
	end
	local sb = terriblesouvenir or target
	if sb then
		use.card = card
		if use.to then use.to:append(sb) end
		return
	end
end

sgs.ai_use_priority.TH_renguiCARD = 5
sgs.ai_card_intention.TH_renguiCARD = 180
--------------------------------------------------------------------

local TH_erdaoliu_skill = {}--������
TH_erdaoliu_skill.name = "TH_erdaoliu"
table.insert(sgs.ai_skills, TH_erdaoliu_skill)
TH_erdaoliu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_erdaoliuCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_erdaoliuCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end

sgs.ai_skill_use_func["#TH_erdaoliuCARD"] = function(card, use, self)--����������
	local cards=sgs.QList2Table(self.player:getHandcards())
	if #cards == 0 then return false end
	self:sortByUseValue(cards, true)
	self:sort(self.enemies, "defense")
	local terriblesouvenir, target
	local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
	slash:addSubcard(cards[1]:getEffectiveId())
	for _,enemy in ipairs(self.enemies) do
		if self:slashIsEffective(slash, enemy) and self:TheWuhun(enemy) >= 0 and self.player:canSlash(enemy, nil, true) then
			if enemy:getMark("@TH_terriblesouvenir") > 0 then
				terriblesouvenir = enemy
				break
			end
			if not target then target = enemy end
		end
	end
	local sb = terriblesouvenir or target
	if sb then
		use.card = sgs.Card_Parse("#TH_erdaoliuCARD:" .. cards[1]:getEffectiveId() .. ":")
		if use.to then use.to:append(sb) end
		return
	end
end

sgs.ai_view_as.TH_erdaoliu = function(card, player, card_place) --������ ����
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
		return ("thunder_slash:TH_erdaoliu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["TH_erdaoliuCARD"] = 4
sgs.ai_use_priority["TH_erdaoliuCARD"] = 2.8
sgs.ai_card_intention["TH_erdaoliuCARD"]  = 77

------------------------------------------------------------------------------------------------------------------------------------------HouraisanKaguya

sgs.ai_card_intention.TH_YongyeguifanDaixiaoCARD = 10
------------------------------------------------------------------------------------------------------------------------------------------HouraisanKaguya_Nos
local TH_nanti_skill = {}--����
TH_nanti_skill.name = "TH_nanti"
table.insert(sgs.ai_skills, TH_nanti_skill)
TH_nanti_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_nantiCARD") then return false end
		local TH_skillcard = sgs.Card_Parse("#TH_nantiCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
sgs.ai_skill_use_func["#TH_nantiCARD"] = function(card, use, self)--����

	self:sort(self.friends,"hp")
	for _, friend in ipairs(self.friends) do
		if friend:getEquips():length() > 0 then
			if friend:hasSkill("xiaoji") or ((friend:hasArmorEffect("SilverLion") and friend:isWounded() and not self:hasSkills(sgs.use_lion_skill, friend))) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getCardCount(false)>0 and not enemy:hasSkill("TH_mingke") then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end


sgs.ai_skill_choice.TH_nanti = function(self, choices, data)--��ҹ������
	if  #self.friends >= 3 and  #self.enemies == 1 then
		local suicidemark = nil
		for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:getMark("TH_nanti_suicideno") < 1 then
				suicidemark = ap
			end
		end
		if suicidemark == nil and sgs.turncount > 1 then
			return "nantisuicide"
		end
	end

	local id = data:toInt()
	local x = sgs.Sanguosha:getCard(id):getNumber()
	local choice = { "nantisuit", "nantiequip" }
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("TH_nanti_target") > 0 and not self:isFriend(p) then

			if x == 13 and self:getMaxCard(p) ~= 13 then
				return "nantibig"
			elseif x == 1 and self:getMinCard(p) ~= 1 then
				return "nantismall"
			end

			if x == 12 and p:getHandcardNum() < 7 and p:getHandcardNum() > 0 then
				return "nantibig"
			elseif x==12 and  p:getHandcardNum() >= 7 then
				return choice[math.random(1, 2)]
			end
			if x == 2  and p:getHandcardNum() < 7 and p:getHandcardNum() > 0 then
				return "nantismall"
			elseif x == 2  and p:getHandcardNum() >= 7 then
				return choice[math.random(1,2)]
			end
			if p:getHandcardNum() == 1 and x >2 and x<12 then
				return "nantisuit"
			end

			if p:getHandcardNum() > 1 and x > 2 and x < 12 then
				if p:getEquips():length() > 0 and not p:hasSkills(sgs.lose_equip_skill) then
						return "nantiequip"
				elseif p:getEquips():isEmpty() then
					return choice[math.random(1,2)]
				end
			end

		elseif p:getMark("TH_nanti_target") > 0 and self:isFriend(p) then
			if p:hasSkills(lose_equip_skill) and p:getEquips():length() > 0 then
				return  "nantiequip"
			elseif p:hasArmorEffect("SilverLion") and p:isWounded() then
				return "nantiequip"
			end
		end
	end
end


sgs.ai_skillChoice_intention.TH_nantiCARD = function(from, to, answer, self)
	local room = from:getRoom()
	local target
	for _,ap in sgs.qlist(room:getOtherPlayers(from)) do
		if ap:getMark("TH_nanti_target")>0  then
			target = ap
			break
		end
	end
	if not target then return end
	local intention = 88
	if answer == "nantiequip" and (target:hasArmorEffect("SilverLion") and target:isWounded() or target:hasSkill("xiaoji") and target:getEquips():length() > 0) then
		intention = 0
	end
	sgs.updateIntention(from, target, intention)
end

sgs.ai_skill_cardask["@TH_nanti4"] = function(self, data)--��ҹ������

	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isKindOf("EquipCard") then
			table.insert(cards, card)
		end
	end
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

sgs.ai_skill_choice.TH_nantisuicide= function(self, choices)--��ҹ������
	if  #self.friends <2 and  #self.enemies>2 then
		return "suicideyes"
	else
		return "suicideno"
	end
 end

function sgs.ai_cardneed.TH_nanti(to, card, self)
	if not to:containsTrick("indulgence") then
		return card:isKindOf("BasicCard")
	end
end

sgs.ai_use_value.TH_nantiCARD = 8
sgs.ai_use_priority.TH_nantiCARD = 8
-----------------------
local TH_penglaiyuzhi_skill = {}--������֦
TH_penglaiyuzhi_skill.name = "TH_penglaiyuzhi"
table.insert(sgs.ai_skills, TH_penglaiyuzhi_skill)
TH_penglaiyuzhi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() and self.player:getPile("lightpile"):length() < 7  then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_penglaiyuzhiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_penglaiyuzhiCARD"] = function(card, use, self)--������֦
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	if self.player:getPile("lightpile"):length() >= 7 then
		use.card = card
		return
	end

	local i = 0
	for _, bcard in ipairs (cards) do
		if self.player:hasSkill("yongsi") and bcard:isKindOf("BasicCard") then
			use.card = sgs.Card_Parse("#TH_penglaiyuzhiCARD:" .. bcard:getId() .. ":")
			return
		end
		if self.player:getHandcardNum() > self.player:getHp() then
			if bcard:isKindOf("BasicCard") and (not bcard:isKindOf("Peach") or self:getCardsNum("Peach") > 1) then
				use.card = sgs.Card_Parse("#TH_penglaiyuzhiCARD:"..bcard:getId()..":")
				return
			end
		elseif self.player:getHandcardNum() <= self.player:getHp() then
			if bcard:isKindOf("Slash") then
				use.card = sgs.Card_Parse("#TH_penglaiyuzhiCARD:"..bcard:getId()..":")
				return
			end
		end
	end
end

sgs.ai_use_value.TH_penglaiyuzhiCARD = 7
sgs.ai_use_priority.TH_penglaiyuzhiCARD = 0.01
-----------------------------------------------------------------------------------------------------------------------------------------------------YagokoroEirin
local TH_penglaizhiyao_skill = {}--����֮ҩ
TH_penglaizhiyao_skill.name = "TH_penglaizhiyao"
table.insert(sgs.ai_skills, TH_penglaizhiyao_skill)
TH_penglaizhiyao_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_plzy") > 0 then
		local TH_skillcard = sgs.Card_Parse("#TH_penglaizhiyaoCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_penglaizhiyaoCARD"] = function(card, use, self)--����֮ҩ

	self:sort(self.friends,"hp")
	for _, friend in ipairs(self.friends) do
		if friend:getHp() == 1 and self:isWeak(friend) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end

	local lord = self.room:getLord()
	if self:isFriend(lord) and lord:getHp() < self.player:getHp() and not lord:hasSkill("TH_sichongcunzai") and not lord:hasSkill("TH_yongyefan") and lord:getMark("Phoenixrevive")<1 then
		use.card=card
		if use.to then use.to:append(lord) end
		return
	end

	use.card = card
	if use.to then use.to:append(self.player) end
	return
end

sgs.ai_use_value.TH_penglaizhiyaoCARD = 8
sgs.ai_use_priority.TH_penglaizhiyaoCARD = 4
sgs.ai_card_intention["TH_penglaizhiyaoCARD"] = -122
--------------------------------------------
local TH_LifeGame_skill = {}--������Ϸ
TH_LifeGame_skill.name = "TH_LifeGame"
table.insert(sgs.ai_skills, TH_LifeGame_skill)
TH_LifeGame_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_LifeGameCARD") then return false end
		local TH_skillcard = sgs.Card_Parse("#TH_LifeGameCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
sgs.ai_skill_use_func["#TH_LifeGameCARD"] = function(card, use, self)--������Ϸ

	local terriblesouvenir, first, second
	self:sort(self.enemies,"hp")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and self:TheWuhun(enemy) >= 0 then
			if enemy:getMark("@TH_terriblesouvenir") > 0 then
				terriblesouvenir = enemy
				break
			elseif not self:needToLoseHp(enemy,self.player,nil) and not first then
				first = enemy
			else
				if not second then second = enemy end
			end
		end
	end

	local sb = terriblesouvenir or first or second
	if sb then
		use.card = card
		if use.to then use.to:append(sb) end
		return
	end
end

sgs.ai_use_value["TH_LifeGameCARD"] = 7
sgs.ai_use_priority["TH_LifeGameCARD"] = 7
sgs.ai_card_intention["TH_LifeGameCARD"]  = 108
---------------------------------------------------------------------------------------------------------------------------------------------------------ReisenUdongeinInaba
sgs.ai_cardneed.TH_xiepohuanjue = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.TH_huanlongyueni = true

sgs.ai_need_damaged.TH_huanlongyueni = function(self, attacker, player)
	if not player:hasSkill("TH_huanlongyueni") then return false end
	if player:getHp() > 1 and player:getEquips():length() + player:getHp() > 3 then return true end
	if player:getHp() == 1 and player:getEquips():length() >= 3 and
		(getCardsNum("Peach", player) + getCardsNum("Analeptic", player) > 0 or self:isFriend(player) and self:getCardsNum("Peach") > 0) then return true end
	return false
end
sgs.ai_can_damagehp.TH_huanlongyueni = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

sgs.ai_skill_askforyiji.TH_huanlongyueni = function(self, card_ids)
	local allcards, cards = {}, {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(allcards, sgs.Sanguosha:getCard(card_id))
		local ShouldGive
		if self:willSkipPlayPhase() and (self:willSkipDrawPhase() and self:getOverflow() >= 0 or self:getOverflow() >= -2) then ShouldGive = true end
		if isCard("Peach", card, self.player) and self:getCardsNum("Peach") > self.player:getLostHp() then ShouldGive = true end
		if isCard("Analeptic", card, self.player) and not (self:getCardsNum("Peach") == 0 and self:isWeak() and self:getCardsNum("Analeptic") == 0) then ShouldGive = true end
		if not card:isKindOf("EquipCard") or self:hasSameEquip(card, self.player) then ShouldGive = true end
		if ShouldGive then table.insert(cards, sgs.Sanguosha:getCard(card_id)) end
	end

	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end

	if Shenfen_user then
		if self:isFriend(Shenfen_user) then
			if Shenfen_user:objectName() ~= self.player:objectName() then
				for _, id in ipairs(card_ids) do
					return Shenfen_user, id
				end
			else
				return nil, -1
			end
		else
			if self.player:getHandcardNum() < self:getOverflow(false, true) then
				return nil, -1
			end
			local card, friend = self:getCardNeedPlayer(cards)
			if card and friend and friend:getHandcardNum() >= 4 then
				return friend, card:getId()
			end
		end
	end

	if self.player:getHandcardNum() <= 2 and not Shenfen_user then
		return nil, -1
	end

	local new_friends = {}
	local CanKeep
	for _, friend in ipairs(self.friends) do
		if not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) and
		not self:needKongcheng(friend, true) and
		(not Shenfen_user or friend:objectName() == Shenfen_user:objectName() or friend:getHandcardNum() >= 4) then
			if friend:objectName() == self.player:objectName() then CanKeep = true
			else
				table.insert(new_friends, friend)
			end
		end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards)
		if card and target then
			for _, friend in ipairs(new_friends) do
				if target:objectName() == friend:objectName() then
					return friend, card:getEffectiveId()
				end
			end
		end
		if Shenfen_user and self:isFriend(Shenfen_user) then
			return Shenfen_user, allcards[1]:getEffectiveId()
		end
		if #cards == 0 then return end
		self:sort(new_friends, "defense")
		self:sortByKeepValue(cards, true)
		return new_friends[1], cards[1]:getEffectiveId()
	elseif CanKeep then
		return nil, -1
	end

end

local TH_yuetubingqi_skill = {}--���ñ���
TH_yuetubingqi_skill.name = "TH_yuetubingqi"
table.insert(sgs.ai_skills, TH_yuetubingqi_skill)
TH_yuetubingqi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_yuetubingqiCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_yuetubingqiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_yuetubingqiCARD"] = function(card, use, self)--���ñ���
	use.card = card
end

function sgs.ai_cardneed.TH_huanlongyueni(to, card, self)
	if to:containsTrick("indulgence") then return false end
	return not self:getSameEquip(card, to)
end

sgs.ai_use_priority["TH_yuetubingqiCARD"] = 10
---------------------------------------------------------------------------------------------------------------------------------------------------------FujiwaranoMokou
local TH_fengyitianxiang_skill = {}--��������
TH_fengyitianxiang_skill.name = "TH_fengyitianxiang"
table.insert(sgs.ai_skills, TH_fengyitianxiang_skill)
TH_fengyitianxiang_skill.getTurnUseCard = function(self, inclusive)
	for _,acard in sgs.qlist(self.player:getHandcards()) do
		if acard:isKindOf("FireSlash") then
			local TH_skillcard = sgs.Card_Parse("#TH_fengyitianxiangCARD:"..acard:getEffectiveId()..":")
			assert(TH_skillcard)
			return TH_skillcard
		end
	end
end
sgs.ai_skill_use_func["#TH_fengyitianxiangCARD"] = function(card, use, self)--��������
	local jiu
	if not self.player:hasUsed("Analeptic") and self:getCard("Analeptic") then
		jiu = self:getCard("Analeptic")
	end
	local fs = self:getCard("FireSlash")
	if self:UseAoeSkillValue(sgs.DamageStruct_Fire, nil, fs) > 0 then
		if jiu and not use.isDummy then use.card = jiu return end
		use.card = card
		return
	end
end

sgs.ai_use_priority["TH_fengyitianxiangCARD"] = 3

function sgs.ai_cardneed.TH_fengyitianxiang(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (isCard("FireSlash", card, to) and getKnownCard(to, "FireSlash", true) == 0)
	end
end

sgs.ai_canNiepan_skill.TH_Phoenixrevive = function(player)
	return player:getMark("Phoenixrevive") == 0
end

sgs.ai_skill_invoke.TH_bumie = function(self, data)---����
	if self:UseAoeSkillValue(sgs.DamageStruct_Fire) > 0 and self.player:getMark("Phoenixreviveon") < 1 and not self.player:containsTrick("indulgence") then
		return true
	end
end

sgs.ai_skill_invoke.TH_Phoenixrevive = true
---------------------------------------------------------------------------------------------------------------------------------------------------------shikieiki
function sgs.ai_slash_prohibit.TH_Guilty(self, from, to, card)
	return to:hasSkill("TH_Guilty") and self.player:getMark("@TH_guilty")>0 and self.player:isKongcheng()
end

local TH_shiwangshenpan_skill = {}-----ʮ������
TH_shiwangshenpan_skill.name = "TH_shiwangshenpan"
table.insert(sgs.ai_skills, TH_shiwangshenpan_skill)
TH_shiwangshenpan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("TH_shiwangshenpan_used") then return end
	local TH_skillcard = sgs.Card_Parse("#TH_shiwangshenpanCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_shiwangshenpanCARD"] = function(card, use, self)----ʮ������
	sgs.TH_shiwangshenpan_target = nil
	sgs.TH_shiwangshenpan_choice = nil

	local maxzui = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		maxzui = math.max(maxzui, p:getMark("@TH_guilty"))
	end
	if maxzui == 0 then return false end

	if self:isWeak() then
		local num_player, num_cards = 0, 0
		for _, pp in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if pp:getMark("@TH_guilty") > 0 and pp:getHandcardNum() > 0 then
				num_player = num_player + 1
				num_cards = num_cards + pp:getHandcardNum()
			end
		end
		if num_player > 2 then
			sgs.TH_shiwangshenpan_choice = "TH_swsp_all"
			use.card = card
			return
		end

		if num_player <= 2 then
			local otherplayers = sgs.QList2Table(self.room:getOtherPlayers(self.player))
			self:sort(otherplayers, "morehcard")
			for _, ppp in ipairs(otherplayers) do
				if ppp:getMark("@TH_guilty") == maxzui and ppp:getHandcardNum() > 0 and self:isEnemy(ppp) then
					sgs.TH_shiwangshenpan_choice = "TH_swsp_one"
					sgs.TH_shiwangshenpan_target = ppp
					use.card = card
					return
				end
			end
		end
	end

	local maxmarkenemy, bestmaxmarkenemy
	self:sort(self.enemies,"defense")
	for _,pp in ipairs(self.enemies) do
		if pp:getMark("@TH_guilty") == maxzui and pp:getHandcardNum()>1 then
			bestmaxmarkenemy = pp
			break
		end
	end
	if not bestmaxmarkenemy then
		for _,pp in ipairs(self.enemies) do
			if pp:getMark("@TH_guilty") == maxzui and  pp:getHandcardNum()>0 and self:isEnemy(pp) then
				maxmarkenemy=pp
				break
			end
		end
	end
	if  bestmaxmarkenemy or maxmarkenemy then
		sgs.TH_shiwangshenpan_choice = "TH_swsp_one"
		sgs.TH_shiwangshenpan_target = bestmaxmarkenemy or maxmarkenemy
		use.card = card
		return
	end

	local fp, ep = 0, 0
	for _, ppp in sgs.qlist(self.room:getAlivePlayers()) do
		if ppp:getMark("@TH_guilty") > 0 and not ppp:isKongcheng() then
			if self:isFriend(ppp) then
				fp=fp+1
			elseif self:isEnemy(ppp) then
				ep=ep+1
			end
		end
	end
	if  (ep == 0 and fp > 1) or (ep > 0 and fp > ep) then
		sgs.TH_shiwangshenpan_choice = "TH_swsp_all"
		use.card = card
		return
	end

end

sgs.ai_skill_choice.TH_shiwangshenpanCARD = function(self, choices)---ʮ������
	if sgs.TH_shiwangshenpan_choice then return sgs.TH_shiwangshenpan_choice end
	return "TH_swsp_one"
end

sgs.ai_skill_playerchosen.TH_shiwangshenpanCARD = function(self, targets)---ʮ������
	if sgs.TH_shiwangshenpan_target then return sgs.TH_shiwangshenpan_target end
	return targets:first()
end

sgs.ai_use_value["TH_shiwangshenpanCARD"] = 9.2
sgs.ai_use_priority["TH_shiwangshenpanCARD"] = 9.2
sgs.ai_playerchosen_intention.TH_shiwangshenpanCARD = 92
---------------------------------------------------------------
sgs.ai_skill_cardask["#TH_LastJudgement"] = function(self, data)------��������
	local judge = data:toJudge()
	local all_cards = sgs.QList2Table(self.player:getCards("he"))
	local all_hcards = sgs.QList2Table(self.player:getCards("h"))
	if #all_cards==0 then return "." end
	local cards = {}
	for _, card in ipairs(all_cards) do
		table.insert(cards, card)
	end
	local hcards={}
	for _, card in ipairs(all_hcards) do
		table.insert(hcards, card)
	end
	if #cards == 0 then return "." end

	if judge.who:hasSkill("TH_sichongcunzai") and self:isFriend(judge.who) and judge.who:getHp() > 1 then
		self:sortByKeepValue(cards)
		for _, bcard in ipairs(cards) do
			if bcard:getSuit() == 3 then
				return "#TH_LastJudgementCARD:"..bcard:getEffectiveId()..":"
			end
		end
	end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id then
		if not self:needRetrial(judge) and judge.who:hasSkill("luoshen") then return "." end
		if not self:needRetrial(judge) and judge.who:hasSkill("TH_sichongcunzai") then return "." end
		local newhcard = self:getRetrialCardId(hcards, judge, nil)
		if not newhcard then return end
		local newhcards = {}
		table.insert(newhcards, sgs.Sanguosha:getCard(newhcard))
		self:sortByKeepValue(newhcards)
		for _, acard in ipairs(newhcards) do
			if acard:isKindOf("Slash") or (acard:isKindOf("Jink") and self:getCardsNum("Jink")>1) then
				return "#TH_LastJudgementCARD:"..acard:getEffectiveId()..":"
			end
		end
		for _,acard in ipairs(newhcards) do
			if (acard:isKindOf("Weapon")  and self.player:getWeapon()) or (acard:isKindOf("Armor") and self.player:getArmor()) or
			(acard:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse()) or (acard:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse()) then
				return "#TH_LastJudgementCARD:"..acard:getEffectiveId()..":"
			end
		end
		if self:needRetrial(judge) then
			local newhcard = self:getRetrialCardId(cards, judge, nil)
			local newhcards = {}
			table.insert(newhcards, sgs.Sanguosha:getCard(newhcard))
			self:sortByKeepValue(newhcards)
			for _, card in ipairs(newhcards) do
				return "#TH_LastJudgementCARD:"..card:getEffectiveId()..":"
			end
		end
	elseif card_id == -1 then
		if self:needRetrial(judge) then
			self:sortByKeepValue(hcards)
			for _, card in ipairs(hcards) do
				if self:getUseValue(card) >= 6 or self:getKeepValue(card) >= 6 then return end
				return "#TH_LastJudgementCARD:"..card:getEffectiveId()..":"
			end
		end
	end
	return "."
end
sgs.wizard_skill = sgs.wizard_skill .. "|TH_LastJudgement"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|TH_LastJudgement"
sgs.ai_cardneed.TH_LastJudgement = sgs.ai_cardneed.guicai
----------------------------------------------------------------------------------------------------------------------shameimaruaya
local TH_wenwenxinwen_skill = {}-----��������
TH_wenwenxinwen_skill.name = "TH_wenwenxinwen"
table.insert(sgs.ai_skills, TH_wenwenxinwen_skill)
TH_wenwenxinwen_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_wenwenxinwenCARD") then return false end
	if self.player:isKongcheng()then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_wenwenxinwenCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_wenwenxinwenCARD"] = function(card, use, self)----��������

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	local cards = sgs.QList2Table(self.player:getHandcards())
	local terriblesouvenir, bakatarget, btarget, atarget, targetc, normaltarget, sbtarget
	local slash = sgs.Sanguosha:cloneCard("slash")
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if self:slashIsEffective(slash, enemy) and not self:damageprohibit(enemy,"G",2) and self.player:canPindian(enemy) and self:TheWuhun(enemy) >= 0 then
			if enemy:getMark("@TH_terriblesouvenir") > 0 and ((max_point > 10 and self.player:getHp() > 2) or max_point == 13) and not terriblesouvenir then
				terriblesouvenir = enemy
				break
			end
			if enemy:hasSkill("TH_PerfectMath") and max_point > 9 and not bakatarget then
				bakatarget = enemy
			end
			if self.player:inMyAttackRange(enemy) and getCardsNum("Jink", enemy) < 1 and ((max_point > 11  and self.player:getHp() > 2) or max_point == 13)
				and not btarget then btarget = enemy end
			if self.player:inMyAttackRange(enemy) and ((max_point > 11  and self.player:getHp() > 1) or max_point == 13) and not atarget then
				atarget = enemy
			end
			if (max_point > 11  and self.player:getHp() >= 2 or max_point == 13) and enemy:getHandcardNum() == 1 and not targetc then
				targetc = enemy
			end
			if (max_point > 11  and self.player:getHp() >= 2) or max_point == 13 and not normaltarget then
				normaltarget = enemy
			end
			if not sbtarget and max_point >= 8 and (self.player:getLostHp() == 0 or self:getCardsNum("Peach") > 1 and self.player:getLostHp() <= 1) then
				sbtarget = enemy
			end
		end
	end

	if terriblesouvenir then
		use.card = sgs.Card_Parse("#TH_wenwenxinwenCARD:"..max_card:getEffectiveId()..":")
		if use.to then use.to:append(terriblesouvenir) end
		return
	end
	if bakatarget then
		self:sortByUseValue(cards, true)
		for _,card in ipairs(cards) do
			if card:getNumber() > 9 then
				use.card = sgs.Card_Parse("#TH_wenwenxinwenCARD:"..card:getEffectiveId()..":")
				if use.to then use.to:append(bakatarget) end
				return
			end
		end
	end
	local to = btarget or atarget or targetc or normaltarget or sbtarget
	if to then
		use.card = sgs.Card_Parse("#TH_wenwenxinwenCARD:"..max_card:getEffectiveId()..":")
		if use.to then use.to:append(to) end
		return
	end
end

sgs.ai_skill_invoke.TH_IllusionaryDominance = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to)
end
sgs.ai_skill_invoke.TH_fengshenshaonv = function(self, data)
	if self.player:containsTrick("YanxiaoCard") then return false end
	if self.player:getJudgingArea():length() == 1 and self.player:containsTrick("lightning") and self:getFinalRetrial() == 1 then return false end
	return true
end

sgs.ai_cardneed.TH_wenwenxinwen = sgs.ai_cardneed.bignumber
sgs.ai_use_priority["TH_wenwenxinwenCARD"] = sgs.ai_use_priority.IronChain + 0.1
sgs.ai_use_value["TH_wenwenxinwenCARD"] = 7
sgs.ai_card_intention["TH_wenwenxinwenCARD"] = 85



---------------------------------------------------------------------------------------------------------------------------------------------------------kazamiyuuka
local TH_huaniaofengyue_skill = {}----�������
TH_huaniaofengyue_skill.name = "TH_huaniaofengyue"
table.insert(sgs.ai_skills, TH_huaniaofengyue_skill)
TH_huaniaofengyue_skill.getTurnUseCard = function(self, inclusive)--------------�������
	local TH_skillcard = sgs.Card_Parse("#TH_huaniaofengyueCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_huaniaofengyueCARD"] = function(card, use, self)-----------�������
	if self.player:getPile("TH_flower"):length() >=5 then
		use.card = card
	elseif (self.player:getHp() == 1 or self.player:getHandcardNum()<=1) and self.player:getPile("TH_flower"):length() > 0 then
		use.card = card
	end
end
sgs.ai_skill_invoke.TH_huaniaofengyue = function(self, data)---�������
	if self.player:getPile("TH_flower"):length() <1 then return false end
	local move = data:toMoveOneTime()
	if move.card_ids:length() > 1 and self.player:getPile("TH_flower"):length() >0 then
		return true
	elseif  move.card_ids:length() == 1 and self.player:getPile("TH_flower"):length() > 1 then
		return true
	end
end

sgs.ai_use_priority["TH_huaniaofengyueCARD"] = 6.9
---------------------------------------------------------------
local TH_YuukaSama_skill = {}----S
TH_YuukaSama_skill.name = "TH_YuukaSama"
table.insert(sgs.ai_skills, TH_YuukaSama_skill)
TH_YuukaSama_skill.getTurnUseCard = function(self, inclusive)---------------S
	if self.player:getPile("TH_flower"):length() < 1 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_YuukaSamaCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_YuukaSamaCARD"] = function(card, use, self)-----------S
	if self.player:getPile("TH_flower"):length() ==1 then
		local targets = sgs.SPlayerList()
		for _,enemy in ipairs(self.enemies) do
			if not enemy:isChained() and (enemy:hasArmorEffect("Vine") or enemy:getHp()==1 or getCardsNum("Jink", enemy) < 1.5) then
				if enemy:getMark("@TH_terriblesouvenir") > 0 then
					targets:append(enemy)
					if targets:length() >= 2 then break end
				end
			end
		end
		for _,friend in ipairs(self.friends_noself) do
			if friend:hasSkill("TH_mshi") and not friend:isChained() and targets:length() < 2 then
				targets:append(friend)
				if targets:length() >= 2 then break end
			end
		end
		for _,enemy in ipairs(self.enemies) do
			if not enemy:isChained() and (enemy:hasArmorEffect("Vine") or enemy:getHp()==1 or getCardsNum("Jink", enemy) < 1.5) and targets:length() < 2 then
				targets:append(enemy)
				if targets:length() >= 2 then
					break
				end
			end
		end
		if targets:length() == 2 then
			use.card = card
			if use.to then use.to = targets end
			return
		end
	elseif self.player:getPile("TH_flower"):length() >1 then
		local Mer = sgs.SPlayerList()
		for _,enemy in ipairs(self.enemies) do
			if enemy:getMark("@TH_terriblesouvenir") > 0 and not enemy:isChained() and Mer:length() < 2 then
				Mer:append(enemy)
				if Mer:length()>=2 then break end
			end
		end
		for _,friend in ipairs(self.friends_noself) do
			if friend:hasSkill("TH_mshi") and not friend:isChained() and Mer:length() < 2 then
				Mer:append(friend)
				if Mer:length() >= 2 then break end
			end
		end
		self:sort(self.enemies,"hp")
		for _,enemy in ipairs(self.enemies) do
			if Mer:length()<2 and not enemy:isChained() then
				Mer:append(enemy)
			end
			if Mer:length()>=2 then break end
		end
		if Mer:length() == 2 then
			use.card = card
			if use.to then use.to = Mer end
			return
		end
	end
end
sgs.ai_skill_invoke.TH_YuukaSama = function(self, data)---S
	local da = data:toDamage()
	if da.to:getLostHp() > 2 and self.player:getPile("TH_flower"):length() >0 and da.to:isAlive() then
		return true
	elseif da.to:getLostHp() == 2 and self.player:getPile("TH_flower"):length() > 1 and da.to:isAlive() and not da.to:isChained() then
		return true
	end
	if self:isFriend(da.to) and da.to:hasSkill("TH_mshi") and da.to:hasSkill("TH_tianjiedetaozi") then return true end
end
sgs.ai_use_value["TH_YuukaSamaCARD"] = 7
sgs.ai_use_priority["TH_YuukaSamaCARD"] = 7

sgs.ai_card_intention.TH_YuukaSamaCARD = 44
---------------------------------------------------------------------------------------------------------------------------------------------------------kirisamemarisa
local TH_MasterSpark_skill = {}----���޻�
TH_MasterSpark_skill.name = "TH_MasterSpark"
table.insert(sgs.ai_skills, TH_MasterSpark_skill)
TH_MasterSpark_skill.getTurnUseCard = function(self, inclusive)-------------���޻�
	if self.player:hasUsed("#TH_MasterSparkCARD") then return false end
	if self.player:isKongcheng() then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_MasterSparkCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_MasterSparkCARD"] = function(card, use, self)-----------���޻�
	self:sort(self.enemies,"hp")
	local terriblesouvenir, target
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and not self:damageprohibit(enemy,"G",2) and self:TheWuhun(enemy) >= 0 then
			if enemy:getMark("@TH_terriblesouvenir")>0 then
				terriblesouvenir = enemy
				break
			elseif not target then
				target = enemy
			end
		end
	end

	if terriblesouvenir then
		use.card = card
		if use.to then use.to:append(terriblesouvenir) end
		return
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.TH_MasterSparkEX = function(self, data)------���޻�
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("TH_MasterSpark_target") then
			target = p
			break
		end
	end
	if not target then return false end
	local x = target:getHp()

	--- @todo
	if target:getMaxHp() == 1 and not target:hasSkill("TH_mingke") then
		return true
	elseif target:getMaxHp() ==2 then
		if self:isEnemy(target) and not target:hasSkill("TH_mingke") and (self:getCardsNum("Jink") > 0 or self.player:getHp()>1)  then
			return true
		end
	elseif target:getMaxHp() == 3 then
		if self:isEnemy(target) and self:getDefenseSlash(self.player) > 6 and (self:getCardsNum("Jink") > 0 or self.player:getHp() > 1)  then
			return true
		end
	elseif target:getMaxHp() == 4 then
		if self:isEnemy(target) and self:getDefenseSlash(self.player) > 6 and self:getCardsNum("Jink") > 0 and self.player:getHp()>1 and target:getHp()>2 then
			return true
		end
	elseif target:getMaxHp() > 4 then
		if self:isEnemy(target) and self:getDefenseSlash(self.player) > 6 and self:getCardsNum("Jink") > 0 and self.player:getHp()>1 and not target:isWounded() then
			return true
		end
	end
	return false
end

sgs.ai_use_priority["TH_MasterSparkCARD"] = 3
sgs.ai_card_intention.TH_MasterSparkCARD = 83
function sgs.ai_armor_value.TH_MasterSpark(player, self, card)
    if card and card:isKindOf("EightDiagram") then return 4 end
end
sgs.ai_skill_cardask["@TH_MasterSpark"] = function(self, data, pattern)
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
-----------------------------------------
local TH_thethiefmarisa_skill = {}----���ħ��ɳ
TH_thethiefmarisa_skill.name = "TH_thethiefmarisa"
table.insert(sgs.ai_skills, TH_thethiefmarisa_skill)
TH_thethiefmarisa_skill.getTurnUseCard = function(self, inclusive)-------------���ħ��ɳ
	if self.player:hasUsed("#TH_thethiefmarisaCARD") then return end
	if self.player:hasSkill("TH_chihuo") and self.player:hasSkill("TH_MiracleofOtensui") and self.player:isWounded() then return end
	if self:hasSkills("TH_chihuo|TH_MiracleofOtensui|TH_jiushizhiguang") then
		for _, friend in ipairs(self.friends) do
			if friend:getHp()==1 and friend:getMaxHp() > 1 then return end
		end
	end
	if self.player:getHp()>2 then
		if self.player:hasSkill("TH_mifeng") and self.player:getHandcardNum() > 2 then return end
		if self:hasSkills("TH_nanti|TH_LifeGame|TH_rengui|TH_wujiecao|TH_MoreUnscientific") then return end
	end
	if self.player:getCards("e"):length() + self.player:getHp() >= 4 and self.player:hasSkill("TH_huanlongyueni") and self.player:getHp() > 1 then return end

	if self.player:hasSkill("TH_LastJudgement") then
		local judge=0
		for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:getCards("j"):length() > 0 then
				judge =judge+1
			end
		end
		if judge>0 and self.player:getCardCount(true) > 0 then return end
	end

	local TH_skillcard = sgs.Card_Parse("#TH_thethiefmarisaCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end

sgs.ai_skill_use_func["#TH_thethiefmarisaCARD"] = function(card, use, self)-----------���ħ��ɳ
	use.card = card
end

sgs.ai_skill_choice.TH_thethiefmarisa = function(self, choices)------���ħ��ɳ

	local str = choices
	choices = str:split("+")
	local cardh = sgs.QList2Table(self.player:getHandcards())
	local cardhe=sgs.QList2Table(self.player:getCards("he"))

	if str:matchOne("TH_death") then return "TH_death" end

	if str:matchOne("TH_jiushizhiguang")  then
		local willdie = 0
		for _,friend in ipairs(self.friends) do
			if friend:getHp()==1 and friend:getMaxHp() > 1 then
				willdie=willdie+1
			end
		end
		if willdie > 0 then return "TH_jiushizhiguang" end
	end

	local nb,willdie=0,0
	if str:matchOne("TH_chihuo") or str:matchOne("TH_MiracleofOtensui") then
		for _,nbcard in ipairs(cardhe) do
			if not nbcard:isKindOf("BasicCard") then
				nb=nb+1
			end
		end
		for _,friend in ipairs(self.friends) do
			if friend:getHp()==1 then
				willdie=willdie+1
			end
		end
		if (nb>0 and self.player:isWounded()) or (willdie>0 and nb>0) then
			return "TH_chihuo"
		end
		if #cardh>0 and self.player:isWounded() or willdie>0 then
			return "TH_MiracleofOtensui"
		end
	end

	if str:matchOne("TH_wuwuweizhong") then
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:hasSkill('TH_qed') then return "TH_wuwuweizhong" end
		end
	end

	if str:matchOne("TH_wujiecao") then return "TH_wujiecao" end

	if str:matchOne("TH_yuezhiyaoniao") and self.player:getHandcardNum() < 8 then return "TH_yuezhiyaoniao" end

	if str:matchOne("TH_liandemaihuo") then
		if #self.enemies > 0 and #self.friends_noself > 0 then
			local emax, fmin = 0, 100
			for _, enemy in ipairs(self.enemies) do
				emax = math.max(emax, enemy:getCardCount(true))
			end
			for _, friend in ipairs(self.friends) do
				fmin = math.min(fmin, friend:getCardCount(true))
			end
			if emax > fmin then
				return "TH_liandemaihuo"
			end
		end
	end

	if str:matchOne("TH_wuyishi") then return "TH_wuyishi" end

	if str:matchOne("TH_PhilosophersStone") then return "TH_PhilosophersStone" end

	if str:matchOne("TH_shitifanhuajie") then
		local x=0
		for _,p in sgs.qlist(self.room:getPlayers()) do
			if p:isDead() then
				x=x+1
			end
		end
		if x>3 then
			return "TH_shitifanhuajie"
		end
	end

	if str:matchOne("TH_ZombieFairy") then
		for _,p in sgs.qlist(self.room:getPlayers()) do
			if p:isDead() then
				return "TH_shitifanhuajie"
			end
		end
	end

	if self.player:getCards("e"):length() > 0 and str:matchOne("TH_huanlongyueni") then return "TH_huanlongyueni" end

	if self.player:getCards("he"):length() >= 4 and str:matchOne("TH_huaimiepaohou") then return "TH_huaimiepaohou" end

	if str:matchOne("TH_Hypnosis") then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getCardCount(true) > 4 then return "TH_Hypnosis" end
		end
	end

	if str:matchOne("TH_fengyitianxiang") and self:getCardsNum("FireSlash") > 0 and self:UseAoeSkillValue(sgs.DamageStruct_Fire) > 0 then
		return "TH_fengyitianxiang"
	end

	if str:matchOne("TH_MissingPower") and self.player:getHp() <= 2 and self:getCardsNum("Jink") > 1 then return "TH_MissingPower" end

	if self:getOverflow()>=3 and str:matchOne("TH_saiqianxiang") then return "TH_saiqianxiang" end

	if self.player:getHp()>=2 then
		if str:matchOne("TH_rengui") then
			return "TH_rengui"
		elseif str:matchOne("TH_MoreUnscientific") then
			return "TH_MoreUnscientific"
		elseif str:matchOne("TH_LifeGame") then
			return "TH_LifeGame"
		elseif str:matchOne("TH_Unscientific") then
			return "TH_Unscientific"
		elseif str:matchOne("TH_Science") then
			return "TH_Science"
		elseif str:matchOne("TH_wenwenxinwen") then
			return "TH_wenwenxinwen"
		elseif str:matchOne("TH_nanti") then
			return "TH_nanti"
		elseif str:matchOne("TH_mifeng") and self.player:getHandcardNum() > 2 then
			return "TH_mifeng"
		elseif str:matchOne("TH_shenlingdayuzhou") and self.player:getHandcardNum() > math.min(3, math.ceil(self.player:aliveCount())) then
			return "TH_shenlingdayuzhou"
		end
	end

	if str:matchOne("TH_GreatestTreasure") and self:getCardsNum("Santch") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if self.player:distanceTo(enemy) == 1 then
				return "TH_GreatestTreasure"
			end
		end
	end

	if str:matchOne("TH_hengong") and #self.enemies > 0 then
		self:sort(self.enemies,"hp")
		for  _, acard in sgs.qlist(self.player:getCards("he")) do
			if acard:getNumber() <= self.enemies[1]:getHp() then
				return "TH_hengong"
			end
		end
	end

	if self.player:getHp()>=2 and #cardh > 0 and #self.enemies>1 then
		if str:matchOne("TH_shengyusi") then
			return "TH_shengyusi"
		end
		if str:matchOne("TH_menghuanpaoying") then
			return "TH_menghuanpaoying"
		end
	end

	for _,enemy in ipairs(self.enemies) do
		if self:TheWuhun(enemy) and str:matchOne("TH_UnrememberedCrop") and #cardh > 2 then
			return "TH_UnrememberedCrop"
		end
	end

	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies) do
		if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") and not self.player:canSlash(enemy, nil, true) and self:getCardsNum("Slash")>0 and not self.player:inMyAttackRange(enemy) then
			if str:matchOne("TH_huimie") then
				return "TH_huimie"
			elseif str:matchOne("TH_SpearTheGungnir") then
				return "TH_SpearTheGungnir"
			end
		end
	end

	if str:matchOne("TH_LastJudgement") and self.player:getCardCount(true)>1 then
		local judge=0
		for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:getCards("j"):length() > 0 then
				judge =judge+1
			end
		end
		if judge>0 then
			return	"TH_LastJudgement"
		end
	end

	local defense_skill = {}
	local attack_skill = {}
	for _,att in ipairs(("TH_RemiliaStalker|TH_BadFortune|TH_hongsehuanxiangxiang|TH_huanzang|TH_erdaoliu|TH_IllusionaryDominance|TH_demacia"..
									"TH_xiepohuanjue|TH_Miracle_GodsWind|TH_YuukaSama|TH_Eternal|TH_aoyi_sanbubisha|TH_Meltdown|TH_BlazeGeyser"..
									"TH_GreatestCaution|TH_GalacticIllusion|TH_CosmicMarionnette|TH_longyudianzuan|TH_UndefinedUFO|TH_sanbuhuaifei"):split("|")) do
		if str:matchOne(att) then
			  table.insert(attack_skill,att)
		end
	end
	for _,def in ipairs(("TH_mingke|TH_cranberry|TH_sijianzhinaoOLD|TH_yongye|TH_Sakuya|TH_saiqianxiang|TH_huanlongyueni|"..
									"TH_yuetubingqi|TH_CatWalk|TH_tianjiedetaozi|TH_Detector|TH_NazrinPendulum|TH_UmbrellaCyclone|"..
									"TH_paratrooper|TH_huamaozhihuan"):split("|")) do
		if str:matchOne(def) then
			  table.insert(defense_skill,def)
		end
	end
	if self.player:getHp() >= 2 and #attack_skill > 0 then
		return attack_skill[math.random(1,#attack_skill)]
	elseif self.player:getHp() <= 1 and #defense_skill ~= 0 then
		return defense_skill[math.random(1,#defense_skill)]
	else
		return choices[math.random(1,#choices)]
	end
end

sgs.ai_use_priority["TH_thethiefmarisaCARD"] = 0.1
---------------------------------------------------------------------------------------------------------------------------------------------------------kagiyamahina
local TH_BadFortune_skill = {}----ج��
TH_BadFortune_skill.name = "TH_BadFortune"
table.insert(sgs.ai_skills, TH_BadFortune_skill)
TH_BadFortune_skill.getTurnUseCard = function(self, inclusive)-------------ج��
	if self.player:hasUsed("#TH_BadFortuneCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_BadFortuneCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_BadFortuneCARD"] = function(card, use, self)-----------ج��

	for _,enemy in ipairs(self.enemies) do
		if enemy:hasSkills("yongsi|TH_wujiecao|haoshi|nosjuejing|juejing|zishou|yingzi|nosyingzi") and not enemy:containsTrick("supply_shortage") then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:hasSkills("tuxi|shelie|shaungxiong|nosfuhun|TH_wuyishi|gongxin|qiaobian") and enemy:getMark("@TH_badfortune") < 1 and not enemy:containsTrick("supply_shortage") then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_priority.TH_BadFortuneCARD = 2.2
sgs.ai_card_intention.TH_BadFortuneCARD = 83
-------
sgs.ai_skill_playerchosen.TH_brokencharm = function(self, targets)
	local enemy = sgs.QList2Table(targets)
	self:sort(enemy,"hp")
	for _,ap in ipairs(enemy) do
		if self:isEnemy(ap) then
			return ap
		end
	end
	return targets:first()
end
-----
local TH_ExiledDoll_skill = {}----������ż
TH_ExiledDoll_skill.name = "TH_ExiledDoll"
table.insert(sgs.ai_skills, TH_ExiledDoll_skill)
TH_ExiledDoll_skill.getTurnUseCard = function(self, inclusive)-------------������ż
	if self.player:getMark("TH_ExiledDoll_used") == 1 then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_ExiledDollCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_ExiledDollCARD"] = function(card, use, self)-----------������ż
	self:sort(self.friends,"defense")
	for _,friend in ipairs(self.friends) do
		if friend:getHp()==1 then
			if friend:hasSkill("yiji")  and self:getAllPeachNum() > 0 then return false end
			if friend:hasSkill("TH_huanlongyueni")  and self:getAllPeachNum() > 0 and friend:getEquips():length()>1  then return false end
			if friend:hasSkill("TH_sichongcunzai") or friend:getMark("@TH_exileddoll") > 0 then return false end
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_skill_invoke.TH_ExiledDoll = function(self, data)-------������ż
	local da = data:toDamage()
	if not da or not da.to then return end
	if self:isFriend(da.to) then
		if da.to:hasSkill("yiji") and self:getAllPeachNum() > 0 then return false end
		if da.to:hasSkill("TH_huanlongyueni")  and self:getAllPeachNum() > 0 and da.to:getEquips():length() > 1  then return false end
		if da.to:hasSkill("TH_sichongcunzai") or da.to:getMark("@TH_exileddoll") > 0 then return false end
		return true
	end
end

function sgs.ai_slash_prohibit.TH_brokencharm(self, from, to, card)
	if not to:hasSkill("TH_brokencharm") then return false end
	for _,friend in ipairs(self.friends) do
		if friend:getMark("@TH_brokencharm") > 0 and friend:getHp() == 1 and self:getAllPeachNum() < 1 then
			return true
		end
	end
	return false
end

sgs.ai_need_damaged.TH_brokencharm = function(self, attacker, player)
	for _, target in ipairs(self:getEnemies(player)) do
		if target:getMark("@TH_brokencharm") > 0 then return true end
	end
	return false
end


sgs.ai_use_priority["TH_ExiledDollCARD"] = 4
sgs.ai_card_intention.TH_ExiledDollCARD = -122
sgs.ai_skillInvoke_intention.TH_ExiledDoll = function(from, to, yesorno, self)
	if yesorno == "yes" then
		for _, ap in sgs.qlist(self.room:getOtherPlayers(from)) do
			if ap:hasFlag("TH_ExiledDoll_target" .. from:objectName()) then
				from:speak("TH_ExiledDoll_target->" .. ap:getGeneralName())
				sgs.updateIntention(from, ap, -122)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------Yasakakanako
local TH_MiracleofOtensui_skill = {}----��������ˮ�漣��
TH_MiracleofOtensui_skill.name = "TH_MiracleofOtensui"
table.insert(sgs.ai_skills, TH_MiracleofOtensui_skill)
TH_MiracleofOtensui_skill.getTurnUseCard = function(self, inclusive)-------------��������ˮ�漣��
	if self.player:hasUsed("#TH_MiracleofOtensuiCARD") or self.player:isKongcheng() then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_MiracleofOtensuiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_MiracleofOtensuiCARD"] = function(card, use, self)-----------��������ˮ�漣��
	local hcard = self.player:getHandcards()
	cards=sgs.QList2Table(hcard)
	self:sortByUseValue(cards, true)

	if self.player:isWounded() and self:getOverflow()>1 then
		if self.player:isChained() and self:GoodChaintoRecover(self.player) then
			use.card = sgs.Card_Parse("#TH_MiracleofOtensuiCARD:"..cards[1]:getEffectiveId()..":")
			if use.to then use.to:append(self.player) end
				return
		elseif not self.player:isChained() then
			use.card = sgs.Card_Parse("#TH_MiracleofOtensuiCARD:"..cards[1]:getEffectiveId()..":")
			if use.to then use.to:append(self.player) end
			return
		end
	end

	local lord = self.room:getLord()
	if self:isFriend(lord) and not sgs.isLordHealthy()  and lord:isWounded() then
		use.card=sgs.Card_Parse("#TH_MiracleofOtensuiCARD:"..cards[1]:getEffectiveId()..":")
		if use.to then use.to:append(lord) end
		return
	end
	self:sort(self.friends,"hp")
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() and
			not (friend:hasSkill("longhun") and self:getAllPeachNum() > 0) and
			not (friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0 and self:getAllPeachNum() > 1) then
			if friend:isChained() and self:GoodChaintoRecover(friend) then
				use.card=sgs.Card_Parse("#TH_MiracleofOtensuiCARD:"..cards[1]:getEffectiveId()..":")
				if use.to then use.to:append(friend) end
				return
			elseif not friend:isChained() then
				use.card=sgs.Card_Parse("#TH_MiracleofOtensuiCARD:"..cards[1]:getEffectiveId()..":")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_value["TH_MiracleofOtensuiCARD"] = 8
sgs.ai_use_priority["TH_MiracleofOtensuiCARD"] = 5.1
sgs.ai_card_intention.TH_MiracleofOtensuiCARD = -102
-------------------------------------
sgs.ai_skill_use["@@TH_UnrememberedCrop"] = function(self, prompt)-------------����֮��
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)

	local he = self.player:getCards("he"):length()

	local sb = self.room:getCurrent()

	if self.player:getMark("TH_SanaeBuff1_on") < 1 then
		if self:isEnemy(sb) and (self:CanUseAttackSkill(sb) or self:getOverflow() > 2) and not sb:hasSkill("TH_UnrememberedCrop") then
			if sb:getHp() >= 3 and he > 1 then
				return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId()..":->"..sb:objectName())
			elseif sb:getHp() == 2 and (sb:objectName() == self.player:objectName() and he >= 4 or he > 2) then
				return	 ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":->"..sb:objectName())
			elseif sb:getHp() == 1 and (sb:objectName() == self.player:objectName() and he >= 5 or he > 3) then
				return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId().."+"..cards[3]:getEffectiveId()..":->"..sb:objectName())
			end
		elseif self:isFriend(sb) then
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkill("TH_UnrememberedCrop") then
					if ((self:TheWuhun(enemy) < 0 or self:undeadplayer(enemy)) and he > 2 and sb:canSlash(enemy, nil, true) and getCardsNum("Slash", sb, self.player) >= 1) and
					(sb:canSlash(enemy, nil, true) and self:getOverflow() > 3) then
						return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId().."+"..cards[3]:getEffectiveId()..":->%s"):format(enemy:objectName())
					end
					if (self:maixueplayer(enemy) or self:saveplayer(enemy)) and sb:canSlash(enemy, nil, true) and getCardsNum("Slash", sb, self.player) >= 1 then
						if enemy:getHp() >= 3 and (sb:objectName() == self.player:objectName() and he >= 3 or he > 1)  then
							return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId()..":->%s"):format(enemy:objectName())
						elseif enemy:getHp() == 2 and (sb:objectName() == self.player:objectName() and he >= 3 or he > 1) then
							return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":->%s"):format(enemy:objectName())
						elseif enemy:getHp() == 1 and (sb:objectName() == self.player:objectName() and he >= 4 or he > 2) then
							return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId().."+"..cards[3]:getEffectiveId()..":->%s"):format(enemy:objectName())
						end
					end
				end
			end
		end
	elseif self.player:getMark("TH_SanaeBuff1_on") == 1 then
		if self:isEnemy(sb) and (self:CanUseAttackSkill(sb) or self:getOverflow() > 3) and not sb:hasSkill("TH_UnrememberedCrop") then
			if sb:getHp()>=2 and he>1 then
				return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId()..":->%s"):format(sb:objectName())
			elseif sb:getHp()==1 and he>=2 then
				return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":->%s"):format(sb:objectName())
			end
		elseif self:isFriend(sb) then
			self:sort(self.enemies, "defense")
			for _,enemy in ipairs(self.enemies) do
				if not enemy:hasSkill("TH_UnrememberedCrop") then
					if ((self:TheWuhun(enemy) < 0 or self:undeadplayer(enemy)) and sb:canSlash(enemy, nil, true) and he > 2 and getCardsNum("Slash", sb, self.player) >= 1) then
						return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":->%s"):format(enemy:objectName())
					end
					if (self:maixueplayer(enemy) or self:saveplayer(enemy)) and sb:canSlash(enemy, nil, true) and getCardsNum("Slash", sb, self.player) then
						if enemy:getHp()>=2 and he >1 then
							return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId()..":->%s"):format(enemy:objectName())
						elseif enemy:getHp()==1 and he>2 then
							return ("#TH_UnrememberedCropCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":->%s"):format(enemy:objectName())
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.TH_UnrememberedCropCARD = 101
----------------------------------------------
local TH_MoutainOfFaith_skill = {}----����֮ɽ
TH_MoutainOfFaith_skill.name = "TH_MoutainOfFaith"
table.insert(sgs.ai_skills, TH_MoutainOfFaith_skill)
TH_MoutainOfFaith_skill.getTurnUseCard = function(self, inclusive)-------------����֮ɽ
	if self.player:getMark("@TH_faith") >= 5 then
		local TH_skillcard = sgs.Card_Parse("#TH_MoutainOfFaithCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	elseif self.player:getMark("@TH_faith") >= 3 and self.player:getMark("TH_SanaeBuff1_on") > 0 then
		local TH_skillcard = sgs.Card_Parse("#TH_MoutainOfFaithCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_MoutainOfFaithCARD"] = function(card, use, self)-----------����֮ɽ

	if self.player:getHandcardNum() <= 2 then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end

	local friend = self:findPlayerToDraw(true, 2)
	if friend then
		use.card = card
		if use.to then use.to:append(friend) end
		return
	end

	self:sort(self.friends, "defense")
	for _, ap in ipairs(self.friends) do
		if self:canDraw(ap,self.player) and not self:willSkipPlayPhase(ap) then
			use.card = card
			if use.to then use.to:append(ap) end
			return
		end
	end
end

sgs.ai_use_priority["TH_MoutainOfFaithCARD"] = 8
sgs.ai_card_intention.TH_MoutainOfFaithCARD = -88
---------------------------------------------------------------------------------------------------------------------------------------------------------Yakumoyukari,yakumoranyakumochen
sgs.ai_skill_invoke["#TH_bianshen_MaribelHearn"] = function(self, data)
	return math.random(1, 4) == 1
end

sgs.ai_skill_invoke.TH_sichongjiejie = function(self, data)-------���ؽ��
	if self.player:getHandcardNum() > 0 then return true end
	return
end

local TH_shishen_skill = {}----ʽ��
TH_shishen_skill.name = "TH_shishen"
table.insert(sgs.ai_skills, TH_shishen_skill)
TH_shishen_skill.getTurnUseCard = function(self, inclusive)-------------ʽ��
	self.TH_shishen_choice = nil
	if self.player:getMark("TH_shishen_off") > 0 then return end
	if self.player:hasSkills("TH_UnilateralContract+TH_qimendunjia") then return end
	local can
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then can = true break end
	end
	if can and not self.player:hasUsed("#TH_UnilateralContractCARD") and (not self.player:getGeneral2() or self.player:getGeneral2Name() ~= "YakumoRan") then
		self.TH_shishen_choice = "YakumoRan"
		local TH_skillcard = sgs.Card_Parse("#TH_shishenCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
	if self.player:hasUsed("#TH_UnilateralContractCARD") and self.player:getGeneral2Name() == "YakumoRan" then
		self.TH_shishen_choice = "YakumoChen"
		local TH_skillcard = sgs.Card_Parse("#TH_shishenCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_shishenCARD"] = function(card, use, self)-----------ʽ��
	use.card = card
end
sgs.ai_skill_choice.TH_shishen = function(self, choices)-----ʽ��
	if self.TH_shishen_choice then return self.TH_shishen_choice end
	if not self.player:hasUsed("#TH_UnilateralContractCARD") then
		return "YakumoRan"
	elseif self.player:hasUsed("#TH_shishenCARD") then
		return  "YakumoChen"
	end
end

sgs.ai_use_priority["TH_shishenCARD"] = 7

-------------------------------------------------------------------
local TH_shengyusi_skill = {}----�������ľ���
TH_shengyusi_skill.name = "TH_shengyusi"
table.insert(sgs.ai_skills, TH_shengyusi_skill)
TH_shengyusi_skill.getTurnUseCard = function(self, inclusive)-------------�������ľ���
	if self.player:hasUsed("#TH_shengyusiCARD") or self.player:isKongcheng() then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_shengyusiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end

sgs.ai_skill_use_func["#TH_shengyusiCARD"] = function(card, use, self)-----------�������ľ���
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	local terriblesouvenir, target
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies) do
		if self:TheWuhun(enemy) >= 0 and self:damageIsEffective(enemy) and not self:damageprohibit(enemy, "G", 2) and not self:needToLoseHp(enemy, self.player)
			and (self.player:getSeat() == self.room:getAlivePlayers():length() and enemy:getSeat() ~= 1 or enemy:getSeat() ~= self.player:getSeat() + 1)
			and (enemy:getLostHp() < 2 or (enemy:getHp() == 1 and (enemy:isKongcheng() and #self.enemies == 1 or self:getAllPeachNum(enemy) < 1)))  then
			if enemy:getMark("@TH_terriblesouvenir") > 0 then
				terriblesouvenir = enemy
				break
			end
			if not target then
				target = enemy
			end
		end
	end
	if terriblesouvenir then
		use.card = sgs.Card_Parse("#TH_shengyusiCARD:"..cards[1]:getEffectiveId()..":")
		if use.to then use.to:append(terriblesouvenir) end
		return
	end
	-- for _, friend in ipairs(friends) do
		-- if self:toTurnOver(friend, friend:getLostHp() + 1) then
			-- use.card = sgs.Card_Parse("#TH_shengyusiCARD:"..cards[1]:getEffectiveId()..":")
			-- if use.to then use.to:append(friend) end
			-- return
		-- end
	-- end
	if target then
		use.card = sgs.Card_Parse("#TH_shengyusiCARD:"..cards[1]:getEffectiveId()..":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority["TH_shengyusiCARD"] = 2.8
sgs.ai_card_intention.TH_shengyusiCARD = 10
-- sgs.ai_card_intention.TH_shengyusiCARD = function(self, card, from, tos)
	-- for _, to in ipairs(tos) do
		-- if self:getDamagedEffects(to, from) then
		-- else sgs.updateIntention(from, to, 10)
		-- end
	-- end
-- end

-------------------------------------------------------------------------------------
local TH_menghuanpaoying_skill = {}----�λ���Ӱ
TH_menghuanpaoying_skill.name = "TH_menghuanpaoying"
table.insert(sgs.ai_skills, TH_menghuanpaoying_skill)
TH_menghuanpaoying_skill.getTurnUseCard = function(self, inclusive)-------------�λ���Ӱ
	if self.player:hasUsed("#TH_menghuanpaoyingCARD") or self.player:isKongcheng() or self.player:getLostHp() == 0 then return end
	if self.player:getLostHp() > 1 and self:getCardsNum("Peach") > 0 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_menghuanpaoyingCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_menghuanpaoyingCARD"] = function(card, use, self)-----------�λ���Ӱ
	local cards=sgs.QList2Table(self.player:getHandcards())
	local allcards = {}
	for _, card in ipairs(cards) do
		table.insert(allcards, card:getEffectiveId())
	end
	local x = #allcards
	local sb = sgs.SPlayerList()

	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies) do
		if self:slashIsEffective(slash, enemy) and self:TheWuhun(enemy) >= 0 and not self:maixueplayer(enemy) and enemy:getMark("@TH_terriblesouvenir")>0
		and not sb:contains(enemy) and self:needToLoseHp(enemy,self.player,slash) then
			sb:append(enemy)
			if sb:length() >= x then
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies) do
		if self:slashIsEffective(slash, enemy) and self:TheWuhun(enemy) >= 0 and not self:maixueplayer(enemy) and not sb:contains(enemy)
			and not self:needToLoseHp(enemy,self.player,slash) then
			sb:append(enemy)
			if sb:length() >= x then
				break
			end
		end
	end

	if sb:length() < x then
		for _, friend in ipairs(self.friends) do
			if (self:maixueplayer(friend) or self:needToLoseHp(friend,self.player,slash)) and self:slashIsEffective(slash, friend) and self:TheWuhun(friend) >= 0 then
				sb:append(friend)
				if sb:length() >= x then
					break
				end
			end
		end
	end
	if sb:length() == 0 or sb:length() > x then return end
	if (sb:length() == 1 and x <= 2) or (sb:length() >= 2 and x - sb:length() <= 2) then
		local anal = self:getCard("Analeptic")
		if anal and sgs.Analeptic_IsAvailable(self.player, anal) and self.player:getHandcardNum() > 1 and not use.isDummy then
			use.card = self:getCard("Analeptic")
			return
		end
		use.card = sgs.Card_Parse("#TH_menghuanpaoyingCARD:" .. table.concat(allcards, "+") .. ":")
		if use.to then use.to = sb end
		return
	end
end

sgs.ai_use_priority["TH_menghuanpaoyingCARD"] = 2.0
-- sgs.ai_card_intention.TH_menghuanpaoyingCARD = 77
sgs.ai_card_intention.TH_menghuanpaoyingCARD = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if self:needToLoseHp(to,from,nil,true) then
		else sgs.updateIntention(from, to, 10)
		end
	end
end
---------------------���ͳ�
sgs.ai_skill_invoke.TH_qimendunjia = function(self, data)-------���Ŷݼ�
	local effect = data:toCardEffect()
	local card = effect.card
	if card:isKindOf("SkillCard") then
		if card:isKindOf("TuxiCard") then return true end
		return false
	end
	if card:isKindOf("LuaSkillCard") then
		if card:objectName() == "TH_TerribleSouvenirCARD" then return true end
		return false
	end
	if card:isKindOf("EXCard_YJJG") or card:isKindOf("EXCard_YYDL") then return false end
	if card:isKindOf("AmazingGrace") or card:isKindOf("Analeptic") or card:isKindOf("Peach") or card:isKindOf("GodSalvation") then return false end
	if effect.from and self:isFriend(effect.from) then
		if card:isKindOf("Nullification") or card:isKindOf("IronChain") then return false end
		if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and
			(self:willSkipPlayPhase(nil, true) or self:willSkipPlayPhase(nil, true)) then return false end
	end
	return true
end


local TH_UnilateralContract_skill = {}----Ƭ��������Լ
TH_UnilateralContract_skill.name = "TH_UnilateralContract"
table.insert(sgs.ai_skills, TH_UnilateralContract_skill)
TH_UnilateralContract_skill.getTurnUseCard = function(self, inclusive)-------------Ƭ��������Լ
	if self.player:hasUsed("#TH_UnilateralContractCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_UnilateralContractCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_UnilateralContractCARD"] = function(card, use, self)-----------Ƭ��������Լ
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_priority["TH_UnilateralContractCARD"] = 9
sgs.ai_card_intention["TH_UnilateralContractCARD"] = 50
---------------------------------------------------------------------------------------------------------------------------------------------------------cirno

local TH_chao9_skill = {}----���������ն
TH_chao9_skill.name = "TH_chao9"
table.insert(sgs.ai_skills, TH_chao9_skill)
TH_chao9_skill.getTurnUseCard = function(self, inclusive)-------------���������ն
	if self.player:hasUsed("#TH_chao9CARD")  then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_chao9CARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_chao9CARD"] = function(card, use, self)-----------���������ն
	local cards = sgs.QList2Table(self.player:getHandcards())
	local bakacard = {}
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards) do
		if acard:getNumber() == 9 and #bakacard < 2 then
			table.insert(bakacard, acard:getEffectiveId())
		end
	end
	assert(#bakacard <= 2)
	if #bakacard==0 then return false end

	local atarget,btarget,ctarget,dtarget,terriblesouvenir
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 and not self:damageprohibit(enemy, "G", #cards - #bakacard) then
			if enemy:getMark("@TH_terriblesouvenir")>0 and enemy:getMark("@TH_exileddoll") < 1 then
				terriblesouvenir=enemy
				break
			end
			if enemy:getKingdom()=="TH_kingdom_baka" and enemy:getMark("@TH_exileddoll") < 1 and not atarget then
				atarget = enemy
			end
			if not self:maixueplayer(enemy) and enemy:getMark("@TH_exileddoll") < 1 and not btarget then
				btarget = enemy
			end
			if enemy:getMark("@TH_exileddoll") < 1 and not ctarget then
				ctarget = enemy
			end
			if not dtarget then
				dtarget = enemy
			end
		end
	end

	local to = terriblesouvenir or atarget or btarget or ctarget or dtarget
	if #bakacard > 0 and to then
		use.card = sgs.Card_Parse("#TH_chao9CARD:"..table.concat(bakacard,"+")..":")
		if use.to then use.to:append(to) return end
		return
	end
end

sgs.ai_use_priority["TH_chao9CARD"] = 5.8
sgs.ai_card_intention.TH_chao9CARD = 99

sgs.TH_chao9_number_value = {
	["9"] = 1
}

function sgs.ai_cardneed.TH_chao9(to, card, self)
	if not to:containsTrick("indulgence") then
		return to:hasSkill("TH_PerfectMath") and card:getNumber() >= 9 or card:getNumber() == 9
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------------------komeijisatori
local TH_TerribleSouvenir_skill = {}------------�ֲ��Ļ���
TH_TerribleSouvenir_skill.name = "TH_TerribleSouvenir"
table.insert(sgs.ai_skills, TH_TerribleSouvenir_skill)
TH_TerribleSouvenir_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_TerribleSouvenirCARD") then return end
	if self.player:isKongcheng() then return end
	local hcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(hcards, true)
	local TH_skillcard = sgs.Card_Parse("#TH_TerribleSouvenirCARD:" .. hcards[1]:getEffectiveId().. ":")
	assert(TH_skillcard)
	return TH_skillcard
end

sgs.ai_skill_use_func["#TH_TerribleSouvenirCARD"] = function(card, use, self)------------�ֲ��Ļ���
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_card_intention.TH_TerribleSouvenirCARD = 88
sgs.ai_use_priority.TH_TerribleSouvenirCARD = 8.9

local TH_Hypnosis_skill = {}------------�ֲ�������
TH_Hypnosis_skill.name = "TH_Hypnosis"
table.insert(sgs.ai_skills, TH_Hypnosis_skill)
TH_Hypnosis_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self.player:hasUsed("#TH_HypnosisCARD") then return end
	local hcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(hcards, true)
	local TH_skillcard = sgs.Card_Parse("#TH_HypnosisCARD:" .. hcards[1]:getEffectiveId() .. ":")
	assert(TH_skillcard)
	return TH_skillcard
end

sgs.ai_skill_use_func["#TH_HypnosisCARD"] = function(card, use, self)------------�ֲ�������
	local xiaojicard = 0
	local ft
	for _, friend in ipairs(self.friends_noself) do
		if friend:getCardCount(true) > 0 and friend:hasSkill("xiaoji") and friend:getEquips():length() * 2 > friend:getHandcardNum() then
			xiaojicard = friend:getEquips():length() * 2 + friend:getHandcardNum()
			ft = friend
			break
		end
	end

	local maxhe = 0
	for _, enemy in ipairs(self.enemies) do
		if enemy:getCardCount(true) > 0 then
			local x = enemy:getHandcardNum()
			local y = enemy:getEquips():length()
			if enemy:hasSkills("tuntian|xuanfeng|nosxuanfeng") then
				x = x - 1
			end
			if enemy:hasSkill("xiaoji") then
				x = x - y
			end
			maxhe = math.max(maxhe, x + y)
		end
	end

	if ft and xiaojicard > maxhe then
		use.card = card
		if use.to then use.to:append(ft) end
		return
	end

	if maxhe > 0 then
		self:sort(self.enemies,"morehecard")
		for _,enemy in ipairs(self.enemies) do
			if enemy:getCardCount(true) >0 then
				local x = enemy:getHandcardNum()
				local y = enemy:getEquips():length()
				if enemy:hasSkills("tuntian|xuanfeng|nosxuanfeng") then
					x = x -1
				end
				if enemy:hasSkill("xiaoji") then
					x = x - y
				end
				if x + y >= maxhe then
					use.card = card
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

end

sgs.ai_card_intention.TH_HypnosisCARD = 108
sgs.ai_use_priority.TH_HypnosisCARD = 9

sgs.ai_skill_invoke.TH_ShyRose = function(self, data)
	local use = data:toCardUse()
	if not use.from then return end
	if use.from:getHandcardNum() == 1 and use.from:hasSkill("kongcheng") then
		if self:isFriend(use.from) then
			return true
		else
			return
		end
	end
	if self:isFriend(use.from) then return end
	sgs.TH_ShyRose_to = use.from
	return true
end

sgs.ai_skillInvoke_intention.TH_ShyRose = function(from, to, yesorno, self)
	if sgs.TH_ShyRose_to then
		sgs.updateIntention(from, sgs.TH_ShyRose_to, 82)
		sgs.TH_ShyRose_to = nil
	end
end

sgs.ai_skill_cardask["@TH_TerribleSouvenir"] = function(self, data, pattern)
    local damage = data:toDamage()
    if not self:needToLoseHp(self.player,damage.from,damage.card) then
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


---------------------------------------------------------------------------------------------------------------------------------------------------------komeijikoishi
sgs.ai_skill_invoke.TH_RoseHell = function(self, data)------------Ǿޱ����
	local da = data:toDamage()
	return not self:isFriend(da.from)
end
sgs.ai_can_damagehp.TH_RoseHell = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getHandcardNum() > 2
	end
end

function sgs.ai_slash_prohibit.TH_RoseHell(self, from, to, card)
	local black = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isBlack() then black = black + 1 end
	end
	return to:hasSkill("TH_RoseHell") and black / 2 >= self.player:getHp()
end

sgs.ai_skillInvoke_intention.TH_RoseHell = 82

sgs.ai_skill_invoke.TH_wuyishi=function(self,data)----------����ʶ
	return self.room:getDiscardPile():length() > 2
end

sgs.ai_skill_askforag.TH_wuyishi = function(self, card_ids)
	local toomuch
	if not self.player:isWounded() and self.player:getMaxCards() > 0 and self:getCardsNum("Peach") / self.player:getMaxCards() > 0.5 then tomuch = true end
	local cards = {}
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") and toomuch then continue end
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	if not toomuch then
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") then return card:getEffectiveId() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Indulgence") then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards)
	return cards[#cards]:getEffectiveId()
end

-------------------------------------
local TH_liandemaihuo_skill = {}----�������
TH_liandemaihuo_skill.name = "TH_liandemaihuo"
table.insert(sgs.ai_skills, TH_liandemaihuo_skill)
TH_liandemaihuo_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_liandemaihuoCARD") then return false end
	if self:hasCrossbowEffect() or self:getCardsNum("Corssbow") > 0 then
		sgs.ai_use_priority["TH_liandemaihuoCARD"] = 0
	elseif self.player:getCardCount() >= 5 then
		sgs.ai_use_priority["TH_liandemaihuoCARD"] = 2
	else
		sgs.ai_use_priority["TH_liandemaihuoCARD"] = 3
	end
	local TH_skillcard = sgs.Card_Parse("#TH_liandemaihuoCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_liandemaihuoCARD"] = function(card, use, self)---------�������
	local ftargets = {}
	local etargets = {}
	for _, pp in sgs.qlist(self.room:getAllPlayers()) do
		if pp:getCardCount() > 0 then
			if self:isFriend(pp) then
				table.insert(ftargets, pp)
			else
				table.insert(etargets, pp)
			end
		end
	end
	if #ftargets + #etargets < 2 then return end

	local emax, emin = 0, 100
	for _, et in ipairs(etargets) do
		local x = et:getCardCount()
		emax = math.max(emax, x)
		emin = math.min(emin, x)
	end

	local fmax, fmin = 0, 100
	for _, ft in ipairs(ftargets) do
		local x = ft:getCardCount()
		fmax = math.max(fmax, x)
		fmin = math.min(fmin, x)
	end
	
	local function morehecard(a, b)
		local c1 = a:getCardCount()
		local c2 = b:getCardCount()
		if c1 == c2 then
			return sgs.getDefense(a, self) > sgs.getDefense(b, self)
		else
			return c1 > c2
		end
	end

	if emax > fmin then
		local n1 = math.ceil(emax - fmin / 2)
		local n2 = math.ceil(fmax - fmin / 2)
		if n1 >= n2 - 2 or (emax >= 8 and emax - fmin >= 4) then
			if #etargets > 1 then table.sort(etargets, morehecard) end

			local function HEvalue(a, b)
				local function getvalue_HE(player)
					local value = player:getCardCount()
					if player:hasSkill("nosrende") then value = value - 2 end
					if player:hasSkill("rende") and not player:hasUsed("RendeCard") then value = value - 1.3 end
					if player:hasSkill("lirang") then value = value - 1.6 end
					if player:hasSkill("xiaoji") then value = value - 1 end
					if player:hasSkills("kofxiaoji|xuanfeng|nosxuanfeng") then value = value - 0.5 end
					if self:willSkipPlayPhase(player) and self:getOverflow(player, true) < emax then value = value + 5 end
					value = value + getKnownCard(player, self.player, "Peach") 
					value = value + self:playerGetRound(player) / 4
					return value
				end
				return getvalue_HE(a) < getvalue_HE(b)
			end

			if #ftargets > 1 then table.sort(ftargets, HEvalue) end
			if ftargets[1]:objectName() == self.player:objectName() then sgs.ai_use_priority["TH_liandemaihuoCARD"] = 0 end
			use.card = card
			if use.to then use.to:append(etargets[1]) use.to:append(ftargets[1]) end
			if not use.isDummy then
				if sgs.ai_role[etargets[1]:objectName()] ~= "neutral" then sgs.updateIntention(self.player, etargets[1], 10)
				elseif sgs.ai_role[ftargets[1]:objectName()] ~= "neutral" then sgs.updateIntention(self.player, ftargets[1], -10) end
			end
			return
		elseif #ftargets >= 2 then
			if #ftargets > 2 then table.sort(ftargets, morehecard) end
			use.card = card
			if use.to then use.to:append(ftargets[1]) use.to:append(ftargets[#ftargets]) end
			if not use.isDummy then
				if sgs.ai_role[ftargets[1]:objectName()] ~= "neutral" then sgs.updateIntention(self.player, ftargets[1], -10)
				elseif sgs.ai_role[ftargets[#ftargets]:objectName()] ~= "neutral" then sgs.updateIntention(self.player, ftargets[#ftargets], -10) end
			end
			return
		end
	else
		local n1 = math.ceil(emax - emin / 2)
		local n2 = math.ceil(fmax - fmin / 2)
		if n1 < n2 and #ftargets >= 2 then
			table.sort(ftargets, morehecard)
			use.card = card
			if use.to then use.to:append(ftargets[1]) use.to:append(ftargets[#ftargets]) end
			return
		elseif #etargets >= 2 then
			if #etargets > 2 then table.sort(etargets, morehecard) end
			use.card = card
			if use.to then use.to:append(etargets[1]) use.to:append(etargets[#etargets]) end
			return
		end
	end
	global_room:writeToConsole("")
	global_room:writeToConsole("TH_liandemaihuo")
	global_room:writeToConsole("fmax:" .. fmax .. ", fmin:" .. fmin .. ", emax:" .. emax .. ", emin:" .. emin)
end

sgs.ai_use_value["TH_liandemaihuoCARD"] = 7
sgs.ai_use_priority["TH_liandemaihuoCARD"] = 3

sgs.ai_card_intention.TH_liandemaihuoCARD = function(self, card, from, to)
	if not from:getAI() then
		local compare_func = function(a, b)
			return a:getCardCount() < b:getCardCount()
		end
		table.sort(to, compare_func)
		if sgs.ai_role[to[1]:objectName()] ~= sgs.ai_role[to[2]:objectName()] and to[1]:getCardCount() < to[2]:getCardCount() then
			sgs.updateIntention(from, to[1], -10)
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------------------hoshigumayuugi
local TH_huaimiepaohou_skill = {}----�����غ�
TH_huaimiepaohou_skill.name = "TH_huaimiepaohou"
table.insert(sgs.ai_skills, TH_huaimiepaohou_skill)
TH_huaimiepaohou_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasFlag("TH_huaimiepaohou_on") then return false end
	if self.player:getCardCount(true)==0 then return false end
	local slash = sgs.Sanguosha:cloneCard("slash")
	if self.player:isCardLimited(slash, sgs.Card_MethodUse) then return end
	local TH_skillcard = sgs.Card_Parse("#TH_huaimiepaohouCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_huaimiepaohouCARD"] = function(card, use, self)---------�����غ�
	local cards=sgs.QList2Table(self.player:getCards("he"))
	if #cards==0 then return false end
	self:sortByUseValue(cards,true)

	local lord = self.room:getLord()
	if self:isEnemy(lord) then
		for _,acard in ipairs(cards) do
			if not lord:hasSkills("jianxiong|nosjianxiong") or (not acard:isKindOf("Peach") and not acard:isKindOf("Jink") and not acard:isKindOf("Analeptic")) then
				local slash = acard:isKindOf("NatureSlash") and sgs.Sanguosha:cloneCard(acard:objectName(), acard:getSuit(), acard:getNumber()) or sgs.Sanguosha:cloneCard("slash")
				if self:slashIsEffective(slash,lord) and not self:damageprohibit(lord,"G", 2) then
					use.card = sgs.Card_Parse("#TH_huaimiepaohouCARD:"..acard:getEffectiveId()..":")
					if use.to then use.to:append(lord) end
					return
				end
			end
		end
	end

	self:sort(self.enemies,"defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("@TH_terriblesouvenir") > 0 then
			for _,acard in ipairs(cards) do
				if not enemy:hasSkills("jianxiong|nosjianxiong") or (not acard:isKindOf("Peach") and not acard:isKindOf("Jink") and not acard:isKindOf("Analeptic")) then
					local slash
					if acard:isKindOf("NatureSlash") then
						slash = sgs.Sanguosha:cloneCard(acard:objectName(), acard:getSuit(), acard:getNumber())
					else
						slash =  sgs.Sanguosha:cloneCard("slash")
					end
					if slash and self:slashIsEffective(slash,enemy) and not self:damageprohibit(enemy,"G", 2) and self:TheWuhun(enemy) >= 0 then
						use.card = sgs.Card_Parse("#TH_huaimiepaohouCARD:"..acard:getEffectiveId()..":")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end

		self:sort(self.enemies,"defense")
		for _, enemy in ipairs(self.enemies) do
			for _,acard in ipairs(cards) do
				if not enemy:hasSkills("jianxiong|nosjianxiong") or (not acard:isKindOf("Peach") and not acard:isKindOf("Jink") and not acard:isKindOf("Analeptic")) then
					local slash
					if acard:isKindOf("NatureSlash") then
						slash = sgs.Sanguosha:cloneCard(acard:objectName(), acard:getSuit(), acard:getNumber())
					else
						slash =  sgs.Sanguosha:cloneCard("slash")
					end
					if slash and self:slashIsEffective(slash,enemy) and not self:damageprohibit(enemy,"G", 2) and self:TheWuhun(enemy) >= 0 then
						use.card = sgs.Card_Parse("#TH_huaimiepaohouCARD:"..acard:getEffectiveId()..":")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end
end

sgs.ai_view_as.TH_huaimiepaohou = function(card, player, card_place)
	if not player:hasFlag("TH_huaimiepaohou_on") then return false end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceSpecial then return end
	local slash = card:isKindOf("NatureSlash") and card:objectName() or "slash"
	return (slash..":TH_huaimiepaohou[%s:%s]=%d"):format(suit, number, card_id)
end


sgs.ai_use_value["TH_huaimiepaohouCARD"] = 5
sgs.ai_use_priority["TH_huaimiepaohouCARD"]  = 4
-- sgs.ai_card_intention.TH_huaimiepaohouCARD = 88

sgs.ai_need_damaged.TH_huaimiepaohou = function(self, attacker, player)
	if not player:hasSkill("TH_huaimiepaohou") then return false end
	if player:getHp() > 2 and player:getMark("TH_huaimiepaohou_draw") == 0 and player:getCardCount(true) > 3 then return true end
	return false
end
sgs.ai_can_damagehp.TH_huaimiepaohou = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and to:getMark("TH_huaimiepaohou_draw") == 0
end
sgs.ai_cardneed.TH_huaimiepaohou = sgs.ai_cardneed.slash
sgs.ai_cardneed.TH_aoyi_sanbubisha = sgs.ai_cardneed.slash
---------------------------------------------------------------------------------------------------------------------------------------------------------hoshigumayuugi
local TH_Nuclear_skill = {}----�˵�
TH_Nuclear_skill.name = "TH_Nuclear"
table.insert(sgs.ai_skills, TH_Nuclear_skill)
TH_Nuclear_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_nuclear")<10 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_NuclearCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_NuclearCARD"] = function(card, use, self)

	local lord = self.room:getLord()
	if self:isEnemy(lord) and self:damageIsEffective(lord,sgs.DamageStruct_Fire) and self.player:getMark("TH_Nuclear_sb"..lord:objectName()) < 1 then
		use.card=card
		if use.to then use.to:append(lord) end
		return
	end

	self:sort(self.enemies,"morehp")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(lord,sgs.DamageStruct_Fire) and self.player:getMark("TH_Nuclear_sb"..enemy:objectName()) < 1 and self:TheWuhun(enemy) >= 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_priority["TH_NuclearCARD"] = 0.4
sgs.ai_card_intention.TH_NuclearCARD = 180

sgs.ai_skill_invoke.TH_BlazeGeyser=function(self, data)------------������ӿ
	local tg = {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:hasFlag("TH_BlazeGeyser_target" .. p:objectName()) then
			table.insert(tg, p)
		end
	end
	if #tg == 0 then return false end
	--global_room:writeToConsole("good is "..good)
	local good = self:UseAoeSkillValue(sgs.DamageStruct_Fire, tg)
	return good > 0
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------kaenbyouein
sgs.ai_skill_invoke.TH_CatWalk = function(self, data)
	local str = data:toStringList()
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then 
			use = self.room:getTag("UseHistory"..data:toStringList()[4]):toCardUse()
		end
	end
	if #str == 0 then return true end
	if str[1] == "slash" then
		if sgs.jijiangsource then return self:isFriend(sgs.jijiangsource) end
		if self.player:hasFlag("JijiangTarget") then return self:needToLoseHp(self.player, use.from, use.card) end
	elseif str[1] == "jink" then
		if sgs.hujiasource then return self:isFriend(sgs.hujiasource) end
		local prompt = str[2]:split(":")
		if prompt[1] == "slash-jink" and sgs.NatureSlash_data and self.player:isChained() then
			local use = sgs.NatureSlash_data:toCardUse()
			if use.from and prompt[2] == use.from:objectName() and use.to:contains(self.player)
				and self:isGoodChainTarget(self.player, use.card, use.from) then
				return false
			end
		end
	end
	return true
end

local TH_ZombieFairy_skill = {}----ɥʬ����
TH_ZombieFairy_skill.name = "TH_ZombieFairy"
table.insert(sgs.ai_skills, TH_ZombieFairy_skill)
TH_ZombieFairy_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("ban_TH_ZombieFairy") == 1 then return end
	if self.player:hasFlag("TH_ZombieFairy_used") then return end
	local TH_skillcard = sgs.Card_Parse("#TH_ZombieFairyCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_ZombieFairyCARD"] = function(card, use, self)
	local dplayer
	self.TH_ZombieFairy_unsummon = nil
	local zbs = {"KaenbyouRin_zabingjia", "KaenbyouRin_zabingyi", "KaenbyouRin_zabingbing"}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() then
			dplayer = true
		end
	end
	for _,ap in sgs.qlist(self.room:getAllPlayers()) do
		if (ap:getGeneralName() == "KaenbyouRin_zabingjia" or ap:getGeneralName() == "KaenbyouRin_zabingyi" or ap:getGeneralName() == "KaenbyouRin_zabingbing") and
		ap:getMark("TH_ZombieFairy_Slave"..self.player:objectName()) > 0 then
			for i in pairs(zbs) do
				if zbs[i] == ap:getGeneralName() then
					table.remove(zbs, i)
				end
			end
		end
	end

	if self.player:getRole() == "renegade" then
		if sgs.playerRoles["loyalist"] == 0 and sgs.playerRoles["rebel"] and #zbs < 3 then
			use.card = card
			self.TH_ZombieFairy_unsummon = "TH_ZombieFairy_unsummon"
			return
		end
	end

	if dplayer and #zbs > 0 then
		use.card = card
	end
end


sgs.ai_skill_choice.TH_ZombieFairy_shiti = function(self, choices)
	local players = choices:split("+")
	return players[1]
end

sgs.ai_skill_choice.TH_ZombieFairyCARD = function(self, choices)
	if self.TH_ZombieFairy_unsummon == "TH_ZombieFairy_unsummon" then
		self.room:setPlayerMark(self.player, "ban_TH_ZombieFairy", 1)
		return "TH_ZombieFairy_unsummon"
	end
	return "TH_ZombieFairy_summon"
 end

sgs.ai_use_priority["TH_ZombieFairyCARD"]  = 7.5

sgs.ai_event_callback[sgs.CardUsed].TH_ZombieFairyCARD = function(self, player, data)
	local use = data:toCardUse()
	if use.card and use.card:objectName() == "TH_ZombieFairyCARD" then
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if sb:hasFlag("TH_ZombieFairy_target") then
				-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
				-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
				sgs.roleValue[sb:objectName()]["renegade"] = 0
				sgs.roleValue[sb:objectName()]["loyalist"] = 0
				local role, value = sb:getRole(), 1000
				if role == "rebel" then role = "loyalist" value = -1000 end
				-- sgs.role_evaluation[sb:objectName()][role] = value
				-- sgs.ai_role[sb:objectName()] = sb:getRole()
				sgs.roleValue[sb:objectName()][sb:getRole()] = 1000
				sgs.ai_role[sb:objectName()] = sb:getRole()
				self.room:setPlayerFlag(sb, "-TH_ZombieFairy_target")
				self:updatePlayers()
			end
		end
	end
end


local TH_GreatestCaution_skill = {}----�Ұ���������
TH_GreatestCaution_skill.name = "TH_GreatestCaution"
table.insert(sgs.ai_skills, TH_GreatestCaution_skill)
TH_GreatestCaution_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_GreatestCautionCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_GreatestCautionCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_GreatestCautionCARD"] = function(card, use, self)
	local terriblesouvenir, target
	self:sort(self.enemies,"hp")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy,sgs.DamageStruct_Thunder) and self:TheWuhun(enemy) >= 0 then
			if enemy:getMark("@TH_terriblesouvenir")>0 then
				terriblesouvenir = enemy
				break
			elseif not target then
				target = enemy
			end
		end
	end
	if terriblesouvenir or target then
		local to = terriblesouvenir or target
		use.card = card
		if use.to then use.to:append(to) end
		return
	end

end

sgs.ai_use_priority["TH_GreatestCautionCARD"]  = 8
sgs.ai_card_intention.TH_GreatestCautionCARD = 101

local TH_GalacticIllusion_skill = {}----�����þ�
TH_GalacticIllusion_skill.name = "TH_GalacticIllusion"
table.insert(sgs.ai_skills, TH_GalacticIllusion_skill)
TH_GalacticIllusion_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_GalacticIllusionCARD") then return false end
	if #self.enemies < 2 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_GalacticIllusionCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_GalacticIllusionCARD"] = function(card, use, self)
	local Fslash = sgs.Sanguosha:cloneCard("fire_slash")
	Fslash:deleteLater()
	local targets = sgs.SPlayerList()
	self:sort(self.enemies, "defense")

	for _, enemy in ipairs(self.enemies) do
		local from = targets:length() > 0 and targets:first()
		if self:TheWuhun(enemy) >= 0 and not self:needToLoseHp(enemy,from,Fslash) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, from)
			and not enemy:isChained() or self:isGoodChainTarget(enemy, sgs.DamageStruct_Fire, self.player) then
			targets:append(enemy)
			if targets:length() == 2 then break end
		end
	end

	if targets:length() <= 1 then
		local from = targets:length() > 0 and targets:first()
		for _, friend in ipairs(self.friends_noself) do
			if self:needToLoseHp(friend,from,Fslash) and (not friend:isChained() or self:isGoodChainTarget(friend, sgs.DamageStruct_Fire, from))
				or not self:damageIsEffective(friend, sgs.DamageStruct_Fire, from) then
				if not targets:contains(friend) then
					targets:append(friend)
					if targets:length() == 2 then break end
				end
			end
		end
	end

	if targets:length() <= 1 then
		local from = targets:length() > 0 and targets:first()
		for _, enemy in ipairs(self.enemies) do
			if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, from) and self:TheWuhun(enemy) >= 0 and not targets:contains(enemy)
				and not enemy:isChained() or self:isGoodChainTarget(enemy, sgs.DamageStruct_Fire, self.player) then
				targets:append(enemy)
				if targets:length() == 2 then break end
			end
		end
	end


	if targets:length() == 2 then
		use.card = card
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["TH_GalacticIllusionCARD"] = 8
sgs.ai_card_intention.TH_GalacticIllusionCARD = function(self, card, from, tos)
	local Fslash = sgs.Sanguosha:cloneCard("fire_slash")
	Fslash:deleteLater()
	if not self:needToLoseHp(tos[1],tos[2],Fslash) then sgs.updateIntention(from, tos[1], 10) end
	if not self:needToLoseHp(tos[2],tos[1],Fslash) then sgs.updateIntention(from, tos[2], 10) end
end

local TH_CosmicMarionnette_skill = {}----�ǳ�������
TH_CosmicMarionnette_skill.name = "TH_CosmicMarionnette"
table.insert(sgs.ai_skills, TH_CosmicMarionnette_skill)
TH_CosmicMarionnette_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_CosmicMarionnetteCARD") then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_CosmicMarionnetteCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_CosmicMarionnetteCARD"] = function(card, use, self)
	local Hcard = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(Hcard, true)
	if #Hcard < 2 then return end
	self:sort(self.enemies, "morehcard")
	for _,friend in ipairs(self.friends) do
		if not friend:faceUp() and (not friend:hasSkill("TH_sichongjiejie") and friend:getHandcardNum()) and friend:getMark("TH_huanyue_waked") <1 then
			use.card = sgs.Card_Parse("#TH_CosmicMarionnetteCARD:" .. Hcard[1]:getEffectiveId() .. "+" .. Hcard[2]:getEffectiveId().. ":")
			if use.to then use.to:append(friend) end
			return
		end
	end

	for _,sb in ipairs(self.enemies) do
		if (not sb:hasSkill("TH_sichongjiejie") or sb:getHandcardNum() == 0) and sb:getMark("TH_huanyue_waked") < 1
			and sb:getMark("TH_CosmicMarionnette_target") < 1 and sb:faceUp() then
			use.card = sgs.Card_Parse("#TH_CosmicMarionnetteCARD:" .. Hcard[1]:getEffectiveId() .. "+" .. Hcard[2]:getEffectiveId() .. ":")
			if use.to then use.to:append(sb) end
			return
		end
	end
end

sgs.ai_use_priority["TH_CosmicMarionnetteCARD"]  = 8
sgs.ai_card_intention.TH_CosmicMarionnetteCARD= 55
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------pachouliknowledge

sgs.ai_skill_cardask["#TH_qiyaomofa"] = function(self, data)--7ҫħ��
	local cards=sgs.QList2Table(self.player:getHandcards())
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)
	local use = data:toCardUse()
	if use.card:isKindOf("Duel") then
		if use.to and self:getCardsNum("Slash") >= getCardsNum("Slash", use.to:at(0)) then
			return cards[1]:getEffectiveId()
		end
	elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
		local target = use.to and use.to:at(0)
		if target and target:getCards("hej"):length() > 0 then
			if self:isFriend(target) then
				if (target:containsTrick("supply_shortage") or target:containsTrick("indulgence")) and not target:containsTrick("YanxiaoCard") then
					return cards[1]:getEffectiveId()
				elseif self:isFriend(target) and target:containsTrick("lightning") and self:getFinalRetrial(target) ~= 1 then
					return cards[1]:getEffectiveId()
				elseif target:isWounded() and target:hasArmorEffect("SilverLion") then
					return cards[1]:getEffectiveId()
				elseif target:hasSkill("xiaoji") and target:getEquips():length() > 0 then
					return cards[1]:getEffectiveId()
				end
			else
				if target:getCards("he"):length() > 0 then
					return cards[1]:getEffectiveId()
				elseif target:getCards("j"):length() > 0 then
					if self:willSkipDrawPhase(target) or self:willSkipPlayPhase(target) then
						return cards[1]:getEffectiveId()
					end
				end
			end
		end
	elseif use.card:isKindOf("AmazingGrace") and self:getUseValue(cards[1]) < self:getUseValue(use.card) then
		return cards[1]:getEffectiveId()
	elseif use.card:isKindOf("GodSalvation") and self:getUseValue(cards[1]) < self:getUseValue(use.card) and self:willUseGodSalvation(use.card) then
		return cards[1]:getEffectiveId()
	elseif use.card:isKindOf("ExNihilo") then
		return cards[1]:getEffectiveId()
	elseif use.card:isKindOf("Collateral") then
		return cards[1]:getEffectiveId()
	elseif use.card:isKindOf("AOE") then
		local dummy_use = { isDummy = true }
		self:useTrickCard(use.card, dummy_use)
		if dummy_use.card then return cards[1]:getEffectiveId() end
	elseif use.card:isKindOf("EXCard_YJJG") then
		return cards[1]:getEffectiveId()
	elseif use.card:isKindOf("EXCard_YYDL") and self:getOverflow() > 0 then
		return cards[1]:getEffectiveId()
	end
	return "."
end

local TH_PhilosophersStone_skill = {}----����֮ʯ
TH_PhilosophersStone_skill.name = "TH_PhilosophersStone"
table.insert(sgs.ai_skills, TH_PhilosophersStone_skill)
TH_PhilosophersStone_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_PhilosophersStoneCARD")  then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_PhilosophersStoneCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_PhilosophersStoneCARD"] = function(card, use, self)---------����֮ʯ
	sgs.ai_use_priority["TH_PhilosophersStoneCARD"] = 9
	if self.room:getDrawPile():length() < 5 then sgs.ai_use_priority["TH_PhilosophersStoneCARD"] = 2.8 end
	use.card = card
end
sgs.ai_skill_invoke.TH_PhilosophersStone = function(self, data)
	local str = data:toStringList()
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then 
			use = self.room:getTag("UseHistory"..data:toStringList()[4]):toCardUse()
		end
	end
	if #str == 0 then return true end
	if str[1] == "slash" then
		if sgs.jijiangsource then return self:isFriend(sgs.jijiangsource) end
		if self.player:hasFlag("JijiangTarget") then return self:needToLoseHp(self.player, use.from, use.card) end
	elseif str[1] == "jink" then
		if sgs.hujiasource then return self:isFriend(sgs.hujiasource) end
		local prompt = str[2]:split(":")
		if prompt[1] == "slash-jink" and sgs.NatureSlash_data and self.player:isChained() then
			local use = sgs.NatureSlash_data:toCardUse()
			if use.from and prompt[2] == use.from:objectName() and use.to:contains(self.player)
				and self:isGoodChainTarget(self.player, self.room:getCurrent(), nil, nil, use.card) then
				return false
			end
		end
	end
	return true
end

sgs.TH_qiyaomofa_keep_value =
{
	ExNihilo 			= 4.09,
	Snatch 				= 4.08,
	Dismantlement 		= 4.07,
	IronChain 			= 4.06,
	SavageAssault 		= 4.05,
	Duel 				= 4.04,
	ArcheryAttack		= 4.03,
	AmazingGrace 		= 4.02,
	Collateral 			= 4.01
}

sgs.TH_PhilosophersStone_keep_value =
{
	Jink 				= 4.2
}

sgs.ai_use_priority["TH_PhilosophersStoneCARD"] = 9.5
function sgs.ai_cardneed.TH_qiyaomofa(to,card)
	return card:getTypeId()==sgs.Card_TypeTrick
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------hinanawitenshi
local TH_AllMUser_skill = {}
TH_AllMUser_skill.name = "TH_AllMUser"
table.insert(sgs.ai_skills, TH_AllMUser_skill)
TH_AllMUser_skill.getTurnUseCard = function(self, inclusive)
	local tenshis = self.room:findPlayersBySkillName("TH_AllM")
	if tenshis:isEmpty() then return end
	for _, tenshi in sgs.qlist(tenshis) do
		if not tenshi:hasFlag("TH_M_yamede") then
			local friend = self:isFriend(tenshi) or sgs.ai_role[tenshi:objectName()] == "neutral"
			local healthy = (not tenshi:isLord() and tenshi:getHp() > 1) or tenshi:getHp() > 3 or self:getCardsNum("Peach") > 0
			if friend and healthy and tenshi:getMark("@TH_terriblesouvenir") < 1 then
				local canuse = not self.player:hasUsed("#TH_AllMUserCARD")
				if not self:damageIsEffective(tenshi, sgs.DamageStruct_Thunder) then canuse = true end
				if self:hasSkills("TH_hongsehuanxiangxiang|TH_YuukaSama") and self:getOverflow() < 5 then canuse = true end
				if self.player:hasSkill("TH_chihuo") then
					for _,card in sgs.qlist(self.player:getCards("he")) do
						if not card:isKindOf("BasicCard") then canuse = true end
					end
				end
				if self:hasCrossbowEffect() and self:slashIsAvailable() then canuse = true end
				if self.player:hasSkill("TH_huaimiepaohou") and self.player:hasFlag("TH_huaimiepaohou_on") then canuse = true end
				if not self:isWeak(tenshi) and self:getOverflow() <= -1 then canuse = true end
				if tenshi:isChained() then canuse = self:isGoodChainTarget(tenshi,sgs.DamageStruct_Thunder, self.player) end
				if self.player:hasSkill("TH_yuyiruokong") then canuse = true end
				if #self.enemies == 0 then canuse = false end
				if canuse then
					local TH_skillcard = sgs.Card_Parse("#TH_AllMUserCARD:.:")
					assert(TH_skillcard)
					return TH_skillcard
				end
			end
		end
	end
end
sgs.ai_skill_use_func["#TH_AllMUserCARD"] = function(card, use, self)
	sgs.ai_use_priority.TH_AllMUserCARD = 9
	if sgs.ai_role[self.player:objectName()] == "neutral" then sgs.ai_use_priority.TH_AllMUserCARD = 2 end
	use.card = card
end

sgs.ai_skill_choice.TH_AllMUser= function(self, choices)
	if self.player:hasFlag("TH_M_yamede") then return "TH_M_no" end
	local ap = self.room:getCurrent()
	if not self:isFriend(ap) then
		return "TH_M_no"
	elseif sgs.ai_role[ap:objectName()] ~= "renegade" then
		if self.player:getRole() == "renegade" and self.player:getHp() > 3 then return "TH_M_yes" end
		if self.player:getRole() ~= "renegade" then
			if ap:hasSkill("TH_chihuo") then return "TH_M_yes" end
			if self.player:getHp() > 1 then return "TH_M_yes" end
			if self:getCardsNum("Peach") > 0 then return "TH_M_yes" end
			if self:getCardsNum("Analeptic") > 0 then return "TH_M_yes" end
			if ap:getState() == "online" then return "TH_M_yes" end
			if ap:getHandcardNum() > 6 then return "TH_M_yes" end
			if getCardsNum("Peach", ap, self.player) > 0 then return "TH_M_yes" end
			if self:needToLoseHp(self.player, ap) then return "TH_M_yes" end
			if self:damageIsEffective(self.player, sgs.DamageStruct_Thunder, ap) then return "TH_M_yes" end
		end
	end
	return "TH_M_no"
 end

sgs.ai_use_priority["TH_AllMUserCARD"]  = 9

sgs.ai_skillChoice_intention.TH_AllMUser = function(from, to, answer, self)
	if answer == "TH_M_yes" then  sgs.updateIntention(from, to, -10) end
end
------------------------------------------

local TH_mshi_skill = {}
TH_mshi_skill.name = "TH_mshi"
table.insert(sgs.ai_skills, TH_mshi_skill)
TH_mshi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_mshiCARD") then return end
	local TH_skillcard = sgs.Card_Parse("#TH_mshiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_mshiCARD"] = function(card, use, self)

	if self.player:isLord() then
		local can
		for _,enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and enemy:isChained() and self.player:getHp() > 3 and self.player:isChained() and self:isGoodChainTarget(self.player, sgs.DamageStruct_Thunder, enemy) then
				can = true
			end
		end
		if self.player:getHp() > 3 and can then
			for _,friend in ipairs(self.friends_noself) do
				if friend:hasSkills("TH_hongsehuanxiangxiang|TH_YuukaSama") and (friend:isChained() and friend:getHp() > 1 or not friend:isChained()) then
					use.card = card
					if use.to then use.to:append(friend) end
					return
				end
			end
			for _,friend in ipairs(self.friends_noself) do
				if friend:hasSkill("TH_yuyiruokong") and friend:getCardCount(true) >0 then
					use.card = card
					if use.to then use.to:append(friend) end
					return
				end
			end

			self:sort(self.friends_noself, "morehp")
			for _,friend in ipairs(self.friends_noself) do
				if friend:isChained() and friend:getHp()>1 or not friend:isChained() then
					use.card = card
					if use.to then use.to:append(friend) end
					return
				end
			end
		end

	else

		if not self.player:isChained() then

			local lord = self.room:getLord()
			if self:isEnemy(lord) and not lord:isChained() and (self.player:getHp()>2 or self:pleaseSme()) then
				use.card = card
				if use.to then use.to:append(lord) end
				return
			end

			self:sort(self.enemies,"hp")
			for _,enemy in ipairs(self.enemies) do
				if not enemy:isChained() and enemy:getHp() <= 2 and (self.player:getHp()>2 or self:pleaseSme()) then
					use.card = card
					if use.to then use.to:append(enemy) end
					return
				end
			end

		elseif self.player:isChained() and self:isGoodChainTarget(self.player, sgs.DamageStruct_Thunder,  self.player) then

			for _,friend in ipairs(self.friends_noself) do
				if friend:hasSkills("TH_hongsehuanxiangxiang|TH_YuukaSama") and (self.player:getHp() > 1 or self:pleaseSme()) then
					use.card = card
					if use.to then use.to:append(friend) end
					return
				end
			end

			local lord = self.room:getLord()
			if self:isEnemy(lord) and not lord:hasSkills("TH_hongsehuanxiangxiang|TH_YuukaSama") and (self.player:getHp() > 2 or self:pleaseSme()) then
				use.card = card
				if use.to then use.to:append(lord) end
				return
			end

			for _,enemy in ipairs(self.enemies) do
				if enemy:getHp() <= 2 and not enemy:hasSkills("TH_hongsehuanxiangxiang|TH_YuukaSama") and (self.player:getHp() > 2 or self:pleaseSme()) then
					use.card = card
					if use.to then use.to:append(enemy) end
					return
				end
			end

		end
	end
end

sgs.ai_skill_invoke.TH_mshi = function(self, data)
	local da = data:toDamage()
	if da.from and self:isFriend(da.from) then return end
	return true
end

sgs.ai_use_value["TH_mshiCARD"] = 6
sgs.ai_use_priority["TH_mshiCARD"]  = 0


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------nagaeiku
sgs.ai_skill_invoke.TH_yuyiruokong = function(self, data)
	local da = data:toDamage()
	if self:damageIsEffective(da.to, da.nature, da.from) then return true end
	if self:needToLoseHp(da.to, da.from, da.card) then return not self:isFriend(da.to) end
	if not da.chain and da.to:isChained() and not self:isGoodChainTarget(da.to, da.from, da.nature, da.damage, da.card) then return true end
	return self:isFriend(da.to)
end

sgs.ai_skillInvoke_intention.TH_yuyiruokong = function(from, to, yesorno, self)
	if yesorno == "yes" then
		local da = self.room:getTag("TH_yuyiruokong_data"):toDamage()
		if self:damageIsEffective(da.to, da.nature, da.from) then return true end
		if self:needToLoseHp(da.to, da.from, da.card) then return not self:isFriend(da.to) end
		if not da.to:isChained() then sgs.updateIntention(from, da.to, -77) end
		return
	end
end
sgs.ai_ajustdamage_from.TH_longyudianzuan = function(self, from, to, card, nature)
	if to:getArmor() then
		return 1
	end
end
sgs.ai_ajustdamage_from.TH_guanglongzhitanxi = function(self, from, to, card, nature)
	if from:getMark("@TH_yuyi") > 2 and not beFriend(to, from) then
		return 1
	end
end

local TH_guanglongzhitanxi_skill = {}
TH_guanglongzhitanxi_skill.name = "TH_guanglongzhitanxi"
table.insert(sgs.ai_skills, TH_guanglongzhitanxi_skill)
TH_guanglongzhitanxi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_yuyi") >= self.player:aliveCount() - 1 and self.player:getMark("@TH_yuyi") >= 3 then
		local TH_skillcard = sgs.Card_Parse("#TH_guanglongzhitanxiCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_guanglongzhitanxiCARD"] = function(card, use, self)

	local targets = sgs.SPlayerList()
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) and not self:needToLoseHp(enemy, self.player)
			and (not enemy:isChained() or self:isGoodChainTarget(enemy,sgs.DamageStruct_Thunder, self.player)) then
			targets:append(enemy)
			if targets:length() >= 5 then break end
		end
	end
	if targets:length() < 5 then
		for _, friend in ipairs(self.friends_noself) do
			if self:damageIsEffective(friend, sgs.DamageStruct_Thunder, self.player) and self:needToLoseHp(friend, self.player)
				and (not friend:isChained() or self:isGoodChainTarget(friend, sgs.DamageStruct_Thunder, self.player)) then
				targets:append(friend)
				if targets:length() >= 5 then break end
			end
		end
	end
	if targets:length() > 0 and targets:length() <= 5 then
		use.card = card
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["TH_guanglongzhitanxiCARD"] = 5
sgs.ai_use_priority["TH_guanglongzhitanxiCARD"]  = 3.5

sgs.ai_skill_invoke.TH_guanglongzhitanxi = function(self, data)
	local da = data:toDamage()
	return self:isEnemy(da.to) and self:TheWuhun(da.to) >= 0
end

sgs.ai_skillInvoke_intention.TH_guanglongzhitanxi = function(from, to, yesorno, self)
	if yesorno ~= "yes" then return end
	for _, p in sgs.qlist(self.room:getOtherPlayers(from)) do
		if p:hasFlag("TH_guanglongzhitanxi_target") then sgs.updateIntention(from, p, 10) end
	end
end

local TH_longshendeshandian_skill = {}
TH_longshendeshandian_skill.name = "TH_longshendeshandian"
table.insert(sgs.ai_skills, TH_longshendeshandian_skill)
TH_longshendeshandian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if self:getKeepValue(acard) < 4 then
			local TH_skillcard = sgs.Card_Parse("#TH_longshendeshandianCARD:" .. acard:getEffectiveId() .. ":")
			assert(TH_skillcard)
			return TH_skillcard
		end
	end
end
sgs.ai_skill_use_func["#TH_longshendeshandianCARD"] = function(card, use, self)
	local sd = sgs.Sanguosha:cloneCard("lightning", sgs.Card_NoSuit, 0)
	sd:deleteLater()
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not player:containsTrick("lightning") and not self.room:isProhibited(self.player, player, sd) then
			use.card = card
			if use.to then use.to:append(player) end
			return
		end
	end
	if not self.player:containsTrick("lightning") and not self.room:isProhibited(self.player, self.player, sd) then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
end

sgs.ai_use_value["TH_longshendeshandian"] = 6
sgs.ai_use_priority["TH_longshendeshandian"]  = 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------houjuunue
sgs.ai_skill_invoke.TH_UndefinedAF = function(self, data)
	local effect = data:toCardEffect()
	local card = effect.card
	local togive
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if self.player:hasFlag("TH_UndefinedAF"..c:getId()) then togive = c break end
	end
	if card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") or card:isKindOf("EXCard_YJJG") then return false end
	if card:isKindOf("FireAttack") and self.player:isChained() and self:isGoodChainTarget(self.player, card, effect.from) then return false end
	if self:isFriend(effect.from) then
		if (self.player:containsTrick("indulgence") or self.player:containsTrick("supply_shortage") or self:needToThrowArmor()) and (card:isKindOf("Santch") or card:isKindOf("Dismantlement")) then return false end
		if card:isKindOf("IronChain") then return false end
		if card:isKindOf("Duel") and (self:needToLoseHp(self.player, effect.from, card)) then return false end
		return true
	else
		if card:isKindOf("SavageAssault") and self:getCardsNum("Slash") > 0 then return false end
		if card:isKindOf("ArcheryAttack") and self:getCardsNum("Jink") > 0 then return false end
		if effect.from:hasSkill("luanji") then return false end
		if effect.from and card:isKindOf("Duel") and self:getCardsNum("Slash") > getCardsNum("Slash", effect.from, self.player) then return false end
		if togive then
			if togive:isKindOf("Peach") or togive:isKindOf("Analeptic") or togive:isKindOf("Nullification") then return false end
			if (card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("Duel") or card:isKindOf("FireAttack")) and not self:isWeak()
				and (togive:isKindOf("Santch") or togive:isKindOf("Dismantlement") or togive:isKindOf("ex_nihilo")) then return false end
		end
		return true
	end
	return false
end

sgs.ai_skill_choice.TH_hengong = function(self, choices)
	local str = choices
	choices = str:split("+")
	local selfcandis
	if str:matchOne("TH_hengong_selfdis") and self:getCardsNum("Jink") ~= self.player:getHandcardNum() and self:getCardsNum("Peach") ~= self.player:getHandcardNum() then
		if self:getOverflow() > 0 then
			return "TH_hengong_selfdis"
		end
		selfcandis = true
	end

	if str:matchOne("TH_hengong_otherdis") then
		local fmaxcard = 0
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() > fmaxcard then
				fmaxcard = friend:getHandcardNum()
				sgs.TH_hengong_help = friend
			end
		end
	end

	if sgs.TH_hengong_help and (not selfcandis or sgs.TH_hengong_help:getHandcardNum() > self.player:getHandcardNum()) then
		return "TH_hengong_otherdis"
	end

	if selfcandis then return "TH_hengong_selfdis" end

	if sgs.TH_hengong_help then return "TH_hengong_otherdis" end

	return choices[1]
end

sgs.ai_skill_discard.TH_hengong_otherdis = function(self, discard_num, min_num, optional, include_equip)
	if self.player:isKongcheng() then return end
	local Hcard = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(Hcard)
	local ap = self.room:getTag("TH_hengong_target"):toPlayer()
	if self:isFriend(ap) then
		if sgs.TH_hengong_help then
			if sgs.TH_hengong_help:getHandcardNum() <= self.player:getHandcardNum() then
				sgs.TH_hengong_help = nil
				return Hcard[1]:getEffectiveId()
			elseif self.player:objectName() == sgs.TH_hengong_help:objectName() then
				sgs.TH_hengong_help = nil
				return Hcard[1]:getEffectiveId()
			elseif sgs.TH_hengong_help:isKongcheng() then
				sgs.TH_hengong_help = nil
				return Hcard[1]:getEffectiveId()
			end
		else
			local maxcard_fri
			local maxcard = 0
			for _, friend in ipairs(self.friends) do
				if friend:objectName() ~= ap:objectName() and friend:getHandcardNum() > maxcard then
					maxcard = friend:getHandcardNum()
					maxcard_fri = friend
				end
			end
			if maxcard_fri then
				if self.player:objectName() == maxcard_fri:objectName() then
					return Hcard[1]:getEffectiveId()
				elseif self.player:getHandcardNum() == maxcard then
					return Hcard[1]:getEffectiveId()
				end
			end
		end
	end
	return {}
end

local TH_hengong_skill = {}
TH_hengong_skill.name = "TH_hengong"
table.insert(sgs.ai_skills, TH_hengong_skill)
TH_hengong_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("TH_hengong_used") then return end
	if self.player:getCardCount(true) == 0  then return end
	local TH_skillcard = sgs.Card_Parse("#TH_hengongCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_hengongCARD"] = function(card, use, self)

	local terriblesouvenir, target
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	local compare_func_cardnumber = function(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func_cardnumber)

	self:sort(self.enemies, "hp")
	for _,enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 and enemy:getMark("@TH_terriblesouvenir") > 0 and not terriblesouvenir then
			terriblesouvenir = enemy
		elseif not target then
			target = enemy
		end
	end

	if terriblesouvenir then
		for _, acard in ipairs(cards) do
			if acard:getNumber() <= terriblesouvenir:getHp() then
				use.card = sgs.Card_Parse("#TH_hengongCARD:"..acard:getEffectiveId()..":")
				if use.to then use.to:append(terriblesouvenir) end
				return
			end
		end
	end
	if target then
		for _, acard in ipairs(cards) do
			if acard:getNumber() <= target:getHp() then
				use.card = sgs.Card_Parse("#TH_hengongCARD:"..acard:getEffectiveId()..":")
				if use.to then use.to:append(target) end
				return
			end
		end
	end
end

function sgs.ai_cardneed.TH_hengong(to, card, self)
	return not to:containsTrick("indulgence") and card:getNumber() <= 3
end

sgs.ai_use_value["TH_hengongCARD"] = 6
sgs.ai_use_priority["TH_hengongCARD"]  = 3
sgs.ai_card_intention.TH_hengongCARD = 97
-----------------
function SmartAI:willdistance(player)
	if not player then return end
	local apc =  self.player:aliveCount()
	local distance = self.player:distanceTo(player)
	if distance == 1 then return 0 end
	if self.player:getSeat() > player:getSeat() then apc = - apc end
	local left = math.abs(self.player:getSeat() + apc - player:getSeat())
	local right = math.abs(self.player:getSeat() - player:getSeat())
	return math.min(left, right) - distance + 1
end

local TH_UndefinedUFO_skill ={}
TH_UndefinedUFO_skill.name = "TH_UndefinedUFO"
table.insert(sgs.ai_skills, TH_UndefinedUFO_skill)
TH_UndefinedUFO_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("TH_UndefinedUFO_off") then return end
	if self.player:getCardCount(true) == 0 then return end
	if self:getCardsNum("Peach") + self:getCardsNum("Jink") == self.player:getHandcardNum() and self.player:getHandcardNum() <= 2 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_UndefinedUFOCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_UndefinedUFOCARD"] = function(card, use, self)
	local slash = sgs.Sanguosha:cloneCard("slash")
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if (enemy:getEquip(0) and self:willdistance(enemy) == 1 or self:willdistance(enemy) == 2 and (self.player:getEquip(3) or self.player:getWeapon() and not self.player:getWeapon():isKindOf("Crossbow"))) and
		self:slashIsEffective(slash, enemy) and self:TheWuhun(enemy) >= 0 and
		self.player:getNextAlive():objectName() ~= enemy:objectName() and enemy:getNextAlive():objectName() ~= self.player:objectName() then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_priority["TH_UndefinedUFOCARD"] = 0
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------nazrin

local TH_NazrinPendulum_skill = {}
TH_NazrinPendulum_skill.name = "TH_NazrinPendulum"
table.insert(sgs.ai_skills, TH_NazrinPendulum_skill)
TH_NazrinPendulum_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_NazrinPendulumCARD") then return end
	local TH_skillcard = sgs.Card_Parse("#TH_NazrinPendulumCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_NazrinPendulumCARD"] = function(card, use, self)
	self.TH_NazrinPendulum = nil

	local f_slash, f_jink, f_peach, e_slash, e_jink, e_peach = 0, 0, 0, 0, 0, 0
	local f_zdl, e_zdl = 0, 0
	local hasWeakfriend, hasWeakenemy
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then hasWeakfriend = true end
		f_zdl = sgs.getDefense(friend)
		f_slash = f_slash + getCardsNum("Slash", friend, self.player)
		f_jink = f_jink + getCardsNum("Jink", friend, self.player)
		f_peach = f_peach + getCardsNum("Peach", friend, self.player)
	end
	f_zdl = sgs.getDefense(self.player)
	f_slash = f_slash + self:getCardsNum("Slash")
	f_peach = f_peach + self:getCardsNum("Peach")
	f_jink = f_jink + self:getCardsNum("Jink")
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then hasWeakenemy = true end
		e_zdl = sgs.getDefense(enemy)
		e_slash = e_slash + getCardsNum("Slash", enemy, self.player)
		e_jink = e_jink + getCardsNum("Jink", enemy, self.player)
		e_peach = e_peach + getCardsNum("Peach", enemy, self.player)
	end
	if f_zdl > 0 then f_zdl = f_zdl / #self.friends end
	if e_zdl > 0 then e_zdl = e_zdl / #self.enemies	end
	local friendlord
	local lord = self.room:getLord()
	if lord and self:isFriend(lord) then friendlord = true end
	-- global_room:writeToConsole("f_zdl:"..f_zdl..", f_slash:"..f_slash..", e_zdl:"..e_zdl..", e_slash:"..e_slash)

	if friendlord or e_zdl > f_zdl and e_slash > f_slash then
		use.card = sgs.Card_Parse("#TH_NazrinPendulumCARD:.:")
		self.TH_NazrinPendulum = "Slash"
		-- global_room:writeToConsole("aaa")
		return
	elseif (not friendlord or getKnownCard(lord, self.player, "Jink", true) >= 1) and e_zdl > f_zdl and e_jink > f_jink then
		use.card = sgs.Card_Parse("#TH_NazrinPendulumCARD:.:")
		self.TH_NazrinPendulum = "Jink"
		-- global_room:writeToConsole("bbb")
		return
	elseif not hasWeakfriend and hasWeakenemy and f_zdl > e_zdl then
		use.card = sgs.Card_Parse("#TH_NazrinPendulumCARD:.:")
		self.TH_NazrinPendulum = "Peach"
		-- global_room:writeToConsole("ccc")
	end
end

sgs.ai_skill_choice.TH_NazrinPendulum = function(self, choices, data)
	if self.TH_NazrinPendulum then return self.TH_NazrinPendulum end
	return choices[math(1,3)]
end

sgs.ai_event_callback[sgs.CardUsed].TH_NazrinPendulumCARD = function(self, player, data)
	local use = data:toCardUse()
	if use.card and use.card:objectName() == "TH_NazrinPendulumCARD" then
		local tag = self.room:getTag("TH_NazrinPendulum_Choice")
		if tag then
			local class_name = tag:toString()
			if class_name ~= "Slash" and class_name ~= "Jink" and class_name ~= "Peach" then return end
			
			self.room:removeTag("TH_NazrinPendulum_Choice")
		end
	end
end

sgs.ai_use_priority["TH_NazrinPendulumCARD"]  = 1

sgs.ai_skill_cardask["#TH_Detector"] = function(self, data, pattern)
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


local TH_GreatestTreasure_skill = {}
TH_GreatestTreasure_skill.name = "TH_GreatestTreasure"
table.insert(sgs.ai_skills, TH_GreatestTreasure_skill)
TH_GreatestTreasure_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag('TH_GreatestTreasure_used') then return end
	if self.player:isKongcheng() then return end
	local cards=sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	return sgs.Card_Parse(("snatch:TH_GreatestTreasure[%s:%s]=%d"):format(cards[1]:getSuitString(),cards[1]:getNumberString(),cards[1]:getEffectiveId()))
end

sgs.ai_use_value["TH_GreatestTreasure"] = sgs.ai_use_value.Snatch
sgs.ai_use_priority["TH_GreatestTreasure"]  = sgs.ai_use_priority.Snatch - 0.05
function sgs.ai_cardneed.TH_GreatestTreasure(to,card,self)
	return card:isKindOf("Snatch")
end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------ibukisuika

sgs.ai_cardsview_valuable.TH_jiu = function(self, class_name, player)
	if class_name ~= "Analeptic" then return end
	local analeptic = sgs.Sanguosha:cloneCard("analeptic")
	if sgs.Analeptic_IsAvailable(self.player, analeptic) and not player:hasFlag("TH_jiu_used") and player:getPhase() == sgs.Player_Play then
		return ("analeptic:TH_jiu[no_suit:-1]=.")
	end
end

sgs.ai_view_as.TH_jiu = function(card, player, card_place, class_name)
	if not player:hasFlag("TH_jiu_used") and player:getHp() < 1 and class_name == "Analeptic" then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if card_place == sgs.Player_PlaceSpecial then return end
		return ("analeptic:TH_jiu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local TH_jiu_skill = {}
TH_jiu_skill.name = "TH_jiu"
table.insert(sgs.ai_skills,TH_jiu_skill)
TH_jiu_skill.getTurnUseCard = function(self,inclusive)
	if self.player:hasFlag("TH_jiu_used") then return end
	local slash = dummyCard("analeptic")
	slash:setSkillName("TH_jiu")
	if slash:isAvailable(self.player)
	then return slash end
end


local TH_MissingPower_skill = {}
TH_MissingPower_skill.name = "TH_MissingPower"
table.insert(sgs.ai_skills, TH_MissingPower_skill)
TH_MissingPower_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getHp() <= 2 or self.player:hasFlag("TH_suiyue_buff") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Jink") then
				return sgs.Card_Parse(("duel:TH_MissingPower[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
			end
		end
	end
end

sgs.ai_canliegong_skill.TH_MissingPower = function(self, from, to)
	return to:getHp() > from:getHp()
end

local TH_suiyue_skill ={}
TH_suiyue_skill.name = "TH_suiyue"
table.insert(sgs.ai_skills, TH_suiyue_skill)
TH_suiyue_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_suiyue") > 0 then
		local TH_skillcard = sgs.Card_Parse("#TH_suiyueCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end

sgs.ai_skill_use_func["#TH_suiyueCARD"] = function(card, use, self)
	-- if self:isWeak() and (self:getCardsNum("Slash") > 0 or self:getCardsNum("Jink") > 0) then
		-- use.card = card
	-- end
	local e_peach = 0
	for _, enemy in ipairs(self.enemies) do
		e_peach = e_peach + getCardsNum("Peach", enemy)
	end
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() + e_peach <= self:getCardsNum("Jink") and self:getCardsNum("Jink") > 1 and self:hasTrickEffective(duel, enemy)
			and self:damageIsEffective(enemy) and not self:needToLoseHp(enemy, self.player, duel) then
			use.card = card
			return
		end
	end

	local jink = self:getCardsNum("Jink")
	if jink > 0 and #self.enemies > 0 then
		local dummy_use = self:aiUseCard(duel, dummy())
		if dummy_use.card and dummy_use.card:isKindOf("Duel") and dummy_use.to:length() > 0 then
			local t = dummy_use.to:first()
			if jink + (self.player:inMyAttackRange(t) and 1 or 0) >= t:getHp() then
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_priority.TH_suiyueCARD = 3
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------tatarakogasa

local TH_demacia_skill = {}
TH_demacia_skill.name = "TH_demacia"
table.insert(sgs.ai_skills, TH_demacia_skill)
TH_demacia_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@TH_demacia") == 1 then return end
	if self:getCardsNum("Peach") + self:getCardsNum("Jink") == self.player:getHandcardNum() and self.player:getHandcardNum() <= 3 then return end
	if self.player:getCardCount(true) < 2 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_demaciaCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_demaciaCARD"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		if not friend:faceUp() and not (friend:hasSkill("TH_sichongjiejie") and friend:getHandcardNum() > 0 ) then
			sgs.TH_demacia_friend = friend
			use.card = sgs.Card_Parse("#TH_demaciaCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":")
			return
		end
	end

	if self:getOverflow() > 0 then
		use.card = sgs.Card_Parse("#TH_demaciaCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":")
		return
	end
	for _,enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) or enemy:getCardCount(true) > 6 then
			use.card = sgs.Card_Parse("#TH_demaciaCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":")
			return
		end
	end
end

sgs.ai_skill_invoke.TH_demacia = function(self, data)
	local target = self.room:getCurrent()

	if sgs.TH_demacia_friend then
		if not sgs.TH_demacia_friend:faceUp() and sgs.TH_demacia_friend:objectName() == target:objectName() then
			sgs.TH_demacia_friend = nil
			return true
		end
	end

	if not sgs.TH_demacia_friend or sgs.TH_demacia_friend:faceUp() then
		sgs.TH_demacia_friend = nil
		if self:isEnemy(target) and target:faceUp() and (not target:hasSkill("TH_sichongjiejie") or target:isKongcheng()) and target:getMark("TH_huanyue_waked") < 1 then
			if self:isWeak(target) then return true end
			if self:getOverflow(target) >= 0 then return true end
			if target:getCardCount(true) > 5 then return true end
			if self:getOverflow() >= 0 then return true end
		end
	end
	return
end

sgs.ai_use_value.TH_demaciaCARD = 6
sgs.ai_use_priority.TH_demaciaCARD = 0.5
sgs.ai_skillInvoke_intention.TH_demacia = function(from, to, yesorno, self)
	if yesorno == "yes" then
		local intention = to:faceUp() and 88 or -88
		sgs.updateIntention(from, to, intention)
	end
end

------------

local TH_paratrooper_skill ={}
TH_paratrooper_skill.name = "TH_paratrooper"
table.insert(sgs.ai_skills, TH_paratrooper_skill)
TH_paratrooper_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_paratrooperCARD") then return end
	if self.player:getCardCount(true) == 0 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_paratrooperCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_paratrooperCARD"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)

	local weapon, armor ,defhorse, offhorse
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			weapon = card:getEffectiveId()
		elseif card:isKindOf("Armor") then
			armor = card:getEffectiveId()
		elseif card:isKindOf("DefensiveHorse") then
			defhorse = card:getEffectiveId()
		elseif card:isKindOf("OffensiveHorse") then
			offhorse = card:getEffectiveId()
		end
	end

	if not weapon and not armor and not defhorse and not offhorse then return end

	local f_damage, e_damage = 0,0
	local targetw, targeta, targetd, targeto = {}, {}, {}, {}
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ap:getWeapon() then
			table.insert(targetw, ap)
		elseif ap:getArmor() then
			table.insert(targeta, ap)
		elseif ap:getDefensiveHorse() then
			table.insert(targetd, ap)
		elseif ap:getOffensiveHorse() then
			table.insert(targeto, ap)
		end
	end

	if #targetw == 0 and  #targeta == 0 and #targetd == 0 and #targeto == 0 then return end

	local TH_paratrooper_value = {weapon = -100, armor = -100, defhorse = -100, offhorse = -100}
	if weapon and #targetw > 0 then
		TH_paratrooper_value.weapon = self:UseAoeSkillValue(nil, targetw)
	end
	if armor and #targeta > 0 then
		TH_paratrooper_value.armor = self:UseAoeSkillValue(nil, targeta)
	end
	if defhorse and #targetd > 0 then
		TH_paratrooper_value.defhorse = self:UseAoeSkillValue(nil, targetd)
	end
	if offhorse and #targeto > 0 then
		TH_paratrooper_value.offhorse = self:UseAoeSkillValue(nil, targeto)
	end

	local maxvalue = - 101
	for k, avalue in pairs(TH_paratrooper_value) do
		if avalue > maxvalue then maxvalue = avalue end
	end
	if maxvalue <= 0 then return end

	if TH_paratrooper_value.weapon == maxvalue then
		use.card = sgs.Card_Parse("#TH_paratrooperCARD:"..weapon..":")
		return
	elseif TH_paratrooper_value.armor == maxvalue then
		use.card = sgs.Card_Parse("#TH_paratrooperCARD:"..armor..":")
		return
	elseif TH_paratrooper_value.defhorse == maxvalue then
		use.card = sgs.Card_Parse("#TH_paratrooperCARD:"..defhorse..":")
		return
	elseif TH_paratrooper_value.offhorse == maxvalue then
		use.card = sgs.Card_Parse("#TH_paratrooperCARD:"..offhorse..":")
		return
	end

end

sgs.ai_use_priority.TH_paratrooperCARD = 6
-----

local TH_UmbrellaCyclone_skill ={}
TH_UmbrellaCyclone_skill.name = "TH_UmbrellaCyclone"
table.insert(sgs.ai_skills, TH_UmbrellaCyclone_skill)
TH_UmbrellaCyclone_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_UmbrellaCycloneCARD") then return end
	if self.player:getMark("@TH_Umbrella") > 0 then
		local TH_skillcard = sgs.Card_Parse("#TH_UmbrellaCycloneCARD:.:")
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_UmbrellaCycloneCARD"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0  then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end
sgs.ai_skill_choice.TH_UmbrellaCycloneCARD = function(self, choices, data)
	local damage = choices
	choices = damage:split("+")
	local target = data:toPlayer()
	local hp = tostring(math.max(target:getHp() - 1, 1))
	if isLord(target) then return choices[#choices] end
	if damage:matchOne(hp) then return hp end
	return choices[#choices]
end

sgs.ai_use_value.TH_UmbrellaCycloneCARD = 6
sgs.ai_use_priority.TH_UmbrellaCycloneCARD = 9

sgs.ai_ajustdamage_to["@TH_Umbrella_damage"] = function(self, from, to, card, nature)
	return to:getMark("@TH_Umbrella_damage")
end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------hijiribyakuren
sgs.ai_skill_invoke.TH_moshenfusong = function(self, data)
	local dying = data:toDying()
	local lord = self.room:getLord()
	if self:isFriend(dying.who) and dying.who:objectName() ~= self.player:objectName() then
		if dying.who:objectName() == lord:objectName() then return true end
		if self:isFriend(lord) and not self:undeadplayer(lord) and lord:getHp() == 1 then return end
		if self.player:getRole() == "renegade" and #self.friends >= #self.enemies then return end
		return true
	end
	if dying.who:hasSkill("wuhun") and self:TheWuhun(dying.who, true) == -2  then return true end
	if self.player:objectName() == dying.who:objectName() then return true end
	return
end

local TH_chaoren_skill ={}
TH_chaoren_skill.name = "TH_chaoren"
table.insert(sgs.ai_skills, TH_chaoren_skill)
TH_chaoren_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_chaorenCARD") then return end
	if self.player:getPile("TH_yinhexi_pile"):length() < 7 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_chaorenCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_chaorenCARD"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.TH_chaorenCARD = 0.2

local TH_yinhexi_skill ={}
TH_yinhexi_skill.name = "TH_yinhexi"
table.insert(sgs.ai_skills, TH_yinhexi_skill)
TH_yinhexi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_yinhexiCARD") or self.player:getPile("TH_yinhexi_pile"):length() == 0 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_yinhexiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_yinhexiCARD"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_discard.TH_yinhexigive = function(self, discard_num, min_num, optional, include_equip)
	local cangive
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(ap) and ap:hasSkill("TH_yinhexi") and ap:getPile("TH_yinhexi_pile"):length() < 12 then cangive = true end
	end
	if cangive then
		return self:askForDiscard("tuohou_discardreason", discard_num, min_num, false, false)
	end
	return {}
end
sgs.ai_skill_invoke.TH_yinhexi_askcard = function(self, data)
	local target = self.room:getCurrent()
	if self:isFriend(target) and (self:isWeak(target) or math.random(1,2) == 1) then return true end
	return
end
sgs.ai_skillInvoke_intention.TH_yinhexi_askcard = -77
sgs.ai_use_priority.TH_yinhexiCARD = 9
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------usamirenko
local TH_Science_skill ={}
TH_Science_skill.name = "TH_Science"
table.insert(sgs.ai_skills, TH_Science_skill)
TH_Science_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_ScienceCARD")  then return end
	if self.player:isKongcheng() then return end
	if self:getCardsNum("Jink") + self:getCardsNum("Peach") == self.player:getHandcardNum() and self.player:getHandcardNum() <= 2 and self:getOverflow() <= 0 then return false end
	local TH_skillcard = sgs.Card_Parse("#TH_ScienceCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_ScienceCARD"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	self:sort(self.enemies, "handcard")
	local peach
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") and card:getSuit() == sgs.Card_Heart then
			peach = card:getEffectiveId()
			break
		end
	end
	if peach then
		for _, friend in ipairs(self.friends_noself) do
			if self:getCardsNum("Peach") > 1 and not self.player:isWounded() and getKnownCard(friend, self.player, "heart") >= 1 and not friend:containsTrick("indulgence") then
				use.card = sgs.Card_Parse("#TH_ScienceCARD:"..peach..":")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 then
			use.card = sgs.Card_Parse("#TH_ScienceCARD:"..cards[1]:getEffectiveId()..":")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_cardshow.TH_Science = function(self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if self:isFriend(requestor) then
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Heart then return card end
		end
	end
	return self.player:getRandomHandCard()
end

sgs.ai_use_value["TH_ScienceCARD"]  = 7
sgs.ai_use_priority["TH_ScienceCARD"] = 5.0
sgs.ai_card_intention.TH_ScienceCARD = 82
------------

local TH_Unscientific_skill ={}
TH_Unscientific_skill.name = "TH_Unscientific"
table.insert(sgs.ai_skills, TH_Unscientific_skill)
TH_Unscientific_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_UnscientificCARD")  then return end
	if self.player:isKongcheng() then return end
	local TH_skillcard = sgs.Card_Parse("#TH_UnscientificCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_UnscientificCARD"] = function(card, use, self)
	local use_card, heart , spade, club, diamond
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getSuitString() == "heart" then heart = card:getEffectiveId() end
		if card:getSuitString() == "spade" then spade = card:getEffectiveId() end
		if card:getSuitString() == "club" then club = card:getEffectiveId() end
		if card:getSuitString() == "diamond" then diamond = card:getEffectiveId() end
	end
	use_card = heart or spade or club or diamond

	local xiaoqiao
	local target
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and enemy:hasSkill("hongyan") and self:damageIsEffective(enemy) and self:TheWuhun(enemy) >=0 then
			xiaoqiao = enemy
		elseif not enemy:isKongcheng() and not target and self:damageIsEffective(enemy) and self:TheWuhun(enemy) >=0 then
			target = enemy
		end
	end
	if xiaoqiao and spade then
		use.card = sgs.Card_Parse("#TH_UnscientificCARD:"..spade..":")
		if use.to then use.to:append(xiaoqiao) end
		return
	end
	if target then
		use.card = sgs.Card_Parse("#TH_UnscientificCARD:"..use_card..":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_cardask["#TH_Unscientific"] = function(self, data, pattern, target, target2, arg, arg2)
	local suit = pattern:split("|")
	suit = suit[2]
	if self:needToLoseHp(self.player, self.room:getCurrent()) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:getSuitString() == suit then return c:getEffectiveId() end
	end
	return "."
end

sgs.ai_use_priority["TH_UnscientificCARD"] = 5.1
sgs.ai_card_intention.TH_UnscientificCARD = 83
-----------------------

local TH_MoreUnscientific_skill ={}
TH_MoreUnscientific_skill.name = "TH_MoreUnscientific"
table.insert(sgs.ai_skills, TH_MoreUnscientific_skill)
TH_MoreUnscientific_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_MoreUnscientificCARD")  then return end
	local TH_skillcard = sgs.Card_Parse("#TH_MoreUnscientificCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_MoreUnscientificCARD"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:damageIsEffective(enemy) and self:TheWuhun(enemy) >= 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_skill_cardask["#TH_MoreUnscientific"] = function(self, data, pattern, target, target2, arg, arg2)
	local num = pattern:split("|")
	num = num[3]:split("~")
	num = tonumber(num[1])
	if self:needToLoseHp(self.player, self.room:getCurrent()) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:getNumber() >= num then return c:getEffectiveId() end
	end
	return "."
end

sgs.ai_use_priority["TH_MoreUnscientificCARD"] = 5.2
sgs.ai_card_intention.TH_MoreUnscientificCARD = 84
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------maribelhearn
sgs.ai_skill_choice["TH_yuezhiyaoniao"] = function(self, choices, data)
	local str = data:toString()
	local cardids = str:split("-")
	local Peach, Jink, Slash, trick, attack = 0, 0, 0, 0, 0
	for _, cardid in ipairs(cardids) do
		local card = sgs.Sanguosha:getCard(cardid)
		if card:isKindOf("Peach") then
			Peach = Peach + 1
		end
		if card:isKindOf("Jink") then
			Jink = Jink + 1
		end
		if card:isKindOf("Slash") then
			Slash = Slash + 1
		end
		if card:isKindOf("TrickCard") and not card:isKindOf("Lightning") and not card:isKindOf("GodSalvation") and not card:isKindOf("AmazingGrace") then
			trick = trick + 1
		end
		if card:isKindOf("Weapon") or card:isKindOf("OffensiveHorse") then
			attack = attack + 1
		end
	end
	local target = self.room:getCurrent()
	if self:isFriend(target) then
		if self:isWeak(target) and Peach == 0 and Jink == 0 then return "TH_yuezhiyaoniao_dis" end
		if target:getLostHp() <= 1 then
			local canattack
			for _, enemy in ipairs(self.enemies) do
				if target:inMyAttackRange(enemy) then
					canattack = true
				end
			end
			if canattack and target:getWeapon() and target:getWeapon():isKindOf("Crossbow") and Slash == 0 and Peach == 0 then return "TH_yuezhiyaoniao_dis" end
			if not canattack and Peach == 0 and trick == 0 and attack == 0 then return "TH_yuezhiyaoniao_dis" end
		end
	else
		if self:isWeak(target) and Peach > 0 then return "TH_yuezhiyaoniao_dis" end
		if trick == 2 then return "TH_yuezhiyaoniao_dis" end
	end
	return "TH_yuezhiyaoniao_obtain"
end

sgs.ai_skill_invoke.TH_huamaozhihuan = function (self, data)
	return true
end


local TH_mifeng_skill ={}
TH_mifeng_skill.name = "TH_mifeng"
table.insert(sgs.ai_skills, TH_mifeng_skill)
TH_mifeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_mifengCARD") then return end
	if self.player:getHandcardNum() < 2 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_mifengCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_mifengCARD"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if (cards[1]:isKindOf("Jink") or cards[1]:isKindOf("Peach")) and self:getCardsNum("Jink") + self:getCardsNum("Peach") <= 2 then return end
	self:sort(self.enemies,"defense")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:containsTrick("indulgence") and not enemy:containsTrick("supply_shortage") then
			use.card = sgs.Card_Parse("#TH_mifengCARD:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value["TH_mifengCARD"]  = 7
sgs.ai_use_priority["TH_mifengCARD"] = 1.1
sgs.ai_card_intention.TH_mifengCARD = 82

sgs.ai_skill_invoke["#TH_bianshen_YakumoYukari"] = function(self, data)
	return math.random(1, 4) == 1
end
---------------------------------------------------------------------------------------------------------------------------------------toyosatomiminomiko
sgs.ai_skill_invoke.TH_jiushizhiguang = function(self, data)
	local dy = data:toDying()
	if self:isFriend(dy.who) and (dy.who:getMaxHp() > 1 or dy.who:hasSkill("TH_mingke")) then
		if self.player:getRole() == "renegade" and #self.friends >= #self.enemies and not dy.who:isLord() and self.player:getHp() >2 and self.player:getLostHp() <= 1 then return end
		return true
	end
	return
end

local TH_shenlingdayuzhou_skill ={}
TH_shenlingdayuzhou_skill.name = "TH_shenlingdayuzhou"
table.insert(sgs.ai_skills, TH_shenlingdayuzhou_skill)
TH_shenlingdayuzhou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_shenlingdayuzhouCARD")  then return end
	local touse = math.min(math.ceil(self.player:aliveCount()/2), 3)
	if self.player:getHandcardNum() < touse then return end
	if self:getCardsNum("Jink") + self:getCardsNum("Peach") <= #self.enemies/2 then return end
	if self:getCardsNum("Jink") == 0 and self.player:getHp() <= 2 and self.player:getHandcardNum() <= 2 and not self:isFriend(self.player:getNextAlive()) then return end
	if self.player:aliveCount() <= 2 then return end
	local TH_skillcard = sgs.Card_Parse("#TH_shenlingdayuzhouCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_shenlingdayuzhouCARD"] = function(card, use, self)
	local num = math.min(math.ceil(self.player:aliveCount()/2), 3)
	local tocard = sgs.ai_skill_discard.gamerule(self, num, num)
	if #tocard == num then
		use.card = sgs.Card_Parse("#TH_shenlingdayuzhouCARD:"..table.concat(tocard, "+")..":")
	end
end

sgs.ai_skill_choice.TH_shenlingdayuzhou = function(self, choices, data)
	local target = self.player:getRoom():getCurrent()
	if self:isEnemy(target) then
		--if self:needLeiji(target, self.palyer) then return "TH_givecard" end
		if self:needToLoseHp() then return "TH_slashto" end
		local slashs = self:getCards("Slash", "h")
		if #slashs == 0 then return "TH_givecard" else return "TH_slashto" end
	end
	return "TH_givecard"
end
sgs.ai_skill_cardask["#TH_shenlingdayuzhou"] = function(self, data, pattern, target)
	local slashs = self:getCards("Slash")
	for _, slash in ipairs(slashs) do
		if self:slashIsEffective(slash, target) then
			return slash:toString()
		end
	end
	if #slashs > 0 then return slashs[1]:toString() end
	return "."
end

sgs.ai_use_value.TH_shenlingdayuzhouCARD = 8
sgs.ai_use_priority.TH_shenlingdayuzhouCARD = 2.8
sgs.ai_skillChoice_intention.TH_shenlingdayuzhou = function(from, to, answer, self)
	local intention = 83
	if to:hasSkill("leiji") or to:hasSkill("liuli") then intention = 0 end
	if answer == "TH_slashto" then
		sgs.updateIntention(from, to, intention)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------MagakiReimu
local TH_shenji_skill = {}
TH_shenji_skill.name = "TH_shenji"
table.insert(sgs.ai_skills, TH_shenji_skill)
TH_shenji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_shenjiCARD")  then return end
	local TH_skillcard = sgs.Card_Parse("#TH_shenjiCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_shenjiCARD"] = function(card, use, self)
	for _, friend in ipairs(self.friends_noself) do
		if not self:hasSkills(sgs.use_lion_skill, friend) and friend:hasArmorEffect("SilverLion")
		and friend:isWounded() and not (friend:hasSkill("TH_yongyefan") and self.player:getNext():objectName() == friend:objectName()) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end

	local terriblesouvenir, atarget, btarget, ctarget
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("@TH_terriblesouvenir") > 0 and enemy:getHandcardNum() > 0 and enemy:getEquips():length() > 0 and not terriblesouvenir then
			terriblesouvenir = enemy
		end
		if not atarget and enemy:getHandcardNum() > 0 and enemy:getEquips():length() > 0 and not self:hasSkills(sgs.lose_equip_skill, enemy) then
			atarget = enemy
		end
		if not btarget and enemy:getHandcardNum() > 0 and enemy:getEquips():length() > 0 then
			btarget = enemy
		end
		if not ctarget and (enemy:getHandcardNum() > 0 or enemy:getEquips():length() > 0) then
			ctarget = enemy
		end
	end
	local target = terriblesouvenir or atarget or btarget or ctarget
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["TH_shenjiCARD"]  = 9
sgs.ai_use_priority["TH_shenjiCARD"] = 5
sgs.ai_card_intention.TH_shenjiCARD = 85
---------------------------
local TH_huanghuo_skill = {}
TH_huanghuo_skill.name = "TH_huanghuo"
table.insert(sgs.ai_skills, TH_huanghuo_skill)
TH_huanghuo_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#TH_huanghuoCARD")  then return end
	local TH_skillcard = sgs.Card_Parse("#TH_huanghuoCARD:.:")
	assert(TH_skillcard)
	return TH_skillcard
end
sgs.ai_skill_use_func["#TH_huanghuoCARD"] = function(card, use, self)
	local weakfriend, fulan, yuyuko, kanako
	self:sort(self.friends,"hp")
	for _, friend in ipairs(self.friends_noself) do
		if 	friend:getHp() == 1 and friend:getLostHp() >= 2 and self:getAllPeachNum() == 0 or friend:hasSkill("TH_yongyefan") or friend:getLostHp() > friend:getHp() then
			weakfriend = friend
			sgs.TH_huanghuo = "TH_huanghuo_losemax"
			break
		end
		if friend:hasSkill("TH_mingke") and not fulan then
			sgs.TH_huanghuo = "TH_huanghuo_addmax"
			fulan = friend
		end
		if friend:getHp() >2 and self:getOverflow(friend) > 0 then
			if friend:hasSkill("TH_chihuo") and getCardsNum("TrickCard", friend) + getCardsNum("EquipCard", friend) > 1 and friend:getCardCount(true) > 3 then
				yuyuko =friend
				sgs.TH_huanghuo = "TH_huanghuo_addmax"
			end
			if friend:hasSkill("TH_MiracleofOtensui") and friend:getHandcardNum() > 3 then
				kanako = friend
				sgs.TH_huanghuo = "TH_huanghuo_addmax"
			end
		end
	end
	local tofriend = weakfriend or fulan or yuyuko or kanako
	if tofriend then
		use.card = card
		if use.to then use.to:append(tofriend) end
		return
	end

	local targeta, targetb, targetc
	self:sort(self.enemies,"hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getLostHp() == 1 and self:hasSkills("TH_mingke|TH_yongyefan", enemy) and not targeta then
			targeta = enemy
			sgs.TH_huanghuo = "TH_huanghuo_losemax"
		end
		if enemy:getLostHp() > 1 and enemy:getHp() == 2 and self:hasSkills("TH_mingke", enemy) and not targetb then
			targetb = enemy
			sgs.TH_huanghuo = "TH_huanghuo_addmax"
		end
		if enemy:isWounded() and enemy:getHp() > enemy:getLostHp() then
			targetc = enemy
			sgs.TH_huanghuo = "TH_huanghuo_losemax"
		end
	end
	local toenemy = targeta or targetb
	if toenemy then
		use.card = card
		if use.to then use.to:append(toenemy) end
		return
	end
	if not self.player:hasSkill("#TH_sishen") or self.player:getMark("TH_sishen_used") > 1 then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
	if targetc then
		use.card = card
		if use.to then use.to:append(targetc) end
		return
	end
end

sgs.ai_skill_choice.TH_huanghuoCARD = function(self, choices, data)
	choices = choices:split("+")
	if sgs.TH_huanghuo then return sgs.TH_huanghuo end
	return choices[1]
end

sgs.ai_use_value["TH_huanghuoCARD"]  = 9
sgs.ai_use_priority["TH_huanghuoCARD"] = 4.9

function sgs.ai_cardneed.TH_zhongduotian(to, card, self)
	if not to:containsTrick("indulgence") then
		if not to:getOffensiveHorse() then return card:isKindOf("OffensiveHorse") end
		if not to:getWeapon() then return card:isKindOf("OffensiveHorse") end
	end
end

sgs.ai_skill_choice.TH_sishen = function(self, choices, data)
	choices = choices:split("+")
	if self.player:getHp() == 1 then return "TH_sishen_recover" end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_choice.TH_sishenskilllist = function(self, choices, data)
	choices = choices:split("+")
	local new = {}
	for _, str in ipairs(choices) do
		if not self.player:hasSkill(str) then table.insert(new, str) end
	end
	if #new > 0 then
		return new[math.random(1, #new)]
	end
	return choices[math.random(1, #choices)]
end
-------------------------------------------------------------------

TH_lordskill_sub_skill = {}
TH_lordskill_sub_skill.name = "TH_lordskill_sub"
table.insert(sgs.ai_skills, TH_lordskill_sub_skill)
TH_lordskill_sub_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#TH_lordskill_subCARD") then return end
	local minnum = self.player:getKingdom() == "qun" and 2 or 1
	if self.player:getCardCount(true) < minnum then return end
	local lord = self.room:getLord()
	if not lord or not self:isFriend(lord) then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	if self.player:getKingdom() == "wei" then
		local card_id
		for _, card in ipairs(cards) do
			if card:isBlack() and (not card:isKindOf("Peach") or self:getCardsNum("Peach") > 1)
				and (not card:isKindOf("Jink") or self:getCardsNum("Jink") > 1 or (self.player:getHp() >= 2 and self.player:getArmor() and not self.player:hasArmorEffect("SilverLion")))
				and (not card:isKindOf("Analeptic") or self:getCardsNum("Jink") > 0 or self.player:getHp() >= 2)
				then
				card_id = card:getEffectiveId() break
			end
		end
		if card_id then
			local TH_skillcard = sgs.Card_Parse("#TH_lordskill_subCARD:" .. card_id .. ":")
			assert(TH_skillcard)
			return TH_skillcard
		end
	elseif self.player:getKingdom() == "shu" then
		local card_id
		for _, card in ipairs(cards) do
			if card:isRed() and (not card:isKindOf("Peach") or self:getCardsNum("Peach") > 1)
				and (not card:isKindOf("Jink") or self:getCardsNum("Jink") > 1 or (self.player:getHp() >= 2 and self.player:getArmor() and not self.player:hasArmorEffect("SilverLion")))
				and (not card:isKindOf("Analeptic") or self:getCardsNum("Jink") > 0 or self.player:getHp() >= 2)
				then
				card_id = card:getEffectiveId() break
			end
		end
		if card_id then
			local TH_skillcard = sgs.Card_Parse("#TH_lordskill_subCARD:" .. card_id .. ":")
				assert(TH_skillcard)
				return TH_skillcard
			end
	elseif self.player:getKingdom() == "wu" then
		local card_id
		for _, card in ipairs(cards) do
			if card:isKindOf("BasicCard") and (not card:isKindOf("Peach") or self:getCardsNum("Peach") > 1)
				and (not card:isKindOf("Jink") or self:getCardsNum("Jink") > 1 or (self.player:getHp() >= 2 and self.player:getArmor() and not self.player:hasArmorEffect("SilverLion")))
				and (not card:isKindOf("Analeptic") or self:getCardsNum("Jink") > 0 or self.player:getHp() >= 2)
				then
				card_id = card:getEffectiveId() break
			end
		end
		if card_id then
			local TH_skillcard = sgs.Card_Parse("#TH_lordskill_subCARD:" .. card_id .. ":")
			assert(TH_skillcard)
			return TH_skillcard
		end
	elseif self.player:getKingdom() == "qun" then
		local first, second
		for _, c in ipairs(cards) do
			if self:getUseValue(c) < 6 then
				if not first then
					first = c
				elseif first and c:getSuit() == first:getSuit() then
					second = c
				end
				if first and second then break end
			end
		end
		if first and second then
			local TH_skillcard = sgs.Card_Parse("#TH_lordskill_subCARD:" .. first:getEffectiveId() .. "+" .. second:getEffectiveId() .. ":")
			assert(TH_skillcard)
			return TH_skillcard
		end
	else
		local card_id
		for _, card in ipairs(cards) do
			if (not card:isKindOf("Peach") or self:getCardsNum("Peach") > 1)
				and (not card:isKindOf("Jink") or self:getCardsNum("Jink") > 1 or (self.player:getHp() >= 2 and self.player:getArmor() and not self.player:hasArmorEffect("SilverLion")))
				and (not card:isKindOf("Analeptic") or self:getCardsNum("Jink") > 0 or self.player:getHp() >= 2)
				then
				card_id = card:getEffectiveId() break
			end
		end
		if card_id then
			local TH_skillcard = sgs.Card_Parse("#TH_lordskill_subCARD:" .. card_id .. ":")
			assert(TH_skillcard)
			return TH_skillcard
		end
	end
end

sgs.ai_skill_use_func["#TH_lordskill_subCARD"] = function(card, use, self)
	sgs.ai_use_priority.TH_lordskill_subCARD = 0
	if self.player:hasUsed("#TH_lordskillCARD") then return end
	local lord = self.room:getLord()
	if not lord then return end
	if self.player:getKingdom() == "wei" then
		self:sort(self.enemies, "hp")
		local first, second
		for _, enemy in ipairs(self.enemies) do
			if self:damageIsEffective(enemy, nil, lord) and self:TheWuhun(enemy) >= 0 and enemy:objectName() ~= lord:objectName()
				and enemy:objectName() ~= self.player:objectName() then
				if enemy:getMark("@TH_terriblesouvenir") > 0 then
					use.card = card
					if use.to then use.to:append(enemy) end
					return
				elseif self:needToLoseHp(enemy, lord) and not second then
					second = enemy
				elseif not self:needToLoseHp(enemy, lord) and not first then
					first = enemy
				end
			end
		end
		if first then
			use.card = card
			if use.to then use.to:append(first) end
			return
		end
		for _, friend in ipairs(self.friends_noself) do
			if self:damageIsEffective(friend, nil, lord) and self:TheWuhun(friend) >= 0 and friend:objectName() ~= lord:objectName()
				and friend:objectName() ~= self.player:objectName() and self:needToLoseHp(friend, lord) and friend:getMark("@TH_terriblesouvenir") == 0 then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
		if second then
			use.card = card
			if use.to then use.to:append(second) end
			return
		end
	elseif self.player:getKingdom() == "shu" then
		local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
		local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)
		self:useCardSnatchOrDismantlement(snatch, dummy_use)
		if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
			local t = dummy_use.to:at(0)
			if t:objectName() ~= self.player:objectName() and t:objectName() ~= lord:objectName() then
				use.card = card
				if use.to then use.to:append(t) end
				return
			end
		end

	elseif self.player:getKingdom() == "wu" then
		use.card = card
		return
	elseif self.player:getKingdom() == "qun" then
		sgs.ai_use_priority.TH_lordskill_subCARD = 3
		use.card = card
		return
	else
		use.card = card
		return
	end
end

sgs.ai_skill_choice.TH_invoke_lordskill = function(self, choices, data)
	local cp = self.room:getCurrent()
	if cp:getKingdom() == "wei" then
		local target
		for _, ap in sgs.qlist(self.room:getOtherPlayers(self.palyer)) do
			if ap:objectName() ~= cp:objectName() and ap:hasFlag("TH_lordskill_target") then target = ap break end
		end
		if target then
			if self:TheWuhun(target) >= 0 and (not self:needToLoseHp(target, self.player) and self:isEnemy(target) or self:isFriend(target) and self:needToLoseHp(target, self.player)) then
				return "yes"
			end
		end
		return "no"
	else
		return "yes"
	end
end

sgs.ai_skill_choice.TH_lordskill_men = function(self, choices, data)
	if not self.player:faceUp() and not self.player:hasSkill("TH_sichongjiejie")
		and not (self.player:hasSkill("TH_sichongcunzai+TH_huanyue") and self.player:getMark("TH_huanyue_waked") > 0) then
		return "TH_turnover"
	end
	if self.player:isWounded() and (self:isWeak()
									or self.player:getHandcardNum() - 2 > self:getOverflow(nil, true)
									or self.player:getHandcardNum() > 10
									or self.player:getLostHp() > 1 and self.player:hasSkill("TH_tianjiedetaozi")
									or self.player:hasSkill("TH_huanlongyueni") and self.player:getEquips():length() > 1
									or self.player:getLostHp() > 1 and hasWulingEffect("@water")) then
		return "TH_recover1"
	end
	return "TH_draw2"
end

sgs.ai_event_callback[sgs.CardUsed].TH_lordskill_subCARD = function(self, player, data)
	local use = data:toCardUse()
	if use.card and use.card:objectName() == "TH_lordskill_subCARD" then
		local lord = self.room:getLord()
		if not lord then return end
		if use.from:getKingdom() == "wei" then
			for _, to in sgs.qlist(use.to) do
				local intention = self:needToLoseHp(to, lord) and 0 or 10
				sgs.updateIntention(use.from, to, intention)
			end
		elseif use.from:getKingdom() == "shu" then
		else
			sgs.updateIntention(use.from, lord, -10)
		end
	end
end


sgs.ai_use_priority.TH_lordskill_subCARD = 0

------�������������������������������������������������������������������������������---------------------------------------
local function TableRemoveOne(atable, str)
	local new = {}
	for _, t in ipairs(atable) do
		if t ~= str then table.insert(new, t) end
	end
	return new
end
local function TableContainsOne(atable, str)
	for _, t in ipairs(atable) do
		if t == str then return true end
	end
	return
end

function SmartAI:askForKingdom()
	local kingdoms = sgs.Sanguosha:getKingdoms()
	kingdoms = TableRemoveOne(kingdoms, "god")
	if sgs.GetConfig("EnableHegemony", false) then
		kingdoms = { "wei", "shu", "wu", "qun" }
		return kingdoms[math.random(1, #kingdoms)]
	end

	local lord = self.room:getLord()
	if not lord then return kingdoms[math.random(1, #kingdoms)] end
	if self.player:isLord() then
		local baka = true
		if TableContainsOne(kingdoms, "TH_kingdom_baka") then
			for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
				if ap:hasSkill("TH_allbaka") then
					if ap:getRole() == "rebel" then baka = false
					else return "TH_kingdom_baka" end
				end
			end
		end
		if not baka then
			kingdoms = TableRemoveOne(kingdoms, "TH_kingdom_baka")
		end
		return kingdoms[math.random(1, #kingdoms)]
	end
	if self.player:getRole() == "rebel" then
		local baka = true
		if TableContainsOne(kingdoms, "TH_kingdom_baka") then
			for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
				if ap:hasSkill("TH_allbaka") then
					if ap:getRole() == "rebel" then return "TH_kingdom_baka"
					else baka = false end
				end
			end
		end
		if lord:hasSkill("TH_allbaka") or not baka then
			kingdoms = TableRemoveOne(kingdoms, "TH_kingdom_baka")
		end
		if lord:hasLordSkill("xueyi") then
			kingdoms = TableRemoveOne(kingdoms, "qun")
		end
		if lord:hasLordSkill("shichou") then
			kingdoms = TableRemoveOne(kingdoms, "shu")
		end
		if lord:hasLordSkill("TH_lordskill") then
			return kingdoms[math.random(1, #kingdoms)]
		end
		if TableContainsOne(kingdoms, lord:getKingdom()) then return lord:getKingdom()
		else return kingdoms[math.random(1, #kingdoms)]
		end
	end
	if self.player:getRole() == "loyalist" or self.player:getRole() == "renegade" then
		if (lord:hasLordSkill("jijiang") or lord:hasLordSkill("shichou")) and TableContainsOne(kingdoms, "shu") then
			return "shu"
		elseif (lord:hasLordSkill("hujia") or lord:hasLordSkill("songwei")) and TableContainsOne(kingdoms, "wei") then
			return "wei"
		elseif (lord:hasLordSkill("jiuyuan") or lord:hasLordSkill("zhiba")) and TableContainsOne(kingdoms, "wu") then
			return "wu"
		elseif (lord:hasLordSkill("huangtian") or lord:hasLordSkill("xueyi") or lord:hasLordSkill("baonue")) and TableContainsOne(kingdoms, "qun") then
			return "qun"
		end
		local baka = true
		if TableContainsOne(kingdoms, "TH_kingdom_baka") then
			for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
				if ap:hasSkill("TH_allbaka") then
					if (ap:getRole() == "loyalist" or ap:getRole() == "lord") and TableContainsOne(kingdoms, "TH_kingdom_baka") then
						return "TH_kingdom_baka"
					else baka = false end
				end
			end
		end
		if not baka then
			kingdoms = TableRemoveOne(kingdoms, "TH_kingdom_baka")
		end
		if lord:hasLordSkill("TH_lordskill") then
			return kingdoms[math.random(1, #kingdoms)]
		end
		if TableContainsOne(kingdoms, lord:getKingdom()) then return lord:getKingdom()
		else return kingdoms[math.random(1, #kingdoms)] end
	end
	return kingdoms[math.random(1, #kingdoms)]
end

--========================================================Equips
sgs.ai_weapon_value.TH_Weapon_Laevatein = function(self, enemy, player) ---����͡
	if enemy and enemy:getArmor() then return 4 end
end
sgs.ai_slash_weaponfilter.TH_Weapon_Laevatein = function(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.TH_Weapon_Laevatein, player:getAttackRange()) then return end
	return to:getArmor() and not player:hasWeapon("TH_Weapon_SpearTheGungnir")
end
sgs.weapon_range.TH_Weapon_Laevatein = 2
sgs.ai_use_priority.TH_Weapon_Laevatein = 5.650
sgs.ai_use_revises.TH_Weapon_Laevatein = function(self,card,use)
	if card:isKindOf("Slash") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
		card:setFlags("Qinggang")
	end
end

sgs.ai_weapon_value.TH_Weapon_SpearTheGungnir = function(self, enemy, player) --�Ը����
	if enemy then return 7 end
end
sgs.ai_slash_weaponfilter.TH_Weapon_SpearTheGungnir = function(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.TH_Weapon_SpearTheGungnir, player:getAttackRange()) then return end
	return getCardsNum("Jink", to, player) > 0
end
sgs.weapon_range.TH_Weapon_SpearTheGungnir = 5

sgs.ai_canliegong_skill.TH_Weapon_SpearTheGungnir = function(self, from, to)
	return from:getWeapon() and from:getWeapon():isKindOf("TH_Weapon_SpearTheGungnir") and from:hasEquip("TH_Weapon_SpearTheGungnir")
end
-- sgs.ai_use_priority.TH_Weapon_SpearTheGungnir = 5.700

sgs.ai_weapon_value.TH_Weapon_Penglaiyuzhi = function(self, enemy, player)--������֦
	if enemy then
		if string.find(player:getGeneralName(), "HouraisanKaguya") or string.find(player:getGeneral2Name(), "HouraisanKaguya") then
			if player:distanceTo(enemy) <= math.max(sgs.weapon_range.TH_Weapon_Penglaiyuzhi, player:getAttackRange()) then return 7
			else return 3
			end
		else return 2
		end
	end
end
sgs.ai_slash_weaponfilter.TH_Weapon_Penglaiyuzhi = function(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.TH_Weapon_Penglaiyuzhi, player:getAttackRange()) then return end
	return player:hasSkill("paoxiao")
end
sgs.weapon_range.TH_Weapon_Penglaiyuzhi = 1
sgs.ai_use_priority.TH_Weapon_Penglaiyuzhi = 5.635

sgs.ai_weapon_value.TH_Weapon_BailouLouguan = function(self, enemy, player)--��¥����¥�۽�
	if enemy then return enemy:getHandcardNum() < 2 and 5 or 4 end
end
sgs.ai_slash_weaponfilter.TH_Weapon_BailouLouguan = function(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.TH_Weapon_BailouLouguan, player:getAttackRange()) then return end
	return getCardsNum("Jink", to, player) > 1 and not player:hasWeapon("TH_Weapon_SpearTheGungnir")
end
sgs.weapon_range.TH_Weapon_BailouLouguan = 2
sgs.ai_use_priority.TH_Weapon_BailouLouguan = 5.687

sgs.ai_weapon_value.TH_Weapon_Feixiangjian = function(self, enemy, player)--��뽣
	if enemy then return 4 end
end
sgs.ai_slash_weaponfilter.TH_Weapon_Feixiangjian = function(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.TH_Weapon_Feixiangjian, player:getAttackRange()) then return end
	return getCardsNum("Jink", to, player) >= 1 and not player:hasWeapon("TH_Weapon_SpearTheGungnir")
end
sgs.weapon_range.TH_Weapon_Feixiangjian = 2
--sgs.ai_use_priority.TH_Weapon_Feixiangjian = 5.686
sgs.ai_skill_choice.TH_Weapon_Feixiangjian = function(self, choices, data)
	local to = data:toPlayer()
	if self:isFriend(to) then return "cancel" end
	local Jinks = getKnownCard(to, self.player, "Jink", true, "h", true)
	if Jinks > 0 then
		for _, jink in sgs.qlist(to:getHandcards()) do
			if jink:isKindOf("Jink") and jink:isRed() then return "red"
			elseif jink:isKindOf("Jink") and jink:isBlack() then return "black"
			end
		end
	end
	return "red"
end

sgs.ai_skill_choice.ponian = function(self, choices, data)
    local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
	    if not target:hasEquip() or self:isWeak(target) or damage.damage > 1 then 
		    return "killconcept" 
	    else
	        return "causedamage"
	    end
	elseif self:isEnemy(target) then
	    if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then
	        return "killconcept"
        else	
	        return "causedamage"
	    end
	end
	return "causedamage"
end

sgs.ai_skill_choice.genyuan = "recover"

Jiuzi_skill = {}
Jiuzi_skill.name = "Jiuzi"
table.insert(sgs.ai_skills, Jiuzi_skill)
Jiuzi_skill.getTurnUseCard = function(self)
	local player = self.player
	local used = self.player:usedTimes("#JiuziCard")
	for _,enemy in ipairs(self.enemies) do
		if player:canSlash(enemy, nil, false) and (player:getMark("@jianding") > 0 ) and (used < player:getHp()) then
			local parse = sgs.Card_Parse("#JiuziCard:.:")
			assert (parse ~= nil)
			return parse
		end
	end
	return nil
end
sgs.ai_skill_use_func["#JiuziCard"] = function(card, use, self)
    local enemyfound = false
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, nil, false) and self:slashIsEffective(card, enemy) and enemy:hasFlag("zhisi_lost") and 
		    not (enemy:hasSkill("kongcheng") and  enemy:isKongcheng()) and not (enemy:hasSkill("xiangle") and self:getCardsNum("BasicCard") == 0)
			and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
			use.card = card
			if use.to then
				use.to:append(enemy)
				enemyfound = true
			end
			return
		end
	end
	if enemyfound == false then
	    for _,enemy in ipairs(self.enemies) do
		    if self.player:canSlash(enemy, nil, false) and self:slashIsEffective(card, enemy) and 
		        not (enemy:hasSkill("kongcheng") and  enemy:isKongcheng()) and not (enemy:hasSkill("xiangle") and self:getCardsNum("BasicCard") == 0)
			    and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
			    use.card = card
			    if use.to then
				    use.to:append(enemy)
			    end
			    return
		    end
	    end
    end		
end


zhisi_skill = {}
zhisi_skill.name = "zhisi"
table.insert(sgs.ai_skills, zhisi_skill)
zhisi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#zhisiCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#zhisiCard:.:")
end
sgs.ai_skill_use_func["#zhisiCard"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local jiuzislash = sgs.Card_Parse("#JiuziCard:.:")
	for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, nil, false) and self:slashIsEffective(jiuzislash, enemy) and
		not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and (enemy:getMark("@sharengui") >= 1) and
		not enemy:isKongcheng() and self:canAttack(enemy, self.player) and 
		not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
			local maxpoint = self:getMaxCard(self.player):getNumber()
			if maxpoint > 9  or (self.player:hasSkill("yingyang") and maxpoint > 6) then
			    use.card = card
			    if use.to then
				use.to:append(enemy)
			    end
			end
			return
		end
	end
end

function sgs.ai_skill_pindian.zhisi(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	if requestor:getHandcardNum() <= 2 then return minusecard end
end

sgs.ai_card_intention.zhisiCard = 70
sgs.ai_use_value.zhisiCard = 9.2
sgs.ai_use_priority.zhisiCard = 9.2