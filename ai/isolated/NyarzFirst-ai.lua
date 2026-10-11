-- NyarzFirst fixed b6025acc. Readonly hypotheses are never payment receipts.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('NyarzFirst source input unknown',k)end;return v end
local function hydrate_context(self,value,kind)
 if value==nil then return nil end
 if kind=='Player' then
  if AIValue.isPlayer(value)then return value end
  return known(self.room:findPlayerByObjectName(value,true),'context.player:'..tostring(value))
 end
 if kind=='Card'then
  if AIValue.isCard(value)or AIValue.isConversion(value)then return value end
  return CardView.new(value,self.room)
 end
 if kind=='Bool'or kind=='String'or kind=='Int'then return value end
 if kind=='IntList'then return AIList.new(value)end
 local row={};for k,v in pairs(value)do row[k]=v end
 for _,k in ipairs{'from','who','m_who'}do if value[k]then row[k]=hydrate_context(self,value[k],'Player')end end
 for _,k in ipairs{'card','whocard','m_card','m_toCard'}do if value[k]then row[k]=hydrate_context(self,value[k],'Card')end end
 if kind=='CardUse'then row.to=AIList.new({});for _,v in ipairs(value.to or{})do row.to:append(hydrate_context(self,v,'Player'))end
 elseif value.to then row.to=hydrate_context(self,value.to,'Player')end
 if kind=='Dying'and value.damage then row.damage=hydrate_context(self,value.damage,'Damage')end
 if kind=='Judge'then
  function row:isGood(c)
   if c==nil then return self.good end
   if self.outcomes_complete~=true then return nil end
   local values=self.outcome_by_id;if type(values)=='table'then return values[tostring(c:getEffectiveId())]end
  end
  function row:isBad(c)local v=self:isGood(c);if type(v)=='boolean'then return not v end end
 end
 return row
