-- Source: b6025acc ai/imagine-ai.lua.
local nullable={getWeapon=true,getArmor=true,sortByRecoverRate=true}
local function imagine_call(object,name,...)
    if object==nil then error("attempt to index a nil value",0) end
    local method=object[name]
    if type(method)~="function" then ai_unsupported("imagine method unavailable",name) end
    local value=method(object,...)
    if AIUnsupported and AIUnsupported.is(value) then error(value,0) end
    if value==nil and not nullable[name] and not (name=="damageIsEffective" and SmartAIView.isKnownNilStrategyResult(object,name,method)) then ai_unsupported("imagine input is unknown",name) end
    return value
end
local function imagine_log(self,site,text)
    -- The donor only logged here; there is no decision effect to reproduce.
end
--[[
	文件：imagine-ai.lua
	主题：场景模拟
	函数列表：
		SmartAI:AtomDamageCount(target,source,nature,card)
		SmartAI:DamageToCards(target,source,count)
		SmartAI:DamageToTurnOver(target,source,count)
		SmartAI:DamageResult(target,source,nature,card,chained)
		SmartAI:tdr(result,source,target)
		SmartAI:KingdomsCount(players)
		SmartAI:SortByAtomDamageCount(targets,source,nature,card,inverse)
]]
--[[
	函数名：AtomDamageCount
	功能：计算一次单体伤害的点数
	参数表：
		target：伤害目标
		source：伤害来源，默认值为nil（无源伤害）,推荐值为self.player（当前角色）
		nature：伤害属性，取值为：
			一般伤害：sgs.DamageStruct_Normal（默认值）
			火焰伤害：sgs.DamageStruct_Fire
			雷电伤害：sgs.DamageStruct_Thunder
		card：伤害所用卡牌，默认值为nil（没有卡牌）
	返回值：一个整数，表示伤害点数
]]
function SmartAIView:AtomDamageCount(target,source,nature,card)
	if not target then return 0 end--没有伤害目标直接返回0
	nature = nature or sgs.DamageStruct_Normal --伤害属性的默认值处理
	if not imagine_call(self,"damageIsEffective",target,nature,source)
	then return 0 end --伤害无效直接返回0
	local count = 1 --初始伤害点数
	local isSlash = false --杀造成的伤害
	local isNDTrick = false --非延时性锦囊造成的伤害
	if card then --卡牌伤害
		isSlash = imagine_call(card,"isKindOf","Slash")
		isNDTrick = imagine_call(card,"isNDTrick")
	end
	if imagine_call(target,"getMark","@late")>0 then --如果目标智迟中
		if isSlash or isNDTrick then --如果卡牌为杀或非延时性锦囊
			return 0
		end
	end
	if imagine_call(target,"hasSkill","wuyan") or imagine_call(target,"hasSkill","noswuyan") then --如果目标有技能无言
		if isNDTrick then --如果卡牌为非延时性锦囊
			return 0
		end
	end
	if imagine_call(target,"hasSkill","huoshou") or imagine_call(target,"hasSkill","juxiang") then --如果目标有技能祸首、巨象
		if isNDTrick and imagine_call(card,"isKindOf","SavageAssault") then --如果卡牌为南蛮入侵
			return 0
		end
	end
	if nature==sgs.DamageStruct_Fire then --如果是火焰伤害
		if imagine_call(target,"hasArmorEffect","Vine") then --如果目标装备了藤甲
			count = count+1
			imagine_log(self,"56","vine+1")
		end
        if imagine_call(target,"getMark","&kuangfeng")>0 then --如果目标有狂风标记
			count = count+1
			imagine_log(self,"60","gale+1")
		end
	end
	if source then --如果有伤害来源
		local weapon = imagine_call(source,"getWeapon")
		if weapon then
			if imagine_call(weapon,"isKindOf","GudingBlade") then --如果来源有古锭刀
				if isSlash and imagine_call(target,"isKongcheng") then --如果卡牌为杀且目标空城
					count = count+1
					imagine_log(self,"69","guding+1")
				end
			end
		end
		if imagine_call(source,"hasFlag","luoyi") then --如果来源有裸衣标志
			if isSlash or imagine_call(card,"isKindOf","Duel") then --如果卡牌为杀或决斗
				count = count+1
				imagine_log(self,"76","luoyi+1")
			end
		end
		if isSlash then --如果卡牌为杀
			if imagine_call(card,"hasFlag","drank") then --如果卡牌为酒杀
				count = count+1
				imagine_log(self,"82","drank+1")
			end
			if imagine_call(source,"hasSkill","jie") then --如果来源有技能疾恶
				if imagine_call(card,"isRed") then --如果是红杀
					count = count+1
					imagine_log(self,"87","jie+1")
				end
			end
		end
	end
	return count
