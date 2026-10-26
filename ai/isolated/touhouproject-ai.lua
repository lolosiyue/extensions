-- Source: b6025acc ai/touhouproject-ai.lua.
sgs.ai_ajustdamage_from.TH_guanglongzhitanxi = function(self, from, to, card, nature)
    local mark = from:getStrategyMark("@TH_yuyi")
    if AIUnsupported.is(mark) then error(mark, 0) end
    if mark == nil then ai_unsupported("source strategy mark is unknown", "@TH_yuyi") end
    if mark > 2 and not self:beFriend(to, from) then
        return 1
    end
end

do
 sgs.ai_skillInvoke_intention=sgs.ai_skillInvoke_intention or{}

 local function list(v,k)if not AIValue.isList(v)then ai_unsupported('Guanglong source player list unknown',k)end;return v end
ai_fill_skill.TH_guanglongzhitanxi = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getMark("@TH_yuyi") >= self.player:aliveCount() - 1 and self.player:getMark("@TH_yuyi") >= 3 then
		local TH_skillcard = self:evaluateTurnSkillCard("TH_guanglongzhitanxi", "#TH_guanglongzhitanxiCARD", {}, request)
		assert(TH_skillcard)
		return TH_skillcard
	end
end
ai_card_use["#TH_guanglongzhitanxiCARD"] = function(self, card, use, request)

	local targets = AIList.new({})
	for _, enemy in ipairs(list(self.enemies,"enemies")) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) and not self:needToLoseHp(enemy, self.player)
			and (not enemy:isChained() or self:isGoodChainTarget(enemy, sgs.DamageStruct_Thunder, self.player)) then
			targets:append(enemy)
			if targets:length() >= 5 then break end
		end
	end
	if targets:length() < 5 then
		for _, friend in ipairs(list(self.friends_noself,"friends_noself")) do
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

ai_skill_invoke.TH_guanglongzhitanxi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local da = data:toDamage()
	return (self:isEnemy(da.to) and self:TheWuhun(da.to) >= 0) or false
end

sgs.ai_skillInvoke_intention.TH_guanglongzhitanxi = function(from, to, yesorno, self)
	if yesorno ~= "yes" then return end
	for _, p in sgs.qlist(self.room:getOtherPlayers(from)) do
		if p:hasFlag("TH_guanglongzhitanxi_target") then sgs.updateIntention(from, p, 10) end
	end
end

