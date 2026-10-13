-- du, fixed b6025acc: preserve policy order and donor terminal incompatibilities.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("du fact is unknown",k)end;return v end
local nullable={getCard=true,getMaxCard=true,findPlayerBySkillName=true,getLord=true,getCurrent=true,getSourceLord=true,toPlayer=true,updateIntention=true,updatePlayers=true,setStrategyPlayerFlag=true}
local function q(o,k,...)
 if not o or type(o[k])~="function"then ai_unsupported("du source helper unavailable",k)end
 local method=k;if k=="getMark"and AIValue.isPlayer(o)then method="getStrategyMark"end
 local v=o[method](o,...);if AIUnsupported.is(v)then error(v,0)end
 if k=="sort"or k=="sortByKeepValue"or k=="sortByUseValue"or k=="sortByCardNeed"then local t=(...);known(v,k);for i,x in ipairs(v)do t[i]=x end;return t end
 if k=="hasSkill"or k=="hasSkills"or k=="hasLordSkill"then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local r=type(p)=="table"and rawget(p,"_view");if v==false and r and r.skills_complete~=true then ai_unsupported("du foreign skill absence unknown",(...))end end
 if nullable[k]then return v end;return known(v,k)
end
-- Whether a legacy LuaSkillCard prototype parses is an engine query that is not projected.
local function old_parse(self,selector,costs)
 ai_unsupported("du legacy prototype presence is not projected",selector)
end
local function old_response(self,selector,targets)
 ai_unsupported("du legacy prototype presence is not projected",selector)
end
local function role(self,p)return q(self,"getRoleEstimate",p)end
local function true_role(self,p)return p==self.player and q(p,"getRole")or q(self,"getRoleEstimate",p)end
local function pflag(self,p,key)
 -- Room::setPlayerFlag broadcasts, so every player's flags are projected.
 return q(p,"hasFlag",key)
end
local function global_read(self,key)
 local value,present=self:getStrategyMemory("response_source:"..key)
 if AIUnsupported.is(value)then error(value,0)end
 if present then return value==false and nil or q(self.room,"findPlayerByObjectName",value)end
 ai_unsupported("du Room-global state has not been observed by this viewer",key)
end
local function global_write(self,key,p)return q(self,"setStrategyMemory","response_source:"..key,p and q(p,"objectName")or false)end
local function source_card(self,id)
 -- jinfan's actual ipairs index bug is retained. Never peek an unoffered hidden face.
 return q(self,"getKnownCardById",id)
end
local function conversion(self,c,request)
 return q(self,"evaluateTurnConversion","jieyou","Analeptic",{name="analeptic",skill="jieyou",suit=q(c,"getSuit"),number=q(c,"getNumber"),subcards={q(c,"getEffectiveId")}},request or self.request)
end
local function source_analeptic_available(self,c)
 local row=rawget(c,"_view");local b=row and row.source_analeptic_available
 if type(b)~="boolean"then ai_unsupported("jieyou requires original Analeptic_IsAvailable fact","jieyou")end;return b
end
local function nested(reg,key,...)
 local fn=sgs[reg]and sgs[reg][key];if type(fn)~="function"then ai_unsupported("du nested source callback unavailable",reg.."."..key)end
 local v=fn(...);if AIUnsupported.is(v)then error(v,0)end;return v
end

sgs.ai_skill_invoke.jinfan = function(self, data)
    return true
end

sgs.ai_skill_choice.jinfan = function(self, choices)
    choices = choices:split("+")

    local allow = getChoice(choices, "jinfanTake_allow")
    local disallow = getChoice(choices, "jinfanTake_disallow")
    if q(self,"isFriend",q(self.room,"getCurrent")) and allow then
        return allow
    end
    return disallow
end

sgs.ai_fill_skill.jinfanTake = function(self,inclusive,request)
    if q(self.player,"hasUsed","#jfTakeCard") then
        return
    end
    for _, player in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(player,"hasSkill","jinfan") and not q(player,"getPile","du_jin"):isEmpty() then
            return old_parse(self,"#jfTakeCard",{})
        end
    end
end

