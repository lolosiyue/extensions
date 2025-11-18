--["qhstandard-ai"] = "标准版-强化-ai",
--global_room:writeToConsole(debug.traceback())--调试ai

----------------卡牌拓展----------------

--乐不思蜀-强化
function SmartAI:useCardQhstandardIndulgence(card, use)                                                                                          --卡牌使用
	local enemies = self
		.enemies                                                                                                                                 --获取所有敌方角色
	if #enemies > 0 then
		self:sort(enemies, "threat")                                                                                                             --将目标按威胁值从大到小排序
		for _, enemy in ipairs(enemies) do
			if not enemy:containsTrick("qhstandard_indulgence") and not enemy:containsTrick("indulgence") and not enemy:containsTrick("YanxiaoCard") then --判定区无相同牌 言笑牌
				use.card = card
				if use.to then                                                                                                                   --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value.QhstandardIndulgence = 9        --使用价值
sgs.ai_use_priority.QhstandardIndulgence = 0.5   --使用优先值
sgs.ai_card_intention.QhstandardIndulgence = 120 --仇恨值
sgs.ai_keep_value.QhstandardIndulgence = 3.5     --保留值

----------------武将拓展----------------

--标准版-强化 曹操-奸雄
sgs.ai_skill_invoke.qhstandardjianxiong = function(self, data) --是否发动技能
	return true                                                --始终发动
end
sgs.ai_target_revises.qhstandardjianxiong = sgs.ai_target_revises.jianxiong

sgs.ai_can_damagehp.qhstandardjianxiong = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return (card and (card:isKindOf("Duel") or card:isKindOf("AOE"))) or to:getHandcardNum() < 4
	end
end
sgs.ai_ajustdamage_from.qhstandardjianxiong = function(self, from, to, card, nature)
	return from:getMark("&qhstandardjianxiong")
end


--奋血
sgs.ai_skill_playerchosen.qhstandardfenxue = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "value")                                  --将目标按综合值从小到大排序
	for _, target in ipairs(targetTable) do                          --对所有目标进行扫描
		if self:isEnemy(target) then                                 --目标是敌方
			return target
		end
	end
end

--护驾
sgs.ai_skill_invoke.qhstandardhujia = function(self, data)        --是否发动技能
	local cards = self.player:getHandcards()                      --获取手牌
	local current = self.room:getCurrent()
	if self:isFriend(current) and self:getOverflow(current) > 2 then --若当前回合是友方回合且多余牌大于2
		return true                                               --发动
	end
	for _, card in sgs.qlist(cards) do                            --对手牌进行扫描
		if card:isKindOf("Jink") then                             --若有闪
			return false                                          --不发动
		end
	end
	return #self.friends_noself > 0 --有友方则发动
end

sgs.ai_skill_cardask["#askForqhstandardhujia"] = function(self, data) --询问使用或打出一张卡牌
	local source = data:toPlayer()                                    --获取发起者
	if not self:isFriend(source) then return "." end                  --不是友方则不出
	local handcards = self.player:getCards("h")                       --获取手牌
	if handcards:isEmpty() then return "." end                        --没牌则不出
	local cards = {}
	for _, card in sgs.qlist(handcards) do                            --对手牌进行扫描
		if card:isKindOf("Jink") then                                 --类型是闪,isKindOf要大写
			table.insert(cards, card)
		end
	end
	if #cards == 0 then return "." end --没闪则不出
	self:sortByKeepValue(cards)     --按保留值从小到大排序
	local card = cards[1]
	return card:getEffectiveId()    --出闪
end

--标准版-强化 司马懿-反馈
sgs.ai_skill_invoke.qhstandardfankui = function(self, data) --是否发动技能
	local damage = data:toDamage()                          --获取伤害来源
	local from = damage.from
	local target = damage.to
	if from:isNude() then return true end --没牌则发动
	if self:isFriend(from) then
		if self:getOverflow(from) > 2 then return true end
		if self:doDisCard(from, "he", true) then return true end
		return (self:hasSkills(sgs.lose_equip_skill, from) and not target:getEquips():isEmpty())
			or (self:needToThrowArmor(from) and from:getArmor()) or self:doDisCard(from, "he", true)
	end
	if self:isEnemy(from) then
		if not self:doDisCard(from, "he", true) then return false end
		return true
	end
	return true
end


sgs.ai_can_damagehp.qhstandardfankui = function(self,from,card,to)
	if to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return (from and self:isEnemy(from)) or not from
	end
end


--鬼才
sgs.ai_skill_invoke.qhstandardguicai = function(self, data) --是否发动技能
	local friends = self.friends                            --获取所有友方角色
	for _, friend in ipairs(friends) do                     --对所有友方角色进行扫描
		local DelayedTrickCard = friend:getJudgingArea()    --获取判定区卡牌
		if DelayedTrickCard:length() > 0 then               --判定区有牌
			return true                                     --发动
		end
	end
end

sgs.ai_skill_playerchosen.qhstandardguicai_PlayerChosen1 = function(self, targets) --选择目标
	local DelayedTrickCard = self.player:getJudgingArea()                          --获取判定区卡牌
	if DelayedTrickCard:length() > 0 then                                          --判定区有牌
		return self.player                                                         --选自己
	end
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "value")      --将目标按综合值从小到大排序
	for _, target in ipairs(targetTable) do --对所有目标进行扫描
		if self:isFriend(target) then    --目标是友方
			return target
		end
	end
end

sgs.ai_skill_playerchosen.qhstandardguicai_PlayerChosen2 = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "value")                                                --将目标按综合值从小到大排序
	for _, target in ipairs(targetTable) do                                        --对所有目标进行扫描
		if not self:isFriend(target) then                                          --目标不是友方
			return target
		end
	end
end


local qhstandardguicaiVS_skill = {}
qhstandardguicaiVS_skill.name = "qhstandardguicai"
table.insert(sgs.ai_skills, qhstandardguicaiVS_skill)
qhstandardguicaiVS_skill.getTurnUseCard = function(self)             --考虑使用视为技的可能性
	if self.player:hasFlag("qhstandardguicai_used") then return nil end --有标志则不用
	return sgs.Card_Parse("#qhstandardguicaiCARD:.:")                --返回技能卡
	--注意技能卡前面+#号，后面连接用:号
end

sgs.ai_skill_use_func["#qhstandardguicaiCARD"] = function(card, use, self) --技能卡的使用函数(不完整)
	local enemies = self.enemies                                           --获取所有敌方角色
	local getvalue = function(enemy)                                       --新建函数 获得修改综合值
		local value = sgs.getValue(enemy)
		local start = enemy:getMark("Player_Start")
		local finish = enemy:getMark("Player_Finish")
		if start > 0 or finish > 0 then
			value = value + 20
		end
		return value
	end
	local compare_func = function(a, b) --排序方法
		return getvalue(a) < getvalue(b)
	end
	table.sort(enemies, compare_func) --排序
	local target = enemies[1]      --综合值最小的敌方为目标
	if target then
		use.card = card
		if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
			use.to:append(target)
		end
	end
	return
end

--天命
local qhstandardtianming_skill = {}
qhstandardtianming_skill.name = "qhstandardtianming"
table.insert(sgs.ai_skills, qhstandardtianming_skill)
qhstandardtianming_skill.getTurnUseCard = function(self)                               --考虑使用视为技的可能性
	if self.player:hasUsed("#qhstandardtianmingCARD") then return nil end              --用过技能卡则不用
	local cards = sgs.QList2Table(self.player:getHandcards())                          --获取手牌
	if #cards < 2 then return nil end
	self:sortByUseValue(cards, true)                                                   --按使用价值从小到大排列卡牌
	return sgs.Card_Parse("#qhstandardtianmingCARD:" .. cards[1]:getEffectiveId() .. ":") --返回技能卡
end

sgs.ai_skill_use_func["#qhstandardtianmingCARD"] = function(card, use, self) --技能卡的使用函数(不完整)
	local enemies = self.enemies                                             --获取所有敌方角色
	self:sort(enemies, "value", true)                                        --排序
	local target = enemies[1]                                                --综合值最大的敌方为目标
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
	return
end

--标准版-强化 夏侯惇-刚烈
sgs.ai_skill_invoke.qhstandardganglie = function(self, data) --是否发动技能
	local from = data:toPlayer()                             --获取伤害来源
	if from == nil or not self:isFriend(from) then           --没有伤害来源或伤害来源不是友方
		return true                                          --发动
	end
end
sgs.ai_can_damagehp.qhstandardganglie = function(self,from,card,to)
	if to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return (from and self:isEnemy(from) and not self:cantbeHurt(from) and self:damageIsEffective(from)) or not from
	end
end

-- sgs.ai_need_damaged.qhstandardganglie = sgs.ai_need_damaged.ganglie

sgs.ai_slash_prohibit.qhstandardganglie = sgs.ai_slash_prohibit.ganglie

sgs.ai_skill_playerchosen.qhstandardganglie = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "hp")                                      --将目标按体力值从小到大排序
	for _, target in ipairs(targetTable) do                           --对所有目标进行扫描
		if self:isEnemy(target) then                                  --目标是敌方
			return target
		end
	end
end

--标准版-强化 张辽-突袭
sgs.ai_skill_use["@qhstandardtuxi"] = function(self, prompt) --被动技能卡的使用函数
	local Int = self.player:getMark("qhstandardtuxi_length") --获取标记
	Int = Int + 1                                            --加1
	self:updatePlayers()
	local enemies = self.enemies                             --获取所有敌方角色
	self:sort(enemies, "handcard_defense")                   --将所有敌方角色按手牌防御值从小到大排序
	local targets = {}
	local n = 0
	for _, enemy in ipairs(enemies) do --对所有敌方角色进行扫描
		if not enemy:isKongcheng() then --有手牌
			table.insert(targets, enemy:objectName())
			n = n + 1               --加1
			if n == Int then break end
		end
	end
	if #targets > 0 then
		local targetstring = table.concat(targets, "+") --转换为字符串
		return ("#qhstandardtuxiCARD:.:->" .. targetstring) --格式为 技能卡:发动卡牌:->目标
	end
end

sgs.ai_skill_discard.qhstandardtuxiCARD = function(self, discard_num, min_num, optional, include_equip) --突袭 制衡效果
	local pattern = self.player:property("qhstandardtuxi_card"):toString():split(",")
	local to_discard = {}                                                                               -- 初始化 to_discard 为空表
	for _, value in ipairs(pattern) do
		local id = tonumber(value)
		if id then
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Slash") and self:getCardsNum("Slash") >= 2 then
				table.insert(to_discard, id)
			end
			if c:isKindOf("Jink") and self:getCardsNum("Jink") >= 2 then
				table.insert(to_discard, id)
			end
		end
	end
	return to_discard
end
sgs.drawpeach_skill = sgs.drawpeach_skill .. "|qhstandardtuxi"

--标准版-强化 许褚-裸衣
sgs.ai_skill_invoke.qhstandardluoyi = function(self, data) --是否发动技能
	return true                                            --发动
end

sgs.ai_skill_choice.qhstandardluoyi = function(self, choices, data) --进行选择
	if self.player:isSkipped(sgs.Player_Play) then                  --跳过出牌
		return "Luoyi_duo"
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	if #cards < 3 then --手牌小于3
		return "Luoyi_duo"
	end
	local slashtarget = 0
	local dueltarget = 0
	local othertarget = 0
	self:sort(self.enemies, "hp")
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then --杀
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) then
					if getCardsNum("Jink", enemy) < 1 or (self:isEquip("Axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if card:isKindOf("Duel") then --决斗
			for _, enemy in ipairs(self.enemies) do
				if not self:cantbeHurt(enemy) and self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) and self:damageIsEffective(enemy) then
					dueltarget = dueltarget + 1
				end
			end
		end
		if card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") then --南蛮 万箭
			othertarget = othertarget + 1
		end
	end
	if (slashtarget + dueltarget + othertarget) > 0 then
		return "Luoyi_shao"
	else
		return "Luoyi_duo"
	end
end

sgs.ai_cardneed.qhstandardluoyi = sgs.ai_cardneed.luoyi
sgs.ai_ajustdamage_from.qhstandardluoyi = function(self, from, to, card, nature)
	if from:getMark("Luoyi_shao") > 0 and card and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) then
		return 1
	end
end

--标准版-强化 郭嘉-天妒
sgs.ai_skill_invoke.qhstandardtiandu = function(self, data) --是否发动技能
	local use = data:toCardUse()
	local target = use.to:at(0)                             --目标
	local HandcardNum = target:getHandcardNum()             --手牌数
	if HandcardNum < 3 then
		return true                                         --发动
	end
	if use.card:isKindOf("DelayedTrickCard") then           --延时性锦囊
		return true                                         --发动
	end
	local cards = sgs.QList2Table(target:getCards("h"))     --获取手牌
	self:sortByKeepValue(cards)                             --按保留值从小到大排列卡牌
	for _, card in ipairs(cards) do                         --对卡牌进行扫描
		if not card:isKindOf("Peach") and self:getKeepValue(card) < self:getKeepValue(use.card) then
			return true                                     --发动
		end
	end
end

sgs.ai_skill_discard.qhstandardtiandu = function(self) --弃牌选择
	local to_discard = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) --按保留值从小到大排列卡牌
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

--遗计
sgs.ai_skill_invoke.qhstandardyiji = function(self, data) --是否发动技能
	return true                                           --发动
end
sgs.ai_can_damagehp.qhstandardyiji = function (self,attacker,player)
	if not player:hasSkill("yiji") then return end
	local friends = {}
	for _,ap in sgs.list(self.room:getAlivePlayers())do
		if self:isFriend(ap,player) then
			table.insert(friends,ap)
		end
	end
	self:sort(friends,"hp")

	if #friends>0 and friends[1]:objectName()==player:objectName() and self:isWeak(player) and getCardsNum("Peach",player,(attacker or self.player))==0 then return false end

	return player:getHp()>2 and sgs.turncount>2 and #friends>1 and not self:isWeak(player) and player:getHandcardNum()>=2
end

sgs.ai_can_damagehp.qhstandardyiji = sgs.ai_can_damagehp.yiji