-- Fixed Touhou header4-16 dispatch for this one audited registry entry.
sgs.ai_choicemade_filter.skillInvoke.TH_guanglongzhitanxi=function(self,from,promptlist)
 local reason=string.gsub(promptlist[2],"%-","_")
 local f=self.room.getCurrent
 if type(f)~="function"then ai_unsupported("Current public player unavailable","getCurrent")end
 local to=f(self.room);if AIUnsupported.is(to)then error(to,0)end
 local callback=sgs.ai_skillInvoke_intention[reason]
 if callback then
  if type(callback)=="number" and promptlist[#promptlist]=="yes" and to:objectName()~=from:objectName()then
   sgs.updateIntention(from,to,sgs.ai_skillInvoke_intention[reason])
  elseif type(callback)=="function"then callback(from,to,promptlist[#promptlist],self)end
 end
end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(from, "hasSkill", "TH_SubterraneanSun") then
            nature = "F"
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_from["TH_SubterraneanSun"]
    sgs.ai_ajustdamage_from["TH_SubterraneanSun"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_from" and context.rule == "TH_SubterraneanSun" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "TH_SubterraneanSun", {
        {phase="before_from", rule="TH_SubterraneanSun", order=4300},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["TH_terriblesouvenir"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(to,"getMark","@TH_terriblesouvenir") > 0 then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["TH_terriblesouvenir"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "TH_terriblesouvenir" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "TH_terriblesouvenir", {
        {phase="need_hp_before_damage", order=13, rule="TH_terriblesouvenir"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["TH_aoyi_sanbubisha"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","TH_aoyi_sanbubisha") and card and damage_call(card,"isKindOf","Slash") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["TH_aoyi_sanbubisha"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "TH_aoyi_sanbubisha" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "TH_aoyi_sanbubisha", {
        {phase="need_hp_before_damage", order=14, rule="TH_aoyi_sanbubisha"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["huashen"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","huashen|gongxin|mingce|ganlu|anxu|TH_SpearTheGungnir|TH_wugufengdeng|TH_Miracle_GodsWind|TH_Wonder_NwOBNS|TH_rengui|TH_nanti|"..
        	"TH_LifeGame|TH_thethiefmarisa|TH_BadFortune|TH_Hypnosis|TH_TerribleSouvenir|TH_liandemaihuo|TH_GreatestCaution|TH_GalacticIllusion|"..
        	"TH_CosmicMarionnette|TH_PhilosophersStone|TH_MoreUnscientific") then return true, true end
        return value
    end
    sgs.ai_target_damage["huashen"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "huashen" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "huashen", {
        {phase="attack_skill_available", order=1, rule="huashen"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["shuangxiong"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","shuangxiong") and q(q(to,"property","shuangxiong_colors_turn"),"toString") ~= "" and q(to,"getHandcardNum") > 3 then return true, true end
        return value
    end
    sgs.ai_target_damage["shuangxiong"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "shuangxiong" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "shuangxiong", {
        {phase="attack_skill_available", order=2, rule="shuangxiong"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["rende"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","rende|nosrende|jieyin|zhiheng|nosguose|guhuo|quhu|tianyi|dimeng|shenji|manjuan|dahe|TH_wenwenxinwen|TH_MasterSpark") and q(to,"getHandcardNum") > 1 then return true, true end
        return value
    end
    sgs.ai_target_damage["rende"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "rende" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "rende", {
        {phase="attack_skill_available", order=3, rule="rende"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["fanjian"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","fanjian|nosfanjian|qingnang|noslijian|lijian|qice|TH_huaidiao|TH_shengyusi|TH_Unscientific|TH_Science") and q(to,"getHandcardNum") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["fanjian"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "fanjian" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "fanjian", {
        {phase="attack_skill_available", order=4, rule="fanjian"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["luanji"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","luanji|paoxiao|jizhi|qixi|xianzhen|yinling") and q(to,"getHandcardNum") > 3 then return true, true end
        return value
    end
    sgs.ai_target_damage["luanji"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "luanji" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "luanji", {
        {phase="attack_skill_available", order=5, rule="luanji"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["juejing"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","juejing|fuluan|TH_chihuo") and q(q(to,"getCards","he"),"length") > 2 then return true, true end
        return value
    end
    sgs.ai_target_damage["juejing"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "juejing" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "juejing", {
        {phase="attack_skill_available", order=6, rule="juejing"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_fengyitianxiang"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_fengyitianxiang") and global("getCardsNum","FireSlash", to, self.player) > 1 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_fengyitianxiang"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_fengyitianxiang" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_fengyitianxiang", {
        {phase="attack_skill_available", order=7, rule="TH_fengyitianxiang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_huanzang"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_huanzang") and global("getCardsNum","Slash", to, self.player) > 0 then
        		for _,friend in ipairs(self.friends) do
        			if q(to,"canSlash",friend, nil, true) and q(to,"distanceTo",friend) == 1 then
        				return true, true
        			end
        		end
        	end
        return value
    end
    sgs.ai_target_damage["TH_huanzang"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_huanzang" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_huanzang", {
        {phase="attack_skill_available", order=8, rule="TH_huanzang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_GreatestTreasure"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_GreatestTreasure") and q(to,"getHandcardNum") > 1 then
        		for _,friend in ipairs(self.friends) do
        			if q(to,"distanceTo",friend) == 1 then return true, true end
        		end
        	end
        return value
    end
    sgs.ai_target_damage["TH_GreatestTreasure"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_GreatestTreasure" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_GreatestTreasure", {
        {phase="attack_skill_available", order=9, rule="TH_GreatestTreasure"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["tieji"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","tieji|wushuang|liegong|mengjin|lieren|tiaoxin|pojun|nosqianxi|TH_Eternal|TH_aoyi_sanbubisha|TH_hengong") and q(to,"getHandcardNum") > 1 then
        		for _,friend in ipairs(self.friends) do
        			if q(to,"canSlash",friend, nil, true) then
        				return true, true
        			end
        		end
        	end
        return value
    end
    sgs.ai_target_damage["tieji"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "tieji" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "tieji", {
        {phase="attack_skill_available", order=10, rule="tieji"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["lihun"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","lihun") then
        		for _,friend in ipairs(self.friends) do
        			if q(friend,"getHandcardNum") > 4 and q(friend,"isMale") then
        				return true, true
        			end
        		end
        	end
        return value
    end
    sgs.ai_target_damage["lihun"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "lihun" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "lihun", {
        {phase="attack_skill_available", order=11, rule="lihun"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_moshenfusong"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if (q(to,"hasSkill","TH_moshenfusong") and q(to,"getMark","@TH_moshenfusong") > 0) or q(to,"hasSkill","TH_jiushizhiguang") then
        		for _,enemy in ipairs(self.enemies) do
        			if q(enemy,"getHp") == 1 then
        				return true, true
        			end
        		end
        		return nil, true
        	end
        return value
    end
    sgs.ai_target_damage["TH_moshenfusong"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_moshenfusong" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_moshenfusong", {
        {phase="attack_skill_available", order=12, rule="TH_moshenfusong"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["yanxiao"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","yanxiao") then
        		local yanxiao_on
        		for _,enemy in ipairs(self.enemies) do
        			if q(enemy,"containsTrick","indulgence") or q(enemy,"containsTrick","supply_shortage") then
        				yanxiao_on = true
        			end
        		end
        		if yanxiao_on then
        			for _, card in sgs.qlist(q(to,"getCards","he")) do
        				if q(card,"getSuit") == 3 then return true, true end
        			end
        		end
        		return nil, true
        	end
        return value
    end
    sgs.ai_target_damage["yanxiao"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "yanxiao" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "yanxiao", {
        {phase="attack_skill_available", order=13, rule="yanxiao"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["nosguose"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","nosguose") and q(self,"hasSuit","diamond", true, to) then return true, true end
        return value
    end
    sgs.ai_target_damage["nosguose"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "nosguose" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "nosguose", {
        {phase="attack_skill_available", order=14, rule="nosguose"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["duanliang"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","duanliang") and q(self,"hasSuit","club", true, to) then return true, true end
        return value
    end
    sgs.ai_target_damage["duanliang"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "duanliang" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "duanliang", {
        {phase="attack_skill_available", order=15, rule="duanliang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["wansha"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if (q(to,"hasSkill","wansha") and q(to,"getMark","@chaos") > 0) or (q(to,"hasSkill","shenfen") and q(to,"getMark","@wrath") > 5) then
        		for _, p in ipairs(self.friends) do
        			if q(p,"getHp") == 1 then return true, true end
        		end
        	end
        return value
    end
    sgs.ai_target_damage["wansha"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "wansha" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "wansha", {
        {phase="attack_skill_available", order=16, rule="wansha"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["jilve"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","jilve") and q(to,"getMark","@bear") > 3 and q(to,"getMark","@waked") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["jilve"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "jilve" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "jilve", {
        {phase="attack_skill_available", order=17, rule="jilve"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_fanhundie"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_fanhundie") and q(to,"getMark","@TH_fhdonce") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_fanhundie"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_fanhundie" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_fanhundie", {
        {phase="attack_skill_available", order=18, rule="TH_fanhundie"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["jixi"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","jixi") and q(q(to,"getPile","field"),"length") > 1 and q(to,"getMark","@waked") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["jixi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "jixi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "jixi", {
        {phase="attack_skill_available", order=19, rule="jixi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["paiyi"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","paiyi") and q(q(to,"getPile","power"),"length") > 1 and q(to,"getMark","@waked") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["paiyi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "paiyi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "paiyi", {
        {phase="attack_skill_available", order=20, rule="paiyi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["yinling"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","yinling") and q(q(to,"getPile","junwei_equip"),"length") < 5 then return true, true end
        return value
    end
    sgs.ai_target_damage["yinling"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "yinling" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "yinling", {
        {phase="attack_skill_available", order=21, rule="yinling"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["qixing"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","qixing") and q(q(to,"getPile","stars"),"length") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["qixing"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "qixing" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "qixing", {
        {phase="attack_skill_available", order=22, rule="qixing"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_yinhexi"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_yinhexi") and q(q(to,"getPile","TH_yinhexi_pile"),"length") > 6 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_yinhexi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_yinhexi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_yinhexi", {
        {phase="attack_skill_available", order=23, rule="TH_yinhexi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["kurou"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","kurou") and q(to,"getHp") > 2 then return true, true end
        return value
    end
    sgs.ai_target_damage["kurou"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "kurou" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "kurou", {
        {phase="attack_skill_available", order=24, rule="kurou"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["nosshangshi"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkills","nosshangshi|shangshi") and q(to,"getLostHp") > 2 then return true, true end
        return value
    end
    sgs.ai_target_damage["nosshangshi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "nosshangshi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "nosshangshi", {
        {phase="attack_skill_available", order=25, rule="nosshangshi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["qiangxi"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","qiangxi") and (q(to,"getHp") > 2 or q(to,"getWeapon")) then return true, true end
        return value
    end
    sgs.ai_target_damage["qiangxi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "qiangxi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "qiangxi", {
        {phase="attack_skill_available", order=26, rule="qiangxi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_menghuanpaoying"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_menghuanpaoying") and q(to,"getLostHp") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_menghuanpaoying"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_menghuanpaoying" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_menghuanpaoying", {
        {phase="attack_skill_available", order=27, rule="TH_menghuanpaoying"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_huaimiepaohou"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_huaimiepaohou") and q(to,"hasFlag","TH_huaimiepaohou_on") then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_huaimiepaohou"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_huaimiepaohou" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_huaimiepaohou", {
        {phase="attack_skill_available", order=28, rule="TH_huaimiepaohou"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_Nuclear"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_Nuclear") and q(to,"getMark","@TH_nuclear") > 9 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_Nuclear"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_Nuclear" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_Nuclear", {
        {phase="attack_skill_available", order=29, rule="TH_Nuclear"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_ZombieFairy"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_ZombieFairy") and q(q(self.room,"getAlivePlayers"),"length") ~= q(q(self.room,"getPlayers"),"length") then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_ZombieFairy"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_ZombieFairy" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_ZombieFairy", {
        {phase="attack_skill_available", order=30, rule="TH_ZombieFairy"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_guanglongzhitanxi"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_guanglongzhitanxi") and q(to,"getMark","@TH_yuyi") > 1 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_guanglongzhitanxi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_guanglongzhitanxi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_guanglongzhitanxi", {
        {phase="attack_skill_available", order=31, rule="TH_guanglongzhitanxi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["TH_suiyue"]
    local policy = function(self, to, context)
        local value, q = context.value, context.query
        local global = context.extra[1]
        if q(to,"hasSkill","TH_suiyue") and q(to,"getMark","@TH_suiyue") > 0 then return true, true end
        return value
    end
    sgs.ai_target_damage["TH_suiyue"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "attack_skill_available" and context.rule == "TH_suiyue" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "TH_suiyue", {
        {phase="attack_skill_available", order=32, rule="TH_suiyue"},
    })
end)()
end
