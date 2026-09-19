-- 共用入口的型別邊界：明確辨識原生 userdata、值代理與純 ID，不靠 type() 猜。
-- gameplay VM 由 smart-ai.lua dofile 載入；這裡只用純 Lua，不碰 Engine、Room
-- 或任何 gameplay 全域，隔離側與契約測試才能載同一份定義。
-- 隔離 VM 先載入 isolated-facades.lua 才有 AIValue；gameplay VM 沒有代理，一律回 nil。
function aiValueKind(value)
	if type(value)~="table" or type(AIValue)~="table" then return end
	return AIValue.kind(value)
end

-- 未支援不是「空集合」也不是「沒有」：明講哪個入口還沒接受哪種代理，
-- 不靜默回退到原生查詢或預設決策。非代理輸入回 false，維持原有分支。
function aiRejectValueView(entry,value)
	local kind = aiValueKind(value)
	if not kind then return false end
	error(entry.." does not accept the isolated "..kind.." view yet",3)
end

-- 卡牌身份一律以 effective id 比較：CardView 每次查詢都是新代理，不能假定 pointer 相同。
function aiCardId(card)
	if type(card)=="userdata" or aiValueKind(card)=="card" then card = card:getEffectiveId() end
	card = tonumber(card)
	return card and card>=0 and card or nil
end

-- 技能身份是名稱加實例：同名多實例只比 objectName 會被誤判成同一個技能。
-- 原生 Skill 沒有 instance getter，實例由呼叫端提供；SkillView 自己帶。
function aiSkillKey(skill,instance_id)
	local name
	if type(skill)=="string" then name = skill
	elseif type(skill)=="userdata" then name = skill:objectName()
	elseif aiValueKind(skill)=="skill" then
		name = skill:objectName()
		if instance_id==nil then instance_id = skill:getInstanceId() end
	else return end
	if type(instance_id)=="number" and instance_id>0 then return name.."#"..instance_id end
	return name
end
