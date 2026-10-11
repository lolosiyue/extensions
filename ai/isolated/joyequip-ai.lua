-- Fixed joyequip donor; complete scoring branches, with pure scoped data.
local function known(v,key)
 if AIUnsupported.is(v)then error(v,0)end
 if v==nil then ai_unsupported("Joyequip requires "..key,"joyequip")end;return v
end
local function q(o,m,...)
 if AIValue.isPlayer(o)and m=="getMark"then m="getStrategyMark"end
 if not o or type(o[m])~="function"then ai_unsupported("Joyequip getter missing: "..m,"joyequip")end
 return known(o[m](o,...),m)
end
local function yx_damage(self)
 local ctx=q(self,"getDecisionContext").joyequip
 local row=type(ctx)=="table"and ctx.yx_sword_damage
 if type(row)~="table"then ai_unsupported("YxSwordData exact scoped damage missing","yx_sword")end
 local d={};for k,v in pairs(row)do d[k]=v end
 for _,k in ipairs({"from","to"})do
  if type(row[k])=="string"and row[k]~=""then d[k]=known(self.room:findPlayerByObjectName(row[k]),"damage "..k)end
 end
 if type(row.card)=="table"then d.card=CardView.new(row.card)end
 return d
end
local function role_of(self,p)
 local role=p.getRole and p:getRole()
 if role~=nil then return role end
 return self:useKnowledgeEstimate({status="estimate",value=q(self,"getRoleEstimate",p),
  basis="joyequip.getLord.foreign_role_viewer_inference",player=p:objectName()},"yx_sword.getLord")
end
local function legacy_lord(self,p)
 if known(self.world.enable_hegemony,"EnableHegemony")then return end
 local lord=self.room:getLord();if lord then return lord end
 if role_of(self,p)~="renegade"then
  for _,other in ipairs(q(self.room,"getOtherPlayers",p))do
   if role_of(self,other)==role_of(self,p)then return other end
  end
 end
 return p
end
--[[
    卡牌：屎（基本牌）
    效果：当此牌在你的回合内从你的手牌进入弃牌堆时，你将受到自己对自己的1点伤害（黑桃为流失1点体力），其中方块为无属性伤害、梅花为雷电伤害、红桃为火焰伤害。造成伤害的牌为此牌。在你的回合内，你可多次食用。
]]--
local function useShit_LoseHp(self,card,use)
    local lose = 1
    local hp = q(self.player,"getHp")
    local amSafe = ( lose<hp )
    if not amSafe then
        amSafe = ( lose<hp+q(self,"getCardsNum","Peach") )
    end
    if amSafe then
        if q(self,"hasZhaxiangEffect",self.player) then
            use.card = card
            return 
        elseif q(self.player,"getHandcardNum")==1 and q(self.player,"getLostHp")==0 and q(self,"needKongcheng") then
            use.card = card
            return 
        elseif getBestHp(self.player)>q(self.player,"getHp") and q(self,"getOverflow")<=0 then
            use.card = card
            return 
        end
    else
        if q(self.player,"getRole")=="renegade" or q(self.player,"getRole")=="lord" then
            return
        elseif q(self,"getAllPeachNum")>0 or q(self,"getOverflow")<=0 then
            return 
        elseif q(self.player,"hasSkill","wuhun") and q(self,"needDeath",self.player) then
            use.card = card
            return 
        end
    end