sgs.ai_skill_use_func["#jfTakeCard"] = function(card, use, self)
    sgs.ai_use_priority["#jfTakeCard"] = 9.1
    if role(self,self.player) == "neutral" then
        sgs.ai_use_priority["#jfTakeCard"] = 0
    end
    if q(self.player,"hasUsed","#jfTakeCard") then
        return
    end
    local zhanglu
    local cards
    for _, player in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(player,"hasSkill","jinfan") and not q(player,"getPile","du_jin"):isEmpty() then
            zhanglu = player
            cards = q(player,"getPile","du_jin")
            break
        end
    end
    if not zhanglu or q(self,"isEnemy",zhanglu) then
        return
    end
    cards = sgs.QList2Table(cards)
    for _, pcard in ipairs(cards) do
        use.card = card
    end
    if use.to then
        use.to:append(zhanglu)
    end
end

sgs.ai_event_callback[sgs.ChoiceMade].jinfan = function(self, player, data)
    -- These two native public ChoiceMade families cannot match the source's
    -- skillChoice prefix. Reading QString has no gameplay side effect; prove
    -- this negative without demanding a private Yiji card-ID suffix.
    local details = type(data)=="table" and data.details
    if type(data)=="table" and data.kind=="choice" and type(details)=="table"
        and (details.choice_kind=="playerChosen" or details.choice_kind=="Yiji") then return end
    local datastr = q(data,"toString")
    if datastr:startsWith("skillChoice:jinfan:jinfanTake_allow") then
        q(self,"updateIntention",self.player, q(self.room,"getCurrent"), -70)
    end
end

sgs.ai_use_priority["#jfTakeCard"] = 9.1

sgs.ai_skill_askforag.jinfan = function(self, card_ids)
    local to_obtain = {}
    for card_id in ipairs(card_ids) do
        table.insert(to_obtain, source_card(self,card_id))
    end
    q(self,"sortByCardNeed",to_obtain, true)
    return q(to_obtain[1],"getEffectiveId")
end

