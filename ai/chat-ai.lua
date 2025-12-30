sgs.ai_chat = {}

function AIChat(p)
	if p and p:getState()~="robot" then return end
	return global_delay>0 and sgs.ai_humanized--sgs.AIChat
end

sgs.ai_event_callback[sgs.Death].stupid_lord=function(self,player,data)
	if not AIChat(player) then return end
	local damage=data:toDeath().damage
	local chat = {
		"2B了吧",
		"我那么忠诚，竟落得如此下场....",
		"我为主上出过力，呃啊.....",
		"主要臣死，臣不得不死",
		"昏君！",
		"还有更2的吗",
		"真的很无语"
	}
	if damage and damage.from and damage.from:isLord()
	and self.role=="loyalist"and damage.to==player
	then damage.to:speak(chat[math.random(1,#chat)]) end
end

sgs.ai_event_callback[sgs.Dying].fuck_renegade=function(self,player,data)
	local dying = data:toDying()
	if dying.who~=player or not AIChat(player) or math.random()>0.5
	or player:aliveCount()-#self.enemies<2 then return end
	local chat = {
		"999...999...",
		"来捞一下啊...."
	}
	if self.role~="renegade" and sgs.playerRoles["renegade"]>0 then
		table.insert(chat,"9啊，不9就输了")
		table.insert(chat,"小内你还不救，要崩盘了")
		table.insert(chat,"没戏了小内不出手全部托管吧")
		table.insert(chat,"小内，我死了你也赢不了")
	end
	if self:getAllPeachNum()+player:getHp()<1
	and #self.friends_noself>0 then
		table.insert(chat,"寄")
		table.insert(chat,"要寄.....")
		table.insert(chat,"还有救吗.....")
	end
	if #self.enemies<player:aliveCount()-1 then
		table.insert(chat,"不要见死不救啊.....")
		table.insert(chat,"我还不能死.....")
		table.insert(chat,"6了6了")
		table.insert(chat,"6")
	end
	player:speak(chat[math.random(1,#chat)])
end

sgs.ai_event_callback[sgs.DamageForseen].kylin_bow = function(self,player,data)
	local damage = data:toDamage()
	if AIChat(player) and damage.card and damage.from
	and damage.card:isKindOf("Slash") and damage.from:hasWeapon("KylinBow")
	and (player:getOffensiveHorse() or player:getDefensiveHorse())
	and self:isEnemy(damage.from) and math.random()<0.6 then
		local chat = {
			"我靠，5弓",
			"敢杀我马？",
			"我的宝驹.....",
			"蛤！我的千里驹",
			"我马药丸...."
		}
		player:speak(chat[math.random(1,#chat)])
	end
end

sgs.ai_event_callback[sgs.CardFinished].analeptic = function(self,player,data)
	if not AIChat() then return end
	local use = data:toCardUse()
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if math.random()>0.95 and p:getState()=="robot"
		then p:speak("<#"..math.random(1,56).."#>") end
	end
	if use.card:isKindOf("Analeptic") and player:getPhase()<=sgs.Player_Play
	and use.card:getSkillName()~="zhendu" then
		local chat = {
			"!",
			"不要吓我..."
		}
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if p:getState()=="robot" and not self:isFriend(p)
			and math.random()<0.3 then
				if p:getLostHp()<1 then
					table.insert(chat,"喜闻乐见")
					table.insert(chat,"我满血，不慌")
					table.insert(chat,"来呀，来砍我呀，我满血")
					table.insert(chat,"系兄弟就来啃我！")
				end
				if p:getHp()<3 and #self.enemies>1 then
					table.insert(chat,"队友呢，有桃没？")
					table.insert(chat,"有点慌，但有队友应该可以...")
				elseif p:getHp()>3 then
					table.insert(chat,"我血多，不怕")
					table.insert(chat,"绝对带不走")
					table.insert(chat,"我菊花一紧")
				end
				if p:getHandcardNum()>0 then
					table.insert(chat,"打不中的")
					table.insert(chat,"猜猜我有没有闪")
					table.insert(chat,"不要砍我，我有"..PatternsCard("jink"):getLogName())
					table.insert(chat,"没闪，但是有"..PatternsCard("peach"):getLogName())
				else
					if player:canSlash(p) then
						table.insert(chat,"敢不敢放过我")
						table.insert(chat,"空城..药丸...")
						table.insert(chat,"不要杀我，我给你钱（先打欠条）")
					else
						table.insert(chat,"我没牌，可惜了你")
						table.insert(chat,"哎呀，打不到，哈哈哈")
						table.insert(chat,"前排围观，出售爆米花，矿泉水，花生，瓜子...")
					end
				end
				p:speak(chat[math.random(1,#chat)])
			end
		end
	elseif use.card:isKindOf("Crossbow") then
		local chat = {
			"你小子早该突突了！",
			"哒哒哒！",
			"杀！杀！杀！",
			"AK来了~~",
			"随机送走一位童鞋",
			"看我反手掏出这大家伙",
			"满手的杀哦"
		}
		if player:getState()=="robot"
		and (self:getCardsNum("Slash")>1 or math.random()<0.4 and player:getHandcardNum()>1)
		then player:speak(chat[math.random(1,#chat)]) end
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if p:getState()=="robot" and math.random()<0.3
			and not self:isFriend(p,player) then
				chat = {"额，AK出现了","有点危险","得找机会拿过来","好家伙"}
				if player:canSlash(p) then
					if p:getLostHp()<1 then
						table.insert(chat,"我满血，不慌")
						table.insert(chat,"来呀，来砍我呀，我满血")
					end
					if getCardsNum("Slash",player,p)<1
					and player:getHandcardNum()<5 then
						table.insert(chat,"我赌你没有杀")
						table.insert(chat,"断杀，啊哈哈哈哈")
						table.insert(chat,"你这趁手的AK怎么没有弹药呢，哈哈哈")
					else
						table.insert(chat,"不要砍我....")
						table.insert(chat,"我是你队友，不要打错了")
						table.insert(chat,"其实我是他们的卧底")
						table.insert(chat,"我可以改邪归正，弃暗投明")
						table.insert(chat,"我愿归降，求您放过我...")
					end
				else
					table.insert(chat,"可惜够不着我呢~~~")
					table.insert(chat,"哎呀呀，距离不够，哈哈哈")
					table.insert(chat,"打不着~~打不着~~")
				end
				p:speak(chat[math.random(1,#chat)])
			end
		end
	elseif use.card:isKindOf("Peach") then
		for chat,p in sgs.qlist(use.to)do
			if p==use.from or p:getHp()<1
			or p:getState()~="robot" then continue end
			if use.from:isFemale() and math.random()<0.2
			and p:getGender()~=use.from:getGender()
			and use.from:getState()=="robot" then
				use.from:speak("复活吧，我的勇士")
				p:speak("为你而战，我的女王")
			elseif math.random()<0.5 then
				chat = {
					"大人功德无量！",
					"杀不死的我，会更加强大！",
					"哼，我还是有队友的",
					"还好有队友",
					"救我苟命，不胜感激",
					"天命在我，不该绝矣",
					"哈哈，活了",
					"差点无了.....",
					"活下来了....",
					"谢了.....",
					"还好还好"
				}
				p:speak(chat[math.random(1,#chat)])
			end
		end
	elseif use.card:isKindOf("OffensiveHorse")
	and player:getState()=="robot" then
		for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
			if self:isEnemy(player,p) and player:distanceTo(p,1)==2 and math.random()<0.2
			then player:speak("妖人"..p:screenName().."你往哪里跑") return end
		end
	end
end

sgs.ai_event_callback[sgs.PreCardUsed].CardUse = function(self,player,data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if player:getState()=="robot" then
		local ac = sgs.ai_chat[use.card:objectName()]
		if player:isFemale() then ac = sgs.ai_chat[use.card:objectName().."_female"] or ac end
		if type(ac)=="table" and math.random()<0.6
		then player:speak(ac[math.random(1,#ac)])
		elseif type(ac)=="function" then ac(self)
		elseif use.card:getSkillName():match("luanji") then
			if not sgs.ai_yuanshao_ArcheryAttack
			or #sgs.ai_yuanshao_ArcheryAttack<1 then
				sgs.ai_yuanshao_ArcheryAttack = {
					"此身，为剑所成",
					"血如钢铁，心似琉璃",
					"跨越无数战场而不败",
					"未尝一度被理解",
					"亦未尝一度有所得",
					"剑之丘上，剑手孤单一人，沉醉于辉煌的胜利",
					"铁匠孑然一身，执著于悠远的锻造",
					"因此，此生没有任何意义",
					"那么，此生无需任何意义",
					"这身体，注定由剑而成"
				}
			end
			player:speak(sgs.ai_yuanshao_ArcheryAttack[1])
			table.remove(sgs.ai_yuanshao_ArcheryAttack,1)
		end
	end
	if use.card:isDamageCard()
	and use.to:length()>player:aliveCount()/2 then
		local chat = {
			"我靠，AOE",
			"喜闻乐见",
			"蛤！"
		}
		self.aoeTos = use.to
		for _,p in sgs.qlist(self.room:getOtherPlayers(use.from))do
			if math.random()<0.8 or p:getState()~="robot" then continue end
			if use.to:contains(p) and self:aoeIsEffective(use.card,p,use.from) then
				if self:isWeak(p) or p:isKongcheng() then
					table.insert(chat,"不要哇")
					table.insert(chat,"不要收割我....")
					table.insert(chat,"有点慌")
				else
					table.insert(chat,"血多，不慌")
				end
				if use.from:usedTimes(use.card:getClassName())>1 then
					table.insert(chat,"哪来这么多AOE啊")
					table.insert(chat,"你特么....")
					table.insert(chat,"怎么还有....")
					table.insert(chat,"还来....")
				end
			else
				table.insert(chat,"呃哈哈")
				table.insert(chat,"此计伤不到我")
				table.insert(chat,"此小计尔")
				table.insert(chat,"哎呀打不动")
				table.insert(chat,"坐山观斗虎")
			end
			p:speak(chat[math.random(1,#chat)])
		end
		self.aoeTos = nil
	elseif use.card:isKindOf("Slash") then
		local chat ={
			"您老悠着点儿阿",
			"泥玛杀我，你等着阿",
			"再杀！老子和你拼命了"
		}
		for _,p in sgs.qlist(use.to)do
			if math.random()>0.3 or p:getState()~="robot" then continue end
			if sgs.ai_role[p:objectName()]=="neutral" then
				table.insert(chat,"盲狙一时爽啊,我泪奔")
				table.insert(chat,"我次奥，盲狙能不能轻点？")
				if use.from:usedTimes("Analeptic")>0 then
					table.insert(chat,"喝醉了吧，乱砍人？")
				end
			end
			if p:getRole()~="lord"
			and self:hasCrossbowEffect(use.from) then
				table.insert(chat,"杀得我也是醉了。。。")
				table.insert(chat,"果然是连弩降智商....")
				table.insert(chat,"杀死我也没牌拿，真2")
			end
			if use.from:getRole()=="lord"
			and sgs.playerRoles.loyalist>0
			and sgs.ai_role[p:objectName()]~="rebel" then
				table.insert(chat,"尼玛眼瞎啊，老子是忠！")
				table.insert(chat,"主公别打我，我是忠")
				table.insert(chat,"主公别开枪，自己人")
				table.insert(chat,"再杀我，你会裸")
			end
			p:speak(chat[1+(os.time()%#chat)])
		end
	end
end

sgs.ai_event_callback[sgs.EventPhaseStart].luanwu = function(self,player,data)
	if not AIChat() then return end
	if player:getPhase()==sgs.Player_Play and self.player:getMark("@chaos")>0
	and self.player:hasSkill("luanwu") then
		local chat = {
			"乱一个，乱一个",
			"要乱了",
			"要死....",
			"完了，没杀"
		}
		local chat1 = {
			"不要紧张",
			"乱世随时开始",
			"月黑风高夜，杀人放火时！",
			"准备好了吗？"
		}
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if p~=player and p:getState()=="robot" and math.random()<0.2
			then p:speak(chat[math.random(1,#chat)])
			elseif p==player and p:getState()=="robot" and math.random()<0.1
			then p:speak(chat1[math.random(1,#chat1)]) end
		end
	end
	if player:getState()~="robot" then return end
	local chat = {
		"有货，可以来搞一下",
		"有闪有黑桃",
		"看我眼色行事",
		"没闪,忠内不要乱来",
		"不爽，来啊！砍我啊",
		"求杀求砍求蹂躏",
	}
	if player:getPhase()==sgs.Player_Finish and not player:isKongcheng()
	and player:hasSkills("leiji|nosleiji|olleiji") and os.time()%10<4
	then player:speak(chat[1+(os.time()%#chat)]) end
	if player:getPhase()==sgs.Player_Start and math.random()<0.4
	and sgs.playerRoles["renegade"]+sgs.playerRoles["loyalist"]<1
	and sgs.playerRoles["rebel"]>=2 then
		if self.role=="rebel" then
			chat = {
				"大家一起围观主公",
				"不要一下弄死了，慢慢来",
				"主公投降吧，免受皮肉之苦",
				"速度，一人一下弄死",
				"怎么成光杆司令了啊",
				"哈哈哈主公阿",
				"包养主公了",
				"投降给全尸"
			}
		else
			if sgs.turncount>4 then
				chat = {
					"看我一人包围你们全部......",
					"这就是所谓一人包围全场",
					"已经是最后的希望了",
					"最后的希望么？",
					"纵死，我亦无惧",
					"我要杀出重围",
					"我将不屈服",
					"（苦笑）",
					"哈哈哈，这是我最后的荣光了"
				}
			else
				chat = {
					"啊这",
					"怎么全都死了",
					"我竟进入如此境地",
					"看我一人包围你们全部......",
					"不好，被包围了",
					"不要轮我",
					"（苦笑）"
				}
			end
		end
		player:speak(chat[math.random(1,#chat)])
	end
	if player:getPhase()==sgs.Player_RoundStart
	and self.room:getMode()=="08_defense"
	and math.random()<0.3 then
		local kingdom = self.player:getKingdom()
		local chat1 = {
			"无知小儿，报上名来，饶你不死！",
			"剑阁乃险要之地，诸位将军须得谨慎行事。",
			"但看后山火起，人马一齐杀出！"
		}
		local chat2 = {
			"嗷~！",
			"呜~！",
			"咕~！",
			"呱~！",
			"发动机已启动，随时可以出发——"
		}
		if kingdom=="shu" then
			table.insert(chat1,"人在塔在！")
			table.insert(chat1,"汉室存亡，在此一战！")
			table.insert(chat1,"星星之火，可以燎原")
			table.insert(chat2,"红色！")
		elseif kingdom=="wei" then
			table.insert(chat1,"众将官，剑阁去者！")
			table.insert(chat1,"此战若胜，大业必成！")
			table.insert(chat1,"一切反动派都是纸老虎")
			table.insert(chat2,"蓝色！")
		end
		if string.find(self.player:getGeneral():objectName(),"baihu") then table.insert(chat2,"喵~！") end
		if string.find(self.player:getGeneral():objectName(),"jiangwei") then  --姜维
			table.insert(chat1,"白水地狭路多，非征战之所，不如且退，去救剑阁")
			table.insert(chat1,"若剑阁一失，是绝路也。")
			table.insert(chat1,"今四面受敌，粮道不同，不如退守剑阁，再作良图。")
		elseif string.find(self.player:getGeneral():objectName(),"dengai") then  --邓艾
			table.insert(chat1,"剑阁之守必还赴涪，则会方轨而进")
			table.insert(chat1,"剑阁之军不还，则应涪之兵寡矣")
			table.insert(chat1,"以愚意度之，可引一军从阴平小路出汉中德阳亭")
			table.insert(chat1,"用奇兵径取成都，姜维必撤兵来救，将军乘虚就取剑阁，可获全功")
		elseif string.find(self.player:getGeneral():objectName(),"simayi") then  --司马懿
			table.insert(chat1,"吾前军不能独当孔明之众，而又分兵为前后，非胜算也")
			table.insert(chat1,"不如留兵守上邽，余众悉往祁山")
			table.insert(chat1,"蜀兵退去，险阻处必有埋伏，须十分仔细，方可追之。")
		elseif string.find(self.player:getGeneral():objectName(),"zhugeliang") then --诸葛亮
			table.insert(chat1,"老臣受先帝厚恩，誓以死报")
			table.insert(chat1,"今若内有奸邪，臣安能讨贼乎？")
			table.insert(chat1,"吾伐中原，非一朝一夕之事")
			table.insert(chat1,"正当为此长久之计")
		end
		if string.find(self.player:getGeneral():objectName(),"machine")
		then p:speak(chat2[math.random(1,#chat2)])
		else p:speak(chat1[math.random(1,#chat1)]) end
	end
	if isRolePredictable() then
	elseif player:getPhase()==sgs.Player_RoundStart
	and math.random()<0.2 then
		local friend_name,enemy_name
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if self:isFriend(p) and math.random()<0.5 then friend_name = p:getLogName()
			elseif self:isEnemy(p) and math.random()<0.5 then enemy_name = p:getLogName() end
		end
		local chat1 = {
			"要记住该跳就跳，不要装身份",
			"装什么身份，跳啊",
			"到底谁是内啊？",
			"都在这装呢？",
			"还在这装呢"
		}
		local quick = {
			"都快点，我还要去吃饭呢",
			"都快点，打完这局我要去取快递",
			"都快点，我要去做面膜的",
			"都快点，打完这局我要去约会呢",
			"都快点，打完这局我要去跪搓衣板",
			"都快点，打完这局我要去混班了",
			"都快点，打完这局我要睡觉了",
			"都快点，打完这局我要去打代码",
			"都快点，打完这局我要去撸啊撸",
			"都快点，打完这局我要去打电动了",
			"都快点，我要开新局",
		}
		local role1 = {
			"孰忠孰反，吾早已明辨",
			"都是反，怎么打！"
		}
		local role2 = {
			"当忠臣嘛，个人能力要强",
			"装个忠我容易嘛我",
			"这主坑内，跳反了",
			"这主坑内，投降算了"
		}
		local role3 = {
			"反贼都集火啊！集火！",
			"我们根本没有输出",
			"输出，加大输出啊！",
			"对这种阵容，我已经没有希望了"
		}
		chat = {}
		if friend_name then
			table.insert(role1,"忠臣"..friend_name.."，你是在坑我吗？")
			table.insert(role1,friend_name.."你不会是奸细吧？")
		end
		if enemy_name then
			table.insert(chat1,enemy_name.."你小子怎么了啊")
			table.insert(chat1,"游戏可以输，你"..enemy_name.."必须死！")
			table.insert(chat1,enemy_name.."你这样坑队友，连我都看不下去了")
		end
		if math.random()<0.2 then
			table.insert(chat,quick[math.random(1,#quick)])
		end
		if math.random()<0.3 then
			table.insert(chat,chat1[math.random(1,#chat1)])
		end
		if player:isLord() then table.insert(chat,role1[math.random(1,#role1)])
		elseif sgs.ai_role[player:objectName()]=="loyalist"
		or sgs.ai_role[player:objectName()]=="renegade" and math.random()<0.2
		then table.insert(chat,role2[math.random(1,#role2)])
		elseif sgs.ai_role[player:objectName()]=="rebel"
		or sgs.ai_role[player:objectName()]=="renegade" and math.random()<0.2
		then table.insert(chat,role3[math.random(1,#role3)]) end
		if #chat>0 and sgs.turncount>=2 then
			player:speak(chat[math.random(1,#chat)])
		end
	end
	if player:getPhase()==sgs.Player_Play
	and player:hasSkill("jieyin") then
		chat = {
			"香香睡我",
			"香香救我",
			"香香，我快没命了"
		}
		local chat1 = {
			"牌不够啊",
			"哼，考虑考虑",
			"让我斟酌斟酌"
		}
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if p~=player and p:getState()=="robot" and self:isFriend(p)
			and p:isMale() and self:isWeak(p) then p:speak(chat[math.random(1,#chat)])
			elseif p==player and p:getState()=="robot" and math.random()<0.1
			then p:speak(chat1[math.random(1,#chat1)]) end
		end
	end
end

sgs.ai_event_callback[sgs.ChoiceMade].state = function(self,player,data)
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if math.random()>0.97 and AIChat(p)
		then p:speak("<#"..math.random(1,56).."#>") end
	end
end

sgs.ai_event_callback[sgs.DrawNCards].screen = function(self,player,data)
	local draw = data:toDraw()
	if draw.reason~="InitialHandCards" then return end
	local sn = player:screenName()
	if sn:match("神小杀")
	and AIChat(player) then
		local speaks = {
			sn.."准备就绪",
			sn.."随时可以开始",
			sn.."程序加载完成",
			sn.."准备好了",
			sn.."进入游戏成功"
		}
		player:speak(speaks[math.random(1,#speaks)])
	end
end

sgs.ai_event_callback[sgs.StartJudge].isBad = function(self,player,data)
	local judge = data:toJudge()
	if judge:isBad() and math.random()<0.6 then
		local dc = dummyCard(judge.reason)
		if not(dc and dc:isDamageCard()) then return end
		local chat = {
			"我靠，天谴之子",
			"竞是如此",
			"蛤！炸了",
			"劈哩批哩喽"
		}
		if player:getKingdom()=="wei" then
			table.insert(chat,"大魏招雷术")
			table.insert(chat,"大魏引雷法")
			table.insert(chat,"这就是大魏")
		end
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if math.random()>0.77 and AIChat(p) then
				if self:isFriend(p,player) then
					table.insert(chat,"不可能！")
					table.insert(chat,"不可以！")
					table.insert(chat,"那种事情不要啊.....")
					if #self.friends_noself>0 then
						table.insert(chat,"有改判的吗.....")
						table.insert(chat,"判官，我要重新裁决.....")
					end
				else
					table.insert(chat,"该！")
					table.insert(chat,"哦嚯")
					table.insert(chat,"早该劈劈了")
					table.insert(chat,"一次不够，下次我也放雷")
					table.insert(chat,"你小子做了什么伤天害理之事啊")
					table.insert(chat,"这就是天弃之子")
				end
				p:speak(chat[math.random(1,#chat)])
			end
		end
	end
end

function SmartAI:speak(cardtype,isFemale)
	if AIChat(self.player) then else return end
	local ac = sgs.ai_chat[cardtype]
	if type(ac)=="function" then ac(self)
	elseif type(ac)=="table" then
		if isFemale then ac = sgs.ai_chat[cardtype.."_female"] or ac end
		if self.player:getPhase()<=sgs.Player_Play then self.room:getThread():delay(math.random(global_delay*0.5,global_delay*1.5))
		elseif self.player:hasFlag("Global_Dying") then self.room:getThread():delay(math.random(global_delay,global_delay*2)) end
		self.player:speak(ac[math.random(1,#ac)])
		return true
	end
end

sgs.ai_chat.blade={
	"这把刀就是我爷爷传下来的，上斩逗比，下斩傻逼！",
	"尚方宝刀，专戳贱逼!"
}

sgs.ai_chat.no_peach_female = {
	"妾身不玩了！",
	"哇啊欺负我，不玩了" ,
	"放下俗物，飘飘升仙" ,
	"你们好意思欺负我一个女孩子吗....",
	"哼，本姑娘不伺候了"
}

sgs.ai_chat.no_peach = {
	"yoooo少年，不溜等什么",
	"摆烂.....",
	"看我主动走小道",
	"不挣扎了",
	"有桃不吃，先走了",
	"开下一局，走了",
	"围观我？我直接超脱",
	"投个降先"
}

sgs.ai_chat.yiji={
	"再用力一点",
	"再来再来",
	"要死了啊!"
}

sgs.ai_chat.null_card={
	"想卖血？",
	"我不想让你受伤！",
	"我不喜欢你扣血.....",
	"没事掉什么血啊",
	"我来保护你！！",
	"你这血我扣下了",
	"你不能受到1点伤害",
	"只有我可怜你哦~~~",
	"精血很贵的，还是留着吧",
	"看，只有我在意你，不让你受伤",
	"哼哼!"
}

sgs.ai_chat.snatch_female = {
	"啧啧啧，来帮你解决点牌吧",
	"叫你欺负人!" ,
	"看你就不是好人",
	"你留着牌就是祸害"
}

sgs.ai_chat.snatch = {
	"yoooo少年，不来一发么",
	"果然还是看你不爽",
	"你的牌太多辣",
	"摸你一下看看",
	"我看你霸气外露，不可不防啊"
}

sgs.ai_chat.dismantlement_female = sgs.ai_chat.snatch_female

sgs.ai_chat.dismantlement = sgs.ai_chat.snatch

sgs.ai_chat.dismantlement_female = sgs.ai_chat.snatch_female

sgs.ai_chat.zhujinqiyuan = sgs.ai_chat.snatch

sgs.ai_chat.zhujinqiyuan_female = sgs.ai_chat.snatch_female

sgs.ai_chat.respond_hostile={
	"擦，小心菊花不保",
	"内牛满面了",
	"哎哟我去"
}

sgs.ai_chat.friendly={
	"。。。"
}

sgs.ai_chat.respond_friendly={
	"谢了。。。"
}

sgs.ai_chat.duel_female={
	"不要拒绝哦",
	"小女子我也要亲自上场了",
	"哼哼哼，怕了吧"
}

sgs.ai_chat.duel={
	"不要回避！",
	"来直面挑战吧！",
	"哈哈哈，我的杀一定比你多！",
	"来吧！像个勇士一样决斗吧！"
}

sgs.ai_chat.ex_nihilo={
	"哎哟运气好",
	"手气不错",
	"无中复无中！？",
	"抽个大牌",
	"哈哈哈哈哈"
}

sgs.ai_chat.dongzhuxianji = sgs.ai_chat.ex_nihilo

sgs.ai_chat.collateral_female={
	"将军，帮帮妾身吧",
	"就替妾身手刃他吧",
	"这人欺负我，打他"
}

sgs.ai_chat.collateral={
	"你的刀，就是我的刀",
	"你的剑，就是我的剑！",
	"替我————杀了他",
	"借汝之刀一用！"
}

sgs.ai_chat.amazing_grace_female={
	"让我看看，有什么好东西呢",
	"人人有份哟",
	"风调雨顺，五谷丰登",
	"丰收喽~~~~"
}

sgs.ai_chat.amazing_grace={
	"开仓，放粮！",
	"俺颇有家资",
	"一人一口，分而食之",
	"来分牌喽！"
}

sgs.ai_chat.supply_shortage={
	"嘻嘻，不给你摸",
	"你最好不是摸牌白",
	"看我断你口粮",
	"做个饿死鬼去吧！"
}

sgs.ai_chat.supply_shortageIsGood={
	"果然要天过",
	"嚯~~~~",
	"天可怜见",
	"哈哈哈哈哈哈哈哈哈",
	"废兵也就这样了"
}

sgs.ai_chat.collateralNoslash_female={
	"将军，妾身帮不了你",
	"要杀没有，这刀本宫赏给你了",
	"无杀，给你，哼"
}

sgs.ai_chat.collateralNoslash={
	"赏你了，还不快快跪谢！",
	"手残了，无法助你一臂之力",
	"孙子欸，敢收我的刀！",
	"我的趁手宝刀.....",
	"我帮不了你",
	"汝妹啊，吾刀！"
}

sgs.ai_chat.jijiang_female={
	"别指望下次我会帮你哦",
	"只是杀多了，消耗一点"
}

sgs.ai_chat.jijiang={
	"主公，我来啦",
	"我为主公出个力！"
}

sgs.ai_chat.eight_diagramIsGood={
	"哈哈，打不中",
	"八卦闪~！",
	"判红",
	"红色！！！"
}

sgs.ai_chat.judgeIsGood={
	"献祭GK木琴换来的",
	"这就是天意",
	"天助我，宵小不足为惧",
	"好判定",
	"判得好",
	"此天命不可违也，哈哈哈哈",
	"好耶!"
}

sgs.ai_chat.noJink={
	"有桃么!有桃么？",
	".......！",
	"我大意了",
	"要死",
	"没闪了",
	"完了",
	"挡不住了",
	"这下惨了"
}

sgs.ai_chat.noJink_female={
	"救命啊！",
	"妾身挡不住了",
	"完了完了",
	"没闪了呀",
	"不要啊"
}

--huanggai
sgs.ai_chat.kurou={
	"有桃么!有桃么？",
	"教练，我想要摸桃",
	"桃桃桃我的桃呢",
	"求桃求连弩各种求",
	"自己打自己",
	"苦肉计",
	"为了胜利，忍了",
	"痛并快乐着"
}

--indulgence
sgs.ai_chat.indulgence={
	"乐",
	"哈哈哈，乐",
	"五方诸神，此乐必中，急急如律令！",
	"你小子，就空过一回吧",
	"耶稣佛祖，不要天过",
	"此乐加之于你，定可一战而擒",
	"妖孽，看我封印你！",
	"关你禁闭！",
	"随机选择一位小盆友"
}

sgs.ai_chat.indulgence_female={
	"要懂得劳逸结合啊~~",
	"不要拒接妾身哦",
	"自娱自乐去吧",
	"休息一下吧"
}

sgs.ai_chat.indulgenceIsGood={
	"哈哈哈，乐不中",
	"信吾者，可上天国",
	"哟，天过",
	"我果然天眷者",
	"呀~~居然是假乐",
	"虚惊一场",
	"果然！",
	"此天助我也！"
}

--leiji
sgs.ai_chat.leiji_jink={
	"我有闪我会到处乱说么？",
	"你觉得我有木有闪啊",
	"哈我有闪"
}

--quhu
sgs.ai_chat.quhu={
	"出大的！",
	"来来来拼点了",
	"我要打虎了",
	"我又要打虎了",
	"谁会是狼呢？",
	"哟，拼点吧"
}

--wusheng to yizhong
sgs.ai_chat.wusheng_yizhong={
	"诶你技能是啥来着？",
	"在杀的颜色这个问题上咱是色盲",
	"咦你的技能呢？"
}

--salvageassault
sgs.ai_chat.daxiang={
	"好多大象！",
	"擦，孟获你的宠物又调皮了",
	"内牛满面啊敢不敢少来点AOE"
}

--xiahoudun
sgs.ai_chat.ganglie_death={
	"菊花残，满地伤。。。"
}

sgs.ai_chat.guojia_weak={
	"擦，再卖血会卖死的",
	"虚了，已经虚了",
	"不敢再卖了诶诶诶"
}

sgs.ai_chat.yuanshao_fire={
	"谁去打119啊",
	"别别别烧了别烧了。。。",
	"又烧啊，饶了我吧。。。",
	"救火啊，救一下啊"
}

--xuchu
sgs.ai_chat.luoyi={
	"不脱光衣服干不过你",
	"裸衣上阵！",
	"脱了！",
	"看我真正的实力",
	"认真模式"
}

sgs.ai_chat.bianshi = {
	"据我观察现在可以鞭尸",
	"鞭他，最后一下留给我",
	"我要刷战功，这个人头是我的",
	"这个可以鞭尸",
	"啊笑死"
}

sgs.ai_chat.bianshi_female = {
	"对面是个美女你们慢点",
	"人人有份，永不落空",
	"美人，来香一个"
}

sgs.ai_chat.usepeach = {
	"不好，这桃里有屎",
	"你往这里面掺了什么？"
}

-- 连续杀同一目标
sgs.ai_chat.continuous_slash = {
	"是兄弟就来砍我啊",
	"还来？没完了是吧",
	"我招你惹你了？",
	"针对我是吧？",
	"能不能换个人杀啊",
	"你是有多恨我啊",
	"有完没完啊？",
	"轮流来行不行",
	"你小子，别太过分"
}

sgs.ai_chat.continuous_slash_female = {
	"你就欺负我一个女孩子",
	"怎么老是打我",
	"男人都是大猪蹄子",
	"你好意思吗",
	"换个人打好不好",
	"过分了啊"
}

-- 成功闪避多次攻击
sgs.ai_chat.multi_jink = {
	"闪~闪~又闪~",
	"都打不中，菜",
	"你行不行啊",
	"手残了吧",
	"哈哈哈都闪掉了",
	"闪避大师就是我",
	"我看你是在给我挠痒痒"
}

-- 连续摸到好牌
sgs.ai_chat.good_cards = {
	"欧皇附体",
	"手气爆棚啊",
	"今天运气不错",
	"抽到了好东西",
	"牌运来了挡都挡不住",
	"哈哈哈，全是好牌",
	"手气爆炸",
	"全是好牌",
	"这波不亏",
	"抽到宝了",
	"欧气满满"
}

-- 连续摸到烂牌
sgs.ai_chat.bad_cards = {
	"这什么垃圾牌啊",
	"非酋之魂在燃烧",
	"能不能给点好牌",
	"我的桃呢？我的杀呢？",
	"牌堆是不是出问题了",
	"就这？就这？",
	"我不玩了，全是垃圾",
	"什么鬼牌",
	"全是垃圾",
	"非洲人落泪",
	"能不能重抽",
	"这牌没法玩"
}

-- 装备被拆
sgs.ai_chat.equip_removed = {
	"我的装备！",
	"还我宝贝",
	"你给我等着",
	"君子动口不动手啊",
	"我记住你了",
	"卑鄙！无耻！下流！"
}

sgs.ai_chat.equip_removed_female = {
	"你抢女孩子东西算什么本事",
	"还我！",
	"我的宝贝装备",
	"你好坏哦",
	"欺负人！"
}

-- 被多人集火
sgs.ai_chat.focused_fire = {
	"你们联合起来欺负我一个",
	"以多欺少算什么本事",
	"有种单挑啊",
	"我就这么招人恨吗",
	"能不能雨露均沾一下",
	"为什么受伤的总是我",
	"你们是商量好的吧"
}

-- 残血反杀
sgs.ai_chat.low_hp_kill = {
	"反杀！",
	"还有这种操作？",
	"哈哈，没想到吧",
	"绝地反击！",
	"我还没倒下！",
	"越残越强！",
	"别小看我",
	"最后的荣光"
}

sgs.ai_chat.low_hp_kill_female = {
	"本宫不是好欺负的",
	"看本姑娘的厉害",
	"谁说女子不如男",
	"反杀成功！",
	"哼，大意了吧"
}

-- 锦囊被无懈
sgs.ai_chat.trick_nullified = {
	"啊这...",
	"被无懈了",
	"怎么回事",
	"被克制了",
	"可恶",
	"失算了",
	"白出了"
}

sgs.ai_chat.trick_nullified_female = {
	"呜呜被无懈了",
	"白出了",
	"可恶",
	"哼"
}

-- 拿到神装
sgs.ai_chat.god_equip = {
	"神装到手",
	"装备齐全了",
	"这波装备可以",
	"满配了兄弟们",
	"全副武装",
	"来战！"
}

-- 空城状态
sgs.ai_chat.empty_city = {
	"空城了兄弟们",
	"一张牌都没有",
	"卡手了",
	"给我点牌吧",
	"我太难了",
	"空空如也"
}

-- 满手牌
sgs.ai_chat.full_hand = {
	"牌太多了",
	"手牌爆炸",
	"选择困难症犯了",
	"不知道出哪张",
	"资源丰富",
	"牌多任性"
}

-- 成为主公
sgs.ai_chat.become_lord = {
	"主公之位，舍我其谁",
	"众卿平身",
	"朕即国家",
	"效忠于我吧",
	"替朕守好江山"
}

-- 主公被围攻
sgs.ai_chat.lord_in_danger = {
	"主公危险！",
	"护驾！",
	"保护主公",
	"主公小心",
	"忠臣何在",
	"速速救驾"
}

-- 反贼暴露
sgs.ai_chat.rebel_exposed = {
	"反贼现身了",
	"抓住他！",
	"看我不打死你",
	"胆敢造反",
	"大胆逆贼",
	"拿下！"
}

-- 内奸身份可疑
sgs.ai_chat.renegade_suspicious = {
	"你是不是内奸",
	"表现得很可疑啊",
	"我怀疑你",
	"感觉你有问题",
	"你到底是哪边的",
	"别装了"
}

-- 队友给力
sgs.ai_chat.good_teammate = {
	"队友给力",
	"配合完美",
	"好兄弟",
	"就靠你了",
	"Nice",
	"干得漂亮"
}

sgs.ai_chat.good_teammate_female = {
	"姐妹给力",
	"好闺蜜",
	"Nice",
	"配合得好",
	"就知道你靠得住"
}

-- 队友坑爹
sgs.ai_chat.bad_teammate = {
	"队友在干嘛",
	"能不能靠谱点",
	"这是什么操作",
	"我™...",
	"你是对面派来的吧",
	"演员！"
}

-- 对手失误
sgs.ai_chat.enemy_mistake = {
	"对面送了",
	"失误了吧",
	"谢谢老板",
	"送的好",
	"这波不亏",
	"笑死",
	"23333",
	"哈哈哈哈哈",
	"笑死我了",
	"太菜了吧",
	"就这？",
	"不会吧不会吧",
	"送的好"
}

-- 自己失误
sgs.ai_chat.self_mistake = {
	"我大意了",
	"失误了",
	"手滑了",
	"不好意思",
	"算错了",
	"我的锅",
}

-- 游戏开始
sgs.ai_chat.game_start = {
	"开始了开始了",
	"让我看看什么身份",
	"这局好好打",
	"准备就绪",
	"来吧",
	"出发！"
}

-- 即将胜利
sgs.ai_chat.near_victory = {
	"稳了稳了",
	"这局拿下",
	"赢定了",
	"GG",
	"没悬念了",
	"收工"
}

-- 即将失败
sgs.ai_chat.near_defeat = {
	"要输了",
	"凉了",
	"没救了",
	"GG",
	"投降吧",
	"下把再来",
	"认输",
	"投了投了",
	"没得打",
	"下一局",
	"溜了溜了"
}

-- 平局预感
sgs.ai_chat.stalemate = {
	"这局焦灼啊",
	"谁输谁赢还不一定",
	"难分胜负",
	"势均力敌",
	"看到最后",
	"拉锯战"
}

-- 新增事件：连续被同一人杀
sgs.ai_event_callback[sgs.TargetConfirmed].continuous_slash = function(self, player, data)
	if not AIChat(player) then return end
	local use = data:toCardUse()
	if not use.card:isKindOf("Slash") then return end
	
	for _, to in sgs.qlist(use.to) do
		if to:getState() == "robot" and to:objectName() ~= use.from:objectName() then
			-- 检查是否被同一人连续杀
			if not to:getMark("last_slasher") then to:setMark("last_slasher", 0) end
			if to:getMark("last_slasher") == use.from:objectName():toInt() then
				to:addMark("continuous_slash_count")
				if to:getMark("continuous_slash_count") >= 2 and math.random() < 0.5 then
					local chat = sgs.ai_chat.continuous_slash
					if to:isFemale() then
						chat = sgs.ai_chat.continuous_slash_female
					end
					to:speak(chat[math.random(1, #chat)])
					to:setMark("continuous_slash_count", 0)
				end
			else
				to:setMark("last_slasher", use.from:objectName():toInt())
				to:setMark("continuous_slash_count", 1)
			end
		end
	end
end

-- 新增事件：装备被拆除
sgs.ai_event_callback[sgs.CardsMoveOneTime].equip_removed = function(self, player, data)
	if not AIChat() then return end
	local move = data:toMoveOneTime()
	if move.to_place ~= sgs.Player_DiscardPile and move.to_place ~= sgs.Player_PlaceHand then return end
	if not move.from or move.from:getState() ~= "robot" then return end
	
	for _, id in sgs.qlist(move.card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("EquipCard") and move.from_places:at(0) == sgs.Player_PlaceEquip then
			if math.random() < 0.3 then
				local chat = sgs.ai_chat.equip_removed
				if move.from:isFemale() then
					chat = sgs.ai_chat.equip_removed_female
				end
				move.from:speak(chat[math.random(1, #chat)])
			end
			break
		end
	end
end

-- 新增事件：残血反杀
sgs.ai_event_callback[sgs.Death].low_hp_kill = function(self, player, data)
	if not AIChat() then return end
	local death = data:toDeath()
	if not death.damage or not death.damage.from then return end
	
	local killer = death.damage.from
	if killer:getState() == "robot" and killer:getHp() <= 1 and math.random() < 0.4 then
		local chat = sgs.ai_chat.low_hp_kill
		if killer:isFemale() then
			chat = sgs.ai_chat.low_hp_kill_female
		end
		killer:speak(chat[math.random(1, #chat)])
	end
end

-- 新增事件：空城状态
sgs.ai_event_callback[sgs.EventPhaseStart].empty_city = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_Discard then return end
	if player:getState() ~= "robot" then return end
	
	if player:isKongcheng() and math.random() < 0.2 then
		player:speak(sgs.ai_chat.empty_city[math.random(1, #sgs.ai_chat.empty_city)])
	end
end

-- 新增事件：满手牌
sgs.ai_event_callback[sgs.DrawNCards].full_hand = function(self, player, data)
	if not AIChat(player) then return end
	if player:getState() ~= "robot" then return end
	
	-- 延迟检查，在摸牌后
	if player:getHandcardNum() >= player:getMaxCards() and math.random() < 0.15 then
		player:speak(sgs.ai_chat.full_hand[math.random(1, #sgs.ai_chat.full_hand)])
	end
end

-- 新增事件：被多人集火
sgs.ai_event_callback[sgs.Damaged].focused_fire = function(self, player, data)
	if not AIChat(player) then return end
	local damage = data:toDamage()
	if damage.to:getState() ~= "robot" then return end
	
	if damage.to:getMark("damage_point_round") >= 3 and math.random() < 0.4 then
		damage.to:speak(sgs.ai_chat.focused_fire[math.random(1, #sgs.ai_chat.focused_fire)])
	end
end

-- 新增事件：成功闪避多次
sgs.ai_event_callback[sgs.CardResponded].multi_jink = function(self, player, data)
	if not AIChat(player) then return end
	local response = data:toCardResponse()
	if not response.m_card or not response.m_card:isKindOf("Jink") then return end
	if player:getState() ~= "robot" then return end
	
	if not player:getMark("jink_count") then player:setMark("jink_count", 0) end
	player:addMark("jink_count")
	
	if player:getMark("jink_count") >= 2 and math.random() < 0.3 then
		player:speak(sgs.ai_chat.multi_jink[math.random(1, #sgs.ai_chat.multi_jink)])
		player:setMark("jink_count", 0)
	end
end

-- 新增事件：队友给力/坑爹
sgs.ai_event_callback[sgs.CardFinished].teammate_evaluation = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.card then return end
	
	-- 评估队友的行为
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getState() == "robot" and p:objectName() ~= player:objectName() then
			if self:isFriend(p, player) and math.random() < 0.1 then
				-- 判断是好行为还是坏行为
				if use.card:isKindOf("Peach") or use.card:isKindOf("Nullification") then
					local chat = sgs.ai_chat.good_teammate
					if p:isFemale() then
						chat = sgs.ai_chat.good_teammate_female
					end
					p:speak(chat[math.random(1, #chat)])
				end
			end
		end
	end
end

-- 新增事件：游戏开始时的问候
sgs.ai_event_callback[sgs.GameStart].greeting = function(self, player, data)
	if not AIChat() then return end
	
	-- 随机让一些AI在游戏开始时说话
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getState() == "robot" and math.random() < 0.2 then
			p:speak(sgs.ai_chat.game_start[math.random(1, #sgs.ai_chat.game_start)])
		end
	end
end

-- 新增事件：获得神装时
sgs.ai_event_callback[sgs.CardsMoveOneTime].god_equip = function(self, player, data)
	if not AIChat() then return end
	local move = data:toMoveOneTime()
	if not move.to or move.to:getState() ~= "robot" then return end
	if move.to_place ~= sgs.Player_PlaceEquip then return end
	
	-- 检查装备栏是否满了
	local equip_count = 0
	if move.to:getWeapon() then equip_count = equip_count + 1 end
	if move.to:getArmor() then equip_count = equip_count + 1 end
	if move.to:getDefensiveHorse() then equip_count = equip_count + 1 end
	if move.to:getOffensiveHorse() then equip_count = equip_count + 1 end
	
	if equip_count >= 3 and math.random() < 0.25 then
		move.to:speak(sgs.ai_chat.god_equip[math.random(1, #sgs.ai_chat.god_equip)])
	end
end

-- 新增事件：主公被围攻时忠臣呼喊
sgs.ai_event_callback[sgs.Damaged].lord_in_danger_call = function(self, player, data)
	if not AIChat() then return end
	local damage = data:toDamage()
	if not damage.to or not damage.to:isLord() then return end
	
	if damage.to:getHp() <= 2 and math.random() < 0.3 then
		for _, p in sgs.qlist(self.room:getOtherPlayers(damage.to)) do
			if p:getState() == "robot" and self:isFriend(p, damage.to) and math.random() < 0.5 then
				p:speak(sgs.ai_chat.lord_in_danger[math.random(1, #sgs.ai_chat.lord_in_danger)])
				break
			end
		end
	end
end

-- 特殊组合聊天
sgs.ai_chat.combo_attack = {
	"配合完美！",
	"Combo！",
	"连击！",
	"连续技发动",
	"无缝衔接",
	"行云流水"
}

sgs.ai_chat.steal_kill = {
	"抢人头！",
	"这人头是我的",
	"让我来收割",
	"KS大师",
	"我来终结他",
	"补刀成功"
}

sgs.ai_chat.steal_kill_female = {
	"让妾身来",
	"这个人头归我",
	"本宫来收尾",
	"补刀~"
}

-- 特殊局势聊天
sgs.ai_chat.comeback = {
	"绝地反击！",
	"翻盘了！",
	"柳暗花明",
	"起死回生",
	"奇迹发生了",
	"永不放弃",
	"这就是羁绊的力量"
}

sgs.ai_chat.dominating = {
	"势不可挡",
	"无人能敌",
	"碾压局",
	"大优势",
	"已经赢了",
	"可以打GG了"
}

sgs.ai_chat.clutch_save = {
	"关键救援！",
	"就差一点",
	"千钧一发",
	"及时雨啊",
	"救命之恩",
	"好险好险"
}

sgs.ai_chat.misplay = {
	"手抖了",
	"点错了",
	"失误失误",
	"这不是我想要的",
	"系统卡了",
	"我不是故意的"
}

sgs.ai_chat.troll = {
	"23333",
	"哈哈哈哈哈",
	"笑死我了",
	"太菜了吧",
	"就这？",
	"不会吧不会吧",
	"送的好"
}

sgs.ai_chat.troll_female = {
	"咯咯咯~",
	"好好笑哦",
	"人家笑死了",
	"太逗了",
	"不会吧~"
}

sgs.ai_chat.respect = {
	"佩服",
	"厉害",
	"高手",
	"服了",
	"强",
	"牛批"
}

sgs.ai_chat.nice = {
	"漂亮！",
	"Nice！",
	"干得好",
	"666",
	"秀啊",
	"太强了"
}

-- 针对特定卡牌的反应
sgs.ai_chat.see_duel = {
	"又是决斗",
	"来就来，谁怕谁",
	"手里一大把杀",
	"比杀是吧"
}

sgs.ai_chat.see_duel_female = {
	"决斗什么的最讨厌了",
	"欺负女孩子",
	"不要啦",
	"人家不想打架"
}

sgs.ai_chat.see_aoe = {
	"又是群攻",
	"躺枪",
	"能不能别搞AOE",
	"殃及池鱼"
}

sgs.ai_chat.see_lightning = {
	"闪电！",
	"快跑",
	"天打雷劈",
	"谁这么缺德",
	"雷来了"
}

sgs.ai_chat.avoid_lightning = {
	"躲过去了",
	"没劈到我",
	"虚惊一场",
	"好险",
	"天佑我也"
}


-- 回合开始/结束
sgs.ai_chat.turn_start = {
	"轮到我了",
	"我的回合",
	"看我表演",
	"该我了",
	"Draw！"
}

sgs.ai_chat.turn_start_female = {
	"轮到我啰",
	"我的回合呢",
	"看我表现吧",
	"该我上场了",
	"抽牌！"
}

sgs.ai_chat.turn_end = {
	"结束了",
	"过了",
	"下一位",
	"完事",
	"你的回合"
}

sgs.ai_chat.turn_end_female = {
	"我这边结束啰",
	"轮到你啦",
	"该你上场了",
	"我先收手啦",
	"就到这里，换你"
}

-- 针对闪电的事件回调
sgs.ai_event_callback[sgs.StartJudge].lightning_fear = function(self, player, data)
	if not AIChat(player) then return end
	local judge = data:toJudge()
	if judge.reason == "lightning" and math.random() < 0.5 then
		local chat = sgs.ai_chat.see_lightning
		if player:getState() == "robot" then
			player:speak(chat[math.random(1, #chat)])
		end
	end
end

-- 决斗时的反应
sgs.ai_event_callback[sgs.TargetConfirmed].duel_response = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.card:isKindOf("Duel") then return end
	
	for _, to in sgs.qlist(use.to) do
		if to:getState() == "robot" and math.random() < 0.4 then
			local chat = sgs.ai_chat.see_duel
			if to:isFemale() then
				chat = sgs.ai_chat.see_duel_female
			end
			to:speak(chat[math.random(1, #chat)])
		end
	end
end

-- AOE的额外反应
sgs.ai_event_callback[sgs.PreCardUsed].aoe_reaction = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("SavageAssault") then
		for _, p in sgs.qlist(self.room:getOtherPlayers(use.from)) do
			if p:getState() == "robot" and use.to:contains(p) and math.random() < 0.2 then
				p:speak(sgs.ai_chat.see_aoe[math.random(1, #sgs.ai_chat.see_aoe)])
				break
			end
		end
	end
end

-- 失误反应事件
sgs.ai_event_callback[sgs.CardFinished].mistake_reaction = function(self, player, data)
	if not AIChat() then return end
	
	-- 检查是否有失误发生
	if sgs.ai_mistake_log and #sgs.ai_mistake_log > 0 then
		local latest = sgs.ai_mistake_log[#sgs.ai_mistake_log]
		
		-- 如果是最近的失误且是当前玩家
		if latest.player == player:objectName() and os.time() - latest.timestamp < 5 then
			-- 其他玩家可能会嘲讽
			for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if p:getState() == "robot" and math.random() < 0.1 then
					if self:isEnemy(p, player) then
						p:speak(sgs.ai_chat.enemy_mistake[math.random(1, #sgs.ai_chat.enemy_mistake)])
					end
					break
				end
			end
		end
	end
end

-- 判定相关的额外聊天
sgs.ai_chat.supply_shortageIsBad = {
	"糟了，真的断粮了",
	"这下没得摸了",
	"完蛋，黑桃",
	"兵粮寸断",
	"我的摸牌啊"
}

sgs.ai_chat.indulgenceIsBad = {
	"真的乐了",
	"空过了",
	"这回合白给",
	"什么都干不了",
	"我太难了"
}

sgs.ai_chat.indulgenceIsBad_female = {
	"真的要休息了",
	"妾身动不了了",
	"乐不思蜀",
	"呜呜呜"
}

-- 装备特定聊天
sgs.ai_chat.crossbow = {
	"连弩到手",
	"可以开始突突了",
	"AK在手",
	"准备扫射"
}

sgs.ai_chat.kylin_bow = {
	"麒麟弓",
	"废马神器",
	"专业拆马",
	"马克星"
}

sgs.ai_chat.blade = {
	"青龙偃月刀",
	"神兵到手",
	"可以二连斩了"
}

sgs.ai_chat.spear = {
	"丈八蛇矛",
	"化牌为杀",
	"这下不缺杀了"
}

sgs.ai_chat.eight_diagram = {
	"八卦阵",
	"防御神器",
	"有八卦，不慌"
}

-- 濒死相关
sgs.ai_chat.dying = {
	"救命...",
	"快没了...",
	"谁来救我",
	"撑不住了",
	"要死了"
}

sgs.ai_chat.dying_female = {
	"救救妾身",
	"要不行了",
	"好难受",
	"快来救我"
}

sgs.ai_chat.recover = {
	"回血了",
	"好多了",
	"满状态",
	"又能战斗了",
	"活过来了"
}

sgs.ai_chat.recover_female = {
	"妾身恢复了",
	"好多了",
	"谢谢治疗",
	"血回来了"
}

-- 摸牌相关
sgs.ai_chat.draw_many = {
	"摸好多牌",
	"牌来了",
	"资源爆炸",
	"发财了",
	"手牌丰富"
}

-- 弃牌相关
sgs.ai_chat.discard_many = {
	"弃这么多",
	"手牌太多了",
	"弃弃弃",
	"牌多的烦恼",
	"选择困难"
}

-- 观星聊天
sgs.ai_chat.guanxing = {
	"观星象，知天命",
	"让我算算",
	"天机不可泄露",
	"卜算一番",
	"天象如此..."
}

-- 锦囊被无懈的回调
sgs.ai_event_callback[sgs.CardFinished].trick_nullified = function(self, player, data)
	if not AIChat(player) then return end
	local use = data:toCardUse()
	if not use.card:isKindOf("TrickCard") then return end
	if not use.card:isKindOf("DelayedTrick") and use.nullified_list and use.nullified_list:length() > 0 then
		if use.from and use.from:getState() == "robot" and math.random() < 0.3 then
			self:speak("trick_nullified", use.from:isFemale())
		end
	end
end

-- 摸到好牌/烂牌的回调
sgs.ai_event_callback[sgs.EventPhaseEnd].card_quality = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_Draw then return end
	if player:getState() ~= "robot" or math.random() > 0.15 then return end
	
	local good_cards = 0
	local total_cards = 0
	for _, card in sgs.qlist(player:getHandcards()) do
		total_cards = total_cards + 1
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") 
			or card:isKindOf("ExNihilo") or card:isKindOf("Nullification") then
			good_cards = good_cards + 1
		end
	end
	
	if total_cards >= 3 then
		if good_cards >= 2 then
			self:speak("good_cards", player:isFemale())
		elseif good_cards == 0 and total_cards >= 4 then
			self:speak("bad_cards", player:isFemale())
		end
	end
end

-- 使用装备时的聊天
sgs.ai_event_callback[sgs.CardUsed].equip_chat = function(self, player, data)
	if not AIChat(player) then return end
	local use = data:toCardUse()
	if player:getState() ~= "robot" or math.random() > 0.25 then return end
	
	if use.card:isKindOf("Crossbow") then
		self:speak("crossbow", player:isFemale())
	elseif use.card:isKindOf("Blade") then
		self:speak("blade", player:isFemale())
	elseif use.card:isKindOf("Spear") then
		self:speak("spear", player:isFemale())
	elseif use.card:isKindOf("EightDiagram") then
		self:speak("eight_diagram", player:isFemale())
	elseif use.card:isKindOf("KylinBow") then
		self:speak("kylin_bow", player:isFemale())
	end
end

-- 判定的聊天
sgs.ai_event_callback[sgs.FinishJudge].delayed_trick = function(self, player, data)
	if not AIChat(player) then return end
	local judge = data:toJudge()
	if player:getState() ~= "robot" or math.random() > 0.4 then return end
	
	-- 兵粮寸断判定
	if judge.reason == "supply_shortage" then
		if judge:isGood() and math.random() < 0.5 then
			self:speak("supply_shortageIsGood", player:isFemale())
		elseif judge:isBad() and math.random() < 0.4 then
			self:speak("supply_shortageIsBad", player:isFemale())
		end
	-- 乐不思蜀判定
	elseif judge.reason == "indulgence" then
		if judge:isGood() and math.random() < 0.5 then
			self:speak("indulgenceIsGood", player:isFemale())
		elseif judge:isBad() and math.random() < 0.4 then
			self:speak("indulgenceIsBad", player:isFemale())
		end
	-- 八卦阵判定
	elseif judge.reason == "eight_diagram" then
		if judge:isGood() and math.random() < 0.6 then
			self:speak("eight_diagramIsGood", player:isFemale())
		end
	end
end

-- 游戏局势判断
sgs.ai_event_callback[sgs.EventPhaseStart].game_situation = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_RoundStart then return end
	if player:getState() ~= "robot" or math.random() > 0.1 then return end
	
	-- 计算局势
	local friend_hp = 0
	local enemy_hp = 0
	local friend_count = 0
	local enemy_count = 0
	
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) then
			friend_hp = friend_hp + p:getHp()
			friend_count = friend_count + 1
		else
			enemy_hp = enemy_hp + p:getHp()
			enemy_count = enemy_count + 1
		end
	end
	
	local hp_ratio = 0
	if enemy_hp > 0 then
		hp_ratio = friend_hp / enemy_hp
	end
	
	-- 即将胜利
	if hp_ratio > 2 and friend_count >= enemy_count then
		self:speak("near_victory", player:isFemale())
	-- 即将失败
	elseif hp_ratio < 0.5 and friend_count <= enemy_count then
		self:speak("near_defeat", player:isFemale())
	-- 焦灼
	elseif math.abs(hp_ratio - 1) < 0.3 and sgs.turncount > 10 then
		self:speak("stalemate", player:isFemale())
	end
end

-- 主公身份相关
sgs.ai_event_callback[sgs.GameStart].lord_identity = function(self, player, data)
	if not AIChat(player) then return end
	if not player:isLord() then return end
	if player:getState() ~= "robot" or math.random() > 0.3 then return end
	
	self:speak("become_lord", player:isFemale())
end

-- 反贼/内奸暴露
sgs.ai_event_callback[sgs.CardUsed].identity_exposed = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	
	-- 当有人攻击主公时
	if use.card:isKindOf("Slash") or (use.card:isKindOf("Duel")) then
		for _, to in sgs.qlist(use.to) do
			if to:isLord() and use.from and use.from:getState() == "robot" then
				-- 其他忠臣可能会说反贼暴露（仅当确实有反贼且没有内奸或内奸数量少时）
				if sgs.playerRoles["rebel"] > 0 and sgs.playerRoles["renegade"] < 2 then
					for _, p in sgs.qlist(self.room:getOtherPlayers(use.from)) do
						if p:getState() == "robot" and self:isFriend(p, to) 
							and not self:isFriend(p, use.from) and math.random() < 0.15 then
							p:speak(sgs.ai_chat.rebel_exposed[math.random(1, #sgs.ai_chat.rebel_exposed)])
							break
						end
					end
				end
				break
			end
		end
	end
end

-- 队友表现判断
sgs.ai_event_callback[sgs.CardUsed].teammate_performance = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.from then return end
	
	-- 队友坑爹判断：比如队友用AOE伤害到自己
	if use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("SavageAssault") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p ~= use.from and p:getState() == "robot" 
				and self:isFriend(p, use.from) and math.random() < 0.1 then
				-- 检查自己是否会受到伤害
				local ai = p:getAI()
				if ai and ai:aoeIsEffective(use.card, p, use.from) and not ai:needToLoseHp(p, use.from, use.card, true) then
					p:speak(sgs.ai_chat.bad_teammate[math.random(1, #sgs.ai_chat.bad_teammate)])
					break
				end
			end
		end
	end
end

-- 观星技能触发
sgs.ai_event_callback[sgs.AskForGuanxing].guanxing_skill = function(self, player, data)
	if not AIChat(player) then return end
	if player:getState() ~= "robot" or math.random() > 0.2 then return end
	
	self:speak("guanxing", player:isFemale())
end

-- 内奸可疑判断
sgs.ai_event_callback[sgs.CardResponded].renegade_suspicious = function(self, player, data)
	if not AIChat() then return end
	local response = data:toCardResponse()
	
	-- 当有人濒死时，其他人没有出桃救人，可能会被怀疑是内奸
	if self.room:getCurrentDyingPlayer() then
		local dying = self.room:getCurrentDyingPlayer()
		if dying and dying:isLord() and not response.m_card then
			-- 如果主公濒死，有人不救，且确实存在内奸，可能被怀疑
			if sgs.playerRoles["renegade"] > 0 and player:getState() == "robot" and math.random() < 0.08 then
				-- 其他人可能会怀疑
				for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
					if p:getState() == "robot" and p ~= dying 
						and math.random() < 0.3 then
						p:speak(sgs.ai_chat.renegade_suspicious[math.random(1, #sgs.ai_chat.renegade_suspicious)])
						break
					end
				end
			end
		end
	end
end

-- 内奸可疑判断（基于出牌行为）
sgs.ai_event_callback[sgs.CardUsed].suspicious_behavior = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.from or use.from:getState() ~= "robot" then return end
	if math.random() > 0.05 then return end
	
	-- 在游戏中后期，如果有人行为暧昧（比如帮敌人）
	if sgs.turncount < 5 then return end
	
	-- 检测可疑行为：用有益锦囊帮助敌人，或用伤害锦囊伤害队友
	local lord = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isLord() then
			lord = p
			break
		end
	end
	
	if not lord then return end
	
	-- 如果用桃救了攻击过主公的人
	if use.card:isKindOf("Peach") then
		for _, to in sgs.qlist(use.to) do
			if to ~= use.from and to ~= lord then
				-- 检查这个人是否攻击过主公
				local ai = use.from:getAI()
				if ai and ai:isEnemy(to, lord) then
					-- 其他人可能会怀疑
					for _, p in sgs.qlist(self.room:getOtherPlayers(use.from)) do
						if p:getState() == "robot" and p:isLord() and math.random() < 0.2 then
							p:speak(sgs.ai_chat.renegade_suspicious[math.random(1, #sgs.ai_chat.renegade_suspicious)])
							break
						end
					end
				end
			end
		end
	end
	
	-- 如果用伤害性锦囊打了看起来像队友的人
	if use.card:isKindOf("Duel") or use.card:isKindOf("FireAttack") then
		for _, to in sgs.qlist(use.to) do
			if to:isLord() then
				-- 打主公但不是明确的反贼，且存在内奸，可疑
				if sgs.ai_role[use.from:objectName()] ~= "rebel" and sgs.playerRoles["renegade"] > 0 then
					for _, p in sgs.qlist(self.room:getOtherPlayers(use.from)) do
						if p:getState() == "robot" and not p:isLord() and math.random() < 0.15 then
							p:speak(sgs.ai_chat.renegade_suspicious[math.random(1, #sgs.ai_chat.renegade_suspicious)])
							break
						end
					end
				end
				break
			end
		end
	end
end

-- 回合结束触发
sgs.ai_event_callback[sgs.EventPhaseStart].turn_end = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_Finish then return end
	if player:getState() ~= "robot" or math.random() > 0.1 then return end
	
	self:speak("turn_end", player:isFemale())
end

-- 回合开始触发
sgs.ai_event_callback[sgs.EventPhaseStart].turn_start = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_Start then return end
	if player:getState() ~= "robot" or math.random() > 0.1 then return end
	
	self:speak("turn_start", player:isFemale())
end

-- 记录被伤害事件
sgs.ai_event_callback[sgs.Damaged].record_damage = function(self, player, data)
	if not player then return end
	local damage = data:toDamage()
	if damage.to then
		damage.to:addMark("ai_attacked-Clear")
	end
end

-- combo_attack: 配合攻击（两个队友连续攻击同一目标）
sgs.ai_event_callback[sgs.CardFinished].combo_attack = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.card or not use.card:isKindOf("Slash") then return end
	if not use.from or use.from:getState() ~= "robot" then return end
	if math.random() > 0.1 then return end
	
	-- 检查是否有队友刚刚攻击过同一目标
	if not sgs.last_slash_target or not sgs.last_slasher then return end
	
	for _, to in sgs.qlist(use.to) do
		if sgs.last_slash_target == to:objectName() and sgs.last_slasher ~= use.from:objectName() then
			local ai = use.from:getAI()
			if ai and ai:isFriend(self.room:findPlayerByObjectName(sgs.last_slasher)) then
				use.from:speak(sgs.ai_chat.combo_attack[math.random(1, #sgs.ai_chat.combo_attack)])
				break
			end
		end
	end
	
	-- 记录本次攻击信息
	sgs.last_slasher = use.from:objectName()
	if use.to:length() > 0 then
		sgs.last_slash_target = use.to:at(0):objectName()
	end
end

-- steal_kill: 抢人头（击杀濒死敌人）
sgs.ai_event_callback[sgs.Death].steal_kill = function(self, player, data)
	if not AIChat() then return end
	local death = data:toDeath()
	if not death.damage or not death.damage.from then return end
	
	local killer = death.damage.from
	if killer:getState() == "robot" and killer:objectName() ~= player:objectName() then
		-- 检查死者血量是否很低
		if math.random() < 0.25 then
			local chat = sgs.ai_chat.steal_kill
			if killer:isFemale() then
				chat = sgs.ai_chat.steal_kill_female or chat
			end
			killer:speak(chat[math.random(1, #chat)])
		end
	end
end

-- comeback: 翻盘（从劣势到优势）
sgs.ai_event_callback[sgs.EventPhaseStart].comeback = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_RoundStart then return end
	if player:getState() ~= "robot" or math.random() > 0.08 then return end
	if sgs.turncount < 8 then return end
	
	-- 计算血量对比
	local friend_hp = 0
	local enemy_hp = 0
	
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) then
			friend_hp = friend_hp + p:getHp()
		else
			enemy_hp = enemy_hp + p:getHp()
		end
	end
	
	local hp_ratio = 0
	if enemy_hp > 0 then
		hp_ratio = friend_hp / enemy_hp
	end
	
	-- 如果现在优势但记录的之前是劣势，说明翻盘了
	if hp_ratio > 1.5 then
		if not player:getMark("last_hp_ratio") or player:getMark("last_hp_ratio") < 1 then
			player:speak(sgs.ai_chat.comeback[math.random(1, #sgs.ai_chat.comeback)])
		end
		player:setMark("last_hp_ratio", math.floor(hp_ratio * 100))
	end
end

-- dominating: 压倒性优势
sgs.ai_event_callback[sgs.EventPhaseStart].dominating = function(self, player, data)
	if not AIChat(player) then return end
	if player:getPhase() ~= sgs.Player_RoundStart then return end
	if player:getState() ~= "robot" or math.random() > 0.08 then return end
	
	-- 计算血量对比
	local friend_hp = 0
	local enemy_hp = 0
	local friend_count = 0
	local enemy_count = 0
	
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) then
			friend_hp = friend_hp + p:getHp()
			friend_count = friend_count + 1
		else
			enemy_hp = enemy_hp + p:getHp()
			enemy_count = enemy_count + 1
		end
	end
	
	-- 如果明显优势（血量是敌人3倍以上，或人数更多血量还多）
	if friend_hp > 0 and enemy_hp > 0 and friend_hp / enemy_hp > 3 then
		player:speak(sgs.ai_chat.dominating[math.random(1, #sgs.ai_chat.dominating)])
	elseif friend_count > enemy_count and friend_hp > enemy_hp * 1.5 then
		player:speak(sgs.ai_chat.dominating[math.random(1, #sgs.ai_chat.dominating)])
	end
end

-- clutch_save: 关键救援（救濒死队友）
sgs.ai_event_callback[sgs.CardFinished].clutch_save = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.card or not use.from then return end
	
	-- 用桃或其他救命牌救队友
	if use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic") then
		for _, to in sgs.qlist(use.to) do
			if to:getState() == "robot" and use.from:getState() == "robot" then
				-- 检查是否救的是濒死队友
				local ai = use.from:getAI()
				if ai and ai:isFriend(to) and to:getMark("Global_Dying") > 0 then
					if math.random() < 0.3 then
						use.from:speak(sgs.ai_chat.clutch_save[math.random(1, #sgs.ai_chat.clutch_save)])
					end
					break
				end
			end
		end
	end
	
	-- 用无懈救队友
	if use.card:isKindOf("Nullification") then
		local ai = use.from:getAI()
		if ai and use.from:getState() == "robot" then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:getMark("Global_Dying") > 0 and ai:isFriend(p) and math.random() < 0.25 then
					use.from:speak(sgs.ai_chat.clutch_save[math.random(1, #sgs.ai_chat.clutch_save)])
					break
				end
			end
		end
	end
end

-- respect: 敬佩（对方出了很漂亮的操作）
sgs.ai_event_callback[sgs.CardFinished].respect = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.card or not use.from then return end
	if math.random() > 0.05 then return end
	
	-- 敌人用了很聪明的操作
	for _, p in sgs.qlist(self.room:getOtherPlayers(use.from)) do
		if p:getState() == "robot" and use.from:getState() == "robot" then
			local ai = p:getAI()
			if ai and ai:isEnemy(p, use.from) then
				-- 敌人用了关键的无懈
				if use.card:isKindOf("Nullification") then
					p:speak(sgs.ai_chat.respect[math.random(1, #sgs.ai_chat.respect)])
					break
				end
				-- 敌人在被多次伤害后还能出闪防守（防守时他造成的伤害次数多）
				if use.card:isKindOf("Jink") and use.from:getMark("damage_point_round") > 2 then
					p:speak(sgs.ai_chat.respect[math.random(1, #sgs.ai_chat.respect)])
					break
				end
			end
		end
	end
end

-- nice: 漂亮（赞美队友或自己的优秀操作）
sgs.ai_event_callback[sgs.CardFinished].nice = function(self, player, data)
	if not AIChat() then return end
	local use = data:toCardUse()
	if not use.card or not use.from then return end
	if math.random() > 0.06 then return end
	
	-- 队友或自己出了好牌
	if use.from:getState() == "robot" then
		-- 自己出了关键牌
		if use.card:isKindOf("Slash") and use.to:length() > 1 then
			-- 一次击中多个敌人的杀
			use.from:speak(sgs.ai_chat.nice[math.random(1, #sgs.ai_chat.nice)])
		elseif use.card:isKindOf("ExNihilo") or use.card:isKindOf("AmazingGrace") then
			-- 出了好的过牌术
			use.from:speak(sgs.ai_chat.nice[math.random(1, #sgs.ai_chat.nice)])
		end
	end
	
	-- 队友出了好牌，我们赞美
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p ~= use.from and p:getState() == "robot" and use.from:getState() == "robot" then
			local ai = p:getAI()
			if ai and ai:isFriend(p, use.from) then
				-- 队友用无懈救了我们
				if use.card:isKindOf("Nullification") and math.random() < 0.3 then
					p:speak(sgs.ai_chat.nice[math.random(1, #sgs.ai_chat.nice)])
					break
				end
				-- 队友出了好的控制或伤害
				if (use.card:isKindOf("Duel") or use.card:isKindOf("Slash")) and use.to:length() >= 1 then
					if math.random() < 0.1 then
						p:speak(sgs.ai_chat.nice[math.random(1, #sgs.ai_chat.nice)])
						break
					end
				end
			end
		end
	end
end