--标准版-强化 甄姬-洛神
sgs.ai_skill_invoke.qhstandardluoshen = function(self, data) --是否发动技能
	return true                                              --发动
end

--倾国
sgs.ai_view_as.qhstandardqingguo = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:getSuit() ~= sgs.Card_Heart then
		return ("jink:qhstandardqingguo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

function sgs.ai_cardneed.qhstandardqingguo(to, card, self)
	--在分牌时，自己 to 的友方玩家 self 先将自己需要的卡牌 card 交给自己
	return to:getHandcardNum() < 3 and card:getSuit() ~= sgs.Card_Heart
end

sgs.qingguo_suit_value = {
	spade = 4.1,
	club = 4.2
}

--风包-强化 夏侯渊-神速
sgs.ai_skill_use["@qhwindshensu"] = function(self, prompt) --被动技能卡的使用函数
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	if prompt == "#askForUseqhwindshensuVS1" then --跳过判定摸牌
		if self.player:containsTrick("lightning") and self.player:getCards("j"):length() == 1
			and self:hasWizard(self.friends) and not self:hasWizard(self.enemies, true) then
			return "."
		end
		for _, enemy in ipairs(self.enemies) do
			local def = self:getDefenseSlash(enemy)
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			if not self.player:canSlash(enemy, slash, false) then
			elseif self:slashProhibit(nil, enemy) then
			elseif def < 6 and enemy:getHp() < 3 and eff then
				return "#qhwindshensuCARD:.:->" .. enemy:objectName() --低防御用技能
			elseif self.player:getHp() - self.player:getHandcardNum() >= 2 then
				return "."
			elseif self.player:getHandcardNum() <= 2 then
				return "."
			elseif sgs.getDefense(self.player) < 6 then
				return "."
			elseif def < 6 and eff then
				return "#qhwindshensuCARD:.:->" .. enemy:objectName() --低防御用技能
			end
		end
	elseif prompt == "#askForUseqhwindshensuVS2" then --跳过出牌
		local cards = sgs.QList2Table(self.player:getHandcards())
		local shouldUseCard, range_fix = 0, 0
		local hasCrossbow = false
		if self.player:getHandcardNum() <= 2 and not self:getCardsNum("Peach") and self.player:getHp() > 1 then
			shouldUseCard = shouldUseCard - 10
		end
		for _, card in ipairs(cards) do
			if card:isKindOf("TrickCard") and self:getUseValue(card) > 3.69 then --锦囊
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then shouldUseCard = shouldUseCard + (card:isKindOf("ExNihilo") and 2 or 1) end
			end
			if card:isKindOf("Weapon") then
				local new_range = sgs.weapon_range[card:getClassName()] or 0
				local current_range = self.player:getAttackRange()
				range_fix = math.min(current_range - new_range, 0)
			end
			if card:isKindOf("Peach") and self.player:isWounded() then --桃
				shouldUseCard = shouldUseCard + 2
			end
			if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix - 1 end
			if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink") == 0) then
				shouldUseCard =
					shouldUseCard + 1
			end
			if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
			local slashs = self:getCards("Slash")
			for _, enemy in ipairs(self.enemies) do
				for _, slash in ipairs(slashs) do
					if hasCrossbow and self:getCardsNum("Slash") > 1 and self:slashIsEffective(slash, enemy)
						and self.player:canSlash(enemy, slash, true, range_fix) then
						shouldUseCard = shouldUseCard + 2
						hasCrossbow = false
						break
					elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash, enemy)
						and self.player:canSlash(enemy, slash, true, range_fix) and getCardsNum("Jink", enemy) < 1 then
						shouldUseCard = shouldUseCard + 1
						slashTo = true
					end
				end
			end
		end
		if shouldUseCard > 2 then return "." end --有可用牌不用技能
		for _, enemy in ipairs(self.enemies) do
			local def = sgs.getDefense(enemy)
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			if not self.player:canSlash(enemy, slash, false) then
			elseif self:slashProhibit(nil, enemy) then
			elseif eff then
				if shouldUseCard < 2 then
					return "#qhwindshensuCARD:.:->" .. enemy:objectName()
				elseif def < 8 then
					return "#qhwindshensuCARD:.:->" .. enemy:objectName()
				end
			end
		end
		return "."
	elseif prompt == "#askForUseqhwindshensuVS3" then --受伤
		for _, enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash")
			if not self.player:canSlash(enemy, slash, false) then
			elseif not self:slashProhibit(nil, enemy) and self:slashIsEffective(slash, enemy) then
				return "#qhwindshensuCARD:.:->" .. enemy:objectName() --使用技能
			end
		end
	end
end

sgs.ai_skill_playerchosen.qhwindshensu = function(self, targets) --选择目标
	return self:findPlayerToDiscard("hej", true, false, targets)[1]
end

sgs.ai_choicemade_filter.cardChosen.qhwindshensu = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

sgs.ai_can_damagehp.qhwindshensu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and not sgs.ai_skill_use["@qhwindshensu"](self, "#askForUseqhwindshensuVS3") == "."
end


--风包-强化 曹仁-据守
sgs.ai_skill_invoke.qhwindjushou = function(self, data) --是否发动技能
	if self.player:hasSkill("qhwindjiewei") then
		return true                                     --发动
	end
	return false
end

--解围
sgs.ai_skill_invoke.qhwindjiewei = function(self, data) --是否发动技能
	return true                                         --发动
end

sgs.ai_skill_use["@qhwindjiewei-AI"] = function(self, prompt, method) --被动用卡的使用函数
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not card:isKindOf("Jink") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.qhwindjiewei = function(self, targets) --选择目标
	return self:findPlayerToDiscard("hej", true, true, targets)[1]
end

sgs.ai_choicemade_filter.cardChosen.qhwindjiewei = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

--火包-强化 典韦-强袭
local qhfireqiangxi_skill = {}
qhfireqiangxi_skill.name = "qhfireqiangxi"
table.insert(sgs.ai_skills, qhfireqiangxi_skill)
qhfireqiangxi_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:getHp() > 1 then
		return sgs.Card_Parse("#qhfireqiangxiCARD:.:") --返回技能卡，子卡在 ai_skill_use_func 中添加
	end
end

sgs.ai_skill_use_func["#qhfireqiangxiCARD"] = function(card, use, self)
	local handcards = self.player:getCards("he")
	local enemies = self.enemies                               --获取所有敌方角色
	if #enemies > 0 then
		self:sort(enemies, "hp")                               --将所有敌方角色按体力值从小到大排序
		for _,enemy in sgs.list(self.enemies)do
			if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
				if self.player:getMark("qhfireqiangxi_card-Clear") == 0 then --弃牌
					for _, handcard in sgs.qlist(handcards) do
						if handcard:isKindOf("EquipCard") then
							use.card = sgs.Card_Parse("#qhfireqiangxiCARD:" .. handcard:getEffectiveId() .. ":")
							if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
								use.to:append(enemy)
							end
							return
						end
					end
				end
				if self.player:getMark("qhfireqiangxi_lose-Clear") == 0 then --失去体力
					if self.player:getHp() > 0 then
						use.card = sgs.Card_Parse("#qhfireqiangxiCARD:.:")
						if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
							use.to:append(enemy)
						end
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value["qhfireqiangxiCARD"] = 7.5     --使用价值
sgs.ai_use_priority["qhfireqiangxiCARD"] = 4    --使用优先值
sgs.ai_card_intention["qhfireqiangxiCARD"] = 80 --仇恨值
sgs.dynamic_value.damage_card["qhfireqiangxiCARD"] = true
sgs.ai_cardneed["qhfireqiangxiCARD"] = sgs.ai_cardneed.equip

sgs.qiangxi_keep_value = {
	Peach = 6,
	Jink = 5.1,
	EquipCard = 6
}

--火包-强化 荀彧-驱虎
local qhfirequhu_skill = {}
qhfirequhu_skill.name = "qhfirequhu"
table.insert(sgs.ai_skills, qhfirequhu_skill)
qhfirequhu_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:hasUsed("#qhfirequhuCARD") then return end
	if self:needBear() then return end
	if self.player:getHp() == 1 then return end
	local mcard
	local num = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if not card:isKindOf("Peach") and card:getNumber() > num then
			num = card:getNumber()
			mcard = card
		end
	end
	if mcard then
		return sgs.Card_Parse("#qhfirequhuCARD:" .. mcard:getEffectiveId() .. ":")
	end
end

sgs.ai_skill_use_func["#qhfirequhuCARD"] = function(card, use, self)
	local enemies = self.enemies --获取所有敌方角色
	if #enemies > 0 then
		self:sort(enemies, "handcard") ----将所有敌方玩家按手牌数从小到大排序
		for _, enemy in sgs.list(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) then
				use.card = card
				if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_cardneed["qhfirequhu"] = sgs.ai_cardneed.bignumber
sgs.ai_skill_playerchosen["qhfirequhu"] = sgs.ai_skill_playerchosen.damage                  --选择目标
sgs.ai_use_value["qhfirequhuCARD"] = 7.5                                                    --使用价值
sgs.ai_use_priority["qhfirequhuCARD"] = 6                                                   --使用优先值
sgs.ai_playerchosen_intention["qhfirequhu"] = 80                                            --仇恨值
sgs.ai_choicemade_filter.cardChosen.qhfirequhu = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

--节命
sgs.ai_skill_playerchosen.qhfirejieming = function(self, targets)
	if self.player:getHandcardNum() < 3 then
		return self.player
	end
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "handcard")   --将所有玩家按手牌数从小到大排序
	for _, target in ipairs(targetTable) do --对所有目标进行扫描
		if self:isFriend(target) then    --目标是友方
			return target
		end
	end
end
sgs.ai_playerchosen_intention["qhfirejieming"] = -40  
sgs.ai_need_damaged.qhfirejieming = function (self,attacker,player)
	return player:hasSkill("qhfirejieming") and self:getJiemingChaofeng(player)<=-6
