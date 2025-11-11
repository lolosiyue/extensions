--新势力：鬼，妖，圣，仙
do
	require "lua.config"
	local config = config
	table.insert(config.kingdoms, "kegui")
	config.kingdom_colors["kegui"] = "#96943D"
	table.insert(config.kingdoms, "keyao")
	config.kingdom_colors["keyao"] = "#96943D"
	table.insert(config.kingdoms, "kesheng")
	config.kingdom_colors["kesheng"] = "#96943D"
	table.insert(config.kingdoms, "kexian")
	config.kingdom_colors["kexian"] = "#96943D"
end

sgs.LoadTranslationTable{
	["kegui"] = "鬼",
	["keyao"] = "妖",
	["kesheng"] = "圣",
	["kexian"] = "仙",
}