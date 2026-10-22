
-- Instance state contains only serializable values; event actors stay in ctx.invoker.
local function state(player, ref, key)
    return player:getSkillInstanceStateValue(ref.key.skillName, ref.key.instanceID, key)
end
local function setstate(player, ref, key, value)
    player:setSkillInstanceStateValue(ref.key.skillName, ref.key.instanceID, key, sgs.QVariant(value))
end
local function own(self, event, room, player, data)
    if player and player:isAlive() and player:hasSkill(self:objectName()) then return self:objectName(), player end
    return ""
end
local function owners(self, room)
    local names, players = {}, {}
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:hasSkill(self:objectName()) then
            table.insert(names, self:objectName()); table.insert(players, p:objectName())
        end
    end
    return table.concat(names, "|"), table.concat(players, "|")
end
local function invoke(self, event, room, player, ctx)
    return room:askForSkillInvoke(player, self:objectName(), ctx.original_data)
end
local function log(room, kind, from, to, arg, arg2)
    local entry = sgs.LogMessage(); entry.type = kind; entry.from = from
    if to then entry.to:append(to) end
    if arg then entry.arg = tostring(arg) end
    if arg2 then entry.arg2 = tostring(arg2) end
    room:sendLog(entry)
end
local function requestRef(request)
    local key=sgs.SkillInstanceKey();key.skillName=request:getActivationSkillName();key.instanceID=request:getActivationInstanceId()
    return sgs.SkillInstanceRef(request:getInitiator():objectName(),key)
end
local function play(request)
    return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
end
local function exactName(ref)
    return ref.key:toString()
end

-- Wall-clock game duration; GameStart is recorded per instance, Room has no elapsed API.
local function gameElapsedSeconds(player, ref)
    local t0 = state(player, ref, "game_start"):toInt()
    if t0 <= 0 then return 0 end
    return math.max(0, os.time() - t0)
end

local function observedSkill(event, data)
    local name
    if event == sgs.SkillTriggered then name = data:toString()
    else
        local context = data:toSkillContext()
        local ref = context:getActivationRef()
        name = ref:isValid() and ref.key.skillName or context.skill_name
        local definition = sgs.Sanguosha:getSkill(name)
        -- Ownerless rules are not borrowable player skills.
        if not ref:isValid() and definition and definition:inherits("TriggerSkillV2") then return nil end
        -- Legacy trigger adapters emit SkillTriggered as well; consume it once.
        if definition and definition:inherits("TriggerSkill") and not definition:inherits("TriggerSkillV2") then return nil end
    end
    local skill = sgs.Sanguosha:getSkill(name)
    if not skill or skill:isEquipSkill() or name == "c_huaming" or name == "c_ji_jizhan"
        or name:sub(1, 1) == "#" then return nil end
    return name
end

local function hasThreeInvocations(room, player)
    local turn = room:historyScopes().turn_id
    if not turn or turn == "0" then return false end
    local filter = {kind = "skill_invoked", turn_id = turn, player = player:objectName(), limit = 64}
    local count = 0
    while true do
        local page = room:queryHistoryFacts(filter)
        if page.error or not page.complete then
            error("c_ji_jizhan: invocation history is incomplete")
        end
        -- Actor is explicitly recorded; unknown legacy source ownership is irrelevant.
        for _, fact in ipairs(page.items) do
            local name = fact.data.invoked_skill
            local skill = name and sgs.Sanguosha:getSkill(name)
            if skill and not skill:isEquipSkill() and name:sub(1, 1) ~= "#"
                and name ~= "c_huaming" and name ~= "c_ji_jizhan" then count = count + 1 end
        end
        if count >= 3 then return true end
        if not page.has_more then return false end
        filter.watermark = filter.watermark or page.watermark
        filter.after = page.next_after
    end
end

local extension = sgs.Package("cdiy",sgs.Package_GeneralPack)
sgs.LoadTranslationTable {
["cdiy"]="人间包",
}

--[[
有bug,别管了

--祝融
sgs.LoadTranslationTable {
["C_zhurong"]="祝融",
["#C_zhurong"]="南蛮女将",
}

C_zhurong = sgs.General(extension, "C_zhurong", "shu", 4,false)



c_feirenVS = sgs.CreateZeroCardViewAsSkill{
	name = "c_feiren",
	view_as = function(self)
		local cards = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		cards:setSkillName(self:objectName())
		return cards
	end,
	enabled_at_play = function(self, player)
		local weapon = player:getWeapon()
		if weapon then
			if player:getWeaponRange() > 0 then
				return sgs.Slash_IsAvailable(player)
			end
		end
	end,
	enabled_at_response = function(self, player, pattern)
		local weapon = player:getWeapon()
		return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and weapon~= nil and weapon:getWeaponRange() > 0
	end
}
c_feiren = sgs.CreateTriggerSkill{
	name = "c_feiren",
	view_as_skill = c_feirenVS,
	events = {sgs.PreCardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		local weapon = player:getWeapon()
		room:notifyWeaponRange("kylin_bow",2)

		if weapon ~= nil then
			local range = player:getWeaponRange()
			room:writeToConsole("weapon:"..weapon:objectName())
			room:writeToConsole("range"..range)
			local index = player:getWeaponRange()-1

			room:writeToConsole("index"..index)
			player:obtainCard(weapon)
			if index > 0 then

				room:notifyWeaponRange(weapon:objectName(),index)
				room:writeToConsole("修改后"..player:getWeaponRange())

			else
				room:breakCard(weapon)
			end
		end
		room:writeToConsole(player:getWeaponRange())
	end
}


C_zhurong:addSkill(c_feiren)
C_zhurong:addSkill("paoxiao")

]]--

--马钧

sgs.LoadTranslationTable {
["C_majun"]="人间-马钧",
["&C_majun"]="马钧",
["cs_mingli_msg"]="你可以将你的装备区内的武器或防具牌移除,并摸X张牌（X为此牌名字长度）",
[":cs_mingli"]="回合开始或结束时,你可以将你的装备区内的武器或防具牌销毁",
["cs_mingli"]="明理",
["cs_jinggong"]="精工",
[":cs_jinggong"]="当你通过【明理】销毁装备牌后,你视为装备之",
}

C_majun = sgs.General(extension, "C_majun", "wei", 3)
C_majun:setImage("majun")

cs_mingli = sgs.CreateTriggerSkillV2{
    name = "cs_mingli", events = {sgs.EventPhaseStart}, frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if player and (player:getPhase()==sgs.Player_Start or player:getPhase()==sgs.Player_Finish)
            and (player:getWeapon() or player:getArmor()) then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost = function(self,event,room,player,ctx)
        local choices={}; if player:getWeapon() then table.insert(choices,"weapon") end
        if player:getArmor() then table.insert(choices,"armor") end
        table.insert(choices,"cancel")
        ctx.choice=room:askForChoice(player,self:objectName(),table.concat(choices,"+"),sgs.QVariant(),nil,"cs_mingli_msg")
        if ctx.choice=="cancel" then return false end
        local card=ctx.choice=="weapon" and player:getWeapon() or player:getArmor()
        if not card then return false end
        ctx.extra_data=sgs.QVariant(card:getEffectiveId()); ctx.choice=tostring(card:nameLength()); return true
    end,
    on_pay = function(self,event,room,player,ctx)
        local card=sgs.Sanguosha:getCard(ctx.extra_data:toInt())
        if room:getCardOwner(card:getEffectiveId())~=player or room:getCardPlace(card:getEffectiveId())~=sgs.Player_PlaceEquip then return false end
        local stored=state(player,ctx:getActivationRef(),"equipment"):toString()
        setstate(player,ctx:getActivationRef(),"equipment",stored=="" and card:objectName() or stored..","..card:objectName())
        room:breakCard(card); return true
    end,
    on_effect = function(self,event,room,player,ctx) player:drawCards(tonumber(ctx.choice) * self:getEffectiveAmount(ctx),self:objectName()); return false end
}

-- ViewAsEquip has its own equipment-grant contract, not a Trigger/Active V2 factory.
cs_jinggong = sgs.CreateViewAsEquipSkill{
    name="cs_jinggong",
    view_as_equip=function(self,player)
        local equips={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds("cs_mingli")) do
            local names=player:getSkillInstanceStateValue("cs_mingli",id,"equipment"):toString()
            if names~="" then table.insert(equips,names) end
        end
        return table.concat(equips,",")
    end
}

C_majun:addSkill(cs_mingli)
C_majun:addSkill(cs_jinggong)



--急急许褚
sgs.LoadTranslationTable {
["C_Jixuchu"]="人间-许褚",
["&C_Jixuchu"]="许褚",
["#C_Jixuchu"]="急急国王",
["c_ji_jizhan"]="急斩",
["jiji"]="好急啊",
["jiji-Clear"]="好急啊",
[":c_ji_jizhan"]="当有角色于一回合内使用技能累计3次或以上时,你可以视为对其使用1张【杀】（此技能不咋完善）",
["@jizhan_msg"]="你可以视为对 【%src】 使用一张【杀】",
}

C_Jixuchu = sgs.General(extension, "C_Jixuchu", "wei", 4)
C_Jixuchu:setImage("xuchu")
C_Jixuchu:addSkill("luoyi")



c_ji_jizhan = sgs.CreateTriggerSkillV2{
    name="c_ji_jizhan", events={sgs.EventSkillInvoking, sgs.SkillTriggered},

    can_trigger=function(self,event,room,player,data)
        if not player or not player:isAlive() or not observedSkill(event, data) then return "" end
        if not hasThreeInvocations(room, player) then return "" end
        local names,holders={},{}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p~=player and p:hasSkill(self:objectName()) then table.insert(names,self:objectName());table.insert(holders,p:objectName()) end
        end
        return table.concat(names,"|"),table.concat(holders,"|")
    end,
    on_cost=function(self,event,room,player,ctx)
        local data=sgs.QVariant();data:setValue(ctx.invoker)
        return room:askForSkillInvoke(player,self:objectName(),data)
    end,
    on_effect=function(self,event,room,player,ctx)
        local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0);slash:setSkillName(self:objectName())
        room:useCard(sgs.CardUseStruct(slash,player,ctx.invoker));return false
    end
}

C_Jixuchu:addSkill(c_ji_jizhan)


--背诗曹植

C_caozhi = sgs.General(extension, "C_caozhi", "wei", 3)
C_caozhi:setImage("caozhi")
sgs.LoadTranslationTable {
["C_caozhi"]="人间-曹植",
["&C_caozhi"]="曹植",
["c_chengzhang"]="成章",
[":c_chengzhang"]="出牌阶段,你可以吟诵一句曹植的诗,若成功则摸1张牌,否则技能失效直至回合结束",
["c_chengzhang_tip"]="请开始朗诵,禁止重复",
["你好"]="111",

}
local caozhi_poem = {
    -- 七步诗双版本合并
    "煮豆持作羹", "漉菽以为汁", "萁在釜下燃", "豆在釜中泣", "本自同根生", "相煎何太急",  -- 网页1/2/5/8
    "煮豆燃豆萁", "豆在釜中泣", "本是同根生", "相煎何太急",  -- 网页2/5/8

    -- 白马篇全诗
    "白马饰金羁", "连翩西北驰", "借问谁家子", "幽并游侠儿", "少小去乡邑", "扬声沙漠垂",  -- 网页2/5/7/8
    "宿昔秉良弓", "楛矢何参差", "控弦破左的", "右发摧月支", "仰手接飞猱", "俯身散马蹄",
    "狡捷过猴猿", "勇剽若豹螭", "边城多警急", "虏骑数迁移", "羽檄从北来", "厉马登高堤",
    "长驱蹈匈奴", "左顾凌鲜卑", "弃身锋刃端", "性命安可怀", "父母且不顾", "何言子与妻",
    "名编壮士籍", "不得中顾私", "捐躯赴国难", "视死忽如归",  -- 网页2/5/7/8

    -- 洛神赋全段
    "翩若惊鸿", "婉若游龙", "荣曜秋菊", "华茂春松", "髣髴兮若轻云之蔽月",  -- 网页3/5/7/8
    "飘飖兮若流风之回雪", "远而望之，皎若太阳升朝霞", "迫而察之，灼若芙蕖出渌波",
    "秾纤得衷，修短合度", "肩若削成，腰如约素", "延颈秀项，皓质呈露", "芳泽无加，铅华弗御",
    "云髻峨峨，修眉联娟", "丹唇外朗，皓齿内鲜", "明眸善睐，靥辅承权", "瓌姿艳逸，仪静体闲",
    "柔情绰态，媚于语言", "奇服旷世，骨像应图", "披罗衣之璀粲兮", "珥瑶碧之华琚",
    "戴金翠之首饰", "缀明珠以耀躯", "践远游之文履", "曳雾绡之轻裾",  -- 网页3/5/7/8

    -- 杂诗系列
    "南国有佳人", "容华若桃李", "朝游江北岸", "夕宿潇湘沚", "时俗薄朱颜", "谁为发皓齿",  -- 网页2/5/7/8
    "俯仰岁将暮", "荣曜难久恃", "高树多悲风", "海水扬其波", "利剑不在掌", "结友何须多",  -- 网页2/5/7

    -- 其他名篇
    "明月照高楼", "流光正徘徊", "上有愁思妇", "悲叹有余哀",  -- 网页2/5/7/8
    "君若清路尘", "妾若浊水泥", "愿为西南风", "长逝入君怀",  -- 网页2/5/7
    "罗衣何飘飘", "轻裾随风还", "顾盼遗光彩", "长啸气若兰",  -- 网页3/5/7
    "潜鱼跃清波", "好鸟鸣高枝", "秋兰被长坂", "朱华冒绿池",  -- 网页2/5/7

    -- 新增网页10中赠丁翼诗
    "嘉宾填城阙", "丰膳出中厨", "吾与二三子", "曲宴此城隅",  -- 网页1/4/5
    "秦筝发西气", "齐瑟扬东讴", "肴来不虚归", "觞至反无余",

    -- 新增网页4中大魏篇
    "大魏应灵符", "天禄方甫始", "圣德致泰和", "神明为驱使",  -- 网页4/5
    "储礼如江海", "积善若陵山", "皇嗣繁且炽", "孙子列曾玄",

       "嘉宾填城阙", "丰膳出中厨", "吾与二三子", "曲宴此城隅",  -- 网页1
    "秦筝发西气", "齐瑟扬东讴", "大国多良材", "譬海出明珠",  -- 网页1
    "大魏应灵符", "天禄方甫始", "圣德致泰和", "神明为驱使",  -- 网页1
    "储礼如江海", "积善若陵山", "皇嗣繁且炽", "孙子列曾玄",  -- 网页1
    "精微烂金石", "至心动神明", "杞妻哭死夫", "梁山为之倾",  -- 网页1
    "子丹西质秦", "乌白马角生", "邹衍囚燕市", "繁霜为夏零",  -- 网页1
    "来日大难", "口燥唇干", "今日相乐", "皆当喜欢",  -- 网页1
    "经历名山", "芝草翩翩", "仙人王乔", "奉药一丸",  -- 网页1
    "行游到日南", "经历交址乡", "苦热但曝露", "越夷水中藏",  -- 网页1
    "弹筝奋逸响", "新声好入神", "仆夫早严驾", "吾行将远游",  -- 网页3
    "八方各异气", "千里殊风雨", "剧哉边海民", "寄身于草野",  -- 网页3
    "妻子象禽兽", "行止依林阻", "柴门何萧条", "狐兔翔我宇",  -- 网页3
    "天地无穷极", "阴阳转相因", "人居一世间", "忽若风吹尘",  -- 网页3
    "愿得展功勤", "输力于明君", "怀此王佐才", "慷慨独不群",  -- 网页3
    "浮萍寄清水", "随风东西流", "结发辞严亲", "来为君子仇",  -- 网页4
    "恪勤在朝夕", "无端获罪尤", "在昔蒙恩君", "和乐如瑟琴",  -- 网页4
    "何意今摧颓", "旷若商与参", "茱萸自有芳", "不若桂与兰",  -- 网页4
    "行云有返期", "君恩傥中还", "慊慊仰天叹", "愁心将何愬",  -- 网页4
    "高台多悲风", "朝日照北林", "之子在万里", "江湖逈且深",  -- 网页5
    "方舟安可极", "离思故难任", "孤鴈飞南游", "过庭长哀吟",  -- 网页5
    "转蓬离本根", "飘飖随长风", "何意回飚举", "吹我入云中",  -- 网页5
    "飞观百余尺", "临牖御棂轩", "烈士多悲心", "小人偷自闲",  -- 网页5
    "弦急悲声发", "聆我慷慨言", "揽衣出中闺", "逍遥步两楹",  -- 网页5
    "潜光养羽翼", "进趣且徐徐", "不见昔轩辕", "升龙出鼎湖",  -- 网页4
    "鰕䱇游潢潦", "不知江海流", "世士此诚明", "大德固无俦",  -- 网页4
    "晨游泰山", "云雾窈窕", "忽逢二童", "颜色鲜好",  -- 网页4
    "乘彼白鹿", "手翳芝草", "授我仙药", "神皇所造",  -- 网页4
    "行女生于季秋", "而终于首夏", "三年之中", "二子频丧",  -- 网页4
    "仰彼朔风", "用怀魏都", "愿骋代马", "倏忽北徂",  -- 网页5
    "凯风永至", "思彼蛮方", "愿随越鸟", "翻飞南翔",  -- 网页5
    "四气代谢", "悬景运周", "别如俯仰", "脱若三秋",  -- 网页5
    "昔我初迁", "朱华未希", "今我旋止", "素雪云飞",  -- 网页5
    "俯降千仞", "仰登天阻", "风飘蓬飞", "载离寒暑"  -- 网页5
}


-- 成章 is a V2 custom action; no SkillCard shell.
c_chengzhangVS = sgs.CreateViewAsSkillV2{
    name="c_chengzhang", target_mode=sgs.ViewAsSkillV2_NoTarget,
    can_activate=function(self,request)
        return play(request) and not state(request:getInitiator(),requestRef(request),"failed"):toBool()
    end,
    cost=function(self,room,ctx,request)
        local source=ctx.invoker
        local aisay=caozhi_poem[math.random(1,#caozhi_poem)]
        source:setTag("c_chengzhang_ai",sgs.QVariant(aisay))
        ctx.choice=source:getState()=="robot" and aisay or room:askForChoice(source,"c_chengzhang","#INPUT",sgs.QVariant(),nil,"c_chengzhang_tip")
        source:removeTag("c_chengzhang_ai")
        return true -- An incorrect/cancelled recital is a failed attempt in the donor.
    end,
    on_effect=function(self,ctx)
        local source=ctx.invoker
        local list=state(source,ctx:getActivationRef(),"poem"):toString():split("+")
        if table.contains(caozhi_poem,ctx.choice) and not table.contains(list,ctx.choice) then
            table.insert(list,ctx.choice);setstate(source,ctx:getActivationRef(),"poem",table.concat(list,"+"));source:drawCards(self:getEffectiveAmount(ctx))
        else setstate(source,ctx:getActivationRef(),"failed",true) end
        source:speak(ctx.choice)
    end
}
c_chengzhang = sgs.CreateTriggerSkillV2{
    name="c_chengzhang",view_as_skill=c_chengzhangVS,events={sgs.EventPhaseChanging},
    on_record=function(self,event,room,player,ctx)
        if ctx.original_data:toPhaseChange().to==sgs.Player_NotActive then setstate(ctx.owner,ctx:getActivationRef(),"failed",false) end
    end,
    can_trigger=function() return "" end
}

C_caozhi:addSkill(c_chengzhang)




--淳于琼


C_chunyuqiong = sgs.General(extension, "C_chunyuqiong", "qun", 4)
C_chunyuqiong:setImage("chunyuqiong")
sgs.LoadTranslationTable{
["C_chunyuqiong"]="人间-淳于琼",
["&C_chunyuqiong"]="淳于琼",
["#C_chunyuqiong"]="乌巢酒徒",
["c_jiukuang"]="酒狂",
[":c_jiukuang"]="锁定技，每当你失去一张手牌后，你翻面并视为使用一张【酒】",

}

c_jiukuang = sgs.CreateTriggerSkillV2{
    name="c_jiukuang",frequency=sgs.Skill_Compulsory,events={sgs.CardsMoveOneTime},
    can_trigger=function(self,event,room,player,data)
        local move=data:toMoveOneTime()
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) then
            return own(self,event,room,room:findPlayerByObjectName(move.from:objectName()),data)
        end
        return ""
    end,
    on_effect=function(self,event,room,player,ctx)
        player:turnOver()
        local card=sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0);card:setSkillName(self:objectName())
        room:useCard(sgs.CardUseStruct(card,player,player),false);return false
    end
}


