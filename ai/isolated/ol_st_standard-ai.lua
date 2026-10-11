-- Fixed b6025acc ol_st_standard policy; native source scopes own construction.
local function known(v,k) if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('OL standard source input is unknown',k)end;return v end
local nullable={AssistTarget=true,withOwnerDistanceAdjustment=true,getStrategyMemory=true,getCurrent=true,getCurrentDyingPlayer=true,getLord=true,getArmor=true,getWeapon=true,getEquip=true,getMaxCard=true,getMinCard=true,getSameEquip=true,getCard=true,getCardId=true,getCardNeedPlayer=true,findPlayerByObjectName=true,findPlayerBySkillName=true,toPlayer=true,updateIntention=true,updatePlayers=true,moveField=true,aiUseCard=true,useCardSlash=true,useBasicCard=true,useTrickCard=true,useEquipCard=true,useCardByClassName=true,setStrategyMemory=true,setStrategyPlayerFlag=true,setStrategyCardFlag=true}
local function q(o,k,...)
 if not o or type(o[k])~='function'then ai_unsupported('OL standard helper unavailable',k)end
 local method=k;if k=='getMark'and AIValue.isPlayer(o)then method='getStrategyMark'end
 if k=='hasFlag'and AIValue.isPlayer(o)then method='getStrategyFlag'end
 local provider=o[method];local r=table.pack(provider(o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='getRole'and r[1]==nil and AIValue.isPlayer(o)then
  local ai=o._room and o._room._ai;if not ai or type(ai.getRoleEstimate)~='function'then ai_unsupported('OL role viewpoint estimate unavailable','getRole')end
  r[1]=ai:getRoleEstimate(o);r.n=1
  if r[1]==nil or r[1]=='unknown'or r[1]=='neutral'then ai_unsupported('OL private role estimate is unresolved','getRole')end
  r[1]=ai:useKnowledgeEstimate({value=r[1],status='estimate',basis='viewer_role_inference_replaces_private_role',viewer=ai.player:objectName(),target=o:objectName()},'ol_st_standard.role')
 end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,x in ipairs(r[1])do t[i]=x end;return t end
 if (k=='hasSkill'or k=='hasSkills')and AIValue.isPlayer(o)and r[1]==false and o._view.skills_complete~=true then ai_unsupported('OL standard foreign skill absence unknown',(...))end
 if r[1]==nil and type(SmartAIView.isKnownNilStrategyResult)=='function'and SmartAIView.isKnownNilStrategyResult(o,method,provider)then return table.unpack(r,1,r.n)end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function callback(self,registry,key,...)
 local f=q(self,'getHooks',registry)[key];if type(f)~='function'then ai_unsupported('OL standard shared source callback missing',registry..'.'..key)end
 local r=table.pack(f(...));if AIUnsupported.is(r[1])then error(r[1],0)end;return table.unpack(r,1,r.n)
end
local function face(self,id)return q(self,'getKnownCardById',id)end
local function evaluation(self,name)return q(self,'getEvaluationCard',name or 'slash')end
local function spec(c,name,skill)return{name=name,skill=skill,suit=q(c,'getSuit'),number=q(c,'getNumber'),subcards={q(c,'getEffectiveId')}}end
local classes={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic',fire_attack='FireAttack',iron_chain='IronChain',nullification='Nullification',archery_attack='ArcheryAttack',supply_shortage='SupplyShortage'}
local function turn(self,skill,name,ids,material,request)
 local proposal=material and spec(material,name,skill)or{name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=ids}
 return q(self,'evaluateTurnConversion',skill,known(classes[name],name),proposal,request)
end
local function declared(self,skill,name,ids)return q(self,'evaluateSkillCard',skill,name,ids)end
local selectors={OLJijiangCard='oljijiang',OLHuangtianCard='olhuangtian_attach',OLGuhuoCard='olguhuo',OLQimouCard='olqimou',OLZhibaCard='olzhiba',OLZhibaPindianCard='olzhiba_pindian',OLChangbiaoCard='olchangbiao',OLTiaoxinCard='oltiaoxin',OLQiangxiCard='olqiangxi',OLJianmieCard='oljianmie',OLMiejiCard='olmieji',OLZhijianCard='olzhijian',OLQiaobianCard='olqiaobian',OLTianxiangCard='oltianxiang',OLWulieCard='olwulie',OLFangquanCard='olfangquan',OLXuanhuoCard='olxuanhuo',OLZaiqiCard='olzaiqi',OLZongxuanCard='olzongxuan',SecondOLHanzhanCard='secondolhanzhan',OLChunlaoCard='olchunlao'}
local function parse(self,wire,request,paid)
 if type(wire)~='string'then error('Card_Parse expects a string',0)end
 local cls,costs,user=wire:match('^@([%w_]+)=([^:]+):?(.*)$')
 local skill=cls and selectors[cls];if not skill then ai_unsupported('OL standard unrepresented source constructor',wire)end
 local ids={};if costs~='.'then for id in costs:gmatch('[^+]+')do ids[#ids+1]=known(tonumber(id),'source cost')end end
 if user==''then user=nil end
 if paid then return q(self,'bindSkillCard',skill,ids,request,user,cls)end
 return q(self,'evaluateTurnSkillCard',skill,cls,ids,request,user)
end
local function response(self,wire)
 local cardtext,targets=wire:match('^(.-)%->(.*)$');cardtext=cardtext or wire
 local card=parse(self,cardtext,nil,true);local names={};for name in (targets or''):gmatch('[^+]+')do names[#names+1]=name end
 return{kind='use_card',card_spec=q(card,'toCardSpec'),targets=names}
end
local function facts(self)return known(q(self,'getDecisionContext').ol_st_standard,'ol_st_standard.context')end
local function tag(self,key,kind)
 local row=known(known(facts(self).tags,'ol_st_standard.tags')[key],key)
 if row.known~=true then ai_unsupported('OL standard owner tag is not observed',key)end
 if kind=='card' then return row.present and face(self,known(row.card_id,key))or nil end
 if kind=='use'then
  if not row.present then return{card=nil,to=AIList.new({})}end
  local use=known(row.use,key);return{card=use.card_id and face(self,use.card_id),from=use.from and self.room:findPlayerByObjectName(use.from),to=AIList.new((function()local p={}for _,n in ipairs(use.to or{})do p[#p+1]=known(self.room:findPlayerByObjectName(n),key)end;return p end)())}
 end
 return known(row.value,key)
end
local function source_flag(self,p,flag)
 local remove=flag:sub(1,1)=='-';return q(self,'setStrategyPlayerFlag',p,remove and flag:sub(2)or flag,not remove)
end
-- Memory stores only legal source facts, never turns an observation into a receipt.
local function encode(v)
 if v==nil then return{kind='nil'}end
 if AIValue.isPlayer(v)then return{kind='player',name=q(v,'objectName')}end
 if AIValue.isCard(v)or AIValue.isConversion(v)then
  if q(v,'isVirtualCard')then ai_unsupported('OL stored virtual card requires bound recipe','ol_st_standard.memory')end
  return{kind='card',id=q(v,'getEffectiveId')}
 end
 if type(v)=='table'then local a={}for k,x in pairs(v)do a[k]=encode(x)end;return{kind='table',value=a}end
 return{kind='scalar',value=v}
end
local function decode(self,v)
 if v.kind=='nil'then return nil elseif v.kind=='player'then return q(self.room,'findPlayerByObjectName',v.name,true)
 elseif v.kind=='card'then return face(self,v.id)elseif v.kind=='table'then local a={}for k,x in pairs(v.value)do a[k]=decode(self,x)end;return AIList.new(a)
 elseif v.kind=='scalar'then return v.value end
 ai_unsupported('OL stored policy value malformed','ol_st_standard.memory')
end
local state_keys={'guhuo_to','olqimou_lose','olzhiba_card','olzhiba_pindian_card','olcb_to','olqiaobian_phase','olqiaobian_to','olqiaobian_ej'}
local function load_state(self)
 for _,key in ipairs(state_keys)do local v,present=q(self,'getStrategyMemory','ol_st_standard.'..key);if present then self[key]=decode(self,v)end end
end
local function save_state(self)
 for _,key in ipairs(state_keys)do q(self,'setStrategyMemory','ol_st_standard.'..key,encode(self[key]))end
end
local function global_call(self,op,value)
 if type(ai_ol_jijiang_state)~='function'then ai_unsupported('OLJijiang continuity host missing','oljijiang')end
 local row=ai_ol_jijiang_state(op,value)
 if type(row)~='table'or row.kind~='ol_jijiang_state'or row.known~=true then ai_unsupported(type(row)=='table'and(row.reason or row.error)or'OLJijiang state unknown','oljijiang')end
 return row
end
local function write_global(self,key,value)
 if key=='oljijiangsource'then
  global_call(self,value and'source_write'or'source_clear',value and q(value,'objectName')or nil)
 elseif key=='oljijiangtarget'then
  if value==nil then global_call(self,'targets_clear')
  elseif type(value)=='table'and #value==0 then global_call(self,'targets_reset')
  else ai_unsupported('OLJijiang target writer shape differs','oljijiang')end
 end
 self[key]=value
end
local function global_source(self)
 local row=global_call(self,'source_read')
 if row.present==false then return nil end
 return known(q(self.room,'findPlayerByObjectName',known(row.player,'OLJijiang source'),true),'OLJijiang current roster')
end
local olguhuo_policy
local function general(self,name)
 local ctx=q(self,"getDecisionContext");local row=ctx.general_catalog and ctx.general_catalog[name]
 if row then
  if row.exists==false then return nil end
  return{getMaxHp=function()return known(row.max_hp,name)end,getSkillDescription=function()return known(row.skill_description,name)end}
 end
 row=known(facts(self).huashen_generals and facts(self).huashen_generals[name],name)
 if row.exists==false then return nil end
 return{getVisibleSkillList=function()local out={}for _,key in ipairs(known(row.skills,name))do local k=key;out[#out+1]={objectName=function()return k end}end;return AIList.new(out)end}
end
-- Fixed b6025 effective top-level general-choice functions (15 literal keys).
-- Missing isolated bodies stay unknown; an unregistered name remains source nil.
local source_general_choices={ov_lusu=true,ov_zhaoe=true,heg_qingcheng=true,mobilemou_caoren=true,mobilemou_gaoshun=true,mobilemou_lvmeng=true,mobilemou_machao=true,sp_machao=true,tw_machao=true,xizhicai=true,liubei=true,nos_huanggai=true,nos_liubei=true,nos_xiahoudun=true,cenhun=true}
-- Missing fixed dependencies are private to this reached OL recommendation.
-- Native metadata verifies the actual configured source; this is not a global
-- registry overwrite or a guessed absent callback.
local recommendation_sources={mobilemou_machao={'mobile-ai.lua',5565,5576},mobilemou_lvmeng={'mobile-ai.lua',5579,5598},mobilemou_caoren={'mobile-ai.lua',5601,5606},mobilemou_gaoshun={'mobile-ai.lua',5609,5614},xizhicai={'sp-ai.lua',11115,11130},sp_machao={'sp-ai.lua',11133,11144},tw_machao={'sp-ai.lua',11147,11158}}
local function lord_general(self,lord)
 local facts=known(self.world.strategy_facts.target_recommend,'general description facts')
 local rows=known(facts.general_descriptions,'general descriptions')
 local row=known(known(rows[q(lord,'objectName')],'lord description').first,'lord first general')
 if row.known~=true then ai_unsupported('OL recommendation lord general is not disclosed','ol.general')end
 if row.present==false then return nil end
 if row.present~=true then ai_unsupported('OL recommendation general presence unknown','ol.general')end
 return{getSkillDescription=function(_,includeName)if includeName~=true then ai_unsupported('OL exact description flag differs','ol.general')end;return known(row.text,'lord skill description')end}
end
local recommendations={}
recommendations.mobilemou_machao=function(ai,lord,role)
 if not lord then return 0 end
 if role=='rebel' then local desc=lord_general(ai,lord):getSkillDescription(true)or'';if string.find(desc,'受到伤害')then return 1 end end
 return 0
end
recommendations.sp_machao=recommendations.mobilemou_machao
recommendations.tw_machao=recommendations.mobilemou_machao
recommendations.mobilemou_lvmeng=function(ai,lord,role)
 if role=='renegade'or role=='villager'then return 1 end
 if lord then local g=lord_general(ai,lord);if g then local desc=g:getSkillDescription(true)or''
  if string.find(desc,'失去')and string.find(desc,'体力')then return -1 end
  if string.find(desc,'体力流失')then return -1 end
 end end
 return 0
end
recommendations.mobilemou_caoren=function(ai,lord,role)if role=='loyalist'then return -1 end;return 0 end
recommendations.mobilemou_gaoshun=function(ai,lord,role)if role=='rebel'then return 1 end;return 0 end
recommendations.xizhicai=function(ai,lord,role)
 if not lord then return 0 end
 if role=='loyalist'then local g=lord_general(ai,lord);if g then local desc=g:getSkillDescription(true)or''
  if string.find(desc,'受到伤害')or string.find(desc,'体力流失')or(string.find(desc,'失去')and string.find(desc,'体力'))then return 1 end
 end end
 return 0
end
local function general_choice(self,key)
 if not source_general_choices[key]then return nil end
 local row=known(known(q(self,'getDecisionContext').ol_general_sources,'actual source recommendations')[key],key)
 if row.known~=true then ai_unsupported('OL general source provider is unknown',key)end
 if row.present==false or row.value_type~='function'then return nil end
 local f=q(self,'getHooks','ai_general_choice')[key]
 if type(f)=='function'then return f end
 local source=recommendation_sources[key]
 if source and type(row.source)=='string'and row.source:sub(-#source[1])==source[1]and row.line==source[2]and row.last_line==source[3]then return recommendations[key]end
 ai_unsupported('OL general source recommendation body differs',key)
end

-- Mountain donor 527–565 returns a proposal string. The isolated Mountain
-- entry binds immediately, so this private copy preserves only that original
-- selection body for OL's later literal class substitution (no early receipt).
local function fangquan_proposal(self)
 local cards=q(self.player,'getHandcards');q(self,'sortByKeepValue',cards)
 local function wire(p)return '@FangquanCard='..q(cards[1],'getEffectiveId')..'->'..q(p,'objectName')end
 if known(q(self,'getRoleCounts').rebel,'role_count.rebel')==0 then
  local lord=q(self.room,'getLord');if lord and q(self,'isFriend',lord)and q(lord,'objectName')~=q(self.player,'objectName')then return wire(lord)end
 end
 local target=q(self,'AssistTarget');if target and not q(self,'willSkipPlayPhase',target)then return wire(target)end
 q(self,'sort',self.friends_noself,'chaofeng')
 for _,p in ipairs(self.friends_noself)do
  if not q(p,'hasSkill','dawu')and q(p,'hasSkills','yongsi|zhiheng|'..sgs.priority_skill..'|shensu')
   and(not q(self,'willSkipPlayPhase',p)or q(p,'hasSkill','shensu'))then return wire(p)end
 end
 for _,p in ipairs(self.friends_noself)do
  if q(p,'hasSkill','dawu')then local use=true;for _,other in ipairs(self.friends_noself)do if q(other,'getMark','&dawu')>0 then use=false;break end end
   if use then return wire(p)end
  else return wire(p)end
 end
 return '.'
end
-- The isolated core need not install every legacy event bucket. Preserve any
-- existing entries, and create only the three nested registries this module writes.
for _,bucket in ipairs({'skillInvoke','cardResponded','pindian'})do
 sgs.ai_choicemade_filter[bucket]=sgs.ai_choicemade_filter[bucket]or{}
end
local before_nested={};for key,t in pairs(sgs.ai_choicemade_filter)do if type(t)=='table'then before_nested[key]={};for k,v in pairs(t)do before_nested[key][k]=v end end end
local before={};for registry,t in pairs(sgs)do if type(t)=='table'then before[registry]={};for k,v in pairs(t)do before[registry][k]=v end end end


sgs.ai_choicemade_filter.OLJijiangCard = function(self,player,carduse)
	write_global(self,"oljijiangsource",player)
end

sgs.ai_skill_invoke.jijiang = function(self,data)
	if not q(self.player,"isLord") then return end
	if global_source(self) then return false end
	local asked = q(data,"toStringList")
	local prompt = asked[2]
	if q(self,"askForCard","slash",prompt,1)=="." then return false end

	local current = q(self.room,"getCurrent")
	if q(self,"isFriend",current) and q(current,"getKingdom")=="shu" and q(self,"getOverflow",current)>2 and not q(self,"hasCrossbowEffect",current) then
		return true
	end

	local cards = q(self.player,"getHandcards")
	for _,card in sgs.list(cards)do
		if isCard("Slash",card,self.player) then
			return false
		end
	end

	local lieges = q(self.room,"getLieges","shu",self.player)
	if lieges:isEmpty() then return false end
	local has_friend = false
	for _,p in sgs.list(lieges)do
		if not q(self,"isEnemy",p) then
			has_friend = true
			break
		end
	end
	return has_friend
end

sgs.ai_choicemade_filter.skillInvoke.oljijiang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		write_global(self,"oljijiangsource",player)
	end
end

sgs.ai_fill_skill.oljijiang = function(self,inclusive,request)
	local lieges = q(self.room,"getLieges","shu",self.player)
	if lieges:isEmpty() then return end
	local has_friend
	for _,p in sgs.list(lieges)do
		if q(self,"isFriend",p) then
			return parse(self,"@OLJijiangCard=.")
		end
	end
end

sgs.ai_skill_use_func.OLJijiangCard = function(card,use,self)
	q(self,"sort",self.enemies,"defenseSlash")
	write_global(self,"oljijiangtarget",{})
	local dummy_use = AIUsePlan.new()
	dummy_use.to = AIList.new({})
	if q(self.player,"hasFlag","slashTargetFix") then
		for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
			if q(p,"hasFlag","SlashAssignee") then
				dummy_use.to:append(p)
			end
		end
	end
	local slash = evaluation(self)
	q(self,"useCardSlash",slash,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		use.card = card
		for _,p in sgs.list(dummy_use.to)do
			global_call(self,'targets_append',q(p,'objectName'))
			table.insert(self.oljijiangtarget,p)
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.OLJijiangCard = sgs.ai_use_value.JijiangCard+0.1
sgs.ai_use_priority.OLJijiangCard = sgs.ai_use_priority.JijiangCard+0.1

sgs.ai_card_intention.OLJijiangCard = function(self,card,from,tos)
	return callback(self,"ai_card_intention","JijiangCard",self,card,from,tos)
end

sgs.ai_choicemade_filter.cardResponded["@oljijiang-slash"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		q(self,"updateIntention",player,global_source(self),-40)
		write_global(self,"oljijiangsource",nil)
		write_global(self,"oljijiangtarget",nil)
	elseif global_source(self) and q(player,"objectName")==q(player,"getRoom"):getLieges("shu",global_source(self)):last():objectName() then
		write_global(self,"oljijiangsource",nil)
		write_global(self,"oljijiangtarget",nil)
	end
end

sgs.ai_skill_cardask["@oljijiang-slash"] = function(self,data)
	if not global_source(self) or not q(self,"isFriend",global_source(self)) then return "." end
	if q(self,"needBear") then return "." end

	local jijiangtargets = {}
	for _,player in sgs.list(q(self.room,"getAllPlayers"))do
		if q(player,"hasFlag","JijiangTarget") then
			if q(self,"isFriend",player) and not q(self,"needToLoseHp",player,global_source(self),evaluation(self)) then return "." end
			table.insert(jijiangtargets,player)
		end
	end

	if #jijiangtargets==0 then
		return q(self,"getCardId","Slash") or "."
	end

	q(self,"sort",jijiangtargets,"defenseSlash")
	local slashes = q(self,"getCards","Slash")
	for _,slash in ipairs(slashes)do
		for _,target in ipairs(jijiangtargets)do
			if not q(self,"slashProhibit",slash,target,global_source(self)) and q(self,"slashIsEffective",slash,target,global_source(self)) then
				return q(slash,"toString")
			end
		end
	end
	return "."
end

function sgs.ai_cardsview_valuable.oljijiang(self,class_name,player)
	local current = q(self.room,"getCurrent")
	if q(current,"getKingdom")=="shu" and q(self,"getOverflow",current)>2 and not q(self,"hasCrossbowEffect",current)
	then
		source_flag(self,self.player,"stack_overflow_jijiang")
		local isfriend = q(self,"isFriend",current,player)
		source_flag(self,self.player,"-stack_overflow_jijiang")
		if isfriend then return "@OLJijiangCard=." end
	end
	local cards = q(player,"getHandcards")
	for _,card in sgs.list(cards)do
		if isCard("Slash",card,player) then return end
	end
	local has_friend = false
	for _,p in sgs.list(q(self.room,"getLieges","shu",player))do
		source_flag(self,self.player,"stack_overflow_jijiang")
		has_friend = q(self,"isFriend",p,player)
		source_flag(self,self.player,"-stack_overflow_jijiang")
		if has_friend then break end
	end
	if has_friend then return "@OLJijiangCard=." end
end

sgs.ai_skill_playerchosen.oljijiang = function(self,targets)
	targets = AIList.new(targets)
	q(self,"sort",targets)
	for _,p in ipairs(targets)do
		if q(self,"isFriend",p) and q(self,"canDraw",p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.oltishen = function(self,data)
	return q(self,"isWeak")
end

sgs.ai_fill_skill.ollongdan = function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	q(self,"sortByUseValue",cards,true)
	for _,c in ipairs(cards)do
		if q(c,"isKindOf","Analeptic") then
			return turn(self,"ollongdan","peach",{},c,request)
		end
	end
	for _,c in ipairs(cards)do
		if q(c,"isKindOf","Peach") then
			return known(self.world.strategy_facts.ol_st_standard and self.world.strategy_facts.ol_st_standard.analeptic_available,"ollongdan.Analeptic_IsAvailable") and turn(self,"ollongdan","analeptic",{},c,request)
		end
	end
	for _,c in ipairs(cards)do
		if q(c,"isKindOf","Jink") then
			return turn(self,"ollongdan","slash",{},c,request)
		end
	end
end

sgs.ai_view_as.ollongdan = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand then
		if q(card,"isKindOf","Jink") then
			return spec(card,"slash","ollongdan")
		elseif q(card,"isKindOf","Slash") then
			return spec(card,"jink","ollongdan")
		elseif q(card,"isKindOf","Peach") then
			return spec(card,"analeptic","ollongdan")
		elseif q(card,"isKindOf","Analeptic") then
			return spec(card,"peach","ollongdan")
		end
	end
end

sgs.ollongdan_keep_value = sgs.longdan_keep_value

sgs.ai_skill_invoke.olyajiao = true

sgs.ai_skill_playerchosen.olyajiao = function(self,targets)
	local id = q(self.player,"getMark","olyajiao")
	local card = face(self,id)
	local cards = { card }
	local c,friend = q(self,"getCardNeedPlayer",cards,self.friends)
	if friend then return friend end

	q(self,"sort",self.friends)
	for _,friend in ipairs(self.friends)do
		if q(self,"isValuableCard",card,friend) and not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true) then return friend end
	end
	for _,friend in ipairs(self.friends)do
		if q(self,"isWeak",friend) and not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true) then return friend end
	end
	local trash = q(card,"isKindOf","Disaster") or q(card,"isKindOf","GodSalvation") or q(card,"isKindOf","AmazingGrace")
	if trash then
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"getPhase")>sgs.Player_Play and q(self,"needKongcheng",enemy,true) and not hasManjuanEffect(enemy) then return enemy end
		end
	end
	for _,friend in ipairs(self.friends)do
		if not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true) then return friend end
	end
end

sgs.ai_playerchosen_intention.olyajiao = function(self,from,to)
	if not q(self,"needKongcheng",to,true) and not hasManjuanEffect(to) then q(self,"updateIntention",from,to,-50) end
end

sgs.ai_skill_playerchosen.olyajiao_discard = function(self,targets)
	return q(self,"findPlayerToDiscard","hej",false,true,targets)[1]
end

sgs.ai_skill_playerchosen.oljiuyuan = function(self,targets)
	return callback(self,"ai_skill_playerchosen","tenyearjiuyuan",self,targets)
end

sgs.ai_skill_invoke.olbotu = true

sgs.ai_skill_invoke.olleiji = true

sgs.ai_skill_playerchosen.olleiji = function(self,targets)
	return callback(self,"ai_skill_playerchosen","leiji",self,targets)
end

sgs.ai_playerchosen_intention.olleiji = sgs.ai_playerchosen_intention.leiji

function sgs.ai_slash_prohibit.olleiji(self,from,to,card) -- @todo: Qianxi flag name
	if q(self,"isFriend",to) then return false end
	if q(to,"hasSkills","hongyan|olhongyan") then return false end
	if q(to,"hasFlag","QianxiTarget") and (not q(self,"hasEightDiagramEffect",to) or q(self.player,"hasWeapon","QinggangSword")) then return false end
	local hcard = q(to,"getHandcardNum")
	if q(self,"canLiegong",to,from) then return false end
	if q(from,"getRole")=="rebel" and q(to,"isLord")
	then
		local other_rebel
		for _,player in sgs.list(q(self.room,"getOtherPlayers",from))do
			if q(self,"getRoleEstimate",player)=="rebel"
			or q(self,"compareRoleEvaluation",player,"rebel","loyalist")=="rebel"
			then
				other_rebel = player
				break
			end
		end
		if not other_rebel and q(self.player,"getHp")>=4
		and (q(self,"getCardsNum","Peach")>0  or q(self.player,"hasSkills","ganglie|neoganglie"))
		then
			return false
		end
	end

	if getKnownCard(to,self.player,"Jink",true)>=1 or (q(self,"hasSuit","spade",true,to) and hcard>=2) or hcard>=4 then return true end
	if not from then
		from = q(self.room,"getCurrent")
	end
	if q(self,"hasEightDiagramEffect",to) and not IgnoreArmor(from,to) then return true end
end

sgs.ai_skill_cardask["@olguidao-card"]=function(self,data)
	local all_cards = callback(self,"ai_skill_cardask","@guidao-card",self,data)
	if all_cards~="." then return all_cards end
	all_cards = q(self,"addHandPile","he")
	if #all_cards<1 then return "." end
	local cards = {}
	for _,c in sgs.list(all_cards)do
		if q(c,"getSuit")==0 and q(c,"getNumber")>1 and q(c,"getNumber")<10
		then table.insert(cards,c) end
	end
	local judge = q(data,"toJudge")
	if #cards>0 then
		local id = q(self,"getRetrialCardId",cards,judge,nil,true)
		if id>-1 then
			if q(self,"needRetrial",judge)
			or q(judge.card,"isKindOf","Jink") and q(self,"getCardsNum","Jink")<1
			or q(judge.card,"getSuit")==0 and q(self,"getSuitNum","spade",true)<1
			or q(self,"getUseValue",judge.card)>q(self,"getUseValue",face(self,id))
			or #self.enemies>0 and judge.who==self.player and q(self.player,"hasSkill","olleiji")
			then return id end
		end
	end
	cards = {}
	for _,c in sgs.list(all_cards)do
		if q(c,"isBlack") then table.insert(cards,c) end
	end
	if #cards>0 then
		local id = q(self,"getRetrialCardId",cards,judge,nil,true)
		if id>-1 then
			if q(self,"needRetrial",judge)
			or q(judge.card,"isKindOf","Jink") and q(self,"getCardsNum","Jink")<1
			or q(judge.card,"getSuit")==0 and q(self,"getSuitNum","spade",true)<1
			or q(self,"getUseValue",judge.card)>q(self,"getUseValue",face(self,id))
			or #self.enemies>0 and judge.who==self.player and q(self.player,"hasSkill","olleiji")
			then return id end
		end
	end
	return "."
end

function sgs.ai_cardneed.olguidao(to,card,self)
	return callback(self,"ai_cardneed","guidao",to,card,self)
end

sgs.ai_suit_priority.olguidao = sgs.ai_suit_priority.guidao

sgs.ai_useto_revises.olguidao = function(self,card,use,p)
	if q(card,"isKindOf","Lightning")
	then
		if q(self,"isFriend",p) and q(p,"getCardCount")>2
		then use.card = card return end
		return false
	end
end

sgs.ai_fill_skill.olhuangtian_attach = function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	local card
	q(self,"sortByUseValue",cards,true)
	if q(self,"getCardsNum","Jink","h")>1 then
		for _,acard in ipairs(cards)  do
			if q(acard,"isKindOf","Jink") then
				card = acard
				break
			end
		end
	end
	if q(self,"getOverflow",self.player)>0 then
		for _,acard in ipairs(cards)  do
			if q(acard,"getSuit")==sgs.Card_Spade then
				card = acard
				break
			end
		end
	end
	if not card then return nil end
	return parse(self,"@OLHuangtianCard="..q(card,"getEffectiveId"))
end

sgs.ai_skill_use_func.OLHuangtianCard = function(card,use,self)
	if q(self,"needBear") then
		return "."
	end
	local targets = {}
	for _,friend in ipairs(self.friends_noself)do
		if q(friend,"hasLordSkill","olhuangtian") and q(friend,"getMark","olhuangtian-PlayClear")<=0 then
			if not hasManjuanEffect(friend) then
				table.insert(targets,friend)
			end
		end
	end
	if #targets>0 then --黄天己方
		use.card = card
		q(self,"sort",targets,"defense")
		use.to:append(targets[1])
	elseif q(self,"getCardsNum","Slash","he")>=2 then --黄天对方
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"hasLordSkill","olhuangtian") and q(enemy,"getMark","olhuangtian-PlayClear")<=0 then
				if not hasManjuanEffect(enemy,true) then
					if q(enemy,"isKongcheng") and not q(enemy,"hasSkill","kongcheng") and not q(self,"hasTuntianEffect",enemy,true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
						table.insert(targets,enemy)
					end
				end
			end
		end
		if #targets>0 then
			local flag = false
			if q(self.player,"hasSkill","tianyi") and not q(self.player,"hasUsed","TianyiCard") then
				flag = true
			elseif q(self.player,"hasSkill","xianzhen") and not q(self.player,"hasUsed","XianzhenCard") then
				flag = true
			elseif q(self.player,"hasSkill","tenyearxianzhen") and not q(self.player,"hasUsed","TenyearXianzhenCard") then
				flag = true
			elseif q(self.player,"hasSkill","mobilexianzhen") and not q(self.player,"hasUsed","MobileXianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = q(self,"getMaxCard",self.player) --最大点数的手牌
				if maxCard:getNumber()>q(card,"getNumber") then --可以保证拼点成功
					q(self,"sort",targets,"defense",true)
					for _,enemy in ipairs(targets)do
						if q(self.player,"canSlash",enemy,nil,false,0) then --可以发动天义或陷阵
							use.card = card
							source_flag(self,enemy,"AI_HuangtianPindian")
							use.to:append(enemy)
							break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.OLHuangtianCard = function(self,card,from,tos)
	return callback(self,"ai_card_intention","HuangtianCard",self,card,from,tos)
end

sgs.ai_use_priority.OLHuangtianCard = sgs.ai_use_priority.HuangtianCard
sgs.ai_use_value.OLHuangtianCard = sgs.ai_use_value.HuangtianCard

sgs.ai_skill_choice.olguhuo = function(self,choices,data)
	local yuji = q(data,"toPlayer")
	if not yuji or q(self,"isEnemy",yuji) then return "noquestion" end
	local guhuoname = known(facts(self).guhuo_type,"OLGuhuoType")
	if guhuoname=="peach+analeptic" then guhuoname = "peach" end
	if guhuoname=="normal_slash" then guhuoname = "slash" end
	local guhuocard = evaluation(self,guhuoname)
	local guhuotype = q(guhuocard,"getClassName")
	if guhuotype and q(self,"getRestCardsNum",guhuotype,yuji)==0 and q(self.player,"getHp")>0 then return "question" end
	if guhuotype and guhuotype=="AmazingGrace" then return "noquestion" end
	if q(self.player,"hasSkill","hunzi") and q(self.player,"getMark","hunzi")==0 and math.random(1,15)~=1 then return "noquestion" end
	if guhuotype:match("Slash") then
		if q(yuji,"getState")~="robot" and math.random(1,8)==1 then return "question" end
		if not q(self,"hasCrossbowEffect",yuji) then return "noquestion" end
	end
	local x = 5
	if guhuoname=="peach" or guhuoname=="ex_nihilo" then
		x = 2
		if getKnownCard(yuji,self.player,guhuotype,false)>0 then x = x*3 end
	end
	return math.random(1,x)==1 and "question" or "noquestion"
end

sgs.ai_fill_skill.olguhuo = function(self,inclusive,request)
	if q(self.player,"isKongcheng") then return end
    local cards = q(self.player,"getCards","h")
    cards = q(self,"sortByKeepValue",cards,nil,true) -- 按保留值排序
	local Guhuo_str = {}
	for _,card in ipairs(cards)do
		if q(card,"isNDTrick") or q(card,"isKindOf","BasicCard")
		then
			table.insert(Guhuo_str,"@OLGuhuoCard="..q(card,"getId")..":"..q(card,"objectName"))
		end
	end
	local peach = olguhuo_policy(self,"peach","Peach")
	if peach then table.insert(Guhuo_str,peach) end
	local question = #self.enemies
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"hasSkill","hunzi") and q(enemy,"getMark","hunzi")<1
		or q(enemy,"hasSkill","chanyuan")
		then question = question-1 end
	end
	local ratio = question<1 and 100 or (#self.enemies/question)
	if #Guhuo_str>0
	and ratio<100
	then
		for i=1,5 do
			local guhuo_str = Guhuo_str[math.random(1,#Guhuo_str)]
			local declaration=guhuo_str:split(":")[2]
            guhuo_str=parse(self,guhuo_str,request)
            local user=declared(self,"olguhuo",declaration,q(guhuo_str,"getSubcards"))
			if q(user,"isAvailable",self.player)
			then
				local dummy = q(self,"aiUseCard",user)
				if dummy.card and dummy.to
				then
					if q(user,"canRecast")
					and dummy.to:length()<1
					then continue end
					self.guhuo_to = dummy.to
					if q(user,"isKindOf","ExNihilo") and math.random(1,3)<=ratio then return guhuo_str
					elseif math.random(1,4)<=ratio then return guhuo_str end
				end
			end
		end
	end
	if math.random(1,5)<=3*ratio
	then
		for c,pn in ipairs(known(self.world.strategy_facts.pattern_names,"patterns"))do
			c = evaluation(self,pn)
			if c and (q(c,"getTypeId")==1 or q(c,"isNDTrick"))
			and q(self,"getRestCardsNum",q(c,"getClassName"))>0
			and q(c,"isDamageCard") then
				c=declared(self,"olguhuo",q(c,"objectName"),{cards[1]:getEffectiveId()})
				if q(c,"isAvailable",self.player)
				then
					local dummy = q(self,"aiUseCard",c)
					if dummy.card and dummy.to
					then
						if q(c,"canRecast")
						and dummy.to:length()<1
						then continue end
						self.guhuo_to = dummy.to
						return parse(self,"@OLGuhuoCard="..cards[1]:getId()..":"..q(c,"objectName"))
					end
				end
			end
		end
		for c,pn in ipairs(known(self.world.strategy_facts.pattern_names,"patterns"))do
			c = evaluation(self,pn)
			if c and (q(c,"getTypeId")==1 or q(c,"isNDTrick"))
			and q(self,"getRestCardsNum",q(c,"getClassName"))>0
			then
				c=declared(self,"olguhuo",q(c,"objectName"),{cards[1]:getEffectiveId()})
				if q(c,"isAvailable",self.player)
				then
					local dummy = q(self,"aiUseCard",c)
					if dummy.card and dummy.to
					then
						if q(c,"canRecast")
						and dummy.to:length()<1
						then continue end
						self.guhuo_to = dummy.to
						return parse(self,"@OLGuhuoCard="..cards[1]:getId()..":"..q(c,"objectName"))
					end
				end
			end
		end
	end
	if q(self,"isWeak")
	then
		ratio = olguhuo_policy(self,"peach","Peach")
		if ratio
		then
			local dummy = evaluation(self,"peach")
			if q(dummy,"isAvailable",self.player)
			then
				dummy = q(self,"aiUseCard",dummy)
				if dummy.card and dummy.to
				then
					self.guhuo_to = dummy.to
					return parse(self,ratio)
				end
			end
		end
	end
	ratio = olguhuo_policy(self,"slash","Slash")
	if ratio and q(self,"slashIsAvailable")
	then
		local dummy = q(self,"aiUseCard",evaluation(self))
		if dummy.card and dummy.to
		then
			self.guhuo_to = dummy.to
		   	return parse(self,ratio)
		end
	end
end

sgs.ai_skill_use_func.OLGuhuoCard=function(card,use,self)
	use.card = card
   	use.to = self.guhuo_to
end

sgs.ai_use_priority.OLGuhuoCard = sgs.ai_use_priority.GuhuoCard

sgs.ai_guhuo_card.olguhuo = function(self,toname,class_name)
	if q(self.player,"isKongcheng")
	or q(self.player,"getMark","olguhuo-Clear")>0
	then return end
    local hcards = q(self.player,"getCards","h")
    hcards = q(self,"sortByKeepValue",hcards,nil,true) -- 按保留值排序
    local hc,fake = {},{}
    local all = q(self.room,"getMode")=="_mini_48"
    local question = #self.enemies
   	for _,enemy in sgs.list(self.enemies)do
    	if q(enemy,"hasSkill","chanyuan")
    	or q(enemy,"hasSkill","hunzi") and q(enemy,"getMark","hunzi")<1
    	then question = question-1 end
    end
    if question<1 then all = true end
	for _,c in sgs.list(hcards)do
    	if q(c,"isKindOf",class_name)
		then
			table.insert(hc,c)
    		if q(self,"getCardsNum",class_name)>0
			then table.insert(fake,c) end
		end
    end
    question = question<1 and 100 or (#self.enemies/question)
    if all then hc = hcards end
    if #hc>1 or #hc>0 and all
    then
    	local index = 1
    	if not all and (class_name=="Peach" or class_name=="Analeptic" or class_name=="Jink")
    	then index = #hc end
    	return "@OLGuhuoCard="..hc[index]:getEffectiveId()..":"..toname
    end
    if #fake>0 and math.random(1,5)<=question
    then return "@OLGuhuoCard="..fake[1]:getEffectiveId()..":"..toname end
    if #hc>0 then return "@OLGuhuoCard="..hc[1]:getEffectiveId()..":"..toname end
	if q(self,"isWeak")
	then
		if (class_name=="Peach" or class_name=="Analeptic")
		and q(self,"getCardsNum",{"Analeptic","Peach"})<1
		then return "@OLGuhuoCard="..hcards[1]:getEffectiveId()..":"..toname
		elseif class_name=="Jink"
		then return "@OLGuhuoCard="..hcards[1]:getEffectiveId()..":"..toname end
	end
	if class_name=="Jink" and math.random(1,#hcards+1)<(#hcards+1)/2
	then return "@OLGuhuoCard="..hcards[1]:getEffectiveId()..":"..toname
	elseif class_name=="Slash" and math.random(1,#hcards+2)>(#hcards+1)/2
	then return "@OLGuhuoCard="..hcards[1]:getEffectiveId()..":"..toname
	elseif class_name=="Peach" or class_name=="Analeptic"
	then
		question = q(self.room,"getCurrentDyingPlayer")
		if question and q(self,"isFriend",question) and math.random(1,#hcards+1)>(#hcards+1)/2
		then return "@OLGuhuoCard="..hcards[1]:getEffectiveId()..":"..toname end
    end
end

sgs.ai_skill_choice.olguhuo_saveself = function(self,choices)
	return callback(self,"ai_skill_choice","guhuo_saveself",self,choices)
end

sgs.ai_skill_choice.olguhuo_slash = function(self,choices)
	return callback(self,"ai_skill_choice","guhuo_slash",self,choices)
end

sgs.ai_skill_discard.olguhuo = function(self,discard_num,min_num,optional,include_equip)
	if q(self,"hasZhaxiangEffect",self.player) and q(self,"canDraw") and not q(self,"willSkipPlayPhase") and (q(self.player,"getHp")>0 or hasBuquEffect(self.player) or q(self,"getSaveNum",true)>0) then
		return {}
	end
	return q(self,"askForDiscard","dummy",1,1,false,include_equip)
end

local function shebian_slot(self,op,key,value)
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('Shebian global continuation host missing',key)end
 local row=op=='record'and{known=true,present=true,value=value}or nil
 local result=ai_response_choice_continuity({op=op,key=key,row=row})
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.known~=true then ai_unsupported('Shebian source registry continuation unknown',key)end
 if op=='record'then if result.recorded~=true then ai_unsupported('Shebian source write unconfirmed',key)end;return end
 if type(result.present)~='boolean'then ai_unsupported('Shebian source registry presence unknown',key)end
 if not result.present then return nil end
 if key=='olshebian'then
  if type(result.value)~='number'then ai_unsupported('Shebian numeric slot changed type',key)end
  return result.value
 end
 if type(result.value)~='string'then ai_unsupported('Shebian player slot changed type',key)end
 return known(q(self.room,'findPlayerByObjectName',result.value,true),key)
end
sgs.ai_skill_invoke.olshebian = function(self,data)
	local from,card,to = q(self,"moveField",nil,"e")
	if from and card and to then
		shebian_slot(self,'record','olshebian_from',q(from,'objectName'))
		shebian_slot(self,'record','olshebian',q(card,'getId'))
		shebian_slot(self,'record','olshebian_to',q(to,'objectName'))
		return true
	end
	return false
end

sgs.ai_fill_skill.olqimou = function(self,inclusive,request)
	if #self.enemies<=0 then return end
	if q(self.player,"getHp")+q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")<2 then return end
	return parse(self,"@OLQimouCard=.")
end

sgs.ai_skill_use_func.OLQimouCard = function(card,use,self)
	self.olqimou_lose = 0
	local slashcount = q(self,"getCardsNum","Slash")-1
	self.olqimou_lose = math.min(slashcount,q(self.player,"getHp"))
	if self.olqimou_lose<=0 then return end
	
	return q(self,"withOwnerDistanceAdjustment","olqimou",-self.olqimou_lose,function()
	local slash = q(self,"getCard","Slash")
	if not slash then  return end
	
	local dummy_use = AIUsePlan.new()
	if slash then q(self,"useBasicCard",slash,dummy_use) end
	
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
 end)
end

sgs.ai_skill_choice.olqimou = function(self,choices)
	choices = choices:split("+")
	local num = self.olqimou_lose
	for _,choice in ipairs(choices)do
		if tonumber(choice)==num then return choice end
	end
	return choices[1]
end

sgs.ai_use_priority.OLQimouCard = sgs.ai_use_priority.TenyearQimouCard

sgs.ai_skill_use["@@oltianxiang"] = function(self,prompt)
	return callback(self,"ai_skill_use","@@tenyeartianxiang",self,prompt)
end

sgs.ai_suit_priority.olhongyan = sgs.ai_suit_priority.hongyan

sgs.ai_skill_invoke.olpiaoling = true

sgs.ai_skill_playerchosen.olpiaoling = function(self,targets)
	local card = tag(self,"olpiaoling","card")
	local cards = { card }
	local c,friend = q(self,"getCardNeedPlayer",cards,self.friends)
	if friend then return friend end

	q(self,"sort",self.friends)
	for _,friend in ipairs(self.friends)do
		if q(self,"isValuableCard",card,friend) and not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true)
		then return friend end
	end
	for _,friend in ipairs(self.friends)do
		if q(self,"isWeak",friend) and not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true)
		then return friend end
	end
	if q(card,"isKindOf","Disaster") or q(card,"isKindOf","GodSalvation") or q(card,"isKindOf","AmazingGrace") then
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"getPhase")>sgs.Player_Play and q(self,"needKongcheng",enemy,true) and not hasManjuanEffect(enemy)
			then return enemy end
		end
	end
	for _,friend in ipairs(self.friends)do
		if not hasManjuanEffect(friend) and not q(self,"needKongcheng",friend,true)
		then return friend end
	end
end

sgs.ai_playerchosen_intention.olpiaoling = function(self,from,to)
	if not q(self,"needKongcheng",to,true) and not hasManjuanEffect(to) then q(self,"updateIntention",from,to,-50) end
end

sgs.ai_skill_discard.olpiaoling = function(self,discard_num,min_num,optional,include_equip)
	return q(self,"askForDiscard","dummyreason",1,1,false,include_equip)
end

sgs.ai_fill_skill.olluanji = function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	if #cards>=2
	then
		q(self,"sortByKeepValue",cards)
		local useAll = false
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"getHp")==1 and not q(enemy,"hasArmorEffect","Vine")
			and not q(self,"hasEightDiagramEffect",enemy) and q(self,"damageIsEffective",enemy,nil,self.player)
			and q(self,"isWeak",enemy) and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)==0
			then useAll = true end
		end
		for _,fcard in ipairs(cards)do
			if isCard("Peach",fcard,self.player)
			or isCard("ExNihilo",fcard,self.player)
			or isCard("ArcheryAttack",fcard,self.player)
			or useAll and isCard("ArcheryAttack",fcard,self.player)
			then continue end
			for _,scard in ipairs(cards)do
				if q(scard,"getSuit")~=q(fcard,"getSuit")
				or fcard==scard
				or isCard("Peach",scard,self.player)
				or isCard("ExNihilo",scard,self.player)
				or isCard("ArcheryAttack",scard,self.player)
				or useAll and isCard("ArcheryAttack",scard,self.player)
				then continue end
				local archery = turn(self,"olluanji","archery_attack",{q(fcard,"getEffectiveId"),q(scard,"getEffectiveId")},nil,request)
				local dummy_use = q(self,"aiUseCard",archery)
				if dummy_use.card then return archery end
			end
		end
	end
end

sgs.ai_skill_playerchosen.olluanji = function(self,targets)
	local use = tag(self,"olluanji_data","use")
	if not use then return nil end
	q(self,"sort",self.friends_noself)
	local lord = q(self.room,"getLord")
	if lord and q(lord,"objectName")~=q(self.player,"objectName") and q(self,"isFriend",lord) and q(self,"isWeak",lord) and q(self,"hasTrickEffective",use.card,lord,self.player) then
		return lord
	end
	for _,friend in ipairs(self.friends_noself)do
		if q(self,"hasTrickEffective",use.card,friend,self.player) then
			return friend
		end
	end
	return nil
end

sgs.ai_skill_invoke.olxueyi = function(self,data)
	if not q(self,"canDraw") then return false end
	if q(self,"willSkipPlayPhase") then return false end
	local num = 2  --偷懒不管别的摸牌数了，也不管手里的【无中生有】了
	if q(self,"willSkipDrawPhase") then
		num = 0
	end
	if q(self.player,"getHandcardNum")>=4 then return false end
	if q(self.player,"getHandcardNum")+1+num<q(self.player,"getMaxCards")-2 then return true end
	return false
end

sgs.ai_skill_invoke.secondolxueyi = function(self,data)
	if not q(self,"canDraw") then return false end
	if q(self.player,"getHandcardNum")>=4 then return false end
	if q(self.player,"getHandcardNum")+1<q(self.player,"getMaxCards")-1 then return true end
	return false
end

sgs.ai_fill_skill.olhuoji = function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	local card
	q(self,"sortByUseValue",cards,true)
	for _,acard in ipairs(cards)do
		if q(acard,"isRed") and not q(acard,"isKindOf","Peach") and (q(self,"getDynamicUsePriority",acard)<sgs.ai_use_value.FireAttack or q(self,"getOverflow")>0) then
			if q(acard,"isKindOf","Slash") and q(self,"getCardsNum","Slash")==1 then
				local keep
				local dummy_use = AIUsePlan.new()
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
	return turn(self,"olhuoji","fire_attack",{},card,request)
end

sgs.ai_cardneed.olhuoji = function(to,card,self)
	return callback(self,"ai_cardneed","huoji",to,card,self)
end

sgs.ai_skill_cardask["olhuoji0"] = function(self,data,pattern)
	local effect = q(data,"toCardEffect")
	if (not q(self,"isFriend",effect.to) or q(effect.to,"isChained"))
		and q(self,"damageIsEffective",effect.to,effect.card)
    	then return true 
	end
    return "."
end

sgs.ai_view_as.olkanpo = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand or card_place==sgs.Player_PlaceEquip then
		if q(card,"isBlack") then
			return spec(card,"nullification","olkanpo")
		end
	end
end

sgs.ai_cardneed.olkanpo = function(to,card,self)
	return callback(self,"ai_cardneed","kanpo",to,card,self)
end

sgs.olkanpo_suit_value = sgs.kanpo_suit_value

sgs.ai_fill_skill.ollianhuan = function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	local card
	q(self,"sortByUseValue",cards,true)
	local slash = q(self,"getCard","FireSlash") or q(self,"getCard","ThunderSlash") or q(self,"getCard","Slash")
	if slash then
		local dummy_use = AIUsePlan.new()
		q(self,"useBasicCard",slash,dummy_use)
		if not dummy_use.card then slash = nil end
	end
	for _,acard in ipairs(cards)do
		if q(acard,"getSuit")==sgs.Card_Club then
			local shouldUse = true
			if q(self,"getUseValue",acard)>sgs.ai_use_value.IronChain and q(acard,"getTypeId")==sgs.Card_TypeTrick then
				local dummy_use = AIUsePlan.new()
				q(self,"useTrickCard",acard,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if q(acard,"getTypeId")==sgs.Card_TypeEquip then
				local dummy_use = AIUsePlan.new()
				q(self,"useEquipCard",acard,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse and (not slash or q(slash,"getEffectiveId")~=q(acard,"getEffectiveId")) then
				card = acard
				break
			end
		end
	end
	if not card then return nil end
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	return turn(self,"ollianhuan","iron_chain",{},card,request)
end

sgs.ai_cardneed.ollianhuan = function(to,card,self)
 self=self or (to._room and to._room._ai)
	return callback(self,"ai_cardneed","lianhuan",to,card)
end

sgs.ai_skill_invoke.olniepan = function(self,data)
	return callback(self,"ai_skill_invoke","niepan",self,data)
end

sgs.ai_skill_choice.olniepan = function(self,choices)
	choices = choices:split("+")
	if q(self.player,"hasArmorEffect","EightDiagram") or q(self.player,"getArmor") then
		if table.contains(choices,"bazhen") then table.removeOne(choices,"bazhen") end
	end
	if table.contains(choices,"bazhen") then return "bazhen" end
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_invoke.oljianchu = function(self,data)
	return callback(self,"ai_skill_invoke","tenyearjianchu",self,data)
end

sgs.ai_skill_invoke.olhanzhan = function(self,data)
	local to = q(data,"toPlayer")
	if to and not q(self,"isFriend",to) then return true end
	return false
end

sgs.ai_skill_invoke.secondolhanzhan = function(self,data)
	return callback(self,"ai_skill_invoke","olhanzhan",self,data)
end

sgs.ai_skill_use["@@secondolhanzhan"] = function(self,prompt,method)
	local ids = tag(self,"secondolhanzhanForAI","list")
	for _,id in sgs.qlist(ids)do
		local card = face(self,id)
		if not q(self.player,"canUse",card) then continue end
		local dummyuse = AIUsePlan.new()
		q(self,"useCardByClassName",card,dummyuse)
		if not dummyuse.to:isEmpty() then
			return "@SecondOLHanzhanCard="..id
		end
	end
	if not q(self,"canDraw") then return "." end
	return "@SecondOLHanzhanCard="..ids:at(0)
end

sgs.ai_skill_use["@@olwulie"] = function(self,prompt,method)
	local num = q(self.player,"getHp")-1+q(self,"getSaveNum",true)
	if num<=0 and hasBuquEffect(self.player) then
		local buqu,nosbuqu
		if q(self.player,"hasSkill","buqu") then buqu = 4-q(self.player,"getPile","buqu") end
		if q(self.player,"hasSkill","nosbuqu") then nosbuqu = 4-q(self.player,"getPile","nosbuqu") end
		num = math.max(nosbuqu,buqu)
	end
	num = math.min(num,#self.friends_noself)
	if num<=0 then return "." end
	
	q(self,"sort",self.friends_noself)
	local friends = {}
	for i = 1,num do
		table.insert(friends,self.friends_noself[i]:objectName())
	end
	if #friends>0 then return "@OLWulieCard=.->"..table.concat(friends,"+") end
	return "."
end

sgs.ai_fill_skill.oljiuchi = function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	local card
	q(self,"sortByUseValue",cards,true)
	for _,acard in ipairs(cards)  do
		if q(acard,"getSuit")==sgs.Card_Spade then
			card = acard
			break
		end
	end
	if not card then return nil end
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	local analeptic = turn(self,"oljiuchi","analeptic",{},card,request)
	assert(analeptic)
	if q(self,"readonlyTurnAvailability",analeptic) then
		return analeptic
	end
end

sgs.ai_view_as.oljiuchi = function(card,player,card_place)
 local self=known(player._room and player._room._ai,"oljiuchi.viewer")
	local str = callback(self,"ai_view_as","jiuchi",card,player,card_place)
	if not str or str=="" or str==nil then return end
	if type(str)~="table"then ai_unsupported("Jiuchi shared proposal ABI unknown","oljiuchi")end
 local r={}for k,v in pairs(str)do r[k]=v end;r.skill="oljiuchi";return r
end

function sgs.ai_cardneed.oljiuchi(to,card,self)
	return callback(self,"ai_cardneed","jiuchi",to,card,self)
end

sgs.ai_skill_invoke.olbaonue = function(self,data)

	return q(self.player,"isWounded")--to and q(self,"isFriend",to)
end

sgs.ai_skill_invoke.olhuashen = function(self,data)
	return callback(self,"ai_skill_invoke","huashen",self,data)
end

function sgs.ai_skill_choice.olhuashen(self,choices,data,xiaode_choice)
	local items = choices:split("+")
	if table.contains(items,"exchangetwo")
	then
		local sk = {}
		local huashens = tag(self,"Huashens","list")
		for _,hs in sgs.list(huashens)do
			local general = general(self,hs)
			for _,s in sgs.list(q(general,"getVisibleSkillList"))do
				table.insert(sk,q(s,"objectName"))
			end
		end
		sk = table.concat(sk,"+")
		sk = callback(self,"ai_skill_choice","huashen",self,sk,data,xiaode_choice)
		if sk and q(self.player,"hasSkill",sk)
		then return "exchangetwo" end
	end
	if table.contains(items,"change") then return "change" end
	return callback(self,"ai_skill_choice","huashen",self,choices,data,xiaode_choice)
end

sgs.ai_skill_invoke.olfangquan = function(self,data)
	return callback(self,"ai_skill_invoke","fangquan",self,data)
end

sgs.ai_skill_use["@@olfangquan"] = function(self,prompt)
	local str = fangquan_proposal(self)
	if not str or str=="" or str==nil then return "." end
	return string.gsub(str,"FangquanCard","OLFangquanCard")
end

sgs.ai_skill_playerchosen.olsishu = function(self,targets)
	targets = AIList.new(targets)
	q(self,"sort",targets,"handcard")
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets)do
		if not q(self,"isFriend",p) or q(p,"getMark","&olsishu")>0 then continue end
		if q(p,"containsTrick","indulgence") then
			if q(p,"containsTrick","YanxiaoCard") or (q(p,"hasSkill","qiaobian") and q(p,"canDiscard",p,"h")) then continue end
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not q(self,"isFriend",p) or q(p,"getMark","&olsishu")>0 then continue end
		if q(p,"containsTrick","indulgence") then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not q(self,"isFriend",p) or q(p,"getMark","&olsishu")>0 then continue end
		return p
	end
	return nil
end

sgs.ai_fill_skill.olzhiba = function(self,inclusive,request)
	if q(self,"needBear") then return end
	return parse(self,"@OLZhibaCard=.")
end

sgs.ai_use_priority.OLZhibaCard = 7

sgs.ai_skill_use_func.OLZhibaCard = function(card,use,self)
	local enemies = {}
	for _,p in ipairs(self.enemies)do
		if q(p,"getKingdom")=="wu" and q(self.player,"canPindian",p) then
			table.insert(enemies,p)
		end
	end
	if #enemies<=0 then return end
	q(self,"sort",enemies,"defense")
	
	local max_card = q(self,"getMaxCard")
	if not max_card then return end
	local point = q(max_card,"getNumber")
	if q(self.player,"hasSkill","tianbian") and q(max_card,"getSuit")==sgs.Card_Heart then point = 13 end
	
	for _,p in ipairs(enemies)do
		local zhiba_str
		
		local enemy_max_card = q(self,"getMaxCard",p)
		if not enemy_max_card then continue end
		local enemy_point = q(enemy_max_card,"getNumber")
		if q(p,"hasSkill","tianbian") and q(enemy_max_card,"getSuit")==sgs.Card_Heart then enemy_point = 13 end

		if point>10 and point>enemy_point then
			if isCard("Jink",max_card,self.player) and q(self,"getCardsNum","Jink")==1 then return end
			if isCard("Peach",max_card,self.player) or isCard("Analeptic",max_card,self.player) then return end
			self.olzhiba_card = max_card
			zhiba_str = "@OLZhibaCard=."
		end

		if zhiba_str then
			use.card = parse(self,zhiba_str,nil,true)
			use.to:append(p)
			return
		end
	end
end

sgs.ai_skill_choice.olzhiba_pindian_obtain = function(self,choices)
	if q(self.player,"isKongcheng") and q(self,"needKongcheng") then return "reject" end
	return "obtainPindianCards"
end

function sgs.ai_skill_pindian.olzhiba(minusecard,self,requestor,maxcard)
	local cards,maxcard = AIList.new(q(self.player,"getHandcards"))
	local function compare_func(a,b)
		return q(a,"getNumber")>q(b,"getNumber")
	end
	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if q(self,"getUseValue",card)<6 then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_card_intention.OLZhibaCard = 50
sgs.ai_choicemade_filter.pindian.olzhiba = 50

sgs.ai_fill_skill.olzhiba_pindian = function(self,inclusive,request)
	if q(self,"needBear") or q(self,"getOverflow")<=0 then return end
	return parse(self,"@OLZhibaPindianCard=.")
end

sgs.ai_use_priority.OLZhibaPindianCard = 0

sgs.ai_skill_use_func.OLZhibaPindianCard = function(card,use,self)
	local lords = {}
	for _,player in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		if q(player,"hasLordSkill","olzhiba") and q(self.player,"canPindian",player) and q(player,"getMark","olzhiba-PlayClear")<=0 and q(self,"isFriend",player) then
			table.insert(lords,player)
		end
	end
	if #lords==0 then return end
	q(self,"sort",lords,"defense")
	for _,lord in ipairs(lords)do
		local zhiba_str
		local cards = q(self.player,"getHandcards")

		local max_num,max_card= 0,nil
		local min_num,min_card = 14,nil
		for _,hcard in sgs.list(cards)do
			if q(hcard,"getNumber")>max_num then
				max_num = q(hcard,"getNumber")
				max_card = hcard
			end

			if q(hcard,"getNumber")<=min_num then
				if q(hcard,"getNumber")==min_num then
					if min_card and q(self,"getKeepValue",hcard)>q(self,"getKeepValue",min_card) then
						min_num = q(hcard,"getNumber")
						min_card = hcard
					end
				else
					min_num = q(hcard,"getNumber")
					min_card = hcard
				end
			end
		end

		local lord_max_num,lord_max_card = 0,nil
		local lord_min_num,lord_min_card = 14,nil
		local lord_cards = q(lord,"getHandcards")
		local flag = string.format("%s_%s_%s","visible",q(self.room,"getCurrent"):objectName(),q(lord,"objectName"))
		for _,lcard in sgs.list(lord_cards)do
			if (q(lcard,"hasFlag","visible") or q(lcard,"hasFlag",flag)) and q(lcard,"getNumber")>lord_max_num then
				lord_max_card = lcard
				lord_max_num = q(lcard,"getNumber")
			end
			if q(lcard,"getNumber")<lord_min_num then
				lord_min_num = q(lcard,"getNumber")
				lord_min_card = lcard
			end
		end

		if not q(lord,"hasSkill","manjuan") and ((lord_max_num>0 and min_num<=lord_max_num) or min_num<7) then
			if isCard("Jink",min_card,self.player) and q(self,"getCardsNum","Jink")==1 then return end
			self.olzhiba_pindian_card = min_card
			zhiba_str = "@OLZhibaPindianCard=."
		end

		if zhiba_str then
			use.card = parse(self,zhiba_str,nil,true)
			use.to:append(lord)
			return
		end
	end
end

sgs.ai_skill_choice.olzhiba_pindian = function(self,choices)
	local who = q(self.room,"getCurrent")
	local cards = q(self.player,"getHandcards")
	local has_large_number,all_small_number = false,true
	for _,c in sgs.list(cards)do
		if q(c,"getNumber")>11 then
			has_large_number = true
			break
		end
	end
	for _,c in sgs.list(cards)do
		if q(c,"getNumber")>4 then
			all_small_number = false
			break
		end
	end
	if all_small_number or (q(self,"isEnemy",who) and not has_large_number) then return "reject"
	else return "accept"
	end
end

sgs.ai_skill_choice.olzhiba_pindian_obtain = function(self,choices)
	if q(self.player,"isKongcheng") and q(self,"needKongcheng") then return "reject" end
	return "obtainPindianCards"
end

function sgs.ai_skill_pindian.olzhiba_pindian(minusecard,self,requestor,maxcard)
	local cards,maxcard = AIList.new(q(self.player,"getHandcards"))
	local function compare_func(a,b)
		return q(a,"getNumber")>q(b,"getNumber")
	end
	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if q(self,"getUseValue",card)<6 then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_card_intention.OLZhibaPindianCard = 0

sgs.ai_choicemade_filter.pindian.olzhiba_pindian = function(self,from,promptlist)
	local number = face(self,tonumber(promptlist[4])):getNumber()
	local lord = q(self.room,"findPlayerByObjectName",promptlist[5])
	if not lord then return end
	local lord_max_card = q(self,"getMaxCard",lord)
	if lord_max_card and q(lord_max_card,"getNumber")>=number then q(self,"updateIntention",from,lord,-60)
	elseif lord_max_card and q(lord_max_card,"getNumber")<number then q(self,"updateIntention",from,lord,60)
	elseif number<6 then q(self,"updateIntention",from,lord,-60)
	elseif number>8 then q(self,"updateIntention",from,lord,60)
	end
end

sgs.ai_skill_invoke.oltuntian = function(self,data)
	return callback(self,"ai_skill_invoke","tuntian",self,data)
end

sgs.ai_skill_invoke.olqiaomeng = function(self,data)
	local player = q(data,"toPlayer")
	if q(self,"isFriend",player) then
		if q(player,"getArmor") and q(self,"needToThrowArmor",player) and q(self.player,"canDiscard",player,q(player,"getArmor"):getEffectiveId()) then return true end
		if q(self.player,"canDiscard",player,"j") and not q(player,"containsTrick","YanxiaoCard") then
			if q(player,"containsTrick","indulgence") or q(player,"containsTrick","supply_shortage") then return true end
			if (q(player,"containsTrick","lightning") and q(self,"getFinalRetrial",player)==2) or #self.enemies==0 then return true end
		end
		return false
	end
	return q(self,"doDisCard",player,"e")
end

sgs.ai_fill_skill.olchangbiao = function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	cards = q(self,"sortByKeepValue",cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs
  	for _,c in sgs.list(cards)do
		if q(self,"getKeepValue",c)>3
		or #ids>=#cards/2 then continue end
		table.insert(ids,q(c,"getEffectiveId"))
	end
	if #ids<1 and #cards>1
	then
		table.insert(ids,cards[1]:getEffectiveId())
	end
	fs=declared(self,"olchangbiao","slash",ids)
 local dummy = q(self,"aiUseCard",fs)
	if q(fs,"isAvailable",self.player)
	and dummy.card
	and dummy.to
	and #ids>0
  	then
		self.olcb_to = dummy.to
		ids = #ids>0 and table.concat(ids,"+") or "."
		return parse(self,"@OLChangbiaoCard="..ids)
	end
end

sgs.ai_skill_use_func["OLChangbiaoCard"] = function(card,use,self)
	use.card = card
	use.to = self.olcb_to
end

sgs.ai_use_value.OLChangbiaoCard = 9.4
sgs.ai_use_priority.OLChangbiaoCard = 2.8

sgs.ai_fill_skill.oltiaoxin = function(self,inclusive,request)
	return parse(self,"@OLTiaoxinCard=.")
end

sgs.ai_skill_use_func["OLTiaoxinCard"] = function(card,use,self)
	q(self,"sort",self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"inMyAttackRange",self.player)
		and q(ep,"getCardCount")>0
		then
			if q(self,"getCardsNum","Jink","h")>0
			or q(self.player,"getHandcardNum")>q(ep,"getHandcardNum")
			then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	end
end

sgs.ai_use_value.OLTiaoxinCard = 9.4
sgs.ai_use_priority.OLTiaoxinCard = 4.8

sgs.ai_skill_use["@@olzaiqi"] = function(self,prompt)
	local valid = {}
	local destlist = q(self.room,"getAllPlayers")
    destlist = AIList.new(destlist) -- 将列表转换为表
    q(self,"sort",destlist,"hp")
	local n = q(self.player,"getMark","olzaiqi-Clear")
	for _,friend in sgs.list(destlist)do
		if #valid>=n then break end
		if q(self,"isFriend",friend) then table.insert(valid,q(friend,"objectName")) end
	end
	for _,friend in sgs.list(destlist)do
		if #valid>=n then break end
		if table.contains(valid,q(friend,"objectName")) then continue end
		if not q(self,"isEnemy",friend) then table.insert(valid,q(friend,"objectName")) end
	end
	if #valid>0
	then
    	return string.format("@OLZaiqiCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_choice.olzaiqi = function(self,choices,data)
	local items = choices:split("+")
	local target = q(data,"toPlayer")
	if q(self,"isFriend",target)
	and q(self,"isWeak",target)
	then return items[2] end
	return items[1]
end

sgs.ai_fill_skill.olduanliang = function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	cards = q(self,"sortByKeepValue",cards,nil,true)
  	for _,c in sgs.list(cards)do
	   	if q(c,"getTypeId")~=1 and q(c,"getTypeId")~=3 then continue end
		local fs = turn(self,"olduanliang","supply_shortage",{},c,request)
		if q(fs,"isAvailable",self.player)
		and q(c,"isBlack") then return fs end
	end
end

sgs.ai_skill_playerchosen.oljiezi = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	q(self,"sort",destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_choice.olqiaobian = function(self,choices)
	local items = choices:split("+")
	self.olqiaobian_phase = items[1]:split("=")[2]
	local can = false
	if #items>2
	then
		if self.olqiaobian_phase=="judge"
		and q(self,"doDisCard",self.player,"j")
		and q(self,"getCardsNum","Nullification")<1
		then can = true end
		if self.olqiaobian_phase=="draw"
		then
			local n = 0
			for _,ep in sgs.list(self.enemies)do
				if q(self,"doDisCard",ep,"h")
				then n = n+1 end
			end
			can = n>1
		end
		if self.olqiaobian_phase=="play"
		then
			for _,fp in sgs.list(self.friends)do
				if can then break end
				self.olqiaobian_to = fp
				for _,j in sgs.list(q(fp,"getJudgingArea"))do
					if can then break end
					if q(self,"doDisCard",fp,j:getEffectiveId())
					then
						self.olqiaobian_ej = j
						for _,ep in sgs.list(self.enemies)do
							if q(ep,"containsTrick",j:objectName())
							then continue end
							can = true
						end
						for _,ep in sgs.list(q(self.room,"getAllPlayers"))do
							if q(ep,"containsTrick",j:objectName())
							or q(self,"isFriend",ep)
							then continue end
							can = true
						end
					end
				end
			end
			for _,ep in sgs.list(self.enemies)do
				if can then break end
				self.olqiaobian_to = ep
				for _,e in sgs.list(q(ep,"getEquips"))do
					if can then break end
					self.olqiaobian_ej = e
					local n = q(e,"getEquipSlot")
					for _,fp in sgs.list(self.friends)do
						if q(self,"doDisCard",ep,q(e,"getEffectiveId"))
						and not q(fp,"getEquip",n)
						then can = true end
					end
				end
			end
			can = can and #q(self,"getTurnUse")<3
		end
		if self.olqiaobian_phase=="discard"
		and q(self.player,"getHandcardNum")>q(self.player,"getMaxCards")
		then can = true end
		if can
		then
			if q(self.player,"getCardCount")>3
			and q(self.player,"getMark","&olzhbian")<3
			then return items[1] end
			return items[2]
		end
	else
		if self.olqiaobian_phase=="judge"
		and q(self,"doDisCard",self.player,"j")
		then can = true end
		if self.olqiaobian_phase=="draw"
		then
			local n = 0
			for _,ep in sgs.list(self.enemies)do
				if q(self,"doDisCard",ep,"h")
				then n = n+1 end
			end
			can = n>1
		end
		if self.olqiaobian_phase=="play"
		then
			for _,fp in sgs.list(self.friends)do
				if can then break end
				self.olqiaobian_to = fp
				for _,j in sgs.list(q(fp,"getJudgingArea"))do
					if can then break end
					if q(self,"doDisCard",fp,j:getEffectiveId())
					then
						self.olqiaobian_ej = j
						for _,ep in sgs.list(self.enemies)do
							if q(ep,"containsTrick",j:objectName())
							then continue end
							can = true
						end
						for _,ep in sgs.list(q(self.room,"getAllPlayers"))do
							if q(ep,"containsTrick",j:objectName())
							or q(self,"isFriend",ep)
							then continue end
							can = true
						end
					end
				end
			end
			for _,ep in sgs.list(self.enemies)do
				if can then break end
				self.olqiaobian_to = ep
				for _,e in sgs.list(q(ep,"getEquips"))do
					if can then break end
					self.olqiaobian_ej = e
					local n = q(e,"getEquipSlot")
					for _,fp in sgs.list(self.friends)do
						if q(self,"doDisCard",ep,q(e,"getEffectiveId"))
						and not q(fp,"getEquip",n)
						then can = true end
					end
				end
			end
			can = can and #q(self,"getTurnUse")<3
		end
		if self.olqiaobian_phase=="discard"
		and q(self.player,"getHandcardNum")>q(self.player,"getMaxCards")
		then can = true end
		if can
		then
			return items[1]
		end
	end
	return items[#items]
end

sgs.ai_skill_use["@@olqiaobian"] = function(self,prompt)
	local valid = {}
	local destlist = q(self.room,"getAllPlayers")
    destlist = AIList.new(destlist) -- 将列表转换为表
    q(self,"sort",destlist,"hp")
	local n = self.olqiaobian_phase=="draw" and 2 or 1
	for _,p in sgs.list(destlist)do
		if #valid>=n then break end
		self.olqiaobian_phase = p
		if q(self,"isEnemy",p) and n>1 and q(self,"doDisCard",p,"h")
		then table.insert(valid,q(p,"objectName")) continue end
		if n<2 and self.olqiaobian_to:objectName()==q(p,"objectName")
		then table.insert(valid,q(p,"objectName")) continue end
	end
	for _,p in sgs.list(destlist)do
		if #valid>=n then break end
		if table.contains(valid,q(p,"objectName")) then continue end
		self.olqiaobian_phase = p
		if not q(self,"isFriend",p) and n>1 and q(self,"doDisCard",p,"h")
		then table.insert(valid,q(p,"objectName")) continue end
		if n<2 and self.olqiaobian_to:objectName()==q(p,"objectName")
		then table.insert(valid,q(p,"objectName")) continue end
		if q(self,"isFriend",p) and n<2 and q(self,"doDisCard",p,"ej")
		then table.insert(valid,q(p,"objectName")) continue end
		if not q(self,"isFriend",p) and n<2 and q(self,"doDisCard",p,"e")
		then table.insert(valid,q(p,"objectName")) continue end
	end
	if #valid>0
	then
    	return string.format("@OLQiaobianCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_playerchosen.olqiaobian = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	q(self,"sort",destlist,"handcard")
	if self.olqiaobian_ej and q(self.olqiaobian_ej,"isKindOf","TrickCard")
	or q(self,"isFriend",self.olqiaobian_phase)
	then
		for _,target in sgs.list(destlist)do
			if q(self,"isEnemy",target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not q(self,"isFriend",target)
			then return target end
		end
	else
		for _,target in sgs.list(destlist)do
			if q(self,"isFriend",target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not q(self,"isEnemy",target)
			then return target end
		end
	end
end

sgs.ai_skill_cardchosen.olqiaobian = function(self,who,flags,method)
	for _,c in sgs.list(q(who,"getCards",flags))do
		if self.olqiaobian_ej and q(c,"getEffectiveId")==q(self.olqiaobian_ej,"getEffectiveId")
		then return q(c,"getId") end
	end
end

sgs.ai_skill_invoke.olbeige = function(self,data)
	local target = q(data,"toPlayer")
	if target
	then
		return not q(self,"isEnemy",target)
	end
end

sgs.ai_skill_discard.olbeige = function(self,max,min)
	local to_cards = {}
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards,nil,true)
	local pattern = tag(self,"OLbeigeTag","string"):split("+")
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		if q(c,"getSuitString")==pattern[1]
		then
         	table.insert(to_cards,q(c,"getEffectiveId"))
		end
	end
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		if q(c,"getNumberString")==pattern[2]
		then
         	table.insert(to_cards,q(c,"getEffectiveId"))
		end
	end
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		local target = q(self.room,"getCurrent")
		if q(self,"isEnemy",target)
		then
         	table.insert(to_cards,q(c,"getEffectiveId"))
		end
	end
	return to_cards
end

sgs.ai_skill_playerchosen.oljieming = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	local function func(a,b)
		return q(a,"getMaxHp")-q(a,"getHandcardNum")>q(b,"getMaxHp")-q(b,"getHandcardNum")
	end
	table.sort(destlist,func)
    for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target)
		and q(target,"getHandcardNum")<5
		and q(target,"getHandcardNum")<q(target,"getMaxHp")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target)
		and q(target,"getHandcardNum")<6
		and q(target,"getHandcardNum")<=q(target,"getMaxHp")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target)
		and q(target,"getHandcardNum")>q(target,"getMaxHp")*(math.random()+1)
		then return target end
	end
end

sgs.ai_can_damagehp.oljieming = function(self,from,card,to)
	if q(self,"isFriend",to)
	and q(self,"canLoseHp",from,card,to)
	and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	then
		for _,fp in sgs.list(self.friends)do
			if q(fp,"getHandcardNum")<5
			and q(fp,"getHandcardNum")<q(fp,"getMaxHp")
			then return true end
		end
	end
end

sgs.ai_fill_skill.olqiangxi = function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","Weapon")
		then
			return parse(self,"@OLQiangxiCard="..q(c,"getEffectiveId"))
		end
	end
	return parse(self,"@OLQiangxiCard=.")
end

sgs.ai_skill_use_func["OLQiangxiCard"] = function(card,use,self)
	q(self,"sort",self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if q(self,"isWeak",ep)
		and q(ep,"getMark","olqiangxiTarget-Clear")<1
		and (q(self.player,"getHp")>1 or q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")>0 or q(card,"subcardsLength")>0)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if (not q(self,"isWeak") or q(card,"subcardsLength")>0)
		and q(ep,"getMark","olqiangxiTarget-Clear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		if q(self,"isWeak",ep) and not q(self,"isWeak")
		and q(ep,"getMark","olqiangxiTarget-Clear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.OLQiangxiCard = 5.4
sgs.ai_use_priority.OLQiangxiCard = 4.8

sgs.ai_skill_playerchosen["#olhujia"] = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	q(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isEnemy",target)
		and q(self,"isWeak",target)
		then return target end
	end
end

sgs.ai_skill_invoke.olqieting = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_choice.olzaiqi = function(self,choices,data)
	local items = choices:split("+")
	local target = q(data,"toPlayer")
	if q(self,"isFriend",target)
	and table.contains(items,"draw")
	then return "draw" end
	return items[1]
end

sgs.ai_fill_skill.oljianmie = function(self,inclusive,request)
	return parse(self,"@OLJianmieCard=.")
end

sgs.ai_skill_use_func["OLJianmieCard"] = function(card,use,self)
	q(self,"sort",self.enemies,nil,true)
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getCardCount")>=q(self.player,"getCardCount") then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.OLJianmieCard = 5.4
sgs.ai_use_priority.OLJianmieCard = -0.8

sgs.ai_fill_skill.olmieji = function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	cards = q(self,"sortByKeepValue",cards)
	if #cards<1 then return end
  	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) or q(c,"getTypeId")~=2 then continue end
		return parse(self,"@OLMiejiCard="..q(c,"getId"))
	end
end

sgs.ai_skill_use_func["OLMiejiCard"] = function(card,use,self)
	q(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getCardCount")>1 and q(self.player,"inMyAttackRange",ep) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getCardCount")>0 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.OLMiejiCard = 4.4
sgs.ai_use_priority.OLMiejiCard = 2.8

sgs.ai_skill_invoke.ollihuo = function(self,data)
	return callback(self,"ai_skill_invoke","fan",self,data)
end

sgs.ai_skill_discard.ollihuo = function(self,max,min)
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
	if #cards>0 and (q(self,"isWeak") or #cards>3) then
       	return {cards[1]}
	end
	return {}
end

sgs.ai_skill_use["@@olchunlao"] = function(self,prompt)
	local valid = {}
	local ids = q(self.player,"getPile","wine")
	if ids:length()<2 then return end
	for _,id in sgs.list(ids)do
		if #valid>1 then break end
		table.insert(valid,id)
	end
	if #valid>0 then
    	return "@OLChunlaoCard="..table.concat(valid,"+")
	end
end

function sgs.ai_cardsview_valuable.olchunlao(self,class_name,player)
	local dy = q(self.room,"getCurrentDyingPlayer")
	if dy and q(self,"isFriend",dy) then
		local ids = q(player,"getPile","wine")
		return "@OLChunlaoCard="..(ids:at(0)or(#ids==0 and 0 or nil))
	end
end

sgs.ai_skill_cardask["olrenxin0"] = function(self,data,pattern,prompt)
    local dy = q(data,"toDying")
    if q(self,"isFriend",dy.who)
	then return true end
	return "."
end

sgs.ai_skill_invoke.olchengxiang = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_invoke.olbuyi = function(self,data)
	local target = q(data,"toPlayer")
	if target then
		return q(self,"isFriend",target)
	end
end

sgs.ai_skill_cardchosen.olbuyi = function(self,who,flags,method)
	if q(self,"isFriend",who) then
		for _,e in sgs.list(q(who,"getEquips"))do
			return q(e,"getId")
		end
	end
end

function sgs.ai_cardsview_valuable.oljiushi(self,class_name,player)
 return {name="analeptic",skill="oljiushi",suit=sgs.Card_NoSuit,number=0,subcards={}}
end

sgs.ai_fill_skill.oljiushi = function(self,inclusive,request)
	local dc = turn(self,"oljiushi","analeptic",{},nil,request)
	return dc
end

sgs.ai_skill_invoke.oljiushi = function(self,data)
	return true
end

sgs.ai_skill_invoke.olguzheng = function(self,data)
	if q(data,"toString")~="" then
		return q(self,"canDraw")
	end
	local target = q(data,"toPlayer")
	if target then
		return not q(self,"isEnemy",target)
		or q(self.player,"getMark","olguzhengNum")>2 and q(self,"canDraw")
	end
end

sgs.ai_fill_skill.olzhijian = function(self,inclusive,request)
	local equips = {}
	for _,card in sgs.qlist(q(self.player,"getHandcards"))do
		if q(card,"getTypeId")==sgs.Card_TypeEquip then
			table.insert(equips,card)
		end
	end
	if #equips==0 then return end

	return parse(self,"@OLZhijianCard=.")
end

sgs.ai_skill_use_func.OLZhijianCard = function(card,use,self)
	local equips = {}
	for _,card in sgs.qlist(q(self.player,"getHandcards"))do
		if q(card,"isKindOf","Armor") or q(card,"isKindOf","Weapon") then
			if not q(self,"getSameEquip",card) then
			elseif q(card,"isKindOf","GudingBlade") and q(self,"getCardsNum","Slash")>0 then
				local HeavyDamage
				local slash = q(self,"getCard","Slash")
				for _,enemy in ipairs(self.enemies)do
					if q(self.player,"canSlash",enemy,slash,true) and not q(self,"slashProhibit",slash,enemy) and
						q(self,"slashIsEffective",slash,enemy) and not q(self,"hasJueqingEffect",self.player,enemy) and q(enemy,"isKongcheng") then
							HeavyDamage = true
							break
					end
				end
				if not HeavyDamage then table.insert(equips,card) end
			else
				table.insert(equips,card)
			end
		elseif q(card,"getTypeId")==sgs.Card_TypeEquip then
			table.insert(equips,card)
		end
	end

	if #equips==0 then return end

	local select_equip,target
	for _,friend in ipairs(self.friends_noself)do
		for _,equip in ipairs(equips)do
			local index = q(equip,"getEquipSlot")
			if not q(friend,"hasEquipArea",index) then continue end
			if not q(self,"getSameEquip",equip,friend) and q(self,"hasSkills",sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _,equip in ipairs(equips)do
			local index = q(equip,"getEquipSlot")
			if not q(friend,"hasEquipArea",index) then continue end
			if not q(self,"getSameEquip",equip,friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end

	if not target then return end
	use.to:append(target)
	use.card = parse(self,"@OLZhijianCard="..q(select_equip,"getId"),nil,true)
end

sgs.ai_card_intention.OLZhijianCard = -80
sgs.ai_use_priority.OLZhijianCard = sgs.ai_use_priority.RendeCard+0.1  -- 刘备二张双将的话，优先直谏
ai_audited_aliases.register{id="ai_cardneed.olzhijian",registry="ai_cardneed",path={"olzhijian"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}

sgs.ai_skill_invoke.oljiang = function(self,data)
	local use = q(data,"toCardUse")
	if use.card then
		return q(self,"canDraw")
	end
	return not q(self,"isWeak")
end

sgs.ai_skill_invoke.olfuli = function(self,data)
	return q(self,"getAllPeachNum")+q(self.player,"getHp")<1
end

sgs.ai_skill_invoke.oldangxian = function(self,data)
	if q(self,"getCardsNum","Slash")<1 then
		for _,enemy in ipairs(self.enemies)do
			if q(self.player,"canSlash",enemy) then
				return true
			end
		end
	end
end

sgs.ai_skill_invoke.olenyuan = function(self,data)
	local damage = q(data,"toDamage")
	if damage.from then
		return not q(self,"isFriend",damage.from)
	end
	local move = q(data,"toMoveOneTime")
	if move.from then
		return q(self,"isFriend",move.from)
	end
end

sgs.ai_skill_use["@@olxuanhuo"] = function(self,prompt)
	local destlist = q(self.room,"getOtherPlayers",self.player)
    destlist = AIList.new(destlist) -- 将列表转换为表
    q(self,"sort",destlist,nil,true)
	local cards = q(self.player,"getCards","h")
	cards = q(self,"sortByKeepValue",cards)
	for _,p in sgs.list(destlist)do
		for _,e in sgs.list(self.enemies)do
			if q(p,"canSlash",e,false) then
				local valid = {}
				for _,h in sgs.list(cards)do
					table.insert(valid,q(h,"toString"))
					if #valid>1 then
						return "@OLXuanhuoCard="..table.concat(valid,"+").."->"..q(p,"objectName")
					end
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.olxuanhuo = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	q(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_cardask["olenyuan0"] = function(self,data,pattern,prompt)
	local damage = q(data,"toDamage")
    if q(self,"isFriend",damage.to) or q(self,"isWeak")
	or q(self,"getOverflow")>0
	then return true end
	return "."
end

sgs.ai_skill_invoke.oljiangchi = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_cardask["oljiangchi0"] = function(self,data,pattern,prompt)
    if q(self,"getCardsNum","Slash")>0
	then return true end
	return "."
end

sgs.ai_skill_use["@@olzongxuan"] = function(self,prompt)
	local valid = {}
	local cs = {}
	for _,id in sgs.list(tag(self,"olzongxuanForAI","list"))do
		table.insert(cs,face(self,id))
	end
	q(self,"sortByKeepValue",cs,true)
	if q(self.player,"getPhase")==sgs.Player_NotActive then
		for _,c in sgs.list(cs)do
			if q(self,"aiUseCard",c).card or q(self,"getKeepValue",c)>7 then
				table.insert(valid,q(c,"getId"))
			end
		end
		for _,c in sgs.list(cs)do
			if #valid<1 then
				table.insert(valid,q(c,"getId"))
			end
		end
	else
		q(self,"sort",self.enemies)
		for _,c in sgs.list(cs)do
			if q(c,"getTypeId")==3 then
				if q(self,"isWeak",self.friends) then
					table.insert(valid,q(c,"getId"))
				end
			elseif q(self,"isWeak",self.enemies) and self.enemies[1]:getHp()~=q(self.player,"getHp") then
				table.insert(valid,q(c,"getId"))
			end
		end
	end
	if #valid>0 then
    	return "@OLZongxuanCard="..table.concat(valid,"+")
	end
end

sgs.ai_skill_playerchosen.olzhiyan = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	q(self,"sort",destlist)
	local c = face(self,known(facts(self).visible_draw_top_id,"olzhiyan.drawtop"))
	if c and q(c,"hasFlag","visible") then
		if q(c,"getTypeId")==3 then
			for _,p in sgs.list(destlist)do
				if q(self,"isFriend",p) and q(p,"isWounded")
				then return p end
			end
			for _,p in sgs.list(destlist)do
				if q(self,"isFriend",p) and not q(self,"getSameEquip",c) and #q(self,"poisonCards",{c},p)<1
				then return p end
			end
			for _,p in sgs.list(destlist)do
				if q(self,"isFriend",p) and q(p,"isWounded")
				and not q(c,"isAvailable",p)
				then return p end
			end
			for _,p in sgs.list(destlist)do
				if q(self,"isEnemy",p) and not q(p,"isWounded")
				and #q(self,"poisonCards",{c},p)>0
				and q(c,"isAvailable",p)
				then return p end
			end
			for _,p in sgs.list(destlist)do
				if not q(self,"isEnemy",p)
				then return p end
			end
		end
	end
	for _,p in sgs.list(destlist)do
		if q(self,"isFriend",p) and q(self.player,"getHp")==q(p,"getHp")
		and q(self,"canDraw",p)
		then return p end
	end
	for _,p in sgs.list(destlist)do
		if q(self,"isEnemy",p) and q(self.player,"getHp")~=q(p,"getHp")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not q(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_skill_invoke.oljiezishou = function(self,data)
	return q(self,"canDraw") and #self.enemies>0
end

sgs.ai_skill_invoke.olzhuikong = function(self,data)
	local to = q(data,"toPlayer")
	if q(self,"isEnemy",to) then
		if q(to,"inMyAttackRange",self.player) then
			local mc = q(self,"getMaxCard")
			if mc then
				return q(mc,"getNumber")>9
			end
		end
		return #self.enemies>1
	end
end

sgs.ai_skill_playerchosen.olqiuyuan = function(self,players)
	local destlist = AIList.new(players) -- 将列表转换为表
	q(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_cardask["olqiuyuan1"] = function(self,data,pattern,prompt)
    local use = q(data,"toCardUse")
	if q(use.card,"isKindOf","Slash") then
		if q(self,"slashIsEffective",use.card,self.player) and q(self,"getCardsNum","Jink")<1 then
			return true
		end
	else
		if q(self,"hasTrickEffective",use.card,use.from,self.player) and q(self,"getCardsNum","Nullification")<1 then
			return true
		end
	end
	return "."
end

sgs.ai_skill_invoke.oljiejingce = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_general_choice_for_lord["ol_yuanshao"] = function(ai, generals, default_choice, lord)
	local role = q(ai.player,"getRole")
	local general_scores = {}
	for _, general_name in ipairs(generals) do
		local score = 0
		local general = general(ai,general_name)

		if general then
			local desc = q(general,"getSkillDescription",true) or ""
			local hp = q(general,"getMaxHp")

			if role == "loyalist" then
				if string.find(desc, "闪") then score = score + 3 end
				if string.find(desc, "受到伤害") and string.find(desc, "摸") then score = score + 5 end
				if hp >= 4 then score = score + 3 end
			else
				if string.find(desc, "受到伤害") then score = score + 5 end
			end

			local strategy_func = general_choice(ai,general_name)
			if type(strategy_func) == "function" then
				local recommend = strategy_func(ai, lord, role)
				if recommend == 1 then
					score = score + 10
				elseif recommend == -1 then
					score = score - 10
				end
			end
		end

		table.insert(general_scores, {name = general_name, score = score})
	end

	table.sort(general_scores, function(a, b) return a.score > b.score end)
	local best_score = general_scores[1] and general_scores[1].score or 0
	local best_generals = {}
	for _, gs in ipairs(general_scores) do
		if gs.score == best_score then
			table.insert(best_generals, gs.name)
		else
			break
		end
	end

	if #best_generals > 0 then
		return best_generals[math.random(1, #best_generals)]
	end

	return #generals > 0 and generals[math.random(1, #generals)] or default_choice
end

sgs.ai_general_choice_for_lord["second_ol_yuanshao"] = sgs.ai_general_choice_for_lord["ol_yuanshao"]











sgs.ai_skill_playerchosen.olshebian_from=function(self)return shebian_slot(self,'read','olshebian_from')end
sgs.ai_skill_playerchosen.olshebian_to=function(self)return shebian_slot(self,'read','olshebian_to')end
sgs.ai_skill_cardchosen.olshebian=function(self)return shebian_slot(self,'consume','olshebian')end
olguhuo_policy=sgs.ai_guhuo_card.olguhuo
-- Only callbacks assigned by this module are wrapped. Nested registries are
-- captured individually; no global-prefix sweep touches another package.
local function wrap(fn,registry,key,self_index)
 return function(...)
  local args=table.pack(...);local self=args[self_index]
  if registry=='ai_view_as'then self=nil end
  if self then load_state(self)end
  local result=table.pack(fn(table.unpack(args,1,args.n)))
  if AIUnsupported.is(result[1])then error(result[1],0)end
  if self then save_state(self)end
  if registry=='ai_skill_use'and type(result[1])=='string'and result[1]:sub(1,1)=='@'then result[1]=response(self,result[1])end
  if registry=='ai_guhuo_card'and type(result[1])=='string'then
   local id,name=result[1]:match('^@OLGuhuoCard=(%d+):(.+)$')
   if not id then ai_unsupported('OLGuhuo source proposal changed',key)end
   result[1]={skill='olguhuo',legacy_class='OLGuhuoCard',subcards={tonumber(id)},user_string=name}
  end
  if registry=='ai_cardsview_valuable'and type(result[1])=='string'then
   if result[1]=='@OLJijiangCard=.'then result[1]={skill='oljijiang',legacy_class='OLJijiangCard',subcards={}}
   elseif key=='oljiushi'then result[1]={name='analeptic',skill='oljiushi',suit=sgs.Card_NoSuit,number=0,subcards={}}
   elseif key=='olchunlao'then local id=result[1]:match('^@OLChunlaoCard=(%d+)$');result[1]={skill='olchunlao',legacy_class='OLChunlaoCard',subcards={tonumber(id)}}end
  end
  return table.unpack(result,1,result.n)
 end
end
for registry,t in pairs(sgs)do if type(t)=='table'and registry:match('^ai_')then
 for key,fn in pairs(t)do if type(fn)=='function'and (not before[registry]or before[registry][key]~=fn)then
  t[key]=wrap(fn,registry,key,(registry=='ai_skill_use_func'or registry=='ai_cardneed')and 3 or registry=='ai_skill_pindian'and 2 or 1)
 end end
end end
for bucket,t in pairs(sgs.ai_choicemade_filter)do if type(t)=='table'then for key,fn in pairs(t)do
 if type(fn)=='function'and(not before_nested[bucket]or before_nested[bucket][key]~=fn)then t[key]=wrap(fn,'ai_choicemade_filter',key,1)end
end end end
