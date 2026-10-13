-- new, fixed b6025acc. Exact source policies; no repair of removed legacy cards.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("new package input unknown",k)end;return v end
local nullable={getLord=true,getCurrent=true,getSameEquip=true,getMaxCard=true,getArmor=true,getTreasure=true,getCard=true,findLeijiTarget=true,findPlayerBySkillName=true,findPlayerToDraw=true,updatePlayers=true,updateIntention=true,setStrategyPlayerFlag=true}
local function q(o,k,...)
 if not o or type(o[k])~="function"then ai_unsupported("new package helper unavailable",k)end
 local method=k;if k=="getMark"and AIValue.isPlayer(o)then method="getStrategyMark"end
 local v=o[method](o,...);if AIUnsupported.is(v)then error(v,0)end
 if k=="sort"or k=="sortByKeepValue"or k=="sortByUseValue"then local t=(...);known(v,k);for i,x in ipairs(v)do t[i]=x end;return t end
 if k=="hasSkill"or k=="hasSkills"then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local r=type(p)=="table"and rawget(p,"_view");if v==false and r and r.skills_complete~=true then ai_unsupported("new foreign skill absence unknown",(...))end end
 if nullable[k]then return v end;return known(v,k)
end
-- Whether a legacy LuaSkillCard prototype parses is an engine query that is not projected.
local function old_parse(self,name,costs)
 ai_unsupported("legacy prototype presence is not projected",name)
end
local function terminal(self,wire)
 if wire=="."then return wire end
 ai_unsupported("legacy prototype presence is not projected","#luajiejiang")
end
-- sgs.ai_AOE_data has a writer only in the original-hegemony overrides.
local function aoe_truth(self)
 local h=AIHegemony.facts(self.world)
 if type(h)~="table"or type(h.original_overrides_loaded)~="boolean"then ai_unsupported("original override domain unknown","ai_AOE_data")end
 if not h.original_overrides_loaded then return false end
 ai_unsupported("legacy ai_AOE_data stack is not projected","ai_AOE_data")
end
local function complete_he(self,p)
 local cards=q(p,"getCards","he")
 if #cards~=q(p,"getHandcardNum")+#q(p,"getEquips")then ai_unsupported("luafan requires complete legal foreign Spade inventory","luafan.foreign_cards")end
 return cards
end
local function first_hand(self,player,cards)
 if #cards~=q(player,"getHandcardNum")then ai_unsupported("source first foreign hand card is undisclosed","luajiejiang2_main.first_hand")end
 return cards[1]
end
local function pile_card(player,id)
 local ai=player._room and player._room._ai
 if not ai or player~=ai.player then ai_unsupported("luaqiyi pile face is not viewer-owned","luaqiyi")end
 return q(ai,"getKnownCardById",id)
