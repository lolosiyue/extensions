-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.


local function paid(self,skill,selector,request,old)
    local card=self:bindSkillCard(skill, {}, request, nil, selector)
    if old then card=self:inheritLegacyCardIdentity(card, old) end
    return card
end
local function slash_available(self)
    -- Slash::IsAvailable(owner) is the printed Slash's owner availability rule.
    return (self:getEvaluationCard("slash")):isAvailable(self.player)
end
--神技
sgs.ai_fill_skill.shenjiZHCMT=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#shenjiZHCMTCard") then return end
	if #self.enemies == 0 then return end--没有敌人f
	return self:legacySkillSeed("shenjiZHCMT", "#shenjiZHCMTCard", request)
end
sgs.ai_skill_use_func["#shenjiZHCMTCard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            table.insert(targets, enemy)
        end
    end

    if #targets > 0 then
        use.card = paid(self,"shenjiZHCMT","#shenjiZHCMTCard",request,card)
        local random_index = math.random(1, #targets)  -- 随机索引
        local target = targets[random_index]  -- 随机选取一个目标
            if use.to then
                use.to:append(target)
            end
        return
    end
end
sgs.ai_skill_playerchosen["#shenjiZHCMTCard"] = function(self, targets)
    local chosen = nil
    for _, p in ipairs(self.enemies) do
        if p then
            chosen = p
            break
        end
    end
    return chosen
end
--追戮
sgs.ai_fill_skill.zhuiluZHCMT=function(self,inclusive,request)
	if not slash_available(self) then return end
	if #self.enemies == 0 then return end--敌人多
	if self.player:getMark("zhuiluZHCMT")==0 then
	return self:legacySkillSeed("zhuiluZHCMT", "#zhuiluZHCMTCard", request)
            end
end
sgs.ai_skill_use_func["#zhuiluZHCMTCard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:hasSkill("mashu") or enemy:getStrategyMark("&mashu") > 0 then
            table.insert(targets, enemy)
        end
    end

    if #targets > 0 then
        use.card = paid(self,"zhuiluZHCMT","#zhuiluZHCMTCard",request,card)
        for _, target in ipairs(targets) do
            if use.to then
                use.to:append(target)
            end
        end
        return
    end
end
--甄族
sgs.ai_skill_invoke.zhenzuZHCMT = function(self, data)
    return true
end
--魏代
sgs.ai_skill_invoke.weidaiZHCMT = function(self, data)
    return true
end
sgs.ai_skill_playerchosen.weidaiZHCMT = function(self, targets)
    local chosen = nil
    for _, p in ipairs(self.enemies) do
        if p:objectName() ~= self.player:objectName() and p:getKnownKingdom() ~= "wei" then
            chosen = p
            break
        end
    end
    return chosen
end
--滞横
sgs.ai_fill_skill.XiansiZHCMT=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#XiansiZHCMTCard") then return end
	if #self.enemies == 0 then return end--没有敌人f
	return self:legacySkillSeed("XiansiZHCMT", "#XiansiZHCMTCard", request)
end
sgs.ai_skill_use_func["#XiansiZHCMTCard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local targets = {}

    -- 优先选择:
    -- 1. 手牌多的敌人
    -- 2. 有重要装备的敌人
    -- 3. 关键角色(主公、核心武将等)
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isNude() and #targets < 2 then
            table.insert(targets, enemy)

        end
    end

    if #targets > 0 then
        use.card = paid(self,"XiansiZHCMT","#XiansiZHCMTCard",request,card)
        for _, target in ipairs(targets) do
            if use.to then
                use.to:append(target)
            end
        end
        return
    end
end
sgs.ai_skill_invoke["XiansiZHCMTCard"] = false
sgs.ai_use_value["XiansiZHCMTCard"] = 4
sgs.ai_use_priority["XiansiZHCMTCard"] = 10
sgs.ai_card_intention["XiansiZHCMTCard"]  = 100
sgs.dynamic_value.control_card.XiansiZHCMTCard = true
--陷嗣
sgs.ai_fill_skill.XiansiZHCMTSlash=function(self,inclusive,request)
	if not slash_available(self) then return end
	if self.player:getStrategyHasUsed("#XiansiZHCMTSlashCard") then return end
	if #self.enemies == 0 then return end--敌人多
	return self:legacySkillSeed("XiansiZHCMTSlash", "#XiansiZHCMTSlashCard", request)
end
sgs.ai_skill_use_func["#XiansiZHCMTSlashCard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:getPileCount("counter") > 2 then
            table.insert(targets, enemy)

        end
    end

    if #targets > 0 then
        use.card = paid(self,"XiansiZHCMTSlash","#XiansiZHCMTSlashCard",request,card)
        for _, target in ipairs(targets) do
            if use.to then
                use.to:append(target)
            end
        end
        return
    end
end
--争嗣
sgs.ai_fill_skill.zhengsiZHCMT=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#zhengsiZHCMTCard") then return end
	if self.player:isKongcheng() then return end--没有手牌f
	if #self.enemies < 2 then return end--敌人多
	return self:legacySkillSeed("zhengsiZHCMT", "#zhengsiZHCMTCard", request)
end
sgs.ai_skill_use_func["#zhengsiZHCMTCard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() and #targets < 2 then
            table.insert(targets, enemy)

        end
    end

    if #targets > 1 then
        use.card = paid(self,"zhengsiZHCMT","#zhengsiZHCMTCard",request,card)
        for _, target in ipairs(targets) do
            if use.to then
                use.to:append(target)
            end
        end
        return
    end
end
sgs.ai_skill_playerchosen["#zhengsiZHCMTCard"] = function(self, targets)
    local chosen = nil
    for _, p in sgs.qlist(targets) do
        if p:objectName() ~= self.player:objectName() then
            chosen = p
        end
    end
    return chosen
end
--魂聚
sgs.ai_skill_invoke.hunjuZHCMT = function(self, data)
    if self.player:getHp() <= 2 then
        return true
    end
end
--敛财
sgs.ai_skill_invoke.liancaiZHCMT = function(self, data)
    return true
end
--诈逆
sgs.ai_skill_playerchosen.zhaniZHCMT = function(self, targets)
    local chosen = nil
    for _, p in ipairs(self.enemies) do
        if p and p:objectName() ~= self.player:objectName()  then
            chosen = p
        end
    end
    return chosen
end
