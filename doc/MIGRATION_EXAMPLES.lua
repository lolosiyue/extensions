-- Migration Example for scarletayuhuo.lua
-- This shows how to refactor existing extra turn skills using ExtraTurnUtils

require "ExtraTurnUtils"

-- =============================================================================
-- EXAMPLE 1: Simple refactoring (s2_houqi)
-- =============================================================================

-- OLD CODE (Lines 4362-4380):
--[[
s2_houqiGive = sgs.CreateTriggerSkill{
	name = "#s2_houqi-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s2_houqi") then
			local target = room:getTag("s2_houqi"):toPlayer()
			room:removeTag("s2_houqi")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}
]]

-- NEW CODE (3 lines):
s2_houqiGive = CreateExtraTurnGiveSkill(
	"#s2_houqi-give",
	"s2_houqi",
	sgs.Player_NotActive,
	1
)

-- =============================================================================
-- EXAMPLE 2: Refactoring with different phase (s2_andu)
-- =============================================================================

-- OLD CODE (Lines 8475-8495):
--[[
s2_anduGive = sgs.CreateTriggerSkill{
	name = "#s2_andu-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s2_andu") then
			local target = room:getTag("s2_andu"):toPlayer()
			room:removeTag("s2_andu")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)  -- NOTE: Different phase!
	end ,
	priority = 1
}
]]

-- NEW CODE:
s2_anduGive = CreateExtraTurnGiveSkill(
	"#s2_andu-give",
	"s2_andu",
	sgs.Player_Start,  -- Different trigger phase
	1
)

-- =============================================================================
-- EXAMPLE 3: Refactoring s2_jubing
-- =============================================================================

-- OLD CODE (Lines 7770-7790):
--[[
s2_jubingGive = sgs.CreateTriggerSkill{
	name = "#s2_jubing-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s2_jubingTarget") then
			local target = room:getTag("s2_jubingTarget"):toPlayer()
			room:removeTag("s2_jubingTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}
]]

-- NEW CODE:
s2_jubingGive = CreateExtraTurnGiveSkill(
	"#s2_jubing-give",
	"s2_jubingTarget",
	sgs.Player_NotActive,
	1
)

-- =============================================================================
-- EXAMPLE 4: Complex case with additional effects (from scarlet.lua)
-- =============================================================================

-- OLD CODE from scarlet.lua (Lines 10691-10711):
--[[
s4_s_xianneng_buff = sgs.CreateTriggerSkill{
	name = "#s4_s_xianneng_buff" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s4_s_xiannengTarget") then
			local target = room:getTag("s4_s_xiannengTarget"):toPlayer()
			room:removeTag("s4_s_xiannengTarget")
			if target and target:isAlive() then
                room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 1)
				target:gainAnExtraTurn()
                room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}
]]

-- NEW CODE using callbacks:
s4_s_xianneng_buff = CreateExtraTurnGiveSkill(
	"#s4_s_xianneng_buff",
	"s4_s_xiannengTarget",
	sgs.Player_NotActive,
	1,
	-- before_grant callback
	function(room, target)
		room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 1)
	end,
	-- after_grant callback
	function(room, target)
		room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 0)
	end
)

-- =============================================================================
-- EXAMPLE 5: Multiple players scenario (dongmanbao.lua Lines 7912-7913)
-- =============================================================================

-- OLD CODE - Multiple gainAnExtraTurn() calls:
--[[
if room:getAllPlayers(true):length() == 2 then
	mygod:gainAnExtraTurn()
	mygod:gainAnExtraTurn()
end
]]

-- NEW CODE - Using queue system:
if room:getAllPlayers(true):length() == 2 then
	QueueExtraTurn(room, mygod, 2)  -- Queue 2 extra turns
end

-- Then create the give skill once:
SE_ShenminGive = CreateExtraTurnGiveSkill(
	"#SE_Shenmin-give",
	"ExtraTurnQueue",  -- Use queue system
	sgs.Player_NotActive,
	1
)

-- =============================================================================
-- EXAMPLE 6: Multiple different players (hypothetical)
-- =============================================================================

-- Scenario: Skill grants extra turns to multiple players based on conditions

-- In your main skill:
s2_hypotheticalSkill = sgs.CreateTriggerSkill{
	name = "s2_hypotheticalSkill",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = {}
		
		-- Collect all valid targets
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:isWounded() then
				table.insert(targets, p)
			end
		end
		
		-- Schedule them all for extra turns (will be sorted by action order)
		if #targets > 0 then
			ScheduleMultipleExtraTurns(room, targets)
		end
		
		return false
	end
}

-- Create the give skill (single instance handles all)
s2_hypotheticalSkillGive = CreateExtraTurnGiveSkill(
	"#s2_hypotheticalSkill-give",
	"ExtraTurnQueue",
	sgs.Player_NotActive,
	1
)

-- =============================================================================
-- EXAMPLE 7: Complex - Different turn counts for different players
-- =============================================================================

s2_complexSkill = sgs.CreateTriggerSkill{
	name = "s2_complexSkill",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		
		-- Find targets
		local lord = room:getLord()
		local loyalists = {}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getRole() == "loyalist" then
				table.insert(loyalists, p)
			end
		end
		
		-- Lord gets 2 extra turns
		if lord and lord:isAlive() then
			QueueExtraTurn(room, lord, 2)
		end
		
		-- Each loyalist gets 1 extra turn
		for _, loyalist in ipairs(loyalists) do
			QueueExtraTurn(room, loyalist, 1)
		end
		
		-- All will be processed in action order
		
		return false
	end
}

s2_complexSkillGive = CreateExtraTurnGiveSkill(
	"#s2_complexSkill-give",
	"ExtraTurnQueue",
	sgs.Player_NotActive,
	1
)

-- =============================================================================
-- SUMMARY OF BENEFITS
-- =============================================================================

--[[
Lines of code saved per skill:
- Simple case: 19 lines → 6 lines (68% reduction)
- With callbacks: 21 lines → 12 lines (43% reduction)
- Multiple players: NEW FEATURE (impossible before without multiple skills)

Code quality improvements:
✓ Consistent error handling
✓ Automatic tag cleanup
✓ Alive check standardized
✓ Action order sorting for multiple players
✓ Single source of truth for extra turn logic
✓ Easy to test and maintain
✓ Reduces copy-paste errors

Migration effort:
- Low: Most cases are drop-in replacements
- Medium: Cases with additional effects need callback extraction
- Easy: Pattern is clear and consistent
]]
