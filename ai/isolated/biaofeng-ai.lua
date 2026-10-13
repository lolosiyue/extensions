-- Fixed biaofeng-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local source_uses={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("biaofeng policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("biaofeng policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function pq(object,method,...)
    local values=table.pack(call(object,method,...))
    local value=values[1]
    if value==false and (method=="hasSkill"or method=="hasSkills"or method=="hasLordSkill")and AIValue.isPlayer(object)then
        local row=rawget(object,"_view")
        if row and row.skills_complete~=true then ai_unsupported("foreign skill absence is unknown",(...))end
    end
    known(value,method);return table.unpack(values,1,values.n)
end
local function sorted(self,cards,method,...)
    local result=pq(self,method,cards,...)
    for i,c in ipairs(result) do cards[i]=c end
    return cards
end
local function sort_players(self,cards,...) return sorted(self,cards,"sort",...) end
local function sort_use(self,cards,...) return sorted(self,cards,"sortByUseValue",...) end
local function sort_keep(self,cards,...) return sorted(self,cards,"sortByKeepValue",...) end
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return pq(self,"legacySkillSeed",skill,class,action_request(self,request)) end
local skill_cards={["#PlusChenggui"]="PlusChenggui",["#PlusCuorui_DummyCard"]="PlusCuorui",["#PlusDuocheng_Card"]="PlusDuocheng",["#PlusFanjian_Card"]="PlusFanjian",["#PlusFuzheng_Card"]="PlusFuzheng",["#PlusGuicai_Card"]="PlusGuicai",["#PlusGuicai_DummyCard"]="PlusGuicai",["#PlusGuidao_Card"]="PlusGuidao",["#PlusHuangtian_Card"]="PlusHuangtianQun",["#PlusJiahuo_Card"]="PlusJiahuo",["#PlusJiangcai_Card"]="PlusJiangcai",["#PlusJianxiong_Card"]="PlusJianxiong",["#PlusJieyin_Card"]="PlusJieyin",["#PlusKuangjun_Card"]="PlusKuangjun",["#PlusKurou_Card"]="PlusKurou",["#PlusLeiji_Card"]="PlusLeiji",["#PlusLiangyuan_Card"]="PlusLiangyuan",["#PlusLiuli_Card"]="PlusLiuli",["#PlusLuoyi_select"]="PlusLuoyi",["#PlusMizhao_Card"]="PlusMizhao",["#PlusPaoxiao_Card"]="PlusPaoxiao",["#PlusQimou_Card"]="PlusQimou",["#PlusRende_Card"]="PlusRende",["#PlusShensu_Card"]="PlusShensu",["#PlusTianxiang_Card"]="PlusTianxiang",["#PlusXuanhu_Card"]="PlusXuanhu",["#PlusYiji_Card"]="PlusYiji",["#PlusYizhong_Card"]="PlusYizhong",["#PlusYuanmou_Card"]="PlusYuanmou",["#PlusZenhui_Card"]="PlusZenhui",["#PlusZhaxiang_Card"]="PlusZhaxiang",["#PlusZhiguo_Card"]="PlusZhiguo",["#PlusZhiheng_Card"]="PlusZhiheng",["#PlusZhiren_Card"]="PlusZhiren",["#PlusZhongyong_Card"]="PlusZhongyong",["#SevenChuanJiao"]="SevenChuanJiao",["#SevenFenLiang"]="SevenFenLiang",["#SevenFengPing"]="SevenFengPing",["#SevenJiujiaCard"]="SevenJiujia",["#SevenJuDi"]="SevenJuDi",["#SevenKanLuan"]="SevenKanLuan",["#SevenLuanZheng"]="SevenLuanZheng",["#SevenWeiYuan"]="SevenWeiYuan",["#SevenYingYong"]="SevenYingYong",["#SevenZhaoXiang"]="SevenZhaoXiang",["#SevenZhengBian"]="SevenZhengBian",["#SixChouyuanCard"]="SixChouyuan",["#SixChouzuanCard"]="SixChouzuan",["#SixChunlaoCard"]="SixChunlao",["#SixChunlaoWineCard"]="SixChunlao",["#SixGuicaiCard"]="SixGuicai",["#SixGuicaiDummyCard"]="SixGuicai",["#SixLongdanCard"]="SixLongdan",["#SixMiBian"]="SixMiBian",["#SixMingduanCard"]="SixMingduan",["#SixPaoxiaoCard"]="SixPaoxiao",["#SixRendeCard"]="SixRende",["#SixSanceCard"]="SixSance",["#SixTaichenCard"]="SixTaichen",["#SixTaohuiCard"]="SixTaohui",["#SixWuzhiCard"]="SixWuzhi",["#SixZhidiCard"]="SixZhidi"}
local function disclosed(self,id)
 if type(id)=='string'and id:match('^%d+$')then id=tonumber(id)end
 local card=self:getKnownCardById(id)or self:getChoiceCard(id)
 if card then return card end
 local preview=self:getDecisionContext().retrial_preview
 if type(preview)=='table'and preview.known==true and preview.skill=='PlusYiji'then
  local admitted=false;for _,value in ipairs(preview.ids or{})do if value==id then admitted=true end end
  if admitted then for _,face in ipairs(preview.cards or{})do if face.effective_id==id then return known(CardView.new(face),'biaofeng private preview card')end end end
 end
 return known(nil,'biaofeng disclosed card '..tostring(id))
end
local function ids(cards)local out={};for _,c in ipairs(cards)do out[#out+1]=type(c)=='number'and c or pq(c,'getEffectiveId')end;return out end
local function spec(self,skill,name,costs)
 local suit,number=sgs.Card_NoSuit,0;local red,black=true,true
 for _,id in ipairs(costs)do local c=disclosed(self,id);red=red and pq(c,'isRed');black=black and pq(c,'isBlack')end
 if #costs==1 then local c=disclosed(self,costs[1]);suit,number=pq(c,'getSuit'),pq(c,'getNumber')elseif #costs>1 then suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 return{name=name,skill=skill,suit=suit,number=number,subcards=costs}
end
local function turn_normal(self,skill,name,costs,request)
 local value=spec(self,skill,name,costs)
 return pq(self,'evaluateTurnConversion',skill,pq(pq(self,'getEvaluationCard',name),'getClassName'),value,action_request(self,request))
end
local function owner_normal(self,skill,name,costs,output_skill)
 local value=spec(self,output_skill or skill,name,costs);value.source_key=skill
 return pq(self,'evaluateOwnerViewAsCard',value)
end
local function owner_clone(self,source,name,suit,number)
 return pq(self,'evaluateOwnerViewAsCard',{source_key=source,skill='',name=name,suit=suit,number=number,subcards={}})
end
local function wire_parts(wire)
 local class,raw,user=wire:match('^(#[^:]+):([^:]*):(.*)$');if not class then return end
 local costs={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id)end
 return class,costs,user~=''and user or nil
end
local function normal_parts(wire)
 local name,skill,raw=wire:match('^([^:]+):([^%[]*)%[[^%]]+%]=(.*)$');if not name then ai_unsupported('unrecognized source card grammar',wire)end
 name=({Collateral='collateral',ArcheryAttack='archery_attack',SavageAssault='savage_assault'})[name]or name
 local costs={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id)end;return name,skill,costs
end
local function parse(self,request,wire)
 local class,costs,user=wire_parts(wire)
 if class then local skill=known(skill_cards[class],class)
  if #costs==0 and user==nil then return seed(self,skill,class,request)end
  return pq(self,'evaluateTurnSkillCard',skill,class,costs,action_request(self,request),user)
 end
 local name,skill,material=normal_parts(wire);return turn_normal(self,skill,name,material,request)
end
local function final_parse(self,request,wire)
 local class,costs,user=wire_parts(wire)
 if class then return pq(self,'bindSkillCard',known(skill_cards[class],class),costs,action_request(self,request),user,class)end
 local name,skill,material=normal_parts(wire)
 return pq(self,'bindOriginalSelectedConversion',spec(self,skill,name,material),pq(pq(self,'getEvaluationCard',name),'getClassName'),skill,false)
end
local function property_card(self,skill,wire)local name,_,costs=normal_parts(wire);return owner_normal(self,skill,name,costs)end
local function dummy(value,extra)local use=AIUsePlan.new();use.isDummy=value~=false;use.extra_target=extra or 0;return use end
local function sort_priority(self,cards,...)return sorted(self,cards,'sortByUsePriority',...)end
local function role(self,p)local v=call(p,'getRole');if v~=nil then return v end;return pq(self,'useKnowledgeEstimate',{status='estimate',value=pq(self,'getRoleEstimate',p),basis='viewer_role_estimate_private_role',player=pq(p,'objectName')},'biaofeng.role')end
local function role_count(self,key)return known(known(self.world.mode_policy,'mode policy').role_counts,'role counts')[key]or ai_unsupported('role count unknown',key)end
local function scoped_flag(self,player,name)
 local rows=pq(self,'getDecisionContext').biaofeng_flags
 local value=type(rows)=='table'and rows[pq(player,'objectName')]
 value=type(value)=='table'and value[name]
 if type(value)=='boolean'then return value end
 return pq(player,'hasFlag',name)
end
local function yizhong_mark(self,player)
 local rows=pq(self,'getDecisionContext').biaofeng_yizhong_marks
 local value=type(rows)=='table'and rows[pq(player,'objectName')]
 if type(value)=='number'then return value end
 return pq(player,'getMark','PlusYizhong')
end
local function owner_fact(self,key)
 if key=='jilve_wansha'then
  -- The viewer's own JilveWansha tag read through toBool(); absent is false.
  local v=self.player:getTag('JilveWansha');if v==nil then return false end
  if type(v)~='boolean'then ai_unsupported('JilveWansha tag is not a boolean',key)end;return v
 end
 if key=='six_wulve_card'then return known(pq(self,'getDecisionContext').biaofeng_six_wulve_card,key)end
 ai_unsupported('biaofeng fact is not projected',key)
end
local function find(self,name)if type(name)=='table'then return name end;if name==nil or name==false or name==''then return nil end;return known(self.room:findPlayerByObjectName(name,true),'biaofeng player '..tostring(name))end
local function remember_player(self,key,p)self:setStrategyMemory('biaofeng.'..key,p and pq(p,'objectName')or false)end
local function recall_player(self,key)return find(self,self:getStrategyMemory('biaofeng.'..key))end
local function get_jiujia(self)return find(self,self:getStrategyMemory('response_source:SevenJiujia'))end
local function set_jiujia(self,p)return self:setStrategyMemory('response_source:SevenJiujia',p and pq(p,'objectName')or false)end
local function rehydrate(self,row,kind)
 if type(row)~='table'then ai_unsupported('current tagged struct absent',kind)end
 local v={};for k,x in pairs(row)do v[k]=x end
 for _,k in ipairs({'from','who'})do if v[k]~=nil then v[k]=find(self,v[k])end end
 if kind=='use'then local to=AIList.new{};for _,name in ipairs(v.to or v.targets or{})do to[#to+1]=find(self,name)end;v.to=to else if v.to~=nil then v.to=find(self,v.to)end end
 for _,k in ipairs({'card','from_card','to_card'})do if v[k]and type(v[k].isKindOf)~='function'then v[k]=known(CardView.new(v[k]),kind..'.'..k)end end
 if v.amount~=nil then v.damage=v.amount end
 return v
end
local tag_keys={CurrentPindianStruct='biaofeng_pindian',CurrentUseStruct='biaofeng_use',CurrentJudgeStruct='biaofeng_judge',PlusYiji='biaofeng_yiji',PlusYuanmou_Damage='biaofeng_yuanmou_card',PlusChenggui_card='biaofeng_chenggui_card',PlusCuorui='biaofeng_cuorui_target',['liuli-card']='biaofeng_liuli_card',SevenFengPing='biaofeng_fengping'}
local function tag(self,key)
 local value
 if key=='CurrentJudgeStruct' then value=pq(self,'getDecisionContext').biaofeng_judge;if value~=nil then return{toJudge=function()return pq(self,'getScopedJudge',value)end}end end
 if key=='ai_PlusLuoyi_card_id'or key=='ai_PlusLuoyi_card_name'then value=self:getStrategyMemory('biaofeng.'..key);if value==nil then value=key=='ai_PlusLuoyi_card_id'and 0 or''end
 elseif key=='CurrentDamageStruct'then value=pq(self,'getDecisionContext').damage -- the room tag reaches only asks that carry it
 else value=pq(self,'getDecisionContext')[known(tag_keys[key],key)]end
 value=known(value,key)
 return{toString=function()if value==false then return''end;if type(value)~='string'then ai_unsupported('tag string unavailable',key)end;return value end,
 toInt=function()if type(value)~='number'then ai_unsupported('tag integer unavailable',key)end;return value end,
 toCard=function()if value==false then return nil end;return type(value.isKindOf)=='function'and value or known(CardView.new(value),key)end,
 toPlayer=function()return find(self,value)end,
 toDamage=function()return rehydrate(self,value,'damage')end,
 toPindian=function()return rehydrate(self,value,'pindian')end,
 toCardUse=function()return rehydrate(self,value,'use')end,
 toJudge=function()if type(value)=='table'and type(value.isGood)=='function'then return value end;ai_unsupported('tagged judge predicate requires typed judge capability','biaofeng_judge')end}
end
local function set_tag(self,key,v)
 if key~='ai_PlusLuoyi_card_id'and key~='ai_PlusLuoyi_card_name'then ai_unsupported('unapproved source tag write',key)end
 self:setStrategyMemory('biaofeng.'..key,v)
end
local function remove_tag(self,key)
 if key=='PlusYiji'then self:setStrategyMemory('biaofeng.consumed_yiji',self.request and self.request.id);return end
 set_tag(self,key,nil)
end
local function luoyi_mark(self,add)
 local epoch=known(known(AIWorldLifecycle.epochs(self.world,'turn'),'turn mark clear epochs')[pq(self.player,'objectName')],'owner mark clear epoch')
 local row=self:getStrategyMemory('biaofeng.luoyi_mark');local base=pq(self.player,'getMark','AI_do_not_invoke_PlusLuoyi-Clear')
 local offset=row and row.epoch==epoch and row.offset or 0
 if add then offset=offset+1;self:setStrategyMemory('biaofeng.luoyi_mark',{epoch=epoch,offset=offset})end
 return base+offset
end
-- sgs.ai_AOE_data has a writer only in the original-hegemony overrides.
local function aoe_truth(self)
 local active=known(known(AIHegemony.facts(self.world),'hegemony facts').original_overrides_loaded,'original override domain')
 if not active then return nil end
 ai_unsupported('legacy ai_AOE_data stack is not projected','ai_AOE_data')
end
sgs.ai_skill_use["@PlusJianxiong"] = function(self, prompt)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	local dest = damage.to
	if not dest or not pq(self,"isEnemy",dest) then return "." end
	local target
	if pq(dest,"getHp") <= 1 then
		if role(self,dest) == "rebel" and pq(self,"getOverflow") then
			for _, friend in ipairs(self.friends_noself) do
				if friend then
					if not pq(self,"hasJueqingEffect",friend, dest, damage.nature) then
						target = friend
					end
				end
			end
		elseif role(self,dest) == "loyalist" then
			local lord = call(self.room,"getLord")
			if pq(self,"isEnemy",lord) then
				target = friend
			end
		end
	end


	if not target then
		if pq(self,"hasSkills",sgs.masochism_skill, dest) then
			sort_players(self,self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if enemy then
					target = enemy
				end
			end
		end
	end

	local discard_cards = {}

	for _, id in sgs.qlist(pq(self.player,"getCards","h")) do
		if pq(id,"isBlack") then
			table.insert(discard_cards, id)
		end
	end
	if target and #discard_cards > 0 then
		return "#PlusJianxiong_Card:" ..
			discard_cards[1]:getEffectiveId() .. ":->" .. pq(target,"objectName")
	end
	return "."
end


sgs.ai_skill_choice.PlusWulve = function(self, choices, data)
	local damage = pq(data,"toDamage")
	local choice1 = getChoice(choices, "PlusWulve_choice1")
	local choice2 = getChoice(choices, "PlusWulve_choice2")
	if not damage.card then return choice2 end
	if pq(damage.card,"isKindOf","Slash") and not pq(self,"hasCrossbowEffect") and pq(self.player,"getLostHp") > 1 and pq(self,"getCardsNum","Slash") > 0 then
		return choice2
	end
	if pq(self,"isWeak") and (pq(self,"getCardsNum","Slash") > 0 or not pq(damage.card,"isKindOf","Slash") or pq(self.player,"getHandcardNum") <= pq(self.player,"getHp")) then
		return choice2
	end
	local items = pq(choices,"split","+")
	if choice1 then return choice1 end
	return items[1]
end
ai_audited_aliases.register{id="ai_target_revises.PlusWulve",registry="ai_target_revises",path={"PlusWulve"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=3,defer_canonical=true}
sgs.ai_can_damagehp.PlusWulve = function(self, from, card, to)
	if from and pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0
		and pq(self,"canLoseHp",from, card, to)
	then
		return pq(card,"isKindOf","Duel") or pq(card,"isKindOf","AOE") or pq(to,"getLostHp") > 2
	end
end

ai_audited_aliases.register{id="ai_skill_invoke.PlusLangmou",registry="ai_skill_invoke",path={"PlusLangmou"},canonical_registry="ai_skill_invoke",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.PlusLangmou",registry="ai_choicemade_filter",path={"cardChosen","PlusLangmou"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_cardchosen.PlusLangmou",registry="ai_skill_cardchosen",path={"PlusLangmou"},canonical_registry="ai_skill_cardchosen",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_need_damaged.PlusLangmou",registry="ai_need_damaged",path={"PlusLangmou"},canonical_registry="ai_need_damaged",canonical_path={"fankui"},self_index=1,defer_canonical=true}
sgs.wizard_skill = sgs.wizard_skill .. "|PlusGuicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|PlusGuicai"


sgs.ai_skill_cardask["@PlusGuicai-card"] = function(self, data)
	local judge = pq(data,"toJudge")

	
	if pq(self,"needRetrial",judge) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		if pq(self.player,"getPile","wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
				table.insert(cards, disclosed(self,id))
			end
		end
		local card_id = pq(self,"getRetrialCardId",cards, judge)
		if card_id ~= -1 then
			
			return "#PlusGuicai_DummyCard:" .. card_id .. ":"
		end
	end

	return "."
end

function sgs.ai_cardneed.PlusGuicai(to, card, self)
	for _, player in sgs.qlist(pq(self.room,"getAllPlayers")) do
		if pq(self,"getFinalRetrial",to) == 1 then
			if pq(player,"containsTrick","lightning") and not pq(player,"containsTrick","YanxiaoCard") then
				return pq(card,"getSuit") == sgs.Card_Spade and pq(card,"getNumber") >= 2 and pq(card,"getNumber") <= 9 and
					not pq(self,"hasSkills","hongyan|wuyan")
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipDrawPhase",player) then
				return pq(card,"getSuit") == sgs.Card_Club
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipPlayPhase",player) then
				return pq(card,"getSuit") == sgs.Card_Heart
			end
		end
	end
end

sgs.PlusGuicai_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}


sgs.ai_skill_use["@PlusGuicai2"] = function(self, prompt)
	local targets = AIList.new(pq(self.room,"getAllPlayers"))
	local pindian = tag(self,"CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if scoped_flag(self,p,"PlusGuicai_Source") then
			from = p
		end
		if scoped_flag(self,p,"PlusGuicai_Target") then
			to = p
		end
	end
	if from and to and pq(self,"isFriend",to) and pq(self,"isEnemy",from) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		local max_card = {}
		local min_card = {}
		sort_keep(self,cards)
		if pq(pindian.to_card,"getNumber") < pq(pindian.from_card,"getNumber") then
			for _, acard in ipairs(cards) do
				if not pq(acard,"isKindOf","Peach") then
					if pq(acard,"getNumber") < pq(pindian.to_card,"getNumber") then
						table.insert(min_card, pq(acard,"getEffectiveId"))
					elseif pq(acard,"getNumber") >= pq(pindian.from_card,"getNumber") then
						table.insert(max_card, pq(acard,"getEffectiveId"))
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuicai_Card:" .. max_card[1] .. ":->" .. pq(to,"objectName")
			end
			if #min_card > 0 then
				return "#PlusGuicai_Card:" .. min_card[1] .. ":->" .. pq(from,"objectName")
			end
		end
	end
	if from and to and pq(self,"isFriend",from) and pq(self,"isEnemy",to) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		local max_card = {}
		local min_card = {}
		sort_keep(self,cards)
		if pq(pindian.to_card,"getNumber") >= pq(pindian.from_card,"getNumber") then
			for _, acard in ipairs(cards) do
				if not pq(acard,"isKindOf","Peach") then
					if pq(acard,"getNumber") > pq(pindian.to_card,"getNumber") then
						table.insert(max_card, pq(acard,"getEffectiveId"))
					elseif pq(acard,"getNumber") < pq(pindian.from_card,"getNumber") then
						table.insert(min_card, pq(acard,"getEffectiveId"))
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuicai_Card:" .. max_card[1] .. ":->" .. pq(from,"objectName")
			end
			if #min_card > 0 then
				return "#PlusGuicai_Card:" .. min_card[1] .. ":->" .. pq(to,"objectName")
			end
		end
	end

	return "."
end

sgs.ai_target_revises.PlusTaohui = function(to, card, self, use)
	if pq(card,"isNDTrick") and pq(to,"getHandcardNum") <= pq(to,"getMaxHp")
		and pq(self,"getCardsNum","BasicCard") - pq(self,"getCardsNum","Peach") < 2
	then
		return true
	end
end

sgs.ai_skill_cardask["@PlusTaohui"] = function(self, data)
	local use = pq(data,"toCardUse")
	local current = call(self.room,"getCurrent")
	for _, p in sgs.qlist(use.to) do
		if pq(p,"getMark","PlusTaohui-Clear") > 0 then
			if pq(self,"isFriend",p) then
				if pq(use.card,"isKindOf","AmazingGrace") and
					(pq(p,"getSeat") - pq(current,"getSeat")) % (pq(self.room,"alivePlayerCount")) < pq(self.room,"alivePlayerCount") / 2 then
					local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if pq(use.card,"isKindOf","GodSalvation") and pq(p,"isWounded") or pq(use.card,"isKindOf","ExNihilo") then
					local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")

					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if pq(use.card,"isKindOf","IronChain") then
					if pq(p,"isChained") and not pq(self,"isGoodChainTarget",p) then
						local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
						if #to_discard > 0 then return "$" .. to_discard[1] end
					end
				end
			end
			if pq(self,"isEnemy",p) or (pq(self,"isFriend",p) and role(self,p) == "loyalist" and not pq(self,"hasJueqingEffect",self.player, p, sgs.card_damage_nature[pq(use.card,"getClassName")]) and pq(self.player,"isLord") and pq(p,"getHp") == 1) then
				if pq(use.card,"isKindOf","AOE") then
					local from = use.from
					if pq(use.card,"isKindOf","SavageAssault") then
						local menghuo = call(self.room,"findPlayerBySkillName","huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, q in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
						if pq(self,"isFriend",q) then friend_null = friend_null + getCardsNum("Nullification", q, self.player) end
						if pq(self,"isEnemy",q) then friend_null = friend_null - getCardsNum("Nullification", q, self.player) end
					end
					friend_null = friend_null + pq(self,"getCardsNum","Nullification")
					local sj_num = pq(self,"getCardsNum",pq(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

					if pq(self,"hasTrickEffective",use.card, p, from) then
						if pq(self,"damageIsEffective",p, sgs.DamageStruct_Normal, from) then
							if sj_num == 0 and friend_null <= 0 then
								if pq(self,"isEnemy",from) and pq(self,"hasJueqingEffect",from, p, sgs.card_damage_nature[pq(use.card,"getClassName")]) then
				
									local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
								if pq(self,"isFriend",from) and role(self,p) == "loyalist" and pq(from,"isLord") and pq(p,"getHp") == 1 and not pq(self,"hasJueqingEffect",from, p, sgs.card_damage_nature[pq(use.card,"getClassName")]) then
									return "."
								end
								if (not (pq(self,"hasSkills",sgs.masochism_skill, p) or (pq(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or pq(self,"hasJueqingEffect",use.from, p, sgs.card_damage_nature[pq(use.card,"getClassName")])) then
									return "."
								end
							end
						end
					end
				elseif pq(self,"isEnemy",p) then
					if pq(use.card,"isKindOf","FireAttack") then
						if pq(self,"hasTrickEffective",use.card, p) then
							if pq(self,"damageIsEffective",p, sgs.DamageStruct_Fire, self.player) then
								if (pq(p,"hasArmorEffect","vine") or pq(p,"getMark","@gale") > 0) and pq(self.player,"getHandcardNum") > 3
									and not (pq(self.player,"hasSkill","hongyan") and getKnownCard(p, p, "spade") > 0) then
				
									local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								elseif pq(p,"isChained") and not pq(self,"isGoodChainTarget",p, use.from) then
				
									local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
							end
						end
					elseif (pq(use.card,"isKindOf","Snatch") or pq(use.card,"isKindOf","Dismantlement") or pq(use.card,"isKindOf","Zhujinqiyuan") or pq(use.card,"isKindOf","ZdShengdongjixi")) and not pq(p,"isKongcheng") then
						if pq(self,"hasTrickEffective",use.card, p) then
							local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
		
							if #to_discard > 0 then return "$" .. to_discard[1] end
						end
					elseif pq(use.card,"isKindOf","Duel") or pq(use.card,"isKindOf","chuqibuyi") then
						if pq(self,"hasTrickEffective",use.card, p) then
							if pq(self,"damageIsEffective",p, sgs.DamageStruct_Normal, self.player) then
								local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
								if #to_discard > 0 then return "$" .. to_discard[1] end
							end
						end
					elseif pq(use.card,"isKindOf","IronChain") then
						if pq(self,"isGoodChainTarget",p) then
							local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
							if #to_discard > 0 then return "$" .. to_discard[1] end
						end
					end
				end
			end
		end
	end

	return "."
end


ai_audited_aliases.register{id="ai_skill_invoke.PlusTiandu",registry="ai_skill_invoke",path={"PlusTiandu"},canonical_registry="ai_skill_invoke",canonical_path={"jianxiong"},self_index=1,defer_canonical=true}
function sgs.ai_slash_prohibit.PlusTiandu(self, from, to)
	if pq(self,"canLiegong",to, from) then return false end
	if pq(self,"isEnemy",to) and pq(self,"hasEightDiagramEffect",to) and not IgnoreArmor(from, to) and #self.enemies > 1 then return true end
end

sgs.ai_skill_use["@PlusYiji"] = function(self, prompt)
	

	local tag = tag(self,"PlusYiji")
	local guanxu_cardsToGet
	if tag then
		guanxu_cardsToGet = pq(tag,"toString"):split("+")
	else
		return "."
	end
	remove_tag(self,"PlusYiji")

	local cards = {}
	for i = 1, #guanxu_cardsToGet, 1 do
		local card_data = guanxu_cardsToGet[i]
		if card_data == nil then break end
		if card_data ~= "" then
			local card_id = tonumber(card_data)
			table.insert(cards, disclosed(self,card_id))
		end
	end



	local give_card = {}
	local equip_card = {}
	local judge_card = {}
	sort_keep(self,cards)
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","EquipCard") then
			table.insert(equip_card, pq(acard,"getEffectiveId"))
		elseif pq(acard,"isKindOf","DelayedTrick") then
			table.insert(judge_card, pq(acard,"getEffectiveId"))
		else
			table.insert(give_card, pq(acard,"getEffectiveId"))
		end
	end
	if #judge_card > 0 then
		sort_players(self,self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if (not pq(self.player,"isProhibited",enemy, disclosed(self,judge_card[1])) and pq(enemy,"hasJudgeArea") and not pq(enemy,"containsTrick",disclosed(self,judge_card[1]):objectName())) then
				return "#PlusYiji_Card:" .. judge_card[1] .. ":->" .. pq(enemy,"objectName")
			end
		end
	end
	if #equip_card > 0 then
		sort_players(self,self.friends, "defense")
		local equip_index = disclosed(self,equip_card[1]):getEquipSlot()
		for _, friend in ipairs(self.friends) do
			if call(friend,"getEquip",equip_index) == nil and pq(friend,"hasEquipArea",equip_index) then
				return "#PlusYiji_Card:" .. equip_card[1] .. ":->" .. pq(friend,"objectName")
			end
		end
	end



	if #give_card > 0 then
		local target1
		local extra = pq(self,"getCardsNum","Jink") - pq(self.player,"getHp") - pq(self,"getCardsNum","Peach") > 0
		for _, acard in ipairs(give_card) do
			local card = disclosed(self,acard)
			if pq(card,"isKindOf","Peach") or pq(card,"isKindOf","Analeptic") then continue end
			if not extra and pq(card,"isKindOf","Jink") then continue end
			local ids = {}
			table.insert(ids, pq(card,"getEffectiveId"))
			local target, cardid = sgs.ai_skill_askforyiji.nosyiji(self, ids)
			if not target then continue end
			if not target1 or pq(target1,"objectName") == pq(target,"objectName") then
				target1 = target
			end
		end
		if not target1 then return "." end
		return "#PlusYiji_Card:" .. give_card[1] .. ":->" .. pq(target1,"objectName")
	end
	return "."
end


ai_audited_aliases.register{id="ai_skill_invoke.PlusYiji",registry="ai_skill_invoke",path={"PlusYiji"},canonical_registry="ai_skill_invoke",canonical_path={"yiji"},self_index=1,defer_canonical=true}
sgs.ai_skill_choice.PlusYiji = function(self, choices, data)
	local target = pq(data,"toPlayer")
	local items = pq(choices,"split","+")
	if table.contains(items, "PlusYiji_delayedTrick") and target and pq(self,"isEnemy",target) then
		return
		"PlusYiji_delayedTrick"
	end
	if table.contains(items, "PlusYiji_equip") and target and pq(self,"isFriend",target) then return "PlusYiji_equip" end
	return items[1]
end

sgs.ai_need_damaged.PlusYiji = function(self, attacker, player)
	if not pq(player,"hasSkill","PlusYiji") then return end

	local friends = {}
	for _, ap in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(self,"isFriend",ap, player) then
			table.insert(friends, ap)
		end
	end
	sort_players(self,friends, "hp")

	if #friends > 0 and friends[1]:objectName() == pq(player,"objectName") and pq(self,"isWeak",player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end

	return pq(player,"getHp") > 2 and pq(self.room,"getTurnCount") > 2 and #friends > 1 and not pq(self,"isWeak",player) and
		pq(player,"getHandcardNum") >= 2
end

sgs.ai_skill_choice.PlusGanglie = function(self, choices, data)
	local use = pq(data,"toCardUse")
	local items = pq(choices,"split","+")
	if table.contains(items, "PlusGanglie_choice1") then
		if not use.from or pq(use.from,"isDead") then return "PlusGanglie_cancel" end
		if self.role == "rebel" and pq(self,"getRoleEstimate",use.from) == "rebel" and not pq(self,"hasJueqingEffect",use.from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")])
			and pq(self.player,"getHp") == 1 and pq(self,"getAllPeachNum") < 1 then
			return "PlusGanglie_cancel"
		end

		if pq(self,"isEnemy",use.from) or (pq(self,"isFriend",use.from) and self.role == "loyalist" and not pq(self,"hasJueqingEffect",use.from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")]) and pq(use.from,"isLord") and pq(self.player,"getHp") == 1) then
			if pq(use.card,"isKindOf","Slash") then
				if not pq(self,"slashIsEffective",use.card, self.player, use.from) then return "PlusGanglie_cancel" end
				if pq(self,"hasHeavyDamage",use.from, use.card, self.player) then return "PlusGanglie_choice1" end

				local jink_num = pq(self,"getExpectedJinkNum",use)
				local hasHeart = false
				for _, card in ipairs(pq(self,"getCards","Jink")) do
					if pq(card,"getSuit") == sgs.Card_Heart then
						hasHeart = true
						break
					end
				end
				if pq(self,"getCardsNum","Jink") == 0
					or jink_num == 0
					or pq(self,"getCardsNum","Jink") < jink_num
					or (pq(use.from,"hasSkill","dahe") and pq(self.player,"hasFlag","dahe") and not hasHeart) then
					if pq(use.card,"isKindOf","NatureSlash") and pq(self.player,"isChained") and not pq(self,"isGoodChainTarget",self.player, use.from, nil, nil, use.card) then
						return
						"PlusGanglie_choice1"
					end
					if pq(use.from,"hasSkill","nosqianxi") and pq(use.from,"distanceTo",self.player) == 1 then
						return
						"PlusGanglie_choice1"
					end
					if pq(self,"isFriend",use.from) and self.role == "loyalist" and not pq(self,"hasJueqingEffect",use.from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")]) and pq(use.from,"isLord") and pq(self.player,"getHp") == 1 then
						return
						"PlusGanglie_choice1"
					end
					if (not (pq(self,"hasSkills",sgs.masochism_skill) or (pq(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or pq(self,"hasJueqingEffect",use.from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")])) then
						return "PlusGanglie_choice1"
					end
				end
			elseif pq(use.card,"isKindOf","AOE") then
				local from = use.from
				if pq(use.card,"isKindOf","SavageAssault") then
					local menghuo = call(self.room,"findPlayerBySkillName","huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
					if pq(self,"isFriend",p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if pq(self,"isEnemy",p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + pq(self,"getCardsNum","Nullification")
				local sj_num = pq(self,"getCardsNum",pq(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

				if not pq(self,"hasTrickEffective",use.card, self.player, from) then return "PlusGanglie_cancel" end
				if not pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, from) then
					return
					"PlusGanglie_cancel"
				end
				if pq(use.from,"hasSkill","drwushuang") and pq(self.player,"getCardCount") == 1 and pq(self,"hasLoseHandcardEffective") then
					return
					"PlusGanglie_choice1"
				end
				if sj_num == 0 and friend_null <= 0 then
					if pq(self,"isEnemy",from) and pq(self,"hasJueqingEffect",from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")]) then
						return
						"PlusGanglie_choice1"
					end
					if pq(self,"isFriend",from) and self.role == "loyalist" and pq(from,"isLord") and pq(self.player,"getHp") == 1 and not pq(self,"hasJueqingEffect",from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")]) then
						return
						"PlusGanglie_choice1"
					end
					if (not (pq(self,"hasSkills",sgs.masochism_skill) or (pq(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or pq(self,"hasJueqingEffect",from, self.player, sgs.card_damage_nature[pq(use.card,"getClassName")])) then
						return "PlusGanglie_choice1"
					end
				end
			elseif pq(self,"isEnemy",use.from) then
				if pq(use.card,"isKindOf","FireAttack") and pq(use.from,"getHandcardNum") > 0 then
					if not pq(self,"hasTrickEffective",use.card, self.player) then return "PlusGanglie_cancel" end
					if not pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, use.from) then
						return
						"PlusGanglie_cancel"
					end
					if (pq(self.player,"hasArmorEffect","vine") or pq(self.player,"getMark","@gale") > 0) and pq(use.from,"getHandcardNum") > 3
						and not (pq(use.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
						return "PlusGanglie_choice1"
					elseif pq(self.player,"isChained") and not pq(self,"isGoodChainTarget",self.player, use.from) then
						return "PlusGanglie_choice1"
					end
				elseif (pq(use.card,"isKindOf","Snatch") or pq(use.card,"isKindOf","Dismantlement") or pq(use.card,"isKindOf","Zhujinqiyuan"))
					and not pq(self.player,"isKongcheng") and not pq(self,"isWeak") then
					if not pq(self,"hasTrickEffective",use.card, self.player) then return "PlusGanglie_cancel" end
					return "PlusGanglie_choice1"
				elseif pq(use.card,"isKindOf","chuqibuyi") then
					if pq(self,"hasTrickEffective",use.card, self.player) and pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, use.from) then
						return
						"PlusGanglie_choice1"
					end
				elseif pq(use.card,"isKindOf","Duel") then
					if pq(self,"getCardsNum","Slash") == 0 or pq(self,"getCardsNum","Slash") < getCardsNum("Slash", use.from, self.player) then
						if pq(self,"hasTrickEffective",use.card, self.player) and pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, use.from) then
							return
							"PlusGanglie_choice1"
						end
					end
				elseif pq(use.card,"isKindOf","TrickCard") and not pq(use.card,"isKindOf","AmazingGrace") then
					if pq(self,"needToLoseHp",self.player, use.from, use.card) then
						return "PlusGanglie_choice1"
					end
				end
			end
		end
	end
	if table.contains(items, "PlusGanglie_choice2") then
		if use.from and pq(self,"isEnemy",use.from) then
			if pq(use.card,"isKindOf","FireAttack") or pq(use.card,"isKindOf","Snatch") or pq(use.card,"isKindOf","Zhujinqiyuan") or pq(use.card,"isKindOf","Collateral") then
				return
				"PlusGanglie_cancel"
			end
			if pq(use.card,"isKindOf","Slash") then
				if not pq(self,"slashIsEffective",use.card, use.from, use.from) then return "PlusGanglie_cancel" end
				if pq(self,"hasHeavyDamage",use.from, use.card, use.from) then return "PlusGanglie_choice2" end

				

				if getCardsNum("Jink", use.from) == 0
					or jink_num == 0
					or getCardsNum("Jink", use.from) < 1 then
					if pq(use.card,"isKindOf","NatureSlash") and pq(use.from,"isChained") and not pq(self,"isGoodChainTarget",use.from, use.from, nil, nil, use.card) then
						return
						"PlusGanglie_choice2"
					end
					return "PlusGanglie_choice2"
				end
			elseif pq(use.card,"isKindOf","AOE") then
				if pq(self,"isWeak",use.from)  and pq(self,"hasTrickEffective",use.card, use.from, use.from) then
					return "PlusGanglie_choice2"
				end
			elseif pq(use.card,"isKindOf","Duel") or pq(use.card,"isKindOf","chuqibuyi") then
				if pq(self,"isWeak",use.from)  and pq(self,"hasTrickEffective",use.card, use.from, use.from) then
					return "PlusGanglie_choice2"
				end
			end
		end
	end
	return "PlusGanglie_cancel"
end


sgs.ai_skill_invoke.PlusLuoyi = function(self, data)
	if pq(self.player,"isSkipped",sgs.Player_Play) then return false end
	if pq(self,"needBear") then return false end
	local cards = pq(self.player,"getCards","he")
	cards = AIList.new(cards)
	local slashtarget = 0
	local dueltarget = 0
	sort_players(self,self.enemies, "hp")
	for _, card in ipairs(cards) do
		if pq(card,"isKindOf","Slash") or pq(card,"isKindOf","EquipCard") then
			for _, enemy in ipairs(self.enemies) do
				if pq(self.player,"canSlash",enemy, card, true) and pq(self,"slashIsEffective",card, enemy) and pq(self,"objectiveLevel",enemy) > 3 and pq(self,"isGoodTarget",enemy, self.enemies) then
					if getCardsNum("Jink", enemy) < 1 or (pq(self.player,"hasWeapon","axe") and pq(self.player,"getCards","he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if pq(card,"isKindOf","Duel") or pq(card,"isKindOf","EquipCard") then
			for _, enemy in ipairs(self.enemies) do
				if pq(self,"getCardsNum","Slash") >= getCardsNum("Slash", enemy) and pq(self,"isGoodTarget",enemy, self.enemies)
					and pq(self,"objectiveLevel",enemy) > 3 and not pq(self,"cantbeHurt",enemy, self.player, 2) and pq(self,"canDamage",enemy,self.player,nil)
					and pq(self,"damageIsEffective",enemy) and pq(enemy,"getMark","@late") < 1 then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget + dueltarget) > 0 then
		return true
	end
	return false
end


local PlusLuoyi_skill = {}
PlusLuoyi_skill.name = "PlusLuoyi"
table.insert(package_skills, PlusLuoyi_skill)
PlusLuoyi_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self.player,"hasFlag","PlusLuoyi") or not pq(self.player,"hasEquip") then return end
	local patterns = { "slash", "duel" }
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = call(self,"cloneEvaluationCard",name)
		
		if pq(poi,"isAvailable",self.player) then
			table.insert(choices, name)
		end
	end

	if next(choices) and luoyi_mark(self,false) == 0 then
		return parse(self,request,"#PlusLuoyi_select:.:")
	end
end

sgs.ai_skill_use_func["#PlusLuoyi_select"] = function(card,use,self,request)
	local useable_cards = AIList.new(pq(self.player,"getCards","e"))
	sort_use(self,useable_cards, true)

	if #useable_cards == 0 then return end
	if useable_cards[1]:hasFlag("xiahui") then return end
	set_tag(self,"ai_PlusLuoyi_card_id",useable_cards[1]:getEffectiveId())
	local card_str = string.format("#PlusLuoyi_select:%s:", useable_cards[1]:getEffectiveId())
	local acard = parse(self,request,card_str)
	use.card = acard
end

sgs.ai_use_priority["PlusLuoyi_select"] = 3
sgs.ai_use_value["PlusLuoyi_select"] = 3

sgs.ai_skill_choice["PlusLuoyi"] = function(self, choices, data)
	local ai_taoluan_card_id = tag(self,"ai_PlusLuoyi_card_id"):toInt()
	remove_tag(self,"ai_PlusLuoyi_card_id")
	local taoluan_vs_card = {}
	local suit = disclosed(self,ai_taoluan_card_id):getSuit()
	local number = disclosed(self,ai_taoluan_card_id):getNumber()
	local items = pq(choices,"split","+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card=owner_clone(self,"PlusLuoyi",card_name,suit,number)
			
			table.insert(taoluan_vs_card, use_card)
		end
	end
	sort_priority(self,taoluan_vs_card)
	for _, c in ipairs(taoluan_vs_card) do
		if table.contains(items, pq(c,"objectName")) then
			if pq(c,"isKindOf","Duel") then
				local dummyuse = { isDummy = true, to = AIList.new({}) }
				call(self,"useTrickCard",c, dummyuse)
				if not pq(dummyuse.to,"isEmpty") then
					for _, p in sgs.qlist(dummyuse.to) do
						set_tag(self,"ai_PlusLuoyi_card_name",pq(c,"objectName"))
						set_tag(self,"ai_PlusLuoyi_card_id",ai_taoluan_card_id)
						return pq(c,"objectName")
					end
				end
			end
			if pq(c,"isKindOf","Slash") then
				local dummyuse = { isDummy = true, to = AIList.new({}) }
				call(self,"useBasicCard",c, dummyuse)
				if not pq(dummyuse.to,"isEmpty") then
					for _, p in sgs.qlist(dummyuse.to) do
						set_tag(self,"ai_PlusLuoyi_card_name",pq(c,"objectName"))
						set_tag(self,"ai_PlusLuoyi_card_id",ai_taoluan_card_id)
						return pq(c,"objectName")
					end
				end
			end
		end
	end
	luoyi_mark(self,true)
	return "cancel"
end

sgs.ai_skill_use["@PlusLuoyi"] = function(self, prompt, method)
	local ai_taoluan_card_name = tag(self,"ai_PlusLuoyi_card_name"):toString()
	remove_tag(self,"ai_PlusLuoyi_card_name")
	local ai_taoluan_card_id = tag(self,"ai_PlusLuoyi_card_id"):toInt()
	remove_tag(self,"ai_PlusLuoyi_card_id")
	local taoluan_use_card = disclosed(self,ai_taoluan_card_id)
	local suit = pq(taoluan_use_card,"getSuitString")
	local number = pq(taoluan_use_card,"getNumberString")
	local use_card=owner_normal(self,"PlusLuoyi",ai_taoluan_card_name,{ai_taoluan_card_id})

	local dummyuse = { isDummy = true, to = AIList.new({}) }
	call(self,"useTrickCard",use_card, dummyuse)
	local targets = {}
	if not pq(dummyuse.to,"isEmpty") then
		for _, p in sgs.qlist(dummyuse.to) do
			table.insert(targets, pq(p,"objectName"))
		end
		if #targets > 0 then
			return pq(use_card,"getLegacyStringKey") .. "->" .. table.concat(targets, "+")
		end
	end

	luoyi_mark(self,true)
	return "."
end

function sgs.ai_cardneed.PlusLuoyi(to, card, self)
	local slash_num = 0
	local target
	local slash = call(self,"cloneEvaluationCard","slash")
	

	local cards = pq(to,"getHandcards")
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", call(self.room,"getCurrent"):objectName(), pq(to,"objectName"))
		if pq(c,"hasFlag","visible") or pq(c,"hasFlag",flag) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end
		end
	end

	sort_players(self,self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if pq(to,"canSlash",enemy) and not pq(self,"slashProhibit",slash, enemy) and pq(self,"slashIsEffective",slash, enemy) and pq(self,"getDefenseSlash",enemy) <= 2 then
			target = enemy
			break
		end
	end

	if need_slash and target and isCard("Slash", card, to) then return true end
	return isCard("Duel", card, to) or isCard("EquipCard", card, to)
end

sgs.PlusLuoyi_keep_value = {
	Peach          = 6,
	Analeptic      = 5.8,
	Jink           = 5.2,
	Duel           = 5.5,
	FireSlash      = 5.6,
	Slash          = 5.4,
	ThunderSlash   = 5.5,
	Axe            = 5,
	Blade          = 4.9,
	spear          = 4.9,
	fan            = 4.8,
	KylinBow       = 4.7,
	Halberd        = 4.6,
	MoonSpear      = 4.5,
	SPMoonSpear    = 4.5,
	DefensiveHorse = 4
}

sgs.ai_ajustdamage_from.PlusLuoyi = function(self, from, to, card, nature)
	if (card and (pq(card,"isKindOf","Slash") or pq(card,"isKindOf","Duel"))) and pq(from,"hasFlag","PlusLuoyi") and not pq(from,"hasEquip")
	then
		return 1
	end
end

sgs.use_lion_skill = sgs.use_lion_skill .. "|PlusLuoyi"
sgs.need_equip_skill = sgs.need_equip_skill .. "|PlusLuoyi"

sgs.ai_skill_invoke.PlusHuwei = function(self, data)
	if pq(self.player,"getHp") == 1 then return false end
	local dying = 0
	local handang = call(self.room,"findPlayerBySkillName","nosjiefan")
	for _, aplayer in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(aplayer,"getHp") < 1 and not pq(aplayer,"hasSkill","nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and pq(self,"isFriend",handang) and dying > 0 then return false end

	local heart_jink = false
	for _, card in sgs.qlist(pq(self.player,"getCards","he")) do
		if pq(card,"getSuit") == sgs.Card_Heart and isCard("Jink", card, self.player) then
			heart_jink = true
			break
		end
	end

	
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isFriend",current) and pq(self.player,"isChained") and pq(self,"isGoodChainTarget",self.player, current) then return false end

	if pq(self.player,"getHandcardNum") == 1 and pq(self,"getCardsNum","Jink") == 1 and pq(self.player,"hasSkills","zhiji|beifa") and pq(self,"needKongcheng") then
		local enemy_num = pq(self,"getEnemyNumBySeat",call(self.room,"getCurrent"), self.player, self.player)
		if pq(self.player,"getHp") > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and pq(self,"isFriend",handang) and dying > 0 then return false end
	if pq(self.player,"hasFlag","dahe") then return false end
	if sgs.hujiasource and (not pq(self,"isFriend",sgs.hujiasource) or pq(sgs.hujiasource,"hasFlag","dahe")) then return false end
	if sgs.lianlisource and (not pq(self,"isFriend",sgs.lianlisource) or pq(sgs.lianlisource,"hasFlag","dahe")) then return false end
	if pq(self,"needToLoseHp",self.player, nil, nil, true, true) then return false end
	if pq(self,"getCardsNum","Jink") == 0 then
		return true
	else
		return false
	end

	return true
end


ai_get_cardType = function(card)
	if pq(card,"isKindOf","Weapon") then return 1 end
	if pq(card,"isKindOf","Armor") then return 2 end
	if pq(card,"isKindOf","DefensiveHorse") then return 3 end
	if pq(card,"isKindOf","OffensiveHorse") then return 4 end
	if pq(card,"isKindOf","Treasure") then return 5 end
end

sgs.ai_skill_use["@PlusShensu1"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	if pq(self.player,"containsTrick","lightning") and pq(self.player,"getCards","j"):length() == 1
		and pq(self,"hasWizard",self.friends) and not pq(self,"hasWizard",self.enemies, true) then
		return "."
	end

	if pq(self,"needBear") then return "." end
	local selfDef = self:getDefense(self.player)

	local cards = pq(self.player,"getCards","he")
	cards = AIList.new(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0 }

	if pq(self,"needToThrowArmor") and not pq(self.player,"isCardLimited",call(self.player,"getArmor"), method) then
		eCard = call(self.player,"getArmor")
	end

	if not eCard then
		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) then
				hasCard[ai_get_cardType(card)] = hasCard[ai_get_cardType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and hasCard[ai_get_cardType(card)] > 1 then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and ai_get_cardType(card) > 3 and not pq(self.player,"isCardLimited",card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and not pq(card,"isKindOf","Armor") and not pq(self.player,"isCardLimited",card, method) then
					eCard = card
					break
				end
			end
		end
	end
	if not eCard then return "." end

	local effectslash, best_target, target, throw_weapon
	local defense = 6
	local weapon = call(self.player,"getWeapon")
	if weapon and pq(eCard,"getId") == pq(weapon,"getId") and (pq(eCard,"isKindOf","fan") or pq(eCard,"isKindOf","QinggangSword")) then throw_weapon = true end

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local slash = call(self,"cloneEvaluationCard","slash")
		
		local eff = pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)

		if not pq(self.player,"canSlash",enemy, slash, false) then
		elseif throw_weapon and pq(enemy,"hasArmorEffect","vine") and not pq(self.player,"hasSkill","zonghuo") then
		elseif pq(self,"slashProhibit",nil, enemy) then
		elseif eff then
			if pq(enemy,"getHp") == 1 and getCardsNum("Jink", enemy) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
	end

	if best_target then return "#PlusShensu_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. pq(best_target,"objectName") end
	if target then return "#PlusShensu_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. pq(target,"objectName") end


	for _, friend in ipairs(self.friends_noself) do
		local def = self:getDefense(friend)
		local slash = call(self,"cloneEvaluationCard","slash")
		
		local eff = pq(self,"slashIsEffective",slash, friend)

		if not pq(self.player,"canSlash",friend, slash, false) then
		elseif pq(self,"slashProhibit",nil, friend) then
		elseif eff then
			if pq(self,"needToLoseHp",friend, self.player, slash) then
				target = friend
			end
		end
	end
	if target then return "#PlusShensu_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. pq(target,"objectName") end

	return "."
end

sgs.ai_skill_use["@PlusShensu2"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")

	local selfSub = pq(self.player,"getHp") - pq(self.player,"getHandcardNum")
	local selfDef = self:getDefense(self.player)

	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)

	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if pq(card,"isRed") and not pq(card,"isKindOf","Peach") and not pq(card,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") == 1 then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end

	local effectslash, best_target, target
	local defense = 6

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local slash = call(self,"cloneEvaluationCard","slash")
		
		local eff = pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)

		if not pq(self.player,"canSlash",enemy, slash, false) then
		elseif pq(self,"slashProhibit",nil, enemy) then
		elseif eff then
			if pq(enemy,"getHp") == 1 and getCardsNum("Jink", enemy) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
		if selfSub < 0 then return "." end
	end

	if best_target then return "#PlusShensu_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. pq(best_target,"objectName") end
	if target then return "#PlusShensu_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. pq(target,"objectName") end

	return "."
end

sgs.ai_cardneed.PlusShensu = function(to, card, self)
	return (pq(card,"getTypeId") == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", false) < 2)
		or (pq(card,"isRed") and pq(to,"getHandcardNum") <= 2)
end

ai_audited_aliases.register{id="ai_card_intention.PlusShensu_Card",registry="ai_card_intention",path={"PlusShensu_Card"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
sgs.need_equip_skill = sgs.need_equip_skill .. "|PlusShensu"

function sgs.ai_skill_invoke.PlusJushou(self, data)
	local sbdiaochan = call(self.room,"findPlayerBySkillName","lihun")
	if sbdiaochan and pq(sbdiaochan,"faceUp") and not pq(self,"willSkipPlayPhase",sbdiaochan)
		and (pq(self,"isEnemy",sbdiaochan) or (pq(self.room,"getTurnCount") <= 1 and pq(self,"getRoleEstimate",sbdiaochan) == "neutral")) then
		return false
	end
	if not pq(self.player,"faceUp") then return true end
	for _, friend in ipairs(self.friends) do
		if pq(self,"hasSkills","fangzhu|jilve", friend) then return true end
		if pq(friend,"hasSkill","junxing") and pq(friend,"faceUp") and not pq(self,"willSkipPlayPhase",friend)
			and not (pq(friend,"isKongcheng") and pq(self,"willSkipDrawPhase",friend)) then
			return true
		end
	end
	return pq(self,"isWeak")
end

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|PlusJushou"

sgs.ai_skill_askforag["PlusKuiwei"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	sort_use(self,to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_use["@PlusYizhong"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")

	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0 }

	if not eCard then
		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) then
				hasCard[ai_get_cardType(card)] = hasCard[ai_get_cardType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and hasCard[ai_get_cardType(card)] > 1 then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and ai_get_cardType(card) > 3 and not pq(self.player,"isCardLimited",card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if pq(card,"isKindOf","EquipCard") and not (pq(card,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and not pq(card,"isKindOf","Armor") and not pq(self.player,"isCardLimited",card, method) then
					eCard = card
					break
				end
			end
		end
	end
	if not eCard then
		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","TrickCard") and not pq(self.player,"isCardLimited",card, method) then
				eCard = card
				break
			end
		end
	end


	local effectslash, best_target, target
	local defense = 6
	local use = tag(self,"CurrentUseStruct"):toCardUse()
	for _, friend in ipairs(self.friends) do
		if yizhong_mark(self,friend) > 0 then
			local def = self:getDefense(friend)
			local slash = use.card
			local eff = pq(self,"slashIsEffective",slash, friend)
			if use.card and pq(self,"hasHeavyDamage",use.from, use.card, friend) then
				best_target = friend
				break
			end
			if not pq(self.player,"canSlash",friend, slash, false) then
			elseif pq(self,"slashProhibit",nil, friend) then
			elseif eff then
				if pq(friend,"getHp") == 1 and getCardsNum("Jink", friend) == 0 then
					best_target = friend
					break
				end
				if def < defense then
					best_target = friend
					defense = def
				end
				target = friend
			end
		end
	end

	if best_target then
		if not eCard then
			for _, card in ipairs(cards) do
				if not pq(card,"isKindOf","Peach") and not pq(self.player,"isCardLimited",card, method) then
					eCard = card
					break
				end
			end
		end
		if eCard then
			call(self,"updateIntention",self.player, best_target, -70)
			return "#PlusYizhong_Card:" .. pq(eCard,"getEffectiveId") .. ":"
		end
	end

	if target then
		if not eCard and pq(self.player,"getHandcardNum") >= 2 then
			for _, card in ipairs(cards) do
				if not pq(card,"isKindOf","Peach") and not pq(self.player,"isCardLimited",card, method) then
					eCard = card
					break
				end
			end
		end
		if eCard then
			call(self,"updateIntention",self.player, target, -70)
			return "#PlusYizhong_Card:" .. pq(eCard,"getEffectiveId") .. ":"
		end
	end
	if not eCard then return "." end
	return "."
end

sgs.ai_skill_invoke.PlusYizhong = function(self, data)
	return true
end

function sgs.ai_cardneed.PlusYizhong(to, card)
	return (not pq(card,"isKindOf","BasicCard") and pq(to,"getHandcardNum") < 2) or
		(isCard("OffensiveHorse", card, to) and not (call(to,"getOffensiveHorse") or getKnownCard(to, "OffensiveHorse", false) > 0))
end

sgs.ai_card_intention["#PlusYizhong_Card"] = function(self, card, from, tos)
	local intention = -70
	local to
	for _, p in ipairs(AIList.new(pq(self.room,"getOtherPlayers",from))) do
		if yizhong_mark(self,p) > 0 then
			to = p
			break
		end
	end
	if to then
		call(self,"updateIntention",from, to, intention)
	end
end

sgs.ai_skill_invoke.PlusJilei = function(self, data)
	local damage = pq(data,"toDamage")
	if damage.from and pq(self,"isEnemy",damage.from) then
		if not pq(damage.from,"isKongcheng") and pq(self,"doDisCard",damage.from, "h") then
			return true
		end
	end
	return false
end

sgs.ai_skill_suit["PlusJilei"] = function(self)
	local target
	for _, p in ipairs(AIList.new(pq(self.room,"getOtherPlayers",self.player))) do
		if pq(p,"getMark","PlusJilei") > 0 then
			target = p
			break
		end
	end
	if target then
		local cards = AIList.new(pq(target,"getHandcards"))
		local flag = string.format("%s_%s_%s", "visible", pq(self.player,"objectName"), pq(target,"objectName"))
		for _, cc in ipairs(cards) do
			if (pq(cc,"hasFlag","visible") or pq(cc,"hasFlag",flag)) and (pq(cc,"isKindOf","Peach") or pq(cc,"isKindOf","Analeptic")) then
				return pq(cc,"getSuit")
			end
		end
	end
	return math.random(0, 3)
end


sgs.ai_skill_use["@PlusJiangcai"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "handcard")
	sort_players(self,self.friends_noself, "handcard")


	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)

	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","BasicCard") and not pq(card,"isKindOf","Peach") and not (pq(card,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") == 1) then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end


	local friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not pq(friend,"isKongcheng") and #friends < 3 then
			table.insert(friends, pq(friend,"objectName"))
		end
	end
	if #friends == 3 then
		return "#PlusJiangcai_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. table.concat(friends, "+")
	elseif (#friends == 1 or #friends == 2) then
		sort_players(self,self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if not pq(enemy,"isKongcheng") and #friends < 3 then
				table.insert(friends, pq(enemy,"objectName"))
			end
		end
		if #friends > 1 then
			return "#PlusJiangcai_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. table.concat(friends, "+")
		end
	end
	return "."
end


sgs.ai_skill_discard.PlusJiangcai = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_keep(self,cards)
	local target
	for _, p in ipairs(AIList.new(pq(self.room,"getOtherPlayers",self.player))) do
		if pq(p,"getMark","PlusJiangcai") > 0 then
			target = p
			break
		end
	end
	if cards[1] == nil then return {} end
	if target then
		if pq(self,"isFriend",target) then
			sort_keep(self,cards, true)
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		elseif pq(self,"isEnemy",target) then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end

	return cards[1]:getEffectiveId()
end

sgs.ai_skill_use["@PlusYuanmou"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "handcard")
	sort_players(self,self.friends_noself, "handcard")

	local damagecard = tag(self,"PlusYuanmou_Damage"):toCard()
	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if not pq(card,"isKindOf","Peach") and not (pq(card,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") == 1) and
				pq(self,"getKeepValue",card) < pq(self,"getKeepValue",damagecard) then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end

	if pq(self,"isWeak") then return "." end
	local friends = {}
	for _, p in ipairs(self.friends) do
		if not pq(self,"willSkipPlayPhase",p) then
			table.insert(friends, p)
		end
	end
	if #friends == 0 then return "." end
	sort_players(self,friends, "defense")
	if #friends > 0 then
		return "#PlusYuanmou_Card:" .. pq(eCard,"getEffectiveId") .. ":->" .. friends[1]:objectName()
	end
	return "."
end


sgs.ai_card_intention["#PlusYuanmou_Card"] = -60

sgs.ai_target_revises.PlusYuanmou = function(to, card, self)
	if pq(card,"isDamageCard")
		and not pq(self,"isFriend",to)
		and pq(card,"subcardsLength") > 0
	then
		for _, id in sgs.list(pq(card,"getSubcards")) do
			if isCard("Peach,Analeptic", disclosed(self,id), to)
			then
				return pq(to,"getHandcardNum") > 0
			end
		end
	end
end


sgs.ai_skill_invoke.PlusDanji = function(self, data)
	local damage = pq(data,"toDamage")
	if damage.card and pq(damage.card,"isKindOf","Slash") then
		if pq(self,"hasHeavyDamage",damage.from, damage.card, self.player) then
			return true
		end
	end
	if pq(self,"needToLoseHp",self.player, damage.from) and damage.damage <= 1 then return false end
	return true
end

sgs.ai_ajustdamage_to.PlusDanji = function(self, from, to, card, nature)
	if card and (pq(card,"isKindOf","Slash") or pq(card,"isNDTrick")) then
		if from and to and pq(from,"getHandcardNum") > pq(to,"getHandcardNum") then
			return -1
		end
	end
end



sgs.ai_skill_use["@PlusFuzheng"] = function(self, prompt, method)
	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isFriend",current) then
		local eCard

		if not eCard then
			for _, card in ipairs(cards) do
				if pq(card,"isRed") and not pq(card,"isKindOf","Peach") and (not (pq(card,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") == 1) or pq(self,"getOverflow",current) >= 2) then
					eCard = card
					break
				end
			end
		end

		if not eCard then return "." end

		return "#PlusFuzheng_Card:" .. pq(eCard,"getEffectiveId") .. ":"
	end
	return "."
end

sgs.ai_skill_invoke.PlusFuzheng = function(self, data)
	return true
end

sgs.ai_card_intention["#PlusFuzheng_Card"] = function(self, card, from, tos)
	local intention = -70
	local current = call(self.room,"getCurrent")
	if current then
		call(self,"updateIntention",from, current, intention)
	end
end
sgs.ai_target_revises.PlusPingluan = function(to, card)
	if pq(card,"isKindOf","SavageAssault")
		or pq(card,"isKindOf","ArcheryAttack")
	then
		return true
	end
end

local PlusZhiguo_skill = {}
PlusZhiguo_skill.name = "PlusZhiguo"
table.insert(package_skills, PlusZhiguo_skill)
PlusZhiguo_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#PlusZhiguo_Card") then return end
	return parse(self,request,"#PlusZhiguo_Card:.:")
end

sgs.ai_skill_use_func["#PlusZhiguo_Card"] = function(card,use,self,request)
	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_use(self,cards, true)

	for _, card in ipairs(cards) do
		if not pq(card,"isKindOf","Peach") and (not (pq(card,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") == 1)) then
			local targets = {}

			for _, friend in ipairs(self.friends) do
				if #targets < pq(card,"getNumber") and pq(self,"canDraw",friend, self.player) then
					table.insert(targets, friend)
				end
			end
			for _, friend in ipairs(self.friends) do
				if #targets < pq(card,"getNumber") then
					table.insert(targets, friend)
				else
					break
				end
			end
			local x = 0
			if #targets < pq(card,"getNumber") then
				for _, enemy in ipairs(self.enemies) do
					if #targets < pq(card,"getNumber") and x < 2 then
						table.insert(targets, enemy)
						x = x + 1
					end
				end
			end
			if #targets > 0 and #targets == pq(card,"getNumber") then
				use.card=final_parse(self,request,"#PlusZhiguo_Card:"..pq(card,"getEffectiveId")..":")
				for _, p in ipairs(targets) do
					if use.to then
						call(use.to,"append",p)
					end
				end
			end
			return
		end
	end
	
end

sgs.ai_skill_choice["PlusZhiguo"] = function(self, choices, data)
	return "PlusZhiguo_Draw"
end

local PlusRende_skill = {}
PlusRende_skill.name = "PlusRende"
table.insert(package_skills, PlusRende_skill)
PlusRende_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"isKongcheng") then return end
	if pq(self.player,"getHandcardNum") <= 1 and pq(self.player,"getMaxCards") > 0 and pq(self.player,"getMark","PlusRende") == 0 then return end
	local mode = string.lower(pq(self.room,"getMode"))
	if pq(self.player,"getMark","PlusRende") > 1 and call(mode,"find","04_1v3") then return end

	if pq(self.player,"isWounded") then
		if pq(self.player,"getMark","PlusRende") > 1 and pq(self,"getOverflow") <= 0 then return end
	else
		if pq(self,"getOverflow") <= 0 then return end
	end

	if pq(self,"shouldUseRende") then
		return parse(self,request,"#PlusRende_Card:.:")
	end
end

sgs.ai_skill_use_func["#PlusRende_Card"] = function(card,use,self,request)
	
	if pq(self.player,"getHp") < 3 and pq(self.player,"isWounded") and pq(self.player,"getHandcardNum") == 2 then
		sort_players(self,self.friends_noself, "handcard")
		local give_all_cards = {}
		for _, c in ipairs(AIList.new(pq(self.player,"getCards","h"))) do
			table.insert(give_all_cards, pq(c,"getEffectiveId"))
		end
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
		if #targets > 0 and #give_all_cards > 1 then
			local card_str = string.format("#PlusRende_Card:" .. table.concat(give_all_cards, "+") .. ":")
			local acard = parse(self,request,card_str)
			use.card = acard
			if use.to then
				call(use.to,"append",targets[1])
			end
			return
		end
	end

	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	local notFound

	for i = 1, pq(self.player,"getHandcardNum") do
		local card, friend = call(self,"getCardNeedPlayer",cards)
		if card and friend then
			cards = call(self,"resetCards",cards, card)
		else
			notFound = true
			break
		end

		if pq(friend,"objectName") == pq(self.player,"objectName") or not pq(self.player,"getHandcards"):contains(card) then continue end
		local canJijiang = pq(self.player,"hasLordSkill","jijiang") and pq(friend,"getKingdom") == "shu"
		if pq(card,"isAvailable",self.player) and ((pq(card,"isKindOf","Slash") and not canJijiang) or pq(card,"isKindOf","Duel") or pq(card,"isKindOf","Snatch") or pq(card,"isKindOf","Dismantlement")) then
			local dummy_use = pq(self,"aiUseCard",card)
			if dummy_use.card and pq(dummy_use.to,"length") > 0 then
				if pq(card,"isKindOf","Slash") or pq(card,"isKindOf","Duel") then
					local t1 = pq(dummy_use.to,"first")
					if pq(dummy_use.to,"length") > 1 then
						continue
					elseif pq(t1,"getHp") == 1 or getCardsNum("Jink",t1,self.player)<1
						or pq(t1,"isCardLimited",call(self,"cloneEvaluationCard","jink"), sgs.Card_MethodResponse) then
						continue
					end
				elseif (pq(card,"isKindOf","Snatch") or pq(card,"isKindOf","Dismantlement")) and pq(self,"getEnemyNumBySeat",self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if pq(self,"isFriend",p) and (pq(self,"willSkipDrawPhase",p) or pq(self,"willSkipPlayPhase",p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif pq(card,"isAvailable",self.player) and pq(self,"getEnemyNumBySeat",self.player, friend) > 0 and (pq(card,"isKindOf","Indulgence") or pq(card,"isKindOf","SupplyShortage")) then
			local dummy_use = { isDummy = true }
			call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then continue end
		end

		if pq(friend,"hasSkill","enyuan") and #cards >= 1 and not (pq(self.room,"getMode") == "04_1v3" and pq(self.player,"getMark","PlusRende") == 1) then
			use.card=final_parse(self,request,"#PlusRende_Card:" .. pq(card,"getId") .. "+" .. cards[1]:getId() .. ":")
		else
			use.card=final_parse(self,request,"#PlusRende_Card:" .. pq(card,"getId") .. ":")
		end
		if use.to then call(use.to,"append",friend) end
		return
	end

	if notFound then
		local cards = AIList.new(pq(self.player,"getHandcards"))
		sort_use(self,cards, true)
		if pq(self.player,"isWounded") and pq(self.player,"getHandcardNum") > 3 and pq(self.player,"getMark","PlusRende") < 2 then
			sort_use(self,cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
					table
						.insert(to_give, pq(card,"getId"))
				end
				if #to_give == 2 - pq(self.player,"getMark","PlusRende") then break end
			end
			if #to_give > 0 then
				for _,p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player))do
					if pq(self,"isFriend",p)  then
						use.card=final_parse(self,request,"#PlusRende_Card:" .. table.concat(to_give, "+") .. ":")
						if use.to then call(use.to,"append",p) end
					end
				end
			end
		end
	end
end

sgs.ai_use_value["#PlusRende_Card"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["#PlusRende_Card"] = sgs.ai_use_priority.RendeCard

ai_audited_aliases.register{id="ai_card_intention.#PlusRende_Card",registry="ai_card_intention",path={"#PlusRende_Card"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
sgs.dynamic_value.benefit["#PlusRende_Card"] = true


sgs.ai_skill_choice.PlusRende = function(self, choices, data)
	local items = pq(choices,"split","+")
	if table.contains(items, "PlusRende_choice1") then
		if pq(self.player,"getHp") < self:getBestHp(self.player) then
			return "PlusRende_choice1"
		end
	end

	if table.contains(items, "PlusRende_choice3") then
		local god_salvation = call(self,"cloneEvaluationCard","god_salvation")
		
		local good = 0
		for _, who in ipairs(AIList.new(pq(self.room,"getAllPlayers"))) do
			if pq(self,"hasTrickEffective",god_salvation, who, self.player) then
				if pq(self,"isFriend",who) then
					if not pq(who,"isWounded") or pq(who,"getHp") >= self:getBestHp(who) then
					elseif pq(self,"isWeak",who) then
						good = good + 1.2
					elseif pq(who,"hasSkills",sgs.masochism_skill) then
						good = good + 1
					else
						good = good + 0.9
					end
				elseif pq(self,"isEnemy",who) then
					if not pq(who,"isWounded") or pq(who,"getHp") >= self:getBestHp(who) then
					elseif pq(self,"isWeak",who) then
						good = good - 1.2
					elseif pq(who,"hasSkills",sgs.masochism_skill) then
						good = good - 1
					else
						good = good - 0.9
					end
				end
			end
		end

		if pq(self,"willUseGodSalvation",god_salvation) and good > 0 then
			local handcards = AIList.new(pq(self.player,"getCards","h"))
			sort_use(self,handcards, true)
			local useable_cards = {}
			if pq(self.player,"getPile","wooden_ox"):length() > 0 then
				for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
					if disclosed(self,id):isKindOf("Slash") then
						table.insert(handcards, disclosed(self,id))
					end
				end
			end
			for _, c in ipairs(handcards) do
				if not pq(c,"isKindOf","Peach")
					and not pq(c,"isKindOf","Analeptic")
					and not (pq(c,"isKindOf","Analeptic") and pq(self,"getCardsNum","Analeptic") == 1 and pq(self.player,"getHp") <= 1)
					and not (pq(c,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") == 1)
					and not pq(c,"isKindOf","Nullification")
					and not pq(c,"isKindOf","SavageAssault")
					and not pq(c,"isKindOf","ArcheryAttack")
					and not pq(c,"isKindOf","Duel")
					and not pq(c,"isKindOf","Armor")
					and not pq(c,"isKindOf","DefensiveHorse")
					and pq(c,"getSuit") == sgs.Card_Heart
				then
					table.insert(useable_cards, c)
				end
			end
			if #useable_cards == 0 then return "PlusRende_cancel" end
			return "PlusRende_choice3"
		end
	end
	if table.contains(items, "PlusRende_choice2") then
		local can_invoke = true
		for _, p in sgs.qlist(pq(self.room,"getAllPlayers")) do
			if pq(p,"hasFlag","PlusRende_target") then
				if pq(p,"isNude") or pq(self,"isWeak",p) then
					can_invoke = false
					break
				end
			end
		end
		if can_invoke then
			return "PlusRende_choice2"
		end
	end

	return "PlusRende_cancel"
end

sgs.ai_skill_cardask["#PlusRende_Salvation"] = function(self, data, pattern, target)
	local cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,cards, true)
	for _, card in ipairs(cards) do
		if pq(card,"getSuit") == sgs.Card_Heart then
			return "$" .. pq(card,"getEffectiveId")
		end
	end
	return "."
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusRende"

sgs.ai_skill_invoke.PlusGuanxing = function(self, data)
	return true
end

sgs.ai_skill_invoke.PlusKongcheng = function(self, data)
	return true
end


sgs.ai_skill_playerchosen.PlusKongcheng = function(self, targets)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_keep(self,cards)
	if role_count(self,"rebel") == 0 then
		local lord = call(self.room,"getLord")
		if lord and pq(self,"isFriend",lord) and pq(lord,"objectName") ~= pq(self.player,"objectName") and not hasManjuanEffect(lord) then
			return lord
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) and not hasManjuanEffect(AssistTarget) then
		return AssistTarget
	end

	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and pq(friend,"hasSkills",sgs.cardneed_skill) then
			return friend
		end
	end

	sort_players(self,self.friends_noself, "chaofeng")
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.PlusKongcheng = -80

function sgs.ai_slash_prohibit.PlusKongcheng(self, from, to)
	if pq(self,"isEnemy",to) then return true end
end

sgs.ai_view_as.PlusWusheng = function(card, player, card_place)
	local suit = pq(card,"getSuitString")
	local number = pq(card,"getNumberString")
	local card_id = pq(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or pq(player,"getPile","wooden_ox"):contains(card_id))
		and not pq(card,"isKindOf","Peach") and not pq(card,"hasFlag","using") and not (pq(card,"isKindOf","WoodenOx") and pq(player,"getPile","wooden_ox"):length() > 0) then
		return ("slash:PlusWusheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end


sgs.ai_ajustdamage_from.PlusWusheng = function(self, from, to, card, nature)
	if card and pq(card,"isKindOf","Slash") and pq(card,"getSuit") == sgs.Card_Diamond
	then
		return 1
	end
end

local PlusWusheng_skill = {}
PlusWusheng_skill.name = "PlusWusheng"
table.insert(package_skills, PlusWusheng_skill)
PlusWusheng_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = pq(self.player,"getCards","he")
	cards = AIList.new(cards)
	if pq(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	local red_card = {}
	sort_use(self,cards, true)

	local useAll = false
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHp") == 1 and not pq(enemy,"hasArmorEffect","eight_diagram") and pq(self.player,"distanceTo",enemy) <= pq(self.player,"getAttackRange") and pq(self,"isWeak",enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end
	for _,card in ipairs(cards)do
		if not pq(card,"isKindOf","Slash") 
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (pq(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or pq(self,"getEvaluationCard","slash"):getTargetModResidue()>0)
		then table.insert(red_card,card) end
	end
	for _,card in ipairs(red_card)do
		local slash=turn_normal(self,"PlusWusheng","slash",{pq(card,"getEffectiveId")},request)
		if pq(slash,"isAvailable",self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.PlusWusheng(to, card)
	return pq(to,"getHandcardNum") < 3
end
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|PlusWusheng"
sgs.double_slash_skill = sgs.double_slash_skill .. "|PlusWusheng"

local PlusPaoxiao_skill = {}
PlusPaoxiao_skill.name = "PlusPaoxiao"
table.insert(package_skills, PlusPaoxiao_skill)
PlusPaoxiao_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getLostHp") == 0 or pq(self.player,"hasUsed","#PlusPaoxiao_Card") then return nil end

	return parse(self,request,"#PlusPaoxiao_Card:.:")
end

sgs.ai_skill_use_func["#PlusPaoxiao_Card"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#PlusPaoxiao_Card:.:")
end

sgs.ai_use_value["PlusPaoxiao_Card"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["PlusPaoxiao_Card"] = sgs.ai_use_priority.Slash + 0.2


sgs.ai_skill_choice.PlusPaoxiao_Card = function(self, choices, data)
	local extra = getChoice(choices, "PlusPaoxiao1")
	local num = getChoice(choices, "PlusPaoxiao2")

	local slashcount = pq(self,"getCardsNum","Slash")
	if slashcount > 1 then
		return num
	end
	if #self.enemies == 1 then
		return num
	end
	return extra
end

sgs.ai_getBestHp_skill.PlusPaoxiao = function(owner)
	return pq(owner,"getMaxHp") - 1
end



sgs.ai_cardneed.PlusJie = function(to, card)
	return pq(card,"isRed") and isCard("Slash", card, to)
end

sgs.ai_ajustdamage_from.PlusJie = function(self, from, to, card, nature)
	if from and card and pq(card,"isKindOf","Slash") and pq(card,"isRed")
	then
		return 1
	end
end

sgs.ai_skill_invoke.PlusChangsheng = function(self, data)
	return true
end

sgs.PlusLongdan_suit_value = {
	heart = 4.0,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.PlusLongdan(to, card, self)
	if pq(to,"getCardCount") > 3 then return false end
	if pq(to,"isNude") then return true end
	return pq(card,"getSuit") == sgs.Card_Spade
end


local PlusLongdan_skill = {}
PlusLongdan_skill.name = "PlusLongdan"
table.insert(package_skills, PlusLongdan_skill)
PlusLongdan_skill.getTurnUseCard=function(self,inclusive,request)
	local usable_cards = pq(self,"addHandPile")
	local equips = AIList.new(pq(self.player,"getCards","e"))
	for _, e in ipairs(equips) do
		if pq(e,"isKindOf","DefensiveHorse") or pq(e,"isKindOf","OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	for _, id in sgs.qlist(pq(self.player,"getHandPile")) do
		table.insert(usable_cards, disclosed(self,id))
	end
	sort_use(self,usable_cards, true)
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if pq(c,"getSuit") == sgs.Card_Diamond and #two_diamond_cards < 2 and not pq(c,"isKindOf","Peach") and not (pq(c,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) and not pq(c,"isKindOf","Slash") then
			table.insert(two_diamond_cards, pq(c,"getEffectiveId"))
		end
	end
	if #two_diamond_cards == 2 and pq(self,"slashIsAvailable") and (pq(self.player,"getHp") > 2) and pq(self,"getOverflow") > 0 then
		return parse(self,request,("slash:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_diamond_cards[1],
			two_diamond_cards[2]))
	end
	if pq(self,"slashIsAvailable") and pq(self.player,"getHp") <= 2 then
		for _, c in ipairs(usable_cards) do
			if pq(c,"getSuit") == sgs.Card_Diamond and pq(self,"slashIsAvailable") and not pq(c,"isKindOf","Peach") and not (pq(c,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") < 3) and not (pq(c,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) then
				return parse(self,request,("slash:PlusLongdan[%s:%s]=%d"):format(pq(c,"getSuitString"), pq(c,"getNumberString"),
					pq(c,"getEffectiveId")))
			end
		end
	end
	local two_heart_cards = {}
	for _, c in ipairs(usable_cards) do
		if pq(c,"getSuit") == sgs.Card_Heart and #two_heart_cards < 2 and not pq(c,"isKindOf","Peach") and not (pq(c,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) then
			table.insert(two_heart_cards, pq(c,"getEffectiveId"))
		end
	end
	if #two_heart_cards == 2 and (pq(self.player,"getHp") > 2) and pq(self,"getOverflow") > 0 then
		return parse(self,request,("analeptic:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_heart_cards[1],
			two_heart_cards[2]))
	end
	if pq(self,"slashIsAvailable") and pq(self.player,"getHp") <= 2 then
		for _, c in ipairs(usable_cards) do
			if pq(c,"getSuit") == sgs.Card_Heart and not pq(c,"isKindOf","Peach") then
				return parse(self,request,("analeptic:PlusLongdan[%s:%s]=%d"):format(pq(c,"getSuitString"), pq(c,"getNumberString"),
					pq(c,"getEffectiveId")))
			end
		end
	end
end

sgs.ai_view_as.PlusLongdan = function(card, player, card_place, class_name)
	if card_place == sgs.Player_PlaceSpecial then return end
	local usable_cards = AIList.new(pq(player,"getCards","he"))
	for _, id in sgs.qlist(pq(player,"getHandPile")) do
		table.insert(usable_cards, disclosed(self,id))
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_spade_cards = {}
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if pq(c,"getSuit") == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, pq(c,"getEffectiveId"))
		elseif pq(c,"getSuit") == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, pq(c,"getEffectiveId"))
		elseif pq(c,"getSuit") == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, pq(c,"getEffectiveId"))
		elseif pq(c,"getSuit") == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, pq(c,"getEffectiveId"))
		end
	end

	local suit = pq(card,"getSuitString")
	local number = pq(card,"getNumberString")
	local card_id = pq(card,"getEffectiveId")

	if #two_club_cards == 2 and (pq(player,"getHp") > 2) then
		return ("jink:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_club_cards[1], two_club_cards[2])
	elseif pq(card,"getSuit") == sgs.Card_Club and pq(player,"getHp") <= 2 then
		return ("jink:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if #two_heart_cards == 2 and (pq(player,"getHp") > 2) then
		return ("analeptic:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_heart_cards[1], two_heart_cards[2])
	elseif pq(card,"getSuit") == sgs.Card_Heart and pq(player,"getHp") <= 2 then
		return ("analeptic:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	
	if pq(card,"getSuit") == sgs.Card_Spade and pq(player,"getHp") <= 2 then
		return ("nullification:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if #two_diamond_cards == 2 and (pq(player,"getHp") > 2) then
		return ("slash:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_diamond_cards[1], two_diamond_cards[2])
	elseif pq(card,"getSuit") == sgs.Card_Diamond and pq(player,"getHp") <= 2 then
		return ("slash:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_getBestHp_skill.PlusLongdan = function(owner)
	return 2
end

sgs.ai_cardneed.PlusTieji = function(to, card, self)
	return (isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0) or
		(not pq(self,"willSkipPlayPhase",to) and pq(self,"getUseValue",card) < 6 and pq(card,"getNumber") > 10)
end

function sgs.ai_skill_pindian.PlusTieji(minusecard, self, requestor)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_keep(self,cards)
	if pq(requestor,"objectName") == pq(self.player,"objectName") then
		return cards[1]:getId()
	end
	return call(self,"getMaxCard",self.player):getId()
end

sgs.ai_skill_invoke.PlusTieji = function(self, data)
	local target = pq(data,"toPlayer")
	if not pq(self,"isEnemy",target) then return false end
	if not pq(self.player,"canPindian",target, true) then return false end

	if pq(self.player,"getHandcardNum") == 1 then
		if (pq(self,"needKongcheng") or not pq(self,"hasLoseHandcardEffective")) and not pq(self,"isWeak") then return true end
		local card = pq(self.player,"getHandcards"):first()
		if pq(card,"isKindOf","Jink") or pq(card,"isKindOf","Peach") then return end
	end

	if (pq(self.player,"getHandcardNum") >= pq(self.player,"getHp") or call(self,"getMaxCard"):getNumber() > 10
			or (pq(self,"needKongcheng") and pq(self.player,"getHandcardNum") == 1) or not pq(self,"hasLoseHandcardEffective"))
		and pq(self,"doDisCard",target, "he") then
		return true
	end
	if pq(self,"doDisCard",target, "e") then return true end
	return false
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.PlusTieji",registry="ai_choicemade_filter",path={"cardChosen","PlusTieji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
function sgs.ai_skill_pindian.PlusTieji(minusecard, self, requestor)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_keep(self,cards)
	if pq(requestor,"objectName") == pq(self.player,"objectName") then
		return minusecard
	end
	return call(self,"getMaxCard")
end

sgs.ai_skill_invoke.PlusJizhi = function(self, data)
	local target = pq(data,"toPlayer")
	if target then
		return pq(self,"doDisCard",target,"h")
	end
	return true
end

function sgs.ai_cardneed.PlusJizhi(to, card)
	return pq(card,"getTypeId") == sgs.Card_TypeTrick
end

function sgs.ai_cardneed.PlusYongyi(to, card)
	return (isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0) or
		(pq(card,"isKindOf","Weapon") and not (call(to,"getWeapon") or getKnownCard(to, "Weapon", false) > 0))
end

sgs.ai_skill_invoke.PlusYongyi = function(self, data)
	local target = pq(data,"toPlayer")
	return not pq(self,"isFriend",target)
end

sgs.ai_skill_invoke.PlusLiegong = function(self, data)
	local use = pq(data,"toCardUse")
	if use.from then
		return pq(self,"doDisCard",use.from,"h")
	end
	return true
end

sgs.ai_canliegong_skill.PlusLiegong = function(self, from, to)
	return pq(from,"getPhase") == sgs.Player_Play and (pq(to,"getHandcardNum") >= pq(from,"getHp") or pq(to,"getHandcardNum") <= pq(from,"getAttackRange"))
end

local PlusQimou_skill = {}
PlusQimou_skill.name = "PlusQimou"
table.insert(package_skills, PlusQimou_skill)
PlusQimou_skill.getTurnUseCard=function(self,inclusive,request)
	if (pq(self.player,"getMark","@stratagem") == 0) then return end
	if pq(self,"needBear") then return end
	if #self.enemies == 0 then return end
	if pq(self,"getRoleEstimate",self.player) == "neutral" then return end
	return parse(self,request,"#PlusQimou_Card:.:")
end
sgs.ai_skill_use_func["#PlusQimou_Card"] = function(card,use,self,request)
	local target

	local slashcount = pq(self,"getCardsNum","Slash")

	sort_players(self,self.friends_noself, "handcard", true)
	for _, friend in ipairs(self.friends_noself) do
		if friend and not pq(friend,"isKongcheng") then
			if pq(self,"needKongcheng",friend) then
				target = friend
				break
			end
			if not pq(self,"isWeak",friend) then
				target = friend
				break
			end
		end
	end
	local can_slash = false
	for _, enemy in ipairs(self.enemies) do
		local def = pq(self,"getDefenseSlash",enemy)
		local slash = call(self,"cloneEvaluationCard","slash")
		
		local eff = pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)

		if not pq(self.player,"canSlash",enemy, slash, false) then
		elseif pq(self,"slashProhibit",nil, enemy) then
		elseif def < 6 and eff then
			can_slash = true
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local slash = call(self,"cloneEvaluationCard","slash")
		
		local eff = pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)

		if not pq(self.player,"canSlash",enemy, slash, false) then
		elseif pq(self,"slashProhibit",nil, enemy) then
		elseif eff and def < 8 then
			can_slash = true
		end
	end
	local can_invoke = false
	for _, c in sgs.qlist(pq(self.player,"getHandcards")) do
		local x = nil
		if isCard("ArcheryAttack", c, self.player) then
			x = call(self,"cloneEvaluationCard","archery_attack")
		elseif isCard("SavageAssault", c, self.player) then
			x = call(self,"cloneEvaluationCard","savage_assault")
		else
			continue
		end
		

		local du = { isDummy = true }
		call(self,"useTrickCard",x, du)
		if (du.card) then can_invoke = true end
		
	end
	if target and ((slashcount > 0 and can_slash and pq(self,"slashIsAvailable")) or can_invoke) then
		local card_str = ("#PlusQimou_Card:.:")
		use.card=final_parse(self,request,card_str)
		if use.to then call(use.to,"append",target) end
	end
end
sgs.ai_use_priority["PlusQimou_Card"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_choice.PlusQimou = function(self, choices, data)
	local target = pq(data,"toPlayer")
	local give = getChoice(choices, "PlusQimou_Give")

	if target and pq(self,"isFriend",target) then
		return give
	end
	return "PlusQimou_Refuse"
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusZaiqi"
sgs.ai_skill_invoke.PlusZaiqi = sgs.ai_skill_invoke.zaiqi

sgs.ai_skill_invoke.PlusZaiqi_ss = function(self, data)
	local card = call(self,"cloneEvaluationCard","savage_assault")
	
	if pq(self,"getAoeValue",card) > 0 and ((pq(self.player,"getHandcardNum") <= 4)) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@PlusZhongyong_Slash"] = function(self, data, pattern, target)
	local cards = AIList.new(pq(self.player,"getCards","h"))
	sort_use(self,cards, true)
	for _, card in ipairs(cards) do
		if pq(card,"isRed") then
			return "$" .. pq(card,"getEffectiveId")
		end
	end
	return "."
end


sgs.ai_skill_playerchosen.PlusZhongyong = function(self, targets)
	local friends = {}
	for _, player in ipairs(self.friends) do
		if pq(player,"isAlive") and pq(self,"canDraw",player, self.player) and pq(self.player,"distanceTo",player) <= 2 then
			table.insert(friends, player)
		end
	end
	sort_players(self,friends)

	local max_x = 0
	local target

	local CP = call(self.room,"getCurrent")
	local max_x = 0
	local AssistTarget = call(self,"AssistTarget")
	for _, friend in ipairs(friends) do
		local x = math.min(pq(friend,"getMaxHp"), 5) - pq(friend,"getHandcardNum")
		if pq(self,"hasCrossbowEffect",CP) then x = x + 1 end
		if AssistTarget and pq(friend,"objectName") == pq(AssistTarget,"objectName") then x = x + 0.5 end

		if x > max_x and pq(friend,"isAlive") then
			max_x = x
			target = friend
		end
	end

	return target
end

sgs.ai_playerchosen_intention.PlusZhongyong = function(self, from, to)
	if pq(to,"getHandcardNum") < math.min(5, pq(to,"getMaxHp")) then
		call(self,"updateIntention",from, to, -80)
	end
end

sgs.ai_skill_use["@PlusZhongyong"] = function(self, prompt)
	if pq(self.player,"isKongcheng") then return "." end
	sort_players(self,self.enemies, "handcard")
	local max_card = call(self,"getMaxCard")
	local max_point = pq(max_card,"getNumber")
	local slash = call(self,"cloneEvaluationCard","slash")
	
	local dummy_use=pq(self,"withOwnerRange","slashNoDistanceLimit","@PlusZhongyong",function()return pq(self,"aiUseCard",slash)end)
	if not pq(dummy_use.to,"isEmpty") then
		for _, enemy in sgs.qlist(dummy_use.to) do
			if not (pq(enemy,"hasSkill","kongcheng") and pq(enemy,"getHandcardNum") == 1) and not pq(enemy,"isKongcheng") and pq(self.player,"canPindian",enemy) then
				local enemy_max_card = call(self,"getMaxCard",enemy)
				local enemy_max_point = enemy_max_card and pq(enemy_max_card,"getNumber") or 100
				if max_point > enemy_max_point then
					call(self,"remember","shuangren_card",pq(max_card,"getEffectiveId"))
					return "#PlusZhongyong_Card:" .. pq(max_card,"getEffectiveId") .. ":->" .. pq(enemy,"objectName")
				end
			end
		end
		for _, enemy in sgs.qlist(dummy_use.to) do
			if not (pq(enemy,"hasSkill","kongcheng") and pq(enemy,"getHandcardNum") == 1) and not pq(enemy,"isKongcheng") and pq(self.player,"canPindian",enemy) then
				if max_point >= 10 then
					call(self,"remember","shuangren_card",pq(max_card,"getEffectiveId"))
					return "#PlusZhongyong_Card" .. pq(max_card,"getEffectiveId") .. ":->" .. pq(enemy,"objectName")
				end
			end
		end
		if #self.enemies < 1 then return end
	end

	return "."
end

function sgs.ai_skill_pindian.PlusZhongyong(minusecard, self, requestor)
	local maxcard = call(self,"getMaxCard")
	return (pq(maxcard,"getNumber") < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.PlusZhongyong",registry="ai_cardneed",path={"PlusZhongyong"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
function sgs.ai_skill_invoke.PlusChouyuan(self, data)
	local use = pq(data,"toCardUse")
	local target
	for _, p in sgs.qlist(use.to) do
		if pq(p,"getMark","PlusChouyuan_target") > 0 then
			target = p
		end
	end
	if target and pq(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.PlusChouyuan = function(self,player,promptlist)
	local target
	for _,p in sgs.qlist(pq(self.room,"getOtherPlayers",player))do
		if pq(p,"getMark","PlusChouyuan_target") > 0 then target = p break end
	end
	if target then
		if promptlist[#promptlist]=="yes" then
			call(self,"updateIntention",player,target,-80)
		else
			call(self,"updateIntention",player,target,80)
		end
	end
end


sgs.ai_skill_invoke.PlusChenggui = function(self, data)
	local card = tag(self,"PlusChenggui_card"):toCard()
	if ((pq(card,"isKindOf","DefensiveHorse") and call(self.player,"getDefensiveHorse"))
			or (pq(card,"isKindOf","OffensiveHorse") and (call(self.player,"getOffensiveHorse") or (pq(self.player,"hasSkill","drmashu") and call(self.player,"getDefensiveHorse")))))
		and not pq(self.player,"hasSkills",sgs.lose_equip_skill) then
		return false
	end
	if pq(card,"isKindOf","Armor")
		and ((pq(self.player,"hasSkills","bazhen|yizhong") and not call(self.player,"getArmor"))
			or (call(self.player,"getArmor") and pq(self,"evaluateArmor",card) < pq(self,"evaluateArmor",call(self.player,"getArmor")))) then
		return false
	end
	if pq(card,"isKindOf","Weanpon") and (call(self.player,"getWeapon") and pq(self,"evaluateArmor",card) < pq(self,"evaluateArmor",call(self.player,"getWeapon"))) then return false end
	return true
end


local PlusChenggui_skill = {}
PlusChenggui_skill.name = "PlusChenggui"
table.insert(package_skills, PlusChenggui_skill)
PlusChenggui_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"isKongcheng") then return end
	if pq(self,"needBear") then return end
	if not pq(self.player,"hasUsed","#PlusChenggui") then
		return parse(self,request,"#PlusChenggui:.:")
	end
end

sgs.ai_skill_use_func["#PlusChenggui"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.friends, "handcard")
	local cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,cards)
	local use_card
	local nextAlive = self.player
	repeat
		nextAlive = pq(nextAlive,"getNextAlive")
	until pq(nextAlive,"faceUp")



	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = pq(nextAlive,"getJudgingArea")
	if not pq(tricks,"isEmpty") and not pq(nextAlive,"containsTrick","YanxiaoCard") then
		local trick = pq(tricks,"at",pq(tricks,"length") - 1)
		if pq(self,"hasTrickEffective",trick, nextAlive) then
			if pq(trick,"isKindOf","Lightning") then
				hasLightning = true
			elseif pq(trick,"isKindOf","Indulgence") then
				hasIndulgence = true
			elseif pq(trick,"isKindOf","SupplyShortage") then
				hasSupplyShortage = true
			end
		end
	end

	if hasLightning and pq(self,"isEnemy",nextAlive) and not (pq(nextAlive,"hasSkill","qiaobian") and pq(nextAlive,"getHandcardNum") > 0) then
		for _, id in ipairs(cards) do
			local card = pq(self,"getPrintedCardById",id)
			if pq(card,"getSuit") == sgs.Card_Spade and pq(card,"getNumber") >= 2 and pq(card,"getNumber") <= 9 then
				use_card = card
			end
		end
	end
	if not use_card then
		if hasIndulgence then
			if pq(self,"isFriend",nextAlive) then
				for _, card in ipairs(cards) do
					
					if pq(card,"getSuit") == sgs.Card_Heart then
						use_card = card
					end
				end
			elseif pq(self,"isEnemy",nextAlive) then
				for _, card in ipairs(cards) do
					
					if pq(card,"getSuit") ~= sgs.Card_Heart then
						use_card = card
					end
				end
			end
		end
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if not pq(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) then
			table.insert(targets, friend)
		end
	end
	if not use_card then
		use_card = cards[1]
	end


	if #targets == 0 then return end
	if not use_card then return end
	use.card=final_parse(self,request,"#PlusChenggui:" .. pq(use_card,"getId") .. ":")
	if use.to then
		call(use.to,"append",targets[1])
	end
end

sgs.ai_use_priority["PlusChenggui"] = 7
sgs.ai_use_value["PlusChenggui"] = 7


local PlusZhiheng_skill = {}
PlusZhiheng_skill.name = "PlusZhiheng"
table.insert(package_skills, PlusZhiheng_skill)
PlusZhiheng_skill.getTurnUseCard=function(self,inclusive,request)
	local has_Crossbow = false
	for _, c in ipairs(AIList.new(pq(self.player,"getCards","h"))) do
		if pq(c,"isKindOf","Crossbow") then
			has_Crossbow = true
		end
	end
	if has_Crossbow or pq(self,"hasCrossbowEffect") then
		for _, slash in ipairs(pq(self,"getCards","Slash")) do
			local dummyuse = { isDummy = true, to = AIList.new({}) }
			call(self,"useBasicCard",slash, dummyuse)
			if not pq(dummyuse.to,"isEmpty") then return end
		end
	end

	if not pq(self.player,"hasUsed","#PlusZhiheng_Card") then
		return parse(self,request,"#PlusZhiheng_Card:.:")
	end
end

sgs.ai_skill_use_func["#PlusZhiheng_Card"] = function(card,use,self,request)
	local unpreferedCards = {}
	local cards = AIList.new(pq(self.player,"getHandcards"))
	if pq(self.player,"getHp") < 3 then
		local zcards = pq(self.player,"getCards","he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = owner_fact(self,"jilve_wansha")
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = pq(self,"aiUseCard",zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if pq(p,"getHp") <= 1 then
									shouldUse = false
									if pq(self.player,"distanceTo",p) > 1 then keep_weapon = call(self.player,"getWeapon") end
									break
								end
							end
							if pq(dummy_use.to,"length") > 1 then shouldUse = false end
						end
						if not pq(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if pq(zcard,"getTypeId") == sgs.Card_TypeTrick then
					local dummy_use = pq(self,"aiUseCard",zcard)
					if dummy_use.card then shouldUse = false end
				end
				if pq(zcard,"getTypeId") == sgs.Card_TypeEquip and not pq(self.player,"hasEquip",zcard) then
					local dummy_use = pq(self,"aiUseCard",zcard)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and pq(zcard,"getEffectiveId") == pq(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if pq(self.player,"hasEquip",zcard) and pq(zcard,"isKindOf","Armor") and not pq(self,"needToThrowArmor") then shouldUse = false end
				if pq(self.player,"hasEquip",zcard) and pq(zcard,"isKindOf","DefensiveHorse") and not pq(self,"needToThrowArmor") then shouldUse = false end
				if pq(self.player,"hasEquip",zcard) and pq(zcard,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if pq(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, pq(zcard,"getId")) end
			end
		end
	end
	if #unpreferedCards == 0 then
		local use_slash_num = 0
		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if pq(card,"isKindOf","Slash") then
				local will_use = false
				if use_slash_num <= pq(card,"getTargetModResidue") then
					local dummy_use = pq(self,"aiUseCard",card)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, pq(card,"getId")) end
			end
		end

		local num = pq(self,"getCardsNum","Jink") - 1
		if call(self.player,"getArmor") then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if pq(card,"isKindOf","Jink") and num > 0 then
					table.insert(unpreferedCards, pq(card,"getId"))
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (pq(card,"isKindOf","Weapon") and pq(self.player,"getHandcardNum") < 3) or pq(card,"isKindOf","OffensiveHorse")
				or call(self,"getSameEquip",card, self.player) or pq(card,"isKindOf","AmazingGrace") then
				table.insert(unpreferedCards, pq(card,"getId"))
			elseif pq(card,"getTypeId") == sgs.Card_TypeTrick then
				local dummy_use = pq(self,"aiUseCard",card)
				if not dummy_use.card then table.insert(unpreferedCards, pq(card,"getId")) end
			end
		end

		if call(self.player,"getWeapon") and pq(self.player,"getHandcardNum") < 3 then
			table.insert(unpreferedCards, call(self.player,"getWeapon"):getId())
		end

		if pq(self,"needToThrowArmor") then
			table.insert(unpreferedCards, call(self.player,"getArmor"):getId())
		end

		if call(self.player,"getOffensiveHorse") and call(self.player,"getWeapon") then
			table.insert(unpreferedCards, call(self.player,"getOffensiveHorse"):getId())
		end
	end
	for index = #unpreferedCards, 1, -1 do
		if disclosed(self,unpreferedCards[index]):isKindOf("WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not pq(self.player,"isJilei",disclosed(self,unpreferedCards[index])) then
			table.insert(use_cards,
				unpreferedCards[index])
		end
	end

	if #use_cards > 0 then
		use.card=final_parse(self,request,"#PlusZhiheng_Card:" .. table.concat(use_cards, "+") .. ":")
		return
	end
end

sgs.ai_use_value["#PlusZhiheng_Card"] = 9
sgs.ai_use_priority["#PlusZhiheng_Card"] = 2.61
sgs.dynamic_value.benefit["#PlusZhiheng_Card"] = true


function sgs.ai_cardneed.PlusZhiheng(to, card)
	return not pq(card,"isKindOf","Jink")
end

sgs.ai_skill_choice.PlusZhiheng = function(self, choices, data)
	local max = 0
	local min = 999
	for _, p in ipairs(AIList.new(pq(self.room,"getOtherPlayers",self.player))) do
		if pq(p,"getHandcardNum") > max then
			max = pq(p,"getHandcardNum")
		end
		if pq(p,"getHandcardNum") < min then
			min = pq(p,"getHandcardNum")
		end
	end
	local friend_can_invoke = false
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getHandcardNum") == min and (not pq(self,"needKongcheng",friend, true) or hasManjuanEffect(friend)) then
			friend_can_invoke = true
		end
	end
	local enemy_can_invoke = false
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHandcardNum") == max and not hasTuntianEffect(enemy, true) then
			enemy_can_invoke = true
		end
	end
	if friend_can_invoke and enemy_can_invoke then
		return "PlusZhiheng_ok"
	end
	return "PlusZhiheng_cancel"
end


sgs.ai_skill_playerchosen["#PlusZhiheng_from"] = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if pq(self,"isEnemy",p) and not hasTuntianEffect(p, true) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["#PlusZhiheng_from"] = function(self, from, to)
	call(self,"updateIntention",from, to, 30)
end

sgs.ai_skill_playerchosen["#PlusZhiheng_to"] = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if pq(self,"isFriend",p) and (not pq(self,"needKongcheng",p, true) or hasManjuanEffect(p)) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["#PlusZhiheng_to"] = function(self, from, to)
	call(self,"updateIntention",from, to, -30)
end

sgs.ai_use_revises.PlusZhiheng = function(self, card, use)
	if pq(card,"isKindOf","Weapon")
		and not pq(card,"isKindOf","Crossbow")
		and call(self,"getSameEquip",card)
		and not pq(self.player,"hasUsed","#PlusZhiheng_Card")
	then
		return false
	end
end

local PlusFanjian_skill = {
	name = "PlusFanjian",
	getTurnUseCard=function(self,inclusive,request)
		if pq(self.player,"hasUsed","#PlusFanjian_Card") then return end
		if pq(self.player,"isNude") then return end
		local can_use = false
		sort_players(self,self.enemies, "chaofeng")
		local slash = call(self,"cloneEvaluationCard","slash")
		
		for _, enemy in ipairs(self.enemies) do
			if not pq(self,"slashIsEffective",slash, enemy) then continue end
			can_use = true
			break
		end
		if can_use then
			return parse(self,request,"#PlusFanjian_Card:.:")
		end
	end,
}
table.insert(package_skills, PlusFanjian_skill) 
sgs.ai_skill_use_func["#PlusFanjian_Card"] = function(card,use,self,request)
	local handcards = AIList.new(pq(self.player,"getCards","he"))
	local slash = call(self,"cloneEvaluationCard","slash")
	
	if #handcards == 0 then return end
	sort_use(self,handcards, true) 
	local togive = nil
	local slasher, target
	sort_players(self,self.enemies, "defense")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if pq(enemy_b,"canSlash",enemy_a) and not pq(self,"slashProhibit",slash, enemy_a) and pq(self,"getDefenseSlash",enemy_a) <= 2
				and pq(self,"slashIsEffective",slash, enemy_a) and pq(self,"isGoodTarget",enemy_a, self.enemies, slash) and pq(enemy_b,"getHandcardNum") > pq(enemy_a,"getHandcardNum") and pq(enemy_a,"objectName") ~= pq(self.player,"objectName") then
				slasher = enemy_b
				target = enemy_a
				break
			end
		end
	end
	if not slasher then
		for _, enemy in ipairs(self.enemies) do
			for _, p in ipairs(AIList.new(pq(self.room,"getOtherPlayers",enemy))) do
				if pq(p,"canSlash",enemy) and not pq(self,"slashProhibit",slash, enemy) and pq(self,"getDefenseSlash",enemy) <= 2
					and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(p,"getHandcardNum") > pq(enemy,"getHandcardNum") and pq(enemy,"objectName") ~= pq(self.player,"objectName") then
					slasher = p
					target = enemy
					break
				end
			end
		end
	end

	if slasher and target then
		togive = handcards[1]
		local card_str = string.format("#PlusFanjian_Card:%s:", pq(togive,"getEffectiveId"))
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then
			call(use.to,"append",slasher)
			call(use.to,"append",target)
		end
	end
end

sgs.ai_use_priority["PlusFanjian_Card"] = 0
sgs.ai_use_value["PlusFanjian_Card"] = 0
sgs.ai_card_intention["PlusFanjian_Card"] = 80

sgs.ai_use_revises.PlusKeji = function(self, card, use)
	if pq(card,"isKindOf","Slash") and not pq(self.player,"hasFlag","PlusKejiSlashInPlayPhase")
		and ((pq(self.player,"getMark","PlusDujiang") == 0 and pq(self.player,"hasSkill","PlusDujiang")) or pq(self.player,"getPile","slack"):length() == 0)
	then
		return false
	end
end

sgs.ai_getBestHp_skill.PlusDujiang = function(owner)
	if pq(owner,"getMark","PlusDujiang") == 0 and pq(owner,"getPile","slack"):length() >= 4 then
		return pq(owner,"getMaxHp") - 1
	end
end

local PlusDuocheng_skill = {}
PlusDuocheng_skill.name = "PlusDuocheng"
table.insert(package_skills, PlusDuocheng_skill)
PlusDuocheng_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"isKongcheng") then return end
	if not pq(self.player,"hasUsed","#PlusDuocheng_Card") then
		return parse(self,request,"#PlusDuocheng_Card:.:")
	end
end

sgs.ai_skill_use_func["#PlusDuocheng_Card"] = function(card,use,self,request)
	local useable_cards = {}
	if pq(self.player,"getPile","slack"):length() > 0 then
		for _, id in sgs.qlist(pq(self.player,"getPile","slack")) do
			table.insert(useable_cards, disclosed(self,id))
		end
	end
	if #useable_cards == 0 then return end
	local target
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"hasEquip") and not pq(self,"hasSkills",sgs.lose_equip_skill, enemy) and pq(enemy,"getEquips"):length() <= pq(self.player,"getHandcardNum") then
			target = enemy
		end
	end
	if target then
		if useable_cards[1]:hasFlag("xiahui") then return end
		local card_str = string.format("#PlusDuocheng_Card:%s:", useable_cards[1]:getEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then call(use.to,"append",target) end
	end
end

sgs.ai_use_priority["#PlusDuocheng_Card"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value["#PlusDuocheng_Card"] = 1

sgs.ai_skill_discard.PlusDuocheng = function(self, discard_num, min_num, optional, include_equip)
	return pq(self,"askForDiscard","dummyreason", discard_num, min_num, false, false)
end


sgs.ai_skill_invoke["#PlusKeji_Jink"] = function(self, data)
	local dying = 0
	local handang = call(self.room,"findPlayerBySkillName","nosjiefan")
	for _, aplayer in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(aplayer,"getHp") < 1 and not pq(aplayer,"hasSkill","nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and pq(self,"isFriend",handang) and dying > 0 then return false end

	
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isFriend",current) and pq(self.player,"isChained") and pq(self,"isGoodChainTarget",self.player, current) then return false end 
	
	

	if pq(self.player,"getHandcardNum") == 1 and pq(self,"getCardsNum","Jink") == 1 and pq(self.player,"hasSkills","zhiji|beifa") and pq(self,"needKongcheng") then
		local enemy_num = pq(self,"getEnemyNumBySeat",call(self.room,"getCurrent"), self.player, self.player)
		if pq(self.player,"getHp") > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and pq(self,"isFriend",handang) and dying > 0 then return false end
	if pq(self,"needToLoseHp",self.player, nil, nil, true, true) then return false end
	if pq(self,"getCardsNum","Jink") == 0 then return true end

	return true
end


sgs.ai_skill_use["@PlusCuorui"] = function(self, prompt)
	local target = tag(self,"PlusCuorui"):toPlayer()

	local cards = {}
	for _, c in ipairs(AIList.new(pq(self.player,"getCards","he"))) do
		table.insert(cards, pq(c,"getEffectiveId"))
	end
	if #cards > 0 and target and pq(self,"isFriend",target) then
		return "#PlusCuorui_DummyCard:" .. cards[1] .. ":"
	end
	return "."
end


sgs.ai_getLeastHandcardNum_skill.PlusDuoshi = function(self, player, least)
	if least < 1 then
		return 1
	end
end


local PlusQixi_skill = {}
PlusQixi_skill.name = "PlusQixi"
table.insert(package_skills, PlusQixi_skill)
PlusQixi_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasFlag","PlusQixi_used") then return end
	local cards = pq(self.player,"getCards","he")
	cards = AIList.new(cards)

	if pq(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local black_card

	sort_use(self,cards, true)

	local has_weapon = false

	for _, card in ipairs(cards) do
		if pq(card,"isKindOf","Weapon") and pq(card,"isBlack") then has_weapon = true end
	end

	for _, card in ipairs(cards) do
		if pq(card,"isBlack") and ((pq(self,"getUseValue",card) < sgs.ai_use_value.Dismantlement) or inclusive or pq(self,"getOverflow") > 0) then
			local shouldUse = true

			if pq(card,"isKindOf","Armor") then
				if not call(self.player,"getArmor") then
					shouldUse = false
				elseif pq(self.player,"hasEquip",card) and not pq(self,"needToThrowArmor") then
					shouldUse = false
				end
			end

			if pq(card,"isKindOf","Weapon") then
				if not call(self.player,"getWeapon") then
					shouldUse = false
				elseif pq(self.player,"hasEquip",card) and not has_weapon then
					shouldUse = false
				end
			end

			if pq(card,"isKindOf","Slash") then
				local dummy_use = { isDummy = true }
				if pq(self,"getCardsNum","Slash") == 1 then
					local dummy_use = pq(self,"aiUseCard",card)
					if dummy_use.card then shouldUse = false end
				end
			end

			if pq(self,"getUseValue",card) > sgs.ai_use_value.Dismantlement and pq(card,"isKindOf","TrickCard") then
				local dummy_use = pq(self,"aiUseCard",card)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
		end
	end

	if black_card then
		local suit = pq(black_card,"getSuitString")
		local number = pq(black_card,"getNumberString")
		local card_id = pq(black_card,"getEffectiveId")
		local card_str = ("dismantlement:PlusQixi[%s:%s]=%d"):format(suit, number, card_id)
		local dismantlement = parse(self,request,card_str)

		assert(dismantlement)

		return dismantlement
	end
end

sgs.PlusQixi_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.PlusQixi(to, card)
	return pq(card,"isBlack")
end

sgs.ai_skill_invoke.PlusQixi = function(self, data)
	local target = pq(data,"toPlayer")
	if pq(self,"isEnemy",target) then
		return pq(self,"doDisCard",target, "hej")
	end
	if pq(self,"isFriend",target) then
		return pq(self,"needToThrowArmor",target) or pq(self,"doDisCard",target, "hej") or pq(target,"getJudgingArea"):length() > 0
	end
	return not pq(self,"isFriend",target)
end

sgs.ai_skill_cardask["@PlusQixi_prompt"] = function(self, data, pattern, target)
	local move = pq(data,"toMoveOneTime")
	local card_id = pq(move.card_ids,"first")
	local cd = disclosed(self,card_id)
	local cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		if pq(self,"getKeepValue",card) < pq(self,"getKeepValue",cd) then
			return "$" .. pq(card,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_use_revises.PlusQixi = function(self, card, use)
	if pq(card,"isKindOf","EquipCard")
		and pq(card,"isBlack")
	then
		same = call(self,"getSameEquip",card)
		if same and pq(same,"isBlack")
		then
			return false
		end
	end
end

local PlusKurou_skill = {}
PlusKurou_skill.name = "PlusKurou"
table.insert(package_skills, PlusKurou_skill)
PlusKurou_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#PlusKurou_Card") then return end
	local func = nil -- fixed classical_func has no PlusKurou entry
	if func then return func(self, nil) end
	self:setPriorityValue("#PlusKurou_Card",6.8)
	local losthp = pq(self.player,"isLord") and 0 or 1
	if ((pq(self.player,"getHp") > 3 and pq(self.player,"getLostHp") <= losthp and pq(self.player,"getHandcardNum") > pq(self.player,"getHp"))
			or (pq(self.player,"getHp") - pq(self.player,"getHandcardNum") >= 2)) and not (pq(self.player,"isLord") and pq(self.room,"getTurnCount") <= 1) then
		return parse(self,request,"#PlusKurou_Card:.:")
	end
	local slash = call(self,"cloneEvaluationCard","slash")
	
	if (call(self.player,"getWeapon") and call(self.player,"getWeapon"):isKindOf("Crossbow")) or pq(self.player,"hasSkill","paoxiao") then
		for _, enemy in ipairs(self.enemies) do
			if pq(self.player,"canSlash",enemy, nil, true) and pq(self,"slashIsEffective",slash, enemy)
				and not (pq(enemy,"hasSkill","kongcheng") and pq(enemy,"isKongcheng"))
				and not (pq(enemy,"hasSkills","fankui|guixin") and not pq(self.player,"hasSkill","paoxiao"))
				and not pq(enemy,"hasSkills","fenyong|jilei|zhichi")
				and pq(self,"isGoodTarget",enemy, self.enemies, slash) and not pq(self,"slashProhibit",slash, enemy) and pq(self.player,"getHp") > 1 then
				return parse(self,request,"#PlusKurou_Card:.:")
			end
		end
	end
	if pq(self.player,"getHp") == 1 and pq(self,"getCardsNum","Analeptic") >= 1 then
		return parse(self,request,"#PlusKurou_Card:.:")
	end

	
	local nextplayer = pq(self.player,"getNextAlive")
	if pq(self.player,"getHp") == 1 and role(self,self.player) ~= "lord" and role(self,self.player) ~= "renegade" then
		local to_death = false
		if pq(self,"isFriend",nextplayer) then
			for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
				if pq(p,"hasSkill","xiaoguo") and not pq(self,"isFriend",p) and not pq(p,"isKongcheng")
					and self.role == "rebel" and pq(self.player,"getEquips"):isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not pq(self,"willSkipPlayPhase",nextplayer) then
				if pq(nextplayer,"hasSkill","jieyin") and pq(self.player,"isMale") then return end
				if pq(nextplayer,"hasSkill","qingnang") then return end
			end
		end
		if role(self,self.player) == "rebel" and not pq(self,"isFriend",nextplayer) then
			if not pq(self,"willSkipPlayPhase",nextplayer) or pq(nextplayer,"hasSkill","shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if role(self,self.player) == "loyalist" then
			if lord and pq(lord,"getCards","he"):isEmpty() then return end
			if pq(self,"isEnemy",nextplayer) and not pq(self,"willSkipPlayPhase",nextplayer) then
				if pq(nextplayer,"hasSkills","noslijian|lijian") and pq(self.player,"isMale") and lord and pq(lord,"isMale") then
					to_death = true
				elseif pq(nextplayer,"hasSkill","quhu") and lord and pq(lord,"getHp") > pq(nextplayer,"getHp") and not pq(lord,"isKongcheng")
					and pq(lord,"inMyAttackRange",self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = call(self.room,"findPlayerBySkillName","xingshang")
			if caopi and pq(self,"isEnemy",caopi) then
				if role(self,self.player) == "rebel" and pq(self.player,"getHandcardNum") > 3 then to_death = false end
				if role(self,self.player) == "loyalist" and lord and pq(lord,"getCardCount",true) + 2 <= pq(self.player,"getHandcardNum") then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and pq(self.player,"aliveCount") == 2 then to_death = false end
		end
		if to_death then
			call(self,"setStrategyPlayerFlag",self.player,"NosKurou_toDie",true)
			self:setPriorityValue("NosKurouCard",0)
			return parse(self,request,"#PlusKurou_Card:.:")
		end
		call(self,"setStrategyPlayerFlag",self.player,"NosKurou_toDie",false)
	end
end

sgs.ai_skill_use_func["#PlusKurou_Card"] = function(card,use,self,request)
	if not use.isDummy then call(self,"speak","noskurou") end
	use.card = card
end

sgs.ai_use_priority["#PlusKurou_Card"] = 6.8


sgs.ai_skill_playerchosen["PlusKurou"] = function(self, targets)
	return self.player
end


sgs.ai_skill_choice.PlusKurou = function(self, choices, data)
	return "PlusKurou_Draw"
end

local PlusZhaxiang_skill = { name = "PlusZhaxiang" }
table.insert(package_skills, PlusZhaxiang_skill)
function PlusZhaxiang_skill.getTurnUseCard(self)
	if pq(self.player,"getMark","@surrender") < 1 then return end
	if pq(self.player,"getHp") > 1 then return end
	if pq(self,"needBear") then return end
	if (#self.friends > 1) or (#self.enemies == 1 and pq(self.room,"getTurnCount") > 1) then
		if pq(self,"getAllPeachNum") == 0 and pq(self.player,"getHp") == 1 then
			for _, enemy in ipairs(self.enemies) do
				if pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire, self.player) and pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, self.player) and pq(enemy,"isChained") then
					return parse(self,request,"#PlusZhaxiang_Card:.:")
				end
			end
			if self.role == "rebel" then
				local can_invoke = true
				for _, friend in ipairs(self.friends_noself) do
					if pq(self,"damageIsEffective",friend, sgs.DamageStruct_Fire, self.player) and pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, self.player) and pq(friend,"isChained") then
						can_invoke = false
						break
					end
				end
				if can_invoke then
					return parse(self,request,"#PlusZhaxiang_Card:.:")
				end
			end
		end
		if pq(self,"isWeak") and self.role == "rebel" and call(self.room,"getLord"):isChained() then
			return parse(self,request,"#PlusZhaxiang_Card:.:")
		end
	end
end

sgs.ai_skill_use_func["#PlusZhaxiang_Card"] = function(card,use,self,request)
	use.card = card
end


sgs.ai_skill_use["@PlusLiuli"] = function(self, prompt, method)
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isFriend",current) and pq(self,"isGoodChainTarget",self.player, current) then return "." end
	local others = pq(self.room,"getOtherPlayers",self.player)
	local slash = tag(self,"liuli-card"):toCard()
	others = AIList.new(others)
	local source
	for _, player in ipairs(others) do
		if pq(player,"hasFlag","LiuliSlashSource") then
			source = player
			break
		end
	end
	sort_players(self,self.enemies, "defense")

	local doLiuli = function(who)
		if not pq(self,"isFriend",who) and pq(who,"hasSkills","leiji|nosleiji|olleiji")
			and (pq(self,"hasSuit","spade", true, who) or pq(who,"getHandcardNum") >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or pq(self,"hasEightDiagramEffect",who)) then
			return "."
		end
		local cards = pq(self.player,"getCards","h")
		cards = AIList.new(cards)
		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if not pq(self.player,"isCardLimited",card, method) and pq(who,"isMale") and ((pq(self.player,"distanceTo",who) <= 2 and not pq(card,"isKindOf","OffensiveHorse")) or
					(pq(self.player,"distanceTo",who, 1) <= 2) and pq(card,"isKindOf","OffensiveHorse")) then
				if pq(self,"isFriend",who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "#PlusLiuli_Card:" .. pq(card,"getEffectiveId") .. ":->" .. pq(who,"objectName")
				else
					return "#PlusLiuli_Card:" .. pq(card,"getEffectiveId") .. ":->" .. pq(who,"objectName")
				end
			end
		end
		local cards = pq(self.player,"getCards","e")
		cards = AIList.new(cards)
		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if not pq(self.player,"isCardLimited",card, method) and pq(who,"isMale") and ((pq(self.player,"distanceTo",who) <= 2 and not pq(card,"isKindOf","OffensiveHorse")) or
					(pq(self.player,"distanceTo",who, 1) <= 2) and pq(card,"isKindOf","OffensiveHorse")) then
				return "#PlusLiuli_Card:" .. pq(card,"getEffectiveId") .. ":->" .. pq(who,"objectName")
			end
		end
		return "."
	end
	for _, enemy in ipairs(self.enemies) do
		if not (source and pq(source,"objectName") == pq(enemy,"objectName")) then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if pq(self,"objectiveLevel",player) == 0 and not (source and pq(source,"objectName") == pq(player,"objectName")) then
			local ret = doLiuli(player)
			if ret ~= "." then return ret end
		end
	end

	sort_players(self,self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)


	for _, friend in ipairs(self.friends_noself) do
		if (not (pq(self,"slashIsEffective",slash, friend, source)) or call(self,"findLeijiTarget",friend, 50, source)) then
			if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if pq(self,"needToLoseHp",friend, source, slash) then
			if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end
	if (pq(self,"isWeak") or pq(self,"hasHeavyDamage",source, slash)) and pq(source,"hasWeapon","axe") and pq(source,"getCards","he"):length() > 2
		and not call(self,"getCardId","Peach") and not call(self,"getCardId","Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"isWeak",friend) then
				if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	if (pq(self,"isWeak") or pq(self,"hasHeavyDamage",source, slash)) and not call(self,"getCardId","Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"isWeak",friend) or (pq(self,"hasEightDiagramEffect",friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention["#PlusLiuli_Card"] = function(self, card, from, to)
	call(self,"setCommonEventMemory","ai_liuli_effect",true)
	if not pq(self,"hasExplicitRebel") then
		call(self,"setCommonEventMemory","ai_liuli_user",from)
	else
		call(self,"setCommonEventMemory","ai_liuli_user",nil)
	end
end

function sgs.ai_slash_prohibit.PlusLiuli(self, from, to, card)
	if pq(self,"isFriend",to, from) then return false end
	if pq(from,"hasFlag","NosJiefanUsed") then return false end
	if pq(to,"isNude") then return false end
	for _, friend in ipairs(pq(self,"getFriends",from, true)) do
		if pq(to,"distanceTo",friend) <= 2 and pq(friend,"isMale") and pq(self,"slashIsEffective",card, friend, from) then return true end
	end
end

function sgs.ai_cardneed.PlusLiuli(to, card)
	return pq(to,"getCards","he"):length() <= 2
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusJieyin"

local PlusJieyin_skill = {}
PlusJieyin_skill.name = "PlusJieyin"
table.insert(package_skills, PlusJieyin_skill)
PlusJieyin_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getHandcardNum") < 2 then return nil end
	if pq(self.player,"hasUsed","#PlusJieyin_Card") then return nil end
	if pq(self,"needBear") and not pq(self.player,"isWounded") and not pq(self,"isWeak") then return nil end

	local cards = pq(self.player,"getHandcards")
	cards = AIList.new(cards)

	local first, second
	sort_use(self,cards, true)
	for _, card in ipairs(cards) do
		if pq(card,"isKindOf","TrickCard") then
			local dummy_use = pq(self,"aiUseCard",card)
			if not dummy_use.card then
				if not first then
					first = pq(card,"getEffectiveId")
				elseif first and not second then
					second = pq(card,"getEffectiveId")
				end
			end
			if first and second then break end
		end
	end

	for _, card in ipairs(cards) do
		if pq(card,"getTypeId") ~= sgs.Card_TypeEquip and (not pq(self,"isValuableCard",card) or pq(self.player,"isWounded")) then
			if not first then
				first = pq(card,"getEffectiveId")
			elseif first and first ~= pq(card,"getEffectiveId") and not second then
				second = pq(card,"getEffectiveId")
			end
		end
		if first and second then break end
	end

	if not second or not first then return end
	local card_str = ("#PlusJieyin_Card:%d+%d:"):format(first, second)
	assert(card_str)
	return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#PlusJieyin_Card"] = function(card,use,self,request)
	local target = nil
	local others = pq(self.room,"getOtherPlayers",self.player)
	for _, other in sgs.qlist(others) do
		if pq(other,"getMark","@match") > 0 and pq(other,"isMale") then
			target = other
			break
		end
	end
	local can_invoke = false
	if target and pq(target,"isLord") then
		if pq(target,"getMark","hunzi") == 0 and pq(target,"hasSkill","hunzi") and pq(self,"getEnemyNumBySeat",self.player, target) <= (pq(target,"getHp") >= 2 and 1 or 0) then
			return
		elseif pq(self,"needToLoseHp",target, nil, nil, true, true) then
			return
		elseif not pq(self,"isLordHealthy") then
			can_invoke = true
		end
	else
		if pq(self,"needToLoseHp",target, nil, nil, nil, true) or (pq(self,"hasSkills","rende|kuanggu|zaiqi", target) and pq(target,"getHp") >= 2) then
			return
		else
			can_invoke = true
		end
	end

	if target and can_invoke then
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
end




sgs.ai_skill_use["@PlusLiangyuan"] = function(self, prompt, method)
	local min = 999
	for _, friend in ipairs(AIList.new(pq(self.room,"getOtherPlayers",self.player))) do
		if pq(friend,"getHandcardNum") < min then
			min = pq(friend,"getHandcardNum")
		end
	end
	if self.role == "loyalist" and call(self.room,"getLord"):isMale() and (call(self.room,"getLord"):getHandcardNum() == min or call(self.room,"getLord"):isWounded()) then
		return "#PlusLiangyuan_Card:.:->" .. call(self.room,"getLord"):objectName()
	end
	for _, friend in ipairs(self.friends_noself) do
		if (pq(friend,"getHandcardNum") == min or pq(friend,"isWounded")) and pq(friend,"isMale") then
			return "#PlusLiangyuan_Card:.:->" .. pq(friend,"objectName")
		end
	end

	return "."
end


sgs.ai_card_intention["#PlusLiangyuan_Card"] = -80

sgs.ai_skill_invoke.PlusYinli = function(self, data)
	return true
end
sgs.ai_skill_askforag.PlusYinli = function(self, card_ids)
	if pq(self,"needKongcheng",self.player, true) then return card_ids[1] else return -1 end
end

sgs.ai_skill_invoke.PlusHongyan = function(self, data)
	local target = pq(data,"toPlayer")
	if target and pq(self,"isFriend",target) then
		return true
	end

	return false
end

sgs.ai_skill_askforag.PlusHongyan = function(self, card_ids)
	if pq(self,"needKongcheng",self.player, true) then return card_ids[1] else return -1 end
end


sgs.ai_skill_use["@PlusTianxiang"] = function(self, prompt, method)
	sort_players(self,self.enemies, "defense")
	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local use_card
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) and pq(card,"getSuit") == sgs.Card_Heart then
			use_card = card
		end
	end
	local target
	for _, friend in ipairs(self.friends_noself) do
		if pq(self,"ImitateResult_DrawNCards",friend, pq(friend,"getVisibleSkillList",true)) > 2 then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if pq(friend,"hasSkill",sgs.cardneed_skill) then
				target = friend
				break
			end
		end
	end
	

	if not target then
		for _, enemy in ipairs(self.enemies) do
			if pq(self,"getOverflow",enemy) > 3 or pq(enemy,"hasSkill","yongsi") then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			target = friend
			break
		end
	end



	if use_card and target then
		return "#PlusTianxiang_Card:" .. pq(use_card,"getEffectiveId") .. ":->" .. pq(target,"objectName")
	end

	return "."
end

sgs.ai_skill_choice["PlusTianxiang"] = function(self, choices, data)
	local target = pq(data,"toPlayer")
	local items = pq(choices,"split","+")
	if #items == 1 then
		return items[1]
	else
		if pq(self,"isEnemy",target) then
			return "PlusTianxiang_Discard"
		end
	end
	return "PlusTianxiang_Draw"
end





sgs.ai_skill_askforag.PlusBuqu = function(self, card_ids)
	for i, card_id in ipairs(card_ids) do
		for j, card_id2 in ipairs(card_ids) do
			if i ~= j and disclosed(self,card_id):getNumber() == disclosed(self,card_id2):getNumber() then
				return card_id
			end
		end
	end

	return card_ids[1]
end



function sgs.ai_skill_invoke.PlusBuqu(self, data)
	if #self.enemies == 1 and self.enemies[1]:hasSkill("guhuo") then
		return false
	else
		return true
	end
end

sgs.ai_hasBuquEffect_skill.PlusBuqu = function(player)
	return pq(player,"getPile","Plushurt"):length() <= 4
end

sgs.save_skill = sgs.save_skill .. "|PlusHuzhu"
function sgs.ai_skill_invoke.PlusHuzhu(self, data)
	local dying = pq(data,"toDying")
	local target = dying.who
	if target and pq(self,"isFriend",target) then
		return true
	end
	return false
end

function sgs.ai_skill_invoke.PlusBiyou(self, data)
	local target = pq(data,"toPlayer")
	if target and pq(self,"isFriend",target) then
		return not pq(self,"isWeak")
	end
	return false
end

function sgs.ai_skill_invoke.PlusLiangjie(self, data)
	return true
end

function sgs.ai_skill_invoke.PlusQiaojian(self, data)
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isFriend",current) then
		if not pq(current,"containsTrick","YanxiaoCard") then
			if (pq(current,"containsTrick","lightning") and not pq(self,"hasWizard",self.friends) and pq(self,"hasWizard",self.enemies))
				or (pq(current,"containsTrick","lightning") and #self.friends > #self.enemies) then
				return true
			elseif pq(current,"containsTrick","supply_shortage") then
				
				return true
			elseif pq(current,"containsTrick","indulgence") then
				if pq(self.player,"getHandcardNum") > 3 or pq(self.player,"getHandcardNum") > pq(self.player,"getHp") - 1 then return true end
				for _, friend in ipairs(self.friends_noself) do
					if not pq(friend,"containsTrick","YanxiaoCard") and (pq(friend,"containsTrick","indulgence") or pq(friend,"containsTrick","supply_shortage")) then
						return true
					end
				end
			end
		end
	end
	return false
end

sgs.ai_skill_cardask["@PlusQiaojian_Prompt"] = function(self, data, pattern, target, target2)
	local suit = pq(pattern,"split","|")[2]
	local current = call(self.room,"getCurrent")
	local usable_cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,usable_cards)
	local give_card = {}
	if pq(self,"isFriend",current) then
		for _, c in ipairs(usable_cards) do
			if pq(c,"getSuitString") == suit then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:getLegacyStringKey()
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@PlusQiaojian_Prompt"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player, current, -60)
	end
end



sgs.ai_skill_use["@PlusJiahuo"] = function(self, prompt, method)
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isFriend",current) and pq(self,"isGoodChainTarget",self.player, current) then return "." end

	local others = pq(self.room,"getOtherPlayers",self.player)
	local slash = tag(self,"liuli-card"):toCard()
	others = AIList.new(others)
	local source
	for _, player in ipairs(others) do
		if pq(player,"hasFlag","LiuliSlashSource") then
			source = player
			break
		end
	end
	sort_players(self,self.enemies, "defense")

	local doLiuli = function(who)
		if not pq(self,"isFriend",who) and pq(who,"hasSkills","leiji|nosleiji|olleiji")
			and (pq(self,"hasSuit","spade", true, who) or pq(who,"getHandcardNum") >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or pq(self,"hasEightDiagramEffect",who)) then
			return "."
		end

		if (pq(self.player,"canSlash",who)) then
			if pq(self,"isFriend",who) then
				return "#PlusJiahuo_Card:.:->" .. pq(who,"objectName")
			else
				return "#PlusJiahuo_Card:.:->" .. pq(who,"objectName")
			end
		end

		if pq(self.player,"canSlash",who) then
			return "#PlusJiahuo_Card:.:->" .. pq(who,"objectName")
		end
		return "."
	end

	for _, enemy in ipairs(self.enemies) do
		if not (source and pq(source,"objectName") == pq(enemy,"objectName")) then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if pq(self,"objectiveLevel",player) == 0 and not (source and pq(source,"objectName") == pq(player,"objectName")) then
			local ret = doLiuli(player)
			if ret ~= "." then return ret end
		end
	end


	sort_players(self,self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)


	for _, friend in ipairs(self.friends_noself) do
		if not pq(self,"slashIsEffective",slash, friend) or call(self,"findLeijiTarget",friend, 50, source) then
			if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if pq(self,"needToLoseHp",friend, source, nil) then
			if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	if (pq(self,"isWeak") or pq(self,"hasHeavyDamage",source, slash)) and pq(source,"hasWeapon","axe") and pq(source,"getCards","he"):length() > 2
		and not call(self,"getCardId","Peach") and not call(self,"getCardId","Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"isWeak",friend) then
				if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end

	if (pq(self,"isWeak") or pq(self,"hasHeavyDamage",source, slash)) and not call(self,"getCardId","Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"isWeak",friend) or (pq(self,"hasEightDiagramEffect",friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and pq(source,"objectName") == pq(friend,"objectName")) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end


function sgs.ai_slash_prohibit.PlusJiahuo(self, from, to, card)
	if pq(self,"isFriend",to, from) then return false end
	if pq(from,"hasFlag","NosJiefanUsed") then return false end
	for _, friend in ipairs(pq(self,"getFriends",from, true)) do
		if pq(to,"canSlash",friend) and pq(self,"slashIsEffective",card, friend, from) then return not pq(to,"faceUp") end
	end
end

local PlusZenhui_skill = {
	name = "PlusZenhui",
	getTurnUseCard=function(self,inclusive,request)
		if pq(self.player,"hasUsed","#PlusZenhui_Card") then return end
		local can_use = false
		sort_players(self,self.enemies, "chaofeng")
		for _, enemy_a in ipairs(self.enemies) do
			for _, enemy_b in ipairs(self.enemies) do
				if pq(enemy_b,"getHp") == pq(enemy_a,"getHp") then continue end
				if pq(enemy_a,"objectName") == pq(enemy_b,"objectName") then continue end
				can_use = true
				break
			end
			if can_use == true then break end
		end
		if can_use then
			return parse(self,request,"#PlusZenhui_Card:.:")
		end
	end,
}
table.insert(package_skills, PlusZenhui_skill) 
sgs.ai_skill_use_func["#PlusZenhui_Card"] = function(card,use,self,request)
	local handcards = pq(self.player,"getHandcards")
	local blacks = {}
	for _, c in sgs.qlist(handcards) do
		if pq(c,"getSuit") == sgs.Card_Spade then
			table.insert(blacks, c) 
		end
	end
	if #blacks == 0 then return end
	sort_use(self,blacks, true) 
	local togive = nil
	sort_players(self,self.enemies, "chaofeng")
	local weak_enemy = {}
	local kong_enemy = {}
	local kong_weak = {}
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"isWeak",enemy) and not pq(enemy,"isKongcheng") then
			table.insert(weak_enemy, enemy)
		elseif not pq(self,"isWeak",enemy) and pq(enemy,"isKongcheng") then
			if hasManjuanEffect(enemy) or pq(enemy,"hasSkill","qingjian") then continue end
			table.insert(kong_enemy, enemy)
		elseif pq(self,"isWeak",enemy) and pq(enemy,"isKongcheng") then
			table.insert(weak_enemy, enemy)
			if hasManjuanEffect(enemy) or pq(enemy,"hasSkill","qingjian") then continue end
			table.insert(kong_enemy, enemy)
			table.insert(kong_weak, enemy)
		end
	end
	if #weak_enemy == 0 then return end
	local lost_enemy = nil
	local dis_enemy = nil
	if #kong_weak > 0 then
		for _, enemy_a in ipairs(kong_weak) do
			for _, enemy_b in ipairs(self.enemies) do
				if pq(enemy_b,"getHp") == pq(enemy_a,"getHp") then continue end
				if pq(enemy_a,"objectName") == pq(enemy_b,"objectName") then continue end
				dis_enemy = enemy_b
				break
			end
			if dis_enemy then
				lost_enemy = enemy_a
				break
			end
		end
	end
	if not lost_enemy then
		if #weak_enemy > 1 then
			for _, enemy_a in ipairs(weak_enemy) do
				for _, enemy_b in ipairs(self.enemies) do
					if pq(enemy_b,"getHp") == pq(enemy_a,"getHp") then continue end
					if pq(enemy_a,"objectName") == pq(enemy_b,"objectName") then continue end
					if not pq(self,"isWeak",enemy_b) then continue end
					togive = blacks[1]
					if pq(enemy_a,"getCardCount",true) > pq(enemy_b,"getCardCount",true) then
						if pq(enemy_b,"getCardCount",true) > 1 then
							lost_enemy = enemy_a
							dis_enemy = enemy_b
						else
							lost_enemy = enemy_b
							dis_enemy = enemy_a
						end
					else
						if pq(enemy_a,"getCardCount",true) > 1 then
							lost_enemy = enemy_b
							dis_enemy = enemy_a
						else
							lost_enemy = enemy_a
							dis_enemy = enemy_b
						end
					end
					break
				end
				if togive then break end
			end
		end
		if not lost_enemy then
			for _, enemy_a in ipairs(weak_enemy) do
				for _, enemy_b in ipairs(self.enemies) do
					if pq(enemy_b,"getHp") == pq(enemy_a,"getHp") then continue end
					if pq(enemy_a,"objectName") == pq(enemy_b,"objectName") then continue end

					dis_enemy = enemy_b
					break
				end
				if not dis_enemy and #kong_enemy > 0 then
					for _, enemy_b in ipairs(kong_enemy) do
						if pq(enemy_a,"objectName") == pq(enemy_b,"objectName") then continue end
						if pq(enemy_b,"getHp") == pq(enemy_a,"getHp") then continue end
						dis_enemy = enemy_b
						break
					end
				end
				if dis_enemy then
					lost_enemy = enemy_a
					break
				end
			end
		end
	end
	if lost_enemy and dis_enemy then
		togive = blacks[1]
		local card_str = string.format("#PlusZenhui_Card:%s:", pq(togive,"getEffectiveId"))
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then
			if pq(dis_enemy,"isKongcheng") then
				call(use.to,"append",dis_enemy)
				call(use.to,"append",lost_enemy)
			else
				call(use.to,"append",lost_enemy)
				call(use.to,"append",dis_enemy)
			end
		end
	end
end

sgs.ai_use_priority["PlusZenhui_Card"] = 0
sgs.ai_use_value["PlusZenhui_Card"] = 0
sgs.ai_card_intention["PlusZenhui_Card"] = 80

sgs.ai_skill_choice["PlusZenhui"] = function(self, choices, data)
	local target = pq(data,"toPlayer")
	local items = pq(choices,"split","+")
	if #items == 1 then
		return items[1]
	else
		if pq(self,"isEnemy",target) then
			return "PlusZenhui_Damage"
		elseif pq(self,"isFriend",target) then
			if pq(self,"isWeak",target) then
				return "PlusZenhui_Discard"
			elseif pq(self,"damageIsEffective",target, sgs.DamageStruct_Normal, self.player) and pq(self,"needToLoseHp",target, self.player, nil) then
				return "PlusZenhui_Damage"
			end
		end
	end
	return "PlusZenhui_Discard"
end



local PlusSheji_skill = { name = "PlusSheji" }
table.insert(package_skills, PlusSheji_skill)
PlusSheji_skill.getTurnUseCard=function(self,inclusive,request)
	call(self,"updatePlayers")
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"isWeak",enemy) then
			has_weak_enemy = true
		end
	end
	if (pq(self.player,"isKongcheng")) then return end
	if not has_weak_enemy then
		if pq(self,"getCardsNum","Peach") > 0 or pq(self,"getCardsNum","Duel") > 0
			or (pq(self,"getCardsNum","Analeptic") > 0 and pq(self,"isWeak"))
			or (pq(self,"getCardsNum","Jink") > 0 and pq(self,"isWeak"))
			or pq(self,"getCardsNum","SupplyShortage") > 0 or pq(self,"getCardsNum","Indulgence") > 0
			or pq(self,"getCardsNum","ArcheryAttack") > 0 or pq(self,"getCardsNum","SavageAssault") > 0
		then
			return
		end
	end

	if pq(self.player,"getHandcardNum") > 1 then
		for _, c in sgs.qlist(pq(self.player,"getHandcards")) do
			if not pq(c,"isKindOf","Analeptic") then
				if pq(self,"willUse",self.player, c) or pq(c,"isAvailable",self.player) then return end
			end
		end
	end
	local slash=turn_normal(self,"PlusSheji","slash",ids(pq(self.player,"getHandcards")),request)
	return slash
end
sgs.ai_use_priority.PlusSheji_skill = sgs.ai_use_priority.Slash - 0.1

function sgs.ai_cardsview.PlusSheji(self, class_name, player)
	if pq(player,"getPhase") ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(pq(player,"getCards","h")) do
			if pq(c,"isKindOf","Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			local c=owner_normal(self,"PlusSheji","slash",ids(pq(player,"getHandcards")))
			return pq(c,"getLegacyStringKey")
		end
	end
end

sgs.ai_card_priority.PlusSheji = function(self, card)
	if pq(card,"isKindOf","Slash") and pq(self.player,"getHandcardNum") < 4 and table.contains(pq(card,"getSkillNames"), "PlusSheji")
	then
		return 1
	end
end

sgs.save_skill = sgs.save_skill .. "|PlusMafei"

sgs.ai_use_revises.PlusMafei = function(self, card, use)
	if pq(card,"isKindOf","EquipCard")
		and pq(card,"isRed")
	then
		same = call(self,"getSameEquip",card)
		if same and pq(same,"isRed")
		then
			return false
		end
	end
end

sgs.ai_target_revises.PlusMafei = function(to, card)
	if (pq(card,"isKindOf","Slash")
			or pq(card,"isNDTrick")) and pq(to,"hasFlag","PlusMafei")
	then
		return true
	end
end

sgs.PlusMafei_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.PlusMafei = function(to, card)
	return pq(card,"isRed")
end

sgs.ai_skill_cardask["@PlusMafei_Prompt"] = function(self, data, pattern, target, target2)
	local dying = pq(data,"toDying")
	local target = dying.who
	local usable_cards = AIList.new(pq(self.player,"getCards","he"))
	sort_keep(self,usable_cards)
	local give_card = {}
	if pq(self,"isFriend",target) then
		for _, c in ipairs(usable_cards) do
			if pq(c,"isRed") then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:getLegacyStringKey()
		end
	end
	return "."
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusXuanhu"

sgs.ai_use_revises.PlusXuanhu = function(self, card, use)
	if pq(card,"isKindOf","Slash") and pq(self,"isWeak")
		and pq(self,"getOverflow") <= 0
	then
		return false
	end
end

local PlusXuanhu_skill = {}
PlusXuanhu_skill.name = "PlusXuanhu"
table.insert(package_skills, PlusXuanhu_skill)
PlusXuanhu_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getHandcardNum") < 1 then return nil end
	if pq(self.player,"hasUsed","#PlusXuanhu_Card") then return nil end

	local cards = pq(self.player,"getHandcards")
	cards = AIList.new(cards)

	local compare_func = function(a, b)
		local v1 = pq(self,"getKeepValue",a) + (pq(a,"isRed") and 50 or 0) + (pq(a,"isKindOf","Peach") and 50 or 0)
		local v2 = pq(self,"getKeepValue",b) + (pq(b,"isRed") and 50 or 0) + (pq(b,"isKindOf","Peach") and 50 or 0)
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("#PlusXuanhu_Card:%d:"):format(cards[1]:getId())
	return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#PlusXuanhu_Card"] = function(card,use,self,request)
	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	local target = nil

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1]) or pq(self,"getOverflow") >= 1) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
	if pq(self,"getOverflow") > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not pq(friend,"hasSkills","hunzi|longhun") then
				use.card = card
				if use.to then call(use.to,"append",friend) end
				return
			end
		end
	end
end

sgs.ai_use_priority["#PlusXuanhu_Card"] = 4.2
sgs.ai_card_intention["#PlusXuanhu_Card"] = -100

sgs.dynamic_value.benefit["#PlusXuanhu_Card"] = true



sgs.ai_skill_playerchosen.PlusQingnang = function(self, targets)
	local first, second
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _, friend in ipairs(targets) do
		if pq(self,"isFriend",friend) and pq(friend,"isAlive") then
			if pq(friend,"isLord") and pq(self,"isWeak",friend) then return friend end
			if not (pq(friend,"hasSkill","zhiji") and pq(friend,"getMark","zhiji") == 0 and not pq(self,"isWeak",friend) and pq(friend,"getPhase") == sgs.Player_NotActive) then
				if pq(self,"getRoleEstimate",friend) == "renegade" then
					second = friend
				elseif pq(self,"getRoleEstimate",friend) ~= "renegade" and not first then
					first = friend
				end
			end
		end
	end
	if first then return first end
	if second then return second end
	for _, friend in ipairs(targets) do
		if pq(self,"isFriend",friend) then
			return friend
		end
	end
	return nil
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|PlusQingnang"

sgs.ai_skill_choice["PlusQingnang"] = function(self, choices, data)
	local target = pq(data,"toPlayer")
	local items = pq(choices,"split","+")
	if #items == 1 then
		return items[1]
	else
		if pq(self,"isFriend",target) then
			if pq(self,"isWeak",target) or pq(self,"hasSkills",sgs.need_maxhp_skill, target) then
				return "PlusQingnang_choice1"
			else
				return "PlusQingnang_choice2"
			end
		end
	end
	return "PlusQingnang_choice1"
end



sgs.ai_skill_cardask["@PlusGuidao-card"] = function(self, data)
	local judge = pq(data,"toJudge")
	local all_cards = pq(self.player,"getCards","he")

	if pq(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
			call(all_cards,"prepend",disclosed(self,id))
		end
	end

	if pq(all_cards,"isEmpty") then return "." end

	local needTokeep = pq(judge.card,"getSuit") ~= sgs.Card_Spade and
		((not pq(self.player,"hasSkill","leiji") and not pq(self.player,"hasSkill","olleiji")) or pq(judge.card,"getSuit") ~= sgs.Card_Club)
		and aoe_truth(self) and pq(self,"playerGetRound",judge.who) < pq(self,"playerGetRound",self.player) and
		call(self,"findLeijiTarget",self.player, 50)
		and (pq(self,"getCardsNum","Jink") > 0 or pq(self,"hasEightDiagramEffect")) and pq(self,"getFinalRetrial") == 1

	if not needTokeep then
		local who = judge.who
		if pq(who,"getPhase") == sgs.Player_Judge and not pq(who,"getJudgingArea"):isEmpty() and pq(who,"containsTrick","lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if pq(self.player,"hasSkill","nosleiji") then keptspade = 2 end
		if pq(self.player,"hasSkill","PlusLeiji") then keptspade = 2 end
		if pq(self.player,"hasSkill","leiji") then keptblack = 2 end
		if pq(self.player,"hasSkill","olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if pq(card,"isBlack") and not pq(card,"hasFlag","using") then
			if pq(card,"getSuit") == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not pq(self.player,"hasSkill","olleiji") then return "." end
	if keptspade == 1 and not pq(self.player,"hasSkill","leiji") then return "." end

	local card_id = pq(self,"getRetrialCardId",cards, judge)
	if card_id == -1 then
		if pq(self,"needRetrial",judge) and judge.reason ~= "beige" then
			if pq(self,"needToThrowArmor") then return "$" .. call(self.player,"getArmor"):getEffectiveId() end
			sort_use(self,cards, true)
			if pq(self,"getUseValue",judge.card) > pq(self,"getUseValue",cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif pq(self,"needRetrial",judge) or pq(self,"getUseValue",judge.card) > pq(self,"getUseValue",disclosed(self,card_id)) then
		local card = disclosed(self,card_id)
		return "$" .. card_id
	end

	return "."
end


sgs.PlusGuidao_suit_value = {
	spade = 3.9,
	club = 2.7
}

sgs.PlusGuidao_keep_value = {
	Peach = 10,
	Jink = 9
}

sgs.ai_skill_use["@PlusGuidao2"] = function(self, prompt)
	local targets = AIList.new(pq(self.room,"getAllPlayers"))
	local pindian = tag(self,"CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if scoped_flag(self,p,"PlusGuidao_Source") then
			from = p
		end
		if scoped_flag(self,p,"PlusGuidao_Target") then
			to = p
		end
	end
	if from and to and pq(self,"isFriend",to) and pq(self,"isEnemy",from) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		local max_card = {}
		local min_card = {}
		sort_keep(self,cards)
		if pq(pindian.to_card,"getNumber") < pq(pindian.from_card,"getNumber") then
			for _, acard in ipairs(cards) do
				if not pq(acard,"isKindOf","Peach") and pq(acard,"isBlack") then
					if pq(acard,"getNumber") < pq(pindian.to_card,"getNumber") then
						table.insert(min_card, pq(acard,"getEffectiveId"))
					elseif pq(acard,"getNumber") >= pq(pindian.from_card,"getNumber") then
						table.insert(max_card, pq(acard,"getEffectiveId"))
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuidao_Card:" .. max_card[1] .. ":->" .. pq(to,"objectName")
			end
			if #min_card > 0 then
				return "#PlusGuidao_Card:" .. min_card[1] .. ":->" .. pq(from,"objectName")
			end
		end
	end
	if from and to and pq(self,"isFriend",from) and pq(self,"isEnemy",to) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		local max_card = {}
		local min_card = {}
		sort_keep(self,cards)
		if pq(pindian.to_card,"getNumber") >= pq(pindian.from_card,"getNumber") then
			for _, acard in ipairs(cards) do
				if not pq(acard,"isKindOf","Peach") and pq(acard,"isBlack") then
					if pq(acard,"getNumber") > pq(pindian.to_card,"getNumber") then
						table.insert(max_card, pq(acard,"getEffectiveId"))
					elseif pq(acard,"getNumber") < pq(pindian.from_card,"getNumber") then
						table.insert(min_card, pq(acard,"getEffectiveId"))
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuidao_Card:" .. max_card[1] .. ":->" .. pq(from,"objectName")
			end
			if #min_card > 0 then
				return "#PlusGuidao_Card:" .. min_card[1] .. ":->" .. pq(to,"objectName")
			end
		end
	end

	return "."
end

function sgs.ai_cardneed.PlusGuidao(to, card, self)
	for _, player in sgs.qlist(pq(self.room,"getAllPlayers")) do
		if pq(self,"getFinalRetrial",to) == 1 then
			if pq(player,"containsTrick","lightning") and not pq(player,"containsTrick","YanxiaoCard") then
				return pq(card,"getSuit") == sgs.Card_Spade and pq(card,"getNumber") >= 2 and pq(card,"getNumber") <= 9 and
					not pq(self,"hasSkills","hongyan|wuyan")
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipDrawPhase",player) then
				return pq(card,"getSuit") == sgs.Card_Club and pq(self,"hasSuit","club", true, to)
			end
		end
	end
end

function sgs.ai_cardneed.PlusLeiji(to, card, self)
	return ((isCard("Jink", card, to) and getKnownCard(to, "Jink", true) == 0)
		or (pq(card,"getSuit") == sgs.Card_Spade and pq(self,"hasSuit","spade", true, to))
		or (pq(card,"isKindOf","EightDiagram") and not (pq(self,"isEquip","EightDiagram") or getKnownCard(to, "EightDiagram", false) > 0)))
end

sgs.ai_skill_use["@PlusLeiji"] = function(self, prompt)
	local mode = pq(self.room,"getMode")
	if call(mode,"find","_mini_17") or call(mode,"find","_mini_19") or call(mode,"find","_mini_20") or call(mode,"find","_mini_26") then
		local players = pq(self.room,"getAllPlayers");
		for _, aplayer in sgs.qlist(players) do
			if pq(aplayer,"getState") ~= "robot" then
				return "#PlusLeiji_Card:.:->" .. pq(aplayer,"objectName")
			end
		end
	end

	call(self,"updatePlayers")
	sort_players(self,self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not pq(enemy,"hasArmorEffect","SilverLion") and not pq(enemy,"hasSkill","hongyan") and
			pq(self,"objectiveLevel",enemy) > 3 and not pq(self,"cantbeHurt",enemy) and not (pq(enemy,"isChained") and not pq(self,"isGoodChainTarget",enemy)) and pq(self,"canDamage",enemy,self.player,nil) then
			return "#PlusLeiji_Card:.:->" .. pq(enemy,"objectName")
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if not pq(enemy,"hasSkill","hongyan")
			and not (pq(enemy,"isChained") and not pq(self,"isGoodChainTarget",enemy)) then
			return "#PlusLeiji_Card:.:->" .. pq(enemy,"objectName")
		end
	end

	return "."
end

sgs.ai_card_intention["#PlusLeiji_Card"] = 80

function sgs.ai_slash_prohibit.PlusLeiji(self, to, card)
	if pq(self,"isFriend",to) then return false end
	local hcard = pq(to,"getHandcardNum")
	if pq(self.player,"hasSkill","liegong") and (hcard >= pq(self.player,"getHp") or hcard <= pq(self.player,"getAttackRange")) then return false end
	if self.role == "rebel" and pq(to,"isLord") then
		local other_rebel
		for _, player in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
			if pq(self,"getRoleEstimate",player) == "rebel" or pq(self,"compareRoleEvaluation",player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and (pq(self,"hasSkills","hongyan") or pq(self.player,"getHp") >= 4) and (pq(self,"getCardsNum","Peach") > 0 or pq(self,"hasSkills","hongyan|ganglie|neoganglie")) then
			return false
		end
	end

	if getKnownCard(to, "Jink", true) >= 1 or (pq(self,"hasSuit","spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if pq(self,"isEquip","EightDiagram", to) and not IgnoreArmor(self.player, to) then return true end
end

local PlusHuangtianQun_skill = {}
PlusHuangtianQun_skill.name = "PlusHuangtianQun"
table.insert(package_skills, PlusHuangtianQun_skill)
PlusHuangtianQun_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasFlag","ForbidPlusHuangtian") then return nil end
	if pq(self.player,"getKingdom") ~= "qun" then return nil end

	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	local card
	sort_use(self,cards, true)
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","Jink") or pq(acard,"isKindOf","ThunderSlash") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = pq(card,"getEffectiveId")
	local card_str = "#PlusHuangtian_Card:" .. card_id .. ":"
	local skillcard = parse(self,request,card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func["#PlusHuangtian_Card"] = function(card,use,self,request)
	if pq(self,"needBear") or pq(self,"getCardsNum","Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasLordSkill","PlusHuangtian") then
			if not pq(friend,"hasFlag","PlusHuangtianInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then 
		use.card = card
		sort_players(self,targets, "defense")
		if use.to then
			call(use.to,"append",targets[1])
		end
	elseif pq(self,"getCardsNum","Slash", "he") >= 2 then 
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"hasLordSkill","PlusHuangtian") then
				if not pq(enemy,"hasFlag","PlusHuangtianInvoked") then
					if not hasManjuanEffect(enemy) then
						if pq(enemy,"isKongcheng") and not pq(enemy,"hasSkill","kongcheng") and not hasTuntianEffect(enemy, true) then 
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if pq(self.player,"hasSkill","tianyi") and not pq(self.player,"hasUsed","TianyiCard") then
				flag = true
			elseif pq(self.player,"hasSkill","xianzhen") and not pq(self.player,"hasUsed","XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = call(self,"getMaxCard",self.player) 
				if pq(maxCard,"getNumber") > pq(card,"getNumber") then 
					sort_players(self,targets, "defense", true)
					for _, enemy in ipairs(targets) do
						if pq(self.player,"canSlash",enemy, nil, false, 0) then 
							use.card = card
							call(self,"setStrategyPlayerFlag",enemy,"AI_HuangtianPindian",true)
							if use.to then
								call(use.to,"append",enemy)
							end
							break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.PlusHuangtian_Card = function(self, card, from, tos)
	if tos[1]:isKongcheng() and ((pq(from,"hasSkill","tianyi") and not pq(from,"hasUsed","TianyiCard"))
			or (pq(from,"hasSkill","xianzhen") and not pq(from,"hasUsed","XianzhenCard"))) then
	else
		call(self,"updateIntention",from, tos[1], -80)
	end
end

sgs.ai_use_priority.PlusHuangtian_Card = 10
sgs.ai_use_value.PlusHuangtian_Card = 8.5

sgs.exclusive_skill = sgs.exclusive_skill .. "|PlusHunzhou"

sgs.bad_skills = sgs.bad_skills .. "|PlusShiyong"


sgs.ai_skill_choice["PlusMizhao_Card"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	if #items == 1 then
		return items[1]
	else
		local target = pq(data,"toPlayer")
		if pq(self.player,"canSlash",target) and pq(self,"isEnemy",target) then
			local slash = call(self,"cloneEvaluationCard","slash")
			
			if not pq(self,"slashProhibit",slash, target) and pq(self.player,"canSlash",target, slash, false) and pq(self,"isGoodTarget",target, self.enemies, slash) then
				return "PlusMizhao_Use"
			end
		end
	end
	return "PlusMizhao_Draw"
end



local PlusMizhao_skill = {}
PlusMizhao_skill.name = "PlusMizhao"
table.insert(package_skills, PlusMizhao_skill)
PlusMizhao_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#PlusMizhao_Card") then return end
	local use_cards = {}
	local card
	if pq(self,"needToThrowArmor") then
		table.insert(use_cards, call(self.player,"getArmor"):getEffectiveId())
	end
	if #use_cards < 3 then
		local hcards = pq(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_use(self,hcards, true)

		for _, hcard in ipairs(hcards) do
			if #use_cards < 3 then
				if pq(hcard,"isKindOf","Slash") then
					if pq(self,"getCardsNum","Slash") > 1 then
						card = hcard
						break
					else
						local dummy_use = pq(self,"aiUseCard",hcard)
						if dummy_use and dummy_use.to and (pq(dummy_use.to,"length") == 0
								or pq(dummy_use.to,"length") == 1 and not pq(self,"hasHeavyDamage",self.player, hcard, pq(dummy_use.to,"first"))) then
							table.insert(use_cards, pq(hcard,"getEffectiveId"))
						end
					end
				else
					table.insert(use_cards, pq(hcard,"getEffectiveId"))
				end
			else
				break
			end
		end
	end
	if #use_cards < 3 then
		local ecards = pq(self.player,"getCards","e")
		ecards = AIList.new(ecards)

		for _, ecard in ipairs(ecards) do
			if (pq(ecard,"isKindOf","Weapon") or pq(ecard,"isKindOf","OffensiveHorse")) and #use_cards < 3 then
				table.insert(use_cards, pq(ecard,"getEffectiveId"))
			end
		end
	end
	if #use_cards == 3 then
		card = parse(self,request,"#PlusMizhao_Card:" .. table.concat(use_cards, "+") .. ":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#PlusMizhao_Card"] = function(card,use,self,request)
	local target
	local friends = self.friends_noself
	local slash = call(self,"cloneEvaluationCard","slash")
	
	remember_player(self,"PlusMizhaoTarget",nil)

	local canMingceTo = function(player)
		local canGive = not pq(self,"needKongcheng",player, true)
		return canGive or (not canGive and pq(self,"getEnemyNumBySeat",self.player, player) == 0)
	end

	sort_players(self,self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) then
			for _, enemy in ipairs(self.enemies) do
				if pq(friend,"canSlash",enemy) and not pq(self,"slashProhibit",slash, enemy) and pq(self,"getDefenseSlash",enemy) <= 2
					and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)
					and pq(enemy,"objectName") ~= pq(self.player,"objectName") then
					target = friend
					remember_player(self,"PlusMizhaoTarget",enemy)
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		sort_players(self,friends, "defense")
		for _, friend in ipairs(friends) do
			if canMingceTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			call(use.to,"append",target)
		end
	end
end


sgs.ai_skill_playerchosen.PlusMizhao_Card = function(self, targets)
	if recall_player(self,"PlusMizhaoTarget") then return recall_player(self,"PlusMizhaoTarget") end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_use_value["#PlusMizhao_Card"] = 5.9
sgs.ai_use_priority["#PlusMizhao_Card"] = 4

sgs.ai_card_intention["#PlusMizhao_Card"] = -70


sgs.ai_skill_invoke.PlusAnxi = function(self, data)
	local max_card = call(self,"getMaxCard")
	local max_point = pq(max_card,"getNumber")
	local target = call(self.room,"getCurrent")
	if pq(self,"isFriend",target) then return false end
	if pq(target,"getHandcardNum") > pq(self.player,"getHandcardNum") and not pq(target,"isKongcheng") and pq(self.player,"canPindian",target) then
		local enemy_max_card = call(self,"getMaxCard",target)
		local allknown = 0
		if pq(self,"getKnownNum",target) == pq(target,"getHandcardNum") then
			allknown = allknown + 1
		end
		if (enemy_max_card and max_point > pq(enemy_max_card,"getNumber") and allknown > 0)
			or (enemy_max_card and max_point > pq(enemy_max_card,"getNumber") and allknown < 1 and max_point > 10)
			or (not enemy_max_card and max_point > 10) then
			call(self,"remember","PlusAnxi_card",pq(max_card,"getEffectiveId"))
			return true
		end
	end
	return false
end


sgs.ai_skill_invoke.PlusAnxidamage = function(self, data)
	return true
end



ai_audited_aliases.register{id="ai_cardneed.PlusAnxi",registry="ai_cardneed",path={"PlusAnxi"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_playerchosen.PlusAnxi",registry="ai_skill_playerchosen",path={"PlusAnxi"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"},self_index=1,defer_canonical=true}
local PlusZhuni_skill = {}
PlusZhuni_skill.name = "PlusZhuni"
table.insert(package_skills, PlusZhuni_skill)

PlusZhuni_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getHandcardNum") < 1 then return end
	local can = false
	local cards = AIList.new(pq(self.player,"getCards","h"))
	local subcards = {}
	sort_use(self,cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if pq(card,"isBlack") then table.insert(cardsq, card) end
	end
	if #cardsq == 0 then return end
	if pq(self,"getKeepValue",cardsq[1]) > 18 then return end
	if pq(self,"getUseValue",cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "Collateral:PlusZhuni[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = parse(self,request,card_str)
	assert(AsCard)
	return AsCard
end

sgs.ai_skill_cardask["@PlusZhuni"] = function(self, data, pattern, target)
	local victim = pq(data,"toPlayer")
	if not victim then return "." end
	if pq(self,"isFriend",victim) then return "." end
	if pq(self,"needToThrowArmor") then
		return "$" .. call(self.player,"getArmor"):getEffectiveId()
	end
	local cards = AIList.new(pq(self.player,"getCards","e"))
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		return "$" .. pq(card,"getEffectiveId")
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_skill_use["@PlusKuangjun"] = function(self, prompt, method)
	local arr1, arr2 = pq(self,"getWoundedFriend",false, false)
	local target = nil

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1]) or pq(self,"getOverflow") >= 1) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		return "#PlusKuangjun_Card:.:->" .. pq(target,"objectName")
	end


	return "."
end
sgs.ai_card_intention["PlusKuangjun_Card"] = -80



local PlusZhiren_skill = {}
PlusZhiren_skill.name = "PlusZhiren"
table.insert(package_skills, PlusZhiren_skill)
PlusZhiren_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#PlusZhiren_Card") then return nil end
	if #self.friends == 0 then return nil end
	local card_str = "#PlusZhiren_Card:.:"
	return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#PlusZhiren_Card"] = function(card,use,self,request)
	sort_players(self,self.friends, "handcard")
	self.friends = sgs.reverse(self.friends)
	local target = call(self,"findPlayerToDraw",true,2)
	if target and not pq(target,"isKongcheng") and getKnownCard(target, self.player, "EquipCard", true) + getKnownCard(target, self.player, "TrickCard", true) > 0 then 
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
	for _, friend in ipairs(self.friends) do
		if not pq(friend,"isKongcheng") and pq(self,"canDraw",friend, self.player) and getKnownCard(friend, self.player, "EquipCard", true) + getKnownCard(friend, self.player, "TrickCard", true) > 0 then
			use.card = card
			if use.to then call(use.to,"append",friend) end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if not pq(friend,"isKongcheng") and pq(friend,"getHp") < self:getBestHp(friend) and getKnownCard(friend, self.player, "BasicCard", true) > 0 then
			use.card = card
			if use.to then call(use.to,"append",friend) end
			return
		end
	end
	if target and not pq(target,"isKongcheng") then 
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_priority["#PlusZhiren_Card"] = 4.2
sgs.ai_card_intention["#PlusZhiren_Card"] = -80

sgs.ai_skill_askforag.PlusZhiren = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, disclosed(self,card_id))
	end
	local target
	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(p,"hasFlag","PlusZhiren") then
			target = p
			break
		end
	end
	if not target then return -1 end
	for _, card in ipairs(cards) do
		if pq(card,"isKindOf","BasicCard") and pq(target,"getHp") < self:getBestHp(target) then
			return pq(card,"getEffectiveId")
		end
	end
	for _, card in ipairs(cards) do
		if not pq(card,"isKindOf","BasicCard") then
			return pq(card,"getEffectiveId")
		end
	end
	return -1
end


sgs.ai_skill_invoke.PlusChenghao = function(self, data)
	local target = call(self.room,"getCurrent")
	if pq(self,"isFriend",target) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.PlusChenghao = function(self, player, promptlist)
	local current = call(self.room,"getCurrent")
	if current then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",player, current, -20)
		end
	end
end




sgs.ai_skill_choice.SixWulve = function(self, choices, data)
	local damage = pq(data,"toDamage")
	if not damage.card then return "SixWulveDraw" end
	
	if pq(self,"isWeak") and (pq(self,"getCardsNum","Slash") > 0 or not pq(damage.card,"isKindOf","Slash") or pq(self.player,"getHandcardNum") <= pq(self.player,"getHp")) then
		return
		"SixWulveDraw"
	end
	if damage.card then 
		if pq(damage.card,"isVirtualCard") then
			return "SixWulveDraw"
		end
	end
	
	local items = pq(choices,"split","+")
	if table.contains(items, "SixWulveGet") then return "SixWulveGet" end
	return items[1]
end

sgs.ai_skill_invoke.SixWulve = function(self, data)
	local target = call(self.room,"getCurrent")
	if target and pq(self,"isFriend",target) then
		for _, id in sgs.qlist(pq(self.player,"getPile","strategy")) do
			local c = disclosed(self,id)
			if pq(c,"targetFixed") then
				if pq(c,"isKindOf","Peach") and pq(target,"isWounded") and pq(target,"getHp") <= 2 then
					return true
				end
				if pq(c,"isKindOf","ExNihilo") and pq(target,"getHandcardNum") <= 2 then
					return true
				end
				if pq(c,"isKindOf","SavageAssault") then
					if pq(self,"getAoeValue",c) > 0 then
						return true
					end
				end
				if pq(c,"isKindOf","ArcheryAttack") then
					if pq(self,"getAoeValue",c) > 0 then
						return true
					end
				end
				if pq(c,"isKindOf","AmazingGrace") then
					local low_handcard_friend = false
					for _, friend in ipairs(self.friends_noself) do
						if pq(friend,"getHandcardNum") <= 4 then
							low_handcard_friend = true
						end
					end
					if low_handcard_friend then
						return true
					end
				end
				if pq(c,"isKindOf","GodSalvation") then
					if pq(self,"willUseGodSalvation",c) then
						return true
					end
				end
				if pq(c,"isKindOf","EquipCard") then
					local equip_index = pq(c,"getEquipSlot")
					if call(target,"getEquip",equip_index) == nil and pq(target,"hasEquipArea",equip_index) then
						return true
					end
				end
			else
				if pq(c,"isKindOf","Slash") then
					local dummyuse = pq(self,"aiUseCard",c)
					local targets = {}
					if not pq(dummyuse.to,"isEmpty") then
						for _, p in sgs.qlist(dummyuse.to) do
							return true
						end
					end
				end
				
				if pq(c,"isKindOf","TrickCard") and not pq(c,"isKindOf","Collateral") then
					local dummyuse = pq(self,"aiUseCard",c)
					local targets = {}
					if not pq(dummyuse.to,"isEmpty") then
						for _, p in sgs.qlist(dummyuse.to) do
							if pq(p,"getHp") <= 2 and pq(p,"getCards","he"):length() <= 2 and pq(p,"getHandcardNum") <= 1 then
								return true
							end
						end
					end
				end
			end

			
		end
	end
	return false
end

sgs.ai_skill_askforag.SixWulve = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, disclosed(self,card_id))
	end
	sort_use(self,cards)
	local target = call(self.room,"getCurrent")
	for _, c in ipairs(cards) do
		if pq(c,"targetFixed") then
			if pq(c,"isKindOf","Peach") and pq(target,"isWounded") and pq(target,"getHp") <= 2 then
				return pq(c,"getEffectiveId")
			end
			if pq(c,"isKindOf","ExNihilo") and pq(target,"getHandcardNum") <= 2 then
				return pq(c,"getEffectiveId")
			end
			if pq(c,"isKindOf","SavageAssault") then
				if pq(self,"getAoeValue",c) > 0 then
					return pq(c,"getEffectiveId")
				end
			end
			if pq(c,"isKindOf","ArcheryAttack") then
				if pq(self,"getAoeValue",c) > 0 then
					return pq(c,"getEffectiveId")
				end
			end
			if pq(c,"isKindOf","AmazingGrace") then
				local low_handcard_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if pq(friend,"getHandcardNum") <= 4 then
						low_handcard_friend = true
					end
				end
				if low_handcard_friend then
					return pq(c,"getEffectiveId")
				end
			end
			if pq(c,"isKindOf","GodSalvation") then
				if pq(self,"willUseGodSalvation",c) then
					return pq(c,"getEffectiveId")
				end
			end
			if pq(c,"isKindOf","EquipCard") then
				local equip_index = pq(c,"getEquipSlot")
				if call(target,"getEquip",equip_index) == nil and pq(target,"hasEquipArea",equip_index) then
					return pq(c,"getEffectiveId")
				end
			end
			
		else
			if pq(c,"isKindOf","Slash") and pq(self,"getCardsNum","Slash") == 0 then
				local dummyuse = pq(self,"aiUseCard",c)
				local targets = {}
				if not pq(dummyuse.to,"isEmpty") then
					for _, p in sgs.qlist(dummyuse.to) do
						return pq(c,"getEffectiveId")
					end
				end
			end
			
			if pq(c,"isKindOf","TrickCard") and not pq(c,"isKindOf","Collateral") then
				local dummyuse = pq(self,"aiUseCard",c)
				local targets = {}
				if not pq(dummyuse.to,"isEmpty") then
					for _, p in sgs.qlist(dummyuse.to) do
						if pq(p,"getHp") <= 2 and pq(p,"getCards","he"):length() <= 2 and pq(p,"getHandcardNum") <= 1 then
							return pq(c,"getEffectiveId")
						end
					end
				end
			end
		end
	end

	return -1
end

sgs.ai_can_damagehp.SixWulve = function(self, from, card, to)
	if from and pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0
		and pq(self,"canLoseHp",from, card, to)
	then
		return (pq(card,"isNDTrick") and pq(card,"isDamageCard")) or pq(card,"isKindOf","AOE")
	end
end
sgs.ai_target_revises.SixWulve = function(to, card, self)
	if pq(card,"isDamageCard")
		and not pq(self,"isFriend",to)
		and pq(card,"subcardsLength") > 0
	then
		for _, id in sgs.list(pq(card,"getSubcards")) do
			if isCard("Peach,Analeptic", disclosed(self,id), to)
			then
				return true
			end
		end
	end
end


sgs.ai_skill_use["@@SixWulveOthers!"] = function(self, prompt, method)
	local taoluan_use_card=property_card(self,"SixWulve",owner_fact(self,"six_wulve_card"))

	local dummyuse = pq(self,"aiUseCard",taoluan_use_card)
	local targets = {}
	if not pq(dummyuse.to,"isEmpty") then
		for _, p in sgs.qlist(dummyuse.to) do
			table.insert(targets, pq(p,"objectName"))
		end
		if #targets > 0 then
			return pq(taoluan_use_card,"getLegacyStringKey") .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end


ai_audited_aliases.register{id="ai_skill_invoke.SixLangmou",registry="ai_skill_invoke",path={"SixLangmou"},canonical_registry="ai_skill_invoke",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SixLangmou",registry="ai_choicemade_filter",path={"cardChosen","SixLangmou"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_cardchosen.SixLangmou",registry="ai_skill_cardchosen",path={"SixLangmou"},canonical_registry="ai_skill_cardchosen",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_need_damaged.SixLangmou",registry="ai_need_damaged",path={"SixLangmou"},canonical_registry="ai_need_damaged",canonical_path={"fankui"},self_index=1,defer_canonical=true}
sgs.use_lion_skill = sgs.use_lion_skill .. "|SixTaohui"


sgs.ai_skill_use["@SixTaohui"] = function(self, prompt, method)
	local cards = {}
	if pq(self,"needToThrowArmor",self.player) then
		table.insert(cards, call(self.player,"getArmor"):getEffectiveId())
	end
	for _, c in ipairs(AIList.new(pq(self.player,"getCards","e"))) do
		if not table.contains(cards, pq(c,"getEffectiveId")) and pq(self,"doDisCard",self.player, pq(c,"getEffectiveId"), true) then
			table.insert(cards, pq(c,"getEffectiveId"))
		end
	end
	if #cards > 0 then
		return "#SixTaohuiCard:" .. table.concat(cards, "+") .. ":"
	end
	return "."
end

sgs.wizard_skill = sgs.wizard_skill .. "|SixGuicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|SixGuicai"

sgs.ai_skill_use["@@SixGuicai2"] = function(self, prompt)
	local targets = AIList.new(pq(self.room,"getAllPlayers"))
	local pindian = tag(self,"CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if scoped_flag(self,p,"SixGuicaiSource") then
			from = p
		end
		if scoped_flag(self,p,"SixGuicaiTarget") then
			to = p
		end
	end
	if from and to and pq(self,"isFriend",to) and pq(self,"isEnemy",from) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		local max_card = {}
		local min_card = {}
		sort_keep(self,cards)
		if pq(pindian.to_card,"getNumber") < pq(pindian.from_card,"getNumber") then
			if #cards > 0 then
				return "#SixGuicaiCard:" .. cards[1]:getEffectiveId() .. ":->" .. pq(from,"objectName")
			end
		end
	end
	if from and to and pq(self,"isFriend",from) and pq(self,"isEnemy",to) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		local max_card = {}
		local min_card = {}
		sort_keep(self,cards)
		if pq(pindian.to_card,"getNumber") >= pq(pindian.from_card,"getNumber") then
			if #cards > 0 then
				return "#SixGuicaiCard:" .. cards[1]:getEffectiveId() .. ":->" .. pq(to,"objectName")
			end
		end
	end

	return "."
end


sgs.ai_skill_choice["SixGuicaipindian"] = function(self, choices, data)
	local target

	local targets = AIList.new(pq(self.room,"getAllPlayers"))
	for _, p in ipairs(targets) do
		if pq(p,"hasFlag","SixGuicaiModify") then
			target = p
		end
	end
	if target then
		if pq(self,"isFriend",target) then
			return "13"
		else
			return "1"
		end
	end
	return "1"
end
function sgs.ai_skill_suit.SixGuicai(self)
	local judge = tag(self,"CurrentJudgeStruct"):toJudge()
	local who = judge.who
	if judge and pq(self,"needRetrial",judge) then
		if judge.reason == "beige" then
			local damage = tag(self,"CurrentDamageStruct"):toDamage()
			if damage.from then
				if pq(self,"isFriend",damage.from) then
					if not pq(self,"toTurnOver",damage.from, 0) and pq(judge.card,"getSuit") ~= sgs.Card_Spade then
						return sgs.Card_Spade
					else
						local retr = true
						if (pq(judge.card,"getSuit") == sgs.Card_Heart and pq(who,"isWounded") and pq(self,"isFriend",who))
							or (pq(judge.card,"getSuit") == sgs.Card_Diamond and pq(self,"isEnemy",who) and hasManjuanEffect(who))
							or (pq(judge.card,"getSuit") == sgs.Card_Club and pq(self,"needToThrowArmor",damage.from)) then
							retr = false
						end
						if retr then
							if (pq(self,"isFriend",who) and pq(who,"isWounded")) then
								return sgs.Card_Heart
							elseif pq(self,"isEnemy",who) and hasManjuanEffect(who) then
								return sgs.Card_Diamond
							elseif pq(self,"isFriend",who) and not hasManjuanEffect(who) then
								return sgs.Card_Diamond
							elseif (pq(self,"needToThrowArmor",damage.from) or pq(damage.from,"isNude")) then
								return sgs.Card_Club
							elseif pq(self,"toTurnOver",damage.from, 0) then
								return sgs.Card_Spade
							end
						end
					end
				else
					if not pq(self,"toTurnOver",damage.from, 0) and pq(judge.card,"getSuit") == sgs.Card_Spade then
						return sgs.Card_Club
					end
				end
			end
		elseif pq(self,"isFriend",who) and not (pq(self,"getFinalRetrial") == 2) then
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Diamond,0)
			
			if pq(judge,"isGood",newcard) then
				return sgs.Card_Diamond
			end
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Heart,0)
			
			if pq(judge,"isGood",newcard) then
				return sgs.Card_Heart
			end
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Spade,0)
			
			if pq(judge,"isGood",newcard) then
				return sgs.Card_Spade
			end
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Club,0)
			
			if pq(judge,"isGood",newcard) then
				return sgs.Card_Club
			end
		elseif pq(self,"isEnemy",who) and not (pq(self,"getFinalRetrial") == 2) then
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Diamond,0)
			
			if not pq(judge,"isGood",newcard) then
				return sgs.Card_Diamond
			end
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Heart,0)
			
			if not pq(judge,"isGood",newcard) then
				return sgs.Card_Heart
			end
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Spade,0)
			
			if not pq(judge,"isGood",newcard) then
				return sgs.Card_Spade
			end
			local newcard = pq(judge,"cloneCandidate",sgs.Card_Club,0)
			
			if not pq(judge,"isGood",newcard) then
				return sgs.Card_Club
			end
		end
	end
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	return suit
end

sgs.ai_skill_choice["SixGuicai"] = function(self, choices, data)
	local judge = pq(data,"toJudge")
	local items = pq(choices,"split","+")
	local target = judge.who
	if target and pq(self,"needRetrial",judge) then
		if pq(self,"isFriend",target) then
			return "13"
		else
			return items[math.random(3, #items - 3)]
		end
	end
	return items[math.random(1, #items)]
end


sgs.ai_skill_cardask["@SixGuicai"] = function(self, data)
	local judge = pq(data,"toJudge")

	
	if pq(self,"needRetrial",judge) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		
		if #cards > 0 then
			
			return "#SixGuicaiDummyCard:" .. cards[1]:getEffectiveId() .. ":"
		end
	end

	return "."
end

function sgs.ai_cardneed.SixGuicai(to, card, self)
	for _, player in sgs.qlist(pq(self.room,"getAllPlayers")) do
		if pq(self,"getFinalRetrial",to) == 1 then
			if pq(player,"containsTrick","lightning") and not pq(player,"containsTrick","YanxiaoCard") then
				return pq(to,"getCards","h"):length() <= 2 and not pq(self,"hasSkills","hongyan|wuyan")
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipDrawPhase",player) then
				return pq(to,"getCards","h"):length() <= 2
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipPlayPhase",player) then
				return pq(to,"getCards","h"):length() <= 2
			end
		end
	end
end

sgs.ai_skill_cardask["@SixHuwei"] = function(self, data)
	local target = pq(data,"toPlayer")
	if pq(self,"isFriend",target) then return "." end
	if pq(self,"needToThrowArmor") then
		return "$" .. call(self.player,"getArmor"):getEffectiveId()
	end

	local has_equip

	for _, card in sgs.qlist(pq(self.player,"getCards","e")) do
		if pq(card,"isKindOf","EquipCard") and pq(self.player,"hasSkills",sgs.lose_equip_skill) then
			has_equip = card
		end
	end

	if has_equip then
		return "$" .. pq(has_equip,"getEffectiveId")
	else
		return "."
	end
end

function sgs.ai_armor_value.SixHuwei(player, self, card)
	if not card then return 4 end
end

sgs.ai_skill_invoke.SixJushou = function(self, data)
	if sgs.ai_skill_playerchosen.SixJushou(self, AIList.new(pq(self.room,"getOtherPlayers",self.player))) ~= nil then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.SixJushou = function(self, targets)
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "handcard")
	local target = nil
	local n = math.min(pq(self.player,"getMark","SixJushou"), 4)
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"toTurnOver",friend, n, "SixJushou") and pq(friend,"faceUp") and pq(friend,"inMyAttackRange",self.player) then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = call(self,"findPlayerToDraw",false, n)
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if pq(self,"toTurnOver",enemy, n, "SixJushou") and hasManjuanEffect(enemy) and pq(enemy,"faceUp") and pq(enemy,"inMyAttackRange",self.player) then
						target = enemy
						break
					end
				end
			end
		else
			sort_players(self,self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if pq(self,"toTurnOver",enemy, n, "SixJushou") and hasManjuanEffect(enemy) and pq(enemy,"faceUp") and pq(enemy,"inMyAttackRange",self.player) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if pq(self,"toTurnOver",enemy, n, "SixJushou") and pq(self,"hasSkills",sgs.priority_skill, enemy) and pq(enemy,"faceUp") and pq(enemy,"inMyAttackRange",self.player) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if pq(self,"toTurnOver",enemy, n, "SixJushou") and pq(enemy,"faceUp") and pq(enemy,"inMyAttackRange",self.player) then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end



sgs.ai_playerchosen_intention.SixJushou = function(self, from, to)
	if hasManjuanEffect(to) then call(self,"updateIntention",from, to, 80) end
	local intention = 80 / math.max(pq(from,"getMark","SixJushou"), 1)
	if not pq(self,"toTurnOver",to, pq(from,"getMark","SixJushou"), "SixJushou") then intention = -intention end
	if pq(from,"getMark","SixJushou") < 3 then
		call(self,"updateIntention",from, to, intention)
	else
		call(self,"updateIntention",from, to, math.min(intention, -30))
	end
end

sgs.ai_skill_use["@@SixMingduan"] = function(self, prompt)
	local can_invoke = false
	local target = call(self.room,"getCurrent")
	local slash2 = call(self,"cloneEvaluationCard","slash")
	
	if pq(self.room,"alivePlayerCount") <= 2 or #self.friends_noself < 1 then return "." end

	if pq(self,"isEnemy",target) then
		if pq(target,"isJilei",slash2) then can_invoke = true end

		if pq(target,"hasSkills","guose|qixi|duanliang|ol_duanliang|luanji") and pq(target,"getHandcardNum") > 1 then can_invoke = true end
		if pq(target,"hasSkills","shuangxiong") and not pq(self,"isWeak",target) then can_invoke = true end
		if not pq(self,"slashIsEffective",slash2, self.player, target) and not pq(self,"isWeak") then can_invoke = true end
		if call(self.player,"getArmor") and call(self.player,"getArmor"):isKindOf("Vine") and not pq(self,"isWeak") then can_invoke = true end
		if call(self.player,"getArmor") and not pq(self,"isWeak") and pq(self,"getCardsNum","Jink") > 0 then can_invoke = true end
	end

	local use_card
	local slashtarget
	local cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,cards)
	for _, c in ipairs(cards) do
		if pq(c,"isBlack") then
			use_card = c
			break
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not pq(target,"isProhibited",enemy, slash2) and pq(self,"slashIsEffective",slash2, enemy) then
			slashtarget = enemy
			break
		end
	end
	if use_card and can_invoke and slashtarget then
		return "#SixMingduanCard:" .. pq(use_card,"getEffectiveId") .. ":"
	end
	return "."
end


sgs.ai_skill_playerchosen.SixMingduan = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


sgs.ai_skill_invoke.SixQiaoxie = function(self, data)
	local target = pq(data,"toPlayer")
	if target and not pq(self,"isEnemy",target) and #self.enemies > 0 and pq(self,"getCardsNum","Slash") >= 1 and not pq(self,"needBear") then
		local slash = call(self,"cloneEvaluationCard","slash")
		
		local dummy_use=pq(self,"withOwnerRange","slashNoDistanceLimit","SixQiaoxie",function()return pq(self,"aiUseCard",slash)end)
		if not pq(dummy_use.to,"isEmpty") then
			for _, p in sgs.qlist(dummy_use.to) do
				if not pq(self.player,"inMyAttackRange",p) then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_cardask["@SixQiaoxie"] = function(self, data, pattern, target)
	local target = call(self.room,"getCurrent")
	if target and pq(self,"isFriend",target) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if pq(card,"isBlack") then
				return "$" .. pq(card,"getEffectiveId")
			end
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@SixQiaoxie"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player, current, -60)
	end
end




sgs.ai_skill_use["@@SixZhidi"] = function(self, prompt)
	local use_card
	local cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,cards)

	if #cards > 0 then
		return "#SixZhidiCard:" .. cards[1]:getEffectiveId() .. ":"
	end
	return "."
end



sgs.ai_skill_invoke.SixZhidi = function(self, data)
	local use = pq(data,"toCardUse")

	if use.card then
		if pq(use.card,"isKindOf","Peach") then return false end
		return not (pq(use.card,"isKindOf","Slash") and pq(self,"isPriorFriendOfSlash",self.player, use.card, use.from))
	end
end


local SixChouzuan_skill = {}
SixChouzuan_skill.name = "SixChouzuan"
table.insert(package_skills, SixChouzuan_skill)
SixChouzuan_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if pq(self.player,"hasUsed","#SixChouzuanCard") then return nil end
	return parse(self,request,"#SixChouzuanCard:.:")
end

sgs.ai_skill_use_func["#SixChouzuanCard"] = function(card,use,self,request)
	local maxvalue = 0
	local target
	for _, friend in ipairs(self.friends_noself) do
		local value = 0
		local enemies = {}
		for _, enemy in ipairs(self.enemies) do
			if pq(friend,"inMyAttackRange",enemy) then table.insert(enemies, enemy) end
		end
		if #enemies == 0 then return end
		sort_players(self,enemies, "hp")

		
		local card_ids = {}

		local zcards = pq(self.player,"getHandcards")
		local use_slash, keep_jink, keep_analeptic = false, false, false
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if pq(zcard,"getTypeId") == sgs.Card_TypeTrick then
					local dummy_use = pq(self,"aiUseCard",zcard)
					if dummy_use.card then shouldUse = false end
				end
				if pq(zcard,"getTypeId") == sgs.Card_TypeEquip and not pq(self.player,"hasEquip",zcard) then
					local dummy_use = pq(self,"aiUseCard",zcard)
					if dummy_use.card then shouldUse = false end
				end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if pq(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(card_ids, pq(zcard,"getId")) end
			end
		end

		if #card_ids >= pq(friend,"getAttackRange") then
			for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",friend)) do
				if pq(friend,"inMyAttackRange",p) then
					value = value + 1
				end
			end
		end
		if value > maxvalue then
			maxvalue = value
			target = friend
		end
	end
	if maxvalue > 0 and target then
		use.card=final_parse(self,request,"#SixChouzuanCard:.:")
		if use.to then call(use.to,"append",target) end
	end
end

sgs.ai_use_priority["#SixChouzuanCard"] = 0.6
sgs.ai_use_value["#SixChouzuanCard"] = 2.45
sgs.ai_card_intention["#SixChouzuanCard"] = -80



sgs.ai_skill_choice["SixChouzuan"] = function(self, choices, data)
	local current = call(self.room,"getCurrent")
	if (pq(self,"needToLoseHp",self.player, nil, nil)) and not pq(self,"isWeak") then
		return "SixChouzuanDamage"
	end
	return "SixChouzuanDraw"
end



sgs.ai_skill_playerchosen.SixWeiyuan = function(self, targets)
	local target, min_friend, max_enemy
	for _, enemy in ipairs(self.enemies) do
		if not pq(self,"hasSkills",sgs.lose_equip_skill, enemy) and not hasTuntianEffect(enemy, true) and pq(self.player,"getPile","wooden_ox"):length() == 0 then
			local ee = pq(enemy,"getEquips"):length()
			local fe = pq(self.player,"getEquips"):length()
			local value = pq(self,"evaluateArmor",call(enemy,"getArmor"), self.player) -
				pq(self,"evaluateArmor",call(self.player,"getArmor"), enemy)
				- pq(self,"evaluateArmor",call(self.player,"getArmor"), self.player) + pq(self,"evaluateArmor",call(enemy,"getArmor"), enemy)
			if ee > 0 and (ee > fe or ee == fe and value > 0) then
				return enemy
			end
		end
	end
	if pq(self.player,"getEquips"):length() > 2 then
		for _, friend in ipairs(self.friends_noself) do
			if (pq(self,"hasSkills",sgs.lose_equip_skill, friend)
				or (hasTuntianEffect(friend, true)) or pq(self,"hasSkills",sgs.need_equip_skill, friend)) and pq(friend,"getEquips"):length() < pq(self.player,"getEquips"):length() then
				return friend
			end
		end
	end

	target = nil
	if pq(self,"needToThrowArmor",self.player) or ((pq(self,"hasSkills",sgs.lose_equip_skill, self.player)
				or (hasTuntianEffect(self.player, true)))
			and not pq(self.player,"getEquips"):isEmpty()) then
		target = self.player
	end
	if not target then return end
	for _, friend in ipairs(self.friends_noself) do
		if (pq(self,"hasSkills",sgs.lose_equip_skill, friend)
			or (hasTuntianEffect(friend, true)) or pq(self,"hasSkills",sgs.need_equip_skill, friend)) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end

	return nil
end


ai_audited_aliases.register{id="ai_cardneed.SixTaichen",registry="ai_cardneed",path={"SixTaichen"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
local SixTaichen_skill = {
	name = "SixTaichen",
	getTurnUseCard=function(self,inclusive,request)
		if pq(self,"getCardsNum","Slash") == 0 then return end
		if pq(self.player,"hasUsed","#SixTaichenCard") then return end
		local can_use = false
		for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
			if pq(p,"isNude") then continue end
			if pq(self.player,"inMyAttackRange",p) then
				can_use = true
				break
			end
		end
		if can_use then
			return parse(self,request,"#SixTaichenCard:.:")
		end
	end,
}
table.insert(package_skills, SixTaichen_skill) 
sgs.ai_skill_use_func["#SixTaichenCard"] = function(card,use,self,request)
	local handcards = pq(self.player,"getHandcards")
	local slashs = {}
	for _, c in sgs.qlist(handcards) do
		if pq(c,"isKindOf","Slash") then
			if pq(self.player,"canDiscard",self.player, pq(c,"getEffectiveId")) then
				table.insert(slashs, c)
			end
		end
	end
	if #slashs == 0 then return end
	sort_players(self,self.enemies, "chaofeng")
	local enemys = {}
	for _, enemy in ipairs(self.enemies) do
		if not pq(self.player,"inMyAttackRange",enemy) then continue end
		if pq(self,"cantbeHurt",enemy) then continue end
		if not pq(self,"canDamage",enemy,self.player,nil) then continue end
		if not pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) then continue end
		if pq(self,"getCardsNum","Slash") - 1 < getCardsNum("Slash", enemy) and pq(self.player,"getHp") <= pq(enemy,"getHp") then continue end
		table.insert(enemys, enemy)
	end
	if #enemys > 0 then
		local card_str = string.format("#SixTaichenCard:%s:", slashs[1]:getEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then call(use.to,"append",enemys[1]) end
	end
end

local SixRende_skill = {}
SixRende_skill.name = "SixRende"
table.insert(package_skills, SixRende_skill)
SixRende_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"isKongcheng") then return end
	if pq(self.player,"getHandcardNum") <= 1 and pq(self.player,"getMaxCards") > 0 and pq(self.player,"getMark","SixRende") == 0 then return end
	local mode = string.lower(pq(self.room,"getMode"))
	if pq(self.player,"getMark","SixRende") > 1 and call(mode,"find","04_1v3") then return end

	if pq(self.player,"isWounded") then
		if pq(self.player,"getMark","SixRende") > 1 and pq(self,"getOverflow") <= 0 then return end
	end

	if pq(self,"shouldUseRende") then
		return parse(self,request,"#SixRendeCard:.:")
	end
end

sgs.ai_skill_use_func["#SixRendeCard"] = function(card,use,self,request)
	
	if pq(self.player,"getHp") < 3 and pq(self.player,"isWounded") and pq(self.player,"getHandcardNum") == 2 then
		sort_players(self,self.friends_noself, "handcard")
		local give_all_cards = {}
		for _, c in ipairs(AIList.new(pq(self.player,"getCards","h"))) do
			table.insert(give_all_cards, pq(c,"getEffectiveId"))
		end
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
		if #targets > 0 and #give_all_cards > 1 then
			local card_str = string.format("#SixRendeCard:" .. table.concat(give_all_cards, "+") .. ":")
			local acard = parse(self,request,card_str)
			use.card = acard
			if use.to then
				call(use.to,"append",targets[1])
			end
			return
		end
	end

	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	local notFound

	for i = 1, pq(self.player,"getHandcardNum") do
		local card, friend = call(self,"getCardNeedPlayer",cards)
		if card and friend then
			cards = call(self,"resetCards",cards, card)
		else
			notFound = true
			break
		end

		if pq(friend,"objectName") == pq(self.player,"objectName") or not pq(self.player,"getHandcards"):contains(card) then continue end
		local canJijiang = pq(self.player,"hasLordSkill","jijiang") and pq(friend,"getKingdom") == "shu"
		if pq(card,"isAvailable",self.player) and ((pq(card,"isKindOf","Slash") and not canJijiang) or pq(card,"isKindOf","Duel") or pq(card,"isKindOf","Snatch") or pq(card,"isKindOf","Dismantlement")) then
			local dummy_use = pq(self,"aiUseCard",card, dummy())
			if dummy_use.card
			then
				if pq(card,"isKindOf","Slash") or pq(card,"isKindOf","Duel") then
					local t1 = pq(dummy_use.to,"first")
					if pq(dummy_use.to,"length") > 1 then
						continue
					elseif pq(t1,"getHp") == 1 or getCardsNum("Jink",t1,self.player)<1
						or pq(t1,"isCardLimited",call(self,"cloneEvaluationCard","jink"), sgs.Card_MethodResponse) then
						continue
					end
				elseif (pq(card,"isKindOf","Snatch") or pq(card,"isKindOf","Dismantlement")) and pq(self,"getEnemyNumBySeat",self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if pq(self,"isFriend",p) and (pq(self,"willSkipDrawPhase",p) or pq(self,"willSkipPlayPhase",p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif pq(card,"isAvailable",self.player) and pq(self,"getEnemyNumBySeat",self.player, friend) > 0 and (pq(card,"isKindOf","Indulgence") or pq(card,"isKindOf","SupplyShortage")) then
			local dummy_use = pq(self,"aiUseCard",card, dummy())
			if dummy_use.card then continue end
		end

		if pq(friend,"hasSkill","enyuan") and #cards >= 1 and not (pq(self.room,"getMode") == "04_1v3" and ((pq(self.player,"getHandcardNum") + 2 > pq(self.player,"getMaxCards")) or (pq(self.player,"isWounded") and pq(self.player,"getMark","SixRende") < 2))) then
			use.card=final_parse(self,request,"#SixRendeCard:" .. pq(card,"getId") .. "+" .. cards[1]:getId() .. ":")
		else
			use.card=final_parse(self,request,"#SixRendeCard:" .. pq(card,"getId") .. ":")
		end
		if use.to then call(use.to,"append",friend) end
		return
	end

	if notFound then

		if pq(self.player,"getMark","SixRende") <= 1 or (pq(self.player,"getHandcardNum") + 2 < pq(self.player,"getMaxCards") and not pq(self.player,"isWounded")) or pq(self,"getOverflow") > 0 then
			local cards = AIList.new(pq(self.player,"getHandcards"))
			sort_use(self,cards, true)
			sort_players(self,self.friends_noself, "handcard")
			local give_all_cards = {}
			for _, c in ipairs(AIList.new(pq(self.player,"getCards","h"))) do
				table.insert(give_all_cards, pq(c,"getEffectiveId"))
			end
			local targets = {}
			for _, friend in ipairs(self.friends_noself) do
				if not pq(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
			if #targets > 0 and #give_all_cards > 1 then
				local card_str = string.format("#SixRendeCard:" .. give_all_cards[1] .. ":")
				local acard = parse(self,request,card_str)
				use.card = acard
				if use.to then
					call(use.to,"append",targets[1])
				end
				return
			end
		end



		local pangtong = call(self.room,"findPlayerBySkillName","manjuan")
		if not pangtong then pangtong = call(self.room,"findPlayerBySkillName","zishu") end
		if not pangtong then return end
		local cards = AIList.new(pq(self.player,"getHandcards"))
		sort_use(self,cards, true)
		if ((pq(self.player,"getHandcardNum") + 2 > pq(self.player,"getMaxCards")) or (pq(self.player,"isWounded") and pq(self.player,"getMark","SixRende") < 2)) then
			sort_use(self,cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
					table.insert(to_give, pq(card,"getId"))
				end
				if #to_give == 2 - pq(self.player,"getMark","SixRende") then break end
			end
			if #to_give > 0 then
				use.card=final_parse(self,request,"#SixRendeCard:" .. table.concat(to_give, "+") .. ":")
				if use.to then call(use.to,"append",pangtong) end
			end
		end
	end
end

sgs.ai_use_value["SixRendeCard"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["SixRendeCard"] = sgs.ai_use_priority.RendeCard

ai_audited_aliases.register{id="ai_card_intention.SixRendeCard",registry="ai_card_intention",path={"SixRendeCard"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
sgs.dynamic_value.benefit["SixRendeCard"] = true



sgs.ai_skill_choice.SixRende = function(self, choices, data)
	local items = pq(choices,"split","+")
	if table.contains(items, "SixRendeRecover") then
		if pq(self.player,"getHp") < self:getBestHp(self.player) then
			return "SixRendeRecover"
		end
	end

	if table.contains(items, "SixRendeDraw") then
		return "SixRendeDraw"
	end

	return "SixRendeCancel"
end

sgs.ai_use_revises.SixRende = function(self,card,use)
	if pq(self.player,"getLostHp")>1 and pq(self,"findFriendsByType",sgs.Friend_Draw) and pq(self.player,"getMark","SixRende") < 2 then
		if pq(card,"getTypeId")==1 
		or pq(card,"getTypeId")==3 and call(self,"getSameEquip",card)
		or pq(card,"getTypeId")==2 and not (pq(card,"targetFixed") and pq(card,"isDamageCard"))
		then return false end
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|SixRende"

local SixPaoxiao_skill = {}
SixPaoxiao_skill.name = "SixPaoxiao"
table.insert(package_skills, SixPaoxiao_skill)

SixPaoxiao_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self,"slashIsAvailable") then return nil end
	if pq(self.player,"hasFlag","SixPaoxiaoForbidden") then return nil end
	if not pq(self.player,"canSlashWithoutCrossbow") then return nil end

	return parse(self,request,"#SixPaoxiaoCard:.:")
end

sgs.ai_skill_use_func["#SixPaoxiaoCard"] = function(card,use,self,request)
	sort_players(self,self.enemies, "defense")
	remember_player(self,"MingceTarget",nil)
	local slash = call(self,"cloneEvaluationCard","slash")
	
	for _, enemy in ipairs(self.enemies) do
		if pq(self.player,"canSlash",enemy, slash) and not pq(self,"slashProhibit",slash, enemy)
			and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)
			and pq(enemy,"objectName") ~= pq(self.player,"objectName") then
			remember_player(self,"MingceTarget",enemy)
			break
		end
	end

	if recall_player(self,"MingceTarget") then
		use.card=final_parse(self,request,"#SixPaoxiaoCard:.:")
		if use.to then
			call(use.to,"append",recall_player(self,"MingceTarget"))
		end
	end
end

function sgs.ai_cardneed.SixPaoxiao(to,card,self)
	return pq(card,"isKindOf","Crossbow")
end

sgs.ai_use_value["SixPaoxiaoCard"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["SixPaoxiaoCard"] = sgs.ai_use_priority.Slash + 1


sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|SixLongdan"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|SixLongdan"

sgs.ai_skill_use["@@SixLongdan2"] = function(self, data, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")

	local card_str = ("slash:SixLongdan[%s:%s]=."):format("to_be_decided", 0)
	local use_card=parse(self,request,card_str)
	local dummy_use = pq(self,"aiUseCard",use_card,dummy())
	local targets = {}
	if not pq(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			if pq(self,"getDefenseSlash",p) < 6 then
				table.insert(targets, pq(p,"objectName"))
			end
		end
		if #targets > 0 then
			return pq(use_card,"getLegacyStringKey") .. "->" .. table.concat(targets, "+")
		end
	end


	return "."
end

sgs.ai_skill_use["@@SixLongdan1"] = function(self, data, method)
	local target
	local use_card
	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
		if scoped_flag(self,p,"SixLongdan_Target") then
			target = p
			break
		end
	end
	if target and pq(self,"isFriend",target) and pq(self.player,"getMark","SixLongdan_using") == 0 then
		local shouldUse = false

		local defense = 6
		local use = tag(self,"CurrentUseStruct"):toCardUse()

		local def = self:getDefense(target)
		local slash = use.card
		local eff = pq(self,"slashIsEffective",slash, target)
		if use.card and pq(self,"hasHeavyDamage",use.from, use.card, target) then
			shouldUse = true
		end
		if not pq(use.from,"canSlash",target, slash, false) then
		elseif pq(self,"slashProhibit",nil, target) then
		elseif eff then
			if pq(target,"getHp") == 1 and getCardsNum("Jink", target) == 0 then shouldUse = true end
			shouldUse = true
		end
		for _, card in ipairs(cards) do
			if not pq(card,"isKindOf","Peach") and not pq(self.player,"isCardLimited",card, method) and pq(card,"isKindOf","BasicCard") then
				use_card = card
				break
			end
		end
		if use_card and pq(self,"isFriend",target) then
			call(self,"updateIntention",self.player, target, -70)
			return "#SixLongdanCard:" .. pq(use_card,"getEffectiveId") .. ":"
		end
	end
	return "."
end



local SixSance_skill = {}
SixSance_skill.name = "SixSance"
table.insert(package_skills, SixSance_skill)
SixSance_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self.player,"hasUsed","#SixSanceCard") then
		return parse(self,request,"#SixSanceCard:.:")
	end
end

sgs.ai_skill_use_func["#SixSanceCard"] = function(card,use,self,request)
	local target = nil
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		target = friend
	end
	if target then
		local handcards = AIList.new(pq(self.player,"getCards","h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		sort_use(self,handcards)
		for _, c in ipairs(handcards) do
			if not pq(c,"isKindOf","Peach")
				and not pq(c,"isKindOf","Duel")
				and not pq(c,"isKindOf","Indulgence")
				and not pq(c,"isKindOf","SupplyShortage")
				and not (pq(self,"getCardsNum","Jink") == 1 and pq(c,"isKindOf","Jink"))
				and not (pq(self,"getCardsNum","Analeptic") == 1 and pq(c,"isKindOf","Analeptic"))
			then
				if spade_check and pq(c,"getSuit") == sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards, pq(c,"getEffectiveId"))
				elseif heart_check and pq(c,"getSuit") == sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards, pq(c,"getEffectiveId"))
				elseif club_check and pq(c,"getSuit") == sgs.Card_Club then
					club_check = false
					table.insert(discard_cards, pq(c,"getEffectiveId"))
				elseif diamond_check and pq(c,"getSuit") == sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards, pq(c,"getEffectiveId"))
				end
				if #discard_cards == 3 then
					break
				end
			end
		end

		if #discard_cards == 3 and target then
			local card_str = string.format("#SixSanceCard:%s:", table.concat(discard_cards, "+"))
			use.card=final_parse(self,request,card_str)
			if use.to then call(use.to,"append",target) end
		end
	end
end


sgs.ai_skill_askforag.SixSance = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	pq(self,"sortByCardNeed",to_obtain, true)
	if pq(self,"isWeak") then
		for card_id in ipairs(card_ids) do
			if disclosed(self,card_id):getSuit() == sgs.Card_Heart then
				return card_id
			end
		end
	end
	local target
	for _,friend in ipairs(self.friends_noself)do
		if pq(friend,"hasFlag","SixSance_from") then
			target = friend
			break
		end
	end
	if target and pq(self,"isWeak",target) then
		for card_id in ipairs(card_ids) do
			if disclosed(self,card_id):getSuit() == sgs.Card_Diamond then
				return card_id
			end
		end
	end
	if target then
		for card_id in ipairs(card_ids) do
			if disclosed(self,card_id):isBlack() then
				return card_id
			end
		end
	end
	for card_id in ipairs(card_ids) do
		if disclosed(self,card_id):getSuit() == sgs.Card_Spade then
			return card_id
		end
	end

	return to_obtain[1]:getEffectiveId()
end
sgs.ai_use_priority["SixSanceCard"] = 3
sgs.ai_use_value["SixSanceCard"] = 3
sgs.ai_card_intention["SixSanceCard"] = -80

function sgs.ai_cardneed.SixQucai(to, card)
	return pq(card,"getTypeId") == sgs.Card_TypeTrick
end

sgs.ai_skill_invoke.SixZhongyong = function(self, data)
	local target = pq(data,"toPlayer")
	local use = tag(self,"CurrentUseStruct"):toCardUse()
	if not pq(self,"isFriend",target) or pq(self,"isFriend",use.from) then return false end
	if use.card and pq(use.card,"isKindOf","Slash") then
		if pq(target,"hasSkills","liuli|tianxiang|ol_tianxiang") and pq(target,"getHandcardNum") > 1 then return false end
		if not pq(self,"slashIsEffective",use.card, target, use.from) then return false end
		if pq(self,"getCardsNum","Jink") > 0 then return true end
	end
	if pq(self,"needToLoseHp",target, use.from, use.card) then return false end
	if pq(self.player,"getHandcardNum") + pq(self.player,"getEquips"):length() < 2 and not pq(self,"isWeak",target) then return false end


	if pq(self,"isWeak",target) and not pq(self,"isWeak") then return true end

	return false
end


sgs.ai_skill_use["@@SixChouyuan"] = function(self, data, method)
	call(self,"updatePlayers")
	sort_players(self,self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getHp") <= 3 and pq(friend,"isWounded") and pq(self,"canDraw",friend, self.player) then
			return "#SixChouyuanCard:.:->" .. pq(friend,"objectName")
		end
	end
	sort_players(self,self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"isWounded") and (pq(enemy,"getHp") > 3 and not pq(enemy,"isKongcheng")) and pq(self,"doDisCard",enemy, "h") then
			return "#SixChouyuanCard:.:->" .. pq(enemy,"objectName")
		end
	end


	return "."
end

sgs.ai_skill_invoke.SixWujun = function(self, data)
	local target = call(self.room,"getCurrent")
	if target and pq(self,"isEnemy",target) then
		return true
	end

	return false
end

sgs.ai_choicemade_filter.skillInvoke.SixWujun = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = call(self.room,"getCurrent")
		call(self,"updateIntention",player, current, 50)
	end
end

sgs.ai_skill_cardask["@SixWujun"] = function(self, data, pattern, target, target2)
	if target and pq(self,"isFriend",target) and not call(self,"findLeijiTarget",target, 50, self.player) then
		return "."
	end
	if not pq(self.player,"canSlash",target, false) then return "." end

	local use_card
	if not pq(target,"hasSkill","yizhong") and not pq(target,"hasArmorEffect","renwang_shield") and not pq(target,"hasArmorEffect","vine") then
		local cards = AIList.new(pq(self.player,"getHandcards"))


		sort_keep(self,cards)
		local slash = call(self,"cloneEvaluationCard","slash")
		
		for _, card in ipairs(cards) do
			if pq(self,"getKeepValue",card, cards) <= pq(self,"getKeepValue",slash, cards) then
				local black_slash=owner_normal(self,"SixWujun","slash",{pq(card,"getEffectiveId")},"")
				if pq(self,"slashIsEffective",black_slash, target) then
					use_card = card
					break
				end
			end
		end
	end
	if pq(self,"needKongcheng",self.player, true) and pq(self.player,"getHandcardNum") == 1 then
		use_card = pq(self.player,"getHandcards"):first()
	end
	if use_card then
		local black_slash=owner_normal(self,"SixWujun","slash",{pq(use_card,"getEffectiveId")})
		return pq(black_slash,"getLegacyStringKey")
	end
	return "."
end

sgs.ai_target_revises.SixWujun = function(to, card, self)
	if pq(card,"isKindOf","DefensiveHorse") or pq(card,"isKindOf","OffensiveHorse")
	then
		return true
	end
end


local SixWuzhi_skill = {}
SixWuzhi_skill.name = "SixWuzhi"
table.insert(package_skills, SixWuzhi_skill)
SixWuzhi_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self.player,"hasUsed","#SixWuzhiCard") then
		return parse(self,request,"#SixWuzhiCard:.:")
	end
end

sgs.ai_skill_use_func["#SixWuzhiCard"] = function(card,use,self,request)
	local target = nil
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getJudgingArea"):length() > 0 then
			for _, judge in sgs.qlist(pq(friend,"getJudgingArea")) do
				if not pq(judge,"isKindOf","YanxiaoCard") then
					target = friend
					break
				end
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if pq(friend,"getEquips"):length() > 0 and pq(friend,"hasSkills",sgs.lose_equip_skill) then
				target = friend
				break
			end
		end
	end
	if not target then
		local handcards = AIList.new(pq(self.player,"getCards","h"))
		sort_use(self,handcards)
		local cards = {}
		for _, c in ipairs(handcards) do
			if pq(c,"isKindOf","Slash") then
				table.insert(cards,c)
			end
		end
		if #cards > 0 then
			local c,to = call(self,"getCardNeedPlayer",cards,false)
			if c and to then
				target = to
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"getEquips"):length() > 0 and not pq(enemy,"hasSkills",sgs.lose_equip_skill) then
				target = enemy
				break
			end
		end
	end
	if target then
		local handcards = AIList.new(pq(self.player,"getCards","h"))
		sort_use(self,handcards)
		local use_card
		for _, c in ipairs(handcards) do
			if pq(c,"isKindOf","Slash") then
				use_card = c
			end
		end

		if use_card and target then
			use.card=final_parse(self,request,"#SixWuzhiCard:" .. pq(use_card,"getEffectiveId") .. ":")
			if use.to then call(use.to,"append",target) end
		end
	end
end

sgs.ai_skill_choice.SixWuzhi = function(self, choices, data)
	local target = pq(data,"toPlayer")
	local items = pq(choices,"split","+")
	if table.contains(items, "SixWuzhiGet") then
		if pq(self,"isFriend",target) then
			if pq(self,"doDisCard",target, "ej", true) then
				return "SixWuzhiGet"
			end
		else
			return "SixWuzhiGet"
		end
	end
	if table.contains(items, "SixWuzhiDiscard") then
		if pq(self,"isEnemy",target) and pq(self,"doDisCard",target, "h", false, 2) then
			return "SixWuzhiDiscard"
		end
	end
	return "SixWuzhiCancel"
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SixWuzhiCard",registry="ai_choicemade_filter",path={"cardChosen","SixWuzhiCard"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
function sgs.ai_cardneed.SixWuzhi(to, card, self)
	return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
end

sgs.ai_skill_invoke.SixHusi = function(self, data)
	local move = pq(data,"toMoveOneTime")
	if pq(self.player,"isLord") and pq(self,"isWeak") then return false end
	if move.from and pq(self,"isFriend",move.from) and move.to and not pq(self,"isFriend",move.to) then
		return pq(move.card_ids,"length") >= 2 or pq(self,"isWeak",move.from)
	end
	if move.from and pq(move.from,"objectName") == pq(self.player,"objectName") then return not pq(self,"isWeak") end

	return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|SixToujing"

sgs.ai_skill_playerchosen.SixToujing = function(self, targets)
	local first, second
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _, friend in ipairs(targets) do
		if pq(self,"isFriend",friend) and pq(friend,"isAlive") and not (hasManjuanEffect(friend) and pq(friend,"getLostHp") == 0) then
			if pq(friend,"isLord") and pq(self,"isWeak",friend) then return friend end
			if not (pq(friend,"hasSkill","zhiji") and pq(friend,"getMark","zhiji") == 0 and not pq(self,"isWeak",friend) and pq(friend,"getPhase") == sgs.Player_NotActive) then
				if pq(self,"getRoleEstimate",friend) == "renegade" then
					second = friend
				elseif pq(self,"getRoleEstimate",friend) ~= "renegade" and not first then
					first = friend
				end
			end
		end
	end
	if first then return first end
	if second then return second end
	for _, friend in ipairs(targets) do
		if pq(self,"isFriend",friend) then
			return friend
		end
	end
	return targets[1]
end

sgs.ai_use_revises.SixToujing = function(self,card,use)
	if pq(card,"isKindOf","FireAttack") then
		if pq(self,"getAllPeachNum") + pq(self.player,"getHp") == 1 and pq(self.player,"getHandcardNum") > 1 and pq(self,"hasTrickEffective",card, self.player) and pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire) and not pq(self.player,"isChained") then
			use.card = card
			call(use.to,"append",self.player)
			return true
		end
	end
end

sgs.ai_skill_invoke.PlusYingwu = function(self, data)
	return not (pq(self.player,"hasSkill","yingzi") and pq(self.player,"hasSkill","yinghun"))
end


sgs.ai_skill_cardask["@PlusYingwu"] = function(self, data, pattern, target, target2)
	local use_card
	local cards = AIList.new(pq(self.player,"getHandcards"))
	if pq(self,"needToLoseHp") then return "." end

	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		use_card = card
		break
	end
	if pq(self,"needToThrowArmor") then use_card = call(self.player,"getArmor") end
	if pq(self,"needKongcheng",self.player, true) and pq(self.player,"getHandcardNum") == 1 then
		use_card = pq(self.player,"getHandcards"):first()
	end
	if use_card then
		return pq(use_card,"getLegacyStringKey")
	end
	return "."
end


sgs.ai_skill_choice.PlusYingwu = function(self, choices, data)
	local items = pq(choices,"split","+")
	if table.contains(items, "yinghun") then
		if pq(self.player,"getLostHp") > 2 then
			return "yinghun"
		end
	end
	return "yingzi"
end


sgs.ai_skill_invoke.SixLiangjie = function(self, data)
	return pq(self.player,"wholeHandCards"):isBlack() or pq(self.player,"wholeHandCards"):isRed()
end

sgs.ai_skill_invoke.SixLiangjieDraw = function(self, data)
	return true
end


sgs.ai_skill_cardask["@SixZenhui"] = function(self, data, pattern, target, target2)
	local current = call(self.room,"getCurrent")
	if current and pq(self,"isEnemy",current) then
		local use_card
		local cards = AIList.new(pq(self.player,"getHandcards"))

		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if pq(card,"getSuit") == sgs.Card_Spade then
				use_card = card
				break
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if pq(current,"inMyAttackRange",friend) then
				if use_card then
					return pq(use_card,"getLegacyStringKey")
				end
			end
		end
	end
	return "."
end



sgs.ai_skill_playerchosen["SixZenhui"] = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if pq(self,"isFriend",p) and (not pq(self,"needKongcheng",p, true) or hasManjuanEffect(p)) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["SixZenhui"] = function(self, from, to)
	call(self,"updateIntention",from, to, -30)
end

sgs.ai_skill_playerchosen.SixJiahuo = function(self, targets)
	for _,p in ipairs(call(self,"findPlayerToDiscard","h", false, false, targets))do
		return p
	end
	return nil
end

sgs.ai_skill_invoke.SixJiahuoSecond = function(self, data)
	return true
end


local SixChunlao_skill = {}
SixChunlao_skill.name = "SixChunlao"
table.insert(package_skills, SixChunlao_skill)
SixChunlao_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"isKongcheng") or pq(self.player,"hasUsed","#SixChunlaoCard") then return nil end
	return parse(self,request,"#SixChunlaoCard:.:")
end

sgs.ai_skill_use_func["#SixChunlaoCard"] = function(card,use,self,request)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	sort_players(self,self.enemies, "defense")

	self:setPriorityValue("#SixChunlaoCard",0.2)
	local suit_table = { "spade", "club", "heart", "diamond" }
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHandcardNum") > 0 then
			local max_suit_num, max_suit = 0, {}
			for i = 0, 3, 1 do
				local suit_num = getKnownCard(enemy, self.player, suit_table[i + 1])
				if suit_num > max_suit_num then
					max_suit_num = suit_num
					max_suit = { i }
				elseif suit_num == max_suit_num then
					table.insert(max_suit, i)
				end
			end
			if max_suit_num == 0 then
				max_suit = {}
				local suit_value = { 1, 1, 1.3, 1.5 }
				for _, skill in ipairs(sgs.getPlayerSkillList(enemy)) do
					if sgs[pq(skill,"objectName") .. "_suit_value"] then
						for i = 1, 4, 1 do
							local v = sgs[pq(skill,"objectName") .. "_suit_value"][suit_table[i]]
							if v then suit_value[i] = suit_value[i] + v end
						end
					end
				end
				local max_suit_val = 0
				for i = 0, 3, 1 do
					local suit_val = suit_value[i + 1]
					if suit_val > max_suit_val then
						max_suit_val = suit_val
						max_suit = { i }
					elseif suit_val == max_suit_val then
						table.insert(max_suit, i)
					end
				end
			end
			for _, card in ipairs(cards) do
				if pq(self,"getUseValue",card) < 6 and not (pq(card,"isKindOf","Peach") or pq(card,"isKindOf","Analeptic")) then
					use.card=final_parse(self,request,"#SixChunlaoCard:" .. pq(card,"getEffectiveId") .. ":")
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
			if getCardsNum("Peach", enemy, self.player) < 2 then
				for _, card in ipairs(cards) do
					if pq(self,"getUseValue",card) < 6 and not pq(self,"isValuableCard",card) and not (pq(card,"isKindOf","Peach") or pq(card,"isKindOf","Analeptic")) then
						use.card=final_parse(self,request,"#SixChunlaoCard:" .. pq(card,"getEffectiveId") .. ":")
						if use.to then call(use.to,"append",enemy) end
						return
					end
				end
			end
			if pq(self,"getOverflow") > 0 then
				for _, card in ipairs(cards) do
					use.card=final_parse(self,request,"#SixChunlaoCard:" .. pq(card,"getEffectiveId") .. ":")
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention["#SixChunlaoCard"] = function(self, card, from, tos)
	local to = tos[1]
	call(self,"updateIntention",from, to, 60)
end

sgs.ai_use_priority["#SixChunlaoCard"] = 0.2


function sgs.ai_cardsview_valuable.SixChunlao(self, class_name, player)
	if class_name == "Peach" and pq(player,"getPile","beer"):length() > 0 then
		local dying = pq(player,"getRoom"):getCurrentDyingPlayer()
		if dying then
			local analeptic = call(self,"cloneEvaluationCard","analeptic")
			
			if pq(dying,"isLocked",analeptic) then return nil end

			local give_card = {}
			for _, card_id in sgs.qlist(pq(self.player,"getPile","beer")) do
				table.insert(give_card, disclosed(self,card_id))
			end
			sort_keep(self,give_card)



			local diamond_cards = {}
			local heart_cards = {}
			local spade_cards = {}
			local club_cards = {}
			local use_cards = {}

			for _, c in ipairs(give_card) do
				if pq(c,"getSuit") == sgs.Card_Diamond then
					table.insert(diamond_cards, pq(c,"getEffectiveId"))
				elseif pq(c,"getSuit") == sgs.Card_Heart then
					table.insert(heart_cards, pq(c,"getEffectiveId"))
				elseif pq(c,"getSuit") == sgs.Card_Spade then
					table.insert(spade_cards, pq(c,"getEffectiveId"))
				elseif pq(c,"getSuit") == sgs.Card_Club then
					table.insert(club_cards, pq(c,"getEffectiveId"))
				end
			end

			if #diamond_cards >= 2 then
				table.insert(use_cards, diamond_cards[1])
				table.insert(use_cards, diamond_cards[2])
			elseif #heart_cards >= 2 then
				table.insert(use_cards, heart_cards[1])
				table.insert(use_cards, heart_cards[2])
			elseif #spade_cards >= 2 then
				table.insert(use_cards, spade_cards[1])
				table.insert(use_cards, spade_cards[2])
			elseif #club_cards >= 2 then
				table.insert(use_cards, club_cards[1])
				table.insert(use_cards, club_cards[2])
			end
			if #use_cards > 0 then
				return "#SixChunlaoWineCard:" .. use_cards[1] .. "+" .. use_cards[2] .. ":"
			end
		end
	end
end

ai_audited_aliases.register{id="ai_card_intention.SixChunlaoWineCard",registry="ai_card_intention",path={"SixChunlaoWineCard"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
sgs.save_skill = sgs.save_skill .. "|SixChunlao"

sgs.ai_skill_invoke.SevenMizhao = function(self, data)
	return sgs.ai_skill_playerchosen.SevenMizhao(self, pq(self.room,"getOtherPlayers",self.player)) ~= nil
end

sgs.ai_skill_playerchosen.SevenMizhao = function(self, targets)
	if (sgs.ai_skill_invoke.fangquan(self) or pq(self,"needKongcheng",self.player)) then
		local cards = AIList.new(pq(self.player,"getHandcards"))
		sort_keep(self,cards)
		if role_count(self,"rebel") == 0 then
			local lord = call(self.room,"getLord")
			if lord and pq(self,"isFriend",lord) and pq(lord,"objectName") ~= pq(self.player,"objectName") and not hasManjuanEffect(lord) then
				return lord
			end
		end

		local AssistTarget = call(self,"AssistTarget")
		if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) and not hasManjuanEffect(AssistTarget) then
			return AssistTarget
		end

		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and pq(friend,"hasSkills",sgs.cardneed_skill) then
				return friend
			end
		end

		sort_players(self,self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) then
				return friend
			end
		end
		
	end
	return nil
end

sgs.ai_playerchosen_intention.SevenMizhao = -80

sgs.ai_choicemade_filter.cardResponded["SevenJiujiajink"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            call(self,"updateIntention",player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = pq(player,"getRoom"):getOtherPlayers(get_jiujia(self))
        if lieges and not pq(lieges,"isEmpty") then
            if pq(player,"objectName") == pq(lieges,"last"):objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end

sgs.ai_skill_cardask["SevenJiujiajink"] = function(self,data)
	local target = pq(data,"toPlayer")
	if not pq(self,"isFriend",target) then return "." end
	return call(self,"getCardId","Jink") or "."
end

sgs.ai_choicemade_filter.cardResponded["SevenJiujiaslash"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            call(self,"updateIntention",player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = pq(player,"getRoom"):getOtherPlayers(get_jiujia(self))
        if lieges and not pq(lieges,"isEmpty") then
            if pq(player,"objectName") == pq(lieges,"last"):objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end
sgs.ai_skill_cardask["SevenJiujiaslash"] = function(self,data)
	local target = pq(data,"toPlayer")
	if not pq(self,"isFriend",target) then return "." end
	return call(self,"getCardId","Slash") or "."
end

sgs.ai_choicemade_filter.cardResponded["SevenJiujiapeach"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            call(self,"updateIntention",player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = pq(player,"getRoom"):getOtherPlayers(get_jiujia(self))
        if lieges and not pq(lieges,"isEmpty") then
            if pq(player,"objectName") == pq(lieges,"last"):objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end

sgs.ai_skill_cardask["SevenJiujiapeach"] = function(self,data)
	local target = pq(data,"toPlayer")
	if not pq(self,"isFriend",target) then return "." end
	return call(self,"getCardId","Peach") or "."
end

sgs.ai_choicemade_filter.skillInvoke.SevenJiujia = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        set_jiujia(self,player)
    end
end

sgs.ai_skill_invoke["SevenJiujia"] = function(self, data)
	return true
end

function sgs.ai_slash_prohibit.SevenJiujia(self, from, to, card)
    if pq(self,"isFriend",to) then
        return false
    end
    if pq(self,"canLiegong",to, from) then
        return false
    end
    local players = AIList.new(pq(self.room,"getOtherPlayers",to))
    for _, player in ipairs(players) do
        if pq(self,"isFriend",player, to) then
            if pq(player,"hasSkill","tiandu") and sgs.ai_slash_prohibit.tiandu(self, from, player, card) then
                return true
            end
            if pq(player,"hasLordSkill","hujia") and sgs.ai_slash_prohibit.hujia(self, from, player, card) then
                return true
            end
            if pq(player,"hasSkill","leiji") and sgs.ai_slash_prohibit.leiji(self, from, player, card) then
                return true
            end
            if pq(player,"hasSkill","weidi") and sgs.ai_slash_prohibit.weidi(self, from, player, card) then
                return true
            end
        end
    end
    return false
end

sgs.ai_skill_cardask["@@SevenJiujia"] = function(self, data, pattern)
    local target = pq(data,"toPlayer")
    if target and pq(self,"isFriend",target) then
        local cards = pq(self.player,"getCards","he")
        cards = AIList.new(cards)
        sort_keep(self,cards)
        for _,h in sgs.list(cards)do
            if pq(self,"matchesDiscardPattern",pattern,h)
            then return pq(h,"getEffectiveId") end
            if pq(h,"isKindOf",pattern)
            then return pq(h,"getEffectiveId") end
        end
        return call(self,"getCardId",pattern)
        
    end
    return "."
end

sgs.ai_choicemade_filter.cardResponded["@@SevenJiujia"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            call(self,"updateIntention",player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = pq(player,"getRoom"):getOtherPlayers(get_jiujia(self))
        if lieges and not pq(lieges,"isEmpty") then
            if pq(player,"objectName") == pq(lieges,"last"):objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end

sgs.ai_cardsview_valuable.SevenJiujia = function(self, class_name, player)
	local handcards = AIList.new(pq(self.player,"getCards","h"))
    local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
		["Peach"] = "peach",
	}
	local name = classname2objectname[class_name]
    if not name then return end
	local had_card = nil
	for _, c in ipairs(handcards) do
		if pq(c,"isKindOf",name) then
			had_card = c
            break
		end
	end
	if class_name == "Peach" and self.request.reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end

	if name and not pq(player,"hasFlag","Global_SevenJiujiaFailed") and had_card == nil and pq(player,"getPhase") == sgs.Player_NotActive  then
		return string.format("#SevenJiujiaCard:.:%s", name)
	end
end

local SevenJiujia_filter = function(self,player,carduse)
	if pq(carduse.card,"isKindOf","SevenJiujiaCard") then
		set_jiujia(self,player)
	end
end
table.insert(sgs.ai_choicemade_filter.cardUsed,SevenJiujia_filter)

local SixMiBian_skill = {}
SixMiBian_skill.name = "SixMiBian"
table.insert(package_skills, SixMiBian_skill)
SixMiBian_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self.player,"hasUsed","#SixMiBian") then
		return parse(self,request,"#SixMiBian:.:")
	end
end

sgs.ai_skill_use_func["#SixMiBian"] = function(card,use,self,request)
	local target = nil
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "handcard")
	local max = 0
	local slash = call(self,"cloneEvaluationCard","slash")
	
	for _, enemy in ipairs(self.enemies) do
		local x = 0
		if pq(self.player,"inMyAttackRange",enemy) then
			for _, friend in ipairs(self.friends) do
				if pq(friend,"inMyAttackRange",enemy) then
					if not pq(friend,"isKongcheng") and not pq(self,"slashProhibit",slash, enemy, friend)
						and pq(self,"slashIsEffective",slash, enemy, friend) and pq(self,"isGoodTarget",enemy, self.enemies, slash) then
						x = x + 1
					end
				end
			end
			if x > max then
				max = x
				target = enemy
			end
		end
	end

	if target == nil then return end

	local handcards = AIList.new(pq(self.player,"getCards","h"))
	local discard_cards = {}
	local spade_check = true
	local heart_check = true
	local club_check = true
	local diamond_check = true

	for _, c in ipairs(handcards) do
		if not pq(c,"isKindOf","Peach")
			and not pq(c,"isKindOf","Duel")
			and not pq(c,"isKindOf","Indulgence")
			and not pq(c,"isKindOf","SupplyShortage")
			and not (pq(self,"getCardsNum","Jink") == 1 and pq(c,"isKindOf","Jink"))
			and not (pq(self,"getCardsNum","Analeptic") == 1 and pq(c,"isKindOf","Analeptic"))
		then
			if spade_check and pq(c,"getSuit") == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, pq(c,"getEffectiveId"))
			elseif heart_check and pq(c,"getSuit") == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, pq(c,"getEffectiveId"))
			elseif club_check and pq(c,"getSuit") == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, pq(c,"getEffectiveId"))
			elseif diamond_check and pq(c,"getSuit") == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, pq(c,"getEffectiveId"))
			end
		end
	end
	if #discard_cards > 0 then
		use.card=final_parse(self,request,string.format("#SixMiBian:%s:", table.concat(discard_cards, "+")))
		if use.to then call(use.to,"append",target) end
	end
end

sgs.ai_skill_cardask["@SixMiBian"] = function(self, data, pattern, target)
	local dest = pq(data,"toPlayer")
	local slash = call(self,"cloneEvaluationCard","slash")
	
	if dest and not pq(self,"slashProhibit",slash, dest, self.player) and pq(self,"isEnemy",dest) and pq(self,"slashIsEffective",slash, dest, self.player) and pq(self,"isGoodTarget",dest, self.enemies, slash) then
		local cards = AIList.new(pq(self.player,"getCards","h"))
		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if string.find(pattern, pq(card,"getSuitString")) then
				return pq(card,"getLegacyStringKey")
			end
		end
	end
	return "."
end


sgs.ai_skill_invoke["SixJianCe"] = function(self, data)
	local target = pq(data,"toPlayer")
	local max_card = call(self,"getMaxCard")

	if target and pq(self,"isEnemy",target) and max_card then
		local max_point = pq(max_card,"getNumber")
		local enemy_max_card = call(self,"getMaxCard",target)
		if (enemy_max_card and max_point > pq(enemy_max_card,"getNumber"))
			or (enemy_max_card and max_point > pq(enemy_max_card,"getNumber") and max_point > 10)
			or (not enemy_max_card and max_point > 10) then
			if pq(self.player,"getHandcardNum") > pq(target,"getHandcardNum") then
				call(self,"remember","SixJianCe_card",pq(max_card,"getEffectiveId"))
				return true
			end
		end
	end
	return false
end



sgs.ai_skill_discard.SixJianCe = function(self, discard_num, optional, include_equip)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local to_discard = {}
	local compare_func = function(a, b)
		return pq(self,"getKeepValue",a) < pq(self,"getKeepValue",b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, pq(card,"getId"))
	end

	return to_discard
end

ai_audited_aliases.register{id="ai_cardneed.SixJianCe",registry="ai_cardneed",path={"SixJianCe"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
function sgs.ai_skill_pindian.SixJianCe(minusecard, self, requestor)
	local maxcard = call(self,"getMaxCard")
	return pq(self,"isFriend",requestor) and minusecard or (pq(maxcard,"getNumber") < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.SixShouLue",registry="ai_cardneed",path={"SixShouLue"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.ai_skill_invoke["SixYangShi"] = function(self, data)
	return true
end

sgs.ai_skill_invoke["SevenRenDe"] = function(self, data)
	if pq(self.player,"isWounded") or pq(self,"isWeak") or pq(self.player,"getHandcardNum") < 3 then
		return true
	end

	if #self.friends_noself >= #self.enemies then
		return true
	end

	return false
end

sgs.ai_skill_cardask["@SevenRenDe"] = function(self, data, pattern, target, target2)
	local target = pq(data,"toPlayer")
	local usable_cards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,usable_cards)

	if target then
		if pq(self,"isFriend",target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:getLegacyStringKey()
		else
			return usable_cards[1]:getLegacyStringKey()
		end
	end
	return "."
end




function sgs.ai_skill_invoke.SevenJuDi(self, data)
	return true
end

sgs.ai_skill_use["@@SevenJuDi"] = function(self, prompt)
	local enemynum = 0
	for _, enemy in ipairs(self.enemies) do
		if (not pq(self,"needKongcheng",enemy) and pq(self,"hasLoseHandcardEffective",enemy)) or call(self,"getDangerousCard",enemy) or call(self,"getValuableCard",enemy) then
			enemynum = enemynum + 1
		end
	end

	if enemynum == 0 then
		return "."
	end
	sort_players(self,self.enemies, "defense")

	local first_index, second_index, third_index
	for i = 1, #self.enemies do
		if ((not pq(self,"needKongcheng",self.enemies[i]) and pq(self,"hasLoseHandcardEffective",self.enemies[i]))
				or call(self,"getDangerousCard",self.enemies[i]) or call(self,"getValuableCard",self.enemies[i])) and not self.enemies[i]:isNude() and
			not (self.enemies[i]:hasSkill("guzheng") and call(self.room,"getCurrent"):getPhase() == sgs.Player_Discard) then
			if not first_index then
				first_index = i
			elseif not second_index then
				second_index = i
			else
				third_index = i
			end
		end
		if third_index then break end
	end
	if first_index then
		local first = self.enemies[first_index]:objectName()
		if first_index and not second_index then
			return ("#SevenJuDi:.:->%s"):format(first)
		elseif second_index and not third_index then
			local second = self.enemies[second_index]:objectName()
			return ("#SevenJuDi:.:->%s+%s"):format(first, second)
		else
			local second = self.enemies[second_index]:objectName()
			local third = self.enemies[third_index]:objectName()
			return ("#SevenJuDi:.:->%s+%s"):format(first, second, third_index)
		end
	end
end

sgs.ai_card_intention["#SevenJuDi"] = 80

sgs.double_slash_skill = sgs.double_slash_skill .. "|SevenKanLuan"

function sgs.ai_skill_invoke.SevenKanLuan(self, data)
	local discard_num = pq(self.player,"getHandcardNum") - pq(self.player,"getHp")
	if discard_num >= 3 then
		return false
	end
	local cardstr = source_uses["@@SevenKanLuan"](self, "@SevenKanLuan")
	if call(cardstr,"match","->") then
		return true
	end
	return false
end

sgs.ai_skill_use["@@SevenKanLuan"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local discard_num = pq(self.player,"getHandcardNum") - pq(self.player,"getHp")
	local discard_table = pq(self,"askForDiscard","dummyreason", discard_num, discard_num, false, true)


	local slash = call(self,"cloneEvaluationCard","slash")
	

	local dummy_use = pq(self,"aiUseCard",slash, dummy())
	local targets = {}
	if not pq(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, pq(p,"objectName"))
		end
	end
	if #targets > 0 then
		return "#SevenKanLuan:" .. table.concat(discard_table, "+") .. ":->" .. targets[1]
	end
	return "."
end

sgs.ai_cardneed.SevenKanLuan = function(to,card)
	return pq(to,"getHandcardNum") < pq(to,"getHp")
end

sgs.ai_skill_discard.SevenZhenShi = function(self, discard_num, optional, include_equip)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local target
	for _,p in sgs.list(AIList.new(pq(self.room,"getOtherPlayers",self.player)))do
		if pq(p,"hasFlag","SevenZhenShi") then
			target = p
            break
		end
	end
	local to_discard = {}
	local compare_func = function(a, b)
		return pq(self,"getKeepValue",a) < pq(self,"getKeepValue",b)
	end
	table.sort(cards, compare_func)
	local n = 2
	if target and pq(self,"isFriend",target) then n = pq(self,"getOverflow") end
	for _, card in ipairs(cards) do
		if #to_discard >= n then break end
		table.insert(to_discard, pq(card,"getId"))
	end

	return to_discard
end



sgs.ai_skill_playerchosen["SevenZhenShi"] = function(self, targets)
	local targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _, p in ipairs(targets) do
		if pq(self,"isFriend",p) and pq(p,"getHandcardNum") <= 1 and not pq(self,"needKongcheng",p, true) and not hasManjuanEffect(p) and pq(self,"canDraw",p, self.player) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if pq(self,"isFriend",p) and not hasManjuanEffect(p) and pq(self,"canDraw",p, self.player) then
			return p
		end
	end
	if pq(self,"isWeak") then
		return targets[1]
	end
	return nil
end

sgs.ai_playerchosen_intention["SevenZhenShi"] = -40

local SevenZhaoXiang_skill = {}
SevenZhaoXiang_skill.name = "SevenZhaoXiang"
table.insert(package_skills, SevenZhaoXiang_skill)
SevenZhaoXiang_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self.player,"hasUsed","#SevenZhaoXiang") then
		return parse(self,request,"#SevenZhaoXiang:.:")
	end
end

sgs.ai_skill_use_func["#SevenZhaoXiang"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.friends_noself, "defense")
	local target = nil
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getEquips"):length() > 0 and pq(self,"hasSkills",sgs.lose_equip_skill, friend) then
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if pq(self,"doDisCard",friend, "e", true) then
				target = friend
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if pq(friend,"getEquips"):length() > 0 then
				target = friend
			end
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then call(use.to,"append",target) end
end

sgs.ai_use_priority["SevenZhaoXiang"] = 7
sgs.ai_use_value["SevenZhaoXiang"] = 7
sgs.ai_card_intention["SevenZhaoXiang"] = -40


sgs.ai_can_damagehp.SevenTaoHui = function(self, from, card, to)
	return pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0
		and pq(self,"canLoseHp",from, card, to)
end


function sgs.ai_skill_invoke.SevenTaoHui(self, data)
	local sbdiaochan = call(self.room,"findPlayerBySkillName","lihun")
	if sbdiaochan and pq(sbdiaochan,"faceUp") and not pq(self,"willSkipPlayPhase",sbdiaochan)
		and (pq(self,"isEnemy",sbdiaochan) or (pq(self.room,"getTurnCount") <= 1 and pq(self,"getRoleEstimate",sbdiaochan) == "neutral")) then
		return false
	end
	if not pq(self.player,"faceUp") then return true end
	for _, friend in ipairs(self.friends) do
		if pq(self,"hasSkills","fangzhu|jilve", friend) then return true end
		if pq(friend,"hasSkill","junxing") and pq(friend,"faceUp") and not pq(self,"willSkipPlayPhase",friend)
			and not (pq(friend,"isKongcheng") and pq(self,"willSkipDrawPhase",friend)) then
			return true
		end
	end
	local current = call(self.room,"getCurrent")
	return pq(self,"isWeak") or
		not (pq(current,"getNextAlive"):objectName() == pq(self.player,"objectName") and pq(self.player,"faceUp"))
end

function sgs.ai_skill_invoke.SevenLangMou(self, data)
	return true
end

sgs.ai_skill_cardask["@SevenQuanBian-card"] = function(self, data)
	local judge = pq(data,"toJudge")

	if pq(self.room,"getMode"):find("_mini_46") and not pq(judge,"isGood") then return "$" .. pq(self.player,"handCards"):first() end
	if pq(self,"needRetrial",judge) then
		local cards = AIList.new(pq(self.player,"getHandcards"))
		if pq(self.player,"getPile","wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
				table.insert(cards, disclosed(self,id))
			end
		end
		local card_id = pq(self,"getRetrialCardId",cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end

function sgs.ai_cardneed.SevenQuanBian(to, card, self)
	for _, player in sgs.qlist(pq(self.room,"getAllPlayers")) do
		if pq(self,"getFinalRetrial",to) == 1 then
			if pq(player,"containsTrick","lightning") and not pq(player,"containsTrick","YanxiaoCard") then
				return pq(card,"getSuit") == sgs.Card_Spade and pq(card,"getNumber") >= 2 and pq(card,"getNumber") <= 9 and
					not pq(self,"hasSkills","hongyan|wuyan")
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipDrawPhase",player) then
				return pq(card,"getSuit") == sgs.Card_Club
			end
			if pq(self,"isFriend",player) and pq(self,"willSkipPlayPhase",player) then
				return pq(card,"getSuit") == sgs.Card_Heart
			end
		end
	end
end

sgs.SevenQuanBian_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

sgs.wizard_skill = sgs.wizard_skill .. "|SevenQuanBian"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|SevenQuanBian"

function sgs.ai_skill_invoke.SevenQuanBian(self, data)
	local card = pq(data,"toCard")
	sort_players(self,self.friends, "hp")
	sort_players(self,self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (pq(friend,"isWounded") and 10 or 0)
		if pq(self,"hasSkills",sgs.masochism_skill, friend) then
			down = down - 5
			if pq(friend,"isWounded") then up = up + 5 end
		end
		if pq(self,"needToLoseHp",friend, nil, nil, true) then down = down + 5 end
		if pq(self,"needToLoseHp",friend, nil, nil, true, true) and pq(friend,"isWounded") then up = up - 5 end

		if pq(self,"isWeak",friend) then
			if pq(friend,"isWounded") then up = up + 10 + (pq(friend,"isLord") and 20 or 0) end
			down = down - 10 - (pq(friend,"isLord") and 40 or 0)
			if pq(friend,"getHp") <= 1 and not pq(friend,"hasSkill","buqu") or pq(friend,"getPile","trauma"):length() > 4 then
				down = down - 20 - (pq(friend,"isLord") and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (pq(enemy,"isWounded") and 10 or 0)
		if pq(self,"hasSkills",sgs.masochism_skill, enemy) then
			down = down + 10
			if pq(enemy,"isWounded") then up = up - 10 end
		end
		if pq(self,"needToLoseHp",enemy, nil, nil, true) then down = down - 5 end
		if pq(self,"needToLoseHp",enemy, nil, nil, true, true) and pq(enemy,"isWounded") then up = up - 5 end

		if pq(self,"isWeak",enemy) then
			if pq(enemy,"isWounded") then up = up - 10 end
			down = down + 10
			if pq(enemy,"getHp") <= 1 and not pq(enemy,"hasSkill","buqu") then
				down = down + 10 + ((pq(enemy,"isLord") and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 and pq(card,"isBlack") then
		return true
	elseif up > 0 and pq(card,"isRed") then
		return true
	end
	return false
end

sgs.ai_skill_invoke.SevenChuaiYi = function(self, data)
	local damage = pq(data,"toDamage")
	if damage and damage.from and pq(self,"isEnemy",damage.from) then
		return true
	end
	return not pq(self,"needToLoseHp",damage.to, damage.from, damage.card)
end

sgs.ai_skill_cardask["@SevenChuaiYi-show"] = function(self, data)
	local damage = pq(data,"toDamage")
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_keep(self,cards)
	if damage.from and pq(self.player,"objectName") == pq(damage.from,"objectName") then
		if pq(self,"isEnemy",damage.to) then
			for _, card in ipairs(cards) do
				if getKnownCard(damage.to, self.player, pq(card,"getSuitString"), false, "h") > 0 then
					return "$" .. pq(card,"getEffectiveId")
				end
			end
		elseif pq(self,"isFriend",damage.to) and not pq(self,"needToLoseHp",damage.to, self.player, damage.card) then
			for _, card in ipairs(cards) do
				if getKnownCard(damage.to, self.player, pq(card,"getSuitString"), false, "h") == 0 then
					return "$" .. pq(card,"getEffectiveId")
				end
			end
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_ajustdamage_to.SevenChuaiYi = function(self, from, to, card, nature)
	if not pq(to,"isKongcheng")
	then
		if pq(self,"isFriend",to, from)
		then
			return -1
		else
			if pq(from,"objectName") ~= pq(self.player,"objectName")
			then
				if ((getKnownCard(to, self.player, "heart", false, "h") == 0 and getKnownCard(self.player, self.player, "heart", false, "h") > 0) or
						(getKnownCard(to, self.player, "spade", false, "h") == 0 and getKnownCard(self.player, self.player, "spade", false, "h") > 0) or
						(getKnownCard(to, self.player, "club", false, "h") == 0 and getKnownCard(self.player, self.player, "club", false, "h") > 0) or
						(getKnownCard(to, self.player, "diamond", false, "h") == 0 and getKnownCard(self.player, self.player, "diamond", false, "h") > 0)
					)

				then
					return -1
				end
			end
		end
	end
end



sgs.ai_skill_invoke.SevenZhiDi = function(self, data)
	local target = pq(data,"toPlayer")
	if target then
		if pq(self,"isEnemy",target) then
			return true
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.SevenZhiDi = function(self, player, promptlist)
	if #promptlist == "yes" then
		local lord = call(self.room,"getCurrent")
		if lord then
			call(self,"updateIntention",player, lord, 60)
		end
	end
end



sgs.ai_skill_choice["SevenZhiDi"] = function(self, choices, data)
	call(self,"updatePlayers")
	local who = pq(data,"toPlayer")
	local handcards = AIList.new(pq(who,"getHandcards"))
	local items = pq(choices,"split","+")
	for _, c in ipairs(handcards) do
		local flag = string.format("%s_%s_%s", "visible", pq(self.player,"objectName"), pq(who,"objectName"))
		if pq(c,"hasFlag","visible") or pq(c,"hasFlag",flag) then
			if table.contains(items, pq(c,"objectName")) then
				return c
			end
		end
	end
	return items[math.random(1, #items)]
end

function sgs.ai_cardsview_valuable.SevenWeiYuan(self, class_name, player)
	local dying = call(self.room,"getCurrentDyingPlayer")
	if not dying or pq(self,"isEnemy",dying, player) or pq(dying,"objectName") == pq(player,"objectName") then return end
	if pq(dying,"isLord") and pq(self,"isFriend",dying, player) then return "#SevenWeiYuan:.:" end

	
		local cards = pq(player,"getCards","he")
		cards = AIList.new(cards)
		for _, fcard in ipairs(cards) do
			if pq(fcard,"isKindOf","EquipCard") then
				return "#SevenWeiYuan:" .. pq(fcard,"getEffectiveId") .. ":"
			end
		end
	if pq(player,"getHp") >= 2 or getCardsNum("Analeptic", player, self.player) > 0
	then
		return "#SevenWeiYuan:.:"
	end
end

ai_audited_aliases.register{id="ai_card_intention.SevenWeiYuan",registry="ai_card_intention",path={"SevenWeiYuan"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_cardneed.SevenWeiYuan",registry="ai_cardneed",path={"SevenWeiYuan"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.save_skill = sgs.save_skill .. "|SevenWeiYuan"

sgs.ai_skill_choice["SevenJuGong"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	if pq(self,"getCardsNum","Peach") > 0 then
		return "loseHp"
	end
	if pq(self,"getAllPeachNum") < 1 then
		return "discard"
	end
	return items[math.random(1, #items)]
end


local SevenFenLiang_skill = {}
SevenFenLiang_skill.name = "SevenFenLiang"
table.insert(package_skills, SevenFenLiang_skill)
SevenFenLiang_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#SevenFenLiang") or pq(self.player,"getMark","@SevenFenLiang") < 1 then return end
	if #self.enemies == 0 then return end


	return parse(self,request,"#SevenFenLiang:.:")
end

sgs.ai_skill_use_func["#SevenFenLiang"] = function(wuqiancard, use, self)
	sort_players(self,self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target
	for _, enemy in ipairs(self.enemies) do
		if pq(self.player,"getCardCount") >= pq(self.player,"distanceTo",enemy) and pq(self.player,"distanceTo",enemy) < pq(enemy,"getHandcardNum") and pq(self,"doDisCard",enemy, "h") and pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not pq(self,"cantbeHurt",enemy) and pq(self,"canDamage",enemy,self.player,nil)  then
			target = enemy
			break
		end
	end
	if target then
		use.card=final_parse(self,request,"#SevenFenLiang:.:")
		if use.to then
			call(use.to,"append",target)
		end
	end
end

sgs.ai_use_value["#SevenFenLiang"] = 5
sgs.ai_use_priority["#SevenFenLiang"] = 10
sgs.ai_card_intention["#SevenFenLiang"] = 80


sgs.ai_skill_invoke.SevenPingPan = function(self, data)
	return true
end

-- Fixed donor tests #promptlist (integer) against the string "yes".
-- No role-row mutation is reachable for the dense public prompt DTO.
sgs.ai_choicemade_filter.skillInvoke.SevenPingPan = function(self,player,promptlist)
 if #promptlist == "yes" then error("invalid source length primitive",0)end
end

sgs.ai_skill_invoke.SevenHuBei = function(self, data)
	local target = pq(data,"toPlayer")
	if target and pq(self,"isFriend",target) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@SevenHuBei"] = function(self, data)
	local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, true, ".")
	if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

ai_audited_aliases.register{id="ai_cardneed.SevenXiaoRui",registry="ai_cardneed",path={"SevenXiaoRui"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_skill_use["@@SevenYingYong"] = function(self, prompt)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local duel = call(self,"cloneEvaluationCard","duel")
	
	local d = pq(self,"aiUseCard",duel)
	if d.card then
		dc = {}
		for _,p in sgs.list(d.to)do
			table.insert(dc,pq(p,"objectName"))
		end
		return "#SevenYingYong:.:->" .. table.concat(dc,"+")
	end

	for _, enemy in ipairs(self.enemies) do
		local eff = pq(self,"hasTrickEffective",duel, enemy, self.player) and pq(self,"isGoodTarget",enemy, self.enemies, duel)
		if pq(self.player,"isProhibited",enemy, duel) then
		elseif eff then
			return "#SevenYingYong:.:->" .. pq(enemy,"objectName")
		else
			return "."
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local eff = pq(self,"hasTrickEffective",duel, enemy, self.player) and pq(self,"isGoodTarget",enemy, self.enemies, duel)

		if pq(self.player,"isProhibited",enemy, duel) then
		elseif eff and def < 8 then
			return "#SevenYingYong:.:->" .. pq(enemy,"objectName")
		else
			return "."
		end
	end
	return "."
end

sgs.ai_skill_cardask["@SevenFuTui"] = function(self, data)
	local current = call(self.room,"getCurrent")
	local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
	if #to_discard > 0 and current and pq(self,"isEnemy",current) and not pq(current,"hasFlag","Global_PlayPhaseTerminated") then
		return
			"$" .. to_discard[1]
	else
		return "."
	end
end

sgs.ai_choicemade_filter.cardResponded["@SevenFuTui"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player, current, 80)
	end
end

sgs.ai_skill_invoke.SevenYiZe = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.SevenYiZe = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getEquips"):length() > 0 and (pq(self,"hasSkills",sgs.lose_equip_skill, friend) or pq(self,"doDisCard",friend, "e")) then
			return friend
		end
	end
	
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getEquips"):length() > 0 then
			if (pq(self,"doDisCard",enemy, "e")) then
				return enemy
			end
		end
	end
end


sgs.ai_skill_choice.SevenZhengBian = function(self, choices, data)
	local target = pq(data,"toPlayer")
	if pq(self,"isFriend",target) then return "SevenZhengBian_equip" end
	if pq(self,"isEnemy",target) and pq(self,"doDisCard",target, "e", true) then return "SevenZhengBian_equip" end
	return "SevenZhengBian_limit"
end

local SevenZhengBian_skill = {}
SevenZhengBian_skill.name = "SevenZhengBian"
table.insert(package_skills, SevenZhengBian_skill)
SevenZhengBian_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#SevenZhengBian") then return end
	return parse(self,request,"#SevenZhengBian:.:")
end
sgs.ai_skill_use_func["#SevenZhengBian"] = function(card,use,self,request)
	local player = self.player
	local room = pq(player,"getRoom")
	local cards = AIList.new(pq(player,"getCards","he"))
	for _, card in ipairs(cards) do
		if not pq(card,"isKindOf","EquipCard") then table.removeOne(cards, card) end
	end
	sort_keep(self,cards, false)
	local players = AIList.new(pq(room,"getAlivePlayers"))
	local targets, friends, enemies = {}, {}, {}
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
		if not pq(p,"isKongcheng") then
			table.insert(targets, p)
			if pq(self,"isFriend",p) then
				table.insert(friends, p)
			elseif pq(self,"isEnemy",p) and pq(self,"doDisCard",p, "e", true) then
				table.insert(enemies, p)
			end
		end
	end

	if #targets == 0 then return end
	local target


	if not target then
		for _, enemy in ipairs(enemies) do
			if call(self,"getDangerousCard",enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _, enemy in ipairs(enemies) do
			if call(self,"getValuableCard",enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _, friend in ipairs(friends) do
			if pq(self,"needToThrowArmor",friend) or pq(friend,"hasArmorEffect","silver_lion") or pq(friend,"hasSkill","yqijiang") then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(enemies) do
			if pq(self,"hasSkills",sgs.concentrated_skill, enemy) and pq(self,"doDisCard",enemy, "e") then
				if call(enemy,"getDefensiveHorse") then
					target = enemy
					break
				end
				if not target then
					if call(enemy,"getArmor") and not pq(self,"needToThrowArmor",enemy) then
						target = enemy
						break
					end
				end
			end
		end
	end
	if not target and pq(self,"getCardsNum","Slash") > 0 then
		local slash = call(self,"getCard","Slash")
		assert(slash)

		local dummy_use = pq(self,"aiUseCard",slash, dummy())
		if dummy_use.card and dummy_use.to and pq(dummy_use.to,"length") > 0 then
			for _, p in sgs.qlist(dummy_use.to) do
				if not pq(self,"canHit",p, self.player) or (pq(p,"getHp") <= 1 and pq(self,"getAllPeachNum",p) > 0) then
					target = p
					break
				end
			end
		end
	end

	local cards = AIList.new(pq(player,"getCards","he"))
	sort_use(self,cards, true)
	local subcard
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","EquipCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	if not target then
		use.card = nil
		return
	end
	use.card=final_parse(self,request,"#SevenZhengBian:"..pq(subcard,"getEffectiveId")..":")
	sort_players(self,targets, "handcard")
	if use.to then call(use.to,"append",target) end
end





sgs.ai_use_value["SevenZhengBian"] = 9
sgs.ai_use_priority["SevenZhengBian"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["SevenZhengBian"] = sgs.ai_card_intention.Dismantlement

ai_audited_aliases.register{id="ai_cardneed.SevenZhengBian",registry="ai_cardneed",path={"SevenZhengBian"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.ai_skill_cardask["@SevenQuGao-discard"] = function(self, data)
	local use = pq(data,"toCardUse")
	if pq(self,"isFriend",use.from) then
		if use.card and pq(use.card,"isKindOf","IronChain") then
			return "."
		end
		local shouldUse = false
		local dummy_use = pq(self,"aiUseCard",use.card, dummy())
		if dummy_use.card then shouldUse = true end


		local card_id
		local hcards = pq(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_use(self,hcards, true)
		for _, hcard in ipairs(hcards) do
			if pq(self.player,"canDiscard",self.player, pq(hcard,"getId")) and pq(hcard,"getSuitString") == pq(use.card,"getSuitString") and pq(self,"getUseValue",hcard) < pq(self,"getUseValue",use.card) then
				card_id = pq(hcard,"getEffectiveId")
				break
			end
		end

		if shouldUse and card_id then
			return "$" .. card_id
		end
	elseif pq(self,"isFriend",pq(use.to,"first")) then
		if not use.from or pq(use.from,"isDead") then return "cancel" end
		if self.role == "rebel" and pq(self,"getRoleEstimate",use.from) == "rebel" and not pq(self,"hasJueqingEffect",use.from, pq(use.to,"first"), sgs.card_damage_nature[pq(use.card,"getClassName")])
			and pq(self.player,"getHp") == 1 and pq(self,"getAllPeachNum") < 1 then
			return "."
		end
		local card_id
		local hcards = pq(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_use(self,hcards, true)
		for _, hcard in ipairs(hcards) do
			if pq(self.player,"canDiscard",self.player, pq(hcard,"getId")) and pq(hcard,"getSuitString") == pq(use.card,"getSuitString") and pq(self,"getUseValue",hcard) < pq(self,"getUseValue",use.card) then
				card_id = pq(hcard,"getEffectiveId")
				break
			end
		end
		if card_id then
			if pq(self,"isEnemy",use.from) or (pq(self,"isFriend",use.from) and self.role == "loyalist" and not pq(self,"hasJueqingEffect",use.from, pq(use.to,"first"), sgs.card_damage_nature[pq(use.card,"getClassName")]) and pq(use.from,"isLord") and pq(self.player,"getHp") == 1) then
				if pq(use.card,"isKindOf","AOE") then
					local from = use.from
					if pq(use.card,"isKindOf","SavageAssault") then
						local menghuo = call(self.room,"findPlayerBySkillName","huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
						if pq(self,"isFriend",p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
						if pq(self,"isEnemy",p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
					end
					friend_null = friend_null + pq(self,"getCardsNum","Nullification")
					local sj_num = pq(self,"getCardsNum",pq(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

					if pq(self,"hasTrickEffective",use.card, self.player, from) then
						if pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, from) then
							if pq(use.from,"hasSkill","drwushuang") and pq(self.player,"getCardCount") == 1 and pq(self,"hasLoseHandcardEffective") then
								return
									"$" .. card_id
							end
							if sj_num == 0 and friend_null <= 0 then
								if pq(self,"isEnemy",from) and pq(self,"hasJueqingEffect",from, pq(use.to,"first"), sgs.card_damage_nature[pq(use.card,"getClassName")]) then
									return
										"$" .. card_id
								end
								if pq(self,"isFriend",from) and self.role == "loyalist" and pq(from,"isLord") and pq(self.player,"getHp") == 1 and not pq(self,"hasJueqingEffect",from, pq(use.to,"first"), sgs.card_damage_nature[pq(use.card,"getClassName")]) then
									return
										"$" .. card_id
								end
								if (not (pq(self,"hasSkills",sgs.masochism_skill) or (pq(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or pq(self,"hasJueqingEffect",from, pq(use.to,"first"), sgs.card_damage_nature[pq(use.card,"getClassName")])) then
									return "$" .. card_id
								end
							end
						end
					end
				elseif pq(self,"isEnemy",use.from) then
					if pq(use.card,"isKindOf","FireAttack") and pq(use.from,"getHandcardNum") > 0 then
						if pq(self,"hasTrickEffective",use.card, self.player) then
							if pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, use.from) then
								if (pq(self.player,"hasArmorEffect","vine") or pq(self.player,"getMark","@gale") > 0) and pq(use.from,"getHandcardNum") > 3
									and not (pq(use.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
									return "$" .. card_id
								elseif pq(self.player,"isChained") and not pq(self,"isGoodChainTarget",self.player, use.from) then
									return "$" .. card_id
								end
							end
						end
					elseif (pq(use.card,"isKindOf","Snatch") or pq(use.card,"isKindOf","Dismantlement"))
						and not pq(self.player,"isKongcheng") then
						if pq(self,"hasTrickEffective",use.card, self.player) then
							return "$" .. card_id
						end
					elseif pq(use.card,"isKindOf","Duel") then
						if pq(self,"getCardsNum","Slash") == 0 or pq(self,"getCardsNum","Slash") < getCardsNum("Slash", use.from, self.player) then
							if pq(self,"hasTrickEffective",use.card, self.player) then
								if pq(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, use.from) then
									return "$" .. card_id
								end
							end
						end
					end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.SevenQuGao = function(self, choices, data)
	local use = pq(data,"toCardUse")
	local items = pq(choices,"split","+")
	if pq(self,"isFriend",use.from) then
		return "SevenQuGao_double"
	elseif pq(self,"isFriend",pq(use.to,"first")) then
		return "SevenQuGao_invalid"
	end
	return items[math.random(1, #items)]
end

sgs.ai_skill_choice.SevenBaChao = function(self, choices)
	if pq(self.player,"getMaxHp") >= pq(self.player,"getHp") + 2 then
		if pq(self.player,"getMaxHp") > 5 and (pq(self.player,"hasSkills","nosmiji|yinghun|juejing|zaiqi|nosshangshi") or pq(self.player,"hasSkill","miji") and call(self,"findPlayerToDraw",false)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if pq(p,"inMyAttackRange",self.player) and not pq(self,"willSkipPlayPhase",p) then enemy_num = enemy_num + 1 end
			end
			local ls = self:getStrategyMemory("fangquan_effect") and call(self.room,"findPlayerBySkillName","fangquan")
			if ls then
				call(self,"setStrategyMemory","fangquan_effect",false)
				enemy_num = pq(self,"getEnemyNumBySeat",ls, self.player, self.player)
			end
			local least_hp = pq(self.player,"isLord") and math.max(2, enemy_num - 1) or 1
			if (pq(self,"getCardsNum","Peach") + pq(self,"getCardsNum","Analeptic") + pq(self.player,"getHp") > least_hp) then
				return
				"hp"
			end
		end
		return "maxhp"
	else
		return "hp"
	end
end

sgs.bad_skills = sgs.bad_skills .. "|SevenBaChao"

local SevenLuanZheng_skill = {}
SevenLuanZheng_skill.name = "SevenLuanZheng"
table.insert(package_skills, SevenLuanZheng_skill)
SevenLuanZheng_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#SevenLuanZheng") then return end
	return parse(self,request,"#SevenLuanZheng:.:")
end

sgs.ai_skill_use_func["#SevenLuanZheng"] = function(card,use,self,request)
	use.card = card
end


sgs.ai_skill_cardask["@SevenJieMing"] = function(self, data)
	local target = pq(data,"toDamage").to
	if pq(self,"isFriend",target) then return "." end
	local to_discard = pq(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
	if #to_discard > 0 then
		return "$" .. to_discard[1]
	else
		return "."
	end
end

sgs.ai_ajustdamage_to.SevenJieMing = function(self, from, to, card, nature)
	if from and (pq(from,"isKongcheng") or pq(self,"beFriend",to,from))
	then
		return -1
	end
end

sgs.ai_skill_invoke.SevenTaDao = function(self, data)
	local target = pq(data,"toPlayer")
	if target and pq(self,"isEnemy",target) then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen.SevenTaDao = function(self, targets)
	local target = call(self,"findPlayerToDamage",1, self.player, "N", targets)[1]
	return target
end
sgs.ai_skill_invoke.SevenMiDao = function(self, data)
	return true
end


local SevenChuanJiao_skill = {}
SevenChuanJiao_skill.name = "SevenChuanJiao"
table.insert(package_skills, SevenChuanJiao_skill)
SevenChuanJiao_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#SevenChuanJiao") then return end
	return parse(self,request,"#SevenChuanJiao:.:")
end

sgs.ai_skill_use_func["#SevenChuanJiao"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_choice.SevenChuanJiao = function(self, choices, data)
	local items = pq(choices,"split","+")
	local red_friend = 0
	local black_friend = 0
	local red_enemy = 0
	local black_enemy = 0

	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(p,"hasFlag","SevenChuanJiaored") then
			if pq(self,"isFriend",p) then
				red_friend = red_friend + 1
			elseif pq(self,"isEnemy",p) then
				red_enemy = red_enemy + 1
			end
		elseif pq(p,"hasFlag","SevenChuanJiaoblack") then
			if pq(self,"isFriend",p) then
				black_friend = black_friend + 1
			elseif pq(self,"isEnemy",p) then
				black_enemy = black_enemy + 1
			end
		end
	end
	local x = red_friend - red_enemy
	local y = black_friend - black_enemy
	if x > y then
		return "red"
	else
		return "black"
	end

	return items[math.random(1, #items)]
end




local SevenFengPing_skill = {}
SevenFengPing_skill.name = "SevenFengPing"
table.insert(package_skills, SevenFengPing_skill)
SevenFengPing_skill.getTurnUseCard=function(self,inclusive,request)
	if not pq(self.player,"hasUsed","#SevenFengPing") then
		return parse(self,request,"#SevenFengPing:.:")
	end
end

sgs.ai_skill_use_func["#SevenFengPing"] = function(card,use,self,request)
	sort_players(self,self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"doDisCard",enemy, "he") then
			use.card=final_parse(self,request,"#SevenFengPing:.:")
			if use.to then
				call(use.to,"append",enemy)
			end
		end
		return
	end
end

sgs.ai_use_value.SevenFengPing = 2.5
sgs.ai_card_intention.SevenFengPing = 0



sgs.ai_skill_choice.SevenFengPing = function(self, choices, data)
	local items = pq(choices,"split","+")
	local target = pq(data,"toPlayer")
	if pq(self,"isFriend",target) then return "red" end
	if pq(self,"isEnemy",target) then return "black" end

	return items[math.random(1, #items)]
end

sgs.ai_choicemade_filter.skillChoice["SevenFengPing"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target = tag(self,"SevenFengPing"):toPlayer()
	if choice == "red" then
		call(self,"updateIntention",player, target, -80)
	else
		call(self,"updateIntention",player, target, 80)
	end
end


sgs.ai_skill_cardask["@SevenFengPing"] = function(self, data, pattern, target)
	local target = pq(data,"toPlayer")
	if pq(self,"isFriend",target) then return "." end
	local card_id
	local hcards = pq(self.player,"getCards","h")
	hcards = AIList.new(hcards)
	sort_use(self,hcards, true)
	local types = pq(pattern,"split","|")[2]
	for _, hcard in ipairs(hcards) do
		if pq(self.player,"canDiscard",self.player, pq(hcard,"getId")) and pq(hcard,"getColorString") == types then
			card_id = pq(hcard,"getEffectiveId")
			break
		end
	end
	if card_id then
		return "$" .. card_id
	end

	return "."
end
sgs.ai_skill_invoke.SevenYueDan = function(self, data)
	local ids = tag(self,"SevenFengPing"):toString():split("+") or {}
	if #ids == 0 then return false end
	local x = 0
	for _, id in pairs(ids) do
		if disclosed(self,id):isKindOf("BasicCard") and pq(self.room,"getCardPlace",tonumber(id)) == sgs.Player_DiscardPile then
			x = x + 1
		end
	end
	if x >= 3 then
		return true
	end
	return false
end


for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end

local response_use_keys={["@@SevenJuDi"]=true,["@@SevenKanLuan"]=true,["@@SevenYingYong"]=true,["@@SixChouyuan"]=true,["@@SixGuicai2"]=true,["@@SixLongdan1"]=true,["@@SixLongdan2"]=true,["@@SixMingduan"]=true,["@@SixWulveOthers!"]=true,["@@SixZhidi"]=true,["@PlusCuorui"]=true,["@PlusFuzheng"]=true,["@PlusGuicai2"]=true,["@PlusGuidao2"]=true,["@PlusJiahuo"]=true,["@PlusJiangcai"]=true,["@PlusJianxiong"]=true,["@PlusKuangjun"]=true,["@PlusLeiji"]=true,["@PlusLiangyuan"]=true,["@PlusLiuli"]=true,["@PlusLuoyi"]=true,["@PlusShensu1"]=true,["@PlusShensu2"]=true,["@PlusTianxiang"]=true,["@PlusYiji"]=true,["@PlusYizhong"]=true,["@PlusYuanmou"]=true,["@PlusZhongyong"]=true,["@SixTaohui"]=true}
for key in pairs(response_use_keys)do local source=sgs.ai_skill_use[key];source_uses[key]=source
 sgs.ai_skill_use[key]=function(self,...)
  local wire=source(self,...);if wire==nil or wire=='.'or type(wire)~='string'then return wire end
  local cardwire,targets=wire:match('^(.-)%-%>(.*)$');cardwire=cardwire or wire
  local use=AIUsePlan.new();use.card=final_parse(self,nil,cardwire)
  if targets then for _,name in ipairs(targets:split('+'))do use.to:append(known(find(self,name),'response target'))end end
  return use:toAnswer()
 end
end
local function response_descriptor(self,wire)
 if type(wire)~='string'or wire=='.'then return wire end
 local class,costs,user=wire_parts(wire)
 if class then local value={skill=known(skill_cards[class],class),legacy_class=class,subcards=costs};if user then value.user_string=user end;return value end
 local name,skill,costs=normal_parts(wire);return spec(self,skill,name,costs)
end
do local source=sgs.ai_cardsview["PlusSheji"];sgs.ai_cardsview["PlusSheji"]=function(self,...)return response_descriptor(self,source(self,...))end end
do local source=sgs.ai_cardsview_valuable["SevenJiujia"];sgs.ai_cardsview_valuable["SevenJiujia"]=function(self,...)return response_descriptor(self,source(self,...))end end
do local source=sgs.ai_cardsview_valuable["SevenWeiYuan"];sgs.ai_cardsview_valuable["SevenWeiYuan"]=function(self,...)return response_descriptor(self,source(self,...))end end
do local source=sgs.ai_cardsview_valuable["SixChunlao"];sgs.ai_cardsview_valuable["SixChunlao"]=function(self,...)return response_descriptor(self,source(self,...))end end
do local source=sgs.ai_view_as["PlusLongdan"];sgs.ai_view_as["PlusLongdan"]=function(card,player,...)
 local wire=source(card,player,...);if wire==nil then return end
 local name,skill,costs=normal_parts(wire)
 if #costs~=1 or costs[1]~=pq(card,'getEffectiveId')then ai_unsupported('view-as material differs from supplied owner card','biaofeng.view_as')end
 return{name=name,skill=skill,suit=pq(card,'getSuit'),number=pq(card,'getNumber'),subcards=costs}
end end
do local source=sgs.ai_view_as["PlusWusheng"];sgs.ai_view_as["PlusWusheng"]=function(card,player,...)
 local wire=source(card,player,...);if wire==nil then return end
 local name,skill,costs=normal_parts(wire)
 if #costs~=1 or costs[1]~=pq(card,'getEffectiveId')then ai_unsupported('view-as material differs from supplied owner card','biaofeng.view_as')end
 return{name=name,skill=skill,suit=pq(card,'getSuit'),number=pq(card,'getNumber'),subcards=costs}
end end

-- Serialized SkillCard responses are selected first, then bound by native scope.
do local source=sgs.ai_skill_cardask["#PlusRende_Salvation"];sgs.ai_skill_cardask["#PlusRende_Salvation"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@@SevenJiujia"];sgs.ai_skill_cardask["@@SevenJiujia"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusGuicai-card"];sgs.ai_skill_cardask["@PlusGuicai-card"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusGuidao-card"];sgs.ai_skill_cardask["@PlusGuidao-card"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusMafei_Prompt"];sgs.ai_skill_cardask["@PlusMafei_Prompt"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusQiaojian_Prompt"];sgs.ai_skill_cardask["@PlusQiaojian_Prompt"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusQixi_prompt"];sgs.ai_skill_cardask["@PlusQixi_prompt"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusTaohui"];sgs.ai_skill_cardask["@PlusTaohui"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusYingwu"];sgs.ai_skill_cardask["@PlusYingwu"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusZhongyong_Slash"];sgs.ai_skill_cardask["@PlusZhongyong_Slash"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@PlusZhuni"];sgs.ai_skill_cardask["@PlusZhuni"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenChuaiYi-show"];sgs.ai_skill_cardask["@SevenChuaiYi-show"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenFengPing"];sgs.ai_skill_cardask["@SevenFengPing"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenFuTui"];sgs.ai_skill_cardask["@SevenFuTui"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenHuBei"];sgs.ai_skill_cardask["@SevenHuBei"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenJieMing"];sgs.ai_skill_cardask["@SevenJieMing"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenQuGao-discard"];sgs.ai_skill_cardask["@SevenQuGao-discard"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenQuanBian-card"];sgs.ai_skill_cardask["@SevenQuanBian-card"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SevenRenDe"];sgs.ai_skill_cardask["@SevenRenDe"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SixGuicai"];sgs.ai_skill_cardask["@SixGuicai"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SixHuwei"];sgs.ai_skill_cardask["@SixHuwei"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SixMiBian"];sgs.ai_skill_cardask["@SixMiBian"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SixQiaoxie"];sgs.ai_skill_cardask["@SixQiaoxie"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SixWujun"];sgs.ai_skill_cardask["@SixWujun"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["@SixZenhui"];sgs.ai_skill_cardask["@SixZenhui"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["SevenJiujiajink"];sgs.ai_skill_cardask["SevenJiujiajink"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["SevenJiujiapeach"];sgs.ai_skill_cardask["SevenJiujiapeach"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
do local source=sgs.ai_skill_cardask["SevenJiujiaslash"];sgs.ai_skill_cardask["SevenJiujiaslash"]=function(self,...)
 local value=source(self,...)
 if type(value)=='string'and value:sub(1,1)=='#'then return final_parse(self,nil,value)end
 return value
end end