end
local function useShit_FireDamage(self,card,use)
    if q(self.player,"isChained") then
        if #(q(self,"getChainedFriends"))>#(q(self,"getChainedEnemies")) then
            return 
        end
    end
    local damage = 1
    if q(self.player,"hasSkill","chouhai") and q(self.player,"isKongcheng") then
        damage = damage+1
    end
    if q(self.player,"hasArmorEffect","gale_shell") then
        damage = damage+1
    elseif q(self.player,"hasArmorEffect","Vine") then
        damage = damage+1
    elseif q(self.player,"hasArmorEffect","bossmanjia") then
        damage = damage+1
    end
    local JinXuanDi = self.room:findPlayerBySkillName("wuling")
    if JinXuanDi and q(JinXuanDi,"getMark","@wind")>0 then
        damage = damage+1
    end
    if damage>1 and q(self.player,"hasArmorEffect","SilverLion") then
        damage = 1
    end
    local hp = q(self.player,"getHp")
    local amSafe = ( damage<hp )
    local peachNum = nil
    if not amSafe then
        peachNum = q(self,"getCardsNum","Peach")
        amSafe = ( damage<hp+peachNum )
    end
    if amSafe then
        if self:hasSkills("kuanggu") then
            use.card = card
            return 
        elseif q(self.player,"hasSkill","kuangbao") and hp>3 then
            use.card = card
            return 
        end
        peachNum = peachNum or q(self,"getCardsNum","Peach")
        if self:hasSkills("guixin|yiji|nosyiji|chengxiang|noschengxiang") and peachNum>0 then
            use.card = card
            return 
        elseif q(self.player,"hasSkill","jieming") and peachNum>0 and q(self,"getJiemingChaofeng",self.player)>0 then
            use.card = card
            return 
        elseif q(self.player,"getHandcardNum")==1 and q(self.player,"getLostHp")==0 and q(self,"needKongcheng") then
            use.card = card
            return 
        elseif getBestHp(self.player)>q(self.player,"getHp") and q(self,"getOverflow")<=0 then
            use.card = card
            return 
        end
    else
        if q(self.player,"getRole")=="renegade" or q(self.player,"getRole")=="lord" then
            return
        elseif q(self,"getAllPeachNum")>0 or q(self,"getOverflow")<=0 then
            return 
        elseif q(self.player,"hasSkill","wuhun") and q(self,"needDeath",self.player) then
            use.card = card
            return 
        end
    end
end
local function useShit_ThunderDamage(self,card,use)
    if q(self.player,"isChained") then
        if #(q(self,"getChainedFriends"))>#(q(self,"getChainedEnemies")) then
            return 
        end
    end
    local damage = 1
    if q(self.player,"hasSkill","chouhai") and q(self.player,"isKongcheng") then
        damage = damage+1
    end
    local JinXuanDi = self.room:findPlayerBySkillName("wuling")
    if JinXuanDi and q(JinXuanDi,"getMark","@thunder")>0 then
        damage = damage+1
    end
    if damage>1 and q(self.player,"hasArmorEffect","SilverLion") then
        damage = 1
    end
    local hp = q(self.player,"getHp")
    local amSafe = ( damage<hp )
    local peachNum = nil
    if not amSafe then
        peachNum = q(self,"getCardsNum","Peach")
        amSafe = ( damage<hp+peachNum )
    end
    if amSafe then
        if self:hasSkills("kuanggu") then
            use.card = card
            return 
        elseif q(self.player,"hasSkill","kuangbao") and hp>3 then
            use.card = card
            return 
        end
        peachNum = peachNum or q(self,"getCardsNum","Peach")
        if self:hasSkills("guixin|yiji|nosyiji|chengxiang|noschengxiang") and peachNum>0 then
            use.card = card
            return 
        elseif q(self.player,"hasSkill","jieming") and peachNum>0 and q(self,"getJiemingChaofeng",self.player)>0 then
            use.card = card
            return 
        elseif q(self.player,"getHandcardNum")==1 and q(self.player,"getLostHp")==0 and q(self,"needKongcheng") then
            use.card = card
            return 
        elseif getBestHp(self.player)>q(self.player,"getHp") and q(self,"getOverflow")<=0 then
            use.card = card
            return 
        end
    else
        if q(self.player,"getRole")=="renegade" or q(self.player,"getRole")=="lord" then
            return
        elseif q(self,"getAllPeachNum")>0 or q(self,"getOverflow")<=0 then
            return 
        elseif q(self.player,"hasSkill","wuhun") and q(self,"needDeath",self.player) then
            use.card = card
            return 
        end
    end
