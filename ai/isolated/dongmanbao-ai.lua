-- Fixed dongmanbao-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local source_uses={}
local checkEnemyDetailed,checkFriendDetailed
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("dongmanbao policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("dongmanbao policy helper unavailable",method) end
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
local skill_cards={["#SE_GeassCard"]="SE_Geass",["#SE_Nagong_Geiqian"]="SE_Nagong_Geiqian",["#se_banyuncard"]="se_banyun",["#se_bianhuaCard"]="se_bianhua",["#se_bilingvscard"]="se_biling",["#se_cairencard"]="se_cairen",["#se_chenglingcard"]="se_chengling",["#se_chenyan"]="se_chenyan",["#se_chongjingcard"]="se_chongjing",["#se_chouyuancard"]="se_chouyuan",["#se_dushecard"]="se_dushe",["#se_erdao_oldCard"]="se_erdao_old",["#se_erdaocard"]="se_erdao",["#se_gaobaicard"]="se_gaobai",["#se_gatecard"]="se_gate",["#se_hengsaocard"]="se_hengsao",["#se_huanyuancard"]="se_huanyuan",["#se_jianguicard"]="se_jiangui",["#se_jianshicard"]="se_jianshi",["#se_jianwucard"]="se_jianwu",["#se_jianyucard"]="se_jianyu",["#se_jiejiecard"]="se_jiejie",["#se_jieshucard"]="se_jieshu",["#se_kanhucard"]="se_kanhu",["#se_liaolicard"]="se_liaoli",["#se_mipacard"]="se_mipa",["#se_origincard"]="se_origin",["#se_paojicard"]="se_paoji",["#se_poyicard"]="se_poyi",["#se_qingqiangweicard"]="se_qingqiangwei",["#se_qiyuancard"]="se_qiyuan",["#se_shengjiancard"]="se_shengjian",["#se_shixiancard"]="se_shixian",["#se_shourencard"]="se_shouren",["#se_shunshancard"]="se_shunshan",["#se_tiaoyuecard"]="se_tiaoyue",["#se_tonglingcard"]="se_tongling",["#se_xunyucard"]="se_xunyu",["#se_yekongcard"]="se_yekong",["#se_youhuocard"]="se_youhuo",["#se_zhanjingcard"]="se_zhanjing",["#se_zhijiancard"]="se_zhijian",["#se_zhilingcard"]="se_zhiling",["#se_zhiyucard"]="se_zhiyu",["#se_zhurencard"]="se_zhuren"}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'dongmanbao disclosed card '..tostring(id))end
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
local function ai_present(self,player)
 local state=pq(player,'getState')
 if state=='online'then return false end -- native getAI has this unconditional gate
 return pq(self,'useKnowledgeEstimate',{status='estimate',value=true,
  basis='dongmanbao.ai_presence_nononline_public_state_prior',player=pq(player,'objectName')},'dongmanbao.ai_presence')
end
local function second_general_present(self,player)
 local name=call(player,'getGeneral2Name')
 if type(name)=='string'and name~=''then return true end
 return pq(self,'useKnowledgeEstimate',{status='estimate',value=false,
  basis='dongmanbao.second_general_no_public_identity_evidence_prior',player=pq(player,'objectName')},'dongmanbao.second_general_presence')
end
local function viewer_role(self,p)local v=call(p,'getRole');if v~=nil then return v end;return pq(self,'useKnowledgeEstimate',{status='estimate',value=pq(self,'getRoleEstimate',p),basis='viewer_role_estimate_private_role',player=pq(p,'objectName')},'dongmanbao.role')end
local function role_count(self,key)return known(known(self.world.mode_policy,'mode policy').role_counts,'role counts')[key]or ai_unsupported('role count unknown',key)end
local function player_disclosed(player,id)
 for _,c in ipairs(known(player:getCards('he'),'owner cards'))do if c:getEffectiveId()==id then return c end end
 local v=rawget(player,'_view');for _,pile in ipairs(v and v.piles or{})do
  local admitted=false;for _,cid in ipairs(pile.card_ids or{})do if cid==id then admitted=true;break end end
  if admitted then for _,c in ipairs(pile.cards or{})do if c.id==id or c.effective_id==id then return known(CardView.new(c),'disclosed owner pile card')end end end
 end
 ai_unsupported('owner pile face not disclosed','dongmanbao.view_as')
end
local function resolve(self,name)if type(name)=='table'then return name end;if name==false or name==nil or name==''then return nil end;return known(self.room:findPlayerByObjectName(name,true),'tagged player')end
local function struct(self,row,kind)
 if type(row)~='table'then ai_unsupported('current tagged struct absent','dongmanbao.'..kind)end
 local v={};for k,x in pairs(row)do v[k]=x end
 for _,k in ipairs({'from','who'})do if v[k]~=nil then v[k]=resolve(self,v[k])end end
 if kind=='use'then local to=AIList.new{};for _,x in ipairs(v.to or v.targets or{})do to[#to+1]=resolve(self,x)end;v.to=to elseif v.to~=nil then v.to=resolve(self,v.to)end
 if v.card and type(v.card.isKindOf)~='function'then v.card=known(CardView.new(v.card),'tag card')end
 if v.amount~=nil then v.damage=v.amount end
 return v
end
local tag_keys={FansheDamage='dongmanbao_fanshe_damage',SE_Zhihui='dongmanbao_zhihui_damage',SE_Zishang='dongmanbao_zishang_damage',SE_Shouzang_target='dongmanbao_shouzang_target',SE_Lingshang_type='dongmanbao_lingshang_type',se_bilingvs_target='dongmanbao_biling_target'}
local function tag(self,key)
 local value
 if key:match('^ai_se_chenyan_card_')then value=self:getStrategyMemory('dongmanbao.'..key);if value==nil then value=key=='ai_se_chenyan_card_name'and''or 0 end
 elseif key=='CurrentDamageStruct'then value=known(self.world.strategy_facts.standard,'standard facts').current_damage
 elseif key:match('^UseHistory')then local row=known(self:getDecisionContext().dongmanbao_use_history,'current use history');if row.key~=key then ai_unsupported('current use history key differs',key)end;value=row.use
 else value=self:getDecisionContext()[known(tag_keys[key],key)]end
 value=known(value,key)
 return{toInt=function()if type(value)~='number'then ai_unsupported('integer tag unavailable',key)end;return value end,
 toString=function()if value==false then return''end;if type(value)~='string'then ai_unsupported('string tag unavailable',key)end;return value end,
 toPlayer=function()return resolve(self,value)end,toDamage=function()return struct(self,value,'damage')end,toCardUse=function()return struct(self,value,'use')end}
end
local function set_tag(self,key,value)if not key:match('^ai_se_chenyan_card_')then ai_unsupported('unapproved tag write',key)end;self:setStrategyMemory('dongmanbao.'..key,value)end
local function remove_tag(self,key)set_tag(self,key,nil)end
local function chenyan_mark(self,key,operation,value)
 local epoch=known(known(self.world.strategy_facts.strategy_turn_clear_epochs,'turn mark clear epochs')[pq(self.player,'objectName')],'owner mark clear epoch')
 local row=self:getStrategyMemory('dongmanbao.mark.'..key);local base=pq(self.player,'getMark',key);local offset=row and row.epoch==epoch and row.offset or 0
 if operation=='set'then offset=value-base elseif operation=='add'then offset=offset+value end
 if operation then self:setStrategyMemory('dongmanbao.mark.'..key,{epoch=epoch,offset=offset})end
 return base+offset
end
local function dushe_flag(self,p,name,set)
 local epochs=known(self.world.strategy_facts.strategy_flag_clear_epochs,'flag clear epochs');local epoch=known(epochs[pq(p,'objectName')],'target clear epoch')
 local key='dongmanbao.'..name..'.'..pq(p,'objectName');local old=self:getStrategyMemory(key)
 if set then self:setStrategyMemory(key,{epoch=epoch,value=true});return end
 if old and old.epoch==epoch then return old.value end
 return pq(p,'hasFlag',name)
end
local function role_write(self,skill,target,source,reset)
 if skill~='SE_Dapo' then
  ai_unsupported('dongmanbao role assignment requires scoped role-effect contract',skill)
 end
 -- Preserve the three reached source role reads and the unused rebel rewrite.
 -- The host stages one atomic effect; a source error after its early resets is
 -- outside successful-event parity and must never silently become a no-op.
 local role,value=pq(target,'getRole'),1000
 if role=='rebel' then role='loyalist';value=-1000 end
 local assigned=pq(source,'getRole')
 local inferred=pq(source,'getRole')
 local witness=self.world.strategy_facts and self.world.strategy_facts.dongmanbao_dapo_role_witness
 local targetName,sourceName=pq(target,'objectName'),pq(source,'objectName')
 local witnessed
 if type(witness)=='table' and witness.player==targetName and witness.target_role_known==true
  and type(witness.sources)=='table' then
  for _,row in ipairs(witness.sources)do
   if row.player==sourceName and row.role_known==true then witnessed=row.role;break end
  end
 end
 if not ({lord=true,loyalist=true,rebel=true,renegade=true})[witnessed]
  or assigned~=witnessed or inferred~=witnessed then
  ai_unsupported('Current Dying role witness unavailable','dongmanbao.SE_Dapo.role')
 end
 call(self,'emitStrategyEffect',{kind='dongmanbao_dapo_role',player=targetName,
  source_player=sourceName,role=assigned})
end
local function generateAllCardObjectNameTablePatterns(self)return known(self.world.strategy_facts.pattern_names,'registered card pattern list')end
local function peiqi(self)
 local fn=sgs.ai_skill_invoke.peiqi;if type(fn)~='function'then ai_unsupported('effective peiqi policy missing','dongmanbao.peiqi')end
 local ok,value=pcall(fn,self,nil)
 if self.peiqiData then local d=self.peiqiData;self:setStrategyMemory('dongmanbao.peiqi',{from=d.from and pq(d.from,'objectName'),to=d.to and pq(d.to,'objectName'),cid=d.cid})end
 if not ok then error(value,0)end;return value
end
local function peiqi_data(self)
 if self.peiqiData then return self.peiqiData end
 local row=known(self:getStrategyMemory('dongmanbao.peiqi'),'dongmanbao preceding peiqi state')
 return{from=row.from and known(self.room:findPlayerByObjectName(row.from,true),'peiqi.from'),to=row.to and known(self.room:findPlayerByObjectName(row.to,true),'peiqi.to'),cid=row.cid}
end
sgs.ai_event_callback[sgs.Dying or 'Dying']=sgs.ai_event_callback[sgs.Dying or 'Dying']or{}
sgs.ai_event_callback[sgs.CardFinished or 'CardFinished']=sgs.ai_event_callback[sgs.CardFinished or 'CardFinished']or{}




local function ThunderImmune(self, player)
	if pq(player,"hasSkill","LuaTianmo") and pq(player,"getMark","@tianmo") > 0 then return true end
	if pq(self,"hasSkills","SE_Maoqun|Tianhuo", player) then return true end
	return false
end


local function isEquip(name, player)
	for _, e in sgs.qlist(pq(player,"getEquips")) do
		if pq(e,"isKindOf",name) then
			return true
		end
	end
	return false
end


local function hasJudgePlayer(self, isFriend)
	for _, player in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(self,"hasSkills","se_qidian|guicai|guidao", player) then
			if isFriend then
				if pq(self,"isFriend",player) then return true end
			else
				if pq(self,"isEnemy",player) then return true end
			end
		end
	end
	return false
end


local function mostPlayer(self, isFriend, kind)
	local num = 0
	local target
	if kind == 1 then 
		num = 100
		if isFriend then
			for _, p in ipairs(self.friends) do
				if pq(p,"getHandcardNum") < num then
					target = p
					num = pq(p,"getHandcardNum")
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if pq(p,"getHandcardNum") < num then
					target = p
					num = pq(p,"getHandcardNum")
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 2 then 
		num = 0
		if isFriend then
			for _, p in ipairs(self.friends) do
				if pq(p,"getHandcardNum") > num then
					target = p
					num = pq(p,"getHandcardNum")
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if pq(p,"getHandcardNum") > num then
					target = p
					num = pq(p,"getHandcardNum")
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 3 then 
		num = 100
		if isFriend then
			for _, p in ipairs(self.friends) do
				if pq(p,"getHp") < num then
					target = p
					num = pq(p,"getHp")
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if pq(p,"getHp") < num then
					target = p
					num = pq(p,"getHp")
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 4 then 
		num = 0
		if isFriend then
			for _, p in ipairs(self.friends) do
				if pq(p,"getHp") > num then
					target = p
					num = pq(p,"getHp")
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if pq(p,"getHp") > num then
					target = p
					num = pq(p,"getHp")
				end
			end
			if not target then target = self.enemies[1] end
		end
	end
	if target then return target end
	return nil
end



sgs.ai_chaofeng["Mikoto"] = 5
sgs.ai_chaofeng["Shana"] = 1
sgs.ai_chaofeng["Louise"] = 0
sgs.ai_chaofeng["Saito"] = 6
sgs.ai_chaofeng["Eustia"] = 4
sgs.ai_chaofeng["Touma"] = -2
sgs.ai_chaofeng["Okarin"] = 2
sgs.ai_chaofeng["Taiga"] = 3
sgs.ai_chaofeng["SE_Kirito"] = 5
sgs.ai_chaofeng["SE_Asuna"] = -3
sgs.ai_chaofeng["Nanami"] = -3
sgs.ai_chaofeng["SE_Eren"] = 6
sgs.ai_chaofeng["Kuroko"] = 5
sgs.ai_chaofeng["HYui"] = 5
sgs.ai_chaofeng["Alice"] = 5
sgs.ai_chaofeng["Sakamoto"] = -4
sgs.ai_chaofeng["Kanade"] = -1
sgs.ai_chaofeng["Rena"] = -1
sgs.ai_chaofeng["Rena_black"] = 5
sgs.ai_chaofeng["Saber"] = 3
sgs.ai_chaofeng["Kirei"] = 4
sgs.ai_chaofeng["Tomoya"] = 2
sgs.ai_chaofeng["Misaka_Imouto"] = 9
sgs.ai_chaofeng["Tukasa"] = 4
sgs.ai_chaofeng["Natsume_Rin"] = -2
sgs.ai_chaofeng["Leafa"] = 2
sgs.ai_chaofeng["Reimu"] = 4
sgs.ai_chaofeng["Kuroneko"] = 3
sgs.ai_chaofeng["Sugisaki"] = -1
sgs.ai_chaofeng["Kuroyukihime"] = 4
sgs.ai_chaofeng["Nagase"] = -3
sgs.ai_chaofeng["Kazehaya"] = -1
sgs.ai_chaofeng["Ayase"] = 5
sgs.ai_chaofeng["Akarin"] = -3
sgs.ai_chaofeng["Hikigaya"] = 5
sgs.ai_chaofeng["Chiyuri"] = 3
sgs.ai_chaofeng["AiAstin"] = 4
sgs.ai_chaofeng["Hakaze"] = 4
sgs.ai_chaofeng["Kotori"] = -5
sgs.ai_chaofeng["Kotori_white"] = 0
sgs.ai_chaofeng["Aria"] = 4
sgs.ai_chaofeng["Reki"] = 4
sgs.ai_chaofeng["Ange"] = 1
sgs.ai_chaofeng["Rivaille"] = 4
sgs.ai_chaofeng["Asagi"] = -2
sgs.ai_chaofeng["Riko"] = 3
sgs.ai_chaofeng["Kurumi"] = 5
sgs.ai_chaofeng["Sakura"] = -4
sgs.ai_chaofeng["Eugeo"] = -4

sgs.ai_chaofeng.Accelerator = -5
sgs.ai_chaofeng.Lelouch = 5




sgs.ai_skill_playerchosen["se_jinqu"] = function(self, targets)
	
	if pq(self,"needKongcheng",self.player, true) and #self.friends_noself == 0 and pq(self.player,"getHandcardNum") == 0 then return false end
	return call(self,"findPlayerToDraw",false, 2)
end

sgs.ai_playerchosen_intention["se_jinqu"] = -70



sgs.ai_need_damaged["se_jinqu"] = function(self, attacker, player)
	if not pq(player,"hasSkill","se_jinqu") then return end

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

sgs.ai_can_damagehp.se_jinqu = function(self,from,card,to)
	return pq(to,"getHp")+pq(self,"getAllPeachNum")-pq(self,"ajustDamage",from,to,1,card)>0
	and pq(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_invoke["shengyou"] = function(self, data)
	
	return true
end



sgs.ai_skill_invoke["se_jinghua"] = true

sgs.ai_skill_playerchosen["se_jinghua"] = function(self, targets)
	local targets = AIList.new(targets)
	sort_players(self,targets, "defense")

	local friends = {}
	local player_list = AIList.new({})
	for _, player in ipairs(targets) do
		if pq(self,"isFriend",player) and not hasManjuanEffect(player) and not pq(self,"needKongcheng",player, true)
			and not (pq(player,"hasSkill","kongcheng") and pq(player,"isKongcheng")) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return nil end

	sort_players(self,friends, hp)

	local max_x = 5 - pq(self.player,"getHandcardNum")

	for _, friend in ipairs(friends) do
		if pq(friend,"isWounded") and pq(self,"isWeak",friend) and pq(friend,"getHp") < pq(self,"getBestHp",friend) then
			return friend
		end
	end


	for _, friend in ipairs(friends) do
		if pq(friend,"getHandcardNum") < 2 and not pq(self,"needKongcheng",friend) and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) and (pq(AssistTarget,"getHandcardNum") < pq(AssistTarget,"getMaxCards") * 2 or pq(AssistTarget,"getHandcardNum") < pq(self.player,"getHandcardNum")) then
		for _, friend in ipairs(friends) do
			if pq(friend,"objectName") == pq(AssistTarget,"objectName") and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if pq(self,"hasSkills",sgs.cardneed_skill, friend) and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	sort_players(self,friends, "handcard")
	for _, friend in ipairs(friends) do
		if not pq(self,"needKongcheng",friend) and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil

	
end



sgs.ai_skill_choice["se_jinghua"] = function(self, choices, data)
	local source = pq(data,"toPlayer")
	local items = pq(choices,"split","+")
	if #items == 1 then
		return items[1]
	else
		if table.contains(items, "se_jinghua_recover") and pq(self,"isWeak",source) and pq(source,"isWounded") and pq(source,"getHp") < pq(self,"getBestHp",source) then
			return
			"se_jinghua_recover"
		end
		if table.contains(items, "se_jinghua_getcard") and pq(source,"getJudgingArea"):length() > 0 then
			return
			"se_jinghua_getcard"
		end
		return "se_jinghua_drawcard"
	end
	return "se_jinghua_drawcard"
end

sgs.ai_playerchosen_intention.se_jinghua = -40

sgs.ai_skill_cardask["@se_jinghua"] = function(self,data)
	local target = pq(data,"toPlayer")
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards,true)
	local targets = AIList.new({})
	call(targets,"append",target)
	local h,friend = call(self,"getCardNeedPlayer",cards, false, targets)
	if h and friend then
		return "$"..pq(h,"getEffectiveId")
	end
	if pq(self,"isFriend",target) then
		return "$"..cards[1]:getEffectiveId()
	end
	return "."
end


sgs.ai_skill_invoke["se_jiushu"] = function(self, data)
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	local lord = call(self.room,"getLord")
	if lord and pq(self,"isWeak",lord) and viewer_role(self,self.player) == "loyalist" then
		if pq(lord,"objectName") == pq(source,"objectName") then
			return true
		else
			return false
		end
	end
	if pq(self,"isWeak",self.player) and pq(source,"objectName") ~= pq(self.player,"objectName") then
		return false
	end
	for _, player in ipairs(self.friends) do
		if pq(player,"isAlive") and source and pq(source,"objectName") == pq(player,"objectName") then
			return true
		end
	end
	if pq(source,"objectName") == pq(self.player,"objectName") then
		return true
	end
	return false
end





sgs.ai_skill_invoke.Huansha = function(self, data)
	local damage = pq(data,"toDamage")
	local source = damage.to
	for _, player in ipairs(self.friends) do
		if pq(player,"isAlive") and pq(source,"objectName") == pq(player,"objectName") then
			return true
		end
	end
	if pq(source,"objectName") == pq(self.player,"objectName") then
		return true
	end
	return false
end