end
--[[
	函数名：DamageToCards
	功能：模拟一次伤害带来的卡牌收入
	参数表：
		target：伤害目标
		source：伤害来源，默认值为nil（无源伤害）
		count：伤害点数，默认值为1
	返回值：table类型，表示卡牌收入。包含2个项目：
		thisIncome：table类型，表示对target方带来的卡牌收入情况，其中：
			Max：最高收入；
			Min：最低收入；
			Expectancy：收入的平均值。
		thatIncome：table类型，表示对target的对方带来的卡牌收入情况，其中：
			Max：最高收入；
			Min：最低收入；
			Expectancy：收入的平均值。
]]
function SmartAIView:DamageToCards(target,source,count)
	local result = {
		thisIncome = {
			Max = 0,
			Min = 0,
			Expectancy = 0,
		},
		thatIncome = {
			Max = 0,
			Min = 0,
			Expectancy = 0,
		}
	}
	local thisRangeMax = 0
	local thisRangeMin = 0
	local thatRangeMax = 0
	local thatRangeMin = 0
	--收入计算
	if target then --伤害目标必须存在
		local room = self.room
		local civil = false --是否自相残杀
		local enemies = {}
		local friends = {}
		local players = imagine_call(room,"getAlivePlayers")
		local others = imagine_call(room,"getOtherPlayers",target)
		if not count then
			count = 1
		end
		if source then
			civil = imagine_call(self,"isFriend",target,source)
		end
		for _,p in sgs.list(players)do --区分敌友
			if imagine_call(self,"isFriend",p,target) then
				table.insert(friends,p)
			else
				table.insert(enemies,p)
			end
		end
		--遗计（按点数结算）
		if imagine_call(target,"hasSkill","yiji") then
			thisRangeMax = thisRangeMax+2*count
			thisRangeMin = thisRangeMin+2*count
		end
		--节命（按点数结算，应取前count名补牌空间最大的同伴计总数）
		if imagine_call(target,"hasSkill","jieming") then
			for i=1,count,1 do
				local minCount = 6
				local maxCount = -1
				local flag = false
				for _,p in pairs(friends)do
					local maxhp = math.min(imagine_call(p,"getMaxHp"),5)
					local handcount = imagine_call(p,"getHandcardNum")
					local ct = maxhp-handcount
					if ct>maxCount then
						maxCount = ct
						flag = true
					end
					if ct<minCount then
						minCount = ct
						flag = true
					end
				end
				if flag then
					thisRangeMax = thisRangeMax+maxCount
					thisRangeMin = thisRangeMin+minCount
				end
			end
		end
		--反馈（按次数结算）
		if imagine_call(target,"hasSkill","fankui") then
			if source and not civil then
				thisRangeMax = thisRangeMax+1
				thisRangeMin = thisRangeMin+1
				thatRangeMax = thatRangeMax-1
				thatRangeMin = thatRangeMin-1
			end
		end
		--恩怨（按点数结算）
		if imagine_call(target,"hasSkill","enyuan") then
			if source and not civil then
				thisRangeMax = thisRangeMax+count
				thisRangeMin = thisRangeMin+count
				thatRangeMax = thatRangeMax-count
				thatRangeMin = thatRangeMin-count
			end
		end
		--刚烈（按次数结算）
		if imagine_call(target,"hasSkill","ganglie") then
			if source and not civil then
				if imagine_call(source,"getHandcardNum")>=2 then
					thatRangeMax = thatRangeMax-2 --选择弃牌
					thatRangeMin = thatRangeMin-0 --选择掉血
				end
			end
		end
		--放逐（包括极略中的放逐，按次数结算，这部分先这么写了，其实应该根据放逐本身的AI确定卡牌收入）
		if imagine_call(target,"hasSkill","fangzhu") or imagine_call(target,"hasSkill","jilve") then
			local flag = true
			local lost = imagine_call(target,"getLostHp")
			for _,p in pairs(friends)do
				if not imagine_call(p,"faceUp") then --放逐target一方
					thisRangeMax = thisRangeMax+lost
					thisRangeMin = thisRangeMin+lost
					flag = false
					break
				end
			end
			if flag then --放逐target的对方
				thatRangeMax = thatRangeMax+lost
				thatRangeMin = thatRangeMin+lost
			end
		end
		--破军（按次数结算，被忽略）
		--归心（按点数结算）
		if imagine_call(target,"hasSkill","guixin") then
			local maxlength = 0
			for _,p in sgs.list(players)do --统计场上
				local ct = imagine_call(p,"getCardCount",true)+imagine_call(p,"getJudgingArea"):length()
				if ct>maxlength then
					maxlength = ct
				end
			end
			local times = math.min(maxlength,count) --归心的次数
			for i=1,times,1 do
				local k = 0
				for _,p in pairs(enemies)do --由于是统计收益，也就是差值，所以只看能收对方多少牌就行了。
					if not imagine_call(p,"isAllNude") then
						k = k+1
					end
				end
				thisRangeMax = thisRangeMax+k --发动归心
				thisRangeMin = thisRangeMin+0 --不发动归心
				thatRangeMax = thatRangeMax-k --发动归心
				thatRangeMin = thatRangeMin-0 --不发动归心
			end
		end
		--誓仇
		if imagine_call(target,"hasLordSkill","shichou") then
			if target.tag then --这个总是nil，始终无效。
				local tag = imagine_call(target.tag,"value","ShichouTarget")
				if tag then
					local victim = imagine_call(tag,"toPlayer")
					if imagine_call(self,"isFriend",victim,target) then --被誓仇将伤害弹到自己人身上
						thisRangeMax = thisRangeMax+count
						thisRangeMin = thisRangeMin+count
					else --将伤害弹到对方身上
						thatRangeMax = thatRangeMax+count
						thatRangeMin = thatRangeMin+count
					end
				end
			end
		end
		--天香
		if imagine_call(target,"hasSkill","tianxiang") then
			if not imagine_call(target,"isKongcheng") then
				local maxCount = -1
				local minCount = 999
				local flag = false
				for _,p in pairs(enemies)do --将伤害弹到target的对方
					local lost = imagine_call(p,"getLostHp")
					if lost<minCount then
						minCount = lost
						flag = true
					end
					if lost>maxCount then
						maxCount = lost
						flag = true
					end
				end
				if flag then
					thatRangeMax = thatRangeMax+maxCount
					thatRangeMin = thatRangeMin+minCount
				end
				flag = false
				minCount = 999
				maxCount = -1
				for _,p in pairs(friends)do --将伤害弹到target一方
					local lost = imagine_call(p,"getLostHp")
					if lost<minCount then
						minCount = lost
						flag = true
					end
					if lost>maxCount then
						maxCount = lost
						flag = true
					end
				end
				if flag then
					thisRangeMax = thisRangeMax+maxCount-1
					thisRangeMin = thisRangeMin+minCount-1
				end
			end
		end
		--涅槃
		if imagine_call(target,"hasSkill","niepan") then
			if imagine_call(target,"getMark","@nirvana")>0 then
				if imagine_call(target,"getHp")<=count then
					local cardcount = imagine_call(target,"getCardCount",true) --原有的卡牌数目
					thisRangeMax = thisRangeMax-cardcount+3 --发动涅槃
					thisRangeMin = thisRangeMin+0 --不发动涅槃（被前位同伴所救）
				end
			end
		end
		--智愚
		if imagine_call(target,"hasSkill","zhiyu") then
			if source and not civil then
				thisRangeMax = thisRangeMax+1
				thisRangeMin = thisRangeMin+1
				thatRangeMax = thatRangeMax-1
				if imagine_call(target,"isKongcheng") then
					thatRangeMin = thatRangeMin-1 --依然同色
				else
					thatRangeMin = thatRangeMin-0 --不再同色
				end
			end
		end
		--连理
		if imagine_call(target,"getMark","@tie")>0 then
			for _,p in pairs(enemies)do
				if imagine_call(p,"getMark","@tie")>0 then
					thatRangeMax = thatRangeMax+count
					thatRangeMin = thatRangeMin+count
				end
			end
			for _,p in pairs(friends)do
				if imagine_call(p,"getMark","@tie")>0 then
					thisRangeMax = thisRangeMax+count
					thisRangeMin = thisRangeMin+count
				end
			end
		end
	end
	--产生结果
	result[thisIncome][Expectancy] = math.floor( (thisRangeMax+thisRangeMin)/2 ) --对己方收入向下取整
	result[thisIncome][Max] = thisRangeMax
	result[thisIncome][Min] = thisRangeMin
	result[thatIncome][Expectancy] = math.ceil( (thatRangeMax+thatRangeMax)/2 ) --对对方收入向上取整
	result[thatIncome][Max] = thatRangeMax
	result[thatIncome][Min] = thatRangeMin
	return result
