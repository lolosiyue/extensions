local extension=sgs.Package("giantequip",sgs.Package_CardPack)
sgs.LoadTranslationTable{
    ["giantequip"] = "巨型装备包",
    ["#EquipAreaAbandoned"] = "%from 无法装备 %card ：所需装备栏已被废除",
}

sgs.LoadTranslationTable{
    ["ChongNu"] = "重弩",
    [":ChongNu"] = "装备牌，武器，攻击范围3。<br /><b>占据武器栏、-1马栏和+1马栏。</b><br />锁定技，你使用【杀】无次数限制且不可被响应。",
}

sgs.LoadTranslationTable{
    ["QixingJitan"] = "七星祭坛",
    [":QixingJitan"] = "装备牌，宝物。<br/><b>占据+1马栏、-1马栏和宝物栏。</b><br/>回合开始时，你可以令任意名角色获得【狂风】效果，直到你的下个回合开始。<br/><font color=\"#FF8C00\"><b>狂风</b></font>：当角色受到火焰伤害时，此伤害+1。",
    ["@qixingjitan-choose"] = "七星祭坛：你可以选择任意名角色，令其获得【狂风】效果",
    ["#QixingJitanGale"] = "%from 的【狂风】效果触发，火焰伤害从 %arg 点增加至 %arg2 点",
}

sgs.LoadTranslationTable{
    ["LouChuan"] = "楼船",
    [":LouChuan"] = "装备牌，坐骑。<br/><b>占据+1马栏和-1马栏。</b><br/>回合结束后，你可以与你的上家交换座次。",
    ["@louchuan-invoke"] = "楼船：你可以与你的上家交换座次",
    ["#LouChuanSwap"] = "%from 发动【楼船】，与 %to 交换座次\
    呜~呜~楼船经过\
    借过借过~",
}

sgs.LoadTranslationTable{
    ["QingnangYaoluo"] = "青囊药篓",
    [":QingnangYaoluo"] = "装备牌，宝物。<br/><b>占据宝物栏和防具栏。</b><br/>出牌阶段限一次，你可以将手牌中的若干张【毒】、【桃】或【酒】置于此装备牌上（【毒】不触发失去体力效果）。你可以将此装备上的牌如手牌般使用或打出。当此装备离开装备区且不是进入其他角色的装备区时，弃置此装备上的所有【毒】，然后你失去等量的体力。",
    ["@qingnangyaoluo-put"] = "青囊药篓：你可以将手牌中的若干张【毒】、【桃】或【酒】置于此装备牌上",
    ["#QingnangYaoluo"] = "%from 将 %arg 张牌从【青囊药篓】中%arg3了",
    ["&qingnangyaoluo"] = "药篓",  -- pile名称的翻译
}

local function log(room, kind, from, to, arg, arg2)
    local msg = sgs.LogMessage(); msg.type = kind; msg.from = from
    if to then msg.to:append(to) end
    msg.arg = arg or ""; msg.arg2 = arg2 or ""; room:sendLog(msg)
end
local function addCard(card, suit, number)
    local copy = card:clone(); copy:setSuit(suit); copy:setNumber(number); copy:setParent(extension)
end
local function movedEquip(move, name)
    for i = 0, move.card_ids:length() - 1 do
        if move.from_places:at(i) == sgs.Player_PlaceEquip
            and sgs.Sanguosha:getCard(move.card_ids:at(i)):objectName() == name then return true end
    end
    return false
end

-- 装备修正没有玩家技能实例；System 查询仍通过实际装备效果资格。
local ChongNuSlashUnlimited = sgs.CreateTargetModSkillV2{
    name = "#ChongNuSlashUnlimited", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from = ctx:getPrimary()
        if from and from:hasWeapon("ChongNu") and ctx:getModType() == sgs.TargetModSkill_Residue then return 999 end
        return false
    end,
}
local ChongNuNoRespond = sgs.CreateEquipSkillV2{
    name = "#ChongNuNoRespond", equipment = "ChongNu", equipment_type = "weapon",
    frequency = sgs.Skill_Compulsory, events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
        local use = data:toCardUse()
        if not player or not use.card or not use.card:isKindOf("Slash") then return "" end
        return self:objectName(), player
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local list = use.no_respond_list; table.insert(list, "_ALL_TARGETS"); use.no_respond_list = list
        ctx.original_data:setValue(use); return false
    end,
}
addToSkills(ChongNuSlashUnlimited)
local ChongNu = sgs.CreateWeapon{name="ChongNu", class_name="ChongNu", range=3, occupy_slots={0,2,3}, equip_skill=ChongNuNoRespond}
addCard(ChongNu, sgs.Card_Heart, 8)

