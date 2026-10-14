-- smart-ai policies for 三国杀diy吧 3D2J (no isolated AI).
sgs.ai_fill_skill.diyba_quanjian = function(self)
    if #self.friends_noself==0 then return end
    local cards=sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _,c in ipairs(cards) do
        if c:isKindOf("Jink") and (self:getCardsNum("Jink")>1 or self:getOverflow()>0) then
            local card=sgs.ActiveSkillCard()
            card:setSkillName("diyba_quanjian")
            card:addSubcard(c:getEffectiveId())
            return card
        end
    end
end
sgs.ai_skill_use_func.diyba_quanjian = function(card,use,self)
    self:sort(self.friends_noself,"handcard")
    for _,p in ipairs(self.friends_noself) do
        if not self:needKongcheng(p,true) then
            use.card=card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_skill_invoke.diyba_sijie = function(self)
    for _,p in ipairs(self.enemies) do
        if self.player:canDiscard(p,"he") then return true end
    end
    return false
end
sgs.ai_skill_playerchosen.diyba_sijie = function(self,targets)
    local enemies={}
    for _,p in sgs.qlist(targets) do
        if self:isEnemy(p) then table.insert(enemies,p) end
    end
    self:sort(enemies,"defense")
    return enemies[1]
end
sgs.ai_cardneed.diyba_quanjian = function(to,card) return card:isKindOf("Jink") end
sgs.ai_use_priority.diyba_quanjian = 3
sgs.ai_fill_skill.diyba_pengri = function(self)
    if self:getCardsNum("Jink")<1 and self.player:getHp()<3 then return end
    local card=sgs.ActiveSkillCard()
    card:setSkillName("diyba_pengri")
    return card
end
sgs.ai_skill_use_func.diyba_pengri = function(card,use,self)
    self:sort(self.enemies,"handcard")
    for _,p in ipairs(self.enemies) do
        if not p:isNude() then
            use.card=card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_skill_invoke.diyba_gangli = function(self,data)
    local from=data:toDamage().from
    if not from then return false end
    local slash=sgs.Sanguosha:cloneCard("slash")
    for _,p in ipairs(self.enemies) do
        if p~=from and not from:isProhibited(p,slash) and self:slashIsEffective(slash,p,from) then
            slash:deleteLater()
            return true
        end
    end
    slash:deleteLater()
    return false
end
sgs.ai_skill_playerchosen.diyba_gangli = function(self,targets)
    local enemies={}
    for _,p in sgs.qlist(targets) do
        if self:isEnemy(p) then table.insert(enemies,p) end
    end
    self:sort(enemies,"defense")
    return enemies[1]
end
sgs.ai_use_priority.diyba_pengri = 3
sgs.ai_fill_skill.diyba_duji = function(self)
    if not self.player:getPile("diyba_poison"):isEmpty() then return end
    local cards=sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _,c in ipairs(cards) do
        if c:getSuit()==sgs.Card_Spade and not self:isValuableCard(c) then
            local card=sgs.ActiveSkillCard();card:setSkillName("diyba_duji");card:addSubcard(c)
            return card
        end
    end
end
sgs.ai_skill_use_func.diyba_duji = function(card,use,self) use.card=card end
sgs.ai_skill_invoke.diyba_duji = function(self,data)
    local use=data:toCardUse()
    if not self:isFriend(use.from) then return false end
    for _,p in sgs.qlist(use.to) do
        if self:isEnemy(p) and self:slashIsEffective(use.card,p,use.from) then return true end
    end
    return false
end
sgs.ai_skill_choice.diyba_duji = function(self)
    if not self.player:faceUp() or self.player:getHp()<=2 then return "turnover" end
    return "losehp"
end
sgs.ai_use_priority.diyba_duji = 2
sgs.ai_fill_skill.diyba_xuezhao = function(self)
    local cards=sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local cost={}
    for _,c in ipairs(cards) do
        if not self.player:isJilei(c) and not self:isValuableCard(c) then table.insert(cost,c) end
    end
    local card=sgs.ActiveSkillCard();card:setSkillName("diyba_xuezhao")
    if #cost>=2 and (self.player:getHp()<=2 or self:getOverflow()>1) then
        card:addSubcard(cost[1]);card:addSubcard(cost[2])
    elseif self.player:getHp()<=2 then return end
    return card