C_chunyuqiong:addSkill(c_jiukuang)


--孙皓

C_sunhao = sgs.General(extension, "C_sunhao$", "wu", 6)
C_sunhao:setImage("sunhao")
sgs.LoadTranslationTable{
    ["C_sunhao"] = "人间-孙皓",
    ["&C_sunhao"] = "孙皓",
    ["#C_sunhao"] = "末世暴君",
    ["c_canshi"] = "残噬",
    [":c_canshi"] = "锁定技，回合开始后，你将你回合内最后一个不为出牌阶段的阶段永久替换为出牌阶段。出牌阶段开始时，你摸3张牌并失去1点体力。",
    ["#c_canshi"] = "%from 的【%arg】被触发，将会把 %arg2 替换为出牌阶段",
    ["#c_canshi_change"] = "%from 的【残噬】效果发动，%arg 阶段被替换为 %arg2阶段",
    ["#c_canshi_play"] = "%from 的【残噬】效果发动，摸3张牌并失去1点体力",

    -- 添加阶段名翻译
    ["start"] = "准备阶段",
    ["judge"] = "判定阶段",
    ["draw"] = "摸牌阶段",
    ["play"] = "出牌阶段",
    ["discard"] = "弃牌阶段",
    ["finish"] = "结束阶段",
    ["not_active"] = "回合外"
}

c_canshi = sgs.CreateTriggerSkillV2{
    name = "c_canshi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TurnStarted, sgs.EventPhaseChanging, sgs.EventPhaseStart},
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local room = player:getRoom()

        -- 使用翻译表获取阶段名
        local function getPhaseString(phase)
            local phase_strings = {
                [sgs.Player_Start] = "start",
                [sgs.Player_Judge] = "judge",
                [sgs.Player_Draw] = "draw",
                [sgs.Player_Play] = "play",
                [sgs.Player_Discard] = "discard",
                [sgs.Player_Finish] = "finish",
                [sgs.Player_NotActive] = "not_active"
            }
            -- 使用三国杀的翻译系统
            return phase_strings[phase]
        end

        -- 标准阶段序列（从后往前的顺序，除了出牌阶段）
        local standard_phases = {
            sgs.Player_Finish,   -- 结束阶段
            sgs.Player_Discard,  -- 弃牌阶段
            sgs.Player_Draw,     -- 摸牌阶段
            sgs.Player_Judge,    -- 判定阶段
            sgs.Player_Start     -- 准备阶段
        }

        if event == sgs.TurnStarted then
            if player:hasSkill(self:objectName()) then
                -- 初始时记录最后一个非出牌阶段
                local phase_list = {}
                local old_phases = state(player,ctx:getActivationRef(),"phases"):toString()

                if old_phases == "" then
                    -- 初次设置，默认替换结束阶段
                    phase_list = {sgs.Player_Finish}
                    setstate(player,ctx:getActivationRef(),"phases",table.concat(phase_list, ","))

                    -- 通知玩家技能发动
                    room:notifySkillInvoked(player, self:objectName())
                    local msg = sgs.LogMessage()
                    msg.type = "#c_canshi"
                    msg.from = player
                    msg.arg = self:objectName()
                    msg.arg2 = getPhaseString(sgs.Player_Finish)
                    room:sendLog(msg)
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()

            -- 如果进入回合结束时，尝试记录新的阶段
            if change.to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
                local phase_list = {}
                local old_phases = state(player,ctx:getActivationRef(),"phases"):toString()

                if old_phases ~= "" then
                    for _, phase in ipairs(old_phases:split(",")) do
                        table.insert(phase_list, tonumber(phase))
                    end
                end

                -- 从标准阶段中找出下一个未被记录的阶段
                local next_phase = nil
                for _, standard_phase in ipairs(standard_phases) do
                    local already_recorded = false
                    for _, recorded_phase in ipairs(phase_list) do
                        if recorded_phase == standard_phase then
                            already_recorded = true
                            break
                        end
                    end

                    if not already_recorded then
                        next_phase = standard_phase
                        break
                    end
                end

                if next_phase then
                    table.insert(phase_list, next_phase)
                    setstate(player,ctx:getActivationRef(),"phases",table.concat(phase_list, ","))

                    -- 通知玩家技能发动
                    room:notifySkillInvoked(player, self:objectName())
                    local msg = sgs.LogMessage()
                    msg.type = "#c_canshi"
                    msg.from = player
                    msg.arg = self:objectName()
                    msg.arg2 = getPhaseString(next_phase)
                    room:sendLog(msg)
                end
            end

            -- 处理阶段替换
            local phase_list = {}
            local old_phases = state(player,ctx:getActivationRef(),"phases"):toString()

            if old_phases ~= "" then
                for _, phase in ipairs(old_phases:split(",")) do
                    table.insert(phase_list, tonumber(phase))
                end

                -- 检查当前阶段是否需要被替换
                for _, recorded_phase in ipairs(phase_list) do
                    if change.to == recorded_phase then
                        -- 替换为出牌阶段
                        change.to = sgs.Player_Play
                        data:setValue(change)

                        -- 通知阶段变更
                        local msg = sgs.LogMessage()
                        msg.type = "#c_canshi_change"
                        msg.from = player
                        msg.arg = getPhaseString(recorded_phase)
                        msg.arg2 = getPhaseString(sgs.Player_Play)
                        room:sendLog(msg)
                        break
                    end
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
                -- 出牌阶段开始时，失去1点体力并摸3张牌
                room:notifySkillInvoked(player, self:objectName())

                -- 记录日志
                local msg = sgs.LogMessage()
                msg.type = "#c_canshi_play"
                msg.from = player
                room:sendLog(msg)

                player:drawCards(3 * self:getEffectiveAmount(ctx))
				room:loseHp(player, 1, true, player, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self,event,room,player,data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return "" end
        local names={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds(self:objectName())) do
            local recorded=player:getSkillInstanceStateValue(self:objectName(),id,"phases"):toString()
            local applies=event==sgs.TurnStarted and recorded==""
            if event==sgs.EventPhaseStart then applies=player:getPhase()==sgs.Player_Play end
            if event==sgs.EventPhaseChanging then
                local change=data:toPhaseChange();local count=0
                for _,phase in ipairs(recorded:split(",")) do
                    if tonumber(phase) then count=count+1;if tonumber(phase)==change.to then applies=true end end
                end
                if change.to==sgs.Player_NotActive and count<5 then applies=true end
            end
            if applies then table.insert(names,self:objectName().."#"..id) end
        end
        return table.concat(names,"+"),player
    end
}

C_sunhao:addSkill(c_canshi)

-- 孙皓的主公技
sgs.LoadTranslationTable{
    ["c_daijun"] = "代君",
    [":c_daijun"] = "主公技，游戏开始时，其他吴势力角色选择一项：1.令你加1点体力上限和体力；2.令你减少1点体力上限。",
    ["c_daijun_buff"] = "增益",
    ["c_daijun_debuff"] = "削弱",
    ["c_daijun_buff:buff"] = "令孙皓加1点体力上限和体力",
    ["c_daijun_buff:debuff"] = "令孙皓减少1点体力上限",
    ["#c_daijun_buff"] = "%from 选择了令 %to 加1点体力上限和体力",
    ["#c_daijun_debuff"] = "%from 选择了令 %to 减少1点体力上限",
    ["c_daijun_buff_tip"] = "请选择增加其体力上限或减少"

}


c_daijun = sgs.CreateTriggerSkillV2{
    name = "c_daijun$",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    can_trigger = function(self,event,room,player,data)
        if player and player:isLord() then return own(self,event,room,player,data) end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local room = player:getRoom()
        if not player:isLord() then return end
        local players = room:getOtherPlayers(player)
        for _, p in sgs.qlist(players) do
            if p:getKingdom() == "wu" then
                local choices = "c_daijun_buff+c_daijun_debuff"
				local data = sgs.QVariant()
				data:setValue(player)
                local choice = room:askForChoice(p, "c_daijun_buff", choices,data,nil,"c_daijun_buff_tip")

                if choice == "c_daijun_buff" then
                    -- 玩家选择增加孙皓的体力上限和体力
                    room:notifySkillInvoked(player, self:objectName())

                    -- 记录日志
                    local msg = sgs.LogMessage()
                    msg.type = "#c_daijun_buff"
                    msg.from = p
                    msg.to:append(player)
                    room:sendLog(msg)

                    -- 增加体力上限和体力
                    room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
                    room:recover(player, sgs.RecoverStruct(p, nil, 1))
                else
                    -- 玩家选择减少孙皓的体力上限
                    room:notifySkillInvoked(player, self:objectName())

                    -- 记录日志
                    local msg = sgs.LogMessage()
                    msg.type = "#c_daijun_debuff"
                    msg.from = p
                    msg.to:append(player)
                    room:sendLog(msg)

                    -- 减少体力上限，同时确保体力值不超过新的体力上限
                    local new_maxhp = player:getMaxHp() - 1
                    room:setPlayerProperty(player, "maxhp", sgs.QVariant(new_maxhp))

                    -- 如果当前体力值超过新的体力上限，则调整体力值
                    if player:getHp() > new_maxhp then
                        room:setPlayerProperty(player, "hp", sgs.QVariant(new_maxhp))
                    end
                end
            end
        end
        return false
    end,

}


C_sunhao:addSkill(c_daijun)

--左慈

C_zuoci = sgs.General(extension, "C_zuoci", "qun", 3)
C_zuoci:setImage("zuoci")
sgs.LoadTranslationTable{
    ["C_zuoci"] = "人间-左慈",
    ["&C_zuoci"] = "左慈",
    ["#C_zuoci"] = "神化方士",
    ["c_huaming"] = "化名",
    [":c_huaming"] = "锁定技，你视为拥有最近场上发动的三个技能(本技能除外)。",
    ["#c_huaming_acquire"] = "%from 的【化名】效果获得了技能【%arg】"
}

c_huaming = sgs.CreateTriggerSkillV2{
    name="c_huaming",frequency=sgs.Skill_Compulsory,events={sgs.EventSkillInvoking, sgs.SkillTriggered},
    can_trigger=function(self,event,room,player,data)
        if not observedSkill(event, data) then return "" end
        return owners(self,room)
    end,
    on_effect=function(self,event,room,player,ctx)
        local name=observedSkill(event, ctx.original_data)
        if not name then return false end
        local recorded=state(player,ctx:getActivationRef(),"skills"):toString():split(",")
        for i=#recorded,1,-1 do if recorded[i]==name or recorded[i]=="" then table.remove(recorded,i) end end
        table.insert(recorded,1,name);while #recorded>3 do table.remove(recorded) end
        local parent = ctx:getActivationRef()
        local retained, acquired = {}, {}
        for _, skill in ipairs(recorded) do retained[skill] = true end
        -- Retain exact instances (and their usage/state); retire only departed grants.
        for _, old in ipairs(state(player,ctx:getActivationRef(),"acquired"):toString():split(",")) do
            local skill, id = old:match("^(.-)#(%d+)$")
            if skill and not retained[skill] then
                room:detachAttachedSkill(sgs.SkillInstanceRef(player:objectName(), sgs.SkillInstanceKey(skill, tonumber(id))))
            end
        end
        for _, name in ipairs(recorded) do
            local ref = room:attachSkillToPlayer(player, name, parent)
            if ref:isValid() then
                table.insert(acquired, ref.key:toString())
                -- Helpers share this grant's lifetime; neither root removal nor eviction leaks them.
                for _, helper in sgs.qlist(sgs.Sanguosha:getRelatedSkills(name)) do
                    room:attachSkillToPlayer(player, helper:objectName(), ref, helper:isVisible())
                end
                if not state(player, ref, "huaming_initialized"):toBool() then
                    local definition = sgs.Sanguosha:getSkill(name)
                    if definition:getLimitMark() ~= "" then room:setPlayerMark(player, definition:getLimitMark(), 1) end
                    setstate(player, ref, "huaming_initialized", true)
                    log(room, "#c_huaming_acquire", player, nil, name)
                end
            end
        end
        setstate(player,ctx:getActivationRef(),"skills",table.concat(recorded,","))
        setstate(player,ctx:getActivationRef(),"acquired",table.concat(acquired,","));return false
    end
}

-- 辅助函数：应用化名技能


-- 注册化名技能
C_zuoci:addSkill(c_huaming)

--刘三刀

C_liusandao = sgs.General(extension, "C_liusandao", "qun", 3)

sgs.LoadTranslationTable{
    ["C_liusandao"] = "人间-刘三刀",
    ["&C_liusandao"] = "刘三刀",
    ["#C_liusandao"] = "三刀客",
    ["c_sandao"] = "三刀",
    [":c_sandao"] = "出牌阶段开始时,你可以视为对一名其他角色使用3张【杀】,每命中一张则你摸1张牌,否则你失去1点体力。",
    ["@c_sandao"] = "请选择【三刀】的目标",
    ["#c_sandao_hit"] = "%from 的【三刀】命中，摸一张牌",
    ["#c_sandao_miss"] = "%from 的【三刀】被闪避，失去一点体力"
}

c_sandao = sgs.CreateTriggerSkillV2{
    name="c_sandao",events={sgs.EventPhaseStart,sgs.DamageDone,sgs.CardFinished},
    can_trigger=function(self,event,room,player,data)
        if event==sgs.EventPhaseStart then
            if player and player:getPhase()==sgs.Player_Play then return own(self,event,room,player,data) end
        elseif event==sgs.DamageDone then
            local damage=data:toDamage()
            if damage.card and damage.card:getSkillName()==self:objectName() then
                local id=damage.card:getSkillInstanceId()
                if damage.from and id>0 and damage.from:hasSkillInstance(self:objectName(),id) then return self:objectName().."#"..id,damage.from end
            end
        else
            local use=data:toCardUse()
            if use.card and use.card:getSkillName()==self:objectName() and not use.card:hasFlag("c_sandao_hit") then
                local id=use.card:getSkillInstanceId()
                if use.from and id>0 and use.from:hasSkillInstance(self:objectName(),id) then return self:objectName().."#"..id,use.from end
            end
        end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        if event~=sgs.EventPhaseStart then return true end
        if not room:askForSkillInvoke(player,self:objectName()) then return false end
        local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@c_sandao",true)
        if not target then return false end
        ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        if event==sgs.EventPhaseStart then
            for i=1,3 do
                local card=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0);card:setSkillName(self:objectName());card:setSkillInstanceId(ctx.instanceID)
                room:useCard(sgs.CardUseStruct(card,player,ctx.targets:first()))
            end
        elseif event==sgs.DamageDone then
            log(room,"#c_sandao_hit",player);player:drawCards(self:getEffectiveAmount(ctx))
            room:setCardFlag(ctx.original_data:toDamage().card,"c_sandao_hit")
        else log(room,"#c_sandao_miss",player);room:loseHp(player,1,true,player,self:objectName()) end
        return false
    end
}

C_liusandao:addSkill(c_sandao)

--司马师

C_simaishi = sgs.General(extension, "C_simaishi", "wei", 3)
C_simaishi:setImage("simashi")
sgs.LoadTranslationTable{
    ["C_simaishi"] = "人间-司马师",
    ["&C_simaishi"] = "司马师",
    ["#C_simaishi"] = "冷血谋主",
    ["c_yinyang"] = "阴养",
    [":c_yinyang"] = "锁定技，你标记所有经过你手牌区的牌，回合结束后，你弃置所有手牌并从弃牌堆中抽取未标记过的牌直至手牌上限。",
    ["#c_yinyang_mark"] = "%from 的【阴养】效果标记了牌 %card",
    ["#c_yinyang_discard"] = "%from 的【阴养】效果弃置了所有手牌",
    ["#c_yinyang_draw"] = "%from 的【阴养】效果从弃牌堆获得了 %arg 张未标记过的牌",
    ["c_zhaoji"] = "朝集",
    [":c_zhaoji"] = "限定技，出牌阶段开始时或当你进入濒死状态时，你可以获得所有你标记过的牌。",
    ["#c_zhaoji"] = "%from 发动了【朝集】，获得了所有标记过的牌"
}

c_yinyang = sgs.CreateTriggerSkillV2{
    name="c_yinyang",frequency=sgs.Skill_Compulsory,events={sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
    on_record=function(self,event,room,player,ctx)
        if event~=sgs.CardsMoveOneTime or not ctx:getActivationRef():isValid() then return end
        player=ctx.owner
        local data=ctx.original_data
            local move = data:toMoveOneTime()
            -- 检查牌是否进入了玩家的手牌区
            if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
                -- 获取已标记的牌ID列表，使用哈希表来提高查找效率
                local marked_ids_set = {}
                local marked_ids_list = {}
                local marked_str = state(player,ctx:getActivationRef(),"marked"):toString()

                if marked_str ~= "" then
                    for _, id_str in ipairs(marked_str:split(",")) do
                        local id = tonumber(id_str)
                        marked_ids_set[id] = true
                        table.insert(marked_ids_list, id)
                    end
                end

                -- 标记新的牌
                local has_new_cards = false
                for _, card_id in sgs.qlist(move.card_ids) do
                    -- 使用哈希表快速检查是否已经记录过这个ID
                    if not marked_ids_set[card_id] then
                        marked_ids_set[card_id] = true
                        table.insert(marked_ids_list, card_id)
                        has_new_cards = true

                        -- 记录日志
                        local msg = sgs.LogMessage()
                        msg.type = "#c_yinyang_mark"
                        msg.from = player
                        msg.card_str = sgs.Sanguosha:getCard(card_id):toString()
                        room:sendLog(msg)
                    end
                end

                -- 只有当有新牌被标记时才更新标记列表
                if has_new_cards then
                    local new_marked_str = table.concat(marked_ids_list, ",")
                    setstate(player,ctx:getActivationRef(),"marked",new_marked_str)
                end
            end

    end,
    can_trigger=function(self,event,room,player,data)
        if event==sgs.EventPhaseEnd and player and player:getPhase()==sgs.Player_Finish and not player:isKongcheng() then return own(self,event,room,player,data) end
        return ""
    end,
    on_effect=function(self,event,room,player,ctx)
            -- 回合结束时，弃置所有手牌
            if not player:isKongcheng() then
                -- 记录日志
                local msg = sgs.LogMessage()
                msg.type = "#c_yinyang_discard"
                msg.from = player
                room:sendLog(msg)

                -- 弃置所有手牌
                local handcards = player:getHandcards()
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                for _, card in sgs.qlist(handcards) do
                    dummy:addSubcard(card:getId())
                end
                room:throwCard(dummy, player, player)

                -- 获取已标记的牌ID列表，直接使用哈希表结构
                local marked_ids = {}
                local marked_str = state(player,ctx:getActivationRef(),"marked"):toString()
                if marked_str ~= "" then
                    for _, id_str in ipairs(marked_str:split(",")) do
                        marked_ids[tonumber(id_str)] = true
                    end
                end

                -- 从弃牌堆中获取未标记的牌
                local discard_pile = room:getDiscardPile()
                local available_cards = {}
                local count = 0
                local max_cards = player:getMaxCards()

                -- 只收集需要的数量的牌
                for _, id in sgs.qlist(discard_pile) do
                    if not marked_ids[id] then
                        table.insert(available_cards, id)
                        count = count + 1
                        if count >= max_cards then
                            break
                        end
                    end
                end

                -- 如果有可用的牌
                local n = #available_cards
                if n > 0 then
                    -- 记录日志
                    local msg = sgs.LogMessage()
                    msg.type = "#c_yinyang_draw"
                    msg.from = player
                    msg.arg = n
                    room:sendLog(msg)

                    -- 直接使用available_cards，避免额外的复制
                    local move = sgs.CardsMoveStruct()
                    move.card_ids = sgs.IntList()
                    for _, id in ipairs(available_cards) do
                        move.card_ids:append(id)
                    end
                    move.to = player
                    move.to_place = sgs.Player_PlaceHand
                    room:moveCardsAtomic(move, true)
                end
            end
        return false
    end
}

C_simaishi:addSkill(c_yinyang)

-- 添加朝集技能
c_zhaoji = sgs.CreateTriggerSkillV2{
    name="c_zhaoji",frequency=sgs.Skill_Limited,limit_scope=sgs.Skill_Limit_Game,max_usage_limit=1,
    events={sgs.EventPhaseStart,sgs.Dying},
    can_trigger=function(self,event,room,player,data)
        if (event==sgs.EventPhaseStart and player and player:getPhase()==sgs.Player_Play)
            or (event==sgs.Dying and data:toDying().who==player) then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local marked={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds("c_yinyang")) do
            for _,card in ipairs(player:getSkillInstanceStateValue("c_yinyang",id,"marked"):toString():split(",")) do
                if tonumber(card) then marked[tonumber(card)]=true end
            end
        end
        log(room,"#c_zhaoji",player)
        for id in pairs(marked) do
            local place=room:getCardPlace(id)
            if place~=sgs.Player_PlaceTable and place~=sgs.Player_PlaceUnknown then
                local owner=room:getCardOwner(id)
                if not owner or player:canGet(owner,id) then
                    local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,player:objectName(),owner and owner:objectName() or "","c_zhaoji","")
                    room:obtainCard(player,sgs.Sanguosha:getCard(id),reason,place~=sgs.Player_PlaceHand)
                end
            end
        end
        return false
    end
}

