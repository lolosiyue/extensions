-- Meow 隔離 AI。SmartAI 相等函式在 smart-ai-functions.lua。
-- 本檔只擴充技能名單與各 Meow handler，不改基礎層。
-- 主動技走已授權的轉化票；缺投影回 nil／unsupported，不猜成不出牌。

sgs.append_skill_list("notActive_cardneed_skill", "MeowBeige")
sgs.append_skill_list("exclusive_skill", "MeowDuanchang")
sgs.append_skill_list("Active_cardneed_skill", "MeowQiangwu")
sgs.append_skill_list("lose_equip_skill", "MeowXiaoji")
sgs.append_skill_list("jueqing_skill", "MeowJueqing")

local function relations(self, key)
    if not self.enemies or not self.friends or not self.friends_noself then
        ai_unsupported(key .. " relations are unknown", key)
    end
end

local function role_of(player)
    if not player or type(player.getRole) ~= "function" then return nil end
    local role = player:getRole()
    if role == "lord" or role == "loyalist" or role == "rebel" or role == "renegade" then return role end
    return nil
end

local function choices_of(options, key)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" or #items == 0 then
        ai_unsupported(key .. " choices are missing", key)
    end
    return items
end

local function pick(items, wanted)
    for _, choice in ipairs(items) do
        if choice == wanted then return choice end
    end
end

local function damage_of(self, key)
    local damage = self:getDecisionContext().damage
    if type(damage) ~= "table" or not damage.to then
        ai_unsupported(key .. " damage is not projected", key)
    end
    return damage
end

local function use_of(self, key)
    local use = self:getDecisionContext().use
    if type(use) ~= "table" or not use.card then
        ai_unsupported(key .. " card use is not projected", key)
    end
    return use
end

local function same(left, right)
    return left and right and left:objectName() == right:objectName()
end

local function activate(skill)
    return function(self)
        return self:playAuthorizedConversion(skill)
    end
end

local function bind_use(name, handler)
    sgs.ai_skill_use_func["#" .. name] = handler
    sgs.ai_skill_use_func[name] = handler
end

local function meow_rule(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("Meow source predicate is unknown",key) end
    return value
end

rawset(ai_skill_cardask,"@MeowBeige",nil)
sgs.ai_skill_cardask["@MeowBeige"] = function(self, data)
    local damage = data:toDamage()
    if not self:isFriend(damage.to) or self:isFriend(damage.from) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)

    if self:isFriend(damage.from)
    then
        for _, card in ipairs(cards) do
            if not self:toTurnOver(damage.from, 0)
                and card:getSuit() == sgs.Card_Spade
            then
                return "$" .. card:getEffectiveId()
            end
        end
    else
        for _, card in ipairs(cards) do
            if self:toTurnOver(damage.from, 0)
                and card:getSuit() == sgs.Card_Spade
            then
                return "$" .. card:getEffectiveId()
            end
        end
    end
    for _, card in ipairs(cards) do
        if (card:getSuit() == sgs.Card_Heart and damage.to:getHp() < getBestHp(damage.to) and self:isFriend(damage.to))
            or (card:getSuit() == sgs.Card_Diamond and self:isFriend(damage.to) and self:canDraw(damage.to))
            or (card:getSuit() == sgs.Card_Club and damage.from and self:doDisCard(damage.from, "he")) then
            return "$" .. card:getEffectiveId()
        end
    end

    local to_discard = self:askForDiscard("beige", 1, 1, false, true)
    if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

function sgs.ai_cardneed.MeowBeige(to, card)
    local count = to:getCardCount()
    if type(count) ~= "number" then return nil end
    return count <= 2
end