sgs.ai_skill_use["@@duYinling"] = function(self, prompt)
    q(self,"sort",self.enemies, "handcard_defense")
    local targets = {}

    local zhugeliang = q(self.room,"findPlayerBySkillName","kongcheng")
    local luxun = q(self.room,"findPlayerBySkillName","noslianying")
    local dengai = q(self.room,"findPlayerBySkillName","tuntian")
    local jiangwei = q(self.room,"findPlayerBySkillName","zhiji")
    local zhijiangwei = q(self.room,"findPlayerBySkillName","beifa")

    local add_player = function(player, isfriend)
        if q(player,"getHandcardNum") == 0 or q(player,"objectName") == q(self.player,"objectName") then
            return #targets
        end
        if q(self,"objectiveLevel",player) == 0 and q(player,"isLord") and known(q(self,"getRoleCounts").rebel,"rebel count") > 1 then
            return #targets
        end
        if #targets == 0 then
            table.insert(targets, q(player,"objectName"))
        end
        if isfriend and isfriend == 1 then
            q(self,"setStrategyPlayerFlag",self.player,"nostuxi_isfriend_" .. q(player,"objectName"),true)
        end
        return #targets
    end

    local lord = q(self.room,"getLord")
    if lord and q(self,"isEnemy",lord) and known(self.world.turn_count,"turncount") <= 1 and not q(lord,"isKongcheng") then
        add_player(lord)
    end

    if jiangwei and q(self,"isFriend",jiangwei) and q(jiangwei,"getMark","zhiji") == 0 and q(jiangwei,"getHandcardNum") == 1 and
        q(self,"getEnemyNumBySeat",self.player, jiangwei) <= (q(jiangwei,"getHp") >= 3 and 1 or 0) then
        if add_player(jiangwei, 1) == 1 then
            return old_response(self,"#duYinlingCard",targets)
        end
    end

    if dengai and q(self,"isFriend",dengai) and
        (not q(self,"isWeak",dengai) or q(self,"getEnemyNumBySeat",self.player, dengai) == 0) and q(dengai,"hasSkill","zaoxian") and
        q(dengai,"getMark","zaoxian") == 0 and q(dengai,"getPile","field"):length() == 2 and add_player(dengai, 1) == 1 then
        return old_response(self,"#duYinlingCard",targets)
    end

    if zhugeliang and q(self,"isFriend",zhugeliang) and q(zhugeliang,"getHandcardNum") == 1 and
        q(self,"getEnemyNumBySeat",self.player, zhugeliang) > 0 then
        if q(zhugeliang,"getHp") <= 2 then
            if add_player(zhugeliang, 1) == 1 then
                return old_response(self,"#duYinlingCard",targets)
            end
        else
            local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(zhugeliang,"objectName"))
            local cards = sgs.QList2Table(q(zhugeliang,"getHandcards"))
            if #cards == 1 and (q(cards[1],"hasFlag","visible") or q(cards[1],"hasFlag",flag)) then
                if q(cards[1],"isKindOf","TrickCard") or q(cards[1],"isKindOf","Slash") or q(cards[1],"isKindOf","EquipCard") then
                    if add_player(zhugeliang, 1) == 1 then
                        return old_response(self,"#duYinlingCard",targets)
                    end
                end
            end
        end
    end

    if luxun and q(self,"isFriend",luxun) and q(luxun,"getHandcardNum") == 1 and q(self,"getEnemyNumBySeat",self.player, luxun) > 0 then
        local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(luxun,"objectName"))
        local cards = sgs.QList2Table(q(luxun,"getHandcards"))
        if #cards == 1 and (q(cards[1],"hasFlag","visible") or q(cards[1],"hasFlag",flag)) then
            if q(cards[1],"isKindOf","TrickCard") or q(cards[1],"isKindOf","Slash") or q(cards[1],"isKindOf","EquipCard") then
                if add_player(luxun, 1) == 1 then
                    return old_response(self,"#duYinlingCard",targets)
                end
            end
        end
    end

    if zhijiangwei and q(self,"isFriend",zhijiangwei) and q(zhijiangwei,"getHandcardNum") == 1 and #self.enemies > 0 and
        q(self,"getEnemyNumBySeat",self.player, zhijiangwei) <= (q(zhijiangwei,"getHp") >= 3 and 1 or 0) then
        local isGood
        for _, enemy in ipairs(self.enemies) do
            local def = q(self,"getDefenseSlash",enemy)
            local slash = q(self,"getEvaluationCard","slash")
            local eff = q(self,"slashIsEffective",slash, enemy, zhijiangwei) and
                q(self,"isGoodTarget",enemy, self.enemies, slash)
            if q(zhijiangwei,"canSlash",enemy, slash) and not q(self,"slashProhibit",slash, enemy, zhijiangwei) and eff and def <
                4 then
                isGood = true
            end
            
        end
        if isGood and add_player(zhijiangwei, 1) == 1 then
            return old_response(self,"#duYinlingCard",targets)
        end
    end

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        local cards = sgs.QList2Table(q(p,"getHandcards"))
        local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(p,"objectName"))
        for _, card in ipairs(cards) do
            if (q(card,"hasFlag","visible") or q(card,"hasFlag",flag)) and
                (q(card,"isKindOf","Peach") or q(card,"isKindOf","Nullification") or q(card,"isKindOf","Analeptic")) then
                if add_player(p) == 1 then
                    return old_response(self,"#duYinlingCard",targets)
                end
            end
        end
    end

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        if q(p,"hasSkills",
                "jijiu|qingnang|xinzhan|leiji|nosleiji|olleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|ol_tianxiang|noslijian|lijian") then
            if add_player(p) == 1 then
                return old_response(self,"#duYinlingCard",targets)
            end
        end
    end

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        local x = q(p,"getHandcardNum")
        local good_target = true
        if x == 1 and q(self,"needKongcheng",p) then
            good_target = false
        end
        if x >= 2 and q(self,"hasTuntianEffect",p) then
            good_target = false
        end
        if good_target and add_player(p) == 1 then
            return old_response(self,"#duYinlingCard",targets)
        end
    end

    if luxun and add_player(luxun, (q(self,"isFriend",luxun) and 1 or nil)) == 1 then
        return old_response(self,"#duYinlingCard",targets)
    end

    if dengai and q(self,"isFriend",dengai) and q(dengai,"hasSkill","zaoxian") and
        (not q(self,"isWeak",dengai) or q(self,"getEnemyNumBySeat",self.player, dengai) == 0) and add_player(dengai, 1) == 1 then
        return old_response(self,"#duYinlingCard",targets)
    end

    local others = q(self.room,"getOtherPlayers",self.player)
    for _, other in sgs.qlist(others) do
        if q(self,"objectiveLevel",other) >= 0 and not (q(self,"hasTuntianEffect",other, true)) and
            add_player(other) == 1 then
            return old_response(self,"#duYinlingCard",targets)
        end
    end

    for _, other in sgs.qlist(others) do
        if q(self,"objectiveLevel",other) >= 0 and not (q(self,"hasTuntianEffect",other, true)) and
            add_player(other) == 1 and math.random(0, 5) <= 1 and not q(self,"hasSkills","qiaobian") then
            return old_response(self,"#duYinlingCard",targets)
        end
    end

    return "."