C_simaishi:addSkill(c_zhaoji)

--陈宫
sgs.LoadTranslationTable{
    ["C_chengong"] = "人间-陈宫",
    ["&C_chengong"] = "陈宫",
    ["#C_chengong"] = "智计百出",
    ["c_fengjun"] = "奉君",
    ["c_fengjun_"] = "奉君",
    ["c_fengjun_target"] = "奉君",
    [":c_fengjun"] = "结束阶段，你可以选择一名其他角色，该角色的下一个出牌阶段可以使用你的手牌，若直到其出牌阶段结束时，其没有使用，则其失去1点体力。",
    ["c_choucuo"] = "筹错",
    [":c_choucuo"] = "当你于回合外失去手牌后，你可以令1名其他角色本回合非锁定技能无效。",
    ["@c_fengjun"] = "请选择【奉君】的目标角色",
    ["@c_choucuo"] = "请选择【筹错】的目标角色",
    ["#c_fengjun_give"] = "%from 的【奉君】效果让 %to 可以使用其手牌",
    ["#c_fengjun_unused"] = "%from 的【奉君】效果未被使用，%to 失去1点体力",
    ["#c_choucuo_disable"] = "%from 的【筹错】效果让 %to 的非锁定技能无效",
    ["c_fengjun_use"] = "奉君",
    ["c_fengjun_real"] = "奉君",
    ["@c_fengjun-use"] = "请选择一张陈宫的手牌来使用",
    ["@c_fengjun-use:%arg"] = "请选择一张%arg的手牌来使用"
}

C_chengong = sgs.General(extension, "C_chengong", "qun", 3)
C_chengong:setImage("chengong")
-- 奉君技能
c_fengjun = sgs.CreateTriggerSkillV2{
    name="c_fengjun",events={sgs.EventPhaseEnd,sgs.EventPhaseStart},
    can_trigger=function(self,event,room,player,data)
        if not player or not player:isAlive() then return "" end
        if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then return own(self,event,room,player,data) end
        if player:getPhase()~=sgs.Player_Play then return "" end
        local names,holders={},{}
        for _,owner in sgs.qlist(room:getAlivePlayers()) do
            for _,id in sgs.qlist(owner:getValidSkillInstanceIds(self:objectName())) do
                if owner:getSkillInstanceStateValue(self:objectName(),id,"target"):toString()==player:objectName() then
                    table.insert(names,self:objectName().."#"..id);table.insert(holders,owner:objectName())
                end
            end
        end
        return table.concat(names,"|"),table.concat(holders,"|")
    end,
    on_cost=function(self,event,room,player,ctx)
        if ctx.invoker:getPhase()~=sgs.Player_Finish then return true end
        if not room:askForSkillInvoke(player,self:objectName()) then return false end
        local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@c_fengjun")
        if not target then return false end;ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local ref=ctx:getActivationRef()
        if ctx.invoker:getPhase()==sgs.Player_Finish then
            local target=ctx.targets:first();setstate(player,ref,"target",target:objectName());setstate(player,ref,"used",false)
            room:setPlayerMark(target,"&c_fengjun_target",1);log(room,"#c_fengjun_give",player,target)
        elseif event==sgs.EventPhaseStart then
            if not player:isKongcheng() then
                local use=room:attachSkillToPlayer(ctx.invoker,"c_fengjun_use",ref)
                local real=room:attachSkillToPlayer(ctx.invoker,"c_fengjun_real",ref,false)
                setstate(player,ref,"use_id",use.key.instanceID);setstate(player,ref,"real_id",real.key.instanceID)
            end
        else
            local target=ctx.invoker
            if not state(player,ref,"used"):toBool() then log(room,"#c_fengjun_unused",player,target);room:loseHp(target,1,true,player,self:objectName()) end
            for _,entry in ipairs({{"c_fengjun_use","use_id"},{"c_fengjun_real","real_id"}}) do
                local id=state(player,ref,entry[2]):toInt()
                if id>0 then room:detachAttachedSkill(sgs.SkillInstanceRef(target:objectName(),sgs.SkillInstanceKey(entry[1],id))) end
                setstate(player,ref,entry[2],0)
            end
            setstate(player,ref,"target","");setstate(player,ref,"used",false)
            room:setPlayerMark(target,"&c_fengjun_target",0)
        end
        return false
    end
}



-- 奉君使用SkillCard（点击按钮时执行的核心逻辑）
-- Request preview stays private to the receiver. The physical cards keep their provider owner.
local function fengjunProvider(request)
    local receiver=request:getInitiator()
    local parent=receiver:getSkillInstanceParentRef(request:getActivationSkillName(),request:getActivationInstanceId())
    if not parent:isValid() then return nil,parent end
    for _,player in sgs.qlist(receiver:getSiblings(true)) do
        if player:objectName()==parent.ownerObjectName then return player,parent end
    end
    return nil,parent
end


-- 奉君使用按钮（在出牌阶段显示的技能按钮）
c_fengjun_useVS = sgs.CreateViewAsSkillV2{
    name="c_fengjun_use",target_mode=sgs.ViewAsSkillV2_NoTarget,
    can_activate=function(self,request)
        local source=fengjunProvider(request)
        return play(request) and source and source:isAlive() and not source:isKongcheng()
    end,
    on_effect=function(self,ctx)
        local receiver=ctx.invoker;local room=receiver:getRoom();local parent=ctx:getSourceRef()
        local source=room:findPlayerByObjectName(parent.ownerObjectName)
        if not source or not source:isAlive() or source:isKongcheng() then return end
        local ids=sgs.IntList();for _,card in sgs.qlist(source:getHandcards()) do ids:append(card:getId()) end
        room:notifyMoveToPile(receiver,ids,"handcards",sgs.Player_PlaceHand,true,true)
        local aidata=sgs.QVariant();aidata:setValue(ids);receiver:setTag("c_fengjun_ai_cards",aidata)
        -- Nested named response is restricted to this exact grant, even with several providers.
        local realId=state(source,parent,"real_id"):toInt()
        if realId<=0 or not receiver:hasSkillInstance("c_fengjun_real",realId) then
            receiver:removeTag("c_fengjun_ai_cards")
            room:notifyMoveToPile(receiver,ids,"handcards",sgs.Player_PlaceUnknown,false,true)
            return
        end
        local offered={};for _,id in sgs.qlist(ids) do table.insert(offered,tostring(id)) end
        receiver:setSkillInstanceStateValue("c_fengjun_real",realId,"offered",sgs.QVariant(table.concat(offered,",")))
        receiver:setSkillInstanceStateValue("c_fengjun_real",realId,"requesting",sgs.QVariant(true))
        local used=room:askForUseCard(receiver,"@@c_fengjun_real","@c_fengjun-use:"..source:objectName())
        receiver:removeTag("c_fengjun_ai_cards")
        receiver:setSkillInstanceStateValue("c_fengjun_real",realId,"requesting",sgs.QVariant(false))
        receiver:setSkillInstanceStateValue("c_fengjun_real",realId,"offered",sgs.QVariant(""))
        room:notifyMoveToPile(receiver,ids,"handcards",sgs.Player_PlaceUnknown,false,true)
        if used then setstate(source,parent,"used",true) end
    end
}

-- 奉君使用技能（包装按钮ViewAsSkill的容器）
c_fengjun_use = sgs.CreateTriggerSkillV2{name="c_fengjun_use",view_as_skill=c_fengjun_useVS}


-- 实际选择陈宫手牌的ViewAs（响应"@@c_fengjun_real"模式的选择界面）
c_fengjun_realVS = sgs.CreateViewAsSkillV2{
    name="c_fengjun_real",n=1,expand_pile="#handcards",
    can_activate=function(self,request)
        local source,parent=fengjunProvider(request)
        return request:getPattern()=="@@c_fengjun_real" and source and source:isAlive()
            and state(request:getInitiator(),requestRef(request),"requesting"):toBool()
    end,
    can_select_card=function(self,request,card)
        local source=fengjunProvider(request)
        if not source or not request:getSelectedCardIds():isEmpty() or not card:isAvailable(request:getInitiator()) then return false end
        return table.contains(state(request:getInitiator(),requestRef(request),"offered"):toString():split(","),tostring(card:getId()))
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==1 end,
    cost=function(self,room,ctx,request)
        local source=room:findPlayerByObjectName(ctx:getSourceRef().ownerObjectName)
        local id=request:getSelectedCardIds():first()
        return source and source:isAlive() and room:getCardOwner(id)==source and room:getCardPlace(id)==sgs.Player_PlaceHand
    end,
    create_card=function(self,request)
        if request:getSelectedCardIds():length()~=1 then return nil end
        local original=sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
        if not original:isAvailable(request:getInitiator()) then return nil end
        local card=sgs.Sanguosha:cloneCard(original:objectName(),original:getSuit(),original:getNumber())
        card:addSubcard(original:getId());card:setSkillName("c_fengjun");return card
    end
}

-- 实际选择陈宫手牌的技能（包装ViewAsSkill的容器）
c_fengjun_real = sgs.CreateTriggerSkillV2{name="c_fengjun_real",view_as_skill=c_fengjun_realVS}



-- 筹错技能
c_choucuo = sgs.CreateTriggerSkillV2{
    name="c_choucuo",events={sgs.CardsMoveOneTime},
    can_trigger=function(self,event,room,player,data)
        local move=data:toMoveOneTime();local current=room:getCurrent()
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) and current and current:objectName()~=move.from:objectName() then
            return own(self,event,room,room:findPlayerByObjectName(move.from:objectName()),data)
        end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local candidates=sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do if p:getMark("@skill_invalidity-Clear")==0 then candidates:append(p) end end
        if candidates:isEmpty() or not room:askForSkillInvoke(player,self:objectName()) then return false end
        local target=room:askForPlayerChosen(player,candidates,self:objectName(),"@c_choucuo")
        if not target then return false end;ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first();log(room,"#c_choucuo_disable",player,target)
        room:setPlayerMark(target,"@skill_invalidity-Clear",1);return false
    end
}


C_chengong:addSkill(c_fengjun)
addToSkills(c_fengjun_use)
addToSkills(c_fengjun_real)
C_chengong:addSkill(c_choucuo)






--张辽
C_zhangliao = sgs.General(extension, "C_zhangliao", "wei", 4)
C_zhangliao:setImage("zhangliao")

sgs.LoadTranslationTable{
    ["C_zhangliao"] = "人间-张辽",
    ["&C_zhangliao"] = "张辽",
    ["#C_zhangliao"] = "前将军",
    ["c_yongxi"] = "勇袭",
    [":c_yongxi"] = "你可以跳过摸牌阶段，并令一名角色重铸至少2张牌。",
    ["@c_yongxi"] = "请选择【勇袭】的目标角色",
    ["@c_yongxi-recast"] = "请选择至少2张牌进行重铸",
    ["#c_yongxi_target"] = "%from 发动了【勇袭】，令 %to 重铸至少2张牌",
    ["c_weiqing"] = "威倾",
    [":c_weiqing"] = "每回合限一次，当其他角色于摸牌阶段外获得牌时，你可选择其等量的牌获得之。"
}

c_yongxi = sgs.CreateTriggerSkillV2{
    name="c_yongxi",events={sgs.EventPhaseChanging},
    can_trigger=function(self,event,room,player,data)
        if player and data:toPhaseChange().to==sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        if not room:askForSkillInvoke(player,self:objectName()) then return false end
        local target=room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"@c_yongxi")
        if not target then return false end;ctx.targets:append(target);return true
    end,
    on_pay=function(self,event,room,player,ctx) player:skip(sgs.Player_Draw,true);return true end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first();local actor=sgs.QVariant();actor:setValue(player)
        target:setTag("c_yongxi_source",actor);log(room,"#c_yongxi_target",player,target)
        local ids=sgs.IntList();for _,card in sgs.qlist(target:getCards("he")) do ids:append(card:getId()) end
        if ids:length()>=2 then
            local selected=room:askForExchange(target,self:objectName(),math.min(ids:length(),999),2,true,"@c_yongxi-recast",false,".")
            if selected and selected:subcardsLength()>=2 then room:recastCards(target,selected:getSubcards(),self:objectName()) end
        elseif not ids:isEmpty() then room:recastCards(target,ids,self:objectName()) end
        target:removeTag("c_yongxi_source");return false
    end
}

c_weiqing = sgs.CreateTriggerSkillV2{
    name="c_weiqing",events={sgs.CardsMoveOneTime},limit_scope=sgs.Skill_Limit_Turn,max_usage_limit=1,
    can_trigger=function(self,event,room,player,data)
        local move=data:toMoveOneTime()
        if not move.to or move.to_place~=sgs.Player_PlaceHand or move.card_ids:isEmpty() or room:getTag("FirstRound"):toBool() then return "" end
        local target=room:findPlayerByObjectName(move.to:objectName())
        if not target or not target:isAlive() or target:getPhase()==sgs.Player_Draw then return "" end
        local names,holders={},{}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p~=target and p:hasSkill(self:objectName()) then table.insert(names,self:objectName());table.insert(holders,p:objectName()) end
        end
        return table.concat(names,"|"),table.concat(holders,"|")
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local move=ctx.original_data:toMoveOneTime();local target=room:findPlayerByObjectName(move.to:objectName())
        if not target or not player:canGet(target,"he") then return false end
        local dummy=sgs.DummyCard()
        for i=1,move.card_ids:length() do
            if target:getCardCount()<i or not player:canGet(target,"he") then break end
            local id=room:askForCardChosen(player,target,"he",self:objectName(),false,sgs.Card_MethodGet,dummy:getSubcards())
            if id<0 or not player:canGet(target,id) then break end;dummy:addSubcard(id)
        end
        if dummy:subcardsLength()>0 then room:obtainCard(player,dummy,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,player:objectName(),target:objectName(),self:objectName(),""),false) end
        dummy:deleteLater();return false
    end
}

C_zhangliao:addSkill(c_yongxi)
C_zhangliao:addSkill(c_weiqing)

-- 黄盖
-- 苦肉：蓄力技(1/4)，出牌阶段，你可以消耗一蓄力点并依次执行以下两项，若两项你选择的角色相同，则你可选择一项额外执行一次
-- 1.令一名角色摸2张牌  2.令一名角色失去一点体力并获得1蓄力点

-- 苦肉 uses the default ActiveSkillCard and resolves its dependent choices in order.

c_kurouVS = sgs.CreateViewAsSkillV2{
    name="c_kurou",target_mode=sgs.ViewAsSkillV2_NoTarget,
    can_activate=function(self,request) return play(request) and request:getInitiator():getMark("&charge_num")>0 end,
    pay=function(self,room,ctx,request)
        if ctx.invoker:getMark("&charge_num")<1 then return false end
        ctx.invoker:loseMark("&charge_num",1);return true
    end,
    on_effect=function(self,ctx)
        local source=ctx.invoker;local room=source:getRoom()
        -- 第一项：选择一名角色摸2张牌
        local all_players = room:getAlivePlayers()
        source:setTag("c_kurou_stage", sgs.QVariant("draw"))  -- 设置选人阶段标记
        local target1 = room:askForPlayerChosen(source, all_players, "c_kurou", "@c_kurou_draw")
        source:removeTag("c_kurou_stage")  -- 清除标记

        if target1 then
            -- 显示从黄盖到目标的指示动画
            room:showIndicator(source:objectName(), target1:objectName())
            -- 记录第一项效果
            local msg = sgs.LogMessage()
            msg.type = "#c_kurou_draw"
            msg.from = source
            msg.to = sgs.SPlayerList()
            msg.to:append(target1)
            room:sendLog(msg)

            target1:drawCards(2 * self:getEffectiveAmount(ctx))

            -- 第二项：选择一名角色失去体力并获得蓄力点
            source:setTag("c_kurou_stage", sgs.QVariant("damage"))  -- 设置选人阶段标记
            local target2 = room:askForPlayerChosen(source, all_players, "c_kurou", "@c_kurou_damage")
            source:removeTag("c_kurou_stage")  -- 清除标记

            if target2 then
                -- 显示从黄盖到目标的指示动画
                room:showIndicator(source:objectName(), target2:objectName())
                -- 记录第二项效果
                local msg2 = sgs.LogMessage()
                msg2.type = "#c_kurou_damage"
                msg2.from = source
                msg2.to = sgs.SPlayerList()
                msg2.to:append(target2)
                room:sendLog(msg2)

                -- 失去体力
                room:loseHp(target2, 1, true, source, "c_kurou")

                -- 黄盖获得蓄力点（但不超过上限）
                if target2:getMark("&charge_num") < xuLiMax(target2) then
                    target2:gainMark("&charge_num")
                end

                -- 如果两个目标相同，可以额外执行一次
                if target1:objectName() == target2:objectName() then
                    local choices = {"c_kurou_extra_draw", "c_kurou_extra_damage"}
                    local choice = room:askForChoice(source, "c_kurou", table.concat(choices, "+"), sgs.QVariant())

                    if choice == "c_kurou_extra_draw" then
                        -- 额外摸牌：重新选择一名角色
                        source:setTag("c_kurou_stage", sgs.QVariant("extra_draw"))  -- 设置选人阶段标记
                        local target3 = room:askForPlayerChosen(source, all_players, "c_kurou", "@c_kurou_extra_draw")
                        source:removeTag("c_kurou_stage")  -- 清除标记
                        if target3 then
                            -- 显示从黄盖到目标的指示动画
                            room:showIndicator(source:objectName(), target3:objectName())
                            local msg3 = sgs.LogMessage()
                            msg3.type = "#c_kurou_extra_draw"
                            msg3.from = source
                            msg3.to = sgs.SPlayerList()
                            msg3.to:append(target3)
                            room:sendLog(msg3)

                            target3:drawCards(2 * self:getEffectiveAmount(ctx))
                        end
                    elseif choice == "c_kurou_extra_damage" then
                        -- 额外失去体力：重新选择一名角色
                        source:setTag("c_kurou_stage", sgs.QVariant("extra_damage"))  -- 设置选人阶段标记
                        local target3 = room:askForPlayerChosen(source, all_players, "c_kurou", "@c_kurou_extra_damage")
                        source:removeTag("c_kurou_stage")  -- 清除标记
                        if target3 then
                            -- 显示从黄盖到目标的指示动画
                            room:showIndicator(source:objectName(), target3:objectName())
                            local msg3 = sgs.LogMessage()
                            msg3.type = "#c_kurou_extra_damage"
                            msg3.from = source
                            msg3.to = sgs.SPlayerList()
                            msg3.to:append(target3)
                            room:sendLog(msg3)

                            room:loseHp(target3, 1, true, source, "c_kurou")
                            if target3:getMark("&charge_num") < xuLiMax(target3) then
                                target3:gainMark("&charge_num")
                            end
                        end
                    end
                end
            end
        end

    end
}

