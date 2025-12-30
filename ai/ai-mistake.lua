-- AI失误系统 (AI Mistake System)
-- 让AI偶尔做出不那么完美的决策，使其更像真人玩家
--
-- 设计原则：
-- 1. 失误应该增加趣味性，而不是破坏游戏体验
-- 2. 避免在关键决策（救人、无懈）上失误
-- 3. 失误率应该可控且合理（建议2-10%）
-- 4. 失误应该有明显的反馈（对话）
-- 5. 随着游戏进行，AI应该越来越"熟练"

-- 失误配置
sgs.ai_mistake_config = {
	enabled = true,                    -- 是否启用失误系统
	base_rate = 0.05,                  -- 基础失误率 (5%)
	turncount_factor = 0.005,          -- 回合数影响因子（回合越多，越熟练，失误率降低）
	max_rate = 0.15,                   -- 最大失误率 (15%)
	min_rate = 0.02,                   -- 最小失误率 (2%)
}

-- 获取当前失误率
function getAIMistakeRate()
	if not sgs.ai_mistake_config.enabled or not sgs.ai_humanized then
		return 0
	end
	
	local rate = sgs.ai_mistake_config.base_rate
	
	-- 回合数越多，失误率降低（AI "熟练度"提升）
	if sgs.turncount then
		rate = rate - (sgs.turncount * sgs.ai_mistake_config.turncount_factor)
	end
	
	-- 限制在合理范围内
	rate = math.max(sgs.ai_mistake_config.min_rate, rate)
	rate = math.min(sgs.ai_mistake_config.max_rate, rate)
	
	return rate
end

-- 判断是否应该触发失误
function shouldMakeMistake(extra_chance)
	extra_chance = extra_chance or 0
	local rate = getAIMistakeRate() + extra_chance
	return math.random() < rate
end

-- 判断是否为关键局势（关键时刻不应失误）
function isCriticalSituation(player)
	if not player then return false end
	
	-- 主公濒死
	local lord = getLord(player)
	if lord and lord:getHp() <= 1 then
		return true
	end
	
	-- 自己濒死
	if player:getHp() <= 1 then
		return true
	end
	
	-- 游戏即将结束（存活人数很少）
	if player:aliveCount() <= 3 then
		return true
	end
	
	return false
end

-- 安全的失误判断（在关键时刻自动禁用）
function shouldMakeSafeMistake(player, extra_chance)
	if isCriticalSituation(player) then
		return false
	end
	return shouldMakeMistake(extra_chance)
end

-- 检测玩家是否为真人玩家
function isHumanPlayer(player)
	if not player then return false end
	return player:getState() ~= "robot"
end

-- 检测目标是否为同队的真人玩家（单机模式保护）
function isTeammateHuman(self_player, target)
	if not self_player or not target then return false end
	
	-- 目标不是真人，没问题
	if not isHumanPlayer(target) then
		return false
	end
	
	-- 目标是真人，检查是否同队
	local self_ai = self_player:getAI()
	if self_ai and self_ai.isFriend then
		return self_ai:isFriend(target)
	end
	
	-- 无法判断时保守处理：保护真人
	return true
end

-- 失误类型枚举
sgs.ai_mistake_type = {
	-- ✅ 已启用的失误类型（影响较小）
	WRONG_TARGET = "wrong_target",           -- 选错目标（例如：杀次优目标而非最优）
	SKIP_SKILL = "skip_skill",               -- 跳过应该使用的技能（非关键技能）
	WRONG_SKILL = "wrong_skill",             -- 错误使用技能（概率极低）
	DISCARD_GOOD_CARD = "discard_good",      -- 弃掉好牌（弃牌阶段随机弃）
	KEEP_BAD_CARD = "keep_bad",              -- 保留坏牌
	WRONG_ORDER = "wrong_order",             -- 出牌顺序错误
	MISS_LETHAL = "miss_lethal",             -- 错失斩杀（仅记录统计）
	OVER_DEFEND = "over_defend",             -- 过度防守
	FRIENDLY_FIRE = "friendly_fire",         -- 误伤队友（打死受益受伤的队友）
	
}

-- 失误记录（用于统计和调试）
sgs.ai_mistake_log = {}

-- 记录失误
function logAIMistake(player, mistake_type, reason)
	if not player or player:getState() ~= "robot" then return end
	
	local log = {
		player = player:objectName(),
		screen_name = player:screenName(),
		mistake_type = mistake_type,
		reason = reason or "unknown",
		turncount = sgs.turncount or 0,
		timestamp = os.time()
	}
	
	table.insert(sgs.ai_mistake_log, log)
	
	-- 限制日志大小
	if #sgs.ai_mistake_log > 100 then
		table.remove(sgs.ai_mistake_log, 1)
	end
	
	-- 输出到控制台（调试用）
	if _G.AI_DEBUG_MODE then
		print(string.format("[AI失误] %s (%s) - 类型:%s 原因:%s", 
			log.screen_name, log.player, mistake_type, reason))
	end