end
local function useShit_NormalDamage(self,card,use)
    local damage = 1
    if q(self.player,"hasSkill","chouhai") and q(self.player,"isKongcheng") then
        damage = damage+1
    end
    if damage>1 and q(self.player,"hasArmorEffect","SilverLion") then
        damage = 1
    end
    local hp = q(self.player,"getHp")
    local amSafe = ( damage<hp )
    local peachNum = nil
    if not amSafe then
        peachNum = q(self,"getCardsNum","Peach")
        amSafe = ( damage<hp+peachNum )
    end
    if amSafe then
        if self:hasSkills("kuanggu") then
            use.card = card
            return 
        elseif q(self.player,"hasSkill","kuangbao") and hp>3 then
            use.card = card
            return 
        end
        peachNum = peachNum or q(self,"getCardsNum","Peach")
        if self:hasSkills("guixin|yiji|nosyiji|chengxiang|noschengxiang") and peachNum>0 then
            use.card = card
            return 
        elseif q(self.player,"hasSkill","jieming") and peachNum>0 and q(self,"getJiemingChaofeng",self.player)>0 then
            use.card = card
            return 
        elseif q(self.player,"getHandcardNum")==1 and q(self.player,"getLostHp")==0 and q(self,"needKongcheng") then
            use.card = card
            return 
        elseif getBestHp(self.player)>q(self.player,"getHp") and q(self,"getOverflow")<=0 then
            use.card = card
            return 
        end
    else
        if q(self.player,"getRole")=="renegade" or q(self.player,"getRole")=="lord" then
            return
        elseif q(self,"getAllPeachNum")>0 or q(self,"getOverflow")<=0 then
            return 
        elseif q(self.player,"hasSkill","wuhun") and q(self,"needDeath",self.player) then
            use.card = card
            return 
        end
    end
end
function SmartAIView:useCardShit(card,use)
    if q(self.player,"hasSkill","jueqing") then
        useShit_LoseHp(self,card,use)
        return 
    end
    local suit = q(card,"getSuit")
    if suit==sgs.Card_Spade then
        useShit_LoseHp(self,card,use)
        return 
    end
    local JinXuanDi = self.room:findPlayerBySkillName("wuling")
    if JinXuanDi and q(JinXuanDi,"getMark","@fire")>0 then
        useShit_FireDamage(self,card,use)
    elseif suit==sgs.Card_Heart then
        useShit_FireDamage(self,card,use)
    elseif suit==sgs.Card_Club then
        useShit_ThunderDamage(self,card,use)
    elseif suit==sgs.Card_Diamond then
        useShit_NormalDamage(self,card,use)
    end
end
sgs.ai_use_value["Shit"] = -10
sgs.ai_keep_value["Shit"] = 10
--[[
    卡牌：猴子（装备牌·坐骑牌）
    效果：1、当场上有其他角色使用【桃】时，你可以弃置【猴子】，阻止【桃】的结算并将其收为手牌；
        2、你计算与其他角色的距离时，始终-1
]]--
sgs.ai_skill_invoke.grab_peach = function(self,data)
    local from = data:toCardUse().from
    return q(self,"isEnemy",from)