c_kurou = sgs.CreateTriggerSkillV2{name="c_kurou",view_as_skill=c_kurouVS}
-- 设置蓄力技属性：苦肉(1/4)
c_kurou:setProperty("ChargeNum", ToData("1/4"))

-- 世臣：当有角色死亡后，你可选择回复一点体力或增加1蓄力点
c_shichen = sgs.CreateTriggerSkillV2{
    name="c_shichen",events={sgs.Death},
    can_trigger=function(self,event,room,player,data) return owners(self,room) end,
    on_cost=function(self,event,room,player,ctx)
        local choices={}
        if player:isWounded() then table.insert(choices,"c_shichen_recover") end
        if player:getMark("&charge_num")<xuLiMax(player) then table.insert(choices,"c_shichen_charge") end
        if #choices==0 or not room:askForSkillInvoke(player,self:objectName()) then return false end
        ctx.choice=#choices==1 and choices[1] or room:askForChoice(player,self:objectName(),table.concat(choices,"+"),sgs.QVariant())
        return true
    end,
    on_effect=function(self,event,room,player,ctx)
        log(room,"#"..ctx.choice,player)
        if ctx.choice=="c_shichen_recover" then room:recover(player,sgs.RecoverStruct(player,nil,1))
        else player:gainMark("&charge_num") end
        return false
    end
}

C_huanggai = sgs.General(extension, "C_huanggai", "wu", 4)
C_huanggai:setImage("huanggai")

sgs.LoadTranslationTable{
    ["C_huanggai"] = "人间-黄盖",
    ["&C_huanggai"] = "黄盖",
    ["#C_huanggai"] = "轻身为国",
    ["c_kurou"] = "苦肉",
    [":c_kurou"] = "蓄力技(1/4)，出牌阶段，你可以消耗一蓄力点并依次执行以下两项，若两项你选择的角色相同，则你可选择一项额外执行一次：1.令一名角色摸2张牌；2.令一名角色失去一点体力并获得1蓄力点。",
    ["@c_kurou_draw"] = "苦肉：请选择摸2张牌的角色",
    ["@c_kurou_damage"] = "苦肉：请选择失去体力的角色",
    ["@c_kurou_extra_draw"] = "苦肉：请选择额外摸2张牌的角色",
    ["@c_kurou_extra_damage"] = "苦肉：请选择额外失去体力的角色",
    ["#c_kurou_draw"] = "%from 发动了【苦肉】，令 %to 摸2张牌",
    ["#c_kurou_damage"] = "%from 发动了【苦肉】，令 %to 失去1点体力",
    ["#c_kurou_extra_draw"] = "%from 发动了【苦肉】额外效果，令 %to 摸2张牌",
    ["#c_kurou_extra_damage"] = "%from 发动了【苦肉】额外效果，令 %to 失去1点体力",
    ["c_kurou_extra_draw"] = "额外执行：令一名角色摸2张牌",
    ["c_kurou_extra_damage"] = "额外执行：令一名角色失去1点体力",
    -- 世臣技能翻译
    ["c_shichen"] = "世臣",
    [":c_shichen"] = "当有角色死亡后，你可选择回复一点体力或增加1蓄力点。",
    ["c_shichen_recover"] = "回复1点体力",
    ["c_shichen_charge"] = "增加1蓄力点",
    ["#c_shichen_recover"] = "%from 发动了【世臣】，回复了1点体力",
    ["#c_shichen_charge"] = "%from 发动了【世臣】，获得了1蓄力点",
    ["charge_num"] = "蓄力"
}

C_huanggai:addSkill(c_kurou)
C_huanggai:addSkill(c_shichen)

-- 庞德
C_pangde = sgs.General(extension, "C_pangde", "qun", 4)
C_pangde:setImage("pangde")

sgs.LoadTranslationTable{
    ["C_pangde"] = "人间-庞德",
    ["&C_pangde"] = "庞德",
    ["#C_pangde"] = "抬榇之悟",
    ["c_qiaochu"] = "鞘出",
    [":c_qiaochu"] = "当你使用【杀】指定一名角色为目标后，你可以弃置其一张牌，若此牌为【杀】，你视为对其使用此【杀】。",
    ["@c_qiaochu"] = "鞘出：你可以弃置 %src 的一张牌",
    ["#c_qiaochu_slash"] = "%from 的【鞘出】效果弃置了 %to 的【杀】，视为对其使用此【杀】"
}

-- 鞘出技能
c_qiaochu = sgs.CreateTriggerSkillV2{
    name="c_qiaochu",events={sgs.TargetSpecified},
    can_trigger=function(self,event,room,player,data)
        local use=data:toCardUse()
        if player and player:isAlive() and player:hasSkill(self:objectName()) and use.card and use.card:isKindOf("Slash") and not use.to:isEmpty() then
            local names={}
            for _,p in sgs.qlist(use.to) do
                if p:isAlive() and not p:isNude() then table.insert(names,p:objectName()) end
            end
            if #names>0 then return self:objectName().."->"..table.concat(names,"+"),player end
        end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local target=ctx.preferredTarget
        if not target or target:isNude() then return false end
        local data=sgs.QVariant();data:setValue(target)
        if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
        ctx.extra_data=sgs.QVariant(room:askForCardChosen(player,target,"he",self:objectName()))
        return ctx.extra_data:toInt()>=0
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first();local id=ctx.extra_data:toInt();local card=sgs.Sanguosha:getCard(id)
        room:throwCard(id,target,player)
        if card:isKindOf("Slash") then
            log(room,"#c_qiaochu_slash",player,target)
            if player:isAlive() and target:isAlive() then
                local slash=sgs.Sanguosha:getWrappedCard(id);slash:setSkillName(self:objectName())
                room:useCard(sgs.CardUseStruct(slash,player,target),true)
            end
        end
        return false
    end
}

C_pangde:addSkill("mashu")  -- 直接引用马术技能
C_pangde:addSkill(c_qiaochu)

-- 神吕布
sgs.LoadTranslationTable {
    ["C_god_lvbu"] = "人间-神吕布",
    ["&C_god_lvbu"] = "神吕布",
    ["#C_god_lvbu"] = "武神",

    ["c_wuqiong"] = "武穷",
    [":c_wuqiong"] = "使命技，当你受到伤害后，你可以废除一个武器栏以外的装备栏，然后获得一个额外的武器栏并恢复一点体力。\n使命成功：回合开始时，若你的装备区只有武器栏，则你从牌堆里选择5张装备牌获得并获得技能【狂睨】。\n使命失败：你进入濒死状态时，你获得技能【崩坏】。",
    ["@c_wuqiong"] = "武穷：选择要废除的装备栏",
    ["#c_wuqiong_abolish"] = "%from 发动了【武穷】，废除了 %arg 并获得一个武器栏，恢复1点体力",
    ["#c_wuqiong_success"] = "%from 的【武穷】使命成功！",
    ["#c_wuqiong_fail"] = "%from 的【武穷】使命失败",
    ["armor_area"] = "防具栏",
    ["horse_area"] = "+1马栏",
    ["horse2_area"] = "-1马栏",
    ["treasure_area"] = "宝物栏",
}

-- 创建神吕布武将
C_god_lvbu = sgs.General(extension, "C_god_lvbu", "god", 5)
C_god_lvbu:setImage("shenlvbu")

-- 武穷技能：使命技
c_wuqiong = sgs.CreateTriggerSkillV2{
    name="c_wuqiong",shiming_skill=true,waked_skills="",events={sgs.Damaged,sgs.EventPhaseStart,sgs.Dying},
    can_trigger=function(self,event,room,player,data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return "" end
        if event==sgs.EventPhaseStart then
            if player:getPhase()~=sgs.Player_Start then return "" end
            for i=1,4 do if player:hasEquipArea(i) then return "" end end
        elseif event==sgs.Dying and data:toDying().who~=player then return "" end
        local names={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds(self:objectName())) do
            local ref=sgs.SkillInstanceRef(player:objectName(),sgs.SkillInstanceKey(self:objectName(),id))
            if room:getShimingStatus(ref)==0 then table.insert(names,self:objectName().."#"..id) end
        end
        return table.concat(names,"+"),player
    end,
    on_cost=function(self,event,room,player,ctx)
        if event~=sgs.Damaged then return true end
        local choices={};local names={"armor_area","horse_area","horse2_area","treasure_area"}
        for i=1,4 do if player:hasEquipArea(i) then table.insert(choices,names[i]) end end
        if #choices==0 or not room:askForSkillInvoke(player,self:objectName()) then return false end
        ctx.choice=room:askForChoice(player,self:objectName(),table.concat(choices,"+"),sgs.QVariant(),nil,"@c_wuqiong")
        for i,name in ipairs(names) do if name==ctx.choice then ctx.extra_data=sgs.QVariant(i) end end
        return true
    end,
    on_pay=function(self,event,room,player,ctx)
        if event==sgs.Damaged then
            if not player:hasEquipArea(ctx.extra_data:toInt()) then return false end
            player:throwEquipArea(ctx.extra_data:toInt())
        end
        return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local ref=ctx:getActivationRef()
        if event==sgs.Damaged then
            player:addEquipArea(0);room:recover(player,sgs.RecoverStruct(player,nil,1));log(room,"#c_wuqiong_abolish",player,nil,ctx.choice)
        elseif event==sgs.EventPhaseStart then
            if not room:sendShimingLog(ref,true) then return false end
            local ids=sgs.IntList()
            for _,id in sgs.qlist(room:getDrawPile()) do if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then ids:append(id) end end
            if not ids:isEmpty() then
                player:removeTag("c_wuqiong_selected_crossbow");player:removeTag("c_wuqiong_selected_long_range")
                room:fillAG(ids);local dummy=sgs.DummyCard()
                for i=1,math.min(5,ids:length()) do
                    local id=room:askForAG(player,ids,false,self:objectName());if id<0 then break end
                    dummy:addSubcard(id);ids:removeOne(id);room:takeAG(player,id,false)
                end
                room:clearAG();if dummy:subcardsLength()>0 then room:obtainCard(player,dummy,"c_wuqiong") end;dummy:deleteLater()
            end
            room:acquireSkill(player,"c_kuangni")
        else
            if not room:sendShimingLog(ref,false) then return false end
            room:acquireSkill(player,"benghuai")
        end
        return false
    end
}

-- 狂睨技能
sgs.LoadTranslationTable {
    ["c_kuangni"] = "狂睨",
    [":c_kuangni"] = "你可以将当前无法使用的牌当【杀】使用。",
}

c_kuangniVS = sgs.CreateViewAsSkillV2{
    name="c_kuangni",n=1,
    can_activate=function(self,request) return play(request) and sgs.Slash_IsAvailable(request:getInitiator()) end,
    can_select_card=function(self,request,card) return request:getSelectedCardIds():isEmpty() and not card:isAvailable(request:getInitiator()) end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==1 end,
    create_card=function(self,request)
        if request:getSelectedCardIds():length()~=1 then return nil end
        local card=sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
        local slash=sgs.Sanguosha:cloneCard("slash",card:getSuit(),card:getNumber());slash:addSubcard(card:getId());slash:setSkillName(self:objectName());return slash
    end
}

c_kuangni = sgs.CreateTriggerSkillV2{name="c_kuangni",view_as_skill=c_kuangniVS}
addToSkills(c_kuangni)
C_god_lvbu:addSkill(c_wuqiong)
C_god_lvbu:addRelateSkill("c_kuangni")
C_god_lvbu:addRelateSkill("benghuai")
--C_god_lvbu:addSkill(c_kuangni)

-- 曹操
sgs.LoadTranslationTable {
    ["C_caocao"] = "人间-曹操",
    ["&C_caocao"] = "曹操",
    ["#C_caocao"] = "魏武帝",
    ["c_jianxiong"] = "奸雄",
    [":c_jianxiong"] = "当你受到伤害后，你可以获得伤害牌；当你造成伤害后，你可以失去一点体力并获得伤害牌。",
    ["@c_jianxiong_damaged"] = "奸雄：你可以获得伤害牌",
    ["@c_jianxiong_damage"] = "奸雄：你可以失去一点体力并获得伤害牌",
    ["#c_jianxiong_get"] = "%from 发动了【奸雄】，获得了伤害牌 %card",
    ["#c_jianxiong_losehp"] = "%from 发动了【奸雄】，失去1点体力并获得了伤害牌 %card"
}

C_caocao = sgs.General(extension, "C_caocao$", "wei", 4)
C_caocao:setImage("caocao")

-- 奸雄技能
-- 检查伤害牌是否可以获得（不是虚拟卡）
local function canObtainDamageCard(card, room)
    if not card then
        return false
    end

    -- 检查牌是否有子牌
    if card:subcardsLength() > 0 then
        -- 有子牌的牌可以获得
        return true
    else
        -- 没有子牌的牌，检查其位置
        local place = room:getCardPlace(card:getEffectiveId())
        -- 如果牌在延时锦囊、弃牌堆或处理区，可以获得
        if place == sgs.Player_PlaceDelayedTrick or
           place == sgs.Player_DiscardPile or
           place == sgs.Player_PlaceTable then
            return true
        end
    end

    return false
end

c_jianxiong = sgs.CreateTriggerSkillV2{
    name="c_jianxiong",events={sgs.Damaged,sgs.Damage},
    can_trigger=function(self,event,room,player,data)
        local damage=data:toDamage()
        if not canObtainDamageCard(damage.card,room) then return "" end
        local owner=event==sgs.Damaged and damage.to or damage.from
        return own(self,event,room,owner,data)
    end,
    on_cost=invoke,
    on_pay=function(self,event,room,player,ctx) if event==sgs.Damage then room:loseHp(player,1,true,player,self:objectName()) end;return true end,
    on_effect=function(self,event,room,player,ctx)
        local card=ctx.original_data:toDamage().card
        local msg=sgs.LogMessage();msg.type=event==sgs.Damaged and "#c_jianxiong_get" or "#c_jianxiong_losehp";msg.from=player;msg.card_str=card:toString();room:sendLog(msg)
        room:obtainCard(player,card,self:objectName());return false
    end
}

-- 清正技能
sgs.LoadTranslationTable {
    ["c_qingzheng"] = "清正",
    [":c_qingzheng"] = "当你失去一种花色的最后一张手牌后，你可以令一名其他角色将其该花色的所有手牌当【杀】对你使用。",
    ["@c_qingzheng"] = "清正：选择一名角色，令其将%src花色的所有手牌当【杀】对你使用",
    ["#c_qingzheng_slash"] = "%from 被【清正】效果影响，视为对 %to 使用【杀】"
}

c_qingzheng = sgs.CreateTriggerSkillV2{
    name="c_qingzheng",events={sgs.CardsMoveOneTime},
    can_trigger=function(self,event,room,player,data)
        local move=data:toMoveOneTime()
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) then return own(self,event,room,room:findPlayerByObjectName(move.from:objectName()),data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local suits={};local move=ctx.original_data:toMoveOneTime()
        for _,id in sgs.qlist(move.card_ids) do local suit=sgs.Sanguosha:getCard(id):getSuit();if suit~=sgs.Card_NoSuit then suits[suit]=true end end
        for _,card in sgs.qlist(player:getHandcards()) do suits[card:getSuit()]=nil end
        for suit in pairs(suits) do
            local others=room:getOtherPlayers(player);if others:isEmpty() then return false end
            local names={[sgs.Card_Spade]="spade",[sgs.Card_Heart]="heart",[sgs.Card_Club]="club",[sgs.Card_Diamond]="diamond"}
            local slash=sgs.Sanguosha:cloneCard("slash",suit,0)
            player:setTag("c_qingzheng_slash",sgs.QVariant(slash:toString()));player:setTag("c_qingzheng_suit",sgs.QVariant(suit));slash:deleteLater()
            local accepted=room:askForSkillInvoke(player,self:objectName())
            local target=nil
            if accepted then target=room:askForPlayerChosen(player,others,self:objectName(),"@c_qingzheng:"..names[suit]) end
            player:removeTag("c_qingzheng_slash");player:removeTag("c_qingzheng_suit");player:removeTag("c_qingzheng_chosen_target")
            if not target then return false end
            ctx.targets:append(target);ctx.extra_data=sgs.QVariant(suit);ctx.choice=names[suit];return true
        end
        return false
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first();local slash=sgs.Sanguosha:cloneCard("slash",ctx.extra_data:toInt(),0)
        for _,card in sgs.qlist(target:getHandcards()) do if card:getSuit()==ctx.extra_data:toInt() then slash:addSubcard(card:getId()) end end
        slash:setSkillName(self:objectName());log(room,"#c_qingzheng_slash",target,player,ctx.choice)
        room:useCard(sgs.CardUseStruct(slash,target,player));return false
    end
}

C_caocao:addSkill(c_jianxiong)
C_caocao:addSkill(c_qingzheng)

--刘备
sgs.LoadTranslationTable {
["C_liubei"]="人间-刘备",
["&C_liubei"]="刘备",
["#C_liubei"]="仁德之主",
["c_shien"]="施恩",
[":c_shien"]="使命技，出牌阶段，你可以将两张牌交给一名其他角色（每名角色每回合限一次），然后你摸两张牌。\n使命成功：当所有存活的其他角色都成为过你【施恩】的目标后，你获得技能【仁泽】。\n使命失败：若你给出的牌颜色不同，目标角色须选择交给你任意张牌，然后你视为对其使用X张【杀】（X为其手牌数）。",
["c_shienCard"]="施恩",
["@c_shien"]="你可以发动【施恩】，选择两张手牌交给一名其他角色",
["~c_shien"]="选择两张手牌→选择一名其他角色→确定",
["@c_shien-give"]="施恩：请选择交给 %src 的牌（可以不给）",
["@c_shien-slash"]="施恩：你需要对 %src 视为使用 %arg 张【杀】",
["c_renze"]="仁泽",
[":c_renze"]="锁定技，任意角色的回合开始时，你摸一张牌。",
["c_hanmai"]="汉脉",
[":c_hanmai"]="主公技，锁定技，当一名角色死亡后，若其武将牌上有主公技，你获得之。",
}

C_liubei = sgs.General(extension, "C_liubei$", "shu", 4)
C_liubei:setImage("liubei")

-- 施恩技能卡
-- 施恩 selected cards are given by V2 pay; effects use the exact source instance.

-- 施恩 ViewAs 技能
c_shienVS = sgs.CreateViewAsSkillV2{
    name="c_shien",n=2,target_mode=sgs.ViewAsSkillV2_SelectTargets,will_throw_selected_cards=false,
    can_activate=function(self,request)
        local player=request:getInitiator()
        return play(request) and player:getHandcardNum()>=2
            and player:getRoom():getShimingStatus(requestRef(request))==0
    end,
    can_select_card=function(self,request,card)
        return request:getSelectedCardIds():length()<2 and not card:isEquipped()
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==2 end,
    can_select_target=function(self,request,selected,candidate)
        local player=request:getInitiator()
        return #selected==0 and candidate~=player and not table.contains(state(player,requestRef(request),"used"):toString():split("+"),candidate:objectName())
    end,
    targets_feasible=function(self,request,selected) return #selected==1 end,
    pay=function(self,room,ctx,request)
        local source=ctx.invoker;local target=ctx.targets:first()
        if not target or request:getSelectedCardIds():length()~=2 then return false end
        local list=state(source,ctx:getActivationRef(),"used"):toString():split("+")
        if table.contains(list,target:objectName()) then return false end
        local dummy=sgs.DummyCard();local red,black=false,false
        for _,id in sgs.qlist(request:getSelectedCardIds()) do
            if room:getCardOwner(id)~=source or room:getCardPlace(id)~=sgs.Player_PlaceHand then dummy:deleteLater();return false end
            local card=sgs.Sanguosha:getCard(id);red=red or card:isRed();black=black or card:isBlack();dummy:addSubcard(id)
        end
        ctx.extra_data=sgs.QVariant(red and black)
        table.insert(list,target:objectName());setstate(source,ctx:getActivationRef(),"used",table.concat(list,"+"))
        local all=state(source,ctx:getActivationRef(),"all_targets"):toString():split("+")
        if not table.contains(all,target:objectName()) then table.insert(all,target:objectName());setstate(source,ctx:getActivationRef(),"all_targets",table.concat(all,"+")) end
        local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,source:objectName(),target:objectName(),"c_shien","")
        room:obtainCard(target,dummy,reason,false);dummy:deleteLater();return true
    end,
    on_effect=function(self,ctx)
        local source=ctx.invoker;local room=source:getRoom();local target=ctx.targets:first()
        local ref=ctx:getActivationRef()
        local all=state(source,ref,"all_targets"):toString():split("+")
        if source:isAlive() then source:drawCards(2 * self:getEffectiveAmount(ctx),"c_shien") end
        if ctx.extra_data:toBool() and source:isAlive() and target:isAlive() then
            if not room:sendShimingLog(ref,false) then return end
            if not target:isKongcheng() then
                local cards=room:askForExchange(target,"c_shien",target:getHandcardNum(),0,true,"@c_shien-give:"..source:objectName())
                if cards and cards:subcardsLength()>0 then room:obtainCard(source,cards,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,target:objectName(),source:objectName(),"c_shien",""),false) end
            end
            if source:isAlive() and target:isAlive() then
                local count=target:getHandcardNum()
                for i=1,count do
                    if source:isAlive() and target:isAlive() and source:canSlash(target,nil,false) then
                        local card=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0);card:setSkillName("c_shien")
                        room:useCard(sgs.CardUseStruct(card,source,target),false)
                    end
                end
            end
            return
        end
        if source:isAlive() and room:getShimingStatus(ref)==0 then
            for _,other in sgs.qlist(room:getOtherPlayers(source)) do if not table.contains(all,other:objectName()) then return end end
            if room:sendShimingLog(ref,true) then room:acquireSkill(source,"c_renze") end
        end
    end
}