ai_audited_aliases.register{id="ai_cardneed.Huansha",registry="ai_cardneed",path={"Huansha"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
sgs.ai_ajustdamage_to.Huansha = function(self, from, to, card, nature)
	if nature ~= "N" and ((from and pq(from,"isKongcheng")) or not from)
	then
		return -99
	end
end

sgs.ai_event_callback[sgs.Dying or "Dying"].SE_Dapo = function(self, player, data)
	local target = pq(data,"toDying").who
	for _, sb in sgs.qlist(pq(self.room,"getOtherPlayers",player)) do
		if pq(sb,"hasSkill","SE_Dapo") and pq(sb,"getHp") == 1 and target then
			role_write(self,"SE_Dapo",target,sb,true)
			call(self,"updatePlayers")
		end
	end
end


local se_paoji_skill = {}
se_paoji_skill.name = "se_paoji"
table.insert(package_skills, se_paoji_skill)
se_paoji_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_paojicard") then return end
	if #self.enemies < 1 then return end
	if pq(self.player,"getMark","@se_ying") < 1 then return end
	if not hasJudgePlayer(self, true) then
		if pq(self.player,"getHp") > 2 and pq(self.player,"getMark","@se_ying") < 4 then return end
		if pq(self.player,"getHp") > 1 and pq(self.player,"getMark","@se_ying") < 3 then return end
	end
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and not pq(self,"cantbeHurt",enemy) and pq(self,"canDamage",enemy,self.player,nil) then
				return parse(self,request,"#se_paojicard:.:")
			end
		end
	end
	return
end

sgs.ai_skill_use_func["#se_paojicard"] = function(card,use,self,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and not pq(self,"cantbeHurt",enemy) and pq(self,"canDamage",enemy,self.player,nil) then
				use.card=final_parse(self,request,"#se_paojicard:.:")
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
end




sgs.ai_skill_choice["se_paoji"] = function(self, choices, data)
	local choice_table = pq(choices,"split","+")
	local target = pq(data,"toPlayer")
	local count = pq(self.player,"getMark","@se_ying")
	local x = math.ceil(2 / pq(target,"getHp") + 1)
	if hasJudgePlayer(self, true) or pq(self,"cantDamageMore",self.player, target) then return "paoji_1" end
	
	
	if count > x then return "paoji_" .. x end
	if count < x then return "paoji_" .. count end
	return choice_table[1]
end



sgs.ai_use_value["se_paojicard"]      = 8
sgs.ai_use_priority["se_paojicard"]   = 2
sgs.ai_card_intention["se_paojicard"] = 100

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|se_paoji"

sgs.ai_getBestHp_skill.Dianci = function(owner)
	if pq(owner,"getMark","@ying") >= 1 then
		return pq(owner,"getMaxHp") - 1
	end
end



local se_cairen_skill = {}
se_cairen_skill.name = "se_cairen"
table.insert(package_skills, se_cairen_skill)
se_cairen_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"getPile","moli"):length() <= 3 then return end
	return parse(self,request,"#se_cairencard:.:")
end

sgs.ai_skill_use_func["#se_cairencard"] = function(card,use,self,request)
	local useable_cards = {}
	if pq(self.player,"getPile","moli"):length() > 3 then
		for _, id in sgs.qlist(pq(self.player,"getPile","moli")) do
			table.insert(useable_cards, disclosed(self,id))
		end
	end
	local card_str = string.format("#se_cairencard:%s:", useable_cards[1]:getEffectiveId())
	local acard = parse(self,request,card_str)
	use.card = acard

	
	return
end
sgs.ai_use_value["se_cairencard"] = 8
sgs.ai_use_priority["se_cairencard"] = 10

sgs.ai_skill_playerchosen.Beizeng = function(self, targets)
	local targets = AIList.new(targets)
	sort_players(self,targets, "hp")
	for _, p in ipairs(targets) do
		if pq(self,"isEnemy",p) and not pq(self,"hasZhaxiangEffect",p) and pq(p,"hasSkills",sgs.need_maxhp_skill) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if pq(self,"isEnemy",p) and not pq(self,"hasZhaxiangEffect",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["Beizeng"] = 50

sgs.ai_cardneed.Xuwu = function(to, card, self)
	return pq(card,"getTypeId") == sgs.Card_TypeTrick
end

sgs.ai_card_priority.Xuwu = function(self, card, v)
	if self.useValue
		and pq(card,"isKindOf","TrickCard")
	then
		v = v + 4
	end
end



sgs.ai_use_priority["se_zhijiancard"]   = 10
sgs.ai_card_intention["se_zhijiancard"] = 0


local se_zhijian_skill = {}
se_zhijian_skill.name = "se_zhijian"
table.insert(package_skills, se_zhijian_skill)
se_zhijian_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self,"needBear") then return end
	local source = self.player
	if pq(source,"getPile","moli"):length() < 3 then return end
	
	if not pq(self.player,"hasFlag","se_zhijiancard_used") and not pq(self.player,"isKongcheng") then
		return parse(self,request,
			"#se_zhijiancard:.:")
	end
end

sgs.ai_skill_use_func["#se_zhijiancard"] = function(card,use,self,request)
	sort_players(self,self.enemies, "handcard")
	local cards = AIList.new({})
	local peach = 0
	for _, c in sgs.qlist(pq(self.player,"getHandcards")) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			call(cards,"append",c)
		end
	end
	local max_card = call(self,"getMaxCard",self.player, cards)
	if not max_card then return end
	local max_point = pq(max_card,"getNumber")
	local useable_cards = {}
	if pq(self.player,"getPile","moli"):length() > 0 then
		for _, id in sgs.qlist(pq(self.player,"getPile","moli")) do
			table.insert(useable_cards, disclosed(self,id))
		end
	end
	local card_str = string.format("#se_zhijiancard:%s:", useable_cards[1]:getEffectiveId())
	for _, enemy in ipairs(self.enemies) do
		if not pq(enemy,"isKongcheng") and pq(self.player,"canPindian",enemy) then
			local enemy_max_card = call(self,"getMaxCard",enemy)
			local allknown = 0
			if pq(self,"getKnownNum",enemy) == pq(enemy,"getHandcardNum") then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > pq(enemy_max_card,"getNumber") and allknown > 0)
				or (enemy_max_card and max_point > pq(enemy_max_card,"getNumber") and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				local acard = parse(self,request,card_str)
				use.card = acard
				call(self,"remember","zhijian_card",max_card)
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	if pq(self.player,"getHandcardNum") >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if not pq(enemy,"isKongcheng") and pq(self.player,"canPindian",enemy) then
				local enemy_min_card = call(self,"getMinCard",enemy)
				local cardsq = pq(self.player,"getHandcards")
				cardsq = AIList.new(cardsq)
				sort_use(self,cardsq, true)

				local min_card = call(self,"getMinCard")
				local enemy_min_card = call(self,"getMinCard",enemy)
				if enemy_min_card and pq(min_card,"getNumber") < pq(enemy_min_card,"getNumber") then
					local acard = parse(self,request,card_str)
					use.card = acard
					call(self,"remember","zhijian_card",max_card)
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
	end

	if pq(self.player,"hasSkill","kongcheng") and pq(self.player,"getHandcardNum") == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not pq(enemy,"isKongcheng") and not pq(self,"doDisCard",enemy, "h") and pq(self.player,"canPindian",enemy) then
				local acard = parse(self,request,card_str)
				use.card = acard
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	local zhugeliang = call(self.room,"findPlayerBySkillName","kongcheng")



	cards = AIList.new(cards)
	sort_use(self,cards, true)
	if zhugeliang and pq(self,"isFriend",zhugeliang) and pq(zhugeliang,"getHandcardNum") == 1 and pq(self.player,"canPindian",zhugeliang)
		and pq(zhugeliang,"objectName") ~= pq(self.player,"objectName") and pq(self,"getEnemyNumBySeat",self.player, zhugeliang) >= 1 then
		if isCard("Jink", cards[1], self.player) and pq(self,"getCardsNum","Jink") == 1 then return end
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then call(use.to,"append",zhugeliang) end
		return
	end

	if pq(self,"getOverflow") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not pq(self,"doDisCard",enemy, "h", true) and not pq(enemy,"isKongcheng") and pq(self.player,"canPindian",enemy) then
				local acard = parse(self,request,card_str)
				use.card = acard
				call(self,"remember","zhijian_card",max_card)
				if use.to then call(use.to,"append",enemy) end
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.se_zhijiancard(minusecard, self, requestor)
	if pq(requestor,"getHandcardNum") == 1 then
		local cards = AIList.new(pq(self.player,"getHandcards"))
		sort_keep(self,cards)
		return cards[1]
	end
	local maxcard = call(self,"getMaxCard")
	return pq(self,"isFriend",requestor) and call(self,"getMinCard") or (pq(maxcard,"getNumber") < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.se_zhijian",registry="ai_cardneed",path={"se_zhijian"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
local se_hengsao_skill = {}
se_hengsao_skill.name = "se_hengsao"
table.insert(package_skills, se_hengsao_skill)
se_hengsao_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if #self.enemies < 2 then return end
	if pq(source,"getHp") <= 2 then return end
	if pq(self,"isWeak",source) then return end
	if pq(source,"getHp") <= 3 and #self.enemies < 3 then return end
	return parse(self,request,"#se_hengsaocard:.:")
end

sgs.ai_skill_use_func["#se_hengsaocard"] = function(card,use,self,request)
	local targets = AIList.new({})
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy and pq(targets,"length") < 3 and pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not pq(self,"cantbeHurt",enemy) and pq(self,"canDamage",enemy,self.player,nil) then 
			call(targets,"append",enemy)
		end
	end
	if pq(targets,"length") >= 2 then
		use.card=final_parse(self,request,"#se_hengsaocard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["se_hengsaocard"]    = 4.2
sgs.ai_card_intention["se_hengsaocard"]  = 108

function sgs.ai_cardneed.Zhena(to, card, self)
	return (pq(card,"isKindOf","Weapon") and not call(self.player,"getWeapon")) or pq(card,"isKindOf","fire_attack") or
		pq(card,"isKindOf","fire_slash") or pq(card,"isKindOf","iron_chain")
end


sgs.ai_skill_invoke.Zhena       = function(self, data)
	local damage = pq(data,"toDamage")
	local source = damage.to
	if pq(self,"isEnemy",source) and (pq(source,"getHp") - damage.damage > 1 or pq(self.player,"getHp") <= 1)
		and pq(self,"damageIsEffective",source, sgs.DamageStruct_Fire) then
		return not pq(self,"cantDamageMore",self.player, source) and
			((pq(self,"isWeak",self.player) or pq(self.player,"getHp") == 1) or
				(pq(self.player,"getHp") <= pq(source,"getHp") and pq(self,"getCardsNum","Peach") > 0) or pq(source,"isLord"))
	end
	return false
end

sgs.ai_used_revises.Zhena       = function(self, use)
	if pq(use.card,"isKindOf","Slash")
		and not call(self.player,"getWeapon")
		and not use.isDummy
	then
		for _, to in sgs.list(use.to) do
			if pq(self,"isEnemy",to)
				and getCardsNum("Jink", to, self.player) < 1
			then
				local use_card
				for _, card in sgs.qlist(pq(self.player,"getHandcards")) do
					if pq(card,"isKindOf","Weapon") then
						use_card = card
					end
				end
				if use_card then
					use.card = use_card

					use.to = AIList.new({})
					return false
				end
			end
		end
	end
end



sgs.ai_ajustdamage_to.Tianhuo   = function(self, from, to, card, nature)
	if nature ~= "N" then
		return -99
	end
end
sgs.ai_ajustdamage_from.Tianhuo = function(self, from, to, card, nature)
	if nature == "F" then
		return 1
	end
end
function sgs.ai_cardneed.Tianhuo(to, card, self)
	return (pq(card,"isKindOf","Weapon") and not call(self.player,"getWeapon")) or pq(card,"isKindOf","fire_attack") or
		pq(card,"isKindOf","fire_slash") or pq(card,"isKindOf","iron_chain")
end


sgs.ai_chaofeng.Shana = 4
sgs.ai_chaofeng.Shana2 = 4
sgs.ai_chaofeng.Shana3 = 4




local se_shixian_skill = {}
se_shixian_skill.name = "se_shixian"
table.insert(package_skills, se_shixian_skill)
se_shixian_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"getMark","@time") == 0 then return end
	if pq(source,"getMark","@Benhuihe") > 0 then return end
	if pq(source,"getMark","@timepoint") > 0 then return end
	if pq(source,"getHandcardNum") < 4 then return end
	if pq(source,"getHp") == 1 and pq(source,"getHandcardNum") < 7 then return end
	if pq(source,"getHp") == 2 and pq(source,"getHandcardNum") < 6 then return end
	if pq(source,"getHp") == 3 and pq(source,"getHandcardNum") < 5 then return end
	return parse(self,request,"#se_shixiancard:.:")
end

sgs.ai_skill_use_func["#se_shixiancard"] = function(card,use,self,request)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local needed = {}
	for _, acard in ipairs(cards) do
		table.insert(needed, pq(acard,"getEffectiveId"))
	end
	if pq(self.player,"getHp") >= 3 then
		if call(self.player,"getArmor") then
			table.insert(needed, call(self.player,"getArmor"):getEffectiveId())
		end
		if call(self.player,"getDefensiveHorse") then
			table.insert(needed, call(self.player,"getDefensiveHorse"):getEffectiveId())
		end
	else
		if call(self.player,"getWeapon") then
			table.insert(needed, call(self.player,"getWeapon"):getEffectiveId())
		end
		if call(self.player,"getOffensiveHorse") then
			table.insert(needed, call(self.player,"getOffensiveHorse"):getEffectiveId())
		end
	end
	use.card=final_parse(self,request,"#se_shixiancard:" .. table.concat(needed, "+") .. ":")
	return
end

sgs.ai_use_priority["se_shixiancard"] = 10



local se_tiaoyue_skill = {}
se_tiaoyue_skill.name = "se_tiaoyue"
table.insert(package_skills, se_tiaoyue_skill)
se_tiaoyue_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"getMark","@time") == 0 then return end
	if pq(source,"getMark","@timepoint") == 0 then return end
	if pq(source,"getMark","Benhuihe") > 0 then return end
	if pq(source,"getHp") > 2 then return end
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local help_card_num = 0
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","Peach") or pq(acard,"isKindOf","Jink") or pq(acard,"isKindOf","Analeptic") then
			help_card_num = help_card_num + 1
		end
	end
	if pq(source,"getHp") == 2 and (help_card_num > 0 and pq(source,"getHandcardNum") <= 3) then return end
	return parse(self,request,"#se_tiaoyuecard:.:")
end

sgs.ai_skill_use_func["#se_tiaoyuecard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#se_tiaoyuecard:.:")
	return
end



sgs.ai_use_priority["se_tiaoyuecard"] = 3.6




local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if pq(self,"isFriend",who) then
		local judges = pq(who,"getJudgingArea")
		if not pq(judges,"isEmpty") then
			for _, judge in sgs.qlist(judges) do
				card = disclosed(self,pq(judge,"getEffectiveId"))
				if not pq(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not pq(enemy,"containsTrick",pq(judge,"objectName")) and not pq(enemy,"containsTrick","YanxiaoCard")
							and not pq(self.room,"isProhibited",self.player, enemy, judge) and not (pq(enemy,"hasSkill","hongyan") or pq(judge,"isKindOf","Lightning")) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = pq(who,"getCards","e")
		local weak
		if not target and not pq(equips,"isEmpty") and pq(self,"hasSkills",sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if pq(equip,"isKindOf","OffensiveHorse") then
					card = equip
					break
				elseif pq(equip,"isKindOf","Weapon") then
					card = equip
					break
				elseif pq(equip,"isKindOf","DefensiveHorse") and not pq(self,"isWeak",who) then
					card = equip
					break
				elseif pq(equip,"isKindOf","Armor") and (not pq(self,"isWeak",who) or pq(self,"needToThrowArmor",who)) then
					card = equip
					break
				end
			end

			if card then
				if pq(card,"isKindOf","Armor") or pq(card,"isKindOf","DefensiveHorse") then
					sort_players(self,self.friends, "defense")
				else
					sort_players(self,self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not call(self,"getSameEquip",card, friend) and pq(friend,"objectName") ~= pq(who,"objectName")
						and pq(self,"hasSkills",sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not call(self,"getSameEquip",card, friend) and pq(friend,"objectName") ~= pq(who,"objectName") then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = pq(who,"getJudgingArea")
		if pq(who,"containsTrick","YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if pq(judge,"isKindOf","YanxiaoCard") then
					card = disclosed(self,pq(judge,"getEffectiveId"))
					for _, friend in ipairs(self.friends) do
						if not pq(friend,"containsTrick",pq(judge,"objectName")) and not pq(self.room,"isProhibited",self.player, friend, judge)
							and not pq(friend,"getJudgingArea"):isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not pq(friend,"containsTrick",pq(judge,"objectName")) and not pq(self.room,"isProhibited",self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card == nil or target == nil then
			if not pq(who,"hasEquip") or pq(self,"hasSkills",sgs.lose_equip_skill, who) then return nil end
			local card_id = pq(self,"askForCardChosen",who, "e", "snatch")
			if card_id >= 0 and pq(who,"hasEquip",disclosed(self,card_id)) then card = disclosed(self,card_id) end

			if card then
				if pq(card,"isKindOf","Armor") or pq(card,"isKindOf","DefensiveHorse") then
					sort_players(self,self.friends, "defense")
				else
					sort_players(self,self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not call(self,"getSameEquip",card, friend) and pq(friend,"objectName") ~= pq(who,"objectName") and pq(self,"hasSkills",sgs.lose_equip_skill .. "|shensu", friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not call(self,"getSameEquip",card, friend) and pq(friend,"objectName") ~= pq(who,"objectName") then
						target = friend
						break
					end
				end
			end
		end
	end

	if return_prompt == "card" then
		return card
	elseif return_prompt == "target" then
		return target
	else
		return (card and target)
	end
end


sgs.ai_skill_invoke.Zhudao = true
ai_audited_aliases.register{id="ai_cardneed.Zhudao",registry="ai_cardneed",path={"Zhudao"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.ai_skill_playerchosen.Zhudao_from = function(self,players)
    if peiqi(self)
	then
		for _,target in sgs.list(players)do
			if pq(target,"objectName")==pq(peiqi_data(self).from,"objectName")
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen.Zhudao_to = function(self,players)
	for _,target in sgs.list(players)do
		if pq(target,"objectName")==pq(peiqi_data(self).to,"objectName")
		then return target end
	end
end

sgs.ai_skill_cardchosen.Zhudao = function(self,who,flags,method)
	for i,c in sgs.list(pq(who,"getCards",flags))do
		i = pq(c,"getEffectiveId")
		if i==peiqi_data(self).cid
		then return i end
	end
end
sgs.ai_skill_playerchosen.Sixu_from = function(self,players)
    if peiqi(self)
	then
		for _,target in sgs.list(players)do
			if pq(target,"objectName")==pq(peiqi_data(self).from,"objectName")
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen.Sixu_to = function(self,players)
	for _,target in sgs.list(players)do
		if pq(target,"objectName")==pq(peiqi_data(self).to,"objectName")
		then return target end
	end
end

sgs.ai_skill_cardchosen.Sixu = function(self,who,flags,method)
	for i,c in sgs.list(pq(who,"getCards",flags))do
		i = pq(c,"getEffectiveId")
		if i==peiqi_data(self).cid
		then return i end
	end
end

sgs.Zhudao_keep_value = sgs.xiaoji_keep_value




function sgs.ai_cardneed.se_erdao(to, card, self)
	return pq(card,"isKindOf","Weapon")
end

local se_erdao_skill = {}
se_erdao_skill.name = "se_erdao"
table.insert(package_skills, se_erdao_skill)
se_erdao_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or pq(self.player,"isKongcheng") then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if pq(player,"getHp") >= 2 and pq(self,"slashIsEffective",call(self,"cloneEvaluationCard","slash"), player) and pq(self,"slashIsEffective",call(self,"cloneEvaluationCard","thunder_slash"), player) and pq(self,"slashIsEffective",call(self,"cloneEvaluationCard","fire_slash"), player) then
			too_weak = false
		end
	end
	if too_weak then return end
	local source = self.player
	local OK_num = 0
	if call(source,"getWeapon") then
		OK_num = OK_num + 1
	end
	local cards = AIList.new(pq(self.player,"getHandcards"))
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","Weapon") then
			OK_num = OK_num + 1
		end
	end
	if OK_num > 1 then
		return parse(self,request,"#se_erdaocard:.:")
	end
end

sgs.ai_skill_use_func["#se_erdaocard"] = function(card,use,self,request)
	local target
	local slash = call(self,"cloneEvaluationCard","slash")
	
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"isEnemy",enemy) and not pq(self,"slashProhibit",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(self,"slashIsEffective",slash, enemy) then
			
			target = enemy
		end
	end
	if target then
		local needed = {}
		if call(self.player,"getWeapon") then
			table.insert(needed, call(self.player,"getWeapon"):getEffectiveId())
		end
		local cards = AIList.new(pq(self.player,"getHandcards"))
		for _, acard in ipairs(cards) do
			if pq(acard,"isKindOf","Weapon") then
				table.insert(needed, pq(acard,"getEffectiveId"))
				if #needed > 1 then
					break
				end
			end
		end
		use.card=final_parse(self,request,"#se_erdaocard:" .. table.concat(needed, "+") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_erdaocard"]       = 8
sgs.ai_use_priority["se_erdaocard"]    = 8
sgs.ai_card_intention.se_erdaocard     = 108



sgs.ai_skill_invoke.se_erdao = function(self, data)
	local use = pq(data,"toCardUse")
	if pq(use.card,"isDamageCard") or pq(use.card,"isKindOf","SingleTargetTrick") then
		for _,to in sgs.list(use.to)do
			if pq(self,"isFriend",to)
			then return false end
		end
		return true
	end
	local dummy_use = pq(self,"aiUseCard",use.card, dummy())
	if dummy_use.card then
        if not pq(dummy_use.to,"isEmpty") then
			for _, p in sgs.qlist(dummy_use.to) do
				for _,to in sgs.list(use.to)do
					if pq(p,"objectName") == pq(to,"objectName") then
						return true
					end
				end
			end
        end
    end
    return false
end


local se_yekong_skill = {}
se_yekong_skill.name = "se_yekong"
table.insert(package_skills, se_yekong_skill)
se_yekong_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getMark","@Yuzora") == 0 then return end
	local total_damage = 0
	for _, friend in ipairs(self.friends) do
		if friend then
			total_damage = total_damage + pq(friend,"getLostHp")
		end
	end
	if #self.friends == 1 and total_damage < 2 then return end
	if #self.friends == 2 and total_damage < 2 and pq(self.player,"getHp") > 1 then return end
	if #self.friends > 2 and total_damage < 3 and pq(self.player,"getHp") > 1 then return end
	return parse(self,request,"#se_yekongcard:.:")
end

sgs.ai_skill_use_func["#se_yekongcard"]   = function(card,use,self,request)
	if pq(self,"getCardsNum","duel") > 0 or pq(self,"getCardsNum","dismantlement") > 0 or pq(self,"getCardsNum","snatch") > 0 or pq(self,"getCardsNum","ex_nihilo") > 0 then
		use.card = card
	end
	if pq(self.player,"getHp") == 1 then
		use.card = card
	end
	local help = 0
	for _, friend in ipairs(self.friends) do
		if pq(friend,"hasSkill","SE_Shanguang") or pq(friend,"hasSkill","se_jianwu") or pq(friend,"hasSkill","Huajian") then
			help = help + 1
		end
		if pq(friend,"getHp") <= 2 then
			help = help + 1
		end
	end
	if help >= 1 then
		use.card = card
	end
end

sgs.ai_use_value["se_yekongcard"]         = 8
sgs.ai_use_priority["se_yekongcard"]      = 10
sgs.ai_card_intention.se_yekongcard       = -100

sgs.ai_skill_invoke.se_yekongRe           = function(self, data)
	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	local target

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1])) and arr1[1]:getHp() < pq(self,"getBestHp",arr1[1]) then target = arr1[1] end
	if target then
		return true
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not pq(friend,"hasSkills","hunzi|longhun") then
				return true
			end
		end
	end

	if target then
		return true 
	end
	return false
end

sgs.ai_skill_playerchosen.se_yekongRe     = function(self, targets)
	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	local target = self.player

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1])) and arr1[1]:getHp() < pq(self,"getBestHp",arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not pq(friend,"hasSkills","hunzi|longhun") then
				return friend
			end
		end
	end


	return target 
end

sgs.ai_playerchosen_intention.se_yekongRe = function(self, from, to)
	if pq(to,"isWounded") then
		call(self,"updateIntention",from, to, -50)
	end
end

sgs.ai_skill_invoke.Yuzora_Shanguang      = function(self, data)
	local damage = pq(data,"toDamage")
	if damage.from and pq(self,"isFriend",damage.from) and pq(damage.from,"hasSkill","SE_Shanguang") then
		return true
	end
	return false
end

sgs.ai_skill_invoke.Yuzora_se_jianwu      = function(self, data)
	local source = pq(data,"toPlayer")
	if source and pq(self,"isFriend",source) and pq(source,"hasSkill","se_jianwu") then
		return true
	end
	return false
end





sgs.ai_skill_invoke.SE_Dixian = function(self, data)
	local damage = pq(data,"toDamage")
	if pq(self,"canDamage",damage.from, damage.to) then
		if pq(self,"isFriend",damage.from) then
			return pq(self,"dontHurt",damage.from, damage.to)
		end
		return true
	end
	return not pq(self,"isFriend",damage.from)
end


function sgs.ai_slash_prohibit.SE_Dixian(self, from, to)
	if pq(self,"isFriend",from, to) then return false end
	if pq(from,"hasSkill","jueqing") or (pq(from,"hasSkill","nosqianxi") and pq(from,"distanceTo",to) == 1) then return false end
	if pq(from,"hasFlag","NosJiefanUsed") then return false end
	if pq(from,"getHandcardNum") < pq(to,"getLostHp") + 1 and pq(from,"getEquips"):length() == 0 and pq(from,"getHandcards"):at(0):isKindOf("Slash") and pq(from,"getHp") >= 2 then return false end
	return pq(from,"getHp") + pq(from,"getEquips"):length() < 4 or pq(from,"getHp") < 2
end

sgs.ai_can_damagehp.SE_Dixian = function(self, from, card, to)
	if from and pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0 and
		pq(self,"canLoseHp",from, card, to) then
		return pq(self,"isEnemy",from) and pq(from,"getHandcardNum") > 0 and pq(self,"canAttack",from, to)
	end
end

sgs.ai_choicemade_filter.skillInvoke.SE_Dixian = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not pq(self,"canAttack",damage.from, player) and not pq(self,"needToLoseHp",damage.from, player) then
				call(self,"updateIntention",damage.to, damage.from, 40)
			end
		elseif pq(self,"canAttack",damage.from) then
			call(self,"updateIntention",damage.to, damage.from, -40)
		end
	end
end

function SmartAIView:findSE_DixianTarget(player, SE_Dixian_value)
	local getCmpValue = function(enemy)
		local value = 0
		if not pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire, player) then return 100 end
		if pq(self,"cantbeHurt",enemy, player, 1) or pq(self,"objectiveLevel",enemy) < 3
			or (pq(enemy,"isChained") and not pq(self,"isGoodChainTarget",enemy,  sgs.DamageStruct_Fire,player, 1)) then
			return 100
		end
		if not pq(self,"isGoodTarget",enemy, self.enemies, nil) then value = value + 50 end
		if pq(enemy,"hasSkills",sgs.exclusive_skill) then value = value + 10 end
		if pq(enemy,"hasSkills",sgs.masochism_skill) then value = value + 5 end
		if pq(enemy,"isChained") and pq(self,"isGoodChainTarget",enemy,  sgs.DamageStruct_Fire,player, 1) and #(pq(self,"getChainedEnemies",player)) > 1 then
			value =
				value - 25
		end
		if pq(enemy,"isLord") then value = value - 5 end
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = pq(self,"getEnemies",player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < SE_Dixian_value then return enemy end
	end
	return nil
end

sgs.ai_skill_playerchosen.SE_Dixian = function(self, targets)
	local target
	sort_players(self,self.enemies, "defense")
	return call(self,"findSE_DixianTarget",self.player, 100)
end


ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SE_Shanguang",registry="ai_choicemade_filter",path={"cardChosen","SE_Shanguang"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_playerchosen.SE_Shanguang = function(self, targets)
	local targets = AIList.new(targets)
	local target
	sort_players(self,targets, "hp")
	for _, enemy in ipairs(targets) do
		if pq(self,"isEnemy",enemy) then
			target = enemy
		end
	end
	if target then return target end
	return nil
end


sgs.ai_skill_cardchosen.SE_Shanguang = function(self, who, flags)
	if call(who,"getArmor") then return call(who,"getArmor") end
	if pq(who,"getHandcardNum") == 1 and not pq(self,"needKongcheng",who) then
		local cards = pq(who,"getHandcards")
		return cards[1]
	end
	if call(who,"getWeapon") then return call(who,"getWeapon") end
	if call(who,"getOffensiveHorse") then return call(who,"getOffensiveHorse") end
	if call(who,"getDefensiveHorse") then return call(who,"getDefensiveHorse") end
	if pq(who,"getHandcardNum") > 1 then
		local cards = pq(who,"getHandcards")
		return cards[1]
	end
	return
end



local SE_Erdao_old_skill = {}
SE_Erdao_old_skill.name = "se_erdao_old"
table.insert(package_skills, SE_Erdao_old_skill)
SE_Erdao_old_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or pq(self.player,"isKongcheng") then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if pq(player,"getHp") >= 2 and pq(self,"damageIsEffective",player, nil, self.player) and pq(self,"isGoodTarget",player, self.enemies, nil) then
			too_weak = false
		end
	end
	if too_weak then return end
	local source = self.player
	local OK_num = 0
	if call(source,"getWeapon") then
		OK_num = OK_num + 1
	end
	local cards = AIList.new(pq(self.player,"getHandcards"))
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","Weapon") then
			OK_num = OK_num + 1
		end
	end
	if OK_num > 1 then
		return parse(self,request,"#se_erdao_oldCard:.:")
	end
end

sgs.ai_skill_use_func["#se_erdao_oldCard"] = function(card,use,self,request)
	local target
	local slash = call(self,"cloneEvaluationCard","slash")
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"isEnemy",enemy) and pq(self,"damageIsEffective",enemy, nil, self.player) and pq(self,"isGoodTarget",enemy, self.enemies, nil) then
			target = enemy
		end
	end
	if target then
		local needed = {}
		if call(self.player,"getWeapon") then
			table.insert(needed, call(self.player,"getWeapon"):getEffectiveId())
		end
		local cards = AIList.new(pq(self.player,"getHandcards"))
		for _, acard in ipairs(cards) do
			if pq(acard,"isKindOf","Weapon") then
				table.insert(needed, pq(acard,"getEffectiveId"))
				if #needed > 1 then
					break
				end
			end
		end
		use.card=final_parse(self,request,"#se_erdao_oldCard:" .. table.concat(needed, "+") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_erdao_oldCard"]       = 8
sgs.ai_use_priority["se_erdao_oldCard"]    = 8
sgs.ai_card_intention.se_erdao_oldCard     = 108

ai_audited_aliases.register{id="ai_skill_invoke.se_erdao_old",registry="ai_skill_invoke",path={"se_erdao_old"},canonical_registry="ai_skill_invoke",canonical_path={"se_erdao"},self_index=1,defer_canonical=true}
sgs.ai_skill_invoke.SE_Qiehuan_K = function(self, data)
	if (pq(self,"isWeak",self.player)) or (pq(self.player,"getHp") < pq(self,"getBestHp",self.player)) then return true end
	return false
end
sgs.ai_skill_invoke.SE_Qiehuan_A = function(self, data)
	if (pq(self,"isWeak",self.player)) or (pq(self.player,"getHp") < pq(self,"getBestHp",self.player)) then return true end
	return false
end



local se_chouyuan_skill = {}
se_chouyuan_skill.name = "se_chouyuan"
table.insert(package_skills, se_chouyuan_skill)
se_chouyuan_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or pq(self.player,"getMark","@hates") < 1 then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if pq(player,"getHp") >= 2 then
			too_weak = false
		end
	end
	if too_weak then return end
	local lord = call(self.room,"getLord")
	if viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" or viewer_role(self,self.player) == "rebel" then
		return parse(self,request,"#se_chouyuancard:.:")
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends + 1 >= #self.enemies and (pq(self.player,"getHp") >= 3 or pq(lord,"getHp") >= 3) then return end
		if #self.friends >= #self.enemies and (pq(self.player,"getHp") >= 2 or pq(lord,"getHp") >= 2) then return end
		return parse(self,request,"#se_chouyuancard:.:")
	end
end


sgs.ai_skill_use_func["#se_chouyuancard"] = function(card,use,self,request)
	local target
	sort_players(self,self.enemies, "defense")
	local lord = call(self.room,"getLord")
	if viewer_role(self,self.player) == "rebel" then
		target = lord
	end
	if viewer_role(self,self.player) == "loyalist" or viewer_role(self,self.player) == "lord" then
		for _, enemy in ipairs(self.enemies) do
			if enemy then
				target = enemy
			end
		end
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends == #self.enemies then
			for _, enemy in ipairs(self.enemies) do
				if viewer_role(self,enemy) == "rebel" and enemy then
					target = enemy
				end
			end
		end
		if #self.friends + 1 == #self.enemies then
			for _, enemy in ipairs(self.enemies) do
				if enemy then
					target = enemy
				end
			end
		end
		if pq(lord,"getHp") <= 2 then
			for _, enemy in ipairs(self.enemies) do
				if viewer_role(self,enemy) == "rebel" and enemy then
					target = enemy
				end
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_chouyuancard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_cardneed.SE_Qixin                  = function(to, card, self)
	return pq(card,"isKindOf","Slash")
end

sgs.ai_use_value["se_chouyuancard"]       = 8
sgs.ai_use_priority["se_chouyuancard"]    = 8
sgs.ai_card_intention["se_chouyuancard"]  = 108

sgs.ai_skill_invoke.SE_Qixin              = function(self, data)
	return true
end



sgs.ai_skill_choice.SE_Qixin              = function(self, choices, data)
	local target = pq(self.player,"getRoom"):getCurrent()
	if pq(self,"isFriend",target) then
		local slashs = pq(self,"getCards","Slash")
		if #slashs == 0 then
			return "Qixin_setcard"
		end
		return "Qixin_slashto"
	end
	return "Qixin_setcard"
end

sgs.ai_skill_playerchosen.SE_Qixin        = function(self, targets)
	return call(self,"findPlayerToDraw",true, 1)
end

















local se_shunshan_skill = {}
se_shunshan_skill.name = "se_shunshan"
table.insert(package_skills, se_shunshan_skill)
se_shunshan_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or pq(self.player,"hasFlag","se_shunshan_used") then return end
	return parse(self,request,"#se_shunshancard:.:")
end


sgs.ai_skill_use_func["#se_shunshancard"] = function(card,use,self,request)
	local target
	if #self.enemies < 1 then return end
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"isAlive") and call(enemy,"getDefensiveHorse") and call(self.player,"getOffensiveHorse") and pq(enemy,"getMark","@Stop") > 0 then
			target = enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"isAlive") and call(enemy,"getDefensiveHorse") and call(self.player,"getOffensiveHorse") and pq(enemy,"getMark","@Stop") == 0 then
			target = enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"isAlive") and not call(enemy,"getDefensiveHorse") and pq(enemy,"getMark","@Stop") > 0 then
			target = enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"isAlive") and not call(enemy,"getDefensiveHorse") and pq(enemy,"getMark","@Stop") == 0 then
			target = enemy
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_shunshancard:.:")
		local next_people = pq(target,"getNextAlive")
		if use.to then call(use.to,"append",next_people) end
		return
	end
end

sgs.ai_use_value["se_shunshancard"]       = 8
sgs.ai_use_priority["se_shunshancard"]    = 7

sgs.ai_skill_playerchosen.se_shunshan     = function(self, targets)
	for _, p in sgs.qlist(targets) do
		if pq(self,"isEnemy",p) and pq(p,"getMaxCards") > 0 then return p end
	end
	for _, p in sgs.qlist(targets) do
		if pq(self,"isEnemy",p) then return p end
	end
	return pq(targets,"first")
end

sgs.ai_playerchosen_intention.se_shunshan = 100




local se_chongjing_skill = {}
se_chongjing_skill.name = "se_chongjing"
table.insert(package_skills, se_chongjing_skill)
se_chongjing_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends < 1 or pq(self.player,"getMark","@longing") < 1 then return end
	local no_sister = true
	for _, player in ipairs(self.friends) do
		if not pq(player,"isMale") and pq(player,"objectName") ~= pq(self.player,"objectName") then
			no_sister = false
		end
	end
	local mikoto_unknown = false
	local list = pq(self.room,"getAlivePlayers")
	for _, player in sgs.qlist(list) do
		if pq(player,"getGeneralName") == "Mikoto" then
			if not pq(self,"isFriend",player) and not pq(self,"isEnemy",player) then
				mikoto_unknown = true
			end
		end
	end
	if no_sister or mikoto_unknown then return end
	local lord = call(self.room,"getLord")
	if viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" or viewer_role(self,self.player) == "rebel" then
		return parse(self,request,"#se_chongjingcard:.:")
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends + 1 >= #self.enemies and (pq(self.player,"getHp") >= 3 or pq(lord,"getHp") >= 3) then return end
		if #self.friends >= #self.enemies and (pq(self.player,"getHp") >= 2 or pq(lord,"getHp") >= 2) then return end
		return parse(self,request,"#se_chongjingcard:.:")
	end
end


sgs.ai_skill_use_func["#se_chongjingcard"] = function(card,use,self,request)
	local target = nil
	sort_players(self,self.friends, "defense")
	local lord = call(self.room,"getLord")
	if viewer_role(self,self.player) == "rebel" or viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" then
		for _, friend in ipairs(self.friends) do
			if not pq(friend,"isMale") and pq(friend,"objectName") ~= pq(self.player,"objectName") then
				target = friend
			end
		end
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends == #self.enemies then
			for _, friend in ipairs(self.friends) do
				if viewer_role(self,friend) == "lord" and not pq(friend,"isMale") and pq(friend,"objectName") ~= pq(self.player,"objectName") then
					target = friend
				end
			end
		end
		if #self.friends + 1 <= #self.enemies then
			for _, friend in ipairs(self.friends) do
				if (viewer_role(self,friend) == "lord" or viewer_role(self,friend) == "rebel") and not pq(friend,"isMale") and pq(friend,"objectName") ~= pq(self.player,"objectName") then
					target = friend
				end
			end
		end
		if pq(lord,"getHp") <= 2 then
			for _, friend in ipairs(self.friends) do
				if viewer_role(self,friend) == "lord" and not pq(friend,"isMale") and pq(friend,"objectName") ~= pq(self.player,"objectName") then
					target = friend
				end
			end
		end
	end
	if viewer_role(self,self.player) == "loyalist" then
		if not pq(lord,"isMale") then
			target = lord
		end
	end
	if viewer_role(self,self.player) == "rebel" or viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" then
		for _, friend in ipairs(self.friends) do
			if pq(friend,"getGeneralName") == "Mikoto" then
				target = friend
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_chongjingcard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_chongjingcard"]       = 8
sgs.ai_use_priority["se_chongjingcard"]    = 8
sgs.ai_card_intention["se_chongjingcard"]  = -100

sgs.ai_skill_invoke.se_chongjing_Attack    = function(self, data)
	local damage = pq(data,"toDamage")
	local victim = damage.to
	local source = damage.from
	if pq(self,"isEnemy",victim) or pq(self,"isEnemy",source) then
		return true
	end
end


local se_jieshu_skill = {}
se_jieshu_skill.name                       = "se_jieshu"
table.insert(package_skills, se_jieshu_skill)
se_jieshu_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends < 1 then return end
	local target = false
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getMark","@Stop") > 0 then
			target = true
		end
	end
	if not target then return end
	if target then
		return parse(self,request,"#se_jieshucard:.:")
	end
end


sgs.ai_skill_use_func["#se_jieshucard"] = function(card,use,self,request)
	local target
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getMark","@Stop") > 0 then
			target = friend
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_jieshucard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_jieshucard"]       = 6
sgs.ai_use_priority["se_jieshucard"]    = 4
sgs.ai_card_intention["se_jieshucard"]  = -50


sgs.ai_skill_invoke.dai                 = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.dai           = function(self, targets)
	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	local target = self.player

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1])) and arr1[1]:getHp() < pq(self,"getBestHp",arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not pq(friend,"hasSkills","hunzi|longhun") then
				return friend
			end
		end
	end


	return target 
end



sgs.ai_playerchosen_intention.dai = function(from, to)
	local intention = -60
	call(self,"updateIntention",from, to, intention)
end

sgs.ai_skill_invoke.daiVS = function(self, data)
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	if pq(self.player,"getMark","@daiwei") < 2 then return false end
	if pq(self,"isFriend",source) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.daiVS = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"getCurrentDyingPlayer")
		if target then call(self,"updateIntention",player,target,-50) end
	end
end


sgs.save_skill = sgs.save_skill .. "|dai"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|dai"
sgs.priority_skill = sgs.priority_skill .. "|dai"

sgs.ai_skill_invoke.zhuchang = function(self, data)
	local target = pq(data,"toPlayer")
	if pq(self,"isFriend",target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.zhuchang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|zhuchang"
sgs.priority_skill = sgs.priority_skill .. "|zhuchang"






local se_tianming_skill = {}
se_tianming_skill.name = "se_tianming"
table.insert(package_skills, se_tianming_skill)
se_tianming_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = pq(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	for _, card in ipairs(cards) do
		if pq(card,"isKindOf","Slash") then
			return
		end
	end
	if pq(self,"slashIsAvailable") and pq(self.player,"getMark","@Tianming") >= 12 then
		local card_str = string.format("slash:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		return parse(self,request,card_str)
	end
end

function sgs.ai_cardsview_valuable.se_tianming(self, class_name, player)
	if pq(player,"getPhase") ~= sgs.Player_NotActive or pq(self.player,"getMark","@Tianming") < 12 then return end
	if class_name == "Slash"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pq(self.player,"getMark","@Tianming") >= 12
	then
		local slashs = {}
		for _, c in sgs.qlist(pq(player,"getCards","h")) do
			if pq(c,"isKindOf","Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			return string.format("slash:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		end
	elseif class_name == "Jink"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pq(self.player,"getMark","@Tianming") >= 17
	then
		local jinks = {}
		for _, c in sgs.qlist(pq(player,"getCards","h")) do
			if pq(c,"isKindOf","Jink") then
				table.insert(jinks, c)
			end
		end
		if #jinks == 0 then
			return string.format("jink:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		end
	elseif class_name == "Nullification"
		and pq(self.player,"getMark","@Tianming") >= 23
	then
		local Nullifications = {}
		for _, c in sgs.qlist(pq(player,"getCards","h")) do
			if pq(c,"isKindOf","Nullification") then
				table.insert(Nullifications, c)
			end
		end
		if #Nullifications == 0 then
			return string.format("Nullification:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		end
	end
end

local se_jianwu_skill = {}
se_jianwu_skill.name = "se_jianwu"
table.insert(package_skills, se_jianwu_skill)
se_jianwu_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"getMark","@Tianming") < 130 then return end
	if #self.enemies < 2 then return end
	return parse(self,request,"#se_jianwucard:.:")
end

sgs.ai_skill_use_func["#se_jianwucard"] = function(card,use,self,request)
	local targets = AIList.new({})
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy and pq(targets,"length") < 3 and pq(enemy,"faceUp") then
			call(targets,"append",enemy)
		end
	end
	if pq(targets,"length") >= 1 then
		use.card=final_parse(self,request,"#se_jianwucard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["se_jianwucard"]    = 6
sgs.ai_card_intention["se_jianwucard"]  = 100

local se_kanhu_skill = {}
se_kanhu_skill.name                     = "se_kanhu"
table.insert(package_skills, se_kanhu_skill)
se_kanhu_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"hasUsed","#se_kanhucard") then return end
	if pq(source,"getMark","@Tianming") < 20 then return end
	local target = 0
	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	if #arr1 > 0 and (pq(self,"isWeak",arr1[1])) and arr1[1]:getHp() < pq(self,"getBestHp",arr1[1]) then target = 1 end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not pq(friend,"hasSkills","hunzi|longhun") then
				target = 1
			end
		end
	end
	
	if target == 1 then
		return parse(self,request,"#se_kanhucard:.:")
	end
end

sgs.ai_skill_use_func["#se_kanhucard"] = function(card,use,self,request)
	local target

	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	local target = self.player

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1])) and arr1[1]:getHp() < pq(self,"getBestHp",arr1[1]) then target = arr1[1] end
	if target then
		use.card=final_parse(self,request,"#se_kanhucard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not pq(friend,"hasSkills","hunzi|longhun") then
				target = friend
				break
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_kanhucard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
	
end

sgs.ai_use_value["#se_kanhucard"]       = 6
sgs.ai_use_priority["#se_kanhucard"]    = 9
sgs.ai_card_intention["#se_kanhucard"]  = -100



sgs.ai_skill_invoke.SE_Xianjing  = function(self, data)
	local damage = pq(data,"toDamage")
	local source = damage.from
	if not pq(self,"isFriend",source) then
		return true
	end
	return false
end

sgs.ai_can_damagehp.SE_Xianjing  = function(self, from, card, to)
	if from and pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0
		and pq(self,"canLoseHp",from, card, to)
	then
		return pq(self,"isEnemy",from)
	end
end



sgs.ai_skill_invoke["SE_Boming"] = function(self, data)
	if pq(self.player,"getMark","@HIMIKO") == 0 then return false end
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	if pq(self,"isFriend",source) then
		local skill_list = pq(self.player,"getVisibleSkillList")
		local i = 0
		local boming_skill_list = { "yingzi", "shensu", "fankui", "longdan", "paoxiao", "guicao" }
		for _, skill in sgs.qlist(skill_list) do
			if pq(skill,"objectName") ~= "SE_Boming" and pq(skill,"objectName") ~= "SE_Xianjing" and pq(skill,"objectName") ~= "SE_BomingGet"
				and table.contains(boming_skill_list, pq(skill,"objectName")) then
				i = i + 1
			end
		end
		if i == 0 then return false end
		if pq(source,"objectName") == pq(self.player,"objectName") then return true end
		if viewer_role(self,self.player) == "renegade" then
			if pq(source,"objectName") ~= pq(self.player,"objectName") and viewer_role(self,source) ~= "lord" then return false end
		end
		if i == 1 and #self.friends > 2 then return false end
		if i >= 2 then return true end
		return false
	end
end

sgs.ai_canNiepan_skill.SE_Boming = function(player)
	if pq(player,"getMark","@HIMIKO") > 0
		and (pq(player,"hasSkill","yingzi") or
			pq(player,"hasSkill","shensu") or
			pq(player,"hasSkill","fankui") or
			pq(player,"hasSkill","longdan") or
			pq(player,"hasSkill","paoxiao") or
			pq(player,"hasSkill","guicao")) 
	then return true end
end



local se_qiyuan_skill = {}
se_qiyuan_skill.name             = "se_qiyuan"
table.insert(package_skills, se_qiyuan_skill)
se_qiyuan_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"getMark","@se_qiyuan") == 0 then return end
	local room = pq(source,"getRoom")
	local deathplayer = {}
	for _, p in sgs.qlist(pq(room,"getPlayers")) do
		if pq(p,"isDead") and pq(p,"getMaxHp") >= 2 then
			table.insert(deathplayer, pq(p,"getGeneralName"))
		end
	end
	if #deathplayer == 0 then return end
	if #deathplayer > 0 then
		return parse(self,request,"#se_qiyuancard:.:")
	end
end

sgs.ai_skill_use_func["#se_qiyuancard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#se_qiyuancard:.:")
	return
end

sgs.ai_use_value["se_qiyuancard"] = 8
sgs.ai_use_priority["se_qiyuancard"] = 7

sgs.ai_skill_choice["se_qiyuan"] = function(self, choices, data)
	local source = self.player
	local room = pq(source,"getRoom")
	local maxHpMax = 2
	local theP
	for _, p in sgs.qlist(pq(room,"getPlayers")) do
		if pq(p,"isDead") and pq(p,"getMaxHp") >= 2 then
			if pq(p,"getMaxHp") > maxHpMax then
				maxHpMax = pq(p,"getMaxHp")
				theP = p
			end
		end
	end
	if theP then return theP end
	local choice_table = pq(choices,"split","+")
	return choice_table[1]
end

sgs.ai_event_callback[sgs.CardFinished or "CardFinished"].se_qiyuancard = function(self, player, data)
	local use = pq(data,"toCardUse")
	if use.card and pq(use.card,"objectName") == "se_qiyuancard" then
		local room = pq(player,"getRoom")
		for _, sb in sgs.qlist(pq(room,"getOtherPlayers",player)) do
			if pq(sb,"hasFlag","se_qiyuan_ed") then
				
				role_write(self,"se_qiyuancard",sb,sb,true)
			end
		end
	end
end


sgs.ai_skill_invoke.Lichang = function(self, data)
	local isUse = pq(data,"toStringList")[3] == "use"
	local use 
	if isUse then
		if pq(data,"toStringList")[4] then 
			use = tag(self,"UseHistory"..pq(data,"toStringList")[4]):toCardUse()
		end
	end
	if pq(self.player,"hasFlag","dahe") then return false  end
	if isUse then
		if use.card and pq(use.card,"hasFlag","NosJiefanUsed") then return false  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or pq(use.card,"isKindOf","NatureSlash") and  pq(self.player,"isChained") and pq(self,"isGoodChainTarget", self.player,use.card,use.from)
		or pq(self,"needToLoseHp", self.player,use.from,use.card) and pq(self,"ajustDamage",use.from, self.player,1,use.card)==1 then return false end
	end
	
	if pq(self,"getCardsNum","Jink") == 0 then return true end
	if pq(self,"needToLoseHp", self.player, use.from, use.card, true) then return false  end
	if pq(self,"ajustDamage",use.from, self.player,1,use.card)>1 then return true end
	
	return true
end




local se_shouren_skill = {}
se_shouren_skill.name = "se_shouren"
table.insert(package_skills, se_shouren_skill)
se_shouren_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"hasUsed","#se_shourencard") then return end
	if #self.enemies == 0 then return end
	return parse(self,request,"#se_shourencard:.:")
end

sgs.ai_skill_use_func["#se_shourencard"] = function(card,use,self,request)
	local target
	local minHp = 100
	for _, enemy in ipairs(self.enemies) do
		local hp = pq(enemy,"getHp")
		if pq(self,"hasSkills",sgs.masochism_skill, enemy) then hp = hp - 1 end
		if hp < minHp and not pq(self,"hasZhaxiangEffect",enemy) then
			minHp = hp
			target = enemy
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_shourencard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_shourencard"]       = 8
sgs.ai_use_priority["se_shourencard"]    = 2
sgs.ai_card_intention["se_shourencard"]  = 60

sgs.ai_skill_choice.Pifu_Kanade          = function(self, data)
	local x = math.random(1, 3)
	if x == 1 then
		return "Kanade_1"
	elseif x == 2 then
		return "Kanade_2"
	else
		return "Kanade_3"
	end
end




sgs.ai_skill_invoke.Zizhu = function(self, data)
	return true
end
sgs.ai_skill_invoke.Chaidao = function(self)
	if pq(self.player,"hasFlag","DimengTarget") then
		local another
		for _, player in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
			if pq(player,"hasFlag","DimengTarget") then
				another = player
				break
			end
		end
		if not another or not pq(self,"isFriend",another) then return false end
	end
	return not pq(self,"needKongcheng",self.player, true)
end

sgs.ai_skill_askforag.Chaidao = function(self, card_ids)
	if pq(self,"needKongcheng",self.player, true) then return card_ids[1] else return -1 end
end
sgs.ai_skill_invoke.Keai = function(self)
	if pq(self.player,"hasFlag","DimengTarget") then
		local another
		for _, player in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
			if pq(player,"hasFlag","DimengTarget") then
				another = player
				break
			end
		end
		if not another or not pq(self,"isFriend",another) then return false end
	end
	return not pq(self,"needKongcheng",self.player, true)
end

sgs.ai_skill_askforag.Keai = function(self, card_ids)
	if pq(self,"needKongcheng",self.player, true) then return card_ids[1] else return -1 end
end
sgs.ai_can_damagehp.Zizhu = function(self,from,card,to)
	return pq(to,"getHp")+pq(self,"getAllPeachNum")-pq(self,"ajustDamage",from,to,1,card)>0
	and pq(self,"canLoseHp",from,card,to) and pq(self,"getEnemyNumBySeat",call(self.room,"getCurrent"),self.player,self.player,true)>pq(self.room,"getAlivePlayers"):length()/2
end



local se_shengjian_skill = {}
se_shengjian_skill.name = "se_shengjian"
table.insert(package_skills, se_shengjian_skill)
se_shengjian_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if pq(source,"hasUsed","#se_shengjiancard") then return end
	local power = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		local force = math.abs(pq(source,"getEquips"):length() - pq(enemy,"getEquips"):length()) + (pq(enemy,"getEquips"):length()) /
			2
		if force > power then
			if pq(self,"objectiveLevel",enemy) > 3 and not pq(self,"cantbeHurt",enemy) and pq(self,"damageIsEffective",enemy) and not pq(self,"cantDamageMore",self.player, enemy) and pq(self,"canDamage",enemy,self.player,nil) then
				if not pq(enemy,"hasSkills",sgs.lose_equip_skill) and pq(self,"damageIsEffective",enemy, nil, self.player) then
					target = enemy
					power = force
				end
			end
		end
	end
	if not target then return end
	if power < 2 then return end
	if target and power >= 2 then
		return parse(self,request,"#se_shengjiancard:.:")
	end
end

sgs.ai_skill_use_func["#se_shengjiancard"] = function(card,use,self,request)
	local target
	local source = self.player
	local power = 0
	for _, enemy in ipairs(self.enemies) do
		local force = math.abs(pq(source,"getEquips"):length() - pq(enemy,"getEquips"):length()) + (pq(enemy,"getEquips"):length()) /
			3
		if force > power then
			if pq(self,"objectiveLevel",enemy) > 3 and not pq(self,"cantbeHurt",enemy) and pq(self,"damageIsEffective",enemy) and not pq(enemy,"hasArmorEffect","silver_lion")  and pq(self,"canDamage",enemy,self.player,nil) then
				if not pq(enemy,"hasSkills",sgs.lose_equip_skill) and pq(self,"damageIsEffective",enemy, nil, self.player) then
					target = enemy
					power = force
				end
			end
		end
	end
	if target and power >= 3 then
		use.card=final_parse(self,request,"#se_shengjiancard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_shengjiancard"]       = 8
sgs.ai_use_priority["se_shengjiancard"]    = 5
sgs.ai_card_intention.se_shengjiancard     = 90

ai_audited_aliases.register{id="ai_cardneed.se_shengjian",registry="ai_cardneed",path={"se_shengjian"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}
sgs.ai_skill_invoke.Yuyue                  = function(self, data)
	return true
end



sgs.ai_skill_playerchosen.Xianhai = function(self, targets)
	local target = tag(self,"CurrentDamageStruct"):toDamage().to
	if target and pq(target,"getHp") <= 1 then
		if pq(self,"isFriend",target) then
			if viewer_role(self,target) == "rebel" then
				for _, friend in ipairs(self.friends_noself) do
					if friend then
						target = friend
					end
				end
			elseif viewer_role(self,target) == "loyalist" then
				for _, enemy in ipairs(self.enemies) do
					if enemy then
						target = enemy
					end
				end
			end
		elseif not pq(self,"isFriend",target) then
			if viewer_role(self,target) == "rebel" then
				if not pq(self,"hasSkills",sgs.exclusive_skill, target) then
					for _, friend in ipairs(self.friends_noself) do
						if friend then
							target = friend
						end
					end
				end
			elseif viewer_role(self,target) == "loyalist" then
				target = call(self.room,"getLord")
			end
		end
	end
	if target then return target end
	return nil
end



local se_zhuren_skill = {}
se_zhuren_skill.name = "se_zhuren"
table.insert(package_skills, se_zhuren_skill)
se_zhuren_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends <= 1 then return end
	local source = self.player
	if pq(source,"isKongcheng") then return end
	if pq(source,"hasUsed","#se_zhurencard") then return end
	return parse(self,request,"#se_zhurencard:.:")
end

sgs.ai_skill_use_func["#se_zhurencard"]   = function(card,use,self,request)
	local target
	local source = self.player
	local max_num = pq(source,"getMaxHp") - pq(source,"getHp") + 1
	local max_x = 0

	for _, friend in ipairs(self.friends_noself) do
		local x = 5 - pq(friend,"getHandcardNum")
		if x > max_x and not pq(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) then
			max_x = x
			target = friend
		end
	end
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local needed = {}
	for _, acard in ipairs(cards) do
		if #needed < max_num then
			table.insert(needed, pq(acard,"getEffectiveId"))
		end
	end
	if target and needed then
		use.card=final_parse(self,request,"#se_zhurencard:" .. table.concat(needed, "+") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_zhurencard"]         = 4
sgs.ai_use_priority["se_zhurencard"]      = 1
sgs.ai_card_intention["se_zhurencard"]    = -60

sgs.ai_skill_choice.Daolu                 = function(self, data)
	local lord = call(self.room,"getLord")
	if pq(self.player,"getHp") > 0 then return "daolu_cancel" end
	if viewer_role(self,self.player) == "lord" then
		for _, friend in ipairs(self.friends) do
			if pq(self,"isWeak",friend) and pq(friend,"objectName") ~= pq(self.player,"objectName") then
				return "Fuko_summoner"
			end
		end
		return "Nagisa_Protector"
	elseif viewer_role(self,self.player) == "loyalist" then
		return "Tomoyo_Couple"
	elseif viewer_role(self,self.player) == "rebel" then
		for _, friend in ipairs(self.friends) do
			if pq(self,"isWeak",friend) and pq(self.player,"getHp") > 2 and pq(friend,"objectName") ~= pq(self.player,"objectName") then
				
				if math.random(1, 2) == 1 then
					return "Fuko_summoner"
				else
					return "Tomoyo_Couple"
				end
			end
		end
		if math.random(1, 2) == 1 then
			return "Fuko_summoner"
		else
			return "Tomoyo_Couple"
		end
	elseif viewer_role(self,self.player) == "renegade" then
		if pq(lord,"getHp") <= 2 or pq(self,"isWeak",self.player) then
			return "Fuko_summoner"
		end
		return "Nagisa_Protector"
	end
end

sgs.ai_skill_playerchosen.se_diangong     = function(self, targets)
	targets = AIList.new(targets)
	local target
	sort_players(self,self.friends, "hp")
	for _, friend in ipairs(targets) do
		if pq(self,"isFriend",friend) then
			target = friend
		end
	end
	if target then return target end
	return nil
end

sgs.ai_playerchosen_intention.se_diangong = function(from, to)
	local intention = -50
	call(self,"updateIntention",from, to, intention)
end

sgs.ai_skill_playerchosen.Shouyang_st     = function(self, targets)
	local target
	local lord = call(self.room,"getLord")
	if viewer_role(self,self.player) == "loyalist" then return lord end
	if viewer_role(self,self.player) == "rebel" then
		for _, friend in ipairs(self.friends) do
			if not pq(friend,"objectName") ~= pq(self.player,"objectName") and pq(self,"isWeak",friend) and pq(self.player,"getHp") > 2 then
				target = friend
			end
		end
	end
	if target then return target end
	for _, friend in ipairs(self.friends) do
		if not pq(friend,"objectName") ~= pq(self.player,"objectName") then
			target = friend
		end
	end
	return target
end

sgs.ai_playerchosen_intention.Shouyang_st = function(from, to)
	local intention = -100
	call(self,"updateIntention",from, to, intention)
end

sgs.ai_ajustdamage_to.Shouyang_ed         = function(self, from, to, card, nature)
	if pq(to,"getMark","@Tomoyo") > 0
	then
		for _, p in sgs.list(pq(self.room,"getOtherPlayers",to)) do
			if pq(p,"hasSkill","Shouyang")
			then
				return pq(self,"ajustDamage",from, p, 0, card, nature)
			end
		end
	end
end

sgs.ai_skill_defense.Shouyang_ed = function(self, player)
	local defense = 0
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",player)) do
		if pq(p,"hasSkill","Shouyang") then
			defense = defense + pq(p,"getHp")
			break
		end
	end
	return defense
end


local se_diangong_skill = {}
se_diangong_skill.name  = "se_diangong"
table.insert(package_skills, se_diangong_skill)
se_diangong_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	for _, acard in ipairs(cards) do
		if pq(self,"getKeepValue",acard) < 4 and pq(acard,"isBlack") then
			local number = pq(acard,"getNumberString")
			local card_id = pq(acard,"getEffectiveId")
			local suit = pq(acard,"getSuitString")
			return parse(self,request,("lightning:se_diangong[%s:%s]=%d"):format(suit, number, card_id))
		end
	end
end
sgs.ai_use_value["se_diangong"]          = 8
sgs.ai_use_priority["se_diangong"]       = 2.5

sgs.ai_ajustdamage_to["se_diangong"]     = function(self, from, to, card, nature)
	if card and pq(card,"isKindOf","Lightning") then
		return -99
	end
end
sgs.ai_ajustdamage_to["se_diangong_def"] = function(self, from, to, card, nature)
	if card and pq(card,"isKindOf","Lightning") then
		return -99
	end
end

sgs.ai_skill_invoke.Shouyang             = function(self, data)
	return true
end
sgs.save_skill = sgs.save_skill .. "|Haixing"
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|Haixing"
sgs.ai_skill_invoke.Haixing              = function(self, data)
	return true
end

sgs.ai_skill_discard["Haixing"]          = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = AIList.new(pq(self.player,"getCards","h"))
	local target = call(self.room,"getCurrentDyingPlayer")
	if target and pq(self,"isFriend",target) then
		sort_keep(self,usable_cards)
		local to_discard = {}
		for _, c in ipairs(usable_cards) do
			if #to_discard < discard_num and not pq(c,"isKindOf","Peach") then
				table.insert(to_discard, pq(c,"getEffectiveId"))
			end
		end
		if #to_discard > 0 then
			return to_discard
		end
	end
	return {}
end

sgs.ai_skill_defense.se_Fanshe = function(self, player)
	return pq(player,"getCards","he"):length()
end

sgs.ai_skill_discard["se_Fanshe"] = function(self, discard_num, min_num, optional, include_equip)
	local damage = tag(self,"FansheDamage"):toDamage()
	local usable_cards = AIList.new(pq(self.player,"getCards","eh"))
	local target = damage.from
	if (target and not pq(self,"isFriend",target)) or not target then
		sort_keep(self,usable_cards)
		local to_discard = {}
		for _, c in ipairs(usable_cards) do
			if #to_discard < discard_num and not pq(c,"isKindOf","Peach") then
				table.insert(to_discard, pq(c,"getEffectiveId"))
			end
		end
		if #to_discard > 0 then
			return to_discard
		end
	end
	return {}
end

sgs.ai_skill_choice["Heiyi-discard"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	if #items == 1 then
		return items[1]
	else
		return items[#items]
	end
end

sgs.ai_skill_playerchosen.Heiyi = function(self, targets)
	return call(self,"findPlayerToDiscard","hej", true, true, targets, false)[1]
end

function sgs.ai_slash_prohibit.se_Fanshe(self, from, to)
	if pq(from,"hasSkill","jueqing") or (pq(from,"hasSkill","nosqianxi") and pq(from,"distanceTo",to) == 1) then return false end
	if pq(from,"hasFlag","NosJiefanUsed") then return false end
	if pq(self,"isFriend",to, from) then return false end
	return pq(self,"cantbeHurt",to, from)
end

local se_bianhua_skill = {}
se_bianhua_skill.name = "se_bianhua"
table.insert(package_skills, se_bianhua_skill)
se_bianhua_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"usedTimes","#se_bianhuaCard") >= 5 then return end
	local cards = AIList.new(pq(self.player,"getCards","he"))
	sort_keep(self,cards)
	for _, card1 in ipairs(cards) do
		if not pq(card1,"isKindOf","Peach") then
			return parse(self,request,"#se_bianhuaCard:" .. pq(card1,"getEffectiveId") .. ":")
		end
	end
end

sgs.ai_skill_use_func["#se_bianhuaCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_invoke["se_Baiyi"]       = function(self, data)
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	local lord = call(self.room,"getLord")
	if lord and pq(self,"isWeak",lord) and viewer_role(self,self.player) == "loyalist" then
		if pq(lord,"objectName") == pq(source,"objectName") then
			return true
		else
			return false
		end
	end
	if pq(self,"isWeak",self.player) and pq(source,"objectName") ~= pq(self.player,"objectName") then
		return false
	end
	for _, player in ipairs(self.friends) do
		if pq(player,"isAlive") and source and pq(source,"objectName") == pq(player,"objectName") then
			return true
		end
	end
	if pq(source,"objectName") == pq(self.player,"objectName") then
		return true
	end
	return false
end






local se_jianyu_skill = {}
se_jianyu_skill.name = "se_jianyu"
table.insert(package_skills, se_jianyu_skill)
se_jianyu_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_jianyucard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#se_jianyucard:.:")
end

sgs.ai_skill_use_func["#se_jianyucard"] = function(card,use,self,request)
	local targets = AIList.new({})
	local slash = call(self,"cloneEvaluationCard","slash")
	
	sort_players(self,self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if pq(targets,"length") < pq(self.player,"getMaxHp") - pq(self.player,"getHp") + 1 and not pq(enemy,"inMyAttackRange",self.player) and pq(self,"slashIsEffective",slash, enemy, self.player) and pq(self,"isGoodTarget",enemy, self.enemies, slash) then
			call(targets,"append",enemy)
		end
	end
	if pq(targets,"length") < pq(self.player,"getMaxHp") - pq(self.player,"getHp") + 1 then
		for _, enemy1 in ipairs(self.enemies) do
			if pq(targets,"length") < pq(self.player,"getMaxHp") - pq(self.player,"getHp") + 1 and pq(enemy1,"inMyAttackRange",self.player) and pq(self,"slashIsEffective",slash, enemy1, self.player) then
				call(targets,"append",enemy1)
			end
		end
	end
	if pq(targets,"length") > 0 then
		use.card=final_parse(self,request,"#se_jianyucard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["se_jianyucard"]       = 8
sgs.ai_use_priority["se_jianyucard"]    = 2
sgs.ai_card_intention["se_jianyucard"]  = 100

sgs.hit_skill = sgs.hit_skill .. "|SE_Juji"

sgs.ai_canliegong_skill.SE_Juji = function(self, from, to)
	return pq(from,"getPhase") == sgs.Player_Play and not pq(to,"inMyAttackRange",from)
end


sgs.ai_skill_invoke.se_qidian           = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen["se_qidian"]  = function(self, targets)
	local target
	targets = AIList.new(targets)
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(targets) do
		if enemy and pq(self,"isEnemy",enemy)
			and pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder, self.player)
			and not pq(self,"cantbeHurt",enemy) and pq(self,"canDamage",enemy,self.player,nil) then
			target = enemy
			break
		end
	end
	if target then return target end
	return false
end

sgs.ai_playerchosen_intention.se_qidian = 80


sgs.se_qidian_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

function sgs.ai_cardneed.se_qidian(to, card, self)
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

sgs.ai_skill_cardask["#se_qidian"] = function(self, data)
	local judge = pq(data,"toJudge")

	if pq(self.room,"getMode"):find("_mini_46") and not pq(judge,"isGood") then return "$" .. pq(self.player,"handCards"):first() end
	if pq(self,"needRetrial",judge) then
		local cards = AIList.new(pq(self.player,"getCards","he"))
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

sgs.wizard_skill = sgs.wizard_skill .. "|se_qidian"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|se_qidian"




local se_zhiyu_skill = {}
se_zhiyu_skill.name = "se_zhiyu"
table.insert(package_skills, se_zhiyu_skill)
se_zhiyu_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends <= 1 then return end
	if pq(self.player,"isKongcheng") then return end
	local invoke = false
	for _, card in sgs.qlist(pq(self.player,"getHandcards")) do
		if pq(card,"isKindOf","EquipCard") then
			invoke = true
			break
		end
		if pq(card,"getSuit") == sgs.Card_Heart then
			if pq(self.player,"isWounded") then
				invoke = true
				break
			else
				if pq(self.player,"getHandcardNum") > pq(self.player,"getHp") then
					invoke = true
					break
				end
			end
		end
	end
	if not invoke then return end
	return parse(self,request,"#se_zhiyucard:.:")
end
















































































































































sgs.ai_skill_use_func["#se_zhiyucard"] = function(card,use,self,request)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	local notFound
	for i = 1, #cards do
		local card, friend = call(self,"getCardNeedPlayer",cards)
		if card and friend then
			table.removeOne(cards, card)
		else
			notFound = true
			break
		end
		if pq(friend,"objectName") == pq(self.player,"objectName")
			or not pq(self.player,"getHandcards"):contains(card) or
			not (pq(card,"getSuit") == sgs.Card_Heart or pq(card,"isKindOf","EquipCard"))
		then
			continue
		end
		if pq(card,"isAvailable",self.player)
		then
			if pq(card,"isKindOf","Slash") and pq(card,"getSuit") == sgs.Card_Heart
			then
				local dummy_use = pq(self,"aiUseCard",card)
				if dummy_use.card
				then
					local t1 = pq(dummy_use.to,"first")
					if pq(dummy_use.to,"length") > 1 then
						continue
					elseif pq(t1,"getHp") < 2 or getCardsNum("Jink", t1, self.player) < 1
						or pq(t1,"isCardLimited",call(self,"cloneEvaluationCard","jink"), sgs.Card_MethodResponse)
					then
						continue
					end
				end
			elseif (pq(card,"isKindOf","Snatch") or pq(card,"isKindOf","Dismantlement")) and pq(card,"getSuit") == sgs.Card_Heart
				and pq(self,"getEnemyNumBySeat",self.player, friend) > 0
			then
				local dummy_use = pq(self,"aiUseCard",card)
				if dummy_use.card
				then
					local hasDelayedTrick
					for _, p in sgs.list(dummy_use.to) do
						if pq(self,"isFriend",p) and (pq(self,"willSkipDrawPhase",p) or pq(self,"willSkipPlayPhase",p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			elseif pq(card,"isKindOf","DelayedTrick") and pq(card,"getSuit") == sgs.Card_Heart
				and pq(self,"getEnemyNumBySeat",self.player, friend) > 0
				and pq(self,"aiUseCard",card).card
			then
				continue
			end
		end
		if pq(friend,"hasSkill","enyuan") and #cards >= 1
			and not (pq(self.room,"getMode") == "04_1v3")
		then
			use.card=final_parse(self,request,"#se_zhiyucard:" .. pq(card,"getId") .. "+" .. cards[1]:getId() .. ":")
		else
			use.card=final_parse(self,request,"#se_zhiyucard:" .. pq(card,"getId") .. ":")
		end
		if use.to then call(use.to,"append",friend) end
		return
	end
	if notFound and ((pq(self,"isWeak")
		and pq(self.player,"getHandcardNum") > 3) or (pq(self,"getOverflow") > 0))
	then
		cards = AIList.new(pq(self.player,"getHandcards"))
		sort_use(self,cards, true)
		for _, p in sgs.list(pq(self.room,"getOtherPlayers",self.player)) do
			if not pq(self,"isFriend",p) and hasManjuanEffect(p)
			then
				local to_give = {}
				for _, card in ipairs(cards) do
					if not isCard("Peach", card, self.player) and (pq(card,"getSuit") == sgs.Card_Heart or pq(card,"isKindOf","EquipCard"))
					then
						table.insert(to_give, pq(card,"getId"))
					end
					if pq(card,"getSuit") == sgs.Card_Heart or pq(card,"isKindOf","EquipCard") then break end
				end
				if #to_give > 0 then
					use.card=final_parse(self,request,"#se_zhiyucard:" .. table.concat(to_give, "+") .. ":")
					if use.to then
						call(use.to,"append",p)
						break
					end
				end
			end
		end
	end
end

sgs.ai_use_value["se_zhiyucard"]       = 8
sgs.ai_use_priority["se_zhiyucard"]    = 9.7
sgs.ai_card_intention["se_zhiyucard"]  = -60

local se_liaoli_skill = {}
se_liaoli_skill.name                   = "se_liaoli"
table.insert(package_skills, se_liaoli_skill)
se_liaoli_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends == 0 then return end
	if pq(self.player,"hasUsed","#se_liaolicard") then return end
	if pq(self.player,"isKongcheng") then return end
	local invoke = false
	local Card_H_Num = 0
	for _, card in sgs.qlist(pq(self.player,"getHandcards")) do
		if pq(card,"getSuit") ~= sgs.Card_Heart then
			Card_H_Num = Card_H_Num + 1
			if not pq(self.player,"isWounded") then
				invoke = true
				break
			end
			for _, friend in ipairs(self.friends) do
				if pq(friend,"getJudgingArea"):length() > 0 then
					invoke = true
					break
				end
			end
		end
	end
	if Card_H_Num > pq(self.player,"getMaxHp") - pq(self.player,"getHp") then
		invoke = true
	end
	if not invoke then return end
	return parse(self,request,"#se_liaolicard:.:")
end

sgs.ai_skill_use_func["#se_liaolicard"] = function(card,use,self,request)
	local target
	local card_to
	local judge_num = 0
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getJudgingArea"):length() > judge_num and pq(friend,"getMark","@se_liaoli") == 0 then
			target = friend
			judge_num = pq(friend,"getJudgingArea"):length()
		end
	end
	if not target then
		local handcard_num = 0
		for _, friend in ipairs(self.friends) do
			if pq(friend,"getHandcardNum") > handcard_num and pq(friend,"getMark","@se_liaoli") == 0 then
				target = friend
				handcard_num = pq(friend,"getHandcardNum")
			end
		end
	end
	if not target and pq(self.player,"getMark","@se_liaoli") == 0 then target = self.player end
	local hcard = pq(self.player,"getHandcards")
	local cards = AIList.new(hcard)
	sort_use(self,cards, true)
	card_to = cards[1]
	if target and card_to then
		use.card=final_parse(self,request,"#se_liaolicard:" .. pq(card_to,"getEffectiveId") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_liaolicard"]       = 9
sgs.ai_use_priority["se_liaolicard"]    = 9.8
sgs.ai_card_intention["se_liaolicard"]  = -100

sgs.ai_skill_invoke.se_zhiyu            = function(self, data)
	return true
end


sgs.ai_need_damaged.SE_Maoqun           = function(self, attacker)
	return pq(self.player,"getHp") > 10
end

sgs.SE_Maoqun_keep_value                =
{
	Peach     = 9,
	Analeptic = 8,
	Jink      = 9,
}



local se_zhiling_skill = {}
se_zhiling_skill.name = "se_zhiling"
table.insert(package_skills, se_zhiling_skill)

se_zhiling_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if pq(self.player,"getPile","Neko"):length() == 0 then return end
	local can = false
	for _, enemy in ipairs(self.enemies) do
		if (pq(enemy,"getMark","@Neko_S") == 0 or pq(enemy,"getMark","@Neko_C") == 0 or (pq(enemy,"getMark","@Neko_D") == 0 and not pq(enemy,"hasSkill","Huansha")) or pq(enemy,"getMark","@Neko_H") == 0) and not pq(enemy,"hasFlag","Can_not") then
			can = true
		end
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.enemies - #self.friends <= 0 then
			can = false
		end
		if pq(self.player,"getPile","Neko"):length() <= 8 and #self.enemies - #self.friends <= 1 then
			can = false
		end
		if pq(self.player,"getPile","Neko"):length() <= 3 and #self.enemies - #self.friends <= 2 then
			can = false
		end
	end
	if not can then return end
	return parse(self,request,"#se_zhilingcard:.:")
end

sgs.ai_skill_use_func["#se_zhilingcard"] = function(card,use,self,request)
	local target
	local lord = call(self.room,"getLord")
	for _, enemy in ipairs(self.enemies) do
		if ((pq(enemy,"getMark","@Neko_S") == 0) or (pq(enemy,"getMark","@Neko_C") == 0) or ((pq(enemy,"getMark","@Neko_D") == 0) and not pq(enemy,"hasSkill","Huansha")) or (pq(enemy,"getMark","@Neko_H") == 0)) and not pq(enemy,"hasFlag","Can_not") then
			target = enemy
		end
	end
	if viewer_role(self,self.player) == "rebel" then
		if (pq(lord,"getMark","@Neko_S") == 0 or pq(lord,"getMark","@Neko_C") == 0 or (pq(lord,"getMark","@Neko_D") == 0 and not pq(lord,"hasSkill","Huansha")) or pq(lord,"getMark","@Neko_H") == 0) and not pq(lord,"hasFlag","Can_not") then
			target = lord
		end
	end
	if target then
		local cardsq
		for _, id in sgs.qlist(pq(self.player,"getPile","Neko")) do
			local card = disclosed(self,id)
			local suit = pq(card,"getSuitString")
			local card_id = pq(card,"getEffectiveId")
			if (pq(target,"getMark","@Neko_S") == 0) or (pq(target,"getMark","@Neko_C") == 0) or (pq(target,"getMark","@Neko_D") == 0) or (pq(target,"getMark","@Neko_H") == 0) then
				if ((pq(target,"getMark","@Neko_S") == 0) and (suit == "spade")) or ((pq(target,"getMark","@Neko_C") == 0) and (suit == "club")) or ((pq(target,"getMark","@Neko_D") == 0) and (suit == "diamond")) or ((pq(target,"getMark","@Neko_H") == 0) and (suit == "heart")) then
					cardsq = card
				end
			end
		end
		if cardsq then
			local card_str = string.format("#se_zhilingcard:%s:", pq(cardsq,"getEffectiveId"))
			local acard = parse(self,request,card_str)
			use.card = acard
			if use.to then call(use.to,"append",target) end
			return
		end
	end
end

sgs.ai_use_value["se_zhilingcard"]       = 9
sgs.ai_use_priority["se_zhilingcard"]    = 9.8
sgs.ai_card_intention["se_zhilingcard"]  = 50

sgs.ai_ajustdamage_to["@Neko_D"] = function(self, from, to, card, nature)
	if nature~="N"
	then
		return 1
	end
end

sgs.save_skill = sgs.save_skill .. "|SE_Zhixing"

sgs.ai_skill_playerchosen.SE_Zhixing = function(self, targets)
	local dyingwho = call(self.room,"getCurrentDyingPlayer")
	if not pq(self,"isFriend",dyingwho) then return nil end
	local target
	local targets = AIList.new(targets)
	for _, friend in ipairs(targets) do
		if pq(friend,"isMale") and pq(friend,"getHandcardNum") <= 2 and pq(self,"isFriend",friend) then
			target = friend
			break
		end
	end
	if not target then
		for _, enemy in ipairs(targets) do
			if pq(enemy,"isMale") and not pq(enemy,"isKongcheng") and pq(self,"isEnemy",enemy) then
				target = enemy
				break
			end
		end
	end
	if target then return target end
	return nil
end

sgs.ai_cardshow.SE_Zhixing = function(self, requestor)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	if pq(self,"isFriend",requestor) then
		for _, card in ipairs(cards) do
			if pq(card,"getSuit") == sgs.Card_Diamond then return card end
		end
	end
	if pq(self,"isFriend",requestor) then
		for _, card in ipairs(cards) do
			if pq(card,"getSuit") == sgs.Card_Heart then return card end
		end
	end
	return pq(self.player,"getRandomHandCard")
end


sgs.ai_skill_playerchosen.SE_Zhihui = function(self, targets)
	local target
	local dmg = tag(self,"SE_Zhihui"):toDamage()
	local targets = AIList.new(targets)
	sort_players(self,targets, "hp")


	for _, friend in ipairs(targets) do
		if friend and pq(self,"isFriend",friend) and (pq(friend,"getLostHp") + dmg.damage > 1 and pq(friend,"isAlive")) then
			if pq(friend,"isChained") and dmg.nature ~= sgs.DamageStruct_Normal and not pq(self,"isGoodChainTarget",friend, dmg.from, dmg.nature, dmg.damage, dmg.card) then
			elseif pq(friend,"getHp") >= 2 and dmg.damage < 2
				and (pq(friend,"hasSkills","yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
					or pq(self,"canAttack",friend, dmg.from or call(self.room,"getCurrent"))
					or pq(self,"needToLoseHp",friend)
					or (pq(friend,"getHandcardNum") < 3 and (pq(friend,"hasSkill","nosrende") or (pq(friend,"hasSkill","rende") and not pq(friend,"hasUsed","RendeCard"))))) then
				return friend
			elseif dmg.card and pq(dmg.card,"getTypeId") == sgs.Card_TypeTrick and pq(friend,"hasSkill","wuyan") and pq(friend,"getLostHp") > 1 then
				return friend
			elseif hasBuquEffect(friend) then
				return friend
			end
		end
	end

	return nil
end

sgs.ai_skill_defense.SE_Zhihui = function(self, player)
	local defense = 0
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",player)) do
		if pq(p,"getMark","@Geass") > 0 then
			defense = defense + 1
		end
	end
	return defense
end

local SE_Geass_skill = {}
SE_Geass_skill.name = "SE_Geass"
table.insert(package_skills, SE_Geass_skill)

SE_Geass_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	local can = true
	local role = viewer_role(self,self.player)
	local list = pq(self.room,"getOtherPlayers",self.player)
	local self_people = 1
	if role == "lord" then
		for _, p in sgs.qlist(list) do
			if viewer_role(self,p) == "loyalist" then
				self_people = self_people + 1
			end
		end
	elseif role == "rebel" then
		for _, p in sgs.qlist(list) do
			if viewer_role(self,p) == "rebel" then
				self_people = self_people + 1
			end
		end
	end
	if self_people >= pq(list,"length") / 2 then
		can = false
	end
	if not can then return end
	return parse(self,request,"#SE_GeassCard:.:")
end

sgs.ai_skill_use_func["#SE_GeassCard"] = function(card,use,self,request)
	local target

	local list = pq(self.room,"getOtherPlayers",self.player)
	list = AIList.new(list)
	sort_players(self,list, "hp")
	for _, p in ipairs(list) do
		if pq(p,"getMark","@Geass") == 0 then
			target = p
		end
	end
	if target then
		local card_str = "#SE_GeassCard:.:"

		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then
			
			role_write(self,"SE_Geass",target,target,false)
			call(use.to,"append",target)
		end
		return
	end
end

sgs.ai_use_value["SE_GeassCard"]       = 9
sgs.ai_use_priority["SE_GeassCard"]    = 9.8



sgs.ai_skill_invoke.SE_Zhuzhen_Trick = function(self, data)
	if #self.friends_noself > 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.SE_Zhuzhen_Trick = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","se_erdao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","Xuwu") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","jizhi") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkills",sgs.cardneed_skill) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getHp") > 2 then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend then
			return friend
		end
	end
	return targets[1]
end


sgs.ai_skill_invoke.SE_Zhuzhen_Equip = function(self, data)
	if pq(self.player,"getPhase") == sgs.Player_NotActive then
		return true
	else
		if #self.friends_noself > 0 then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.SE_Zhuzhen_Equip = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","Zhudao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","se_zhiyu") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","se_erdao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","xuanfeng") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","xiaoji") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkills",sgs.lose_equip_skill) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getHp") > 2 then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend then
			return friend
		end
	end
	return targets[1]
end

sgs.ai_skill_playerchosen.SE_Zhuzhen_Equip_Out = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","Zhudao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","se_zhiyu") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","se_erdao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","xuanfeng") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"hasSkill","xiaoji") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if pq(friend,"getHp") > 2 then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend then
			return friend
		end
	end
	return targets[1]
end

function sgs.ai_cardneed.SE_Zhuzhen(to,card)
	return pq(card,"isNDTrick") or pq(card,"isKindOf","EquipCard")
end



sgs.ai_skill_invoke.SE_Mengfeng = function(self, data)
	if #self.friends == 1 then return false end
	if pq(self.player,"getMaxCards") <= 0 then return false end
	if pq(self.player,"hasFlag","WangzunDecMaxCards") and pq(self.player,"getHp") <= 1 then return false end

	
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local shouldUse, range_fix = 0, 0
	local hasCrossbow, slashTo = false, false
	for _, card in ipairs(cards) do
		if pq(card,"isKindOf","TrickCard") and pq(self,"getUseValue",card) > 3.69 then
			local dummy_use = pq(self,"aiUseCard",card, dummy())
			if dummy_use.card then shouldUse = shouldUse + (pq(card,"isKindOf","ExNihilo") and 2 or 1) end
		end
		if pq(card,"isKindOf","Weapon") then
			local new_range = sgs.weapon_range[pq(card,"getClassName")] or 0
			local current_range = pq(self.player,"getAttackRange")
			range_fix = math.min(current_range - new_range, 0)
		end
		if pq(card,"isKindOf","OffensiveHorse") and not call(self.player,"getOffensiveHorse") then range_fix = range_fix - 1 end
		if pq(card,"isKindOf","DefensiveHorse") or pq(card,"isKindOf","Armor") and not call(self,"getSameEquip",card) and (pq(self,"isWeak") or pq(self,"getCardsNum","Jink") == 0) then
			shouldUse =
				shouldUse + 1
		end
		if pq(card,"isKindOf","Crossbow") or pq(self,"hasCrossbowEffect") then hasCrossbow = true end
	end

	local slashs = pq(self,"getCards","Slash")
	for _, enemy in ipairs(self.enemies) do
		for _, slash in ipairs(slashs) do
			if hasCrossbow and pq(self,"getCardsNum","Slash") > 1 and pq(self,"slashIsEffective",slash, enemy)
				and pq(self.player,"canSlash",enemy, slash, true, range_fix) then
				shouldUse = shouldUse + 2
				hasCrossbow = false
				break
			elseif not slashTo and pq(self,"slashIsAvailable") and pq(self,"slashIsEffective",slash, enemy)
				and pq(self.player,"canSlash",enemy, slash, true, range_fix) and getCardsNum("Jink", enemy) < 1 then
				shouldUse = shouldUse + 1
				slashTo = true
			end
		end
	end
	if shouldUse >= 2 then return false end


	if role_count(self,"rebel") then
		local lord = call(self.room,"getLord")
		if lord and pq(self,"isFriend",lord) then
			return true
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) then
		return true
	end

	sort_players(self,self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, target in ipairs(self.friends_noself) do
		if not pq(target,"hasSkill","dawu") and pq(target,"hasSkills","yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not pq(self,"willSkipPlayPhase",target) or pq(target,"hasSkill","shensu")) then
			return true
		end
	end

	for _, target in ipairs(self.friends_noself) do
		if pq(target,"hasSkill","dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if pq(p,"getMark","@fog") > 0 then
					use = false
					break
				end
			end
			if use then
				return true
			end
		else
			return true
		end
	end
	return false
end



sgs.ai_skill_playerchosen.SE_Mengfeng = function(self, data)
	if role_count(self,"rebel") then
		local lord = call(self.room,"getLord")
		if lord and pq(self,"isFriend",lord) and pq(lord,"objectName") ~= pq(self.player,"objectName") and pq(lord,"getHp")+pq(self,"getAllPeachNum") - 1 > 0 then
			return lord
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) and pq(self,"isFriend",AssistTarget) and pq(AssistTarget,"getHp")+pq(self,"getAllPeachNum") - 1 > 0 then
		return AssistTarget
	end

	sort_players(self,self.friends_noself, "chaofeng")
	for _, target in ipairs(self.friends_noself) do
		if not pq(target,"hasSkill","dawu") and pq(target,"hasSkills","yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not pq(self,"willSkipPlayPhase",target) or pq(target,"hasSkill","shensu")) and pq(target,"getHp")+pq(self,"getAllPeachNum") - 1 > 0  then
			return target
		end
	end

	for _, target in ipairs(self.friends_noself) do
		if pq(target,"hasSkill","dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if pq(p,"getMark","@fog") > 0 then
					use = false
					break
				end
			end
			if use then
				return target
			end
		else
			return target
		end
	end
end
sgs.ai_playerchosen_intention.SE_Mengfeng = -80
sgs.ai_skill_choice.SE_Mengfeng = function(self, choices, data)
	local dest = pq(data,"toPlayer")
	if not pq(dest,"faceUp") then
		return "TurnOver_target"
	end
	return "LoseHp_target"
end

sgs.ai_skill_playerchosen.SE_Nagong_Geiqian = function(self, targets)
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if pq(self,"isFriend",target) and pq(target,"isAlive") then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.SE_Nagong_Geiqian = -50

sgs.ai_skill_use["@@SE_Nagong_Geiqian"] = function(self, prompt)
	call(self,"updatePlayers")
	
	if not pq(self.player,"isWounded") then return "." end
	if pq(self.player,"getHandcardNum") < 2 then return "." end
	local reimu = call(self.room,"findPlayerBySkillName","SE_Nagong")
	if not reimu then return "." end
	if pq(self,"needKongcheng",reimu, true) or hasManjuanEffect(reimu) then
		return "."
	end
	local give_all_cards = {}
	for _, c in ipairs(AIList.new(pq(self.player,"getCards","h"))) do
		if #give_all_cards < 2 then
			table.insert(give_all_cards, pq(c,"getEffectiveId"))
		end
	end
	if reimu and pq(self,"isFriend",reimu) and #give_all_cards > 1 then
		return "#SE_Nagong_Geiqian:" .. table.concat(give_all_cards, "+") .. ":->" .. pq(reimu,"objectName")
	end
	return "."
end





sgs.ai_skill_invoke.SE_Yishi = function(self, data)
	for _, p in ipairs(self.friends) do
		if pq(p,"isMale") then
			return true
		end
	end
	return false
end
sgs.ai_playerchosen_intention.SE_Yishi = -80
sgs.ai_skill_playerchosen.SE_Yishi = function(self, targets)
	local lord = call(self.room,"getLord")
	for _, p in ipairs(self.friends) do
		if pq(p,"isMale") and pq(p,"objectName") == pq(lord,"objectName") then
			return p
		end
	end
	local hp = 0
	local max_man
	local hp_min = 100
	local min_man
	for _, p in ipairs(self.friends) do
		if pq(p,"isMale") and pq(p,"getHp") > hp then
			hp = pq(p,"getHp")
			max_man = p
		end
		if pq(p,"isMale") and pq(p,"getHp") < hp_min then
			hp_min = pq(p,"getHp")
			min_man = p
		end
	end
	if hp_min == 1 then return min_man end
	if max_man then
		return max_man
	else
		return nil
	end
end

local se_dushe_skill = {}
se_dushe_skill.name = "se_dushe"
table.insert(package_skills, se_dushe_skill)
se_dushe_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(self.player,"hasFlag","se_dushecard") then return end
	if #self.enemies < 1 or pq(self.player,"isKongcheng") then return end
	local can_man = false
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHandcardNum") > 0 then
			can_man = true
		end
	end
	if not can_man then return end
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local OK = false
	for _, card in ipairs(cards) do
		if pq(card,"getNumber") > 8 then
			OK = true
		end
	end
	if OK then
		return parse(self,request,"#se_dushecard:.:")
	end
end

sgs.ai_skill_use_func["#se_dushecard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#se_dushecard:.:")
	return
end

sgs.ai_playerchosen_intention.se_dushecard = 60
sgs.ai_skill_playerchosen.se_dushecard = function(self, targets)
	local B
	local R
	for _, card in sgs.qlist(pq(self.player,"getHandcards")) do
		if pq(card,"isBlack") then B = true end
		if pq(card,"isRed") then R = true end
	end
	if B then
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"isAlive") and not pq(enemy,"isKongcheng") and not pq(enemy,"hasSkill","tuntian") and not (pq(enemy,"getHandcardNum") == 1 and pq(enemy,"hasSkill","kongcheng")) then
				if pq(enemy,"getEquips"):length() > 2 then
					dushe_flag(self,enemy,"se_dushe_Equip",true)
					return enemy
				end
			end
		end
	end
	if R then
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"isAlive") and not pq(enemy,"isKongcheng") and not pq(enemy,"hasSkill","tuntian") and not (pq(enemy,"getHandcardNum") == 1 and pq(enemy,"hasSkill","kongcheng")) then
				if pq(enemy,"getHp") == 1 or pq(enemy,"getHp") == 2 then
					dushe_flag(self,enemy,"se_dushe_Dm",true)
					return enemy
				end
			end
		end
	end
	if B then
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"isAlive") and not pq(enemy,"isKongcheng") and not pq(enemy,"hasSkill","tuntian") and not (pq(enemy,"getHandcardNum") == 1 and pq(enemy,"hasSkill","kongcheng")) then
				if pq(enemy,"getEquips"):length() > 1 then
					dushe_flag(self,enemy,"se_dushe_Equip",true)
					return enemy
				end
			end
		end
	end
	if R then
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"isAlive") and not pq(enemy,"isKongcheng") and not pq(enemy,"hasSkill","tuntian") and not (pq(enemy,"getHandcardNum") == 1 and pq(enemy,"hasSkill","kongcheng")) then
				dushe_flag(self,enemy,"se_dushe_Dm",true)
				return enemy
			end
		end
	end
end

sgs.ai_skill_pindian["se_dushecard"] = function(minusecard, self, requestor, maxcard, mincard)
	return maxcard
end

sgs.ai_skill_choice.se_dushecard = function(self, choices, data)
	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if dushe_flag(self,p,"se_dushe_Equip") then return "se_dushe_Discard" end
		if dushe_flag(self,p,"se_dushe_Dm") then return "se_dushe_Damage" end
	end
	return false
end

sgs.ai_skill_cardask["se_dushe_invoke"] = function(self, data, pattern, target, target2)
	local handcards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if dushe_flag(self,target,"se_dushe_Dm") then
			if not pq(c,"isKindOf","Peach") then
				table.insert(give_cards, c)
				break
			end
		end
		if dushe_flag(self,target,"se_dushe_Equip") then
			table.insert(give_cards, c)
			break
		end
	end
	if #give_cards > 0 then
		return give_cards[1]
	end
	return "."
end
sgs.ai_skill_cardask["se_dushe_Damage"] = function(self, data, pattern, target, target2)
	local handcards = AIList.new(pq(self.player,"getCards","h"))
	sort_keep(self,handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if pq(c,"isRed") then
			table.insert(give_cards, c)
			break
		end
	end
	if #give_cards > 0 then
		return give_cards[1]
	end
	return "."
end

ai_audited_aliases.register{id="ai_cardneed.se_dushe",registry="ai_cardneed",path={"se_dushe"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
sgs.ai_use_priority["se_dushecard"]   = 4
sgs.ai_card_intention["se_dushecard"] = 80



sgs.ai_skill_invoke.SE_Kurimu = function(self, data)
	return true
end

sgs.ai_skill_invoke.SE_Minatsu = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_invoke.SE_Chizuru = function(self, data)
	return true
end

sgs.ai_skill_invoke.SE_Mafuyu = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_playerchosen_intention.SE_Kurimu = -40
sgs.ai_skill_playerchosen.SE_Kurimu = function(self, targets)
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getHandcardNum") < 3 and pq(friend,"objectName") ~= pq(self.player,"objectName") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends) do
		if pq(friend,"objectName") ~= pq(self.player,"objectName") then
			return friend
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention.SE_Minatsu = 60
sgs.ai_skill_playerchosen.SE_Minatsu = function(self, targets)
	if #self.enemies == 0 then return nil end
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		local def = pq(self,"getDefenseSlash",enemy)
		local slash = call(self,"cloneEvaluationCard","fire_slash")
		
		local eff = pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)

		if not pq(self.player,"canSlash",enemy, slash, false) then
		elseif pq(self,"slashProhibit",nil, enemy) then
		elseif def < 6 and eff then
			return enemy
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.SE_Chizuru = -80
sgs.ai_skill_playerchosen.SE_Chizuru = function(self, targets)
	local arr1, arr2 = pq(self,"getWoundedFriend",false, true)
	local target = nil

	if #arr1 > 0 and (pq(self,"isWeak",arr1[1])) and arr1[1]:getHp() < pq(self,"getBestHp",arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2>0 then
		for _,friend in ipairs(arr2)do
			return friend
		end
	end
	
	
	return nil
end

sgs.ai_playerchosen_intention.SE_Mafuyu = 80
sgs.ai_skill_playerchosen.SE_Mafuyu = function(self, targets)
	local card_num = 0
	local target
	if #self.enemies == 0 then return self.player end
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHandcardNum") - pq(enemy,"getHp") > card_num and pq(enemy,"getMark","@SE_Mafuyu") == 0 then
			target = enemy
			card_num = pq(enemy,"getHandcardNum") - pq(enemy,"getHp")
		end
	end
	if target then
		return target
	end
	for _, enemy in ipairs(self.enemies) do
		if  pq(enemy,"getMark","@SE_Mafuyu") == 0 then
			return enemy
		end
	end
	return self.enemies[1]
end

sgs.ai_hasTuntianEffect_skill.SE_Kurimu = function(to, need_zaoxian)
	return pq(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_hasTuntianEffect_skill.SE_Minatsu = function(to, need_zaoxian)
	return pq(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_hasTuntianEffect_skill.SE_Chizuru = function(to, need_zaoxian)
	return pq(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_hasTuntianEffect_skill.SE_Mafuyu = function(to, need_zaoxian)
	return pq(to,"getPhase") == sgs.Player_NotActive
end



local se_xunyu_skill = {}
se_xunyu_skill.name = "se_xunyu"
table.insert(package_skills, se_xunyu_skill)
se_xunyu_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	if pq(self.player,"isKongcheng") then return end
	local cards = AIList.new(pq(self.player,"getHandcards"))
	if pq(self.player,"getMark","@SE_Chaopin_Red") > 0 then
		if pq(self.player,"hasUsed","#se_xunyucard") then return end
		return parse(self,request,"#se_xunyucard:.:")
	end
	local card_OK = false
	for _, acard in ipairs(cards) do
		if not pq(acard,"isKindOf","Jink") and not pq(acard,"isKindOf","Peach") and not pq(acard,"isKindOf","Analeptic") then
			card_OK = true
		end
	end
	if not card_OK then return end
	if pq(self.player,"getMark","@SE_Chaopin_Blue") > 0 then
		if pq(self.player,"usedTimes","#se_xunyucard") >= 3 then return end
	elseif pq(self.player,"getMark","@SE_Chaopin_Blue") == 0 then
		if pq(self.player,"hasUsed","#se_xunyucard") then return end
	end
	if pq(self.player,"getMark","@SE_Chaopin_Green") > 0 then return end
	for _, enemy in ipairs(self.enemies) do
		local slash = call(self,"cloneEvaluationCard","slash")
		
		if pq(self.player,"inMyAttackRange",enemy) and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(self.player,"canSlash",enemy, slash, false) and not pq(self,"slashProhibit",nil, enemy) then
			return parse(self,request,"#se_xunyucard:.:")
		end
	end
end

sgs.ai_skill_use_func["#se_xunyucard"] = function(card,use,self,request)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_use(self,cards, true)
	local target
	local card
	local slash = call(self,"cloneEvaluationCard","slash")
	
	if pq(self.player,"getMark","@SE_Chaopin_Red") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not pq(self,"hasSkills",sgs.masochism_skill, enemy) then
				target = enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not pq(self,"hasSkills",sgs.masochism_skill, enemy) and pq(enemy,"getHp") == 1 and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(self.player,"canSlash",enemy, slash, false) and not pq(self,"slashProhibit",nil, enemy) then
				target = enemy
			end
		end
		if not target then target = self.enemies[1] end
		use.card=final_parse(self,request,"#se_xunyucard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
	for _, acard in ipairs(cards) do
		if not pq(acard,"isKindOf","Jink") and not pq(acard,"isKindOf","Peach") and not pq(acard,"isKindOf","Analeptic") then
			card = acard
		end
	end
	if pq(self.player,"getMark","@SE_Chaopin_Blue") > 0 then
		card = cards[1]
	end
	local min_people
	local min_Hp = 100
	for _, enemy in ipairs(self.enemies) do
		if not pq(self,"hasSkills",sgs.masochism_skill, enemy) and pq(self.player,"inMyAttackRange",enemy) and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(self.player,"canSlash",enemy, slash, false) and not pq(self,"slashProhibit",nil, enemy) then
			if pq(enemy,"getHp") <= min_Hp then
				min_people = enemy
				min_Hp = pq(enemy,"getHp")
			end
		end
	end
	if pq(self.player,"getMark","@SE_Chaopin_Blue") > 0 then
		local min_Hp = 100
		for _, enemy in ipairs(self.enemies) do
			if pq(self.player,"inMyAttackRange",enemy) and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(self.player,"canSlash",enemy, slash, false) and not pq(self,"slashProhibit",nil, enemy) then
				if pq(enemy,"getHp") <= min_Hp then
					min_people = enemy
					min_Hp = pq(enemy,"getHp")
				end
			end
		end
		local min_Hp = 100
		for _, enemy in ipairs(self.enemies) do
			if not pq(self,"hasSkills",sgs.masochism_skill, enemy) and pq(self.player,"inMyAttackRange",enemy) and pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash) and pq(self.player,"canSlash",enemy, slash, false) and not pq(self,"slashProhibit",nil, enemy) then
				if pq(enemy,"getHp") <= min_Hp then
					min_people = enemy
					min_Hp = pq(enemy,"getHp")
				end
			end
		end
	end
	target = min_people
	if target and card then
		use.card=final_parse(self,request,"#se_xunyucard:" .. pq(card,"getEffectiveId") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_xunyucard"]       = 9
sgs.ai_use_priority["se_xunyucard"]    = 3.2
sgs.ai_card_intention["se_xunyucard"]  = 80



sgs.ai_skill_invoke.SE_Chaopin = function(self, data)
	return true
end

sgs.ai_skill_choice.SE_Chaopin = function(self, choices, data)
	local weak = #self.enemies - #self.friends
	local can_Slash = false
	for _, enemy in ipairs(self.enemies) do
		if pq(self.player,"inMyAttackRange",enemy) then
			can_slash = true
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHp") == 1 then
			if pq(self.player,"inMyAttackRange",enemy) then
				if pq(self.player,"getHandcardNum") < 2 then
					return "SE_Chaopin_Red"
				else
					return "SE_Chaopin_Blue"
				end
			else
				return "SE_Chaopin_Red"
			end
		end
	end
	if weak == 1 then 
		if pq(self.player,"getHandcardNum") < 2 then return "SE_Chaopin_Green" end
		if pq(self.player,"getHandcardNum") < 4 then return "SE_Chaopin_Red" end
		if not can_slash then return "SE_Chaopin_Red" end
		return "SE_Chaopin_Blue"
	elseif weak > 1 then
		if pq(self.player,"getHandcardNum") < 5 then return "SE_Chaopin_Green" end
		if not can_slash then return "SE_Chaopin_Green" end
		return "SE_Chaopin_Blue"
	elseif weak == 0 or weak == -1 then
		if pq(self.player,"getHandcardNum") < 3 then return "SE_Chaopin_Green" end
		if pq(self.player,"getHandcardNum") < 5 then return "SE_Chaopin_Red" end
		if not can_slash then return "SE_Chaopin_Red" end
		return "SE_Chaopin_Blue"
	elseif weak < -1 then
		if pq(self.player,"getHandcardNum") < 5 then return "SE_Chaopin_Green" end
		if not can_slash then return "SE_Chaopin_Green" end
		return "SE_Chaopin_Blue"
	end
end




sgs.SE_Qifen_keep_value =
{
	Peach     = 9,
	Analeptic = 8,
}

sgs.ai_skill_invoke.SE_Qifen = function(self, data)
	if pq(self.player,"getHp") < pq(self.player,"getMaxHp") then return true end
	if pq(self.player,"getHp") == pq(self.player,"getMaxHp") then
		if #self.friends >= #self.enemies then return true end
	end
	return false
end


sgs.ai_getBestHp_skill.SE_Qifen = function(owner)
	return pq(owner,"getMaxHp") - 1
end

sgs.ai_skill_invoke.SE_Mishi = function(self, data)
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	local good
	if not pq(self,"isFriend",source) then
		good = true
	end
	if not good then return false end
	local peach_num = 0
	local jink_num = 0
	for _, card in sgs.qlist(pq(self.player,"getHandcards")) do
		if pq(card,"isKindOf","Peach") or pq(card,"isKindOf","Analeptic") then
			peach_num = peach_num + 1
		end
		if pq(card,"isKindOf","Jink") then
			jink_num = jink_num + 1
		end
	end
	if good then
		if pq(self.player,"getHp") > 0 and peach_num > 2 then return true end
		if pq(self.player,"getHp") > 0 and peach_num > 1 and jink_num > 0 then return true end
		if pq(self.player,"getHp") > 1 and peach_num > 1 then return true end
		if pq(self.player,"getHp") > 1 and peach_num > 0 and jink_num > 0 then return true end
		if pq(self.player,"getHp") > 2 and peach_num > 0 then return true end
		if pq(self.player,"getHp") > 2 and jink_num > 0 then return true end
	end
	return false
end


sgs.ai_skill_invoke.SE_Zhufu = function(self, data)
	if #self.friends <= 1 then return false end
	return true
end

sgs.ai_playerchosen_intention.SE_Zhufu = -60
sgs.ai_skill_playerchosen.SE_Zhufu = function(self, targets)
	local max_num = 0
	local good_to
	for _, friend in ipairs(self.friends) do
		if pq(self.player,"getHandcardNum") - pq(friend,"getHandcardNum") > max_num and pq(friend,"objectName") ~= pq(self.player,"objectName") and pq(self,"canDraw",friend, self.player) then
			good_to = friend
			max_num = pq(self.player,"getHandcardNum") - pq(friend,"getHandcardNum")
		end
	end
	if good_to then return good_to end
	for _, friend in ipairs(self.friends) do
		if pq(friend,"objectName") ~= pq(self.player,"objectName") and pq(self,"canDraw",friend, self.player) then
			return friend
		end
	end
	return nil
end






sgs.ai_skill_playerchosen.SE_Xiuse = function(self, targets)
	call(self,"updatePlayers")
	
	local targets = AIList.new(targets)
	sort_players(self,targets, "handcard")
	local target = nil
	local n = pq(self.player,"getHp")
	for _, friend in ipairs(targets) do
		if not pq(friend,"faceUp") and pq(self,"isFriend",friend) then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(targets) do
			if not pq(self,"toTurnOver",friend, n, "SE_Xiuse") and pq(self,"isFriend",friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = call(self,"findPlayerToDraw",false, n)
			if not target then
				for _, enemy in ipairs(targets) do
					if pq(self,"toTurnOver",enemy, n, "SE_Xiuse") and hasManjuanEffect(enemy) and pq(self,"isEnemy",enemy) then
						target = enemy
						break
					end
				end
			end
		else
			sort_players(self,self.enemies)
			for _, enemy in ipairs(targets) do
				if pq(self,"toTurnOver",enemy, n, "SE_Xiuse") and hasManjuanEffect(enemy) and pq(self,"isEnemy",enemy) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(targets) do
					if pq(self,"toTurnOver",enemy, n, "SE_Xiuse") and pq(self,"hasSkills",sgs.priority_skill, enemy) and pq(self,"isEnemy",enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(targets) do
					if pq(self,"toTurnOver",enemy, n, "SE_Xiuse") and pq(self,"isEnemy",enemy) then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end

sgs.ai_need_damaged.SE_Xiuse = function(self, attacker, player)
	if not pq(player,"hasSkill","SE_Xiuse") then return false end
	local enemies = pq(self,"getEnemies",player)
	if #enemies < 1 then return false end
	sort_players(self,enemies, "defense")
	for _, enemy in ipairs(enemies) do
		if pq(player,"getLostHp") < 1 and pq(self,"toTurnOver",enemy, pq(player,"getHp") - 1, "SE_Xiuse") then
			return true
		end
	end
	local friends = pq(self,"getFriends",player, true)
	sort_players(self,friends, "defense")
	for _, friend in ipairs(friends) do
		if not pq(self,"toTurnOver",friend, pq(player,"getHp") - 1, "SE_Xiuse") then return true end
	end
	return false
end


sgs.ai_playerchosen_intention.SE_Xiuse = function(self, from, to)
	if hasManjuanEffect(to) then call(self,"updateIntention",from, to, 80) end
	local intention = 80 / math.max(pq(from,"getHp"), 1)
	if not pq(self,"toTurnOver",to, pq(from,"getHp"), "SE_Xiuse") then intention = -intention end
	if pq(from,"getHp") < 3 then
		call(self,"updateIntention",from, to, intention)
	else
		call(self,"updateIntention",from, to, math.min(intention, -30))
	end
end

sgs.ai_skill_invoke.SE_Shuanglang = function(self, data)
	local target = pq(data,"toPlayer")
	if target and pq(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.SE_Shuanglang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,50) end
	end
end




sgs.ai_playerchosen_intention.SE_Lianmu = -60
sgs.ai_skill_playerchosen.SE_Lianmu     = function(self, targets)
	local list = pq(self.room,"getAlivePlayers")

	local min_Hp = 100
	local target
	for _, friend in sgs.qlist(targets) do
		if pq(self,"isFriend",friend) and pq(friend,"getHp") < min_Hp then
			min_Hp = pq(friend,"getHp")
			target = friend
		end
	end
	if target then return target end
	return nil
end



sgs.ai_skill_invoke.SE_Feiti            = function(self, data)
	local list = pq(self.room,"getAlivePlayers")
	local targets = AIList.new({})
	for _, p in sgs.qlist(list) do
		if pq(p,"isMale") then
			call(targets,"append",p)
		end
	end
	if pq(targets,"length") > 0 then return true end
	return false
end

sgs.ai_skill_playerchosen.SE_Feiti      = function(self, targets)
	local list = pq(self.room,"getAlivePlayers")
	local targets = AIList.new({})
	for _, p in sgs.qlist(list) do
		if pq(p,"isMale") then
			call(targets,"append",p)
		end
	end
	for _, p in sgs.qlist(targets) do
		if pq(self,"isFriend",p) and pq(p,"hasSkill","SE_Shuanglang") then
			return p
		end
	end
	local card_num = 100
	local target
	for _, p in sgs.qlist(targets) do
		if pq(self,"isFriend",p) then
			if pq(p,"getHandcardNum") < card_num then
				target = p
				card_num = pq(p,"getHandcardNum")
			end
		end
	end
	if target then
		return target
	end
	for _, p in sgs.qlist(targets) do
		return p
	end
	return nil
end


sgs.ai_skill_choice.SE_Feiti = function(self, choices, data)
	local list = pq(self.room,"getAlivePlayers")
	local target
	for _, p in sgs.qlist(list) do
		if pq(p,"hasFlag","SE_Feiti_Target") then
			target = p
		end
	end
	if pq(self,"isFriend",target) then return "SE_Feiti_Get" end
	return "SE_Feiti_Not_Get"
end

sgs.ai_choicemade_filter.skillChoice["SE_Feiti"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	local list = pq(self.room,"getAlivePlayers")
	for _, p in sgs.qlist(list) do
		if pq(p,"hasFlag","SE_Feiti_Target") then
			target = p
		end
	end
	if choice == "SE_Feiti_Get" and target then
		call(self,"updateIntention",player, target, -80)
	end
end

sgs.ai_damage_reason_suppress_intention["SE_Feiti"] = true



sgs.ai_skill_invoke.SE_Menghei = function(self, data)
	local damage = pq(data,"toDamage")
	if pq(self.player,"objectName") == pq(damage.from,"objectName") then
		if pq(self,"isEnemy",damage.to) then
			return true
		end
	end
	if pq(self.player,"objectName") == pq(damage.to,"objectName") then
		local danteng = damage.from
		for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
			if pq(danteng,"distanceTo",p) <= 1 then
				if pq(self,"isEnemy",p) then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen.SE_Menghei = function(self, targets)
	local hp_min = 100
	local target
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isEnemy",ap) and pq(ap,"getHp") < hp_min and not pq(self,"hasZhaxiangEffect",ap) then
			target = ap
			hp_min = pq(ap,"getHp")
		end
	end
	if target then return target end
	return nil
end



function sgs.ai_slash_prohibit.SE_Menghei(self, from, to)
	if pq(self,"isFriend",from, to) then return false end
	if pq(from,"hasSkill","jueqing") or (pq(from,"hasSkill","nosqianxi") and pq(from,"distanceTo",to) == 1) then return false end
	if pq(from,"hasFlag","NosJiefanUsed") then return false end
	if pq(from,"getHp") >= 2 then return false end
	return pq(from,"getHp") + pq(from,"getEquips"):length() < 4 or pq(from,"getHp") < 2
end



local se_gaobai_skill = {}
se_gaobai_skill.name = "se_gaobai"
table.insert(package_skills, se_gaobai_skill)
se_gaobai_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getMark","@Gaobai") < 1 then return end
	if #self.friends < 1 then return end
	local OK = false
	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(p,"isMale") and pq(self,"isFriend",p) and pq(p,"getHp") == 1 then
			OK = true
		end
		if pq(p,"isMale") and pq(self,"isFriend",p) and pq(p,"getHp") == 2 and pq(self.player,"getHp") == 1 and pq(p,"getMaxHp") == 3 then
			OK = true
		end
	end
	if OK then
		return parse(self,request,"#se_gaobaicard:.:")
	end
	return
end

sgs.ai_skill_use_func["#se_gaobaicard"] = function(card,use,self,request)
	local target
	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		if pq(p,"isMale") and pq(self,"isFriend",p) and pq(p,"getHp") == 1 then
			target = p
		end
		if pq(p,"isMale") and pq(self,"isFriend",p) and pq(p,"getHp") == 2 and pq(self.player,"getHp") == 1 and pq(p,"getMaxHp") == 3 then
			target = p
		end
		if pq(p,"isMale") and pq(self,"isFriend",p) and pq(p,"getHp") == 1 and pq(p,"getMaxHp") == 3 then
			target = p
		end
	end
	if target then
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_gaobaicard"]       = 10
sgs.ai_use_priority["se_gaobaicard"]    = 4
sgs.ai_card_intention.se_gaobaicard     = -100




function sgs.ai_skill_invoke.SE_Touming(self, data)
	if not pq(self.player,"faceUp") then return true end
	for _, friend in ipairs(self.friends) do
		if pq(self,"hasSkills","fangzhu|jilve", friend) then return true end
		if pq(friend,"hasSkill","junxing") and pq(friend,"faceUp") and not pq(self,"willSkipPlayPhase",friend)
			and not (pq(friend,"isKongcheng") and pq(self,"willSkipDrawPhase",friend)) then
			return true
		end
	end
	return pq(self,"isWeak") or pq(self.room,"getAlivePlayers"):length() > 4
end

sgs.ai_ajustdamage_to.SE_Touming = function(self, from, to, card, nature)
	if not pq(to,"faceUp") then
		return -99
	end
end

sgs.ai_skill_invoke.SE_Tuanzi = function(self, data)
	local card = pq(data,"toCardUse").card
	local people = pq(self.player,"getNextAlive")
	if pq(card,"isKindOf","Peach") or pq(card,"isKindOf","Jink") or pq(card,"isKindOf","Analeptic") or pq(card,"isKindOf","EquipCard") or pq(card,"isNDTrick") then
		if pq(self,"isFriend",people) then return true end
		if pq(self.player,"getHandcardNum") - pq(self.player,"getHp") < 2 then return true end
		return false
	end
	if pq(self,"isFriend",people) and isEquip("Crossbow", people) then
		if pq(card,"isKindOf","Slash") then return true end
	end
	return false
end



sgs.ai_skill_invoke.SE_Zishang = function(self, data)
	local damage = pq(data,"toDamage")
	local victim = damage.to
	if pq(self,"isFriend",victim) then
		if (pq(self,"isWeak",victim) and not pq(self,"isWeak",self.player)) then
			if pq(self,"isEnemy",damage.from) then return true end
		end
		if not pq(self,"isWeak",self.player) then
			for _, friend in ipairs(self.friends) do
				if pq(friend,"getHp") < pq(friend,"getMaxHp") and pq(friend,"objectName") ~= pq(self.player,"objectName") then
					if pq(self,"isEnemy",damage.from) and pq(damage.from,"faceUp") then return true end
				end
			end
		end
		if not pq(self,"damageIsEffective",self.player, damage.nature, damage.from) then
			for _, friend in ipairs(self.friends) do
				if pq(friend,"getHp") < pq(friend,"getMaxHp") and pq(friend,"objectName") ~= pq(self.player,"objectName") then
					if pq(self,"isEnemy",damage.from) and pq(damage.from,"faceUp") then return true end
				end
			end
		end
	end
	if pq(self.room,"getAllPlayers",true):length() == 2 then
		if pq(self.player,"getHp") >= 2 and pq(victim,"faceUp") then return true end
	end
	return false
end


sgs.ai_skill_playerchosen.SE_Zishang = function(self, targets)
	local hp_min = 100
	local target
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isFriend",ap) and pq(ap,"getHp") < hp_min then
			target = ap
			hp_min = pq(ap,"getHp")
		end
	end
	if target then return target end
	return pq(targets,"first")
end


sgs.ai_choicemade_filter.skillInvoke.SE_Zishang = function(self,player,promptlist)
	local damage = tag(self,"SE_Zishang"):toDamage()
	if damage.to then
		if promptlist[#promptlist]=="yes" then
			call(self,"updateIntention",self.player,damage.to,-80)
		end
	end
end

sgs.ai_skill_choice.SE_Zibi = function(self, data)
	if pq(self.player,"getHp") < pq(self.player,"getMaxHp") then
		return "SE_Zibi_R"
	end
	return "SE_Zibi_D"
end


local se_huanyuan_skill = {}
se_huanyuan_skill.name = "se_huanyuan"
table.insert(package_skills, se_huanyuan_skill)
se_huanyuan_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_huanyuancard") then return end
	if pq(self.player,"getMark","se_huanyuan_Pre_MaxHp") <= 0 then return end
	if #self.friends < 1 and #self.enemies < 1 then return end
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getMark","se_huanyuan_Pre_Hp") - pq(friend,"getHp") + (pq(friend,"getMark","se_huanyuan_Pre_MaxHp") - pq(friend,"getMaxHp")) * 2 > 0 then
			return parse(self,request,"#se_huanyuancard:.:")
		end
		if pq(friend,"getMark","se_huanyuan_Pre_Handcards") > pq(friend,"getHandcardNum") then
			return parse(self,request,"#se_huanyuancard:.:")
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHp") - pq(enemy,"getMark","se_huanyuan_Pre_Hp") + (pq(enemy,"getMaxHp") - pq(enemy,"getMark","se_huanyuan_Pre_MaxHp")) * 2 > 0 then
			return parse(self,request,"#se_huanyuancard:.:")
		end
	end
	return
end

sgs.ai_skill_use_func["#se_huanyuancard"] = function(card,use,self,request)
	local target
	self.se_huanyuan = "cancel"
	local value = 0
	local cardx
	local hcards = pq(self.player,"getCards","h")
	hcards = AIList.new(hcards)
	sort_keep(self,hcards, true)

	for _, hcard in ipairs(hcards) do
		if not pq(hcard,"isKindOf","Peach") then
			cardx = hcard
			break
		end
	end
	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		local p_v = 0
		local draw = true
		if pq(self,"isFriend",p) then
			if pq(p,"getMark","se_huanyuan_Pre_Hp") - pq(p,"getHp") + (pq(p,"getMark","se_huanyuan_Pre_MaxHp") - pq(p,"getMaxHp")) * 2 > p_v then
				p_v = pq(p,"getMark","se_huanyuan_Pre_Hp") - pq(p,"getHp") +
					(pq(p,"getMark","se_huanyuan_Pre_MaxHp") - pq(p,"getMaxHp")) *
					2
				draw = false
			end
			if pq(p,"getMark","se_huanyuan_Pre_Handcards") - pq(p,"getHandcardNum") > p_v * 2 then
				p_v = (pq(p,"getMark","se_huanyuan_Pre_Handcards") - pq(p,"getHandcardNum")) / 2
				draw = true
			end
		elseif pq(self,"isEnemy",p) then
			if pq(p,"getHp") - pq(p,"getMark","se_huanyuan_Pre_Hp") + (pq(p,"getMaxHp") - pq(p,"getMark","se_huanyuan_Pre_MaxHp")) * 2 > p_v then
				p_v = pq(p,"getHp") - pq(p,"getMark","se_huanyuan_Pre_Hp") +
					(pq(p,"getMaxHp") - pq(p,"getMark","se_huanyuan_Pre_MaxHp")) *
					2
				draw = false
			end
		end
		if p_v > value then
			value = p_v
			target = p
			if draw then
				self.se_huanyuan = "se_huanyuan_Draw"
			else
				self.se_huanyuan = "se_huanyuan_Hp"
			end
		end
	end
	if target and cardx then
		use.card=final_parse(self,request,"#se_huanyuancard:" .. pq(cardx,"getId") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end
sgs.ai_skill_choice["se_huanyuancard"]    = function(self, choices, data)
	return self.se_huanyuan
end

sgs.ai_use_value["se_huanyuancard"]       = 10
sgs.ai_use_priority["se_huanyuancard"]    = 2
sgs.ai_card_intention.se_huanyuancard     = -20

local se_chengling_skill = {}
se_chengling_skill.name                   = "se_chengling"
table.insert(package_skills, se_chengling_skill)
se_chengling_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getMark","@LimeBell") < 1 then return end
	if #self.friends < 2 then return end
	local OK = 0
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
		if pq(self,"isFriend",p) and pq(p,"getMaxHp") - pq(p,"getHp") >= 2 then
			OK = OK + 1
		end
		if pq(self,"isFriend",p) and pq(self.player,"getHp") == 1 and pq(p,"getMaxHp") - pq(p,"getHp") >= 1 then
			OK = OK + 1
		end
		if pq(self,"isEnemy",p) and pq(p,"getMark","@waked") > 0 and pq(p,"getHp") > 2 then
			OK = OK + 1
		end
	end
	if #self.friends == 1 then OK = OK + 1 end
	if OK > 1 then
		return parse(self,request,"#se_chenglingcard:.:")
	end
	return
end

sgs.ai_skill_use_func["#se_chenglingcard"] = function(card,use,self,request)
	local targets = AIList.new({})
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getMark","@waked") > 0 and pq(enemy,"getHp") > 2 and pq(targets,"length") < 2 then
			call(targets,"append",enemy)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if (pq(friend,"getMaxHp") - pq(friend,"getHp") >= 2 or (pq(self.player,"getHp") == 1 and pq(friend,"getMaxHp") - pq(friend,"getHp") >= 1)) and pq(targets,"length") < 2 then
			call(targets,"append",friend)
		end
	end
	if targets then
		use.card=final_parse(self,request,"#se_chenglingcard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["se_chenglingcard"]       = 10
sgs.ai_use_priority["se_chenglingcard"]    = 7
sgs.ai_card_intention.se_chenglingcard     = -100


sgs.ai_skill_invoke.SE_Shouzang            = function(self, data)
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	if pq(self,"isEnemy",source) then return true end
	return false
end

sgs.ai_skill_discard.SE_Shouzang           = function(self)
	local to_discard = {}
	local cards = pq(self.player,"getCards","he")
	local victim = tag(self,"SE_Shouzang_target"):toPlayer()
	if not victim or not pq(self,"isEnemy",victim) then return {} end
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		if #to_discard < pq(victim,"getMaxHp") then
			table.insert(to_discard, pq(card,"getEffectiveId"))
		else
			break
		end
	end
	if #to_discard > 0 and (#to_discard == pq(victim,"getMaxHp")) then
		return to_discard
	end
	return {}
end


sgs.ai_skill_invoke.SE_Xiangren = function(self, data)
	local dying_data = pq(data,"toDying")
	local source = dying_data.who
	if pq(self,"isFriend",source) then return true end
	return false
end


local se_jiejie_skill = {}
se_jiejie_skill.name = "se_jiejie"
table.insert(package_skills, se_jiejie_skill)
se_jiejie_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if pq(source,"getMark","@MagicEquip") == 0 then return end
	local target = 0
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getMark","@Kekkai") == 0 then
			target = 1
			break
		end
	end
	if target == 1 then
		return parse(self,request,"#se_jiejiecard:.:")
	end
	return
end

sgs.ai_skill_use_func["#se_jiejiecard"] = function(card,use,self,request)
	local target
	local minHp = 100
	for _, friend in ipairs(self.friends) do
		if pq(friend,"getMark","@Kekkai") == 0 then
			local hp = pq(friend,"getHp")
			if pq(self,"hasSkills",sgs.masochism_skill, friend) then
				hp = hp + 1
			end
			if pq(friend,"isLord") then
				hp = hp - 1
			end
			if hp < minHp then
				minHp = hp
				target = friend
			end
		end
	end
	if pq(self.player,"getHp") < 3 and pq(self.player,"getMark","@Kekkai") == 0 then
		target = self.player
	end
	if target then
		use.card=final_parse(self,request,"#se_jiejiecard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end


sgs.ai_use_value["se_jiejiecard"]      = 6
sgs.ai_use_priority["se_jiejiecard"]   = 9
sgs.ai_card_intention["se_jiejiecard"] = -100


local se_jiangui_skill = {}
se_jiangui_skill.name                  = "se_jiangui"
table.insert(package_skills, se_jiangui_skill)
se_jiangui_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_jianguicard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#se_jianguicard:.:")
end

sgs.ai_skill_use_func["#se_jianguicard"] = function(card,use,self,request)
	local targets = AIList.new({})
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			call(targets,"append",enemy)
		end
	end
	if targets then
		use.card=final_parse(self,request,"#se_jianguicard:.:")
		use.to = targets
		return
	end
end

sgs.ai_use_value["se_jianguicard"]       = 10
sgs.ai_use_priority["se_jianguicard"]    = 9
sgs.ai_card_intention["se_jianguicard"]  = 60

sgs.ai_can_damagehp.SE_Niepan = function(self,from,card,to)
	return pq(to,"getHp")+pq(self,"getAllPeachNum")-pq(self,"ajustDamage",from,to,1,card)>0
	and pq(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_invoke.SE_Wufan             = function(self, data)
	if #self.enemies == 0 then return false end
	if pq(self.player,"getMark","@Efreet") >= 4 then return true end
	local total_enemy_num, average_enemy_hp, least_enemy_hp = checkEnemyDetailed(self, data)
	local total_friend_num, average_friend_hp, least_friend_hp = checkFriendDetailed(self, data)
	local hp = pq(self.player,"getHp")
	if pq(self.player,"getMark","@Efreet") == 3 then
		if hp < 3 then return true end
		if least_enemy_hp == 1 then return true end
		if total_friend_num < total_enemy_num or average_enemy_hp >= average_friend_hp then return true end
		if total_friend_num == total_enemy_num and average_enemy_hp >= average_friend_hp + 1 then return true end
		if total_friend_num > total_enemy_num then return true end
	elseif pq(self.player,"getMark","@Efreet") == 2 then
		if total_friend_num + 1 < total_enemy_num or average_enemy_hp > average_friend_hp + 1 then return true end
		if least_enemy_hp == 1 then return true end
		if hp < 2 then return true end
		if total_friend_num <= 2 then return true end
	elseif pq(self.player,"getMark","@Efreet") == 1 then
		if hp < 2 and total_friend_num <= 2 then return true end
		if total_friend_num == 1 and total_enemy_num > 1 then return true end
	end
	return false
end


checkEnemyDetailed=function(self, data)
	local total_enemy_num = 0
	local average_enemy_hp = 0
	local least_enemy_hp = 100
	for _, enemy in ipairs(self.enemies) do
		total_enemy_num = total_enemy_num + 1
		average_enemy_hp = average_enemy_hp + pq(enemy,"getHp")
		if pq(enemy,"getHp") < least_enemy_hp then
			least_enemy_hp = pq(enemy,"getHp")
		end
	end
	average_enemy_hp = average_enemy_hp / total_enemy_num
	return total_enemy_num, average_enemy_hp, least_enemy_hp
end

checkFriendDetailed=function(self, data)
	local total_friend_num = 0
	local average_friend_hp = 0
	local least_friend_hp = 100
	for _, friend in ipairs(self.friends) do
		total_friend_num = total_friend_num + 1
		average_friend_hp = average_friend_hp + pq(friend,"getHp")
		if pq(friend,"getHp") < least_friend_hp then
			least_friend_hp = pq(friend,"getHp")
		end
	end
	average_friend_hp = average_friend_hp / total_friend_num
	return total_friend_num, average_friend_hp, least_friend_hp
end



sgs.ai_skill_invoke.SE_Shuangqiang = function(self, data)
	local source = pq(data,"toPlayer")
	if pq(self,"isEnemy",source) then
		return true
	end
	return false
end

sgs.ai_ajustdamage_from.SE_Shuangqiang = function(self,from,to,card,nature)
	if pq(from,"getEquips"):length()>0 and not pq(self,"beFriend",to,from) and nature == "N"
	then return 1 end
end


sgs.ai_skill_invoke.SE_Xinlai = function(self, data)
	local source = pq(data,"toPlayer")
	if pq(self,"isFriend",source) then
		return true
	end
	return false
end



sgs.ai_skill_playerchosen["SE_Xinlai"] = function(self, targets)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	local drawnum = damage.damage
	local players = AIList.new(targets)
	local friends = {}
	for _, player in ipairs(players) do
		if pq(self,"isFriend",player) and not hasManjuanEffect(player) and not pq(self,"needKongcheng",player, true)
			and not (pq(player,"hasSkill","kongcheng") and pq(player,"isKongcheng") and drawnum <= 2) and pq(player,"getMark","@Baskervilles") == 1 then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return nil end

	sort_players(self,friends, "defense")
	for _, friend in ipairs(friends) do
		if pq(friend,"getHandcardNum") < 2 and not pq(self,"needKongcheng",friend) and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) and (pq(AssistTarget,"getHandcardNum") < pq(AssistTarget,"getMaxCards") * 2 or pq(AssistTarget,"getHandcardNum") < pq(self.player,"getHandcardNum")) then
		for _, friend in ipairs(friends) do
			if pq(friend,"objectName") == pq(AssistTarget,"objectName") and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if pq(self,"hasSkills",sgs.cardneed_skill, friend) and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	sort_players(self,friends, "handcard")
	for _, friend in ipairs(friends) do
		if not pq(self,"needKongcheng",friend) and not pq(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.SE_Xinlai = -50

sgs.need_equip_skill = sgs.need_equip_skill .. "|SE_Shuangqiang"


sgs.ai_skill_invoke.moesenskill = function(self, data)
	local target = pq(data,"toPlayer")
	if target and pq(self,"isFriend",target) then
		return true
	end
	return false
end


sgs.hit_skill = sgs.hit_skill .. "|SE_Juji_Reki"
ai_audited_aliases.register{id="ai_cardneed.SE_Juji_Reki",registry="ai_cardneed",path={"SE_Juji_Reki"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_canliegong_skill.SE_Juji_Reki = function(self, from, to)
	return pq(from,"getPhase") == sgs.Player_Play and not pq(to,"inMyAttackRange",from)
end

ai_audited_aliases.register{id="ai_cardneed.SE_Zhiyuan",registry="ai_cardneed",path={"SE_Zhiyuan"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_skill_invoke.SE_Zhiyuan = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["SE_Zhiyuan"] = function(self, targets)
	local players = AIList.new(targets)
	local friends = {}
	for _, player in ipairs(players) do
		if pq(self,"isFriend",player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return nil end

	sort_players(self,friends, "handcard")
	for _, friend in ipairs(friends) do
		if pq(friend,"getHandcardNum") < 2 and not pq(self,"willSkipPlayPhase",friend) then
			return friend
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) and (pq(AssistTarget,"getHandcardNum") < pq(AssistTarget,"getMaxCards") * 2 or pq(AssistTarget,"getHandcardNum") < pq(self.player,"getHandcardNum")) then
		for _, friend in ipairs(friends) do
			if pq(friend,"objectName") == pq(AssistTarget,"objectName") and not pq(self,"willSkipPlayPhase",friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if pq(self,"hasSkills",sgs.cardneed_skill, friend) and not pq(self,"willSkipPlayPhase",friend) then
			return friend
		end
	end

	sort_players(self,friends, "handcard")
	for _, friend in ipairs(friends) do
		if not pq(self,"willSkipPlayPhase",friend) then
			return friend
		end
	end
	return nil
end


sgs.ai_playerchosen_intention.SE_Zhiyuan = -80




sgs.ai_skill_invoke["SE_Qizhuang"] = function(self, data)
	if #self.enemies > 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen["Lucifer"] = function(self, targets)
	local target
	local min_hp = 100
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isEnemy",ap) and pq(ap,"getMark","@Belphegor") == 0 then
			if pq(self,"hasSkills",sgs.masochism_skill, ap) then return ap end
			if pq(ap,"getHp") < min_hp then
				min_hp = pq(ap,"getHp")
				target = ap
			end
		end
	end
	if target then return target end
	return self.enemies[1]
end
sgs.ai_playerchosen_intention["Lucifer"] = 80


sgs.ai_skill_playerchosen["Leviathan"] = function(self, targets)
	local target
	local equip_max = 0
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isEnemy",ap) then
			if pq(ap,"getEquips"):length() > equip_max and not pq(ap,"hasSkills",sgs.lose_equip_skill) then
				equip_max = pq(ap,"getEquips"):length()
				target = ap
			end
		end
	end
	if target then return target end
	return self.enemies[1]
end
sgs.ai_playerchosen_intention["Leviathan"] = 50


sgs.ai_skill_playerchosen["Satan"] = function(self, targets)
	local target
	local min_hp = 100
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isEnemy",ap) and pq(ap,"getMark","@Belphegor") == 0 then
			if not pq(self,"hasSkills",sgs.masochism_skill, ap) and pq(self,"isGoodTarget",ap, self.enemies, nil) and pq(self,"damageIsEffective",ap, sgs.DamageStruct_Normal) then
				if pq(ap,"getHp") < min_hp then
					min_hp = pq(ap,"getHp")
					target = ap
				end
			end
		end
	end
	if target then return target end
	return self.enemies[1]
end
sgs.ai_playerchosen_intention["Satan"] = 40


sgs.ai_skill_playerchosen["Belphegor"] = function(self, targets)
	local target
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isEnemy",ap) then
			if pq(ap,"getMark","@Satan") == 0 and pq(ap,"getMark","@Lucifer") == 0 then
				target = ap
			end
		end
	end
	if target then return target end
	return self.enemies[1]
end
sgs.ai_playerchosen_intention["Belphegor"] = 60


sgs.ai_skill_playerchosen["Beelzebub"] = function(self, targets)
	local target
	local least_num = 0
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isFriend",ap) then
			if pq(ap,"getHandcardNum") > least_num then
				least_num = pq(ap,"getHandcardNum")
				target = ap
			end
		end
	end
	if target then return target end
	return self.friends[1]
end

sgs.ai_playerchosen_intention["Beelzebub"] = -60
sgs.ai_skill_playerchosen["Asmodeus"] = function(self, targets)
	local target
	local least_hp = 100
	for _, ap in sgs.qlist(targets) do
		if pq(self,"isFriend",ap) then
			if pq(ap,"getHp") < least_hp then
				least_hp = pq(ap,"getHp")
				target = ap
			end
		end
	end
	if target then return target end
	return self.friends[1]
end

sgs.ai_playerchosen_intention["Asmodeus"] = -80
sgs.ai_skill_invoke["Lucifer"] = true
sgs.ai_skill_invoke["Leviathan"] = true
sgs.ai_skill_invoke["Satan"] = true
sgs.ai_skill_invoke["Belphegor"] = true
sgs.ai_skill_invoke["Beelzebub"] = true
sgs.ai_skill_invoke["Asmodeus"] = true
sgs.ai_skill_invoke["Mammon"] = true



sgs.ai_skill_invoke.SE_Fanhun = function(self, data)
	for _, p in sgs.qlist(pq(self.room,"getPlayers")) do
		if pq(p,"isDead") and pq(p,"getMaxHp") >= 1 then
			if pq(self,"isFriend",p) then return true end
		end
	end
	return false
end

sgs.ai_skill_choice["SE_Fanhun_choose"] = function(self, choices, data)
	for _, p in sgs.qlist(pq(self.room,"getPlayers")) do
		if pq(p,"isDead") and pq(p,"getMaxHp") >= 1 then
			if pq(self,"isFriend",p) then return pq(p,"getGeneralName") end
		end
	end
	local choice_table = pq(choices,"split","+")
	return choice_table[1]
end

sgs.ai_skill_choice.SE_Fanhun = function(self, data)
	if pq(self.player,"getMark","@Mahou_ai") > 0 then
		return true
	end
	return false
end


sgs.ai_target_revises.SE_Jiepi = function(to, card, self)
	return pq(card,"isNDTrick") and pq(self.player,"getHandcardNum") < pq(to,"getHandcardNum")
end

local se_zhanjing_skill = {}
se_zhanjing_skill.name = "se_zhanjing"
table.insert(package_skills, se_zhanjing_skill)
se_zhanjing_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_zhanjingcard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#se_zhanjingcard:.:")
end

sgs.ai_skill_use_func["#se_zhanjingcard"] = function(card,use,self,request)
	local target
	sort_players(self,self.enemies, "defense")
	for _, p in ipairs(self.enemies) do
		if pq(p,"getHandcardNum") > 3 then
			if not ((pq(p,"getHp") < pq(self.player,"getHp")) and pq(p,"getMaxHp") < pq(self.player,"getMaxHp") and not pq(self,"damageIsEffective",p, nil, self.player)) then
				target = p
				break
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if pq(p,"getMaxHp") > pq(self.player,"getMaxHp") then
			if not ((pq(p,"getHp") < pq(self.player,"getHp")) and pq(p,"getMaxHp") < pq(self.player,"getMaxHp") and not pq(self,"damageIsEffective",p, nil, self.player)) then
				target = p
				break
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if pq(p,"getHandcardNum") > 6 then
			if not ((pq(p,"getHp") < pq(self.player,"getHp")) and pq(p,"getMaxHp") < pq(self.player,"getMaxHp") and not pq(self,"damageIsEffective",p, nil, self.player)) then
				target = p
				break
			end
		end
	end
	if not target then target = self.enemies[1] end
	use.card = card
	if use.to then call(use.to,"append",target) end
	return
end

sgs.ai_use_value["se_zhanjingcard"]       = 8
sgs.ai_use_priority["se_zhanjingcard"]    = 8
sgs.ai_card_intention["se_zhanjingcard"]  = 80




sgs.ai_skill_cardask["@SE_Guanli"] = function(self, data)
	local PlayerNow = pq(data,"toPlayer")
	local cards = pq(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_use(self,cards)
	if pq(self,"isEnemy",PlayerNow) then
		call(self,"setStrategyMemory","dongmanbao.SE_Guanli_reason","enemy_discard")
		if pq(PlayerNow,"getHandcardNum") - pq(PlayerNow,"getMaxCards") > 1 then
			if pq(self.player,"getHandcardNum") > 3 then
				for _, card in ipairs(cards) do
					return pq(card,"getEffectiveId")
				end
			end
		elseif pq(PlayerNow,"getHandcardNum") - pq(PlayerNow,"getMaxCards") > 2 then
			if pq(self.player,"getHandcardNum") > 2 then
				for _, card in ipairs(cards) do
					return pq(card,"getEffectiveId")
				end
			end
		elseif pq(PlayerNow,"getHandcardNum") - pq(PlayerNow,"getMaxCards") > 4 then
			if pq(self.player,"getHandcardNum") > 0 then
				for _, card in ipairs(cards) do
					return pq(card,"getEffectiveId")
				end
			end
			if pq(self.player,"getEquips"):length() > 0 then
				for _, card in ipairs(cards) do
					return pq(card,"getEffectiveId")
				end
			end
		end
		if pq(self.room,"getAllPlayers",true):length() == 2 then
			for _, card in ipairs(cards) do
				return pq(card,"getEffectiveId")
			end
		end
	elseif pq(self,"isFriend",PlayerNow) then
		if pq(self.player,"getHandcardNum") > 0 then
			if pq(self,"hasSkills","se_chouyuan|se_shunshan|se_kanhu|se_shengjian|se_jianyu|se_huanyuan|se_zhanjing|LuaGonglue|LuaBoxue|", PlayerNow) then
				call(self,"setStrategyMemory","dongmanbao.SE_Guanli_reason","friend_play")
				for _, card in ipairs(cards) do
					return pq(card,"getEffectiveId")
				end
			end
			if pq(self,"hasSkills","SE_Guanli|SE_Weigong|SE_Zhufu|LuaLuowang", PlayerNow) then
				call(self,"setStrategyMemory","dongmanbao.SE_Guanli_reason","friend_draw")
				for _, card in ipairs(cards) do
					return pq(card,"getEffectiveId")
				end
			end
		end
		if pq(self.player,"getHandcardNum") > 3 then
			call(self,"setStrategyMemory","dongmanbao.SE_Guanli_reason","friend_draw")
			for _, card in ipairs(cards) do
				return pq(card,"getEffectiveId")
			end
		end
	end
	return "."
end


sgs.ai_skill_choice["SE_Guanli"] = function(self, choices, data)
	if self:getStrategyMemory("dongmanbao.SE_Guanli_reason") == "friend_draw" then
		return "Gl_draw"
	elseif self:getStrategyMemory("dongmanbao.SE_Guanli_reason") == "friend_play" then
		return "Gl_play"
	elseif self:getStrategyMemory("dongmanbao.SE_Guanli_reason") == "enemy_discard" then
		return "Gl_discard"
	end
end
sgs.ai_choicemade_filter.skillChoice["SE_Guanli"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = call(self.room,"getCurrent")
	if choice == "Gl_discard" then
		call(self,"updateIntention",player, current, 60)
	else
		call(self,"updateIntention",player, current, -60)
	end
end

local se_poyi_skill = {}
se_poyi_skill.name = "se_poyi"
table.insert(package_skills, se_poyi_skill)
se_poyi_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_poyicard") then return end
	local AIList = AIList.new({})
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
		if ai_present(self,p) and pq(self,"isEnemy",p) then
			call(AIList,"append",p)
		end
	end
	if pq(AIList,"length") < 1 then return end
	return parse(self,request,"#se_poyicard:.:")
end

sgs.ai_skill_use_func["#se_poyicard"] = function(card,use,self,request)
	use.card = card
	return
end

sgs.ai_use_value["se_poyicard"]       = 5
sgs.ai_use_priority["se_poyicard"]    = 2
sgs.ai_card_intention["se_poyicard"]  = 0

sgs.ai_skill_playerchosen["se_poyi1"] = function(self, targets)
	local target
	local maxHp = 0
	local room = pq(self.player,"getRoom")
	for _, p in sgs.qlist(targets) do
		if ai_present(self,p) and pq(self,"isEnemy",p) and pq(p,"getHp") > maxHp then
			target = p
			maxHp = pq(p,"getHp")
		end
	end
	if target then
		return target
	end
	return self.enemies[1]
end

sgs.ai_skill_playerchosen["se_poyi2"] = function(self, targets)
	local target
	local maxHp = 0
	local room = pq(self.player,"getRoom")
	for _, p in sgs.qlist(targets) do
		if ai_present(self,p) and pq(self,"isEnemy",p) and pq(p,"getHp") > maxHp then
			target = p
			maxHp = pq(p,"getHp")
		end
	end
	if not target then
		for _, p in sgs.qlist(targets) do
			if pq(self,"isEnemy",p) then
				target = p
			end
		end
	end
	if target then
		return target
	end
	return self.enemies[1]
end

sgs.ai_card_intention["se_poyicard"]  = function(card, from, to)
 local self=card
 local legacy=known(self.world.strategy_facts.dongmanbao_poyi_history,"public poyi history")
 local poyi1=resolve(self,legacy.first);local poyi2=resolve(self,legacy.second)
	if poyi1 then
		call(self,"updateIntention",poyi1, from, -50)
		if poyi2 then
			call(self,"updateIntention",poyi2, poyi1, 200)
			call(self,"updateIntention",poyi1, poyi2, 200)
			poyi2=nil
		end
		poyi1=nil
	end
end


sgs.ai_skill_choice["SE_Yirong"]      = function(self, choices, data)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local choice_table = pq(choices,"split","+")
	return choice_table[math.random(1,#choice_table)]
end


local se_youhuo_skill = {}
se_youhuo_skill.name = "se_youhuo"
table.insert(package_skills, se_youhuo_skill)
se_youhuo_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"hasUsed","#se_youhuocard") then return end
	if pq(self.player,"isKongcheng") then return end
	local target
	for _, p in ipairs(self.enemies) do
		if pq(p,"getHandcardNum") > 0 then target = p end
	end
	if not target then return end
	return parse(self,request,"#se_youhuocard:.:")
end
sgs.ai_skill_use_func["#se_youhuocard"]        = function(card,use,self,request)
	local target
	local cards = AIList.new(pq(self.player,"getHandcards"))
		sort_keep(self,cards)
	local card
	for _, p in ipairs(self.enemies) do
		if pq(self,"doDisCard",p, "he", true) then target = p end
	end
	for _, c in ipairs(cards) do
		card = c
		break
	end
	if not target then return end
	if card and target then
		use.card=final_parse(self,request,"#se_youhuocard:" .. pq(card,"getEffectiveId") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_youhuocard"]              = 8
sgs.ai_use_priority["se_youhuocard"]           = 5
sgs.ai_card_intention["se_youhuocard"]         = 80

sgs.ai_skill_choice["Youhuo"]                  = function(self, choices, data)
	local num = 0
	for _, p in sgs.qlist(pq(self.room,"getOtherPlayers",self.player)) do
		if pq(p,"getMark","@Baskervilles") == 1 and pq(self,"isEnemy",p) then
			num = num + 1
		end
	end
	local Riko = call(self.room,"findPlayerBySkillName","se_youhuo")
	if num >= 2 then
		if pq(self.player,"getHp") > 2 and pq(Riko,"getHp") == 3 then return "se_youhuo_Recovery" end
	end
	return "se_youhuo_Obtain"
end

sgs.ai_skill_choice["Youhuo_Obtain"]           = function(self, choices, data)
	local target = pq(data,"toPlayer")
	if pq(self,"isFriend",target) then
		return string.format("Allow to obtain card:" .. pq(target,"getGeneralName"))
	end
	return "Youhuo_Obtain_Not"
end

sgs.ai_skill_playerchosen["se_youhuocard"]     = function(self, targets)
	call(self,"updatePlayers")
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if pq(self,"isFriend",target) and not hasManjuanEffect(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if pq(self,"isEnemy",target) and hasManjuanEffect(target) then
			return target
		end
	end
	if table.contains(targets, self.player) or #targets == 0 then return self.player end
	return nil
end

sgs.ai_playerchosen_intention["se_youhuocard"] = function(self, from, to)
	call(self,"updateIntention",from, to, -50)
end



sgs.ai_skill_invoke.SE_Qidan = function(self, data)
	if #self.enemies > 0 then return true end
	return false
end

sgs.ai_skill_invoke.SE_Shidan = function(self, data)
	for _, p in ipairs(self.enemies) do
		if pq(p,"faceUp") then return true end
	end
	return false
end

local function getMinHpEnemy(self)
	local min_hp = 100
	local target
	for _, p in ipairs(self.enemies) do
		if pq(p,"getHp") < min_hp then
			target = p
		end
	end
	if target then return target end
	return self.enemies[1]
end

sgs.ai_playerchosen_intention.SE_Qidan = function(self, from, to)
	local intention = 80
	if not pq(self,"toTurnOver",to, 0, "SE_Qidan") then intention = -intention end
	call(self,"updateIntention",from, to, intention)
end
sgs.ai_skill_playerchosen.SE_Qidan = function(self, targets)
	local target = nil
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not pq(self,"toTurnOver",friend, 0, "SE_Qidan") then
				target = friend
				break
			end
		end
	end
	if not target then
		sort_players(self,self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if pq(self,"toTurnOver",enemy, 0, "SE_Qidan") then
				target = enemy
				break
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if pq(self,"toTurnOver",enemy, 0, "SE_Qidan") and pq(self,"hasSkills",sgs.priority_skill, enemy) then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if pq(self,"toTurnOver",enemy, 0, "SE_Qidan") then
					target = enemy
					break
				end
			end
		end
	end
	return target
end



sgs.ai_skill_playerchosen.SE_Shidan = function(self, targets)
	for _, p in ipairs(self.enemies) do
		if pq(p,"getMark","@Qidan_attacked") > 0 and pq(self,"damageIsEffective",p, sgs.DamageStruct_Fire, self.player) and pq(self,"isGoodTarget",p, self.enemies, nil) then
			return
				p
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local def = pq(self,"getDefenseSlash",enemy)
		local slash = call(self,"cloneEvaluationCard","fire_slash")
		
		local eff = pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, slash)

		if not pq(self.player,"canSlash",enemy, slash, false) then
		elseif pq(self,"slashProhibit",nil, enemy) then
		elseif def < 6 and eff then
			return enemy
		end
	end
	
	return nil
end

sgs.ai_skill_invoke.SE_Badan = function(self, data)
	if pq(self.player,"getMark","@Eight") == 0 then return false end
	if pq(self.player,"getHp") <= 1 then return true end
end

sgs.ai_skill_choice["SE_Badan"] = function(self, data)
	return "SE_Badan_Odd"
end



sgs.ai_can_damagehp.SE_Rennai = function(self,from,card,to)
	return pq(to,"getHp")+pq(self,"getAllPeachNum")-pq(self,"ajustDamage",from,to,1,card)>0
	and pq(self,"canLoseHp",from,card,to) and pq(self.player,"getMark","@Patience") == 0
end

sgs.ai_ajustdamage_to.SE_Rennai = function(self, from, to, card, nature)
	if pq(to,"getMark","@Patience") > 0 then
		return -99
	end
end

local se_qingqiangwei_skill = {}
se_qingqiangwei_skill.name = "se_qingqiangwei"
table.insert(package_skills, se_qingqiangwei_skill)
se_qingqiangwei_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	local eNum = 0
	local fNum = 0
	for _, p in sgs.qlist(pq(self.room,"getAlivePlayers")) do
		local dist = pq(source,"distanceTo",p)
		if dist <= pq(source,"getMaxHp") - pq(source,"getHp") + 1 then
			if pq(self,"isFriend",p) then
				fNum = fNum + 1
			else
				eNum = eNum + 1
			end
		end
	end
	local work = true
	if eNum == 0 or eNum < fNum + 1 then work = false end
	if work then
		return parse(self,request,"#se_qingqiangweicard:.:")
	end
end

sgs.ai_skill_use_func["#se_qingqiangweicard"] = function(card,use,self,request)
	use.card = card
	return
end
sgs.ai_use_value["se_qingqiangweicard"] = 8
sgs.ai_use_priority["se_qingqiangweicard"] = 10

sgs.ai_skill_invoke.SE_Huajian = function(self, data)
	if #self.friends > 1 then return true end
	return false
end

sgs.ai_skill_playerchosen.SE_Huajian = function(self, targets)
	local bestChoice
	local bestP = 0
	for _, p in ipairs(self.friends_noself) do
		if pq(p,"isAlive") and pq(p,"objectName") ~= pq(self.player,"objectName") then
			local point = 0
			if pq(p,"hasSkill","se_erdao") then point = point + 20 end
			if pq(p,"hasSkill","Zhena") then point = point + 10 end
			if pq(p,"hasSkill","se_xunyu") then point = point + 30 end
			if pq(p,"hasSkill","LuaCangshan") then point = point + 9 end
			if pq(p,"hasSkill","LuaSaoshe") then point = point + 30 end
			if pq(p,"getHp") > 2 then point = point + 3 end
			if pq(p,"getHp") <= 1 then point = point - 10 end
			if point > bestP then
				bestP = point
				bestChoice = p
			end
		end
	end
	if bestChoice then return bestChoice end
	return self.friends[1]
end





sgs.ai_skill_invoke["SE_Shenghua"] = true

sgs.ai_skill_choice["SE_Shenghua"] = "suipian"

sgs.ai_skill_invoke["SE_Wumai"] = function(self, data)
	local damage = pq(data,"toDamage")
	if pq(self,"isFriend",damage.from) and pq(self.player,"getPile","Fragments"):length() > 4 then return false end
	return true
end
sgs.ai_can_damagehp.SE_Wumai = function(self, from, card, to)
	if from and pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0
		and pq(self,"canLoseHp",from, card, to)
	then
		return pq(self,"isEnemy",from) and pq(self,"isWeak",from) and pq(from,"getCardCount") > 0
	end
end


local se_mipa_skill = {}
se_mipa_skill.name = "se_mipa"
table.insert(package_skills, se_mipa_skill)
se_mipa_skill.getTurnUseCard=function(self,inclusive,request)
	local Fr = pq(self.player,"getPile","Fragments"):length()
	if Fr == 0 then return end
	local tf = 0
	if Fr == 1 then
		for _, p in ipairs(self.enemies) do
			if pq(p,"getMark","@mipa_basic") > 0 or pq(p,"getMark","@mipa_notbasic") > 0 then tf = tf - 5 end
			if pq(p,"getHp") <= 1 then tf = tf + 10 end
			if pq(p,"getHandcardNum") > 5 then tf = tf + 1 end
			if call(p,"getWeapon") and call(p,"getWeapon"):isKindOf("Crossbow") and pq(p,"getHandcardNum") > 3 then tf = tf + 11 end
		end
	elseif Fr == 2 then
		for _, p in ipairs(self.enemies) do
			if pq(p,"getMark","@mipa_basic") > 0 or pq(p,"getMark","@mipa_notbasic") > 0 then tf = tf - 1 end
			if pq(p,"getHp") <= 1 then tf = tf + 11 end
			if pq(p,"getHandcardNum") > 3 then tf = tf + 1 end
			if pq(p,"getHandcardNum") > 6 then tf = tf + 4 end
			if pq(p,"getHandcardNum") > 8 then tf = tf + 10 end
			if call(p,"getWeapon") and call(p,"getWeapon"):isKindOf("Crossbow") and pq(p,"getHandcardNum") > 3 then tf = tf + 11 end
		end
	elseif Fr >= 3 then
		for _, p in ipairs(self.enemies) do
			if pq(p,"getHp") <= 1 then tf = tf + 11 end
			if pq(p,"getHandcardNum") > 3 then tf = tf + 4 end
			if pq(p,"getHandcardNum") > 6 then tf = tf + 5 end
			if pq(p,"getHandcardNum") > 8 then tf = tf + 11 end
			if pq(self,"hasSkills","SE_Juji|SE_Juji_Reki|se_chouyuan|LuaTianmo|LuaBimie|LuaPoshi|LuaGungnir|LuaSaoshe", p) and pq(p,"getHandcardNum") > 1 then
				tf =
					tf + 11
			end
			if call(p,"getWeapon") and call(p,"getWeapon"):isKindOf("Crossbow") and pq(p,"getHandcardNum") > 3 then tf = tf + 11 end
		end
	end
	if #self.enemies == 1 then tf = 100 end
	if tf > 10 then return parse(self,request,"#se_mipacard:.:") end
	return
end
sgs.ai_skill_use_func["#se_mipacard"] = function(card,use,self,request)
	local target
	local Fr = pq(self.player,"getPile","Fragments"):length()
	for _, p in ipairs(self.enemies) do
		if call(p,"getWeapon") and call(p,"getWeapon"):isKindOf("Crossbow") and pq(p,"getHandcardNum") > 3 and (pq(p,"getMark","@mipa_basic") == 0 or pq(p,"getMark","@mipa_notbasic") == 0) then
			target = p
			break
		end
	end
	if not target then
		if Fr >= 2 then
			for _, p in ipairs(self.enemies) do
				if pq(self,"hasSkills","SE_Juji|SE_Juji_Reki|se_chouyuan|LuaTianmo|LuaBimie|LuaPoshi|LuaGungnir|LuaSaoshe", p) and pq(p,"getHandcardNum") > 1 and (pq(p,"getMark","@mipa_basic") == 0 or pq(p,"getMark","@mipa_notbasic") == 0) then
					target = p
					break
				end
			end
		end
		if not target then
			local ma = 0
			for _, p in ipairs(self.enemies) do
				if pq(p,"getHandcardNum") > ma and (pq(p,"getMark","@mipa_basic") == 0 or pq(p,"getMark","@mipa_notbasic") == 0) then
					ma = pq(p,"getHandcardNum")
					target = p
				end
			end
		end
	end
	local cardsq
	if target then
		for _, id in sgs.qlist(pq(self.player,"getPile","Fragments")) do
			local card = disclosed(self,id)
			if (pq(target,"getMark","@mipa_basic") == 0) or (pq(target,"getMark","@mipa_notbasic") == 0) then
				cardsq = card
			end
		end
	end
	if cardsq and target and (pq(target,"getMark","@mipa_basic") == 0 or pq(target,"getMark","@mipa_notbasic") == 0) then
		local card_str = string.format("#se_mipacard:%s:", pq(cardsq,"getEffectiveId"))
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_mipacard"] = 5
sgs.ai_use_priority["se_mipacard"] = 5
sgs.ai_skill_choice["se_mipa"] = "Mipa_Basic"



local se_chenyan_skill = {}
se_chenyan_skill.name = "se_chenyan"
table.insert(package_skills, se_chenyan_skill)
se_chenyan_skill.getTurnUseCard=function(self,inclusive,request)
	call(self,"updatePlayers")
	local patterns = generateAllCardObjectNameTablePatterns(self)
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = call(self,"cloneEvaluationCard",name)
		if pq(poi,"isAvailable",self.player) then
			table.insert(choices, name)
		end
	end
	if pq(self.player,"isNude") and pq(self,"isWeak") then return end
	if pq(self,"getRoleEstimate",self.player) == "neutral" then return end
	if role_count(self,"rebel") == 0 then return end
	if chenyan_mark(self,"AI_do_not_invoke_se_chenyan-Clear") > 0 then return end

	if next(choices) and pq(self.player,"getMark","se_chenyan-Clear") == 0 then
		return parse(self,request,"#se_chenyan:.:")
	end
end

sgs.ai_skill_use_func["#se_chenyan"] = function(card,use,self,request)
	local handcards = AIList.new(pq(self.player,"getCards","h"))
	sort_use(self,handcards, true)
	local useable_cards = {}
	if call(self.player,"getArmor") and pq(self.player,"hasArmorEffect","silver_lion") and pq(self.player,"isWounded") then
		table.insert(useable_cards, call(self.player,"getArmor"))
	end
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
		then
			table.insert(useable_cards, c)
		end
	end
	
	local card_str = "#se_chenyan:.:"
	local acard = parse(self,request,card_str)
	if #useable_cards >= 2 then
		if pq(useable_cards[1],"hasFlag","xiahui") then return end
		
		set_tag(self,"ai_se_chenyan_card_id",useable_cards[1]:getEffectiveId())
		set_tag(self,"ai_se_chenyan_card_id2",useable_cards[2]:getEffectiveId())
		acard=final_parse(self,request,"#se_chenyan:"..useable_cards[1]:getEffectiveId().."+"..useable_cards[2]:getEffectiveId()..":")
		use.card = acard
		chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear","set",0)
	else
		chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear","set",1)
		if not pq(self,"isWeak") then
			use.card = acard
		end
	end
	
end

sgs.ai_use_priority["se_chenyan"] = 3
sgs.ai_use_value["se_chenyan"] = 3

sgs.ai_skill_choice["se_chenyan"] = function(self, choices, data)
	call(self,"updatePlayers")
	local ai_se_chenyan_card_id
	local ai_se_chenyan_card_id2
	if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
		ai_se_chenyan_card_id = tag(self,"ai_se_chenyan_card_id"):toInt()
		remove_tag(self,"ai_se_chenyan_card_id")
		ai_se_chenyan_card_id2 = tag(self,"ai_se_chenyan_card_id2"):toInt()
		remove_tag(self,"ai_se_chenyan_card_id2")
	end
	local se_chenyan_vs_card = {}
	local items = pq(choices,"split","+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = owner_clone(self,"se_chenyan",card_name,sgs.Card_SuitToBeDecided,-1)
			
			if not table.contains(se_chenyan_vs_card, use_card) then
				table.insert(se_chenyan_vs_card, use_card)
			end
		end
	end
	sort_priority(self,se_chenyan_vs_card)
	for _, c in ipairs(se_chenyan_vs_card) do
		if table.contains(items, pq(c,"objectName")) then
			if pq(c,"targetFixed") then
				if pq(c,"isKindOf","Peach") and pq(self.player,"isWounded") and pq(self.player,"getHp") <= 2 and chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
					return pq(c,"objectName")
				end
				if pq(c,"isKindOf","ExNihilo") and pq(self.player,"getHandcardNum") <= 2 and pq(self,"getOverflow") > 0 then
					return pq(c,"objectName")
				end
				if pq(c,"isKindOf","SavageAssault") then
					if pq(self,"getAoeValue",c) > 0 then
						return pq(c,"objectName")
					end
				end
				if pq(c,"isKindOf","ArcheryAttack") then
					if pq(self,"getAoeValue",c) > 0 then
						return pq(c,"objectName")
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
						return pq(c,"objectName")
					end
				end
				if pq(c,"isKindOf","GodSalvation") then
					if pq(self,"willUseGodSalvation",c) then
						return pq(c,"objectName")
					end
				end
				
			else
				if pq(c,"isKindOf","NatureSlash") and pq(self,"getCardsNum","NatureSlash") == 0 then
					if pq(c,"isKindOf","FireSlash") or pq(c,"isKindOf","ThunderSlash") then
						local dummy_use = pq(self,"aiUseCard",c, dummy())
						if not pq(dummy_use.to,"isEmpty") then
							for _, p in sgs.qlist(dummy_use.to) do
								if pq(p,"isChained") then
									set_tag(self,"ai_se_chenyan_card_name",pq(c,"objectName"))
									if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
										set_tag(self,"ai_se_chenyan_card_id2",ai_se_chenyan_card_id2)
										set_tag(self,"ai_se_chenyan_card_id",ai_se_chenyan_card_id)
									end
									return pq(c,"objectName")
								end
							end
						end
					end
				end
				
				if pq(c,"isKindOf","TrickCard") and not pq(c,"isKindOf","Collateral") then
					local dummy_use = pq(self,"aiUseCard",c, dummy())
					if not pq(dummy_use.to,"isEmpty") then
						for _, p in sgs.qlist(dummy_use.to) do
							if pq(p,"getHp") <= 2 and pq(p,"getCards","he"):length() <= 2 and pq(p,"getHandcardNum") <= 1 then
								set_tag(self,"ai_se_chenyan_card_name",pq(c,"objectName"))
								if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
									set_tag(self,"ai_se_chenyan_card_id2",ai_se_chenyan_card_id2)
									set_tag(self,"ai_se_chenyan_card_id",ai_se_chenyan_card_id)
								end
								return pq(c,"objectName")
							end
						end
					end
				end
			end
		end
	end

	chenyan_mark(self,"AI_do_not_invoke_se_chenyan-Clear","add",1)
	return "cancel"
end

sgs.ai_skill_use["@@se_chenyan"] = function(self, prompt, method)
	local ai_se_chenyan_card_name = tag(self,"ai_se_chenyan_card_name"):toString()
	remove_tag(self,"ai_se_chenyan_card_name")
	local costs={}
 if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear")==0 then
  costs[1]=tag(self,"ai_se_chenyan_card_id"):toInt();remove_tag(self,"ai_se_chenyan_card_id")
  costs[2]=tag(self,"ai_se_chenyan_card_id2"):toInt();remove_tag(self,"ai_se_chenyan_card_id2")
 end
 local use_card=owner_normal(self,"se_chenyan",ai_se_chenyan_card_name,costs)
 local dummy_use = pq(self,"aiUseCard",use_card, dummy())
	local targets = {}
	if not pq(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, pq(p,"objectName"))
		end
		if #targets > 0 then
			return pq(use_card,"getLegacyStringKey") .. "->" .. table.concat(targets, "+")
		end
	end

	chenyan_mark(self,"AI_do_not_invoke_se_chenyan-Clear","add",1)
	return "."
end

sgs.ai_cardsview_valuable["se_chenyan"] = function(self, class_name, player)
	if self.request.reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
		["Analeptic"] = "analeptic",
		["Nullification"] = "nullification",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = pq(player,"getCards","he")
	for _, id in sgs.qlist(pq(player,"getPile","wooden_ox")) do
		call(cards,"prepend",disclosed(self,id))
	end
	for _, c in sgs.qlist(cards) do
		if pq(c,"isKindOf",class_name) then
			no_have = false
			break
		end
	end
	if not no_have or pq(player,"getMark","se_chenyan-Clear") ~= 0 then return end
	if class_name == "Peach" and pq(player,"getMark","Global_PreventPeach") > 0 then return end
	cards = AIList.new(cards)
	sort_keep(self,cards)
	if pq(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(pq(player,"getPile","wooden_ox")) do
			if not disclosed(self,id):isKindOf("Peach") then
				cards[1] = disclosed(self,id)
			end
		end
	end
	if #cards >= 2 then
		
		if cards[1]:isKindOf("Peach")
			or cards[1]:isKindOf("Analeptic")
			or (cards[1]:isKindOf("Jink"))
			or (cards[1]:isKindOf("Slash"))
			
			
			or cards[1]:isKindOf("Nullification")
			or cards[1]:isKindOf("SavageAssault")
			or cards[1]:isKindOf("ArcheryAttack")
			or cards[1]:isKindOf("Duel")
			or cards[1]:isKindOf("ExNihilo")
		then
			return
		end
		if cards[2]:isKindOf("Peach")
			or cards[2]:isKindOf("Analeptic")
			or (cards[2]:isKindOf("Jink"))
			or (cards[2]:isKindOf("Slash"))
			
			
			or cards[2]:isKindOf("Nullification")
			or cards[2]:isKindOf("SavageAssault")
			or cards[2]:isKindOf("ArcheryAttack")
			or cards[2]:isKindOf("Duel")
			or cards[2]:isKindOf("ExNihilo")
		then
			return
		end
	end

	
	
	
		
		if #cards >= 2 then
			
			return (name .. ":se_chenyan[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, cards[1]:getEffectiveId(),
				cards[2]:getEffectiveId())
		elseif not pq(self,"isWeak") then
			return string.format(name .. ":se_chenyan[%s:%s]=.", sgs.Card_NoSuit, 0)
		end
	return
end





local se_tongling_skill = {}
se_tongling_skill.name = "se_tongling"
table.insert(package_skills, se_tongling_skill)
se_tongling_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if #self.enemies == 1 and viewer_role(self,self.enemies[1]) == "lord" then return end
	if pq(self.player,"getMark","@se_tongling") == 0 then return end
	return parse(self,request,"#se_tonglingcard:.:")
end
sgs.ai_skill_use_func["#se_tonglingcard"] = function(card,use,self,request)
	use.card = card
	return
end
sgs.ai_use_value["se_tonglingcard"] = 10
sgs.ai_use_priority["se_tonglingcard"] = 10


sgs.ai_skill_choice["se_tongling_kd"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	return items[math.random(1, #items)]
end

sgs.ai_skill_choice["se_tongling_d"] = function(self, choices, data)
	local items = pq(choices,"split","+")

	return items[math.random(1, #items)]
end


sgs.ai_skill_playerchosen["se_tongling_k"] = function(self, targets)
	
	sort_players(self,self.enemies, "defense")
	return self.enemies[1]
end

sgs.ai_ajustdamage_to.SE_Juyang = function(self, from, to, card, nature)
	if nature=="F" then
		return 1
	elseif nature=="N" then
		return -99
	end
end


sgs.ai_skill_invoke["SE_Zuozhan"] = true

sgs.ai_skill_choice["SE_Zuozhan1"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	local room = self.room
	local p = call(room,"getCurrent")
	if pq(self,"isEnemy",p) and table.contains(items, "1_Zuozhan") then
		return "1_Zuozhan"
	else
		if pq(p,"getHandcardNum") <= pq(p,"getHp") and table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		elseif table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		end
	end
	return items[1]
end

sgs.ai_skill_choice["SE_Zuozhan2"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	local room = self.room
	local p = call(room,"getCurrent")
	if pq(self,"isEnemy",p) then
		if pq(p,"getHandcardNum") <= 1 and pq(p,"getHp") <= 2 and table.contains(items, "3_Zuozhan") then
			return "3_Zuozhan"
		elseif table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		end
	else
		if pq(p,"getHandcardNum") <= pq(p,"getHp") and table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		end
	end
	return items[1]
end

sgs.ai_skill_choice["SE_Zuozhan3"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	local room = self.room
	local p = call(room,"getCurrent")
	if pq(self,"isEnemy",p) then
		if pq(p,"getHandcardNum") <= 1 and pq(p,"getHp") <= 2 and table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		elseif table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		end
	else
		if pq(p,"getHandcardNum") <= pq(p,"getHp") and table.contains(items, "3_Zuozhan") then
			return "3_Zuozhan"
		elseif table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		end
	end
	return items[1]
end

sgs.ai_skill_choice["SE_Zuozhan4"] = function(self, choices, data)
	local items = pq(choices,"split","+")
	local room = self.room
	local p = call(room,"getCurrent")
	if pq(self,"isEnemy",p) then
		if pq(p,"getHandcardNum") <= 1 and pq(p,"getHp") <= 2 and table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		elseif table.contains(items, "3_Zuozhan") then
			return "3_Zuozhan"
		end
	elseif table.contains(items, "1_Zuozhan") then
		return "1_Zuozhan"
	end
	return items[1]
end


function sgs.ai_cardsview_valuable.SE_Gaoling(self, class_name, player)
	if class_name == "Jink"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and (math.ceil(pq(self.player,"getHandcardNum") / 2) * 2 == pq(self.player,"getHandcardNum"))
	then
		return string.format("jink:SE_Gaoling[%s:%s]=.", sgs.Card_NoSuit, 0)
	elseif class_name == "Nullification"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and (math.ceil(pq(self.player,"getHandcardNum") / 2) * 2 == pq(self.player,"getHandcardNum"))
	then
		return string.format("Nullification:SE_Gaoling[%s:%s]=.", sgs.Card_NoSuit, 0)
	end
end

sgs.ai_skill_invoke["SE_Shengmu"] = function(self, data)
	local da = pq(data,"toDamage")
	if pq(self,"isFriend",da.to) then return true end
	return false
end
sgs.ai_skill_cardask["@SE_Shengmu"] = function(self, data, pattern, target)
	local damage = pq(data,"toDamage")
	if pq(self,"isFriend",damage.to) then
		if pq(self,"needToThrowArmor") then
			return "$" .. call(self.player,"getArmor"):getEffectiveId()
		end
		local cards = AIList.new(pq(self.player,"getCards","he"))
		sort_keep(self,cards)
		for _, card in ipairs(cards) do
			if pq(damage.to,"getHandcardNum") < pq(damage.to,"getMaxHp") then
				if pq(card,"isRed") then
					return "$" .. pq(card,"getEffectiveId")
				end
			end
		end
		for _, card in ipairs(cards) do
			return "$" .. pq(card,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@SE_Shengmu"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage and damage.to and promptlist[#promptlist] ~= "" then
		call(self,"updateIntention",player, damage.to, -80)
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|SE_Shengmu"


sgs.ai_skill_invoke["se_jianshi"] = function(self, data)
	return #self.enemies > 0
end


sgs.ai_skill_playerchosen["SE_JianshiTr"] = function(self, targets)
	for _, p in ipairs(self.friends) do
		if pq(p,"getMark","@Wuwei") > pq(self.room,"getAlivePlayers"):length() and pq(self,"damageIsEffective",p, sgs.DamageStruct_Thunder, self.player) then
			return
				p
		end
	end
	local target
	for _, p in ipairs(self.enemies) do
		local GoodMark = { "@Asmodeus", "@Baskervilles", "@Beelzebub", "@daiwei", "@Chamber", "@Efreet", "@Eight",
			"@Father_daughter", "@Frozen_Eu", "@Fuko", "@Gaobai", "@hates", "@HIMIKO",
			"@Kekkai", "@kizuna", "@LimeBell", "@longing", "@MagicEquip", "@Mahou_ai", "@Mammon", "@Patience",
			"@se_qiyuan", "@shenmin", "@shouhu", "@Tianming", "@tianmo", "@Yuzorano" }
		if pq(self,"damageIsEffective",p, sgs.DamageStruct_Thunder, self.player) and pq(self,"isGoodTarget",p, self.enemies, nil) then
			for i = 1, #GoodMark do
				if pq(p,"getMark",GoodMark[i]) > 0 then return p end
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if pq(self,"damageIsEffective",p, sgs.DamageStruct_Thunder, self.player) and pq(self,"isGoodTarget",p, self.enemies, nil) then
			target = p
		end
	end
	if target and pq(self,"damageIsEffective",target, sgs.DamageStruct_Thunder, self.player) then return target end
	for _, p in ipairs(self.enemies) do
		if pq(self,"damageIsEffective",p, sgs.DamageStruct_Thunder, self.player) and not pq(self,"cantbeHurt",target) and pq(self,"canDamage",target,self.player,nil) then
			target = p
		end
	end
	if target and pq(self,"damageIsEffective",target, sgs.DamageStruct_Thunder, self.player) then return target end
	return nil
end

sgs.ai_playerchosen_intention["SE_JianshiTr"] = function(self, from, to)
	local intention = 60
	if pq(to,"getMark","@Wuwei") > 0 then
		intention = -intention
	end
	call(self,"updateIntention",from, to, intention)
end


local se_jianshi_skill = {}
se_jianshi_skill.name = "se_jianshi"
table.insert(package_skills, se_jianshi_skill)
se_jianshi_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends <= 1 then return end
	if pq(self.player,"getMark","@surveillance") <= 1 then return end
	for _, p in ipairs(self.friends) do
		if pq(p,"getMark","@surveillance") == 0 and pq(p,"getHp") > 1 then return parse(self,request,"#se_jianshicard:.:") end
	end
	return
end
sgs.ai_skill_use_func["#se_jianshicard"] = function(card,use,self,request)
	local target
	
	for _, p in ipairs(self.friends) do
		if pq(p,"getMark","@surveillance") == 0 and pq(p,"getHp") > 1 then target = p end
	end
	if target then
		use.card = card
		if use.to then call(use.to,"append",target) end
		return
	end
end
sgs.ai_use_value["se_jianshicard"] = 10
sgs.ai_use_priority["se_jianshicard"] = 6

sgs.ai_skill_invoke["SE_Heimu"] = true

sgs.ai_damage_reason_suppress_intention["SE_Guiyin"] = true


sgs.ai_skill_invoke["SE_Jiawu"] = function(self, data)
	if pq(self.player,"getPhase") == sgs.Player_Discard and pq(self.player,"getMark","jiawu_fin") > 4 then
		pq(self.player,"setMark","jiawu_fin", 0)
		return false
	end
	if pq(self.player,"getPhase") == sgs.Player_Discard then
		pq(self.player,"setMark","jiawu_fin", pq(self.player,"getMark","jiawu_fin") + 1)
	end
	return true
end

sgs.ai_skill_choice["SE_Jiawu"] = function(self, data)
	if pq(self.player,"hasFlag","SE_Jiawu_EquipCard") then
		if not call(self.player,"getWeapon") then return "SE_Jiawu_use" end
		return "SE_Jiawu_give"
	else
		if pq(self.player,"getHp") <= 2 and pq(self.player,"isWounded") then return "SE_Jiawu_use" end
	end
	return "SE_Jiawu_give"
end

sgs.ai_skill_invoke["SE_Zhandan"] = function(self, data)
	local dam = pq(data,"toDamage")
	if dam.to and pq(self,"isFriend",dam.to) then return true end
	return false
end

sgs.ai_skill_cardask["@SE_Zhandanspade"] = function(self,data,pattern,target)
	local cards = AIList.new(pq(self.player,"getCards","eh"))
	sort_keep(self,cards)
	for _,card in ipairs(cards) do
		if pq(card,"getSuit") == sgs.Card_Spade then return "$" .. pq(card,"getEffectiveId") end
	end
	return "."
end
sgs.ai_skill_cardask["@SE_Zhandandiamond"] = function(self,data,pattern,target)
	local cards = AIList.new(pq(self.player,"getCards","eh"))
	sort_keep(self,cards)
	for _,card in ipairs(cards) do
		if pq(card,"getSuit") == sgs.Card_Diamond then return "$" .. pq(card,"getEffectiveId") end
	end
	return "."
end
sgs.ai_skill_cardask["@SE_Zhandanclub"] = function(self,data,pattern,target)
	local cards = AIList.new(pq(self.player,"getCards","eh"))
	sort_keep(self,cards)
	for _,card in ipairs(cards) do
		if pq(card,"getSuit") == sgs.Card_Club then return "$" .. pq(card,"getEffectiveId") end
	end
	return "."
end
sgs.ai_skill_cardask["@SE_Zhandanheart"] = function(self,data,pattern,target)
	local cards = AIList.new(pq(self.player,"getCards","eh"))
	sort_keep(self,cards)
	for _,card in ipairs(cards) do
		if pq(card,"getSuit") == sgs.Card_Heart then return "$" .. pq(card,"getEffectiveId") end
	end
	return "."
end


sgs.ai_skill_discard["SE_Lingshang"] = function(self, discard_num, min_num, optional, include_equip)
	local handcards = AIList.new(pq(self.player,"getCards","he"))
	if pq(self,"isWeak") and pq(self.room,"getDrawPile"):length() < pq(self.room,"getDiscardPile"):length() then return {} end
	sort_keep(self,handcards)
	local name = tag(self,"SE_Lingshang_type"):toString()
	local to_discard = {}
	for _, c in ipairs(handcards) do
		if #to_discard < discard_num then
			if ((name == "BasicCard" and pq(c,"isKindOf","BasicCard") and not pq(c,"isKindOf","Peach")) or (name == "TrickCard" and pq(c,"isKindOf","TrickCard")) or (name == "EquipCard" and pq(c,"isKindOf","EquipCard"))) then
				table.insert(to_discard, pq(c,"getEffectiveId"))
			end
		end
	end
	if #to_discard == discard_num then
		return to_discard
	end
	return {}
end

sgs.ai_skill_invoke["SE_Lingshang"] = function(self, data)
	local cardType = pq(data,"toString")
	local peaches = pq(self,"getCardsNum","Peach")
	if cardType == "BasicCard" then
		if pq(self,"isWeak",self.player) then return false end
		if peaches > 0 and pq(self.player,"hasSkill","SE_Guiling") then return false end
	end
	return true
end

sgs.ai_skill_choice["SE_Lingshang_type"] = function(self, data)
	for _, p in ipairs(self.friends) do
		if pq(self,"isWeak",p) then return "BasicCard" end
	end
	return "TrickCard"
end

sgs.ai_skill_choice["SE_Lingshang"] = function(self, choices, data) 
	local choice_table = pq(choices,"split","+")
	if pq(self.player,"getPhase") == sgs.Player_Play and #self.enemies > 0 then
		if call(self.player,"getWeapon") and call(self.player,"getWeapon"):isKindOf("Crossbow") then
			if not call(self.player,"getOffensiveHorse") and pq(self.player,"getHandcardNum") > pq(self.player,"getHp") + 1 then
				if table.contains(choice_table, "ChiTu") then return "ChiTu" end
				if table.contains(choice_table, "DaYuan") then return "DaYuan" end
				if table.contains(choice_table, "ZiXing") then return "ZiXing" end
			end
			if pq(self.player,"getHandcardNum") > pq(self.player,"getHp") then
				if table.contains(choices, "slash") then return "slash" end
			end
		end
	end
	for _, p in ipairs(self.friends) do
		if pq(self,"isWeak",p) then
			if table.contains(choice_table, "peach") then return "peach" end
		end
		if pq(self,"isWeak",p) and pq(p,"objectName") == pq(self.player,"objectName") then
			if table.contains(choice_table, "jink") then return "jink" end
		end
	end
	if table.contains(choice_table, "ex_nihilo") then return "ex_nihilo" end
	if #self.enemies > #self.friends and table.contains(choice_table, "savage_assault") then return "savage_assault" end
	if #self.enemies < #self.friends and table.contains(choice_table, "duel") then return "duel" end
	if table.contains(choice_table, "archery_attack") then return "archery_attack" end
	if table.contains(choice_table, "indulgence") then return "indulgence" end
	return choice_table[1]
end


sgs.ai_skill_invoke["SE_Wuwei"] = function(self, data)
	local use = pq(data,"toCardUse")
	if pq(use.to,"length") > 1 then return true end
	local target = pq(use.to,"at",0)
	if pq(self,"isFriend",target) then return false end
	if pq(self,"cantDamageMore",self.player,target) then return false end
	if not pq(self,"slashIsEffective",pq(data,"toCardUse").card, target)then return false end
	local player = use.from
	if pq(player,"getMark","@Wuwei") > pq(self.room,"getAllPlayers",true):length() and pq(player,"getMark","@Wuwei") > 4 then return true end
	if pq(target,"isKongcheng") or pq(self,"canLiegong",target, player) then return true end
	if pq(self,"getCardsNum","Slash") > 1 and pq(target,"getHandcardNum") > 2 and pq(player,"getMark","@Wuwei") <= 2 then return false end
	if pq(player,"getMark","@Wuwei") < 3 and pq(self,"getCardsNum","Slash") > 1 then return true end
	if pq(self,"isWeak",target) and math.random(1, 2) == 1 then return true end
	if pq(target,"getHandcardNum") == 1 and math.random(1, 3) > 1 then return true end
	if getCardsNum("Jink", target, self.player) < 1 then return true end
	if pq(target,"getHandcardNum") > 3 then return false end
	return math.random(1, 5) == 1
end


sgs.ai_ajustdamage_from.SE_Wuwei = function(self, from, to, card, nature)
	if (card and pq(card,"isKindOf","Slash")) and (pq(card,"hasFlag","wuwei_used") or not pq(self,"beFriend",to, from))
	then
		return 1
	end
end

sgs.ai_use_revises.SE_Wuwei = function(self, card, use)
	if pq(card,"isKindOf","Slash") and pq(self.player,"getMark","@Wuwei") > 2
	then
		call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end
sgs.ai_can_damagehp.SE_Wuwei = function(self, from, card, to)
	return pq(to,"getHp")+pq(self,"getAllPeachNum")-pq(self,"ajustDamage",from,to,1,card)>0
	and pq(self,"canLoseHp",from,card,to) and pq(to,"getMark","@Wuwei") == 0
end

ai_audited_aliases.register{id="ai_cardneed.SE_Wuwei",registry="ai_cardneed",path={"SE_Wuwei"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_canliegong_skill.SE_Wuwei = function(self, from, to)
	return pq(from,"getMark","@Wuwei") > pq(self.room,"getAlivePlayers"):length() and pq(from,"getMark","@Wuwei") > 4
end


sgs.ai_skill_invoke["SE_Tiansuo"] = function(self, data)
	local use = pq(data,"toCardUse")
	if pq(self,"isEnemy",pq(use.to,"at",0)) and pq(self,"isGoodChainTarget",pq(use.to,"at",0), use.card, use.from) then return true end
	return false
end

sgs.ai_use_revises.se_gate = function(self, card, use)
	if pq(card,"isKindOf","Weapon")
	then
		same = call(self,"getSameEquip",card)
		if same
		then
			return false
		end
	end
end

sgs.ai_skill_invoke["se_gate"] = true


local se_gate_skill = {}
se_gate_skill.name = "se_gate"
table.insert(package_skills, se_gate_skill)
se_gate_skill.getTurnUseCard=function(self,inclusive,request)
	local player = self.player
	local hasWea = false
	if call(player,"getWeapon") then hasWea = true end
	if not hasWea then
		if pq(player,"getPile","pika_gob"):length() > 0 then
			for _, p in ipairs(self.enemies) do
				if pq(self,"slashIsEffective",call(self,"cloneEvaluationCard","slash"), p) or pq(self,"slashIsEffective",call(self,"cloneEvaluationCard","fire_slash"), p) then
					hasWea = true
					break
				end
			end
		end
	end
	if not hasWea then
		for _, card in sgs.qlist(pq(player,"getHandcards")) do
			if pq(card,"isKindOf","Weapon") then
				hasWea = true
				break
			end
		end
	end
	if hasWea then
		for _, id in sgs.qlist(pq(self.player,"getPile","pika_gob")) do
			local card = disclosed(self,id)
			local suit = pq(card,"getSuitString")
			local number = pq(card,"getNumberString")
			local card_id = pq(card,"getEffectiveId")
			return parse(self,request,"#se_gatecard:" .. pq(card,"getId") .. ":")
		end
	end
end

sgs.ai_skill_use_func["#se_gatecard"] = function(card,use,self,request)
	local cards = AIList.new(pq(self.player,"getHandcards"))
	local needed = {}
	for _, acard in ipairs(cards) do
		if pq(acard,"isKindOf","Weapon") then
			table.insert(needed, pq(acard,"getEffectiveId"))
		end
	end
	if call(self.player,"getWeapon") then
		table.insert(needed, call(self.player,"getWeapon"):getEffectiveId())
	end
	if needed and #needed > 0 then
		use.card=final_parse(self,request,"#se_gatecard:" .. table.concat(needed, "+") .. ":")
		return
	end

	for _, id in sgs.qlist(pq(self.player,"getPile","pika_gob")) do
		local card = disclosed(self,id)
		local suit = pq(card,"getSuitString")
		local number = pq(card,"getNumberString")
		local card_id = pq(card,"getEffectiveId")
		local target = nil
		local normal_slash = owner_clone(self,"se_gate","slash",pq(card,"getSuit"),pq(card,"getNumber"))
		
		local thunder_slash = owner_clone(self,"se_gate","thunder_slash",pq(card,"getSuit"),pq(card,"getNumber"))
		
		local fire_slash = owner_clone(self,"se_gate","fire_slash",pq(card,"getSuit"),pq(card,"getNumber"))
		
		for _, enemy in ipairs(self.enemies) do
			if pq(self,"isGoodTarget",enemy, self.enemies, nil) then
				if pq(self,"slashIsEffective",thunder_slash, enemy, self.player) and pq(self,"isGoodChainTarget",enemy, thunder_slash, self.player) and pq(self.player,"canSlash",enemy, thunder_slash, false) then
					target = enemy
					call(self,"setStrategyMemory","dongmanbao.GateNatural","thunder_slash")
				elseif pq(self,"slashIsEffective",fire_slash, enemy, self.player) and pq(self,"isGoodChainTarget",enemy, fire_slash, self.player) and pq(self.player,"canSlash",enemy, fire_slash, false) then
					target = enemy
					call(self,"setStrategyMemory","dongmanbao.GateNatural","fire_slash")
				elseif pq(self,"slashIsEffective",normal_slash, enemy, self.player) and pq(self.player,"canSlash",enemy, normal_slash, false) then
					target = enemy
					call(self,"setStrategyMemory","dongmanbao.GateNatural","slash")
				end
			end
		end
		if not target then return end
		use.card=final_parse(self,request,"#se_gatecard:" .. pq(card,"getId") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end


sgs.ai_skill_choice["se_gate"]     = function(self, choices, data)
	if self:getStrategyMemory("dongmanbao.GateNatural") == "thunder_slash" then
		return "gateThunder"
	elseif self:getStrategyMemory("dongmanbao.GateNatural") == "fire_slash" then
		return "gateFire"
	elseif self:getStrategyMemory("dongmanbao.GateNatural") == "slash" then
		return "gateNormal"
	end
	return "gateFire"
end

sgs.ai_use_value["se_gatecard"]    = 8
sgs.ai_use_priority["se_gatecard"] = 5


ai_audited_aliases.register{id="ai_cardneed.se_gate",registry="ai_cardneed",path={"se_gate"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|se_gate"
sgs.hit_skill = sgs.hit_skill .. "|SE_Tiansuo"

sgs.ai_canliegong_skill.SE_Tiansuo = function(self, from, to)
	return pq(to,"isChained") and pq(to,"isKongcheng")
end

sgs.ai_skill_cardask["@SE_Tiansuo-discard"] = function(self, data, pattern)
	local use = pq(data,"toCardUse")
	if not pq(self,"slashIsEffective",use.card, self.player, use.from)
		or (not pq(self,"hasHeavyDamage",use.from, use.card, pq(use.to,"first"))
			and (pq(self,"canAttack",self.player, use.from, true) or pq(self,"needToLoseHp",self.player, use.from, nil))) then
		return "."
	end
	if not pq(self,"hasHeavyDamage",use.from, use.card, pq(use.to,"first")) and pq(self,"getCardsNum","Peach") > 0 then return "." end
	if pq(self,"getCardsNum","Jink") == 0 or not sgs.isJinkAvailable(use.from, self.player, use.card, true) then return "." end
	if pq(self,"NeedDoubleJink",use.from, self.player) and pq(self,"getCardsNum","Jink") <= 1 then return "." end

	local cards = AIList.new(pq(self.player,"getHandcards"))
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		if not pq(card,"isKindOf","BasicCard") or (not pq(self,"isWeak") and (pq(self,"getKeepValue",card) > 8 or pq(self,"isValuableCard",card)))
			or (isCard("Jink", card, self.player) and pq(self,"getCardsNum","Jink") - 1 < (pq(self,"NeedDoubleJink",use.from, self.player) and 2 or 1)) then
			continue
		end
		return "$" .. pq(card,"getEffectiveId")
	end
end


local se_origin_skill = {}
se_origin_skill.name = "se_origin"
table.insert(package_skills, se_origin_skill)
se_origin_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if (not pq(self.player,"isWounded")) and pq(self.player,"getMark","@origin_bullet") > 0 then return end
	if (not pq(self.player,"isLord") and pq(self.player,"getMaxHp") > 3) or pq(self.player,"getMaxHp") > 4 and pq(self,"getCardsNum","Slash") > 0 then
		return parse(self,request,"#se_origincard:.:")
	end
	local slash = call(self,"cloneEvaluationCard","slash")
	
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHandcardNum") == 0 and pq(self.player,"inMyAttackRange",enemy) and pq(self,"slashIsEffective",slash, enemy) and pq(self,"getCardsNum","Slash") > 0 then
			if pq(self.player,"getMark","@origin_bullet") > 0 then return end
			return parse(self,request,"#se_origincard:.:")
		end
	end
end

sgs.ai_skill_use_func["#se_origincard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#se_origincard:.:")
	return
end

sgs.ai_use_value["se_origincard"]       = 6
sgs.ai_use_priority["se_origincard"]    = 5

sgs.ai_skill_choice["se_origin"]        = function(self, choices, data)
	local use = pq(data,"toCardUse")
	local target = pq(use.to,"at",0)
	if not pq(self,"isEnemy",target) then return "use_normal" end
	local slash = call(self,"cloneEvaluationCard","slash")
	
	if pq(target,"getHandcardNum") == 0 and pq(self,"slashIsEffective",slash, target) then
		return
		"use_origin"
	end
	if getCardsNum("Jink", target, self.player) < 1 then return "use_origin" end
	if pq(self,"getCardsNum","Slash") > 0 and math.random(1, 15) == 1 then return "use_origin" end
	if pq(self.player,"hasFlag","slash_one") and math.random(1, 4) > 1 then return "use_origin" end
	if math.random(1, 10) == 1 then return "use_origin" end
	return "use_normal"
end
ai_audited_aliases.register{id="ai_cardneed.se_origin",registry="ai_cardneed",path={"se_origin"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|se_origin"

local se_bilingvs_skill = {}
se_bilingvs_skill.name                  = "se_bilingvs"
table.insert(package_skills, se_bilingvs_skill)
se_bilingvs_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getMark","@Biling_kiri") == 0 then return end
	if #self.enemies == 0 then return end
	if #self.enemies == 1 and #self.friends == 1 then return end
	for _, enemy in ipairs(self.enemies) do
		if second_general_present(self,enemy) then
			return parse(self,request,"#se_bilingvscard:.:")
		end
	end
	if #self.enemies == 1 or #self.friends == 1 then return end
	local slash = call(self,"cloneEvaluationCard","slash")
	
	for _, enemy in ipairs(self.enemies) do
		if pq(enemy,"getHp") <= 1 and pq(self,"slashIsEffective",slash, enemy) then
			return parse(self,request,"#se_bilingvscard:.:")
		end
	end
	if pq(self.player,"getHp") == 1 then
		for _, enemy in ipairs(self.enemies) do
			if pq(enemy,"getHp") <= 2 and pq(self,"slashIsEffective",slash, enemy) then
				return parse(self,request,"#se_bilingvscard:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#se_bilingvscard"] = function(card,use,self,request)
	if pq(self.player,"getMark","@Biling_kiri") == 0 then return end
	if #self.enemies == 0 then return end
	local target
	for _, enemy in ipairs(self.enemies) do
		if second_general_present(self,enemy) then
			target = enemy
		end
	end
	if not target then
		if #self.enemies == 1 or #self.friends == 1 then return end
		local slash = call(self,"cloneEvaluationCard","slash")
		
		for _, enemy in ipairs(self.enemies) do
			if pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, nil) then
				target = enemy
			end
		end
	end

	if not target then
		if pq(self.player,"getHp") == 1 then
			local slash = call(self,"cloneEvaluationCard","slash")
			
			for _, enemy in ipairs(self.enemies) do
				if pq(self,"slashIsEffective",slash, enemy) and pq(self,"isGoodTarget",enemy, self.enemies, nil) then
					target = enemy
				end
			end
		end
	end

	if not target then return end
	if use.to then call(use.to,"append",target) end
	use.card=final_parse(self,request,"#se_bilingvscard:.:")
	return
end

sgs.ai_skill_playerchosen["se_biling"]    = function(self, targets)
	local target = tag(self,"se_bilingvs_target"):toPlayer()
	local slash = call(self,"cloneEvaluationCard","slash")
			
	if viewer_role(self,self.player) == "rebel" then
		local lord = call(self.room,"getLord")
		if pq(targets,"contains",lord) and pq(self,"slashIsEffective",slash, target, lord) then
			return
				lord
		end
	else
		for _, p in sgs.qlist(targets) do
			if pq(self,"isFriend",p) and pq(self,"hasSkills","SE_Juji|SE_Juji_Reki|LuaTianmo|LuaBimie|LuaGungnir|SE_Shuangqiang", p) and pq(self,"slashIsEffective",slash, target, p) then
				return
					p
			end
		end
		for _, p in sgs.qlist(targets) do
			if pq(self,"isFriend",p) and pq(self,"slashIsEffective",slash, target, p) then
				return
					p
			end
		end
	end
end

sgs.ai_use_value["se_bilingvscard"]       = 8
sgs.ai_use_priority["se_bilingvscard"]    = 1.8
sgs.ai_card_intention.se_bilingvscard     = 100

sgs.ai_ajustdamage_from.se_biling         = function(self, from, to, card, nature)
	if pq(to,"getMark","@Biling_target") > 0 then
		return -99
	end
end

sgs.ai_skill_invoke["se_jianqiao"]        = function(self, data)
	local damage = pq(data,"toDamage")
	if viewer_role(self,self.player) == "loyalist" and pq(self,"isWeak",call(self.room,"getLord")) then return false end
	if pq(self,"isFriend",damage.to) and (pq(self,"getCardsNum","Peach") == 0 or damage.damage > 1) and (pq(self,"damageIsEffective",damage.to, damage.nature, damage.from)) then return true end
	return false
end


local se_banyun_skill = {}
se_banyun_skill.name                      = "se_banyun"
table.insert(package_skills, se_banyun_skill)
se_banyun_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if pq(self.player,"hasUsed","#se_banyuncard") then
		return
	end
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and pq(self,"isGoodTarget",enemy, self.enemies, nil) then
			return parse(self,request,"#se_banyuncard:.:")
		end
	end
end

sgs.ai_skill_use_func["#se_banyuncard"] = function(card,use,self,request)
	if #self.enemies == 0 then return end
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if pq(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and pq(self,"isGoodTarget",enemy, self.enemies, nil) then
			target = enemy
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_banyuncard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["se_banyuncard"]       = 6
sgs.ai_use_priority["se_banyuncard"]    = 5

sgs.ai_skill_playerchosen["se_banyun"]  = function(self, targets)
	targets = AIList.new(targets)
	if role_count(self,"rebel") == 0 then
		local lord = call(self.room,"getLord")
		if lord and pq(self,"isFriend",lord) and pq(lord,"objectName") ~= pq(self.player,"objectName") then
			return lord
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not pq(self,"willSkipPlayPhase",AssistTarget) then
		return AssistTarget
	end

	sort_players(self,self.friends_noself, "chaofeng")
	for _, target in ipairs(self.friends_noself) do
		if not pq(target,"hasSkill","dawu") and pq(target,"hasSkills","yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not pq(self,"willSkipPlayPhase",target) or pq(target,"hasSkill","shensu")) then
			return target
		end
	end
	for _, p in ipairs(targets) do
		if pq(self,"isFriend",p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		return p
	end
end





function sgs.ai_slash_prohibit.se_shenglong(self, from, to)
	if pq(from,"hasSkill","jueqing") or (pq(from,"hasSkill","nosqianxi") and pq(from,"distanceTo",to) == 1) then return false end
	if pq(from,"hasFlag","NosJiefanUsed") then return false end
	if pq(from,"getHandcardNum") == 1 and pq(from,"getEquips"):length() == 0 and pq(from,"getHandcards"):at(0):isKindOf("Slash") and pq(from,"getHp") >= 2 then return false end
	return pq(from,"getHp") + pq(from,"getEquips"):length() < 4 or pq(from,"getHp") < 2 or
		(pq(from,"getHandcardNum") > 3 and pq(from,"getHp") <= 3)
end

sgs.ai_can_damagehp.se_shenglong = function(self, from, card, to)
	if from and pq(to,"getHp") + pq(self,"getAllPeachNum") - pq(self,"ajustDamage",from, to, 1, card) > 0
		and pq(self,"canLoseHp",from, card, to)
	then
		return pq(self,"isEnemy",from) and not pq(self,"cantbeHurt",from) and pq(self,"canDamage",from,self.player,nil)
	end
end



sgs.ai_skill_invoke["se_shifeng"] = function(self, data)
	local damage = pq(data,"toDamage")
	if pq(self,"isFriend",damage.to) and not pq(self,"needToLoseHp",damage.to, damage.from) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke["se_shifeng"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",player, damage.to, -80)
		end
	end
end

sgs.ai_view_as.se_zhiyan = function(card, player, card_place)
	if pq(player,"getMark","@Yukino_shifeng") < math.floor(pq(player,"getRoom"):getAlivePlayers():length() / 5) + 1 then return end
	if pq(player,"getMark","@yukino_zhiyan") < 1 then return end
	return ("nullification:se_zhiyan[%s:%s]=."):format(sgs.Card_NoSuit, 0)
end

sgs.ai_skill_invoke["se_wenchang"] = function(self, data)
	local damage = pq(data,"toDamage")
	if pq(self,"isFriend",damage.to) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke["se_wenchang"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",player, damage.to, -80)
		end
	end
end


function sgs.ai_cardneed.se_wenchang(to, card)
	return pq(to,"getCards","h"):length() <= 2
end

sgs.ai_skill_cardchosen["se_wenchang"] = function(self, who, flags)
	local card
	local cards = AIList.new(pq(who,"getEquips"))
	local handcards = AIList.new(pq(who,"getHandcards"))
	if pq(self,"isFriend",who) then
		if pq(self,"needToThrowArmor",who) then
			return call(who,"getArmor")
		end
		if pq(who,"hasSkills",sgs.lose_equip_skill) or pq(self,"doDisCard",who, "he") then
			for _, card in ipairs(cards) do
				if pq(card,"isKindOf","Weapon") then
					if pq(card,"isKindOf","Crossbow") or pq(card,"isKindOf","Blade") then continue end
					if pq(card,"isKindOf","Axe") or pq(card,"isKindOf","GudingBlade") then continue end
				elseif pq(card,"isKindOf","Armor") then
					if not pq(self,"hasSkills","bazhen|yizhong|linglong") and pq(self,"isWeak",who) then
						continue
					end
				elseif pq(card,"isKindOf","DefensiveHorse") then
					if pq(self,"isWeak",who) then continue end
				end
				if pq(card,"isBlack") then continue end
				return card
			end
		end
		if not pq(who,"isKongcheng") then return handcards[1] end
		return cards[1]
	else
		if #handcards == 1 and pq(handcards[1],"hasFlag","visible") then table.insert(cards, handcards[1]) end
		if not pq(who,"hasSkills",sgs.lose_equip_skill) then
			for _, card in ipairs(cards) do
				if pq(card,"isRed") then return card end
				if pq(card,"isKindOf","Weapon") then
					if pq(card,"isKindOf","Crossbow") or pq(card,"isKindOf","Blade") then return card end
					if pq(card,"isKindOf","Axe") or pq(card,"isKindOf","GudingBlade") then return card end
				elseif pq(card,"isKindOf","Armor") then
					if not pq(self,"hasSkills","bazhen|yizhong|linglong") and pq(self,"isWeak",who) then
						return card
					end
				elseif pq(card,"isKindOf","DefensiveHorse") then
					if pq(self,"isWeak",who) then return card end
				end
			end
			if #cards > 0 then return cards[1] end
		end
	end
	return nil
end

sgs.recover_hp_skill = sgs.recover_hp_skill.. "|se_wenchang"

sgs.ai_skill_invoke["se_yuanxin"] = function(self, data)
	local damage = pq(data,"toDamage")
	if pq(self,"isFriend",damage.to) and not pq(damage.from,"hasSkill","SE_Shuangqiang") then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke["se_yuanxin"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",player, damage.to, -80)
		end
	end
end
sgs.ai_skill_cardchosen["se_linmo"] = function(self, who, flags)
	local cards = pq(who,"getCards","he")
	sort_keep(self,cards, true)
	return pq(cards,"first")
end

sgs.ai_skill_invoke["se_linmo"] = function(self, data)
	local use = pq(data,"toCardUse")
	if pq(self,"isWeak") and (pq(use.card,"isKindOf","Peach") or pq(use.card,"isKindOf","Analeptic")) then return true end
	if call(self.player,"getWeapon") and call(self.player,"getWeapon"):isKindOf("Crossbow") and pq(use.card,"isKindOf","Slash") then return true end
	if not pq(self,"isWeak") and (pq(use.card,"isKindOf","Snatch") or pq(use.card,"isKindOf","ExNihilo") or pq(use.card,"isKindOf","Dismantlement") or pq(use.card,"isKindOf","reijyuu")) then return true end
	return false
end

sgs.ai_view_as.se_linmo = function(card, player, card_place)
	if pq(player,"getPile","drawing"):length() == 0 then return end
	local suit = pq(card,"getSuitString")
	local number = pq(card,"getNumberString")
	local card_id = pq(card,"getEffectiveId")

	local tp

	if player_disclosed(player,pq(player,"getPile","copying"):at(0)):isKindOf("BasicCard") then tp = "BasicCard" end
	if player_disclosed(player,pq(player,"getPile","copying"):at(0)):isKindOf("TrickCard") then tp = "TrickCard" end
	if player_disclosed(player,pq(player,"getPile","copying"):at(0)):isKindOf("EquipCard") then tp = "EquipCard" end
	if not tp then return end
	if pq(card,"isKindOf",tp) then
		local name = player_disclosed(player,pq(player,"getPile","drawing"):at(0)):objectName()
		return (name .. ":se_linmo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local se_linmo_skill = {}
se_linmo_skill.name = "se_linmo"
table.insert(package_skills, se_linmo_skill)
se_linmo_skill.getTurnUseCard=function(self,inclusive,request)
	if pq(self.player,"getPile","drawing"):length() == 0 then return end
	local usable_cards = AIList.new(pq(self.player,"getCards","h"))
	local equips = AIList.new(pq(self.player,"getCards","e"))
	for _, e in ipairs(equips) do
		if pq(e,"isKindOf","DefensiveHorse") or pq(e,"isKindOf","OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	if pq(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(pq(self.player,"getPile","wooden_ox")) do
			table.insert(usable_cards, disclosed(self,id))
		end
	end
	sort_use(self,usable_cards, true)
	local cards = {}
	local tp

	if disclosed(self,pq(self.player,"getPile","copying"):at(0)):isKindOf("BasicCard") then tp = "BasicCard" end
	if disclosed(self,pq(self.player,"getPile","copying"):at(0)):isKindOf("TrickCard") then tp = "TrickCard" end
	if disclosed(self,pq(self.player,"getPile","copying"):at(0)):isKindOf("EquipCard") then tp = "EquipCard" end
	if not tp then return end
	for _, c in ipairs(usable_cards) do
		local cardex = owner_clone(self,"se_linmo",disclosed(self,pq(self.player,"getPile","drawing"):at(0)):objectName(),pq(c,"getSuit"),pq(c,"getNumber"))
		if pq(c,"isKindOf",tp) and not pq(self.player,"isCardLimited",cardex, sgs.Card_MethodUse, true) and pq(cardex,"isAvailable",self.player) and not pq(c,"isKindOf","Peach") and not (pq(c,"isKindOf","Jink") and pq(self,"getCardsNum","Jink") < 3) and not (pq(c,"isKindOf","WoodenOx") and pq(self.player,"getPile","wooden_ox"):length() > 0) then
			local name = disclosed(self,pq(self.player,"getPile","drawing"):at(0)):objectName()
			return parse(self,request,(name .. ":se_linmo[%s:%s]=%d"):format(pq(c,"getSuitString"), pq(c,"getNumberString"),
				pq(c,"getEffectiveId")))
		end
	end
end
sgs.ai_use_priority["se_linmo"] = 10
sgs.ai_use_value["se_linmo"] = 10



sgs.ai_skill_invoke["se_fupao"] = function(self, data)
	local use = pq(data,"toCardUse")
	if pq(self,"isFriend",use.from) then
		for _, p in sgs.qlist(use.to) do
			if pq(self,"isFriend",p) and not (pq(self,"needToLoseHp",p, self.player) or pq(self,"canAttack",p, self.player)) and pq(self,"slashIsEffective",call(self,"cloneEvaluationCard","slash"), p, self.player) and pq(self,"isWeak",p) then
				return false
			end
			if pq(self,"isEnemy",p) and not pq(self,"isGoodTarget",p, self.enemies, nil) and pq(self,"canAttack",p, self.player) then
				return false
			end
		end
		return true
	end
	return false
end

local function response_descriptor(self,wire)
 if type(wire)~='string'or wire=='.'then return wire end
 local class,costs,user=wire_parts(wire)
 if class then local value={skill=known(skill_cards[class],class),legacy_class=class,subcards=costs};if user then value.user_string=user end;return value end
 local name,skill,costs=normal_parts(wire);return spec(self,skill,name,costs)
end
for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end

do local source=sgs.ai_cardsview_valuable["SE_Gaoling"];sgs.ai_cardsview_valuable["SE_Gaoling"]=function(self,...)return response_descriptor(self,source(self,...))end end

do local source=sgs.ai_cardsview_valuable["se_chenyan"];sgs.ai_cardsview_valuable["se_chenyan"]=function(self,...)return response_descriptor(self,source(self,...))end end

do local source=sgs.ai_cardsview_valuable["se_tianming"];sgs.ai_cardsview_valuable["se_tianming"]=function(self,...)return response_descriptor(self,source(self,...))end end

do local source=sgs.ai_skill_use["@@SE_Nagong_Geiqian"];sgs.ai_skill_use["@@SE_Nagong_Geiqian"]=function(self,...)
 local wire=source(self,...);if wire==nil or wire=='.'or type(wire)~='string'then return wire end
 local cw,targets=wire:match('^(.-)%-%>(.*)$');cw=cw or wire
 local use=AIUsePlan.new();use.card=final_parse(self,nil,cw)
 if targets then for _,name in ipairs(targets:split('+'))do use.to:append(known(resolve(self,name),'response target'))end end
 return use:toAnswer()
end end

do local source=sgs.ai_skill_use["@@se_chenyan"];sgs.ai_skill_use["@@se_chenyan"]=function(self,...)
 local wire=source(self,...);if wire==nil or wire=='.'or type(wire)~='string'then return wire end
 local cw,targets=wire:match('^(.-)%-%>(.*)$');cw=cw or wire
 local use=AIUsePlan.new();use.card=final_parse(self,nil,cw)
 if targets then for _,name in ipairs(targets:split('+'))do use.to:append(known(resolve(self,name),'response target'))end end
 return use:toAnswer()
end end

do local source=sgs.ai_view_as["se_linmo"];sgs.ai_view_as["se_linmo"]=function(card,player,...)
 local wire=source(card,player,...);if wire==nil then return end
 local name,skill,costs=normal_parts(wire)
 if #costs~=1 or costs[1]~=pq(card,'getEffectiveId')then ai_unsupported('view-as source material changed','dongmanbao.view_as')end
 return{name=name,skill=skill,suit=pq(card,'getSuit'),number=pq(card,'getNumber'),subcards=costs}
end end

do local source=sgs.ai_view_as["se_zhiyan"];sgs.ai_view_as["se_zhiyan"]=function(card,player,...)
 local wire=source(card,player,...);if wire==nil then return end
 local name,skill,costs=normal_parts(wire)
 if #costs~=1 or costs[1]~=pq(card,'getEffectiveId')then ai_unsupported('view-as source material changed','dongmanbao.view_as')end
 return{name=name,skill=skill,suit=pq(card,'getSuit'),number=pq(card,'getNumber'),subcards=costs}
end end

local function event_data(self,event,method)
 -- The shared event DTO exposes toCardUse even on Dying. Only the exact
 -- callback-required method proves that this event is already adapted.
 if type(event[method])=='function'then return event end
 return{toDying=function()local row=event.details or{};return{who=resolve(self,known(row.who or event.to,'dying target'))}end,
 toCardUse=function()local details=event.details or{};if details.card then return struct(self,{from=event.from,to=known(event.targets,'event target list'),card=details.card},'use')end;ai_unsupported('CardFinished use descriptor unavailable','dongmanbao.event_use')end}
end
for _,item in ipairs({{sgs.Dying or'Dying','SE_Dapo','toDying'},{sgs.CardFinished or'CardFinished','se_qiyuancard','toCardUse'}})do
 local source=sgs.ai_event_callback[item[1]][item[2]]
 sgs.ai_event_callback[item[1]][item[2]]=function(self,player,event)return source(self,player,event_data(self,event,item[3]))end
end