end
--[[
    卡牌：杨修剑
    技能：当你的【杀】造成伤害时，可以指定攻击范围内的一名其他角色为伤害来源，杨修剑归该角色所有
]]--
sgs.weapon_range.YxSword = 3
--room->askForPlayerChosen(player,players,objectName(),"@yxsword-select",true,true)
sgs.ai_skill_playerchosen["yx_sword"] = function(self,targets)
    local damage = yx_damage(self)
    local victim = damage.to
    local willKillVictim = ( q(victim,"getHp")+q(self,"getAllPeachNum",victim)<=damage.damage )
    local friends,enemies = {},{}
    for _,p in sgs.list(targets)do
        if q(self,"isFriend",p) then
            table.insert(friends,p)
        else
            table.insert(enemies,p)
        end
    end
    if willKillVictim then
        if q(victim,"hasSkill","yuwen") then
            return nil
        elseif q(victim,"hasSkill","duanchang") then
            local bad_skills = "benghuai|wumou|shiyong|yaowu|zaoyao|chanyuan|chouhai"
            local function hasOtherSkills(player)
                local skills = q(player,"getVisibleSkillList")
                for _,skill in sgs.list(skills)do
                    if q(skill,"inherits","SPConvertSkill") then
                    elseif q(skill,"isAttachedLordSkill") then
                    elseif q(skill,"isLordSkill") then
                        if q(player,"hasLordSkill",q(skill,"objectName")) then
                            return true
                        end
                    elseif not string.find(bad_skills,q(skill,"objectName")) then
                        return true
                    end
                end
                return false
            end
            if #friends>0 then
                self:sort(friends,"defense")
                for _,friend in sgs.list(friends)do
                    if self:hasSkills(bad_skills,friend) then
                        if not hasOtherSkills(friend) then
                            return friend
                        end
                    end
                end
            end
            if #enemies>0 then
                self:sort(enemies,"threat")
                for _,enemy in sgs.list(enemies)do
                    if hasOtherSkills(enemy) then
                        return enemy
                    end
                end
            end
        end
        local role = q(self,"getRoleEstimate",victim)
        if role=="rebel" then
            if #friends>0 then
                local drawTargets = self:findPlayerToDraw(true,3,true)
                for _,target in sgs.list(drawTargets)do
                    for _,friend in sgs.list(friends)do
                        if q(target,"objectName")==q(friend,"objectName") then
                            return friend
                        end
                    end
                end
            end
        elseif role=="loyalist" then
            local lord = legacy_lord(self,victim)
            if lord and q(lord,"objectName")~=q(victim,"objectName") and #enemies>0 then
                for _,enemy in sgs.list(enemies)do
                    if q(lord,"objectName")==q(enemy,"objectName") then
                        return enemy
                    end
                end
            end
        end
    end
    if q(self,"cantbeHurt",victim,self.player,damage.damage) then
        if #friends>0 then
            for _,friend in sgs.list(friends)do
                if not q(self,"cantbeHurt",victim,friend,damage.damage) then
                    return friend
                end
            end
        end
        if #enemies>0 then
            for _,enemy in sgs.list(enemies)do
                if q(self,"cantbeHurt",victim,enemy,damage.damage) then
                    return enemy
                end
            end
        end
    end
    if not willKillVictim then
        if q(self,"needToLoseHp",victim,self.player,damage.card) then
            if #friends>0 then
                for _,friend in sgs.list(friends)do
                    if not q(self,"needToLoseHp",victim,friend,damage.card)
                    then return friend end
                end
            end
            if #enemies>0 then
                self:sort(enemies,"defense")
                return enemies[1]
            end
        end
    end
    if self:hasSkills(sgs.lose_equip_skill) and #friends>0 then
        local cards = { self.player:getWeapon() }
        local weapon,priorTarget = self:getCardNeedPlayer(cards,false)
        if weapon and priorTarget then
            for _,friend in sgs.list(friends)do
                if q(priorTarget,"objectName")==q(friend,"objectName") then
                    return friend
                end
            end
        end
        self:sort(friends,"threat")
        friends = sgs.reverse(friends)
        return friends[1]
    end
    return nil
end
--[[
    卡牌：狂风甲
    技能：1、锁定技，每次受到火焰伤害时，该伤害+1；
        2、你可以将狂风甲装备和你距离为1以内的一名角色的装备区内
]]--
sgs.ai_card_intention.GaleShell = 80
sgs.ai_use_priority.GaleShell = 0.9
sgs.dynamic_value.control_card.GaleShell = true
sgs.ai_armor_value["gale_shell"] = function(player,self)
    return -10
end
function SmartAIView:useCardGaleShell(card,use)
    self:sort(self.enemies,"threat")
    local targets = {}
    for _,enemy in sgs.list(self.enemies)do
        if q(self.player,"distanceTo",enemy)==1 then
            table.insert(targets,enemy)
        end
    end
    if #targets>0 then
        local function getArmorUseValue(target)
            local value = 0
            if q(target,"getMark","&kuangfeng")>0 then
                value = value+2
            end
            local armor = target:getArmor()
            if armor then
                value = value+10
                if q(target,"hasArmorEffect","SilverLion") and q(target,"isWounded") then
                    value = value-4
                end
                if self:hasSkills(sgs.lose_equip_skill,target) then
                    value = value-1.5
                end
                if q(target,"hasSkill","tuntian") then
                    value = value-1
                end
            else
                value = value+2
                if self:hasSkills("bazhen|yizhong|jiqiao|bossmanjia",target) then
                    value = value+8
                end
                if self:hasSkills(sgs.lose_equip_skill,target) then
                    value = value-2
                end
                if self:hasSkills(sgs.need_equip_skill,target) then
                    value = value-2
                end
            end
            if self:hasSkills("jijiu|longhun",target) then
                value = value-5
            end
            if self:hasSkills("wusheng|wushen",target) then
                value = value-2
            end
            return value
        end
        local values = {}
        for _,enemy in sgs.list(targets)do
            values[q(enemy,"objectName")] = getArmorUseValue(enemy)
        end
        local compare_func = function(a,b)
            local valueA = values[q(a,"objectName")] or 0
            local valueB = values[q(b,"objectName")] or 0
            return valueA>valueB
        end
        table.sort(targets,compare_func)
        local target = targets[1]
        local value = values[q(target,"objectName")] or 0
        if value>0 then
            use.card = card
            use.to:append(target)
        end
    end
