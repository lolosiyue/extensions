--妖智
sgs.ai_skill_invoke.sgkgodyaozhi = true


--杀绝
local sgkgodshajue_skill = {}
sgkgodshajue_skill.name = "sgkgodshajue"
table.insert(sgs.ai_skills, sgkgodshajue_skill)
sgkgodshajue_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sgkgodshajueCard") or self.player:isKongcheng() then return end
	if #self.enemies == 0 then return end
	if self.player:hasSkills("wushen|sgkgodwushen") or ((not self.player:hasSkill("sgkgodguiqu")) and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < 1) then return end
	return sgs.Card_Parse("#sgkgodshajueCard:.:")
end

sgs.ai_skill_use_func["#sgkgodshajueCard"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	local inicards = sgs.CardList()
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if not self.player:isJilei(c) then
			inicards:append(c)
		end
	end
	local x = inicards:length()
	local target
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:hasSkill("kongcheng")) and self.player:canSlash(enemy, nil, false) and (not self:canLiuli(enemy, self.friends_noself)) then
			if x >= enemy:getHp() then
				target = enemy
				break
			end
		end
	end
	if target then
		use.card = sgs.Card_Parse("#sgkgodshajueCard:.:")
		if use.to then use.to:append(target) end
		return
	end
end


sgs.ai_use_value["sgkgodshajueCard"] = 9.5
sgs.ai_use_priority["sgkgodshajueCard"] = 9.5
sgs.ai_card_intention["sgkgodshajueCard"] = 100


--鬼驱
sgs.ai_cardsview["sgkgodguiqu"] = function(self, class_name, player)
	if class_name == "Peach" then
		if player:hasSkill("sgkgodguiqu") and player:hasFlag("Global_Dying") and player:getVisibleSkillList():length() > 0 then
			return ("peach:sgkgodguiqu[no_suit:0]=.")
		end
	end
end

