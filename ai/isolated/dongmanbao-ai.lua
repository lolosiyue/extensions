-- Fixed dongmanbao-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local source_uses={}
local checkEnemyDetailed,checkFriendDetailed
local known = AIValue.requireKnown


local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local skill_cards={["#SE_GeassCard"]="SE_Geass",["#SE_Nagong_Geiqian"]="SE_Nagong_Geiqian",["#se_banyuncard"]="se_banyun",["#se_bianhuaCard"]="se_bianhua",["#se_bilingvscard"]="se_biling",["#se_cairencard"]="se_cairen",["#se_chenglingcard"]="se_chengling",["#se_chenyan"]="se_chenyan",["#se_chongjingcard"]="se_chongjing",["#se_chouyuancard"]="se_chouyuan",["#se_dushecard"]="se_dushe",["#se_erdao_oldCard"]="se_erdao_old",["#se_erdaocard"]="se_erdao",["#se_gaobaicard"]="se_gaobai",["#se_gatecard"]="se_gate",["#se_hengsaocard"]="se_hengsao",["#se_huanyuancard"]="se_huanyuan",["#se_jianguicard"]="se_jiangui",["#se_jianshicard"]="se_jianshi",["#se_jianwucard"]="se_jianwu",["#se_jianyucard"]="se_jianyu",["#se_jiejiecard"]="se_jiejie",["#se_jieshucard"]="se_jieshu",["#se_kanhucard"]="se_kanhu",["#se_liaolicard"]="se_liaoli",["#se_mipacard"]="se_mipa",["#se_origincard"]="se_origin",["#se_paojicard"]="se_paoji",["#se_poyicard"]="se_poyi",["#se_qingqiangweicard"]="se_qingqiangwei",["#se_qiyuancard"]="se_qiyuan",["#se_shengjiancard"]="se_shengjian",["#se_shixiancard"]="se_shixian",["#se_shourencard"]="se_shouren",["#se_shunshancard"]="se_shunshan",["#se_tiaoyuecard"]="se_tiaoyue",["#se_tonglingcard"]="se_tongling",["#se_xunyucard"]="se_xunyu",["#se_yekongcard"]="se_yekong",["#se_youhuocard"]="se_youhuo",["#se_zhanjingcard"]="se_zhanjing",["#se_zhijiancard"]="se_zhijian",["#se_zhilingcard"]="se_zhiling",["#se_zhiyucard"]="se_zhiyu",["#se_zhurencard"]="se_zhuren"}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'dongmanbao disclosed card '..tostring(id))end
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
local function ai_present(self,player)
 local state=player:getState()
 if state=='online'then return false end -- native getAI has this unconditional gate
 return self:useKnowledgeEstimate({status='estimate',value=true,
  basis='dongmanbao.ai_presence_nononline_public_state_prior',player=player:objectName()}, 'dongmanbao.ai_presence')
end
local function second_general_present(self,player)
 local name=player:getGeneral2Name()
 if type(name)=='string'and name~=''then return true end
 return self:useKnowledgeEstimate({status='estimate',value=false,
  basis='dongmanbao.second_general_no_public_identity_evidence_prior',player=player:objectName()}, 'dongmanbao.second_general_presence')
end
local function viewer_role(self,p)local v=p:getRole();if v~=nil then return v end;return self:useKnowledgeEstimate({status='estimate',value=self:getRoleEstimate(p),basis='viewer_role_estimate_private_role',player=p:objectName()}, 'dongmanbao.role')end
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
 elseif key=='CurrentDamageStruct'then value=self:getDecisionContext().damage
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
 local epoch=known(known(AIWorldLifecycle.epochs(self.world,'turn'),'turn mark clear epochs')[self.player:objectName()],'owner mark clear epoch')
 local row=self:getStrategyMemory('dongmanbao.mark.'..key);local base=self.player:getMark(key);local offset=row and row.epoch==epoch and row.offset or 0
 if operation=='set'then offset=value-base elseif operation=='add'then offset=offset+value end
 if operation then self:setStrategyMemory('dongmanbao.mark.'..key,{epoch=epoch,offset=offset})end
 return base+offset
end
local function dushe_flag(self,p,name,set)
 local epochs=known(AIWorldLifecycle.epochs(self.world,'flag'),'flag clear epochs');local epoch=known(epochs[p:objectName()],'target clear epoch')
 local key='dongmanbao.'..name..'.'..p:objectName();local old=self:getStrategyMemory(key)
 if set then self:setStrategyMemory(key,{epoch=epoch,value=true});return end
 if old and old.epoch==epoch then return old.value end
 return p:hasFlag(name)
end
local function role_write(self,skill,target,source,reset)
 if skill~='SE_Dapo' then
  ai_unsupported('dongmanbao role assignment requires scoped role-effect contract',skill)
 end
 -- Preserve the three reached source role reads and the unused rebel rewrite.
 -- The host stages one atomic effect; a source error after its early resets is
 -- outside successful-event parity and must never silently become a no-op.
 local role,value=target:getKnownRole(),1000
 if role=='rebel' then role='loyalist';value=-1000 end
 local assigned=source:getKnownRole()
 local inferred=source:getKnownRole()
 local targetName,sourceName=target:objectName(),source:objectName()
 -- The witness is the public board: a role counts only when it is the viewer's
 -- own or visible to it. The caller already checked SE_Dapo and HP 1.
 local roles={lord=true,loyalist=true,rebel=true,renegade=true}
 local function seen_role(p,name)
  if name~=self.player:objectName() and not p:isRoleVisible() then return nil end
  local r=p:getKnownRole();return roles[r] and r or nil
 end
 local witnessed=seen_role(target,targetName) and seen_role(source,sourceName)
 if not roles[witnessed] or assigned~=witnessed or inferred~=witnessed then
  ai_unsupported('Current Dying role witness unavailable','dongmanbao.SE_Dapo.role')
 end
 self:emitStrategyEffect({kind='dongmanbao_dapo_role',player=targetName,
  source_player=sourceName,role=assigned})
end
local function generateAllCardObjectNameTablePatterns(self)return known(AICardCatalog.patternNames(),'registered card pattern list')end
local function peiqi(self)
 local fn=sgs.ai_skill_invoke.peiqi;if type(fn)~='function'then ai_unsupported('effective peiqi policy missing','dongmanbao.peiqi')end
 local ok,value=pcall(fn,self,nil)
 if self.peiqiData then local d=self.peiqiData;self:setStrategyMemory('dongmanbao.peiqi',{from=d.from and d.from:objectName(),to=d.to and d.to:objectName(),cid=d.cid})end
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
	if player:hasSkill("LuaTianmo") and player:getMark("@tianmo") > 0 then return true end
	if self:hasSkills("SE_Maoqun|Tianhuo", player) then return true end
	return false
end


local function isEquip(name, player)
	for _, e in sgs.qlist(player:getEquips()) do
		if e:isKindOf(name) then
			return true
		end
	end
	return false
end


local function hasJudgePlayer(self, isFriend)
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if self:hasSkills("se_qidian|guicai|guidao", player) then
			if isFriend then
				if self:isFriend(player) then return true end
			else
				if self:isEnemy(player) then return true end
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
				if p:getHandcardNum() < num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHandcardNum() < num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 2 then 
		num = 0
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHandcardNum() > num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHandcardNum() > num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 3 then 
		num = 100
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHp() < num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHp() < num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 4 then 
		num = 0
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHp() > num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHp() > num then
					target = p
					num = p:getHp()
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
	
	if self:needKongcheng(self.player, true) and #self.friends_noself == 0 and self.player:getHandcardNum() == 0 then return false end
	return self:findPlayerToDraw(false, 2)
end

sgs.ai_playerchosen_intention["se_jinqu"] = -70



sgs.ai_need_damaged["se_jinqu"] = function(self, attacker, player)
	if not player:hasSkill("se_jinqu") then return end

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

sgs.ai_can_damagehp.se_jinqu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
end

sgs.ai_skill_invoke["shengyou"] = function(self, data)
	
	return true
end



sgs.ai_skill_invoke["se_jinghua"] = true