end
sgs.ai_can_damagehp.qhfirejieming = function(self,from,card,to)
	if self:isFriend(to)
	and self:canLoseHp(from,card,to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	then
		for _,fp in sgs.list(self.friends)do
			if fp:getHandcardNum()<5
			and fp:getHandcardNum()<fp:getMaxHp()
			then return true end
		end
	end
end


--标准版-强化 刘备-仁德
local qhstandardrendeVS_skill = {}
qhstandardrendeVS_skill.name = "qhstandardrende"
table.insert(sgs.ai_skills, qhstandardrendeVS_skill)
qhstandardrendeVS_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:isKongcheng() then return nil end    --不发动
	return sgs.Card_Parse("#qhstandardrendeCARD:.:")    --返回技能卡，子卡在 ai_skill_use_func 中添加
end

sgs.ai_skill_use_func["#qhstandardrendeCARD"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)       --按使用价值从小到大排列卡牌
	local Num = self:getOverflow(self.player) --获取多余牌数量
	Num = math.max(Num, 0)                 --取大值
	local friends = self.friends_noself    --获取所有友方角色
	self:sort(friends, "handcard")         --将所有友方玩家按手牌数从小到大排序
	local friend1 = friends[1]
	if not friend1 then return end
	local friend2 = friends[2]
	local Max
	if friend2 then
		Max = friend2:getHandcardNum() - friend1:getHandcardNum() + 1
	else
		Max = 20
	end
	local Int = self.player:getMark("qhstandardrende") --获取标记
	if #cards > Num and Num + Int == (1 or 3) then
		Num = Num + 1
	end
	if #cards > 3 - Int and Num + Int < 2 then
		Num = math.max(Num, 2 - Int) --取大值
	end
	if #cards > 5 - Int and Num + Int < 4 then
		Num = math.max(Num, 4 - Int) --取大值
	end
	Num = math.min(Num, Max)   --取小值
	local usecards = {}
	for i = 1, Num do
		if cards[i] then
			table.insert(usecards, cards[i]:getId())
		end
	end
	if #usecards > 0 then
		use.card = sgs.Card_Parse("#qhstandardrendeCARD:" .. table.concat(usecards, "+") .. ":")
	end
	if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
		use.to:append(friend1)
	end
	return
end

sgs.ai_use_value["qhstandardrendeCARD"] = 8        --使用价值
sgs.ai_use_priority["qhstandardrendeCARD"] = 4     --使用优先值
sgs.ai_card_intention["qhstandardrendeCARD"] = -50 --仇恨值

--激将
local qhstandardjijiangVS_skill = {}
qhstandardjijiangVS_skill.name = "qhstandardjijiang"
table.insert(sgs.ai_skills, qhstandardjijiangVS_skill)
qhstandardjijiangVS_skill.getTurnUseCard = function(self)             --考虑使用视为技的可能性
	if self.player:hasFlag("qhstandardjijiang_used") then return nil end --有标志则不发动
	local cards = self.player:getHandcards()                          --获取手牌
	for _, card in sgs.qlist(cards) do                                --对手牌进行扫描
		if card:isKindOf("Slash") then                                --若有杀
			return nil                                                --不发动
		end
	end
	local friend_num = #self.friends_noself          --获取友方数量
	if friend_num > 0 then                           --有友方则发动
		return sgs.Card_Parse("#qhstandardjijiangCARD:.:") --返回技能卡
	end
end

sgs.ai_skill_use_func["#qhstandardjijiangCARD"] = function(card, use, self) --技能卡的使用函数
	use.card = card
	return
end

sgs.ai_use_value["qhstandardjijiangCARD"] = 2                --使用价值
sgs.ai_use_priority["qhstandardjijiangCARD"] = 1             --使用优先值

sgs.ai_skill_invoke.qhstandardjijiang = function(self, data) --是否发动技能
	local cards = self.player:getHandcards()                 --获取手牌
	for _, card in sgs.qlist(cards) do                       --对手牌进行扫描
		if card:isKindOf("Slash") then                       --若有杀
			return nil                                       --不发动
		end
	end
	local friend_num = #self.friends_noself --获取友方数量
	if friend_num > 0 then               --有友方
		return true                      --发动
	end
end

sgs.ai_skill_cardask["#askForqhstandardjijiang"] = function(self, data) --询问使用或打出一张卡牌
	local source = data:toPlayer()                                      --获取发起者
	if not self:isFriend(source) then return "." end                    --不是友方则不出
	local handcards = self.player:getCards("h")                         --获取手牌
	if handcards:isEmpty() then return "." end                          --没牌则不出
	local cards = {}
	for _, card in sgs.qlist(handcards) do                              --对手牌进行扫描
		if card:isKindOf("Slash") then                                  --类型是杀,isKindOf要大写
			table.insert(cards, card)
		end
	end
	if #cards == 0 then return "." end --没杀则不出
	self:sortByKeepValue(cards)     --按保留值从小到大排列卡牌
	local card = cards[1]
	return card:getEffectiveId()
end

--标准版-强化 关羽-武圣
sgs.ai_view_as.qhstandardwusheng = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") --红色且不是桃
		and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:qhstandardwusheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local qhstandardwusheng_skill = {}
qhstandardwusheng_skill.name = "qhstandardwusheng"
table.insert(sgs.ai_skills, qhstandardwusheng_skill)
qhstandardwusheng_skill.getTurnUseCard = function(self, inclusive) --考虑使用视为技的可能性
	local cards = sgs.QList2Table(self.player:getCards("h"))       --获取手牌
	if self.player:getPile("wooden_ox"):length() > 0 then          --木牛流马上的牌加入
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	local use_card
	self:sortByUseValue(cards, true) --按使用价值从小到大排列卡牌
	local use_cardtype
	if self.player:getMark("qhstandardwusheng-Clear") == 0 then
		for _, card in ipairs(cards) do --对卡牌进行扫描
			if card:getSuit() == sgs.Card_Spade and self.player:isWounded() then
				use_card = card   --出桃
				use_cardtype = "peach"
				break
			end
			if card:getSuit() == sgs.Card_Club and self:getCardsNum("Slash") > 0 then
				use_card = card --出酒
				use_cardtype = "analeptic"
				break
			end
		end
	end
	if not use_card then
		for _, card in ipairs(cards) do --对卡牌进行扫描
			if card:isRed() and sgs.Slash_IsAvailable(self.player) then
				use_card = card   --出杀
				use_cardtype = "slash"
				break
			end
		end
	end
	if use_card then
		local suit = use_card:getSuitString()
		local number = use_card:getNumberString()
		local card_id = use_card:getEffectiveId()
		local card_str = ("%s:qhstandardwusheng[%s:%s]=%d"):format(use_cardtype, suit, number, card_id)
		local acard = sgs.Card_Parse(card_str)
		return acard
	end
end

sgs.ai_cardsview_valuable.qhstandardwusheng = function(self, class_name, player) --多类型响应
	--响应时机
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and
		sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		return
	end
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
	}
	local name = classname2objectname[class_name] --转化名称
	local cards = player:getCards("h")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	if cards:isEmpty() then return end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			return --有牌就不用
		end
	end
	if class_name == "Slash" then
		for _, c in sgs.qlist(cards) do
			if c:isRed() and not player:isCardLimited(c, sgs.Card_MethodUse) then
				local suit = c:getSuitString()
				local number = c:getNumberString()
				local card_id = c:getEffectiveId()
				return ("slash:qhstandardwusheng[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
	if self.player:getMark("qhstandardwusheng-Clear") == 1 then return end
	for _, c in sgs.qlist(cards) do
		if not player:isCardLimited(c, sgs.Card_MethodUse) then
			local suit = c:getSuitString()
			local number = c:getNumberString()
			local card_id = c:getEffectiveId()
			return ("%s:qhstandardwusheng[%s:%s]=%d"):format(name, suit, number, card_id)
		end
	end
end
function sgs.ai_armor_value.qhstandardqinglong(player, self, card)
    if card and card:isKindOf("Blade") then return 4 end
end
sgs.ai_ajustdamage_from.qhstandardqinglong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from:hasWeapon("Blade") then
		return 1
	end
end

--标准版-强化 张飞-丈八
sgs.double_slash_skill = sgs.double_slash_skill .. "|qhstandardpaoxiao"
sgs.ai_cardneed.qhstandardpaoxiao = sgs.ai_cardneed.slash
sgs.ai_cardneed.qhstandardzhangba = sgs.ai_cardneed.slash
sgs.ai_view_as.qhstandardzhangba = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getMark("qhstandardzhangbaUsed-Clear") == 0 and not card:isKindOf("Peach") and not card:hasFlag("using")
		and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:qhstandardzhangba[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local qhstandardzhangba_skill = {}
qhstandardzhangba_skill.name = "qhstandardzhangba"
table.insert(sgs.ai_skills, qhstandardzhangba_skill)
qhstandardzhangba_skill.getTurnUseCard = function(self, inclusive) --考虑使用视为技的可能性
	local cards = sgs.QList2Table(self.player:getCards("h"))       --获取手牌
	if self.player:getPile("wooden_ox"):length() > 0 then          --木牛流马上的牌加入
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(cards, true) --按使用价值从小到大排列卡牌
	if #cards > 1 then
		local card = cards[1]
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local card_str = ("slash:qhstandardzhangba[%s:%s]=%d"):format(suit, number, card_id)
		local acard = sgs.Card_Parse(card_str)
		return acard
	end
end


sgs.ai_ajustdamage_from.qhstandardzhangba = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from:getMark("qhstandardzhangbaMiss-Clear") == 1 then
		return 1
	end
end

--标准版-强化 诸葛亮-观星
sgs.ai_skill_invoke.qhstandardguanxing = function(self, data) --是否发动技能
	return true                                               --发动
end

local qhstandardguanxingVS_skill = {}
qhstandardguanxingVS_skill.name = "qhstandardguanxing"
table.insert(sgs.ai_skills, qhstandardguanxingVS_skill)
qhstandardguanxingVS_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:hasUsed("#qhstandardguanxingCARD") then --使用过技能卡
		return nil                                         --不发动
	end
	return sgs.Card_Parse("#qhstandardguanxingCARD:.:")    --返回技能卡
end

sgs.ai_skill_use_func["#qhstandardguanxingCARD"] = function(card, use, self) --技能卡的使用函数
	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))  --获取其他角色
	local playersB = {}
	for _, play in ipairs(players) do
		if play:getMark("@qhstandardguanxing_target") == 0 then --无标记
			table.insert(playersB, play)                  --添加
		end
	end
	local compare_func = function(a, b) --获得角色的综合值+[判定区有牌-50]
		local v1 = sgs.getValue(a) + (a:getJudgingArea():length() > 0 and -50 or 0)
		local v2 = sgs.getValue(b) + (b:getJudgingArea():length() > 0 and -50 or 0)
		return v1 < v2
	end
	table.sort(playersB, compare_func) --排序
	use.card = card
	if use.to then                  --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
		use.to:append(playersB[1])
	end
	return
end

sgs.ai_use_value["qhstandardguanxingCARD"] = 5    --使用价值
sgs.ai_use_priority["qhstandardguanxingCARD"] = 1 --使用优先值




