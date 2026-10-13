-- Common speech is a pure strategy operation: it consumes this VM's decision
-- RNG and stages typed effects. Native publication happens only after commit.
local function speech_unknown(message)
    return ai_unsupported(message, "speech")
end
local function speech_policy(self)
    local policy = type(self.getResponsePolicy) == "function" and self:getResponsePolicy()
    if type(policy) ~= "table" then return speech_unknown("speech policy is not projected") end
    return policy
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function stage(self, effect)
    if self._strategy_evaluation then return end
    if self._event_effect_sink then return self:emitStrategyEffect(effect) end
    self._strategy_effects = self._strategy_effects or {}
    assert(#self._strategy_effects < 64, "strategy effect limit")
    effect.after_delta = 0
    self._strategy_effects[#self._strategy_effects + 1] = effect
end
function SmartAIView:getSpeechDelay()
    -- Without AI chat there is no speech to pace.
    if self.world and self.world.ai_chat_enabled == false then return 0 end
    local delay = speech_policy(self).origin_ai_delay
    if not finite(delay) then return speech_unknown("OriginAIDelay is unknown") end
    return delay
end
function SmartAIView:canSpeak(player)
    -- Donor AIChat(p) returns nil, not false, for a nonrobot. No-argument
    -- AIChat() has no viewer-state test and may enable another robot's speech.
    if player then
        local state = player:getState()
        if type(state) ~= "string" then return speech_unknown("speaker state is unknown") end
        if state ~= "robot" then return nil end
    end
    -- ai_chat_enabled already combines robot state, OriginAIDelay > 0 and AIHumanized.
    local enabled = self.world and self.world.ai_chat_enabled
    if type(enabled) ~= "boolean" then return speech_unknown("AI chat setting is unknown") end
    return enabled
end
function AIChat(player, ai)
    ai = ai or player and player._room and player._room._ai
    if not ai then return speech_unknown("AIChat needs a pure request context") end
    return ai:canSpeak(player)
end
function SmartAIView:stageSpeechDelay(milliseconds, source_key)
    if not finite(milliseconds) or type(source_key) ~= "string" then
        return speech_unknown("invalid speech delay")
    end
    stage(self, {kind="delay", milliseconds=milliseconds, source_key=source_key})
end
function SmartAIView:emitSpeechLine(player, text, source_key)
    if type(text) ~= "string" or type(source_key) ~= "string" then
        return speech_unknown("invalid speech text or provenance")
    end
    local name = type(player) == "string" and player or player and player:objectName()
    if type(name) ~= "string" or not self.room:findPlayerByObjectName(name, true) then
        return speech_unknown("speech player is not in the current roster")
    end
    stage(self, {kind="speech", player=name, text=text, source_key=source_key})
end
function SmartAIView:setPersonalityTarget()
    stage(self, {kind="personality_target", player=self.player:objectName()})
end
function SmartAIView:speak(cardtype, isFemale)
    if not self:canSpeak(self.player) then return end
    local ac = sgs.ai_chat[cardtype]
    if type(ac) == "function" then
        -- Function callbacks' return values are deliberately ignored by SmartAI.
        local previous = self._speech_source_key
        self._speech_source_key = "speak:" .. tostring(cardtype)
        local ok, err = pcall(ac, self)
        self._speech_source_key = previous
        if not ok then error(err, 0) end
    elseif type(ac) == "table" then
        if isFemale then ac = sgs.ai_chat[cardtype .. "_female"] or ac end
        local phase = self.player:getPhase()
        if not finite(phase) or type(sgs.Player_Play) ~= "number" then
            return speech_unknown("speaker phase is unknown")
        end
        local delay, key = self:getSpeechDelay(), "speak:" .. cardtype
        if phase <= sgs.Player_Play then
            -- Keep the donor's bounds unchanged: odd delay values have the
            -- same nonintegral math.random error, never a rounded alternative.
            self:stageSpeechDelay(math.random(delay * 0.5, delay * 1.5), key)
        else
            local dying = self.player:hasFlag("Global_Dying")
            if type(dying) ~= "boolean" then return speech_unknown("speaker dying flag is unknown") end
            if dying then self:stageSpeechDelay(math.random(delay, delay * 2), key) end
        end
        self:emitSpeechLine(self.player, ac[math.random(1, #ac)], key)
        return true
    end
end

-- Fixed public common lines from the pinned chat-ai.lua. These are policy
-- constants, never another player's private AI memory or a live legacy call.
sgs.ai_chat = sgs.ai_chat or {}
sgs.ai_chat.blade={
	"这把刀就是我爷爷传下来的，上斩逗比，下斩傻逼！",
	"尚方宝刀，专戳贱逼!"
}

sgs.ai_chat.eight_diagram = {
	"八卦阵",
	"防御神器",
	"有八卦，不慌"
}

sgs.ai_chat.kylin_bow = {
	"麒麟弓",
	"废马神器",
	"专业拆马",
	"马克星"
}

sgs.ai_chat.spear = {
	"丈八蛇矛",
	"化牌为杀",
	"这下不缺杀了"
}

sgs.ai_chat.no_peach_female = {
	"妾身不玩了！",
	"哇啊欺负我，不玩了" ,
	"放下俗物，飘飘升仙" ,
	"你们好意思欺负我一个女孩子吗....",
	"哼，本姑娘不伺候了"
}

sgs.ai_chat.no_peach = {
	"yoooo少年，不溜等什么",
	"摆烂.....",
	"看我主动走小道",
	"不挣扎了",
	"有桃不吃，先走了",
	"开下一局，走了",
	"围观我？我直接超脱",
	"投个降先"
}

sgs.ai_chat.yiji={
	"再用力一点",
	"再来再来",
	"要死了啊!"
}

sgs.ai_chat.null_card={
	"想卖血？",
	"我不想让你受伤！",
	"我不喜欢你扣血.....",
	"没事掉什么血啊",
	"我来保护你！！",
	"你这血我扣下了",
	"你不能受到1点伤害",
	"只有我可怜你哦~~~",
	"精血很贵的，还是留着吧",
	"看，只有我在意你，不让你受伤",
	"哼哼!"
}

sgs.ai_chat.snatch_female = {
	"啧啧啧，来帮你解决点牌吧",
	"叫你欺负人!" ,
	"看你就不是好人",
	"你留着牌就是祸害"
}

sgs.ai_chat.snatch = {
	"yoooo少年，不来一发么",
	"果然还是看你不爽",
	"你的牌太多辣",
	"摸你一下看看",
	"我看你霸气外露，不可不防啊"
}

sgs.ai_chat.dismantlement_female = sgs.ai_chat.snatch_female

sgs.ai_chat.dismantlement = sgs.ai_chat.snatch

sgs.ai_chat.dismantlement_female = sgs.ai_chat.snatch_female

sgs.ai_chat.zhujinqiyuan = sgs.ai_chat.snatch

sgs.ai_chat.zhujinqiyuan_female = sgs.ai_chat.snatch_female

sgs.ai_chat.duel_female={
	"不要拒绝哦",
	"小女子我也要亲自上场了",
	"哼哼哼，怕了吧",
	"决斗什么的最讨厌了",
}

sgs.ai_chat.duel={
	"不要回避！",
	"来直面挑战吧！",
	"哈哈哈，我的杀一定比你多！",
	"来吧！像个勇士一样决斗吧！",
	"来就来，谁怕谁",
	"手里一大把杀",
}

sgs.ai_chat.ex_nihilo={
	"哎哟运气好",
	"手气不错",
	"无中复无中！？",
	"抽个大牌",
	"哈哈哈哈哈"
}

sgs.ai_chat.dongzhuxianji = sgs.ai_chat.ex_nihilo

sgs.ai_chat.collateral_female={
	"将军，帮帮妾身吧",
	"就替妾身手刃他吧",
	"这人欺负我，打他"
}

sgs.ai_chat.collateral={
	"你的刀，就是我的刀",
	"你的剑，就是我的剑！",
	"替我————杀了他",
	"借汝之刀一用！"
}

sgs.ai_chat.amazing_grace_female={
	"让我看看，有什么好东西呢",
	"人人有份哟",
	"风调雨顺，五谷丰登",
	"丰收喽~~~~"
}

sgs.ai_chat.amazing_grace={
	"开仓，放粮！",
	"俺颇有家资",
	"一人一口，分而食之",
	"来分牌喽！"
}

sgs.ai_chat.supply_shortage={
	"嘻嘻，不给你摸",
	"你最好不是摸牌白",
	"看我断你口粮",
	"做个饿死鬼去吧！"
}

sgs.ai_chat.lightningIsGood={
	"躲过去了",
	"没劈到我",
	"虚惊一场",
	"好险",
	"天佑我也"
}

sgs.ai_chat.supply_shortageIsGood={
	"果然要天过",
	"嚯~~~~",
	"天可怜见",
	"哈哈哈哈哈哈哈哈哈",
	"废兵也就这样了"
}

sgs.ai_chat.collateralNoslash_female={
	"将军，妾身帮不了你",
	"要杀没有，这刀本宫赏给你了",
	"无杀，给你，哼"
}

sgs.ai_chat.collateralNoslash={
	"赏你了，还不快快跪谢！",
	"手残了，无法助你一臂之力",
	"孙子欸，敢收我的刀！",
	"我的趁手宝刀.....",
	"我帮不了你",
	"汝妹啊，吾刀！"
}

sgs.ai_chat.jijiang_female={
	"别指望下次我会帮你哦",
	"只是杀多了，消耗一点"
}

sgs.ai_chat.jijiang={
	"主公，我来啦",
	"我为主公出个力！"
}

sgs.ai_chat.eight_diagramIsGood={
	"哈哈，打不中",
	"八卦闪~！",
	"判红",
	"红色！！！"
}

sgs.ai_chat.judgeIsGood={
	"献祭GK木琴换来的",
	"这就是天意",
	"天助我，宵小不足为惧",
	"好判定",
	"判得好",
	"此天命不可违也，哈哈哈哈",
	"好耶!"
}

sgs.ai_chat.noJink={
	"有桃么!有桃么？",
	".......！",
	"我大意了",
	"要死",
	"没闪了",
	"完了",
	"挡不住了",
	"这下惨了"
}

sgs.ai_chat.noJink_female={
	"救命啊！",
	"妾身挡不住了",
	"完了完了",
	"没闪了呀",
	"不要啊"
}

sgs.ai_chat.kurou={
	"有桃么!有桃么？",
	"教练，我想要摸桃",
	"桃桃桃我的桃呢",
	"求桃求连弩各种求",
	"自己打自己",
	"苦肉计",
	"为了胜利，忍了",
	"痛并快乐着"
}

sgs.ai_chat.indulgence={
	"乐",
	"哈哈哈，乐",
	"五方诸神，此乐必中，急急如律令！",
	"你小子，就空过一回吧",
	"耶稣佛祖，不要天过",
	"此乐加之于你，定可一战而擒",
	"妖孽，看我封印你！",
	"关你禁闭！",
	"随机选择一位小盆友"
}

sgs.ai_chat.indulgence_female={
	"要懂得劳逸结合啊~~",
	"不要拒接妾身哦",
	"自娱自乐去吧",
	"休息一下吧"
}

sgs.ai_chat.indulgenceIsGood={
	"哈哈哈，乐不中",
	"信吾者，可上天国",
	"哟，天过",
	"我果然天眷者",
	"呀~~居然是假乐",
	"虚惊一场",
	"果然！",
	"此天助我也！"
}

sgs.ai_chat.supply_shortageIsBad = {
	"糟了，真的断粮了",
	"这下没得摸了",
	"完蛋，黑桃",
	"兵粮寸断",
	"我的摸牌啊"
}

sgs.ai_chat.indulgenceIsBad = {
	"真的乐了",
	"空过了",
	"这回合白给",
	"什么都干不了",
	"我太难了"
}

sgs.ai_chat.indulgenceIsBad_female = {
	"真的要休息了",
	"妾身动不了了",
	"乐不思蜀",
	"呜呜呜"
}

sgs.ai_chat.quhu={
	"出大的！",
	"来来来拼点了",
	"我要打虎了",
	"我又要打虎了",
	"谁会是狼呢？",
	"哟，拼点吧"
}

sgs.ai_chat.luoyi={
	"不脱光衣服干不过你",
	"裸衣上阵！",
	"脱了！",
	"看我真正的实力",
	"认真模式"
}

sgs.ai_chat.guanxing = {
	"观星象，知天命",
	"让我算算",
	"天机不可泄露",
	"卜算一番",
	"天象如此..."
}

sgs.ai_chat.bianshi = {
	"据我观察现在可以鞭尸",
	"鞭他，最后一下留给我",
	"我要刷战功，这个人头是我的",
	"这个可以鞭尸",
	"啊笑死"
}

sgs.ai_chat.bianshi_female = {
	"对面是个美女你们慢点",
	"人人有份，永不落空",
	"美人，来香一个"
}

sgs.ai_chat.continuous_slash = {
	"是兄弟就来砍我啊",
	"还来？没完了是吧",
	"我招你惹你了？",
	"针对我是吧？",
	"能不能换个人杀啊",
	"你是有多恨我啊",
	"有完没完啊？",
	"轮流来行不行",
	"你小子，别太过分"
}

sgs.ai_chat.continuous_slash_female = {
	"你就欺负我一个女孩子",
	"怎么老是打我",
	"男人都是大猪蹄子",
	"你好意思吗",
	"换个人打好不好",
	"过分了啊"
}

sgs.ai_chat.multi_jink = {
	"闪~闪~又闪~",
	"都打不中，菜",
	"你行不行啊",
	"手残了吧",
	"哈哈哈都闪掉了",
	"闪避大师就是我",
	"我看你是在给我挠痒痒"
}

sgs.ai_chat.low_hp_kill = {
	"反杀！",
	"还有这种操作？",
	"哈哈，没想到吧",
	"绝地反击！",
	"我还没倒下！",
	"越残越强！",
	"别小看我",
	"最后的荣光"
}

sgs.ai_chat.low_hp_kill_female = {
	"本宫不是好欺负的",
	"看本姑娘的厉害",
	"谁说女子不如男",
	"反杀成功！",
	"哼，大意了吧"
}

sgs.ai_chat.game_start = {
	"开始了开始了",
	"让我看看什么身份",
	"这局好好打",
	"准备就绪",
	"来吧",
	"出发！"
}

sgs.ai_chat.turn_start = {
	"轮到我了",
	"我的回合",
	"看我表演",
	"该我了",
	"Draw！"
}

sgs.ai_chat.turn_start_female = {
	"轮到我啰",
	"我的回合呢",
	"看我表现吧",
	"该我上场了",
	"抽牌！"
}

sgs.ai_chat.turn_end = {
	"结束了",
	"过了",
	"下一位",
	"完事",
	"你的回合"
}

sgs.ai_chat.turn_end_female = {
	"我这边结束啰",
	"轮到你啦",
	"该你上场了",
	"我先收手啦",
	"就到这里，换你"
}

sgs.ai_chat.become_lord = {
	"主公之位，舍我其谁",
	"众卿平身",
	"朕即国家",
	"效忠于我吧",
	"替朕守好江山"
}

sgs.ai_chat.full_hand = {
	"牌太多了",
	"手牌爆炸",
	"选择困难症犯了",
	"不知道出哪张",
	"资源丰富",
	"牌多任性"
}

sgs.ai_chat.god_equip = {
	"神装到手",
	"装备齐全了",
	"这波装备可以",
	"满配了兄弟们",
	"全副武装",
	"来战！"
}

sgs.ai_chat.lord_in_danger = {
	"主公危险！",
	"护驾！",
	"保护主公",
	"主公小心",
	"忠臣何在",
	"速速救驾"
}

sgs.ai_chat.equip_removed = {
	"我的装备！",
	"还我宝贝",
	"你给我等着",
	"君子动口不动手啊",
	"我记住你了",
	"卑鄙！无耻！下流！"
}

sgs.ai_chat.equip_removed_female = {
	"你抢女孩子东西算什么本事",
	"还我！",
	"我的宝贝装备",
	"你好坏哦",
	"欺负人！"
}

sgs.ai_chat.discard_many = {
	"弃这么多",
	"手牌太多了",
	"弃弃弃",
	"牌多的烦恼",
	"选择困难"
}


local function speech_known(value, label)
    if value == nil then return speech_unknown(label .. " is unknown") end
    return value
end
local function speech_friends_noself(self)
    local result = {}
    for _, p in ipairs(speech_known(self:getFriends(), "speech friends")) do
        if p ~= self.player then result[#result+1] = p end
    end
    return result
end
local function speech_roles(self)
    return speech_known(self:getRoleCounts(), "speech role counts")
end
local function speech_role(self, name)
    local player = self.room:findPlayerByObjectName(name, true)
    return speech_known(self:getRoleEstimate(speech_known(player, "speech role player")), "speech role estimate")
end
local function speech_time(self)
    return speech_unknown("the source wall clock is not available")
end
local function speech_pattern_log_name(pattern)
    return speech_unknown("pattern log names are not projected")
end
local function speech_event_data(self, event)
    local details = event.details or {}
    local function player(name)
        if name == nil or name == "" then return nil end
        return speech_known(self.room:findPlayerByObjectName(name, true), "speech event player")
    end
    local function card(row)
        if row == nil then return nil end
        return type(row.isKindOf) == "function" and row or CardView.new(row)
    end
    local function damage()
        return {from=player(event.from),to=player(event.to),card=card(details.card),
            damage=event.amount,nature=event.nature,chain=event.chain,transfer=event.transfer}
    end
    return {
        toDamage=function() return damage() end,
        toDeath=function()
            local present = speech_known(details.damage_present, "death damage presence")
            return {who=player(event.to),damage=present and damage() or nil}
        end,
        toDying=function() return {who=player(event.to)} end,
        toCardUse=function()
            local targets = AIList.new({})
            for _, name in ipairs(speech_known(event.targets, "speech card-use targets")) do targets:append(player(name)) end
            return {from=player(event.from),to=targets,card=speech_known(card(details.card), "speech used card")}
        end,
        toCardEffect=function()return {from=player(event.from),to=player(event.to),card=card(details.card)}end,
        toJudge=function()
            local raw = speech_known(details.judge, "speech judgment")
            local good = speech_known(raw.good, "speech judgment result")
            return {who=player(raw.who),reason=raw.reason,pattern=raw.pattern,good=good,card=card(raw.card),
                isGood=function()return good end,isBad=function()return not good end}
        end,
        toDraw=function()return speech_known(details.draw, "speech draw event")end,
        toMoveOneTime=function()
            local raw = speech_known(details.move, "speech move event")
            local places, ids, cards = AIList.new({}), AIList.new({}), {}
            for i,row in ipairs(speech_known(raw.cards, "speech move rows")) do
                places:append(speech_known(row.from_place, "speech move source place"))
                -- Hidden rows keep only a positional placeholder. Equip-removal
                -- consumers can request a CardView only for a disclosed row.
                ids:append(i)
                cards[i] = card(row.card)
            end
            return {from=player(raw.from),to=player(raw.to),to_place=raw.to_place,
                from_places=places,card_ids=ids,cards=cards}
        end
    }
end
function SmartAIView:getSpeechCounter(player, name)
    -- Chat counters are this observer's own bookkeeping.
    local counters = self:getStrategyMemory("speech_counters") or {}
    local row = counters[player:objectName()]
    local value = row and row[name] or 0
    if not finite(value) or value < 0 or value % 1 ~= 0 then return speech_unknown("invalid speech counter") end
    return value
end
function SmartAIView:setSpeechCounter(player, name, value)
    local source = self._speech_source_key
    local valid = name == "jink_count-Clear" and source == "chat:CardOffset:multi_jink"
        or name:match("^continuous_slash_count.+%-Clear$") and source == "chat:TargetSpecified:continuous_slash"
    if not valid or not finite(value) or value < 0 or value % 1 ~= 0 then return speech_unknown("invalid speech counter write") end
    local counters = self:getStrategyMemory("speech_counters") or {}
    local actor = player:objectName()
    counters[actor] = counters[actor] or {}
    counters[actor][name] = value
    self:setStrategyMemory("speech_counters", counters)
    stage(self,{kind="speech_counter",player=actor,name=name,value=value,source_key=source})
end
function SmartAIView:addSpeechCounter(player, name)
    return self:setSpeechCounter(player,name,self:getSpeechCounter(player,name)+1)
end
-- Only errors proven in the pinned common donor are absorbed at its callback
-- pcall boundary. Missing projection, resource limits, and new bugs still abort.
local missing_defense_speaker = {}
local delayed_callbacks = {
    ["chat:GameStart:greeting"]=true, ["chat:GameStart:lord_identity"]=true,
    ["chat:EventPhaseStart:turn_start"]=true, ["chat:EventPhaseStart:turn_end"]=true,
    ["chat:FinishJudge:delayed_trick"]=true
}
local function donor_callback_error(self, source, err)
    if type(AIUnsupported) == "table" and type(AIUnsupported.is) == "function" and AIUnsupported.is(err) then return false end
    local code
    if source == "chat:EventPhaseStart:luanwu" and err == missing_defense_speaker then
        code = "undefined_defense_speaker"
    elseif delayed_callbacks[source] and type(err) == "string"
        and err:find("number has no integer representation",1,true)
        and self.player:getPhase() <= sgs.Player_Play then
        local delay = self:getSpeechDelay()
        if delay > 0 and delay % 1 == 0 and delay % 2 == 1 then code = "nonintegral_speech_delay_bound" end
    end
    if not code then return false end
    local errors = self:getStrategyMemory("donor_callback_errors") or {}
    errors[#errors+1] = {kind="donor_callback_error",source_key=source,code=code}
    if #errors > 16 then table.remove(errors,1) end
    self:setStrategyMemory("donor_callback_errors",errors)
    return true
end
local function register_speech_event(event_name, key, callback)
    local event_key = sgs[event_name] or event_name
    sgs.ai_event_callback = sgs.ai_event_callback or {}
    sgs.ai_event_callback[event_key] = sgs.ai_event_callback[event_key] or {}
    sgs.ai_event_callback[event_key][key] = function(self, player, event)
        -- RoomThread calls the target AI's filterEvent. Other observers still
        -- process intention/history, but must not duplicate public chat RNG.
        if not player or player:objectName() ~= self.player:objectName() then return end
        local source = "chat:" .. event_name .. ":" .. key
        local previous = self._speech_source_key
        self._speech_source_key = source
        local function say(speaker, text) self:emitSpeechLine(speaker,text,source) end
        local function chat(speaker) return self:canSpeak(speaker) end
        local ok, result = pcall(callback,self,player,speech_event_data(self,event),chat,say,event)
        self._speech_source_key = previous
        if not ok then
            if donor_callback_error(self,source,result) then return end
            error(result,0)
        end
        return result
    end
end

register_speech_event("Death", "stupid_lord", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	local damage=data:toDeath().damage
	local chat = {
		"2B了吧",
		"我那么忠诚，竟落得如此下场....",
		"我为主上出过力，呃啊.....",
		"主要臣死，臣不得不死",
		"昏君！",
		"还有更2的吗",
		"真的很无语"
	}
	if damage and damage.from and damage.from:isLord()
	and self.player:getRole()=="loyalist"and damage.to==player
	then say(damage.to,chat[math.random(1,#chat)]) end
end)

register_speech_event("Dying", "fuck_renegade", function(self,player,data,AIChat,say,event)
	local dying = data:toDying()
	if dying.who~=player or not AIChat(player) or math.random()>0.5
	or player:aliveCount()-#speech_known(self:getEnemies(), "speech enemies")<2 then return end
	local chat = {
		"999...999...",
		"来捞一下啊...."
	}
	if self.player:getRole()~="renegade" and speech_roles(self)["renegade"]>0 then
		table.insert(chat,"9啊，不9就输了")
		table.insert(chat,"小内你还不救，要崩盘了")
		table.insert(chat,"没戏了小内不出手全部托管吧")
		table.insert(chat,"小内，我死了你也赢不了")
	end
	if self:getAllPeachNum()+player:getHp()<1
	and #speech_friends_noself(self)>0 then
		table.insert(chat,"寄")
		table.insert(chat,"要寄.....")
		table.insert(chat,"还有救吗.....")
	end
	if #speech_known(self:getEnemies(), "speech enemies")<player:aliveCount()-1 then
		table.insert(chat,"不要见死不救啊.....")
		table.insert(chat,"我还不能死.....")
		table.insert(chat,"6了6了")
		table.insert(chat,"6")
	end
	say(player,chat[math.random(1,#chat)])
end)

register_speech_event("DamageForseen", "kylin_bow", function(self,player,data,AIChat,say,event)
	local damage = data:toDamage()
	if AIChat(player) and damage.card and damage.from
	and damage.card:isKindOf("Slash") and damage.from:hasWeapon("KylinBow")
	and (player:getOffensiveHorse() or player:getDefensiveHorse())
	and self:isEnemy(damage.from) and math.random()<0.6 then
		local chat = {
			"我靠，5弓",
			"敢杀我马？",
			"我的宝驹.....",
			"蛤！我的千里驹",
			"我马药丸...."
		}
		say(player,chat[math.random(1,#chat)])
	end
end)

register_speech_event("CardFinished", "analeptic", function(self,player,data,AIChat,say,event)
	if not AIChat() then return end
	local use = data:toCardUse()
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if math.random()>0.95 and p:getState()=="robot"
		then say(p,"<#"..math.random(1,56).."#>") end
	end
	if use.card:isKindOf("Analeptic") and player:getPhase()<=sgs.Player_Play
	and use.card:getSkillName()~="zhendu" then
		local chat = {
			"!",
			"不要吓我..."
		}
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if p:getState()=="robot" and not self:isFriend(p)
			and math.random()<0.3 then
				if p:getLostHp()<1 then
					table.insert(chat,"喜闻乐见")
					table.insert(chat,"我满血，不慌")
					table.insert(chat,"来呀，来砍我呀，我满血")
					table.insert(chat,"系兄弟就来啃我！")
				end
				if p:getHp()<3 and #speech_known(self:getEnemies(), "speech enemies")>1 then
					table.insert(chat,"队友呢，有桃没？")
					table.insert(chat,"有点慌，但有队友应该可以...")
				elseif p:getHp()>3 then
					table.insert(chat,"我血多，不怕")
					table.insert(chat,"绝对带不走")
					table.insert(chat,"我菊花一紧")
				end
				if p:getHandcardNum()>0 then
					table.insert(chat,"打不中的")
					table.insert(chat,"猜猜我有没有闪")
					table.insert(chat,"不要砍我，我有"..speech_pattern_log_name("jink"))
					table.insert(chat,"没闪，但是有"..speech_pattern_log_name("peach"))
				else
					if player:canSlash(p) then
						table.insert(chat,"敢不敢放过我")
						table.insert(chat,"空城..药丸...")
						table.insert(chat,"不要杀我，我给你钱（先打欠条）")
					else
						table.insert(chat,"我没牌，可惜了你")
						table.insert(chat,"哎呀，打不到，哈哈哈")
						table.insert(chat,"前排围观，出售爆米花，矿泉水，花生，瓜子...")
					end
				end
				say(p,chat[math.random(1,#chat)])
			end
		end
	elseif use.card:isKindOf("Crossbow") then
		local chat = {
			"你小子早该突突了！",
			"哒哒哒！",
			"杀！杀！杀！",
			"AK来了~~",
			"随机送走一位童鞋",
			"看我反手掏出这大家伙",
			"满手的杀哦",
			"可以开始突突了",
			"准备扫射"
		}
		if player:getState()=="robot"
		and (self:getCardsNum("Slash")>1 or math.random()<0.4 and player:getHandcardNum()>1)
		then say(player,chat[math.random(1,#chat)]) end
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if p:getState()=="robot" and math.random()<0.3
			and not self:isFriend(p,player) then
				chat = {"额，AK出现了","有点危险","得找机会拿过来","好家伙"}
				if player:canSlash(p) then
					if p:getLostHp()<1 then
						table.insert(chat,"我满血，不慌")
						table.insert(chat,"来呀，来砍我呀，我满血")
					end
					if getCardsNum("Slash",player,p)<1
					and player:getHandcardNum()<5 then
						table.insert(chat,"我赌你没有杀")
						table.insert(chat,"断杀，啊哈哈哈哈")
						table.insert(chat,"你这趁手的AK怎么没有弹药呢，哈哈哈")
					else
						table.insert(chat,"不要砍我....")
						table.insert(chat,"我是你队友，不要打错了")
						table.insert(chat,"其实我是他们的卧底")
						table.insert(chat,"我可以改邪归正，弃暗投明")
						table.insert(chat,"我愿归降，求您放过我...")
					end
				else
					table.insert(chat,"可惜够不着我呢~~~")
					table.insert(chat,"哎呀呀，距离不够，哈哈哈")
					table.insert(chat,"打不着~~打不着~~")
				end
				say(p,chat[math.random(1,#chat)])
			end
		end
	elseif use.card:isKindOf("Peach") then
		for _,p in sgs.qlist(use.to)do
			if p==use.from or p:getHp()<1
			or p:getState()~="robot" then continue end
			if use.from:isFemale() and math.random()<0.2
			and p:getGender()~=use.from:getGender()
			and use.from:getState()=="robot" then
				say(use.from,"复活吧，我的勇士")
				say(p,"为你而战，我的女王")
			elseif math.random()<0.5 then
				local chat = {
					"大人功德无量！",
					"杀不死的我，会更加强大！",
					"哼，我还是有队友的",
					"还好有队友",
					"救我苟命，不胜感激",
					"天命在我，不该绝矣",
					"哈哈，活了",
					"差点无了.....",
					"活下来了....",
					"谢了.....",
					"还好还好",
					"不好，这桃里有屎",
					"你往这里面掺了什么？"
				}
				say(p,chat[math.random(1,#chat)])
			end
		end
	elseif use.card:isKindOf("OffensiveHorse")
	and player:getState()=="robot" then
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if self:isEnemy(player,p) and player:distanceTo(p,1)==2 and math.random()<0.2
			then say(player,"妖人"..p:screenName().."你往哪里跑") return end
		end
	end
end)

register_speech_event("PreCardUsed", "CardUse", function(self,player,data,AIChat,say,event)
	local speech_queue = self:getStrategyMemory("speech_luanji")
	if not AIChat() then return end
	local use = data:toCardUse()
	if player:getState()=="robot" then
		local ac = sgs.ai_chat[use.card:objectName()]
		if player:isFemale() then ac = sgs.ai_chat[use.card:objectName().."_female"] or ac end
		if type(ac)=="table" and math.random()<0.6
		then say(player,ac[math.random(1,#ac)])
		elseif type(ac)=="function" then ac(self)
		elseif use.card:getSkillName():match("luanji") then
			if not speech_queue
			or #speech_queue<1 then
				speech_queue = {
					"此身，为剑所成",
					"血如钢铁，心似琉璃",
					"跨越无数战场而不败",
					"未尝一度被理解",
					"亦未尝一度有所得",
					"剑之丘上，剑手孤单一人，沉醉于辉煌的胜利",
					"铁匠孑然一身，执著于悠远的锻造",
					"因此，此生没有任何意义",
					"那么，此生无需任何意义",
					"这身体，注定由剑而成"
				}
			end
			say(player,speech_queue[1])
			table.remove(speech_queue,1)
            self:setStrategyMemory("speech_luanji", speech_queue)
		end
	end
	if use.card:isDamageCard()
	and use.to:length()>player:aliveCount()/2 then
		local chat = {
			"我靠，AOE",
			"喜闻乐见",
			"蛤！",
			"又是群攻",
			"躺枪",
			"能不能别搞AOE",
			"殃及池鱼"
		}
		self.aoeTos = use.to
		for _,p in sgs.qlist(self.room:getOtherPlayers(use.from))do
			if math.random()<0.8 or p:getState()~="robot" then continue end
			if use.to:contains(p) and self:aoeIsEffective(use.card,p,use.from) then
				if self:isWeak(p) or p:isKongcheng() then
					table.insert(chat,"不要哇")
					table.insert(chat,"不要收割我....")
					table.insert(chat,"有点慌")
				else
					table.insert(chat,"血多，不慌")
				end
				if use.from:usedTimes(use.card:getClassName())>1 then
					table.insert(chat,"哪来这么多AOE啊")
					table.insert(chat,"你特么....")
					table.insert(chat,"怎么还有....")
					table.insert(chat,"还来....")
				end
			else
				table.insert(chat,"呃哈哈")
				table.insert(chat,"此计伤不到我")
				table.insert(chat,"此小计尔")
				table.insert(chat,"哎呀打不动")
				table.insert(chat,"坐山观斗虎")
			end
			say(p,chat[math.random(1,#chat)])
		end
		self.aoeTos = nil
	elseif use.card:isKindOf("Slash") then
		local chat ={
			"您老悠着点儿阿",
			"泥玛杀我，你等着阿",
			"再杀！老子和你拼命了"
		}
		for _,p in sgs.qlist(use.to)do
			if math.random()>0.3 or p:getState()~="robot" then continue end
			if speech_role(self,p:objectName())=="neutral" then
				table.insert(chat,"盲狙一时爽啊,我泪奔")
				table.insert(chat,"我次奥，盲狙能不能轻点？")
				if use.from:usedTimes("Analeptic")>0 then
					table.insert(chat,"喝醉了吧，乱砍人？")
				end
			end
			if not p:isLord()
			and self:hasCrossbowEffect(use.from) then
				table.insert(chat,"杀得我也是醉了。。。")
				table.insert(chat,"果然是连弩降智商....")
				table.insert(chat,"杀死我也没牌拿，真2")
			end
			if use.from:isLord()
			and speech_roles(self).loyalist>0
			and speech_role(self,p:objectName())~="rebel" then
				table.insert(chat,"尼玛眼瞎啊，老子是忠！")
				table.insert(chat,"主公别打我，我是忠")
				table.insert(chat,"主公别开枪，自己人")
				table.insert(chat,"再杀我，你会裸")
			end
			say(p,chat[1+(speech_time(self)%#chat)])
		end
	end
end)

register_speech_event("EventPhaseStart", "luanwu", function(self,player,data,AIChat,say,event)
	if not AIChat() then return end
	if player:getPhase()==sgs.Player_Play and self.player:getMark("@chaos")>0
	and self.player:hasSkill("luanwu") then
		local chat = {
			"乱一个，乱一个",
			"要乱了",
			"要死....",
			"完了，没杀"
		}
		local chat1 = {
			"不要紧张",
			"乱世随时开始",
			"月黑风高夜，杀人放火时！",
			"准备好了吗？"
		}
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if p~=player and p:getState()=="robot" and math.random()<0.2
			then say(p,chat[math.random(1,#chat)])
			elseif p==player and p:getState()=="robot" and math.random()<0.1
			then say(p,chat1[math.random(1,#chat1)]) end
		end
	end
	if player:getState()~="robot" then return end
	local chat = {
		"有货，可以来搞一下",
		"有闪有黑桃",
		"看我眼色行事",
		"没闪,忠内不要乱来",
		"不爽，来啊！砍我啊",
		"求杀求砍求蹂躏",
		"我有闪我会到处乱说么？",
		"你觉得我有木有闪啊",
		"哈我有闪"
	}
	if player:getPhase()==sgs.Player_Finish and not player:isKongcheng()
	and player:hasSkills("leiji|nosleiji|olleiji") and speech_time(self)%10<4
	then say(player,chat[1+(speech_time(self)%#chat)]) end
	if player:getPhase()==sgs.Player_Start and math.random()<0.4
	and speech_roles(self)["renegade"]+speech_roles(self)["loyalist"]<1
	and speech_roles(self)["rebel"]>=2 then
		if self.player:getRole()=="rebel" then
			chat = {
				"大家一起围观主公",
				"不要一下弄死了，慢慢来",
				"主公投降吧，免受皮肉之苦",
				"速度，一人一下弄死",
				"怎么成光杆司令了啊",
				"哈哈哈主公阿",
				"包养主公了",
				"投降给全尸"
			}
		else
			if speech_known(self:getResponsePolicy().turn_count, "speech turn count")>4 then
				chat = {
					"看我一人包围你们全部......",
					"这就是所谓一人包围全场",
					"已经是最后的希望了",
					"最后的希望么？",
					"纵死，我亦无惧",
					"我要杀出重围",
					"我将不屈服",
					"（苦笑）",
					"哈哈哈，这是我最后的荣光了",
				}
			else
				chat = {
					"啊这",
					"怎么全都死了",
					"我竟进入如此境地",
					"看我一人包围你们全部......",
					"不好，被包围了",
					"不要轮我",
					"（苦笑）"
				}
			end
		end
		say(player,chat[math.random(1,#chat)])
	end
	if player:getPhase()==sgs.Player_RoundStart
	and self.room:getMode()=="08_defense"
	and math.random()<0.3 then
		local kingdom = self.player:getKingdom()
		local chat1 = {
			"无知小儿，报上名来，饶你不死！",
			"剑阁乃险要之地，诸位将军须得谨慎行事。",
			"但看后山火起，人马一齐杀出！"
		}
		local chat2 = {
			"嗷~！",
			"呜~！",
			"咕~！",
			"呱~！",
			"发动机已启动，随时可以出发——"
		}
		if kingdom=="shu" then
			table.insert(chat1,"人在塔在！")
			table.insert(chat1,"汉室存亡，在此一战！")
			table.insert(chat1,"星星之火，可以燎原")
			table.insert(chat2,"红色！")
		elseif kingdom=="wei" then
			table.insert(chat1,"众将官，剑阁去者！")
			table.insert(chat1,"此战若胜，大业必成！")
			table.insert(chat1,"一切反动派都是纸老虎")
			table.insert(chat2,"蓝色！")
		end
		if string.find(self.player:getGeneralName(),"baihu") then table.insert(chat2,"喵~！") end
		if string.find(self.player:getGeneralName(),"jiangwei") then  --姜维
			table.insert(chat1,"白水地狭路多，非征战之所，不如且退，去救剑阁")
			table.insert(chat1,"若剑阁一失，是绝路也。")
			table.insert(chat1,"今四面受敌，粮道不同，不如退守剑阁，再作良图。")
		elseif string.find(self.player:getGeneralName(),"dengai") then  --邓艾
			table.insert(chat1,"剑阁之守必还赴涪，则会方轨而进")
			table.insert(chat1,"剑阁之军不还，则应涪之兵寡矣")
			table.insert(chat1,"以愚意度之，可引一军从阴平小路出汉中德阳亭")
			table.insert(chat1,"用奇兵径取成都，姜维必撤兵来救，将军乘虚就取剑阁，可获全功")
		elseif string.find(self.player:getGeneralName(),"simayi") then  --司马懿
			table.insert(chat1,"吾前军不能独当孔明之众，而又分兵为前后，非胜算也")
			table.insert(chat1,"不如留兵守上邽，余众悉往祁山")
			table.insert(chat1,"蜀兵退去，险阻处必有埋伏，须十分仔细，方可追之。")
		elseif string.find(self.player:getGeneralName(),"zhugeliang") then --诸葛亮
			table.insert(chat1,"老臣受先帝厚恩，誓以死报")
			table.insert(chat1,"今若内有奸邪，臣安能讨贼乎？")
			table.insert(chat1,"吾伐中原，非一朝一夕之事")
			table.insert(chat1,"正当为此长久之计")
		end
        -- The donor dereferences an undefined global p before evaluating its
        -- random line argument. Preserve that exact draw boundary and its
        -- enclosing filterEvent callback-pcall behavior.
        error(missing_defense_speaker, 0)
	end
	if self:isRolePredictable() then
	elseif player:getPhase()==sgs.Player_RoundStart
	and math.random()<0.2 then
		local friend_name,enemy_name
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if self:isFriend(p) and math.random()<0.5 then friend_name = p:getLogName()
			elseif self:isEnemy(p) and math.random()<0.5 then enemy_name = p:getLogName() end
		end
		local chat1 = {
			"要记住该跳就跳，不要装身份",
			"装什么身份，跳啊",
			"到底谁是内啊？",
			"都在这装呢？",
			"还在这装呢",
		}
		local quick = {
			"都快点，我还要去吃饭呢",
			"都快点，打完这局我要去取快递",
			"都快点，我要去做面膜的",
			"都快点，打完这局我要去约会呢",
			"都快点，打完这局我要去跪搓衣板",
			"都快点，打完这局我要去混班了",
			"都快点，打完这局我要睡觉了",
			"都快点，打完这局我要去打代码",
			"都快点，打完这局我要去撸啊撸",
			"都快点，打完这局我要去打电动了",
			"都快点，我要开新局",
		}
		local role1 = {
			"孰忠孰反，吾早已明辨",
			"都是反，怎么打！",
			"别装了"
		}
		local role2 = {
			"当忠臣嘛，个人能力要强",
			"装个忠我容易嘛我",
			"这主坑内，跳反了",
			"这主坑内，投降算了",
		}
		local role3 = {
			"反贼都集火啊！集火！",
			"我们根本没有输出",
			"输出，加大输出啊！",
			"对这种阵容，我已经没有希望了",
		}
		chat = {}
		if friend_name then
			table.insert(role1,"忠臣"..friend_name.."，你是在坑我吗？")
			table.insert(role1,friend_name.."你不会是奸细吧？")
			table.insert(role1,friend_name.."表现得很可疑啊")
			table.insert(role1,"感觉"..friend_name.."有问题")
			table.insert(role1,"到底"..friend_name.."是哪边的")
		end
		if enemy_name then
			table.insert(chat1,enemy_name.."你小子怎么了啊")
			table.insert(chat1,"游戏可以输，你"..enemy_name.."必须死！")
			table.insert(chat1,enemy_name.."你这样坑队友，连我都看不下去了")
		end
		if math.random()<0.2 then
			table.insert(chat,quick[math.random(1,#quick)])
		end
		if math.random()<0.3 then
			table.insert(chat,chat1[math.random(1,#chat1)])
		end
		if player:isLord() then table.insert(chat,role1[math.random(1,#role1)])
		elseif speech_role(self,player:objectName())=="loyalist"
		or speech_role(self,player:objectName())=="renegade" and math.random()<0.2
		then table.insert(chat,role2[math.random(1,#role2)])
		elseif speech_role(self,player:objectName())=="rebel"
		or speech_role(self,player:objectName())=="renegade" and math.random()<0.2
		then table.insert(chat,role3[math.random(1,#role3)]) end
		if #chat>0 and speech_known(self:getResponsePolicy().turn_count, "speech turn count")>=2 then
			say(player,chat[math.random(1,#chat)])
		end
	end
	if player:getPhase()==sgs.Player_Play
	and player:hasSkill("jieyin") then
		chat = {
			"香香睡我",
			"香香救我",
			"香香，我快没命了"
		}
		local chat1 = {
			"牌不够啊",
			"哼，考虑考虑",
			"让我斟酌斟酌"
		}
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if p~=player and p:getState()=="robot" and self:isFriend(p)
			and p:isMale() and self:isWeak(p) then say(p,chat[math.random(1,#chat)])
			elseif p==player and p:getState()=="robot" and math.random()<0.1
			then say(p,chat1[math.random(1,#chat1)]) end
		end
	end
end)

register_speech_event("ChoiceMade", "state", function(self,player,data,AIChat,say,event)
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if math.random()>0.97 and AIChat(p)
		then say(p,"<#"..math.random(1,56).."#>") end
	end
end)

register_speech_event("DrawNCards", "screen", function(self,player,data,AIChat,say,event)
	local draw = data:toDraw()
	if draw.reason~="InitialHandCards" then return end
	local sn = player:screenName()
	if sn:match("神小杀")
	and AIChat(player) then
		local speaks = {
			sn.."准备就绪",
			sn.."随时可以开始",
			sn.."程序加载完成",
			sn.."准备好了",
			sn.."进入游戏成功"
		}
		say(player,speaks[math.random(1,#speaks)])
	end
end)

register_speech_event("StartJudge", "isBad", function(self,player,data,AIChat,say,event)
	local judge = data:toJudge()
	if judge:isBad() and math.random()<0.6 then
		local descriptor = speech_known(event.details.judge.reason_card, "judgment reason card classification")
        local dc = descriptor ~= false and CardView.new(descriptor) or nil
		if not(dc and dc:isDamageCard()) then return end
		local chat = {
			"我靠，天谴之子",
			"竞是如此",
			"蛤！炸了",
			"劈哩批哩喽",
		}
		if player:getKingdom()=="wei" then
			table.insert(chat,"大魏招雷术")
			table.insert(chat,"大魏引雷法")
			table.insert(chat,"这就是大魏")
		end
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if math.random()>0.77 and AIChat(p) then
				if self:isFriend(p,player) then
					table.insert(chat,"不可能！")
					table.insert(chat,"不可以！")
					table.insert(chat,"那种事情不要啊.....")
					if #speech_friends_noself(self)>0 then
						table.insert(chat,"有改判的吗.....")
						table.insert(chat,"判官，我要重新裁决.....")
					end
				else
					table.insert(chat,"该！")
					table.insert(chat,"哦嚯")
					table.insert(chat,"早该劈劈了")
					table.insert(chat,"一次不够，下次我也放雷")
					table.insert(chat,"你小子做了什么伤天害理之事啊")
					table.insert(chat,"这就是天弃之子")
				end
				say(p,chat[math.random(1,#chat)])
			end
		end
	end
end)

register_speech_event("FinishJudge", "delayed_trick", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	local judge = data:toJudge()
	if player:getState() ~= "robot" or math.random() > 0.4 then return end
	if judge:isBad() and math.random()<0.4 then
		if self:speak(judge.reason.."IsBad", player:isFemale()) or judge.pattern=="."
		or math.random()<0.4 then return end
		self:speak("judgeIsBad")
	end
end)

register_speech_event("TargetSpecified", "continuous_slash", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	local use = data:toCardUse()
	if not use.card:isKindOf("Slash") then return end

	for _, to in sgs.qlist(use.to) do
		if to:getState() == "robot" and to:objectName() ~= use.from:objectName() then
			self:addSpeechCounter(to, "continuous_slash_count".. use.from:objectName() .."-Clear")
			if self:getSpeechCounter(to,"continuous_slash_count".. use.from:objectName() .."-Clear") >= 2 and math.random() < 0.5 then
				local chat = sgs.ai_chat.continuous_slash
				if to:isFemale() then
					chat = sgs.ai_chat.continuous_slash_female
				end
				say(to,chat[math.random(1, #chat)])
				self:setSpeechCounter(to, "continuous_slash_count".. use.from:objectName() .."-Clear", 0)
			end
		end
	end
end)

register_speech_event("CardOffset", "multi_jink", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	local effect = data:toCardEffect()
	if not effect.card or not effect.card:isKindOf("Slash") then return end
	if not effect.to then return end
	if not AIChat(effect.to) then return end
	self:addSpeechCounter(effect.to, "jink_count-Clear")

	if self:getSpeechCounter(effect.to,"jink_count-Clear") >= 2 and math.random() < 0.3 then
		say(effect.to,sgs.ai_chat.multi_jink[math.random(1, #sgs.ai_chat.multi_jink)])
		self:setSpeechCounter(effect.to, "jink_count-Clear", 0)
	end
end)

register_speech_event("Death", "low_hp_kill", function(self,player,data,AIChat,say,event)
	local death = data:toDeath()
	if not death.damage or not death.damage.from then return end

	local killer = death.damage.from
	if not AIChat(killer) then return end
	if killer:getState() == "robot" and killer:getHp() <= 1 and math.random() < 0.4 and player:objectName() == killer:objectName() then
		local chat = sgs.ai_chat.low_hp_kill
		if killer:isFemale() then
			chat = sgs.ai_chat.low_hp_kill_female
		end
		say(killer,chat[math.random(1, #chat)])
	end
end)

register_speech_event("GameStart", "greeting", function(self,player,data,AIChat,say,event)
	if not AIChat() then return end

	if player:getState() == "robot" and math.random() < 0.2 then
		self:speak("game_start")
	end
end)

register_speech_event("EventPhaseStart", "turn_end", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_Finish then return end
	if player:getState() ~= "robot" or math.random() > 0.1 then return end

	self:speak("turn_end", player:isFemale())
end)

register_speech_event("EventPhaseStart", "turn_start", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_Start then return end
	if player:getState() ~= "robot" or math.random() > 0.1 then return end

	self:speak("turn_start", player:isFemale())
end)

register_speech_event("GameStart", "lord_identity", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	if not player:isLord() then return end
	if player:getState() ~= "robot" or math.random() > 0.5 then return end

	self:speak("become_lord")
end)

register_speech_event("EventPhaseStart", "full_hand", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	if player:getState() ~= "robot" then return end
	if player:getPhase() ~= sgs.Player_Draw then return end
	if player:getHandcardNum() >= player:getMaxCards() + 2 and math.random() < 0.15 then
		say(player,sgs.ai_chat.full_hand[math.random(1, #sgs.ai_chat.full_hand)])
	end
end)

register_speech_event("CardsMoveOneTime", "god_equip", function(self,player,data,AIChat,say,event)
	if not AIChat() then return end
	local move = data:toMoveOneTime()
	if move.to_place ~= sgs.Player_PlaceEquip then return end
	if not move.to then return end
	local to = self.room:findPlayerByObjectName(move.to:objectName())
	if to:objectName() ~= player:objectName() then return end
	if not to or to:getState() ~= "robot" then return end

	if to:getEquips():length() >= 5 and math.random() < 0.25 then
		say(to,sgs.ai_chat.god_equip[math.random(1, #sgs.ai_chat.god_equip)])
	end
end)

register_speech_event("Damaged", "lord_in_danger_call", function(self,player,data,AIChat,say,event)
	if not AIChat() then return end
	local damage = data:toDamage()
	if not damage.to or not damage.to:isLord() then return end

	if damage.to:getHp() <= 2 and math.random() < 0.3 then
		for _, p in sgs.qlist(self.room:getOtherPlayers(damage.to)) do
			if p:getState() == "robot" and self:isFriend(p, damage.to) and math.random() < 0.5 and speech_roles(self).loyalist>1 then
				say(p,sgs.ai_chat.lord_in_danger[math.random(1, #sgs.ai_chat.lord_in_danger)])
				break
			end
		end
	end
end)

register_speech_event("CardsMoveOneTime", "equip_removed", function(self,player,data,AIChat,say,event)
	if not AIChat() then return end
	local move = data:toMoveOneTime()
	if move.to_place ~= sgs.Player_DiscardPile then return end
	if not move.from_places:contains(sgs.Player_PlaceEquip) then return end
	if not move.from then return end
	local from = self.room:findPlayerByObjectName(move.from:objectName())
	if not from or from:getState() ~= "robot" then return end
	if from:objectName() ~= player:objectName() then return end
	for i = 0, move.card_ids:length() - 1 do
        -- 檢查第 i 張牌的來源是否為裝備區
        if move.from_places:at(i) == sgs.Player_PlaceEquip then
            local card_id = move.card_ids:at(i)
            local card = speech_known(move.cards[card_id], "disclosed removed equipment")

            if card:isKindOf("EquipCard") then
                if math.random() < 0.3 then
                    local chat = sgs.ai_chat.equip_removed
                    if from:isFemale() then
                        chat = sgs.ai_chat.equip_removed_female
                    end
                    -- 增加非空檢查，防止 chat 表為空時報錯
                    if chat and #chat > 0 then
                        say(from,chat[math.random(1, #chat)])
                    end
                end
                break -- 只要有一張是裝備，說完話就跳出，避免刷屏
            end
        end
    end
end)

register_speech_event("EventPhaseStart", "discard_many", function(self,player,data,AIChat,say,event)
	if not AIChat(player) then return end
	if player:getState() ~= "robot" then return end
	if player:getPhase() ~= sgs.Player_Discard then return end
	if player:getHandcardNum() >= player:getMaxCards() + 2 and math.random() < 0.15 then
		say(player,sgs.ai_chat.discard_many[math.random(1, #sgs.ai_chat.discard_many)])
	end
end)
