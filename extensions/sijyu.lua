extension = sgs.Package("sijyu", sgs.Package_GeneralPack)
extension_lost = sgs.Package("sijyu_lost", sgs.Package_GeneralPack)

sgs.LoadTranslationTable {
    ["sijyu"] = "超群絕倫",
    ["sijyu_lost"] = "覆车之戒",
}
-- common prompt
sgs.LoadTranslationTable {
    ["#skill_add_damage"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%from对%to造成的伤害增加至%arg2点。", -- add
    ["#skill_add_damage_byother1"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，", -- add
    ["#skill_add_damage_byother2"] = "%from 对%to造成的伤害增加至%arg点。", -- add
    ["#skill_cant_jink"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%to 不能使用【闪】响应 %from 对 %to 使用的【杀】。", -- add
    ["#BecomeTargetBySkill"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%to 成为了 %card 的目标", -- add
    ["#ArmorNullifyDamage"] = "%from 的防具【%arg】效果被触发，抵消 %arg2 点伤害", -- add
    ["#SkillNullifyDamage"] = "%from 的技能【%arg】效果被触发，抵消 %arg2 点伤害", -- add
    ["#ChooseSkill"] = "%from 的技能 %arg 选择了 %arg2",

}
sgs.LoadTranslationTable {
    ["sijyu_guanyu"] = "关羽",
    ["&sijyu_guanyu"] = "关羽",
    ["#sijyu_guanyu"] = "过关斩将",
    ["~sijyu_guanyu"] = "桃园一拜，此生不改！",
    ["designer:sijyu_guanyu"] = "046435jkl",
    ["cv:sijyu_guanyu"] = "",
    ["illustrator:sijyu_guanyu"] = "特特肉",


    ["sijyu_wusheng"] = "武圣",
    [":sijyu_wusheng"] = "你可以将一张红色牌当做任意一种【杀】使用或打出；每回合每种花色限一次，你使用或打出非转化的【杀】时，摸一张牌。",
    ["$sijyu_wusheng1"] = "忠心赤胆，青龙啸天！",
    ["$sijyu_wusheng2"] = "撒满腔热血，扫天下汉贼！",

    ["sijyu_qifeng"] = "奇锋",
    [":sijyu_qifeng"] = "你使用【杀】结算完毕后，若此牌没有造成伤害，你可以弃置其他角色一张牌，然后若之不为装备牌，你可以将此牌交给一名角色。",
    ["sijyu_qifeng-invoke"] = "你可以发动“奇锋”，弃置其他角色一张牌<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    ["@sijyu_qifeng"] = "你可以将 %src 交给一名角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    ["sijyu_qifeng_get"] = "奇锋",
    ["$sijyu_qifeng1"] = "又一个刀下亡魂！",
    ["$sijyu_qifeng2"] = "忠义当先，有进无退！",


    ["sijyu_tuodao"] = "拖刀",
    [":sijyu_tuodao"] = "每当你受到的伤害结算完毕后，你可以与伤害来源各弃对方一张手牌，然后你可以对其使用一张【杀】，若此【杀】造成了伤害，你可以令一名角色回复一点体力。",
    ["@sijyu_tuodao"] = "你可以发动“拖刀”，对 %src 使用一张【杀】",
    ["sijyu_tuodao-invoke"] = "你可以发动“拖刀”，令一名角色回复一点体力<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    ["$sijyu_tuodao1"] = "将军之恩，今日两清！",
    ["$sijyu_tuodao2"] = "千里追魂，一刀索命！",

    ["sijyu_zhanjiang"] = "斩将",
    [":sijyu_zhanjiang"] = "锁定技，出牌阶段，你每造成一次伤害后，你可以额外使用一张【杀】。",
    ["$sijyu_zhanjiang1"] = "过关斩将，谁能拦我！",
    ["$sijyu_zhanjiang2"] = "手握青龙，胯骑赤兔。",

    --[[初見是賴皮角色，堆了一堆菜刀將特效，實際上就是很多時間"每回合使用一張殺，發動奇锋，過"的程度。有原身殺對低防禦角色攻擊力就自帶武聖咆哮一樣。方差將
    拖刀9成時間會令關羽陷入手牌愈來愈少的境地，大多數時候就是減少2張手牌厚度換來一次奇锋的機會。不發沒有存在感，發了愈來愈資源缺乏
    斩将令關羽成為欺善怕惡的角色，打防禦空虛的角色能做到咆哮，打防禦高的角色直接不存在。只有放完AOE後有空間去調度資源
    整體不怎麼樣，DIY小白水平]]
    ----------------------------------------------------------------------------------------------------------

    ["sijyu_zhaoyun"] = "赵云",
    ["&sijyu_zhaoyun"] = "赵云",
    ["#sijyu_zhaoyun"] = "青虹游龙",
    ["~sijyu_zhaoyun"] = "酒足驱年兽，新岁老一人。",
    ["designer:sijyu_zhaoyun"] = "霍凛",
    ["cv:sijyu_zhaoyun"] = "",
    ["illustrator:sijyu_zhaoyun"] = "-a白",

    ["sijyu_youlong"] = "游龙",
    [":sijyu_youlong"] = "每回合限一次，你可以将一张牌当做任意基本牌或【无懈可击】使用或打出，然后摸一张牌。",
    ["sijyu_youlong_slash"] = "游龙【杀】",
    ["$sijyu_youlong1"] = "龙翔九天，曳日月于天地，换旧符于新岁。",
    ["$sijyu_youlong2"] = "御风万里，辟邪祟于宇外，映祥瑞于神州。",

    ["sijyu_kehou"] = "克祸",
    [":sijyu_kehou"] = "每回合限一次，当你的体力值变化时，你可以将手牌补至体力值。",
    ["$sijyu_kehou1"] = "龙诞新岁，普天同庆，魂佑宇内，裔泽炎黄。",
    ["$sijyu_kehou2"] = "龙吐息而万物生，今龙临神州，华夏当兴！",

    ["sijyu_qizhan"] = "七战",
    [":sijyu_qizhan"] = "锁定技，当你使用或打出非转化的牌时，你武将牌上的技能视为未发动过。",
    ["$sijyu_qizhan1"] = "满腔热血，浑身是胆！",
    ["$sijyu_qizhan2"] = "攻防一体，无懈可击！",

    --[[游龙又是印牌技ORZ，幸好guhuodialog能讓LUA用，要是讓我從select->skillcard從0做絕對會無視
    不怎麼有新意，明明都說了最好不要有原版影子，還有要文字版，什麼都沒有
    克祸 游龙自帶摸牌的話，很多時候手牌都比較充足，更多時候受傷是因為用了遊龍還未刷新 雖然有作用但不多
    七战 雖然不算很有新意，但這技能還是讓這個將有操作感和特色玩法的核心，
    整體確實有一定樂趣 克祸效果改為手牌大於上限時，能怎樣怎樣 應該更對稱和有趣 至於要是空城了就等死吧
    ]]
    ----------------------------------------------------------------------------------------------------------

    ["sijyu_caocao"] = "曹操",
    ["&sijyu_caocao"] = "曹操",
    ["#sijyu_caocao"] = "梦中杀人",
    ["~sijyu_caocao"] = "霸业未成，未成啊...",
    ["designer:sijyu_caocao"] = "方之易小文",
    ["cv:sijyu_caocao"] = "",
    ["illustrator:sijyu_caocao"] = "",

    ["sijyu_xuanmeng"] = "宣梦",
    [":sijyu_xuanmeng"] = "回合结束时，你可以声明一种牌名，然后摸两张牌，将武将牌翻面。",

    ["sijyu_zhanshi"] = "斩侍",
    [":sijyu_zhanshi"] = "当你成为其他角色使用牌的目标时，若你的武将牌背面朝上，你可以弃置一张名称与你“宣梦”声明的牌名相同的手牌，对该角色造成1点伤害，然后将武将牌翻面。",
    ["@sijyu_zhanshi"] = "你可以弃置一张名称与你“宣梦”声明的牌名相同的手牌对 %src 造成1点伤害",
    ["$sijyu_zhanshi"] = "孤，好梦中杀人！",

    ["sijyu_zuotai"] = "作态",
    [":sijyu_zuotai"] = "当你的武将牌翻面后，若你的武将牌正面朝上，你可以令一名已受伤的角色摸两张牌，然后清除“宣梦”声明的牌名。",
    ["sijyu_zuotai-invoke"] = "你可以发动“作态”<br/> <b>操作提示</b>: 选择一名已受伤角色→点击确定<br/>",
    ["$sijyu_zuotai"] = "宁教我负天下人，休教天下人负我！",


    --[[無緣無故聲明 增加工作量 然後實際就是摸2棄1摸2 跟去除聲明條件差不多 單純限制棄置牌就寫幾百行 沒有意義]]
    --[[本來想用設伏/guhuo之類做的 看了看allowed_guhuo_dialog_buttons放在最後 一來就被Self->isCardLimited(card, Card::MethodUse)||!card->isAvailable(Self) 限制了
        想要個shenfu之類的dialog]]
    ----------------------------------------------------------------------------------------------------------

    ["sijyu_yuanshao"] = "袁紹",
    ["&sijyu_yuanshao"] = "袁紹",
    ["#sijyu_yuanshao"] = "豪貴名門",
    ["~sijyu_yuanshao"] = "",
    ["designer:sijyu_yuanshao"] = "zfawvn",
    ["cv:sijyu_yuanshao"] = "",
    ["illustrator:sijyu_yuanshao"] = "",

    ["sijyu_zhuluan"] = "诛乱",
    [":sijyu_zhuluan"] = "<font color=\"green\"><b>出牌阶段限三次，</b></font>你可以弃置X张手牌，视为使用一张使用伤害+1的【万箭齐发】（X为当前角色数-1）；\
    其他角色因响应你使用的【万箭齐发】而打出【闪】时，你摸一张牌，且此牌不计入本回合的使用次数限制；\
    若所有其他角色受到你使用的【万箭齐发】的伤害，你下轮造成的伤害视作体力流失。",
    ["sijyu_zhuluanUsed"] = "诛乱:已使用",
    ["zhuluandamage"] = "诛乱:体力流失",
    ["sijyu_huju"] = "虎踞",
    [":sijyu_huju"] = "若你本回合造成過伤害，你可以摸X张牌，然后将武将牌翻面，跳过弃牌阶段。（X为当前角色数）；\
    当你成为其他角色使用锦囊牌的目标时，若你的武将牌背面朝上，你可以摸一张牌后交给其一张牌，使本锦囊牌对你无效。",
    ["@sijyu_huju"] = "虎踞：交给 %src 一张牌，令 【%dest】对你无效",
    ["sijyu_youbing"] = "忧病",
    [":sijyu_youbing"] = "当你的准备阶段开始时或一轮结束时，你失去1点体力；\
    若你处于濒死状态时，你失去1点体力上限，亮出牌堆顶的一张牌：若该牌花色为红桃，你回复至1点体力，然后选择获得下列技能中的一个：“硝妄”，“执志”，“中兴”，“利剑”，“思召”；",--否则你死亡。",
    ["sijyu_pingwei"] = "平威",
    [":sijyu_pingwei"] = "主公技，每轮开始时，你可以令所有其他角色选择是否交给你一张牌；\
    本轮当你摸牌时，交给你手牌的其他角色可以摸一张牌（每轮限一次）。",
    ["@sijyu_pingwei"] = "平威：你可以交给 %src 一张牌",
    ["sijyupingwei"] = "平威",
    ["sijyu_xiaowang"] = "硝妄",
    [":sijyu_xiaowang"] = "锁定技，你造成非火属性伤害后，你额外造成1点火属性伤害；若你本回合未能造成伤害，则失去1点体力对所有其他角色各造成1点火焰伤害。",
    ["sijyuzhizhi"] = "执志",
    ["sijyu_zhizhi"] = "执志",
    [":sijyu_zhizhi"] = "准备阶段，你可以亮出牌堆顶等同于存活角色数量的牌，所有角色同时展示一张手牌，然后展示花色唯一的角色获得亮出牌中的所有牌且获得“执志”标记，直到本轮结束。；\
    其他角色对有“执志”标记角色用【杀】无距离、无次数限制；每当其他角色对其造成伤害，你与伤害来源各摸一张牌。",
    ["sijyu_zhongxing"] = "中兴",
    [":sijyu_zhongxing"] = "锁定技，当你失去最后的手牌后，你将手牌补至体力上限；\
    当你的牌被弃置后，若弃牌数大于你的手牌数，你摸等同弃牌数张的牌。",
    ["sijyu_lijian"] = "利剑",
    [":sijyu_lijian"] = "其他角色的防具于你回合内无效；\
    每当你造成伤害时，你可以令此伤害+1，然后受伤角色摸一张牌。\
    当你受到伤害时，你可以弃置一张牌令此伤害-1；\
    若你装备区没有武器牌，你的攻击范围+1。",
    ["@sijyu_lijian"] = "利剑：你可以弃置一张牌令伤害-1",
    ["sijyu_sizhao"] = "思召",
    [":sijyu_sizhao"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你赢，你将体力回复至体力上限且摸等量的牌；若你没赢，则你每造成一次伤害后，若你已受伤，你回复1点体力，否则你增加1点体力上限，直到回合结束。",

    --[[超狗屎描述 自HIGH強度然後加個你死亡 堆了幾百種效果 700字]]
    --結果9成代碼沒有用
    --[[多人局約等於白版 單挑3牌6傷/過3牌+無視次數特效]]
    --過於無趣拖更了 配音也沒心思找了
    --超級跨回合記憶

    ----------------------------------------------------------------------------------------------------------

    ["sijyu_jiangwei"] = "姜维",
    ["&sijyu_jiangwei"] = "姜维",
    ["#sijyu_jiangwei"] = "恨幽望明",
    ["~sijyu_jiangwei"] = "无力回天，有负丞相重托。",
    ["designer:sijyu_jiangwei"] = "o金水木o",
    ["cv:sijyu_jiangwei"] = "",
    ["illustrator:sijyu_jiangwei"] = "凝聚永恒",

    ["sijyu_nuozhan"] = "搦战",
    [":sijyu_nuozhan"] = "<font color=\"green\"><b>每轮每名角色限一次，</b></font>一名角色结束阶段时，若其本回合出牌阶段未造成过伤害，你获得一枚“战”标记。回合结束后，你可以移去一枚“战”标记并获得一个额外回合。",
    ["$sijyu_nuozhan1"] = "困而舍其命，奋而尽其忠！",
    ["$sijyu_nuozhan2"] = "而今身陷囹圄，安能坐以待毙！",

    ["sijyuzhan"] = "战",
    ["sijyu_xinghan"] = "兴汉",
    [":sijyu_xinghan"] = "使命技，游戏开始时，你选择一名其他角色，当其受到伤害后你获得一枚“战”标记。\
        成功：你或选择的角色杀死一名角色，你获得“ol界挑衅”“界观星”\
        失败：你或选择的角色进入濒死状态，其回复体力至1点，你获得“死战”并结束当前回合。",
    ["@sijyu_xinghan-start"] = "兴汉：请选择一名其他角色",
    ["$sijyu_xinghan1"] = "蜀汉大业，虽身小亦鼎力而为！",
    ["$sijyu_xinghan2"] = "丞相北伐大业未完，吾必尽力图之！",
    ["$sijyu_xinghan3"] = "蜀汉兴隆之志，伯约继之！",
    ["$sijyu_xinghan4"] = "五星所行，合散犯守。",

    ["sijyu_sizhan"] = "死战",
    [":sijyu_sizhan"] = "锁定技，其他角色回合结束后，你失去1点体力上限获得一个额外回合。",
    ["$sijyu_sizhan1"] = "放手一搏，或未可知。",
    ["$sijyu_sizhan2"] = "璀璨星河，伴我同行。",

    --一邊打兴汉目標一邊存標記有點滑稽
    --多人局能玩成三國殺單機版(雖然神殺本來就是) 特點就是很多回合的白板
    --(本人只玩多人局)
    --成功了強度太逆天了 失敗活不過一輪

    ----------------------------------------------------------------------------------------------------------

    ["sijyu_zhugeliang"] = "诸葛亮",
    ["&sijyu_zhugeliang"] = "诸葛亮",
    ["#sijyu_zhugeliang"] = "己命何知",
    ["~sijyu_zhugeliang"] = "寥落星辰，蜀汉尽衰。",
    ["designer:sijyu_zhugeliang"] = "o金水木o",
    ["cv:sijyu_zhugeliang"] = "",
    ["illustrator:sijyu_zhugeliang"] = "",

    ["sijyu_xing"] = "星",
    ["sijyu_qixing"] = "七星",
    [":sijyu_qixing"] = "锁定技，你的起始手牌数+7。分发起始手牌后，你将其中七张扣置于武将牌旁，称为“星”。出牌阶段开始时，你令一角色获得所有“星”并将等量牌成为“星”。当你进入濒死时，你回复体力至1点并进行判定，若点数与“星”均不同，你失去1点体力上限。",
    ["sijyu_qixing-invoke"] = "你可以发动“七星”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    ["$sijyu_qixing1"] = "伏忘天恩，誓讨汉贼！",
    ["$sijyu_qixing2"] = "斗转星移，七星借命！",
    ["$sijyu_qixing3"] = "虚实难测，莫敢来攻。",
    ["$sijyu_qixing4"] = "天公助我雾胧满江。",

    ["sijyu_fa"] = "伐",
    ["sijyu_fabei"] = "伐北",
    [":sijyu_fabei"] = "锁定技，你以此法以外当前回合获得的牌进入弃牌堆后你将其置于武将牌上称为“伐”。其他角色准备阶段，你获得所有“伐”，失去1点体力并进行一个额外的出牌阶段。",
    ["$sijyu_fabei1"] = "请再帮我一次，延续大汉的国运吧。",
    ["$sijyu_fabei2"] = "星象凶险，须谨慎再三，方有一线胜机。",

    ["sijyu_fengyi"] = "逢懿",
    [":sijyu_fengyi"] = "你可以用一张“星”替换判定牌并令其立即生效。当你死亡后，你可以将所有“星”交给一名角色并令其翻面。",
    ["@sijyu_fengyi-card"] = "请发动“%dest”来修改 %src 的“%arg”判定",
    ["sijyu_fengyi-invoke"] = "你可以发动“逢懿”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    ["$sijyu_fengyi1"] = "疑心者，难识破。",
    ["$sijyu_fengyi2"] = "多思多疑，不如放手一搏。",
    ["$sijyu_fengyi3"] = "鞠躬尽瘁，愿蜀汉长存！",

    --伐北運營比較關鍵


}


sijyu_guanyu = sgs.General(extension_lost, "sijyu_guanyu", "shu", 4, true)


--[[
	技能名：武圣
	相关武将：关羽
	技能描述：你可以将一张红色牌当做任意一种【杀】使用或打出；每回合每种花色限一次，你使用或打出非转化的【杀】时，摸一张牌。
	引用：sijyu_wusheng
]] --
sijyu_wushengCard = sgs.CreateSkillCard {
    name = "sijyu_wusheng",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local plist = sgs.PlayerList()
        for i = 1, #targets do plist:append(targets[i]) end
        local rangefix = 0
        if not self:getSubcards():isEmpty() and player:getWeapon() and player:getWeapon():getId() == self:getSubcards():first() then
            local card = player:getWeapon():getRealCard():toWeapon()
            rangefix = rangefix + card:getRange() - player:getAttackRange(false)
        end
        if not self:getSubcards():isEmpty() and player:getOffensiveHorse() and player:getOffensiveHorse():getId() == self:getSubcards():first() then
            rangefix = rangefix + 1
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card, user_str = nil, self:getUserString()
            if user_str ~= "" then
                local us = user_str:split("+")
                card = sgs.Sanguosha:cloneCard(us[1])
            end
            return card and card:targetFilter(plist, to_select, player) and
                not player:isProhibited(to_select, card, plist)
                and (card:isKindOf("Slash") and
                    (player:canSlash(to_select, true, rangefix)))
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local card = player:getTag("sijyu_wusheng"):toCard()
        return card and card:targetFilter(plist, to_select, player) and
            not player:isProhibited(to_select, card, plist)
            and (card:isKindOf("Slash") and player:canSlash(to_select, true, rangefix))
    end,
    feasible = function(self, targets, player)
        local plist = sgs.PlayerList()
        for i = 1, #targets do plist:append(targets[i]) end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card, user_str = nil, self:getUserString()
            if user_str ~= "" then
                local us = user_str:split("+")
                card = sgs.Sanguosha:cloneCard(us[1])
            end
            return card and card:targetsFeasible(plist, player)
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local card = player:getTag("sijyu_wusheng"):toCard()
        return card and card:targetsFeasible(plist, player)
    end,
    on_validate = function(self, use)
        local yuji = use.from
        local to_guhuo = self:getUserString()
        local use_card = dummyCard(to_guhuo)
        use_card:setSkillName("sijyu_wusheng")
        use_card:addSubcard(self)
        return use_card
    end,
    on_validate_in_response = function(self, yuji)
        local to_guhuo = self:getUserString()
        local use_card = dummyCard(to_guhuo)
        use_card:setSkillName("sijyu_wusheng")
        use_card:addSubcard(self)
        return use_card
    end
}
sijyu_wushengVS = sgs.CreateViewAsSkillV2 {
    name = "sijyu_wusheng",
    n = 1,
    response_or_use = true,
    can_activate = function(self, request)
        local player = request:getInitiator()
        if not player then return false end
        local reason = request:getReason()
        if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return CardIsAvailable(player, "slash", "sijyu_wusheng") ~= nil
        elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local pattern = request:getPattern() or ""
            if string.find(pattern, "slash")
            then
                return true
            end
        end
        return false
    end,
    can_select_card = function(self, request, to_select)
        if not to_select or not to_select:isRed() then return false end
        if not request:getSelectedCardIds():isEmpty() then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local player = request:getInitiator()
            if not player then return false end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:addSubcard(to_select:getEffectiveId())
            slash:deleteLater()
            return slash:isAvailable(player)
        end
        return true
    end,
    create_card = function(self, request)
        if request:getSelectedCardIds():length() == 1 then
            local c = sijyu_wushengCard:clone()
            local name = request:getUserString()
            if not name or name == "" then return nil end
            c:setUserString(name)
            for _, ic in sgs.qlist(request:getSelectedCardIds()) do
                c:addSubcard(ic)
            end
            return c
        end
    end,
}

sijyu_wusheng = sgs.CreateTriggerSkillV2 {
    name = "sijyu_wusheng",
    events = { sgs.CardUsed, sgs.CardResponded },
    view_as_skill = sijyu_wushengVS,
    juguan_type = "all_slashs",
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return false end
        local card
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if not card or not card:isKindOf("Slash") or card:isVirtualCard() then return false end
        return self:objectName()
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local card
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        local record = player:property("sijyu_wushengRecords"):toString()
        local suit = card:getSuitString()
        local records
        if (record) then
            records = record:split(",")
        end
        if records and (table.contains(records, suit) or not card:hasSuit()) then

        else
            table.insert(records, suit)
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1, self:objectName())
        end
        room:setPlayerProperty(player, "sijyu_wushengRecords", sgs.QVariant(table.concat(records, ",")));
        for _, mark in sgs.list(player:getMarkNames()) do
            if (string.startsWith(mark, "&sijyu_wusheng+#record") and player:getMark(mark) > 0) then
                room:setPlayerMark(player, mark, 0)
            end
        end
        local mark = "&sijyu_wusheng+#record"
        for _, suit in ipairs(records) do
            mark = mark .. "+" .. suit .. "_char"
        end
        mark = mark .. "-Clear"
        room:setPlayerMark(player, mark, 1)


        return false
    end
}
sijyu_wushengClear = sgs.CreateTriggerSkillV2 {
    name = "#sijyu_wushengClear",
    events = { sgs.EventLoseSkill, sgs.EventPhaseChanging },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventLoseSkill then
            if data:toSkillChange().skillName ~= "sijyu_wusheng" then return false end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
        end
        local names, owners = {}, {}
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if not p:getValidSkillInstanceIds(self:objectName()):isEmpty() then
                table.insert(names, self:objectName())
                table.insert(owners, p:objectName())
            end
        end
        if #names > 0 then
            return table.concat(names, "|"), table.concat(owners, "|")
        end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.EventLoseSkill then
            local target = ctx.invoker
            if target and data:toSkillChange().skillName == "sijyu_wusheng" then
                local records = {}
                room:setPlayerProperty(target, "sijyu_wushengRecords", sgs.QVariant(table.concat(records, ",")));
            end
        elseif event == sgs.EventPhaseChanging then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                local records = {}
                room:setPlayerProperty(p, "sijyu_wushengRecords", sgs.QVariant(table.concat(records, ",")))
            end
        end
        return false
    end,
}
sijyu_guanyu:addSkill(sijyu_wusheng)
sijyu_guanyu:addSkill(sijyu_wushengClear)
extension_lost:insertRelatedSkills("sijyu_wusheng", "#sijyu_wushengClear")
--[[
	技能名：奇锋
	相关武将：关羽
	技能描述：你使用【杀】结算完毕后，若此牌没有造成伤害，你可以弃置其他角色一张牌，然后若之不为装备牌，你可以将此牌交给一名角色。
	引用：sijyu_qifeng
]] --
sijyu_qifeng = sgs.CreateTriggerSkillV2 {
    name = "sijyu_qifeng",
    events = { sgs.Damage, sgs.CardFinished },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return false end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                return self:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and not use.card:hasFlag("sijyu_qifeng_damage") then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:canDiscard(p, "he") then
                        return self:objectName()
                    end
                end
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                room:setCardFlag(damage.card, "sijyu_qifeng_damage")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then
                if not use.card:hasFlag("sijyu_qifeng_damage") then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:canDiscard(p, "he") then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "sijyu_qifeng-invoke",
                            true, true)
                        if target then
                            room:broadcastSkillInvoke(self:objectName())
                            local to_throw = room:askForCardChosen(player, target, "he", self:objectName())
                            local card = sgs.Sanguosha:getCard(to_throw)
                            if card:isKindOf("EquipCard") then
                                room:throwCard(card, target, player)
                            else
                                if room:getCardPlace(to_throw) == sgs.Player_PlaceHand then
                                    room:showCard(target, to_throw)
                                end
                                local cdata = sgs.QVariant()
                                cdata:setValue(card)
                                room:setTag("sijyu_qifeng_get", cdata)
                                local target = room:askForPlayerChosen(player, room:getAlivePlayers(),
                                    self:objectName() .. "_get",
                                    string.format("@sijyu_qifeng:%s", card:objectName()), true, true)
                                room:removeTag("sijyu_qifeng_get")
                                if target then
                                    --room:obtainCard(player, card)
                                    room:giveCard(player, target, card, self:objectName(), false)
                                else
                                    room:throwCard(card, target, player)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
}
sijyu_guanyu:addSkill(sijyu_qifeng)

--[[
	技能名：拖刀
	相关武将：关羽
	技能描述：每当你受到的伤害结算完毕后，你可以与伤害来源各弃对方一张手牌，然后你可以对其使用一张【杀】，若此【杀】造成了伤害，你可以令一名角色回复一点体力。
	引用：sijyu_tuodao
]] --
sijyu_tuodao = sgs.CreateTriggerSkillV2 {
    name = "sijyu_tuodao",
    events = { sgs.Damaged, sgs.DamageComplete, sgs.PreCardUsed, sgs.Damage },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return false end
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() then
                return self:objectName()
            end
        elseif event == sgs.DamageComplete then
            local damage = data:toDamage()
            if player:hasFlag("sijyu_tuodao") and damage.from and damage.from:isAlive()
                and not player:hasFlag("sijyu_tuodao_using") then
                return self:objectName()
            end
        elseif event == sgs.PreCardUsed then
            if not player:hasFlag("sijyu_tuodaoUsed") then return false end
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then
                return self:objectName()
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("sijyu_tuodao") then
                return self:objectName()
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() then
                room:setPlayerFlag(damage.to, "sijyu_tuodao")
            end
        elseif event == sgs.DamageComplete then
            local damage = data:toDamage()
            if player:hasFlag("sijyu_tuodao") and damage.from and damage.from:isAlive() and not player:hasFlag("sijyu_tuodao_using") then
                room:setPlayerFlag(player, "-sijyu_tuodao")
                if player:canDiscard(damage.from, "h") and damage.from:canDiscard(player, "h") then
                    local dest = sgs.QVariant()
                    dest:setValue(damage.from)
                    if room:askForSkillInvoke(player, self:objectName(), dest) then
                        room:broadcastSkillInvoke(self:objectName(), 2)
                        room:setPlayerFlag(player, "sijyu_tuodao_using")
                        local to_throw = room:askForCardChosen(player, damage.from, "h", self:objectName())
                        local card = sgs.Sanguosha:getCard(to_throw)
                        room:throwCard(card, damage.from, player)
                        local to_throw = room:askForCardChosen(damage.from, player, "h", self:objectName())
                        local card = sgs.Sanguosha:getCard(to_throw)
                        room:throwCard(card, player, damage.from)
                        player:setFlags("sijyu_tuodaoUsed")
                        room:setPlayerMark(player, "InfinityAttackRange", 1)
                        local slash = room:askForUseSlashTo(player, damage.from,
                            string.format("@sijyu_tuodao:%s", damage.from:objectName()), false)
                        room:setPlayerMark(player, "InfinityAttackRange", 0)
                        if not slash then
                            player:setFlags("-sijyu_tuodaoUsed")
                        else
                            if player:hasFlag("sijyu_tuodaoDamage") then
                                room:setPlayerFlag(player, "-sijyu_tuodaoDamage")
                                local targets = sgs.SPlayerList()
                                for _, p in sgs.qlist(room:getAlivePlayers()) do
                                    if p:isWounded() then
                                        targets:append(p)
                                    end
                                end
                                if targets:isEmpty() then
                                    room:setPlayerFlag(player, "-sijyu_tuodao_using")
                                    return false
                                end
                                local target = room:askForPlayerChosen(player, targets, self:objectName(),
                                    "sijyu_tuodao-invoke", true, true)
                                if target then
                                    room:broadcastSkillInvoke(self:objectName(), 1)
                                    local recover = sgs.RecoverStruct()
                                    recover.recover = 1
                                    recover.who = player
                                    room:recover(target, recover)
                                end
                            end
                        end
                        room:setPlayerFlag(player, "-sijyu_tuodao_using")
                    end
                end
            end
        elseif event == sgs.PreCardUsed then
            if not player:hasFlag("sijyu_tuodaoUsed") then return false end
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then
                player:setFlags("-sijyu_tuodaoUsed")
                room:setCardFlag(use.card, "sijyu_tuodao")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("sijyu_tuodao") then
                room:setPlayerFlag(player, "sijyu_tuodaoDamage")
            end
        end
        return false
    end
}
sijyu_guanyu:addSkill(sijyu_tuodao)
--[[
	技能名：斩将
	相关武将：关羽
	技能描述：锁定技，出牌阶段，你每造成一次伤害后，你可以额外使用一张【杀】。
	引用：sijyu_zhanjiang
]] --
sijyu_zhanjiang = sgs.CreateTriggerSkillV2 {
    name = "sijyu_zhanjiang",
    events = { sgs.Damage, sgs.CardUsed },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player then return false end
        if event == sgs.Damage then
            if player:getPhase() == sgs.Player_Play then
                return self:objectName()
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from and use.card and use.card:isKindOf("Slash")
                and player:getMark("&sijyu_zhanjiang-PlayClear") > 0 then
                return self:objectName()
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.Damage then
            if player and player:getPhase() == sgs.Player_Play then
                room:addPlayerMark(player, "&" .. self:objectName() .. "-PlayClear")
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from:hasSkill("sijyu_zhanjiang") and use.card and use.card:isKindOf("Slash")
                and player:getMark("&sijyu_zhanjiang-PlayClear") > 0 then
                if player:hasFlag("sijyu_zhanjiang_broadcast") then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerFlag(player, "-sijyu_zhanjiang_broadcast")
                else
                    room:setPlayerFlag(player, "sijyu_zhanjiang_broadcast")
                end
            end
        end
        return false
    end,
}
sijyu_zhanjiangTM = sgs.CreateTargetModSkillV2 {
    name = "#sijyu_zhanjiangTM",
    pattern = "Slash",
    holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        if ctx:getModType() ~= sgs.TargetModSkill_Residue then return 0 end
        local player = ctx:getPrimary()
        if player and player:getPhase() == sgs.Player_Play then
            return player:getMark("&sijyu_zhanjiang-PlayClear")
        end
        return 0
    end
}

sijyu_guanyu:addSkill(sijyu_zhanjiang)
sijyu_guanyu:addSkill(sijyu_zhanjiangTM)
extension_lost:insertRelatedSkills("sijyu_zhanjiang", "#sijyu_zhanjiangTM")



sijyu_zhaoyun = sgs.General(extension_lost, "sijyu_zhaoyun", "shu", 4, true)


--[[
	技能名：游龙
	相关武将：赵云
	技能描述：每回合限一次，你可以将一张牌当做任意基本牌或【无懈可击】使用或打出，然后摸一张牌。
	引用：sijyu_youlong
]] --
local function sijyu_youlongBuildCard(request, name)
    local ids = request:getSelectedCardIds()
    if ids:length() ~= 1 then return nil end
    if not name or name == "" then return nil end
    local card = sgs.Sanguosha:cloneCard(name)
    if not card then return nil end
    card:deleteLater()
    if (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] then return nil end
    card:addSubcard(ids:first())
    card:setSkillName("sijyu_youlong")
    return card
end

sijyu_youlongVS = sgs.CreateViewAsSkillV2 {
    name = "sijyu_youlong",
    n = 1,
    response_or_use = true,
    guhuo_type = "l",
    can_activate = function(self, request)
        local player = request:getInitiator()
        if not (player and player:isAlive()) then return false end
        local reason = request:getReason()
        if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if player:getMark("&sijyu_youlong-Clear") == 0 and player:getCardCount(true) > 0 then
                return (player:isWounded() or sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player))
            end
            return false
        end
        if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local pattern = request:getPattern()
            local skill_invoke = pattern
            if pattern == "peach+analeptic" and player:getMark("Global_PreventPeach") > 0
            then
                pattern = "analeptic"
            end
            pattern = dummyCard(pattern:split("+")[1])
            if pattern and player:getMark("&sijyu_youlong-Clear") < 1 and player:getCardCount(true) > 0
            then
                return pattern:isKindOf("BasicCard") or pattern:isKindOf("Nullification") or
                    ((string.find(skill_invoke, "slash")) ~= nil)
            end
        end
        return false
    end,
    can_select_card = function(self, request, to_select)
        return request:getSelectedCardIds():isEmpty()
            and not request:getInitiator():isJilei(to_select)
    end,
    create_card = function(self, request)
        local name = request:getUserString()
        if name == "" then
            name = request:getPattern():gsub("!$", ""):split("+")[1]:split("|")[1]
        end
        local card = sijyu_youlongBuildCard(request, name)
        if not card then return nil end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if not card:isKindOf("BasicCard") then return nil end
        elseif not sgs.Sanguosha:matchPattern(request:getPattern():gsub("!$", ""),
            request:getInitiator(), card) then
            return nil
        end
        return card
    end,
    cost = function(self, room, ctx, request)
        local yuji = ctx.invoker
        if not yuji then return false end
        room:addPlayerMark(yuji, "&sijyu_youlong-Clear")
        local to_guhuo
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            to_guhuo = request:getUserString()
        else
            to_guhuo = request:getPattern()
        end
        if to_guhuo == "slash" then
            to_guhuo = table.concat(sgs.Sanguosha:getSlashNames(), "+")
        end
        local user_str = room:askForChoice(yuji, "sijyu_youlong_slash", to_guhuo)
        local use_card = sgs.Sanguosha:cloneCard(user_str)
        if not use_card then return false end
        use_card:setSkillName("sijyu_youlong")
        for _, id in sgs.qlist(request:getSelectedCardIds()) do
            use_card:addSubcard(id)
        end
        ctx.updated_card = use_card
        return true
    end,
}

sijyu_youlong = sgs.CreateTriggerSkillV2 {
    name = "sijyu_youlong",
    events = { sgs.CardUsed, sgs.CardResponded },
    view_as_skill = sijyu_youlongVS,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return false end
        local card
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if not card or card:isKindOf("SkillCard") or card:getSkillName() ~= "sijyu_youlong" then return false end
        return self:objectName()
    end,
    on_effect = function(self, event, room, player, ctx)
        room:setPlayerMark(player, "&sijyu_youlong-Clear", 1)
        player:drawCards(1, self:objectName())
        return false
    end
}
sijyu_zhaoyun:addSkill(sijyu_youlong)

--[[
	技能名：克祸
	相关武将：赵云
	技能描述：每回合限一次，当你的体力值变化时，你可以将手牌补至体力值。
	引用：sijyu_kehou
]] --
sijyu_kehou = sgs.CreateTriggerSkillV2 {
    name = "sijyu_kehou",
    events = { sgs.HpChanged },
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return false end
        if player:getHandcardNum() < player:getHp()
            and player:getMark("&sijyu_kehou-Clear") < 1 then
            return self:objectName()
        end
        return false
    end,
    on_cost = function(self, event, room, player, ctx)
        return player:getHandcardNum() < player:getHp()
            and player:getMark("&sijyu_kehou-Clear") < 1
            and room:askForSkillInvoke(player, self:objectName())
    end,
    on_effect = function(self, event, room, player, ctx)
        room:addPlayerMark(player, "&sijyu_kehou-Clear")
        player:drawCards(player:getHp() - player:getHandcardNum(), self:objectName())
        SkillInvoke(self, player, false)
        return false
    end,
}

sijyu_zhaoyun:addSkill(sijyu_kehou)

--[[
	技能名：七战
	相关武将：赵云
	技能描述：锁定技，当你使用或打出非转化的牌时，你武将牌上的技能视为未发动过。
	引用：sijyu_qizhan
]] --

sijyu_qizhan = sgs.CreateTriggerSkillV2 {
    name = "sijyu_qizhan",
    events = { sgs.CardUsed, sgs.CardResponded },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return false end
        local card
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if not card or card:isVirtualCard() then return false end
        return self:objectName()
    end,
    on_effect = function(self, event, room, player, ctx)
        room:setPlayerMark(player, "&sijyu_youlong-Clear", 0)
        room:setPlayerMark(player, "&sijyu_kehou-Clear", 0)
        SkillInvoke(self, player, true)
        return false
    end
}

sijyu_zhaoyun:addSkill(sijyu_qizhan)




sijyu_caocao = sgs.General(extension_lost, "sijyu_caocao", "wei", 4, true)

--[[
	技能名：宣梦
	相关武将：曹操
	技能描述：回合结束时，你可以声明一种牌名，然后摸两张牌，将武将牌翻面。
	引用：sijyu_xuanmeng
]] --

sijyu_xuanmengCard = sgs.CreateSkillCard {
    name = "sijyu_xuanmeng",
    target_fixed = true,
    mute = true,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("sijyu_xuanmeng", 1)
        local list = {}
        for _, p in sgs.list(patterns()) do
            local dc = dummyCard(p)
            if dc and not source:property("sijyu_xuanmengRecords"):toString():contains(dc:objectName()) then
                table.insert(list, p)
            end
        end
        local choice = room:askForChoice(source, self:objectName(), table.concat(list, "+"))
        if choice ~= "" then
            card = sgs.Sanguosha:cloneCard(choice)
        end
        -- local card, user_str = nil, self:getUserString()
        -- if user_str ~= "" then
        --     local us = user_str:split("+")
        --     card = sgs.Sanguosha:cloneCard(us[1])
        -- end
        if card then
            local record = source:property("sijyu_xuanmengRecords"):toString()
            local name = card:objectName()
            local records = {}
            if (record) then
                records = record:split(",")
            end
            table.insert(records, name)
            room:setPlayerProperty(source, "sijyu_xuanmengRecords", sgs.QVariant(table.concat(records, ",")));
            for _, mark in sgs.list(source:getMarkNames()) do
                if (string.startsWith(mark, "&sijyu_xuanmeng+#record") and source:getMark(mark) > 0) then
                    room:setPlayerMark(source, mark, 0)
                end
            end
            local mark = "&sijyu_xuanmeng+#record"
            for _, name in ipairs(records) do
                mark = mark .. "+" .. name
            end
            room:setPlayerMark(source, mark, 1)
            --room:setPlayerMark(source, "sijyu_xuanmeng_guhuo_remove_" .. self:getUserString(), 1)
            source:drawCards(2, self:objectName())
            source:turnOver()
        end
    end,
}
sijyu_xuanmengVS = sgs.CreateViewAsSkillV2 {
    name = "sijyu_xuanmeng",
    n = 0,
    can_activate = function(skill, request)
        local reason = request:getReason()
        if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return false
        end
        return string.find(request:getPattern(), "@@sijyu_xuanmeng")
    end,
    create_card = function(skill, request)
        return sijyu_xuanmengCard:clone()
    end,
}
sijyu_xuanmeng = sgs.CreateTriggerSkillV2 {
    name = "sijyu_xuanmeng",
    view_as_skill = sijyu_xuanmengVS,
    events = { sgs.EventPhaseChanging },
    can_trigger = function(skill, event, room, player, data)
        if event ~= sgs.EventPhaseChanging then return false end
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_NotActive then return false end
        return skill:objectName(), player
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName())
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:askForUseCard(player, "@@sijyu_xuanmeng", "@sijyu_xuanmeng", -1, sgs.Card_MethodNone)
        return false
    end,
}
--sijyu_xuanmeng:setGuhuoDialog("!lr")
sijyu_caocao:addSkill(sijyu_xuanmeng)

--[[
	技能名：斩侍
	相关武将：曹操
	技能描述：你成为其他角色使用牌的目标时，若你的武将牌背面朝上，你可以弃置一张名称与你“宣梦”声明的牌名相同的手牌，对该角色造成1点伤害，然后翻面。
	引用：sijyu_zhanshi
]] --
sijyu_zhanshi = sgs.CreateTriggerSkillV2 {
    name = "sijyu_zhanshi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.TargetConfirming },
    can_trigger = function(skill, event, room, player, data)
        if event ~= sgs.TargetConfirming or not player then return false end
        local use = data:toCardUse()
        if use.from and use.from:objectName() ~= player:objectName()
            and use.card and not use.card:isKindOf("SkillCard") and use.to:contains(player) then
            if player:canDiscard(player, "h") and not player:faceUp() then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local record = player:property("sijyu_xuanmengRecords"):toString()
        local records = {}
        if (record) then
            records = record:split(",")
        end

        local temp = {}
        for _, str in ipairs(records) do
            table.insert(temp, sgs.Sanguosha:cloneCard(str):getClassName())
        end
        local pattern = table.concat(temp, ",")
        local prompt = string.format("@sijyu_zhanshi:%s", use.from:objectName())

        local card = room:askForCard(player, pattern, prompt, ctx.original_data,
            sgs.Card_MethodDiscard, use.from)
        return card ~= nil
    end,
    on_effect = function(skill, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        room:notifySkillInvoked(player, skill:objectName())
        room:broadcastSkillInvoke(skill:objectName())
        local damage = sgs.DamageStruct()
        damage.reason = skill:objectName()
        damage.from = player
        damage.to = use.from
        room:damage(damage)
        room:getThread():delay(50)
        player:turnOver()
        return false
    end,
}
sijyu_caocao:addSkill(sijyu_zhanshi)

--[[
	技能名：作态
	相关武将：曹操
	技能描述：你翻面后，若你的武将牌正面朝上，你可以令一名已受伤的角色摸两张牌，然后清除“宣梦”声明的牌名。
	引用：sijyu_zuotai
]] --
sijyu_zuotai = sgs.CreateTriggerSkillV2 {
    name = "sijyu_zuotai",
    events = { sgs.TurnedOver },
    frequency = sgs.Skill_NotFrequent,
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.TurnedOver and player and player:faceUp() then
            return skill:objectName(), player
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isWounded() then
                targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, targets, skill:objectName(), "sijyu_zuotai-invoke", true, true)
        if target then
            ctx.extra_data:setValue(target)
            return true
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local target = ctx.extra_data:toPlayer()
        if target then
            target:drawCards(2, skill:objectName())
            local records = {}
            room:setPlayerProperty(player, "sijyu_xuanmengRecords", sgs.QVariant(table.concat(records, ",")));
            for _, mark in sgs.list(player:getMarkNames()) do
                if (string.startsWith(mark, "&sijyu_xuanmeng+#record") and player:getMark(mark) > 0) then
                    room:setPlayerMark(player, mark, 0)
                end
            end
            room:broadcastSkillInvoke(skill:objectName())
        end
        return false
    end
}

sijyu_caocao:addSkill(sijyu_zuotai)

sijyu_yuanshao = sgs.General(extension_lost, "sijyu_yuanshao$", "qun", 5, true)

--[[
	技能名：诛乱
	相关武将：袁紹
	技能描述：出牌阶段限三次，你可以弃置X张手牌，视为使用一张使用伤害+1的【万箭齐发】（X为当前角色数-1）；\
    其他角色因响应你使用的【万箭齐发】而打出【闪】时，你摸一张牌，且此牌不计入本回合的使用次数限制；\
    若所有其他角色受到你使用的【万箭齐发】的伤害，你下轮造成的伤害视作体力流失。
	引用：sijyu_zhuluan
]] --

sijyu_zhuluanCard = sgs.CreateSkillCard {
    name = "sijyu_zhuluan",
    target_fixed = true,
    on_use = function(self, room, player, targets)
        local x = room:alivePlayerCount() - 1
        if player:getHandcardNum() >= x then
            local discard = room:askForDiscard(player, self:objectName(), x, x, true, false)
            if discard then
                local use_card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
                use_card:setSkillName("sijyu_zhuluan")
                local players = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if not player:isProhibited(p, use_card) then
                        players:append(p)
                    end
                end
                if players:length() > 0 then
                    local card_use = sgs.CardUseStruct()
                    card_use.from = player
                    card_use.to = players
                    card_use.card = use_card
                    room:useCard(card_use, true)
                end
				use_card:deleteLater()
            end
        end
    end
}
sijyu_zhuluanVS = sgs.CreateViewAsSkillV2 {
    name = "sijyu_zhuluan",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and player and player:isAlive()
            and player:getMark("&sijyu_zhuluanUsed-PlayClear") < 3
            and player:canDiscard(player, "h")
    end,
    create_card = function(skill, request)
        return sijyu_zhuluanCard:clone()
    end,
}
sijyu_zhuluan = sgs.CreateTriggerSkillV2 {
    name = "sijyu_zhuluan",
    view_as_skill = sijyu_zhuluanVS,
    events = { sgs.CardResponded, sgs.PreCardUsed, sgs.AfterDrawNCards,
        sgs.DamageCaused, sgs.EventPhaseChanging, sgs.DamageDone, sgs.CardFinished,
        sgs.Predamage, sgs.RoundStart
    },
    on_record = function(skill, event, room, player, ctx)
        -- 舊版此二事件於任意存活目標的 dispatch 上執行，對象為事件目標而非持有者。
        local data = ctx.original_data
        local target = ctx.invoker
        if not (target and target:isAlive()) then return end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return end
            for _, card in sgs.qlist(target:getHandcards()) do
                if card:hasFlag("sijyu_zhuluan") then
                    room:setCardFlag(card, "-RemoveFromHistory")
                end
            end
        elseif event == sgs.DamageDone then
            local damage = data:toDamage()
            if damage.card and table.contains(damage.card:getSkillNames(), "sijyu_zhuluan") then
                room:setPlayerFlag(damage.to, "-" .. skill:objectName())
            end
        end
    end,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if event == sgs.CardResponded then
            local resp = data:toCardResponse()
            if resp.m_card:isKindOf("Jink") and resp.m_who and resp.m_who:hasSkill(skill) and player ~= resp.m_who
                and resp.m_toCard and resp.m_toCard:isKindOf("ArcheryAttack") then
                return skill:objectName(), resp.m_who
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == skill:objectName() and not use.card:isKindOf("SkillCard")
            then
                return skill:objectName(), player
            end
        elseif event == sgs.AfterDrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= "sijyu_zhuluan" then return false end
            if draw.who and draw.who:objectName() == player:objectName() then
                return skill:objectName(), player
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and table.contains(damage.card:getSkillNames(), "sijyu_zhuluan") and damage.from and damage.from:objectName() == player:objectName() then
                return skill:objectName(), player
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == skill:objectName() and not use.card:isKindOf("SkillCard") then
                if use.from and player:objectName() == use.from:objectName() then
                    return skill:objectName(), player
                end
            end
        elseif event == sgs.RoundStart then
            if player:getMark("&sijyu_zhuluan") > 0 then
                return skill:objectName(), player
            end
        elseif event == sgs.Predamage then
            if player:getMark("&zhuluandamage_lun") > 0 then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.CardResponded then
            room:sendCompulsoryTriggerLog(player, skill)
            room:drawCards(player, 1, skill:objectName())
        elseif event == sgs.PreCardUsed then
            room:addPlayerMark(player, "&sijyu_zhuluanUsed-PlayClear")
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:setPlayerFlag(p, skill:objectName())
            end
        elseif event == sgs.AfterDrawNCards then
            local draw = data:toDraw()
            for _, id in sgs.list(draw.card_ids) do
                room:setCardTip(id, skill:objectName() .. "-Clear")
                room:setCardFlag(sgs.Sanguosha:getCard(id), "RemoveFromHistory")
                room:setCardFlag(sgs.Sanguosha:getCard(id), "sijyu_zhuluan")
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            room:sendCompulsoryTriggerLog(player, skill)
            damage.damage = damage.damage + 1
            data:setValue(damage)
        elseif event == sgs.CardFinished then
            local can_invoke = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasFlag(skill:objectName()) then
                    room:setPlayerFlag(p, "-" .. skill:objectName())
                    can_invoke = false
                end
            end
            if can_invoke then
                room:setPlayerMark(player, "&" .. skill:objectName(), 1)
            end
        elseif event == sgs.RoundStart then
            room:sendCompulsoryTriggerLog(player, skill)
            room:setPlayerMark(player, "&zhuluandamage_lun", 1)
            room:setPlayerMark(player, "&" .. skill:objectName(), 0)
        elseif event == sgs.Predamage then
            local damage = data:toDamage()
            if damage.to:isDead() then return false end
            room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true);
            room:loseHp(sgs.HpLostStruct(damage.to, damage.damage, skill:objectName(), player))
            return true;
        end
        return false
    end,
}
sijyu_zhuluanBuff = sgs.CreateTargetModSkillV2 {
    name = "#sijyu_zhuluanBuff",
    holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        if ctx:getModType() ~= sgs.TargetModSkill_Residue then return nil end
        local card = ctx:getCard()
        if card and card:hasFlag("sijyu_zhuluan") then return 1000 end
        return nil
    end,
}