--标准版-强化 赵云-龙胆
sgs.ai_view_as.qhstandardlongdan = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Slash") then --是杀
		return ("jink:qhstandardlongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
	if card:isKindOf("Jink") then --是闪
		return ("slash:qhstandardlongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
	if card:isKindOf("Analeptic") then --是酒
		return ("peach:qhstandardlongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
	if card:isKindOf("Peach") then --是桃
		return ("analeptic:qhstandardlongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local qhstandardlongdan_skill = {}
qhstandardlongdan_skill.name = "qhstandardlongdan"
table.insert(sgs.ai_skills, qhstandardlongdan_skill)
qhstandardlongdan_skill.getTurnUseCard = function(self)    --考虑使用视为技的可能性
	local cards = sgs.QList2Table(self.player:getCards("he")) --获取手牌和装备牌
	local use_card
	self:sortByUseValue(cards, true)                       --按使用价值从小到大排列卡牌
	local use_cardtype
	for _, card in ipairs(cards) do                        --对卡牌进行扫描
		if card:isKindOf("Peach") and self:getCardsNum("Slash") > 0 and (not self.player:isWounded()) then
			use_card = card                                --出酒
			use_cardtype = "analeptic"
			break
		end
		if card:isKindOf("Analeptic") and self.player:isWounded() then
			use_card = card --出桃
			use_cardtype = "peach"
			break
		end
		if card:isKindOf("Jink") then
			use_card = card --出杀
			use_cardtype = "slash"
			break
		end
	end
	if use_card then
		local suit = use_card:getSuitString()
		local number = use_card:getNumberString()
		local card_id = use_card:getEffectiveId()
		local card_str = ("%s:qhstandardlongdan[%s:%s]=%d"):format(use_cardtype, suit, number, card_id)
		local acard = sgs.Card_Parse(card_str)
		return acard
	end
end

--龙勇
sgs.ai_skill_invoke.qhstandardlongyong = function(self, data) --是否发动技能
	return true                                               --发动
end

--标准版-强化 马超-铁骑
sgs.ai_skill_invoke.qhstandardtieqi = function(self, data) --是否发动技能
	if self.player:hasFlag("use_from") then
		local target = data:toPlayer()
		if not self:isFriend(target) then return true end
		return false
	end
	return true
end
sgs.ai_cardneed.qhstandardtieqi = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|qhstandardtieqi"
sgs.ai_choicemade_filter.skillInvoke.qhstandardtieqi = sgs.ai_choicemade_filter.skillInvoke.tieji

--标准版-强化 黄月英-集智
sgs.ai_skill_invoke.qhstandardjizhi = function(self, data) --是否发动技能
	return true                                            --发动
end
sgs.ai_card_priority.qhstandardjizhi = function(self,card,v)
	if self.useValue
	and card:isKindOf("TrickCard")
	then v = v+3 end
end
function sgs.ai_cardneed.qhstandardjizhi(to,card)
	return card:getTypeId()==sgs.Card_TypeTrick
end
function sgs.ai_cardneed.qhstandardqicai(to,card)
	return card:isKindOf("SingleTargetTrick")
end

sgs.ai_skill_invoke.qhstandardjizhi2 = function(self, data) --是否发动技能
	--local use = data:toCardUse()
	--local dummy_use = { isDummy = true }
	--self:useTrickCard(use.card, dummy_use)
	--if dummy_use.card then
	return true --发动
	--end
end

--风包-强化 黄忠-烈弓
sgs.ai_skill_invoke.qhwindliegong = function(self, data) --是否发动技能
	if self.player:hasFlag("qhwindliegong_TargetSpecified") then
		if self:isEnemy(data:toPlayer()) then
			return true --发动
		end
	else
		local damage = data:toDamage()
		if self.player:getHp() > damage.to:getHp() then
			return true --发动
		elseif self:isEnemy(damage.to) then
			return true --发动
		end
	end
end
sgs.ai_ajustdamage_from.qhwindliegong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from and to and from:getHp() <= to:getHp() then
		return 1
	end
end

sgs.ai_cardneed.qhwindliegong = sgs.ai_cardneed.slash

sgs.ai_canliegong_skill.qhwindliegong = function(self, from, to)
	return to:getHandcardNum() <= from:getAttackRange()
end
sgs.ai_cardneed.qhwindgongshu = sgs.ai_cardneed.weapon

sgs.ai_card_priority.qhwindkuanggu = function(self,card,v)
	if card:isKindOf("Peach")
	then v = 1.09 end
end
sgs.ai_use_revises.qhwindkuanggu = function(self,card,use)
	if card:isKindOf("Peach")
	and not hasJueqingEffect(self.player)
	and self.player:getOffensiveHorse()
	and self.player:getLostHp()==1
	and self:getOverflow()<1
	then return false end
end
function sgs.ai_cardneed.qhwindkuanggu(to,card,self)
	return card:isKindOf("OffensiveHorse") and not (to:getOffensiveHorse() or getKnownCard(to,self.player,"OffensiveHorse",false)>0)
end


--风包-强化 神关羽-武魂
sgs.ai_use_revises.qhwindwushen = function(self,card,use)
	if card:isKindOf("Slash") and card:getSuit() == sgs.Card_Heart then
		card:setFlags("Qinggang")
	end
end
sgs.ai_card_priority.qhwindwushen = function(self,card)
	if card:isKindOf("Slash") and card:getSuit()==sgs.Card_Heart
	then return 0.03 end
end
sgs.ai_suit_priority.qhwindwushen= "club|spade|diamond|heart"
sgs.ai_skill_playerchosen.qhwindwuhun = function(self, targets) --选择目标
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp", true)                              --将目标按体力值从大到小排序
	local target
	local lord
	for _, player in ipairs(targets) do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and not target then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	if self.player:getRole() == "loyalist" and targets[1]:isLord() then return targets[2] end
	return targets[1]
end

sgs.ai_canNiepan_skill.qhwindwuhun = function(player)
	return player:getMark("qhwindwuhun_limit") > 0
end

--火包-强化 庞统-连环
sgs.ai_view_as.qhfirelianhuan = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:getSuit() == sgs.Card_Spade then
		return ("thunder_slash:qhfirelianhuan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local qhfirelianhuan_skill = {}
qhfirelianhuan_skill.name = "qhfirelianhuan"
table.insert(sgs.ai_skills, qhfirelianhuan_skill)
qhfirelianhuan_skill.getTurnUseCard = function(self)       --考虑使用视为技的可能性
	local cards = sgs.QList2Table(self.player:getCards("he")) --获取手牌和装备牌
	local use_card
	self:sortByUseValue(cards, true)                       --按使用价值从小到大排列卡牌
	local use_cardtype
	for _, card in ipairs(cards) do                        --对卡牌进行扫描
		if card:getSuit() == sgs.Card_Spade then
			local usecard = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Spade, card:getNumber())
			usecard:deleteLater()
			local dummy_use = self:aiUseCard(usecard, dummy())
			if dummy_use.card then
				use_card = card --雷杀
				use_cardtype = "thunder_slash"
				break
			end
		end
		if card:getSuit() == sgs.Card_Club then
			use_card = card --铁索
			use_cardtype = "iron_chain"
			break
		end
	end
	if use_card then
		local suit = use_card:getSuitString()
		local number = use_card:getNumberString()
		local card_id = use_card:getEffectiveId()
		local card_str = ("%s:qhfirelianhuan[%s:%s]=%d"):format(use_cardtype, suit, number, card_id)
		local acard = sgs.Card_Parse(card_str)
		return acard
	end
end

sgs.ai_cardneed.qhfirelianhuan = function(to, card, self)
	--在分牌时，自己 to 的友方玩家 self 先将自己需要的卡牌 card 交给自己
	return card:isBlack() and to:getHandcardNum() <= 2
end

--涅槃
sgs.ai_skill_invoke.qhfireniepan = function(self, data) --是否发动技能
	return true                                         --发动
end

sgs.ai_skill_invoke.qhfireniepan_endPlay = function(self, data) --是否发动技能
	--结束出牌询问
	local current = self.room:getCurrent()
	if self:isFriend(current) then
		return false
	else
		return true
	end
end

sgs.ai_canNiepan_skill.qhfireniepan = function(player)
	return player:getMark("qhfireniepan_limit") > 0
end

--火包-强化 诸葛亮-火计
local qhfirehuoji_skill = {}
qhfirehuoji_skill.name = "qhfirehuoji"
table.insert(sgs.ai_skills, qhfirehuoji_skill)
qhfirehuoji_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:getMark("qhfirehuoji-Clear") ~= 0 then
		return nil
	end
	local card_str = ("fire_attack:qhfirehuoji[%s:%s]=."):format("no_suit_red", 0) --无子卡虚拟火攻
	local acard = sgs.Card_Parse(card_str)
	return acard
end

sgs.ai_cardneed.qhfirehuoji = function(to,card,self)
	return to:getHandcardNum()>=2 
end

--看破
sgs.ai_view_as.qhfirekanpo = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isBlack() then
		return ("nullification:qhfirekanpo[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.ai_cardneed.qhfirekanpo = function(to,card,self)
	return card:isBlack()
end


sgs.ai_skill_invoke.qhfirekanpo = function(self, data) --是否发动技能
	return true                                        --发动
end

--八阵
sgs.ai_skill_invoke.qhfirebazhen = function(self, data) --是否发动技能
	return true                                         --发动
end

--火包-强化 神诸葛亮-狂风
sgs.ai_skill_use["@@qhfirekuangfeng"] = function(self, prompt)
	local enemies = self.enemies
	if #enemies > 0 then
		self:sort(enemies, "hp")
		if sgs.ai_skill_use["@@kuangfeng"](self, prompt) ~= "." then
			local str = sgs.ai_skill_use["@@kuangfeng"](self, prompt)
			str = string.gsub(str,"@KuangfengCard","#qhfirekuangfengCARD")
			str = string.gsub(str,"=",":")
			str = string.gsub(str,"->",":->")
			return str
		end
		for _, enemy in ipairs(enemies) do
			if enemy:getMark("&qhfirekuangfeng") > 0 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,"F", self.player) then
				return "#qhfirekuangfengCARD:" .. self.player:getPile("stars"):first() .. ":->" .. enemy:objectName()
			end
		end
		for _, enemy in ipairs(enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,"F", self.player) then
				return "#qhfirekuangfengCARD:" .. self.player:getPile("stars"):first() .. ":->" .. enemy:objectName()
			end
		end
		return "#qhfirekuangfengCARD:" .. self.player:getPile("stars"):first() .. ":->" .. enemies[1]:objectName()
	else
		return "."
	end
end
sgs.ai_ajustdamage_to["&qhfirekuangfeng"] = function(self,from,to,card,nature)
	if nature=="F"
	then return 1 end
end

sgs.ai_card_intention.qhfirekuangfengCARD = 80

--大雾
sgs.ai_skill_use["@@qhfiredawu"] = function(self, prompt)
	local friends = self.friends
	self:sort(friends, "hp")

	if sgs.ai_skill_use["@@dawu"](self, prompt) ~= "." then
		local str = sgs.ai_skill_use["@@dawu"](self, prompt)
		str = string.gsub(str,"@DawuCard","#qhfiredawuCARD")
		str = string.gsub(str,"=",":")
		str = string.gsub(str,"->",":->")
		return str
	end

	for _, friend in ipairs(friends) do
		if friend:getLostHp() > 0 then
			return "#qhfiredawuCARD:" .. self.player:getPile("stars"):first() .. ":->" .. friend:objectName()
		end
	end
	return "."
end
sgs.ai_ajustdamage_to["&qhfiredawu"] = function(self,from,to,card,nature)
	if nature~="T"
	then return -99 end
end
sgs.ai_card_intention.qhfiredawuCARD = -70

--禳星
sgs.ai_skill_invoke.qhfirerangxing = function(self, data) --是否发动技能
	return true                                           --发动
end

--标准版-强化 孙权-制衡
local qhstandardzhihengVS_skill = {}
qhstandardzhihengVS_skill.name = "qhstandardzhiheng"
table.insert(sgs.ai_skills, qhstandardzhihengVS_skill)
qhstandardzhihengVS_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	local maxhp = self.player:getMaxHp()
	local hp = self.player:getHp()
	local MaxHpXin = maxhp / 1.5                  --体力上限除以1.5
	local MaxHpceil = math.ceil(MaxHpXin)
	local HandcardNum = self.player:getHandcardNum() --手牌数
	local Mark = self.player:getMark("@qhstandardzhiheng")
	if HandcardNum < MaxHpceil and HandcardNum < 3 and Mark == 1 then
		return nil                                   --不发动
	end
	local cishu = maxhp - hp + 2                     --计算最大使用次数
	if Mark < cishu then                             --使用次数小于次数
		return sgs.Card_Parse("#qhstandardzhihengCARD:.:") --返回技能卡，子卡在 ai_skill_use_func 中添加
	end
	return nil
end

sgs.ai_skill_use_func["#qhstandardzhihengCARD"] = function(card, use, self) --技能卡的使用函数
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	if sgs.GetConfig("starfire", true) then
		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self:getCardsNum("Nullification") + self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack") + self:getCardsNum("Duel") == 0 then
			local use_zhiheng_cards = {}
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				table.insert(use_zhiheng_cards, c:getEffectiveId())
			end
			for _, e in ipairs(sgs.QList2Table(self.player:getCards("e"))) do
				if not e:isKindOf("Armor") and not e:isKindOf("DefensiveHorse") then
					table.insert(use_zhiheng_cards, e:getEffectiveId())
				end
			end
			if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
				table.insert(use_zhiheng_cards, self.player:getArmor():getEffectiveId())
			end
			use.card = sgs.Card_Parse("#qhstandardzhihengCARD:" .. table.concat(use_zhiheng_cards, "+") .. ":")
			return
		end
	end

	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = self:aiUseCard(zcard, dummy())
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(zcard, dummy())
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = self:aiUseCard(zcard, dummy())
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = self:aiUseCard(card, dummy())
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = self:aiUseCard(card, dummy())
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end

	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then
			table.insert(use_cards,
				unpreferedCards[index])
		end
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("#qhstandardzhihengCARD:" .. table.concat(use_cards, "+") .. ":") --返回技能卡
		return
	end
end

sgs.ai_use_value["qhstandardzhihengCARD"] = 9.1    --使用价值
sgs.ai_use_priority["qhstandardzhihengCARD"] = 2.1 --使用优先值
function sgs.ai_cardneed.qhstandardzhiheng(to,card)
	return not card:isKindOf("Jink")
end
sgs.ai_use_revises.qhstandardzhiheng = function(self,card,use)
	if card:isKindOf("Weapon")
	and not card:isKindOf("Crossbow")
	and self:getSameEquip(card)
	and not self.player:hasUsed("#qhstandardzhihengCARD")
	then return false end
end


--标准版-强化 甘宁-奇袭
local qhstandardqixi_skill = {}
qhstandardqixi_skill.name = "qhstandardqixi"
table.insert(sgs.ai_skills, qhstandardqixi_skill)
qhstandardqixi_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, c in sgs.list(cards) do
		local fs = sgs.Sanguosha:cloneCard("dismantlement")
		fs:setSkillName("qhstandardqixi")
		fs:addSubcard(c)
		if c:isBlack() and fs:isAvailable(self.player) then
			return fs
		end
		fs:deleteLater()
	end
end
sgs.ai_use_revises.qhstandardqixi = function(self,card,use)
	if card:isKindOf("EquipCard")
	and card:isBlack()
	then
		local same = self:getSameEquip(card)
		if same and same:isBlack()
		then return false end
	end
end
function sgs.ai_cardneed.qhstandardqixi(to,card)
	return card:isBlack()
end


--破袭
sgs.ai_skill_playerchosen.qhstandardpoxi = function(self, targets) --选择目标
	local target = self:findPlayerToDiscard("hej", true, true, targets)[1]
	if target then
		return target
	else
		local targetTable = sgs.QList2Table(targets)
		self:sort(targetTable, "handcard") --将所有友方玩家按手牌数从小到大排序
		for _, target2 in ipairs(targetTable) do --对所有目标进行扫描
			if self:isEnemy(target2) and self:doDisCard(target2, "hej") then  --目标是敌方
				return target2
			end
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.qhstandardpoxi = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

sgs.ai_skill_use["@qhstandardpoxi"] = function(self, prompt)                                    --被动技能卡的使用函数                                                                            --加1
	self:updatePlayers()
	local enemies = self.enemies                                                                --获取所有敌方角色
	self:sort(enemies, "hp")                                                                    --将所有敌方角色按体力值从小到大排序
	for _, enemy in ipairs(enemies) do                                                          --对所有敌方角色进行扫描
		if enemy:isKongcheng() and self:canDamage(enemy,self.player,nil) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then                                                             --无手牌
			if self.player:isKongcheng() then
				return ("#qhstandardpoxiCARD:.:->" .. enemy:objectName())                       --格式为 技能卡:发动卡牌:->目标
			else
				local cards = sgs.QList2Table(self.player:getHandcards())
				self:sortByUseValue(cards, true)                         --按使用价值从小到大排列卡牌
				local id = cards[1]:getEffectiveId()
				return ("#qhstandardpoxiCARD:" .. id .. ":->" .. enemy:objectName()) --格式为 技能卡:发动卡牌:->目标
			end
		end
	end
end

--标准版-强化 吕蒙-克己
sgs.ai_skill_invoke.qhstandardkeji = function(self, data) --是否发动技能
	return true                                           --发动
end
sgs.ai_use_revises.qhstandardkeji = function(self,card,use)
	if card:isKindOf("Slash") and not self:hasCrossbowEffect()
	and (#self.enemies>1 or #self.friends>1) and self:getOverflow()>1
	then return false end
end

--标准版-强化 黄盖-苦肉
local qhstandardkurou_skill = {}
qhstandardkurou_skill.name = "qhstandardkurou"
table.insert(sgs.ai_skills, qhstandardkurou_skill)
qhstandardkurou_skill.getTurnUseCard = function(self)                     --考虑使用视为技的可能性
	if self.player:usedTimes("#qhstandardkurouCARD") > 4 then return nil end --使用次数大于4则不用
	if #self.enemies == 0 then return nil end                             --无敌方则不用
	if self.player:getHp() < 3 then return nil end                        --血少则不用
	local canuse_skill = false
	if self.player:getHp() > 3 and self.player:getHandcardNum() < 3 then
		canuse_skill = true
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
				and not self:slashProhibit(slash, enemy) then
				canuse_skill = true
			end
		end
	end
	if canuse_skill then
		return sgs.Card_Parse("#qhstandardkurouCARD:.:") --返回技能卡
	end
end

sgs.ai_skill_use_func["#qhstandardkurouCARD"] = function(card, use, self) --技能卡的使用函数
	use.card = card
	return
end

sgs.ai_use_value["qhstandardkurouCARD"] = 5    --使用价值
sgs.ai_use_priority["qhstandardkurouCARD"] = 8 --使用优先值
sgs.ai_card_priority.qhstandardkurou = function(self,card,v)
	if self.useValue
	and card:isKindOf("Crossbow")
	then return 9 end
end

--标准版-强化 周瑜-英姿
sgs.ai_skill_invoke.qhstandardyingzi = function(self, data) --是否发动技能
	return true                                             --发动
end

--反间
local qhstandardfanjian_skill = {}
qhstandardfanjian_skill.name = "qhstandardfanjian"
table.insert(sgs.ai_skills, qhstandardfanjian_skill)
qhstandardfanjian_skill.getTurnUseCard = function(self)               --考虑使用视为技的可能性
	if self.player:getHandcardNum() < 3 then return nil end           --牌少则不用
	if self.player:hasUsed("#qhstandardfanjianCARD") then return nil end --用过则不用
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)                                  --按使用价值从小到大排列卡牌
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") then                            --不是桃
			local cardid = card:getEffectiveId()
			return sgs.Card_Parse("#qhstandardfanjianCARD:" .. cardid .. ":") --返回技能卡
		end
	end
end

sgs.ai_skill_use_func["#qhstandardfanjianCARD"] = function(card, use, self) --技能卡的使用函数
	local targetTable = self.enemies
	if #targetTable > 0 then
		self:sort(targetTable, "hp") --将目标按体力值从小到大排序
		for _, enemy in ipairs(targetTable) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal,self.player) and self:canDamage(enemy,self.player,nil) then
				use.card = card
				if use.to then          --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
					use.to:append(enemy)
				end
				return
			end
		end
		local target = targetTable[1] --血量最少的敌方为目标
		use.card = card
		if use.to then          --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
			use.to:append(target)
		end
		return
	end
end

sgs.ai_card_intention["qhstandardfanjianCARD"] = 70                                                --仇恨值
sgs.ai_use_value["qhstandardfanjianCARD"] = 6                                                      --使用价值
sgs.ai_use_priority["qhstandardfanjianCARD"] = 4                                                   --使用优先值

sgs.ai_choicemade_filter.cardChosen.qhstandardfanjian = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

--标准版-强化 大乔 国色
local qhstandardguose_skill = {}
qhstandardguose_skill.name = "qhstandardguose"
table.insert(sgs.ai_skills, qhstandardguose_skill)
qhstandardguose_skill.getTurnUseCard = function(self, inclusive) --考虑使用视为技的可能性
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then --木牛流马上的牌加入
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local card

	self:sortByUseValue(cards, true) --按使用价值从小到大排列卡牌

	local has_weapon, has_armor = false, false

	for _, acard in ipairs(cards) do
		if acard:isKindOf("Weapon") and not (acard:getSuit() == sgs.Card_Diamond) then has_weapon = true end
	end

	for _, acard in ipairs(cards) do
		if acard:isKindOf("Armor") and not (acard:getSuit() == sgs.Card_Diamond) then has_armor = true end
	end

	for _, acard in ipairs(cards) do
		if (acard:getSuit() == sgs.Card_Diamond) and ((self:getUseValue(acard) < sgs.ai_use_value.QhstandardIndulgence) or inclusive) then
			local shouldUse = true

			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then
					shouldUse = false
				elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0 then
					shouldUse = false
				end
			end

			if acard:isKindOf("Weapon") then
				if not self.player:getWeapon() then
					shouldUse = false
				elseif self.player:hasEquip(acard) and not has_weapon then
					shouldUse = false
				end
			end

			if shouldUse then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("qhstandard_indulgence:qhstandardguose[diamond:%s]=%d"):format(number, card_id)
	local indulgence = sgs.Card_Parse(card_str)
	assert(indulgence)
	return indulgence
end

function sgs.ai_cardneed.qhstandardguose(to, card, self)
	--在分牌时，自己 to 的友方玩家 self 先将自己需要的卡牌 card 交给自己
	return card:getSuit() == sgs.Card_Diamond
end

sgs.qhstandardguose_suit_value = { --花色保留值
	diamond = 4.3
}

sgs.ai_skill_invoke.qhstandardguose = function(self, data) --是否发动技能
	return true                                            --发动
end

--流离
sgs.ai_skill_use["@qhstandardliuli"] = function(self, prompt, method) --被动技能卡的使用函数
	local canChoicefrom = false                                       --低血可以选使用者
	if self.player:getHp() <= 2 then
		canChoicefrom = true
	end
	local others = self.room:getOtherPlayers(self.player)
	local slash = sgs.Card_Parse(self.player:property("qhstandardliuli"):toString())
	others = sgs.QList2Table(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("qhstandardLiuliSlashSource") then
			source = player
			break
		end
	end
	if not source then return "." end     --不发动
	local enemies = self.enemies
	self:sort(enemies, "defense")         --按防御值从小到大排序
	local doLiuli = function(who)         --选牌函数
		local cards = self.player:getCards("h") --手牌
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)       --按保留值从小到大排列卡牌
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and
				self.player:distanceTo(who, -1) <= self.player:getAttackRange() then
				return ("#qhstandardliuliCARD:%d:->%s"):format(card:getEffectiveId(), who:objectName()) --格式为 技能卡:发动卡牌:->目标
			end
		end
		cards = self.player:getCards("e") --装备
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards) --按保留值从小到大排列卡牌
		for _, card in ipairs(cards) do
			local range_fix = -1
			if card:isKindOf("Weapon") then
				range_fix = range_fix + sgs.weapon_range[card:getClassName()] - 1
			end
			if card:isKindOf("OffensiveHorse") then
				range_fix = range_fix + 1
			end
			if not self.player:isCardLimited(card, method) and
				self.player:distanceTo(who, range_fix) <= self.player:getAttackRange() then
				return ("#qhstandardliuliCARD:%d:->%s"):format(card:getEffectiveId(), who:objectName()) --格式为 技能卡:发动卡牌:->目标
			end
		end
		return "."
	end
	for _, enemy in ipairs(enemies) do
		if source:objectName() ~= enemy:objectName() then
			if source:canSlash(enemy, slash, false) then
				local ret = doLiuli(enemy)
				if ret ~= "." then return ret end
			end
		elseif canChoicefrom and source:objectName() == enemy:objectName() then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end
	local cards = self.player:getCards("h") --手牌
	for _, card in sgs.qlist(cards) do   --对手牌进行扫描
		if card:isKindOf("Jink") then    --若有闪
			return "."                   --不发动
		end
	end
	self:sort(others, "defense", true) --按防御值从大到小排序
	for _, other in ipairs(others) do
		if (self:isFriend(other) and sgs.getDefense(other) > sgs.getDefense(self.player)) or not self:isFriend(other) then
			if source:objectName() ~= other:objectName() then
				if source:canSlash(other, slash, false) then
					local ret = doLiuli(other)
					if ret ~= "." then return ret end
				end
			elseif canChoicefrom and source:objectName() == other:objectName() then
				local ret = doLiuli(other)
				if ret ~= "." then return ret end
			end
		end
	end
	return "." --不发动
end

function sgs.ai_slash_prohibit.qhstandardliuli(self, from, to, card) --返回 true 表明在策略上不宜对 to 使用【杀】 card
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:isNude() then return false end
	for _, friend in ipairs(self:getFriends(from, true)) do
		if to:distanceTo(friend, -1) <= to:getAttackRange() and self:slashIsEffective(card, friend, from) then return true end
	end
end

function sgs.ai_cardneed.qhstandardliuli(to, card, self)
	--在分牌时，自己 to 的友方玩家 self 先将自己需要的卡牌 card 交给自己
	return to:getCards("he"):length() <= 2
end


sgs.ai_nullification.qhstandard_indulgence = function(self,trick,from,to,positive,null_num)
	if positive then
		if self:isFriend(to)
		and not(self:hasGuanxingEffect(to) or to:isSkipped(sgs.Player_Play))
		then--无观星友方判定区有乐不思蜀->视“突袭”、“巧变”情形而定
			if to:getHp()-to:getHandcardNum()>=2
			or to:getHp()>2 and to:hasSkill("tuxi")
			or null_num<2 and self:getOverflow(to)<-1
			or not to:isKongcheng() and to:hasSkill("qiaobian")
			and (to:containsTrick("supply_shortage") or self:willSkipDrawPhase(to))
			then else return true end
		end
	else
		
	end
end


--标准版-强化 陆逊-连营
sgs.ai_skill_invoke.qhstandardlianying = function(self, data) --是否发动技能
	return true                                               --发动
end

sgs.ai_skill_discard.qhstandardlianying = function(self) --弃牌选择
	local to_discard = {}
	local cards = self.player:getCards("h")
	if cards:length() > 5 then
		return to_discard --不弃牌
	end
	cards = sgs.QList2Table(cards)
	for _, card in ipairs(cards) do
		if self:getKeepValue(card) < 3.5 then
			table.insert(to_discard, card:getEffectiveId())
			table.removeOne(cards, card)
		end
	end
	if #cards - #to_discard == 2 then                 --弃完剩2张
		self:sortByKeepValue(cards)                   --按保留值从小到大排列卡牌
		table.insert(to_discard, cards[1]:getEffectiveId()) --多弃1张
	end

	if #cards - #to_discard >= 3 then --弃完剩3张以上
		return {}                  --不弃牌
	end
	return to_discard
end

sgs.ai_getLeastHandcardNum_skill.qhstandardlianying = function(self, player, least)
	if least < 2 then
		return 2
	end
end

--标准版-强化 孙尚香-结姻
local qhstandardjieyin_skill = {}
qhstandardjieyin_skill.name = "qhstandardjieyin"
table.insert(sgs.ai_skills, qhstandardjieyin_skill)
qhstandardjieyin_skill.getTurnUseCard = function(self)                                        --考虑使用视为技的可能性
	if self.player:getHandcardNum() + self.player:getCards("e"):length() < 2 then return nil end --牌少则不用
	if self.player:hasUsed("#qhstandardjieyinCARD") then return nil end                       --使用过技能卡则不用
	local cards = sgs.QList2Table(self.player:getHandcards())                                 --获取手牌
	local Equip = sgs.QList2Table(self.player:getCards("e"))                                  --获取装备牌
	local cardid
	self:sortByUseValue(cards, true)                                                          --按使用价值从小到大排列卡牌
	if self.player:hasSkill("qhstandardxiaoji") then                                          --枭姬
		if #Equip >= 2 then
			self:sortByUseValue(Equip, true)                                                  --按使用价值从小到大排列卡牌
			cardid = Equip[1]:getEffectiveId() .. "+" .. Equip[2]:getEffectiveId()
		end
		if #Equip == 1 then
			cardid = Equip[1]:getEffectiveId() .. "+" .. cards[1]:getEffectiveId()
		end
		if #Equip == 0 then
			cardid = cards[1]:getEffectiveId() .. "+" .. cards[2]:getEffectiveId()
		end
	else
		cardid = cards[1]:getEffectiveId() .. "+" .. cards[2]:getEffectiveId()
	end
	return sgs.Card_Parse("#qhstandardjieyinCARD:" .. cardid .. ":") --返回技能卡
end

sgs.ai_skill_use_func["#qhstandardjieyinCARD"] = function(card, use, self) --技能卡的使用函数
	local friends = self.friends                                           --获取所有友方角色
	local targets = {}
	for _, friend in ipairs(friends) do                                    --对所有友方角色进行扫描
		if friend:isWounded() then                                         --若受伤
			table.insert(targets, friend)                                  --加入目标table
		end
	end
	self:sort(targets, "hp") --将受伤的所有友方玩家按体力值从小到大排序
	if #targets > 0 then    --有可发动目标
		local target = targets[1] --血量最少的友方为目标
		use.card = card
		if use.to then      --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
			use.to:append(target)
		end
		return
	end
end

sgs.ai_use_value["qhstandardjieyinCARD"] = 7         --使用价值
sgs.ai_use_priority["qhstandardjieyinCARD"] = 2      --使用优先值
sgs.ai_card_intention["qhstandardjieyinCARD"] = -100 --仇恨值
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|qhstandardjieyin"
--枭姬
sgs.ai_skill_invoke.qhstandardxiaoji = function(self, data) --是否发动技能
	return true                                             --发动
end
sgs.ai_use_revises.qhstandardxiaoji = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end

sgs.qhstandardxiaoji_keep_value = {
	--保留值
	Peach = 6,
	Jink = 5.1,
	Weapon = 5.3,
	Armor = 5.5,
	OffensiveHorse = 5.3,
	DefensiveHorse = 5.3
}

sgs.ai_cardneed.qhstandardxiaoji = sgs.ai_cardneed.equip --分牌
sgs.lose_equip_skill = sgs.lose_equip_skill .. "|qhstandardxiaoji"
--风包-强化 小乔-红颜
sgs.qhwindhongyan_suit_value = { --花色保留值
	heart = 7,
}
sgs.ai_ajustdamage_from.qhwindhongyan = function(self, from, to, card, nature)
	if card and card:getSuit() == sgs.Card_Heart then
		return 1
	end
end
function sgs.ai_cardneed.qhwindhongyan(to,card,self)
	return (card:getSuit()==sgs.Card_Heart)
	and (getKnownCard(to,self.player,"heart",false))<2
end
--天香
sgs.ai_skill_use["@qhwindtianxiang"] = function(self, prompt, method) --被动技能卡的使用函数
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card_id
	for _, card in ipairs(cards) do
		if not self.player:isCardLimited(card, method) then
			if card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade then
				card_id = card:getId()
				break
			end
		end
	end
	if not card_id then return "." end
	self:sort(self.enemies, "hp")
	if #self.enemies > 0 then
		local enemy = self.enemies[1]                                         --血量最少的敌方为目标
		return ("#qhwindtianxiangCARD:%d:->%s"):format(card_id, enemy:objectName()) --格式为 技能卡:发动卡牌:->目标
	else
		local others = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(others, "hp", true)                                              --血量最多的非敌方为目标
		if #others > 0 then
			return ("#qhwindtianxiangCARD:%d:->%s"):format(card_id, others[1]:objectName()) --格式为 技能卡:发动卡牌:->目标
		end
	end
end

sgs.ai_can_damagehp.qhwindtianxiang = function(self,from,card,to)
	local d = {damage=1}
	d.nature = card and sgs.card_damage_nature[card:getClassName()] or sgs.DamageStruct_Normal
	return sgs.ai_skill_use["@qhwindtianxiang"](self,d,sgs.Card_MethodDiscard)~="."
end
sgs.qhwindtianxiang_suit_value = {
	--花色保留值
	heart = 6,
	spade = 6
}
function sgs.ai_slash_prohibit.qhwindtianxiang(self,from,to)
	if hasJueqingEffect(from,to) or (from:hasSkill("nosqianxi") and from:distanceTo(to)==1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if self:isFriend(to,from) then return false end
	return self:cantbeHurt(to,from)
end
function sgs.ai_cardneed.qhwindtianxiang(to,card,self)
	return (card:getSuit()==sgs.Card_Heart or (card:getSuit()==sgs.Card_Spade))
	and (getKnownCard(to,self.player,"heart",false)+getKnownCard(to,self.player,"spade",false))<2
end
sgs.ai_card_intention["qhwindtianxiangCARD"] = function(self,card,from,tos)
	local to = tos[1]
	if self:needToLoseHp(to) then return end
	local intention = 10
	if hasBuquEffect(to) then intention = 0
	elseif (to:getHp()>=2 and to:hasSkills("yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu"))
		or (to:getHandcardNum()<3 and (to:hasSkill("nosrende") or (to:hasSkill("rende") and not to:hasUsed("RendeCard")))) then
		intention = 0
	end
	sgs.updateIntention(from,to,intention)
end

sgs.ai_hasBuquEffect_skill.qhwindbuqu = function(player)
	return player:getPile("qhwindbuqu"):length() <= 4
end
--风包-强化 周泰-奋激
sgs.ai_skill_invoke.qhwindfenji = function(self, data) --是否发动技能
	return true                                        --发动
end

sgs.ai_skill_playerchosen.qhwindfenji = function(self, targets) --选择目标
	if self:findPlayerToDiscard("he", true, true, targets)[1] then
		return self:findPlayerToDiscard("he", true, true, targets)[1]
	end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in sgs.list(targets) do
		if (self:doDisCard(p, "he")) and self.player:canDiscard(p, "he") then
			return p
		end
	end
	return nil                                         --返回 nil 表示不发动
end

sgs.ai_choicemade_filter.cardChosen.qhwindfenji = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

--风包-强化 神吕蒙-涉猎
sgs.ai_skill_invoke.qhwindshelie = function(self, data) --是否发动技能
	return true                                         --发动
end

--攻心
local qhwindgongxin_skill = {}
qhwindgongxin_skill.name = "qhwindgongxin"
table.insert(sgs.ai_skills, qhwindgongxin_skill)
qhwindgongxin_skill.getTurnUseCard = function(self)               --考虑使用视为技的可能性
	if self.player:hasUsed("#qhwindgongxinCARD") then return nil end --使用过技能卡则不用
	return sgs.Card_Parse("#qhwindgongxinCARD:.:")                --返回技能卡
end

sgs.ai_skill_use_func["#qhwindgongxinCARD"] = function(card, use, self) --技能卡的使用函数
	local targets = self.room:getOtherPlayers(self.player)
	local target = self:findPlayerToDiscard("hej", true, true, targets)[1]
	if target then
		use.card = card
		if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
			use.to:append(target)
		end
		return
	end
end

sgs.ai_skill_cardchosen.qhwindgongxin = function(self, who, flags) --卡牌选择
	if self:isFriend(who) then                                     --友方
		if not who:containsTrick("YanxiaoCard") and not (who:hasSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					lightning = trick:getId()
				elseif trick:isKindOf("Indulgence") then
					indulgence = trick:getId()
				elseif not trick:isKindOf("Disaster") then
					supply_shortage = trick:getId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end
	else
		local dangerous = self:getDangerousCard(who)
		if dangerous then --优先弃危险牌
			return dangerous
		end
		local cards = who:getCards("he")
		cards = sgs.QList2Table(cards)
		if #cards > 0 then
			self:sortByUseValue(cards) --按使用价值从大到小排列卡牌
			return cards[1]:getEffectiveId()
		end
	end
end

sgs.ai_use_value["qhwindgongxinCARD"] = 7    --使用价值
sgs.ai_use_priority["qhwindgongxinCARD"] = 9 --使用优先值

--火包-强化 太史慈-天义
local qhfiretianyi_skill = {}
qhfiretianyi_skill.name = "qhfiretianyi"
table.insert(sgs.ai_skills, qhfiretianyi_skill)
qhfiretianyi_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self:needBear() then return end
	if not self.player:hasUsed("#qhfiretianyiCARD") then
		local mcard
		local num = 0
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if not card:isKindOf("Peach") and card:getNumber() > num then
				num = card:getNumber()
				mcard = card
			end
		end
		if mcard then
			return sgs.Card_Parse("#qhfiretianyiCARD:" .. mcard:getEffectiveId() .. ":")
		end
	end
	if self.player:getMark("qhfiretianyi_slash-Clear") == 1 then
		local card_str = ("slash:qhfiretianyi[%s:%s]=."):format("no_suit", 0) --无子卡虚拟火攻
		local acard = sgs.Card_Parse(card_str)
		return acard
	end
end

sgs.ai_skill_use_func["#qhfiretianyiCARD"] = function(card, use, self)
	local enemies = self.enemies --获取所有敌方角色
	if #enemies > 0 then
		self:sort(enemies, "handcard") ----将所有敌方玩家按手牌数从小到大排序
		for _, enemy in sgs.list(self.enemies) do
			if self.player:canPindian(enemy) then
				use.card = card
				if use.to then --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
					use.to:append(enemies[1])
				end
				return
			end
		end
	end
end

sgs.ai_cardneed["qhfiretianyi"] = sgs.ai_cardneed.bignumber
sgs.ai_use_value["qhfiretianyiCARD"] = 9      --使用价值
sgs.ai_use_priority["qhfiretianyiCARD"] = 9.8 --使用优先值

sgs.ai_use_revises.qhfiretianyi = function(self,card,use)
	if card:isKindOf("Slash") and self.player:getMark("qhfiretianyi_success-Clear") == 1
	then card:setFlags("Qinggang") end
end
--酣战
sgs.ai_skill_invoke.qhfirehanzhan = function(self, data) --是否发动技能
	return true                                          --发动
end

--神周瑜-业炎
sgs.ai_skill_playerschosen.qhfireyeyan = function(self, targets, max_num, min_num) --选择多目标
	targets = sgs.QList2Table(targets)                                             -- 将列表转换为表
	self:sort(targets, "hp")                                                       --按体力值从小到大排序
	local tos = {}
	local n = 0
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not self:cantbeHurt(target) and self:canDamage(target,self.player,nil) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
			table.insert(tos, target)
			n = n + 1
		end
		if n == 2 or n == max_num then
			break
		end
	end
	return tos
end

--琴音
sgs.ai_skill_invoke.qhfireqinyin = function(self, data) --是否发动技能
	return true                                         --发动
end

sgs.ai_skill_choice.qhfireqinyin = function(self, choices, data) --进行选择
	if self.player:getLostHp() >= 2 then
		return "recover"
	end
	return "lose"
end

sgs.ai_skill_playerchosen.qhfireqinyin = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "hp")                                 --将目标按体力值从小到大排序
	local choice = self.player:property("qhfireqinyin-AI"):toString()
	for _, target in ipairs(targetTable) do                      --对所有目标进行扫描
		if self:isEnemy(target) and choice == "recover" then
			return target
		end
		if self:isFriend(target) and choice == "lose" then
			return target
		end
	end
end

--薪火
sgs.ai_skill_invoke.qhfirexinhuo = function(self, data) --是否发动技能
	return true                                         --发动
end

sgs.ai_cardshow.qhfirexinhuo = function(self, requestor)
	local suitrRecord = self.player:getTag("qhfirexinhuo"):toString():split("+")
	local hcards = self.player:getHandcards()
	for _, hcard in sgs.qlist(hcards) do
		local suit = hcard:getSuitString()
		if not table.contains(suitrRecord, suit) then
			return hcard
		end
	end
	return self.player:getRandomHandCard()
end

--标准版-强化 华佗-青囊
local qhstandardqingnang_skill = {}
qhstandardqingnang_skill.name = "qhstandardqingnang"
table.insert(sgs.ai_skills, qhstandardqingnang_skill)
qhstandardqingnang_skill.getTurnUseCard = function(self)               --考虑使用视为技的可能性
	if self.player:getHandcardNum() < 1 then return nil end            --牌少则不用
	if self.player:hasUsed("#qhstandardqingnangCARD") then return nil end --使用过技能卡则不用
	local cards = sgs.QList2Table(self.player:getHandcards())          --获取手牌
	local compare_func = function(a, b)                                --获得一张卡牌的保留值+[为红色+50]+[为桃+50]
		local v1 = self:getKeepValue(a) + (a:isRed() and 50 or 0) + (a:isKindOf("Peach") and 50 or 0)
		local v2 = self:getKeepValue(b) + (b:isRed() and 50 or 0) + (b:isKindOf("Peach") and 50 or 0)
		return v1 < v2
	end
	table.sort(cards, compare_func)                                 --排序
	local cardid = cards[1]:getEffectiveId()
	return sgs.Card_Parse("#qhstandardqingnangCARD:" .. cardid .. ":") --返回技能卡
end

sgs.ai_skill_use_func["#qhstandardqingnangCARD"] = function(card, use, self) --技能卡的使用函数
	local friends = self.friends                                             --获取所有友方角色
	local targets = {}
	for _, friend in ipairs(friends) do                                      --对所有友方角色进行扫描
		if friend:isWounded() then                                           --若受伤
			table.insert(targets, friend)                                    --加入目标table
		end
	end
	self:sort(targets, "hp") --将受伤的所有友方玩家按体力值从小到大排序
	if #targets > 0 then    --有可发动目标
		local target = targets[1] --血量最少的友方为目标
		use.card = card
		if use.to then      --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
			use.to:append(target)
		end
		return
	end
end

sgs.ai_use_value["qhstandardqingnangCARD"] = 7         --使用价值
sgs.ai_use_priority["qhstandardqingnangCARD"] = 2      --使用优先值
sgs.ai_card_intention["qhstandardqingnangCARD"] = -100 --仇恨值
sgs.ai_use_revises.qhstandardqingnang = function(self,card,use)
	if card:isKindOf("Slash") and self:isWeak()
	and self:getOverflow()<=0
	then return false end
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|qhstandardqingnang"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|qhstandardqingnang"
--急救
sgs.ai_view_as.qhstandardjijiu = function(card, player, card_place) --重写视为技
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() then --红色
		return ("peach:qhstandardjijiu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value.qhstandardjijiu = 7
sgs.ai_use_priority.qhstandardjijiu = 1.5
sgs.qhstandardjijiu_suit_value = {
	--花色保留值
	heart = 6,
	diamond = 6
}

function sgs.ai_cardneed.qhstandardjijiu(to, card, self)
	--在分牌时，自己 to 的友方玩家 self 先将自己需要的卡牌 card 交给自己
	return to:getHandcardNum() < 3 and card:isRed()
end
sgs.ai_use_revises.qhstandardjijiu = function(self,card,use)
	if card:isKindOf("EquipCard")
	and card:isRed()
	then
		local same = self:getSameEquip(card)
		if same and same:isRed()
		then return false end
	end
end
sgs.save_skill = sgs.save_skill .. "|qhstandardjijiu"

--仁心
local qhstandardrenxinVS_skill = {}
qhstandardrenxinVS_skill.name = "qhstandardrenxin"
table.insert(sgs.ai_skills, qhstandardrenxinVS_skill)
qhstandardrenxinVS_skill.getTurnUseCard = function(self)             --考虑使用视为技的可能性
	if self.player:hasUsed("#qhstandardrenxinCARD") then return nil end --使用过技能卡则不用
	if self.player:getMark("@qhstandardrenxin") < 2 then return nil end --小于2则不用
	return sgs.Card_Parse("#qhstandardrenxinCARD:.:")                --返回技能卡
end

sgs.ai_skill_use_func["#qhstandardrenxinCARD"] = function(card, use, self) --技能卡的使用函数(同青囊)
	local friends = self.friends                                           --获取所有友方角色
	local targets = {}
	for _, friend in ipairs(friends) do                                    --对所有友方角色进行扫描
		if friend:isWounded() then                                         --若受伤
			table.insert(targets, friend)                                  --加入目标table
		end
	end
	self:sort(targets, "value") --将受伤的所有友方玩家按综合值从小到大排序
	if #targets > 0 then     --有可发动目标
		local target = targets[1] --综合值最小的友方为目标
		use.card = card
		if use.to then       --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
			use.to:append(target)
		end
		return
	end
end

sgs.ai_use_value["qhstandardrenxinCARD"] = 3         --使用价值
sgs.ai_use_priority["qhstandardrenxinCARD"] = 1      --使用优先值
sgs.ai_card_intention["qhstandardrenxinCARD"] = -100 --仇恨值
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|qhstandardrenxin"
--标准版-强化 吕布-无双
sgs.ai_skill_cardask["#askForqhstandardWushuang-1"] = function(self, data, pattern, target) --询问使用或打出一张卡牌
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if self:getCardsNum("Slash") < 2 and not (self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng)) then
		return "."
	end
end

sgs.ai_skill_cardask["#qhstandardWushuang-discard"] = function(self, data) --询问使用或打出一张卡牌
	local target = data:toPlayer()
	if self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then return "." end
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Slash") then
			return card:getEffectiveId()
		end
	end
	return "."
end
sgs.hit_skill = sgs.hit_skill .. "|qhstandardWushuang"

function sgs.ai_slash_prohibit.qhstandardWushuang(self, from, to) --不宜用杀
	if self:isFriend(to, from) then return false end
	local slash_num
	if from:objectName() == self.player:objectName() then
		slash_num = self:getCardsNum("Slash")
	else
		slash_num = getCardsNum("Slash", from, self.player)
	end
	return slash_num < 2
end
sgs.ai_target_revises.qhstandardWushuang = function(to,card,self,use)
	if card:isKindOf("Slash")
	and self:getCardsNum("Slash")<2
	then return true end
end


--标准版-强化 貂蝉-离间
local qhstandardLijian_skill = {}
qhstandardLijian_skill.name = "qhstandardLijian"
table.insert(sgs.ai_skills, qhstandardLijian_skill)
qhstandardLijian_skill.getTurnUseCard = function(self)                        --考虑使用视为技的可能性
	if self.player:hasUsed("#qhstandardLijianCARD") or self.player:isNude() then --没使用技能 有牌
		return nil
	end
	local cardid = self:getLijianCard()
	if cardid then
		return sgs.Card_Parse("#qhstandardLijianCARD:" .. cardid .. ":") --返回技能卡
	end
end

function SmartAI:findqhLijianTarget(card_name, use) --删除了部分判断
	local lord = self.room:getLord()
	local duel = sgs.Sanguosha:cloneCard("duel")

	local findFriend_maxSlash = function(self, first)
		self:log("Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng, fazheng
		for _, friend in ipairs(self.friends) do
			if self:hasTrickEffective(duel, first, friend) then
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
			elseif (getCardsNum("Slash", friend_maxSlash) >= getCardsNum("Slash", first)) then
				safe = true
			end
			if safe then return friend_maxSlash end
		else
			self:log("unfound")
		end
		if nos_fazheng or fazheng then return nos_fazheng or fazheng end --备用友方，各种恶心的法正
		return nil
	end

	if self.role == "rebel" or (self.role == "renegade" and sgs.playerRoles["loyalist"]  + 1 > sgs.playerRoles["rebel"]) then
		if lord and not lord:isNude() and lord:objectName() ~= self.player:objectName() then -- 优先离间1血忠和主
			self:sort(self.enemies, "handcard")
			local e_peaches = 0
			local loyalist

			for _, enemy in ipairs(self.enemies) do
				e_peaches = e_peaches + getCardsNum("Peach", enemy)
				if enemy:getHp() == 1 and self:hasTrickEffective(duel, enemy, lord) and enemy:objectName() ~= lord:objectName()
					and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches < 1 then return loyalist, lord end
		end

		if #self.friends >= 2 and self:getAllPeachNum() < 1 then --收友方反
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

				for _, a_friend in ipairs(self.friends_noself) do -- 目标1：寻找1血友方
					if a_friend:getHp() == 1 and a_friend:isKongcheng() and not self:hasSkills("kongcheng|yuwen", a_friend) then
						for _, b_friend in ipairs(self.friends) do --目标2：寻找位于我之后，离我最近的友方
							if b_friend:objectName() ~= a_friend:objectName() and self:playerGetRound(b_friend) < round
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
			for _, ap in sgs.qlist(self.room:getAllPlayers()) do
				if ap:objectName() ~= lord:objectName() and self:hasTrickEffective(duel, lord, ap) then
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
	if shenguanyu and shenguanyu:objectName() ~= self.player:objectName() then
		if self.role == "rebel" and lord and lord:objectName() ~= self.player:objectName() and not lord:hasSkill("jueqing") and self:hasTrickEffective(duel, shenguanyu, lord) then
			return shenguanyu, lord
		elseif self:isEnemy(shenguanyu) and #self.enemies >= 2 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:objectName() ~= shenguanyu:objectName() and not enemy:isLocked(duel)
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
			if not enemy:hasSkills("wuyan|noswuyan") then
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
					zhugeliang_kongcheng = enemy
				elseif enemy:hasSkill("jieming") then
					xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:objectName() ~= enemy:objectName() then
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
			if lord and self:isFriend(lord) and lord:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel, males[1], lord)
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
				local p_slash, max_p, max_pp = 0, 0, 0
				for _, p in sgs.qlist(self.room:getAllPlayers()) do
					if not self:isFriend(p) and p:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel, males[1], p) and not p:isLocked(duel)
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
						local x = enemy:getMaxHp() > enemy:getHandcardNum() and
							math.min(5, enemy:getMaxHp() - enemy:getHandcardNum()) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, xunyu)
					end
				end
			end
		end

		if #males == 1 and #self.friends > 0 then
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
				elseif not self:hasSkills("wuyan|noswuyan", lord) then
					if self.role == "rebel" and not first:isLord() and self:hasTrickEffective(duel, first, lord) then
						second = lord
					else
						if ((self.role == "loyalist" or self.role == "renegade") and not self:hasSkills("ganglie|enyuan|neoganglie|nosenyuan", first))
							and (getCardsNum("Slash", first) <= getCardsNum("Slash", second)) then
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

sgs.ai_skill_use_func["#qhstandardLijianCARD"] = function(card, use, self) --技能卡的使用函数
	local first, second = self:findqhLijianTarget("#qhstandardLijianCARD", use)
	if first and second then
		use.card = card
		if use.to then
			use.to:append(first)
			use.to:append(second)
		end
	end
end

sgs.ai_use_value["qhstandardLijianCARD"] = 8.5  --使用价值
sgs.ai_use_priority["qhstandardLijianCARD"] = 4 --使用优先值
qhstandardLijian_filter = function(self,player,carduse)
	if carduse.card:isKindOf("qhstandardLijianCARD") then
		sgs.ZenhuiEffect = true
	end
end

table.insert(sgs.ai_choicemade_filter.cardUsed,qhstandardLijian_filter)
--闭月
sgs.ai_skill_invoke.qhstandardBiyue = function(self, data) --是否发动技能
	return true                                            --发动
end
sgs.ai_cardneed.qhstandardyaowu = sgs.ai_cardneed.slash

--公孙瓒-趫猛
sgs.ai_skill_invoke.qhstandardqiaomeng = function(self, data) --是否发动技能
	local player = data:toPlayer()
	if self:isEnemy(player) then
		return self:doDisCard(player, "hej") --发动
	end
end

sgs.ai_cardneed.qhstandardqiaomeng = sgs.ai_cardneed.slash
--风包-强化 张角-雷击
sgs.ai_skill_playerchosen.qhwindleiji = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "hp")                                --将目标按体力值从小到大排序
	for _, target in ipairs(targetTable) do                     --对所有目标进行扫描
		if self:isEnemy(target) and self:damageIsEffective(target,sgs.DamageStruct_Thunder,self.player) then                            --目标是敌方
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["qhwindleiji"] = 80                --仇恨值