end
--[[
    卡牌：地震
    效果：将【地震】放置于你的判定区里，回合判定阶段进行判定：若判定结果为♣2~9之间，与当前角色距离为1以内的角色(无视+1马)弃置装备区里的所有牌，将【地震】置入弃牌堆。若判定结果不为♣2~9之间，将【地震】移动到当前角色下家的判定区里
]]--
function SmartAIView:useCardEarthquake(card,use)
    if q(self.player,"containsTrick","earthquake") then return
    elseif q(self.player,"isProhibited",self.player,card) then return
    elseif q(self.player,"containsTrick","YanxiaoCard") and q(self,"getOverflow")>0
    then use.card = card return end
    local value = 0
    local finalRetrial,wizard = self:getFinalRetrial()
    known(finalRetrial,"final retrial result")
    if finalRetrial==2 then
        return
    elseif finalRetrial==1 then
        value = value+12
    end
    local function getEquipsValue(player)
        local v = 0
        local danID = self:getDangerousCard(player)
        local weapon = player:getWeapon()
        if weapon then
            v = v+5
            if danID and q(weapon,"getEffectiveId")==danID then
                value = value+2
            end
        end
        local armor = player:getArmor()
        if armor then
            v = v+8
            if danID and q(armor,"getEffectiveId")==danID then
                value = value+2
            end
        end
        local dhorse = player:getDefensiveHorse()
        if dhorse then
            v = v+7
        end
        local ohorse = player:getOffensiveHorse()
        if ohorse then
            v = v+4
        end
        local treasure = player:getTreasure()
        if treasure then
            v = v+2
        end
        return v
    end
    if #self.enemies>0 then
        for _,enemy in sgs.list(self.enemies)do
            if self:hasSkills("tiandu|luoying",enemy) then
                value = value-10
            end
            if self:hasSkills("guanxing|super_guanxing",enemy) then
                value = value+2
            end
            if q(enemy,"hasSkill","xinzhan") then
                value = value-1
            end
            local equips = q(enemy,"getEquips")
            if not equips:isEmpty() then
                value = value+getEquipsValue(enemy)
                if self:hasSkills(sgs.lose_equip_skill,enemy) then
                    value = value-equips:length()*2
                end
                if enemy:getArmor() and q(self,"needToThrowArmor",enemy) then
                    value = value-1.5
                end
                if q(enemy,"hasSkill","tuntian") then
                    value = value-1
                end
            end
        end
    end
    if #self.friends>0 then
        for _,friend in sgs.list(self.friends)do
            if self:hasSkills("tiandu|luoying",friend) then
                value = value+10
            end
            if self:hasSkills("guanxing|super_guanxing",friend) then
                value = value-2
            end
            if q(friend,"hasSkill","xinzhan") then
                value = value+1
            end
            local equips = q(friend,"getEquips")
            if not equips:isEmpty() then
                value = value-getEquipsValue(friend)
                if self:hasSkills(sgs.lose_equip_skill,friend) then
                    value = value+equips:length()*2
                end
                if friend:getArmor() and q(self,"needToThrowArmor",friend) then
                    value = value+1.5
                end
                if q(friend,"hasSkill","tuntian") then
                    value = value+1
                end
            end
        end
    end
    local HanHaoShiHuan = self.room:findPlayerBySkillName("yonglve")
    if HanHaoShiHuan then
        if q(self,"isFriend",HanHaoShiHuan) then
            value = value+10
        else
            value = value-10
        end
    end
    if value>0 then
        use.card = card
    end
