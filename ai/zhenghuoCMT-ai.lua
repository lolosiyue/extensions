--神技
shenjiZHCMT_skill={}
shenjiZHCMT_skill.name="shenjiZHCMT"
table.insert(sgs.ai_skills,shenjiZHCMT_skill)
shenjiZHCMT_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#shenjiZHCMTCard") then return end
	if #self.enemies == 0 then return end--没有敌人f
	return sgs.Card_Parse("#shenjiZHCMTCard:.:") 
end
sgs.ai_skill_use_func["#shenjiZHCMTCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            table.insert(targets, enemy)
        end
    end
    
    if #targets > 0 then
        use.card = card
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
zhuiluZHCMT_skill={}
zhuiluZHCMT_skill.name="zhuiluZHCMT"
table.insert(sgs.ai_skills,zhuiluZHCMT_skill)
zhuiluZHCMT_skill.getTurnUseCard=function(self,inclusive)
	if not sgs.Slash_IsAvailable(self.player) then return end
	if #self.enemies == 0 then return end--敌人多
	if self.player:getMark("zhuiluZHCMT")==0 then
	return sgs.Card_Parse("#zhuiluZHCMTCard:.:") 
            end
end
sgs.ai_skill_use_func["#zhuiluZHCMTCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:hasSkill("mashu") or enemy:getMark("&mashu") > 0 then
            table.insert(targets, enemy)
        end
    end
    
    if #targets > 0 then
        use.card = card
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
        if p:objectName() ~= self.player:objectName() and p:getKingdom() ~= "wei" then
            chosen = p
            break
        end
    end
    return chosen
end
--滞横
XiansiZHCMT_skill={}
XiansiZHCMT_skill.name="XiansiZHCMT"
table.insert(sgs.ai_skills,XiansiZHCMT_skill)
XiansiZHCMT_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#XiansiZHCMTCard") then return end
	if #self.enemies == 0 then return end--没有敌人f
	return sgs.Card_Parse("#XiansiZHCMTCard:.:") 
end
sgs.ai_skill_use_func["#XiansiZHCMTCard"] = function(card, use, self)
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
        use.card = card
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
XiansiZHCMTSlash_skill={}
XiansiZHCMTSlash_skill.name="XiansiZHCMTSlash"
table.insert(sgs.ai_skills,XiansiZHCMTSlash_skill)
XiansiZHCMTSlash_skill.getTurnUseCard=function(self,inclusive)
	if not sgs.Slash_IsAvailable(self.player) then return end
	if self.player:hasUsed("#XiansiZHCMTSlashCard") then return end
	if #self.enemies == 0 then return end--敌人多
	return sgs.Card_Parse("#XiansiZHCMTSlashCard:.:") 
end
sgs.ai_skill_use_func["#XiansiZHCMTSlashCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:getPile("counter"):length() > 2 then
            table.insert(targets, enemy)

        end
    end
    
    if #targets > 0 then
        use.card = card
        for _, target in ipairs(targets) do
            if use.to then
                use.to:append(target)
            end
        end
        return
    end
end
--争嗣
zhengsiZHCMT_skill={}
zhengsiZHCMT_skill.name="zhengsiZHCMT"
table.insert(sgs.ai_skills,zhengsiZHCMT_skill)
zhengsiZHCMT_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#zhengsiZHCMTCard") then return end
	if self.player:isKongcheng() then return end--没有手牌f
	if #self.enemies < 2 then return end--敌人多
	return sgs.Card_Parse("#zhengsiZHCMTCard:.:") 
end
sgs.ai_skill_use_func["#zhengsiZHCMTCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() and #targets < 2 then
            table.insert(targets, enemy)

        end
    end
    
    if #targets > 1 then
        use.card = card
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