function sgs.ai_slash_prohibit.qhwindleiji(self, from, to, card) --返回 true 表明在策略上不宜对 to 使用【杀】 card
	if self:isFriend(to) then return false end
	if to:getMark("@qhwindGuibing") >= 1 then return false end
	if getCardsNum("Jink", to, self.player) > 0 then return true end
	local hcard = to:getHandcardNum()
	if getKnownCard(to, self.player, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 3) or hcard >= 4 then return true end
end

--鬼道
sgs.ai_skill_cardask["#askforqhwindguidao"] = function(self, data) --询问使用或打出一张卡牌
	local judge = data:toJudge()
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end
function sgs.ai_cardneed.qhwindleiji(to,card,self)
	for _,p in sgs.qlist(self.room:getAllPlayers())do
		if self:getFinalRetrial(to)==1 then
			if p:containsTrick("lightning") and not p:containsTrick("YanxiaoCard") then
				return card:getSuit()==sgs.Card_Spade and card:getNumber()>=2 and card:getNumber()<=9 and not self:hasSkills("hongyan|olhongyan|wuyan")
			end
			if self:isFriend(p) and self:willSkipDrawPhase(p) then
				return card:getSuit()==sgs.Card_Club and self:hasSuit("club",true,to)
			end
		end
	end
	if self:getFinalRetrial(to)==1 then
		if to:hasSkills("qhwindleiji") then
			return card:isBlack()
		end
	end