sgs.ai_skill_playerchosen["se_jinghua"] = function(self, targets)
	local targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")

	local friends = {}
	local player_list = AIList.new({})
	for _, player in ipairs(targets) do
		if self:isFriend(player) and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
			and not (player:hasSkill("kongcheng") and player:isKongcheng()) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return nil end

	self:sortInPlace(friends, hp)

	local max_x = 5 - self.player:getHandcardNum()

	for _, friend in ipairs(friends) do
		if friend:isWounded() and self:isWeak(friend) and friend:getHp() < self:getBestHp(friend) then
			return friend
		end
	end


	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	self:sortInPlace(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil

	
end



sgs.ai_skill_choice["se_jinghua"] = function(self, choices, data)
	local source = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if table.contains(items, "se_jinghua_recover") and self:isWeak(source) and source:isWounded() and source:getHp() < self:getBestHp(source) then
			return
			"se_jinghua_recover"
		end
		if table.contains(items, "se_jinghua_getcard") and source:getJudgingArea():length() > 0 then
			return
			"se_jinghua_getcard"
		end
		return "se_jinghua_drawcard"
	end
	return "se_jinghua_drawcard"
end

sgs.ai_playerchosen_intention.se_jinghua = -40

sgs.ai_skill_cardask["@se_jinghua"] = function(self,data)
	local target = data:toPlayer()
	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	local targets = AIList.new({})
	targets:append(target)
	local h,friend = self:getCardNeedPlayer(cards, false, targets)
	if h and friend then
		return "$"..h:getKnownEffectiveId()
	end
	if self:isFriend(target) then
		return "$"..cards[1]:getEffectiveId()
	end
	return "."
end


sgs.ai_skill_invoke["se_jiushu"] = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	local lord = self.room:getLord()
	if lord and self:isWeak(lord) and viewer_role(self,self.player) == "loyalist" then
		if lord:objectName() == source:objectName() then
			return true
		else
			return false
		end
	end
	if self:isWeak(self.player) and source:objectName() ~= self.player:objectName() then
		return false
	end
	for _, player in ipairs(self.friends) do
		if player:isAlive() and source and source:objectName() == player:objectName() then
			return true
		end
	end
	if source:objectName() == self.player:objectName() then
		return true
	end
	return false
end





sgs.ai_skill_invoke.Huansha = function(self, data)
	local damage = data:toDamage()
	local source = damage.to
	for _, player in ipairs(self.friends) do
		if player:isAlive() and source:objectName() == player:objectName() then
			return true
		end
	end
	if source:objectName() == self.player:objectName() then
		return true
	end
	return false
end

ai_audited_aliases.register{id="ai_cardneed.Huansha",registry="ai_cardneed",path={"Huansha"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
sgs.ai_ajustdamage_to.Huansha = function(self, from, to, card, nature)
	if nature ~= "N" and ((from and from:isKongcheng()) or not from)
	then
		return -99
	end
end

sgs.ai_event_callback[sgs.Dying or "Dying"].SE_Dapo = function(self, player, data)
	local target = data:toDying().who
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if sb:hasSkill("SE_Dapo") and sb:getHp() == 1 and target then
			role_write(self,"SE_Dapo",target,sb,true)
			self:updatePlayers()
		end
	end
end


local se_paoji_skill = {}
se_paoji_skill.name = "se_paoji"
table.insert(package_skills, se_paoji_skill)
se_paoji_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#se_paojicard") then return end
	if #self.enemies < 1 then return end
	if self.player:getMark("@se_ying") < 1 then return end
	if not hasJudgePlayer(self, true) then
		if self.player:getHp() > 2 and self.player:getMark("@se_ying") < 4 then return end
		if self.player:getHp() > 1 and self.player:getMark("@se_ying") < 3 then return end
	end
	self:updatePlayers()
	self:sortInPlace(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) then
				return parse(self,request,"#se_paojicard:.:")
			end
		end
	end
	return
end

sgs.ai_skill_use_func["#se_paojicard"] = function(card,use,self,request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) then
				use.card=final_parse(self,request,"#se_paojicard:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end




sgs.ai_skill_choice["se_paoji"] = function(self, choices, data)
	local choice_table = choices:split("+")
	local target = data:toPlayer()
	local count = self.player:getMark("@se_ying")
	local x = math.ceil(2 / target:getHp() + 1)
	if hasJudgePlayer(self, true) or self:cantDamageMore(self.player, target) then return "paoji_1" end
	
	
	if count > x then return "paoji_" .. x end
	if count < x then return "paoji_" .. count end
	return choice_table[1]
end



sgs.ai_use_value["se_paojicard"]      = 8
sgs.ai_use_priority["se_paojicard"]   = 2
sgs.ai_card_intention["se_paojicard"] = 100

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|se_paoji"

sgs.ai_getBestHp_skill.Dianci = function(owner)
	if owner:getMark("@ying") >= 1 then
		return owner:getMaxHp() - 1
	end
end



local se_cairen_skill = {}
se_cairen_skill.name = "se_cairen"
table.insert(package_skills, se_cairen_skill)
se_cairen_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if source:getPile("moli"):length() <= 3 then return end
	return parse(self,request,"#se_cairencard:.:")
end

sgs.ai_skill_use_func["#se_cairencard"] = function(card,use,self,request)
	local useable_cards = {}
	if self.player:getPile("moli"):length() > 3 then
		for _, id in sgs.qlist(self.player:getPile("moli")) do
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
	self:sortInPlace(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not self:hasZhaxiangEffect(p) and p:hasSkills(sgs.need_maxhp_skill) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not self:hasZhaxiangEffect(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["Beizeng"] = 50

sgs.ai_cardneed.Xuwu = function(to, card, self)
	return card:getTypeId() == sgs.Card_TypeTrick
end

sgs.ai_card_priority.Xuwu = function(self, card, v)
	if self.useValue
		and card:isKindOf("TrickCard")
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
	if self:needBear() then return end
	local source = self.player
	if source:getPile("moli"):length() < 3 then return end
	
	if not self.player:hasFlag("se_zhijiancard_used") and not self.player:isKongcheng() then
		return parse(self,request,
			"#se_zhijiancard:.:")
	end
end

sgs.ai_skill_use_func["#se_zhijiancard"] = function(card,use,self,request)
	self:sortInPlace(self.enemies, "handcard")
	local cards = AIList.new({})
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	if not max_card then return end
	local max_point = max_card:getNumber()
	local useable_cards = {}
	if self.player:getPile("moli"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("moli")) do
			table.insert(useable_cards, disclosed(self,id))
		end
	end
	local card_str = string.format("#se_zhijiancard:%s:", useable_cards[1]:getEffectiveId())
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
				or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				local acard = parse(self,request,card_str)
				use.card = acard
				self:remember("zhijian_card", max_card)
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if self.player:getHandcardNum() >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local enemy_min_card = self:getMinCard(enemy)
				local cardsq = self.player:getHandcards()
				cardsq = AIList.new(cardsq)
				self:sortByUseValueInPlace(cardsq, true)

				local min_card = self:getMinCard()
				local enemy_min_card = self:getMinCard(enemy)
				if enemy_min_card and min_card:getNumber() < enemy_min_card:getNumber() then
					local acard = parse(self,request,card_str)
					use.card = acard
					self:remember("zhijian_card", max_card)
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and not self:doDisCard(enemy, "h") and self.player:canPindian(enemy) then
				local acard = parse(self,request,card_str)
				use.card = acard
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")



	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self.player:canPindian(zhugeliang)
		and zhugeliang:objectName() ~= self.player:objectName() and self:getEnemyNumBySeat(self.player, zhugeliang) >= 1 then
		if isCard("Jink", cards[1], self.player) and self:getCardsNum("Jink") == 1 then return end
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then use.to:append(zhugeliang) end
		return
	end

	if self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:doDisCard(enemy, "h", true) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local acard = parse(self,request,card_str)
				use.card = acard
				self:remember("zhijian_card", max_card)
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.se_zhijiancard(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = AIList.new(self.player:getHandcards())
		self:sortByKeepValueInPlace(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.se_zhijian",registry="ai_cardneed",path={"se_zhijian"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
local se_hengsao_skill = {}
se_hengsao_skill.name = "se_hengsao"
table.insert(package_skills, se_hengsao_skill)
se_hengsao_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if #self.enemies < 2 then return end
	if source:getHp() <= 2 then return end
	if self:isWeak(source) then return end
	if source:getHp() <= 3 and #self.enemies < 3 then return end
	return parse(self,request,"#se_hengsaocard:.:")
end

sgs.ai_skill_use_func["#se_hengsaocard"] = function(card,use,self,request)
	local targets = AIList.new({})
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy and targets:length() < 3 and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) then
			targets:append(enemy)
		end
	end
	if targets:length() >= 2 then
		use.card=final_parse(self,request,"#se_hengsaocard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["se_hengsaocard"]    = 4.2
sgs.ai_card_intention["se_hengsaocard"]  = 108

function sgs.ai_cardneed.Zhena(to, card, self)
	return (card:isKindOf("Weapon") and not self.player:getWeapon()) or card:isKindOf("fire_attack") or
		card:isKindOf("fire_slash") or card:isKindOf("iron_chain")
end


sgs.ai_skill_invoke.Zhena       = function(self, data)
	local damage = data:toDamage()
	local source = damage.to
	if self:isEnemy(source) and (source:getHp() - damage.damage > 1 or self.player:getHp() <= 1)
		and self:damageIsEffective(source, sgs.DamageStruct_Fire) then
		return not self:cantDamageMore(self.player, source) and
			((self:isWeak(self.player) or self.player:getHp() == 1) or
				(self.player:getHp() <= source:getHp() and self:getCardsNum("Peach") > 0) or source:isLord())
	end
	return false
end

sgs.ai_used_revises.Zhena       = function(self, use)
	if use.card:isKindOf("Slash")
		and not self.player:getWeapon()
		and not use.isDummy
	then
		for _, to in sgs.list(use.to) do
			if self:isEnemy(to)
				and getCardsNum("Jink", to, self.player) < 1
			then
				local use_card
				for _, card in sgs.qlist(self.player:getHandcards()) do
					if card:isKindOf("Weapon") then
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
	return (card:isKindOf("Weapon") and not self.player:getWeapon()) or card:isKindOf("fire_attack") or
		card:isKindOf("fire_slash") or card:isKindOf("iron_chain")
end


sgs.ai_chaofeng.Shana = 4
sgs.ai_chaofeng.Shana2 = 4
sgs.ai_chaofeng.Shana3 = 4




local se_shixian_skill = {}
se_shixian_skill.name = "se_shixian"
table.insert(package_skills, se_shixian_skill)
se_shixian_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if source:getMark("@time") == 0 then return end
	if source:getMark("@Benhuihe") > 0 then return end
	if source:getMark("@timepoint") > 0 then return end
	if source:getHandcardNum() < 4 then return end
	if source:getHp() == 1 and source:getHandcardNum() < 7 then return end
	if source:getHp() == 2 and source:getHandcardNum() < 6 then return end
	if source:getHp() == 3 and source:getHandcardNum() < 5 then return end
	return parse(self,request,"#se_shixiancard:.:")
end

sgs.ai_skill_use_func["#se_shixiancard"] = function(card,use,self,request)
	local cards = AIList.new(self.player:getHandcards())
	local needed = {}
	for _, acard in ipairs(cards) do
		table.insert(needed, acard:getKnownEffectiveId())
	end
	if self.player:getHp() >= 3 then
		if self.player:getArmor() then
			table.insert(needed, self.player:getArmor():getEffectiveId())
		end
		if self.player:getDefensiveHorse() then
			table.insert(needed, self.player:getDefensiveHorse():getEffectiveId())
		end
	else
		if self.player:getWeapon() then
			table.insert(needed, self.player:getWeapon():getEffectiveId())
		end
		if self.player:getOffensiveHorse() then
			table.insert(needed, self.player:getOffensiveHorse():getEffectiveId())
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
	if source:getMark("@time") == 0 then return end
	if source:getMark("@timepoint") == 0 then return end
	if source:getMark("Benhuihe") > 0 then return end
	if source:getHp() > 2 then return end
	local cards = AIList.new(self.player:getHandcards())
	local help_card_num = 0
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Peach") or acard:isKindOf("Jink") or acard:isKindOf("Analeptic") then
			help_card_num = help_card_num + 1
		end
	end
	if source:getHp() == 2 and (help_card_num > 0 and source:getHandcardNum() <= 3) then return end
	return parse(self,request,"#se_tiaoyuecard:.:")
end

sgs.ai_skill_use_func["#se_tiaoyuecard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#se_tiaoyuecard:.:")
	return
end



sgs.ai_use_priority["se_tiaoyuecard"] = 3.6




local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = disclosed(self,judge:getKnownEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then
					card = equip
					break
				elseif equip:isKindOf("Weapon") then
					card = equip
					break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sortInPlace(self.friends, "defense")
				else
					self:sortInPlace(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = disclosed(self,judge:getKnownEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card == nil or target == nil then
			if not who:hasEquip() or self:hasSkills(sgs.lose_equip_skill, who) then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(disclosed(self,card_id)) then card = disclosed(self,card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sortInPlace(self.friends, "defense")
				else
					self:sortInPlace(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu", friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
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
			if target:objectName()==(peiqi_data(self).from):objectName()
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen.Zhudao_to = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==(peiqi_data(self).to):objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.Zhudao = function(self,who,flags,method)
	for i,c in sgs.list(who:getCards(flags))do
		i = c:getKnownEffectiveId()
		if i==peiqi_data(self).cid
		then return i end
	end
end
sgs.ai_skill_playerchosen.Sixu_from = function(self,players)
    if peiqi(self)
	then
		for _,target in sgs.list(players)do
			if target:objectName()==(peiqi_data(self).from):objectName()
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen.Sixu_to = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==(peiqi_data(self).to):objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.Sixu = function(self,who,flags,method)
	for i,c in sgs.list(who:getCards(flags))do
		i = c:getKnownEffectiveId()
		if i==peiqi_data(self).cid
		then return i end
	end
end

sgs.Zhudao_keep_value = sgs.xiaoji_keep_value




function sgs.ai_cardneed.se_erdao(to, card, self)
	return card:isKindOf("Weapon")
end

local se_erdao_skill = {}
se_erdao_skill.name = "se_erdao"
table.insert(package_skills, se_erdao_skill)
se_erdao_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or self.player:isKongcheng() then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if player:getHp() >= 2 and self:slashIsEffective(self:cloneEvaluationCard("slash"), player) and self:slashIsEffective(self:cloneEvaluationCard("thunder_slash"), player) and self:slashIsEffective(self:cloneEvaluationCard("fire_slash"), player) then
			too_weak = false
		end
	end
	if too_weak then return end
	local source = self.player
	local OK_num = 0
	if source:getWeapon() then
		OK_num = OK_num + 1
	end
	local cards = AIList.new(self.player:getHandcards())
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Weapon") then
			OK_num = OK_num + 1
		end
	end
	if OK_num > 1 then
		return parse(self,request,"#se_erdaocard:.:")
	end
end

sgs.ai_skill_use_func["#se_erdaocard"] = function(card,use,self,request)
	local target
	local slash = self:cloneEvaluationCard("slash")
	
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:isEnemy(enemy) and not self:slashProhibit(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self:slashIsEffective(slash, enemy) then
			
			target = enemy
		end
	end
	if target then
		local needed = {}
		if self.player:getWeapon() then
			table.insert(needed, self.player:getWeapon():getEffectiveId())
		end
		local cards = AIList.new(self.player:getHandcards())
		for _, acard in ipairs(cards) do
			if acard:isKindOf("Weapon") then
				table.insert(needed, acard:getKnownEffectiveId())
				if #needed > 1 then
					break
				end
			end
		end
		use.card=final_parse(self,request,"#se_erdaocard:" .. table.concat(needed, "+") .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_erdaocard"]       = 8
sgs.ai_use_priority["se_erdaocard"]    = 8
sgs.ai_card_intention.se_erdaocard     = 108



sgs.ai_skill_invoke.se_erdao = function(self, data)
	local use = data:toCardUse()
	if use.card:isDamageCard() or use.card:isKindOf("SingleTargetTrick") then
		for _,to in sgs.list(use.to)do
			if self:isFriend(to)
			then return false end
		end
		return true
	end
	local dummy_use = self:aiUseCard(use.card, dummy())
	if dummy_use.card then
        if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				for _,to in sgs.list(use.to)do
					if p:objectName() == to:objectName() then
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
	if self.player:getMark("@Yuzora") == 0 then return end
	local total_damage = 0
	for _, friend in ipairs(self.friends) do
		if friend then
			total_damage = total_damage + friend:getLostHp()
		end
	end
	if #self.friends == 1 and total_damage < 2 then return end
	if #self.friends == 2 and total_damage < 2 and self.player:getHp() > 1 then return end
	if #self.friends > 2 and total_damage < 3 and self.player:getHp() > 1 then return end
	return parse(self,request,"#se_yekongcard:.:")
end

sgs.ai_skill_use_func["#se_yekongcard"]   = function(card,use,self,request)
	if self:getCardsNum("duel") > 0 or self:getCardsNum("dismantlement") > 0 or self:getCardsNum("snatch") > 0 or self:getCardsNum("ex_nihilo") > 0 then
		use.card = card
	end
	if self.player:getHp() == 1 then
		use.card = card
	end
	local help = 0
	for _, friend in ipairs(self.friends) do
		if friend:hasSkill("SE_Shanguang") or friend:hasSkill("se_jianwu") or friend:hasSkill("Huajian") then
			help = help + 1
		end
		if friend:getHp() <= 2 then
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
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return true
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
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
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end


	return target 
end

sgs.ai_playerchosen_intention.se_yekongRe = function(self, from, to)
	if to:isWounded() then
		self:updateIntention(from, to, -50)
	end
end

sgs.ai_skill_invoke.Yuzora_Shanguang      = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isFriend(damage.from) and damage.from:hasSkill("SE_Shanguang") then
		return true
	end
	return false
end

sgs.ai_skill_invoke.Yuzora_se_jianwu      = function(self, data)
	local source = data:toPlayer()
	if source and self:isFriend(source) and source:hasSkill("se_jianwu") then
		return true
	end
	return false
end





sgs.ai_skill_invoke.SE_Dixian = function(self, data)
	local damage = data:toDamage()
	if self:canDamage(damage.from, damage.to) then
		if self:isFriend(damage.from) then
			return self:dontHurt(damage.from, damage.to)
		end
		return true
	end
	return not self:isFriend(damage.from)
end


function sgs.ai_slash_prohibit.SE_Dixian(self, from, to)
	if self:isFriend(from, to) then return false end
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if from:getHandcardNum() < to:getLostHp() + 1 and from:getEquips():length() == 0 and from:getHandcards():at(0):isKindOf("Slash") and from:getHp() >= 2 then return false end
	return from:getHp() + from:getEquips():length() < 4 or from:getHp() < 2
end

sgs.ai_can_damagehp.SE_Dixian = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0 and
		self:canLoseHp(from, card, to) then
		return self:isEnemy(from) and from:getHandcardNum() > 0 and self:canAttack(from, to)
	end
end

sgs.ai_choicemade_filter.skillInvoke.SE_Dixian = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not self:canAttack(damage.from, player) and not self:needToLoseHp(damage.from, player) then
				self:updateIntention(damage.to, damage.from, 40)
			end
		elseif self:canAttack(damage.from) then
			self:updateIntention(damage.to, damage.from, -40)
		end
	end
end

function SmartAIView:findSE_DixianTarget(player, SE_Dixian_value)
	local getCmpValue = function(enemy)
		local value = 0
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Fire, player) then return 100 end
		if self:cantbeHurt(enemy, player, 1) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget(enemy, sgs.DamageStruct_Fire, player, 1)) then
			return 100
		end
		if not self:isGoodTarget(enemy, self.enemies, nil) then value = value + 50 end
		if enemy:hasSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget(enemy, sgs.DamageStruct_Fire, player, 1) and #(self:getChainedEnemies(player)) > 1 then
			value =
				value - 25
		end
		if enemy:isLord() then value = value - 5 end
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < SE_Dixian_value then return enemy end
	end
	return nil
end

sgs.ai_skill_playerchosen.SE_Dixian = function(self, targets)
	local target
	self:sortInPlace(self.enemies, "defense")
	return self:findSE_DixianTarget(self.player, 100)
end


ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SE_Shanguang",registry="ai_choicemade_filter",path={"cardChosen","SE_Shanguang"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
sgs.ai_skill_playerchosen.SE_Shanguang = function(self, targets)
	local targets = AIList.new(targets)
	local target
	self:sortInPlace(targets, "hp")
	for _, enemy in ipairs(targets) do
		if self:isEnemy(enemy) then
			target = enemy
		end
	end
	if target then return target end
	return nil
end


sgs.ai_skill_cardchosen.SE_Shanguang = function(self, who, flags)
	if who:getArmor() then return who:getArmor() end
	if who:getHandcardNum() == 1 and not self:needKongcheng(who) then
		local cards = who:getHandcards()
		return cards[1]
	end
	if who:getWeapon() then return who:getWeapon() end
	if who:getOffensiveHorse() then return who:getOffensiveHorse() end
	if who:getDefensiveHorse() then return who:getDefensiveHorse() end
	if who:getHandcardNum() > 1 then
		local cards = who:getHandcards()
		return cards[1]
	end
	return
end



local SE_Erdao_old_skill = {}
SE_Erdao_old_skill.name = "se_erdao_old"
table.insert(package_skills, SE_Erdao_old_skill)
SE_Erdao_old_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or self.player:isKongcheng() then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if player:getHp() >= 2 and self:damageIsEffective(player, nil, self.player) and self:isGoodTarget(player, self.enemies, nil) then
			too_weak = false
		end
	end
	if too_weak then return end
	local source = self.player
	local OK_num = 0
	if source:getWeapon() then
		OK_num = OK_num + 1
	end
	local cards = AIList.new(self.player:getHandcards())
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Weapon") then
			OK_num = OK_num + 1
		end
	end
	if OK_num > 1 then
		return parse(self,request,"#se_erdao_oldCard:.:")
	end
end

sgs.ai_skill_use_func["#se_erdao_oldCard"] = function(card,use,self,request)
	local target
	local slash = self:cloneEvaluationCard("slash")
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:isEnemy(enemy) and self:damageIsEffective(enemy, nil, self.player) and self:isGoodTarget(enemy, self.enemies, nil) then
			target = enemy
		end
	end
	if target then
		local needed = {}
		if self.player:getWeapon() then
			table.insert(needed, self.player:getWeapon():getEffectiveId())
		end
		local cards = AIList.new(self.player:getHandcards())
		for _, acard in ipairs(cards) do
			if acard:isKindOf("Weapon") then
				table.insert(needed, acard:getKnownEffectiveId())
				if #needed > 1 then
					break
				end
			end
		end
		use.card=final_parse(self,request,"#se_erdao_oldCard:" .. table.concat(needed, "+") .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_erdao_oldCard"]       = 8
sgs.ai_use_priority["se_erdao_oldCard"]    = 8
sgs.ai_card_intention.se_erdao_oldCard     = 108

ai_audited_aliases.register{id="ai_skill_invoke.se_erdao_old",registry="ai_skill_invoke",path={"se_erdao_old"},canonical_registry="ai_skill_invoke",canonical_path={"se_erdao"},self_index=1,defer_canonical=true}
sgs.ai_skill_invoke.SE_Qiehuan_K = function(self, data)
	if (self:isWeak(self.player)) or (self.player:getHp() < self:getBestHp(self.player)) then return true end
	return false
end
sgs.ai_skill_invoke.SE_Qiehuan_A = function(self, data)
	if (self:isWeak(self.player)) or (self.player:getHp() < self:getBestHp(self.player)) then return true end
	return false
end



local se_chouyuan_skill = {}
se_chouyuan_skill.name = "se_chouyuan"
table.insert(package_skills, se_chouyuan_skill)
se_chouyuan_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or self.player:getMark("@hates") < 1 then return end
	local too_weak = true
	for _, player in ipairs(self.enemies) do
		if player:getHp() >= 2 then
			too_weak = false
		end
	end
	if too_weak then return end
	local lord = self.room:getLord()
	if viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" or viewer_role(self,self.player) == "rebel" then
		return parse(self,request,"#se_chouyuancard:.:")
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends + 1 >= #self.enemies and (self.player:getHp() >= 3 or lord:getHp() >= 3) then return end
		if #self.friends >= #self.enemies and (self.player:getHp() >= 2 or lord:getHp() >= 2) then return end
		return parse(self,request,"#se_chouyuancard:.:")
	end
end


sgs.ai_skill_use_func["#se_chouyuancard"] = function(card,use,self,request)
	local target
	self:sortInPlace(self.enemies, "defense")
	local lord = self.room:getLord()
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
		if lord:getHp() <= 2 then
			for _, enemy in ipairs(self.enemies) do
				if viewer_role(self,enemy) == "rebel" and enemy then
					target = enemy
				end
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_chouyuancard:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_cardneed.SE_Qixin                  = function(to, card, self)
	return card:isKindOf("Slash")
end

sgs.ai_use_value["se_chouyuancard"]       = 8
sgs.ai_use_priority["se_chouyuancard"]    = 8
sgs.ai_card_intention["se_chouyuancard"]  = 108

sgs.ai_skill_invoke.SE_Qixin              = function(self, data)
	return true
end



sgs.ai_skill_choice.SE_Qixin              = function(self, choices, data)
	local target = self.player:getRoom():getCurrent()
	if self:isFriend(target) then
		local slashs = self:getCards("Slash")
		if #slashs == 0 then
			return "Qixin_setcard"
		end
		return "Qixin_slashto"
	end
	return "Qixin_setcard"
end

sgs.ai_skill_playerchosen.SE_Qixin        = function(self, targets)
	return self:findPlayerToDraw(true, 1)
end

















local se_shunshan_skill = {}
se_shunshan_skill.name = "se_shunshan"
table.insert(package_skills, se_shunshan_skill)
se_shunshan_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or self.player:hasFlag("se_shunshan_used") then return end
	return parse(self,request,"#se_shunshancard:.:")
end


sgs.ai_skill_use_func["#se_shunshancard"] = function(card,use,self,request)
	local target
	if #self.enemies < 1 then return end
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and enemy:getDefensiveHorse() and self.player:getOffensiveHorse() and enemy:getMark("@Stop") > 0 then
			target = enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and enemy:getDefensiveHorse() and self.player:getOffensiveHorse() and enemy:getMark("@Stop") == 0 then
			target = enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and not enemy:getDefensiveHorse() and enemy:getMark("@Stop") > 0 then
			target = enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and not enemy:getDefensiveHorse() and enemy:getMark("@Stop") == 0 then
			target = enemy
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_shunshancard:.:")
		local next_people = target:getNextAlive()
		if use.to then use.to:append(next_people) end
		return
	end
end

sgs.ai_use_value["se_shunshancard"]       = 8
sgs.ai_use_priority["se_shunshancard"]    = 7

sgs.ai_skill_playerchosen.se_shunshan     = function(self, targets)
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) and p:getMaxCards() > 0 then return p end
	end
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets:first()
end

sgs.ai_playerchosen_intention.se_shunshan = 100




local se_chongjing_skill = {}
se_chongjing_skill.name = "se_chongjing"
table.insert(package_skills, se_chongjing_skill)
se_chongjing_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends < 1 or self.player:getMark("@longing") < 1 then return end
	local no_sister = true
	for _, player in ipairs(self.friends) do
		if not player:isMale() and player:objectName() ~= self.player:objectName() then
			no_sister = false
		end
	end
	local mikoto_unknown = false
	local list = self.room:getAlivePlayers()
	for _, player in sgs.qlist(list) do
		if player:getKnownGeneralName() == "Mikoto" then
			if not self:isFriend(player) and not self:isEnemy(player) then
				mikoto_unknown = true
			end
		end
	end
	if no_sister or mikoto_unknown then return end
	local lord = self.room:getLord()
	if viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" or viewer_role(self,self.player) == "rebel" then
		return parse(self,request,"#se_chongjingcard:.:")
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends + 1 >= #self.enemies and (self.player:getHp() >= 3 or lord:getHp() >= 3) then return end
		if #self.friends >= #self.enemies and (self.player:getHp() >= 2 or lord:getHp() >= 2) then return end
		return parse(self,request,"#se_chongjingcard:.:")
	end
end


sgs.ai_skill_use_func["#se_chongjingcard"] = function(card,use,self,request)
	local target = nil
	self:sortInPlace(self.friends, "defense")
	local lord = self.room:getLord()
	if viewer_role(self,self.player) == "rebel" or viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" then
		for _, friend in ipairs(self.friends) do
			if not friend:isMale() and friend:objectName() ~= self.player:objectName() then
				target = friend
			end
		end
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.friends == #self.enemies then
			for _, friend in ipairs(self.friends) do
				if viewer_role(self,friend) == "lord" and not friend:isMale() and friend:objectName() ~= self.player:objectName() then
					target = friend
				end
			end
		end
		if #self.friends + 1 <= #self.enemies then
			for _, friend in ipairs(self.friends) do
				if (viewer_role(self,friend) == "lord" or viewer_role(self,friend) == "rebel") and not friend:isMale() and friend:objectName() ~= self.player:objectName() then
					target = friend
				end
			end
		end
		if lord:getHp() <= 2 then
			for _, friend in ipairs(self.friends) do
				if viewer_role(self,friend) == "lord" and not friend:isMale() and friend:objectName() ~= self.player:objectName() then
					target = friend
				end
			end
		end
	end
	if viewer_role(self,self.player) == "loyalist" then
		if not lord:isMale() then
			target = lord
		end
	end
	if viewer_role(self,self.player) == "rebel" or viewer_role(self,self.player) == "lord" or viewer_role(self,self.player) == "loyalist" then
		for _, friend in ipairs(self.friends) do
			if friend:getKnownGeneralName() == "Mikoto" then
				target = friend
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_chongjingcard:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_chongjingcard"]       = 8
sgs.ai_use_priority["se_chongjingcard"]    = 8
sgs.ai_card_intention["se_chongjingcard"]  = -100

sgs.ai_skill_invoke.se_chongjing_Attack    = function(self, data)
	local damage = data:toDamage()
	local victim = damage.to
	local source = damage.from
	if self:isEnemy(victim) or self:isEnemy(source) then
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
		if friend:getMark("@Stop") > 0 then
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
		if friend:getMark("@Stop") > 0 then
			target = friend
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_jieshucard:.:")
		if use.to then use.to:append(target) end
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
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end


	return target 
end



sgs.ai_playerchosen_intention.dai = function(from, to)
	local intention = -60
	self:updateIntention(from, to, intention)
end

sgs.ai_skill_invoke.daiVS = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	if self.player:getMark("@daiwei") < 2 then return false end
	if self:isFriend(source) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.daiVS = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getCurrentDyingPlayer()
		if target then self:updateIntention(player, target, -50) end
	end
end


sgs.save_skill = sgs.save_skill .. "|dai"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|dai"
sgs.priority_skill = sgs.priority_skill .. "|dai"

sgs.ai_skill_invoke.zhuchang = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.zhuchang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, -50) end
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|zhuchang"
sgs.priority_skill = sgs.priority_skill .. "|zhuchang"






local se_tianming_skill = {}
se_tianming_skill.name = "se_tianming"
table.insert(package_skills, se_tianming_skill)
se_tianming_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			return
		end
	end
	if self:slashIsAvailable() and self.player:getMark("@Tianming") >= 12 then
		local card_str = string.format("slash:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		return parse(self,request,card_str)
	end
end

function sgs.ai_cardsview_valuable.se_tianming(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive or self.player:getMark("@Tianming") < 12 then return end
	if class_name == "Slash"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and self.player:getMark("@Tianming") >= 12
	then
		local slashs = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			return string.format("slash:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		end
	elseif class_name == "Jink"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and self.player:getMark("@Tianming") >= 17
	then
		local jinks = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Jink") then
				table.insert(jinks, c)
			end
		end
		if #jinks == 0 then
			return string.format("jink:se_tianming[%s:%s]=.", sgs.Card_NoSuit, 0)
		end
	elseif class_name == "Nullification"
		and self.player:getMark("@Tianming") >= 23
	then
		local Nullifications = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Nullification") then
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
	if source:getMark("@Tianming") < 130 then return end
	if #self.enemies < 2 then return end
	return parse(self,request,"#se_jianwucard:.:")
end

sgs.ai_skill_use_func["#se_jianwucard"] = function(card,use,self,request)
	local targets = AIList.new({})
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy and targets:length() < 3 and enemy:faceUp() then
			targets:append(enemy)
		end
	end
	if targets:length() >= 1 then
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
	if source:getStrategyHasUsed("#se_kanhucard") then return end
	if source:getMark("@Tianming") < 20 then return end
	local target = 0
	local arr1, arr2 = self:getWoundedFriend(false, true)
	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then target = 1 end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
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

	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card=final_parse(self,request,"#se_kanhucard:.:")
		if use.to then use.to:append(target) end
		return
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				target = friend
				break
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_kanhucard:.:")
		if use.to then use.to:append(target) end
		return
	end
	
end

sgs.ai_use_value["#se_kanhucard"]       = 6
sgs.ai_use_priority["#se_kanhucard"]    = 9
sgs.ai_card_intention["#se_kanhucard"]  = -100



sgs.ai_skill_invoke.SE_Xianjing  = function(self, data)
	local damage = data:toDamage()
	local source = damage.from
	if not self:isFriend(source) then
		return true
	end
	return false
end

sgs.ai_can_damagehp.SE_Xianjing  = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from)
	end
end



sgs.ai_skill_invoke["SE_Boming"] = function(self, data)
	if self.player:getMark("@HIMIKO") == 0 then return false end
	local dying_data = data:toDying()
	local source = dying_data.who
	if self:isFriend(source) then
		local skill_list = self.player:getVisibleSkillList()
		local i = 0
		local boming_skill_list = { "yingzi", "shensu", "fankui", "longdan", "paoxiao", "guicao" }
		for _, skill in sgs.qlist(skill_list) do
			if skill:objectName() ~= "SE_Boming" and skill:objectName() ~= "SE_Xianjing" and skill:objectName() ~= "SE_BomingGet"
				and table.contains(boming_skill_list, skill:objectName()) then
				i = i + 1
			end
		end
		if i == 0 then return false end
		if source:objectName() == self.player:objectName() then return true end
		if viewer_role(self,self.player) == "renegade" then
			if source:objectName() ~= self.player:objectName() and viewer_role(self,source) ~= "lord" then return false end
		end
		if i == 1 and #self.friends > 2 then return false end
		if i >= 2 then return true end
		return false
	end
end

sgs.ai_canNiepan_skill.SE_Boming = function(player)
	if player:getMark("@HIMIKO") > 0
		and (player:hasSkill("yingzi") or
			player:hasSkill("shensu") or
			player:hasSkill("fankui") or
			player:hasSkill("longdan") or
			player:hasSkill("paoxiao") or
			player:hasSkill("guicao"))
	then return true end
end



local se_qiyuan_skill = {}
se_qiyuan_skill.name             = "se_qiyuan"
table.insert(package_skills, se_qiyuan_skill)
se_qiyuan_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if source:getMark("@se_qiyuan") == 0 then return end
	local room = source:getRoom()
	local deathplayer = {}
	for _, p in sgs.qlist(room:getPlayers()) do
		if p:isDead() and p:getMaxHp() >= 2 then
			table.insert(deathplayer, p:getKnownGeneralName())
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
	local room = source:getRoom()
	local maxHpMax = 2
	local theP
	for _, p in sgs.qlist(room:getPlayers()) do
		if p:isDead() and p:getMaxHp() >= 2 then
			if p:getMaxHp() > maxHpMax then
				maxHpMax = p:getMaxHp()
				theP = p
			end
		end
	end
	if theP then return theP end
	local choice_table = choices:split("+")
	return choice_table[1]
end

sgs.ai_event_callback[sgs.CardFinished or "CardFinished"].se_qiyuancard = function(self, player, data)
	local use = data:toCardUse()
	if use.card and use.card:objectName() == "se_qiyuancard" then
		local room = player:getRoom()
		for _, sb in sgs.qlist(room:getOtherPlayers(player)) do
			if sb:hasFlag("se_qiyuan_ed") then
				
				role_write(self,"se_qiyuancard",sb,sb,true)
			end
		end
	end
end


sgs.ai_skill_invoke.Lichang = function(self, data)
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then
			use = tag(self,"UseHistory"..data:toStringList()[4]):toCardUse()
		end
	end
	if self.player:hasFlag("dahe") then return false  end
	if isUse then
		if use.card and use.card:hasFlag("NosJiefanUsed") then return false  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or use.card:isKindOf("NatureSlash") and  self.player:isChained() and self:isGoodChainTarget(self.player, use.card, use.from)
		or self:needToLoseHp(self.player, use.from, use.card) and self:ajustDamage(use.from, self.player, 1, use.card)==1 then return false end
	end
	
	if self:getCardsNum("Jink") == 0 then return true end
	if self:needToLoseHp(self.player, use.from, use.card, true) then return false  end
	if self:ajustDamage(use.from, self.player, 1, use.card)>1 then return true end
	
	return true
end




local se_shouren_skill = {}
se_shouren_skill.name = "se_shouren"
table.insert(package_skills, se_shouren_skill)
se_shouren_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if source:getStrategyHasUsed("#se_shourencard") then return end
	if #self.enemies == 0 then return end
	return parse(self,request,"#se_shourencard:.:")
end

sgs.ai_skill_use_func["#se_shourencard"] = function(card,use,self,request)
	local target
	local minHp = 100
	for _, enemy in ipairs(self.enemies) do
		local hp = enemy:getHp()
		if self:hasSkills(sgs.masochism_skill, enemy) then hp = hp - 1 end
		if hp < minHp and not self:hasZhaxiangEffect(enemy) then
			minHp = hp
			target = enemy
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_shourencard:.:")
		if use.to then use.to:append(target) end
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
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.Chaidao = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end
sgs.ai_skill_invoke.Keai = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.Keai = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end
sgs.ai_can_damagehp.Zizhu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to) and self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true)>self.room:getAlivePlayers():length()/2
end



local se_shengjian_skill = {}
se_shengjian_skill.name = "se_shengjian"
table.insert(package_skills, se_shengjian_skill)
se_shengjian_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:getStrategyHasUsed("#se_shengjiancard") then return end
	local power = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		local force = math.abs(source:getEquips():length() - enemy:getEquips():length()) + (enemy:getEquips():length()) /
			2
		if force > power then
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and not self:cantDamageMore(self.player, enemy) and self:canDamage(enemy, self.player, nil) then
				if not enemy:hasSkills(sgs.lose_equip_skill) and self:damageIsEffective(enemy, nil, self.player) then
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
		local force = math.abs(source:getEquips():length() - enemy:getEquips():length()) + (enemy:getEquips():length()) /
			3
		if force > power then
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and not enemy:hasArmorEffect("silver_lion")  and self:canDamage(enemy, self.player, nil) then
				if not enemy:hasSkills(sgs.lose_equip_skill) and self:damageIsEffective(enemy, nil, self.player) then
					target = enemy
					power = force
				end
			end
		end
	end
	if target and power >= 3 then
		use.card=final_parse(self,request,"#se_shengjiancard:.:")
		if use.to then use.to:append(target) end
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
	if target and target:getHp() <= 1 then
		if self:isFriend(target) then
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
		elseif not self:isFriend(target) then
			if viewer_role(self,target) == "rebel" then
				if not self:hasSkills(sgs.exclusive_skill, target) then
					for _, friend in ipairs(self.friends_noself) do
						if friend then
							target = friend
						end
					end
				end
			elseif viewer_role(self,target) == "loyalist" then
				target = self.room:getLord()
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
	if source:isKongcheng() then return end
	if source:getStrategyHasUsed("#se_zhurencard") then return end
	return parse(self,request,"#se_zhurencard:.:")
end

sgs.ai_skill_use_func["#se_zhurencard"]   = function(card,use,self,request)
	local target
	local source = self.player
	local max_num = source:getMaxHp() - source:getHp() + 1
	local max_x = 0

	for _, friend in ipairs(self.friends_noself) do
		local x = 5 - friend:getHandcardNum()
		if x > max_x and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
			max_x = x
			target = friend
		end
	end
	local cards = AIList.new(self.player:getHandcards())
	local needed = {}
	for _, acard in ipairs(cards) do
		if #needed < max_num then
			table.insert(needed, acard:getKnownEffectiveId())
		end
	end
	if target and needed then
		use.card=final_parse(self,request,"#se_zhurencard:" .. table.concat(needed, "+") .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_zhurencard"]         = 4
sgs.ai_use_priority["se_zhurencard"]      = 1
sgs.ai_card_intention["se_zhurencard"]    = -60

sgs.ai_skill_choice.Daolu                 = function(self, data)
	local lord = self.room:getLord()
	if self.player:getHp() > 0 then return "daolu_cancel" end
	if viewer_role(self,self.player) == "lord" then
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend) and friend:objectName() ~= self.player:objectName() then
				return "Fuko_summoner"
			end
		end
		return "Nagisa_Protector"
	elseif viewer_role(self,self.player) == "loyalist" then
		return "Tomoyo_Couple"
	elseif viewer_role(self,self.player) == "rebel" then
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend) and self.player:getHp() > 2 and friend:objectName() ~= self.player:objectName() then
				
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
		if lord:getHp() <= 2 or self:isWeak(self.player) then
			return "Fuko_summoner"
		end
		return "Nagisa_Protector"
	end
end

sgs.ai_skill_playerchosen.se_diangong     = function(self, targets)
	targets = AIList.new(targets)
	local target
	self:sortInPlace(self.friends, "hp")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) then
			target = friend
		end
	end
	if target then return target end
	return nil
end

sgs.ai_playerchosen_intention.se_diangong = function(from, to)
	local intention = -50
	self:updateIntention(from, to, intention)
end

sgs.ai_skill_playerchosen.Shouyang_st     = function(self, targets)
	local target
	local lord = self.room:getLord()
	if viewer_role(self,self.player) == "loyalist" then return lord end
	if viewer_role(self,self.player) == "rebel" then
		for _, friend in ipairs(self.friends) do
			if not friend:objectName() ~= self.player:objectName() and self:isWeak(friend) and self.player:getHp() > 2 then
				target = friend
			end
		end
	end
	if target then return target end
	for _, friend in ipairs(self.friends) do
		if not friend:objectName() ~= self.player:objectName() then
			target = friend
		end
	end
	return target
end

sgs.ai_playerchosen_intention.Shouyang_st = function(from, to)
	local intention = -100
	self:updateIntention(from, to, intention)
end

sgs.ai_ajustdamage_to.Shouyang_ed         = function(self, from, to, card, nature)
	if to:getMark("@Tomoyo") > 0
	then
		for _, p in sgs.list(self.room:getOtherPlayers(to)) do
			if p:hasSkill("Shouyang")
			then
				return self:ajustDamage(from, p, 0, card, nature)
			end
		end
	end
end

sgs.ai_skill_defense.Shouyang_ed = function(self, player)
	local defense = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasSkill("Shouyang") then
			defense = defense + p:getHp()
			break
		end
	end
	return defense
end


local se_diangong_skill = {}
se_diangong_skill.name  = "se_diangong"
table.insert(package_skills, se_diangong_skill)
se_diangong_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	for _, acard in ipairs(cards) do
		if self:getKeepValue(acard) < 4 and acard:isBlack() then
			local number = acard:getNumberString()
			local card_id = acard:getKnownEffectiveId()
			local suit = acard:getSuitString()
			return parse(self,request,("lightning:se_diangong[%s:%s]=%d"):format(suit, number, card_id))
		end
	end
end
sgs.ai_use_value["se_diangong"]          = 8
sgs.ai_use_priority["se_diangong"]       = 2.5

sgs.ai_ajustdamage_to["se_diangong"]     = function(self, from, to, card, nature)
	if card and card:isKindOf("Lightning") then
		return -99
	end
end
sgs.ai_ajustdamage_to["se_diangong_def"] = function(self, from, to, card, nature)
	if card and card:isKindOf("Lightning") then
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
	local usable_cards = AIList.new(self.player:getCards("h"))
	local target = self.room:getCurrentDyingPlayer()
	if target and self:isFriend(target) then
		self:sortByKeepValueInPlace(usable_cards)
		local to_discard = {}
		for _, c in ipairs(usable_cards) do
			if #to_discard < discard_num and not c:isKindOf("Peach") then
				table.insert(to_discard, c:getKnownEffectiveId())
			end
		end
		if #to_discard > 0 then
			return to_discard
		end
	end
	return {}
end

sgs.ai_skill_defense.se_Fanshe = function(self, player)
	return player:getCards("he"):length()
end

sgs.ai_skill_discard["se_Fanshe"] = function(self, discard_num, min_num, optional, include_equip)
	local damage = tag(self,"FansheDamage"):toDamage()
	local usable_cards = AIList.new(self.player:getCards("eh"))
	local target = damage.from
	if (target and not self:isFriend(target)) or not target then
		self:sortByKeepValueInPlace(usable_cards)
		local to_discard = {}
		for _, c in ipairs(usable_cards) do
			if #to_discard < discard_num and not c:isKindOf("Peach") then
				table.insert(to_discard, c:getKnownEffectiveId())
			end
		end
		if #to_discard > 0 then
			return to_discard
		end
	end
	return {}
end

sgs.ai_skill_choice["Heiyi-discard"] = function(self, choices, data)
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		return items[#items]
	end
end

sgs.ai_skill_playerchosen.Heiyi = function(self, targets)
	return self:findPlayerToDiscard("hej", true, true, targets, false)[1]
end

function sgs.ai_slash_prohibit.se_Fanshe(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if self:isFriend(to, from) then return false end
	return self:cantbeHurt(to, from)
end

local se_bianhua_skill = {}
se_bianhua_skill.name = "se_bianhua"
table.insert(package_skills, se_bianhua_skill)
se_bianhua_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:usedTimes("#se_bianhuaCard") >= 5 then return end
	local cards = AIList.new(self.player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	for _, card1 in ipairs(cards) do
		if not card1:isKindOf("Peach") then
			return parse(self,request,"#se_bianhuaCard:" .. card1:getKnownEffectiveId() .. ":")
		end
	end
end

sgs.ai_skill_use_func["#se_bianhuaCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_invoke["se_Baiyi"]       = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	local lord = self.room:getLord()
	if lord and self:isWeak(lord) and viewer_role(self,self.player) == "loyalist" then
		if lord:objectName() == source:objectName() then
			return true
		else
			return false
		end
	end
	if self:isWeak(self.player) and source:objectName() ~= self.player:objectName() then
		return false
	end
	for _, player in ipairs(self.friends) do
		if player:isAlive() and source and source:objectName() == player:objectName() then
			return true
		end
	end
	if source:objectName() == self.player:objectName() then
		return true
	end
	return false
end






local se_jianyu_skill = {}
se_jianyu_skill.name = "se_jianyu"
table.insert(package_skills, se_jianyu_skill)
se_jianyu_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#se_jianyucard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#se_jianyucard:.:")
end

sgs.ai_skill_use_func["#se_jianyucard"] = function(card,use,self,request)
	local targets = AIList.new({})
	local slash = self:cloneEvaluationCard("slash")
	
	self:sortInPlace(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if targets:length() < self.player:getMaxHp() - self.player:getHp() + 1 and not enemy:inMyAttackRange(self.player) and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, slash) then
			targets:append(enemy)
		end
	end
	if targets:length() < self.player:getMaxHp() - self.player:getHp() + 1 then
		for _, enemy1 in ipairs(self.enemies) do
			if targets:length() < self.player:getMaxHp() - self.player:getHp() + 1 and enemy1:inMyAttackRange(self.player) and self:slashIsEffective(slash, enemy1, self.player) then
				targets:append(enemy1)
			end
		end
	end
	if targets:length() > 0 then
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
	return from:getPhase() == sgs.Player_Play and not to:inMyAttackRange(from)
end


sgs.ai_skill_invoke.se_qidian           = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen["se_qidian"]  = function(self, targets)
	local target
	targets = AIList.new(targets)
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(targets) do
		if enemy and self:isEnemy(enemy)
			and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
			and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) then
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

sgs.ai_skill_cardask["#se_qidian"] = function(self, data)
	local judge = data:toJudge()

	if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = AIList.new(self.player:getCards("he"))
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

sgs.wizard_skill = sgs.wizard_skill .. "|se_qidian"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|se_qidian"




local se_zhiyu_skill = {}
se_zhiyu_skill.name = "se_zhiyu"
table.insert(package_skills, se_zhiyu_skill)
se_zhiyu_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends <= 1 then return end
	if self.player:isKongcheng() then return end
	local invoke = false
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("EquipCard") then
			invoke = true
			break
		end
		if card:getSuit() == sgs.Card_Heart then
			if self.player:isWounded() then
				invoke = true
				break
			else
				if self.player:getHandcardNum() > self.player:getHp() then
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
	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	local notFound
	for i = 1, #cards do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			table.removeOne(cards, card)
		else
			notFound = true
			break
		end
		if friend:objectName() == self.player:objectName()
			or not self.player:getHandcards():contains(card) or
			not (card:getSuit() == sgs.Card_Heart or card:isKindOf("EquipCard"))
		then
			continue
		end
		if card:isAvailable(self.player)
		then
			if card:isKindOf("Slash") and card:getSuit() == sgs.Card_Heart
			then
				local dummy_use = self:aiUseCard(card)
				if dummy_use.card
				then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then
						continue
					elseif t1:getHp() < 2 or getCardsNum("Jink", t1, self.player) < 1
						or t1:isCardLimited(self:cloneEvaluationCard("jink"), sgs.Card_MethodResponse)
					then
						continue
					end
				end
			elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and card:getSuit() == sgs.Card_Heart
				and self:getEnemyNumBySeat(self.player, friend) > 0
			then
				local dummy_use = self:aiUseCard(card)
				if dummy_use.card
				then
					local hasDelayedTrick
					for _, p in sgs.list(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			elseif card:isKindOf("DelayedTrick") and card:getSuit() == sgs.Card_Heart
				and self:getEnemyNumBySeat(self.player, friend) > 0
				and self:aiUseCard(card).card
			then
				continue
			end
		end
		if friend:hasSkill("enyuan") and #cards >= 1
			and not (self.room:getMode() == "04_1v3")
		then
			use.card=final_parse(self,request,"#se_zhiyucard:" .. card:getKnownId() .. "+" .. cards[1]:getId() .. ":")
		else
			use.card=final_parse(self,request,"#se_zhiyucard:" .. card:getKnownId() .. ":")
		end
		if use.to then use.to:append(friend) end
		return
	end
	if notFound and ((self:isWeak()
		and self.player:getHandcardNum() > 3) or (self:getOverflow() > 0))
	then
		cards = AIList.new(self.player:getHandcards())
		self:sortByUseValueInPlace(cards, true)
		for _, p in sgs.list(self.room:getOtherPlayers(self.player)) do
			if not self:isFriend(p) and hasManjuanEffect(p)
			then
				local to_give = {}
				for _, card in ipairs(cards) do
					if not isCard("Peach", card, self.player) and (card:getSuit() == sgs.Card_Heart or card:isKindOf("EquipCard"))
					then
						table.insert(to_give, card:getKnownId())
					end
					if card:getSuit() == sgs.Card_Heart or card:isKindOf("EquipCard") then break end
				end
				if #to_give > 0 then
					use.card=final_parse(self,request,"#se_zhiyucard:" .. table.concat(to_give, "+") .. ":")
					if use.to then
						use.to:append(p)
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
	if self.player:getStrategyHasUsed("#se_liaolicard") then return end
	if self.player:isKongcheng() then return end
	local invoke = false
	local Card_H_Num = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getSuit() ~= sgs.Card_Heart then
			Card_H_Num = Card_H_Num + 1
			if not self.player:isWounded() then
				invoke = true
				break
			end
			for _, friend in ipairs(self.friends) do
				if friend:getJudgingArea():length() > 0 then
					invoke = true
					break
				end
			end
		end
	end
	if Card_H_Num > self.player:getMaxHp() - self.player:getHp() then
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
		if friend:getJudgingArea():length() > judge_num and friend:getMark("@se_liaoli") == 0 then
			target = friend
			judge_num = friend:getJudgingArea():length()
		end
	end
	if not target then
		local handcard_num = 0
		for _, friend in ipairs(self.friends) do
			if friend:getHandcardNum() > handcard_num and friend:getMark("@se_liaoli") == 0 then
				target = friend
				handcard_num = friend:getHandcardNum()
			end
		end
	end
	if not target and self.player:getMark("@se_liaoli") == 0 then target = self.player end
	local hcard = self.player:getHandcards()
	local cards = AIList.new(hcard)
	self:sortByUseValueInPlace(cards, true)
	card_to = cards[1]
	if target and card_to then
		use.card=final_parse(self,request,"#se_liaolicard:" .. card_to:getKnownEffectiveId() .. ":")
		if use.to then use.to:append(target) end
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
	return self.player:getHp() > 10
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
	if self.player:getPile("Neko"):length() == 0 then return end
	local can = false
	for _, enemy in ipairs(self.enemies) do
		if (enemy:getMark("@Neko_S") == 0 or enemy:getMark("@Neko_C") == 0 or (enemy:getMark("@Neko_D") == 0 and not enemy:hasSkill("Huansha")) or enemy:getMark("@Neko_H") == 0) and not enemy:hasFlag("Can_not") then
			can = true
		end
	end
	if viewer_role(self,self.player) == "renegade" then
		if #self.enemies - #self.friends <= 0 then
			can = false
		end
		if self.player:getPile("Neko"):length() <= 8 and #self.enemies - #self.friends <= 1 then
			can = false
		end
		if self.player:getPile("Neko"):length() <= 3 and #self.enemies - #self.friends <= 2 then
			can = false
		end
	end
	if not can then return end
	return parse(self,request,"#se_zhilingcard:.:")
end

sgs.ai_skill_use_func["#se_zhilingcard"] = function(card,use,self,request)
	local target
	local lord = self.room:getLord()
	for _, enemy in ipairs(self.enemies) do
		if ((enemy:getMark("@Neko_S") == 0) or (enemy:getMark("@Neko_C") == 0) or ((enemy:getMark("@Neko_D") == 0) and not enemy:hasSkill("Huansha")) or (enemy:getMark("@Neko_H") == 0)) and not enemy:hasFlag("Can_not") then
			target = enemy
		end
	end
	if viewer_role(self,self.player) == "rebel" then
		if (lord:getMark("@Neko_S") == 0 or lord:getMark("@Neko_C") == 0 or (lord:getMark("@Neko_D") == 0 and not lord:hasSkill("Huansha")) or lord:getMark("@Neko_H") == 0) and not lord:hasFlag("Can_not") then
			target = lord
		end
	end
	if target then
		local cardsq
		for _, id in sgs.qlist(self.player:getPile("Neko")) do
			local card = disclosed(self,id)
			local suit = card:getSuitString()
			local card_id = card:getKnownEffectiveId()
			if (target:getMark("@Neko_S") == 0) or (target:getMark("@Neko_C") == 0) or (target:getMark("@Neko_D") == 0) or (target:getMark("@Neko_H") == 0) then
				if ((target:getMark("@Neko_S") == 0) and (suit == "spade")) or ((target:getMark("@Neko_C") == 0) and (suit == "club")) or ((target:getMark("@Neko_D") == 0) and (suit == "diamond")) or ((target:getMark("@Neko_H") == 0) and (suit == "heart")) then
					cardsq = card
				end
			end
		end
		if cardsq then
			local card_str = string.format("#se_zhilingcard:%s:", cardsq:getKnownEffectiveId())
			local acard = parse(self,request,card_str)
			use.card = acard
			if use.to then use.to:append(target) end
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
	local dyingwho = self.room:getCurrentDyingPlayer()
	if not self:isFriend(dyingwho) then return nil end
	local target
	local targets = AIList.new(targets)
	for _, friend in ipairs(targets) do
		if friend:isMale() and friend:getHandcardNum() <= 2 and self:isFriend(friend) then
			target = friend
			break
		end
	end
	if not target then
		for _, enemy in ipairs(targets) do
			if enemy:isMale() and not enemy:isKongcheng() and self:isEnemy(enemy) then
				target = enemy
				break
			end
		end
	end
	if target then return target end
	return nil
end

sgs.ai_cardshow.SE_Zhixing = function(self, requestor)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	if self:isFriend(requestor) then
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Diamond then return card end
		end
	end
	if self:isFriend(requestor) then
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Heart then return card end
		end
	end
	return self.player:getRandomHandCard()
end


sgs.ai_skill_playerchosen.SE_Zhihui = function(self, targets)
	local target
	local dmg = tag(self,"SE_Zhihui"):toDamage()
	local targets = AIList.new(targets)
	self:sortInPlace(targets, "hp")


	for _, friend in ipairs(targets) do
		if friend and self:isFriend(friend) and (friend:getLostHp() + dmg.damage > 1 and friend:isAlive()) then
			if friend:isChained() and dmg.nature ~= sgs.DamageStruct_Normal and not self:isGoodChainTarget(friend, dmg.from, dmg.nature, dmg.damage, dmg.card) then
			elseif friend:getHp() >= 2 and dmg.damage < 2
				and (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
					or self:canAttack(friend, dmg.from or self.room:getCurrent())
					or self:needToLoseHp(friend)
					or (friend:getHandcardNum() < 3 and (friend:hasSkill("nosrende") or (friend:hasSkill("rende") and not friend:getStrategyHasUsed("RendeCard"))))) then
				return friend
			elseif dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and friend:hasSkill("wuyan") and friend:getLostHp() > 1 then
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
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:getMark("@Geass") > 0 then
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
	local list = self.room:getOtherPlayers(self.player)
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
	if self_people >= list:length() / 2 then
		can = false
	end
	if not can then return end
	return parse(self,request,"#SE_GeassCard:.:")
end

sgs.ai_skill_use_func["#SE_GeassCard"] = function(card,use,self,request)
	local target

	local list = self.room:getOtherPlayers(self.player)
	list = AIList.new(list)
	self:sortInPlace(list, "hp")
	for _, p in ipairs(list) do
		if p:getMark("@Geass") == 0 then
			target = p
		end
	end
	if target then
		local card_str = "#SE_GeassCard:.:"

		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then
			
			role_write(self,"SE_Geass",target,target,false)
			use.to:append(target)
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
		if friend:hasSkill("se_erdao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("Xuwu") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("jizhi") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkills(sgs.cardneed_skill) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() > 2 then
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
	if self.player:getPhase() == sgs.Player_NotActive then
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
		if friend:hasSkill("Zhudao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("se_zhiyu") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("se_erdao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("xuanfeng") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("xiaoji") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkills(sgs.lose_equip_skill) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() > 2 then
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
		if friend:hasSkill("Zhudao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("se_zhiyu") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("se_erdao") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("xuanfeng") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("xiaoji") then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() > 2 then
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
	return card:isNDTrick() or card:isKindOf("EquipCard")
end



sgs.ai_skill_invoke.SE_Mengfeng = function(self, data)
	if #self.friends == 1 then return false end
	if self.player:getMaxCards() <= 0 then return false end
	if self.player:hasFlag("WangzunDecMaxCards") and self.player:getHp() <= 1 then return false end

	
	local cards = AIList.new(self.player:getHandcards())
	local shouldUse, range_fix = 0, 0
	local hasCrossbow, slashTo = false, false
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") and self:getUseValue(card) > 3.69 then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then shouldUse = shouldUse + (card:isKindOf("ExNihilo") and 2 or 1) end
		end
		if card:isKindOf("Weapon") then
			local new_range = sgs.weapon_range[card:getClassName()] or 0
			local current_range = self.player:getAttackRange()
			range_fix = math.min(current_range - new_range, 0)
		end
		if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix - 1 end
		if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink") == 0) then
			shouldUse =
				shouldUse + 1
		end
		if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
	end

	local slashs = self:getCards("Slash")
	for _, enemy in ipairs(self.enemies) do
		for _, slash in ipairs(slashs) do
			if hasCrossbow and self:getCardsNum("Slash") > 1 and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) then
				shouldUse = shouldUse + 2
				hasCrossbow = false
				break
			elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) and getCardsNum("Jink", enemy) < 1 then
				shouldUse = shouldUse + 1
				slashTo = true
			end
		end
	end
	if shouldUse >= 2 then return false end


	if role_count(self,"rebel") then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) then
			return true
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return true
	end

	self:sortInPlace(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, target in ipairs(self.friends_noself) do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			return true
		end
	end

	for _, target in ipairs(self.friends_noself) do
		if target:hasSkill("dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if p:getMark("@fog") > 0 then
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
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() and lord:getHp()+self:getAllPeachNum() - 1 > 0 then
			return lord
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and self:isFriend(AssistTarget) and AssistTarget:getHp()+self:getAllPeachNum() - 1 > 0 then
		return AssistTarget
	end

	self:sortInPlace(self.friends_noself, "chaofeng")
	for _, target in ipairs(self.friends_noself) do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) and target:getHp()+self:getAllPeachNum() - 1 > 0  then
			return target
		end
	end

	for _, target in ipairs(self.friends_noself) do
		if target:hasSkill("dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if p:getMark("@fog") > 0 then
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
	local dest = data:toPlayer()
	if not dest:faceUp() then
		return "TurnOver_target"
	end
	return "LoseHp_target"
end

sgs.ai_skill_playerchosen.SE_Nagong_Geiqian = function(self, targets)
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.SE_Nagong_Geiqian = -50

sgs.ai_skill_use["@@SE_Nagong_Geiqian"] = function(self, prompt)
	self:updatePlayers()
	
	if not self.player:isWounded() then return "." end
	if self.player:getHandcardNum() < 2 then return "." end
	local reimu = self.room:findPlayerBySkillName("SE_Nagong")
	if not reimu then return "." end
	if self:needKongcheng(reimu, true) or hasManjuanEffect(reimu) then
		return "."
	end
	local give_all_cards = {}
	for _, c in ipairs(AIList.new(self.player:getCards("h"))) do
		if #give_all_cards < 2 then
			table.insert(give_all_cards, c:getKnownEffectiveId())
		end
	end
	if reimu and self:isFriend(reimu) and #give_all_cards > 1 then
		return "#SE_Nagong_Geiqian:" .. table.concat(give_all_cards, "+") .. ":->" .. reimu:objectName()
	end
	return "."
end





sgs.ai_skill_invoke.SE_Yishi = function(self, data)
	for _, p in ipairs(self.friends) do
		if p:isMale() then
			return true
		end
	end
	return false
end
sgs.ai_playerchosen_intention.SE_Yishi = -80
sgs.ai_skill_playerchosen.SE_Yishi = function(self, targets)
	local lord = self.room:getLord()
	for _, p in ipairs(self.friends) do
		if p:isMale() and p:objectName() == lord:objectName() then
			return p
		end
	end
	local hp = 0
	local max_man
	local hp_min = 100
	local min_man
	for _, p in ipairs(self.friends) do
		if p:isMale() and p:getHp() > hp then
			hp = p:getHp()
			max_man = p
		end
		if p:isMale() and p:getHp() < hp_min then
			hp_min = p:getHp()
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
	if self.player:hasFlag("se_dushecard") then return end
	if #self.enemies < 1 or self.player:isKongcheng() then return end
	local can_man = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 then
			can_man = true
		end
	end
	if not can_man then return end
	local cards = AIList.new(self.player:getHandcards())
	local OK = false
	for _, card in ipairs(cards) do
		if card:getNumber() > 8 then
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
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isBlack() then B = true end
		if card:isRed() then R = true end
	end
	if B then
		for _, enemy in ipairs(self.enemies) do
			if enemy:isAlive() and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") and not (enemy:getHandcardNum() == 1 and enemy:hasSkill("kongcheng")) then
				if enemy:getEquips():length() > 2 then
					dushe_flag(self,enemy,"se_dushe_Equip",true)
					return enemy
				end
			end
		end
	end
	if R then
		for _, enemy in ipairs(self.enemies) do
			if enemy:isAlive() and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") and not (enemy:getHandcardNum() == 1 and enemy:hasSkill("kongcheng")) then
				if enemy:getHp() == 1 or enemy:getHp() == 2 then
					dushe_flag(self,enemy,"se_dushe_Dm",true)
					return enemy
				end
			end
		end
	end
	if B then
		for _, enemy in ipairs(self.enemies) do
			if enemy:isAlive() and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") and not (enemy:getHandcardNum() == 1 and enemy:hasSkill("kongcheng")) then
				if enemy:getEquips():length() > 1 then
					dushe_flag(self,enemy,"se_dushe_Equip",true)
					return enemy
				end
			end
		end
	end
	if R then
		for _, enemy in ipairs(self.enemies) do
			if enemy:isAlive() and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") and not (enemy:getHandcardNum() == 1 and enemy:hasSkill("kongcheng")) then
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
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if dushe_flag(self,p,"se_dushe_Equip") then return "se_dushe_Discard" end
		if dushe_flag(self,p,"se_dushe_Dm") then return "se_dushe_Damage" end
	end
	return false
end

sgs.ai_skill_cardask["se_dushe_invoke"] = function(self, data, pattern, target, target2)
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if dushe_flag(self,target,"se_dushe_Dm") then
			if not c:isKindOf("Peach") then
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
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if c:isRed() then
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
		if friend:getHandcardNum() < 3 and friend:objectName() ~= self.player:objectName() then
			return friend
		end
	end
	for _, friend in ipairs(self.friends) do
		if friend:objectName() ~= self.player:objectName() then
			return friend
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention.SE_Minatsu = 60
sgs.ai_skill_playerchosen.SE_Minatsu = function(self, targets)
	if #self.enemies == 0 then return nil end
	self:sortInPlace(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = self:cloneEvaluationCard("fire_slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then
			return enemy
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.SE_Chizuru = -80
sgs.ai_skill_playerchosen.SE_Chizuru = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then target = arr1[1] end
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
		if enemy:getHandcardNum() - enemy:getHp() > card_num and enemy:getMark("@SE_Mafuyu") == 0 then
			target = enemy
			card_num = enemy:getHandcardNum() - enemy:getHp()
		end
	end
	if target then
		return target
	end
	for _, enemy in ipairs(self.enemies) do
		if  enemy:getMark("@SE_Mafuyu") == 0 then
			return enemy
		end
	end
	return self.enemies[1]
end

sgs.ai_hasTuntianEffect_skill.SE_Kurimu = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_hasTuntianEffect_skill.SE_Minatsu = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_hasTuntianEffect_skill.SE_Chizuru = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_hasTuntianEffect_skill.SE_Mafuyu = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end



local se_xunyu_skill = {}
se_xunyu_skill.name = "se_xunyu"
table.insert(package_skills, se_xunyu_skill)
se_xunyu_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	if self.player:isKongcheng() then return end
	local cards = AIList.new(self.player:getHandcards())
	if self.player:getMark("@SE_Chaopin_Red") > 0 then
		if self.player:getStrategyHasUsed("#se_xunyucard") then return end
		return parse(self,request,"#se_xunyucard:.:")
	end
	local card_OK = false
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("Jink") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
			card_OK = true
		end
	end
	if not card_OK then return end
	if self.player:getMark("@SE_Chaopin_Blue") > 0 then
		if self.player:usedTimes("#se_xunyucard") >= 3 then return end
	elseif self.player:getMark("@SE_Chaopin_Blue") == 0 then
		if self.player:getStrategyHasUsed("#se_xunyucard") then return end
	end
	if self.player:getMark("@SE_Chaopin_Green") > 0 then return end
	for _, enemy in ipairs(self.enemies) do
		local slash = self:cloneEvaluationCard("slash")
		
		if self.player:inMyAttackRange(enemy) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) then
			return parse(self,request,"#se_xunyucard:.:")
		end
	end
end

sgs.ai_skill_use_func["#se_xunyucard"] = function(card,use,self,request)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	local target
	local card
	local slash = self:cloneEvaluationCard("slash")
	
	if self.player:getMark("@SE_Chaopin_Red") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.masochism_skill, enemy) then
				target = enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.masochism_skill, enemy) and enemy:getHp() == 1 and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) then
				target = enemy
			end
		end
		if not target then target = self.enemies[1] end
		use.card=final_parse(self,request,"#se_xunyucard:.:")
		if use.to then use.to:append(target) end
		return
	end
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("Jink") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
			card = acard
		end
	end
	if self.player:getMark("@SE_Chaopin_Blue") > 0 then
		card = cards[1]
	end
	local min_people
	local min_Hp = 100
	for _, enemy in ipairs(self.enemies) do
		if not self:hasSkills(sgs.masochism_skill, enemy) and self.player:inMyAttackRange(enemy) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) then
			if enemy:getHp() <= min_Hp then
				min_people = enemy
				min_Hp = enemy:getHp()
			end
		end
	end
	if self.player:getMark("@SE_Chaopin_Blue") > 0 then
		local min_Hp = 100
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) then
				if enemy:getHp() <= min_Hp then
					min_people = enemy
					min_Hp = enemy:getHp()
				end
			end
		end
		local min_Hp = 100
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.masochism_skill, enemy) and self.player:inMyAttackRange(enemy) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:canSlash(enemy, slash, false) and not self:slashProhibit(nil, enemy) then
				if enemy:getHp() <= min_Hp then
					min_people = enemy
					min_Hp = enemy:getHp()
				end
			end
		end
	end
	target = min_people
	if target and card then
		use.card=final_parse(self,request,"#se_xunyucard:" .. card:getKnownEffectiveId() .. ":")
		if use.to then use.to:append(target) end
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
		if self.player:inMyAttackRange(enemy) then
			can_slash = true
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 then
			if self.player:inMyAttackRange(enemy) then
				if self.player:getHandcardNum() < 2 then
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
		if self.player:getHandcardNum() < 2 then return "SE_Chaopin_Green" end
		if self.player:getHandcardNum() < 4 then return "SE_Chaopin_Red" end
		if not can_slash then return "SE_Chaopin_Red" end
		return "SE_Chaopin_Blue"
	elseif weak > 1 then
		if self.player:getHandcardNum() < 5 then return "SE_Chaopin_Green" end
		if not can_slash then return "SE_Chaopin_Green" end
		return "SE_Chaopin_Blue"
	elseif weak == 0 or weak == -1 then
		if self.player:getHandcardNum() < 3 then return "SE_Chaopin_Green" end
		if self.player:getHandcardNum() < 5 then return "SE_Chaopin_Red" end
		if not can_slash then return "SE_Chaopin_Red" end
		return "SE_Chaopin_Blue"
	elseif weak < -1 then
		if self.player:getHandcardNum() < 5 then return "SE_Chaopin_Green" end
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
	if self.player:getHp() < self.player:getMaxHp() then return true end
	if self.player:getHp() == self.player:getMaxHp() then
		if #self.friends >= #self.enemies then return true end
	end
	return false
end


sgs.ai_getBestHp_skill.SE_Qifen = function(owner)
	return owner:getMaxHp() - 1
end

sgs.ai_skill_invoke.SE_Mishi = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	local good
	if not self:isFriend(source) then
		good = true
	end
	if not good then return false end
	local peach_num = 0
	local jink_num = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			peach_num = peach_num + 1
		end
		if card:isKindOf("Jink") then
			jink_num = jink_num + 1
		end
	end
	if good then
		if self.player:getHp() > 0 and peach_num > 2 then return true end
		if self.player:getHp() > 0 and peach_num > 1 and jink_num > 0 then return true end
		if self.player:getHp() > 1 and peach_num > 1 then return true end
		if self.player:getHp() > 1 and peach_num > 0 and jink_num > 0 then return true end
		if self.player:getHp() > 2 and peach_num > 0 then return true end
		if self.player:getHp() > 2 and jink_num > 0 then return true end
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
		if self.player:getHandcardNum() - friend:getHandcardNum() > max_num and friend:objectName() ~= self.player:objectName() and self:canDraw(friend, self.player) then
			good_to = friend
			max_num = self.player:getHandcardNum() - friend:getHandcardNum()
		end
	end
	if good_to then return good_to end
	for _, friend in ipairs(self.friends) do
		if friend:objectName() ~= self.player:objectName() and self:canDraw(friend, self.player) then
			return friend
		end
	end
	return nil
end






sgs.ai_skill_playerchosen.SE_Xiuse = function(self, targets)
	self:updatePlayers()
	
	local targets = AIList.new(targets)
	self:sortInPlace(targets, "handcard")
	local target = nil
	local n = self.player:getHp()
	for _, friend in ipairs(targets) do
		if not friend:faceUp() and self:isFriend(friend) then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(targets) do
			if not self:toTurnOver(friend, n, "SE_Xiuse") and self:isFriend(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = self:findPlayerToDraw(false, n)
			if not target then
				for _, enemy in ipairs(targets) do
					if self:toTurnOver(enemy, n, "SE_Xiuse") and hasManjuanEffect(enemy) and self:isEnemy(enemy) then
						target = enemy
						break
					end
				end
			end
		else
			self:sortInPlace(self.enemies)
			for _, enemy in ipairs(targets) do
				if self:toTurnOver(enemy, n, "SE_Xiuse") and hasManjuanEffect(enemy) and self:isEnemy(enemy) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(targets) do
					if self:toTurnOver(enemy, n, "SE_Xiuse") and self:hasSkills(sgs.priority_skill, enemy) and self:isEnemy(enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(targets) do
					if self:toTurnOver(enemy, n, "SE_Xiuse") and self:isEnemy(enemy) then
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
	if not player:hasSkill("SE_Xiuse") then return false end
	local enemies = self:getEnemies(player)
	if #enemies < 1 then return false end
	self:sortInPlace(enemies, "defense")
	for _, enemy in ipairs(enemies) do
		if player:getLostHp() < 1 and self:toTurnOver(enemy, player:getHp() - 1, "SE_Xiuse") then
			return true
		end
	end
	local friends = self:getFriends(player, true)
	self:sortInPlace(friends, "defense")
	for _, friend in ipairs(friends) do
		if not self:toTurnOver(friend, player:getHp() - 1, "SE_Xiuse") then return true end
	end
	return false
end


sgs.ai_playerchosen_intention.SE_Xiuse = function(self, from, to)
	if hasManjuanEffect(to) then self:updateIntention(from, to, 80) end
	local intention = 80 / math.max(from:getHp(), 1)
	if not self:toTurnOver(to, from:getHp(), "SE_Xiuse") then intention = -intention end
	if from:getHp() < 3 then
		self:updateIntention(from, to, intention)
	else
		self:updateIntention(from, to, math.min(intention, -30))
	end
end

sgs.ai_skill_invoke.SE_Shuanglang = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.SE_Shuanglang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, 50) end
	end
end




sgs.ai_playerchosen_intention.SE_Lianmu = -60
sgs.ai_skill_playerchosen.SE_Lianmu     = function(self, targets)
	local list = self.room:getAlivePlayers()

	local min_Hp = 100
	local target
	for _, friend in sgs.qlist(targets) do
		if self:isFriend(friend) and friend:getHp() < min_Hp then
			min_Hp = friend:getHp()
			target = friend
		end
	end
	if target then return target end
	return nil
end



sgs.ai_skill_invoke.SE_Feiti            = function(self, data)
	local list = self.room:getAlivePlayers()
	local targets = AIList.new({})
	for _, p in sgs.qlist(list) do
		if p:isMale() then
			targets:append(p)
		end
	end
	if targets:length() > 0 then return true end
	return false
end

sgs.ai_skill_playerchosen.SE_Feiti      = function(self, targets)
	local list = self.room:getAlivePlayers()
	local targets = AIList.new({})
	for _, p in sgs.qlist(list) do
		if p:isMale() then
			targets:append(p)
		end
	end
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) and p:hasSkill("SE_Shuanglang") then
			return p
		end
	end
	local card_num = 100
	local target
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) then
			if p:getHandcardNum() < card_num then
				target = p
				card_num = p:getHandcardNum()
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
	local list = self.room:getAlivePlayers()
	local target
	for _, p in sgs.qlist(list) do
		if p:hasFlag("SE_Feiti_Target") then
			target = p
		end
	end
	if self:isFriend(target) then return "SE_Feiti_Get" end
	return "SE_Feiti_Not_Get"
end

sgs.ai_choicemade_filter.skillChoice["SE_Feiti"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	local list = self.room:getAlivePlayers()
	for _, p in sgs.qlist(list) do
		if p:hasFlag("SE_Feiti_Target") then
			target = p
		end
	end
	if choice == "SE_Feiti_Get" and target then
		self:updateIntention(player, target, -80)
	end
end

sgs.ai_damage_reason_suppress_intention["SE_Feiti"] = true



sgs.ai_skill_invoke.SE_Menghei = function(self, data)
	local damage = data:toDamage()
	if self.player:objectName() == damage.from:objectName() then
		if self:isEnemy(damage.to) then
			return true
		end
	end
	if self.player:objectName() == damage.to:objectName() then
		local danteng = damage.from
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if danteng:distanceTo(p) <= 1 then
				if self:isEnemy(p) then
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
		if self:isEnemy(ap) and ap:getHp() < hp_min and not self:hasZhaxiangEffect(ap) then
			target = ap
			hp_min = ap:getHp()
		end
	end
	if target then return target end
	return nil
end



function sgs.ai_slash_prohibit.SE_Menghei(self, from, to)
	if self:isFriend(from, to) then return false end
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if from:getHp() >= 2 then return false end
	return from:getHp() + from:getEquips():length() < 4 or from:getHp() < 2
end



local se_gaobai_skill = {}
se_gaobai_skill.name = "se_gaobai"
table.insert(package_skills, se_gaobai_skill)
se_gaobai_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getMark("@Gaobai") < 1 then return end
	if #self.friends < 1 then return end
	local OK = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isMale() and self:isFriend(p) and p:getHp() == 1 then
			OK = true
		end
		if p:isMale() and self:isFriend(p) and p:getHp() == 2 and self.player:getHp() == 1 and p:getMaxHp() == 3 then
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
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isMale() and self:isFriend(p) and p:getHp() == 1 then
			target = p
		end
		if p:isMale() and self:isFriend(p) and p:getHp() == 2 and self.player:getHp() == 1 and p:getMaxHp() == 3 then
			target = p
		end
		if p:isMale() and self:isFriend(p) and p:getHp() == 1 and p:getMaxHp() == 3 then
			target = p
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_gaobaicard"]       = 10
sgs.ai_use_priority["se_gaobaicard"]    = 4
sgs.ai_card_intention.se_gaobaicard     = -100




function sgs.ai_skill_invoke.SE_Touming(self, data)
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return true
		end
	end
	return self:isWeak() or self.room:getAlivePlayers():length() > 4
end

sgs.ai_ajustdamage_to.SE_Touming = function(self, from, to, card, nature)
	if not to:faceUp() then
		return -99
	end
end

sgs.ai_skill_invoke.SE_Tuanzi = function(self, data)
	local card = data:toCardUse().card
	local people = self.player:getNextAlive()
	if card:isKindOf("Peach") or card:isKindOf("Jink") or card:isKindOf("Analeptic") or card:isKindOf("EquipCard") or card:isNDTrick() then
		if self:isFriend(people) then return true end
		if self.player:getHandcardNum() - self.player:getHp() < 2 then return true end
		return false
	end
	if self:isFriend(people) and isEquip("Crossbow", people) then
		if card:isKindOf("Slash") then return true end
	end
	return false
end



sgs.ai_skill_invoke.SE_Zishang = function(self, data)
	local damage = data:toDamage()
	local victim = damage.to
	if self:isFriend(victim) then
		if (self:isWeak(victim) and not self:isWeak(self.player)) then
			if self:isEnemy(damage.from) then return true end
		end
		if not self:isWeak(self.player) then
			for _, friend in ipairs(self.friends) do
				if friend:getHp() < friend:getMaxHp() and friend:objectName() ~= self.player:objectName() then
					if self:isEnemy(damage.from) and damage.from:faceUp() then return true end
				end
			end
		end
		if not self:damageIsEffective(self.player, damage.nature, damage.from) then
			for _, friend in ipairs(self.friends) do
				if friend:getHp() < friend:getMaxHp() and friend:objectName() ~= self.player:objectName() then
					if self:isEnemy(damage.from) and damage.from:faceUp() then return true end
				end
			end
		end
	end
	if self.room:getAllPlayers(true):length() == 2 then
		if self.player:getHp() >= 2 and victim:faceUp() then return true end
	end
	return false
end


sgs.ai_skill_playerchosen.SE_Zishang = function(self, targets)
	local hp_min = 100
	local target
	for _, ap in sgs.qlist(targets) do
		if self:isFriend(ap) and ap:getHp() < hp_min then
			target = ap
			hp_min = ap:getHp()
		end
	end
	if target then return target end
	return targets:first()
end


sgs.ai_choicemade_filter.skillInvoke.SE_Zishang = function(self,player,promptlist)
	local damage = tag(self,"SE_Zishang"):toDamage()
	if damage.to then
		if promptlist[#promptlist]=="yes" then
			self:updateIntention(self.player, damage.to, -80)
		end
	end
end

sgs.ai_skill_choice.SE_Zibi = function(self, data)
	if self.player:getHp() < self.player:getMaxHp() then
		return "SE_Zibi_R"
	end
	return "SE_Zibi_D"
end


local se_huanyuan_skill = {}
se_huanyuan_skill.name = "se_huanyuan"
table.insert(package_skills, se_huanyuan_skill)
se_huanyuan_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#se_huanyuancard") then return end
	if self.player:getMark("se_huanyuan_Pre_MaxHp") <= 0 then return end
	if #self.friends < 1 and #self.enemies < 1 then return end
	for _, friend in ipairs(self.friends) do
		if friend:getMark("se_huanyuan_Pre_Hp") - friend:getHp() + (friend:getMark("se_huanyuan_Pre_MaxHp") - friend:getMaxHp()) * 2 > 0 then
			return parse(self,request,"#se_huanyuancard:.:")
		end
		if friend:getMark("se_huanyuan_Pre_Handcards") > friend:getHandcardNum() then
			return parse(self,request,"#se_huanyuancard:.:")
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() - enemy:getMark("se_huanyuan_Pre_Hp") + (enemy:getMaxHp() - enemy:getMark("se_huanyuan_Pre_MaxHp")) * 2 > 0 then
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
	local hcards = self.player:getCards("h")
	hcards = AIList.new(hcards)
	self:sortByKeepValueInPlace(hcards, true)

	for _, hcard in ipairs(hcards) do
		if not hcard:isKindOf("Peach") then
			cardx = hcard
			break
		end
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		local p_v = 0
		local draw = true
		if self:isFriend(p) then
			if p:getMark("se_huanyuan_Pre_Hp") - p:getHp() + (p:getMark("se_huanyuan_Pre_MaxHp") - p:getMaxHp()) * 2 > p_v then
				p_v = p:getMark("se_huanyuan_Pre_Hp") - p:getHp() +
					(p:getMark("se_huanyuan_Pre_MaxHp") - p:getMaxHp()) *
					2
				draw = false
			end
			if p:getMark("se_huanyuan_Pre_Handcards") - p:getHandcardNum() > p_v * 2 then
				p_v = (p:getMark("se_huanyuan_Pre_Handcards") - p:getHandcardNum()) / 2
				draw = true
			end
		elseif self:isEnemy(p) then
			if p:getHp() - p:getMark("se_huanyuan_Pre_Hp") + (p:getMaxHp() - p:getMark("se_huanyuan_Pre_MaxHp")) * 2 > p_v then
				p_v = p:getHp() - p:getMark("se_huanyuan_Pre_Hp") +
					(p:getMaxHp() - p:getMark("se_huanyuan_Pre_MaxHp")) *
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
		use.card=final_parse(self,request,"#se_huanyuancard:" .. cardx:getKnownId() .. ":")
		if use.to then use.to:append(target) end
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
	if self.player:getMark("@LimeBell") < 1 then return end
	if #self.friends < 2 then return end
	local OK = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and p:getMaxHp() - p:getHp() >= 2 then
			OK = OK + 1
		end
		if self:isFriend(p) and self.player:getHp() == 1 and p:getMaxHp() - p:getHp() >= 1 then
			OK = OK + 1
		end
		if self:isEnemy(p) and p:getMark("@waked") > 0 and p:getHp() > 2 then
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
		if enemy:getMark("@waked") > 0 and enemy:getHp() > 2 and targets:length() < 2 then
			targets:append(enemy)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if (friend:getMaxHp() - friend:getHp() >= 2 or (self.player:getHp() == 1 and friend:getMaxHp() - friend:getHp() >= 1)) and targets:length() < 2 then
			targets:append(friend)
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
	local dying_data = data:toDying()
	local source = dying_data.who
	if self:isEnemy(source) then return true end
	return false
end

sgs.ai_skill_discard.SE_Shouzang           = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	local victim = tag(self,"SE_Shouzang_target"):toPlayer()
	if not victim or not self:isEnemy(victim) then return {} end
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		if #to_discard < victim:getMaxHp() then
			table.insert(to_discard, card:getKnownEffectiveId())
		else
			break
		end
	end
	if #to_discard > 0 and (#to_discard == victim:getMaxHp()) then
		return to_discard
	end
	return {}
end


sgs.ai_skill_invoke.SE_Xiangren = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	if self:isFriend(source) then return true end
	return false
end


local se_jiejie_skill = {}
se_jiejie_skill.name = "se_jiejie"
table.insert(package_skills, se_jiejie_skill)
se_jiejie_skill.getTurnUseCard=function(self,inclusive,request)
	local source = self.player
	if source:getMark("@MagicEquip") == 0 then return end
	local target = 0
	for _, friend in ipairs(self.friends) do
		if friend:getMark("@Kekkai") == 0 then
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
		if friend:getMark("@Kekkai") == 0 then
			local hp = friend:getHp()
			if self:hasSkills(sgs.masochism_skill, friend) then
				hp = hp + 1
			end
			if friend:isLord() then
				hp = hp - 1
			end
			if hp < minHp then
				minHp = hp
				target = friend
			end
		end
	end
	if self.player:getHp() < 3 and self.player:getMark("@Kekkai") == 0 then
		target = self.player
	end
	if target then
		use.card=final_parse(self,request,"#se_jiejiecard:.:")
		if use.to then use.to:append(target) end
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
	if self.player:getStrategyHasUsed("#se_jianguicard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#se_jianguicard:.:")
end

sgs.ai_skill_use_func["#se_jianguicard"] = function(card,use,self,request)
	local targets = AIList.new({})
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
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
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
end

sgs.ai_skill_invoke.SE_Wufan             = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getMark("@Efreet") >= 4 then return true end
	local total_enemy_num, average_enemy_hp, least_enemy_hp = checkEnemyDetailed(self, data)
	local total_friend_num, average_friend_hp, least_friend_hp = checkFriendDetailed(self, data)
	local hp = self.player:getHp()
	if self.player:getMark("@Efreet") == 3 then
		if hp < 3 then return true end
		if least_enemy_hp == 1 then return true end
		if total_friend_num < total_enemy_num or average_enemy_hp >= average_friend_hp then return true end
		if total_friend_num == total_enemy_num and average_enemy_hp >= average_friend_hp + 1 then return true end
		if total_friend_num > total_enemy_num then return true end
	elseif self.player:getMark("@Efreet") == 2 then
		if total_friend_num + 1 < total_enemy_num or average_enemy_hp > average_friend_hp + 1 then return true end
		if least_enemy_hp == 1 then return true end
		if hp < 2 then return true end
		if total_friend_num <= 2 then return true end
	elseif self.player:getMark("@Efreet") == 1 then
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
		average_enemy_hp = average_enemy_hp + enemy:getHp()
		if enemy:getHp() < least_enemy_hp then
			least_enemy_hp = enemy:getHp()
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
		average_friend_hp = average_friend_hp + friend:getHp()
		if friend:getHp() < least_friend_hp then
			least_friend_hp = friend:getHp()
		end
	end
	average_friend_hp = average_friend_hp / total_friend_num
	return total_friend_num, average_friend_hp, least_friend_hp
end



sgs.ai_skill_invoke.SE_Shuangqiang = function(self, data)
	local source = data:toPlayer()
	if self:isEnemy(source) then
		return true
	end
	return false
end

sgs.ai_ajustdamage_from.SE_Shuangqiang = function(self,from,to,card,nature)
	if from:getEquips():length()>0 and not self:beFriend(to, from) and nature == "N"
	then return 1 end
end


sgs.ai_skill_invoke.SE_Xinlai = function(self, data)
	local source = data:toPlayer()
	if self:isFriend(source) then
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
		if self:isFriend(player) and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
			and not (player:hasSkill("kongcheng") and player:isKongcheng() and drawnum <= 2) and player:getMark("@Baskervilles") == 1 then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return nil end

	self:sortInPlace(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	self:sortInPlace(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.SE_Xinlai = -50

sgs.need_equip_skill = sgs.need_equip_skill .. "|SE_Shuangqiang"


sgs.ai_skill_invoke.moesenskill = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end


sgs.hit_skill = sgs.hit_skill .. "|SE_Juji_Reki"
ai_audited_aliases.register{id="ai_cardneed.SE_Juji_Reki",registry="ai_cardneed",path={"SE_Juji_Reki"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_canliegong_skill.SE_Juji_Reki = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and not to:inMyAttackRange(from)
end

ai_audited_aliases.register{id="ai_cardneed.SE_Zhiyuan",registry="ai_cardneed",path={"SE_Zhiyuan"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_skill_invoke.SE_Zhiyuan = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["SE_Zhiyuan"] = function(self, targets)
	local players = AIList.new(targets)
	local friends = {}
	for _, player in ipairs(players) do
		if self:isFriend(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return nil end

	self:sortInPlace(friends, "handcard")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	self:sortInPlace(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:willSkipPlayPhase(friend) then
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
		if self:isEnemy(ap) and ap:getMark("@Belphegor") == 0 then
			if self:hasSkills(sgs.masochism_skill, ap) then return ap end
			if ap:getHp() < min_hp then
				min_hp = ap:getHp()
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
		if self:isEnemy(ap) then
			if ap:getEquips():length() > equip_max and not ap:hasSkills(sgs.lose_equip_skill) then
				equip_max = ap:getEquips():length()
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
		if self:isEnemy(ap) and ap:getMark("@Belphegor") == 0 then
			if not self:hasSkills(sgs.masochism_skill, ap) and self:isGoodTarget(ap, self.enemies, nil) and self:damageIsEffective(ap, sgs.DamageStruct_Normal) then
				if ap:getHp() < min_hp then
					min_hp = ap:getHp()
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
		if self:isEnemy(ap) then
			if ap:getMark("@Satan") == 0 and ap:getMark("@Lucifer") == 0 then
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
		if self:isFriend(ap) then
			if ap:getHandcardNum() > least_num then
				least_num = ap:getHandcardNum()
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
		if self:isFriend(ap) then
			if ap:getHp() < least_hp then
				least_hp = ap:getHp()
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
	for _, p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and p:getMaxHp() >= 1 then
			if self:isFriend(p) then return true end
		end
	end
	return false
end

sgs.ai_skill_choice["SE_Fanhun_choose"] = function(self, choices, data)
	for _, p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and p:getMaxHp() >= 1 then
			if self:isFriend(p) then return p:getKnownGeneralName() end
		end
	end
	local choice_table = choices:split("+")
	return choice_table[1]
end

sgs.ai_skill_choice.SE_Fanhun = function(self, data)
	if self.player:getMark("@Mahou_ai") > 0 then
		return true
	end
	return false
end


sgs.ai_target_revises.SE_Jiepi = function(to, card, self)
	return card:isNDTrick() and self.player:getHandcardNum() < to:getHandcardNum()
end

local se_zhanjing_skill = {}
se_zhanjing_skill.name = "se_zhanjing"
table.insert(package_skills, se_zhanjing_skill)
se_zhanjing_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#se_zhanjingcard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#se_zhanjingcard:.:")
end

sgs.ai_skill_use_func["#se_zhanjingcard"] = function(card,use,self,request)
	local target
	self:sortInPlace(self.enemies, "defense")
	for _, p in ipairs(self.enemies) do
		if p:getHandcardNum() > 3 then
			if not ((p:getHp() < self.player:getHp()) and p:getMaxHp() < self.player:getMaxHp() and not self:damageIsEffective(p, nil, self.player)) then
				target = p
				break
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if p:getMaxHp() > self.player:getMaxHp() then
			if not ((p:getHp() < self.player:getHp()) and p:getMaxHp() < self.player:getMaxHp() and not self:damageIsEffective(p, nil, self.player)) then
				target = p
				break
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if p:getHandcardNum() > 6 then
			if not ((p:getHp() < self.player:getHp()) and p:getMaxHp() < self.player:getMaxHp() and not self:damageIsEffective(p, nil, self.player)) then
				target = p
				break
			end
		end
	end
	if not target then target = self.enemies[1] end
	use.card = card
	if use.to then use.to:append(target) end
	return
end

sgs.ai_use_value["se_zhanjingcard"]       = 8
sgs.ai_use_priority["se_zhanjingcard"]    = 8
sgs.ai_card_intention["se_zhanjingcard"]  = 80




sgs.ai_skill_cardask["@SE_Guanli"] = function(self, data)
	local PlayerNow = data:toPlayer()
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards)
	if self:isEnemy(PlayerNow) then
		self:setStrategyMemory("dongmanbao.SE_Guanli_reason", "enemy_discard")
		if PlayerNow:getHandcardNum() - PlayerNow:getMaxCards() > 1 then
			if self.player:getHandcardNum() > 3 then
				for _, card in ipairs(cards) do
					return card:getKnownEffectiveId()
				end
			end
		elseif PlayerNow:getHandcardNum() - PlayerNow:getMaxCards() > 2 then
			if self.player:getHandcardNum() > 2 then
				for _, card in ipairs(cards) do
					return card:getKnownEffectiveId()
				end
			end
		elseif PlayerNow:getHandcardNum() - PlayerNow:getMaxCards() > 4 then
			if self.player:getHandcardNum() > 0 then
				for _, card in ipairs(cards) do
					return card:getKnownEffectiveId()
				end
			end
			if self.player:getEquips():length() > 0 then
				for _, card in ipairs(cards) do
					return card:getKnownEffectiveId()
				end
			end
		end
		if self.room:getAllPlayers(true):length() == 2 then
			for _, card in ipairs(cards) do
				return card:getKnownEffectiveId()
			end
		end
	elseif self:isFriend(PlayerNow) then
		if self.player:getHandcardNum() > 0 then
			if self:hasSkills("se_chouyuan|se_shunshan|se_kanhu|se_shengjian|se_jianyu|se_huanyuan|se_zhanjing|LuaGonglue|LuaBoxue|", PlayerNow) then
				self:setStrategyMemory("dongmanbao.SE_Guanli_reason", "friend_play")
				for _, card in ipairs(cards) do
					return card:getKnownEffectiveId()
				end
			end
			if self:hasSkills("SE_Guanli|SE_Weigong|SE_Zhufu|LuaLuowang", PlayerNow) then
				self:setStrategyMemory("dongmanbao.SE_Guanli_reason", "friend_draw")
				for _, card in ipairs(cards) do
					return card:getKnownEffectiveId()
				end
			end
		end
		if self.player:getHandcardNum() > 3 then
			self:setStrategyMemory("dongmanbao.SE_Guanli_reason", "friend_draw")
			for _, card in ipairs(cards) do
				return card:getKnownEffectiveId()
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
	local current = self.room:getCurrent()
	if choice == "Gl_discard" then
		self:updateIntention(player, current, 60)
	else
		self:updateIntention(player, current, -60)
	end
end

local se_poyi_skill = {}
se_poyi_skill.name = "se_poyi"
table.insert(package_skills, se_poyi_skill)
se_poyi_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#se_poyicard") then return end
	local AIList = AIList.new({})
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ai_present(self,p) and self:isEnemy(p) then
			AIList:append(p)
		end
	end
	if AIList:length() < 1 then return end
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
	local room = self.player:getRoom()
	for _, p in sgs.qlist(targets) do
		if ai_present(self,p) and self:isEnemy(p) and p:getHp() > maxHp then
			target = p
			maxHp = p:getHp()
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
	local room = self.player:getRoom()
	for _, p in sgs.qlist(targets) do
		if ai_present(self,p) and self:isEnemy(p) and p:getHp() > maxHp then
			target = p
			maxHp = p:getHp()
		end
	end
	if not target then
		for _, p in sgs.qlist(targets) do
			if self:isEnemy(p) then
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
 local legacy=ai_unsupported("public poyi history is not projected","dongmanbao_poyi_history")
 local poyi1=resolve(self,legacy.first);local poyi2=resolve(self,legacy.second)
	if poyi1 then
		self:updateIntention(poyi1, from, -50)
		if poyi2 then
			self:updateIntention(poyi2, poyi1, 200)
			self:updateIntention(poyi1, poyi2, 200)
			poyi2=nil
		end
		poyi1=nil
	end
end


sgs.ai_skill_choice["SE_Yirong"]      = function(self, choices, data)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local choice_table = choices:split("+")
	return choice_table[math.random(1,#choice_table)]
end


local se_youhuo_skill = {}
se_youhuo_skill.name = "se_youhuo"
table.insert(package_skills, se_youhuo_skill)
se_youhuo_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#se_youhuocard") then return end
	if self.player:isKongcheng() then return end
	local target
	for _, p in ipairs(self.enemies) do
		if p:getHandcardNum() > 0 then target = p end
	end
	if not target then return end
	return parse(self,request,"#se_youhuocard:.:")
end
sgs.ai_skill_use_func["#se_youhuocard"]        = function(card,use,self,request)
	local target
	local cards = AIList.new(self.player:getHandcards())
		self:sortByKeepValueInPlace(cards)
	local card
	for _, p in ipairs(self.enemies) do
		if self:doDisCard(p, "he", true) then target = p end
	end
	for _, c in ipairs(cards) do
		card = c
		break
	end
	if not target then return end
	if card and target then
		use.card=final_parse(self,request,"#se_youhuocard:" .. card:getKnownEffectiveId() .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_youhuocard"]              = 8
sgs.ai_use_priority["se_youhuocard"]           = 5
sgs.ai_card_intention["se_youhuocard"]         = 80

sgs.ai_skill_choice["Youhuo"]                  = function(self, choices, data)
	local num = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("@Baskervilles") == 1 and self:isEnemy(p) then
			num = num + 1
		end
	end
	local Riko = self.room:findPlayerBySkillName("se_youhuo")
	if num >= 2 then
		if self.player:getHp() > 2 and Riko:getHp() == 3 then return "se_youhuo_Recovery" end
	end
	return "se_youhuo_Obtain"
end

sgs.ai_skill_choice["Youhuo_Obtain"]           = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return string.format("Allow to obtain card:" .. target:getKnownGeneralName())
	end
	return "Youhuo_Obtain_Not"
end

sgs.ai_skill_playerchosen["se_youhuocard"]     = function(self, targets)
	self:updatePlayers()
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and not hasManjuanEffect(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and hasManjuanEffect(target) then
			return target
		end
	end
	if table.contains(targets, self.player) or #targets == 0 then return self.player end
	return nil
end

sgs.ai_playerchosen_intention["se_youhuocard"] = function(self, from, to)
	self:updateIntention(from, to, -50)
end



sgs.ai_skill_invoke.SE_Qidan = function(self, data)
	if #self.enemies > 0 then return true end
	return false
end

sgs.ai_skill_invoke.SE_Shidan = function(self, data)
	for _, p in ipairs(self.enemies) do
		if p:faceUp() then return true end
	end
	return false
end

local function getMinHpEnemy(self)
	local min_hp = 100
	local target
	for _, p in ipairs(self.enemies) do
		if p:getHp() < min_hp then
			target = p
		end
	end
	if target then return target end
	return self.enemies[1]
end

sgs.ai_playerchosen_intention.SE_Qidan = function(self, from, to)
	local intention = 80
	if not self:toTurnOver(to, 0, "SE_Qidan") then intention = -intention end
	self:updateIntention(from, to, intention)
end
sgs.ai_skill_playerchosen.SE_Qidan = function(self, targets)
	local target = nil
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, 0, "SE_Qidan") then
				target = friend
				break
			end
		end
	end
	if not target then
		self:sortInPlace(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if self:toTurnOver(enemy, 0, "SE_Qidan") then
				target = enemy
				break
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, 0, "SE_Qidan") and self:hasSkills(sgs.priority_skill, enemy) then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, 0, "SE_Qidan") then
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
		if p:getMark("@Qidan_attacked") > 0 and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) and self:isGoodTarget(p, self.enemies, nil) then
			return
				p
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = self:cloneEvaluationCard("fire_slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then
			return enemy
		end
	end
	
	return nil
end

sgs.ai_skill_invoke.SE_Badan = function(self, data)
	if self.player:getMark("@Eight") == 0 then return false end
	if self.player:getHp() <= 1 then return true end
end

sgs.ai_skill_choice["SE_Badan"] = function(self, data)
	return "SE_Badan_Odd"
end



sgs.ai_can_damagehp.SE_Rennai = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to) and self.player:getMark("@Patience") == 0
end

sgs.ai_ajustdamage_to.SE_Rennai = function(self, from, to, card, nature)
	if to:getMark("@Patience") > 0 then
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
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		local dist = source:distanceTo(p)
		if dist <= source:getMaxHp() - source:getHp() + 1 then
			if self:isFriend(p) then
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
		if p:isAlive() and p:objectName() ~= self.player:objectName() then
			local point = 0
			if p:hasSkill("se_erdao") then point = point + 20 end
			if p:hasSkill("Zhena") then point = point + 10 end
			if p:hasSkill("se_xunyu") then point = point + 30 end
			if p:hasSkill("LuaCangshan") then point = point + 9 end
			if p:hasSkill("LuaSaoshe") then point = point + 30 end
			if p:getHp() > 2 then point = point + 3 end
			if p:getHp() <= 1 then point = point - 10 end
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
	local damage = data:toDamage()
	if self:isFriend(damage.from) and self.player:getPile("Fragments"):length() > 4 then return false end
	return true
end
sgs.ai_can_damagehp.SE_Wumai = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getCardCount() > 0
	end
end


local se_mipa_skill = {}
se_mipa_skill.name = "se_mipa"
table.insert(package_skills, se_mipa_skill)
se_mipa_skill.getTurnUseCard=function(self,inclusive,request)
	local Fr = self.player:getPile("Fragments"):length()
	if Fr == 0 then return end
	local tf = 0
	if Fr == 1 then
		for _, p in ipairs(self.enemies) do
			if p:getMark("@mipa_basic") > 0 or p:getMark("@mipa_notbasic") > 0 then tf = tf - 5 end
			if p:getHp() <= 1 then tf = tf + 10 end
			if p:getHandcardNum() > 5 then tf = tf + 1 end
			if p:getWeapon() and p:getWeapon():isKindOf("Crossbow") and p:getHandcardNum() > 3 then tf = tf + 11 end
		end
	elseif Fr == 2 then
		for _, p in ipairs(self.enemies) do
			if p:getMark("@mipa_basic") > 0 or p:getMark("@mipa_notbasic") > 0 then tf = tf - 1 end
			if p:getHp() <= 1 then tf = tf + 11 end
			if p:getHandcardNum() > 3 then tf = tf + 1 end
			if p:getHandcardNum() > 6 then tf = tf + 4 end
			if p:getHandcardNum() > 8 then tf = tf + 10 end
			if p:getWeapon() and p:getWeapon():isKindOf("Crossbow") and p:getHandcardNum() > 3 then tf = tf + 11 end
		end
	elseif Fr >= 3 then
		for _, p in ipairs(self.enemies) do
			if p:getHp() <= 1 then tf = tf + 11 end
			if p:getHandcardNum() > 3 then tf = tf + 4 end
			if p:getHandcardNum() > 6 then tf = tf + 5 end
			if p:getHandcardNum() > 8 then tf = tf + 11 end
			if self:hasSkills("SE_Juji|SE_Juji_Reki|se_chouyuan|LuaTianmo|LuaBimie|LuaPoshi|LuaGungnir|LuaSaoshe", p) and p:getHandcardNum() > 1 then
				tf =
					tf + 11
			end
			if p:getWeapon() and p:getWeapon():isKindOf("Crossbow") and p:getHandcardNum() > 3 then tf = tf + 11 end
		end
	end
	if #self.enemies == 1 then tf = 100 end
	if tf > 10 then return parse(self,request,"#se_mipacard:.:") end
	return
end
sgs.ai_skill_use_func["#se_mipacard"] = function(card,use,self,request)
	local target
	local Fr = self.player:getPile("Fragments"):length()
	for _, p in ipairs(self.enemies) do
		if p:getWeapon() and p:getWeapon():isKindOf("Crossbow") and p:getHandcardNum() > 3 and (p:getMark("@mipa_basic") == 0 or p:getMark("@mipa_notbasic") == 0) then
			target = p
			break
		end
	end
	if not target then
		if Fr >= 2 then
			for _, p in ipairs(self.enemies) do
				if self:hasSkills("SE_Juji|SE_Juji_Reki|se_chouyuan|LuaTianmo|LuaBimie|LuaPoshi|LuaGungnir|LuaSaoshe", p) and p:getHandcardNum() > 1 and (p:getMark("@mipa_basic") == 0 or p:getMark("@mipa_notbasic") == 0) then
					target = p
					break
				end
			end
		end
		if not target then
			local ma = 0
			for _, p in ipairs(self.enemies) do
				if p:getHandcardNum() > ma and (p:getMark("@mipa_basic") == 0 or p:getMark("@mipa_notbasic") == 0) then
					ma = p:getHandcardNum()
					target = p
				end
			end
		end
	end
	local cardsq
	if target then
		for _, id in sgs.qlist(self.player:getPile("Fragments")) do
			local card = disclosed(self,id)
			if (target:getMark("@mipa_basic") == 0) or (target:getMark("@mipa_notbasic") == 0) then
				cardsq = card
			end
		end
	end
	if cardsq and target and (target:getMark("@mipa_basic") == 0 or target:getMark("@mipa_notbasic") == 0) then
		local card_str = string.format("#se_mipacard:%s:", cardsq:getKnownEffectiveId())
		local acard = parse(self,request,card_str)
		use.card = acard
		if use.to then use.to:append(target) end
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
	self:updatePlayers()
	local patterns = generateAllCardObjectNameTablePatterns(self)
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = self:cloneEvaluationCard(name)
		if poi:isAvailable(self.player) then
			table.insert(choices, name)
		end
	end
	if self.player:isNude() and self:isWeak() then return end
	if self:getRoleEstimate(self.player) == "neutral" then return end
	if role_count(self,"rebel") == 0 then return end
	if chenyan_mark(self,"AI_do_not_invoke_se_chenyan-Clear") > 0 then return end

	if next(choices) and self.player:getMark("se_chenyan-Clear") == 0 then
		return parse(self,request,"#se_chenyan:.:")
	end
end

sgs.ai_skill_use_func["#se_chenyan"] = function(card,use,self,request)
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByUseValueInPlace(handcards, true)
	local useable_cards = {}
	if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
		table.insert(useable_cards, self.player:getArmor())
	end
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
		then
			table.insert(useable_cards, c)
		end
	end
	
	local card_str = "#se_chenyan:.:"
	local acard = parse(self,request,card_str)
	if #useable_cards >= 2 then
		if useable_cards[1]:hasFlag("xiahui") then return end
		
		set_tag(self,"ai_se_chenyan_card_id",useable_cards[1]:getEffectiveId())
		set_tag(self,"ai_se_chenyan_card_id2",useable_cards[2]:getEffectiveId())
		acard=final_parse(self,request,"#se_chenyan:"..useable_cards[1]:getEffectiveId().."+"..useable_cards[2]:getEffectiveId()..":")
		use.card = acard
		chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear","set",0)
	else
		chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear","set",1)
		if not self:isWeak() then
			use.card = acard
		end
	end
	
end

sgs.ai_use_priority["se_chenyan"] = 3
sgs.ai_use_value["se_chenyan"] = 3

sgs.ai_skill_choice["se_chenyan"] = function(self, choices, data)
	self:updatePlayers()
	local ai_se_chenyan_card_id
	local ai_se_chenyan_card_id2
	if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
		ai_se_chenyan_card_id = tag(self,"ai_se_chenyan_card_id"):toInt()
		remove_tag(self,"ai_se_chenyan_card_id")
		ai_se_chenyan_card_id2 = tag(self,"ai_se_chenyan_card_id2"):toInt()
		remove_tag(self,"ai_se_chenyan_card_id2")
	end
	local se_chenyan_vs_card = {}
	local items = choices:split("+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = owner_clone(self,"se_chenyan",card_name,sgs.Card_SuitToBeDecided,-1)
			
			if not table.contains(se_chenyan_vs_card, use_card) then
				table.insert(se_chenyan_vs_card, use_card)
			end
		end
	end
	self:sortByUsePriorityInPlace(se_chenyan_vs_card)
	for _, c in ipairs(se_chenyan_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:targetFixed() then
				if c:isKindOf("Peach") and self.player:isWounded() and self.player:getHp() <= 2 and chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
					return c:objectName()
				end
				if c:isKindOf("ExNihilo") and self.player:getHandcardNum() <= 2 and self:getOverflow() > 0 then
					return c:objectName()
				end
				if c:isKindOf("SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if c:isKindOf("ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
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
						return c:objectName()
					end
				end
				if c:isKindOf("GodSalvation") then
					if self:willUseGodSalvation(c) then
						return c:objectName()
					end
				end
				
			else
				if c:isKindOf("NatureSlash") and self:getCardsNum("NatureSlash") == 0 then
					if c:isKindOf("FireSlash") or c:isKindOf("ThunderSlash") then
						local dummy_use = self:aiUseCard(c, dummy())
						if not dummy_use.to:isEmpty() then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:isChained() then
									set_tag(self,"ai_se_chenyan_card_name",c:objectName())
									if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
										set_tag(self,"ai_se_chenyan_card_id2",ai_se_chenyan_card_id2)
										set_tag(self,"ai_se_chenyan_card_id",ai_se_chenyan_card_id)
									end
									return c:objectName()
								end
							end
						end
					end
				end
				
				if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
					local dummy_use = self:aiUseCard(c, dummy())
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
								set_tag(self,"ai_se_chenyan_card_name",c:objectName())
								if chenyan_mark(self,"AI_do_not_invoke_se_chenyan_nocard-Clear") == 0 then
									set_tag(self,"ai_se_chenyan_card_id2",ai_se_chenyan_card_id2)
									set_tag(self,"ai_se_chenyan_card_id",ai_se_chenyan_card_id)
								end
								return c:objectName()
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
 local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
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
	local cards = player:getCards("he")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(disclosed(self,id))
	end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have or player:getMark("se_chenyan-Clear") ~= 0 then return end
	if class_name == "Peach" and player:getMark("Global_PreventPeach") > 0 then return end
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
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
		elseif not self:isWeak() then
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
	if self.player:getMark("@se_tongling") == 0 then return end
	return parse(self,request,"#se_tonglingcard:.:")
end
sgs.ai_skill_use_func["#se_tonglingcard"] = function(card,use,self,request)
	use.card = card
	return
end
sgs.ai_use_value["se_tonglingcard"] = 10
sgs.ai_use_priority["se_tonglingcard"] = 10


sgs.ai_skill_choice["se_tongling_kd"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1, #items)]
end

sgs.ai_skill_choice["se_tongling_d"] = function(self, choices, data)
	local items = choices:split("+")

	return items[math.random(1, #items)]
end


sgs.ai_skill_playerchosen["se_tongling_k"] = function(self, targets)
	
	self:sortInPlace(self.enemies, "defense")
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
	local items = choices:split("+")
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) and table.contains(items, "1_Zuozhan") then
		return "1_Zuozhan"
	else
		if p:getHandcardNum() <= p:getHp() and table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		elseif table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		end
	end
	return items[1]
end

sgs.ai_skill_choice["SE_Zuozhan2"] = function(self, choices, data)
	local items = choices:split("+")
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 and table.contains(items, "3_Zuozhan") then
			return "3_Zuozhan"
		elseif table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		end
	else
		if p:getHandcardNum() <= p:getHp() and table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		end
	end
	return items[1]
end

sgs.ai_skill_choice["SE_Zuozhan3"] = function(self, choices, data)
	local items = choices:split("+")
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 and table.contains(items, "2_Zuozhan") then
			return "2_Zuozhan"
		elseif table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		end
	else
		if p:getHandcardNum() <= p:getHp() and table.contains(items, "3_Zuozhan") then
			return "3_Zuozhan"
		elseif table.contains(items, "4_Zuozhan") then
			return "4_Zuozhan"
		end
	end
	return items[1]
end

sgs.ai_skill_choice["SE_Zuozhan4"] = function(self, choices, data)
	local items = choices:split("+")
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 and table.contains(items, "4_Zuozhan") then
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
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and (math.ceil(self.player:getHandcardNum() / 2) * 2 == self.player:getHandcardNum())
	then
		return string.format("jink:SE_Gaoling[%s:%s]=.", sgs.Card_NoSuit, 0)
	elseif class_name == "Nullification"
		and self.request.reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and (math.ceil(self.player:getHandcardNum() / 2) * 2 == self.player:getHandcardNum())
	then
		return string.format("Nullification:SE_Gaoling[%s:%s]=.", sgs.Card_NoSuit, 0)
	end
end

sgs.ai_skill_invoke["SE_Shengmu"] = function(self, data)
	local da = data:toDamage()
	if self:isFriend(da.to) then return true end
	return false
end
sgs.ai_skill_cardask["@SE_Shengmu"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		if self:needToThrowArmor() then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		local cards = AIList.new(self.player:getCards("he"))
		self:sortByKeepValueInPlace(cards)
		for _, card in ipairs(cards) do
			if damage.to:getHandcardNum() < damage.to:getMaxHp() then
				if card:isRed() then
					return "$" .. card:getKnownEffectiveId()
				end
			end
		end
		for _, card in ipairs(cards) do
			return "$" .. card:getKnownEffectiveId()
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@SE_Shengmu"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage and damage.to and promptlist[#promptlist] ~= "" then
		self:updateIntention(player, damage.to, -80)
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|SE_Shengmu"


sgs.ai_skill_invoke["se_jianshi"] = function(self, data)
	return #self.enemies > 0
end


sgs.ai_skill_playerchosen["SE_JianshiTr"] = function(self, targets)
	for _, p in ipairs(self.friends) do
		if p:getMark("@Wuwei") > self.room:getAlivePlayers():length() and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) then
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
		if self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) and self:isGoodTarget(p, self.enemies, nil) then
			for i = 1, #GoodMark do
				if p:getMark(GoodMark[i]) > 0 then return p end
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) and self:isGoodTarget(p, self.enemies, nil) then
			target = p
		end
	end
	if target and self:damageIsEffective(target, sgs.DamageStruct_Thunder, self.player) then return target end
	for _, p in ipairs(self.enemies) do
		if self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) and not self:cantbeHurt(target) and self:canDamage(target, self.player, nil) then
			target = p
		end
	end
	if target and self:damageIsEffective(target, sgs.DamageStruct_Thunder, self.player) then return target end
	return nil
end

sgs.ai_playerchosen_intention["SE_JianshiTr"] = function(self, from, to)
	local intention = 60
	if to:getMark("@Wuwei") > 0 then
		intention = -intention
	end
	self:updateIntention(from, to, intention)
end


local se_jianshi_skill = {}
se_jianshi_skill.name = "se_jianshi"
table.insert(package_skills, se_jianshi_skill)
se_jianshi_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.friends <= 1 then return end
	if self.player:getMark("@surveillance") <= 1 then return end
	for _, p in ipairs(self.friends) do
		if p:getMark("@surveillance") == 0 and p:getHp() > 1 then return parse(self,request,"#se_jianshicard:.:") end
	end
	return
end
sgs.ai_skill_use_func["#se_jianshicard"] = function(card,use,self,request)
	local target
	
	for _, p in ipairs(self.friends) do
		if p:getMark("@surveillance") == 0 and p:getHp() > 1 then target = p end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end
sgs.ai_use_value["se_jianshicard"] = 10
sgs.ai_use_priority["se_jianshicard"] = 6

sgs.ai_skill_invoke["SE_Heimu"] = true

sgs.ai_damage_reason_suppress_intention["SE_Guiyin"] = true


sgs.ai_skill_invoke["SE_Jiawu"] = function(self, data)
	if self.player:getPhase() == sgs.Player_Discard and self.player:getMark("jiawu_fin") > 4 then
		self.player:setMark("jiawu_fin", 0)
		return false
	end
	if self.player:getPhase() == sgs.Player_Discard then
		self.player:setMark("jiawu_fin", self.player:getMark("jiawu_fin") + 1)
	end
	return true
end

sgs.ai_skill_choice["SE_Jiawu"] = function(self, data)
	if self.player:hasFlag("SE_Jiawu_EquipCard") then
		if not self.player:getWeapon() then return "SE_Jiawu_use" end
		return "SE_Jiawu_give"
	else
		if self.player:getHp() <= 2 and self.player:isWounded() then return "SE_Jiawu_use" end
	end
	return "SE_Jiawu_give"
end

sgs.ai_skill_invoke["SE_Zhandan"] = function(self, data)
	local dam = data:toDamage()
	if dam.to and self:isFriend(dam.to) then return true end
	return false
end

sgs.ai_skill_cardask["@SE_Zhandanspade"] = function(self,data,pattern,target)
	local cards = AIList.new(self.player:getCards("eh"))
	self:sortByKeepValueInPlace(cards)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then return "$" .. card:getKnownEffectiveId() end
	end
	return "."
end
sgs.ai_skill_cardask["@SE_Zhandandiamond"] = function(self,data,pattern,target)
	local cards = AIList.new(self.player:getCards("eh"))
	self:sortByKeepValueInPlace(cards)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond then return "$" .. card:getKnownEffectiveId() end
	end
	return "."
end
sgs.ai_skill_cardask["@SE_Zhandanclub"] = function(self,data,pattern,target)
	local cards = AIList.new(self.player:getCards("eh"))
	self:sortByKeepValueInPlace(cards)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Club then return "$" .. card:getKnownEffectiveId() end
	end
	return "."
end
sgs.ai_skill_cardask["@SE_Zhandanheart"] = function(self,data,pattern,target)
	local cards = AIList.new(self.player:getCards("eh"))
	self:sortByKeepValueInPlace(cards)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart then return "$" .. card:getKnownEffectiveId() end
	end
	return "."
end


sgs.ai_skill_discard["SE_Lingshang"] = function(self, discard_num, min_num, optional, include_equip)
	local handcards = AIList.new(self.player:getCards("he"))
	if self:isWeak() and self.room:getDrawPile():length() < self.room:getDiscardPile():length() then return {} end
	self:sortByKeepValueInPlace(handcards)
	local name = tag(self,"SE_Lingshang_type"):toString()
	local to_discard = {}
	for _, c in ipairs(handcards) do
		if #to_discard < discard_num then
			if ((name == "BasicCard" and c:isKindOf("BasicCard") and not c:isKindOf("Peach")) or (name == "TrickCard" and c:isKindOf("TrickCard")) or (name == "EquipCard" and c:isKindOf("EquipCard"))) then
				table.insert(to_discard, c:getKnownEffectiveId())
			end
		end
	end
	if #to_discard == discard_num then
		return to_discard
	end
	return {}
end

sgs.ai_skill_invoke["SE_Lingshang"] = function(self, data)
	local cardType = data:toString()
	local peaches = self:getCardsNum("Peach")
	if cardType == "BasicCard" then
		if self:isWeak(self.player) then return false end
		if peaches > 0 and self.player:hasSkill("SE_Guiling") then return false end
	end
	return true
end

sgs.ai_skill_choice["SE_Lingshang_type"] = function(self, data)
	for _, p in ipairs(self.friends) do
		if self:isWeak(p) then return "BasicCard" end
	end
	return "TrickCard"
end

sgs.ai_skill_choice["SE_Lingshang"] = function(self, choices, data) 
	local choice_table = choices:split("+")
	if self.player:getPhase() == sgs.Player_Play and #self.enemies > 0 then
		if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") then
			if not self.player:getOffensiveHorse() and self.player:getHandcardNum() > self.player:getHp() + 1 then
				if table.contains(choice_table, "ChiTu") then return "ChiTu" end
				if table.contains(choice_table, "DaYuan") then return "DaYuan" end
				if table.contains(choice_table, "ZiXing") then return "ZiXing" end
			end
			if self.player:getHandcardNum() > self.player:getHp() then
				if table.contains(choices, "slash") then return "slash" end
			end
		end
	end
	for _, p in ipairs(self.friends) do
		if self:isWeak(p) then
			if table.contains(choice_table, "peach") then return "peach" end
		end
		if self:isWeak(p) and p:objectName() == self.player:objectName() then
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
	local use = data:toCardUse()
	if use.to:length() > 1 then return true end
	local target = use.to:at(0)
	if self:isFriend(target) then return false end
	if self:cantDamageMore(self.player, target) then return false end
	if not self:slashIsEffective(data:toCardUse().card, target)then return false end
	local player = use.from
	if player:getMark("@Wuwei") > self.room:getAllPlayers(true):length() and player:getMark("@Wuwei") > 4 then return true end
	if target:isKongcheng() or self:canLiegong(target, player) then return true end
	if self:getCardsNum("Slash") > 1 and target:getHandcardNum() > 2 and player:getMark("@Wuwei") <= 2 then return false end
	if player:getMark("@Wuwei") < 3 and self:getCardsNum("Slash") > 1 then return true end
	if self:isWeak(target) and math.random(1, 2) == 1 then return true end
	if target:getHandcardNum() == 1 and math.random(1, 3) > 1 then return true end
	if getCardsNum("Jink", target, self.player) < 1 then return true end
	if target:getHandcardNum() > 3 then return false end
	return math.random(1, 5) == 1
end


sgs.ai_ajustdamage_from.SE_Wuwei = function(self, from, to, card, nature)
	if (card and card:isKindOf("Slash")) and (card:hasFlag("wuwei_used") or not self:beFriend(to, from))
	then
		return 1
	end
end

sgs.ai_use_revises.SE_Wuwei = function(self, card, use)
	if card:isKindOf("Slash") and self.player:getMark("@Wuwei") > 2
	then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end
sgs.ai_can_damagehp.SE_Wuwei = function(self, from, card, to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to) and to:getMark("@Wuwei") == 0
end

ai_audited_aliases.register{id="ai_cardneed.SE_Wuwei",registry="ai_cardneed",path={"SE_Wuwei"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_canliegong_skill.SE_Wuwei = function(self, from, to)
	return from:getMark("@Wuwei") > self.room:getAlivePlayers():length() and from:getMark("@Wuwei") > 4
end


sgs.ai_skill_invoke["SE_Tiansuo"] = function(self, data)
	local use = data:toCardUse()
	if self:isEnemy(use.to:at(0)) and self:isGoodChainTarget(use.to:at(0), use.card, use.from) then return true end
	return false
end

sgs.ai_use_revises.se_gate = function(self, card, use)
	if card:isKindOf("Weapon")
	then
		same = self:getSameEquip(card)
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
	if player:getWeapon() then hasWea = true end
	if not hasWea then
		if player:getPile("pika_gob"):length() > 0 then
			for _, p in ipairs(self.enemies) do
				if self:slashIsEffective(self:cloneEvaluationCard("slash"), p) or self:slashIsEffective(self:cloneEvaluationCard("fire_slash"), p) then
					hasWea = true
					break
				end
			end
		end
	end
	if not hasWea then
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isKindOf("Weapon") then
				hasWea = true
				break
			end
		end
	end
	if hasWea then
		for _, id in sgs.qlist(self.player:getPile("pika_gob")) do
			local card = disclosed(self,id)
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getKnownEffectiveId()
			return parse(self,request,"#se_gatecard:" .. card:getKnownId() .. ":")
		end
	end
end

sgs.ai_skill_use_func["#se_gatecard"] = function(card,use,self,request)
	local cards = AIList.new(self.player:getHandcards())
	local needed = {}
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Weapon") then
			table.insert(needed, acard:getKnownEffectiveId())
		end
	end
	if self.player:getWeapon() then
		table.insert(needed, self.player:getWeapon():getEffectiveId())
	end
	if needed and #needed > 0 then
		use.card=final_parse(self,request,"#se_gatecard:" .. table.concat(needed, "+") .. ":")
		return
	end

	for _, id in sgs.qlist(self.player:getPile("pika_gob")) do
		local card = disclosed(self,id)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getKnownEffectiveId()
		local target = nil
		local normal_slash = owner_clone(self,"se_gate","slash",card:getSuit(),card:getNumber())
		
		local thunder_slash = owner_clone(self,"se_gate","thunder_slash",card:getSuit(),card:getNumber())
		
		local fire_slash = owner_clone(self,"se_gate","fire_slash",card:getSuit(),card:getNumber())
		
		for _, enemy in ipairs(self.enemies) do
			if self:isGoodTarget(enemy, self.enemies, nil) then
				if self:slashIsEffective(thunder_slash, enemy, self.player) and self:isGoodChainTarget(enemy, thunder_slash, self.player) and self.player:canSlash(enemy, thunder_slash, false) then
					target = enemy
					self:setStrategyMemory("dongmanbao.GateNatural", "thunder_slash")
				elseif self:slashIsEffective(fire_slash, enemy, self.player) and self:isGoodChainTarget(enemy, fire_slash, self.player) and self.player:canSlash(enemy, fire_slash, false) then
					target = enemy
					self:setStrategyMemory("dongmanbao.GateNatural", "fire_slash")
				elseif self:slashIsEffective(normal_slash, enemy, self.player) and self.player:canSlash(enemy, normal_slash, false) then
					target = enemy
					self:setStrategyMemory("dongmanbao.GateNatural", "slash")
				end
			end
		end
		if not target then return end
		use.card=final_parse(self,request,"#se_gatecard:" .. card:getKnownId() .. ":")
		if use.to then use.to:append(target) end
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
	return to:isChained() and to:isKongcheng()
end

sgs.ai_skill_cardask["@SE_Tiansuo-discard"] = function(self, data, pattern)
	local use = data:toCardUse()
	if not self:slashIsEffective(use.card, self.player, use.from)
		or (not self:hasHeavyDamage(use.from, use.card, use.to:first())
			and (self:canAttack(self.player, use.from, true) or self:needToLoseHp(self.player, use.from, nil))) then
		return "."
	end
	if not self:hasHeavyDamage(use.from, use.card, use.to:first()) and self:getCardsNum("Peach") > 0 then return "." end
	if self:getCardsNum("Jink") == 0 or not sgs.isJinkAvailable(use.from, self.player, use.card, true) then return "." end
	if self:NeedDoubleJink(use.from, self.player) and self:getCardsNum("Jink") <= 1 then return "." end

	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		if not card:isKindOf("BasicCard") or (not self:isWeak() and (self:getKeepValue(card) > 8 or self:isValuableCard(card)))
			or (isCard("Jink", card, self.player) and self:getCardsNum("Jink") - 1 < (self:NeedDoubleJink(use.from, self.player) and 2 or 1)) then
			continue
		end
		return "$" .. card:getKnownEffectiveId()
	end
end


local se_origin_skill = {}
se_origin_skill.name = "se_origin"
table.insert(package_skills, se_origin_skill)
se_origin_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if (not self.player:isWounded()) and self.player:getMark("@origin_bullet") > 0 then return end
	if (not self.player:isLord() and self.player:getMaxHp() > 3) or self.player:getMaxHp() > 4 and self:getCardsNum("Slash") > 0 then
		return parse(self,request,"#se_origincard:.:")
	end
	local slash = self:cloneEvaluationCard("slash")
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() == 0 and self.player:inMyAttackRange(enemy) and self:slashIsEffective(slash, enemy) and self:getCardsNum("Slash") > 0 then
			if self.player:getMark("@origin_bullet") > 0 then return end
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
	local use = data:toCardUse()
	local target = use.to:at(0)
	if not self:isEnemy(target) then return "use_normal" end
	local slash = self:cloneEvaluationCard("slash")
	
	if target:getHandcardNum() == 0 and self:slashIsEffective(slash, target) then
		return
		"use_origin"
	end
	if getCardsNum("Jink", target, self.player) < 1 then return "use_origin" end
	if self:getCardsNum("Slash") > 0 and math.random(1, 15) == 1 then return "use_origin" end
	if self.player:hasFlag("slash_one") and math.random(1, 4) > 1 then return "use_origin" end
	if math.random(1, 10) == 1 then return "use_origin" end
	return "use_normal"
end
ai_audited_aliases.register{id="ai_cardneed.se_origin",registry="ai_cardneed",path={"se_origin"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|se_origin"

local se_bilingvs_skill = {}
se_bilingvs_skill.name                  = "se_bilingvs"
table.insert(package_skills, se_bilingvs_skill)
se_bilingvs_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getMark("@Biling_kiri") == 0 then return end
	if #self.enemies == 0 then return end
	if #self.enemies == 1 and #self.friends == 1 then return end
	for _, enemy in ipairs(self.enemies) do
		if second_general_present(self,enemy) then
			return parse(self,request,"#se_bilingvscard:.:")
		end
	end
	if #self.enemies == 1 or #self.friends == 1 then return end
	local slash = self:cloneEvaluationCard("slash")
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= 1 and self:slashIsEffective(slash, enemy) then
			return parse(self,request,"#se_bilingvscard:.:")
		end
	end
	if self.player:getHp() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() <= 2 and self:slashIsEffective(slash, enemy) then
				return parse(self,request,"#se_bilingvscard:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#se_bilingvscard"] = function(card,use,self,request)
	if self.player:getMark("@Biling_kiri") == 0 then return end
	if #self.enemies == 0 then return end
	local target
	for _, enemy in ipairs(self.enemies) do
		if second_general_present(self,enemy) then
			target = enemy
		end
	end
	if not target then
		if #self.enemies == 1 or #self.friends == 1 then return end
		local slash = self:cloneEvaluationCard("slash")
		
		for _, enemy in ipairs(self.enemies) do
			if self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
				target = enemy
			end
		end
	end

	if not target then
		if self.player:getHp() == 1 then
			local slash = self:cloneEvaluationCard("slash")
			
			for _, enemy in ipairs(self.enemies) do
				if self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
					target = enemy
				end
			end
		end
	end

	if not target then return end
	if use.to then use.to:append(target) end
	use.card=final_parse(self,request,"#se_bilingvscard:.:")
	return
end

sgs.ai_skill_playerchosen["se_biling"]    = function(self, targets)
	local target = tag(self,"se_bilingvs_target"):toPlayer()
	local slash = self:cloneEvaluationCard("slash")
			
	if viewer_role(self,self.player) == "rebel" then
		local lord = self.room:getLord()
		if targets:contains(lord) and self:slashIsEffective(slash, target, lord) then
			return
				lord
		end
	else
		for _, p in sgs.qlist(targets) do
			if self:isFriend(p) and self:hasSkills("SE_Juji|SE_Juji_Reki|LuaTianmo|LuaBimie|LuaGungnir|SE_Shuangqiang", p) and self:slashIsEffective(slash, target, p) then
				return
					p
			end
		end
		for _, p in sgs.qlist(targets) do
			if self:isFriend(p) and self:slashIsEffective(slash, target, p) then
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
	if to:getMark("@Biling_target") > 0 then
		return -99
	end
end

sgs.ai_skill_invoke["se_jianqiao"]        = function(self, data)
	local damage = data:toDamage()
	if viewer_role(self,self.player) == "loyalist" and self:isWeak(self.room:getLord()) then return false end
	if self:isFriend(damage.to) and (self:getCardsNum("Peach") == 0 or damage.damage > 1) and (self:damageIsEffective(damage.to, damage.nature, damage.from)) then return true end
	return false
end


local se_banyun_skill = {}
se_banyun_skill.name                      = "se_banyun"
table.insert(package_skills, se_banyun_skill)
se_banyun_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if self.player:getStrategyHasUsed("#se_banyuncard") then
		return
	end
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self:isGoodTarget(enemy, self.enemies, nil) then
			return parse(self,request,"#se_banyuncard:.:")
		end
	end
end

sgs.ai_skill_use_func["#se_banyuncard"] = function(card,use,self,request)
	if #self.enemies == 0 then return end
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self:isGoodTarget(enemy, self.enemies, nil) then
			target = enemy
		end
	end
	if target then
		use.card=final_parse(self,request,"#se_banyuncard:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_banyuncard"]       = 6
sgs.ai_use_priority["se_banyuncard"]    = 5

sgs.ai_skill_playerchosen["se_banyun"]  = function(self, targets)
	targets = AIList.new(targets)
	if role_count(self,"rebel") == 0 then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() then
			return lord
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return AssistTarget
	end

	self:sortInPlace(self.friends_noself, "chaofeng")
	for _, target in ipairs(self.friends_noself) do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			return target
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		return p
	end
end





function sgs.ai_slash_prohibit.se_shenglong(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if from:getHandcardNum() == 1 and from:getEquips():length() == 0 and from:getHandcards():at(0):isKindOf("Slash") and from:getHp() >= 2 then return false end
	return from:getHp() + from:getEquips():length() < 4 or from:getHp() < 2 or
		(from:getHandcardNum() > 3 and from:getHp() <= 3)
end

sgs.ai_can_damagehp.se_shenglong = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and not self:cantbeHurt(from) and self:canDamage(from, self.player, nil)
	end
end



sgs.ai_skill_invoke["se_shifeng"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) and not self:needToLoseHp(damage.to, damage.from) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke["se_shifeng"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, damage.to, -80)
		end
	end
end

sgs.ai_view_as.se_zhiyan = function(card, player, card_place)
	if player:getMark("@Yukino_shifeng") < math.floor(player:getRoom():getAlivePlayers():length() / 5) + 1 then return end
	if player:getMark("@yukino_zhiyan") < 1 then return end
	return ("nullification:se_zhiyan[%s:%s]=."):format(sgs.Card_NoSuit, 0)
end

sgs.ai_skill_invoke["se_wenchang"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke["se_wenchang"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, damage.to, -80)
		end
	end
end


function sgs.ai_cardneed.se_wenchang(to, card)
	return to:getCards("h"):length() <= 2
end

sgs.ai_skill_cardchosen["se_wenchang"] = function(self, who, flags)
	local card
	local cards = AIList.new(who:getEquips())
	local handcards = AIList.new(who:getHandcards())
	if self:isFriend(who) then
		if self:needToThrowArmor(who) then
			return who:getArmor()
		end
		if who:hasSkills(sgs.lose_equip_skill) or self:doDisCard(who, "he") then
			for _, card in ipairs(cards) do
				if card:isKindOf("Weapon") then
					if card:isKindOf("Crossbow") or card:isKindOf("Blade") then continue end
					if card:isKindOf("Axe") or card:isKindOf("GudingBlade") then continue end
				elseif card:isKindOf("Armor") then
					if not self:hasSkills("bazhen|yizhong|linglong") and self:isWeak(who) then
						continue
					end
				elseif card:isKindOf("DefensiveHorse") then
					if self:isWeak(who) then continue end
				end
				if card:isBlack() then continue end
				return card
			end
		end
		if not who:isKongcheng() then return handcards[1] end
		return cards[1]
	else
		if #handcards == 1 and handcards[1]:hasFlag("visible") then table.insert(cards, handcards[1]) end
		if not who:hasSkills(sgs.lose_equip_skill) then
			for _, card in ipairs(cards) do
				if card:isRed() then return card end
				if card:isKindOf("Weapon") then
					if card:isKindOf("Crossbow") or card:isKindOf("Blade") then return card end
					if card:isKindOf("Axe") or card:isKindOf("GudingBlade") then return card end
				elseif card:isKindOf("Armor") then
					if not self:hasSkills("bazhen|yizhong|linglong") and self:isWeak(who) then
						return card
					end
				elseif card:isKindOf("DefensiveHorse") then
					if self:isWeak(who) then return card end
				end
			end
			if #cards > 0 then return cards[1] end
		end
	end
	return nil
end

sgs.recover_hp_skill = sgs.recover_hp_skill.. "|se_wenchang"

sgs.ai_skill_invoke["se_yuanxin"] = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) and not damage.from:hasSkill("SE_Shuangqiang") then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke["se_yuanxin"] = function(self, player, promptlist)
	local damage = tag(self,"CurrentDamageStruct"):toDamage()
	if damage then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, damage.to, -80)
		end
	end
end
sgs.ai_skill_cardchosen["se_linmo"] = function(self, who, flags)
	local cards = who:getCards("he")
	self:sortByKeepValueInPlace(cards, true)
	return cards:first()
end

sgs.ai_skill_invoke["se_linmo"] = function(self, data)
	local use = data:toCardUse()
	if self:isWeak() and (use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic")) then return true end
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") and use.card:isKindOf("Slash") then return true end
	if not self:isWeak() and (use.card:isKindOf("Snatch") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("reijyuu")) then return true end
	return false
end

sgs.ai_view_as.se_linmo = function(card, player, card_place)
	if player:getPile("drawing"):length() == 0 then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()

	local tp

	if player_disclosed(player,player:getPile("copying"):at(0)):isKindOf("BasicCard") then tp = "BasicCard" end
	if player_disclosed(player,player:getPile("copying"):at(0)):isKindOf("TrickCard") then tp = "TrickCard" end
	if player_disclosed(player,player:getPile("copying"):at(0)):isKindOf("EquipCard") then tp = "EquipCard" end
	if not tp then return end
	if card:isKindOf(tp) then
		local name = player_disclosed(player,player:getPile("drawing"):at(0)):objectName()
		return (name .. ":se_linmo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local se_linmo_skill = {}
se_linmo_skill.name = "se_linmo"
table.insert(package_skills, se_linmo_skill)
se_linmo_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getPile("drawing"):length() == 0 then return end
	local usable_cards = AIList.new(self.player:getCards("h"))
	local equips = AIList.new(self.player:getCards("e"))
	for _, e in ipairs(equips) do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, disclosed(self,id))
		end
	end
	self:sortByUseValueInPlace(usable_cards, true)
	local cards = {}
	local tp

	if disclosed(self,self.player:getPile("copying"):at(0)):isKindOf("BasicCard") then tp = "BasicCard" end
	if disclosed(self,self.player:getPile("copying"):at(0)):isKindOf("TrickCard") then tp = "TrickCard" end
	if disclosed(self,self.player:getPile("copying"):at(0)):isKindOf("EquipCard") then tp = "EquipCard" end
	if not tp then return end
	for _, c in ipairs(usable_cards) do
		local cardex = owner_clone(self,"se_linmo",disclosed(self,self.player:getPile("drawing"):at(0)):objectName(),c:getSuit(),c:getNumber())
		if c:isKindOf(tp) and not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			local name = disclosed(self,self.player:getPile("drawing"):at(0)):objectName()
			return parse(self,request,(name .. ":se_linmo[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
				c:getKnownEffectiveId()))
		end
	end
end
sgs.ai_use_priority["se_linmo"] = 10
sgs.ai_use_value["se_linmo"] = 10



sgs.ai_skill_invoke["se_fupao"] = function(self, data)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) and not (self:needToLoseHp(p, self.player) or self:canAttack(p, self.player)) and self:slashIsEffective(self:cloneEvaluationCard("slash"), p, self.player) and self:isWeak(p) then
				return false
			end
			if self:isEnemy(p) and not self:isGoodTarget(p, self.enemies, nil) and self:canAttack(p, self.player) then
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
 if #costs~=1 or costs[1]~=card:getKnownEffectiveId()then ai_unsupported('view-as source material changed','dongmanbao.view_as')end
 return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards=costs}
end end

do local source=sgs.ai_view_as["se_zhiyan"];sgs.ai_view_as["se_zhiyan"]=function(card,player,...)
 local wire=source(card,player,...);if wire==nil then return end
 local name,skill,costs=normal_parts(wire)
 if #costs~=1 or costs[1]~=card:getKnownEffectiveId()then ai_unsupported('view-as source material changed','dongmanbao.view_as')end
 return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards=costs}
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