end
--[[
	函数名：DamageToTurnOver
	功能：模拟一次伤害造成的翻面影响
	参数表：
		target：伤害目标
		source：伤害来源，默认为nil（无源伤害）
		count：伤害点数，默认为1
	返回值：table类型，包含2个项目：
		thisResult：table类型，表示对target一方造成的翻面影响，其中：
			turnOver：target一方受到翻面影响的人数（被翻面人数+被翻回人数）
			equalNum：对target一方造成的等价翻面人数（被翻面人数-被翻回人数）
			faceUp：伤害后target一方正面向上的人数
			faceDown：伤害后target一方背面向上的人数
		thatResult：table类型，表示对target的对方造成的翻面影响，其中：
			turnOver：target的对方受到翻面影响的人数（被翻面人数+被翻回人数）
			equalNum：对target的对方造成的等价翻面人数（被翻面人数-被翻回人数）
			faceUp：伤害后target的对方正面向上的人数
			faceDown：伤害后target的对方背面向上的人数
]]
function SmartAIView:DamageToTurnOver(target,source,count)
	local result = {
		thisResult = {
			turnOver = 0,
			equalNum = 0,
			faceUp = 0,
			faceDown = 0,
		},
		thatResult = {
			turnOver = 0,
			equalNum = 0,
			faceUp = 0,
			faceDown = 0,
		},
	}
	local thisTurnOverCount = 0
	local thatTurnOverCount = 0
	local thisDownCount = 0
	local thatDownCount = 0
	local thisEqualNum = 0
	local thatEqualNum = 0

	if target then
		local room = self.room
		local civil = false --是否自相残杀
		local enemies = {}
		local friends = {}
		local players = imagine_call(room,"getAlivePlayers")
		local others = imagine_call(room,"getOtherPlayers",target)
		if source then
			civil = imagine_call(self,"isFriend",target,source)
		end
		for _,p in sgs.list(players)do --区分敌友
			if imagine_call(self,"isFriend",p,target) then
				table.insert(friends,p)
				if not imagine_call(p,"faceUp") then
					thisDownCount = thisDownCount+1
				end
			else
				table.insert(enemies,p)
				if not imagine_call(p,"faceUp") then
					thatDownCount = thatDownCount+1
				end
			end
		end
		--放逐（包括极略中的放逐，按次数结算）
		if imagine_call(target,"hasSkill","fangzhu") or imagine_call(target,"hasSkill","jilve") then
			if thisDownCount>0 then
				thisDownCount = thisDownCount-1
				thisTurnOverCount = thisTurnOverCount+1
				thisEqualNum = thisEqualNum-1
			elseif imagine_call(target,"getLostHp") +count>=3 then
				thisDownCount = thisDownCount+1
				thisTurnOverCount = thisTurnOverCount+1
				thisEqualNum = thisEqualNum+1
			else
				thatDownCount = thatDownCount+1
				thatTurnOverCount = thatTurnOverCount+1
				thatEqualNum = thatEqualNum+1
			end
		end
		--破军（按次数结算，被忽略）

		--归心（按点数结算）
		if imagine_call(target,"hasSkill","guixin") then
			local flag = imagine_call(target,"faceUp")
			for i=1,count,1 do
				flag = not flag
				if flag then
					thisDownCount = thisDownCount-1
				else
					thisDownCount = thisDownCount+1
				end
			end
			if flag~=imagine_call(target,"faceUp") then
				thisTurnOverCount = thisTurnOverCount+1
				if flag then --从背面翻回正面
					thisEqualNum = thisEqualNum-1
				else --从正面翻到背面
					thisEqualNum = thisEqualNum+1
				end
			end
		end
		--酒诗
		if imagine_call(target,"hasSkill","jiushi") then
			if imagine_call(target,"faceUp") then --正面濒死造酒
				if imagine_call(target,"getHp")<=count then
					thisDownCount = thisDownCount+1
					thisTurnOverCount = thisTurnOverCount+1
					thisEqualNum = thisEqualNum+1
				end
			else --背面受伤翻回
				thisDownCount = thisDownCount-1
				thisTurnOverCount = thisTurnOverCount+1
				thisEqualNum = thisEqualNum-1
			end
		end
		--悲歌（被忽略）
		if imagine_call(target,"getHp")<=count then --模拟濒死场景
			--伏枥
			if imagine_call(target,"hasSkill","fuli") then
				if imagine_call(target,"getMark","@laoji")>0 then
					if imagine_call(target,"faceUp") then
						thisDownCount = thisDownCount+1
						thisEqualNum = thisEqualNum+1
					else
						thisDownCount = thisDownCount-1
						thisEqualNum = thisEqualNum-1
					end
					thisTurnOverCount = thisTurnOverCount+1
				end
			end
			--涅槃
			if imagine_call(target,"hasSkill","niepan") then
				if imagine_call(target,"getMark","@nirvana")>0 then
					if not imagine_call(target,"faceUp") then
						thisDownCount = thisDownCount-1
						thisTurnOverCount = thisTurnOverCount+1
						thisEqualNum = thisEqualNum-1
					end
				end
			end
		end
		--产生结果
		result[thisResult][turnOver] = thisTurnOverCount
		result[thisResult][equalNum] = thisEqualNum
		result[thisResult][faceUp] = #friends-thisDownCount
		result[thisResult][faceDown] = thisDownCount
		result[thatResult][turnOver] = thatTurnOverCount
		result[thatResult][equalNum] = thatEqualNum
		result[thatResult][faceUp] = #enemies-thatDownCount
		result[thatResult][faceDown] = thatDownCount
	end
	return result