end
--[[
    卡牌：台风
    效果：将【台风】放置于你的判定区里，回合判定阶段进行判定：若判定结果为♦2~9之间，与当前角色距离为1的角色弃置6张手牌，将【台风】置入弃牌堆。若判定结果不为♦2~9之间，将【台风】移动到当前角色下家的判定区里
]]--
function SmartAIView:useCardTyphoon(card,use)
    if q(self.player,"containsTrick","typhoon") then return 
    elseif q(self.player,"isProhibited",self.player,card) 
    then return
    elseif q(self.player,"containsTrick","YanxiaoCard") and q(self,"getOverflow")>0
    then use.card = card return end
    local finalRetrial,wizard = self:getFinalRetrial()
    known(finalRetrial,"final retrial result")
    if finalRetrial==2
    then return
    elseif finalRetrial==1 then
        use.card = card
        return 
    end
    local alives = q(self.room,"getAlivePlayers")
    local value = 0
    for _,p in sgs.list(alives)do
        local v = 0
        local num = q(p,"getHandcardNum")
        local discard = math.min(6,num)
        if discard>0 then
            local keep = num-discard
            v = v+discard*1.5
            if keep==0 then
                if q(self,"needKongcheng",p) then
                    v = v-4
                end
                v = v+10
            else
                v = v+1.5 ^ keep
            end
        end
        if self:hasSkills("tiandu|luoying",p) then
            v = v-10
        end
        if self:hasSkills("guanxing|super_guanxing",p) then
            v = v+2
        end
        if q(self,"isFriend",p) then
            v =-v
        end
        value = value+v
    end
    local HanHaoShiHuan = self.room:findPlayerBySkillName("yonglve")
    if HanHaoShiHuan then
        if q(self,"isFriend",HanHaoShiHuan) then
            value = value+10
        else
            value = value-10
        end
    end
    if value>0 then
        if q(self,"getOverflow")>0 or value>6 then
            use.card = card
        end
    end
end
--相关信息：判断是否需要改判
sgs.ai_need_retrial_func["typhoon"] = function(self,judge,isGood,who,isFriend,lord)
    local others = self.room:getOtherPlayers(who)
    local friends,enemies = {},{}
    for _,p in sgs.list(others)do
        if q(who,"distanceTo",p)==1 then
            if q(self,"isFriend",p) then
                table.insert(friends,p)
            else
                table.insert(enemies,p)
            end
        end
    end
    local friend_discard_num,enemy_discard_num = 0,0
    for _,friend in sgs.list(friends)do
        local num = q(friend,"getHandcardNum")
        num = math.min(6,num)
        friend_discard_num = friend_discard_num+num
    end
    for _,enemy in sgs.list(enemies)do
        local num = q(enemy,"getHandcardNum")
        num = math.min(6,num)
        enemy_discard_num = enemy_discard_num+num
    end
    --如果没中奖
    if isGood then
        if friend_discard_num==0 and enemy_discard_num>0 then
            return true
        end
        return false
    end
    --如果中奖
    if enemy_discard_num==0 and friend_discard_num>0 then
        return true
    elseif friend_discard_num>enemy_discard_num+1 then
        return true
    end
    return false
end
--相关信息：改判动机值
sgs.ai_retrial_intention["typhoon"] = function(self,judge,start_good)
    return 0
