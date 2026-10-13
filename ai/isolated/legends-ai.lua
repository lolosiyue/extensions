local PACKAGE="legends"
local SELECTORS={["#lol_zhengyiCard"]="lol_zhengyi",["#junhengCard"]="junheng",["#lol_lirenCard"]="lol_liren",["#duantouCard"]="duantou",["#gehouCard"]="gehou",["#zhuanzhuCard"]="zhuanzhu",["#yingyanCard"]="yingyan",["#ZhongliCard"]="Zhongli",["#mingxiangCard"]="mingxiang",["#shenghuaCard"]="shenghua",["#bihuCard"]="bihu",["#zhouchuCard"]="zhouchu",["#xieliCard"]="xieli",["#xielidestCard"]="xielidest",["#huanyinCard"]="huanyin",["#shixueCard"]="shixue",["#yongbaoCard"]="yongbao",["#cannueCard"]="cannue",["#lumangCard"]="lumang",["#moguCard"]="mogu",["#moyingCard"]="moying",["#mengyanCard"]="mengyan",["#lol_jiushuCard"]="lol_jiushu",["#guanzhuCard"]="guanzhu",["#lol_qiyuanCard"]="lol_qiyuan",["#shabingCard"]="shabing",["#jinjunCard"]="jinjun"}
local package_skills={}
-- Package-private source clone state. These plain records are not cards or receipts.
local active_requests=setmetatable({},{__mode="k"})
local clone_states=setmetatable({},{__mode='k'})
local function unsupported(key)ai_unsupported('source capability is not projected',PACKAGE..'.'..key)end
local function raw_call(o,k,...)
 if not o or type(o[k])~='function' then unsupported(k)end
 local v=table.pack(o[k](o,...));if AIUnsupported.is(v[1])then error(v[1],0)end;return table.unpack(v,1,v.n)
end
-- Donor tag reads: CurrentDamageStruct from the raw question context (invoke/
-- choice/response asks only), the viewer's own tags as QVariant reads them.
-- Room tags such as xinyan are not projected.
local function fact(self,key)
 if key=='CurrentDamageStruct'then
  local c=self.request and self.request.options and self.request.options.context
  local d=type(c)=='table'and c.damage;if type(d)~='table'then unsupported(key)end
  local row={};for k,x in pairs(d)do row[k]=x end
  for _,k in ipairs({'from','to'})do if row[k]==''then row[k]=nil end end;return row
 end
 if key=='KuileiSkills'then local v=self.player:getTag(key);if v==nil then return''end;return v end
 if key=='zhuanzhu'then local v=self.player:getTag(key);if v==nil then return false end;return v end
 unsupported(key)
end
local function clone(self,name,skill,suit,number)
 name=name or 'slash';local p=raw_call(self,'cloneEvaluationCard',name)
 if p==false then return nil end;if not p then unsupported('prototype.'..tostring(name))end
 local v={};clone_states[v]={self=self,name=raw_call(p,'objectName'),skill=skill or '',suit=suit==nil and sgs.Card_NoSuit or suit,number=number or 0,costs={},prototype=p,flags={}}
 return v
end
local function materialize(v)
 local s=clone_states[v];if not s then return v end
 if next(s.flags) then unsupported('clone_flags.'..s.skill)end
 local card
 if s.skill=='' and #s.costs==0 and s.suit==sgs.Card_NoSuit and s.number==0 then card=s.prototype
 else card=raw_call(s.self,'evaluateSkillCard',s.skill,s.name,s.costs)end
 if not card then unsupported('clone.'..s.skill..'.'..s.name)end
 -- Current narrow endpoint has no arbitrary face parameters. A mismatched native
 -- clone is unknown, never a substitute with different suit/rank.
 if #s.costs==0 and (raw_call(card,'getSuit')~=s.suit or raw_call(card,'getNumber')~=s.number)then unsupported('clone_face.'..s.skill)end
 if card~=s.prototype then clone_states[card]=s end;return card
end
local function copied_spec(s)
 local ids={};for i,id in ipairs(s.costs)do ids[i]=id end
 return{name=s.name,skill=s.skill,suit=s.suit,number=s.number,subcards=ids}
end
local function finish_turn(self,v,request)
 local s=clone_states[v];if not s then return v end
 if next(s.flags)then unsupported('turn_clone_flags.'..s.skill)end
 return raw_call(self,'evaluateTurnConversion',s.skill,raw_call(s.prototype,'getClassName'),copied_spec(s),request)
end
local function proposal(self,v)
 local s=clone_states[v];if s then return copied_spec(s)end
 if AIValue.isConversion(v)then return raw_call(v,'toCardSpec')end
 return raw_call(v,'getEffectiveId')