end
--[[
	函数名：DamageResult
	功能：模拟一次伤害产生的后果
	参数表：
		target：伤害目标
		source：伤害来源，默认值为self.player（当前角色）
		nature：伤害属性，取值为：
			一般伤害：sgs.DamageStruct_Normal（默认值）
			火焰伤害：sgs.DamageStruct_Fire
			雷电伤害：sgs.DamageStruct_Thunder
		card：伤害所用卡牌，默认值为nil（没有卡牌）
		chained：是否考虑铁索连环的影响，取值为：
			考虑铁索连环：true（默认值）
			忽略铁索连环：false
	返回值：table类型，表示伤害结果。包含3个项目：
		damageValue：表示伤害总收益价值
		friendProfit：table类型，表示本次伤害对target一方造成的影响，其中：
			damageCount：对target一方造成的伤害点数
			cardsIncome：对target一方造成的手牌收入
			turnOver：对target一方造成的翻面人数
		enemyProfit：table类型，表示本次伤害对target的对方造成的影响，其中：
			damageCount：对target的对方造成的伤害点数
			cardsIncome：对target的对方造成的手牌收入
			turnOver：对target的对方造成的翻面人数
]]
function SmartAIView:DamageResult(target,source,nature,card,chained)
	local result = {
		damageValue = 0,
		friendProfit = {
			damageCount = 0,
			cardsIncome = 0,
			turnOver = 0,
		},
		enemyProfit = {
			damageCount = 0,
			cardsIncome = 0,
			turnOver = 0,
		},
	}
	local damageValue = 0
	local enemyProfit = {0,0,0}
	local friendProfit = {0,0,0}
	if target then --伤害目标必须存在
		if not nature then
			nature = sgs.DamageStruct_Normal
		end
		local shrink = false --伤害缩水标志
		local armor = imagine_call(target,"getArmor")
		if armor and imagine_call(armor,"isKindOf","SilverLion") then --目标装备有白银狮子
			shrink = true
		end
		--直接伤害
		local count = imagine_call(self,"AtomDamageCount",target,source,nature,card)
		if count>1 and shrink then
			count = 1
		end
		--DEBUG--
		imagine_log(self,"582",string.format("Now:immediateDamage=%d",count))

		local cardsEffect = imagine_call(self,"DamageToCards",target,source,count) --平均收入、最高收入、最低收入
		local turnOverEffect = imagine_call(self,"DamageToTurnOver",target,source,count) --翻面人数、正面人数、背面人数

		friendProfit[1] = friendProfit[1]+count --对target一方造成的伤害点数
		friendProfit[2] = friendProfit[2]+cardsEffect[thisIncome][Min] --对target一方造成的卡牌收入
		friendProfit[3] = friendProfit[3]+turnOverEffect[thisResult][equalNum] --对target一方造成的翻面影响
		damageValue = damageValue-2*friendProfit[1]+friendProfit[2]-2.5*friendProfit[3] --target一方收益
		--DEBUG--
		imagine_log(self,"592",
			string.format(
				"Now:damageValue=%d,fd=%d,fc=%d,ft=%d",
				damageValue,
				friendProfit[1],
				friendProfit[2],
				friendProfit[3]
				)
			)

		enemyProfit[1] = enemyProfit[1]+0 --对target对方造成的伤害点数
		enemyProfit[2] = enemyProfit[2]+cardsEffect[thatIncome][Max] --对target对方造成的卡牌收入
		enemyProfit[3] = enemyProfit[3]+turnOverEffect[thatResult][equalNum] --对target对方造成的翻面影响
		damageValue = damageValue+2*enemyProfit[1]-enemyProfit[3]+2.5*enemyProfit[3] --target对方收益
		--DEBUG--
		imagine_log(self,"607",
			string.format("Now:damageValue=%d,ed=%d,ec=%d,et=%d",
				damageValue,
				enemyProfit[1],
				enemyProfit[2],
				enemyProfit[3]
				)
			)

		--传导伤害
		if chained then --如果考虑铁索连环
			if nature~=sgs.DamageStruct_Normal then --如果是属性伤害
				if imagine_call(target,"isChained") then --如果目标被铁索连环
					local others = imagine_call(self.room,"getOtherPlayers",target)
					for _,p in sgs.list(others)do
						if imagine_call(p,"isChained") then
							--DEBUG--
							imagine_log(self,"624","in chained.")

							local SubResult = imagine_call(self,"DamageResult",p,source,nature,nil,false)
							if imagine_call(self,"isFriend",p,target) then
								friendProfit[1] = friendProfit[1]+SubResult[friendProfit][damageCount]
								friendProfit[2] = friendProfit[2]+SubResult[friendProfit][cardsIncome]
								friendProfit[3] = friendProfit[3]+SubResult[friendProfit][turnOver]
								damageValue = damageValue+SubResult[damageValue]
							else
								enemyProfit[1] = enemyProfit[1]+SubResult[enemyProfit][damageCount]
								enemyProfit[2] = enemyProfit[2]+SubResult[enemyProfit][cardsIncome]
								enemyProfit[3] = enemyProfit[3]+SubResult[enemyProfit][turnOver]
								damageValue = damageValue-SubResult[damageValue]
							end
						end
					end
				end
			end
		end
	end
	--产生最终结果
	result[damageValue] = damageValue
	result[friendProfit][damageCount] = friendProfit[1]
	result[friendProfit][cardsIncome] = friendProfit[2]
	result[friendProfit][turnOver] = friendProfit[3]
	result[enemyProfit][damageCount] = enemyProfit[1]
	result[enemyProfit][cardsIncome] = enemyProfit[2]
	result[enemyProfit][turnOver] = enemyProfit[3]
	return result