sgs.ai_skill_choice["sgkgodguiqu"] = function(self, choices, data)
	local room = self.room
	local skills = choices:split("+")
	local bad_skills = {"shiyong", "sk_shiyong", "longnu", "jinjiu", "sgkgodwushen", "wushen", "tongji"}  --几个与【杀】有关的负面技
	local lvbu_initial = {"sgkgodshajue", "sgkgodluocha", "sgkgodguiqu"}
	local to_lose
	for _, bad in ipairs(bad_skills) do
		if table.contains(skills, bad) then
			to_lose = bad
			break
		end
	end
	if not to_lose then
		local lvbu_extra = {}
		for _, _skill in ipairs(skills) do
			if not table.contains(lvbu_initial, _skill) then table.insert(lvbu_extra, _skill) end
		end
		if #lvbu_extra > 0 then
			to_lose = lvbu_extra[math.random(1, #lvbu_extra)]
		end
	end
	if not to_lose then
		if #skills <= 3 then
			if table.contains(skills, lvbu_initial[1]) then return lvbu_initial[1] end  --如果额外技能全丢了，优先舍弃【杀绝】
			if table.contains(skills, lvbu_initial[2]) then return lvbu_initial[2] end  --再其次，为了保命，舍弃【罗刹】
			if table.contains(skills, lvbu_initial[3]) then return lvbu_initial[3] end  --最后变成白板，舍弃【鬼驱】
		end
	end
	if to_lose then
		return to_lose
	end
	return skills[math.random(1, #skills)]
end


--函数1：判断SP神张角当前所处的“阴阳生”状态
function getYinyangState(player)
	if player:getHp() > player:getLostHp() then  --体力值大于损失体力，阳
		return "hp_Yang"
	end
	if player:getHp() == player:getLostHp() then  --体力值等于损失体力，生
		return "hp_Sheng"
	end
	if player:getHp() < player:getLostHp() then  --体力值小于损失体力，阴
		return "hp_Yin"
	end
end


--函数2：判断SP神张角自身的技能是否会因为体力上限的变化引起“阴阳生”状态变化
function canChangeYinyangState(player, add_or_lose)
	if add_or_lose == "add" then
		if getYinyangState(player) == "hp_Sheng" then  --处在“生”状态下，只要增加体力上限，必定打破平衡
			return true
		elseif getYinyangState(player) == "hp_Yang" then  --处在“阳”状态下，只有hp比lost多1时，再加1点就从“阳”变为“生”
			if player:getHp() == player:getLostHp() + 1 then return true end
		elseif getYinyangState(player) == "hp_Yin" then  --处在“阴”状态下，如果只是增加体力上限，这是无论如何都无法改变“阴阳生”状态的
			return false
		end
	elseif add_or_lose == "lose" then
		if getYinyangState(player) == "hp_Sheng" then  --处在“生”状态下，只要减少体力上限，必定打破平衡
			return true
		elseif getYinyangState(player) == "hp_Yang" then  --处在“阳”状态下，如果只是减少体力上限，这是无论如何都无法改变“阴阳生”状态的
			return false
		elseif getYinyangState(player) == "hp_Yin" then  --处在“阴”状态下，只有hp=losthp-1时，再减1点就会从“阴”变成“生”
			if player:getHp() + 1 == player:getLostHp() then return true end
		end
	end
end


--极阳
sgs.ai_skill_playerchosen.sgkgodjiyang = function(self, targets)
	local jiyang = {}
	for _, _player in sgs.qlist(targets) do
	    if self:isFriend(_player) then 
			if (not (_player:hasSkill("hunzi") and _player:getHp() == 1)) then table.insert(jiyang, _player) end
		end
	end
	self:sort(jiyang, "value")
	if #jiyang > 0 then
	    self:sort(jiyang, "value")
	    return jiyang[1]
	end
end


--极阴
sgs.ai_skill_playerchosen.sgkgodjiyin = function(self, targets)
	local jiyin = {}
	if self.player:isWounded() and (not self.player:hasSkill("jueqing")) and canChangeYinyangState(self.player, "lose") then return self.player end
	for _, _player in sgs.qlist(targets) do
	    if self:isEnemy(_player) then 
			if (not _player:hasSkills("sgkgodyinshi|sgkgodleihun")) or (_player:hasSkill("sr_weiwo") and _player:isKongcheng()) then
				table.insert(jiyin, _player)
			end
		end
	end
	self:sort(jiyin, "value")
	if #jiyin > 0 then
	    self:sort(jiyin, "value")
	    return jiyin[1]
	end
end


--定命
sgs.ai_skill_invoke.sgkgoddingming = function(self, data)
	local to = data:toPlayer()
	local x = math.abs(to:getHp() - to:getLostHp())
	if self.player:getMaxHp() == 1 then return false end
	--情形1：自己的准备阶段
	if self.player:getSeat() == to:getSeat() and self.player:getPhase() == sgs.Player_Start then
		--有【桃】或【酒】，想炸血卖
		if getYinyangState(self.player) == "hp_Yang" and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") >= 1 then
			if x >= 2 then return true end
			--有界黄盖的【诈降】，哪怕差值只有1也卖
			if hasZhaxiangEffect(self.player) then return true end
			--能触发夏侯霸的【豹变】也卖了
			if self.player:hasSkill("baobian") and self.player:getHp() - x <= 3 then return true end
			--如果有【英魂】/【再起】也卖
			if self.player:hasSkills("yinghun|zaiqi") and self.player:getLostHp() + x >= 2 and self.player:getHp() - x >= 0 then return true end
			--有神孙策的【冯河】，必须得卖，否则保不住手牌上限
			if self.player:hasSkill("f_pinghe") and self.player:getHp() - x >= 0 then return true end
		end
		--自己刚好状态很残
		if getYinyangState(self.player) == "hp_Yin" and x >= 2 then return true end
	end
	--情形2：伤害类
	local damage = data:toDamage()
	--分支2-1：自己受到伤害时
	if self.player:getSeat() == to:getSeat() then
		if getYinyangState(self.player) == "hp_Yin" and x >= 1 then return true end
		--特殊：自己有孙策的【魂姿】且没觉醒的时候，即使自己处在“阳”也要炸血，并且压得越多越好，先保证能觉醒
		if getYinyangState(self.player) == "hp_Yang" and self.player:getMark("@waked") == 0 and self.player:hasSkill("hunzi") then
			if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") >= 1 and self.player:getHp() - x <= 1 then return true end
		end
	else
	--分支2-2：对其他角色造成伤害时
		if self:isEnemy(to) then
			if getYinyangState(to) == "hp_Yang" and not (to:hasSkill("hunzi") and to:getMark("@waked") == 0) then
				if (x >= 2 or to:getHp() - x <= 1) and self.player:getMaxHp() > 1 and canChangeYinyangState(self.player, "lose") then return true end
			end
		elseif self:isFriend(to) then
			--特例：如果这个人是没觉醒且有【魂姿】的孙策
			if getYinyangState(to) == "hp_Yang" and not (to:hasSkill("hunzi") and to:getMark("@waked") == 0) then
				if self.player:getMaxHp() > 1 and to:getLostHp() == 1 then return true end
			else
				if getYinyangState(to) == "hp_Yin" then return true end
			end
		end
	end
end


--锋影
sgs.ai_skill_playerchosen.sgkgodfengying = function(self, targets)
	if #self.enemies == 0 then return nil end
	local room = self.room
	local tos = {}
	local tslash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			if not sgs.Sanguosha:isProhibited(self.player, p, tslash) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) then table.insert(tos, p) end
		end
	end
	if #tos > 0 then
		self:sort(tos, "defenseSlash")
		return tos[1]
	else
	    return nil
	end
	return nil
end


--止啼
sgs.ai_skill_invoke.sgkgodzhiti = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end


--止啼5选1
function evil()
	return {"mobilepojun", "tenyearzhiheng", "pingjian", "pingcai", "jieyingg", "tenyearxuanfeng", "jiwu", "sgkgodguixin", "guixin", "sgkgodyaozhi", "sgkgodjinlong",
	"fenyin", "qinzheng", "sgkgodluocha", "sgkgodzhitian", "sgkgodtongtian", "f_lingce", "rangjie", "chengxiang", "hengwu", "liuzhuan", "sgkgodtiangong", 
	"chouce", "yiji", "sgkgodzhiti", "sgkgodyinyang", "fangzhu", "yuqi", "sgkgodxiejia", "gdlonghun", "f_huishi", "longhun", "sgkgodleihun", "sgkgodyingshi", 
	"sgkgodmeixin", "sr_zhaoxiang", "jiaozi", "shanjia", "wushuang", "tenyearyiji", "sgkgodjilue", "lingce", "tieji", "jianying", "moutieqii"}
end
sgs.ai_skill_choice["sgkgodzhiti"] = function(self, choices, data)
	local imba = evil()
	local steal = false
	local target = data:toPlayer()
	if string.find(choices, "_stealOneSkill") then
		
		for _, sk in sgs.qlist(target:getVisibleSkillList()) do
			if string.find(table.concat(imba, "+"), sk:objectName()) then
				steal = true
				break
			end
		end
		if not steal then
			for _, sk in sgs.qlist(target:getVisibleSkillList()) do
				if self:isValueSkill(sk:objectName(), target, true) then
					steal = true
					break
				end
			end
		end
		if not steal then
			for _, sk in sgs.qlist(target:getVisibleSkillList()) do
				if self:isValueSkill(sk:objectName(), target) then
					steal = true
					break
				end
			end
		end
		if steal then return "spgodzl_stealOneSkill" end
	end
	local zhiti = choices:split("+")
	for i = 1, #zhiti, 1 do
		if self:isWeak() and string.find(zhiti[i], "_stealOneHpAndMaxhp") then
			return zhiti[i]
		end
		if self:isEnemy(target) and target:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill) and string.find(zhiti[i], "_banEquip") then
			return zhiti[i]
		end
		if self:isEnemy(target) and self:hasSkills(sgs.priority_skill, target) and string.find(zhiti[i], "_turnOver") then
			return zhiti[i]
		end
	end
	return zhiti[math.random(1, #zhiti)]
end

sgs.ai_skill_choice["zhiti_stealWhat"] = function(self, choices, data)
	local target = data:toPlayer()
	local skills = choices:split("+")
	local imba = evil()
	for _, sk in ipairs(skills) do
		if table.contains(imba, sk) then
			return sk
		end
	end
	for _, sk in ipairs(skills) do
		if self:isValueSkill(sk, target, true) then
			return sk
		end
	end
	for _, sk in ipairs(skills) do
		if self:isValueSkill(sk, target) then
			return sk
		end
	end
	for _, sk in ipairs(skills) do
		if string.find(sgs.masochism_skill, sk) or string.find(sgs.recover_skill, sk) then
			return sk
		end
	end
	local not_bad_skills = {}
	for _, sk in ipairs(skills) do
		if string.find(sgs.bad_skills, sk) then continue end
		table.insert(not_bad_skills, sk)
	end
	if #not_bad_skills > 0 then
		return not_bad_skills[math.random(1, #not_bad_skills)]
	end
	return skills[math.random(1, #skills)]
end


--劫营
sgs.ai_skill_invoke.sgkgodjieying = function(self, data)
	if #self.enemies == 0 then return nil end
	return true
end

sgs.ai_skill_playerchosen.sgkgodjieying = function(self, targets)
	local target
	for _, pe in sgs.qlist(targets) do
		if self:isEnemy(pe) and pe:hasSkills("yongsi|tenyearzhiheng|zhiheng|sgkgodluocha|zishou|xiaoji|haoshi|mou_yingzi|yingzi|sgkgodguixin|fenyin|pingcai|tenyearfenyin") then
			target = pe
			break
		end
	end
	if not target then
		for _, pe in sgs.qlist(targets) do
			if self:isEnemy(pe) and pe:hasSkills("sgkgodyinyang|sgkgodjiyang|sgkgodxiangsheng|sgkgodyaozhi|sgkgodzhitian|sy_mingzheng|hunzi|zhiji|wuji|zhengnan|tenyearzhengnan|sgkgodzhiti") then
				target = pe
				break
			end
		end
	end
	if not target then
		local es = {}
		for _, pe in sgs.qlist(targets) do
			if self:isEnemy(pe) then table.insert(es, pe) end
		end
		self:sort(es, "chaofeng")
		target = es[1]
	end
	return target
end


--鹰视
sgs.ai_skill_askforag.sgkgodyingshi = function(self, card_ids)
	local result_id = -1
	for _,id in sgs.list(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") then
			result_id = id
			break
		end
	end
	if result_id ~= -1 then return result_id end
end

sgs.ai_cardneed.sgkgodyingshi = function(to,card)
	return card:getTag("jlyingshi_eagle"):toBool() == false
end

--狼袭
sgs.ai_skill_use["@@sgkgodlangxi"] = function(self, prompt)
    if #self.enemies == 0 then return "." end
	local room = self.room
	local langxi_tar = {}
	for _, pe in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if (not self:isFriend(pe)) and pe:getMark("jllangxi_target") > 0 then table.insert(langxi_tar, pe:objectName()) end
	end
	if #langxi_tar > 0 then return "#sgkgodlangxiCard:.:->" .. table.concat(langxi_tar, "+") else return "." end
end

sgs.ai_skill_askforag.sgkgodlangxi = function(self, card_ids)
	local result_id = -1
	for _,id in sgs.list(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Snatch") then
			result_id = id
			break
		end
	end
	if result_id ~= -1 then return result_id end
end

sgs.ai_skill_invoke.sgkgodlangxi = function(self, data)
	local use = data:toCardUse()
	if use.card:isKindOf("ExNihilo") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("IronChain") or use.card:isKindOf("AmazingGrace") or use.card:isKindOf("Collateral") then
		return false
	end
	if use.card:isKindOf("Dongzhuxianji") or use.card:isKindOf("Chuqibuyi") then return false end
	return true
end

sgs.sgkgodlangxi_keep_value = {
	Snatch      = 5.7,
	Dismantlement = 5.6,
	SavageAssault=5.4,
	Duel        = 5.3,
	ArcheryAttack = 5.2,
	AmazingGrace = 5.1,
	FireAttack  =4.9
}

--神隐
sgs.ai_skill_invoke.sgkgodshenyin = function(self, data)
	if self.player:getPhase() == sgs.Player_Start and self.player:getMark("&sgkgodshenyin") > 0 then return true end
	local dying = data:toDying()
	if dying.who:objectName() == self.player:objectName() then
		local peaches = 1 - self.player:getHp()
		return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
	end
end

sgs.ai_skill_invoke["#sgkgodshenyinLose"] = true


--潜渊
sgs.ai_skill_invoke.sgkgodqianyuan = function(self, data)
	if data:toString() and data:toString():startsWith("sgkgodjiguan_") then return false end
	if self.player:getMark("sgkgodhualong") < 8 then return true end
end

sgs.ai_skill_invoke["#sgkgodqianyuanLose"] = function(self, data)
	if data:toString():startsWith("sgkgodjiguan_") then return false end
	return true
end


--化龙
sgs.ai_skill_invoke.sgkgodhualong = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen.sgkgodhualong = function(self, targets)
	local enemies = {}
	for _, pe in sgs.qlist(targets) do
		if self:isEnemy(pe) then table.insert(enemies, pe) end
	end
	self:sort(enemies)
	return enemies[1]
end

--天工
sgs.ai_skill_invoke.sgkgodtiangong = true  --组装机关是一定要组装的，OL南华老仙是一定要跪下唱征服的

sgs.ai_skill_choice["tiangong_targets"] = function(self, choices, data)
	local targets = choices:split("+")
	if table.contains(targets, "niziji") then return "niziji" end
	for _, frequent_target in ipairs(tiangong_frequent_targets) do
		if table.contains(targets, frequent_target) then return frequent_target end
	end
	return targets[math.random(1, #targets)]
end

tiangong_frequent_timings = {  --天工机关常用时机
	"phase_begin", "judge_begin", "draw_begin", "play_begin", "play_end", "discard_end", "finish_begin",
	"afterusebasic1", "afterusebasic2", "afterusebasic3", 
	"afterusetrick1", "afterusetrick2", "afterusetrick3", 
	"afteruseequip1", "afteruseequip2", "afteruseequip3", 
	"afterusered1", "afterusered2", "afterusered3",
	"afteruseblack1", "afteruseblack2", "afteruseblack3", 
}

sgs.ai_skill_choice["tiangong_timings"] = function(self, choices, data)
	local timings = choices:split("+")
	for _, frequent_timing in ipairs(tiangong_frequent_timings) do
		if table.contains(timings, frequent_timing) then return frequent_timing end
	end
	return timings[math.random(1, #timings)]
end

tiangong_frequent_targets = {  --天工机关常用目标
	"niziji", "suoyouqitajuese", "suoyouqunjuese", "suoyoujlgodjuese", "suoyoujlmojuese", "maxhpmost", "maxhpleast", 
	"hpmost", "hpleast", "shoupaizuiduo", "shoupaizuishao"
}

tiangong_negative_effects = {  --天工机关负面效果
	"fanmian", "shandianpanding", "suijishiquyigejineng", "onedamage", "onefiredamage", "onethunderdamage", "oneicedamage", "loseonemaxhp", 
	"loseonehp", "losetwohp", "suijiqizhitwo", "suijiqizhithree", "suijiqizhifour", "exchangewithless"
}

tiangong_gainskill_effects = {  --天工机关获得技能的效果（魏/蜀/吴/群/晋/普通神/极略神/魔）
	"suijishujineng", "suijiweijineng", "suijiwujineng", "suijiqunjineng", "suijigodjineng", "suijijinjineng", "suijijlgodjineng", "suijimojineng"
}

tiangong_basic_effects = {  --天工机关基础增益（视为使用【桃】/摸牌/回血/加上限/加摸牌数/加【杀】次数/定向获得红/黑/基本/装备/锦囊牌/……）
	"view_as_peach", "suijitwored", "suijitwoblack", "suijitwobasic", "suijitwotrick", "suijitwoequip", "addonemaxhp", "recoveronehp", "recovertwohp", 
	"mopaishumore", "mopaitwo", "mopaithree", "mopaifour", "suijiguixin", "giantzhiheng", "exchangewithmore"
}

sgs.ai_skill_choice["tiangong_effects"] = function(self, choices, data)
	local effects = choices:split("+")
	local to = self.player:getTag("tiangong_targets_AI"):toString()
	if to == "niziji" then
		for _, _gainskill in ipairs(tiangong_gainskill_effects) do  --能设法获得技能肯定优先选这个，一个是膨胀自身强度，二来能给“玲珑”提供更多的减伤防扣上限的护盾
			if table.contains(effects, _gainskill) then
				if _gainskill == "suijimojineng" then return _gainskill end  --优先考虑《极略三国》的魔将技能
				if _gainskill == "suijijlgodjineng" then return _gainskill end  --然后考虑《极略三国》的神将技能
				if _gainskill == "suijigodjineng" then return _gainskill end  --再考虑普通（苟咔官方）神将的技能
				if _gainskill == "suijiqunjineng" then return _gainskill end  --再次一级考虑群雄技能
				if _gainskill == "suijiwujineng" then return _gainskill end  --再再次一级考虑吴国技能（毕竟界孙权吹那么多，敢让界孙权挑战“人机牌序单挑武诸葛亮都能随便爆杀的SP神司马懿”都不眨眼）
				if _gainskill == "suijishujineng" then return _gainskill end  --再再再次一级考虑蜀国技能（毕竟蜀汉盛产菜刀但过牌相对吴国没那么多）
				return _gainskill
			end
		end
		for _, _basiceffects in ipairs(tiangong_basic_effects) do
			if table.contains(effects, _basiceffects) then
				if _basiceffects:startsWith("mopait") or _basiceffects:startsWith("mopaif") then return _basiceffects end  --首选能即时摸牌的效果
				if _basiceffects:startsWith("suijitwo") then return _basiceffects end  --次选随机两张定向牌
				if _basiceffects == "addonemaxhp" or _basiceffects == "recoveronehp" or _basiceffects == "recovertwohp" then return _basiceffects end  --然后考虑续航效果
				return _basiceffects
			end
		end
		for _, _negativeeffects in ipairs(tiangong_negative_effects) do
			if table.contains(effects, _negativeeffects) then
				if _negativeeffects == "suijishiquyigejineng" then return _negativeeffects end  --首选随机失去一个技能
				if _negativeeffects:startsWith("lose") then return _negativeeffects end  --次选失去1点体力/2点体力/1点体力上限
				if _negativeeffects:startsWith("one") then return _negativeeffects end  --再次选受到1点普通/雷电/火焰/冰冻伤害
				if _negativeeffects:startsWith("suijiqizhi") then return _negativeeffects end  --再次一级选择随机弃置2/3/4张牌
				return _negativeeffects
			end
		end
	else
		local buff = false
		for _, effect in ipairs(effects) do
			if table.contains(tiangong_gainskill_effects, effect) or table.contains(tiangong_basic_effects, effect) then
				buff = true
				break
			end
		end
		if not buff then
			for _, _negativeeffects in ipairs(tiangong_negative_effects) do
				if table.contains(effects, _negativeeffects) then
					if _negativeeffects == "suijishiquyigejineng" then return _negativeeffects end  --首选随机失去一个技能
					if _negativeeffects:startsWith("lose") then return _negativeeffects end  --次选失去1点体力/2点体力/1点体力上限
					if _negativeeffects:startsWith("one") then return _negativeeffects end  --再次选受到1点普通/雷电/火焰/冰冻伤害
					if _negativeeffects:startsWith("suijiqizhi") then return _negativeeffects end  --再次一级选择随机弃置2/3/4张牌
					return _negativeeffects
				end
			end
		end
	end
	return effects[math.random(1, #effects)]
end

function youAreVictim(targets, kingdom)
	if targets == "suoyouweijuese" and kingdom == "wei" then return true end
	if targets == "suoyouweishuse" and kingdom == "shu" then return true end
	if targets == "suoyouweiwuse" and kingdom == "wu" then return true end
	if targets == "suoyouweiqunse" and kingdom == "qun" then return true end
	if targets == "suoyouweijinse" and kingdom == "jin" then return true end
	if targets == "suoyoujlgodjinse" and kingdom == "sy_god" then return true end
	if targets == "suoyoujlmojuese" and kingdom == "sgk_magic" then return true end
	return false
end

sgs.ai_skill_playerchosen.sgkgodtiangong = function(self, targets)
	local setup = self.player:getTag("tiangong_schemesetup_AI"):toString():split("+")
	local room = self.player:getRoom()
	--[1]机关技能名、[2]发动时机、[3]执行目标、[4]技能效果、[5]限制次数（0代表不限制）
	local timing, exe, effect = setup[2], setup[3], setup[4]
	if self.player:getRole() == "loyalist" then
		if table.contains(tiangong_basic_effects, effect) then
			if youAreVictim(exe, self.player:getKingdom()) then
				return room:getLord()
			end
		end
		if table.contains(tiangong_gainskill_effects) and exe == "niziji" then
			return room:getLord()
		end
	end
	if #self.enemies == 0 then
		if table.contains(tiangong_negative_effects, effect) then  --如果这个执行效果是负面的
			if exe == "niziji" then  --如果这个机关的执行主体是“你”
				for _, t in sgs.qlist(targets) do
					if t:objectName() ~= self.player:objectName() and t:hasSkills("wuhun|sgkgodsuohun|duanchang|sgkgodyinshi|sgkgodyaozhi|sgkgodshenyin") then
						return t
					end
				end
			elseif (exe == "suoyounvxingjuese" and self.player:isFemale()) or (exe == "suoyounanxingjuese" and self.player:isMale()) or youAreVictim(exe, self.player:getKingdom()) then
				return self.player:getNextAlive(room:getAlivePlayers():length() - 1)
			end
			local players = sgs.QList2Table(targets)
			table.removeOne(players, self.player)
			self:sort(players, "value")
			return players[1]
		else
			if table.contains(tiangong_gainskill_effects, effect) or table.contains(tiangong_basic_effects, effect) then
				return self.player
			end
		end
	elseif #self.enemies > 0 then
		if table.contains(tiangong_negative_effects, effect) then
			if exe == "niziji" then
				local players = sgs.QList2Table(targets)
				table.removeOne(players, self.player)
				self:sort(players, "value")
				for _, enemy in ipairs(players) do
					if self:isEnemy(enemy) then
						if timing:startsWith("playergainskill") then
							if enemy:hasSkills("sgkgodtongtian|sgkgodzhitian|sgkgodyaozhi|sgkgodluocha|sgkgodzhiti|sgkgodjieying") then
								return enemy
							end
							return enemy
						elseif timing:startsWith("gaincard") or timing:startsWith("afteruse") then
							if enemy:hasSkills("sgkgodjilue|zishu|qinzheng|yongsi|zhiheng|tenyearzhiheng|jizhi|qiangzhi|guixin|sgkgodguixin|sgkgodshajue|sgkgodluocha") then
								return enemy
							end
							if enemy:hasSkills("feiyang|bahu|moujizhi|paiyi|luoshen|yiji|new_jilue|jilve|tongli|shezang||ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun|zhizhe") then
								return enemy
							end
						end
						return enemy
					end
				end
			elseif (exe == "suoyounvxingjuese" and self.player:isFemale()) or (exe == "suoyounanxingjuese" and self.player:isMale()) or youAreVictim(exe, self.player:getKingdom()) then
				local players = sgs.QList2Table(targets)
				table.removeOne(players, self.player)
				self:sort(players, "value")
				for _, enemy in ipairs(players) do
					if self:isEnemy(enemy) and ((exe == "suoyounvxingjuese" and enemy:isFemale()) or (exe == "suoyounanxingjuese" and enemy:isMale()) or youAreVictim(exe, enemy:getKingdom())) then
						return enemy
					end
				end
			end
			local players = sgs.QList2Table(targets)
			table.removeOne(players, self.player)
			self:sort(players, "value")
			for _, enemy in ipairs(players) do
				if self:isEnemy(enemy) and (not youAreVictim(exe, self.player:getKingdom())) then
					return enemy
				end
			end
		else
			if table.contains(tiangong_gainskill_effects, effect) and exe == "niziji" then
				return self.player
			end
			if table.contains(tiangong_basic_effects, effect) and exe == "niziji" then
				local players = sgs.QList2Table(targets)
				self:sort(players, "hp")
				for _, friend in ipairs(players) do
					if self:isFriend(friend) then return friend end
				end
			end
		end
	end
	if table.contains(tiangong_gainskill_effects, effect) or table.contains(tiangong_basic_effects, effect) then
		if exe == "niziji" then
			return self.player
		end
	end
	return self.player
end


--玲珑
sgs.ai_skill_invoke.sgkgodlinglong = function(self, data)
	if data:toMaxHp().change < 0 then return true end
	if data:toHpLost().lose > 0 then return true end
	if (player:getMark(data:toString().."_mark") == 0 or player:hasInnateSkill(data:toString())) and #self.enemies > 0 then return true end
	if data:toDamage().damage > 0 and (not self:needToLoseHp(self.player)) then return true end
end

function hasSchemeSkill(target)
	local has = false
	for _, skill in sgs.qlist(target:getVisibleSkillList()) do
		if string.find(skill:objectName(), "sgkgodjiguan_") then
			has = true
			break
		end
	end
	return has
end

function getSchemeSkills(target)
	local schemes = {}
	for _, sk in sgs.qlist(target:getVisibleSkillList()) do
		if string.find(sk:objectName(), "sgkgodjiguan_") then table.insert(schemes, sk:objectName()) end
	end
	return schemes
end

function getOtherSkills(player)
	local others = {}
	for _, skill in sgs.qlist(player:getVisibleSkillList()) do
		if not player:hasInnateSkill(skill:objectName()) then table.insert(others, skill:objectName()) end
	end
	return others
end

sgs.ai_skill_playerchosen.sgkgodlinglong = function(self, targets)
	--失去体力上限
	local mhp = self.player:getTag("linglong_maxhpData"):toMaxHp()
	if mhp and mhp.change < 0 then
		local players = sgs.QList2Table(targets)
		self:sort(players, "maxhp")
		for _, t in ipairs(players) do
			if self:isEnemy(t) then return t end
		end
	end
	--失去体力
	local lose = self.player:getTag("linglong_losehpData"):toHpLost()
	if lose and lose.lose > 0 and (not self:needToLoseHp(self.player)) then
		local players = sgs.QList2Table(targets)
		self:sort(players, "hp")
		for _, t in ipairs(players) do
			if self:isEnemy(t) then return t end
		end
	end
	--受到伤害
	local damage = self.player:getTag("linglong_damageData"):toDamage()
	if damage then
		if damage.damage > 0 and (not self:needToLoseHp(self.player)) then
			local players = sgs.QList2Table(targets)
			self:sort(players, "hp")
			for _, t in ipairs(players) do
				if self:isEnemy(t) then return t end
			end
		end
		if damage.damage >= self.player:getHp() then
			local players = sgs.QList2Table(targets)
			self:sort(players, "hp")
			for _, t in ipairs(players) do
				if self:isEnemy(t) then return t end
			end
		end
	end
	--失去技能
	local skill = self.player:getTag("linglong_loseskillData"):toString()
	if skill and skill ~= "" and skill ~= nil then
		local players = sgs.QList2Table(targets)
		self:sort(players, "value")
		for _, t in ipairs(players) do
			if self:isEnemy(t) then return t end
		end
	end
	local others = getOtherSkills(self.player)
	if #others > 0 then return self.player end
	return nil
end


local value_skills = {
	"sgkgodjilue", "sgkgodtongtian", "sgkgodluocha", "sgkgodguiqu", "sgkgodyinyang", "sgkgodzhitian", "sgkgodyinshi",
	"sgkgodguixin", "jilve", "renjie", "mobilepojun", "moutieqii", "tieji", "tenyearzhiheng", "zhiheng", "sgkgodyaozhi",
	"sgkgodqifeng", "sgkgodlunce", "sgkgodxingwu", "sgkgodchenyu", "ny_10th_qingbei", "ny_10th_zhangcai", "ny_10th_sujun",
	"sgkgodzhiti", "sy_bolue", "sy_lingnue", "sy_tianyou", "sy_yinzi", "sy_fangu", "sy_canlue", "sy_shisha", "sy_huoxin",
	"sgkgodleihun", "sgkgodmeixin", "sgkgodtianzi", "sgkgodlangxi", "sgkgodshenyin", "sgkgodyingshi"
}

sgs.ai_skill_choice.sgkgodlinglong = function(self, choices, data)
	local to = data:toPlayer()
	local skills = choices:split("+")
	if self.player:objectName() == to:objectName() then
		for _, skill in ipairs(skills) do
			if string.find(sgs.bad_skills, skill) then return skill end
			if not table.contains(value_skills, skill) then return skill end
		end
		return skills[#skills]
	else
		return skills[math.random(1, #skills)]
	end
end

sgs.ai_skill_invoke.sgkgodzhanyue = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end

sgs.ai_skill_playerchosen.sgkgodzhanyue = function(self, targets)
	local slash = dummyCard()
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defenseSlash")
	for _,target in sgs.list(targets)do
		if self:isEnemy(target)
		and not self:slashProhibit(slash,target)
		and self:isGoodTarget(target,targets,slash)
		and self:slashIsEffective(slash,target)
		then return target end
	end
	return nil
end

sgs.ai_skill_invoke.sgkgodfengtian = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end

sgs.ai_skill_discard.sgkgodfengtian = function(self, discard_num, min_num, optional, include_equip)
	local give = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards, true)
	for _, c in ipairs(cards) do
		if c:isKindOf("Slash") then
			table.insert(give, c:getEffectiveId())
			break
		end
	end
	if #give == 0 then
		if self:needToThrowArmor() then
			table.insert(give,self.player:getArmor():getEffectiveId())
			for _,c in ipairs(cards)do
				if c:getEffectiveId()==self.player:getArmor():getEffectiveId() then continue end
				table.insert(give,c:getEffectiveId())
				break
			end
		end
	end
	if #give == 0 then
		for _,c in ipairs(cards)do
			table.insert(give,c:getEffectiveId())
			if #give==1 then break end
		end
	end
	if #give == 1 then return give end
end