end

--鬼兵
local qhwindGuibing_skill = {}
qhwindGuibing_skill.name = "qhwindGuibing"
table.insert(sgs.ai_skills, qhwindGuibing_skill)
qhwindGuibing_skill.getTurnUseCard = function(self)               --考虑使用视为技的可能性
	if self.player:hasUsed("#qhwindGuibingCARD") then return nil end --使用过技能卡则不用
	local cardid
	local handcards = sgs.QList2Table(self.player:getHandcards()) --获取手牌
	self:sortByUseValue(handcards, true)                          --按使用价值从小到大排列卡牌
	for _, card in ipairs(handcards) do
		if card:isKindOf("Jink") then                             --是闪
			cardid = card:getId()
			break
		end
	end
	if cardid then
		return sgs.Card_Parse("#qhwindGuibingCARD:" .. cardid .. ":") --返回技能卡
	end
end

sgs.ai_skill_use_func["#qhwindGuibingCARD"] = function(card, use, self) --技能卡的使用函数
	use.card = card
	return
end

sgs.ai_use_value["qhwindGuibingCARD"] = 9    --使用价值
sgs.ai_use_priority["qhwindGuibingCARD"] = 6 --使用优先值


sgs.ai_skill_invoke.qhwindGuibing = function(self, data) --是否发动技能
	return true                                          --发动