-- 施恩触发技能（使命技主体）
c_shien = sgs.CreateTriggerSkillV2{
    name="c_shien",shiming_skill=true,view_as_skill=c_shienVS,events={sgs.EventPhaseChanging},
    on_record=function(self,event,room,player,ctx)
        if ctx.original_data:toPhaseChange().to==sgs.Player_NotActive then setstate(ctx.owner,ctx:getActivationRef(),"used","") end
    end,
    can_trigger=function() return "" end
}

C_liubei:addSkill(c_shien)

-- 仁泽技能（使命成功后获得）
c_renze = sgs.CreateTriggerSkillV2{
    name="c_renze",events={sgs.EventPhaseStart},frequency=sgs.Skill_Compulsory,
    can_trigger=function(self,event,room,player,data)
        if player and player:getPhase()==sgs.Player_Start then return owners(self,room) end
        return ""
    end,
    on_effect=function(self,event,room,player,ctx) room:sendCompulsoryTriggerLog(player,self:objectName());player:drawCards(self:getEffectiveAmount(ctx),self:objectName());return false end
}

-- 使用addToSkills注册仁泽技能
addToSkills(c_renze)

-- 汉脉技能（主公技）
c_hanmai = sgs.CreateTriggerSkillV2{
    name = "c_hanmai",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,  -- 锁定技

    on_effect = function(self, event, room, player, ctx)
        local data=ctx.original_data
        -- player是拥有汉脉技能的刘备
        local death = data:toDeath()
        local dead = death.who

        -- 检查死亡角色的武将牌上是否有主公技
        local lord_skills = {}

        -- 检查主将
        local general1 = dead:getGeneral()
        if general1 then
            local skills1 = general1:getSkillList()
            for _, skill in sgs.qlist(skills1) do
                if skill:isLordSkill() then
                    table.insert(lord_skills, skill:objectName())
                end
            end
        end

        -- 检查副将
        local general2 = dead:getGeneral2()
        if general2 then
            local skills2 = general2:getSkillList()
            for _, skill in sgs.qlist(skills2) do
                if skill:isLordSkill() then
                    table.insert(lord_skills, skill:objectName())
                end
            end
        end

        -- 如果死亡角色没有主公技，不触发
        if #lord_skills == 0 then return false end

        -- 刘备获得主公技
        room:sendCompulsoryTriggerLog(player, "c_hanmai")

        for _, skill_name in ipairs(lord_skills) do
            -- 检查刘备是否已经有这个技能
            if not player:hasSkill(skill_name) then
                room:acquireSkill(player, skill_name)

                -- 发送日志
                local log = sgs.LogMessage()
                log.type = "#AcquireSkill"
                log.from = player
                log.arg = skill_name
                room:sendLog(log)
            end
        end

        return false
    end,

    can_trigger = function(self,event,room,player,data)
        local dead=data:toDeath().who;local found=false
        for _,general in ipairs({dead:getGeneral(),dead:getGeneral2()}) do
            if general then for _,skill in sgs.qlist(general:getSkillList()) do if skill:isLordSkill() then found=true;break end end end
        end
        if not found then return "" end
        local names,holders={},{}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasLordSkill(self:objectName()) then table.insert(names,self:objectName());table.insert(holders,p:objectName()) end
        end
        return table.concat(names,"|"),table.concat(holders,"|")
    end
}

C_liubei:addSkill(c_hanmai)


--庞统
sgs.LoadTranslationTable{
    ["C_pangtong"] = "人间-庞统",
    ["&C_pangtong"] = "庞统",
    ["#C_pangtong"] = "凤雏",
    ["c_luanhui"] = "鸾回",
    [":c_luanhui"] = "出牌阶段限一次，你可以将你的体力值调整为你已损失体力值，然后摸X张牌（X为二者之差）。",
    ["#c_luanhui_log"] = "%from 发动了【鸾回】，体力值从 %arg 调整为 %arg2，摸 %arg3 张牌",
    ["c_fengqi"] = "凤栖",
    [":c_fengqi"] = "限定技，当你进入濒死状态时，你可以发动【鸾回】并失去【鸾回】，然后本轮你使用牌无次数限制。",
    ["@c_fengqi"] = "凤栖",
    ["#c_fengqi_log"] = "%from 发动了【凤栖】，失去了【鸾回】，本轮使用牌无次数限制"
}

-- General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
C_pangtong = sgs.General(extension, "C_pangtong", "shu", 5, true, false, false, 3)
C_pangtong:setImage("pangtong")

-- 鸾回技能卡
local function resolveLuanhui(room,source,amount)
        local current_hp = source:getHp()
        local lost_hp = source:getLostHp()
        local diff = math.abs(current_hp - lost_hp)

        -- 记录日志
        local msg = sgs.LogMessage()
        msg.type = "#c_luanhui_log"
        msg.from = source
        msg.arg = current_hp
        msg.arg2 = lost_hp
        msg.arg3 = diff
        room:sendLog(msg)

        -- 通过失去体力或回复体力来调整，而不是直接设置
        if current_hp > lost_hp then
            -- 当前体力大于目标体力，需要失去体力
            room:loseHp(source, current_hp - lost_hp, true, source, "c_luanhui")
        elseif current_hp < lost_hp then
            -- 当前体力小于目标体力，需要回复体力
            room:recover(source, sgs.RecoverStruct(source, nil, lost_hp - current_hp))
        end

        -- 摸X张牌
        if diff > 0 and source:isAlive() then
            source:drawCards(diff * amount, "c_luanhui")
        end

end

-- 鸾回 ViewAs 技能
c_luanhuiVS = sgs.CreateViewAsSkillV2{
    name="c_luanhui",target_mode=sgs.ViewAsSkillV2_NoTarget,limit_scope=sgs.Skill_Limit_Phase,phase_name="Play",max_usage_limit=1,
    can_activate=function(self,request) return play(request) and request:getInitiator():getHp()~=request:getInitiator():getLostHp() end,
    on_effect=function(self,ctx) resolveLuanhui(ctx.invoker:getRoom(),ctx.invoker,self:getEffectiveAmount(ctx)) end
}

c_luanhui = sgs.CreateTriggerSkillV2{name="c_luanhui",view_as_skill=c_luanhuiVS}

-- 凤栖技能（限定技）
c_fengqi = sgs.CreateTriggerSkillV2{
    name="c_fengqi",frequency=sgs.Skill_Limited,limit_scope=sgs.Skill_Limit_Game,max_usage_limit=1,
    events={sgs.Dying,sgs.RoundEnd},
    on_record=function(self,event,room,player,ctx)
        if event==sgs.RoundEnd then room:setSkillInstanceCorrectState(ctx.owner,ctx:getActivationRef(),"unlimited",sgs.QVariant(false)) end
    end,
    can_trigger=function(self,event,room,player,data)
        if event==sgs.Dying and data:toDying().who==player then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        if not room:askForSkillInvoke(player,self:objectName()) then return false end
        local choices={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds("c_luanhui")) do table.insert(choices,"c_luanhui#"..id) end
        ctx.choice=#choices==0 and "" or (#choices==1 and choices[1] or room:askForChoice(player,self:objectName(),table.concat(choices,"+")))
        return true
    end,
    on_effect=function(self,event,room,player,ctx)
        log(room,"#c_fengqi_log",player);resolveLuanhui(room,player,self:getEffectiveAmount(ctx))
        if ctx.choice~="" then room:detachSkillFromPlayer(player,ctx.choice) end
        room:setSkillInstanceCorrectState(player,ctx:getActivationRef(),"unlimited",sgs.QVariant(true));return false
    end
}

-- 凤栖的无次数限制效果
c_fengqi_unlimited = sgs.CreateTargetModSkillV2{
    name="#c_fengqi_unlimited",holder_selector=sgs.CorrectSkill_Primary,
    correct_func=function(self,ctx)
        local parent=ctx:getHolder():getSkillInstanceParentRef(ctx:getInstanceRef().key.skillName,ctx:getInstanceRef().key.instanceID)
        if parent:isValid() and ctx:getModType()==sgs.TargetModSkill_Residue and ctx:getHolder():getSkillInstanceCorrectStateValue(parent.key.skillName,parent.key.instanceID,"unlimited"):toBool() then
            return sgs.CorrectSkillResult.unlimitedResidue()
        end
        return false
    end
}

C_pangtong:addSkill(c_luanhui)
C_pangtong:addSkill(c_fengqi)
addToSkills(c_fengqi_unlimited)
extension:insertRelatedSkills("c_fengqi", "#c_fengqi_unlimited")



--于禁

C_yujin = sgs.General(extension, "C_yujin", "wei", 4)
C_yujin:setImage("yujin")
sgs.LoadTranslationTable{
    ["C_yujin"] = "人间-于禁",
    ["&C_yujin"] = "于禁",
    ["#C_yujin"] = "威严毅重",
    ["c_yizhong"] = "毅重",
    [":c_yizhong"] = "锁定技，黑色杀对你无效。准备阶段，你可以将此技能交给一名其他角色，直至本轮结束。",
    ["@c_yizhong"] = "你可以将【毅重】交给一名其他角色，直至本轮结束",
    ["#c_yizhong_invalid"] = "%from 的【毅重】被触发，【%arg】对其无效",
    ["#c_yizhong_transfer"] = "%from 将【毅重】交给了 %to，直至本轮结束",
    ["#c_yizhong_return"] = "本轮结束，【毅重】从 %from 返回给 %to"
}

-- 毅重技能效果：黑色杀无效
c_yizhong = sgs.CreateTriggerSkillV2{
    name="c_yizhong",frequency=sgs.Skill_Compulsory,events={sgs.CardEffected,sgs.EventPhaseStart},
    can_trigger=function(self,event,room,player,data)
        if event==sgs.CardEffected then
            local effect=data:toCardEffect()
            if effect.card and effect.card:isKindOf("Slash") and effect.card:isBlack() then return own(self,event,room,player,data) end
        elseif player and player:getPhase()==sgs.Player_Start then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        if event==sgs.CardEffected then return true end
        if state(player,ctx:getActivationRef(),"original"):toString()~="" then return false end
        local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@c_yizhong",true,true)
        if not target then return false end;ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        if event==sgs.CardEffected then
            local effect=ctx.original_data:toCardEffect();log(room,"#c_yizhong_invalid",player,nil,effect.card:objectName())
            effect.nullified=true;ctx.original_data:setValue(effect)
        else
            local target=ctx.targets:first();log(room,"#c_yizhong_transfer",player,target)
            room:detachSkillFromPlayer(player,exactName(ctx:getActivationRef()))
            local id=room:acquireSkill(target,self:objectName())
            if id<=0 then return false end
            local ref=sgs.SkillInstanceRef(target:objectName(),sgs.SkillInstanceKey(self:objectName(),id))
            setstate(target,ref,"original",player:objectName())
            room:attachSkillToPlayer(target,"#c_yizhong_return",ref,false)
        end
        return false
    end
}

-- 隐藏技能：本轮结束时返还毅重技能
c_yizhong_return = sgs.CreateTriggerSkillV2{
    name="#c_yizhong_return",frequency=sgs.Skill_Compulsory,events={sgs.RoundEnd},
    can_trigger=function(self,event,room,player,data) return owners(self,room) end,
    on_cost=function(self,event,room,player,ctx)
        local parent=player:getSkillInstanceParentRef(self:objectName(),ctx.instanceID)
        if not parent:isValid() then return false end
        local original=room:findPlayerByObjectName(state(player,parent,"original"):toString())
        if not original or not original:isAlive() or original==player then return false end
        ctx.targets:append(original);ctx.extra_data=sgs.QVariant(parent.key.instanceID);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local original=ctx.targets:first();log(room,"#c_yizhong_return",player,original)
        room:detachSkillFromPlayer(player,"c_yizhong#"..ctx.extra_data:toInt())
        room:acquireSkill(original,"c_yizhong");return false
    end
}

C_yujin:addSkill(c_yizhong)
addToSkills(c_yizhong_return)



--[[
    时师 - 利用游戏计时功能的测试武将
    技能：
    【计时】：回合开始时，根据游戏时长获得不同效果：
        - 0-3分钟：摸1张牌
        - 3-6分钟：摸2张牌
        - 6-10分钟：摸2张牌并回复1点体力
        - 10分钟以上：摸3张牌并回复1点体力
    【时光】：当你受到伤害后，若游戏时长超过5分钟，你可以防止此伤害
]]--

sgs.LoadTranslationTable {
    ["C_shishi"] = "人间-时师",
    ["&C_shishi"] = "时师",
    ["#C_shishi"] = "掌控时间",
    ["designer:C_shishi"] = "Kiro AI",

    ["c_jishi"] = "计时",
    [":c_jishi"] = "回合开始时，根据游戏时长获得不同效果：0-3分钟摸1张牌；3-6分钟摸2张牌；6-10分钟摸2张牌并回复1点体力；10分钟以上摸3张牌并回复1点体力。",

    ["c_shiguang"] = "时光",
    [":c_shiguang"] = "当你受到伤害后，若游戏时长超过5分钟，你可以防止此伤害。",

    ["#c_jishi_log"] = "%from 发动了【%arg】，当前游戏时长：%arg2",
    ["#c_shiguang_prevent"] = "%from 发动了【%arg】，游戏时长已超过5分钟，防止了此次伤害",
}

C_shishi = sgs.General(extension, "C_shishi", "qun", 3)

-- 技能1：计时 - 根据游戏时长获得不同效果
c_jishi = sgs.CreateTriggerSkillV2{
    name = "c_jishi",
    events = {sgs.EventPhaseStart, sgs.GameStart},
    frequency = sgs.Skill_Compulsory,

    on_record = function(self, event, room, player, ctx)
        if event == sgs.GameStart then setstate(ctx.owner, ctx:getActivationRef(), "game_start", os.time()) end
    end,

    on_effect = function(self, event, room, player, ctx)
        room:writeToConsole("========== 【计时】技能触发 ==========")
        room:writeToConsole("玩家: " .. player:getGeneralName())
        room:writeToConsole("当前阶段: " .. player:getPhase())

        if player:getPhase() ~= sgs.Player_Start then
            room:writeToConsole("不是准备阶段，跳过")
            return false
        end

        -- 获取游戏时长（秒）
        local elapsed = gameElapsedSeconds(player, ctx:getActivationRef())
        room:writeToConsole(">>> 游戏时长: " .. tostring(elapsed) .. " 秒")

        -- 转换为分钟和秒
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        local time_str = string.format("%d分%d秒", minutes, seconds)
        room:writeToConsole(">>> 格式化时间: " .. time_str)

        -- 发送日志
        local log = sgs.LogMessage()
        log.type = "#c_jishi_log"
        log.from = player
        log.arg = self:objectName()
        log.arg2 = time_str
        room:sendLog(log)

        room:notifySkillInvoked(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), player)

        -- 根据游戏时长给予不同效果
        local draw_count = 0
        local recover = false
        local effect_desc = ""

        if elapsed < 180 then
            -- 0-3分钟：摸1张牌
            draw_count = 1
            effect_desc = "0-3分钟效果"
            room:writeToConsole(">>> 时间段: 0-3分钟，摸1张牌")
        elseif elapsed < 360 then
            -- 3-6分钟：摸2张牌
            draw_count = 2
            effect_desc = "3-6分钟效果"
            room:writeToConsole(">>> 时间段: 3-6分钟，摸2张牌")
        elseif elapsed < 600 then
            -- 6-10分钟：摸2张牌并回复1点体力
            draw_count = 2
            recover = true
            effect_desc = "6-10分钟效果"
            room:writeToConsole(">>> 时间段: 6-10分钟，摸2张牌并回复1点体力")
        else
            -- 10分钟以上：摸3张牌并回复1点体力
            draw_count = 3
            recover = true
            effect_desc = "10分钟以上效果"
            room:writeToConsole(">>> 时间段: 10分钟以上，摸3张牌并回复1点体力")
        end

        room:writeToConsole(">>> 效果: " .. effect_desc)
        room:writeToConsole(">>> 摸牌数: " .. draw_count)
        room:writeToConsole(">>> 是否回复体力: " .. tostring(recover))

        -- 执行效果
        if draw_count > 0 then
            room:writeToConsole(">>> 执行摸牌...")
            player:drawCards(draw_count * self:getEffectiveAmount(ctx), self:objectName())
            room:writeToConsole(">>> 摸牌完成")
        end

        if recover and player:isWounded() then
            room:writeToConsole(">>> 执行回复体力...")
            local rec = sgs.RecoverStruct()
            rec.who = player
            rec.recover = self:getEffectiveAmount(ctx)
            room:recover(player, rec)
            room:writeToConsole(">>> 回复体力完成")
        elseif recover then
            room:writeToConsole(">>> 玩家未受伤，跳过回复")
        end

        room:writeToConsole("========== 【计时】技能结束 ==========")
        return false
    end,

    can_trigger=function(self,event,room,player,data)
        if player and player:getPhase()==sgs.Player_Start then return own(self,event,room,player,data) end
        return ""
    end
}

-- 技能2：时光 - 游戏时长超过5分钟时可以防止伤害
c_shiguang = sgs.CreateTriggerSkillV2{
    name="c_shiguang",events={sgs.DamageComplete,sgs.GameStart},frequency=sgs.Skill_Limited,
    limit_scope=sgs.Skill_Limit_Game,max_usage_limit=1,
    on_record=function(self,event,room,player,ctx)
        if event==sgs.GameStart then setstate(ctx.owner,ctx:getActivationRef(),"game_start",os.time()) end
    end,
    can_trigger=function(self,event,room,player,data)
        if event~=sgs.DamageComplete or not player or not player:isAlive() then return "" end
        local damage=data:toDamage()
        if damage.to~=player then return "" end
        local names={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds(self:objectName())) do
            local ref=sgs.SkillInstanceRef(player:objectName(),sgs.SkillInstanceKey(self:objectName(),id))
            if gameElapsedSeconds(player,ref)>=300 then table.insert(names,self:objectName().."#"..id) end
        end
        return table.concat(names,"+"),player
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        room:broadcastSkillInvoke(self:objectName(),player);log(room,"#c_shiguang_prevent",player,nil,self:objectName())
        -- Donor uses DamageComplete: restore already-lost HP, never claim prevention.
        local amount=ctx.original_data:toDamage().damage
        if amount>0 then room:recover(player,sgs.RecoverStruct(player,nil,amount)) end
        return false
    end
}

C_shishi:addSkill(c_jishi)
C_shishi:addSkill(c_shiguang)