end
--[[
	函数名：tdr
	功能：测试DamageResult函数的结果
	参数表：result（待测试的结果）
	返回值：无
]]
function SmartAIView:tdr(result,source,target)
	local room = self.room
	local from = "nobody"
	local to = "nobody"
	if source then
		from = imagine_call(source,"getGeneralName")
	end
	if target then
		to = imagine_call(target,"getGeneralName")
	end
	imagine_log(self,"670","--------------------")
	imagine_log(self,"671","*******START********")
	imagine_log(self,"672",string.format("damage from %s to %s:",from,to))
	imagine_log(self,"673",string.format(" damageValue: %d",result[damageValue]))
	imagine_log(self,"674","target:")
	imagine_log(self,"675",string.format(" damageCount: %d",result[friendProfit][damageCount]))
	imagine_log(self,"676",string.format(" drawCards: %d",result[friendProfit][cardsIncome]))
	imagine_log(self,"677",string.format(" turnDelt: %d",result[friendProfit][turnOver]))
	imagine_log(self,"678","another:")
	imagine_log(self,"679",string.format(" damageCount: %d",result[enemyProfit][damageCount]))
	imagine_log(self,"680",string.format(" drawCards: %d",result[enemyProfit][cardsIncome]))
	imagine_log(self,"681",string.format(" turnDelt: %d",result[enemyProfit][turnOver]))
	imagine_log(self,"682","********END*********")
	imagine_log(self,"683","--------------------")
