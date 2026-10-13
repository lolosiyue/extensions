-- rushB fixed b6025acc. Readonly hypotheses are never payment receipts.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('rushB source input unknown',k)end;return v end
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
 return row
end
local nullable={getCard=true,getArmor=true,getWeapon=true,getTreasure=true,findPlayerBySkillName=true,toPlayer=true,useEquipCard=true,useTrickCard=true,useBasicCard=true,setStrategyMemory=true,getStrategyMemory=true,updateIntention=true,setStrategyCardFlag=true}
local function q(o,k,...)
 if not o or type(o[k])~='function'then ai_unsupported('rushB helper unavailable',k)end
 local m=k;if k=='getMark'and AIValue.isPlayer(o)then m='getStrategyMark'end
 local r=table.pack(o[m](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,v in ipairs(r[1])do t[i]=v end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('rushB foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function face(self,id)return q(self,'getKnownCardById',id)end
local function engineface(self,id)
 -- The printed face is projected only where the card itself is visible.
 return known(self:getPrintedCardById(id),'public engine printed descriptor '..tostring(id))
end
local function random_catalogue(self)
 -- Engine::getRandomCards order is not projected.
 ai_unsupported('source random catalog is not projected','rushB_xiongsuan')
end
local function draw_count(self)return known(self.world.draw_pile_count,'draw_count')end
-- Draw pile contents are hidden.
local function draw_id(self,index)ai_unsupported('draw pile contents are not projected','draw_index:'..index)end
local function draw_iter(self)local index=-1;return function()index=index+1;if index<draw_count(self)then return index+1,draw_id(self,index)end end end
local function fullhand(p)local cs=q(p,'getHandcards');if #cs~=q(p,'getHandcardNum')then ai_unsupported('rushB source requires complete lawful foreign hand','rushB.foreign_hand')end;return cs end
local function evaluation(self,name)return q(self,'getEvaluationCard',name or'slash')end
local function named(self,skill,name,costs)return q(self,'evaluateSkillCard',skill,name,costs or{})end
local function touch_physical(self,c,skill)
 -- Source mutates the actual physical card's skill name; readonly cloning alone cannot commit it.
 return q(self,'evaluatePhysicalSkillMutation',skill,c)
end
local function sourceuse(self,key)
 local c=q(self,'getDecisionContext');if key=='CurrentDamageStruct'then return known(c.damage,key)end
 local rows=c.rushB;return hydrate_context(self,known(rows and rows[key],key),key=='SlashData'and'CardEffect'or'CardUse')
end
local function own_ai(p)local a=p._room and p._room._ai;if not a or a.player~=p then ai_unsupported('rushB view-as requires owner','rushB.view_as')end;return a end
local function memory(self,key,value,write)
 if write then if value==nil then value=false end;q(self,'setStrategyMemory','rushB.'..key,value);return end
 local value,present=q(self,'getStrategyMemory','rushB.'..key);if present then return value~=false and value or nil end
end
local function save_targets(self,key,ts)local names={};for _,p in ipairs(ts or{})do names[#names+1]=q(p,'objectName')end;memory(self,key,names,true)end
local function targets(self,key)local names=memory(self,key);if not names then return nil end;local out=AIList.new({});for _,n in ipairs(names)do out:append(known(self.room:findPlayerByObjectName(n),n))end;return out end
local selectors={rushB_chenglve=true,rushB_paiyi=true,diy_f_pojun=true,diy_qixi=true,wen_jtweidi=true,rushB_lihun=true,rushB_fanjian=true,rushB_xiongyi=true,diy_f_zhuiji=true,diy_f_xionglie=true,diy_k_qice=true,diy_m_chuifeng=true,diy_zuguangu=true,mjin_xiongzhi=true,rushB_baobian_shensu=true,rushB_baobian=true,rushB_baobian_tiaoxin=true,rushB_dimeng=true,rushB_diaogui=true,mmou_leiji=true,mmou_guidao=true,rushB_huace=true,rushB_pizhuan=true,rushB_tongbo=true,rushB_moutongye=true,rushB_juezhi=true,sgskanxue=true,sgszhenhua=true,DIT_qianxun=true}
local provider={diy_qixi='diy_k_qixi',rushB_baobian_tiaoxin='rushB_baobian',rushB_baobian_shensu='rushB_baobian'}
local function ids(raw)local out={};if raw~='.'and raw~=''then for v in raw:gmatch('[^+]+')do local id=tonumber(v);if not id or id<0 or id%1~=0 then ai_unsupported('invalid rushB source material',raw)end;out[#out+1]=id end end;return out end
local function wireparts(wire)
 local cls,raw,user=wire:match('^#([%w_]+):([^:]*):(.*)$');if not cls or not selectors[cls]then ai_unsupported('unmapped rushB skillcard selector',wire)end
 local to={};local declaration=user;local names=user:match('^%-%>(.*)$');if names then declaration='';for n in names:gmatch('[^+]+')do to[#to+1]=n end end
 return cls,ids(raw),declaration,to
end
local suits={spade=0,club=1,heart=2,diamond=3,no_suit_black=4,no_suit_red=5,no_suit=6,to_be_decided=6}
local function printed(wire,self)
 local name,skill,suit,num,raw=wire:match('^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=([^:]+)$')
 if not name or suits[suit]==nil then ai_unsupported('rushB source CardParse face needs exact native parser witness',wire)end
 local numbers={A=1,J=11,Q=12,K=13,JOKER=0};local number=numbers[num]or tonumber(num);if not number then ai_unsupported('rushB source number is not parsed',wire)end
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
 local cls,costs,user,to=wireparts(wire);local c=q(self,'bindSkillCard',provider[cls]or cls,costs,self.request,user~=''and user or nil,'#'..cls)
 return{kind='use_card',card_spec=q(c,'toCardSpec'),targets=to}
end
local function answer(self,c,to)
 if q(c,'isEvaluationOnly')then local skill=q(c,'getSkillName',false);local provider=skill:gsub('^_','');local receipt=q(self,'bindSkillCard',provider,q(c,'getSubcards'),self.request,q(c,'objectName'))
  for _,key in ipairs{'objectName','getSuit','getNumber'}do if q(receipt,key)~=q(c,key)then ai_unsupported('rushB receipt changed selected source product',key)end end
  if q(receipt,'getSkillName',false)~=skill then ai_unsupported('rushB receipt changed raw skill',skill)end
  local a,b=q(receipt,'getSubcards'),q(c,'getSubcards');if #a~=#b then ai_unsupported('rushB receipt changed costs',skill)end;for i,id in ipairs(a)do if b[i]~=id then ai_unsupported('rushB receipt reordered costs',skill)end end;c=receipt
 end
 if AIValue.isConversion(c)then return{kind='use_card',card_spec=q(c,'toCardSpec'),targets=to or{}}end
 if q(c,'isVirtualCard')then ai_unsupported('rushB selected virtual lacks authority','rushB.answer')end
 return{kind='use_card',card_ids={q(c,'getEffectiveId')},targets=to or{}}
end
local function nested(self,reg,key,...)
 local f=q(self,'getHooks',reg)[key];if type(f)~='function'then ai_unsupported('rushB required shared callback missing',reg..'.'..key)end
 local values=table.pack(f(...));if AIUnsupported.is(values[1])then error(values[1],0)end;return table.unpack(values,1,values.n)
end
local function view(self,wire)return printed(wire,self)end

local function RandomList(items)
 local pending={};for _,v in ipairs(items)do pending[#pending+1]=v end
 while #pending>0 do local v=pending[math.random(1,#pending)];table.removeOne(pending,v);table.removeOne(items,v);items[#items+1]=v end
 return items
end
local function saved_player(self,key)local name=memory(self,key);return name and known(self.room:findPlayerByObjectName(name),key)end


sgs.ai_fill_skill.rushB_chenglve=function(self,inclusive,request)
	return parse(self,"#rushB_chenglve:.:")
end

sgs.ai_skill_use_func["#rushB_chenglve"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.rushB_chenglve = 3
sgs.ai_use_value.rushB_chenglve = 7

sgs.ai_skill_discard.rushB_chenglve = function(self,discard_num,min_num,optional,include_equip)
	local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
	local slashs = q(self,"getCards","Slash")
	if #slashs>0 then q(self,"sortByUseValue",handcards,true)
	else q(self,"sortByKeepValue",handcards) end
	local to_discard = {}
	local suits = {}
	for s,sl in ipairs(slashs)do
		s = q(sl,"getSuitString")
		if suits[s] then suits[s] = suits[s]+1
		else suits[s] = 1 end
	end
	local func = function(a,b)
		return a>b
	end
	table.sort(suits,func)
	for i,c in ipairs(handcards)do
		i = q(c,"getEffectiveId")
		if table.contains(slashs,c)
		or #to_discard>=discard_num
		or #self.enemies<1
		then continue end
		if suits[q(c,"getSuitString")]
		and suits[q(c,"getSuitString")]>0
		then table.insert(to_discard,i) end
	end
	for i,c in ipairs(handcards)do
		i = q(c,"getEffectiveId")
		if table.contains(to_discard,i)
		or #to_discard>=discard_num
		then continue end
		table.insert(to_discard,i)
	end
	return to_discard
end

sgs.ai_card_priority.rushB_chenglve = function(self,card)
	if q(self.player,"getMark","chenglve"..card:getSuitString().."-Clear")>0
	and q(card,"getTypeId")>0
	then return -1 end
end



sgs.ai_card_priority.rushB_jianying = function(self,card,v)
	if (q(card,"isRed") and q(self.player,"getMark","&jianyingcolorred") > 0) or
	(q(card,"isBlack") and q(self.player,"getMark","&jianyingcolorblack") > 0)
	or q(self.player,"getMark","&jianyingnumber")==q(card,"getNumber")
	then return 10 end
end





sgs.ai_fill_skill.rushB_zhiheng=function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	q(self,"sortByUseValue",cards,true)
	local card
	for _,acard in sgs.list(cards)do
		local shouldUse = true
		if q(self,"getUseValue",acard)>sgs.ai_use_value.IronChain then
			local dummy_use = q(self,"aiUseCard",acard, dummy())
			if dummy_use.card and q(acard,"isAvailable",self.player) then shouldUse = false end
		end
		if q(acard,"getTypeId")==sgs.Card_TypeEquip then
			local dummy_use = dummy()
			q(self,"useEquipCard",acard,dummy_use)
			if dummy_use.card then shouldUse = false end
		end
		if shouldUse then
			card = acard
			break
		end
	end
	if q(self.player,"getHandcardNum") == 1 and q(self.player,"getMark","zhiheng".."-Clear") == 0 then
		card = cards[1]
	end
	if math.random() < 0.7 and ((q(self,"getOverflow")==0 and not q(self.player,"getHandcardNum") == 1) or #self.enemies == 0) then return nil end
	if not card then return nil end
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	local card_str = ("iron_chain:rushB_zhiheng[%s:%s]=%d"):format(number, q(card,"getSuitString"),card_id)
	local skillcard = parse(self,card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_hasTuntianEffect_skill.rushB_tuntian = function(to, need_zaoxian)
	return q(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_skill_invoke.rushB_jiuyuan = function(self,data)
	local target = q(data,"toPlayer")
	if target and q(self,"isFriend",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.rushB_jiuyuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then q(self,"updateIntention",player,target,-50) end
	end
end

sgs.ai_can_damagehp.rushB_quanji = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>1
	and q(self,"canLoseHp",from,card,to)
end


sgs.ai_fill_skill.rushB_paiyi=function(self,inclusive,request)
	if q(self.player,"getPile","power"):length()>0 then
		return parse(self,"#rushB_paiyi:"..self.player:getPile("power"):first()..":")
	end
end

sgs.ai_skill_use_func["#rushB_paiyi"] = function(card,use,self)
	local target
	q(self,"sort",self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if q(friend,"getHandcardNum")<2 and q(friend,"getHandcardNum")+1<q(self.player,"getHandcardNum")
		  and not q(self,"needKongcheng",friend,true) and not q(friend,"hasSkill","manjuan") then
			target = friend
		end
		if target then break end
	end
	if not target then
		if q(self.player,"getHandcardNum")<q(self.player,"getHp")+q(self.player,"getPile","power"):length()-1 then
			target = self.player
		end
	end
	q(self,"sort",self.friends_noself,"hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if q(friend,"getHandcardNum")+2>q(self.player,"getHandcardNum")
			and q(self,"needToLoseHp",friend,self.player,nil,true)
			and not q(friend,"hasSkill","manjuan") then
				target = friend
			end
			if target then break end
		end
	end
	q(self,"sort",self.enemies,"defense")
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if q(self,"hasManjuanEffect",enemy)
			and q(self,"canDamage",enemy, self.player)
			and (q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player) 
				or q(self,"damageIsEffective",enemy,sgs.DamageStruct_Thunder,self.player)
				or q(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire,self.player)
				or q(self,"damageIsEffective",enemy,sgs.DamageStruct_Ice,self.player)
				)
			and q(enemy,"getHandcardNum")>q(self.player,"getHandcardNum") 
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if q(self,"canDamage",enemy, self.player)
				and not q(enemy,"hasSkills",sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and (q(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player) 
				or q(self,"damageIsEffective",enemy,sgs.DamageStruct_Thunder,self.player)
				or q(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire,self.player)
				or q(self,"damageIsEffective",enemy,sgs.DamageStruct_Ice,self.player)
				)
				and not q(self,"cantbeHurt",enemy)
				and not q(self,"needToLoseHp",enemy)
				and q(enemy,"getHandcardNum")+2>q(self.player,"getHandcardNum")
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = parse(self,"#rushB_paiyi:"..self.player:getPile("power"):first()..":")
		use.to:append(target)
	end
end

sgs.ai_skill_askforag.rushB_paiyi = function(self,card_ids)
	return card_ids[math.random(1,#card_ids)]
end

sgs.ai_card_intention.rushB_paiyi = function(self,card,from,tos)
	local to = tos[1]
	if q(to,"objectName")==q(from,"objectName") then return end
	if not q(to,"hasSkill","manjuan")
	and ((q(to,"getHandcardNum")<2 and q(to,"getHandcardNum")+1<q(from,"getHandcardNum") and not q(self,"needKongcheng",to,true))
	or (q(to,"getHandcardNum")+2>q(from,"getHandcardNum") and q(self,"needToLoseHp",to,from)))
	then
	else
		q(self,"updateIntention",from,to,60)
	end
end

sgs.ai_skill_cardask["@diy_f_pojun"] = function(self, data, pattern, target)
	local target = q(self.room,"getCurrent")
	if q(self,"needBear") then return "." end
	if target and q(self,"isEnemy",target) and q(self,"objectiveLevel",target) > 3 and not q(self,"willSkipPlayPhase",target) then
		return true
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@diy_f_pojun"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = q(self.room,"getCurrent")
		if not current then return end
		q(self,"updateIntention",player, current, 80)
	end
end


sgs.ai_fill_skill.diy_f_pojun=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
		return parse(self,"#diy_f_pojun:"..c:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#diy_f_pojun"] = function(card,use,self)
	
	q(self,"sort",self.enemies,"defense")
	local slashcount = q(self,"getCardsNum","Slash")
	if slashcount > 0 then
		local slash = q(self,"getCard","Slash")
		local dummy_use = q(self,"aiUseCard",slash, dummy())
		if dummy_use.card and dummy_use.to then
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if q(self,"doDisCard",p, "he", true) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
	for _,p in ipairs(self.enemies)do
		if q(self,"doDisCard",p, "he", true) then
			use.card = parse(self,"#diy_f_pojun:.:")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_priority.diy_f_pojun = 6
sgs.ai_use_value.diy_f_pojun = 8.5

sgs.ai_ajustdamage_from.diy_f_pojun = function(self,from,to,card,nature)
	local n = 0
	if q(to,"getHandcardNum") <= q(from,"getHandcardNum") then n = n + 1 end
	if q(to,"getEquips"):length() <= q(from,"getEquips"):length() then n = n + 1 end
	if q(to,"getJudgingArea"):length() >= q(from,"getJudgingArea"):length() then n = n + 1 end
	return n
end


sgs.ai_fill_skill.diy_k_qixi=function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	local black_card
	local red_card
	q(self,"sortByUseValue",cards,true)
	local has_weapon = false
	for _,card in ipairs(cards)  do
		if q(card,"isKindOf","Weapon") then has_weapon=true end
	end
	for _,card in ipairs(cards)  do
		if q(card,"isBlack") and ((q(self,"getUseValue",card)<sgs.ai_use_value.Dismantlement) or inclusive or q(self,"getOverflow")>0) then
			local shouldUse = true
			if q(card,"isKindOf","Armor") then
				if not q(self.player,"getArmor") then shouldUse = false
				elseif q(self.player,"hasEquip",card) and not q(self,"needToThrowArmor") then shouldUse = false
				end
			end
			if q(card,"isKindOf","Weapon") then
				if not q(self.player,"getWeapon") then shouldUse = false
				elseif q(self.player,"hasEquip",card) and not has_weapon then shouldUse = false
				end
			end
			if q(card,"isKindOf","Slash") then
				local dummy_use = dummy()
				if q(self,"getCardsNum","Slash")==1 then
					q(self,"useBasicCard",card,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if q(self,"getUseValue",card)>sgs.ai_use_value.Dismantlement and q(card,"isKindOf","TrickCard") then
				local dummy_use = dummy()
				q(self,"useTrickCard",card,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				black_card = card
				break
			end
		end
	end
	for _,card in ipairs(cards)  do
		if (q(card,"isRed") and q(card,"isKindOf","EquipCard")) and ((q(self,"getUseValue",card)<sgs.ai_use_value.Dismantlement) or inclusive or q(self,"getOverflow")>0) then
			local shouldUse = true
			if q(card,"isKindOf","Armor") then
				if not q(self.player,"getArmor") then shouldUse = false
				elseif q(self.player,"hasEquip",card) and not q(self,"needToThrowArmor") then shouldUse = false
				end
			end
			if q(card,"isKindOf","Weapon") then
				if not q(self.player,"getWeapon") then shouldUse = false
				elseif q(self.player,"hasEquip",card) and not has_weapon then shouldUse = false
				end
			end
			if q(card,"isKindOf","Slash") then
				local dummy_use = dummy()
				if q(self,"getCardsNum","Slash")==1 then
					q(self,"useBasicCard",card,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if q(self,"getUseValue",card)>sgs.ai_use_value.Dismantlement and q(card,"isKindOf","TrickCard") then
				local dummy_use = dummy()
				q(self,"useTrickCard",card,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				red_card = card
				break
			end
		end
	end
	if red_card then
		return parse(self,"#diy_qixi:"..red_card:getEffectiveId()..":")
	end
	if black_card then
		local suit = q(black_card,"getSuitString")
		local number = q(black_card,"getNumberString")
		local card_id = q(black_card,"getEffectiveId")
		local card_str = ("dismantlement:diy_k_qixi[%s:%s]=%d"):format(suit,number,card_id)
		local dismantlement = parse(self,card_str)
		assert(dismantlement)
		return dismantlement
	end
end

sgs.ai_skill_use_func["#diy_qixi"]=function(card,use,self)
	q(self,"sort",self.enemies, "handcard", true)
	for _, enemy in ipairs(self.enemies) do
		if q(self,"doDisCard",enemy, "he", true) then
			use.card=card
			use.to:append(enemy)
			return
		end
	end
end
sgs.ai_use_priority.diy_qixi = sgs.ai_use_priority.Dismantlement + 0.2

sgs.ai_skill_use["@@diy_k_qixi"] = function(self,prompt)
	local cards = q(self,"addHandPile","he")
	q(self,"sortByUseValue",cards,true)
	for _,card in ipairs(cards)  do
		if q(card,"isBlack") then
			local dismantlement = named(self,"_diy_k_qixi","dismantlement",{q(card,"getEffectiveId")})
			
			local dummy_use = q(self,"aiUseCard",dismantlement, dummy())
			if dummy_use.to and dummy_use.to:length() > 0 then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					table.insert(tos, q(to,"objectName"))
				end
				return answer(self,dismantlement,tos)
			end
		end
	end
	for _,card in ipairs(cards)  do
		if (q(card,"isRed") and q(card,"isKindOf","EquipCard")) then
			
			for _,to in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
				if not q(to,"isNude") and q(self,"doDisCard",to, "he", true) then
					return response(self,"#diy_qixi:"..card:getEffectiveId()..":->"..to:objectName())
				end
			end
		end
	end
	return "."
end

local function getFenweiValue(self,who,card,from)
	if not q(self,"hasTrickEffective",card,who,from) then return 0 end
	if q(card,"isKindOf","AOE") then
		if not q(self,"isFriend",who) then return 0 end
		local value = q(self,"getAoeValueTo",card,who,from)
		if value<0 then return -value/30 end
	elseif q(card,"isKindOf","GodSalvation") then
		if not q(self,"isEnemy",who) or not q(who,"isWounded") or q(who,"getHp")>=getBestHp(who) then return 0 end
		if q(self,"isWeak",who) then return 1.2 end
		if q(who,"hasSkills",sgs.masochism_skill) then return 1.0 end
		return 0.9
	elseif q(card,"isKindOf","AmazingGrace") then
		if not q(self,"isEnemy",who) or q(self,"hasManjuanEffect",who) then return 0 end
		local v = 1.2
		local p = q(self.room,"getCurrent")
		while q(p,"objectName")~=q(who,"objectName")do
			v = v*0.9
			p = q(p,"getNextAlive")
		end
		return v
	end
	return 0
end
sgs.ai_skill_playerschosen.diy_k_fenwei = function(self, targets, max, min)
	local fenwei = nested(self,"ai_skill_use","@@fenwei",self,"")
    local selected = sgs.SPlayerList()
	
	if fenwei ~= "." then
		local targets = fenwei:split(">")[2]:split("+")
		local can_choose = sgs.QList2Table(targets)
		q(self,"sort",can_choose, "defense")
		for _,target in ipairs(can_choose) do
			if q(self,"isFriend",target) and table.contains(targets, q(target,"objectName")) then
				selected:append(target)
			end
		end
	elseif math.random() < 0.8 then
		local card = sourceuse(self,"fenwei").card
		local from = sourceuse(self,"fenwei").from
		local can_choose = sgs.QList2Table(targets)
		q(self,"sort",can_choose, "defense")
		for _,target in ipairs(can_choose) do
			local val = getFenweiValue(self,target,card,from)
			if val>0 then
				selected:append(target)
			end
		end
	end
    return selected
end
sgs.ai_skill_invoke.wen_jingtian = true


sgs.ai_skill_invoke.wen_jtweidi = function(self,data)
	local damage = q(data,"toDamage")
	return not q(self,"needToLoseHp",self.player, damage.from, damage.card)
end

sgs.ai_skill_invoke.wen_zemin = function(self,data)
	local damage = q(data,"toDamage")
	return damage.to and q(self,"isFriend",damage.to) and not q(self,"needToLoseHp",damage.to, damage.from, damage.card)
end


sgs.ai_fill_skill.wen_jtweidi=function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getPile","chushibiao"))
  	for _,id in sgs.list(cards)do
		return parse(self,"#wen_jtweidi:"..id..":") 
	end
end

sgs.ai_skill_use_func["#wen_jtweidi"] = function(card,use,self)
	for _,enemy in ipairs(self.enemies)do
		if q(self,"canDamage",enemy, self.player, nil) and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire,self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if q(self,"canDraw",friend, self.player)  then
			use.card = card
			use.to:append(friend)
			return
		end
	end
end

sgs.ai_use_value.wen_jtweidi = 9.4
sgs.ai_use_priority.wen_jtweidi = 4.8

sgs.ai_skill_choice["wen_jtweidi"] = function(self, choices, data)
	local items = choices:split("+")
	local target = q(data,"toPlayer")
	if q(self,"isFriend",target) then
		if table.contains(items, "3") then
			return "3"
		end
		if table.contains(items, "4") then
			return "4"
		end
	end
	if table.contains(items, "1") then
		if q(self,"canDamage",target, self.player, nil) and q(self,"damageIsEffective",target,sgs.DamageStruct_Fire,self.player) then
			if math.random() < 0.8 then
				return "1"
			end
		end
	end
	if table.contains(items, "3") then
		if math.random() < 0.5 then
			return "3"
		end
	end
	if table.contains(items, "2") then
		if not q(self,"damageIsEffective",self.player,sgs.DamageStruct_Fire,target) then
			return "2"
		end
		if math.random() < 0.5 then
			return "2"
		end
	end
	if table.contains(items, "4") then
		if math.random() < 0.5 then
			return "4"
		end
	end
end

sgs.ai_can_damagehp.diy_k_zhongzuo = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to) and q(to,"getMark","damaged_round-Clear") == 0
end
sgs.ai_skill_playerchosen.diy_k_zhongzuo = function(self,targets)
	q(self,"sort",self.friends_noself,"defense")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if not q(self,"canDraw",friend) then continue end
		if (q(friend,"getHandcardNum")+(q(friend,"isWounded") and -2 or 1))<(q(self.player,"getHandcardNum")+(q(self.player,"isWounded") and -2 or 0)) then
			return friend
		end
	end
	if q(self,"canDraw",self.player) then return self.player end
	return nil
end
sgs.ai_playerchosen_intention.diy_k_zhongzuo = -40

sgs.ai_skill_invoke.diy_k_tongqu = false


sgs.ai_skill_discard.diy_k_wanlan = function(self)
	local damage = sourceuse(self,"CurrentDamageStruct")
	if damage.from and q(self.player,"objectName") == q(damage.from,"objectName") then
		if not q(self,"canDamage",damage.to, self.player, nil) then
			return {}
		end
	elseif damage.from then
		if not q(self,"canDamage",damage.from, self.player, nil) then
			return {}
		end
	end
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, q(card,"getEffectiveId"))
		if #to_discard == 2 then
        	break
		end
	end
	if #to_discard == 2 then
		return to_discard
	end
	return {}
end


sgs.ai_fill_skill.rushB_lihun=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	if #cards<1 then return end
	return parse(self,"#rushB_lihun:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#rushB_lihun"] = function(card,use,self)
	q(self,"sort",self.enemies,"handcard",true)
	local jwfy = q(self.room,"findPlayerBySkillName","shoucheng")
	for _,enemy in sgs.list(self.enemies)do
		if not q(enemy,"hasSkill","kongcheng")
		then
			if (q(enemy,"hasSkill","lianying") or jwfy and q(self,"isFriend",jwfy,enemy)) and q(self,"damageMinusHp",enemy,1)>0
			or q(enemy,"getHp")<3 and q(self,"damageMinusHp",enemy,0)>0 and q(enemy,"getHandcardNum")>0
			or q(enemy,"getHandcardNum")>=q(enemy,"getHp") and q(enemy,"getHp")>2 and q(self,"damageMinusHp",enemy,0)>=-1
			or q(enemy,"getHandcardNum")-q(enemy,"getHp")>2
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	if not q(self.player,"faceUp")
	then
		for _,enemy in sgs.list(self.enemies)do
			if q(enemy,"getHandcardNum")>=q(enemy,"getHp")
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	if q(self,"hasCrossbowEffect")
	or q(self,"getCardsNum","Crossbow")>0
	then
		local slash = q(self,"getCard","Slash") or evaluation(self)
		for _,enemy in sgs.list(self.enemies)do
			if not q(enemy,"isKongcheng")
			and q(self,"slashIsEffective",slash,enemy)
			and q(self.player,"distanceTo",enemy)==1
			and not q(enemy,"hasSkills","fenyong|zhichi|fankui|vsganglie|ganglie|neoganglie|enyuan|nosenyuan|langgu|guixin|kongcheng")
			and q(self,"getCardsNum","Slash")+getKnownCard(enemy,self.player,"Slash")>=3
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
end


sgs.ai_skill_discard.rushB_lihun = function(self,discard_num,min_num,optional,include_equip)
	local to_discard = {}

	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByKeepValue",cards)
	local card_ids = {}
	for _,card in sgs.list(cards)do
		table.insert(card_ids,q(card,"getEffectiveId"))
	end

	local temp = table.copyFrom(card_ids)
	for i = 1,#temp,1 do
		local card = face(self,temp[i])
		if q(self.player,"getArmor") and temp[i]==q(self.player,"getArmor"):getEffectiveId() and q(self,"needToThrowArmor") then
			table.insert(to_discard,temp[i])
			table.removeOne(card_ids,temp[i])
			if #to_discard==discard_num then
				return to_discard
			end
		end
	end

	temp = table.copyFrom(card_ids)

	for i = 1,#card_ids,1 do
		local card = face(self,card_ids[i])
		table.insert(to_discard,card_ids[i])
		if #to_discard==discard_num then
			return to_discard
		end
	end

	if #to_discard<discard_num then return {} end
end

sgs.ai_use_value.rushB_lihun = 8.5
sgs.ai_use_priority.rushB_lihun = 6
sgs.ai_card_intention.rushB_lihun = 80


sgs.ai_fill_skill.rushB_fanjian=function(self,inclusive,request)
	if q(self.player,"isKongcheng") then return nil end
	return parse(self,"#rushB_fanjian:.:")
end

sgs.ai_skill_use_func["#rushB_fanjian"]=function(card,use,self)

	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByUseValue",cards,true)
	if #cards==1 and cards[1]:getSuit()==sgs.Card_Diamond then return end
	if #cards<=4 and (q(self,"getCardsNum","Peach")>0 or q(self,"getCardsNum","Analeptic")>0) then return end
	q(self,"sort",self.enemies,"hp")

	local suits = {}
	local suits_num = 0
	for _,c in ipairs(cards)do
		if not suits[q(c,"getSuitString")] then
			suits[q(c,"getSuitString")] = true
			suits_num = suits_num+1
		end
	end

	local wgt = q(self.room,"findPlayerBySkillName","buyi")
	if wgt and q(self,"isFriend",wgt) then wgt = nil end

	for _,enemy in ipairs(self.enemies)do
		local visible = 0
		for _,card in ipairs(cards)do
			local flag = string.format("%s_%s_%s","visible",q(enemy,"objectName"),q(self.player,"objectName"))
			if q(card,"hasFlag","visible") or q(card,"hasFlag",flag) then visible = visible+1 end
		end
		if visible>0 and (#cards<=2 or suits_num<=2) then continue end
		if q(self,"canAttack",enemy) and not q(enemy,"hasSkills","qingnang|jijiu|tianxiang")
		and not (wgt and q(card,"getTypeId")~=sgs.Card_Basic and (q(enemy,"isKongcheng") or q(enemy,"objectName")==wgt:objectName()))
		and q(self,"damageIsEffective",enemy,card)
		then
			use.card = parse(self,"#rushB_fanjian:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_card_intention.rushB_fanjian = 70


sgs.ai_skill_use["@@rushB_xiongyi"] = function(self, prompt)
	q(self,"sort",self.friends_noself, "defense", true)
	local targets = {}
	local to_use = {}
	for _,friend in ipairs(self.friends_noself) do
		for _,c in sgs.list(q(self,"sortByKeepValue",q(self.player,"getHandcards")))do
			if not table.contains(to_use, q(c,"getId")) then
				table.insert(to_use, q(c,"getId"))
				table.insert(targets, q(friend,"objectName"))
				break
			end
		end
	end
	if (#targets == #to_use and #targets > 0) then
		return response(self,"#rushB_xiongyi:".. table.concat(to_use, "+") ..":->".. table.concat(targets, "+"))
	end
	return "."
end
sgs.ai_card_intention.rushB_xiongyi = -70

sgs.ai_fill_skill.diy_f_zhuiji=function(self,inclusive,request)
	if #self.enemies==0 then return nil end	
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	if #cards<1 then return end
	return parse(self,"#diy_f_zhuiji:"..cards[1]:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#diy_f_zhuiji"] = function(card, use, self)
	q(self,"sort",self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if q(self,"canDamage",enemy,self.player,nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_fill_skill.diy_f_xionglie=function(self,inclusive,request)
	if #self.enemies==0 then return nil end	
	return parse(self,"#diy_f_xionglie:.:")
end

sgs.ai_skill_use_func["#diy_f_xionglie"] = function(card, use, self)
	q(self,"sort",self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if (q(self,"canDamage",self.player,enemy,nil) or not q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player)) and q(self,"doDisCard",enemy, "he", true) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end


-- audited alias ai_skill_playerchosen.diy_k_qizhi
sgs.ai_skill_invoke.diy_k_jinqu = function(self)
	if q(self.room,"getCurrent") and q(self.room,"getCurrent"):objectName() ~= q(self.player,"objectName") then return true end
	if q(self.player,"getMark","&qizhi-Clear")>=q(self.player,"getHandcardNum") then return true end
	return false
end

sgs.ai_fill_skill.diy_k_fanghun=function(self,inclusive,request)
	local handcards = q(self,"addHandPile")
	if #handcards<1 then return end
	handcards = q(self,"sortByUseValue",handcards,true)
	for _,c in sgs.list(handcards)do
		local slash = named(self,"diy_k_fanghun","slash",{q(c,"getEffectiveId")})
		if q(c,"isKindOf","Jink")
		and q(slash,"isAvailable",self.player)
		then
			return slash
		elseif q(c,"isKindOf","Analeptic") then
			return parse(self,("peach:diy_k_fanghun[%s:%s]=%d"):format(q(c,"getSuitString"),q(c,"getNumberString"),q(c,"getEffectiveId")))
		end
	end
end

function sgs.ai_cardsview.diy_k_fanghun(self,class_name,player)
   	local cards = sgs.QList2Table(q(player,"getCards","h"))
    q(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
		if class_name=="Slash" and q(c,"isKindOf","Jink")
		then return view(self,("slash:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()))
		elseif class_name=="Jink" and q(c,"isKindOf","Slash")
		then return view(self,("jink:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()) )
		elseif q(c,"isKindOf","Analeptic") then
			return view(self,("peach:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()))
		end
	end
end



sgs.ai_skill_invoke.diy_k_fuhan = function(self,data)
	local meiying = q(self.player,"getMark","&diy_k_meiying")
	if q(self.player,"getLostHp")>0 then
		return meiying>q(self.player,"getHp") and q(self.player,"isLowestHpPlayer") and q(self,"getCardsNum","Peach")==0 and q(self,"isWeak")
	else
		return meiying>q(self.player,"getMaxHp")
	end
	return false
end



sgs.ai_fill_skill.diy_k_qice=function(self,inclusive,request)
	if #self.toUse>2 then return end
	local ids = q(self.player,"handCards")
	local canCs = {}
	for _,pn in ipairs(known(AICardCatalog.patternNames(),"pattern_names"))do
		local dc = evaluation(self,pn)
		if dc and q(dc,"isNDTrick") then
			dc = named(self,"diy_k_qice",pn,sgs.QList2Table(ids))
			if q(dc,"isAvailable",self.player)
			then table.insert(canCs,dc) end
		end
	end
	ids = sgs.QList2Table(ids)
	q(self,"sortByUseValue",canCs)
	sgs.ai_use_priority.diy_k_qice = 4-#ids
	if #ids<3 then
		for _,c in ipairs(canCs)do
			if q(c,"isKindOf","AOE") then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if q(c,"targetFixed") and not q(c,"isDamageCard")
			and q(self,"getCardsNum","Jink,Peach")<1 then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	if #ids==3 then
		for _,c in ipairs(canCs)do
			if q(c,"isKindOf","AOE") then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if q(c,"isKindOf","GlobalEffect")
			and q(self.player,"isWounded") then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if q(c,"targetFixed") and not q(c,"isDamageCard")
			and q(self,"getCardsNum","Jink,Peach,Analeptic,Nullification")<1 then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	local caocao = q(self.room,"findPlayerBySkillName","jianxiong")
	for _,c in ipairs(canCs)do
		if q(c,"isKindOf","AOE")
		and caocao and caocao:getHp()>1
		and q(self,"getAoeValue",c)>-5 and q(self,"isFriend",caocao) and not q(self,"willSkipPlayPhase",caocao)
		and not q(self.player,"hasSkill","jueqing") and q(self,"aoeIsEffective",c,caocao,self.player) then
			local d = q(self,"aiUseCard",c)
			if d.card then
				save_targets(self,"qice_to",d.to)
				return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
			end
		end
	end
	if #ids<=3
	and q(self,"getCardsNum","Jink,Peach,Analeptic,Nullification")<1 then
		for _,c in ipairs(canCs)do
			if q(c,"isKindOf","GlobalEffect")
			and q(self.player,"isWounded") then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if q(c,"targetFixed") and not q(c,"isDamageCard") then
				local d = q(self,"aiUseCard",c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	for _,c in ipairs(canCs)do
		local d = q(self,"aiUseCard",c)
		if d.card and q(c,"isDamageCard")
		and q(self,"getUseValue",c)>#ids*2.1 then
			save_targets(self,"qice_to",d.to)
			return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
		end
	end
	for _,c in ipairs(canCs)do
		local d = q(self,"aiUseCard",c)
		if d.card and q(self,"getUseValue",c)>#ids*2.6 then
			save_targets(self,"qice_to",d.to)
			return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
		end
	end
end

sgs.ai_skill_use_func["#diy_k_qice"] = function(card,use,self)
	self.qice_to=targets(self,"qice_to");return nested(self,"ai_skill_use_func","QiceCard",card,use,self)
end

-- audited alias ai_use_priority.diy_k_qice
sgs.ai_ajustdamage_to.diy_f_mingshi = function(self,from,to,slash,nature)
	if (q(from,"faceUp") and not q(to,"faceUp")) or (not q(from,"faceUp") and q(to,"faceUp"))
	then return -1 end
end



sgs.ai_skill_playerchosen.diy_f_lirang = function(self,targets)
	q(self,"sort",self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if q(self,"toTurnOver",enemy,1,"diy_f_lirang") and q(self,"hasManjuanEffect",enemy) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if q(self,"toTurnOver",enemy,1,"diy_f_lirang") and q(enemy,"hasSkills",sgs.priority_skill) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if q(self,"toTurnOver",enemy,1,"diy_f_lirang") then
			return enemy
		end
	end
end
sgs.ai_skill_choice["diy_f_lirang"] = function(self, choices, data)
    return "1"
end
sgs.ai_skill_choice["@lirangobtain"] = function(self, choices, data)
    return "yes"
end

sgs.ai_playerchosen_intention.diy_f_lirang = function(self,from,to)
	if q(self,"hasManjuanEffect",to) then q(self,"updateIntention",from,to,80) end
	local intention = 80
	if not q(self,"toTurnOver",to,1) then intention = -intention end
	q(self,"updateIntention",from,to,intention)
end



sgs.ai_card_priority.diy_k_fenyin = function(self,card,v)
	if ((q(self.player,"getMark","&".."fenyin".."colorred".."-Clear")> 0 and q(card,"isBlack")) or
	(q(self.player,"getMark","&".."fenyin".."colorblack".."-Clear")> 0 and q(card,"isRed"))
	) or q(self.player,"getMark","&fenyinnumber-Clear")==q(card,"getNumber")
	then return 10 end
end



sgs.ai_fill_skill.diy_m_chuifeng=function(self,inclusive,request)
	local ts = {"slash","duel", "thunder_slash", "ice_slash", "fire_slash"}
	local cn = ts[math.random(1,2)]
	local dc = named(self,"diy_m_chuifeng",cn,{})
	sgs.ai_use_priority.diy_m_chuifeng = sgs.ai_use_priority[q(dc,"getClassName")]
	local d = q(self,"aiUseCard",dc)
	if d.card and d.to and not q(self,"isWeak") then
		save_targets(self,"cf_to",d.to)
		memory(self,"diy_m_chuifengChoice",cn,true)
		return parse(self,"#diy_m_chuifeng:.:"..cn) 
	end
end

sgs.ai_skill_use_func["#diy_m_chuifeng"] = function(card,use,self)
	use.card = card
	use.to = targets(self,"cf_to")
end
sgs.ai_use_value.diy_m_chuifeng = 5.4
sgs.ai_use_priority.diy_m_chuifeng = 2.8

sgs.ai_skill_choice.diy_m_chuifeng = function(self, choices, data)
	return memory(self,"diy_m_chuifengChoice")
end

sgs.ai_use_revises.diy_m_quedi = function(self,card,use)
	if table.contains(q(card,"getSkillNames"), "diy_m_chuifengg") or table.contains(q(card,"getSkillNames"), "diy_m_chongjian") or table.contains(q(card,"getSkillNames"), "diy_m_choujue") then
		q(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

sgs.ai_fill_skill.diy_m_chongjian=function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	q(self,"sortByUseValue",cards,true)
	for _,card in sgs.list(cards)do
		if q(card,"isKindOf","OffensiveHorse") and q(self,"slashIsAvailable") then
			return parse(self,("fire_slash:diy_m_chongjian[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")))
		elseif q(card,"isKindOf","Treasure") and q(self,"slashIsAvailable") then
			return parse(self,("ice_slash:diy_m_chongjian[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")))
		elseif q(card,"isKindOf","DefensiveHorse") and q(self,"slashIsAvailable") then
			return parse(self,("thunder_slash:diy_m_chongjian[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")))
		elseif q(card,"isKindOf","Weapon") and q(self,"slashIsAvailable") then
			return parse(self,("slash:diy_m_chongjian[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")))
		elseif q(card,"isKindOf","Armor") and q(self,"slashIsAvailable") then
			return parse(self,("analeptic:diy_m_chongjian[%s:%s]=%d"):format(q(card,"getSuitString"),q(card,"getNumberString"),q(card,"getId")))
		end
	end
end
sgs.ai_card_priority.diy_m_chongjian = function(self,card,v)
	if table.contains(q(card,"getSkillNames"), "diy_m_chongjian")
	then return 5 end
end

sgs.ai_view_as.diy_m_chongjian = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceSpecial then return end
	if q(card,"isKindOf","OffensiveHorse") then
		return view(own_ai(player),("fire_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif q(card,"isKindOf","DefensiveHorse") then
		return view(own_ai(player),("thunder_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif q(card,"isKindOf","Treasure") then
		return view(own_ai(player),("ice_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif q(card,"isKindOf","Weapon") then
		return view(own_ai(player),("slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif q(card,"isKindOf","Armor") then
		return view(own_ai(player),("analeptic:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	end
end


sgs.ai_fill_skill.diy_m_jichou=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if q(self.player,"getMark","diy_m_jichou"..c:objectName().."-Clear")>0 then continue end
		if c and q(c,"isNDTrick") and q(c,"isAvailable",self.player) then
			c = touch_physical(self,c,"diy_m_jichou")
			local d = q(self,"aiUseCard",c)
			if d.card then
				if q(c,"canRecast") and d.to:length()<1 then continue end
				return c:toString()
			end
		end
	end
end
sgs.ai_card_priority.diy_m_jichou = function(self,card,v)
	if table.contains(q(card,"getSkillNames"), "diy_m_jichou")
	then return 5 end
end
sgs.ai_guhuo_card.diy_m_jichou = function(self,toname,class_name)
	if q(self.player,"getMark","diy_m_jichou"..toname.."-Clear")<1 then
		local cards = q(self.player,"getCards","he")
		cards = q(self,"sortByKeepValue",cards)
        for _,c in sgs.list(cards)do
			if c and q(c,"isNDTrick") and q(c,"isKindOf",class_name) then 
				c = touch_physical(self,c,"diy_m_jichou")
				return c:toString()
			end
		end
	end
end


sgs.ai_fill_skill.diy_m_jilun=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if q(self.player,"getMark","diy_m_jilun"..c:objectName().."-Clear")>0 then continue end
		if q(self.player,"getMark","diy_m_jichou"..c:objectName().."-Clear")>0 then
			if c and q(c,"isNDTrick") and q(c,"isAvailable",self.player) then
				c = touch_physical(self,c,"diy_m_jilun")
				local d = q(self,"aiUseCard",c)
				if d.card then
					if q(c,"canRecast") and d.to:length()<1 then continue end
					return c:toString()
				end
			end
		end
	end
end
sgs.ai_card_priority.diy_m_jilun = function(self,card,v)
	if table.contains(q(card,"getSkillNames"), "diy_m_jilun")
	then return 4 end
end

sgs.ai_guhuo_card.diy_m_jilun = function(self,toname,class_name)
	if q(self.player,"getMark","diy_m_jichou"..toname.."-Clear")>0 and q(self.player,"getMark","diy_m_jilun"..toname.."-Clear")<1 then
		local cards = q(self.player,"getCards","he")
		cards = q(self,"sortByKeepValue",cards)
        for _,c in sgs.list(cards)do
			if c and q(c,"isNDTrick") and q(c,"isKindOf",class_name) then 
				c = touch_physical(self,c,"diy_m_jilun")
				return c:toString()
			end
		end
	end
end

sgs.ai_fill_skill.diy_zuguangu=function(self,inclusive,request)
    return parse(self,"#diy_zuguangu:.:")
end

sgs.ai_skill_use_func["#diy_zuguangu"] = function(card,use,self)
	if q(self.player,"getChangeSkillState","diy_zuguangu") == 1 then
		local max = math.min(4, draw_count(self))
    	if max <= 0 then return end
		for i = 1, max, 1 do
			local cards = {}
			for j = 0, i - 1, 1 do
				local cc = face(self,draw_id(self,j))
				local num = q(cc,"nameLength")
				if q(cc,"isKindOf","Slash") then num = 1 end
				if num == i then
					table.insert(cards, cc)
				end
			end
			if #cards > 0 then
				q(self,"sortByUseValue",cards)
				for _,cc in ipairs(cards) do
					if q(cc,"isKindOf","BasicCard") or q(cc,"isNDTrick") then
						local dummy_use = q(self,"aiUseCard",cc, dummy(true))
						if dummy_use.card then
							use.card = card
							return 
						end
					end
				end
			end
		end
	else
		local all = sgs.QList2Table(q(self.room,"getOtherPlayers",self.player))
		q(self,"sort",all, "defense")
		for _,p in ipairs(all) do
			if (not q(self,"isFriend",p)) and (not q(p,"isKongcheng")) then
				local cards = sgs.QList2Table(fullhand(p))
				q(self,"sortByUseValue",cards)
				local max = q(p,"getHandcardNum")
				for _,cc in ipairs(cards) do
					local num = q(cc,"nameLength")
					if q(cc,"isKindOf","Slash") then num = 1 end
					if num > 4 or num > max then continue end
					if q(cc,"isKindOf","BasicCard") or q(cc,"isNDTrick") then
						local dummy_use = q(self,"aiUseCard",cc, dummy(true))
						if dummy_use.card then
							use.card = card
							memory(self,"diy_zuguangu",q(p,"objectName"),true)

							return 
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_priority.diy_zuguangu = 8
sgs.ai_use_value.diy_zuguangu = 8


sgs.ai_skill_playerchosen.diy_zuguangu = function(self,targets)
	if saved_player(self,"diy_zuguangu") then return saved_player(self,"diy_zuguangu") end
	targets = sgs.QList2Table(targets)
	for _,p in ipairs(targets) do
		if (not q(self,"isFriend",p)) and (not q(p,"isKongcheng")) then
			local cards = sgs.QList2Table(fullhand(p))
			q(self,"sortByUseValue",cards)
			local max = q(p,"getHandcardNum")
			for _,cc in ipairs(cards) do
				local num = q(cc,"nameLength")
				if q(cc,"isKindOf","Slash") then num = 1 end
				if num > 4 or num > max then continue end
				if q(cc,"isKindOf","BasicCard") or q(cc,"isNDTrick") then
					local dummy_use = q(self,"aiUseCard",cc, dummy(true))
					if dummy_use.card then
						return p
					end
				end
			end
		end
	end
	for _,p in ipairs(targets) do
		if not q(p,"isKongcheng") and q(self,"isEnemy",p) then
			return p
		end
	end
end

sgs.ai_skill_choice.diy_zuguangunum = function(self, choices)
    if not saved_player(self,"diy_zuguangu") then
        if q(self.player,"getHp") == 1 and q(self.player,"isWounded") then
            local card = face(self,draw_id(self,0))
            if q(card,"isKindOf","Peach") then return tostring(1) end
            return tostring(4)
        end
        local max = math.min(4, draw_count(self))
        if max <= 0 then return end
    
        for i = 1, max, 1 do
            local cards = {}
            for j = 0, i - 1, 1 do
                local cc = face(self,draw_id(self,j))
                local num = q(cc,"nameLength")
                if q(cc,"isKindOf","Slash") then num = 1 end
				if q(self.player,"getMark","diy_zuxiaoyong-"..num.."-Clear") > 0 then continue end
                if num == i then
                    table.insert(cards, cc)
                end
            end
            if #cards > 0 then
                q(self,"sortByUseValue",cards)
                for _,cc in ipairs(cards) do
					if q(cc,"isKindOf","BasicCard") or q(cc,"isNDTrick") then
						local dummy_use = q(self,"aiUseCard",cc, dummy(true))
						if dummy_use.card then
							return tostring(i)
						end
					end
                end
            end
        end
    else
		local target = saved_player(self,"diy_zuguangu")
        local cards = sgs.QList2Table(fullhand(target))
        q(self,"sortByUseValue",cards)
        local max = q(target,"getHandcardNum")
        for _,cc in ipairs(cards) do
            local num = q(cc,"nameLength")
            if q(cc,"isKindOf","Slash") then num = 1 end
            if num > 4 or num > max then continue end
            if q(self.player,"getMark","diy_zuxiaoyong-"..num.."-Clear") > 0 then continue end
			if q(cc,"isKindOf","BasicCard") or q(cc,"isNDTrick") then
				local dummy_use = q(self,"aiUseCard",cc, dummy(true))
				if dummy_use.card then
					return tostring(num)
				end
			end
        end
    end
    return tostring(4)
end

sgs.ai_skill_askforag.diy_zuguangu = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = face(self,id)
		if q(card,"isKindOf","BasicCard") or q(card,"isNDTrick") then
			local num = q(card,"nameLength")
			if q(card,"isKindOf","Slash") then num = 1 end
			if q(self.player,"getMark","diy_zuxiaoyong-"..num.."-Clear") == 0 and num == q(self.player,"getMark","&diy_zuguangu") then
				local dummy_use = q(self,"aiUseCard",card, dummy())
				if q(card,"isAvailable",self.player) and dummy_use.card then
					if q(card,"canRecast") and dummy_use.to:length()<1 then continue end
					return id
				end
			end
		end
	end
	for _,id in ipairs(card_ids)do
		local card = face(self,id)
		if q(card,"isKindOf","BasicCard") or q(card,"isNDTrick") then
			local dummy_use = q(self,"aiUseCard",card, dummy())
			if q(card,"isAvailable",self.player) and dummy_use.card then
				if q(card,"canRecast") and dummy_use.to:length()<1 then continue end
				return id
			end
		end
	end
end

sgs.ai_skill_use["@@diy_zuguangu"] = function(self, prompt)
	-- Own property; absent reads as the donor's empty toString().
	local pattern = self.player:getPropertyValue("diy_zuguangu") or ""
	local card = named(self,"diy_zuguangu",pattern,{})
    
    local dummy_use = q(self,"aiUseCard",card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, q(to,"objectName"))
            end
            return answer(self,card,tos)
        else
            return answer(self,card,{})
        end
    end
end

sgs.ai_card_priority.diy_zuxiaoyong = function(self,card,v)
	local n, m = q(card,"nameLength"), q(self.player,"getMark","&diy_zuguangu")
	if q(self.player,"getMark","diy_zuxiaoyong-"..m.."-Clear") < 1 and n == m
	then return 10 end
end

sgs.ai_skill_playerchosen.mjin_buchen = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) then
			return p
		end
	end
	return targets:first()
end
sgs.ai_playerchosen_intention.mjin_buchen = -40


sgs.ai_fill_skill.mjin_xiongzhi=function(self,inclusive,request)
	return parse(self,"#mjin_xiongzhi:.:")
end

sgs.ai_skill_use_func["#mjin_xiongzhi"] = function(card,use,self)
	if q(self.player,"getMark","&mjin_quanbian-PlayClear") + 1 >= q(self.player,"getMaxHp") then 
		sgs.ai_use_priority.mjin_xiongzhi = 10
		use.card = card
	end
	local list = q(self,"getSourceTopCardObservation","mjin_xiongzhi",1)
	local use_num = 0
	for _,id in sgs.qlist(list)do
		local card = face(self,id)
		if not q(self.player,"canUse",card) then break end
		if q(self,"willUse",self.player,card)
		then use_num = use_num+1
		else break end
	end
	if use_num>0 then
		use.card = card
	end
end

sgs.ai_use_priority.mjin_xiongzhi = 0

sgs.ai_card_priority.mjin_xiongzhi = function(self,card,v)
	if q(self.player,"getMark","&mjin_quanbian-PlayClear") + 1 >= q(self.player,"getMaxHp") then 
		sgs.ai_use_priority.mjin_xiongzhi = 10
		if table.contains(q(card,"getSkillNames"), "mjin_xiongzhi") then
			return 10 
		end
	end
end


sgs.ai_skill_use["@@mjin_xiongzhi"] = function(self,prompt,method)
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	for _, card in ipairs(cards) do
		if q(card,"hasFlag","mjin_xiongzhi") then
			local dummy = q(self,"aiUseCard",card)
			if dummy.card and dummy.to then
				local tos = {}
				for _,p in sgs.qlist(dummy.to)do
					table.insert(tos,q(p,"objectName"))
				end
				return answer(self,card,tos)
			end
		end
	end
	return "."
end
sgs.ai_skill_invoke.mjin_quanbian = true


local function baobian_shensu(self,index,prompt)
 local plan=q(self,'planShensuResponse',index,prompt)
 if not plan or plan=='.' then return '.' end
 if type(plan)~='table' or type(plan.subcards)~='table' or type(plan.targets)~='table' then
  ai_unsupported('Shensu source selector returned an unknown proposal ABI','rushB_baobian_shensu')
 end
 local costs={};for i,id in ipairs(plan.subcards)do costs[i]=id end
 local source='@ShensuCard='..(#costs==0 and '.' or table.concat(costs,'+'))..'->'..table.concat(plan.targets,'+')
 local wire=string.gsub(source,'@ShensuCard=','#rushB_baobian_shensu:')..':'
 -- Pinned donor leaves the final colon after the target names and has no
 -- registered #rushB_baobian_shensu prototype. Do not silently repair to V2.
 local signal=AIUnsupported.new('rushB donor Shensu rewritten terminal has no native prototype','rushB_baobian_shensu')
 signal.terminal_response_selection=true;signal.donor_terminal_unavailable=true
 signal.source_wire=wire;signal.selected_costs=costs;signal.selected_targets=plan.targets
 error(signal,0)
end
sgs.ai_skill_use["@@rushB_baobian_shensu1"]=function(self,prompt)
 return baobian_shensu(self,1,prompt)
end
sgs.ai_skill_use["@@rushB_baobian_shensu2"]=function(self,prompt)
 return baobian_shensu(self,2,prompt)
end

sgs.ai_skill_use["@@rushB_baobian_shensu3"] = function(self,prompt)
	q(self,"sort",self.enemies,"defense")
	if q(self,"needBear") then return "." end
	local selfSub = q(self,"getOverflow")
	local selfDef = sgs.getDefense(self.player)
	for _,enemy in ipairs(self.enemies)do
		local def = q(self,"getDefenseSlash",enemy)
		local slash = named(self,"_rushB_baobian_shensu","slash",{})
		local eff = q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)

		if not q(self.player,"canSlash",enemy,slash,false) then
		elseif q(self,"slashProhibit",nil,enemy) then
		elseif def<6 and eff then return "#rushB_baobian_shensu:.:->"..enemy:objectName()

		elseif selfSub>=2 then return "#rushB_baobian_shensu:.:->"..enemy:objectName()
		elseif selfDef<6 then return "." end
	end

	for _,enemy in ipairs(self.enemies)do
		local def=sgs.getDefense(enemy)
		local slash = named(self,"_rushB_baobian_shensu","slash",{})
		local eff = q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)

		if not q(self.player,"canSlash",enemy,slash,false) then
		elseif q(self,"slashProhibit",nil,enemy) then
		elseif eff and def<8 then return "#rushB_baobian_shensu:.:->"..enemy:objectName()
		else return "." end
	end
	return "."
end

sgs.ai_skill_use_func["#rushB_baobian_tiaoxin"] = function(card,use,self)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if q(self,"doDisCard",enemy,"he") and q(self,"isTiaoxinTarget",enemy)
		then table.insert(targets,enemy) end
	end

	if #targets==0 then return end

	sgs.ai_use_priority.rushB_baobian_tiaoxin = 8
	if not q(self.player,"getArmor") and not q(self.player,"isKongcheng") then
		for _,c in sgs.qlist(q(self.player,"getCards","h"))do
			if q(c,"isKindOf","Armor") and q(self,"evaluateArmor",c)>3 then
				sgs.ai_use_priority.rushB_baobian_tiaoxin = 5.9
				break
			end
		end
	end

	q(self,"sort",targets,"defenseSlash")
	use.to:append(targets[1])
	use.card = card
end

-- audited alias ai_card_intention.rushB_baobian_tiaoxin
-- audited alias ai_use_priority.rushB_baobian_tiaoxin
sgs.ai_fill_skill.rushB_baobian=function(self,inclusive,request)

  	if q(self.player,"getHp") > getBestHp(self.player) then
		return parse(self,"#rushB_baobian:.:")
	end
	if q(self.player,"getHp") <= 3 then
		local cards = q(self.player,"getCards","h")
		cards = q(self,"sortByKeepValue",cards)
		if #cards>0 then
			return parse(self,"#rushB_baobian_tiaoxin:"..cards[1]:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#rushB_baobian"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.rushB_baobian = 9.4
sgs.ai_use_priority.rushB_baobian = 0.8

sgs.ai_getBestHp_skill.rushB_baobian = function(owner)
	return math.max(1, q(owner,"getMaxHp") - 3)
end


sgs.ai_fill_skill.rushB_dimeng=function(self,inclusive,request)
	if q(self,"needBear") then return end
	return parse(self,"#rushB_dimeng:.:")
end
function DimengIsWorth(self, friend, enemy, mycards, myequips)
	local e_hand1, e_hand2 = q(enemy,"getHandcardNum"), q(enemy,"getHandcardNum") - q(self,"getLeastHandcardNum",enemy)
	local f_hand1, f_hand2 = q(friend,"getHandcardNum"), q(friend,"getHandcardNum") - q(self,"getLeastHandcardNum",friend)
	local e_peach, f_peach = getCardsNum("Peach", enemy), getCardsNum("Peach", friend)
	if e_hand1 < f_hand1 then
		return false
	elseif e_hand2 <= f_hand2 and e_peach <= f_peach then
		return false
	elseif e_peach < f_peach and e_peach < 1 then
		return false
	elseif e_hand1 == f_hand1 and e_hand1 > 0 then
		return hasTuntianEffect(friend, true)
	end
	local cardNum = #mycards
	local delt = e_hand1 - f_hand1 --assert: delt>0
	if delt > cardNum then
		return false
	end
	local equipNum = #myequips
	if equipNum > 0 then
		if q(self.player,"hasSkills","xuanfeng|xiaoji|nosxuanfeng") then
			return true
		end
	end

	local soKeep = 0
	local soUse = 0
	local marker = math.ceil(delt / 2)
	for i=1, delt, 1 do
		local card = mycards[i]
		local keepValue = q(self,"getKeepValue",card)
		if keepValue > 4 then
			soKeep = soKeep + 1
		end
		local useValue = q(self,"getUseValue",card)
		if useValue >= 6 then
			soUse = soUse + 1
		end
	end
	if soKeep > marker then
		return false
	end
	if soUse > marker then
		return false
	end
	return true
end

local dimeng_discard = function(self, discard_num, mycards)
	local cards = mycards
	local to_discard = {}

	local aux_func = function(card)
		local place = q(self.room,"getCardPlace",q(card,"getEffectiveId"))
		if place == sgs.Player_PlaceEquip then
			if q(card,"isKindOf","SilverLion") and q(self.player,"isWounded") then return -2
			elseif q(card,"isKindOf","OffensiveHorse") then return 1
			elseif q(card,"isKindOf","Weapon") then return 2
			elseif q(card,"isKindOf","DefensiveHorse") then return 3
			elseif q(card,"isKindOf","Armor") then return 4
			end
		elseif q(self,"getUseValue",card) >= 6 then return 3
		elseif q(self,"hasSkills",sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return q(self,"getKeepValue",a) < q(self,"getKeepValue",b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not q(self.player,"isJilei",card) then table.insert(to_discard, q(card,"getId")) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

sgs.ai_skill_use_func["#rushB_dimeng"] = function(card,use,self)
	local mycards = {}
	local myequips = {}
	local keepaslash
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if not q(self.player,"isJilei",c) then
			local shouldUse
			if not keepaslash and isCard("Slash", c, self.player) then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				q(self,"useBasicCard",c, dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length() > 1 or dummy_use.to:first():getHp() <= 1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards, c) end
		end
	end
	for _, c in sgs.qlist(q(self.player,"getEquips")) do
		if not q(self.player,"isJilei",c) then
			table.insert(mycards, c)
			table.insert(myequips, c)
		end
	end
	if #mycards == 0 then return end
	q(self,"sortByKeepValue",mycards) --�ҵ�keepValue��5��useValue��6��˳��ǣ���keepValue��1.9��useValue��9

	q(self,"sort",self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not q(self,"hasManjuanEffect",player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	q(self,"sort",friends, "defense")
	local function cmp_HandcardNum(a, b)
		local x = q(a,"getHandcardNum") - q(self,"getLeastHandcardNum",a)
		local y = q(b,"getHandcardNum") - q(self,"getLeastHandcardNum",b)
		return x < y
	end
	table.sort(friends, cmp_HandcardNum)

	q(self,"sort",self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if q(self,"hasManjuanEffect",enemy) then
			local e_hand = q(enemy,"getHandcardNum")
			for _, friend in ipairs(friends) do
				local f_peach, f_hand = getCardsNum("Peach", friend), q(friend,"getHandcardNum")
				if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					if e_hand == f_hand then
						use.card = card
					else
						local discard_num = e_hand - f_hand
						local discards = dimeng_discard(self, discard_num, mycards)
						if #discards > 0 then use.card = parse(self,"#rushB_dimeng:.:") end
					end
					if use.card and use.to then
						use.to:append(enemy)
						use.to:append(friend)
					end
					return
				end
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local e_hand = q(enemy,"getHandcardNum")
		for _, friend in ipairs(friends) do
			local f_hand = q(friend,"getHandcardNum")
			if DimengIsWorth(self, friend, enemy, mycards, myequips) and (e_hand > 0 or f_hand > 0) then
				if e_hand == f_hand then
					use.card = card
				else
					local discard_num = math.abs(e_hand - f_hand)
					local discards = dimeng_discard(self, discard_num, mycards)
					if #discards > 0 then use.card = parse(self,"#rushB_dimeng:.:") end
				end
				if use.to then
					use.to:append(enemy)
					use.to:append(friend)
					end
				return
			end
		end
	end
end

sgs.ai_card_intention["#rushB_dimeng"] = function(self,card, from, to)
	local compare_func = function(a, b)
		return q(a,"getHandcardNum") < q(b,"getHandcardNum")
	end
	table.sort(to, compare_func)
	if to[1]:getHandcardNum() < to[2]:getHandcardNum() then
		q(self,"updateIntention",from, to[1], -80)
	end
end

sgs.ai_use_value["#rushB_dimeng"] = 3.5
sgs.ai_use_priority["#rushB_dimeng"] = 2.8

sgs.dynamic_value.control_card["#rushB_dimeng"] = true

sgs.ai_fill_skill.rushB_diaogui=function(self,inclusive,request)

	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","EquipCard") then
			return parse(self,"#rushB_diaogui:"..c:getEffectiveId()..":")
		end
	end
end
sgs.ai_skill_use_func["#rushB_diaogui"] = function(card,use,self)
	local max_friends = 0
    local best_target = nil

    for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
        local temp_friends = 0

        local simulated_next = q(p,"getNextAlive")
        local simulated_prev = q(p,"getNextAlive",q(self.room,"alivePlayerCount") - 1)

        if q(self.player,"isYourFriend",simulated_prev) then
            temp_friends = temp_friends + 1
        end

        if q(self.player,"isYourFriend",simulated_next) then
            temp_friends = temp_friends + 1
        end

        if temp_friends > max_friends then
            max_friends = temp_friends
            best_target = p
        end
    end
	if best_target then
		use.card = card
		use.to:append(best_target)
	end
end

sgs.ai_use_priority["#rushB_diaogui"] = 5

sgs.ai_fill_skill.mmou_leiji=function(self,inclusive,request)
	return parse(self,"#mmou_leiji:.:")
end

sgs.ai_skill_use_func["#mmou_leiji"] = function(card,use,self)
	q(self,"sort",self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if q(self,"damageIsEffective",ep, sgs.DamageStruct_Thunder, self.player) and q(self,"canDamage",ep,self.player,nil) then 
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_fill_skill.mmou_guidao=function(self,inclusive,request)
	return parse(self,"#mmou_guidao:.:")
end

sgs.ai_skill_use_func["#mmou_guidao"] = function(card,use,self)
	use.card = card
end

sgs.ai_skill_cardask["@rushB_wushuang-slash"] = function(self,data,pattern,target)
	local use = q(data,"toCardUse")
	local effect = {}
	effect.card = use.card
	effect.from = use.from
	effect.to = self.player
	local _data = {toCardEffect=function()return effect end}
	if nested(self,"ai_skill_cardask","duel-slash",self,_data,pattern,use.from) == "." then return "." end
	if q(self,"getCardsNum","Slash")<3 then
		return "."
	end
	return true
end


sgs.ai_skill_cardask["@rushB_wushuang-jink"] = function(self,data,pattern,target)
	local use = q(data,"toCardUse")
	local effect = {}
	effect.card = use.card
	effect.from = use.from
	effect.to = self.player
	local _data = {toCardEffect=function()return effect end}
	local slash = sourceuse(self,"SlashData")
	if slash and slash.offset_num > 1 then
		if nested(self,"ai_skill_cardask","@multi-jink-start",self,data,"jink",q(data,"toCardEffect").from, nil, slash.offset_num) == "." then return "." end
	end
	return nested(self,"ai_skill_cardask","slash-jink",self,data,"jink",q(data,"toCardEffect").from)
end


sgs.ai_skill_use["@rushB_huace"] = function(self, prompt)
	local c = engineface(self,q(self.player,"getMark","rushB_huaceName"))
	local card = named(self,"rushB_huace",q(c,"objectName"),{})
    local dummy_use = q(self,"aiUseCard",card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, q(to,"objectName"))
            end
            return answer(self,dummy_use.card,tos)
        else
            return answer(self,dummy_use.card,{})
        end
    end
	return "."
end


sgs.ai_fill_skill.rushB_huace=function(self,inclusive,request)
	memory(self,"rushB_huace",nil,true)
	local huaces = {}
	for _, id in sgs.qlist(q(self.room,"getDiscardPile")) do
		local c = engineface(self,id)
		if (q(c,"isKindOf","BasicCard") or q(c,"isNDTrick")) and not (q(c,"isKindOf","Suijiyingbian") or q(c,"isKindOf","Jink") or q(c,"isKindOf","Nullification") or q(c,"isKindOf","FczhizheBasic") or q(c,"isKindOf","FczhizheTrick") or q(c,"isKindOf","KezhuanYing") or q(c,"isKindOf","BigJoker") or q(c,"isKindOf","SmallJoker")) then
			if not table.contains(huaces, q(c,"objectName")) and q(self.player,"getMark","rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, q(c,"objectName")) end
		end
	end
	if #huaces > 0 then
		for _, pn in sgs.list(RandomList(huaces)) do
			local dc = named(self,"rushB_huace",pn,{})
			local dummy_use = q(self,"aiUseCard",dc, dummy())
			if q(dc,"isAvailable",self.player) and dummy_use.card then
				if q(dc,"canRecast") and dummy_use.to:length()<1 then continue end
				memory(self,"rushB_huace",pn,true)
				sgs.ai_use_priority.rushB_huace = sgs.ai_use_priority[q(dc,"getClassName")]
				local card = parse(self,"#rushB_huace:.:")
				assert(card)
				return card
			end
		end
	end
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	local huaces = {}
	for _, id in draw_iter(self) do
		local c = engineface(self,id)
		if (q(c,"isKindOf","BasicCard") or q(c,"isNDTrick")) and not (q(c,"isKindOf","Suijiyingbian") or q(c,"isKindOf","Jink") or q(c,"isKindOf","Nullification") or q(c,"isKindOf","FczhizheBasic") or q(c,"isKindOf","FczhizheTrick") or q(c,"isKindOf","KezhuanYing") or q(c,"isKindOf","BigJoker") or q(c,"isKindOf","SmallJoker")) then
			if not table.contains(huaces, q(c,"objectName")) and q(self.player,"getMark","rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, q(c,"objectName")) end
		end
	end
	for _,c in sgs.list(cards)do
		for _, pn in sgs.list(RandomList(huaces)) do
			local dc = named(self,"rushB_huace",pn,{q(c,"getEffectiveId")})
			local dummy_use = q(self,"aiUseCard",dc, dummy())
			if q(dc,"isAvailable",self.player) and dummy_use.card then
				if q(dc,"canRecast") and dummy_use.to:length()<1 then continue end
				memory(self,"rushB_huace",pn,true)
				sgs.ai_use_priority.rushB_huace = sgs.ai_use_priority[q(dc,"getClassName")]
				local card = parse(self,"#rushB_huace:"..c:getEffectiveId() ..":")
				assert(card)
				return card
			end
		end
	end
end

sgs.ai_skill_use_func["#rushB_huace"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.rushB_huace = 5.4
sgs.ai_use_priority.rushB_huace = 2.8

sgs.ai_skill_choice.rushB_huace = function(self, choices, data)
	if memory(self,"rushB_huace") then return memory(self,"rushB_huace") end
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = named(self,"rushB_huace",pn,{})
		local dummy_use = q(self,"aiUseCard",dc, dummy())
		if q(dc,"isAvailable",self.player) and dummy_use.card then
			if q(dc,"canRecast") and dummy_use.to:length()<1 then continue end
			return pn
		end
	end
end

sgs.ai_fill_skill.rushB_pizhuan=function(self,inclusive,request)
	return parse(self,"#rushB_pizhuan:.:")
end

sgs.ai_skill_use_func["#rushB_pizhuan"] = function(card,use,self)
	use.card = card
end


sgs.ai_skill_use["@@rushB_tongbo"] = function(self, prompt)
	local c = engineface(self,q(self.player,"getMark","rushB_tongboName"))
	local card = named(self,"_rushB_tongbo",q(c,"objectName"),{})

    local dummy_use = q(self,"aiUseCard",card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, q(to,"objectName"))
            end
            return answer(self,card,tos)
        else
            return answer(self,card,{})
        end
    end
	return "."
end

sgs.ai_skill_choice.rushB_tongbo = function(self, choices, data)
	if memory(self,"rushB_tongbo") then return memory(self,"rushB_tongbo") end
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = named(self,"rushB_tongbo",pn,{})
		local dummy_use = q(self,"aiUseCard",dc, dummy())
		if q(dc,"isAvailable",self.player) and dummy_use.card then
			if q(dc,"canRecast") and dummy_use.to:length()<1 then continue end
			return pn
		end
	end
end

sgs.ai_fill_skill.rushB_tongbo=function(self,inclusive,request)
	memory(self,"rushB_tongbo",nil,true)
	local to_use = {}
	local suits = {}
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	for _, card in ipairs(cards) do
		if not table.contains(suits, q(card,"getSuitString")) then
			table.insert(to_use, q(card,"getId"))
			table.insert(suits, q(card,"getSuitString"))
			if #to_use == q(self.player,"getPile","bookpile"):length() then break end
		end
	end
	if #to_use < q(self.player,"getPile","bookpile"):length() then
		return
	end
	local choices = {}
	for _,id in draw_iter(self) do
		    local card = engineface(self,id)
			if q(card,"isNDTrick") or q(card,"isKindOf","BasicCard") then
				if table.contains(choices, q(card,"objectName")) or q(card,"isKindOf","Jink") or q(card,"isKindOf","Nullification") then continue end
				local transcard = named(self,"rushB_tongbo",q(card,"objectName"),{})
				
				if not q(transcard,"isAvailable",self.player) then continue end
				if q(self.player,"getMark","rushB_tongbo".."+"..card:objectName().."-Clear") < 1 then table.insert(choices, q(card,"objectName")) end
			end
			if not q(self.player,"isWounded") then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(self.player) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(self.player) then
				table.removeOne(choices, "analeptic")
			end
		end
		for _,id in sgs.qlist(q(self.room,"getDiscardPile")) do
		    local card = engineface(self,id)
			if q(card,"isNDTrick") or q(card,"isKindOf","BasicCard") then
				if table.contains(choices, q(card,"objectName")) or q(card,"isKindOf","Jink") or q(card,"isKindOf","Nullification") then continue end
				local transcard = named(self,"rushB_tongbo",q(card,"objectName"),{})
				
				if not q(transcard,"isAvailable",self.player) then continue end
				if q(self.player,"getMark","rushB_tongbo".."+"..card:objectName().."-Clear") < 1 then table.insert(choices, q(card,"objectName")) end
			end
			if not q(self.player,"isWounded") then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(self.player) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(self.player) then
				table.removeOne(choices, "analeptic")
			end
		end
	for _, pn in sgs.list(RandomList(choices)) do
		local dc = named(self,"rushB_tongbo",pn,{q(self.player,"getPile","bookpile"):first()})
		local dummy_use = q(self,"aiUseCard",dc, dummy())
		if q(dc,"isAvailable",self.player) and dummy_use.card then
			if q(dc,"canRecast") and dummy_use.to:length()<1 then continue end
			memory(self,"rushB_tongbo",pn,true)
			sgs.ai_use_priority.rushB_tongbo = sgs.ai_use_priority[q(dc,"getClassName")]
			local card = parse(self,"#rushB_tongbo:".. table.concat(to_use, "+") ..":")
			assert(card)
			return card
		end
	end
	
end

sgs.ai_skill_use_func["#rushB_tongbo"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.rushB_tongbo = 5.4
sgs.ai_use_priority.rushB_tongbo = 2.8


sgs.ai_skill_use["@@rushB_xiongsuan"] = function(self, prompt)
	local c = engineface(self,q(self.player,"getMark","rushB_xiongsuanName"))
	local card = named(self,"_rushB_xiongsuan",q(c,"objectName"),{})
    local dummy_use = q(self,"aiUseCard",card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, q(to,"objectName"))
            end
            return answer(self,card,tos)
        else
            return answer(self,card,{})
        end
    end
	return "."
end
sgs.ai_skill_choice.rushB_xiongsuan = function(self, choices, data)
	local choices = {}
	for _,id in sgs.qlist(random_catalogue(self)) do
		local card = engineface(self,id)
		if q(card,"isKindOf","BasicCard") or q(card,"isNDTrick") then
			if table.contains(choices, q(card,"objectName")) then continue end
			local transcard = named(self,"rushB_xiongsuan",q(card,"objectName"),{})
			if not q(transcard,"isAvailable",self.player) then continue end
			if q(self.player,"getMark","rushB_xiongsuan+"..card:objectName().."-Clear") < 1 then table.insert(choices, q(card,"objectName")) end
		end
	end
	if nested(self,"ai_skill_choice","rushB_xiongsuanUse",self, table.concat(choices, "+")) ~= "cancel" then
		return "yes"
	end
	return "no"
end
sgs.ai_skill_choice.rushB_xiongsuanUse = function(self, choices, data)
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = named(self,"_rushB_xiongsuan",pn,{})
		local dummy_use = q(self,"aiUseCard",dc, dummy())
		if q(dc,"isAvailable",self.player) and dummy_use.card then
			if q(dc,"canRecast") and dummy_use.to:length()<1 then continue end
			return pn
		end
	end
	return "cancel"
end


sgs.ai_fill_skill.rushB_moutongye=function(self,inclusive,request)
	local n = q(self.player,"getChangeSkillState","rushB_moutongye")
	if n == 1 then
		if q(self,"getCardsNum","BasicCard")>q(self,"getCardsNum","TrickCard")+q(self,"getCardsNum","EquipCard") then
			return parse(self,"#rushB_moutongye:.:")
		end
	elseif n == 2 then
		if q(self,"getCardsNum","TrickCard")>q(self,"getCardsNum","EquipCard")+q(self,"getCardsNum","BasicCard") then
			return parse(self,"#rushB_moutongye:.:")
		end
	elseif n == 3 then
		if q(self,"getCardsNum","EquipCard")>q(self,"getCardsNum","TrickCard")+q(self,"getCardsNum","BasicCard") then
			return parse(self,"#rushB_moutongye:.:")
		end
	end
end

sgs.ai_skill_use_func["#rushB_moutongye"] = function(card,use,self)
	use.card = card
end
sgs.ai_use_priority.rushB_moutongye = 10

sgs.ai_card_priority.rushB_xingtu = function(self,card,v)
	if q(self.player,"getMark","&rushB_xingtunum") % q(card,"getNumber") == 0 or q(card,"getNumber") % q(self.player,"getMark","&rushB_xingtunum") == 0
	then return 10 end
end


sgs.ai_fill_skill.rushB_juezhi=function(self,inclusive,request)
	sgs.ai_use_priority.rushB_juezhi = 3
	if q(self.player,"getCardCount",true)<2 then return false end
	if q(self,"getOverflow")<=0 then return false end
	if q(self,"isWeak") and q(self,"getOverflow")<=1 then return false end
	return parse(self,"#rushB_juezhi:.:")
end
sgs.ai_skill_use_func["#rushB_juezhi"] = function(card,use,self)
	local num = q(self.player,"getMark","&rushB_xingtunum")
	local unpreferedCards = {}
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)

	for _,c1 in ipairs(cards)do
		local temp = 0
		temp = temp + q(c1,"getNumber")
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not q(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) and not q(self.player,"isCardLimited",c1,sgs.Card_MethodDiscard) and q(c1,"getNumber") % q(c,"getNumber") == 0 then
					if table.contains(unpreferedCards,q(c,"getId")) then continue end
					if (((temp + q(c,"getNumber")) % num) == 0) then
						temp = temp + q(c,"getNumber")
						table.insert(unpreferedCards,q(c,"getId"))
						table.insert(unpreferedCards,q(c1,"getId"))
						break
					end
					
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end

	if #unpreferedCards==2 then
		use.card = parse(self,"#rushB_juezhi:"..table.concat(unpreferedCards,"+")..":")
		sgs.ai_use_priority.rushB_juezhi = 0
		return
	end
	for _,c1 in ipairs(cards)do
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not q(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) and not q(self.player,"isCardLimited",c1,sgs.Card_MethodDiscard) and q(c1,"getNumber") % q(c,"getNumber") == 0 then
					if table.contains(unpreferedCards,q(c,"getId")) then continue end
					table.insert(unpreferedCards,q(c,"getId"))
					table.insert(unpreferedCards,q(c1,"getId"))
					break
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end
	use.card = parse(self,"#rushB_juezhi:"..table.concat(unpreferedCards,"+")..":")
	sgs.ai_use_priority.rushB_juezhi = 0
	return
end

sgs.ai_use_priority.rushB_juezhi = 3

sgs.ai_fill_skill.sgskanxue=function(self,inclusive,request)
	return parse(self,"#sgskanxue:.:")
end
sgs.ai_skill_use_func["#sgskanxue"] = function(card,use,self)
	use.card = card
end
sgs.ai_use_priority.sgskanxue = 10

sgs.ai_skill_choice.sgskanxue = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "throwsame") then
		return "throwsame"
	end
	return items[math.random(1, #items)]
end

sgs.ai_fill_skill.sgszhenhua=function(self,inclusive,request)
	return parse(self,"#sgszhenhua:.:")
end
sgs.ai_skill_use_func["#sgszhenhua"] = function(card,use,self)
	for _,enemy in ipairs(self.enemies)do
		if q(self,"doDisCard",enemy, "he") and q(enemy,"getMark","sgszhenhua-Clear") == 0 then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end
-- audited alias ai_use_priority.sgszhenhua
sgs.ai_skill_playerchosen["sgszhenhua"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_invoke.rushB_kanxue = function(self, data)
	return q(self.player,"getHujia") < 5 and q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0
end


sgs.ai_view_as.rushB_kanxue = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and q(card,"isRed") and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
		return view(own_ai(player),("slash:rushB_kanxue[%s:%s]=%d"):format(suit,number,card_id))
	end
end

sgs.ai_fill_skill.rushB_kanxue=function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	cards = q(self,"sortByUseValue",cards,true)
	local red_card = {}
	local useAll = false
	q(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")<2 and not q(enemy,"hasArmorEffect","EightDiagram")
		and q(self.player,"distanceTo",enemy)<=q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	q(self,"sort",self.enemies,"defense")

	for _,card in ipairs(cards)do
		if q(card,"isRed") and not q(card,"isKindOf","Slash") 	and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or q(evaluation(self),"getTargetResidue",self.player)>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash = named(self,"rushB_kanxue","slash",{q(card,"getEffectiveId")})
		if q(slash,"isAvailable",self.player)
		then return slash end
	end
end

sgs.ai_skill_invoke.rushB_kanxue_yuqi = true

sgs.ai_skill_use["@@DIT_qianxun!"] = function(self, prompt)
	return response(self,"#DIT_qianxun:.:")
end

sgs.ai_skill_choice["@DIT_qianxun"] = function(self, choices, data)
	return "yes"
end


sgs.ai_view_as.DIT_duoshi = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(q(player,"getCards","h"))
	if q(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(player,"getPile","wooden_ox")) do
			table.insert(usable_cards, face(self,id))
		end
	end
	local two_cards = {}
	for _, c in ipairs(usable_cards) do
		if #two_cards < 2 then
			table.insert(two_cards, q(c,"getEffectiveId"))
		end
	end
	if #two_cards == 2 and not q(card,"isKindOf","Jink") then
		return view(own_ai(player),("jink:DIT_duoshi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2]))
	end
	if #two_cards == 2 and not q(card,"isKindOf","Slash") then
		return view(own_ai(player),("slash:DIT_duoshi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2]))
	end
end


sgs.ai_fill_skill.DIT_duoshi=function(self,inclusive,request)
	return turnUse_spear(self,"DIT_duoshi",request)
end

sgs.ai_fill_skill.DIT_if_mouhuoji=function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	local card
	q(self,"sortByUseValue",cards,true)
	for _,acard in ipairs(cards)do
		if q(acard,"isRed") and not q(acard,"isKindOf","Peach") and (q(self,"getDynamicUsePriority",acard)<sgs.ai_use_value.FireAttack or q(self,"getOverflow")>0) then
			if q(acard,"isKindOf","Slash") and q(self,"getCardsNum","Slash")==1 then
				local keep
				local dummy_use = dummy()
				q(self,"useBasicCard",acard,dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length()>0 then
					for _,p in sgs.list(dummy_use.to)do
						if q(p,"getHp")<=1 then keep = true break end
					end
					if dummy_use.to:length()>1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack+0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	return parse(self,("fire_attack:DIT_if_mouhuoji[%s:%s]=%d"):format(suit,number,card_id))
end

sgs.ai_skill_cardask["@DIT_if_mouhuoji"] = function(self,data,pattern, target, target2)
	local use = q(data,"toCardUse")
	if (not q(self,"isFriend",target2) or q(target2,"isChained"))
		and q(self,"damageIsEffective",target2,use.card) then
		return true
	end
    return "."
end

sgs.ai_skill_choice.DIT_if_mouhuoji = function(self, choices, data)
	return "1"
end

sgs.ai_skill_askforag.DIT_if_mouhuoji = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = face(self,id)
		if getCardsNum(q(card,"getSuitString"),self.player,self.player)> 0 then
			return id
		end
	end
end
sgs.ai_cardneed.DIT_if_mouhuoji = function(to,card,self)
	return nested(self,"ai_cardneed","huoji",to,card,self)
end

sgs.ai_view_as.DIT_if_moukanpo = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand or card_place==sgs.Player_PlaceEquip then
		if q(card,"isBlack") then
			return view(own_ai(player),("nullification:DIT_if_moukanpo[%s:%s]=%d"):format(suit,number,card_id))
		end
	end
end

sgs.ai_skill_choice.DIT_if_moukanpo = function(self, choices, data)
	return "1"
end

sgs.ai_cardneed.DIT_if_moukanpo = function(to,card,self)
	return nested(self,"ai_cardneed","kanpo",to,card,self)
end


sgs.ai_skill_invoke.mk_danlveYY = function(self, data)
   	local use = q(data,"toCardUse")
	if q(use.card,"isKindOf","DelayedTrick") or q(use.card,"isKindOf","EquipCard") then return false end
    return true
end
sgs.ai_skill_invoke.mk_danlveQG = function(self, data)
   	local use = q(data,"toCardUse")
	if q(use.card,"isKindOf","DelayedTrick") or q(use.card,"isKindOf","EquipCard") then return false end
    return true
end


sgs.ai_fill_skill.mk_danlve_yinyue=function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(q(self.player,"getPile","mk_danlve_yinyue"))do
		local card = face(self,id)
		card = touch_physical(self,card,"mk_danlve_yinyue")
		table.insert(cs,card)
	end
	return cs
end

function sgs.ai_cardsview.mk_danlve_yinyue(self,class_name,player)
	for _,id in sgs.list(q(player,"getPile","mk_danlve_yinyue"))do
		if face(self,id):isKindOf(class_name) then 
			local card = face(self,id)
			card = touch_physical(self,card,"mk_danlve_yinyue")
			return card:toString() 
		end
	end
end
sgs.ai_fill_skill.mk_danlve_qinggang=function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(q(self.player,"getPile","mk_danlve_qinggang"))do
		local card = face(self,id)
		card = touch_physical(self,card,"mk_danlve_qinggang")
		table.insert(cs,card)
	end
	return cs
end

function sgs.ai_cardsview.mk_danlve_qinggang(self,class_name,player)
	for _,id in sgs.list(q(player,"getPile","mk_danlve_qinggang"))do
		if face(self,id):isKindOf(class_name) then 
			local card = face(self,id)
			card = touch_physical(self,card,"mk_danlve_qinggang")
			return card:toString() 
		end
	end
end

sgs.ai_skill_invoke.mk_kongying = true

sgs.ai_ajustdamage_from.mk_kongying = function(self,from,to,card,nature)
	if card and q(from,"getMark","mk_kongyingJS") == q(card,"getEffectiveId")
	then return 1 end
end

sgs.ai_card_priority.mk_kongying = function(self,card,v)
	if q(self.player,"getMark","&mk_kongying")==1
	and table.contains(q(card,"getSkillNames"), "mk_danlve_qinggang")
	then return 10 end
	if q(self.player,"getMark","&mk_kongying")==0
	and table.contains(q(card,"getSkillNames"), "mk_danlve_yinyue") and q(self.player,"getPile","mk_danlve_qinggang"):length() > 0
	then return 10 end
end


ai_audited_aliases.register({id="ai_skill_playerchosen.diy_k_qizhi",registry="ai_skill_playerchosen",path={"diy_k_qizhi"},canonical_registry="ai_skill_playerchosen",canonical_path={"qizhi"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.diy_k_qice",registry="ai_use_priority",path={"diy_k_qice"},canonical_registry="ai_use_priority",canonical_path={"QiceCard"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_card_intention.rushB_baobian_tiaoxin",registry="ai_card_intention",path={"rushB_baobian_tiaoxin"},canonical_registry="ai_card_intention",canonical_path={"TiaoxinCard"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.rushB_baobian_tiaoxin",registry="ai_use_priority",path={"rushB_baobian_tiaoxin"},canonical_registry="ai_use_priority",canonical_path={"TiaoxinCard"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.sgszhenhua",registry="ai_use_priority",path={"sgszhenhua"},canonical_registry="ai_use_priority",canonical_path={"Dismantlement"},self_index=1,defer_canonical=true})