end

--黄天
local qhwindhuangtianVS_skill = {}
qhwindhuangtianVS_skill.name = "qhwindhuangtianvs"
table.insert(sgs.ai_skills, qhwindhuangtianVS_skill)
qhwindhuangtianVS_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:hasUsed("#qhwindhuangtianVSCARD") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true) --按使用价值从小到大排列卡牌
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Jink") then
			card = acard
			break
		end
	end
	if not card then return nil end
	local card_id = card:getEffectiveId()
	local card_str = "#qhwindhuangtianVSCARD:" .. card_id .. ":"
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard --返回技能卡
end

sgs.ai_skill_use_func["#qhwindhuangtianVSCARD"] = function(card, use, self) --技能卡的使用函数
	if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
		return "."
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("qhwindhuangtian") then
			table.insert(targets, friend)
		end
	end
	if #targets > 0 then
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	end
end

--于吉 蛊惑
sgs.ai_cardsview_valuable.qhwindguhuo = function(self, class_name, player) --多类型响应
	--响应时机
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and
		sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		return
	end
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
		["Analeptic"] = "analeptic",
		["Nullification"] = "nullification",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name] --转化名称
	local cards = player:getCards("h")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	if cards:isEmpty() then return end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			return --有牌就不用
		end
	end
	local qhwindguhuoused = player:property("qhwindguhuoused"):toString():split("+") --获取属性
	if not table.contains(qhwindguhuoused, name) then
		cards = sgs.QList2Table(cards)
		if #cards == 0 then return end
		self:sortByUseValue(cards, true)
		local suit = cards[1]:getSuitString()
		local number = cards[1]:getNumberString()
		local card_id = cards[1]:getEffectiveId()
		if player:hasSkill("qhwindguhuo") then
			return ("%s:qhwindguhuo[%s:%s]=%d"):format(name, suit, number, card_id)
		end
	end
end

local qhwindguhuo_skill = {}
qhwindguhuo_skill.name = "qhwindguhuo"
table.insert(sgs.ai_skills, qhwindguhuo_skill)
qhwindguhuo_skill.getTurnUseCard = function(self)                                      --考虑使用视为技的可能性
	if self.player:isKongcheng() or self.player:getMark("qhwindguhuoNum") > 3 then return end
	local qhwindguhuoused = self.player:property("qhwindguhuoused"):toString():split("+") --获取属性
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)                                                   --按使用价值从小到大排列卡牌
	local card = cards[1]
	local suit = card:getSuit()
	local suitString = card:getSuitString()
	local point = card:getNumber()
	local card_id = card:getEffectiveId()
	local usecardTable = { "ex_nihilo", "snatch", "peach", "slash", "archery_attack", "savage_assault", "dismantlement"
	, "fire_attack" } --使用卡牌table
	local usecardName
	for index, value in ipairs(usecardTable) do
		if not table.contains(qhwindguhuoused, value) then
			local usecard = sgs.Sanguosha:cloneCard(value, suit, point)
			usecard:deleteLater()
			if usecard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useTrickCard(usecard, dummy_use)
				if dummy_use.card then
					usecardName = value
					break
				end
			elseif usecard:getTypeId() == sgs.Card_TypeBasic then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(usecard, dummy_use)
				if dummy_use.card then
					usecardName = value
					break
				end
			end
		end
	end
	if usecardName then
		local card_str = ("%s:qhwindguhuo[%s:%d]=%d"):format(usecardName, suitString, point, card_id)
		return sgs.Card_Parse(card_str)
	end
end