end
--[[
    卡牌：火山
    效果：将【火山】放置于你的判定区里，回合判定阶段进行判定：若判定结果为♥2~9之间，当前角色受到2点火焰伤害，与当前角色距离为1的角色(无视+1马)受到1点火焰伤害，【火山】生效后即置入弃牌堆。若判定结果不为♥2~9之间，将【火山】移动到当前角色下家的判定区里
]]--
function SmartAIView:useCardVolcano(card,use)
    if q(self.player,"containsTrick","volcano")  then return 
    elseif q(self.player,"isProhibited",self.player,card)  then return
    elseif q(self.player,"containsTrick","YanxiaoCard") and q(self,"getOverflow")>0
    then use.card = card return end
    local finalRetrial,wizard = self:getFinalRetrial()
    known(finalRetrial,"final retrial result")
    if finalRetrial==2
    then return
    elseif finalRetrial==1 then
        use.card = card
        return 
    end
    local careLord = q(self.player,"getRole")=="renegade" and q(self.room,"alivePlayerCount")>2
    local alives = q(self.room,"getAlivePlayers")
    local value = 0
    for _,p in sgs.list(alives)do
        local v = 0
        local damage = 0
        local deathFlag = false
        local can_transfer = false
        local isFriend = q(self,"isFriend",p)
        if q(self,"damageIsEffective",p,sgs.DamageStruct_Fire) then
            damage = 2
            if q(p,"hasArmorEffect","Vine") or q(p,"hasArmorEffect","gale_shell") then
                damage = damage+1
            elseif q(p,"hasSkill","bossmanjia") then
                damage = damage+1
            end
            if q(p,"hasArmorEffect","SilverLion") then
                damage = 1
            end
            if q(p,"hasSkill","tianxiang") then
                can_transfer = true
            elseif q(p,"hasLordSkill","shichou") then
                local others = self.room:getOtherPlayers(p)
                for _,victim in sgs.list(others)do
                    if q(victim,"getMark","@hate_to")>0 then
                        if q(victim,"getMark","hate_"..q(p,"objectName"))>0 then
                            can_transfer = true
                            break
                        end
                    end
                end
            end
        end
        if damage>0 and not can_transfer then
            local hp = q(p,"getHp")
            if hp<=damage then
                if hp+q(self,"getAllPeachNum",p)<=damage then
                    deathFlag = true
                end
            end
            if deathFlag then
                v = v+50
            else
                if self:hasSkills("jianxiong|yiji|nosyiji|fangzhu|jieming|guixin|chengxiang|noschengxiang",p) then
                    v = v-damage
                end
                if q(self,"isWeak",p) then
                    v = v+1
                end
            end
        end
        if self:hasSkills("tiandu|luoying",p) then
            v = v-10
        end
        if self:hasSkills("guanxing|super_guanxing",p) then
            v = v+2
        end
        if isFriend then
            v =-v
        end
        if can_transfer then
            if isFriend then
                v = v+4
            else
                v = v-5
            end
        end
        if deathFlag and careLord and q(p,"isLord") then
            v = v-100
        end
        value = value+v
    end
    local HanHaoShiHuan = self.room:findPlayerBySkillName("yonglve")
    if HanHaoShiHuan then
        if q(self,"isFriend",HanHaoShiHuan) then
            value = value+10
        else
            value = value-10
        end
    end
    if value>0 then
        if q(self,"getOverflow")>0 or value>6 then
            use.card = card
        end
    end
end
--[[
    卡牌：洪水
    效果：将【洪水】放置于你的判定区里，回合判定阶段进行判定：若判定结果为 A,K，从当前角色的牌随机取出和场上存活人数相等的数量置于桌前，从下家开始，每人选一张收为手牌，将【洪水】置入弃牌堆。若判定结果不为AK，将【洪水】移到当前角色下家的判定区里
]]--
function SmartAIView:useCardDeluge(card,use)
    if q(self.player,"containsTrick","deluge") then return 
    elseif q(self.player,"isProhibited",self.player,card) then return
    elseif q(self.player,"containsTrick","YanxiaoCard") and q(self,"getOverflow")>0
    then use.card = card return end
    local finalRetrial,wizard = self:getFinalRetrial()
    known(finalRetrial,"final retrial result")
    if finalRetrial==2
    then return
    elseif finalRetrial==1 then
        use.card = card
        return 
    end
    local alives = q(self.room,"getAlivePlayers")
    local count = alives:length()
    local value = 0
    local function getValue(target)
        local v = 0
        local isFriend = q(self,"isFriend",target)
        local card_count = q(target,"getCardCount",true)
        local throw_count = math.min(card_count,count)
        if throw_count>0 then
            if isFriend then
                v = v-throw_count
            else
                v = v+throw_count
            end
            local the_lucky = q(target,"getNextAlive")
            for i=1,throw_count,1 do
                if q(the_lucky,"hasSkill","manjuan") then
                elseif q(self,"isFriend",the_lucky) then
                    v = v+1
                else
                    v = v-1
                end
                the_lucky = q(the_lucky,"getNextAlive")
            end
        end
        if isFriend then
            if q(target,"hasSkill","tiandu") then
                v = v+1
            end
            if q(target,"hasSkill","luoying") then
                v = v+0.5
            end
        else
            if q(target,"hasSkill","tiandu") then
                v = v-1
            end
            if q(target,"hasSkill","luoying") then
                v = v-0.5
            end
        end
        return v
    end
    local values,targets = {},{}
    for _,p in sgs.list(alives)do
        values[q(p,"objectName")] = getValue(p) or 0
        table.insert(targets,p)
    end
    local compare_func = function(a,b)
        local valueA = values[q(a,"objectName")] or 0
        local valueB = values[q(b,"objectName")] or 0
        return valueA>valueB
    end
    table.sort(targets,compare_func)
    local target = targets[1]
    local target_value = values[q(target,"objectName")] or 0
    value = value+target_value
    local HanHaoShiHuan = self.room:findPlayerBySkillName("yonglve")
    if HanHaoShiHuan then
        if q(self,"isFriend",HanHaoShiHuan) then
            value = value+10
        else
            value = value-10
        end
    end
    if value>0 then
        if q(self,"getOverflow")>0 or value>6 then
            use.card = card
        end
    end
