-- Source: b6025acc ai/biaofeng-ai.lua.
local package_skills={}
local source_uses={}
local known = AIValue.requireKnown

local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
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
local function ids(cards)local out={};for _,c in ipairs(cards)do out[#out+1]=type(c)=='number'and c or c:getKnownEffectiveId()end;return out end
local function spec(self,skill,name,costs)
 local suit,number=sgs.Card_NoSuit,0;local red,black=true,true
 for _,id in ipairs(costs)do local c=disclosed(self,id);red=red and c:isRed();black=black and c:isBlack()end
 if #costs==1 then local c=disclosed(self,costs[1]);suit,number=c:getSuit(),c:getNumber()elseif #costs>1 then suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 return{name=name,skill=skill,suit=suit,number=number,subcards=costs}
end
local function turn_normal(self,skill,name,costs,request)
 local value=spec(self,skill,name,costs)
 return self:evaluateTurnConversion(skill, (self:getEvaluationCard(name)):getClassName(), value, action_request(self,request))
end
local function owner_normal(self,skill,name,costs,output_skill)
 local value=spec(self,output_skill or skill,name,costs);value.source_key=skill
 return self:evaluateOwnerViewAsCard(value)
end
local function owner_clone(self,source,name,suit,number)
 return self:evaluateOwnerViewAsCard({source_key=source,skill='',name=name,suit=suit,number=number,subcards={}})
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
  return self:evaluateTurnSkillCard(skill, class, costs, action_request(self,request), user)
 end
 local name,skill,material=normal_parts(wire);return turn_normal(self,skill,name,material,request)
end
local function final_parse(self,request,wire)
 local class,costs,user=wire_parts(wire)
 if class then return self:bindSkillCard(known(skill_cards[class],class), costs, action_request(self,request), user, class)end
 local name,skill,material=normal_parts(wire)
 return self:bindOriginalSelectedConversion(spec(self,skill,name,material), (self:getEvaluationCard(name)):getClassName(), skill, false)
end
local function property_card(self,skill,wire)local name,_,costs=normal_parts(wire);return owner_normal(self,skill,name,costs)end
local dummy = AIUsePlan.dummy
local function role(self,p)local v=p:getRole();if v~=nil then return v end;return self:useKnowledgeEstimate({status='estimate',value=self:getRoleEstimate(p),basis='viewer_role_estimate_private_role',player=p:objectName()}, 'biaofeng.role')end
local function role_count(self,key)return known(known(self.world.mode_policy,'mode policy').role_counts,'role counts')[key]or ai_unsupported('role count unknown',key)end
local function scoped_flag(self,player,name)
 local rows=self:getDecisionContext().biaofeng_flags
 local value=type(rows)=='table'and rows[player:objectName()]
 value=type(value)=='table'and value[name]
 if type(value)=='boolean'then return value end
 return player:hasFlag(name)
end
local function yizhong_mark(self,player)
 local rows=self:getDecisionContext().biaofeng_yizhong_marks
 local value=type(rows)=='table'and rows[player:objectName()]
 if type(value)=='number'then return value end
 return player:getMark('PlusYizhong')
end
local function owner_fact(self,key)
 if key=='jilve_wansha'then
  -- The viewer's own JilveWansha tag read through toBool(); absent is false.
  local v=self.player:getTag('JilveWansha');if v==nil then return false end
  if type(v)~='boolean'then ai_unsupported('JilveWansha tag is not a boolean',key)end;return v
 end
 if key=='six_wulve_card'then return known(self:getDecisionContext().biaofeng_six_wulve_card,key)end
 ai_unsupported('biaofeng fact is not projected',key)
end
local function find(self,name)if type(name)=='table'then return name end;if name==nil or name==false or name==''then return nil end;return known(self.room:findPlayerByObjectName(name,true),'biaofeng player '..tostring(name))end
local function remember_player(self,key,p)self:setStrategyMemory('biaofeng.'..key,p and p:objectName()or false)end
local function recall_player(self,key)return find(self,self:getStrategyMemory('biaofeng.'..key))end
local function get_jiujia(self)return find(self,self:getStrategyMemory('response_source:SevenJiujia'))end
local function set_jiujia(self,p)return self:setStrategyMemory('response_source:SevenJiujia',p and p:objectName()or false)end
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
 if key=='CurrentJudgeStruct' then value=self:getDecisionContext().biaofeng_judge;if value~=nil then return{toJudge=function()return self:getScopedJudge(value)end}end end
 if key=='ai_PlusLuoyi_card_id'or key=='ai_PlusLuoyi_card_name'then value=self:getStrategyMemory('biaofeng.'..key);if value==nil then value=key=='ai_PlusLuoyi_card_id'and 0 or''end
 elseif key=='CurrentDamageStruct'then value=self:getDecisionContext().damage -- the room tag reaches only asks that carry it
 else value=self:getDecisionContext()[known(tag_keys[key],key)]end
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
 local epoch=known(known(AIWorldLifecycle.epochs(self.world,'turn'),'turn mark clear epochs')[self.player:objectName()],'owner mark clear epoch')
 local row=self:getStrategyMemory('biaofeng.luoyi_mark');local base=self.player:getMark('AI_do_not_invoke_PlusLuoyi-Clear')
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
ai_skill_use["@PlusJianxiong"] = function(self, prompt, request)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	local dest = damage.to
	if not dest or not self:isEnemy(dest) then return "." end
	local target
	if dest:getHp() <= 1 then
		if role(self,dest) == "rebel" and self:getOverflow() then
			for _, friend in ipairs(self.friends_noself) do
				if friend then
					if not self:hasJueqingEffect(friend, dest, damage.nature) then
						target = friend
					end
				end
			end
		elseif role(self,dest) == "loyalist" then
			local lord = self.room:getLord()
			if self:isEnemy(lord) then
				target = friend
			end
		end
	end

	if not target then
		if self:hasSkills(sgs.masochism_skill, dest) then
			self:sortInPlace(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if enemy then
					target = enemy
				end
			end
		end
	end

	local discard_cards = {}

	for _, id in sgs.qlist(self.player:getCards("h")) do
		if id:isBlack() then
			table.insert(discard_cards, id)
		end
	end
	if target and #discard_cards > 0 then
		return "#PlusJianxiong_Card:" ..
			discard_cards[1]:getEffectiveId() .. ":->" .. target:objectName()
	end
	return "."
end

ai_skill_choice.PlusWulve = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local damage = data:toDamage()
	local choice1 = getChoice(choices, "PlusWulve_choice1")
	local choice2 = getChoice(choices, "PlusWulve_choice2")
	if not damage.card then return ai_choice_result((choice2), options) end
	if damage.card:isKindOf("Slash") and not self:hasCrossbowEffect() and self.player:getLostHp() > 1 and self:getCardsNum("Slash") > 0 then
		return ai_choice_result((choice2), options)
	end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then
		return ai_choice_result((choice2), options)
	end
	local items = choices:split("+")
	if choice1 then return ai_choice_result((choice1), options) end
	return ai_choice_result((items[1]), options)
end
ai_audited_aliases.register{id="ai_target_revises.PlusWulve",registry="ai_target_revises",path={"PlusWulve"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=3,defer_canonical=true}
sgs.ai_can_damagehp.PlusWulve = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return card:isKindOf("Duel") or card:isKindOf("AOE") or to:getLostHp() > 2
	end
end

ai_audited_aliases.register{id="ai_skill_invoke.PlusLangmou",registry="ai_skill_invoke",path={"PlusLangmou"},canonical_registry="ai_skill_invoke",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.PlusLangmou",registry="ai_choicemade_filter",path={"cardChosen","PlusLangmou"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_cardchosen.PlusLangmou",registry="ai_skill_cardchosen",path={"PlusLangmou"},canonical_registry="ai_skill_cardchosen",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_need_damaged.PlusLangmou",registry="ai_need_damaged",path={"PlusLangmou"},canonical_registry="ai_need_damaged",canonical_path={"fankui"},self_index=1,defer_canonical=true}
sgs.wizard_skill = sgs.wizard_skill .. "|PlusGuicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|PlusGuicai"

sgs.ai_skill_cardask["@PlusGuicai-card"] = function(self, data)
	local judge = data:toJudge()

	if self:needRetrial(judge) then
		local cards = AIList.new(self.player:getCards("h"))
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, disclosed(self,id))
			end
		end
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			
			return "#PlusGuicai_DummyCard:" .. card_id .. ":"
		end
	end

	return "."
end

function sgs.ai_cardneed.PlusGuicai(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.PlusGuicai_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

ai_skill_use["@PlusGuicai2"] = function(self, prompt, request)
	local targets = AIList.new(self.room:getAllPlayers())
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
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = AIList.new(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValueInPlace(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getKnownEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getKnownEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuicai_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuicai_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = AIList.new(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValueInPlace(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getKnownEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getKnownEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuicai_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuicai_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end

sgs.ai_target_revises.PlusTaohui = function(to, card, self, use)
	if card:isNDTrick() and to:getHandcardNum() <= to:getMaxHp()
		and self:getCardsNum("BasicCard") - self:getCardsNum("Peach") < 2
	then
		return true
	end
end

sgs.ai_skill_cardask["@PlusTaohui"] = function(self, data)
	local use = data:toCardUse()
	local current = self.room:getCurrent()
	for _, p in sgs.qlist(use.to) do
		if p:getMark("PlusTaohui-Clear") > 0 then
			if self:isFriend(p) then
				if use.card:isKindOf("AmazingGrace") and
					(p:getSeat() - current:getSeat()) % (self.room:alivePlayerCount()) < self.room:alivePlayerCount() / 2 then
					local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if use.card:isKindOf("GodSalvation") and p:isWounded() or use.card:isKindOf("ExNihilo") then
					local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")

					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if use.card:isKindOf("IronChain") then
					if p:isChained() and not self:isGoodChainTarget(p) then
						local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
						if #to_discard > 0 then return "$" .. to_discard[1] end
					end
				end
			end
			if self:isEnemy(p) or (self:isFriend(p) and role(self,p) == "loyalist" and not self:hasJueqingEffect(self.player, p, sgs.card_damage_nature[use.card:getClassName()]) and self.player:isLord() and p:getHp() == 1) then
				if use.card:isKindOf("AOE") then
					local from = use.from
					if use.card:isKindOf("SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, q in sgs.qlist(self.room:getOtherPlayers(self.player)) do
						if self:isFriend(q) then friend_null = friend_null + getCardsNum("Nullification", q, self.player) end
						if self:isEnemy(q) then friend_null = friend_null - getCardsNum("Nullification", q, self.player) end
					end
					friend_null = friend_null + self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

					if self:hasTrickEffective(use.card, p, from) then
						if self:damageIsEffective(p, sgs.DamageStruct_Normal, from) then
							if sj_num == 0 and friend_null <= 0 then
								if self:isEnemy(from) and self:hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
								if self:isFriend(from) and role(self,p) == "loyalist" and from:isLord() and p:getHp() == 1 and not self:hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
									return "."
								end
								if (not (self:hasSkills(sgs.masochism_skill, p) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or self:hasJueqingEffect(use.from, p, sgs.card_damage_nature[use.card:getClassName()])) then
									return "."
								end
							end
						end
					end
				elseif self:isEnemy(p) then
					if use.card:isKindOf("FireAttack") then
						if self:hasTrickEffective(use.card, p) then
							if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
								if (p:hasArmorEffect("vine") or p:getMark("@gale") > 0) and self.player:getHandcardNum() > 3
									and not (self.player:hasSkill("hongyan") and getKnownCard(p, p, "spade") > 0) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								elseif p:isChained() and not self:isGoodChainTarget(p, use.from) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
							end
						end
					elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("ZdShengdongjixi")) and not p:isKongcheng() then
						if self:hasTrickEffective(use.card, p) then
							local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
		
							if #to_discard > 0 then return "$" .. to_discard[1] end
						end
					elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
						if self:hasTrickEffective(use.card, p) then
							if self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
								local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
								if #to_discard > 0 then return "$" .. to_discard[1] end
							end
						end
					elseif use.card:isKindOf("IronChain") then
						if self:isGoodChainTarget(p) then
							local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
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
	if self:canLiegong(to, from) then return false end
	if self:isEnemy(to) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) and #self.enemies > 1 then return true end
end

ai_skill_use["@PlusYiji"] = function(self, prompt, request)

	local tag = tag(self,"PlusYiji")
	local guanxu_cardsToGet
	if tag then
		guanxu_cardsToGet = tag:toString():split("+")
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
	self:sortByKeepValueInPlace(cards)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("EquipCard") then
			table.insert(equip_card, acard:getKnownEffectiveId())
		elseif acard:isKindOf("DelayedTrick") then
			table.insert(judge_card, acard:getKnownEffectiveId())
		else
			table.insert(give_card, acard:getKnownEffectiveId())
		end
	end
	if #judge_card > 0 then
		self:sortInPlace(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if (not self.player:isProhibited(enemy, disclosed(self,judge_card[1])) and enemy:hasJudgeArea() and not enemy:containsTrick(disclosed(self,judge_card[1]):objectName())) then
				return "#PlusYiji_Card:" .. judge_card[1] .. ":->" .. enemy:objectName()
			end
		end
	end
	if #equip_card > 0 then
		self:sortInPlace(self.friends, "defense")
		local equip_index = disclosed(self,equip_card[1]):getEquipSlot()
		for _, friend in ipairs(self.friends) do
			if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
				return "#PlusYiji_Card:" .. equip_card[1] .. ":->" .. friend:objectName()
			end
		end
	end

	if #give_card > 0 then
		local target1
		local extra = self:getCardsNum("Jink") - self.player:getHp() - self:getCardsNum("Peach") > 0
		for _, acard in ipairs(give_card) do
			local card = disclosed(self,acard)
			if card:isKindOf("Peach") or card:isKindOf("Analeptic") then continue end
			if not extra and card:isKindOf("Jink") then continue end
			local ids = {}
			table.insert(ids, card:getKnownEffectiveId())
			local target, cardid = sgs.ai_skill_askforyiji.nosyiji(self, ids)
			if not target then continue end
			if not target1 or target1:objectName() == target:objectName() then
				target1 = target
			end
		end
		if not target1 then return "." end
		return "#PlusYiji_Card:" .. give_card[1] .. ":->" .. target1:objectName()
	end
	return "."
end

ai_audited_aliases.register{id="ai_skill_invoke.PlusYiji",registry="ai_skill_invoke",path={"PlusYiji"},canonical_registry="ai_skill_invoke",canonical_path={"yiji"},self_index=1,defer_canonical=true}
ai_skill_choice.PlusYiji = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "PlusYiji_delayedTrick") and target and self:isEnemy(target) then
		return
		ai_choice_result(("PlusYiji_delayedTrick"), options)
	end
	if table.contains(items, "PlusYiji_equip") and target and self:isFriend(target) then return ai_choice_result(("PlusYiji_equip"), options) end
	return ai_choice_result((items[1]), options)
end

sgs.ai_need_damaged.PlusYiji = function(self, attacker, player)
	if not player:hasSkill("PlusYiji") then return end

	local friends = {}
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(ap, player) then
			table.insert(friends, ap)
		end
	end
	self:sortInPlace(friends, "hp")

	if #friends > 0 and friends[1]:objectName() == player:objectName() and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end

	return player:getHp() > 2 and self.room:getTurnCount() > 2 and #friends > 1 and not self:isWeak(player) and
		player:getHandcardNum() >= 2
end

ai_skill_choice.PlusGanglie = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local use = data:toCardUse()
	local items = choices:split("+")
	if table.contains(items, "PlusGanglie_choice1") then
		if not use.from or use.from:isDead() then return ai_choice_result(("PlusGanglie_cancel"), options) end
		if self.role == "rebel" and self:getRoleEstimate(use.from) == "rebel" and not self:hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()])
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return ai_choice_result(("PlusGanglie_cancel"), options)
		end

		if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not self:hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1) then
			if use.card:isKindOf("Slash") then
				if not self:slashIsEffective(use.card, self.player, use.from) then return ai_choice_result(("PlusGanglie_cancel"), options) end
				if self:hasHeavyDamage(use.from, use.card, self.player) then return ai_choice_result(("PlusGanglie_choice1"), options) end

				local jink_num = self:getExpectedJinkNum(use)
				local hasHeart = false
				for _, card in ipairs(self:getCards("Jink")) do
					if card:getSuit() == sgs.Card_Heart then
						hasHeart = true
						break
					end
				end
				if self:getCardsNum("Jink") == 0
					or jink_num == 0
					or self:getCardsNum("Jink") < jink_num
					or (use.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then
					if use.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, use.from, nil, nil, use.card) then
						return
						ai_choice_result(("PlusGanglie_choice1"), options)
					end
					if use.from:hasSkill("nosqianxi") and use.from:distanceTo(self.player) == 1 then
						return
						ai_choice_result(("PlusGanglie_choice1"), options)
					end
					if self:isFriend(use.from) and self.role == "loyalist" and not self:hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1 then
						return
						ai_choice_result(("PlusGanglie_choice1"), options)
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or self:hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()])) then
						return ai_choice_result(("PlusGanglie_choice1"), options)
					end
				end
			elseif use.card:isKindOf("AOE") then
				local from = use.from
				if use.card:isKindOf("SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + self:getCardsNum("Nullification")
				local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

				if not self:hasTrickEffective(use.card, self.player, from) then return ai_choice_result(("PlusGanglie_cancel"), options) end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
					return
					ai_choice_result(("PlusGanglie_cancel"), options)
				end
				if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
					return
					ai_choice_result(("PlusGanglie_choice1"), options)
				end
				if sj_num == 0 and friend_null <= 0 then
					if self:isEnemy(from) and self:hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
						return
						ai_choice_result(("PlusGanglie_choice1"), options)
					end
					if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not self:hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
						return
						ai_choice_result(("PlusGanglie_choice1"), options)
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or self:hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()])) then
						return ai_choice_result(("PlusGanglie_choice1"), options)
					end
				end
			elseif self:isEnemy(use.from) then
				if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
					if not self:hasTrickEffective(use.card, self.player) then return ai_choice_result(("PlusGanglie_cancel"), options) end
					if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then
						return
						ai_choice_result(("PlusGanglie_cancel"), options)
					end
					if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and use.from:getHandcardNum() > 3
						and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
						return ai_choice_result(("PlusGanglie_choice1"), options)
					elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
						return ai_choice_result(("PlusGanglie_choice1"), options)
					end
				elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan"))
					and not self.player:isKongcheng() and not self:isWeak() then
					if not self:hasTrickEffective(use.card, self.player) then return ai_choice_result(("PlusGanglie_cancel"), options) end
					return ai_choice_result(("PlusGanglie_choice1"), options)
				elseif use.card:isKindOf("chuqibuyi") then
					if self:hasTrickEffective(use.card, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
						return
						ai_choice_result(("PlusGanglie_choice1"), options)
					end
				elseif use.card:isKindOf("Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
						if self:hasTrickEffective(use.card, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
							return
							ai_choice_result(("PlusGanglie_choice1"), options)
						end
					end
				elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("AmazingGrace") then
					if self:needToLoseHp(self.player, use.from, use.card) then
						return ai_choice_result(("PlusGanglie_choice1"), options)
					end
				end
			end
		end
	end
	if table.contains(items, "PlusGanglie_choice2") then
		if use.from and self:isEnemy(use.from) then
			if use.card:isKindOf("FireAttack") or use.card:isKindOf("Snatch") or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("Collateral") then
				return
				ai_choice_result(("PlusGanglie_cancel"), options)
			end
			if use.card:isKindOf("Slash") then
				if not self:slashIsEffective(use.card, use.from, use.from) then return ai_choice_result(("PlusGanglie_cancel"), options) end
				if self:hasHeavyDamage(use.from, use.card, use.from) then return ai_choice_result(("PlusGanglie_choice2"), options) end

				if getCardsNum("Jink", use.from) == 0
					or jink_num == 0
					or getCardsNum("Jink", use.from) < 1 then
					if use.card:isKindOf("NatureSlash") and use.from:isChained() and not self:isGoodChainTarget(use.from, use.from, nil, nil, use.card) then
						return
						ai_choice_result(("PlusGanglie_choice2"), options)
					end
					return ai_choice_result(("PlusGanglie_choice2"), options)
				end
			elseif use.card:isKindOf("AOE") then
				if self:isWeak(use.from)  and self:hasTrickEffective(use.card, use.from, use.from) then
					return ai_choice_result(("PlusGanglie_choice2"), options)
				end
			elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
				if self:isWeak(use.from)  and self:hasTrickEffective(use.card, use.from, use.from) then
					return ai_choice_result(("PlusGanglie_choice2"), options)
				end
			end
		end
	end
	return ai_choice_result(("PlusGanglie_cancel"), options)
end

ai_skill_invoke.PlusLuoyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:isSkipped(sgs.Player_Play) then return (false) or false end
	if self:needBear() then return (false) or false end
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	local slashtarget = 0
	local dueltarget = 0
	self:sortInPlace(self.enemies, "hp")
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") or card:isKindOf("EquipCard") then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and self:isGoodTarget(enemy, self.enemies) then
					if getCardsNum("Jink", enemy) < 1 or (self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if card:isKindOf("Duel") or card:isKindOf("EquipCard") then
			for _, enemy in ipairs(self.enemies) do
				if self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) and self:isGoodTarget(enemy, self.enemies)
					and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy, self.player, 2) and self:canDamage(enemy, self.player, nil)
					and self:damageIsEffective(enemy) and enemy:getMark("@late") < 1 then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget + dueltarget) > 0 then
		return (true) or false
	end
	return (false) or false
end

local PlusLuoyi_skill = {}
PlusLuoyi_skill.name = "PlusLuoyi"
table.insert(package_skills, PlusLuoyi_skill)
PlusLuoyi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:hasFlag("PlusLuoyi") or not self.player:hasEquip() then return end
	local patterns = { "slash", "duel" }
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = self:cloneEvaluationCard(name)
		
		if poi:isAvailable(self.player) then
			table.insert(choices, name)
		end
	end

	if next(choices) and luoyi_mark(self,false) == 0 then
		return parse(self,request,"#PlusLuoyi_select:.:")
	end
end

ai_card_use["#PlusLuoyi_select"] = function(self, card, use, request)
	local useable_cards = AIList.new(self.player:getCards("e"))
	self:sortByUseValueInPlace(useable_cards, true)

	if #useable_cards == 0 then return end
	if useable_cards[1]:hasFlag("xiahui") then return end
	set_tag(self,"ai_PlusLuoyi_card_id",useable_cards[1]:getEffectiveId())
	local card_str = string.format("#PlusLuoyi_select:%s:", useable_cards[1]:getEffectiveId())
	local acard = parse(self,request,card_str)
	use.card = acard
end

sgs.ai_use_priority["PlusLuoyi_select"] = 3
sgs.ai_use_value["PlusLuoyi_select"] = 3

ai_skill_choice["PlusLuoyi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local ai_taoluan_card_id = tag(self,"ai_PlusLuoyi_card_id"):toInt()
	remove_tag(self,"ai_PlusLuoyi_card_id")
	local taoluan_vs_card = {}
	local suit = disclosed(self,ai_taoluan_card_id):getSuit()
	local number = disclosed(self,ai_taoluan_card_id):getNumber()
	local items = choices:split("+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card=owner_clone(self,"PlusLuoyi",card_name,suit,number)
			
			table.insert(taoluan_vs_card, use_card)
		end
	end
	self:sortByUsePriorityInPlace(taoluan_vs_card)
	for _, c in ipairs(taoluan_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:isKindOf("Duel") then
				local dummyuse = { isDummy = true, to = AIList.new({}) }
				self:useTrickCard(c, dummyuse)
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						set_tag(self,"ai_PlusLuoyi_card_name",c:objectName())
						set_tag(self,"ai_PlusLuoyi_card_id",ai_taoluan_card_id)
						return ai_choice_result((c:objectName()), options)
					end
				end
			end
			if c:isKindOf("Slash") then
				local dummyuse = { isDummy = true, to = AIList.new({}) }
				self:useBasicCard(c, dummyuse)
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						set_tag(self,"ai_PlusLuoyi_card_name",c:objectName())
						set_tag(self,"ai_PlusLuoyi_card_id",ai_taoluan_card_id)
						return ai_choice_result((c:objectName()), options)
					end
				end
			end
		end
	end
	luoyi_mark(self,true)
	return ai_choice_result(("cancel"), options)
end

ai_skill_use["@PlusLuoyi"] = function(self, prompt, request)
	local method = request and request.handling_method
	local ai_taoluan_card_name = tag(self,"ai_PlusLuoyi_card_name"):toString()
	remove_tag(self,"ai_PlusLuoyi_card_name")
	local ai_taoluan_card_id = tag(self,"ai_PlusLuoyi_card_id"):toInt()
	remove_tag(self,"ai_PlusLuoyi_card_id")
	local taoluan_use_card = disclosed(self,ai_taoluan_card_id)
	local suit = taoluan_use_card:getSuitString()
	local number = taoluan_use_card:getNumberString()
	local use_card=owner_normal(self,"PlusLuoyi",ai_taoluan_card_name,{ai_taoluan_card_id})

	local dummyuse = { isDummy = true, to = AIList.new({}) }
	self:useTrickCard(use_card, dummyuse)
	local targets = {}
	if not dummyuse.to:isEmpty() then
		for _, p in sgs.qlist(dummyuse.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
		end
	end

	luoyi_mark(self,true)
	return "."
end

function sgs.ai_cardneed.PlusLuoyi(to, card, self)
	local slash_num = 0
	local target
	local slash = self:cloneEvaluationCard("slash")

	local cards = to:getHandcards()
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end
		end
	end

	self:sortInPlace(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if to:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and self:getDefenseSlash(enemy) <= 2 then
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
	if (card and (card:isKindOf("Slash") or card:isKindOf("Duel"))) and from:hasFlag("PlusLuoyi") and not from:hasEquip()
	then
		return 1
	end
end

sgs.use_lion_skill = sgs.use_lion_skill .. "|PlusLuoyi"
sgs.need_equip_skill = sgs.need_equip_skill .. "|PlusLuoyi"

ai_skill_invoke.PlusHuwei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHp() == 1 then return (false) or false end
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and self:isFriend(handang) and dying > 0 then return (false) or false end

	local heart_jink = false
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:getSuit() == sgs.Card_Heart and isCard("Jink", card, self.player) then
			heart_jink = true
			break
		end
	end

	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return (false) or false end

	if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if self.player:getHp() > enemy_num and enemy_num <= 1 then return (false) or false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return (false) or false end
	if self.player:hasFlag("dahe") then return (false) or false end
	local hujia_requester = self:getHujiaRequester(data)
	if hujia_requester and (not self:isFriend(hujia_requester) or hujia_requester:hasFlag("dahe")) then return (false) or false end
	if sgs.lianlisource and (not self:isFriend(sgs.lianlisource) or sgs.lianlisource:hasFlag("dahe")) then return (false) or false end
	if self:needToLoseHp(self.player, nil, nil, true, true) then return (false) or false end
	if self:getCardsNum("Jink") == 0 then
		return (true) or false
	else
		return (false) or false
	end

	return (true) or false
end

ai_get_cardType = function(card)
	if card:isKindOf("Weapon") then return 1 end
	if card:isKindOf("Armor") then return 2 end
	if card:isKindOf("DefensiveHorse") then return 3 end
	if card:isKindOf("OffensiveHorse") then return 4 end
	if card:isKindOf("Treasure") then return 5 end
end

ai_skill_use["@PlusShensu1"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	if self.player:containsTrick("lightning") and self.player:getCards("j"):length() == 1
		and self:hasWizard(self.friends) and not self:hasWizard(self.enemies, true) then
		return "."
	end

	if self:needBear() then return "." end
	local selfDef = self:getDefense(self.player)

	local cards = self.player:getCards("he")
	cards = AIList.new(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0 }

	if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(), method) then
		eCard = self.player:getArmor()
	end

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				hasCard[ai_get_cardType(card)] = hasCard[ai_get_cardType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and hasCard[ai_get_cardType(card)] > 1 then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and ai_get_cardType(card) > 3 and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not card:isKindOf("Armor") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
	end
	if not eCard then return "." end

	local effectslash, best_target, target, throw_weapon
	local defense = 6
	local weapon = self.player:getWeapon()
	if weapon and eCard:getKnownId() == weapon:getKnownId() and (eCard:isKindOf("fan") or eCard:isKindOf("QinggangSword")) then throw_weapon = true end

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local slash = self:cloneEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif throw_weapon and enemy:hasArmorEffect("vine") and not self.player:hasSkill("zonghuo") then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
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

	if best_target then return "#PlusShensu_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. best_target:objectName() end
	if target then return "#PlusShensu_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. target:objectName() end

	for _, friend in ipairs(self.friends_noself) do
		local def = self:getDefense(friend)
		local slash = self:cloneEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, friend)

		if not self.player:canSlash(friend, slash, false) then
		elseif self:slashProhibit(nil, friend) then
		elseif eff then
			if self:needToLoseHp(friend, self.player, slash) then
				target = friend
			end
		end
	end
	if target then return "#PlusShensu_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. target:objectName() end

	return "."
end

ai_skill_use["@PlusShensu2"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")

	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = self:getDefense(self.player)

	local cards = self.player:getCards("h")
	cards = AIList.new(cards)

	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isRed() and not card:isKindOf("Peach") and not card:isKindOf("Jink") and self:getCardsNum("Jink") == 1 then
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
		local slash = self:cloneEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
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

	if best_target then return "#PlusShensu_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. best_target:objectName() end
	if target then return "#PlusShensu_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. target:objectName() end

	return "."
end

sgs.ai_cardneed.PlusShensu = function(to, card, self)
	return (card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", false) < 2)
		or (card:isRed() and to:getHandcardNum() <= 2)
end

ai_audited_aliases.register{id="ai_card_intention.PlusShensu_Card",registry="ai_card_intention",path={"PlusShensu_Card"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
sgs.need_equip_skill = sgs.need_equip_skill .. "|PlusShensu"

function ai_skill_invoke.PlusJushou(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (self.room:getTurnCount() <= 1 and self:getRoleEstimate(sbdiaochan) == "neutral")) then
		return (false) or false
	end
	if not self.player:faceUp() then return (true) or false end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return (true) or false end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return (true) or false
		end
	end
	return (self:isWeak()) or false
end

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|PlusJushou"

sgs.ai_skill_askforag["PlusKuiwei"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	self:sortByUseValueInPlace(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

ai_skill_use["@PlusYizhong"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")

	local cards = self.player:getCards("h")
	cards = AIList.new(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0 }

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				hasCard[ai_get_cardType(card)] = hasCard[ai_get_cardType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and hasCard[ai_get_cardType(card)] > 1 then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and ai_get_cardType(card) > 3 and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not card:isKindOf("Armor") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
	end
	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("TrickCard") and not self.player:isCardLimited(card, method) then
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
			local eff = self:slashIsEffective(slash, friend)
			if use.card and self:hasHeavyDamage(use.from, use.card, friend) then
				best_target = friend
				break
			end
			if not self.player:canSlash(friend, slash, false) then
			elseif self:slashProhibit(nil, friend) then
			elseif eff then
				if friend:getHp() == 1 and getCardsNum("Jink", friend) == 0 then
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
				if not card:isKindOf("Peach") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if eCard then
			self:updateIntention(self.player, best_target, -70)
			return "#PlusYizhong_Card:" .. eCard:getKnownEffectiveId() .. ":"
		end
	end

	if target then
		if not eCard and self.player:getHandcardNum() >= 2 then
			for _, card in ipairs(cards) do
				if not card:isKindOf("Peach") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if eCard then
			self:updateIntention(self.player, target, -70)
			return "#PlusYizhong_Card:" .. eCard:getKnownEffectiveId() .. ":"
		end
	end
	if not eCard then return "." end
	return "."
end

ai_skill_invoke.PlusYizhong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

function sgs.ai_cardneed.PlusYizhong(to, card)
	return (not card:isKindOf("BasicCard") and to:getHandcardNum() < 2) or
		(isCard("OffensiveHorse", card, to) and not (to:getOffensiveHorse() or getKnownCard(to, "OffensiveHorse", false) > 0))
end

sgs.ai_card_intention["#PlusYizhong_Card"] = function(self, card, from, tos)
	local intention = -70
	local to
	for _, p in ipairs(AIList.new(self.room:getOtherPlayers(from))) do
		if yizhong_mark(self,p) > 0 then
			to = p
			break
		end
	end
	if to then
		self:updateIntention(from, to, intention)
	end
end

ai_skill_invoke.PlusJilei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		if not damage.from:isKongcheng() and self:doDisCard(damage.from, "h") then
			return (true) or false
		end
	end
	return (false) or false
end

sgs.ai_skill_suit["PlusJilei"] = function(self)
	local target
	for _, p in ipairs(AIList.new(self.room:getOtherPlayers(self.player))) do
		if p:getMark("PlusJilei") > 0 then
			target = p
			break
		end
	end
	if target then
		local cards = AIList.new(target:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
		for _, cc in ipairs(cards) do
			if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
				return cc:getSuit()
			end
		end
	end
	return math.random(0, 3)
end

ai_skill_use["@PlusJiangcai"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "handcard")
	self:sortInPlace(self.friends_noself, "handcard")

	local cards = self.player:getCards("h")
	cards = AIList.new(cards)

	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("BasicCard") and not card:isKindOf("Peach") and not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end

	local friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not friend:isKongcheng() and #friends < 3 then
			table.insert(friends, friend:objectName())
		end
	end
	if #friends == 3 then
		return "#PlusJiangcai_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. table.concat(friends, "+")
	elseif (#friends == 1 or #friends == 2) then
		self:sortInPlace(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and #friends < 3 then
				table.insert(friends, enemy:objectName())
			end
		end
		if #friends > 1 then
			return "#PlusJiangcai_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. table.concat(friends, "+")
		end
	end
	return "."
end

sgs.ai_skill_discard.PlusJiangcai = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	local target
	for _, p in ipairs(AIList.new(self.room:getOtherPlayers(self.player))) do
		if p:getMark("PlusJiangcai") > 0 then
			target = p
			break
		end
	end
	if cards[1] == nil then return {} end
	if target then
		if self:isFriend(target) then
			self:sortByKeepValueInPlace(cards, true)
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		elseif self:isEnemy(target) then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end

	return cards[1]:getEffectiveId()
end

ai_skill_use["@PlusYuanmou"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "handcard")
	self:sortInPlace(self.friends_noself, "handcard")

	local damagecard = tag(self,"PlusYuanmou_Damage"):toCard()
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") and not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) and
				self:getKeepValue(card) < self:getKeepValue(damagecard) then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end

	if self:isWeak() then return "." end
	local friends = {}
	for _, p in ipairs(self.friends) do
		if not self:willSkipPlayPhase(p) then
			table.insert(friends, p)
		end
	end
	if #friends == 0 then return "." end
	self:sortInPlace(friends, "defense")
	if #friends > 0 then
		return "#PlusYuanmou_Card:" .. eCard:getKnownEffectiveId() .. ":->" .. friends[1]:objectName()
	end
	return "."
end

sgs.ai_card_intention["#PlusYuanmou_Card"] = -60

sgs.ai_target_revises.PlusYuanmou = function(to, card, self)
	if card:isDamageCard()
		and not self:isFriend(to)
		and card:subcardsLength() > 0
	then
		for _, id in sgs.list(card:getSubcards()) do
			if isCard("Peach,Analeptic", disclosed(self,id), to)
			then
				return to:getHandcardNum() > 0
			end
		end
	end
end

ai_skill_invoke.PlusDanji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") then
		if self:hasHeavyDamage(damage.from, damage.card, self.player) then
			return (true) or false
		end
	end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return (false) or false end
	return (true) or false
end

sgs.ai_ajustdamage_to.PlusDanji = function(self, from, to, card, nature)
	if card and (card:isKindOf("Slash") or card:isNDTrick()) then
		if from and to and from:getHandcardNum() > to:getHandcardNum() then
			return -1
		end
	end
end

ai_skill_use["@PlusFuzheng"] = function(self, prompt, request)
	local method = request and request.handling_method
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		local eCard

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isRed() and not card:isKindOf("Peach") and (not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) or self:getOverflow(current) >= 2) then
					eCard = card
					break
				end
			end
		end

		if not eCard then return "." end

		return "#PlusFuzheng_Card:" .. eCard:getKnownEffectiveId() .. ":"
	end
	return "."
end

ai_skill_invoke.PlusFuzheng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_card_intention["#PlusFuzheng_Card"] = function(self, card, from, tos)
	local intention = -70
	local current = self.room:getCurrent()
	if current then
		self:updateIntention(from, current, intention)
	end
end
sgs.ai_target_revises.PlusPingluan = function(to, card)
	if card:isKindOf("SavageAssault")
		or card:isKindOf("ArcheryAttack")
	then
		return true
	end
end

local PlusZhiguo_skill = {}
PlusZhiguo_skill.name = "PlusZhiguo"
table.insert(package_skills, PlusZhiguo_skill)
PlusZhiguo_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#PlusZhiguo_Card") then return end
	return parse(self,request,"#PlusZhiguo_Card:.:")
end

ai_card_use["#PlusZhiguo_Card"] = function(self, card, use, request)
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)

	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") and (not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1)) then
			local targets = {}

			for _, friend in ipairs(self.friends) do
				if #targets < card:getNumber() and self:canDraw(friend, self.player) then
					table.insert(targets, friend)
				end
			end
			for _, friend in ipairs(self.friends) do
				if #targets < card:getNumber() then
					table.insert(targets, friend)
				else
					break
				end
			end
			local x = 0
			if #targets < card:getNumber() then
				for _, enemy in ipairs(self.enemies) do
					if #targets < card:getNumber() and x < 2 then
						table.insert(targets, enemy)
						x = x + 1
					end
				end
			end
			if #targets > 0 and #targets == card:getNumber() then
				use.card=final_parse(self,request,"#PlusZhiguo_Card:"..card:getKnownEffectiveId()..":")
				for _, p in ipairs(targets) do
					if use.to then
						use.to:append(p)
					end
				end
			end
			return
		end
	end
	
end

ai_skill_choice["PlusZhiguo"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("PlusZhiguo_Draw"), options)
end

local PlusRende_skill = {}
PlusRende_skill.name = "PlusRende"
table.insert(package_skills, PlusRende_skill)
PlusRende_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return end
	if self.player:getHandcardNum() <= 1 and self.player:getMaxCards() > 0 and self.player:getMark("PlusRende") == 0 then return end
	local mode = string.lower(self.room:getMode())
	if self.player:getMark("PlusRende") > 1 and mode:find("04_1v3") then return end

	if self.player:isWounded() then
		if self.player:getMark("PlusRende") > 1 and self:getOverflow() <= 0 then return end
	else
		if self:getOverflow() <= 0 then return end
	end

	if self:shouldUseRende() then
		return parse(self,request,"#PlusRende_Card:.:")
	end
end

ai_card_use["#PlusRende_Card"] = function(self, card, use, request)
	
	if self.player:getHp() < 3 and self.player:isWounded() and self.player:getHandcardNum() == 2 then
		self:sortInPlace(self.friends_noself, "handcard")
		local give_all_cards = {}
		for _, c in ipairs(AIList.new(self.player:getCards("h"))) do
			table.insert(give_all_cards, c:getKnownEffectiveId())
		end
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
		if #targets > 0 and #give_all_cards > 1 then
			local card_str = string.format("#PlusRende_Card:" .. table.concat(give_all_cards, "+") .. ":")
			local acard = parse(self,request,card_str)
			use.card = acard
			if use.to then
				use.to:append(targets[1])
			end
			return
		end
	end

	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	local notFound

	for i = 1, self.player:getHandcardNum() do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			cards = self:resetCards(cards, card)
		else
			notFound = true
			break
		end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
		local canJijiang = self.player:hasLordSkill("jijiang") and friend:getKnownKingdom() == "shu"
		if card:isAvailable(self.player) and ((card:isKindOf("Slash") and not canJijiang) or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = self:aiUseCard(card)
			if dummy_use.card and dummy_use.to:length() > 0 then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then
						continue
					elseif t1:getHp() == 1 or getCardsNum("Jink",t1,self.player)<1
						or t1:isCardLimited(self:cloneEvaluationCard("jink"), sgs.Card_MethodResponse) then
						continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then continue end
		end

		if friend:hasSkill("enyuan") and #cards >= 1 and not (self.room:getMode() == "04_1v3" and self.player:getMark("PlusRende") == 1) then
			use.card=final_parse(self,request,"#PlusRende_Card:" .. card:getKnownId() .. "+" .. cards[1]:getId() .. ":")
		else
			use.card=final_parse(self,request,"#PlusRende_Card:" .. card:getKnownId() .. ":")
		end
		if use.to then use.to:append(friend) end
		return
	end

	if notFound then
		local cards = AIList.new(self.player:getHandcards())
		self:sortByUseValueInPlace(cards, true)
		if self.player:isWounded() and self.player:getHandcardNum() > 3 and self.player:getMark("PlusRende") < 2 then
			self:sortByUseValueInPlace(cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
					table
						.insert(to_give, card:getKnownId())
				end
				if #to_give == 2 - self.player:getMark("PlusRende") then break end
			end
			if #to_give > 0 then
				for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
					if self:isFriend(p)  then
						use.card=final_parse(self,request,"#PlusRende_Card:" .. table.concat(to_give, "+") .. ":")
						if use.to then use.to:append(p) end
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

ai_skill_choice.PlusRende = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if table.contains(items, "PlusRende_choice1") then
		if self.player:getHp() < self:getBestHp(self.player) then
			return ai_choice_result(("PlusRende_choice1"), options)
		end
	end

	if table.contains(items, "PlusRende_choice3") then
		local god_salvation = self:cloneEvaluationCard("god_salvation")
		
		local good = 0
		for _, who in ipairs(AIList.new(self.room:getAllPlayers())) do
			if self:hasTrickEffective(god_salvation, who, self.player) then
				if self:isFriend(who) then
					if not who:isWounded() or who:getHp() >= self:getBestHp(who) then
					elseif self:isWeak(who) then
						good = good + 1.2
					elseif who:hasSkills(sgs.masochism_skill) then
						good = good + 1
					else
						good = good + 0.9
					end
				elseif self:isEnemy(who) then
					if not who:isWounded() or who:getHp() >= self:getBestHp(who) then
					elseif self:isWeak(who) then
						good = good - 1.2
					elseif who:hasSkills(sgs.masochism_skill) then
						good = good - 1
					else
						good = good - 0.9
					end
				end
			end
		end

		if self:willUseGodSalvation(god_salvation) and good > 0 then
			local handcards = AIList.new(self.player:getCards("h"))
			self:sortByUseValueInPlace(handcards, true)
			local useable_cards = {}
			if self.player:getPile("wooden_ox"):length() > 0 then
				for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
					if disclosed(self,id):isKindOf("Slash") then
						table.insert(handcards, disclosed(self,id))
					end
				end
			end
			for _, c in ipairs(handcards) do
				if not c:isKindOf("Peach")
					and not c:isKindOf("Analeptic")
					and not (c:isKindOf("Analeptic") and self:getCardsNum("Analeptic") == 1 and self.player:getHp() <= 1)
					and not (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1)
					and not c:isKindOf("Nullification")
					and not c:isKindOf("SavageAssault")
					and not c:isKindOf("ArcheryAttack")
					and not c:isKindOf("Duel")
					and not c:isKindOf("Armor")
					and not c:isKindOf("DefensiveHorse")
					and c:getSuit() == sgs.Card_Heart
				then
					table.insert(useable_cards, c)
				end
			end
			if #useable_cards == 0 then return ai_choice_result(("PlusRende_cancel"), options) end
			return ai_choice_result(("PlusRende_choice3"), options)
		end
	end
	if table.contains(items, "PlusRende_choice2") then
		local can_invoke = true
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if p:hasFlag("PlusRende_target") then
				if p:isNude() or self:isWeak(p) then
					can_invoke = false
					break
				end
			end
		end
		if can_invoke then
			return ai_choice_result(("PlusRende_choice2"), options)
		end
	end

	return ai_choice_result(("PlusRende_cancel"), options)
end

sgs.ai_skill_cardask["#PlusRende_Salvation"] = function(self, data, pattern, target)
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart then
			return "$" .. card:getKnownEffectiveId()
		end
	end
	return "."
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusRende"

ai_skill_invoke.PlusGuanxing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_invoke.PlusKongcheng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.PlusKongcheng = function(self, targets)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if role_count(self,"rebel") == 0 then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() and not hasManjuanEffect(lord) then
			return lord
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and not hasManjuanEffect(AssistTarget) then
		return AssistTarget
	end

	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and friend:hasSkills(sgs.cardneed_skill) then
			return friend
		end
	end

	self:sortInPlace(self.friends_noself, "chaofeng")
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.PlusKongcheng = -80

function sgs.ai_slash_prohibit.PlusKongcheng(self, from, to)
	if self:isEnemy(to) then return true end
end

sgs.ai_view_as.PlusWusheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:PlusWusheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_ajustdamage_from.PlusWusheng = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:getSuit() == sgs.Card_Diamond
	then
		return 1
	end
end

local PlusWusheng_skill = {}
PlusWusheng_skill.name = "PlusWusheng"
table.insert(package_skills, PlusWusheng_skill)
PlusWusheng_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	local red_card = {}
	self:sortByUseValueInPlace(cards, true)

	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end
	for _,card in ipairs(cards)do
		if not card:isKindOf("Slash")
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or self:getEvaluationCard("slash"):getTargetModResidue()>0)
		then table.insert(red_card,card) end
	end
	for _,card in ipairs(red_card)do
		local slash=turn_normal(self,"PlusWusheng","slash",{card:getKnownEffectiveId()},request)
		if slash:isAvailable(self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.PlusWusheng(to, card)
	return to:getHandcardNum() < 3
end
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|PlusWusheng"
sgs.double_slash_skill = sgs.double_slash_skill .. "|PlusWusheng"

local PlusPaoxiao_skill = {}
PlusPaoxiao_skill.name = "PlusPaoxiao"
table.insert(package_skills, PlusPaoxiao_skill)
PlusPaoxiao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getLostHp() == 0 or self.player:getStrategyHasUsed("#PlusPaoxiao_Card") then return nil end

	return parse(self,request,"#PlusPaoxiao_Card:.:")
end

ai_card_use["#PlusPaoxiao_Card"] = function(self, card, use, request)
	use.card=final_parse(self,request,"#PlusPaoxiao_Card:.:")
end

sgs.ai_use_value["PlusPaoxiao_Card"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["PlusPaoxiao_Card"] = sgs.ai_use_priority.Slash + 0.2

ai_skill_choice.PlusPaoxiao_Card = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local extra = getChoice(choices, "PlusPaoxiao1")
	local num = getChoice(choices, "PlusPaoxiao2")

	local slashcount = self:getCardsNum("Slash")
	if slashcount > 1 then
		return ai_choice_result((num), options)
	end
	if #self.enemies == 1 then
		return ai_choice_result((num), options)
	end
	return ai_choice_result((extra), options)
end

sgs.ai_getBestHp_skill.PlusPaoxiao = function(owner)
	return owner:getMaxHp() - 1
end

sgs.ai_cardneed.PlusJie = function(to, card)
	return card:isRed() and isCard("Slash", card, to)
end

sgs.ai_ajustdamage_from.PlusJie = function(self, from, to, card, nature)
	if from and card and card:isKindOf("Slash") and card:isRed()
	then
		return 1
	end
end

ai_skill_invoke.PlusChangsheng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.PlusLongdan_suit_value = {
	heart = 4.0,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.PlusLongdan(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Spade
end

local PlusLongdan_skill = {}
PlusLongdan_skill.name = "PlusLongdan"
table.insert(package_skills, PlusLongdan_skill)
PlusLongdan_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local usable_cards = self:addHandPile()
	local equips = AIList.new(self.player:getCards("e"))
	for _, e in ipairs(equips) do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(usable_cards, disclosed(self,id))
	end
	self:sortByUseValueInPlace(usable_cards, true)
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not c:isKindOf("Slash") then
			table.insert(two_diamond_cards, c:getKnownEffectiveId())
		end
	end
	if #two_diamond_cards == 2 and self:slashIsAvailable() and (self.player:getHp() > 2) and self:getOverflow() > 0 then
		return parse(self,request,("slash:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_diamond_cards[1],
			two_diamond_cards[2]))
	end
	if self:slashIsAvailable() and self.player:getHp() <= 2 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				return parse(self,request,("slash:PlusLongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
					c:getKnownEffectiveId()))
			end
		end
	end
	local two_heart_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(two_heart_cards, c:getKnownEffectiveId())
		end
	end
	if #two_heart_cards == 2 and (self.player:getHp() > 2) and self:getOverflow() > 0 then
		return parse(self,request,("analeptic:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_heart_cards[1],
			two_heart_cards[2]))
	end
	if self:slashIsAvailable() and self.player:getHp() <= 2 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") then
				return parse(self,request,("analeptic:PlusLongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
					c:getKnownEffectiveId()))
			end
		end
	end
end

sgs.ai_view_as.PlusLongdan = function(card, player, card_place, class_name)
	if card_place == sgs.Player_PlaceSpecial then return end
	local usable_cards = AIList.new(player:getCards("he"))
	for _, id in sgs.qlist(player:getHandPile()) do
		table.insert(usable_cards, disclosed(self,id))
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_spade_cards = {}
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, c:getKnownEffectiveId())
		elseif c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, c:getKnownEffectiveId())
		elseif c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, c:getKnownEffectiveId())
		elseif c:getSuit() == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, c:getKnownEffectiveId())
		end
	end

	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()

	if #two_club_cards == 2 and (player:getHp() > 2) then
		return ("jink:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_club_cards[1], two_club_cards[2])
	elseif card:getSuit() == sgs.Card_Club and player:getHp() <= 2 then
		return ("jink:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if #two_heart_cards == 2 and (player:getHp() > 2) then
		return ("analeptic:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_heart_cards[1], two_heart_cards[2])
	elseif card:getSuit() == sgs.Card_Heart and player:getHp() <= 2 then
		return ("analeptic:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if card:getSuit() == sgs.Card_Spade and player:getHp() <= 2 then
		return ("nullification:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if #two_diamond_cards == 2 and (player:getHp() > 2) then
		return ("slash:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_diamond_cards[1], two_diamond_cards[2])
	elseif card:getSuit() == sgs.Card_Diamond and player:getHp() <= 2 then
		return ("slash:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_getBestHp_skill.PlusLongdan = function(owner)
	return 2
end

sgs.ai_cardneed.PlusTieji = function(to, card, self)
	return (isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0) or
		(not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 and card:getNumber() > 10)
end

function sgs.ai_skill_pindian.PlusTieji(minusecard, self, requestor)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if requestor:objectName() == self.player:objectName() then
		return cards[1]:getId()
	end
	return self:getMaxCard(self.player):getId()
end

ai_skill_invoke.PlusTieji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not self:isEnemy(target) then return (false) or false end
	if not self.player:canPindian(target, true) then return (false) or false end

	if self.player:getHandcardNum() == 1 then
		if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return (true) or false end
		local card = self.player:getHandcards():first()
		if card:isKindOf("Jink") or card:isKindOf("Peach") then return false end
	end

	if (self.player:getHandcardNum() >= self.player:getHp() or self:getMaxCard():getNumber() > 10
			or (self:needKongcheng() and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective())
		and self:doDisCard(target, "he") then
		return (true) or false
	end
	if self:doDisCard(target, "e") then return (true) or false end
	return (false) or false
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.PlusTieji",registry="ai_choicemade_filter",path={"cardChosen","PlusTieji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
function sgs.ai_skill_pindian.PlusTieji(minusecard, self, requestor)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if requestor:objectName() == self.player:objectName() then
		return minusecard
	end
	return self:getMaxCard()
end

ai_skill_invoke.PlusJizhi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (self:doDisCard(target, "h")) or false
	end
	return (true) or false
end

function sgs.ai_cardneed.PlusJizhi(to, card)
	return card:getTypeId() == sgs.Card_TypeTrick
end

function sgs.ai_cardneed.PlusYongyi(to, card)
	return (isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0) or
		(card:isKindOf("Weapon") and not (to:getWeapon() or getKnownCard(to, "Weapon", false) > 0))
end

ai_skill_invoke.PlusYongyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	return (not self:isFriend(target)) or false
end

ai_skill_invoke.PlusLiegong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if use.from then
		return (self:doDisCard(use.from, "h")) or false
	end
	return (true) or false
end

sgs.ai_canliegong_skill.PlusLiegong = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and (to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange())
end

local PlusQimou_skill = {}
PlusQimou_skill.name = "PlusQimou"
table.insert(package_skills, PlusQimou_skill)
PlusQimou_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if (self.player:getMark("@stratagem") == 0) then return end
	if self:needBear() then return end
	if #self.enemies == 0 then return end
	if self:getRoleEstimate(self.player) == "neutral" then return end
	return parse(self,request,"#PlusQimou_Card:.:")
end
ai_card_use["#PlusQimou_Card"] = function(self, card, use, request)
	local target

	local slashcount = self:getCardsNum("Slash")

	self:sortInPlace(self.friends_noself, "handcard", true)
	for _, friend in ipairs(self.friends_noself) do
		if friend and not friend:isKongcheng() then
			if self:needKongcheng(friend) then
				target = friend
				break
			end
			if not self:isWeak(friend) then
				target = friend
				break
			end
		end
	end
	local can_slash = false
	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = self:cloneEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then
			can_slash = true
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local slash = self:cloneEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff and def < 8 then
			can_slash = true
		end
	end
	local can_invoke = false
	for _, c in sgs.qlist(self.player:getHandcards()) do
		local x = nil
		if isCard("ArcheryAttack", c, self.player) then
			x = self:cloneEvaluationCard("archery_attack")
		elseif isCard("SavageAssault", c, self.player) then
			x = self:cloneEvaluationCard("savage_assault")
		else
			continue
		end

		local du = { isDummy = true }
		self:useTrickCard(x, du)
		if (du.card) then can_invoke = true end
		
	end
	if target and ((slashcount > 0 and can_slash and self:slashIsAvailable()) or can_invoke) then
		local card_str = ("#PlusQimou_Card:.:")
		use.card=final_parse(self,request,card_str)
		if use.to then use.to:append(target) end
	end
end
sgs.ai_use_priority["PlusQimou_Card"] = sgs.ai_use_priority.Slash + 0.1

ai_skill_choice.PlusQimou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local give = getChoice(choices, "PlusQimou_Give")

	if target and self:isFriend(target) then
		return ai_choice_result((give), options)
	end
	return ai_choice_result(("PlusQimou_Refuse"), options)
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusZaiqi"
ai_skill_invoke.PlusZaiqi = ai_skill_invoke.zaiqi

ai_skill_invoke.PlusZaiqi_ss = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local card = self:cloneEvaluationCard("savage_assault")
	
	if self:getAoeValue(card) > 0 and ((self.player:getHandcardNum() <= 4)) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_cardask["@PlusZhongyong_Slash"] = function(self, data, pattern, target)
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:isRed() then
			return "$" .. card:getKnownEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.PlusZhongyong = function(self, targets)
	local friends = {}
	for _, player in ipairs(self.friends) do
		if player:isAlive() and self:canDraw(player, self.player) and self.player:distanceTo(player) <= 2 then
			table.insert(friends, player)
		end
	end
	self:sortInPlace(friends)

	local max_x = 0
	local target

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(friends) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end

	return target
end

sgs.ai_playerchosen_intention.PlusZhongyong = function(self, from, to)
	if to:getHandcardNum() < math.min(5, to:getMaxHp()) then
		self:updateIntention(from, to, -80)
	end
end

ai_skill_use["@PlusZhongyong"] = function(self, prompt, request)
	if self.player:isKongcheng() then return "." end
	self:sortInPlace(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slash = self:cloneEvaluationCard("slash")
	
	local dummy_use=self:withOwnerRange("slashNoDistanceLimit", "@PlusZhongyong", function()return self:aiUseCard(slash)end)
	if not dummy_use.to:isEmpty() then
		for _, enemy in sgs.qlist(dummy_use.to) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					self:remember("shuangren_card", max_card:getKnownEffectiveId())
					return "#PlusZhongyong_Card:" .. max_card:getKnownEffectiveId() .. ":->" .. enemy:objectName()
				end
			end
		end
		for _, enemy in sgs.qlist(dummy_use.to) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				if max_point >= 10 then
					self:remember("shuangren_card", max_card:getKnownEffectiveId())
					return "#PlusZhongyong_Card" .. max_card:getKnownEffectiveId() .. ":->" .. enemy:objectName()
				end
			end
		end
		if #self.enemies < 1 then return end
	end

	return "."
end

function sgs.ai_skill_pindian.PlusZhongyong(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return (maxcard:getNumber() < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.PlusZhongyong",registry="ai_cardneed",path={"PlusZhongyong"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
function ai_skill_invoke.PlusChouyuan(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	local target
	for _, p in sgs.qlist(use.to) do
		if p:getMark("PlusChouyuan_target") > 0 then
			target = p
		end
	end
	if target and self:isFriend(target) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.PlusChouyuan = function(self,player,promptlist)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:getMark("PlusChouyuan_target") > 0 then target = p break end
	end
	if target then
		if promptlist[#promptlist]=="yes" then
			self:updateIntention(player, target, -80)
		else
			self:updateIntention(player, target, 80)
		end
	end
end

ai_skill_invoke.PlusChenggui = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local card = tag(self,"PlusChenggui_card"):toCard()
	if ((card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse())
			or (card:isKindOf("OffensiveHorse") and (self.player:getOffensiveHorse() or (self.player:hasSkill("drmashu") and self.player:getDefensiveHorse()))))
		and not self.player:hasSkills(sgs.lose_equip_skill) then
		return (false) or false
	end
	if card:isKindOf("Armor")
		and ((self.player:hasSkills("bazhen|yizhong") and not self.player:getArmor())
			or (self.player:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getArmor()))) then
		return (false) or false
	end
	if card:isKindOf("Weanpon") and (self.player:getWeapon() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getWeapon())) then return (false) or false end
	return (true) or false
end

local PlusChenggui_skill = {}
PlusChenggui_skill.name = "PlusChenggui"
table.insert(package_skills, PlusChenggui_skill)
PlusChenggui_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return end
	if self:needBear() then return end
	if not self.player:getStrategyHasUsed("#PlusChenggui") then
		return parse(self,request,"#PlusChenggui:.:")
	end
end

ai_card_use["#PlusChenggui"] = function(self, card, use, request)
	self:updatePlayers()
	self:sortInPlace(self.friends, "handcard")
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	local use_card
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length() - 1)
		if self:hasTrickEffective(trick, nextAlive) then
			if trick:isKindOf("Lightning") then
				hasLightning = true
			elseif trick:isKindOf("Indulgence") then
				hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then
				hasSupplyShortage = true
			end
		end
	end

	if hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		for _, id in ipairs(cards) do
			local card = self:getPrintedCardById(id)
			if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
				use_card = card
			end
		end
	end
	if not use_card then
		if hasIndulgence then
			if self:isFriend(nextAlive) then
				for _, card in ipairs(cards) do
					
					if card:getSuit() == sgs.Card_Heart then
						use_card = card
					end
				end
			elseif self:isEnemy(nextAlive) then
				for _, card in ipairs(cards) do
					
					if card:getSuit() ~= sgs.Card_Heart then
						use_card = card
					end
				end
			end
		end
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
			table.insert(targets, friend)
		end
	end
	if not use_card then
		use_card = cards[1]
	end

	if #targets == 0 then return end
	if not use_card then return end
	use.card=final_parse(self,request,"#PlusChenggui:" .. use_card:getKnownId() .. ":")
	if use.to then
		use.to:append(targets[1])
	end
end

sgs.ai_use_priority["PlusChenggui"] = 7
sgs.ai_use_value["PlusChenggui"] = 7

local PlusZhiheng_skill = {}
PlusZhiheng_skill.name = "PlusZhiheng"
table.insert(package_skills, PlusZhiheng_skill)
PlusZhiheng_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local has_Crossbow = false
	for _, c in ipairs(AIList.new(self.player:getCards("h"))) do
		if c:isKindOf("Crossbow") then
			has_Crossbow = true
		end
	end
	if has_Crossbow or self:hasCrossbowEffect() then
		for _, slash in ipairs(self:getCards("Slash")) do
			local dummyuse = { isDummy = true, to = AIList.new({}) }
			self:useBasicCard(slash, dummyuse)
			if not dummyuse.to:isEmpty() then return end
		end
	end

	if not self.player:getStrategyHasUsed("#PlusZhiheng_Card") then
		return parse(self,request,"#PlusZhiheng_Card:.:")
	end
end

ai_card_use["#PlusZhiheng_Card"] = function(self, card, use, request)
	local unpreferedCards = {}
	local cards = AIList.new(self.player:getHandcards())
	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = owner_fact(self,"jilve_wansha")
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getKnownEffectiveId() == keep_weapon:getKnownEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getKnownId()) end
			end
		end
	end
	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= card:getTargetModResidue() then
					local dummy_use = self:aiUseCard(card)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getKnownId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getKnownId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getKnownId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = self:aiUseCard(card)
				if not dummy_use.card then table.insert(unpreferedCards, card:getKnownId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end
	for index = #unpreferedCards, 1, -1 do
		if disclosed(self,unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(disclosed(self,unpreferedCards[index])) then
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
	return not card:isKindOf("Jink")
end

ai_skill_choice.PlusZhiheng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local max = 0
	local min = 999
	for _, p in ipairs(AIList.new(self.room:getOtherPlayers(self.player))) do
		if p:getHandcardNum() > max then
			max = p:getHandcardNum()
		end
		if p:getHandcardNum() < min then
			min = p:getHandcardNum()
		end
	end
	local friend_can_invoke = false
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() == min and (not self:needKongcheng(friend, true) or hasManjuanEffect(friend)) then
			friend_can_invoke = true
		end
	end
	local enemy_can_invoke = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() == max and not hasTuntianEffect(enemy, true) then
			enemy_can_invoke = true
		end
	end
	if friend_can_invoke and enemy_can_invoke then
		return ai_choice_result(("PlusZhiheng_ok"), options)
	end
	return ai_choice_result(("PlusZhiheng_cancel"), options)
end

sgs.ai_skill_playerchosen["#PlusZhiheng_from"] = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not hasTuntianEffect(p, true) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["#PlusZhiheng_from"] = function(self, from, to)
	self:updateIntention(from, to, 30)
end

sgs.ai_skill_playerchosen["#PlusZhiheng_to"] = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and (not self:needKongcheng(p, true) or hasManjuanEffect(p)) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["#PlusZhiheng_to"] = function(self, from, to)
	self:updateIntention(from, to, -30)
end

sgs.ai_use_revises.PlusZhiheng = function(self, card, use)
	if card:isKindOf("Weapon")
		and not card:isKindOf("Crossbow")
		and self:getSameEquip(card)
		and not self.player:getStrategyHasUsed("#PlusZhiheng_Card")
	then
		return false
	end
end

local PlusFanjian_skill = {
	name = "PlusFanjian",
	getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

		if self.player:getStrategyHasUsed("#PlusFanjian_Card") then return end
		if self.player:isNude() then return end
		local can_use = false
		self:sortInPlace(self.enemies, "chaofeng")
		local slash = self:cloneEvaluationCard("slash")
		
		for _, enemy in ipairs(self.enemies) do
			if not self:slashIsEffective(slash, enemy) then continue end
			can_use = true
			break
		end
		if can_use then
			return parse(self,request,"#PlusFanjian_Card:.:")
		end
	end,
}
table.insert(package_skills, PlusFanjian_skill) 
ai_card_use["#PlusFanjian_Card"] = function(self, card, use, request)
	local handcards = AIList.new(self.player:getCards("he"))
	local slash = self:cloneEvaluationCard("slash")
	
	if #handcards == 0 then return end
	self:sortByUseValueInPlace(handcards, true)
	local togive = nil
	local slasher, target
	self:sortInPlace(self.enemies, "defense")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if enemy_b:canSlash(enemy_a) and not self:slashProhibit(slash, enemy_a) and self:getDefenseSlash(enemy_a) <= 2
				and self:slashIsEffective(slash, enemy_a) and self:isGoodTarget(enemy_a, self.enemies, slash) and enemy_b:getHandcardNum() > enemy_a:getHandcardNum() and enemy_a:objectName() ~= self.player:objectName() then
				slasher = enemy_b
				target = enemy_a
				break
			end
		end
	end
	if not slasher then
		for _, enemy in ipairs(self.enemies) do
			for _, p in ipairs(AIList.new(self.room:getOtherPlayers(enemy))) do
				if p:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and p:getHandcardNum() > enemy:getHandcardNum() and enemy:objectName() ~= self.player:objectName() then
					slasher = p
					target = enemy
					break
				end
			end
		end
	end

	if slasher and target then
		togive = handcards[1]
		local card_str = string.format("#PlusFanjian_Card:%s:", togive:getKnownEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then
			use.to:append(slasher)
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["PlusFanjian_Card"] = 0
sgs.ai_use_value["PlusFanjian_Card"] = 0
sgs.ai_card_intention["PlusFanjian_Card"] = 80

sgs.ai_use_revises.PlusKeji = function(self, card, use)
	if card:isKindOf("Slash") and not self.player:hasFlag("PlusKejiSlashInPlayPhase")
		and ((self.player:getMark("PlusDujiang") == 0 and self.player:hasSkill("PlusDujiang")) or self.player:getPile("slack"):length() == 0)
	then
		return false
	end
end

sgs.ai_getBestHp_skill.PlusDujiang = function(owner)
	if owner:getMark("PlusDujiang") == 0 and owner:getPile("slack"):length() >= 4 then
		return owner:getMaxHp() - 1
	end
end

local PlusDuocheng_skill = {}
PlusDuocheng_skill.name = "PlusDuocheng"
table.insert(package_skills, PlusDuocheng_skill)
PlusDuocheng_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return end
	if not self.player:getStrategyHasUsed("#PlusDuocheng_Card") then
		return parse(self,request,"#PlusDuocheng_Card:.:")
	end
end

ai_card_use["#PlusDuocheng_Card"] = function(self, card, use, request)
	local useable_cards = {}
	if self.player:getPile("slack"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("slack")) do
			table.insert(useable_cards, disclosed(self,id))
		end
	end
	if #useable_cards == 0 then return end
	local target
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getEquips():length() <= self.player:getHandcardNum() then
			target = enemy
		end
	end
	if target then
		if useable_cards[1]:hasFlag("xiahui") then return end
		local card_str = string.format("#PlusDuocheng_Card:%s:", useable_cards[1]:getEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["#PlusDuocheng_Card"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value["#PlusDuocheng_Card"] = 1

sgs.ai_skill_discard.PlusDuocheng = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, false)
end

ai_skill_invoke["#PlusKeji_Jink"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and self:isFriend(handang) and dying > 0 then return (false) or false end

	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return (false) or false end

	if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if self.player:getHp() > enemy_num and enemy_num <= 1 then return (false) or false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return (false) or false end
	if self:needToLoseHp(self.player, nil, nil, true, true) then return (false) or false end
	if self:getCardsNum("Jink") == 0 then return (true) or false end

	return (true) or false
end

ai_skill_use["@PlusCuorui"] = function(self, prompt, request)
	local target = tag(self,"PlusCuorui"):toPlayer()

	local cards = {}
	for _, c in ipairs(AIList.new(self.player:getCards("he"))) do
		table.insert(cards, c:getKnownEffectiveId())
	end
	if #cards > 0 and target and self:isFriend(target) then
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
PlusQixi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasFlag("PlusQixi_used") then return end
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local black_card

	self:sortByUseValueInPlace(cards, true)

	local has_weapon = false

	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon = true end
	end

	for _, card in ipairs(cards) do
		if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then
					shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then
					shouldUse = false
				end
			end

			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then
					shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then
					shouldUse = false
				end
			end

			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					local dummy_use = self:aiUseCard(card)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = self:aiUseCard(card)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getKnownEffectiveId()
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
	return card:isBlack()
end

ai_skill_invoke.PlusQixi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if self:isEnemy(target) then
		return (self:doDisCard(target, "hej")) or false
	end
	if self:isFriend(target) then
		return (self:needToThrowArmor(target) or self:doDisCard(target, "hej") or target:getJudgingArea():length() > 0) or false
	end
	return (not self:isFriend(target)) or false
end

sgs.ai_skill_cardask["@PlusQixi_prompt"] = function(self, data, pattern, target)
	local move = data:toMoveOneTime()
	local card_id = move.card_ids:first()
	local cd = disclosed(self,card_id)
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		if self:getKeepValue(card) < self:getKeepValue(cd) then
			return "$" .. card:getKnownEffectiveId()
		end
	end
	return "."
end

sgs.ai_use_revises.PlusQixi = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:isBlack()
	then
		same = self:getSameEquip(card)
		if same and same:isBlack()
		then
			return false
		end
	end
end

local PlusKurou_skill = {}
PlusKurou_skill.name = "PlusKurou"
table.insert(package_skills, PlusKurou_skill)
PlusKurou_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#PlusKurou_Card") then return end
	local func = nil -- fixed classical_func has no PlusKurou entry
	if func then return func(self, nil) end
	self:setPriorityValue("#PlusKurou_Card",6.8)
	local losthp = self.player:isLord() and 0 or 1
	if ((self.player:getHp() > 3 and self.player:getLostHp() <= losthp and self.player:getHandcardNum() > self.player:getHp())
			or (self.player:getHp() - self.player:getHandcardNum() >= 2)) and not (self.player:isLord() and self.room:getTurnCount() <= 1) then
		return parse(self,request,"#PlusKurou_Card:.:")
	end
	local slash = self:cloneEvaluationCard("slash")
	
	if (self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkill("paoxiao") then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, nil, true) and self:slashIsEffective(slash, enemy)
				and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
				and not (enemy:hasSkills("fankui|guixin") and not self.player:hasSkill("paoxiao"))
				and not enemy:hasSkills("fenyong|jilei|zhichi")
				and self:isGoodTarget(enemy, self.enemies, slash) and not self:slashProhibit(slash, enemy) and self.player:getHp() > 1 then
				return parse(self,request,"#PlusKurou_Card:.:")
			end
		end
	end
	if self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1 then
		return parse(self,request,"#PlusKurou_Card:.:")
	end

	local nextplayer = self.player:getNextAlive()
	if self.player:getHp() == 1 and role(self,self.player) ~= "lord" and role(self,self.player) ~= "renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng()
					and self.role == "rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("qingnang") then return end
			end
		end
		if role(self,self.player) == "rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if role(self,self.player) == "loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp() > nextplayer:getHp() and not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if role(self,self.player) == "rebel" and self.player:getHandcardNum() > 3 then to_death = false end
				if role(self,self.player) == "loyalist" and lord and lord:getCardCount(true) + 2 <= self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and self.player:aliveCount() == 2 then to_death = false end
		end
		if to_death then
			self:setStrategyPlayerFlag(self.player, "NosKurou_toDie", true)
			self:setPriorityValue("NosKurouCard",0)
			return parse(self,request,"#PlusKurou_Card:.:")
		end
		self:setStrategyPlayerFlag(self.player, "NosKurou_toDie", false)
	end
end

ai_card_use["#PlusKurou_Card"] = function(self, card, use, request)
	if not use.isDummy then self:speak("noskurou") end
	use.card = card
end

sgs.ai_use_priority["#PlusKurou_Card"] = 6.8

sgs.ai_skill_playerchosen["PlusKurou"] = function(self, targets)
	return self.player
end

ai_skill_choice.PlusKurou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("PlusKurou_Draw"), options)
end

local PlusZhaxiang_skill = { name = "PlusZhaxiang" }
table.insert(package_skills, PlusZhaxiang_skill)
function PlusZhaxiang_skill.getTurnUseCard(self, options, native_request)
	if self.player:getMark("@surrender") < 1 then return end
	if self.player:getHp() > 1 then return end
	if self:needBear() then return end
	if (#self.friends > 1) or (#self.enemies == 1 and self.room:getTurnCount() > 1) then
		if self:getAllPeachNum() == 0 and self.player:getHp() == 1 then
			for _, enemy in ipairs(self.enemies) do
				if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player) and enemy:isChained() then
					return parse(self,request,"#PlusZhaxiang_Card:.:")
				end
			end
			if self.role == "rebel" then
				local can_invoke = true
				for _, friend in ipairs(self.friends_noself) do
					if self:damageIsEffective(friend, sgs.DamageStruct_Fire, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player) and friend:isChained() then
						can_invoke = false
						break
					end
				end
				if can_invoke then
					return parse(self,request,"#PlusZhaxiang_Card:.:")
				end
			end
		end
		if self:isWeak() and self.role == "rebel" and self.room:getLord():isChained() then
			return parse(self,request,"#PlusZhaxiang_Card:.:")
		end
	end
end

ai_card_use["#PlusZhaxiang_Card"] = function(self, card, use, request)
	use.card = card
end

ai_skill_use["@PlusLiuli"] = function(self, prompt, request)
	local method = request and request.handling_method
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self:isGoodChainTarget(self.player, current) then return "." end
	local others = self.room:getOtherPlayers(self.player)
	local slash = tag(self,"liuli-card"):toCard()
	others = AIList.new(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("LiuliSlashSource") then
			source = player
			break
		end
	end
	self:sortInPlace(self.enemies, "defense")

	local doLiuli = function(who)
		if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
			and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
			return "."
		end
		local cards = self.player:getCards("h")
		cards = AIList.new(cards)
		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and who:isMale() and ((self.player:distanceTo(who) <= 2 and not card:isKindOf("OffensiveHorse")) or
					(self.player:distanceTo(who, 1) <= 2) and card:isKindOf("OffensiveHorse")) then
				if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "#PlusLiuli_Card:" .. card:getKnownEffectiveId() .. ":->" .. who:objectName()
				else
					return "#PlusLiuli_Card:" .. card:getKnownEffectiveId() .. ":->" .. who:objectName()
				end
			end
		end
		local cards = self.player:getCards("e")
		cards = AIList.new(cards)
		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and who:isMale() and ((self.player:distanceTo(who) <= 2 and not card:isKindOf("OffensiveHorse")) or
					(self.player:distanceTo(who, 1) <= 2) and card:isKindOf("OffensiveHorse")) then
				return "#PlusLiuli_Card:" .. card:getKnownEffectiveId() .. ":->" .. who:objectName()
			end
		end
		return "."
	end
	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doLiuli(player)
			if ret ~= "." then return ret end
		end
	end

	self:sortInPlace(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)

	for _, friend in ipairs(self.friends_noself) do
		if (not (self:slashIsEffective(slash, friend, source)) or self:findLeijiTarget(friend, 50, source)) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, slash) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end
	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
		and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention["#PlusLiuli_Card"] = function(self, card, from, to)
	self:setCommonEventMemory("ai_liuli_effect", true)
	if not self:hasExplicitRebel() then
		self:setCommonEventMemory("ai_liuli_user", from)
	else
		self:setCommonEventMemory("ai_liuli_user", nil)
	end
end

function sgs.ai_slash_prohibit.PlusLiuli(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:isNude() then return false end
	for _, friend in ipairs(self:getFriends(from, true)) do
		if to:distanceTo(friend) <= 2 and friend:isMale() and self:slashIsEffective(card, friend, from) then return true end
	end
end

function sgs.ai_cardneed.PlusLiuli(to, card)
	return to:getCards("he"):length() <= 2
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusJieyin"

local PlusJieyin_skill = {}
PlusJieyin_skill.name = "PlusJieyin"
table.insert(package_skills, PlusJieyin_skill)
PlusJieyin_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getHandcardNum() < 2 then return nil end
	if self.player:getStrategyHasUsed("#PlusJieyin_Card") then return nil end
	if self:needBear() and not self.player:isWounded() and not self:isWeak() then return nil end

	local cards = self.player:getHandcards()
	cards = AIList.new(cards)

	local first, second
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			local dummy_use = self:aiUseCard(card)
			if not dummy_use.card then
				if not first then
					first = card:getKnownEffectiveId()
				elseif first and not second then
					second = card:getKnownEffectiveId()
				end
			end
			if first and second then break end
		end
	end

	for _, card in ipairs(cards) do
		if card:getTypeId() ~= sgs.Card_TypeEquip and (not self:isValuableCard(card) or self.player:isWounded()) then
			if not first then
				first = card:getKnownEffectiveId()
			elseif first and first ~= card:getKnownEffectiveId() and not second then
				second = card:getKnownEffectiveId()
			end
		end
		if first and second then break end
	end

	if not second or not first then return end
	local card_str = ("#PlusJieyin_Card:%d+%d:"):format(first, second)
	assert(card_str)
	return parse(self,request,card_str)
end

ai_card_use["#PlusJieyin_Card"] = function(self, card, use, request)
	local target = nil
	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if other:getMark("@match") > 0 and other:isMale() then
			target = other
			break
		end
	end
	local can_invoke = false
	if target and target:isLord() then
		if target:getMark("hunzi") == 0 and target:hasSkill("hunzi") and self:getEnemyNumBySeat(self.player, target) <= (target:getHp() >= 2 and 1 or 0) then
			return
		elseif self:needToLoseHp(target, nil, nil, true, true) then
			return
		elseif not self:isLordHealthy() then
			can_invoke = true
		end
	else
		if self:needToLoseHp(target, nil, nil, nil, true) or (self:hasSkills("rende|kuanggu|zaiqi", target) and target:getHp() >= 2) then
			return
		else
			can_invoke = true
		end
	end

	if target and can_invoke then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

ai_skill_use["@PlusLiangyuan"] = function(self, prompt, request)
	local method = request and request.handling_method
	local min = 999
	for _, friend in ipairs(AIList.new(self.room:getOtherPlayers(self.player))) do
		if friend:getHandcardNum() < min then
			min = friend:getHandcardNum()
		end
	end
	if self.role == "loyalist" and self.room:getLord():isMale() and (self.room:getLord():getHandcardNum() == min or self.room:getLord():isWounded()) then
		return "#PlusLiangyuan_Card:.:->" .. self.room:getLord():objectName()
	end
	for _, friend in ipairs(self.friends_noself) do
		if (friend:getHandcardNum() == min or friend:isWounded()) and friend:isMale() then
			return "#PlusLiangyuan_Card:.:->" .. friend:objectName()
		end
	end

	return "."
end

sgs.ai_card_intention["#PlusLiangyuan_Card"] = -80

ai_skill_invoke.PlusYinli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end
sgs.ai_skill_askforag.PlusYinli = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end

ai_skill_invoke.PlusHongyan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return (true) or false
	end

	return (false) or false
end

sgs.ai_skill_askforag.PlusHongyan = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end

ai_skill_use["@PlusTianxiang"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:sortInPlace(self.enemies, "defense")
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	local use_card
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) and card:getSuit() == sgs.Card_Heart then
			use_card = card
		end
	end
	local target
	for _, friend in ipairs(self.friends_noself) do
		if self:ImitateResult_DrawNCards(friend, friend:getVisibleSkillList(true)) > 2 then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkill(sgs.cardneed_skill) then
				target = friend
				break
			end
		end
	end

	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:getOverflow(enemy) > 3 or enemy:hasSkill("yongsi") then
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
		return "#PlusTianxiang_Card:" .. use_card:getKnownEffectiveId() .. ":->" .. target:objectName()
	end

	return "."
end

ai_skill_choice["PlusTianxiang"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return ai_choice_result((items[1]), options)
	else
		if self:isEnemy(target) then
			return ai_choice_result(("PlusTianxiang_Discard"), options)
		end
	end
	return ai_choice_result(("PlusTianxiang_Draw"), options)
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

function ai_skill_invoke.PlusBuqu(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if #self.enemies == 1 and self.enemies[1]:hasSkill("guhuo") then
		return (false) or false
	else
		return (true) or false
	end
	return false

end

sgs.ai_hasBuquEffect_skill.PlusBuqu = function(player)
	return player:getPile("Plushurt"):length() <= 4
end

sgs.save_skill = sgs.save_skill .. "|PlusHuzhu"
function ai_skill_invoke.PlusHuzhu(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = data:toDying()
	local target = dying.who
	if target and self:isFriend(target) then
		return (true) or false
	end
	return (false) or false
end

function ai_skill_invoke.PlusBiyou(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return (not self:isWeak()) or false
	end
	return (false) or false
end

function ai_skill_invoke.PlusLiangjie(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

function ai_skill_invoke.PlusQiaojian(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return (true) or false
			elseif current:containsTrick("supply_shortage") then
				
				return (true) or false
			elseif current:containsTrick("indulgence") then
				if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return (true) or false end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return (true) or false
					end
				end
			end
		end
	end
	return (false) or false
end

sgs.ai_skill_cardask["@PlusQiaojian_Prompt"] = function(self, data, pattern, target, target2)
	local suit = pattern:split("|")[2]
	local current = self.room:getCurrent()
	local usable_cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(usable_cards)
	local give_card = {}
	if self:isFriend(current) then
		for _, c in ipairs(usable_cards) do
			if c:getSuitString() == suit then
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
		
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, -60)
	end
end

ai_skill_use["@PlusJiahuo"] = function(self, prompt, request)
	local method = request and request.handling_method
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self:isGoodChainTarget(self.player, current) then return "." end

	local others = self.room:getOtherPlayers(self.player)
	local slash = tag(self,"liuli-card"):toCard()
	others = AIList.new(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("LiuliSlashSource") then
			source = player
			break
		end
	end
	self:sortInPlace(self.enemies, "defense")

	local doLiuli = function(who)
		if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
			and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
			return "."
		end

		if (self.player:canSlash(who)) then
			if self:isFriend(who) then
				return "#PlusJiahuo_Card:.:->" .. who:objectName()
			else
				return "#PlusJiahuo_Card:.:->" .. who:objectName()
			end
		end

		if self.player:canSlash(who) then
			return "#PlusJiahuo_Card:.:->" .. who:objectName()
		end
		return "."
	end

	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doLiuli(player)
			if ret ~= "." then return ret end
		end
	end

	self:sortInPlace(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)

	for _, friend in ipairs(self.friends_noself) do
		if not self:slashIsEffective(slash, friend) or self:findLeijiTarget(friend, 50, source) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, nil) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
		and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end

	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end

function sgs.ai_slash_prohibit.PlusJiahuo(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	for _, friend in ipairs(self:getFriends(from, true)) do
		if to:canSlash(friend) and self:slashIsEffective(card, friend, from) then return not to:faceUp() end
	end
end

local PlusZenhui_skill = {
	name = "PlusZenhui",
	getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

		if self.player:getStrategyHasUsed("#PlusZenhui_Card") then return end
		local can_use = false
		self:sortInPlace(self.enemies, "chaofeng")
		for _, enemy_a in ipairs(self.enemies) do
			for _, enemy_b in ipairs(self.enemies) do
				if enemy_b:getHp() == enemy_a:getHp() then continue end
				if enemy_a:objectName() == enemy_b:objectName() then continue end
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
ai_card_use["#PlusZenhui_Card"] = function(self, card, use, request)
	local handcards = self.player:getHandcards()
	local blacks = {}
	for _, c in sgs.qlist(handcards) do
		if c:getSuit() == sgs.Card_Spade then
			table.insert(blacks, c) 
		end
	end
	if #blacks == 0 then return end
	self:sortByUseValueInPlace(blacks, true)
	local togive = nil
	self:sortInPlace(self.enemies, "chaofeng")
	local weak_enemy = {}
	local kong_enemy = {}
	local kong_weak = {}
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) and not enemy:isKongcheng() then
			table.insert(weak_enemy, enemy)
		elseif not self:isWeak(enemy) and enemy:isKongcheng() then
			if hasManjuanEffect(enemy) or enemy:hasSkill("qingjian") then continue end
			table.insert(kong_enemy, enemy)
		elseif self:isWeak(enemy) and enemy:isKongcheng() then
			table.insert(weak_enemy, enemy)
			if hasManjuanEffect(enemy) or enemy:hasSkill("qingjian") then continue end
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
				if enemy_b:getHp() == enemy_a:getHp() then continue end
				if enemy_a:objectName() == enemy_b:objectName() then continue end
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
					if enemy_b:getHp() == enemy_a:getHp() then continue end
					if enemy_a:objectName() == enemy_b:objectName() then continue end
					if not self:isWeak(enemy_b) then continue end
					togive = blacks[1]
					if enemy_a:getCardCount(true) > enemy_b:getCardCount(true) then
						if enemy_b:getCardCount(true) > 1 then
							lost_enemy = enemy_a
							dis_enemy = enemy_b
						else
							lost_enemy = enemy_b
							dis_enemy = enemy_a
						end
					else
						if enemy_a:getCardCount(true) > 1 then
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
					if enemy_b:getHp() == enemy_a:getHp() then continue end
					if enemy_a:objectName() == enemy_b:objectName() then continue end

					dis_enemy = enemy_b
					break
				end
				if not dis_enemy and #kong_enemy > 0 then
					for _, enemy_b in ipairs(kong_enemy) do
						if enemy_a:objectName() == enemy_b:objectName() then continue end
						if enemy_b:getHp() == enemy_a:getHp() then continue end
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
		local card_str = string.format("#PlusZenhui_Card:%s:", togive:getKnownEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then
			if dis_enemy:isKongcheng() then
				use.to:append(dis_enemy)
				use.to:append(lost_enemy)
			else
				use.to:append(lost_enemy)
				use.to:append(dis_enemy)
			end
		end
	end
end

sgs.ai_use_priority["PlusZenhui_Card"] = 0
sgs.ai_use_value["PlusZenhui_Card"] = 0
sgs.ai_card_intention["PlusZenhui_Card"] = 80

ai_skill_choice["PlusZenhui"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return ai_choice_result((items[1]), options)
	else
		if self:isEnemy(target) then
			return ai_choice_result(("PlusZenhui_Damage"), options)
		elseif self:isFriend(target) then
			if self:isWeak(target) then
				return ai_choice_result(("PlusZenhui_Discard"), options)
			elseif self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and self:needToLoseHp(target, self.player, nil) then
				return ai_choice_result(("PlusZenhui_Damage"), options)
			end
		end
	end
	return ai_choice_result(("PlusZenhui_Discard"), options)
end

local PlusSheji_skill = { name = "PlusSheji" }
table.insert(package_skills, PlusSheji_skill)
PlusSheji_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	self:updatePlayers()
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
		end
	end
	if (self.player:isKongcheng()) then return end
	if not has_weak_enemy then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Duel") > 0
			or (self:getCardsNum("Analeptic") > 0 and self:isWeak())
			or (self:getCardsNum("Jink") > 0 and self:isWeak())
			or self:getCardsNum("SupplyShortage") > 0 or self:getCardsNum("Indulgence") > 0
			or self:getCardsNum("ArcheryAttack") > 0 or self:getCardsNum("SavageAssault") > 0
		then
			return
		end
	end

	if self.player:getHandcardNum() > 1 then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not c:isKindOf("Analeptic") then
				if self:willUse(self.player, c) or c:isAvailable(self.player) then return end
			end
		end
	end
	local slash=turn_normal(self,"PlusSheji","slash",ids(self.player:getHandcards()),request)
	return slash
end
sgs.ai_use_priority.PlusSheji_skill = sgs.ai_use_priority.Slash - 0.1

function sgs.ai_cardsview.PlusSheji(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			local c=owner_normal(self,"PlusSheji","slash",ids(player:getHandcards()))
			return c:getLegacyStringKey()
		end
	end
end

sgs.ai_card_priority.PlusSheji = function(self, card)
	if card:isKindOf("Slash") and self.player:getHandcardNum() < 4 and table.contains(card:getSkillNames(), "PlusSheji")
	then
		return 1
	end
end

sgs.save_skill = sgs.save_skill .. "|PlusMafei"

sgs.ai_use_revises.PlusMafei = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:isRed()
	then
		same = self:getSameEquip(card)
		if same and same:isRed()
		then
			return false
		end
	end
end

sgs.ai_target_revises.PlusMafei = function(to, card)
	if (card:isKindOf("Slash")
			or card:isNDTrick()) and to:hasFlag("PlusMafei")
	then
		return true
	end
end

sgs.PlusMafei_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.PlusMafei = function(to, card)
	return card:isRed()
end

sgs.ai_skill_cardask["@PlusMafei_Prompt"] = function(self, data, pattern, target, target2)
	local dying = data:toDying()
	local target = dying.who
	local usable_cards = AIList.new(self.player:getCards("he"))
	self:sortByKeepValueInPlace(usable_cards)
	local give_card = {}
	if self:isFriend(target) then
		for _, c in ipairs(usable_cards) do
			if c:isRed() then
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
	if card:isKindOf("Slash") and self:isWeak()
		and self:getOverflow() <= 0
	then
		return false
	end
end

local PlusXuanhu_skill = {}
PlusXuanhu_skill.name = "PlusXuanhu"
table.insert(package_skills, PlusXuanhu_skill)
PlusXuanhu_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getHandcardNum() < 1 then return nil end
	if self.player:getStrategyHasUsed("#PlusXuanhu_Card") then return nil end

	local cards = self.player:getHandcards()
	cards = AIList.new(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + (a:isRed() and 50 or 0) + (a:isKindOf("Peach") and 50 or 0)
		local v2 = self:getKeepValue(b) + (b:isRed() and 50 or 0) + (b:isKindOf("Peach") and 50 or 0)
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("#PlusXuanhu_Card:%d:"):format(cards[1]:getId())
	return parse(self,request,card_str)
end

ai_card_use["#PlusXuanhu_Card"] = function(self, card, use, request)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				if use.to then use.to:append(friend) end
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
	self:sortInPlace(targets, "defense")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) and friend:isAlive() then
			if friend:isLord() and self:isWeak(friend) then return friend end
			if not (friend:hasSkill("zhiji") and friend:getMark("zhiji") == 0 and not self:isWeak(friend) and friend:getPhase() == sgs.Player_NotActive) then
				if self:getRoleEstimate(friend) == "renegade" then
					second = friend
				elseif self:getRoleEstimate(friend) ~= "renegade" and not first then
					first = friend
				end
			end
		end
	end
	if first then return first end
	if second then return second end
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) then
			return friend
		end
	end
	return nil
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|PlusQingnang"

ai_skill_choice["PlusQingnang"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return ai_choice_result((items[1]), options)
	else
		if self:isFriend(target) then
			if self:isWeak(target) or self:hasSkills(sgs.need_maxhp_skill, target) then
				return ai_choice_result(("PlusQingnang_choice1"), options)
			else
				return ai_choice_result(("PlusQingnang_choice2"), options)
			end
		end
	end
	return ai_choice_result(("PlusQingnang_choice1"), options)
end

sgs.ai_skill_cardask["@PlusGuidao-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(disclosed(self,id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade and
		((not self.player:hasSkill("leiji") and not self.player:hasSkill("olleiji")) or judge.card:getSuit() ~= sgs.Card_Club)
		and aoe_truth(self) and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and
		self:findLeijiTarget(self.player, 50)
		and (self:getCardsNum("Jink") > 0 or self:hasEightDiagramEffect()) and self:getFinalRetrial() == 1

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("nosleiji") then keptspade = 2 end
		if self.player:hasSkill("PlusLeiji") then keptspade = 2 end
		if self.player:hasSkill("leiji") then keptblack = 2 end
		if self.player:hasSkill("olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isBlack() and not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not self.player:hasSkill("olleiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("leiji") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValueInPlace(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(disclosed(self,card_id)) then
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

ai_skill_use["@PlusGuidao2"] = function(self, prompt, request)
	local targets = AIList.new(self.room:getAllPlayers())
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
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = AIList.new(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValueInPlace(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") and acard:isBlack() then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getKnownEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getKnownEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuidao_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuidao_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = AIList.new(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValueInPlace(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") and acard:isBlack() then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getKnownEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getKnownEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuidao_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuidao_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end

function sgs.ai_cardneed.PlusGuidao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club and self:hasSuit("club", true, to)
			end
		end
	end
end

function sgs.ai_cardneed.PlusLeiji(to, card, self)
	return ((isCard("Jink", card, to) and getKnownCard(to, "Jink", true) == 0)
		or (card:getSuit() == sgs.Card_Spade and self:hasSuit("spade", true, to))
		or (card:isKindOf("EightDiagram") and not (self:isEquip("EightDiagram") or getKnownCard(to, "EightDiagram", false) > 0)))
end

ai_skill_use["@PlusLeiji"] = function(self, prompt, request)
	local mode = self.room:getMode()
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers();
		for _, aplayer in sgs.qlist(players) do
			if aplayer:getState() ~= "robot" then
				return "#PlusLeiji_Card:.:->" .. aplayer:objectName()
			end
		end
	end

	self:updatePlayers()
	self:sortInPlace(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("SilverLion") and not enemy:hasSkill("hongyan") and
			self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:canDamage(enemy, self.player, nil) then
			return "#PlusLeiji_Card:.:->" .. enemy:objectName()
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasSkill("hongyan")
			and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) then
			return "#PlusLeiji_Card:.:->" .. enemy:objectName()
		end
	end

	return "."
end

sgs.ai_card_intention["#PlusLeiji_Card"] = 80

function sgs.ai_slash_prohibit.PlusLeiji(self, to, card)
	if self:isFriend(to) then return false end
	local hcard = to:getHandcardNum()
	if self.player:hasSkill("liegong") and (hcard >= self.player:getHp() or hcard <= self.player:getAttackRange()) then return false end
	if self.role == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:getRoleEstimate(player) == "rebel" or self:compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and (self:hasSkills("hongyan") or self.player:getHp() >= 4) and (self:getCardsNum("Peach") > 0 or self:hasSkills("hongyan|ganglie|neoganglie")) then
			return false
		end
	end

	if getKnownCard(to, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if self:isEquip("EightDiagram", to) and not IgnoreArmor(self.player, to) then return true end
end

local PlusHuangtianQun_skill = {}
PlusHuangtianQun_skill.name = "PlusHuangtianQun"
table.insert(package_skills, PlusHuangtianQun_skill)
PlusHuangtianQun_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasFlag("ForbidPlusHuangtian") then return nil end
	if self.player:getKnownKingdom() ~= "qun" then return nil end

	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	local card
	self:sortByUseValueInPlace(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Jink") or acard:isKindOf("ThunderSlash") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getKnownEffectiveId()
	local card_str = "#PlusHuangtian_Card:" .. card_id .. ":"
	local skillcard = parse(self,request,card_str)

	assert(skillcard)
	return skillcard
end

ai_card_use["#PlusHuangtian_Card"] = function(self, card, use, request)
	if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("PlusHuangtian") then
			if not friend:hasFlag("PlusHuangtianInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then 
		use.card = card
		self:sortInPlace(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", "he") >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("PlusHuangtian") then
				if not enemy:hasFlag("PlusHuangtianInvoked") then
					if not hasManjuanEffect(enemy) then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not hasTuntianEffect(enemy, true) then
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:getStrategyHasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:getStrategyHasUsed("XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player)
				if maxCard:getNumber() > card:getNumber() then
					self:sortInPlace(targets, "defense", true)
					for _, enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then
							use.card = card
							self:setStrategyPlayerFlag(enemy, "AI_HuangtianPindian", true)
							if use.to then
								use.to:append(enemy)
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
	if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:getStrategyHasUsed("TianyiCard"))
			or (from:hasSkill("xianzhen") and not from:getStrategyHasUsed("XianzhenCard"))) then
	else
		self:updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority.PlusHuangtian_Card = 10
sgs.ai_use_value.PlusHuangtian_Card = 8.5

sgs.exclusive_skill = sgs.exclusive_skill .. "|PlusHunzhou"

sgs.bad_skills = sgs.bad_skills .. "|PlusShiyong"

ai_skill_choice["PlusMizhao_Card"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if #items == 1 then
		return ai_choice_result((items[1]), options)
	else
		local target = data:toPlayer()
		if self.player:canSlash(target) and self:isEnemy(target) then
			local slash = self:cloneEvaluationCard("slash")
			
			if not self:slashProhibit(slash, target) and self.player:canSlash(target, slash, false) and self:isGoodTarget(target, self.enemies, slash) then
				return ai_choice_result(("PlusMizhao_Use"), options)
			end
		end
	end
	return ai_choice_result(("PlusMizhao_Draw"), options)
end

local PlusMizhao_skill = {}
PlusMizhao_skill.name = "PlusMizhao"
table.insert(package_skills, PlusMizhao_skill)
PlusMizhao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#PlusMizhao_Card") then return end
	local use_cards = {}
	local card
	if self:needToThrowArmor() then
		table.insert(use_cards, self.player:getArmor():getEffectiveId())
	end
	if #use_cards < 3 then
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			if #use_cards < 3 then
				if hcard:isKindOf("Slash") then
					if self:getCardsNum("Slash") > 1 then
						card = hcard
						break
					else
						local dummy_use = self:aiUseCard(hcard)
						if dummy_use and dummy_use.to and (dummy_use.to:length() == 0
								or dummy_use.to:length() == 1 and not self:hasHeavyDamage(self.player, hcard, dummy_use.to:first())) then
							table.insert(use_cards, hcard:getKnownEffectiveId())
						end
					end
				else
					table.insert(use_cards, hcard:getKnownEffectiveId())
				end
			else
				break
			end
		end
	end
	if #use_cards < 3 then
		local ecards = self.player:getCards("e")
		ecards = AIList.new(ecards)

		for _, ecard in ipairs(ecards) do
			if (ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse")) and #use_cards < 3 then
				table.insert(use_cards, ecard:getKnownEffectiveId())
			end
		end
	end
	if #use_cards == 3 then
		card = parse(self,request,"#PlusMizhao_Card:" .. table.concat(use_cards, "+") .. ":")
		return card
	end

	return nil
end

ai_card_use["#PlusMizhao_Card"] = function(self, card, use, request)
	local target
	local friends = self.friends_noself
	local slash = self:cloneEvaluationCard("slash")
	
	remember_player(self,"PlusMizhaoTarget",nil)

	local canMingceTo = function(player)
		local canGive = not self:needKongcheng(player, true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player, player) == 0)
	end

	self:sortInPlace(self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) then
			for _, enemy in ipairs(self.enemies) do
				if friend:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
					and enemy:objectName() ~= self.player:objectName() then
					target = friend
					remember_player(self,"PlusMizhaoTarget",enemy)
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		self:sortInPlace(friends, "defense")
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
			use.to:append(target)
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

ai_skill_invoke.PlusAnxi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local target = self.room:getCurrent()
	if self:isFriend(target) then return (false) or false end
	if target:getHandcardNum() > self.player:getHandcardNum() and not target:isKongcheng() and self.player:canPindian(target) then
		local enemy_max_card = self:getMaxCard(target)
		local allknown = 0
		if self:getKnownNum(target) == target:getHandcardNum() then
			allknown = allknown + 1
		end
		if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
			or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
			or (not enemy_max_card and max_point > 10) then
			self:remember("PlusAnxi_card", max_card:getKnownEffectiveId())
			return (true) or false
		end
	end
	return (false) or false
end

ai_skill_invoke.PlusAnxidamage = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_audited_aliases.register{id="ai_cardneed.PlusAnxi",registry="ai_cardneed",path={"PlusAnxi"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_playerchosen.PlusAnxi",registry="ai_skill_playerchosen",path={"PlusAnxi"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"},self_index=1,defer_canonical=true}
local PlusZhuni_skill = {}
PlusZhuni_skill.name = "PlusZhuni"
table.insert(package_skills, PlusZhuni_skill)

PlusZhuni_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = AIList.new(self.player:getCards("h"))
	local subcards = {}
	self:sortByUseValueInPlace(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if card:isBlack() then table.insert(cardsq, card) end
	end
	if #cardsq == 0 then return end
	if self:getKeepValue(cardsq[1]) > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "Collateral:PlusZhuni[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = parse(self,request,card_str)
	assert(AsCard)
	return AsCard
end

sgs.ai_skill_cardask["@PlusZhuni"] = function(self, data, pattern, target)
	local victim = data:toPlayer()
	if not victim then return "." end
	if self:isFriend(victim) then return "." end
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = AIList.new(self.player:getCards("e"))
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		return "$" .. card:getKnownEffectiveId()
	end
	return "$" .. cards[1]:getEffectiveId()
end

ai_skill_use["@PlusKuangjun"] = function(self, prompt, request)
	local method = request and request.handling_method
	local arr1, arr2 = self:getWoundedFriend(false, false)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		return "#PlusKuangjun_Card:.:->" .. target:objectName()
	end

	return "."
end
sgs.ai_card_intention["PlusKuangjun_Card"] = -80

local PlusZhiren_skill = {}
PlusZhiren_skill.name = "PlusZhiren"
table.insert(package_skills, PlusZhiren_skill)
PlusZhiren_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#PlusZhiren_Card") then return nil end
	if #self.friends == 0 then return nil end
	local card_str = "#PlusZhiren_Card:.:"
	return parse(self,request,card_str)
end

ai_card_use["#PlusZhiren_Card"] = function(self, card, use, request)
	self:sortInPlace(self.friends, "handcard")
	self.friends = sgs.reverse(self.friends)
	local target = self:findPlayerToDraw(true, 2)
	if target and not target:isKongcheng() and getKnownCard(target, self.player, "EquipCard", true) + getKnownCard(target, self.player, "TrickCard", true) > 0 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	for _, friend in ipairs(self.friends) do
		if not friend:isKongcheng() and self:canDraw(friend, self.player) and getKnownCard(friend, self.player, "EquipCard", true) + getKnownCard(friend, self.player, "TrickCard", true) > 0 then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if not friend:isKongcheng() and friend:getHp() < self:getBestHp(friend) and getKnownCard(friend, self.player, "BasicCard", true) > 0 then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
	if target and not target:isKongcheng() then
		use.card = card
		if use.to then use.to:append(target) end
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
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("PlusZhiren") then
			target = p
			break
		end
	end
	if not target then return -1 end
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") and target:getHp() < self:getBestHp(target) then
			return card:getKnownEffectiveId()
		end
	end
	for _, card in ipairs(cards) do
		if not card:isKindOf("BasicCard") then
			return card:getKnownEffectiveId()
		end
	end
	return -1
end

ai_skill_invoke.PlusChenghao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self.room:getCurrent()
	if self:isFriend(target) then return (true) or false end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.PlusChenghao = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, current, -20)
		end
	end
end

ai_skill_choice.SixWulve = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local damage = data:toDamage()
	if not damage.card then return ai_choice_result(("SixWulveDraw"), options) end
	
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then
		return
		ai_choice_result(("SixWulveDraw"), options)
	end
	if damage.card then 
		if damage.card:isVirtualCard() then
			return ai_choice_result(("SixWulveDraw"), options)
		end
	end
	
	local items = choices:split("+")
	if table.contains(items, "SixWulveGet") then return ai_choice_result(("SixWulveGet"), options) end
	return ai_choice_result((items[1]), options)
end

ai_skill_invoke.SixWulve = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self.room:getCurrent()
	if target and self:isFriend(target) then
		for _, id in sgs.qlist(self.player:getPile("strategy")) do
			local c = disclosed(self,id)
			if c:targetFixed() then
				if c:isKindOf("Peach") and target:isWounded() and target:getHp() <= 2 then
					return (true) or false
				end
				if c:isKindOf("ExNihilo") and target:getHandcardNum() <= 2 then
					return (true) or false
				end
				if c:isKindOf("SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return (true) or false
					end
				end
				if c:isKindOf("ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return (true) or false
					end
				end
				if c:isKindOf("AmazingGrace") then
					local low_handcard_friend = false
					for _, friend in ipairs(self.friends_noself) do
						if friend:getHandcardNum() <= 4 then
							low_handcard_friend = true
						end
					end
					if low_handcard_friend then
						return (true) or false
					end
				end
				if c:isKindOf("GodSalvation") then
					if self:willUseGodSalvation(c) then
						return (true) or false
					end
				end
				if c:isKindOf("EquipCard") then
					local equip_index = c:getEquipSlot()
					if target:getEquip(equip_index) == nil and target:hasEquipArea(equip_index) then
						return (true) or false
					end
				end
			else
				if c:isKindOf("Slash") then
					local dummyuse = self:aiUseCard(c)
					local targets = {}
					if not dummyuse.to:isEmpty() then
						for _, p in sgs.qlist(dummyuse.to) do
							return (true) or false
						end
					end
				end
				
				if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
					local dummyuse = self:aiUseCard(c)
					local targets = {}
					if not dummyuse.to:isEmpty() then
						for _, p in sgs.qlist(dummyuse.to) do
							if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
								return (true) or false
							end
						end
					end
				end
			end

		end
	end
	return (false) or false
end

sgs.ai_skill_askforag.SixWulve = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, disclosed(self,card_id))
	end
	self:sortByUseValueInPlace(cards)
	local target = self.room:getCurrent()
	for _, c in ipairs(cards) do
		if c:targetFixed() then
			if c:isKindOf("Peach") and target:isWounded() and target:getHp() <= 2 then
				return c:getKnownEffectiveId()
			end
			if c:isKindOf("ExNihilo") and target:getHandcardNum() <= 2 then
				return c:getKnownEffectiveId()
			end
			if c:isKindOf("SavageAssault") then
				if self:getAoeValue(c) > 0 then
					return c:getKnownEffectiveId()
				end
			end
			if c:isKindOf("ArcheryAttack") then
				if self:getAoeValue(c) > 0 then
					return c:getKnownEffectiveId()
				end
			end
			if c:isKindOf("AmazingGrace") then
				local low_handcard_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:getHandcardNum() <= 4 then
						low_handcard_friend = true
					end
				end
				if low_handcard_friend then
					return c:getKnownEffectiveId()
				end
			end
			if c:isKindOf("GodSalvation") then
				if self:willUseGodSalvation(c) then
					return c:getKnownEffectiveId()
				end
			end
			if c:isKindOf("EquipCard") then
				local equip_index = c:getEquipSlot()
				if target:getEquip(equip_index) == nil and target:hasEquipArea(equip_index) then
					return c:getKnownEffectiveId()
				end
			end
			
		else
			if c:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then
				local dummyuse = self:aiUseCard(c)
				local targets = {}
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						return c:getKnownEffectiveId()
					end
				end
			end
			
			if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
				local dummyuse = self:aiUseCard(c)
				local targets = {}
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
							return c:getKnownEffectiveId()
						end
					end
				end
			end
		end
	end

	return -1
end

sgs.ai_can_damagehp.SixWulve = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return (card:isNDTrick() and card:isDamageCard()) or card:isKindOf("AOE")
	end
end
sgs.ai_target_revises.SixWulve = function(to, card, self)
	if card:isDamageCard()
		and not self:isFriend(to)
		and card:subcardsLength() > 0
	then
		for _, id in sgs.list(card:getSubcards()) do
			if isCard("Peach,Analeptic", disclosed(self,id), to)
			then
				return true
			end
		end
	end
end

ai_skill_use["@@SixWulveOthers!"] = function(self, prompt, request)
	local method = request and request.handling_method
	local taoluan_use_card=property_card(self,"SixWulve",owner_fact(self,"six_wulve_card"))

	local dummyuse = self:aiUseCard(taoluan_use_card)
	local targets = {}
	if not dummyuse.to:isEmpty() then
		for _, p in sgs.qlist(dummyuse.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return taoluan_use_card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end

ai_audited_aliases.register{id="ai_skill_invoke.SixLangmou",registry="ai_skill_invoke",path={"SixLangmou"},canonical_registry="ai_skill_invoke",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SixLangmou",registry="ai_choicemade_filter",path={"cardChosen","SixLangmou"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_cardchosen.SixLangmou",registry="ai_skill_cardchosen",path={"SixLangmou"},canonical_registry="ai_skill_cardchosen",canonical_path={"fankui"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_need_damaged.SixLangmou",registry="ai_need_damaged",path={"SixLangmou"},canonical_registry="ai_need_damaged",canonical_path={"fankui"},self_index=1,defer_canonical=true}
sgs.use_lion_skill = sgs.use_lion_skill .. "|SixTaohui"

ai_skill_use["@SixTaohui"] = function(self, prompt, request)
	local method = request and request.handling_method
	local cards = {}
	if self:needToThrowArmor(self.player) then
		table.insert(cards, self.player:getArmor():getEffectiveId())
	end
	for _, c in ipairs(AIList.new(self.player:getCards("e"))) do
		if not table.contains(cards, c:getKnownEffectiveId()) and self:doDisCard(self.player, c:getKnownEffectiveId(), true) then
			table.insert(cards, c:getKnownEffectiveId())
		end
	end
	if #cards > 0 then
		return "#SixTaohuiCard:" .. table.concat(cards, "+") .. ":"
	end
	return "."
end

sgs.wizard_skill = sgs.wizard_skill .. "|SixGuicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|SixGuicai"

ai_skill_use["@@SixGuicai2"] = function(self, prompt, request)
	local targets = AIList.new(self.room:getAllPlayers())
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
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = AIList.new(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValueInPlace(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			if #cards > 0 then
				return "#SixGuicaiCard:" .. cards[1]:getEffectiveId() .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = AIList.new(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValueInPlace(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			if #cards > 0 then
				return "#SixGuicaiCard:" .. cards[1]:getEffectiveId() .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end

ai_skill_choice["SixGuicaipindian"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target

	local targets = AIList.new(self.room:getAllPlayers())
	for _, p in ipairs(targets) do
		if p:hasFlag("SixGuicaiModify") then
			target = p
		end
	end
	if target then
		if self:isFriend(target) then
			return ai_choice_result(("13"), options)
		else
			return ai_choice_result(("1"), options)
		end
	end
	return ai_choice_result(("1"), options)
end
function sgs.ai_skill_suit.SixGuicai(self)
	local judge = tag(self,"CurrentJudgeStruct"):toJudge()
	local who = judge.who
	if judge and self:needRetrial(judge) then
		if judge.reason == "beige" then
			local damage = tag(self,"CurrentDamageStruct"):toDamage()
			if damage.from then
				if self:isFriend(damage.from) then
					if not self:toTurnOver(damage.from, 0) and judge.card:getSuit() ~= sgs.Card_Spade then
						return sgs.Card_Spade
					else
						local retr = true
						if (judge.card:getSuit() == sgs.Card_Heart and who:isWounded() and self:isFriend(who))
							or (judge.card:getSuit() == sgs.Card_Diamond and self:isEnemy(who) and hasManjuanEffect(who))
							or (judge.card:getSuit() == sgs.Card_Club and self:needToThrowArmor(damage.from)) then
							retr = false
						end
						if retr then
							if (self:isFriend(who) and who:isWounded()) then
								return sgs.Card_Heart
							elseif self:isEnemy(who) and hasManjuanEffect(who) then
								return sgs.Card_Diamond
							elseif self:isFriend(who) and not hasManjuanEffect(who) then
								return sgs.Card_Diamond
							elseif (self:needToThrowArmor(damage.from) or damage.from:isNude()) then
								return sgs.Card_Club
							elseif self:toTurnOver(damage.from, 0) then
								return sgs.Card_Spade
							end
						end
					end
				else
					if not self:toTurnOver(damage.from, 0) and judge.card:getSuit() == sgs.Card_Spade then
						return sgs.Card_Club
					end
				end
			end
		elseif self:isFriend(who) and not (self:getFinalRetrial() == 2) then
			local newcard = judge:cloneCandidate(sgs.Card_Diamond, 0)
			
			if judge:isGood(newcard) then
				return sgs.Card_Diamond
			end
			local newcard = judge:cloneCandidate(sgs.Card_Heart, 0)
			
			if judge:isGood(newcard) then
				return sgs.Card_Heart
			end
			local newcard = judge:cloneCandidate(sgs.Card_Spade, 0)
			
			if judge:isGood(newcard) then
				return sgs.Card_Spade
			end
			local newcard = judge:cloneCandidate(sgs.Card_Club, 0)
			
			if judge:isGood(newcard) then
				return sgs.Card_Club
			end
		elseif self:isEnemy(who) and not (self:getFinalRetrial() == 2) then
			local newcard = judge:cloneCandidate(sgs.Card_Diamond, 0)
			
			if not judge:isGood(newcard) then
				return sgs.Card_Diamond
			end
			local newcard = judge:cloneCandidate(sgs.Card_Heart, 0)
			
			if not judge:isGood(newcard) then
				return sgs.Card_Heart
			end
			local newcard = judge:cloneCandidate(sgs.Card_Spade, 0)
			
			if not judge:isGood(newcard) then
				return sgs.Card_Spade
			end
			local newcard = judge:cloneCandidate(sgs.Card_Club, 0)
			
			if not judge:isGood(newcard) then
				return sgs.Card_Club
			end
		end
	end
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	return suit
end

ai_skill_choice["SixGuicai"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local judge = data:toJudge()
	local items = choices:split("+")
	local target = judge.who
	if target and self:needRetrial(judge) then
		if self:isFriend(target) then
			return ai_choice_result(("13"), options)
		else
			return ai_choice_result((items[math.random(3, #items - 3)]), options)
		end
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end

sgs.ai_skill_cardask["@SixGuicai"] = function(self, data)
	local judge = data:toJudge()

	if self:needRetrial(judge) then
		local cards = AIList.new(self.player:getCards("h"))
		
		if #cards > 0 then
			
			return "#SixGuicaiDummyCard:" .. cards[1]:getEffectiveId() .. ":"
		end
	end

	return "."
end

function sgs.ai_cardneed.SixGuicai(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return to:getCards("h"):length() <= 2 and not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return to:getCards("h"):length() <= 2
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return to:getCards("h"):length() <= 2
			end
		end
	end
end

sgs.ai_skill_cardask["@SixHuwei"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return "." end
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end

	local has_equip

	for _, card in sgs.qlist(self.player:getCards("e")) do
		if card:isKindOf("EquipCard") and self.player:hasSkills(sgs.lose_equip_skill) then
			has_equip = card
		end
	end

	if has_equip then
		return "$" .. has_equip:getKnownEffectiveId()
	else
		return "."
	end
end

function sgs.ai_armor_value.SixHuwei(player, self, card)
	if not card then return 4 end
end

ai_skill_invoke.SixJushou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if sgs.ai_skill_playerchosen.SixJushou(self, AIList.new(self.room:getOtherPlayers(self.player))) ~= nil then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.SixJushou = function(self, targets)
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "handcard")
	local target = nil
	local n = math.min(self.player:getMark("SixJushou"), 4)
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, n, "SixJushou") and friend:faceUp() and friend:inMyAttackRange(self.player) then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = self:findPlayerToDraw(false, n)
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "SixJushou") and hasManjuanEffect(enemy) and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
						target = enemy
						break
					end
				end
			end
		else
			self:sortInPlace(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, n, "SixJushou") and hasManjuanEffect(enemy) and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "SixJushou") and self:hasSkills(sgs.priority_skill, enemy) and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "SixJushou") and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
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
	if hasManjuanEffect(to) then self:updateIntention(from, to, 80) end
	local intention = 80 / math.max(from:getMark("SixJushou"), 1)
	if not self:toTurnOver(to, from:getMark("SixJushou"), "SixJushou") then intention = -intention end
	if from:getMark("SixJushou") < 3 then
		self:updateIntention(from, to, intention)
	else
		self:updateIntention(from, to, math.min(intention, -30))
	end
end

ai_skill_use["@@SixMingduan"] = function(self, prompt, request)
	local can_invoke = false
	local target = self.room:getCurrent()
	local slash2 = self:cloneEvaluationCard("slash")
	
	if self.room:alivePlayerCount() <= 2 or #self.friends_noself < 1 then return "." end

	if self:isEnemy(target) then
		if target:isJilei(slash2) then can_invoke = true end

		if target:hasSkills("guose|qixi|duanliang|ol_duanliang|luanji") and target:getHandcardNum() > 1 then can_invoke = true end
		if target:hasSkills("shuangxiong") and not self:isWeak(target) then can_invoke = true end
		if not self:slashIsEffective(slash2, self.player, target) and not self:isWeak() then can_invoke = true end
		if self.player:getArmor() and self.player:getArmor():isKindOf("Vine") and not self:isWeak() then can_invoke = true end
		if self.player:getArmor() and not self:isWeak() and self:getCardsNum("Jink") > 0 then can_invoke = true end
	end

	local use_card
	local slashtarget
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	for _, c in ipairs(cards) do
		if c:isBlack() then
			use_card = c
			break
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not target:isProhibited(enemy, slash2) and self:slashIsEffective(slash2, enemy) then
			slashtarget = enemy
			break
		end
	end
	if use_card and can_invoke and slashtarget then
		return "#SixMingduanCard:" .. use_card:getKnownEffectiveId() .. ":"
	end
	return "."
end

sgs.ai_skill_playerchosen.SixMingduan = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

ai_skill_invoke.SixQiaoxie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and not self:isEnemy(target) and #self.enemies > 0 and self:getCardsNum("Slash") >= 1 and not self:needBear() then
		local slash = self:cloneEvaluationCard("slash")
		
		local dummy_use=self:withOwnerRange("slashNoDistanceLimit", "SixQiaoxie", function()return self:aiUseCard(slash)end)
		if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				if not self.player:inMyAttackRange(p) then
					return (true) or false
				end
			end
		end
	end
	return (false) or false
end

sgs.ai_skill_cardask["@SixQiaoxie"] = function(self, data, pattern, target)
	local target = self.room:getCurrent()
	if target and self:isFriend(target) then
		local cards = AIList.new(self.player:getCards("h"))
		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if card:isBlack() then
				return "$" .. card:getKnownEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@SixQiaoxie"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, -60)
	end
end

ai_skill_use["@@SixZhidi"] = function(self, prompt, request)
	local use_card
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)

	if #cards > 0 then
		return "#SixZhidiCard:" .. cards[1]:getEffectiveId() .. ":"
	end
	return "."
end

ai_skill_invoke.SixZhidi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()

	if use.card then
		if use.card:isKindOf("Peach") then return (false) or false end
		return (not (use.card:isKindOf("Slash") and self:isPriorFriendOfSlash(self.player, use.card, use.from))) or false
	end
	return false

end

local SixChouzuan_skill = {}
SixChouzuan_skill.name = "SixChouzuan"
table.insert(package_skills, SixChouzuan_skill)
SixChouzuan_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies == 0 then return end
	if self.player:getStrategyHasUsed("#SixChouzuanCard") then return nil end
	return parse(self,request,"#SixChouzuanCard:.:")
end

ai_card_use["#SixChouzuanCard"] = function(self, card, use, request)
	local maxvalue = 0
	local target
	for _, friend in ipairs(self.friends_noself) do
		local value = 0
		local enemies = {}
		for _, enemy in ipairs(self.enemies) do
			if friend:inMyAttackRange(enemy) then table.insert(enemies, enemy) end
		end
		if #enemies == 0 then return end
		self:sortInPlace(enemies, "hp")

		local card_ids = {}

		local zcards = self.player:getHandcards()
		local use_slash, keep_jink, keep_analeptic = false, false, false
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
				end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(card_ids, zcard:getKnownId()) end
			end
		end

		if #card_ids >= friend:getAttackRange() then
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if friend:inMyAttackRange(p) then
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
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["#SixChouzuanCard"] = 0.6
sgs.ai_use_value["#SixChouzuanCard"] = 2.45
sgs.ai_card_intention["#SixChouzuanCard"] = -80

ai_skill_choice["SixChouzuan"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local current = self.room:getCurrent()
	if (self:needToLoseHp(self.player, nil, nil)) and not self:isWeak() then
		return ai_choice_result(("SixChouzuanDamage"), options)
	end
	return ai_choice_result(("SixChouzuanDraw"), options)
end

sgs.ai_skill_playerchosen.SixWeiyuan = function(self, targets)
	local target, min_friend, max_enemy
	for _, enemy in ipairs(self.enemies) do
		if not self:hasSkills(sgs.lose_equip_skill, enemy) and not hasTuntianEffect(enemy, true) and self.player:getPile("wooden_ox"):length() == 0 then
			local ee = enemy:getEquips():length()
			local fe = self.player:getEquips():length()
			local value = self:evaluateArmor(enemy:getArmor(), self.player) -
				self:evaluateArmor(self.player:getArmor(), enemy)
				- self:evaluateArmor(self.player:getArmor(), self.player) + self:evaluateArmor(enemy:getArmor(), enemy)
			if ee > 0 and (ee > fe or ee == fe and value > 0) then
				return enemy
			end
		end
	end
	if self.player:getEquips():length() > 2 then
		for _, friend in ipairs(self.friends_noself) do
			if (self:hasSkills(sgs.lose_equip_skill, friend)
				or (hasTuntianEffect(friend, true)) or self:hasSkills(sgs.need_equip_skill, friend)) and friend:getEquips():length() < self.player:getEquips():length() then
				return friend
			end
		end
	end

	target = nil
	if self:needToThrowArmor(self.player) or ((self:hasSkills(sgs.lose_equip_skill, self.player)
				or (hasTuntianEffect(self.player, true)))
			and not self.player:getEquips():isEmpty()) then
		target = self.player
	end
	if not target then return end
	for _, friend in ipairs(self.friends_noself) do
		if (self:hasSkills(sgs.lose_equip_skill, friend)
			or (hasTuntianEffect(friend, true)) or self:hasSkills(sgs.need_equip_skill, friend)) then
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
	getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

		if self:getCardsNum("Slash") == 0 then return end
		if self.player:getStrategyHasUsed("#SixTaichenCard") then return end
		local can_use = false
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:isNude() then continue end
			if self.player:inMyAttackRange(p) then
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
ai_card_use["#SixTaichenCard"] = function(self, card, use, request)
	local handcards = self.player:getHandcards()
	local slashs = {}
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			if self.player:canDiscard(self.player, c:getKnownEffectiveId()) then
				table.insert(slashs, c)
			end
		end
	end
	if #slashs == 0 then return end
	self:sortInPlace(self.enemies, "chaofeng")
	local enemys = {}
	for _, enemy in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(enemy) then continue end
		if self:cantbeHurt(enemy) then continue end
		if not self:canDamage(enemy, self.player, nil) then continue end
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Normal) then continue end
		if self:getCardsNum("Slash") - 1 < getCardsNum("Slash", enemy) and self.player:getHp() <= enemy:getHp() then continue end
		table.insert(enemys, enemy)
	end
	if #enemys > 0 then
		local card_str = string.format("#SixTaichenCard:%s:", slashs[1]:getEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then use.to:append(enemys[1]) end
	end
end

local SixRende_skill = {}
SixRende_skill.name = "SixRende"
table.insert(package_skills, SixRende_skill)
SixRende_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return end
	if self.player:getHandcardNum() <= 1 and self.player:getMaxCards() > 0 and self.player:getMark("SixRende") == 0 then return end
	local mode = string.lower(self.room:getMode())
	if self.player:getMark("SixRende") > 1 and mode:find("04_1v3") then return end

	if self.player:isWounded() then
		if self.player:getMark("SixRende") > 1 and self:getOverflow() <= 0 then return end
	end

	if self:shouldUseRende() then
		return parse(self,request,"#SixRendeCard:.:")
	end
end

ai_card_use["#SixRendeCard"] = function(self, card, use, request)
	
	if self.player:getHp() < 3 and self.player:isWounded() and self.player:getHandcardNum() == 2 then
		self:sortInPlace(self.friends_noself, "handcard")
		local give_all_cards = {}
		for _, c in ipairs(AIList.new(self.player:getCards("h"))) do
			table.insert(give_all_cards, c:getKnownEffectiveId())
		end
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
		if #targets > 0 and #give_all_cards > 1 then
			local card_str = string.format("#SixRendeCard:" .. table.concat(give_all_cards, "+") .. ":")
			local acard = parse(self,request,card_str)
			use.card = acard
			if use.to then
				use.to:append(targets[1])
			end
			return
		end
	end

	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	local notFound

	for i = 1, self.player:getHandcardNum() do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			cards = self:resetCards(cards, card)
		else
			notFound = true
			break
		end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
		local canJijiang = self.player:hasLordSkill("jijiang") and friend:getKnownKingdom() == "shu"
		if card:isAvailable(self.player) and ((card:isKindOf("Slash") and not canJijiang) or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card
			then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then
						continue
					elseif t1:getHp() == 1 or getCardsNum("Jink",t1,self.player)<1
						or t1:isCardLimited(self:cloneEvaluationCard("jink"), sgs.Card_MethodResponse) then
						continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then continue end
		end

		if friend:hasSkill("enyuan") and #cards >= 1 and not (self.room:getMode() == "04_1v3" and ((self.player:getHandcardNum() + 2 > self.player:getMaxCards()) or (self.player:isWounded() and self.player:getMark("SixRende") < 2))) then
			use.card=final_parse(self,request,"#SixRendeCard:" .. card:getKnownId() .. "+" .. cards[1]:getId() .. ":")
		else
			use.card=final_parse(self,request,"#SixRendeCard:" .. card:getKnownId() .. ":")
		end
		if use.to then use.to:append(friend) end
		return
	end

	if notFound then

		if self.player:getMark("SixRende") <= 1 or (self.player:getHandcardNum() + 2 < self.player:getMaxCards() and not self.player:isWounded()) or self:getOverflow() > 0 then
			local cards = AIList.new(self.player:getHandcards())
			self:sortByUseValueInPlace(cards, true)
			self:sortInPlace(self.friends_noself, "handcard")
			local give_all_cards = {}
			for _, c in ipairs(AIList.new(self.player:getCards("h"))) do
				table.insert(give_all_cards, c:getKnownEffectiveId())
			end
			local targets = {}
			for _, friend in ipairs(self.friends_noself) do
				if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
			if #targets > 0 and #give_all_cards > 1 then
				local card_str = string.format("#SixRendeCard:" .. give_all_cards[1] .. ":")
				local acard = parse(self,request,card_str)
				use.card = acard
				if use.to then
					use.to:append(targets[1])
				end
				return
			end
		end

		local pangtong = self.room:findPlayerBySkillName("manjuan")
		if not pangtong then pangtong = self.room:findPlayerBySkillName("zishu") end
		if not pangtong then return end
		local cards = AIList.new(self.player:getHandcards())
		self:sortByUseValueInPlace(cards, true)
		if ((self.player:getHandcardNum() + 2 > self.player:getMaxCards()) or (self.player:isWounded() and self.player:getMark("SixRende") < 2)) then
			self:sortByUseValueInPlace(cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
					table.insert(to_give, card:getKnownId())
				end
				if #to_give == 2 - self.player:getMark("SixRende") then break end
			end
			if #to_give > 0 then
				use.card=final_parse(self,request,"#SixRendeCard:" .. table.concat(to_give, "+") .. ":")
				if use.to then use.to:append(pangtong) end
			end
		end
	end
end

sgs.ai_use_value["SixRendeCard"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["SixRendeCard"] = sgs.ai_use_priority.RendeCard

ai_audited_aliases.register{id="ai_card_intention.SixRendeCard",registry="ai_card_intention",path={"SixRendeCard"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
sgs.dynamic_value.benefit["SixRendeCard"] = true

ai_skill_choice.SixRende = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if table.contains(items, "SixRendeRecover") then
		if self.player:getHp() < self:getBestHp(self.player) then
			return ai_choice_result(("SixRendeRecover"), options)
		end
	end

	if table.contains(items, "SixRendeDraw") then
		return ai_choice_result(("SixRendeDraw"), options)
	end

	return ai_choice_result(("SixRendeCancel"), options)
end

sgs.ai_use_revises.SixRende = function(self,card,use)
	if self.player:getLostHp()>1 and self:findFriendsByType(sgs.Friend_Draw) and self.player:getMark("SixRende") < 2 then
		if card:getTypeId()==1
		or card:getTypeId()==3 and self:getSameEquip(card)
		or card:getTypeId()==2 and not (card:targetFixed() and card:isDamageCard())
		then return false end
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|SixRende"

local SixPaoxiao_skill = {}
SixPaoxiao_skill.name = "SixPaoxiao"
table.insert(package_skills, SixPaoxiao_skill)

SixPaoxiao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self:slashIsAvailable() then return nil end
	if self.player:hasFlag("SixPaoxiaoForbidden") then return nil end
	if not self.player:canSlashWithoutCrossbow() then return nil end

	return parse(self,request,"#SixPaoxiaoCard:.:")
end

ai_card_use["#SixPaoxiaoCard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "defense")
	remember_player(self,"MingceTarget",nil)
	local slash = self:cloneEvaluationCard("slash")
	
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() then
			remember_player(self,"MingceTarget",enemy)
			break
		end
	end

	if recall_player(self,"MingceTarget") then
		use.card=final_parse(self,request,"#SixPaoxiaoCard:.:")
		if use.to then
			use.to:append(recall_player(self,"MingceTarget"))
		end
	end
end

function sgs.ai_cardneed.SixPaoxiao(to,card,self)
	return card:isKindOf("Crossbow")
end

sgs.ai_use_value["SixPaoxiaoCard"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["SixPaoxiaoCard"] = sgs.ai_use_priority.Slash + 1

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|SixLongdan"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|SixLongdan"

ai_skill_use["@@SixLongdan2"] = function(self, prompt, native_request)
	local data = prompt
	local method = native_request and native_request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")

	local card_str = ("slash:SixLongdan[%s:%s]=."):format("to_be_decided", 0)
	local use_card=parse(self,request,card_str)
	local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if self:getDefenseSlash(p) < 6 then
				table.insert(targets, p:objectName())
			end
		end
		if #targets > 0 then
			return use_card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
		end
	end

	return "."
end

ai_skill_use["@@SixLongdan1"] = function(self, prompt, request)
	local data = prompt
	local method = request and request.handling_method
	local target
	local use_card
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if scoped_flag(self,p,"SixLongdan_Target") then
			target = p
			break
		end
	end
	if target and self:isFriend(target) and self.player:getMark("SixLongdan_using") == 0 then
		local shouldUse = false

		local defense = 6
		local use = tag(self,"CurrentUseStruct"):toCardUse()

		local def = self:getDefense(target)
		local slash = use.card
		local eff = self:slashIsEffective(slash, target)
		if use.card and self:hasHeavyDamage(use.from, use.card, target) then
			shouldUse = true
		end
		if not use.from:canSlash(target, slash, false) then
		elseif self:slashProhibit(nil, target) then
		elseif eff then
			if target:getHp() == 1 and getCardsNum("Jink", target) == 0 then shouldUse = true end
			shouldUse = true
		end
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") and not self.player:isCardLimited(card, method) and card:isKindOf("BasicCard") then
				use_card = card
				break
			end
		end
		if use_card and self:isFriend(target) then
			self:updateIntention(self.player, target, -70)
			return "#SixLongdanCard:" .. use_card:getKnownEffectiveId() .. ":"
		end
	end
	return "."
end

local SixSance_skill = {}
SixSance_skill.name = "SixSance"
table.insert(package_skills, SixSance_skill)
SixSance_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#SixSanceCard") then
		return parse(self,request,"#SixSanceCard:.:")
	end
end

ai_card_use["#SixSanceCard"] = function(self, card, use, request)
	local target = nil
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		target = friend
	end
	if target then
		local handcards = AIList.new(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		self:sortByUseValueInPlace(handcards)
		for _, c in ipairs(handcards) do
			if not c:isKindOf("Peach")
				and not c:isKindOf("Duel")
				and not c:isKindOf("Indulgence")
				and not c:isKindOf("SupplyShortage")
				and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
				and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
			then
				if spade_check and c:getSuit() == sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif heart_check and c:getSuit() == sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif club_check and c:getSuit() == sgs.Card_Club then
					club_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				end
				if #discard_cards == 3 then
					break
				end
			end
		end

		if #discard_cards == 3 and target then
			local card_str = string.format("#SixSanceCard:%s:", table.concat(discard_cards, "+"))
			use.card=final_parse(self,request,card_str)
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_skill_askforag.SixSance = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	self:sortByCardNeed(to_obtain, true)
	if self:isWeak() then
		for card_id in ipairs(card_ids) do
			if disclosed(self,card_id):getSuit() == sgs.Card_Heart then
				return card_id
			end
		end
	end
	local target
	for _,friend in ipairs(self.friends_noself)do
		if friend:hasFlag("SixSance_from") then
			target = friend
			break
		end
	end
	if target and self:isWeak(target) then
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
	return card:getTypeId() == sgs.Card_TypeTrick
end

ai_skill_invoke.SixZhongyong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	local use = tag(self,"CurrentUseStruct"):toCardUse()
	if not self:isFriend(target) or self:isFriend(use.from) then return (false) or false end
	if use.card and use.card:isKindOf("Slash") then
		if target:hasSkills("liuli|tianxiang|ol_tianxiang") and target:getHandcardNum() > 1 then return (false) or false end
		if not self:slashIsEffective(use.card, target, use.from) then return (false) or false end
		if self:getCardsNum("Jink") > 0 then return (true) or false end
	end
	if self:needToLoseHp(target, use.from, use.card) then return (false) or false end
	if self.player:getHandcardNum() + self.player:getEquips():length() < 2 and not self:isWeak(target) then return (false) or false end

	if self:isWeak(target) and not self:isWeak() then return (true) or false end

	return (false) or false
end

ai_skill_use["@@SixChouyuan"] = function(self, prompt, request)
	local data = prompt
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if friend:getHp() <= 3 and friend:isWounded() and self:canDraw(friend, self.player) then
			return "#SixChouyuanCard:.:->" .. friend:objectName()
		end
	end
	self:sortInPlace(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() and (enemy:getHp() > 3 and not enemy:isKongcheng()) and self:doDisCard(enemy, "h") then
			return "#SixChouyuanCard:.:->" .. enemy:objectName()
		end
	end

	return "."
end

ai_skill_invoke.SixWujun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self.room:getCurrent()
	if target and self:isEnemy(target) then
		return (true) or false
	end

	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.SixWujun = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = self.room:getCurrent()
		self:updateIntention(player, current, 50)
	end
end

sgs.ai_skill_cardask["@SixWujun"] = function(self, data, pattern, target, target2)
	if target and self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then
		return "."
	end
	if not self.player:canSlash(target, false) then return "." end

	local use_card
	if not target:hasSkill("yizhong") and not target:hasArmorEffect("renwang_shield") and not target:hasArmorEffect("vine") then
		local cards = AIList.new(self.player:getHandcards())

		self:sortByKeepValueInPlace(cards)
		local slash = self:cloneEvaluationCard("slash")
		
		for _, card in ipairs(cards) do
			if self:getKeepValue(card, cards) <= self:getKeepValue(slash, cards) then
				local black_slash=owner_normal(self,"SixWujun","slash",{card:getKnownEffectiveId()},"")
				if self:slashIsEffective(black_slash, target) then
					use_card = card
					break
				end
			end
		end
	end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() == 1 then
		use_card = self.player:getHandcards():first()
	end
	if use_card then
		local black_slash=owner_normal(self,"SixWujun","slash",{use_card:getKnownEffectiveId()})
		return black_slash:getLegacyStringKey()
	end
	return "."
end

sgs.ai_target_revises.SixWujun = function(to, card, self)
	if card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse")
	then
		return true
	end
end

local SixWuzhi_skill = {}
SixWuzhi_skill.name = "SixWuzhi"
table.insert(package_skills, SixWuzhi_skill)
SixWuzhi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#SixWuzhiCard") then
		return parse(self,request,"#SixWuzhiCard:.:")
	end
end

ai_card_use["#SixWuzhiCard"] = function(self, card, use, request)
	local target = nil
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getJudgingArea():length() > 0 then
			for _, judge in sgs.qlist(friend:getJudgingArea()) do
				if not judge:isKindOf("YanxiaoCard") then
					target = friend
					break
				end
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getEquips():length() > 0 and friend:hasSkills(sgs.lose_equip_skill) then
				target = friend
				break
			end
		end
	end
	if not target then
		local handcards = AIList.new(self.player:getCards("h"))
		self:sortByUseValueInPlace(handcards)
		local cards = {}
		for _, c in ipairs(handcards) do
			if c:isKindOf("Slash") then
				table.insert(cards,c)
			end
		end
		if #cards > 0 then
			local c,to = self:getCardNeedPlayer(cards, false)
			if c and to then
				target = to
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getEquips():length() > 0 and not enemy:hasSkills(sgs.lose_equip_skill) then
				target = enemy
				break
			end
		end
	end
	if target then
		local handcards = AIList.new(self.player:getCards("h"))
		self:sortByUseValueInPlace(handcards)
		local use_card
		for _, c in ipairs(handcards) do
			if c:isKindOf("Slash") then
				use_card = c
			end
		end

		if use_card and target then
			use.card=final_parse(self,request,"#SixWuzhiCard:" .. use_card:getKnownEffectiveId() .. ":")
			if use.to then use.to:append(target) end
		end
	end
end

ai_skill_choice.SixWuzhi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "SixWuzhiGet") then
		if self:isFriend(target) then
			if self:doDisCard(target, "ej", true) then
				return ai_choice_result(("SixWuzhiGet"), options)
			end
		else
			return ai_choice_result(("SixWuzhiGet"), options)
		end
	end
	if table.contains(items, "SixWuzhiDiscard") then
		if self:isEnemy(target) and self:doDisCard(target, "h", false, 2) then
			return ai_choice_result(("SixWuzhiDiscard"), options)
		end
	end
	return ai_choice_result(("SixWuzhiCancel"), options)
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SixWuzhiCard",registry="ai_choicemade_filter",path={"cardChosen","SixWuzhiCard"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
function sgs.ai_cardneed.SixWuzhi(to, card, self)
	return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
end

ai_skill_invoke.SixHusi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local move = data:toMoveOneTime()
	if self.player:isLord() and self:isWeak() then return (false) or false end
	if move.from and self:isFriend(move.from) and move.to and not self:isFriend(move.to) then
		return (move.card_ids:length() >= 2 or self:isWeak(move.from)) or false
	end
	if move.from and move.from:objectName() == self.player:objectName() then return (not self:isWeak()) or false end

	return (false) or false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|SixToujing"

sgs.ai_skill_playerchosen.SixToujing = function(self, targets)
	local first, second
	targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) and friend:isAlive() and not (hasManjuanEffect(friend) and friend:getLostHp() == 0) then
			if friend:isLord() and self:isWeak(friend) then return friend end
			if not (friend:hasSkill("zhiji") and friend:getMark("zhiji") == 0 and not self:isWeak(friend) and friend:getPhase() == sgs.Player_NotActive) then
				if self:getRoleEstimate(friend) == "renegade" then
					second = friend
				elseif self:getRoleEstimate(friend) ~= "renegade" and not first then
					first = friend
				end
			end
		end
	end
	if first then return first end
	if second then return second end
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) then
			return friend
		end
	end
	return targets[1]
end

sgs.ai_use_revises.SixToujing = function(self,card,use)
	if card:isKindOf("FireAttack") then
		if self:getAllPeachNum() + self.player:getHp() == 1 and self.player:getHandcardNum() > 1 and self:hasTrickEffective(card, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Fire) and not self.player:isChained() then
			use.card = card
			use.to:append(self.player)
			return true
		end
	end
end

ai_skill_invoke.PlusYingwu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (not (self.player:hasSkill("yingzi") and self.player:hasSkill("yinghun"))) or false
end

sgs.ai_skill_cardask["@PlusYingwu"] = function(self, data, pattern, target, target2)
	local use_card
	local cards = AIList.new(self.player:getHandcards())
	if self:needToLoseHp() then return "." end

	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		use_card = card
		break
	end
	if self:needToThrowArmor() then use_card = self.player:getArmor() end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() == 1 then
		use_card = self.player:getHandcards():first()
	end
	if use_card then
		return use_card:getLegacyStringKey()
	end
	return "."
end

ai_skill_choice.PlusYingwu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if table.contains(items, "yinghun") then
		if self.player:getLostHp() > 2 then
			return ai_choice_result(("yinghun"), options)
		end
	end
	return ai_choice_result(("yingzi"), options)
end

ai_skill_invoke.SixLiangjie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self.player:wholeHandCards():isBlack() or self.player:wholeHandCards():isRed()) or false
end

ai_skill_invoke.SixLiangjieDraw = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_cardask["@SixZenhui"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		local use_card
		local cards = AIList.new(self.player:getHandcards())

		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade then
				use_card = card
				break
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if current:inMyAttackRange(friend) then
				if use_card then
					return use_card:getLegacyStringKey()
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen["SixZenhui"] = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and (not self:needKongcheng(p, true) or hasManjuanEffect(p)) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["SixZenhui"] = function(self, from, to)
	self:updateIntention(from, to, -30)
end

sgs.ai_skill_playerchosen.SixJiahuo = function(self, targets)
	for _,p in ipairs(self:findPlayerToDiscard("h", false, false, targets))do
		return p
	end
	return nil
end

ai_skill_invoke.SixJiahuoSecond = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

local SixChunlao_skill = {}
SixChunlao_skill.name = "SixChunlao"
table.insert(package_skills, SixChunlao_skill)
SixChunlao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() or self.player:getStrategyHasUsed("#SixChunlaoCard") then return nil end
	return parse(self,request,"#SixChunlaoCard:.:")
end

ai_card_use["#SixChunlaoCard"] = function(self, card, use, request)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	self:sortInPlace(self.enemies, "defense")

	self:setPriorityValue("#SixChunlaoCard",0.2)
	local suit_table = { "spade", "club", "heart", "diamond" }
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 then
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
					if sgs[skill:objectName() .. "_suit_value"] then
						for i = 1, 4, 1 do
							local v = sgs[skill:objectName() .. "_suit_value"][suit_table[i]]
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
				if self:getUseValue(card) < 6 and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
					use.card=final_parse(self,request,"#SixChunlaoCard:" .. card:getKnownEffectiveId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
			if getCardsNum("Peach", enemy, self.player) < 2 then
				for _, card in ipairs(cards) do
					if self:getUseValue(card) < 6 and not self:isValuableCard(card) and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
						use.card=final_parse(self,request,"#SixChunlaoCard:" .. card:getKnownEffectiveId() .. ":")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
			if self:getOverflow() > 0 then
				for _, card in ipairs(cards) do
					use.card=final_parse(self,request,"#SixChunlaoCard:" .. card:getKnownEffectiveId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention["#SixChunlaoCard"] = function(self, card, from, tos)
	local to = tos[1]
	self:updateIntention(from, to, 60)
end

sgs.ai_use_priority["#SixChunlaoCard"] = 0.2

function sgs.ai_cardsview_valuable.SixChunlao(self, class_name, player)
	if class_name == "Peach" and player:getPile("beer"):length() > 0 then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if dying then
			local analeptic = self:cloneEvaluationCard("analeptic")
			
			if dying:isLocked(analeptic) then return nil end

			local give_card = {}
			for _, card_id in sgs.qlist(self.player:getPile("beer")) do
				table.insert(give_card, disclosed(self,card_id))
			end
			self:sortByKeepValueInPlace(give_card)

			local diamond_cards = {}
			local heart_cards = {}
			local spade_cards = {}
			local club_cards = {}
			local use_cards = {}

			for _, c in ipairs(give_card) do
				if c:getSuit() == sgs.Card_Diamond then
					table.insert(diamond_cards, c:getKnownEffectiveId())
				elseif c:getSuit() == sgs.Card_Heart then
					table.insert(heart_cards, c:getKnownEffectiveId())
				elseif c:getSuit() == sgs.Card_Spade then
					table.insert(spade_cards, c:getKnownEffectiveId())
				elseif c:getSuit() == sgs.Card_Club then
					table.insert(club_cards, c:getKnownEffectiveId())
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

ai_skill_invoke.SevenMizhao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (sgs.ai_skill_playerchosen.SevenMizhao(self, self.room:getOtherPlayers(self.player)) ~= nil) or false
end

sgs.ai_skill_playerchosen.SevenMizhao = function(self, targets)
	if (ai_skill_invoke.fangquan(self, {}, nil) or self:needKongcheng(self.player)) then
		local cards = AIList.new(self.player:getHandcards())
		self:sortByKeepValueInPlace(cards)
		if role_count(self,"rebel") == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() and not hasManjuanEffect(lord) then
				return lord
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and not hasManjuanEffect(AssistTarget) then
			return AssistTarget
		end

		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and friend:hasSkills(sgs.cardneed_skill) then
				return friend
			end
		end

		self:sortInPlace(self.friends_noself, "chaofeng")
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
            self:updateIntention(player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = player:getRoom():getOtherPlayers(get_jiujia(self))
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end

sgs.ai_skill_cardask["SevenJiujiajink"] = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return "." end
	return self:getCardId("Jink") or "."
end

sgs.ai_choicemade_filter.cardResponded["SevenJiujiaslash"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            self:updateIntention(player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = player:getRoom():getOtherPlayers(get_jiujia(self))
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end
sgs.ai_skill_cardask["SevenJiujiaslash"] = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return "." end
	return self:getCardId("Slash") or "."
end

sgs.ai_choicemade_filter.cardResponded["SevenJiujiapeach"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            self:updateIntention(player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = player:getRoom():getOtherPlayers(get_jiujia(self))
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end

sgs.ai_skill_cardask["SevenJiujiapeach"] = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return "." end
	return self:getCardId("Peach") or "."
end

sgs.ai_choicemade_filter.skillInvoke.SevenJiujia = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        set_jiujia(self,player)
    end
end

ai_skill_invoke["SevenJiujia"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

function sgs.ai_slash_prohibit.SevenJiujia(self, from, to, card)
    if self:isFriend(to) then
        return false
    end
    if self:canLiegong(to, from) then
        return false
    end
    local players = AIList.new(self.room:getOtherPlayers(to))
    for _, player in ipairs(players) do
        if self:isFriend(player, to) then
            if player:hasSkill("tiandu") and sgs.ai_slash_prohibit.tiandu(self, from, player, card) then
                return true
            end
            if player:hasLordSkill("hujia") and sgs.ai_slash_prohibit.hujia(self, from, player, card) then
                return true
            end
            if player:hasSkill("leiji") and sgs.ai_slash_prohibit.leiji(self, from, player, card) then
                return true
            end
            if player:hasSkill("weidi") and sgs.ai_slash_prohibit.weidi(self, from, player, card) then
                return true
            end
        end
    end
    return false
end

sgs.ai_skill_cardask["@@SevenJiujia"] = function(self, data, pattern)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
        local cards = self.player:getCards("he")
        cards = AIList.new(cards)
        self:sortByKeepValueInPlace(cards)
        for _,h in sgs.list(cards)do
            if self:matchesDiscardPattern(pattern, h)
            then return h:getKnownEffectiveId() end
            if h:isKindOf(pattern)
            then return h:getKnownEffectiveId() end
        end
        return self:getCardId(pattern)
        
    end
    return "."
end

sgs.ai_choicemade_filter.cardResponded["@@SevenJiujia"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if get_jiujia(self) then
            self:updateIntention(player, get_jiujia(self), -80)
		    set_jiujia(self,nil)
        end
    elseif get_jiujia(self) then
        local lieges = player:getRoom():getOtherPlayers(get_jiujia(self))
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                set_jiujia(self,nil)
            end
        end
    end
end

sgs.ai_cardsview_valuable.SevenJiujia = function(self, class_name, player)
	local handcards = AIList.new(self.player:getCards("h"))
    local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
		["Peach"] = "peach",
	}
	local name = classname2objectname[class_name]
    if not name then return end
	local had_card = nil
	for _, c in ipairs(handcards) do
		if c:isKindOf(name) then
			had_card = c
            break
		end
	end
	if class_name == "Peach" and self.request.reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end

	if name and not player:hasFlag("Global_SevenJiujiaFailed") and had_card == nil and player:getPhase() == sgs.Player_NotActive  then
		return string.format("#SevenJiujiaCard:.:%s", name)
	end
end

local SevenJiujia_filter = function(self,player,carduse)
	if carduse.card:isKindOf("SevenJiujiaCard") then
		set_jiujia(self,player)
	end
end
table.insert(sgs.ai_choicemade_filter.cardUsed,SevenJiujia_filter)

local SixMiBian_skill = {}
SixMiBian_skill.name = "SixMiBian"
table.insert(package_skills, SixMiBian_skill)
SixMiBian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#SixMiBian") then
		return parse(self,request,"#SixMiBian:.:")
	end
end

ai_card_use["#SixMiBian"] = function(self, card, use, request)
	local target = nil
	self:updatePlayers()
	self:sortInPlace(self.enemies, "handcard")
	local max = 0
	local slash = self:cloneEvaluationCard("slash")
	
	for _, enemy in ipairs(self.enemies) do
		local x = 0
		if self.player:inMyAttackRange(enemy) then
			for _, friend in ipairs(self.friends) do
				if friend:inMyAttackRange(enemy) then
					if not friend:isKongcheng() and not self:slashProhibit(slash, enemy, friend)
						and self:slashIsEffective(slash, enemy, friend) and self:isGoodTarget(enemy, self.enemies, slash) then
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

	local handcards = AIList.new(self.player:getCards("h"))
	local discard_cards = {}
	local spade_check = true
	local heart_check = true
	local club_check = true
	local diamond_check = true

	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
		then
			if spade_check and c:getSuit() == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif heart_check and c:getSuit() == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif club_check and c:getSuit() == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			end
		end
	end
	if #discard_cards > 0 then
		use.card=final_parse(self,request,string.format("#SixMiBian:%s:", table.concat(discard_cards, "+")))
		if use.to then use.to:append(target) end
	end
end

sgs.ai_skill_cardask["@SixMiBian"] = function(self, data, pattern, target)
	local dest = data:toPlayer()
	local slash = self:cloneEvaluationCard("slash")
	
	if dest and not self:slashProhibit(slash, dest, self.player) and self:isEnemy(dest) and self:slashIsEffective(slash, dest, self.player) and self:isGoodTarget(dest, self.enemies, slash) then
		local cards = AIList.new(self.player:getCards("h"))
		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if string.find(pattern, card:getSuitString()) then
				return card:getLegacyStringKey()
			end
		end
	end
	return "."
end

ai_skill_invoke["SixJianCe"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	local max_card = self:getMaxCard()

	if target and self:isEnemy(target) and max_card then
		local max_point = max_card:getNumber()
		local enemy_max_card = self:getMaxCard(target)
		if (enemy_max_card and max_point > enemy_max_card:getNumber())
			or (enemy_max_card and max_point > enemy_max_card:getNumber() and max_point > 10)
			or (not enemy_max_card and max_point > 10) then
			if self.player:getHandcardNum() > target:getHandcardNum() then
				self:remember("SixJianCe_card", max_card:getKnownEffectiveId())
				return (true) or false
			end
		end
	end
	return (false) or false
end

sgs.ai_skill_discard.SixJianCe = function(self, discard_num, optional, include_equip)
	local cards = AIList.new(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, card:getKnownId())
	end

	return to_discard
end

ai_audited_aliases.register{id="ai_cardneed.SixJianCe",registry="ai_cardneed",path={"SixJianCe"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
function sgs.ai_skill_pindian.SixJianCe(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and minusecard or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.SixShouLue",registry="ai_cardneed",path={"SixShouLue"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
ai_skill_invoke["SixYangShi"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_invoke["SevenRenDe"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:isWounded() or self:isWeak() or self.player:getHandcardNum() < 3 then
		return (true) or false
	end

	if #self.friends_noself >= #self.enemies then
		return (true) or false
	end

	return (false) or false
end

sgs.ai_skill_cardask["@SevenRenDe"] = function(self, data, pattern, target, target2)
	local target = data:toPlayer()
	local usable_cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(usable_cards)

	if target then
		if self:isFriend(target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:getLegacyStringKey()
		else
			return usable_cards[1]:getLegacyStringKey()
		end
	end
	return "."
end

function ai_skill_invoke.SevenJuDi(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_use["@@SevenJuDi"] = function(self, prompt, request)
	local enemynum = 0
	for _, enemy in ipairs(self.enemies) do
		if (not self:needKongcheng(enemy) and self:hasLoseHandcardEffective(enemy)) or self:getDangerousCard(enemy) or self:getValuableCard(enemy) then
			enemynum = enemynum + 1
		end
	end

	if enemynum == 0 then
		return "."
	end
	self:sortInPlace(self.enemies, "defense")

	local first_index, second_index, third_index
	for i = 1, #self.enemies do
		if ((not self:needKongcheng(self.enemies[i]) and self:hasLoseHandcardEffective(self.enemies[i]))
				or self:getDangerousCard(self.enemies[i]) or self:getValuableCard(self.enemies[i])) and not self.enemies[i]:isNude() and
			not (self.enemies[i]:hasSkill("guzheng") and self.room:getCurrent():getPhase() == sgs.Player_Discard) then
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

function ai_skill_invoke.SevenKanLuan(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local discard_num = self.player:getHandcardNum() - self.player:getHp()
	if discard_num >= 3 then
		return (false) or false
	end
	local cardstr = source_uses["@@SevenKanLuan"](self, "@SevenKanLuan")
	if cardstr:match("->") then
		return (true) or false
	end
	return (false) or false
end

ai_skill_use["@@SevenKanLuan"] = function(self, prompt, request)
	local method = request and request.handling_method
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	local discard_num = self.player:getHandcardNum() - self.player:getHp()
	local discard_table = self:askForDiscard("dummyreason", discard_num, discard_num, false, true)

	local slash = self:cloneEvaluationCard("slash")

	local dummy_use = self:aiUseCard(slash, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
	end
	if #targets > 0 then
		return "#SevenKanLuan:" .. table.concat(discard_table, "+") .. ":->" .. targets[1]
	end
	return "."
end

sgs.ai_cardneed.SevenKanLuan = function(to,card)
	return to:getHandcardNum() < to:getHp()
end

sgs.ai_skill_discard.SevenZhenShi = function(self, discard_num, optional, include_equip)
	local cards = AIList.new(self.player:getHandcards())
	local target
	for _,p in sgs.list(AIList.new(self.room:getOtherPlayers(self.player)))do
		if p:hasFlag("SevenZhenShi") then
			target = p
            break
		end
	end
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	local n = 2
	if target and self:isFriend(target) then n = self:getOverflow() end
	for _, card in ipairs(cards) do
		if #to_discard >= n then break end
		table.insert(to_discard, card:getKnownId())
	end

	return to_discard
end

sgs.ai_skill_playerchosen["SevenZhenShi"] = function(self, targets)
	local targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getHandcardNum() <= 1 and not self:needKongcheng(p, true) and not hasManjuanEffect(p) and self:canDraw(p, self.player) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and not hasManjuanEffect(p) and self:canDraw(p, self.player) then
			return p
		end
	end
	if self:isWeak() then
		return targets[1]
	end
	return nil
end

sgs.ai_playerchosen_intention["SevenZhenShi"] = -40

local SevenZhaoXiang_skill = {}
SevenZhaoXiang_skill.name = "SevenZhaoXiang"
table.insert(package_skills, SevenZhaoXiang_skill)
SevenZhaoXiang_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#SevenZhaoXiang") then
		return parse(self,request,"#SevenZhaoXiang:.:")
	end
end

ai_card_use["#SevenZhaoXiang"] = function(self, card, use, request)
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "defense")
	local target = nil
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > 0 and self:hasSkills(sgs.lose_equip_skill, friend) then
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if self:doDisCard(friend, "e", true) then
				target = friend
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getEquips():length() > 0 then
				target = friend
			end
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["SevenZhaoXiang"] = 7
sgs.ai_use_value["SevenZhaoXiang"] = 7
sgs.ai_card_intention["SevenZhaoXiang"] = -40

sgs.ai_can_damagehp.SevenTaoHui = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
end

function ai_skill_invoke.SevenTaoHui(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (self.room:getTurnCount() <= 1 and self:getRoleEstimate(sbdiaochan) == "neutral")) then
		return (false) or false
	end
	if not self.player:faceUp() then return (true) or false end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return (true) or false end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return (true) or false
		end
	end
	local current = self.room:getCurrent()
	return (self:isWeak() or
		not (current:getNextAlive():objectName() == self.player:objectName() and self.player:faceUp())) or false
end

function ai_skill_invoke.SevenLangMou(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_cardask["@SevenQuanBian-card"] = function(self, data)
	local judge = data:toJudge()

	if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = AIList.new(self.player:getHandcards())
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, disclosed(self,id))
			end
		end
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end

function sgs.ai_cardneed.SevenQuanBian(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
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

function ai_skill_invoke.SevenQuanBian(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local card = data:toCard()
	self:sortInPlace(self.friends, "hp")
	self:sortInPlace(self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (friend:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			if friend:isWounded() then up = up + 5 end
		end
		if self:needToLoseHp(friend, nil, nil, true) then down = down + 5 end
		if self:needToLoseHp(friend, nil, nil, true, true) and friend:isWounded() then up = up - 5 end

		if self:isWeak(friend) then
			if friend:isWounded() then up = up + 10 + (friend:isLord() and 20 or 0) end
			down = down - 10 - (friend:isLord() and 40 or 0)
			if friend:getHp() <= 1 and not friend:hasSkill("buqu") or friend:getPile("trauma"):length() > 4 then
				down = down - 20 - (friend:isLord() and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (enemy:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then
			down = down + 10
			if enemy:isWounded() then up = up - 10 end
		end
		if self:needToLoseHp(enemy, nil, nil, true) then down = down - 5 end
		if self:needToLoseHp(enemy, nil, nil, true, true) and enemy:isWounded() then up = up - 5 end

		if self:isWeak(enemy) then
			if enemy:isWounded() then up = up - 10 end
			down = down + 10
			if enemy:getHp() <= 1 and not enemy:hasSkill("buqu") then
				down = down + 10 + ((enemy:isLord() and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 and card:isBlack() then
		return (true) or false
	elseif up > 0 and card:isRed() then
		return (true) or false
	end
	return (false) or false
end

ai_skill_invoke.SevenChuaiYi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage and damage.from and self:isEnemy(damage.from) then
		return (true) or false
	end
	return (not self:needToLoseHp(damage.to, damage.from, damage.card)) or false
end

sgs.ai_skill_cardask["@SevenChuaiYi-show"] = function(self, data)
	local damage = data:toDamage()
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if damage.from and self.player:objectName() == damage.from:objectName() then
		if self:isEnemy(damage.to) then
			for _, card in ipairs(cards) do
				if getKnownCard(damage.to, self.player, card:getSuitString(), false, "h") > 0 then
					return "$" .. card:getKnownEffectiveId()
				end
			end
		elseif self:isFriend(damage.to) and not self:needToLoseHp(damage.to, self.player, damage.card) then
			for _, card in ipairs(cards) do
				if getKnownCard(damage.to, self.player, card:getSuitString(), false, "h") == 0 then
					return "$" .. card:getKnownEffectiveId()
				end
			end
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_ajustdamage_to.SevenChuaiYi = function(self, from, to, card, nature)
	if not to:isKongcheng()
	then
		if self:isFriend(to, from)
		then
			return -1
		else
			if from:objectName() ~= self.player:objectName()
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

ai_skill_invoke.SevenZhiDi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		if self:isEnemy(target) then
			return (true) or false
		end
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.SevenZhiDi = function(self, player, promptlist)
	if #promptlist == "yes" then
		local lord = self.room:getCurrent()
		if lord then
			self:updateIntention(player, lord, 60)
		end
	end
end

ai_skill_choice["SevenZhiDi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	self:updatePlayers()
	local who = data:toPlayer()
	local handcards = AIList.new(who:getHandcards())
	local items = choices:split("+")
	for _, c in ipairs(handcards) do
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), who:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if table.contains(items, c:objectName()) then
				return ai_choice_result((c), options)
			end
		end
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end

function sgs.ai_cardsview_valuable.SevenWeiYuan(self, class_name, player)
	local dying = self.room:getCurrentDyingPlayer()
	if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return end
	if dying:isLord() and self:isFriend(dying, player) then return "#SevenWeiYuan:.:" end

		local cards = player:getCards("he")
		cards = AIList.new(cards)
		for _, fcard in ipairs(cards) do
			if fcard:isKindOf("EquipCard") then
				return "#SevenWeiYuan:" .. fcard:getKnownEffectiveId() .. ":"
			end
		end
	if player:getHp() >= 2 or getCardsNum("Analeptic", player, self.player) > 0
	then
		return "#SevenWeiYuan:.:"
	end
end

ai_audited_aliases.register{id="ai_card_intention.SevenWeiYuan",registry="ai_card_intention",path={"SevenWeiYuan"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_cardneed.SevenWeiYuan",registry="ai_cardneed",path={"SevenWeiYuan"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.save_skill = sgs.save_skill .. "|SevenWeiYuan"

ai_skill_choice["SevenJuGong"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if self:getCardsNum("Peach") > 0 then
		return ai_choice_result(("loseHp"), options)
	end
	if self:getAllPeachNum() < 1 then
		return ai_choice_result(("discard"), options)
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end

local SevenFenLiang_skill = {}
SevenFenLiang_skill.name = "SevenFenLiang"
table.insert(package_skills, SevenFenLiang_skill)
SevenFenLiang_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#SevenFenLiang") or self.player:getMark("@SevenFenLiang") < 1 then return end
	if #self.enemies == 0 then return end

	return parse(self,request,"#SevenFenLiang:.:")
end

ai_card_use["#SevenFenLiang"] = function(self, wuqiancard, use, native_request)
	self:sortInPlace(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target
	for _, enemy in ipairs(self.enemies) do
		if self.player:getCardCount() >= self.player:distanceTo(enemy) and self.player:distanceTo(enemy) < enemy:getHandcardNum() and self:doDisCard(enemy, "h") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil)  then
			target = enemy
			break
		end
	end
	if target then
		use.card=final_parse(self,request,"#SevenFenLiang:.:")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["#SevenFenLiang"] = 5
sgs.ai_use_priority["#SevenFenLiang"] = 10
sgs.ai_card_intention["#SevenFenLiang"] = 80

ai_skill_invoke.SevenPingPan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

-- Fixed donor tests #promptlist (integer) against the string "yes".
-- No role-row mutation is reachable for the dense public prompt DTO.
sgs.ai_choicemade_filter.skillInvoke.SevenPingPan = function(self,player,promptlist)
 if #promptlist == "yes" then error("invalid source length primitive",0)end
end

ai_skill_invoke.SevenHuBei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_cardask["@SevenHuBei"] = function(self, data)
	local to_discard = self:askForDiscard("dummyreason", 1, 1, false, true, ".")
	if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

ai_audited_aliases.register{id="ai_cardneed.SevenXiaoRui",registry="ai_cardneed",path={"SevenXiaoRui"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
ai_skill_use["@@SevenYingYong"] = function(self, prompt, request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	local duel = self:cloneEvaluationCard("duel")
	
	local d = self:aiUseCard(duel)
	if d.card then
		dc = {}
		for _,p in sgs.list(d.to)do
			table.insert(dc,p:objectName())
		end
		return "#SevenYingYong:.:->" .. table.concat(dc,"+")
	end

	for _, enemy in ipairs(self.enemies) do
		local eff = self:hasTrickEffective(duel, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, duel)
		if self.player:isProhibited(enemy, duel) then
		elseif eff then
			return "#SevenYingYong:.:->" .. enemy:objectName()
		else
			return "."
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefense(enemy)
		local eff = self:hasTrickEffective(duel, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, duel)

		if self.player:isProhibited(enemy, duel) then
		elseif eff and def < 8 then
			return "#SevenYingYong:.:->" .. enemy:objectName()
		else
			return "."
		end
	end
	return "."
end

sgs.ai_skill_cardask["@SevenFuTui"] = function(self, data)
	local current = self.room:getCurrent()
	local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
	if #to_discard > 0 and current and self:isEnemy(current) and not current:hasFlag("Global_PlayPhaseTerminated") then
		return
			"$" .. to_discard[1]
	else
		return "."
	end
end

sgs.ai_choicemade_filter.cardResponded["@SevenFuTui"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, 80)
	end
end

ai_skill_invoke.SevenYiZe = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.SevenYiZe = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > 0 and (self:hasSkills(sgs.lose_equip_skill, friend) or self:doDisCard(friend, "e")) then
			return friend
		end
	end
	
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > 0 then
			if (self:doDisCard(enemy, "e")) then
				return enemy
			end
		end
	end
end

ai_skill_choice.SevenZhengBian = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	if self:isFriend(target) then return ai_choice_result(("SevenZhengBian_equip"), options) end
	if self:isEnemy(target) and self:doDisCard(target, "e", true) then return ai_choice_result(("SevenZhengBian_equip"), options) end
	return ai_choice_result(("SevenZhengBian_limit"), options)
end

local SevenZhengBian_skill = {}
SevenZhengBian_skill.name = "SevenZhengBian"
table.insert(package_skills, SevenZhengBian_skill)
SevenZhengBian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#SevenZhengBian") then return end
	return parse(self,request,"#SevenZhengBian:.:")
end
ai_card_use["#SevenZhengBian"] = function(self, card, use, request)
	local player = self.player
	local room = player:getRoom()
	local cards = AIList.new(player:getCards("he"))
	for _, card in ipairs(cards) do
		if not card:isKindOf("EquipCard") then table.removeOne(cards, card) end
	end
	self:sortByKeepValueInPlace(cards, false)
	local players = AIList.new(room:getAlivePlayers())
	local targets, friends, enemies = {}, {}, {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isKongcheng() then
			table.insert(targets, p)
			if self:isFriend(p) then
				table.insert(friends, p)
			elseif self:isEnemy(p) and self:doDisCard(p, "e", true) then
				table.insert(enemies, p)
			end
		end
	end

	if #targets == 0 then return end
	local target

	if not target then
		for _, enemy in ipairs(enemies) do
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _, enemy in ipairs(enemies) do
			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) or friend:hasArmorEffect("silver_lion") or friend:hasSkill("yqijiang") then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(enemies) do
			if self:hasSkills(sgs.concentrated_skill, enemy) and self:doDisCard(enemy, "e") then
				if enemy:getDefensiveHorse() then
					target = enemy
					break
				end
				if not target then
					if enemy:getArmor() and not self:needToThrowArmor(enemy) then
						target = enemy
						break
					end
				end
			end
		end
	end
	if not target and self:getCardsNum("Slash") > 0 then
		local slash = self:getCard("Slash")
		assert(slash)

		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
			for _, p in sgs.qlist(dummy_use.to) do
				if not self:canHit(p, self.player) or (p:getHp() <= 1 and self:getAllPeachNum(p) > 0) then
					target = p
					break
				end
			end
		end
	end

	local cards = AIList.new(player:getCards("he"))
	self:sortByUseValueInPlace(cards, true)
	local subcard
	for _, acard in ipairs(cards) do
		if acard:isKindOf("EquipCard") then
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
	use.card=final_parse(self,request,"#SevenZhengBian:"..subcard:getKnownEffectiveId()..":")
	self:sortInPlace(targets, "handcard")
	if use.to then use.to:append(target) end
end

sgs.ai_use_value["SevenZhengBian"] = 9
sgs.ai_use_priority["SevenZhengBian"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["SevenZhengBian"] = sgs.ai_card_intention.Dismantlement

ai_audited_aliases.register{id="ai_cardneed.SevenZhengBian",registry="ai_cardneed",path={"SevenZhengBian"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.ai_skill_cardask["@SevenQuGao-discard"] = function(self, data)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		if use.card and use.card:isKindOf("IronChain") then
			return "."
		end
		local shouldUse = false
		local dummy_use = self:aiUseCard(use.card, dummy())
		if dummy_use.card then shouldUse = true end

		local card_id
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)
		for _, hcard in ipairs(hcards) do
			if self.player:canDiscard(self.player, hcard:getKnownId()) and hcard:getSuitString() == use.card:getSuitString() and self:getUseValue(hcard) < self:getUseValue(use.card) then
				card_id = hcard:getKnownEffectiveId()
				break
			end
		end

		if shouldUse and card_id then
			return "$" .. card_id
		end
	elseif self:isFriend(use.to:first()) then
		if not use.from or use.from:isDead() then return "cancel" end
		if self.role == "rebel" and self:getRoleEstimate(use.from) == "rebel" and not self:hasJueqingEffect(use.from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()])
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return "."
		end
		local card_id
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)
		for _, hcard in ipairs(hcards) do
			if self.player:canDiscard(self.player, hcard:getKnownId()) and hcard:getSuitString() == use.card:getSuitString() and self:getUseValue(hcard) < self:getUseValue(use.card) then
				card_id = hcard:getKnownEffectiveId()
				break
			end
		end
		if card_id then
			if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not self:hasJueqingEffect(use.from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1) then
				if use.card:isKindOf("AOE") then
					local from = use.from
					if use.card:isKindOf("SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
						if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
						if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
					end
					friend_null = friend_null + self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

					if self:hasTrickEffective(use.card, self.player, from) then
						if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
							if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
								return
									"$" .. card_id
							end
							if sj_num == 0 and friend_null <= 0 then
								if self:isEnemy(from) and self:hasJueqingEffect(from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()]) then
									return
										"$" .. card_id
								end
								if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not self:hasJueqingEffect(from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()]) then
									return
										"$" .. card_id
								end
								if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or self:hasJueqingEffect(from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()])) then
									return "$" .. card_id
								end
							end
						end
					end
				elseif self:isEnemy(use.from) then
					if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
						if self:hasTrickEffective(use.card, self.player) then
							if self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then
								if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and use.from:getHandcardNum() > 3
									and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
									return "$" .. card_id
								elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
									return "$" .. card_id
								end
							end
						end
					elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
						and not self.player:isKongcheng() then
						if self:hasTrickEffective(use.card, self.player) then
							return "$" .. card_id
						end
					elseif use.card:isKindOf("Duel") then
						if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
							if self:hasTrickEffective(use.card, self.player) then
								if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
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

ai_skill_choice.SevenQuGao = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local use = data:toCardUse()
	local items = choices:split("+")
	if self:isFriend(use.from) then
		return ai_choice_result(("SevenQuGao_double"), options)
	elseif self:isFriend(use.to:first()) then
		return ai_choice_result(("SevenQuGao_invalid"), options)
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end

ai_skill_choice.SevenBaChao = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self.player:getMaxHp() >= self.player:getHp() + 2 then
		if self.player:getMaxHp() > 5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num + 1 end
			end
			local ls = self:getStrategyMemory("fangquan_effect") and self.room:findPlayerBySkillName("fangquan")
			if ls then
				self:setStrategyMemory("fangquan_effect", false)
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = self.player:isLord() and math.max(2, enemy_num - 1) or 1
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() > least_hp) then
				return
				ai_choice_result(("hp"), options)
			end
		end
		return ai_choice_result(("maxhp"), options)
	else
		return ai_choice_result(("hp"), options)
	end

    return ai_choice_result(nil, options)
end

sgs.bad_skills = sgs.bad_skills .. "|SevenBaChao"

local SevenLuanZheng_skill = {}
SevenLuanZheng_skill.name = "SevenLuanZheng"
table.insert(package_skills, SevenLuanZheng_skill)
SevenLuanZheng_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#SevenLuanZheng") then return end
	return parse(self,request,"#SevenLuanZheng:.:")
end

ai_card_use["#SevenLuanZheng"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_skill_cardask["@SevenJieMing"] = function(self, data)
	local target = data:toDamage().to
	if self:isFriend(target) then return "." end
	local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
	if #to_discard > 0 then
		return "$" .. to_discard[1]
	else
		return "."
	end
end

sgs.ai_ajustdamage_to.SevenJieMing = function(self, from, to, card, nature)
	if from and (from:isKongcheng() or self:beFriend(to, from))
	then
		return -1
	end
end

ai_skill_invoke.SevenTaDao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.SevenTaDao = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, "N", targets)[1]
	return target
end
ai_skill_invoke.SevenMiDao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

local SevenChuanJiao_skill = {}
SevenChuanJiao_skill.name = "SevenChuanJiao"
table.insert(package_skills, SevenChuanJiao_skill)
SevenChuanJiao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#SevenChuanJiao") then return end
	return parse(self,request,"#SevenChuanJiao:.:")
end

ai_card_use["#SevenChuanJiao"] = function(self, card, use, request)
	use.card = card
end

ai_skill_choice.SevenChuanJiao = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local red_friend = 0
	local black_friend = 0
	local red_enemy = 0
	local black_enemy = 0

	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("SevenChuanJiaored") then
			if self:isFriend(p) then
				red_friend = red_friend + 1
			elseif self:isEnemy(p) then
				red_enemy = red_enemy + 1
			end
		elseif p:hasFlag("SevenChuanJiaoblack") then
			if self:isFriend(p) then
				black_friend = black_friend + 1
			elseif self:isEnemy(p) then
				black_enemy = black_enemy + 1
			end
		end
	end
	local x = red_friend - red_enemy
	local y = black_friend - black_enemy
	if x > y then
		return ai_choice_result(("red"), options)
	else
		return ai_choice_result(("black"), options)
	end

	return ai_choice_result((items[math.random(1, #items)]), options)
end

local SevenFengPing_skill = {}
SevenFengPing_skill.name = "SevenFengPing"
table.insert(package_skills, SevenFengPing_skill)
SevenFengPing_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#SevenFengPing") then
		return parse(self,request,"#SevenFengPing:.:")
	end
end

ai_card_use["#SevenFengPing"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			use.card=final_parse(self,request,"#SevenFengPing:.:")
			if use.to then
				use.to:append(enemy)
			end
		end
		return
	end
end

sgs.ai_use_value.SevenFengPing = 2.5
sgs.ai_card_intention.SevenFengPing = 0

ai_skill_choice.SevenFengPing = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then return ai_choice_result(("red"), options) end
	if self:isEnemy(target) then return ai_choice_result(("black"), options) end

	return ai_choice_result((items[math.random(1, #items)]), options)
end

sgs.ai_choicemade_filter.skillChoice["SevenFengPing"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target = tag(self,"SevenFengPing"):toPlayer()
	if choice == "red" then
		self:updateIntention(player, target, -80)
	else
		self:updateIntention(player, target, 80)
	end
end

sgs.ai_skill_cardask["@SevenFengPing"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	if self:isFriend(target) then return "." end
	local card_id
	local hcards = self.player:getCards("h")
	hcards = AIList.new(hcards)
	self:sortByUseValueInPlace(hcards, true)
	local types = pattern:split("|")[2]
	for _, hcard in ipairs(hcards) do
		if self.player:canDiscard(self.player, hcard:getKnownId()) and hcard:getColorString() == types then
			card_id = hcard:getKnownEffectiveId()
			break
		end
	end
	if card_id then
		return "$" .. card_id
	end

	return "."
end
ai_skill_invoke.SevenYueDan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local ids = tag(self,"SevenFengPing"):toString():split("+") or {}
	if #ids == 0 then return (false) or false end
	local x = 0
	for _, id in pairs(ids) do
		if disclosed(self,id):isKindOf("BasicCard") and self.room:getCardPlace(tonumber(id)) == sgs.Player_DiscardPile then
			x = x + 1
		end
	end
	if x >= 3 then
		return (true) or false
	end
	return (false) or false
end

for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end

local response_use_keys={["@@SevenJuDi"]=true,["@@SevenKanLuan"]=true,["@@SevenYingYong"]=true,["@@SixChouyuan"]=true,["@@SixGuicai2"]=true,["@@SixLongdan1"]=true,["@@SixLongdan2"]=true,["@@SixMingduan"]=true,["@@SixWulveOthers!"]=true,["@@SixZhidi"]=true,["@PlusCuorui"]=true,["@PlusFuzheng"]=true,["@PlusGuicai2"]=true,["@PlusGuidao2"]=true,["@PlusJiahuo"]=true,["@PlusJiangcai"]=true,["@PlusJianxiong"]=true,["@PlusKuangjun"]=true,["@PlusLeiji"]=true,["@PlusLiangyuan"]=true,["@PlusLiuli"]=true,["@PlusLuoyi"]=true,["@PlusShensu1"]=true,["@PlusShensu2"]=true,["@PlusTianxiang"]=true,["@PlusYiji"]=true,["@PlusYizhong"]=true,["@PlusYuanmou"]=true,["@PlusZhongyong"]=true,["@SixTaohui"]=true}
for key in pairs(response_use_keys)do local source=ai_skill_use[key];source_uses[key]=source
 ai_skill_use[key]=function(self, prompt, request)
  local wire=source(self,prompt, request);if wire==nil or wire=='.'or type(wire)~='string'then return wire end
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
 if #costs~=1 or costs[1]~=card:getKnownEffectiveId()then ai_unsupported('view-as material differs from supplied owner card','biaofeng.view_as')end
 return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards=costs}
end end
do local source=sgs.ai_view_as["PlusWusheng"];sgs.ai_view_as["PlusWusheng"]=function(card,player,...)
 local wire=source(card,player,...);if wire==nil then return end
 local name,skill,costs=normal_parts(wire)
 if #costs~=1 or costs[1]~=card:getKnownEffectiveId()then ai_unsupported('view-as material differs from supplied owner card','biaofeng.view_as')end
 return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards=costs}
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

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, player, value, defense_query, siblings, context)
        for _, sibling in ipairs(siblings) do
            if defense_query(sibling, "hasSkill", "SixZhongyong") and defense_query(player, "getHandcardNum") < defense_query(sibling, "getHandcardNum")
                and defense_query(self, "beFriend", sibling, player) then value = value + (defense_query(sibling, "getHandcardNum") + defense_query(sibling, "getHp")) * 0.5 break end
        end
        return value
    end
    local previous_1 = sgs.ai_skill_defense["SixZhongyong"]
    sgs.ai_skill_defense["SixZhongyong"] = function(self, player, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_health" and context.rule == "SixZhongyong" then
                return policy_1(self, player, context.value, context.query, context.extra[1], context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player) end
        return previous_1
    end
    sgs.declareValueHookStages("ai_skill_defense", "SixZhongyong", {
        {phase="after_health", rule="SixZhongyong", order=8100},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_defense_slash["slash_defense.double_jink"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
        local double = call(self.player, "hasSkills", "wushuang|drwushuang")
            or call(self.player, "hasSkill", "roulin") and call(to, "isFemale")
            or call(to, "hasSkill", "roulin") and call(self.player, "isFemale")
            or jiangqin and call(jiangqin, "isAdjacentTo", to) and call(self.player, "isAdjacentTo", to)
                and call(self, "isFriend", jiangqin)
        if double and state.knownJink < 2 and (not call(to, "hasLordSkill", "hujia") or state.hujiaJink < 2) then defense = 0 end
        return defense
    end
    sgs.ai_defense_slash["slash_defense.double_jink"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "special_2" and context.rule == "slash_defense.double_jink" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "slash_defense.double_jink", {
        {phase="special_2", order=10, rule="slash_defense.double_jink"},
    })
end)()
end