end
--[[
	函数名：KingdomsCount
	功能：统计指定范围内出现的势力数目
	参数表：players（QList<Player*>类型，表示待统计的范围）
	返回值：一个整数，表示范围内出现的势力的数目
]]

--[[
	函数名：SortByAtomDamageCount
	功能：按单体伤害对一组目标进行排序
	参数表：
		targets：目标列表，table类型
		source：伤害来源
		nature：伤害属性，取值为：
			一般伤害：sgs.DamageStruct_Normal（默认值）
			火焰伤害：sgs.DamageStruct_Fire
			雷电伤害：sgs.DamageStruct_Thunder
		card：伤害所用卡牌，默认值为nil（没有卡牌）
		inverse：排序顺序，取值为：
			true：按从小到大的顺序排序
			false：按从大到小的顺序排序（默认值）
	返回值：table类型，表示排序结果。
]]
function SmartAIView:SortByAtomDamageCount(targets,source,nature,card,inverse)
	if not nature then
		nature = sgs.DamageStruct_Normal
	end
	local compare_func = function(a,b)
		local damageA = imagine_call(self,"AtomDamageCount",a,source,nature,card)
		local damageB = imagine_call(self,"AtomDamageCount",b,source,nature,card)
		if damageA==damageB then
			if inverse then
				return imagine_call(a,"getHp")>=imagine_call(b,"getHp")
			else
				return imagine_call(a,"getHp")<=imagine_call(b,"getHp")
			end
		else
			if inverse then
				return damageA<damageB
			else
				return damageA>damageB
			end
		end
	end
	table.sort(targets,compare_func)
	return targets