sijyu_yuanshao:addSkill(sijyu_zhuluan)
sijyu_yuanshao:addSkill(sijyu_zhuluanBuff)
extension_lost:insertRelatedSkills("sijyu_zhuluan", "#sijyu_zhuluanBuff")

--[[
	技能名：虎踞
	相关武将：袁紹
	技能描述：若你本回合造成過伤害，你可以摸X张牌，然后将武将牌翻面，跳过弃牌阶段。（X为当前角色数）；\
    当你成为其他角色使用锦囊牌的目标时，若你的武将牌背面朝上，你可以摸一张牌后交给其一张牌，使本锦囊牌对你无效。
	引用：sijyu_huju
]] --
sijyu_huju = sgs.CreateTriggerSkillV2 {
    name = "sijyu_huju",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging, sgs.TargetConfirming },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard and player:getMark("damage_point_turn-Clear") > 0 then
                return skill:objectName(), player
            end
        elseif event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("TrickCard") and use.from
                and use.from:objectName() ~= player:objectName() and not player:faceUp() then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseChanging then
            return player:askForSkillInvoke(skill:objectName())
        elseif event == sgs.TargetConfirming then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.EventPhaseChanging then
            player:drawCards(room:alivePlayerCount(), skill:objectName())
            player:turnOver()
            player:skip(sgs.Player_Discard)
        elseif event == sgs.TargetConfirming then
            local use = data:toCardUse()
            player:drawCards(1, skill:objectName())
            local prompt = string.format("@sijyu_huju:%s:%s", use.from:objectName(), use.card:objectName())
            local card = room:askForCard(player, ".!", prompt, data, sgs.Card_MethodNone, use.from, false)
            if card then
                room:obtainCard(use.from, card,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                        use.from:objectName(), skill:objectName(), ""), false)
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end
}
sijyu_yuanshao:addSkill(sijyu_huju)