end
local nullable={useCardByClassName=true,updatePlayers=true,getCard=true,getArmor=true,getWeapon=true,getTreasure=true,findPlayerBySkillName=true,toPlayer=true,useEquipCard=true,useTrickCard=true,useBasicCard=true,moveField=true,getCurrent=true,getLord=true,getMaxCard=true,setStrategyMemory=true,getStrategyMemory=true,updateIntention=true,setStrategyCardFlag=true}
local function q(o,k,...)
 if k=='hasFlag'and AIValue.isPlayer(o)then
  local ai=o._room and o._room._ai;local fs=ai and ai.world.strategy_facts
  local rows=fs and fs.NyarzFirst and fs.NyarzFirst.public_flags
  local values=rows and rows[(...)];local v=values and values[o:objectName()]
  local audited={['jitongxindraw']=true,['jitongxinda']=true,['spjinjintarget']=true,['hflanggutarget']=true,['drangjiejud']=true,['dwqingshidrawall']=true,['dwqingshiupcan']=true,['dmzhanmenggood']=true,['old_yifuta']=true,['shejifrom']=true,['shejito']=true,['xrxiaoruitarget']=true}
  if audited[(...)]then if type(v)~='boolean'then ai_unsupported('public flag disclosure missing',(...))end;return v end
 end
 if not o or type(o[k])~='function'then ai_unsupported('NyarzFirst helper unavailable',k)end
 local m=k;if k=='getMark'and AIValue.isPlayer(o)then m='getStrategyMark'end
 local r=table.pack(o[m](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,v in ipairs(r[1])do t[i]=v end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('NyarzFirst foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function source_type(c)for _,name in ipairs{"BasicCard","TrickCard","EquipCard"}do if q(c,"isKindOf",name)then return name end end end
local function facts(self)return known(self.world.strategy_facts and self.world.strategy_facts.NyarzFirst,'NyarzFirst')end
local function face(self,id)return q(self,'getKnownCardById',id)end
local function fullhand(p)local cs=q(p,'getHandcards');if #cs~=q(p,'getHandcardNum')then ai_unsupported('NyarzFirst source requires complete lawful foreign hand','NyarzFirst.foreign_hand')end;return cs end
local function evaluation(self,name)return q(self,'getEvaluationCard',name or'slash')end
local function named(self,skill,name,costs)return q(self,'evaluateSkillCard',skill,name,costs or{})end
local function own_ai(p)local a=p._room and p._room._ai;if not a or a.player~=p then ai_unsupported('NyarzFirst view-as requires owner','NyarzFirst.view_as')end;return a end
local function memory(self,key,value,write)
 if write then if value==nil then value=false end;q(self,'setStrategyMemory','NyarzFirst.'..key,value);return end
 local value,present=q(self,'getStrategyMemory','NyarzFirst.'..key);if present then return value~=false and value or nil end
end
local function save_targets(self,key,ts)local names={};for _,p in ipairs(ts or{})do names[#names+1]=q(p,'objectName')end;memory(self,key,names,true)end
local function targets(self,key)local names=memory(self,key);if not names then return nil end;local out=AIList.new({});for _,n in ipairs(names)do out:append(known(self.room:findPlayerByObjectName(n),n))end;return out end
local selectors={Godpoxi=true,GodpoxidisCard=true,exchengxiang=true,renchou=true,pingjianex=true,Dlimu=true,gfengying=true,dyuyuan=true,paiyiex=true,DiylijiCard=true,godgongxin=true,godgongxindisCard=true,extuifengCard=true,exqiangwu=true,spyuqi=true,jitongxin=true,jitongxinelse=true,spjiang=true,exfangtongCard=true,spjilve=true,sppingxiang=true,sppingxiangSlash=true,spjiufa=true,dyizheng=true,drangjie=true,dwzhizhe=true,dwqingshi=true,jfjifengdis=true,xrxiaorui=true,xrshanjia=true,yzxieshu=true}
local provider={GodpoxidisCard='Godpoxi',godgongxindisCard='godgongxin',DiylijiCard='Diyliji',extuifengCard='extuifeng',exfangtongCard='exfangtong',sppingxiangSlash='sppingxiang',jfjifengdis='jfjifeng'}
local function ids(raw)local out={};if raw~='.'and raw~=''then for v in raw:gmatch('[^+]+')do local id=tonumber(v);if not id or id<0 or id%1~=0 then ai_unsupported('invalid NyarzFirst source material',raw)end;out[#out+1]=id end end;return out end
local function wireparts(wire)
 local cls,raw,user=wire:match('^#([%w_]+):([^:]*):(.*)$');if not cls or not selectors[cls]then ai_unsupported('unmapped NyarzFirst skillcard selector',wire)end
 local to={};local declaration=user;local names=user:match('^%-%>(.*)$');if names then declaration='';for n in names:gmatch('[^+]+')do to[#to+1]=n end end
 return cls,ids(raw),declaration,to
end
local suits={spade=0,club=1,heart=2,diamond=3,no_suit_black=4,no_suit_red=5,no_suit=6,to_be_decided=6}
local function printed(wire,self)
 local name,skill,suit,num,raw=wire:match('^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=([^:]+)$')
 if not name or suits[suit]==nil then ai_unsupported('NyarzFirst source CardParse face needs exact native parser witness',wire)end
 local numbers={A=1,J=11,Q=12,K=13,JOKER=0};local number=numbers[num]or tonumber(num);if not number then ai_unsupported('NyarzFirst source number is not parsed',wire)end
 local costs=ids(raw);local color=suits[suit]
 if #costs==1 then local c=face(self,costs[1]);if color==6 then color=q(c,'getSuit')end;if number<=0 then number=q(c,'getNumber')end
 elseif #costs>1 and color==6 then local red,black=true,true;for _,id in ipairs(costs)do local c=face(self,id);red=red and q(c,'isRed');black=black and q(c,'isBlack')end;color=red and 5 or black and 4 or 6 end
 return{name=name,skill=skill,suit=color,number=number,subcards=costs}
end
local function parse(self,wire)
 if wire:sub(1,1)~='#'then local spec=printed(wire,self);local c=evaluation(self,spec.name);return q(self,'evaluateTurnConversion',spec.skill,q(c,'getClassName'),spec,self.request)end
 local cls,costs,user=wireparts(wire);local skill=provider[cls]or cls
 if #costs==0 and user==''then return q(self,'legacySkillSeed',skill,'#'..cls,self.request)end
 return q(self,'evaluateTurnSkillCard',skill,'#'..cls,costs,self.request,user~=''and user or nil)
end
local function response(self,wire)
 local cls,costs,user,to=wireparts(wire);local request=self.request
 -- This response callback receives the outer DTO, not an AiLegacyRequestView.
 -- With no explicit skill_action, the existing binder selects the unique
 -- current native source scope; it still rejects missing or ambiguous scopes.
 if cls=='gfengying'then request=AILegacyRequest.new(request,self.room)end
 local c=q(self,'bindSkillCard',provider[cls]or cls,costs,request,user~=''and user or nil,'#'..cls)
 return{kind='use_card',card_spec=q(c,'toCardSpec'),targets=to}
end
local function answer(self,c,to)
 if q(c,'isEvaluationOnly')then local skill=q(c,'getSkillName',false);local provider=skill:gsub('^_','');local receipt=q(self,'bindSkillCard',provider,q(c,'getSubcards'),self.request,q(c,'objectName'))
  for _,key in ipairs{'objectName','getSuit','getNumber'}do if q(receipt,key)~=q(c,key)then ai_unsupported('NyarzFirst receipt changed selected source product',key)end end
  if q(receipt,'getSkillName',false)~=skill then ai_unsupported('NyarzFirst receipt changed raw skill',skill)end
  local a,b=q(receipt,'getSubcards'),q(c,'getSubcards');if #a~=#b then ai_unsupported('NyarzFirst receipt changed costs',skill)end;for i,id in ipairs(a)do if b[i]~=id then ai_unsupported('NyarzFirst receipt reordered costs',skill)end end;c=receipt
 end
 if AIValue.isConversion(c)then return{kind='use_card',card_spec=q(c,'toCardSpec'),targets=to or{}}end
 if q(c,'isVirtualCard')then ai_unsupported('NyarzFirst selected virtual lacks authority','NyarzFirst.answer')end
 return{kind='use_card',card_ids={q(c,'getEffectiveId')},targets=to or{}}
end
local function nested(self,reg,key,...)
 local f=q(self,'getHooks',reg)[key];if type(f)~='function'then ai_unsupported('NyarzFirst required shared callback missing',reg..'.'..key)end
 local v=f(...);if AIUnsupported.is(v)then error(v,0)end;return v
end
local function view(self,wire)return printed(wire,self)end

local function source_inverse(self) local row=facts(self).inverse; if type(row)~="table" or row.known~=true then ai_unsupported("source global inverse is unknown","NyarzFirst.inverse")end; return row.value end
local function prop(self,key)return known(facts(self).properties and facts(self).properties[key],key)end
local function context(self)return known(q(self,'getDecisionContext').NyarzFirst,'NyarzFirst.context')end
local function tagplayer(self,owner,key)
 local rows=context(self).player_tags;local row=rows and rows[key]
 if type(row)~='table'or row.owner~=(owner and q(owner,'objectName')or'@room')or row.known~=true then ai_unsupported('NyarzFirst current actor tag unknown',key)end
 if row.present==false then return nil end
 return hydrate_context(self,row.value,'Player')
end
local function tagids(self,key)local rows=context(self).id_tags;return AIList.new(known(rows and rows[key],key))end
local function taguse(self,key)return hydrate_context(self,known(context(self)[key],key),'CardUse')end
local function tagjudge(self,key)return hydrate_context(self,known(context(self)[key],key),'Judge')end
local function cardtag(self,c,key)
 if key=='dwqingshitarget'then
  local raw=type(c)=='table'and rawget(c,'_view')
  local identity=raw and raw.legacy_identity_token
  local rows=facts(self).card_observations
  local row=type(identity)=='string'and rows and rows[identity]
  if type(row)~='table'or row.known~=true or type(row[key])~='string'then
   ai_unsupported('source card tag lacks this observer card-lifecycle witness',key)
  end
  return row[key]
 end
 local rows=facts(self).card_tags;local row=rows and rows[tostring(q(c,'getEffectiveId'))];return known(row and row[key],key)
end
local function role(self,p)if p==self.player then return q(p,'getRole')end;return q(self,'getRoleEstimate',p)end
local function descriptor(c)local ids={};for _,id in ipairs(q(c,'getSubcards'))do ids[#ids+1]=id end;return{name=q(c,'objectName'),skill=q(c,'getSkillName',false),suit=q(c,'getSuit'),number=q(c,'getNumber'),subcards=ids}end


sgs.ai_skill_playerchosen.Dqizhi = function(self,targets)
	q(self,"updatePlayers")

	if q(self.player,"getJudgingArea"):length() > 0 then return self.player end
	local targets = sgs.QList2Table(targets)
	for _,target in ipairs(targets)do
		if q(self,"isFriend",target) and q(target,"getJudgingArea"):length() > 0 then return target end
	end
	return nested(self,"ai_skill_playerchosen","qizhi",self,targets)
end


sgs.ai_skill_invoke.Djinqu = function(self, data)
	local player = self.player
    if (q(player,"getMark","&Dqizhi-Clear") > 0) and (q(player,"getMark","&Dqizhi-Clear") >= q(player,"getHandcardNum")) then return true end
    return false 
end


sgs.ai_skill_invoke.Godjieying = function(self, data)
	local player = self.player
    local target = tagplayer(self,player,"jieyingtarget")
    if q(self,"isEnemy",target) then 
        return true
    else
        return false 
    end
end

sgs.ai_skill_playerchosen.Godjieying = function(self, targets)
	if q(self.player,"getMark","&Godying") < 2 then return nil end
	for _,target in sgs.qlist(targets) do
		if q(self,"isFriend",target) then
			return target
		end
	end
	if q(self.player,"getMark","&Godying") < 3 then return nil end
	for _,target in sgs.qlist(targets) do
		if q(self,"isEnemy",target) then
			return target
		end
	end
	return nil
end


sgs.ai_fill_skill.Godpoxi=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#Godpoxi") then
		return parse(self,"#Godpoxi:.:")
	end
end

sgs.ai_skill_use_func["#Godpoxi"] = function(card, use, self)
	q(self,"updatePlayers")
	if #self.enemies <= 0 then return end
	local target = nil
	q(self,"sort",self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do

		if q(p,"getHandcardNum") == 0 then continue end
		target = p
		break
	end
	if not target then return end
	if target then
		local card_str = "#Godpoxi:.:->"..target:objectName()
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_use["@@Godpoxi"] = function(self, prompt)
	local target = tagplayer(self,self.player,"godpoxi")
	if target then
		local target_handcards = sgs.QList2Table(fullhand(target))
		q(self,"sortByUseValue",target_handcards, source_inverse(self))
		local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0
		
		for _, c in ipairs(target_handcards) do
			if spade_check and q(c,"getSuit") == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			elseif heart_check and q(c,"getSuit") == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			elseif club_check and q(c,"getSuit") == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			elseif diamond_check and q(c,"getSuit") == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			end
			target_discard_count = #discard_cards
		end
		
		for _, c in ipairs(handcards) do
			if not q(c,"isKindOf","Peach")
			and not q(c,"isKindOf","Duel")
			and not q(c,"isKindOf","Indulgence")
			and not q(c,"isKindOf","SupplyShortage")
			and not (q(self,"getCardsNum","Jink") == 1 and q(c,"isKindOf","Jink"))
			and not (q(self,"getCardsNum","Analeptic") == 1 and q(c,"isKindOf","Analeptic"))
			then
				if spade_check and q(c,"getSuit") == sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				elseif heart_check and q(c,"getSuit") == sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				elseif club_check and q(c,"getSuit") == sgs.Card_Club then
					club_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				elseif diamond_check and q(c,"getSuit") == sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards, q(c,"getEffectiveId"))
				end
			end
		end

		if ((4 - target_discard_count) == 0) and q(self.player,"getHandcardNum") > q(self.player,"getMaxCards") then return "." end
		
		if #discard_cards == 4 then
			return response(self,"#GodpoxidisCard:"..table.concat(discard_cards, "+")..":")

		end
	end
	return "."
end

sgs.ai_use_priority.Godpoxi = 3
sgs.ai_use_value.Godpoxi = 3
sgs.ai_card_intention.Godpoxi = 50


sgs.ai_skill_invoke.exchengxiang = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.exchengxiang = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if q(self,"isFriend",target) and q(target,"isWounded") then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
		if q(self,"isFriend",target) then
			return target
		end
	end
    return nil
end

sgs.ai_playerchosen_intention.exchengxiang = function(self, from, to)
	q(self,"updateIntention",from, to, -80)
end

sgs.ai_skill_use["@@exchengxiang"] = function(self, prompt)
	local card_ids = tagids(self,"chengxiangcards")
	local getcards = {}
	local sum = 0
	for _,id in sgs.qlist(card_ids) do
		local card = face(self,id)
		if q(card,"isKindOf","EquipCard") or (q(card,"objectName") == "peach") or (q(card,"objectName") == "analeptic") then
			if (q(card,"getNumber") + sum) <= 13 then
				table.insert(getcards,id)
				sum = sum + q(card,"getNumber")
			end
		end
	end
	for _,id in sgs.qlist(card_ids) do
		local card = face(self,id)
		if ((q(card,"getNumber") + sum) <= 13) and (not table.contains(getcards,id)) then
			table.insert(getcards,id)
			sum = sum + q(card,"getNumber")
		end
	end
	local card_str = "#exchengxiang:"..table.concat(getcards, "+")..":"
	return response(self,card_str)
end

sgs.ai_can_damagehp.exchengxiang = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
end


sgs.ai_skill_invoke.exrenxin = function(self, data)
	local target = tagplayer(self,self.player,"renxintarget")
    if q(self,"isFriend",target) then return true end
    if q(target,"objectName") == q(self.player,"objectName") then return true end
    return false
end

 
sgs.ai_fill_skill.LuaLonghun=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByUseValue",cards,true)
	for _, card in ipairs(cards) do
		if q(card,"getSuit") == sgs.Card_Diamond and q(self,"slashIsAvailable") then
			return parse(self,("fire_slash:longhun[%s:%s]=%d"):format(q(card,"getSuitString"), q(card,"getNumberString"), q(card,"getId")))
		end
	end
end

sgs.ai_view_as.LuaLonghun = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceSpecial then return end
	if q(card,"getSuit") == sgs.Card_Diamond then
		return view(own_ai(player),("fire_slash:longhun[%s:%s]=%d"):format(suit, number, card_id))
	elseif q(card,"getSuit") == sgs.Card_Club then
		return view(own_ai(player),("jink:longhun[%s:%s]=%d"):format(suit, number, card_id))
	elseif q(card,"getSuit") == sgs.Card_Heart and q(player,"getMark","Global_PreventPeach") == 0 then
		return view(own_ai(player),("peach:longhun[%s:%s]=%d"):format(suit, number, card_id))
	elseif q(card,"getSuit") == sgs.Card_Spade then
		return view(own_ai(player),("nullification:longhun[%s:%s]=%d"):format(suit, number, card_id))
	end
end

sgs.LuaLonghun_suit_value = {
	heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.LuaLonghun(to, card, self)
	if q(to,"getCardCount") > 3 then return false end
	if q(to,"isNude") then return true end
	return q(card,"getSuit") == sgs.Card_Heart or q(card,"getSuit") == sgs.Card_Spade
end


sgs.ai_skill_invoke.exjueqing = function(self, data)
	local player = self.player
    local target = tagplayer(self,player,"exjueqingta")
    if q(self,"isEnemy",target) then 
        return true
    else
        return false 
    end
end

sgs.ai_getLeastHandcardNum_skill.exshangshi = function(self, player, least)
	local x = math.max(q(player,"getLostHp"), 1)
	if least < x then
		return x
	end
end


sgs.ai_fill_skill.renchou=function(self,inclusive,request)
	local card = named(self,"renchou_limit","slash",{})
	
	if not q(self.player,"isCardLimited",card, sgs.Card_MethodUse) then
		return q(self,"legacySkillSeed","renchou","#renchou",request)
	end
end

sgs.ai_skill_use_func["#renchou"] = function(card, use, self, request)
	local target = nil
	q(self,"sort",self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	local card = named(self,"renchou","slash",{})
	for _, enemy in ipairs(self.enemies) do
		if  (((q(self.player,"getHandcardNum") == q(enemy,"getHandcardNum") and q(self.player,"getHp") ~= q(enemy,"getHp")) 
		or (q(self.player,"getHandcardNum") ~= q(enemy,"getHandcardNum") and q(self.player,"getHp") == q(enemy,"getHp")))) and q(self,"slashIsEffective",card, enemy, self.player) and q(self,"isGoodTarget",enemy, self.enemies, card) then
			use.card = card
			target = enemy
		end
	end
	if target then
		local card_str = "#renchou:.:->"..target:objectName()
		local acard = q(self,"evaluateTurnSkillCard","renchou","#renchou",{},request)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end


sgs.ai_skill_playerchosen.dwanggui = function(self, targets)

	if q(self.player,"getMark","dwangguida") > 0 then
		for _,p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) and not q(self,"cantbeHurt",p) and q(self,"damageIsEffective",p) and q(self,"canDamage",p,self.player,nil) then 
				return p
			end
		end
		return nil
	else
		local p = nil
		local hand = 999
		for _,ta in sgs.qlist(targets) do
			if q(self,"isFriend",ta) and (q(ta,"getHandcardNum") < hand) and (q(ta,"objectName") ~= q(self.player,"objectName")) then
				p = ta
				hand = q(ta,"getHandcardNum")
			end
		end
		if p then 
			return p
		else
			return self.player
		end
	end
end


sgs.ai_skill_invoke.dxibin = function(self, data)
	local player = self.player
    local target = tagplayer(self,player,"dxibinta")
    if q(self,"isEnemy",target) then 
		if q(target,"getHandcardNum") >= q(target,"getHp") then
        	return true
		elseif q(target,"getHandcardNum") < q(target,"getHp") then
			local draw = q(target,"getHp") - q(target,"getHandcardNum")
			if draw >= 3 then return false end
			return true
		end
    elseif q(self,"isFriend",target) then
        if (q(target,"getHandcardNum") + 2) < q(target,"getHp") then
			for _,card in sgs.qlist(fullhand(target)) do
				if q(card,"isAvailable",target) then return false end
			end
			return true
		end
    end
	return false
end


sgs.ai_fill_skill.pingjianex=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#pingjianex") then
		return parse(self,"#pingjianex:.:")
	end
end

sgs.ai_skill_use_func["#pingjianex"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_invoke.pingjianex = function(self, data)
	return true
end


sgs.ai_skill_invoke.Dtushe = function(self, data)
	if q(self.player,"getPhase") == sgs.Player_NotActive then return true end
	if q(self.player,"getMark","dtushe") >= 2 then return true end
	local can = true
	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	q(self,"sortByUseValue",cards,true)
	for _, card in ipairs(cards) do
		if q(card,"isKindOf","BasicCard") then 
			can = false 
			break
		end
	end
	local slash = 0
	local more = 0
	local mm = {"amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
	for _, card in ipairs(cards) do
		if q(card,"isKindOf","Slash") then 
			slash = slash + 1
		end
		if table.contains(mm,q(card,"objectName")) then
			more = more + 1
		end
	end
	if slash == 0 and more == 0 then return true end
	return can
end


sgs.ai_skill_invoke.Dlimu = true

sgs.ai_fill_skill.Dlimu=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByUseValue",cards,true)
	local slash = 0
	local red = 0
	local black = 0
	for _, card in ipairs(cards) do
		if q(card,"isKindOf","Slash") then 
			slash = slash + 1
		end
		if q(card,"isRed") then
			red = red + 1
		end
		if q(card,"isBlack") then
			black = black + 1
		end
	end
	if (slash >= 2 and (not q(self.player,"containsTrick","supply_shortage")) and black > 0)  then
		return parse(self,"#Dlimu:.:")
	elseif q(self.player,"getHp") == 1 and red > 0 and (not q(self.player,"containsTrick","indulgence")) 
	or ((not q(self.player,"containsTrick","indulgence")) and slash >= 4 and red > 0 and (not q(self.player,"containsTrick","supply_shortage"))) then
		return parse(self,"#Dlimu:.:")
	end
end

sgs.ai_skill_use_func["#Dlimu"] = function(card, use, self)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByUseValue",cards,true)
	local slash = 0
	local red = 0
	local black = 0
	for _, cc in ipairs(cards) do
		if q(cc,"isKindOf","Slash") then 
			slash = slash + 1
		end
		if q(cc,"isRed") then
			red = red + 1
		end
		if q(cc,"isBlack") then
			black = black + 1
		end
	end
	local usecard = nil
	if slash >= 2 and (not q(self.player,"containsTrick","supply_shortage")) and black > 0 then
		for _, cc in ipairs(cards) do
			if q(cc,"isBlack") then
				usecard = cc
				break
			end
		end
	elseif (q(self.player,"getHp") == 1 and red > 0 and (not q(self.player,"containsTrick","indulgence"))) 
	or ((not q(self.player,"containsTrick","indulgence")) and slash >= 4 and red > 0 and (not q(self.player,"containsTrick","supply_shortage")))then
		for _, cc in ipairs(cards) do
			if q(cc,"isRed") then
				usecard = cc
				break
			end
		end
	end
	if usecard then
		local target = self.player
		local card_str = string.format("#Dlimu:%d:->%s", q(usecard,"getId"), q(target,"objectName"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.Dlimu = 7
sgs.double_slash_skill = sgs.double_slash_skill .. "|Dlimu"

sgs.ai_card_priority.Dlimu = function(self, card, v)
	if q(card,"objectName") == "_xuanjian" then
		return v + 5
	end
	
	if q(card,"objectName") == "spear" then
		return v + 4
	end
	
	if q(self.player,"hasWeapon","_xuanjian") or q(self.player,"hasWeapon","spear") then
		if q(card,"isKindOf","Slash") then
			return v + 3
		end
	end
	
	if (q(self.player,"hasWeapon","_xuanjian") or q(self.player,"hasWeapon","spear")) 
	   and (q(card,"isKindOf","Dlimu") or table.contains(q(card,"getSkillNames"), "Dlimu")) then
		return v + 2
	end
	
	return v
end

-- audited alias ai_skill_carduse.Dlimu
sgs.ai_use_revises.Dlimu = function(self,card,use)
	if q(self.player,"hasWeapon","spear")
	and q(card,"isKindOf","Weapon")
	then return false end
	if q(card,"objectName")=="spear"
	then
		use.card = card
		return true
	end
	if q(self,"getCardsNum","BasicCard","h")<1
	then
		local ge = q(self,"getCard","GlobalEffect") or q(self,"getCard","AOE")
		if ge and q(ge,"isAvailable",self.player)
		then use.card = ge return true end
	end
end


sgs.ai_skill_invoke.spduorui = function(self, data)
	local ta = tagplayer(self,self.player,"duoruita")
	if q(self,"isEnemy",ta) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.spduorui = function(self,player,promptlist)
	local target = tagplayer(self,player,"duoruita")
	if target then
		if promptlist[#promptlist]=="yes" then
			q(self,"updateIntention",player,target,80)
		else
			q(self,"updateIntention",player,target,-10)
		end
	end
end


sgs.ai_skill_use["@@gfengying"] = function(self, prompt)
	if q(self.player,"getHandcardNum") < 2 then return "." end
	local handcards = q(self.player,"getCards","he")
	handcards = sgs.QList2Table(handcards)
	q(self,"sortByKeepValue",handcards)
	local card = handcards[1] 
	q(self,"sort",self.enemies, "defense")
	local slash = named(self,"gfengying","thunder_slash",{q(card,"getEffectiveId")})
	
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"isAlive") and q(self,"round50CanSlash",slash,enemy) and not q(self,"slashProhibit",slash, enemy)
			and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) then 
			target = enemy
			break
		end
	end
	if target then
		local card_str = string.format("#gfengying:%d:->%s", q(card,"getId"), q(target,"objectName"))
		return response(self,card_str)
	else
		return "."
	end
end

sgs.ai_card_intention.gfengying = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		q(self,"updateIntention",from, to, 40)
	end
end


sgs.ai_skill_invoke.xuzun = function(self, data)
	if q(self.player,"getHandcardNum") <= q(self.player,"getMaxHp") then return true end
	return false
end


sgs.ai_skill_use["@@dyuyuan"] = function(self, prompt)
	if q(self.player,"getHandcardNum") <= q(self.player,"getMaxCards") then return "." end
	local handcards = q(self.player,"getCards","h")
	handcards = sgs.QList2Table(handcards)
	if #handcards == 0 then return "." end
	if q(self.player,"getPhase") == sgs.Player_Play then
		q(self,"sortByUseValue",handcards, true)
		if #handcards == 1 then return "." end
	else
		q(self,"sortByKeepValue",handcards, true)
	end
	local card = handcards[1] 

	q(self,"sort",self.friends, "defense")
	local target = nil
	for _,friend in ipairs(self.friends) do
		if q(friend,"isAlive") and q(friend,"getMark","dyuyuan") == 0 and (q(self.player,"objectName") ~= q(friend,"objectName")) then 
			target = friend
			break
		end
	end

	if not target and q(self.player,"getHandcardNum") > 3 and q(self.player,"getPhase") == sgs.Player_Play then
		q(self,"sort",self.enemies, "defense")
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"isAlive") and q(enemy,"getMark","dyuyuan") == 0 and (q(enemy,"getMark","dyuyuan"..self.player:objectName()) < q(enemy,"getHp")) then 
				target = enemy
				break
			end
		end
	end

	if target then
		if q(self,"isEnemy",target) then
			local card_str = string.format("#dyuyuan:%d:->%s", q(card,"getId"), q(target,"objectName"))
			return response(self,card_str)
		elseif q(self,"isFriend",target) then
			if (q(self.player,"getHandcardNum") > (q(self.player,"getMaxCards") + 1)) and (#handcards >= 2) then
				local cards = {}
				table.insert(cards, handcards[1]:getEffectiveId())
				table.insert(cards, handcards[2]:getEffectiveId())
				local card_str = string.format("#dyuyuan:%s:->%s", table.concat(cards,"+"), q(target,"objectName"))
				return response(self,card_str)
			else
				local card_str = string.format("#dyuyuan:%d:->%s", q(card,"getId"), q(target,"objectName"))
				return response(self,card_str)
			end
		end
	else
		return "."
	end
end

sgs.ai_skill_playerchosen.dyuyuan = function(self, targets)
	local max = -1
	local target = nil
	for _,p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) and q(p,"getMark","dyuyuan"..self.player:objectName()) > max and q(self,"damageIsEffective",p) and not q(self,"cantDamageMore",self.player, p) and q(self,"canDamage",p,self.player,nil) then 
			max = q(p,"getMark","dyuyuan"..self.player:objectName())
			target = p
		end
	end
	return target
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|dyuyuan"
function sgs.ai_slash_prohibit.dyuyuan(self,from,to)
	if q(self,"hasJueqingEffect",from,to) or (q(from,"hasSkill","nosqianxi") and q(from,"distanceTo",to)==1) then return false end
	if q(from,"hasFlag","NosJiefanUsed") then return false end
	if q(to,"getHp")>1 or #(q(self,"getEnemies",from))==1 then return false end
	if q(from,"getMaxHp")==3 and q(from,"getArmor") and q(from,"getDefensiveHorse") then return false end
	if q(from,"getMaxHp")<=3 or (q(from,"isLord") and q(self,"isWeak",from)) then return true end
	if q(from,"getMaxHp")<=3 or (q(self.room,"getLord") and role(self,from)=="renegade") then return true end
	return false
end


sgs.ai_skill_playerchosen.Gliegong = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.Gliegong = function(self, from, to)
	q(self,"updateIntention",from, to, 200)
end


sgs.ai_skill_invoke.Gposhi = function(self, data)
	local ta = tagplayer(self,self.player,"Gposhi")
	if q(self,"isEnemy",ta) then 
		return true
	else
		return false
	end
end
sgs.hit_skill = sgs.hit_skill .. "|Gposhi"
-- audited alias ai_cardneed.Gposhi
sgs.ai_skill_invoke.exquanji = true
sgs.ai_can_damagehp.exquanji = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>1
	and q(self,"canLoseHp",from,card,to)
end


sgs.ai_skill_choice["ziliex"] = function(self, choices, data)
	if q(self.player,"getLostHp") > 1 then 
		return "recover"
	else
		return "draw"
	end
end


sgs.ai_skill_invoke.paiyiex = true

sgs.ai_fill_skill.paiyiex=function(self,inclusive,request)
	if (not q(self.player,"hasUsed","#paiyiex")) and (q(self.player,"getPile","exquan"):length() > 0 )  then
		return parse(self,"#paiyiex:.:")
	end
end

sgs.ai_skill_use_func["#paiyiex"] = function(card, use, self)
	local card_ids = q(self.player,"getPile","exquan")
	local usecard = nil
	for _,id in sgs.qlist(card_ids) do
		usecard = face(self,id)
		break
	end

	local target = nil
	if q(self.player,"getPile","exquan"):length() <= 2 then
		q(self,"sort",self.enemies, "defense")
		self.enemies = sgs.reverse(self.enemies)
		for _,enemy in ipairs(self.enemies) do
			if (q(enemy,"getHandcardNum") + q(self.player,"getPile","exquan"):length() - 1) > q(self.player,"getHandcardNum") then
				target = enemy
				break
			end
		end
	end
	if not target then
		q(self,"sort",self.friends, "defense")
		self.friends = sgs.reverse(self.friends)
		for _,friend in ipairs(self.friends) do
			if (q(friend,"getHandcardNum") + q(self.player,"getPile","exquan"):length() - 1) <= q(self.player,"getHandcardNum") then
				target = friend
				break
			end
		end
	end
	if not target then target = self.player end
	local card_str = string.format("#paiyiex:%d:->%s", q(usecard,"getId"), q(target,"objectName"))
	local acard = parse(self,card_str)
	assert(acard)
	use.card = acard
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_card_intention["#paiyiex"] = function(self, card, from ,tos)
	for _,to in sgs.qlist(tos) do
		if q(from,"getPile","exquan"):length() <= 2 then
			q(self,"updateIntention",from, to, 30)
		else
			q(self,"updateIntention",from, to, -50)
		end
	end
end

sgs.ai_use_priority["#paiyiex"] = 3


sgs.ai_fill_skill.Diyliji=function(self,inclusive,request)
	if (q(self.player,"getMark","&Diyliji-Clear") > 0) and (q(self.player,"canDiscard",self.player, "he")) then
		return parse(self,"#DiylijiCard:.:")
	end
end

sgs.ai_skill_use_func["#DiylijiCard"] = function(card, use, self)
	local handcards = q(self.player,"getCards","he")
	handcards = sgs.QList2Table(handcards)
	q(self,"sortByKeepValue",handcards)
	local usecard = nil
	usecard = handcards[1]
	q(self,"sort",self.enemies, "defense")
	local target = self.enemies[1]
	if target then
		local card_str = string.format("#DiylijiCard:%d:->%s", q(usecard,"getId"), q(target,"objectName"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.Diyliji = 5


sgs.ai_skill_invoke.godshelie = true

sgs.ai_skill_discard.godshelie = function(self,max,min)
	local player = self.player
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByKeepValue",cards)
	local dis = {}
	if #cards >= 2 then
		table.insert(dis, cards[1]:getEffectiveId())
		table.insert(dis, cards[2]:getEffectiveId())
	end
	return dis
end

sgs.ai_skill_choice["godshelie"] = function(self, choices, data)
	if q(self.player,"getHandcardNum") > 3 then 
		return "play"
	else
		return "draw"
	end
end


sgs.ai_fill_skill.godgongxin=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#godgongxin") then
		return parse(self,"#godgongxin:.:")
	end
end

sgs.ai_skill_use_func["#godgongxin"] = function(card, use, self)
	q(self,"updatePlayers")
	if #self.enemies <= 0 then return end
	local target = nil
	q(self,"sort",self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do

		target = p
		break
	end
	if not target then return end
	if target then
		local card_str = "#godgongxin:.:->"..target:objectName()
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_use["@@godgongxin"] = function(self, prompt)
	local target = tagplayer(self,self.player,"godgongxin")
	if target then
		local target_handcards = sgs.QList2Table(fullhand(target))
		q(self,"sortByUseValue",target_handcards, source_inverse(self))
		local discard_cards = {}
		local color = nil
		local n = 0
		for _,card in ipairs(target_handcards) do
			if n == 0 then
				table.insert(discard_cards,q(card,"getEffectiveId"))
				if q(card,"isRed") then 
					color = "red"
				elseif q(card,"isBlack") then
					color = "black"
				end
				n = n + 1
			elseif q(card,"isRed") and color == "red" then
				table.insert(discard_cards,q(card,"getEffectiveId"))
				n = n + 1
			elseif q(card,"isBlack") and color == "black" then
				table.insert(discard_cards,q(card,"getEffectiveId"))
				n = n + 1
			end
			if n == 2 then break end
		end
		if n > 0 then
			return response(self,"#godgongxindisCard:"..table.concat(discard_cards, "+")..":")
		end
	end
	return "."
end

sgs.ai_use_priority.godgongxin = 3
sgs.ai_use_value.godgongxin = 3
sgs.ai_card_intention.godgongxin = 50


sgs.ai_fill_skill.extuifeng=function(self,inclusive,request)
	if q(self.player,"canDiscard",self.player, "he") and q(self.player,"getMark","&extuifeng") > 0 then
		return parse(self,"#extuifengCard:.:")
	end
end

sgs.ai_skill_use_func["#extuifengCard"] = function(card, use, self)
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	if #cards > 0 then
		local card_str = string.format("#extuifengCard:%d:", cards[1]:getEffectiveId())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
	end
end


sgs.ai_fill_skill.exqiangwu=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#exqiangwu") then
		return parse(self,"#exqiangwu:.:")
	end
end

sgs.ai_skill_use_func["#exqiangwu"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_discard.exqiangwu = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByKeepValue",cards)
	local to_discard = {}
	local min = 13
	local slash = 0
	for _,card in ipairs(cards) do
		if q(card,"isKindOf","Slash") then
			slash = slash + 1
			if q(card,"getNumber") <= 13 then min = q(card,"getNumber") end
		end
	end
	if slash >= 2 then
		for _,card in ipairs(cards) do
			if q(card,"getNumber") <= min then 
				table.insert(to_discard,q(card,"getEffectiveId"))
				break
			end
		end
	end
	return to_discard
end

sgs.ai_use_priority.exqiangwu = 8


sgs.ai_skill_invoke.spyuqi = true

sgs.ai_skill_use["@@spyuqi"] = function(self, prompt)
	local card_ids = tagids(self,"spyuqicc")
	local getcards = {}
	local choices = {}
	for _,id in sgs.qlist(card_ids) do
		local card = face(self,id)
		table.insert(choices,card)
	end
	q(self,"sortByKeepValue",choices)
	local target = tagplayer(self,self.player,"spyuqita")
	if (not q(self,"isFriend",target)) then
		table.insert(getcards,choices[1]:getEffectiveId())
	elseif q(self,"isFriend",target) and q(self.player,"objectName") ~= q(target,"objectName") then
		table.insert(getcards,choices[1]:getEffectiveId())
		table.insert(getcards,choices[2]:getEffectiveId())
	elseif q(self.player,"objectName") == q(target,"objectName") then
		for _,card in ipairs(choices) do
			table.insert(getcards,q(card,"getEffectiveId"))
		end
	end
	local card_str = "#spyuqi:"..table.concat(getcards, "+")..":"
	return response(self,card_str)
end

sgs.ai_can_damagehp.spyuqi = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
end


sgs.ai_skill_invoke.spxianjin = true

sgs.ai_skill_playerchosen.spxianjin = function(self, targets)
	local min = 999
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(p,"getHandcardNum") < min then
			min = q(p,"getHandcardNum")
		end
	end
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(p,"getHandcardNum") == min then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.spxianjin = function(self, from, to)
	q(self,"updateIntention",from, to, -40)
end

sgs.ai_skill_invoke.spshanshen = true

sgs.ai_skill_playerchosen.spshanshen = function(self, targets)
	local min = 999
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(p,"getHandcardNum") < min then
			min = q(p,"getHandcardNum")
		end
	end
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(p,"getHandcardNum") == min then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.spshanshen = function(self, from, to)
	q(self,"updateIntention",from, to, -40)
end


sgs.ai_skill_invoke.shaoyan = true


sgs.ai_fill_skill.jitongxin=function(self,inclusive,request)
	local can = false
	if q(self.player,"getChangeSkillState","jitongxin") <= 1 then
		for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if not q(p,"isKongcheng") then 
				can = true 
				break
			end
		end
	elseif q(self.player,"getChangeSkillState","jitongxin") == 2 then
		if q(self.player,"getHandcardNum") >= 2 then
			can = true
		end
	end
	if q(self.player,"getMark","jitongxin-PlayClear") == 0 and can then
		return parse(self,"#jitongxin:.:")
	end
end

sgs.ai_skill_use_func["#jitongxin"] = function(card, use, self)
	if q(self.player,"getChangeSkillState","jitongxin") <= 1 then
		local target = nil
		q(self,"sort",self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _,p in ipairs(self.enemies) do
			if q(p,"getHandcardNum") > 0 then
				target = p
				break
			end
		end
		if not target then
			q(self,"sort",self.friends, "handcard")
			for _,p in ipairs(self.friends) do
				if q(p,"getHandcardNum") > 0 and q(p,"objectName") ~= q(self.player,"objectName") then
					target = p
					break
				end
			end
		end
		local card_str = string.format("#jitongxin:.:->%s",q(target,"objectName"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end

	if q(self.player,"getChangeSkillState","jitongxin") == 2 then
		local target = nil
		local usecard = nil
		local handcards = q(self.player,"getCards","h")
		handcards = sgs.QList2Table(handcards)
		q(self,"sortByKeepValue",handcards)
		local usecard = nil
		for _,card in ipairs(handcards) do
			usecard = card
			break
		end
		q(self,"sort",self.enemies, "defense")
			for _,p in ipairs(self.enemies) do
				if not q(self,"cantbeHurt",p) and q(self,"damageIsEffective",p) and q(self,"canDamage",p,self.player,nil) then
					target = p
					break
				end
			end
		if not target then
			q(self,"sort",self.friends, "hp")
			for _,p in ipairs(self.friends) do
				if q(p,"objectName") ~= q(self.player,"objectName") then
					target = p
					break
				end
			end
		end
		if target and usecard then
			local card_str = string.format("#jitongxin:%d:->%s", q(usecard,"getId"), q(target,"objectName"))
			local acard = parse(self,card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_skill_use["@@jitongxin"] = function(self, prompt)
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","jitongxindraw") and q(self,"isFriend",p) then
			local card_str = "#jitongxinelse:.:"
			return response(self,card_str)
		end
		if q(p,"hasFlag","jitongxinda") and not q(self,"cantbeHurt",p) and q(self,"damageIsEffective",p) and q(self,"canDamage",p,self.player,nil)  then
			local card_str = "#jitongxinelse:.:"
			return response(self,card_str)
		end
	end
	return "."
end

sgs.ai_use_priority.jitongxin = 10


sgs.ai_skill_invoke.spjiang = true

sgs.ai_fill_skill.spjiang=function(self,inclusive,request)
	if (q(self.player,"getHandcardNum") > 1) and (not q(self.player,"hasUsed","#spjiang")) and ((q(self.player,"getHp") > 1 and q(self.player,"getMark","sphunzi") > 0) or (q(self.player,"getMark","sphunzi") ==0)) then
		return parse(self,"#spjiang:.:")
	end
end

sgs.ai_skill_use_func["#spjiang"] = function(card, use, self)
	local handcards = q(self.player,"getCards","h")
	handcards = sgs.QList2Table(handcards)
	q(self,"sortByKeepValue",handcards)
	local usecard = {}
	local n = q(self.player,"getHandcardNum")
	local duel
	n = math.ceil(n/2)
	for _,card in ipairs(handcards) do
		table.insert(usecard,q(card,"getEffectiveId"))
		
		n = n - 1
		if n <= 0 then break end
	end
	q(self,"sort",self.enemies, "defense")
	
	
	local target
	duel = named(self,"spjiang","duel",usecard)
	local dummy_use = q(self,"aiUseCard",duel, dummy())
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			target = p
		end
	end

	if target then
		local card_str = string.format("#spjiang:%s:->%s", table.concat(usecard,"+"), q(target,"objectName"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.spjiang = 4

sgs.ai_canNiepan_skill.sphunzi = function(player)
	return q(player,"hasLordSkill","sphunzi") and q(player,"getMark","sphunzi") == 0
end


sgs.ai_skill_invoke.spyingzi = true


sgs.ai_skill_playerchosen.spyinghun = function(self, targets)
	if q(self.player,"getLostHp") <= 1 then
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and q(p,"getHandcardNum") >= 1 then
				return p
			end
		end
	end
	if q(self.player,"getLostHp") > 1 then
		local n = -1
		local target = nil
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and ((q(p,"getHandcardNum") < n) or n < 0) then
				n = q(p,"getHandcardNum")
				target = p
			end
		end
		if target then return target end
		n = -1
		for _,p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) and ((q(p,"getHandcardNum") < n) or n < 0) then
				n = q(p,"getHandcardNum")
				target = p
			end
		end
		if target then return target end
		return self.player
	end
end

sgs.ai_skill_choice["spyinghun"] = function(self, choices, data)
	local target = tagplayer(self,self.player,"spyinghun")
	choices = choices:split("+")
	if q(self,"isFriend",target) then 
		for _,choice in ipairs(choices) do
			if string.find(choice,"draw") then
				return choice
			end
		end
	elseif q(self,"isEnemy",target) then
		for _,choice in ipairs(choices) do
			if string.find(choice,"dis") then
				return choice
			end
		end
	elseif q(self.player,"objectName") == q(target,"objectName") then
		for _,choice in ipairs(choices) do
			if string.find(choice,"draw") then
				return choice
			end
		end
	end
end


local function fangtongca(self,tasum, card_ids)
	local sum = 0
	local usecards = {}
	if card_ids:length() > 30 then
		for _,id in sgs.qlist(card_ids) do
			local card = face(self,id)
			if (q(card,"getNumber") + sum) <= tasum then
				table.insert(usecards,id)
				sum = sum + q(card,"getNumber")
			end
		end
	else
		local n = card_ids:length()
		local allcards = {}
		for _,id in sgs.qlist(card_ids) do
			table.insert(allcards, id)
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if (i & (2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + face(self,id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then 
		return usecards
	else
		return {}
	end
end

sgs.ai_skill_use["@@exfangtong"] = function(self, prompt)
	if q(self.player,"isNude") then return "." end
	local card_ids = q(self.player,"getPile","exfang")
	local allcards = {}
	local sum = 0
	local n = 0
	for _,id in sgs.qlist(card_ids) do
		sum = sum + face(self,id):getNumber()
		table.insert(allcards,id)
		n = n + 1
	end
	if sum < 23 then return "." end

	q(self,"sort",self.enemies, "defense")
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"isAlive") and not q(self,"cantDamageMore",self.player, enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) then 
			target = enemy
			break
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"isAlive") and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) then 
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"isAlive") then 
				target = enemy
				break
			end
		end
	end

	if not target then return "." end

	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 36 - q(card,"getNumber")
		usecards = fangtongca(self,tem,card_ids)
		if #usecards > 0 then
			table.insert(usecards,q(card,"getEffectiveId"))
		end
		for _,c in ipairs(usecards) do
			sum = sum + face(self,c):getNumber()
		end
		if sum == 36 then break end
	end
	
	if sum ~= 36 then return "." end

	local card_str = "#exfangtongCard:"..table.concat(usecards, "+")..":->"..target:objectName()
	return response(self,card_str)
end


sgs.ai_fill_skill.spjilve=function(self,inclusive,request)
	if (not q(self.player,"hasUsed","#spjilve")) and (q(self.player,"getMark","&spren") > 0) then
		return parse(self,"#spjilve:.:")
	end
end

sgs.ai_skill_use_func["#spjilve"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.spjilve = 6
sgs.ai_use_value.spjilve = 6

sgs.ai_skill_playerchosen.spjilve = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and (not q(p,"faceUp")) then
			return p
		end
	end
	q(self,"sort",self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do
		if q(p,"faceUp") then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.spjilve = function(self, from, to)
	if q(to,"faceUp") then
		q(self,"updateIntention",from, to, 80)
	else
		q(self,"updateIntention",from, to, -80)
	end
end

sgs.ai_skill_invoke.spjilve = function(self,data)
	if q(self.player,"getMark","spjilvejudge") > 0 then
		if q(self.player,"getMark","&spren") < 3 then return false end
		local judge = tagjudge(self,"spjilvejudge")
		local can = false
		if judge.reason == "indulgence" then
			if q(self,"isFriend",judge.who) and q(judge.card,"getSuitString") ~= "heart" then
				can = true
			elseif q(self,"isEnemy",judge.who) and q(judge.card,"getSuitString") == "heart" then
				can = true
			end
		elseif judge.reason == "supply_shortage" then
			if q(self,"isFriend",judge.who) and q(judge.card,"getSuitString") ~= "club" then
				can = true
			elseif q(self,"isEnemy",judge.who) and q(judge.card,"getSuitString") == "club" then
				can = true
			end
		elseif judge.reason == "lightning" then
			if q(self,"isFriend",judge.who) and q(judge.card,"getSuitString") == "spade" and q(judge.card,"getNumber") >= 2 and q(judge.card,"getNumber") <= 9 then
				can = true
			elseif q(self,"isEnemy",judge.who) and ((q(judge.card,"getSuitString") ~= "spade") or (q(judge.card,"getSuitString") == "spade" and (q(judge.card,"getNumber") < 2 and q(judge.card,"getNumber") > 9))) then
				can = true
			end
		elseif judge.reason == "eight_diagram" then
			if q(self,"isFriend",judge.who) and q(judge.card,"isBlack") then
				can = true
			elseif q(self,"isEnemy",judge.who) and q(judge.card,"isRed") then
				can = true
			end
		end
		return can 
	end

	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") <= 0 and q(self,"isEnemy",p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice["spjilve"] = function(self, choices, data)
	local judge = tagjudge(self,"spjilvejudge")

	if judge.reason == "indulgence" then
		if q(self,"isFriend",judge.who) and string.find(choices,"heart") then
			return "heart"
		elseif q(self,"isEnemy",judge.who) and string.find(choices,"heart") then
			return "diamond"
		end
	elseif judge.reason == "supply_shortage" then
		if q(self,"isFriend",judge.who) and string.find(choices,"club") then
			return "club"
		elseif q(self,"isEnemy",judge.who) and string.find(choices,"club") then
			return "diamond"
		end
	elseif judge.reason == "lightning" then
		if q(self,"isFriend",judge.who) and string.find(choices,"club") then
			return "diamond"
		elseif q(self,"isEnemy",judge.who) and string.find(choices,"club") then
			return "spade"
		elseif q(self,"isEnemy",judge.who) and string.find(choices,"5") then
			return "5"
		end
	elseif judge.reason == "eight_diagram" then
		if q(self,"isFriend",judge.who) and string.find(choices,"diamond") then
			return "diamond"
		elseif q(self,"isEnemy",judge.who) and string.find(choices,"club") then
			return "club"
		end
	end

	local canchoose = choices:split("+")
	return canchoose[1]
end

sgs.ai_need_damaged.spjilve = function (self, attacker, player)
	if not q(player,"hasSkill","spjilve") then return end

	local will = false
	for _, p in ipairs(self.enemies) do
		if q(p,"faceUp") then
			will = true
			break
		end
	end
	for _,p in ipairs(self.friends) do
		if not q(p,"faceUp") then
			will = true
			break
		end
	end
	local n = q(self.player,"getHp") + q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Peach")

	return n > 2 and will
end







sgs.ai_skill_choice["splianpo"] = function(self, choices, data)
	if q(self.player,"getHp") == 1 then return "redr" end
	local canchoose = choices:split("+")
	return canchoose[1]
end


sgs.ai_fill_skill.sppingxiang=function(self,inclusive,request)
	if q(self.player,"getMark","sppingxiang") == 0 and q(self.player,"getMaxHp") >= 10 then
		return parse(self,"#sppingxiang:.:")
	elseif q(self.player,"getMaxHp") > 4 and (not q(self.player,"hasUsed","#sppingxiangSlash")) and q(self.player,"getMark","sppingxiang") > 0 then
		return parse(self,"#sppingxiangSlash:.:")
	end
end

sgs.ai_skill_use_func["#sppingxiang"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_use_func["#sppingxiangSlash"] = function(card, use, self)
	local qtargets = sgs.PlayerList()
    
    local slash = named(self,"sppingxiang","fire_slash",{})

	q(self,"sort",self.enemies, "defense")
	local target = {}
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"isAlive") and q(slash,"targetFilter",qtargets, enemy, self.player) and (not q(self.player,"isProhibited",enemy, slash, qtargets)) and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)  then 
			qtargets:append(enemy)
			table.insert(target,q(enemy,"objectName"))
		end
	end
	
	if #target > 0 then
		local card_str = string.format("#sppingxiangSlash:.:->%s", table.concat(target,"+"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to = qtargets
		end
	end
end

sgs.ai_skill_use["@@sppingxiang"] = function(self, prompt)
	local qtargets = sgs.PlayerList()
    
    local slash = named(self,"sppingxiang","fire_slash",{})

	q(self,"sort",self.enemies, "defense")
	local target = {}
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"isAlive") and q(slash,"targetFilter",qtargets, enemy, self.player) and (not q(self.player,"isProhibited",enemy, slash, qtargets)) then 
			qtargets:append(enemy)
			table.insert(target,q(enemy,"objectName"))
		end
	end
	
	if #target > 0 then
		local card_str = string.format("#sppingxiangSlash:.:->%s", table.concat(target,"+"))
		return response(self,card_str)
	else 
		return "."
	end
end


sgs.ai_skill_invoke.spjiufa = true



sgs.ai_skill_use["@@spjiufa"] = function(self, prompt)
	local card_ids = tagids(self,"spjiufalist")
	local canuse = {}
    for _,id in sgs.qlist(card_ids) do
        local card = face(self,id)
        if q(card,"isAvailable",self.player) then
            table.insert(canuse, card)
        end
    end
    if #canuse == 0 then return "." end

	q(self,"sortByUseValue",canuse)
    for _,card in ipairs(canuse) do

		local use = {isDummy=true,to=sgs.SPlayerList()}
		q(self,"useCardByClassName",card, use)
        if use.card then
            if use.to and use.to:length() > 0 then
                local tos = {}
                for _,p in sgs.qlist(use.to) do
                    table.insert(tos, q(p,"objectName"))
                end

				return response(self,string.format("#spjiufa:%s:->%s", q(card,"getId"), table.concat(tos,"+")))
            end
        end
    end
    return "."
end


sgs.ai_skill_playerchosen.miyund = function(self, targets)
	if q(self.player,"hasFlag","miyunget") then
		for _,p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) then
				return p
			end
		end
	elseif q(self.player,"hasFlag","miyungive1") then
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) then
				return p
			end
		end
	elseif q(self.player,"hasFlag","miyungive2") then
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) then
				return p
			end
		end
		return nil
	end
	for _,p in sgs.qlist(targets) do
		return p
	end
end

sgs.ai_use_revises.miyund = function(self,card,use)
	if q(card,"hasFlag","miyunsafe") and q(self.player,"getHp") > 1 then
		return false 
	end
end

sgs.ai_cardneed.miyund = function(to,card,self)
	return q(card,"hasFlag","miyunsafe")
end
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|miyund"

sgs.ai_fill_skill.danyind=function(self,inclusive,request)
	if q(self.player,"getMark","danyind-Clear") > 0 then return end
	local handcards = q(self.player,"getCards","he")
	handcards = q(self,"sortByKeepValue",handcards) -- 按保留值排序
	if q(self,"getCardsNum","Peach") == 0 then
		for _, h in ipairs(handcards) do
			if q(h,"hasFlag","miyunsafe") then
				local slash = named(self,"danyind","Peach",{})
				if q(slash,"isAvailable",self.player)
				then return slash end
			end
		end
	end
	if q(self,"getCardsNum","Slash") == 0 then
		for _, h in ipairs(handcards) do
			if q(h,"hasFlag","miyunsafe") then
				local slash = named(self,"danyind","Slash",{})
				if q(slash,"isAvailable",self.player)
				then return slash end
			end
		end
	end
end

sgs.ai_guhuo_card.danyind = function(self,toname,class_name)
    if q(self.player,"getMark","danyind-Clear") > 0 then return end
	local current = q(self.room,"getCurrent")
	if current and q(self,"isFriend",current) then
	else
		if class_name and q(self,"getCardsNum",class_name) > 0 then return end
	end
	local card = evaluation(self,toname)
	
	if (not card) or (not q(card,"isKindOf","BasicCard")) then return end
	local handcards = q(self.player,"getCards","he")
	handcards = q(self,"sortByKeepValue",handcards) -- 按保留值排序
	for _, h in ipairs(handcards) do
		if q(h,"hasFlag","miyunsafe") then
			local slash = named(self,"danyind",toname,{})
			return descriptor(slash)
		end
	end
end

sgs.ai_card_priority.danyind = function(self,card)
	if q(card,"hasFlag","miyunsafe")
	then return -0.05 end
end


sgs.ai_skill_invoke.sphaochong = function(self, data)
	if q(self.player,"getHandcardNum") == 0 then return true end
	if q(self.player,"getPhase") ~= sgs.Player_NotActive then return true end
	local n = 0
	local cards = {"peach", "jink", "analeptic", "nullification"}
	for _,p in sgs.qlist(q(self.player,"getHandcards")) do
		if table.contains(cards, q(p,"objectName")) then
			n = n + 1
		end
	end
	if n < 2 then return true end
    return false 
end

sgs.ai_skill_invoke.spjinjin = function(self, data)
	if q(self.player,"getHandcardNum") < q(self.player,"getMaxCards") then
		return true
	elseif q(self.player,"getHandcardNum") > q(self.player,"getMaxCards") then
		local n = q(self.player,"getHandcardNum") - q(self.player,"getMaxCards") 
		if n > 2 then return false end
		return true
	end
    return false 
end
sgs.ai_skill_choice["spjinjin"] = function(self, choices, data)
	local source = q(data,"toPlayer")
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if table.contains(items, "recover") and q(self,"isWeak",source) and source:isWounded() and source:getHp() < getBestHp(source) then
			return
			"recover"
		end
		local choice1 = getChoice(choices, "damage")
		if choice1 and ((q(self,"isFriend",source) and q(self,"needToLoseHp",source, self.player, nil)) or (q(self,"isEnemy",source) and not q(self,"cantbeHurt",source) and q(self,"damageIsEffective",source, sgs.DamageStruct_Normal) and q(self,"canDamage",source,self.player,nil))) then
			return choice1
		end
	end
	return "recover"
end

sgs.ai_can_damagehp.spjinjin = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to) and ((q(self.player,"getMaxCards") - q(self.player,"getHandcardNum") > 2) or ((q(self.player,"getHandcardNum") -  q(self.player,"getMaxCards")> 0) and from and q(self,"isEnemy",from) and q(self,"isWeak",from) and q(self,"damageIsEffective",from, sgs.DamageStruct_Normal)))
end


sgs.ai_skill_invoke.spjinjin = function(self, data)
	if q(self.player,"getHandcardNum") < q(self.player,"getMaxCards") then return true end
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","spjinjintarget") then
			target = p
			break
		end
	end
	local save = q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","peach")
	local n = q(self.player,"getHandcardNum") - q(self.player,"getMaxCards")
	if q(self.player,"isWounded") then
		if n <= 1 then return true end
		if q(self.player,"getMaxCards") + 1 >= save then return true end
		if q(self.player,"containsTrick","indulgence") and q(self.player,"getHp") <= 1 and q(self,"getCardsNum","Nullification") < 1 then return true end
	end
	if not target then
		return false 
	elseif target then
		if q(self,"isEnemy",target) and n <= 2 then return true end
	end
	return false
end

sgs.ai_skill_choice["spjinjin"] = function(self, choices, data)
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","spjinjintarget") then
			target = p
			break
		end
	end
	if target and q(self,"isEnemy",target) and q(target,"getHp") <= 1 and q(self.player,"getLostHp") < 2 then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "damage") then
				return choice
			end
		end
	end
	if (q(self.player,"getLostHp") >= 2) or (not target) then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "recover") then
				return choice
			end
		end
	end
	if target and q(self,"isEnemy",target) then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "damage") then
				return choice
			end
		end
	end
	for _,choice in ipairs(choices:split("+")) do
		return choice
	end
end


sgs.ai_fill_skill.hfgushi=function(self,inclusive,request)
	local card = nil
	if q(self.player,"getMark","&hfgushi-PlayClear") == 0 then
		card = q(self,"evaluateOwnerViewAsCard",{source_key="hfgushi",name="peach",skill="hfgushi",suit=sgs.Card_SuitToBeDecided,number=-1,subcards={}})
	elseif q(self.player,"getMark","&hfgushi-PlayClear") == 1 then
		card = q(self,"evaluateOwnerViewAsCard",{source_key="hfgushi",name="ex_nihilo",skill="hfgushi",suit=sgs.Card_SuitToBeDecided,number=-1,subcards={}})
	elseif q(self.player,"getMark","&hfgushi-PlayClear") == 2 then
		card = q(self,"evaluateOwnerViewAsCard",{source_key="hfgushi",name="duel",skill="hfgushi",suit=sgs.Card_SuitToBeDecided,number=-1,subcards={}})
	end
	if not card then return end
	
	if card and q(card,"isAvailable",self.player) then
		local card_str = nil
		if q(self.player,"getMark","&hfgushi-PlayClear") == 0 then
			card_str = string.format("peach:hfgushi[%s:%s]=.", "no_suit", 0)
		elseif q(self.player,"getMark","&hfgushi-PlayClear") == 1 then
			card_str = string.format("ex_nihilo:hfgushi[%s:%s]=.", "no_suit", 0)
		elseif q(self.player,"getMark","&hfgushi-PlayClear") == 2 then
			card_str = string.format("duel:hfgushi[%s:%s]=.", "no_suit", 0)
		end
		local spec = printed(card_str,self)
        local classes={peach="Peach",ex_nihilo="ExNihilo",duel="Duel"}
        local usec = q(self,"evaluateTurnConversion","hfgushi",classes[spec.name],spec,request)
		return usec
	end
end

sgs.ai_card_priority.hfgushi = function(self,card)
	if table.contains(q(card,"getSkillNames"), "hfgushi")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_use_priority.hfgushi = sgs.ai_use_priority.Peach + 0.1


sgs.ai_skill_askforag["hflanggu"] = function(self, card_ids)
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","hflanggutarget") then
			target = p
			break
		end
	end
	local can = false
	for _,id in ipairs(card_ids) do
		local card = face(self,id)
		if q(card,"getSuitString") == "spade" and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9 then
			can = true
		end
	end
	if not can  then
		local choosecards = {}
		for _,id in ipairs(card_ids) do
			local card = face(self,id)
			table.insert(choosecards,card)
		end

		q(self,"sortByKeepValue",choosecards, true)
    	return choosecards[#choosecards]:getEffectiveId()
	else 
		if q(self,"isEnemy",target) then
			for _,id in ipairs(card_ids) do
				local card = face(self,id)
				if q(card,"getSuitString") == "spade" and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9 then
				else return id end
			end
		else
			for _,id in ipairs(card_ids) do
				local card = face(self,id)
				if q(card,"getSuitString") == "spade" and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9 then
					return id 
				end
			end
		end
	end
end


sgs.ai_fill_skill.dyizheng=function(self,inclusive,request)
	if q(self.player,"hasUsed","#dyizheng") then return end
	return parse(self,"#dyizheng:.:")
end

sgs.ai_skill_use_func["#dyizheng"] = function(card, use, self)
	local max_card = q(self,"getMaxCard")
	if not max_card then return end
	local point = max_card:getNumber()
	if q(self.player,"hasSkill","tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
	if (((q(self.player,"getHp") <= 2) or (known(facts(self).swap_pile,"SwapPile") ~= 0)) and point >=10) or point >= 7 or (q(self.player,"getHp") > 2 and known(facts(self).swap_pile,"SwapPile") == 0) then
		q(self,"sort",self.enemies, "handcard")
		for _, p in ipairs(self.enemies) do
			if not q(self.player,"canPindian",p)  then continue end
			local card_str = string.format("#dyizheng:.:->%s",q(p,"objectName"))
			local acard = parse(self,card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(p)
			end
			return
		end
	end
end

function sgs.ai_skill_pindian.dyizheng(minusecard, self, requestor)
	local maxcard = q(self,"getMaxCard")
	return q(self,"isFriend",requestor) and q(self,"getMinCard") or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_use_priority.dyizheng = 6
sgs.ai_use_value.dyizheng = 2
sgs.ai_card_intention["#dyizheng"] = 50


sgs.ai_skill_invoke.drangjie = function(self, data)
	if not q(self.room,"canMoveField","ej") and not q(self,"canDraw") then return false end
	if q(self,"canDraw") then return true end
	local from, card, to = q(self,"moveField")
	if from and card and to then return true end
	return false
end

sgs.ai_skill_choice.drangjie = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "move") then
		local from, card, to = q(self,"moveField")
		if from and card and to then return "move" end
		return "draw"
	else
		return "hand"
	end
end

sgs.ai_skill_use["@@drangjie"] = function(self, prompt)
	local card_ids = tagids(self,"drangjiecards")
	local cards = {}
	for _,id in sgs.qlist(card_ids) do
		table.insert(cards,face(self,id))
	end

	q(self,"sortByKeepValue",cards)
	local card_str = "#drangjie:"..cards[#cards]:getEffectiveId()..":"
	return response(self,card_str)
end

sgs.ai_skill_playerchosen.drangjie = function(self, targets)
	q(self,"sort",self.friends, "defense")
	return self.friends[1]
end

sgs.ai_playerchosen_intention.drangjie = function(self, from, to)
	if q(from,"hasFlag","drangjiejud") then
		q(self,"updateIntention",from, to, 60)
	else
		q(self,"updateIntention",from, to, -60)
	end
end

sgs.ai_can_damagehp.drangjie = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
end


sgs.ai_fill_skill.dwzhizhe=function(self,inclusive,request)
	if q(self.player,"getMark","dwzhizheused") == 0 then
		local names = {"peach", "nullification", "archery_attack", "savage_assault", "snatch", "fire_attack", "duel", "dismantlement"}
		if q(self.player,"getHandcardNum") == 0 then return end
		for _,card in sgs.qlist(q(self.player,"getHandcards")) do
			if table.contains(names, q(card,"objectName")) then
				return parse(self,"#dwzhizhe:.:")
			end
		end
		return
	end
	if q(self.player,"getMark","dwzhizhe-Clear") > 0 then return end
	local pattern = prop(self,"dwzhizheshow")
	local card_str = string.format("%s:dwzhizhe[%s:%s]=.", pattern,"no_suit", 0)
	local usec = parse(self,card_str)
	assert(usec)
	return usec
end

sgs.ai_skill_use_func["#dwzhizhe"] = function(card, use, self)
	local handcards = q(self.player,"getCards","h")
	handcards = sgs.QList2Table(handcards)
	local usecard
	q(self,"sortByUseValue",handcards, source_inverse(self))
	local names = {"peach", "nullification", "archery_attack", "savage_assault", "snatch", "fire_attack", "duel", "dismantlement"}
	for _,card in ipairs(handcards) do
		if table.contains(names, q(card,"objectName")) then
			usecard = card
			break
		end
	end

	if usecard then
		local card_str = string.format("#dwzhizhe:%d:", q(usecard,"getId"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
	end
end

sgs.ai_cardsview_valuable.dwzhizhe = function(self, class_name, player)
	if q(self.player,"getMark","dwzhizhe-Clear") > 0 then return end
	if q(self.player,"getMark","dwzhizheused") == 0 then return end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
		["Nullification"] = "nullification",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local pattern = prop(self,"dwzhizheshow")
	if string.find(pattern, name) or pattern == name or string.find(name, pattern) then
		return view(self,string.format("%s:dwzhizhe[%s:%s]=.", pattern,"no_suit", 0))
	end
	return
end

sgs.ai_use_priority.dwzhizhe = 8

sgs.ai_card_priority.dwzhizhe = function(self,card)
	if table.contains(q(card,"getSkillNames"), "dwzhizhe")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


sgs.ai_skill_invoke.dwqingshi = true

sgs.ai_skill_choice["dwqingshi"] = function(self, choices, data)
	choices = choices:split("+")
	local names = {"slash", "thunder_slash", "fire_slash", "fire_attack", "duel", "archery_attack", "savage_assault"}

	if q(self.player,"getMark","dwqingshiuseai") > 0 then
		local use = taguse(self,"dwqingshiuseai")
		if not table.contains(names,q(use.card,"objectName")) then
			local canuse = false
			local num = 0
			for _,card in sgs.qlist(q(self.player,"getHandcards")) do
				if not q(card,"isAvailable",self.player) then break end
				canuse = true
				if q(card,"objectName") == q(use.card,"objectName") then num = num + 1 end
			end
			if (#self.friends == 2 and q(self.player,"getHandcardNum") >3) 
			or (#self.friends > 2) 
			or (canuse and num > 1) then
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawall") then
						return choice
					end
				end
			else
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawself") then
						return choice
					end
				end
			end
		else
			local canuse = false
			local num = 0
			for _,card in sgs.qlist(q(self.player,"getHandcards")) do
				if not q(card,"isAvailable",self.player) then break end
				canuse = true
				if q(card,"objectName") == q(use.card,"objectName") 
				or (q(card,"isKindOf","Slash") and q(use.card,"isKindOf","Slash"))
				then num = num + 1 end
			end
			local enemynum = 0
			local weakenemy = false
			for _,p in sgs.qlist(use.to) do
				if q(self,"isEnemy",p) then
					enemynum = enemynum + 1
					if q(p,"getHp") <= 2 or q(p,"getHandcardNum") <= 2 then
						weakenemy = true
					end
				end
			end
			if (enemynum > 1) or (canuse and num > 1) or weakenemy then
				for _,choice in ipairs(choices) do
					if string.find(choice, "damage") then
						return choice
					end
				end
			end

			if (#self.friends == 2 and q(self.player,"getHandcardNum") >3) 
			or (#self.friends > 2) 
			or (canuse and num > 1) then
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawall") then
						return choice
					end
				end
			else
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawself") then
						return choice
					end
				end
			end
		end
	else
		if (#self.friends == 2 and q(self.player,"getHandcardNum") >3) 
			or (#self.friends > 2) then
			for _,choice in ipairs(choices) do
				if string.find(choice, "drawall") then
					return choice
				end
			end
		else
			for _,choice in ipairs(choices) do
				if string.find(choice, "drawself") then
					return choice
				end
			end
		end
	end
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_use["@@dwqingshi"] = function(self, prompt)
	local targets = {}
	if q(self.player,"hasFlag","dwqingshidrawall") then
		for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(self,"isFriend",p) then
				table.insert(targets,q(p,"objectName"))
			end
		end
	elseif q(self.player,"hasFlag","dwqingshidamage") then
		for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(self,"isEnemy",p) and q(p,"hasFlag","dwqingshiupcan") then
				table.insert(targets,q(p,"objectName"))
			end
		end
	end
	if #targets > 0 then
		local card_str = string.format("#dwqingshi:.:->%s", table.concat(targets,"+"))
		return response(self,card_str)
	else 
		return "."
	end
end

sgs.ai_card_intention.dwqingshi = function(self, card, from, tos)
	if q(from,"hasFlag","dwqingshidrawall") then
		for _,to in ipairs(tos) do
			q(self,"updateIntention",from, to, -40)
		end
	else
		for _,to in ipairs(tos) do
			q(self,"updateIntention",from, to, 60)
		end
	end
end
sgs.ai_ajustdamage_from.dwqingshi = function(self, from, to, card, nature)
	if card and q(card,"hasFlag","dwqingshidamage") then
		local names = cardtag(self,card,"dwqingshitarget"):split("+")
		if table.contains(names, q(to,"objectName")) then
			return 1
		end
	end
end


sgs.ai_skill_invoke.dwjingcui = function(self, data)
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") <= 0 then 
			target = p
			break
		end
	end
	if not q(self,"isFriend",target) then return false end
	local n = nil
	if q(target,"objectName") ~= q(self.player,"objectName") then
		n = q(self,"getCardsNum","Peach")
		for _,card in sgs.qlist(fullhand(target)) do
			if q(card,"objectName") == "peach" or q(card,"objectName") == "analeptic" then n = n + 1 end
		end
		if q(self.player,"getMark","dwzhizheused") > 0 then
			if q(self.player,"getMark","dwzhizhe-Clear") == 0 then
				local pattern = prop(self,"dwzhizheshow")
				if pattern == "peach" then n = n + 1 end
			end
		end
	else
		n = q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic")
		if q(self.player,"getMark","dwzhizheused") > 0 then
			if q(self.player,"getMark","dwzhizhe-Clear") == 0 then
				local pattern = prop(self,"dwzhizheshow")
				if pattern == "peach" or pattern == "analeptic" then n = n + 1 end
			end
		end
	end
	if n >= 1 - q(target,"getHp") then return false end
	return true
end


sgs.ai_skill_playerchosen.spzhiheng =  function(self, targets)
	for _,p in sgs.qlist(targets) do
		if q(self.player,"getMark","spzhihenggood") > 0 then
			if q(self,"isFriend",p) then return p end
		elseif q(self,"isEnemy",p) then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.spzhiheng = function(self, from, to)
	if q(from,"getMark","spzhihenggood") > 0 then
		q(self,"updateIntention",from, to, -80)
	else
		q(self,"updateIntention",from, to, 80)
	end
end


sgs.ai_skill_invoke.shouchang = true

sgs.ai_skill_discard.shouchang = function(self,max,min)
	local dis = {}
	local red = {}
    local black = {}
    for _,card in sgs.qlist(q(self.player,"getHandcards")) do
        if q(card,"isRed") then
            table.insert(red, card)
        elseif q(card,"isBlack") then
            table.insert(black, card)
        end
    end


	if q(self.player,"getPhase") ~= sgs.Player_NotActive then
		q(self,"sortByUseValue",red, true)
		q(self,"sortByUseValue",black, true)
	else
		q(self,"sortByKeepValue",red)
		q(self,"sortByKeepValue",black)
	end
	if q(self.player,"getPhase") == sgs.Player_Play and q(self.player,"getHandcardNum") > 10 and #red > 0 then
		table.insert(dis, red[1]:getEffectiveId())
		return dis
	end
	if #red > #black then
		table.insert(dis, red[1]:getEffectiveId())
	elseif #black > #red then
		table.insert(dis, black[1]:getEffectiveId())
	end
	return dis
end


sgs.ai_skill_choice["Djianxiong"] = function(self, choices, data)
	choices = choices:split("+")
	if q(self.player,"getLostHp") <= 2 and q(self.player,"getHandcardNum") <= 2 then
		return "draw"
	end
	if table.contains(choices, "recover") then
		return "recover"
	end
	return choices[1]
end

sgs.ai_can_damagehp.Djianxiong = function(self, from, card, to)
	return  (card and not q(card,"isKindOf","SkillCard"))
		and q(self,"canLoseHp",from, card, to)
end


sgs.ai_skill_playerchosen.dmwumei = function(self,players)
	local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	q(self,"sort",destlist,"handcard",true)
	for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target) and q(target,"getHandcardNum") > q(self.player,"getHandcardNum") + 2
		then return target end
	end
	return self.player
end

sgs.ai_playerchosen_intention.dmwumei = function(self, from, to)
	q(self,"updateIntention",from, to, -100)
end


sgs.ai_skill_invoke.dmzhanmeng = function(self,data)
	local allchoices = {"recover", "draw", "discard"}
    local choices = {}
    for _,cc in ipairs(allchoices) do
        if q(self.player,"getMark","dmzhanmeng"..cc.."-Clear") == 0 then
            table.insert(choices, cc)
        end
    end
	if table.contains(choices, "recover") then
		local wumeiextra = false
		local wounded = false
		local danger = false
		local nofaceup = false
		local chained = false
		for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(p,"getMark","&dmwumei-SelfClear") > 0 then wumeiextra = true end
			if q(self,"isFriend",p) then
				if q(p,"isWounded") then
					wounded = true
					if q(p,"getHp") == 1 then danger = true end
				end
				if q(p,"isChained") then chained = true end
				if not q(p,"faceUp") then nofaceup = true end
			end
		end
		if nofaceup or ((not wumeiextra) and wounded) or chained or (wumeiextra and danger) then return true end
	end
	if table.contains(choices, "draw") then return true end
	if table.contains(choices, "discard") then
		for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(self,"isEnemy",p) and q(p,"canDiscard",p, "he")  and q(self,"damageIsEffective",p, sgs.DamageStruct_Fire) and not q(self,"cantbeHurt",p) and q(self,"canDamage",p,self.player,nil) then return true end
		end
	end
	return false
end

sgs.ai_skill_choice.dmzhanmeng = function(self,choices,data)
	local items = choices:split("+")

	local wumeiextra = false
	local wounded = false
	local danger = false
	local nofaceup = false
	local chained = false
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getMark","&dmwumei-SelfClear") > 0 then wumeiextra = true end
		if q(self,"isFriend",p) then
			if q(p,"isWounded") then
				wounded = true
				if q(p,"getHp") == 1 then danger = true end
			end
			if q(p,"isChained") then chained = true end
			if not q(p,"faceUp") then nofaceup = true end
		end
	end
		
	if table.contains(items, "recover") then
		if nofaceup or danger then return "recover" end
	end

	if table.contains(items, "draw") and wumeiextra then return "draw" end

	if table.contains(items, "discard") then
		for _,p in ipairs(self.enemies) do
			if q(p,"canDiscard",p, "he") then return "discard" end
		end
	end

	if table.contains(items, "recover") then
		if wounded and (not wumeiextra) then return "recover" end
	end

	if table.contains(items, "draw") then return "draw" end

	if table.contains(items, "recover") then
		if chained then return "recover" end
	end

	return items[math.random(1, #items)]
end

sgs.ai_playerchosen_intention.dmzhanmeng = function(self, from, to)
	if q(from,"hasFlag","dmzhanmenggood") then
		q(self,"updateIntention",from, to, -80)
	else
		q(self,"updateIntention",from, to, 100)
	end
end

sgs.ai_skill_playerchosen.dmzhanmeng = function(self, targets)
	if q(self.player,"hasFlag","dmzhanmenggood") then
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and (not q(p,"faceUp")) then return p end
		end
		local min = -1
		local target = nil
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and ((min == - 1) or q(p,"getHp") < min) and q(p,"isWounded") then 
				target = p
				min = q(p,"getHp")
			end
		end
		if target then return target end
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and q(p,"isChained") then return p end
		end
	else
		q(self,"sort",self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if q(p,"canDiscard",p, "he") then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not q(self,"isFriend",p) then return p end
		end
	end
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|dmshenyou"


sgs.ai_fill_skill.godlongnu=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	q(self,"sortByUseValue",cards,true)
	for _, card in ipairs(cards) do

		local slash = nil

		if q(card,"isRed") and ((q(self.player,"getMark","&godlongnu+:+fire_slash-PlayClear") > 0) or (q(self.player,"getMark","&godlongnuall-PlayClear") > 0) ) then
			slash = q(self,"evaluateTurnConversion","godlongnu","FireSlash",{name="fire_slash",skill="godlongnu",suit=-1,number=-1,subcards={q(card,"getEffectiveId")}},request)
			if not q(slash,"isAvailable",self.player) then slash = nil end
		end

		if q(card,"isBlack") and ((q(self.player,"getMark","&godlongnu+:+thunder_slash-PlayClear") > 0) or (q(self.player,"getMark","&godlongnuall-PlayClear") > 0) ) then
			slash = q(self,"evaluateTurnConversion","godlongnu","ThunderSlash",{name="thunder_slash",skill="godlongnu",suit=-1,number=-1,subcards={q(card,"getEffectiveId")}},request)
			if not q(slash,"isAvailable",self.player) then slash = nil end
		end

		if slash and q(card,"isRed") then
			local spec=printed(("fire_slash:godlongnu[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")),self)
			return q(self,"evaluateTurnConversion","godlongnu","FireSlash",spec,request)
		elseif slash and q(card,"isBlack") then
			local spec=printed(("thunder_slash:godlongnu[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")),self)
			return q(self,"evaluateTurnConversion","godlongnu","ThunderSlash",spec,request)
		end
	end
end

sgs.ai_skill_choice["godlongnu"] = function(self, choices, data)
	local n = q(self.player,"getHp") + q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic")
	if #self.enemies > 0 and n > 1 and q(self.player,"getMaxHp") > 2 then
		q(self,"sort",self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if q(p,"getHp") <= 2 then
				return "all"
			elseif q(p,"getHandcardNum") < 2 and q(p,"getHp") <= 3 then
				return "all"
			end
		end
		for _,cc in sgs.qlist(q(self.player,"getHandcards")) do
			if q(cc,"objectName") == "crossbow" then return "all" end
		end
		for _,cc in sgs.qlist(q(self.player,"getEquips")) do
			if q(cc,"objectName") == "crossbow" then return "all" end
		end
	end
	if q(self.player,"getLostHp") < 3 and q(self.player,"getHp") > 1 then return "red" end
	if q(self.player,"getLostHp") >= 3 then return "black" end
	if q(self.player,"getHp") == 1 and (q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0) then return "red" end
	if q(self.player,"getHp") == 1 and q(self.player,"isWounded") then return "black" end
	if q(self.player,"getMaxHp") == 1 then return "red" end
	choices = choices:split("+")
	table.removeOne(choices, "all")
	return  choices[math.random(1, #choices)]
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|godlongnu"


sgs.ai_skill_playerchosen.godjieyin = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		if not q(self,"isFriend",p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		return p
	end
end
sgs.ai_target_revises.godjieyin = function(to,card,self,use)
    if q(card,"isKindOf","IronChain") then return true end
end


sgs.ai_playerchosen_intention.godjieyin = function(self, from, to)
	q(self,"updateIntention",from, to, 30)
end

sgs.ai_suppress_intention["xiaoyizi"] = true
sgs.ai_skill_playerchosen.xiaorenfu = function(self, targets)
	if q(self.player,"hasFlag","xiaoyifu") then
		local slash = named(self,"_xiaoyizi","slash",{})
		
		for _,p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) and q(self,"slashIsEffective",slash, p, self.player) and q(self,"isGoodTarget",p, self.enemies, slash) then return p end
		end
		return nil
	end
	local max = -1
	local yifu = nil
	for _,p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) and (max == -1 or (q(p,"getHandcardNum") + q(p,"getEquips"):length() > max)) then
			yifu = p
			max = q(p,"getHandcardNum") + q(p,"getEquips"):length()
		end
	end
	if yifu then return yifu end
	for _,p in sgs.qlist(targets) do
		return p
	end
end

sgs.ai_playerchosen_intention.xiaorenfu = function(self, from, to)
	q(self,"updateIntention",from, to, 80)
end

sgs.ai_skill_invoke.xiaorenfu = function(self, data)
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(p,"hasFlag","old_yifuta") then
			target = p
			break
		end
	end
	if target and (not q(self,"isFriend",target) and q(self,"damageIsEffective",target, sgs.DamageStruct_Normal) and not q(self,"cantbeHurt",target) and q(self,"canDamage",target,self.player,nil)) then return true end
	return false
end

sgs.ai_ajustdamage_from.xiaorenfu = function(self, from, to, card, nature)
	if card and q(card,"isKindOf","Slash") and from and q(to,"getMark","xiaoyifufrom"..from:objectName()) > 0
	then
		return 1
	end
end


sgs.ai_skill_invoke.xiaosheji = function(self, data)
	local from = nil
	local to = nil
	for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(p,"hasFlag","shejifrom") then
			from = p
		elseif q(p,"hasFlag","shejito") then
			to = p
		end
	end
	local slash = named(self,"xiaosheji","slash",{})
	if (not q(self,"isFriend",from)) and (not q(self,"isEnemy",to) and q(self,"slashIsEffective",slash, from, self.player) and q(self,"isGoodTarget",from, self.enemies, slash)) then return true end
	return false
end


sgs.ai_skill_playerchosen.doubleneifa = function(self, targets)
	if q(self.player,"hasSkill","doubleneifa") then
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and q(p,"getJudgingArea"):length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) and q(p,"getEquips"):length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) and q(p,"getMark","&doubleneifa") > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not q(self,"isFriend",p) then return p end
		end
		for _,p in sgs.qlist(targets) do
			return p
		end
	else
		for _,p in sgs.qlist(targets) do
			if q(self,"isFriend",p) and q(p,"getJudgingArea"):length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not q(self,"isFriend",p) then return p end
		end
		if q(self.player,"getHandcardNum") > 1 then return self.player end
		return nil
	end
end

sgs.ai_playerchosen_intention.doubleneifa = function(self, from, to)
	if q(to,"getJudgingArea"):length() > 0 then
		q(self,"updateIntention",from, to, -40)
	else
		q(self,"updateIntention",from, to, 40)
	end
end


sgs.ai_skill_askforag["wwguixin"] = function(self, card_ids)
	local cards = {}
	for _,id in ipairs(card_ids) do
		local card = face(self,id)
		table.insert(cards, card)
	end

	q(self,"sortByKeepValue",cards)
    return cards[1]:getEffectiveId()
end


sgs.ai_fill_skill.jfjifeng=function(self,inclusive,request)
	if q(self.player,"getMark","jfjifengfailed-PlayClear") > 0 then return end
	local fire_attack = named(self,"jfjifeng","fire_attack",{})
	if fire_attack and q(fire_attack,"isAvailable",self.player) then
		local card_str = nil
		card_str = string.format("fire_attack:jfjifeng[%s:%s]=.", "no_suit", 0)
		local usec = parse(self,card_str)
		assert(usec)
		return usec
	end
end

sgs.ai_skill_use["@@jfjifeng"] = function(self, prompt)
	local dis = nil
	local card_ids = tagids(self,"jfjifengai")
	local suit = prop(self,"jfjifengsuit")
	for _,id in sgs.qlist(card_ids) do
		local cc = face(self,id)
		if q(cc,"getSuitString") == suit then
			dis = cc
			break
		end
	end
	if not dis then
		local cards = sgs.QList2Table(q(self.player,"getCards","h"))

		q(self,"sortByKeepValue",cards)
		for _,cc in ipairs(cards) do
			if q(cc,"getSuitString") == suit then
				dis = cc
				break
			end
		end
	end
	if dis then
		return response(self,"#jfjifengdis:"..dis:getEffectiveId()..":")
	else
		return "."
	end
end

sgs.ai_ajustdamage_to["&jfjifeng"] = function(self, from, to, card, nature)
	if nature == sgs.DamageStruct_Fire
	then
		return 1
	end
end

sgs.ai_ajustdamage_to.jfyueyin = function(self, from, to, card, nature)
	local can_invoke = false
	if (not card) or (card and q(card,"isKindOf","SkillCard")) then can_invoke = true end
	if card and (not q(card,"isKindOf","SkillCard")) then
		local ctype = source_type(card)
		if q(to,"getMark","jfyueyin"..ctype.."-Clear") > 0 then
			can_invoke = true
		end
	end
	if can_invoke then
		return -999
	end
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|jfqixing"

sgs.ai_skill_playerchosen.jfqixing = function(self, targets)
	if q(self.player,"getRole") == "loyalist" then
		for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if role(self,p) == "lord" then
				return p
			end
		end
	end
	q(self,"sort",self.friends, "hp")
	for _,p in ipairs(self.friends) do
		if q(p,"isAlive") then
			return p
		end
	end
	return nil
end


sgs.ai_skill_invoke.xrxiaorui = function(self, data)
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","xrxiaoruitarget") then
			target = p
			break
		end
	end
	local slash = named(self,"xrxiaorui","slash",{})
	
	if q(self,"isEnemy",target) and q(self,"slashIsEffective",slash, target, self.player) and q(self,"isGoodTarget",target, self.enemies, slash) then return true end
	return false
end

sgs.ai_skill_use["@@xrxiaorui"] = function(self, prompt)
	local target = nil
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","xrxiaoruitarget") then
			target = p
			break
		end
	end
	if not target then return "." end
	local cards = sgs.QList2Table(fullhand(target))
	q(self,"sortByKeepValue",cards, source_inverse(self))
	if #cards > 0 then
		return response(self,"#xrxiaorui:"..cards[#cards]:getEffectiveId()..":")
	end
	return "."
end


sgs.ai_skill_invoke.xrshanjia = true

sgs.ai_skill_use["@@xrshanjia"] = function(self, prompt)
	local slash = named(self,"xrshanjia","slash",{})
	local targets = {}

	local dummy_use = q(self,"aiUseCard",slash, dummy())
	if dummy_use.card then
        if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, q(p,"objectName"))
			end
		end
	end
    

	if #targets > 0 then
		local card_str = string.format("#xrshanjia:.:->%s",  table.concat(targets, "+"))
		return response(self,card_str)
	end
	return "."
end
sgs.ai_use_revises.xrshanjia = function(self,card,use)
	if q(card,"isKindOf","EquipCard") and q(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|xrshanjia"
-- audited alias ai_cardneed.xrshanjia
sgs.ai_skill_invoke.cqtieji = function(self, data)
	local target = q(data,"toPlayer")
	return q(self,"isEnemy",target)
end
sgs.ai_choicemade_filter.skillInvoke.cqtieji = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then q(self,"updateIntention",player,target,50) end
	end
end
-- audited alias ai_cardneed.cqtieji
sgs.hit_skill = sgs.hit_skill .. "|cqtieji"

sgs.ai_canliegong_skill.cqtieji = function(self, from, to)
	return true
end


sgs.ai_skill_playerchosen.cqchangqu = function(self, targets)
	q(self,"sort",self.enemies, "defense")
	if #self.enemies == 0 then return nil end
	local slash = named(self,"cqchangqu","slash",{})
	
	for _,p in ipairs(self.enemies) do
		if q(self.player,"inMyAttackRange",p) then
			if not q(p,"inMyAttackRange",self.player) and q(self,"slashIsEffective",slash, p, self.player) and q(self,"isGoodTarget",p, self.enemies, slash) then
				return p
			end
		end
	end
	for _,p in ipairs(self.enemies) do
		if q(self.player,"inMyAttackRange",p) and q(p,"inMyAttackRange",self.player) and q(self,"slashIsEffective",slash, p, self.player) and q(self,"isGoodTarget",p, self.enemies, slash)  then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if q(self,"slashIsEffective",slash, p, self.player) and q(self,"isGoodTarget",p, self.enemies, slash)  then
			return p
		end
	end
	return self.enemies[1]
end

sgs.ai_playerchosen_intention.cqchangqu = function(self, from, to)
	q(self,"updateIntention",from, to, 80)
end


sgs.ai_skill_discard.yzyuzhi = function(self,max,min)
	local cards = q(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	local n = q(self.player,"getHp")
	q(self,"sortByUseValue",cards)
	local max = -1
	local show = {}
	local special = nil
	for _,card in ipairs(cards) do
		local name_number = q(card,"nameLength")
		if q(card,"isKindOf","Slash") then name_number = 1 end
		if name_number > max and name_number <= q(self.player,"getHp") then 
			max = name_number
			special = card
		end
	end
	if special then
		table.insert(show, special:getEffectiveId())
		return show
	end
	for _,card in ipairs(cards) do
		table.insert(show, q(card,"getEffectiveId"))
		return show
	end
end


sgs.ai_skill_use["@@yzxieshu"] = function(self, prompt)
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)

	local n = q(self.player,"getMark","yzxieshu")
	if #cards < n then return "."end
	if (n > q(self.player,"getLostHp") + 1) and q(self.player,"getHp") ~= 1 and q(self.player,"getHandcardNum") < 8 then return "." end
	
	local target = nil
	if q(self.player,"getHp") == 1 and (q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Peach") < 1) then
		target = self.player
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy) and q(self,"canDamage",enemy,self.player,nil) then
				target = enemy
				break
			end
		end
	end

	if not target then
		if #self.enemies == 0 then return "." end
		q(self,"sort",self.enemies, "hp")
		target = self.enemies[1]
	end

	local usecards = {}
	for _,card in ipairs(cards) do
		if #usecards < n then
			table.insert(usecards, q(card,"getEffectiveId"))
		else
			break
		end
	end

	if target then
		local card_str = string.format("#yzxieshu:%s:->%s", table.concat(usecards, "+"), q(target,"objectName"))
		return response(self,card_str)
	else
		return "."
	end
end

sgs.ai_card_intention.yzxieshu = 50

sgs.ai_can_damagehp.yzxieshu = function(self,from,card,to)
	if card and not q(card,"isKindOf","SkillCard") then
		local name_number = q(card,"nameLength")
		if q(card,"isKindOf","Slash") then name_number = 1 end
		if q(to,"getMark","yzxieshu"..name_number.."-Clear") > 0 then return false end

		return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
		and q(self,"canLoseHp",from,card,to) and name_number <= q(to,"getLostHp") + 1 and q(to,"getCards","he"):length() >= name_number
	end
end


sgs.ai_skill_invoke.lgliegong = function(self, data)
	local target = q(data,"toPlayer")
	return q(self,"isEnemy",target)
end

sgs.ai_skill_discard.lgliegong = function(self,max,min)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByKeepValue",cards)
	local dis = {}
	if #cards == 0 then return dis end
	if q(self.player,"containsTrick","indulgence") and (q(self.player,"getHandcardNum") > (q(self.player,"getMaxCards") - 2)) then
		local n = q(self.player,"getHandcardNum") - q(self.player,"getMaxCards") + 3
		local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
		q(self,"sortByKeepValue",handcards)
		for _,card in ipairs(handcards) do
			table.insert(dis, q(card,"getEffectiveId"))
			n = n - 1
			if n <= 0 then break end
		end
	elseif q(self,"getCardsNum","Slash") == 0 then
		table.insert(dis, cards[1]:getEffectiveId())
	end
	return dis
end

sgs.ai_ajustdamage_from.lgliegong = function(self, from, to, card, nature)
	if card and q(card,"isKindOf","Slash") then else return 0 end
	local n = 0
	if q(from,"getHp") <= q(to,"getHp") then n = n + 1 end
	if q(from,"getHandcardNum") <= q(to,"getHandcardNum") then n = n + 1 end
	if q(from,"getEquips"):length() <= q(to,"getEquips"):length() then n = n + 1 end
	if n <= 0 then return false end
	return n
end

sgs.ai_choicemade_filter.skillInvoke.lgliegong = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then q(self,"updateIntention",player,target,50) end
	end
end
-- audited alias ai_cardneed.lgliegong
sgs.hit_skill = sgs.hit_skill .. "|lgliegong"


ai_audited_aliases.register({id="ai_skill_carduse.Dlimu",registry="ai_skill_carduse",path={"Dlimu"},canonical_registry="ai_skill_carduse",canonical_path={"limu"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.Gposhi",registry="ai_cardneed",path={"Gposhi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.xrshanjia",registry="ai_cardneed",path={"xrshanjia"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.cqtieji",registry="ai_cardneed",path={"cqtieji"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lgliegong",registry="ai_cardneed",path={"lgliegong"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})