-- 三国杀diy吧 3D2J：仅据 diyba.md §2.1，独立于官方同名版本。
local diyba_quanjian = sgs.CreateViewAsSkillV2{
    name="diyba_quanjian", n=1, target_mode=sgs.ViewAsSkillV2_SelectTargets,
    will_throw_selected_cards=false, limit_scope=sgs.Skill_Limit_Phase, phase_name="Play", max_usage_limit=1,
    can_activate=function(self,request) return play(request) end,
    can_select_card=function(self,request,card)
        return request:getSelectedCardIds():isEmpty() and not card:isEquipped() and card:isKindOf("Jink")
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==1 end,
    can_select_target=function(self,request,selected,candidate)
        return #selected==0 and candidate~=request:getInitiator()
    end,
    targets_feasible=function(self,request,selected) return #selected==1 end,
    pay=function(self,room,ctx,request)
        local id=request:getSelectedCardIds():first()
        local target=ctx.targets:first()
        if not target or room:getCardOwner(id)~=ctx.invoker or room:getCardPlace(id)~=sgs.Player_PlaceHand
            or not sgs.Sanguosha:getCard(id):isKindOf("Jink") then return false end
        room:obtainCard(target,sgs.Sanguosha:getCard(id),sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,ctx.invoker:objectName(),target:objectName(),self:objectName(),""),false)
        return true
    end,
    on_effect=function(self,ctx)
        local source,target=ctx.invoker,ctx.targets:first()
        local room=source:getRoom()
        if not source:isAlive() or not target:isAlive() or target:isKongcheng() then return end
        local id=room:askForCardChosen(source,target,"h",self:objectName())
        room:showCard(target,id,sgs.SPlayerList(),self:objectName())
        if sgs.Sanguosha:getCard(id):isKindOf("Jink") then
            source:drawCards(1,self:objectName())
            if target:isAlive() then target:drawCards(1,self:objectName()) end
        end
    end
}
local diyba_sijie = sgs.CreateTriggerSkillV2{
    name="diyba_sijie", events={sgs.Damaged},
    can_trigger=function(self,event,room,player,data)
        -- 每一点伤害各自选择（multiplier）；伤害过程中死亡或失去技能由 can_trigger 重检。
        local name,owner=own(self,event,room,player,data)
        local damage=data:toDamage()
        if name~="" and damage.damage>0 then return name.."*"..damage.damage, owner end
        return ""
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local candidates=sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if player:canDiscard(p,"he") then candidates:append(p) end
        end
        if candidates:isEmpty() then return false end
        local target=room:askForPlayerChosen(player,candidates,self:objectName(),"@diyba-sijie",false,true)
        local count=math.max(1,target:getLostHp())
        for j=1,count do
            if not player:isAlive() or not target:isAlive() or not player:canDiscard(target,"he") then break end
            local id=room:askForCardChosen(player,target,"he",self:objectName(),false,sgs.Card_MethodDiscard)
            room:throwCard(id,target,player)
        end
        return false
    end
}
local diyba_jushou=sgs.General(extension,"diyba_2j_jushou","qun",3)
diyba_jushou:setImage("jushou")
diyba_jushou:addSkill(diyba_quanjian)
diyba_jushou:addSkill(diyba_sijie)
sgs.LoadTranslationTable{
    ["diyba_2j_jushou"]="沮授", ["&diyba_2j_jushou"]="沮授", ["#diyba_2j_jushou"]="忠贞义烈·3D二将",
    ["designer:diyba_2j_jushou"]="三国杀diy吧",
    ["diyba_quanjian"]="劝谏",
    [":diyba_quanjian"]="出牌阶段，你可以交给一名其他角色一张【闪】，展示其一张手牌：若为【闪】，则你与该角色各摸一张牌。每阶段限一次。",
    ["diyba_sijie"]="死节",
    [":diyba_sijie"]="每当你受到1点伤害后，可弃置一名角色的X张牌（X为该角色已损失的体力值，且至少为1）。",
    ["@diyba-sijie"]="死节：选择一名角色，弃置其牌",
}


-- 3D2J 程昱：捧日/刚戾，同名官方及极略版本均非本设计。
local function diyba_slash(room,from,to,skill)
    if not from:isAlive() or not to:isAlive() then return end
    local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
    slash:setSkillName(skill)
    if not from:isProhibited(to,slash) then
        local use=sgs.CardUseStruct()
        use.card=slash; use.from=from; use.to:append(to)
        room:useCard(use,false)
    end
    slash:deleteLater()
end
local diyba_pengri=sgs.CreateViewAsSkillV2{
    name="diyba_pengri", target_mode=sgs.ViewAsSkillV2_SelectTargets,
    limit_scope=sgs.Skill_Limit_Phase, phase_name="Play", max_usage_limit=1,
    can_activate=function(self,request) return play(request) end,
    can_select_target=function(self,request,selected,candidate)
        return #selected==0 and candidate~=request:getInitiator() and not candidate:isNude()
    end,
    targets_feasible=function(self,request,selected) return #selected==1 end,
    on_effect=function(self,ctx)
        local player,target=ctx.invoker,ctx.targets:first()
        local room=player:getRoom()
        if not target or not target:isAlive() or not player:canGet(target,"he") then return end
        local id=room:askForCardChosen(player,target,"he",self:objectName(),false,sgs.Card_MethodGet)
        if not player:canGet(target,id) then return end
        room:obtainCard(player,sgs.Sanguosha:getCard(id),sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,player:objectName(),target:objectName(),self:objectName(),""),false)
        diyba_slash(room,target,player,self:objectName())
    end
}
local diyba_gangli=sgs.CreateTriggerSkillV2{
    name="diyba_gangli", events={sgs.Damaged},
    can_trigger=function(self,event,room,player,data)
        local damage=data:toDamage()
        if damage.from and damage.from~=player and damage.from:isAlive() and damage.damage>0 then
            local name,owner=own(self,event,room,player,data)
            if name~="" then return name.."*"..damage.damage, owner end
        end
        return ""
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local damage=ctx.original_data:toDamage()
        local candidates=sgs.SPlayerList()
        local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
        slash:setSkillName(self:objectName())
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p~=damage.from and not damage.from:isProhibited(p,slash) then candidates:append(p) end
        end
        slash:deleteLater()
        if not candidates:isEmpty() then
            local target=room:askForPlayerChosen(player,candidates,self:objectName(),"@diyba-gangli",false,true)
            diyba_slash(room,damage.from,target,self:objectName())
        end
        return false
    end
}
local diyba_chengyu=sgs.General(extension,"diyba_2j_chengyu","wei",3)
diyba_chengyu:setImage("chengyu")
diyba_chengyu:addSkill(diyba_pengri)
diyba_chengyu:addSkill(diyba_gangli)
sgs.LoadTranslationTable{
    ["diyba_2j_chengyu"]="程昱", ["&diyba_2j_chengyu"]="程昱", ["#diyba_2j_chengyu"]="世之奇士·3D二将",
    ["designer:diyba_2j_chengyu"]="三国杀diy吧",
    ["diyba_pengri"]="捧日",
    [":diyba_pengri"]="出牌阶段，你可以获得一名其他角色的一张牌，视为该角色对你使用一张【杀】。每阶段限一次。",
    ["diyba_gangli"]="刚戾",
    [":diyba_gangli"]="每当你受到其他角色造成的1点伤害后，你可以：选择除伤害来源外的另一名角色，视为伤害来源对该角色使用一张【杀】（此【杀】无距离限制且不计入出牌阶段使用次数限制）。",
    ["@diyba-gangli"]="刚戾：选择伤害来源以外的一名角色，令来源对其使用【杀】",
}

-- 3D2J 李儒：毒计储牌与本次杀的酒效果；不改官方同名将。
local diyba_dujiVS=sgs.CreateViewAsSkillV2{
    name="diyba_duji", n=1, target_mode=sgs.ViewAsSkillV2_SelectTargets,
    will_throw_selected_cards=false,
    can_activate=function(self,request)
        return play(request) and request:getInitiator():getPile("diyba_poison"):isEmpty()
    end,
    can_select_card=function(self,request,card)
        return request:getSelectedCardIds():isEmpty() and card:getSuit()==sgs.Card_Spade
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==1 end,
    targets_feasible=function(self,request,selected) return #selected==0 end,
    pay=function(self,room,ctx,request)
        local id=request:getSelectedCardIds():first()
        if not ctx.invoker:getPile("diyba_poison"):isEmpty() or room:getCardOwner(id)~=ctx.invoker then return false end
        ctx.invoker:addToPile("diyba_poison",id,true)
        return true
    end,
    on_effect=function(self,ctx) end
}
local diyba_duji=sgs.CreateTriggerSkillV2{
    name="diyba_duji", view_as_skill=diyba_dujiVS, events={sgs.TargetSpecified},
    can_trigger=function(self,event,room,player,data)
        local use=data:toCardUse()
        if not player or player:getPhase()~=sgs.Player_Play or not use.card:isKindOf("Slash") then return "" end
        local names,players={},{}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p~=player and p:hasSkill(self:objectName()) and not p:getPile("diyba_poison"):isEmpty() then
                table.insert(names,self:objectName());table.insert(players,p:objectName())
            end
        end
        return table.concat(names,"|"),table.concat(players,"|")
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local owner=ctx.owner
        local use=ctx.original_data:toCardUse()
        local id=owner:getPile("diyba_poison"):first()
        if id<0 or not use.from:isAlive() then return false end
        -- Tag before the card movement: movement triggers may kill the user.
        use.card:setTag("drank",sgs.QVariant(math.max(1,use.card:getTag("drank"):toInt())))
        room:setCardFlag(use.card,"drank")
        room:obtainCard(use.from,sgs.Sanguosha:getCard(id),sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,owner:objectName(),use.from:objectName(),self:objectName(),""),true)
        if use.from:isAlive() then
            if room:askForChoice(use.from,self:objectName(),"turnover+losehp",ctx.original_data)=="turnover" then
                use.from:turnOver()
            else room:loseHp(use.from,1,true,owner,self:objectName()) end
        end
        return false
    end
}
local diyba_shipo=sgs.CreateProhibitSkillV2{
    name="diyba_shipo",
    holder_selector = sgs.CorrectSkill_Secondary,
    is_prohibited=function(self,ctx)
        local to, card = ctx:getTo(), ctx:getCard()
        return to:hasSkill(self:objectName()) and card:getSuit()==sgs.Card_Spade
            and (card:isKindOf("Slash") or card:isKindOf("TrickCard"))
    end
}
local diyba_liru=sgs.General(extension,"diyba_2j_liru","qun",3)
diyba_liru:setImage("liru")
diyba_liru:addSkill(diyba_duji)
diyba_liru:addSkill(diyba_shipo)
sgs.LoadTranslationTable{
    ["diyba_2j_liru"]="李儒",["&diyba_2j_liru"]="李儒",["#diyba_2j_liru"]="魔王的智囊·3D二将",
    ["designer:diyba_2j_liru"]="三国杀diy吧",["diyba_poison"]="毒计",
    ["diyba_duji"]="毒计",[":diyba_duji"]="出牌阶段，若你的武将牌上没有牌，你可以将一张黑桃牌置于你的武将牌上。当一名其他角色在其出牌阶段使用一张【杀】指定目标后，你可将此牌置于其手上，并令此【杀】当有【酒】效果的【杀】结算，然后该角色须执行下列一项：将武将牌翻面或失去1点体力。",
    ["diyba_shipo"]="识破",[":diyba_shipo"]="锁定技，你不能成为黑桃【杀】或黑桃锦囊的目标。",
}

-- 3D3J 刘协：血昭按选择顺序指定杀的使用者、目标。
local diyba_xuezhao=sgs.CreateViewAsSkillV2{
    name="diyba_xuezhao",n=2,target_mode=sgs.ViewAsSkillV2_SelectTargets,
    limit_scope=sgs.Skill_Limit_Phase,phase_name="Play",max_usage_limit=1,
    will_throw_selected_cards=false,
    can_activate=function(self,request) return play(request) end,
    can_select_card=function(self,request,card)
        return request:getSelectedCardIds():length()<2 and not request:getInitiator():isJilei(card)
    end,
    card_selection_feasible=function(self,request)
        local n=request:getSelectedCardIds():length();return n==0 or n==2
    end,
    can_select_target=function(self,request,selected,candidate)
        return #selected<2 and (#selected==0 or selected[1]~=candidate)
    end,
    targets_feasible=function(self,request,selected) return #selected==2 end,
    pay=function(self,room,ctx,request)
        local ids=request:getSelectedCardIds()
        if ids:isEmpty() then room:loseHp(ctx.invoker,1,true,ctx.invoker,self:objectName());return true end
        if ids:length()~=2 then return false end
        local dummy=sgs.DummyCard()
        for _,id in sgs.qlist(ids) do
            if room:getCardOwner(id)~=ctx.invoker or ctx.invoker:isJilei(sgs.Sanguosha:getCard(id)) then
                dummy:deleteLater();return false
            end
            dummy:addSubcard(id)
        end
        room:throwCard(dummy,ctx.invoker,ctx.invoker);dummy:deleteLater()
        return true
    end,
    on_effect=function(self,ctx)
        local from,to=ctx.targets:at(0),ctx.targets:at(1)
        local room=ctx.invoker:getRoom()
        if not from or not to or not from:isAlive() or not to:isAlive() then return end
        if not room:askForUseSlashTo(from,to,"@diyba-xuezhao:"..to:objectName(),false,false,false)
            and from:isAlive() then room:loseHp(from,1,true,ctx.invoker,self:objectName()) end
    end
}
local diyba_hanhuang=sgs.CreateTriggerSkillV2{
    name="diyba_hanhuang$",events={sgs.EventPhaseEnd},
    can_trigger=function(self,event,room,player,data)
        if not player or not player:isAlive() or player:getPhase()~=sgs.Player_Discard
            or player:getKingdom()~="qun" or not player:isKongcheng() then return "" end
        local names,holders={},{}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasLordSkill(self:objectName()) and p:isWounded() then
                table.insert(names,self:objectName());table.insert(holders,p:objectName())
            end
        end
        return table.concat(names,"|"),table.concat(holders,"|")
    end,
    on_cost=function(self,event,room,player,ctx)
        return room:askForSkillInvoke(ctx.invoker,self:objectName(),sgs.QVariant(ctx.owner:objectName()))
    end,
    on_effect=function(self,event,room,player,ctx)
        if ctx.owner:isAlive() then room:recover(ctx.owner,sgs.RecoverStruct(ctx.invoker,nil,1)) end
        return false
    end
}
local diyba_liuxie=sgs.General(extension,"diyba_3j_liuxie$","qun",4)
diyba_liuxie:setImage("liuxie")
diyba_liuxie:addSkill(diyba_xuezhao)
diyba_liuxie:addSkill(diyba_hanhuang)
sgs.LoadTranslationTable{
    ["diyba_3j_liuxie"]="刘协",["&diyba_3j_liuxie"]="刘协",["#diyba_3j_liuxie"]="最后的汉皇·3D三将",
    ["designer:diyba_3j_liuxie"]="三国杀diy吧",
    ["diyba_xuezhao"]="血昭",[":diyba_xuezhao"]="出牌阶段，你可以失去一点体力或弃两张牌，并指定一名角色发动，目标需要对另一名你指定的角色无视距离使用一张杀，否则目标失去一点体力。每阶段限一次。",
    ["@diyba-xuezhao"]="血昭：请对 %src 使用一张【杀】，否则失去1点体力",
    ["diyba_hanhuang"]="汉皇",[":diyba_hanhuang"]="主公技，群势力角色弃牌阶段结束时若没有手牌，可以令你恢复一点体力。",
}

-- 3D7J 韩当：装备格数使用引擎计数，含宝物及额外装备格。
local diyba_gongqi=sgs.CreateDistanceSkillV2{
    name="diyba_gongqi",holder_selector=sgs.CorrectSkill_Primary,
    correct_func=function(self,ctx)
        local from=ctx:getPrimary()
        return -from:getEquipArea()
    end
}
local diyba_jiefan=sgs.CreateViewAsSkillV2{
    name="diyba_jiefan",response_or_use=true,
    can_activate=function(self,request)
        local p=request:getInitiator()
        if p:getEquipArea()<=0 or p:getMark("Global_PreventPeach")>0 then return false end
        if play(request) then
            local peach=sgs.Sanguosha:cloneCard("peach")
            local available=peach:isAvailable(p);peach:deleteLater();return available
        end
        return string.find(request:getPattern() or "","peach",1,true)~=nil
    end,
    create_card=function(self,request)
        local peach=sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit,0)
        peach:setSkillName(self:objectName());return peach
    end,
    pay=function(self,room,ctx,request)
        local p=ctx.invoker
        local choices={}
        local names={"weapon_area","armor_area","defensive_horse_area","offensive_horse_area","treasure_area"}
        for i=0,4 do if p:hasEquipArea(i) then table.insert(choices,names[i+1]) end end
        if #choices==0 then return false end
        local choice=room:askForChoice(p,self:objectName(),table.concat(choices,"+"))
        for i=0,4 do
            if names[i+1]==choice and p:hasEquipArea(i) then
                local equipped=p:getEquip(i)~=nil
                p:throwEquipArea(i)
                if equipped and p:isAlive() then p:drawCards(2,self:objectName()) end
                return true
            end
        end
        return false
    end
}
local diyba_handang=sgs.General(extension,"diyba_7j_handang","wu",4)
diyba_handang:setImage("handang")
diyba_handang:addSkill(diyba_gongqi)
diyba_handang:addSkill(diyba_jiefan)
sgs.LoadTranslationTable{
    ["diyba_7j_handang"]="韩当",["&diyba_7j_handang"]="韩当",["#diyba_7j_handang"]="3D七将",
    ["designer:diyba_7j_handang"]="好孩子系我",
    ["diyba_gongqi"]="弓骑",[":diyba_gongqi"]="锁定技，你与其他角色计算距离时始终-X。(X为你的装备格数)",
    ["diyba_jiefan"]="解烦",[":diyba_jiefan"]="你可以失去一个装备格，视为使用一张【桃】；若你以此法失去了装备牌，你摸两张牌。",
}