--[[
	技能名：忧病
	相关武将：袁紹
	技能描述：当你的准备阶段开始时或一轮结束时，你失去1点体力；\
    若你处于濒死状态时，你失去1点体力上限，亮出牌堆顶的一张牌：若该牌花色为红桃，你回复至1点体力，然后选择获得下列技能中的一个：“硝妄”，“执志”，“中兴”，“利剑”，“思召”；否则你死亡。
	引用：sijyu_youbing
]] --

sijyu_youbing = sgs.CreateTriggerSkillV2 {
    name = "sijyu_youbing",
    events = { sgs.EventPhaseStart, sgs.RoundEnd, sgs.AskForPeaches },
    frequency = sgs.Skill_Frequent,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or event == sgs.RoundEnd then
            return skill:objectName(), player
        end
        if event == sgs.AskForPeaches then
            local dying = data:toDying()
            if dying.who and dying.who:objectName() == player:objectName() then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or event == sgs.RoundEnd) then
            room:loseHp(player, 1, true, player, skill:objectName())
            room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true, 1)
        end
        if (event == sgs.AskForPeaches) then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            room:loseMaxHp(player)
            local ids = room:getNCards(1, false)
            local move = sgs.CardsMoveStruct()
            move.card_ids = ids
            move.to = player
            move.to_place = sgs.Player_PlaceTable
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
                skill:objectName(), nil)
            room:moveCardsAtomic(move, true)
            local id = ids:first()
            local card = sgs.Sanguosha:getCard(id)
            local suit = card:getSuit()
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                skill:objectName(), nil)
            room:throwCard(card, reason, nil)
            if suit == sgs.Card_Heart then
                local recover = sgs.RecoverStruct()
                recover.who = player
                recover.recover = 1 - player:getHp()
                room:recover(player, recover)
                local skilllist = { "sijyu_xiaowang", "sijyu_zhizhi", "sijyu_zhongxing",
                    "sijyu_lijian", "sijyu_sizhao" }
                local choicelist = {}
                for _, skill in ipairs(skilllist) do
                    if not player:hasSkill(skill) then
                        table.insert(choicelist, skill)
                    end
                end
                local choice = room:askForChoice(player, skill:objectName(), table.concat(choicelist, "+"))
                if choice then
                    room:handleAcquireDetachSkills(player, choice)
                end
            else
                --room:killPlayer(player)
            end
        end
        return false
    end,
}