end
--[[
	主题：集火
	函数列表：
		SmartAI:getDamagePoint(player)
		SmartAI:getRecoverPoint(player)
		SmartAI:RecoverRate(player)
		SmartAI:sortByRecoverRate(players,inverse)
		SmartAI:getFocusTarget(players)
]]
function SmartAIView:getDamagePoint(player)
	if player then
		return self:getImagineFocusMark(player,"FocusDamageCount")
	end
	return 0
end
function SmartAIView:getRecoverPoint(player)
	if player then
		return self:getImagineFocusMark(player,"FocusRecoverCount")
	end
	return 0
end
function SmartAIView:RecoverRate(player)
	if player then
		local room = imagine_call(player,"getRoom")
		local damage = self:getImagineFocusMark(player,"FocusDamageCount")
		local recover = self:getImagineFocusMark(player,"FocusRecoverCount")
		local rate = (recover+1)/damage
		return (recover+1)*rate+damage*0.05
	end
	return 1000
end
function SmartAIView:sortByRecoverRate(players,inverse)
	local compare_func = function(a,b)
		local rateA = imagine_call(self,"RecoverRate",a)
		local rateB = imagine_call(self,"RecoverRate",b)
		if rateA==rateB then
			return imagine_call(self,"getDamagePoint",a)<imagine_call(self,"getDamagePoint",b)
		else
			if inverse then
				return rateA>rateB
			else
				return rateA<rateB
			end
		end
	end
	table.sort(players,compare_func)