end
local function package_call(o,k,...)
 local args=table.pack(...);local s=clone_states[o]
 if s then
  if k=='setSkillName'then s.skill=args[1];return end
  if k=='deleteLater'then return end
  if k=='clearSubcards'then s.costs={};return end
  if k=='addSubcard'then local x=args[1];s.costs[#s.costs+1]=type(x)=='number'and x or raw_call(x,'getEffectiveId');return end
  if k=='addSubcards'then for _,x in ipairs(args[1])do s.costs[#s.costs+1]=type(x)=='number'and x or raw_call(x,'getEffectiveId')end;return end
  if k=='setFlags'then s.flags[args[1]]=true;return end
  if k=='subcardsLength'then return #s.costs end
  if k=='getSubcards'then return AIList.new(copied_spec(s).subcards)end
  if k=='getSkillName'then if args[1]~=false and s.skill:sub(1,1)=='_'then return s.skill:sub(2)end;return s.skill end
  if k=='objectName'then return s.name end
  o=materialize(o)
 end
 for i=1,args.n do
  if clone_states[args[i]]then args[i]=materialize(args[i])
  elseif AIValue.isList(args[i])then for j,v in ipairs(args[i])do if clone_states[v]then args[i][j]=materialize(v)end end end
 end
 if k=='toString' and (AIValue.isCard(o)or AIValue.isConversion(o))then k='getLegacyStringKey'end
 return raw_call(o,k,table.unpack(args,1,args.n))
end
local function package_known(o,k,...)
 local v=table.pack(package_call(o,k,...));if v[1]==nil then unsupported(k)end;return table.unpack(v,1,v.n)
end
local function dummy(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or{};return u end
local function patterns_for(self,class)
 if class then return patterns(class)end
 local a=AICardCatalog.patternNames()
 if not AIValue.isList(a)then unsupported('pattern_names')end;return a
end
local function source_fact(self,key,kind)
 local v=fact(self,key)
 if kind=='toPlayer'then return v~=false and package_known(self.room,'findPlayerByObjectName',v,true)or nil end
 if kind=='toInt'or kind=='toString'or kind=='toBool'then return v end
 if kind=='toIntList'then return AIList.new(v)end
 if kind=='toHpLost'or kind=='toMaxHp'then return v~=false and v or nil end
 if kind=='toMoveOneTime'then if v==false then return nil end;local d={};for k,x in pairs(v)do d[k]=x end;for _,k in ipairs({'card_ids','from_places'})do if d[k]then d[k]=AIList.new(d[k])end end;for _,k in ipairs({'from','to'})do if d[k]then d[k]=package_known(self.room,'findPlayerByObjectName',d[k],true)end end;return d end
 if kind=='toJudge'then if v==false then return nil end;local j={};for k,x in pairs(v)do j[k]=x end;j.who=j.who and package_known(self.room,'findPlayerByObjectName',j.who,true);j.card=j.card and CardView.new(j.card);function j:isGood(c)if not c then return self.good end;if self.outcomes_complete~=true or type(self.outcome_by_id)~='table'then unsupported('judge_outcomes.'..key)end;local n=self.outcome_by_id[tostring(package_known(c,'getEffectiveId'))];if type(n)~='boolean'then unsupported('judge_outcome.'..key)end;return n end;function j:isBad(c)return not self:isGood(c)end;return j end
 if kind=='toCardUse'then
  if v==false then return{to=AIList.new({})}end
  local u={card=v.card and CardView.new(v.card),from=v.from and package_known(self.room,'findPlayerByObjectName',v.from,true),to=AIList.new({})}
  for _,n in ipairs(v.to or{})do u.to:append(package_known(self.room,'findPlayerByObjectName',n,true))end;return u
 end
 if kind=='toDamage'then local d={};for k,x in pairs(v)do d[k]=x end;for _,k in ipairs({'from','to'})do if d[k]then d[k]=package_known(self.room,'findPlayerByObjectName',d[k],true)end end;if d.card then d.card=CardView.new(d.card)end;return d end
 unsupported(key..'.'..kind)
end
local function skill_source(self,selector,costs,request,user)
 request=request or active_requests[self]
 local skill=SELECTORS[selector];if not skill then unsupported('selector.'..selector)end
 if request and type(request.getActivationSkillName)=='function'then skill=request:getActivationSkillName()end
 return package_known(self,'evaluateTurnSkillCard',skill,selector,costs,request,user~=''and user or nil)
end
-- Only literals present in this package's source may enter this small grammar.
-- It is a pure policy constructor, never Card_Parse or an action-string parser.
local function source_skill(self,text,request)
 if type(text)~='string'then unsupported('source_skill')end
 text=text:match('^(.-)%->')or text
 local selector,cost,user=text:match('^(#[%w_]+):([^:]*):(.*)$')
 if not selector then unsupported('source_skill_shape')end
 local ids={};if cost~='.'and cost~=''then for x in cost:gmatch('[^+]+')do local id=tonumber(x);if not id or id<0 or id%1~=0 then unsupported('source_cost')end;ids[#ids+1]=id end end
 return skill_source(self,selector,ids,request,user)
end
local function selected(self,card,targets)
 local s=clone_states[card];local actual
 if s then actual=package_known(self,'bindOriginalSelectedConversion',copied_spec(s),package_known(s.prototype,'getClassName'),s.skill)
 elseif AIValue.isConversion(card)then actual=card
 elseif package_known(card,'isEvaluationOnly')then actual=package_known(self,'materializeTurnSelectedCard',card)
 else actual=card end
 local p=AIUsePlan.new();p.card=actual
 for _,n in ipairs(targets)do p.to:append(type(n)=='string'and package_known(self.room,'findPlayerByObjectName',n,true)or n)end
 return p:toAnswer()
end
local function response_skill(self,selector,costs,targets,request,user)
 local sk=SELECTORS[selector];if not sk then unsupported('response_selector.'..selector)end
 if request and type(request.getActivationSkillName)~='function'then request=AILegacyRequest.new(request,self.player,sk)end
 local c=package_known(self,'bindSkillCard',sk,costs,request,user,selector);return selected(self,c,targets)
end
local function save_plan(self,key,plan)
 local c=plan.card;local s=clone_states[c];local row=s and{spec=copied_spec(s)}or{card_id=c and package_known(c,'getEffectiveId')}
 row.targets={};for _,p in ipairs(plan.to or{})do row.targets[#row.targets+1]=package_known(p,'objectName')end
 package_call(self,'setStrategyMemory',PACKAGE..'.plan.'..key,row)
end
local function load_plan(self,key)
 local row,known=package_call(self,'getStrategyMemory',PACKAGE..'.plan.'..key);if not known or type(row)~='table'then unsupported('plan.'..key)end
 local p=dummy();if row.spec then local s=row.spec;p.card=clone(self,s.name,s.skill,s.suit,s.number);clone_states[p.card].costs=s.subcards else p.card=package_known(self,'getKnownCardById',row.card_id)end
 for _,n in ipairs(row.targets)do p.to:append(package_known(self.room,'findPlayerByObjectName',n,true))end;return p
end

local function clone_native(self,name,suit,number)return clone(self,name,nil,suit,number)end
local function conversion_clone(self,name,skill,suit,number,ids)local c=clone(self,name,skill,suit,number);clone_states[c].costs=ids;return c end
local function owner_ai(self,player)if player~=self.player then unsupported("foreign_ai")end;return self end
-- Another player's tags are not projected (getTag raises); the viewer's own
-- read as QVariant::toString.
local function source_player_fact(self,player,key)if not AIValue.isPlayer(player)then unsupported("player_fact."..key)end;local v=player:getTag(key);if v==nil then return""end;return v end
local function source_error(key)ai_unsupported("fixed donor calls an unavailable method",PACKAGE..".donor_error."..key)end
local function visible_hand(self,to)if to==self.player then return package_known(to,"getHandcards")end;local cards=package_known(self,"getKnownCards",to,self.player,"h");if #cards<package_known(to,"getHandcardNum")then package_known(self,"useKnowledgeEstimate",{value=#cards,status="estimate",basis="legends.shenyan known cards under viewer visibility; original current-player visibility unavailable",target=package_known(to,"objectName")},"legends.shenyan")end;return cards end
local function turn_count(self)local v=self.world and self.world.turn_count;if type(v)~="number"then unsupported("turncount")end;return v end
local function set_memory(self,key,value)package_call(self,"setStrategyMemory","legends."..key,value)end
local function xieli_source(self)local v,known=package_call(self,"getStrategyMemory","legends.xielisource");if not known then package_known(self,"useKnowledgeEstimate",{value=false,status="estimate",basis="legends.xielisource unobserved prior history",viewer=package_known(self.player,"objectName")},"legends.xielisource");return nil end;return v~=false and package_known(self.room,"findPlayerByObjectName",v,true)or nil end
local function set_thornmail(self,value)package_call(self,"setStrategyMemory","ai_Thornmail_effect",value)end
-- Donor sgs.ai_skills membership: this VM's own fill-skill registries are authoritative.
local function source_fill_skills(self)local out={};for name in pairs(sgs.ai_fill_skill or{})do out[#out+1]={name=name}end;for _,s in ipairs(sgs.ai_skills or{})do out[#out+1]={name=s.name}end;return out end
local function skill_proposal(selector,costs,user)local sk=SELECTORS[selector];if not sk then unsupported("selector."..selector)end;return{name=selector:sub(2),skill=sk,suit=sgs.Card_NoSuit,number=0,subcards=costs,user_string=user}end
local function response_value(self,card)if package_known(card,"isEvaluationOnly")then card=package_known(self,"materializeResponseSelectedCard",card)end;if AIValue.isConversion(card)then return package_known(card,"toCardSpec")end;return package_known(card,"getEffectiveId")end









sgs.ai_skill_invoke.lvdong = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	local from = damage.from
	if package_known(self,"isFriend",target) then
		return false
	elseif package_known(self,"cantDamageMore",from,target) then
		return false
	elseif package_known(target,"hasArmorEffect","SilverLion") or package_known(target,"hasArmorEffect","xieshen") then
		return false
	elseif package_known(target,"hasArmorEffect","jingji") and package_known(from,"getHp") <= 2 then
		return false
	elseif package_known(target,"hasArmorEffect","zhongya") and (not package_known(target,"faceUp")) then
		return false
	end
	return true
end
sgs.ai_choicemade_filter.skillInvoke.lvdong = function(self, player, promptlist)
	local damage = source_fact(self,"CurrentDamageStruct","toDamage")
	if damage.to then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, damage.to, 80)
		end
	end
end

sgs.ai_ajustdamage_from.lvdong = function(self,from,to,card,nature)
	if package_known(to,"getStrategyMark","@lvdong") == 0 and not beFriend(to,from)
	then return 1 end
end
sgs.ai_skill_playerchosen.tulong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if package_known(self,"isFriend",target) and package_known(target,"isAlive") and package_known(self,"canDraw",target, self.player) then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.tulong = -40

sgs.ai_cardneed.lol_zhiming = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|lol_zhiming"
sgs.ai_canliegong_skill.lol_zhiming = function(self, from, to)
	return package_known(to,"getHp") < package_known(from,"getHp") and package_known(from,"distanceTo",to) <= 1
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|yongqi"


local lol_zhengyi_skill = {}
lol_zhengyi_skill.name= "lol_zhengyi"
table.insert(package_skills,lol_zhengyi_skill)
lol_zhengyi_skill.getTurnUseCard=function(self,inclusive,request)
	return source_skill(self,"#lol_zhengyiCard:.:")
end

sgs.ai_skill_use_func["#lol_zhengyiCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"objectiveLevel",enemy)>3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy)
		and package_known(self.player,"distanceTo",enemy)<=package_known(self.player,"getAttackRange") and not package_known(self,"cantDamageMore",self.player,enemy) and package_known(enemy,"getLostHp") > 0 then
			use.card = source_skill(self,"#lol_zhengyiCard:.:")
			package_call(use.to,"append",enemy)
			return
		end
	end
end

sgs.ai_use_value.lol_zhengyiCard = 2.5
sgs.ai_card_intention.lol_zhengyiCard = 80
sgs.dynamic_value.damage_card.lol_zhengyiCard = true


sgs.ai_skill_invoke.xinyan = function(self, data)
	local use = package_known(data,"toCardUse")
	local from = use.from
	local max_card = package_call(self,"getMaxCard")
	if not max_card then return end
	if package_known(max_card,"getNumber") > 10 and package_known(self,"isFriend",from) then
		if package_known(from,"getHandcardNum") == 1 and package_known(self,"needKongcheng",from) then return true end
		if package_known(self,"getOverflow",from) > 2 then return true end
		if not package_known(self,"hasLoseHandcardEffective",from) then return true end
	end
	if package_known(self,"isFriend",from) then return false end
	if package_known(max_card,"getNumber") > 10
		or (package_known(self.player,"getHp") > 2 and package_known(self.player,"getHandcardNum") > 2 and package_known(max_card,"getNumber") > 4)
		or (package_known(self.player,"getHp") > 1 and package_known(self.player,"getHandcardNum") > 1 and package_known(max_card,"getNumber") > 7)
		or (package_known(from,"getHandcardNum") <= 2 and package_known(max_card,"getNumber") > 2)
		or (package_known(from,"getHandcardNum") == 1 and package_known(self,"hasLoseHandcardEffective",from) and not package_known(self,"needKongcheng",from))
		or package_known(self,"getOverflow") > 2 then
		return true
	end
end

sgs.ai_choicemade_filter.skillInvoke.xinyan = function(self, player, promptlist)
	local use = source_fact(self,"xinyan","toCardUse")
	if use.from and promptlist[3] == "yes" then
		local target = use.from
		local intention = 10
		if package_known(target,"getHandcardNum") == 1 and package_known(self,"needKongcheng",target) then intention = 0 end
		if package_known(self,"getOverflow",target) > 2 then intention = 0 end
		if not package_known(self,"hasLoseHandcardEffective",target) then intention = 0 end
		sgs.updateIntention(player, target, intention)
	end
end

function sgs.ai_skill_pindian.xinyan(minusecard, self, requestor)
	local maxcard = package_call(self,"getMaxCard")
	return package_known(self,"isFriend",requestor) and minusecard or ( package_known(maxcard,"getNumber") < 6 and minusecard or maxcard )
end

sgs.ai_cardneed.xinyan = sgs.ai_cardneed.bignumber
sgs.ai_ajustdamage_to.daren = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Duel")
	then
		return -99
	end
end

sgs.ai_cardneed.jianwu = sgs.ai_cardneed.slash


local function getSkillTarget(self, trick, targets)
	local enemies = {}
	for _,p in ipairs(targets) do
		if package_known(self,"isEnemy",p) then
			if package_known(trick,"targetFilter",sgs.PlayerList(), p, self.player) then
				table.insert(enemies, p)
			end
		end
	end
	if #enemies == 0 then
		return nil
	end
	local ZhangHe = package_call(self.room,"findPlayerBySkillName","qiaobian")
	local ZhangHeSeat = 0
	local ZhangHeRound = 0
	if ZhangHe and package_known(ZhangHe,"faceUp") then
		if not package_known(ZhangHe,"isKongcheng") then
			if not package_known(self,"isFriend",ZhangHe) then
				ZhangHeSeat = package_known(ZhangHe,"getSeat")
				ZhangHeRound = package_known(self,"playerGetRound",ZhangHe)
			end
		end
	end
	local DaQiao = package_call(self.room,"findPlayerBySkillName","yanxiao")
	local YanXiao = false
	local DaQiaoRound = 0
	if DaQiao and package_known(DaQiao,"faceUp") then
		if not package_known(self,"isFriend",DaQiao) then
			if getKnownCard(DaQiao, self.player, "diamond", nil, "he") > 0 then
				YanXiao = true
			elseif package_known(DaQiao,"containsTrick","YanxiaoCard") then
				YanXiao = true
			else
				local num = package_known(DaQiao,"getHandcardNum")
				local skills = package_known(DaQiao,"getVisibleSkillList",true)
				local draw = package_known(self,"ImitateResult_DrawNCards",DaQiao, skills)
				if num + draw > 3 then
					YanXiao = true
				end
			end
			if YanXiao then
				DaQiaoRound = package_known(self,"playerGetRound",DaQiao)
			end
		end
	end
	local getIndulgenceValue = function(enemy)
		if package_known(enemy,"containsTrick","indulgence") or package_known(enemy,"containsTrick","YanxiaoCard") then
			return -100
		end
		if package_known(enemy,"hasSkill","qiaobian") then
			if not package_known(enemy,"containsTrick","supply_shortage") and not package_known(enemy,"containsTrick","indulgence") then
				return -100
			end
		end
		local round = package_known(self,"playerGetRound",enemy)
		if ZhangHeSeat > 0 then
			if ZhangHeRound <= round and package_known(self,"enemiesContainsTrick") <= 1 or not package_known(enemy,"faceUp") then
				return -100
			end
		end
		if YanXiao then
			if DaQiaoRound <= round and package_known(self,"enemiesContainsTrick",true) <= 1 or not package_known(enemy,"faceUp") then
				return -100
			end
		end
		local value = package_known(enemy,"getHandcardNum") - package_known(enemy,"getHp")
		local skills = "noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|"
		skills = skills .. "anxu|yongsi|zhiheng|manjuan|nosrende|rende|qixi|jixi"
		if package_known(enemy,"hasSkills",skills) then
			value = value + 10
		end
		skills = "houyuan|qice|guose|duanliang|yanxiao|nosjujian|luoshen|nosjizhi|jizhi|mengyan|wansha|mingce|sizhan"
		if package_known(enemy,"hasSkills",skills) then
			value = value + 5
		end
		skills = "guzheng|shenyanng|xiliang|guixin|lihun|yinling|yingyan|shenfen|ganlu|heg_duoshi|jueji|zhenggong"
		if package_known(enemy,"hasSkills",skills) then
			value = value + 3
		end
		if package_known(self,"isWeak",enemy) then
			value = value + 3
		end
		if package_known(enemy,"isLord") then
			value = value + 3
		end
		if package_known(self,"objectiveLevel",enemy) < 3 then
			value = value - 10
		end
		if not package_known(enemy,"faceUp") then
			value = value - 10
		end
		if package_known(enemy,"hasSkills","keji|shensu|conghui") then
			value = value - package_known(enemy,"getHandcardNum")
		end
		if package_known(enemy,"hasSkills","guanxing|xiuluo") then
			value = value - 5
		end
		if package_known(enemy,"hasSkills","lirang|longluo") then
			value = value - 5
		end
		if package_known(enemy,"hasSkills","tuxi|noszhenlie|guanxing|juewang|zongshi|tiandu") then
			value = value - 3
		end
		if package_known(enemy,"hasSkill","conghui") then
			value = value - 20
		end
		if package_known(self,"needBear",enemy) then
			value = value - 20
		end
		if not package_known(self,"isGoodTarget",enemy, self.enemies) then
			value = value - 1
		end
		if getKnownCard(enemy, self.player, "Dismantlement", true) > 0 then
			value = value + 2
		end
		value = value + (package_known(self.room,"alivePlayerCount") - round) / 2
		return value
	end
	local getSupplyShortageValue = function(enemy)
		if package_known(enemy,"containsTrick","supply_shortage") or package_known(enemy,"containsTrick","YanxiaoCard") then
			return -100
		end
		if package_known(enemy,"getStrategyMark","juao") > 0 then
			return -100
		end
		if package_known(enemy,"hasSkill","qiaobian") then
			if not package_known(enemy,"containsTrick","supply_shortage") and not package_known(enemy,"containsTrick","indulgence") then
				return -100
			end
		end
		local round = package_known(self,"playerGetRound",enemy)
		if ZhangHeSeat > 0 then
			if ZhangHeRound <= round and package_known(self,"enemiesContainsTrick") <= 1 or not package_known(enemy,"faceUp") then
				return - 100
			end
		end
		if YanXiao then
			if DaQiaoRound <= round and package_known(self,"enemiesContainsTrick",true) <= 1 or not package_known(enemy,"faceUp") then
				return -100
			end
		end
		local value = 0 - package_known(enemy,"getHandcardNum")
		local skills = "yongsi|haoshi|tuxi|noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|manjuan|beige"
		if package_known(self,"hasSkills",skills, enemy) then
			value = value + 10
		elseif package_known(enemy,"hasSkill","zaiqi") and package_known(enemy,"getLostHp") > 1 then
			value = value + 10
		end
		skills = "zhaolie|tianxiang|juewang|yanxiao|zhaoxin|zhouchu|renjie"
		if package_known(self,"hasSkills",sgs.cardneed_skill, enemy) then
			value = value + 5
		elseif package_known(self,"hasSkills",skills, enemy) then
			value = value + 5
		end
		skills = "yingzi|shelie|xuanhuo|buyi|jujian|jiangchi|mizhao|hongyuan|chongzhen|heg_duoshi"
		if package_known(self,"hasSkills",skills, enemy) then
			value = value + 1
		end
		if package_known(enemy,"hasSkill","noszishou") then
			value = value + package_known(enemy,"getLostHp")
		end
		if package_known(self,"isWeak",enemy) then
			value = value + 5
		end
		if package_known(enemy,"isLord") then
			value = value + 3
		end
		if package_known(self,"objectiveLevel",enemy) < 3 then
			value = value - 10
		end
		if not package_known(enemy,"faceUp") then
			value = value - 10
		end
		if package_known(self,"hasSkills","keji|shensu|qingyi", enemy) then
			value = value - package_known(enemy,"getHandcardNum")
		end
		if package_known(self,"hasSkills","guanxing|xiuluo|tiandu|guidao|noszhenlie", enemy) then
			value = value - 5
		end
		if not package_known(self,"isGoodTarget",enemy, self.enemies) then
			value = value - 1
		end
		if package_known(self,"needKongcheng",enemy) then
			value = value - 1
		end
		if package_known(enemy,"getStrategyMark","@kuiwei") > 0 then
			value = value - 2
		end
		return value
	end
	local values = {}
	local getValue = nil
	if package_known(trick,"isKindOf","Indulgence") then
		getValue = getIndulgenceValue
	elseif package_known(trick,"isKindOf","SupplyShortage") then
		getValue = getSupplyShortageValue
	end
	if type(getValue) == "function" then
		for _,enemy in ipairs(enemies) do
			values[package_known(enemy,"objectName")] = getValue(enemy)
		end
	end
	local compare_func = function(a, b)
		local valueA = values[package_known(a,"objectName")] or 0
		local valueB = values[package_known(b,"objectName")] or 0
		return valueA > valueB
	end
	table.sort(enemies, compare_func)
	local target = enemies[1]
	local value = values[package_known(target,"objectName")] or -100
	if value > -100 then
		return target
	end
	return nil
end






local skill_skill = {
	name = "junheng",
	getTurnUseCard = function(self,inclusive,request)
		if package_known(self.player,"isKongcheng") then
			return nil
		end
		return source_skill(self,"#junhengCard:.:")
	end,
}
table.insert(package_skills, skill_skill)
sgs.ai_skill_use_func["#junhengCard"] = function(card,use,self,request)
	local others = package_known(self.room,"getAlivePlayers")
	local targets = {}
	local hp = package_known(self.player,"getHp")
	for _,p in sgs.qlist(others) do
		if package_known(p,"getHp") >= hp then
			table.insert(targets, p)
		end
	end
	if #targets == 0 then
		return
	end
	local handcards = package_known(self.player,"getHandcards")
	local reds, blacks = {}, {}
	for _,c in sgs.qlist(handcards) do
		if package_known(c,"isRed") then
			table.insert(reds, c)
		elseif package_known(c,"isBlack") then
			table.insert(blacks, c)
		end
	end
	if #reds > 0 then
		local to_use = nil
		package_call(self,"sortByUseValue",reds, true)
		for _,red in ipairs(reds) do
			local dummy_use = package_known(self,"aiUseCard",red, dummy())
			if not dummy_use.card then
				to_use = red
				break
			end
		end
		if to_use then
			local suit = package_known(to_use,"getSuit")
			local point = package_known(to_use,"getNumber")
			local indulgence = clone_native(self,"indulgence", suit, point)
			package_call(indulgence,"deleteLater")
			local target = getSkillTarget(self, indulgence, targets)
			if target then
				local card_str = "#junhengCard:"..package_known(to_use,"getEffectiveId")..":->"..package_known(target,"objectName")
				local acard = source_skill(self,card_str)
				assert(acard)
				use.card = acard
				if use.to then
					package_call(use.to,"append",target)
				end
				return
			end
		end
	end
	if #blacks > 0 then
		local to_use = nil
		package_call(self,"sortByUseValue",blacks, true)
		for _,black in ipairs(blacks) do
			local dummy_use = package_known(self,"aiUseCard",black, dummy())
			if not dummy_use.card then
				to_use = black
				break
			end
		end
		if to_use then
			local suit = package_known(to_use,"getSuit")
			local point = package_known(to_use,"getNumber")
			local supply_shortage = clone_native(self,"supply_shortage", suit, point)
			package_call(supply_shortage,"deleteLater")
			local target = getSkillTarget(self, supply_shortage, targets)
			if target then
				local card_str = "#junhengCard:"..package_known(to_use,"getEffectiveId")..":->"..package_known(target,"objectName")
				local acard = source_skill(self,card_str)
				assert(acard)
				use.card = acard
				if use.to then
					package_call(use.to,"append",target)
				end
				return
			end
		end
	end
end

sgs.ai_use_value["junhengCard"] = 4
sgs.ai_use_priority["junhengCard"] = 9
sgs.ai_card_intention["junhengCard"] = 70

sgs.need_equip_skill = sgs.need_equip_skill .. "|zhizun"
function sgs.ai_cardneed.zhizun(to,card,self)
	if not package_known(self,"willSkipPlayPhase",to) and package_known(to,"getStrategyMark","zhizun") == 0 then
		return package_known(card,"isKindOf","EquipCard")
	end
end

local lol_liren_skill = {
	name = "lol_liren",
	getTurnUseCard = function(self,inclusive,request)
		if package_known(self.player,"isKongcheng") then
			return nil
		elseif package_known(self.player,"hasUsed","#lol_lirenCard") then
			return nil
		end
		return source_skill(self,"#lol_lirenCard:.:")
	end,
}
table.insert(package_skills, lol_liren_skill)
sgs.ai_skill_use_func["#lol_lirenCard"] = function(card,use,self,request)
	local target = nil
	package_call(self,"sort",self.enemies, "defense")
	if package_known(self,"getCardsNum","Slash") > 0 then
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",slash, dummy())
		if dummy_use.card then
			for _, p in sgs.qlist(dummy_use.to) do
				if not package_known(p,"isKongcheng") or package_call(p,"getArmor") or package_known(self,"getOverflow") > 0 then
					target = p
					break
				end
			end
		end
	end
	if not target then
		if package_known(self,"getCardsNum","ArcheryAttack", self.player) > 0 then
			local aa = clone_native(self,"archery_attack", sgs.Card_Heart, 0)
			package_call(aa,"deleteLater")
			local dummy_use = package_known(self,"aiUseCard",aa, dummy())

			if dummy_use.card then
				for _,enemy in ipairs(self.enemies) do
					if package_known(enemy,"hasArmorEffect","Vine") then
						target = enemy
						break
					end
				end
				if not target then
					for _,enemy in ipairs(self.enemies) do
						if getCardsNum("Jink", enemy) > 0 then
							target = enemy
							break
						end
					end
				end
			end
		end
	end
	if not target then
		if package_known(self,"getCardsNum","SavageAssault", self.player) > 0 then
			local sa = clone_native(self,"savage_assault", sgs.Card_Spade, 0)
			package_call(sa,"deleteLater")
			local dummy_use = package_known(self,"aiUseCard",sa, dummy())
			if dummy_use.card then
				for _,enemy in ipairs(self.enemies) do
					if package_known(enemy,"hasArmorEffect","Vine") then
						target = enemy
						break
					end
				end
			end
		end
	end
	if target then
		local handcards = package_known(self.player,"getHandcards")
		handcards = sgs.QList2Table(handcards)
		package_call(self,"sortByUseValue",handcards, true)
		local card_id = nil
		for _,c in ipairs(handcards) do
			if not package_known(c,"isKindOf","Peach") then
				if not package_known(c,"isKindOf","AOE") then
					if package_known(c,"isKindOf","Slash") then
						if package_known(self,"getCardsNum","Slash") > 1 then
							card_id = package_known(c,"getEffectiveId")
							break
						end
					else
						card_id = package_known(c,"getEffectiveId")
						break
					end
				end
			end
		end
		if card_id then
			local card_str = "#lol_lirenCard:"..card_id..":->"..package_known(target,"objectName")
			local acard = source_skill(self,card_str)
			assert(acard)
			use.card = acard
			if use.to then
				package_call(use.to,"append",target)
			end
		end
	end
end

sgs.ai_use_value["lol_lirenCard"] = 4
sgs.ai_use_priority["lol_lirenCard"] = 9
sgs.ai_card_intention["lol_lirenCard"] = 80

sgs.ai_skill_invoke.zhican = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	local from = damage.from
	if package_known(self,"isFriend",target) then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@zhicandis"] = function(self,data,pattern)
	local damage = package_known(data,"toDamage")
	if damage.from and (not package_known(damage.from,"hasSkill","duantou") or  package_known(damage.from,"getStrategyMark","@duantou") == 0) then return "." end
	if(package_known(self,"ajustDamage",damage.from,self.player,package_known(self.player,"getStrategyMark","@blood"),nil)<2
	and package_known(self,"needToLoseHp",self.player,damage.from,nil)) then return "." end
	if package_known(self,"ajustDamage",damage.from,self.player,package_known(self.player,"getStrategyMark","@blood"),nil) + package_known(self,"getCardsNum","Peach")>0 then return "." end
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)
	for _,card in ipairs(cards)do do
		if not package_known(card,"isRed") or (not package_known(self,"isWeak") and (package_known(self,"getKeepValue",card)>8 or package_known(self,"isValuableCard",card))) then goto package_continue_1 end
		return package_known(card,"getEffectiveId")
	end ::package_continue_1:: end
end

local duantou_skill = {}
duantou_skill.name= "duantou"
table.insert(package_skills,duantou_skill)
duantou_skill.getTurnUseCard=function(self,inclusive,request)
	return source_skill(self,"#duantouCard:.:")
end

sgs.ai_skill_use_func["#duantouCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"objectiveLevel",enemy)>3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy)
		and package_known(self.player,"distanceTo",enemy)<=package_known(self.player,"getAttackRange") and package_known(enemy,"getStrategyMark","@blood")>=package_known(enemy,"getHp") and not package_known(self,"cantDamageMore",self.player,enemy)
		then
			use.card = source_skill(self,"#duantouCard:.:")
			package_call(use.to,"append",enemy)
			return
		end
	end
end

sgs.ai_use_value["duantouCard"] = 2.5
sgs.ai_card_intention["duantouCard"] = 80
sgs.dynamic_value.damage_card["duantouCard"] = true

sgs.ai_skill_invoke.tieshou = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	local from = damage.from
	if package_known(self,"isFriend",target) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.buxiang = function(self, from, to, card, nature)
	return package_known(to,"getStrategyMark","@buxiang")
end







ai_skill_use["@@gehou"]=function(self,prompt,request)
	if #self.enemies > 0 then
		local mymaxcard = package_call(self,"getMaxCard")
		if mymaxcard then
			local mymaxpoint = package_known(mymaxcard,"getNumber")
			package_call(self,"sort",self.enemies, "handcard")
			self.enemies = sgs.reverse(self.enemies)
			local targets = {}
			for _,enemy in ipairs(self.enemies) do
				if not package_known(enemy,"isKongcheng") then
					local maxcard = package_call(self,"getMaxCard",enemy)
					local maxpoint = maxcard and package_known(maxcard,"getNumber") or 10
					if mymaxpoint > maxpoint then
						table.insert(targets, enemy)
					end
				end
			end
			local target = nil
			if #targets > 0 then
				for _,enemy in ipairs(targets) do
					if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) then
						if not package_known(self,"cantbeHurt",enemy) then
							target = enemy
							break
						end
					end
				end
				target = target or self.enemies[#self.enemies]
			end
			if target then
				local card_str = "#gehouCard:"..package_known(mymaxcard,"getEffectiveId")..":->"..package_known(target,"objectName")
				return response_skill(self,"#gehouCard",{package_known(mymaxcard,"getEffectiveId")},{package_known(target,"objectName")},request)
			end
		end
	end
	return "."
end
sgs.ai_cardneed.gehou = sgs.ai_cardneed.bignumber


sgs.ai_ajustdamage_from.gehou = function(self, from, to, card, nature)
	if to and package_known(to,"objectName") == source_player_fact(self,from,"GehouTarget") then
		return 1
	end
end
sgs.ai_ajustdamage_from.lianmin = function(self, from, to, card, nature)
	if (not package_known(to,"getJudgingArea"):isEmpty()) or (not (package_known(to,"faceUp"))) then
		return 1
	end
end





sgs.ai_skill_invoke["kuilei"] = function(self, data)
	local record = source_fact(self,"KuileiSkills","toString")
	local skillnames = package_known(record,"split","+")
	local value = 0
	for _,skillname in ipairs(skillnames) do
		if skillname == "benghuai" then
			value = value - 10
		elseif skillname == "wumou" then
			value = value - 6
		elseif string.find("shiyong|yaowu|wuyan|noswuyan", skillname) then
			value = value - 1
		elseif string.find(sgs.priority_skill, skillname) then
			value = value + 4
		else
			for _,skill in ipairs(source_fill_skills(self)) do
				if skill.name == skillname then
					value = value + 1
					break
				end
			end
		end
	end
	return value > 0
end

sgs.ai_ajustdamage_from.jihun = function(self, from, to, card, nature)
	if card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel"))
	then
		return package_known(from,"getStrategyMark","@hun")
	end
end

sgs.ai_chaofeng["Mordekaiser"] = 1

local jianshen_skill = {}
jianshen_skill.name = "jianshen"
table.insert(package_skills, jianshen_skill)
jianshen_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","Forbidjianshen-PlayClear") > 0 then return end
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)

	local slash_card

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if package_known(card,"isKindOf","Slash") then
			local shouldUse = true

			if shouldUse then
				slash_card = card
				break
			end

		end
	end

	if slash_card then
		local suit = package_known(slash_card,"getSuitString")
		local number = package_known(slash_card,"getNumberString")
		local card_id = package_known(slash_card,"getEffectiveId")
		local card_str = ("archery_attack:jianshen[%s:%s]=%d"):format(suit, number, card_id)
		local archery_attack=conversion_clone(self,"archery_attack","jianshen",package_known(slash_card,"getSuit"),package_known(slash_card,"getNumber"),{card_id})

		assert(archery_attack)

		return archery_attack
	end
end
sgs.ai_card_priority.jianshen = function(self,card,v)
	if package_known(card,"isKindOf","ArcheryAttack")
	then return 6 end
end

sgs.jianshen_keep_value = {
	Slash = 4.2,
}

function sgs.ai_cardneed.jianshen(to, card)
	return package_known(card,"isKindOf","Slash")
end

ai_skill_use["@@zhuanzhu"]=function(self,prompt,request)
	local card = source_fact(self,"zhuanzhu","toCardUse").card
	local targets = {}
	local players = sgs.QList2Table(package_known(self.room,"getAllPlayers"))
	package_call(self,"sort",players, "defense")
	for _, player in ipairs(players) do
		if package_known(player,"getStrategyFlag","zhuanzhu") then
			if package_known(self,"aoeIsEffective",card,player,self.player) and package_known(self,"isFriend",player) and not package_known(self,"needToLoseHp",player, self.player, card) then
				table.insert(targets, package_known(player,"objectName"))
			end
			if #targets >= package_known(self.player,"getHp") then
				break
			end
		end
	end
	if #targets == 0 then return "." end
	return response_skill(self,"#zhuanzhuCard",{},targets,request)
end

sgs.ai_card_intention.zhuanzhuCard = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		local intention = -80
		sgs.updateIntention(from, to, intention)
	end
end



local yingyan_skill = {}
yingyan_skill.name = "yingyan"
table.insert(package_skills, yingyan_skill)
yingyan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isKongcheng") then return end
	if not package_known(self.player,"hasUsed","#yingyanCard") then
		return source_skill(self,"#yingyanCard:.:")
	end
end

sgs.ai_skill_use_func["#yingyanCard"] = function(card,use,self,request)
	package_call(self,"updatePlayers")
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if not package_known(enemy,"isKongcheng") then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	local acard = source_skill(self,"#yingyanCard:.:")
	use.card = acard
	if use.to then package_call(use.to,"append",targets[1]) end
end

sgs.ai_use_priority["yingyanCard"] = 3
sgs.ai_use_value["yingyanCard"] = 1
sgs.ai_card_intention["yingyanCard"] = 40

sgs.ai_skill_choice.Mohe = function(self, choices)
	local choices_table = package_known(choices,"split","+")
	return choices_table[math.random(1, #choices_table)]
end

local Zhongli_skill = {}
Zhongli_skill.name = "Zhongli"
table.insert(package_skills, Zhongli_skill)
Zhongli_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isKongcheng") then return end
	if not package_known(self.player,"hasUsed","#ZhongliCard") then
		return source_skill(self,"#ZhongliCard:.:")
	end
end

sgs.ai_skill_use_func["#ZhongliCard"] = function(card,use,self,request)
	package_call(self,"updatePlayers")
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local slashcount = package_known(self,"getCardsNum","Slash")
	if slashcount>0 then
		local slash = package_call(self,"getCard","Slash")
		if slash then
			local dummy_use = package_known(self,"aiUseCard",slash, dummy(true))
			if not package_known(dummy_use.to,"isEmpty") then
				for _, p in sgs.qlist(dummy_use.to) do
					for _, card in ipairs(cards) do
						if package_known(self,"getCardsNum","Slash") > 1 then
							use.card = source_skill(self,"#ZhongliCard:" .. package_known(card,"getId") .. ":")
							if use.to then
								package_call(use.to,"append",p)
							end
							return
						elseif not package_known(card,"isKindOf","Slash") then
							use.card = source_skill(self,"#ZhongliCard:" .. package_known(card,"getId") .. ":")
							if use.to then
								package_call(use.to,"append",p)
							end
							return
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_priority["ZhongliCard"] = 3
sgs.ai_use_value["ZhongliCard"] = 1
sgs.ai_card_intention["ZhongliCard"] = 40
sgs.ai_use_priority["ZhongliCard"] = sgs.ai_use_priority.Slash + 1

sgs.ai_ajustdamage_from.baotou = function(self, from, to, card, nature)
	if from and card and package_known(card,"isKindOf","Slash") and not beFriend(to, from)
	then
		return 1
	end
end

sgs.ai_skill_cardask["@baotou-hur"] = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	if package_known(self,"isFriend",target) then return "." end
	if package_known(self,"cantDamageMore",self.player,target) then return "." end
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)
	for _,card in ipairs(cards) do
		if package_known(card,"getSuit") == sgs.Card_Spade then return package_known(card,"getEffectiveId") end
	end
	return "."
end
sgs.ai_cardneed.baotou = sgs.ai_cardneed.slash
sgs.ai_cardneed.juji = sgs.ai_cardneed.slash
sgs.juji_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5.2,
}
sgs.ai_canliegong_skill.juji = function(self, from, to)
	return not package_known(to,"inMyAttackRange",from)
end

sgs.ai_cardneed.qiangpao = sgs.ai_cardneed.slash
function sgs.ai_skill_invoke.jiaohuo(self, data)
	local damage = package_known(data,"toDamage")
	local enemynum = 0
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",damage.to)) do
		if package_known(damage.to,"distanceTo",p) <= 1 and package_known(self,"isEnemy",p) then
			enemynum = enemynum + 1
		end
	end
	if enemynum < 1 then return false end
	return true
end

sgs.ai_skill_playerchosen.jiaohuo = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if package_known(self,"isEnemy",target) then table.insert(tos, target) end
	end

	if #tos > 0 then
		tos = package_known(self,"SortByAtomDamageCount",tos, self.player, sgs.DamageStruct_Fire, nil)
		return tos[1]
	end
end

sgs.ai_playerchosen_intention.jiaohuo = function(self, from, to)
	set_memory(self,"jiaohuo_target",package_known(to,"objectName"))
	sgs.updateIntention(from, to , 10)
end

sgs.ai_view_as.wujijian = function(card, player, card_place)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place ~= sgs.Player_PlaceSpecial and package_known(card,"isRed") and not package_known(card,"isKindOf","Peach") and not package_known(card,"hasFlag","using") then
		return {name="slash",skill="wujijian",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end

local wujijian_skill = {}
wujijian_skill.name = "wujijian"
table.insert(package_skills, wujijian_skill)
wujijian_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)

	local tc_card
	package_call(self,"sortByUseValue",cards, true)
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","TrickCard")
			and not isCard("ExNihilo", card, self.player)
			and (package_known(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive or package_known(clone(self,"slash"),"getTargetModResidue",self.player) > 0) then
			tc_card = card
			break
		end
	end

	if tc_card then
		local suit = package_known(tc_card,"getSuitString")
		local number = package_known(tc_card,"getNumberString")
		local card_id = package_known(tc_card,"getEffectiveId")
		local card_str = ("slash:wujijian[%s:%s]=%d"):format(suit, number, card_id)
		local slash=conversion_clone(self,"slash","wujijian",package_known(tc_card,"getSuit"),package_known(tc_card,"getNumber"),{card_id})

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.wujijian(to, card)
	return package_known(to,"getHandcardNum") < 3 and package_known(card,"isKindOf","TrickCard")
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|wujijian"


local mingxiang_skill = {}
mingxiang_skill.name = "mingxiang"
table.insert(package_skills,mingxiang_skill)
mingxiang_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies<=0 then return end
	return source_skill(self,"#mingxiangCard:.:")
end

sgs.ai_skill_use_func["#mingxiangCard"] = function(card,use,self,request)
	local slashcount = package_known(self,"getCardsNum","Slash")-1
	if slashcount<=0 then return end
	local slash = package_call(self,"getCard","Slash")
	if not slash then return end
	local dummy_use = dummy()
	if slash then package_call(self,"useBasicCard",slash,dummy_use) end
	if not dummy_use.card or package_known(dummy_use.to,"isEmpty") then return end
	use.card = card
end
sgs.ai_use_priority["mingxiangCard"] = sgs.ai_use_priority.Slash+0.1
local huangwu_skill={}
huangwu_skill.name="huangwu"
table.insert(package_skills,huangwu_skill)
huangwu_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local card

	package_call(self,"sortByUseValue",cards,true)

	for _,acard in ipairs(cards) do
		if package_known(acard,"isKindOf","Slash") and (package_known(self,"getDynamicUsePriority",acard) < sgs.ai_use_value.FireAttack or package_known(self,"getOverflow") > 0) then
			if package_known(self,"getCardsNum","Slash") == 1 then
				local keep
				local dummy_use = package_known(self,"aiUseCard",acard, dummy(true))
				if dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length") > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if package_known(p,"getHp") <= 1 then keep = true break end
					end
					if package_known(dummy_use.to,"length") > 1 then keep = true end
				end
				if keep then package_call(self,"setPriorityValue","Slash", package_known(self,"getPriorityValue","FireAttack")+0.1,"legends.huangwu")
				else
					package_call(self,"setPriorityValue","Slash",2.6,"legends.huangwu")
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
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local card_str = ("fire_attack:huangwu[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard=conversion_clone(self,"fire_attack","huangwu",package_known(card,"getSuit"),package_known(card,"getNumber"),{card_id})

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.huangwu = function(to, card, self)
	return package_known(to,"getHandcardNum") >= 2 and package_known(card,"isKindOf","Slash")
end

sgs.ai_skill_invoke.lol_lingti = function(self, data)
	if (package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") + package_known(self.player,"getHp") >= 1) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_to.lol_lingti = function(self, from, to, card, nature)
	if package_known(to,"getStrategyMark","bsyz") > 0
	then
		return -99
	end
end


sgs.ai_skill_invoke.nuhuo = function(self, data)
	if (package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") + package_known(self.player,"getHp") >= 1) then
		return false
	end
	return true
end
local shenghua_skill = {}
shenghua_skill.name = "shenghua"
table.insert(package_skills, shenghua_skill)
shenghua_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyFlag","shenghuaBC") and package_known(self.player,"getStrategyFlag","shenghuaEC") and package_known(self.player,"getStrategyFlag","shenghuaTC") then return end
	return source_skill(self,"#shenghuaCard:.:")
end

sgs.ai_skill_use_func["#shenghuaCard"] = function(card,use,self,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local slashcount = package_known(self,"getCardsNum","Slash")
	if slashcount>0 then
		local slash = package_call(self,"getCard","Slash")
		if slash then
			local dummy_use = package_known(self,"withOwnerRange","slashNoDistanceLimit","shenghua",function()
				return package_known(self,"aiUseCard",slash, dummy(true))
			end)
			if not package_known(dummy_use.to,"isEmpty") then
				for _, p in sgs.qlist(dummy_use.to) do
					if not package_known(self.player,"getStrategyFlag","shenghuaBC") and not package_known(self.player,"inMyAttackRange",p) then
						for _, card in ipairs(cards) do
							if package_known(card,"isKindOf","BasicCard") then
								if package_known(self,"getCardsNum","Slash") > 1 then
									use.card = source_skill(self,"#shenghuaCard:" .. package_known(card,"getId") .. ":")
									return
								elseif not package_known(card,"isKindOf","Slash") then
									use.card = source_skill(self,"#shenghuaCard:" .. package_known(card,"getId") .. ":")
									return
								end
							end
						end
					end
				end

				if not package_known(self.player,"getStrategyFlag","shenghuaTC") then
					for _, card in ipairs(cards) do
						if package_known(card,"isKindOf","TrickCard") then
							use.card = source_skill(self,"#shenghuaCard:" .. package_known(card,"getId") .. ":")
							return
						end
					end
				end

				for _, p in sgs.qlist(dummy_use.to) do
					if package_known(self,"isEnemy",p) and not package_known(self,"cantDamageMore",self.player, p) then
						for _, card in ipairs(cards) do
							if package_known(card,"isKindOf","EquipCard") then
								use.card = source_skill(self,"#shenghuaCard:" .. package_known(card,"getId") .. ":")
								return
							end
						end
					end
				end
			end
		end
	end
end
sgs.ai_use_priority["shenghuaCard"] = sgs.ai_use_priority.Slash + 1

sgs.ai_canliegong_skill.shenghua = function(self, from, to)
	return package_known(from,"getStrategyFlag","shenghuaTCdww")
end

sgs.hit_skill = sgs.hit_skill .. "|shenghua"
sgs.ai_cardneed.shenghua = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.shenghua = function(self, from, to, card, nature)
	if from and card and (package_known(card,"isKindOf","Slash")) and package_known(from,"getStrategyFlag","shenghuaEC")
	then
		return 1
	end
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|jingxi"

sgs.ai_skill_playerchosen.jingxi = function(self, targets)
	local first, second
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets,"defense")
	for _, enemy in ipairs(targets) do
		if not package_known(self,"isFriend",enemy) and package_known(enemy,"isAlive") then
			if package_call(self,"getRoleEstimate",enemy) == "renegade" then second = enemy
			elseif package_call(self,"getRoleEstimate",enemy) ~= "renegade" and not first then first = enemy
			end
		end
	end
	return first or second
end

sgs.ai_skill_invoke.lol_fushi = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = nil
	if package_known(self.player,"objectName") == package_known(damage.from,"objectName") then
		target = damage.to
	elseif package_known(self.player,"objectName") == package_known(damage.to,"objectName") then
		target = damage.from
	end
	if package_known(self,"isFriend",target) then
		return false
	elseif package_known(target,"getHandcardNum") == 0 then
		return false
	end
	return true
end
sgs.ai_use_revises.shenyan = function(self,card,use)
	if package_known(card,"isKindOf","Slash") and package_known(self.player,"getStrategyFlag","shenyantar") then
		package_call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end
sgs.ai_skill_invoke.shenyan = function(self, data)
	if package_known(self.player,"isSkipped",sgs.Player_Play) then return false end
	if package_known(self,"needBear") then return false end
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	package_call(self,"sort",self.enemies,"hp")
	for _,card in ipairs(cards) do
		if package_known(card,"isKindOf","Slash") then
			for _,enemy in ipairs(self.enemies) do
				if package_known(self.player,"canSlash",enemy, card, true) and package_known(self,"slashIsEffective",card, enemy) and package_known(self,"objectiveLevel",enemy) > 3 and package_known(self,"isGoodTarget",enemy, self.enemies, card) then
					if getCardsNum("Jink", enemy) < 1 or package_known(self.player,"getCards","he"):length() > 4 then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
	end
	if (slashtarget) > 0 then
		package_call(self,"speak","shenyan")
		return true
	end
	return false
end

function sgs.ai_cardneed.shenyan(to, card, self)
	local slash_num = 0
	local target
	local slash = clone_native(self,"slash")
	package_call(slash,"deleteLater")
	local cards = visible_hand(self,to)
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s","visible",package_call(self.room,"getCurrent"):objectName(),package_known(to,"objectName"))
		if package_known(c,"hasFlag","visible") or package_known(c,"hasFlag",flag) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end
		end
	end

	package_call(self,"sort",self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if package_known(to,"canSlash",enemy) and not package_known(self,"slashProhibit",slash ,enemy) and package_known(self,"slashIsEffective",slash, enemy) and package_known(self,"getDefenseSlash",enemy) <= 2 then
			target = enemy
			break
		end
	end

	if need_slash and target and isCard("Slash", card, to) then return true end
end

ai_skill_use["@@bihu"]=function(self,prompt,request)
	package_call(self,"sort",self.friends_noself, "handcard")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))

	local equips = {}
	for _, card in sgs.qlist(package_known(self.player,"getHandcards")) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	local ecards = package_known(self.player,"getCards","e")
	ecards = sgs.QList2Table(ecards)

	for _, ecard in ipairs(ecards) do
		if package_known(ecard,"isKindOf","Weapon") or package_known(ecard,"isKindOf","OffensiveHorse") then
			table.insert(equips, ecard)
		end
	end

	if #equips == 0 then return "." end

	local target
	package_call(self,"sort",self.friends,"defense")
	local lord = package_call(self.room,"getLord")
	if lord and package_known(self,"isFriend",lord) and not package_known(self,"isLordHealthy") and not package_known(self.player,"isLord") and not hasBuquEffect(lord)
		and not (package_known(lord,"getHp") >= getBestHp(lord) and package_known(lord,"getHp") > 1) then
			target = lord
	else
		for _, friend in ipairs(self.friends) do
			if package_known(self,"isWeak",friend) and not hasBuquEffect(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		return response_skill(self,"#bihuCard",{package_known(equips[1],"getId")},{package_known(target,"objectName")},request)
	end
	return "."
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|bihu"
sgs.ai_cardneed.bihu = sgs.ai_cardneed.equip


sgs.ai_ajustdamage_to["@bihu"] = function(self, from, to, card, nature)
	if package_known(to,"getStrategyMark","@bihu") > 0
	then
		return -99
	end
end
sgs.ai_ajustdamage_from.langke = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","@lang") >= 4 and not beFriend(to,from)
	then
		return 1
	end
end



sgs.ai_skill_invoke["langkea"] = true
sgs.ai_skill_invoke["langkeb"] = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	local from = damage.from
	if package_known(self,"isFriend",target) then
		return false
	elseif package_known(self,"cantDamageMore",from,target) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.fengbi = function(self, from, to, card, nature)
	if (package_known(from,"getStrategyMark","feng") > 0 or (card and package_known(card,"hasFlag","fengbiSlash")))
	then
		return 1
	end
end
sgs.ai_cardneed.fengbi = sgs.ai_cardneed.slash

function sgs.ai_cardsview.chongfeng(self,class_name,player)
	local slash = clone(self,"slash")
	package_call(slash,"setSkillName","chongfeng")
	local newcards = {}
	for _,c in sgs.list(owner_ai(self,player):addHandPile())do do
		if isCard("ExNihilo",c,player) and package_known(player,"getPhase")<=sgs.Player_Play
		or isCard("Peach",c,player) then goto package_continue_2 end
		if isCard("Slash",c,player) then return end
		table.insert(newcards,c)
	end ::package_continue_2:: end
	owner_ai(self,player):sortByKeepValue(newcards,nil,true)
	local use_cards = {}
	for _,h in sgs.list(newcards)do
		for _,h2 in sgs.list(newcards)do do
			if package_known(h,"getEffectiveId") == package_known(h2,"getEffectiveId") or table.contains(use_cards, package_known(h,"getEffectiveId"))  then goto package_continue_3 end
			if package_known(h,"getSuit") == package_known(h2,"getSuit") then
				if package_known(slash,"subcardsLength")<2	then
					table.insert(use_cards,package_known(h,"getEffectiveId"))
					package_call(slash,"addSubcard",h)
				end
			end
		end ::package_continue_3:: end
	end
	if package_known(slash,"subcardsLength")>=2
	then return proposal(self,slash) end
end
local chongfeng_skill = {}
chongfeng_skill.name = "chongfeng"
table.insert(package_skills, chongfeng_skill)
chongfeng_skill.getTurnUseCard = function(self,inclusive,request)
	local first_found, second_found = false, false
	local first_card, second_card
	if package_known(self.player,"getHandcardNum") >= 2 then
		local cards = package_known(self.player,"getHandcards")
		local same_suit = false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player)) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and package_known(scard,"getSuit") == package_known(first_card,"getSuit")
						and not (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player)) then

						local card_str = ("slash:chongfeng[%s:%s]=%d+%d"):format("to_be_decided", 0, package_known(first_card,"getId"), package_known(scard,"getId"))
						local slash=conversion_clone(self,"slash","chongfeng",sgs.Card_NoSuit,0,{package_known(first_card,"getId"),package_known(scard,"getId")})
						local dummy_use = package_known(self,"aiUseCard",slash, dummy())
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = package_known(first_card,"getId")
		local second_id = package_known(second_card,"getId")
		local card_str = ("slash:chongfeng[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local slash=conversion_clone(self,"slash","chongfeng",sgs.Card_NoSuit,0,{first_id,second_id})
		assert(slash)

		return slash
	end
end

sgs.ai_skill_invoke.wuwei = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = nil
	if package_known(self.player,"objectName") == package_known(damage.from,"objectName") then
		target = damage.to
	elseif package_known(self.player,"objectName") == package_known(damage.to,"objectName") then
		target = damage.from
	end
	if package_known(self,"isFriend",target) then
		return false
	elseif package_known(target,"hasSkill","wushuang") or package_known(target,"hasSkill","wuyan") or package_known(target,"hasSkill","noswuyan") then
		return false
	elseif package_known(target,"hasSkill","wujijian") or package_known(target,"hasSkill","wuhun") or package_known(target,"hasSkill","duanchang") then
		return false
	elseif package_known(self,"getCardsNum","Slash", self.player) <= 1 then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@wuweidis"] = function(self, data, pattern)
	local target = package_call(data,"toPlayer")
	if not target then return "." end
	local hcards = package_known(self.player,"getCards","h")
	hcards = sgs.QList2Table(hcards)
	package_call(self,"sortByUseValue",hcards, true)
	local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
		package_call(duel,"setSkillName","wuwei")
		package_call(duel,"deleteLater")
	for _, hcard in ipairs(hcards) do
		local dummy_use = package_known(self,"aiUseCard",duel, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
		if dummy_use.card and package_known(dummy_use.to,"contains",target) then
			return package_known(hcard,"getEffectiveId")
		end
	end
	return "."
end

ai_skill_use["@@zhouchu"]=function(self,prompt,request)
	local zhouchu_target = nil
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self.player,"canSlash",p, nil, false) and package_known(self.player,"inMyAttackRange",p) then
			package_call(targets,"append",p)
		end
	end
	if package_known(targets,"length") == 0 then return "." end
	zhouchu_target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
	if not zhouchu_target then return "." end
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) and package_known(self,"isFriend",zhouchu_target)) then
			return response_skill(self,"#zhouchuCard",{package_known(card,"getEffectiveId")},{package_known(zhouchu_target,"objectName")},request)
		end
	end
	return "."
end

sgs.ai_card_intention.zhouchuCard = sgs.ai_card_intention.Slash

sgs.ai_need_damaged.zhouchu = function(self, attacker, player)
	if not package_known(player,"hasSkill","zhouchu") then return false end
	local peaches = getCardsNum("Peach", player)
	if peaches >= package_known(player,"getLostHp") and peaches > 0 then return true end
	if package_known(self.player,"objectName") == package_known(player,"objectName") and package_known(player,"getHp") > 1 then
		local slash = clone_native(self,"Slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		for _, target in ipairs(self.enemies) do
			if package_known(self,"isEnemy",target) and package_known(self,"slashIsEffective",slash, target) and not package_known(self,"needToLoseHp",target, self.player,slash)
				and getCardsNum("Jink", target, self.player) < 1 and (package_known(target,"getHp") == 1 or package_known(self,"hasHeavyDamage",player, slash, target) and package_known(target,"getHp") == 2) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.juewang = function(self, data)
	package_call(self,"sort",self.friends, "hp")
	package_call(self,"sort",self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (package_known(friend,"isWounded") and 10 or 0)
		if package_known(self,"hasSkills",sgs.masochism_skill, friend) then
			down = down - 5
			if package_known(friend,"isWounded") then up = up + 5 end
		end
		if package_known(self,"needToLoseHp",friend, nil, nil, true) then down = down + 5 end
		if package_known(self,"needToLoseHp",friend, nil, nil, true, true) and package_known(friend,"isWounded") then up = up - 5 end

		if package_known(self,"isWeak",friend) then
			if package_known(friend,"isWounded") then up = up + 10 + (package_known(friend,"isLord") and 20 or 0) end
			down = down - 10 - (package_known(friend,"isLord") and 40 or 0)
			if package_known(friend,"getHp") <= 1 and not package_known(friend,"hasSkill","buqu") or package_known(friend,"getPileCount","buqu") > 4 then
				down = down - 20 - (package_known(friend,"isLord") and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (package_known(enemy,"isWounded") and 10 or 0)
		if package_known(self,"hasSkills",sgs.masochism_skill, enemy) then
			down = down + 10
			if package_known(enemy,"isWounded") then up = up - 10 end
		end
		if package_known(self,"needToLoseHp",enemy, nil, nil, true) then down = down - 5 end
		if package_known(self,"needToLoseHp",enemy, nil, nil, true, true) and package_known(enemy,"isWounded") then up = up - 5 end

		if package_known(self,"isWeak",enemy) then
			if package_known(enemy,"isWounded") then up = up - 10 end
			down = down + 10
			if package_known(enemy,"getHp") <= 1 and not package_known(enemy,"hasSkill","buqu") then
				down = down + 10 + ((package_known(enemy,"isLord") and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 then
		return true
	elseif up > 0 then
		return false
	end
	return true
end
sgs.ai_skill_cardask["@juewangdis"] = function(self, data, pattern, target)
	if hasZhaxiangEffect(self.player) then return "." end
	if not package_known(self,"needToLoseHp",self.player, nil, nil, true) then
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		package_call(self,"sortByKeepValue",cards)
		for _, card in ipairs(cards) do
			return package_known(card,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_skill_invoke.shihuo = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	local from = damage.from
	if package_known(self,"isFriend",target) then
		return false
	elseif not package_known(damage.to,"faceUp") then
		return false
	elseif package_known(self,"damageIsEffective",damage.to, sgs.DamageStruct_Fire) then
		return not package_known(self,"cantDamageMore",self.player, damage.to) and package_known(self,"toTurnOver",damage.to,0,"shihuo")
	end
	return false
end
sgs.ai_ajustdamage_from.shihuo = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","@huo") >= 4 and not beFriend(to, from)
	then
		return 1
	end
end
function sgs.ai_cardneed.shihuo(to,card)
	return package_known(card,"getTypeId")==sgs.Card_TypeTrick
end

sgs.ai_view_as.quexie = function(card, player, card_place)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place ~= sgs.Player_PlaceSpecial and package_known(card,"getSuit") == sgs.Card_Diamond and not package_known(card,"hasFlag","using") then
		return {name="slash",skill="quexie",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end

local quexie_skill = {}
quexie_skill.name = "quexie"
table.insert(package_skills, quexie_skill)
quexie_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)

	local tc_card
	package_call(self,"sortByUseValue",cards, true)
	for _, card in ipairs(cards) do
		if package_known(card,"getSuit") == sgs.Card_Diamond
			and (package_known(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive) then
			tc_card = card
			break
		end
	end

	if tc_card then
		local suit = package_known(tc_card,"getSuitString")
		local number = package_known(tc_card,"getNumberString")
		local card_id = package_known(tc_card,"getEffectiveId")
		local card_str = ("slash:quexie[%s:%s]=%d"):format(suit, number, card_id)
		local slash=conversion_clone(self,"slash","quexie",package_known(tc_card,"getSuit"),package_known(tc_card,"getNumber"),{card_id})

		assert(slash)
		return slash
	end
end

sgs.ai_skill_playerchosen.quexie     = function(self, targets)
	local arr1, arr2 = package_call(self,"getWoundedFriend",false, true)
	local target = self.player

	if #arr1 > 0 and (package_known(self,"isWeak",arr1[1])) and package_known(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if package_known(friend,"getHp") < getBestHp(friend) then
				return friend
			end
		end
	end


	return nil
end

sgs.ai_card_priority.quexie = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "quexie")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end
function sgs.ai_cardneed.quexie(to, card)
	return package_known(to,"getHandcardNum") < 3 and package_known(card,"getSuit") == sgs.Card_Diamond
end

local xieli_skill = {}
xieli_skill.name = "xieli"
table.insert(package_skills,xieli_skill)
xieli_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.friends_noself<=0 then return end
	return source_skill(self,"#xieliCard:.:")
end

sgs.ai_skill_use_func["#xieliCard"] = function(card,use,self,request)
	local target
	package_call(self,"sort",self.friends,"defense")
	local AssistTarget = package_call(self,"AssistTarget")
	if AssistTarget then target = AssistTarget end
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			target = friend
			break
		end
	end
	if target then
		use.card = card
		if use.to then
			package_call(use.to,"append",target)
		end
	end
end

sgs.ai_skill_invoke.xieli = function(self, data)
	local asked = package_known(data,"toStringList")
	if xieli_source(self) then return false end
	return true
end

sgs.ai_choicemade_filter.skillInvoke.xieli = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		set_memory(self,"xielisource",package_known(player,"objectName"))
	end
end


sgs.ai_choicemade_filter.cardResponded["@xieli-jink"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		sgs.updateIntention(player, xieli_source(self), -80)
		set_memory(self,"xielisource",false)
	end
end

sgs.ai_skill_cardask["@xieli-jink"] = function(self)
	if not package_call(self.room,"getLord") then return "." end
	if not xieli_source(self) then return "." end
	if not package_known(self,"isFriend",xieli_source(self)) then return "." end
	if package_known(self,"needBear") then return "." end
	local bgm_zhangfei = package_call(self.room,"findPlayerBySkillName","dahe")
	if bgm_zhangfei and package_known(bgm_zhangfei,"isAlive") and xieli_source(self):hasFlag("dahe") then
		for _, card in ipairs(package_known(self,"getCards","Jink")) do
			if package_known(card,"getSuit") == sgs.Card_Heart then
				return response_value(self,card)
			end
		end
		return "."
	end
	return package_known(self,"getCardId","Jink") or "."
end

sgs.ai_choicemade_filter.cardResponded["@xieli-slash"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		sgs.updateIntention(player, xieli_source(self), -80)
		set_memory(self,"xielisource",false)
	end
end

sgs.ai_skill_cardask["@xieli-slash"] = function(self, data)
	if not xieli_source(self) or not package_known(self,"isFriend",xieli_source(self)) then return "." end
	if package_known(self,"needBear") then return "." end

	local xielitargets = {}
	for _, player in sgs.qlist(package_known(self.room,"getAllPlayers")) do
		if package_known(player,"getStrategyMark","@xieli") > 0 then
			if package_known(self,"isFriend",player) and not (package_known(self,"needToLoseHp",player, xieli_source(self), nil)) then return "." end
			table.insert(xielitargets, player)
		end
	end

	if #xielitargets == 0 then
		return package_known(self,"getCardId","Slash") or "."
	end

	package_call(self,"sort",xielitargets, "defenseSlash")
	local slashes = package_known(self,"getCards","Slash")
	for _, slash in ipairs(slashes) do
		for _, target in ipairs(xielitargets) do
			if not package_known(self,"slashProhibit",slash, target, xieli_source(self)) and package_known(self,"slashIsEffective",slash, target, xieli_source(self)) then
				return response_value(self,slash)
			end
		end
	end
	return "."
end

function sgs.ai_cardsview_valuable.xielidest(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	if package_known(player,"getPhase") ~= sgs.Player_NotActive then return end
	if package_known(player,"getStrategyFlag","xieli_using") then return end
	if package_known(player,"getStrategyFlag","Global_xieliFailed") then return end
	return skill_proposal("#xielidestCard",{},name)
end
sgs.ai_choicemade_filter["xielidestCard"] = function(self,player,carduse)
	set_memory(self,"xielisource",package_known(player,"objectName"))
end

sgs.ai_skill_cardask["@@xieli"] = function(self, data, pattern)
    local target = package_call(data,"toPlayer")
    if target and package_known(self,"isFriend",target) then
        local cards = package_known(self.player,"getCards","he")
        cards = sgs.QList2Table(cards)
        package_call(self,"sortByKeepValue",cards)
        for _,h in sgs.list(cards)do
            if package_known(self,"matchesDiscardPattern",pattern,h)
            then return package_known(h,"getEffectiveId") end
            if package_known(h,"isKindOf",pattern)
            then return package_known(h,"getEffectiveId") end
        end
        return package_known(self,"getCardId",pattern)
    end
    return "."
end

sgs.ai_choicemade_filter.cardResponded["@@xieli"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		if not xieli_source(self) then return end
		sgs.updateIntention(player, xieli_source(self), -80)
		set_memory(self,"xielisource",false)
	end
end

sgs.ai_ajustdamage_from.cangfei  = function(self, from, to, card, nature)
	if to and package_known(to,"getStrategyMark","@fei") > 0 and card and package_known(card,"isKindOf","Slash") then
		return 1
	end
end
local huanyin_skill = {}
huanyin_skill.name = "huanyin"
table.insert(package_skills, huanyin_skill)
huanyin_skill.getTurnUseCard = function(self,inclusive,request)
	local target
	local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
	package_call(duel,"deleteLater")
	local dummy = package_known(self,"aiUseCard",duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end

	if target then
		return source_skill(self,"#huanyinCard:.:")
	else
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		local dummy = package_known(self,"aiUseCard",slash)
		if dummy.card and dummy.to
			then
			for _,enemy in sgs.list(dummy.to)do
				target = enemy
				break
			end
		end
		if target then
			return source_skill(self,"#huanyinCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#huanyinCard"] = function(card,use,self,request)
	local target
	local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
	package_call(duel,"deleteLater")
	local dummy = package_known(self,"aiUseCard",duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end

	if target then
		use.card = card
		if use.to then
			package_call(use.to,"append",target)
		end
	else
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		local dummy = package_known(self,"aiUseCard",slash)
		if dummy.card and dummy.to
			then
			for _,enemy in sgs.list(dummy.to)do
				target = enemy
				break
			end
		end
		if target then
			use.card = card
			if use.to then
				package_call(use.to,"append",target)
			end
		end
	end
end
sgs.ai_skill_choice.huanyinCard = function(self, choices, data)
	local target = package_call(data,"toPlayer")
	local items = package_known(choices,"split","+")
	if table.contains(items, "duel") then
		local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
		package_call(duel,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",duel, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
		if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) and package_known(target,"getStrategyMark","@cang") > 0 and package_known(self.player,"hasSkill","cangfei") then
			return "duel"
		end
	end
	if table.contains(items, "slash") then
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",slash, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
		if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) and package_known(target,"getStrategyMark","@fei") > 0 and package_known(self.player,"hasSkill","cangfei") then
			return "slash"
		end
	end
	if table.contains(items, "duel") then
		local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
		package_call(duel,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",duel, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
		if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
			return "duel"
		end
	end
	if table.contains(items, "slash") then
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",slash, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
		if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
			return "slash"
		end
	end
	return items[math.random(1, #items)]
end


local shixue_skill = {}
shixue_skill.name= "shixue"
table.insert(package_skills,shixue_skill)
shixue_skill.getTurnUseCard=function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","shixueCard") then
		return source_skill(self,"#shixueCard:.:")
	end
end
sgs.ai_skill_use_func["#shixueCard"] = function(card,use,self,request)
	local spadecard, cards
	cards = package_known(self.player,"getCards","he")
	for _, card in sgs.qlist(cards) do
		if package_known(card,"getSuit") == sgs.Card_Spade then
			spadecard = card
			break
		end
	end
	package_call(self,"sort",self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy) then
			if spadecard then
				use.card = source_skill(self,"#shixueCard:" .. package_known(spadecard,"getId").. ":")
				if use.to then
					package_call(use.to,"append",enemy)
				end
				break
			end
		end
	end
end
sgs.ai_use_value["shixueCard"] = 5.5
sgs.ai_card_intention["shixueCard"] = 80
sgs.dynamic_value.damage_card["shixueCard"] = true
sgs.shixue_keep_value = {
	Peach = 6,
	Jink = 5.1,
	OffensiveHorse = 5
}
sgs.shixue_suit_value = {
	spade = 5,
}

sgs.ai_ajustdamage_from.ningshi = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Slash") and not beFriend(to, from)
	then
		return 1
	end
end
sgs.ai_skill_invoke.ningshi = function(self, data)
	local damage = package_known(data,"toDamage")
	if damage and damage.to and package_known(self,"isEnemy",damage.to) then
		if package_known(self,"isWeak",self.player) then return false end
		if package_known(self,"damageIsEffective",damage.to, sgs.card_damage_nature[package_known(damage.card,"getClassName")]) then
			return not package_known(self,"cantDamageMore",self.player, damage.to)
		end
		if package_known(self,"isWeak",damage.to) then return true end
		if package_known(self.player,"getHp") > getBestHp(self.player) then return true end
	end
	return false
end
sgs.ai_cardneed.ningshi = sgs.ai_cardneed.slash

local yongbao_skill = {}
yongbao_skill.name= "yongbao"
table.insert(package_skills,yongbao_skill)
yongbao_skill.getTurnUseCard=function(self,inclusive,request)
	return source_skill(self,"#yongbaoCard:.:")
end

sgs.ai_skill_use_func["#yongbaoCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"objectiveLevel",enemy)>3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy)
		and package_known(self.player,"distanceTo",enemy)<=package_known(self.player,"getAttackRange") and package_known(self.player,"getStrategyMark","@yongbao")>=package_known(enemy,"getHp") and not package_known(self,"cantDamageMore",self.player,enemy)
		then
			use.card = source_skill(self,"#yongbaoCard:.:")
			package_call(use.to,"append",enemy)
			return
		end
	end
end

sgs.ai_use_value["yongbaoCard"] = 2.5
sgs.ai_card_intention["yongbaoCard"] = 80
sgs.dynamic_value.damage_card["yongbaoCard"] = true

local cannue_skill = {}
cannue_skill.name = "cannue"
table.insert(package_skills, cannue_skill)
cannue_skill.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#cannueCard:.:")
end

sgs.ai_skill_use_func["#cannueCard"] = function(card,use,self,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local slashcount = package_known(self,"getCardsNum","Slash")
	if slashcount>0 then
		local slash = package_call(self,"getCard","Slash")
		if slash then
			local dummy_use = package_known(self,"aiUseCard",slash, dummy(true))
			if not package_known(dummy_use.to,"isEmpty") then
				for _, p in sgs.qlist(dummy_use.to) do
					if package_known(self,"isEnemy",p) and not package_known(self,"cantDamageMore",self.player, p) and (getCardsNum("Jink", p, self.player) < 1 or package_known(self,"canLiegong",p, self.player)) then
						local to_use = {}
						for _, card in ipairs(cards) do
							if package_known(self,"getUseValue",card) < 5 then
								table.insert(to_use, package_known(card,"getId"))

							end
						end
						if package_known(self,"needToThrowArmor",self.player) then table.insert(to_use, package_call(self.player,"getArmor"):getId()) end
						if #to_use > 0 then
							use.card = source_skill(self,"#cannueCard:"..table.concat(to_use, "+") ..":")
							return
						end
					end
				end
			end
		end
	end
end
sgs.ai_use_priority["cannueCard"] = sgs.ai_use_priority.Slash + 1
sgs.ai_ajustdamage_from.cannue = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Slash")
	then
		return package_known(from,"getStrategyMark","cannue")
	end
end
sgs.ai_skill_playerchosen.manheng = sgs.ai_skill_playerchosen.zero_card_as_slash

local lumang_skill = {}
lumang_skill.name= "lumang"
table.insert(package_skills,lumang_skill)
lumang_skill.getTurnUseCard=function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","lumangCard") then
		return source_skill(self,"#lumangCard:.:")
	end
end
sgs.ai_skill_use_func["#lumangCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy) then
			if package_known(self.player,"distanceTo",enemy) <= package_known(self.player,"getAttackRange") and package_known(self.player,"getHp") <= package_known(enemy,"getHp") and package_known(self.player,"getHp") > 1 and (not package_known(self,"cantDamageMore",self.player, enemy) or package_known(self.player,"getStrategyMark","huanghun") == 0) then
				use.card = source_skill(self,"#lumangCard:.:")
				if use.to then
					package_call(use.to,"append",enemy)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy) then
			if package_known(self.player,"distanceTo",enemy) <= package_known(self.player,"getAttackRange") and package_known(self.player,"getHp") <= package_known(enemy,"getHp") and package_known(self.player,"getHp") > 1 then
				use.card = source_skill(self,"#lumangCard:.:")
				if use.to then
					package_call(use.to,"append",enemy)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy) then
			if package_known(self.player,"distanceTo",enemy) <= package_known(self.player,"getAttackRange") and package_known(self.player,"getHp") > 1 then
				use.card = source_skill(self,"#lumangCard:.:")
				if use.to then
					package_call(use.to,"append",enemy)
				end
				return
			end
		end
	end
end
sgs.ai_use_value["lumangCard"] = 2.5
sgs.ai_card_intention["lumangCard"] = 80
sgs.dynamic_value.damage_card.lumangCard = true
sgs.lumang_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 4
}

sgs.ai_skill_invoke.huanghun = function(self, data)
	if package_known(self.player,"getJudgingArea"):length() > 1 or package_known(self,"isWeak") then return true end
	if ((package_known(self.player,"containsTrick","supply_shortage") and package_known(self.player,"getHp") > package_known(self.player,"getHandcardNum") and package_known(self.player,"getHp") <= 2) or
		(package_known(self.player,"containsTrick","indulgence") and package_known(self.player,"getHandcardNum") > package_known(self.player,"getHp")-1)) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.Thornmail = function(self, data)
	local mode = package_known(self.room,"getMode")
	if package_known(mode,"find","_mini_41") or package_known(mode,"find","_mini_46") then return true end
	local damage = package_known(data,"toDamage")
	if package_known(self,"needToLoseHp",damage.from, self.player,nil) then
		if package_known(self,"isFriend",damage.from) then
			set_thornmail(self,string.format("%s_%s_%d", package_known(self.player,"objectName"), package_known(damage.from,"objectName"), turn_count(self)))
			return true
		end
		return false
	end
	return not package_known(self,"isFriend",damage.from) and package_known(self,"canAttack",damage.from)
end











local function Thornmail_discard(self, discard_num, min_num, optional, include_equip, skillName)
	local Thornmail = source_error("Thornmail.Room_getArmor"):isKindOf("Thornmail")
	if Thornmail and (not package_known(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, Thornmail)) then return {} end
	if Thornmail and package_known(self,"needToLoseHp",self.player, Thornmail) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and package_known(self,"getOverflow") <= 0 then return {} end
	package_call(self,"sortByKeepValue",cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not package_known(self.player,"isJilei",card) then
			table.insert(to_discard, package_known(card,"getEffectiveId"))
			table.remove(cards, i)
			index = index + 1
			if index == 2 then break end
		end
	end
	if #to_discard < 2 then return {}
	else
		return to_discard
	end
end

sgs.ai_skill_discard.Thornmail = function(self, discard_num, min_num, optional, include_equip)
	return Thornmail_discard(self, discard_num, min_num, optional, include_equip, "Thornmail")
end








sgs.ai_choicemade_filter.skillInvoke.Thornmail = function(self, player, promptlist)
	local damage = source_fact(self,"CurrentDamageStruct","toDamage")
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not package_known(self,"needToLoseHp",damage.from, player) then
				sgs.updateIntention(damage.to, damage.from, 40)
			end
		elseif package_known(self,"canAttack",damage.from) then
			sgs.updateIntention(damage.to, damage.from, -40)
		end
	end
end

sgs.ai_skill_invoke.WarmongArmor = function(self, data)
	if package_known(self.player,"getHp") > 2 and package_known(self.player,"getHandcardNum") < 2 then
		return false
	end
	return true
end

sgs.ai_skill_invoke.zhimang = function(self, data)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	local from = damage.from
	if package_known(self,"isFriend",target) then
		return false
	end
	return true
end
local mogu_skill= {}
mogu_skill.name = "mogu"
table.insert(package_skills, mogu_skill)
mogu_skill.getTurnUseCard          = function(self,inclusive,request)
	local source = self.player
	if not (package_known(source,"getHandcardNum") >= 2 or package_known(source,"getHandcardNum") > package_known(source,"getHp")) then return end

	if package_known(source,"hasUsed","#moguCard") then return end
	return source_skill(self,"#moguCard:.:")
end

sgs.ai_skill_use_func["#moguCard"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards, true)
	local needed = {}
	local suit = {}
	for _, acard in ipairs(cards) do do
		if package_known(self.player,"getPile","muthroom"):length() > 0 then
			for _,card_id in sgs.qlist(package_known(self.player,"getPile","muthroom")) do do
				if package_known(acard,"getSuit") == package_known(self,"getKnownCardById",card_id):getSuit() or table.contains(suit, package_known(acard,"getSuitString")) then goto package_continue_4 end
				table.insert(needed, package_known(acard,"getEffectiveId"))
				table.insert(suit, package_known(acard,"getSuitString"))
			end ::package_continue_4:: end
		else
			if table.contains(suit, package_known(acard,"getSuitString")) then goto package_continue_5 end
			table.insert(needed, package_known(acard,"getEffectiveId"))
			table.insert(suit, package_known(acard,"getSuitString"))
		end
	end ::package_continue_5:: end
	if #needed > 0 then
		use.card = source_skill(self,"#moguCard:" .. table.concat(needed, "+") .. ":")
		return
	end
end
sgs.ai_skill_invoke["moguhit"] = function(self, data)
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) then
		return false
	end
	return (package_known(self,"damageIsEffective",target, sgs.DamageStruct_Normal, self.player) and not package_known(self,"cantbeHurt",target, self.player)) and package_known(self,"canDamage",target,self.player,nil)
end
sgs.ai_cardneed.tengyun = sgs.ai_cardneed.slash
sgs.ai_cardneed.jingang = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.jingang = function(self, data)
	local damage = package_known(data,"toDamage")
	if package_known(self,"hasSkills",sgs.lose_equip_skill, damage.to) then
		return package_known(self,"isFriend",damage.to) and not package_known(self,"isWeak",damage.to)
	end
	local benefit = (package_call(damage.to,"getArmor") and package_known(self,"needToThrowArmor",damage.to))
	if package_known(self,"isFriend",damage.to) then return benefit end
	return not benefit
end
sgs.ai_skill_choice.jingang = function(self, choices)
	return "movearmor"
end

sgs.ai_cardneed.moying = sgs.ai_cardneed.bignumber
ai_skill_use["@@moying"]=function(self,prompt,request)
	if #self.enemies > 0 then
		local mymaxcard = package_call(self,"getMaxCard")
		if mymaxcard then
			local mymaxpoint = package_known(mymaxcard,"getNumber")
			package_call(self,"sort",self.enemies, "handcard")
			self.enemies = sgs.reverse(self.enemies)
			local targets = {}
			for _,enemy in ipairs(self.enemies) do
				if not package_known(enemy,"isKongcheng") then
					local maxcard = package_call(self,"getMaxCard",enemy)
					local maxpoint = maxcard and package_known(maxcard,"getNumber") or 4
					if mymaxpoint > maxpoint then
						table.insert(targets, enemy)
					end
				end
			end
			local target = nil
			if #targets > 0 then
				for _,enemy in ipairs(targets) do
					if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) then
						if not package_known(self,"cantbeHurt",enemy) then
							target = enemy
							break
						end
					end
				end
				target = target or self.enemies[#self.enemies]
			end
			if target then
				local card_str = "#moyingCard:"..package_known(mymaxcard,"getEffectiveId")..":->"..package_known(target,"objectName")
				return response_skill(self,"#moyingCard",{package_known(mymaxcard,"getEffectiveId")},{package_known(target,"objectName")},request)
			end
		end
	end
	return "."
end

local mengyan_skill = {}
mengyan_skill.name = "mengyan"
table.insert(package_skills, mengyan_skill)
mengyan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@mengyan") < 1 then return end
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not (package_known(enemy,"hasSkill","kongcheng") and package_known(enemy,"isKongcheng")) and package_known(self,"isWeak",enemy) and package_known(self,"damageMinusHp",enemy, 1) > 0
			and #self.enemies > 1 then
			package_call(self,"setPriorityValue","mengyanCard",8,"legends.mengyan")
			return source_skill(self,"#mengyanCard:.:")
		end
	end
end
sgs.ai_skill_use_func["#mengyanCard"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority["mengyanCard"] = sgs.ai_use_priority.Slash + 0.1
local lol_jiushu_skill = {}
lol_jiushu_skill.name= "lol_jiushu"
table.insert(package_skills,lol_jiushu_skill)
lol_jiushu_skill.getTurnUseCard=function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","lol_jiushuCard") then
		return source_skill(self,"#lol_jiushuCard:.:")
	end
end
sgs.ai_skill_use_func["#lol_jiushuCard"] = function(card,use,self,request)
	package_call(self,"sort",self.friends_noself, "hp")
	for _,friend in ipairs(self.friends_noself) do
		if package_known(self.player,"getHp") > package_known(friend,"getHp") and package_known(self.player,"getHp") > 1 then
			use.card = source_skill(self,"#lol_jiushuCard:.:")
			if use.to then
				package_call(use.to,"append",friend)
			end
			return
		end
	end
end
sgs.ai_use_value["lol_jiushuCard"] = 2.5
sgs.ai_card_intention["lol_jiushuCard"] = -80
sgs.ai_use_priority["lol_jiushuCard"] = 3
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lol_jiushu"
local guanzhu_skill = {}
guanzhu_skill.name= "guanzhu"
table.insert(package_skills,guanzhu_skill)
guanzhu_skill.getTurnUseCard=function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","guanzhuCard") then
		return source_skill(self,"#guanzhuCard:.:")
	end
end
sgs.ai_skill_use_func["#guanzhuCard"] = function(card,use,self,request)
	package_call(self,"sort",self.friends_noself, "hp")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local card
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Heart then
			card = c
			break
		end
	end
	if card then
		for _,friend in ipairs(self.friends_noself) do
			if package_known(self,"canDraw",friend, self.player) then
				use.card = source_skill(self,"#guanzhuCard:".. package_known(card,"getId")..":")
				if use.to then
					package_call(use.to,"append",friend)
				end
				return
			end
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Spade then
			card = c
			break
		end
	end
	if card and package_known(card,"getSuit") == sgs.Card_Spade then
		for _,enemy in ipairs(self.enemies) do
			if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and not package_known(self,"cantbeHurt",enemy) and package_known(self,"objectiveLevel",enemy) > 3  and package_known(self,"canDamage",enemy,self.player,nil) then
				use.card = source_skill(self,"#guanzhuCard:".. package_known(card,"getId")..":")
				if use.to then
					package_call(use.to,"append",enemy)
				end
				return
			end
		end
	end
	if package_known(self,"getOverflow") > 0 then
		for _, c in ipairs(cards) do
			for _,friend in ipairs(self.friends_noself) do
				if package_known(self,"canDraw",friend, self.player) then
					use.card = source_skill(self,"#guanzhuCard:".. package_known(c,"getId")..":")
					if use.to then
						package_call(use.to,"append",friend)
					end
					return
				end
			end
		end
	end
end
sgs.ai_use_priority["guanzhuCard"] = 2
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|guanzhu"
local lol_qiyuan_skill= {}
lol_qiyuan_skill.name = "lol_qiyuan"
table.insert(package_skills, lol_qiyuan_skill)
lol_qiyuan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@lol_qiyuan_l") < 1 then return end
	if (#self.friends <= #self.enemies and turn_count(self) > 2 and package_known(self.player,"getLostHp") > 0) or (turn_count(self) > 1 and package_known(self,"isWeak")) then
		return source_skill(self,"#lol_qiyuanCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_qiyuanCard"] = function(card,use,self,request)
	use.card = card
	for i = 1, #self.friends do
		if use.to then package_call(use.to,"append",self.friends[i]) end
	end
end
sgs.ai_card_intention["lol_qiyuanCard"] = -80
sgs.ai_use_priority["lol_qiyuanCard"] = 9.31
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lol_qiyuan"


sgs.ai_skill_invoke.lol_nuhuo = function(self, data)
	local peaches = 1 - package_known(self.player,"getHp")

	return package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") < peaches
end
sgs.ai_can_damagehp.lol_nuhuo = function(self, from, card, to)
	if package_known(to,"getStrategyMark","wjnh") > 0 and package_known(self,"canLoseHp",from, card, to) then return true end
end

sgs.ai_getBestHp_skill.lol_nuhuo = function(owner)
	if package_known(owner,"getStrategyMark","wjnh") > 0 and package_known(owner,"getPhase") == sgs.Player_NotActive then
		return 0
	end
end

sgs.ai_hasBuquEffect_skill.lol_nuhuo = function(player)
	return package_known(player,"getStrategyMark","wjnh") > 0 or package_known(player,"getStrategyMark","@lol_nuhuo") > 0
end

sgs.ai_cardneed.kuangnu = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.kuangnu = function(self, from, to, card, nature)
	if package_known(from,"getLostHp") >= 3  and card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel"))
	then
		return 1
	end
end
sgs.ai_canliegong_skill.kuangnu = function(self, from, to)
	return package_known(from,"getLostHp") >= 4
end

sgs.ai_getBestHp_skill.kuangnu = function(owner)
	return package_known(owner,"getMaxHp") - 1
end


local shabing_skill= {}
shabing_skill.name = "shabing"
table.insert(package_skills, shabing_skill)
shabing_skill.getTurnUseCard          = function(self,inclusive,request)
	local source = self.player
	if not (package_known(source,"getHandcardNum") >= 2 or package_known(source,"getHandcardNum") > package_known(source,"getHp")) then return end

	if package_known(source,"hasUsed","#shabingCard") then return end
	return source_skill(self,"#shabingCard:.:")
end

sgs.ai_skill_use_func["#shabingCard"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards, true)
	local needed = {}
	local suit = {}
	for _,card_id in sgs.qlist(package_known(self.player,"getPile","soldier")) do do
		if table.contains(suit, package_known(self,"getKnownCardById",card_id):getSuitString()) then goto package_continue_6 end
		table.insert(suit, package_known(self,"getKnownCardById",card_id):getSuitString())
	end ::package_continue_6:: end
	for _, acard in ipairs(cards) do do
		if table.contains(suit, package_known(acard,"getSuitString")) then goto package_continue_7 end
		table.insert(needed, package_known(acard,"getEffectiveId"))
		table.insert(suit, package_known(acard,"getSuitString"))
	end ::package_continue_7:: end
	if #needed > 0 then
		use.card = source_skill(self,"#shabingCard:" .. table.concat(needed, "+") .. ":")
		return
	end
end


sgs.ai_skill_invoke.jinjun = true

function sgs.ai_cardsview_valuable.jinjun(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return nil end
	if package_known(player,"getPhase") ~= sgs.Player_NotActive then return nil end
	if (package_known(player,"getPileCount","soldier")==0) then return nil end
	if package_known(player,"getStrategyFlag","Global_jinjunFailed") then return nil end
	return skill_proposal("#jinjunCard",{},name)
end


sgs.ai_skill_playerchosen.liusha = function(self, targets)
	targets = sgs.QList2Table(targets)
	local target
	for _,enemy in ipairs(targets) do
		if enemy and package_known(self,"isEnemy",enemy) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and not package_known(self,"cantbeHurt",enemy) and package_known(self,"canDamage",enemy,self.player,nil) and package_known(enemy,"faceUp") and package_known(self,"toTurnOver",enemy, 0) then
			target= enemy
			break
		end
	end
	if target and math.random()<0.3 and not package_known(self,"isWeak") then
		return target
	end
	return nil
end

sgs.ai_cardneed.xuechang = sgs.ai_cardneed.slash

sgs.ai_skill_choice.xuechang = function(self, choices, data)
	local damage = package_known(data,"toDamage")
	local items = package_known(choices,"split","+")
	if table.contains(items, "hurt") then
		if package_known(self,"isEnemy",damage.to) and not package_known(self,"isWeak") and package_known(self,"damageIsEffective",damage.to, sgs.card_damage_nature[package_known(damage.card,"getClassName")]) and not package_known(self,"cantDamageMore",self.player, damage.to) then
			return "hurt"
		end
	end
	if table.contains(items, "reco") then
		if package_known(self,"isWeak") or package_known(self.player,"getHp") < getBestHp(self.player) or not package_known(self,"damageIsEffective",damage.to, sgs.card_damage_nature[package_known(damage.card,"getClassName")]) then
			return "reco"
		end
	end
	return "cancel"
end

sgs.ai_canNiepan_skill.xuemo = function(player)
	return package_known(player,"getStrategyMark","@xuemo") > 0
end

sgs.ai_ajustdamage_from.InfinityEdge = function(self,from,to,slash,nature)
	if slash and package_known(slash,"isKindOf","Slash")
	then return 1 end
end
sgs.ai_ajustdamage_from.Deathcap = function(self,from,to,card,nature)
	if card and package_known(card,"isKindOf","TrickCard")
	then return 1 end
end

for _,skill in ipairs(package_skills)do local fn=skill.getTurnUseCard;sgs.ai_fill_skill[skill.name]=function(self,inclusive,request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,self,inclusive,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return finish_turn(self,r[2],request)end end
for selector in pairs(SELECTORS)do local fn=sgs.ai_skill_use_func[selector];if type(fn)=="function"then sgs.ai_skill_use_func[selector]=function(card,use,self,request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,card,use,self,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return table.unpack(r,2,r.n)end end end