sijyu_yuanshao:addSkill(sijyu_youbing)

--[[
	技能名：平威
	相关武将：袁紹
	技能描述：主公技，每轮开始时，你可以令所有其他角色选择是否交给你一张牌；\
    本轮当你摸牌时，交给你手牌的其他角色可以摸一张牌（每轮限一次）。
	引用：sijyu_pingwei
]] --

sijyu_pingwei = sgs.CreateTriggerSkillV2 {
    name = "sijyu_pingwei$",
    events = { sgs.RoundStart, sgs.DrawNCards },
    frequency = sgs.Skill_NotFrequent,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if event == sgs.RoundStart then
            if player:hasLordSkill(skill:objectName()) then
                return skill:objectName(), player
            end
        elseif event == sgs.DrawNCards then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("&sijyupingwei_lun") > 0 then
                    return skill:objectName(), player
                end
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.RoundStart then
            return room:askForSkillInvoke(player, skill:objectName())
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.RoundStart then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isNude() then
                    local card = room:askForCard(p, "..", "@sijyu_pingwei:" .. player:objectName(), data,
                        sgs.Card_MethodNone)
                    if card then
                        room:giveCard(p, player, card, skill:objectName())
                        room:addPlayerMark(p, "&sijyupingwei_lun")
                    end
                end
            end
        elseif event == sgs.DrawNCards then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("&sijyupingwei_lun") > 0 then
                    room:sendCompulsoryTriggerLog(player, skill:objectName())
                    p:drawCards(1, skill:objectName())
                    room:setPlayerMark(p, "&sijyupingwei_lun", 0)
                end
            end
        end
        return false
    end,
}
sijyu_yuanshao:addSkill(sijyu_pingwei)

