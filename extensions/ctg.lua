-- 陈塘关：以 V2 实例、成本和效果管线保留 HUMAN donor 内容。
local extension = sgs.Package("ctg", sgs.Package_GeneralPack)
createMode {name="陈塘关模式", class="ctg", roles="ZCCCCC", skipChooseGeneral=true, showRole=true}
local ctg_nazha = sgs.General(extension, "ctg_nazha", "god", 3)
local ctg_xilong = sgs.General(extension, "ctg_xilong", "god", 4)
local ctg_donglong = sgs.General(extension, "ctg_donglong", "god", 4)
local ctg_beilong = sgs.General(extension, "ctg_beilong", "god", 4)
local ctg_nanlong = sgs.General(extension, "ctg_nanlong", "god", 4)
local villagers = {}
for i=1,4 do
    local general = sgs.General(extension, "ctg_cunmin"..i, "qun", 3, i%2==1, true)
    general:setImage("villager-"..i)
    table.insert(villagers, general)
end
local function refs(player, name, predicate)
    if not player then return false end
    local names = {}
    for _, id in sgs.qlist(player:getValidSkillInstanceIds(name)) do
        if not predicate or predicate(id) then table.insert(names, name.."#"..id) end
    end
    return #names>0 and table.concat(names,"+") or false
end
local function state(player, name, id, key)
    return player:getSkillInstanceStateValue(name, id, key)
end
local function setstate(player, name, id, key, value)
    player:setSkillInstanceStateValue(name, id, key, sgs.QVariant(value))
end
local function log(room, kind, from, to, arg, arg2)
    local msg=sgs.LogMessage(); msg.type=kind; msg.from=from
    if to then msg.to:append(to) end
    msg.arg=arg or ""; msg.arg2=arg2 or ""; room:sendLog(msg)
end
local function play_request(skill, request)
    local player=request:getInitiator()
    return player and player:isAlive() and request:getReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
end
local function single_other(skill, request, selected, candidate)
    return #selected==0 and candidate and candidate:isAlive() and candidate~=request:getInitiator()
end
local function one_target(skill, request, selected) return #selected==1 end
-- 所有无牌自定义动作使用原生 ActiveSkillCard；次数由 activation instance 计数。
local function once_action(spec)
    spec.n=0; spec.limit_scope=sgs.Skill_Limit_Phase; spec.phase_name="Play"; spec.max_usage_limit=1
    spec.can_activate=spec.can_activate or play_request
    return sgs.CreateViewAsSkillV2(spec)