end
sgs.ai_skill_use_func.diyba_xuezhao = function(card,use,self)
    self:sort(self.enemies,"hp")
    if #self.enemies==0 then return end
    local victim=self.enemies[1]
    local slash=sgs.Sanguosha:cloneCard("slash")
    for _,p in ipairs(self.friends_noself) do
        if not p:isProhibited(victim,slash) and self:getCardsNum("Slash",p)>0
            and self:slashIsEffective(slash,victim,p) then
            use.card=card;if use.to then use.to:append(p);use.to:append(victim) end
            slash:deleteLater();return
        end
    end
    slash:deleteLater()
    if #self.enemies>=2 then
        use.card=card;if use.to then use.to:append(victim);use.to:append(self.enemies[2]) end
    end
end
sgs.ai_skill_invoke.diyba_hanhuang = function(self,data)
    local p=self.room:findPlayerByObjectName(data:toString())
    return p and self:isFriend(p)
end
sgs.ai_use_priority.diyba_xuezhao = 4
sgs.ai_fill_skill.diyba_jiefan = function(self)
    if not self.player:isWounded() or self.player:getEquipArea()<=0 then return end
    if self.player:getHp()>2 and self.player:getCards("he"):length()>2 then return end
    return sgs.Card_Parse("peach:diyba_jiefan[no_suit:0]=.")
end
sgs.ai_cardsview_valuable.diyba_jiefan = function(self,class_name,player)
    if class_name=="Peach" and player:getEquipArea()>0 and player:getMark("Global_PreventPeach")==0 then
        return "peach:diyba_jiefan[no_suit:0]=."
    end
end
sgs.ai_skill_choice.diyba_jiefan = function(self,choices)
    local names={"treasure_area","defensive_horse_area","offensive_horse_area","armor_area","weapon_area"}
    local indices={4,2,3,1,0}
    for i,name in ipairs(names) do
        if string.find(choices,name,1,true) and self.player:getEquip(indices[i]) then return name end
    end
    for _,name in ipairs(names) do if string.find(choices,name,1,true) then return name end end
    return string.split(choices,"+")[1]
end
sgs.ai_skill_invoke.diyba_yaliang = function(self,data)
    local use=data:toCardUse()
    if use.card:isKindOf("ExNihilo") or use.card:isKindOf("GodSalvation")
        or use.card:isKindOf("AmazingGrace") then return false end
    return self:getCardsNum("Jink")>0 or self.player:getHp()>2
end
sgs.ai_fill_skill.diyba_xungui = function(self)
    local cards=sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _,c in ipairs(cards) do
        if c:isNDTrick() and (self.player:getPile("diyba_rule"):isEmpty() or self.player:isWounded()) then
            local card=sgs.ActiveSkillCard();card:setSkillName("diyba_xungui");card:addSubcard(c)
            return card
        end
    end
end
sgs.ai_skill_use_func.diyba_xungui = function(card,use,self) use.card=card end
sgs.ai_fill_skill.diyba_daoju = function(self)
    local pile=self.player:getPile("diyba_rule")
    if pile:isEmpty() then return end
    local cards=sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for i,a in ipairs(cards) do
        for j=i+1,#cards do
            local b=cards[j]
            if not self:isValuableCard(a) and not self:isValuableCard(b)
                and ((a:isRed() and b:isRed()) or (a:isBlack() and b:isBlack())) then
                local card=sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(pile:first()):objectName(),sgs.Card_NoSuit,0)
                card:setSkillName("diyba_daoju");card:addSubcard(a);card:addSubcard(b)
                return card
            end
        end
    end
end
sgs.ai_use_priority.diyba_xungui = 2
sgs.ai_skill_playerchosen.diyba_xiandeng = function(self,targets)
    if self:getCardsNum("Slash")==0 then return end
    local enemies={}
    for _,p in sgs.qlist(targets) do
        if self:isEnemy(p) and self.player:distanceTo(p)>self.player:getAttackRange() then table.insert(enemies,p) end
    end
    self:sort(enemies,"defenseSlash")
    return enemies[1]
end
sgs.ai_skill_invoke.diyba_xiaoguo = function(self,data)
    local effect=data:toSlashEffect()
    local name=effect.slash:isBlack() and "supply_shortage" or "indulgence"
    return self:isEnemy(effect.to) and effect.to:hasJudgeArea() and not effect.to:containsTrick(name)