--[[
	技能名：硝妄
	相关武将：袁紹
	技能描述：锁定技，你造成非火属性伤害后，你额外造成1点火属性伤害；若你本回合未能造成伤害，则失去1点体力对所有其他角色各造成1点火焰伤害。
	引用：sijyu_xiaowang
]] --
sijyu_xiaowang = sgs.CreateTriggerSkillV2 {
    name = "sijyu_xiaowang",
    events = { sgs.Damage, sgs.EventPhaseChanging },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.nature ~= sgs.DamageStruct_Fire and damage.to and damage.to:isAlive() then
                return skill:objectName(), player
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:getMark("damage_point_turn-Clear") == 0 then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.Damage then
            local damage = data:toDamage()
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            local newdamage = sgs.DamageStruct()
            newdamage.from = player
            newdamage.to = damage.to
            newdamage.damage = 1
            newdamage.nature = sgs.DamageStruct_Fire
            room:damage(newdamage)
        elseif event == sgs.EventPhaseChanging then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            room:loseHp(player, 1, true, player, skill:objectName())
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                local damage = sgs.DamageStruct()
                damage.from = player
                damage.to = p
                damage.damage = 1
                damage.nature = sgs.DamageStruct_Fire
                room:damage(damage)
            end
        end
        return false
    end
}
addToSkills(sijyu_xiaowang)
sijyu_yuanshao:addRelateSkill("sijyu_xiaowang")