--火包-强化 袁绍-乱击
local qhfireluanji_skill = {}
qhfireluanji_skill.name = "qhfireluanji"
table.insert(sgs.ai_skills, qhfireluanji_skill)
qhfireluanji_skill.getTurnUseCard = function(self)
	local archery = sgs.Sanguosha:cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("archery_attack:qhfireluanji[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
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
		local card_str = ("archery_attack:qhfireluanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id,
			second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

sgs.ai_skill_playerschosen.qhfireluanji = function(self, targets, max_num, min_num) --选择多目标
	targets = sgs.QList2Table(targets)                                              -- 将列表转换为表
	self:sort(targets, "defense")                                                   --按防御值从小到大排序
	local tos = {}
	local data = self.player:getTag("qhfireluanji-AI")
	local use = data:toCardUse()
	if use.card:isKindOf("IronChain") then
		return {}
	end
	for _, target in ipairs(targets) do
		if use.card:isDamageCard() then
			if self:isFriend(target) and not self:needToLoseHp(target, self.player, use.card) then
				table.insert(tos, target)
				max_num = max_num - 1
			end
		else
			if self:isEnemy(target) then
				table.insert(tos, target)
				max_num = max_num - 1
			end
		end
		if max_num <= 0 then
			break
		end
	end
	return tos
end

sgs.ai_skill_invoke.qhfireluanji = function(self, data) --是否发动技能
	return true                                         --发动
end
sgs.ai_card_priority.qhfireluanji = function(self,card,v)
	if card:isKindOf("ArcheryAttack")
	then return 6 end
end
sgs.ai_use_revises.qhfireluanji = function(self,card,use)
	if card:isKindOf("AOE") and self.player:getRole()=="lord" and sgs.turncount<2 and math.random()>0.7
	then self.player:addMark("AI_fangjian-Clear") end
end


--火包-强化 颜良文丑-双雄
sgs.ai_skill_invoke.qhfireshuangxiong = function(self, data) --是否发动技能
	return true                                              --发动
end

sgs.ai_view_as.qhfireshuangxiong = function(card, player, card_place) --重写视为技
	if player:getMark("&qhfireshuangxiong_damage-Clear") == 2 then
		return
	end
	local color
	if player:getMark("&qhfireshuangxiong_red-Clear") == 1 then
		color = sgs.Card_Red
	elseif player:getMark("&qhfireshuangxiong_black-Clear") == 1 then
		color = sgs.Card_Black
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:getColor() == color and not card:isEquipped() then
		return ("slash:qhfireshuangxiong[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local qhfireshuangxiong_skill = {}
qhfireshuangxiong_skill.name = "qhfireshuangxiong"
table.insert(sgs.ai_skills, qhfireshuangxiong_skill)
qhfireshuangxiong_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:getMark("&qhfireshuangxiong_damage-Clear") == 2 then
		return
	end
	local color
	if self.player:getMark("&qhfireshuangxiong_red-Clear") == 1 then
		color = sgs.Card_Red
	elseif self.player:getMark("&qhfireshuangxiong_black-Clear") == 1 then
		color = sgs.Card_Black
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true) --按使用价值从小到大排列卡牌
	local use_card
	local use_cardtype
	for _, card in ipairs(cards) do --对卡牌进行扫描
		if card:getColor() ~= color then
			local usecard = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
			usecard:deleteLater()
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(usecard, dummy_use)
			if dummy_use.card then
				use_card = card --决斗
				use_cardtype = "duel"
				break
			end
		end
		if card:getColor() == color then
			local usecard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			usecard:deleteLater()
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useBasicCard(usecard, dummy_use)
			if dummy_use.card then
				use_card = card --杀
				use_cardtype = "slash"
				break
			end
		end
	end
	if use_card then
		local suit = use_card:getSuitString()
		local number = use_card:getNumberString()
		local card_id = use_card:getEffectiveId()
		local card_str = ("%s:qhfireshuangxiong[%s:%s]=%d"):format(use_cardtype, suit, number, card_id)
		local acard = sgs.Card_Parse(card_str)
		return acard
	end
end

sgs.ai_cardneed.qhfireshuangxiong=function(to,card,self)
	return not self:willSkipDrawPhase(to)
end
sgs.ai_card_priority.qhfireshuangxiong = function(self,card,v)
	if self.useValue
	and card:getSkillName()=="qhfireshuangxiong"
	then v = 6 end
end

--火包-强化 庞德-猛进
sgs.ai_skill_invoke.qhfiremengjin = function(self, data) --是否发动技能
	local player = data:toPlayer()
	if self:isEnemy(player) then
		local use = self.player:getTag("qhfiremengjin-AI"):toCardUse()
		if use.card:isKindOf("Slash") then
			return self:doDisCard(player, "he", true) --发动
		end
		if player:getCards("he"):length() <= 1 then
			if use.card:isKindOf("FireAttack") or use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
				return false
			end
		end
		return self:doDisCard(player, "he") --发动
	end
end

sgs.ai_choicemade_filter.cardChosen.qhfiremengjin = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择
sgs.ai_cardneed.qhfiremengjin = sgs.ai_cardneed.slash

--神话降临 黄月英-机巧
sgs.ai_card_priority.mythjizhi = function(self,card,v)
	if self.useValue
	and card:isKindOf("TrickCard")
	then v = v+3 end
end
function sgs.ai_cardneed.mythjizhi(to,card)
	return card:getTypeId()==sgs.Card_TypeTrick
end
local mythjiqiao_skill = {}
mythjiqiao_skill.name = "mythjiqiao"
table.insert(sgs.ai_skills, mythjiqiao_skill)
mythjiqiao_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:hasUsed("#mythjiqiaoCard") then return end
	local usecardTable = { "snatch", "ex_nihilo", "archery_attack", "savage_assault", "dismantlement"
	, "fire_attack" } --使用卡牌table
	for index, value in ipairs(usecardTable) do
		local usecard = sgs.Sanguosha:cloneCard(value)
		usecard:deleteLater()
		local dummy_use = self:aiUseCard(usecard, dummy())
		if dummy_use.card then
			return sgs.Card_Parse("#mythjiqiaoCard:.:" .. value)
		end
	end
end

sgs.ai_skill_use_func["#mythjiqiaoCard"] = function(card, use, self) --技能卡的使用函数
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local usecard = sgs.Sanguosha:cloneCard(userstring)
	local dummy_use = self:aiUseCard(usecard, dummy())
	if dummy_use.card then
		use.card = card
		use.to = dummy_use.to
	end
end

sgs.ai_view_as.mythjiqiao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("TrickCard") then
		return ("nullification:mythjiqiao[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.ai_skill_playerchosen.mythlinglong = function(self, targets) --选择目标
	if self:findPlayerToDiscard("he", true, true, targets)[1] then
		return self:findPlayerToDiscard("he", true, true, targets)[1]
	end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in sgs.list(targets) do
		if (self:doDisCard(p, "he")) and self.player:canDiscard(p, "he") then
			return p
		end
	end
	return nil                                         --返回 nil 表示不发动
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|mythbeifen"

sgs.ai_card_priority.mythbeifen = function(self,card,v)
	if card:hasFlag("mythhujia")
	then v = v+3 end
end

--神话降临 滕公主-幸宠
sgs.ai_skill_discard["mythxingchong"] = function(self, data) --askForExchange 处理
	local handcards = sgs.QList2Table(self.player:getHandcards())
	local maxhp = self.player:getMaxHp()
	local min = math.min(maxhp, #handcards)
	self:sortByKeepValue(handcards) --按保留值从小到大排序
	local cards = {}
	for i = 1, min, 1 do
		table.insert(cards, handcards[i]:getEffectiveId())
	end
	return cards
end
sgs.ai_card_priority.mythxingchong = function(self,card,v)
	if self.player:getMark("mythxingchong_" .. card:getEffectiveId() .. "_lun") == 1 
	then v = v+3 end
end

--神话降临 滕芳兰-落宠
sgs.ai_skill_choice.mythluochong = function(self, choices, data) --进行选择
	local items = choices:split("+")
	if table.contains(items, "discard") then
		local current = self.room:getCurrent()
		if self:isEnemy(current) then
			if current:hasWeapon("crossbow") or current:getHandcardNum() <= 3 then
				return "discard"
			end
		end
	end
	if table.contains(items, "recover") then
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() then
				return "recover"
			end
		end
	end
	if table.contains(items, "lose") then
		if #self.enemies > 0 then
			return "lose"
		end
	end
	if table.contains(items, "draw") then
		return "draw"
	end
	if table.contains(items, "discard") then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canDiscard(enemy, "he") then
				return "discard"
			end
		end
	end
end

sgs.ai_skill_playerchosen.mythluochong = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	local choice = self.player:property("mythluochong_choice"):toString()
	--self.player:speak(choice)
	if choice == "recover" then
		if self.player:isWounded() then
			return self.player
		end
		self:sort(targetTable, "hp")      --将目标按体力值从小到大排序
		for _, target in ipairs(targetTable) do --对所有目标进行扫描
			if self:isFriend(target) then --目标是友方
				return target
			end
		end
	end
	if choice == "lose" then
		self:sort(targetTable, "hp")      --将目标按体力值从小到大排序
		for _, target in ipairs(targetTable) do --对所有目标进行扫描
			if self:isEnemy(target) and not (hasZhaxiangEffect(target) and not self:isWeak(target)) then  --目标是敌方
				return target
			end
		end
	end
	if choice == "discard" then
		return self:findPlayerToDiscard("he", false, true, targets)[1]
	end
	if choice == "delaydiscard" then
		local target = self:findPlayerToDiscard("he", false, true, targets)[1]
		if target then
			return target
		else
			if self.role == "loyalist" and targetTable[1]:isLord() then
				if #targetTable >= 2 then
					return targetTable[2]
				end
			else
				return targetTable[1]
			end
		end
	end
	if choice == "draw" then
		if self.player:getHandcardNum() <= 3 then
			return self.player
		end
		self:sort(targetTable, "value")   --将目标按综合值从小到大排序
		for _, target in ipairs(targetTable) do --对所有目标进行扫描
			if self:isFriend(target) then --目标是友方
				return target
			end
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.mythluochong = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

--神话降临 曹金玉-隅泣
sgs.ai_skill_use["@@mythyuqi"] = function(self, prompt) --被动技能卡的使用函数
	local num = self.player:getMark("mythyuqi_num")
	local list = self.player:property("mythyuqi_AI"):toIntList()
	local pile = {}
	for _, id in sgs.qlist(list) do
		table.insert(pile, sgs.Sanguosha:getCard(id))
	end
	self:sortByKeepValue(pile, true) --按保留值从大到小排列卡牌
	if prompt:startsWith("#mythyuqi1") then
		local target = self.room:findPlayerByObjectName(prompt:split(":")[2])
		if self:isFriend(target) then --受伤是友方
			num = math.min(num, 3, #pile)
			local cards = {}
			for i = 1, num, 1 do
				table.insert(cards, pile[i]:getEffectiveId())
			end
			return ("#mythyuqiCARD:" .. table.concat(cards, "+") .. ":") --格式为 技能卡:发动卡牌:->目标
		end
	else
		num = math.min(num, #pile)
		local cards = {}
		for i = 1, num, 1 do
			table.insert(cards, pile[i]:getEffectiveId())
		end
		return ("#mythyuqiCARD:" .. table.concat(cards, "+") .. ":") --格式为 技能卡:发动卡牌:->目标
	end
end

--娴静
function find_choice(items, choice)
	for _, item in ipairs(items) do
		if item:startsWith(choice) then
			return item
		end
	end
end

sgs.ai_skill_choice.mythxianjing = function(self, choices, data) --进行选择
	local items = choices:split("+")
	local usableTimes, juli, guankan, geipai, huode, maxCard = yuqi_getMark(self.player)
	if huode < 3 then
		return find_choice(items, "huode")
	end
	if guankan < 5 then
		return find_choice(items, "guankan")
	end
	if usableTimes < 3 then
		return find_choice(items, "usableTimes")
	end
	if juli < 3 then
		return find_choice(items, "juli")
	end
	if huode < 5 then
		return find_choice(items, "huode")
	end
	if usableTimes < 5 then
		return find_choice(items, "usableTimes")
	end
end

--善身
local mythshanshen_skill = {}
mythshanshen_skill.name = "mythshanshen"
table.insert(sgs.ai_skills, mythshanshen_skill)
mythshanshen_skill.getTurnUseCard = function(self)               --考虑使用视为技的可能性
	if self.player:getHp() < 3 then return nil end               --血少则不用
	if self.player:hasUsed("#mythshanshenCARD") then return nil end --使用过技能卡则不用
	return sgs.Card_Parse("#mythshanshenCARD:.:")                --返回技能卡
end

sgs.ai_skill_use_func["#mythshanshenCARD"] = function(card, use, self) --技能卡的使用函数
	local enemies = {}
	if self.player:hasSkill("mythyuqi") then
		local usableTimes, juli, guankan, geipai, huode, maxCard = yuqi_getMark(self.player)
		for _, enemy in ipairs(self.enemies) do
			if self.player:distanceTo(enemy) <= juli then
				table.insert(enemies, enemy)
			end
		end
	else
		enemies = self.enemies
	end
	self:sort(enemies, "hp") --将目标按体力值从小到大排序
	if #enemies > 0 then  --有可发动目标
		for _, enemy in ipairs(enemies) do
			if self:damageIsEffective(enemy) and not self:cantbeHurt(enemy, self.player, 1) and self:canDamage(enemy,self.player,nil) then
				use.card = card
				if use.to then    --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
					use.to:append(enemy)
				end
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:damageIsEffective(friend) and self:needToLoseHp(friend, self.player, nil) then
			use.card = card
			if use.to then    --不可省略，因为在找出可用卡牌时use.to不为QList，添加角色时会出错
				use.to:append(friend)
			end
		end
	end
end

sgs.ai_use_value["mythshanshenCARD"] = 10      --使用价值
sgs.ai_use_priority["mythshanshenCARD"] = 8    --使用优先值
sgs.ai_card_intention["mythshanshenCARD"] = 50 --仇恨值

--孙鲁育-魅步
sgs.ai_skill_invoke.mythmeibu = function(self, data) --是否发动技能
	local player = data:toPlayer()
	if self:isEnemy(player) then
		return true --发动
	end
end
sgs.ai_choicemade_filter.skillInvoke.mythmeibu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end

--穆穆
sgs.ai_skill_invoke.mythmumu = function(self, data) --是否发动技能
	return true                                     --发动
end

sgs.ai_skill_choice.mythmumu = function(self, choices, data) --进行选择
	local r = math.random(1, 3)
	if r == 1 then
		return "huode"
	else
		return "mopai"
	end
end

sgs.ai_skill_playerchosen.mythmumu = function(self, targets) --选择目标
	local targetTable = sgs.QList2Table(targets)
	self:sort(targetTable, "value", true)                    --将目标按综合值从大到小排序
	for _, target in ipairs(targetTable) do                  --对所有目标进行扫描
		if self:isEnemy(target) and self:doDisCard(target, "he") then                         --目标是敌方
			return target
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.mythmumu = sgs.ai_choicemade_filter.cardChosen.snatch --卡牌选择

--薛灵芸-霞泪
sgs.ai_skill_invoke.mythxialei = function(self, data)
	return true
end

sgs.mythxialei_suit_value = {
	--花色保留值
	heart = 6,
	diamond = 6
}

--暗织
sgs.ai_skill_invoke.mythanzhi = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.mythanzhi = function(self, players) --选择目标
	local destlist = self:sort(players, "card")
	for _, target in sgs.list(destlist) do
		if self:isFriend(target)
		then
			return target
		end
	end
end

local mythanzhi_skill = {}
mythanzhi_skill.name = "mythanzhi"
table.insert(sgs.ai_skills, mythanzhi_skill)
mythanzhi_skill.getTurnUseCard = function(self) --考虑使用视为技的可能性
	if self.player:getMark("&mythanzhi-Clear") > 0 then return nil end
	if self.player:getMark("&mythxialei-Clear") > 0 then
		local did = self.room:getDrawPile():at(0)
		if sgs.Sanguosha:getCard(did):isRed() then --判红
			return sgs.Card_Parse("#mythanzhiCARD:.:") --返回技能卡
		end
	end
	local n = 0
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _, key in ipairs(self.player:getPileNames()) do
		if key:match("&") or key == "wooden_ox" then
			for _, id in sgs.qlist(self.player:getPile(key)) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end
	end
	for _, card in ipairs(cards) do
		if card:isAvailable(self.player) then
			if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					n = n + 1
					break
				end
			elseif card:getTypeId() == sgs.Card_TypeBasic and not card:isKindOf("Jink") then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
					n = n + 1
					break
				end
			elseif card:getTypeId() == sgs.Card_TypeEquip then
				local dummy_use = { isDummy = true }
				self:useEquipCard(card, dummy_use)
				if dummy_use.card then
					n = n + 1
					break
				end
			end
		end
	end
	if n == 0 then                           --无可用手牌
		return sgs.Card_Parse("#mythanzhiCARD:.:") --返回技能卡
	end
end

sgs.ai_skill_use_func["#mythanzhiCARD"] = function(card, use, self) --技能卡的使用函数
	use.card = card
end

sgs.ai_use_value["mythanzhiCARD"] = 7                   --使用价值
sgs.ai_use_priority["mythanzhiCARD"] = 9.9              --使用优先值

sgs.ai_skill_use["@mythanzhi"] = function(self, prompt) --被动技能卡的使用函数	
	return ("#mythanzhiCARD:.:")
end

sgs.ai_nullification.QhstandardIndulgence = function(self,trick,from,to,positive,null_num)
	if positive then
		if self:isFriend(to)
		and not(self:hasGuanxingEffect(to) or to:isSkipped(sgs.Player_Play))
		then--无观星友方判定区有乐不思蜀->视“突袭”、“巧变”情形而定
			if to:getHp()-to:getHandcardNum()>=2
			or to:getHp()>2 and to:hasSkill("tuxi")
			or null_num<2 and self:getOverflow(to)<-1
			or not to:isKongcheng() and to:hasSkill("qiaobian")
			and (to:containsTrick("supply_shortage") or self:willSkipDrawPhase(to))
			then else return true end
		end
	else
		
	end
end