local function clearGale(room)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        local count = p:getTag("qixingjitan_kuangfeng"):toInt()
        for i = 1, count do room:removePlayerMark(p, "&kuangfeng") end
        if count > 0 then p:removeTag("qixingjitan_kuangfeng") end
    end
end
local QixingJitanTrigger = sgs.CreateEquipSkillV2{
    name="#QixingJitanTrigger", equipment="QixingJitan", equipment_type="treasure",
    events={sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    on_record=function(self, event, room, player, ctx)
        -- 清理必须早于可取消的发动询问；卸装后也无需借用玩家技能实例。
        if event == sgs.EventPhaseStart then
            if player and player:isAlive() and player:getPhase() == sgs.Player_Start and player:hasTreasure("QixingJitan") then clearGale(room) end
        elseif movedEquip(ctx.original_data:toMoveOneTime(), "QixingJitan") then clearGale(room) end
    end,
    can_trigger=function(self, event, room, player, data)
        if event ~= sgs.EventPhaseStart or not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Start then return "" end
        return self:objectName(), player
    end,
    on_cost=function(self, event, room, player, ctx)
        if not player:askForSkillInvoke("QixingJitan", ctx.original_data) then return false end
        ctx.targets = room:askForPlayersChosen(player, room:getAlivePlayers(), "QixingJitan", 0, room:getAlivePlayers():length(), "@qixingjitan-choose", false, true)
        return true
    end,
    on_effect=function(self, event, room, player, ctx)
        for _, target in sgs.qlist(ctx.targets) do
            room:addPlayerMark(target, "&kuangfeng")
            target:setTag("qixingjitan_kuangfeng", sgs.QVariant(target:getTag("qixingjitan_kuangfeng"):toInt() + 1))
        end
        return false
    end,
}
local QixingJitanGale = sgs.CreateRuleSkillV2{
    name="#QixingJitanGale", frequency=sgs.Skill_Compulsory, events={sgs.DamageForseen},
    can_trigger=function(self, event, room, player, data)
        if not player or not player:isAlive() or player:getMark("&kuangfeng") <= 0 or data:toDamage().nature ~= sgs.DamageStruct_Fire then return "" end
        return self:objectName(), player
    end,
    on_effect=function(self, event, room, player, ctx)
        local damage=ctx.original_data:toDamage()
        log(room, "#QixingJitanGale", player, nil, tostring(damage.damage), tostring(damage.damage + self:getEffectiveAmount(ctx)))
        damage.damage=damage.damage+self:getEffectiveAmount(ctx); ctx.original_data:setValue(damage); return false
    end,
}
addToSkills(QixingJitanGale)
local QixingJitan=sgs.CreateTreasure{name="QixingJitan",class_name="QixingJitan",occupy_slots={2,3,4},equip_skill=QixingJitanTrigger}
addCard(QixingJitan,sgs.Card_Diamond,1)

local LouChuanTrigger=sgs.CreateEquipSkillV2{
    name="#LouChuanTrigger",equipment="LouChuan",equipment_type="offensive_horse",events={sgs.EventPhaseStart},
    can_trigger=function(self,event,room,player,data)
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Finish then return "" end
        local previous=player:getPreviousAlive()
        if not previous or previous==player then return "" end
        return self:objectName(),player
    end,
    on_cost=function(self,event,room,player,ctx) return player:askForSkillInvoke("LouChuan",ctx.original_data) end,
    on_effect=function(self,event,room,player,ctx)
        local previous=player:getPreviousAlive()
        if previous and previous~=player then room:swapSeat(player,previous);log(room,"#LouChuanSwap",player,previous) end
        return false
    end,
}
local LouChuan=sgs.CreateOffensiveHorse{name="LouChuan",class_name="LouChuan",occupy_slots={2,3},equip_skill=LouChuanTrigger}
addCard(LouChuan,sgs.Card_Club,5)

-- 通用 ActiveSkillCard 承载动作；不保留具备效果的旧 SkillCard 壳。
local QingnangYaoluoVS=sgs.CreateViewAsSkillV2{
    name="QingnangYaoluo",n=999,target_mode=sgs.ViewAsSkillV2_NoTarget,
    history_key="QingnangYaoluoCard",will_throw_selected_cards=false,
    can_activate=function(self,request)
        local player=request:getInitiator()
        return request:getReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY and player
            and not player:hasUsed("QingnangYaoluoCard") and player:hasTreasure("QingnangYaoluo")
    end,
    can_select_card=function(self,request,card)
        return not card:isEquipped()
            and (card:isKindOf("YjPoison") or card:isKindOf("Peach") or card:isKindOf("Analeptic"))
    end,
    card_selection_feasible=function(self,request) return not request:getSelectedCardIds():isEmpty() end,
    pay=function(self,room,ctx,request) return true end,
    on_effect=function(self,ctx)
        local player=ctx.invoker
        player:addMark("BanPoisonEffect")
        player:addToPile("&qingnangyaoluo",ctx.use_card:getSubcards(),false)
        player:removeMark("BanPoisonEffect")
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}
local QingnangYaoluoTrigger=sgs.CreateEquipSkillV2{
    name="QingnangYaoluo",equipment="QingnangYaoluo",equipment_type="treasure",view_as_skill=QingnangYaoluoVS,
    frequency=sgs.Skill_Compulsory,events={sgs.CardsMoveOneTime},movement_source=true,
    on_record=function(self,event,room,player,ctx)
        local move=ctx.original_data:toMoveOneTime()
        if move.from and movedEquip(move,"QingnangYaoluo") then room:addPlayerHistory(move.from,"QingnangYaoluoCard",0) end
    end,
    can_trigger=function(self,event,room,player,data)
        local move=data:toMoveOneTime()
        if move.to_place==sgs.Player_PlaceEquip and move.to and move.from then
            for _,id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):objectName()=="QingnangYaoluo" and not move.from:getPile("&qingnangyaoluo"):isEmpty() then return self:objectName(),move.to end
            end
        end
        if move.from and (movedEquip(move,"QingnangYaoluo") or move.from_pile_names:contains("&qingnangyaoluo")) then return self:objectName(),move.from end
        return ""
    end,
    on_effect=function(self,event,room,player,ctx)
        local move=ctx.original_data:toMoveOneTime()
        if move.to_place==sgs.Player_PlaceEquip and move.to==player and move.from then
            for _,id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):objectName()=="QingnangYaoluo" and not move.from:getPile("&qingnangyaoluo"):isEmpty() then
                    if player:isAlive() then
                        local viewers=sgs.SPlayerList();viewers:append(player)
                        player:addToPile("&qingnangyaoluo",move.from:getPile("&qingnangyaoluo"),false,viewers)
                    else room:throwCard(move.from:getPile("&qingnangyaoluo"),"&qingnangyaoluo",nil) end
                end
            end
        end
        if move.from==player and player:hasTreasure("QingnangYaoluo") and move.from_pile_names:contains("&qingnangyaoluo")
            and (move.reason.m_reason==sgs.CardMoveReason_S_REASON_RESPONSE or move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE) then
            local count=0
            for i=0,move.card_ids:length()-1 do if move.from_pile_names:at(i)=="&qingnangyaoluo" then count=count+1 end end
            if count>0 then
                local msg=sgs.LogMessage();msg.type="#QingnangYaoluo";msg.from=player;msg.arg=tostring(count);msg.arg2="&qingnangyaoluo"
                msg.arg3=move.reason.m_reason==sgs.CardMoveReason_S_REASON_RESPONSE and "打出" or "使用";room:sendLog(msg)
            end
        end
        if move.from==player and move.to_place~=sgs.Player_PlaceEquip and movedEquip(move,"QingnangYaoluo") then
            local poison=0
            for _,id in sgs.qlist(player:getPile("&qingnangyaoluo")) do if sgs.Sanguosha:getCard(id):isKindOf("YjPoison") then poison=poison+1 end end
            room:throwCard(player:getPile("&qingnangyaoluo"),"&qingnangyaoluo",nil)
            for i=1,poison do if player:isAlive() then room:loseHp(player,1,true,nil,"yj_poison") end end
        end
        return false
    end,
}
local QingnangYaoluo=sgs.CreateTreasure{name="QingnangYaoluo",class_name="QingnangYaoluo",occupy_slots={1,4},equip_skill=QingnangYaoluoTrigger}
addCard(QingnangYaoluo,sgs.Card_Spade,3)
return extension