--[[
	技能名：执志
	相关武将：袁紹
	技能描述：准备阶段，你可以亮出牌堆顶等同于存活角色数量的牌，所有角色同时展示一张手牌，然后展示花色唯一的角色获得亮出牌中的所有牌且获得“执志”标记；\
    其他角色对有“执志”标记角色用【杀】无距离、无次数限制；每当其他角色对其造成伤害，你与伤害来源各摸一张牌。
	引用：sijyu_zhizhi
]] --
sijyu_zhizhi = sgs.CreateTriggerSkillV2 {
    name = "sijyu_zhizhi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:isAlive() and player:getPhase() == sgs.Player_Start then
            return skill:objectName(), player
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:askForSkillInvoke(player, skill:objectName())
    end,
    on_effect = function(skill, event, room, player, ctx)
        if player:getPhase() == sgs.Player_Start then
            local x = room:alivePlayerCount()
            local ids = room:getNCards(x, false)
            local move = sgs.CardsMoveStruct()
            move.card_ids = ids
            move.to = player
            move.to_place = sgs.Player_PlaceTable
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
                skill:objectName(), nil)
            room:moveCardsAtomic(move, true)
            local card_to_throw = {}
            local card_to_gotback = {}
            local show_suit = {}
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not p:isKongcheng() then
                    local card = room:askForCardShow(p, player, "sijyu_zhizhi")
                    if card then
                        table.insert(show_suit, card:getSuitString())
                        room:setPlayerMark(p, "sijyu_zhizhi", card:getEffectiveId())
                    end
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("sijyu_zhizhi") > 0 and not p:isKongcheng() then
                    room:showCard(p, p:getMark("sijyu_zhizhi"))
                end
            end
            table.sort(show_suit)

            for i = 0, x - 1, 1 do
                local id = ids:at(i)
                local card = sgs.Sanguosha:getCard(id)
                local suit = card:getSuitString()

                local num = 0
                for _, suitstring in ipairs(show_suit) do
                    if table.contains(show_suit, suit) and suitstring == suit then
                        num = num + 1
                    end
                end
                if num == 1 then
                    table.insert(card_to_gotback, id)
                else
                    table.insert(card_to_throw, id)
                end
            end
            if #card_to_throw > 0 then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                dummy:deleteLater()
                for _, id in ipairs(card_to_throw) do
                    dummy:addSubcard(id)
                end
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                    skill:objectName(), nil)
                room:throwCard(dummy, reason, nil)
            end
            if #card_to_gotback > 0 then
                for _, suit in ipairs(show_suit) do
                    local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    for _, id in ipairs(card_to_gotback) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:getSuitString() == suit then
                            dummy2:addSubcard(id)
                        end
                    end
                    if dummy2:subcardsLength() > 0 then
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:getMark("sijyu_zhizhi") > 0 then
                                local card = sgs.Sanguosha:getCard(p:getMark("sijyu_zhizhi"))
                                if card:getSuitString() == suit then
                                    room:obtainCard(p, dummy2)
                                    room:addPlayerMark(p, "&sijyuzhizhi_lun")
                                end
                            end
                        end
                    end
						dummy2:deleteLater()
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("sijyu_zhizhi") > 0 then
                    room:setPlayerMark(p, "sijyu_zhizhi", 0)
                end
            end
        end
        return false
    end
}
sijyu_zhizhiBuff = sgs.CreateTargetModSkillV2 {
    name = "#sijyu_zhizhiBuff",
    pattern = "Slash",
    holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local modType = ctx:getModType()
        if modType ~= sgs.TargetModSkill_Residue and modType ~= sgs.TargetModSkill_DistanceLimit then return nil end
        local from = ctx:getPrimary()
        local to = ctx:getSecondary()
        if from and not from:hasSkill("sijyu_zhizhi") and to and to:getMark("&sijyu_zhizhi_lun") > 0 then
            return 1000
        end
        return nil
    end,
}
sijyu_zhizhiDraw = sgs.CreateTriggerSkillV2 {
    name = "#sijyu_zhizhiDraw",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Damage },
    can_trigger = function(skill, event, room, player, data)
        if not player then return false end
        local damage = data:toDamage()
        if not damage.to or damage.to:getMark("&sijyuzhizhi_lun") == 0 then return false end
        if not damage.from or damage.from:objectName() == damage.to:objectName()
            or player:objectName() ~= damage.from:objectName() then
            return false
        end
        local trigger_list_skill, trigger_list_who = {}, {}
        for _, p in sgs.qlist(room:findPlayersBySkillName("sijyu_zhizhi")) do
            if p:objectName() ~= damage.from:objectName() then
                table.insert(trigger_list_skill, skill:objectName())
                table.insert(trigger_list_who, p:objectName())
            end
        end
        if #trigger_list_skill > 0 then
            return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local damage = ctx.original_data:toDamage()
        room:sendCompulsoryTriggerLog(player, "sijyu_zhizhi")
        ctx.invoker:drawCards(1, skill:objectName())
        player:drawCards(1, skill:objectName())
        return false
    end,
}
addToSkills(sijyu_zhizhi)
addToSkills(sijyu_zhizhiBuff)
addToSkills(sijyu_zhizhiDraw)
extension_lost:insertRelatedSkills("sijyu_zhizhi", "#sijyu_zhizhiBuff")
extension_lost:insertRelatedSkills("sijyu_zhizhi", "#sijyu_zhizhiDraw")
sijyu_yuanshao:addRelateSkill("sijyu_zhizhi")
--[[
	技能名：中兴
	相关武将：袁紹
	技能描述：锁定技，当你失去最后的手牌后，你将手牌补至体力上限；\
    当你的牌被弃置后，若弃牌数大于你的手牌数，你摸等同弃牌数张的牌。
	引用：sijyu_zhongxing
]] --

sijyu_zhongxing = sgs.CreateTriggerSkillV2 {
    name = "sijyu_zhongxing",
    events = { sgs.CardsMoveOneTime },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then
            return skill:objectName(), player
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local move = ctx.original_data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
            player:drawCards(player:getMaxHp() - player:getHandcardNum(), skill:objectName())
            room:sendCompulsoryTriggerLog(player, skill:objectName())
        end
        if (event == sgs.CardsMoveOneTime) then
            local move = ctx.original_data:toMoveOneTime()
            if move.from
                and (move.card_ids:length() > player:getHandcardNum())
                and (move.from:objectName() == player:objectName())
                and (not move.from_places:contains(sgs.Player_PlaceJudge))
                and (
                    (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
                    or ((move.to_place == sgs.Player_PlaceHand) and move.to and (move.to:objectName() ~= move.from:objectName()))
                ) then
                room:sendCompulsoryTriggerLog(player, skill:objectName())
                player:drawCards(move.card_ids:length(), skill:objectName())
            end
        end
        return false
    end
}
addToSkills(sijyu_zhongxing)
sijyu_yuanshao:addRelateSkill("sijyu_zhongxing")

--[[
	技能名：利剑
	相关武将：袁紹
	技能描述：其他角色的防具于你回合内无效；\
    每当你造成伤害时，你可以令此伤害+1，然后受伤角色摸一张牌。\
    当你受到伤害时，你可以弃置一张牌令此伤害-1；\
    若你装备区没有武器牌，你的攻击范围+1。",
	引用：sijyu_lijian
]] --
sijyu_lijianBuff = sgs.CreateAttackRangeSkillV2 {
    name = "#sijyu_lijianBuff",
    holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local n = 0
        local target = ctx:getPrimary()
        if target and target:hasSkill("sijyu_lijian") and not target:getWeapon() then
            n = n + 1
        end
        return n
    end
}

sijyu_lijian = sgs.CreateTriggerSkillV2 {
    name = "sijyu_lijian",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.DamageInflicted, sgs.DamageCaused, sgs.EventPhaseStart, sgs.EventPhaseChanging },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if (event == sgs.DamageCaused) then
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() then
                return skill:objectName(), player
            end
        elseif (event == sgs.DamageInflicted) then
            if player:canDiscard(player, "he") then
                return skill:objectName(), player
            end
        elseif (event == sgs.EventPhaseStart) then
            if player:getPhase() == sgs.Player_Start then
                return skill:objectName(), player
            end
        elseif (event == sgs.EventPhaseChanging) then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if (event == sgs.DamageCaused) then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
        elseif (event == sgs.DamageInflicted) then
            if room:askForDiscard(player, "sijyu_lijian", 1, 1, true, true, "@sijyu_lijian:") then
                room:broadcastSkillInvoke(skill:objectName())
                return true
            end
            return false
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        local data = ctx.original_data
        if (event == sgs.DamageCaused) then
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            damage.to:drawCards(1, skill:objectName())
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            data:setValue(damage)
        elseif (event == sgs.DamageInflicted) then
            local damage = data:toDamage()
            damage.damage = damage.damage - 1
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            data:setValue(damage)
        elseif (event == sgs.EventPhaseStart) then
            if player:getPhase() == sgs.Player_Start then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:addPlayerMark(p, "&" .. skill:objectName() .. "-Clear")
                    p:addEquipsNullified("EquipCard")
                end
            end
        elseif (event == sgs.EventPhaseChanging) then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:setPlayerMark(p, "&" .. skill:objectName() .. "-Clear", 0)
                p:removeEquipsNullified("EquipCard")
            end
        end
        return false
    end,
}
addToSkills(sijyu_lijianBuff)
addToSkills(sijyu_lijian)
extension_lost:insertRelatedSkills("sijyu_lijian", "#sijyu_lijianBuff")
sijyu_yuanshao:addRelateSkill("sijyu_lijian")
--[[
	技能名：思召
	相关武将：袁紹
	技能描述：出牌阶段限一次，你可以与一名其他角色拼点：若你赢，你将体力回复至体力上限且摸等量的牌；
    若你没赢，则你每造成一次伤害后，若你已受伤，你回复1点体力，否则你增加1点体力上限。
	引用：sijyu_sizhao
]] --