end

sgs.ai_getBestHp_skill.duYinling = function(owner)
	if q(owner,"hasSkills","du_jieying+duYinling") and q(owner,"getMark","du_jieying") == 0 and q(owner,"getPile","du_jin"):length() >= 2 then
		return q(owner,"getMaxHp") - 2
	end
end

sgs.drawpeach_skill = sgs.drawpeach_skill .."|duYinling"
sgs.ai_card_intention["#duYinlingCard"] = function(self, card, from, tos)
    local lord = q(self,"getSourceLord",self.player)
    local nostuxi_lord = false
    if role(self,from) == "neutral" and role(self,tos[1]) == "neutral" and
        (not tos[2] or sgs.ai_role[tois[2]:objectName()]=="neutral") and lord and not q(lord,"isKongcheng") and
        not (q(self,"needKongcheng",lord) and q(lord,"getHandcardNum") == 1) and q(self,"hasLoseHandcardEffective",lord) and
        not (q(self,"hasTuntianEffect",lord, true)) and q(from,"aliveCount") >= 4 then
        q(self,"updateIntention",from, lord, -80)
        return
    end
    if q(from,"getState") == "online" then
        for _, to in ipairs(tos) do
            if q(to,"hasSkill","kongcheng") or q(to,"hasSkill","noslianying") or q(to,"hasSkill","zhiji") or
                (q(self,"hasTuntianEffect",to, true)) then
            else
                q(self,"updateIntention",from, to, 80)
            end
        end
    else
        for _, to in ipairs(tos) do
            if lord and q(to,"objectName") == q(lord,"objectName") then
                nostuxi_lord = true
            end
            local intention = pflag(self,from,"nostuxi_isfriend_" .. q(to,"objectName")) and -5 or 80
            q(self,"updateIntention",from, to, intention)
        end
        if known(self.world.turn_count,"turncount") == 1 and not nostuxi_lord and lord and not q(lord,"isKongcheng") and
            q(self.room,"alivePlayerCount") > 2 then
            q(self,"updateIntention",from, lord, -80)
        end
    end
end


sgs.ai_cardneed.duXiaoguo = function(to, card, self)
    return isCard("Slash", card, to) and q(self,"getKnownCard",to, self.player, "Slash", true) == 0
end

sgs.ai_skill_invoke.duXiaoguo = function(self, data)
    local damage = q(data,"toDamage")
    if not q(self,"isEnemy",damage.to) then
        return false
    end

    if q(self.player,"getHandcardNum") == 1 then
        if (q(self,"needKongcheng") or not q(self,"hasLoseHandcardEffective")) and not q(self,"isWeak") then
            return true
        end
        local card = q(self.player,"getHandcards"):first()
        if q(card,"isKindOf","Jink") or q(card,"isKindOf","Peach") then
            return
        end
    end
    if q(self,"ajustDamage",self.player,damage.to,1,damage.card) > 0 then
        return q(self,"doDisCard",damage.to, "h")
    end

    return false
end

function sgs.ai_skill_pindian.duXiaoguo(minusecard, self, requestor, maxcard)
    local cards = sgs.QList2Table(q(self.player,"getHandcards"))
    q(self,"sortByKeepValue",cards)
    if q(requestor,"objectName") == q(self.player,"objectName") then
        return cards[1]
    end
    return maxcard
end







