-- Mode policy is owned by the loading Room VM. No Engine-global AI state or userdata
-- is exported to the isolated AI VM; evaluateModeAI returns primitive snapshot data.
if sgs.registerModeAI then return end

local policies, minds = {}, {}
local standard_modes = {}
-- Scenario admission is separate: an unregistered scenario still switches to
-- the donor managed wrapper when custom role enums are present.
local scenario_modes = {}
local function base_mode(world)
    return standard_modes[world.mode_id]~=nil
        or scenario_modes[world.mode_id]==true and world.custom_roles~=true
end
local generation = 0
local valid_relations = {friend=true, enemy=true, neutral=true, unknown=true}
local scores = {friend=-2, enemy=5, neutral=0, unknown=0}
local hook_names = {"relation", "objective", "rolePredictable", "gameProcess", "onIntention"}
local hook_errors = {
    relation="relation_hook", objective="objective_hook",
    rolePredictable="predictable_hook", gameProcess="process_hook",
    onIntention="intention_hook",
}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function policy_role(role, selector)
    assert(type(role) == "string" and role ~= "", "invalid policy role")
    if sgs.Sanguosha and not (selector and role == "unknown") then
        assert(sgs.Sanguosha:getRoleAbbreviation(role) ~= "", "unregistered policy role: "..role)
    end
    return role
end

-- Hooks often resolve the same IDs several times.  Keep the index ephemeral: it
-- is an evaluation detail and never becomes part of the exported world/state.
local active_indexes = setmetatable({}, {__mode="k"})
local readonly_worlds = setmetatable({}, {__mode="k"})
local function view_player(world, id)
    local index = active_indexes[world]
    if index then return index[id] end
    if world.self.object_name == id then return world.self end
    for _, player in ipairs(world.players) do
        if player.object_name == id then return player end
    end
end