sijyu_sizhaoCard = sgs.CreateSkillCard {
    name = "sijyu_sizhao",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0
            and (not to_select:isKongcheng()) and (to_select:objectName() ~= player:objectName())
            and (player:canPindian(to_select, true))
    end,
    on_use = function(self, room, player, targets)
        local target = targets[1]
        local success = player:pindian(target, "sijyu_sizhao", nil)
        if success then
            local x = player:getLostHp()
            local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = x
            room:recover(player, recover)
            player:drawCards(x, self:objectName())
        else
            room:addPlayerMark(player, "&" .. self:objectName() .. "-Clear")
        end
    end
}

sijyu_sizhaoVS = sgs.CreateViewAsSkillV2 {
    name = "sijyu_sizhao",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and player and player:isAlive()
            and not (player:hasUsed("#sijyu_sizhao"))
    end,
    create_card = function(skill, request)
        return sijyu_sizhaoCard:clone()
    end,
    pay = function(skill, room, context, request)
        -- V2 產生的 SkillCard 以技能名入 history；舊版 SkillCard 以 "#"＋牌名入 history。
        -- AI 及 can_activate 皆檢查 "#sijyu_sizhao"，補回該 history key。
        local player = request:getInitiator()
        if player then
            room:addPlayerHistory(player, "#sijyu_sizhao", 1)
        end
        return true
    end,
}
sijyu_sizhao = sgs.CreateTriggerSkillV2 {
    name = "sijyu_sizhao",
    events = { sgs.Damage },
    view_as_skill = sijyu_sizhaoVS,
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.Damage and player and player:isAlive()
            and player:getMark("&" .. skill:objectName() .. "-Clear") > 0 then
            return skill:objectName(), player
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(player, skill:objectName())
        if player:isWounded() then
            room:recover(player, sgs.RecoverStruct(player))
        else
            room:gainMaxHp(player)
        end
        return false
    end,
}
addToSkills(sijyu_sizhao)
sijyu_yuanshao:addRelateSkill("sijyu_sizhao")


sijyu_jiangwei = sgs.General(extension_lost, "sijyu_jiangwei", "shu", 4, true)
--[[
	技能名：搦战
	相关武将：姜维
	技能描述：每轮每名角色限一次，一名角色结束阶段，若其本回合出牌阶段未造成过伤害，你获得一个“战”。回合结束，你可移去一个“战”并执行一额外回合。
	引用：sijyu_nuozhan
]] --
sijyu_nuozhan = sgs.CreateTriggerSkillV2 {
    name = "sijyu_nuozhan",
    events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
    can_trigger = function(skill, event, room, player, data)
        if event ~= sgs.EventPhaseStart or not player then return false end
        if player:getPhase() == sgs.Player_Finish and player:getMark("damage_point_play_phase") == 0 and player:getMark("sijyu_nuozhan_lun") == 0 then
            local trigger_list_skill, trigger_list_who = {}, {}
            for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
                table.insert(trigger_list_skill, skill:objectName())
                table.insert(trigger_list_who, p:objectName())
            end
            if #trigger_list_skill > 0 then
                return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
            end
        end
        if player:getPhase() == sgs.Player_NotActive and player:getMark("&sijyuzhan") > 0 then
            return skill:objectName(), player
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        if ctx.invoker:getPhase() == sgs.Player_Finish then
            room:addPlayerMark(ctx.invoker, "sijyu_nuozhan_lun")
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            player:gainMark("&sijyuzhan")
        else
            if player:getMark("sijyu_nuozhan_using") == 0 then
                while player:getMark("&sijyuzhan") > 0 do
                    if room:askForSkillInvoke(player, skill:objectName()) then
                        room:broadcastSkillInvoke(skill:objectName())
                        room:removePlayerMark(player, "&sijyuzhan")
                        room:addPlayerMark(player, "sijyu_nuozhan_using")
                        player:gainAnExtraTurn()
                        room:setPlayerMark(player, "sijyu_nuozhan_using", 0)
                    else
                        break
                    end
                end
            end
        end
        return false
    end,
}


sijyu_jiangwei:addSkill(sijyu_nuozhan)



--[[
	技能名：兴汉
	相关武将：姜维
	技能描述：使命技，游戏开始你选择一名其他角色，当其受到伤害后你获得一个“战”。\
        成功：杀死一名角色，你获得[ol界挑衅][界观星]\
        失败：你或选择的角色进入濒死状态，其回复体力至一点，你获得[死战]并结束当前回合。
	引用：sijyu_xinghan
]] --

sijyu_xinghan = sgs.CreateTriggerSkillV2 {
    name = "sijyu_xinghan",
    shiming_skill = true,
    events = { sgs.Dying, sgs.Death, sgs.GameStart, sgs.Damaged },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if event == sgs.GameStart then
            -- 舊版 owners = {player}：僅處理事件目標自身的實例。
            if not player:hasSkill(skill:objectName()) then return false end
            local names = {}
            for _, id in sgs.qlist(player:getValidSkillInstanceIds(skill:objectName())) do
                local ref = sgs.SkillInstanceRef(player:objectName(), sgs.SkillInstanceKey(skill:objectName(), id))
                if room:getShimingStatus(ref) == 0 then
                    table.insert(names, ref.key:toString())
                end
            end
            if #names == 0 then return false end
            room:addPlayerMark(player, "sijyu_xinghan+sys_+_force")
            return table.concat(names, "+")
        end
        -- 其餘事件舊版逐一檢查所有持有者實例；format-2 依實例精確生成 context。
        local trigger_list_skill, trigger_list_who = {}, {}
        local marked_owners = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
            for _, id in sgs.qlist(owner:getValidSkillInstanceIds(skill:objectName())) do
                local ref = sgs.SkillInstanceRef(owner:objectName(), sgs.SkillInstanceKey(skill:objectName(), id))
                if room:getShimingStatus(ref) == 0 then
                    local partner = owner:getSkillInstanceStateValue(skill:objectName(), id, "partner"):toString()
                    local matched = false
                    if event == sgs.Damaged then
                        local damage = data:toDamage()
                        matched = damage.to ~= nil and damage.to:objectName() == partner
                    elseif event == sgs.Death then
                        local death = data:toDeath()
                        matched = death.damage ~= nil and death.damage.from == player
                            and (owner == player or partner == player:objectName())
                    elseif event == sgs.Dying then
                        local who = room:getCurrentDyingPlayer()
                        matched = who ~= nil and (who == owner or who:objectName() == partner)
                    end
                    if matched then
                        table.insert(trigger_list_skill, ref.key:toString())
                        table.insert(trigger_list_who, owner:objectName())
                        if not marked_owners[owner] then
                            marked_owners[owner] = true
                            room:addPlayerMark(owner, "sijyu_xinghan+sys_+_force")
                        end
                    end
                end
            end
        end
        if #trigger_list_skill == 0 then return false end
        return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
    end,
    on_cost = function(skill, event, room, player, ctx)
        room:setPlayerMark(player, "sijyu_xinghan+sys_+_force", 0)
        if event ~= sgs.GameStart and room:getShimingStatus(ctx:getActivationRef()) ~= 0 then return false end
        if event == sgs.Damaged then
            local partner = player:getSkillInstanceStateValue(skill:objectName(), ctx.instanceID, "partner"):toString()
            local damage = ctx.original_data:toDamage()
            return damage.to ~= nil and damage.to:objectName() == partner
        elseif event == sgs.Death then
            local partner = player:getSkillInstanceStateValue(skill:objectName(), ctx.instanceID, "partner"):toString()
            local death = ctx.original_data:toDeath()
            return death.damage ~= nil and death.damage.from == ctx.invoker
                and (player == ctx.invoker or partner == ctx.invoker:objectName())
        elseif event == sgs.Dying then
            local partner = player:getSkillInstanceStateValue(skill:objectName(), ctx.instanceID, "partner"):toString()
            local who = room:getCurrentDyingPlayer()
            return who ~= nil and (who == player or who:objectName() == partner)
        end
        return true
    end,
    on_effect = function(skill, event, room, player, ctx)
        local id = ctx.instanceID
        if event == sgs.GameStart then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@sijyu_xinghan-start", false, true)
            if target and player:hasSkillInstance(skill:objectName(), id) then
                player:setSkillInstanceStateValue(skill:objectName(), id, "partner", sgs.QVariant(target:objectName()))
                target:gainMark("&sijyu_xinghan+#" .. player:objectName() .. "+" .. id .. "_num")
                room:broadcastSkillInvoke(skill:objectName(), 1)
            end
        elseif event == sgs.Damaged then
            room:sendCompulsoryTriggerLog(player, skill:objectName())
            room:broadcastSkillInvoke(skill:objectName(), 4)
            room:addPlayerMark(player, "&sijyuzhan")
        elseif event == sgs.Death then
            if room:sendShimingLog(ctx:getActivationRef()) then
                room:handleAcquireDetachSkills(player, "oltiaoxin|tenyearguanxing")
            end
        elseif event == sgs.Dying then
            local who = room:getCurrentDyingPlayer()
            if who and room:sendShimingLog(ctx:getActivationRef(), false) then
                local recover = math.min(1 - who:getHp(), who:getMaxHp() - who:getHp())
                room:recover(who, sgs.RecoverStruct(player, nil, recover))
                room:handleAcquireDetachSkills(player, "sijyu_sizhan")
                room:setPlayerMark(ctx.invoker, "sijyu_nuozhan_using", 0)
                room:throwEvent(sgs.TurnBroken)
            end
        end
        return false
    end,
    on_shiming_success = function(skill, room, player, ref)
        ShimingSkillDoAnimate(skill, player, true, "sijyu_jiangwei")
    end,
    on_shiming_fail = function(skill, room, player, ref)
        ShimingSkillDoAnimate(skill, player, false, "keolmoujiangwei")
    end,
}

sijyu_jiangwei:addSkill(sijyu_xinghan)
sijyu_jiangwei:addRelateSkill("oltiaoxin")
sgs.Sanguosha:setAudioType("sijyu_jiangwei", "tenyearguanxing", "3,4")
sijyu_jiangwei:addRelateSkill("tenyearguanxing")

--[[
	技能名：死战
	相关武将：姜维
	技能描述：锁定技，其他角色回合结束，你失去一体力上限并执行一额外回合。
	引用：sijyu_sizhan
]] --
sijyu_sizhan = sgs.CreateTriggerSkillV2 {
    name = "sijyu_sizhan",
    events = { sgs.EventPhaseStart },
    can_trigger = function(skill, event, room, player, data)
        if event ~= sgs.EventPhaseStart or not player or player:getPhase() ~= sgs.Player_NotActive then
            return false
        end
        local trigger_list_skill, trigger_list_who = {}, {}
        for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
            if p:objectName() ~= player:objectName() then
                table.insert(trigger_list_skill, skill:objectName())
                table.insert(trigger_list_who, p:objectName())
            end
        end
        if #trigger_list_skill == 0 then return false end
        return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:sendCompulsoryTriggerLog(player, skill:objectName())
        room:broadcastSkillInvoke(skill:objectName())
        room:loseMaxHp(player)
        if player:isAlive() and player:getMark("sijyu_nuozhan_using") == 0 then
            room:addPlayerMark(player, "sijyu_nuozhan_using")
            player:gainAnExtraTurn()
            room:setPlayerMark(player, "sijyu_nuozhan_using", 0)
            room:getThread():trigger(sgs.EventPhaseStart, room, player, sgs.QVariant())
        end
        return false
    end,
}
addToSkills(sijyu_sizhan)
sijyu_jiangwei:addRelateSkill("sijyu_sizhan")