end
--[[
    卡牌：泥石流
    效果：将【泥石流】放置于你的判定区里，回合判定阶段进行判定：若判定结果为黑桃或梅花A,K,4,7，从当前角色开始，每名角色依次按顺序弃置武器、防具、+1马、-1马，无装备者受到1点无属性伤害，当总共被弃置的装备达到4件或你上家结算完成时，【泥石流】停止结算并置入弃牌堆。若判定牌不为黑色AK47，将【泥石流】移动到下家的判定区里
]]--
function SmartAIView:useCardMudslide(card,use)
    if q(self.player,"containsTrick","mudslide") then return 
    elseif q(self.player,"isProhibited",self.player,card) then return
    elseif q(self.player,"containsTrick","YanxiaoCard") and q(self,"getOverflow")>0
    then use.card = card return end
    local finalRetrial,wizard = self:getFinalRetrial()
    known(finalRetrial,"final retrial result")
    if finalRetrial==2 then return
    elseif finalRetrial==1 then
        use.card = card
        return 
    end
    local alives = q(self.room,"getAlivePlayers")
    local value = 0
    local values = {}
    for _,p in sgs.list(alives)do
        values[q(p,"objectName")] = {}
    end
    local starter = q(self.player,"objectName")
    local function getMudSlideValue(target,task)
        if task>0 then
            local v = 0
            local isFriend = q(self,"isFriend",target)
            local e_num = q(target,"getEquips"):length()
            if e_num==0 then --make damage
                if isFriend then
                    v = v-4
                    if self:hasSkills("jianxiong|yiji|nosyiji|fangzhu|jieming|guixin|chengxiang|noschengxiang",target) then
                        if not q(self,"isWeak",target) then
                            v = v+3
                        end
                    end
                else
                    v = v+4
                    if self:hasSkills("jianxiong|yiji|nosyiji|fangzhu|jieming|guixin|chengxiang|noschengxiang",target) then
                        if not q(self,"isWeak",target) then
                            v = v-3
                        end
                    end
                end
            else --discard equips
                if isFriend then
                    if self:hasSkills(sgs.lose_equip_skill,target) then
                        v = v+e_num*2
                    end
                    if target:getArmor() and q(self,"needToThrowArmor",target) then
                        v = v+1.5
                    end
                else
                    if self:hasSkills(sgs.lose_equip_skill,target) then
                        v = v-e_num*2
                    end
                    if target:getArmor() and q(self,"needToThrowArmor",target) then
                        v = v-1.5
                    end
                end
            end
            if isFriend then
                if q(target,"hasSkill","tiandu") then
                    v = v+1
                end
                if q(target,"hasSkill","luoying") then
                    v = v+0.5
                end
            else
                if q(target,"hasSkill","tiandu") then
                    v = v-1
                end
                if q(target,"hasSkill","luoying") then
                    v = v-0.5
                end
            end
            table.insert(values[q(target,"objectName")],v)
            task = task-e_num
            local next_target = q(target,"getNextAlive")
            if q(next_target,"objectName")~=starter and task>0 then
                getMudSlideValue(next_target,task)
            end
        end
    end
    for _,p in sgs.list(alives)do
        getMudSlideValue(p,4)
    end
    for _,p in sgs.list(alives)do
        local pv,pc = 0,0
        for _,v in sgs.list(values[q(p,"objectName")])do
            pv = pv+v
            pc = pc+1
        end
        if pc>0 then
            value = value+pv/pc
        end
    end
    local HanHaoShiHuan = self.room:findPlayerBySkillName("yonglve")
    if HanHaoShiHuan then
        if q(self,"isFriend",HanHaoShiHuan) then
            value = value+5
        else
            value = value-5
        end
    end
    if value>0 then
        if q(self,"getOverflow")>0 or value>4 then
            use.card = card
        end
    end
end