local function snapshot_players(world)
    local players, index = {world.self}, {[world.self.object_name]=world.self}
    for _, player in ipairs(world.players) do
        if not index[player.object_name] then
            players[#players + 1], index[player.object_name] = player, player
        end
    end
    return players, index
end

local function known_role(player, state)
    -- Visible facts override this observer's estimates; never read a hidden role.
    if player.role_visible then return player.role end
    return state.inferred_roles and state.inferred_roles[player.object_name] or "unknown"
end

local function compile_objectives(spec, fallback)
    assert(type(spec) == "table", "objectiveByRole requires a table")
    local targets = {}
    for role, callback in pairs(spec) do
        policy_role(role, true)
        assert(type(callback) == "function" or finite(callback) and callback >= -5 and callback <= 5,
            "target objective requires a callback or a score from -5 to 5")
        targets[role] = callback
    end
    return function(world, target_id, state, process)
        local target = view_player(world, target_id)
        if not target then return nil end
        local callback = targets[known_role(target, state)]
        if type(callback) == "function" then return callback(world, target_id, state, process) end
        if callback ~= nil then return callback end
        -- Only an absent mapping falls back. An explicit callback returning nil
        -- leaves the score unspecified, just like the original objective hook.
        if fallback then return fallback(world, target_id, state, process) end
    end
end

local function compile_intentions(spec)
    assert(type(spec) == "table", "intentions requires a table")
    local ignored, rules, inference = {}, {}, {}
    for _, field in ipairs({"ignoreActors", "rules", "infer"}) do
        assert(spec[field] == nil or type(spec[field]) == "table", "invalid intentions."..field)
        local count = 0
        for key in pairs(spec[field] or {}) do
            assert(type(key) == "number" and key >= 1 and key % 1 == 0, "intentions."..field.." requires an array")
            count = count + 1
        end
        for index = 1, count do
            assert(spec[field][index] ~= nil, "sparse intentions."..field)
        end
    end
    for _, role in ipairs(spec.ignoreActors or {}) do
        ignored[policy_role(role, true)] = true
    end
    for _, rule in ipairs(spec.rules or {}) do
        assert(type(rule) == "table" and type(rule.update) == "function", "invalid intention rule")
        rules[#rules + 1] = {
            actor=rule.actor ~= nil and policy_role(rule.actor, true) or nil,
            target=rule.target ~= nil and policy_role(rule.target, true) or nil,
            update=rule.update,
        }
    end
    local seen = {}
    for _, candidate in ipairs(spec.infer or {}) do
        assert(type(candidate) == "table" and type(candidate.test) == "function", "invalid intention inference")
        local role = policy_role(candidate.role, false)
        assert(not seen[role], "duplicate intention inference role: "..role)
        seen[role] = true
        inference[#inference + 1] = {role=role, test=candidate.test}
    end

    return function(world, from_id, to_id, level, state)
        local from, to = view_player(world, from_id), view_player(world, to_id)
        if not from or not to then return end
        local actor, target = known_role(from, state), known_role(to, state)
        if ignored[actor] then return end
        local event = {from=from_id, to=to_id, actor_role=actor, target_role=target, level=level}
        local values = {}
        for key, value in pairs(state.role_values and state.role_values[from_id] or {}) do
            values[key] = value
        end
        local matched = false
        for _, rule in ipairs(rules) do
            if (rule.actor == nil or rule.actor == actor) and (rule.target == nil or rule.target == target) then
                rule.update(world, event, values, state)
                matched = true
            end
        end
        if not matched then return end
        local estimate
        if not from.role_visible then
            for _, candidate in ipairs(inference) do
                local accepted = candidate.test(world, event, values, state)
                assert(type(accepted) == "boolean", "intention inference must return boolean")
                if accepted then estimate = candidate.role break end
            end
        end
        for key, value in pairs(values) do
            assert(type(key) == "string" and finite(value), "intention evidence must contain finite numeric values")
        end
        -- Commit only after all selected rules and inference have succeeded. Callbacks
        -- may edit values; world, event and state are read-only by contract.
        state.role_values = state.role_values or {}
        state.inferred_roles = state.inferred_roles or {}
        state.role_values[from_id] = values
        state.inferred_roles[from_id] = estimate
    end
end

local function copy_hooks(spec, defaults)
    assert(type(spec) == "table", "mode/role AI requires a table")
    local copy = {}
    for _, name in ipairs(hook_names) do
        assert(spec[name] == nil or type(spec[name]) == "function", "invalid AI hook: "..name)
        copy[name] = spec[name]
    end
    if spec.intentions ~= nil then
        assert(spec.onIntention == nil, "choose intentions or onIntention at the same policy level")
        copy.onIntention = compile_intentions(spec.intentions)
    end
    if spec.objectiveByRole ~= nil then
        copy.objective = compile_objectives(spec.objectiveByRole, copy.objective or defaults and defaults.objective)
    end
    return copy
end

function sgs.registerModeAI(mode, spec)
    assert(type(mode) == "string" and mode ~= "", "mode AI requires a mode ID")
    assert(type(spec) == "table", "mode AI requires a table")
    local policy = copy_hooks(spec)
    policy.teams, policy.roles = {}, {}
    assert(spec.roles == nil or type(spec.roles) == "table", "AI roles must be a table")
    for role, hooks in pairs(spec.roles or {}) do
        assert(type(role) == "string" and role ~= "", "invalid AI role")
        if sgs.Sanguosha then
            assert(sgs.Sanguosha:getRoleAbbreviation(role) ~= "", "unregistered AI role: "..role)
        end
        policy.roles[role] = copy_hooks(hooks, policy)
    end
    assert(spec.teams == nil or type(spec.teams) == "table", "teams must be a table")
    for team, roles in pairs(spec.teams or {}) do
        assert(type(team) == "string" and team ~= "" and type(roles) == "table", "invalid team")
        for _, role in ipairs(roles) do
            assert(type(role) == "string" and role ~= "" and not policy.teams[role], "duplicate/invalid team role")
            if sgs.Sanguosha then
                assert(sgs.Sanguosha:getRoleAbbreviation(role) ~= "", "unregistered team role: "..role)
            end
            policy.teams[role] = team
        end
    end
    policies[mode] = policy
    scenario_modes[mode] = nil
    standard_modes[mode] = nil -- An author's replacement always takes precedence.
    minds[mode] = {} -- Definition replacement invalidates this VM's old inferred state.
    generation = generation + 1
end

-- The standard strategy uses the same observer minds and hook dispatcher as
-- extension modes. Public role counts and observer evidence drive the fixed
-- source policy; private foreign identities never enter the snapshot.
local function alive_in_order(world)
    local result, seen = {}, {}
    for _, name in ipairs(world.alive_player_order or {}) do
        local p = view_player(world, name)
        if p and p.alive then result[#result+1], seen[name] = p, true end
    end
    for _, p in ipairs(snapshot_players(world)) do
        if p.alive and not seen[p.object_name] then result[#result+1] = p end
    end
    return result
end

local function role_counts(world)
    local scenario=world.strategy_facts and world.strategy_facts.legacy_relation_kind=="scenario"
    if scenario then
        local public={lord=0,loyalist=0,rebel=0,renegade=0}
        local complete=true
        for _,p in ipairs(alive_in_order(world)) do
            if p.role_revealed~=true or p.role_visible~=true or public[p.role]==nil then complete=false;break end
            public[p.role]=public[p.role]+1
        end
        if complete then return public,false end
    end
    local counts = world.role_counts
    assert(type(counts) == "table", "standard role policy requires public role counts")
    for _, name in ipairs({"loyalist", "rebel", "renegade"}) do
        assert(finite(counts[name]) and counts[name] >= 0, "unknown public role count: "..name)
    end
    return counts,scenario==true
end

local function role_row(state, name)
    state.role_values = state.role_values or {}
    local row = state.role_values[name]
    if not row then row = {lord=0,loyalist=0,rebel=0,renegade=0}; state.role_values[name]=row end
    return row
end

-- evaluateAlivePlayersRole's sort, three passes and reverse correction, using
-- this observer's evidence. Authorized identities constrain the estimate; no
-- hidden native role or another AI's memory enters these rows.
local function standard_evaluate_roles(world, state)
    local counts, players = role_counts(world), alive_in_order(world)
    state.inferred_roles = state.inferred_roles or {}
    local roles = state.inferred_roles
    for _,p in ipairs(players) do
        assert(type(p.role_revealed)=="boolean","public role revelation is unknown")
        if p.role_revealed then assert(p.role_visible==true and type(p.role)=="string",
            "revealed role identity is not projected") end
    end
    for _, p in ipairs(players) do
        local missing = not (state.role_values and state.role_values[p.object_name])
        local row = role_row(state,p.object_name)
        if missing and p.role_visible and p.role=="lord" then row.lord=99999; row.loyalist=65535 end
    end
    table.sort(players,function(a,b) return role_row(state,a.object_name).loyalist > role_row(state,b.object_name).loyalist end)
    local rebel, loyalist, renegade = 0,0,0
    state.explicit_renegade = false
    for _, p in ipairs(players) do
        local role = p.role_revealed and p.role or "neutral"
        roles[p.object_name] = role == "lord" and "loyalist" or role
        if role == "loyalist" then loyalist=loyalist+1
        elseif role == "rebel" then rebel=rebel+1
        elseif role == "renegade" then renegade=renegade+1 end
    end
    for _, p in ipairs(players) do
        if not p.role_revealed then
            local row, role = role_row(state,p.object_name)
            if counts.rebel+counts.loyalist<1 then state.explicit_renegade=true; role="renegade"
            elseif counts.renegade+counts.loyalist<1 then role="rebel"
            elseif row.loyalist>3 and counts.loyalist>loyalist then role="loyalist"
            elseif row.loyalist< -5 and counts.rebel>rebel then role="rebel"
            elseif counts.renegade>renegade and row.loyalist> -15 and row.renegade>8 then
                state.explicit_renegade=row.renegade>(counts.rebel<1 and 25 or 40); role="renegade"
            end
            if role then
                roles[p.object_name]=role
                if role=="loyalist" then loyalist=loyalist+1 elseif role=="rebel" then rebel=rebel+1 else renegade=renegade+1 end
            end
        end
    end
    for _, p in ipairs(players) do
        if not p.role_revealed and roles[p.object_name]=="neutral" then
            local row=role_row(state,p.object_name)
            if loyalist<counts.loyalist and row.loyalist>0 then roles[p.object_name]="loyalist"; loyalist=loyalist+1
            elseif rebel<counts.rebel and row.loyalist<0 then roles[p.object_name]="rebel"; rebel=rebel+1
            elseif renegade<counts.renegade and row.renegade>5 then roles[p.object_name]="renegade"; renegade=renegade+1 end
        end
    end
    if rebel<counts.rebel then
        for i=#players,1,-1 do
            local p=players[i]; local row=role_row(state,p.object_name)
            if not p.role_revealed and roles[p.object_name]~="rebel" and row.loyalist< -5 and row.renegade>5 then
                row.loyalist=math.min(-row.renegade,row.loyalist); row.renegade=0
                roles[p.object_name]="rebel"; rebel=rebel+1
                if rebel>=counts.rebel then break end
            end
        end
    end
end

local function has_public_skill(player, name)
    for _, skill in ipairs(player.skills or {}) do
        if skill == name or type(skill)=="table" and (skill.name==name or skill.object_name==name) then return true end
    end
    return false
end

local function standard_lord(world)
    for _, p in ipairs(alive_in_order(world)) do if p.lord or p.role_visible and p.role=="lord" then return p end end
end

local function lord_hp(lord)
    local hp=lord.hp
    if hp>4 and has_public_skill(lord,"benghuai") then hp=4 end
    return hp
end

local function public_defense(world, player)
    -- The isolated sort cache belongs to a different VM. A documented public
    -- state estimate replaces that private cache, never a zero default.
    return player.hp*2 + (player.handcard_count or 0) + (player.hand_pile_count or 0)
end

local function standard_process(world, state)
    local counts, lord = role_counts(world), standard_lord(world)
    if counts.rebel<1 and counts.loyalist>0 then return 99,"loyalist" end
    if counts.loyalist<1 and counts.rebel>1 then return -99,"rebel" end
    local diff=(counts.loyalist+1-counts.rebel)*3
    for _, player in ipairs(alive_in_order(world)) do
        local role, hp=known_role(player,state),player.hp
        if hp>4 and has_public_skill(player,"benghuai") then hp=4 end
        if role=="rebel" then
            diff=diff-hp+math.max(public_defense(world,player)-hp*2,0)*0.5
            local rows=world.distances
            local distance=lord and rows and rows[player.object_name] and rows[player.object_name][lord.object_name]
            if finite(distance) and distance <= (player.attack_range or 1) then diff=diff-0.4 end
        elseif role=="loyalist" or role=="lord" then diff=diff+hp+math.max(public_defense(world,player)-hp*2,0)*0.5 end
    end
    local hp=lord and lord_hp(lord)
    local healthy=not lord or hp>3 or hp>2 and public_defense(world,lord)>3
    local danger=lord and hp<3
    local process="neutral"
    if diff>=4 then process=healthy and "loyalist" or "dilemma"
    elseif diff>=2 then process=healthy and "loyalish" or danger and "dilemma" or "rebelish"
    elseif diff<= -4 then process="rebel"
    elseif diff<= -2 then process=healthy and "rebelish" or "rebel"
    elseif not healthy then process="rebelish" end
    return diff,process
end

local function standard_objective_body(self,to,sgs,isRolePredictable,BeMan)
    local target_role -- the fixed donor reads an unset global; preserve nil
	--if type(to)~="userdata" then return 0 end
	if to:objectName()==self.player:objectName() then return -3 end
	local players = self.room:getAlivePlayers()
	players:removeOne(self.player)
	if players:length()<2 then
		if self.role~="renegade" and sgs.ai_role[to:objectName()]==sgs.ai_role[self.player:objectName()]
		then return -1 else return 5 end
	elseif self.player:getMark("revenge"..to:objectName())>0 then--报复仇恨
		self.player:removeMark("revenge"..to:objectName())
		return 3
	elseif isRolePredictable(true) then--明身份
		to = BeMan(self.room,to)
		if self.lua_ai:isFriend(to) then return -2
		elseif self.lua_ai:isEnemy(to) then return 5
		elseif self.lua_ai:relationTo(to)==sgs.AI_Neutrality
		and self.lua_ai:getEnemies():isEmpty() then return 4 end
	elseif self.player:getMark("roleRobot")>0 then--添加点随机仇恨
		self.player:removeMark("roleRobot")
		if sgs.ai_role[to:objectName()]==sgs.ai_role[self.player:objectName()]
		then return 4-to:getHp() end
	end
	-- Keep the original roster snapshot, but only convert it when the role
	-- evaluation continues past the common predictable-role early returns.
	players = sgs.QList2Table(players)
	-- Use cached gameProcess. Forcing update=true here made every
	-- objectiveLevel recompute defense for all alive players. updateIntention
	-- refreshes all AIs via updatePlayers, so that was O(n^3) per intention
	-- (lethal at 50p: ~10 turns/hour). Callers that need a fresh process
	-- already call sgs.gameProcess(true,true) / updatePlayers(true).
	local process = sgs.gameProcess()
	if self.role=="renegade" then
		if to:getRole()=="lord" and sgs.getMode~="couple" and to:hasFlag("Global_Dying")
		and not sgs.GetConfig("EnableHegemony",false) then return -2  end
		local lord = self.room:getLord()
		local lord_hp = lord and lord:getHp() or 4
		local lord_max_hp = lord and lord:getMaxHp() or 4
		local lord_lost_hp = lord_max_hp - lord_hp
		if sgs.playerRoles.loyalist<1 or sgs.playerRoles.rebel<1 then
			if sgs.playerRoles.rebel>0 then
				if sgs.playerRoles.rebel>1 then
					if to:getRole()=="lord" then return -2
					elseif sgs.ai_role[to:objectName()]=="rebel" then return 5 end
					return 0
				elseif sgs.playerRoles.renegade>1 then
					if to:getRole()=="lord" then return 0
					elseif sgs.ai_role[to:objectName()]=="renegade" then return 3 end
				else
					if process=="loyalist" then
						if to:getRole()=="lord" then
							return sgs.isLordHealthy() and 1 or -1
						elseif sgs.ai_role[to:objectName()]=="rebel" then return 0 end
					elseif process:find("rebel",1,true) then
						if sgs.ai_role[to:objectName()]~="rebel" then return -1 end
					elseif to:getRole()=="lord" then return 0 end
				end
			elseif sgs.playerRoles.loyalist>0 then
				if sgs.explicit_renegade and sgs.playerRoles.renegade>1
				and sgs.ai_role[self.player:objectName()]~="renegade"
				then return sgs.ai_role[to:objectName()]~="loyalist" and 5 or -1 end
				if to:getRole()=="lord" then
					if not sgs.explicit_renegade and sgs.roleValue[self.player:objectName()].renegade<30
					or not sgs.isLordHealthy() then return 0 else return 1 end
				elseif sgs.ai_role[to:objectName()]=="renegade" and sgs.playerRoles.renegade>1
				then return 3 end
			else
				if to:getRole()=="lord" then
					if sgs.isLordInDanger() then return 0
					elseif not sgs.isLordHealthy() then return 3 end
				elseif sgs.isLordHealthy() then return 3 end
				process = sgs.getDefense(to)
				return sgs.getDefense(self.player)<process and process or 0
			end
			return 5
		end
		if to:getRole()=="lord" then
			if lord_hp <= 1 then return -3
			elseif sgs.isLordInDanger() then return -2
			elseif lord_lost_hp >= 2 then
				if process:match("rebel") then return -2 else return -1 end
			elseif lord_lost_hp == 1 then
				if process:match("rebel") then return -1 else return 0 end
			else
				if sgs.isLordHealthy() then
					if process=="loyalist" or process=="loyalish" then return 1 end
				end
				return 0
			end
		end
		if target_role=="renegade" and sgs.playerRoles.renegade>1 then
			return 2
		end
		local rebel_hostility = 3
		local loyalist_hostility = 3
		if process=="rebel" then
			rebel_hostility = 5
			loyalist_hostility = 1
		elseif process=="rebelish" then
			rebel_hostility = 4
			loyalist_hostility = 2
		elseif process=="loyalist" then
			rebel_hostility = 1
			loyalist_hostility = 5
		elseif process=="loyalish" then
			rebel_hostility = 2
			loyalist_hostility = 4
		elseif process=="dilemma" then
			rebel_hostility = 5
			loyalist_hostility = 0
		else
			local power_diff = sgs.playerRoles.loyalist - sgs.playerRoles.rebel
			if power_diff > 0 then
				rebel_hostility = 2
				loyalist_hostility = 3
			elseif power_diff < 0 then
				rebel_hostility = 3
				loyalist_hostility = 2
			else
				rebel_hostility = 3
				loyalist_hostility = 3
			end
		end
		if lord_hp <= 2 then
			rebel_hostility = math.min(rebel_hostility + 2, 5)
			loyalist_hostility = math.max(loyalist_hostility - 1, 0)
		elseif lord_lost_hp >= 2 then
			rebel_hostility = math.min(rebel_hostility + 1, 5)
		end
		if sgs.turncount<2 and sgs.isLordHealthy() then
			rebel_hostility = math.max(rebel_hostility - 1, 1)
			loyalist_hostility = math.max(loyalist_hostility - 1, 1)
		end
		if target_role=="rebel" then
			return rebel_hostility
		elseif target_role=="loyalist" then
			return loyalist_hostility
		else
			if process:match("rebel") then return 2
			elseif process:match("loyal") then return 2
			else return self:getOverflow()>0 and 2 or 0 end
		end
	elseif self.player:getRole()=="lord" or self.role=="loyalist" then
		if to:getRole()=="lord" then return -2 end
		if self.role=="loyalist" and sgs.playerRoles.loyalist<2 and (sgs.playerRoles.renegade<1 or sgs.playerRoles.rebel<1)
		or sgs.playerRoles.loyalist+sgs.playerRoles.renegade<1 then return 5 end
		if sgs.ai_role[to:objectName()]=="neutral" then
			if sgs.playerRoles.rebel>0 then
				local fn,en,rn = 1,0,0
				for _,ap in sgs.qlist(self.player:getAliveSiblings())do
					if sgs.ai_role[ap:objectName()]=="loyalist" then fn = fn+1
					elseif sgs.ai_role[ap:objectName()]=="renegade" then rn = rn+1
					elseif sgs.ai_role[ap:objectName()]=="rebel" then en = en+1 end
				end
				local rebelish = process:find("rebel",1,true)
				local cr = sgs.getMode=="05p" or sgs.getMode=="07p" or sgs.getMode=="09p"
				if fn+((cr or rebelish) and rn or 0)>=sgs.playerRoles.loyalist+((rebelish or cr) and sgs.playerRoles.renegade or 0)+1
				then return self:getOverflow()>-1 and 5 or 3
				elseif en+(cr and rn or rebelish and 0 or rn)>=sgs.playerRoles.rebel+(cr and sgs.playerRoles.renegade or rebelish and 0 or sgs.playerRoles.renegade)
				then return -1
				elseif en<=1 and en/sgs.playerRoles.rebel<0.35
				and fn+((cr or rebelish) and rn or 0)+1==sgs.playerRoles.loyalist+((rebelish or cr) and sgs.playerRoles.renegade or 0)+1
				and self:getOverflow()>-1
				then return 1 end
			elseif sgs.explicit_renegade
			and sgs.playerRoles.renegade==1
			then return -1 end
		end
		self:sort(players,sgs.turncount<1 and "hp" or "chaofeng")
		if sgs.playerRoles.rebel<1 then
			if #players==2 and self.role=="loyalist" and to:getRole()~="lord" then return 5 end
			if self.player:getRole()=="lord" and not self.player:hasFlag("stack_overflow_jijiang")
			and players[1]==to then return 0 end
			if sgs.explicit_renegade then
				if self.player:getRole()=="lord" then
					if sgs.ai_role[to:objectName()]=="loyalist" then return -2
					elseif sgs.ai_role[to:objectName()]=="renegade" and sgs.roleValue[to:objectName()].renegade>50
					then return 5 else return to:getHp()>1 and 4 or 0 end
				else
					if self.role=="loyalist"
					and sgs.ai_role[self.player:objectName()]=="renegade" then
						for _,p in ipairs(players)do
							if sgs.roleValue[p:objectName()].renegade>0
							then return to:objectName()==p:objectName() and 5 or -2 end
						end
					else
						if sgs.ai_role[to:objectName()]=="loyalist"
						then return -2 end
					end
					return 4
				end
			else
				local maxhp = players[#players]:getRole()=="lord" and players[#players-1]:getHp() or players[#players]:getHp()
				if maxhp>2 then return to:getHp()>=maxhp and 5 or 0 end
				if maxhp==2 then return self.player:getRole()=="lord" and 0 or (to:getHp()>=maxhp and 5 or 1) end
				return self.player:getRole()=="lord" and 0 or 5
			end
		end
		if sgs.playerRoles.loyalist<1
		and sgs.ai_role[to:objectName()]=="renegade" then
			if sgs.playerRoles.rebel>2 then return -1
			elseif sgs.playerRoles.rebel>1 then return to:getHp()-1 end
			return sgs.isLordInDanger() and -1 or to:getHp()+1
		end
		local rn = 0
		for _,p in ipairs(players)do
			if sgs.ai_role[p:objectName()]=="rebel"
			then rn = rn+1 end
		end
		sgs.UnknownRebel = rn<sgs.playerRoles.rebel
		if sgs.playerRoles.renegade<1 then
			if sgs.ai_role[to:objectName()]=="loyalist" then return -2 end
			if sgs.playerRoles.rebel>0 and sgs.turncount>1 then
				if not sgs.UnknownRebel then
					rn = players[#players]:getRole()=="lord" and players[#players-1]:getHp() or players[#players]:getHp()
					if rn>2 then return to:getHp()>=rn and 5 or 0 end
					if rn==2 then return self.player:getRole()=="lord" and 0 or (to:getHp()>=rn and 5 or 1) end
					return self.player:getRole()=="lord" and 0 or 5
				end
			end
		end
		if sgs.ai_role[to:objectName()]=="rebel" then return 5
		elseif sgs.ai_role[to:objectName()]=="loyalist" then return -2
		elseif sgs.ai_role[to:objectName()]=="renegade" then
			if process:find("rebel",1,true) then return -2 end
			return sgs.isLordInDanger() and 0 or to:getHp()+1
		end
	elseif self.role=="rebel" then
		if sgs.playerRoles.loyalist+sgs.playerRoles.renegade<1
		then return to:getRole()=="lord" and 5 or -2 end
		if sgs.ai_role[to:objectName()]=="neutral" then
			local fn,en,rn = 1,0,0
			for _,ap in sgs.qlist(self.player:getAliveSiblings())do
				if sgs.ai_role[ap:objectName()]=="rebel" then fn = fn+1
				elseif sgs.ai_role[ap:objectName()]=="renegade" then rn = rn+1
				elseif sgs.ai_role[ap:objectName()]=="loyalist" then en = en+1 end
			end
			local loyalish = process:find("loyal",1,true)
			local cr = sgs.getMode=="05p" or sgs.getMode=="07p" or sgs.getMode=="09p"
			if fn+((cr or loyalish) and rn or 0)>=sgs.playerRoles.rebel+((cr or loyalish) and sgs.playerRoles.renegade or 0)
			then return self:getOverflow()>-1 and 5 or 3
			elseif en+(cr and rn or loyalish and 0 or rn)>=sgs.playerRoles.loyalist+(cr and sgs.playerRoles.renegade or loyalish and 0 or sgs.playerRoles.renegade)+1
			then return -1
			elseif sgs.playerRoles.loyalist+sgs.playerRoles.renegade>0
			and fn+((cr or loyalish) and rn or 0)+1==sgs.playerRoles.rebel+((cr or loyalish) and sgs.playerRoles.renegade or 0)
			and en<=1 and en/(sgs.playerRoles.loyalist+sgs.playerRoles.renegade)<0.35
			and self:getOverflow()>=0
			then return 1 end
		end
		if to:getRole()=="lord" then return 5
		elseif sgs.ai_role[to:objectName()]=="loyalist" then return 4 end
		if sgs.ai_role[to:objectName()]=="rebel" then
			return (sgs.playerRoles.rebel>1 or sgs.playerRoles.renegade>0 and process:find("loyal",1,true)) and -2 or 5
		elseif sgs.ai_role[to:objectName()]=="renegade" then
			if sgs.playerRoles.loyalist<1 then return to:getHp() end
			return process:find("loyal",1,true) and -1 or to:getHp()+1
		end
	end
	return 0
end

local function standard_classical(world)
    local counts=role_counts(world)
    return world.mode_id=="50p" or (counts.lord or 0)+counts.loyalist+counts.rebel+counts.renegade>16
        or world.mode_id=="02p" or world.mode_id:sub(3,3)~="p"
end

local function standard_predictable(world)
    if standard_classical(world) then return true end
    local configured=world.strategy_facts and world.strategy_facts.role_predictable_config
    assert(type(configured)=="boolean","public RolePredictable configuration is unknown")
    return configured
end

-- Source objectiveLevel uses only these methods. Wrappers contain snapshot
-- values, never native Players or another AI's private policy state.
local function objective_context(world, state, process)
    local estimates = {}
    local function estimate(key) estimates[key] = true end
    local wrapped, alive = {}, {}
    local function list(items)
        function items:removeOne(p) for i,v in ipairs(self) do if v==p then table.remove(self,i);return end end end
        function items:length() return #self end
        function items:isEmpty() return #self==0 end
        return items
    end
    local function mark_value(p,name)
        local offsets=state.strategy_mark_offsets and state.strategy_mark_offsets[p.object_name]
        local existing=state.strategy_marks and state.strategy_marks[p.object_name]
        local base=(p.public_marks and p.public_marks[name] or 0)+(existing and existing[name] or 0)
        local offset=offsets and offsets[name] or 0
        if base+offset<0 and offsets then
            -- An external native removal clamps the observed mark at zero;
            -- reconcile the consumed offset so later native additions survive.
            offsets[name]=-base
            offset=-base
        end
        return math.max(0,base+offset)
    end
    local function flag_value(p,name)
        local row=state.strategy_flags and state.strategy_flags[p.object_name]
        if row and row[name]~=nil then return row[name] end
        for _,flag in ipairs(p.flags or {}) do if flag==name then return true end end
        if name=="Global_Dying" and p.object_name~=world.self.object_name then
            local facts=world.strategy_facts or {}
            if type(facts.dying_players)=="table" then
                for _,id in ipairs(facts.dying_players) do if id==p.object_name then return true end end
            else estimate("mode.objective_public_dying_estimate");return p.hp<=0 end
        end
        return false
    end
    for _,p in ipairs(snapshot_players(world)) do
        local w={snapshot=p}
        wrapped[p.object_name]=w
        function w:objectName() return p.object_name end
        function w:getHp() return p.hp end
        function w:getMaxHp() return p.max_hp or p.hp end
        function w:getHujia() return p.hujia or 0 end
        function w:getRole() return p.lord and "lord" or p.role_visible and p.role or "unknown" end
        function w:hasFlag(name) return flag_value(p,name) end
        function w:getMark(name) return mark_value(p,name) end
        function w:removeMark(name)
            assert(p.object_name==world.self.object_name and (name=="roleRobot" or name:sub(1,7)=="revenge" and wrapped[name:sub(8)]),"invalid objective mark")
            state.strategy_mark_offsets=state.strategy_mark_offsets or {}
            local row=state.strategy_mark_offsets[p.object_name] or {}
            row[name]=(row[name] or 0)-1
            state.strategy_mark_offsets[p.object_name]=row
        end
        function w:getAliveSiblings()
            local r={};for _,other in ipairs(alive) do if other~=self then r[#r+1]=other end end;return list(r)
        end
    end
    for _,p in ipairs(alive_in_order(world)) do alive[#alive+1]=wrapped[p.object_name] end
    local counts,composition_prior=role_counts(world)
    if composition_prior then estimate("mode.scenario_public_composition_prior") end
    local classical=standard_classical(world)
    local local_sgs={ai_role={},roleValue=state.role_values or {},playerRoles=counts,getMode=world.mode_id,
        turncount=world.turn_count or 0,explicit_renegade=state.explicit_renegade,UnknownRebel=state.unknown_rebel,AI_Neutrality="neutral"}
    for name,w in pairs(wrapped) do
        local role=state.inferred_roles and state.inferred_roles[name] or known_role(w.snapshot,state)
        local_sgs.ai_role[name]=role=="lord" and "loyalist" or role=="unknown" and "neutral" or role
        local_sgs.roleValue[name]=local_sgs.roleValue[name] or {loyalist=0,renegade=0}
    end
    local_sgs.qlist=ipairs
    local_sgs.QList2Table=function(t) return t end
    local_sgs.gameProcess=function() return process and process.label or "neutral" end
    local_sgs.GetConfig=function(_,default) return default end -- identity mode only
    local_sgs.getDefense=function(w) estimate("mode.objective_public_defense");return public_defense(world,w.snapshot) end
    local lord=standard_lord(world)
    local_sgs.isLordHealthy=function()
        if not lord then return true end
        local hp=lord_hp(lord)
        return hp>3 or hp>2 and local_sgs.getDefense(wrapped[lord.object_name])>3
    end
    local_sgs.isLordInDanger=function() return lord~=nil and lord_hp(lord)<3 end
    local own=world.self
    local self={player=wrapped[own.object_name],role=state.owner_role or (own.role_visible and own.role or known_role(own,state)),room={},lua_ai={}}
    function self.room:getAlivePlayers() local r={};for _,p in ipairs(alive) do r[#r+1]=p end;return list(r) end
    function self.room:getLord() return lord and wrapped[lord.object_name] end
    function self:getOverflow()
        local hand=assert(own.handcard_count,"unknown owner hand count")
        local m=assert(own.max_cards,"unknown owner max cards")
        local function skill(name) return has_public_skill(own,name) end
        local keji=skill("keji") and not flag_value(own,"KejiSlashInPlayPhase")
        if skill("qiaobian") then m=math.max(hand-1,m) end
        if keji or skill("zaoyao") then m=hand end
        if (own.phase or 7)<6 and skill("yongsi") and not keji and not skill("conghui") then
            local kingdoms={};local count=0
            for _,p in ipairs(alive_in_order(world)) do
                local kingdom=p.kingdom
                if not kingdom or kingdom=="" or kingdom=="unknown" then estimate("mode.objective_yongsi_public_kingdoms")
                elseif not kingdoms[kingdom] then kingdoms[kingdom]=true;count=count+1 end
            end
            if count>0 then local cards=hand+#(own.equips or {});m=cards>count and math.min(m,cards-count) or 0 end
        end
        if skill("heg_keji") and mark_value(own,"heg_keji-Clear")==0 then m=hand end
        local ignored=world.strategy_facts and world.strategy_facts.owner_ignore_limit_count
        assert(finite(ignored),"unknown owner MethodIgnore count")
        return hand-m-ignored
    end
    function self:sort(players,key)
        if #players<2 then return players end
        estimate("mode.objective_public_defense_sort")
        table.sort(players,function(a,b)
            if key=="hp" then
                local va,vb=a:getHp()+a:getHujia(),b:getHp()+b:getHujia()
                if va~=vb then return va<vb end
            end
            return local_sgs.getDefense(a)<local_sgs.getDefense(b)
        end)
        return players
    end
    local function relation(to)
        if to==wrapped[world.self.object_name] then return "friend" end
        local facts=world.strategy_facts or {}
        local kind=facts.legacy_relation_kind
        assert(kind=="scenario" or kind=="role_prefix" or kind=="public_hegemony" or kind=="identity_balance",
            "native relation rule family is unknown")
        if kind=="scenario" then
            local scenario=facts.legacy_scenario_relation
            assert(type(scenario)=="table" and (scenario.kind=="identity_balance" or scenario.kind=="guandu"
                or scenario.kind=="zombie" or scenario.kind=="couple"),"audited scenario relation rule is unknown")
            local function role(p)
                if not p.role_visible then estimate("mode.scenario_hidden_role_prior") end
                return known_role(p,state)
            end
            if scenario.kind=="couple" then
                local spouse=scenario.spouse
                assert(spouse==nil or spouse==false or type(spouse)=="string" and wrapped[spouse],
                    "public scenario spouse is malformed")
                if spouse==nil then estimate("mode.scenario_spouse_unobserved_prior") end
                if spouse==to:objectName() then return "friend" end
                -- Source's asymmetric lord tests deliberately do not commute.
                if role(own)=="lord" then
                    assert(finite(own.gender) and finite(to.snapshot.gender),"scenario public gender is unknown")
                    if own.gender~=to.snapshot.gender then return "neutral" end
                elseif role(to.snapshot)=="lord" then
                    assert(finite(own.hp) and finite(to.snapshot.hp),"scenario public hp is unknown")
                    if own.hp>=to.snapshot.hp then return "neutral" end
                end
                return "enemy"
            elseif scenario.kind=="zombie" then
                local a,b=role(own),role(to.snapshot)
                -- An unobserved identity is a marked human/zombie prior, not
                -- authority to inspect the foreign role enum.
                local ah=a=="lord" or a=="loyalist"
                local bh=b=="lord" or b=="loyalist"
                return ah==bh and "friend" or "enemy"
            elseif scenario.kind=="guandu" then
                if role(own)=="renegade" and role(to.snapshot)=="renegade" then return "friend" end
            end
            -- Scenario's inherited implementation and Guandu's remaining arm
            -- use AI::GetRelation, not Hegemony/3v3 global-mode routing.
            kind="identity_balance"
        end
        if kind=="role_prefix" then
            local a,b=own.role_visible and own.role or known_role(own,state),known_role(to.snapshot,state)
            if not to.snapshot.role_visible then estimate("mode.native_role_prefix_hidden_role_prior") end
            -- Unknown is the explicit neutral prior, never a fabricated role.
            if a=="unknown" or a=="neutral" or b=="unknown" or b=="neutral" then return "neutral" end
            assert(type(a)=="string" and #a>0 and type(b)=="string" and #b>0,"native role prefix is unknown")
            return a:sub(1,1)==b:sub(1,1) and "friend" or "enemy"
        end
        if kind=="public_hegemony" then
            local public=facts.public_revealed_relationships
            local hegemony=facts.hegemony
            assert(type(public)=="table" and type(public.friends)=="table"
                and type(hegemony)=="table" and type(hegemony.players)=="table",
                "public hegemony relationship projection is unknown")
            local function faction(p)
                local row=hegemony.players[p.object_name]
                assert(type(row)=="table" and type(row.public_kingdom)=="string",
                    "native public seeming kingdom is unknown")
                return row.public_kingdom
            end
            local a,b=faction(own),faction(to.snapshot)
            if a=="" or a=="unknown" or a=="god" or b=="" or b=="unknown" or b=="god" then return "neutral" end
            local row=public.friends[own.object_name]
            assert(type(row)=="table" and type(row[to:objectName()])=="boolean","public hegemony alliance is unknown")
            if row[to:objectName()] then return "friend" end
            if a=="careerist" or b=="careerist" then return "enemy" end
            return a==b and "friend" or "enemy"
        end
        local a,b=own.role_visible and own.role or known_role(own,state),known_role(to.snapshot,state)
        if not to.snapshot.role_visible then estimate("mode.objective_predictable_hidden_role") end
        local good=(counts.lord or 0)+counts.loyalist-counts.rebel
        if good>0 then
            if a=="renegade" and b=="loyalist" then return "enemy" end
            if a=="renegade" and b=="rebel" then return "friend" end
            if a=="renegade" and b=="lord" or a=="lord" and b=="renegade" then return "neutral" end
        elseif good<0 then
            if a=="renegade" and b=="rebel" or a=="rebel" and b=="renegade" then return "enemy" end
            if a=="renegade" and b=="loyalist" or a=="loyalist" and b=="renegade" then return "neutral" end
        end
        if a=="renegade" then return b=="lord" and "friend" or "neutral" end
        if b=="renegade" then return "neutral" end
        local camps={lord="court",loyalist="court",rebel="rebel"}
        return camps[a] and camps[b] and (camps[a]==camps[b] and "friend" or "enemy") or "neutral"
    end
    function self.lua_ai:isFriend(to) return to==wrapped[world.self.object_name] or relation(to)=="friend" end
    function self.lua_ai:isEnemy(to) return relation(to)=="enemy" end
    function self.lua_ai:relationTo(to) return relation(to) end
    function self.lua_ai:getEnemies() local r={};for _,p in ipairs(alive) do if p~=self.player and relation(p)=="enemy" then r[#r+1]=p end end;return list(r) end
    return self,wrapped,local_sgs,function() return classical end,function(_,p) return p end,estimates
end

local function standard_objective(world, target_id, state, process)
    local self,wrapped,local_sgs,predictable,be_man,estimates=objective_context(world,state,process)
    local target=wrapped[target_id]
    if not target then return nil end
    -- The wrapper installed at smart-ai.lua:2030 precedes the original method.
    if target_id~=world.self.object_name and world.self.controller==target_id then return -2,estimates end
    local value=standard_objective_body(self,target,local_sgs,predictable,be_man)
    state.unknown_rebel=local_sgs.UnknownRebel
    return value,estimates
end

-- updatePlayers stores friends/enemies. isFriend/isEnemy read these lists;
-- they must not repeatedly consume objectiveLevel's observational marks.
local standard_adjust_roles
local function standard_refresh_relations(world,state,to_use_count,refresh_process)
    local own_role=world.self.role_visible and world.self.role or known_role(world.self,state)
    if state.owner_role~=nil and state.owner_role~=own_role and own_role~="lord" then
        local values=role_row(state,world.self.object_name)
        values.loyalist,values.renegade,values.rebel=0,0,0
    end
    state.owner_role=own_role
    if refresh_process or not state.cached_process then
        local value,label=standard_process(world,state)
        state.cached_process={value=value,label=label}
    end
    if not standard_classical(world) and world.strategy_facts and world.strategy_facts.role_predictable_config
        and state.inferred_roles and state.inferred_roles[world.self.object_name]~=own_role and own_role~="lord" then
        standard_adjust_roles(world,state)
    end
    local self,wrapped,local_sgs,predictable,_,estimates=objective_context(world,state,state.cached_process)
    local row,neutral,enemies={},{},0
    for _,p in ipairs(alive_in_order(world)) do
        local name=p.object_name
        local relation
        if predictable() then
            relation=name==world.self.object_name and "friend" or self.lua_ai:relationTo(wrapped[name])
        else
            local value,used=standard_objective(world,name,state,state.cached_process)
            relation=value<0 and "friend" or value>0 and "enemy" or "neutral"
            for key in pairs(used) do estimates[key]=true end
        end
        row[name]=relation
        if relation=="enemy" then enemies=enemies+1 elseif relation=="neutral" then neutral[#neutral+1]=wrapped[name] end
    end
    if enemies<#neutral then
        local promote=predictable()
        if not promote then
            if to_use_count==nil then
                -- The other VM has not supplied this observer's previous plan.
                -- Empty prior is explicit and cannot be confused with exact data.
                to_use_count=0;estimates["mode.update_players_owner_plan_cache_prior"]=true
            end
            promote=to_use_count<3 and self:getOverflow()>0
        end
        if promote then
            table.sort(neutral,function(a,b)return local_sgs.getDefense(a)<local_sgs.getDefense(b)end)
            row[neutral[predictable() and 1 or #neutral]:objectName()]="enemy"
        end
    end
    if state.harsh_retain==nil then state.harsh_retain=true end
    if predictable() then state.harsh_retain=false end
    state.relation_row=row
    state.relation_estimates=estimates
    return row,estimates
end

local function initialize_base_role_cache(world,state)
    if state.base_role_cache_initialized then return end
    state.role_values=state.role_values or {}
    state.inferred_roles=state.inferred_roles or {}
    state.base_role_cache_estimates=state.base_role_cache_estimates or {}
    -- A first observed cache is later than source VM initialization. Do not
    -- claim that previously changed roles or private VM history were observed.
    state.base_role_cache_estimates["mode.base_late_role_cache_initialization"]=true
    for _,p in ipairs(snapshot_players(world)) do
        if state.inferred_roles[p.object_name]==nil then
            local role=known_role(p,state)
            local values=role_row(state,p.object_name)
            state.inferred_roles[p.object_name]="neutral"
            if role=="lord" then
                values.lord,values.loyalist=99999,65535
                state.inferred_roles[p.object_name]="loyalist"
            elseif standard_predictable(world) then
                if p.role_visible and role~="unknown" and role~="neutral" then
                    values[role]=65535;state.inferred_roles[p.object_name]=role
                    if role=="renegade" then state.explicit_renegade=true end
                else state.base_role_cache_estimates["mode.base_initial_hidden_role_prior"]=true end
            end
        end
    end
    if state.owner_role==nil then state.owner_role=world.self.role end -- source initialize sets this before updatePlayers(false)
    state.base_role_cache_initialized=true
end

-- Explicit SmartAI:updatePlayers calls retain their own source lifecycle. The
-- Activate constructor's narrower refresh above remains a separate operation.
local function standard_update_players(world,state,to_use_count,update)
    assert(finite(to_use_count) and to_use_count>=0 and to_use_count%1==0,"invalid owner plan count")
    assert(type(update)=="boolean","invalid updatePlayers update flag")
    local own_role=world.self.role_visible and world.self.role
    assert(own_role=="lord" or own_role=="loyalist" or own_role=="rebel" or own_role=="renegade",
        "owner role is not disclosed")
    if state.owner_role~=own_role then
        if own_role~="lord" then
            local values=role_row(state,world.self.object_name)
            values.loyalist,values.renegade,values.rebel=0,0,0
        end
        state.owner_role=own_role
    end
    -- Counts are supplied by the lawful current roster projection on every
    -- call, including update=false; no cached role count can shadow this read.
    local _,composition_prior=role_counts(world)
    local estimates={}
    if composition_prior then estimates["mode.scenario_public_composition_prior"]=true end
    for key in pairs(state.base_role_cache_estimates or {}) do estimates[key]=true end
    if update or not state.cached_process then
        local value,label=standard_process(world,state)
        state.cached_process={value=value,label=label}
        estimates["mode.game_process_public_defense"]=true
    end
    local classical=standard_classical(world)
    if not classical then
        local configured=world.strategy_facts and world.strategy_facts.role_predictable_config
        assert(type(configured)=="boolean","public RolePredictable configuration is unknown")
        if configured then
            if (not state.inferred_roles or state.inferred_roles[world.self.object_name]~=own_role)
                and own_role~="lord" then standard_adjust_roles(world,state) end
        elseif update then
            -- No mutable QList cache crosses this boundary. Rebuild the alive
            -- array inside the evaluator at the same source refresh position.
            standard_evaluate_roles(world,state)
        end
    end
    if state.adjust_role_inferred then estimates["mode.adjust_hidden_role_inference"]=true end
    local self,wrapped,local_sgs,_,_,used=objective_context(world,state,state.cached_process)
    local row,neutral,friends,friends_noself,enemies={},{},{},{},{}
    for _,p in ipairs(alive_in_order(world)) do
        local name=p.object_name
        local relation
        if classical then
            -- Keep the original friend / enemy / neutrality predicate order.
            if self.lua_ai:isFriend(wrapped[name]) then relation="friend"
            elseif self.lua_ai:isEnemy(wrapped[name]) then relation="enemy"
            elseif self.lua_ai:relationTo(wrapped[name])==local_sgs.AI_Neutrality then relation="neutral" end
        else
            local value,branches=standard_objective(world,name,state,state.cached_process)
            assert(finite(value),"invalid updatePlayers objective")
            relation=value<0 and "friend" or value>0 and "enemy" or "neutral"
            for key in pairs(branches) do estimates[key]=true end
        end
        row[name]=relation
        if relation=="friend" then
            friends[#friends+1]=name
            if name~=world.self.object_name then friends_noself[#friends_noself+1]=name end
        elseif relation=="enemy" then enemies[#enemies+1]=name
        elseif relation=="neutral" then neutral[#neutral+1]=wrapped[name] end
    end
    if state.harsh_retain==nil then state.harsh_retain=true end -- source initialize
    if classical then state.harsh_retain=false end
    if #enemies<#neutral and (classical or to_use_count<3 and self:getOverflow()>0) then
        table.sort(neutral,function(a,b)return local_sgs.getDefense(a)<local_sgs.getDefense(b)end)
        local selected=neutral[classical and 1 or #neutral]:objectName()
        row[selected]="enemy"
        enemies[#enemies+1]=selected -- promoted neutral is appended, not roster-reordered
    end
    for key in pairs(used) do estimates[key]=true end
    state.relation_row,state.relation_estimates=row,estimates
    state.relation_friends,state.relation_friends_noself,state.relation_enemies=friends,friends_noself,enemies
    return estimates
end

local function standard_refresh_after_intention(world,state,actor)
    if #alive_in_order(world)<=16 or actor==world.self.object_name then
        standard_refresh_relations(world,state,nil,true)
    else
        -- Fixed source's large-room path refreshes only the acting AI's lists.
        local value,label=standard_process(world,state)
        state.cached_process={value=value,label=label}
    end
end

local function standard_relation(world, from_id, to_id, state)
    local from, to = view_player(world, from_id), view_player(world, to_id)
    if not from or not to then return nil end
    if from_id == world.self.object_name then return state.relation_row and state.relation_row[to_id] end
    local a, b = known_role(from, state), known_role(to, state)
    local camps = {lord="court", loyalist="court", rebel="rebel"}
    if camps[a] and camps[b] then return camps[a] == camps[b] and "friend" or "enemy" end
    -- Renegade policy depends on the observing player's own objective. Do not
    -- transplant that objective to another player's relation row.
    return nil
end

local function intention_can_chat(world, player)
    -- AIChat ignores the AIChat configuration flag. Humanization and the
    -- configured delay are its actual gates; nonrobots return nil in the donor.
    local policy = world.response_policy or {}
    local humanized = policy.humanized
    if humanized == nil then humanized = world.ai_humanized end
    if humanized == false then return false end
    assert(type(player.state)=="string", "intention speaker state is unknown")
    if player.state~="robot" then return false end
    assert(finite(policy.origin_ai_delay), "intention speech delay is unknown")
    if policy.origin_ai_delay<=0 then return false end
    assert(type(humanized)=="boolean", "intention speech humanization is unknown")
    return humanized
end

local function standard_intention(world, from_id, to_id, level, state, defer_refresh, presentation, position)
    local from,to=view_player(world,from_id),view_player(world,to_id)
    if not from or not to or from_id==to_id then return end
    -- Donor math.random(0.3,0.5) throws in this authority's Lua 5.4 after
    -- consuming one draw. Explicitly authorized repair: one uniform draw.
    level=level*(0.3+math.random()*0.2)
    state.donor_intention_random_repaired=true
    local counts=role_counts(world)
    if not state.inferred_roles then standard_evaluate_roles(world,state) end
    local actor,target=known_role(from,state),known_role(to,state)
    local function revenge(divisor)
        -- Only this observer's revenge affects its future objective calls.
        -- Preserve setMark's integer conversion, reset prior consumption, and
        -- retain later native additions via a baseline-relative shadow.
        if to_id~=world.self.object_name then return end
        local key="revenge"..from_id
        state.strategy_marks=state.strategy_marks or {}
        local marks=state.strategy_marks[to_id] or {}
        marks[key]=math.floor(level/divisor)-(to.public_marks and to.public_marks[key] or 0)
        state.strategy_marks[to_id]=marks
        local offsets=state.strategy_mark_offsets and state.strategy_mark_offsets[to_id]
        if offsets then offsets[key]=nil end
    end
    local function say(lines)
        assert(type(presentation)=="table", "intention speech needs a staged presentation sink")
        assert(#presentation<128,"too many mode presentation effects")
        presentation[#presentation+1]={kind="speech",player=to_id,text=lines[math.random(1,#lines)],
            source_key="mode:updateIntention",after_delta=position or 0}
    end
    if actor=="lord" then
        -- The chance draw precedes AIChat even when chatter is disabled.
        if level>0 and target~="rebel" and math.random()<0.2
            and intention_can_chat(world,to) and role_row(state,to_id).loyalist>-level/2 then
            local lines={"。。。。。。","我特么....","<#"..math.random(1,56).."#>",
                "<#"..math.random(1,56).."#>","<#44#>","小心我跳反！"}
            assert(finite(from.phase),"intention actor phase is unknown")
            if from.phase<=sgs.Player_Play then
                table.insert(lines,"不要乱来啊");table.insert(lines,"主公别乱打啊");table.insert(lines,"盲狙轻点....")
            end
            if level>22 then
                table.insert(lines,"<#20#>");table.insert(lines,"主公你这样就不好了");table.insert(lines,"你乱来，就不要怪我乱来了")
                revenge(3)
            end
            say(lines)
        end
        return
    end
    if target=="neutral" or target=="unknown" then
        if level>0 and intention_can_chat(world,to) then
            if target==actor then
                if math.random()<0.3 then
                    local lines={"嗯？","。。。。","<#"..math.random(1,56).."#>",
                        "<#"..math.random(1,56).."#>","<#12#>","我记下了"}
                    assert(finite(from.phase),"intention actor phase is unknown")
                    if from.phase<=sgs.Player_Play then
                        table.insert(lines,"警告你");table.insert(lines,"喂喂喂！");table.insert(lines,"我特么....")
                    end
                    if level>22 then
                        table.insert(lines,"你等着！");table.insert(lines,"乱来是吧");table.insert(lines,"找茬是吧");table.insert(lines,"<#19#>")
                        revenge(2)
                    end
                    say(lines)
                end
            elseif math.random()<0.2 then
                local lines={"看好身份","<#"..math.random(1,56).."#>","<#"..math.random(1,56).."#>",
                    "<#6#>","<#44#>","。。。。"}
                assert(finite(from.phase),"intention actor phase is unknown")
                if from.phase<=sgs.Player_Play then
                    table.insert(lines,"点读机是吧");table.insert(lines,"我招你惹你了....");table.insert(lines,"我特么....")
                end
                if level>22 then
                    table.insert(lines,"你等着！");table.insert(lines,"你歌姬吧");table.insert(lines,"*****");table.insert(lines,"<#7#>");table.insert(lines,"<#15#>")
                    revenge(2)
                end
                say(lines)
            end
        end
        return
    end
    local values=role_row(state,from_id)
    if target=="rebel" then
        values.loyalist=values.loyalist+level
        if counts.renegade>0 and (actor~="loyalist" and level>0 or actor~="rebel" and level<0) then values.renegade=values.renegade+math.abs(level) end
    else
        local unknown=state.unknown_rebel
        if not (target~="lord" and (unknown or values.renegade>0 and not state.explicit_renegade)) and counts.rebel+counts.renegade>0 then values.loyalist=values.loyalist-level end
        if counts.renegade>0 then
            if unknown and level>0 and counts.loyalist>0 then
            elseif target~="lord" and not state.explicit_renegade and counts.rebel<1 and counts.loyalist>0 then
            elseif actor~="rebel" and level>0 or actor~="loyalist" and level<0 then values.renegade=values.renegade+math.abs(level) end
        end
    end
    state.intention_needs_refresh=true
    state.intention_refresh_actor=from_id
    if not defer_refresh then
        standard_evaluate_roles(world,state)
        standard_refresh_after_intention(world,state,from_id)
        state.intention_needs_refresh,state.intention_refresh_actor=nil,nil
    end
end

-- Pure value counterpart for focused differential validation and mode authors.
sgs.evaluateStandardRoleEvidence=standard_evaluate_roles

standard_adjust_roles=function(world,state)
    state.explicit_renegade=false
    state.inferred_roles=state.inferred_roles or {}
    for _, player in ipairs(alive_in_order(world)) do
        local role=known_role(player,state)
        if role~="lord" then
            local values=role_row(state,player.object_name)
            values.renegade=0
            if not player.role_visible then state.adjust_role_inferred=true end
            if role=="renegade" then state.explicit_renegade=true end
            -- Preserve the donor's misspelled field; changing it would repair
            -- another behavior, beyond the explicitly authorized RNG repair.
            if role=="rebel" then values.loaylist=-65535
            elseif role=="loyalist" or role=="renegade" then values[role]=65535 end
            state.inferred_roles[player.object_name]=role
        end
    end
end

function sgs.registerStandardModeAI(mode, normal_identity, hegemony, scenario)
    if policies[mode] then return false end
    -- Native admission supplies the existing normal-mode classification. Kingdom
    -- and scenario victory policies need their own explicit mode registration.
    if hegemony then
        -- Role visibility is the authorization boundary.  A public careerist
        -- recruitment can be known while its kingdom field is still empty.
        local function faction(player)
            if not player.role_visible then return nil end
            local role = player.role
            if type(role) == "string" and (role == "careerist" or role:match("^careerist_")) then
                return role
            end
            local kingdom = player.kingdom
            if type(kingdom) == "string" and kingdom ~= "" and kingdom ~= "unknown" and kingdom ~= "god" then
                return kingdom
            end
        end
        sgs.registerModeAI(mode, {relation=function(world, from_id, to_id)
            if from_id == to_id then return "friend" end
            local from, to = view_player(world, from_id), view_player(world, to_id)
            if not from or not to then return "unknown" end
            local a, b = faction(from), faction(to)
            if not a or not b then return "neutral" end
            if a == "careerist" or b == "careerist" then return "enemy" end
            return a == b and "friend" or "enemy"
        end})
        return true
    end
    if scenario==true then
        scenario_modes[mode]=true
        generation=generation+1
        return true
    end
    local fixed_teams = {
        ["02_1v1"]={first={"lord"}, second={"renegade"}},
        ["03_1v2"]={first={"lord"}, second={"rebel"}},
        ["04_1v3"]={first={"lord"}, second={"rebel"}},
        ["04_boss"]={first={"lord"}, second={"rebel"}},
        ["04_2v2"]={first={"loyalist"}, second={"rebel"}},
        ["05_ol"]={first={"lord", "loyalist"}, second={"rebel"}},
        ["06_ol"]={first={"lord", "loyalist"}, second={"rebel"}},
        ["08_defense"]={first={"loyalist"}, second={"rebel"}},
    }
    if fixed_teams[mode] then
        sgs.registerModeAI(mode, {teams=fixed_teams[mode]})
    elseif normal_identity then
        sgs.registerModeAI(mode, {relation=standard_relation,
            objective=standard_objective, gameProcess=standard_process,rolePredictable=standard_predictable,
            onIntention=standard_intention})
    else
        return false
    end
    standard_modes[mode] = normal_identity and not fixed_teams[mode] and "identity" or true
    return true
end

local function mind(mode, viewer)
    minds[mode] = minds[mode] or {}
    minds[mode][viewer] = minds[mode][viewer] or {}
    return minds[mode][viewer]
end

local function invoke(policy, name, world, ...)
    if not policy then return true, nil end
    -- Dispatch by the observer's known identity, never by a hidden target identity.
    local role_policy = world.self.role_visible and policy.roles[world.self.role]
    local callback = role_policy and role_policy[name] or policy[name]
    if not callback then return true, nil end
    local ok, value, extra = pcall(callback, readonly_worlds[world] or world, ...)
    local error_class
    if not ok then error_class = hook_errors[name] end
    return ok, value, extra, error_class
end

local function clone_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do copy[clone_value(key, seen)] = clone_value(item, seen) end
    return copy
end

local function valid_state(value, seen, depth, budget)
    budget = budget or {remaining=1024}
    budget.remaining = budget.remaining - 1
    if budget.remaining < 0 then return false end
    if value == nil or type(value) == "string" or type(value) == "boolean" then return true end
    if type(value) == "number" then return finite(value) end
    if type(value) ~= "table" or getmetatable(value) ~= nil then return false end
    depth = depth or 0
    if depth > 6 then return false end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if (type(key) ~= "string" and type(key) ~= "number")
            or not valid_state(key, seen, depth + 1, budget)
            or not valid_state(item, seen, depth + 1, budget) then return false end
    end
    seen[value] = nil
    return true
end

-- Completed public flag clears survive subsequent policy rejection. Each viewer
-- independently acknowledges the monotonic native epochs before any query reads
-- its shadow flags. Replacing one cloned mind commits clear+ack atomically.
local function synchronize_mark_mind(world,epoch_key,mark_names)
    local epochs=world.strategy_facts and world.strategy_facts[epoch_key]
    if epochs==nil then return end -- Old snapshots cannot authorize new epoch-dependent helpers.
    assert(type(epochs)=="table" and getmetatable(epochs)==nil,"invalid play-clear epochs")
    local original=mind(world.mode_id,world.self.object_name)
    local applied=original[epoch_key] or {}
    local state
    for name,epoch in pairs(epochs) do
        local previous=applied[name] or 0
        assert(view_player(world,name) and finite(epoch) and epoch%1==0 and epoch>=previous,"invalid play-clear epoch")
        if epoch>previous then
            state=state or clone_value(original)
            local marks=state.strategy_marks and state.strategy_marks[name]
            if marks then for _, mark_name in ipairs(mark_names) do marks[mark_name]=nil end end
        end
    end
    if state then
        state[epoch_key]=clone_value(epochs)
        minds[world.mode_id][world.self.object_name]=state;generation=generation+1
    end
end
local function synchronize_flag_mind(world)
    synchronize_mark_mind(world,"strategy_play_clear_epochs",{"yhpodi_to-PlayClear"})
    synchronize_mark_mind(world,"strategy_turn_clear_epochs",{"AI_fangjian-Clear","AI_do_not_invoke_s2_longwei-Clear"})
    local epochs = world.strategy_facts and world.strategy_facts.strategy_flag_clear_epochs
    assert(type(epochs) == "table" and getmetatable(epochs) == nil, "invalid strategy flag-clear epochs")
    local _, roster = snapshot_players(world)
    for name, epoch in pairs(epochs) do
        assert(type(name) == "string" and roster[name] and finite(epoch) and epoch >= 0
            and epoch <= 9007199254740991 and epoch % 1 == 0, "invalid strategy flag-clear epoch")
    end
    for name in pairs(roster) do assert(epochs[name] ~= nil, "incomplete strategy flag-clear roster") end
    local original = mind(world.mode_id, world.self.object_name)
    local applied = original.strategy_flag_clear_epochs or {}
    assert(type(applied) == "table" and getmetatable(applied) == nil, "invalid applied strategy flag-clear epochs")
    local changed = {}
    for name, epoch in pairs(epochs) do
        local previous = applied[name] or 0
        assert(finite(previous) and previous >= 0 and previous % 1 == 0 and epoch >= previous,
            "regressed strategy flag-clear epoch")
        if epoch > previous then changed[#changed+1] = name end
    end
    if #changed == 0 then return end
    local state = clone_value(original)
    state.strategy_flags = state.strategy_flags or {}
    state.strategy_flags_cleared = state.strategy_flags_cleared or {}
    state.strategy_flag_clear_epochs = clone_value(applied)
    for _, name in ipairs(changed) do
        state.strategy_flags[name] = {}
        state.strategy_flags_cleared[name] = true
        state.strategy_flag_clear_epochs[name] = epochs[name]
    end
    assert(valid_state(state,nil,0,{remaining=standard_modes[world.mode_id] == "identity" and 32768 or 1024}),
        "invalid synchronized flag state")
    minds[world.mode_id][world.self.object_name] = state
    generation = generation + 1
end

-- Extension query hooks receive a read-only primitive view. The fixed standard
-- policy uses explicit staged observational state for its source side effects.
local function readonly(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local proxy = {}
    seen[value] = proxy
    setmetatable(proxy, {
        __index=function(_, key) return readonly(value[key], seen) end,
        __newindex=function() end,
        __len=function() return #value end,
        __pairs=function() return function(_, key)
            local next_key, next_value = next(value, key)
            if next_key ~= nil then return next_key, readonly(next_value, seen) end
        end, proxy, nil end,
    })
    return proxy
end

function sgs.evaluateModeAI(world, options, state_override)
    -- Internal prepared-prefix evaluation must never temporarily publish its
    -- shadow into minds, or acknowledge clears on behalf of that shadow.
    if state_override==nil then synchronize_flag_mind(world)
    else assert(not base_mode(world) and type(state_override)=="table",
        "prepared policy evaluation requires a legacy managed mode") end
    local policy = policies[world.mode_id]
    local scenario_estimates={}
    if not policy and scenario_modes[world.mode_id] and world.custom_roles~=true then
        policy={roles={},teams={},relation=function(w,from,to,state)
            if from~=w.self.object_name then return nil end
            local ai,players,_,_,_,estimates=objective_context(w,clone_value(state),nil)
            local relation=ai.lua_ai:relationTo(players[to])
            for key in pairs(estimates) do scenario_estimates[key]=true end
            return relation
        end}
    end
    -- The boolean form is the C++ boundary.  Keep the table form as a small
    -- Lua compatibility aid for callers that already pass option records.
    local viewer_only
    if type(options)=="table" and type(options.viewer_only)=="boolean" then
        viewer_only=options.viewer_only
    else viewer_only=options==true or world.viewer_only==true end
    local result = {managed=policy ~= nil or world.custom_roles == true,
        relations={}, objectives={}, predictable=false, game_process=0, process_label="neutral",
        relation_scope=viewer_only and "viewer" or "full"}
    result.legacy_managed=result.managed and not base_mode(world) or false
    result.legacy_base_update=base_mode(world)
    if not result.managed then return result end
    local state = state_override or mind(world.mode_id, world.self.object_name)
    if standard_modes[world.mode_id] == "identity" then
        state = clone_value(state)
        if not state.inferred_roles then standard_evaluate_roles(world,state) end
        result.standard_identity = true
        result.estimated_branches = {"mode.observer_local_role_evidence", "mode.game_process_public_defense"}
        if state.donor_intention_random_repaired then result.estimated_branches[#result.estimated_branches+1]="donor_error_repair.updateIntention_fractional_random" end
        if state.adjust_role_inferred then result.estimated_branches[#result.estimated_branches+1]="mode.adjust_hidden_role_inference" end
    end
    if result.standard_identity and not state.relation_row then
        local ok=pcall(standard_refresh_relations,world,state,0,false)
        if not ok then result.error="objective_hook" end
    end
    result.explicit_renegade = state.explicit_renegade == true
    local query_state = readonly(state)
    local players, index = snapshot_players(world)
    result.strategy_flags = clone_value(state.strategy_flags or {})
    result.strategy_marks = clone_value(state.strategy_marks or {})
    result.strategy_flags_cleared = clone_value(state.strategy_flags_cleared or {})
    result.role_values = clone_value(state.role_values or {})
    if result.standard_identity then
        local seen={};for _,key in ipairs(result.estimated_branches) do seen[key]=true end
        for key in pairs(state.relation_estimates or {}) do if not seen[key] then result.estimated_branches[#result.estimated_branches+1]=key end end
    end
    result.role_estimates = {}
    for _, player in ipairs(players) do result.role_estimates[player.object_name] = known_role(player, state) end
    local previous_index = active_indexes[world]
    local query_world = readonly(world)
    active_indexes[world] = index
    active_indexes[query_world] = index
    readonly_worlds[world] = query_world
    local function fail(error_class)
        if not result.error then result.error = error_class end
    end
    local predictable = world.self.role_visible == true
    for _, player in ipairs(players) do
        if player.object_name ~= world.self.object_name
            and player.alive and not player.role_visible then predictable = false end
    end
    local ok, custom, _, hook_error = invoke(policy, "rolePredictable", world, query_state)
    if hook_error then fail(hook_error) end
    result.predictable = ok and (custom == true or custom == nil and predictable) or false
    -- Evaluate the selected mode/observer process once. Objective hooks receive
    -- its validated values, so overriding gameProcess also changes target scoring.
    local accepted, process_value, label, hook_error = invoke(policy, "gameProcess", world, query_state)
    if hook_error then fail(hook_error) end
    if accepted and finite(process_value) then
        result.game_process = process_value
        if type(label) == "string" then result.process_label = label end
    end
    if result.standard_identity and state.cached_process then
        result.game_process=state.cached_process.value
        result.process_label=state.cached_process.label
    end
    local objectives = {}
    for _, to in ipairs(players) do
        local process = {value=result.game_process, label=result.process_label}
        local role_policy=world.self.role_visible and policy and policy.roles[world.self.role]
        local builtin=(role_policy and role_policy.objective or policy and policy.objective)==standard_objective
        local accepted,value,extra,hook_error
        if builtin then
            accepted,value,extra=pcall(standard_objective,world,to.object_name,clone_value(state),process)
            if not accepted then hook_error="objective_hook" end
            if accepted then
                local seen={};for _,key in ipairs(result.estimated_branches or {}) do seen[key]=true end
                for key in pairs(extra or {}) do if not seen[key] then result.estimated_branches[#result.estimated_branches+1]=key end end
            end
        else accepted,value,extra,hook_error=invoke(policy,"objective",world,to.object_name,query_state,process) end
        if hook_error then fail(hook_error) end
        objectives[to.object_name] = {valid=accepted and finite(value) and (builtin or value >= -5 and value <= 5),
            supplied=not accepted or value ~= nil, value=value}
    end
    local relation_sources = viewer_only and {world.self} or players
    for _, from in ipairs(relation_sources) do
        local row = {}
        result.relations[from.object_name] = row
        for _, to in ipairs(players) do
            local relation = "unknown"
            if from.object_name == to.object_name
                or from.controller and from.controller ~= "" and from.controller == to.controller then
                relation = "friend"
            else
                local accepted, value, _, hook_error = invoke(policy, "relation", world, from.object_name, to.object_name, query_state)
                if hook_error then fail(hook_error) end
                if accepted and valid_relations[value] then relation = value
                elseif accepted and value == nil then
                    -- Never derive team membership from an invisible identity.
                    local a = policy and from.role_visible and policy.teams[from.role]
                    local b = policy and to.role_visible and policy.teams[to.role]
                    if a and b then
                        relation = a == b and "friend" or "enemy"
                    elseif from.object_name == world.self.object_name then
                        -- Legacy objectiveLevel also defines friends/enemies. A score is
                        -- viewer-relative; never transpose it into another player's row.
                        local score = objectives[to.object_name]
                        if score.valid then
                            relation = score.value < 0 and "friend" or score.value > 0 and "enemy" or "neutral"
                        end
                    end
                end
            end
            row[to.object_name] = relation
        end
    end
    if next(scenario_estimates) then
        result.estimated_branches=result.estimated_branches or {}
        for key in pairs(scenario_estimates) do result.estimated_branches[#result.estimated_branches+1]=key end
    end
    for _, to in ipairs(players) do
        local value = scores[result.relations[world.self.object_name][to.object_name]]
        local score = objectives[to.object_name]
        if score.supplied then value = score.valid and score.value or 0 end
        if result.standard_identity then
            if world.self.controller==to.object_name and to.object_name~=world.self.object_name then value=-2 end
        elseif world.self.controller and world.self.controller ~= "" and world.self.controller == to.controller then value = -2 end
        result.objectives[to.object_name] = to.object_name == world.self.object_name and -3 or value
    end
    if result.standard_identity and not result.error then
        minds[world.mode_id][world.self.object_name]=state
        result.strategy_marks=clone_value(state.strategy_marks or {})
        for name,marks in pairs(result.strategy_marks) do
            local p=view_player(world,name)
            for mark,amount in pairs(marks) do
                if mark=="roleRobot" or mark:sub(1,7)=="revenge" then marks[mark]=(p and p.public_marks and p.public_marks[mark] or 0)+amount end
            end
        end
        for name,offsets in pairs(state.strategy_mark_offsets or {}) do
            local p=view_player(world,name)
            local row=result.strategy_marks[name] or {}
            for mark,offset in pairs(offsets) do row[mark]=math.max(0,(row[mark]~=nil and row[mark] or p and p.public_marks and p.public_marks[mark] or 0)+offset) end
            result.strategy_marks[name]=row
        end
    end
    active_indexes[world] = previous_index
    readonly_worlds[world] = nil
    active_indexes[query_world] = nil
    return result
end

-- Called only by the host's active-request bridge. Actual objective queries are
-- lazy; preview mode-policy rows never advance the observational mark ledger.
local active_event_session
local prepare_event_prefix
local prepared_objectives=setmetatable({}, {__mode="k"})

local function standard_query_state(world)
    synchronize_flag_mind(world)
    assert(standard_modes[world.mode_id]=="identity","objective query requires standard identity mode")
    local state=clone_value(mind(world.mode_id,world.self.object_name))
    if not state.inferred_roles then standard_evaluate_roles(world,state) end
    if not state.cached_process then
        local value,label=standard_process(world,state);state.cached_process={value=value,label=label}
    end
    return state
end

local function standard_query_result(world,state,value,estimates,event_prefix)
    local marks=clone_value(state.strategy_marks or {})
    for name,entries in pairs(marks) do
        local p=view_player(world,name)
        for key,amount in pairs(entries) do
            if key=="roleRobot" or key:sub(1,7)=="revenge" then entries[key]=(p and p.public_marks and p.public_marks[key] or 0)+amount end
        end
    end
    for name,offsets in pairs(state.strategy_mark_offsets or {}) do
        local p=view_player(world,name);local row=marks[name] or {}
        for key,offset in pairs(offsets) do
            row[key]=math.max(0,(row[key]~=nil and row[key] or p and p.public_marks and p.public_marks[key] or 0)+offset)
        end
        marks[name]=row
    end
    local used={};for key in pairs(estimates or {}) do used[#used+1]=key end;table.sort(used)
    assert(valid_state(state,nil,0,{remaining=standard_modes[world.mode_id]=="identity" and 32768 or 1024}),"invalid prepared mode state")
    local result={value=value,estimated_branches=used,strategy_marks=marks,relations=clone_value(state.relation_row or {})}
    local token={}
    prepared_objectives[token]={mode=world.mode_id,viewer=world.self.object_name,state=state,
        original=mind(world.mode_id,world.self.object_name),generation=generation,
        session=event_prefix and active_event_session or nil,prefix=event_prefix}
    return result,token
end

-- Tiny trusted commit, captured by native before invoking the preparation.
-- No policy calls, allocations, or traversals occur after schema validation.
function sgs.commitStandardObjective(token)
    local pending=prepared_objectives[token]
    if not pending then return "objective_prepared" end
    prepared_objectives[token]=nil
    if pending.generation~=generation or minds[pending.mode][pending.viewer]~=pending.original then return "objective_stale" end
    if pending.session then
        if active_event_session~=pending.session then return "objective_event_stale" end
        pending.session.shadow=pending.state
        pending.session.deltas=pending.prefix.deltas
        pending.session.effects=pending.prefix.effects
        pending.session.presentation=pending.prefix.presentation
        pending.session.queried=true
    else
        minds[pending.mode][pending.viewer]=pending.state
        generation=generation+1
    end
end

function sgs.prepareStandardObjective(world,target_id)
    assert(type(target_id)=="string" and view_player(world,target_id),"unknown objective target")
    local state=standard_query_state(world)
    local value,estimates=standard_objective(world,target_id,state,state.cached_process)
    assert(finite(value),"invalid objective result")
    return standard_query_result(world,state,value,estimates)
end

function sgs.prepareStandardRelations(world,to_use_count)
    assert(to_use_count==nil or finite(to_use_count) and to_use_count>=0 and to_use_count%1==0,"invalid previous owner plan count")
    local state=standard_query_state(world)
    local _,estimates=standard_refresh_relations(world,state,to_use_count,false)
    return standard_query_result(world,state,0,estimates)
end

local function player_relations_result(world,state,estimates,event_prefix)
    local result,token=standard_query_result(world,state,0,estimates,event_prefix)
    result.owner_role,result.harsh_retain=state.owner_role,state.harsh_retain
    result.friends=clone_value(state.relation_friends)
    result.friends_noself=clone_value(state.relation_friends_noself)
    result.enemies=clone_value(state.relation_enemies)
    result.role_values=clone_value(state.role_values or {})
    result.role_estimates={}
    for _,player in ipairs(snapshot_players(world)) do
        result.role_estimates[player.object_name]=state.inferred_roles and state.inferred_roles[player.object_name] or "neutral"
    end
    result.explicit_renegade=state.explicit_renegade==true
    result.game_process,result.process_label=state.cached_process.value,state.cached_process.label
    result.role_counts=clone_value(role_counts(world))
    return result,token
end

local function managed_player_relations_result(world,state,to_use_count,update,event_prefix)
    assert(finite(to_use_count) and to_use_count>=0 and to_use_count%1==0 and type(update)=="boolean",
        "invalid updatePlayers arguments")
    assert(not base_mode(world),"base mode is not the managed updatePlayers body")
    local policy=sgs.evaluateModeAI(world,{viewer_only=false},state)
    assert(policy.legacy_managed==true and not policy.error,policy.error or "managed mode policy unavailable")
    local relations=assert(policy.relations[world.self.object_name],"managed observer relation row is unavailable")
    local public_roles,counts,friends,friends_noself,enemies={},{lord=0,loyalist=0,rebel=0,renegade=0},{},{},{}
    assert(world.self.role_visible==true and type(world.self.role)=="string","owner role is unknown")
    -- These are the installModeAI compatibility globals, not the mode policy's
    -- private inferred-role state. Dead-player entries are retained by the
    -- isolated observer's separate compatibility cache, never seeded from mind.
    for _,p in ipairs(alive_in_order(world)) do
        assert(type(p.role_revealed)=="boolean","public role revelation is unknown")
        if p.role_revealed then assert(p.role_visible==true and type(p.role)=="string",
            "revealed role identity is not projected") end
        public_roles[p.object_name]=p.role_revealed and p.role or "neutral"
    end
    for _,p in ipairs(alive_in_order(world)) do
        local role=p.role_revealed and p.role or "unknown"
        counts[role]=(counts[role] or 0)+1
    end
    for _,p in ipairs(alive_in_order(world)) do
        local relation=relations[p.object_name]
        assert(valid_relations[relation],"managed relation is not projected")
        if relation=="friend" then
            friends[#friends+1]=p.object_name
            if p.object_name~=world.self.object_name then friends_noself[#friends_noself+1]=p.object_name end
        elseif relation=="enemy" then enemies[#enemies+1]=p.object_name end
    end
    local estimates={};for _,key in ipairs(policy.estimated_branches or {}) do estimates[key]=true end
    local result,token=standard_query_result(world,state,0,estimates,event_prefix)
    result.relations=clone_value(relations)
    result.relation_matrix=clone_value(policy.relations)
    result.owner_role,result.harsh_retain=world.self.role,false
    result.friends,result.friends_noself,result.enemies=friends,friends_noself,enemies
    result.role_values=clone_value(policy.role_values or {})
    result.role_estimates,result.role_counts=public_roles,counts
    result.explicit_renegade=policy.explicit_renegade==true
    result.game_process,result.process_label=policy.game_process,policy.process_label
    return result,token
end

local function prepare_player_relations(world,state,to_use_count,update,event_prefix)
    if base_mode(world) then
        if standard_modes[world.mode_id]~="identity" then initialize_base_role_cache(world,state) end
        local estimates=standard_update_players(world,state,to_use_count,update)
        return player_relations_result(world,state,estimates,event_prefix)
    end
    return managed_player_relations_result(world,state,to_use_count,update,event_prefix)
end

function sgs.prepareStandardUpdatePlayers(world,to_use_count,update)
    synchronize_flag_mind(world)
    local state=clone_value(mind(world.mode_id,world.self.object_name))
    return prepare_player_relations(world,state,to_use_count,update)
end

function sgs.evaluateStandardObjective(world,target_id)
    local result,token=sgs.prepareStandardObjective(world,target_id)
    assert(sgs.commitStandardObjective(token)==nil,"objective commit rejected")
    return result
end

function sgs.refreshStandardRelations(world,to_use_count)
    local result,token=sgs.prepareStandardRelations(world,to_use_count)
    assert(sgs.commitStandardObjective(token)==nil,"relation refresh commit rejected")
    return result
end

function sgs.beginStandardEventQueries(world)
    assert(active_event_session==nil,"nested standard event queries")
    local state
    if standard_modes[world.mode_id]=="identity" then state=standard_query_state(world)
    else
        synchronize_flag_mind(world)
        assert(policies[world.mode_id] or scenario_modes[world.mode_id] or world.custom_roles==true,
            "mode event query domain is unavailable")
        state=clone_value(mind(world.mode_id,world.self.object_name))
    end
    active_event_session={mode=world.mode_id,viewer=world.self.object_name,revision=world.revision,
        original=mind(world.mode_id,world.self.object_name),generation=generation,
        shadow=state,deltas={},effects={},presentation={},queried=false}
    return true
end

function sgs.abortStandardEventQueries()
    active_event_session=nil
end

function sgs.prepareEventStandardObjective(world,target_id,deltas,effects)
    assert(type(target_id)=="string" and view_player(world,target_id),"unknown event objective target")
    local session=active_event_session
    assert(session and session.mode==world.mode_id and session.viewer==world.self.object_name
        and session.revision==world.revision,"event objective session unavailable")
    local state,presentation=prepare_event_prefix(world,deltas,effects)
    local value,estimates=standard_objective(world,target_id,state,state.cached_process)
    assert(finite(value),"invalid event objective result")
    return standard_query_result(world,state,value,estimates,{deltas=clone_value(deltas),effects=clone_value(effects),presentation=presentation})
end

function sgs.prepareEventStandardUpdatePlayers(world,to_use_count,update,deltas,effects)
    local session=active_event_session
    assert(session and session.mode==world.mode_id and session.viewer==world.self.object_name
        and session.revision==world.revision,"event updatePlayers session unavailable")
    local state,presentation=prepare_event_prefix(world,deltas,effects)
    return prepare_player_relations(world,state,to_use_count,update,
        {deltas=clone_value(deltas),effects=clone_value(effects),presentation=presentation})
end

-- Opaque tokens never contain state. Keep only the latest preparation and let
-- an abandoned token disappear with its caller; no failed event retains a queue.
local prepared_intentions = setmetatable({}, {__mode="k"})

-- Only typed AI strategy state is accepted here. These effects never write Room
-- flags/marks and cannot reveal a hidden native role or card identity.
local function valid_history_data(data)
    if type(data) ~= "table" or getmetatable(data) ~= nil then return false end
    local statistics={drawData=true,convertData=true,damageData=true,throwData=true}
    local total=0
    for category, rows in pairs(data) do
        if not statistics[category] and category~="aiResponse" and category~="card_damage_nature" then return false end
        if type(rows)~="table" or getmetatable(rows)~=nil then return false end
        for name,value in pairs(rows) do
            total=total+1
            if total>4096 or type(name)~="string" or #name<1 or #name>256 then return false end
            if statistics[category] then
                if type(value)~="table" or getmetatable(value)~=nil then return false end
                local count=0
                for key, sample in pairs(value) do
                    if type(key)~="number" or key%1~=0 or key<1 or key>99 or not finite(sample) then return false end
                    count=count+1
                end
                for i=1,count do if value[i]==nil then return false end end
            elseif category=="aiResponse" then
                if type(value)~="string" or #value<1 or #value>256 then return false end
            elseif not finite(value) or value%1~=0 or value<0 or value>5 then return false end
        end
    end
    return true
end

local function valid_effect(effect, present, delta_count, previous, viewer, world)
    if type(effect) ~= "table" or getmetatable(effect) ~= nil then return false end
    local position = effect.after_delta
    if type(position) ~= "number" or position % 1 ~= 0 or position < previous or position > delta_count then return false end
    local common = {kind=true, after_delta=true}
    local fields
    if effect.kind == "speech" then
        fields={player=true,text=true,source_key=true}
        if not present[effect.player] or type(effect.text)~="string" or #effect.text>4096
            or type(effect.source_key)~="string" or #effect.source_key>256 then return false end
    elseif effect.kind == "speech_counter" then
        fields={player=true,name=true,value=true,source_key=true}
        if not present[effect.player] or not finite(effect.value) or effect.value<0 or effect.value%1~=0
            or effect.value>1000000 or type(effect.name)~="string" then return false end
        local target=effect.name:match("^continuous_slash_count(.+)%-Clear$")
        if not (effect.name=="jink_count-Clear" and effect.source_key=="chat:CardOffset:multi_jink")
            and not (target and present[target] and effect.source_key=="chat:TargetSpecified:continuous_slash") then return false end
    elseif effect.kind == "delay" then
        fields={milliseconds=true,source_key=true}
        if not finite(effect.milliseconds) or effect.milliseconds%1~=0 or effect.milliseconds<0 or effect.milliseconds>60000
            or type(effect.source_key)~="string" or #effect.source_key>256 then return false end
    elseif effect.kind == "personality_target" then
        fields={player=true}
        if effect.player~=viewer then return false end
    elseif effect.kind == "phase_clear" then
        fields={player=true}
        if effect.player~=viewer then return false end
    elseif effect.kind == "cardask_no_jink" then
        if effect.player~=viewer or effect.amount~=1 then return false end
        if effect.source_key~=nil then
            fields={player=true,amount=true,source_key=true,scope=true,ordinal=true}
            if effect.source_key~="aocai:slash-jink" or type(effect.scope)~="string"
                or not effect.scope:match("^[1-9]%d*$") or #effect.scope>20
                or effect.scope~=(world and world.strategy_facts and world.strategy_facts.aocai_nojink_scope)
                or not finite(effect.ordinal) or effect.ordinal%1~=0
                or effect.ordinal<1 or effect.ordinal>64 then return false end
        elseif effect.card_token~=nil then
            fields={player=true,card_token=true,amount=true}
            if type(effect.card_token)~="string" or #effect.card_token>128
                or not effect.card_token:match("^native:[%x%-]+:%d+$")
                or effect.card_token~=(world and world.strategy_facts and world.strategy_facts.response_effect_nojink_token) then return false end
        else
            fields={player=true,card_id=true,amount=true}
            if not finite(effect.card_id) or effect.card_id%1~=0
                or effect.card_id< -2147483648 or effect.card_id>2147483647 then return false end
        end
    elseif effect.kind == "ai_player_hint" then
        fields = {source=true,player=true,name=true}
        if effect.source~=viewer or not present[effect.player]
            or (effect.name~="jiaozhaoAI" and effect.name~="jiyuAI" and effect.name~="kuangbiAI") then return false end
        -- A hint is never copied into mode state. Native publishes it only after
        -- final acceptance and the exact public use/choice witness.
    elseif effect.kind == "ai_data" then
        fields = {revision=true,data=true}
        if type(effect.revision)~="string" or #effect.revision>256 or not valid_history_data(effect.data) then return false end
    elseif effect.kind == "role_refresh" then
        fields = {adjust=true,force=true,refresh=true}
        if effect.adjust ~= nil and type(effect.adjust) ~= "boolean" then return false end
        if effect.force ~= nil and type(effect.force) ~= "boolean" then return false end
        if effect.refresh ~= nil and type(effect.refresh) ~= "boolean" then return false end
        if effect.adjust and (effect.force or effect.refresh) then return false end
    elseif effect.kind == "role_row_update" then
        fields={player=true,role=true,assigned_role=true,assigned_value=true,source_skill=true}
        local witness=world.strategy_facts and world.strategy_facts.role_row_update_witness
        local rows=type(witness)=="table" and witness[effect.source_skill]
        local roles={lord=true,loyalist=true,rebel=true,renegade=true}
        if not present[effect.player] or not roles[effect.role] or type(rows)~="table" then return false end
        local found=false;for _,name in ipairs(rows)do if name==effect.player then found=true;break end end
        local mercenary=effect.source_skill=="Cjiyongbing"
        local assigned=mercenary and effect.role or (effect.role=="rebel" and "loyalist" or effect.role)
        if not found or effect.assigned_role~=assigned or effect.assigned_value~=(mercenary and 1000 or 0)then return false end
    elseif effect.kind == "loong_feilong_role" then
        fields={actor=true,player=true,role=true}
        local witness=world.strategy_facts and world.strategy_facts.loong_feilong_role_witness
        local roles={lord=true,loyalist=true,rebel=true,renegade=true}
        if type(witness)~="table" or effect.actor~=world.self.object_name
            or effect.actor~=witness.actor or effect.role~=witness.role
            or not roles[effect.role] or not present[effect.player] then return false end
        local found=false;for _,name in ipairs(witness.targets or {})do if name==effect.player then found=true;break end end
        if not found then return false end
    elseif effect.kind == "du_tongque_role" then
        fields={player=true}
        local witness=world.strategy_facts and world.strategy_facts.du_tongque_role_witness
        if not present[effect.player] or type(witness)~="table" or witness.player~=effect.player then return false end
    elseif effect.kind == "kaiyuan_role" or effect.kind == "quanxiang_role" or effect.kind == "sfofl_longmu_role" then
        fields = {player=true,source_player=true,source_role=true,target_role=true}
        local witness=world.strategy_facts and world.strategy_facts[effect.kind.."_witness"]
        local roles={lord=true,loyalist=true,rebel=true,renegade=true}
        if not present[effect.player] or not present[effect.source_player]
            or not roles[effect.source_role] or not roles[effect.target_role]
            or type(witness)~="table" or witness.player~=effect.player or type(witness.sources)~="table" then return false end
        local found=false
        for _,name in ipairs(witness.sources) do if name==effect.source_player then found=true;break end end
        if not found then return false end
    elseif effect.kind == "dongmanbao_dapo_role" then
        fields={player=true,source_player=true,role=true}
        local witness=world.strategy_facts and world.strategy_facts.dongmanbao_dapo_role_witness
        local found=false
        if type(witness)=="table" and witness.player==effect.player and witness.target_role_known==true and type(witness.sources)=="table" then
            for _,row in ipairs(witness.sources)do
                if row.player==effect.source_player and row.role_known==true and row.role==effect.role then found=true;break end
            end
        end
        if not found or not present[effect.player] or not present[effect.source_player]
            or not ({lord=true,loyalist=true,rebel=true,renegade=true})[effect.role]then return false end
    elseif effect.kind == "azirshenji_role" then
        fields={player=true,role=true}
        local witness=world.strategy_facts and world.strategy_facts.azirshenji_role_witness
        local found=false
        if type(witness)=="table" and type(witness.rows)=="table" then
            for _,row in ipairs(witness.rows)do
                if row.player==effect.player and row.head_known==true and row.solar==true
                    and row.role_known==true and row.role==effect.role then found=true;break end
            end
        end
        if not found or not present[effect.player]
            or not ({lord=true,loyalist=true,rebel=true,renegade=true})[effect.role]then return false end
    elseif effect.kind == "tongling_role" then
        fields = {player=true,role=true}
        local witness=world.strategy_facts and world.strategy_facts.tongling_role_witness
        if not present[effect.player] or type(witness)~="table"
            or witness.player~=effect.player or witness.role~=effect.role
            or not ({lord=true,loyalist=true,rebel=true,renegade=true})[effect.role] then return false end
    elseif effect.kind == "role_value_add" then
        fields = {player=true, role=true, amount=true}
        if not present[effect.player] or effect.role ~= "renegade" or not finite(effect.amount) then return false end
    elseif effect.kind == "intention" then
        fields = {from=true, to=true, level=true}
        if not present[effect.from] or not present[effect.to] or effect.from == effect.to or not finite(effect.level) then return false end
    elseif effect.kind == "role_copy" or effect.kind == "peach_renegade" then
        fields = {from=true, to=true}
        if not present[effect.from] or not present[effect.to] or effect.from == effect.to then return false end
    elseif effect.kind == "strategy_flags_clear" then
        fields = {player=true}
        if not present[effect.player] then return false end
    elseif effect.kind == "strategy_flag" then
        fields = {player=true, name=true, value=true}
        local name = effect.name
        if not present[effect.player] or type(name) ~= "string" or type(effect.value) ~= "boolean" then return false end
        local ordinary = {AI_doNotSave=true, AIGlobal_NeedToWake=true, needCrossbow=true, AI_HuangtianPindian=true, AI_NosXuanhuoTarget=true, AI_MizhaoTarget=true}
        local owner_only = {NosKurou_toDie=true, AI_doNotInvoke_luoshen=true, AI_doNotInvoke_qianxi=true,
            AI_Luoshen_Conflict_With_Guanxing=true, stack_overflow_jijiang=true,
            should_luawu=true, AI_doInvoke_luawu=true, vecter_friend=true, vecter_slash=true, AI_XiechanUsing=true}
        local package_flag = name=='willSkipPlayPhase' and effect.player==viewer
            and world and world.strategy_facts and world.strategy_facts.original_guanxing_flag_write==true
        if effect.player == viewer then
            package_flag = package_flag or owner_only[name] == true
            for _, prefix in ipairs({"nostuxi_isfriend_", "tuxi_isfriend_", "jieyin_isenemy_", "AI_XiansiToFriend_", "sp_qiangxi_isfriend_", "luajiejiang_isfriend_", "AI_TuxiToFriend_"}) do
                if name:sub(1,#prefix) == prefix and present[name:sub(#prefix+1)] then package_flag=true end
            end
            if name:find("yj_zhengyuUse",1,true) then
                for target in pairs(present) do
                    local prefix=target.."yj_zhengyuUse"
                    if name:sub(1,#prefix)==prefix then
                        local suffix=name:sub(#prefix+1);local id=tonumber(suffix)
                        if id and id>=0 and id%1==0 and tostring(id)==suffix then
                            for _,card in ipairs(world and world.hand_cards or {}) do if card.effective_id==id then package_flag=true end end
                            for _,card in ipairs(world and world.self and world.self.equips or {}) do if card.effective_id==id then package_flag=true end end
                        end
                    end
                end
            end
            for _, pattern in ipairs(world and world.strategy_facts and world.strategy_facts.pattern_names or {}) do
                if type(pattern)=="string" and name==pattern.."nosguhuoFailed" then package_flag=true;break end
            end
        end
        local weapon_flag = "weapon_done_"..viewer.."_"..effect.player
        if not ordinary[name] and not package_flag and name ~= weapon_flag and not (name:sub(1,7) == "duelTo_" and present[name:sub(8)]) then return false end
    elseif effect.kind == "strategy_mark" then
        fields = {player=true, name=true, amount=true}
        local name = effect.name
        if not present[effect.player] or type(name) ~= "string" or not finite(effect.amount) or effect.amount % 1 ~= 0 then return false end
        local focus=world.strategy_facts and world.strategy_facts.imagine_focus_event
        local focus_allowed=(name=="FocusDamageCount" or name=="FocusRecoverCount") and type(focus)=="table"
            and focus.name==name and focus.player==effect.player and focus.amount==effect.amount and finite(focus.baseline)
        if not focus_allowed and name ~= "roleRobot" and not ((name=="yhpodi_to-PlayClear" or ((name=="AI_fangjian-Clear" or name=="AI_do_not_invoke_s2_longwei-Clear") and effect.player==world.self.object_name)) and effect.amount==1) and not (name:sub(1,9) == "Intention" and present[name:sub(10)])
            and not (name:sub(1,7)=="revenge" and present[name:sub(8)] and effect.player==viewer) then return false end
    else return false end
    for key in pairs(effect) do if not common[key] and not fields[key] then return false end end
    return true
end

local function apply_effect(world, effect, state, presentation)
    if effect.kind == "speech" or effect.kind == "delay" then
        assert(type(presentation)=="table" and #presentation<128,"too many mode presentation effects")
        presentation[#presentation+1]=clone_value(effect)
    elseif effect.kind == "personality_target" then
        state.personality_target=effect.player
    elseif effect.kind == "phase_clear" then
        local marks=state.strategy_marks and state.strategy_marks[effect.player]
        for name in pairs(marks or {}) do
            if name:match("^ai_NoJinkCard%-?%d+_targeted%-Clear$")
                or name:match("^ai_NoJinkDummy%d+_%d+_targeted%-Clear$")
                or name:match("^ai_NoJinkVirtualnative:[%x%-]+:%d+_targeted%-Clear$") then marks[name]=nil end
        end
    elseif effect.kind == "cardask_no_jink" then
        state.strategy_marks=state.strategy_marks or {}
        local marks=state.strategy_marks[effect.player] or {}
        local key
        if effect.source_key then
            -- Each primitive-data invocation creates a new source dummy card.
            -- Use an independent opaque namespace, never the shared -1 catalog
            -- ID or a real Card ID. A repeated accepted ordinal is a replay.
            key="ai_NoJinkDummy"..effect.scope.."_"..effect.ordinal.."_targeted-Clear"
            if marks[key]~=nil then return "intention_effect_replay" end
            marks[key]=1
        elseif effect.card_token then
            key="ai_NoJinkVirtual"..effect.card_token.."_targeted-Clear"
            marks[key]=(marks[key] or 0)+effect.amount
        else
            key="ai_NoJinkCard"..effect.card_id.."_targeted-Clear"
            local previous=marks[key]
            if previous==nil then
                local player=view_player(world,effect.player)
                previous=player and player.public_marks and player.public_marks[key] or 0
            end
            marks[key]=previous+effect.amount
        end
        state.strategy_marks[effect.player]=marks
    elseif effect.kind == "role_refresh" then
        if effect.adjust then
            standard_adjust_roles(world,state)
        elseif standard_modes[world.mode_id] == "identity" and (effect.force or effect.refresh or state.intention_needs_refresh) then
            local dirty,actor=state.intention_needs_refresh,state.intention_refresh_actor
            if effect.force or dirty then standard_evaluate_roles(world,state) end
            if effect.refresh then standard_refresh_relations(world,state,nil,effect.force)
            elseif dirty then standard_refresh_after_intention(world,state,actor) end
            state.intention_needs_refresh,state.intention_refresh_actor=nil,nil
        end
    elseif effect.kind == "intention" then
        local level = effect.level
        local marks = state.strategy_marks and state.strategy_marks[effect.to]
        local key = "Intention" .. effect.from
        if marks and marks[key] ~= nil then level = level + marks[key]; marks[key] = 0 end
        local ok, failure
        if standard_modes[world.mode_id]=="identity" then
            local accepted, _, _, reason=invoke(policies[world.mode_id], "onIntention", world,
                effect.from,effect.to,level,state,nil,presentation,effect.after_delta)
            ok,failure=accepted,reason
        else
            local accepted, _, _, reason=invoke(policies[world.mode_id], "onIntention", world,
                effect.from,effect.to,level,state)
            ok,failure=accepted,reason
        end
        if not ok then return failure end
    elseif effect.kind == "role_row_update" then
        state.role_values=state.role_values or {};state.inferred_roles=state.inferred_roles or {}
        local values=state.role_values[effect.player]or {lord=0,loyalist=0,rebel=0,renegade=0}
        values.renegade,values.loyalist=0,0
        values[effect.assigned_role]=effect.assigned_value
        state.role_values[effect.player]=values;state.inferred_roles[effect.player]=effect.role
        -- The source callback's updatePlayers follows as its own effect.
    elseif effect.kind == "loong_feilong_role" then
        state.role_values=state.role_values or {};state.inferred_roles=state.inferred_roles or {}
        local values=state.role_values[effect.player] or {lord=0,loyalist=0,rebel=0,renegade=0}
        values.renegade,values.loyalist=0,0
        local role,value=effect.role,1000
        if role=="rebel" then role,value="loyalist",-1000 end
        values[role]=value
        state.role_values[effect.player]=values;state.inferred_roles[effect.player]=effect.role
        -- Source updatePlayers follows separately, once per matched target.
    elseif effect.kind == "du_tongque_role" then
        state.role_values=state.role_values or {};state.inferred_roles=state.inferred_roles or {}
        local values=state.role_values[effect.player] or {lord=0,loyalist=0,rebel=0,renegade=0}
        values.renegade,values.loyalist=0,0
        values.renegade=1000
        state.role_values[effect.player]=values;state.inferred_roles[effect.player]="renegade"
    elseif effect.kind == "kaiyuan_role" or effect.kind == "quanxiang_role" or effect.kind == "sfofl_longmu_role" then
        state.role_values=state.role_values or {}
        state.inferred_roles=state.inferred_roles or {}
        local values=state.role_values[effect.player] or {lord=0,loyalist=0,rebel=0,renegade=0}
        -- AIgeneral-ai.lua27: the local rebel->loyalist/-1000 rewrite is
        -- unused by the actual assignment, which indexes sb:getRole() again.
        values.renegade,values.loyalist=0,0
        values[effect.source_role]=1000
        state.role_values[effect.player]=values
        state.inferred_roles[effect.player]=effect.target_role
        -- Source callback calls updatePlayers next, as a separate prefix query.
    elseif effect.kind == "tongling_role" or effect.kind == "azirshenji_role" or effect.kind == "dongmanbao_dapo_role" then
        state.role_values=state.role_values or {}
        state.inferred_roles=state.inferred_roles or {}
        local values=state.role_values[effect.player] or {lord=0,loyalist=0,rebel=0,renegade=0}
        -- Dragon-ai.lua:314: preserve assignment order (including renegade
        -- becoming 1000 after being reset). Existing unrelated role keys survive.
        values.renegade,values.loyalist=0,0
        values[effect.role]=1000
        state.role_values[effect.player]=values
        state.inferred_roles[effect.player]=effect.role
        -- Dapo calls updatePlayers next as a separate prefix query; these other
        -- donors do not refresh relations or run role evaluation here.
    elseif effect.kind == "role_value_add" then
        state.role_values = state.role_values or {}
        local values = state.role_values[effect.player] or {lord=0, loyalist=0, rebel=0, renegade=0}
        values[effect.role] = (values[effect.role] or 0) + effect.amount
        state.role_values[effect.player] = values
    elseif effect.kind == "peach_renegade" then
        local predictable = world.mode_policy and world.mode_policy.predictable
        local counts = world.role_counts
        if predictable == true then return end
        if type(predictable) ~= "boolean" or type(counts) ~= "table" or not finite(counts.renegade) then
            error("Peach role evidence needs predictable/count facts")
        end
        local from, target = view_player(world, effect.from), view_player(world, effect.to)
        local actor_role, target_role = known_role(from, state), known_role(target, state)
        if not predictable and counts.renegade > 0 and target_role == "rebel"
            and (actor_role == "loyalist" or actor_role == "renegade") then
            apply_effect(world, {kind="role_value_add", player=effect.from, role="renegade", amount=100}, state)
        end
    elseif effect.kind == "role_copy" then
        state.role_values = state.role_values or {}
        state.inferred_roles = state.inferred_roles or {}
        -- Legacy Fenxin assigns the row, not a numerical delta. Preserve row
        -- aliasing within this observer's cloned transaction as well as values.
        local values = state.role_values[effect.from] or {lord=0, loyalist=0, rebel=0, renegade=0}
        state.role_values[effect.from], state.role_values[effect.to] = values, values
        state.inferred_roles[effect.to] = known_role(view_player(world, effect.from), state)
        if standard_modes[world.mode_id]=="identity" then standard_refresh_relations(world,state,nil,false) end
    elseif effect.kind == "strategy_flags_clear" then
        state.strategy_flags = state.strategy_flags or {}
        state.strategy_flags_cleared = state.strategy_flags_cleared or {}
        state.strategy_flags[effect.player] = {}
        state.strategy_flags_cleared[effect.player] = true
    elseif effect.kind == "strategy_flag" then
        state.strategy_flags = state.strategy_flags or {}
        local flags = state.strategy_flags[effect.player] or {}
        flags[effect.name] = effect.value
        state.strategy_flags[effect.player] = flags
    elseif effect.kind == "strategy_mark" then
        state.strategy_marks = state.strategy_marks or {}
        local marks = state.strategy_marks[effect.player] or {}
        local value = marks[effect.name]
        if effect.name == "roleRobot" or effect.name:sub(1,7)=="revenge" then
            marks[effect.name]=(value or 0)+effect.amount
            state.strategy_marks[effect.player]=marks
            return
        end
        if value == nil then
            local player = view_player(world, effect.player)
            value = player.public_marks and player.public_marks[effect.name] or 0
        end
        marks[effect.name] = value + effect.amount
        state.strategy_marks[effect.player] = marks
    end
end

local function same_prefix_value(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for key,value in pairs(a) do if not same_prefix_value(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end

-- Preparation is budgeted by the host. It never replaces an observer mind,
-- including when an instruction hook interrupts after the callbacks finish.
function sgs.prepareModeAIIntentions(world, deltas, effects)
    synchronize_flag_mind(world)
    local pending = setmetatable({}, {__mode="k"})
    prepared_intentions = pending
    if type(deltas) ~= "table" or getmetatable(deltas) ~= nil then return "intention_input" end
    local present = {[world.self.object_name]=true}
    for _, player in ipairs(world.players) do present[player.object_name] = true end
    local count = 0
    for key in pairs(deltas) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 64 then return "intention_input" end
        count = count + 1
    end
    local fields = {from=true, to=true, level=true, defer_refresh=true}
    for index = 1, count do
        local delta = deltas[index]
        if type(delta) ~= "table" or getmetatable(delta) ~= nil then return "intention_input" end
        for key in pairs(delta) do
            if not fields[key] then return "intention_input" end
        end
        if type(delta.from) ~= "string" or type(delta.to) ~= "string"
            or delta.from == delta.to or not present[delta.from] or not present[delta.to]
            or not finite(delta.level)
            or delta.defer_refresh ~= nil and type(delta.defer_refresh) ~= "boolean" then return "intention_input" end
    end
    effects = effects or {}
    if type(effects) ~= "table" or getmetatable(effects) ~= nil then return "intention_effect" end
    local effect_count, previous = 0, 0
    local dummy_nojink = {}
    for key in pairs(effects) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 64 then return "intention_effect" end
        effect_count = effect_count + 1
    end
    for index = 1, effect_count do
        if not valid_effect(effects[index], present, count, previous, world.self.object_name, world) then return "intention_effect" end
        local effect=effects[index]
        if effect.kind=="cardask_no_jink" and effect.source_key then
            local key=effect.scope..":"..effect.ordinal
            if dummy_nojink[key] then return "intention_effect" end
            dummy_nojink[key]=true
        end
        previous = effects[index].after_delta
    end
    local mode, viewer = world.mode_id, world.self.object_name
    local policy = policies[mode]
    -- Reserve an empty observer envelope before the native no-allocation commit.
    local original = mind(mode, viewer)
    local owned = minds[mode]
    local prepared_generation = generation
    local query_world = readonly(world)
    local session=active_event_session
    local start_delta,start_effect=0,0
    if session then
        if session.mode~=mode or session.viewer~=viewer or session.revision~=world.revision
            or session.original~=original or session.generation~=generation then return "intention_event_stale" end
        start_delta,start_effect=#session.deltas,#session.effects
        if count<start_delta or effect_count<start_effect then return "intention_prefix" end
        for i=1,start_delta do if not same_prefix_value(deltas[i],session.deltas[i]) then return "intention_prefix" end end
        for i=1,start_effect do if not same_prefix_value(effects[i],session.effects[i]) then return "intention_prefix" end end
        if effects[start_effect+1] and effects[start_effect+1].after_delta<start_delta then return "intention_prefix" end
    end
    local shadow = clone_value(session and session.shadow or original or {})
    local presentation = clone_value(session and session.presentation or {})
    -- Pass the read-only view directly. No global lookup mapping needs cleanup
    -- if a host instruction hook aborts any part of this preparation.
    local effect_index = start_effect+1
    for position = start_delta, count do
        while effect_index <= effect_count and effects[effect_index].after_delta == position do
            local effect_error = apply_effect(query_world, effects[effect_index], shadow, presentation)
            if effect_error then return effect_error end
            effect_index = effect_index + 1
        end
        local delta = deltas[position + 1]
        if delta then
            local level = delta.level
            -- Rule-discard evidence is consumed once by the next source→target
            -- intention, in the same location as legacy updateIntention's mark.
            local marks = shadow.strategy_marks and shadow.strategy_marks[delta.to]
            local key = "Intention" .. delta.from
            if marks and marks[key] ~= nil then level = level + marks[key]; marks[key] = 0 end
            local ok, callback_error
            if standard_modes[mode]=="identity" then
                local accepted, _, _, reason=invoke(policy, "onIntention",query_world,
                    delta.from,delta.to,level,shadow,delta.defer_refresh,presentation,position+1)
                ok,callback_error=accepted,reason
            else
                local accepted, _, _, reason=invoke(policy, "onIntention",query_world,
                    delta.from,delta.to,level,shadow,delta.defer_refresh)
                ok,callback_error=accepted,reason
            end
            if not ok then return callback_error end
        end
    end
    local state_budget=standard_modes[mode]=="identity" and 32768 or 1024
    if not valid_state(shadow,nil,0,{remaining=state_budget}) then return "intention_state" end
    if prepared_intentions ~= pending or generation ~= prepared_generation then return "intention_stale" end
    local token = {}
    pending[token] = {mode=mode, viewer=viewer, owned=owned,
        original=original, generation=prepared_generation,
        -- A hook may retain its mutable shadow. Detach the validated result so
        -- subsequent changes to that reference cannot alter the prepared mind.
        shadow=clone_value(shadow), noop=not (session and session.queried) and effect_count == 0 and (count == 0 or policy == nil)}
    return token,presentation
end

prepare_event_prefix=function(world,deltas,effects)
    local token,presentation=sgs.prepareModeAIIntentions(world,deltas,effects)
    assert(type(token)=="table",token)
    local prepared=prepared_intentions[token]
    prepared_intentions[token]=nil
    assert(prepared,"event prefix preparation is not trusted")
    return prepared.shadow,presentation
end

-- Native callers disable their instruction hook before this tiny commit. Only
-- private, current, unused tokens can replace one viewer's state; no callbacks,
-- traversals, validation loops or exported mutable state occur here.
function sgs.commitModeAIIntentions(token)
    if type(token) ~= "table" then return "intention_prepared" end
    local prepared = prepared_intentions[token]
    if not prepared then return "intention_prepared" end
    prepared_intentions[token] = nil
    if prepared.generation ~= generation or prepared.owned ~= minds[prepared.mode]
        or prepared.original ~= (prepared.owned and prepared.owned[prepared.viewer]) then
        return "intention_stale"
    end
    if not prepared.noop then
        prepared.owned[prepared.viewer] = prepared.shadow
        generation = generation + 1
    end
    return nil
end

function sgs.updateModeAIIntentions(world, deltas, effects)
    local prepared = sgs.prepareModeAIIntentions(world, deltas, effects)
    if type(prepared) ~= "table" then return prepared end
    return sgs.commitModeAIIntentions(prepared)
end

-- Keep the legacy single-intention ABI while sharing the atomic batch consumer.
function sgs.updateModeAIIntention(world, from, to, level)
    if type(from) ~= "string" or type(to) ~= "string" or from == to or not finite(level) then return end
    local present = {[world.self.object_name]=true}
    for _, player in ipairs(world.players) do present[player.object_name] = true end
    if not present[from] or not present[to] then return end
    return sgs.updateModeAIIntentions(world, {{from=from, to=to, level=level}})
end

-- Cache only values, keyed by authoritative Room revision and hook/mind generation.
function sgs.modeAIWorld(ai)
    local revision = ai.room:aiStateRevision()
    local cache = ai._mode_world
    if cache and cache.revision == revision and ai._mode_generation == generation then return cache end
    cache = ai.room:buildAIWorldView(ai.player)
    ai._mode_world, ai._mode_generation = cache, generation
    return cache
end

local function current_ai()
    if current_self and current_self.room == global_room then return current_self end
    for _, ai in pairs(sgs.ais or {}) do
        if ai.room == global_room then return ai end
    end
end

local managed_rooms = setmetatable({}, {__mode="k"})
function sgs.modeAIEnabled(room, viewer)
    if standard_modes[room:getMode()] then return false end
    if policies[room:getMode()] then return true end
    -- This is exactly evaluateModeAI's admission rule. Ordinary identity SmartAI
    -- must not compute geometry, card zones and skill callbacks just to return false.
    local revision = room:aiStateRevision()
    local cached = managed_rooms[room]
    if cached and cached.revision == revision then return cached.custom_roles end
    local custom_roles = false
    for _, player in sgs.qlist(room:getAllPlayers(true)) do
        if player:getRoleEnum() == sgs.Player_UnknownRole then
            custom_roles = true
            break
        end
    end
    managed_rooms[room] = {revision=revision, custom_roles=custom_roles}
    return custom_roles
end

function sgs.installModeAI(SmartAI)
    local objective, friend, enemy = SmartAI.objectiveLevel, SmartAI.isFriend, SmartAI.isEnemy
    local update, compare, adjust = SmartAI.updatePlayers, SmartAI.compareRoleEvaluation, SmartAI.adjustAIRole
    local friends, enemies = SmartAI.getFriends, SmartAI.getEnemies
    local predictable, intentions = isRolePredictable, sgs.updateIntention
    local process, evaluate, counts = sgs.gameProcess, evaluateAlivePlayersRole, updateAlivePlayerRoles

    local function policy(ai)
        if not sgs.modeAIEnabled(ai.room, ai.player) then return nil end
        local world = sgs.modeAIWorld(ai)
        return world.mode_policy.managed and world or nil
    end
    local function relation(ai, from, to)
        if not from or not to then return "unknown" end
        if ai:isDualControlLinked(from, to) then return "friend" end
        local world = sgs.modeAIWorld(ai)
        local row = world.mode_policy.relations[from:objectName()]
        return row and row[to:objectName()] or "unknown"
    end
    function SmartAI:objectiveLevel(to)
        local world = policy(self)
        if not world then return objective(self, to) end
        if not to then return 0 end
        if to == self.player then return -3 end
        if self:isDualControlLinked(self.player, to) then return -2 end
        return world.mode_policy.objectives[to:objectName()] or 0
    end
    function SmartAI:isFriend(other, another)
        if not policy(self) then return friend(self, other, another) end
        return relation(self, another or self.player, other) == "friend"
    end
    function SmartAI:isEnemy(other, another)
        if not policy(self) then return enemy(self, other, another) end
        return relation(self, another or self.player, other) == "enemy"
    end
    function SmartAI:updatePlayers(changed)
        if not policy(self) then return update(self, changed) end
        self.role = self.player:getRole()
        evaluateAlivePlayersRole()
        updateAlivePlayerRoles()
        self.friends, self.friends_noself, self.enemies = {}, {}, {}
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if self:isFriend(p) then
                table.insert(self.friends, p)
                if p ~= self.player then table.insert(self.friends_noself, p) end
            elseif self:isEnemy(p) then table.insert(self.enemies, p) end
        end
        self.harsh_retain = false
    end
    function SmartAI:getFriends(player, no_self)
        if not policy(self) then return friends(self, player, no_self) end
        player = player or self.player
        local result = {}
        for _, target in sgs.qlist(self.room:getAlivePlayers()) do
            if (not no_self or target ~= player) and self:isFriend(target, player) then
                result[#result + 1] = target
            end
        end
        return result
    end
    function SmartAI:getEnemies(player)
        if not policy(self) then return enemies(self, player) end
        local result = {}
        for _, target in sgs.qlist(self.room:getAlivePlayers()) do
            if self:isEnemy(target, player or self.player) then result[#result + 1] = target end
        end
        return result
    end
    function SmartAI:compareRoleEvaluation(player, first, second)
        local world = policy(self)
        if not world then return compare(self, player, first, second) end
        local role = self.room:canSeeRole(self.player, player) and player:getRole() or "neutral"
        return (role == first or role == second) and role or "neutral"
    end
    function SmartAI:adjustAIRole(...)
        if not policy(self) then return adjust(self, ...) end
        self:updatePlayers(false)
    end
    function isRolePredictable(classical)
        local ai = current_ai()
        if ai then
            local world = policy(ai)
            if world then return world.mode_policy.predictable end
        elseif global_room and policies[global_room:getMode()] and not standard_modes[global_room:getMode()] then
            return false -- Initialization must not populate hidden identities in shared legacy tables.
        end
        return predictable(classical)
    end
    function sgs.gameProcess(arg, changed)
        local ai = current_ai()
        local world = ai and policy(ai)
        if not world then return process(arg, changed) end
        if arg then return world.mode_policy.game_process or 0 end
        return world.mode_policy.process_label or "neutral"
    end
    function evaluateAlivePlayersRole()
        local ai = current_ai()
        if not ai or not policy(ai) then return evaluate() end
        -- The shared legacy compatibility table contains public identities only.
        for _, p in sgs.qlist(ai.room:getAlivePlayers()) do
            sgs.ai_role[p:objectName()] = ai.room:isRoleRevealed(p) and p:getRole() or "neutral"
        end
    end
    function updateAlivePlayerRoles()
        local ai = current_ai()
        if not ai or not policy(ai) then return counts() end
        sgs.playerRoles = {lord=0, loyalist=0, rebel=0, renegade=0}
        for _, p in sgs.qlist(ai.room:getAlivePlayers()) do
            local role = ai.room:isRoleRevealed(p) and p:getRole() or "unknown"
            sgs.playerRoles[role] = (sgs.playerRoles[role] or 0) + 1
        end
    end
    function sgs.updateIntention(from, to, level)
        local ai = current_ai()
        if not ai or not policy(ai) then return intentions(from, to, level) end
        if not from or not to or not finite(level) then return end
        if sgs.ai_doNotUpdateIntenion then level = 0 end
        sgs.ai_doNotUpdateIntenion = nil
        if from == to then return end
        -- Mixed routes keep legacy role scoring, but the independent event
        -- pipeline is the sole producer of managed mode-mind updates.
        if not sgs.modeAIUsesIsolatedEvents then
            for _, observer in pairs(sgs.ais) do
                if observer.room == ai.room then
                    local world = sgs.modeAIWorld(observer)
                    sgs.updateModeAIIntention(world, from:objectName(), to:objectName(), level)
                end
            end
        end
        for _, observer in pairs(sgs.ais) do
            if observer.room == ai.room then observer:updatePlayers(false) end
        end
    end
end