sijyu_zhugeliang = sgs.General(extension_lost, "sijyu_zhugeliang", "shu", 4, true, false, false, 1)

--[[
	技能名：七星
	相关武将：诸葛亮
	技能描述：锁定技，你的起始手牌数+7。分发起始手牌后，你将其中七张扣置于武将牌旁，称为“星”。出牌阶段开始时，你令一角色获得所有“星”并将等量牌成为“星”。当你进入濒死时，你回复体力至1点并进行判定，若点数与“星”均不同，你失去1点体力上限。
	引用：sijyu_qixing
]] --


sijyu_qixing = sgs.CreateTriggerSkillV2 {
    name = "sijyu_qixing",
    events = { sgs.EventPhaseStart },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(skill, event, room, player, data)
        if player and player:isAlive() and player:getPile("sijyu_xing"):length() > 0
            and player:getPhase() == sgs.Player_Play then
            return skill:objectName(), player
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:broadcastSkillInvoke("sijyu_qixing", math.random(1, 2))
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(),
            "sijyu_qixing-invoke", false, true)
        local dummy = sgs.Sanguosha:cloneCard("slash")
        dummy:addSubcards(player:getPile("sijyu_xing"))
        if dummy:subcardsLength() > 0 then
            target:obtainCard(dummy)
        end
        local exchange_card = room:askForExchange(target, "sijyu_qixing", dummy:subcardsLength(), dummy:subcardsLength())
        dummy:deleteLater()
        local players = sgs.SPlayerList()
        players:append(player)
        player:addToPile("sijyu_xing", exchange_card:getSubcards(), false, players)
        exchange_card:deleteLater()
        return false
    end,
}

sijyu_qixingStart = sgs.CreateTriggerSkillV2 {
    name = "#sijyu_qixingStart",
    events = { sgs.DrawNCards, sgs.AfterDrawNCards },
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        local draw = data:toDraw()
        if draw.reason ~= "InitialHandCards" then return false end
        return skill:objectName(), player
    end,
    on_effect = function(skill, event, room, player, ctx)
        local draw = ctx.original_data:toDraw()
        if event == sgs.DrawNCards then
            room:sendCompulsoryTriggerLog(player, "sijyu_qixing")
            draw.num = draw.num + 7
            ctx.original_data:setValue(draw)
        elseif event == sgs.AfterDrawNCards then
            local exchange_card = room:askForExchange(player, "sijyu_qixing", 7, 7)
            room:broadcastSkillInvoke("sijyu_qixing", 1)
            player:addToPile("sijyu_xing", exchange_card:getSubcards(), false)
            exchange_card:deleteLater()
        end
        return false
    end,
}
sijyu_qixingDying = sgs.CreateTriggerSkillV2 {
    name = "#sijyu_qixingDying",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.EnterDying },
    can_trigger = function(skill, event, room, player, data)
        if not player then return false end
        local who = room:getCurrentDyingPlayer()
        if who and who:objectName() == player:objectName() then
            return skill:objectName(), player
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        room:broadcastSkillInvoke("sijyu_qixing", math.random(3, 4))
        room:sendCompulsoryTriggerLog(player, "sijyu_qixing")
        local recover = sgs.RecoverStruct()
        recover.recover = 1 - player:getHp()
        recover.who = player
        room:recover(player, recover)
        local number = {}
        for _, id in sgs.qlist(player:getPile("sijyu_xing")) do
            if not table.contains(number, sgs.Sanguosha:getCard(id):getNumberString()) then
                table.insert(number, sgs.Sanguosha:getCard(id):getNumberString())
            end
        end
        local judge = sgs.JudgeStruct()
        judge.pattern = ".|.|" .. table.concat(number, ",")
        judge.who = player
        judge.reason = "sijyu_qixing"
        --judge.good = false
        room:judge(judge)
        if judge:isBad() then
            room:loseMaxHp(player)
        end
        return false
    end,
}

sijyu_zhugeliang:addSkill(sijyu_qixing)
sijyu_zhugeliang:addSkill(sijyu_qixingStart)
sijyu_zhugeliang:addSkill(sijyu_qixingDying)
extension_lost:insertRelatedSkills("sijyu_qixing", "#sijyu_qixingStart")
extension_lost:insertRelatedSkills("sijyu_qixing", "#sijyu_qixingDying")


--[[
	技能名：伐北
	相关武将：诸葛亮
	技能描述：锁定技，你以此法以外当前回合获得的牌进入弃牌堆后你将其置于武将牌上称为“伐”。其他角色准备阶段，你获得所有“伐”，失去1点体力并进行一个额外的出牌阶段。
	引用：sijyu_fabei
]] --


sijyu_fabei = sgs.CreateTriggerSkillV2 {
    name = "sijyu_fabei",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() then return false end
        if (event == sgs.CardsMoveOneTime) then
            local move = data:toMoveOneTime()
            if move.to_place == sgs.Player_PlaceHand
                and move.reason.m_skillName ~= "InitialHandCards"
                and not (move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial)
				and move.from_pile_names and table.contains(move.from_pile_names, "sijyu_fa"))
                and move.to:objectName() == player:objectName() and player:hasSkill(skill:objectName(), true) then
                return skill:objectName(), player
            elseif move.to_place == sgs.Player_DiscardPile then
                for _, card_id in sgs.qlist(move.card_ids) do
                    if player:getMark("sijyu_fabei:" .. card_id .. "-Clear") > 0 then
                        return skill:objectName(), player
                    end
                end
            end
            return false
        elseif (event == sgs.EventPhaseChanging) then
            local change = data:toPhaseChange()
            if (change.from == sgs.Player_Start) then
                local trigger_list_skill, trigger_list_who = {}, {}
                for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
                    if p:objectName() ~= player:objectName() and p:getPile("sijyu_fa"):length() > 0 then
                        table.insert(trigger_list_skill, skill:objectName())
                        table.insert(trigger_list_who, p:objectName())
                    end
                end
                if #trigger_list_skill > 0 then
                    return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
                end
            end
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        if (event == sgs.CardsMoveOneTime) then
            local move = ctx.original_data:toMoveOneTime()
            if move.to_place == sgs.Player_PlaceHand then
                for _, id in sgs.list(move.card_ids) do
                    room:setCardTip(id, "sijyu_fabei-Clear")
                    room:setPlayerMark(player, "sijyu_fabei:" .. id .. "-Clear", 1)
                end
            elseif move.to_place == sgs.Player_DiscardPile then
                local card_ids = sgs.IntList()
                for _, card_id in sgs.qlist(move.card_ids) do
                    if player:getMark("sijyu_fabei:" .. card_id .. "-Clear") > 0 then
                        card_ids:append(card_id)
                    end
                end
                if not card_ids:isEmpty() then
                    player:addToPile("sijyu_fa", card_ids, true)
                end
            end
        elseif (event == sgs.EventPhaseChanging) then
            local dummy = sgs.Sanguosha:cloneCard("slash")
            dummy:addSubcards(player:getPile("sijyu_fa"))
            if dummy:subcardsLength() > 0 then
                player:obtainCard(dummy)
            end
            dummy:deleteLater()
            room:loseHp(player, 1, true, player, skill:objectName())
            room:broadcastSkillInvoke("sijyu_fabei")
            if player:isAlive() then
                local phases = sgs.PhaseList()
                phases:append(sgs.Player_Play)
                player:play(phases)
            end
        end
        return false
    end,
}
sijyu_zhugeliang:addSkill(sijyu_fabei)

--[[
	技能名：逢懿
	相关武将：诸葛亮
	技能描述：你可以用一张“星”替换判定牌并令其立即生效。当你死亡后，你可以将所有“星”交给一名角色并令其翻面。
	引用：sijyu_fengyi
]] --

sijyu_fengyiCard = sgs.CreateSkillCard {
    name = "sijyu_fengyiCard",
    target_fixed = true,
    will_throw = false,
}

sijyu_fengyiVS = sgs.CreateViewAsSkillV2 {
    name = "sijyu_fengyi",
    n = 1,
    expand_pile = "sijyu_xing",
    can_activate = function(skill, request)
        local reason = request:getReason()
        return (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
            and request:getPattern() == "@@sijyu_fengyi"
    end,
    can_select_card = function(skill, request, card)
        local player = request:getInitiator()
        return card ~= nil and player ~= nil
            and player:getPile("sijyu_xing"):contains(card:getEffectiveId())
    end,
    card_selection_feasible = function(skill, request)
        return request:getSelectedCardIds():length() == 1
    end,
    create_card = function(skill, request)
        local card = sijyu_fengyiCard:clone()
        card:addSubcard(request:getSelectedCardIds():first())
        card:setSkillName(skill:objectName())
        return card
    end,
}
sijyu_fengyi = sgs.CreateTriggerSkillV2 {
    name = "sijyu_fengyi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.AskForRetrial, sgs.Death },
    view_as_skill = sijyu_fengyiVS,
    can_trigger = function(skill, event, room, player, data)
        if not player then return false end
        if event == sgs.AskForRetrial then
            if player:isAlive() and player:getPile("sijyu_xing"):length() > 0 then
                return skill:objectName(), player
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            -- 舊版 triggerable 要求 dispatch 目標存活，死亡者自身永不滿足
            -- death.who == player，故此分支為 dead code；保留同樣語義。
            if player:isAlive() and death.who and death.who:objectName() == player:objectName()
                and player:getPile("sijyu_xing"):length() > 0 then
                return skill:objectName(), player
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.AskForRetrial then
            local judge = ctx.original_data:toJudge()
            local prompt = string.format("@sijyu_fengyi-card:%s:%s:%s", judge.who:objectName(), skill:objectName(),
                judge.reason) --%src,%dest,%arg
            local card = room:askForCard(player, "@@sijyu_fengyi", prompt, ctx.original_data, sgs.Card_MethodResponse,
                nil, true)
            if card then
                ctx.extra_data:setValue(card)
                return true
            end
            return false
        elseif event == sgs.Death then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(),
                "sijyu_fengyi-invoke", true, true)
            if target then
                ctx.extra_data:setValue(target)
                return true
            end
            return false
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.AskForRetrial then
            local judge = ctx.original_data:toJudge()
            room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
            room:retrial(ctx.extra_data:toCard(), player, judge, skill:objectName())
            return true
        elseif event == sgs.Death then
            local target = ctx.extra_data:toPlayer()
            room:broadcastSkillInvoke("sijyu_fengyi", 3)
            local dummy = sgs.Sanguosha:cloneCard("slash")
            dummy:addSubcards(player:getPile("sijyu_xing"))
            if dummy:subcardsLength() > 0 then
                target:obtainCard(dummy)
            end
            dummy:deleteLater()
            target:turnOver()
        end
        return false
    end
}

sijyu_zhugeliang:addSkill(sijyu_fengyi)




return { extension, extension_lost }
