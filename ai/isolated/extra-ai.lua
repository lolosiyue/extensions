-- Fixed b6025acc extra-ai.lua:2998–3007. This focused module ports the
-- heg_congjian damage callbacks; it does not claim the rest of extra-ai.
local function phase(player)
    if player == nil then error("attempt to index a nil value", 0) end
    if type(player.getPhase) ~= "function" then ai_unsupported("heg_congjian phase helper absent", "heg_congjian") end
    local value = player:getPhase()
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil then ai_unsupported("heg_congjian public phase is unknown", "heg_congjian") end
    return value
end
sgs.ai_ajustdamage_from.heg_congjian = function(self, from, to, card, nature)
    if from and phase(from) == sgs.Player_NotActive then return 1 end
end
sgs.ai_ajustdamage_to.heg_congjian = function(self, from, to, card, nature)
    if phase(to) ~= sgs.Player_NotActive then return 1 end
end

local prior_extra_hooks,prior_extra_typed_uses={},{}
prior_extra_hooks["ai_ajustdamage_from.PeaceSpell"]=sgs.ai_ajustdamage_from["PeaceSpell"]
prior_extra_hooks["ai_ajustdamage_from.heg_congjian"]=sgs.ai_ajustdamage_from["heg_congjian"]
prior_extra_hooks["ai_ajustdamage_from.heg_ejue"]=sgs.ai_ajustdamage_from["heg_ejue"]
prior_extra_hooks["ai_ajustdamage_from.heg_fengshih"]=sgs.ai_ajustdamage_from["heg_fengshih"]
prior_extra_hooks["ai_ajustdamage_from.heg_mobile_liegong"]=sgs.ai_ajustdamage_from["heg_mobile_liegong"]
prior_extra_hooks["ai_ajustdamage_from.heg_suzhi"]=sgs.ai_ajustdamage_from["heg_suzhi"]
prior_extra_hooks["ai_ajustdamage_from.heg_xinghuo"]=sgs.ai_ajustdamage_from["heg_xinghuo"]
prior_extra_hooks["ai_ajustdamage_from.heg_xiongnve"]=sgs.ai_ajustdamage_from["heg_xiongnve"]
prior_extra_hooks["ai_ajustdamage_from.heg_zhuosheng"]=sgs.ai_ajustdamage_from["heg_zhuosheng"]
prior_extra_hooks["ai_ajustdamage_to.&gd_xujiu"]=sgs.ai_ajustdamage_to["&gd_xujiu"]
prior_extra_hooks["ai_ajustdamage_to.heg_congjian"]=sgs.ai_ajustdamage_to["heg_congjian"]
prior_extra_hooks["ai_ajustdamage_to.heg_fengshih"]=sgs.ai_ajustdamage_to["heg_fengshih"]
prior_extra_hooks["ai_ajustdamage_to.heg_nos_yuanyu"]=sgs.ai_ajustdamage_to["heg_nos_yuanyu"]
prior_extra_hooks["ai_ajustdamage_to.heg_xiongnve"]=sgs.ai_ajustdamage_to["heg_xiongnve"]
prior_extra_hooks["ai_ajustdamage_to.heg_yuanyu"]=sgs.ai_ajustdamage_to["heg_yuanyu"]
prior_extra_hooks["ai_ajustdamage_to.twyj_baimei"]=sgs.ai_ajustdamage_to["twyj_baimei"]
prior_extra_hooks["ai_armor_value.heg_lord_hongfa"]=sgs.ai_armor_value["heg_lord_hongfa"]
prior_extra_hooks["ai_armor_value.heg_lord_wendao"]=sgs.ai_armor_value["heg_lord_wendao"]
prior_extra_hooks["ai_armor_value.heg_lord_zongyu"]=sgs.ai_armor_value["heg_lord_zongyu"]
prior_extra_hooks["ai_canNiepan_skill.heg_lord_jizhao"]=sgs.ai_canNiepan_skill["heg_lord_jizhao"]
prior_extra_hooks["ai_canNiepan_skill.heg_ov_shigong"]=sgs.ai_canNiepan_skill["heg_ov_shigong"]
prior_extra_hooks["ai_can_damagehp.heg_fudi"]=sgs.ai_can_damagehp["heg_fudi"]
prior_extra_hooks["ai_can_damagehp.heg_nos_quanji"]=sgs.ai_can_damagehp["heg_nos_quanji"]
prior_extra_hooks["ai_can_damagehp.heg_quanji"]=sgs.ai_can_damagehp["heg_quanji"]
prior_extra_hooks["ai_canliegong_skill.heg_chujue"]=sgs.ai_canliegong_skill["heg_chujue"]
prior_extra_hooks["ai_canliegong_skill.heg_mobile_liegong"]=sgs.ai_canliegong_skill["heg_mobile_liegong"]
prior_extra_hooks["ai_canliegong_skill.heg_nos_xiaoni"]=sgs.ai_canliegong_skill["heg_nos_xiaoni"]
prior_extra_hooks["ai_canliegong_skill.heg_ol_liegong"]=sgs.ai_canliegong_skill["heg_ol_liegong"]
prior_extra_hooks["ai_card_intention.heg_await_exhausted"]=sgs.ai_card_intention["heg_await_exhausted"]
prior_extra_hooks["ai_card_intention.heg_befriend_attacking"]=sgs.ai_card_intention["heg_befriend_attacking"]
prior_extra_hooks["ai_card_intention.heg_huyuan"]=sgs.ai_card_intention["heg_huyuan"]
prior_extra_hooks["ai_card_intention.heg_yanxi"]=sgs.ai_card_intention["heg_yanxi"]
prior_extra_hooks["ai_card_intention.twyj_huzhu"]=sgs.ai_card_intention["twyj_huzhu"]
prior_extra_hooks["ai_card_priority.guandu_shicai"]=sgs.ai_card_priority["guandu_shicai"]
prior_extra_hooks["ai_card_priority.heg_guishu"]=sgs.ai_card_priority["heg_guishu"]
prior_extra_hooks["ai_card_priority.heg_longdan"]=sgs.ai_card_priority["heg_longdan"]
prior_extra_hooks["ai_card_priority.heg_nos_guishu"]=sgs.ai_card_priority["heg_nos_guishu"]
prior_extra_hooks["ai_cardneed.heg_duanliang"]=sgs.ai_cardneed["heg_duanliang"]
prior_extra_hooks["ai_cardneed.heg_shensu"]=sgs.ai_cardneed["heg_shensu"]
prior_extra_hooks["ai_cardsview.heg_lord_hongfa_Attach"]=sgs.ai_cardsview["heg_lord_hongfa_Attach"]
prior_extra_hooks["ai_choicemade_filter.cardResponded.@guandu_jieliang"]=sgs.ai_choicemade_filter["cardResponded"]["@guandu_jieliang"]
prior_extra_hooks["ai_choicemade_filter.cardResponded.@heg_zhulan"]=sgs.ai_choicemade_filter["cardResponded"]["@heg_zhulan"]
prior_extra_hooks["ai_choicemade_filter.skillChoice.heg_lianpian"]=sgs.ai_choicemade_filter["skillChoice"]["heg_lianpian"]
prior_extra_hooks["ai_choicemade_filter.skillChoice.heg_nos_daming"]=sgs.ai_choicemade_filter["skillChoice"]["heg_nos_daming"]
prior_extra_hooks["ai_choicemade_filter.skillChoice.yinghun_po"]=sgs.ai_choicemade_filter["skillChoice"]["yinghun_po"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.bf_sec_tiaodu"]=sgs.ai_choicemade_filter["skillInvoke"]["bf_sec_tiaodu"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.bf_third_tiaodu"]=sgs.ai_choicemade_filter["skillInvoke"]["bf_third_tiaodu"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.bf_tiaodu"]=sgs.ai_choicemade_filter["skillInvoke"]["bf_tiaodu"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.bf_yuejian"]=sgs.ai_choicemade_filter["skillInvoke"]["bf_yuejian"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.chenggong"]=sgs.ai_choicemade_filter["skillInvoke"]["chenggong"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.guandu_fuyuan"]=sgs.ai_choicemade_filter["skillInvoke"]["guandu_fuyuan"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_chenglue"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_chenglue"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_hengjiang"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_hengjiang"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_huaiyuan"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_huaiyuan"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_jujian"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_jujian"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_mobile_bushi"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_mobile_bushi"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_mobile_jiancai"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_mobile_jiancai"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_mobile_zhuwei"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_mobile_zhuwei"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_qiao"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_qiao"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_tenyear_zhuwei"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_tenyear_zhuwei"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_tongdu"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_tongdu"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_true_jiancai"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_true_jiancai"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_true_pozhen"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_true_pozhen"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_yicheng"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_yicheng"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.heg_zhuwei"]=sgs.ai_choicemade_filter["skillInvoke"]["heg_zhuwei"]
prior_extra_hooks["ai_choicemade_filter.skillInvoke.twyj_huzhu"]=sgs.ai_choicemade_filter["skillInvoke"]["twyj_huzhu"]
prior_extra_hooks["ai_fill_skill.bf_nos_tiaodu"]=sgs.ai_fill_skill["bf_nos_tiaodu"]
prior_extra_hooks["ai_fill_skill.bf_qice"]=sgs.ai_fill_skill["bf_qice"]
prior_extra_hooks["ai_fill_skill.bf_xiongsuan"]=sgs.ai_fill_skill["bf_xiongsuan"]
prior_extra_hooks["ai_fill_skill.bf_yongjin"]=sgs.ai_fill_skill["bf_yongjin"]
prior_extra_hooks["ai_fill_skill.gd_zezhu"]=sgs.ai_fill_skill["gd_zezhu"]
prior_extra_hooks["ai_fill_skill.guandu_shicai"]=sgs.ai_fill_skill["guandu_shicai"]
prior_extra_hooks["ai_fill_skill.guandu_yuanlue"]=sgs.ai_fill_skill["guandu_yuanlue"]
prior_extra_hooks["ai_fill_skill.heg_chengliu"]=sgs.ai_fill_skill["heg_chengliu"]
prior_extra_hooks["ai_fill_skill.heg_duanliang"]=sgs.ai_fill_skill["heg_duanliang"]
prior_extra_hooks["ai_fill_skill.heg_duanxie"]=sgs.ai_fill_skill["heg_duanxie"]
prior_extra_hooks["ai_fill_skill.heg_duwu"]=sgs.ai_fill_skill["heg_duwu"]
prior_extra_hooks["ai_fill_skill.heg_fengying"]=sgs.ai_fill_skill["heg_fengying"]
prior_extra_hooks["ai_fill_skill.heg_guikuang"]=sgs.ai_fill_skill["heg_guikuang"]
prior_extra_hooks["ai_fill_skill.heg_guishu"]=sgs.ai_fill_skill["heg_guishu"]
prior_extra_hooks["ai_fill_skill.heg_huaiyi"]=sgs.ai_fill_skill["heg_huaiyi"]
prior_extra_hooks["ai_fill_skill.heg_jianglue"]=sgs.ai_fill_skill["heg_jianglue"]
prior_extra_hooks["ai_fill_skill.heg_jiaping_Attach"]=sgs.ai_fill_skill["heg_jiaping_Attach"]
prior_extra_hooks["ai_fill_skill.heg_jinfa"]=sgs.ai_fill_skill["heg_jinfa"]
prior_extra_hooks["ai_fill_skill.heg_jinghe"]=sgs.ai_fill_skill["heg_jinghe"]
prior_extra_hooks["ai_fill_skill.heg_kurou"]=sgs.ai_fill_skill["heg_kurou"]
prior_extra_hooks["ai_fill_skill.heg_longdan"]=sgs.ai_fill_skill["heg_longdan"]
prior_extra_hooks["ai_fill_skill.heg_lord_hongfa_Attach"]=sgs.ai_fill_skill["heg_lord_hongfa_Attach"]
prior_extra_hooks["ai_fill_skill.heg_lord_huibian"]=sgs.ai_fill_skill["heg_lord_huibian"]
prior_extra_hooks["ai_fill_skill.heg_lord_jiahe_Attach"]=sgs.ai_fill_skill["heg_lord_jiahe_Attach"]
prior_extra_hooks["ai_fill_skill.heg_lord_lianzi"]=sgs.ai_fill_skill["heg_lord_lianzi"]
prior_extra_hooks["ai_fill_skill.heg_lord_shouyue_wusheng"]=sgs.ai_fill_skill["heg_lord_shouyue_wusheng"]
prior_extra_hooks["ai_fill_skill.heg_lord_wendao"]=sgs.ai_fill_skill["heg_lord_wendao"]
prior_extra_hooks["ai_fill_skill.heg_mobile_duoshi"]=sgs.ai_fill_skill["heg_mobile_duoshi"]
prior_extra_hooks["ai_fill_skill.heg_mobile_paiyi"]=sgs.ai_fill_skill["heg_mobile_paiyi"]
prior_extra_hooks["ai_fill_skill.heg_nos_guishu"]=sgs.ai_fill_skill["heg_nos_guishu"]
prior_extra_hooks["ai_fill_skill.heg_nos_huaiyi"]=sgs.ai_fill_skill["heg_nos_huaiyi"]
prior_extra_hooks["ai_fill_skill.heg_ov_hongyuan"]=sgs.ai_fill_skill["heg_ov_hongyuan"]
prior_extra_hooks["ai_fill_skill.heg_paiyi"]=sgs.ai_fill_skill["heg_paiyi"]
prior_extra_hooks["ai_fill_skill.heg_pojing"]=sgs.ai_fill_skill["heg_pojing"]
prior_extra_hooks["ai_fill_skill.heg_qiangxi"]=sgs.ai_fill_skill["heg_qiangxi"]
prior_extra_hooks["ai_fill_skill.heg_qingyin"]=sgs.ai_fill_skill["heg_qingyin"]
prior_extra_hooks["ai_fill_skill.heg_quanjin"]=sgs.ai_fill_skill["heg_quanjin"]
prior_extra_hooks["ai_fill_skill.heg_ruilve_attach"]=sgs.ai_fill_skill["heg_ruilve_attach"]
prior_extra_hooks["ai_fill_skill.heg_sanchen"]=sgs.ai_fill_skill["heg_sanchen"]
prior_extra_hooks["ai_fill_skill.heg_shunfu"]=sgs.ai_fill_skill["heg_shunfu"]
prior_extra_hooks["ai_fill_skill.heg_six_swords"]=sgs.ai_fill_skill["heg_six_swords"]
prior_extra_hooks["ai_fill_skill.heg_tenyear_boyan"]=sgs.ai_fill_skill["heg_tenyear_boyan"]
prior_extra_hooks["ai_fill_skill.heg_tenyear_fenglue"]=sgs.ai_fill_skill["heg_tenyear_fenglue"]
prior_extra_hooks["ai_fill_skill.heg_tenyear_mingfa"]=sgs.ai_fill_skill["heg_tenyear_mingfa"]
prior_extra_hooks["ai_fill_skill.heg_tenyear_weimeng"]=sgs.ai_fill_skill["heg_tenyear_weimeng"]
prior_extra_hooks["ai_fill_skill.heg_transfer"]=sgs.ai_fill_skill["heg_transfer"]
prior_extra_hooks["ai_fill_skill.heg_weidi"]=sgs.ai_fill_skill["heg_weidi"]
prior_extra_hooks["ai_fill_skill.heg_xianqu"]=sgs.ai_fill_skill["heg_xianqu"]
prior_extra_hooks["ai_fill_skill.heg_xiejian"]=sgs.ai_fill_skill["heg_xiejian"]
prior_extra_hooks["ai_fill_skill.heg_xuanhuoAttach"]=sgs.ai_fill_skill["heg_xuanhuoAttach"]
prior_extra_hooks["ai_fill_skill.heg_yinsha"]=sgs.ai_fill_skill["heg_yinsha"]
prior_extra_hooks["ai_fill_skill.heg_yinyangyu"]=sgs.ai_fill_skill["heg_yinyangyu"]
prior_extra_hooks["ai_fill_skill.heg_zaoyun"]=sgs.ai_fill_skill["heg_zaoyun"]
prior_extra_hooks["ai_fill_skill.heg_zhiheng"]=sgs.ai_fill_skill["heg_zhiheng"]
prior_extra_hooks["ai_fill_skill.heg_zhuangrong"]=sgs.ai_fill_skill["heg_zhuangrong"]
prior_extra_hooks["ai_fill_skill.twyj_huzhu"]=sgs.ai_fill_skill["twyj_huzhu"]
prior_extra_hooks["ai_fill_skill.twyj_qijia"]=sgs.ai_fill_skill["twyj_qijia"]
prior_extra_hooks["ai_fill_skill.twyj_rangyi"]=sgs.ai_fill_skill["twyj_rangyi"]
prior_extra_hooks["ai_fill_skill.twyj_zhuchen"]=sgs.ai_fill_skill["twyj_zhuchen"]
prior_extra_hooks["ai_getBestHp_skill.heg_yinghun"]=sgs.ai_getBestHp_skill["heg_yinghun"]
prior_extra_hooks["ai_getBestHp_skill.yinghun_po"]=sgs.ai_getBestHp_skill["yinghun_po"]
prior_extra_hooks["ai_nullification.heg_alliance_feast"]=sgs.ai_nullification["heg_alliance_feast"]
prior_extra_hooks["ai_nullification.heg_await_exhausted"]=sgs.ai_nullification["heg_await_exhausted"]
prior_extra_hooks["ai_nullification.heg_befriend_attacking"]=sgs.ai_nullification["heg_befriend_attacking"]
prior_extra_hooks["ai_nullification.heg_burning_camps"]=sgs.ai_nullification["heg_burning_camps"]
prior_extra_hooks["ai_nullification.heg_fight_together"]=sgs.ai_nullification["heg_fight_together"]
prior_extra_hooks["ai_nullification.heg_known_both"]=sgs.ai_nullification["heg_known_both"]
prior_extra_hooks["ai_nullification.heg_threaten_emperor"]=sgs.ai_nullification["heg_threaten_emperor"]
prior_extra_hooks["ai_playerchosen_intention.heg_nos_daming_slash"]=sgs.ai_playerchosen_intention["heg_nos_daming_slash"]
prior_extra_hooks["ai_playerchosen_intention.yinghun_po"]=sgs.ai_playerchosen_intention["yinghun_po"]
prior_extra_hooks["ai_playerschosen_intention.heg_baolie"]=sgs.ai_playerschosen_intention["heg_baolie"]
prior_extra_hooks["ai_playerschosen_intention.heg_chengxi"]=sgs.ai_playerschosen_intention["heg_chengxi"]
prior_extra_hooks["ai_playerschosen_intention.heg_fengying"]=sgs.ai_playerschosen_intention["heg_fengying"]
prior_extra_hooks["ai_playerschosen_intention.heg_gongxiu"]=sgs.ai_playerschosen_intention["heg_gongxiu"]
prior_extra_hooks["ai_playerschosen_intention.heg_gongzhi"]=sgs.ai_playerschosen_intention["heg_gongzhi"]
prior_extra_hooks["ai_playerschosen_intention.heg_jianglue"]=sgs.ai_playerschosen_intention["heg_jianglue"]
prior_extra_hooks["ai_playerschosen_intention.heg_limeng"]=sgs.ai_playerschosen_intention["heg_limeng"]
prior_extra_hooks["ai_playerschosen_intention.heg_tenyear_jianliang"]=sgs.ai_playerschosen_intention["heg_tenyear_jianliang"]
prior_extra_hooks["ai_playerschosen_intention.heg_yingshi"]=sgs.ai_playerschosen_intention["heg_yingshi"]
prior_extra_hooks["ai_playerschosen_intention.heg_zhuihuan"]=sgs.ai_playerschosen_intention["heg_zhuihuan"]
prior_extra_hooks["ai_skill_askforag.bf_yongjin"]=sgs.ai_skill_askforag["bf_yongjin"]
prior_extra_hooks["ai_skill_askforag.twyj_liancai"]=sgs.ai_skill_askforag["twyj_liancai"]
prior_extra_hooks["ai_skill_cardask.@bf_nos_tiaodu"]=sgs.ai_skill_cardask["@bf_nos_tiaodu"]
prior_extra_hooks["ai_skill_cardask.@gd_zezhu-give"]=sgs.ai_skill_cardask["@gd_zezhu-give"]
prior_extra_hooks["ai_skill_cardask.@guandu_jieliang"]=sgs.ai_skill_cardask["@guandu_jieliang"]
prior_extra_hooks["ai_skill_cardask.@heg_ciwei"]=sgs.ai_skill_cardask["@heg_ciwei"]
prior_extra_hooks["ai_skill_cardask.@heg_fengshih"]=sgs.ai_skill_cardask["@heg_fengshih"]
prior_extra_hooks["ai_skill_cardask.@heg_fk_bushi-put"]=sgs.ai_skill_cardask["@heg_fk_bushi-put"]
prior_extra_hooks["ai_skill_cardask.@heg_fk_midao-card"]=sgs.ai_skill_cardask["@heg_fk_midao-card"]
prior_extra_hooks["ai_skill_cardask.@heg_fudi-give"]=sgs.ai_skill_cardask["@heg_fudi-give"]
prior_extra_hooks["ai_skill_cardask.@heg_jieyue-give"]=sgs.ai_skill_cardask["@heg_jieyue-give"]
prior_extra_hooks["ai_skill_cardask.@heg_jinfa"]=sgs.ai_skill_cardask["@heg_jinfa"]
prior_extra_hooks["ai_skill_cardask.@heg_limeng"]=sgs.ai_skill_cardask["@heg_limeng"]
prior_extra_hooks["ai_skill_cardask.@heg_luoyi"]=sgs.ai_skill_cardask["@heg_luoyi"]
prior_extra_hooks["ai_skill_cardask.@heg_midao-give"]=sgs.ai_skill_cardask["@heg_midao-give"]
prior_extra_hooks["ai_skill_cardask.@heg_mobile_midao"]=sgs.ai_skill_cardask["@heg_mobile_midao"]
prior_extra_hooks["ai_skill_cardask.@heg_nos_daming"]=sgs.ai_skill_cardask["@heg_nos_daming"]
prior_extra_hooks["ai_skill_cardask.@heg_ov_zhenxi"]=sgs.ai_skill_cardask["@heg_ov_zhenxi"]
prior_extra_hooks["ai_skill_cardask.@heg_ov_zhuidu-beishui"]=sgs.ai_skill_cardask["@heg_ov_zhuidu-beishui"]
prior_extra_hooks["ai_skill_cardask.@heg_threaten_emperor"]=sgs.ai_skill_cardask["@heg_threaten_emperor"]
prior_extra_hooks["ai_skill_cardask.@heg_xijue-tenyeartuxi"]=sgs.ai_skill_cardask["@heg_xijue-tenyeartuxi"]
prior_extra_hooks["ai_skill_cardask.@heg_xijue-xiaoguo"]=sgs.ai_skill_cardask["@heg_xijue-xiaoguo"]
prior_extra_hooks["ai_skill_cardask.@heg_xishe"]=sgs.ai_skill_cardask["@heg_xishe"]
prior_extra_hooks["ai_skill_cardask.@heg_yingwei"]=sgs.ai_skill_cardask["@heg_yingwei"]
prior_extra_hooks["ai_skill_cardask.@heg_zhulan"]=sgs.ai_skill_cardask["@heg_zhulan"]
prior_extra_hooks["ai_skill_cardask.@twyj_huzhu"]=sgs.ai_skill_cardask["@twyj_huzhu"]
prior_extra_hooks["ai_skill_cardask.heg_chengshang"]=sgs.ai_skill_cardask["heg_chengshang"]
prior_extra_hooks["ai_skill_cardchosen.heg_huaiyi"]=sgs.ai_skill_cardchosen["heg_huaiyi"]
prior_extra_hooks["ai_skill_cardchosen.heg_mouduan"]=sgs.ai_skill_cardchosen["heg_mouduan"]
prior_extra_hooks["ai_skill_choice.bf_xiongsuan"]=sgs.ai_skill_choice["bf_xiongsuan"]
prior_extra_hooks["ai_skill_choice.do_command"]=sgs.ai_skill_choice["do_command"]
prior_extra_hooks["ai_skill_choice.heg_duanqiu_ChooseKingdom"]=sgs.ai_skill_choice["heg_duanqiu_ChooseKingdom"]
prior_extra_hooks["ai_skill_choice.heg_gongxiu"]=sgs.ai_skill_choice["heg_gongxiu"]
prior_extra_hooks["ai_skill_choice.heg_huaiyi"]=sgs.ai_skill_choice["heg_huaiyi"]
prior_extra_hooks["ai_skill_choice.heg_lianpian"]=sgs.ai_skill_choice["heg_lianpian"]
prior_extra_hooks["ai_skill_choice.heg_liegong"]=sgs.ai_skill_choice["heg_liegong"]
prior_extra_hooks["ai_skill_choice.heg_lixia"]=sgs.ai_skill_choice["heg_lixia"]
prior_extra_hooks["ai_skill_choice.heg_lord_jianan"]=sgs.ai_skill_choice["heg_lord_jianan"]
prior_extra_hooks["ai_skill_choice.heg_mobile_kuangfu"]=sgs.ai_skill_choice["heg_mobile_kuangfu"]
prior_extra_hooks["ai_skill_choice.heg_mobile_suishi"]=sgs.ai_skill_choice["heg_mobile_suishi"]
prior_extra_hooks["ai_skill_choice.heg_nos_daming"]=sgs.ai_skill_choice["heg_nos_daming"]
prior_extra_hooks["ai_skill_choice.heg_nos_huaiyi"]=sgs.ai_skill_choice["heg_nos_huaiyi"]
prior_extra_hooks["ai_skill_choice.heg_nos_lixia"]=sgs.ai_skill_choice["heg_nos_lixia"]
prior_extra_hooks["ai_skill_choice.heg_ov_shigong"]=sgs.ai_skill_choice["heg_ov_shigong"]
prior_extra_hooks["ai_skill_choice.heg_ov_zhenxi"]=sgs.ai_skill_choice["heg_ov_zhenxi"]
prior_extra_hooks["ai_skill_choice.heg_ov_zhuidu"]=sgs.ai_skill_choice["heg_ov_zhuidu"]
prior_extra_hooks["ai_skill_choice.heg_pojing"]=sgs.ai_skill_choice["heg_pojing"]
prior_extra_hooks["ai_skill_choice.heg_tenyear_anyong"]=sgs.ai_skill_choice["heg_tenyear_anyong"]
prior_extra_hooks["ai_skill_choice.heg_tenyear_shejian"]=sgs.ai_skill_choice["heg_tenyear_shejian"]
prior_extra_hooks["ai_skill_choice.heg_yanxi"]=sgs.ai_skill_choice["heg_yanxi"]
prior_extra_hooks["ai_skill_choice.heg_yinghun"]=sgs.ai_skill_choice["heg_yinghun"]
prior_extra_hooks["ai_skill_choice.heg_zhengbi"]=sgs.ai_skill_choice["heg_zhengbi"]
prior_extra_hooks["ai_skill_choice.start_command_heg_jianglue"]=sgs.ai_skill_choice["start_command_heg_jianglue"]
prior_extra_hooks["ai_skill_choice.yinghun_po"]=sgs.ai_skill_choice["yinghun_po"]
prior_extra_hooks["ai_skill_discard.bf_wanwei"]=sgs.ai_skill_discard["bf_wanwei"]
prior_extra_hooks["ai_skill_discard.command"]=sgs.ai_skill_discard["command"]
prior_extra_hooks["ai_skill_discard.heg_juejue"]=sgs.ai_skill_discard["heg_juejue"]
prior_extra_hooks["ai_skill_discard.heg_lord_jianan"]=sgs.ai_skill_discard["heg_lord_jianan"]
prior_extra_hooks["ai_skill_discard.heg_neiji"]=sgs.ai_skill_discard["heg_neiji"]
prior_extra_hooks["ai_skill_discard.heg_shilus"]=sgs.ai_skill_discard["heg_shilus"]
prior_extra_hooks["ai_skill_discard.heg_triblade_Skill"]=sgs.ai_skill_discard["heg_triblade_Skill"]
prior_extra_hooks["ai_skill_invoke.ChangeGeneral"]=sgs.ai_skill_invoke["ChangeGeneral"]
prior_extra_hooks["ai_skill_invoke.DragonPhoenix"]=sgs.ai_skill_invoke["DragonPhoenix"]
prior_extra_hooks["ai_skill_invoke.bf_sec_tiaodu"]=sgs.ai_skill_invoke["bf_sec_tiaodu"]
prior_extra_hooks["ai_skill_invoke.bf_third_tiaodu"]=sgs.ai_skill_invoke["bf_third_tiaodu"]
prior_extra_hooks["ai_skill_invoke.bf_tiaodu"]=sgs.ai_skill_invoke["bf_tiaodu"]
prior_extra_hooks["ai_skill_invoke.bf_yuejian"]=sgs.ai_skill_invoke["bf_yuejian"]
prior_extra_hooks["ai_skill_invoke.chenggong"]=sgs.ai_skill_invoke["chenggong"]
prior_extra_hooks["ai_skill_invoke.guandu_fuyuan"]=sgs.ai_skill_invoke["guandu_fuyuan"]
prior_extra_hooks["ai_skill_invoke.heg_beiluan"]=sgs.ai_skill_invoke["heg_beiluan"]
prior_extra_hooks["ai_skill_invoke.heg_buyi"]=sgs.ai_skill_invoke["heg_buyi"]
prior_extra_hooks["ai_skill_invoke.heg_chengliu"]=sgs.ai_skill_invoke["heg_chengliu"]
prior_extra_hooks["ai_skill_invoke.heg_chenglue"]=sgs.ai_skill_invoke["heg_chenglue"]
prior_extra_hooks["ai_skill_invoke.heg_duannian"]=sgs.ai_skill_invoke["heg_duannian"]
prior_extra_hooks["ai_skill_invoke.heg_duanqiu"]=sgs.ai_skill_invoke["heg_duanqiu"]
prior_extra_hooks["ai_skill_invoke.heg_gongxiu"]=sgs.ai_skill_invoke["heg_gongxiu"]
prior_extra_hooks["ai_skill_invoke.heg_gongzhi"]=sgs.ai_skill_invoke["heg_gongzhi"]
prior_extra_hooks["ai_skill_invoke.heg_hengjiang"]=sgs.ai_skill_invoke["heg_hengjiang"]
prior_extra_hooks["ai_skill_invoke.heg_huaiyuan"]=sgs.ai_skill_invoke["heg_huaiyuan"]
prior_extra_hooks["ai_skill_invoke.heg_jianzhi"]=sgs.ai_skill_invoke["heg_jianzhi"]
prior_extra_hooks["ai_skill_invoke.heg_jinxian"]=sgs.ai_skill_invoke["heg_jinxian"]
prior_extra_hooks["ai_skill_invoke.heg_juejue"]=sgs.ai_skill_invoke["heg_juejue"]
prior_extra_hooks["ai_skill_invoke.heg_jujian"]=sgs.ai_skill_invoke["heg_jujian"]
prior_extra_hooks["ai_skill_invoke.heg_jushou"]=sgs.ai_skill_invoke["heg_jushou"]
prior_extra_hooks["ai_skill_invoke.heg_liangfan"]=sgs.ai_skill_invoke["heg_liangfan"]
prior_extra_hooks["ai_skill_invoke.heg_luanchang"]=sgs.ai_skill_invoke["heg_luanchang"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_bushi"]=sgs.ai_skill_invoke["heg_mobile_bushi"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_jiancai"]=sgs.ai_skill_invoke["heg_mobile_jiancai"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_kuangfu"]=sgs.ai_skill_invoke["heg_mobile_kuangfu"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_suishi"]=sgs.ai_skill_invoke["heg_mobile_suishi"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_tanfeng"]=sgs.ai_skill_invoke["heg_mobile_tanfeng"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_yaowu"]=sgs.ai_skill_invoke["heg_mobile_yaowu"]
prior_extra_hooks["ai_skill_invoke.heg_mobile_zhuwei"]=sgs.ai_skill_invoke["heg_mobile_zhuwei"]
prior_extra_hooks["ai_skill_invoke.heg_nos_lixia"]=sgs.ai_skill_invoke["heg_nos_lixia"]
prior_extra_hooks["ai_skill_invoke.heg_ol_liegong"]=sgs.ai_skill_invoke["heg_ol_liegong"]
prior_extra_hooks["ai_skill_invoke.heg_ov_jiansu"]=sgs.ai_skill_invoke["heg_ov_jiansu"]
prior_extra_hooks["ai_skill_invoke.heg_ov_shigong_gain"]=sgs.ai_skill_invoke["heg_ov_shigong_gain"]
prior_extra_hooks["ai_skill_invoke.heg_ov_zhenxi"]=sgs.ai_skill_invoke["heg_ov_zhenxi"]
prior_extra_hooks["ai_skill_invoke.heg_ov_zhuidu"]=sgs.ai_skill_invoke["heg_ov_zhuidu"]
prior_extra_hooks["ai_skill_invoke.heg_pojing"]=sgs.ai_skill_invoke["heg_pojing"]
prior_extra_hooks["ai_skill_invoke.heg_qiance"]=sgs.ai_skill_invoke["heg_qiance"]
prior_extra_hooks["ai_skill_invoke.heg_qiao"]=sgs.ai_skill_invoke["heg_qiao"]
prior_extra_hooks["ai_skill_invoke.heg_qiuan"]=sgs.ai_skill_invoke["heg_qiuan"]
prior_extra_hooks["ai_skill_invoke.heg_shejus"]=sgs.ai_skill_invoke["heg_shejus"]
prior_extra_hooks["ai_skill_invoke.heg_shiren"]=sgs.ai_skill_invoke["heg_shiren"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_anyong"]=sgs.ai_skill_invoke["heg_tenyear_anyong"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_boyan"]=sgs.ai_skill_invoke["heg_tenyear_boyan"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_dechao"]=sgs.ai_skill_invoke["heg_tenyear_dechao"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_fenglue"]=sgs.ai_skill_invoke["heg_tenyear_fenglue"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_shejian"]=sgs.ai_skill_invoke["heg_tenyear_shejian"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_weimeng"]=sgs.ai_skill_invoke["heg_tenyear_weimeng"]
prior_extra_hooks["ai_skill_invoke.heg_tenyear_zhuwei"]=sgs.ai_skill_invoke["heg_tenyear_zhuwei"]
prior_extra_hooks["ai_skill_invoke.heg_tongdu"]=sgs.ai_skill_invoke["heg_tongdu"]
prior_extra_hooks["ai_skill_invoke.heg_true_jiancai"]=sgs.ai_skill_invoke["heg_true_jiancai"]
prior_extra_hooks["ai_skill_invoke.heg_true_jiancai_change"]=sgs.ai_skill_invoke["heg_true_jiancai_change"]
prior_extra_hooks["ai_skill_invoke.heg_true_pozhen"]=sgs.ai_skill_invoke["heg_true_pozhen"]
prior_extra_hooks["ai_skill_invoke.heg_wenji"]=sgs.ai_skill_invoke["heg_wenji"]
prior_extra_hooks["ai_skill_invoke.heg_xiace"]=sgs.ai_skill_invoke["heg_xiace"]
prior_extra_hooks["ai_skill_invoke.heg_xiongnve"]=sgs.ai_skill_invoke["heg_xiongnve"]
prior_extra_hooks["ai_skill_invoke.heg_xishe"]=sgs.ai_skill_invoke["heg_xishe"]
prior_extra_hooks["ai_skill_invoke.heg_yinyangyu"]=sgs.ai_skill_invoke["heg_yinyangyu"]
prior_extra_hooks["ai_skill_invoke.heg_zhuwei"]=sgs.ai_skill_invoke["heg_zhuwei"]
prior_extra_hooks["ai_skill_invoke.twyj_huzhu"]=sgs.ai_skill_invoke["twyj_huzhu"]
prior_extra_hooks["ai_skill_invoke.twyj_liancai"]=sgs.ai_skill_invoke["twyj_liancai"]
prior_extra_hooks["ai_skill_playerchosen.bf_nos_tiaodu"]=sgs.ai_skill_playerchosen["bf_nos_tiaodu"]
prior_extra_hooks["ai_skill_playerchosen.bf_sec_tiaodu"]=sgs.ai_skill_playerchosen["bf_sec_tiaodu"]
prior_extra_hooks["ai_skill_playerchosen.bf_third_tiaodu"]=sgs.ai_skill_playerchosen["bf_third_tiaodu"]
prior_extra_hooks["ai_skill_playerchosen.bf_tiaodu"]=sgs.ai_skill_playerchosen["bf_tiaodu"]
prior_extra_hooks["ai_skill_playerchosen.bf_xuanlve"]=sgs.ai_skill_playerchosen["bf_xuanlve"]
prior_extra_hooks["ai_skill_playerchosen.gd_zhanyanliangzhuwenchou"]=sgs.ai_skill_playerchosen["gd_zhanyanliangzhuwenchou"]
prior_extra_hooks["ai_skill_playerchosen.guandu_zhongjie"]=sgs.ai_skill_playerchosen["guandu_zhongjie"]
prior_extra_hooks["ai_skill_playerchosen.heg_bushi"]=sgs.ai_skill_playerchosen["heg_bushi"]
prior_extra_hooks["ai_skill_playerchosen.heg_chenglue"]=sgs.ai_skill_playerchosen["heg_chenglue"]
prior_extra_hooks["ai_skill_playerchosen.heg_chengshang"]=sgs.ai_skill_playerchosen["heg_chengshang"]
prior_extra_hooks["ai_skill_playerchosen.heg_chengxi"]=sgs.ai_skill_playerchosen["heg_chengxi"]
prior_extra_hooks["ai_skill_playerchosen.heg_congcha"]=sgs.ai_skill_playerchosen["heg_congcha"]
prior_extra_hooks["ai_skill_playerchosen.heg_huyuan"]=sgs.ai_skill_playerchosen["heg_huyuan"]
prior_extra_hooks["ai_skill_playerchosen.heg_jieyue"]=sgs.ai_skill_playerchosen["heg_jieyue"]
prior_extra_hooks["ai_skill_playerchosen.heg_lianpian"]=sgs.ai_skill_playerchosen["heg_lianpian"]
prior_extra_hooks["ai_skill_playerchosen.heg_lianyou"]=sgs.ai_skill_playerchosen["heg_lianyou"]
prior_extra_hooks["ai_skill_playerchosen.heg_longdan"]=sgs.ai_skill_playerchosen["heg_longdan"]
prior_extra_hooks["ai_skill_playerchosen.heg_longdan_recover"]=sgs.ai_skill_playerchosen["heg_longdan_recover"]
prior_extra_hooks["ai_skill_playerchosen.heg_mobile_shushen"]=sgs.ai_skill_playerchosen["heg_mobile_shushen"]
prior_extra_hooks["ai_skill_playerchosen.heg_mobile_tanfeng"]=sgs.ai_skill_playerchosen["heg_mobile_tanfeng"]
prior_extra_hooks["ai_skill_playerchosen.heg_mouduan"]=sgs.ai_skill_playerchosen["heg_mouduan"]
prior_extra_hooks["ai_skill_playerchosen.heg_neiji"]=sgs.ai_skill_playerchosen["heg_neiji"]
prior_extra_hooks["ai_skill_playerchosen.heg_nos_daming"]=sgs.ai_skill_playerchosen["heg_nos_daming"]
prior_extra_hooks["ai_skill_playerchosen.heg_nos_daming_slash"]=sgs.ai_skill_playerchosen["heg_nos_daming_slash"]
prior_extra_hooks["ai_skill_playerchosen.heg_ov_hongyuan"]=sgs.ai_skill_playerchosen["heg_ov_hongyuan"]
prior_extra_hooks["ai_skill_playerchosen.heg_tongling"]=sgs.ai_skill_playerchosen["heg_tongling"]
prior_extra_hooks["ai_skill_playerchosen.heg_triblade_Skill"]=sgs.ai_skill_playerchosen["heg_triblade_Skill"]
prior_extra_hooks["ai_skill_playerchosen.heg_wenji"]=sgs.ai_skill_playerchosen["heg_wenji"]
prior_extra_hooks["ai_skill_playerchosen.heg_yidu"]=sgs.ai_skill_playerchosen["heg_yidu"]
prior_extra_hooks["ai_skill_playerchosen.heg_yinghun"]=sgs.ai_skill_playerchosen["heg_yinghun"]
prior_extra_hooks["ai_skill_playerchosen.heg_yingshi"]=sgs.ai_skill_playerchosen["heg_yingshi"]
prior_extra_hooks["ai_skill_playerchosen.heg_zhaoxin"]=sgs.ai_skill_playerchosen["heg_zhaoxin"]
prior_extra_hooks["ai_skill_playerchosen.heg_zhefu"]=sgs.ai_skill_playerchosen["heg_zhefu"]
prior_extra_hooks["ai_skill_playerchosen.heg_zhengbi"]=sgs.ai_skill_playerchosen["heg_zhengbi"]
prior_extra_hooks["ai_skill_playerchosen.heg_zhidao"]=sgs.ai_skill_playerchosen["heg_zhidao"]
prior_extra_hooks["ai_skill_playerchosen.shushen"]=sgs.ai_skill_playerchosen["shushen"]
prior_extra_hooks["ai_skill_playerchosen.yinghun_po"]=sgs.ai_skill_playerchosen["yinghun_po"]
prior_extra_hooks["ai_skill_playerschosen.heg_baolie"]=sgs.ai_skill_playerschosen["heg_baolie"]
prior_extra_hooks["ai_skill_playerschosen.heg_chengxi"]=sgs.ai_skill_playerschosen["heg_chengxi"]
prior_extra_hooks["ai_skill_playerschosen.heg_duoshi"]=sgs.ai_skill_playerschosen["heg_duoshi"]
prior_extra_hooks["ai_skill_playerschosen.heg_fengying"]=sgs.ai_skill_playerschosen["heg_fengying"]
prior_extra_hooks["ai_skill_playerschosen.heg_gongxiu"]=sgs.ai_skill_playerschosen["heg_gongxiu"]
prior_extra_hooks["ai_skill_playerschosen.heg_gongzhi"]=sgs.ai_skill_playerschosen["heg_gongzhi"]
prior_extra_hooks["ai_skill_playerschosen.heg_guowu"]=sgs.ai_skill_playerschosen["heg_guowu"]
prior_extra_hooks["ai_skill_playerschosen.heg_huaiyi"]=sgs.ai_skill_playerschosen["heg_huaiyi"]
prior_extra_hooks["ai_skill_playerschosen.heg_jianglue"]=sgs.ai_skill_playerschosen["heg_jianglue"]
prior_extra_hooks["ai_skill_playerschosen.heg_limeng"]=sgs.ai_skill_playerschosen["heg_limeng"]
prior_extra_hooks["ai_skill_playerschosen.heg_nos_huaiyi"]=sgs.ai_skill_playerschosen["heg_nos_huaiyi"]
prior_extra_hooks["ai_skill_playerschosen.heg_tenyear_jianliang"]=sgs.ai_skill_playerschosen["heg_tenyear_jianliang"]
prior_extra_hooks["ai_skill_playerschosen.heg_xunjim"]=sgs.ai_skill_playerschosen["heg_xunjim"]
prior_extra_hooks["ai_skill_playerschosen.heg_yingshi_target"]=sgs.ai_skill_playerschosen["heg_yingshi_target"]
prior_extra_hooks["ai_skill_playerschosen.heg_zhuihuan"]=sgs.ai_skill_playerschosen["heg_zhuihuan"]
prior_extra_hooks["ai_skill_use.@@bf_yongjin!"]=sgs.ai_skill_use["@@bf_yongjin!"]
prior_extra_typed_uses["@@bf_yongjin!"]=ai_skill_use["@@bf_yongjin!"]
prior_extra_hooks["ai_skill_use.@@command6!"]=sgs.ai_skill_use["@@command6!"]
prior_extra_typed_uses["@@command6!"]=ai_skill_use["@@command6!"]
prior_extra_hooks["ai_skill_use.@@heg_chengliu"]=sgs.ai_skill_use["@@heg_chengliu"]
prior_extra_typed_uses["@@heg_chengliu"]=ai_skill_use["@@heg_chengliu"]
prior_extra_hooks["ai_skill_use.@@heg_fk_bushi"]=sgs.ai_skill_use["@@heg_fk_bushi"]
prior_extra_typed_uses["@@heg_fk_bushi"]=ai_skill_use["@@heg_fk_bushi"]
prior_extra_hooks["ai_skill_use.@@heg_huyuan"]=sgs.ai_skill_use["@@heg_huyuan"]
prior_extra_typed_uses["@@heg_huyuan"]=ai_skill_use["@@heg_huyuan"]
prior_extra_hooks["ai_skill_use.@@heg_jiantong"]=sgs.ai_skill_use["@@heg_jiantong"]
prior_extra_typed_uses["@@heg_jiantong"]=ai_skill_use["@@heg_jiantong"]
prior_extra_hooks["ai_skill_use.@@heg_keshou"]=sgs.ai_skill_use["@@heg_keshou"]
prior_extra_typed_uses["@@heg_keshou"]=ai_skill_use["@@heg_keshou"]
prior_extra_hooks["ai_skill_use.@@heg_mobile_keshou"]=sgs.ai_skill_use["@@heg_mobile_keshou"]
prior_extra_typed_uses["@@heg_mobile_keshou"]=ai_skill_use["@@heg_mobile_keshou"]
prior_extra_hooks["ai_skill_use.@@heg_ov_jiansu"]=sgs.ai_skill_use["@@heg_ov_jiansu"]
prior_extra_typed_uses["@@heg_ov_jiansu"]=ai_skill_use["@@heg_ov_jiansu"]
prior_extra_hooks["ai_skill_use.@@heg_pozhu"]=sgs.ai_skill_use["@@heg_pozhu"]
prior_extra_typed_uses["@@heg_pozhu"]=ai_skill_use["@@heg_pozhu"]
prior_extra_hooks["ai_skill_use.@@heg_shensu1"]=sgs.ai_skill_use["@@heg_shensu1"]
prior_extra_typed_uses["@@heg_shensu1"]=ai_skill_use["@@heg_shensu1"]
prior_extra_hooks["ai_skill_use.@@heg_shensu2"]=sgs.ai_skill_use["@@heg_shensu2"]
prior_extra_typed_uses["@@heg_shensu2"]=ai_skill_use["@@heg_shensu2"]
prior_extra_hooks["ai_skill_use.@@heg_shensu3"]=sgs.ai_skill_use["@@heg_shensu3"]
prior_extra_typed_uses["@@heg_shensu3"]=ai_skill_use["@@heg_shensu3"]
prior_extra_hooks["ai_skill_use.@@heg_tianxiang"]=sgs.ai_skill_use["@@heg_tianxiang"]
prior_extra_typed_uses["@@heg_tianxiang"]=ai_skill_use["@@heg_tianxiang"]
prior_extra_hooks["ai_skill_use.@@heg_yanxi"]=sgs.ai_skill_use["@@heg_yanxi"]
prior_extra_typed_uses["@@heg_yanxi"]=ai_skill_use["@@heg_yanxi"]
prior_extra_hooks["ai_skill_use.@@heg_zhengbi"]=sgs.ai_skill_use["@@heg_zhengbi"]
prior_extra_typed_uses["@@heg_zhengbi"]=ai_skill_use["@@heg_zhengbi"]
prior_extra_hooks["ai_skill_use.@@twyj_rangyi"]=sgs.ai_skill_use["@@twyj_rangyi"]
prior_extra_typed_uses["@@twyj_rangyi"]=ai_skill_use["@@twyj_rangyi"]
prior_extra_hooks["ai_skill_use.@@zhengbidiscard!"]=sgs.ai_skill_use["@@zhengbidiscard!"]
prior_extra_typed_uses["@@zhengbidiscard!"]=ai_skill_use["@@zhengbidiscard!"]
prior_extra_hooks["ai_skill_use.@heg_mouduan"]=sgs.ai_skill_use["@heg_mouduan"]
prior_extra_typed_uses["@heg_mouduan"]=ai_skill_use["@heg_mouduan"]
prior_extra_hooks["ai_skill_use_func.#bf_nos_tiaodu"]=sgs.ai_skill_use_func["#bf_nos_tiaodu"]
prior_extra_hooks["ai_skill_use_func.#bf_qice"]=sgs.ai_skill_use_func["#bf_qice"]
prior_extra_hooks["ai_skill_use_func.#bf_xiongsuan"]=sgs.ai_skill_use_func["#bf_xiongsuan"]
prior_extra_hooks["ai_skill_use_func.#bf_yongjin"]=sgs.ai_skill_use_func["#bf_yongjin"]
prior_extra_hooks["ai_skill_use_func.#gd_zezhu"]=sgs.ai_skill_use_func["#gd_zezhu"]
prior_extra_hooks["ai_skill_use_func.#guandu_shicai"]=sgs.ai_skill_use_func["#guandu_shicai"]
prior_extra_hooks["ai_skill_use_func.#guandu_yuanlue"]=sgs.ai_skill_use_func["#guandu_yuanlue"]
prior_extra_hooks["ai_skill_use_func.#heg_chengliu"]=sgs.ai_skill_use_func["#heg_chengliu"]
prior_extra_hooks["ai_skill_use_func.#heg_duanxie"]=sgs.ai_skill_use_func["#heg_duanxie"]
prior_extra_hooks["ai_skill_use_func.#heg_duwu"]=sgs.ai_skill_use_func["#heg_duwu"]
prior_extra_hooks["ai_skill_use_func.#heg_guikuang"]=sgs.ai_skill_use_func["#heg_guikuang"]
prior_extra_hooks["ai_skill_use_func.#heg_huaiyi"]=sgs.ai_skill_use_func["#heg_huaiyi"]
prior_extra_hooks["ai_skill_use_func.#heg_jianglue"]=sgs.ai_skill_use_func["#heg_jianglue"]
prior_extra_hooks["ai_skill_use_func.#heg_jiaping_Attach"]=sgs.ai_skill_use_func["#heg_jiaping_Attach"]
prior_extra_hooks["ai_skill_use_func.#heg_jinfa"]=sgs.ai_skill_use_func["#heg_jinfa"]
prior_extra_hooks["ai_skill_use_func.#heg_jinghe"]=sgs.ai_skill_use_func["#heg_jinghe"]
prior_extra_hooks["ai_skill_use_func.#heg_kurou"]=sgs.ai_skill_use_func["#heg_kurou"]
prior_extra_hooks["ai_skill_use_func.#heg_lord_huibian"]=sgs.ai_skill_use_func["#heg_lord_huibian"]
prior_extra_hooks["ai_skill_use_func.#heg_lord_jiahe_Attach"]=sgs.ai_skill_use_func["#heg_lord_jiahe_Attach"]
prior_extra_hooks["ai_skill_use_func.#heg_lord_lianzi"]=sgs.ai_skill_use_func["#heg_lord_lianzi"]
prior_extra_hooks["ai_skill_use_func.#heg_lord_wendao"]=sgs.ai_skill_use_func["#heg_lord_wendao"]
prior_extra_hooks["ai_skill_use_func.#heg_mobile_paiyi"]=sgs.ai_skill_use_func["#heg_mobile_paiyi"]
prior_extra_hooks["ai_skill_use_func.#heg_nos_huaiyi"]=sgs.ai_skill_use_func["#heg_nos_huaiyi"]
prior_extra_hooks["ai_skill_use_func.#heg_ov_hongyuan"]=sgs.ai_skill_use_func["#heg_ov_hongyuan"]
prior_extra_hooks["ai_skill_use_func.#heg_paiyi"]=sgs.ai_skill_use_func["#heg_paiyi"]
prior_extra_hooks["ai_skill_use_func.#heg_pojing"]=sgs.ai_skill_use_func["#heg_pojing"]
prior_extra_hooks["ai_skill_use_func.#heg_qiangxi"]=sgs.ai_skill_use_func["#heg_qiangxi"]
prior_extra_hooks["ai_skill_use_func.#heg_qingyin"]=sgs.ai_skill_use_func["#heg_qingyin"]
prior_extra_hooks["ai_skill_use_func.#heg_quanjin"]=sgs.ai_skill_use_func["#heg_quanjin"]
prior_extra_hooks["ai_skill_use_func.#heg_ruilve"]=sgs.ai_skill_use_func["#heg_ruilve"]
prior_extra_hooks["ai_skill_use_func.#heg_sanchen"]=sgs.ai_skill_use_func["#heg_sanchen"]
prior_extra_hooks["ai_skill_use_func.#heg_shunfu"]=sgs.ai_skill_use_func["#heg_shunfu"]
prior_extra_hooks["ai_skill_use_func.#heg_six_swords_Skill"]=sgs.ai_skill_use_func["#heg_six_swords_Skill"]
prior_extra_hooks["ai_skill_use_func.#heg_tenyear_boyan"]=sgs.ai_skill_use_func["#heg_tenyear_boyan"]
prior_extra_hooks["ai_skill_use_func.#heg_tenyear_fenglue"]=sgs.ai_skill_use_func["#heg_tenyear_fenglue"]
prior_extra_hooks["ai_skill_use_func.#heg_tenyear_mingfa"]=sgs.ai_skill_use_func["#heg_tenyear_mingfa"]
prior_extra_hooks["ai_skill_use_func.#heg_tenyear_weimeng"]=sgs.ai_skill_use_func["#heg_tenyear_weimeng"]
prior_extra_hooks["ai_skill_use_func.#heg_transfer"]=sgs.ai_skill_use_func["#heg_transfer"]
prior_extra_hooks["ai_skill_use_func.#heg_weidi"]=sgs.ai_skill_use_func["#heg_weidi"]
prior_extra_hooks["ai_skill_use_func.#heg_xianqu"]=sgs.ai_skill_use_func["#heg_xianqu"]
prior_extra_hooks["ai_skill_use_func.#heg_xiejian"]=sgs.ai_skill_use_func["#heg_xiejian"]
prior_extra_hooks["ai_skill_use_func.#heg_xuanhuo"]=sgs.ai_skill_use_func["#heg_xuanhuo"]
prior_extra_hooks["ai_skill_use_func.#heg_yinyangyu"]=sgs.ai_skill_use_func["#heg_yinyangyu"]
prior_extra_hooks["ai_skill_use_func.#heg_zaoyun"]=sgs.ai_skill_use_func["#heg_zaoyun"]
prior_extra_hooks["ai_skill_use_func.#heg_zhuangrong"]=sgs.ai_skill_use_func["#heg_zhuangrong"]
prior_extra_hooks["ai_skill_use_func.#twyj_huzhu"]=sgs.ai_skill_use_func["#twyj_huzhu"]
prior_extra_hooks["ai_skill_use_func.#twyj_qijia"]=sgs.ai_skill_use_func["#twyj_qijia"]
prior_extra_hooks["ai_skill_use_func.#twyj_rangyi"]=sgs.ai_skill_use_func["#twyj_rangyi"]
prior_extra_hooks["ai_skill_use_func.#twyj_zhuchen"]=sgs.ai_skill_use_func["#twyj_zhuchen"]
prior_extra_hooks["ai_skill_use_func.heg_zhiheng"]=sgs.ai_skill_use_func["heg_zhiheng"]
prior_extra_hooks["ai_target_revises.heg_kongcheng"]=sgs.ai_target_revises["heg_kongcheng"]
prior_extra_hooks["ai_target_revises.heg_mobile_qianxun"]=sgs.ai_target_revises["heg_mobile_qianxun"]
prior_extra_hooks["ai_use_revises.heg_paoxiao"]=sgs.ai_use_revises["heg_paoxiao"]
prior_extra_hooks["ai_use_revises.heg_xiaoji"]=sgs.ai_use_revises["heg_xiaoji"]
prior_extra_hooks["ai_view_as.heg_guishu"]=sgs.ai_view_as["heg_guishu"]
prior_extra_hooks["ai_view_as.heg_longdan"]=sgs.ai_view_as["heg_longdan"]
prior_extra_hooks["ai_view_as.heg_lord_shouyue_wusheng"]=sgs.ai_view_as["heg_lord_shouyue_wusheng"]
prior_extra_hooks["ai_view_as.heg_nos_guishu"]=sgs.ai_view_as["heg_nos_guishu"]
prior_extra_hooks["ai_view_as.heg_xiace"]=sgs.ai_view_as["heg_xiace"]
prior_extra_hooks["ai_view_as.heg_yimie_attach"]=sgs.ai_view_as["heg_yimie_attach"]
prior_extra_hooks["SmartAI.useCardTunliang"]=SmartAIView["useCardTunliang"]
prior_extra_hooks["SmartAI.useCardXujiu"]=SmartAIView["useCardXujiu"]
prior_extra_hooks["SmartAI.useCardYuanjun"]=SmartAIView["useCardYuanjun"]
prior_extra_hooks["SmartAI.useCardheg_alliance_feast"]=SmartAIView["useCardheg_alliance_feast"]
prior_extra_hooks["SmartAI.useCardheg_await_exhausted"]=SmartAIView["useCardheg_await_exhausted"]
prior_extra_hooks["SmartAI.useCardheg_befriend_attacking"]=SmartAIView["useCardheg_befriend_attacking"]
prior_extra_hooks["SmartAI.useCardheg_burning_camps"]=SmartAIView["useCardheg_burning_camps"]
prior_extra_hooks["SmartAI.useCardheg_fight_together"]=SmartAIView["useCardheg_fight_together"]
prior_extra_hooks["SmartAI.useCardheg_known_both"]=SmartAIView["useCardheg_known_both"]
prior_extra_hooks["SmartAI.useCardheg_threaten_emperor"]=SmartAIView["useCardheg_threaten_emperor"]

local accepted_congjian_from=sgs.ai_ajustdamage_from.heg_congjian
local accepted_congjian_to=sgs.ai_ajustdamage_to.heg_congjian
-- Pure adaptation layer for the complete fixed extra-ai body. A missing
-- capability interrupts only the exercised branch; it never becomes false/pass.
local package_skills={}
local function addAiSkills(name)local skill={name=name};package_skills[#package_skills+1]=skill;return skill end
-- Source legacy callbacks are collected before choosing the existing ABI slot.
-- Existing Original typed callbacks are never registered into the other ABI.
local source_use_registry=setmetatable({},{__index=function(_,key)
 return sgs.ai_skill_use[key]or ai_skill_use[key]
end})
local current_ai,current_key,current_request
local previews=setmetatable({},{__mode='k'})
local constructed=setmetatable({},{__mode='k'})
local resolve_preview,call,q,source_flag_read
local function known(v,key)
 if AIUnsupported.is(v)then error(v,0)end
 if v==nil then ai_unsupported('extra policy input is unknown',key)end
 return v
end
local function owner()return known(current_ai,'extra callback viewer')end
local function ids(cards)local out={};for _,c in ipairs(cards)do out[#out+1]=type(c)=='number'and c or q(c,'getEffectiveId')end;return out end
local function disclosed(id)
 local ai=owner();return known(ai:getKnownCardById(id)or ai:getChoiceCard(id),'extra disclosed card '..tostring(id))
end
local function source_printed(id)return q(owner(),'getPrintedCardById',id)end
local function request_view(self,request)
 request=request or current_request
 if request and type(request.getActivationSkillName)~='function'then return AILegacyRequest.new(request,self.room)end
 return request
end
local function aggregate(costs,suit,number)
 if suit==sgs.Card_NoSuit or suit==sgs.Card_SuitToBeDecided then
  if #costs==1 then suit=q(disclosed(costs[1]),'getSuit')
  elseif #costs>1 then local red,black=true,true;for _,id in ipairs(costs)do local c=disclosed(id);red=red and q(c,'isRed');black=black and q(c,'isBlack')end;suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
  else suit=sgs.Card_NoSuit end
 end
 if number<=0 then number=#costs==1 and q(disclosed(costs[1]),'getNumber')or 0 end
 return suit,number
end
local function clone_source(name,suit,number,skill)
 if name=='heg_threaten_emperor'then
  -- The printed-card catalog stands in for Engine::cloneCard's name lookup.
  known(ai_card_catalog,'card catalog')
  if AICardCatalog.get(name)==nil then return nil end
 end
 if type(suit)=='string'then skill=suit;suit=sgs.Card_NoSuit end
 local c={};previews[c]={name=name or'slash',suit=suit or sgs.Card_NoSuit,number=number or 0,skill=skill or'',costs={}};return c
end
local function active_source()local c=clone_source('ActiveSkillCard');previews[c].class='ActiveSkillCard';return c end
local function mutate(c,method,...)
 local p=previews[c]or constructed[c]
 if not p then ai_unsupported('unissued source card mutation lacks construction provenance','extra.'..method)end
 local args={...};if method=='deleteLater'then return end
 if method=='setSkillName'then p.skill=args[1]
 elseif method=='clearSubcards'then p.costs={}
 elseif method=='addSubcard'then p.costs[#p.costs+1]=type(args[1])=='number'and args[1]or q(args[1],'getEffectiveId')
 elseif method=='addSubcards'then for _,id in ipairs(ids(args[1]))do p.costs[#p.costs+1]=id end
 else ai_unsupported('unsupported source construction mutation',method)end
 p.resolved=nil;p.dirty=true
end
resolve_preview=function(value,turn)
 local p=previews[value]or constructed[value];if not p then return value end
 if p.resolved and (constructed[value]or not turn)and not p.dirty then return p.resolved end
 local self=owner();local result
 if p.class then
  if not p.skill or p.skill==''then ai_unsupported('unattributed source SkillCard requires native prototype context',p.class)end
  if turn then result=q(self,'evaluateTurnSkillCard',p.skill,p.class,p.costs,request_view(self,p.request),p.user)
  else ai_unsupported('source SkillCard hypothesis requires matching native source scope',p.class)end
 else
  local suit,number=aggregate(p.costs,p.suit,p.number)
  if turn then
   local printed=q(self,'getEvaluationCard',p.name)
   result=q(self,'evaluateTurnConversion',p.skill,q(printed,'getClassName'),{name=q(printed,'objectName'),skill=p.skill,suit=suit,number=number,subcards=p.costs},request_view(self,p.request))
  elseif p.skill==''and#p.costs==0 and suit==sgs.Card_NoSuit and number==0 then
   result=call(self,'cloneEvaluationCard',p.name)
  else
   result=q(self,'evaluateOwnerViewAsCard',{source_key=p.skill~=''and p.skill or'extra28_printed',skill=p.skill,name=p.name,suit=suit,number=number,subcards=p.costs})
  end
 end
 if result==nil then return nil end
 if constructed[value]and result~=value then result=q(self,"inheritLegacyCardIdentity",result,value)end
 p.resolved=result;p.dirty=false;return result
end
local range_pending
call=function(object,method,...)
 if object==nil then error('attempt to index a nil value',0)end
 -- Source deletion schedules a temporary native allocation for later cleanup;
 -- immutable request-owned views need no mutation or early authority disposal.
 if method=='deleteLater'then return end
 if method=='hasFlag'and source_flag_read then local v,k=source_flag_read(object,...);if k then return v end end
 if previews[object]or constructed[object]then
  if method=='deleteLater'or method=='setSkillName'or method=='addSubcard'or method=='addSubcards'or method=='clearSubcards'then return mutate(object,method,...)end
  object=known(resolve_preview(object),'extra readonly source card')
 end
 local args=table.pack(...)
 for i=1,args.n do if previews[args[i]]or constructed[args[i]]then args[i]=resolve_preview(args[i])end end
 if type(object[method])~='function'then ai_unsupported('extra policy helper unavailable',method)end
 local values
 if object==current_ai and method=='aiUseCard'and range_pending then
  values=table.pack(object:withOwnerRange('InfinityAttackRange',current_key,function()return object[method](object,table.unpack(args,1,args.n))end))
 else values=table.pack(object[method](object,table.unpack(args,1,args.n)))end
 if AIUnsupported.is(values[1])then error(values[1],0)end
 return table.unpack(values,1,values.n)
end
q=function(object,method,...)
 local provider=object and object[method]
 local values=table.pack(call(object,method,...))
 if values[1]==nil and type(SmartAIView.isKnownNilStrategyResult)=='function'
  and SmartAIView.isKnownNilStrategyResult(object,method,provider)then return table.unpack(values,1,values.n)end
 known(values[1],method);return table.unpack(values,1,values.n)
end
local function sorted(self,cards,method,...)
 local result=q(self,method,cards,...);for i,c in ipairs(result)do cards[i]=c end;return cards
end
local function sort_players(self,cards,...)return sorted(self,cards,'sort',...)end
local function sort_keep(self,cards,...)return sorted(self,cards,'sortByKeepValue',...)end
local function sort_use(self,cards,...)return sorted(self,cards,'sortByUseValue',...)end
local function sort_priority(self,cards,...)return sorted(self,cards,'sortByUsePriority',...)end
local function dummy(value,extra,targets)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=targets or{};return u end
local function isCurrent(use,to)
 if type(use.current_targets)=='table'then for _,p in ipairs(use.current_targets)do if p==to or p==q(to,'objectName')then return true end end end
end
local function source_can_to(card,from,to,prefix)return q(resolve_preview(card),'targetFilter',AIList.new(prefix or{}),to,from)end
local function source_helper(name,...)return q(owner(),name,...)end
local function printed(self,name)return q(self,'getEvaluationCard',name)end
local function history_available(self,c,n)return q(q(self,'getEvaluationCandidate',c),'isAvailableWithHistoryOffset',n,'Slash')end
-- Whether the Room VM loaded this global helper is not projected.
local function source_global(self,name,...)
 ai_unsupported('Room-VM global presence is not projected','extra.'..name)
end
-- R29 finite constructor pairs. A source class is not an activation alias;
-- both fill and use_func consume the actual request forwarded by decision-core.
local extra29_prototypes={gd_zezhu='#gd_zezhu',guandu_shicai='#guandu_shicai',
 guandu_yuanlue='#guandu_yuanlue',twyj_huzhu='#twyj_huzhu',
 twyj_qijia='#twyj_qijia',twyj_rangyi='#twyj_rangyi',twyj_zhuchen='#twyj_zhuchen'}
local extra29_classes={};for skill,class in pairs(extra29_prototypes)do extra29_classes[class]=skill end
local function source_activation(self,class)
 local expected=extra29_classes[class]
 if expected then
  local request=known(request_view(self),'extra source activation request')
  local skill=q(request,'getActivationSkillName')
  if skill~=expected then ai_unsupported('source prototype does not match actual activation',class)end
  -- evaluateTurnSkillCard separately validates all six source identity fields
  -- against the issued scope. Preserve the request rather than synthesizing one.
  return skill,request
 end
 local skill=current_key and current_key:match('^extra:ai_fill_skill%.(.+)$')
 if not skill then ai_unsupported('existing source prototype requires exact activation mapping',class)end
 return skill,request_view(self)
end
local function parse_source(wire)
 local self=owner();if type(wire)~='string'then error('Card_Parse requires a string',0)end
 if wire:match('^%d+$')then return disclosed(tonumber(wire))end
 local class,raw,user=wire:match('^(#[^:]+):([^:]*):(.*)$')
 if not class then class,raw=wire:match('^@([^=]+)=(.*)$')end
 if class then
  -- Whether a legacy Card_Parse prototype exists is an engine query that is not
  -- projected; the construction below stays for when it is.
  ai_unsupported('legacy prototype presence is not projected','extra prototype '..class)
  local skill,request=source_activation(self,class)
  local costs={};for v in (raw or''):gmatch('%d+')do costs[#costs+1]=tonumber(v)end
  local r=q(self,'evaluateTurnSkillCard',skill,class,costs,request,user~=''and user or nil)
  constructed[r]={class=class,costs=costs,skill=skill,request=current_request,user=user~=''and user or nil,resolved=r}
  return r
 end
 ai_unsupported('source Card_Parse grammar needs native proposal bridge','extra.Card_Parse:'..wire)
end
local function begin_range()range_pending=true end
local function end_range()range_pending=nil end
local shadow_flag_names={AI_doNotInvoke_yinghun=true,AI_heg_huyuanToChoose=true}
local function flag_memory(self,player)
 local name=q(player,'objectName');local epochs=known(AIWorldLifecycle.epochs(self.world,'flag'),'flag clear epochs')
 local epoch=known(epochs[name],'flag clear epoch '..name)
 local saved=self:getStrategyMemory('extra.flags');local state={}
 if type(saved)=='table'then for k,v in pairs(saved)do state[k]=v end end
 local old=state[name];local row={epoch=epoch,values={}}
 if type(old)=='table'and old.epoch==epoch and type(old.values)=='table'then for k,v in pairs(old.values)do row.values[k]=v end end
 state[name]=row;return state,row
end
source_flag_read=function(player,flag)
 if not shadow_flag_names[flag]then return nil,false end
 local self=owner();local _,row=flag_memory(self,player)
 if type(row.values[flag])=='boolean'then return row.values[flag],true end
 return nil,false
end
local function source_flag(self,player,flag)
 local remove=flag:sub(1,1)=='-';local key=remove and flag:sub(2)or flag
 if not shadow_flag_names[key]then ai_unsupported('source gameplay flag write has no isolated action contract','extra.flag:'..flag)end
 local state,row=flag_memory(self,player);row.values[key]=not remove;self:setStrategyMemory('extra.flags',state)
end
local function source_choice(self,key,value)
 if key~='heg_tianxiang'then ai_unsupported('unaudited source choice mutation',key)end
 self:setStrategyMemory('choice_override:'..key,value)
end
local function legacy_result_string(value,key)
 if type(value)=='table'then ai_unsupported('source caller needs serialized result of migrated callback',key)end
 return value
end
local function source_global_clone(name)
 ai_unsupported('source global card prototype requires exact native scoped construction',name)
end
local function foreign_keep(self,who,card)
 if who==self.player then return q(self,'getKeepValue',card)end
 ai_unsupported('another viewer keep-value memory is private','extra.heg_huaiyi.keep')
end
local function match_pattern(pattern,player,card)return q(owner(),'matchesDiscardPattern',pattern,resolve_preview(card))end
local function source_general(name)
 ai_unsupported('source general metadata requires lawful public or owner witness','extra.general:'..tostring(name))
end
local function struct(row,kind)
 local self=owner();if type(row)~='table'then ai_unsupported('scoped source struct unavailable',current_key)end
 local copy={};for k,v in pairs(row)do copy[k]=v end
 local function player(name)if name==nil or name==false or name==''then return nil end;return q(self.room,'findPlayerByObjectName',name,true)end
 for _,k in ipairs{'from','who'}do if type(copy[k])=='string'then copy[k]=player(copy[k])end end
 if kind=='use'then local to=AIList.new{};for _,n in ipairs(copy.to or copy.targets or{})do to[#to+1]=player(n)end;copy.to=to
 elseif type(copy.to)=='string'then copy.to=player(copy.to)end
 if copy.card then copy.card=CardView.new(copy.card)end;if copy.amount~=nil then copy.damage=copy.amount end
 return copy
end
local function tag_value(key,player_tag)
 local self=owner();local context=q(self,'getDecisionContext');local value
 if key=='CurrentDamageStruct'then
  -- Its asks carry no data, so the context damage is the CurrentDamageStruct room tag;
  -- an absent tag reads as the donor's default DamageStruct.
  local raw=type(self.request.options)=='table'and self.request.options.context
  value=type(raw)=='table'and raw.damage or{amount=1,nature=sgs.DamageStruct_Normal}
 elseif key:match('^UseHistory')then
  local row=known(context.extra28_use_history,'extra current use history');if row.key~=key then ai_unsupported('current use history identity mismatch',key)end;value=row.use
 else value=known(context.extra28,'extra current question')[key]end
 known(value,key)
 return {toDamage=function()return struct(value,'damage')end,toCardUse=function()return struct(value,'use')end,
 toPlayer=function()if value==false then return nil end;return q(self.room,'findPlayerByObjectName',value,true)end,
 toString=function()if value==false then return''end;return known(type(value)=='string'and value or nil,key)end,
 toJudge=function()return q(self,'getScopedJudge',value)end}
end
local function room_tag(key)return tag_value(key,false)end
local function owner_tag(key)return tag_value(key,true)end
local function extra_alias(row)ai_audited_aliases.register(row)end


local guandu_shicai_skill = {}
guandu_shicai_skill.name = "guandu_shicai"
table.insert(package_skills, guandu_shicai_skill)
guandu_shicai_skill.getTurnUseCard = function(self,inclusive,request)
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if q(c,"hasFlag","guandu_shicai") then return end
	end
	-- Only the source's used top-card face needs evaluation. Preserve the
	-- canDiscard short circuit; this never obtains or temporarily owns the top.
	if q(self.player,"canDiscard",self.player, "he") and q(self,"getUseValue",q(self,"getShicaiPreviewEvaluation")) >= 5 then
		return parse_source("#guandu_shicai:.:")
	end
end

sgs.ai_skill_use_func["#guandu_shicai"] = function(card,use,self,request)
	local usable_cards = AIList.new(q(self.player,"getCards","he"))
	sort_use(self,usable_cards)
	local use_card = {}
	for _,c in ipairs(usable_cards) do
		if q(self,"getUseValue",c) < 5 then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return end
	local card_str = string.format("#guandu_shicai:%s:", use_card[1]:getEffectiveId())
	local acard = parse_source(card_str)
	use.card = acard
end

sgs.ai_use_priority["guandu_shicai"] = 7
sgs.ai_use_value["guandu_shicai"] = 7

sgs.ai_card_priority.guandu_shicai = function(self,card,v)
	if q(card,"hasFlag","guandu_shicai")
	then return 10 end
end

sgs.ai_skill_invoke["chenggong"] = function(self, data)
	local target_name = q(data,"toString"):split(":")[2]
	local target = nil
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"objectName") == target_name then
			target = p
		end
	end
	return target and q(self,"isFriend",target)
end

sgs.ai_choicemade_filter.skillInvoke["chenggong"] = function(self, player, promptlist)
    local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1]:split(":")[2]) 
	if target then
		if promptlist[#promptlist] == "yes" then
            
			call(self,"updateIntention",player, target, -20)
		else
			call(self,"updateIntention",player, target, 20)
		end
	end
end

local gd_zezhu_skill = {}
gd_zezhu_skill.name = "gd_zezhu"
table.insert(package_skills, gd_zezhu_skill)
gd_zezhu_skill.getTurnUseCard = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#gd_zezhu") then
		return parse_source("#gd_zezhu:.:")
	end
end

sgs.ai_skill_use_func["#gd_zezhu"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local targets = {}
	if q(self.player,"isLord") then
		for _, enemy in ipairs(self.enemies) do
			if (q(enemy,"getEquips"):length() > 0 or q(enemy,"getHandcardNum") == 1) and #targets < 2 then
				table.insert(targets, enemy)
			end
		end
	else
		table.insert(targets, call(self.room,"getLord"))
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isLord") and (q(enemy,"getEquips"):length() > 0 or q(enemy,"getHandcardNum") == 1) and #targets < 2 then
				table.insert(targets, enemy)
			end
		end
	end
	local use_checker = true
	local handcards = AIList.new(q(self.player,"getCards","h"))
	for _,c in ipairs(handcards) do
		if q(self,"getUseValue",c) < 2 then
			use_checker = false
		end
	end
	if #handcards == 0 then return end
	if #targets == 0 then return end
	if use_checker then return end
	use.card = card
	if use.to then
		for i = 1, #targets, 1 do
			call(use.to,"append",targets[i])
		end
	end
end

sgs.ai_use_priority["gd_zezhu"] = 7
sgs.ai_use_value["gd_zezhu"] = 7

sgs.ai_skill_cardask["@gd_zezhu-give"] = function(self, data, pattern, target, target2)
	local handcards = AIList.new(q(self.player,"getCards","h"))
	sort_use(self,handcards, true)
	for _,c in ipairs(handcards) do
		return q(c,"getLegacyStringKey")
	end
end

sgs.ai_skill_invoke.guandu_hengjiang = sgs.ai_skill_invoke.hengjiang
sgs.ai_choicemade_filter.skillInvoke.guandu_hengjiang = sgs.ai_choicemade_filter.skillInvoke.hengjiang

local guandu_yuanlue_skill = {}
guandu_yuanlue_skill.name = "guandu_yuanlue"
table.insert(package_skills, guandu_yuanlue_skill)
guandu_yuanlue_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"isNude") or #self.enemies == 0 or #self.friends_noself == 0 then return end
	local card_id
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for _, acard in ipairs(cards) do
		if not q(acard,"isKindOf","EquipCard") then
			card_id = q(acard,"getEffectiveId")
			break
		end
	end
	if not card_id then
	    return nil
	else
	    return parse_source("#guandu_yuanlue:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#guandu_yuanlue"] = function(card,use,self,request)
    if not q(self.player,"isNude") then
        sort_players(self,self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
		    if friend and not q(self,"needKongcheng",friend, true) then
				use.card = card
			    if use.to then call(use.to,"append",friend) end
		        return
			end
	    end
	end
	return nil
end

sgs.ai_use_value.guandu_yuanlue = 8.5
sgs.ai_use_priority.guandu_yuanlue = 9.5
sgs.ai_card_intention.guandu_yuanlue = -80
sgs.ai_skill_invoke.guandu_fuyuan = function(self, data)
    local current = call(self.room,"getCurrent")
    if current then
        if q(current,"getHandcardNum") <= q(self.player,"getHandcardNum") then
            return q(self,"canDraw",current, self.player) and q(self,"isFriend",current)
        end
    end
    return true
end
sgs.ai_choicemade_filter.skillInvoke.guandu_fuyuan = function(self, player, promptlist)
    local current = call(self.room,"getCurrent")
    if promptlist[#promptlist] == "yes" then
        if current and q(current,"getHandcardNum") < q(self.player,"getHandcardNum") then
            call(self,"updateIntention",player, current, -40)
        end
    end
end

sgs.ai_skill_playerchosen.guandu_zhongjie = function(self,targets)
	local first,second
	targets = AIList.new(targets)
	sort_players(self,targets,"defense")
	for _,friend in ipairs(targets)do
		if q(self,"isFriend",friend) and q(friend,"isAlive") and q(self,"canDraw",friend, self.player) then
			if isLord(friend) and q(self,"isWeak",friend) then return friend end
			if q(self,"getRoleEstimate",friend)=="renegade" then second = friend
			elseif q(self,"getRoleEstimate",friend)~="renegade" and not first then first = friend
			end
		end
	end
	return first or second
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|guandu_zhongjie"




sgs.ai_skill_cardask["@guandu_jieliang"] = function(self, data, pattern, target)
	local current = call(self.room,"getCurrent")
	local usable_cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,usable_cards)
	if current and q(self,"isEnemy",current) then
		for _, c in ipairs(usable_cards) do
				return q(c,"getLegacyStringKey")
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@guandu_jieliang"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player, current, 80)
	end
end
sgs.ai_skill_invoke.guandu_jieliang = true


function SmartAIView:useCardYuanjun(card,use)
	sort_players(self,self.friends,"hp")
	local extraTarget = 1 + q(card,"getTargetModExtra",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends_noself)do do 
		if isCurrent(use,ep) then goto package_continue_1 end
		if q(self.player,"canUse",card,ep) then
	    	use.card = card
	    	call(use.to,"append",ep)
	    	if q(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_1:: end
end
sgs.ai_use_priority.Yuanjun = 2.4
sgs.ai_keep_value.Yuanjun = 2.2
sgs.ai_use_value.Yuanjun = 4.7
sgs.ai_card_intention.Yuanjun = -33



function SmartAIView:useCardTunliang(card,use)
	sort_players(self,self.friends,"hp")
	local extraTarget = 2 + q(card,"getTargetModExtra",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends)do do 
		if isCurrent(use,ep) then goto package_continue_2 end
		if q(self.player,"canUse",card,ep) and q(self,"canDraw",ep, self.player) then
	    	use.card = card
	    	call(use.to,"append",ep)
	    	if q(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_2:: end
end
sgs.ai_use_priority.Tunliang = 2.4
sgs.ai_keep_value.Tunliang = 2.2
sgs.ai_use_value.Tunliang = 4.7
sgs.ai_card_intention.Tunliang = -33



function SmartAIView:useCardXujiu(card,use)
	local extraTarget = q(card,"getTargetModExtra",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	if q(card,"subcardsLength")+q(self,"getOverflow")>1 and not(q(self.player,"hasEquip",card) or q(self,"isWeak") or q(self,"hasLoseHandcardEffective"))
	or q(card,"getEffectiveId")>=0 and call(self.room,"getCardOwner",q(card,"getEffectiveId"))~=self.player then 
		for _, enemy in ipairs(self.enemies) do
			if source_can_to(card,self.player,enemy) then
				use.card = card
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
	elseif self.request.reason==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		if q(self.room,"getTurnCount")<=1 and self.role=="renegade" and q(self,"isLordHealthy") and q(self,"getOverflow")<2
		or q(self.player,"hasFlag","canshi") and q(self.player,"getHandcardNum")<3
		then return end
		local n,cs = 0,{}
		for _,c in ipairs(q(self,"sortByDynamicUsePriority",q(self,"getCards","Slash")))do do 
			if q(c,"getSubcards"):contains(q(card,"getEffectiveId")) then goto package_continue_3 end
			local can=history_available(self,c,n)
			can = can and call(self,"aiUseCard",c)
			if can and can.card then
				table.insert(cs,can)
				n = n+1
			end
		end ::package_continue_3:: end
		if #cs<1 then return end
		for i,d in ipairs(cs)do
			for _,to in sgs.qlist(d.to)do do 
				if q(self,"isFriend",to)
				or q(to,"getHandcardNum")>0 and q(self,"getOverflow")<0 and q(to,"hasSkill","anxian")
				or q(to,"hasSkills","zhenlie|mobilejxtpjinjiu")
				then goto package_continue_4 end
				if q(d.card,"hasFlag","Qinggang") and q(to,"hasArmorEffect","silver_lion") then
				else
					local da = q(self,"ajustDamage",self.player,to,2,d.card)
					
				end
				n = getKnownCard(to,self.player,"Jink",true,"he")
				if n>0 and q(self,"getOverflow")<2
				then goto package_continue_4 end
			
				if isCurrent(use,to) then goto package_continue_4 end
				if q(self.player,"canUse",card,to) then
					use.card = card
					call(use.to,"append",to)
					if q(use.to,"length")>extraTarget
					then return end
				end
			end ::package_continue_4:: end
		end
	end
end

sgs.ai_use_value.Xujiu = 5.98
sgs.ai_keep_value.Xujiu = 2.1
sgs.ai_use_priority.Xujiu = 10

sgs.ai_ajustdamage_to["&gd_xujiu"] = function(self,from,to,card,nature)
	return 1
end


sgs.ai_skill_playerchosen.gd_zhanyanliangzhuwenchou = function(self,targets)
	local card = clone_source("Duel", sgs.Card_NoSuit, 0)
	call(card,"setSkillName","gd_zhanyanliangzhuwenchou")
	call(card,"deleteLater")
	if source_helper("hasZhaxiangEffect",self.player) and not q(self,"isWeak") then return nil end
	targets = AIList.new(targets)
	local dummy_use = call(self,"aiUseCard",card, dummy())
    if dummy_use.card and dummy_use and dummy_use.to then
		for _,p in sgs.list(dummy_use.to)do
			if table.contains(targets, p) then
				return p
			end
		end
	end
	return targets[1]
end







sgs.ai_skill_choice["yinghun_po"] = function(self, choices)
	return self.yinghun_pochoice
end
sgs.ai_skill_playerchosen.yinghun_po = function(self, targets)
	if q(self.player,"hasFlag","AI_doNotInvoke_yinghun") then
		source_flag(self,self.player,"-AI_doNotInvoke_yinghun")
		return
	end
	local x = q(self.player,"getLostHp")
	if q(self.player,"getCards","e"):length() >= q(self.player,"getHp") then x = q(self.player,"getMaxHp")end
	local n = x - 1
	call(self,"updatePlayers")
	if x == 1 and #self.friends == 1 then
		for _, enemy in ipairs(self.enemies) do
			if q(enemy,"hasSkill","manjuan") then
				return enemy
			end
		end
		return nil
	end

	self.yinghun_po = nil
	local player = call(self,"AssistTarget")

	if x == 1 then
		sort_players(self,self.friends_noself, "handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"hasSkills",sgs.lose_equip_skill, friend) and q(friend,"getCards","e"):length() > 0
			  and not q(friend,"hasSkill","manjuan") then
				self.yinghun_po = friend
				break
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if hasTuntianEffect(friend, true) and not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if q(self,"needToThrowArmor",friend) and not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po then
			for _, enemy in ipairs(self.enemies) do
				if q(enemy,"hasSkill","manjuan") then
					return enemy
				end
			end
		end

		if not self.yinghun_po and player and not q(player,"hasSkill","manjuan") and q(player,"getCardCount",true) > 0 and not q(self,"needKongcheng",player, true) then
			self.yinghun_po = player
		end

		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if q(friend,"getCards","he"):length() > 0 and not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end

		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
	elseif #self.friends > 1 then
		sort_players(self,self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"hasSkills",sgs.lose_equip_skill, friend) and q(friend,"getCards","e"):length() > 0
			  and not q(friend,"hasSkill","manjuan") then
				self.yinghun_po = friend
				break
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if hasTuntianEffect(friend, true) and not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if q(self,"needToThrowArmor",friend) and not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po and #self.enemies > 0 then
			local wf
			if q(self.player,"isLord") then
				if q(self,"isWeak") and (q(self.player,"getHp") < 2 and q(self,"getCardsNum","Peach") < 1) then
					wf = true
				end
			end
			if not wf then
				for _, friend in ipairs(self.friends_noself) do
					if q(self,"isWeak",friend) then
						wf = true
						break
					end
				end
			end

			if not wf then
				sort_players(self,self.enemies, "chaofeng")
				for _, enemy in ipairs(self.enemies) do
					if q(enemy,"getCards","he"):length() == n
						and q(self,"doDisCard",enemy, "he", false, n) then
						self.yinghun_pochoice = "yinghun1"
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if q(enemy,"getCards","he"):length() >= n
						and  q(self,"doDisCard",enemy, "he", false, n)
						and q(self,"hasSkills",sgs.cardneed_skill, enemy) then
						self.yinghun_pochoice = "yinghun1"
						return enemy
					end
				end
			end
		end

		if not self.yinghun_po and player and not q(player,"hasSkill","manjuan") and not q(self,"needKongcheng",player, true) then
			self.yinghun_po = player
		end

		if not self.yinghun_po then
			self.yinghun_po = call(self,"findPlayerToDraw",false, n)
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if not q(friend,"hasSkill","manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if self.yinghun_po then self.yinghun_pochoice = "yinghun2" end
	end
	if not self.yinghun_po and x > 1 and #self.enemies > 0 then
		sort_players(self,self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if q(enemy,"getCards","he"):length() >= n
				and q(self,"doDisCard",enemy, "he", false, n) then
				self.yinghun_pochoice = "yinghun1"
				return enemy
			end
		end
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isNude")
				and not (q(self,"hasSkills",sgs.lose_equip_skill, enemy) and q(enemy,"getCards","e"):length() > 0)
				and not q(self,"needToThrowArmor",enemy)
				and not hasTuntianEffect(enemy, true) then
				self.yinghun_pochoice = "yinghun1"
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isNude")
				and not (q(self,"hasSkills",sgs.lose_equip_skill, enemy) and q(enemy,"getCards","e"):length() > 0)
				and not q(self,"needToThrowArmor",enemy)
				and not (hasTuntianEffect(enemy, true) and x < 3 and q(enemy,"getCards","he"):length() < 2) then
				self.yinghun_pochoice = "yinghun1"
				return enemy
			end
		end
	end

	return self.yinghun_po
end

extra_alias{ id="ai_cardneed.yinghun_po",registry="ai_cardneed",path={"yinghun_po"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|yinghun_po"
sgs.need_equip_skill = sgs.need_equip_skill .. "|yinghun_po"

sgs.ai_playerchosen_intention.yinghun_po = function(self,from,to)
	if q(from,"getLostHp")>1 or q(from,"getEquips"):length() >= q(from,"getHp") then return end
	local intention = -80
	if q(to,"hasSkill","manjuan") then intention = -intention end
	call(self,"updateIntention",from,to,intention)
end

sgs.ai_choicemade_filter.skillChoice.yinghun_po = function(self,player,promptlist)
	local to
	for _,p in sgs.qlist(q(self.room,"getOtherPlayers",player))do
		if q(p,"hasFlag","yinghun_poTarget") then
			to = p
			break
		end
	end
	local choice = promptlist[#promptlist]
	local intention = (choice=="yinghun2") and -80 or 80
	call(self,"updateIntention",player,to,intention)
end

sgs.ai_getBestHp_skill.yinghun_po = function(owner)
	return q(owner,"getMaxHp") - 2
end

sgs.ai_fill_skill.heg_xianqu = function(self,inclusive,request)
	if #self.enemies == 0 then return nil end
	if q(self.player,"getHandcardNum") < 4 then 
		return parse_source("#heg_xianqu:.::")
	end
	return nil
end

sgs.ai_skill_use_func["#heg_xianqu"] = function(card,use,self,request)
	sort_players(self,self.enemies, "handcard")
	for _,enemy in ipairs(self.enemies) do
		if not q(enemy,"isKongcheng") then
			use.card = card
			if use.to then
				call(use.to,"append",enemy)
			end
			return
		end
	end
end

sgs.ai_fill_skill.heg_yinyangyu = function(self,inclusive,request)
	if q(self,"needBear") then return nil end
	if q(self,"isWeak") and q(self,"getOverflow") <= 0 then 
		return parse_source("#heg_yinyangyu:.::")
	end
	return nil
end

sgs.ai_skill_use_func["#heg_yinyangyu"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority["heg_yinyangyu"] = 10

sgs.ai_skill_invoke.heg_yinyangyu = function(self, data)
	if q(self,"getOverflow") > 1 then
		return true
	end
	return false
end


source_use_registry["@heg_mouduan"] = function(self, prompt, method)
	call(self,"updatePlayers")
	local selectset = {}
	for _,friend in ipairs(self.friends) do
		if q(friend,"containsTrick","indulgence") or q(friend,"containsTrick","supply_shortage") then
			for _,enemy in ipairs(self.enemies) do
				if #selectset == 0 and q(enemy,"getJudgingArea"):isEmpty() then
					table.insert(selectset, q(friend,"objectName"))
				end
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if not q(enemy,"getEquips"):isEmpty() then
			for _, e in ipairs(AIList.new(q(enemy,"getCards","e"))) do
				local equip_index = q(e,"getRealCard"):toEquipCard():location()
				for _,friend in ipairs(self.friends) do
					if #selectset == 0 and call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
						table.insert(selectset, q(enemy,"objectName"))
					end
				end
			end
		end
	end
	if #selectset > 0 then
		return "#heg_mouduan:.:->" .. selectset[1]
	end
	return "."
end

sgs.ai_skill_cardchosen["heg_mouduan"] = function(self, who, flags)
	call(self,"updatePlayers")
	if q(self,"isEnemy",who) and call(flags,"match","e") then
		for _, e in ipairs(AIList.new(q(who,"getCards",flags))) do
			local equip_index = q(e,"getRealCard"):toEquipCard():location()
			for _,friend in ipairs(self.friends) do
				if call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
					return q(e,"getEffectiveId")
				end
			end
		end
	end
end

extra_alias{ id="ai_choicemade_filter.cardChosen.heg_mouduan",registry="ai_choicemade_filter",path={"cardChosen","heg_mouduan"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_playerchosen["heg_mouduan"] = function(self, targets)
	local ol_jiewei_target = room_tag("heg_mouduanTarget"):toPlayer()
	local targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	if q(self,"isFriend",ol_jiewei_target) then
		for _,p in ipairs(targets) do
			if q(self,"isEnemy",p) then
				return p
			end
		end
	else
		for _,p in ipairs(targets) do
			if q(self,"isFriend",p) then
				return p
			end
		end
	end
	for _,p in ipairs(targets) do
		return p
	end
end


sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_paoxiao"

sgs.ai_use_revises.heg_paoxiao = function(self,card,use)
	if q(card,"isKindOf","Crossbow")
	then return false end
end
extra_alias{ id="ai_cardneed.heg_paoxiao",registry="ai_cardneed",path={"heg_paoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3,defer_canonical=true}
sgs.ai_target_revises.heg_kongcheng = function(to,card)
	if q(card,"isKindOf","Slash") and q(to,"isKongcheng")
	then return true end
end

sgs.need_kongcheng = sgs.need_kongcheng .. "|heg_kongcheng"


local heg_longdan_skill={}
heg_longdan_skill.name="heg_longdan"
table.insert(package_skills,heg_longdan_skill)
heg_longdan_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	local jink_card
	sort_use(self,cards,true)
	for _,card in ipairs(cards)  do
		if q(card,"isKindOf","Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	local suit = q(jink_card,"getSuitString")
	local number = q(jink_card,"getNumberString")
	local card_id = q(jink_card,"getEffectiveId")
	local card_str = ("slash:heg_longdan[%s:%s]=%d"):format(suit,number,card_id)
	local slash = parse_source(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.heg_longdan = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand then
		if q(card,"isKindOf","Jink") then
			return ("slash:heg_longdan[%s:%s]=%d"):format(suit,number,card_id)
		elseif q(card,"isKindOf","Slash") then
			return ("jink:heg_longdan[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.heg_longdan_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

sgs.ai_card_priority.heg_longdan = function(self,card)
	if table.contains(q(card,"getSkillNames"), "heg_longdan")
	then
		return 1
	end
end
sgs.ai_skill_playerchosen.heg_longdan = function(self, targets)
	return q(self,"findBestDamageTarget",1, "N", 0, nil)[1]
end
sgs.ai_skill_playerchosen["heg_longdan_recover"] = function(self, targets)
	local arr1, arr2 = q(self,"getWoundedFriend",false, true)
	local target = nil

	if #arr1 > 0 and (q(self,"isWeak",arr1[1])) and arr1[1]:getHp() < source_helper("getBestHp",arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2>0 then
		for _,friend in ipairs(arr2)do
			return friend
		end
	end
	for _,friend in ipairs(self.friends) do
		if q(friend,"getHp") < source_helper("getBestHp",friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_skill_invoke.heg_jushou = function(self,data)
	local draw = getKingdoms(self.player)
	if draw <= 2 then
		return true
	end
	return sgs.ai_skill_invoke.tenyearjushou(self, data)
end


heg_duanliang_skill={}
heg_duanliang_skill.name="heg_duanliang"
table.insert(package_skills,heg_duanliang_skill)
heg_duanliang_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	local card
	sort_use(self,cards,true)
	for _,acard in ipairs(cards)  do
		if (q(acard,"isBlack")) and (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard")) and (q(self,"getDynamicUsePriority",acard)<sgs.ai_use_value.SupplyShortage)then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	return parse_source(("supply_shortage:heg_duanliang[%s:%s]=%d"):format(suit,number,card_id))
end

sgs.ai_cardneed.heg_duanliang = function(to,card,self)
	return q(card,"isBlack") and q(card,"getTypeId")~=sgs.Card_TypeTrick and getKnownCard(to,self.player,"black",false)<2
end

sgs.heg_duanliang_suit_value = {
	spade = 3.9,
	club = 3.9
}


local function getKurouCard(self,not_slash)
	local card_id
	local hold_crossbow = (q(self,"getCardsNum","Slash")>1)
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local lightning = call(self,"getCard","Lightning")

	if q(self,"needToThrowArmor") then
		card_id = call(self.player,"getArmor"):getId()
	elseif q(self.player,"getHandcardNum")>q(self.player,"getHp") then
		if lightning and not q(self,"willUseLightning",lightning) then
			card_id = q(lightning,"getEffectiveId")
		else
			for _,acard in ipairs(cards)do
				if (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace"))
					and not q(self,"isValuableCard",acard) and not (q(acard,"isKindOf","Crossbow") and hold_crossbow)
					and not (q(acard,"isKindOf","Slash") and not_slash) then
					card_id = q(acard,"getEffectiveId")
					break
				end
			end
		end
	elseif not q(self.player,"getEquips"):isEmpty() then
		if call(self.player,"getOffensiveHorse") then card_id = call(self.player,"getOffensiveHorse"):getId()
		elseif call(self.player,"getWeapon") and q(self,"evaluateWeapon",call(self.player,"getWeapon"))<3
				and not (call(self.player,"getWeapon"):isKindOf("Crossbow") and hold_crossbow) then card_id = call(self.player,"getWeapon"):getId()
		elseif call(self.player,"getArmor") and q(self,"evaluateArmor",call(self.player,"getArmor"))<2 then card_id = call(self.player,"getArmor"):getId()
		end
	end
	if not card_id then
		if lightning and not q(self,"willUseLightning",lightning) then
			card_id = q(lightning,"getEffectiveId")
		else
			for _,acard in ipairs(cards)do
				if (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace"))
					and not q(self,"isValuableCard",acard) and not (q(acard,"isKindOf","Crossbow") and hold_crossbow)
					and not (q(acard,"isKindOf","Slash") and not_slash) then
					card_id = q(acard,"getEffectiveId")
					break
				end
			end
		end
	end
	return card_id
end
local heg_kurou_skill = {}
heg_kurou_skill.name = "heg_kurou"
table.insert(package_skills,heg_kurou_skill)
heg_kurou_skill.getTurnUseCard = function(self,inclusive,request)
	if (q(self.player,"getHp")==2 and q(self.player,"hasSkill","chanyuan")) then return end
	if (q(self.player,"getHp")>3 and q(self.player,"getHandcardNum")>q(self.player,"getHp"))
	or (q(self.player,"getHp")-q(self.player,"getHandcardNum")>=2)
	then
		local id = getKurouCard(self)
		if id then return parse_source("#heg_kurou:"..id..":") end
	end

	local function can_heg_kurou_with_cb(self)
		if q(self.player,"getHp")>1 then return true end
		local has_save = false
		local huatuo = call(self.room,"findPlayerBySkillName","jijiu")
		if huatuo and q(self,"isFriend",huatuo) then
			for _,equip in sgs.list(q(huatuo,"getEquips"))do
				if q(equip,"isRed") then has_save = true break end
			end
			if not has_save then has_save = (q(huatuo,"getHandcardNum")>3) end
		end
		if has_save then return true end
		local handang = call(self.room,"findPlayerBySkillName","nosjiefan")
		if handang and q(self,"isFriend",handang) and getCardsNum("Slash",handang,self.player)>=1 then return true end
		return false
	end

	if (q(self.player,"hasWeapon","crossbow") or q(self,"getCardsNum","Crossbow")>0) or q(self,"getCardsNum","Slash")>1 then
		local slash = clone_source()
		for _,enemy in ipairs(self.enemies)do
			if q(self.player,"canSlash",enemy) and q(self,"slashIsEffective",slash,enemy)
				and q(self,"isGoodTarget",enemy,self.enemies,slash) and not q(self,"slashProhibit",slash,enemy) and can_heg_kurou_with_cb(self) then
				local id = getKurouCard(self,true)
				if id then return parse_source("#heg_kurou:"..id..":") end
			end
		end
	end
end

sgs.ai_skill_use_func["#heg_kurou"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority["heg_kurou"] = 6.8

sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_kurou"



source_use_registry["@@heg_shensu1"] = function(self,prompt)
	sort_players(self,self.enemies,"defense")
	if q(self.player,"containsTrick","lightning") and q(self.player,"getCards","j"):length()==1
	and q(self,"hasWizard",self.friends) and not q(self,"hasWizard",self.enemies,true)
	then return "." end

	if q(self,"needBear") then return "." end

	local selfSub = q(self.player,"getHp")-q(self.player,"getHandcardNum")
	local selfDef = q(self,"getDefense",self.player)

	local slash = clone_source()
	call(slash,"setSkillName","heg_shensu")
	local dummy = call(self,"aiUseCard",slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,q(p,"objectName"))
		end
		return "#heg_shensu:.:->"..table.concat(tos,"+")
	end
	return "."
end

source_use_registry["@@heg_shensu2"] = function(self,prompt,method)
	local card_str = source_use_registry["@@shensu2"](self,prompt,method)
	if not card_str or card_str=="." then return "." end
	local new_str = string.gsub(card_str,"@ShensuCard=","#heg_shensu:")
	new_str = string.gsub(card_str,"->",":->")
	return new_str
end

source_use_registry["@@heg_shensu3"] = function(self,prompt)
	sort_players(self,self.enemies,"defense")
	if q(self,"needBear") then return "." end
	local selfSub = q(self,"getOverflow")
	local selfDef = q(self,"getDefense",self.player)
	for _,enemy in ipairs(self.enemies)do
		local def = q(self,"getDefenseSlash",enemy)
		local slash = clone_source()
		call(slash,"setSkillName","_heg_shensu")
		local eff = q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)

		if not q(self.player,"canSlash",enemy,slash,false) then
		elseif q(self,"slashProhibit",nil,enemy) then
		elseif def<6 and eff then return "#heg_shensu:.:->"..q(enemy,"objectName")

		elseif selfSub>=2 then return "#heg_shensu:.:->"..q(enemy,"objectName")
		elseif selfDef<6 then return "." end
	end

	for _,enemy in ipairs(self.enemies)do
		local def=q(self,"getDefense",enemy)
		local slash = clone_source()
		call(slash,"setSkillName","_heg_shensu")
		local eff = q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)

		if not q(self.player,"canSlash",enemy,slash,false) then
		elseif q(self,"slashProhibit",nil,enemy) then
		elseif eff and def<8 then return "#heg_shensu:.:->"..q(enemy,"objectName")
		else return "." end
	end
	return "."
end

sgs.ai_cardneed.heg_shensu = function(to,card,self)
	return sgs.ai_cardneed.shensu(to,card,self)
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_shensu"

sgs.ai_card_intention.heg_shensuCard = sgs.ai_card_intention.ShensuCard
sgs.heg_shensu_keep_value = sgs.shensu_keep_value
sgs.ai_skill_cardask["@heg_luoyi"] = function(self,data)
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_use(self,cards,true)
	if sgs.ai_skill_invoke.nosluoyi(self, data) then
		return "$"..cards[1]:getEffectiveId()
	end
	return "."
end


extra_alias{ id="ai_cardneed.heg_luoyi",registry="ai_cardneed",path={"heg_luoyi"},canonical_registry="ai_cardneed",canonical_path={"nosluoyi"},self_index=3,defer_canonical=true}
local heg_qiangxi_skill = {}
heg_qiangxi_skill.name= "heg_qiangxi"
table.insert(package_skills,heg_qiangxi_skill)
heg_qiangxi_skill.getTurnUseCard=function(self,inclusive,request)
	return parse_source("#heg_qiangxi:.:")
end

sgs.ai_skill_use_func["#heg_qiangxi"] = function(card,use,self,request)
	local weapon = call(self.player,"getWeapon")
	if weapon then
		local hand_weapon,cards
		cards = q(self.player,"getHandcards")
		for _,card in sgs.qlist(cards)do
			if q(card,"isKindOf","Weapon") then
				hand_weapon = card
				break
			end
		end
		sort_players(self,self.enemies)
		self.equipsToDec = hand_weapon and 0 or 1
		for _,enemy in sgs.list(self.enemies)do
			if q(self,"objectiveLevel",enemy)>3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy)
			then
				if hand_weapon then
					use.card = parse_source("#heg_qiangxi:"..q(hand_weapon,"getId")..":")
					call(use.to,"append",enemy)
					break
				end
				use.card = parse_source("#heg_qiangxi:"..q(weapon,"getId")..":")
				call(use.to,"append",enemy)
				return
			end
		end
		self.equipsToDec = 0
	else
		sort_players(self,self.enemies,"hp")
		for _,enemy in sgs.list(self.enemies)do
			if q(self,"objectiveLevel",enemy)>3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy)
			and q(self.player,"getHp")>q(enemy,"getHp") and q(self.player,"getHp")>1
			then
				use.card = parse_source("#heg_qiangxi:.:")
				call(use.to,"append",enemy)
				return
			end
		end
	end
end

sgs.ai_use_value.heg_qiangxi = 2.5
sgs.ai_card_intention.heg_qiangxi = 80
sgs.dynamic_value.damage_card.heg_qiangxi = true
extra_alias{ id="ai_cardneed.heg_qiangxi",registry="ai_cardneed",path={"heg_qiangxi"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}
sgs.heg_qiangxi_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}
sgs.straight_damage_skill = sgs.straight_damage_skill .. "|heg_qiangxi"

sgs.ai_skill_choice["heg_liegong"] = function(self, choices, data)
	local target = q(data,"toPlayer")
	if q(self,"isEnemy",target) and not q(self,"cantDamageMore",self.player, target) and getCardsNum("Jink", target, self.player) < 1 then
		return "heg_liegong_addDamage"
	end
	if not q(self,"isFriend",target) then
		return "heg_liegong_cantjink"
	end
	return "cancel"
end
extra_alias{ id="ai_cardneed.heg_liegong",registry="ai_cardneed",path={"heg_liegong"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.hit_skill = sgs.hit_skill .. "|heg_liegong"

sgs.ai_skill_playerchosen.heg_yinghun = function(self,targets)
	if q(self.player,"isWounded") then
		return sgs.ai_skill_playerchosen.yinghun(self, targets)
	else
		for _,friend in ipairs(self.friends_noself)do
			if q(self,"canDraw",friend, self.player) then
				return friend
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if q(self,"doDisCard",enemy, "he") then
				return enemy
			end
		end
	end

end
sgs.ai_skill_choice.heg_yinghun = function(self,choices, data)
	if q(self.player,"isWounded") then
		return self.yinghunchoice
	else
		local target = q(data,"toPlayer")
		if q(self,"isFriend",target) then
			return "d1tx"
		end
		if q(self,"isEnemy",target) then
			return "dxt1"
		end
	end
	return "d1tx"
end

sgs.ai_getBestHp_skill.heg_yinghun = function(owner)
	return q(owner,"getMaxHp") - 2
end

extra_alias{ id="ai_cardneed.heg_xiaoji",registry="ai_cardneed",path={"heg_xiaoji"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.lose_equip_skill = sgs.lose_equip_skill .. "|heg_xiaoji"
sgs.ai_use_revises.heg_xiaoji = function(self,card,use)
	if q(card,"isKindOf","EquipCard") and q(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end


source_use_registry["@@heg_tianxiang"] = function(self, prompt, method)
	local handcards = AIList.new(q(self.player,"getCards","h"))
	q(self,"sortByCardNeed",handcards, true)
	local use_card = nil
	local target = nil
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "hp")
	sort_players(self,self.friends_noself, "hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,c in ipairs(handcards) do
		if q(c,"getSuit") == sgs.Card_Heart and not q(c,"isKindOf","Peach") then
			use_card = c
		end
	end
	if use_card == nil then return "." end
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"getMark","heg_tianxiang_two-Clear") == 0 then
			source_choice(self,"heg_tianxiang","heg_tianxiang2")
			return "#heg_tianxiang:" .. q(use_card,"getEffectiveId") .. ":->" .. q(enemy,"objectName")
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if q(self.player,"getMark","heg_tianxiang_one-Clear") == 0 then
			source_choice(self,"heg_tianxiang","heg_tianxiang1")
			return "#heg_tianxiang:" .. q(use_card,"getEffectiveId") .. ":->" .. q(friend,"objectName")
		end
	end
	return "."
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|shuangren"


sgs.ai_skill_playerchosen.shushen = function(self,targets)
	if #self.friends_noself==0 then return nil end
	return call(self,"findPlayerToDraw",false,2)
end
sgs.ai_playerchosen_intention.shushen = -80

extra_alias{ id="ai_skill_invoke.heg_yicheng",registry="ai_skill_invoke",path={"heg_yicheng"},canonical_registry="ai_skill_invoke",canonical_path={"yicheng"},self_index=1,defer_canonical=true}
sgs.ai_skill_discard.heg_yicheng = sgs.ai_skill_discard.yicheng

sgs.ai_choicemade_filter.skillInvoke.heg_yicheng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-20) end
	end
end

function sgs.ai_skill_invoke.heg_hengjiang(self,data)
	local target = q(data,"toPlayer")
	if q(self,"isEnemy",target) then
		return true
	else
		if source_helper("hasManjuanEffect",self.player) then return false end
		if q(target,"getPhase")>sgs.Player_Discard then return true end
		if q(target,"hasSkill","yongsi") then return false end
		if q(target,"hasSkill","keji") and not q(target,"hasFlag","KejiSlashInPlayPhase") then return true end
		return q(target,"getHandcardNum")<=q(target,"getMaxCards")-2
	end
end

sgs.ai_choicemade_filter.skillInvoke.heg_hengjiang = function(self,player,promptlist)
	if promptlist[3]=="yes" then
		local current = call(self.room,"getCurrent")
		if current and q(current,"getPhase")<=sgs.Player_Discard
			and not (q(current,"hasSkill","keji") and not q(current,"hasFlag","KejiSlashInPlayPhase")) and q(current,"getHandcardNum")>q(current,"getMaxCards")-2 then
			call(self,"updateIntention",player,current,50)
		end
	end
end

sgs.ai_skill_playerschosen.heg_duoshi = function(self, targets, max, min)
    local selected = AIList.new{}
    local can_choose = AIList.new(targets)
    sort_players(self,can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if q(self,"isFriend",target) then
            call(selected,"append",target)
        end
    end
    return selected
end

local function heg_huyuan_validate(self,equip_type,is_handcard)
	local targets
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type=="SilverLion" then
		for _,enemy in sgs.list(self.enemies)do
			if q(enemy,"hasSkills","yizhong|bazhen") then table.insert(targets,enemy) end
		end
	end
	for _,friend in sgs.list(targets)do
		local has_equip = false
		for _,equip in sgs.list(q(friend,"getEquips"))do
			if q(equip,"isKindOf",equip_type) then
				has_equip = true
				break
			end
		end
		if not has_equip and not ((equip_type=="Armor" or equip_type=="SilverLion") and q(friend,"hasSkills","yizhong|bazhen")) then
			sort_players(self,self.enemies,"defense")
			for _,enemy in sgs.list(self.enemies)do
				if q(friend,"distanceTo",enemy)==1 and q(self.player,"canDiscard",enemy,"he") then
					source_flag(self,enemy,"AI_heg_huyuanToChoose")
					return friend
				end
			end
		end
	end
	return nil
end

source_use_registry["@@heg_huyuan"] = function(self,prompt)
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	if q(self.player,"hasArmorEffect","SilverLion") then
		local player = heg_huyuan_validate(self,"SilverLion",false)
		if player then return "#heg_huyuan:"..call(self.player,"getArmor"):getEffectiveId()..":->"..q(player,"objectName") end
	end
	if call(self.player,"getOffensiveHorse") then
		local player = heg_huyuan_validate(self,"OffensiveHorse",false)
		if player then return "#heg_huyuan:"..call(self.player,"getOffensiveHorse"):getEffectiveId()..":->"..q(player,"objectName") end
	end
	if call(self.player,"getWeapon") then
		local player = heg_huyuan_validate(self,"Weapon",false)
		if player then return "#heg_huyuan:"..call(self.player,"getWeapon"):getEffectiveId()..":->"..q(player,"objectName") end
	end
	if call(self.player,"getArmor") and q(self.player,"getLostHp")<=1 and q(self.player,"getHandcardNum")>=3 then
		local player = heg_huyuan_validate(self,"Armor",false)
		if player then return "#heg_huyuan:"..call(self.player,"getArmor"):getEffectiveId()..":->"..q(player,"objectName") end
	end
	for _,card in sgs.list(cards)do
		if q(card,"isKindOf","DefensiveHorse") then
			local player = heg_huyuan_validate(self,"DefensiveHorse",true)
			if player then return "#heg_huyuan:"..q(card,"getEffectiveId")..":->"..q(player,"objectName") end
		end
	end
	for _,card in sgs.list(cards)do
		if q(card,"isKindOf","OffensiveHorse") then
			local player = heg_huyuan_validate(self,"OffensiveHorse",true)
			if player then return "#heg_huyuan:"..q(card,"getEffectiveId")..":->"..q(player,"objectName") end
		end
	end
	for _,card in sgs.list(cards)do
		if q(card,"isKindOf","Weapon") then
			local player = heg_huyuan_validate(self,"Weapon",true)
			if player then return "#heg_huyuan:"..q(card,"getEffectiveId")..":->"..q(player,"objectName") end
		end
	end
	for _,card in sgs.list(cards)do
		if q(card,"isKindOf","SilverLion") then
			local player = heg_huyuan_validate(self,"SilverLion",true)
			if player then return "#heg_huyuan:"..q(card,"getEffectiveId")..":->"..q(player,"objectName") end
		end
		if q(card,"isKindOf","Armor") and heg_huyuan_validate(self,"Armor",true) then
			local player = heg_huyuan_validate(self,"Armor",true)
			if player then return "#heg_huyuan:"..q(card,"getEffectiveId")..":->"..q(player,"objectName") end
		end
	end
	local c,to = call(self,"getCardNeedPlayer",cards)
	if c and to then return "#heg_huyuan:"..q(c,"getEffectiveId")..":->"..q(to,"objectName") end
end

sgs.ai_skill_playerchosen.heg_huyuan = function(self,targets)
	targets = AIList.new(targets)
	for _,p in sgs.list(targets)do
		if q(p,"hasFlag","AI_heg_huyuanToChoose") then
			source_flag(self,p,"-AI_heg_huyuanToChoose")
			return p
		end
	end
	for _,p in sgs.list(targets)do
		if q(self,"doDisCard",p, "ej") then
			return p
		end
	end
	return targets[1]
end

sgs.ai_card_intention["heg_huyuan"] = function(self,card,from,to)
	if to[1]:hasSkills("bazhen|yizhong") then
		if disclosed(q(card,"getEffectiveId")):isKindOf("SilverLion") then
			call(self,"updateIntention",from,to[1],10)
			return
		end
	end
	call(self,"updateIntention",from,to[1],-50)
end

extra_alias{ id="ai_cardneed.heg_huyuan",registry="ai_cardneed",path={"heg_huyuan"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.heg_huyuan_keep_value = {
	Peach = 6,
	Jink = 5.1,
	EquipCard = 4.8
}


local heg_duanxie_skill = {}
heg_duanxie_skill.name = "heg_duanxie"
table.insert(package_skills,heg_duanxie_skill)
heg_duanxie_skill.getTurnUseCard = function(self,inclusive,request)
	return parse_source("#heg_duanxie:.:")
end
sgs.ai_skill_use_func["#heg_duanxie"] = function(card,use,self,request)
	local x = math.max(q(self.player,"getLostHp"), 1)
	sort_players(self,self.enemies,"handcard")
	local targets = AIList.new{}

	for _,enemy in sgs.list(self.enemies)do
		if not q(enemy,"isChained") and q(enemy,"isKongcheng") then
			if q(targets,"length") >= x then break end
			call(targets,"append",enemy)
		end
	end

	for _,enemy in sgs.list(self.enemies)do
		if not q(enemy,"isChained") and not q(targets,"contains",enemy) then
			if q(targets,"length") >= x then break end
			call(targets,"append",enemy)
		end
	end
	if q(targets,"length") > 0 then
		use.card = card
		if use.to then
			for _,enemy in sgs.list(targets)do
				call(use.to,"append",enemy)
			end
		end
		return
	end

end

sgs.ai_card_intention["heg_duanxie"] = 50
sgs.ai_use_priority["heg_duanxie"] = 0

local heg_nos_guishu_skill = {}
heg_nos_guishu_skill.name = "heg_nos_guishu"
table.insert(package_skills,heg_nos_guishu_skill)
heg_nos_guishu_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	sort_use(self,cards,true)
	for _,acard in sgs.list(cards)do
		if q(acard,"getSuit") == sgs.Card_Spade then
			local c 
			if q(self.player,"getMark","heg_nos_guishu") == 1 then
				c = parse_source("EXCard_YJJG:heg_nos_guishu[no_suit:0]="..q(acard,"getEffectiveId"))
			elseif q(self.player,"getMark","heg_nos_guishu") == 2 then
				c = parse_source("EXCard_ZJZB:heg_nos_guishu[no_suit:0]="..q(acard,"getEffectiveId"))
			else
				c = parse_source("EXCard_YJJG:heg_nos_guishu[no_suit:0]="..q(acard,"getEffectiveId"))
			end
			if c and q(c,"isAvailable",self.player) then return c end
		end
	end
end

sgs.ai_view_as.heg_nos_guishu = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand and suit == "spade" then
		if q(player,"getMark","heg_nos_guishu") == 1 then
			return ("EXCard_YJJG:heg_nos_guishu[%s:%s]=%d"):format(suit,number,card_id)
		elseif q(player,"getMark","heg_nos_guishu") == 2 then
			return ("EXCard_ZJZB:heg_nos_guishu[%s:%s]=%d"):format(suit,number,card_id)
		else
			return ("EXCard_YJJG:heg_nos_guishu[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end
sgs.ai_card_priority.heg_nos_guishu = function(self,card)
	if table.contains(q(card,"getSkillNames"), "heg_nos_guishu") and q(card,"isKindOf","EXCard_ZJZB")
	then return 5 end
end

sgs.ai_ajustdamage_to.heg_nos_yuanyu   = function(self, from, to, card, nature)
	if from and not (q(from,"getNextAlive"):objectName() == q(self.player,"objectName") or q(from,"getNextAlive",q(self.room,"alivePlayerCount") - 1):objectName() == q(self.player,"objectName") )  then
		return -99
	end
end


local heg_guishu_skill = {}
heg_guishu_skill.name = "heg_guishu"
table.insert(package_skills,heg_guishu_skill)
heg_guishu_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	sort_use(self,cards,true)
	for _,acard in sgs.list(cards)do
		if q(acard,"getSuit") == sgs.Card_Spade then
			local c 
			if q(self.player,"getMark","heg_guishu-Clear") == 1 then
				c = parse_source("EXCard_YJJG:heg_guishu[no_suit:0]="..q(acard,"getEffectiveId"))
			elseif q(self.player,"getMark","heg_guishu-Clear") == 2 then
				c = parse_source("EXCard_ZJZB:heg_guishu[no_suit:0]="..q(acard,"getEffectiveId"))
			else
				c = parse_source("EXCard_YJJG:heg_guishu[no_suit:0]="..q(acard,"getEffectiveId"))
			end
			if c and q(c,"isAvailable",self.player) then return c end
		end
	end
end

sgs.ai_view_as.heg_guishu = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand and suit == "spade" then
		if q(player,"getMark","heg_guishu-Clear") == 1 then
			return ("EXCard_YJJG:heg_guishu[%s:%s]=%d"):format(suit,number,card_id)
		elseif q(player,"getMark","heg_guishu") == 2 then
			return ("EXCard_ZJZB:heg_guishu[%s:%s]=%d"):format(suit,number,card_id)
		else
			return ("EXCard_YJJG:heg_guishu[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end
sgs.ai_card_priority.heg_guishu = function(self,card)
	if table.contains(q(card,"getSkillNames"), "heg_guishu") and q(card,"isKindOf","EXCard_ZJZB")
	then return 5 end
end

sgs.ai_ajustdamage_to.heg_yuanyu   = function(self, from, to, card, nature)
	if from and not (q(from,"inMyAttackRange",to))  then
		return -1
	end
end

sgs.ai_skill_playerschosen.heg_zhuihuan = function(self, targets, max, min)
	local selected = AIList.new{}
    local can_choose = AIList.new(targets)
    sort_players(self,can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if q(self,"isFriend",target) and q(selected,"length") < max then
            call(selected,"append",target)
        end
    end
    return selected
end

sgs.ai_playerschosen_intention.heg_zhuihuan = function(self, from, prompt)
    local intention = -60
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_skill_invoke.heg_qiao = function(self,data)
	local target = q(data,"toPlayer")
	if q(self,"isEnemy",target) then
		return q(self,"doDisCard",target, "he")
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_qiao = function(self,player,promptlist)
	if promptlist[3]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,40) end
	end
end

sgs.ai_skill_playerchosen.heg_chengshang = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard")
	for _,p in sgs.list(targets)do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he", true) and q(p,"getHandcardNum") < 4 then
			return p
		end
	end
	return nil
end

sgs.ai_skill_cardask["heg_chengshang"] = function(self, data)
	local use = q(data,"toCardUse")
	local target = use.from
	if q(self,"isEnemy",target) then
		local cards = q(self.player,"getCards","he")
		cards = AIList.new(cards)
		sort_use(self,cards, true)
		for _,card in ipairs(cards) do
			if q(card,"getSuit") == q(use.card,"getSuit") or q(card,"getNumber") == q(use.card,"getNumber") then
				return "$"..q(card,"getEffectiveId")
			end
		end
	end
	return true
end

sgs.ai_playerchosen_intention.heg_chengshang = 40

sgs.ai_skill_invoke.heg_guowu = sgs.ai_skill_invoke.guowu

sgs.ai_skill_playerschosen.heg_guowu = function(self, targets, max, min)
	local use = room_tag("heg_guowu"):toCardUse()
	local dummy_use = call(self,"aiUseCard",use.card, dummy(true, 2, use.to))
	local enemy = AIList.new{}
	if dummy_use.card and q(dummy_use.to,"length") > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if q(self,"isEnemy",p) and q(targets,"contains",p) then
				call(enemy,"append",p)
				if q(enemy,"length") >= max then
					break
				end
			end
		end
	end
	return enemy
end

sgs.ai_fill_skill.heg_zhuangrong = function(self,inclusive,request)
	local use_card
    local cards = q(self.player,"getCards","h")
    cards = sort_use(self,cards,true) 
	for i,h in sgs.list(cards)do
		if q(h,"isKindOf","TrickCard") then
			use_card = h
			break
		end
	end
	if use_card then
		return parse_source("#heg_zhuangrong:"..q(use_card,"getEffectiveId")..":")
	end
end

sgs.ai_skill_use_func["#heg_zhuangrong"] = function(card,use,self,request)
	if q(self,"getCardsNum","Slash") > 0 and not q(self.player,"hasSkill","wushuang") then
		for _, c in sgs.qlist(q(self.player,"getHandcards")) do
			if source_helper("isCard","Slash", c, self.player) then
				local dummy_use = call(self,"aiUseCard",c, dummy())
				if dummy_use.card and q(dummy_use.to,"length") > 0 then
					use.card = card
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["heg_zhuangrong"] = 5

sgs.ai_skill_invoke.heg_duannian = function(self, data)
	if q(self.player,"getHandcardNum") > q(self.player,"getMaxHp") and q(self.player,"getMaxCards") > q(self.player,"getMaxHp") then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.heg_lianyou = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in sgs.list(targets)do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return nil
end

sgs.ai_ajustdamage_from.heg_xinghuo = function(self, from, to, card, nature)
	if nature == "F" then
		return 1
	end
end

sgs.ai_skill_invoke.heg_gongxiu = function(self, data)
	if sgs.ai_skill_playerschosen.heg_gongxiu(self, q(self.room,"getAlivePlayers"), q(self.player,"getMaxHp")):length() > 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerschosen.heg_gongxiu = function(self, targets, max, min)
	local selected = AIList.new{}
	local can_choose = AIList.new(targets)
	sort_players(self,can_choose, "defense")
	local choicelist = {}
	if q(self.player,"getMark","heg_gongxiu_draw") == 0 then
		table.insert(choicelist, "draw")
	end
	if q(self.player,"getMark","heg_gongxiu_discard") == 0 then
		table.insert(choicelist, "discard")
	end
	local choice
	if self.heg_gongxiu then
		choice = self.heg_gongxiu
		self.heg_gongxiu = nil
	else
		choice = choicelist[math.random(1, #choicelist)]
		self.heg_gongxiu = choice
	end
	if choice == "draw" then
		for _,target in ipairs(can_choose) do
			if q(self,"isFriend",target) and q(selected,"length") < max and q(self,"canDraw",target) then
				call(selected,"append",target)
			end
		end
	elseif choice == "discard" then
		for _,target in ipairs(can_choose) do
			if q(self,"isEnemy",target) and q(selected,"length") < max and q(self,"doDisCard",target, "he") then
				call(selected,"append",target)
			end
		end
	end
	return selected
end

sgs.ai_skill_choice.heg_gongxiu = function(self, choices, data)
	if self.heg_gongxiu then
		return self.heg_gongxiu
	end
	local items = q(choices,"split","+")
	return items[1]
end

sgs.ai_playerschosen_intention.heg_gongxiu = function(self, from, prompt)
	local intention = 0
	local tolist = q(prompt,"split","+")
	local choice = ""
	if q(from,"getMark","heg_gongxiu_draw") == 0 then
		choice = "draw"
	else
		choice = "discard"
	end
	if choice == "draw" then
		intention = -30
	else
		intention = 30
	end
	for _, dest in ipairs(tolist) do
		local to = call(self.room,"findPlayerByObjectName",dest)
		call(self,"updateIntention",from, to, intention)
	end
end

sgs.ai_fill_skill.heg_jinghe = function(self,inclusive,request)
	if q(self.player,"hasUsed","#heg_jinghe") then
		return nil
	end
	return parse_source("#heg_jinghe:.:")
end

sgs.ai_skill_use_func["#heg_jinghe"] = function(card,use,self,request)
	use.card = card
	call(use.to,"append",self.player)
end

sgs.ai_use_priority["heg_jinghe"] = 10

sgs.ai_skill_invoke.heg_ol_liegong = function(self,data)
	local target = q(data,"toPlayer")
	return not q(self,"isFriend",target)
end
sgs.hit_skill = sgs.hit_skill .. "|heg_ol_liegong"

sgs.ai_canliegong_skill.heg_ol_liegong = function(self, from, to)
	return q(from,"getPhase") == sgs.Player_Play and (q(to,"getHandcardNum") >= q(from,"getHp") or q(to,"getHandcardNum") <= q(from,"getAttackRange"))
end

extra_alias{ id="ai_cardneed.heg_ol_liegong",registry="ai_cardneed",path={"heg_ol_liegong"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_skill_invoke["ChangeGeneral"] = function(self, data)
	call(self,"updatePlayers")
	if q(self.player,"hasSkill","bf_nos_diancai") then return true end
	if q(self.player,"hasSkill","bf_qice") then
		if #self.enemies > #self.friends then
			return true
		end
	end
	for _,p in sgs.qlist(q(self.room,"findPlayersBySkillName","bf_zhiman")) do
		if p then
			return false



		end
	end
	return true
end

local bf_qice_skill = {}
bf_qice_skill.name = "bf_qice"
table.insert(package_skills, bf_qice_skill)
bf_qice_skill.getTurnUseCard = function(self,inclusive,request)
	call(self,"setPriorityValue","bf_qice",1.5,"extra.bf_qice")
	if q(self.player,"hasUsed","#bf_qice") or q(self.player,"isKongcheng") then return end
	local cards = q(self.player,"getHandcards")
	local allcard = {}
	cards = AIList.new(cards)
	
	local function get_handcard_suit(cards)
		if #cards == 0 then return sgs.Card_NoSuit end
		if #cards == 1 then return cards[1]:getSuit() end
		local black = false
		if cards[1]:isBlack() then black = true end
		for _, c in ipairs(cards) do
			if black ~= q(c,"isBlack") then return sgs.Card_NoSuit end
		end
		return black and sgs.Card_NoSuitBlack or sgs.Card_NoSuitRed
	end
	
	local suit = get_handcard_suit(cards)
	local aoename = "savage_assault|archery_attack"
	local aoenames = q(aoename,"split","|")
	local aoe
	local i

	local caocao = call(self.room,"findPlayerBySkillName","jianxiong")
	local qicetrick = "savage_assault|archery_attack|ex_nihilo|god_salvation"
	local qicetricks = q(qicetrick,"split","|")
	local aoe_available, ge_available, ex_available = true, true, true
	
	
	local target_count = 0
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		target_count = target_count + 1
	end
	for i = 1, #qicetricks do
		local qice_card_name = qicetricks[i]
		qice_card_name = clone_source(qice_card_name, suit)
		if q(qice_card_name,"isKindOf","AOE") and target_count - 1 > #cards then aoe_available = false end
		if q(qice_card_name,"isKindOf","GlobalEffect") and target_count > #cards then ge_available = false end
	end
	
	for i = 1, #qicetricks do
		local forbiden = qicetricks[i]
		forbid = clone_source(forbiden, suit)
		if q(self.player,"isCardLimited",forbid, sgs.Card_MethodUse, true) or not q(forbid,"isAvailable",self.player) then
			if q(forbid,"isKindOf","AOE") then aoe_available = false end
			if q(forbid,"isKindOf","GlobalEffect") then ge_available = false end
			if q(forbid,"isKindOf","ExNihilo") then ex_available = false end
		end
	end
	if q(self.player,"hasUsed","#bf_qice") then return end
















	for _, card in ipairs(cards) do
		if q(card,"hasFlag","xiahui") then return end
	end

	for _, card in ipairs(cards) do
		table.insert(allcard, q(card,"getEffectiveId"))
	end

	if #allcard > 1 then sgs.ai_use_priority["bf_qice"] = 0 end
	
	if #self.friends > #self.enemies and #self.friends + #self.enemies == q(self.room,"getAlivePlayers"):length() and q(self.player,"getHandcardNum") < 4 and q(self,"getCardsNum","Peach") == 0 and q(self.player,"getHp") >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if q(enemy,"getHp") <= 1 and q(enemy,"isKongcheng") then
				local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":duel")
				return parsed_card
			end
		end
	end
	
	local godsalvation = clone_source("god_salvation", suit, 0)
	
		if aoe_available then
			for i = 1, #aoenames do
				local newqice = aoenames[i]
				aoe = clone_source(newqice)
				if q(self,"getAoeValue",aoe) > 0 then
					local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. newqice)
					return parsed_card
				end
			end
		end
		if ge_available and q(self,"willUseGodSalvation",godsalvation) then
			local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "god_salvation")
			return parsed_card
		end
		if ex_available and q(self,"getCardsNum","Jink") == 0 and q(self,"getCardsNum","Peach") == 0 then
			local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "ex_nihilo")
			return parsed_card
		end
	

	if aoe_available then
		for i = 1, #aoenames do
			local newqice = aoenames[i]
			aoe = clone_source(newqice)
			if q(self,"getAoeValue",aoe) > -5 and caocao and q(self,"isFriend",caocao) and q(caocao,"getHp") > 1 and not q(self,"willSkipPlayPhase",caocao)
				and not q(self.player,"hasSkill","jueqing") and q(self,"aoeIsEffective",aoe, caocao, self.player) then
				local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. newqice)
				return parsed_card
			end
		end
	end
	if q(self,"getCardsNum","Jink") == 0 and q(self,"getCardsNum","Peach") == 0 and q(self,"getCardsNum","Analeptic") == 0
		and q(self,"getCardsNum","Nullification") == 0 and q(self.player,"getHandcardNum") <= 3 then
		if ge_available and q(self,"willUseGodSalvation",godsalvation) and q(self.player,"isWounded") then
			local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "god_salvation")
			return parsed_card
		end
		if ex_available then
			local parsed_card = parse_source("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "ex_nihilo")
			return parsed_card
		end
	end
end

sgs.ai_skill_use_func["#bf_qice"] = function(card,use,self,request)
	local userstring = q(card,"getLegacyStringKey")
	userstring = (q(userstring,"split",":"))[4]
	local qicecard = clone_source(userstring, q(card,"getSuit"), q(card,"getNumber"))
	call(qicecard,"setSkillName","bf_qice")
	call(self,"useTrickCard",qicecard, use)
	if use.card then
		for _, acard in sgs.qlist(q(self.player,"getHandcards")) do
			if source_helper("isCard","Peach", acard, self.player) and q(self.player,"getHandcardNum") > 1 and q(self.player,"isWounded")
				and not q(self,"needToLoseHp",self.player) then
					use.card = acard
					return
			end
		end
		use.card = card
	end
end


sgs.ai_skill_discard["bf_wanwei"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,usable_cards)
	local to_discard = {}
	local count = 0
	for _,c in ipairs(usable_cards) do
		if count < discard_num then
			count = count + 1
			table.insert(to_discard, q(c,"getEffectiveId"))
		end
	end
	return to_discard
end
sgs.ai_skill_invoke.bf_yuejian = function(self, data)
	local target = call(self.room,"getCurrent")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_yuejian = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrent")
		if target then call(self,"updateIntention",player,target,-50) end
	end
end


sgs.ai_skill_invoke["bf_zhiman"] = sgs.ai_skill_invoke["yishihz"]

extra_alias{ id="ai_choicemade_filter.cardChosen.bf_zhiman",registry="ai_choicemade_filter",path={"cardChosen","bf_zhiman"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.lose_equip_skill = sgs.lose_equip_skill .. "|bf_xuanlve"
extra_alias{ id="ai_cardneed.bf_xuanlve",registry="ai_cardneed",path={"bf_xuanlve"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.ai_skill_playerchosen["bf_xuanlve"] = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return nil
end

extra_alias{ id="ai_choicemade_filter.cardChosen.bf_xuanlve",registry="ai_choicemade_filter",path={"cardChosen","bf_xuanlve"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
local bf_yongjin_skill = {}
bf_yongjin_skill.name = "bf_yongjin"
table.insert(package_skills, bf_yongjin_skill)
bf_yongjin_skill.getTurnUseCard = function(self,inclusive,request)
	local equip_num = 0
	if q(self.player,"getMark","@bf_yongjin") > 0 then
		for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(self,"isEnemy",p) then
				equip_num = equip_num + q(p,"getEquips"):length()
			end
		end
	end
	if equip_num > 2 then
		return parse_source("#bf_yongjin:.:")
	end
end

sgs.ai_skill_use_func["#bf_yongjin"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority["bf_yongjin"] = 7
sgs.ai_use_value["bf_yongjin"] = 7

sgs.ai_skill_askforag["bf_yongjin"] = function(self, card_ids)
	for i = 1, #card_ids, 1 do
		local equip_card_owner = call(self.room,"getCardOwner",card_ids[i])
		if q(self,"isEnemy",equip_card_owner) then
			return card_ids[i]
		end
	end
	return -1
end

source_use_registry["@@bf_yongjin!"] = function(self, prompt, method)
	local equip_cards = AIList.new(q(self.player,"getCards","h"))
	call(self,"updatePlayers")
	sort_players(self,self.friends, "defense")
	for _, e in ipairs(equip_cards) do
		if q(e,"hasFlag","bf_yongjin") then
			local equip_index = q(e,"getRealCard"):toEquipCard():location()
			for _, friend in ipairs(self.friends) do
				if call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
					return string.format("#bf_yongjin:%d:->%s", q(e,"getEffectiveId"), q(friend,"objectName"))
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.bf_tiaodu = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"canDraw",target, self.player) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_tiaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end
sgs.ai_skill_playerchosen["bf_tiaodu"] = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in ipairs(targets) do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["bf_tiaodu"] = -50


local bf_nos_tiaodu_skill = {}
bf_nos_tiaodu_skill.name = "bf_nos_tiaodu"
table.insert(package_skills, bf_nos_tiaodu_skill)
bf_nos_tiaodu_skill.getTurnUseCard = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#bf_nos_tiaodu") then
		return parse_source("#bf_nos_tiaodu:.:")
	end
end

sgs.ai_skill_use_func["#bf_nos_tiaodu"] = function(card,use,self,request)
	local targets = {}
	call(self,"updatePlayers")
	sort_players(self,self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend)
	end
	use.card = card
	if use.to then
		for i = 1, #targets, 1 do
			call(use.to,"append",targets[i])
		end
	end
end

sgs.ai_use_priority["bf_nos_tiaodu"] = 3
sgs.ai_use_value["bf_nos_tiaodu"] = 3
sgs.ai_card_intention["bf_nos_tiaodu"] = -50

sgs.ai_skill_cardask["@bf_nos_tiaodu"] = function(self, data, pattern, target, target2)
	local handcards = q(self.player,"getCards","h")
	local equip_cards = q(self.player,"getCards","e")
	
	if q(self.player,"hasArmorEffect","silver_lion") and q(self.player,"isWounded") then
		for _, c in sgs.qlist(equip_cards) do
			if q(c,"isKindOf","SilverLion") then
				return q(c,"getLegacyStringKey")
			end
		end
	end
	
	if q(self.player,"hasSkill","bf_nos_tiaodu") and call(self.room,"getCurrent"):objectName() == q(self.player,"objectName") then
		for _,c in sgs.qlist(handcards) do
			if call(self.player,"getArmor") and q(c,"isKindOf","Armor") then
				return call(self.player,"getArmor"):toString()
			elseif call(self.player,"getDefensiveHorse") and q(c,"isKindOf","DefensiveHorse") then
				return call(self.player,"getDefensiveHorse"):toString()
			elseif call(self.player,"getWeapon") and q(c,"isKindOf","Weapon") then
				return call(self.player,"getWeapon"):toString()
			elseif call(self.player,"getOffensiveHorse") and q(c,"isKindOf","OffensiveHorse") then
				return call(self.player,"getOffensiveHorse"):toString()
			end
		end
	else
		for _,c in sgs.qlist(handcards) do
			if not call(self.player,"getArmor") and q(c,"isKindOf","Armor") then
				local dummyuse = { isDummy = true }
				q(self,"useEquipCard",c, dummyuse)
				if dummyuse.card then
					return q(c,"getLegacyStringKey")
				end
			elseif not call(self.player,"getDefensiveHorse") and q(c,"isKindOf","DefensiveHorse") then
				return q(c,"getLegacyStringKey")
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen["bf_nos_tiaodu"] = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in ipairs(targets) do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["bf_nos_tiaodu"] = -50

sgs.ai_skill_invoke.bf_sec_tiaodu = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"canDraw",target, self.player) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_sec_tiaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end
extra_alias{ id="ai_skill_playerchosen.bf_sec_tiaodu",registry="ai_skill_playerchosen",path={"bf_sec_tiaodu"},canonical_registry="ai_skill_playerchosen",canonical_path={"bf_tiaodu"},self_index=1,defer_canonical=true}
sgs.ai_playerchosen_intention["bf_sec_tiaodu"] = sgs.ai_playerchosen_intention["bf_tiaodu"]

sgs.ai_skill_invoke.bf_third_tiaodu = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"canDraw",target, self.player) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_third_tiaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

extra_alias{ id="ai_skill_playerchosen.bf_third_tiaodu",registry="ai_skill_playerchosen",path={"bf_third_tiaodu"},canonical_registry="ai_skill_playerchosen",canonical_path={"bf_tiaodu"},self_index=1,defer_canonical=true}
sgs.ai_playerchosen_intention["bf_third_tiaodu"] = sgs.ai_playerchosen_intention["bf_tiaodu"]



local bf_xiongsuan_skill = {}
bf_xiongsuan_skill.name = "bf_xiongsuan"
table.insert(package_skills, bf_xiongsuan_skill)
bf_xiongsuan_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"getMark","@scary") > 0 and q(self.player,"getHandcardNum") < 3 then
		return parse_source("#bf_xiongsuan:.:")
	end
end

sgs.ai_skill_use_func["#bf_xiongsuan"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "handcard")
	local usable_cards = AIList.new(q(self.player,"getCards","h"))
	local use_card = {}
	local target = {}
	sort_use(self,usable_cards, true)
	for _,c in ipairs(usable_cards) do
		if not q(c,"isKindOf","Peach") then
			table.insert(use_card, c)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local has_limit_skill = false
		for _,skill in sgs.qlist(q(enemy,"getVisibleSkillList")) do
			if not q(skill,"inherits","SPConvertSkill") and not q(skill,"isAttachedLordSkill") and q(skill,"getFrequency") == sgs.Skill_Limited then
				has_limit_skill = true
			end
		end
		if not has_limit_skill and q(enemy,"getHp") <= 2 then
			table.insert(target, enemy)
		end
	end
	if #use_card == 0 or #target == 0 then return end
	local card_str = string.format("#bf_xiongsuan:%s:", use_card[1]:getEffectiveId())
	local acard = parse_source(card_str)
	use.card = acard
	if use.to then call(use.to,"append",target[1]) end
end

sgs.ai_skill_choice["bf_xiongsuan"] = function(self, choices, data)
	local skill_items = q(choices,"split","+")
	if #skill_items == 1 then
		return skill_items[1]
	else
		return skill_items[math.random(1,#skill_items)]
	end
end

sgs.ai_use_priority["bf_xiongsuan"] = 3
sgs.ai_use_value["bf_xiongsuan"] = 3

sgs.ai_skill_choice.bf_nos_huashen = sgs.ai_skill_choice.huashen







sgs.need_kongcheng = sgs.need_kongcheng .. "|twyj_baimei"

sgs.ai_ajustdamage_to.twyj_baimei = function(self, from, to, card, nature)
	if q(to,"isKongcheng") and (nature ~= "N" or (card and q(card,"isKindOf","TrickCard"))) then
		return -99
	end
end



local twyj_rangyi_skill = {}
twyj_rangyi_skill.name = "twyj_rangyi"
table.insert(package_skills, twyj_rangyi_skill)
twyj_rangyi_skill.getTurnUseCard = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#twyj_rangyi") and not q(self.player,"isKongcheng") then
		return parse_source("#twyj_rangyi:.:")
	end
end

sgs.ai_skill_use_func["#twyj_rangyi"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "hp")
	sort_players(self,self.enemies, "hp")
	local handcards = AIList.new(q(self.player,"getCards","h"))
	if call(self.player,"getWeapon") then
		for _,c in ipairs(handcards) do
			if q(c,"isKindOf","Weapon") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = q(c,"getRealCard"):toEquipCard():location()
					if call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
						use.card = card
						if use.to then call(use.to,"append",friend) end
						return
					end
				end
			end
		end
	end
	if call(self.player,"getArmor") then
		for _,c in ipairs(handcards) do
			if q(c,"isKindOf","Armor") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = q(c,"getRealCard"):toEquipCard():location()
					if call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
						use.card = card
						if use.to then call(use.to,"append",friend) end
						return
					end
				end
			end
		end
	end
	if call(self.player,"getDefensiveHorse") then
		for _,c in ipairs(handcards) do
			if q(c,"isKindOf","DefensiveHorse") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = q(c,"getRealCard"):toEquipCard():location()
					if call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
						use.card = card
						if use.to then call(use.to,"append",friend) end
						return
					end
				end
			end
		end
	end
	if call(self.player,"getOffensiveHorse") then
		for _,c in ipairs(handcards) do
			if q(c,"isKindOf","OffensiveHorse") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = q(c,"getRealCard"):toEquipCard():location()
					if call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
						use.card = card
						if use.to then call(use.to,"append",friend) end
						return
					end
				end
			end
		end
	end
	if q(self.player,"getHp") >= 2 and q(self,"getCardsNum","Peach") > 0 then
		for _, friend in ipairs(self.friends_noself) do
			if q(friend,"getHp") <= 2 and q(friend,"isWounded") then
				use.card = card
				if use.to then call(use.to,"append",friend) end
				return
			end
		end
	end
	if not q(self,"slashIsAvailable") and q(self,"getCardsNum","Slash") > 0 then
		for _, friend in ipairs(self.friends_noself) do
			for _, enemy in ipairs(self.enemies) do
				for _, slash in ipairs(q(self,"getCards","Slash")) do
					if q(friend,"canSlash",enemy, slash, false) and not q(self,"slashProhibit",slash, enemy) and q(friend,"inMyAttackRange",enemy)
					and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) then
						use.card = card
						if use.to then call(use.to,"append",friend) end
						return
					end
				end
			end
		end
	end
	if q(self,"getCardsNum","Jink") == #handcards and #handcards <= 2 then
		for _, enemy in ipairs(self.enemies) do
			if q(enemy,"getHp") <= 1 then
				use.card = card
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end

sgs.ai_use_priority["twyj_rangyi"] = 0
sgs.ai_use_value["twyj_rangyi"] = 0

source_use_registry["@@twyj_rangyi"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "hp")
	sort_players(self,self.enemies, "hp")
	local current = call(self.room,"getCurrent")
	local handcards = AIList.new(q(self.player,"getCards","h"))
	local useable_cards = {}
	for _,c in ipairs(handcards) do
		if q(c,"hasFlag","twyj_rangyi") and q(c,"isAvailable",self.player) then
			table.insert(useable_cards, c)
		end
	end
	sort_use(self,useable_cards, false)
	if #useable_cards > 0 then
		
		local use_card = useable_cards[1]
		if current and q(self,"isFriend",current) and useable_cards[1]:isKindOf("Analeptic") then
			for _,c in ipairs(handcards) do
				if q(c,"hasFlag","twyj_rangyi") and q(c,"isAvailable",self.player) and not q(c,"isKindOf","Analeptic") then
					use_card = c
				end
			end
		end
		
		local skillcard = call(self,"prepareRangyiResponse",use_card)
		if q(use_card,"targetFixed") then
			return call(self,"selectRangyiResponse",skillcard,{})
		else
			if q(use_card,"isKindOf","Slash") then
				local dummyuse = { isDummy = true, to = AIList.new{} }
				call(self,"useBasicCard",use_card, dummyuse)
				local targets = {}
				if not q(dummyuse.to,"isEmpty") then
					for _, p in sgs.qlist(dummyuse.to) do
						table.insert(targets, q(p,"objectName"))
					end
					if #targets > 0 then
						return call(self,"selectRangyiResponse",skillcard,targets)
					end
				end
			end
			local dummyuse = { isDummy = true, to = AIList.new{} }
			call(self,"useTrickCard",use_card, dummyuse)
			local targets = {}
			if not q(dummyuse.to,"isEmpty") then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, q(p,"objectName"))
				end
				if #targets > 0 then
					return call(self,"selectRangyiResponse",skillcard,targets)
				end
			end
		end
	end
	return "."
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|twyj_qijia"
sgs.need_equip_skill = sgs.need_equip_skill .. "|twyj_qijia"
extra_alias{ id="ai_cardneed.twyj_qijia",registry="ai_cardneed",path={"twyj_qijia"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
local twyj_qijia_skill = {}
twyj_qijia_skill.name = "twyj_qijia"
table.insert(package_skills, twyj_qijia_skill)
twyj_qijia_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"getEquips"):length() > 0 and q(self.player,"canDiscard",self.player, "e") then
		return parse_source("#twyj_qijia:.:")
	end
end

sgs.ai_skill_use_func["#twyj_qijia"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "hp")
	local equipments = AIList.new(q(self.player,"getCards","e"))
	local targets = {}
	local use_cards = {}
	for _,e in ipairs(equipments) do
		local equip_index = q(e,"getRealCard"):toEquipCard():location()
		if q(self.player,"getMark","twyj_qijia_"..equip_index.."-Clear") == 0 and not (q(e,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
			table.insert(use_cards, e)
		end
	end
	sort_keep(self,use_cards)
	local rangefix = 0
	if #use_cards > 0 then
		if use_cards[1]:isKindOf("Weapon") then
			local card = use_cards[1]:getRealCard():toWeapon()
			rangefix = rangefix + q(card,"getRange") - q(self.player,"getAttackRange",false)
		end
		if use_cards[1]:isKindOf("OffensiveHorse") then
			rangefix = rangefix + 1
		end
	end
	local slash = clone_source("slash", sgs.Card_NoSuit, -1)
	call(slash,"deleteLater")
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"inMyAttackRange",enemy) and q(self.player,"canSlash",enemy, slash, false)
		and q(self.player,"canSlash",enemy, true, rangefix) and not q(self,"slashProhibit",slash, enemy)
		
		
		then
			table.insert(targets, enemy)
		end
	end
	if call(self.player,"getArmor") and q(self.player,"hasArmorEffect","silver_lion") and q(self.player,"isWounded") then
		local equip_index = call(self.player,"getArmor"):getRealCard():toEquipCard():location()
		for _, enemy in ipairs(self.enemies) do
			if q(self.player,"inMyAttackRange",enemy) and q(self.player,"canSlash",enemy, slash, false)
			and not q(self,"slashProhibit",slash, enemy) and q(self.player,"getMark","twyj_qijia_"..equip_index.."-Clear") == 0
			then
				local card_str = string.format("#twyj_qijia:%s:", call(self.player,"getArmor"):getEffectiveId())
				local acard = parse_source(card_str)
				use.card = acard
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	if #targets == 0 or #use_cards == 0 then return end
	local card_str = string.format("#twyj_qijia:%s:", use_cards[1]:getEffectiveId())
	local acard = parse_source(card_str)
	use.card = acard
	if use.to then call(use.to,"append",targets[1]) end
end

sgs.ai_use_priority["twyj_qijia"] = 0
sgs.ai_use_value["twyj_qijia"] = 0
sgs.ai_card_intention["twyj_qijia"] = 80

local twyj_zhuchen_skill = {}
twyj_zhuchen_skill.name = "twyj_zhuchen"
table.insert(package_skills, twyj_zhuchen_skill)
twyj_zhuchen_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 then
		return parse_source("#twyj_zhuchen:.:")
	end
end

sgs.ai_skill_use_func["#twyj_zhuchen"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "hp")
	local targets = {}
	local handcards = AIList.new(q(self.player,"getCards","h"))
	local use_cards = {}
	local slash = clone_source("slash", sgs.Card_NoSuit, -1)
	call(slash,"deleteLater")
	for _, enemy in ipairs(self.enemies) do
		if not q(self.player,"inMyAttackRange",enemy) and q(self.player,"canSlash",enemy, slash, false)
		and not q(self,"slashProhibit",slash, enemy) and not call(enemy,"getArmor")
		and q(enemy,"getHp") <= 2 and q(enemy,"getHandcardNum") == 0
		then
			table.insert(targets, enemy)
		end
	end
	for _,c in ipairs(handcards) do
		if q(c,"isKindOf","Analeptic") then
			table.insert(use_cards, c)
		end
	end
	if #targets == 0 or #use_cards == 0 or q(self.player,"getEquips"):length() < 2 or q(self,"getCardsNum","Analeptic") < 2 then return end
	local card_str = string.format("#twyj_zhuchen:%s:", use_cards[1]:getEffectiveId())
	local acard = parse_source(card_str)
	use.card = acard
	if use.to then call(use.to,"append",targets[1]) end
end

sgs.ai_use_priority["twyj_zhuchen"] = 0
sgs.ai_use_value["twyj_zhuchen"] = 0
sgs.ai_card_intention["twyj_zhuchen"] = 80

sgs.need_equip_skill = sgs.need_equip_skill .. "|twyj_huzhu"
extra_alias{ id="ai_cardneed.twyj_huzhu",registry="ai_cardneed",path={"twyj_huzhu"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
local twyj_huzhu_skill = {}
twyj_huzhu_skill.name = "twyj_huzhu"
table.insert(package_skills, twyj_huzhu_skill)
twyj_huzhu_skill.getTurnUseCard = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#twyj_huzhu") and not q(self.player,"getEquips"):isEmpty() then
		return parse_source("#twyj_huzhu:.:")
	end
end

sgs.ai_skill_use_func["#twyj_huzhu"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "hp")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if q(friend,"getHp") <= q(self.player,"getHp") and q(friend,"getHp") < 3 and q(friend,"getHandcardNum") > 1 and q(friend,"isWounded") then
			table.insert(targets, friend)
		end
	end
	if #targets == 0 then return end
	use.card = card
	if use.to then call(use.to,"append",targets[1]) end
end

sgs.ai_use_priority["twyj_huzhu"] = 3
sgs.ai_use_value["twyj_huzhu"] = 3

sgs.ai_card_intention["twyj_huzhu"] = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if q(to,"getHp") > q(from,"getHp") or not q(to,"isWounded") then
			call(self,"updateIntention",from, to, 20)
		end
	end
end

sgs.ai_skill_invoke["twyj_huzhu"] = function(self, data)
	local player = q(data,"toPlayer")
	return player and q(self,"isFriend",player)
end

sgs.ai_choicemade_filter.skillInvoke.twyj_huzhu = function(self, player, promptlist)
	local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist - 1])
	if target then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",player, target, -80)
		else
			call(self,"updateIntention",player, target, 80)
		end
	end
end

sgs.ai_skill_cardask["@twyj_huzhu"] = function(self, data, pattern, target, target2)
	local handcards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,handcards)
	for _,c in ipairs(handcards) do
		return q(c,"getLegacyStringKey")
	end
end

sgs.ai_skill_invoke["twyj_liancai"] = function(self, data)
	local has_enemy_equips = false
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self,"isEnemy",p) and q(p,"getEquips"):length() > 0 then
			has_enemy_equips = true
		end
	end
	
	local has_equip_enemy = 0
	local only_one_silver = false
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self,"isEnemy",p) and q(p,"getEquips"):length() > 0 then
			has_equip_enemy = has_equip_enemy + 1
		end
		if q(p,"getEquips"):length() == 1 and q(p,"hasArmorEffect","silver_lion") and q(p,"isWounded") then
			only_one_silver = true
		end
	end
	if has_equip_enemy == 1 and only_one_silver then return false end
	
	if q(self.player,"getHp") - q(self.player,"getHandcardNum") > 0 and has_enemy_equips then
		return true
	end
	return false
end

sgs.ai_skill_askforag["twyj_liancai"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		local equip_card_owner = call(self.room,"getCardOwner",card_id)
		if q(self,"isFriend",equip_card_owner) and disclosed(card_id):isKindOf("SilverLion") and q(equip_card_owner,"isWounded") and not table.contains(cards, disclosed(card_id)) then
			table.insert(cards, disclosed(card_id))
		elseif q(self,"isEnemy",equip_card_owner) then
			if not (disclosed(card_id):isKindOf("SilverLion") and q(equip_card_owner,"isWounded")) and not table.contains(cards, disclosed(card_id)) then
				table.insert(cards, disclosed(card_id))
			end
		end
	end
	sort_use(self,cards, true)
	if #cards > 0 then
		return cards[1]:getEffectiveId()
	end
end

sgs.ai_skill_invoke["twyj_liancai_turnover"] = true

sgs.ai_skill_discard["command"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,usable_cards)
	local to_discard = {}
	for _,c in ipairs(usable_cards) do
		if #to_discard < discard_num then
			table.insert(to_discard, q(c,"getEffectiveId"))
		end
	end
	return to_discard
end

sgs.ai_skill_choice.do_command = function(self, choices, data)
	local from = q(data,"toPlayer")
	local items = q(choices,"split","+")
	if table.contains(items, "command1") and math.random() < 0.5 then
		if q(self,"isFriend",from) then
			return "command1"
		end
		if self.friends_noself and #self.friends_noself > 0 and q(self,"getAllPeachNum") <= 0 then
			return "cancel"
		end
		return "command1"
	end
	if table.contains(items, "command2") then
		if q(self,"doDisCard",self.player, "he", true) then
			return "command2"
		end
		if q(self,"isFriend",from) then
			return "command2"
		end
	end
	if table.contains(items, "command3") then
		if source_helper("hasZhaxiangEffect",self.player) and q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 then
			return "command3"
		end
		if math.random() < 0.5 and q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 then
			return "command3"
		end
	end
	if table.contains(items, "command4") then
		if math.random() < 0.5 then
			return "command4"
		end
	end
	if table.contains(items, "command5") then
		if not q(self,"isWeak") and q(self.player,"faceUp") then
			return "command5"
		end
	end
	if table.contains(items, "command6") then
		local hand_discard = q(self.player,"getHandcardNum") - 1
		local equip_discard = q(self.player,"getEquips"):length() - 1
		if hand_discard + equip_discard <= 2 then
			return "command6"
		end
	end
	return "cancel"
end

extra_alias{ id="ai_skill_playerchosen.command1",registry="ai_skill_playerchosen",path={"command1"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"},self_index=1,defer_canonical=true}
source_use_registry["@@command6!"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local ids = {}
	local hand_discard = q(self.player,"getHandcardNum") - 1
	local equip_discard = q(self.player,"getEquips"):length() - 1
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
	for _,c in ipairs(cards) do
		if q(c,"isEquipped") then
			if equip_discard > 0 then
				equip_discard = equip_discard - 1
				table.insert(ids, q(c,"getEffectiveId"))
			end
		else
			if hand_discard > 0 then
				hand_discard = hand_discard - 1
				table.insert(ids, q(c,"getEffectiveId"))
			end
		end
	end
	if #ids == 0 then return "." end
	return q(DummyCard,"clone"):objectName() .. ":"..table.concat(ids,"+") ..":"
end

sgs.ai_skill_cardask["@heg_jieyue-give"] = function(self, data, pattern, target, target2)
	if sgs.ai_skill_playerchosen.heg_jieyue(self, q(self.room,"getOtherPlayers",self.player)) ~= nil then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_jieyue = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["heg_jieyue"] = 40

sgs.ai_fill_skill.heg_fengying = function(self,inclusive,request)
	if #self.toUse > 1 then return nil end
	local dc = clone_source("heg_threaten_emperor", sgs.Card_NoSuit, 0)
	call(dc,"setSkillName","heg_fengying")
	call(dc,"deleteLater")
	call(dc,"addSubcards",q(self.player,"handCards"))
	return dc
end

sgs.ai_skill_playerschosen.heg_fengying = function(self, targets, max, min)
	local selected = AIList.new{}
    local can_choose = AIList.new(targets)
    sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if q(self,"isFriend",target) and q(self,"canDraw",target) then
			call(selected,"append",target)
			if q(selected,"length") >= max then break end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_fengying = function(self, from, prompt)
    local intention = -60
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_skill_invoke.heg_zhengbi = true

sgs.ai_skill_choice.heg_zhengbi = function(self, choices, data)
	local items = q(choices,"split","+")
	if table.contains(items, "heg_zhengbi_give") and source_use_registry["@@heg_zhengbi"](self, "") ~=  "." then
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"canDraw",friend, self.player) and q(self,"doDisCard",friend, "he", true) then
				return "heg_zhengbi_give"
			end
		end
		if math.random() < 0.5 then
			for _, enemy in ipairs(self.enemies) do
				if q(self,"doDisCard",enemy, "he", true) and q(enemy,"getCardCount",true) > 1 then
					return "heg_zhengbi_give"
				end
			end
		end
	end
	return "heg_zhengbi_distance"
end

sgs.ai_skill_playerchosen.heg_zhengbi = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_use(self,cards)
	for _, c in ipairs(cards) do
		if q(c,"isKindOf","Slash") then
			begin_range(self)
			local dummy_use = call(self,"aiUseCard",c,dummy())
			end_range(self)
			if dummy_use and dummy_use.to and dummy_use.card then
				for _, p in sgs.qlist(dummy_use.to) do
					return p
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.heg_zhengbi = 40

source_use_registry["@@zhengbidiscard!"] = function(self, prompt, method)
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local basic = {}
	local nonbasic = {}
	local discard = {}
	for _,card in ipairs(cards)do
		if q(card,"isKindOf","BasicCard") then
			table.insert(basic,card)
		else
			table.insert(nonbasic,card)
		end
	end
	if #cards<=2 then return "." end
	if q(self,"needToThrowArmor") and #basic>=2 then
		table.insert(discard,call(self.player,"getArmor"))
		if basic[1]~=discard[1] then
			table.insert(discard,basic[1]:getEffectiveId())
		else
			table.insert(discard,basic[2]:getEffectiveId())
		end
	end
	if #nonbasic==0 then
		for _,card in ipairs(basic)do
			table.insert(discard,q(card,"getEffectiveId"))
			if #discard==2 or #discard==#basic then
				break
			end
		end
	end
	if #basic==0 and #nonbasic>=1 then
		table.insert(discard,nonbasic[1]:getEffectiveId())
	end
	if #discard>0 then
		return "$"..table.concat(discard,"+")
	end
	return "."
end

source_use_registry["@@heg_zhengbi"] = function(self, prompt, method)
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,cards)
	local use_card
    for _, acard in ipairs(cards) do
		if q(acard,"isKindOf","BasicCard") then
			use_card = acard
			break
		end
	end
	if use_card then
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"doDisCard",friend, "h", true) and q(friend,"getCardCount",true) > 1 and q(self,"canDraw",friend, self.player) then
				return "#heg_zhengbi:"..q(use_card,"getEffectiveId")..":->" .. q(friend,"objectName")
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if q(self,"doDisCard",enemy, "h", true) and q(enemy,"getCardCount",true) > 1 then
				return "#heg_zhengbi:"..q(use_card,"getEffectiveId")..":->" .. q(enemy,"objectName")
			end
		end
	end
	return "."
end

sgs.ai_fill_skill.heg_jianglue = function(self,inclusive,request)
	if (q(self.room,"getTurnCount")>1) or (q(self,"isWeak")) then
		return parse_source("#heg_jianglue:.:")
	end
end

sgs.ai_skill_use_func["#heg_jianglue"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority["heg_jianglue"] = 9.31

sgs.ai_skill_playerschosen.heg_jianglue = function(self, targets, max, min)
	local selected = AIList.new{}
    local can_choose = AIList.new(targets)
    sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if q(self,"isFriend",target) then
			call(selected,"append",target)
			if q(selected,"length") >= max then break end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_jianglue = function(self, from, prompt)
    local intention = -60
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_skill_choice.start_command_heg_jianglue = function(self, choices, data)
	local items = q(choices,"split","+")
	if table.contains(items, "command1") then
		return "command1"
	end
	if table.contains(items, "command2") then
		return "command2"
	end
	if table.contains(items, "command4") then
		return "command4"
	end
	return items[math.random(1,#items)]
end

sgs.ai_fill_skill.heg_xuanhuoAttach = function(self,inclusive,request)
	if q(self,"isWeak") or q(self.player,"isKongcheng") or q(self,"needBear") then return end
	return parse_source("#heg_xuanhuo:.:")
end

sgs.ai_skill_use_func["#heg_xuanhuo"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,cards)
	for _, friend in ipairs(self.friends_noself) do
		if q(friend,"hasSkill","heg_xuanhuo") and q(self,"canDraw",friend, self.player) and q(friend,"getMark","heg_xuanhuo"..q(self.player,"objectName").."-PlayClear") == 0 then
			use.card = parse_source("#heg_xuanhuo:"..cards[1]:getEffectiveId()..":")
			call(use.to,"append",friend)
			return
		end
	end
	
end

sgs.ai_use_value.heg_xuanhuo = 4.4
sgs.ai_use_priority.heg_xuanhuo = 5.2

sgs.ai_skill_discard.heg_enyuan = sgs.ai_skill_discard.enyuan

source_use_registry["@@heg_keshou"] = function(self,prompt,method)
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,cards)
	local damage = room_tag("heg_keshou"):toDamage()
	if q(self,"needToLoseHp",self.player,damage.from,damage.card) then
		return "."
	end
	local use_cards = {}
	for _,c in ipairs(cards)do
		if q(self,"getKeepValue",c) <= 6 then
			for _,c2 in ipairs(cards)do
				if c ~= c2 and q(c,"getColor") == q(c2,"getColor") then
					table.insert(use_cards,c2)
					table.insert(use_cards,c)
					break
				end
			end
			if #use_cards >= 2 then break end
		end
	end
	if #use_cards < 2 then return "." end
	local card_str = "#heg_keshou:"..use_cards[1]:getEffectiveId().."+"..use_cards[2]:getEffectiveId()..":"
	return card_str
end

sgs.ai_skill_invoke.heg_zhuwei = function(self, data)
	if q(data,"toCard") then
		return true
	end
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.heg_zhuwei = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-30) end
	end
end

sgs.ai_skill_invoke.heg_buyi = function(self, data)
	local target = q(data,"toDying").who
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_fill_skill.heg_weidi = function(self,inclusive,request)
	return parse_source("#heg_weidi:.:")
end

sgs.ai_skill_use_func["#heg_weidi"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isKongcheng") and q(self,"doDisCard",enemy, "h", true) and q(enemy,"getMark","heg_weidi-Clear") > 0 then
			use.card = card
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
end

sgs.ai_use_priority["heg_weidi"] = 5.2
sgs.ai_card_intention["heg_weidi"] = 80

sgs.ai_can_damagehp.heg_fudi = function(self,from,card,to)
	if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
	then
		local targets = AIList.new{}
		local max = 0
		for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(p,"getHp") > max then
				max = q(p,"getHp")
			end
		end
		for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(p,"getHp") == max and q(p,"getHp") >= q(to,"getHp") then
				call(targets,"append",p)
			end
		end
		if not q(targets,"isEmpty") then
			for _, p in sgs.qlist(targets) do
				if q(self,"isEnemy",p) and q(self,"canDamage",p, to, nil) then
					return q(self,"isFriend",from) and not q(to,"isKongcheng")
				end
			end
		end
	end
end

sgs.ai_skill_cardask["@heg_fudi-give"] = function(self, data, pattern, target, target2)
	local damage = q(data,"toDamage")
	local targets = AIList.new{}
	local max = 0
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") > max then
			max = q(p,"getHp")
		end
	end
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") == max and q(p,"getHp") >= q(self.player,"getHp") then
			call(targets,"append",p)
		end
	end
	if not q(targets,"isEmpty") then
		for _, p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) and q(self,"canDamage",p, self.player, nil) then
				return true
			end
		end
	end
	return "."
end

extra_alias{ id="ai_skill_playerchosen.heg_fudi",registry="ai_skill_playerchosen",path={"heg_fudi"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"},self_index=1,defer_canonical=true}
sgs.ai_skill_invoke.heg_liangfan = function(self, data)
	local target = q(data,"toPlayer")
	if target then
		return q(self,"doDisCard",target, "he", true)
	end
	return false
end

sgs.ai_ajustdamage_from.heg_congjian = function(self, from, to, card, nature)
	if from and q(from,"getPhase") == sgs.Player_NotActive then
		return 1
	end
end
sgs.ai_ajustdamage_to.heg_congjian = function(self, from, to, card, nature)
	if q(to,"getPhase") ~= sgs.Player_NotActive then
		return 1
	end
end

sgs.ai_skill_invoke.heg_qiuan = function(self, data)
	local damage = q(data,"toDamage")
	if q(self,"needToLoseHp",damage.to, damage.from, damage.card) then
		return false
	end
	return true
end

sgs.ai_skill_invoke.heg_liangfan = function(self, data)
	local target = q(data,"toDamage").to
	if target and q(self,"doDisCard",target,"he",true) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_wenji = function(self,targets)
	targets = AIList.new(targets)
	sort_players(self,targets,"handcard")
	
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(self,"doDisCard",p,"he",true) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(p,"hasSkills",sgs.lose_equip_skill) and (q(p,"getEquips"):length()>1 or q(p,"getPile","wooden_ox"):isEmpty()) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p,"he",true) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(self,"getOverflow",p)>0 then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.heg_wenji = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@heg_fengshih"] = function(self, data, pattern, target, target2)
	local use = q(data,"toCardUse")
	local target
	if q(use.from,"objectName") == q(self.player,"objectName") then
		target = q(use.to,"first")
	else
		target = use.from
	end
	if target then
		if q(self,"doDisCard",target, "he") then
			return true
		end
	end
end

sgs.ai_ajustdamage_from.heg_fengshih = function(self, from, to, card, nature)
	if card and q(card,"hasFlag","heg_fengshih") then
		return 1
	end
end
sgs.ai_ajustdamage_to.heg_fengshih = function(self, from, to, card, nature)
	if card and q(card,"hasFlag","heg_fengshih") then
		return 1
	end
end

sgs.ai_skill_playerchosen.heg_bushi = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	return call(self,"findPlayerToDraw",true, 1)
end

sgs.ai_playerchosen_intention.heg_bushi = -50

sgs.ai_skill_cardask["@heg_midao-give"] = function(self, data, pattern, target, target2)
	if target and q(self,"isFriend",target) and q(self,"canDraw",target, self.player) and q(self,"getOverflow") > 0 then
		return true
	end
end

sgs.ai_skill_choice.heg_lixia = function(self, choices, data)
	local draw = getChoice(choices, "draw")
	local discard = getChoice(choices, "discard")
	if discard then
		local target = q(data,"toPlayer")
		if q(self,"doDisCard",target, "e") and q(self,"isEnemy",target) and (q(self,"getAllPeachNum") + q(self.player,"getHp") - 1 > 0) and (source_helper("hasZhaxiangEffect",self.player) or math.random() < 0.5) then
			return discard
		end
	end
	return draw
end

sgs.ai_skill_invoke.heg_nos_lixia = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"canDraw",target, self.player) and q(self,"doDisCard",target, "e") then
		return true
	end
	if target and q(self,"isEnemy",target) and q(self,"doDisCard",target, "e") then
		if q(self,"getAllPeachNum") + q(self.player,"getHp") - 1 > 0 and (source_helper("hasZhaxiangEffect",self.player) or math.random() < 0.5) and not q(self,"isWeak") then
			return true
		end
		if q(self,"needToThrowCard",self.player,"h",true,false,false) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.heg_nos_lixia = function(self, choices, data)
	local draw = getChoice(choices, "draw")
	local items = q(choices,"split","+")
	local target = q(data,"toPlayer")
	if draw then
		if q(self,"isFriend",target) and q(self,"canDraw",target) then
			return draw
		end
	end
	if table.contains(items, "discard") then
		if q(self,"needToThrowCard",self.player,"h",true,false,false) then
			return "discard"
		end
	end
	if table.contains(items, "loseHp") then
		if q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 and (source_helper("hasZhaxiangEffect",self.player) or math.random() < 0.5) and not q(self,"isWeak") then
			return "loseHp"
		end
	end

	return draw
end

sgs.ai_fill_skill.heg_quanjin = function(self,inclusive,request)
	local cards = AIList.new(q(self.player,"getCards","h"))
    sort_use(self,cards, true)
    for _, card in ipairs(cards) do
        return parse_source("#heg_quanjin:" .. q(card,"getEffectiveId") .. ":")
    end
end

sgs.ai_skill_use_func["#heg_quanjin"] = function(card,use,self,request)
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"getMark","heg_quanjin-PlayClear") > 0 then
			use.card = card
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
end

sgs.ai_fill_skill.heg_zaoyun = function(self,inclusive,request)
	if q(self,"isWeak") or q(self.player,"isKongcheng") or q(self,"needBear") then return end
	return parse_source("#heg_zaoyun:.:")
end

sgs.ai_skill_use_func["#heg_zaoyun"] = function(card,use,self,request)
	sort_players(self,self.enemies, "hp")
	local targets = AIList.new{}
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"distanceTo",enemy) > 1 then
			call(targets,"append",enemy)
		end
	end
	if q(targets,"isEmpty") then return end
	local target = call(self,"findPlayerToDamage",1,self.player,sgs.DamageStruct_Normal,targets,3,nil)[1]
	if not target then return end
	local use_cards = {}
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
	for _,c in ipairs(cards)do
		if q(self,"getKeepValue",c) <= 6 then
			table.insert(use_cards,q(c,"getEffectiveId"))
			if #use_cards >= q(self.player,"distanceTo",target) - 1 then break end
		end
	end
	if #use_cards == q(self.player,"distanceTo",target) - 1 then
		use.card = parse_source("#heg_zaoyun:"..table.concat(use_cards, "+")..":")
		if use.to then call(use.to,"append",target) end
	end
end

sgs.ai_use_priority["heg_zaoyun"] = sgs.ai_use_priority.QiangxiCard

sgs.ai_skill_invoke.heg_qiance = function(self, data)
	local use = q(data,"toCardUse")
	local targets = AIList.new{}
	for _, p in sgs.qlist(use.to) do
		if source_global(self,"IsBigKingdomPlayer",p) then
			call(targets,"append",p)
		end
	end
	if not q(targets,"isEmpty") then
		for _, p in sgs.qlist(targets) do
			if q(self,"isFriend",p) then
				return false
			end
		end
		if use.card and q(use.card,"isDamageCard") then
			for _, p in sgs.qlist(targets) do
				if q(self,"isEnemy",p) and q(self,"canDamage",p,use.from,use.card) then
					return true
				end
			end
		else
			if math.random() < 0.5 then
				for _, p in sgs.qlist(targets) do
					if q(self,"isEnemy",p) then
						return true
					end
				end
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.heg_jujian = function(self, data)
	local target = q(data,"toDying").who
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.heg_jujian = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrentDyingPlayer")
		if target then call(self,"updateIntention",player,target,-80) end
	end
end

sgs.ai_skill_playerchosen.heg_zhidao = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	q(self,"getTurnUse")
	if #self.toUse > 1 then
		for _,c in sgs.list(sort_keep(self,q(self.player,"getHandcards")))do
			if table.contains(self.toUse,c) then
				begin_range(self)
				local dummy_use = call(self,"aiUseCard",c, dummy())
				end_range(self)
				if dummy_use and dummy_use.card and not q(dummy_use.to,"isEmpty") then
					for _,p in sgs.qlist(dummy_use.to)do
						if q(self,"isEnemy",p) and q(self,"canDamage",p,self.player) and table.contains(targets, p) then
							return p
						end
					end
				end
			end
		end
	end
	for _,p in ipairs(targets)do
		if q(self,"isEnemy",p) and q(self,"canDamage",p,self.player) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention.heg_zhidao = 80


sgs.ai_fill_skill.heg_jinfa = function(self,inclusive,request)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_use(self,cards, true)
	for _, card in ipairs(cards) do
		return parse_source("#heg_jinfa:" .. q(card,"getEffectiveId") .. ":")
	end
end

sgs.ai_skill_use_func["#heg_jinfa"] = function(card,use,self,request)
	local slash = clone_source("slash", sgs.Card_NoSuit, -1)
	call(slash,"setSkillName","heg_jinfa")
	call(slash,"deleteLater")
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isNude") and q(self,"doDisCard",enemy, "he", true) and (not q(self,"isWeak") or not q(self,"slashIsEffective",slash, self.player,enemy) or not q(self,"canHit",self.player,enemy)) then
			use.card = card
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not q(friend,"isNude") and q(self,"doDisCard",friend, "he", true) then
			use.card = card
			if use.to then call(use.to,"append",friensd) end
			return
		end
	end
end

extra_alias{ id="ai_choicemade_filter.cardChosen.heg_jinfa",registry="ai_choicemade_filter",path={"cardChosen","heg_jinfa"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_cardask["@heg_jinfa"] = function(self, data, pattern, target, target2)
	if target then
		if q(self,"isFriend",target) then
			return "."
		end
		if q(self,"isEnemy",target) then
			local slash = clone_source("slash", sgs.Card_NoSuit, -1)
			call(slash,"setSkillName","heg_jinfa")
			call(slash,"deleteLater")
			if q(self,"slashIsEffective",slash, target,self.player) then
				for _,c in ipairs(sort_keep(self,AIList.new(q(self.player,"getCards","he"))))do
					if match_pattern(pattern,self.player,c)
					and q(c,"getSuit") == sgs.Card_Spade
					then return q(c,"getLegacyStringKey") end
				end
			end
		end
	end
	return true
end

sgs.ai_skill_playerschosen.heg_baolie = function(self, targets, max, min)
	local selected = AIList.new{}
	local can_choose = AIList.new(targets)
	sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if q(self,"isEnemy",target) and q(self,"doDisCard",target, "he") and q(self,"isTiaoxinTarget",target) then
			call(selected,"append",target)
		end
	end
	if q(selected,"isEmpty") then
		for _,target in ipairs(can_choose) do
			if q(self,"isEnemy",target) and q(self,"isTiaoxinTarget",target) then
				call(selected,"append",target)
				if q(selected,"length") >= min then break end
			end
		end
	end
	if q(selected,"isEmpty") then
		for _,target in ipairs(can_choose) do
			if q(self,"isEnemy",target) then
				call(selected,"append",target)
				if q(selected,"length") >= min then break end
			end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_baolie = function(self, from, prompt)
    local intention = 20
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_skill_invoke.heg_chenglue = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"canDraw",target) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_chenglue = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	local to  = call(self,"findPlayerToDraw",true,1)
	if to then return to end
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(self,"getOverflow",p) > 0 then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return nil 
end

sgs.ai_choicemade_filter.skillInvoke.heg_chenglue = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

sgs.ai_playerchosen_intention.heg_chenglue = -50

sgs.ai_skill_playerchosen.heg_lianpian = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(self,"canDraw",p) then
			return p
		end
	end
	return nil 
end

sgs.ai_playerchosen_intention.heg_lianpian = -50

sgs.ai_skill_choice.heg_lianpian = function(self, choices, data)
	local discard = getChoice(choices, "discard")
	local recover = getChoice(choices, "recover")
	local target = q(data,"toPlayer")
	if q(self,"isFriend",target) then
		if q(target,"getHp") < source_helper("getBestHp",target) then
			return recover
		end
	end
	if discard and q(self,"doDisCard",target, "he") then
		return discard
	end
	return "cancel"
end

sgs.ai_choicemade_filter.skillChoice.heg_lianpian = function(self,player,promptlist)
	local choice = promptlist[#promptlist]
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getOtherPlayers",player))do
		if q(p,"hasFlag","heg_lianpianTarget") then
			target = p
			break
		end
	end
	if not target then return end
	if choice=="recover" then call(self,"updateIntention",player,target,-60) end
end

extra_alias{ id="ai_choicemade_filter.cardChosen.heg_lianpian",registry="ai_choicemade_filter",path={"cardChosen","heg_lianpian"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_invoke.heg_congcha = true

sgs.ai_skill_playerchosen.heg_congcha = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(self,"canDraw",p) then
			return p
		end
	end
	return nil 
end

sgs.ai_playerchosen_intention.heg_congcha = -50

sgs.ai_skill_invoke.heg_jinxian = function(self, data)
	local targets = AIList.new{}
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self.player,"distanceTo",p) <= 1 then
			call(targets,"append",p)
		end
	end
	if q(targets,"isEmpty") then return false end
	local good = 0
	for _, p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he", false, 2) then
			good = good + 2
		elseif q(self,"isFriend",p) and not q(self,"doDisCard",p, "he") then
			good = good - 2
		end
	end
	if good > 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_tongling = function(self, targets)
	local damage = room_tag("CurrentDamageStruct"):toDamage()
	if not damage then return nil end
	if damage.to and q(damage.to,"isAlive") and q(self,"isFriend",damage.to) then
		return nil
	end
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard", true)
	local max = 0
	for _,p in sgs.list(targets)do do 
		if not q(self,"isFriend",p) then goto package_continue_5 end
		local x = 0
		local kc = getKnownCards(p,self.player)
		for _,c in sgs.list(kc)do
			if q(c,"isDamageCard") then
				x = x + 1
			end
		end
		x = x + q(p,"getHandcardNum")/3
		if x > max then
			max = x
		end
	end ::package_continue_5:: end
	for _,p in sgs.list(targets)do do 
		if not q(self,"isFriend",p) then goto package_continue_6 end
		local x = 0
		local kc = getKnownCards(p,self.player)
		for _,c in sgs.list(kc)do
			if q(c,"isDamageCard") then
				x = x + 1
			end
		end
		x = x + q(p,"getHandcardNum")/3
		if x == max then
			return p
		end
	end ::package_continue_6:: end
	return nil 
end

sgs.ai_playerchosen_intention.heg_tongling = -20

sgs.ai_skill_cardask["@heg_nos_daming"] = function(self, data, pattern, target, target2)
	local current = call(self.room,"getCurrent")
	if not current or not q(current,"isAlive") then return "." end
	local targets = AIList.new{}
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if not q(p,"isChained") then
			call(targets,"append",p)
		end
	end
	if q(targets,"isEmpty") then return "." end
	if q(self,"isFriend",current) then
		if q(current,"getHp") < source_helper("getBestHp",current) then
			self.heg_nos_daming = "peach"
			return true
		end
	end
	local thunder_slash = clone_source("thunder_slash", sgs.Card_NoSuit, 0)
	call(thunder_slash,"setSkillName","heg_nos_daming")
	call(thunder_slash,"deleteLater")
	begin_range(self)
	local dummy_use = call(self,"aiUseCard",thunder_slash, dummy())
	end_range(self)
	if dummy_use and dummy_use.card and not q(dummy_use.to,"isEmpty") then
		self.heg_nos_daming = "thunder_slash"
		return true
	end
	return "."
end

sgs.ai_skill_playerchosen.heg_nos_daming = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _,p in ipairs(targets)do
		if q(self,"isEnemy",p) and not q(p,"isChained") then
			return p
		end
	end
	return targets[1] 
end

sgs.ai_skill_playerchosen.heg_nos_daming_slash = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	local thunder_slash = clone_source("thunder_slash", sgs.Card_NoSuit, 0)
	call(thunder_slash,"setSkillName","heg_nos_daming")
	call(thunder_slash,"deleteLater")
	begin_range(self)
	local dummy_use = call(self,"aiUseCard",thunder_slash, dummy(true, 99))
	end_range(self)
	if dummy_use and dummy_use.card and not q(dummy_use.to,"isEmpty") then
		for _,p in sgs.qlist(dummy_use.to)do
			if q(self,"isEnemy",p) and table.contains(targets, p) then
				return p
			end
		end
	end
	return targets[1] 
end

sgs.ai_playerchosen_intention.heg_nos_daming = 30

sgs.ai_playerchosen_intention.heg_nos_daming_slash = function(self,from,to)
	local thunder_slash = clone_source("thunder_slash", sgs.Card_NoSuit, 0)
	call(thunder_slash,"deleteLater")
	local callback = sgs.ai_card_intention.Slash(self, thunder_slash, from, {to})
	if type(callback)=="function" then 
		callback(self,thunder_slash,from,AIList.new(to))
	end
end

sgs.ai_skill_choice.heg_nos_daming = function(self, choices, data)
	local items = q(choices,"split","+")
	if self.heg_nos_daming then return self.heg_nos_daming end
	return items[math.random(1,#items)]
end

sgs.ai_choicemade_filter.skillChoice.heg_nos_daming = function(self,player,promptlist)
	local choice = promptlist[#promptlist]
	local target = call(self.room,"getCurrent")
	if not target then return end
	if choice=="peach" then call(self,"updateIntention",player,target,-40) end
end

sgs.ai_suppress_intention["heg_nos_daming"] = true

sgs.ai_canliegong_skill.heg_nos_xiaoni = function(self, from, to)
	local same_faction = true
	local x = 0
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",from)) do
		if q(p,"getKingdom") == q(from,"getKingdom") then
			x = x + 1
			if q(p,"getHandcardNum") > q(from,"getHandcardNum") then
				same_faction = false
				break
			end
		end
	end
	if same_faction and x > 0 then
		return true
	end
end

sgs.ai_skill_invoke.heg_juejue = function(self, data)
	if q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 then
		return (math.random() < 0.5 or source_helper("hasZhaxiangEffect",self.player)) and not q(self,"isWeak") and q(self,"getOverflow") > 0
	end
	return false
end

sgs.ai_skill_discard.heg_juejue = function(self, discard_num, min_num, optional, include_equip)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
	local to_discard = {}
	local current = call(self.room,"getCurrent")
	if not current or not q(current,"isAlive") then
		return to_discard
	end
	if q(self,"needToLoseHp",self.player, current, nil) or not q(self,"damageIsEffective",self.player,nil,current) then
		return to_discard
	end
	if not q(self,"isWeak") and min_num > 2 then
		return to_discard
	end
	if q(self,"getCardsNum","Peach") > 0 and discard_num > 2 then
		return to_discard
	end
	for _,c in ipairs(cards)do
		if q(self,"getKeepValue",c) <= 6 then
			table.insert(to_discard,q(c,"getEffectiveId"))
			if #to_discard >= discard_num then break end
		end
	end
	if #to_discard < min_num then
		return {}
	end
	return to_discard
end

extra_alias{ id="ai_skill_playerchosen.heg_fangyuan",registry="ai_skill_playerchosen",path={"heg_fangyuan"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1,defer_canonical=true}
sgs.ai_skill_invoke.heg_tongdu = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"canDraw",target, self.player) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_tongdu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-80) end
	end
end

sgs.ai_fill_skill.heg_qingyin = function(self,inclusive,request)
	if (#self.friends<=#self.enemies and q(self.room,"getTurnCount")>2 and q(self.player,"getLostHp")>0) or (q(self.room,"getTurnCount")>1 and q(self,"isWeak")) then
		return parse_source("#heg_qingyin:.:")
	end
end

sgs.ai_skill_use_func["#heg_qingyin"] = function(card,use,self,request)
	use.card = card
	for i = 1,#self.friends do
		call(use.to,"append",self.friends[i])
	end
end

sgs.ai_card_intention["heg_qingyin"] = -80
sgs.ai_use_priority["heg_qingyin"] = 9.31

sgs.ai_fill_skill.heg_duwu = function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if (#self.friends<=#self.enemies and q(self.room,"getTurnCount")>2 and q(self.player,"getLostHp")>0) or (q(self.room,"getTurnCount")>1 and q(self,"isWeak")) then
		return parse_source("#heg_duwu:.:")
	end
end

sgs.ai_skill_use_func["#heg_duwu"] = function(card,use,self,request)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if q(self,"canDamage",enemy) and q(self.player,"inMyAttackRange",enemy) then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	sort_players(self,targets, "defense")
	use.card = card
	for i = 1, #targets do
		call(use.to,"append",targets[i])
	end
end

sgs.ai_card_intention["heg_duwu"] = 80
sgs.ai_use_priority["heg_duwu"] = sgs.ai_use_priority.DuwuCard

sgs.ai_skill_cardask["@heg_xishe"] = function(self, data, pattern, target, target2)
	local slash = clone_source("slash", sgs.Card_NoSuit, 0)
	call(slash,"setSkillName","_heg_xishe")
	call(slash,"deleteLater")
	begin_range(self)
	local dummy_use = call(self,"aiUseCard",slash, dummy(true, 99, q(self.room,"getOtherPlayers",target)))
	end_range(self)
	if dummy_use and dummy_use.card and not q(dummy_use.to,"isEmpty") then
		for _,p in sgs.qlist(dummy_use.to)do
			if q(p,"objectName") == q(target,"objectName") and (q(self.player,"getEquips"):length() > 1 or q(self,"isWeak",target)) then
				return true
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_xishe = function(self, data)
	return math.random() < 0.5
end

sgs.ai_ajustdamage_from.heg_suzhi = function(self, from, to, card, nature)
	if q(from,"getMark","heg_suzhi-Clear") < 3 and card and (q(card,"isKindOf","Slash") or q(card,"isKindOf","Duel")) and q(from,"getPhase") ~= sgs.Player_NotActive then
		return 1
	end
end

extra_alias{ id="ai_card_priority.heg_suzhi",registry="ai_card_priority",path={"heg_suzhi"},canonical_registry="ai_card_priority",canonical_path={"jizhi"},self_index=1,defer_canonical=true}
sgs.ai_skill_playerchosen.heg_zhaoxin = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _, p in ipairs(targets) do
		if q(p,"getHandcardNum")>1 and q(self,"isFriend",p) and (hasTuntianEffect(p) or q(self,"hasLoseHandcardEffective",p)) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(p,"getHandcardNum")>1 and q(self,"isFriend",p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(p,"getHandcardNum")>=1 and q(self,"doDisCard",p, "h", true) then
			return p
		end
	end
end

sgs.ai_can_damagehp.heg_quanji = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>1
	and q(self,"canLoseHp",from,card,to) and q(to,"getMark","heg_quanji-Inflicted-Clear") == 0
end

sgs.ai_fill_skill.heg_paiyi = function(self,inclusive,request)
	if q(self.player,"getPile","heg_quanji_power"):length()>2 then
		return parse_source("#heg_paiyi:"..q(self.player,"getPile","heg_quanji_power"):first()..":")
	end
end
sgs.ai_skill_use_func["#heg_paiyi"] = function(card,use,self,request)
	local target
	local targets = call(self,"findPlayerToDraw",true,q(self.player,"getPile","heg_quanji_power"):length() - 1,true)
	for _,p in ipairs(targets)do
		if q(p,"getHandcardNum")<2 and q(p,"getHandcardNum")+q(self.player,"getPile","heg_quanji_power"):length() - 1 <q(self.player,"getHandcardNum") and q(self,"isFriend",p) then
			target = p
		end
		if target then break end
	end
	if not target then
		if q(self.player,"getHandcardNum")<q(self.player,"getHp")+q(self.player,"getPile","heg_quanji_power"):length()-1 and q(self,"canDraw",self.player) then
			target = self.player
		end
	end
	
	if not target then
		sort_players(self,targets,"hp")
		targets = sgs.reverse(targets)
		for _,friend in ipairs(targets)do
			if q(friend,"getHandcardNum")+q(self.player,"getPile","heg_quanji_power"):length() - 1>q(self.player,"getHandcardNum")
			and q(self,"needToLoseHp",friend,self.player,nil,true) and q(self,"isFriend",friend) then
				target = friend
			end
			if target then break end
		end
	end
	sort_players(self,self.enemies,"defense")
	if not target and q(self.player,"getPile","heg_quanji_power"):length() - 1 <= 2 then
		for _,enemy in ipairs(self.enemies)do
			if source_helper("hasManjuanEffect",enemy) 
			and q(self,"canDamage",enemy, self.player, nil)
			and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player)
			and not q(self,"needToLoseHp",enemy)
			and q(enemy,"getHandcardNum")>q(self.player,"getHandcardNum") 
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if q(self,"canDamage",enemy, self.player, nil)
				and not q(enemy,"hasSkills",sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player) and not q(self,"cantbeHurt",enemy)
				and not q(self,"needToLoseHp",enemy)
				and q(enemy,"getHandcardNum")+q(self.player,"getPile","heg_quanji_power"):length() - 1>q(self.player,"getHandcardNum")
				and not source_helper("hasManjuanEffect",enemy) and ZishuEffect(enemy) <= 0
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = parse_source("#heg_paiyi:"..q(self.player,"getPile","heg_quanji_power"):first()..":")
		call(use.to,"append",target)
	end
end

sgs.ai_card_intention["heg_paiyi"] = sgs.ai_card_intention.PaiyiCard

sgs.ai_can_damagehp.heg_nos_quanji = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>1
	and q(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_discard.heg_shilus = function(self, discard_num, min_num, optional, include_equip)
	local card = parse_source("@ZhihengCard=.")
	local dummy_use = dummy()
	call(self,"useSkillCard",card,dummy_use)
	local to_discard = {}
	if dummy_use.card then 
		local use_cards = q(dummy_use.card,"getSubcards")
		for _,id in sgs.list(use_cards) do
			table.insert(to_discard,id)
			if #to_discard >= discard_num then break end
		end
	end
	return to_discard
end

sgs.ai_ajustdamage_to.heg_xiongnve = function(self, from, to, card, nature)
	if from and q(from,"objectName") ~= q(to,"objectName") and q(to,"getMark","heg_xiongnve_reduce-Self"..sgs.Player_RoundStart.."Clear") > 0 then
		return -1
	end
end

sgs.ai_ajustdamage_from.heg_xiongnve = function(self, from, to, card, nature)
	local kingdom = q(from,"property","heg_xiongnve"):toString()
	if string.find(kingdom, q(to,"getKingdom")) then
		if q(from,"getMark","heg_xiongnve-Damage-Clear") > 0 then
			return 1
		end
	end
end

sgs.ai_skill_invoke.heg_xiongnve = function(self, data)
	local event = q(data,"toString")
	if event == "start" then
		local general_list = q(self.player,"property","heg_shilus_generals"):toString():split("+")
		q(self,"getTurnUse")
		if #self.toUse > 1 then
			for _,c in sgs.list(sort_keep(self,q(self,"addHandPile","he")))do
				if table.contains(self.toUse,c) and q(c,"isDamageCard") then
					local dummy_use = call(self,"aiUseCard",c, dummy())
					if dummy_use and dummy_use.card and not q(dummy_use.to,"isEmpty") then
						for _,p in sgs.qlist(dummy_use.to)do
							if q(self,"isEnemy",p) and q(self,"canDamage",p,self.player,c) then
								for _,gn in ipairs(general_list) do
									local general = source_general(gn)
									if general and string.find(q(general,"getKingdoms"), q(p,"getKingdom")) then
										source_flag(self,self.player,"heg_xiongnve:"..gn)
										return true
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if event == "end" then
		return q(self,"isWeak")
	end
	return false
end

sgs.ai_fill_skill.heg_huaiyi = function(self,inclusive,request)
	local handcards = q(self.player,"getHandcards")
	local red,black = false,false
	if #self.toUse > 0 then return end
	for _,c in sgs.qlist(handcards)do
		if q(c,"isRed") and not red then
			red = true
			if black then
				break
			end
		elseif q(c,"isBlack") and not black then
			black = true
			if red then
				break
			end
		end
	end
	if red and black then
		return parse_source("#heg_huaiyi:.:")
	end
end

sgs.ai_skill_use_func["#heg_huaiyi"] = function(card,use,self,request)
	local handcards = q(self.player,"getHandcards")
    local reds,blacks = {},{}
    for _,c in sgs.qlist(handcards)do
        if q(c,"isRed") then
            table.insert(reds,c)
        else
            table.insert(blacks,c)
        end
    end
    local targets = call(self,"findPlayerToDiscard","he",false,true)
    local n_reds,n_blacks,n_targets = #reds,#blacks,#targets
	
    if n_targets==0 then
        return 
    elseif n_reds-n_targets>=2 and n_blacks-n_targets>=2 and q(handcards,"length")-n_targets>=5 then
        return 
    end
    use.card = card
end
sgs.dynamic_value.benefit["heg_huaiyi"] = true

sgs.ai_skill_choice.heg_huaiyi = function(self,choices,data)
    return sgs.ai_skill_choice.huaiyi(self,choices,data)
end

sgs.ai_skill_playerschosen.heg_huaiyi = function(self, targets, max, min)
	local selected = AIList.new{}
	local can_choose = AIList.new(targets)
	sort_players(self,can_choose, "defense")
	local targets = call(self,"findPlayerToDiscard","he",false,true)
    for _,target in ipairs(targets)do
		call(selected,"append",target)
		if q(selected,"length") >= max then break end
    end
	return selected
end

sgs.ai_skill_cardchosen.heg_huaiyi = function(self, who, flags)
    if not q(who,"isKongcheng") then
        local handcards = q(who,"getHandcards")
        local cards = AIList.new(handcards)
        local display_cards = getDisplayCards(who, self.player)
		local valuable_cards = {}
		for _, dc in ipairs(display_cards) do
			local card_id = q(dc,"getEffectiveId")
			if not q(self.disabled_ids,"contains",card_id) then
				local value = foreign_keep(self,who,dc)
				table.insert(valuable_cards, {card_id = card_id, value = value})
			end
		end
		
		if #valuable_cards > 0 then
			
			table.sort(valuable_cards, function(a, b) return a.value > b.value end)
			return valuable_cards[1].card_id
		end
        if #cards > 0 then
            return cards[math.random(1, #cards)]
        end
    end
    return nil
end


sgs.ai_fill_skill.heg_nos_huaiyi = function(self,inclusive,request)
	local handcards = q(self.player,"getHandcards")
	local red,black = false,false
	if #self.toUse > 0 then return end
	for _,c in sgs.qlist(handcards)do
		if q(c,"isRed") and not red then
			red = true
			if black then
				break
			end
		elseif q(c,"isBlack") and not black then
			black = true
			if red then
				break
			end
		end
	end
	if red and black then
		return parse_source("#heg_nos_huaiyi:.:")
	end
end

sgs.ai_skill_use_func["#heg_nos_huaiyi"] = function(card,use,self,request)
	local handcards = q(self.player,"getHandcards")
    local reds,blacks = {},{}
    for _,c in sgs.qlist(handcards)do
        if q(c,"isRed") then
            table.insert(reds,c)
        else
            table.insert(blacks,c)
        end
    end
    local targets = call(self,"findPlayerToDiscard","he",false,true)
    local n_reds,n_blacks,n_targets = #reds,#blacks,#targets
	
    if n_targets==0 then
        return 
    elseif n_reds-n_targets>=2 and n_blacks-n_targets>=2 and q(handcards,"length")-n_targets>=5 then
        return 
    end
    use.card = card
end
extra_alias{ id="ai_skill_choice.heg_nos_huaiyi",registry="ai_skill_choice",path={"heg_nos_huaiyi"},canonical_registry="ai_skill_choice",canonical_path={"heg_huaiyi"},self_index=1,defer_canonical=true}
extra_alias{ id="ai_skill_playerschosen.heg_nos_huaiyi",registry="ai_skill_playerschosen",path={"heg_nos_huaiyi"},canonical_registry="ai_skill_playerschosen",canonical_path={"heg_huaiyi"},self_index=1,defer_canonical=true}
sgs.ai_skill_playerchosen.heg_yingshi = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard", true)
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_playerschosen.heg_yingshi_target = function(self, targets, max, min)
	local known_both = clone_source("heg_known_both", sgs.Card_NoSuit, 0)
	call(known_both,"setSkillName","heg_yingshi")
	call(known_both,"deleteLater")
	local dummy_use = call(self,"aiUseCard",known_both, dummy())
	local enemy = AIList.new{}
	if dummy_use.card and q(dummy_use.to,"length") > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if q(self,"isEnemy",p) and q(targets,"contains",p) then
				call(enemy,"append",p)
				if q(enemy,"length") >= max then
					break
				end
			end
		end
	end
	return enemy
end
sgs.ai_playerschosen_intention.heg_yingshi = function(self, from, prompt)
    local intention = 30
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_playerchosen_intention.heg_yingshi = -40


sgs.ai_fill_skill.heg_shunfu = function(self,inclusive,request)
	if #self.enemies == 0 or #self.friends_noself == 0 then return end
	if (q(self.room,"getTurnCount")>1) or (q(self,"isWeak")) then
		return parse_source("#heg_shunfu:.:")
	end
end

sgs.ai_skill_use_func["#heg_shunfu"] = function(card,use,self,request)
	local targets = {}
	sort_players(self,self.friends_noself, "handcard", true)
	local friends = self.friends_noself
	
	for i = 1, 3 do
		local target = q(self,"findPlayerToUseSlash",false, friends, "heg_shunfu", nil, 0, nil)
		if target and q(self,"canDraw",target) then
			table.insert(targets, target)
			table.removeOne(friends, target)
		end
		local friend = call(self,"findPlayerToDraw",false, 1)
		if friend and not table.contains(targets, friend) then
			table.insert(targets, friend)
			table.removeOne(friends, friend)
		end
		if #friends == 0 then break end
	end
	if #targets < 3 then
		for _, friend in ipairs(self.friends_noself) do
			if not table.contains(targets, friend) and q(self,"canDraw",friend) then
				table.insert(targets, friend)
			end
			if #targets >= 3 then break end
		end
	end
	if #targets == 0 then return end
	sort_players(self,targets, "defense")
	use.card = card
	for i = 1, #targets do
		call(use.to,"append",targets[i])
	end
end

sgs.ai_use_priority["heg_shunfu"] = 9.31

sgs.ai_ajustdamage_from.heg_ejue = function(self, from, to, card, nature)
	if card and q(card,"isKindOf","Slash") and q(from,"getKingdom") ~= q(to,"getKingdom") then
		return 1
	end
end

sgs.ai_view_as.heg_yimie_attach = function(card,player,card_place)
	if card_place==sgs.Player_PlaceHand and q(card,"getSuit") == sgs.Card_Heart then
		return ("peach:heg_yimie[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getEffectiveId"))
	end
end

sgs.ai_fill_skill.heg_ruilve_attach = function(self,inclusive,request)
	return parse_source("#heg_ruilve:.:")
end

sgs.ai_skill_use_func["#heg_ruilve"] = function(card,use,self,request)
    for _,p in ipairs(self.friends_noself) do
        if q(p,"hasSkill","heg_ruilve") and q(p,"getMark","heg_ruilve-PlayClear") == 0 and q(self,"canDraw",p, self.player) then
            local cards = q(self.player,"getCards","he")
	        cards = sort_keep(self,cards)
            for _,c in ipairs(cards)do
                if q(c,"isDamageCard") then
                    use.card = parse_source("#heg_ruilve:"..q(c,"getEffectiveId")..":")
                    if use.to then
                        call(use.to,"append",p)
                    end
                    return
                end
            end
        end
    end
    use.card = nil
end

sgs.ai_skill_invoke.heg_beiluan = function(self, data)
	local target = q(data,"toDamage").from
	if target and q(self,"isEnemy",target) and not q(self,"hasCrossbowEffect",target) then
		return true
	end
	if target and q(self,"isFriend",target) and q(self,"hasCrossbowEffect",target) and q(target,"getPhase") == sgs.Player_Play and q(self,"willUse",target,clone_source(),false,false,true) then
		return true
	end
	return false
end

sgs.ai_fill_skill.heg_pojing = function(self,inclusive,request)
	return parse_source("#heg_pojing:.:")
end

sgs.ai_skill_use_func["#heg_pojing"] = function(card,use,self,request)
	local friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if q(friend,"getMark","heg_pojing"..q(self.player,"objectName")) == 0 then
			table.insert(friends, friend)
		end
	end
	if #friends > 0 then
		for _, enemy in ipairs(self.enemies) do
			if q(self,"canDamage",enemy, self.player, nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and q(self,"doDisCard",enemy, "hej", true) then
				for _, friend in ipairs(self.friends_noself) do
					if q(friend,"getMark","heg_pojing"..q(self.player,"objectName")) == 0 and q(self,"canDamage",enemy, friend, nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, friend) then
						use.card = card
						call(use.to,"append",enemy)
						return
					end
				end
			end
		end
	else
		for _, friend in ipairs(self.friends_noself) do
			if q(self,"doDisCard",friend, "hej", true) then
				use.card = card
				call(use.to,"append",friend)
				return
			end
		end
	end
end
sgs.ai_use_priority["heg_pojing"] = 4.8

sgs.ai_skill_choice.heg_pojing = function(self, choices, data)
	local target = q(data,"toPlayer")
	local items = q(choices,"split","+")
	local obtain = getChoice(choices, "obtain")
	if (q(self,"isFriend",target) or q(self,"doDisCard",self.player, "hej", true)) and obtain then
		return obtain
	end
	local x = 0
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",target)) do
		if q(self,"isEnemy",p) and q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, p) and q(p,"getMark","heg_pojing"..q(target,"objectName")) == 0 then
			x = x + 1
		end
	end
	if (x > 2 or x > q(self.player,"getHp") + q(self,"getAllPeachNum")) and obtain then
		return obtain
	end
	return "damage"
end

sgs.ai_skill_invoke.heg_pojing = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"canDamage",target, self.player, nil) and q(self,"damageIsEffective",target, sgs.DamageStruct_Normal, self.player) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.heg_gongzhi = function(self, data)
	return sgs.ai_skill_playerschosen.heg_gongzhi(self, q(self.room,"getAlivePlayers"), 0, 4):length() > 0
end

sgs.ai_skill_playerschosen.heg_gongzhi = function(self, targets, max, min)
	local selected = AIList.new{}
	local can_choose = AIList.new(targets)
	sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose)do
		if q(self,"canDraw",target) and q(self,"isFriend",target) then
			call(selected,"append",target)
			if q(selected,"length") >= max then break end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_gongzhi = function(self, from, prompt)
    local intention = -30
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
		if to and q(self,"canDraw",to) then
        	call(self,"updateIntention",from, to, intention)
		end
    end
end

sgs.ai_skill_invoke.heg_shejus = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) and q(self,"isWeak",target) and (q(target,"getHandcardNum") < 3 or getKnownCard(target,self.player,"Peach")<1) then
		return true
	end
	if target and q(self,"isEnemy",target) and (q(target,"getHandcardNum") >= 3 or getKnownCard(target,self.player,"Peach")>0) then
		return true
	end
	
	return false
end

sgs.ai_skill_cardask["@heg_zhulan"] = function(self, data, pattern, target, target2)
	local damage = q(data,"toDamage")
	if q(self,"isEnemy",damage.to) then
		if not q(self,"cantDamageMore",damage.from, damage.to) then
			return true
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@heg_zhulan"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local target = room_tag("heg_zhulan"):toDamage().to
		if not target then return end
		call(self,"updateIntention",player, target, 80)
	end
end

sgs.ai_skill_invoke.heg_luanchang = function(self, data)
	local current = call(self.room,"getCurrent")
	local card = clone_source("archery_attack", sgs.Card_NoSuit, 0)
	call(card,"setSkillName","heg_luanchang")
	call(card,"addSubcards",q(current,"getHandcards"))
	call(card,"deleteLater")
	local dummy_use = call(self,"aiUseCard",card, dummy())
	if dummy_use.card then
		return true
	end
	return false
end

sgs.ai_ajustdamage_from.heg_zhuosheng = function(self, from, to, card, nature)
	if card and (q(card,"hasFlag","heg_zhuosheng") or q(from,"getMark","&heg_zhuosheng-Clear") > 0) then
		return 1
	end
end

sgs.ai_skill_cardask["@heg_ciwei"] = function(self, data, pattern, target, target2)
	local use = q(data,"toCardUse")
	for _, p in sgs.qlist(use.to) do
		if q(self,"isFriend",p) and q(self,"shouldInvokeCostNullifySkill",use, true, false, 1, p) then
			return true
		end
	end
	if (q(use.card,"isKindOf","Jink") or q(use.card,"isKindOf","Nullification")) and use.from and q(self,"isEnemy",use.from) then
		return true
	end
	return "."
end

source_use_registry["@@heg_yanxi"] = function(self, prompt, method)
	self:chuliSourceMap("reset")
	local players = call(self,"findPlayerToDiscard","h",false,true)
	local kingdoms = {}
	local targets = {}
	for _,player in ipairs(players)do
		if q(self,"isFriend",player) and not table.contains(kingdoms,q(player,"getKingdom")) then
			table.insert(targets,q(player,"objectName"))
			table.insert(kingdoms,q(player,"getKingdom"))
			if #targets >= 3 then break end
		end
	end
	for _,player in ipairs(players)do
		if not table.contains(targets,q(player,"objectName")) and not table.contains(kingdoms,q(player,"getKingdom")) then
			table.insert(targets,q(player,"objectName"))
			table.insert(kingdoms,q(player,"getKingdom"))
			if #targets >= 3 then break end
		end
	end
	if #targets==0 then return "." end
	for _,p in ipairs(targets)do
		local target = call(self.room,"findPlayerByObjectName",p)
		local id = q(self,"askForCardChosen",target,"h","dummyreason",sgs.Card_MethodDiscard)
		local chosen_card
		if id then chosen_card = disclosed(id) end
		if id and chosen_card and (q(self,"isFriend",target) or not q(target,"hasEquip",chosen_card) or disclosed(id):getSuit()~=sgs.Card_Spade) then
			self:chuliSourceMap("set",q(target,"objectName"),id)
		end
	end
	if #targets > 0 then
		return "#heg_yanxi:.:->"..table.concat(targets,"+")
	end
	return "."
end
sgs.ai_card_intention["heg_yanxi"] = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if self:chuliSourceMap("state") and self:chuliSourceMap("entry",q(to,"objectName")) then
			local em_prompt = {"cardChosen","heg_yanxi",tostring(self:chuliSourceMap("entry",q(to,"objectName"))),q(to,"objectName")}
			sgs.ai_choicemade_filter.cardChosen.snatch(self,nil,em_prompt)
		end
	end
end

sgs.ai_skill_choice.heg_yanxi = function(self, choices, data)
	local items = q(choices,"split","+")
	local card = disclosed(q(data,"toInt"))
	local current = call(self.room,"getCurrent")
	if current and card then
		if q(self,"isFriend",current) then
			return items[math.random(1, #items)]
		elseif q(self,"isEnemy",current) then
			for _,item in ipairs(items)do
				if item == q(card,"getClassName") then
					return item
				end
			end
		end
	end
	return items[math.random(1, #items)]
end

sgs.ai_skill_invoke.heg_shiren = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(self,"isFriend",damage.to) and q(self,"canDraw",damage.to) then
		return true
	end
	if damage.to and q(self,"isEnemy",damage.to) then
		return false
	end
	return math.random() < 0.5
end

source_use_registry["@@heg_jiantong"] = function(self, prompt, method)
	sort_players(self,self.enemies, "handcard", true)
	for _, enemy in ipairs(self.enemies) do
		if q(self,"doDisCard",enemy, "h", true, 2) and not q(self,"loseEquipEffect",enemy) then
			return "#heg_jiantong:.:->"..q(enemy,"objectName")
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"doDisCard",enemy, "h", true, 2) then
			return "#heg_jiantong:.:->"..q(enemy,"objectName")
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_jiantong = true

sgs.ai_skill_playerchosen.heg_chengxi = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard", true)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and not q(self,"canDraw",p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.heg_chengxi = 60

sgs.ai_skill_playerschosen.heg_chengxi = function(self, targets, max, min)
	local selected = AIList.new{}
	local can_choose = AIList.new(targets)
	sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose)do
		if q(self,"canDamage",target, self.player, nil) and q(self,"doDisCard",target, "he")  then
			call(selected,"append",target)
			if q(selected,"length") >= max then break end
		end
	end
	return selected
end

sgs.ai_damage_reason_suppress_intention.heg_chengxi = true

sgs.ai_playerschosen_intention.heg_chengxi = function(self, from, prompt)
    local intention = 60
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_canliegong_skill.heg_chujue = function(self, from, to)
	for _, p in sgs.qlist(q(self.room,"getAllPlayers",true)) do
		if q(p,"isDead") and q(p,"getKingdom") == q(to,"getKingdom") then
			return true
		end
	end
end

sgs.ai_skill_invoke.heg_jianzhi = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(damage.to,"getRole") == "rebel" and q(self,"getAllPeachNum",damage.to) + q(damage.to,"getHp") + q(damage.to,"getHujia") <= damage.damage then
		return q(self.player,"getHandcardNum") < 9
	end
	return false
end

sgs.ai_skill_playerchosen.heg_zhefu  = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard", true)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "h") then
			return p
		end
	end
	return nil
end

extra_alias{ id="ai_choicemade_filter.cardChosen.heg_zhefu",registry="ai_choicemade_filter",path={"cardChosen","heg_zhefu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_playerchosen.heg_yidu  = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard", true)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "h") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.heg_yidu = 40

sgs.ai_fill_skill.heg_chengliu = function(self,inclusive,request)
	return parse_source("#heg_chengliu:.:")
end

sgs.ai_skill_use_func["#heg_chengliu"] = function(card,use,self,request)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"getEquips"):length() < q(self.player,"getEquips"):length() and q(self,"canDamage",enemy, self.player, nil) and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player) then
			table.insert(targets, enemy)
		end
	end
	
	if #targets > 0 then
		table.sort(targets, function(a, b)
			return q(a,"getEquips"):length() > q(b,"getEquips"):length()
		end)
		use.card = card
		if use.to then call(use.to,"append",targets[1]) end
	end
end
source_use_registry["@@heg_chengliu"] = function(self, prompt, method)
	local card = parse_source("#heg_chengliu:.:")
	local dummy_use = dummy()
	call(self,"useSkillCard",card,dummy_use)
	local to_discard = {}
	if dummy_use.card then
		return "#heg_chengliu:.:->"..q(dummy_use.to,"first"):objectName()
	end
	return "."
end

sgs.ai_skill_invoke.heg_chengliu = function(self, data)
	local target = q(data,"toPlayer")
	return q(self,"doDisCard",target, "e", true)
end

sgs.ai_skill_playerschosen.heg_xunjim = function(self, targets, max, min)
	local use = room_tag("heg_xunjim"):toCardUse()
	local dummy_use = call(self,"aiUseCard",use.card, dummy(true, 2, use.to))
	local enemy = AIList.new{}
	if dummy_use.card and q(dummy_use.to,"length") > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if q(self,"isEnemy",p) and q(targets,"contains",p) then
				call(enemy,"append",p)
				if q(enemy,"length") >= max then
					break
				end
			end
		end
	end
	return enemy
end

sgs.ai_skill_cardask["@heg_xijue-xiaoguo"] = function(self, data, pattern, target, target2)
	if sgs.ai_skill_cardask["@xiaoguo"](self, data) ~= "." and q(self.player,"getCardCount",true) > 1 then
		return true
	end
	return "."
end
sgs.ai_skill_cardask["@heg_xijue-tenyeartuxi"] = function(self, data, pattern, target, target2)
	local tuxi_string = source_use_registry["@@tenyeartuxi"](self, prompt)
	if tuxi_string == "." then
		return "."
	end
	return true
end

sgs.ai_skill_cardask["@heg_yingwei"] = function(self, data, pattern, target, target2)
	return true
end

sgs.ai_skill_invoke.heg_duanqiu = function(self, data)
	q(self,"getTurnUse")
	if #self.toUse > 2 then return false end
	local duel = clone_source("duel", sgs.Card_NoSuit, 0)
	call(duel,"setSkillName","heg_duanqiu")
	call(duel,"deleteLater")
	local dummy_use = call(self,"aiUseCard",duel, dummy())
	if dummy_use.card then
		return true
	end
	return false
end

sgs.ai_skill_choice.heg_duanqiu_ChooseKingdom = function(self, choices)
	local items = q(choices,"split","+")
	local duel = clone_source("duel", sgs.Card_NoSuit, 0)
	call(duel,"setSkillName","heg_duanqiu")
	call(duel,"deleteLater")
	local dummy_use = call(self,"aiUseCard",duel, dummy())
	if dummy_use.card then
		for _,p in sgs.list(dummy_use.to)do
			return q(p,"getKingdom")
		end
	end
	return items[math.random(1, #items)]
end

sgs.ai_skill_invoke.heg_huaiyuan = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_huaiyuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrent")
		if target then call(self,"updateIntention",player,target,-30) end
	end
end

sgs.ai_skill_playerchosen.heg_neiji = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "handcard", true)
	if q(self,"getCardsNum","Slash") > 0 then
		if sgs.ai_role[q(self.player,"objectName")] == "neutral" then return nil end
		for _, p in ipairs(targets) do
			if q(self,"isFriend",p) and q(self,"canDraw",p) and (q(p,"getHandcardNum") >= 3 or getKnownCard(p,self.player,"Slash")>0) then
				return p
			end
		end
	else
		local duel = clone_source("duel", sgs.Card_NoSuit, 0)
		call(duel,"setSkillName","heg_neiji")
		call(duel,"deleteLater")
		local dummy_use = call(self,"aiUseCard",duel, dummy(true, 99))
		if dummy_use.card then
			for _,p in sgs.list(dummy_use.to)do
				if q(self,"isEnemy",p) and (q(p,"getHandcardNum") <= 2 and getKnownCard(p,self.player,"Slash")<=0) and table.contains(targets, p) then
					return p
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_discard.heg_neiji = function(self, discard_num, min_num, optional, include_equip) 
	local target
	local current = call(self.room,"getCurrent")
	if not current then
		return {}
	end
	if q(current,"objectName") == q(self.player,"objectName") then
		for _, p in sgs.list(q(self.room,"getAllPlayers"))do
			if q(p,"hasFlag","heg_neiji") then
				target = p
				break
			end
		end
	else
		if current then target = current end
	end
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,cards)
	local to_discard = {}
	if target then
		if q(self,"isFriend",target) then
			for _,c in ipairs(cards) do
				if q(c,"isKindOf","Slash") then					
					table.insert(to_discard, q(c,"getEffectiveId"))
					break
				end
			end
			for _,c in ipairs(cards) do
				if not q(c,"isKindOf","Slash") then					
					table.insert(to_discard, q(c,"getEffectiveId"))
					break
				end
			end
		else
			for _,c in ipairs(cards) do
				if not q(c,"isKindOf","Slash") then					
					table.insert(to_discard, q(c,"getEffectiveId"))
					if #to_discard >= min_num then break end
				end
			end
			if #to_discard < min_num then
				to_discard = {}
				for _,c in ipairs(cards) do
					if not q(c,"isKindOf","Slash") then					
						table.insert(to_discard, q(c,"getEffectiveId"))
						if #to_discard >= min_num then break end
					end
				end
			end
		end
	end
	return to_discard
end

sgs.ai_suppress_intention.heg_neiji = true

sgs.ai_view_as.heg_xiace = function(card,player,card_place)
	local current
	for _, p in sgs.list(q(player,"getAliveSiblings",true)) do
		if q(p,"hasFlag","CurrentPlayer") then
			current = p
			break
		end
	end
	if card_place~=sgs.Player_PlaceSpecial and current and sgs.Slash_IsAvailable(current) then
		return ("nullification:heg_xiace[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getEffectiveId"))
	end
end

sgs.ai_skill_invoke.heg_xiace = function(self, data)
	return math.random() < 0.5
end

sgs.ai_skill_cardask["@heg_limeng"] = function(self, data, pattern)
	local selected = sgs.ai_skill_playerschosen.heg_limeng(self, q(self.room,"getAllPlayers"),2, 2)
	if selected and q(selected,"length") == 2 then
		return true
	end
	return "."
end

sgs.ai_skill_playerschosen.heg_limeng = function(self, targets, max, min)
	local selected = AIList.new{}
	local can_choose = AIList.new(targets)
	sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose)do
		for _,target2 in ipairs(can_choose)do
			if target ~= target2 and q(self,"canDamage",target, target2, nil) and q(self,"canDamage",target2, target ,nil) then
				call(selected,"append",target)
				call(selected,"append",target2)
				break 
			end
		end
		if q(selected,"length") >= max then break end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_limeng = function(self, from, prompt)
    local intention = 40
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
		if not q(self,"needToLoseHp",to) then
        	call(self,"updateIntention",from, to, intention)
		end
    end
end

sgs.ai_damage_reason_suppress_intention.heg_limeng = true

sgs.ai_fill_skill.heg_xiejian = function(self,inclusive,request)
	return parse_source("#heg_xiejian:.:")
end
sgs.ai_skill_use_func["#heg_xiejian"] = function(card,use,self,request)
	sort_players(self,self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		use.card = card
		call(use.to,"append",enemy)
		return
	end
end
sgs.ai_use_priority["heg_xiejian"] = 4.8

 
sgs.ai_fill_skill.heg_yinsha = function(self,inclusive,request)
    if q(self.player,"getHandcardNum")>q(self.player,"getHp")
	or q(self.player,"isKongcheng") or #self.toUse>1 then return end
	local collateral = clone_source("collateral")
    call(collateral,"addSubcards",q(self.player,"getHandcards"))
    call(collateral,"setSkillName","heg_yinsha")
	return collateral
end

sgs.ai_suppress_intention.heg_yinsha = true

sgs.ai_fill_skill.heg_sanchen = function(self,inclusive,request)
	return parse_source("#heg_sanchen:.:")
end
sgs.ai_skill_use_func["#heg_sanchen"] = function(card,use,self,request)
	sort_players(self,self.friends,"handcard")
	self.friends = sgs.reverse(self.friends)
	for _,p in sgs.list(self.friends)do
		if q(self,"doDisCard",p,"he") and q(p,"getMark","heg_sanchen_target-PlayClear")==0 then
			use.card = card
			call(use.to,"append",p)
			return
		end
	end
	for _,p in sgs.list(self.friends)do do 
		if q(p,"getMark","heg_sanchen_target-PlayClear")>0 then goto package_continue_7 end
		use.card = card
		call(use.to,"append",p)
		return
	end ::package_continue_7:: end
end
sgs.ai_use_value["heg_sanchen"] = 10
sgs.ai_card_intention["heg_sanchen"] = -50

source_use_registry["@@heg_pozhu"] = function(self, prompt)
	local cards = AIList.new(q(self,"addHandPile","he"))
    sort_keep(self,cards)
    for _, c in ipairs(cards) do
		local slash = clone_source("slash", sgs.Card_SuitToBeDecided, -1)
		call(slash,"addSubcard",c)
		call(slash,"setSkillName","heg_pozhu")
		call(slash,"deleteLater")
		local dummy_use = call(self,"aiUseCard",slash,dummy())
		if dummy_use.card and dummy_use and dummy_use.to then
			local tos = {}
        	for _,to in sgs.qlist(dummy_use.to) do
				table.insert(tos, q(to,"objectName"))
			end
        	return q(slash,"getLegacyStringKey").."->"..table.concat(tos, "+")
		end
	end
    return "."
end


source_use_registry["@@heg_fk_bushi"] = function(self, prompt, method)
	local ids = q(self.player,"getPile","heg_fk_rice")
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,disclosed(id))
    end
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if q(self,"canDraw",friend, self.player) then
			table.insert(targets, q(friend,"objectName"))
		end
	end
	if #targets == 0 or #cards == 0 then return "." end
	return "#heg_fk_bushi:"..cards[1]:getEffectiveId()..":->"..table.concat(targets,"+")
end


sgs.ai_card_intention["heg_fk_bushi"] = -50

sgs.ai_skill_cardask["@heg_fk_bushi-put"] = function(self, data, pattern, target, target2)
	if q(self,"isFriend",target) then
		local cards = AIList.new(q(self.player,"getCards","he"))
		sort_keep(self,cards)
		for _,c in ipairs(cards)do do 
			if q(self,"getKeepValue",c) > 6 then goto package_continue_8 end
			return "$"..q(c,"getEffectiveId")
		end ::package_continue_8:: end
		if q(self.player,"objectName") == q(target,"objectName") then
			return "$"..cards[1]:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_cardask["@heg_fk_midao-card"] = function(self, data, pattern, target, target2)
    local judge = owner_tag("judgeData"):toJudge()
    local ids = q(self.player,"getPile","heg_fk_rice")
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,disclosed(id))
    end
    if q(self,"needRetrial",judge) then
        local id = q(self,"getRetrialCardId",cards,judge)
        if id~=-1 then return "$"..id end
    end
    return "."    
end

sgs.ai_skill_invoke.heg_true_pozhen = function(self, data)
	local target = call(self.room,"getCurrent")
	if not target or not q(target,"isAlive") or not q(self,"isEnemy",target) then 
		return false 
	end
	
	
	local aliveCount = q(self.room,"alivePlayerCount")
	if aliveCount < 2 then
		return (q(target,"getHandcardNum") > 3 and not q(self,"willSkipPlayPhase",target)) or q(self,"isWeak")
	end
	
	local x = 0
	
	
	if aliveCount >= 3 and IsEncircled and type(IsEncircled) == "function" then
		local success, isEncircled = pcall(IsEncircled, target)
		if success and isEncircled then
			local success2, encirclers = pcall(GetEncirclers, target)
			if success2 and encirclers and type(encirclers) == "table" and #encirclers > 0 and #encirclers <= aliveCount then
				local processed = {}
				for _, q in ipairs(encirclers) do
					if q and q(q,"isAlive") and not processed[q(q,"objectName")] then
						processed[q(q,"objectName")] = true
						if q(self,"doDisCard",q, "he") then
							x = x + 1
						end
					end
				end
			end
		end
	end
	
	
	if aliveCount >= 2 and IsInQueue and type(IsInQueue) == "function" then
		local success, inQueue = pcall(IsInQueue, target)
		if success and inQueue then
			local success2, queuers = pcall(GetQueueMembers, target)
			if success2 and queuers and type(queuers) == "table" and #queuers > 0 and #queuers <= aliveCount then
				local processed = {}
				for _, q in ipairs(queuers) do
					if q and q(q,"isAlive") and not processed[q(q,"objectName")] then
						processed[q(q,"objectName")] = true
						if q(self,"doDisCard",q, "he") then
							x = x + 1
						end
					end
				end
			end
		end
	end
	
	return (((x >= 2) or (q(target,"getHandcardNum") > 3)) and not q(self,"willSkipPlayPhase",target)) or q(self,"isWeak")
end

sgs.ai_choicemade_filter.skillInvoke.heg_true_pozhen = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrent")
		if target then call(self,"updateIntention",player,target,80) end
	end
end

sgs.ai_skill_invoke.heg_true_jiancai_change = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_skill_invoke.heg_true_jiancai = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(self,"isFriend",damage.to) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_true_jiancai = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrentDyingPlayer")
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

sgs.ai_skill_invoke.DragonPhoenix = function(self, data)
	local target = q(data,"toPlayer")
	if call(self.room,"getCurrentDyingPlayer") and call(self.room,"getCurrentDyingPlayer"):objectName() == q(target,"objectName") then
		return q(self,"doDisCard",target, "he", true)
	end
	if target then
		return q(self,"doDisCard",target, "he")
	end
	return false
end

sgs.ai_view_as.heg_lord_shouyue_wusheng = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") and q(player,"getKingdom") == "shu" then
		local skill_name = ""
		for _,sk in sgs.list(q(player,"getVisibleSkillList"))do do 
			if q(sk,"isAttachedLordSkill") then goto package_continue_9 end
			if string.find(q(sk,"objectName"), "wusheng") then
				skill_name = q(sk,"objectName")
				break
			end
		end ::package_continue_9:: end
		if skill_name== "" then return nil end
		local can_invoke = false
		for _, p in sgs.qlist(q(player,"getAliveSiblings")) do
			if q(p,"hasSkill","heg_lord_shouyue") then
				can_invoke = true
				break
			end
		end
		if not can_invoke then return nil end
		return ("slash:%s[%s:%s]=%d"):format(skill_name, suit,number,card_id)
	end
end

sgs.ai_fill_skill.heg_lord_shouyue_wusheng = function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	cards = sort_use(self,cards,true)
	if q(self.player,"getKingdom") ~= "shu" then return nil end
	local skill_name = ""
	for _,sk in sgs.list(q(self.player,"getVisibleSkillList"))do do 
		if q(sk,"isAttachedLordSkill") then goto package_continue_10 end
		if string.find(q(sk,"objectName"), "wusheng") then
			skill_name = q(sk,"objectName")
			break
		end
	end ::package_continue_10:: end
	if skill_name== "" then return nil end
	local can_invoke = false
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasSkill","heg_lord_shouyue") then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return nil end
	local use_card = {}
	local useAll = false
	sort_players(self,self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")<2 and not q(enemy,"hasArmorEffect","EightDiagram")
		and q(self.player,"distanceTo",enemy)<=q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	local disCrossbow = false
	if q(self,"getCardsNum","Slash")<2
	or q(self.player,"hasSkills","paoxiao|tenyearpaoxiao|olpaoxiao")
	then disCrossbow = true end
	sort_players(self,self.enemies,"defense")

	for _,card in ipairs(cards)do
		if (not source_helper("isCard","Peach",card,self.player) and not source_helper("isCard","ExNihilo",card,self.player) and not useAll)
		and (not source_helper("isCard","Crossbow",card,self.player) or disCrossbow)
		and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or printed(self,"slash"):getTargetModResidue()>0)
		then table.insert(use_card,card) end
	end

	for _,card in ipairs(use_card)do
		local slash = clone_source("slash")
		call(slash,"addSubcard",card)
		call(slash,"setSkillName",skill_name)
		if q(slash,"isAvailable",self.player)
		then return slash end
	end
end

sgs.ai_skill_invoke.heg_lord_jizhao = sgs.ai_skill_invoke.niepan

sgs.ai_canNiepan_skill.heg_lord_jizhao = function(player)
	return q(player,"getMark","heg_lord_jizhao_used") == 0
end

sgs.ai_ajustdamage_from.PeaceSpell = function(self, from, to, card, nature)
	if nature ~= "N" and not IgnoreArmor(from,to) then
		return -99
	end
end

sgs.ai_skill_invoke.heg_lord_hongfa = true

sgs.ai_cardsview["heg_lord_hongfa_Attach"] = function(self,class_name,player)
	if class_name=="Slash" then
		for _, p in sgs.qlist(q(self.room,"findPlayersBySkillName","heg_lord_hongfa")) do
			if q(p,"getPile","heg_lord_hongfa"):length() > 0 and q(p,"getKingdom") == q(player,"getKingdom") then
				for _,id in sgs.list(q(p,"getPile","heg_lord_hongfa"))do
					local c = clone_source()
					call(c,"setSkillName","heg_lord_hongfa")
					call(c,"addSubcard",id)
					return q(c,"getLegacyStringKey")
				end
			end
		end
		
	end
end

addAiSkills("heg_lord_hongfa_Attach").getTurnUseCard = function(self,inclusive,request)
	local dc = clone_source("slash", sgs.Card_NoSuit, 0)
	call(dc,"setSkillName","_heg_lord_hongfa")
	call(dc,"deleteLater")
	local dummy = call(self,"aiUseCard",dc)
	if dummy.card then
		for _, p in sgs.qlist(q(self.room,"findPlayersBySkillName","heg_lord_hongfa")) do
			if q(p,"getPile","heg_lord_hongfa"):length() > 0 and sgs.Slash_IsAvailable(self.player) and q(p,"getKingdom") == q(self.player,"getKingdom") then 
				local cards = AIList.new{}
				for _,id in sgs.list(q(p,"getPile","heg_lord_hongfa")) do
					call(cards,"append",disclosed(id))
				end
				cards = AIList.new(cards) 
				sort_keep(self,cards) 
				for _,h in sgs.list(cards)do
					call(dc,"addSubcard",h)
					if q(dc,"isAvailable",self.player) then
						local d = call(self,"aiUseCard",dc)
						if d.card then
							return dc
						end
					end
					call(dc,"clearSubcards")
					break
				end
			end
		end
	end
end

sgs.ai_fill_skill.heg_lord_wendao = function(self,inclusive,request)
	local to_get
	for _, id in sgs.qlist(q(self.room,"getDiscardPile")) do
		if disclosed(id):isKindOf("PeaceSpell") then
			to_get = disclosed(id)
			break
		end
	end
	if not to_get then
		for _, p in sgs.qlist(q(self.room,"getAllPlayers")) do
			for _, c in sgs.qlist(q(p,"getCards","ej")) do
				if q(c,"isKindOf","PeaceSpell") then
					to_get = c
					break
				end
			end
			if to_get then break end
		end
	end
	if not to_get then return nil end
	local use_card
    local cards = q(self.player,"getCards","h")
    cards = sort_use(self,cards,true) 
	if q(self.player,"hasSkill","heg_lord_hongfa") and q(self.player,"getPile","heg_lord_hongfa"):length() > 0 then
		for i,h in sgs.list(cards)do
			if q(h,"isKindOf","PeaceSpell") then
				use_card = h
				break
			end
		end
	end
	if not use_card then
		for i,h in sgs.list(cards)do
			if q(h,"isRed") then
				use_card = h
				break
			end
		end
	end
	if use_card then
		return parse_source("#heg_lord_wendao:"..q(use_card,"getEffectiveId")..":")
	end
end

sgs.ai_skill_use_func["#heg_lord_wendao"] = function(card,use,self,request)
	use.card = card
	call(use.to,"append",self.player)
end

sgs.ai_use_priority["heg_lord_wendao"] = 3

function sgs.ai_armor_value.heg_lord_hongfa(player, self, card)
    if card and q(card,"isKindOf","PeaceSpell") then return 4 end
end
function sgs.ai_armor_value.heg_lord_wendao(player, self, card)
    if card and q(card,"isKindOf","PeaceSpell") then return 4 end
end


sgs.ai_fill_skill.heg_lord_jiahe_Attach = function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = sort_use(self,cards,true)
	local use_card = nil
	for _,c in ipairs(cards)do
		if q(c,"isKindOf","EquipCard") then
			use_card = c
			break
		end
	end
	if use_card then
		return parse_source("#heg_lord_jiahe_Attach:"..q(use_card,"getEffectiveId")..":")
	end
	return nil
end

sgs.ai_skill_use_func["#heg_lord_jiahe_Attach"] = function(card,use,self,request)
	for _, p in sgs.qlist(q(self.room,"findPlayersBySkillName","heg_lord_jiahe")) do
		if q(self,"isFriend",p) then
			use.card = card
			if use.to then call(use.to,"append",p) end
			return
		end
	end
end

sgs.ai_use_priority["heg_lord_jiahe_Attach"] = sgs.ai_use_priority.ZhihengCard + 1

sgs.ai_skill_invoke.heg_lord_jiahe = true

sgs.ai_fill_skill.heg_zhiheng = function(self,inclusive,request)
	if q(self.player,"getMaxHp") < 1 or not q(self.player,"canDiscard",self.player, "he") then return end
	local card = active_source()
	call(card,"setSkillName","heg_zhiheng")
	return card
end

sgs.ai_skill_use_func.heg_zhiheng = function(card,use,self,request)
	local shared = parse_source("@ZhihengCard=.")
	local dummy_use = dummy()
	call(self,"useSkillCard",shared,dummy_use)
	if dummy_use.card then
		
		call(card,"clearSubcards")
		for _,id in sgs.list(q(dummy_use.card,"getSubcards")) do
			if q(card,"subcardsLength") >= q(self.player,"getMaxHp") then break end
			if q(self.player,"canDiscard",self.player, id) then call(card,"addSubcard",id) end
		end
		if q(card,"subcardsLength") > 0 then use.card = card end
	end
end

sgs.ai_use_priority["heg_zhiheng"] = sgs.ai_use_priority.ZhihengCard
sgs.ai_use_value.heg_zhiheng = sgs.ai_use_value.ZhihengCard
sgs.dynamic_value.benefit.heg_zhiheng = true

sgs.ai_fill_skill.heg_lord_lianzi = function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	cards = sort_use(self,cards,true)
	if #cards > 0 then
		return parse_source("#heg_lord_lianzi:"..cards[1]:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#heg_lord_lianzi"] = function(card,use,self,request)
	use.card = card
end
sgs.ai_use_priority["heg_lord_lianzi"] = sgs.ai_use_priority.ZhihengCard + 1


sgs.ai_skill_discard.heg_lord_jianan = function(self, discard_num, min_num, optional, include_equip)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
	local to_discard = {}
	if q(self.player,"hasSkills",sgs.bad_skills) or math.random() < 0.3 then
		for _,c in ipairs(cards) do
			if #to_discard < discard_num then
				table.insert(to_discard, q(c,"getEffectiveId"))
			end
		end
		if #to_discard < min_num then
			for _,c in ipairs(cards) do
				if not table.contains(to_discard, q(c,"getEffectiveId")) then
					table.insert(to_discard, q(c,"getEffectiveId"))
					if #to_discard >= min_num then break end
				end
			end
		end
	end
	return to_discard
end

sgs.ai_skill_choice.heg_lord_jianan = function(self,choices)
	choices = q(choices,"split","+")
	for _,choice in sgs.list(choices)do
		if string.find(sgs.bad_skills,choice) then
			return choice
		end
	end
	return choices[math.random(1,#choices)]
end


sgs.ai_fill_skill.heg_lord_huibian = function(self,inclusive,request)
    return parse_source("#heg_lord_huibian:.:")
end

sgs.ai_skill_use_func["#heg_lord_huibian"] = function(card,use,self,request)
    sort_players(self,self.friends_noself, "hp")
    local target1, target2
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"getHp") > 1 and q(self,"canDamage",friend,self.player, nil) and q(self,"canDraw",friend) and q(friend,"getKingdom") == "wei" then
            target1 = friend
            break
        end
    end
    if not target1 then
        for _, enemy in ipairs(self.enemies) do
            if q(enemy,"getHp") > 1 and q(self,"canDamage",enemy,self.player, nil) and q(enemy,"getKingdom") == "wei" then
                target1 = enemy
                break
            end
        end
    end
    if not target1 then return end
    for i = #self.friends_noself, 1, -1 do
        local friend = self.friends_noself[i]
        if q(friend,"isWounded") and q(friend,"objectName") ~= q(target1,"objectName") and q(friend,"getKingdom") == "wei" then
            target2 = friend
            break
        end
    end
    if target1 and target2 then
        use.card = parse_source("#heg_lord_huibian:.:")
        call(use.to,"append",target1)
        call(use.to,"append",target2)
        return
    end
end

function sgs.ai_armor_value.heg_lord_zongyu(player, self, card)
    if card and q(card,"isKindOf","SixDragons") then return 4 end
end

sgs.ai_skill_invoke.heg_lord_zongyu = true


sgs.ai_fill_skill.heg_jiaping_Attach = function(self,inclusive,request)
	if (q(self,"isWeak")) then
		return parse_source("#heg_jiaping_Attach:.:")
	end
end

sgs.ai_skill_use_func["#heg_jiaping_Attach"] = function(card,use,self,request)
	for _, p in sgs.qlist(q(self.room,"findPlayersBySkillName","heg_jiaping")) do
		if q(p,"getMark","heg_jiaping_lun") == 0 then
			use.card = card
			if use.to then call(use.to,"append",p) end
			return
		end
	end
end

sgs.ai_fill_skill.heg_guikuang = function(self,inclusive,request)
	return parse_source("#heg_guikuang:.:")
end

sgs.ai_skill_use_func["#heg_guikuang"] = function(card,use,self,request)
	sort_players(self,self.enemies,"handcard")
	local target
	local target2
	for _,enemy in sgs.list(self.enemies)do
		for _,enemy2 in sgs.list(self.enemies)do
			if q(enemy,"canPindian",enemy2) and q(enemy,"objectName")~=q(enemy2,"objectName") and q(enemy,"getKingdom") ~= q(enemy2,"getKingdom") and q(self,"canDamage",enemy,enemy2,nil) and q(self,"canDamage",enemy2,enemy,nil)
			then target = enemy target2 = enemy2 break end
		end
	end
	if target and target2 then
		use.card = parse_source("#heg_guikuang:.:")
		call(use.to,"append",target)
		call(use.to,"append",target2)
		return
	end
end

sgs.ai_card_intention["heg_guikuang"] = 50

sgs.ai_damage_reason_suppress_intention.heg_guikuang = true

sgs.ai_skill_invoke.heg_mobile_bushi = function(self, data)
	local target = q(data,"toPlayer")
	if target and not q(self,"isEnemy",target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_mobile_bushi = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrent")
		if target then call(self,"updateIntention",player,target,-60) end
	end
end

sgs.ai_skill_cardask["@heg_mobile_midao"] = function(self, data, pattern, target, target2)
	local judge = q(data,"toJudge")
	local ids = q(self.player,"getPile","heg_mobile_rice")
	local cards = {}
	for _,id in sgs.list(ids)do
		table.insert(cards,disclosed(id))
	end
	if q(self,"needRetrial",judge) then
		local id = q(self,"getRetrialCardId",cards,judge, false, true)
		if id~=-1 then return "$"..id end
	end
	return "."
end

sgs.ai_skill_invoke.heg_mobile_jiancai = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(self,"isFriend",damage.to) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_mobile_jiancai = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrentDyingPlayer")
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

sgs.ai_fill_skill.heg_mobile_paiyi = function(self,inclusive,request)
	if q(self.player,"getPile","heg_quanji_power"):length() > 1 then
		return parse_source("#heg_mobile_paiyi:"..q(self.player,"getPile","heg_quanji_power"):first()..":")
	end
end

sgs.ai_skill_use_func["#heg_mobile_paiyi"] = function(card,use,self,request)
	local target
	local targets = call(self,"findPlayerToDraw",true,2,true)
	for _,p in ipairs(targets)do
		if q(p,"getHandcardNum")<2 and q(p,"getHandcardNum")+2 <q(self.player,"getHandcardNum") and q(self,"isFriend",p) then
			target = p
		end
		if target then break end
	end
	if not target then
		if q(self.player,"getHandcardNum")<q(self.player,"getHp")+2 and q(self,"canDraw",self.player) then
			target = self.player
		end
	end
	
	if not target then
		sort_players(self,targets,"hp")
		targets = sgs.reverse(targets)
		for _,friend in ipairs(targets)do
			if q(friend,"getHandcardNum")+2>q(self.player,"getHandcardNum")
			and q(self,"needToLoseHp",friend,self.player,nil,true) and q(self,"isFriend",friend) then
				target = friend
			end
			if target then break end
		end
	end
	sort_players(self,self.enemies,"defense")
	if not target and 2 <= 2 then
		for _,enemy in ipairs(self.enemies)do
			if source_helper("hasManjuanEffect",enemy) 
			and q(self,"canDamage",enemy, self.player, nil)
			and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player)
			and not q(self,"needToLoseHp",enemy)
			and q(enemy,"getHandcardNum")>q(self.player,"getHandcardNum") 
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if q(self,"canDamage",enemy, self.player, nil)
				and not q(enemy,"hasSkills",sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player) and not q(self,"cantbeHurt",enemy)
				and not q(self,"needToLoseHp",enemy)
				and q(enemy,"getHandcardNum")+2>q(self.player,"getHandcardNum")
				and not source_helper("hasManjuanEffect",enemy) and ZishuEffect(enemy) <= 0
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = parse_source("#heg_mobile_paiyi:"..q(self.player,"getPile","heg_quanji_power"):first()..":")
		call(use.to,"append",target)
	end
end

source_use_registry["@@heg_mobile_keshou"] = function(self,prompt,method)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
	local damage = room_tag("heg_mobile_keshou"):toDamage()
	if q(self,"needToLoseHp",self.player,damage.from,damage.card) then
		return "."
	end
	local use_cards = {}
	for _,c in ipairs(cards)do
		if q(self,"getKeepValue",c) <= 6 then
			for _,c2 in ipairs(cards)do
				if c ~= c2 and q(c,"getColor") == q(c2,"getColor") then
					table.insert(use_cards,c2)
					table.insert(use_cards,c)
					break
				end
			end
			if #use_cards >= 2 then break end
		end
	end
	if #use_cards < 2 then return "." end
	local card_str = "#heg_keshou:"..use_cards[1]:getEffectiveId().."+"..use_cards[2]:getEffectiveId()..":"
	return card_str
end

sgs.ai_skill_invoke.heg_mobile_zhuwei = function(self, data)
	if q(data,"toCard") then
		return true
	end
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_mobile_zhuwei = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-30) end
	end
end

sgs.ai_skill_invoke.heg_mobile_yaowu = function(self, data)
	return q(self,"isWeak") or q(self,"getOverflow") > 0 or math.random() < 0.5
end

sgs.ai_skill_playerchosen.heg_mobile_tanfeng = function(self, targets)
	local target = call(self,"findPlayerToDiscard","hej",false,false,targets,"heg_mobile_tanfeng")[1]
	if target then
		return target
	end
	return nil
end

extra_alias{ id="ai_choicemade_filter.cardChosen.heg_mobile_tanfeng",registry="ai_choicemade_filter",path={"cardChosen","heg_mobile_tanfeng"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_invoke.heg_mobile_tanfeng = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isEnemy",target) then
		if q(self,"needToLoseHp",self.player,target,nil) and q(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, target) then
			return true
		end
	end
	if target and q(self,"isFriend",target) then
		if q(target,"getJudgingArea"):length() > 0 then
			return q(self,"needToLoseHp",self.player,target,nil) or not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, target) or not q(self,"isWeak")
		end
		return true
	end
	return false
end


sgs.ai_target_revises.heg_mobile_qianxun = function(to,card,self)
	if q(card,"isKindOf","TrickCard") and q(card,"isSingleTargetCard") and q(to,"objectName") ~= q(self.player,"objectName") and q(to,"getPile","heg_mobile_jie"):length() < 3
	then return true end
end

sgs.ai_fill_skill.heg_mobile_duoshi = function(self,inclusive,request)
	if q(self.player,"getPile","heg_mobile_jie"):length() >= 3 then
		local ids = q(self.player,"getPile","heg_mobile_jie")
		local cards = {}
		for _,id in sgs.list(ids)do
			table.insert(cards,disclosed(id))
			if #cards >= 3 then break end
		end
		if #cards == 3 then
			local duoshipatterns = { "fire_slash", "fire_attack", "heg_burning_camps"}
			for c, pn in sgs.list(RandomList(duoshipatterns)) do
				c = clone_source(pn)
				call(c,"clearSubcards")
				call(c,"setSkillName","heg_mobile_duoshi")
				for _,id in sgs.list(ids)do
					call(c,"addSubcard",id)
				end
				local dummy_use = call(self,"aiUseCard",c)
				if q(c,"isAvailable",self.player) and dummy_use.card and dummy_use.to then
					return c
				end
			end
		end
	end
	if q(self.room,"getTurnCount")<=1 and #self.friends_noself==0 and not q(self,"isWeak") and q(self,"getOverflow")<=0 then return end
	local cards = q(self,"addHandPile","h")
	cards = AIList.new(cards)

	local red_card
	if q(self.player,"getHandcardNum")<=2 then return end
	if q(self,"needBear") then return end
	sort_use(self,cards,true)

	for _,card in ipairs(cards)do
		if q(card,"isRed") then
			if not q(self,"willUse",self.player,card,false,false,true) and not q(card,"isKindOf","Peach") then
				red_card = card
				break
			end

		end
	end

	if red_card then
		local heg_await_exhausted = clone_source("heg_await_exhausted")
		call(heg_await_exhausted,"addSubcard",red_card)
		call(heg_await_exhausted,"setSkillName","heg_mobile_duoshi")
		if q(heg_await_exhausted,"isAvailable",self.player)
		then return heg_await_exhausted end
	end
end

sgs.ai_canliegong_skill.heg_mobile_liegong = function(self, from, to)
	return q(from,"getPhase") == sgs.Player_Play and (q(to,"getHandcardNum") >= q(from,"getHp") or q(to,"getHandcardNum") <= q(from,"getAttackRange"))
end

sgs.ai_ajustdamage_from.heg_mobile_liegong = function(self, from, to, card, nature)
	if card and q(card,"isKindOf","Slash") and (q(card,"hasFlag","heg_mobile_liegong"..q(to,"objectName")) or (q(to,"getHandcardNum") >= q(from,"getHp") and q(to,"getHandcardNum") <= q(from,"getAttackRange"))) then
		return 1
	end
end

sgs.ai_skill_invoke.heg_mobile_liegong = sgs.ai_skill_invoke.liegong

sgs.ai_skill_playerchosen.heg_mobile_shushen = function(self,targets)
	if #self.friends_noself==0 then return nil end
	return call(self,"findPlayerToDraw",false,1)
end
sgs.ai_playerchosen_intention.heg_mobile_shushen = -80


sgs.ai_skill_invoke.heg_mobile_suishi = function(self,data)
	local promptlist = q(data,"toString"):split(":")
	local effect = promptlist[1]
	local tianfeng = call(self.room,"findPlayerByObjectName",promptlist[2])
	if effect=="draw" then
		return tianfeng and q(self,"isFriend",tianfeng) and q(self,"canDraw",tianfeng)
	else
		return tianfeng and q(self,"isEnemy",tianfeng)
	end
	return false
end

sgs.ai_skill_choice.heg_mobile_suishi = function(self, choices, data)
	choices = q(choices,"split","+")
	if table.contains(choices, "discardhandcard") then
		if q(self,"doDisCard",self.player, "h") then
			return "discardhandcard"
		end
	end
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_invoke.heg_mobile_kuangfu = function(self, data)
	local target = q(data,"toPlayer")
	if target then
		return q(self,"doDisCard",target, "he", true)
	end
	return false
end

sgs.ai_skill_choice.heg_mobile_kuangfu = function(self, choices, data)
	return "obtain"
end

sgs.ai_skill_invoke.heg_ov_zhenxi = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isEnemy",target) then
		return true
	end
	return q(self,"doDisCard",target, "he")
end

sgs.ai_skill_choice.heg_ov_zhenxi = function(self, choices, data)
	choices = q(choices,"split","+")
	local target = q(data,"toPlayer")
	if target and q(self,"isEnemy",target) then
		if table.contains(choices, "use") then
			local acard = clone_source("indulgence", sgs.Card_NoSuitRed, 0)
			call(acard,"deleteLater")
			call(acard,"setSkillName","heg_ov_zhenxi")
			local bcard = clone_source("supply_shortage", sgs.Card_NoSuitRed, 0)
			call(bcard,"setSkillName","heg_ov_zhenxi")
			call(bcard,"deleteLater")
			local suits = {}
			if not q(self.player,"isProhibited",target, acard) and q(acard,"targetFilter",AIList.new{}, target, self.player) then
				table.insert(suits, "diamond")
			end
			if not q(self.player,"isProhibited",target, bcard) and q(bcard,"targetFilter",AIList.new{}, target, self.player) then
				table.insert(suits, "club")
			end
			if #suits > 0 then
				for _, c in sgs.qlist(q(self.player,"getCards","he")) do
					if table.contains(suits, q(c,"getSuitString")) and not q(c,"isKindOf","TrickCard") then
						return "use"
					end
				end
			end
		end
	end
	if table.contains(choices, "discard") and q(self,"doDisCard",target, "he") then
		return "discard"
	end
	return "cancel"
end

sgs.ai_skill_cardask["@heg_ov_zhenxi"] = function(self, data, pattern, target, target2)
	local target = q(data,"toPlayer")
	if target and q(self,"isEnemy",target) then
		local cards = q(self.player,"getCards","he")
		cards = AIList.new(cards)
		sort_keep(self,cards) 
		local acard = clone_source("indulgence", sgs.Card_NoSuitRed, 0)
		call(acard,"deleteLater")
		call(acard,"setSkillName","heg_ov_zhenxi")
		local bcard = clone_source("supply_shortage", sgs.Card_NoSuitRed, 0)
		call(bcard,"setSkillName","heg_ov_zhenxi")
		call(bcard,"deleteLater")
		for _,c in sgs.list(cards)do
			if match_pattern(pattern,self.player,c) then 
				if q(c,"getSuit") == sgs.Card_Diamond then
					local dummy_use = call(self,"aiUseCard",acard, dummy(true, 99, q(self.room,"getOtherPlayers",target)))
					if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"contains",target) then
						return q(c,"getEffectiveId") 
					end
				end
				if q(c,"getSuit") == sgs.Card_Club then
					local dummy_use = call(self,"aiUseCard",bcard, dummy(true, 99, q(self.room,"getOtherPlayers",target)))
					if dummy_use.card and dummy_use and dummy_use.to and q(dummy_use.to,"contains",target) then
						return q(c,"getEffectiveId") 
					end
				end
				
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_ov_jiansu = function(self, data)
	return math.random() < 0.6
end

source_use_registry["@@heg_ov_jiansu"] = function(self, prompt, method)
	for _, friend in ipairs(self.friends) do
		if q(friend,"getHp") <= 2 then
			local use_cards = {}
			for _, c in sgs.qlist(q(self.player,"getCards","h")) do
				if q(c,"hasTip","heg_ov_jiansu") and #use_cards < q(friend,"getHp") then
					table.insert(use_cards, q(c,"getEffectiveId"))
				end
			end
			if #use_cards == q(friend,"getHp") then
				return "#heg_ov_jiansu:"..table.concat(use_cards, "+")..":->"..q(friend,"objectName")
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_ov_zhuidu = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(self,"isEnemy",damage.to) then
		if q(self,"doDisCard",damage.to, "e") then
			return true
		end
		if not q(self,"cantDamageMore",self.player, damage.to) and q(self,"canDamage",damage.to, self.player, damage.card) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["@heg_ov_zhuidu-beishui"] = function(self, data, pattern, target, target2)
	local damage = q(data,"toDamage")
	if damage.to and q(self,"isEnemy",damage.to) then
		if q(self,"doDisCard",damage.to, "e") and not q(self,"cantDamageMore",self.player, damage.to) and q(self,"canDamage",damage.to, self.player, damage.card) then
			return true
		end
	end
	return "."
end

sgs.ai_skill_choice.heg_ov_zhuidu = function(self, choices, data)
	local damage = q(data,"toDamage")
	choices = q(choices,"split","+")
	if q(self,"doDisCard",self.player, "e") and table.contains(choices, "discard") then
		return "discard"
	end
	return "damage"
end

sgs.ai_canNiepan_skill.heg_ov_shigong = function(player)
	return q(player,"getGeneral2") and q(player,"getMark","@heg_ov_shigong") > 0
end

sgs.ai_skill_invoke.heg_ov_shigong = sgs.ai_skill_invoke.niepan
sgs.ai_skill_invoke.heg_ov_shigong_gain = function(self, data)
	local target = q(data,"toPlayer")
	for _,sk in sgs.list(q(self.player,"getVisibleSkillList"))do do 
		if q(sk,"isAttachedLordSkill") then goto package_continue_11 end
		if not string.find(sgs.bad_skills,choice) then
			return true
		end
	end ::package_continue_11:: end
	return false
end

sgs.ai_skill_choice.heg_ov_shigong = function(self,choices)
	choices = q(choices,"split","+")
	for _,choice in sgs.list(choices)do
		if q(self,"isValueSkill",choice,self.player,true) then
			return choice
		end
	end
	for _,choice in sgs.list(choices)do
		if q(self,"isValueSkill",choice,self.player) then
			return choice
		end
	end
	for _,choice in sgs.list(choices)do do 
		if string.find(sgs.bad_skills,choice) then goto package_continue_12 end
		return choice
	end ::package_continue_12:: end
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_playerchosen.heg_ov_hongyuan = function(self, targets)
	local target = call(self,"findPlayerToDraw",false,1,false)
	if target and q(self,"getOverflow") > 0 then
		return target
	end
	return nil
end

sgs.ai_playerchosen_intention.heg_ov_hongyuan = -50


local function CardIsHezong(card_or_id)
	local id = type(card_or_id) == "number" and card_or_id or q(card_or_id,"getId")
	if id < 0 then return false end
	local engine_card = source_printed(id)
	local current_card = disclosed(id)
	return (engine_card and q(engine_card,"isTransferable"))
		or (current_card and q(current_card,"hasFlag","heg_transfer_card")) or false
end

sgs.ai_fill_skill.heg_ov_hongyuan = function(self,inclusive,request)
	return parse_source("#heg_ov_hongyuan:.:")
end

sgs.ai_skill_use_func["#heg_ov_hongyuan"] = function(card,use,self,request)
	local card = parse_source("@TenyearRendeCard=.")
	local dummy_use = dummy()
	call(self,"useSkillCard",card,dummy_use)
	if dummy_use.card then 
		local use_cards = q(dummy_use.card,"getSubcards")
		for _,id in sgs.list(use_cards) do
			if not CardIsHezong(id) then
				use.card = parse_source("#heg_ov_hongyuan:"..id..":")
				return
			end
		end
	end
end
sgs.ai_use_priority.heg_ov_hongyuan = 1

sgs.ai_skill_invoke.heg_tenyear_dechao = function(self, data)
	local use = q(data,"toCardUse")
	if use.from and q(self,"doDisCard",use.from, "he") then
		return true
	end
	return false
end

extra_alias{ id="ai_choicemade_filter.cardChosen.heg_tenyear_dechao",registry="ai_choicemade_filter",path={"cardChosen","heg_tenyear_dechao"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_fill_skill.heg_tenyear_mingfa = function(self,inclusive,request)
	if #self.enemies > 0 then
		return parse_source("#heg_tenyear_mingfa:.:")
	end
end

sgs.ai_skill_use_func["#heg_tenyear_mingfa"] = function(card,use,self,request)
	local targets = call(self,"findPlayerToDamage",1,self.player,"N")
	if #targets > 0 then
		for _,p in ipairs(targets)do
			if q(p,"getHandcardNum") < q(self.player,"getHandcardNum") then
				use.card = card
				call(use.to,"append",p)
				return
			end
		end
	end
	local max = 0
	for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		if q(p,"getHandcardNum") > max then
			max = q(p,"getHandcardNum")
		end
	end
	for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		if q(p,"getHandcardNum") > q(self.player,"getHandcardNum") and q(p,"getHandcardNum") == max then
			use.card = card
			call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_skill_playerschosen.heg_tenyear_jianliang = function(self, targets, max, min)
	local selected = AIList.new{}
    local can_choose = AIList.new(targets)
    sort_players(self,can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if q(self,"isFriend",target) and q(self,"canDraw",target) then
			call(selected,"append",target)
			if q(selected,"length") >= max then break end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_tenyear_jianliang = function(self, from, prompt)
    local intention = -60
    local tolist = q(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = call(self.room,"findPlayerByObjectName",dest)
        call(self,"updateIntention",from, to, intention)
    end
end

sgs.ai_fill_skill.heg_tenyear_weimeng = function(self,inclusive,request)
	return parse_source("#heg_tenyear_weimeng:.:")
end

sgs.ai_skill_use_func["#heg_tenyear_weimeng"] = function(card,use,self,request)
	for _, friend in ipairs(self.friends_noself) do
		if q(self,"doDisCard",friend, "he", true) then
			use.card = card
			call(use.to,"append",friend)
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"doDisCard",enemy, "he", true) then
			use.card = card
			call(use.to,"append",enemy)
			return
		end
	end
end

sgs.ai_skill_invoke.heg_tenyear_weimeng = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_fill_skill.heg_tenyear_boyan = function(self,inclusive,request)
	return parse_source("#heg_tenyear_boyan:.:")
end

sgs.ai_skill_use_func["#heg_tenyear_boyan"] = function(card,use,self,request)
	if q(self.player,"getMark","heg_tenyear_boyan") <= 0 then
		call(self,"setPriorityValue","heg_tenyear_boyan",sgs.ai_use_priority.BoyanCard,"extra.heg_tenyear_boyan")
		local targets = call(self,"findPlayerToDraw",false,1,true)
		if #targets > 0 then
			for _,p in ipairs(targets)do
				if q(self,"isFriend",p) and q(p,"getHandcardNum") < q(p,"getMaxHp") then
					use.card = card
					call(use.to,"append",p)
					return
				end
			end
		end
	else
		call(self,"setPriorityValue","heg_tenyear_boyan",9,"extra.heg_tenyear_boyan")
		if #self.toUse > 0 then
			for _,c in sgs.list(sort_keep(self,q(self.player,"getHandcards")))do
				if table.contains(self.toUse,c) then
					local dummy_use = call(self,"aiUseCard",c, dummy())
					if dummy_use.card and dummy_use.to and q(dummy_use.to,"length") > 0 then
						for _,p in sgs.list(dummy_use.to)do
							if q(self,"isEnemy",p) and q(p,"getHandcardNum") > 0 then
								use.card = card
								call(use.to,"append",p)
								return
							end
						end
					end
				end
			end
		end
	end
end


sgs.ai_use_value["heg_tenyear_boyan"] = sgs.ai_use_value.BoyanCard
sgs.ai_use_priority["heg_tenyear_boyan"] = sgs.ai_use_priority.BoyanCard

sgs.ai_skill_invoke.heg_tenyear_boyan = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end


sgs.ai_skill_invoke.heg_tenyear_shejian = function(self, data)
	local use = q(data,"toCardUse")
	if use.from and q(self,"isEnemy",use.from) then
		if q(self,"doDisCard",use.from, "he") then
			return true
		end
		if q(self,"canDamage",use.from, self.player, nil) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.heg_tenyear_shejian = function(self, choices, data)
	local items q(choices,"split","+")
	local use = q(data,"toCardUse")
	local damage = getChoice(choices, "damage")
	local discard = getChoice(choices, "discard")
	if damage then
		if use.from and q(self,"canDamage",use.from, self.player, nil) then
			return damage
		end
	end
	return discard
end

sgs.ai_fill_skill.heg_tenyear_fenglue = function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	sort_keep(self,cards)
  	for _,c in sgs.list(cards)do
		if q(c,"getNumber")>9
		then
			return parse_source("#heg_tenyear_fenglue:.:")
		end
	end
end

sgs.ai_skill_use_func["#heg_tenyear_fenglue"] = function(card,use,self,request)
	sort_players(self,self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if q(self.player,"canPindian",ep)
		and q(ep,"getCardCount",true,true)>1
		and q(ep,"getCards","j"):length()<1
		then
			use.card = card
			call(use.to,"append",ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(self.player,"canPindian",ep)
		and q(ep,"getCardCount",true,true)>1
		then
			use.card = card
			call(use.to,"append",ep)
			return
		end
	end
	sort_players(self,self.friends_noself,"card",true)
	for _,ep in sgs.list(self.friends_noself)do
		if q(self.player,"canPindian",ep)
		and q(self,"doDisCard",ep,"ej")
		then
			use.card = card
			call(use.to,"append",ep)
			return
		end
	end
end

sgs.ai_use_value["heg_tenyear_fenglue"] = 9.4
sgs.ai_use_priority["heg_tenyear_fenglue"] = 4.8

sgs.ai_skill_invoke.heg_tenyear_fenglue = function(self, data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end



sgs.ai_skill_invoke.heg_tenyear_anyong = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(self,"isEnemy",damage.to) then
		if not q(self,"cantDamageMore",damage.from, damage.to) and q(self,"damageStruct",damage) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.heg_tenyear_anyong = function(self, choices, data)
	choices = q(choices,"split","+")
	local losehp = getChoice(choices, "losehp")
	local discard = getChoice(choices, "discard")
	local target = q(data,"toPlayer")
	if target and q(self,"isEnemy",target) and losehp then
		return losehp
	end
	if discard and q(self,"doDisCard",target, "h") then
		return discard
	end
	return "cancel"
end

sgs.ai_skill_invoke.heg_tenyear_zhuwei  = function(self, data)
	if q(data,"toCard") then
		return true
	end
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_tenyear_zhuwei = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-30) end
	end
end





function SmartAIView:useCardheg_known_both(card, use)
	sort_players(self,self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local extraTarget = q(card,"getTargetModExtra",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.enemies)do do 
		if isCurrent(use,ep) then goto package_continue_13 end
		if q(self.player,"canUse",card,ep)
		and q(self,"hasTrickEffective",card,ep,self.player) and #getKnownCards(ep,self.player) < q(ep,"getHandcardNum") then
	    	use.card = card
			call(use.to,"append",ep)
	    	if q(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_13:: end
end
sgs.ai_use_priority.heg_known_both = 9.1
sgs.ai_use_value.heg_known_both = 5.4
sgs.ai_keep_value.heg_known_both = 3.33
sgs.ai_nullification.heg_known_both = function(self, card, from, to, positive)
	if positive then
		if q(self,"isFriend",to) and not q(self,"isFriend",from) and q(self.player,"objectName") ~= q(from,"objectName") and (q(self,"getOverflow") > 0 and q(self,"getCardsNum","Nullification") > 1) then return true end
	else
		if q(self,"isEnemy",to) and (q(self,"getOverflow") > 0 and q(self,"getCardsNum","Nullification") > 1) then return true end
	end
	return
end


function SmartAIView:useCardheg_befriend_attacking(card, use)
	local friends = call(self,"findPlayerToDraw",false,1,true)
	sort_players(self,self.friends,nil,true)
	local extraTarget = q(card,"getTargetModExtra",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,fp in sgs.list(friends)do do 
		if isCurrent(use,fp) or q(use.to,"contains",fp) then goto package_continue_14 end
		if source_can_to(card,self.player,fp)
		and q(self,"canDraw",fp) and q(self,"hasTrickEffective",card,fp,self.player) then
	    	use.card = card
	    	call(use.to,"append",fp)
			if q(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_14:: end
	for _,fp in sgs.list(self.friends)do do 
		if isCurrent(use,fp) or q(use.to,"contains",fp) then goto package_continue_15 end
		if source_can_to(card,self.player,fp)
		and q(self,"canDraw",fp) and q(self,"hasTrickEffective",card,fp,self.player) then
	    	use.card = card
	    	call(use.to,"append",fp)
			if q(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_15:: end
end
sgs.ai_use_priority.heg_befriend_attacking = 9.28
sgs.ai_use_value.heg_befriend_attacking = 9
sgs.ai_keep_value.heg_befriend_attacking = 3.88
sgs.ai_card_intention.heg_befriend_attacking = function(self, card, from, tos)
	if #q(self,"getFriends",from) > 1 or tos[1]:isLord() then
		call(self,"updateIntentions",from, tos, -10)
	end
end
sgs.ai_nullification.heg_befriend_attacking = function(self, card, from, to, positive)
	if positive then
		if q(self,"isEnemy",to) and q(self,"isEnemy",from) then return true end
	else
		if q(self,"isFriend",to) and q(self,"isFriend",from) then return true end
	end
	return
end


function SmartAIView:useCardheg_await_exhausted(card, use)
	use.card = card
	if use.to then call(use.to,"append",self.player) end
	for _, player in ipairs(self.friends_noself) do
		if use.to and q(self,"canDraw",player) and not q(player,"isNude") and q(self,"hasTrickEffective",card,player,self.player) then
			call(use.to,"append",player)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if use.to and source_helper("hasManjuanEffect",enemy) and not q(enemy,"isNude") and q(self,"hasTrickEffective",card,enemy,self.player) then
			call(use.to,"append",enemy)
		end
	end
	return
end
sgs.ai_use_priority.heg_await_exhausted = 2.8
sgs.ai_use_value.heg_await_exhausted = 4
sgs.ai_keep_value.heg_await_exhausted = 1
sgs.ai_card_intention.heg_await_exhausted = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		local intention = source_helper("hasManjuanEffect",to) and 10 or -10
		call(self,"updateIntention",from, to, intention)
	end
end
sgs.ai_nullification.heg_await_exhausted = function(self, card, from, to, positive)
	if positive then
		if q(self,"isEnemy",to) then
			if source_helper("hasManjuanEffect",to) then return true end
			if q(to,"isWounded") and q(to,"hasArmorEffect","SilverLion") then return true end
			if q(self,"getOverflow") > 0 and q(self,"getCardsNum","Nullification") > 1 then return true end
		end
	else
		if q(self,"isFriend",to) then
			if q(self,"getOverflow") > 0 and q(self,"getCardsNum","Nullification") > 1 then return true end
			if q(to,"isWounded") and q(to,"hasArmorEffect","SilverLion") then return true end
		end
	end
	return
end

sgs.ai_skill_discard.heg_triblade_Skill = function(self, discard_num, min_num, optional, include_equip)
	local damage = room_tag("CurrentDamageStruct"):toDamage()
	local targets = AIList.new{}
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",damage.to)) do
		if q(damage.to,"distanceTo",p) == 1 then call(targets,"append",p) end
	end
	if q(targets,"isEmpty") then return {} end
	local id
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_keep(self,cards)
	for _, c in ipairs(cards) do
		if not q(self.player,"isCardLimited",c, sgs.Card_MethodDiscard) then id = q(c,"getEffectiveId") break end
	end
	if not id then return {} end
	for _, enemy in sgs.qlist(targets) do
		if q(self,"damageIsEffective",enemy, "N", self.player) and q(self,"canDamage",enemy, self.player) then
			self.heg_triblade_Skill_target = enemy
			return id
		end
	end
	for _, friend in sgs.qlist(targets) do
		if q(self,"damageIsEffective",friend, "N", self.player) and q(self,"canDamage",friend, self.player) then
			self.heg_triblade_Skill_target = friend
			return id
		end
	end
	return {}
end

sgs.ai_skill_playerchosen.heg_triblade_Skill = function(self, targets)
	if self.heg_triblade_Skill_target then
		return self.heg_triblade_Skill_target
	end
	return sgs.ai_skill_playerchosen.damage(self, targets)
end

sgs.weapon_range.heg_six_swords = 2

sgs.ai_fill_skill.heg_six_swords = function(self,inclusive,request)
	if #self.friends > 0 then
		return parse_source("#heg_six_swords:.:")
	end
end

sgs.ai_skill_use_func["#heg_six_swords_Skill"] = function(card,use,self,request)
	sort_players(self,self.friends,"defense")
	local invoke = false
	for _,friend in ipairs(self.friends)do
		if q(friend,"getMark","@heg_six_swords") == 0 then
			invoke = true
			break
		end
	end
	if invoke then
		use.card = card
		for _,friend in ipairs(self.friends)do
			call(use.to,"append",friend)
		end
		return
	end
end



function SmartAIView:useCardheg_threaten_emperor(card, use)
	if q(self.player,"getMark","heg_threaten_emperor_lun") > 0 then return end
	if not q(card,"isAvailable",self.player) then return end
	if q(self.player,"getHandcardNum") - 1 <= 0 then return end
	if not q(self,"hasTrickEffective",card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_value.heg_threaten_emperor = 8
sgs.ai_use_priority.heg_threaten_emperor = 0
sgs.ai_keep_value.heg_threaten_emperor = 3.2

sgs.ai_nullification.heg_threaten_emperor = function(self, card, from, to, positive)
	if positive then
		if q(self,"isEnemy",from) and not q(from,"isKongcheng") then return true end
	else
		if q(self,"isFriend",from) and not q(from,"isKongcheng") then return true end
	end
	return
end

sgs.ai_skill_cardask["@heg_threaten_emperor"] = function(self)
	if q(self.player,"isKongcheng") then return "." end
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_use(self,cards,true)
	if q(self.player,"getHandcardNum") > 0 then
		return true
	end
	return cards[1]:getEffectiveId()
end




function SmartAIView:useCardheg_burning_camps(card, use)
	if not q(card,"isAvailable",self.player) then return end

	local target = q(self.player,"getNextAlive")
	if q(self,"isFriend",target) then return end

	local players = AIList.new{}
	local queue = source_global(self,"GetQueueMembers",target)
	if #queue >= 2 then
		for _, member in ipairs(queue) do
			
			if q(member,"objectName") ~= q(target,"objectName") and not q(self.player,"isProhibited",member, card) then
				call(players,"append",member)
			end
		end
	end
	if q(players,"isEmpty") then return end
	local shouldUse
	for i = 0 , q(players,"length") - 1 do do 
		local player = call(self.room,"findPlayerByObjectName",q(players,"at",i):objectName())
		if not q(self,"hasTrickEffective",card, player, self.player) then
			goto package_continue_16
		end
		local damage = {damage=1,nature=sgs.DamageStruct_Normal,chain=false,transfer=false,by_user=true}
		damage.from = self.player
		damage.to = player
		damage.nature = sgs.DamageStruct_Fire
		damage.damage = 1
		if q(self,"damageStruct",damage) then
			if q(player,"isChained") and q(self,"isGoodChainTarget",player,"F",self.player,1) then
				shouldUse = true
			elseif q(self,"canDamage",player, self.player, card) then
				shouldUse = true
			else
				return
			end
		end
	end ::package_continue_16:: end
	if shouldUse then
		use.card = card
		call(use.to,"append",target)
	end
end

sgs.ai_nullification.heg_burning_camps = function(self,trick,from,to,positive,null_num)
	local targets = AIList.new{}
	local players = room_tag("UseHistory" .. q(trick,"getLegacyStringKey")):toCardUse().to
	for _, q in sgs.qlist(players) do
		call(targets,"append",q)
	end
	if positive then
		if q(from,"objectName") == q(self.player,"objectName") then return false end
		local chained = {}
		local dangerous
		if q(self,"damageIsEffective",to, sgs.DamageStruct_Fire) and q(to,"isChained") then
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",to)) do
				if not q(self,"isGoodChainTarget",to, p, sgs.DamageStruct_Fire) and q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) and q(self,"isFriend",p) then
					table.insert(chained, p)
					if q(self,"isWeak",p) then dangerous = true end
				end
			end
		end
		if q(self,"hasHeavyDamage",from,trick,to) and #chained > 0 then dangerous = true end
		local friends = {}
		if q(self,"isFriend",to) then
			for _, p in sgs.qlist(targets) do
				if q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) then
					table.insert(friends, p)
					if q(self,"isWeak",p) or q(self,"hasHeavyDamage",from,trick,p) then dangerous = true end
				end
			end
		end
		if #chained + #friends > 2 or dangerous then return true end
		if q(self,"isFriend",to) and q(self,"isEnemy",from) then return true end
	else
		if not q(self,"isFriend",from) then return false end
		local chained = {}
		local dangerous
		local enemies = {}
		local good
		if q(self,"damageIsEffective",to, sgs.DamageStruct_Fire) and q(to,"isChained") then
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",to)) do
				if not q(self,"isGoodChainTarget",to, p, sgs.DamageStruct_Fire) and q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) and q(self,"isFriend",p) then
					table.insert(chained, p)
					if q(self,"isWeak",p) then dangerous = true end
				end
				if not q(self,"isGoodChainTarget",to, p, sgs.DamageStruct_Fire) and q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) and q(self,"isEnemy",p) then
					table.insert(enemies, p)
					if q(self,"isWeak",p) then good = true end
				end
			end
		end
		if q(self,"hasHeavyDamage",from,trick,to) and #chained > 0 then dangerous = true end
		if q(self,"hasHeavyDamage",from,trick,to) and #enemies > 0 then good = true end
		local friends = {}
		if q(self,"isFriend",to) then
			for _, p in sgs.qlist(targets) do
				if q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) then
					table.insert(friends, p)
					if q(self,"isWeak",p) or q(self,"hasHeavyDamage",from,trick,p) then dangerous = true end
				end
			end
		end
		if q(self,"isEnemy",to) then
			for _, p in sgs.qlist(targets) do
				if q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) then
					if q(self,"isWeak",p) or q(self,"hasHeavyDamage",from,trick,p) then good = true end
				end
			end
		end
		if #chained + #friends > 2 or dangerous then return false end
		if q(self,"isFriend",from) and q(self,"isEnemy",to) then return true end
	end
	return
end

sgs.ai_use_value.heg_burning_camps = 7.1
sgs.ai_use_priority.heg_burning_camps = 4.7
sgs.ai_keep_value.heg_burning_camps = 3.38
sgs.ai_card_intention.heg_burning_camps = 120




function SmartAIView:useCardheg_fight_together(card, use)
	if not q(card,"isAvailable",self.player) then return end

	local bigs, smalls = {}, {}
	local isBig, isSmall = false, false
	for _, p in sgs.qlist(q(self.room,"getAllPlayers")) do
		if q(self,"hasTrickEffective",card, p, self.player) then
			if source_global(self,"IsBigKingdomPlayer",p) then
				if q(p,"objectName") == q(self.player,"objectName") then isBig = true end
				table.insert(bigs, p)
			else
				if not(q(p,"hasArmorEffect","IronArmor") and not q(p,"isChained")) then
					if q(p,"objectName") == q(self.player,"objectName") then isSmall = true end
					table.insert(smalls, p)
				end
			end
		end
	end

	local choices = {}
	if #bigs > 0 then table.insert(choices, "big") end
	if #bigs > 0 and #smalls > 0 then table.insert(choices, "small") end

	if #choices > 0 then
		local v_big, v_small = 0, 0
		if table.contains(choices, "big") then
			for _, p in ipairs(bigs) do
				if q(self,"isFriend",p) then
					if q(p,"isChained") then v_big = v_big + 1
					else v_big = v_big - 1 end
				elseif q(self,"isEnemy",p) then
					if q(p,"isChained") then
						v_big = v_big - 1
					else
						v_big = v_big + 1
					end
				else
					v_big = v_big + 0.5
				end
			end
		elseif table.contains(choices, "small") then
			for _, p in ipairs(smalls) do
				if q(self,"isFriend",p) then
					if q(p,"isChained") then v_small = v_small + 1
					else v_small = v_small - 1 end
				elseif q(self,"isEnemy",p) then
					if q(p,"isChained") then
						v_small = v_small - 1
					else
						v_small = v_small + 1
					end
				else
					v_small = v_small + 0.5
				end
			end
		end
		local win = math.max(v_small, v_big)
		if win > 1 then
			if win == v_big then
				use.card = card
				if use.to and #bigs > 0 then call(use.to,"append",bigs[1]) end
				return
			elseif win == v_small then
				use.card = card
				if use.to and #smalls > 0 then call(use.to,"append",smalls[1]) end
				return
			end
		end
	end

	if not q(self.player,"isCardLimited",card, sgs.Card_MethodRecast) then
		use.card = card
		return
	end
end


sgs.ai_nullification.heg_fight_together = function(self, card, from, to, positive)
	local targets = AIList.new{}
	local players = room_tag("UseHistory" .. q(card,"getLegacyStringKey")):toCardUse().to
	for _, q in sgs.qlist(players) do
		if q(q,"toPlayer"):objectName() ~= q(to,"objectName") and q(self,"isFriend",q, to) then
			call(targets,"append",q(q,"toPlayer"))
		end
	end
	local ed, no = 0, 0
	if positive then
		if q(to,"isChained") and not keep then
			local single = true
			if q(self,"isEnemy",to) then
				for _, p in sgs.qlist(targets) do
					if q(p,"isChained") then ed = ed + 1 else no = no + 1 end
				end
				if q(targets,"length") > 0 and ed > no then single = false end
				return true
			end
		else
			if q(self,"isFriend",to) then
				for _, p in sgs.qlist(targets) do
					if q(p,"hasArmorEffect","Vine") then
						return true
					end
				end
			end
		end
	else
		if q(self,"isFriend",to) and q(to,"isChained") then return true end
	end
	return
end

sgs.ai_use_value.heg_fight_together = 5.2
sgs.ai_use_priority.heg_fight_together = 8.9
sgs.ai_keep_value.heg_fight_together = 3.24




function SmartAIView:useCardheg_alliance_feast(card, use)
	if not q(card,"isAvailable",self.player) then return end
	local effect_kingdoms = {}

	for _, target in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if not q(self,"isFriend",target) and q(self,"hasTrickEffective",card, target, self.player)
			and not(table.contains(effect_kingdoms, q(target,"getKingdom"))) then
			table.insert(effect_kingdoms, q(target,"getKingdom"))
		end
	end
	if #effect_kingdoms == 0 then return end
	local max_v = 0
	local winner
	for _, kingdom in ipairs(effect_kingdoms) do
		local value = 0
		local their_num = 0
		local self_value = 0
		local enemy_value = 0
		for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(p,"getKingdom") == kingdom then
				their_num = their_num + 1
				if q(self,"isFriend",p) and q(self,"hasTrickEffective",card, p, self.player) then
					self_value = self_value + 0.5
					if q(p,"isChained") then self_value = self_value + 0.5 end
				elseif q(self,"isEnemy",p) and q(self,"hasTrickEffective",card, p, self.player) then
					enemy_value = enemy_value + 0.5
					if q(p,"isChained") then enemy_value = enemy_value + 0.5 end
				end
			end
		end
		if their_num > q(self.player,"getLostHp") then
			self_value = self_value + q(self.player,"getLostHp") * 1.5
			self_value = self_value + (their_num - q(self.player,"getLostHp"))*0.5
		else
			self_value = self_value + their_num * 1.5
		end
		if self_value >= 3 and enemy_value > 2.5 then
			enemy_value = enemy_value / 2
		end
		value = self_value - enemy_value
		if value > max_v then
			winner = kingdom
			max_v = value
		end
	end
	

	if winner then
		local target
		for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(p,"getKingdom") == winner and q(self,"hasTrickEffective",card, p, self.player) then
				target = p
				break
			end
		end
		if target then
			use.card = card
			if use.to then call(use.to,"append",target) end
			return
		end
	end
end

sgs.ai_use_value.heg_alliance_feast = 9.5
sgs.ai_use_priority.heg_alliance_feast = 8.8
sgs.ai_keep_value.heg_alliance_feast = 4.3

sgs.ai_nullification.heg_alliance_feast = function(self, card, from, to, positive)
	if not q(self,"isFriend",to) and not q(self,"isEnemy",to) then return end
	local targets = room_tag("UseHistory" .. q(card,"getLegacyStringKey")):toCardUse().to
	local targets_t = AIList.new(targets)
	table.removeOne(targets_t, from)

	local hegnull = call(self,"getCard","HegNullification")
	local null_num = q(self,"getCardsNum","Nullification")

	local from_value = 0
	if q(to,"objectName") == q(from,"objectName") then
		if q(targets,"length") -1 > q(from,"getLostHp") then
			from_value = from_value + q(from,"getLostHp") * 1.5
			from_value = from_value + (q(targets,"length") -1 - q(self.player,"getLostHp"))*0.5
		else
			from_value = from_value + (q(targets,"length") -1) * 1.5
		end
		if (q(self,"isFriend",to) and positive) or (q(self,"isEnemy",to) and not positive) then
			from_value = -from_value
		end
		if from_value < 0 then return end
	end

	local value = 0
	local target
	if hegnull then
		for _, p in ipairs(targets_t) do
			if q(self,"hasTrickEffective",card, p, from) then
				value = value + 0.5
				if q(p,"isChained") then value = value + 0.5 end
			end
		end
		if value > 2 then
			target = targets_t[1]
		end
	end
	if target and q(self,"isEnemy",target) then
		if q(to,"objectName") == q(from,"objectName") then
			if null_num > 1 and from_value >= 2.5 then
				return true
			else
				return
			end
		else
			if (q(self,"isFriend",to) and positive) or (q(self,"isEnemy",to) and not positive) then
				value = -value
			end
			if value > 2 + (keep and 1 or 0) then
				return true
			end
		end
	end
	if q(to,"objectName") == q(from,"objectName") and from_value >= 2.5 then
		return true
	end
end


sgs.ai_fill_skill.heg_transfer = function(self,inclusive,request)
	call(self,"setPriorityValue","heg_transfer",0.8,"extra.heg_transfer")
	self.yjzy_to = nil
	local use_cards = {}
	local cards = q(self.player,"getCards","h")
	cards = sort_keep(self,cards)
  	for _,c in sgs.list(cards)do
		if CardIsHezong(c) then
			local card,player = call(self,"getCardNeedPlayer",{c},false)
			if card and player and q(self,"canDraw",player, self.player) and q(player,"getKingdom") ~= q(self.player,"getKingdom") then
				self.yjzy_to = player
				table.insert(use_cards, q(c,"getEffectiveId"))
			end
			if #use_cards >= 3 then break end
		end
	end
  	for _,c in sgs.list(cards)do
		if CardIsHezong(c) then
			if not table.contains(use_cards, q(c,"getEffectiveId")) then
				for _, friend in ipairs(self.friends_noself) do
					if q(self,"canDraw",friend, self.player) and q(friend,"getKingdom") ~= q(self.player,"getKingdom") then
						self.yjzy_to = friend
						table.insert(use_cards, q(c,"getEffectiveId"))
						break
					end
				end
			end
			if #use_cards >= 3 then break end
		end
	end
	if #use_cards == 0 then return nil end
	return parse_source("#heg_transfer:"..table.concat(use_cards, "+")..":")
end

sgs.ai_skill_use_func["#heg_transfer"] = function(card,use,self,request)
	if self.yjzy_to then
		use.card = card
		call(use.to,"append",self.yjzy_to)
		return
	end
	for _, friend in ipairs(self.friends_noself) do
		if q(self,"canDraw",friend, self.player) and q(friend,"getKingdom") ~= q(self.player,"getKingdom") then
			use.card = card
			call(use.to,"append",friend)
			return
		end
	end
end

sgs.ai_use_value.heg_transfer = 5.4
sgs.ai_use_priority.heg_transfer = 0.5
sgs.dynamic_value.benefit.heg_transfer = true
sgs.ai_card_intention.heg_transfer = -40






-- Only effective source ai_skills providers become fills. Dormant aliases are
-- kept as audit rows, not activated as an invented replacement.
local effective_fill={["bf_nos_tiaodu"]=true,["bf_qice"]=true,["bf_xiongsuan"]=true,["bf_yongjin"]=true,["gd_zezhu"]=true,["guandu_shicai"]=true,["guandu_yuanlue"]=true,["heg_chengliu"]=true,["heg_duanliang"]=true,["heg_duanxie"]=true,["heg_duwu"]=true,["heg_fengying"]=true,["heg_guikuang"]=true,["heg_guishu"]=true,["heg_huaiyi"]=true,["heg_jianglue"]=true,["heg_jiaping_Attach"]=true,["heg_jinfa"]=true,["heg_jinghe"]=true,["heg_kurou"]=true,["heg_longdan"]=true,["heg_lord_hongfa_Attach"]=true,["heg_lord_huibian"]=true,["heg_lord_jiahe_Attach"]=true,["heg_lord_lianzi"]=true,["heg_lord_shouyue_wusheng"]=true,["heg_lord_wendao"]=true,["heg_mobile_duoshi"]=true,["heg_mobile_paiyi"]=true,["heg_nos_guishu"]=true,["heg_nos_huaiyi"]=true,["heg_ov_hongyuan"]=true,["heg_paiyi"]=true,["heg_pojing"]=true,["heg_qiangxi"]=true,["heg_qingyin"]=true,["heg_quanjin"]=true,["heg_ruilve_attach"]=true,["heg_sanchen"]=true,["heg_shunfu"]=true,["heg_six_swords"]=true,["heg_tenyear_boyan"]=true,["heg_tenyear_fenglue"]=true,["heg_tenyear_mingfa"]=true,["heg_tenyear_weimeng"]=true,["heg_transfer"]=true,["heg_weidi"]=true,["heg_xianqu"]=true,["heg_xiejian"]=true,["heg_xuanhuoAttach"]=true,["heg_yinsha"]=true,["heg_yinyangyu"]=true,["heg_zaoyun"]=true,["heg_zhiheng"]=true,["heg_zhuangrong"]=true,["twyj_huzhu"]=true,["twyj_qijia"]=true,["twyj_rangyi"]=true,["twyj_zhuchen"]=true}
for _,skill in ipairs(package_skills)do
 if effective_fill[skill.name]then sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
end
local state_fields={yinghun_po='player',yinghun_pochoice='scalar',yjzy_to='player',heg_gongxiu='scalar',heg_nos_daming='scalar',heg_triblade_Skill_target='player'}
local function restore_state(ai)
 local state=ai:getStrategyMemory('extra.policy_state');if type(state)~='table'then return end
 for key,kind in pairs(state_fields)do local v=state[key];if kind=='player'and v~=nil then v=ai.room:findPlayerByObjectName(v,true)end;ai[key]=v end
end
local function save_state(ai)
 local state={};for key,kind in pairs(state_fields)do local v=ai[key];if kind=='player'and v~=nil then v=q(v,'objectName')end
  if v~=nil and type(v)~='string'and type(v)~='number'and type(v)~='boolean'then ai_unsupported('nonprimitive source policy memory',key)end;state[key]=v
 end;ai:setStrategyMemory('extra.policy_state',state)
end
local function wrap(body,row)
 return function(...)
  local args=table.pack(...);local ai=row.self_index>0 and args[row.self_index]
  if not ai then for _,value in ipairs(args)do if type(value)=='table'then local room=rawget(value,'_room');if room and rawget(room,'_ai')then ai=rawget(room,'_ai');break end end end end
  local key=row.registry..'.'..table.concat(row.path,'.')
  local facts=ai and ai.world and AIHegemony.facts(ai.world)
  if row.original_override and facts and facts.enabled==true and known(facts.original_overrides_loaded,'Original effective overrides') then
   local prior=prior_extra_hooks[key]
   if type(prior)=='function'then return prior(table.unpack(args,1,args.n))end
   if prior~=nil then return prior end
   ai_unsupported('effective Original provider was not installed',key)
  end
  local previous_ai,previous_key,previous_request,previous_range=current_ai,current_key,current_request,range_pending
  current_ai=ai;current_key='extra:'..row.registry..'.'..table.concat(row.path,'.')
  current_request=row.registry=='ai_fill_skill'and args[3]or row.registry=='ai_skill_use_func'and args[4]or row.registry=='ai_skill_use'and args[5]or nil;range_pending=nil
  local outer=ai and previous_ai~=ai
  local result=table.pack(pcall(function()if outer then restore_state(ai)end;return body(table.unpack(args,1,args.n))end))
  if result[1]and row.registry=='ai_fill_skill'and (previews[result[2]]or constructed[result[2]])then
   local converted=table.pack(pcall(resolve_preview,result[2],true));if converted[1]then result[2]=converted[2]else result=converted end
  end
  if result[1]and row.registry=='ai_skill_use_func'then local use=args[2]
   if use and use.card and (previews[use.card]or constructed[use.card])then
    local converted=table.pack(pcall(resolve_preview,use.card,true));if converted[1]then use.card=converted[2]else result=converted end
   end
  end
  if outer then local saved=table.pack(pcall(save_state,ai));if not saved[1]then result=saved end end
  current_ai,current_key,current_request,range_pending=previous_ai,previous_key,previous_request,previous_range
  if not result[1]then error(result[2],0)end
  return table.unpack(result,2,result.n)
 end
end
local entries={{registry="ai_ajustdamage_from",path={"PeaceSpell"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_congjian"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_ejue"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_fengshih"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_mobile_liegong"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_suzhi"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_xinghuo"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_xiongnve"},self_index=1,original_override=false},
{registry="ai_ajustdamage_from",path={"heg_zhuosheng"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"&gd_xujiu"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"heg_congjian"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"heg_fengshih"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"heg_nos_yuanyu"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"heg_xiongnve"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"heg_yuanyu"},self_index=1,original_override=false},
{registry="ai_ajustdamage_to",path={"twyj_baimei"},self_index=1,original_override=false},
{registry="ai_armor_value",path={"heg_lord_hongfa"},self_index=2,original_override=false},
{registry="ai_armor_value",path={"heg_lord_wendao"},self_index=2,original_override=false},
{registry="ai_armor_value",path={"heg_lord_zongyu"},self_index=2,original_override=false},
{registry="ai_canNiepan_skill",path={"heg_lord_jizhao"},self_index=0,original_override=false},
{registry="ai_canNiepan_skill",path={"heg_ov_shigong"},self_index=0,original_override=false},
{registry="ai_can_damagehp",path={"heg_fudi"},self_index=1,original_override=false},
{registry="ai_can_damagehp",path={"heg_nos_quanji"},self_index=1,original_override=false},
{registry="ai_can_damagehp",path={"heg_quanji"},self_index=1,original_override=false},
{registry="ai_canliegong_skill",path={"heg_chujue"},self_index=1,original_override=false},
{registry="ai_canliegong_skill",path={"heg_mobile_liegong"},self_index=1,original_override=false},
{registry="ai_canliegong_skill",path={"heg_nos_xiaoni"},self_index=1,original_override=false},
{registry="ai_canliegong_skill",path={"heg_ol_liegong"},self_index=1,original_override=false},
{registry="ai_card_intention",path={"heg_await_exhausted"},self_index=1,original_override=false},
{registry="ai_card_intention",path={"heg_befriend_attacking"},self_index=1,original_override=false},
{registry="ai_card_intention",path={"heg_huyuan"},self_index=1,original_override=false},
{registry="ai_card_intention",path={"heg_yanxi"},self_index=1,original_override=false},
{registry="ai_card_intention",path={"twyj_huzhu"},self_index=1,original_override=false},
{registry="ai_card_priority",path={"guandu_shicai"},self_index=1,original_override=false},
{registry="ai_card_priority",path={"heg_guishu"},self_index=1,original_override=false},
{registry="ai_card_priority",path={"heg_longdan"},self_index=1,original_override=false},
{registry="ai_card_priority",path={"heg_nos_guishu"},self_index=1,original_override=false},
{registry="ai_cardneed",path={"heg_duanliang"},self_index=3,original_override=true},
{registry="ai_cardneed",path={"heg_shensu"},self_index=3,original_override=true},
{registry="ai_cardsview",path={"heg_lord_hongfa_Attach"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"cardResponded","@guandu_jieliang"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"cardResponded","@heg_zhulan"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillChoice","heg_lianpian"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillChoice","heg_nos_daming"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillChoice","yinghun_po"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","bf_sec_tiaodu"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","bf_third_tiaodu"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","bf_tiaodu"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","bf_yuejian"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","chenggong"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","guandu_fuyuan"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_chenglue"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_hengjiang"},self_index=1,original_override=true},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_huaiyuan"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_jujian"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_mobile_bushi"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_mobile_jiancai"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_mobile_zhuwei"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_qiao"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_tenyear_zhuwei"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_tongdu"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_true_jiancai"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_true_pozhen"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_yicheng"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","heg_zhuwei"},self_index=1,original_override=false},
{registry="ai_choicemade_filter",path={"skillInvoke","twyj_huzhu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"bf_nos_tiaodu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"bf_qice"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"bf_xiongsuan"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"bf_yongjin"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"gd_zezhu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"guandu_shicai"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"guandu_yuanlue"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_chengliu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_duanliang"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_duanxie"},self_index=1,original_override=true},
{registry="ai_fill_skill",path={"heg_duwu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_fengying"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_guikuang"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_guishu"},self_index=1,original_override=true},
{registry="ai_fill_skill",path={"heg_huaiyi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_jianglue"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_jiaping_Attach"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_jinfa"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_jinghe"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_kurou"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_longdan"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_lord_hongfa_Attach"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_lord_huibian"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_lord_jiahe_Attach"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_lord_lianzi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_lord_shouyue_wusheng"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_lord_wendao"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_mobile_duoshi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_mobile_paiyi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_nos_guishu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_nos_huaiyi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_ov_hongyuan"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_paiyi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_pojing"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_qiangxi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_qingyin"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_quanjin"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_ruilve_attach"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_sanchen"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_shunfu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_six_swords"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_tenyear_boyan"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_tenyear_fenglue"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_tenyear_mingfa"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_tenyear_weimeng"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_transfer"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_weidi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_xianqu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_xiejian"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_xuanhuoAttach"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_yinsha"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_yinyangyu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_zaoyun"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"heg_zhiheng"},self_index=1,original_override=true},
{registry="ai_fill_skill",path={"heg_zhuangrong"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"twyj_huzhu"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"twyj_qijia"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"twyj_rangyi"},self_index=1,original_override=false},
{registry="ai_fill_skill",path={"twyj_zhuchen"},self_index=1,original_override=false},
{registry="ai_getBestHp_skill",path={"heg_yinghun"},self_index=0,original_override=false},
{registry="ai_getBestHp_skill",path={"yinghun_po"},self_index=0,original_override=false},
{registry="ai_nullification",path={"heg_alliance_feast"},self_index=1,original_override=false},
{registry="ai_nullification",path={"heg_await_exhausted"},self_index=1,original_override=false},
{registry="ai_nullification",path={"heg_befriend_attacking"},self_index=1,original_override=false},
{registry="ai_nullification",path={"heg_burning_camps"},self_index=1,original_override=false},
{registry="ai_nullification",path={"heg_fight_together"},self_index=1,original_override=false},
{registry="ai_nullification",path={"heg_known_both"},self_index=1,original_override=false},
{registry="ai_nullification",path={"heg_threaten_emperor"},self_index=1,original_override=false},
{registry="ai_playerchosen_intention",path={"heg_nos_daming_slash"},self_index=1,original_override=false},
{registry="ai_playerchosen_intention",path={"yinghun_po"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_baolie"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_chengxi"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_fengying"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_gongxiu"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_gongzhi"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_jianglue"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_limeng"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_tenyear_jianliang"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_yingshi"},self_index=1,original_override=false},
{registry="ai_playerschosen_intention",path={"heg_zhuihuan"},self_index=1,original_override=false},
{registry="ai_skill_askforag",path={"bf_yongjin"},self_index=1,original_override=false},
{registry="ai_skill_askforag",path={"twyj_liancai"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@bf_nos_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@gd_zezhu-give"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@guandu_jieliang"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_ciwei"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_fengshih"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_fk_bushi-put"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_fk_midao-card"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_fudi-give"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_jieyue-give"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_jinfa"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_limeng"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_luoyi"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_midao-give"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_mobile_midao"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_nos_daming"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_ov_zhenxi"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_ov_zhuidu-beishui"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_threaten_emperor"},self_index=1,original_override=true},
{registry="ai_skill_cardask",path={"@heg_xijue-tenyeartuxi"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_xijue-xiaoguo"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_xishe"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_yingwei"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@heg_zhulan"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"@twyj_huzhu"},self_index=1,original_override=false},
{registry="ai_skill_cardask",path={"heg_chengshang"},self_index=1,original_override=false},
{registry="ai_skill_cardchosen",path={"heg_huaiyi"},self_index=1,original_override=true},
{registry="ai_skill_cardchosen",path={"heg_mouduan"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"bf_xiongsuan"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"do_command"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_duanqiu_ChooseKingdom"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_gongxiu"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_huaiyi"},self_index=1,original_override=true},
{registry="ai_skill_choice",path={"heg_lianpian"},self_index=1,original_override=true},
{registry="ai_skill_choice",path={"heg_liegong"},self_index=1,original_override=true},
{registry="ai_skill_choice",path={"heg_lixia"},self_index=1,original_override=true},
{registry="ai_skill_choice",path={"heg_lord_jianan"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_mobile_kuangfu"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_mobile_suishi"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_nos_daming"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_nos_huaiyi"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_nos_lixia"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_ov_shigong"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_ov_zhenxi"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_ov_zhuidu"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_pojing"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_tenyear_anyong"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_tenyear_shejian"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_yanxi"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_yinghun"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"heg_zhengbi"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"start_command_heg_jianglue"},self_index=1,original_override=false},
{registry="ai_skill_choice",path={"yinghun_po"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"bf_wanwei"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"command"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"heg_juejue"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"heg_lord_jianan"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"heg_neiji"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"heg_shilus"},self_index=1,original_override=false},
{registry="ai_skill_discard",path={"heg_triblade_Skill"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"ChangeGeneral"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"DragonPhoenix"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"bf_sec_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"bf_third_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"bf_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"bf_yuejian"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"chenggong"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"guandu_fuyuan"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_beiluan"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_buyi"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_chengliu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_chenglue"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_duannian"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_duanqiu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_gongxiu"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_gongzhi"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_hengjiang"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_huaiyuan"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_jianzhi"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_jinxian"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_juejue"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_jujian"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_jushou"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_liangfan"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_luanchang"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_bushi"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_jiancai"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_kuangfu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_suishi"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_tanfeng"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_yaowu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_mobile_zhuwei"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_nos_lixia"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_ol_liegong"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_ov_jiansu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_ov_shigong_gain"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_ov_zhenxi"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_ov_zhuidu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_pojing"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_qiance"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_qiao"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_qiuan"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_shejus"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_shiren"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_anyong"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_boyan"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_dechao"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_fenglue"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_shejian"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_weimeng"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tenyear_zhuwei"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_tongdu"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_true_jiancai"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_true_jiancai_change"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_true_pozhen"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_wenji"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_xiace"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_xiongnve"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"heg_xishe"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_yinyangyu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"heg_zhuwei"},self_index=1,original_override=true},
{registry="ai_skill_invoke",path={"twyj_huzhu"},self_index=1,original_override=false},
{registry="ai_skill_invoke",path={"twyj_liancai"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"bf_nos_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"bf_sec_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"bf_third_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"bf_tiaodu"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"bf_xuanlve"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"gd_zhanyanliangzhuwenchou"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"guandu_zhongjie"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_bushi"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_chenglue"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_chengshang"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_chengxi"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_congcha"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_huyuan"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_jieyue"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_lianpian"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_lianyou"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_longdan"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_longdan_recover"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_mobile_shushen"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_mobile_tanfeng"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_mouduan"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_neiji"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_nos_daming"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_nos_daming_slash"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_ov_hongyuan"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_tongling"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_triblade_Skill"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_wenji"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"heg_yidu"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_yinghun"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_yingshi"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_zhaoxin"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_zhefu"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_zhengbi"},self_index=1,original_override=false},
{registry="ai_skill_playerchosen",path={"heg_zhidao"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"shushen"},self_index=1,original_override=true},
{registry="ai_skill_playerchosen",path={"yinghun_po"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_baolie"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_chengxi"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_duoshi"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_fengying"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_gongxiu"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_gongzhi"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_guowu"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_huaiyi"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_jianglue"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_limeng"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_nos_huaiyi"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_tenyear_jianliang"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_xunjim"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_yingshi_target"},self_index=1,original_override=false},
{registry="ai_skill_playerschosen",path={"heg_zhuihuan"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@bf_yongjin!"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@command6!"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_chengliu"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_fk_bushi"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_huyuan"},self_index=1,original_override=true},
{registry="ai_skill_use",path={"@@heg_jiantong"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_keshou"},self_index=1,original_override=true},
{registry="ai_skill_use",path={"@@heg_mobile_keshou"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_ov_jiansu"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_pozhu"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_shensu1"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_shensu2"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_shensu3"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_tianxiang"},self_index=1,original_override=true},
{registry="ai_skill_use",path={"@@heg_yanxi"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@heg_zhengbi"},self_index=1,original_override=true},
{registry="ai_skill_use",path={"@@twyj_rangyi"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@@zhengbidiscard!"},self_index=1,original_override=false},
{registry="ai_skill_use",path={"@heg_mouduan"},self_index=1,original_override=false},
{registry="ai_skill_use_func",path={"#bf_nos_tiaodu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#bf_qice"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#bf_xiongsuan"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#bf_yongjin"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#gd_zezhu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#guandu_shicai"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#guandu_yuanlue"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_chengliu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_duanxie"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_duwu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_guikuang"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_huaiyi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_jianglue"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_jiaping_Attach"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_jinfa"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_jinghe"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_kurou"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_lord_huibian"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_lord_jiahe_Attach"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_lord_lianzi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_lord_wendao"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_mobile_paiyi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_nos_huaiyi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_ov_hongyuan"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_paiyi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_pojing"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_qiangxi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_qingyin"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_quanjin"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_ruilve"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_sanchen"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_shunfu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_six_swords_Skill"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_tenyear_boyan"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_tenyear_fenglue"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_tenyear_mingfa"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_tenyear_weimeng"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_transfer"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_weidi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_xianqu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_xiejian"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_xuanhuo"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_yinyangyu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_zaoyun"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#heg_zhuangrong"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#twyj_huzhu"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#twyj_qijia"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#twyj_rangyi"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"#twyj_zhuchen"},self_index=3,original_override=false},
{registry="ai_skill_use_func",path={"heg_zhiheng"},self_index=3,original_override=true},
{registry="ai_target_revises",path={"heg_kongcheng"},self_index=0,original_override=false},
{registry="ai_target_revises",path={"heg_mobile_qianxun"},self_index=3,original_override=false},
{registry="ai_use_revises",path={"heg_paoxiao"},self_index=1,original_override=false},
{registry="ai_use_revises",path={"heg_xiaoji"},self_index=1,original_override=false},
{registry="ai_view_as",path={"heg_guishu"},self_index=0,original_override=false},
{registry="ai_view_as",path={"heg_longdan"},self_index=0,original_override=true},
{registry="ai_view_as",path={"heg_lord_shouyue_wusheng"},self_index=0,original_override=false},
{registry="ai_view_as",path={"heg_nos_guishu"},self_index=0,original_override=false},
{registry="ai_view_as",path={"heg_xiace"},self_index=0,original_override=false},
{registry="ai_view_as",path={"heg_yimie_attach"},self_index=0,original_override=false},
{registry="SmartAI",path={"useCardTunliang"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardXujiu"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardYuanjun"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_alliance_feast"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_await_exhausted"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_befriend_attacking"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_burning_camps"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_fight_together"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_known_both"},self_index=1,original_override=false},
{registry="SmartAI",path={"useCardheg_threaten_emperor"},self_index=1,original_override=false}}
for _,row in ipairs(entries)do
 local t=row.registry=='SmartAI'and SmartAIView or row.registry=='ai_skill_use'and source_use_registry or sgs[row.registry]
 for i=1,#row.path-1 do t=t and t[row.path[i]]end
 local key=row.path[#row.path];local body=t and t[key]
 if type(body)=='function'then
  local wrapped=wrap(body,row)
  if row.registry=='ai_skill_use'then
   source_use_registry[key]=wrapped
   local previous=prior_extra_typed_uses[key]
   if previous then
    ai_skill_use[key]=function(self,prompt,request)
     local facts=AIHegemony.facts(self.world)
     if row.original_override and facts and facts.enabled==true and known(facts.original_overrides_loaded,'Original effective overrides') then return previous(self,prompt,request)end
     return wrapped(self,prompt,request and request.handling_method,request and request.pattern,request and AILegacyRequest.new(request,self.room))
    end
   else sgs.ai_skill_use[key]=wrapped end
  else t[key]=wrapped end
 end
end
sgs.ai_ajustdamage_from.heg_congjian=accepted_congjian_from
sgs.ai_ajustdamage_to.heg_congjian=accepted_congjian_to