end
local function qiyi_spec(cards)
 local red,black=true,true;local ids={}
 for _,c in ipairs(cards)do ids[#ids+1]=q(c,"getEffectiveId");red=red and q(c,"isRed");black=black and q(c,"isBlack")end
 return{name="jink",skill="luaqiyi",suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit,number=0,subcards=ids}
end
local function call(reg,key,...)
 local f=sgs[reg]and sgs[reg][key];if type(f)~="function"then ai_unsupported("new shared callback unavailable",reg.."."..key)end
 local result=f(...);if AIUnsupported.is(result)then error(result,0)end;return result
end
local function global_call(name,...)
 local f=_G[name];if type(f)~="function"then ai_unsupported("new source helper unavailable",name)end
 return known(f(...),name)
end
local function source_friend(self,to,from)
 if not from or not to then return false end
 if q(from,"objectName")==q(to,"objectName")then return true end
 local function role(p)return p==self.player and q(p,"getRole")or q(self,"getRoleEstimate",p)end
 local fr=role(from)
 if fr=="lord"or fr=="loyalist"then
  if known(self.world.turn_count,"turncount")<=1 and role(to)=="renegade"and q(from,"aliveCount")>7
   or role(to)=="lord"or role(to)=="loyalist"then return true end
 end
 if fr=="rebel"and role(to)=="rebel"then return true end
 if fr=="renegade"then
  if known(self.world.turn_count,"turncount")<=1 and role(to)=="loyalist"and q(from,"aliveCount")>7
   or role(to)=="lord"and q(from,"aliveCount")>2 then return true end
 end
 return false
end
local luajiejiang_policy

sgs.ai_skill_choice.luajuemou = function(self, choice)
	if q(self.player,"getHp") < q(self.player,"getMaxHp") - 1 then return "luajuemouHp" end
	return "luajuemouCd"
end

sgs.ai_can_damagehp.luajuemou = function(self, from, card, to)
	return not (q(to,"isWounded") or q(to,"getMark","luajuemou") > 0)
		and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0 and q(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_playerchosen.lualilian = function(self, targets)
	q(self,"updatePlayers")
	q(self,"sort",self.friends_noself, "handcard")
	local target = nil
	local n = 0
	for _, friend in ipairs(self.friends_noself) do
		if not q(friend,"faceUp") then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not q(self,"toTurnOver",friend, n, "lualilian") then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = q(self,"findPlayerToDraw",false, n)
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if q(self,"toTurnOver",enemy, n, "lualilian") and q(self,"hasManjuanEffect",enemy) then
						target = enemy
						break
					end
				end
			end
		else
			q(self,"sort",self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if q(self,"toTurnOver",enemy, n, "lualilian") and q(self,"hasManjuanEffect",enemy) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if q(self,"toTurnOver",enemy, n, "lualilian") and q(self,"hasSkills",sgs.priority_skill, enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if q(self,"toTurnOver",enemy, n, "lualilian") then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end

sgs.ai_playerchosen_intention.lualilian = function(self, from, to)
	local intention = 80
	if not q(self,"toTurnOver",to, 0, "lualilian") then intention = -intention end
	q(self,"updateIntention",from, to, intention)
end

sgs.ai_need_damaged.lualilian = function(self, attacker, player)
	if not q(player,"hasSkill","lualilian") then return false end
	local enemies = q(self,"getEnemies",player)
	if #enemies < 1 then return false end
	q(self,"sort",enemies, "defense")
	for _, enemy in ipairs(enemies) do
		if q(player,"getLostHp") < 1 and q(self,"toTurnOver",enemy, 0, "lualilian") then
			return true
		end
	end
	local friends = q(self,"getFriends",player, true)
	q(self,"sort",friends, "defense")
	for _, friend in ipairs(friends) do
		if not q(self,"toTurnOver",friend, 0, "lualilian") then return true end
	end
	return false
end

sgs.ai_skill_choice.lualilian = function(self, choice)
	local targets = q(self.room,"getOtherPlayers",self.player)
	if targets:length() == 0 then return false end
	if call("ai_skill_playerchosen","lualilian",self, targets) ~= nil then
		return "luayihengturn"
	end
	return "luayihengmopai"
end


sgs.ai_fill_skill.lualveji_vs = function(self,inclusive,request)
	if q(self.player,"hasUsed","#lualveji") then return end
	if #self.enemies == 0 then return end

	if q(self.player,"hasSkill","luawu_trs") and (q(self.player,"getMark","@luawu_mark") > 0) then
		local good, bad = 0, 0
		local lord = q(self.room,"getLord")
		if lord and q(self.player,"getRole") ~= "rebel" and q(self,"isWeak",lord) then return end
		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(self,"isWeak",player) then
				if q(self,"isFriend",player) then
					bad = bad + 1
				else
					good = good + 1
				end
			end
		end
		if good == 0 then return end

		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			local hp = math.max(q(player,"getHp"), 1)
			if global_call("getCardsNum","Analeptic", player) > 0 then
				if q(self,"isFriend",player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end
			if q(self,"isFriend",player) then
				good = good + math.max(global_call("getCardsNum","Peach", player), 1)
			else
				bad = bad + math.max(global_call("getCardsNum","Peach", player), 1)
			end

			local lost_value = 0
			local hp = math.max(q(player,"getHp"), 1)
			if q(self,"isFriend",player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end

		if good > bad then
			q(self,"setStrategyPlayerFlag",self.player,"should_luawu",true)
		end
	end



	if (q(self.player,"getHp") > 3 and q(self.player,"getHandcardNum") > q(self.player,"getHp"))
		or (q(self.player,"getHp") - q(self.player,"getHandcardNum") >= 2)
		or (q(self.player,"getHp") > 1 and q(self.player,"getRole") == "loyalist")
	then
		return old_parse(self,"#lualveji",{})
	end

	local function can_kurou_with_cb(self)
		if q(self.player,"getHp") > 1 then return true end
		local has_save = false
		local huatuo = q(self.room,"findPlayerBySkillName","jijiu")
		if huatuo and q(self,"isFriend",huatuo) then
			for _, equip in sgs.qlist(q(huatuo,"getEquips")) do
				if q(equip,"isRed") then
					has_save = true
					break
				end
			end
			if not has_save then has_save = (q(huatuo,"getHandcardNum") > 3) end
		end
		if has_save then return true end
		local handang = q(self.room,"findPlayerBySkillName","nosjiefan")
		if handang and q(self,"isFriend",handang) and global_call("getCardsNum","Slash", handang, self.player) >= 1 then return true end
		return false
	end

	local slash = q(self,"getEvaluationCard","slash")
	
	if (q(self.player,"hasWeapon","crossbow") or q(self,"getCardsNum","Crossbow") > 0) or q(self,"getCardsNum","Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if q(self.player,"canSlash",enemy) and q(self,"slashIsEffective",slash, enemy)
				and q(self,"isGoodTarget",enemy, self.enemies) and not q(self,"slashProhibit",slash, enemy) and can_kurou_with_cb(self) then
				return old_parse(self,"#lualveji",{})
			end
		end
	end

	if q(self.player,"getHp") <= 1 and q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Peach") > 1 then
		return old_parse(self,"#lualveji",{})
	end
end

sgs.ai_skill_use_func["#lualveji"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["lualveji"] = 6.7


sgs.ai_skill_askforag["lualveji"] = function(self, card_ids)
	if #card_ids == 1 then return card_ids[1] end
	local cards = {}
	local x = 0
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, q(self,"getKnownCardById",card_id))
		if (q(self,"getKnownCardById",card_id)):isBlack() then
			x = x + 1
		end
	end
	if x >= 2 then
		q(self,"setStrategyPlayerFlag",self.player,"AI_doInvoke_luawu",true)
	end
	if #card_ids > 0 then return q(self,"askForAG",card_ids, false, "dummyreason") end
	return card_ids[1]
end

sgs.ai_skill_choice.lualveji = function(self, choice)
	if q(self.player,"hasFlag","should_luawu") then
		if q(self.player,"hasFlag","lualveji_vsblack") and q(self.player,"hasFlag","AI_doInvoke_luawu") then
			return "lualvejiFZ"
		end
	end
	return "lualvejiQZ"
end




sgs.ai_fill_skill.luawu_trs = function(self,inclusive,request)
	if q(self.player,"getMark","@luawu_mark") <= 0 then return end
	if q(self.room,"getMode") == "_mini_13" then return old_parse(self,"#luawu",{}) end
	local good, bad = 0, 0
	local lord = q(self.room,"getLord")
	if lord and q(self.player,"getRole") ~= "rebel" and q(self,"isWeak",lord) then return end
	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self,"isWeak",player) then
			if q(self,"isFriend",player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		local hp = math.max(q(player,"getHp"), 1)
		if global_call("getCardsNum","Analeptic", player) > 0 then
			if q(self,"isFriend",player) then
				good = good + 1.0 / hp
			else
				bad = bad + 1.0 / hp
			end
		end
		if q(self,"isFriend",player) then
			good = good + math.max(global_call("getCardsNum","Peach", player), 1)
		else
			bad = bad + math.max(global_call("getCardsNum","Peach", player), 1)
		end

		local lost_value = 0
		local hp = math.max(q(player,"getHp"), 1)
		if q(self,"isFriend",player) then
			bad = bad + (lost_value + 1) / hp
		else
			good = good + (lost_value + 1) / hp
		end
	end

	if (good > bad) and ((q(self.player,"hasFlag","should_luawu") and q(self.player,"hasFlag","AI_doInvoke_luawu")) or (not q(self.player,"hasSkill","lualveji_vs"))) then
		return old_parse(self,"#luawu",{})
	end
end

sgs.ai_skill_use_func["#luawu"] = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.damage_card["#luawu"] = true


sgs.ai_use_priority["luawu"] = 6.8


sgs.ai_skill_playerchosen.luafan = function(self, targets)
	local mode = q(self.room,"getMode")
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = q(self.room,"getAllPlayers")
		for _, aplayer in sgs.qlist(players) do
			if q(aplayer,"getState") ~= "robot" then
				return aplayer
			end
		end
	end

	q(self,"updatePlayers")
	return q(self,"findLeijiTarget",self.player, 100, nil, -1)
end

-- shared immutable alias ai_playerchosen_intention.luafan -> ai_playerchosen_intention.leiji
function SmartAIView:SlashCanIgnoreJink(from, to, slash)
	from = from or q(self.room,"getCurrent")
	to = to or self.player
	slash = slash or q(self,"getEvaluationCard","slash")
	return not known(sgs.isJinkAvailable(from,to,slash),"isJinkAvailable") or q(from,"hasSkill","wanglie")
end

function sgs.ai_slash_prohibit.luafan(self, from, to, card)
	local has_black_card = false
	for _, c in ipairs(sgs.QList2Table(complete_he(self,to))) do
		if q(c,"getSuit") == sgs.Card_Spade then
			has_black_card = true
		end
	end

	if q(self,"isFriend",to, from) and has_black_card then return false end
	if q(to,"hasFlag","QianxiTarget") and (not q(self,"hasEightDiagramEffect",to) or q(self.player,"hasWeapon","qinggang_sword")) then return false end
	if q(from,"hasSkill","tieji") then return false end
	local hcard = q(to,"getHandcardNum")
	if q(from,"hasSkill","liegong") and (hcard >= q(from,"getHp") or hcard <= q(from,"getAttackRange")) then return false end
	if q(from,"hasSkill","kofliegong") and hcard >= q(from,"getHp") then return false end
	if q(self,"SlashCanIgnoreJink",from, to) then return false end

	if not q(self,"getCardId","Jink", to) then
		if q(self,"hasEightDiagramEffect",to) then
			if q(self,"ignoreArmor",from,to) then
				return false
			else
				return true
			end
		else
			return false
		end
	else
		return true
	end

	if q(from,"getRole") == "rebel" and q(to,"isLord") then
		local other_rebel
		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",from)) do
			if q(self,"getRoleEstimate",player)== "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((q(from,"getHp") >= 4 and (global_call("getCardsNum","Peach", from, self.player) > 0 or q(from,"hasSkills","nosganglie|vsnosganglie"))) or q(from,"hasSkill","hongyan")) then
			return false
		end
	end
	if q(self,"getKnownCard",to, from, "Jink", true) >= 1 or (q(self,"hasSuit","spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if q(self,"hasEightDiagramEffect",to) and not q(self,"ignoreArmor",from,to) then return true end
	if q(to,"getTreasure") and q(to,"getPile","wooden_ox"):length() > 1 then return true end
end

-- shared immutable alias ai_cardneed.luafan -> ai_cardneed.leiji
sgs.ai_use_revises.luafan = function(self, card, use)
	if q(card,"isKindOf","EquipCard")
		and q(card,"getSuit") == sgs.Card_Spade and q(card,"getNumber") <= 9 and q(card,"getNumber") >= 2 and q(self,"hasSkills",sgs.wizard_skill, self.player)
	then
		local same = q(self,"getSameEquip",card)
		if same and q(same,"getSuit") == sgs.Card_Spade and q(same,"getNumber") <= 9 and q(same,"getNumber") >= 2
		then
			return false
		end
	end
end

sgs.ai_need_damaged.luaxumou = function(self, attacker, player)
	if not q(player,"hasSkill","chanyuan") and q(player,"hasSkill","luaxumou") and q(player,"getMark","luaxumou") == 0 and q(self,"getEnemyNumBySeat",q(self.room,"getCurrent"), player, player, true) < q(player,"getHp")
		and (q(player,"getHp") > 2 or q(player,"getHp") == 2 and (q(player,"faceUp") or q(player,"hasSkill","guixin") or q(player,"hasSkill","toudu") and not q(player,"isKongcheng"))) then
		return true
	end
	return false
end

function sgs.ai_slash_prohibit.luaxumou(self, from, to, card)
	if known(self.world.turn_count,"turncount") <= 1 and q(to,"isLord") and q(to,"getHp") >= 2 and not q(self,"isFriend",to, from) then return true end
end

sgs.ai_view_as.luaqiyi = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(q(player,"getCards","h"))
	if q(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(player,"getPile","wooden_ox")) do
			table.insert(usable_cards, pile_card(player,id))
		end
	end
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")

	local two_cards,materials = {},{}
	for _, c in ipairs(usable_cards) do
		if q(c,"getSuit") == q(card,"getSuit") and #two_cards < 2 then
			
			table.insert(two_cards, q(c,"getEffectiveId"));materials[#materials+1]=c

		end
	end


	if #two_cards == 2 and not q(card,"isKindOf","Jink") then
		return qiyi_spec(materials)
	end
end



sgs.ai_skill_cardask["@luaguidao"] = function(self, data)
	local judge = q(data,"toJudge")
	local all_cards = q(self.player,"getCards","he")

	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			all_cards:prepend(q(self,"getKnownCardById",id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = q(judge.card,"getSuit") ~= sgs.Card_Spade and
		((not q(self.player,"hasSkill","leiji") and not q(self.player,"hasSkill","olleiji")) or q(judge.card,"getSuit") ~= sgs.Card_Club)
		and aoe_truth(self) and q(self,"playerGetRound",judge.who) < q(self,"playerGetRound",self.player) and
		q(self,"findLeijiTarget",self.player, 50)
		and (q(self,"getCardsNum","Jink") > 0 or q(self,"hasEightDiagramEffect")) and q(self,"getFinalRetrial") == 1

	if not needTokeep then
		local who = judge.who
		if q(who,"getPhase") == sgs.Player_Judge and not q(who,"getJudgingArea"):isEmpty() and q(who,"containsTrick","lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if q(self.player,"hasSkill","nosleiji") then keptspade = 2 end
		if q(self.player,"hasSkill","luafan") then keptspade = 2 end
		if q(self.player,"hasSkill","leiji") then keptblack = 2 end
		if q(self.player,"hasSkill","olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not q(card,"hasFlag","using") then
			if q(card,"getSuit") == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not q(self.player,"hasSkill","olleiji") then return "." end
	if keptspade == 1 and not q(self.player,"hasSkill","leiji") then return "." end
	if keptspade == 1 and not q(self.player,"hasSkill","luafan") then return "." end

	local card_id = q(self,"getRetrialCardId",cards, judge)
	if card_id == -1 then
		if q(self,"needRetrial",judge) and judge.reason ~= "beige" then
			if q(self,"needToThrowArmor") then return "$" .. q(self.player,"getArmor"):getEffectiveId() end
			q(self,"sortByUseValue",cards, true)
			if q(self,"getUseValue",judge.card) > q(self,"getUseValue",cards[1]) then
				return "$" .. q(cards[1],"getId")
			end
		end
	elseif q(self,"needRetrial",judge) or q(self,"getUseValue",judge.card) > q(self,"getUseValue",q(self,"getKnownCardById",card_id)) then
		local card = q(self,"getKnownCardById",card_id)
		return "$" .. card_id
	end

	return "."
end
function sgs.ai_cardneed.luaguidao(to, card, self)
	for _, player in sgs.qlist(q(self.room,"getAllPlayers")) do
		if q(self,"getFinalRetrial",to) == 1 then
			if q(player,"containsTrick","lightning") and not q(player,"containsTrick","YanxiaoCard") then
				return q(card,"getSuit") == sgs.Card_Spade and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9 and
					not q(self,"hasSkills","hongyan|wuyan")
			end
			if q(self,"isFriend",player) and q(self,"willSkipDrawPhase",player) then
				return q(card,"getSuit") == sgs.Card_Club and q(self,"hasSuit","club", true, to)
			end
			if q(self,"isFriend",player) and q(self,"willSkipPlayPhase",player) then
				return q(card,"getSuit") == sgs.Card_Heart and q(self,"hasSuit","heart", true, to)
			end
		end
	end
	if q(self,"getFinalRetrial",to) == 1 then
		if q(to,"hasSkill","nosleiji") then
			return q(card,"getSuit") == sgs.Card_Spade
		end
		if q(to,"hasSkill","leiji") then
			return q(card,"isBlack")
		end
		if q(to,"hasSkill","olleiji") then
			return q(card,"isBlack")
		end
		if q(to,"hasSkill","luafan") then
			return q(card,"getSuit") == sgs.Card_Spade and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9
		end
	end
end

sgs.ai_useto_revises.luaguidao = function(self, card, use, p)
	if q(card,"isKindOf","Indulgence") or q(card,"isKindOf","SupplyShortage")
	then
		if q(self,"isFriend",p) and q(p,"getCardCount") > 2
		then
			use.card = card
			return
		end
		return false
	end
end
sgs.wizard_harm_skill =  sgs.wizard_harm_skill .. "|luaguidao"
sgs.wizard_skill =  sgs.wizard_skill .. "|luaguidao"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|luaguidao"


sgs.ai_skill_invoke.luajiejiang = function(self, data)
	if #self.enemies == 0 then
		return false
	end
	local targets = q(self.room,"getOtherPlayers",self.player)
	local cardstr = luajiejiang_policy(self, "@luajiejiang")
	if (call("ai_skill_playerchosen","luajiejiang",self, targets) ~= nil) or (cardstr:match("->")) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.luajiejiang = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	q(self,"updatePlayers")
	q(self,"sort",self.friends_noself, "handcard")
	local target = nil
	local n = 0

	q(self,"sort",self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if q(self,"toTurnOver",enemy, n, "luajiejiang") and q(self,"hasManjuanEffect",enemy) then
			target = enemy
			break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if q(self,"toTurnOver",enemy, n, "luajiejiang") and q(self,"hasSkills",sgs.priority_skill, enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if q(self,"toTurnOver",enemy, n, "luajiejiang") then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not q(friend,"faceUp") then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not q(self,"toTurnOver",friend, n, "luajiejiang") then
				target = friend
				break
			end
		end
	end

	return nil
end

luajiejiang_policy = function(self, prompt)
	q(self,"sort",self.enemies, "handcard_defense")
	local tuxi_mark = 2
	local targets = {}

	local zhugeliang = q(self.room,"findPlayerBySkillName","kongcheng")
	local luxun = q(self.room,"findPlayerBySkillName","lianying") or q(self.room,"findPlayerBySkillName","noslianying")
	local dengai = q(self.room,"findPlayerBySkillName","tuntian")
	local jiangwei = q(self.room,"findPlayerBySkillName","zhiji")
	local zhijiangwei = q(self.room,"findPlayerBySkillName","beifa")

	local add_player = function(player, isfriend)
		if q(player,"getHandcardNum") == 0 or q(player,"objectName") == q(self.player,"objectName") then return #targets end
		if q(self,"objectiveLevel",player) == 0 and q(player,"isLord") and known(q(self,"getRoleCounts").rebel,"rebel count") > 1 then
			return #
				targets
		end

		local f = false
		for _, c in ipairs(targets) do
			if c == q(player,"objectName") then
				f = true
				break
			end
		end

		if not f then table.insert(targets, q(player,"objectName")) end

		if isfriend and isfriend == 1 then
			q(self,"setStrategyPlayerFlag",self.player,"luajiejiang_isfriend_" .. q(player,"objectName"),true)
		end
		return #targets
	end

	local parseTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "#luajiejiang:.:->" .. s
	end

	local lord = q(self.room,"getLord")
	if lord and q(self,"isEnemy",lord) and known(self.world.turn_count,"turncount") <= 1 and not q(lord,"isNude") then
		if add_player(lord) == tuxi_mark then return parseTuxiCard() end
	end

	for _, friend in ipairs(self.friends) do
		if q(friend,"getJudgingArea"):length() > 0 then
			local judges = q(friend,"getJudgingArea")
			for _, judge in sgs.qlist(judges) do
				local card = q(self,"getKnownCardById",q(judge,"getEffectiveId"))
				if not q(judge,"isKindOf","YanxiaoCard") then
					if add_player(friend, 1) == tuxi_mark then return parseTuxiCard() end
				end
			end
		end
	end

	if jiangwei and q(self,"isFriend",jiangwei) and q(jiangwei,"getMark","zhiji") == 0 and q(jiangwei,"getHandcardNum") == 1
		and q(self,"getEnemyNumBySeat",self.player, jiangwei) <= (q(jiangwei,"getHp") >= 3 and 1 or 0) then
		if add_player(jiangwei, 1) == tuxi_mark then return parseTuxiCard() end
	end

	if dengai and q(self,"isFriend",dengai) and (not q(self,"isWeak",dengai) or q(self,"getEnemyNumBySeat",self.player, dengai) == 0)
		and q(dengai,"hasSkill","zaoxian") and q(dengai,"getMark","zaoxian") == 0 and q(dengai,"getPile","field"):length() == 2 and add_player(dengai, 1) == tuxi_mark then
		return parseTuxiCard()
	end

	if zhugeliang and q(self,"isFriend",zhugeliang) and q(zhugeliang,"getHandcardNum") == 1 and q(self,"getEnemyNumBySeat",self.player, zhugeliang) > 0 then
		if q(zhugeliang,"getHp") <= 2 then
			if add_player(zhugeliang, 1) == tuxi_mark then return parseTuxiCard() end
		else
			local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(zhugeliang,"objectName"))
			local cards = sgs.QList2Table(q(zhugeliang,"getHandcards"))
			if #cards == 1 and (q(cards[1],"hasFlag","visible") or q(cards[1],"hasFlag",flag)) then
				if q(cards[1],"isKindOf","TrickCard") or q(cards[1],"isKindOf","Slash") or q(cards[1],"isKindOf","EquipCard") then
					if add_player(zhugeliang, 1) == tuxi_mark then return parseTuxiCard() end
				end
			end
		end
	end

	if luxun and q(self,"isFriend",luxun) and q(luxun,"getHandcardNum") == 1 and q(self,"getEnemyNumBySeat",self.player, luxun) > 0 then
		local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(luxun,"objectName"))
		local cards = sgs.QList2Table(q(luxun,"getHandcards"))
		if #cards == 1 and (q(cards[1],"hasFlag","visible") or q(cards[1],"hasFlag",flag)) then
			if q(cards[1],"isKindOf","TrickCard") or q(cards[1],"isKindOf","Slash") or q(cards[1],"isKindOf","EquipCard") then
				if add_player(luxun, 1) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	if zhijiangwei and q(self,"isFriend",zhijiangwei) and q(zhijiangwei,"getHandcardNum") == 1 and
		q(self,"getEnemyNumBySeat",self.player, zhijiangwei) <= (q(zhijiangwei,"getHp") >= 3 and 1 or 0) then
		local isGood
		for _, enemy in ipairs(self.enemies) do
			local def = q(self,"getDefenseSlash",enemy)
			local slash = q(self,"getEvaluationCard","slash")
			
			local eff = q(self,"slashIsEffective",slash, enemy, zhijiangwei) and
				q(self,"isGoodTarget",enemy, self.enemies, slash)
			if q(zhijiangwei,"canSlash",enemy, slash) and not q(self,"slashProhibit",slash, enemy, zhijiangwei) and eff and def < 4 then
				isGood = true
			end
		end
		if isGood and add_player(zhijiangwei, 1) == tuxi_mark then return parseTuxiCard() end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(q(p,"getHandcards"))
		local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(p,"objectName"))
		for _, card in ipairs(cards) do
			if (q(card,"hasFlag","visible") or q(card,"hasFlag",flag)) and (q(card,"isKindOf","Peach") or q(card,"isKindOf","Nullification") or q(card,"isKindOf","Analeptic")) then
				if add_player(p) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if q(p,"hasSkills","jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == tuxi_mark then return parseTuxiCard() end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = q(p,"getHandcardNum")
		local good_target = true
		if x == 1 and q(self,"needKongcheng",p) then good_target = false end
		if x >= 2 and q(self,"hasTuntianEffect",p, true) then good_target = false end
		if good_target and add_player(p) == tuxi_mark then return parseTuxiCard() end
	end


	if luxun and add_player(luxun, (q(self,"isFriend",luxun) and 1 or nil)) == tuxi_mark then
		return parseTuxiCard()
	end

	if dengai and q(self,"isFriend",dengai) and q(dengai,"hasSkill","zaoxian") and (not q(self,"isWeak",dengai) or q(self,"getEnemyNumBySeat",self.player, dengai) == 0) and add_player(dengai, 1) == tuxi_mark then
		return parseTuxiCard()
	end

	local others = q(self.room,"getOtherPlayers",self.player)
	for _, other in sgs.qlist(others) do
		if q(self,"objectiveLevel",other) >= 0 and not (q(self,"hasTuntianEffect",other, true)) and add_player(other) == tuxi_mark then
			return parseTuxiCard()
		end
	end

	for _, other in sgs.qlist(others) do
		if q(self,"objectiveLevel",other) >= 0 and not (q(self,"hasTuntianEffect",other, true)) and math.random(0, 5) <= 1 and not q(self,"hasSkills","qiaobian") then
			add_player(other)
		end
	end

	return parseTuxiCard()
end

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|luajiejiang"

sgs.ai_skill_cardchosen["luajiejiang2_main"] = function(self, who, flags)
	local equipments = sgs.QList2Table(q(who,"getEquips"))
	equipments = sgs.reverse(equipments)
	local handcards = sgs.QList2Table(q(who,"getHandcards"))
	if q(self,"isFriend",who) then

		if flags:match("j") and not q(who,"containsTrick","YanxiaoCard") and not (q(who,"hasSkill","qiaobian") and q(who,"getHandcardNum") > 0) then
			local tricks = q(who,"getCards","j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if q(trick,"isKindOf","Lightning") then
					lightning = q(trick,"getEffectiveId")
				elseif q(trick,"isKindOf","Indulgence") then
					indulgence = q(trick,"getEffectiveId")
				elseif not q(trick,"isKindOf","Disaster") then
					supply_shortage = q(trick,"getEffectiveId")
				end
			end

			if q(self,"hasWizard",self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if q(who,"getHp") < q(who,"getHandcardNum") then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if q(who,"getPile","wooden_ox"):length() > 0 then
			for _, e in ipairs(equipments) do
				if q(e,"isKindOf","WoodenOx") then
					table.removeOne(equipments, e)
				end
			end
		end

		if q(who,"hasArmorEffect","silver_lion") and q(who,"isWounded") then
			return q(who,"getArmor")
		end
		if q(who,"getEquips"):length() > 0 then
			if q(who,"getHandcardNum") > 2 or (q(who,"getHandcardNum") > 0 and q(who,"getPile","wooden_ox"):length() > 0) then
				return first_hand(self,who,handcards)
			else
				return equipments[1]
			end
		end
	end
	return nil
end



sgs.ai_fill_skill.luamouce = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#luamouce") then
		return old_parse(self,"#luamouce",{})
	end
end

sgs.ai_skill_use_func["#luamouce"] = function(card, use, self)
	q(self,"updatePlayers")
	q(self,"sort",self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"isWounded") and q(self.player,"canDiscard",enemy, "hej") and q(self,"doDisCard",enemy, "hej") and not q(self,"hasZhaxiangEffect",enemy) then
			target = enemy
			break
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["luamouce"] = 7
sgs.ai_use_value["luamouce"] = 7
sgs.ai_card_intention["luamouce"] = 80



sgs.ai_skill_invoke.luaJC = function(self, data)
	if q(self.player,"isLord") then return false end
	if q(self,"getCardsNum","Peach") > 0 then
		return false
	end
	for _, friend in ipairs(self.friends_noself) do
		if global_call("getCardsNum","Peach", friend) > 0 then
			return false
		end
	end
	return true
end




sgs.ai_skill_playerchosen["ask_1"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target     = q(self,"findPlayerToDraw",false, 2)
	if target then
		return target
	end
	return targetlist[1]
end

sgs.ai_skill_playerchosen["ask_2"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local lord       = q(self.room,"getLord")
	if lord and q(self,"isEnemy",lord) then
		return lord
	end
	q(self,"updatePlayers")
	q(self,"sort",self.enemies, "defense")

	if #self.enemies > 0 then
		return self.enemies[1]
	end
	return targetlist[1]
end
function sgs.ai_cardneed.luaqinglong(to, card, self)
	if not q(self,"willSkipPlayPhase",to) then
		return q(card,"isKindOf","Blade") or (isCard("Slash", card, to) and q(self,"getKnownCard",to, "Slash", true) == 0)
	end
end


function sgs.ai_armor_value.luaqinglong(player, self, card)
	if card and q(card,"isKindOf","Blade") then return 4 end
end

sgs.ai_use_revises.luaqinglong = function(self, card, use)
	if card and q(card,"isKindOf","Weapon")
	then
		local same = q(self,"getSameEquip",card)
		if same and q(same,"isKindOf","Blade")
		then
			return false
		end
	end
end


sgs.ai_skill_invoke["@luaqibing"] = function(self, data)
	local use = q(data,"toCardUse")
	local card = use.card
	if q(card,"isKindOf","EquipCard") then
		return false
	end
	return true
end

sgs.ai_skill_invoke["luaqibing"] = function(self, data)
	local damage = q(data,"toDamage")
	local target = damage.to
	if not q(self,"isEnemy",target) then return "." end
	if q(target,"hasArmorEffect","silver_lion") then return "." end


	return true
end

sgs.ai_ajustdamage_from.luaqibing = function(self, from, to, card, nature)
	if q(from,"getPile","luaqibingcards"):length() > 0 and not source_friend(self,to,from) and card and q(card,"isKindOf","Slash")
	then
		return 1
	end
end
-- shared immutable alias ai_cardneed.luaqibing -> ai_cardneed.slash
sgs.ai_skill_invoke["luazhenshe"] = function(self, data)
	local damage = q(data,"toDamage")
	local target = damage.to
	if not q(self,"isEnemy",target) then return "." end
	if q(target,"hasArmorEffect","silver_lion") then return "." end

	local max_card = q(self,"getMaxCard")
	local max_point = q(max_card,"getNumber")
	local enemy_max_card = q(self,"getMaxCard",target)
	local enemy_max_point = enemy_max_card and q(enemy_max_card,"getNumber") or 100
	if (max_point > enemy_max_point) or q(target,"isKongcheng") then
		return true
	end
	if q(self.player,"getLostHp") + 1 >= 2 or not q(self.player,"faceUp") then
		return true
	end
	return false
end

-- shared immutable alias ai_cardneed.luazhenshe -> ai_cardneed.bignumber
-- shared immutable alias ai_need_damaged.luajilue -> ai_need_damaged.fangzhu
-- shared immutable alias ai_can_damagehp.luajilue -> ai_can_damagehp.jieming
sgs.ai_skill_choice.luajilue = function(self, choice)
	local context=q(self,"getDecisionContext")
	local targets = q(self.room,"getOtherPlayers",self.player)
	if (call("ai_skill_playerchosen","fangzhu",self, targets) ~= nil) then
		return "c3"
	end
	if (call("ai_skill_playerchosen","jieming",self, targets) ~= nil) then
		return "c2"
	end

	local damage=known(context.damage,"CurrentDamageStruct")
	if (call("ai_skill_invoke","fankui",self, {toPlayer=function()return damage.from end})) then
		return "c1"
	end
	return "c4"
end



sgs.ai_fill_skill.luahuntian = function(self,inclusive,request)
	if q(self.player,"hasUsed","#luahuntian") then return end
	if #self.enemies < 1 then return end
	return old_parse(self,"#luahuntian",{})
end

sgs.ai_skill_use_func["#luahuntian"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
		end
	end
	local needed = {}
	for _, acard in ipairs(cards) do
		if q(acard,"getSuit") == sgs.Card_Spade and #needed < 5 then
			table.insert(needed, q(acard,"getEffectiveId"))
			if #needed == 5 then
				break
			end
		end
	end
	if targets and needed and #needed == 5 then
		use.card = old_parse(self,"#luahuntian",needed)
		use.to = targets
		return
	end
end

sgs.ai_use_value["luahuntian"]       = 10
sgs.ai_use_priority["luahuntian"]    = 9
sgs.ai_card_intention["luahuntian"]  = 60


sgs.ai_skill_invoke["luajiaodi"] = function(self, data)
	return true
end

sgs.ai_fill_skill.luafentian = function(self,inclusive,request)
	if q(self.player,"hasUsed","#luafentian") then return end
	if #self.enemies < 1 then return end
	if q(self.player,"getMark","@fentian_mark") == 0 then return end
	return old_parse(self,"#luafentian",{})
end

sgs.ai_skill_use_func["#luafentian"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
		end
	end
	local needed = {}
	for _, acard in ipairs(cards) do
		if q(acard,"getSuit") == sgs.Card_Spade and #needed < 1 then
			table.insert(needed, q(acard,"getEffectiveId"))
			if #needed == 1 then
				break
			end
		end
	end
	if targets and needed and #needed == 1 then
		use.card = old_parse(self,"#luafentian",needed)
		use.to = targets
		return
	end
end

sgs.ai_use_value["luafentian"]       = 10
sgs.ai_use_priority["luafentian"]    = 9
sgs.ai_card_intention["luafentian"]  = 60


sgs.ai_skill_playerchosen["@luageipai2"] = function(self, targets)
	return self.player
end


sgs.ai_fill_skill.luajice = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#luajice") and not q(self.player,"getPile","Plianji"):isEmpty() then
		return old_parse(self,"#luajice",{})
	end
end

sgs.ai_skill_use_func["#luajice"] = function(card, use, self)
	q(self,"updatePlayers")
	q(self,"sort",self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isKongcheng") and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not q(self,"cantbeHurt",enemy) and q(self,"doDisCard",enemy, "h", true) then
			target = enemy
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isKongcheng") and q(self,"doDisCard",enemy, "h", true)  then
				target = enemy
			end
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["luajice"] = 7
sgs.ai_use_value["luajice"] = 7
sgs.ai_card_intention["luajice"] = 80

sgs.ai_skill_invoke["lualianji"] = function(self, data)
	return true
end

sgs.ai_skill_use["@@luajiejiang"]=function(self,prompt)return terminal(self,luajiejiang_policy(self,prompt))end

-- Same-closure aliases are admitted only by the native immutable identity snapshot.
if ai_audited_aliases then
 for _,row in ipairs{
  {"ai_playerchosen_intention","luafan","leiji",1},
  {"ai_cardneed","luafan","leiji",3},
  {"ai_cardneed","luaqibing","slash",3},
  {"ai_cardneed","luazhenshe","bignumber",3},
  {"ai_need_damaged","luajilue","fangzhu",1},
  {"ai_can_damagehp","luajilue","jieming",1},
 }do ai_audited_aliases.register{id=row[1].."."..row[2],registry=row[1],path={row[2]},canonical_registry=row[1],canonical_path={row[3]},self_index=row[4],defer_canonical=true}end
end
