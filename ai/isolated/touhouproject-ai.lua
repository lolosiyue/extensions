-- Necessary fixed-source slice: touhouproject-ai.lua:4705-4709 (b6025acc).
-- Other package callbacks are not claimed by this slice.
sgs.ai_ajustdamage_from.TH_guanglongzhitanxi = function(self, from, to, card, nature)
    local mark = from:getStrategyMark("@TH_yuyi")
    if AIUnsupported.is(mark) then error(mark, 0) end
    if mark == nil then ai_unsupported("source strategy mark is unknown", "@TH_yuyi") end
    if mark > 2 and not self:beFriend(to, from) then
        return 1
    end
end

-- R49: complete fixed Guanglong fill/use/invoke/intention family.
do
 sgs.ai_skillInvoke_intention=sgs.ai_skillInvoke_intention or{}
 local function q(o,k,...)
  if o==nil then error('attempt to index a nil value',0)end
  local f=o[k];if type(f)~='function'then ai_unsupported('Guanglong source helper unavailable',k)end
  local v=f(o,...);if AIUnsupported.is(v)then error(v,0)end
  if v==nil and not SmartAIView.isKnownNilStrategyResult(o,k,f)then ai_unsupported('Guanglong source input unknown',k)end
  return v
 end
 local function list(v,k)if not AIValue.isList(v)then ai_unsupported('Guanglong source player list unknown',k)end;return v end
sgs.ai_fill_skill.TH_guanglongzhitanxi = function(self, inclusive, request)
	if q(self.player,"getMark","@TH_yuyi") >= q(self.player,"aliveCount") - 1 and q(self.player,"getMark","@TH_yuyi") >= 3 then
		local TH_skillcard = q(self,"evaluateTurnSkillCard","TH_guanglongzhitanxi","#TH_guanglongzhitanxiCARD",{},request)
		assert(TH_skillcard)
		return TH_skillcard
	end
end
sgs.ai_skill_use_func["#TH_guanglongzhitanxiCARD"] = function(card, use, self)

	local targets = AIList.new({})
	for _, enemy in ipairs(list(self.enemies,"enemies")) do
		if q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder, self.player) and not q(self,"needToLoseHp",enemy, self.player)
			and (not q(enemy,"isChained") or q(self,"isGoodChainTarget",enemy,sgs.DamageStruct_Thunder, self.player)) then
			targets:append(enemy)
			if targets:length() >= 5 then break end
		end
	end
	if targets:length() < 5 then
		for _, friend in ipairs(list(self.friends_noself,"friends_noself")) do
			if q(self,"damageIsEffective",friend, sgs.DamageStruct_Thunder, self.player) and q(self,"needToLoseHp",friend, self.player)
				and (not q(friend,"isChained") or q(self,"isGoodChainTarget",friend, sgs.DamageStruct_Thunder, self.player)) then
				targets:append(friend)
				if targets:length() >= 5 then break end
			end
		end
	end
	if targets:length() > 0 and targets:length() <= 5 then
		use.card = card
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["TH_guanglongzhitanxiCARD"] = 5
sgs.ai_use_priority["TH_guanglongzhitanxiCARD"]  = 3.5

sgs.ai_skill_invoke.TH_guanglongzhitanxi = function(self, data)
	local da = q(data,"toDamage")
	return q(self,"isEnemy",da.to) and q(self,"TheWuhun",da.to) >= 0
end

sgs.ai_skillInvoke_intention.TH_guanglongzhitanxi = function(from, to, yesorno, self)
	if yesorno ~= "yes" then return end
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",from)) do
		if q(p,"hasFlag","TH_guanglongzhitanxi_target") then sgs.updateIntention(from, p, 10) end
	end
end

-- Fixed Touhou header4-16 dispatch for this one audited registry entry.
sgs.ai_choicemade_filter.skillInvoke.TH_guanglongzhitanxi=function(self,from,promptlist)
 local reason=string.gsub(promptlist[2],"%-","_")
 local f=self.room.getCurrent
 if type(f)~="function"then ai_unsupported("Current public player unavailable","getCurrent")end
 local to=f(self.room);if AIUnsupported.is(to)then error(to,0)end
 local callback=sgs.ai_skillInvoke_intention[reason]
 if callback then
  if type(callback)=="number" and promptlist[#promptlist]=="yes" and q(to,"objectName")~=q(from,"objectName")then
   sgs.updateIntention(from,to,sgs.ai_skillInvoke_intention[reason])
  elseif type(callback)=="function"then callback(from,to,promptlist[#promptlist],self)end
 end
end
end
-- End R49 Guanglong family.