rawset(ai_skill_choice,"MeowBeige",nil)
sgs.ai_skill_choice["MeowBeige"] = function(self, choices, data)
    local items = choices:split("+")
    local damage = damage_of(self, "MeowBeige")
    if damage and damage.from then
        if self:isFriend(damage.from)
        then
            if not self:toTurnOver(damage.from, 0)
            then
                return "Spade"
            else
            end
        else
            if self:toTurnOver(damage.from, 0)

            then
                return "Spade"
            end

        end
    end
    if damage.to:getHp() < getBestHp(damage.to) and self:isFriend(damage.to) then
        return "Heart"
    end
    if self:isFriend(damage.to) and self:canDraw(damage.to) then
        return "Diamond"
    end
    if damage.from and self:doDisCard(damage.from, "he") then
        return "Club"
    end
    return items[math.random(1, #items)]
end

function sgs.ai_slash_prohibit.MeowDuanchang(self, from, to)
    if meow_rule(self:hasJueqingEffect(from,to),"MeowDuanchang.jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
    if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
    if from:getMaxHp() <= 3 or (from:isLord() and meow_rule(self:isWeak(from),"MeowDuanchang.weak")) then return true end
    if from:getMaxHp() <= 3 or (self.room:getLord() and meow_rule(self:getRoleEstimate(from),"MeowDuanchang.role") == "renegade") then return true end
    return false
end


-- Full fixed meow-ai.lua:99-301, retaining source sorting and target order.
local function meow_lijian_known(value, key)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil then ai_unsupported("Meowlijian source fact is unknown", key) end
    return value
end
local function meow_lijian_locked(player, card)
    return meow_lijian_known(player:isLocked(card), "Meowlijian.isLocked")
end
local function meow_lijian_log(self, text)
    -- SmartAI:log writes optional debug output only, not speech or strategy state.
    if type(self.log) == "function" then self:log(text) end
end
rawset(ai_skill_activate, "Meowlijian", nil)
sgs.ai_fill_skill.Meowlijian = function(self,inclusive,request)
    if self.player:isNude() or self.room:getAlivePlayers():length() < 3 then return end
    local n = self.player:getHandcardNum() + self.player:getEquips():length()
    if not self.player:hasSkill("Meowdoumiao") then n = n + 1 end
    if n > 1 then return self:evaluateTurnSkillCard("Meowlijian", "#MeowlijianCard", {}, request) end
end
local function use_lijian(card,use,self)
    local lord = self.room:getLord()
    local duel = meow_lijian_known(self:getEvaluationCard("duel"), "duel")
    local findFriend_maxSlash = function(self,first)
		meow_lijian_log(self, "Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng,fazheng
		for _,friend in ipairs(self.friends_noself)do
			if self:hasTrickEffective(duel,first,friend) then
				if friend:hasSkill("nosenyuan") and friend:getHp()>1 then nos_fazheng = friend end
				if friend:hasSkill("enyuan") and friend:getHp()>1 then fazheng = friend end
				if (getCardsNum("Slash",friend)>maxSlash) then
					maxSlash = getCardsNum("Slash",friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan",first) and not self:hasSkills("wuyan|noswuyan",first) then
				if (first:getHp()<=1 and first:getHandcardNum()==0) then safe = true end
			elseif (getCardsNum("Slash",friend_maxSlash)>=getCardsNum("Slash",first)) then safe = true end
			if safe then return friend_maxSlash end
		else meow_lijian_log(self, "unfound")
		end
		if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
		return nil
	end
    local n = self.player:getHandcardNum() + self.player:getEquips():length()
    if not self.player:hasSkill("Meowdoumiao") then
        n = n + 1
    end
    if n < 2 then return end
    local targets = {}
	if meow_lijian_known(self.player:getRole(), "owner_role")=="rebel" or (meow_lijian_known(self.player:getRole(), "owner_role")=="renegade" and meow_lijian_known(self:getRoleCounts().loyalist,"loyalist")+1>meow_lijian_known(self:getRoleCounts().rebel,"rebel")) then

		if lord and not lord:isNude() and lord:objectName()~=self.player:objectName() then      -- 优先离间1血忠和主
			self:sort(self.enemies,"handcard")
			local e_peaches = 0
			local loyalist

			for _,enemy in ipairs(self.enemies)do
				e_peaches = e_peaches+getCardsNum("Peach",enemy)
				if enemy:getHp()==1 and self:hasTrickEffective(duel,enemy,lord) and enemy:objectName()~=lord:objectName() and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches<1 then
                table.insert(targets, loyalist)
                table.insert(targets, lord)
            end
		end
    end
    if #targets < n then
        local shenguanyu = self.room:findPlayerBySkillName("wuhun")
        if shenguanyu and shenguanyu:objectName()~=self.player:objectName() then
            if meow_lijian_known(self.player:getRole(), "owner_role")=="rebel" and lord and lord:objectName()~=self.player:objectName() and shenguanyu:objectName()~=lord:objectName()
                and not self:hasJueqingEffect(lord,shenguanyu) and self:hasTrickEffective(duel,shenguanyu,lord) then
                table.insert(targets, shenguanyu)
            elseif self:isEnemy(shenguanyu) and #self.enemies>=2 then
                for _,enemy in ipairs(self.enemies)do
                    if enemy:objectName()~=shenguanyu:objectName() and not meow_lijian_locked(enemy,duel)
                        and self:hasTrickEffective(duel,shenguanyu,enemy) then
                        if not table.contains(targets,enemy) then
                            table.insert(targets, enemy)
                            if #targets >= n then
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if #targets < n then
        self:sort(self.enemies,"defense")
		local males,others = {},{}
		local first,second
		local zhugeliang_kongcheng,xunyu

		for _,enemy in ipairs(self.enemies)do
			if  not enemy:hasSkills("wuyan|noswuyan") then
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasSkill("jieming") then xunyu = enemy
				else
					for _,anotherenemy in ipairs(self.enemies)do
						if  anotherenemy:objectName()~=enemy:objectName() then
							if #males==0 and self:hasTrickEffective(duel,enemy,anotherenemy) then
								if not (enemy:hasSkill("hunzi") and enemy:getStrategyMark("hunzi")<1 and enemy:getHp()==2) then
									table.insert(males,enemy)
								else
									table.insert(others,enemy)
								end
							end
							if #males==1 and self:hasTrickEffective(duel,males[1],anotherenemy) then
								if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
									table.insert(males,anotherenemy)
								else
									table.insert(others,anotherenemy)
								end
							end
						end
					end
				end
			end
		end

		if #males>0 then
			if isLord(males[1]) and meow_lijian_known(self.world.turn_count,"turn_count")<=1 and meow_lijian_known(self.player:getRole(), "owner_role")=="rebel" and self.player:aliveCount()>=3 then
				local p_slash,max_p,max_pp = 0,nil,nil
				for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
					if not self:isFriend(p) and p:objectName()~=males[1]:objectName() and self:hasTrickEffective(duel,males[1],p) and not meow_lijian_locked(p,duel)
						and p_slash<getCardsNum("Slash",p) then
						if p:getKingdom()==males[1]:getKingdom() then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males,max_p) end
				if max_pp and #males==1 then table.insert(males,max_pp) end
			end
		end

		if #males>0 then
			if #others>=1 and not meow_lijian_locked(others[1],duel) then
                for _,p in ipairs(others)do
                    if not table.contains(males,p) then
				        table.insert(males,p)
                    end
                end
			elseif xunyu and not meow_lijian_locked(xunyu,duel) then
				if getCardsNum("Slash",males[1])<1 then
					table.insert(males,xunyu)
				else
					local drawcards = 0
					for _,enemy in ipairs(self.enemies)do
						local x = enemy:getMaxHp()>enemy:getHandcardNum() and math.min(5,enemy:getMaxHp()-enemy:getHandcardNum()) or 0
						if x>drawcards then drawcards = x end
					end
					if drawcards<=2 then
						table.insert(males,xunyu)
					end
				end
			end
		end

		if #males>0 and #self.friends_noself>0 then
			meow_lijian_log(self, "Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:hasTrickEffective(duel,first,zhugeliang_kongcheng) then
				table.insert(males,zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self,first)
				if friend_maxSlash then table.insert(males,friend_maxSlash) end
			end
		end

		if #males>=2 then
            for _,p in ipairs(males)do
                if not table.contains(targets,p) then
			        table.insert(targets, p)
                    if #targets >= n then
                        break
                    end
                end
            end
        end
    end
	if #targets >= 2 and n >= #targets then
		use.card = card
        for _,p in ipairs(targets)do
		    use.to:append(p)
        end
	end
end

bind_use("MeowlijianCard", use_lijian)
sgs.ai_use_value.MeowlijianCard = 8.5
sgs.ai_use_priority.MeowlijianCard = 4
sgs.ai_card_intention.MeowlijianCard = function(self, card, from, to)
    sgs.updateIntentions(from, to, 40)
end
sgs.dynamic_value.damage_card.MeowlijianCard = true
sgs.ai_suppress_intention.Meowlijian = true

ai_skill_invoke.MeowQieting = function() return true end

local function meow_turn_count(self)
    local policy=self:getResponsePolicy()
    local value=type(policy)=="table" and policy.turn_count
    if type(value)~="number" then ai_unsupported("turn count is unknown","Meowxianzhou") end
    return value
end
rawset(ai_skill_choice,"MeowQieting",nil)
sgs.ai_skill_choice.MeowQieting = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
    if table.contains(items, "draw")
        and self:isFriend(target)
    then
        return "draw"
    end
    local Equip = getChoice(choices, "get")
    local HandCard = getChoice(choices, "getHCrad")
    if target:getHandcardNum() >= 2
    then
        return HandCard
    end
    if target:hasEquip()
    then
        return Equip
    end
    if table.contains(items, "draw")
    then
        return "draw"
    end
end


rawset(ai_skill_activate,"Meowxianzhou",nil)
sgs.ai_fill_skill.Meowxianzhou = function(self,inclusive,request)
    if self.player:getEquips():isEmpty() then return end
    if self.player:getMark("@handover") == 0 then return end
    return self:evaluateTurnSkillCard("Meowxianzhou","#MeowxianzhouCard",{},request)
end

sgs.ai_skill_use_func["#MeowxianzhouCard"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local to_give = {}
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if not isCard("Peach", card, self.player)
            and not isCard("ExNihilo", card, self.player)
        then
            table.insert(to_give, card:getId())
        end
        if #to_give >= 2 and self:getOverflow() - #to_give <= 0
        then
            break
        end
    end
    if #to_give > 0
    then
        if self:isWeak() then
            for _, friend in ipairs(self.friends_noself) do
                if not hasManjuanEffect(friend) and self:canDraw(friend, self.player) then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
            self:sort(self.friends)
            for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                local canUse = true
                for _, friend in ipairs(self.friends) do
                    if target:inMyAttackRange(friend) and self:damageIsEffective(friend, nil, target)
                        and not self:needToLoseHp(friend, target)
                    then
                        canUse = false
                        break
                    end
                end
                if canUse then
                    use.card = self:evaluateTurnSkillCard("Meowxianzhou","#MeowxianzhouCard",to_give)
                    if use.to then use.to:append(target) end
                    return
                end
            end
        end
        if not self.player:isWounded() then
            local killer
            self:sort(self.friends_noself)
            for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                local canUse = false
                for _, friend in ipairs(self.friends_noself) do
                    if friend:inMyAttackRange(target) and self:damageIsEffective(target, nil, friend)
                        and not self:needToLoseHp(target, friend) and self:isWeak(target) then
                        canUse = true
                        killer = friend
                        break
                    end
                end
                if canUse then
                    use.card = self:evaluateTurnSkillCard("Meowxianzhou","#MeowxianzhouCard",to_give)
                    if use.to then use.to:append(killer) end
                    return
                end
            end
        end

        if #self.friends_noself == 0 then return end
        if self.player:getEquips():length() > 2 or self.player:getEquips():length() > #self.enemies and meow_turn_count(self) > 2 then
            local function cmp_AttackRange(a, b)
                local ar_a = a:getAttackRange()
                local ar_b = b:getAttackRange()
                if ar_a == ar_b then
                    return sgs.getDefense(a) > sgs.getDefense(b)
                else
                    return ar_a > ar_b
                end
            end
            table.sort(self.friends_noself, cmp_AttackRange)
            use.card = self:evaluateTurnSkillCard("Meowxianzhou","#MeowxianzhouCard",to_give)
            if use.to then use.to:append(self.friends_noself[1]) end
        end
    end
end

sgs.ai_use_priority.MeowxianzhouCard = 2

-- Fixed donor target policy, shared by the response and hypothetical choice.
local function meow_xianzhou_policy(self, prompt)
    local current = self.room:getCurrent()
    local num = self.player:getMark("Meowxianzhou_count")
    if self:isWeak(current) and self:isFriend(current) then return "." end
    local targets = {}
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if self.player:inMyAttackRange(enemy) and self:damageIsEffective(enemy, nil, self.player)
            and not self:needToLoseHp(enemy, self.player)
        then
            table.insert(targets, enemy:objectName())
            if #targets == tonumber(num) then break end
        end
    end
    if #targets < tonumber(num) then
        self:sort(self.friends_noself)
        self.friends_noself = sgs.reverse(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
            if self.player:inMyAttackRange(friend) and self:damageIsEffective(friend, nil, self.player)
                and not self:needToLoseHp(friend, self.player)
            then
                table.insert(targets, friend:objectName())
                if #targets == tonumber(num) then break end
            end
        end
    end
    if #targets < tonumber(num) then
        for _, target in sgs.qlist(self.room:getAlivePlayers()) do
            if not self:isFriend(target) and self:isWeak(target) then
                table.insert(targets, target:objectName())
            end
        end
    end

    if #targets > 0 and #targets <= tonumber(num) then
        return "#MeowxianzhouCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end


local function meow_response(self,skill,wire)
    if wire=="." then return wire end
    local costs,targets=wire:match("^#"..skill.."Card:([^:]+):%->(.+)$")
    if not costs then ai_unsupported("unexpected Meow response policy wire",skill) end
    local ids={}
    if costs~="." then for id in costs:gmatch("[^+]+") do ids[#ids+1]=tonumber(id) end end
    local card=self:bindSkillCard(skill,ids,nil,nil,"#"..skill.."Card")
    return {kind="use_card",card_spec=card:toCardSpec(),targets=targets:split("+")}
end
rawset(ai_skill_use,"@@Meowxianzhou",nil)
sgs.ai_skill_use["@@Meowxianzhou"]=function(self,prompt)
    return meow_response(self,"Meowxianzhou",meow_xianzhou_policy(self,prompt))
end
rawset(ai_skill_choice,"Meowxianzhou",nil)
sgs.ai_skill_choice.Meowxianzhou=function(self,choices,data)
    local target=data:toPlayer() -- retained source conversion; result is unused
    local items=choices:split("+")
    if table.contains(items,"damage") and meow_xianzhou_policy(self,"@Meowxianzhou")~="." then return "damage" end
    return "recover"
end

sgs.ai_cardneed.MeowQiangwu = sgs.ai_cardneed.slash

sgs.ai_target_revises.MeowJuxiang = function(to, card)
    if card and card:isKindOf("SavageAssault") then return true end
end

function sgs.ai_cardneed.MeowLieren(to, card, self)
    if not self or not isCard("Slash", card, to) then return false end
    local known = getKnownCard(to, self.player, "Slash", true)
    if known == nil then return nil end
    return known == 0
end

local function meow_lieren_flag(self,player,name)
    local context=self:getDecisionContext()
    local row=context and context.round23_choice
    local flags=type(row)=="table" and row.lieren_flags
    local target=type(flags)=="table" and flags[player:objectName()]
    local value=type(target)=="table" and target[name]
    if type(value)~="boolean" then ai_unsupported("Lieren broadcast flag is not projected",name) end
    return value
end
local function meow_lieren_policy(self, prompt)
    self:sort(self.enemies, "handcard")

    for _, enemy in ipairs(self.enemies) do
        if ((meow_lieren_flag(self,enemy,"MeowLierenMarkto") and meow_lieren_flag(self,self.player,"MeowLierenMarkfrom")) or not meow_lieren_flag(self,self.player,"MeowLierenMarkfrom")) and meow_lijian_known(self:canPindian(self.player,enemy),"MeowLieren.canPindian")
        then
            if self.player:getHandcardNum() == 1 then
                if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then
                    return
                        "#MeowLierenCard:.:->" .. enemy:objectName()
                end
                local card = self.player:getHandcards():first()
                if card:isKindOf("Jink") or card:isKindOf("Peach") then return "." end
            end
            if self:doDisCard(enemy, "he", true, 2) then return "#MeowLierenCard:.:->" .. enemy:objectName() end
        end
    end
    return "."
end


function sgs.ai_skill_pindian.MeowLieren(minusecard, self, requestor)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    if requestor:objectName() == self.player:objectName() then
        return cards[1]:getId()
    end
    return self:getMaxCard(self.player):getId()
end

rawset(ai_skill_use,"@@MeowLieren",nil)
sgs.ai_skill_use["@@MeowLieren"]=function(self,prompt)
    return meow_response(self,"MeowLieren",meow_lieren_policy(self,prompt))
end
rawset(ai_skill_invoke,"MeowLieren",nil)
sgs.ai_skill_invoke.MeowLieren = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
        if self.player:getHandcardNum() == 1 then
            if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return true end
            local card = self.player:getHandcards():first()
            if card:isKindOf("Jink") or card:isKindOf("Peach") then return end
        end
        if self:doDisCard(p, "he", true) then return true end
    end
    if meow_lieren_policy(self, "@MeowLieren") ~= "." then
        return true
    end
    return false
end




function sgs.ai_cardneed.MeowJizhi(to, card)
    return card:getTypeId() == sgs.Card_TypeTrick
end

rawset(ai_skill_activate,"MeowGuose",nil)
sgs.ai_fill_skill.MeowGuose = function(self,inclusive,request)
    local cards = self:addHandPile("he")
    self:sortByUseValue(cards, true)
    local card = nil
    local has_weapon, has_armor = false, false

    for _, acard in ipairs(cards) do
        if acard:isKindOf("Weapon") and not acard:getSuit() == sgs.Card_Diamond then has_weapon = true end
    end

    for _, acard in ipairs(cards) do
        if acard:isKindOf("Armor") and not acard:getSuit() == sgs.Card_Diamond then has_armor = true end
    end

    for _, acard in ipairs(cards) do
        if acard:getSuit() == sgs.Card_Diamond
            and ((self:getUseValue(acard) < sgs.ai_use_value.Indulgence) or inclusive)
        then
            local shouldUse = true

            if acard:isKindOf("Armor") then
                if not self.player:getArmor() then
                    shouldUse = false
                elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0
                then
                    shouldUse = false
                end
            end

            if acard:isKindOf("Weapon") then
                if not self.player:getWeapon() then
                    shouldUse = false
                elseif self.player:hasEquip(acard) and not has_weapon
                then
                    shouldUse = false
                end
            end

            if shouldUse then
                card = acard
                break
            end
        end
    end

    if (self.player:getMark("MeowGuoseUsed") >= 4) then return nil end
    if card then
        return self:evaluateTurnSkillCard("MeowGuose","#MeowGuoseCard2",{card:getEffectiveId()},request)
    else
        return self:evaluateTurnSkillCard("MeowGuose","#MeowGuoseCard",{},request)
    end
end

sgs.ai_skill_use_func["#MeowGuoseCard"] = function(card, use, self)
    self:sort(self.friends)


    self:setPriorityValue("#MeowGuoseCard",5.5)
    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("Indulgence")
            and self:willSkipPlayPhase(friend)
            and not friend:hasSkills("shensu|qingyi|qiaobian")
            and (self:isWeak(friend) or self:getOverflow(friend) > 1)
        then
            for _, c in sgs.list(friend:getJudgingArea()) do
                if c:isKindOf("Indulgence")
                    and self.player:canDiscard(friend, c:getEffectiveId())
                then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end

    self:setPriorityValue("#MeowGuoseCard",5.5)

    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("Indulgence")
            and self:willSkipPlayPhase(friend)
        then
            for _, c in sgs.list(friend:getJudgingArea()) do
                if c:isKindOf("Indulgence") and self.player:canDiscard(friend, c:getEffectiveId())
                then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end



    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("Indulgence") then
            for _, c in sgs.list(friend:getJudgingArea()) do
                if c:isKindOf("Indulgence") and self.player:canDiscard(friend, card:getEffectiveId()) then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end
end

sgs.ai_use_priority["#MeowGuoseCard"] = 5.5
sgs.ai_use_value["#MeowGuoseCard"] = 5
sgs.ai_card_intention["#MeowGuoseCard"] = -60

sgs.ai_skill_use_func["#MeowGuoseCard2"] = function(card, use, self)
    self:sort(self.friends)
    local id = card:getEffectiveId()

    local indulgence = self:evaluateOwnerViewAsCard({source_key="MeowGuose",skill="",name="indulgence",suit=sgs.Card_NoSuit,number=0,subcards={id}})
    if not self.player:isLocked(indulgence) then
        local dummy = self:aiUseCard(indulgence)
        if dummy.card and dummy.to:length() > 0
        then
            use.card = card
            self:setPriorityValue("#MeowGuoseCard2",sgs.ai_use_priority.Indulgence)
            if use.to then use.to = dummy.to end
            return
        end
    end
end

sgs.ai_use_priority["#MeowGuoseCard2"] = 5.5
sgs.ai_use_value["#MeowGuoseCard2"] = 5
sgs.ai_card_intention["#MeowGuoseCard2"] = -60

function sgs.ai_cardneed.MeowGuose(to, card)
    return card and card:getSuit() == sgs.Card_Diamond
end

local function meow_liuli_context(self)
    local ctx=self:getDecisionContext()
    local row=ctx and ctx.round22_choice and ctx.round22_choice.meow_liuli
    if type(row)~="table" or type(row.card)~="table" or type(row.source_flags)~="table" then
        ai_unsupported("MeowLiuli public use context is missing","MeowLiuli")
    end
    return {card=CardView.new(row.card),source_flags=row.source_flags}
end
local function meow_liuli_source(self,player)
    local value=meow_liuli_context(self).source_flags[player:objectName()]
    if type(value)~="boolean" then ai_unsupported("MeowLiuli public source flag unknown","MeowLiuli") end
    return value
end
local function meow_liuli_policy(self, prompt, method)
    local others = self.room:getOtherPlayers(self.player)
    --local slash = self.player:getTag("liuli-card"):toCard()
    local slash = meow_liuli_context(self).card
    others = sgs.QList2Table(others)
    local source
    for _, player in ipairs(others) do
        if meow_liuli_source(self,player) then
            source = player
            break
        end
    end
    self:sort(self.enemies, "defense")
    local doMeowLiuli = function(who)
        if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
            and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
            and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
            return "."
        end

        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if not meow_lijian_known(self.player:isCardLimited(card, method), "MeowLiuli.limit") and meow_lijian_known(self.player:canSlash(who), "MeowLiuli.reach") then
                if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
                    return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
                else
                    return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
                end
            end
        end

        local cards = self.player:getCards("e")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            local range_fix = 0
            if card:isKindOf("Weapon") then
                range_fix = range_fix + sgs.weapon_range[card:getClassName()] -
                    self.player:getAttackRange(false)
            end
            if card:isKindOf("OffensiveHorse") then range_fix = range_fix + 1 end
            if not meow_lijian_known(self.player:isCardLimited(card, method), "MeowLiuli.limit") and meow_lijian_known(self.player:canSlash(who, nil, true, range_fix), "MeowLiuli.rangefix") then
                return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
            end
        end
        return "."
    end
    local targets = {}
    local n = 1
    if not self.player:hasSkill("Meowdoumiao") then
        n = 2
    end
    for _, enemy in ipairs(self.enemies) do
        if not (source and source:objectName() == enemy:objectName()) then
            local ret = doMeowLiuli(enemy)
            if ret ~= "." then
                if #targets < n and n > 1 then
                    table.insert(targets, enemy:objectName())
                else
                    return ret
                end
            end
        end
    end

    for _, player in ipairs(others) do
        if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
            local ret = doMeowLiuli(player)
            if ret ~= "." then
                if #targets < n and n > 1 then
                    table.insert(targets, player:objectName())
                else
                    return ret
                end
            end
        end
    end

    self:sort(self.friends_noself, "defense")
    self.friends_noself = sgs.reverse(self.friends_noself)


    for _, friend in ipairs(self.friends_noself) do
        if not self:slashIsEffective(slash, friend) or self:findLeijiTarget(friend, 50, source) then
            if not (source and source:objectName() == friend:objectName()) then
                local ret = doMeowLiuli(friend)
                if ret ~= "." then
                    if #targets < n and n > 1 then
                        table.insert(targets, friend:objectName())
                    else
                        return ret
                    end
                end
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if self:needToLoseHp(friend, source, dummyCard())
        then
            if not (source and source:objectName() == friend:objectName()) then
                local ret = doMeowLiuli(friend)
                if ret ~= "." then
                    if #targets < n and n > 1 then
                        table.insert(targets, friend:objectName())
                    else
                        return ret
                    end
                end
            end
        end
    end

    if (self:isWeak() or self:ajustDamage(source, nil, 1, slash) > 1) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
        and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
        for _, friend in ipairs(self.friends_noself) do
            if not self:isWeak(friend) then
                if not (source and source:objectName() == friend:objectName()) then
                    local ret = doMeowLiuli(friend)
                    if ret ~= "." then
                        if #targets < n and n > 1 then
                            table.insert(targets, friend:objectName())
                        else
                            return ret
                        end
                    end
                end
            end
        end
    end

    if (self:isWeak() or self:ajustDamage(source, nil, 1, slash) > 1) and not self:getCardId("Jink") then
        for _, friend in ipairs(self.friends_noself) do
            if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
                if not (source and source:objectName() == friend:objectName()) then
                    local ret = doMeowLiuli(friend)
                    if ret ~= "." then
                        if #targets < n and n > 1 then
                            table.insert(targets, friend:objectName())
                        else
                            return ret
                        end
                    end
                end
            end
        end
    end
    if #targets > 0 then
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if not meow_lijian_known(self.player:isCardLimited(card, method), "MeowLiuli.limit") then
                return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. table.concat(targets, "+")
            end
        end
        local cards = self.player:getCards("e")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            local range_fix = 0
            if card:isKindOf("Weapon") then
                range_fix = range_fix + sgs.weapon_range[card:getClassName()] -
                    self.player:getAttackRange(false)
            end
            if card:isKindOf("OffensiveHorse") then range_fix = range_fix + 1 end
            if not meow_lijian_known(self.player:isCardLimited(card, method), "MeowLiuli.limit") then
                return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. table.concat(targets, "+")
            end
        end
    end
    return "."
end


rawset(ai_skill_use,"@@MeowLiuli",nil)
sgs.ai_skill_use["@@MeowLiuli"]=function(self,prompt,method)
    return meow_response(self,"MeowLiuli",meow_liuli_policy(self,prompt,method))
end

function sgs.ai_slash_prohibit.MeowLiuli(self, from, to, card)
    if self:isFriend(to, from) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    if to:isNude() then return false end
    for _, friend in ipairs(self:getFriends(from, true)) do
        if meow_rule(to:canSlash(friend,card),"MeowLiuli.canSlash") and meow_rule(self:slashIsEffective(card,friend,from),"MeowLiuli.effective") then return true end
    end
end

function sgs.ai_cardneed.MeowLiuli(to, card)
    return meow_rule(to:getCardCount(),"MeowLiuli.he_count") <= 2
end


local function meow_tianxiang_damage(self)
    local context=self:getDecisionContext()
    local facts=context and context.round21_choice
    local row
    if type(facts)=="table" then row=facts.meow_tianxiang_damage end
    if row==nil then ai_unsupported("owner Tianxiang damage is not projected", "MeowTianxiangDamage") end
    if row==false then return nil end
    local function player(name)
        if name==false or name==nil then return nil end
        return meow_lijian_known(self.room:findPlayerByObjectName(name,true), "MeowTianxiang.damage_player")
    end
    return {from=player(row.from),to=player(row.to),damage=meow_lijian_known(row.amount,"MeowTianxiang.amount"),
        nature=meow_lijian_known(row.nature,"MeowTianxiang.nature"),
        card=row.card and CardView.new(row.card) or nil,chain=row.chain,transfer=row.transfer}
end
local function meow_tianxiang_policy(self, data, method)
    if not method then method = sgs.Card_MethodDiscard end
    local friend_lost_hp = 10
    local friend_hp = 0
    local card_id
    local target
    local cant_use_skill
    local dmg

    if data == "@tianxiang-card" then
        dmg = meow_tianxiang_damage(self)
    else
        dmg = data
    end

    if not dmg then
        self:log(debug.traceback())
        return "."
    end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if not meow_lijian_known(self.player:isCardLimited(card, method), "MeowTianxiang.card_limit") and card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
            card_id = card:getId()
            break
        end
    end
    if not card_id then return "." end

    self:sort(self.enemies, "hp")

    for _, enemy in ipairs(self.enemies) do
        if (enemy:getHp() <= dmg.damage and enemy:isAlive() and enemy:getLostHp() + dmg.damage < 3) then
            if (enemy:getHandcardNum() <= 2 or enemy:hasSkills("guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng") or enemy:containsTrick("indulgence"))
                and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. enemy:objectName()
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if friend:getLostHp() + dmg.damage > 1 and friend:isAlive()
        then
            if friend:isChained() and dmg.nature ~= sgs.DamageStruct_Normal
                and not self:isGoodChainTarget(friend, dmg.card or dmg.nature, dmg.from, dmg.damage)
            then
            elseif friend:getHp() >= 2 and dmg.damage < 2
                and (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
                    or self:needToLoseHp(friend)
                    or (friend:getHandcardNum() < 3 and (friend:hasSkill("nosrende") or (friend:hasSkill("rende") and not friend:hasUsed("RendeCard")))))
            then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. friend:objectName()
            elseif dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick
                and friend:hasSkill("wuyan") and friend:getLostHp() > 1
            then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. friend:objectName()
            elseif hasBuquEffect(friend)
            then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. friend:objectName()
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if (enemy:getLostHp() <= 1 or dmg.damage > 1) and enemy:isAlive() and enemy:getLostHp() + dmg.damage < 4 then
            if (enemy:getHandcardNum() <= 2)
                or enemy:containsTrick("indulgence") or enemy:hasSkills("guose|leiji|vsganglie|ganglie|enyuan|qingguo|wuyan|kongcheng")
                and self:canAttack(enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. enemy:objectName()
            end
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive()
            and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
            and (not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp() > 0) or self:isWeak()) then
            return "#MeowTianxiangCard:" .. card_id .. ":->" .. enemy:objectName()
        end
    end

    return "."
end
rawset(ai_skill_use, "@@MeowTianxiang", nil)
sgs.ai_skill_use["@@MeowTianxiang"] = function(self, data, method)
    local result=meow_tianxiang_policy(self,data,method)
    if result=="." then return result end
    local id,target=result:match("^#MeowTianxiangCard:(%d+):%->(.+)$")
    if not id then ai_unsupported("unexpected source Tianxiang response", "MeowTianxiang") end
    local card=self:bindSkillCard("MeowTianxiang",{tonumber(id)},nil,nil,"#MeowTianxiangCard")
    return {kind="use_card",card_spec=card:toCardSpec(),targets={target}}
end

function sgs.ai_slash_prohibit.MeowTianxiang(self, from, to)
    local jueqing = self:hasJueqingEffect(from, to)
    if jueqing == nil then return nil end
    if jueqing or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") or self:isFriend(to, from) then return false end
    return self:cantbeHurt(to, from)
end

function sgs.ai_cardneed.MeowTianxiang(to, card, self)
    return (card:getSuit() == sgs.Card_Heart or (to:hasSkill("MeowHongyan") and card:getSuit() == sgs.Card_Spade))
        and (meow_rule(getKnownCard(to,self.player,"heart",false),"MeowTianxiang.heart") + meow_rule(getKnownCard(to,self.player,"spade",false),"MeowTianxiang.spade")) < 2
end


local function jieyi_id(self, male)
    local cards = self.player:getCards("he")
    if not cards then return nil end
    cards = self:sortByKeepValue(cards)
    if not cards then return nil end
    for _, card in ipairs(cards) do
        if card:isKindOf("EquipCard") then
            local slot = card:isKindOf("Weapon") and 0 or card:isKindOf("Armor") and 1
                or card:isKindOf("DefensiveHorse") and 2 or card:isKindOf("OffensiveHorse") and 3
                or card:isKindOf("Treasure") and 4
            if type(slot) == "number" and not male:hasEquip(slot) then
                if self.player:canDiscard(self.player, card:getEffectiveId()) then
                    return card:getEffectiveId()
                end
            end
        end
    end
    for _, card in ipairs(cards) do
        if self.player:canDiscard(self.player, card:getEffectiveId()) then
            return card:getEffectiveId()
        end
    end
    return false
end

local function use_jieyi(card, use, self)
    relations(self, "MeowJieyi")
    local function give(pool, predicate)
        for _, target in ipairs(pool) do
            if predicate(target) then
                local id = jieyi_id(self, target)
                if type(id) == "number" then
                    use.card = card
                    use.to:append(target)
                    return true
                end
            end
        end
    end
    local friends = self.friends_noself
    if self:isWeak() and self.player:getLostHp() > 0 then
        if give(friends, function(target)
            return target:getHp() > self.player:getHp() and self:canDraw(target)
        end) then return end
    end
    if give(friends, function(target)
        return self:isWeak(target) and target:getHp() < self.player:getHp() and target:getLostHp() > 0
    end) then return end
    if give(friends, function(target)
        return target:getHp() > self.player:getHp() and self:canDraw(target)
    end) then return end
end
bind_use("MeowJieyiCard", use_jieyi)
ai_skill_activate.MeowJieyi = activate("MeowJieyi")
sgs.ai_use_priority["#MeowJieyiCard"] = 0

ai_skill_choice.MeowJieyi = function(self, options)
    local items = choices_of(options, "MeowJieyi")
    local target = self:getDecisionContext().player
    if not target then ai_unsupported("MeowJieyi target is missing", "MeowJieyi") end
    local best = getBestHp(target)
    if self:isFriend(target) and type(best) == "number" and target:getHp() < best then
        sgs.updateIntention(self.player, target, -80)
        return pick(items, "yes") or "yes"
    end
    return pick(items, "no") or "no"
end

rawset(ai_skill_invoke,"MeowXiaoji_dis",nil)
sgs.ai_skill_invoke.MeowXiaoji_dis = function(self, data)
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() and
            not (enemy:hasSkill("guzheng") and self.room:getCurrent():getPhase() == sgs.Player_Discard) then
            return true
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
            return true
        end
    end
    return false
end

rawset(ai_skill_playerchosen,"MeowXiaoji",nil)
sgs.ai_skill_playerchosen.MeowXiaoji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "je") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "je") then
            return friend
        end
    end
    return nil
end

sgs.ai_use_revises.MeowXiaoji = function(self,card,use)
	if card:isKindOf("EquipCard") and meow_rule(self:evaluateArmor(card),"MeowXiaoji.armor")>-5
	then use.card = card return true end
end


local function meow_qingguo_hypothesis(self,card,request)
    local suit=card:getSuitString()
    local number=card:getNumberString()
    local id=card:getEffectiveId()
    -- Source numeric parse uses 0 for nonnumeric jokers, then single material
    -- getters inherit the printed number; the sealed recipe uses that face.
    local numeric=({A=1,J=11,Q=12,K=13})[number] or tonumber(number) or 0
    if numeric<=0 then numeric=card:getNumber() end
    return self:evaluateTurnConversion("MeowQingguo","Peach",{
        name="peach",skill="MeowQingguo",suit=card:getSuit(),number=numeric,subcards={id}},request)
end
rawset(ai_skill_activate,"MeowQingguo",nil)
sgs.ai_fill_skill.MeowQingguo = function(self,inclusive,request)
    local cards = self:addHandPile()
    self:sortByUseValue(cards, true)
    if not self.player:hasSkill("Meowdoumiao") then
        for _, c in ipairs(cards) do
            if c:isKindOf("Jink") then
                return meow_qingguo_hypothesis(self,c,request)
            end
        end
    end
end

sgs.ai_view_as.MeowQingguo=function(card,player,card_place)
    local suit=card:getSuitString()
    local number=card:getNumberString()
    local card_id=card:getEffectiveId()
    local name
    if card:isBlack() and card_place==sgs.Player_PlaceHand then name="jink"
    elseif card:isKindOf("Jink") and card_place==sgs.Player_PlaceHand and not player:hasSkill("Meowdoumiao") then name="peach" end
    if name then
        local numeric=({A=1,J=11,Q=12,K=13})[number] or tonumber(number) or 0
        if numeric<=0 then numeric=card:getNumber() end
        return {name=name,skill="MeowQingguo",suit=card:getSuit(),number=numeric,subcards={card_id}}
    end
end

function sgs.ai_cardneed.MeowQingguo(to, card)
    return meow_lijian_known(to:getHandcardNum(),"MeowQingguo.hand_count") < 2 and (card:isBlack() or card:isKindOf("Jink"))
end

rawset(ai_skill_invoke,"MeowJueqing",nil)
sgs.ai_skill_invoke.MeowJueqing = function(self, data)
    local damage = data:toDamage()
    if not damage or damage.to:isDead() or self:isFriend(damage.to) then return false end
    if self:cantDamageMore(self.player, damage.to) then return false end
    local n = damage.damage - self.player:getHp()
    if n < 0 or hasBuquEffect(self.player) or self:getSaveNum(true) >= n then return true end
    return false
end


sgs.ai_getLeastHandcardNum_skill.Meowshangshi = function(self, player, least)
	if least < player:getLostHp() then
		return math.max(player:getLostHp(), 1)
	end
end


rawset(ai_skill_invoke,"MeowZhenlie",nil)
function sgs.ai_skill_invoke.MeowZhenlie(self, data)
    local use = data:toCardUse()
    if not use.from or use.from:isDead() then return false end
    if self.role == "rebel" and meow_lijian_known(self:getRoleEstimate(use.from),"MeowZhenlie.role") == "rebel" and not use.from:hasSkill("jueqing")
        and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
        return false
    end

    if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
        if use.card:isKindOf("Slash") then
            if not self:slashIsEffective(use.card, self.player, use.from) then return false end
            if self:ajustDamage(use.from, self.player, 1, use.card) > 1 then return true end
            local jink_num = self:getExpectedJinkNum(use)
            local hasHeart = false
            for _, card in ipairs(self:getCards("Jink")) do
                if card:getSuit() == sgs.Card_Heart then
                    hasHeart = true
                    break
                end
            end
            if self:getCardsNum("Jink") == 0
                or jink_num == 0
                or self:getCardsNum("Jink") < jink_num
                or (use.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then
                if use.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, use.card, use.from) then return true end
                if use.from:hasSkill("nosqianxi") and use.from:distanceTo(self.player) == 1 then return true end
                if self:isFriend(use.from) and self.role == "loyalist" and not hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1 then return true end
                if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkill("tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]))
                    and self:doDisCard(use.from, "he") then
                    return true
                end
            end
        elseif use.card:isKindOf("AOE") then
            local from = use.from
            if use.card:isKindOf("SavageAssault") then
                local menghuo = self.room:findPlayerBySkillName("huoshou")
                if menghuo then from = menghuo end
            end

            local friend_null = 0
            for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
                if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
            end
            friend_null = friend_null + self:getCardsNum("Nullification")
            local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

            if not self:hasTrickEffective(use.card, self.player, from) then return false end
            if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then return false end
            if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end
            if sj_num == 0 and friend_null <= 0 then
                if self:isEnemy(from) and hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
                    return self:doDisCard(from, "he")
                end
                if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
                    return self:doDisCard(from, "he")
                end
                if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkill("tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()])
                        and self:doDisCard(use.from, "he")) then
                    return true
                end
            end
        elseif self:isEnemy(use.from) then
            if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
                if not self:hasTrickEffective(use.card, self.player) then return false end
                if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then return false end
                if (self.player:hasArmorEffect("vine") or self.player:getMark("&kuangfeng") > 0) and use.from:getHandcardNum() > 3
                    and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
                    return self:doDisCard(use.from, "he")
                elseif self.player:isChained() and not self:isGoodChainTarget(self.player, nil, use.from)
                then
                    return self:doDisCard(use.from, "he")
                end
            elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
                and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng()
            then
                if not self:hasTrickEffective(use.card, self.player) then return false end
                return self:doDisCard(use.from, "he")
            elseif use.card:isKindOf("Duel")
            then
                if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player)
                then
                    if not self:hasTrickEffective(use.card, self.player) then return false end
                    if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then return false end
                    return self:doDisCard(use.from, "he")
                end
            elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("AmazingGrace")
            then
                if self:doDisCard(use.from, "he") and self:needToLoseHp(self.player, nil, use.card)
                then
                    return true
                end
            end
        end
    end
    return false
end

ai_skill_invoke.MeowMiji = function() return true end

rawset(ai_skill_playerchosen,"MeowMiji",nil)
sgs.ai_skill_playerchosen.MeowMiji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
    local max = 0
    for _, p in ipairs(targets) do
        if p:getLostHp() > max then
            max = p:getLostHp()
        end
    end
    for _, p in ipairs(targets) do
        if p:getLostHp() == max then
            return p
        end
    end
    return nil
end


ai_skill_use["@@MeowMiji"] = function() return {kind = "pass"} end

rawset(ai_skill_playerchosen,"Meowdoumiao",nil)
rawset(ai_skill_invoke,"Meowdoumiao",nil)
sgs.ai_skill_invoke.Meowdoumiao = function(self, data)
    return sgs.ai_skill_playerchosen.Meowdoumiao(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_playerchosen.Meowdoumiao = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "h") or self:getDangerousCard(enemy) or self:getValuableCard(enemy) or self:hasSkills("MeowZhenlie|Meowshangshi|MeowJueqing|MeowQingguo|MeowXiaoji|MeowJizhi|MeowShenxian|MeowDuanchang|MeowBeige", enemy)) and not enemy:isNude() then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if self:doDisCard(friend, "h") or self:hasSkills("Meowxianzhou|MeowQiangwu|MeowLieren", friend) then
            return friend
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if self:doDisCard(friend, "h") then
            return friend
        end
    end
    return nil
end
ai_skill_invoke.MeowGuowu = function() return true end
sgs.ai_cardneed.MeowGuowu = sgs.ai_cardneed.slash

-- Fixed source intention callbacks; viewer state is stored in common event
-- slots so subsequent Liuli consumers read the same state, without globals.
sgs.ai_card_intention.MeowxianzhouCard = function(self, card, from, tos)
    if meow_lijian_known(from:getStrategyFlag("Meowxianzhou_target"), "Meowxianzhou_target") then
        for _, to in ipairs(tos) do
            if self:damageIsEffective(to, nil, from) and not self:needToLoseHp(to, from) then
                sgs.updateIntention(from, to, 10)
            end
        end
    else
        if not meow_lijian_known(from:isWounded(), "Meowxianzhou.wounded") then sgs.updateIntentions(from, tos, -10) end
    end
end
sgs.ai_card_intention.MeowLiuliCard = function(self, card, from, to)
    self:setCommonEventMemory("ai_liuli_effect", true)
    if not self:hasExplicitRebel() then
        self:setCommonEventMemory("ai_liuli_user", from)
    else
        self:setCommonEventMemory("ai_liuli_user", nil)
    end
end
sgs.ai_card_intention["#MeowTianxiangCard"] = function(self, card, from, tos)
    local to = tos[1]
    if self:needToLoseHp(to) then return end
    local intention = 10
    if hasBuquEffect(to) then
        intention = 0
    elseif (to:getHp() >= 2 and meow_lijian_known(to:hasSkills("yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu"), "MeowTianxiang.predicate"))
        or (to:getHandcardNum() < 3 and (meow_lijian_known(to:hasSkill("nosrende"), "MeowTianxiang.predicate") or (meow_lijian_known(to:hasSkill("rende"), "MeowTianxiang.predicate") and not meow_lijian_known(to:hasUsed("RendeCard"), "MeowTianxiang.predicate")))) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end

-- Fixed donor valuation metadata; previously omitted despite mapped callbacks.
sgs.MeowGuose_suit_value={diamond=3.9}
sgs.MeowTianxiang_suit_value={heart=4.9}

-- Source cardResponded @MeowBeige, scoped by the actual event callback key.
-- The shared public current-damage projection supplies no private response card.
sgs.ai_choicemade_filter.cardResponded["@MeowBeige"]=function(self,player,promptlist)
    local standard=self.world.strategy_facts and self.world.strategy_facts.standard
    local row=standard and standard.current_damage
    if row==nil then ai_unsupported("current public damage is unknown","MeowBeige.intention") end
    if row==false then return end
    if type(row)~="table" then ai_unsupported("current damage shape is invalid","MeowBeige.intention") end
    local target=row.to and self.room:findPlayerByObjectName(row.to,true)
    if row.to and not target then ai_unsupported("current damage target is absent","MeowBeige.intention") end
    if target and promptlist[#promptlist]~="" then sgs.updateIntention(player,target,-80) end
end