end
function SmartAIView:getFocusTarget(players)
	if players and #players>0 then
		imagine_call(self,"sortByRecoverRate",players)
		return players[1]
	end
end

-- SmartAI kept these counters as marks it added itself. They are this observer's
-- own bookkeeping, so they live in its strategy memory.
function SmartAIView:getImagineFocusMark(player,name)
    assert(name=="FocusDamageCount"or name=="FocusRecoverCount","invalid Focus mark")
    local counts=self:getStrategyMemory("imagine_focus") or {}
    return counts[imagine_call(player,"objectName")..":"..name] or 0
end
local function focus_increment(self,player,event,name,kind)
    local counts=self:getStrategyMemory("imagine_focus") or {}
    local key=imagine_call(player,"objectName")..":"..name
    counts[key]=(counts[key] or 0)+1
    self:setStrategyMemory("imagine_focus",counts)
end
for event,callback in pairs({
    -- Damaged is not delivered to this VM; DamageInflicted is its canonical stage.
    [sgs.DamageInflicted or "DamageInflicted"]=function(self,player,event)focus_increment(self,player,event,"FocusDamageCount","damage")end,
    [sgs.HpRecover or "HpRecover"]=function(self,player,event)focus_increment(self,player,event,"FocusRecoverCount","recover")end})do
    sgs.ai_event_callback[event]=sgs.ai_event_callback[event]or{}
    sgs.ai_event_callback[event].general=callback
end