sgs.ai_fill_skill.du_zhouxuan = function(self,inclusive,request)
    if q(self.player,"getMark","@yaochong") == 0 or not q(self.player,"canDiscard",self.player, "h") then
        return
    end
    local card_id
    local cards = q(self.player,"getHandcards")
    cards = sgs.QList2Table(cards)
    q(self,"sortByKeepValue",cards)
    local lightning = q(self,"getCard","Lightning")

    if q(self.player,"getHandcardNum") <= q(self.player,"getHp") then
        if lightning and not q(self,"willUseLightning",lightning) then
            card_id = q(lightning,"getEffectiveId")
        else
            for _, acard in ipairs(cards) do
                if (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace")) and
                    not q(acard,"isKindOf","Peach") then
                    card_id = q(acard,"getEffectiveId")
                    break
                end
            end
        end
    end
    if not card_id then
        if lightning and not q(self,"willUseLightning",lightning) then
            card_id = q(lightning,"getEffectiveId")
        else
            for _, acard in ipairs(cards) do
                if (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace")) and
                    not q(acard,"isKindOf","Peach") then
                    card_id = q(acard,"getEffectiveId")
                    break
                end
            end
        end
    end
    if not card_id then
        return nil
    else
        return old_parse(self,"#du_zhouxuanCard",{card_id})
    end
end

sgs.ai_skill_use_func["#du_zhouxuanCard"] = function(card, use, self)
    if (q(self.player,"getMark","@yaochong") > 0) then
        local target
        if q(self,"getOverflow") > 1 then
            q(self,"sort",self.friends_noself, "handcard")
            self.friends_noself = sgs.reverse(self.friends_noself)
            local jwfy = q(self.room,"findPlayerBySkillName","shoucheng")
            for _, friend in ipairs(self.friends_noself) do
                if q(friend,"isMale") then
                    if (q(friend,"hasSkill","lianying") or (jwfy and q(self,"isFriend",jwfy, friend))) or
                        (q(friend,"getHp") < 3 and q(friend,"getHandcardNum") > 1) then
                        target = friend
                        break
                    end
                end
            end
            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if q(friend,"isMale") and not q(friend,"isKongcheng") then
                        if q(friend,"getHandcardNum") > 1 then
                            target = friend
                            break
                        end
                    end
                end
            end
        else
            q(self,"sort",self.enemies, "handcard")
            self.enemies = sgs.reverse(self.enemies)
            local jwfy = q(self.room,"findPlayerBySkillName","shoucheng")
            for _, enemy in ipairs(self.enemies) do
                if q(enemy,"isMale") and not q(enemy,"hasSkill","kongcheng") then
                    if ((q(enemy,"hasSkill","lianying") or (jwfy and q(self,"isFriend",jwfy, enemy))) and
                            q(self,"damageMinusHp",enemy, 1) > 0) or
                        (q(enemy,"getHp") < 3 and q(self,"damageMinusHp",enemy, 0) > 0 and q(enemy,"getHandcardNum") > 0) or
                        (q(enemy,"getHandcardNum") >= q(enemy,"getHp") and q(enemy,"getHp") > 2 and q(self,"damageMinusHp",enemy, 0) >=
                            -1) or (q(enemy,"getHandcardNum") - q(enemy,"getHp") > 2) then
                        target = enemy
                        break
                    end
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if q(enemy,"isMale") and not q(enemy,"isKongcheng") then
                        if q(enemy,"getHandcardNum") >= q(enemy,"getHp") then
                            target = enemy
                            break
                        end
                    end
                end
            end

            if not target and (q(self,"hasCrossbowEffect") or q(self,"getCardsNum","Crossbow") > 0) then
                local slash = q(self,"getCard","Slash") or q(self,"getEvaluationCard","slash")
                for _, enemy in ipairs(self.enemies) do
                    if q(enemy,"isMale") and not q(enemy,"isKongcheng") and q(self,"slashIsEffective",slash, enemy) and
                        q(self.player,"distanceTo",enemy) == 1 and
                        not q(enemy,"hasSkills",
                            "fenyong|zhichi|fankui|vsganglie|ganglie|neoganglie|enyuan|nosenyuan|langgu|guixin|kongcheng") and
                        q(self,"getCardsNum","Slash") + q(self,"getKnownCard",enemy, self.player, "Slash") >= 3 then
                        target = enemy
                        break
                    end
                end
                
            end
        end
        if target then
            use.card = card
            if use.to then
                use.to:append(target)
                use.to:append(self.player)
            end
        end
    end
end

function sgs.ai_armor_value.duWuhun(player, self, card)
    if card and (q(card,"isKindOf","Blade") or q(card,"objectName") == "chitu") then return 4 end
end

sgs.ai_getBestHp_skill.duWuhun = function(owner)
	if q(owner,"getMark","BladeUsed") == 0 and q(owner,"getMark","ChiTuUsed") == 0 then
		return q(owner,"getMaxHp") - 1
	end
end


sgs.ai_fill_skill.jieyou = function(self,inclusive,request)
    local cards = q(self.player,"getCards","h")
    cards = sgs.QList2Table(cards)

    if q(self.player,"getPile","wooden_ox"):length() > 0 then
        for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
            table.insert(cards, q(self,"getKnownCardById",id))
        end
    end

    local card

    q(self,"sortByUseValue",cards, true)

    for _, acard in ipairs(cards) do
        if q(acard,"getSuit") == sgs.Card_Spade and ((q(acard,"getNumber") >= 2) and q(acard,"getNumber") <= 9) then
            card = acard
            break
        end
    end

    if not card then
        return nil
    end
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    local card_str = ("analeptic:jieyou[spade:%s]=%d"):format(number, card_id)
    local analeptic = conversion(self,card,request)

    if source_analeptic_available(self,analeptic) then
        assert(analeptic)
        return analeptic
    end
end

sgs.ai_view_as.jieyou = function(card, player, card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place == sgs.Player_PlaceHand or q(player,"getPile","wooden_ox"):contains(card_id) then
        if q(card,"getSuit") == sgs.Card_Spade and ((q(card,"getNumber") >= 2) and q(card,"getNumber") <= 9) then
            return {name="analeptic",skill="jieyou",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
        end
    end
end

function sgs.ai_cardneed.jieyou(to, card, self)
    return q(card,"getSuit") == sgs.Card_Spade and ((q(card,"getNumber") >= 2) and q(card,"getNumber") <= 9) and
        (q(self,"getKnownCard",to, self.player, "club", false) + q(self,"getKnownCard",to, self.player, "spade", false)) == 0
end

sgs.jieyou_suit_value = {
    spade = 5,
}

sgs.ai_suit_priority.jieyou = "diamond|heart|club|spade"

sgs.ai_skill_invoke.jiuwei = function(self, data)
    local effect = q(data,"toCardEffect")
    return q(self,"doDisCard",effect.to, "he")
end

-- jiuwei alias requires immutable shared source identity gate.

sgs.ai_skill_choice["jiuwei"] = function(self, choices, data)
    local items = choices:split("+")
    local get = getChoice(choices, "jwTake")
    local discard = getChoice(choices, "jwDrop")

    for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
        if pflag(self,p,"jiuwei_target") then
            if q(self,"isFriend",p) then
                return get
            else
                return discard
            end
        end
    end
    return items[math.random(1, #items)]
end

sgs.ai_skill_invoke.du_tongque = function(self, data)
    local dying = q(data,"toDying")
    local victim = dying.damage.to
    local role = q(self.player,"getRole")
    local list = q(self.room,"getAlivePlayers")
    local self_people = 1
    if role == "lord" then
        for _, p in sgs.qlist(list) do
            if true_role(self,p) == "loyalist" then
                self_people = self_people + 1
            end
        end
    elseif role == "rebel" then
        for _, p in sgs.qlist(list) do
            if true_role(self,p) == "rebel" and q(p,"objectName") ~= q(self.player,"objectName") then
                self_people = self_people + 1
            end
        end
    end
    if self_people >= list:length() / 2 then
        return false
    end
    return true
end

sgs.ai_skill_cardask["#caocao_tongque"] = function(self, data)
    local all_cards = q(self.player,"getCards","he")
    if all_cards:isEmpty() then
        return "."
    end
    local cards = {}
    for _, card in sgs.qlist(all_cards) do
        if not q(card,"hasFlag","using") and not q(card,"isKindOf","Peach") then
            table.insert(cards, card)
        end
    end

    if #cards > 0 then
        return "$" .. q(cards[1],"getId")
    end
    return "."
end

sgs.ai_event_callback[sgs.ChoiceMade].tongque = function(self, player, data)
    -- The native Yiji public prefix includes its exact recipient. Only a
    -- differing third field proves the source conjunction false; if it is
    -- #caocao_tongque, retain the original full-string capability requirement.
    local details=type(data)=="table" and data.details
    local parts=type(details)=="table" and details.prompt_list
    if type(data)=="table" and data.kind=="choice" and type(details)=="table"
        and details.choice_kind=="Yiji" and type(parts)=="table"
        and parts[1]=="Yiji" and type(parts[3])=="string"
        and parts[3]~="#caocao_tongque" then return end
    local datastr = q(data,"toString")
    local data_list = datastr:split(":")

    if data_list[3] == "#caocao_tongque" and data_list[4] ~= "" then



        
        local dying = q(self.room,"findPlayerByObjectName",data_list[4])
        q(self,"applyDuTongqueRole",dying)
        q(self,"updatePlayers",true)
    end
end

sgs.ai_skill_invoke.du_xixing = function(self, data)
    local target = q(data,"toPlayer")

    if q(self,"isFriend",target) then
        return false
    end
    if q(self,"isEnemy",target) then
        return q(self,"doDisCard",target, "h", true)
    end

    return true
end

sgs.ai_can_damagehp.du_xixing = function(self, from, card, to)
    if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0 and
        q(self,"canLoseHp",from, card, to) then
        return q(self,"isEnemy",from) and q(from,"getHandcardNum") > 0
    end
end

sgs.ai_skill_playerchosen.duBaonue = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if q(self,"isFriend",target) and q(target,"isAlive") then
            return target
        end
    end
    return nil
end

sgs.bad_skills = sgs.bad_skills .. "|du_jiyu"

sgs.ai_playerchosen_intention.duBaonue = -40



sgs.ai_skill_invoke["tongpao_jink"] = function(self, data)
    local lieges = q(self.room,"getLieges","wu", self.player)
    for _, p in sgs.qlist(lieges) do
        if q(self,"hasEightDiagramEffect",p) and q(self,"isFriend",p) then
            return true
        end
    end
    return q(self,"getCardsNum","Jink") == 0
end

sgs.ai_choicemade_filter.skillInvoke.tongpao_jink = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        global_write(self,"tongpaoJink",player)
    end
end

sgs.ai_choicemade_filter.cardResponded["@tongpao-jink"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if global_read(self,"tongpaoJink") then
            q(self,"updateIntention",player, global_read(self,"tongpao"), -80)
            global_write(self,"tongpaoJink",nil)
        end
    elseif global_read(self,"tongpaoJink") then
        local lieges = q(self.room,"getLieges","wu", global_read(self,"tongpaoJink"))
        if lieges and not lieges:isEmpty() then
            if q(player,"objectName") == lieges:last():objectName() then
                global_write(self,"tongpaoJink",nil)
            end
        end
    end
end

sgs.ai_skill_cardask["@tongpao-jink"] = function(self, data)
    local target = q(data,"toPlayer")
    if target and q(self,"isFriend",target) then
        return q(self,"getCardId","Jink")
    end
    return "."
end

function sgs.ai_slash_prohibit.tongpao(self, from, to, card)
    if q(self,"isFriend",to) then
        return false
    end
    if q(self,"canLiegong",to, from) then
        return false
    end
    local players = sgs.QList2Table(q(self.room,"getOtherPlayers",to))
    for _, player in ipairs(players) do
        if q(player,"getKingdom") == "wu" and q(self,"isFriend",player, to) then
            if q(player,"hasSkill","tiandu") and nested("ai_slash_prohibit","tiandu",self,from,player,card) then
                return true
            end
            if q(player,"hasLordSkill","hujia") and nested("ai_slash_prohibit","hujia",self,from,player,card) then
                return true
            end
            if q(player,"hasSkill","leiji") and nested("ai_slash_prohibit","leiji",self,from,player,card) then
                return true
            end
            if q(player,"hasSkill","weidi") and nested("ai_slash_prohibit","weidi",self,from,player,card) then
                return true
            end
        end
    end
    return false
end

sgs.ai_fill_skill.tongpaodest = function(self,inclusive,request) -- 考虑主动使用连理杀
    local slash = q(self,"getEvaluationCard","slash")
    
    if q(slash,"isAvailable",self.player) and not q(self.player,"hasFlag","Global_tongpaoFailed") then
        return q(self,"legacySkillSeed","tongpaodest","#tongpaodestCard",request or self.request)
    end
end


sgs.ai_skill_use_func["#tongpaodestCard"] = function(card, use, self)
    if q(self.player,"getKingdom") ~= "wu" and q(self.player,"hasFlag","Global_tongpaoFailed") then
        return
    end
    local slashcount = q(self,"getCardsNum","Slash")
    if slashcount > 1 and q(self,"getOverflow") > 0 then
        return
    end

    local dummy_use = { isDummy = true }
    dummy_use.to = sgs.SPlayerList()
    if q(self.player,"hasFlag","slashTargetFix") then
        for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
            if pflag(self,p,"SlashAssignee") then
                dummy_use.to:append(p)
            end
        end
    end
    local slash = q(self,"getEvaluationCard","slash")
    
    local dummy = q(self,"aiUseCard",slash)
    if dummy.card and dummy.to:length() > 0 then
        use.card = card
        for _, p in sgs.qlist(dummy.to) do
            if use.to then use.to:append(p) end
        end
    end
end

sgs.ai_use_value.tongpaodestCard = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority.tongpaodestCard = sgs.ai_use_priority.Slash + 0.1

local tongpao_filter = function(self,player,carduse)
	if q(carduse.card,"isKindOf","tongpaodestCard") then
		global_write(self,"tongpao",player)
	end
end
table.insert(sgs.ai_choicemade_filter.cardUsed,tongpao_filter)

sgs.ai_choicemade_filter.cardResponded["@tongpao-slash"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if global_read(self,"tongpaoSlash") then
            q(self,"updateIntention",player, global_read(self,"tongpaoSlash"), -80)
            global_write(self,"tongpaoSlash",nil)
        else
            local current = q(self.room,"getCurrent")
            if not current then
                return
            end
            q(self,"updateIntention",player, current, -80)
        end
    elseif global_read(self,"tongpaoSlash") then
        local lieges = q(self.room,"getLieges","wu", global_read(self,"tongpaoSlash"))
        if lieges and not lieges:isEmpty() then
            if q(player,"objectName") == lieges:last():objectName() then
                global_write(self,"tongpaoSlash",nil)
            end
        end
    end
end

sgs.ai_skill_cardask["@tongpao-slash"] = function(self, data)
    local players = q(self.room,"getOtherPlayers",self.player)
    local target = q(data,"toPlayer")
    
    if target and q(self,"isFriend",target) then
        return q(self,"getCardId","Slash")
    end
    return "."
end

sgs.ai_skill_invoke["tongpao_slash"] = function(self, data)
    local asked = q(data,"toStringList")
    local prompt = asked[2]





    local lieges = q(self.room,"getLieges","wu", self.player)
    for _, p in sgs.qlist(lieges) do
        if p and q(p,"getPhase") ~= sgs.Player_NotActive and q(self,"isFriend",p) and q(self,"getOverflow",p) > 2 and
            not q(self,"hasCrossbowEffect",p) then
            return true
        end
    end
    local cards = q(self.player,"getHandcards")
    for _, card in sgs.qlist(cards) do
        if isCard("Slash", card, self.player) then
            return false
        end
    end
    for _, p in sgs.qlist(lieges) do
        if q(self,"isFriend",p) then
            return true
        end
    end
    return false
end
sgs.ai_choicemade_filter.skillInvoke.tongpao_slash = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        global_write(self,"tongpaoSlash",player)
    end
end


sgs.ai_cardsview_valuable.tongpaodest = function(self, class_name, player)
	local current = q(self.room,"getCurrent")
	local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
    local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
    if not name then return end
	local had_card = nil
	for _, c in ipairs(handcards) do
		if q(c,"isKindOf",name) then
			had_card = c
            break
		end
	end

	if name and not q(player,"hasFlag","Global_tongpaoFailed") and had_card == nil  then
		return {skill="tongpaodest",legacy_class="#tongpaodestCard",subcards={},user_string=name}
	end
end

sgs.ai_choicemade_filter.cardResponded["@@tongpao"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if global_read(self,"tongpao") then
            q(self,"updateIntention",player, global_read(self,"tongpaoSlash"), -80)
		    global_write(self,"tongpao",nil)
        end
    elseif global_read(self,"tongpao") then
        local lieges = q(self.room,"getLieges","wu", global_read(self,"tongpaoSlash"))
        if lieges and not lieges:isEmpty() then
            if q(player,"objectName") == lieges:last():objectName() then
                global_write(self,"tongpao",nil)
            end
        end
    end
end

sgs.ai_skill_cardask["@@tongpao"] = function(self, data, pattern)
    local target = q(data,"toPlayer")
    if target and q(self,"isFriend",target) then
        local cards = q(self.player,"getCards","he")
        cards = sgs.QList2Table(cards)
        q(self,"sortByKeepValue",cards)
        for _,h in sgs.list(cards)do
            if q(self,"matchesDiscardPattern",pattern,h)
            then return q(h,"getEffectiveId") end
            if q(h,"isKindOf",pattern)
            then return q(h,"getEffectiveId") end
        end
        return q(self,"getCardId",pattern)
        
    end
    return "."
end