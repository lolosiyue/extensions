local extension = sgs.Package("birth", sgs.Package_CardPack)

sgs.LoadTranslationTable{
    ["birth"] = "初生包",
    
    ["Qiulong"] = "囚笼",
    [":Qiulong"] = "宝物牌<br>当你造成伤害后，你可以令其进入休整状态直到此牌进入弃牌堆。",
    [":Qiulong1"] = "宝物牌<br>当你造成伤害后，你可以令其进入休整状态直到此牌进入弃牌堆。<br><font color='#FF8C00'>当前关押：%prisoner%</font>",
    ["qiulong"] = "囚笼",
    ["#QiulongEffect"] = "%from 发动了【囚笼】效果，令 %to 进入休整状态",
    ["#QiulongLose"] = "%from 的【囚笼】进入了弃牌堆，%to 从休整状态中恢复",
    ["qiulong:rest"] = "你可以令 %src 进入休整状态直到【囚笼】进入弃牌堆",
    
    -- 测试武将
    ["TestGeneral"] = "测试武将",
    ["test_rest"] = "测试休整",
    [":test_rest"] = "锁定技，回合结束时，你进入休整状态。",
    ["#TestRestLog"] = "%from 发动了【测试休整】，进入休整状态",
}

sgs.LoadTranslationTable{
["shilaiyunzhuan"]="时来运转",
[":shilaiyunzhuan"]="锦囊牌<br/>出牌阶段，对自己使用。反转出牌顺序。",
[":shilaiyunzhuan1"]="锦囊牌<br/>出牌阶段，对自己使用。反转出牌顺序。<br/><font color='#00BFFF'>当前出牌顺序：%order_direction%</font>",
["clockwise"]="顺时针",
["counterclockwise"]="逆时针",
}

-- 伤害由装备来源授权；关押记录属于实体牌，离开装备区后仍持续。
local QiulongSkill = sgs.CreateEquipSkillV2{
    name = "#QiulongSkill", equipment = "Qiulong", equipment_type = "treasure",
    events = {sgs.Damage},
    can_trigger = function(self, event, room, player, data)
        if not player then return "" end
        local victim = data:toDamage().to
        local card = player:getTreasure()
        if not victim or victim:isRest() or not card or not card:isKindOf("Qiulong") then return "" end
        local current = room:getTag("QiulongTarget_" .. card:getEffectiveId()):toPlayer()
        if current and current:isRest() then return "" end
        return self:objectName(), player
    end,
    on_cost = function(self, event, room, player, ctx)
        return player:askForSkillInvoke("qiulong", ctx.original_data)
    end,
    on_effect = function(self, event, room, player, ctx)
        local card = player:getTreasure()
        local victim = ctx.original_data:toDamage().to
        if not card or not card:isKindOf("Qiulong") or not victim or victim:isRest() then return false end
        local key = "QiulongTarget_" .. card:getEffectiveId()
        local value = sgs.QVariant(); value:setValue(victim); room:setTag(key, value)
        room:notifySkillInvoked(player, "qiulong")
        local log = sgs.LogMessage(); log.type = "#QiulongEffect"; log.from = player; log.to:append(victim); room:sendLog(log)
        room:directRestPlayer(victim, "qiulong", false)
        room:updateCardDescription("Qiulong", {["%prisoner%"] = victim:getGeneralName()})
        return false
    end,
}
local QiulongRelease = sgs.CreateRuleSkillV2{
    name = "#QiulongRelease", events = {sgs.CardsMoveOneTime},
    can_trigger = function() return "" end,
    on_record = function(self, event, room, player, ctx)
        -- 不依赖当前装备者：equip -> hand -> discard 也必须解除同一卡牌的关押。
        local move = ctx.original_data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile then return end
        for _, id in sgs.qlist(move.card_ids) do
            if sgs.Sanguosha:getCard(id):isKindOf("Qiulong") then
                local key = "QiulongTarget_" .. id
                local victim = room:getTag(key):toPlayer()
                if victim and victim:isRest() then
                    local log = sgs.LogMessage(); log.type = "#QiulongLose"; log.from = move.from or player; log.to:append(victim); room:sendLog(log)
                    room:unrestPlayer(victim, false)
                    room:removeTag(key)
                    room:updateCardDescription("Qiulong", {["%prisoner%"] = "无"})
                end
            end
        end
    end,
}
addToSkills(QiulongRelease)
local Qiulong = sgs.CreateTreasure{
    name = "Qiulong", class_name = "Qiulong", equip_skill = QiulongSkill,
}
local qiulong = Qiulong:clone(); qiulong:setSuit(sgs.Card_Spade); qiulong:setNumber(5); qiulong:setParent(extension)

local shilaiyunzhuan = sgs.CreateTrickCard{
    name = "shilaiyunzhuan", class_name = "shilaiyunzhuan",
    subclass = sgs.LuaTrickCard_TypeSingleTargetTrick, target_fixed = true,
    can_recast = false, is_cancelable = true,
    on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self, effect)
        local room = effect.to:getRoom()
        room:reversePlayOrder()
        room:updateCardDescription("shilaiyunzhuan", {
            ["%order_direction%"] = room:isPlayOrderReversed() and "counterclockwise" or "clockwise",
        })
    end,
}
for i = 0, 10 do
    local card = shilaiyunzhuan:clone(); card:setSuit(i % 4); card:setNumber((i % 13) + 1); card:setParent(extension)
end

return extension