end

sgs.ai_fill_skill.diyba_sansi = function(self)
    local ids=self.player:getValidSkillInstanceIds("diyba_sansi")
    if ids:isEmpty() then return end
    local mode=self.player:getSkillInstanceStateValue("diyba_sansi",ids:first(),"mode"):toInt()%3+1
    local cards=sgs.QList2Table(self.player:getCards("he"));self:sortByKeepValue(cards)
    local chosen,seen={},{}
    for _,c in ipairs(cards) do
        local key=mode==2 and c:getTypeId() or c:getSuit()
        if not self.player:isCardLimited(c,sgs.Card_MethodRecast) and (mode==1 or not seen[key])
            and (mode~=3 or key<=sgs.Card_Diamond) then
            table.insert(chosen,c);seen[key]=true
            if #chosen==mode+1 then break end
        end
    end
    if #chosen~=mode+1 then return end
    local card=sgs.ActiveSkillCard();card:setSkillName("diyba_sansi")
    for _,c in ipairs(chosen) do card:addSubcard(c) end
    return card
end
sgs.ai_skill_use_func.diyba_sansi = function(card,use,self)
    local friends={}
    for _,p in ipairs(self.friends) do if p:isAlive() then table.insert(friends,p) end end
    self:sort(friends,"handcard")
    if friends[1] then use.card=card;if use.to then use.to:append(friends[1]) end end
end
sgs.ai_skill_invoke.diyba_jiezhong = function(self,data)
    local who=data:toDying().who
    return who and self:isFriend(who)
end
sgs.ai_use_priority.diyba_sansi = 4

sgs.ai_skill_choice.diyba_lianman = function(self,choices,data)
    local use=data:toCardUse()
    local benefit=use.card:isKindOf("ExNihilo") or use.card:isKindOf("AmazingGrace") or use.card:isKindOf("GodSalvation")
    local target=self.diyba_lianman_target
    if target then
        self.diyba_lianman_target=nil
        if self:isFriend(target)==benefit then return "diyba_lianman_draw" end
    end
    return "diyba_lianman_skip"
end
sgs.ai_skill_playerchosen.diyba_lianman = function(self,targets)
    local use=self.player:getTag("diyba_lianman_ai"):toCardUse()
    if not use.card then return end
    local benefit=use.card:isKindOf("ExNihilo") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace")
    local list=sgs.QList2Table(targets);self:sort(list,"defense")
    for _,p in ipairs(list) do
        if (benefit and self:isFriend(p)) or (not benefit and self:isEnemy(p)) then
            self.diyba_lianman_target=p;return p
        end
    end
    for _,p in ipairs(list) do
        if self:isFriend(p) or self:isEnemy(p) then self.diyba_lianman_target=p;return p end
    end
end
sgs.ai_skill_playerchosen.diyba_xiemeng = function(self,targets)
    local use=self.player:getTag("diyba_xiemeng_ai"):toCardUse()
    if not use.card then return end
    local benefit=use.card:isKindOf("ExNihilo") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace")
    local list=sgs.QList2Table(targets);self:sort(list,"defense")
    for _,p in ipairs(list) do
        if (benefit and self:isFriend(p)) or (not benefit and self:isEnemy(p)) then return p end
    end
end

sgs.ai_skill_playerchosen.diyba_sili = function(self,targets)
    local enemies={}
    for _,p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies,p) end end
    self:sort(enemies,"defense")
    return enemies[1]
end
-- 辛土必用牌的第二步目标选择；无合法完成路径的角色不会进入targets。
sgs.ai_skill_playerchosen.diyba_xintu = function(self,targets)
    local id=self.player:getTag("diyba_xintu_target_id"):toInt()-1
    if id<0 then return targets:first() end
    local card=sgs.Sanguosha:getCard(id)
    local benefit=card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("GodSalvation")
    local list=sgs.QList2Table(targets);self:sort(list,"defense")
    for _,p in ipairs(list) do
        if (benefit and self:isFriend(p)) or (not benefit and self:isEnemy(p)) then return p end
    end
    return list[1]
end
sgs.ai_skill_use["@@diyba_xintu_use"] = function(self,prompt)
    -- 使用mandatory目标入口，避免为借刀等复合目标拼造不合法的AI回复。
    return "."
end
