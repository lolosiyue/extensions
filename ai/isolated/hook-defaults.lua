-- Built-in category data and ordered value policies; no hook dispatch machinery.
local sgs = assert(rawget(_G, "sgs"), "strategy-hooks.lua must load first")

sgs.lose_equip_skill = sgs.lose_equip_skill or "kofxiaoji|xiaoji|xuanfeng|nosxuanfeng|tenyearxuanfeng|mobilexuanfeng"
sgs.need_kongcheng = sgs.need_kongcheng or "lianying|noslianying|kongcheng|sijian|hengzheng"
sgs.masochism_skill = sgs.masochism_skill or "guixin|yiji|fankui|jieming|xuehen|neoganglie|ganglie|vsganglie|enyuan|fangzhu|nosenyuan|langgu|quanji|zhiyu|renjie|tanlan|tongxin|huashen|duodao|chengxiang|benyu"
sgs.wizard_skill = sgs.wizard_skill or "nosguicai|guicai|guidao|olguidao|jilve|tiandu|luoying|noszhenlie|huanshi|jinshenpin"
sgs.wizard_harm_skill = sgs.wizard_harm_skill or "nosguicai|guicai|guidao|olguidao|jilve|jinshenpin|midao|zhenyi"
sgs.priority_skill = sgs.priority_skill or "dimeng|haoshi|qingnang|nosjizhi|jizhi|guzheng|qixi|jieyin|guose|duanliang|jujian|fanjian|neofanjian|lijian|noslijian|manjuan|tuxi|qiaobian|yongsi|zhiheng|luoshen|nosrende|rende|mingce|wansha|gongxin|jilve|anxu|qice|yinling|heg_qingcheng|houyuan|zhaoxin|shuangren|zhaxiang|xiansi|junxing|bifa|yanyu|shenxian|jgtianyun"
sgs.save_skill = sgs.save_skill or "jijiu|buyi|nosjiefan|chunlao|tenyearchunlao|secondtenyearchunlao|longhun|newlonghun"
sgs.exclusive_skill = sgs.exclusive_skill or "huilei|duanchang|wuhun|buqu|dushi"
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill or "yuce|tanlan|toudu|qiaobian|jieyuan|anxian|liuli|chongzhen|tianxiang|tenyeartianxiang|oltianxiang|guhuo|nosguhuo|olguhuo|leiji|nosleiji|olleiji|qingguo|yajiao|chouhai|tenyearchouhai|nosrenxin|taoluan|tenyeartaoluan|huisheng|zhendu|newzhendu|kongsheng|zhuandui|longhun|newlonghun|fanghun|olfanghun|mobilefanghun|zhenshan|jijiu|daigong|yinshicai"
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill or "paoxiao|tenyearpaoxiao|olpaoxiao|tianyi|xianzhen|shuangxiong|nosjizhi|jizhi|guose|duanliang|qixi|qingnang|luoyi|guhuo|nosguhuo|jieyin|zhiheng|rende|nosrende|nosjujian|luanji|qiaobian|lirang|mingce|fuhun|spzhenwei|nosfuhun|nosluoyi|yinbing|jieyue|sanyao|xinzhan"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill or "kanpo|guicai|guidao|beige|xiaoguo|liuli|tianxiang|jijiu|leiji|nosleijiqingjian|zhuhai|qinxue|jspdanqi|" .. sgs.dont_kongcheng_skill
sgs.cardneed_skill = sgs.cardneed_skill or sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill
sgs.need_equip_skill = sgs.need_equip_skill or "shensu|tenyearshensu|mingce|jujian|beige|yuanhu|huyuan|gongqi|nosgongqi|yanzheng|heg_qingcheng|neoluoyi|longhun|newlonghun|shuijian|yinbing"
sgs.double_slash_skill = sgs.double_slash_skill or "paoxiao|tenyearpaoxiao|olpaoxiao|fuhun|tianyi|xianzhen|zhaxiang|lihuo|jiangchi|shuangxiong|qiangwu|luanji"