end

-- 选择次优目标（用于目标选择失误）
function SmartAI:chooseSuboptimalTarget(optimal_target, all_targets, reason)
	if not shouldMakeMistake() then
		return optimal_target
	end
	
	-- 从其他可选目标中随机选一个
	-- 限制条件：
	-- 1. 必须和首选目标同一阵营（例如本来打敌人A，结果打成敌人B）
	-- 2. 不能是敌对阵营的真人玩家（减少对真人的影响）
	-- 3. 不能是同队真人玩家（保护队友）
	local alternatives = {}
	for _, target in ipairs(all_targets) do
		if target ~= optimal_target then
			local is_same_team = self:isFriend(optimal_target, target)
			local is_enemy_human = not self:isFriend(self.player, target) and isHumanPlayer(target)
			local is_teammate_human = isTeammateHuman(self.player, target)
			
			-- 只选择同阵营且不是敌对真人的目标
			if is_same_team and not is_enemy_human and not is_teammate_human then
				table.insert(alternatives, target)
			end
		end
	end
	
	-- 如果没有合适的替代目标，取消失误
	if #alternatives > 0 then
		local wrong_target = alternatives[math.random(1, #alternatives)]
		logAIMistake(self.player, sgs.ai_mistake_type.WRONG_TARGET, reason)
		self:speak("self_mistake", self.player:isFemale())
		return wrong_target
	end
	
	return optimal_target
end

-- 错误地跳过技能
function SmartAI:mistakeSkipSkill(skill_name, should_invoke)
	if not should_invoke then return false end
	
	-- 关键时刻不失误
	if isCriticalSituation(self.player) then
		return should_invoke
	end
	
	-- 某些核心技能永远不跳过
	local critical_skills = {
		"guanxing", "jizhi", "qingnang", "jijiu",  -- 核心辅助技能
		"rende", "zhiheng",                          -- 核心过牌技能
	}
	
	for _, critical in ipairs(critical_skills) do
		if skill_name:match(critical) then
			return should_invoke
		end
	end
	
	-- 有小概率不发动应该发动的技能
	if shouldMakeMistake(0.02) then
		logAIMistake(self.player, sgs.ai_mistake_type.SKIP_SKILL, skill_name)
		self:speak("self_mistake", self.player:isFemale())
		return false
	end
	
	return should_invoke
end

-- 错误地使用技能
function SmartAI:mistakeUseSkill(skill_name, should_not_invoke)
	if should_not_invoke then return false end
	
	-- 有小概率使用不应该使用的技能
	if shouldMakeMistake(0.01) then
		logAIMistake(self.player, sgs.ai_mistake_type.WRONG_SKILL, skill_name)
		-- 较低概率发动，因为这可能导致严重后果
		if math.random() < 0.3 then
			return true
		end
	end
	
	return false
end

-- 弃牌失误（弃掉好牌或保留坏牌）
function SmartAI:mistakeDiscardCards(sorted_cards, num_to_discard)
	-- 关键时刻不失误
	if not shouldMakeSafeMistake(self.player, 0.03) then
		-- 正常情况：弃掉最差的牌
		local result = {}
		for i = 1, num_to_discard do
			if sorted_cards[i] then
				table.insert(result, sorted_cards[i])
			end
		end
		return result
	end
	
	-- 失误：随机选择要弃的牌（但不会太离谱）
	local shuffled = {}
	for _, card in ipairs(sorted_cards) do
		table.insert(shuffled, card)
	end
	
	-- 轻微打乱顺序（不是完全随机）
	local swap_count = math.min(3, #shuffled)
	for i = 1, swap_count do
		local j = math.random(math.max(1, i-2), math.min(#shuffled, i+2))
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	
	local result = {}
	for i = 1, num_to_discard do
		if shuffled[i] then
			table.insert(result, shuffled[i])
		end
	end
	
	logAIMistake(self.player, sgs.ai_mistake_type.DISCARD_GOOD_CARD, "random_discard")
	self:speak("self_mistake", self.player:isFemale())
	
	return result
end


-- 误伤队友（伤害可以从受伤中获益的队友时计算失误）
-- 返回值：false = 触发失误，禁止伤害；true = 正常处理
function SmartAI:mistakeFriendlyFire(target, damage_value, card)
	if not target or not self:isFriend(target) then
		return true  -- 不是队友，正常处理
	end
	
	-- 保护真人玩家：永远不对真人队友失误
	if isHumanPlayer(target) then
		return true  -- 交给原有逻辑处理
	end
	
	-- 关键时刻不失误
	if isCriticalSituation(self.player) or isCriticalSituation(target) then
		return true
	end
	
	-- 使用现有AI逻辑判断队友是否能从受伤中获益
	-- 1. 检查是否能接受伤害（使用canDamageHp和canLoseHp）
	local can_damage = self:canDamageHp(self.player, card, target)
	local can_lose = self:canLoseHp(self.player, card, target)
	
	-- 2. 检查是否需要掉血（使用needToLoseHp）
	local need_lose = self:needToLoseHp(target, self.player, card, true, false)
	
	-- 如果队友既不能安全受伤，也不需要掉血，正常处理
	if not can_damage and not can_lose and not need_lose then
		return true
	end
	
	-- 计算目标当前血量和伤害值
	damage_value = damage_value or 1
	local target_hp = target:getHp()
	local adjusted_damage = self:ajustDamage(self.player, target, damage_value, card)
	
	-- 计算目标的回复能力（桃的数量）
	local peach_count = self:getAllPeachNum(target)
	
	-- 场景1: 伤害会直接打死队友（最严重）
	if target_hp <= adjusted_damage and peach_count == 0 then
		if shouldMakeMistake(0.03) then  -- 3%概率失误
			logAIMistake(self.player, sgs.ai_mistake_type.FRIENDLY_FIRE, 
				string.format("计算失误，打死队友 %s (HP:%d Damage:%d Peach:%d)", 
					target:screenName(), target_hp, adjusted_damage, peach_count))
			self:speak("self_mistake", self.player:isFemale())
			return false  -- 触发失误：禁止伤害（让原逻辑会打死队友）
		end
	end
	
	-- 场景2: 伤害会让队友进入极度危险状态（血量<=1）
	if target_hp - adjusted_damage <= 1 and peach_count == 0 then
		if shouldMakeMistake(0.02) then  -- 2%概率失误
			logAIMistake(self.player, sgs.ai_mistake_type.FRIENDLY_FIRE, 
				string.format("计算失误，队友 %s 进入危险血线 (HP:%d->%d)", 
					target:screenName(), target_hp, target_hp - adjusted_damage))
			self:speak("self_mistake", self.player:isFemale())
			return false  -- 触发失误
		end
	end
	
	-- 场景3: 过度伤害（目标只需要1点伤害获益，但造成了更多伤害）
	-- 仅当目标确实需要掉血时才检查
	if need_lose and adjusted_damage >= 2 and target_hp >= 3 then
		if shouldMakeMistake(0.025) then  -- 2.5%概率失误
			logAIMistake(self.player, sgs.ai_mistake_type.FRIENDLY_FIRE, 
				string.format("计算失误，过度伤害队友 %s (Damage:%d)", 
					target:screenName(), adjusted_damage))
			self:speak("self_mistake", self.player:isFemale())
			-- 这种情况不禁止，只是记录（送出优势）
		end
	end
	
	return true  -- 默认交给原有逻辑处理
end

-- 获取失误统计
function getAIMistakeStats()
	local stats = {}
	for mistake_type, _ in pairs(sgs.ai_mistake_type) do
		stats[mistake_type] = 0
	end
	
	for _, log in ipairs(sgs.ai_mistake_log) do
		local mtype = log.mistake_type
		stats[mtype] = (stats[mtype] or 0) + 1
	end
	
	return stats
end

-- 清空失误日志
function clearAIMistakeLog()
	sgs.ai_mistake_log = {}
end

-- 调试：打印失误统计
function printAIMistakeStats()
	local stats = getAIMistakeStats()
	print("=== AI失误统计 ===")
	for mistake_type, count in pairs(stats) do
		if count > 0 then
			print(string.format("%s: %d次", mistake_type, count))
		end
	end
	print(string.format("总计: %d次失误", #sgs.ai_mistake_log))
	print(string.format("当前失误率: %.2f%%", getAIMistakeRate() * 100))
end

-- 扩展：给不同难度设置不同的失误率
sgs.ai_difficulty_mistake_rate = {
	easy = 0.20,      -- 简单：20%失误率
	normal = 0.05,    -- 普通：5%失误率
	hard = 0.02,      -- 困难：2%失误率
	expert = 0.00,    -- 专家：0%失误率
}

-- 根据难度设置失误率
function setAIMistakeDifficulty(difficulty)
	local rate = sgs.ai_difficulty_mistake_rate[difficulty]
	if rate then
		sgs.ai_mistake_config.base_rate = rate
		print(string.format("AI失误率设置为: %.2f%% (%s)", rate * 100, difficulty))
	end
end