-- 3D2J 蒋琬：规为公开独立牌堆；蹈矩由原锦囊负责目标校验。
local diyba_yaliang=sgs.CreateTriggerSkillV2{
    name="diyba_yaliang",events={sgs.TargetConfirming},
    can_trigger=function(self,event,room,player,data)
        local use=data:toCardUse()
        if use.from and use.from~=player and use.card:isNDTrick() and use.to:contains(player)
            and not table.contains(use.nullified_list,player:objectName()) then
            return own(self,event,room,player,data)
        end
        return ""
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local use=ctx.original_data:toCardUse()
        local nullified=use.nullified_list
        table.insert(nullified,player:objectName());use.nullified_list=nullified
        ctx.original_data:setValue(use)
        player:drawCards(1,self:objectName())
        diyba_slash(room,use.from,player,self:objectName())
        return false
    end
}
local diyba_xungui=sgs.CreateViewAsSkillV2{
    name="diyba_xungui",n=1,target_mode=sgs.ViewAsSkillV2_SelectTargets,
    limit_scope=sgs.Skill_Limit_Phase,phase_name="Play",max_usage_limit=1,
    will_throw_selected_cards=false,
    can_activate=function(self,request) return play(request) end,
    can_select_card=function(self,request,card)
        return request:getSelectedCardIds():isEmpty() and card:isNDTrick()
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==1 end,
    targets_feasible=function(self,request,selected) return #selected==0 end,
    pay=function(self,room,ctx,request)
        local p=ctx.invoker
        local id=request:getSelectedCardIds():first()
        if room:getCardOwner(id)~=p then return false end
        local old=sgs.DummyCard();old:addSubcards(p:getPile("diyba_rule"))
        local replaced=old:subcardsLength()>0
        -- Install the new rule before movement triggers can re-enter this skill.
        p:addToPile("diyba_rule",id,true)
        if replaced then room:throwCard(old,p,p) end
        old:deleteLater()
        if replaced and p:isAlive() then room:recover(p,sgs.RecoverStruct(p,nil,1)) end
        return true
    end,
    on_effect=function(self,ctx) end
}
local diyba_daoju=sgs.CreateViewAsSkillV2{
    name="diyba_daoju",n=2,
    limit_scope=sgs.Skill_Limit_Phase,phase_name="Play",max_usage_limit=1,
    can_activate=function(self,request)
        local pile=request:getInitiator():getPile("diyba_rule")
        if not play(request) or pile:isEmpty() then return false end
        local card=sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(pile:first()):objectName())
        local available=card:isAvailable(request:getInitiator());card:deleteLater();return available
    end,
    can_select_card=function(self,request,card)
        local ids=request:getSelectedCardIds()
        if card:isEquipped() or ids:length()>=2 then return false end
        if ids:isEmpty() then return card:isRed() or card:isBlack() end
        local first=sgs.Sanguosha:getCard(ids:first())
        return (first:isRed() and card:isRed()) or (first:isBlack() and card:isBlack())
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==2 end,
    create_card=function(self,request)
        local ids=request:getSelectedCardIds()
        local pile=request:getInitiator():getPile("diyba_rule")
        if ids:length()~=2 or pile:isEmpty() then return nil end
        local card=sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(pile:first()):objectName(),sgs.Card_NoSuit,0)
        card:addSubcards(ids);card:setSkillName(self:objectName());return card
    end
}
local diyba_jiangwan=sgs.General(extension,"diyba_2j_jiangwan","shu",3)
diyba_jiangwan:setImage("jiangwan")
diyba_jiangwan:addSkill(diyba_yaliang)
diyba_jiangwan:addSkill(diyba_xungui)
diyba_jiangwan:addSkill(diyba_daoju)
sgs.LoadTranslationTable{
    ["diyba_2j_jiangwan"]="蒋琬",["&diyba_2j_jiangwan"]="蒋琬",["#diyba_2j_jiangwan"]="安阳亭侯·3D二将",
    ["designer:diyba_2j_jiangwan"]="三国杀diy吧",["diyba_rule"]="规",
    ["diyba_yaliang"]="雅量",[":diyba_yaliang"]="当你成为其他角色所使用的非延时类锦囊的目标时，你可以摸一张牌，若如此做，该锦囊对你无效，且视为锦囊使用者对你使用了一张【杀】（该【杀】不计入回合使用限制）。",
    ["diyba_xungui"]="循规",[":diyba_xungui"]="出牌阶段，你可以将一张非延时类锦囊置于你的武将牌上，称为“规”。若存在“规”，则弃掉代替之，且你回复1点体力。每阶段限用一次。",
    ["diyba_daoju"]="蹈矩",[":diyba_daoju"]="出牌阶段，你可以将两张相同颜色手牌当“规”所示锦囊使用。每阶段限用一次。",
}

-- 3D2J 乐进：距离标记由引擎在回合结束清除，不覆盖其他固定距离。
local diyba_xiandeng=sgs.CreateTriggerSkillV2{
    name="diyba_xiandeng",events={sgs.DrawNCards},
    can_trigger=function(self,event,room,player,data)
        if player and player:getPhase()==sgs.Player_Draw and data:toInt()>0 then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@diyba-xiandeng",true,true)
        if not target then return false end
        ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        ctx.original_data:setValue(math.max(0,ctx.original_data:toInt()-1))
        room:setPlayerMark(player,"diyba_xiandeng_"..ctx.targets:first():objectName().."-Clear",1)
        return false
    end
}
local diyba_xiandengDistance=sgs.CreateDistanceSkillV2{
    name="#diyba_xiandeng-distance",holder_selector=sgs.CorrectSkill_Primary,
    fixed_func=function(self,ctx)
        local from,to=ctx:getPrimary(),ctx:getSecondary()
        if to and from:getMark("diyba_xiandeng_"..to:objectName().."-Clear")>0 then return 1 end
        return 0
    end
}
local function diyba_materials(card)
    local ids=sgs.IntList()
    if card:isVirtualCard() then ids=card:getSubcards() else ids:append(card:getEffectiveId()) end
    return ids
end
local diyba_xiaoguo=sgs.CreateTriggerSkillV2{
    name="diyba_xiaoguo",events={sgs.SlashMissed},
    can_trigger=function(self,event,room,player,data)
        local effect=data:toSlashEffect()
        if player and player:getPhase()==sgs.Player_Play and effect.jink and effect.to:isAlive()
            and (effect.slash:isBlack() or effect.slash:getSuit()==sgs.Card_Diamond) then
            return own(self,event,room,player,data)
        end
        return ""
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local effect=ctx.original_data:toSlashEffect()
        local jinks=sgs.DummyCard()
        for _,id in sgs.qlist(diyba_materials(effect.jink)) do
            local place=room:getCardPlace(id)
            if place==sgs.Player_DiscardPile or place==sgs.Player_PlaceTable then jinks:addSubcard(id) end
        end
        if jinks:subcardsLength()>0 then room:obtainCard(effect.to,jinks,self:objectName(),true) end
        jinks:deleteLater()
        if not player:isAlive() or not effect.to:isAlive() then return false end
        local name=effect.slash:isBlack() and "supply_shortage" or "indulgence"
        local trick=sgs.Sanguosha:cloneCard(name,effect.slash:getSuit(),effect.slash:getNumber())
        trick:setSkillName(self:objectName())
        local ids=diyba_materials(effect.slash)
        -- The delayed trick needs the Slash's still-available physical material.
        local available=not ids:isEmpty()
        for _,id in sgs.qlist(ids) do
            if room:getCardPlace(id)~=sgs.Player_PlaceTable then available=false end
        end
        if available and effect.to:hasJudgeArea() and not effect.to:containsTrick(name)
            and not player:isProhibited(effect.to,trick) then
            trick:addSubcards(ids)
            local use=sgs.CardUseStruct();use.card=trick;use.from=player;use.to:append(effect.to)
            room:useCard(use,false)
        end
        trick:deleteLater();return false
    end
}
local diyba_lejin=sgs.General(extension,"diyba_2j_lejin","wei",4)
diyba_lejin:setImage("yuejin")
diyba_lejin:addSkill(diyba_xiandeng)
diyba_lejin:addSkill(diyba_xiandengDistance)
diyba_lejin:addSkill(diyba_xiaoguo)
extension:insertRelatedSkills("diyba_xiandeng","#diyba_xiandeng-distance")
sgs.LoadTranslationTable{
    ["diyba_2j_lejin"]="乐进",["&diyba_2j_lejin"]="乐进",["#diyba_2j_lejin"]="胆识英烈·3D二将",
    ["designer:diyba_2j_lejin"]="三国杀diy吧",
    ["diyba_xiandeng"]="先登",[":diyba_xiandeng"]="摸牌阶段，你可少摸一张牌，然后你无视一名其它角色的距离直到回合结束。",
    ["@diyba-xiandeng"]="先登：选择本回合无视距离的角色（少摸一张牌）",
    ["diyba_xiaoguo"]="骁果",[":diyba_xiaoguo"]="出牌阶段，每当你使用黑色或方块【杀】被目标的【闪】抵消时，你可令此【闪】返回该角色手中，然后将此【杀】当一张延时锦囊对该角色使用（黑色当【兵粮寸断】，方块当【乐不思蜀】）。",
}

-- 3D10J 诸葛靓：转换状态及濒死救援次数分别属于技能实例。
local function diyba_sansiMode(player,ref)
    return state(player,ref,"mode"):toInt()%3+1
end
local function diyba_sansiAdvance(player,ref)
    local mode=diyba_sansiMode(player,ref)%3+1
    setstate(player,ref,"mode",mode-1)
    player:getRoom():setPlayerMark(player,"&diyba_sansi+"..ref.key.instanceID,mode)
    return mode
end
local diyba_sansi=sgs.CreateViewAsSkillV2{
    name="diyba_sansi",n=4,target_mode=sgs.ViewAsSkillV2_SelectTargets,
    will_throw_selected_cards=false,limit_scope=sgs.Skill_Limit_Phase,phase_name="Play",max_usage_limit=1,
    can_activate=function(self,request) return play(request) end,
    can_select_card=function(self,request,card)
        local p=request:getInitiator()
        if p:isCardLimited(card,sgs.Card_MethodRecast) then return false end
        local ids=request:getSelectedCardIds()
        local mode=diyba_sansiMode(p,requestRef(request))
        if ids:length()>=mode+1 then return false end
        if mode==1 then return true end
        for _,id in sgs.qlist(ids) do
            local c=sgs.Sanguosha:getCard(id)
            if (mode==2 and c:getTypeId()==card:getTypeId()) or (mode==3 and c:getSuit()==card:getSuit()) then return false end
        end
        return mode~=3 or card:getSuit()<=sgs.Card_Diamond
    end,
    card_selection_feasible=function(self,request)
        return request:getSelectedCardIds():length()==diyba_sansiMode(request:getInitiator(),requestRef(request))+1
    end,
    can_select_target=function(self,request,selected,candidate) return #selected==0 end,
    targets_feasible=function(self,request,selected) return #selected==1 end,
    pay=function(self,room,ctx,request)
        local p=ctx.invoker
        local ids=request:getSelectedCardIds()
        for _,id in sgs.qlist(ids) do
            if room:getCardOwner(id)~=p or (room:getCardPlace(id)~=sgs.Player_PlaceHand and room:getCardPlace(id)~=sgs.Player_PlaceEquip)
                or p:isCardLimited(sgs.Sanguosha:getCard(id),sgs.Card_MethodRecast) then return false end
        end
        -- Advance before movement/draw callbacks can re-enter the conversion.
        diyba_sansiAdvance(p,ctx:getActivationRef())
        local card=sgs.DummyCard();card:addSubcards(ids)
        room:moveCardTo(card,p,nil,sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST,p:objectName(),self:objectName(),""),true)
        card:deleteLater()
        if p:isAlive() then p:drawCards(ids:length(),self:objectName()) end
        return true
    end,
    on_effect=function(self,ctx)
        local target=ctx.targets:first()
        if target and target:isAlive() then target:drawCards(3,self:objectName()) end
    end
}
local diyba_jiezhong=sgs.CreateTriggerSkillV2{
    name="diyba_jiezhong",events={sgs.Dying},limit_scope=sgs.Skill_Limit_Round,max_usage_limit=1,
    can_trigger=function(self,event,room,player,data)
        local who=data:toDying().who
        if who and who:isAlive() and who:getHp()<1 then
            local names,players={},{}
            for _,p in sgs.qlist(room:getOtherPlayers(who)) do
                if p:hasSkill(self:objectName()) then table.insert(names,self:objectName());table.insert(players,p:objectName()) end
            end
            return table.concat(names,"|"),table.concat(players,"|")
        end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        if not room:askForSkillInvoke(player,self:objectName(),ctx.original_data) then return false end
        local choices={}
        for _,id in sgs.qlist(player:getValidSkillInstanceIds("diyba_sansi")) do table.insert(choices,tostring(id)) end
        ctx.choice=#choices==0 and "" or (#choices==1 and choices[1] or room:askForChoice(player,self:objectName(),table.concat(choices,"+")))
        return true
    end,
    on_pay=function(self,event,room,player,ctx)
        if not self:isUsable(ctx) then return false end
        self:addUsage(ctx);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local who=ctx.original_data:toDying().who
        if not who or not who:isAlive() or who:getHp()>=1 then return false end
        room:recover(who,sgs.RecoverStruct(player,nil,1-who:getHp()))
        if player:isAlive() and ctx.choice~="" and player:getValidSkillInstanceIds("diyba_sansi"):contains(tonumber(ctx.choice)) then
            local key=sgs.SkillInstanceKey();key.skillName="diyba_sansi";key.instanceID=tonumber(ctx.choice)
            local ref=sgs.SkillInstanceRef(player:objectName(),key)
            local mode=diyba_sansiAdvance(player,ref)
            if mode==1 then room:loseHp(player,1,true,player,self:objectName())
            elseif mode==3 then self:resetUsage(ctx) end
        end
        return false
    end
}
local diyba_zhugejing=sgs.General(extension,"diyba_10j_zhugejing","wu",4)
diyba_zhugejing:setImage("zhugejing")
diyba_zhugejing:addSkill(diyba_sansi)
diyba_zhugejing:addSkill(diyba_jiezhong)
sgs.LoadTranslationTable{
    ["diyba_10j_zhugejing"]="诸葛靓",["&diyba_10j_zhugejing"]="诸葛靓",["#diyba_10j_zhugejing"]="失恨咽漆·3D十将",
    ["designer:diyba_10j_zhugejing"]="绝代倾国倾城貌",
    ["diyba_sansi"]="三思",[":diyba_sansi"]="转换技，出牌阶段限一次，你可以重铸①两张牌②三种类别的牌③四种花色的牌，令一名角色摸三张牌。",
    ["diyba_jiezhong"]="竭忠",[":diyba_jiezhong"]="每轮限一次，其他角色进入濒死时，你可以令其将体力值回复至1点，然后你转换“三思”的状态；然后若“三思”状态：为①，你失去1点体力；为③，重置此技能。",
}

-- 3D2J SP 马良：用原牌的目标列表及 extra_effect 保留原结算流程。
local diyba_lianman=sgs.CreateTriggerSkillV2{
    name="diyba_lianman",events={sgs.TargetSpecified},
    can_trigger=function(self,event,room,player,data)
        local use=data:toCardUse()
        if use.card:isKindOf("TrickCard") and use.to:length()>1 then return owners(self,room) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local use=ctx.original_data:toCardUse()
        local candidates=sgs.SPlayerList()
        for _,p in sgs.qlist(use.to) do if p:isAlive() then candidates:append(p) end end
        if candidates:isEmpty() then return false end
        player:setTag("diyba_lianman_ai",ctx.original_data)
        local target=room:askForPlayerChosen(player,candidates,self:objectName(),"@diyba-lianman",true,true)
        player:removeTag("diyba_lianman_ai")
        if not target then return false end
        ctx.targets:append(target)
        ctx.choice=room:askForChoice(player,self:objectName(),"diyba_lianman_draw+diyba_lianman_skip",ctx.original_data)
        return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first()
        local use=ctx.original_data:toCardUse()
        if not target or not target:isAlive() or not use.to:contains(target) then return false end
        if ctx.choice=="diyba_lianman_draw" then
            local key="diyba_lianman_"..target:objectName()
            use.card:setTag(key,sgs.QVariant(use.card:getTag(key):toInt()+1))
            target:drawCards(1,self:objectName())
        else
            -- 保留目标身份，只跳过其效果；不取消其他目标或改变牌的总目标数。
            local nullified=use.nullified_list
            if not table.contains(nullified,target:objectName()) then
                table.insert(nullified,target:objectName());use.nullified_list=nullified
                ctx.original_data:setValue(use)
            end
            room:askForDiscard(target,self:objectName(),1,1,false,true)
        end
        return false
    end
}
local diyba_lianman_effect=sgs.CreateRuleSkillV2{
    name="#diyba_lianman_effect",events={sgs.CardEffect,sgs.CardFinished},
    on_record=function(self,event,room,player,ctx)
        local data=ctx.original_data
        if event==sgs.CardEffect then
            local effect=data:toCardEffect()
            local n=effect.card:getTag("diyba_lianman_"..effect.to:objectName()):toInt()
            if n>0 then effect.extra_effect=effect.extra_effect+n;data:setValue(effect) end
        else
            local card=data:toCardUse().card
            for _,p in sgs.qlist(room:getAllPlayers()) do card:removeTag("diyba_lianman_"..p:objectName()) end
        end
    end
}
addToSkills(diyba_lianman_effect)
local function diyba_xiemengTargets(player,use)
    local candidates=sgs.SPlayerList()
    for _,p in sgs.qlist(player:getRoom():getOtherPlayers(player)) do
        -- 只放宽目标数量；距离、禁止、判定区等原牌规则仍有效。
        if not use.to:contains(p) and not use.from:isProhibited(p,use.card)
            and use.card:targetFilter(sgs.PlayerList(),p,use.from) then candidates:append(p) end
    end
    return candidates
end
local diyba_xiemeng=sgs.CreateTriggerSkillV2{
    name="diyba_xiemeng",events={sgs.TargetConfirming},
    can_trigger=function(self,event,room,player,data)
        local use=data:toCardUse()
        if use.card:isNDTrick() and use.to:length()==1 and use.to:first()==player
            and not diyba_xiemengTargets(player,use):isEmpty() then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local targets=diyba_xiemengTargets(player,ctx.original_data:toCardUse())
        if targets:isEmpty() then return false end
        player:setTag("diyba_xiemeng_ai",ctx.original_data)
        local target=room:askForPlayerChosen(player,targets,self:objectName(),"@diyba-xiemeng",true,true)
        player:removeTag("diyba_xiemeng_ai")
        if not target then return false end
        ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local use=ctx.original_data:toCardUse();local target=ctx.targets:first()
        if target and target:isAlive() and diyba_xiemengTargets(player,use):contains(target) then
            local targets=sgs.SPlayerList();targets:append(target)
            for _,p in sgs.qlist(use.to) do targets:append(p) end
            use.to=targets;ctx.original_data:setValue(use)
        end
        return false
    end
}
local diyba_maliang=sgs.General(extension,"diyba_2j_maliang","shu",3)
diyba_maliang:setImage("maliang")
diyba_maliang:addSkill(diyba_lianman)
diyba_maliang:addSkill(diyba_xiemeng)
extension:insertRelatedSkills("diyba_lianman","#diyba_lianman_effect")
sgs.LoadTranslationTable{
    ["diyba_2j_maliang"]="马良",["&diyba_2j_maliang"]="马良",["#diyba_2j_maliang"]="白眉最良·3D二将SP",
    ["designer:diyba_2j_maliang"]="灭鼠灵大人",
    ["diyba_lianman"]="联蛮",[":diyba_lianman"]="每当一张锦囊牌指定了一名以上的角色为目标时，你可指定其中一名目标角色，并选择其中一项：1.令其摸一张牌并额外进行一次结算 2.令其弃置一张牌并跳过结算",
    ["diyba_xiemeng"]="协盟",[":diyba_xiemeng"]="每当你成为一张非延时性锦囊牌的唯一目标时，你可指定一名其他角色为目标之一，且该角色优先进行结算",
    ["@diyba-lianman"]="联蛮：选择一名锦囊目标，或取消",
    ["@diyba-xiemeng"]="协盟：增加一名优先结算的目标，或取消",
    ["diyba_lianman_draw"]="摸一张牌，额外结算一次",["diyba_lianman_skip"]="弃置一张牌，跳过结算",
}

-- 3D10J 薛灵芸：弃牌批次由全局规则记录，技能失效不撤销已接受的回合效果。
local function diyba_anzhiBlack(room)
    local latest,black=0,false
    for _,id in sgs.qlist(room:getDiscardPile()) do
        local batch=room:getTag("diyba_anzhi_batch_"..id):toInt()
        if batch>latest then latest=batch;black=false end
        if batch==latest and sgs.Sanguosha:getCard(id):isBlack() then black=true end
    end
    -- 上面的遍历会在遇到较新批次时重置，顺序不限。
    return black