end
local ctg_youmin=sgs.CreateTriggerSkillV2 {
    name="ctg_youmin", events={sgs.EventPhaseStart,sgs.DamageInflicted},
    on_record=function(skill,event,room,player,ctx)
        local p=ctx.owner
        if event~=sgs.EventPhaseStart or not p or ctx.invoker~=p or p:getPhase()~=sgs.Player_Start then return end
        local protected=state(p,skill:objectName(),ctx.instanceID,"protected"):toString():split("+")
        for _,q in sgs.qlist(room:getAllPlayers()) do
            if table.contains(protected,q:objectName()) and q:getMark("&ctg_youmin_protect")>0 then q:loseMark("&ctg_youmin_protect") end
        end
        setstate(p,skill:objectName(),ctx.instanceID,"protected","")
    end,
    can_trigger=function(skill,event,room,player,data)
        if not player or not player:isAlive() then return false end
        if event==sgs.EventPhaseStart then
            if player:getPhase()==sgs.Player_Start and room:alivePlayerCount()>=4 then return refs(player,skill:objectName()) end
        else
            for _,q in sgs.qlist(room:getAlivePlayers()) do
                if q~=player then
                    local names=refs(q,skill:objectName(),function(id)
                        return table.contains(state(q,skill:objectName(),id,"protected"):toString():split("+"),player:objectName())
                    end)
                    if names then return names,q end
                end
            end
        end
        return false
    end,
    on_cost=function(skill,event,room,player,ctx)
        if event==sgs.DamageInflicted then return true end -- donor 的转移是自动执行。
        local seat=player:getSeat()+math.floor(room:alivePlayerCount()/2)
        if seat>room:alivePlayerCount() then seat=seat-room:alivePlayerCount() end
        local opposite
        for _,q in sgs.qlist(room:getAlivePlayers()) do if q:getSeat()==seat then opposite=q; break end end
        if not opposite or not room:askForSkillInvoke(player,skill:objectName()) then return false end
        local choice=room:askForChoice(player,skill:objectName(),"clockwise+counterclockwise")
        ctx.extra_data=sgs.QVariant(choice)
        ctx.targets:append(opposite)
        return true
    end,
    on_effect=function(skill,event,room,player,ctx)
        if event==sgs.DamageInflicted then
            local damage=ctx.original_data:toDamage()
            local moved=sgs.DamageStruct(); moved.from=damage.from; moved.to=player
            moved.damage=damage.damage; moved.nature=damage.nature; moved.reason=damage.reason
            moved.transfer=true; moved.by_user=false; moved.card=damage.card
            log(room,"#ctg_youmin_transfer",player,damage.to,tostring(damage.damage))
            room:broadcastSkillInvoke(skill:objectName()); room:damage(moved); return true
        end
        local choice=ctx.extra_data:toString(); local opposite=ctx.targets:first()
        local path=choice=="clockwise" and room:getClockwisePath(player,opposite) or room:getCounterclockwisePath(player,opposite)
        local names={}
        for _,q in sgs.qlist(path) do q:gainMark("&ctg_youmin_protect"); table.insert(names,q:objectName()) end
        setstate(player,skill:objectName(),ctx.instanceID,"protected",table.concat(names,"+"))
        room:broadcastSkillInvoke(skill:objectName())
        log(room,"#ctg_youmin_protect",player,nil,choice,tostring(path:length()))
        return false
    end,
}
ctg_nazha:addSkill(ctg_youmin)
local ctg_faqi=sgs.CreateTriggerSkillV2 {
    name="ctg_faqi", events={sgs.GameStart},
    can_trigger=function(skill,event,room,player,data) return player and player:isAlive() and refs(player,skill:objectName()) end,
    on_cost=function(skill,event,room,player,ctx)
        ctx.extra_data=sgs.QVariant(room:askForChoice(player,skill:objectName(),"_qiankunquan+_huntianling",sgs.QVariant(),nil,"ctg_weapon")); return true
    end,
    on_effect=function(skill,event,room,player,ctx)
        local id=player:getDerivativeCard(ctx.extra_data:toString(),sgs.Player_PlaceTable)
        if id>0 then room:obtainCard(player,id); room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(id),player,player)) end
        return false
    end,
}
ctg_nazha:addSkill(ctg_faqi)
local ctg_danyuan=sgs.CreateTriggerSkillV2 {
    name="ctg_danyuan", events={sgs.EventPhaseStart},
    can_trigger=function(skill,event,room,player,data)
        return player and player:isAlive() and player:getPhase()==sgs.Player_Start and player:getMark("&charge_num")>0 and refs(player,skill:objectName())
    end,
    on_cost=function(skill,event,room,player,ctx) return room:askForSkillInvoke(player,skill:objectName()) end,
    on_pay=function(skill,event,room,player,ctx)
        if player:getMark("&charge_num")<1 then return false end
        player:loseMark("&charge_num",1); return true
    end,
    on_effect=function(skill,event,room,player,ctx)
        room:broadcastSkillInvoke(skill:objectName())
        local choices={}
        for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
            local general=sgs.Sanguosha:getGeneral(name)
            if general and not general:isTotallyHidden() then
                for _,candidate in sgs.qlist(general:getVisibleSkillList()) do
                    if not player:hasSkill(candidate:objectName()) and string.find(candidate:getDescription() or "","杀") then table.insert(choices,candidate:objectName()) end
                end
            end
        end
        if #choices>3 then
            local selected={}
            for i=1,3 do local index=math.random(1,#choices); table.insert(selected,choices[index]); table.remove(choices,index) end
            choices=selected
        end
        if #choices>0 then
            local chosen=room:askForChoice(player,skill:objectName(),table.concat(choices,"+"))
            room:acquireSkill(player,chosen); log(room,"#ctg_danyuan_acquire",player,nil,chosen)
        end
        room:sendCompulsoryTriggerLog(player,skill:objectName()); return false
    end,
}
ctg_danyuan:setProperty("ChargeNum",ToData("4/4")); ctg_nazha:addSkill(ctg_danyuan)
local ctg_xianzeVS=once_action {
    name="ctg_xianze", target_mode=sgs.ViewAsSkillV2_NoTarget,
    cost=function(skill,room,ctx,request)
        ctx.extra_data=sgs.QVariant(room:askForChoice(ctx.invoker,skill:objectName(),"recover+protect"))
        if ctx.extra_data:toString()=="recover" then
            local injured=sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do if p:isWounded() then injured:append(p) end end
            if not injured:isEmpty() then
                local target=room:askForPlayerChosen(ctx.invoker,injured,skill:objectName(),"@ctg_xianze_recover",false,true)
                if target then ctx.targets:append(target) end
            end
        end
        return true
    end,
    on_effect=function(skill,ctx)
        local p=ctx.invoker; local room=p:getRoom()
        if ctx.extra_data:toString()=="recover" then
            if not ctx.targets:isEmpty() then local target=ctx.targets:first(); room:recover(target,sgs.RecoverStruct(skill:objectName(),p,1)); log(room,"#ctg_xianze_recover",p,target) end
        else
            setstate(p,skill:objectName(),ctx.instanceID,"protect",state(p,skill:objectName(),ctx.instanceID,"protect"):toInt()+1)
            p:gainMark("&ctg_xianze_protect"); log(room,"#ctg_xianze_protect",p)
        end
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}
local ctg_xianze=sgs.CreateTriggerSkillV2 {
    name="ctg_xianze", events={sgs.DamageInflicted,sgs.EventPhaseStart}, view_as_skill=ctg_xianzeVS,
    on_record=function(skill,event,room,player,ctx)
        local p=ctx.owner
        if event==sgs.EventPhaseStart and p and ctx.invoker==p and p:getPhase()==sgs.Player_Start and state(p,skill:objectName(),ctx.instanceID,"protect"):toInt()>0 then
            p:loseMark("&ctg_xianze_protect",state(p,skill:objectName(),ctx.instanceID,"protect"):toInt()); setstate(p,skill:objectName(),ctx.instanceID,"protect",0)
        end
    end,
    can_trigger=function(skill,event,room,player,data)
        if event~=sgs.DamageInflicted or not player or not player:isAlive() then return false end
        return refs(player,skill:objectName(),function(id) return state(player,skill:objectName(),id,"protect"):toInt()>0 end)
    end,
    on_pay=function(skill,event,room,player,ctx)
        if state(player,skill:objectName(),ctx.instanceID,"protect"):toInt()<1 then return false end
        setstate(player,skill:objectName(),ctx.instanceID,"protect",state(player,skill:objectName(),ctx.instanceID,"protect"):toInt()-1); player:loseMark("&ctg_xianze_protect"); return true
    end,
    on_effect=function(skill,event,room,player,ctx) log(room,"#ctg_xianze_prevent",player); return true end,
}
ctg_nazha:addSkill(ctg_xianze)
local ctg_kuijue=sgs.CreateTriggerSkillV2 {
    name="ctg_kuijue", frequency=sgs.Skill_Compulsory, events={sgs.Death},
    can_trigger=function(skill,event,room,player,data) return player and data:toDeath().who==player and refs(player,skill:objectName()) end,
    on_effect=function(skill,event,room,player,ctx)
        room:sendCompulsoryTriggerLog(player,skill:objectName())
        -- 保留 donor 死亡座次算法及主公重复受到失去体力的语义。
        local nextPlayer=player:getNextAlive(); local previous=player:getPreviousAlive():getNextAlive()
        for _,p in ipairs({nextPlayer,previous}) do if p and p~=player then room:loseHp(p,1); log(room,"#ctg_kuijue_adjacent",player,p) end end
        local lord=room:getLord(); if lord and lord~=player then room:loseHp(lord,1); log(room,"#ctg_kuijue_lord",player,lord) end
        return false
    end,
}
local ctg_libo=sgs.CreateTriggerSkillV2 {
    name="ctg_libo",frequency=sgs.Skill_Compulsory,events={sgs.EventPhaseChanging},
    can_trigger=function(skill,event,room,player,data)
        return player and player:isAlive() and data:toPhaseChange().to==sgs.Player_Play and refs(player,skill:objectName())
    end,
    on_effect=function(skill,event,room,player,ctx) player:skip(sgs.Player_Play); return false end,
}
addToSkills(ctg_kuijue); addToSkills(ctg_libo)
for _,g in ipairs(villagers) do g:addSkill("ctg_kuijue"); g:addSkill("ctg_libo") end
local dragons={ctg_xilong=true,ctg_donglong=true,ctg_beilong=true,ctg_nanlong=true}
local function dragon_slot(player)
    if dragons[player:getGeneralName()] then return player:getGeneralName(),false end
    if dragons[player:getGeneral2Name()] then return player:getGeneral2Name(),true end
end
local function parse_pool(value)
    local pool={}
    for _,entry in ipairs(value:split("+")) do local parts=entry:split(":"); if #parts==3 then pool[parts[1]]={hp=tonumber(parts[2]),maxhp=tonumber(parts[3])} end end
    return pool
end
local function save_pool(player,pool)
    local entries={}; for name,value in pairs(pool) do table.insert(entries,name..":"..value.hp..":"..value.maxhp) end
    player:setTag("DragonPool",sgs.QVariant(table.concat(entries,"+")))
end
local function transform(room,player,name,pool,secondary)
    local hp=pool[name].hp; local maxhp=pool[name].maxhp
    room:changeHero(player,name,false,false,secondary,true)
    room:setPlayerProperty(player,"hp",ToData(hp)); room:setPlayerProperty(player,"maxhp",ToData(maxhp))
end
local ctg_lunxianVS=once_action {
    name="ctg_lunxian",target_mode=sgs.ViewAsSkillV2_NoTarget,
    can_activate=function(skill,request)
        -- 换将会销毁旧实例；donor 的本阶段门闩必须跨换将保存。
        return play_request(skill,request) and request:getInitiator():getMark("ctg_lunxian-PlayClear")==0
    end,
    cost=function(skill,room,ctx,request)
        local p=ctx.invoker; local current=dragon_slot(p); local pool=parse_pool(p:getTag("DragonPool"):toString()); local choices={}
        for name in pairs(pool) do if name~=current then table.insert(choices,name) end end
        if #choices==0 then return false end
        ctx.extra_data=sgs.QVariant(room:askForChoice(p,skill:objectName(),table.concat(choices,"+"))); return true
    end,
    pay=function(skill,room,ctx,request) room:addPlayerMark(ctx.invoker,"ctg_lunxian-PlayClear"); return true end,
    on_effect=function(skill,ctx)
        local p=ctx.invoker; local room=p:getRoom(); local current,secondary=dragon_slot(p)
        local pool=parse_pool(p:getTag("DragonPool"):toString()); local chosen=ctx.extra_data:toString()
        if current and pool[chosen] then
            pool[current]={hp=p:getHp(),maxhp=p:getMaxHp()}; transform(room,p,chosen,pool,secondary); save_pool(p,pool)
            log(room,"#ctg_lunxian_transform",p,nil,chosen)
        end
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}
local ctg_lunxian=sgs.CreateTriggerSkillV2 {
    name="ctg_lunxian",events={sgs.GameStart,sgs.BeforeGameOverJudge},view_as_skill=ctg_lunxianVS,
    can_trigger=function(skill,event,room,player,data)
        if not player or not dragon_slot(player) then return false end
        if event==sgs.BeforeGameOverJudge and (data:toDeath().who~=player or player:getMaxHp()<=0 or not next(parse_pool(player:getTag("DragonPool"):toString()))) then return false end
        return refs(player,skill:objectName())
    end,
    on_effect=function(skill,event,room,player,ctx)
        if event==sgs.GameStart then
            player:setTag("DragonPool",sgs.QVariant("ctg_xilong:4:4+ctg_donglong:4:4+ctg_beilong:4:4+ctg_nanlong:4:4")); return false
        end
        -- Preserve the donor's main-general pool removal, including deputy setups.
        local pool=parse_pool(player:getTag("DragonPool"):toString()); local current=player:getGeneralName()
        pool[current]=nil; save_pool(player,pool)
        room:restPlayer(player,skill:objectName(),true)
        player:setTag("RestTurn",sgs.QVariant(room:getTag("TurnLengthCount"):toInt())); player:setTag("LunxianRestActive",sgs.QVariant(true))
        log(room,"#ctg_lunxian_rest",player); return true
    end,
}
for _,g in ipairs({ctg_xilong,ctg_donglong,ctg_beilong,ctg_nanlong}) do g:addSkill(ctg_lunxian) end
-- 休整后无有效玩家实例，以显式规则继续 donor 已建立的休整状态。
local ctg_lunxian_rest=sgs.CreateRuleSkillV2 {
    name="#ctg_lunxian_rest",events={sgs.EventPhaseStart},
    can_trigger=function(skill,event,room,player,data)
        if not player or player:isDead() or player:getPhase()~=sgs.Player_NotActive then return false end
        for _,p in sgs.qlist(room:getAllPlayers(true)) do
            if room:isRest(p) and p:getTag("LunxianRestActive"):toBool() and p:getTag("RestTurn"):toInt()<room:getTag("TurnLengthCount"):toInt() then
                local previous=p:getPreviousAlive():getNextAlive()
                if previous and previous==player then return skill:objectName(),p end
            end
        end
        return false
    end,
    on_effect=function(skill,event,room,player,ctx)
        room:unrestPlayer(player,true)
        local pool=parse_pool(player:getTag("DragonPool"):toString()); local choices={}
        for name in pairs(pool) do table.insert(choices,name) end
        if #choices>0 then
            local chosen=room:askForChoice(player,"ctg_lunxian",table.concat(choices,"+")); local current,secondary=dragon_slot(player)
            if pool[chosen] then transform(room,player,chosen,pool,secondary); log(room,"#ctg_lunxian_revive_transform",player,nil,chosen) end
        end
        player:removeTag("LunxianRestActive"); return false
    end,
}
addToSkills(ctg_lunxian_rest)
local ctg_global=sgs.CreateRuleSkillV2 {
    name="ctg_global",frequency=sgs.Skill_Compulsory,events={sgs.DamageCaused},
    can_trigger=function(skill,event,room,player,data)
        local d=data:toDamage(); if not d.from or d.chain then return false end
        local mark=d.nature==sgs.DamageStruct_Fire and "&ctg_yanyang_fire_bonus" or d.nature==sgs.DamageStruct_Thunder and "&ctg_tingyuan_thunder_bonus"
        if mark and d.from:getMark(mark)>0 then return skill:objectName(),d.from end
        return false
    end,
    on_effect=function(skill,event,room,player,ctx)
        local d=ctx.original_data:toDamage(); local fire=d.nature==sgs.DamageStruct_Fire
        d.damage=d.damage+player:getMark(fire and "&ctg_yanyang_fire_bonus" or "&ctg_tingyuan_thunder_bonus")
        ctx.original_data:setValue(d); room:sendCompulsoryTriggerLog(player,fire and "ctg_yanyang" or "ctg_tingyuan"); return false
    end,
}
addToSkills(ctg_global)
-- 四个蓄力技共享 donor 的角色蓄力池；永久奖励有意在失去技能后保留。
local function charged_skill(name,general,mark,chain)
    local function finish(skill,ctx)
        local p=ctx.invoker
        p:gainMark(mark,1)
        if p:getMark("&charge_num")<3 then p:getRoom():detachSkillFromPlayer(p,name.."#"..ctx.instanceID) end
        return sgs.ViewAsSkillV2_FinishSkill
    end
    local action=once_action {
        name=name,target_mode=chain and sgs.ViewAsSkillV2_SelectTargets or sgs.ViewAsSkillV2_NoTarget,
        target_effect_mode=chain and sgs.ViewAsSkillV2_WholeTargetGroup or sgs.ViewAsSkillV2_EachTarget,
        can_activate=function(skill,request) return play_request(skill,request) and request:getInitiator():getMark("&charge_num")>0 end,
        can_select_target=chain and function(skill,request,selected,candidate) return candidate and candidate:isAlive() and #selected<2+request:getInitiator():getMark(mark) end or nil,
        targets_feasible=chain and function(skill,request,selected) return #selected>0 and #selected<=2+request:getInitiator():getMark(mark) end or nil,
        on_effect=not chain and finish or nil,
        on_effect_target_group=chain and function(skill,ctx,targets)
            local p=ctx.invoker; local room=p:getRoom()
            for _,target in ipairs(targets) do
                if not target:isChained() then target:setChained(true); room:broadcastProperty(target,"chained"); room:setEmotion(target,"chain") end
            end
            return finish(skill,ctx)
        end or nil,
    }
    local skill=sgs.CreateTriggerSkillV2 {
        name=name,events={sgs.TurnStart},view_as_skill=action,
        can_trigger=function(self,event,room,player,data)
            return player and player:isAlive() and player:getMark("&charge_num")<xuLiMax(player) and refs(player,self:objectName())
        end,
        on_effect=function(self,event,room,player,ctx)
            if player:getMark("&charge_num")<xuLiMax(player) then player:gainMark("&charge_num"); room:sendCompulsoryTriggerLog(player,self:objectName()) end
            return false
        end,
    }
    skill:setProperty("ChargeNum",ToData("0/3")); general:addSkill(skill)
end
charged_skill("ctg_yanyang",ctg_nanlong,"&ctg_yanyang_fire_bonus",false)
charged_skill("ctg_tingyuan",ctg_donglong,"&ctg_tingyuan_thunder_bonus",false)
charged_skill("ctg_jutao",ctg_xilong,"&ctg_jutao_fengche_bonus",false)
charged_skill("ctg_linming",ctg_beilong,"&ctg_linming_target_bonus",true)
local function elemental_action(name,general,nature)
    general:addSkill(once_action {
        name=name,target_mode=sgs.ViewAsSkillV2_SelectTargets,can_select_target=single_other,targets_feasible=one_target,
        on_effect_target=function(skill,ctx,target)
            ctx.invoker:getRoom():damage(sgs.DamageStruct("",ctx.invoker,target,1,nature))
        end,
    })
end
elemental_action("ctg_huozhuo",ctg_nanlong,sgs.DamageStruct_Fire)
elemental_action("ctg_leiyao",ctg_donglong,sgs.DamageStruct_Thunder)
local function random_cards(target)
    local available={}; for _,id in sgs.qlist(target:handCards()) do table.insert(available,id) end
    for _,card in sgs.qlist(target:getEquips()) do table.insert(available,card:getEffectiveId()) end
    local selected={}
    for i=1,math.min(math.random(1,2),#available) do local index=math.random(#available); table.insert(selected,available[index]); table.remove(available,index) end
    return selected
end
local ctg_fengcheVS=sgs.CreateViewAsSkillV2 {
    name="ctg_fengche",n=0,target_mode=sgs.ViewAsSkillV2_SelectTargets,
    can_activate=function(skill,request)
        local p=request:getInitiator()
        return play_request(skill,request) and state(p,skill:objectName(),request:getActivationInstanceId(),"used"):toInt()<1+p:getMark("&ctg_jutao_fengche_bonus")
    end,
    can_select_target=single_other,targets_feasible=one_target,
    pay=function(skill,room,ctx,request)
        local p=ctx.invoker; local used=state(p,skill:objectName(),ctx.instanceID,"used"):toInt()
        if used>=1+p:getMark("&ctg_jutao_fengche_bonus") then return false end
        setstate(p,skill:objectName(),ctx.instanceID,"used",used+1); return true
    end,
    on_effect_target=function(skill,ctx,target)
        for _,id in ipairs(random_cards(target)) do ctx.invoker:getRoom():obtainCard(ctx.invoker,id) end
    end,
}
local ctg_fengche=sgs.CreateTriggerSkillV2 {
    name="ctg_fengche",events={sgs.EventPhaseChanging},view_as_skill=ctg_fengcheVS,
    can_trigger=function() return false end,
    on_record=function(skill,event,room,player,ctx)
        if ctx.owner and ctx.invoker==ctx.owner and ctx.original_data:toPhaseChange().from==sgs.Player_Play then setstate(ctx.owner,skill:objectName(),ctx.instanceID,"used",0) end
    end,
}
ctg_xilong:addSkill(ctg_fengche)
ctg_beilong:addSkill(once_action {
    name="ctg_shuangning",target_mode=sgs.ViewAsSkillV2_SelectTargets,can_select_target=single_other,targets_feasible=one_target,
    on_effect_target=function(skill,ctx,target) for _,id in ipairs(random_cards(target)) do target:addToPile("shuangning",id) end end,
})
local huntianlingskill=sgs.CreateEquipSkillV2 {
    name="#huntianlingskill",equipment="_huntianling",equipment_type="weapon",frequency=sgs.Skill_Compulsory,
    events={sgs.CardsMoveOneTime,sgs.DrawNCards},
    can_trigger=function(skill,event,room,player,data)
        if not player or not player:isAlive() then return false end
        if event==sgs.CardsMoveOneTime then
            local current=room:getCurrent(); local move=data:toMoveOneTime()
            if current and current:hasWeapon("_huntianling") and move.from==player and player~=current and move.to_place==sgs.Player_DiscardPile then return skill:objectName(),current end
        elseif data:toDraw().reason=="draw_phase" and player:getMark("&huntianling_draw")>0 then
            for _,p in sgs.qlist(room:getAlivePlayers()) do if p:hasWeapon("_huntianling") then return skill:objectName(),p end end
        end
        return false
    end,
    on_effect=function(skill,event,room,player,ctx)
        local target=ctx.invoker
        if event==sgs.CardsMoveOneTime then
            local move=ctx.original_data:toMoveOneTime(); room:addPlayerMark(target,"&huntianling_draw",move.card_ids:length())
        else
            local draw=ctx.original_data:toDraw(); draw.num=math.max(draw.num-target:getMark("&huntianling_draw")/2,0)
            ctx.original_data:setValue(draw); room:setPlayerMark(target,"&huntianling_draw",0)
        end
        return false
    end,
}
local qiankunquanskill=sgs.CreateEquipSkillV2 {
    name="#qiankunquanskill",equipment="_qiankunquan",equipment_type="weapon",frequency=sgs.Skill_Compulsory,
    events={sgs.DamageCaused,sgs.DrawNCards},
    can_trigger=function(skill,event,room,player,data)
        if not player or not player:isAlive() or not player:hasWeapon("_qiankunquan") then return false end
        if event==sgs.DamageCaused and data:toDamage().from==player then return skill:objectName(),player end
        if event==sgs.DrawNCards and data:toDraw().reason=="draw_phase" and player:getMark("&qiankunquan_draw")>0 then return skill:objectName(),player end
        return false
    end,
    on_effect=function(skill,event,room,player,ctx)
        if event==sgs.DamageCaused then room:addPlayerMark(player,"&qiankunquan_draw",ctx.original_data:toDamage().damage)
        else local draw=ctx.original_data:toDraw(); draw.num=draw.num+player:getMark("&qiankunquan_draw"); ctx.original_data:setValue(draw); room:setPlayerMark(player,"&qiankunquan_draw",0) end
        return false
    end,
}
addToSkills(huntianlingskill); addToSkills(qiankunquanskill)
local huntianling=sgs.CreateWeapon {
    name="_huntianling",class_name="huntianling",range=3,suit=sgs.Card_Spade,number=2,
    on_uninstall=function(self,player) local room=player:getRoom(); for _,p in sgs.qlist(room:getAlivePlayers()) do room:setPlayerMark(p,"&huntianling_draw",0) end end,
}
huntianling:setParent(extension)
local qiankunquan=sgs.CreateWeapon {
    name="_qiankunquan",class_name="qiankunquan",range=3,suit=sgs.Card_Spade,number=2,
    on_install=function(self,player) player:drawCards(2) end,
    on_uninstall=function(self,player) player:getRoom():setPlayerMark(player,"&qiankunquan_draw",0) end,
}
qiankunquan:setParent(extension)
sgs.LoadTranslationTable{
["ctg_tip"]="请选择你的阵营",
["ctg_weapon"]="请选择你的武器",
["ctg"]="陈塘关",
["#ctgStart"]="陈塘关模式",
["nazha"]="哪吒",
["ctg_nazha"]="哪吒",
["ctg_youmin"]="佑民",
[":ctg_youmin"]="回合开始时，你可以选择一条你与对面角色的路径，直到你的下个回合开始，此路径上的角色收到伤害时，你可以将此伤害转移给自己。",
["ctg_youmin_protect"]="佑",
["clockwise"]="顺时针",
["counterclockwise"]="逆时针",
["#ctg_youmin_protect"]="%from 发动【佑民】，选择%arg路径，保护%arg2名角色",
["#ctg_youmin_transfer"]="%from 发动【佑民】，将%to受到的%arg点伤害转移给自己",
["ctg_faqi"]="法器",
[":ctg_faqi"]="游戏开始后，你获得并使用【乾坤圈】或【混天绫】。",
["ctg_danyuan"]="殚援",
[":ctg_danyuan"]="蓄力技（4/4），回合开始阶段，你可以消耗一蓄力点，并从三个带【杀】的技能中选择一个获得。",
["#ctg_danyuan_acquire"]="%from 发动【殚援】，获得技能【%arg】",
["ctg_xianze"]="仙泽",
[":ctg_xianze"]="出牌阶段限一次，你可选择一项：1.令一名角色恢复一点体力；2.防止你受到的下次伤害直至你的回合开始。",
["ctg_xianzeCard"]="仙泽",
["ctg_xianze_protect"]="仙",
["recover"]="恢复体力",
["protect"]="防护伤害",
["@ctg_xianze_recover"]="选择一名角色，令其恢复1点体力",
["#ctg_xianze_recover"]="%from 发动【仙泽】，令 %to 恢复1点体力",
["#ctg_xianze_protect"]="%from 发动【仙泽】，获得防护效果",
["#ctg_xianze_prevent"]="%from 的【仙泽】防护效果生效，防止了此次伤害",
["ctg_cunmin1"]="村民",
["ctg_cunmin2"]="村民",
["ctg_cunmin3"]="村民",
["ctg_cunmin4"]="村民",
["ctg_kuijue"]="溃决",
[":ctg_kuijue"]="锁定技，当你死亡时，相邻角色和主公各失去一点体力。",
["#ctg_kuijue_adjacent"]="%from 的【溃决】效果，%to 失去1点体力",
["#ctg_kuijue_lord"]="%from 的【溃决】效果，主公 %to 失去1点体力",
["ctg_libo"]="力薄",
[":ctg_libo"]="锁定技，你跳过出牌阶段。",
["#ctg_game_rules"]="<font color=\"yellow\"><b>=== 陈塘关模式游戏规则 ===</b></font><br/>【主公方（哪吒）】：保护村民，坚持到第6轮获胜<br/>【忠臣方（村民）】：协助哪吒，存活到第6轮获胜<br/>【反贼方（龙王）】：在6轮内击杀所有村民获胜<br/><font color=\"red\"><b>【胜利条件】：</b></font><br/>　★ 主忠胜利：游戏进行到第6轮时自动获胜<br/>　★ 反贼胜利：击杀所有村民（忠臣）即可获胜<br/><font color=\"green\"><b>【特殊说明】：哪吒拥有【佑民】技能可转移伤害保护村民</b></font>",
["ctg_lunxian"]="轮现",
[":ctg_lunxian"]="当你死亡时，你改为休整一轮。出牌阶段限一次，你可将武将牌变为其他龙王。",
["#ctg_lunxian_rest"]="%from 触发【轮现】，改为休整一轮",
["#ctg_lunxian_transform"]="%from 触发【轮现】，变身为 %arg",
["#ctg_lunxian_revive_transform"]="%from 触发【轮现】，复活并变身为 %arg",
["ctg_xilong"]="西龙王",
["ctg_donglong"]="东龙王",
["ctg_beilong"]="北龙王",
["ctg_nanlong"]="南龙王",

["longwang"]="龙王",
["_qiankunquan"]="乾坤圈",
[":_qiankunquan"]="装备牌/武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：装备时摸两张牌；锁定技，每当你造成一点伤害，你下回合摸牌阶段额外摸1张牌。",
["#_qiankunquan1"]="<font color=red><b>%from</b></font> 的锁定技<font color=yellow><b>乾坤圈</b></font>被触发，造成 <font color=yellow><b>%arg</b></font> 点伤害，下回合摸牌阶段额外摸 <font color=yellow><b>%arg</b></font> 张牌",
["#_qiankunquan2"]="<font color=\"red\"><b>%from</b></font> 的锁定技<font color=\"yellow\"><b>乾坤圈</b></font>被触发，摸牌阶段额外摸 <font color=\"yellow\"><b>%arg</b></font> 张牌",
["qiankunquan_draw"]="额外摸牌",
["huntianling_draw"]="减少摸牌",
["_huntianling"]="混天绫",
[":_huntianling"]="装备牌/武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你的回合内，其他角色每累计2张牌进入弃牌堆，其下一个摸牌阶段少摸1张牌。",
}

-- 新技能翻译表
sgs.LoadTranslationTable{
	-- 武将翻译
	["ctg_xilong"] = "西海龙王",
	["#ctg_xilong"] = "西海掌权",
	["ctg_donglong"] = "东海龙王",
	["#ctg_donglong"] = "东海掌权",
	["ctg_beilong"] = "北海龙王",
	["#ctg_beilong"] = "北海掌权",
	["ctg_nanlong"] = "南海龙王",
	["#ctg_nanlong"] = "南海掌权",

	-- 技能翻译
	["ctg_global"] = "全局效果",
	[":ctg_global"] = "锁定技，当角色造成非传导火焰伤害时，若其拥有焱洋标记，此伤害+X（X为焱洋标记数）；当角色造成非传导雷电伤害时，若其拥有霆渊标记，此伤害+Y（Y为霆渊标记数）。",
	["ctg_yanyang"] = "焱洋",
	[":ctg_yanyang"] = "蓄力技（0/3），回合开始时增加一蓄力点，出牌阶段限一次，你可令你本局造成的非传导火焰伤害永久+1，然后若此时蓄力值未满，则你失去此技能。",
	["ctg_yanyangCard"] = "焱洋",
	["ctg_huozhuo"] = "火灼",
	[":ctg_huozhuo"] = "出牌阶段限一次，你可以对一名其他角色造成1点火焰伤害。",
	["ctg_huozhuoCard"] = "火灼",
	["ctg_leiyao"] = "雷耀",
	[":ctg_leiyao"] = "出牌阶段限一次，你可以对一名其他角色造成1点雷电伤害。",
	["ctg_leiyaoCard"] = "雷耀",
	["ctg_tingyuan"] = "霆渊",
	[":ctg_tingyuan"] = "蓄力技（0/3），回合开始时增加一蓄力点，出牌阶段限一次，你可令你本局造成的非传导雷电伤害永久+1，然后若此时蓄力值未满，则你失去此技能。",
	["ctg_tingyuanCard"] = "霆渊",
	["ctg_fengche"] = "风掣",
	[":ctg_fengche"] = "出牌阶段限一次，你可以获得一名其他角色的随机1-2张牌。",
	["ctg_fengcheCard"] = "风掣",
	["ctg_jutao"] = "飓涛",
	[":ctg_jutao"] = "蓄力技（0/3），回合开始时增加一蓄力点，出牌阶段限一次，你可令你【风掣】的发动次数永久+1，然后若此时蓄力值未满，则你失去此技能。",
	["ctg_jutaoCard"] = "飓涛",
	["ctg_linming"] = "凛溟",
	[":ctg_linming"] = "蓄力技（0/3），回合开始时增加一蓄力点，出牌阶段限一次，你可令至多两名角色进入连环状态，然后此技能可选择的目标+1，若此时蓄力值未满，则你失去此技能。",
	["ctg_linmingCard"] = "凛溟",
	["ctg_shuangning"] = "霜凝",
	[":ctg_shuangning"] = "出牌阶段限一次，你可以将一名其他角色的随机1-2张牌置于其武将牌上。",
	["ctg_shuangningCard"] = "霜凝",

	-- 蓄力标记翻译
	["charge_num"] = "蓄力",
	["ctg_yanyang_fire_bonus"] = "焱洋",
	["ctg_tingyuan_thunder_bonus"] = "霆渊",
	["ctg_jutao_fengche_bonus"] = "飓涛",
	["ctg_linming_target_bonus"] = "凛溟",
	["&shuangning"] = "霜",
	["shuangning"] = "霜",

	-- 提示翻译
	["@ctg_yanyang"] = "你可以发动【焱洋】令你本局造成的非传导火焰伤害永久+1",
	["~ctg_yanyang"] = "选择发动【焱洋】",
	["#ctg_yanyang_fire_bonus"] = "%from 的%arg被触发，火焰伤害+%arg2",
	["@ctg_huozhuo"] = "你可以发动【火灼】对一名其他角色造成1点火焰伤害",
	["~ctg_huozhuo"] = "选择【火灼】的目标",
	["@ctg_leiyao"] = "你可以发动【雷耀】对一名其他角色造成1点雷电伤害",
	["~ctg_leiyao"] = "选择【雷耀】的目标",
	["@ctg_tingyuan"] = "你可以发动【霆渊】令你本局造成的非传导雷电伤害永久+1",
	["~ctg_tingyuan"] = "选择发动【霆渊】",
	["@ctg_fengche"] = "你可以发动【风掣】获得一名其他角色的随机1-2张牌",
	["~ctg_fengche"] = "选择【风掣】的目标",
	["@ctg_jutao"] = "你可以发动【飓涛】令你【风掣】的发动次数永久+1",
	["~ctg_jutao"] = "选择发动【飓涛】",
	["@ctg_linming"] = "你可以发动【凛溟】令至多两名角色进入连环状态",
	["~ctg_linming"] = "选择【凛溟】的目标",
	["@ctg_shuangning"] = "你可以发动【霜凝】将一名其他角色的随机1-2张牌置于其武将牌上",
	["~ctg_shuangning"] = "选择【霜凝】的目标",

	-- 技能台词
	["$ctg_yanyang1"] = "焰火焱洋，焚天煮海！",
	["$ctg_yanyang2"] = "蓄力待发，焱火冲天！",
	["$ctg_huozhuo1"] = "烈火炙人，无处可逃！",
	["$ctg_huozhuo2"] = "火焰之力，焚烧一切！",
	["$ctg_leiyao1"] = "雷霆万钧，震慑四方！",
	["$ctg_leiyao2"] = "电光石火，无人能挡！",
	["$ctg_tingyuan1"] = "霆渊深雷，永世不绝！",
	["$ctg_tingyuan2"] = "雷电之威，贯穿九霄！",
	["$ctg_fengche1"] = "疾风如掣，取物无形！",
	["$ctg_fengche2"] = "风驰电掣，夺牌如飞！",
	["$ctg_jutao1"] = "飓风巨涛，势不可挡！",
	["$ctg_jutao2"] = "涛声阵阵，威力倍增！",
	["$ctg_linming1"] = "凛冽寒风，溟海连环！",
	["$ctg_linming2"] = "冰海凛溟，锁链相连！",
	["$ctg_shuangning1"] = "霜花凝结，冰封万物！",
	["$ctg_shuangning2"] = "寒霜凝聚，封印敌牌！"
}
-- 模式规则不依赖玩家技能实例，决策者与原事件角色分开传递。
local ctgStart=sgs.CreateRuleSkillV2 {
    name="#ctgStart",events={sgs.GameReady},
    can_trigger=function(skill,event,room,player,data)
        if player and player:isAlive() and player:getState()~="robot" and room:getMode()=="6_ctg" and not room:getTag("ctgMode"):toBool() then return skill:objectName(),player end
        return false
    end,
    on_cost=function(skill,event,room,player,ctx)
        for _,p in sgs.qlist(room:getAlivePlayers()) do if p:getSeat()==4 then ctx.targets:append(p); break end end
        if ctx.targets:isEmpty() then return false end
        ctx.choice=room:askForChoice(player,skill:objectName(),"nazha+longwang",sgs.QVariant(),nil,"ctg_tip")
        return true
    end,
    on_effect=function(skill,event,room,player,ctx)
        room:setTag("ctgMode",sgs.QVariant(true)); local against=ctx.targets:first()
        if ctx.choice=="nazha" then
            against:setRole("rebel"); room:setPlayerProperty(against,"role",sgs.QVariant("rebel"))
        else
            against:setRole("lord"); room:setPlayerProperty(against,"role",sgs.QVariant("lord"))
            player:setRole("rebel"); room:setPlayerProperty(player,"role",sgs.QVariant("rebel"))
        end
        local count=1
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getRole()=="lord" then room:changeHero(p,"ctg_nazha",true,false,false,false)
            elseif p:getRole()=="loyalist" then room:changeHero(p,"ctg_cunmin"..count,true,false,false,false); count=count+1
            elseif p:getRole()=="rebel" then room:changeHero(p,"ctg_xilong",true,false,false,false) end
            room:resetAI(p)
        end
        room:updateStateItem(); log(room,"#ctg_game_rules",player)
        room:changeBackground("ctg.png",room:getAlivePlayers()); return false
    end,
}
local ctg_sixthRoundWin=sgs.CreateRuleSkillV2 {
    name="#ctg_sixthRoundWin",frequency=sgs.Skill_Compulsory,events={sgs.GameOverJudge,sgs.TurnStart},
    can_trigger=function(skill,event,room,player,data)
        if not player or room:getMode()~="6_ctg" then return false end
        if event==sgs.TurnStart then return room:getTag("TurnLengthCount"):toInt()>=6 and skill:objectName(),player end
        for _,p in sgs.qlist(room:getAlivePlayers()) do if p:getRole()=="loyalist" then return false end end
        return skill:objectName(),player
    end,
    on_effect=function(skill,event,room,player,ctx)
        room:gameOver(event==sgs.TurnStart and "lord+loyalist" or "rebel"); return true
    end,
}
addToSkills(ctgStart); addToSkills(ctg_sixthRoundWin)
return extension