-- Common initialized categories are available before any package loader.
for index, name in ipairs({"All", "Draw", "Male", "Female", "Wounded", "MaleWounded", "FemaleWounded", "Weak"}) do
    local key = "Friend_" .. name
    if sgs[key] == nil then sgs[key] = index - 1 end
end
sgs.drawpeach_skill = sgs.drawpeach_skill or "tuxi|qiaobian"
sgs.recover_hp_skill = sgs.recover_hp_skill or "nosrende|rende|tenyearrende|kofkuanggu|kuanggu|tenyearkuanggu|zaiqi|mobilezaiqi|jieyin|"..
						"qingnang|shenzhi|longhun|newlonghun|ytchengxiang|quji|dev_zhiyu|dev_pinghe|dev_qiliao|dev_saodong"
sgs.recover_skill = sgs.recover_skill or "yinghun|hunzi|nosmiji|noszishou|zishou|olzishou|tenyearzishou|ganlu|xueji|shangshi|nosshangshi|"..
						"buqu|miji|"..sgs.recover_hp_skill
sgs.use_lion_skill = sgs.use_lion_skill or "longhun|newlonghun|duanliang|qixi|guidao|noslijian|lijian|jujian|nosjujian|zhiheng|mingce|"..
						"yongsi|fenxun|gongqi|yinling|jilve|heg_qingcheng|neoluoyi|diyyicong"
sgs.straight_damage_skill = sgs.straight_damage_skill or "qiangxi|nosxuanfeng|duwu|danshou"
sgs.need_maxhp_skill = sgs.need_maxhp_skill or "yingzi|zaiqi|yinghun|hunzi|juejing|ganlu|noszishou|miji|chizhong|xueji|quji|xuehen|shude|"..
						"neojushou|tannang|fangzhu|nosshangshi|nosmiji|yisuan|xuhe"
sgs.hit_skill = sgs.hit_skill or "wushuang|fuqi|tenyearfuqi|zhuandui|tieji|nostieji|dahe|olqianxi|qianxi|tenyearjianchu|oljianchu|"..
					"wenji|tenyearbenxi|mobileliyong|olwushen|tenyearliegong|liegong|kofliegong|tenyearqingxi|wanglie|"..
					"conqueror|zhaxiang|tenyearyijue|yijue|xiongluan|xiying|"
sgs.turnOverSkillsList = sgs.turnOverSkillsList or {
		"jushou", "nosjushou", "neojushou", "super_jushou",
		"fangzhu", "mobilefangzhu", "mobilemoufangzhu", "jilve_mobilefangzhu",
		"jiushi", "mobilejiushi", "qljiushi", "oljiushi",
		"junxing", "mobilejunxing",
		"olxingwu", "lulve", "caiyi", "daili", "shisuan", "jiusi",
		"mobilexincunsi", "mobilexinguixiu",
		"mobilemoushensu", "mobileshensu",
		"guixin", "newguixin", "shenfen", "szfscliu",
		"olshebian", "olrenxin", "nosrenxin",
		"olfuli", "mobilefuli", "mobilebeige",
		"biejun", "pojun", "cangni",
		"jghuodi", "jgdidong", "jgdixian", "jglingyu", "bossdidong", "boss_xushi",
		"mobilemouqiaomeng", "fuji", "zhanlie"
	}

for _, key in ipairs({"damage_card", "control_usecard", "control_card", "lucky_chance", "benefit"}) do
    if type(sgs.dynamic_value[key]) ~= "table" then sgs.dynamic_value[key] = {} end
end

-- Printed standard card natures are definition values; damage hooks still
-- decide their strategic adjustments and never turn this table into a rule engine.
for _, entry in ipairs({{"Slash", "Normal"}, {"Duel", "Normal"},
    {"SavageAssault", "Normal"}, {"ArcheryAttack", "Normal"},
    {"FireSlash", "Fire"}, {"FireAttack", "Fire"}, {"ThunderSlash", "Thunder"},
    {"Lightning", "Thunder"}, {"IceSlash", "Ice"}}) do
    if sgs.card_damage_nature[entry[1]] == nil then
        sgs.card_damage_nature[entry[1]] = sgs["DamageStruct_" .. entry[2]]
    end
end

return sgs