end
local diyba_lianer=sgs.CreateTriggerSkillV2{
    name="diyba_lianer",events={sgs.CardFinished},
    can_trigger=function(self,event,room,player,data)
        local card=data:toCardUse().card
        if card and card:isRed() and not card:isKindOf("SkillCard") and not diyba_materials(card):isEmpty() then
            return own(self,event,room,player,data)
        end
        return ""
    end,
    on_cost=invoke,
    on_effect=function(self,event,room,player,ctx)
        local card=ctx.original_data:toCardUse().card
        local number=card:getNumber()
        local ids=diyba_materials(card)
        local dummy=sgs.DummyCard();dummy:addSubcards(ids)
        room:obtainCard(player,dummy,self:objectName(),true);dummy:deleteLater()
        if player:isAlive() then
            -- 每次限制均持续本回合，交集自然保留其中最严格的上界。
            room:setPlayerCardLimitation(player,"use",".|.|"..number.."~13",true,self:objectName())
        end
        return false
    end
}
local diyba_anzhi=sgs.CreateTriggerSkillV2{
    name="diyba_anzhi",events={sgs.TurnStart},
    can_trigger=function(self,event,room,player,data)
        if diyba_anzhiBlack(room) then return owners(self,room) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local target=room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"@diyba-anzhi",true,true)
        if not target then return false end
        ctx.targets:append(target);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first()
        if target and target:isAlive() then room:setPlayerMark(target,"&diyba_anzhi-Clear",1) end
        return false
    end
}
local diyba_anzhi_rule=sgs.CreateRuleSkillV2{
    name="#diyba_anzhi_rule",events={sgs.CardsMoveOneTime,sgs.TargetConfirming},
    on_record=function(self,event,room,player,ctx)
        local data=ctx.original_data
        if event==sgs.CardsMoveOneTime then
            local move=data:toMoveOneTime()
            if move.to_place~=sgs.Player_DiscardPile or move.card_ids:isEmpty() then return end
            local batch=room:getTag("diyba_anzhi_batch"):toInt()+1
            room:setTag("diyba_anzhi_batch",sgs.QVariant(batch))
            for _,id in sgs.qlist(move.card_ids) do room:setTag("diyba_anzhi_batch_"..id,sgs.QVariant(batch)) end
        elseif player and player:getMark("&diyba_anzhi-Clear")>0 then
            local use=data:toCardUse()
            if use.card:isBlack() and use.to:contains(player) then
                room:setPlayerMark(player,"&diyba_anzhi-Clear",0)
                local nullified=use.nullified_list
                if not table.contains(nullified,player:objectName()) then
                    table.insert(nullified,player:objectName());use.nullified_list=nullified;data:setValue(use)
                end
            end
        end
    end
}
addToSkills(diyba_anzhi_rule)
local diyba_xuelingyun=sgs.General(extension,"diyba_10j_xuelingyun","wei",3,false)
diyba_xuelingyun:setImage("xuelingyun")
diyba_xuelingyun:addSkill(diyba_lianer)
diyba_xuelingyun:addSkill(diyba_anzhi)
extension:insertRelatedSkills("diyba_anzhi","#diyba_anzhi_rule")
sgs.LoadTranslationTable{
    ["diyba_10j_xuelingyun"]="薛灵芸",["&diyba_10j_xuelingyun"]="薛灵芸",["#diyba_10j_xuelingyun"]="玉壶垂霞泪·3D十将",
    ["designer:diyba_10j_xuelingyun"]="GENTOVA07",
    ["diyba_lianer"]="涟洏",[":diyba_lianer"]="当你使用红色牌后，你可以获得之，然后你只能使用点数小于此牌的牌直到回合结束。",
    ["diyba_anzhi"]="暗织",[":diyba_anzhi"]="一名角色的回合开始时，若最近进入并在弃牌堆的牌包含黑色，你可以指定一名角色，此回合其第一次成为黑色牌的目标时，此牌对其无效。",
    ["@diyba-anzhi"]="暗织：选择一名角色，令本回合首张以其为目标的黑色牌对其无效",
}

-- 3D12J 孙和：回合内/外轮次配额独立；临时命也按授予的实例精确移除。
local function diyba_isSunhe(player)
    return player:getGeneralName()=="diyba_12j_sunhe" or player:getGeneral2Name()=="diyba_12j_sunhe"
end
local function diyba_mingyeSlot(room,player)
    return room:getCurrent()==player and player:getPhase()~=sgs.Player_NotActive and "inside" or "outside"
end
local function diyba_mingyeCard(event,data)
    if event==sgs.CardUsed then return data:toCardUse().card end
    local response=data:toCardResponse()
    if response.m_isUse then return response.m_card end
end
local diyba_mingye=sgs.CreateTriggerSkillV2{
    name="diyba_mingye",frequency=sgs.Skill_Compulsory,events={sgs.CardUsed,sgs.CardResponded},
    can_trigger=function(self,event,room,player,data)
        local card=diyba_mingyeCard(event,data)
        if card and (card:isKindOf("BasicCard") or card:isNDTrick()) then return own(self,event,room,player,data) end
        return ""
    end,
    on_cost=function(self,event,room,player,ctx)
        local slot=diyba_mingyeSlot(room,player)
        local round=tostring(room:historyScopes().round_id)
        if state(player,ctx:getActivationRef(),slot):toString()==round then return false end
        ctx.choice=slot;ctx.extra_data=sgs.QVariant(round);return true
    end,
    on_pay=function(self,event,room,player,ctx)
        -- Consume before drawing/healing can cause a nested use of a basic card.
        setstate(player,ctx:getActivationRef(),ctx.choice,ctx.extra_data:toString())
        return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local card=diyba_mingyeCard(event,ctx.original_data)
        if not card then return false end
        if event==sgs.CardUsed then
            local use=ctx.original_data:toCardUse()
            local nullified=use.nullified_list
            if not table.contains(nullified,"_ALL_TARGETS") then table.insert(nullified,"_ALL_TARGETS") end
            use.nullified_list=nullified
            if use.m_addHistory then
                room:addPlayerHistory(player,card:getClassName(),-1)
                use.m_addHistory=false
            end
            ctx.original_data:setValue(use)
        else
            local response=ctx.original_data:toCardResponse()
            response.nullified=true;ctx.original_data:setValue(response)
        end
        player:drawCards(2,self:objectName())
        if player:isAlive() then
            if diyba_isSunhe(player) then
                if player:isWounded() and room:askForCard(player,".|heart", "@diyba-mingye-heal",
                    ctx.original_data,sgs.Card_MethodDiscard) then
                    if player:isAlive() then room:recover(player,sgs.RecoverStruct(player,nil,1)) end
                end
            else
                local candidates=sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do if diyba_isSunhe(p) then candidates:append(p) end end
                local target
                if not candidates:isEmpty() then
                    target=room:askForPlayerChosen(player,candidates,self:objectName(),"@diyba-mingye-give",true,true)
                end
                if target and target:isAlive() then
                    local ids=card:isVirtualCard() and card:getSubcards() or sgs.IntList()
                    if not card:isVirtualCard() then ids:append(card:getEffectiveId()) end
                    local available=sgs.IntList()
                    for _,id in sgs.qlist(ids) do
                        if room:getCardPlace(id)==sgs.Player_PlaceTable then available:append(id) end
                    end
                    if not available:isEmpty() then
                        local dummy=sgs.DummyCard();dummy:addSubcards(available)
                        room:obtainCard(target,dummy,self:objectName(),true);dummy:deleteLater()
                    end
                end
            end
        end
        -- CardUsed stops before GameRule's normal card effects; CardFinished and
        -- native table cleanup still run. Response-use cancellation uses nullified.
        return event==sgs.CardUsed
    end
}
local diyba_danghu=sgs.CreateTriggerSkillV2{
    name="diyba_danghu",events={sgs.HpChanged},limit_scope=sgs.Skill_Limit_Round,max_usage_limit=1,
    can_trigger=own,
    on_cost=function(self,event,room,player,ctx)
        if not self:isUsable(ctx) then return false end
        local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@diyba-danghu",true,true)
        if not target then return false end
        ctx.targets:append(target);return true
    end,
    on_pay=function(self,event,room,player,ctx)
        if not self:isUsable(ctx) then return false end
        self:addUsage(ctx);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first()
        if not target or not target:isAlive() or target:hasSkill("diyba_mingye",true) then return false end
        local id=room:acquireSkill(target,"diyba_mingye")
        if id>0 then
            local grants=room:getTag("diyba_danghu_grants"):toString()
            local entry=target:objectName()..":"..id
            room:setTag("diyba_danghu_grants",sgs.QVariant(grants=="" and entry or grants.."|"..entry))
        end
        return false
    end
}
local diyba_danghu_rule=sgs.CreateRuleSkillV2{
    name="#diyba_danghu_rule",events={sgs.RoundEnd},
    on_record=function(self,event,room,player,ctx)
        local grants=room:getTag("diyba_danghu_grants"):toString()
        room:removeTag("diyba_danghu_grants")
        for name,id in string.gmatch(grants,"([^|:]+):(%d+)") do
            local target=room:findPlayerByObjectName(name,true)
            if target and target:hasSkillInstance("diyba_mingye",tonumber(id)) then
                room:detachSkillFromPlayer(target,"diyba_mingye#"..id)
            end
        end
    end
}
addToSkills(diyba_danghu_rule)
local diyba_sunhe=sgs.General(extension,"diyba_12j_sunhe","wu",3)
diyba_sunhe:setImage("sunhe")
diyba_sunhe:addSkill(diyba_mingye)
diyba_sunhe:addSkill(diyba_danghu)
extension:insertRelatedSkills("diyba_danghu","#diyba_danghu_rule")
sgs.LoadTranslationTable{
    ["diyba_12j_sunhe"]="孙和",["&diyba_12j_sunhe"]="孙和",["#diyba_12j_sunhe"]="季子绝途·3D十二将",
    ["designer:diyba_12j_sunhe"]="再見末日基因",
    ["diyba_mingye"]="命也",[":diyba_mingye"]="锁定技，回合内外每轮各限一次，你使用基本牌或普通锦囊牌时，你取消此牌，且令之不计限制次数，然后摸两张牌。若如此做，若你为孙和，则你可弃置一张红桃牌，回复1点体力；否则你可令孙和获得被取消的牌。",
    ["diyba_danghu"]="党乎",[":diyba_danghu"]="每轮限一次，你的体力值改变后，你可令一名其他角色于本轮中拥有“命也”。",
    ["@diyba-mingye-heal"]="命也：你可弃置一张红桃牌，回复1点体力",
    ["@diyba-mingye-give"]="命也：你可令一名孙和获得被取消的牌",
    ["@diyba-danghu"]="党乎：你可令一名其他角色于本轮内拥有命也",
}


-- 3D9J 濮阳兴。辛土用原实体牌，保留原牌目标规则与正常用牌流程。
local function diyba_xintuCompletion(room,player,card,selected)
    local list=sgs.PlayerList()
    for _,p in ipairs(selected) do list:append(p) end
    if #selected>0 and card:targetsFeasible(list,player) then return selected end
    if #selected>=room:alivePlayerCount() then return nil end
    for _,p in sgs.qlist(room:getAlivePlayers()) do
        if not table.contains(selected,p) and not player:isProhibited(p,card,list)
            and card:targetFilter(list,p,player) then
            local nextTargets={};for _,q in ipairs(selected) do table.insert(nextTargets,q) end
            table.insert(nextTargets,p)
            local result=diyba_xintuCompletion(room,player,card,nextTargets)
            if result then return result end
        end
    end
end
local function diyba_xintuLegal(room,player,card)
    if not player:isAlive() or not card:isAvailable(player) or player:isCardLimited(card,sgs.Card_MethodUse) then return nil end
    if card:targetFixed() then return {} end
    return diyba_xintuCompletion(room,player,card,{})
end
local diyba_xintu_use=sgs.CreateViewAsSkillV2{
    name="diyba_xintu_use",n=1,expand_pile="#diyba_xintu",
    can_activate=function(self,request)
        return request:getPattern()=="@@diyba_xintu_use" and request:getInitiator():getTag("diyba_xintu_id"):toInt()>0
    end,
    can_select_card=function(self,request,card)
        return request:getSelectedCardIds():isEmpty()
            and card:getEffectiveId()+1==request:getInitiator():getTag("diyba_xintu_id"):toInt()
    end,
    card_selection_feasible=function(self,request) return request:getSelectedCardIds():length()==1 end,
    cost=function(self,room,ctx,request)
        local id=request:getSelectedCardIds():first()
        return id+1==ctx.invoker:getTag("diyba_xintu_id"):toInt()
            and room:getCardPlace(id)==sgs.Player_PlaceTable
            and diyba_xintuLegal(room,ctx.invoker,sgs.Sanguosha:getCard(id))~=nil
    end,
    create_card=function(self,request)
        local ids=request:getSelectedCardIds()
        if ids:length()~=1 then return nil end
        return sgs.Sanguosha:getCard(ids:first())
    end
}
addToSkills(diyba_xintu_use)
local function diyba_xintuUse(room,player,id)
    local card=sgs.Sanguosha:getCard(id)
    if room:getCardPlace(id)~=sgs.Player_PlaceTable or not diyba_xintuLegal(room,player,card) then return false end
    local offered=sgs.IntList();offered:append(id)
    player:setTag("diyba_xintu_id",sgs.QVariant(id+1))
    room:notifyMoveToPile(player,offered,"diyba_xintu",sgs.Player_PlaceTable,true,true)
    local used=room:askForUseCardWithBorrowedSkill(player,"diyba_xintu_use","diyba_xintu","@diyba-xintu-use")
    room:notifyMoveToPile(player,offered,"diyba_xintu",sgs.Player_PlaceTable,false,true)
    player:removeTag("diyba_xintu_id")
    if used then return true end
    -- 锁定技不能跳过仍可合法使用的牌。每次选择只提供可完成原牌目标规则的候选。
    if room:getCardPlace(id)~=sgs.Player_PlaceTable then return false end
    local completion=diyba_xintuLegal(room,player,card)
    if not completion then return false end
    local selected={}
    if not card:targetFixed() then
        while true do
            local list=sgs.PlayerList();for _,p in ipairs(selected) do list:append(p) end
            if #selected>0 and card:targetsFeasible(list,player) then break end
            local candidates=sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if not table.contains(selected,p) and not player:isProhibited(p,card,list)
                    and card:targetFilter(list,p,player) then
                    local nextTargets={};for _,q in ipairs(selected) do table.insert(nextTargets,q) end
                    table.insert(nextTargets,p)
                    if diyba_xintuCompletion(room,player,card,nextTargets) then candidates:append(p) end
                end
            end
            if candidates:isEmpty() then return false end
            player:setTag("diyba_xintu_target_id",sgs.QVariant(id+1))
            local target=room:askForPlayerChosen(player,candidates,"diyba_xintu","@diyba-xintu-target",false)
            player:removeTag("diyba_xintu_target_id")
            if not target then return false end
            table.insert(selected,target)
        end
    end
    if not player:isAlive() or room:getCardPlace(id)~=sgs.Player_PlaceTable then return false end
    local use=sgs.CardUseStruct();use.card=card;use.from=player
    for _,p in ipairs(selected) do use.to:append(p) end
    return room:useCard(use,true)
end
local function diyba_xintuCleanup(room,player,ids)
    local offered=sgs.IntList()
    local id=player:getTag("diyba_xintu_id"):toInt()-1
    if id>=0 then
        offered:append(id)
        room:notifyMoveToPile(player,offered,"diyba_xintu",sgs.Player_PlaceTable,false,true)
    end
    player:removeTag("diyba_xintu_id");player:removeTag("diyba_xintu_target_id")
    local rest=sgs.DummyCard()
    for _,cid in sgs.qlist(ids) do if room:getCardPlace(cid)==sgs.Player_PlaceTable then rest:addSubcard(cid) end end
    if rest:subcardsLength()>0 then
        room:moveCardTo(rest,nil,nil,sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,player:objectName(),"diyba_xintu",""),true)
    end
    rest:deleteLater()
end
local diyba_xintu=sgs.CreateTriggerSkillV2{
    name="diyba_xintu",frequency=sgs.Skill_Compulsory,events={sgs.EventPhaseStart},
    can_trigger=function(self,event,room,player,data)
        if player and player:getPhase()==sgs.Player_Draw then return own(self,event,room,player,data) end
        return ""
    end,
    on_effect=function(self,event,room,player,ctx)
        local ids=room:getNCards(math.max(0,player:getMaxHp()))
        local saved={};for _,id in sgs.qlist(ids) do table.insert(saved,tostring(id)) end
        ctx.extra_data=sgs.QVariant(table.concat(saved,","))
        local dummy=sgs.DummyCard();dummy:addSubcards(ids)
        room:moveCardTo(dummy,nil,nil,sgs.Player_PlaceTable,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,player:objectName(),self:objectName(),""),true)
        dummy:deleteLater()
        local count=0
        for _,id in sgs.qlist(ids) do
            if not player:isAlive() then break end
            if diyba_xintuUse(room,player,id) then count=count+1 end
        end
        -- 不能使用或在中途死亡留下的牌正常进入弃牌堆，不收回牌堆。
        diyba_xintuCleanup(room,player,ids)
        ctx.extra_data=sgs.QVariant("")
        if player:isAlive() then
            if count>=player:getHp() and player:canDiscard(player,"e") then
                local id=room:askForCardChosen(player,player,"e",self:objectName(),false,sgs.Card_MethodDiscard)
                room:throwCard(id,player,player)
            end
            if player:isAlive() and count>player:getHp() then return true end
        end
        return false
    end,
    on_turn_broken=function(self,callback,event,room,player,ctx)
        local ids=sgs.IntList()
        for id in string.gmatch(ctx.extra_data:toString(),"%d+") do ids:append(tonumber(id)) end
        ctx.extra_data=sgs.QVariant("")
        diyba_xintuCleanup(room,player,ids)
    end
}
-- 下一次实际受伤先消耗所有已支付的预测，再执行回复；新发动不会被本次消费。
local diyba_sili_rule=sgs.CreateRuleSkillV2{
    name="#diyba_sili_rule",events={sgs.Damaged},priority=5,
    on_record=function(self,event,room,player,ctx)
        local damaged=ctx.original_data:toDamage().to
        if not damaged then return end
        local pending=room:getTag("diyba_sili_pending"):toString()
        room:removeTag("diyba_sili_pending")
        for name in string.gmatch(pending,"[^|]+") do
            if damaged:isAlive() and damaged:objectName()~=name then
                room:recover(damaged,sgs.RecoverStruct(nil,nil,1))
            end
        end
    end
}
addToSkills(diyba_sili_rule)
local diyba_sili=sgs.CreateTriggerSkillV2{
    name="diyba_sili",events={sgs.Damaged},limit_scope=sgs.Skill_Limit_Round,max_usage_limit=1,
    can_trigger=function(self,event,room,player,data)
        local damaged=data:toDamage().to
        if not damaged then return "" end
        local names,players={},{}
        for _,p in sgs.qlist(room:getOtherPlayers(damaged)) do
            if p:hasSkill(self:objectName()) then table.insert(names,self:objectName());table.insert(players,p:objectName()) end
        end
        return table.concat(names,"|"),table.concat(players,"|")
    end,
    on_cost=function(self,event,room,player,ctx)
        if not self:isUsable(ctx) then return false end
        local damaged=ctx.original_data:toDamage().to
        local candidates=sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do if p~=damaged then candidates:append(p) end end
        if candidates:isEmpty() then return false end
        local target=room:askForPlayerChosen(player,candidates,self:objectName(),"@diyba-sili",true,true)
        if not target then return false end
        ctx.targets:append(target);return true
    end,
    on_pay=function(self,event,room,player,ctx)
        if not self:isUsable(ctx) then return false end
        self:addUsage(ctx);return true
    end,
    on_effect=function(self,event,room,player,ctx)
        local target=ctx.targets:first()
        if not target then return false end
        local pending=room:getTag("diyba_sili_pending"):toString()
        room:setTag("diyba_sili_pending",sgs.QVariant(pending=="" and target:objectName() or pending.."|"..target:objectName()))
        return false
    end
}
local diyba_puyangxing=sgs.General(extension,"diyba_9j_puyangxing","wu",3)
diyba_puyangxing:setImage("puyangxing")
diyba_puyangxing:addSkill(diyba_sili)
diyba_puyangxing:addSkill(diyba_xintu)
extension:insertRelatedSkills("diyba_sili","#diyba_sili_rule")
extension:insertRelatedSkills("diyba_xintu","diyba_xintu_use")
sgs.LoadTranslationTable{
    ["diyba_9j_puyangxing"]="濮阳兴",["&diyba_9j_puyangxing"]="濮阳兴",["#diyba_9j_puyangxing"]="3D九将",
    ["designer:diyba_9j_puyangxing"]="龙哥头屑",
    ["diyba_sili"]="肆立",[":diyba_sili"]="每轮限一次，当其他角色受到伤害后，你可以指定另一名其他角色，若下一个受到伤害的角色不为你指定的角色，则该角色回复1点体力。",
    ["diyba_xintu"]="辛土",[":diyba_xintu"]="锁定技，摸牌阶段开始时，你展示牌堆顶X张牌并依次使用之（X为你的体力上限）。若你以此法使用的牌数：不小于你的体力值，弃置你装备区内一张牌；大于你的体力值，跳过你的摸牌阶段。",
    ["diyba_xintu_use"]="辛土用牌",["@diyba-xintu-use"]="辛土：使用展示的牌（可用的牌必须使用）",
    ["@diyba-xintu-target"]="辛土：选择此牌的合法目标",["@diyba-sili"]="肆立：指定下一名受到伤害的角色",
}

return {extension}
