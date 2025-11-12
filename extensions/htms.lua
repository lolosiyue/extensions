module("extensions.htms", package.seeall)
extension = sgs.Package("htms")
--配置

--势力
do
	require "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms, "htms_feng")
	table.insert(kingdoms, "htms_huo")
	table.insert(kingdoms, "htms_lin")
	table.insert(kingdoms, "htms_shan")
	table.insert(kingdoms, "htms_wu")
	config.kingdom_colors["htms_feng"] = "#91edf9" --
	config.kingdom_colors["htms_huo"] = "#FF6347" --西红柿（为什么叫西红柿
	config.kingdom_colors["htms_lin"] = "#32CD32" --橙绿（鬼知道是什么颜色
	config.kingdom_colors["htms_shan"] = "#bc4904"
	config.kingdom_colors["htms_wu"] = "#ffffff"
	--[[jian_colors= {
        htms_feng = "#00ff8a",
        htms_huo = "#ff2403",
        htms_lin = "#00ff00",
        htms_shan = "#bc4904",
        htms_wu = "#fefefe",
    }
    local colors=config.kingdom_colors
    --config.kingdom_colors = "#A500CC"
    --local colors=config.kingdom_colors
    --table.insert(colors,htms_feng="#00ff8a")]]
end

hidden_player          = sgs.General(extension, "hidden_player", "htms_wu", 0, false, true, true)
chitong                = sgs.General(extension, "chitong", "htms_huo", 4, false)
haigls                 = sgs.General(extension, "haigls$", "htms_shan", 4, true)
chanlz                 = sgs.General(extension, "chanlz", "htms_huo", 4, false)
aer                    = sgs.General(extension, "aer", "htms_feng", 4, false)
Kirito                 = sgs.General(extension, "Kirito", "htms_shan", 3, true)
TachibanaKanade        = sgs.General(extension, "TachibanaKanade", "htms_feng", "4", false)
Yoshino                = sgs.General(extension, "Yoshino", "htms_lin", "4", false)
chuyin                 = sgs.General(extension, "chuyin", "htms_lin", "3", false)
ydssx                  = sgs.General(extension, "ydssx", "htms_huo", "4", false)
jiahe                  = sgs.General(extension, "jiahe", "htms_feng", 4, false)
paoj                   = sgs.General(extension, "paoj", "htms_huo", 3, false)
xili_gai               = sgs.General(extension, "xili_gai", "htms_huo", 4, false)
chuannei               = sgs.General(extension, "chuannei", "htms_huo", 4, false)
heixueji               = sgs.General(extension, "heixueji", "htms_feng", 3, false)
bended                 = sgs.General(extension, "bended", "htms_feng", 3, false)
lumuyuanxiang          = sgs.General(extension, "lumuyuanxiang", "htms_lin", 3, false)
guimgm                 = sgs.General(extension, "guimgm", "htms_lin", 3)
youxmj                 = sgs.General(extension, "youxmj", "htms_lin", 3, false)
chuixue                = sgs.General(extension, "chuixue", "htms_huo", 4, false)
sakurakyouko           = sgs.General(extension, "sakurakyouko", "htms_huo", 5, false)
xiana                  = sgs.General(extension, "xiana", "htms_huo", 5, false)
aierkuite              = sgs.General(extension, "aierkuite", "htms_lin", 4, false)
qizui                  = sgs.General(extension, "qizui", "htms_wu", 3, false)
qiulaihuo              = sgs.General(extension, "qiulaihuo", "htms_lin", 3, true)
chicheng               = sgs.General(extension, "chicheng$", "htms_shan", 3, false)
niepdl                 = sgs.General(extension, "niepdl", "htms_huo", 4, false)
xiaomeiyan             = sgs.General(extension, "xiaomeiyan", "htms_feng", 3, false)
Theresa                = sgs.General(extension, "Theresa", "htms_shan", 5, false)
nihuisly               = sgs.General(extension, "nihuisly", "htms_shan", 4)
xuefeng                = sgs.General(extension, "xuefeng", "htms_shan", 3, false)
dangma                 = sgs.General(extension, "dangma", "htms_shan", 5, true)
yasina                 = sgs.General(extension, "yasina", "htms_feng", 3, false)
yikls                  = sgs.General(extension, "yikls", "htms_wu", 3, false, true, true)
lulux                  = sgs.General(extension, "lulux", "htms_feng", 4, true)
jieyi                  = sgs.General(extension, "jieyi", "htms_lin", 3, false)
youer                  = sgs.General(extension, "youer$", "htms_huo", 4, true)
jejms                  = sgs.General(extension, "jejms", "htms_feng", 3, true)
nlls                   = sgs.General(extension, "nlls", "htms_shan", 4, true)
youj                   = sgs.General(extension, "youj", "htms_feng", 4, false)
kklt                   = sgs.General(extension, "kklt", "htms_huo", 3, true)
--swk = sgs.General(extension,"swk","htms_shan",3,true)
jianqm                 = sgs.General(extension, "jianqm", "htms_lin", 3, false)
liangys                = sgs.General(extension, "liangys", "htms_huo", 4, false)
feicunjianxin          = sgs.General(extension, "feicunjianxin", "htms_huo", "3", true)
bfsm                   = sgs.General(extension, "bfsm", "htms_feng", 4, true)
yuru                   = sgs.General(extension, "yuru", "htms_feng", 3, false, true)
yanhe                  = sgs.General(extension, "yanhe", "htms_lin", 3, false)
mssyx                  = sgs.General(extension, "mssyx", "htms_huo", 3, false)
woqiyounai             = sgs.General(extension, "woqiyounai", "htms_feng", 4, false)
gushoulihua            = sgs.General(extension, "gushoulihua", "htms_feng", 3, false)
ougenqinwang           = sgs.General(extension, "ougenqinwang", "htms_lin", 3, false)
gaowen                 = sgs.General(extension, "gaowen", "htms_lin", 2, false, true, true)
fuxiao                 = sgs.General(extension, "fuxiao", "htms_lin", 2, false, true, true)
gemingji               = sgs.General(extension, "gemingji", "htms_lin", 2, false, true, true)
siluokayi              = sgs.General(extension, "siluokayi", "htms_huo", 2, false)
shigure                = sgs.General(extension, "shigure", "htms_shan", 3, false)
BlackRockShooter       = sgs.General(extension, "BlackRockShooter", "htms_feng", 4, false)
insaneBlackRockShooter = sgs.General(extension, "insaneBlackRockShooter", "htms_feng", 4, false, true, true)
qiandaitian            = sgs.General(extension, "qiandaitian$", "htms_feng", 4, false)
htms_wuzang            = sgs.General(extension, "htms_wuzang", "htms_shan", 4, false)
ts_yoshiko             = sgs.General(extension, "ts_yoshiko", "htms_feng", 3, false) --津島善子
gasaiyuno              = sgs.General(extension, "gasaiyuno", "htms_feng", 4, false, true, true)
you                    = sgs.General(extension, "wn_you", "htms_feng", 3, false)
ruby                   = sgs.General(extension, "kz_ruby", "htms_feng", 3, false)    --黒澤ルビィ
tk_rikka               = sgs.General(extension, "tk_rikka", "htms_feng", 3, false)   --小鸟游六花
kataokayuuki           = sgs.General(extension, "kataokayuuki", "htms_huo", 4, false)
riko                   = sgs.General(extension, "sakurauchiriko", "htms_feng", 3, false) --桜内梨子
oh_mari                = sgs.General(extension, "oharamari", "htms_feng", 3, false)  --小原鞠莉
kanan                  = sgs.General(extension, "matsuurakanan", "htms_feng", 3, false) --松浦果南
Akame                  = sgs.General(extension, "Akame", "htms_feng", "3", false)    --剑术赤瞳
beikasi                = sgs.General(extension, "beikasi", "htms_huo", 2, false)     --贝卡斯
washake                = sgs.General(extension, "washake", "htms_huo", 2, true, true) --瓦沙克
heluo                  = sgs.General(extension, "heluo$", "htms_shan", 4, false)     --赫萝
amaekoromo             = sgs.General(extension, "amaekoromo", "htms_feng", 3, false) --天江衣
homura                 = sgs.General(extension, "htms_homura", "htms_feng", "3", false) --晓美焰（弓）
gokoururi              = sgs.General(extension, "gokoururi", "htms_lin", 3, false)   --五更琉璃
yuno                   = sgs.General(extension, "yuno", "htms_lin", 3, false)        --由乃
yuno_cm                = sgs.General(extension, "yuno_cm", "htms_lin", 3, false)     --由乃.圣诞ver
yuno_jy                = sgs.General(extension, "yuno_jy", "htms_lin", 3, false)     --由乃.经验ver
shinai                 = sgs.General(extension, "shinai", "htms_huo", 3, false)      --诗乃
penguin                = sgs.General(extension, "penguin", "htms_shan", 3, false)    --黑泽黛雅
Noire                  = sgs.General(extension, "Noire", "htms_huo", 3, false)       --诺瓦露
jsyasina               = sgs.General(extension, "jsyasina", "htms_lin", 3, false)    --剑速亚丝娜
jide                   = sgs.General(extension, "jide", "htms_feng", 4, true)        --基德
yanmoai                = sgs.General(extension, "yanmoai", "htms_lin", 3, false)     --阎魔爱
huawan                 = sgs.General(extension, "huawan", "htms_feng", 3, false)     --国木田花丸
jiqiangms              = sgs.General(extension, "jiqiangms", "htms_huo", 4, false)   --黑岩机枪模式
chenmosheshou          = sgs.General(extension, "chenmosheshou", "htms_feng", 4, false) --沉默射手
nike                   = sgs.General(extension, "nike", "htms_feng", 3, false)       --妮可
Reki                   = sgs.General(extension, "Reki", "htms_feng", 3, false)       --雷姬
bamameicd              = sgs.General(extension, "bamameicd", "htms_feng", 4, false)  --巴麻美
axu                    = sgs.General(extension, "axu", "htms_feng", 4, true)         --阿虚
haose                  = sgs.General(extension, "haose", "htms_lin", 4, true)        --豪瑟
xieshenyuan            = sgs.General(extension, "xieshenyuan", "htms_lin", 3, false) --邪神圆
toziko                 = sgs.General(extension, "toziko", "htms_huo", 3, false)      --苏我屠自古
sp_reimu               = sgs.General(extension, "sp_reimu", "htms_huo", 3, false)    --灵梦
tokiko                 = sgs.General(extension, "tokiko", "htms_feng", 3, false)     --朱鹭子
poige                  = sgs.General(extension, "poige", "htms_huo", 3, false)       --夕立改二
Togashi                = sgs.General(extension, "Togashi", "htms_shan", 4, true)     --勇太
fdzhende               = sgs.General(extension, "fdzhende", "htms_shan", 4, false)   --绯弹贞德
jinmuyan               = sgs.General(extension, "jinmuyan", "htms_shan", 7, true)    --金木研
b3lita                 = sgs.General(extension, "b3lita", "htms_huo", 2, false)      --丽塔
jika                   = sgs.General(extension, "jika", "htms_lin", 3, false)        --千歌
zlmaki                 = sgs.General(extension, "zlmaki", "htms_lin", 3, false)      --治疗真姬
lsmaki                 = sgs.General(extension, "lsmaki", "htms_feng", 3, false)     --傲娇真姬
qjmaki                 = sgs.General(extension, "qjmaki", "htms_feng", 3, false)     --千金真姬
wypenguin              = sgs.General(extension, "wypenguin", "htms_shan", 3, false)  --威仪黛雅
--seija = sgs.General(extension, "seija", "htms_feng", 3, false)--鬼人正邪
sekibanki              = sgs.General(extension, "sekibanki", "htms_huo", 4, false)   --赤蛮奇
fengjianyouxiang       = sgs.General(extension, "fengjianyouxiang", "htms_feng", 4, false) --风见幽香
xuenai                 = sgs.General(extension, "xuenai", "htms_feng", 3, false)     --雪之下雪乃
subaru                 = sgs.General(extension, "subaru", "htms_lin", 3, true)       --菜月昴
heic8                  = sgs.General(extension, "heic8", "htms_huo", 4, false)       --黑C
youji                  = sgs.General(extension, "youji", "htms_huo", 4, false)       --优纪
Sdorica_Angelia        = sgs.General(extension, "Sdorica_Angelia", "htms_lin", 3, false) --安洁莉亚
oumashu                = sgs.General(extension, "oumashu", "htms_lin", 3, true)      --樱满集
banya                  = sgs.General(extension, "banya", "htms_feng", 3, false)      --板鸭
banyali                = sgs.General(extension, "banyali", "htms_feng", 3, false, true, true)
Megumin                = sgs.General(extension, "Megumin", "htms_huo", 3, false)     --慧慧
Orga                   = sgs.General(extension, "Orga", "htms_feng", 4, true)        --奥尔加
ktln                   = sgs.General(extension, "ktln", "htms_lin", 3, false)        --卡塔琳娜
ayumu                  = sgs.General(extension, "ayumu", "htms_lin", 3, false)       --上原步梦
minoriko               = sgs.General(extension, "minoriko", "htms_lin", 3, false)    --秋穰子
LLENN                  = sgs.General(extension, "LLENN", "htms_huo", 3, false)       --莲
v2                     = sgs.General(extension, "v2", "htms_lin", 3, false)          --格尼薇儿
dns                    = sgs.General(extension, "dns", "htms_huo", 3, false)         --迪妮莎
bumeng                 = sgs.General(extension, "bumeng", "htms_feng", 4, false, true, true) --步梦
zeroll                 = sgs.General(extension, "zeroll", "htms_feng", 3, true)      --zero鲁路修
akuya                  = sgs.General(extension, "akuya", "htms_lin", 4, false)       --阿库娅
jgzb                   = sgs.General(extension, "jgzb", "htms_lin", 3, false)        --姬宫真步
wude                   = sgs.General(extension, "wude", "htms_huo", 4, true)         --伍德
shengmm                = sgs.General(extension, "shengmm", "htms_huo", 4, false)     --圣麻美
hezhen                 = sgs.General(extension, "hezhen", "htms_feng", 4, true)      --佐藤和真
sjtongren              = sgs.General(extension, "sjtongren", "htms_huo", 3, true)    --圣剑桐人
xsll                   = sgs.General(extension, "xsll", "htms_feng", 3, true)        --LL
jcy                    = sgs.General(extension, "jcy", "htms_feng", 3, true)         --橘纯一
rkk                    = sgs.General(extension, "rkk", "htms_lin", 3, false)         --婉弦梨子
whql                   = sgs.General(extension, "whql", "htms_shan", 5, false)       --五河琴里
kailiu                 = sgs.General(extension, "kailiu", "htms_feng", 3, false)     --凯留
htms_bifang            = sgs.General(extension, "htms_bifang", "htms_lin", 3, false) --睡眠彼方
dkns                   = sgs.General(extension, "dkns", "htms_shan", 4, false)       --达克尼斯
bjhz                   = sgs.General(extension, "bjhz", "htms_feng", 3, false)       --白井黑子
luozi                  = sgs.General(extension, "luozi", "htms_feng", 3, true)       --阿姆罗·雷


sgs.LoadTranslationTable {
	--扩展包名
	["htms"]                            = "幻天漫杀",
	--势力
	["htms_feng"]                       = "風",
	["htms_lin"]                        = "林",
	["htms_huo"]                        = "火",
	["htms_shan"]                       = "山",
	["htms_wu"]                         = "无",
	--武将名
	["qizui"]                           = "七罪",
	["chitong"]                         = "赤瞳",
	["haigls"]                          = "海格力斯",
	["chanlz"]                          = "缠流子",
	["aer"]                             = "阿尔托利亚",
	["Kirito"]                          = "桐人",
	["TachibanaKanade"]                 = "立华奏",
	["Yoshino"]                         = "四糸乃",
	["chuyin"]                          = "初音未来",
	["ydssx"]                           = "夜刀神十香",
	["jiahe"]                           = "加贺",
	["paoj"]                            = "御坂美琴",
	["xili_gai"]                        = "夕立改",
	["chuannei"]                        = "川内",
	["heixueji"]                        = "黑雪姬",
	["bended"]                          = "本多二代",
	["lumuyuanxiang"]                   = "鹿目圆香",
	["guimgm"]                          = "桂木桂马",
	["youxmj"]                          = "诱宵美九",
	["chuixue"]                         = "吹雪",
	["sakurakyouko"]                    = "佐仓杏子",
	["xiana"]                           = "夏娜",
	["aierkuite"]                       = "爱尔奎特",
	["qiulaihuo"]                       = "秋濑或",
	["chicheng"]                        = "赤城",
	["niepdl"]                          = "聂普迪努",
	["xiaomeiyan"]                      = "晓美焰",
	["Theresa"]                         = "SP·德丽莎",
	["nihuisly"]                        = "逆回十六夜",
	["xuefeng"]                         = "雪风",
	["dangma"]                          = "上条当麻",
	["yasina"]                          = "亚丝娜",
	["yikls"]                           = "伊卡洛斯",
	["lulux"]                           = "鲁鲁修",
	["jieyi"]                           = "结衣",
	["youer"]                           = "坂井悠二",
	["jejms"]                           = "吉尔伽美什",
	["nlls"]                            = "奴良陆生",
	["youj"]                            = "优纪",
	["kklt"]                            = "卡卡罗特",
	["swk"]                             = "悟空",
	["jianqm"]                          = "间崎鸣",
	["liangys"]                         = "两仪式",
	["bfsm"]                            = "波风水门",
	["feicunjianxin"]                   = "绯村剑心",
	["yuru"]                            = "羽入",
	["yanhe"]                           = "言和",
	["mssyx"]                           = "美树沙耶香",
	["woqiyounai"]                      = "我妻由乃",
	["gushoulihua"]                     = "古手梨花",
	["ougenqinwang"]                    = "欧根亲王",
	["gaowen"]                          = "高文机甲",
	["gemingji"]                        = "革命机",
	["fuxiao"]                          = "拂晓",
	["siluokayi"]                       = "斯洛卡伊",
	["shigure"]                         = "时雨",
	["BlackRockShooter"]                = "黑岩射手",
	["insaneBlackRockShooter"]          = "黑岩射手",
	["qiandaitian"]                     = "千代田",
	["htms_wuzang"]                     = "武藏",
	["ts_yoshiko"]                      = "津岛善子",
	["gasaiyuno"]                       = "我妻由乃",
	["wn_you"]                          = "渡辺曜",
	["kz_ruby"]                         = "黒澤露比",
	["tk_rikka"]                        = "小鸟游六花",
	["kataokayuuki"]                    = "片岡優希",
	["sakurauchiriko"]                  = "樱内梨子",
	["oharamari"]                       = "小原鞠莉",
	["matsuurakanan"]                   = "松浦果南",
	["Akame"]                           = "剑术赤瞳",
	["beikasi"]                         = "贝卡斯",
	["washake"]                         = "瓦沙克",
	["heluo"]                           = "赫萝",
	["amaekoromo"]                      = "天江衣",
	["htms_homura"]                     = "晓美焰（弓）",
	["gokoururi"]                       = "五更琉璃",
	["yuno"]                            = "由乃",
	["yuno_cm"]                         = "由乃.圣诞",
	["yuno_jy"]                         = "由乃.经验",
	["shinai"]                          = "朝田诗乃",
	["penguin"]                         = "黑泽黛雅",
	["Noire"]                           = "诺瓦露",
	["jsyasina"]                        = "剑速亚丝娜",
	["jide"]                            = "基德",
	["yanmoai"]                         = "阎魔爱",
	["huawan"]                          = "国木田花丸",
	["jiqiangms"]                       = "黑岩机枪模式",
	["chenmosheshou"]                   = "沉默射手",
	["nike"]                            = "矢泽日香",
	["Reki"]                            = "雷姬",
	["bamameicd"]                       = "巴麻美",
	["axu"]                             = "阿虚",
	["haose"]                           = "豪瑟",
	["xieshenyuan"]                     = "邪神圆",
	["toziko"]                          = "苏我屠自古",
	["tokiko"]                          = "朱鹭子",
	["sp_reimu"]                        = "博丽灵梦",
	["poige"]                           = "夕立改二",
	["Togashi"]                         = "富樫勇太",
	["fdzhende"]                        = "贞德",
	["jinmuyan"]                        = "金木研",
	["b3lita"]                          = "丽塔",
	["jika"]                            = "高海千歌",
	["zlmaki"]                          = "魔术真姬",
	["lsmaki"]                          = "傲娇真姬",
	["qjmaki"]                          = "千金真姬",
	["wypenguin"]                       = "威仪黛雅",
	--["seija"] = "鬼人正邪",
	["sekibanki"]                       = "赤蛮奇",
	["fengjianyouxiang"]                = "风见幽香",
	["xuenai"]                          = "雪之下雪乃",
	["subaru"]                          = "菜月昴",
	["heic8"]                           = "反转阿尔托利亚",
	["youji"]                           = "连击优纪",
	["Sdorica_Angelia"]                 = "安洁莉亚",
	["oumashu"]                         = "樱满集",
	["banya"]                           = "理之律者",
	["banyali"]                         = "理之律者",
	["Megumin"]                         = "慧慧",
	["Orga"]                            = "奥尔加",
	["ktln"]                            = "卡塔琳娜",
	["ayumu"]                           = "上原步梦",
	["minoriko"]                        = "秋穰子",
	["LLENN"]                           = "莲",
	["v2"]                              = "格尼薇儿",
	["dns"]                             = "迪妮莎",
	["bumeng"]                          = "上原步梦",
	["zeroll"]                          = "ZERO",
	["akuya"]                           = "阿库娅",
	["jgzb"]                            = "姬宫真步",
	["wude"]                            = "伍德",
	["shengmm"]                         = "圣麻美",
	["hezhen"]                          = "佐藤和真",
	["sjtongren"]                       = "圣剑桐人",
	["xsll"]                            = "L.L",
	["jcy"]                             = "橘纯一",
	["rkk"]                             = "婉弦梨子",
	["whql"]                            = "五河琴里",
	["kailiu"]                          = "凯留",
	["htms_bifang"]                     = "睡眠彼方",
	["dkns"]                            = "达克尼斯",
	["bjhz"]                            = "白井黑子",
	["luozi"]                           = "阿姆罗·雷 ",
	--游戏内显示的武将名
	["&qizui"]                          = "七罪",
	["&chitong"]                        = "赤瞳",
	["&haigls"]                         = "海格力斯",
	["&chanlz"]                         = "缠流子",
	["&aer"]                            = "阿尔托利亚",
	["&Kirito"]                         = "桐人",
	["&TachibanaKanade"]                = "立华奏",
	["&Yoshino"]                        = "四糸乃",
	["&chuyin"]                         = "初音未来",
	["&ydssx"]                          = "夜刀神十香",
	["&jiahe"]                          = "加贺",
	["&paoj"]                           = "御坂美琴",
	["&xili_gai"]                       = "夕立改",
	["&chuannei"]                       = "川内",
	["&heixueji"]                       = "黑雪姬",
	["&bended"]                         = "本多二代",
	["&lumuyuanxiang"]                  = "鹿目圆香",
	["&guimgm"]                         = "桂木桂马",
	["&youxmj"]                         = "诱宵美九",
	["&chuixue"]                        = "吹雪",
	["&sakurakyouko"]                   = "佐仓杏子",
	["&xiana"]                          = "夏娜",
	["&aierkuite"]                      = "爱尔奎特",
	["&qiulaihuo"]                      = "秋濑或",
	["&chicheng"]                       = "赤城",
	["&niepdl"]                         = "聂普迪努",
	["&xiaomeiyan"]                     = "晓美焰",
	["&Theresa"]                        = "德丽莎",
	["&nihuisly"]                       = "逆回十六夜",
	["&xuefeng"]                        = "雪风",
	["&dangma"]                         = "上条当麻",
	["&yasina"]                         = "亚丝娜",
	["&yikls"]                          = "伊卡洛斯",
	["&lulux"]                          = "鲁鲁修",
	["&jieyi"]                          = "结衣",
	["&youer"]                          = "坂井悠二",
	["&jejms"]                          = "吉尔伽美什",
	["&nlls"]                           = "奴良陆生",
	["&youj"]                           = "优纪",
	["&kklt"]                           = "卡卡罗特",
	["&swk"]                            = "悟空",
	["&jianqm"]                         = "间崎鸣",
	["&liangys"]                        = "两仪式",
	["&bfsm"]                           = "波风水门",
	["&feicunjianxin"]                  = "绯村剑心",
	["&yuru"]                           = "羽入",
	["&yanhe"]                          = "言和",
	["&mssyx"]                          = "美树沙耶香",
	["&woqiyounai"]                     = "我妻由乃",
	["&gushoulihua"]                    = "古手梨花",
	["&ougenqinwang"]                   = "欧根亲王",
	["&gaowen"]                         = "高文机甲",
	["&gemingji"]                       = "革命机",
	["&fuxiao"]                         = "拂晓",
	["&siluokayi"]                      = "斯洛卡伊",
	["&BlackRockShooter"]               = "黑岩射手",
	["&insaneBlackRockShooter"]         = "黑岩射手",
	["&qiandaitian"]                    = "千代田",
	["&qiansui"]                        = "千岁",
	["&htms_wuzang"]                    = "武藏",
	["&ts_yoshiko"]                     = "津岛善子",
	["&wn_you"]                         = "渡辺曜",
	["&gasaiyuno"]                      = "我妻由乃",
	["&kz_ruby"]                        = "黒澤露比",
	["&tk_rikka"]                       = "小鸟游六花",
	["&kataokayuuki"]                   = "片冈优希",
	["&sakurauchiriko"]                 = "樱内梨子",
	["&oharamari"]                      = "小原鞠莉",
	["&matsuurakanan"]                  = "松浦果南",
	["&Akame"]                          = "剑术赤瞳",
	["&beikasi"]                        = "贝卡斯",
	["&washake"]                        = "瓦沙克",
	["&heluo"]                          = "赫萝",
	["&amaekoromo"]                     = "天江衣",
	["&htms_homura"]                    = "晓美焰（弓）",
	["&gokoururi"]                      = "五更琉璃",
	["&yuno"]                           = "由乃",
	["&yuno_cm"]                        = "由乃.圣诞",
	["&yuno_jy"]                        = "由乃.经验",
	["&shinai"]                         = "朝田诗乃",
	["&penguin"]                        = "黑泽黛雅",
	["&Noire"]                          = "诺瓦露",
	["&jsyasina"]                       = "剑速亚丝娜",
	["&jide"]                           = "基德",
	["&yanmoai"]                        = "阎魔爱",
	["&huawan"]                         = "国木田花丸",
	["&jiqiangms"]                      = "黑岩机枪模式",
	["&chenmosheshou"]                  = "沉默射手",
	["&nike"]                           = "矢泽日香",
	["&Reki"]                           = "雷姬",
	["&bamameicd"]                      = "巴麻美",
	["&axu"]                            = "阿虚",
	["&haose"]                          = "豪瑟",
	["&xieshenyuan"]                    = "邪神圆",
	["&toziko"]                         = "苏我屠自古",
	["&tokiko"]                         = "朱鹭子",
	["&sp_reimu"]                       = "博丽灵梦",
	["&poige"]                          = "夕立改二",
	["&Togashi"]                        = "富樫勇太",
	["&fdzhende"]                       = "贞德",
	["&jinmuyan"]                       = "金木研",
	["&b3lita"]                         = "丽塔",
	["&jika"]                           = "高海千歌",
	["&zlmaki"]                         = "魔术真姬",
	["&lsmaki"]                         = "傲娇真姬",
	["&qjmaki"]                         = "千金真姬",
	["&wypenguin"]                      = "威仪黛雅",
	--["&seija"] = "鬼人正邪",
	["&sekibanki"]                      = "赤蛮奇",
	["&fengjianyouxiang"]               = "风见幽香",
	["&xuenai"]                         = "雪之下雪乃",
	["&subaru"]                         = "菜月昴",
	["&heic8"]                          = "反转阿尔托利亚",
	["&youji"]                          = "连击优纪",
	["&Sdorica_Angelia"]                = "安洁莉亚",
	["&oumashu"]                        = "樱满集",
	["&banya"]                          = "理之律者",
	["&banyali"]                        = "理之律者",
	["&Megumin"]                        = "慧慧",
	["&Orga"]                           = "奥尔加",
	["&ktln"]                           = "卡塔琳娜",
	["&ayumu"]                          = "上原步梦",
	["&minoriko"]                       = "秋穰子",
	["&LLENN"]                          = "莲",
	["&v2"]                             = "格尼薇儿",
	["&dns"]                            = "迪妮莎",
	["&bumeng"]                         = "上原步梦",
	["&zeroll"]                         = "ZERO",
	["&akuya"]                          = "阿库娅",
	["&jgzb"]                           = "姬宫真步",
	["&wude"]                           = "伍德",
	["&shengmm"]                        = "圣麻美",
	["&hezhen"]                         = "佐藤和真",
	["&sjtongren"]                      = "圣剑桐人",
	["&xsll"]                           = "L.L",
	["&jcy"]                            = "橘纯一",
	["&rkk"]                            = "婉弦梨子",
	["&whql"]                           = "五河琴里",
	["&kailiu"]                         = "凯留",
	["&htms_bifang"]                    = "睡眠彼方",
	["&dkns"]                           = "达克尼斯",
	["&bjhz"]                           = "白井黑子",
	["&luozi"]                          = "阿姆罗·雷 ",
	--武将称号
	["#chitong"]                        = "",
	["#haigls"]                         = "",
	["#chanlz"]                         = "",
	["#aer"]                            = "",
	["#Kirito"]                         = "",
	["#TachibanaKanade"]                = "",
	["#Yoshino"]                        = "",
	["#chuyin"]                         = "",
	["#ydssx"]                          = "",
	["#jiahe"]                          = "",
	["#paoj"]                           = "",
	["#xili_gai"]                       = "",
	["#chuannei"]                       = "",
	["#heixueji"]                       = "",
	["#bended"]                         = "",
	["#guimgm"]                         = "",
	["#youxmj"]                         = "",
	["#chuixue"]                        = "",
	["#sakurakyouko"]                   = "",
	["#xiana"]                          = "",
	["#aierkuite"]                      = "",
	["#qiulaihuo"]                      = "",
	["#chicheng"]                       = "",
	["#niepdl"]                         = "",
	["#xiaomeiyan"]                     = "",
	["#Theresa"]                        = "",
	["#nihuisly"]                       = "",
	["#xuefeng"]                        = "",
	["#dangma"]                         = "",
	["#yasina"]                         = "",
	["#yikls"]                          = "",
	["#lulux"]                          = "",
	["#jieyi"]                          = "",
	["#youer"]                          = "",
	["#jejms"]                          = "",
	["#nlls"]                           = "",
	["#youj"]                           = "",
	["#kklt"]                           = "",
	["#jianqm"]                         = "",
	["#liangys"]                        = "",
	["#bfsm"]                           = "",
	["#feicunjianxin"]                  = "",
	["#yuru"]                           = "",
	["#yanhe"]                          = "",
	["#mssyx"]                          = "",
	["#woqiyounai"]                     = "",
	["#gushoulihua"]                    = "",
	["#ougenqinwang"]                   = "",
	["#BlackRockShooter"]               = "冰色冷焰",
	["#qiandaitian"]                    = "五段进化",
	["#htms_wuzang"]                    = "武藏御殿",
	["#ts_yoshiko"]                     = "浮暗沈皑",
	["#wn_you"]                         = "星辰永伴",
	["#kz_ruby"]                        = "瑰石藏亮",
	["#sakurauchiriko"]                 = "京花乡降",
	["#oharamari"]                      = "千金回首",
	["#matsuurakanan"]                  = "万里铭心",
	["#Akame"]                          = "役小角",
	["#heluo"]                          = "贤狼",
	["#amaekoromo"]                     = "",
	["#penguin"]                        = "凌零舞夜",
	["#huawan"]                         = "朝文暮讴",
	["#toziko"]                         = "神明后裔的亡灵",
	["#sp_reimu"]                       = "乐园的巫女",
	["#tokiko"]                         = "读书的妖怪",
	--["#seija"] = "逆转的天邪鬼",
	["#sekibanki"]                      = "柳树下的杜拉罕",
	["cv:xuenai"]                       = "早见沙织",
	["#xuenai"]                         = "冰之女王",
	["#subaru"]                         = "无尽回档的英雄",
	["#Sdorica_Angelia"]                = "复国之公主",
	["#oumashu"]                        = "温柔的王",
	["#minoriko"]                       = "丰收之神",
	--设计者
	["designer:chitong"]                = "黑雪姬",
	["designer:haigls"]                 = "黑白丶",
	["designer:chanlz"]                 = "龙魂",
	["designer:aer"]                    = "修",
	["designer:Kirito"]                 = "桐人",
	["designer:TachibanaKanade"]        = "文文姬",
	["designer:Yoshino"]                = "龙魂",
	["designer:chuyin"]                 = "肯我赛",
	["designer:ydssx"]                  = "龙魂",
	["designer:jiahe"]                  = "肯我赛",
	["designer:paoj"]                   = "黑雪姬",
	["designer:xili_gai"]               = "肯我赛",
	["designer:chuannei"]               = "谷子",
	["designer:heixueji"]               = "黑雪姬",
	["designer:bended"]                 = "肯我赛",
	["designer:lumuyuanxiang"]          = "龙魂",
	["designer:guimgm"]                 = "肯我赛",
	["designer:youxmj"]                 = "龙魂",
	["designer:chuixue"]                = "肯我赛",
	["designer:sakurakyouko"]           = "龙魂",
	["designer:xiana"]                  = "龙魂",
	["designer:aierkuite"]              = "肯我赛",
	["designer:qizui"]                  = "ZY(youko1316)",
	["designer:tk_rikka"]               = "ZY(youko1316),初夏",
	["designer:qiulaihuo"]              = "肯我赛",
	["designer:chicheng"]               = "谷子",
	["designer:niepdl"]                 = "肯我赛",
	["designer:xiaomeiyan"]             = "龙魂",
	["designer:Theresa"]                = "雪儿萧萧",
	["designer:nihuisly"]               = "肯我赛",
	["designer:xuefeng"]                = "肯我赛",
	["designer:dangma"]                 = "152",
	["designer:yasina"]                 = "黑化赛高",
	["designer:lulux"]                  = "霉冥自",
	["designer:jieyi"]                  = "黑雪姬",
	["designer:youer"]                  = "灵云涛",
	["designer:jejms"]                  = "黑化赛高",
	["designer:nlls"]                   = "黑化赛高",
	["designer:youj"]                   = "初夏",
	["designer:kklt"]                   = "初夏",
	["designer:swk"]                    = "初夏",
	["designer:jianqm"]                 = "沐川",
	["designer:liangys"]                = "龙魂",
	["designer:feicunjianxin"]          = "黑雪姬，肯我赛，152",
	["designer:bfsm"]                   = "FK丶xke",
	["designer:yanhe"]                  = "灵云涛",
	["designer:mssyx"]                  = "FK丶xke",
	["designer:woqiyounai"]             = "黑化赛高",
	["designer:gushoulihua"]            = "tassel",
	["designer:ougenqinwang"]           = "龙魂",
	["designer:siluokayi"]              = "龙魂",
	["designer:BlackRockShooter"]       = "雪儿萧萧",
	["designer:insaneBlackRockShooter"] = "黑岩射手",
	["designer:shigure"]                = "肯我赛",
	["designer:ts_yoshiko"]             = "醉花梦月",
	["designer:wn_you"]                 = "醉花梦月",
	["designer:kz_ruby"]                = "醉花梦月",
	["designer:sakurauchiriko"]         = "醉花梦月",
	["designer:oharamari"]              = "醉花梦月",
	["designer:matsuurakanan"]          = "醉花梦月",
	["designer:kataokayuuki"]           = "冰糖",
	["designer:Akame"]                  = "雪儿萧萧",
	["designer:beikasi"]                = "龙魂",
	["designer:washake"]                = "龙魂",
	["designer:amaekoromo"]             = "tassel",
	["designer:htms_homura"]            = "肯我赛",
	["designer:gokoururi"]              = "Paysage",
	["designer:yuno"]                   = "tassel",
	["designer:yuno_cm"]                = "醉花梦月",
	["designer:yuno_jy"]                = "肯我赛",
	["designer:shinai"]                 = "龙魂",
	["designer:penguin"]                = "醉花梦月",
	["designer:Noire"]                  = "文文姬",
	["designer:jsyasina"]               = "wch5621628",
	["designer:jide"]                   = "此生唯爱紫色木棉",
	["designer:yanmoai"]                = "此生唯爱紫色木棉",
	["designer:huawan"]                 = "醉花梦月",
	["designer:jiqiangms"]              = "幸福近琳",
	["designer:chenmosheshou"]          = "变革者ZERO",
	["designer:nike"]                   = "bd波导",
	["designer:Reki"]                   = "奇洛",
	["designer:bamameicd"]              = "守一",
	["designer:heluo"]                  = "赫萝",
	["designer:axu"]                    = "信",
	["designer:haose"]                  = "時語無月",
	["designer:xieshenyuan"]            = "守一",
	["designer:toziko"]                 = "Paysage",
	["designer:tokiko"]                 = "Paysage",
	["designer:sp_reimu"]               = "Paysage",
	["designer:poige"]                  = "完美同调士",
	["designer:Togashi"]                = "プラチナ酱",
	["designer:fdzhende"]               = "奇洛",
	["designer:jinmuyan"]               = "黑血",
	["designer:b3lita"]                 = "兔er",
	["designer:jika"]                   = "樱内瑞业",
	["designer:zlmaki"]                 = "樱内瑞业",
	["designer:lsmaki"]                 = "bd波导",
	["designer:qjmaki"]                 = "醉花梦月",
	["designer:wypenguin"]              = "YO酱最好看不接受反驳",
	--["designer:seija"] = "Paysage",
	["designer:sekibanki"]              = "Paysage",
	["designer:fengjianyouxiang"]       = "肯我赛",
	["designer:xuenai"]                 = "信",
	["designer:subaru"]                 = "光临长夜",
	["designer:heic8"]                  = "奇洛",
	["designer:youji"]                  = "此生唯爱紫色木棉",
	["designer:Sdorica_Angelia"]        = "板蓝根",
	["designer:oumashu"]                = "光临长夜",
	["designer:banya"]                  = "兔er",
	["designer:Megumin"]                = "戴耳机的妖精",
	["designer:Orga"]                   = "戴耳机的妖精",
	["designer:ktln"]                   = "信",
	["designer:ayumu"]                  = "樱内瑞业",
	["designer:minoriko"]               = "Paysage",
	["designer:LLENN"]                  = "bd波导",
	["designer:v2"]                     = "龙魂",
	["designer:dns"]                    = "龙魂",
	["designer:bumeng"]                 = "醉花梦月",
	["designer:zeroll"]                 = "月半",
	["designer:akuya"]                  = "戴耳机的妖精",
	["designer:jgzb"]                   = "戴耳机的妖精",
	["designer:wude"]                   = "龙魂",
	["designer:shengmm"]                = "守一",
	["designer:hezhen"]                 = "戴耳机的妖精",
	["designer:sjtongren"]              = "戴耳机的妖精",
	["designer:xsll"]                   = "GONG",
	["designer:jcy"]                    = "樱内瑞业",
	["designer:rkk"]                    = "樱内瑞业",
	["designer:whql"]                   = "ZY(youko1316)",
	["designer:kailiu"]                 = "戴耳机的妖精",
	["designer:htms_bifang"]            = "樱内瑞业",
	["designer:dkns"]                   = "戴耳机的妖精",
	["designer:bjhz"]                   = "戴耳机的妖精",
	["designer:luozi"]                  = "月半",
	--配音
	["$chitong"]                        = "作战完成，返回基地",
	["$zhuisha1"]                       = "目标",
	["$zhuisha2"]                       = "不是目标",
	["$ansha"]                          = "葬送",
	["$htms_zangsong"]                  = "葬送",
	["~chanlz"]                         = "可恶！居然输了，加油了啊！",
	["$xianxsy1"]                       = "那你有什么事！",
	["$xianxsy2"]                       = "你挺有种的啊！！",
	["$xianxsy3"]                       = "这么想知道初恋啊！",
	["$fengwang1"]                      = "让我们开始吧，御主。",
	["$fengwang2"]                      = "风啊，飞舞吧！",
	["$wangzhe"]                        = " 集结的星之吐息，闪耀的生命奔流 接下吧，Excalibur！",
	["$newfengwang1"]                   = "让我们开始吧，御主。",
	["$newfengwang2"]                   = "风啊，飞舞吧！",
	["$doubleslash1"]                   = "这招怎么样",
	["$doubleslash2"]                   = "二刀流",
	["$betacheater1"]                   = "你也落单了吗",
	["$betacheater2"]                   = "这种程度还不够",
	["$betacheater3"]                   = "啊有点危险",
	["$betacheater4"]                   = "很强啊",
	["$betacheater5"]                   = "可恶",
	["$betacheater6"]                   = "疼",
	["$defencefield1"]                  = "不要像我一样弱小",
	["$defencefield2"]                  = "我相信你所说的话",
	["$defencefield3"]                  = "四糸乃我是心中理想的自己",
	["$frozenpuppet"]                   = "你也是来欺负四糸乃吗",
	["$howling1"]                       = "GUARD SKILL HOWLING",
	["$howling2"]                       = "有你在的话，也许能做到。",
	["$chuszy1"]                        = "天空光芒",
	["$chuszy2"]                        = "这声音是为你而奏！",
	["~jiahe"]                          = "赤城，只要你没事就好。我先走一步了，等着你哦。",
	["$Luajianzai1"]                    = "一航战，出击。",
	["$Luajianzai2"]                    = "甲板着火了。……怎么这样。",
	["$mie1"]                           = "让你们见识一下我的力量",
	["$mie2"]                           = "你真的不会否定我了吗？",
	["$Luazuihou"]                      = "Sandalphon！",
	["$diancp1"]                        = "做好觉悟了的吧！",
	["$diancp2"]                        = "不攻过来的我就打过来了",
	["$diancp3"]                        = "现在的我是很强的",
	["$diancp4"]                        = "嘿呀！",
	["~chuannei"]                       = "還想……打更多的夜戰啊……",
	["$Luayezhan1"]                     = "什麼？夜戰？",
	["$Luayezhan2"]                     = "嘛～不要那麼焦躁嘛，…夜晚可是很長的喲。",
	["$Luayezhan3"]                     = "太好了！我期待已久了的夜戰～！",
	["$Luaemeng1"]                      = "那么，让我们举办一场华丽的派对吧！",
	["$Luaemeng2"]                      = "随便找一个打了poi",
	["$Luaemeng3"]                      = "所罗门的噩梦，让你们见识一下",
	["$jiasugaobai1"]                   = "跟我比起来，你还更像是个超频连线者呢",
	["$jiasugaobai2"]                   = "我的决定果然没错 我由衷地认为 能遇见你真是太好了",
	["$jiasuduijue1"]                   = "别碰我！",
	["$jiasuduijue2"]                   = "你不攻过来的话，那我就先攻了！",
	["$juedoujiasu"]                    = "星光流连击",
	["$qingtq1"]                        = "敌将已经被我打败了！",
	["$qingtq2"]                        = "妨碍的人是谁？",
	["$xiangy1"]                        = "绝不会有那种事情",
	["$xiangy2"]                        = "既然阁下已经选择了要走那条路，那么就由身为极东武士的我来迎击！",
	["~lumuyuanxiang"]                  = "对不起了，是我太过勉强自己了。",
	["$jiujideqiyuan1"]                 = "成功了！",
	["$jiujideqiyuan2"]                 = "还早呢，我不能输啊！",
	["$fazededizao1"]                   = "稍微变得有趣了呢。再稍微努力一下！",
	["$fazededizao2"]                   = "轮到我出场了呢。好，加油！",
	["$fazededizao3"]                   = "还早呢，一起走吧！",
	["$fazededizao4"]                   = "虽然有点累，但我必须要更努力才行！",
	["$gonglzs"]                        = "我已经看到结局了！",
	["$shens1"]                         = "我就是游戏中的神！",
	["$shens2"]                         = "现实游戏",
	["$pojgj1"]                         = "我中意上你了！",
	["$pojgj2"]                         = "我已经拜托过了~",
	["~chuixue"]                        = "对不起，司令官，晚安",
	["$LuamuguanVS"]                    = "攻击开始！上吧！",
	["#LuamuguanBuff"]                  = "就由我来解决吧！",
	["$duanzui"]                        = "无路赛无路赛无路赛！",
	["$zhenhong"]                       = "烦死人了！",
	["$meihuomoyan1"]                   = "一起吧！",
	["$meihuomoyan2"]                   = "真是有趣啊",
	["$guancha1"]                       = "从你们进公园之后我就一直跟着了，这样下去的话你们就必死无疑了",
	["$guancha2"]                       = "你在发抖呢！真是可怜",
	["$jiyi1"]                          = "那么，太阳下山了，我们就死定了",
	["$jiyi2"]                          = "不用担心，我是或，秋濑或，是你的朋友",
	["$Luachicheng"]                    = "烈风？不，不知道的孩子呢。",
	["~chicheng"]                       = "对不起…雷击处分…请实行吧…",
	["$zhujuexz"]                       = "挺不错的",
	["$lunhui1"]                        = "别乱动",
	["$lunhui"]                         = "这..",
	["$pocdsf"]                         = "这样一击就能解决",
	["$lolita"]                         = "你在看哪里啊！你这个死萝！莉！控！",
	["$judas"]                          = "德丽莎今天又是大胜利！",
	["$yuandian1"]                      = "最强的主办者吗 那可真是太好了",
	["$yuandian2"]                      = "啊~因为和小鬼大人约好了啊~",
	["$moxing1"]                        = "OK,你看好咯",
	["$moxing2"]                        = "GAME 开始了！",
	["$xiangrui1"]                      = "舰队就由我来保护",
	["$xiangrui2"]                      = "绝对！没问题！",
	["~xuefeng"]                        = "不沉的话，或许是不可能的吧",
	["$Luachuyi1"]                      = "请一顿饭",
	["$Luachuyi2"]                      = "这样我们就扯平了！怎么样",
	["$Lualianji"]                      = "我是为了找回自我！",
	["$wnlz1"]                          = "我是为了救你而站在这里",
	["$wnlz2"]                          = "你们把她的心当成什么了？",
	["$hxss1"]                          = "告诉我",
	["$hxss2"]                          = "现在我就来救你",
	["$hxss3"]                          = "如果你还是不知道的话，我就告诉你一件事！",
	["$geass1"]                         = "世界啊！臣服于我吧！",
	["$geass2"]                         = "错的不是我，是世界！",
	["$znai"]                           = "好像能用辅助摇杆，举起左手，做出握拳的手势",
	["$changedfate"]                    = "结衣一点也不害怕",
	["$wangzbk1"]                       = "普天之下，莫非王土",
	["$wangzbk2"]                       = "好像还是不够啊",
	["$wangzbk3"]                       = "你为何不明白自己毫无胜算？",
	["$wangzbk4"]                       = "提升一下精度吧",
	["$bings1"]                         = "哼，真是嚣张啊，杂修",
	["$bings2"]                         = "放弃吧！",
	["$bings3"]                         = "呼哈哈哈哈！",
	["$bings4"]                         = "呼呼哈哈哈哈哈哈哈哈！",
	["$guailj"]                         = "你的脑袋，一片肉也别想留下。",
	["$ye"]                             = "二话不说把串击落不就好了 所以 我才想以愚直应愚直 而且 碍事的家伙 必须杀了之后再继续前进",
	["$zhou"]                           = "大家 都被重创了吗",
	["$guichan"]                        = "是爷爷的旧相识吗？",
	["$feils"]                          = "招式名为：飞雷神·时空疾风闪光连段",
	["$jssg"]                           = "身为父亲，总会想走在儿子面前，成为他努力的目标。",
	["$feils2"]                         = "招式名为：飞雷神·时空疾风闪光连段，零！",
	["$zsmy1"]                          = "只要是活着的东西 就算是神也杀给你看！",
	["$zsmy2"]                          = "",
	["$qsas1"]                          = "我所体验的感情，只有杀人而已",
	["$qsas2"]                          = "能为我去死吗？",
	--	["$tjdzf"] = "还早呢！",
	["$tjdzf1"]                         = "还早呢！",
	["$tjdzf2"]                         = "私は無敵だ！",
	["$qrdag1"]                         = "大家一起抵抗下来吧！",
	["$qrdag2"]                         = "想接下我这击可是白费力气",
	["$fenmao"]                         = "来吧！厮杀开始了",
	["$heihua"]                         = "哈哈哈哈哈",
	["$businiao1"]                      = "哇，被打中了！但是，还没结束…",
	["$businiao2"]                      = "祝好运。",
	["$zhanxianfanyu1"]                 = "欧根亲王号、移至追击战！",
	["$zhanxianfanyu2"]                 = "重巡洋舰欧根亲王，出击！",
	["$zhanxianfanyu3"]                 = "重巡洋舰欧根亲王，出击！",
	["$zhanxianfanyu4"]                 = "祝您今天愉快！",
	["$slash_defence1"]                 = "开火！开火！ ",
	["$slash_defence2"]                 = "炮击，开始！开火！",
	["~ougenqinwang"]                   = "我…这次要先沉了，…酒匂…长门…再…见…",
	["$jixieshen1"]                     = "咆哮",
	["$jixieshen1"]                     = "有趣就让我尝尝你的秘密是什么味的",
	["$DSTP"]                           = "不要啊，不是会痛的嘛？",
	["$loyal_inu"]                      = "雨总是会有停的时候",
	["$kikann1"]                        = "可惜了",
	["$kikann2"]                        = "这里绝不退让",
	["$mozy"]                           = "能看见哦，死的颜色",
	["$zuihoudefanji1"]                 = "已经太慢了！已经够了！大家死吧！",
	["$zuihoudefanji2"]                 = "为了牢记，为了下次遇到你时，回想起你是我的敌人",
	["$guangzijupao1"]                  = "目标获得",
	["$guangzijupao2"]                  = "攻击开始",
	["$baozou"]                         = "我是黑岩射手",
	["$kuanghua"]                       = "即使如此我也要战斗",
	["$lanyuhua1"]                      = "发现敌人",
	["$lanyuhua2"]                      = "战斗开始",
	["$jueduiyazhi1"]                   = "这还没结束",
	["$jueduiyazhi2"]                   = "这样的话，再见",
	["~BlackRockShooter"]               = "再一次，一起去学校...",
	["$nidaoren"]                       = "剑是凶器，剑技是杀人的伎俩，无论怎样的美丽的掩饰，终究是事实",
	["$badaozhai"]                      = "绯村剑心，如今就是我存在的意义",
	["$soulfire1"]                      = "结束了哟",
	["$soulfire2"]                      = "少说废话，直接上去打",
	["$jfxl1"]                          = "这家伙由我来对付，神啊，拜托了，请保护我最重要的人吧！",
	["$samsara1"]                       = "又是一个死胡同的世界",
	["$samsara2"]                       = "如果我不走上舞台的话，就不会有奇迹发生",
	["~gushoulihua"]                    = "まだ死ぬ...",
	["~jejms"]                          = "Archer...",
	["~chitong"]                        = "作戦終了、帰還する",
	["~haigls"]                         = "",
	["~aer"]                            = "すまない……マスター……",
	["~Kirito"]                         = "抱歉...我也挂了",
	["~TachibanaKanade"]                = "",
	["~Yoshino"]                        = "ごめんなさい、驚かせて...",
	["~chuyin"]                         = "",
	["~ydssx"]                          = "ここまで...が",
	["~paoj"]                           = "はぁ...なって素直になれないだろう...",
	["~xili_gai"]                       = "もしかして、沈んちゃおうpoi",
	["~heixueji"]                       = "まだ、戦い、わたしはこんなところで止まているわけにはいかない",
	["~bended"]                         = "",
	["~guimgm"]                         = "",
	["~youxmj"]                         = "うるさい...",
	["~sakurakyouko"]                   = "すまんね、後は頼んだぜ...",
	["~xiana"]                          = "",
	["~aierkuite"]                      = "",
	["~qiulaihuo"]                      = "到底是谁...",
	["~niepdl"]                         = "",
	["~xiaomeiyan"]                     = "まどか...まどか...",
	["~Theresa"]                        = "",
	["~nihuisly"]                       = "没什么担心的了",
	["~dangma"]                         = "我的手...",
	["~yasina"]                         = "",
	["~lulux"]                          = "さよなら、ユーフェ。たぶん初恋たんだ",
	["~jieyi"]                          = "わかない、何もわかない...",
	["~youer"]                          = "",
	["~nlls"]                           = "",
	["~kklt"]                           = "",
	["~jianqm"]                         = "",
	["~liangys"]                        = "",
	["~feicunjianxin"]                  = "ありがとう、すまんない、さよなら",
	["~bfsm"]                           = "",
	["~yanhe"]                          = "",
	["~mssyx"]                          = "えへへ、ここでおしまいが...",
	["~woqiyounai"]                     = "",
	["~siluokayi"]                      = "可恶，到此为止了吗",
	["~shigure"]                        = "",
	["~BlackRockShooter"]               = "",
	["~qiansui"]                        = "",
	["~htms_wuzang"]                    = "",
	["~ts_yoshiko"]                     = "下界には、ヨハネの歌が届かないのかしら？",
	["$xinsuo1"]                        = "堕落到地狱深处吧！",
	["$xinsuo2"]                        = "要和我一起堕天吗",
	["$yohane1"]                        = "若无视了我的话，那就被灼热的火焰烧掉吧！",
	["$yohane2"]                        = "找夜羽有什么事情吗？",
	["$fengfu1"]                        = "在那里！",
	["$fengfu2"]                        = "别叫善子！",
	["$fanyi1"]                         = "准备",
	["$fanyi2"]                         = "难得的休息日，我们一起出去玩吧！",
	["$jihang1"]                        = "今后也会更加快乐",
	["$jihang2"]                        = "今后也请指教呢~",
	["~wn_you"]                         = "ううっ……私としたことが、船酔いしちゃったかも……",
	["$jinhua1"]                        = "稍微有点接近千岁姐了吧？",
	["$jinhua2"]                        = "嗯，这样就能赢了！说不定能胜过千岁姐！",
	["$wuduan1"]                        = "差不多是最后一击了吧！",
	["$wuduan2"]                        = "舰载机的训练也足够了。出击",
	["$tisheng"]                        = "接下来！舰爆队，舰攻队，出场！",
	["$jiaoxing1"]                      = "姐姐一直对我很严格的",
	["$jiaoxing2"]                      = "在这种地方是不可以的！",
	["$anni"]                           = "如果可以的话，能和我说吗？",
	["$ann2"]                           = "难道..",
	["~xiana"]                          = "",
	["$tprs"]                           = "难道..",
	["$sandun1"]                        = "别走！",
	["$sandun2"]                        = "我必须找到不可视境界线，绝对！",
	["$xieyan1"]                        = "汇聚至此的漆黑之力，遵吾之名，赐其祝福",
	["$xieyan2"]                        = "绝对效力的魔法碎片，是刚才缔结的新的契约证明",
	["$handsonic1"]                     = "音速手刃",
	["~sakurauchiriko"]                 = "我不会放弃的",
	["$haiyin1"]                        = "多亏帮忙，我也做到了",
	["$haiyin2"]                        = "偶尔也过来把",
	["$fuzou1"]                         = "注意周围",
	["$fuzou2"]                         = "有个请求？但是抄作业可不行哦",
	["$htms_wanlan1"]                   = "我好像蛮喜欢你的",
	["$htms_wanlan2"]                   = "success！做得很好",
	["$tianqu1"]                        = "感觉不错呢",
	["$tianqu2"]                        = "我会帮助你？感觉应该是相反的立场吧",
	["~oharamari"]                      = "不！失败这词是不会存在我的字典里的",
	["~matsuurakanan"]                  = "别在意别在意",
	["$fuqian1"]                        = "人无法独自生存，互相支撑前进吧",
	["$fuqian2"]                        = "对不起，忙吗？想着偶尔见一面呢，",
	["$huanggui1"]                      = "我的话，就在这里",
	["$huanggui2"]                      = "这样就行了",
	["~youj"]                           = "被打败了",
	["$dafan1"]                         = "这招如何",
	["$dafan2"]                         = "切换",
	["$juej1"]                          = "绝剑",
	["$juej2"]                          = "绝剑",
	["$smsy1"]                          = "远远不够，还需要努力",
	["$smsy2"]                          = "圣母圣咏",
	["$hmrleiji1"]                      = "感到力量涌动了。只要不停下来，就能变得更强。",
	["$hmrleiji2"]                      = "嗯，预见一下总不坏。就能看到必须前往的前方了。",
	["$jiyidiejia1"]                    = "所以我将，继续战斗下去。",
	["$jiyidiejia2"]                    = "你们捡了一条命呢",
	["$sugong1"]                        = "阿勒，你害怕了吗",
	["$sugong2"]                        = "我是庄家，上咯",
	["$chibing"]                        = "玉米卷即是正义",
	["$dushe1"]                         = "赶快走开",
	["$dushe2"]                         = "牵手吧！如果那是命运的话",
	["$dushe3"]                         = "这种级别的战斗，根本没办法让我发挥完全的实力",
	["$myjl1"]                          = "地狱的火燃烧吧",
	["$myjl2"]                          = "黑暗的使徒降临",
	["$myjl3"]                          = "神罚",
	["$myjl4"]                          = "坠落地狱里去吧",
	["$zuzhou"]                         = "啊哈！",
	["~gokoururi"]                      = "这怎么可能",
	["$suoersiman"]                     = "走开!",
	["$yinbiman1"]                      = "相信着你",
	["$yinbiman2"]                      = "准备OK",
	["$jujiman1"]                       = "走吧",
	["$jujiman2"]                       = "找到你了",
	["$jujiman3"]                       = "不要忘记补充子弹",
	["$xiangyangshi1"]                  = "加油呢！",
	["$xiangyangshi2"]                  = "上吧！",
	["$shengdanny1"]                    = "还不错",
	["$shengdanny2"]                    = "游戏开始",
	["$leijijingyan1"]                  = "太好了，完美",
	["$leijijingyan2"]                  = "太好了",
	["$mingduan1"]                      = "看起来很疲惫呢，一起喝点抹茶吗。",
	["$yushicp1"]                       = "看看我华丽的技术吧。",
	["$mingduan2"]                      = "像我这种好事做尽的人，当然能够迎来圣诞老人了。",
	["$yushicp2"]                       = "珍惜每分每秒，不想留下任何遗憾。",
	["$liufang1"]                       = "",
	["$liufang2"]                       = "",
	["~yanmoai"]                        = "",
	["$zhengdao2"]                      = "这样就行了！",
	["$zhengdao1"]                      = "邀请也是很重要的，去试试吧！",
	["$zhihouz"]                        = "如果你吃了人鱼肉，变得长生不老，也一定不要忘记花丸的说。",
	["$yueying1"]                       = "那可真是一石二鸟",
	["$yueying2"]                       = "交给我吧",
	["$haite1"]                         = "海底捞月",
	["$haite2"]                         = "我的回合到了",
	["$nvzidao1"]                       = "把更多的魅力传递给大家",
	["$nvzidao2"]                       = "很出色",
	["$chuanxiao"]                      = "把微笑传递给大家",
	["$weixiaojn1"]                     = "你能行",
	["$weixiaojn2"]                     = "拿出自信吧",
	["~nike"]                           = "…好不甘心",
	["$yijizho1"]                       = "（狙击枪声）",
	["$yijizho2"]                       = "（远处狙击声）",
	["$zhongerhx1"]                     = "我是暗黑烈火使，被黑暗的火焰包围着死去吧",
	["$zhongerhx2"]                     = "这家伙没救了",
	["$zhongerhx3"]                     = "中二病真麻烦呢",
	["$zhongerhx4"]                     = "放心吧，再怎么说我也是原暗黑烈火使啊！",
	["$zhongerhx5"]                     = "快让我看吧！邪王真眼！",
	["$qiyuan1"]                        = "啊！Level Up！",
	["$qiyuan2"]                        = "小伊—！看到了吗！？已经成长到这种地步了",
	["$qidao1"]                         = "能听见《魔法速报》世界的小伊的嚎啕大哭诶。又输给了1%的概率么",
	["$qidao2"]                         = "已经实装了两个我呢！",
	["$qidao3"]                         = "拜托了",
	["$hezibz1"]                        = "是谁做了那种事",
	["$hezibz2"]                        = "我变成了一个人，我的归宿已经……",
	["$hezibz3"]                        = "我是喰种",
	["$shayiqr1"]                       = "不行，无法控制，不要，谁来救救我呀",
	["$shayiqr2"]                       = "请快点逃走，再这样下去，我就要杀死你了，所以请你快点逃走",
	["$shayiqr3"]                       = "似乎要被食欲的汪洋所吞噬，体会到坠入快感之中的愉悦，但是，我不能，迷失自我",
	["$tucao1"]                         = "你明白什么了？",
	["$tucao2"]                         = "我行使拒绝权！",
	["$tucao3"]                         = "拜托你说些不会让人觉得不知所云的话吧。",
	["$tucao4"]                         = "哎呀哎呀。",
	["~axu"]                            = "到底现在那家伙在哪里，把我一个人丢在这里，那个笨蛋在哪逍遥呢......",
	["$bingfengzd"]                     = "",
	["$hanrenzd"]                       = "",
	["$puzou1"]                         = "只有你能让我感受到……这样的心情…",
	["$puzou2"]                         = "实在没办法呢。让我来帮你吧",
	["$qianjinzj"]                      = "…居然让我一直在等…会不会有点过分啊？",
	["$zjruoshi"]                       = "还能继续哦！",
	["$zjaojiaol1"]                     = "才不寂寞呢",
	["$zjaojiaol2"]                     = "明明很想跟你见面的说……真是个木头人啦",
	["$zjyizhen1"]                      = "变得想要更深入地了解你……这样子，还真不像我的做风",
	["$zjyizhen2"]                      = "比起战斗更适合被保护的角色……这是什么意思呀",
	["$zjmoshuxif1"]                    = "你…是在挑衅吗？",
	["$zjmoshuxif2"]                    = "喂喂，如果是把我给忘记了我是不会轻饶你的哦",
	["$empaidui1"]                      = "那么，让我们举办一场华丽的派对吧！",
	["$empaidui2"]                      = "随便找一个打了poi",
	["$yftuji1"]                        = "即使是打开船帆，也要继续战斗！",
	["$yftuji2"]                        = "夕立、突击poi。",
	["$htms_weiyi1"]                    = "什么？再继续碰我的话，可要做好觉悟哦。",
	["$htms_weiyi2"]                    = "你的实力就这？",
	["$mingmendia1"]                    = "我可是没有什么空闲时间。如果有什么想说的，赶快说吧。",
	["$mingmendia2"]                    = "我有很多技能，如果有困扰的时候，都可以找我商量的",
	["$zchize1"]                        = "解决的方法只有靠努力啊。",
	["$zchize2"]                        = "你觉得刚才那是在对话吗？",
	["$zchize3"]                        = "这样做人不觉得有问题吗。",
	["$gaoling1"]                       = "不对。",
	["$gaoling2"]                       = "诶，何以见得？",
	["$gaoling3"]                       = "感谢我吧。",
	["~xuenai"]                         = "总有一天，要来拯救我哦。",
	["$huidang1"]                       = "穿越时空，而且是每次死亡都回到初期状态，其名为死亡回归。",
	["$zhengjiu1"]                      = "那么，我也为了我自己来帮助你吧。我的目的是…… 日行一善！",
	["$zhengjiu2"]                      = "跟过来啊，先说好我可是公认的烦到不容忽视的男人",
	["$zhengjiu3"]                      = "那个时候，我发了誓，我一定会拯救你。",
	["~subaru"]                         = "等着我……， 我一定会 …… 拯救你的！",
	["$ujyaozhan1"]                     = "再一次一决胜负吧",
	["$ujyaozhan2"]                     = "交给我吧！",
	["$ujyaozhan3"]                     = "不会放弃的！",
	["$ujyaozhan4"]                     = "快点跟上！亚丝娜！",
	["$ujyaozhan5"]                     = "亚丝娜！",
	["$ujyaozhan6"]                     = "桐人！",
	["$ujlianji1"]                      = "上吧！",
	["$ujlianji2"]                      = "要上了！",
	["$ujlianji3"]                      = "全力的上了！",
	["$ujlianji4"]                      = "这样就结束了！",
	["$ujlianji5"]                      = "也是没办法",
	["$ujzhongshi1"]                    = "就这样保持下去",
	["$ujzhongshi2"]                    = "做好觉悟吧！",
	["$ujzhongshi3"]                    = "交给我吧！",
	["$molwf1"]                         = "机会不错，让我来教育你。",
	["$html_shisheng1"]                 = "卑王铁锤，反转旭光――吞噬光芒吧，誓约胜利之剑！",
	["$molwf2"]                         = "哭泣吧。该是你声名扫地之时了。",
	["$html_shisheng2"]                 = "落入尸山吧。崩塌吧，誓约胜利之剑！",
	["~heic8"]                          = "到此为止了吗。",
	["$Sdorica_FuWei1"]                 = "我来保护大家。",
	["$Sdorica_FuWei2"]                 = "这里由我来！",
	["$Sdorica_FuWei3"]                 = "给同伴们勇气！",
	["$Sdorica_FuWei4"]                 = "全军前进！胜利就在眼前！",
	["$Sdorica_MiLing1"]                = "麻烦你了。",
	["$Sdorica_MiLing2"]                = "消灭敌军！",
	["$Sdorica_MiLing3"]                = "太阳啊！",
	["$Sdorica_MiLing4"]                = "感受太阳的温暖。",
	["$Sdorica_MiLing5"]                = "哈啊！",
	["$Sdorica_MiLing6"]                = "放心吧！",
	["~Sdorica_Angelia"]                = "我不会喊累的。",
	["$void1"]                          = "休想",
	["$void2"]                          = "休想",
	["$wangguo1"]                       = "我要成为王",
	["$wangguo2"]                       = "我知道的",
	["$blmf1"]                          = "燃尽吧！",
	["$blmf2"]                          = "非常的舒服",
	["$blmf3"]                          = "太棒了",
	["$htms_mozhi1"]                    = "我们根本不需要落脚点",
	["$htms_mozhi2"]                    = "只要你们不停下，那前方就有我",
	["$htms_mozhi3"]                    = "至今为止的努力并非是徒劳",
	["$htms_mozhi4"]                    = "什么嘛！我射的蛮准的",
	["$lsmz1"]                          = "该怎么办呢",
	["$lsmz2"]                          = "我回来了，为了踏上新的旅程",
	["$tmsp1"]                          = "夏娜我要改变你的命运",
	["$tmsp2"]                          = "我要改变",
	["$yiban1"]                         = "出发去微服参观吧！",
	["$yiban2"]                         = "不介意的话，能请您和我当朋友吗？",
	["$yiban3"]                         = "你要是能稍微分我一点的话，我会很高兴的。",
	["$yiban4"]                         = "Let‘s go！（吉斯）啊啊...姐姐，冷静点。",
	["$pomiehb1"]                       = "哈~这一天过得太棒了~",
	["$pomiehb2"]                       = "好，就按现在这样，不断努力吧！",
	["$pomiehb3"]                       = "我好厉害呀？我很厉害哟！",
	["$pomiehb4"]                       = "你的头发，像是丝绸一样美丽~",
	["$pomiehb5"]                       = "一定会好的。",
	["$pomiehb6"]                       = "那很不错呀，有很多人都想听你弹钢琴呢。",
	["~ktln"]                           = "你们要是继续干这种事，当心破灭哦！",
	["$embers1"]                        = "手上沾上鲜血的我真的有追求幸福的权利吗？但我讨厌一个人孤零零的.",
	["$embers2"]                        = "我害怕孤单一人，那实在是过于难受",
	["$embers3"]                        = "绝望总是在充满希望的时候出现，所以我不怀有希望",
	["$embers4"]                        = "每个人都有不为人知的一面",
	["$embers5"]                        = "我的回合到了呢",
	["$embers6"]                        = "本回合就这样",
	--技能翻译
	["zyjianshu"]                       = "剑术",
	["zyfashi"]                         = "法师",
	["zymushi"]                         = "任务",
	["zymushijl"]                       = "牧师",
	["zycike"]                          = "刺客",
	["zydadun"]                         = "大盾",
	--技能翻译
	["zhuisha"]                         = "追杀",
	["htms_zangsong"]                   = "葬送",
	["ansha"]                           = "暗杀",
	["shilian"]                         = "试炼",
	["shilianEX"]                       = "试炼",
	["zzsl"]                            = "最终试炼",
	["xianxsy_cishu"]                   = "鲜血神衣",
	["xianxuefeiteng"]                  = "鲜血沸腾",
	["fengwang"]                        = "风王",
	["newfengwang"]                     = "风王",
	["wangzhe"]                         = "王者",
	["doubleslash"]                     = "二刀流",
	["betacheater"]                     = "封弊者",
	["howling"]                         = "高频咆哮",
	["howlingCard"]                     = "高频咆哮",
	["handsonic"]                       = "音速手刃",
	["defencefield"]                    = "防御结界",
	["frozenpuppet"]                    = "冰冻傀儡",
	["frozenpuppetCard"]                = "冰冻傀儡",
	["chuszy"]                          = "初始之音",
	["htms_xiaoshi"]                    = "消失",
	["mie"]                             = "灭杀",
	["mie_EX"]                          = "灭杀",
	["Luazuihou"]                       = "最后",
	["Luajianzai"]                      = "舰载",
	["leij"]                            = "雷击",
	["diancp"]                          = "电磁炮",
	["Luaemeng"]                        = "噩梦",
	["kuangquan"]                       = "所罗门狂犬",
	["Luayezhan"]                       = "夜战",
	["jiasugaobai"]                     = "加速告白",
	["juedoujiasu"]                     = "决斗加速",
	["jiasuduijue"]                     = "加速对决",
	["qingtq"]                          = "蜻蜓切",
	["xiangy"]                          = "翔翼",
	["#Luajianzai"]                     = "舰载",
	["fazededizao"]                     = "法则的缔造",
	["#fazededizaoskip"]                = "法则的缔造",
	["jiujideqiyuan"]                   = "救济的祈愿",
	["gonglzs"]                         = "攻略之神",
	["shens"]                           = "神知",
	["pojgj"]                           = "破军歌姬",
	["hunq"]                            = "魂曲",
	["LuamuguanVS"]                     = "目观",
	["Luamuguan"]                       = "目观",
	["#soulfireDamage"]                 = "余烬",
	["soulfire"]                        = "魂火",
	["jfxl"]                            = "疾风迅雷",
	["duanzui"]                         = "断罪",
	["tprs"]                            = "天破壤碎",
	["zhenhong"]                        = "真红",
	["meihuomoyan"]                     = "魅惑之魔眼",
	["kaleidoscope"]                    = "千变万化镜",
	["haniel"]                          = "赝造魔女",
	["#yanzaostart"]                    = "赝造",
	["guancha"]                         = "观察",
	["jiyi"]                            = "畸意",
	["Luayihang"]                       = "一航",
	["Luachicheng"]                     = "吃撑",
	["zhujuexz"]                        = "主角修正",
	["lunhui"]                          = "轮回的宿命",
	["lunhui1"]                         = "轮回",
	["pocdsf"]                          = "破除的束缚",
	["lolita"]                          = "合法萝莉",
	["judas"]                           = "犹超级大",
	["yuandian"]                        = "原典",
	["moxing"]                          = "魔性",
	["xiangrui"]                        = "祥瑞",
	["wnlz"]                            = "无能力者",
	["hxss"]                            = "幻想杀手",
	["Luachuyi"]                        = "厨艺Max",
	["Lualianji"]                       = "闪光连击",
	["kbyxt"]                           = "可变翼系统",
	["kznw"]                            = "空之女王",
	["geass"]                           = "绝对指令",
	["geasstarget"]                     = "绝对指令",
	["znai"]                            = "智能AI",
	["changedfate"]                     = "被改变的命运",
	["lsmz"]                            = "零时迷子",
	["bhjz"]                            = "避火戒指",
	["tmsp"]                            = "大命诗篇",
	["wangzbk"]                         = "王之宝库",
	["bings"]                           = "兵弑",
	["guailj"]                          = "乖离剑",
	["zhou"]                            = "昼",
	["#zhou"]                           = "昼",
	["ye"]                              = "夜",
	["guichan"]                         = "鬼缠",
	["dafan"]                           = "打反",
	["juej"]                            = "绝剑",
	["smsy"]                            = "圣母圣咏",
	["jiewq"]                           = "界王拳",
	["saiya"]                           = "赛亚人",
	["gbg"]                             = "龟波功",
	["zizai"]                           = "自在极意",
	["bczzr"]                           = "不存在之人",
	["mozy"]                            = "木偶之眼",
	["qsas"]                            = "情殇哀逝",
	["zsmy"]                            = "直死魔眼",
	["nirendao"]                        = "逆刃刀",
	["nidaoren"]                        = "逆刀刃",
	["#nidaorenDis"]                    = "逆刀刃",
	["badaozhai"]                       = "拔刀斋",
	["feils"]                           = "飞雷神之术",
	["jssg"]                            = "金色闪光",
	["feils2"]                          = "飞雷神二段",
	["kuixin"]                          = "窥心",
	["jiushu"]                          = "救赎",
	["xieheng"]                         = "协横",
	["tjdzf"]                           = "痛觉的止符",
	["qrdag"]                           = "青刃的哀歌",
	["fenmao"]                          = "粉毛",
	["changgui"]                        = "常规",
	["heihua"]                          = "黑化",
	["samsara"]                         = "轮回",
	["zuihoudefanji"]                   = "最后的反击",
	["businiao"]                        = "不死鸟",
	["zhanxianfanyu"]                   = "战线防御",
	["jixieshenslash"]                  = "革命机",
	["jixieshendefense"]                = "拂晓",
	["jixieshenchain"]                  = "高文",
	["jixieshen"]                       = "机械公敌",
	["loyal_inu"]                       = "忠犬",
	["kikann"]                          = "归还",
	["loyal_inu_damage"]                = "忠犬",
	["guangzijupao"]                    = "光子巨炮",
	["guangzijupaoCard"]                = "光子巨炮",
	["kuanghua"]                        = "狂化",
	["lanyuhua"]                        = "蓝羽化",
	["baozou"]                          = "暴走",
	["jueduiyazhi"]                     = "绝对压制",
	["jueduiyazhiCard"]                 = "绝对压制",
	["jinhua"]                          = "进化",
	["Luayumian"]                       = "御免",
	["Luayanhu"]                        = "掩护",
	["xinsuo"]                          = "心锁",
	["yohane"]                          = "夜羽",
	["fengfu"]                          = "凤缚",
	["mingchuan"]                       = "命舛",
	["wuduan"]                          = "五段提升",
	["tisheng"]                         = "提升",
	["fanyi"]                           = "繁艺",
	["jihang"]                          = "疾航",
	["jiaoxing"]                        = "娇性",
	["anni"]                            = "暗逆",
	["lianjiqudong"]                    = "连击驱动",
	["moyu"]                            = "摸鱼",
	["sandun"]                          = "伞盾",
	["xieyan"]                          = "邪眼",
	["sugong"]                          = "速攻",
	["chibing"]                         = "吃饼",
	["haiyin"]                          = "海音",
	["fuzou"]                           = "复奏",
	["fuzou_filter"]                    = "复奏",
	["htms_wanlan"]                     = "挽澜",
	["tianqu"]                          = "天驱",
	["tianqu_from"]                     = "天驱",
	["tianqu_to"]                       = "天驱",
	["fuqian"]                          = "浮潜",
	["huanggui"]                        = "煌轨",
	["zangsong"]                        = "葬送",
	["zangsongCard"]                    = "葬送",
	["jianwushu"]                       = "剑武术",
	["jichengzhe"]                      = "继承者",
	["Cjiyongbing"]                     = "C级佣兵",
	["juexingmoshen"]                   = "觉醒魔神",
	["huoliquankai"]                    = "火力全开",
	["fengshou"]                        = "丰收",
	["haite"]                           = "海底摸月",
	["yueying"]                         = "月盈",
	["hmrleiji"]                        = "因果累积",
	["jiyidiejia"]                      = "记忆叠加",
	["dushe"]                           = "毒舌",
	["myjl"]                            = "命运记录",
	["zuzhou"]                          = "诅咒",
	["jujiman"]                         = "狙击",
	["yinbiman"]                        = "隐蔽",
	["suoersiman"]                      = "索尔斯",
	["zhiyujz"]                         = "治愈讲座",
	["zhiyujz_jz"]                      = "治愈讲座.进阶",
	["zhiyujz_jx"]                      = "治愈讲座.觉醒",
	["shengdanny"]                      = "圣诞暖阳",
	["leijijingyan"]                    = "经验累积",
	["xiangyangshi"]                    = "向阳使",
	["mingduan"]                        = "明断",
	["mingduan_put"]                    = "明断",
	["yushicp"]                         = "御势",
	["wushitexing"]                     = "无视特性",
	["meipengyou"]                      = "没有朋友",
	["shanyao"]                         = "闪耀",
	["jiansu"]                          = "剑速",
	["yugao"]                           = "预告",
	["guaidao"]                         = "怪盗",
	["weituo"]                          = "委托",
	["liufang"]                         = "流放",
	["yuanhuo"]                         = "怨火",
	["zhengdao"]                        = "争导",
	["zhihouz"]                         = "滞后",
	["jiqiangs"]                        = "机枪模式",
	["lanyushanbi"]                     = "蓝羽闪避",
	["jibanhy"]                         = "羁绊",
	["jibanvs"]                         = "羁绊",
	["chenmohy"]                        = "沉默",
	["nvzidao"]                         = "女子道",
	["chuanxiao"]                       = "传笑",
	["weixiaojn"]                       = "微笑",
	["yijizho"]                         = "一击",
	["htms_fengyu"]                     = "风语",
	["wujinzhishu"]                     = "无尽之书",
	["chunrijilu"]                      = "春日记录",
	["duandai"]                         = "缎带",
	["tucao"]                           = "吐槽",
	["wangwei"]                         = "王位",
	["qiyuan"]                          = "祈愿",
	["qidao"]                           = "祈祷",
	["LuaLeishi"]                       = "雷矢",
	["Luayuanxing"]                     = "元兴",
	["Luayuanling"]                     = "怨灵",
	["luayuanling"]                     = "怨灵",
	["Luashenyi"]                       = "神裔",
	["luakuaiqing"]                     = "快晴",
	["luajiejie"]                       = "结界",
	["luajieao"]                        = "桀骜",
	["luajinlun"]                       = "经纶",
	["empaidui"]                        = "噩梦派对",
	["yftuji"]                          = "扬帆突击",
	["zhongerhx"]                       = "中二幻想",
	["hanrenzd"]                        = "寒刃",
	["bingfengzd"]                      = "冰封",
	["hezibz"]                          = "赫子暴走",
	["shayiqr"]                         = "杀意浸染",
	["duancai"]                         = "断裁",
	["midie"]                           = "迷迭",
	["duancaiex"]                       = "断裁",
	["tongzhouqg"]                      = "同舟",
	["qgjiesi"]                         = "解思",
	["zjyizhen"]                        = "医诊",
	["zjmoshuxif"]                      = "魔术戏法",
	["zjruoshi"]                        = "高岭之花",
	["zjaojiaol"]                       = "傲娇",
	["qianjinzj"]                       = "千金",
	["bieniu"]                          = "彆扭",
	["puzou"]                           = "谱奏",
	["htms_weiyi"]                      = "威仪",
	["mingmendia"]                      = "名门",
	["luatiaobo"]                       = "挑拨",
	["luanizhuan"]                      = "逆转",
	["luanyanguang"]                    = "眼光",
	["lualushou"]                       = "辘首",
	["huazang"]                         = "花葬",
	["zchize"]                          = "直斥",
	["gaoling"]                         = "高岭",
	["huidang"]                         = "回档",
	["zhengjiu"]                        = "拯救",
	["molwf"]                           = "魔力外放",
	["html_shisheng"]                   = "誓胜",
	["ujyaozhan"]                       = "邀战",
	["ujzhongshi"]                      = "终式",
	["ujlianji"]                        = "连击",
	["ujlianjig"]                       = "连击",
	["Sdorica_FuWei"]                   = "扶危",
	["Sdorica_MiLing"]                  = "辉煌",
	["sdorica_miling"]                  = "辉煌",
	["void"]                            = "虚空",
	["wangguo"]                         = "王国",
	["lsqd"]                            = "零式驱动",
	["tscg"]                            = "天使重构",
	["wzgz"]                            = "武装构造",
	["tcmfs"]                           = "天才魔法师",
	["blmf"]                            = "爆裂魔法",
	["htms_mozhi"]                      = "莫止",
	["yiban"]                           = "依伴",
	["pomiehb"]                         = "破灭回避",
	["zhumyb"]                          = "逐梦一步",
	["tonghh"]                          = "同好",
	["luashouhuo"]                      = "收获",
	["luahongyu"]                       = "红芋",
	["pinkdevil"]                       = "粉红恶魔",
	["khztbuff"]                        = "狂化状态",
	["embers"]                          = "余烬",
	["gxzhiliao"]                       = "高效治疗",
	["shenpan"]                         = "审判",
	["wugshashou"]                      = "莫得感情的杀手",
	["nxlieren"]                        = "耐心的猎人",
	["nxlieren_damage"]                 = "耐心的猎人",
	["xibu"]                            = "系步",
	["dalunb"]                          = "大论",
	["zhanshubuju"]                     = "布局",
	["zhachang"]                        = "炸场",
	["hongshui"]                        = "洪水",
	["zhufu"]                           = "祝福",
	["afuhuo"]                          = "复活",
	["tonghua"]                         = "童话",
	["lingbo"]                          = "灵波",
	["chaogz"]                          = "超改造",
	["shengqiang"]                      = "圣枪",
	["paojixj"]                         = "炮击",
	["dqjt"]                            = "盗窃精通",
	["lianxie"]                         = "连携",
	["huanzhaung"]                      = "换装",
	["xinshengll"]                      = "新生",
	["llpj"]                            = "破局",
	["shejiao"]                         = "社交",
	["shejiaofuka"]                     = "社交",
	["jsdy"]                            = "决胜大衣",
	["wanxian"]                         = "婉弦",
	["liantan"]                         = "连弹",
	["s_yanyu"]                         = "焰愈",
	["s_yanmojianglin"]                 = "炎魔降临",
	["s_lianjie"]                       = "连结",
	["s_polie"]                         = "破裂",
	["s_shuimian"]                      = "睡眠",
	["s_jieshu"]                        = "借宿",
	["s_fudao"]                         = "辅导",
	["s_douM"]                          = "抖M",
	["s_shiziqishi"]                    = "十字骑士",
	["s_kongyi"]                        = "空移",
	["s_yueqian"]                       = "跃迁",
	["s_newtype"]                       = "新人类",
	["s_newtypeOther"]                  = "新人类",
	--技能描述
	[":zyjianshu"]                      = "使用【杀】时，若装备剑武器，目标须使用两张【闪】抵消。",
	[":zyfashi"]                        = "场上有1/3/5个法师职业时，锦囊牌无距离限制/使用红色锦囊牌造成伤害时，可弃置一张牌伤害+1/使用锦囊牌造成伤害时，弃置一张牌此伤害+1。",
	[":zymushi"]                        = "当你使用四张【桃】后，治疗效果+1。",
	[":zymushijl"]                      = "<font color=\"blue\"><b>锁定技，</b></font>你的治疗效果+1。",
	[":zycike"]                         = "出牌阶段限一次，你可观看一名未装备装备牌的其他角色两张手牌。",
	[":zydadun"]                        = "当你受伤时，若牌堆牌少于你当前体力十倍，你可增加一点体力上限并回复回复一点体力失去此技能，若你当前体力为1，则回复至体力上限。",
	--技能叙述
	[":zhuisha"]                        = "当你使用【杀】被抵消时，你可以摸一张牌并将一张牌置于对方武将牌上，称为“追”。有“追”角色受到你的【杀】造成的伤害时，此伤害+x(x为其“追”数量)并弃置所有“追”",
	[":htms_zangsong"]                 	= "出牌阶段限一次，你可以弃置一张伤害牌，视为对一名其他角色使用一张【杀】，此【杀】伤害+x，（x为其已损失体力）。",
	[":ansha"]                          = "<font color=\"blue\"><b>锁定技，</b></font>当你使用的【杀】造成伤害时，若该角色未受伤，则此伤害+1；当你使用的【杀】造成伤害时，若该角色的武将牌上有“追”，则此伤害+X，然后弃置其所有的“追”（X为“追”的数量）",
	[":shilian"]                        = "当你受到伤害后，你可以视为对伤害来源使用一张【杀】",
	[":shilianEX"]                      = "当你受到伤害时，你可以视为对伤害来源使用一张【杀】，此杀无视防具。",
	[":zzsl"]                           = "<font color=\"purple\"><b>觉醒技，</b></font>当你使用三次【杀】后，修改“试炼”（当你受到伤害时，你可以摸一张牌并视为对其使用一张【杀】，此杀无视防具。）",
	[":xianxsy_cishu"]                  = "<font color=\"blue\"><b>锁定技，</b></font>若你首次鲜血标记减少至0或首次获得鲜血标记，则你手牌上限,你的【杀】攻击范围，目标，次数始终为X，（X为鲜血标记数）。",
	[":xianxuefeiteng"]                 = "出牌阶段开始时，你可将体力值与已损失体力互换，若因此回复/减少体力值，则你失去/获得最大数值等量的“鲜血”标记。",
	[":fengwang"]                       = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张基本牌并令一名有手牌且装备区内有牌的其他角色展示所有手牌，然后该角色选择一项：1.弃置一张装备牌；2.弃置手牌中的【杀】",
	[":newfengwang"]                    = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张基本牌选择一名有手牌的其他角色并选择一项：1.其失去一点体力并回收其所有装备区内的牌；2.其无法使用闪，直到你的回合结束。",
	[":wangzhe"]                        = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置一张牌，若如此做，你视为使用了一张【杀】，此【杀】可以额外指定两名目标",
	[":doubleslash"]                    = "出牌阶段开始时，你可以摸一张牌并弃置一张手牌，因此弃置牌为：红色，本回合你使用【杀】的上限+1；若为黑色，本回合你使用【杀】可选择的目标上限+1。",
	[":betacheater"]                    = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，你须将手牌全部放置在武将牌上称为“隐藏”；当你受到一点伤害时，你须弃置一张“隐藏”牌防止之。准备阶段开始时，你获得所有的“隐藏”牌。",
	[":howling"]                        = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌，令攻击范围内所有其他角色打出一张【杀】或【闪】，否则你对其造成一点伤害。",
	[":handsonic"]                      = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张基本牌，令其他装备区没有防具的角色选择一项：将一张牌置于你的武将牌上，称为“等级”，或令你弃置其一张牌。若你的“等级”数量不小于3，你获得之。",
	[":defencefield"]                   = "当一名角色需要使用或打出【闪】时，你可以弃置一张<font color=\"red\">红色</font>牌，视为该角色使用或打出了一张【闪】。",
	[":frozenpuppet"]                   = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以弃置所有手牌（至少1张）并选择一名角色，直到你下个回合开始，其他角色使用的牌对其无效。",
	[":chuszy"]                         = "当一名角色受到伤害后，若是其于本阶段内第一次受到伤害，则你可以弃置一张牌并令其回复1点体力",
	[":htms_xiaoshi"]                   = "<font color=\"blue\"><b>锁定技，</b></font>当你死亡时，你令杀死你的角色扣减1点体力上限并弃置装备区中的所有牌",
	[":mie"]                            = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张基本牌，并选择一名其他角色，你弃置其一张牌。",
	[":mie2"]                           = "<font color=\"green\"><b>出牌阶段限两次，</b></font>你可以弃置一张牌并选择一名其他角色，你获得其一张牌。",
	[":mie_EX"]                         = "<font color=\"green\"><b>出牌阶段限两次，</b></font>你可以弃置一张牌并选择一名其他角色，你获得其一张牌。",
	[":Luazuihou"]                      = "<font color=\"purple\"><b>觉醒技，</b></font>当你的体力值为1点时，你须将体力上限减少至1，立刻跳过当前角色的所有阶段，你进行一个额外回合，并且你攻击距离和手牌上限始终+2，并且将【灭杀皇】的效果修改为，<font color=\"green\"><b>出牌阶段限两次，</b></font>你可以弃置一张牌并选择一名其他角色，你获得其一张牌。",
	[":Luajianzai"]                     = "<font color=\"blue\"><b>锁定技，</b></font>每当你从摸牌堆获得牌时，你摸一张牌（不能发动“舰载”）。每当你受到一次伤害时，你须弃置一张手牌。",
	[":leij"]                           = "<font color=\"blue\"><b>锁定技，</b></font>你的【杀】均视为雷【杀】。<font color=\"blue\"><b>锁定技，</b></font>当你受到雷电伤害时，免疫雷伤。",
	[":diancp"]                         = "出牌阶段，你可以弃置一张雷【杀】并对一名其他角色造成1点雷电伤害，若该角色因此进入了濒死状态，则你失去1点体力",
	[":Luaemeng"]                       = "当你于出牌阶段造成伤害时，你可以弃置一张牌，令此伤害+1",
	[":kuangquan"]                      = "出牌阶段限一次，你可以弃置一枚“忠”标记，对其他所有角色造成一点伤害，并令其弃置两张牌",
	[":Luayezhan"]                      = "摸牌阶段开始时，你可以进行一次判定，若结果为黑色，本回合内你使用的你为伤害来源的【杀】和【决斗】造成的伤害+1。",
	[":jiasugaobai"]                    = "当你成为【决斗】的目标时，你可以令一名男性角色摸一张牌，然后此【决斗】对你的效果无法被响应",
	[":juedoujiasu"]                    = "当你成为【决斗】的目标或使用【决斗】时，你可以摸一张牌，此决斗结算完毕后，受伤角色各摸一张牌。",
	[":jiasuduijue"]                    = "当你成为黑色【杀】的目标时，你可以令此杀无效，视为其对你使用一张【决斗】。每当你使用黑色【杀】时，你可以令此杀无效，视为对其使用一张【决斗】",
	[":qingtq"]                         = "<font color=\"blue\"><b>锁定技，</b></font>你不能被选择为武器牌的目标；当你使用【杀】指定一个目标后，目标角色须弃置一张手牌；你的攻击范围为X（X为场上最大的体力值）",
	[":xiangy"]                         = "你可以将一张装备牌当【闪】使用或打出。若如此做，你选择一项：摸一张牌，或弃置场上的一张牌",
	[":fazededizao"]                    = "回合开始时，你可以选择一个未以此法选择过的游戏阶段（除准备阶段和结束阶段外），所有其他角色回合内均跳过此阶段直到你的下个回合开始；若你已选择过了所有阶段，你重置之。",
	[":jiujideqiyuan"]                  = "出牌阶段限一次，你可以弃置X张不同类型的牌，然后令X名角色各回复一点体力（X最大为3）。",
	[":gonglzs"]                        = "当你成为一名角色【杀】的目标后，你可以弃置你区域内的一张牌，然后你获得该角色相同区域内的一张牌。",
	[":shens"]                          = "当一名角色进入濒死状态时，你可以展示牌堆顶的四张牌，若其中至少有两张花色和类型均相同的牌，则该角色回复一点体力且你获得展示的牌中符合条件的牌中的一张。",
	[":pojgj"]                          = "出牌阶段，你可以失去1点体力并令一名已受伤的其他角色回复1点体力。",
	[":hunq"]                           = "当你的体力发生变化时，你可以令一名角色摸一张牌",
	[":LuamuguanVS"]                    = "出牌阶段每名角色限一次，你可以弃置一张牌，并指定一名其他角色，你与其距离始终为1，且你对其，或其对你造成伤害时，此伤害+1，直到你下回合开始。",
	[":soulfire"]                       = "你可以将一张【闪】或者【杀】当做火【杀】使用或打出。因此杀受到伤害的角色须弃置一张牌，然后你可以失去一点体力对其造成一点伤害。",
	[":jfxl"]                           = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并失去一点体力，对所有距离你为1的所有其他角色造成一点伤害",
	[":duanzui"]                        = "当其他角色于摸牌阶段外获得牌后，你可以对其造成1点火属性伤害。",
	[":tprs"]                           = "限定技，出牌阶段开始时，你可以将体力调整至1，并视为对距离1以内的其他角色使用一张基础伤害为X点的火【杀】，然后对攻击范围内的其他角色造成1点火焰伤害并获得【断罪】（X为因此失去体力数）。",
	[":zhenhong"]                       = "在你的回合外，你可以将一张牌当做火【杀】使用或打出,若目标手牌数大于你则此【杀】无法被闪避：当你以此法使用的【杀】造成伤害时，你可以弃置目标的一张牌。",
	[":meihuomoyan"]                    = "当一名角色使用基本牌或普通锦囊牌指定唯一目标时，你可以将此牌的目标转移给一名合法角色，或取消此牌的目标。每名角色每局游戏限一次，额外的，一名角色对你造成伤害后，重置技能对其的次数。",
	[":kaleidoscope"]                   = "游戏开始时，回合开始或结束时，你可以选择一名角色，于此技能下次发动前拥有其的一项技能。",
	[":haniel"]                         = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你选择是否弃置一张牌，若选择否，你摸一张牌且于此回合内手牌上限-1且于下个准备阶段开始前所有技能无效。",
	[":guancha"]                        = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将你的一半手牌（向上取整）交给一名其他角色，然后你回复一点体力。",
	[":jiyi"]                           = "每当你回复体力后，你可以失去一点体力并观看牌堆顶的4张牌，你获得其中的两张，若如此做，你弃置其余的牌或以任意顺序至于牌堆顶。",
	[":Luayihang"]                      = "<font color=\"blue\"><b>锁定技，</b></font>你计算与其他角色的距离始终-1。并且你手牌上限增加2X(X为已损失体力）",
	[":Luachicheng"]                    = "摸牌阶段开始时，你可以额外摸两张牌，若如此做，本回合你不能使用【杀】。",
	[":zhujuexz"]                       = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置至少1张牌，然后亮出牌堆顶的1张牌直到所有亮出的牌总点数大于x为止，然后你获得这些亮出的牌。（x为你以此法弃置的牌的总点数）",
	[":lunhui"]                         = "你的回合外，当你失去一张牌时，你可以进行一次判定，若判定结果为黑色，则摸一张牌。你的回合内，当你失去一张牌时，若此牌是因弃置进入弃牌堆并且此牌为红色，则你可以使用此牌。",
	[":pocdsf"]                         = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置所有其他角色的武器牌，然后你弃置等量的牌（不足全弃）。",
	[":lolita"]                         = "<font color=\"blue\"><b>锁定技，</b></font>当一名其他角色使用【杀】指定除你之外的唯一目标后，若你同时处于此【杀】使用者以及目标角色的攻击范围内，则你也成为此【杀】的目标。",
	[":judas"]                          = "当你于回合外成为其他角色【杀】的目标后，你可以选择一项：对该角色使用一张【杀】，或摸一张牌。",
	[":yuandian"]                       = "<font color=\"blue\"><b>锁定技，</b></font>当你杀死一名角色时，你摸2X张牌（X为你当前攻击范围）",
	[":moxing"]                         = "当你受到伤害时，你可以对伤害来源使用一张【杀】，若如此做，伤害来源的技能直到你的回合结束前无效。",
	[":xiangrui"]                       = "每当你受到伤害时，你可以进行一次判定，若结果为红色，此伤害-1，若结果为黑色，你可以弃置一张牌对一名其他角色造成一点伤害。",
	[":wnlz"]                           = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害时：若不为牌造成的伤害或为【阵前嘴炮】，此伤害-2；若为【杀】造成的伤害，此伤害+1。",
	[":hxss"]                           = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以把一张基本牌当【阵前嘴炮】使用（无距离限制）。当你使用【阵前嘴炮】，若你赢时，目标角色所有技能无效直到你的回合开始。",
	[":Luachuyi"]                       = "你可以将一张装备牌当【桃】使用",
	[":Lualianji"]                      = "当你使用【杀】时，你可以摸一张牌，然后可以使用一张锦囊牌或者装备牌。",
	[":kbyxt"]                          = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌扣置于武将牌上，称为“变”。每名其他角色的回合限一次，你可以将一张“变”当做一张基本牌使用或打出。准备阶段开始时，你获得你武将牌上的“变”",
	[":kznw"]                           = "当你于回合外获得牌时，你可以将其中至少一张牌扣置于武将牌上，称为“变”。",
	[":geass"]                          = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名装备区有牌的其他角色的手牌，并选择其中一张牌使用，若此牌能指定其他角色为目标，则你可以选择一名任意角色成为此牌目标。",
	[":znai"]                           = "每名角色的回合限一次，当一名其他角色失去其最后一张手牌时，你可以令其获得场上一张装备牌或摸两张牌。",
	[":changedfate"]                    = "一名角色判定阶段开始时，若其判定区内有牌，你可以令此阶段内该角色的判定牌不能被更改且效果反转。",
	--[":lsmz"] = "回合开始阶段，你可以弃置一张黑色手牌，令你的体力值回复至体力上限。",
	[":lsmz"]                           = "<font color=\"red\"><b>限定技，</b></font><font color=\"blue\"><b>锁定技，</b></font>你的回合开始时，你回复体力值至体力上限，且本回合：{你跳过判定阶段；摸牌阶段，你多摸X张牌。}（X为4-你体力上限。）",
	[":tmsp"]                           = "你的回合开始时，你可以减一体力上限，重置“零时谜子”，若如此做，你于本回合使用【杀】的次数上限+X（X为你发动过此技能的次数）。",
	--[":bhjz"] = "锁定技，你受到的火焰伤害至多为1。",
	[":wangzbk"]                        = "每回合限一次，当其他角色的装备置入弃牌堆时，你可以获得之。",
	[":bings"]                          = "当你受到伤害时，你可以弃置一张手牌里的装备牌令此伤害-1；当你于出牌阶段造成伤害时，你可以弃置一张装备牌令此伤害+1。",
	[":guailj"]                         = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令所有其他角色依次选择一项：1.弃置装备区中的防具牌；2.受到你造成的1点伤害。",
	[":zhou"]                           = "<font color=\"blue\"><b>锁定技，</b></font>其他角色与你距离+X（奇数轮时，X为你的体力值；偶数轮时，X为你已损失的体力值）。",
	[":ye"]                             = "觉醒技，准备阶段，若你的体力值为全场最低（或之一），你减少一点体力上限并回复一点体力并获得技能“鬼缠”。",
	[":guichan"]                        = "当其他角色进入濒死状态时，你可获得其一张牌；其他角色死亡时，你摸一张牌。",
	[":dafan"]                          = "当你受到【杀】伤害时，你可以令伤害来源与你同时交给对方一张手牌，若双方因此获得【基本牌】则双方各失去一点体力；若一方因此获得【锦囊牌】双方将手牌弃置至一张；若一方因此获得【杀】则此伤害无效；",
	[":juej"]                           = "准备阶段开始，当你体力值或手牌数为1时，减少一点体力上限并回复一点体力，选择：1，所有其他角色失去一点体力；2所有其他角色将手牌弃置至1；然后获得技能“圣母圣咏”。（当你使用【杀】或【决斗】对其他角色造成伤害时，你可以弃置一张牌，然后若你：1.有手牌，此伤害+1；2.没有手牌，此伤害+2。）",
	[":smsy"]                           = "当你使用【杀】或【决斗】对其他角色造成伤害时，你可以弃置一张牌，然后若你：1.有手牌，此伤害+1；2.没有手牌，此伤害+2。",
	[":jiewq"]                          = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以失去任意点体力，本回合中你使用的下一张杀伤害增加x（x为你以此法失去的体力值）。",
	[":saiya"]                          = "<font color=\"blue\"><b>锁定技，</b></font>当你脱离濒死状态时，你增加两点体力上限，并回复一点体力",
	[":gbg"]                            = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以失去任意点体力，本回合中你使用的下一张杀伤害增加1。",
	[":zizai"]                          = "<font color=\"blue\"><b>锁定技，</b></font>当你脱离濒死状态时，你回复至体力上限，第四次脱离濒死状态后，你对其他角色造成的伤害+1，且增加一点体力上限",
	[":bczzr"]                          = "<font color=\"blue\"><b>锁定技，</b></font>若你本回合内未使用过闪，则你无法成为锦囊牌的目标。",
	[":mozy"]                           = "结束阶段开始时，你可以弃置一张牌选择一名角色并根据此牌颜色执行效果：红色，该角色回复1点体力；黑色，该角色不能使用【桃】直到其回合结束。",
	[":qsas"]                           = "出牌阶段，你可以弃置一张锦囊牌并指定一名其他角色。若如此做，直到你的下个回合开始，其每受到一点伤害，你摸一张牌；其每回复一点体力，你须弃置其一张牌。",
	[":zsmy"]                           = "<font color=\"red\"><b>限定技，</b></font>当你对体力值不大于2的角色造成伤害时，你可以翻开牌顶上的一张牌，若此牌不为【杀】，则此伤害+X（X为死亡角色数量，且最少为1）。若你以此法杀死一名角色，你可额外发动一次此技能。",
	[":nirendao"]                       = "<font color=\"blue\"><b>锁定技，</b></font>你的杀伤害+1，若此杀伤害不小于目标当前体力，则此杀无效。",
	[":nidaoren"]                       = "<font color=\"red\"><b>限定技，</b></font>出牌阶段你可以失去任意点体力，然后你摸3x张牌然后本回合内你计算与其他角色的距离时-X。（x为以此法失去的体力）",
	[":badaozhai"]                      = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令所有体力值低于x的其他角色，进入濒死状态。（x为你已损失体力）",
	[":feils"]                          = "<font color=\"blue\"><b>锁定技，</b></font>当你体力大于等于你手牌时，你与其他角色计算距离时-2；反之其他角色与你计算距离时+2",
	[":jssg"]                           = "觉醒技，准备阶段开始时，若你的体力值为全场最低（或之一），你须回复1点体力，减少一点体力上限并获得技能“飞雷神二段”。（<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以视为对一名其他角色使用了一张杀（不计入出牌阶段使用次数），若如此做，直到该角色下个结束阶段开始时，其无视与你的距离。）",
	[":feils2"]                         = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以视为对一名其他角色使用了一张杀（不计入出牌阶段使用次数），若如此做，直到该角色下个结束阶段开始时，其无视与你的距离。",
	[":kuixin"]                         = "结束阶段，你可以选择一项：1.观看一名其他角色的手牌；2.观看牌堆顶的3张牌。然后若你的手牌数不大于你所观看牌的数量，你可以获得其中一张牌。",
	[":jiushu"]                         = "当一名其他角色进入濒死状态时，你可以摸一张牌，然后你可以弃置两张相同花色或种类的手牌，令其回复1点体力。",
	[":xieheng"]                        = "当你受到一次伤害时，你可以选择一名角色并选择一项：1.令其摸一张牌；2.你弃置一张红色牌，然后其回复1点体力。",
	[":tjdzf"]                          = "每当你受到一点伤害时，你可以防止此次伤害并将牌堆顶的一张牌置于你的武将牌上，称为“音符”。回合结束阶段开始时，你失去等同于“音符”数量的体力然后获得所有的“音符”。",
	[":qrdag"]                          = "出牌阶段你使用的第一张【杀】可以无视距离的指定x名角色为目标（x为“音符”的数量），每当该【杀】造成1点伤害，你可以回复1点体力或弃置一张“音符”。",
	[":fenmao"]                         = "准备阶段开始时，你可以弃置一张手牌并进行一次判定，你获得相应的技能直到回合结束。红色：【常规】（<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看牌堆顶的3张牌，你获得其中一张牌然后将剩余的牌以任意顺序置于牌堆顶。）；黑色：【黑化】（出牌阶段限一次，你可以观看一名任意角色的手牌，然后你展示并获得其中的一张基本牌。）",
	[":changgui"]                       = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看牌堆顶的3张牌，你获得其中一张牌然后将剩余的牌以任意顺序置于牌堆顶。",
	[":heihua"]                         = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名任意角色的手牌，然后你展示并获得其中的一张基本牌。",
	[":samsara"]                        = "结束阶段，你可以将X张手牌当做你本回合出牌阶段内使用的第X张基本牌或通常锦囊使用，然后你可以重复此流程。若你以此法使用了不少于两张牌，则你于此回合结束后获得一个额外回合。（X为你于此阶段已发动本技能的次数＋１。）",
	[":zuihoudefanji"]                  = "觉醒技，当你处于濒死状态时，你明置你的身份牌，若如此做，你将体力回复至3，然后将副武将牌更换为“羽入”",
	[":businiao"]                       = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害时，你进行一次判定，若结果为红桃则防止此伤害，否则获得其伤害来源的一张手牌。",
	[":zhanxianfanyu"]                  = "你可以跳过摸牌阶段或出牌阶段并选择一名角色获得“防御”标记，直到你的下个回合开始，当目标受到【杀】的伤害时，你可以防止此伤害，并视为对伤害来源使用了一张【决斗】",
	[":jixieshenslash"]                 = "当你使用一张【杀】时，你可改为对目标造成一点火焰伤害。",
	[":jixieshendefense"]               = "<font color=\"blue\"><b>锁定技，</b></font>你无视所有的属性伤害，并且你可以弃置一张牌，然后摸一张牌。",
	[":jixieshenchain"]                 = "你可以将你的红色手牌视为【杀】，黑色手牌视为【闪】。",
	[":jixieshen"]                      = "回合开始时，你可以选择三台不同的机体进行驾驶，每台机体具有耐久值，当耐久值下降为零点时便无法驾驶，同时可以更换为其他拥有耐久值的机体。三台机体分别为：革命机，你的所有【杀】可以直接目标造成火焰伤害。拂晓，无视所有的属性伤害。高文，你的红色手牌可视为【杀】，黑色手牌可视为【闪】。",
	[":jixieshen0"]                     = "回合开始时，你可以选择三台不同的机体进行驾驶，每台机体具有耐久值，当耐久值下降为零点时便无法驾驶，同时可以更换为其他拥有耐久值的机体。三台机体分别为：革命机，你的所有【杀】可以直接目标造成火焰伤害。拂晓，无视所有的属性伤害。高文，你的红色手牌可视为【杀】，黑色手牌可视为【闪】。",
	[":jixieshen1"]                     = "回合开始时，你可以选择三台不同的机体进行驾驶，每台机体具有耐久值，当耐久值下降为零点时便无法驾驶，同时可以更换为其他拥有耐久值的机体。三台机体分别为：革命机，你的所有【杀】可以直接目标造成火焰伤害。拂晓，无视所有的属性伤害。高文，你的红色手牌可视为【杀】，黑色手牌可视为【闪】。<br><font color=\"red\"><b>革命机耐久值:</b> %arg1 <b>拂晓耐久值:</b> %arg2 <b>高文耐久值:</b> %arg3 <b>斯洛卡伊生命值:</b> %arg4</font>",
	[":loyal_inu"]                      = "<font color=\"red\"><b>限定技</b></font>，准备阶段，你可以选择一名其他角色，其获得“忠”标记。<font color=\"blue\"><b>锁定技</b></font>，有“忠”标记角色受到大于1的伤害时，你承受多余的伤害。",
	[":DSTP"]                           = "<font color=\"blue\"><b>锁定技</b></font>，当你受到伤害时，若此伤害大于1，则防止多余的伤害；若“忠”角色死亡，免疫【决斗】伤害。",
	[":kikann"]                         = "“忠”角色准备阶段开始时，其可选择：1将体力值调整至于你相同：2将手牌数调整至于你相同。每个选项限一次且全部选择后重置，“忠”角色死亡后，失去此技能。",
	[":guangzijupao"]                   = "<font color=\"green\"><b>阶段技，</b></font>你可以弃置一张牌并展示攻击范围内的一名其他角色的一张牌，然后选择一项：弃置此牌，或视为你对其使用不计入限制的雷【杀】。",
	[":kuanghua"]                       = "<font color=\"blue\"><b>锁定技，转换技，</b></font>准备阶段，①“狂化”：你的“蓝羽”数大于你的体力值，进入“狂化”状态，失去“光子巨炮”并获得“绝对压制”。②“冷静”：你的“蓝羽”数不大于你的体力值，退出“狂化”状态，失去“绝对压制”并获得“光子巨炮”。",
	[":lanyuhua"]                       = "<font color=\"blue\"><b>锁定技，</b></font>当你受到或造成伤害后，你获得一枚“蓝羽”标记，非“狂化”状态下攻击范围+X，“狂化”状态下的出牌阶段可使用【杀】数量+X。（X为你“蓝羽”数）",
	[":baozou"]                         = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始时，若你的“蓝羽”标记数大于你的体力值，你加一点体力上限并回复一点体力，去除“蓝羽化”中攻击范围加成，然后失去技能“光子巨炮”并获得技能“绝对压制”。",
	[":jueduiyazhi"]                    = "<font color=\"green\"><b>阶段技，</b></font>你可以选择任意其他角色并弃置等量的“蓝羽”标记获得以下效果直到回合结束：其于此回合内不能使用或打出手牌，且当你对这些角色造成伤害后，你须选择：弃置两枚“蓝羽”标记，或失去一点体力；然后获得其一张牌。",
	--	[":jinhua"] = "锁定技。摸牌阶段，你固定摸x张牌（x为你的当前回合数，且至多为体力上限。）。",
	[":Luayumian"]                      = "<font color=\"blue\"><b>锁定技，</b></font>当你进入濒死状态时，你须展示牌堆顶的一张牌，若为锦囊牌，则你弃置这张牌，回复至1点体力，否则你获得之。",
	[":jinhua"]                         = "当一名其他角色死亡时，若你的“进化”标记小于你的体力上限，你摸两张牌，回复一点体力并获得一枚“进化”标记",
	[":wuduan"]                         = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段，若你“进化”标记不小于你的当前体力，你须失去一点体力并获得技能“提升”。",
	[":tisheng"]                        = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段，你失去一点体力并多摸X张牌（X为进化数量且不大于你的体力上限）",
	[":Luayanhu"]                       = "当一名距离1以内的其他角色受到伤害时，你可以将此伤害转移给你。",
	[":xinsuo"]                         = "一名角色的结束阶段，你可标记其身份或更改其身份标记。当其死亡时，若其身份与此标记相同，你摸两张牌。",
	[":yohane"]                         = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可获得任意名身份标记互不相同的角色区域内各两张牌，然后依次将两张牌置于其区域内。",
	[":fengfu"]                         = "<font color=\"blue\"><b>锁定技，</b></font>当一名角色使用【杀】指定目标后，若其身份标记与目标相同，其须弃置一张黑色手牌否则此牌无效；若身份标记不同，其摸两张牌然后弃置两张手牌。",
	[":mingchuan"]                      = "<font color=\"blue\"><b>锁定技，</b></font>你的牌均视为黑桃6。",
	[":fanyi"]                          = "准备阶段，你可以观看牌堆顶的四张牌，令下列任意项数值+1，等量项数值-1直到回合结束：1.攻击范围；2.手牌上限；3.使用【杀】的次数上限；4.首次使用【杀】或普通锦囊的目标数上限；5.摸牌阶段摸牌数。",
	[":jihang"]                         = "当你于回合外失去牌前，你可以展示一张手牌并选择一名其他角色，你展示其一张手牌，若两牌点数之差小于4，防止你失去这些牌且你回合开始前不得再因“疾航”展示其手牌",
	[":jiaoxing"]                       = "每当你的红桃或方块A~5的牌因弃置而置入弃牌堆时，你可将之当【乐不思蜀】使用；当一张延时锦囊牌生效时，你可将此牌效果改为【兵粮寸断】或【乐不思蜀】。 ",
	[":anni"]                           = "当一名角色使用红桃或梅花【杀】指定目标后，你可令除目标以外的一名角色预测此【杀】是否造成伤害。此牌结算后，若相符则你摸一张牌，否则其弃置你一张手牌。",
	[":lianjiqudong"]                   = "<font color=\"blue\"><b>锁定技，</b></font>当你于出牌阶段使用非装备牌结算完毕时，若之造成过伤害，你获得一枚“连击”标记，否则你弃所有“连击”标记；<font color=\"blue\"><b>锁定技，</b></font>你使用【杀】造成的伤害+1.5X（X为你“连击”标记的数量）；<font color=\"blue\"><b>锁定技，</b></font>回合结束时，你弃所有“连击”标记。",
	[":moyu"]                           = "出牌阶段结束时，若你本回合已使用的牌数不大于你当前的体力值，你可以摸一张牌。",
	[":sandun"]                         = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害后，若你的装备区里：有牌，你摸一张牌；没有牌，你弃置所有手牌，然后选择获得弃牌堆里的一张黑色装备牌并使用之，或你视为对一名角色使用【杀】。",
	[":xieyan"]                         = "出牌阶段，你可以展示一张不为装备牌的手牌，然后将牌堆顶的一张牌视为该手牌使用，此牌结算后，目标角色与你于此阶段内不能使用与你以此法使用的牌的类型相同的牌。每回合每种类型的牌限展示一次。",
	[":chibing"]                        = "<font color=\"blue\"><b>锁定技，</b></font>每当你回复1点体力后，你摸一张牌，视为你执行了【酒】的效果①。",
	[":sugong"]                         = "第一轮开始时或牌堆切洗后的第一个回合开始前，你可摸一张牌并选择：失去一点体力摸一张牌或回复一点体力，选择后进行一个额外的回合。",
	[":fuqian"]                         = "每回合限两次，当你失去牌时，你可将之面朝上置于牌堆顶第X张牌 之上（X为此牌点数，若牌堆不足则改为1）。当一名角色获得此牌后，你弃置其两张牌，然后此牌失去此效果。",
	[":huanggui"]                       = "当你成为牌的目标时，你可令攻击范围内有你且区域内总牌数为 3  的一名角色摸一张牌，然后转移此牌给其。",
	[":htms_wanlan"]                    = "摸牌阶段结束时，你可令一名其他角色与你同时弃置任意张牌，若你弃置的牌点数总和较大，你对其造成1点伤害，若你弃置的牌点数总和较小，则其可以摸一张牌或获得一张其以此法弃置的牌。",
	[":tianqu"]                         = "当你受到普通【杀】的伤害后，你可将所有手牌（至少1）放置武将牌上，称为雨，并选择两名其他角色交换手牌。雨会因为你的回合开始，置于手牌区域并令你回复一点体力。",
	[":haiyin"]                         = "<font color=\"blue\"><b>锁定技，</b></font>当你失去牌时：若你没有“韵”，你将你失去的牌当中的一张牌置于武将牌上，称为“韵”；若你已有“韵”且你失去的牌当中的一张牌与“韵”的花色形成下列关系，你将此牌作为“韵”并弃置旧“韵”，然后摸一张牌（黑桃→红桃→梅花→方块→黑桃......箭号左方为“韵”的花色，右方为你失去的牌的花色）。",
	[":fuzou"]                          = "当一名角色成为锦囊牌的目标时，你可弃置“韵”，令其所有非红桃手牌均视为【无懈可击】直到回合结束。",
	[":zangsong"]                       = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示一名角色的一张手牌：若该牌为<font color=\"red\">♥</font>，视为你对其使用一张【杀】；若不为<font color=\"red\">♥</font>，你摸一张牌。",
	[":jianwushu"]                      = "当你使用【杀】指定一名角色后，若你装备了武器牌，你可以弃置目标角色一张牌；当你成为一名角色【杀】的目标后，若你没有装备武器牌，你可以弃置其一张牌。",
	[":jichengzhe"]                     = "<font color=\"purple\"><b>觉醒技，</b></font>当你处于濒死状态时，回复一点体力，获得技能“火力全开”，当你死亡时，将武将变更为瓦沙克。",
	[":huoliquankai"]                   = "准备阶段，你可弃置全部区域的牌，对一名角色造成一点伤害然后摸一张牌。",
	[":Cjiyongbing"]                    = "<font color=\"blue\"><b>锁定技，</b></font>若你不为主公，你的身份初始为内奸，若主公阵营女性较多，则变更身份为忠臣；若反贼阵营女性较多，则变更身份为反贼。",
	[":juexingmoshen"]                  = "当你造成伤害时，你可以进行一次判定，若为黑桃，对一名角色造成一点伤害，若为梅花：摸一张牌，若为红桃则恢复一点体力值，若为方块增加一点体力上限。",
	[":fengshou"]                       = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，你为以下属性分配总计X点属性：初始额外摸牌数*1.5，手牌上限2.5。（X为存活角色数）",
	[":haite"]                          = "结束阶段，若本回合内洗过牌，你可以对任意名其他角色各造成1点伤害。",
	[":yueying"]                        = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置至少一张牌，若如此做，你摸等量的牌；若你以此法其弃置了所有手牌，你额外摸一张牌且本回合手牌上限+1。",
	["hmrleijiSlash"]                   = "杀",
	[":hmrleiji"]                       = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害时，若伤害牌牌名，你未记录，则此伤害+1，记录此牌名；若伤害牌名已记录，则，此伤害-1，删除记录并回复一点体力。",
	[":hmrleiji1"]                      = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害时，若伤害牌牌名，你未记录，则此伤害+1，记录此牌名；若伤害牌名已记录，则，此伤害-1，删除记录并回复一点体力。",
	[":hmrleiji11"]                     = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害时，若伤害牌牌名，你未记录，则此伤害+1，记录此牌名；若伤害牌名已记录，则，此伤害-1，删除记录并回复一点体力。\
				<font color=\"red\"><b>已记录：%arg11</b></font>",
	[":jiyidiejia"]                     = "当你使用牌造成伤害时，若已记录此牌名，则你可删除此牌名记录，令此伤害+1，若未记录，则你可记录此牌名，此次伤害-1",
	--[":dushe"] = "一名角色回合开始时，你可以令其进行一次判定，且你可使用一张基本牌，若判定结果与此牌花色相同，其须将所有牌调整至与体力值相同。",
	[":dushe"]                          = "一名角色的判定牌生效时，你可以将其花色改为无花色并令其获得此牌。",
	[":myjl"]                           = "<font color=\"blue\"><b>锁定技，</b></font>你的装备牌均视为黑桃花色；一名角色的黑桃判定牌生效后，你摸一张牌",
	[":zuzhou"]                         = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以失去【命运记录】并令一名其他角色进行一次判定：若花色不为红色，对其造成2点伤害。",
	[":zhiyujz"]                        = "<font color=\"blue\"><b>锁定技，</b></font>当你令已受伤角色回复目标体力时，可超过其体力上限",
	[":zhiyujz_jz"]                     = "<font color=\"blue\"><b>锁定技，</b></font>当你令已受伤角色回复目标体力时，可超过其体力上限。你无法被跳过出牌阶段",
	[":zhiyujz_jx"]                     = "<font color=\"blue\"><b>锁定技，</b></font>你令角色回复体力时，其体力上限视为其原来2倍 。你无法被跳过出牌阶段",
	[":shengdanny"]                     = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可弃置一张牌，对一名角色造成一点火属性伤害，并回复其两点体力",
	[":jujiman"]                        = "出牌阶段开始时，你可结束出牌阶段，若你直到下个回合准备阶段开始时未受到伤害，则你可对一名其他角色造成两点伤害。",
	[":yinbiman"]                       = "结束阶段，你可失去一点体力，则直到下个回合开始，当你成为牌的目标时，你须进行一次判定，若为黑色，则此牌无效",
	[":suoersiman"]                     = "<font color=\"red\"><b>限定技，</b></font>出牌阶段开始时，你可弃置所有牌并回复一点体力。若如此做，你可以进行一次判定：若为基本牌则你获得之，否则你视为对一名其他角色使用一张杀，重复此效果，共x次。（X为以此法弃置的牌数）",
	[":leijijingyan"]                   = "回合结束时，若你本回合使用了X种不同花色的牌时，你获得一枚（经验）X为经验数且至少为一。<br/>经验：当你使用桃时，回复量+X（X为此标记数量）",
	[":xiangyangshi"]                   = "弃牌阶段结束时，你可以选择至多X名角色，这些角色各回复1点体力（X为你于此阶段内弃置牌的数量）。",
	[":mingduan"]                       = "当一名角色受到普通伤害时，你可一名角色获得一枚标记；若下次受到受到普通伤害的角色为该标记角色，则你摸一张牌；若你本回合以此发摸过牌，则改为你令一名角色观看牌顶的一张牌，且可用一张手牌替换",
	[":yushicp"]                        = "出牌阶段，当你需要使用一张非装备（非延时）牌时，你可弃置一张牌，观看一名角色的手牌，获得一张你需要的牌。每回合每名角色限一次。",
	[":wushitexing"]                    = "当你使用南蛮入侵，万箭齐发，杀时，你可改为对目标造成一点伤害。",
	[":meipengyou"]                     = "<font color=\"blue\"><b>锁定技，</b></font>你的防御距离+1，进攻距离-1。",
	[":shanyao"]                        = "当你使用红色【杀】被【闪】抵消时，你可摸一张牌，视为对其使用一张【杀】。",
	[":jiansu"]                         = "其他角色结束阶段开始时，你可指定一名其他角色，当前回合角色与你均可对该角色使用一张【杀】，若【杀】造成伤害，则你与当前回合角色各摸一张牌。",
	[":yugao"]                          = "<font color=\"green\"><b>出牌阶段限两次，</b></font>你可观看一名其他角色的手牌，然后你弃置一枚标记，并指定其一张手牌为预告牌。<br/><b>游戏开始时，你获得7枚“预”标记。你可白嫖一次预告</b></font>",
	[":guaidao"]                        = "出牌阶段开始时，你获得预告牌；出牌阶段结束时，若预告牌仍在你的手牌中且你是从其他角色处获得预告牌的，则将该牌交给该角色。",
	[":weituo"]                         = "当一名其他角色受到伤害时，你可展示牌顶一张牌，令其选择，1，获得此牌，成为<b><font color=\"red\">委托者</b></font>伤害来源成为<b><font color=\"blue\">流放者</b></font>；2,令你获得此牌。<br/><br/><br/><br/><b><font color=\"red\">委托者</b></font>与<b><font color=\"blue\">流放者</b></font>同时只能存在各一个，且不能互为自己或是阎魔爱，<b><font color=\"blue\">流放者</b></font>死亡后，移除双方标记",
	[":liufang"]                        = "<font color=\"blue\"><b>锁定技，</b></font><b><font color=\"blue\">流放者</b></font>准备阶段开始时，其失去X点体力，（X为委托者已损失体力），若流放者体力为1，<b><font color=\"red\">委托者</b></font>须将武将牌翻面。",
	[":yuanhuo"]                        = "<font color=\"blue\"><b>锁定技，</b></font>当你死亡时，对所有其他角色造成一点火焰伤害。",
	[":zhengdao"]                       = "当你使用红桃或黑桃牌时（非延时锦囊牌），你可将此牌与一名其他角色拼点：若你没赢，则此牌无效且下次此技能修改为若你赢，则此牌无效。",
	[":zhihouz"]                        = "一名角色回合结束时，若你于此回合未使用或打出基本牌，且你有过此机会，你可令一名体力不小于你的角色交给你一张手牌。",
	[":jiqiangs"]                       = "当你使用【杀】结算后，你可弃置一枚“蓝羽”，视为对目标使用一张【杀】",
	[":lanyushanbi"]                    = "当你使用或打出【闪】时，你获得一枚“蓝羽”标记，若你已受伤，额外获得一枚“蓝羽”标记",
	[":jibanhy"]                        = "所有其他角色的<font color=\"green\"><b>出牌阶段限一次，</b></font>可令你摸一张牌并依次使用两张牌。",
	[":chenmohy"]                       = "<font color=\"blue\"><b>锁定技，</b></font>你始终跳过出牌阶段，且展示你的身份。",
	[":nvzidao"]                        = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段结束时，若你本回合出牌阶段使用牌的点数和：小于25，你摸一张牌；等于25，你观看一名其他角色的手牌并获得其中一张牌，若此做，则你可移动场上一张牌；大于25，你展示全部手牌",
	[":chuanxiao"]                      = "当你受到伤害时，若伤害来源没有【微笑】技能，你可令其获得【微笑】，并防止此伤害。（微笑：<font color=\"blue\"><b>锁定技，</b></font>结束阶段结束时，若你本回合出牌阶段使用牌的点数和等于25，你观看一名其他角色的手牌并获得其中一张牌，并失去此技能）。",
	[":weixiaojn"]                      = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段结束时，若你本回合出牌阶段使用牌的点数和等于25，你观看一名其他角色的手牌并获得其中一张牌，并失去此技能。",
	[":yijizho"]                        = "<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】指定目标时，目标须使用X张【闪】抵消（X为你攻击范围）",
	[":htms_fengyu"]                    = "结束阶段开始时，你可将牌顶两张牌明置于武将牌上，若有于此牌牌名相同的牌使用或打出，则你摸一张牌；回合开始时，弃置此牌。",
	[":wujinzhishu"]                    = "当你使用牌后，若你的武将牌上没有同名牌，你可以将其盖伏在武将牌上，称为“页”。（使用【春日记录】后本回合此技能无效。）",
	[":chunrijilu"]                     = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可弃置一张手牌使用一张“页”，若该牌效果使场上角色体力值发生变化，你须弃置X张页，不足则失去等量体力（X为场上因此牌角色体力变化值总数）",
	[":duandai"]                        = "<font color=\"green\"><b>出牌阶段每个区域限一次，</b></font>你可以令一名角色选择其任一有牌区域，你弃置其选择区域内的一张牌，然后你选择一项，1.弃置一张相同颜色的牌2.令目标摸一张牌；当你弃置的牌与出牌阶段内弃置的牌花色相同/不同时，你使用【杀】无次数/距离限制。",
	[":tucao"]                          = "每回合限一次，你可将一张基本牌视为【无懈可击】使用；并选择：1，摸一张牌；2，弃置场上一张牌。",
	[":wangwei"]                        = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可弃置任意张颜色相同的手牌并选择等量角色，令其摸牌阶段摸牌数+1（至多因此+1），直到你受到不小于两点伤害或进入濒死状态。",
	[":qiyuan"]                         = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以重置“祈祷”次数。出牌阶段结束时，若你未使用此技能，你可令一名手牌上限小于4的角色获得一枚 “愿”的标记。拥有“愿”标记角色，手牌上限+X。（X为愿的标记）",
	[":qidao"]                          = "<font color=\"green\"><b>每轮限一次，</b></font>当一名角色除摸牌阶段外获得牌时，你可以令其改为摸X张牌或改为弃置一张牌。（X为你已经损失的体力值）",
	[":LuaLeishi"]                      = "每回合限一次，你可以将一张手牌当作雷【杀】使用或打出。",
	[":Luayuanxing"]                    = "<font color=\"red\"><b>限定技，</b></font>你可以令你此次造成的雷属性伤害+1。",
	[":Luayuanling"]                    = "出牌阶段结束时，你可横置X名角色（X为本阶段你造成的雷属性伤害数且至少为1）。",
	[":Luashenyi"]                      = "当你受到伤害后，你可以于此阶段结束时令一名角色执行一个额外的出牌阶段。 ",
	[":luakuaiqing"]                    = "出牌阶段，你可以弃X+1张牌并摸1张牌，且本回合所有角色不能使用、打出或弃置与你弃置牌同名的牌（X为本回合你发动“快晴”的次数）。",
	[":luajiejie"]                      = "<font color=\"green\"><b>出牌阶段限两次，</b></font>当你使用【杀】或【决斗】对目标角色造成一点伤害时，你可展示该角色手牌，并获得其中一张。",
	[":luajieao"]                       = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以和一名其他角色拼点，若你赢，你对其造成一点伤害；若你没赢，视为其对你使用了一张方块【杀】。",
	[":luajinlun"]                      = "你受到伤害的结束阶段，你可以令一名角色弃置所有手牌并执行一个<font color=\"#ff5a00\"><b><u>易逝</u></b></font>回合。<br/><br/><br/>*<font color=\"#ff5a00\"><b><u>易逝</u></b></font>状态下，无法再次获得<font color=\"#ff5a00\"><b><u>易逝</u></b></font>BUFF且回合结束时失去。",
	[":empaidui"]                       = "准备阶段，你可令至多X名角色各摸一张牌，此回合内当你使用【杀】时，其额外成为目标且无法使用闪（X为已损失体力值+1）。",
	[":yftuji"]                         = "当其他角色受到伤害时，你可令受伤角色对你造成一点伤害，此回合结束后，你进行一个<font color=\"#ff5a00\"><b><u>易逝</u></b></font>回合。<br/><br/><br/>*<font color=\"#ff5a00\"><b><u>易逝</u></b></font>状态下，无法再次获得<font color=\"#ff5a00\"><b><u>易逝</u></b></font>BUFF且回合结束时失去。",
	[":zhongerhx"]                      = "当你受到伤害后，你可展示牌顶两张牌，并使用或弃置这些牌。",
	[":hanrenzd"]                       = "当你使用【杀】造成伤害时，你可弃置目标装备区内的武器牌且其手牌上限-1直到你的回合开始。",
	[":bingfengzd"]                     = "当你受到牌的伤害时，你观看伤害来源手牌并获得其中全部锦囊牌。",
	[":hezibz"]                         = "出牌阶段当你使用牌结算后若造成伤害，你对所有角色造成一点伤害或回复一点体力。",
	[":shayiqr"]                        = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段，若你于出牌阶段内未：1，造成伤害；2，使用非装备牌。每满足一项失去一点体力。两项未满足，则增加一点体力上限；两项满足则改为失去一点体力上限。 ",
	["shayish"]                         = "杀意浸染:造成伤害",
	["shayicard"]                       = "杀意浸染:使用非装备牌",
	[":duancai"]                        = "其他角色使用点数大于7的牌时，你可弃置一张点数小于7的手牌，对其造成一点伤害。",
	[":midie"]                          = "<font color=\"red\"><b>限定技，</b></font>当你进入濒死状态时，你可增加两点体力上限并回复至3点体力，并将断裁修改为（出牌阶段，其他角色失去小于7点的牌时，你可弃置一张点数大于7的牌，对其造成一点伤害。）",
	[":duancaiex"]                      = "出牌阶段，其他角色失去小于7点的牌时，你可弃置一张点数大于7的手牌，对其造成一点伤害。",
	[":tongzhouqg"]                     = "摸牌阶段开始时，你可额外摸X张牌，然后依次交给其他所有角色各一张牌。（X为存活的角色数）",
	[":qgjiesi"]                        = "弃牌阶段结束时，你可以选择至多X名角色，令这些角色各弃置一张牌（X为你于此阶段内弃置牌的数量，若你于出牌阶段回复过体力则本次改为其弃置两张牌）。",
	[":zjyizhen"]                       = "出牌阶段，你可选择一名其他角色并弃置X张牌，令其回复一点体力（X为其已损失体力值）。",
	[":zjmoshuxif"]                     = "当你需要使用或打出【闪】时，你可摸一张牌并弃置一张牌，若因此弃置牌为装备牌或普通锦囊牌时，你视为使用或打出一张【闪】。",
	[":zjruoshi"]                       = "准备阶段开始，你可选择一种颜色，并进行判定，若颜色相同，则你获得此牌且此牌颜色相同并继续进行判定，直到颜色不同。",
	[":zjaojiaol"]                      = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可令一名其他角色选择一种颜色，观看并弃置你一张手牌，若颜色相同，则红色：其回复一点体力；黑色，其摸两张牌。",
	[":qianjinzj"]                      = "准备阶段或结束阶段开始时，你可将手牌摸至手牌数最高的其他角色。",
	[":bieniu"]                         = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段内，你不能使用与本阶段上一张颜色相同的牌。",
	[":puzou"]                          = "出牌阶段结束时，若此阶段进入弃牌堆的牌花色均不同或颜色均相同，你可令所有角色，失去一点体力或回复一点体力。",
	[":htms_weiyi"]                     = "当你受到伤害时，你可选择：令伤害来源弃置X张牌或对伤害来源造成X-1点伤害（X为你此次伤害点数，若与上次不同则数值+1并重置）。",
	[":mingmendia"]                     = "准备阶段，你可获得至多两名其他角色各一张牌，并交给其各一张牌；若交给的两张牌：点数相同：你回复一点体力。花色不相同：你失去一点体力。",
	[":luatiaobo"]                      = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以和一名其他角色拼点：若你赢，其视为对你指定的一名角色使用了一张【杀】。若你没赢，其可以视为对你使用了一张【杀】。",
	[":luanizhuan"]                     = "当你成为【杀】的目标后，你可以摸一张牌，然后若你的手牌数比其多，你将此【杀】改为【决斗】。",
	[":lualushou"]                      = "当你使用【杀】后，你可以弃置一张：①基本牌：此【杀】不可被闪避；②锦囊牌；你摸一张牌，然后此【杀】额外指定一个目标；③装备牌：此【杀】若造成伤害，你回复等量的体力。",
	[":luanyanguang"]                   = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以流失一点体力，视为你对一名其他角色使用了一张【杀】。",
	[":huazang"]                        = "当你使用【杀】指定目标时，你可令其武将牌翻面并摸X张牌（X为其已损失体力），若其因此杀受到伤害，其武将牌翻面。",
	[":zchize"]                         = "出牌阶段，你可与一名其他角色进行拼点，若你赢，则你弃置目标非手牌区域内一张牌；若你未赢，结束此回合。",
	[":gaoling"]                        = "当你成为其他角色锦囊牌目标时，若其手牌数小于等于你，则你可令此牌无效。",
	[":huidang"]                        = "<font color=\"blue\"><b>锁定技，</b></font>当你将要死亡时，其他角色依次弃置装备区里一张牌。当一张牌移动后，若你死亡且场上没有装备牌，你将所有角色体力及体力上限调整至初值，并重置场上的<font color=\"red\"><b>限定技，</b></font><font color=\"purple\"><b>觉醒技</b></font>。",
	[":zhengjiu"]                       = "准备阶段开始时，你可以选择一名其他角色（其他人未知），直到你下回合开始前，其成为杀或单体锦囊的目标时，你可以观看牌堆顶3张牌，令其获得一张牌，其余牌以任意顺序置于牌堆顶。若如此做，若该角色体力值在此牌结算后减少体力，则你失去一点体力。",
	[":html_shisheng"]                  = "<font color=\"red\"><b>限定技，</b></font>出牌阶段你可对一名其他角色造成一点伤害，若其因此死亡，对所有其他角色造成一点伤害。",
	[":molwf"]                          = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可弃置一张红色牌，本回合内使用【杀】造成伤害时，此伤害+1。使用五次后重置【誓胜】次数。",
	[":ujyaozhan"]                      = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可令一名其他角色对你使用一张【杀】，此杀结算后，你对其或其对你无距离限制，直到你的回合开始。",
	[":ujzhongshi"]                     = "<font color=\"purple\"><b>觉醒技，</b></font>当你使用【杀】或造成伤害总和11次时，你须失去一点体力上限修改【连击】获得【圣母圣咏】",
	[":ujlianji"]                       = "当你使用【杀】结算完毕后，你可使用一张【杀】。",
	[":ujlianjig"]                      = "<font color=\"green\"><b>出牌阶段限一次，</b></font>当你使用【杀】结算完毕后，你可使用一张牌",
	[":Sdorica_FuWei"]                  = "一名角色的判定阶段开始时，若其判定区有牌或手牌数少于你，你可选择一项：1、将一张牌置于牌堆顶；2、弃置一张牌，将其区域内的一张牌置于牌堆顶。",
	[":Sdorica_MiLing"]                 = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可令一名角色选择：1、使用一张【杀】；2、其下次指定或成为牌的目标时，取消所有目标。若目标角色不为你则其直到其回合结束手牌上限+1。",
	[":void"]                           = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名其他角色所有牌，获得其中一张牌，且其摸一张牌，且此回合结束时，若你拥有此牌，该角色获得此牌；否则该角色失去一点体力。",
	[":wangguo"]                        = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，成为过你“虚空”目标的所有角色依次选择：1，令你失去一点体力，本回合虚空次数-1，然后你视为未对其使用“虚空”；2，令你回复一点体力，本回合虚空次数+1。",
	[":lsqd"]                           = "准备阶段/结束阶段开始时，你可选择：1，弃置一张手牌使用一张弃牌堆一张武器牌；2，装备区内有牌：摸一张牌并将装备区内一张牌置于牌顶。",
	[":tscg"]                           = "<font color=\"purple\"><b>觉醒技，</b></font>当一名其他角色死亡时，你须对一名角色造成一点伤害，然后获得【武装构造】。",
	[":wzgz"]                           = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可获得一名角色装备区内一张牌，若此牌不为武器牌，则你须弃置一张手牌。",
	[":tcmfs"]                          = "锁定技，你的职业默认为【天才魔法师】：始终获得【法师】第二阶段效果。",
	[":blmf"]                           = "你可将一张基本牌视为【火攻】使用，此【火攻】基础伤害+1，此牌结算后立刻结束出牌阶段。",
	[":htms_mozhi"]                     = "出牌阶段，你可重铸X+1张不可使用的牌，然后本阶段进攻距离+1。（X为本回合你使用此技能次数）",
	[":yiban"]                          = "出牌阶段开始时，你可将任意张牌交给一名其他角色，若此做，本阶段当你使用一张基本牌或普通锦囊牌后，其可使用一张牌或交给你一张牌。",
	[":pomiehb"]                        = "结束阶段开始时，你可令一名场上手牌数最少的角色摸一张牌，若其不为你，你摸一张牌。",
	[":zhumyb"]                         = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段，当你使用牌时，若此牌比本阶段上一张牌：大，你摸一张牌；小，你失去一点体力，且本阶段此技能无效。",
	[":tonghh"]                         = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，你选择一名其他角色，当你或该角色受到伤害后，你与其各摸一张牌。",
	[":luashouhuo"]                     = "摸牌阶段，你可以少摸一张牌并令一名角色将手牌补至其手牌上限。若如此做，本回合你手牌上限改为1。",
	[":luahongyu"]                      = "弃牌阶段结束时，若你于此阶段弃置的手牌全为基本牌，你可以将这些牌分发给等量的角色。若这些牌均为红色，你回复1点体力。",
	[":pinkdevil"]                      = "结束阶段，当你于本回合出牌阶段没有使用【杀】或弃牌阶段没有弃牌，你可以视为使用一张【杀】。",
	[":khztbuff"]                       = "<font color=\"blue\"><b>锁定技，</b></font>若你已受伤且装备区无装备，你使用【杀】或【决斗】造成的伤害+1。",
	[":embers"]                         = "当你阵营角色数大于敌对阵营时，获得技能【高效治疗】；当你阵营角色数小于敌对阵营时，获得技能【审判】。<br/>（高效治疗：结束阶段，你可令一名角色下个出牌阶段开始时，弃置一枚“负伤”标记，并回复一点体力。<br/>审判：出牌阶段开始时，你可获得一枚“负伤”标记，对一名体力值最多的其他角色造成一点伤害。）",
	[":gxzhiliao"]                      = "结束阶段，你可令一名角色下个出牌阶段开始时，弃置一枚“负伤”标记，并回复一点体力。",
	[":shenpan"]                        = "出牌阶段开始时，你可获得一枚“负伤”标记，对一名体力值最多的其他角色造成一点伤害。",
	[":wugshashou"]                     = "<font color=\"blue\"><b>锁定技，</b></font>当你造成伤害时，你进行一次判定，若为判定牌为黑桃，受伤角色减少一点体力上限；若为判定牌为红桃，受伤角色失去一点体力。",
	[":nxlieren"]                       = "出牌阶段开始时，你可直接结束出牌阶段，并记录一张基本牌名，下个回合开始前，若一名角色使用或打出与你记录牌相同时，你可对其造成一点伤害令此技能无效直到你回合开始。",
	[":xibu"]                           = "<font color=\"blue\"><b>锁定技，</b></font>当你使用牌后（非无懈可击，延时锦囊牌）将此牌置于武将牌上，称为“步”且至多六张。",
	[":dalunb"]                         = "出牌阶段你可依次弃置共三张“步”，来设计一张牌。",
	[":zhanshubuju"]                    = "每回合限一次，当一名角色需要使用或打出【闪】时，你可弃置牌堆9-X张【闪】（不足则无效,X为存活角色数）视为使用或打出此牌。",
	[":zhachang"]                       = "出牌阶段，你可弃置一张【杀】，弃置牌堆一张【闪】若不足，则所有其他角色弃置区域内全部牌。",
	[":hongshui"]                       = "<font color=\"red\"><b>限定技，</b></font>准备阶段你可弃置全部角色区域内全部牌。",
	[":zhufu"]                          = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可令装备区内无装备牌角色，回复一点体力并摸一张牌。",
	[":afuhuo"]                         = "<font color=\"red\"><b>限定技，</b></font>一名角色濒死时，你可弃置其一个区域内所有牌，其回复至X并摸至X张牌。（X为其空区域数量。）",
	[":tonghua"]                        = "摸牌阶段，你可以少摸一张牌并展示牌堆顶的三张牌，你可将任意张红色牌交给任意角色，然后弃置剩余牌",
	[":lingbo"]                         = "每回合限一次，你使用一张红桃牌后，你可以令一名角色回复一点体力。",
	[":chaogz"]                         = "<font color=\"blue\"><b>锁定技，</b></font>你的【杀】次数上限+1且手牌上限+2，当你首次击杀一名角色时，你的【杀】伤害+1且恒定摸牌数+2。",
	[":shengqiang"]                     = "<font color=\"blue\"><b>锁定技，</b></font>你的【杀】指定目标时，其须X张【闪】抵消；若此【杀】被抵消，本回合【杀】次数+1.攻击范围+1；此【杀】造成伤害时，X归0。（X为你使用【杀】次数）",
	[":paojixj"]                        = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可弃置任意张不同花色牌，选择攻击范围内等量角色，视为对其使用一张【杀】。若弃置装备牌，视为对其额外使用一张火属性【杀】",
	[":dqjt"]                           = "你可以跳过你的摸牌或出牌阶段，然后获得其他角色的一张牌,展示此牌并可交给一名角色",
	[":lianxie"]                        = "你使用非基本牌后，你可以重置你使用【杀】的次数。",
	[":huanzhaung"]                     = "你使用或打出一张基本牌后，你可以重铸一张牌。",
	[":xinshengll"]                     = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你选择一名拥有手牌的角色，其可令你观看其手牌，且你可选择其中一张令其使用。",
	[":llpj"]                           = "准备阶段，你可令所有其他角色无法使用【闪】直到你的回合开始。",
	[":shejiao"]                        = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可选择：1，令一名其他男性角色交给你至少一张手牌，你令其回复一点体力；2，你与一名女性各回复或失去一点体力，你获得/失去一枚负伤。",
	[":jsdy"]                           = "<font color=\"blue\"><b>锁定技，</b></font>若你的装备区内有牌，与你距离为1的女性角色不能响应你【杀】。",
	[":wanxian"]                        = "当你受到伤害后，你可以选择一名角色。若其装备区内牌数：小于你，其回复1点体力；等于你，其摸等同于伤害数的牌；大于你，其失去1点体力。",
	[":liantan"]                        = "出牌阶段结束时，你可以展示牌顶一张牌若与本阶段你使用的牌类型不同。则你令一名其他角色选择一项：1.使用一张与此牌类别相同的牌，然后获得此牌；2.令你获得此牌。",
	[":s_yanyu"]                        = "<font color=\"blue\"><b>锁定技，</b></font>当你受到伤害后，若之：为火焰伤害，你将体力值回复至X点，然后弃置一张手牌；不为火焰伤害，你对你造成1点火焰伤害。（X为你的手牌数且至少为2） ",
	[":s_yanmojianglin"]                = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可弃置全部手牌（至少三张牌），距离你最远的角色，选择跳过出牌阶段或受到一点伤害，距离你最近的角色，选择弃置全部手牌或受到一点伤害。",
	[":s_lianjie"]                      = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名没有“连结”技能的角色，其摸一张牌并获得“连结 ”技能 ",
	[":s_polie"]                        = "出牌阶段，你可以移除场上任意名角色的“连结”技能，然后弃置其中一名角色的x张牌，若其因此失去最后的牌，对其造成一点伤害（x为以此法移除的“连结”数）",
	[":s_shuimian"]                     = "<font color=\"blue\"><b>锁定技，</b></font>你的判定区内视为横置着【乐不思蜀】；当你的出牌阶段被跳过后，你选择一项：1.回复1点体力；2.跳过本回合的弃牌阶段。",
	[":s_jieshu"]                       = "结束阶段，你可与一名其他角色拼点或令一名其他角色获得技能【辅导】，若你赢，你摸两张牌进行一个出牌阶段，若你未赢，其获得技能【辅导】 ",
	[":s_fudao"]                        = "出牌阶段，你可选择令睡眠彼方获得一个出牌阶段或弃置睡眠彼方一张牌。",
	[":s_douM"]                         = "每回合限一次，一名角色获得/弃置其他角色的牌后，你可以摸两张牌，然后令其获得/弃置你一张牌。",
	[":s_shiziqishi"]                   = "<font color=\"blue\"><b>锁定技，</b></font>你每轮第一次造成或受到的杀的伤害改为弃置一张牌。",
	[":s_kongyi"]                       = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择至少一张牌并选择一名其他角色，其选择一项：1令你移动其场上一张牌；2你获得其等量的手牌并交给一名角色；3受到一点伤害，然后其获得你选择的牌 。 ",
	[":s_yueqian"]                      = "你受到伤害时，若你的场上有牌，你可以将你场上的牌移动到其他角色的区域内并防止此伤害。",
	[":s_newtype"]                      = "每轮限一次，一名其他角色的出牌阶段开始时，你可以令其摸两张牌，宣言一个其可主动使用的牌名（基本或非延时锦囊牌），其本回合使用的第一张牌不为你宣言的牌则其无法使用牌；回合结束时，若其本回合没有使用牌，则其可以视为使用你宣言的牌。",
	--房间消息
	["#skill_add_damage"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%from对%to造成的伤害增加至%arg2点。",
	["#skill_cant_jink"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%from对%to造成的伤害增加至%arg2点。",
	["#ansha"]                          = "<b><font color=\"yellow\">暗杀</b></font><b><font color=\"white\">的效果触发，此杀的伤害</b></font><b><font color=\"yellow\">+%arg，现在为%arg2</b></font>",
	["#molw"]                           = "%from 的“<font color=\"yellow\"><b>魔力</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",
	["#xianxsy"]                        = "<b><font color=\"yellow\">鲜血神衣</b></font><b><font color=\"white\">的效果触发，此杀的伤害</b></font><b><font color=\"yellow\">+1</b></font>",
	["#fengwang_equip"]                 = "%from<b><font color=\"white\">选择了</b></font><b><font color=\"yellow\"> 弃置一张装备牌</b></font>",
	["#fengwang_discard"]               = "%from<b><font color=\"white\">选择了</b></font><b><font color=\"yellow\"> 弃置手牌中的【杀】</b></font>",
	["#doubleslash_black"]              = "%from<b><font color=\"yellow\"> 本回合使用【杀】的目标上限+1</b></font>",
	["#doubleslash_red"]                = "%from<b><font color=\"yellow\"> 本回合可使用【杀】的次数+1</b></font>",
	["#betacheater_movetopile"]         = "<b><font color=\"yellow\">封弊者</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\"> 将所有手牌置于武将牌上</b></font>",
	["#betacheater_movetohand"]         = "<b><font color=\"yellow\">封弊者</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\"> 获得所有\"隐藏\"牌</b></font>",
	["#betacheater_damage"]             = "<b><font color=\"yellow\">封弊者</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\">所受伤害-%arg，现在为%arg2</b></font>",
	["#htms_xiaoshi"]                   = "<b><font color=\"yellow\">消失</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\"> 受到消失的效果影响</b></font>",
	["#Luaemeng"]                       = "因为%from 的“<font color=\"yellow\"><b>噩梦</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",
	["#LuayezhanBuff"]                  = "%from 的“<font color=\"yellow\"><b>夜战</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",
	["#qingtq"]                         = "蜻蜓切",
	["#qingtqAR"]                       = "蜻蜓切",
	["#fazededizao_type"]               = "%from 的“<font color=\"yellow\"><b>法则缔造</b></font>”选择 %arg",
	["#LuamuguanBuff"]                  = "吹雪的“<font color=\"yellow\"><b>目观</b></font>”效果被触发，伤害从 %arg 点增加至 %arg 点",
	["#pocdsfcard"]                     = "解除束缚",
	["#wnlz-down"]                      = "<b><font color=\"yellow\">无能力者</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\"> 受到的伤害-1，现在为%arg</b></font>",
	["#wnlz-up"]                        = "<b><font color=\"yellow\">无能力者</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\"> 受到的伤害+1，现在为%arg</b></font>",
	["#xiangrui"]                       = "<b><font color=\"yellow\">祥瑞</b></font><b><font color=\"white\">的效果触发，</b></font>%from<b><font color=\"yellow\"> 受到的伤害-1，现在为%arg</b></font>",
	["#geass"]                          = "%from 发动“<b><font color=\"yellow\">绝对指令</b></font><b><font color=\"white\">”观看了%to的手牌</font>",
	["#bhjz"]                           = "%from<b><font color=\"yellow\">即将受到的伤害改为1</b></font>",
	["#znai1"]                          = "<b><font color=\"yellow\">%from 选择了令 %to 获得一张装备牌</b></font>",
	["#znai2"]                          = "<b><font color=\"yellow\">%from 选择了令 %to 摸两张牌</b></font>",
	["#bings-increase"]                 = "%from 发动“<b><font color=\"yellow\">兵弑</font></b>”，<b><font color=\"yellow\">令%to受到的伤害+1</font></b>，现在为%arg",
	["#zyfashi-zs"]                     = "%from 发动“<b><font color=\"yellow\">法师</font></b>”，<b><font color=\"yellow\">令%to受到的伤害+1</font></b>，现在为%arg",
	["#bings-decrease"]                 = "%from 发动“<b><font color=\"yellow\">兵弑</font></b>”，<b><font color=\"yellow\">令其受到的伤害-1</font></b>，现在为%arg",
	["#dafan"]                          = "%from 发动“<b><font color=\"yellow\">打反</font></b>”，<b><font color=\"yellow\">令其受到的伤害-1</font></b>，现在为%arg",
	["#smsy"]                           = "%from 发动“<b><font color=\"yellow\">圣母圣咏</font></b>”，<b><font color=\"yellow\">令其造成的伤害+%arg</font></b>，现在为%arg2",
	["#jiewq"]                          = "%from 的“<b><font color=\"yellow\">界王拳</font></b>”被触发，<b><font color=\"yellow\">此杀造成的伤害+%arg</font></b>，现在为 %arg2",
	["#saiya"]                          = "%from 的“<b><font color=\"yellow\">赛亚人</font></b>”被触发，<b><font color=\"yellow\">造成的伤害+1</font></b>，现在为%arg",
	["#mozy"]                           = "%from<b><font color=\"yellow\"> 本回合不能成为【桃】的目标</b></font>",
	["#blmf-zs"]                        = "%from “<b><font color=\"red\">爆裂！</font></b>”，<b><font color=\"yellow\">令%to受到的伤害+1</font></b>，现在为%arg",
	["#tjdzf"]                          = "%from 发动了“<b><font color=\"yellow\">痛觉的止符</font></b>”，免除了 %arg 点伤害",
	["$badaozhaiQP"]                    = "剑是杀人的工具，这终究是事实",
	["$nidaorenQP"]                     = "赎罪",
	["#ShowRole"]                       = "%from 的身份为 %arg",
	["#jixieshenfire"]                  = "%from 使用了 %arg 对目标造成了一点火焰伤害。",
	["#jixieshenmianyi"]                = "%from 使用了 %arg 免疫了属性伤害。",
	["#jixieshenfixmachine"]            = "%from 修理机甲 %arg 。",
	["#fanyi-choices"]                  = "%from 发动了 %arg，选择了 %arg2",
	["#jiaoxing"]                       = "%from 发动了“%arg2”，将 %to 的延时锦囊 %card 效果改为 %arg",
	["gzjpdis"]                         = "弃置此牌",
	["gzjpslash"]                       = "视为使用雷【杀】",
	["#kuanghua1Effect"]                = "%from 进入“<font color=\"yellow\">狂化</font>”状态",
	["#kuanghua2Effect"]                = "%from 退出“<font color=\"yellow\">狂化</font>”状态",
	["@kuanghuaask"]                    = "请弃置一张 %src 牌否则失去一点体力",
	["#zhiyejieshao"]                   = "<font color=\"green\"><b>剑：使用【杀】时，若装备剑武器，目标须使用两张【闪】抵消。</b></font><br/><font color=\"red\"><b>法：场上有1/3/5个法师职业时，锦囊牌无距离限制/使用红色锦囊牌造成伤害时，可弃置一张牌伤害+1/使用锦囊牌造成伤害时，弃置一张牌此伤害+1。</b></font><br/></b></font><br/><font color=\"white\"><b>牧：当你使用四张【桃】后，治疗效果+1。</b></font><br/></b></font><br/><font color=\"blue\"><b>刺：出牌阶段限一次，你可观看一名未装备装备牌的其他角色两张手牌。</b></font><br/></b></font><br/><font color=\"yellow\"><b>盾：当你受伤时，若牌堆牌少于你当前体力十倍，你可增加一点体力上限并回复回复一点体力失去此技能，若你当前体力为1，则回复至体力上限。</b></font><br/>",
	["#void_recover"]                   = "%from 令 %to 回复一点体力，本回合虚空次数+1。",
	["#void_lose"]                      = "%from 令 %to 失去一点体力，本回合虚空次数-1。",
	["#khztbuff"]                       = "%from 的“<font color=\"yellow\"><b>狂化</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",
	["#bujushibai"]                     = "布局失败（【闪】不足弃置）",
	["#chaogz-increase"]                = "%from 发动“<b><font color=\"yellow\">超改造</font></b>”，<b><font color=\"yellow\">令%to受到的伤害+1</font></b>，现在为%arg",
	["#s_yanmojianglin_skipplay"]       = "%from 因 %arg 跳过出牌阶段",
	["#s_polie_damage"]                 = "%to 因 %arg 失去最后的牌, %from 对 %to 造成一点伤害 ",
	["#s_kongyi_num"]                   = "%from 发动“空移” 选择了 %arg 张牌",
	["#s_yueqian"]                      = "请选择 %src 的去向。",
	["#s_newtype_choice"]               = "%from 对 %to 发动“新人类” 宣言 %arg",
	["#s_newtype_limit"]                = " %to 使用的第一张牌为 %arg 不为 %from “新人类”宣言的牌 %arg2 ， %to 无法使用牌",
	--提示信息
	["zhiyexzks1"]                      = "职业选择",
	["@zhuisha_ask"]                    = "请选择一张手牌作为“追”",
	["@fengwang_askforequip"]           = "请选择一张装备牌弃置",
	["@wangzhe"]                        = "请选择【杀】的目标",
	["~wangzhe"]                        = "选择目标->点确定",
	["@doubleslash"]                    = "弃置一张手牌根据此牌颜色获得效果",
	["doubleslash_black"]               = "使用【杀】的目标上限+1",
	["doubleslash_red"]                 = "使用【杀】的次数+1",
	["@howlingask"]                     = "请打出一张【杀】或【闪】，否则受到一点伤害",
	["@defencefieldask"]                = "你可以弃置一张红色牌发动“防御结界”",
	["@chuszy_askforcard"]              = "可弃置一张牌令其回复一点体力",
	["@fashiyongchang"]                 = "弃置一张牌，令此伤害+1。",
	["@Luazuihou"]                      = "最后之剑",
	["@emeng"]                          = "你可以弃置一张牌令此伤害+1",
	["hunq-invoke"]                     = "你可以发动“破军歌姬”令一名角色摸一张牌",
	["@znai"]                           = "你可以发动“智能AI”令一名角色获得场上一张装备牌",
	["~znai"]                           = "选择目标",
	["@duanzui"]                        = "你可以对一名角色使用【杀】",
	["@jiyi"]                           = "你可以发动技能“畸意”",
	["~jiyi"]                           = "点确定或取消",
	["~lunhui"]                         = "选择目标",
	["@judaseffect"]                    = "你可以对 %src 使用一张【杀】",
	["@xiangrui"]                       = "你可以弃置一张牌对一名其他角色造成一点伤害。",
	["~xiangrui"]                       = "选择目标和卡牌后点确定。",
	["@Lualianji"]                      = "你可以使用一张锦囊牌或者装备牌。",
	["#lunhui"]                         = "请选择【%src】的目标",
	["@lunhui"]                         = "你可以使用此红色牌",
	["#lunhui1"]                        = "宿命",
	["@geass"]                          = "请选择目标角色",
	["~geass"]                          = "选择目标->点确定",
	["@lsmz"]                           = "你可以发动技能“零时迷子”",
	["~lsmz"]                           = "请选择卡牌或取消",
	["@sglj"]                           = "你可以使用一张锦囊牌或者装备牌",
	["@bings-increase"]                 = "你可以弃置一张装备牌令此伤害+1",
	["@bings-decrease"]                 = "你可以弃置一张手牌里的装备牌令此伤害-1",
	["@dafan"]                          = "你可以发动“打反”",
	["~dafan"]                          = "选择两张黑色牌->点确定",
	["@dafantarget"]                    = "选择一张红色牌交给 %src 或者受到其造成的1点伤害",
	["@smsy"]                           = "你可以发动“圣母圣咏”",
	["~smsy"]                           = "选择一张牌->点确定",
	["@kuixin"]                         = "你可以发动“窥心”",
	["~kuixin"]                         = "选择一名有手牌其他角色（可不选）->点确定",
	["@jiushu"]                         = "你可以对 %src 发动“救赎”",
	["~jiushu"]                         = "选择要弃置的牌->点确定",
	["@xieheng"]                        = "弃置一张牌并令 %src 回复1点体力，或不弃置牌并令其摸一张牌。",
	["@samsara"]                        = "请将 %src 张手牌当【%dest】使用",
	["~samsara"]                        = "点击技能→选择手牌→（选择目标）→确定",
	["zhanxianfanyu-invoke"]            = "请选择一名目标",
	["slash_defence"]                   = "是否发动“战线防御”使该角色免疫此次伤害？",
	["jixieshen:fixmachine"]            = "是否弃置一张手牌修理机甲？",
	["jueduiyazhi_loseMark"]            = "弃置两枚“蓝羽”标记",
	["jueduiyazhi_losehp"]              = "失去一点体力",
	["@kaleidoscope"]                   = "你可以发动“千变万化镜”选择一名角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["@haniel"]                         = "你可以弃置一张牌发动“赝造魔女”",
	["~qizui"]                          = "",
	["meihuomoyaninvoke"]               = "你可以发动“魅惑魔眼”为【%src】指定一个目标",
	["@jdyzask"]                        = "请弃置一张 %src 牌，否则失去一点体力",
	["@jiasugaobai"]                    = "你可以发动“加速告白”",
	["~jiasugaobai"]                    = "请选择一名男性角色",
	["@moxing"]                         = "你可以对 %src 发动技能“魔性”",
	["~moxing"]                         = "选择一张杀，然后点【确定】",
	["@tprs"]                           = "你可以对%src使用“天破壤碎”",
	["#bczzr"]                          = "不存在之人",
	["#yohane-distribute"]              = "请选择一张牌置于 %src 和 %dest 的区域内",
	["@fengfu-discard"]                 = "受到【凤缚】的影响，你需弃置一张黑色手牌，否则此【杀】对当前角色无效",
	["@fanyi-add"]                      = "请选择【%src】的额外目标",
	["@fanyi-remove"]                   = "请选择【%src】减少的目标",
	["@jiaoxing-use"]                   = "你可以发动“娇性”使用【乐不思蜀】",
	["~jiaoxing"]                       = "技能来源：娇性",
	["@anni-target"]                    = "你可以选择一名角色进行猜测",
	["@kuanghuaask"]                    = "请弃置一张%src牌否则失去一点体力",
	["@handsonicPush"]                  = "你可以一张牌（包括装备）置于 %src 的武将牌上",
	["@htms_wanlan-from"]               = "你可以弃置任意张牌（甚至可以不弃）\
	技能来源：挽澜",
	["@htms_wanlan-to"]                 = " %src 对你发动了“挽澜”，你可以弃置任意张牌（甚至可以不弃）\
	技能来源：挽澜",
	["@xiangy-to"]                      = "你可以弃置场上一张牌\
	技能来源：翔翼",
	["@tucao-to"]                       = "你可以弃置场上一张牌\
	技能来源：吐槽",
	["@haite-ask"]                      = "你可以对任意名其他角色各造成1点伤害",
	["~haite"]                          = "技能来源：海底摸月",
	["@jiyidiejia"]                     = "你可以发动“记忆叠加”",
	["~jiyidiejia"]                     = "选择一名角色→点击确定",
	["@dushe-use"]                      = "你可以发动“毒舌”",
	["@dushe-card"]                     = "你可以使用一张基本牌",
	["~dushe"]                          = "技能来源：毒舌",
	["jujimaninvoke"]                   = "选择狙击的目标，<br/>造成两点高额伤害。<br/>(发把狙！)",
	["suoersimaninvoke"]                = "选择甩狙目标",
	["~xysyn"]                          = "回复目标一点体力",
	["~xiangyangshi"]                   = "选择弃牌等量角色",
	["~yugaobp"]                        = "选择一名其他角色",
	["ksyugaobp"]                       = "免费使用一次预告",
	["jiansub"]                         = "剑速",
	["jiansua"]                         = "剑速",
	["jiansu-invoke"]                   = "选择一名目标，<br/>（若为当前回合角色则无效）",
	["huoli-invoke"]                    = "选择一名其他角色造成一点伤害并摸一张牌",
	["#jiansu"]                         = "选择一张杀",
	["weituo11"]                        = "委托<br/>（获得此牌，成为委托者）",
	["juexingmoshen-invoke"]            = "对一名角色造成一点伤害。",
	["duanding-invoke"]                 = "预测，下一次受到普通伤害的角色",
	["@mingduanqiuh"]                   = "你可以用一张手牌替换展示的【%arg】",
	["mingduan-invoke"]                 = "选择一名角色",
	["zhengdao-invoke"]                 = "选择目标进行拼点",
	["zhihou-invoke"]                   = "选择一名其他角色令目标交给你一张手牌",
	["@zhihougp-give"]                  = "将一张手牌交给花丸",
	["@jibanxuanze"]                    = "使用一张牌",
	["muou-invoke"]                     = "选择一名角色",
	["@muou"]                           = "弃置一张牌",
	["nvzi-invoke"]                     = "选择一名其他角色观看手牌",
	["#chunrijilu_dis"]                 = "%arg 使场上 %arg2 名角色体力值发生变化，%from 须弃置 %arg2 张页",
	["@chunrijilu"]                     = "你可以使用一张“页”",
	["~chunrijilu"]                     = "选择一张“页”→选择目标角色→点击确定",
	["#htms_wanlanRace"]                = "%from 弃置的牌点数之和为 %arg",
	["@duandai"]                        = "你须弃置一张 %src 牌",
	["qiyuan-invoke"]                   = "你可以发动“祈愿”<br/> <b>操作提示</b>: 选择一名手牌上限小于4的角色→点击确定<br/>",
	["$qidao_use"]                      = "%from 使用了 <font color=\"yellow\"><b>祈祷</b></font>，%to 获得的  %card  %arg2 ",
	["qidao_draw"]                      = "改为摸X张牌",
	["qidao_dis"]                       = "改为弃置一张牌",
	["@Luayuanling"]                    = "你可以发动“怨灵”",
	["~Luayuanling"]                    = "请选择要横置的角色",
	["Luashenyito"]                     = "你可以令一名角色执行一个额外的出牌阶段。",
	["~empaidui"]                       = "请选择角色",
	["~zhongerhx"]                      = "请选择角色成为目标",
	["@zhongerhx"]                      = "正在使用选择牌",
	["nvzidaoxw"]                       = "是否移动场上一张牌",
	["~nvzidao"]                        = "选择一名有牌角色",
	["nvzidao-to"]                      = "请选择移动【%arg】的目标角色",
	["@duancai"]                        = "你可以弃置一张点数小于7的手牌，对其造成一点伤害。",
	["@duancaiex"]                      = "你可以弃置一张点数大于7的手牌，对其造成一点伤害。",
	["@tongzhouqg"]                     = "交给 %src 一张手牌",
	["@qgjiesi"]                        = "令他们弃置一张牌",
	["~qgjiesi"]                        = "选择至多X名角色，（X为你于此阶段内弃置牌的数量）。",
	["@zjmoshuxif"]                     = "须弃置一张牌",
	["@mingmendia"]                     = "你可以获得至多两名其他角色各一张牌。",
	["~mingmendia"]                     = "选择角色→确定。",
	["@mingmendiaa"]                    = "交给 %src 一张牌",
	["@mingmendib"]                     = "交给 %src 一张牌",
	["$puzou_use"]                      = "此阶段进入过弃牌堆的牌为  %card %arg %arg2 ",
	["luajinlun-invoke"]                = "令一名角色弃置全部手牌进行一个易逝回合。",
	["@dafanuj-give"]                   = "交给对方一张手牌。",
	["lualushouA"]                      = "你可以弃置一张基本牌令此【杀】不可被闪避。",
	["lualushouB"]                      = "你可以弃置一张锦囊牌，摸一张牌，并为此【杀】额外指定一个目标。",
	["lualushouC"]                      = "你可以弃置一张装备牌，若此【杀】造成伤害，你回复等量的体力。",
	["@fenmao-qp"]                      = "你可以弃置一张手牌进行判定获得技能。",
	["@ujyaozhan"]                      = "你可以对优纪使用一张【杀】。",
	["@ujlianji"]                       = "你可以使用一张【杀】。",
	["@ujlianjig"]                      = "你可以使用一张牌。",
	["@Sdorica_FuWei"]                  = "请选择需要置于牌堆顶的牌",
	["@Sdorica_MiLing"]                 = "点确定，使用【杀】； 点取消，获得“免疫”\n（下次指定或成为牌的目标时，取消所有目标）。",
	["pomie_card"]                      = "你可以为“回避破灭”做准备！<br/> <b>操作提示</b>: 选择一名手牌数最少的角色→点击确定<br/>",
	["yiban_card"]                      = "你可以发动“依伴”",
	["~yiban"]                          = "选择任意张牌→选择一名其他角色→点击确定",
	["yiban:cp"]                        = "护花(出一张牌)",
	["yiban:gp"]                        = "投食（给一张牌）",
	["tonghh-invoke"]                   = "选择一名角色成为同好角色。",
	["@luashouhuo"]                     = "令一名角色手牌补至其手牌上限",
	["luahongyu2"]                      = "请选择要分发的一个对象。",
	["pinkdevilx"]                      = "选择一名角色视为对其使用一张杀",
	["shenpan-invoke"]                  = "对一名体力最多的其他角色造成一点伤害",
	["gxzhiliao-invoke"]                = "令一名角色下个出牌阶段弃置一枚“负伤”并回复一点体力。",
	["@dalunb"]                         = "弃置一张步牌决定目标数量",
	["~dalunb"]                         = "选择卡牌指定目标并确定",
	["dalunb_select"]                   = "大论",
	["dalunb_xx"]                       = "大论",
	["@tonghuagp"]                      = "你可以将【%arg】交给一名角色",
	["@dqjtp"]                          = "你可以获得一名其他角色一张牌展示且可交给一名其他角色。",
	["@dqjtx"]                          = "你可以将【%arg】交给一名角色",
	["@xinshengll"]                     = "为此牌选择目标。",
	["shejiaofuka_card"]                = "交给其至少一张牌后，你回复一点体力。",
	["shejiao_hf"]                      = "你与其各回复一点体力",
	["shejiao_sq"]                      = "你与其各失去一点体力",
	["@wanxian"]                        = "选择一名角色根据你与其装备区数量执行效果。",
	["@liantan"]                        = "选择一名角色令其选择。",
	["@liantansyc"]                     = "使用要求牌。",
	["liantan_yp"]                      = "使用一张与此牌类别相同的牌，然后获得此牌",
	["liantan_hd"]                      = "令其获得此牌",
	["s_yanyu-invoke"]                  = "“焰愈”被触发<br/> <b>操作提示</b>: 选择一张手牌→点击确定<br/>",
	["s_yanmojianglin_skipplay"]        = "跳过出牌阶段",
	["s_polie_dis"]                     = "你发动“破裂”弃置其中一名角色的 %src 张牌<br/> <b>操作提示</b>: 选择其中一名角色→点击确定<br/>",
	["s_jieshu-invoke"]                 = "你可以发动“借宿”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["s_jieshu_skill"]                  = "令其获得技能【辅导】",
	["s_jieshu_pindian"]                = "与其拼点",
	["s_shiziqishi-invoke"]             = "“十字骑士”被触发<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	["s_kongyi_getfield"]               = "请选择 %src 的去向。",
	["@s_newtypeOther"]                 = "你可以发动“新人类”视为使用 %src",
	["~s_newtypeOther"]                 = "选择若干名目标→点击确定",
	[":s_newtypeOther"]                 = "若你本回合没有使用牌，则你可以视为使用新人类宣言的牌。",
	--标记
	["@zhiyejs"]                        = "剑士",
	["@zhiyefs"]                        = "法师",
	["@zhiyems"]                        = "牧师",
	["@zhiyeck"]                        = "刺客",
	["@zhiyedd"]                        = "大盾",
	["@tcmfs"]                          = "天才魔法师",
	["@frozenpuppet"]                   = "冰冻傀儡",
	["$frozenpuppetQP"]                 = "冰冻傀儡",
	["@zhanxianfanyu"]                  = "防御",
	["@lanyu"]                          = "蓝羽",
	["@zsmy"]                           = "直死魔眼",
	["@lsmz"]                           = "零时迷子",
	["@yinguo"]                         = "因果",
	["@zuzhou"]                         = "诅咒",
	["@jingyan"]                        = "经验",
	["@jujiman"]                        = "狙击准备",
	["@lianjiqudong"]                   = "连击驱动",
	["@yanliao"]                        = "颜料",
	["@yugao"]                          = "预告",
	["@mozy"]                           = "死亡",
	["@duanding"]                       = "断定",
	["@yugaofenghuan"]                  = "宝石归还",
	["@liufangzhe"]                     = "流放者",
	["@weituozhe"]                      = "委托者",
	["@zhengdao"]                       = "争导",
	["@zhihou"]                         = "滞后",
	["@weixiao"]                        = "微笑",
	["@wangquan"]                       = "王权",
	["@yftuji"]                         = "混战中",
	["@yishi"]                          = "易逝",
	["@htms_qiyuan"]                    = "愿",
	["@luajinlun"]                      = "经书",
	["@hanrenzdbj"]                     = "寒刃冰冻",
	["@xianxue"]                        = "鲜血",
	["@wyqp"]                           = "仪",
	["@wysh"]                           = "威",
	["@mol"]                            = "魔力",
	["@shisheng"]                       = "誓胜",
	["@shengyong"]                      = "圣咏",
	["@Immunity"]                       = "免疫",
	["@tonghao"]                        = "同好",
	--选项
	--ps:建议格式["skillname:alternative"] = "",
	["zhiye:js"]                        = "获得【剑士】职业：装备剑武器时提升命中率。",
	["zhiye:fs"]                        = "获得【法师】职业：根据法师人数获得额外加成。",
	["zhiye:ms"]                        = "获得【牧师】职业：完成任务获得任务奖励。",
	["zhiye:ck"]                        = "获得【刺客】职业：寻找机会一击必杀。",
	["zhiye:dd"]                        = "获得【大盾】职业：后期显著增强。",
	["fengwang_discard"]                = "弃置手牌中的【杀】",
	["fengwang_equip"]                  = "弃置一张装备牌",
	["newfengwang_discard"]             = "直到你的回合结束，其无法使用闪",
	["newfengwang_equip"]               = "其失去一点体力并收回其装备区所有牌",
	["jiyi_guanxing"]                   = "将其余牌以任意顺序放回牌堆顶",
	["jiyi_throw"]                      = "弃置其余牌",
	["Judge"]                           = "令其他角色跳过判定阶段",
	["Draw"]                            = "令其他角色跳过摸牌阶段",
	["Play"]                            = "令其他角色跳过出牌阶段",
	["Discard"]                         = "令其他角色跳过弃牌阶段",
	["znai1"]                           = "令其获得场上一张装备牌",
	["znai2"]                           = "令其摸两张牌",
	["guailj1"]                         = "弃置装备区中的防具牌",
	["guailj2"]                         = "受到一点伤害",
	["qrdag:qrdag_recover"]             = "回复1点体力",
	["qrdag:qrdag_discard"]             = "弃置一张“音符”",
	["kikann_1"]                        = "调整至时雨体力值",
	["kikann_2"]                        = "调整至时雨手牌数",
	["fazededizao:fzndz_1"]             = "跳过判定阶段",
	["fazededizao:fzndz_2"]             = "跳过摸牌阶段",
	["fazededizao:fzndz_3"]             = "跳过出牌阶段",
	["fazededizao:fzndz_4"]             = "跳过弃牌阶段",
	["fzndz_1"]                         = "跳过判定阶段",
	["fzndz_2"]                         = "跳过摸牌阶段",
	["fzndz_3"]                         = "跳过出牌阶段",
	["fzndz_4"]                         = "跳过弃牌阶段",
	["yohane:ph"]                       = "手牌区",
	["yohane:pe"]                       = "装备区",
	["yohane:pj"]                       = "判定区",
	["fanyi:1range_ad"]                 = "攻击范围+1",
	["fanyi:2maxcard_ad"]               = "手牌上限+1",
	["fanyi:3available_ad"]             = "使用【杀】的次数上限+1",
	["fanyi:4target_ad"]                = "首次使用【杀】或普通锦囊的目标数上限+1",
	["fanyi:1range_re"]                 = "攻击范围-1",
	["fanyi:2maxcard_re"]               = "手牌上限-1",
	["fanyi:3available_re"]             = "使用【杀】的次数上限-1",
	["fanyi:4target_re"]                = "首次使用【杀】或普通锦囊的目标数上限-1",
	["fanyi:5draw_ad"]                  = "摸牌阶段摸牌数+1",
	["fanyi:5draw_re"]                  = "摸牌阶段摸牌数-1",
	["fanyi:done"]                      = "选两项就够了",
	["anni:anni_hit"]                   = "此杀会造成伤害",
	["anni:anni_miss"]                  = "此杀不造成伤害",
	["use_blackequip_discard"]          = "获得并使用弃牌堆的一张黑色装备牌",
	["use_slash"]                       = "使用一张【杀】",
	["xiangy:draw1"]                    = "摸一张牌",
	["xiangy:dis"]                      = "弃置场上的一张牌",
	["fengshou:dcards"]                 = "初始额外摸牌数+1.5",
	["fengshou:mcards"]                 = "手牌上限+2.5",
	["htms_wanlan:draw_one_card"]       = "摸一张牌",
	["htms_wanlan:obtain_one_card"]     = "收回自己所弃置的一张牌",
	["sugong:huix"]                     = "回复一点体力",
	["sugong:lius"]                     = "失去一点体力并摸一张牌",
	["duandai_j"]                       = "判定区",
	["duandai_e"]                       = "装备区",
	["duandai_h"]                       = "手牌区",
	["duandai_distance"]                = "【杀】无距离限制",
	["duandai_residue"]                 = "【杀】无次数限制",
	["tucao:mp"]                        = "摸牌",
	["tucao:qp"]                        = "弃置场上一张牌",
	["juejian:qz"]                      = "所有其他角色将手牌弃置至1",
	["juejian:ls"]                      = "所有其他角色失去一点体力",
	["hezibz:shangh"]                   = "所有角色受到一点伤害",
	["hezibz:huif"]                     = "回复一点体力",
	["zjruoshi:red"]                    = "判定红色",
	["zjruoshi:black"]                  = "判定黑色",
	["zjaojiaol:red"]                   = "猜测弃置红色",
	["zjaojiaol:black"]                 = "猜测弃置黑色",
	["htms_weiyi:qp"]                   = "伤害来源弃置X张牌",
	["htms_weiyi:sh"]                   = "伤害来源受到X-1点伤害",
	["puzou_losehp"]                    = "所有角色失去一点体力",
	["puzou_heal"]                      = "所有角色回复一点体力",
	["fwdiscard&put"]                   = "弃置一张牌，将其区域内一张牌置于牌堆顶",
	["put_on_drawcards"]                = "将一张牌置于牌堆顶",
	["cancel"]                          = "取消",
	["oumashu_recover"]                 = "令其回复一点体力，本回合虚空次数+1",
	["oumashu_lose"]                    = "令其失去一点体力，本回合虚空次数-1",
	["lsqd:qp"]                         = "弃置一张牌，使用弃牌堆一张武器牌",
	["lsqd:kd"]                         = "摸一张牌并将装备区内一张牌置于牌顶",
	["fuhuo_j"]                         = "判定区",
	["fuhuo_e"]                         = "装备区",
	["fuhuo_h"]                         = "手牌区",
	["s_yanmojianglin_damage"]          = "受到一点伤害",
	["s_yanmojianglin_throwcard"]       = "弃置全部手牌",
	["s_shuimian_skipdiscard"]          = "跳过本回合的弃牌阶段",
	["s_shuimian_recover"]              = "回复1点体力",
	["s_fudao_discard"]                 = "弃置睡眠彼方一张牌",
	["s_fudao_play"]                    = "令睡眠彼方获得一个出牌阶段",
	["s_kongyi_damage"]                 = "你受到一点伤害然后，获得其选择的牌",
	["s_kongyi_movefield"]              = "移动你场上一张牌",
	["s_kongyi_handcard"]               = "其获得你等量的手牌并交给一名角色",
	--私家牌堆
	["zhui"]                            = "追",
	["hide"]                            = "隐藏",
	["bian"]                            = "变",
	["qrdag_yin"]                       = "音符",
	["yun"]                             = "韵",
	["temporarycards"]                  = "临时牌堆",
	["rains"]                           = "雨",
	["rank"]                            = "等级",
	["htms_fengyu"]                     = "风语",
	["s_ye"]                            = "页",
	["bu_bu"]                           = "步",


	--动画
	["tjdzf$"] = "anim=skill/tjdzf",

}
--切换背景
function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else return false end
end

local n = 0
for i = 1, 998, 1 do
	if file_exists("image/system/backdrop/" .. i .. ".jpg") then
		n = i
	else
		break
	end
end

sgs.SetConfig("BackgroundImage", "image/system/backdrop/" .. math.random(1, n) .. ".jpg")
sgs.SetConfig("TableBgImage", "image/system/backdrop/" .. math.random(1, n) .. ".jpg")

--信息发送
function printTable(t, k, v)
	for k, v in ipairs(t) do
		print(string.format('t[%d] = %s', k, v))
	end
end

function Table2TableSample(tb, n)
	if (n >= #tb) then return false end
	for i = 1, n do
		local index = math.random(1, #tb)
		table.remove(tb, index)
	end
	return tb
end

function sendLog(message_type, room, from, arg, arg2, to)
	local msg = sgs.LogMessage()
	msg.type = message_type
	if to then msg.to:append(to) end
	if from then msg.from = from end
	if arg then msg.arg = arg end
	if arg2 then msg.arg2 = arg2 end
	room:sendLog(msg)
	return
end

--table到playerlist的转换
function Table2Playerlist(thetable)
	local playerlist = sgs.PlayerList()
	for _, player in ipairs(thetable) do
		playerlist:append(player)
	end
	return playerlist
end

--table到serverplayerlist的转换
function Table2SPlayerlist(thetable)
	local playerlist = sgs.SPlayerList()
	for _, player in ipairs(thetable) do
		playerlist:append(player)
	end
	return playerlist
end

--职业
zhiyexuanze = sgs.CreateTriggerSkill {
	name = "zhiyexuanze",
	global = true,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "InitialHandCards" then return false end
		local t = { 'zhiye:js', 'zhiye:fs', 'zhiye:ms', 'zhiye:ck', 'zhiye:dd' }
		if player:getMark("@tcmfs") == 0 then
			if player:getRole() == "lord" and room:askForSkillInvoke(player, "zhiyexzks1") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:addPlayerMark(p, "zhiyexz", 1)
				end
				local msg = sgs.LogMessage()
				msg.type = "#zhiyejieshao"
				room:sendLog(msg)
			end
			local sample = {}
			if (player:getRole() == "lord" or player:getRole() == "renegade") and player:getMark("zhiyexz") == 1 then
				sample = Table2TableSample(t, 0)
			elseif (player:getRole() == "loyalist" or player:getRole() == "rebel") and player:getMark("zhiyexz") == 1 then
				sample = Table2TableSample(t, 2)
			end
			printTable(sample, 0, 2)
			local choice = room:askForChoice(player, self:objectName(), table.concat(sample, '+'), data)
			if choice == 'zhiye:js' then
				player:gainMark("@zhiyejs")
				room:acquireSkill(player, "zyjianshu")
			elseif choice == 'zhiye:fs' then
				player:gainMark("@zhiyefs")
				room:acquireSkill(player, "zyfashi")
			elseif choice == 'zhiye:ms' then
				player:gainMark("@zhiyems")
				room:acquireSkill(player, "zymushi")
			elseif choice == 'zhiye:ck' then
				player:gainMark("@zhiyeck")
				room:acquireSkill(player, "zycike")
			elseif choice == 'zhiye:dd' then
				player:gainMark("@zhiyedd")
				room:acquireSkill(player, "zydadun")
			end
		end
	end,
}

zyjianshu = sgs.CreateTriggerSkill {
	name = "zyjianshu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() and (player:hasWeapon("Elucidator") or
					player:hasWeapon("double_sword") or player:hasWeapon("ice_sword") or player:hasWeapon("Murasame") or player:hasWeapon("qinggang_sword") or player:hasWeapon("tywz")) and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
	end
}

zyfashi = sgs.CreateTriggerSkill {
	name = "zyfashi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local fnum = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@zhiyefs") == 1 then
					fnum = fnum + 1
				end
			end
			if fnum == 3 and damage.card:isKindOf("TrickCard") and damage.card:isRed() and player:getMark("@zhiyefs") == 1 then
				if not room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@fashiyongchang") then return false end
				damage.damage = damage.damage + 1
				sendLog("#zyfashi-zs", room, player, damage.damage, nil, damage.to)
				room:broadcastSkillInvoke(self:objectName())
				data:setValue(damage)
			end
			if fnum == 5 and damage.card:isKindOf("TrickCard") and player:getMark("@zhiyefs") == 1 then
				if not room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@fashiyongchang") then return false end
				damage.damage = damage.damage + 1
				sendLog("#zyfashi-zs", room, player, damage.damage, nil, damage.to)
				room:broadcastSkillInvoke(self:objectName())
				data:setValue(damage)
			end
		end
	end
}
zyfashijl = sgs.CreateTargetModSkill {
	name = "zyfashijl",
	global = true,
	pattern = "TrickCard",
	distance_limit_func = function(self, from, card)
		local n = 0
		for _, p in sgs.qlist(from:getAliveSiblings()) do
			if p:getMark("@zhiyefs") == 0 and from:getMark("@zhiyefs") == 1 then
				n = 10000
			end
		end
		return n
	end
}
zymushi = sgs.CreateTriggerSkill {
	name = "zymushi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified, sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if not use.card:isKindOf("Peach") then return false end
			player:gainMark("@peach")
			if player:getMark("@peach") == 4 then
				player:loseAllMarks("@peach")
				room:handleAcquireDetachSkills(player, "-zymushi|zymushijl")
			end
		end
	end,
}
zymushijl = sgs.CreateTriggerSkill {
	name = "zymushijl",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		if event == sgs.PreHpRecover then
			local room = player:getRoom()
			local rec = data:toRecover()
			for _, p in sgs.qlist(room:findPlayersBySkillName("zymushijl")) do
				if rec.who and (rec.who:objectName() == p:objectName()) then
					rec.recover = rec.recover + 1
					data:setValue(rec)
				end
			end
		end
	end
}
zycikecard = sgs.CreateSkillCard {
	name = "zycike",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and (not to_select:isKongcheng()) and to_select:objectName() ~= player:objectName() and
		(not to_select:hasEquip())
	end,
	on_use = function(self, room, source, targets)
		--[[local list = sgs.IntList()
		local idss = sgs.IntList()
			for _,card in sgs.qlist(targets[1]:getHandcards()) do
				list:append(card:getId())
			end	
		local ids = list
		for i = 1, 2 do
				local id = ids:at(math.random(0, ids:length() - 1))
					idss:append(id)			
			end
		room:fillAG(idss, source)
		room:getThread():delay(2000)
		room:clearAG(source)]]
		room:setPlayerFlag(targets[1], "zycike_InTempMoving");
		local original_places = sgs.PlaceList()
		local card_ids = sgs.IntList()
		local x = 2
		if targets[1]:getHandcardNum() < 2 then
			x = targets[1]:getHandcardNum()
		end
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:deleteLater()
		for i = 1, x, 1 do
			card_ids:append(room:askForCardChosen(source, targets[1], "h", self:objectName()))
			original_places:append(room:getCardPlace(card_ids:at(i - 1)))
			dummy:addSubcard(card_ids:at(i - 1))
			targets[1]:addToPile("#zycike", card_ids:at(i - 1), false)
		end
		if dummy:subcardsLength() > 0 then
			for i = 1, dummy:subcardsLength(), 1 do
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), targets[1], original_places:at(i - 1), false)
			end
		end
		room:setPlayerFlag(targets[1], "-zycike_InTempMoving")
		for _, card in sgs.qlist(card_ids) do
			room:showCard(targets[1], sgs.Sanguosha:getCard(card):getEffectiveId(), source)
		end
	end
}
zycike_InTempMoving = sgs.CreateTriggerSkill {
	name = "#zycike",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("zycike_InTempMoving") then
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

zycike = sgs.CreateZeroCardViewAsSkill {
	name = "zycike",
	view_as = function(self)
		return zycikecard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zycike")
	end
}
extension:insertRelatedSkills("zycike", "#zycike")
zydadun = sgs.CreateTriggerSkill {
	name = "zydadun",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player and room:getDrawPile():length() < player:getHp() * 10 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
			if player:getHp() == 1 then
				local num = player:getMaxHp()
				room:recover(player, sgs.RecoverStruct(player, nil, num))
			else
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
			room:handleAcquireDetachSkills(player, "-zydadun")
		end
	end,
}
--追杀
zhuisha = sgs.CreateTriggerSkill {
	name = "zhuisha",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if not effect.card or not effect.card:isKindOf("Slash") then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1)
			if effect.to:isAlive() then
				local zhui = room:askForCard(player, ".|.|.|hand!", "@zhuisha_ask", data, sgs.Card_MethodNone)
				effect.to:addToPile("zhui", zhui, true)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if not damage.card or not damage.card:isKindOf("Slash") then return false end
			local target = damage.to
			local num = 0
			if target:getPile("zhui"):length() > 0 then
				num = num + math.min(target:getPile("zhui"):length())
				target:clearOnePrivatePile("zhui")
			end
			if num == 0 then return false end
			damage.damage = damage.damage + num
			sendLog("#skill_add_damage", room, damage.from, self:objectName(), damage.damage, damage.to)
			room:broadcastSkillInvoke(self:objectName())
			data:setValue(damage)
		end
	end,
}
zhuisha_mod = sgs.CreateTriggerSkill {
	name = "#zhuishaMod",
	events = { sgs.Death, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death and not data:toDeath().who:hasSkill(self:objectName()) then return false end
		if event == sgs.EventLoseSkill and data:toString() ~= "zhuisha" then return false end
		local playerlist = room:getAlivePlayers()
		for _, aplayer in sgs.qlist(playerlist) do
			aplayer:clearOnePrivatePile("zhui")
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("zhuisha", "#zhuishaMod")
--暗杀
ansha = sgs.CreateTriggerSkill {
	name = "ansha",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") then return false end
		local target = damage.to
		local num = 0
		if not target:isWounded() then
			num = num + 1
		end
		if target:getPile("zhui"):length() > 0 then
			num = num + math.min(target:getPile("zhui"):length())
			target:clearOnePrivatePile("zhui")
		end
		if num == 0 then return false end
		damage.damage = damage.damage + num
		sendLog("#ansha", room, nil, num, damage.damage)
		room:broadcastSkillInvoke(self:objectName())
		data:setValue(damage)
	end,
}
--葬送
htms_zangsongCard = sgs.CreateSkillCard {
	name = "htms_zangsongCard",
	will_throw = true,
	filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("htms_zangsong")

        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player)
    end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		slash:setSkillName("htms_zangsong")
		room:useCard(sgs.CardUseStruct(slash, source, target))
	end,
}
htms_zangsongVS = sgs.CreateOneCardViewAsSkill {
	name = "htms_zangsong",
	view_filter = function(self, to_select)
		return to_select:isDamageCard()
	end,
	view_as = function(self, card)
		local zangsong = htms_zangsongCard:clone()
		zangsong:setSkillName(self:objectName())
		zangsong:addSubcard(card)
		return zangsong
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#htms_zangsongCard")
	end
}
htms_zangsong = sgs.CreateTriggerSkill {
	name = "htms_zangsong",
	view_as_skill = htms_zangsongVS,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") then return false end
		if damage.card:getSkillName() == "htms_zangsong" then
			local target = damage.to
			if target:getLostHp() == 0 then return false end
			damage.damage = damage.damage + target:getLostHp()
			sendLog("#skill_add_damage", room, damage.from, self:objectName(), damage.damage, damage.to)
			-- room:broadcastSkillInvoke(self:objectName())
			data:setValue(damage)
		end
	end,
}
zangsongTargetMod = sgs.CreateTargetModSkill {
	name = "#zangsongTargetMod",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("htms_zangsong") and card and card:getSkillName() == "htms_zangsong" then
			return 999
		end
	end

}

--试炼
shilian = sgs.CreateTriggerSkill {
	name = "shilian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "shilian_ok", 1)
		local damage = data:toDamage()
		if not damage.from then return false end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		slash:setSkillName(self:objectName())
		if not player:canSlash(damage.from, slash, false) then return false end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		room:broadcastSkillInvoke("shilian")
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = player
		use.to:append(damage.from)
		room:useCard(use)
	end,
}
--试炼EX
shilianEX = sgs.CreateTriggerSkill {
	name = "shilianEX",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			if player:getMark("shilian_ok") > 0 then return false end
			local room = player:getRoom()
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "EXCard_WWJZ" then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			if not damage.from then return false end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			slash:deleteLater()
			if not player:canSlash(damage.from, slash, false) then return false end
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = player
			use.to:append(damage.from)
			--damage.from:addQinggangTag(slash)
			room:broadcastSkillInvoke("shilian")
			room:useCard(use)
		elseif event == sgs.TargetSpecified then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.from and use.from:hasSkill(self:objectName()) then
				if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == self:objectName() then
					if use.from:objectName() == player:objectName() then
						for _, p in sgs.qlist(use.to) do
							if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then
								p:addQinggangTag(use.card)
							end
						end
						--room:setEmotion(use.from, "weapon/qinggang_sword")
						room:sendCompulsoryTriggerLog(use.from, "shilianEX", true)
					end
				end
			end
		end
	end
}
shilian_usingjudge = sgs.CreateTriggerSkill { --如果是在伤害结算过程中改描述则不可发动新试炼
	name = "#shilian_usingjudge",
	events = { sgs.Damaged },
	priority = -100,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "shilian_ok", 0)
	end
}
--最终试炼
zzsl_count = sgs.CreateTriggerSkill {
	name = "#zzsl_count",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreCardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from:hasSkill("zzsl") then
			room:addPlayerMark(player, "zzslCount")
		end
	end
}
zzsl = sgs.CreateTriggerSkill {
	name = "zzsl",
	frequency = sgs.Skill_Wake,
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then
			room:addPlayerMark(player, "zzsl")
			if room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				--room:handleAcquireDetachSkills(player, "-shilian")
				--room:handleAcquireDetachSkills(player, "shilianEX")
				room:detachSkillFromPlayer(player, "shilian", true)
				room:getThread():addTriggerSkill(sgs.Sanguosha:getTriggerSkill("shilianEX"))
				room:attachSkillToPlayer(player, "shilianEX")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
			and (target:getMark("zzsl") == 0)
			and (target:getMark("zzslCount") >= 3)
	end
}
extension:insertRelatedSkills("zzsl", "#shilian_usingjudge")
extension:insertRelatedSkills("zzsl", "#zzsl_count")

--鲜血神衣

xianxsy_cishu  = sgs.CreateTargetModSkill {
	name = "xianxsy_cishu",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMark("chanlz") ~= 0 then
			return player:getMark("@xianxue") - 1
		end
	end

}
xianxsy_range  = sgs.CreateAttackRangeSkill {
	name = "#xianxsy_range",
	extra_func = function(self, player)
		if player:hasSkill("xianxsy_cishu") and player:getMark("chanlz") ~= 0 then return player:getMark("@xianxue") - 1 end
	end,
}
xianxsy_target = sgs.CreateTargetModSkill {
	name = "#xianxsy_target",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill("xianxsy_cishu") and from:getMark("chanlz") ~= 0 then return from:getMark("@xianxue") - 1 end
	end,
}
xianxsy_spmax  = sgs.CreateMaxCardsSkill {
	name = "#xianxsy_spmax",
	fixed_func = function(self, target)
		if target:hasSkill("xianxsy_cishu") and target:getMark("chanlz") ~= 0 then
			return target:getMark("@xianxue")
		end
	end
}
--鲜血沸腾
xianxuefeiteng = sgs.CreateTriggerSkill {
	name = "xianxuefeiteng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local hp = math.min(player:getLostHp(), player:getMaxHp())
				local num = math.max(player:getLostHp(), player:getHp())
				if player:getLostHp() > player:getHp() then
					player:loseMark("@xianxue", num)
				end
				if player:getLostHp() < player:getHp() then
					player:gainMark("@xianxue", num)
					if player:getMark("chanlz") == 0 then
						room:addPlayerMark(player, "chanlz")
					end
				end
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				room:enterDying(player, nil)
			end
		end
		return false
	end
}

extension:insertRelatedSkills("xianxsy", "xianxsy_cishu")
extension:insertRelatedSkills("xianxsy", "#xianxsy_range")
extension:insertRelatedSkills("xianxsy", "#xianxsy_target")
extension:insertRelatedSkills("xianxsy", "#xianxsy_spmax")
--风王
fengwangCard = sgs.CreateSkillCard {
	name = "fengwang",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and to_select:hasEquip() and
		not to_select:isKongcheng()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:showAllCards(target)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		for _, card in sgs.qlist(target:getHandcards()) do
			if card:isKindOf("Slash") then dummy:addSubcard(card) end
		end
		local choice = "fengwang_equip"
		if dummy:getSubcards():length() > 0 then
			choice = room:askForChoice(target, self:objectName(), "fengwang_discard+fengwang_equip")
		end
		if choice == "fengwang_equip" then
			sendLog("#fengwang_equip", room, target)
			room:askForCard(target, "EquipCard!", "@fengwang_askforequip")
		else
			sendLog("#fengwang_discard", room, target)
			if dummy:getSubcards():length() > 0 then room:throwCard(dummy, target, target) end
		end
	end,
}
fengwangVS = sgs.CreateViewAsSkill {
	name = "fengwang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = fengwangCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fengwang")
	end,
}
--新风王结界
newfengwangCard = sgs.CreateSkillCard {
	name = "newfengwang",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and
		not to_select:isKongcheng()                                                                        --and to_select:hasEquip()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:hasEquip() then
			room:setPlayerCardLimitation(target, "use", "Jink", true)
			room:addPlayerMark(target, "&newfengwang+to+#" .. source:objectName() .. "-Clear")
			return false
		end
		local dest = sgs.QVariant()
		dest:setValue(target)
		local choice = room:askForChoice(source, self:objectName(), "newfengwang_discard+newfengwang_equip", dest)
		if choice == "newfengwang_equip" then
			room:loseHp(target)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:deleteLater()
			for _, equip in sgs.qlist(target:getEquips()) do
				dummy:addSubcard(equip:getEffectiveId())
			end
			room:obtainCard(target, dummy)
		else
			room:addPlayerMark(target, "&newfengwang+to+#" .. source:objectName() .. "-Clear")
			room:setPlayerCardLimitation(target, "use", "Jink", true)
		end
	end,
}
newfengwangVS = sgs.CreateViewAsSkill {
	name = "newfengwang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = newfengwangCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#newfengwang")
	end,
}

--王者
wangzheCard = sgs.CreateSkillCard {
	name = "wangzhe",
	will_throw = true,
	feasible = function(self, targets)
		return #targets ~= 0
	end,
	filter = function(self, targets, to_select)
		local rangefix = 0
		if sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = card:getRange() - sgs.Self:getAttackRange(false)
		end
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		return sgs.Self:canSlash(to_select, slash, true, rangefix, Table2Playerlist(targets)) and
		#targets < (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, slash))
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "wangzhe_used", 1)
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		local use = sgs.CardUseStruct(slash, source, Table2SPlayerlist(targets), false)
		room:useCard(use, false)
	end,
}
wangzheVS = sgs.CreateViewAsSkill {
	name = "wangzhe",
	n = 1,
	view_filter = function(self, selected, to_select)
		return sgs.Self:getMark(self:objectName()) == 0 and #selected < 1 and
		sgs.Self:canDiscard(sgs.Self, to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = wangzheCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		return player:getMark("wangzhe_used") < 1 and not player:isLocked(slash)
	end,
}
wangzhe = sgs.CreateTriggerSkill {
	name = "wangzhe",
	frequency = sgs.Skill_Limited,
	view_as_skill = wangzheVS,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		return false
	end,
}
wangzheEX = sgs.CreateTargetModSkill {
	name = "#wangzhe",
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and card:getSkillName() == "wangzhe" then
			return 2
		end
	end,
}
extension:insertRelatedSkills("wangzhe", "#wangzhe")
--二刀流
--[[doubleslash = sgs.CreateTriggerSkill{
	name = "doubleslash",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.play_animation = false
				judge.who = player
				room:judge(judge)
				if judge.card:isRed() then
					sendLog("#doubleslash_red",room,player)
					room:setPlayerFlag(player, "doubleslashred")
					room:broadcastSkillInvoke("doubleslash", 1)
				elseif judge.card:isBlack() then
					sendLog("#doubleslash_black",room,player)
					room:setPlayerFlag(player, "doubleslashblack")
					room:broadcastSkillInvoke("doubleslash", 2)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:hasFlag("doubleslashred") then room:setPlayerFlag(player, "-doubleslashred") end
				if player:hasFlag("doubleslashblack") then room:setPlayerFlag(player, "-doubleslashblack") end
			end
		end
		return false
	end
}]] --
doubleslash = sgs.CreateTriggerSkill {
	name = "doubleslash",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(1)
				if player:canDiscard(player, "h") then
					local card = room:askForCard(player, ".|.|.|hand!", "@doubleslash", data, self:objectName())
					if card:isRed() then
						sendLog("#doubleslash_red", room, player)
						room:setPlayerFlag(player, "doubleslashred")
						room:broadcastSkillInvoke("doubleslash", 1)
						room:addPlayerMark(player, "&doubleslash_red-Clear")
					elseif card:isBlack() then
						sendLog("#doubleslash_black", room, player)
						room:setPlayerFlag(player, "doubleslashblack")
						room:broadcastSkillInvoke("doubleslash", 2)
						room:addPlayerMark(player, "&doubleslash_black-Clear")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:hasFlag("doubleslashred") then room:setPlayerFlag(player, "-doubleslashred") end
				if player:hasFlag("doubleslashblack") then room:setPlayerFlag(player, "-doubleslashblack") end
			end
		end
		return false
	end
}
doubleslashMod = sgs.CreateTargetModSkill {
	name = "#doubleslashMod",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("doubleslash") and player:hasFlag("doubleslashred") then
			return 1
		end
	end,
	extra_target_func = function(self, from, card)
		if from:hasSkill("doubleslash") and from:hasFlag("doubleslashblack") then
			return 1
		end
	end,
}
extension:insertRelatedSkills("doubleslash", "#doubleslashMod")
--封弊者
betacheater = sgs.CreateTriggerSkill {
	name = "betacheater",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local hide = player:getPile("hide")
			if player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
				local ids = sgs.IntList()
				for _, card in sgs.qlist(player:getHandcards()) do
					ids:append(card:getId())
				end
				sendLog("#betacheater_movetopile", room, player)
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				player:addToPile("hide", ids, false)
			elseif player:getPhase() == sgs.Player_RoundStart and player:getPile("hide"):length() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, card_id in sgs.qlist(hide) do
					dummy:addSubcard(card_id)
				end
				dummy:deleteLater()
				sendLog("#betacheater_movetohand", room, player)
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:obtainCard(player, dummy, false)
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local hurt = damage.damage
			local hide = player:getPile("hide")
			local num = 0
			if not hide:isEmpty() then room:broadcastSkillInvoke(self:objectName(), math.random(3, 6)) end
			if hurt >= hide:length() then
				player:clearOnePrivatePile("hide")
				damage.damage = damage.damage - hide:length()
				num = num + hide:length()
			else
				for i = 1, hurt, 1 do
					hide = player:getPile("hide")
					if not hide:isEmpty() then
						room:fillAG(hide, player)
						local card_id = room:askForAG(player, hide, false, self:objectName())
						room:throwCard(card_id, player)
						room:clearAG()
						damage.damage = damage.damage - 1
						num = num + 1
					else
						break
					end
				end
			end
			sendLog("#betacheater_damage", room, player, num, damage.damage)
			if damage.damage < 1 then return true end
			data:setValue(damage)
		end
	end
}

--音速手刃
handsonicCard = sgs.CreateSkillCard
	{
		name = "handsonicCard",
		target_fixed = true,
		on_use = function(self, room, player)
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (not p:getArmor()) then
					targets:append(p)
				end
			end
			if (not targets:isEmpty()) then
				for _, t in sgs.qlist(targets) do
					local card = room:askForExchange(t, "handsonic", 1, 1, true,
						"@handsonicPush::" .. player:objectName(), true)
					if (card) then
						player:addToPile("rank", card:getEffectiveId())
					else
						if (t:isNude()) then
							continue
						end
						local card_id = room:askForCardChosen(player, t, "he", "handsonic")
						room:throwCard(card_id, t, player)
					end
				end
				if (player:getPile("rank"):length() >= 3) then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(player:getPile("rank"))
					room:obtainCard(player, dummy)
					room:broadcastSkillInvoke("rank")
					dummy:deleteLater()
				end
			end
		end,
	}

handsonic = sgs.CreateOneCardViewAsSkill
	{
		name = "handsonic",
		view_filter = function(self, to_select)
			return to_select:isKindOf("BasicCard")
		end,
		view_as = function(self, card)
			local handsonicCard = handsonicCard:clone()
			handsonicCard:addSubcard(card)
			return handsonicCard
		end,
		enabled_at_play = function(self, player)
			return not player:hasUsed("#handsonicCard")
		end,
	}

--高频咆哮
howlingCard = sgs.CreateSkillCard {
	name = "howlingCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local list = room:getOtherPlayers(source)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(list) do
			if source:inMyAttackRange(p) then targets:append(p) end
		end
		if targets:isEmpty() then return false end
		for _, p in sgs.qlist(targets) do
			if not room:askForCard(p, "Slash,Jink", "@howlingask", sgs.QVariant(), sgs.Card_MethodResponse) then
				room:damage(sgs.DamageStruct("howling", source, p))
			end
		end
	end,
}
howling = sgs.CreateOneCardViewAsSkill {
	name = "howling",
	view_filter = function(self, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local howlingCard = howlingCard:clone()
		howlingCard:addSubcard(cards)
		return howlingCard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#howlingCard")
	end
}

--防御结界
defencefield = sgs.CreateTriggerSkill {
	name = "defencefield",
	events = { sgs.CardAsked },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return end
		local Yoshinos = room:findPlayersBySkillName(self:objectName())
		--if not Yoshino then return false end
		for _, Yoshino in sgs.qlist(Yoshinos) do
			if not Yoshino:isNude() then
				--if room:askForSkillInvoke(Yoshino, self:objectName(), data) then
				room:setPlayerFlag(player, "defencefield_Target")
				local id = room:askForCard(Yoshino, ".|red", "@defencefieldask", data, self:objectName())
				room:setPlayerFlag(player, "-defencefield_Target")
				if id then
					local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
					jink:setSkillName(self:objectName())
					room:provide(jink)
					return true
				end
				--end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--冰冻傀儡
frozenpuppetCard = sgs.CreateSkillCard {
	name = "frozenpuppetCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:doSuperLightbox("Yoshino", "$frozenpuppetQP")
		source:loseMark("@frozenpuppet")
		source:throwAllHandCards()
		room:addPlayerMark(target, "@frozenpuppettarg")
		target:setTag("frozenpuppettarg", sgs.QVariant(source:objectName()))
	end
}
frozenpuppetVS = sgs.CreateZeroCardViewAsSkill {
	name = "frozenpuppet",
	view_as = function(self, cards)
		local card = frozenpuppetCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@frozenpuppet") > 0 and player:getHandcardNum() >= 1
	end,
}
frozenpuppet = sgs.CreateTriggerSkill {
	name = "frozenpuppet",
	frequency = sgs.Skill_Limited,
	limit_mark = "@frozenpuppet",
	events = { sgs.CardEffected, sgs.TurnStart, sgs.Death },
	view_as_skill = frozenpuppetVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.from and effect.to and effect.to:getMark("@frozenpuppettarg") > 0 then
				if effect.from:objectName() ~= effect.to:objectName() and effect.card and not effect.card:isKindOf("SkillCard") then
					return true
				end
			end
			return false
		end

		local Yoshino = player
		if event == sgs.Death then
			Yoshino = data:toDeath().who
		end
		if Yoshino:hasSkill(self:objectName()) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getTag("frozenpuppettarg"):toString() == Yoshino:objectName() then
					room:setPlayerMark(p, "@frozenpuppettarg", 0)
					p:setTag("frozenpuppettarg", sgs.QVariant(""))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
frozenpuppetPS = sgs.CreateProhibitSkill {
	name = "#frozenpuppetPS",
	is_prohibited = function(self, from, to, card)
		if to:getMark("@frozenpuppettarg") > 0 and from:objectName() ~= to:objectName() then
			return card:isKindOf("DelayedTrick")
		end
	end
}
extension:insertRelatedSkills("frozenpuppet", "#frozenpuppetPS")
--初始之音
chuszy = sgs.CreateTriggerSkill {
	name = "chuszy",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local current = room:getCurrent()
			local damage = data:toDamage()
			if not current or current:isDead() then return end
			if not damage.to or damage.to:isDead() or damage.to:getMark("chuszy-" .. current:getPhase() .. "Clear") > 0 then return end
			room:addPlayerMark(damage.to, "chuszy-" .. current:getPhase() .. "Clear")
			local chuyins = room:findPlayersBySkillName(self:objectName())
			for _, chuyin in sgs.qlist(chuyins) do
				if chuyin:isNude() or damage.to:isDead() or not damage.to:isWounded() then continue end
				--local d = sgs.QVariant()
				--d:setValue(damage.to)
				--if not room:askForSkillInvoke(chuyin,self:objectName(),d) then return false end
				--room:setTag("CurrentDamageStruct", data)
				local prompt = string.format("@chuszy_askforcard:%s", damage.to:objectName())
				local discard = room:askForDiscard(chuyin, self:objectName(), 1, 1, true, true, prompt)
				if discard then
					room:broadcastSkillInvoke("chuszy")
					room:recover(player, sgs.RecoverStruct(chuyin))
					room:addPlayerMark(player, "&chuszy+to+#" .. chuyin:objectName() ..
					"-" .. current:getPhase() .. "Clear")
				end

				--room:removeTag("CurrentDamageStruct")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--消失
htms_xiaoshi = sgs.CreateTriggerSkill {
	name = "htms_xiaoshi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = player:getRoom()
		if death.who:objectName() ~= player:objectName() or not death.who:hasSkill(self:objectName()) then return false end
		if death.damage and death.damage.from then
			sendLog("#htms_xiaoshi", room, death.damage.from)
			death.damage.from:throwAllEquips()
			room:loseMaxHp(death.damage.from)
			room:broadcastSkillInvoke("htms_xiaoshi", math.random(1, 2))
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--灭杀
miecard = sgs.CreateSkillCard {
	name = "mie",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if player:getMark("@Luazuihou") > 0 then
			return #targets < 1 and to_select:objectName() ~= player:objectName() and not to_select:isNude()
		else
			return #targets < 1 and to_select:objectName() ~= player:objectName() and player:canDiscard(to_select, "he")
		end
	end,
	on_use = function(self, room, source, targets)
		local id = room:askForCardChosen(source, targets[1], "he", "mie")
		if source:getMark("@Luazuihou") > 0 then
			room:obtainCard(source, id, false)
		else
			room:throwCard(id, targets[1], source)
		end
	end
}

mie = sgs.CreateViewAsSkill {
	name = "mie",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("@Luazuihou") > 0 then
			return true
		end
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local acard = miecard:clone()
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#mie")) or (player:getMark("@Luazuihou") > 0 and player:usedTimes("#mie") < 2)
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}
mie_EX = sgs.CreateViewAsSkill {
	name = "mie_EX",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("@Luazuihou") > 0 then
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local acard = miecard:clone()
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@Luazuihou") > 0 and player:usedTimes("#mie") < 2)
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

--最后之剑
Luazuihou = sgs.CreateTriggerSkill {
	name = "Luazuihou",
	frequency = sgs.Skill_Wake,
	events = { sgs.HpChanged, sgs.MaxHpChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHp() == 1 and player:getMark("@Luazuihou") == 0 then
			player:gainMark("@Luazuihou")
			if player:getMaxHp() > 1 then
				room:loseMaxHp(player, player:getMaxHp() - 1)
				room:broadcastSkillInvoke("Luazuihou")
			end
			--room:detachSkillFromPlayer(player, "mie", true)
			--[[	local ip = room:getOwner():getIp()
			if ip ~= "" and string.find(ip, "127.0.0.1") then --联机状态时切换BGM无效
				sgs.Sanguosha:addTranslationEntry(":mie", "<font color=\"green\"><b>出牌阶段限两次，</b></font>你可以弃置一张牌并选择一名其他角色，你获得其一张牌。")
				room:acquireSkill(player, "mie")
			else
				room:acquireSkill(player, "mie_EX")
			end]]
			-- sgs.Sanguosha:addTranslationEntry(":mie", "<font color=\"green\"><b>出牌阶段限两次，</b></font>你可以弃置一张牌并选择一名其他角色，你获得其一张牌。")
			-- 	room:acquireSkill(player, "mie")
			local translate = sgs.Sanguosha:translate(":mie_EX")
			room:changeTranslation(player, "mie", 2)
			--player:gainAnExtraTurn()
			room:setPlayerMark(player, "Luazuihou", 1)
			room:setPlayerMark(player, "zuihou", 1)
			room:throwEvent(sgs.TurnBroken)
		end
	end
}
Luazuihouturn = sgs.CreateTriggerSkill {
	name = "#Luazuihouturn",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:findPlayersBySkillName(self:objectName()):isEmpty() then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if not room:findPlayerBySkillName(self:objectName()) then return false end
			local s = room:findPlayerBySkillName(self:objectName())
			if s and change.from == sgs.Player_NotActive then
				if s:getMark("zuihou") > 0 then
					room:setPlayerMark(s, "zuihou", 0)
					s:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return true
	end
}

Luabei1 = sgs.CreateAttackRangeSkill {
	name = "#Luabei1",
	extra_func = function(self, player, include_weapon)
		if player:getMark("@Luazuihou") > 0 then
			return 2
		end
	end
}

Luabei2 = sgs.CreateMaxCardsSkill {
	name = "#Luabei2",
	extra_func = function(self, player)
		if player:getMark("@Luazuihou") > 0 then
			return 2
		end
	end
}
extension:insertRelatedSkills("Luazuihou", "#Luabei1")
extension:insertRelatedSkills("Luazuihou", "#Luabei2")
extension:insertRelatedSkills("Luazuihou", "#Luazuihouturn")
--舰载
Luajianzai = sgs.CreateTriggerSkill {
	name = "Luajianzai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("FirstRound"):toBool() then return false end
		if player:hasFlag("Luajianzai") then
			player:setFlags("-Luajianzai")
			return false
		end
		local move = data:toMoveOneTime()
		local dest = move.to
		if dest then
			if dest:objectName() == player:objectName() then
				if move.to_place == sgs.Player_PlaceHand and move.from_places:at(0) == sgs.Player_DrawPile then
					player:setFlags("Luajianzai")
					player:drawCards(1)
					room:broadcastSkillInvoke("Luajianzai", 1)
				end
			end
		end
	end

}
Luajianzai_keep = sgs.CreateTriggerSkill {
	name = "#Luajianzai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		if player:isDead() then return end
		if not player:isKongcheng() then
			local room = player:getRoom()
			room:askForDiscard(player, "Luajianzai", 1, 1, false, false)
			room:broadcastSkillInvoke("Luajianzai", 2)
		end
	end
}
extension:insertRelatedSkills("Luajianzai", "#Luajianzai")
--雷击
leij = sgs.CreateFilterSkill {
	name = "leij",
	view_filter = function(self, card)
		return card:isKindOf("Slash")
	end,
	view_as = function(self, card)
		local ThunderSlash = sgs.Sanguosha:cloneCard("ThunderSlash", card:getSuit(), card:getNumber())
		ThunderSlash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(ThunderSlash)
		return wrap
	end,
}
--[[
leijEx = sgs.CreateTriggerSkill{
	name = "leij",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	priority = 0,
	on_trigger = function(self,event,player,data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder or damage.damage <= 0 then return false end
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player,self:objectName())
		damage.damage = 0
		data:setValue(damage)
		return false
	end,
}]]
leijEx = sgs.CreateTriggerSkill {
	name = "#leij",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Thunder then
			room:notifySkillInvoked(player, "leij")
			room:sendCompulsoryTriggerLog(player, "leij", true)
			return true
		end
		return false
	end,
}


extension:insertRelatedSkills("leij", "#leij")
--电磁炮
diancpcard = sgs.CreateSkillCard {
	name = "diancp",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("diancp", effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
	end
}
diancpvs = sgs.CreateOneCardViewAsSkill {
	name = "diancp",
	filter_pattern = "ThunderSlash",
	view_as = function(self, card)
		local acard = diancpcard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}
diancp = sgs.CreateTriggerSkill {
	name = "diancp",
	events = { sgs.EnterDying },
	view_as_skill = diancpvs,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local damage = dying.damage
		if damage and damage.from and dying.who:objectName() == player:objectName() and damage:getReason() == "diancp" then
			room:loseHp(damage.from)
		end
	end
}
--噩梦
Luaemeng = sgs.CreateTriggerSkill {
	name = "Luaemeng",
	frequency = sgs.Skill_NotFrequent,
	events = sgs.DamageCaused,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Play then return end
		local room = player:getRoom()
		local damage = data:toDamage()
		local to_data = sgs.QVariant()
		to_data:setValue(damage.to)
		if room:askForCard(player, "..", "@emeng", to_data, self:objectName()) then
			room:broadcastSkillInvoke("Luaemeng")
			local msg = sgs.LogMessage()
			msg.type = "#Luaemeng"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = damage.damage
			msg.arg2 = damage.damage + 1
			room:sendLog(msg)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}
--狂犬
kuangquanCard = sgs.CreateSkillCard {
	name = "kuangquanCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:setFlags("kuangquanUsing")
		source:loseMark("@inu_to", 1)
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("kuangquan", source, player))
		end
		for _, player in sgs.qlist(players) do
			room:askForDiscard(player, "kuangquan", 2, 2)
		end
		source:setFlags("-kuangquanUsing")
	end
}
kuangquan = sgs.CreateZeroCardViewAsSkill {
	name = "kuangquan",
	view_as = function()
		return kuangquanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@inu_to") >= 1 and not player:hasUsed("#kuangquanCard")
	end
}
--夜战
Luayezhan = sgs.CreateTriggerSkill {
	name = "Luayezhan",
	frequency = sgs.Skill_Frequent,
	events = sgs.EventPhaseStart,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isGood() then
					room:broadcastSkillInvoke("Luayezhan", 1)
					room:setPlayerFlag(player, "Luayezhan")
					room:addPlayerMark(player, "&Luayezhan-Clear")
				else
					room:broadcastSkillInvoke("Luayezhan", 2)
				end
			end
		end
	end,
}
LuayezhanBuff = sgs.CreateTriggerSkill {
	name = "#LuayezhanBuff",
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.by_user then return false end
		local reason = damage.card
		if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
			local msg = sgs.LogMessage()
			msg.type = "#LuayezhanBuff"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = damage.damage
			msg.arg2 = damage.damage + 1
			room:sendLog(msg)
			room:broadcastSkillInvoke("Luayezhan", 3)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("Luayezhan") and target:isAlive()
	end
}
extension:insertRelatedSkills("Luayezhan", "#LuayezhanBuff")
--加速告白
jiasugaobaiCard = sgs.CreateSkillCard {
	name = "jiasugaobai",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select:isMale()
	end,
	on_effect = function(self, effect)
		effect.to:drawCards(1)
	end
}
jiasugaobaiVS = sgs.CreateViewAsSkill {
	name = "jiasugaobai",
	n = 0,
	view_as = function(self, card)
		local card = jiasugaobaiCard:clone()
		card:setSkillName("jiasugaobai")
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jiasugaobai"
	end
}
jiasugaobai = sgs.CreateTriggerSkill {
	name = "jiasugaobai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming, sgs.CardEffected },
	view_as_skill = jiasugaobaiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") then
				room:setTag("jiasugaobai", data)
				if room:askForUseCard(player, "@@jiasugaobai", "@jiasugaobai") then
					local list = use.no_respond_list
					table.insert(list, player:objectName())
					use.no_respond_list = list
					data:setValue(use)
				end
				room:removeTag("jiasugaobai")
			end
		end
	end,
}
--加速对决
jiasuduijue = sgs.CreateTriggerSkill {
	name = "jiasuduijue",
	events = { sgs.TargetSpecified, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		local useDuel = sgs.CardUseStruct()
		if not use.card or not use.card:isKindOf("Slash") or not use.card:isBlack() then return end
		local Duel = sgs.Sanguosha:cloneCard("Duel", sgs.Card_SuitToBeDecided, 0)
		--[[if not use.card:isVirtualCard() then
			Duel:addSubcard(use.card)
		elseif use.card:subcardsLength() > 0 then
			for _, id in sgs.qlist(use.card:getSubcards()) do
				Duel:addSubcard(id)
			end
		end]]
		Duel:setSkillName(self:objectName())
		Duel:deleteLater()
		if use.from:isCardLimited(Duel, sgs.Card_MethodUse) then return end
		for _, p in sgs.qlist(use.to) do
			if Duel:targetFilter(sgs.PlayerList(), p, use.from) and not room:isProhibited(use.from, p, Duel) then
				useDuel.to:append(p)
			end
		end
		if useDuel.to:isEmpty() or (event == sgs.TargetConfirmed and not (use.to:contains(player) and useDuel.to:contains(player))) then return end
		if player:hasSkill(self:objectName()) and player:askForSkillInvoke(self:objectName(), data) then
			local nullified_list = use.nullified_list
			table.insert(nullified_list, "_ALL_TARGETS")
			use.nullified_list = nullified_list
			data:setValue(use)
			useDuel.card = Duel
			useDuel.from = use.from
			room:useCard(useDuel)
		end
		if event == sgs.TargetSpecified then
			room:broadcastSkillInvoke("jiasuduijue", 2)
		elseif event == sgs.TargetConfirmed then
			room:broadcastSkillInvoke("jiasuduijue", 1)
		end
	end
}
--决斗加速
juedoujiasu = sgs.CreateTriggerSkill {
	name = "juedoujiasu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.TargetSpecified, sgs.CardFinished, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed or event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if not use.card:isKindOf("Duel") then return end
			if event == sgs.TargetConfirmed and not use.to:contains(player) then return end
			--if player:hasSkill(self:objectName()) and player:askForSkillInvoke(self:objectName(),data) then
			if player:hasSkill(self:objectName()) and player:askForSkillInvoke(self:objectName(), data) then
				room:drawCards(player, 1, self:objectName())
				room:setCardFlag(use.card, "jdjs")
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("jdjs") then
				if use.from and use.from:isAlive() then
					use.from:drawCards(use.from:getMark("jdjs"))
					room:setPlayerMark(use.from, "jdjs", 0)
				end
				for _, target in sgs.qlist(use.to) do
					if target:isAlive() then
						target:drawCards(target:getMark("jdjs"))
						room:setPlayerMark(target, "jdjs", 0)
					end
				end
				room:setCardFlag(use.card, "-jdjs")
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("jdjs") then
				--room:setPlayerFlag(player,"jdjs")
				room:addPlayerMark(player, "jdjs", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--蜻蜓切
qingtq = sgs.CreateProhibitSkill {
	name = "qingtq",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Weapon"))
	end
}
qingtq_keep = sgs.CreateTriggerSkill {
	name = "#qingtq",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and player:objectName() == use.from:objectName() then
				if player:isAlive() and player:hasSkill(self:objectName()) then
					local slash = use.card
					if slash:isKindOf("Slash") then
						for _, p in sgs.qlist(use.to) do
							if not p:isKongcheng() then
								room:broadcastSkillInvoke("qingtq", math.random(1, 2))
								room:askForDiscard(p, self:objectName(), 1, 1, false, false)
							end
						end
					end
				end
			end
		end
	end
}
qingtq_keep_keep = sgs.CreateAttackRangeSkill {
	name = "#qingtqAR",
	fixed_func = function(self, player, include_weapon)
		if player:hasSkill("qingtq") then
			local x = 0
			local list = player:getAliveSiblings()
			list:append(player)
			for _, p in sgs.qlist(list) do
				local hp = p:getHp()
				if hp > x then
					x = hp
				end
			end
			return x
		end
	end,
}
extension:insertRelatedSkills("qingtq", "#qingtq")
extension:insertRelatedSkills("qingtq", "#qingtqAR")
--nos翔翼
--[[
xiangyvs = sgs.CreateOneCardViewAsSkill{
	name = "xiangy",
	response_or_use = true,	
	response_pattern = "jink",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
		local jink = sgs.Sanguosha:cloneCard("jink",card:getSuit(),card:getNumber())
        jink:setSkillName(self:objectName());
        jink:addSubcard(card:getId());
        return jink
	end,
}
xiangy = sgs.CreateTriggerSkill{
	name = "xiangy" ,
	view_as_skill = xiangyvs,
	events = {sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (resp.m_card:getSkillName() == "xiangy")then
					player:drawCards(1)
				end
			end
		return false
	end
}
]]
--翔翼
xiangyvs = sgs.CreateOneCardViewAsSkill {
	name = "xiangy",
	response_or_use = true,
	response_pattern = "jink",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
		local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
		jink:setSkillName(self:objectName());
		jink:addSubcard(card:getId());
		return jink
	end,
}
xiangy = sgs.CreateTriggerSkill {
	name = "xiangy",
	view_as_skill = xiangyvs,
	events = { sgs.CardResponded, sgs.CardUsed },
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (resp.m_card:getSkillName() == "xiangy") then
				card = resp.m_card
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if (use.card:getSkillName() == "xiangy") then
				card = use.card
			end
			if card then
				local choice = room:askForChoice(player, "xiangy", "draw1+dis")
				if (choice == "draw1") then
					player:drawCards(1, self:objectName())
				else
					local players = sgs.SPlayerList()
					-- for (ServerPlayer *p, room->getAlivePlayers()) {
					-- 	if (!p->getJudgingArea().isEmpty() || !p->getEquips().isEmpty()) {
					-- 		players.append(p);
					-- 	}
					-- }
					for _, t in sgs.qlist(room:getAlivePlayers()) do
						if not (t:getJudgingArea():isEmpty() and t:getEquips():isEmpty()) then
							players:append(t)
						end
					end

					if (not players:isEmpty()) then
						local to = room:askForPlayerChosen(player, players, "xiangy", "@xiangy-to")
						if (to) then
							local id = room:askForCardChosen(player, to, "ej", "xiangy")
							room:throwCard(id, to, player)
							-- local card = sgs.Sanguosha:getCard(id)
							-- local place = room:getCardPlace(id)

							-- local equip_index = -1
							-- if place == sgs.Player_PlaceEquip then
							-- 	local equip = card:getRealCard():toEquipCard()
							-- 	equip_index = equip:location()
							-- end
							-- local tos = sgs.SPlayerList()
							-- for _, p in sgs.qlist(room:getAlivePlayers()) do
							-- 	if equip_index ~= -1 then
							-- 		if not p:getEquip(equip_index) then
							-- 			tos:append(p)
							-- 		end
							-- 	else
							-- 		if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
							-- 			tos:append(p)
							-- 		end
							-- 	end
							-- end
							-- local tag = sgs.QVariant()
							-- tag:setValue(from)
							-- room:setTag("QiaobianTarget", tag)
							-- local to = room:askForPlayerChosen(player, tos, self:objectName(), "@xiangy-to")
							-- if to then
							-- 	room:moveCardTo(card, from, to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, from:objectName(), self:objectName(), ""))
							-- end
							-- room:removeTag("QiaobianTarget")
						end
					end
				end
			end
		end
		return false
	end
}
--救济的祈愿
jiujideqiyuanCard = sgs.CreateSkillCard {
	name = "jiujideqiyuan",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:isWounded() and #targets < self:getSubcards():length()
	end,
	feasible = function(self, targets)
		return #targets <= self:getSubcards():length() and #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			room:recover(target, sgs.RecoverStruct(source))
		end
	end
}
jiujideqiyuan = sgs.CreateViewAsSkill {
	name = "jiujideqiyuan",
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			return selected[1]:getTypeId() ~= to_select:getTypeId()
		elseif #selected == 2 then
			return selected[1]:getTypeId() ~= to_select:getTypeId() and selected[2]:getTypeId() ~= to_select:getTypeId() and
			selected[1]:getTypeId() ~= selected[2]:getTypeId()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = jiujideqiyuanCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#jiujideqiyuan")
	end
}
--法则缔造	
fazededizao = sgs.CreateTriggerSkill {
	name = "fazededizao",
	events = { sgs.TurnStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local ori_choice = { "fzndz_1", "fzndz_2", "fzndz_3", "fzndz_4" }
		local choices = {}
		for _, effcet in ipairs(ori_choice) do
			if player:getMark(effcet) == 0 then
				table.insert(choices, effcet)
			elseif player:getMark("&fazededizao:" .. effcet) ~= 0 then
				room:setPlayerMark(player, "&fazededizao:" .. effcet, 0)
			end
		end
		if #choices == 0 then
			choices = ori_choice
			for _, effcet in ipairs(ori_choice) do
				room:setPlayerMark(player, effcet, 0)
			end
		end
		table.insert(choices, "cancel")
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
		if choice ~= "cancel" then
			local msg = sgs.LogMessage()
			msg.type = "#fazededizao_type"
			msg.from = player
			msg.arg = choice
			room:sendLog(msg)
			if choice == "fzndz_1" then
				room:broadcastSkillInvoke(self:objectName(), 2)
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 4))
			end
			room:notifySkillInvoked(player, "fazededizao")
			room:setPlayerMark(player, choice, 1)
			room:setPlayerMark(player, "&fazededizao:" .. choice, 1)
			player:setTag("fzndz", sgs.QVariant(choice))
		else
			player:setTag("fzndz", sgs.QVariant())
		end
		return false
	end,
	priority = 5,
}

fzndz_skip = sgs.CreateTriggerSkill {
	name = "fzndz_skip",
	events = { sgs.EventPhaseStart },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local madokas = room:findPlayersBySkillName("fazededizao")
		--if madoka and madoka:objectName() ~= player:objectName() then
		for _, madoka in sgs.qlist(madokas) do
			if madoka:objectName() == player:objectName() then continue end
			local effect = madoka:getTag("fzndz"):toString()
			if effect == "fzndz_1" then
				player:skip(sgs.Player_Judge)
			elseif effect == "fzndz_2" then
				player:skip(sgs.Player_Draw)
			elseif effect == "fzndz_3" then
				player:skip(sgs.Player_Play)
			elseif effect == "fzndz_4" then
				player:skip(sgs.Player_Discard)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getPhase() == sgs.Player_Start
	end,
}
--extension:insertRelatedSkills("fazededizao","fzndz_skip")

--攻略之神
gonglzs = sgs.CreateTriggerSkill {
	name = "gonglzs",
	events = { sgs.TargetConfirmed },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") or not use.to:contains(player) or player:isAllNude() or not player:canDiscard(player, "hej") then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local target = use.from
			local selfcard = room:askForCardChosen(player, player, "jhe", self:objectName())
			local selfplace = room:getCardPlace(selfcard)
			room:throwCard(selfcard, player, player)
			local place_char = false

			if selfplace == sgs.Player_PlaceEquip and not target:getEquips():isEmpty() then
				place_char = "e"
			elseif selfplace == sgs.Player_PlaceHand and not target:isKongcheng() then
				place_char = "h"
			elseif selfplace == sgs.Player_PlaceDelayedTrick and not target:getJudgingArea():isEmpty() then
				place_char = "j"
			end

			if place_char then
				local A = room:askForCardChosen(player, target, place_char, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:obtainCard(player, A, false)
			end
		end
	end --[[,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and not target:isAllNude()
	end,]]
}
--神知
shens = sgs.CreateTriggerSkill {
	name = "shens",
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data, room)
		local dying = data:toDying()
		--if dying.who == player then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local ids = room:getNCards(4)

			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(),
				nil)
			room:moveCardsAtomic(move, true)

			--room:fillAG(ids)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			--room:getThread():delay(2500)
			room:getThread():delay()
			local to_select = sgs.IntList()
			local splitBySuit = function(list)
				local spade, heart, club, diamond = {}, {}, {}, {}
				for _, id in sgs.qlist(list) do
					local suit = sgs.Sanguosha:getCard(id):getSuitString()
					if suit == "spade" then
						table.insert(spade, id)
					elseif suit == "heart" then
						table.insert(heart, id)
					elseif suit == "club" then
						table.insert(club, id)
					elseif suit == "diamond" then
						table.insert(diamond, id)
					end
				end
				return { spade, heart, club, diamond }
			end
			local splitByType = function(t)
				local basic, trick, equip = {}, {}, {}
				for _, id in ipairs(t) do
					local typ = sgs.Sanguosha:getCard(id):getType()
					if typ == "basic" then
						table.insert(basic, id)
					elseif typ == "trick" then
						table.insert(trick, id)
					elseif typ == "equip" then
						table.insert(equip, id)
					end
				end
				return { basic, trick, equip }
			end
			for _, s in ipairs(splitBySuit(ids)) do
				for _, t in ipairs(splitByType(s)) do
					if #t > 1 then
						for _, e in ipairs(t) do
							to_select:append(e)
						end
					end
				end
			end
			if not to_select:isEmpty() then
				room:recover(dying.who, sgs.RecoverStruct(player))
				--room:fillAG(to_select)
				room:fillAG(ids)
				for _, id in sgs.qlist(ids) do
					if not to_select:contains(id) then
						room:takeAG(nil, id, false)
					end
				end
				local card_id = room:askForAG(player, to_select, false, self:objectName())
				--room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_PlaceTable)
				room:takeAG(player, card_id)
				room:clearAG()
			end
			--room:clearAG()
		end
	end
}
--破军歌姬
pojgjCard = sgs.CreateSkillCard {
	name = "pojgjCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:isWounded()) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	feasible = function(self, targets)
		if #targets == 1 then
			return targets[1]:isWounded()
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1] or source
		local effect = sgs.CardEffectStruct()
		effect.card = self
		effect.from = source
		effect.to = target
		room:cardEffect(effect)
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		local room = dest:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:loseHp(effect.from)
		room:recover(dest, recover)
	end
}
pojgj = sgs.CreateViewAsSkill {
	name = "pojgj",
	n = 0,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = pojgjCard:clone()
			card:setSkillName(self:objectName())
			return card
		end
	end,
}
--魂曲
hunq = sgs.CreateTriggerSkill {
	name = "hunq",
	events = { sgs.HpChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "hunq-invoke", true, true)
		s:drawCards(1)
		room:broadcastSkillInvoke("hunq")
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
--目观
LuamuguanCard = sgs.CreateSkillCard {
	name = "LuamuguanCard",
	target_fixed = false,
	will_throw = true,
	skill_name = "LuamuguanVS",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("muguan") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerMark(effect.from, "muguan", 1)
		room:setPlayerMark(effect.to, "muguan", 1)
		room:setFixedDistance(effect.from, effect.to, 1)
		room:setFixedDistance(effect.to, effect.from, 1)
		room:addPlayerMark(effect.to, "&Luamuguan+to+#" .. effect.from:objectName())
	end
}

LuamuguanVS = sgs.CreateViewAsSkill {
	name = "LuamuguanVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local muguan_card = LuamuguanCard:clone()
		muguan_card:addSubcard(cards[1])
		muguan_card:setSkillName(self:objectName())
		return muguan_card
	end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
}
Luamuguan = sgs.CreateTriggerSkill {
	name = "#Luamuguan",
	frequency = sgs.Skill_Compulsory,
	events = sgs.EventPhaseStart,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("muguan") > 0 then
			room:removePlayerMark(player, "muguan", 1)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("muguan") > 0 then
					room:removeFixedDistance(p, player, 1)
					room:removeFixedDistance(player, p, 1)
					player:loseMark("muguan")
					p:loseMark("muguan")
					room:setPlayerMark(p, "&Luamuguan+to+#" .. player:objectName(), 0)
				end
			end
		end
	end
}
LuamuguanBuff = sgs.CreateTriggerSkill {
	name = "#LuamuguanBuff",
	frequency = sgs.Skill_Compulsory,
	events = sgs.DamageInflicted,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.from then return false end
		if damage.from:getMark("muguan") > 0 and damage.to:getMark("muguan") > 0 then
			if damage.from:objectName() == damage.to:objectName() then return false end
			local num = damage.from:getMark("muguan")
			if damage.from:hasSkill("#LuamuguanBuff") or damage.to:hasSkill("#LuamuguanBuff") then
				damage.damage = damage.damage + num
				local log = sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = "LuamuguanVS"
				log.arg2 = damage.damage
				room:sendLog(log)
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("LuamuguanVS", "#Luamuguan")
extension:insertRelatedSkills("LuamuguanVS", "#LuamuguanBuff")
--魂火
soulfireViewAsSkill = sgs.CreateOneCardViewAsSkill {
	name = "soulfire",
	view_filter = function(self, card)
		if not card:isKindOf("BasicCard") then return false end
		if card:isKindOf("Peach") then return false end
		if card:isKindOf("Analeptic") then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local FireSlash = sgs.Sanguosha:cloneCard("FireSlash", sgs.Card_SuitToBeDecided, -1)
			FireSlash:addSubcard(card:getEffectiveId())
			FireSlash:deleteLater()
			return FireSlash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, originalCard)
		local FireSlash = sgs.Sanguosha:cloneCard("FireSlash", originalCard:getSuit(), originalCard:getNumber())
		FireSlash:addSubcard(originalCard:getId())
		FireSlash:setSkillName(self:objectName())
		return FireSlash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}

soulfire = sgs.CreateTriggerSkill {
	name = "soulfire",
	view_as_skill = soulfireViewAsSkill,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:getSkillName() == "soulfire" and damage.to:getSeat() ~= player:getSeat() then
			if damage.to:isNude() then return false end
			room:askForDiscard(damage.to, "soulfire", 1, 1, false, true)
			if room:askForSkillInvoke(player, "soulfire", data) and player:getHp() > 0 then
				room:loseHp(damage.from)
				if (not damage.from:isAlive()) then return false end
				local damagea = sgs.DamageStruct()
				damagea.from = player
				damagea.to = damage.to
				damagea.damage = 1
				room:damage(damagea)
			end
			return false
		end
	end,
}
--疾风迅雷
jfxlCard = sgs.CreateSkillCard {
	name = "jfxl",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:throwCard(self:getSubcards():first(), source)
		room:loseHp(source)
		for _, target in sgs.qlist(room:getAlivePlayers()) do
			if target:distanceTo(source) ~= 1 then continue end
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = 1
			room:damage(damage)
		end
	end,
}
jfxl = sgs.CreateViewAsSkill {
	name = "jfxl",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and sgs.Self:canDiscard(sgs.Self, to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local card = jfxlCard:clone()
		card:setSkillName("jfxl")
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#jfxl")
	end,
}
--真红
zhenhong = sgs.CreateOneCardViewAsSkill {
	name = "zhenhong",
	view_filter = function(self, card)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local FireSlash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
			FireSlash:addSubcard(card:getEffectiveId())
			FireSlash:deleteLater()
			return FireSlash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, originalCard)
		local FireSlash = sgs.Sanguosha:cloneCard("fire_slash", originalCard:getSuit(), originalCard:getNumber())
		FireSlash:addSubcard(originalCard:getId())
		FireSlash:setSkillName(self:objectName())
		return FireSlash
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern:contains("slash") or pattern:contains("Slash")) and
		player:getPhase() == sgs.Player_NotActive
	end
}
zhenhongslash = sgs.CreateTriggerSkill {
	name = "zhenhong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.ConfirmDamage, sgs.TargetConfirmed },
	view_as_skill = zhenhong,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirmed then
			if use.card:isKindOf("Slash") and use.card:hasFlag("zhenhongslash") then
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:getHandcardNum() < p:getHandcardNum() then
						local log = sgs.LogMessage()
						log.type = "#skill_cant_jink"
						log.from = player
						log.to:append(p)
						log.arg = self:objectName()
						room:sendLog(log)
						jink_table[index] = 0
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "zhenhong" and damage.from and damage.from:isAlive()  then
				room:throwCard(
				room:askForCardChosen(damage.from, damage.to, "he", "zhenhongslash", false, sgs.Card_MethodDiscard), damage
				.to, damage.from)
				return false
			end
		end
	end,
}
--断罪
duanzui = sgs.CreateTriggerSkill {
	name = "duanzui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("FirstRound"):toBool() then return false end
		local move = data:toMoveOneTime()
		if not move.to then return false end
		local to = room:findPlayerByObjectName(move.to:objectName())
		if to and to:getPhase() == sgs.Player_Draw then return false end
		if move.to_place ~= sgs.Player_PlaceHand then return false end
		local dest = sgs.QVariant()
		dest:setValue(to)
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if source:objectName() ~= to:objectName() and source:inMyAttackRange(to) then
				if room:askForSkillInvoke(source, self:objectName(), dest) then
					room:broadcastSkillInvoke("duanzui")
					local damage = sgs.DamageStruct()
					damage.from = source
					damage.to = to
					damage.damage = 1
					damage.nature = sgs.DamageStruct_Fire
					room:damage(damage)
				end
			end
		end
	end
}
--天破壤碎
tprs = sgs.CreateTriggerSkill {
	name = "tprs",
	frequency = sgs.Skill_Limited,
	limit_mark = "@tprs",
	events = { sgs.EventPhaseStart, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getMark("@tprs") > 0 then
			local targets_list = sgs.SPlayerList()
			for _, target in sgs.qlist(room:getOtherPlayers(player)) do
				if player:distanceTo(target) <= 1 then
					targets_list:append(target)
				end
			end
			if targets_list:length() > 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:setPlayerMark(player, "@tprs", 0)
					room:setPlayerMark(player, "tprs", player:getHp() - 1)
					room:setPlayerProperty(player, "hp", sgs.QVariant(1))
					room:broadcastSkillInvoke("tprs")
					local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
					slash:deleteLater()
					slash:setSkillName("tprs")
					room:useCard(sgs.CardUseStruct(slash, player, targets_list))
					for _, target in sgs.qlist(room:getOtherPlayers(player)) do
						if not targets_list:contains(target) and player:inMyAttackRange(target) then
							local damage = sgs.DamageStruct()
							damage.from = player
							damage.to = target
							damage.damage = 1
							damage.nature = sgs.DamageStruct_Fire
							room:damage(damage)
						end
					end
					room:handleAcquireDetachSkills(player, "duanzui")
				end
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "tprs" then
				damage.damage = damage.damage + player:getMark("tprs")
				sendLog("#skill_add_damage", room, damage.from, self:objectName(), damage.damage, damage.to)
				data:setValue(damage)
			end
		end
	end,
}
--魅惑
meihuomoyan = sgs.CreateTriggerSkill {
	name = "meihuomoyan",
	events = { sgs.CardUsed, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.to:length() ~= 1 then return end
			if use.card:isKindOf("SkillCard") or use.card:isKindOf("EquipCard") or use.card:isKindOf("DelayedTrick") then return end
			local targets = sgs.SPlayerList()
			for _, all in sgs.qlist(room:getAllPlayers()) do
				if use.card:targetFilter(sgs.PlayerList(), all, use.from) and not room:isProhibited(use.from, all, use.card) then
					targets:append(all)
				end
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill(self:objectName()) and use.from:getMark("mhmy" .. p:objectName()) == 0 then
					if p:askForSkillInvoke(self:objectName(), data) then
						for _, to in sgs.qlist(use.to) do
							use.to:removeOne(to)
						end
						room:setTag("CurrentUseStruct", data)
						local target = room:askForPlayerChosen(p, targets, self:objectName(),
							"meihuomoyaninvoke:" .. use.card:objectName(), true, true)
						room:removeTag("CurrentUseStruct")
						if target then
							use.to:append(target)
						end
						room:addPlayerMark(use.from, "mhmy" .. p:objectName())
						room:addPlayerMark(use.from, "&meihuomoyan+to+#" .. p:objectName())
						room:setCardFlag(use.card, self:objectName())
						data:setValue(use)
						room:broadcastSkillInvoke("meihuomoyan")
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:hasSkill(self:objectName()) and damage.from:getMark("mhmy" .. damage.to:objectName()) > 0 then
				room:setPlayerMark(damage.from, "mhmy" .. damage.to:objectName(), 0)
				room:setPlayerMark(damage.from, "&meihuomoyan+to+#" .. damage.to:objectName(), 0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--千变万化镜
kaleidoscope = sgs.CreateTriggerSkill {
	name = "kaleidoscope",
	events = { sgs.EventPhaseStart, sgs.GameStart },
	on_trigger = function(self, event, player, data, room)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			local detachList = {}
			for _, skill in sgs.qlist(p:getVisibleSkillList()) do
				if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
					table.insert(detachList, skill:objectName())
				end
			end
			if #detachList > 0 then
				targets:append(p)
			end
		end
		if (event == sgs.GameStart or (event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_NotActive))) and not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@kaleidoscope", true, true)
			if target then
				local skills = {}
				room:broadcastSkillInvoke(self:objectName())
				for _, skill in sgs.qlist(target:getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
						table.insert(skills, skill:objectName())
					end
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(skills, "+"))
				local name = ""
				for _, m in sgs.list(player:getMarkNames()) do
					if player:getMark(m) > 0 and string.find(m, "kaleidoscope") then
						room:removePlayerMark(player, m)
						local new = string.sub(m, 13, string.len(m))
						if new ~= choice then
							name = "|-" .. new
						end
					end
				end
				room:handleAcquireDetachSkills(player, choice .. name)
				room:addPlayerMark(player, "kaleidoscope" .. choice)
			end
		end
	end
}
--赝造魔女
haniel = sgs.CreateTriggerSkill {
	name = "haniel",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.EventAcquireSkill, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:getMark(self:objectName()) > 0 then
				room:removePlayerMark(player, self:objectName())
				for _, skill in sgs.qlist(player:getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and skill:objectName() ~= self:objectName() then
						room:removePlayerMark(player, "Qingcheng" .. skill:objectName())
					end
				end
			end
			if not room:askForCard(player, "..", "@haniel", data, self:objectName()) then
				room:addPlayerMark(player, self:objectName())
				player:drawCards(1, self:objectName())
				for _, skill in sgs.qlist(player:getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and skill:objectName() ~= self:objectName() then
						room:addPlayerMark(player, "Qingcheng" .. skill:objectName())
					end
				end
			end
		end
		if event == sgs.EventAcquireSkill and player:getMark(self:objectName()) > 0 then
			room:addPlayerMark(player, "Qingcheng" .. data:toString())
		end
		if event == sgs.EventLoseSkill and player:getMark(self:objectName()) > 0 then
			room:removePlayerMark(player, "Qingcheng" .. data:toString())
		end
	end
}

--观察
guanchaCard = sgs.CreateSkillCard {
	name = "guancha",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and self:getSubcards():length() == (math.floor((sgs.Self:getHandcardNum() + 1) / 2)) and
		to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1 and self:getSubcards():length() == math.floor((sgs.Self:getHandcardNum() + 1) / 2)
	end,
	on_use = function(self, room, source, targets)
		targets[1]:obtainCard(self, false)
		local recover = sgs.RecoverStruct(source, nil, 1)
		room:recover(source, recover)
	end,
}
guancha = sgs.CreateViewAsSkill {
	name = "guancha",
	n = 999,
	view_filter = function(self, selected, to_select)
		return #selected < math.floor((sgs.Self:getHandcardNum() + 1) / 2) and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = guanchaCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and not player:hasUsed("#guancha")
	end,
}
--畸意技能卡
jiyiCard = sgs.CreateSkillCard {
	name = "jiyi",
	target_fixed = true,
	feasible = function(self)
		return true
	end,
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		local card_ids = room:getNCards(4)
		local to_get = sgs.IntList()
		for i = 1, 2, 1 do
			room:fillAG(card_ids, source)
			local choice = room:askForAG(source, card_ids, false, self:objectName())
			room:clearAG()
			card_ids:removeOne(choice)
			to_get:append(choice)
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(to_get)
		source:obtainCard(dummy, false)
		dummy:deleteLater()
		local choice = room:askForChoice(source, self:objectName(), "jiyi_throw+jiyi_guanxing")
		if choice == "jiyi_throw" then
			dummy:clearSubcards()
			dummy:addSubcards(card_ids)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(),
				self:objectName(), "")
			room:throwCard(dummy, reason, nil, source)
		else
			room:askForGuanxing(source, card_ids, sgs.Room_GuanxingUpOnly)
		end
	end,
}
--畸意
jiyiVS = sgs.CreateZeroCardViewAsSkill {
	name = "jiyi",
	response_pattern = "@@jiyi",
	view_as = function(self)
		local card = jiyiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
}
jiyi = sgs.CreateTriggerSkill {
	name = "jiyi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.HpRecover },
	view_as_skill = jiyiVS,
	on_trigger = function(self, event, player, data)
		if player:getHp() < 1 then return false end
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:askForUseCard(player, "@@jiyi", "@jiyi")
		end
	end,
}

--一航
Luayihang = sgs.CreateDistanceSkill {
	name = "Luayihang",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -1
		end
	end
}
Luayihangpai = sgs.CreateMaxCardsSkill {
	name = "#Luayihangpai",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			local x = target:getLostHp()
			return 2 * x
		end
		return 0
	end
}

--吃撑
Luachicheng = sgs.CreateTriggerSkill {
	name = "Luachicheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke("Luachicheng")
			room:addPlayerMark(player, "&Luachicheng-Clear")
			room:setPlayerCardLimitation(player, "use", "Slash", true)
			draw.num = draw.num + 2
			data:setValue(draw)
		end
	end
}
--主角修正 (惨遭肯神毒手，现已成为单挑历史)
zhujuexzCard = sgs.CreateSkillCard {
	name = "zhujuexz",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source)
		local x = 0
		local num = 0
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(),
			"")
		for _, card_id in sgs.qlist(self:getSubcards()) do
			x = x + sgs.Sanguosha:getCard(card_id):getNumber()
		end
		local dummy = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		while num <= x do
			local card_id = room:getNCards(1):first()
			num = num + sgs.Sanguosha:getCard(card_id):getNumber()
			dummy:addSubcard(card_id)
			room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_PlaceTable, reason)
			room:getThread():delay(500)
		end
		room:obtainCard(source, dummy)
		dummy:deleteLater()
	end,
}
zhujuexz = sgs.CreateViewAsSkill {
	name = "zhujuexz",
	n = 999,
	view_filter = function(self, selected, to_select)
		return sgs.Self:canDiscard(sgs.Self, to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local vs_card = zhujuexzCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zhujuexz")
	end,
}
--轮回的宿命
lunhui1 = sgs.CreateTriggerSkill {
	name = "#lunhui1",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				if not player:askForSkillInvoke("lunhui1", data) then return end
				room:broadcastSkillInvoke("lunhui")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and judge:isGood() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				room:drawCards(player, 1, self:objectName())
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill("lunhui") and target:getPhase() == sgs.Player_NotActive
	end
}

lunhuivs = sgs.CreateViewAsSkill {
	name = "lunhui",
	n = 1,
	expand_pile = "lunhui",
	view_filter = function(self, selected, to_select)
		local pat = ".|.|.|lunhui"
		return sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local acard = sgs.Sanguosha:getCard(cards[1]:getEffectiveId())
			acard:addSubcard(cards[1])
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@lunhui"
	end
}

lunhui = sgs.CreateTriggerSkill {
	name = "lunhui",
	events = { sgs.CardsMoveOneTime },
	view_as_skill = lunhuivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then return false end
		local move = data:toMoveOneTime()
		local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if (flag == sgs.CardMoveReason_S_REASON_DISCARD) and (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName()
				and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
			local will_use = sgs.IntList()
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isAvailable(player) and card:isRed() then
					if card:isKindOf("Jink") or card:isKindOf("Nullification") or (card:isKindOf("Peach") and not player:isWounded()) then
						continue
					else
						will_use:append(id)
					end
				end
			end
			if not will_use:isEmpty() then
				player:addToPile("lunhui", will_use)
				while not player:getPile("lunhui"):isEmpty() do
					local use = room:askForUseCard(player, "@@lunhui", "@lunhui")
					if use then
					else
						break
					end
				end

				if not player:getPile("lunhui"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, cd in sgs.qlist(player:getPile("lunhui")) do
						dummy:addSubcard(cd)
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil,
						self:objectName(), "")
					room:throwCard(dummy, reason, nil)
				end
			end
		end
	end
}


extension:insertRelatedSkills("lunhui", "#lunhui1")

--破除的束缚
pocdsfcard = sgs.CreateSkillCard {
	name = "pocdsf",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "POIPC")
		local n = 0
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			local weapon = p:getWeapon()
			if weapon then
				n = n + 1
				room:throwCard(weapon:getRealCard(), p, source)
			end
		end
		if n > 0 and not source:isNude() then
			local hands = source:getCards("he"):length()
			if hands <= n then
				source:throwAllHandCardsAndEquips()
			else
				room:askForDiscard(source, self:objectName(), n, n, false, true)
			end
		end
	end,
}
pocdsf = sgs.CreateZeroCardViewAsSkill {
	name = "pocdsf",
	view_as = function(self)
		local card = pocdsfcard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, target)
		return not target:hasFlag("POIPC")
	end
}
--合法萝莉
lolita = sgs.CreateTriggerSkill {
	name = "lolita",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (not use.from) or use.from:isDead() then return end
		if use.to:length() ~= 1 then return end
		if use.card and use.card:isKindOf("Slash") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				local uslash = false
				if p:hasSkill(self:objectName()) and (not use.to:contains(p)) and use.from:objectName() ~= p:objectName() then
					for _, i in sgs.qlist(use.to) do
						if i:inMyAttackRange(p) then
							uslash = true
						end
					end
					if (not room:isProhibited(player, p, use.card)) and uslash then
						targets:append(p)
					end
				end
			end
			if not targets:isEmpty() then
				for _, target in sgs.qlist(targets) do
					use.to:append(target)
				end
				data:setValue(use)
				room:broadcastSkillInvoke("lolita", math.random(1, 2))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--犹超级大
judas = sgs.CreateTriggerSkill {
	name = "judas",
	frequency = sgs.Skill_Frequent,
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local room = player:getRoom()
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					if not room:askForUseSlashTo(player, use.from, "@judaseffect:" .. use.from:objectName(), false) then
						player:drawCards(1)
					end
					room:broadcastSkillInvoke("judas")
				end
			end
		end
	end
}
--原典
yuandian = sgs.CreateTriggerSkill {
	name = "yuandian",
	events = { sgs.BuryVictim },
	frequency = sgs.Skill_Compulsory,
	priority = -2,
	can_trigger = function(target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = player:getRoom()
		if death.damage and death.damage.from and death.damage.from:hasSkill(self:objectName()) then
			local x = death.damage.from:getAttackRange()
			room:broadcastSkillInvoke("yuandian")
			death.damage.from:drawCards(2 * x, self:objectName())
		end
		return false
	end,
}
--魔性
--[[
moxingCard = sgs.CreateSkillCard{
	name = "moxing",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return to_select:getMark("moxing") > 0
	end,
	feasible = function(self,targets)
		return #targets == 1 and sgs.Self:canSlash(targets[1],sgs.Sanguosha:getCard(self:getSubcards():first()))
	end,
	on_use = function(self,room,source,targets)
		targets[1]:setFlags("moxing_effect")
		for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
			room:addPlayerMark(targets[1],"Qingcheng"..skill:objectName())
			
		end
		local use = sgs.CardUseStruct()
		use.from = source
		use.to:append(targets[1])
		use.card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:useCard(use,false)
	end,
}
moxingVS = sgs.CreateViewAsSkill{
	name = "moxing",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self,cards)
		if #cards < 1 then return nil end
		local card = moxingCard:clone()
		card:setSkillName("moxing")
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "@@moxing"
	end,
}
moxing = sgs.CreateTriggerSkill{
	name = "moxing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged,sgs.EventPhaseEnd,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	view_as_skill = moxingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and player:hasSkill(self:objectName()) then
				room:setPlayerMark(damage.from,"moxing",1)
				room:askForUseCard(player,"@@moxing","@moxing")
				room:removePlayerMark(damage.from,"moxing")
			end
		end
		if event == sgs.EventPhaseEnd then
			if player:hasSkill(self:objectName()) then
				for _,target in sgs.qlist(room:getAlivePlayers()) do
					target:setFlags("-moxing_effect")
					for _,skill in sgs.qlist(target:getVisibleSkillList()) do
						room:removePlayerMark(target,"Qingcheng"..skill:objectName())
					end
				end
			end
		end
		if event == sgs.EventAcquireSkill then
			local str = data:toString()
			if player:hasFlag("moxing_effect") then
				room:setPlayerMark(player,"Qingcheng"..str)
			end
		end
		if event == sgs.EventLoseSkill then
			local str = data:toString()
			room:removePlayerMark(player,"Qingcheng"..str)
		end
    end,
	can_trigger = function(self,target)
		return target
	end,
}]]
moxing = sgs.CreateTriggerSkill {
	name = "moxing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted, sgs.EventPhaseEnd, sgs.EventLoseSkill, sgs.PreCardUsed },
	view_as_skill = moxingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and player:hasSkill(self:objectName()) then
				room:setPlayerMark(player, "moxing", 1)
				--room:askForUseCard(player,"@@moxing","@moxing")
				local prompt = string.format("@moxing:%s", damage.from:objectName())
				local slash = room:askForUseSlashTo(player, damage.from, prompt, false)
				room:removePlayerMark(player, "moxing")
			end
		end
		if (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName())) or (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				if target:getMark("moxing_effect") > 0 then
					room:setPlayerMark(target, "moxing_effect", 0)
					room:setPlayerMark(target, "&moxing+to+#" .. player:objectName(), 0)

					local Qingchenglist = target:getTag("Qingcheng"):toString():split("+")
					if #Qingchenglist == 0 then continue end
					for _, skill_name in pairs(Qingchenglist) do
						room:setPlayerMark(target, "Qingcheng" .. skill_name, 0);
					end
					target:removeTag("Qingcheng")
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:filterCards(p, p:getCards("he"), true)
					end
				end
			end
		end
		if event == sgs.PreCardUsed then
			if not (player:getMark("moxing") > 0) then return false end
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, "moxing_effect", 1)
					room:addPlayerMark(p, "&moxing+to+#" .. use.from:objectName(), 1)
					local skill_list = {}
					local Qingchenglist = p:getTag("Qingcheng"):toString():split("+") or {}
					for _, skill in sgs.qlist(p:getVisibleSkillList()) do
						if (not table.contains(skill_list, skill:objectName())) and not skill:isAttachedLordSkill() then
							table.insert(skill_list, skill:objectName())
						end
					end
					table.removeTable(skill_list, Qingchenglist)
					for _, skill in ipairs(skill_list) do
						table.insert(Qingchenglist, skill)
						p:setTag("Qingcheng", sgs.QVariant(table.concat(Qingchenglist, "+")))
						room:addPlayerMark(p, "Qingcheng" .. skill)
						for _, z in sgs.qlist(room:getAllPlayers()) do
							room:filterCards(z, z:getCards("he"), true)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--祥瑞
xiangruiCard = sgs.CreateSkillCard {
	name = "xiangruiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		return #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}
xiangruiVS = sgs.CreateViewAsSkill {
	name = "xiangrui",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local xiangrui_card = xiangruiCard:clone()
			xiangrui_card:addSubcard(cards[1])
			xiangrui_card:setSkillName(self:objectName())
			return xiangrui_card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xiangrui"
	end,
}
xiangrui = sgs.CreateTriggerSkill {
	name = "xiangrui",
	frequency = sgs.Skill_NotFrequent,
	events = sgs.DamageInflicted,
	view_as_skill = xiangruiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName(), data) then return end
		local damage = data:toDamage()
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|."
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge.card:isRed() then
			damage.damage = damage.damage - 1
			room:broadcastSkillInvoke("xiangrui", 1)
			sendLog("#xiangrui", room, player, damage.damage)
			data:setValue(damage)
			if damage.damage < 1 then
				return true
			end
		elseif judge.card:isBlack() then
			room:askForUseCard(player, "@@xiangrui", "@xiangrui", -1, sgs.Card_MethodNone)
			room:broadcastSkillInvoke("xiangrui", 2)
		end
	end
}
--无能力者
wnlz = sgs.CreateTriggerSkill {
	name = "wnlz",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if (not card) or card:isVirtualCard() then
			damage.damage = damage.damage - 2
			sendLog("#wnlz-down", room, player, damage.damage)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		end
		if card and card:isKindOf("Slash") then
			damage.damage = damage.damage + 1
			sendLog("#wnlz-up", room, player, damage.damage)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		end
		data:setValue(damage)
		if damage.damage <= 0 then return true end
		return false
	end,
}

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

hxssVS = sgs.CreateOneCardViewAsSkill {
	name = "hxss",
	filter_pattern = "BasicCard",
	view_as = function(self, card)
		local zqzp = sgs.Sanguosha:cloneCard("mouthgun", card:getSuit(), card:getNumber())
		zqzp:addSubcard(card)
		zqzp:setSkillName("hxss")
		return zqzp
	end,
	enabled_at_play = function(self, player)
		return player:getMark("hxss-PlayClear") == 0
	end,
}

hxss = sgs.CreateTriggerSkill {
	name = "hxss",
	events = { sgs.CardEffected }, --怀疑0926版把CardEffected和CardEffected弄反了，但好像又不是这样的
	priority = 2,
	view_as_skill = hxssVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		local effect = data:toCardEffect()
		if not effect.card:isKindOf("mouthgun") or not effect.from:hasSkill(self:objectName()) then return false end
		local room = player:getRoom()
		local thread = room:getThread()                   --获取RoomThread对象
		local new_data = sgs.QVariant()
		new_data:setValue(effect)                         --新建一个data数据，防遇藤甲崩
		room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))  --忽略一次游戏规则
		local avoid = thread:trigger(sgs.CardEffect, room, effect.to, new_data)
		if avoid then return true end                     --判断旧无言等技能效果
		local canceled = room:isCanceled(effect)          --询问无懈
		room:setPlayerFlag(effect.to, "Global_NonSkillNullify") --防止return true出现动画影响观感
		if not canceled then                              --重写一遍【火攻】代码
			effect.from:drawCards(1)
			if effect.to:isKongcheng() or effect.from:isKongcheng() then return false end
			if effect.from:pindian(effect.to, "mouthgun", nil) then
				--[[local LuaChanyuan_skills = effect.to:getTag("hxss_Skills"):toString():split("+")
				local skills = effect.to:getVisibleSkillList()
				for _, skill in sgs.qlist(skills) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not (Set(LuaChanyuan_skills))[skill:objectName()] then
						room:addPlayerMark(effect.to, "Qingcheng"..skill:objectName())
						table.insert(LuaChanyuan_skills, skill:objectName())
					end
				end
				effect.to:setTag("hxss_Skills", sgs.QVariant(table.concat(LuaChanyuan_skills, "+")))]]
				local skill_list = {}
				local Qingchenglist = effect.to:getTag("Qingcheng"):toString():split("+") or {}
				for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
					if (not table.contains(skill_list, skill:objectName())) and not skill:isAttachedLordSkill() then
						table.insert(skill_list, skill:objectName())
					end
				end
				table.removeTable(skill_list, Qingchenglist)
				for _, skill in ipairs(skill_list) do
					table.insert(Qingchenglist, skill)
					effect.to:setTag("Qingcheng", sgs.QVariant(table.concat(Qingchenglist, "+")))
					room:addPlayerMark(effect.to, "Qingcheng" .. skill)
					room:addPlayerMark(effect.to, "hxss")

					for _, z in sgs.qlist(room:getAllPlayers()) do
						room:filterCards(z, z:getCards("he"), true)
					end
				end
				room:addPlayerMark(effect.to, "hxss" .. effect.from:objectName())
				room:addPlayerMark(effect.to, "&hxss+to+#" .. effect.from:objectName())
			end
			return true
		end
		return true
	end,
}
hxssxx = sgs.CreateTriggerSkill {
	name = "#hxssxx",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("mouthgun") then
			if use.card:getSkillName() == "hxss" then
				room:addPlayerMark(player, "hxss-PlayClear")
				room:addPlayerMark(player, "&hxss-PlayClear")
				--room:setPlayerFlag(player, "used_hxss")					
			end
		end
		return false
	end
}
hxss_mod = sgs.CreateTargetModSkill {
	name = "#hxss_mod",
	pattern = "mouthgun",
	distance_limit_func = function(self, from, card)
		if card:getSkillName() == "hxss" then
			return 1000
		else
			return 0
		end
	end
}

hxss_Clear = sgs.CreateTriggerSkill {
	name = "#hxss_Clear",
	events = { sgs.EventPhaseStart, sgs.EventLoseSkill, sgs.Death },
	global = true,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill("hxss")) or (event == sgs.EventLoseSkill and data:toString() == "hxss")
			or (event == sgs.Death and data:toDeath().who:hasSkill("hxss")) then
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				if target:getMark("hxss" .. player:objectName()) > 0 then
					room:setPlayerMark(target, "hxss" .. player:objectName(), 0)
					room:setPlayerMark(target, "&hxss+to+#" .. player:objectName(), 0)
					local Qingchenglist = target:getTag("Qingcheng"):toString():split("+")
					if #Qingchenglist == 0 then continue end
					for _, skill_name in pairs(Qingchenglist) do
						room:setPlayerMark(target, "Qingcheng" .. skill_name, 0);
					end
					target:removeTag("Qingcheng")
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:filterCards(p, p:getCards("he"), true)
					end
				end
			end
			--[[local record = player:getTag("hxss_Skills"):toString():split("+")
			for _, skill_name in ipairs(record) do
				room:removePlayerMark(player, "Qingcheng"..skill_name)
			end
			player:setTag("hxss_Skills", sgs.QVariant())]]
		end
	end
}

extension:insertRelatedSkills("hxss", "#hxss_mod")
extension:insertRelatedSkills("hxss", "#hxssxx")

--[[hxssCard = sgs.CreateSkillCard{
	name = "hxss",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets < 1 and sgs.Self:getSeat() ~= to_select:getSeat()
	end,
	feasible = function(self,targets)
		return #targets == 1
	end,
	on_use = function(self,room,source,targets)
		local target = targets[1]
		local skilllist = target:getVisibleSkillList()
		local skills = {}
		for _,skill in sgs.qlist(skilllist) do
			local name = skill:objectName()
			room:setPlayerMark(target,"Qingcheng"..name,1)
			if not table.contains(skills,name) then table.insert(skills,name) end
		end
		room:setTag(self:objectName().."-skills",sgs.QVariant(table.concat(skills,"+")))
		room:setPlayerMark(target,self:objectName(),1)
	end,
}
hxssVS = sgs.CreateViewAsSkill{
	name = "hxss",
	n = 0,
	view_as = function(self,cards)
		local card = hxssCard:clone()
		card:setSkillName("hxss")
		return card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#hxss")
	end,
}

hxss = sgs.CreateTriggerSkill{
	name = "hxss",
	view_as_skill = hxssVS,
	events = {sgs.EventPhaseChanging, sgs.EventLoseSkill, sgs.EventAcquireSkill},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName(self:objectName())
		local target
		for _,aplayer in sgs.qlist(room:getOtherPlayers(source)) do
			if aplayer:getMark("hxss") > 0 then
				target = aplayer
				break
			end
		end
		if not target then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local tag = room:getTag("hxss-skills")
			if not tag then return false end
			local skills = tag:toString()
			local skill_list = skills:split("+")
			for _,skill_name in ipairs(skill_list) do
				room:setPlayerMark(target,"Qingcheng"..skill_name, 0)
			end
			room:removeTag("hxss-skills")
			room:setPlayerMark(target,"hxss",0)
		elseif event == sgs.EventLoseSkill then
			if player:getMark("hxss") == 0 then return false end
			local skill_name = data:toString()
			local tag = room:getTag("hxss-skills")
			if not tag then return false end
			local skill_list = tag:toString():split("+")
			if not table.contains(skill_list,skill_name) then return false end
			room:setPlayerMark(target,"Qingcheng"..skill_name,0)
			local skills = {}
			for _,skill in ipairs(skill_list) do
				if skill ~= skill_name then table.insert(skills,skill) end
			end
			if #skills == 0 then
				room:removeTag("hxss-skills")
				return false
			end
			room:setTag("hxss-skills",sgs.QVariant(table.concat(skills,"+")))
		elseif event == sgs.EventAcquireSkill then
			if player:getMark("hxss") == 0 then return false end
			local skill_name = data:toString()
			local tag = room:getTag("hxss-skills")
			if not tag then
				room:setTag("hxss-skills",sgs.QVariant(skill_name))
				tag = room:getTag("hxss-skills")
				return false
			end
			local skill_list = tag:toString():split("+")
			if table.contains(skill_list,skill_name) then return false end
			table.insert(skill_list,skill_name)
			room:setPlayerMark(player,"Qingcheng"..skill_name,1)
			room:setTag("hxss-skills",sgs.QVariant(table.concat(skill_list,"+")))
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
}

hxss = sgs.CreateTriggerSkill{
	name = "hxss",
	view_as_skill = hxssVS,
	events = {sgs.Pindian, sgs.EventPhaseEnd, sgs.TrickEffect},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.from:hasFlag("hxss") and pindian.to and pindian.from_number > pindian.to_number then
				room:setPlayerMark(pindian.to, "@hxss_skill_valid", 1)
				room:setPlayerFlag(pindian.from, "used_hxss")
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() ~= sgs.Player_Finish then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerMark(p, "@hxss_skill_valid", 0)
			end
		elseif event == sgs.TrickEffect then
			local trick = data:toCardEffect()
			if trick.card:isKindOf("mouthgun") and trick.from:hasSkill(self:objectName()) and trick.card:getSkillName() == "hxss" then
				room:setPlayerFlag(trick.from, "hxss")
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
}

hxss_i = sgs.CreateInvaliditySkill{
	name = "hxss_i",
	skill_valid = function(self, player, skill)
		if player:getMark("@hxss_skill_valid") >= 1 then
			return false
		else
			return true
		end
	end
}
]]

--厨艺Max
Luachuyi = sgs.CreateViewAsSkill {
	name = "Luachuyi",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("EquipCard")
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
			peach:setSkillName(self:objectName())
			peach:addSubcard(id)
			return peach
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
		peach:deleteLater()
		return peach:isAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach")
	end
}
--闪光连击
Lualianji = sgs.CreateTriggerSkill {
	name = "Lualianji",
	events = { sgs.TargetSpecified },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		player:drawCards(1)
		room:broadcastSkillInvoke("Lualianji", 1)
		local card = room:askForUseCard(player, "TrickCard+^Nullification,EquipCard|.|.|hand", "@sglj")
		if not card then return false end
	end
}
--空之女王
kznwCard = sgs.CreateSkillCard {
	name = "kznw",
	will_throw = false,
	target_fixed = true,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		local card_ids = self:getSubcards()
		source:addToPile("bian", card_ids, false)
		return false
	end,
}
kznwVS = sgs.CreateViewAsSkill {
	name = "kznw",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:hasFlag(self:objectName())
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local vs_card = kznwCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@kznw"
	end,
}
kznw = sgs.CreateTriggerSkill {
	name = "kznw",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	view_as_skill = kznwVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if not player:hasSkill(self:objectName()) then return false end
		if move.to:getSeat() ~= player:getSeat() then return false end
		if room:getTag("FirstRound"):toBool() then return false end
		if player:getPhase() == sgs.Player_NotActive and move.to and move.to_place == sgs.Player_PlaceHand and not (move.from and move.from:getSeat() == player:getSeat() and move.from_places:length() == 1 and move.from_places.contains(sgs.Player_PlaceHand)) then
			for _, card_id in sgs.qlist(move.card_ids) do
				room:setCardFlag(card_id, self:objectName())
			end
			room:askForUseCard(player, "@@kznw", "@kznw")
			for _, card_id in sgs.qlist(move.card_ids) do
				room:setCardFlag(card_id, "-" .. self:objectName())
			end
		end
	end,
}
geassUseCard = sgs.CreateSkillCard {
	name = "geass",
	will_throw = false,
	target_fixed = function(self)
		return sgs.Sanguosha:getCard(self:getSubcards():first()):targetFixed()
	end,
	filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:targetFixed() then return false end
		--[[local playerlist = sgs.Self:getAliveSiblings()
		local target
		for _,player in sgs.qlist(playerlist) do
			if player:getMark("geass_target") > 0 then
				target = player
				break
			end
		end
		playerlist = Table2Playerlist(targets)]]
		return #targets < 1
	end,
	feasible = function(self, targets)
		--[[local playerlist = sgs.Self:getAliveSiblings()
		local target
		for _,player in sgs.qlist(playerlist) do
			if player:getMark("geass_target") > 0 then
				target = player
				break
			end
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:targetFixed() then return true end
		playerlist = Table2Playerlist(targets)
		return card:targetsFeasible(playerlist,target)]] --
		return true
	end,
	on_use = function(self, room, source, targets)
		local playerlist = room:getAlivePlayers()
		local target
		for _, player in sgs.qlist(playerlist) do
			if player:getMark("geass_target") > 0 then
				target = player
				break
			end
		end
		local splayerlist = Table2SPlayerlist(targets)
		local use = sgs.CardUseStruct(sgs.Sanguosha:getCard(self:getSubcards():first()), target, splayerlist, true)
		room:useCard(use)
		return false
	end,
}
geassCard = sgs.CreateSkillCard {
	name = "geasstarget",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:getSeat() ~= sgs.Self:getSeat() and not to_select:isKongcheng() and
		to_select:hasEquip()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local card_list = target:getCards("h")
		local playerlist = room:getAlivePlayers()
		local can_use = false
		local disabled_list = sgs.IntList()
		for _, card in sgs.qlist(card_list) do
			if card:targetFixed() and card:isAvailable(target) then
				can_use = true
			elseif card:targetFixed() then
				disabled_list:append(card:getId())
			else
				local enabled = false
				for _, player in sgs.qlist(playerlist) do
					if card:targetFilter(sgs.PlayerList(), player, target) and not target:isProhibited(player, card) then
						enabled = true
						can_use = true
						break
					end
				end
				if not enabled then disabled_list:append(card:getId()) end
			end
		end
		sendLog("#geass", room, source, nil, nil, target)
		if not can_use then
			room:showAllCards(target, source)
			return false
		else
			local card_ids = sgs.IntList()
			for _, card in sgs.qlist(card_list) do
				card_ids:append(card:getId())
			end
			room:fillAG(card_ids, source, disabled_list)
			room:setPlayerMark(target, "geass_touse", 1)
			local card_id = room:askForAG(source, card_ids, true, "geass")
			room:setPlayerMark(target, "geass_touse", 0)
			room:clearAG(source)
			if card_id == -1 then return false end
			room:showCard(target, card_id)
			room:setPlayerMark(source, "geassused", 1)
			room:setPlayerMark(target, "geass_target", 1)
			room:setPlayerMark(source, "geass", card_id)
			room:askForUseCard(source, "@@geass", "@geass")
			room:setPlayerMark(source, "geass", 0)
			room:setPlayerMark(target, "geass_target", 0)
			room:setPlayerMark(source, "geassused", 0)
			return false
		end
	end,
}
geass = sgs.CreateViewAsSkill {
	name = "geass",
	n = 0,
	view_as = function(self, cards)
		if sgs.Self:getMark("geassused") > 0 then
			local card = sgs.Sanguosha:getCard(sgs.Self:getMark("geass"))
			local vs_card = geassUseCard:clone()
			vs_card:addSubcard(card)
			vs_card:setSkillName(self:objectName())
			return vs_card
		else
			return geassCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#geasstarget")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@geass"
	end,
}
--智能AI
znaiCard = sgs.CreateSkillCard {
	name = "znai",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:hasEquip()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local card_id = room:askForCardChosen(source, targets[1], "e", self:objectName())
		room:setPlayerMark(source, self:objectName(), card_id)
		return false
	end,
}
znaiVS = sgs.CreateViewAsSkill {
	name = "znai",
	n = 0,
	response_pattern = "@@znai",
	view_as = function(self, cards)
		local card = znaiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
}
--[[
znai = sgs.CreateTriggerSkill{
	name = "znai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	view_as_skill = znaiVS,
	on_trigger = function(self,event,player,data)
		if player:hasFlag("znai") then return false end
		local move = data:toMoveOneTime()
		if (not move.from) or move.from:getSeat() == player:getSeat() or move.from:isDead() or (not move.is_last_handcard) then return false end
		local room = player:getRoom()
		local target = room:findPlayer(move.from:getGeneralName())
		local dest = sgs.QVariant()
		dest:setValue(move.from:objectName())
		if not room:askForSkillInvoke(player,self:objectName(), dest) then return false end
		local can_choose = false
		for _,aplayer in sgs.qlist(room:getAlivePlayers()) do
			if aplayer:hasEquip() then
				can_choose = true
				break
			end
		end
		local choice = "znai2"
		
		if can_choose then
		choice = room:askForChoice(player,self:objectName(),"znai1+znai2", dest)
		end
		if choice == "znai1" then
			room:askForUseCard(player,"@@znai","@znai")
			local card_id = player:getMark(self:objectName())
			if card_id and card_id > 0 then room:obtainCard(target,card_id) end
			room:setPlayerMark(player,self:objectName(),0)
			sendLog("#znai1",room,player,nil,nil,target)
		else
			room:drawCards(target,2,self:objectName())
			sendLog("#znai2",room,player,nil,nil,target)
		end
		room:setPlayerFlag(player,"znai")
	end,
}]]
znai = sgs.CreateTriggerSkill {
	name = "znai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	view_as_skill = znaiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local erzhang = room:findPlayerBySkillName(self:objectName())
		local move = data:toMoveOneTime()
		local source = move.from
		if source then
			if player:objectName() == source:objectName() and move.is_last_handcard then
				if erzhang and not erzhang:hasFlag("znai") then
					local p = sgs.QVariant()
					p:setValue(player)
					if not room:askForSkillInvoke(erzhang, self:objectName(), p) then return false end
					local can_choose = false
					for _, aplayer in sgs.qlist(room:getAlivePlayers()) do
						if aplayer:hasEquip() then
							can_choose = true
							break
						end
					end
					local choice = "znai2"

					if can_choose then
						choice = room:askForChoice(erzhang, self:objectName(), "znai1+znai2", p)
					end
					if choice == "znai1" then
						room:askForUseCard(erzhang, "@@znai", "@znai")
						local card_id = erzhang:getMark(self:objectName())
						if card_id and card_id > 0 then room:obtainCard(player, card_id) end
						room:setPlayerMark(erzhang, self:objectName(), 0)
						sendLog("#znai1", room, erzhang, nil, nil, player)
					else
						room:drawCards(player, 2, self:objectName())
						sendLog("#znai2", room, erzhang, nil, nil, player)
					end
					room:setPlayerFlag(erzhang, "znai")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
znaiex = sgs.CreateTriggerSkill {
	name = "#znaiex",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p, "-znai")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,

}
--被改变的命运

changedfate = sgs.CreateTriggerSkill {
	name = "changedfate",
	events = { sgs.StartJudge, sgs.AskForRetrial, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	global = true,
	priority = 5,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local poi = room:findPlayerBySkillName(self:objectName())
		if not poi or player:getPhase() ~= sgs.Player_Judge then return false end
		if event == sgs.EventPhaseStart then
			if not player:getJudgingArea():isEmpty() then
				if room:askForSkillInvoke(poi, self:objectName(), data) then
					room:setPlayerFlag(player, self:objectName())
				end
			end
		elseif event == sgs.AskForRetrial or event == sgs.StartJudge then
			local judge = data:toJudge()
			if judge.who:objectName() ~= player:objectName() or not player:hasFlag(self:objectName()) then return false end
			if event == sgs.StartJudge then
				if judge.good == true then
					judge.good = false
				elseif judge.good == false then
					judge.good = true
				end
				room:sendCompulsoryTriggerLog(poi, self:objectName())
			elseif event == sgs.AskForRetrial then
				return true
			end
		elseif event == sgs.EventPhaseEnd then
			if player:hasFlag(self:objectName()) then
				room:setPlayerFlag(player, "-" .. self:objectName())
			end
		end
		return false
	end,
}
--零时迷子
lsmz = sgs.CreateTriggerSkill
	{
		name = "lsmz",
		frequency = sgs.Skill_Limited,
		events = { sgs.EventPhaseStart, sgs.DrawNCards },
		limit_mark = "@lsmz",
		on_trigger = function(self, event, player, data, room)
			if (event == sgs.EventPhaseStart) then
				if (player:getPhase() == sgs.Player_Start) and (player:getMark("@lsmz") == 1) then
					room:broadcastSkillInvoke("lsmz", math.random(1, 2))
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:recover(player, sgs.RecoverStruct(player, nil, player:getLostHp()))
					--room:addPlayerMark(player, "lsmz")
					room:addPlayerMark(player, "&lsmz-Clear")
					room:setPlayerFlag(player, "lsmz")
					room:removePlayerMark(player, "@lsmz")
					player:skip(sgs.Player_Judge)
				end
			else
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				if (player:hasFlag("lsmz")) then
					local num = math.abs(4 - player:getMaxHp())
					draw.num = draw.num + num
					data:setValue(draw)
					room:sendCompulsoryTriggerLog(player, self:objectName())
				end
			end
		end
	}
--大命诗歌
tmsp = sgs.CreateTriggerSkill
	{
		name = "tmsp",
		events = { sgs.EventPhaseStart },
		on_trigger = function(self, event, player, data, room)
			if (player:getPhase() == sgs.Player_RoundStart and player:getMark("@lsmz") == 0 and room:askForSkillInvoke(player, self:objectName())) then
				room:loseMaxHp(player)
				room:broadcastSkillInvoke("tmsp", math.random(1, 2))
				room:addPlayerMark(player, "@lsmz")
				room:addPlayerMark(player, "tmsp")
				room:setPlayerMark(player, "&tmsp-Clear", player:getMark("tmsp"))
				room:setPlayerFlag(player, "tmsp")
			end
		end
	}

tmsp_more_slash = sgs.CreateTargetModSkill
	{
		name = "#tmsp",
		residue_func = function(self, player)
			if (player:hasFlag("tmsp")) then
				return player:getMark("tmsp")
			else
				return 0
			end
		end
	}

--[[
--零时迷子
lsmzCard = sgs.CreateSkillCard{
	name = "lsmz",
	will_throw = true,
	target_fixed = true,
	on_use = function(self,room,source)
		local recover = sgs.RecoverStruct(source,nil,source:getMaxHp() - source:getHp())
		room:recover(source,recover)
	end,
}
lsmzVS = sgs.CreateViewAsSkill{
	name = "lsmz",
	n = 1,
	response_pattern = "@@lsmz",
	view_filter = function(self,selected,to_select)
		return #selected < 1 and to_select:isBlack() and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards < 1 then return nil end
		local vs_card = lsmzCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
}
lsmz = sgs.CreateTriggerSkill{
	name = "lsmz",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = lsmzVS,
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_Start or player:isKongcheng() or player:getHp() == player:getMaxHp() then return false end
		player:getRoom():askForUseCard(player,"@@lsmz","@lsmz")
	end,
}
--避火戒指
bhjz = sgs.CreateTriggerSkill{
	name = "bhjz",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	priority = 0,
	on_trigger = function(self,event,player,data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Fire or damage.damage <= 1 then return false end
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player,self:objectName())
		sendLog("#bhjz",room,player)
		damage.damage = 1
		data:setValue(damage)
		return false
	end,
}
]]
--王之宝库
wangzbk = sgs.CreateTriggerSkill {
	name = "wangzbk",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			if (not move.from) or move.from:getSeat() == player:getSeat() then return false end
			if not player:hasSkill(self:objectName()) then return false end
			local equips = sgs.CardList()
			for _, card_id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(card_id)
				if card:isKindOf("EquipCard") then equips:append(card) end
			end
			if equips:isEmpty() then return false end
			if player:hasFlag("wzbk") then return false end
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, card in sgs.qlist(equips) do
				dummy:addSubcard(card)
			end
			room:obtainCard(player, dummy)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 4))
			room:setPlayerFlag(player, "wzbk")
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerFlag(p, "-wzbk")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--兵弑
bings = sgs.CreateTriggerSkill {
	name = "bings",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if player:getPhase() ~= sgs.Player_Play then return end
			if room:askForCard(player, "EquipCard", "@bings-increase", data, self:objectName()) then
				damage.damage = damage.damage + 1
				sendLog("#bings-increase", room, player, damage.damage, nil, damage.to)
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 4))
				data:setValue(damage)
				return false
			end
		end
		if event == sgs.DamageInflicted then
			if room:askForCard(player, "EquipCard|.|.|hand", "@bings-decrease", data, self:objectName()) then
				damage.damage = damage.damage - 1
				sendLog("#bings-decrease", room, player, damage.damage, nil)
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 4))
				if damage.damage < 1 then return true end
				data:setValue(damage)
				return false
			end
		end
	end,
}
--乖离剑
guailjCard = sgs.CreateSkillCard {
	name = "guailj",
	target_fixed = true,
	on_use = function(self, room, source)
		room:removePlayerMark(source, "@guailj")
		local playerlist = room:getOtherPlayers(source)
		for _, player in sgs.qlist(playerlist) do
			if player:isAlive() then
				local choice = "guailj2"
				if player:getArmor() and player:canDiscard(player, player:getArmor():getRealCard():getId()) then
					choice = room:askForChoice(player, self:objectName(), "guailj1+guailj2")
				end
				if choice == "guailj1" then
					room:throwCard(player:getArmor():getRealCard(), player, player)
				else
					room:damage(sgs.DamageStruct(self:objectName(), source, player, 1))
				end
			end
		end
	end,
}
guailjVS = sgs.CreateZeroCardViewAsSkill {
	name = "guailj",
	view_as = function(self)
		return guailjCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@guailj") >= 1
	end,
}
guailj = sgs.CreateTriggerSkill {
	name = "guailj",
	frequency = sgs.Skill_Limited,
	view_as_skill = guailjVS,
	limit_mark = "@guailj",
	on_trigger = function()
	end,
}
--昼
--昼
--[[zhouClear = sgs.CreateTriggerSkill{
	name = "zhou-clear",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			local playerlist = room:getAllPlayers()
			for _,target in sgs.qlist(playerlist) do
				room:setPlayerMark(target,"zhou",0)
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
}
zhou = sgs.CreateTriggerSkill{
	name = "zhou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player,self:objectName())
		room:setPlayerMark(player,"zhou",player:getMark("zhou") + 1)
	end,
}
zhouDistance = sgs.CreateDistanceSkill{
	name = "#zhou",
	correct_func = function(self,from,to)
		return to:getMark("zhou")
	end,
}
extension:insertRelatedSkills("zhou","#zhou")]]

--zy奆神的轮数计算器
zhou_count = sgs.CreateTriggerSkill {
	name = "zhou_count",
	global = true,
	events = { sgs.TurnStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill("zhou") and not room:getTag("ExtraTurn"):toBool() then
			room:addPlayerMark(player, "zhou_count", 1)
		end
		return false
	end
}

zhou = sgs.CreateDistanceSkill {
	name = "zhou",
	correct_func = function(self, from, to)
		if to:hasSkill(self:objectName()) then
			if math.fmod(to:getMark("zhou_count") + 1, 2) == 0 then
				return to:getLostHp() --偶数
			else
				return to:getHp() --奇数
			end
		else
			return 0
		end
	end,
}

--夜
ye = sgs.CreateTriggerSkill {
	name = "ye",
	frequency = sgs.Skill_Wake,
	waked_skills = "guichan",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		-- local playerlist = room:getAlivePlayers()
		-- for _,aplayer in sgs.qlist(playerlist) do
		-- 	if aplayer:getHp() < player:getHp() then return false end
		-- end
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:setPlayerMark(player, self:objectName(), 1)
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		room:recover(player, sgs.RecoverStruct(player))
		room:broadcastSkillInvoke(self:objectName(), 1)
		room:handleAcquireDetachSkills(player, "guichan")
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end

		if can_invoke then return true end
		return false
	end,
}
--鬼缠
guichan = sgs.CreateTriggerSkill {
	name = "guichan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Death, sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death and room:askForSkillInvoke(player, "guichan", data) then
			room:broadcastSkillInvoke("zhou", 1)
			room:drawCards(player, 1)
		end
		if event == sgs.Dying then
			local dying = data:toDying()
			local victim = dying.who
			if player:objectName() == victim:objectName() or victim:isNude() then return end
			local dest = sgs.QVariant()
			dest:setValue(victim)
			if room:askForSkillInvoke(player, "guichan", dest) then
				local id = room:askForCardChosen(player, victim, "he", self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:obtainCard(player, id, false)
			end
		end
	end,

}
--打反
--[[dafanSourceCard = sgs.CreateSkillCard{
	name = "dafan",
	will_throw = true,
	target_fixed = true,
	feasible = function(self,targets)
		return true
	end,
	on_use = function(self,room,source,data)
		return false
	end,
}
dafanSourceVS = sgs.CreateViewAsSkill{
	name = "dafan",
	n = 2,
	response_pattern = "@@dafan",
	view_filter = function(self,selected,to_select)
		return #selected < 2 and to_select:isBlack() and sgs.Self:canDiscard(sgs.Self,to_select:getId())
	end,
	view_as = function(self,cards)
		if #cards < 2 then return nil end
		local vs_card = dafanSourceCard:clone()
		for _,card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
}
dafan = sgs.CreateTriggerSkill{
	name = "dafan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	view_as_skill = dafanSourceVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:isNude() then return false end
		if room:askForCard(player,"@@dafan","@dafan") then
			damage.damage = damage.damage - 1
			room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
			sendLog("#dafan",room,player,damage.damage)
			if damage.from then
				local card = nil
				if damage.from:getSeat() ~= player:getSeat() then card = room:askForCard(damage.from,".|red|.|hand","@dafantarget:"..player:objectName(),sgs.QVariant(),sgs.Card_MethodNone) end
				if card then
					player:obtainCard(card)
				else
					local d = sgs.DamageStruct()
					d.from = player
					d.to = damage.from
					d.damage = 1
					d.reason = self:objectName()
					room:damage(d)
				end
			end
			if damage.damage < 1 then return true end
			data:setValue(damage)
		end
	end,
}]]
dafan = sgs.CreateTriggerSkill {
	name = "dafan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local num = player:getLostHp()
		if damage.from and damage.card and damage.card:isKindOf("Slash") and (not damage.from:isKongcheng()) and (not damage.to:isKongcheng()) and room:askForSkillInvoke(player, self:objectName(), data) then
			local card = room:askForCard(damage.from, ".!", "@dafanuj-give", data, sgs.Card_MethodNone)
			local carda = room:askForCard(damage.to, ".!", "@dafanuj-give", data, sgs.Card_MethodNone)
			damage.to:obtainCard(card)
			damage.from:obtainCard(carda)
			if card:isKindOf("BasicCard") and carda:isKindOf("BasicCard") then
				room:loseHp(damage.to)
				room:loseHp(damage.from)
			end
			if card:isKindOf("TrickCard") or carda:isKindOf("TrickCard") then
				room:askForDiscard(damage.to, self:objectName(), damage.to:getHandcardNum() - 1,
					damage.to:getHandcardNum() - 1)
				room:askForDiscard(damage.from, self:objectName(), damage.from:getHandcardNum() - 1,
					damage.from:getHandcardNum() - 1)
			end
			if card:isKindOf("Slash") or carda:isKindOf("Slash") then
				return true
			end
		end
	end,

}
--绝剑
juej = sgs.CreateTriggerSkill {
	name = "juej",
	frequency = sgs.Skill_Wake,
	waked_skills = "smsy",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and (player:getHp() == 1 or player:getHandcardNum() == 1) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
			local choice = room:askForChoice(player, self:objectName(), "juejian:ls+juejian:qz", data)
			if choice == "juejian:ls" then
				room:handleAcquireDetachSkills(player, "smsy")
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:loseHp(p)
				end
			elseif choice == "juejian:qz" then
				room:handleAcquireDetachSkills(player, "smsy")
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHandcardNum() > 1 then
						room:askForDiscard(p, self:objectName(), p:getHandcardNum() - 1, p:getHandcardNum() - 1)
					end
				end
			end
		end
	end,
}
--圣母圣咏
smsyCard = sgs.CreateSkillCard {
	name = "smsy",
	will_throw = true,
	target_fixed = true,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		return false
	end,
}
smsyVS = sgs.CreateViewAsSkill {
	name = "smsy",
	n = 1,
	response_pattern = "@@smsy",
	view_filter = function(self, selected, to_select)
		return #selected < 1 and sgs.Self:canDiscard(sgs.Self, to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local vs_card = smsyCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
}
smsy = sgs.CreateTriggerSkill {
	name = "smsy",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	view_as_skill = smsyVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.to:getSeat() ~= player:getSeat() and damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) and (not player:isNude()) and room:askForCard(player, "@@smsy", "@smsy", data) then
			local x = 1
			if player:isKongcheng() then x = x + 1 end
			damage.damage = damage.damage + x
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			sendLog("#smsy", room, player, x, damage.damage)
			data:setValue(damage)
		end
	end,
}
--界王拳
jiewqCard = sgs.CreateSkillCard {
	name = "jiewq",
	target_fixed = true,
	on_use = function(self, room, source)
		local choices = {}
		for i = 1, source:getHp(), 1 do
			table.insert(choices, tostring(i))
		end
		local choice = tonumber(room:askForChoice(source, self:objectName(), table.concat(choices, '+')))
		room:loseHp(source, choice)
		room:setPlayerMark(source, self:objectName() .. "-Clear", choice)
		room:setPlayerMark(source, "&" .. self:objectName() .. "-Clear", choice)
		return false
	end,
}
jiewqVS = sgs.CreateViewAsSkill {
	n = 0,
	name = "jiewq",
	view_as = function(self, cards)
		local card = jiewqCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getHp() > 0 and not player:hasUsed("#jiewq")
	end,
}
jiewq = sgs.CreateTriggerSkill {
	name = "jiewq",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished, sgs.DamageCaused },
	view_as_skill = jiewqVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark = player:getMark(self:objectName() .. "-Clear")
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerMark(player, self:objectName() .. "-Clear", 0)
				room:setPlayerMark(player, "&" .. self:objectName() .. "-Clear", 0)
			end
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and mark > 0 then
				damage.damage = damage.damage + mark
				sendLog("#jiewq", room, player, mark, damage.damage)
				data:setValue(damage)
				return false
			end
		end
	end,
}
--赛亚人
saiya = sgs.CreateTriggerSkill {
	name = "saiya",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.QuitDying, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.QuitDying then
			if player:isAlive() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				sendLog("#GainMaxHp", room, player, 1)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
			return false
		end
	end,
}
--自在极意
zizai = sgs.CreateTriggerSkill {
	name = "zizai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.QuitDying, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.QuitDying then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			player:gainMark("@zizaiyi", 1)
			room:recover(player, sgs.RecoverStruct(player, nil, player:getMaxHp()))
			if player:getMark("@zizaiyi") == 4 then
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
			end
			return false
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:getMark("@zizaiyi") >= 4 then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				return false
			end
		end
	end,
}
gbgCard = sgs.CreateSkillCard {
	name = "gbg",
	target_fixed = true,
	on_use = function(self, room, source)
		local choices = {}
		for i = 1, source:getHp(), 1 do
			table.insert(choices, tostring(i))
		end
		local choice = tonumber(room:askForChoice(source, self:objectName(), table.concat(choices, '+')))
		room:loseHp(source, choice)
		room:setPlayerMark(source, self:objectName(), choice)
		return false
	end,
}
gbgVS = sgs.CreateViewAsSkill {
	n = 0,
	name = "gbg",
	view_as = function(self, cards)
		local card = gbgCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getHp() > 0 and not player:hasUsed("#gbg")
	end,
}
gbg = sgs.CreateTriggerSkill {
	name = "gbg",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished, sgs.DamageCaused },
	view_as_skill = gbgVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark = player:getMark(self:objectName())
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and mark > 0 then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				return false
			end
		end
	end,
}
--不存在之人
bczzr = sgs.CreateTriggerSkill {
	name = "bczzr",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardResponded, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (not resp.m_card:isKindOf("Jink")) or (not resp.m_isUse) then return false end
			card = resp.card
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if (use.card:isKindOf("Jink")) then
				card = use.card
			end
		end
		if card then
			room:setPlayerMark(player, self:objectName(), 1)
			room:setPlayerMark(player, "&bczzr", 0)
		end
	end,
}
bczzrClear = sgs.CreateTriggerSkill {
	name = "#bczzr-clear",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, target in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(target, "bczzr", 0)
			end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:setPlayerMark(p, "&bczzr", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
bczzrProhibit = sgs.CreateProhibitSkill {
	name = "#bczzr",
	is_prohibited = function(self, from, to, card)
		return card:isKindOf("TrickCard") and to:hasSkill("bczzr") and to:getMark("bczzr") <= 0
	end,
}
extension:insertRelatedSkills("bczzr", "#bczzr")
extension:insertRelatedSkills("bczzr", "#bczzr-clear")
--木偶之眼
mozy = sgs.CreateTriggerSkill {
	name = "mozy",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:canDiscard(player, "he") then
					room:broadcastSkillInvoke("mozy", 1)
					local card = room:askForCard(player, "..", "@muou", data, self:objectName())
					if card then
						local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
							"muou-invoke")
						if card:isRed() then
							room:recover(s, sgs.RecoverStruct(player, nil, 1))
						elseif card:isBlack() then
							--s:gainMark("@mozy")
							room:addPlayerMark(s, "&mozy-SelfClear")
							room:addPlayerMark(s, "mozy-SelfClear")
						end
					end
				end
			end
		end
	end,
}
mozybuff = sgs.CreateTriggerSkill {
	name = "#mozybuff",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Start and player:getMark("@mozy") > 0 then
				player:loseAllMarks("@mozy")
			end
		end
	end
}
mozyProhibit = sgs.CreateProhibitSkill {
	name = "#mozy",
	is_prohibited = function(self, from, to, card)
		if not card:isKindOf("Peach") then return false end
		if from:getMark("mozy-SelfClear") > 0 and (not to) then return true end
		if to and to:getMark("mozy-SelfClear") > 0 then return true end
	end,
}
extension:insertRelatedSkills("mozy", "#mozybuff")
extension:insertRelatedSkills("mozy", "#mozy")


--情殇哀逝
qsasCard = sgs.CreateSkillCard {
	name = "qsas",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:getSeat() ~= sgs.Self:getSeat() and to_select:getMark(self:objectName()) == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1], self:objectName() .. source:objectName(), 1)
		room:setPlayerMark(targets[1], "&" .. self:objectName() .. "+to+#" .. source:objectName(), 1)
		return false
	end,
}
qsasVS = sgs.CreateViewAsSkill {
	n = 1,
	name = "qsas",
	view_filter = function(self, selected, to_select)
		return #selected < 1 and to_select:isKindOf("TrickCard")
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local vs_card = qsasCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,

}
qsas = sgs.CreateTriggerSkill {
	name = "qsas",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.HpRecover, sgs.Damaged },
	view_as_skill = qsasVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to:getMark(self:objectName() .. p:objectName()) > 0 then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					p:drawCards(damage.damage)
					return false
				end
			end
		end
		if event == sgs.HpRecover then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local recover = data:toRecover()
				if player:getMark(self:objectName() .. p:objectName()) > 0 then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					for i = 1, recover.recover, 1 do
						if not p:canDiscard(player, "he") then break end
						local card_id = room:askForCardChosen(p, player, "he", self:objectName(), false,
							sgs.Card_MethodDiscard)
						room:throwCard(card_id, player, p)
					end
				end
			end
			return false
		end
		if event == sgs.EventPhaseStart then
			local current = room:getCurrent()
			if current and current:objectName() == player:objectName() and player:getPhase() == sgs.Player_Start then
				for _, target in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(target, self:objectName() .. player:objectName(), 0)
					room:setPlayerMark(target, "&" .. self:objectName() .. "+to+#" .. player:objectName(), 0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--直死魔眼
zsmy = sgs.CreateTriggerSkill {
	name = "zsmy",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zsmy",
	events = { sgs.Death, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		local damage = data:toDamage()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer = damage.from
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			if killer and killer:hasSkill(self:objectName()) and (death.damage.reason == self:objectName()) then
				killer:gainMark("@zsmy")
				room:broadcastSkillInvoke("zsmy")
			end
		elseif event == sgs.DamageCaused then
			if damage.to:getHp() <= 2 and player:hasSkill(self:objectName()) and player:getMark("@zsmy") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local ids = room:getNCards(1, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
						self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
						self:objectName(), nil)
					for _, card in sgs.list(ids) do
						room:throwCard(sgs.Sanguosha:getCard(card), reason, nil, nil)
					end
					if not sgs.Sanguosha:getCard(ids:first()):isKindOf("Slash") then
						player:loseMark("@zsmy")
						room:broadcastSkillInvoke("zsmy")
						local x = math.max(room:getAllPlayers(true):length() - room:getAlivePlayers():length(), 1)
						damage.damage = damage.damage + x
						damage.reason = self:objectName()
						data:setValue(damage)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--逆刃刀
nirendao = sgs.CreateTriggerSkill {
	name = "nirendao",
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_Compulsory,
	priority = 1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		local damage = data:toDamage()
		local count = damage.damage
		if damage.chain or damage.transfer then return false end
		if damage.card:isKindOf("Slash") then
			if count + 1 >= damage.to:getHp() then
				room:sendCompulsoryTriggerLog(damage.from, self:objectName())
				return true
			else
				local log = sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = self:objectName()
				log.arg2 = damage.damage
				room:sendLog(log)
				count = count + 1
				damage.damage = count
				data:setValue(damage)
			end
		end
	end
}
--逆刀刃
nidaorenCard = sgs.CreateSkillCard {
	name = "nidaorenCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local drawnum = {}
		for i = 1, source:getHp(), 1 do
			table.insert(drawnum, tostring(i))
		end
		local num = tonumber(room:askForChoice(source, "nidaorendraw", table.concat(drawnum, "+")))
		room:doSuperLightbox("feicunjianxin", "$nidaorenQP")
		source:loseMark("@nidaoren")
		room:setPlayerMark(source, "nidaorendying", 0)
		room:loseHp(source, num)
		if not source:isAlive() then return false end
		source:drawCards(num * 3, "nidaoren")
		room:setPlayerMark(source, "nidaoren", num)
	end,
}
nidaorenVS = sgs.CreateZeroCardViewAsSkill {
	name = "nidaoren",
	view_as = function()
		return nidaorenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@nidaoren") > 0
	end
}
nidaoren = sgs.CreateTriggerSkill {
	name = "nidaoren",
	frequency = sgs.Skill_Limited,
	limit_mark = "@nidaoren",
	events = { sgs.EventPhaseChanging, sgs.Dying },
	view_as_skill = nidaorenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			room:setPlayerMark(player, "nidaoren", 0)
		end
	end,
}
nidaorenDis = sgs.CreateDistanceSkill {
	name = "#nidaorenDis",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -from:getMark("nidaoren")
		end
	end,
}
extension:insertRelatedSkills("nidaoren", "#nidaorenDis")
--拔刀斋
badaozhaiCard = sgs.CreateSkillCard {
	name = "badaozhaiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("feicunjianxin", "$badaozhaiQP")
		source:loseMark("@badaozhai")
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getHp() < source:getLostHp() then
				room:setPlayerMark(p, "badaozhaihp", p:getHp())
				room:setPlayerProperty(p, "hp", sgs.QVariant(0))
				room:enterDying(p, nil)
			end
		end
	end,
}
badaozhaiVS = sgs.CreateZeroCardViewAsSkill {
	name = "badaozhai",
	view_as = function()
		return badaozhaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@badaozhai") > 0
	end
}
badaozhai = sgs.CreateTriggerSkill {
	name = "badaozhai",
	frequency = sgs.Skill_Limited,
	limit_mark = "@badaozhai",
	events = { sgs.AskForPeachesDone },
	view_as_skill = badaozhaiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hp = player:getMark("badaozhaihp")
		if hp > 0 then
			room:setPlayerMark(player, "badaozhaihp", 0)
			if player:getHp() <= 0 then return false end
			room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
--飞雷神之术
feils = sgs.CreateDistanceSkill {
	name = "feils",
	correct_func = function(self, from, to)
		local correct = 0
		if from:hasSkill(self:objectName()) and (from:getHp() >= from:getHandcardNum()) then
			correct = correct - 2
		end
		if to:hasSkill(self:objectName()) and (to:getHp() < from:getHandcardNum()) then
			correct = correct + 2
		end
		return correct
	end
}
--金色闪光
jssg = sgs.CreateTriggerSkill {
	name = "jssg",
	frequency = sgs.Skill_Wake,
	waked_skills = "feils2",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		room:sendCompulsoryTriggerLog(player, self:objectName())
		if player:getHp() < player:getMaxHp() then
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
		end
		room:setPlayerMark(player, self:objectName(), 1)
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		room:acquireSkill(player, "feils2")
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		if player:canWake(self:objectName()) then return true end
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end

		if can_invoke then return true end
		return false
	end,

}
--飞雷神二段
feils2Card = sgs.CreateSkillCard {
	name = "feils2",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and sgs.Self:canSlash(to_select, false)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		local use = sgs.CardUseStruct(slash, source, targets[1])
		room:useCard(use, false)
		room:setPlayerMark(targets[1], self:objectName() .. source:objectName(), 1)
		room:setFixedDistance(targets[1], source, 1)
		room:setPlayerMark(targets[1], "&" .. self:objectName() .. "+to+#" .. source:objectName(), 1)
		return false
	end,
}
feils2VS = sgs.CreateViewAsSkill {
	n = 0,
	name = "feils2",
	view_as = function(self, cards)
		local card = feils2Card:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#feils2")
	end,
}
feils2 = sgs.CreateTriggerSkill {
	name = "feils2",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = feils2VS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local room = player:getRoom()
		for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if player:getMark(self:objectName() .. source:objectName()) > 0 then
				room:setPlayerMark(player, self:objectName() .. source:objectName(), 0)
				room:setPlayerMark(player, "&" .. self:objectName() .. "+to+#" .. source:objectName(), 0)
				room:removeFixedDistance(player, source, 1)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--窥心
kuixinCard = sgs.CreateSkillCard {
	name = "kuixin",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:getSeat() ~= sgs.Self:getSeat() and not to_select:isKongcheng()
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if target then
			local card_id = room:doGongxin(source, target, target:handCards(), "kuixin")
			if (card_id == -1) then return end
			if source:getHandcardNum() <= target:getHandcardNum() then
				room:obtainCard(source, card_id)
			end
			return false
		else
			local stars = room:getNCards(3)
			room:fillAG(stars, source)
			if source:getHandcardNum() <= 3 then
				local card_id = room:askForAG(source, stars, true, self:objectName())
				if card_id ~= -1 then
					source:obtainCard(sgs.Sanguosha:getCard(card_id), false)
					stars:removeOne(card_id)
				end
			else
				room:getThread():delay(2500)
			end
			room:clearAG()
			room:returnToTopDrawPile(stars)
			--[[		local card_ids = room:getNCards(3, false)
			if source:getHandcardNum() <= 3 then
				room:fillAG(card_ids,source)
				local card_id = room:askForAG(source,card_ids,true,self:objectName())
				room:clearAG()
				if card_id ~= -1 then source:obtainCard(sgs.Sanguosha:getCard(card_id),false) end
				return false
			end
			room:fillAG(card_ids,source)
			room:getThread():delay(2000)
			room:clearAG()]]
			return false
		end
	end,
}
kuixinVS = sgs.CreateViewAsSkill {
	n = 0,
	name = "kuixin",
	response_pattern = "@@kuixin",
	view_as = function(self, cards)
		local card = kuixinCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
}
kuixin = sgs.CreateTriggerSkill {
	name = "kuixin",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = kuixinVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local room = player:getRoom()
		room:askForUseCard(player, "@@kuixin", "@kuixin")
		return false
	end,
}
--救赎
jiushuCard = sgs.CreateSkillCard {
	name = "jiushu",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		return false
	end,
}
jiushuVS = sgs.CreateViewAsSkill {
	n = 2,
	name = "jiushu",
	response_pattern = "@@jiushu",
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		if not sgs.Self:canDiscard(sgs.Self, to_select:getId()) then return false end
		if #selected == 0 then return true end
		if #selected == 1 then
			return selected[1]:getTypeId() == to_select:getTypeId() or
			selected[1]:getSuitString() == to_select:getSuitString()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards < 2 then return nil end
		local vs_card = jiushuCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
}
jiushu = sgs.CreateTriggerSkill {
	name = "jiushu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	view_as_skill = jiushuVS,
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		local room = player:getRoom()
		if dying.who:getSeat() == player:getSeat() then return false end
		local p = sgs.QVariant()
		p:setValue(dying.who)
		if not room:askForSkillInvoke(player, self:objectName()) then return false end
		player:drawCards(1)
		if not room:askForUseCard(player, "@@jiushu", "@jiushu:" .. dying.who:objectName()) then return false end
		room:recover(dying.who, sgs.RecoverStruct(player, nil, 1))
		return false
	end,
}
--协横
xieheng = sgs.CreateTriggerSkill {
	name = "xieheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:askForSkillInvoke(player, self:objectName()) then return false end
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
		local dest = sgs.QVariant()
		dest:setValue(target)
		if room:askForCard(player, ".|red", "@xieheng:" .. target:objectName(), dest) then
			room:recover(target, sgs.RecoverStruct(player, nil, 1))
		else
			target:drawCards(1)
		end
	end,
}
--痛觉的止符
tjdzf = sgs.CreateTriggerSkill {
	name = "tjdzf",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local damage = data:toDamage()
			local card_ids = room:getNCards(damage.damage)
			player:addToPile("qrdag_yin", card_ids)
			sendLog("#tjdzf", room, player, damage.damage)
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
		if event == sgs.EventPhaseStart then
			local yin = player:getPile("qrdag_yin"):length()
			if player:getPhase() == sgs.Player_Play and yin >= 3 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:doLightbox("tjdzf$", 3600)
			elseif player:getPhase() == sgs.Player_Finish and yin > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:loseHp(player, yin)
				if player:isAlive() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcards(player:getPile("qrdag_yin"))
					player:obtainCard(dummy)
					dummy:deleteLater()
				end
				return false
			end
		end
	end,
}
--[[if player:getPhase() ~= sgs.Player_Finish or player:getPile("yin"):isEmpty() then return false end
			room:loseHp(player,player:getPile("yin"):length())
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit,0)
			dummy:addSubcards(player:getPile("yin"))
			player:obtainCard(dummy)
			return false
		end
	end]]

--青刃的哀歌
qrdag = sgs.CreateTriggerSkill {
	name = "qrdag",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.PreCardUsed, sgs.Damage, sgs.CardFinished, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getPhase() == sgs.Player_Play and use.card:isKindOf("Slash") and player:getMark(self:objectName()) == 0 then
				room:setPlayerMark(player, self:objectName(), 1)
				use.card:setFlags(self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag(self:objectName()) then
				for i = 1, damage.damage, 1 do
					local yin = player:getPile("qrdag_yin")
					local choices = {}
					if yin:length() > 0 then
						table.insert(choices, "qrdag_discard")
					end
					if player:isWounded() then
						table.insert(choices, "qrdag_recover")
					end
					if #choices == 0 then return false end
					if not room:askForSkillInvoke(player, self:objectName()) then return false end
					room:broadcastSkillInvoke(self:objectName(), 2)
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					if choice == "qrdag_recover" then
						room:recover(player, sgs.RecoverStruct(player, nil, 1))
					else
						room:fillAG(yin, player)
						local card_id = room:askForAG(player, yin, false, self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
							player:objectName(), self:objectName(), "")
						local ac = sgs.Sanguosha:getCard(card_id)
						room:throwCard(ac, reason, nil)
						room:clearAG()
					end
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag(self:objectName()) then
				use.card:setFlags("-" .. self:objectName())
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,
}
qrdagEx = sgs.CreateTargetModSkill {
	name = "qrdag_ex",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("qrdag") and not player:hasUsed("Slash") and player:getPhase() == sgs.Player_Play then
			return 999
		else
			return 0
		end
	end,
	extra_target_func = function(self, from)
		if not from:hasSkill("qrdag") then return 0 end
		if from:hasUsed("Slash") or from:getPhase() ~= sgs.Player_Play then return 0 end
		return math.max(0, from:getPile("qrdag_yin"):length() - 1)
	end,
}
--粉毛
fenmao = sgs.CreateTriggerSkill {
	name = "fenmao",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForCard(player, ".|.|.|hand", "@fenmao-qp", data, self:objectName()) then
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				local suit = judge.card:getSuit()
				if judge.card:isRed() then
					room:acquireSkill(player, "changgui")
					if player:getGeneralName() == "gasaiyuno" then
						room:setPlayerProperty(player, "general", sgs.QVariant("woqiyounai"))
					end
				elseif judge.card:isBlack() then
					room:acquireSkill(player, "heihua")
					if player:getGeneralName() == "woqiyounai" then
						room:setPlayerProperty(player, "general", sgs.QVariant("gasaiyuno"))
					end
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasSkill("changgui") then
				room:detachSkillFromPlayer(player, "changgui", false, true)
			end
			if player:hasSkill("heihua") then
				room:detachSkillFromPlayer(player, "heihua", false, true)
			end
		end
	end
}
--常规
changguicard = sgs.CreateSkillCard {
	name = "changgui",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local ids = room:getNCards(3)
		room:fillAG(ids)
		local id = room:askForAG(source, ids, false, "changgui")
		if id ~= -1 then
			room:obtainCard(source, id, false)
			ids:removeOne(id)
		end
		room:clearAG()
		room:askForGuanxing(source, ids, 1)
	end
}
changgui = sgs.CreateZeroCardViewAsSkill {
	name = "changgui",
	view_as = function(self)
		return changguicard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#changgui")
	end
}
--黑化
heihuacard = sgs.CreateSkillCard {
	name = "heihua",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and (not to_select:isKongcheng()) and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local ids = targets[1]:handCards()
		room:fillAG(ids, source)
		room:getThread():delay(2000)
		room:clearAG(source)
		local basic = sgs.IntList()
		for _, d in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(d):isKindOf("BasicCard") then
				basic:append(d)
			end
		end
		if basic:isEmpty() then return false end
		room:fillAG(basic, source)
		local id = room:askForAG(source, basic, false, "heihua")
		if id ~= -1 then
			room:showCard(targets[1], id)
			room:obtainCard(source, id)
		end
		room:clearAG(source)
	end
}
heihua = sgs.CreateZeroCardViewAsSkill {
	name = "heihua",
	view_as = function(self)
		return heihuacard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heihua")
	end
}
--轮回
samsaraVS = sgs.CreateViewAsSkill {
	name = "samsara",
	n = 998,
	response_or_use = true,
	view_filter = function(self, selected, to_select, player)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local pattern = sgs.Self:property("maware_use"):toString():split("+")
		if #cards == tonumber(pattern[1]) then
			local acard = sgs.Sanguosha:cloneCard(pattern[2], sgs.Card_SuitToBeDecided, -1)
			for _, card in ipairs(cards) do
				acard:addSubcard(card)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@maware"
	end
}
samsara = sgs.CreateTriggerSkill {
	name = "samsara",
	events = { sgs.CardUsed, sgs.EventPhaseStart },
	view_as_skill = samsaraVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			if player:getPhase() == sgs.Player_Play then
				local card = data:toCardUse().card
				if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
					if card:isKindOf("BasicCard") or card:isNDTrick() then
						local branch = player:property("maware_branch"):toString()
						if branch == "" then
							branch = card:objectName()
						else
							branch = branch .. "+" .. card:objectName()
						end
						room:setPlayerProperty(player, "maware_branch", sgs.QVariant(branch))
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local branch = player:property("maware_branch"):toString()
				branch = branch:split("+")
				local invoke = 0
				for i = 1, #branch, 1 do
					if player:getHandPile():length() >= i then break end
					local br = branch[i] or ""
					if br ~= "" and (not sgs.Sanguosha:cloneCard(branch[i], sgs.Card_NoSuit, 0):isAvailable(player)) then
						br = ""
					end
					local pattern = br
					pattern = pattern .. "+cancel"
					--if player:getAI() then return false end --AI救援
					local choice = room:askForChoice(player, self:objectName(), pattern, data)

					if choice and choice ~= "cancel" then
						room:setPlayerProperty(player, "maware_use", sgs.QVariant(tostring(i) .. "+" .. choice))
						if room:askForUseCard(player, "@@maware", "@samsara:" .. tostring(i) .. ":" .. choice) then
							invoke = i
						else
							room:setPlayerProperty(player, "maware_use", sgs.QVariant())
							break
						end
						room:setPlayerProperty(player, "maware_use", sgs.QVariant())
					else
						room:setPlayerProperty(player, "maware_use", sgs.QVariant())
						break
					end
				end
				room:setPlayerProperty(player, "maware_branch", sgs.QVariant())
				if invoke >= 2 then
					--room:addPlayerMark(player, "maware_do", 1)
					local playerdata = sgs.QVariant()
					playerdata:setValue(player)
					room:setTag("samsara", playerdata)
				end
			elseif player:getPhase() == sgs.Player_Start then
				room:setPlayerProperty(player, "maware_branch", sgs.QVariant())
				--[[elseif player:getPhase() == sgs.Player_NotActive then
				if player:getMark("maware_do") == 1 then
					room:removePlayerMark(player, "maware_do", 1)
					player:gainAnExtraTurn()
				end]]
			end
		end
	end
}
samsaraGive = sgs.CreateTriggerSkill {
	name = "#samsara-give",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("samsara") then
			local target = room:getTag("samsara"):toPlayer()
			room:removeTag("samsara")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}

--最后的反击
zuihoudefanji = sgs.CreateTriggerSkill
	{
		name = "zuihoudefanji",
		events = { sgs.Dying },
		frequency = sgs.Skill_Wake,
		waked_skills = "kuixin",
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() then
				room:addPlayerMark(player, "fanji_waked")
				room:addPlayerMark(player, self:objectName())
				room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				for _, p in sgs.qlist(room:getPlayers()) do
					room:notifyProperty(p, player, "role", player:getRole())
				end
				room:broadcastProperty(player, "role", player:getRole())
				room:updateStateItem()
				local log = sgs.LogMessage()
				log.type = "#ShowRole"
				log.from = player
				log.arg = player:getRole()
				room:sendLog(log)
				room:recover(player, sgs.RecoverStruct(player, nil, 3 - player:getHp()))
				room:setPlayerProperty(player, "general2", sgs.QVariant("yuru"))
				room:handleAcquireDetachSkills(player, "kuixin", true)
				--	room:changeHero(player, "yuru", false, true, true)
			end
			return false
		end,
		can_wake = function(self, event, player, data, room)
			if not player:hasSkill(self:objectName()) then return false end
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() then return false end
			if player:getMark("fanji_waked") > 0 then return false end
			if player:canWake(self:objectName()) then return true end
			return true
		end,
	}
--不死鸟
businiao = sgs.CreateTriggerSkill {
	name = "businiao",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|heart"
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		else
			if damage.from and damage.from:isAlive() and (not damage.from:isKongcheng()) then
				local poi = room:askForCardChosen(player, damage.from, "h", "businiao")
				room:obtainCard(player, poi, false)
				room:broadcastSkillInvoke(self:objectName(), 2)
			end
		end
	end
}
--战线防御
zhanxianfanyu = sgs.CreateTriggerSkill {
	name = "zhanxianfanyu",
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Draw and change.to ~= sgs.Player_Play then return false end
			if player:isSkipped(change.to) then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			if change.to == sgs.Player_Draw then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			end
			player:skip(change.to)
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "zhanxianfanyu-invoke",
				true, true)
			if not s then return false end
			s:gainMark("@zhanxianfanyu", 1)
			room:setPlayerMark(s, "&zhanxianfanyu+to+#" .. player:objectName(), 1)
			room:setPlayerMark(s, "zhanxianfanyu" .. player:objectName(), 1)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local all_players = room:getAllPlayers()
			for _, poi in sgs.qlist(all_players) do
				if poi:getMark("zhanxianfanyu" .. player:objectName()) > 0 then
					room:setPlayerMark(poi, "@zhanxianfanyu", 0)
					room:setPlayerMark(poi, "&zhanxianfanyu+to+#" .. player:objectName(), 0)
				end
			end
		end
	end
}
--战线防御二段技能
slash_defence = sgs.CreateTriggerSkill {
	name = "slash_defence",
	events = { sgs.DamageInflicted },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local supproter = room:findPlayerBySkillName("zhanxianfanyu")
		for _, supproter in sgs.qlist(room:findPlayersBySkillName("zhanxianfanyu")) do
			local damage = data:toDamage()
			if damage.card and damage.from then
				if damage.card:isKindOf("Slash") and supproter and damage.to:getMark("zhanxianfanyu" .. supproter:objectName()) then
					if supproter:askForSkillInvoke(self:objectName(), data) then
						local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
						duel:deleteLater()
						duel:setSkillName("zhanxianfanyu")
						room:useCard(sgs.CardUseStruct(duel, supproter, damage.from))
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
						return true
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getMark("@zhanxianfanyu") > 0
	end,
}
--革命机火焰技能
jixieshenslash = sgs.CreateTriggerSkill {
	name = "jixieshenslash",
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:isKindOf("Slash") and player:askForSkillInvoke(self:objectName(), data) then
			for _, p in sgs.qlist(use.to) do
				room:damage(sgs.DamageStruct("jixieshenslash", player, p, 1, sgs.DamageStruct_Fire))
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				if not player:isAlive() then break end
				local log = sgs.LogMessage()
				log.from = player
				log.arg = self:objectName()
				log.type = "#jixieshenfire"
				room:sendLog(log)
				use.to:removeOne(p)
				room:sortByActionOrder(use.to)
				local nullified_list = use.nullified_list
				table.insert(nullified_list, p:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
				room:addPlayerMark(player, self:objectName())
				p:setFlags("Global_NonSkillNullify")
			end
		end
	end
}
--拂晓伤害免疫
jixieshendefense = sgs.CreateTriggerSkill {
	name = "jixieshendefense",
	frequency = sgs.Skill_Compulsory,
	events = sgs.DamageInflicted,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal then
			local room = player:getRoom()
			local log = sgs.LogMessage()
			log.type = "#jixieshenmianyi"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			damage.prevented = true
			data:setValue(damage)
			return true
		end
	end
}
--高文卡牌变化
jixieshenchain = sgs.CreateOneCardViewAsSkill {
	name = "jixieshenchain",
	response_or_use = true,
	view_filter = function(self, card)
		if card:isEquipped() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if card:isRed() then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				slash:addSubcard(card:getEffectiveId())
				slash:deleteLater()
				return slash:isAvailable(sgs.Self)
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return card:isBlack()
			elseif pattern == "slash" then
				return card:isRed()
			end
		end
		return false
	end,
	view_as = function(self, card)
		local new_card
		if card:isBlack() then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:isRed() then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			new_card:addSubcard(card)
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" or pattern == "jink"
	end
}
local function changeRobot(player)
	local room = player:getRoom()
	room:changeTranslation(player, "jixieshen",0)
	local choices = {}
	if player:getMark("@gemingji") >= 1 then
		table.insert(choices, "gemingji")
	end
	if player:getMark("@fuxiao") >= 1 then
		table.insert(choices, "fuxiao")
	end
	if player:getMark("@gaowen") >= 1 then
		table.insert(choices, "gaowen")
	end
	if player:getMark("@siluokayi") >= 1 then
		table.insert(choices, "siluokayi")
	end
	local result = room:askForChoice(player, "jixieshen", table.concat(choices, "+"))
	if player:getGeneralName() == "siluokayi" or player:getGeneral2Name() == "siluokayi" then
		room:setPlayerMark(player, "@siluokayi", player:getHp())
	end
	if player:getGeneralName() == "gaowen" or player:getGeneral2Name() == "gaowen" then
		room:setPlayerMark(player, "@gaowen", player:getHp())
	end
	if player:getGeneralName() == "gemingji" or player:getGeneral2Name() == "gemingji" then
		room:setPlayerMark(player, "@gemingji", player:getHp())
	end
	if player:getGeneralName() == "fuxiao" or player:getGeneral2Name() == "fuxiao" then
		room:setPlayerMark(player, "@fuxiao", player:getHp())
	end

	room:changeHero(player, result, false, false,
		(player:getGeneral2Name() == "siluokayi") or (player:getGeneral2Name() == "gemingji") or
		(player:getGeneral2Name() == "fuxiao") or (player:getGeneral2Name() == "gaowen"), true)
	room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMark("@" .. result)))
	player:setSkillDescriptionSwap("jixieshen","%arg1", player:getMark("@gemingji"))
	player:setSkillDescriptionSwap("jixieshen","%arg2", player:getMark("@fuxiao"))
	player:setSkillDescriptionSwap("jixieshen","%arg3", player:getMark("@gaowen"))
	player:setSkillDescriptionSwap("jixieshen","%arg4", player:getMark("@siluokayi"))
	room:changeTranslation(player, "jixieshen",1)
	room:setPlayerMark(player, "@" .. result, 0)
					
end
--机械公敌
jixieshen = sgs.CreateTriggerSkill {
	name = "jixieshen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TurnStart, sgs.GameStart, sgs.AskForPeachesDone },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--local s=room:findPlayerBySkillName(self:objectName())
		if event == sgs.GameStart then
			room:setPlayerMark(player, "@gemingji", 2)
			room:setPlayerMark(player, "@gaowen", 2)
			room:setPlayerMark(player, "@fuxiao", 2)
		elseif event == sgs.TurnStart then
			-- if player:getMark("@fuxiao") == 0 and player:getMark("@gaowen") == 0 and player:getMark("@gemingji") == 0 and player:getMark("@siluokayi") == 0 then
			-- 	local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
			-- 		"jixieshendamage", true, true)
			-- 	room:damage(sgs.DamageStruct("jixieshen", player, target, 1, sgs.DamageStruct_Thunder))
			-- 	room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			-- end
			if (player:getMark("@gemingji") <= 1 or player:getMark("@fuxiao") <= 1 or player:getMark("@gaowen") <= 1) and not player:isKongcheng() and player:askForSkillInvoke(self:objectName(), sgs.QVariant("fixmachine")) then
				room:askForDiscard(player, self:objectName(), 1, 1, false, false)
				local choices = {}
				if player:getMark("@gemingji") <= 1 then
					table.insert(choices, "gemingji")
				end
				if player:getMark("@fuxiao") <= 1 then
					table.insert(choices, "fuxiao")
				end
				if player:getMark("@gaowen") <= 1 then
					table.insert(choices, "gaowen")
				end
				local result = room:askForChoice(player, self:objectName() .. "fixmachine", table.concat(choices, "+"))
				room:addPlayerMark(player, "@" .. result, 1)
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
				local log = sgs.LogMessage()
				log.type = "#jixieshenfixmachine"
				log.from = player
				log.arg = result
				room:sendLog(log)
			end
			if player:getMark("@gemingji") >= 1 or player:getMark("@fuxiao") >= 1 or player:getMark("@siluokayi") >= 1 or player:getMark("@gaowen") >= 1 then
				if player:askForSkillInvoke(self:objectName(), data) then
					changeRobot(player)
					local x = math.random(5, 6)
					if player:getGeneralName() == "gaowen" or player:getGeneral2Name() == "gaowen" then
						x = math.random(7, 8)
					elseif player:getGeneralName() == "gemingji" or player:getGeneral2Name() == "gemingji" then
						x = math.random(9, 10)
					elseif player:getGeneralName() == "siluokayi" or player:getGeneral2Name() == "siluokayi" then
						x = math.random(11, 12)
					elseif player:getGeneralName() == "fuxiao" or player:getGeneral2Name() == "fuxiao" then
						x = math.random(13, 14)
					end
					room:broadcastSkillInvoke(self:objectName(), x)
				end
			end
		elseif event == sgs.AskForPeachesDone then
			if ((player:getGeneralName() == "gemingji" or player:getGeneral2Name() == "gemingji") or (player:getGeneralName() == "fuxiao" or player:getGeneral2Name() == "fuxiao")or (player:getGeneralName() == "gaowen" or player:getGeneral2Name() == "gaowen")) and room:askForSkillInvoke(player, self:objectName()) then
				changeRobot(player)
				return true
			end
			-- if player:getMark("@fuxiao") == 0 and player:getMark("@gaowen") == 0 and player:getMark("@gemingji") == 0 and player:getMark("@siluokayi") == 0 then
			-- 	local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
			-- 		"jixieshendamage", true, true)
			-- 	room:damage(sgs.DamageStruct("jixieshen", player, target, 1, sgs.DamageStruct_Thunder))
			-- 	room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			-- end
		end
	end
}

loyal_inu = sgs.CreateTriggerSkill {
	name = "loyal_inu",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Limited,
	limit_mark = "@inu_from",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:getMark("@inu_to") == 0 then
					targets:append(p)
				end
			end
			local to = room:askForPlayerChosen(player, targets, self:objectName(), nil, true)
			if to then
				local log = sgs.LogMessage()
				log.type = "#ChoosePlayerWithSkill"
				log.from = player
				log.arg = self:objectName()
				log.to:append(to)
				room:sendLog(log)
				room:setPlayerMark(player, "@inu_from", 0)
				room:setPlayerMark(to, "@inu_to", 1)
				room:setPlayerMark(to, "&loyal_inu+to+#" .. player:objectName(), 1)
				room:setPlayerMark(to, "loyal_inu" .. player:objectName(), 1)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
			and target:hasSkill(self:objectName())
			and target:getMark("@inu_from") > 0
			and target:getPhase() == sgs.Player_Start
	end
}

loyal_inu_damage = sgs.CreateTriggerSkill {
	name = "loyal_inu_damage",
	events = { sgs.DamageInflicted },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		for _, source in sgs.qlist(room:findPlayersBySkillName("loyal_inu")) do
			if damage.damage > 1 and player:getMark("loyal_inu" .. source:objectName()) > 0 then
				local reduce = damage.damage - 1
				damage.damage = 1
				room:sendCompulsoryTriggerLog(source, self:objectName()) --或者自己写一个log
				data:setValue(damage)
				local from = damage.from or nil
				room:damage(sgs.DamageStruct(damage.reason, from, source, reduce, damage.nature))
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("@inu_to") > 0
	end
}
loyalex = sgs.CreateTriggerSkill {
	name = "loyalex",
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local victim = death.who
		if death.who:getMark("@inu_to") == 1 then
			room:handleAcquireDetachSkills(player, "-kikann")
			player:gainMark("yihan")
		end
	end
}
DSTP = sgs.CreateTriggerSkill {
	name = "DSTP",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.damage > 1 then
			damage.damage = 1
			room:sendCompulsoryTriggerLog(player, self:objectName()) --或者自己写一个log
			data:setValue(damage)
		end
		if damage.card and damage.card:isKindOf("Duel") and player:getMark("yihan") == 1 then
			damage.damage = 0
			data:setValue(damage)
			room:sendCompulsoryTriggerLog(player, self:objectName())
			return true
		end
	end,
}

kikann = sgs.CreateTriggerSkill {
	name = "kikann",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local source
			for _, p in sgs.qlist(room:findPlayersBySkillName("loyal_inu")) do
				if player:getMark("loyal_inu" .. p:objectName()) > 0 then
					source = p
					break
				end
			end
			if not source then return false end
			local ori_choice = { "kikann_1", "kikann_2" }
			local choices = {}
			for _, effcet in ipairs(ori_choice) do
				if player:getMark(effcet) == 0 then
					table.insert(choices, effcet)
				end
			end
			if #choices == 0 then
				choices = ori_choice
				for _, effcet in ipairs(ori_choice) do
					room:setPlayerMark(player, effcet, 0)
				end
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			if choice ~= "cancel" then
				room:sendCompulsoryTriggerLog(source, self:objectName(), true)
				if choice == "kikann_1" then
					room:broadcastSkillInvoke(self:objectName(), 1)
					local hf = math.min(source:getHp(), player:getMaxHp())
					room:setPlayerProperty(player, "hp", sgs.QVariant(hf))
				else
					room:broadcastSkillInvoke(self:objectName(), 2)
					local n = source:getHandcardNum() - player:getHandcardNum()
					if n < 0 then
						room:askForDiscard(player, self:objectName(), -n, -n, false, false)
					elseif n > 0 then
						player:drawCards(n, self:objectName())
					end
				end
				room:setPlayerMark(player, choice, 1)
				player:setTag("kikann", sgs.QVariant(choice))
			else
				player:setTag("kikann", sgs.QVariant())
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("@inu_to") > 0
	end
}
--[[--光子巨炮
guangzijupaoCard = sgs.CreateSkillCard{
	name = "guangzijupaoCard",
	filter = function(self, targets, to_select)
		if (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() then
			return sgs.Self:inMyAttackRange(to_select) and not to_select:isNude()
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if target:isDead() then return end
		local id = room:askForCardChosen(source, target, "he", "guangzijupao")
		local cd = sgs.Sanguosha:getCard(id)
		local subcd = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:showCard(target, id)
		if cd:sameColorWith(subcd) then
			local ucard = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
			ucard:setSkillName("guangzijupao")
			room:useCard(sgs.CardUseStruct(ucard, source, target))
		else
			room:throwCard(cd, target, source)
		end
	end,
}
guangzijupaoVS = sgs.CreateOneCardViewAsSkill{
	name = "guangzijupao",
	view_filter = function(self, card)
		return not card:isEquipped()
	end,
	view_as = function(self, cards)
		local rdcard = guangzijupaoCard:clone()
		rdcard:addSubcard(cards)
		return rdcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#guangzijupaoCard")
	end
}
guangzijupao = sgs.CreateTriggerSkill{
	name = "guangzijupao",
	events = {sgs.PreCardUsed},
	view_as_skill = guangzijupaoVS,
	on_trigger = function(self, event, player, data, room)
		if data:toCardUse().card:getSkillName() == "guangzijupao" then return true end
	end
}
--蓝羽化
lanyuhua = sgs.CreateTriggerSkill{
	name = "lanyuhua",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			player:gainMark("@lanyu")
		end
	end,
}
lanyuhuaAtR = sgs.CreateAttackRangeSkill{
	name = "#lanyuhuaAtR",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("lanyuhua") and player:getMark("baozou") == 0 then
			return math.min(player:getMark("@lanyu"), player:getMaxHp())
		end
	end,
}
lanyuhuaMxC = sgs.CreateMaxCardsSkill{
	name = "#lanyuhuaMxC",
	extra_func = function(self, target)
		if target:hasSkill("lanyuhua") then
			return math.min(target:getMark("@lanyu"), target:getMaxHp())
		end
	end
}
extension:insertRelatedSkills("lanyuhua", "#lanyuhuaAtR")
extension:insertRelatedSkills("lanyuhua", "#lanyuhuaMxC")
--暴走
baozou = sgs.CreateTriggerSkill{
	name = "baozou",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("@lanyu") > player:getHp() and player:getMark("baozou") == 0 then
				room:doSuperLightbox("BlackRockShooter", "$baozouQP")
				msg.type = "#baozouEffect"
				msg.arg = "jueduiyazhi"
				msg.arg2 = 1
				msg.from = player
				room:sendLog(msg)
				room:broadcastSkillInvoke("baozou", math.random(1, 2))  --语音
				room:setPlayerMark(player, "baozou", 1)
				room:addPlayerMark(player, "@waked")
				local maxhp = player:getMaxHp() + 1
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
				room:recover(player, sgs.RecoverStruct(player))
				room:detachSkillFromPlayer(player, "guangzijupao")
				room:acquireSkill(player, "jueduiyazhi")
			end
		end
	end,
}
--绝对压制
jueduiyazhiCard = sgs.CreateSkillCard{
	name = "jueduiyazhiCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() ~= sgs.Self:objectName() then
			return #targets < sgs.Self:getMark("@lanyu")
		end
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@lanyu", #targets)
		for _,p in pairs(targets) do
			p:setCardLimitation("use,response", ".|.|.|hand", true)
			room:setPlayerFlag(p, "jdyz")
		end
	end,
}
jueduiyazhiVS = sgs.CreateZeroCardViewAsSkill{
	name = "jueduiyazhi",
	view_as = function(self, cards)
		return jueduiyazhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#jueduiyazhiCard") and player:getMark("@lanyu") > 0
	end
}
jueduiyazhi = sgs.CreateTriggerSkill{
	name = "jueduiyazhi",
	events = {sgs.EventPhaseChanging, sgs.Damage, sgs.PreCardUsed},
	view_as_skill = jueduiyazhiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					p:removeCardLimitation("use,response", ".|.|.|hand$1")
					room:setPlayerFlag(p, "-jdyz")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.to:isAlive() and (not damage.to:isNude()) and damage.to:hasFlag("jdyz") then
				if not room:askForCard(player, ".|"..damage.card:getSuitString(), "@jdyzask:"..damage.card:getSuitString(), sgs.QVariant(), self:objectName()) then
					room:loseHp(player)
				end
				if not damage.to:isNude() then
					local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
					room:obtainCard(player, id)
				end
			end
		elseif event == sgs.PreCardUsed then
			if data:toCardUse().card:getSkillName() == "jueduiyazhi" then return true end
		end
	end,
}
]]

--光子巨炮
guangzijupaoCard = sgs.CreateSkillCard {
	name = "guangzijupaoCard",
	filter = function(self, targets, to_select)
		if (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() then
			return sgs.Self:inMyAttackRange(to_select) and not to_select:isNude()
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if target:isDead() then return end
		local id = room:askForCardChosen(source, target, "he", "guangzijupao")
		local cd = sgs.Sanguosha:getCard(id)
		local subcd = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:showCard(target, id)
		local choice = room:askForChoice(source, "guangzijupao", "gzjpdis+gzjpslash")
		if choice == "gzjpdis" then
			room:throwCard(cd, target, source)
		elseif choice == "gzjpslash" then
			local ucard = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
			ucard:setSkillName("guangzijupao")
			room:useCard(sgs.CardUseStruct(ucard, source, target))
		end
	end,
}
guangzijupao = sgs.CreateOneCardViewAsSkill {
	name = "guangzijupao",
	view_filter = function(self, card)
		return true
	end,
	view_as = function(self, cards)
		local rdcard = guangzijupaoCard:clone()
		rdcard:addSubcard(cards)
		return rdcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#guangzijupaoCard")
	end
}
--蓝羽化
lanyuhua = sgs.CreateTriggerSkill {
	name = "lanyuhua",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage then
			--[[if event == sgs.Damage then
				room:broadcastSkillInvoke("lanyuhua", 1)
			elseif event == sgs.Damaged then
				room:broadcastSkillInvoke("lanyuhua", 2)
			end]] --
			player:gainMark("@lanyu", 1)
		end
	end,
}
lanyuhuaAtR = sgs.CreateAttackRangeSkill {
	name = "#lanyuhuaAtR",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("lanyuhua") and player:getMark("kuanghua") == 0 then
			return math.min(player:getMark("@lanyu"), player:getMaxHp())
		end
	end,
}
lanyuhuaSla = sgs.CreateTargetModSkill {
	name = "#lanyuhuaSla",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("lanyuhua") and player:getMark("kuanghua") > 0 then
			return math.min(player:getMark("@lanyu"), player:getMaxHp())
		end
	end
}
--[[lanyuhuaMxC = sgs.CreateMaxCardsSkill{
	name = "#lanyuhuaMxC",
	extra_func = function(self, target)
		if target:hasSkill("lanyuhua") then
			return math.min(target:getMark("@lanyu"), target:getMaxHp())
		end
	end
}]] --

--狂化
kuanghua = sgs.CreateTriggerSkill {
	name = "kuanghua",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("@lanyu") > player:getHp() and player:getMark("kuanghua") == 0 then
				msg.type = "#kuanghua1Effect"
				msg.from = player
				room:sendLog(msg)
				room:broadcastSkillInvoke("kuanghua", 1) --语音
				room:setPlayerMark(player, "kuanghua", 1)
				room:detachSkillFromPlayer(player, "guangzijupao")
				room:acquireSkill(player, "jueduiyazhi")
				if player:getGeneralName() == "BlackRockShooter" then
					room:setPlayerProperty(player, "general", sgs.QVariant("insaneBlackRockShooter"))
				elseif player:getGeneral2Name() == "BlackRockShooter" then
					room:setPlayerProperty(player, "genera2", sgs.QVariant("insaneBlackRockShooter"))
				end
			elseif player:getMark("@lanyu") <= player:getHp() and player:getMark("kuanghua") > 0 then
				msg.type = "#kuanghua2Effect"
				msg.from = player
				room:broadcastSkillInvoke("kuanghua", 2) --语音
				room:setPlayerMark(player, "kuanghua", 0)
				room:detachSkillFromPlayer(player, "jueduiyazhi")
				room:acquireSkill(player, "guangzijupao")
				if player:getGeneralName() == "insaneBlackRockShooter" then
					room:setPlayerProperty(player, "general", sgs.QVariant("BlackRockShooter"))
				elseif player:getGeneral2Name() == "insaneBlackRockShooter" then
					room:setPlayerProperty(player, "genera2", sgs.QVariant("BlackRockShooter"))
				end
			end
		end
	end,
}
--绝对压制
jueduiyazhiCard = sgs.CreateSkillCard {
	name = "jueduiyazhiCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() ~= sgs.Self:objectName() then
			return #targets < sgs.Self:getMark("@lanyu")
		end
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@lanyu", #targets)
		for _, p in pairs(targets) do
			-- p:setCardLimitation("use,response", ".|.|.|hand", true)
			room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", true)
			room:setPlayerFlag(p, "jdyz")
			room:addPlayerMark(p, "&jueduiyazhi+to+#" .. source:objectName() .. "-Clear")
		end
	end,
}
jueduiyazhiVS = sgs.CreateZeroCardViewAsSkill {
	name = "jueduiyazhi",
	view_as = function(self, cards)
		return jueduiyazhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#jueduiyazhiCard")) and player:getMark("@lanyu") > 0
	end
}
jueduiyazhi = sgs.CreateTriggerSkill {
	name = "jueduiyazhi",
	events = { sgs.EventPhaseChanging, sgs.Damage },
	view_as_skill = jueduiyazhiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					p:removeCardLimitation("use,response", ".|.|.|hand$1")
					room:setPlayerFlag(p, "-jdyz")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to:hasFlag("jdyz") then
				local choicelist = "jueduiyazhi_losehp"
				if player:getMark("@lanyu") > 1 then
					choicelist = string.format("%s+%s", choicelist, "jueduiyazhi_loseMark")
				end
				local choice = room:askForChoice(player, "jueduiyazhi", choicelist)
				if choice == "jueduiyazhi_losehp" then
					room:loseHp(player)
				else
					player:loseMark("@lanyu", 2)
				end
				--[[if player:getMark("@lanyu") > 1  then
					player:loseMark("@lanyu",2)
				else
					room:loseHp(player)
				end]]
				if damage.to:isAlive() and (not damage.to:isNude()) then
					local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
					room:obtainCard(player, id)
				end
			end
		end
	end,
}

--进化
jinhua = sgs.CreateTriggerSkill {
	name = "jinhua",
	events = { sgs.Death },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if room:askForSkillInvoke(player, self:objectName()) and player:getMark("@jinhua") < player:getMaxHp() then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(2)
			player:gainMark("@jinhua", 1)
			if player:isWounded() then
				room:recover(player, sgs.RecoverStruct(player))
			end
		end
		return false
	end
}
--五段提升
wuduan = sgs.CreateTriggerSkill {
	name = "wuduan",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	waked_skills = "tisheng",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local msg = sgs.LogMessage()
		room:setPlayerMark(player, "wuduan", 1)
		if room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) then
			room:loseHp(player, 1, true, player, self:objectName())
			room:acquireSkill(player, "tisheng")
			room:broadcastSkillInvoke("wuduan")
			return false
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		if player:getMark("@jinhua") >= player:getHp() then
			return true
		end
		return false
	end
}

--提升
tisheng = sgs.CreateTriggerSkill {
	name = "tisheng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.DrawNCards },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("@jinhua") < player:getMaxHp() then
			end
		else
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			room:loseHp(player, 1)
			local n = math.min(player:getMark("@jinhua"), player:getMaxHp())
			draw.num = draw.num + n
			room:broadcastSkillInvoke("tisheng", 1)
			data:setValue(draw)
		end
	end
}

--御免：锁定技。当你进入濒死状态时，你须展示牌堆顶的一张牌，若为锦囊牌，则你弃置这张牌，回复至1点体力，否则你获得之。

Luayumian = sgs.CreateTriggerSkill {
	name = "Luayumian",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EnterDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())

		local see = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct(
			see,
			player,
			sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
		)
		room:moveCardsAtomic(move, true)

		local first = see:first()
		local card = sgs.Sanguosha:getCard(first)

		room:fillAG(see, player)

		if card:isKindOf("TrickCard") then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
				self:objectName(), "")
			room:throwCard(card, reason, nil)
			room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(), self:objectName(),
				"")
			room:obtainCard(player, card, reason)
		end
		room:getThread():delay()
		room:clearAG()
	end
}
--掩护
Luayanhu = sgs.CreateTriggerSkill {
	name = "Luayanhu",
	frequency = sgs.Skill_NotFrequent,
	events = sgs.DamageInflicted,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local victim = damage.to
		local source = damage.from
		local x = damage.damage
		for _, launch in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if launch:objectName() ~= victim:objectName() and launch:distanceTo(player) <= 1 then
				local victim_data = sgs.QVariant()
				victim_data:setValue(victim)
				if launch:askForSkillInvoke(self:objectName(), data) then
					if damage.card and damage.card:isKindOf("Slash") then
						victim:removeQinggangTag(damage.card)
					end
					damage.to = launch
					damage.transfer = true
					room:damage(damage)
					return true
				end
			end


			--room:damage(sgs.DamageStruct(self:objectName(),source, launch,x,damage.nature))
			--damage.damage =0
			--if damage.damage < 1 then

			-- end
		end
	end,

	can_trigger = function(self, target)
		return true
	end

}

xinsuo = sgs.CreateTriggerSkill {
	name = "xinsuo",
	events = { sgs.EventPhaseEnd, sgs.Death },
	on_trigger = function(self, event, player, data, room)
		local yoshiko = room:findPlayerBySkillName("xinsuo")
		if event == sgs.EventPhaseEnd then
			if player:getPhase() ~= sgs.Player_Finish or not yoshiko or player:isDead() then return false end
			if room:askForSkillInvoke(yoshiko, self:objectName(), data) then
				room:broadcastSkillInvoke("xinsuo")
				local choice = room:askForChoice(yoshiko, self:objectName(), "lord+loyalist+rebel+renegade")
				room:removePlayerMark(player, "@" .. player:property("xinsuo_set"):toString())
				room:addPlayerMark(player, "@" .. choice)
				room:setPlayerProperty(player, "xinsuo_set", sgs.QVariant(choice))
			end
		else
			local death = data:toDeath()
			if not yoshiko or yoshiko:objectName() == death.who:objectName() or death.who:objectName() ~= player:objectName() then return false end
			if death.who:property("xinsuo_set"):toString() == death.who:getRole() then
				room:sendCompulsoryTriggerLog(yoshiko, self:objectName())
				room:broadcastSkillInvoke("xinsuo")
				yoshiko:drawCards(2)
			end
			room:setPlayerProperty(death.who, "xinsuo", sgs.QVariant())
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

yohaneCard = sgs.CreateSkillCard {
	name = "yohane",
	filter = function(self, targets, to_select) --此处不可用to_select:getCards("hej"):length()<2
		if to_select:property("xinsuo_set"):toString() == "" or to_select:getCardCount(true, true) < 2 then return false end
		if #targets == 0 then return true end
		if #targets >= 1 then
			for _, selected in sgs.list(targets) do
				if selected:property("xinsuo_set"):toString() == to_select:property("xinsuo_set"):toString() then
					return false
				end
			end
			return true
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets ~= 0
	end,
	on_use = function(self, room, source, targets)
		local ts = sgs.SPlayerList()
		local tos = {}
		for _, to in ipairs(targets) do
			if to:isAllNude() then continue end
			room:setPlayerFlag(to, "yohane_InTempMoving")
			local first_id = room:askForCardChosen(source, to, "hej", "yohane")
			local original_place = room:getCardPlace(first_id)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:addSubcard(first_id)
			to:addToPile("#yohane", dummy, false)
			if not to:isAllNude() then
				local second_id = room:askForCardChosen(source, to, "hej", "yohane")
				dummy:addSubcard(second_id)
			end
			room:moveCardTo(sgs.Sanguosha:getCard(first_id), to, original_place, false)
			room:setPlayerFlag(to, "-yohane_InTempMoving")
			room:moveCardTo(dummy, source, sgs.Player_PlaceHand, false)
			dummy:deleteLater()
			ts:append(to)
		end

		for _, to in sgs.list(ts) do --防太平要术/倚天剑
			if to:isDead() then
				ts:removeOne(to)
			end
		end

		local count = ts:length() * 2
		--source:speak(count)

		for i = 1, count, 1 do
			if source:isNude() or ts:length() == 0 then break end
			local ObjectTable = {}
			for _, to in sgs.qlist(ts) do
				table.insert(ObjectTable, to:objectName())
			end
			local prompt = "#yohane-distribute:" .. table.concat(ObjectTable, ":")
			local xcard = room:askForCard(source, ".!", prompt, sgs.QVariant(table.concat(ObjectTable, "+")),
				sgs.Card_MethodNone)
			local choices = { "ph" }
			local pt = room:askForPlayerChosen(source, ts, self:objectName())

			if xcard:isKindOf("EquipCard") then
				local equip = xcard:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if pt:getEquip(equip_index) == nil then
					table.insert(choices, "pe")
				end
			elseif xcard:isKindOf("DelayedTrick") then
				if not source:isProhibited(pt, xcard) and not pt:containsTrick(xcard:objectName()) then
					table.insert(choices, "pj")
				end
			end
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
			if choice == "ph" then
				room:moveCardTo(xcard, source, pt, sgs.Player_PlaceHand,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), "yohane", ""))
			elseif choice == "pe" then
				room:moveCardTo(xcard, source, pt, sgs.Player_PlaceEquip,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "yohane", ""))
			else
				room:moveCardTo(xcard, source, pt, sgs.Player_PlaceDelayedTrick,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), "yohane", ""))
			end
			for _, to in sgs.list(ts) do --防目标暴死
				if to:isDead() then
					ts:removeOne(to)
				end
			end
			if pt:isAlive() then
				room:addPlayerMark(pt, "yohane_given")
				if pt:getMark("yohane_given") == 2 then
					room:setPlayerMark(pt, "yohane_given", 0)
					ts:removeOne(pt)
				end
			end
		end
	end
}

yohane = sgs.CreateZeroCardViewAsSkill {
	name = "yohane",
	view_as = function(self)
		local acard = yohaneCard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#yohane")
	end
}

fengfu = sgs.CreateTriggerSkill {
	name = "fengfu",
	events = { sgs.TargetConfirmed, sgs.SlashEffected },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local yoshiko = room:findPlayerBySkillName(self:objectName())
			if not use.card:isKindOf("Slash") or use.from:property("xinsuo_set"):toString() == "" or not yoshiko or player:objectName() ~= use.from:objectName() then return false end
			for _, t in sgs.qlist(use.to) do
				if t:property("xinsuo_set"):toString() == "" then
					continue
				elseif t:property("xinsuo_set"):toString() == use.from:property("xinsuo_set"):toString() then
					room:sendCompulsoryTriggerLog(yoshiko, self:objectName())
					room:broadcastSkillInvoke("fengfu")
					local dest = sgs.QVariant()
					dest:setValue(t)
					if not room:askForCard(use.from, ".|black|.|hand", "@fengfu-discard", dest) then
						room:addPlayerMark(t, "@fengfu_x", 1)
					end
				elseif t:property("xinsuo_set"):toString() ~= use.from:property("xinsuo_set"):toString() then
					room:sendCompulsoryTriggerLog(yoshiko, self:objectName())
					room:broadcastSkillInvoke("fengfu")
					use.from:drawCards(2)
					room:askForDiscard(use.from, self:objectName(), 2, 2)
				end
			end
		else
			local effect = data:toSlashEffect()
			if effect.to:getMark("@fengfu_x") > 0 then
				room:removePlayerMark(effect.to, "@fengfu_x", 1)
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

mingchuan = sgs.CreateFilterSkill {
	name = "mingchuan",
	view_filter = function(self, to_select)
		return true
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Spade)
		new_card:setNumber(6)
		new_card:setModified(true)
		return new_card
	end,
}

yohaneFakeMove = sgs.CreateTriggerSkill { --fakeMove触发技
	name = "yohaneFakeMove",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	global = true,
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("yohane_InTempMoving") then
			--player:speak("InTempMoving!")
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

function NextSuit(x)
	if (x == 0) then
		return 2
	elseif (x == 1) then
		return 3
	elseif (x == 2) then
		return 1
	elseif (x == 3) then
		return 0
	else
		return -1
	end
end

function HaiyinCard(player)
	if player:getPile("yun"):isEmpty() then
		return -1
	end
	return player:getPile("yun"):first()
end

function LoseByDiscard(move)
	if (move.to_place == sgs.Player_DiscardPile) then
		local reason = move.reason.m_reason
		return reason and bit32.band(reason, 0x0F) == 0x03
	else
		return false
	end
end

function PlayerCardLose(player, move)
	if (move.from and (move.from:objectName() == player:objectName())
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)))
		and not (move.to
			and (move.to:objectName() == player:objectName()
				and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
		return true
	else
		return false
	end
end

function PlayerUse2DiscardPile(player, move)
	local reason = move.reason.m_reason
	if (move.from and move.from:objectName() == player:objectName()) then
		return move.to_place == sgs.Player_DiscardPile and reason and bit32.band(reason, 0x0F) == 0x01
	end
	return false
end

haiyin = sgs.CreateTriggerSkill {
	name = "haiyin",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if (PlayerCardLose(player, move) and LoseByDiscard(move)) or PlayerUse2DiscardPile(player, move) then
			local ids = sgs.IntList()
			local haiyin_id = HaiyinCard(player)
			local next_suit = -1
			if (haiyin_id ~= -1) then
				next_suit = NextSuit(sgs.Sanguosha:getCard(haiyin_id):getSuit())
			end
			for _, id in sgs.qlist(move.card_ids) do
				if room:getCardPlace(id) == sgs.Player_DiscardPile then
					if next_suit >= 0 then
						if sgs.Sanguosha:getCard(id):getSuit() == next_suit then
							ids:append(id)
						end
					else
						if sgs.Sanguosha:getCard(id):getSuit() >= 0 or sgs.Sanguosha:getCard(id):getSuit() <= 3 then
							ids:append(id)
						end
					end
				end
			end

			if ids:isEmpty() then return false end
			local id
			if ids:length() == 1 then
				id = ids:first()
			else
				room:fillAG(ids, player)
				id = room:askForAG(player, ids, false, self:objectName())
				room:clearAG(player)
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if HaiyinCard(player) then
				player:clearOnePrivatePile("yun")
			end
			player:addToPile("yun", id)
			player:drawCards(1)
		end
	end,
}

fuzou = sgs.CreateTriggerSkill {
	name = "fuzou",
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data, room)
		local riko = room:findPlayerBySkillName("fuzou")
		if not riko then return false end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("TrickCard") and not riko:getPile("yun"):isEmpty() then
			if room:askForSkillInvoke(riko, self:objectName(), data) then
				riko:clearOnePrivatePile("yun")
				local t = room:askForPlayerChosen(riko, use.to, self:objectName())
				if t:hasSkill("fuzou_filter") then return false end
				room:setPlayerFlag(t, "fuzou_t")
				room:attachSkillToPlayer(t, "fuzou_filter")
				room:filterCards(t, t:getHandcards(), false)
				room:addPlayerMark(t, "&fuzou-Clear")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

fuzou_clear = sgs.CreateTriggerSkill {
	name = "fuzou_clear",
	global = true,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data, room)
		if data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("fuzou_t") then
					room:detachSkillFromPlayer(p, "fuzou_filter", true)
					room:filterCards(p, p:getHandcards(), true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--复奏（锁定视为技）
fuzou_filter = sgs.CreateFilterSkill {
	name = "fuzou_filter&", --不知道为什么用#fuzou_filter当name会隐藏失败而且会detach失败，暂且这样处理
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:getSuit() ~= sgs.Card_Heart and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
		slash:setSkillName("fuzou")
		local card = sgs.Sanguosha:getWrappedCard(card:getId())
		card:takeOver(slash)
		return card
	end,
}

fanyi = sgs.CreateTriggerSkill {
	name = "fanyi",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			if not room:askForSkillInvoke(player, "fanyi") then return false end
			local fourcard = room:getNCards(4)
			room:fillAG(fourcard, player)
			local alternative = { "1range_ad", "2maxcard_ad", "3available_ad", "4target_ad", "5draw_ad" }
			local options = { "1range_re", "2maxcard_re", "3available_re", "4target_re", "5draw_re" }
			local chosen, choices = {}, {}
			room:broadcastSkillInvoke("fanyi")
			local choice = room:askForChoice(player, self:objectName(), table.concat(alternative, "+")) --1
			--第一次选择加数值
			--if choice ~= "cancel" then
			table.removeOne(alternative, choice)
			table.removeOne(options, string.sub(choice, 1, -4) .. "_re")
			table.insert(chosen, choice)

			--test
			--player:speak(table.concat(alternative,"\f"))
			--player:speak(table.concat(options,"\f"))

			for _, v in ipairs(options) do
				table.insert(choices, v)
			end
			for _, v in ipairs(alternative) do
				table.insert(choices, v)
			end
			table.sort(choices)

			choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+")) --2
			--第二次在除去第一次选择的项中选择含+-的项（此时不可选取消）
			table.insert(chosen, choice)

			if string.find(choice, "_ad") then
				--如果第二次也选择了加数值（++=>--）
				table.removeOne(options, string.sub(choice, 1, -4) .. "_re")
				local choice3 = room:askForChoice(player, self:objectName(), table.concat(options, "+")) --3
				table.removeOne(options, choice3)
				table.insert(chosen, choice3)
				local choice4 = room:askForChoice(player, self:objectName(), table.concat(options, "+")) --4
				table.removeOne(options, choice4)
				table.insert(chosen, choice4)
			else
				--test
				--player:speak(table.concat(alternative,"\f"))
				--player:speak(table.concat(options,"\f"))
				--如果第二次选择了减数值
				table.removeOne(alternative, string.sub(choice, 1, -4) .. "_ad")
				table.removeOne(options, choice)

				choices = {}
				for _, v in ipairs(options) do
					table.insert(choices, v)
				end
				for _, v in ipairs(alternative) do
					table.insert(choices, v)
				end
				table.sort(choices)

				choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+") .. "+done") --3
				if choice ~= "done" then
					table.insert(chosen, choice)
					if string.find(choice, "_ad") then
						--"+-+=>--to-"
						table.removeOne(options, string.sub(choice, 1, -4) .. "_re")
						table.insert(chosen, room:askForChoice(player, self:objectName(), table.concat(options, "+")))
					else
						--"+--=>++to+"
						table.removeOne(alternative, string.sub(choice, 1, -4) .. "_ad")
						table.insert(chosen, room:askForChoice(player, self:objectName(), table.concat(alternative, "+")))
					end
				end
			end
			--end

			local msg = sgs.LogMessage()
			msg.type = "#fanyi-choices"
			msg.from = player
			msg.arg = self:objectName()
			for _, v in ipairs(chosen) do
				msg.arg2 = "fanyi:" .. v
				room:setPlayerFlag(player, v)
				room:sendLog(msg)
			end
			room:clearAG()
			room:returnToTopDrawPile(fourcard)
		end
	end,
}

fanyiAttackRange = sgs.CreateAttackRangeSkill {
	name = "fanyiAttackRange",
	extra_func = function(self, player)
		if player:hasFlag("1range_ad") then
			return 1
		elseif player:hasFlag("1range_re") then
			return -1
		end
		return 0
	end,
}

fanyiMaxCards = sgs.CreateMaxCardsSkill {
	name = "fanyiMaxCards",
	extra_func = function(self, target)
		if target:hasFlag("2maxcard_ad") then
			return 1
		elseif target:hasFlag("2maxcard_re") then
			return -1
		end
		return 0
	end,
}

fanyiTargetMod = sgs.CreateTargetModSkill {
	name = "fanyiTargetMod",
	--[[	extra_target_func = function(self, from, card)
		if from:hasFlag("4target_ad") and (card:isKindOf("Slash") or card:isNDTrick()) then
			return 1
		elseif from:hasFlag("4target_re") and (card:isKindOf("Slash") or card:isNDTrick()) then
			return -1
		end
		return 0
	end,]]
	residue_func = function(self, from, card)
		if from:hasFlag("3available_ad") and card:isKindOf("Slash") then
			return 1
		elseif from:hasFlag("3available_re") and card:isKindOf("Slash") then
			return -1
		end
		return 0
	end,
	distance_limit_func = function(self, player, card)
		if player:hasFlag("FanyiExtraTarget") then
			return 1000
		else
			return 0
		end
	end,
}

fanyiGlobalUse = sgs.CreateTriggerSkill {
	name = "fanyiGlobalUse",
	global = true,
	events = { sgs.PreCardUsed },
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:isNDTrick() or use.card:isKindOf("Slash") then
			local choice
			if player:hasFlag("4target_ad") then
				room:setPlayerFlag(player, "-4target_ad")
				choice = "add"
			elseif player:hasFlag("4target_re") then
				room:setPlayerFlag(player, "-4target_re")
				choice = "remove"
			else
				return false
			end
			--player:speak("point1")
			if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
			--player:speak("point1.1")
			local available_targets = sgs.SPlayerList()
			if (not use.card:isKindOf("AOE")) and (not use.card:isKindOf("GlobalEffect")) then
				room:setPlayerFlag(player, "FanyiExtraTarget")
				--player:speak("point1.2")
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.to:contains(p) or room:isProhibited(player, p, use.card) then continue end
					if use.card:targetFixed() then
						if not use.card:isKindOf("Peach") or p:isWounded() then
							available_targets:append(p)
						end
					else
						if use.card:targetFilter(sgs.PlayerList(), p, player) then
							available_targets:append(p)
						end
					end
				end
				room:setPlayerFlag(player, "-FanyiExtraTarget")
			end
			--player:speak("point2")
			if choice == "add" then
				if available_targets:isEmpty() then return false end
				local extra
				if not use.card:isKindOf("Collateral") then
					extra = room:askForPlayerChosen(player, available_targets, "fanyi",
						"@fanyi-add:" .. use.card:objectName())
				else
					local tos = {}
					for _, t in sgs.qlist(use.to) do
						table.insert(tos, t:objectName())
					end

					room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
					room:setPlayerProperty(player, "extra_collateral_current_targets",
						sgs.QVariant(table.concat(tos, "+")))
					room:askForUseCard(player, "@@qiaoshui!", "@qiaoshui-add:::collateral")

					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if (p:hasFlag("ExtraCollateralTarget")) then
							room:setPlayerFlag(p, "-ExtraCollateralTarget")
							extra = p
							break
						end
					end

					if (extra == nil) then
						extra = available_targets:at(math.random(available_targets:length()) - 1)
						local victims = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(extra)) do
							if (extra:canSlash(p) and not (p:objectName() == player:objectName() and p:hasSkill("kongcheng") and p:isLastHandCard(use.card, true))) then
								victims:append(p)
							end
						end

						if victims:isEmpty() then return false end

						local _data = sgs.QVariant()
						_data:setValue(victims:at(math.random(victims:length()) - 1))
						extra:setTag("collateralVictim", _data)
					end
				end
				--player:speak("point3")
				use.to:append(extra)
				room:sortByActionOrder(use.to)

				local log = sgs.LogMessage()
				log.type = "#QiaoshuiAdd"
				log.from = player
				log.to:append(extra)
				log.card_str = use.card:toString()
				log.arg = "fanyi"
				room:sendLog(log)
				room:doAnimate(1, player:objectName(), extra:objectName())

				room:setPlayerProperty(player, "extra_collateral", sgs.QVariant())
				room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant())
			else
				--player:speak("point4")
				local removed = room:askForPlayerChosen(player, use.to, "fanyi",
					"@fanyi-remove:" .. use.card:objectName())
				if removed then
					use.to:removeOne(removed)
					local log = sgs.LogMessage()
					log.type = "#QiaoshuiRemove"
					log.from = player
					log.to:prepend(removed)
					log.card_str = use.card:toString()
					log.arg = "fanyi"
					room:sendLog(log)
				end
			end
			data:setValue(use)
		end
	end,
}

fanyiDrawNCard = sgs.CreateDrawCardsSkill {
	name = "fanyiDrawNCard",
	global = true,
	draw_num_func = function(self, player, n)
		if player:hasFlag("5draw_ad") then
			return n + 1
		elseif player:hasFlag("5draw_re") then
			return n - 1
		end
		return n
	end,
}

jihang = sgs.CreateTriggerSkill {
	name = "jihang",
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if PlayerCardLose(player, move) and player:getPhase() == sgs.Player_NotActive then
			local disabled_ids = sgs.IntList()
			if player:isKongcheng() or not room:askForSkillInvoke(player, "jihang", data) then return false end
			room:broadcastSkillInvoke("jihang")
			local acard = room:askForCardShow(player, player, "jihang")
			room:showCard(player, acard:getEffectiveId())
			local targets = sgs.SPlayerList()
			local ban_ts = player:property("JihnagTargets"):toString()
			local ban = false
			if ban_ts ~= "" then
				ban_ts = ban_ts:split("+")
			else
				ban = true
			end
			for _, t in sgs.qlist(room:getOtherPlayers(player)) do
				if (not t:isKongcheng()) and (ban or not table.contains(ban_ts, t:objectName())) then
					targets:append(t)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, "@jihang")
				if target then
					local bcard = room:askForCardChosen(player, target, "h", "jihang")
					if bcard then
						room:showCard(target, bcard)
						if math.abs(sgs.Sanguosha:getCard(bcard):getNumber() - acard:getNumber()) < 4 then
							local string = player:property("JihnagTargets"):toString()
							string = (string == "" and target:objectName()) or string .. "+" .. target:objectName()
							room:setPlayerProperty(player, "JihnagTargets", sgs.QVariant(string))
							move:removeCardIds(move.card_ids)
							data:setValue(move)
							return true
						end
					end
				end
			end
		end
	end
}

JihangGlobalClear = sgs.CreateTriggerSkill {
	name = "JihangGlobalClear",
	events = { sgs.TurnStart },
	global = true,
	on_trigger = function(self, event, player, data, room)
		room:setPlayerProperty(player, "JihnagTargets", sgs.QVariant(""))
	end
}

function Table2IntList(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

jiaoxingVS = sgs.CreateOneCardViewAsSkill {
	name = "jiaoxing",
	response_pattern = "@@jiaoxing",
	view_filter = function(self, to_select)
		local jiaoxing = sgs.Self:property("jiaoxing"):toString():split("+")
		local ok
		for _, id in sgs.list(jiaoxing) do
			if to_select:getEffectiveId() == tonumber(id) then
				ok = true
			end
		end
		return ok
	end,
	enabled_at_play = function(self, player)
		return not player:getPile("jiaoxing"):isEmpty()
	end,
	view_as = function(self, originalCard)
		local acard = sgs.Sanguosha:cloneCard("indulgence", originalCard:getSuit(), originalCard:getNumber())
		acard:addSubcard(originalCard)
		acard:setSkillName("_jiaoxing")
		return acard
	end,
}

jiaoxingUse = sgs.CreateTriggerSkill {
	name = "#jiaoxing",
	events = { sgs.PreCardUsed },
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:isKindOf("Indulgence") and use.card:getSkillName() == "jiaoxing" then
			local ids = Table2IntList(player:property("jiaoxing"):toString():split("+"))
			ids:removeOne(use.card:getEffectiveId())
			room:setPlayerProperty(player, "jiaoxing", sgs.QVariant(table.concat(sgs.QList2Table(ids), "+")))
		end
	end
}

jiaoxing = sgs.CreateTriggerSkill {
	name = "jiaoxing",
	events = { sgs.BeforeCardsMove, sgs.CardEffect },
	view_as_skill = jiaoxingVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if not player:hasSkill(self:objectName()) then return false end
			if PlayerCardLose(player, move) and LoseByDiscard(move) then
				local ass_id = sgs.IntList()
				local i = 0
				for _, card_id in sgs.list(move.card_ids) do
					local card = sgs.Sanguosha:getCard(card_id)
					if room:getCardOwner(card_id):getSeat() == move.from:getSeat() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) and card:isRed() and card:getNumber() <= 5 then
						ass_id:append(card_id)
					end
					i = i + 1
				end
				if ass_id:isEmpty() then return false end
				local string = table.concat(sgs.QList2Table(ass_id), "+")
				room:setPlayerProperty(player, "jiaoxing", sgs.QVariant(string))
				repeat
					if not room:askForUseCard(player, "@@jiaoxing", "@jiaoxing-use") then break end
					local ids = Table2IntList(player:property("jiaoxing"):toString():split("+"))
					local to_remove = sgs.IntList()
					for _, card_id in sgs.qlist(ass_id) do
						if not ids:contains(card_id) then
							to_remove:append(card_id)
						end
					end
					move:removeCardIds(to_remove)
					data:setValue(move)
					ass_id = sgs.IntList()
					for _, iiid in sgs.qlist(ids) do
						ass_id:append(iiid)
					end
				until ass_id:isEmpty()
			else
				return false
			end
		else
			local effect = data:toCardEffect()
			if not effect.card:isKindOf("DelayedTrick") then return false end
			for _, ruby in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local choice = room:askForChoice(ruby, self:objectName(), "indulgence+supply_shortage+cancel")
				if choice == "cancel" then return false end
				local log = sgs.LogMessage()
				log.type = "#jiaoxing"
				log.from = ruby
				log.to:append(effect.to)
				log.arg = choice
				log.arg2 = self:objectName()
				log.card_str = effect.card:toString()
				room:sendLog(log)
				local thread = room:getThread()
				local Dtrick = sgs.Sanguosha:cloneCard(choice, effect.card:getSuit(), effect.card:getNumber())
				Dtrick:setSkillName(self:objectName())
				Dtrick:addSubcard(effect.card)
				Dtrick:deleteLater()
				effect.card = Dtrick
				data:setValue(effect)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
anni = sgs.CreateTriggerSkill {
	name = "anni",
	events = { sgs.TargetConfirmed, sgs.Damage, sgs.CardFinished },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not player:hasSkill(self:objectName()) or player:isDead() then return false end
			if use.card:isKindOf("Slash") and (use.card:getSuit() == sgs.Card_Heart or use.card:getSuit() == sgs.Card_Club) then
				local avail_list = room:getAlivePlayers()
				local optional_list = sgs.SPlayerList()
				for _, p in sgs.qlist(avail_list) do
					if not use.to:contains(p) then
						optional_list:append(p)
					end
				end
				if optional_list:isEmpty() then return false end
				room:setTag("CurrentUseStruct", data)
				local gusser = room:askForPlayerChosen(player, optional_list, self:objectName(), "@anni-target", true,
					true)
				if gusser then
					local choice = room:askForChoice(gusser, self:objectName(), "anni_hit+anni_miss")

					room:setCardFlag(use.card, "poii")
					room:setCardFlag(use.card, "anni_miss")
					--setTag
					local playerdata = sgs.QVariant()
					playerdata:setValue(gusser)
					room:setTag("anni_judger", playerdata)
					room:setPlayerProperty(gusser, "anni_judge", sgs.QVariant(choice))
				end
				room:removeTag("CurrentUseStruct")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("poii") then
				room:setCardFlag(damage.card, "-anni_miss")
			else
				return false
			end
		else
			local use = data:toCardUse()
			if use.card:hasFlag("poii") then
				room:setCardFlag(use.card, "-poii")
				local ruby = room:findPlayerBySkillName(self:objectName())
				if not ruby then return false end
				--findTag
				if not room:getTag("anni_judger") then return false end
				local gusser = room:getTag("anni_judger"):toPlayer()
				local choice = gusser:property("anni_judge"):toString()
				local win
				if use.card:hasFlag("anni_miss") then --没造成伤害
					win = (choice == "anni_miss")
				else                      --造成伤害
					win = (choice == "anni_hit")
				end
				room:removeTag("anni_judger")
				room:setPlayerProperty(gusser, "anni_judge", sgs.QVariant())
				room:sendCompulsoryTriggerLog(ruby, self:objectName())
				if win then
					ruby:drawCards(1)
				else
					if not ruby:isKongcheng() then
						local id = room:askForCardChosen(gusser, ruby, "h", "anni")
						room:throwCard(id, ruby, gusser)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--连击驱动
lianjiqudong = sgs.CreateTriggerSkill {
	name = "lianjiqudong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.CardFinished, sgs.ConfirmDamage, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			if player:getPhase() == sgs.Player_Play then
				local damage = data:toDamage()
				if damage.by_user and damage.card and not damage.card:isKindOf("SkillCard") and not damage.card:hasFlag(self:objectName()) then
					room:setCardFlag(damage.card, self:objectName())
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (not use.card:isKindOf("EquipCard")) and (not use.card:isKindOf("SkillCard")) and player:getPhase() == sgs.Player_Play then
				if use.card:hasFlag(self:objectName()) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:gainMark("@" .. self:objectName(), 1)
					room:setCardFlag(use.card, "-" .. self:objectName())
				else
					room:sendCompulsoryTriggerLog(player, self:objectName())
					player:loseAllMarks("@" .. self:objectName())
				end
			end
		elseif event == sgs.ConfirmDamage then
			local count, damage = player:getMark("@" .. self:objectName()), data:toDamage()
			if count > 0 and damage.card and damage.card:isKindOf("Slash") then
				damage.damage = damage.damage + 1.5 * count
				room:sendCompulsoryTriggerLog(player, self:objectName())
				data:setValue(damage)
			end
		else
			if data:toPhaseChange().to == sgs.Player_NotActive and player:getMark("@" .. self:objectName()) > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:loseAllMarks("@" .. self:objectName())
			end
		end
	end,
}
--摸鱼
moyu = sgs.CreateTriggerSkill {
	name = "moyu",
	events = { sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.PreCardUsed) or (event == sgs.CardResponded)) and (player:getPhase() <= sgs.Player_Play) then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				player:addMark(self:objectName())
				room:addPlayerMark(player, "&moyu-Clear")
			end
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_RoundStart) then
			player:setMark(self:objectName(), 0)
		elseif event == sgs.EventPhaseEnd then
			if (player:getPhase() == sgs.Player_Play) and (player:getMark(self:objectName()) <= player:getHp()) then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke("zhujuexz")
					player:drawCards(1)
				end
			end
		end
		return false
	end
}
--伞盾
sandun = sgs.CreateTriggerSkill {
	name = "sandun",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		if player:getEquips():length() > 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			player:drawCards(1)
		elseif player:getEquips():length() == 0 then
			player:throwAllHandCards()
			local choice = room:askForChoice(player, self:objectName(), "use_blackequip_discard+use_slash")
			if choice == "use_blackequip_discard" then
				local list = sgs.IntList()
				for _, id in sgs.qlist(room:getDiscardPile()) do
					if sgs.Sanguosha:getCard(id):isBlack() and sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
						list:append(id)
					end
				end
				if list:length() == 0 then return false end
				room:fillAG(list, player)
				local id = room:askForAG(player, list, false, "sandun")
				room:clearAG(player)
				room:obtainCard(player, id, true)
				local use = sgs.CardUseStruct()
				use.card = sgs.Sanguosha:getCard(id)
				use.from = player
				use.to:append(player)
				room:useCard(use)
			elseif choice == "use_slash" then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:deleteLater()
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not player:isProhibited(p, slash) then
						targets:append(p)
					end
				end
				if targets:length() == 0 then return false end
				local victim = room:askForPlayerChosen(player, targets, "sandun")
				slash:setSkillName(self:objectName())
				slash:deleteLater()
				room:useCard(sgs.CardUseStruct(slash, player, victim))
			end
		end
	end
}
--[[
xieyancard=sgs.CreateSkillCard{
 name="xieyancard",
 target_fixed = function(self)
   return sgs.Sanguosha:getCard(self:getSubcards():first()):targetFixed()
 end,
 will_throw=false,
 filter = function(self,targets,to_select)
   local card = sgs.Sanguosha:getCard(self:getSubcards():first())
   if sgs.Self:isProhibited(to_select,card) or not card:isAvailable(sgs.Self) then return false end
   if card:targetFixed() then return false end
   if card:isKindOf("Slash") then return #targets<1 and sgs.Self:inMyAttackRange(to_select) end
   if card:isKindOf("Snatch") then return #targets<1 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select)<=1 and not (to_select:isNude() and to_select:getJudgingArea():length()==0) end
   if card:isKindOf("Dismantlement") then return #targets<1 and to_select:objectName() ~= sgs.Self:objectName() and not (to_select:isNude() and to_select:getJudgingArea():length()==0) end
   if card:isKindOf("SupplyShortage") then return #targets<1 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select)<=1 end
   if card:isKindOf("Indulgence") then return #targets<1 and to_select:objectName() ~= sgs.Self:objectName() end
   if card:isKindOf("Peach") then return #targets<1 and to_select:isWounded() end
   if card:isKindOf("IronChain") then return #targets<2 end
   if card:isKindOf("Collateral") then return #targets<1 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getWeapon()~=nil end
   if card:objectName()=="together_go_die" then return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getHandcardNum() >= sgs.Self:getHandcardNum() end
   if card:objectName()=="mouthgun" then return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() and sgs.Self:distanceTo(to_select) <= math.max(1, sgs.Self:getHp()) and #targets < 1 end
   return #targets < 1
 end,
 feasible = function(self,targets)
   local card = sgs.Sanguosha:getCard(self:getSubcards():first())
   if card:isKindOf("Jink") or card:isKindOf("Nullification") then return false end
   if card:isKindOf("Peach") and not sgs.Self:isWounded() then return false end
   if card:targetFixed() or #targets>0 then
     return true
   end
 end,
 on_use = function(self, room, source, targets)
   local subs=self:getSubcards()
   if subs:length()==0 then return false end
   local id=subs:at(0)
   room:showCard(source,id)
   local card=sgs.Sanguosha:getCard(id)
   if card:isKindOf("BasicCard") then room:setPlayerFlag(source,"basic_showed")
   elseif card:isKindOf("TrickCard") then room:setPlayerFlag(source,"trick_showed") end
   local nilcard = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
   nilcard:addSubcard(room:getNCards(1):at(0))
   nilcard:setSkillName("xieyan")
   if not nilcard:isKindOf("Collateral") then
     local splayerlist = Table2SPlayerlist(targets)
     local use = sgs.CardUseStruct(nilcard,source,splayerlist,true)
     room:useCard(use)
   elseif nilcard:isKindOf("Collateral") then
     local plist=sgs.SPlayerList()
     for _,p in sgs.qlist(room:getAlivePlayers()) do
       if targets[1]:inMyAttackRange(p) then
         plist:append(p)
       end
     end
     if plist:length()==0 then return false end
	 local splayerlist = Table2SPlayerlist(targets)
     local dest=room:askForPlayerChosen(source,plist,"xieyan")
     local use=sgs.CardUseStruct()
     use.card=nilcard
     use.from=source
     use.to:append(splayerlist:at(0))
	 use.to:append(dest)
     room:useCard(use)
   end
 end
}
]]
xieyancard = sgs.CreateSkillCard {
	name = "xieyancard",
	target_fixed = function(self)
		return sgs.Sanguosha:getCard(self:getSubcards():first()):targetFixed()
	end,
	will_throw = false,
	filter = function(self, targets, to_select)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card and card:targetFixed() and card:isAvailable(sgs.Self) then
			return false
		else
			return card and card:targetFilter(plist, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, plist) and card:isAvailable(sgs.Self)
		end
	end,
	feasible = function(self, targets)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and card:targetsFeasible(plist, sgs.Self) and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:showCard(card_use.from, self:getSubcards():first())
		local nilcard = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
		if nilcard == nil then return false end
		nilcard:setSkillName("xieyan")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, nilcard) then
				available = false
				break
			end
		end
		if not available then return nil end
		nilcard:addSubcard(room:getNCards(1):at(0))
		return nilcard
	end
	--[[on_use = function(self, room, source, targets)
   local subs=self:getSubcards()
   if subs:length()==0 then return false end
   local id=subs:at(0)
   room:showCard(source,id)
   local card=sgs.Sanguosha:getCard(id)
   if card:isKindOf("BasicCard") then room:setPlayerFlag(source,"basic_showed")
   elseif card:isKindOf("TrickCard") then room:setPlayerFlag(source,"trick_showed") end
   local nilcard = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
   nilcard:addSubcard(room:getNCards(1):at(0))
   nilcard:setSkillName("xieyan")
   if not nilcard:isKindOf("Collateral") then
     local splayerlist = Table2SPlayerlist(targets)
     local use = sgs.CardUseStruct(nilcard,source,splayerlist,true)
     room:useCard(use)
   elseif nilcard:isKindOf("Collateral") then
     local plist=sgs.SPlayerList()
     for _,p in sgs.qlist(room:getAlivePlayers()) do
       if targets[1]:inMyAttackRange(p) then
         plist:append(p)
       end
     end
     if plist:length()==0 then return false end
	 local splayerlist = Table2SPlayerlist(targets)
     local dest=room:askForPlayerChosen(source,plist,"xieyan")
     local use=sgs.CardUseStruct()
     use.card=nilcard
     use.from=source
     use.to:append(splayerlist:at(0))
	 use.to:append(dest)
     room:useCard(use)
   end
 end]]
}




xieyan = sgs.CreateViewAsSkill {
	name = "xieyan",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			if sgs.Self:hasFlag("basic_showed") then
				return to_select:isKindOf("TrickCard")
			elseif sgs.Self:hasFlag("trick_showed") then
				return to_select:isKindOf("BasicCard")
			elseif not sgs.Self:hasFlag("basic_showed") and not sgs.Self:hasFlag("trick_showed") then
				return not to_select:isKindOf("EquipCard")
			end
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local vs_card = xieyancard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("basic_showed") or not player:hasFlag("trick_showed")
	end
}

xieyan_tri = sgs.CreateTriggerSkill {
	name = "#xieyan_tri",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event ~= sgs.CardFinished then
			if player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("xieyan_basic") > 0 then
						room:setPlayerMark(p, "xieyan_basic", 0)
						room:removePlayerCardLimitation(p, "use", "BasicCard|.|.|hand$1")
					end
					if p:getMark("xieyan_trick") > 0 then
						room:setPlayerMark(p, "xieyan_trick", 0)
						room:removePlayerCardLimitation(p, "use", "TrickCard|.|.|hand$1")
					end
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if use.from and use.from:hasSkill("xieyan") and card:getSkillName() == "xieyan" then
				local source = use.from
				if card:isKindOf("BasicCard") then
					room:setPlayerMark(source, "xieyan_basic", 1)
					room:addPlayerMark(source, "&xieyan+:+basic-PlayClear")
					room:setPlayerCardLimitation(source, "use", "BasicCard|.|.|hand$1", true)
					for _, p in sgs.qlist(use.to) do
						room:setPlayerMark(p, "xieyan_basic", 1)
						room:addPlayerMark(p, "&xieyan+to+#" .. source:objectName() .. "+:+basic-PlayClear")
						room:setPlayerCardLimitation(p, "use", "BasicCard|.|.|hand$1", true)
					end
					--card:setSkillName("")
				elseif card:isKindOf("TrickCard") then
					room:setPlayerMark(source, "xieyan_trick", 1)
					room:addPlayerMark(source, "&xieyan+:+trick-PlayClear")
					room:setPlayerCardLimitation(source, "use", "TrickCard|.|.|hand$1", true)
					for _, p in sgs.qlist(use.to) do
						room:setPlayerMark(p, "xieyan_trick", 1)
						room:addPlayerMark(p, "&xieyan+to+#" .. source:objectName() .. "+:+trick-PlayClear")
						room:setPlayerCardLimitation(p, "use", "TrickCard|.|.|hand$1", true)
					end
					--card:setSkillName("")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}

--浮潜
fuqian = sgs.CreateTriggerSkill {
	name = "fuqian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local current = room:getCurrent()
		local card_ids = sgs.QList2Table(move.card_ids)
		if (not move.from or move.from:objectName() ~= player:objectName()) and move.to and move.to:objectName() == player:objectName() then
			for _, id in ipairs(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if room:getTag("fuqian_made" .. player:objectName() .. string.format("%d", id)):toInt() > 0 then
					room:setTag("fuqian_made" .. player:objectName() .. string.format("%d", id), sgs.QVariant(0))
				end
			end
		end
		local dest
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if move.to and p:objectName() == move.to:objectName() then dest = p end
		end
		if move.to and dest and move.to_place == sgs.Player_PlaceHand then
			for _, id in ipairs(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if id ~= -1 and room:getTag("fuqian_card" .. player:objectName() .. string.format("%d", id)):toInt() > 0 then
					room:setTag("fuqian_card" .. player:objectName() .. string.format("%d", id), sgs.QVariant(0))
					for i = 1, 2, 1 do
						if not dest:isNude() then
							local j = room:askForCardChosen(player, dest, "he", self:objectName())
							room:throwCard(j, dest, player)
						end
					end
				end
			end
		end
		if not move.from or move.from:objectName() ~= player:objectName() then return end
		if move.to and move.to:objectName() == player:objectName() then return end
		if not move.from_places:contains(sgs.Player_PlaceHand) and not move.from_places:contains(sgs.Player_PlaceEquip) then return end
		for _, id in ipairs(card_ids) do
			if id ~= -1 and current and not current:hasFlag("fuqian_used2") and room:getTag("fuqian_card" .. player:objectName() .. string.format("%d", id)):toInt() == 0 and room:getTag("fuqian_made" .. player:objectName() .. string.format("%d", id)):toInt() == 0 and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				if not current:hasFlag("fuqian_used1") then
					room:setPlayerFlag(current, "fuqian_used1")
				else
					room:setPlayerFlag(current, "fuqian_used2")
				end
				local n = sgs.Sanguosha:getCard(id):getNumber()
				local l = room:getDrawPile():length()
				if l < n or n == 1 then
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(id)
					move.to_place = sgs.Player_DrawPile
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					room:moveCardsAtomic(move, true)
					room:setTag("fuqian_card" .. player:objectName() .. string.format("%d", id), sgs.QVariant(1))
				elseif l >= n and n > 1 then
					local list = sgs.IntList()
					for i = 1, n - 1, 1 do
						list:append(room:getDrawPile():at(n - i - 1))
					end
					player:addToPile("temporarycards", list, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids:append(id)
					move.to_place = sgs.Player_DrawPile
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					room:moveCardsAtomic(move, true)
					local move1 = sgs.CardsMoveStruct()
					for _, i in sgs.qlist(list) do
						move1.card_ids:append(i)
					end
					move1.to_place = sgs.Player_DrawPile
					move1.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					room:moveCardsAtomic(move1, false)
					room:setTag("fuqian_card" .. player:objectName() .. string.format("%d", id), sgs.QVariant(1))
				end
				room:setTag("fuqian_made" .. player:objectName() .. string.format("%d", id), sgs.QVariant(1))
			end
		end
	end
}
--煌轨
huanggui = sgs.CreateTriggerSkill {
	name = "huanggui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId() == sgs.Card_TypeSkill then return end
		local can = false
		for _, p in sgs.qlist(use.to) do
			if p:objectName() == player:objectName() then can = true end
		end
		if can == false then return end
		local list = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:inMyAttackRange(player) and p:getHandcardNum() + p:getEquips():length() + p:getJudgingArea():length() == 3 then
				list:append(p)
			end
		end
		if list:length() > 0 then
			room:setTag("huanggui", data)
			local dest = room:askForPlayerChosen(player, list, "huanggui", "huanggui-invoke", true)
			room:removeTag("huanggui")
			if (not dest) then return false end
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, "huanggui")
			dest:drawCards(1)
			use.to:removeOne(player)
			use.to:append(dest)
			data:setValue(use)
			if use.card and use.card:isKindOf("DelayedTrick") then
				room:moveCardTo(use.card, dest, sgs.Player_PlaceDelayedTrick)
			end
		end
	end
}
--挽澜
htms_wanlan = sgs.CreateTriggerSkill {
	name = "htms_wanlan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and player:askForSkillInvoke(self:objectName(), data) then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
			local id1 = room:askForExchange(player, self:objectName(), 998, 1, true, "@htms_wanlan-from", true)
			local id2 = room:askForExchange(target, self:objectName(), 998, 1, true,
				"@htms_wanlan-to::" .. player:objectName(), true)
			local a = 0
			local b = 0
			if not id1 then
				a = 0
			else
				local list = id1:getSubcards()
				room:throwCard(id1, player)
				for _, id in sgs.qlist(list) do
					local c = sgs.Sanguosha:getCard(id)
					a = a + c:getNumber()
				end
			end
			if not id2 then
				b = 0
			else
				local list = id2:getSubcards()
				room:throwCard(id2, target)
				for _, id in sgs.qlist(list) do
					local c = sgs.Sanguosha:getCard(id)
					b = b + c:getNumber()
				end
			end
			local msg = sgs.LogMessage()
			msg.type = "#htms_wanlanRace"
			msg.from = player
			msg.arg = a
			room:sendLog(msg)
			msg.from = target
			msg.arg = b
			room:sendLog(msg)
			if a > b then
				local da = sgs.DamageStruct()
				da.from = player
				da.to = target
				da.damage = 1
				room:damage(da)
			elseif a < b then
				local choice = room:askForChoice(target, self:objectName(), "draw_one_card+obtain_one_card")
				if choice == "draw_one_card" then target:drawCards(1) end
				if choice == "obtain_one_card" then
					room:fillAG(id2:getSubcards(), target)
					local id = room:askForAG(target, id2:getSubcards(), false, self:objectName())
					room:obtainCard(target, id)
					room:clearAG(target)
				end
			end
		end
	end
}
--雨
tianqu = sgs.CreateTriggerSkill {
	name = "tianqu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:objectName() == "slash" and not player:isKongcheng() and player:askForSkillInvoke(self:objectName(), data) then
				player:addToPile("rains", player:handCards())
				if room:getOtherPlayers(player):length() < 2 then return false end
				room:broadcastSkillInvoke("tianqu", math.random(1, 2))
				local target1 = room:askForPlayerChosen(player, room:getOtherPlayers(player), "tianqu_from")
				local list = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:objectName() ~= target1:objectName() then
						list:append(p)
					end
				end
				local target2 = room:askForPlayerChosen(player, list, "tianqu_to")
				local ids = target2:handCards()
				local move = sgs.CardsMoveStruct()
				for _, id in sgs.qlist(target1:handCards()) do
					move.card_ids:append(id)
				end
				move.to = target2
				move.to_place = sgs.Player_PlaceHand
				move.reason.m_reason = sgs.CardMoveReason_S_REASON_SWAP
				room:moveCardsAtomic(move, false)
				local move2 = sgs.CardsMoveStruct()
				for _, id in sgs.qlist(ids) do
					move2.card_ids:append(id)
				end
				move2.to = target1
				move2.to_place = sgs.Player_PlaceHand
				move2.reason.m_reason = sgs.CardMoveReason_S_REASON_SWAP
				room:moveCardsAtomic(move2, false)
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			if player:getPile("rains"):length() > 0 then
				for _, id in sgs.qlist(player:getPile("rains")) do
					room:obtainCard(player, id)
				end
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = 1
				room:recover(player, theRecover, true)
			end
		end
	end
}
-- --海音
-- haiyin=sgs.CreateTriggerSkill{
-- 	name="haiyin",
--  	frequency=sgs.Skill_Compulsory,
-- 	events={sgs.CardsMoveOneTime},
-- 	on_trigger=function(self,event,player,data)
-- 		local room=player:getRoom()
-- 		local move=data:toMoveOneTime()
--      	if not move.from then return end
-- 		if move.to and move.to:objectName()==player:objectName() then return end
-- 		if not move.from_places:contains(sgs.Player_PlaceHand) and not move.from_places:contains(sgs.Player_PlaceEquip) then return end
-- 	 local card_ids = sgs.QList2Table(move.card_ids)
-- 	 local places = sgs.QList2Table(move.from_places)
--      if player:objectName()==move.from:objectName() then
-- 	   if player:getPile("yun"):length()==0 then
-- 	     local list=sgs.IntList()
-- 	     for i=1,#card_ids,1 do
-- 		   if places[i] and (places[i]==sgs.Player_PlaceHand or places[i]==sgs.Player_PlaceEquip) then
-- 		     list:append(card_ids[i])
-- 		   end
-- 		 end
-- 		 if list:length()>0 then
-- 		   room:fillAG(list, player)
-- 	       local id = room:askForAG(player, list, false, self:objectName())
-- 		   player:addToPile("yun",id)
-- 		   room:clearAG(player)
-- 		 end
-- 	   elseif player:getPile("yun"):length()>0 then
-- 	     local id=player:getPile("yun"):at(0)
-- 		 for i=1,#card_ids,1 do
-- 		   if places[i] and (places[i]==sgs.Player_PlaceHand or places[i]==sgs.Player_PlaceEquip) then
-- 		     if suit_proceed(id, card_ids[i]) then
-- 			   player:addToPile("yun",card_ids[i])
-- 			   room:throwCard(id,player,player)
-- 			   player:drawCards(1)
-- 			   break
-- 			 end
-- 		   end
-- 		 end
-- 	   end
-- 	 end
--    end
--  end
-- }
-- --复奏
-- fuzou=sgs.CreateTriggerSkill{
--  name="fuzou",
--  frequency=sgs.Skill_NotFrequent,
--  events={sgs.TargetConfirmed,sgs.EventPhaseEnd},
--  on_trigger=function(self,event,player,data)
--    local room=player:getRoom()
--    if event==sgs.TargetConfirmed then
--      local use=data:toCardUse()
-- 	 local sp=room:findPlayerBySkillName(self:objectName())
-- 	 if not use.card:isKindOf("TrickCard") then return end
-- 	 if not sp or sp:isDead() then return end
-- 	 if sp:getPile("yun"):length()>0 and player:objectName()==sp:objectName() and sp:askForSkillInvoke(self:objectName(),data) then
-- 	   room:throwCard(sp:getPile("yun"):at(0),sp,sp)
-- 	   for _,p in sgs.qlist(use.to) do
-- 	     room:setPlayerMark(p,"fuzoudest",1)
-- 		 room:acquireSkill(p,"fuzou_filter")
-- 		 room:filterCards(p, p:getCards("h"), true)
--        end
--      end
--    end	
--    if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
--      for _,p in sgs.qlist(room:getAlivePlayers()) do
--        if p:getMark("fuzoudest")>0 then
--          room:setPlayerMark(p,"fuzoudest",0)
-- 		 room:detachSkillFromPlayer(p,"fuzou_filter")	
--          room:filterCards(p, p:getCards("h"), false)		
-- 	   end
--      end	
--    end
--  end,
--  can_trigger=function(self,player)
--    return true
--  end
-- }
--吃饼
chibing = sgs.CreateTriggerSkill {
	name = "chibing",
	events = { sgs.HpRecover },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.HpRecover) then
			local rec = data:toRecover()
			for i = 1, rec.recover, 1 do
				if not player:isAlive() then
					break
				end
				player:drawCards(1)
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:setEmotion(player, "analeptic")
				room:addPlayerMark(player, "drank")
			end
		end
	end,
}
--速攻
sugong = sgs.CreatePhaseChangeSkill {
	name = "sugong",
	priority = 1,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_NotActive) then
			local yuuki = room:findPlayerBySkillName(self:objectName())
			local swap_time = room:getTag("SwapPile"):toInt()
			if yuuki and yuuki:getMark("sugong") <= swap_time then
				room:setPlayerMark(yuuki, "sugong", swap_time + 1)
				yuuki:drawCards(1)
				room:broadcastSkillInvoke("sugong", math.random(1, 2))
				local choice = room:askForChoice(yuuki, self:objectName(), "sugong:huix+sugong:lius", data)
				if choice == "sugong:lius" then
					room:loseHp(yuuki, 1)
					yuuki:drawCards(1)
					yuuki:gainAnExtraTurn()
				elseif choice == "sugong:huix" then
					local recover = sgs.RecoverStruct(yuuki, nil, 1)
					room:recover(yuuki, recover)
					yuuki:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

sugongst = sgs.CreateTriggerSkill {
	name = "#sugongst",
	events = { sgs.TurnStart },
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		local players = room:findPlayersBySkillName("sugong")
		if players:isEmpty() then return false end
		for _, p in sgs.qlist(players) do
			if (p:getMark("sugong") == 0) then
				room:setPlayerMark(p, "sugong", 1)
				if (p:askForSkillInvoke("sugong")) then
					p:drawCards(1)
					local choice = room:askForChoice(p, "sugong", "sugong:huix+sugong:lius", data)
					if choice == "sugong:lius" then
						p:drawCards(1)
						room:loseHp(p, 1)
						p:gainAnExtraTurn()
					elseif choice == "sugong:huix" then
						local recover = sgs.RecoverStruct(p, nil, 1)
						room:recover(p, recover)
						p:gainAnExtraTurn()
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end
}
--葬送
zangsongCard = sgs.CreateSkillCard {
	name = "zangsongCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local id = room:askForCardChosen(source, target, "h", "zangsong")
		local cd = sgs.Sanguosha:getCard(id)
		room:showCard(target, id)
		if cd:getSuit() == sgs.Card_Heart then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("zangsong")
			room:useCard(sgs.CardUseStruct(slash, source, target))
		else
			source:drawCards(1)
		end
	end,
}
zangsong = sgs.CreateZeroCardViewAsSkill {
	name = "zangsong",
	view_as = function(self, cards)
		return zangsongCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zangsongCard")
	end
}
--剑武术
jianwushu = sgs.CreateTriggerSkill {
	name = "jianwushu",
	events = { sgs.TargetSpecified, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data, room)
		--local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return end
		if event == sgs.TargetSpecified then
			if player:objectName() == use.from:objectName() and player:getWeapon() then
				for _, p in sgs.qlist(use.to) do
					local dest = sgs.QVariant()
					dest:setValue(p)
					if (not p:isNude()) and room:askForSkillInvoke(player, self:objectName(), dest) then
						local id = room:askForCardChosen(player, p, "he", self:objectName())
						if id then
							room:broadcastSkillInvoke("jianwushu", 1)
							room:throwCard(sgs.Sanguosha:getCard(id), p, player)
						end
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			if use.from and use.to:contains(player) and (not use.from:isNude()) and (not player:getWeapon()) then
				local dest = sgs.QVariant()
				dest:setValue(use.from)
				if room:askForSkillInvoke(player, self:objectName(), dest) then
					local id = room:askForCardChosen(player, use.from, "he", self:objectName())
					if id then
						room:broadcastSkillInvoke("jianwushu", 2)
						room:throwCard(sgs.Sanguosha:getCard(id), use.from, player)
					end
				end
			end
		end
	end
}
--[[--继承者
jichengzhe = sgs.CreateTriggerSkill{
	name = "jichengzhe",
	frequency = sgs.Skill_Wake,
	events = {sgs.AskForPeaches,sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local bks=room:findPlayerBySkillName(self:objectName())
		local dying_data = data:toDying()
		local source = dying_data.who
		if event==sgs.AskForPeaches then
			if source:objectName() == bks:objectName() then
				room:acquireSkill(bks, "tianjiangzhengyi")
			end
		elseif event==sgs.AskForPeachesDone then
			if source:objectName() == bks:objectName() then
				room:changeHero(bks, "washake", true, true, false, true)
			end
		end
	end,
	can_trigger = function(self, target)
			if target:hasSkill(self:objectName()) then
				return true
			end
		return false
	end
}
--天降正义
tianjiangzhengyi = sgs.CreateTriggerSkill{
	name = "tianjiangzhengyi",
	frequency = sgs.Skill_NotFrequent,
	events={sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isNude() then return false end
		if not player:askForSkillInvoke(self:objectName(),data) then return false end
		room:askForDiscard(player, self:objectName(), 1,1, false, true)
		local s=room:askForPlayerChosen(player,room:getAlivePlayers(),"targetSelect-invoke",self:objectName(),true,true)
		room:damage(sgs.DamageStruct(self:objectName(), player, s, 1, sgs.DamageStruct_Normal))
	end
}
--C级佣兵
Cjiyongbing = sgs.CreateTriggerSkill{
	name = "Cjiyongbing",
	frequency = sgs.Skill_Compulsory,
	events={sgs.GameStart,sgs.Death,sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local bks=room:findPlayerBySkillName(self:objectName())
		if not player:hasSkill(self:objectName()) then return false end
		if bks:getRole() == "lord" then return false end
		if event == sgs.GameStart then
		local isRadom=bks:getRole()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "renegade" then
					local temp=isRadom
					room:setPlayerProperty(bks,"role",sgs.QVariant("renegade"))
					room:setPlayerProperty(p,"role",sgs.QVariant(temp))
				end
			end
				room:setPlayerProperty(bks,"role",sgs.QVariant("renegade"))
		elseif event ==sgs.Death or event ==sgs.TurnStart then
		local death = data:toDeath()
			local a=0
			local b=0
			local c=0
			local max=a
			local isloyalist=1
			local isrebel=0
			local isrenegade=0
			if death.who~=bks then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if	(p:getRole() == "lord" or p:getRole() == "loyalist") and p:isFemale() and p:objectName() ~= bks:objectName() then
						a=a+1
					elseif (p:getRole() == "rebel") and p:isFemale() and p:objectName() ~= bks:objectName() then
						b=b+1
					elseif (p:getRole() == "renegade") and p:isFemale() and p:objectName() ~= bks:objectName() then
						c=c+1
					end
				end
				if(b>max) then
					isloyalist=0
					isrebel=1
					isrenegade=0
				end
				if(c>max) then
					isloyalist=0
					isrebel=0
					isrenegade=1
				end
				if isloyalist == 1 then
					room:setPlayerProperty(bks,"role",sgs.QVariant("loyalist"))
				elseif isrebel == 1 then
					room:setPlayerProperty(bks,"role",sgs.QVariant("rebel"))
				elseif isrenegade ==1 then
					room:setPlayerProperty(bks,"role",sgs.QVariant("renegade"))
				end
			end
		end
	end
}
--觉醒魔神
juexingmoshen = sgs.CreateTriggerSkill{
	name = "juexingmoshen",
	frequency = sgs.Skill_Compulsory,
	events={sgs.Damage,sgs,TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local use=data:toCardUse()
		local washake=room:findPlayerBySkillName(self:objectName())
		if event == sgs.Damage then
			if damage.from:objectName() == washake:objectName() and damage.card:isKindOf("Slash")  then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade,heart"
				judge.reason = self:objectName()
				judge.who = player
				judge.time_consuming = true
				room:judge(judge)
				if judge:isGood() then
					local suit = judge.card:getSuit()
					if suit == sgs.Card_Heart then
						room:recover(washake, sgs.RecoverStruct(washake))
					elseif suit == sgs.Card_Spade then
						room:setPlayerMark(washake, "juexingmoshen", washake:getMark("juexingmoshen")+1)
					end
				end
			end
		elseif event == sgs.TurnStart then
			room:setPlayerMark(washake, "juexingmoshen", 0)
		end
	end,
	can_trigger = function(self, target)
			if target:hasSkill(self:objectName()) then
				return true
			end
		return false
	end
}
juexingmoshenSlash = sgs.CreateTargetModSkill{
	name = "#juexingmoshenSlash",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getMark("juexingmoshen")
		end
	end
}
]] --
--丰收
fengshou = sgs.CreateTriggerSkill {
	name = "fengshou",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawInitialCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local a = 0
		local b = 0
		local x = math.ceil(room:alivePlayerCount())
		for i = 1, x, 1 do
			local choice = room:askForChoice(player, self:objectName(), "fengshou:dcards+fengshou:mcards", data)
			if choice == "fengshou:dcards" then
				a = a + 1.5
			elseif choice == "fengshou:mcards" then
				b = b + 2.5
			end
		end
		data:setValue(data:toInt() + a)
		room:setPlayerMark(player, "fengshou", b)
	end
}
fengshouMod = sgs.CreateMaxCardsSkill {
	name = "#fengshouMod",
	extra_func = function(self, target)
		if target:hasSkill("fengshou") then
			return target:getMark("fengshou")
		end
	end
}
--无尽之书
wujinzhishu = sgs.CreateTriggerSkill {
	name = "wujinzhishu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardFinished, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if player:hasFlag(self:objectName()) then return end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card then return end
			if use.card and use.card:getHandlingMethod() == sgs.Card_MethodUse and not use.card:isKindOf("SkillCard") then
				if use.card:getSubcards():length() > 0 then
					local can_invoke = false
					for _, id in sgs.qlist(use.card:getSubcards()) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							local c = sgs.Sanguosha:getCard(id)
							--can_invoke = not (c:isKindOf("Jink") or c:isKindOf("Nullification") or c:isKindOf("EquipCard"))
							can_invoke = not (c:isKindOf("EquipCard"))
							if can_invoke then
								break
							end
						end
					end
					if can_invoke then
						card = use.card
					end
				end
			end
		elseif event == sgs.CardResponded then
			local use = data:toCardResponse()
			if not use.m_card then return end
			if use.m_card:isVirtualCard() then return end
			if use.m_card:isKindOf("SkillCard") then return end
			if not use.m_isUse then return end
			if room:getCardPlace(use.m_card:getEffectiveId()) ~= sgs.Player_PlaceTable then return end
			--if use.m_card:isKindOf("Jink") or use.m_card:isKindOf("Nullification") or use.m_card:isKindOf("EquipCard") then return end
			if use.m_card:isKindOf("EquipCard") then return end
			if use.m_card and use.m_card:getHandlingMethod() == sgs.Card_MethodUse then
				card = use.m_card
			end
		end
		if card and card:getHandlingMethod() == sgs.Card_MethodUse then
			for _, id in sgs.qlist(card:getSubcards()) do
				if player:getPile("s_ye"):isEmpty() then
					if not room:askForSkillInvoke(player, self:objectName(), data) then return end
					room:broadcastSkillInvoke(self:objectName())
					player:addToPile("s_ye", id)
				else
					local same = false
					for _, id2 in sgs.qlist(player:getPile("s_ye")) do
						if sgs.Sanguosha:getCard(id):objectName() == sgs.Sanguosha:getCard(id2):objectName() then
							same = true
							break
						end
					end
					if not same then
						if not room:askForSkillInvoke(player, self:objectName(), data) then return end
						room:broadcastSkillInvoke(self:objectName())
						player:addToPile("s_ye", id)
					end
				end
			end
		end
	end,
}

--春日记录

chunrijilu_select = sgs.CreateSkillCard {
	name = "chunrijilu",
	will_throw = true,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		room:askForUseCard(source, "@@chunrijilu!", "@chunrijilu")
	end
}

chunrijiluVS = sgs.CreateViewAsSkill {
	name = "chunrijilu",
	n = 1,
	expand_pile = "s_ye",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and string.startsWith(pattern, "@@chunrijilu") then
			if (sgs.Self:getSlashCount() > 0 and not sgs.Self:canSlashWithoutCrossbow()) then
				return sgs.Self:getPile("s_ye"):contains(to_select:getEffectiveId()) and to_select:isAvailable(sgs.Self) and
				not to_select:isKindOf("Slash")
			else
				return sgs.Self:getPile("s_ye"):contains(to_select:getEffectiveId()) and to_select:isAvailable(sgs.Self)
			end
		else
			return sgs.Self:getHandcards():contains(to_select)
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = chunrijilu_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern and string.startsWith(pattern, "@@chunrijilu") then
				if #cards == 1 then
					local slash = sgs.Sanguosha:cloneCard(cards[1]:objectName(), cards[1]:getSuit(), cards[1]:getNumber())
					slash:addSubcard(cards[1]:getId())
					slash:setSkillName(self:objectName())
					return slash
				end
			end
		end
	end,
	enabled_at_play = function(self, player)
		local can_invoke = false
		if not player:getPile("s_ye"):isEmpty() then
			for _, id in sgs.qlist(player:getPile("s_ye")) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isAvailable(player) then
					local list = player:getAliveSiblings()
					list:append(player)
					for _, p in sgs.qlist(list) do
						if card:targetFixed() or card:targetFilter(sgs.PlayerList(), p, player) then
							if not player:isProhibited(p, card) then
								can_invoke = true
								break
							end
						end
					end
				end
			end
			return not player:hasUsed("#chunrijilu") and can_invoke
		else
			return false
		end
	end,

	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@chunrijilu")
	end
}
chunrijilu = sgs.CreateTriggerSkill {
	name = "chunrijilu",
	view_as_skill = chunrijiluVS,
	events = { sgs.PreCardUsed, sgs.CardFinished, sgs.Damage, sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = data:toCardUse().card
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and use.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				if card:getSkillName() == "chunrijilu" then
					room:setPlayerFlag(player, "wujinzhishu")
					if player:hasSkill("wujinzhishu") then
						room:addPlayerMark(player, "&wujinzhishu-Clear")
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "chunrijilu" and use.card:getTypeId() ~= 0 and use.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				local x = player:getMark("chunrijilu_damage") + player:getMark("chunrijilu_recover")
				room:setPlayerMark(player, "chunrijilu_recover", 0)
				room:setPlayerMark(player, "chunrijilu_damage", 0)
				if x > 0 then
					local log = sgs.LogMessage()
					log.type = "#chunrijilu_dis"
					log.from = use.from
					log.arg = use.card:objectName()
					log.arg2 = x
					room:sendLog(log)
				end
				if x > player:getPile("s_ye"):length() then
					x = x - player:getPile("s_ye"):length()
					if not player:getPile("s_ye"):isEmpty() then
						player:clearOnePrivatePile("s_ye")
					end
					room:loseHp(player, x)
				elseif (x > 0 and x <= player:getPile("s_ye"):length()) then
					for i = 1, x, 1 do
						if not player:getPile("s_ye"):isEmpty() then
							local idlist = player:getPile("s_ye")
							room:fillAG(idlist, player)
							local id = room:askForAG(player, idlist, false, self:objectName())
							--player:invoke("clearAG")
							room:clearAG()
							if id ~= -1 then
								room:throwCard(id, player)
							end
						end
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "chunrijilu" and room:getCardUser(damage.card) and room:getCardUser(damage.card):isAlive() and room:getCardUser(damage.card):objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				room:addPlayerMark(room:getCardUser(damage.card), "chunrijilu_damage")
			end
		elseif event == sgs.HpRecover then
			local recover = data:toRecover()
			if recover.card and recover.card:getSkillName() == "chunrijilu" and room:getCardUser(recover.card) and room:getCardUser(recover.card):isAlive() and room:getCardUser(recover.card):objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				room:addPlayerMark(room:getCardUser(recover.card), "chunrijilu_recover")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}



--海底捞月
HaiteCard = sgs.CreateSkillCard
	{
		name = "haite",
		filter = function(self, targets, to_select)
			return to_select:objectName() ~= sgs.Self:objectName()
		end,
		on_use = function(self, room, source, targets)
			for _, target in ipairs(targets) do
				if (target:isAlive()) then
					room:damage(sgs.DamageStruct(self:objectName(), source, target))
					room:getThread():delay()
				end
			end
		end
	}

haiteViewAsSkill = sgs.CreateZeroCardViewAsSkill
	{
		name = "haite",
		response_pattern = "@@haite",
		view_as = function()
			return HaiteCard:clone()
		end,
	}

haite = sgs.CreateTriggerSkill
	{
		name = "haite",
		events = { sgs.EventPhaseStart, sgs.TurnStart },
		frequency = sgs.Skill_Frequent,
		view_as_skill = haiteViewAsSkill,
		on_trigger = function(self, event, player, data, room)
			local times = room:getTag("SwapPile"):toInt() or 0
			if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) then
				if (times > player:getMark(self:objectName()) or room:getDrawPile():length() == 0) then
					room:askForUseCard(player, "@@haite", "@haite-ask")
				end
			end
			room:setPlayerMark(player, self:objectName(), times)
			return false
		end,
	}
--月盈
yueyingCard = sgs.CreateSkillCard
	{
		name = "yueying",
		target_fixed = true,
		on_use = function(self, room, source, targets)
			if (source:isAlive()) then
				local num = self:subcardsLength()
				if (source:isLastHandCard(self, true)) then
					num = num + 1
					room:setPlayerFlag(source, "yueying")
					room:addPlayerMark(source, "&yueying-Clear")
				end
				room:drawCards(source, num, self:objectName())
			end
		end,
	}

yueying = sgs.CreateViewAsSkill
	{
		name = "yueying",
		n = 999,
		view_filter = function(self, selected, to_select)
			return not sgs.Self:isJilei(to_select)
		end,
		view_as = function(self, cards)
			if #cards ~= 0 then
				local card = yueyingCard:clone()
				for _, c in ipairs(cards) do
					card:addSubcard(c)
				end
				return card
			end
			return nil
		end,
		enabled_at_play = function(self, player)
			return not player:hasUsed("#yueying")
		end,
	}

yueyingMaxCard = sgs.CreateMaxCardsSkill
	{
		name = "#yueying",
		extra_func = function(self, player)
			if (player:hasFlag("yueying")) then
				return 1
			else
				return 0
			end
		end
	}


--累积
hmrleiji = sgs.CreateTriggerSkill {
	name = "hmrleiji",
	events = { sgs.DamageInflicted },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local card = damage.card
			if (not card) or card:isKindOf("SkillCard") then return false end
			local names, name = player:property("SkillDescriptionRecord_hmrleiji"):toString():split("+"),
				card:objectName()
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			room:broadcastSkillInvoke(self:objectName())
			if card:isKindOf("Slash") then name = "hmrleijiSlash" end
			if table.contains(names, name) then
				table.removeOne(names, name)
				damage.damage = damage.damage - 1
				local recover = sgs.RecoverStruct(player, nil, 1)
				room:recover(player, recover)
				room:setPlayerProperty(player, "SkillDescriptionRecord_hmrleiji", sgs.QVariant(table.concat(names, "+")))
				player:setSkillDescriptionSwap("hmrleiji", "%arg11", table.concat(names, "+"))
				room:changeTranslation(player, "hmrleiji", 11)
				if #names == 0 then
					room:changeTranslation(player, "hmrleiji", 1)
				end
			else
				table.insert(names, name)
				room:setPlayerProperty(player, "SkillDescriptionRecord_hmrleiji", sgs.QVariant(table.concat(names, "+")))
				player:setSkillDescriptionSwap("hmrleiji", "%arg11", table.concat(names, "+"))
				room:changeTranslation(player, "hmrleiji", 11)
				damage.damage = damage.damage + 1
			end
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
}
--记忆叠加

jiyidiejia = sgs.CreateTriggerSkill {
	name = "jiyidiejia",
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if (not card) or card:isKindOf("SkillCard") then return false end
			local names, name = player:property("SkillDescriptionRecord_hmrleiji"):toString():split("+"),
				card:objectName()
			if card:isKindOf("Slash") then name = "hmrleijiSlash" end
			if table.contains(names, name) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					table.removeOne(names, name)
					room:broadcastSkillInvoke(self:objectName())
					damage.damage = damage.damage + 1
					room:setPlayerProperty(player, "SkillDescriptionRecord_hmrleiji",
						sgs.QVariant(table.concat(names, "+")))
					player:setSkillDescriptionSwap("hmrleiji", "%arg11", table.concat(names, "+"))
					room:changeTranslation(player, "hmrleiji", 11)
					if #names == 0 then
						room:changeTranslation(player, "hmrleiji", 1)
					end
				end
			else
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					table.insert(names, name)
					room:setPlayerProperty(player, "SkillDescriptionRecord_hmrleiji",
						sgs.QVariant(table.concat(names, "+")))
					player:setSkillDescriptionSwap("hmrleiji", "%arg11", table.concat(names, "+"))
					room:changeTranslation(player, "hmrleiji", 11)
					damage.damage = damage.damage - 1
				end
			end
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
}

-- 令一名角色将牌数量（包括装备）调整至与体力值相同
--[[doAdjustCardsEqualToHp = function(room, target, reason)
	local hp, countOfCards = target:getHp(), target:getCards("he"):length()
	if (hp > countOfCards) then
		room:drawCards(target, hp - countOfCards, reason)
	elseif (hp < countOfCards) then
		local num = countOfCards - hp
		room:askForDiscard(target, reason, num, num, false, true)
	end
end

dusheCard = sgs.CreateSkillCard
{
	name = "dusheCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local target = room:getCurrent()
		local judge = sgs.JudgeStruct()
		judge.who = target
		judge.pattern = "."
		judge.good = true
		judge.reason = "dushe"
		room:judge(judge)
		local suit = judge.card:getSuit()
		-- target:setFlags("DusheTarget")
		-- source:setFlags("DusheSource")
		-- room:setPlayerFlag(target, "")
		-- room:setPlayerFlag(source, "DusheSource")

		local pattern = {}
		if (source:getSeat() == target:getSeat()) then
			table.insert(pattern, "Analeptic")
			if (not source:isWounded()) then
				table.insert(pattern, "Peach")
			end
		else
			table.insert(pattern, "Slash")
		end
		local card = room:askForUseCard(source, table.concat(pattern, ','), "@dushe-card");
		-- 更准确地话应该在ChoiceMade里面清除Flag，但是我偷懒了
		-- room:setPlayerFlag(target, "-DusheTarget")
		-- room:setPlayerFlag(source, "-DusheSource")
		if (card and card:getSuit() == judge.card:getSuit()) then
			doAdjustCardsEqualToHp(room, target, "dushe")
		end
	end
}

dusheViewAsSkill = sgs.CreateZeroCardViewAsSkill
{
	name = "dushe",
	response_pattern = "@@dushe",
	view_as = function(self)
		return dusheCard:clone()
	end
}

dushe = sgs.CreateTriggerSkill
{
	name = "dushe",
	events = {sgs.EventPhaseStart},
	view_as_skill = dusheViewAsSkill,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if (player:isDead() or player:getPhase() ~= sgs.Player_RoundStart) then return end
		local players = room:findPlayersBySkillName(self:objectName())
		for _, p in sgs.qlist(players) do
			room:askForUseCard(p, "@@dushe", "@dushe-use")
		end
	end
}
]]
dushe = sgs.CreateTriggerSkill
	{
		name = "dushe",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.AskForRetrial },
		on_trigger = function(self, event, player, data, room)
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local judge = data:toJudge()
				new_card = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())
				new_card:setSuit(sgs.Card_NoSuit)
				new_card:setModified(true)
				room:broadcastUpdateCard(room:getPlayers(), new_card:getId(), new_card)
				judge.card = new_card
				data:setValue(judge)
				room:broadcastSkillInvoke("dushe", math.random(1, 3))
				log = sgs.LogMessage()
				log.type = "#ChangedJudge"
				log.arg = self:objectName()
				log.from = player
				log.to:append(judge.who)
				log.card_str = tostring(new_card:getId())
				judge:updateResult()
				judge.who:obtainCard(judge.card)
			end
		end
	}
--你的装备牌均视为♠牌；一名角色的♠判定牌生效后，你可以摸一张牌
myjl = sgs.CreateTriggerSkill
	{
		name = "myjl",
		events = { sgs.FinishJudge },
		frequency = sgs.Skill_Compulsory,
		global = true,
		on_trigger = function(self, event, player, data, room)
			local judge = data:toJudge()
			local card = judge.card
			if (card:getSuit() == sgs.Card_Spade) then
				local players = room:findPlayersBySkillName(self:objectName())
				for _, p in sgs.qlist(players) do
					p:drawCards(1, self:objectName())
					room:broadcastSkillInvoke("myjl", math.random(1, 4)) --语音
				end
			end
		end
	}

myjlFilter = sgs.CreateFilterSkill
	{
		name = "#myjl-filter",
		view_filter = function(self, to_select)
			local room = sgs.Sanguosha:currentRoom()
			local place = room:getCardPlace(to_select:getEffectiveId())
			return place == sgs.Player_PlaceEquip
		end,
		view_as = function(self, card)
			local id = card:getEffectiveId()
			local new_card = sgs.Sanguosha:getWrappedCard(id)
			new_card:setSkillName(self:objectName())
			new_card:setSuit(sgs.Card_Spade)
			new_card:setModified(true)
			return new_card
		end
	}
--诅咒
--[[zuzhou = sgs.CreateTriggerSkill
{
	name = "zuzhou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zuzhou",
	events = {sgs.AskForRetrial},
	on_trigger = function(self, event, player, data, room)
		if (player:getMark("@zuzhou") > 0 and room:askForSkillInvoke(player, self:objectName())) then
			room:broadcastSkillInvoke(self:objectName())
			player:loseMark("@zuzhou")
			local judge = data:toJudge()
			new_card = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())
			new_card:setSuit(sgs.Card_Spade)
			new_card:setModified(true)
			room:broadcastUpdateCard(room:getPlayers(), new_card:getId(), new_card)
			judge.card = new_card
			data:setValue(judge)
			log = sgs.LogMessage()
			log.type = "#ChangedJudge"
			log.arg = self:objectName()
			log.from = player
			log.to:append(judge.who)
			log.card_str = tostring(new_card:getId())
			judge:updateResult()
			room:damage(sgs.DamageStruct("zuzhou", player, judge.who,1, sgs.DamageStruct_Normal))	
		end
	end
}]]
zuzhouCard = sgs.CreateSkillCard {
	name = "zuzhouCard",
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:handleAcquireDetachSkills(source, "-myjl")
		source:loseAllMarks("@zuzhou")
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|red"
		judge.good = true
		judge.negative = true
		judge.reason = self:objectName()
		judge.who = targets[1]
		room:judge(judge)
		--if not judge.card:isRed() then		
		--	room:damage(sgs.DamageStruct("zuzhou", source, targets[1], 2, sgs.DamageStruct_Normal))
		--	end
		if not judge:isGood() then
			room:damage(sgs.DamageStruct("zuzhou", source, targets[1], 2, sgs.DamageStruct_Normal))
		end
	end,
}
zuzhouVS = sgs.CreateZeroCardViewAsSkill {
	name = "zuzhou",
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		return zuzhouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@zuzhou") >= 1
	end
}
zuzhou = sgs.CreateTriggerSkill {
	name = "zuzhou",
	frequency = sgs.Skill_Limited,
	view_as_skill = zuzhouVS,
	limit_mark = "@zuzhou",
	on_trigger = function()
	end
}
--治愈讲座基础版
zhiyujz = sgs.CreateTriggerSkill {
	name = "zhiyujz",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		if event == sgs.PreHpRecover then
			local room = player:getRoom()
			local recover = data:toRecover()
			for _, yuno_1 in sgs.qlist(room:findPlayersBySkillName("zhiyujz")) do
				if recover.who
					and (recover.who:objectName() == yuno_1:objectName()) then
					local xd = recover.recover + player:getHp()
					local yd = player:getMaxHp()
					if xd > yd then
						yuno_1:getRoom():setPlayerProperty(player, "hp", sgs.QVariant(xd))
						return true
					end
				end
			end
		end
		return false
	end
}
--治愈讲座.进阶
zhiyujz_jz = sgs.CreateTriggerSkill {
	name = "zhiyujz_jz",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		if event == sgs.PreHpRecover then
			local room = player:getRoom()
			local recover = data:toRecover()
			for _, yuno_1 in sgs.qlist(room:findPlayersBySkillName("zhiyujz_jz")) do
				if recover.who and (recover.who:objectName() == yuno_1:objectName()) then
					local xd = recover.recover + player:getHp()
					local yd = player:getMaxHp()
					if xd > yd then
						yuno_1:getRoom():setPlayerProperty(player, "hp", sgs.QVariant(xd))
						return true
					end
				end
			end
		end
		return false
	end
}
jzxymianyi = sgs.CreateTriggerSkill { --诡异的无法被跳过阶段技能谢谢饺神
	name = "#jzxymianyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseSkipping },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			return true
		end
	end,

}
--治愈讲座.觉醒
zhiyujz_jx = sgs.CreateTriggerSkill {
	name = "zhiyujz_jx",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		if event == sgs.PreHpRecover then
			local room = player:getRoom()
			local recover = data:toRecover()
			for _, yuno_1 in sgs.qlist(room:findPlayersBySkillName("zhiyujz_jx")) do
				if recover.who
					and (recover.who:objectName() == yuno_1:objectName()) then
					local xd = recover.recover + player:getHp()
					local yd = player:getMaxHp()
					if xd > 2 * yd then
						xd = 2 * yd
					end
					if xd > yd then
						yuno_1:getRoom():setPlayerProperty(player, "hp", sgs.QVariant(xd))
						return true
					end
				end
			end
		end
		return false
	end
}




--圣诞暖阳
shengdannuan = sgs.CreateSkillCard {
	name = "shengdanny",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if #targets == 1 then
			return false
		else
			return true
		end
	end,
	on_use = function(self, room, source, targets)
		local dest = targets[1]
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = dest
		damage.damage = 1
		damage.nature = sgs.DamageStruct_Fire
		damage.reason = self:objectName()
		room:damage(damage)
		local rec = sgs.RecoverStruct()
		rec.recover = 2
		rec.who = source
		room:recover(dest, rec)
	end,

}

shengdanny = sgs.CreateViewAsSkill {
	name = "shengdanny",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 0 then return end
		local vs_card = shengdannuan:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#shengdanny")
	end,
}
--狙击
jujiman = sgs.CreateTriggerSkill {
	name = "jujiman",
	events = { sgs.EventPhaseStart, sgs.Damaged },
	on_trigger = function(self, event, player, data, room)
		--local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke("jujiman", math.random(1, 3))
					player:gainMark("@jujiman")
					return true
				end
			elseif player:getPhase() == sgs.Player_Start then
				if player:getMark("@jujiman") > 0 then
					player:loseAllMarks("@jujiman")
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"jujimaninvoke", true, true)
					if target then
						room:broadcastSkillInvoke("jujiman", 2)
						room:damage(sgs.DamageStruct(self:objectName(), player, target, 2))
					end
				end
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if player:getMark("@jujiman") > 0 then
				player:loseAllMarks("@jujiman")
			end
		end
	end,
	priority = 3,


}

--隐蔽
yinbiman = sgs.CreateTriggerSkill {
	name = "yinbiman",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardEffected, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data, room)
		local msg = sgs.LogMessage()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:removePlayerMark(player, "yinbimanTarget")
				room:removePlayerMark(player, "&yinbiman")
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:loseHp(player, 1)
					room:addPlayerMark(player, "yinbimanTarget")
					room:addPlayerMark(player, "&yinbiman")
					room:broadcastSkillInvoke("yinbiman", math.random(1, 2)) --语音
				end
			end
		elseif event == sgs.CardEffected then
			if player:getMark("yinbimanTarget") > 0 then
				local effect = data:toCardEffect()
				if effect.to:objectName() == player:objectName() then
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.play_animation = true
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						return true
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if player:getMark("yinbimanTarget") > 0 then
				local move = data:toMoveOneTime()
				if not move.to or move.to:objectName() ~= player:objectName() then return false end
				if move.to_place ~= sgs.Player_PlaceDelayedTrick then return false end
				local card = sgs.Sanguosha:getCard(move.card_ids:first())
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.play_animation = true
				judge.pattern = ".|black"
				judge.good = true
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					room:throwCard(card, player)
				end
			end
		end
	end
}
--索尔斯
suoersiman = sgs.CreateTriggerSkill {
	name = "suoersiman",
	frequency = sgs.Skill_Limited,
	limit_mark = "@suoersiman",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		--local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if player:getMark("@suoersiman") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke("suoersiman", 1)
					player:loseMark("@suoersiman")
					local poi = player:getHandcardNum() + player:getEquips():length()
					player:throwAllCards()
					if player:isWounded() then room:recover(player, sgs.RecoverStruct(player)) end
					for i = 1, poi, 1 do
						local judge = sgs.JudgeStruct()
						judge.play_animation = false
						judge.who = player
						judge.reason = self:objectName()
						room:judge(judge)
						if judge.card:isKindOf("BasicCard") then
							player:obtainCard(judge.card)
						else
							local targets = sgs.SPlayerList()
							for _, p in sgs.qlist(room:getOtherPlayers(player)) do
								if player:canSlash(p, nil, false) then targets:append(p) end
							end
							if targets:isEmpty() then return false end
							local target = room:askForPlayerChosen(player, targets, self:objectName(), "suoersimaninvoke")
							if target then
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:deleteLater()
								slash:setSkillName(self:objectName())
								room:useCard(sgs.CardUseStruct(slash, player, target))
							end
						end
					end
				end
			end
		end
	end
}
--经验累积
jysuit = {}
leijijingyan = sgs.CreateTriggerSkill {
	name = "leijijingyan",
	events = { sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardUsed, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if ((event == sgs.PreCardUsed) or (event == sgs.CardResponded)) and (player:getPhase() == sgs.Player_Play) then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				local suit = card:getSuitString()
				local num = (player:getMark("@jingyan") + 1)
				if #jysuit < num and (not table.contains(jysuit, suit .. "_char")) then
					table.insert(jysuit, suit .. "_char")
				end
				local mark = nil
				for _, name in ipairs(player:getMarkNames()) do
					if player:getMark(name) > 0 and name:startsWith("&leijijingyan") then
						mark = name
						break
					end
				end

				if not mark then
					mark = "&leijijingyan+:+" .. table.concat(jysuit, "+") .. "-Clear"
					room:setPlayerMark(player, mark, 1)
				else
					room:setPlayerMark(player, mark, 0)
					mark = "&leijijingyan+:+" .. table.concat(jysuit, "+") .. "-Clear"
					room:setPlayerMark(player, mark, 1)
				end
			end
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_RoundStart) then
			while #jysuit > 0 do table.remove(jysuit) end
		elseif event == sgs.EventPhaseEnd then
			local num = (player:getMark("@jingyan") + 1)
			if (player:getPhase() == sgs.Player_Finish) and (#jysuit >= num) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:gainMark("@jingyan")
					room:broadcastSkillInvoke("leijijingyan", math.random(1, 2)) --语音
				end
			end
		end
		if event == sgs.CardUsed then
			if use.card:isKindOf("Peach") then
				room:setPlayerFlag(player, "zhiliaoleiji")
			end
		end
		if event == sgs.CardFinished then
			if use.card:isKindOf("Peach") then
				room:setPlayerFlag(player, "-zhiliaoleiji")
			end
		end
		return false
	end, }

leijijyb = sgs.CreateTriggerSkill {
	name = "#leijijyb",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local rec = data:toRecover()
		for _, p in sgs.qlist(room:findPlayersBySkillName("leijijingyan")) do
			if rec.card and rec.card:isKindOf("Peach") and p:hasFlag("zhiliaoleiji") then
				rec.recover = rec.recover + p:getMark("@jingyan")
				data:setValue(rec)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
--向阳使
xyscard = sgs.CreateSkillCard {
	name = "xiangyangshi",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets < player:getMark("@yanliao")
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			for _, k in sgs.qlist(room:findPlayersBySkillName("xiangyangshi")) do
				local rec = sgs.RecoverStruct()
				if p:getHp() >= p:getMaxHp() and (p:getMaxHp() * 2) - 1 >= p:getHp()
					and (k:objectName() ~= p:objectName())
				then
					local num = (p:getHp() - p:getMaxHp()) + 1
					local x = p:getHp() - num
					local x2 = (x + num) + 1
					k:getRoom():setPlayerProperty(p, "hp", sgs.QVariant(x))
					k:getRoom():setPlayerProperty(p, "hp", sgs.QVariant(x2))
					source:loseAllMarks("@yanliao")
				else
					if p:getMaxHp() > p:getHp() then
						rec.recover = 1
						rec.who = source
						room:recover(p, rec)
						source:loseAllMarks("@yanliao")
					end
				end
			end
		end
	end,
}

xysvs = sgs.CreateViewAsSkill {
	name = "xiangyangshi",
	n = 0,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local card = xyscard:clone()
		return card
	end,
	response_pattern = "@@xiangyangshi",
}
xys_ex = sgs.CreateTriggerSkill {
	name = "#xys_ex",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		--for _, p in ipairs(use.to) do
		if use.card and use.card:isKindOf("GodSalvation") then
			for _, p in sgs.qlist(use.to) do
				if p:getHp() >= p:getMaxHp() and (p:getMaxHp() * 2) - 1 >= p:getHp()
					and (player:objectName() ~= p:objectName())
				then
					local num = (p:getHp() - p:getMaxHp()) + 1
					local x = p:getHp() - num
					local x2 = (x + num) + 1
					player:getRoom():setPlayerProperty(p, "hp", sgs.QVariant(x))
					player:getRoom():setPlayerProperty(p, "hp", sgs.QVariant(x2))
				end
			end
		end
	end,
}
--[[
xiangyangshi = sgs.CreateTriggerSkill{
	name = "xiangyangshi" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
	view_as_skill = xysvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Discard then
		player:loseAllMarks("@yanliao")	
			local num = player:getHandcardNum() - player:getMaxCards()
			player:gainMark("@yanliao",num)
		end		
		end
		if event == sgs.EventPhaseEnd and player:getMark("@yanliao")  > 0   then
		   if player:getPhase() == sgs.Player_Discard and
		   room:askForSkillInvoke(player, self:objectName(), data) then
		   room:askForUseCard(player, "@@xiangyangshi", "~xysyn")
		   end
	    end
		
	end,
}]]
xiangyangshi = sgs.CreateTriggerSkill {
	name = "xiangyangshi",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd },
	view_as_skill = xysvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				and player:getPhase() == sgs.Player_Discard then
				local room = player:getRoom()
				room:addPlayerMark(player, "@yanliao", move.card_ids:length())
			end
		end
		if event == sgs.EventPhaseEnd and player:getMark("@yanliao") > 0 then
			if player:getPhase() == sgs.Player_Discard then
				-- if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "@@xiangyangshi", "~xysyn")
				-- end
				player:loseAllMarks("@yanliao")
			end
		end
	end,
}


--御势
yushicard = sgs.CreateSkillCard {
	name = "yushicp",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and not (to_select:hasFlag("yushiflag")) and
		to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local ids = targets[1]:handCards()
		room:fillAG(ids, source)
		room:getThread():delay(2000)
		room:clearAG(source)
		room:setPlayerFlag(targets[1], "yushiflag")
		room:addPlayerMark(targets[1], "&yushicp+to+#" .. source:objectName() .. "-Clear")
		local basic = sgs.IntList()
		for _, d in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(d):objectName() == self:getUserString() then
				basic:append(d)
			end
		end
		if basic:isEmpty() then return false end
		room:fillAG(basic, source)
		local id = room:askForAG(source, basic, false, "yushicp")
		if id ~= -1 then
			room:showCard(targets[1], id)
			room:obtainCard(source, id)
		end

		room:clearAG(source)
	end,


}

yushicp = sgs.CreateViewAsSkill {
	name = "yushicp",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 0 then return end
		local c = sgs.Self:getTag("yushicp"):toCard()
		if c then
			local card = yushicard:clone()
			card:addSubcard(cards[1])
			card:setUserString(c:objectName())
			return card
		end
	end,
}
yushicp:setGuhuoDialog("!lr")
--明断
mingduan = sgs.CreateTriggerSkill {
	name = "mingduan",
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local vi = damage.to
		if event == sgs.Damage then
			if damage.nature == sgs.DamageStruct_Normal then
				if vi:getMark("@duanding") > 0 then
					for _, dia in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if vi:getMark("&mingduan+to+#" .. dia:objectName()) > 0 then
							if dia:getMark("mingduanhuan-Clear") == 0 then
								room:broadcastSkillInvoke("mingduan", 2)
								dia:drawCards(1)
								room:addPlayerMark(dia, "mingduanhuan-Clear")
							elseif dia:getMark("mingduanhuan-Clear") == 1 then
								room:broadcastSkillInvoke("mingduan", 1)
								local s = room:askForPlayerChosen(dia, room:getAlivePlayers(), "mingduan_put",
									"mingduan-invoke")
								local ids = room:getNCards(1, false)
								local id = ids:first()
								local card = sgs.Sanguosha:getCard(id)
								local card_ex
								if not s:isKongcheng() then
									local card_data = sgs.QVariant()
									card_data:setValue(card)
									card_ex = room:askForCard(s, ".", "@mingduanqiuh:::" .. card:objectName(), card_data,
										sgs.Card_MethodNone)
								end
								if card_ex then
									local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, s:objectName(),
										self:objectName(), nil)
									local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE,
										s:objectName(), self:objectName(), nil)
									local move1 = sgs.CardsMoveStruct()
									move1.card_ids:append(card_ex:getEffectiveId())
									move1.from = s
									move1.to = nil
									move1.to_place = sgs.Player_DrawPile
									move1.reason = reason1
									local move2 = sgs.CardsMoveStruct()
									move2.card_ids = ids
									move2.from = s
									move2.to = s
									move2.to_place = sgs.Player_PlaceHand
									move2.reason = reason2
									local moves = sgs.CardsMoveList()
									moves:append(move1)
									moves:append(move2)
									room:moveCardsAtomic(moves, false)
								else
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NAUTRAL_ENTER,
										s:objectName(), self:objectName(), nil)
									room:throwCard(card, reason, nil)
								end
							end
							vi:loseMark("@duanding")
							room:setPlayerMark(vi, "&mingduan+to+#" .. dia:objectName(), 0)
						end
					end
				end
				for _, dia in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						p:loseMark("@duanding")
						room:setPlayerMark(p, "&mingduan+to+#" .. dia:objectName(), 0)
					end
					local s = room:askForPlayerChosen(dia, room:getAlivePlayers(), self:objectName(), "duanding-invoke")
					room:setPlayerMark(s, "&mingduan+to+#" .. dia:objectName(), 1)
					s:gainMark("@duanding")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--无视特性
wushitexing = sgs.CreateTriggerSkill {
	name = "wushitexing",
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if ((use.card:objectName() == "savage_assault") or (use.card:objectName() == "archery_attack") or (use.card:isKindOf("Slash")))
			and player:askForSkillInvoke(self:objectName(), data) then
			for _, p in sgs.qlist(use.to) do
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = p
				damage.damage = 1
				damage.nature = sgs.DamageStruct_Normal
				room:damage(damage)
				room:setPlayerFlag(p, "wstxflag")
				if not player:isAlive() then break end
			end
		end
	end
}
wstxbuff = sgs.CreateTriggerSkill {
	name = "#wstxbuff",
	events = { sgs.CardEffected },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local room = player:getRoom()
		if not effect.from or effect.to:objectName() == effect.from:objectName() then return false end
		if effect.to:hasFlag("wstxflag") then
			if effect.from and effect.from:hasSkill(self:objectName()) then
				room:setPlayerFlag(effect.to, "-wstxflag")
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--没有朋友
meipengyou = sgs.CreateDistanceSkill {
	name = "meipengyou",
	correct_func = function(self, from, to)
		if to:hasSkill(self:objectName()) then
			return 1
		else
			if from:hasSkill(self:objectName()) then
				return 1
			end
		end
	end
}
--继承者
jichengzhe = sgs.CreateTriggerSkill {
	name = "jichengzhe",
	events = { sgs.Dying },
	frequency = sgs.Skill_Wake,
	waked_skills = "huoliquankai",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() then
			room:addPlayerMark(player, "fanji_waked")
			room:addPlayerMark(player, self:objectName())
			room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
			room:handleAcquireDetachSkills(player, "huoliquankai", true)
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
		end
		return false
	end,
	can_wake = function(self, event, player, data)
		if player:getMark("zhejc_waked") > 0 then return false end
		if player:getMark("fanji_waked") > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		return true
	end,
}
jichengzhe1 = sgs.CreateTriggerSkill {
	name = "#jichengzhe1",
	events = { sgs.BuryVictim },
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:revivePlayer(player)
		room:addPlayerMark(player, "zhejc_waked")
		room:recover(player, sgs.RecoverStruct(player, nil, 2 - player:getHp()))
		room:setPlayerProperty(player, "general", sgs.QVariant("washake"))
		room:handleAcquireDetachSkills(player, "juexingmoshen", true)
		room:handleAcquireDetachSkills(player, "huoliquankai", true)
		room:handleAcquireDetachSkills(player, "-jichengzhe")
		room:handleAcquireDetachSkills(player, "-Cjiyongbing")
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName()) and target:getMark("zhejc_waked") == 0
	end,
}
--火力全开
huoliquankai = sgs.CreateTriggerSkill {
	name = "huoliquankai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		if player:isAllNude() then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		player:throwAllCards()
		local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "huoli-invoke", true,
			true)
		if not s then return false end
		room:damage(sgs.DamageStruct(self:objectName(), player, s, 1, sgs.DamageStruct_Normal))
		player:drawCards(1)
	end
}
--C级佣兵
Cjiyongbing = sgs.CreateTriggerSkill {
	name = "Cjiyongbing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.Death, sgs.TurnStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local bks = room:findPlayerBySkillName(self:objectName())
		if not player:hasSkill(self:objectName()) then return false end
		if bks:getRole() == "lord" then return false end
		if event == sgs.GameStart then
			--[[local isRadom=bks:getRole()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "renegade" then
					local temp=isRadom
					room:setPlayerProperty(bks,"role",sgs.QVariant("renegade"))
					room:setPlayerProperty(p,"role",sgs.QVariant(temp))
				end
			end]]
			room:setPlayerProperty(bks, "role", sgs.QVariant("renegade"))
			room:updateStateItem()
		elseif event == sgs.Death or event == sgs.TurnStart then
			local death = data:toDeath()
			local a = 0
			local b = 0
			local c = 0
			local max = a
			local isloyalist = 0
			local isrebel = 0
			local isrenegade = 1
			if death.who ~= bks then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (p:getRole() == "lord" or p:getRole() == "loyalist") and p:isFemale() and p:objectName() ~= bks:objectName() then
						a = a + 1
					elseif (p:getRole() == "rebel") and p:isFemale() and p:objectName() ~= bks:objectName() then
						b = b + 1
					elseif (p:getRole() == "renegade") and p:isFemale() and p:objectName() ~= bks:objectName() then
						c = c + 1
					end
				end
				if b > a then
					isloyalist = 0
					isrebel = 1
					isrenegade = 0
				end
				if a > b then
					isloyalist = 1
					isrebel = 0
					isrenegade = 0
				end
				if isloyalist == 1 then
					room:setPlayerProperty(bks, "role", sgs.QVariant("loyalist"))
					room:setPlayerProperty(bks, "role", sgs.QVariant("loyalist"))
				elseif isrebel == 1 then
					room:setPlayerProperty(bks, "role", sgs.QVariant("rebel"))
				elseif isrenegade == 1 then
					room:setPlayerProperty(bks, "role", sgs.QVariant("renegade"))
				end
				room:updateStateItem()
			end
		end
	end
}
--觉醒魔神
juexingmoshen = sgs.CreateTriggerSkill {
	name = "juexingmoshen",
	events = { sgs.Damage },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		local suit = judge.card:getSuit()
		if suit == sgs.Card_Spade then
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "juexingmoshen-invoke",
				true, true)
			if not s then return false end
			room:damage(sgs.DamageStruct(self:objectName(), player, s, 1, sgs.DamageStruct_Normal))
		elseif suit == sgs.Card_Diamond then
			local tl = player:getMaxHp()
			local mhp = sgs.QVariant()
			mhp:setValue(tl + 1)
			room:setPlayerProperty(player, "maxhp", mhp)
		elseif suit == sgs.Card_Club then
			player:drawCards(1)
		elseif suit == sgs.Card_Heart then
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
		end
		return false
	end,
}
--闪耀
shanyao = sgs.CreateTriggerSkill {
	name = "shanyao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardOffset },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card and effect.card:isKindOf("Slash") and effect.card:isRed() then
			if effect.card:isRed() and room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(1)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:deleteLater()
				slash:setSkillName(self:objectName())
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = player
				use.to:append(effect.to)
				room:useCard(use)
			end
		end
	end
}
--剑速
jiansu = sgs.CreateTriggerSkill {
	name = "jiansu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.Damaged },
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local asina = room:findPlayerBySkillName(self:objectName())
		if not asina then return false end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			if player:objectName() ~= asina:objectName() then --and room:askForSkillInvoke(asina, self:objectName(),data) then		
				local s = room:askForPlayerChosen(asina, room:getOtherPlayers(player), self:objectName(), "jiansu-invoke",
					true, true)
				if not s then return false end
				local target = s
				if target then
					room:addPlayerMark(s, "jiansub")
					room:addPlayerMark(player, "jiansua")
					room:askForUseSlashTo(player, s, "#jiansu", false)
					room:askForUseSlashTo(asina, s, "#jiansu", false)

					room:setPlayerMark(s, "jiansub", 0)
					room:setPlayerMark(player, "jiansua", 0)
					--s:loseAllMarks("jiansub")
					--player:loseAllMarks("jiansua")
					return false
				end
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.to:getMark("jiansub") ~= 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("jiansua") ~= 0 then
						p:drawCards(1)
						asina:drawCards(1)
					end
				end
			end
		end
	end,

}

--预告

--[[
yugaoks = sgs.CreateTriggerSkill{
   name = "#yugaoks",
   frequency = sgs.Skill_Compulsory,
   events = {sgs.GameStart,sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
   on_trigger = function(self, event,player,data)
       local room = player:getRoom()
	   if event == sgs.GameStart then
	   --local num = math.ceil(room:alivePlayerCount() )
	  player:gainMark("@yugao",7)
	   end
	   if event == sgs.EventPhaseStart 	and player:getPhase() == sgs.Player_Play then	
	   local id = room:getTag("yugao_card"):toInt()
	   if id == 0 then end
	   if id ~= 0 then
	   room:obtainCard(player, id)
	   room:removeTag("yugao_card")
		room:setTag("yugaoguihuanc", sgs.QVariant(id))
	   end
	  end
	if event == sgs.EventPhaseEnd 	and player:getPhase() == sgs.Player_Play then
	  for _,card in sgs.qlist(player:getHandcards()) do
		  if card:getId() == room:getTag("yugaoguihuanc"):toInt()  then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
				     if p:getMark("@yugaofenghuan") ~= 0 then
				       room:obtainCard(p, card)		
                       room:removeTag("yugaoguihuanc")				
						p:loseAllMarks("@yugaofenghuan")	
                     end		
                end				
	end

	       end
	   end
	
	
	  if event == sgs.CardsMoveOneTime then
	 local move = data:toMoveOneTime()
	 for _,id in sgs.qlist(move.card_ids) do
	 if move.to and move.to:objectName() == player:objectName()and move.from and id == room:getTag("yugao_card"):toInt()and
	 move.from:objectName() ~= player:objectName()  and
	 (move.from_places:contains(sgs.Player_PlaceHand) or
	 move.from_places:contains(sgs.Player_PlaceEquip))
	  then
	  for  _,p in sgs.qlist(room:getAlivePlayers()) do
	  if p:objectName() == move.from:objectName() then
   p:gainMark("@yugaofenghuan")
	  end
 end
 end
 end
	  end
	
	   end,
}
guaidao = sgs.CreateTriggerSkill{
   name = "#guaidao",
   frequency = sgs.Skill_Compulsory,
   events = {sgs.CardsMoveOneTime},
   on_trigger = function(self, event,player,data)
       local room = player:getRoom()
	   if event == sgs.CardsMoveOneTime then
	 local move = data:toMoveOneTime()
	 for _,id in sgs.qlist(move.card_ids) do
	 if  move.from and id == room:getTag("yugaoguihuanc"):toInt()and	
	 move.from_places:contains(sgs.Player_PlaceHand)
	  then
	  for  _,p in sgs.qlist(room:getAlivePlayers()) do
	 p:loseAllMarks("@yugaofenghuan")
	 room:removeTag("yugaoguihuanc")
 end
 end
 end
	  end
	   end
	
}
yugaobcard = sgs.CreateSkillCard{
    name = "yugaobp",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	       return #targets < 1 and to_select:objectName() ~= player:objectName()
	 end,
	on_use = function(self, room, source, targets)
		local ids = targets[1]:handCards()
		room:fillAG(ids, source)
		room:getThread():delay(1000)	
		
		local id = room:askForAG(source, ids, false, "yu1gao")
		if id ~= -1 then
		room:showCard(targets[1], id)
			room:setTag("yugao_card", sgs.QVariant(id))
		room:clearAG(source)	
	end
	end

}

yu1gao = sgs.CreateViewAsSkill{
     name = "yugaobp",
	 n = 0,
	 view_as = function(self,cards)
   if #cards~=0 then return nil end
     local card = yugaobcard:clone()
	 return card
	 end,
	 response_pattern = "@@yugaobp",
}



yugaobp = sgs.CreateTriggerSkill{
	name = "yugaobp",
	events = {sgs.AfterDrawInitialCards},
	view_as_skill = yu1gao,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:askForUseCard(player,"@@yugaobp", "ksyugaobp")
			
		end,
		
}

yugaocard = sgs.CreateSkillCard{
    name = "yugao",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and (not to_select:isKongcheng()) and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local ids = targets[1]:handCards()
		room:fillAG(ids, source)
		room:getThread():delay(1000)	
		if source:getMark("@yugao") == 0 then room:clearAG(source) room:setPlayerFlag(source, "yugaowanbi")  return  end
        if 	room:askForSkillInvoke(source, self:objectName()) and source:getMark("@yugao") ~= 0 then
		source:loseMark("@yugao")
		local id = room:askForAG(source, ids, false, "yugao")
		if id ~= -1 then
		room:showCard(targets[1], id)
			room:setTag("yugao_card", sgs.QVariant(id))
		end	
		end
		room:clearAG(source)
		if source:hasFlag("yugaowanbi") then
		room:setPlayerFlag(source, "yugaowanbi2")
		end
	room:setPlayerFlag(source, "yugaowanbi")
	
	end,

}

yugao = sgs.CreateViewAsSkill{
     name = "yugao",
	 n = 0,
	 view_filter = function(self, selected, to_select)
	  return #selected == 0
	 end,
	 view_as = function(self, cards)
	 local vs_card = yugaocard:clone()
	 return vs_card
	 end,
	 enabled_at_play = function(self, target)
	        return  not target:hasFlag("yugaowanbi2")
	
end,
}]]

yugaocard = sgs.CreateSkillCard {
	name = "yugao",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and (not to_select:isKongcheng()) and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local ids = targets[1]:handCards()
		room:fillAG(ids, source)
		room:getThread():delay(1000)
		if source:getMark("@yugao") == 0 then
			room:clearAG(source)
			room:setPlayerFlag(source, "yugaowanbi")
			return
		end
		local dest = sgs.QVariant()
		dest:setValue(targets[1])
		if (room:askForSkillInvoke(source, self:objectName(), dest) and (source:getMark("@yugao") ~= 0 or sgs.Sanguosha:getCurrentCardUsePattern() == "@@yugao")) then
			if sgs.Sanguosha:getCurrentCardUsePattern() ~= "@@yugao" then
				source:loseMark("@yugao")
			end
			local id = room:askForAG(source, ids, false, "yugao")
			if id ~= -1 then
				room:showCard(targets[1], id)
				room:setTag("yugao_card", sgs.QVariant(id))
				room:setCardTip(id, "yugao")
			end
		end
		room:clearAG(source)
	end,

}

yugaoVS = sgs.CreateViewAsSkill {
	name = "yugao",
	n = 0,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		local vs_card = yugaocard:clone()
		return vs_card
	end,
	enabled_at_play = function(self, target)
		return target:usedTimes("#yugao") < 2
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@yugao"
	end
}
yugao = sgs.CreateTriggerSkill {
	name = "yugao",
	events = { sgs.AfterDrawNCards, sgs.GameStart },
	view_as_skill = yugaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:gainMark("@yugao", 7)
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			room:askForUseCard(player, "@@yugao", "ksyugaobp")
		end
	end,

}


guaidao = sgs.CreateTriggerSkill {
	name = "guaidao",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local id = room:getTag("yugao_card"):toInt()
			if id == 0 then end
			if id ~= 0 then
				room:obtainCard(player, id)
				room:setCardTip(id, "yugao")
				room:removeTag("yugao_card")
				room:setTag("yugaoguihuanc", sgs.QVariant(id))
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:getId() == room:getTag("yugaoguihuanc"):toInt() then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("@yugaofenghuan") ~= 0 then
							room:obtainCard(p, card)
							room:setCardTip(card:getId(), "-yugao")
							room:removeTag("yugaoguihuanc")
							p:loseAllMarks("@yugaofenghuan")
						end
					end
				end
			end
		end


		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			for _, id in sgs.qlist(move.card_ids) do
				if move.to and move.to:objectName() == player:objectName() and move.from and id == room:getTag("yugao_card"):toInt() and
					move.from:objectName() ~= player:objectName() and
					(move.from_places:contains(sgs.Player_PlaceHand) or
						move.from_places:contains(sgs.Player_PlaceEquip))
				then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:objectName() == move.from:objectName() then
							p:gainMark("@yugaofenghuan")
						end
					end
				end
				if move.from and id == room:getTag("yugaoguihuanc"):toInt() and
					move.from_places:contains(sgs.Player_PlaceHand)
				then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						p:loseAllMarks("@yugaofenghuan")
						room:removeTag("yugaoguihuanc")
					end
				end
			end
		end
	end,
}










--委托
weituo       = sgs.CreateTriggerSkill {
	name = "weituo",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			for _, yma in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to ~= damage.from and damage.from:isAlive() and damage.to:isAlive() and damage.to ~= yma and damage.from ~= yma then
					for _, x in sgs.qlist(room:getAlivePlayers()) do
						if x:getMark("@weituozhe") == 1 then
							return false
						end
					end
					if room:askForSkillInvoke(yma, self:objectName(), data) then
						local id = room:drawCard()
						local card = sgs.Sanguosha:getCard(id)
						room:moveCardTo(card, nil, sgs.Player_PlaceTable, true)
						local thread = room:getThread()
						thread:delay()
						if room:askForSkillInvoke(damage.to, "weituo11", data) then
							damage.to:obtainCard(card)
							room:addPlayerMark(damage.to, "&@weituozhe")
							room:addPlayerMark(damage.from, "&@liufangzhe")
							damage.to:gainMark("@weituozhe")
							damage.from:gainMark("@liufangzhe")
						else
							yma:obtainCard(card)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--流放
liufang      = sgs.CreateTriggerSkill {
	name = "liufang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:isAlive() and player:getMark("@liufangzhe") == 1 then
					for _, wtz in sgs.qlist(room:getAlivePlayers()) do
						if wtz and wtz:isAlive() and wtz:getMark("@weituozhe") == 1 then
							local num = wtz:getLostHp()
							room:broadcastSkillInvoke("liufang", 2)
							room:loseHp(player, num)
						end
					end
				end
				if player and player:isAlive() and player:getMark("@liufangzhe") == 1 and player:getHp() == 1 then
					for _, wtz in sgs.qlist(room:getAlivePlayers()) do
						if wtz:getMark("@weituozhe") == 1 then
							room:broadcastSkillInvoke("liufang", 1)
							wtz:turnOver()
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--怨火
yuanhuo      = sgs.CreateTriggerSkill {
	name = "yuanhuo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:getMark("@liufangzhe") == 1 then
			player:loseAllMarks("@liufangzhe")
			room:setPlayerMark(player, "&@liufangzhe", 0)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				p:loseAllMarks("@weituozhe")
				room:setPlayerMark(p, "&@weituozhe", 0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

yuanhuo_ex   = sgs.CreateTriggerSkill {
	name = "#yuanhuo_ex",
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local players = room:getOtherPlayers(player)
		for _, p in sgs.qlist(players) do
			p:loseAllMarks("@weituozhe")
			p:loseAllMarks("@liufangzhe")
			room:setPlayerMark(p, "&@liufangzhe", 0)
			room:setPlayerMark(p, "&@weituozhe", 0)
			room:damage(sgs.DamageStruct("yuanhuo", nil, p, 1, sgs.DamageStruct_Fire))
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
--争导
zhengdao     = sgs.CreateTriggerSkill {
	name = "zhengdao",
	frequency = sgs.Skill_Frequent,
	events = { sgs.PreCardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if not ((use.card:objectName() == "indulgence") or (use.card:objectName() == "supply_shortage") or (use.card:objectName() == "lightning") or (use.card:objectName() == "shuugakulyukou")) and
			(use.card:getSuit() == sgs.Card_Heart or use.card:getSuit() == sgs.Card_Spade) and room:askForSkillInvoke(player, self:objectName(), data) then
			local jnmb = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not (p:isKongcheng()) then
					jnmb:append(p)
				end
			end
			local s = room:askForPlayerChosen(player, jnmb, self:objectName(), "zhengdao-invoke", true, true)
			if not s then return false end
			if player:getMark("@zhengdao") == 0 then
				if (player:pindian(s, "zhengdao", use.card)) then
					room:broadcastSkillInvoke("zhengdao", 2)
				else
					room:setPlayerFlag(player, "zhengdaobuff")
					player:gainMark("@zhengdao")
					room:broadcastSkillInvoke("zhengdao", 1)
					return false
				end
			end
			if player:getMark("@zhengdao") ~= 0 then
				if (player:pindian(s, "zhengdao", use.card)) then
					room:setPlayerFlag(player, "zhengdaobuff")
					player:loseAllMarks("@zhengdao")
				else
					player:loseAllMarks("@zhengdao")
				end
			end
		end

		return false
	end
}

zhengdaobuff = sgs.CreateTriggerSkill {
	name = "#zhengdaobuff",
	events = { sgs.TargetConfirmed },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if player:isAlive() and player:hasFlag("zhengdaobuff") and not use.card:isKindOf("EquipCard") then
				player:setFlags("-zhengdaobuff")
				local nullified_list = use.nullified_list
				for _, p in sgs.qlist(use.to) do
					table.insert(nullified_list, p:objectName())
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		end
	end
}

zhengdaozb   = sgs.CreateTriggerSkill {
	name = "#zhengdaozb",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("EquipCard") and player:hasFlag("zhengdaobuff") then
			room:throwCard(use.card, player)
			use.to:removeOne(player)
			player:setFlags("-zhengdaobuff")
		end
	end
}
--滞后
zhihoujb     = sgs.CreateTriggerSkill {
	name = "#zhihoujb",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.CardResponded, sgs.CardAsked, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card_star = data:toCardResponse().m_card
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:isKindOf("BasicCard") then
				player:loseAllMarks("@zhihou")
			end
		end
		if event == sgs.CardResponded then
			if card_star:isKindOf("BasicCard") then
				player:loseAllMarks("@zhihou")
			end
		end
		if event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			if pattern ~= "slash" and pattern ~= "jink" and pattern ~= "peach" and pattern ~= "analeptic" then return false end
			if player:hasFlag("zhihou") then
				room:setPlayerFlag(player, "-zhihou")
				player:gainMark("@zhihou")
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			player:gainMark("@zhihou")
		end
		return false
	end
}


zhihouz = sgs.CreateTriggerSkill {
	name = "zhihouz",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd, sgs.EventPhaseStart },
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local huawan = room:findPlayerBySkillName(self:objectName())
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			if not huawan or not huawan:isAlive() then return false end
			room:setPlayerFlag(huawan, "-zhihou")
			if huawan:getMark("@zhihou") ~= 0 then
				huawan:loseAllMarks("@zhihou")
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(huawan)) do
					if (not p:isKongcheng()) and p:getHp() >= huawan:getHp() then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(huawan, targets, self:objectName(), "zhihou-invoke", true, true)
				room:broadcastSkillInvoke("zhihouz", 1)
				if target then
					local card = nil
					if target:getHandcardNum() > 1 then
						card = room:askForCard(target, ".!", "@zhihougp-give", sgs.QVariant(), sgs.Card_MethodNone)
						if not card then
							card = target:getHandcards():at(math.random(0, target:getHandcardNum() - 1))
						end
					else
						card = target:getHandcards():first()
					end
					huawan:obtainCard(card)
					room:showCard(huawan, card:getEffectiveId())
				end
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:setPlayerFlag(huawan, "zhihou")
		end
	end
}
--机枪模式
jiqiangs = sgs.CreateTriggerSkill {
	name = "jiqiangs",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		local use = data:toCardUse()
		if player:getMark("@lanyu") > 0 and use.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
			for _, p in sgs.qlist(use.to) do
				if not p:isAlive() then return end
			end
			player:loseMark("@lanyu")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			slash:setSkillName(self:objectName())
			local sc = sgs.CardUseStruct()
			for _, p in sgs.qlist(use.to) do
				sc.card = slash
				sc.from = player
				sc.to:append(p)
				room:useCard(sc)
			end
		end
	end

}
--蓝羽化闪避
lanyushanbi = sgs.CreateTriggerSkill {
	name = "lanyushanbi",
	events = { sgs.CardResponded, sgs.CardUsed },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardResponded then
			local card_star = data:toCardResponse().m_card
			if card_star:isKindOf("Jink") then
				player:gainMark("@lanyu")
				if player:getLostHp() >= 1 then
					player:gainMark("@lanyu")
				end
			end
		elseif sgs.CardUsed then
			local card = data:toCardUse().card
			if card:isKindOf("Jink") then
				player:gainMark("@lanyu")
				if player:getLostHp() >= 1 then
					player:gainMark("@lanyu")
				end
			end
		end
	end
}
--羁绊
jibanhyCard = sgs.CreateSkillCard {
	name = "jibanhyCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("jibanhy")
			and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local targets = targets[1]
		targets:drawCards(1)
		room:setPlayerFlag(source, "jibanvs")
		--[[local card = room:askForUseCard(targets, "TrickCard+^Nullification,BasicCard+^Jink,EquipCard|.|.|hand", "@jibanxuanze")
		if not card then return false end	
		local cardq = room:askForUseCard(targets, "TrickCard+^Nullification,BasicCard+^Jink,EquipCard|.|.|hand", "@jibanxuanze")
		
		if not cardq then return false end	]]
		local pattern = "|.|.|.|."
		for _, cd in sgs.qlist(targets:getHandcards()) do
			if cd:isKindOf("EquipCard") and not targets:isLocked(cd) then
				if cd:isAvailable(targets) then
					pattern = "EquipCard," .. pattern
					break
				end
			end
		end
		for _, cd in sgs.qlist(targets:getHandcards()) do
			if cd:isKindOf("Analeptic") and not targets:isLocked(cd) then
				local card = sgs.Sanguosha:cloneCard("Analeptic", cd:getSuit(), cd:getNumber())
				if card:isAvailable(targets) then
					pattern = "Analeptic," .. pattern
					break
				end
			end
		end
		for _, cd in sgs.qlist(targets:getHandcards()) do
			if cd:isKindOf("Slash") and not targets:isLocked(cd) then
				local card = sgs.Sanguosha:cloneCard("Slash", cd:getSuit(), cd:getNumber())
				if card:isAvailable(targets) then
					for _, p in sgs.qlist(room:getOtherPlayers(targets)) do
						if (not sgs.Sanguosha:isProhibited(targets, p, cd)) and targets:canSlash(p, card, true) then
							pattern = "Slash," .. pattern
							break
						end
					end
				end
				break
			end
		end
		for _, cd in sgs.qlist(targets:getHandcards()) do
			if cd:isKindOf("Peach") and not targets:isLocked(cd) then
				if cd:isAvailable(targets) then
					pattern = "Peach," .. pattern
					break
				end
			end
		end
		for _, cd in sgs.qlist(targets:getHandcards()) do
			if cd:isKindOf("TrickCard") and not targets:isLocked(cd) then
				for _, p in sgs.qlist(room:getOtherPlayers(targets)) do
					if not sgs.Sanguosha:isProhibited(targets, p, cd) then
						pattern = "TrickCard+^Nullification," .. pattern
						break
					end
				end
				break
			end
		end

		local card = room:askForUseCard(targets, pattern, "@jibanxuanze", -1)
		if card then
			room:askForUseCard(targets, pattern, "@jibanxuanze", -1)
		end
	end
}

jibanvs = sgs.CreateViewAsSkill {
	name = "jibanvs&",
	n = 0,
	view_filter = function(self, selected, to_select)
	end,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local card = jibanhyCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("jibanvs")
	end,
}

jibanhy = sgs.CreateTriggerSkill {
	name = "jibanhy",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.EventAcquireSkill },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event == sgs.GameStart then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("jibanvs") then
					room:attachSkillToPlayer(p, "jibanvs")
				end
			end
		end
	end
}
--沉默
chenmohy = sgs.CreateTriggerSkill {
	name = "chenmohy",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging, sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_Play then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:skip(phase)
			end
		end
		if event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			room:broadcastProperty(player, "role", player:getRole())
		end
	end
}
--女子道
nvzidaoCard = sgs.CreateSkillCard {
	name = "nvzidaoCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		local from = targets[1]
		if not from:hasEquip() and from:getJudgingArea():length() == 0 then return end
		local card_id = room:askForCardChosen(source, from, "ej", self:objectName())
		local card = sgs.Sanguosha:getCard(card_id)
		local place = room:getCardPlace(card_id)
		local equip_index = -1
		if place == sgs.Player_PlaceEquip then
			local equip = card:getRealCard():toEquipCard()
			equip_index = equip:location()
		end
		local tos = sgs.SPlayerList()
		local list = room:getAlivePlayers()
		for _, p in sgs.qlist(list) do
			if equip_index ~= -1 then
				if not p:getEquip(equip_index) then
					tos:append(p)
				end
			else
				if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
					tos:append(p)
				end
			end
		end
		local tag = sgs.QVariant()
		tag:setValue(from)
		room:setTag("nvzidaoTarget", tag)
		local to = room:askForPlayerChosen(source, tos, self:objectName(), "@nvzidao-to" .. card:objectName())
		if to then
			room:moveCardTo(card, from, to, place,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
		end
		room:removeTag("nvzidaoTarget")
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then
			local card_id = room:askForCardChosen(effect.from, effect.to, "h", "nvzidao")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName())
			room:obtainCard(effect.from, sgs.Sanguosha:getCard(card_id), reason, false)
		end
	end,
}
nvzidaoVS = sgs.CreateZeroCardViewAsSkill {
	name = "nvzidao",
	response_pattern = "@@nvzidao",
	view_as = function(self, cards)
		return nvzidaoCard:clone()
	end
}
nvzidao = sgs.CreateTriggerSkill {
	name = "nvzidao",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.EventPhaseEnd },
	view_as_skill = nvzidaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
			local num = use.card:getNumber()
			player:gainMark("@weixiao", num)
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			if player:getMark("@weixiao") > 25 then
				room:showAllCards(player)
			elseif player:getMark("@weixiao") == 25 then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (not p:isKongcheng()) then
						targets:append(p)
					end
				end
				local s = room:askForPlayerChosen(player, targets, self:objectName(), "nvzi-invoke", true, true)
				if not s then return false end
				local card = room:askForCardChosen(player, s, "h", "nvzidao", true)
				player:obtainCard(sgs.Sanguosha:getCard(card))
				room:askForUseCard(player, "@@nvzidao", "nvzidaoxw")
			elseif player:getMark("@weixiao") < 25 then
				player:drawCards(1)
				room:broadcastSkillInvoke("nvzidao", 1)
			end
			player:loseAllMarks("@weixiao")
		end
	end

}
--传笑
chuanxiao = sgs.CreateTriggerSkill {
	name = "chuanxiao",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:isAlive() and damage.from ~= damage.to and (not damage.from:hasSkill("weixiaojn")) and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke("chuanxiao", 1)
			room:handleAcquireDetachSkills(damage.from, "weixiaojn")
			room:addPlayerMark(damage.from, "&chuanxiao")
			return true
		end
	end
}
--微笑
weixiaojn = sgs.CreateTriggerSkill {
	name = "weixiaojn",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
			local num = use.card:getNumber()
			if use.card:getTypeId() == sgs.Card_TypeSkill then return end
			player:gainMark("@weixiao", num)
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			if player:getMark("@weixiao") == 25 then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (not p:isKongcheng()) then
						targets:append(p)
					end
				end
				local s = room:askForPlayerChosen(player, targets, self:objectName(), "nvzi-invoke", true, true)
				if not s then return false end
				local card = room:askForCardChosen(player, s, "h", "nvzidao", true)
				player:obtainCard(sgs.Sanguosha:getCard(card))
				room:handleAcquireDetachSkills(player, "-weixiaojn")
				room:setPlayerMark(player, "&chuanxiao", 0)
			end
			player:loseAllMarks("@weixiao")
		end
	end

}
--一击
yijizho = sgs.CreateTriggerSkill {
	name = "yijizho",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local x = use.from:getAttackRange()
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = x
						room:broadcastSkillInvoke("yijizho", math.random(1, 2))
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
	end
}
--风语
htms_fengyu = sgs.CreateTriggerSkill {
	name = "htms_fengyu",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local id = room:drawCard()
			local card = sgs.Sanguosha:getCard(id)
			local idx = room:drawCard()
			local cards = sgs.Sanguosha:getCard(idx)
			room:moveCardTo(card, nil, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), ""),
				true)
			room:moveCardTo(cards, nil, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), ""),
				true)
			local thread = room:getThread()
			thread:delay()
			player:addToPile("htms_fengyu", card, true)
			player:addToPile("htms_fengyu", cards, true)
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, card_id in sgs.qlist(player:getPile("htms_fengyu")) do
				room:throwCard(card_id, player)
			end
		end
	end

}

htms_fengyu_ex = sgs.CreateTriggerSkill {
	name = "#htms_fengyu_ex",
	events = { sgs.CardUsed, sgs.CardResponded },
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card_star = data:toCardResponse().m_card
		for _, f in sgs.qlist(room:findPlayersBySkillName("htms_fengyu")) do
			if event == sgs.CardUsed and f:getPile("htms_fengyu"):length() > 0 then
				for _, cd in sgs.qlist(f:getPile("htms_fengyu")) do
					if sgs.Sanguosha:getCard(cd):objectName() == use.card:objectName() then
						f:drawCards(1)
					end
				end
			end
			if event == sgs.CardResponded and f:getPile("htms_fengyu"):length() > 0 then
				for _, cd in sgs.qlist(f:getPile("htms_fengyu")) do
					if sgs.Sanguosha:getCard(cd):objectName() == card_star:objectName() then
						f:drawCards(1)
					end
				end
			end
		end
	end

}
--缎带
duandaiCard = sgs.CreateSkillCard {
	name = "duandai",
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		local flags = { "e", "h", "j" }
		if sgs.Self:hasFlag("duandai_h") or not sgs.Self:canDiscard(to_select, "h") then
			table.removeOne(flags, "h")
		end
		if sgs.Self:hasFlag("duandai_e") or not sgs.Self:canDiscard(to_select, "e") then
			table.removeOne(flags, "e")
		end
		if sgs.Self:hasFlag("duandai_j") or not sgs.Self:canDiscard(to_select, "j") then
			table.removeOne(flags, "j")
		end
		return (#flags > 0)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local flags = { "duandai_e", "duandai_h", "duandai_j" }
		if effect.from:hasFlag("duandai_h") or not effect.from:canDiscard(effect.to, "h") then
			table.removeOne(flags, "duandai_h")
		end
		if effect.from:hasFlag("duandai_e") or not effect.from:canDiscard(effect.to, "e") then
			table.removeOne(flags, "duandai_e")
		end
		if effect.from:hasFlag("duandai_j") or not effect.from:canDiscard(effect.to, "j") then
			table.removeOne(flags, "duandai_j")
		end
		if #flags == 0 then
			return
		end
		local pattern
		local dest = sgs.QVariant()
		dest:setValue(effect.to)
		local choice = room:askForChoice(effect.to, self:objectName(), table.concat(flags, "+"), dest)
		if choice == "duandai_h" then
			pattern = "h"
		elseif choice == "duandai_j" then
			pattern = "j"
		elseif choice == "duandai_e" then
			pattern = "e"
		end
		local card_id = room:askForCardChosen(effect.from, effect.to, pattern, self:objectName())
		local card = sgs.Sanguosha:getCard(card_id)
		local place = room:getCardPlace(card_id)
		room:throwCard(card, effect.to, effect.from)
		if place == sgs.Player_PlaceHand then
			room:setPlayerFlag(effect.from, "duandai_h")
		elseif place == sgs.Player_PlaceEquip then
			room:setPlayerFlag(effect.from, "duandai_e")
		elseif place == sgs.Player_PlaceJudge then
			room:setPlayerFlag(effect.from, "duandai_j")
		end

		local discard
		local prompt
		local dest = sgs.QVariant()
		dest:setValue(effect.to)
		if card:isRed() then
			prompt  = string.format("@duandai:%s", "red")
			discard = room:askForCard(effect.from, ".|red", prompt, dest, sgs.Card_MethodDiscard, effect.from, false,
				self:objectName())
		else
			prompt  = string.format("@duandai:%s", "black")
			discard = room:askForCard(effect.from, ".|black", prompt, dest, sgs.Card_MethodDiscard, effect.from, false,
				self:objectName())
		end
		if not discard then
			effect.to:drawCards(1)
		end
	end
}
duandaiVS = sgs.CreateViewAsSkill {
	name = "duandai",
	n = 0,
	enabled_at_play = function(self, player)
		return not (player:hasFlag("duandai_e") and player:hasFlag("duandai_h") and player:hasFlag("duandai_j")) --not player:hasUsed("#duandai")
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = duandaiCard:clone()
			return card
		else
			return nil
		end
	end
}
duandai = sgs.CreateTriggerSkill {
	name = "duandai",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	view_as_skill = duandaiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				local whoplayer = room:findPlayerBySkillName(self:objectName())
				if whoplayer and whoplayer:getPhase() == sgs.Player_Play then
					for _, card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						if not whoplayer:hasFlag("duandai_" .. card:getSuitString()) then
							room:setPlayerFlag(whoplayer, "duandai_" .. card:getSuitString())
						end
					end
					local x = 0
					if whoplayer:hasFlag("duandai_spade") then
						x = x + 1
					end
					if whoplayer:hasFlag("duandai_heart") then
						x = x + 1
					end
					if whoplayer:hasFlag("duandai_club") then
						x = x + 1
					end
					if whoplayer:hasFlag("duandai_diamond") then
						x = x + 1
					end
					if x == 1 then
						room:setPlayerFlag(whoplayer, "duandai_targetmod")
						room:setPlayerFlag(whoplayer, "-duandai_range")
						room:setPlayerMark(whoplayer, "&duandai+:+duandai_distance-Clear", 0)
						room:setPlayerMark(whoplayer, "&duandai+:+duandai_residue-Clear", 1)
					else
						room:setPlayerFlag(whoplayer, "duandai_range")
						room:setPlayerFlag(whoplayer, "-duandai_targetmod")
						room:setPlayerMark(whoplayer, "&duandai+:+duandai_distance-Clear", 1)
						room:setPlayerMark(whoplayer, "&duandai+:+duandai_residue-Clear", 0)
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark(self:objectName()) > 0 then
					room:handleAcquireDetachSkills(p, self:objectName())
					room:setPlayerMark(p, self:objectName(), 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
duandai_targetmod = sgs.CreateTargetModSkill {
	name = "#duandai_targetmod",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasFlag("duandai_targetmod") and player:hasSkill("duandai") then
			return 1000
		else
			return 0
		end
	end
}
duandai_range = sgs.CreateAttackRangeSkill {
	name = "#duandai_range",
	extra_func = function(self, player)
		if player:hasFlag("duandai_range") and player:hasSkill("duandai") then return 99 end
	end,
}
extension:insertRelatedSkills("duandai", "#duandai_targetmod")
extension:insertRelatedSkills("duandai", "#duandai_range")
--吐槽
tucao = sgs.CreateOneCardViewAsSkill {
	name = "tucao",
	filter_pattern = "BasicCard|.|.|.",
	view_as = function(self, first)
		local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName(self:objectName())
		return ncard
	end,
	enabled_at_nullification = function(self, player)
		return not player:hasFlag("tucaoks")
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "nullification"
	end
}


tucaoxx = sgs.CreateTriggerSkill {
	name = "#tucaoxx",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Nullification") then
			if use.card:getSkillName() == "tucao" then
				room:setPlayerFlag(player, "tucaoks")
				room:addPlayerMark(player, "&tucao-Clear")
				local choice = room:askForChoice(player, self:objectName(), "tucao:mp+tucao:qp", data)
				if choice == "tucao:mp" then
					player:drawCards(1)
				elseif choice == "tucao:qp" then
					local players = sgs.SPlayerList()
					for _, t in sgs.qlist(room:getAlivePlayers()) do
						if not (t:getJudgingArea():isEmpty() and t:getEquips():isEmpty()) then
							players:append(t)
						end
					end

					if (not players:isEmpty()) then
						local to = room:askForPlayerChosen(player, players, "tucao", "@tucao-to")
						if (to) then
							local id = room:askForCardChosen(player, to, "ej", "tucao")
							room:throwCard(id, to, player)
						end
					end
					return true
				end
			end
		end
		return false
	end
}
tucaoex = sgs.CreateTriggerSkill {
	name = "#tucaoex",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("tucaoks") then
					room:setPlayerFlag(p, "-tucaoks")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
extension:insertRelatedSkills("tucao", "#tucaoxx")
extension:insertRelatedSkills("tucao", "#tucaoex")
--王位
wangweiCard = sgs.CreateSkillCard {
	name = "wangwei",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < self:getSubcards():length()
	end,
	feasible = function(self, targets)
		return #targets <= self:getSubcards():length() and #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			target:gainMark("@wangquan")
			room:setPlayerMark(target, "wangwei" .. source:objectName(), 1)
		end
	end
}
wangwei = sgs.CreateViewAsSkill {
	name = "wangwei",
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected ~= 0 then
			return selected[1]:sameColorWith(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = wangweiCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#wangwei")
	end
}
wangquan = sgs.CreateTriggerSkill {
	name = "#wangquan",
	events = { sgs.DrawNCards, sgs.Dying, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local damage = data:toDamage()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local num = player:getMark("@wangquan")
			if player:getMark("@wangquan") ~= 0 then
				for _, hs in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("wangwei" .. hs:objectName()) > 0 then
						room:sendCompulsoryTriggerLog(hs, "luahuju", true)
						draw.num = draw.num + 1
						data:setValue(draw)
					end
				end
			end
		end
		if event == sgs.Dying then
			for _, hs in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if dying.who == hs then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("wangwei" .. hs:objectName()) > 0 then
							p:loseAllMarks("@wangquan")
							room:setPlayerMark(p, "wangwei" .. hs:objectName(), 0)
						end
					end
				end
			end
		end
		if event == sgs.Damaged and damage.damage > 1 then
			for _, hs in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to == hs then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("wangwei" .. hs:objectName()) > 0 then
							p:loseAllMarks("@wangquan")
							room:setPlayerMark(p, "wangwei" .. hs:objectName(), 0)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
extension:insertRelatedSkills("wangwei", "#wangquan")

--祈祷
listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
qidao = sgs.CreateTriggerSkill {
	name = "qidao",
	events = { sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			for _, who in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if who:getMark("qidao_lun") == 0 then
					if not room:getTag("FirstRound"):toBool() and player:getPhase() ~= sgs.Player_Draw and move.to and move.to:objectName() == player:objectName() then
						local card_ids = sgs.IntList()
						local cardlog = {}
						local drawcard = sgs.IntList()
						for _, card_id in sgs.qlist(move.card_ids) do
							if (move.to_place == sgs.Player_PlaceHand) then
								table.insert(cardlog, sgs.Sanguosha:getCard(card_id):getId())
								card_ids:append(card_id)
								--local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
								--if move.from == nil and flag == sgs.CardMoveReason_S_REASON_DRAW then
								if move.from == nil and move.from_places:contains(sgs.Player_DrawPile) then
									drawcard:append(card_id)
								end
							end
						end
						if card_ids:isEmpty() then return false end
						local choicelist = "cancel+qidao_draw"
						if player and player:canDiscard(player, "he") then
							choicelist = string.format("%s+%s", choicelist, "qidao_dis")
						end
						room:setPlayerFlag(player, "qidao_target")
						local choice = room:askForChoice(who, self:objectName(), choicelist, data)
						room:setPlayerFlag(player, "-qidao_target")
						if choice ~= "cancel" then
							room:addPlayerMark(who, self:objectName() .. "_lun")
							room:addPlayerMark(who, "&" .. self:objectName() .. "_lun")
							room:sendCompulsoryTriggerLog(who, self:objectName(), true)
							for _, id in sgs.qlist(card_ids) do
								if move.card_ids:contains(id) then
									move.from_places:removeAt(listIndexOf(move.card_ids, id))
									move.card_ids:removeOne(id)
									data:setValue(move)
								end
							end
							if not drawcard:isEmpty() then
								room:returnToTopDrawPile(drawcard)
							end
						end
						if choice == "qidao_draw" then
							if who:getLostHp() > 0 then
								room:broadcastSkillInvoke("qidao", math.random(2, 3))
								player:drawCards(who:getLostHp())
							end
						elseif choice == "qidao_dis" then
							room:broadcastSkillInvoke("qidao", 1)
							local to_throw = room:askForCardChosen(player, player, "he", self:objectName(), false,
								sgs.Card_MethodDiscard)
							room:throwCard(sgs.Sanguosha:getCard(to_throw), player, player)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

--祈愿
qiyuan_cardMAX = sgs.CreateMaxCardsSkill {
	name = "#qiyuan_cardMAX",
	extra_func = function(self, target)
		if target:getMark("@htms_qiyuan") > 0 then
			return target:getMark("@htms_qiyuan")
		end
	end
}

qiyuanCard = sgs.CreateSkillCard {
	name = "qiyuan",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "qidao_lun", 0)
		room:setPlayerMark(source, "&qidao_lun", 0)
	end
}
qiyuanVS = sgs.CreateViewAsSkill {
	name = "qiyuan",
	n = 0,
	enabled_at_play = function(self, player)
		local list = player:getAliveSiblings()
		list:append(player)
		local can_invoke = false
		for _, p in sgs.qlist(list) do
			if p:getMark("qidao_lun") > 0 then
				can_invoke = true
				break
			end
		end
		return not player:hasUsed("#qiyuan") and can_invoke
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return qiyuanCard:clone()
		end
	end,
}

qiyuan = sgs.CreateTriggerSkill {
	name = "qiyuan",
	events = { sgs.EventPhaseEnd },
	view_as_skill = qiyuanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and not player:hasUsed("#qiyuan") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMaxCards() < 4 then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "qiyuan-invoke", true, true)
			if not target then return false end
			room:broadcastSkillInvoke("qiyuan", math.random(1, 2))
			target:gainMark("@htms_qiyuan")
		end
		return false
	end
}

--雷矢
--[[LuaLeishi = sgs.CreateOneCardViewAsSkill{
	name = "LuaLeishi",
	--filter_pattern = ".|.|.|hand",
	view_filter = function(self, card)
		if card:isEquipped() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
    		local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
        	slash:addSubcard(card:getEffectiveId())
        	slash:deleteLater()
        	return slash:isAvailable(sgs.Self)
    	end
    	return true
	end,
	view_as = function(self, originalCard)
		local Leishi_card = LuaLeishiCard:clone()
		Leishi_card:addSubcard(originalCard:getId())
		return Leishi_card
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:hasFlag("LuaLeishi_used")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:hasFlag("LuaLeishi_used")
	end
}
LuaLeishiCard = sgs.CreateSkillCard{
	name = "LuaLeishi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets ~= 0 then return false end
	return sgs.Self:inMyAttackRange(to_select)
	end,
	on_validate = function(self,carduse)
		local source = carduse.from
		local target = carduse.to:first()
		local room = source:getRoom()
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if source:canSlash(target, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
			slash:setSkillName(self:objectName())
			slash:addSubcard(card:getEffectiveId())
			room:setPlayerFlag(source,"LuaLeishi_used")
			return slash
		end
	end,
}]]
LuaLeishiVS = sgs.CreateOneCardViewAsSkill {
	name = "LuaLeishi",
	response_or_use = true,
	view_filter = function(self, card)
		if card:isEquipped() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:hasFlag("LuaLeishi_used")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:hasFlag("LuaLeishi_used")
	end
}

LuaLeishi = sgs.CreateTriggerSkill {
	name = "LuaLeishi",
	global = true,
	events = { sgs.EventPhaseStart, sgs.PreCardUsed, sgs.CardResponded },
	view_as_skill = LuaLeishiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			for _, toziko in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:setPlayerFlag(toziko, "-LuaLeishi_used")
				--room:writeToConsole("回合结束")
			end
		elseif event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card:getSkillName() == self:objectName() and player:hasSkill(self:objectName()) then
				room:setPlayerFlag(player, "LuaLeishi_used")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1
}
--元兴
Luayuanxing = sgs.CreateTriggerSkill {
	name = "Luayuanxing",
	events = sgs.DamageCaused,
	global = true,
	limit_mark = "&Luayuanxing",
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if damage.to and damage.to:isAlive() and damage.from:hasSkill("Luayuanxing")
				and p:getMark("&Luayuanxing") > 0 and damage.nature == sgs.DamageStruct_Thunder and room:askForSkillInvoke(p, self:objectName(), data) then
				damage.damage = damage.damage + 1
				room:removePlayerMark(p, "Luayuanxing")
				data:setValue(damage)
				p:loseMark("&Luayuanxing")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
--怨灵
Luayuanlingcard = sgs.CreateSkillCard {
	name = "Luayuanling",
	filter = function(self, targets, to_select)
		local x = sgs.Self:getMark("Luayuanling")
		if x == 0 then x = x + 1 end
		return (#targets < x) and not to_select:isChained()
	end,
	on_effect = function(self, effect)
		local to   = effect.to
		local room = to:getRoom()
		if not to:isChained() then
			room:setPlayerProperty(to, "chained", sgs.QVariant(true))
			room:setEmotion(to, "chain")
		else
			room:setPlayerProperty(to, "chained", sgs.QVariant(false))
			room:setEmotion(to, "chain")
		end
	end,

}
LuayuanlingVS = sgs.CreateViewAsSkill {
	name = "Luayuanling",
	n = 0,
	view_filter = function()
		return false
	end,
	view_as = function()
		return Luayuanlingcard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@Luayuanling"
	end,

}
Luayuanling = sgs.CreateTriggerSkill {
	name = "Luayuanling",
	frequency = sgs.Skill_Compulsory, --Frequent, NotFrequent, Compulsory, Limited, Wake
	events = { sgs.EventPhaseEnd },
	view_as_skill = LuayuanlingVS,
	on_trigger = function(self, triggerEvent, player, data)
		if triggerEvent == sgs.EventPhaseEnd then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				local ccan = false
				local room = player:getRoom()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isChained() then ccan = true end
				end
				if not ccan then return false end
				local x = player:getMark("Luayuanling")
				if x and (x >= 0) and room:askForUseCard(player, "@@Luayuanling", "@Luayuanling", -1, sgs.Card_MethodNone) then
				end
				room:setPlayerMark(player, "Luayuanling", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
Luayuanling2 = sgs.CreateTriggerSkill {
	name = "#Luayuanling",
	frequency = sgs.Skill_Compulsory, --Frequent, NotFrequent, Compulsory, Limited, Wake
	events = { sgs.DamageDone },
	on_trigger = function(self, triggerEvent, player, data)
		if triggerEvent == sgs.DamageDone then
			local damage = data:toDamage()
			if damage.from and damage.from:getPhase() == sgs.Player_Play and damage.from:hasSkill("Luayuanling") and damage.nature == sgs.DamageStruct_Thunder then
				local room = damage.from:getRoom()
				local x = damage.from:getMark("Luayuanling")
				if (not x) or (x <= 0) then
					x = 0
				end
				room:setPlayerMark(damage.from, "Luayuanling", x + damage.damage)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--神裔
Luashenyi2 = sgs.CreateMasochismSkill {
	name = "#Luashenyi",
	on_damaged = function(self, player)
		if not player:hasSkill("Luashenyi") then return false end
		local room = player:getRoom()
		room:setPlayerFlag(player, "Luashenyi")
		-- local nextphase = change.to
		-- room:setPlayerMark(player, "qiaobianPhase", nextphase)		
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill("Luashenyi")
	end
}
Luashenyi = sgs.CreateTriggerSkill {
	name = "Luashenyi",
	events = { sgs.EventPhaseChanging },
	--frequency = sgs.Skill_Frequent , 这句话源代码没有，但是我感觉应该加上，毕竟连破一点副作用都没有
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		for _, toziko in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if toziko:hasFlag("Luashenyi") then
				room:setPlayerFlag(toziko, "-Luashenyi")
				if toziko:askForSkillInvoke("Luashenyi") then
					local room = toziko:getRoom()
					local p = room:askForPlayerChosen(toziko, room:getAlivePlayers(), self:objectName(), "Luashenyito",
						true)
					local playerdata = sgs.QVariant()
					playerdata:setValue(p)
					toziko:setTag("LuashenyiInvoke", playerdata)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
LuashenyiDo = sgs.CreateTriggerSkill {
	name = "#Luashenyi-do",
	events = { sgs.EventPhaseStart },
	priority = 1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, toziko in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if toziko:getTag("LuashenyiInvoke") then
				local target = toziko:getTag("LuashenyiInvoke"):toPlayer()
				toziko:removeTag("LuashenyiInvoke")
				if target and target:isAlive() then
					local room_0 = target:getRoom()
					local thread = room_0:getThread()
					local old_phase = target:getPhase()

					target:setPhase(sgs.Player_Play)

					room_0:broadcastProperty(target, "phase")
					if not thread:trigger(sgs.EventPhaseStart, room_0, target) then
						thread:trigger(sgs.EventPhaseProceeding, room_0, target)
					end

					thread:trigger(sgs.EventPhaseEnd, room_0, target)
					target:setPhase(old_phase)
					room_0:broadcastProperty(target, "phase")


					room_0:writeToConsole(old_phase .. "  " .. sgs.Player_NotActive)
					if toziko and toziko:hasFlag("Luashenyi") then
						room:setPlayerFlag(toziko, "-Luashenyi")
					end
				end
				return false
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--快晴
local function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

kuaiqingCard = sgs.CreateSkillCard {
	name = "luakuaiqing",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:drawCards(1)
		for _, id in sgs.qlist(self:getSubcards()) do
			local card = sgs.Sanguosha:getCard(id)
			--room:writeToConsole(firstToUpper(card:objectName()) .. "  luakuaiqing    Blocked")
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerCardLimitation(p, "use,response,discard", firstToUpper(card:objectName()), true)
				for _, c in sgs.qlist(p:getHandcards()) do
					if firstToUpper(card:objectName()) == firstToUpper(c:objectName()) then
						room:setCardTip(c:getEffectiveId(), "luakuaiqing-Clear")
					end
				end
				for i = 1, 10 do
					if (not p:getTag("luakuaiqing" .. tostring(i))) or (p:getTag("luakuaiqing" .. tostring(i)):toString() == "") then
						p:setTag("luakuaiqing" .. tostring(i), sgs.QVariant(firstToUpper(card:objectName())))
						break
					end
				end
			end
		end
	end
}

luakuaiqing = sgs.CreateViewAsSkill {
	name = "luakuaiqing",
	n = 999,
	view_filter = function(self, selected, to_select)
		return #selected <= sgs.Self:usedTimes("#luakuaiqing") and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		local y = sgs.Self:usedTimes("#luakuaiqing") + 1
		if #cards == y then
			local card = kuaiqingCard:clone()
			for _, cd in ipairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end
}
--结界
luajiejie = sgs.CreateTriggerSkill {
	name = "luajiejie",
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			if player:getPhase() ~= sgs.Player_Play then return end
			local damage = data:toDamage()
			if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel"))
				and damage.by_user and (not damage.chain) and (not damage.transfer) and damage.to:isAlive() and (not player:hasFlag("luajiejie2")) then
				local _data = sgs.QVariant()
				_data:setValue(damage.to)
				if not damage.to:isKongcheng() and room:askForSkillInvoke(player, "luajiejie", _data) then
					room:showAllCards(damage.to)

					local card = room:askForCardChosen(player, damage.to, "h", "luajiejie", true)
					player:obtainCard(sgs.Sanguosha:getCard(card))
					if player:hasFlag("luajiejie") then
						room:setPlayerFlag(player, "luajiejie2")
					end
					room:setPlayerFlag(player, "luajiejie")
				end
			end
		end
	end

}


luakuaiqing2 = sgs.CreateTriggerSkill {
	name = "#luakuaiqing",
	global = true,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for i = 1, 10 do
					if p:getTag("luakuaiqing" .. tostring(i)) and p:getTag("luakuaiqing" .. tostring(i)):toString() ~= "" then
						local str = p:getTag("luakuaiqing" .. tostring(i)):toString()
						--room:writeToConsole(p:getGeneralName() .. str .. "  luakuaiqing")
						p:getRoom():removePlayerCardLimitation(p, "use,response,discard", str .. "$1")
						p:removeTag("luakuaiqing" .. tostring(i))
					end
				end
			end
		end
	end
}

--桀骜

luajieaoCard = sgs.CreateSkillCard {
	name = "luajieao",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() and sgs.Self:canPindian(to_select) then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "luajieao", self)
		if success then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1, sgs.DamageStruct_Normal))
		else
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Diamond, 0)
			slash:deleteLater()
			slash:setSkillName("luajieao")
			room:useCard(sgs.CardUseStruct(slash, targets[1], source))
		end
	end
}
luajieao = sgs.CreateViewAsSkill {
	name = "luajieao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local daheCard = luajieaoCard:clone()
			daheCard:addSubcard(cards[1])
			return daheCard
		end
	end,
	enabled_at_play = function(self, player)
		if not player:hasUsed("#luajieao") then
			return not player:isKongcheng()
		end
		return false
	end
}
--经纶
luajinlun = sgs.CreateTriggerSkill {
	name = "luajinlun",
	events = { sgs.Damaged, sgs.EventPhaseEnd },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			if damage.to and damage.to:hasSkill(self:objectName()) then
				room:setPlayerMark(damage.to, "&luajinlun-Clear", 1)
				room:setPlayerMark(damage.to, "luajinlun-Clear", 1)
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			for _, zlz in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if zlz:getMark("luajinlun-Clear") > 0 then
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("@yishi") == 0 then
							targets:append(p)
						end
					end
					if room:askForSkillInvoke(zlz, self:objectName(), data) then
						local s = room:askForPlayerChosen(zlz, targets, self:objectName(), "luajinlun-invoke", true, true)
						if s then
							s:throwAllHandCards()
							local playerdata = sgs.QVariant()
							playerdata:setValue(s)
							zlz:setTag("luajinlun", playerdata)
							s:setTag("yishi", playerdata)
						end
						--s:gainAnExtraTurn()
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
luajinlunGive = sgs.CreateTriggerSkill {
	name = "#luajinlunGive",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, zlz in sgs.qlist(room:findPlayersBySkillName("luajinlun")) do
			if zlz:getTag("luajinlun") then
				local target = zlz:getTag("luajinlun"):toPlayer()
				zlz:removeTag("luajinlun")
				if target and target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}
--噩梦派对
empaiduicard = sgs.CreateSkillCard {
	name = "empaidui",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets < player:getLostHp() + 1
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			p:drawCards(1)
			room:setPlayerFlag(p, "empaiduibj")
			room:setPlayerCardLimitation(p, "use", "Jink", true)
			room:addPlayerMark(p, "&empaidui+to+#" .. source:objectName() .. "-Clear")
		end
	end,
}

empaiduivs = sgs.CreateViewAsSkill {
	name = "empaidui",
	n = 0,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local card = empaiduicard:clone()
		return card
	end,
	response_pattern = "@@empaidui",
}



empaidui        = sgs.CreateTriggerSkill {
	name = "empaidui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd, sgs.EventPhaseStart },
	view_as_skill = empaiduivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName(), data) then
			room:askForUseCard(player, "@@empaidui", "~empaidui")
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p, "-empaiduibj")
				room:setPlayerCardLimitation(p, "use", "-Jink", true)
			end
		end
	end

}

empaiduiex      = sgs.CreateTriggerSkill {
	name = "#empaiduiex",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local room = player:getRoom()
			local targets = sgs.SPlayerList()
			local others = room:getAlivePlayers()
			for _, p in sgs.qlist(others) do
				if p:hasFlag("empaiduibj") then
					if not use.to:contains(p) then
						targets:append(p)
						use.to:append(p)
						data:setValue(use)
					end
				end
			end
			if not targets:isEmpty() then
			end
		end
	end,

}
--扬帆突击
yftuji          = sgs.CreateTriggerSkill {
	name = "yftuji",
	events = { sgs.Damaged, sgs.EventPhaseEnd },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			--if damage.to == poi then return false end
			for _, poi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to and damage.to:objectName() ~= poi:objectName() and poi:getMark("@yishi") == 0 and poi:getMark("@yftuji") == 0 and poi:askForSkillInvoke(self:objectName(), data) then
					poi:gainMark("@yftuji")
					local damagek = sgs.DamageStruct()
					damagek.from = damage.to
					damagek.to = poi
					damagek.damage = 1
					damagek.nature = sgs.DamageStruct_Normal
					room:damage(damagek)
					room:broadcastSkillInvoke("yftuji", math.random(1, 2))
				end
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			for _, poi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if poi:getMark("@yftuji") ~= 0 and poi:getMark("@yishi") == 0 then
					poi:loseAllMarks("@yftuji")
					poi:gainMark("@yishi")
					--poi:gainAnExtraTurn()
					local playerdata = sgs.QVariant()
					playerdata:setValue(poi)
					poi:setTag("yftuji", playerdata)
					poi:setTag("yishi", playerdata)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
yftujiGive      = sgs.CreateTriggerSkill {
	name = "#yftujiGive",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, poi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if poi:getTag("yftuji") then
				local target = poi:getTag("yftuji"):toPlayer()
				poi:removeTag("yftuji")
				if target and target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}
--中二幻想（感谢P佬）
zhongerhxCard   = sgs.CreateSkillCard {
	name = "zhongerhx",
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Self:getMark("zhongerhuan") - 1
		card = sgs.Sanguosha:getCard(card)
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		--if response then return true end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end

		return card and card:targetFilter(qtargets, to_select, sgs.Self) and
		not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local card = sgs.Self:getMark("zhongerhuan") - 1
		card = sgs.Sanguosha:getCard(card)
		card:setSkillName(self:objectName())
		--if response then return true end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local card = card_use.from:getMark("zhongerhuan") - 1
		card = sgs.Sanguosha:getCard(card)
		local use_card = sgs.Sanguosha:cloneCard(card:objectName())
		use_card:addSubcard(card)
		use_card:setSkillName(self:objectName())
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card) then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(card_use.from)
		if not available then
			local dummy = sgs.Sanguosha:cloneCard("jink")
			dummy:addSubcard(card)
			dummy:deleteLater()
			card_use.from:getRoom():throwCard(dummy, nil, card_use.from)
			return nil
		end

		return use_card
	end,
}
zhongerhuanVS   = sgs.CreateZeroCardViewAsSkill {
	name = "zhongerhx",
	response_pattern = "@@zhongerhx",

	view_as = function(self)
		return zhongerhxCard:clone()
	end
}
zhongerhx       = sgs.CreateTriggerSkill {
	name = "zhongerhx",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	view_as_skill = zhongerhuanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local y = 2
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName()) and y > 0 then
			room:broadcastSkillInvoke("zhongerhx", math.random(1, 5))
			--data:setValue(0)
			local card_ids = room:getNCards(y)

			local function throw(id)
				local dummy = sgs.Sanguosha:cloneCard("jink")
				dummy:addSubcard(id)
				dummy:deleteLater()
				room:throwCard(dummy, nil, player)
			end
			while true do
				room:fillAG(card_ids)
				local id1 = room:askForAG(player, card_ids, true, self:objectName()) --S_REASON_CHANGE_EQUIP
				if id1 == -1 then
					room:clearAG()
					break
				end
				local id2 = id1 + 1
				room:writeToConsole(id1)
				card_ids:removeOne(id1)
				room:clearAG()
				room:setPlayerMark(player, "zhongerhuan", id2)
				local card = sgs.Sanguosha:getCard(id1)
				if card:targetFixed() then
					if card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse") then
						local dummy_p = sgs.Sanguosha:cloneCard("jink")
						dummy_p:deleteLater()
						dummy_p:addSubcard(id1)
						if card:isKindOf("DefensiveHorse") then
							if player:getDefensiveHorse() then
								local moveA = sgs.CardsMoveStruct()
								moveA.card_ids = sgs.IntList()
								moveA.from = player
								moveA.from_place = sgs.Player_PlaceEquip
								moveA.card_ids:append(player:getDefensiveHorse():getId())
								moveA.to = nil
								moveA.to_place = sgs.Player_DiscardPile
								moveA.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP,
									player:objectName(), "zhongerhx", "")
								room:moveCardsAtomic(moveA, true)
							end
							room:moveCardTo(dummy_p, player, player, sgs.Player_PlaceEquip,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
									self:objectName(), nil))
						else
							if player:getOffensiveHorse() then
								local moveA = sgs.CardsMoveStruct()
								moveA.card_ids = sgs.IntList()
								moveA.from = player
								moveA.from_place = sgs.Player_PlaceEquip
								moveA.card_ids:append(player:getOffensiveHorse():getId())
								moveA.to = nil
								moveA.to_place = sgs.Player_DiscardPile
								moveA.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP,
									player:objectName(), "zhongerhx", "")
								room:moveCardsAtomic(moveA, true)
							end
							room:moveCardTo(dummy_p, player, player, sgs.Player_PlaceEquip,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
									self:objectName(), nil))
						end
					else
						local dummy_0 = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
						dummy_0:addSubcard(id1)
						dummy_0:setSkillName("zhongerhx")
						dummy_0:deleteLater()
						room:clearAG()
						if player:isCardLimited(dummy_0, sgs.Card_MethodUse) or card:isKindOf("Jink") or card:isKindOf("sakura") or card:isKindOf("Nullification")
							or ((not player:isWounded()) and card:isKindOf("Peach")) then
							throw(id1)
						else
							room:useCard(sgs.CardUseStruct(dummy_0, player, sgs.SPlayerList()))
						end
					end
				else
					if (not card:isKindOf("Jink")) then
						room:askForUseCard(player, "@@zhongerhx", "@zhongerhx")
					else
						throw(id1)
					end
				end
				y = y - 1

				room:setPlayerMark(player, "zhongerhuan", 0)
				if card_ids:isEmpty() then break end
				if y == 0 then break end
				if not room:askForSkillInvoke(player, self:objectName()) then
					for _, id in sgs.qlist(card_ids) do
						throw(id)
					end
					break
				end
			end
		end
	end
}
--寒刃
hanrenzd        = sgs.CreateTriggerSkill {
	name = "hanrenzd",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if not damage.card or (not damage.card:isKindOf("Slash")) then return end
			local _data = sgs.QVariant()
			_data:setValue(damage)
			local room = player:getRoom()
			if damage.to and room:askForSkillInvoke(player, self:objectName(), _data) then
				damage.to:gainMark("@hanrenzdbj")
				if damage.to and damage.to:getWeapon() then
					room:broadcastSkillInvoke("hanrenzd", 1)
					room:throwCard(damage.to:getWeapon(), damage.to, damage.to)
				end
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				p:loseAllMarks("@hanrenzdbj")
			end
		end
	end
}
hanrenzdMaxCard = sgs.CreateMaxCardsSkill
	{
		name = "#hanrenzdMaxCard",
		extra_func = function(self, player)
			if player:getMark("@hanrenzdbj") ~= 0 then
				return -1
			else
				return 0
			end
		end,
		can_trigger = function(self, target)
			return target and target:isAlive()
		end,
	}
--冰封
bingfengzd      = sgs.CreateTriggerSkill {
	name = "bingfengzd",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.card or not (damage.card:isKindOf("BasicCard") or damage.card:isKindOf("TrickCard")) then return end
		local _data = sgs.QVariant()
		_data:setValue(damage)
		if room:askForSkillInvoke(player, self:objectName(), _data) then
			if not damage.from:isKongcheng() then
				room:broadcastSkillInvoke("bingfengzd", 1)

				local ids = damage.from:handCards()
				room:fillAG(ids, player)
				room:getThread():delay(2000)
				room:clearAG(player)
				local trick = sgs.IntList()
				for _, d in sgs.qlist(ids) do
					if sgs.Sanguosha:getCard(d):isKindOf("TrickCard") then
						room:showCard(damage.from, d)
						room:obtainCard(player, d)
						trick:append(d)
					end
				end
				room:clearAG(player)
			end
		end
	end
}
--赫子暴走
hezibz          = sgs.CreateTriggerSkill {
	name = "hezibz",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.CardFinished, sgs.ConfirmDamage, },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			if player:getPhase() == sgs.Player_Play then
				local damage = data:toDamage()
				if damage.by_user and damage.card and not damage.card:isKindOf("SkillCard") and not damage.card:hasFlag(self:objectName()) then
					room:setCardFlag(damage.card, self:objectName())
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card then
				if use.card:hasFlag(self:objectName()) then
					room:setCardFlag(use.card, "-" .. self:objectName())
					local choice = room:askForChoice(player, self:objectName(), "hezibz:shangh+hezibz:huif", data)
					if choice == "hezibz:shangh" then
						room:broadcastSkillInvoke("hezibz", math.random(1, 2))
						local targets = room:getAlivePlayers()
						room:sortByActionOrder(targets)
						for _, p in sgs.qlist(targets) do
							room:damage(sgs.DamageStruct("hezibz", player, p, 1, sgs.DamageStruct_Normal))
						end
					elseif choice == "hezibz:huif" then
						room:broadcastSkillInvoke("hezibz", 3)
						local recover = sgs.RecoverStruct(player, nil, 1)
						room:recover(player, recover)
					end
				end
			end
		end
	end
}
--杀意浸染
shayiqr         = sgs.CreateTriggerSkill {
	name = "shayiqr",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.CardUsed, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			room:broadcastSkillInvoke("shayiqr", math.random(1, 3))
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			local num = 2 - (player:getMark("shayicard") + player:getMark("shayish"))
			if num == 2 then room:loseMaxHp(player) end
			if num == 0 then room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1)) end
			if num > 0 then
				room:loseHp(player, num)
			end
			player:setMark("shayicard", 0)
			player:setMark("shayihf", 0)
			player:setMark("shayish", 0)
		end
		if player:getPhase() ~= sgs.Player_Play then return end
		if event == sgs.Damage and player:getMark("shayish") == 0 then
			room:addPlayerMark(player, "shayish", 1)
			room:addPlayerMark(player, "&shayish-Clear", 1)
		end
		if event == sgs.CardUsed and (not use.card:isKindOf("EquipCard") and not use.card:isKindOf("SkillCard")) and player:getMark("shayicard") == 0 then
			room:addPlayerMark(player, "shayicard", 1)
			room:addPlayerMark(player, "&shayicard-Clear", 1)
		end
	end
}
--断裁
duancai         = sgs.CreateTriggerSkill {
	name = "duancai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local lt = room:findPlayerBySkillName(self:objectName())
		if not lt or not lt:isAlive() then return end
		if not use.card then return end
		if use.card:getTypeId() == sgs.Card_TypeSkill then return end
		if event == sgs.CardUsed and use.card:getNumber() > 7 and use.from ~= lt then
			if room:askForCard(lt, ".|.|1~7|hand", "@duancai", data, self:objectName()) then
				room:damage(sgs.DamageStruct("duancai", lt, player, 1, sgs.DamageStruct_Normal))
			end
		end
		if event == sgs.CardResponded then
			local uses = data:toCardResponse()
			if not uses.m_card then return end
			if not uses.m_isUse then return end
			if uses.m_card:getNumber() > 7 and uses.m_card:isKindOf("Jink") then
				if room:askForCard(lt, ".|.|1~7|hand", "@duancai", data, self:objectName()) then
					room:damage(sgs.DamageStruct("duancai", lt, player, 1, sgs.DamageStruct_Normal))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
--迷迭
midie           = sgs.CreateTriggerSkill {
	name = "midie",
	events = { sgs.AskForPeaches },
	global = true,
	limit_mark = "@midie",
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:loseMark("@midie")
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
				local maxhp = player:getMaxHp()
				local hp = math.min(3, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				room:handleAcquireDetachSkills(player, "-duancai")
				room:handleAcquireDetachSkills(player, "duancaiex")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("@midie") > 0
	end
}
duancaiex       = sgs.CreateTriggerSkill {
	name = "duancaiex",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
			local lt = room:findPlayerBySkillName(self:objectName())
			if not lt or lt:getPhase() ~= sgs.Player_Play then return end
			local card_ids = sgs.IntList()
			for _, card_id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(card_id):getNumber() < 7 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:objectName() == move.from:objectName() and room:askForCard(lt, ".|.|8~13|hand", "@duancaiex", data, self:objectName()) then
							room:damage(sgs.DamageStruct("duancaiex", player, p, 1, sgs.DamageStruct_Normal))
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and (not target:hasSkill(self:objectName()))
	end,
}
--同舟
tongzhouqg      = sgs.CreateTriggerSkill {
	name = "tongzhouqg",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if room:askForSkillInvoke(player, "tongzhouqg", data) then
				local n = room:alivePlayerCount()
				draw.num = draw.num + n
				room:setPlayerFlag(player, "tongzhouqg")
				data:setValue(draw)
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw and player:hasFlag("tongzhouqg") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (not p:isKongcheng()) then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				local card = nil
				if player:getHandcardNum() > 1 then
					local dest = sgs.QVariant()
					dest:setValue(p)
					card = room:askForCard(player, ".!", "@tongzhouqg:" .. p:objectName(), dest, sgs.Card_MethodNone)
					if not card then
						card = player:getHandcards():at(math.random(0, player:getHandcardNum() - 1))
					end
				else
					card = player:getHandcards():first()
				end
				p:obtainCard(card)
				room:showCard(p, card:getEffectiveId())
			end

			room:setPlayerFlag(player, "-tongzhouqg")
		end
	end
}
--解思
qgjiesiCard     = sgs.CreateSkillCard {
	name = "qgjiesi",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark(self:objectName())
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets <= sgs.Self:getMark(self:objectName())
	end,
	on_use = function(self, room, source, targets)
		local sum = 0
		for _, p in pairs(targets) do
			sum = sum + p:getHp()
		end
		local choices = {}
		if #targets <= source:getMark(self:objectName()) then
			table.insert(choices, "qgjiesi1")
		end
		if sum == source:getMark(self:objectName()) then
			table.insert(choices, "qgjiesi2")
		end
		room:addPlayerMark(source, self:objectName())
		if source:getMark(self:objectName()) > 0 then
			for _, p in pairs(targets) do
				if source:getMark("qgjiesiew") ~= 0 then
					room:askForDiscard(p, self:objectName(), 2, 2, false, true)
				else
					room:askForDiscard(p, self:objectName(), 1, 1, false, true)
				end
			end

			room:removePlayerMark(source, self:objectName())
		end
	end
}
qgjiesiVS       = sgs.CreateZeroCardViewAsSkill {
	name = "qgjiesi",
	view_as = function(self, cards)
		return qgjiesiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@qgjiesi")
	end
}
qgjiesi         = sgs.CreateTriggerSkill {
	name = "qgjiesi",
	view_as_skill = qgjiesiVS,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.HpRecover },
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName()
					and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
					and player:getPhase() == sgs.Player_Discard
				then
					room:addPlayerMark(player, self:objectName(), move.card_ids:length())
					room:addPlayerMark(player, "&" .. self:objectName(), move.card_ids:length())
				end
			else
				if player:getMark(self:objectName()) > 0 then
					room:askForUseCard(player, "@@qgjiesi", "@qgjiesi", -1, sgs.Card_MethodUse)
					room:setPlayerMark(player, self:objectName(), 0)
					room:setPlayerMark(player, "&" .. self:objectName(), 0)
				end
			end
		end
		if player:getPhase() ~= sgs.Player_Play then return end
		if event == sgs.HpRecover and player:getMark("qgjiesiew") == 0 then
			room:addPlayerMark(player, "qgjiesiew", 1)
		end
		return false
	end
}
--医诊
zjyizhenCard    = sgs.CreateSkillCard {
	name = "zjyizhenCard",
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:isWounded()) and (to_select:getLostHp() == self:subcardsLength()) and
		(to_select:isWounded()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		local room = dest:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(dest, recover)
	end
}
zjyizhen        = sgs.CreateViewAsSkill {
	name = "zjyizhen",
	n = 999,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		local zy = zjyizhenCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				zy:addSubcard(c)
			end
		end
		return zy
	end,
}
--魔术戏法
zjmoshuxif      = sgs.CreateTriggerSkill {
	name = "zjmoshuxif",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardAsked },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			if pattern ~= "jink" then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(1)
				room:broadcastSkillInvoke("zjmoshuxif", math.random(1, 2))
				if player:canDiscard(player, "he") then
					local card = room:askForCard(player, "..!", "@zjmoshuxif", data, self:objectName())
					if card:isKindOf("EquipCard") or card:isNDTrick() then
						local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
						jink:setSkillName(self:objectName())
						room:provide(jink)
						return true
					end
				end
			end
		end
	end
}

--若是
zjruoshi        = sgs.CreateTriggerSkill {
	name = "zjruoshi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke("zjruoshi", 1)
					local choice = room:askForChoice(player, self:objectName(), "zjruoshi:red+zjruoshi:black", data)
					if choice == "zjruoshi:red" then
						room:addPlayerMark(player, "zjruoshired", 1)
					elseif choice == "zjruoshi:black" then
						room:addPlayerMark(player, "zjruoshiblack", 1)
					end
					while player:askForSkillInvoke(self:objectName()) do
						local judge = sgs.JudgeStruct()
						if player:getMark("zjruoshired") > 0 then
							judge.pattern = ".|red"
						end
						if player:getMark("zjruoshiblack") > 0 then
							judge.pattern = ".|black"
						end
						judge.good = true
						judge.reason = self:objectName()
						judge.who = player
						judge.time_consuming = true
						room:judge(judge)
						if judge:isGood() then
							player:obtainCard(judge.card)
						else
							player:setMark("zjruoshiblack", 0)
							player:setMark("zjruoshired", 0)
							break
						end
					end
				end
			end
		end
		return false
	end
}
--傲娇
zjaojiaolCard   = sgs.CreateSkillCard {
	name = "zjaojiaol",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if source:canDiscard(source, "h") then
			local choice = room:askForChoice(target, self:objectName(), "zjaojiaol:red+zjaojiaol:black")
			if choice == "zjaojiaol:red" then
				room:addPlayerMark(source, "zjaojiaolred", 1)
			elseif choice == "zjaojiaol:black" then
				room:addPlayerMark(source, "zjaojiaolblack", 1)
			end
			local id = room:askForCardChosen(target, source, "h!", "zjaojiaol", true)
			local cd = sgs.Sanguosha:getCard(id)
			room:throwCard(id, source, target)
			if cd:isRed() then
				if source:getMark("zjaojiaolred") == 1 then
					local recover = sgs.RecoverStruct()
					recover.card = self
					recover.who = source
					room:recover(target, recover)
				end
			elseif cd:isBlack() then
				if source:getMark("zjaojiaolblack") == 1 then
					target:drawCards(2)
				end
			end
			source:setMark("zjaojiaolred", 0)
			source:setMark("zjaojiaolblack", 0)
		end
	end,
}
zjaojiaol       = sgs.CreateViewAsSkill {
	name = "zjaojiaol",
	n = 0,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		local card = zjaojiaolCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zjaojiaol")
	end,
}

--千金 （感谢时雨）
qianjinzj       = sgs.CreateTriggerSkill {
	name = "qianjinzj",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			if player:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke("qianjinzj", 1)
				local drawcardnum = 0
				for _, target in sgs.qlist(room:getOtherPlayers(player)) do
					if (drawcardnum < target:getHandcardNum()) then
						drawcardnum = target:getHandcardNum()
					end
				end
				if player:getHandcardNum() < drawcardnum and room:askForSkillInvoke(player, self:objectName(), data) then
					player:drawCards(drawcardnum - player:getHandcardNum())
				end
			end
		end
	end
}

--彆扭
bieniu          = sgs.CreateTriggerSkill {
	name = "bieniu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			room:removePlayerCardLimitation(player, "use", ".|black")
			room:removePlayerCardLimitation(player, "use", ".|red")
			room:removePlayerCardLimitation(player, "use", ".|no_suit")
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
				if card:isRed() then
					room:removePlayerCardLimitation(player, "use", ".|black")
					room:removePlayerCardLimitation(player, "use", ".|no_suit")
					room:setPlayerCardLimitation(player, "use", ".|red", false)
				elseif card:isBlack() then
					room:removePlayerCardLimitation(player, "use", ".|red")
					room:removePlayerCardLimitation(player, "use", ".|no_suit")
					room:setPlayerCardLimitation(player, "use", ".|black", false)
				else
					room:removePlayerCardLimitation(player, "use", ".|red")
					room:removePlayerCardLimitation(player, "use", ".|black")
					room:setPlayerCardLimitation(player, "use", ".|no_suit", false)
				end
			end
		end
		return false
	end
}


--谱奏
puzou = sgs.CreateTriggerSkill {
	name = "puzou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				local oldtag = room:getTag("puzoucard"):toString():split("+")
				local totag = {}
				for _, is in ipairs(oldtag) do
					table.insert(totag, tonumber(is))
				end
				for _, card_id in sgs.qlist(move.card_ids) do
					table.insert(totag, card_id)
				end
				room:setTag("puzoucard", sgs.QVariant(table.concat(totag, "+")))
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				local tag = room:getTag("puzoucard"):toString():split("+")
				room:removeTag("puzoucard")
				if #tag == 0 then return false end
				local suits = {}
				local color = {}
				local red, black = 0, 0
				for _, is in ipairs(tag) do
					if sgs.Sanguosha:getCard(is):isRed() then
						red = red + 1
					elseif sgs.Sanguosha:getCard(is):isBlack() then
						black = black + 1
					end
					if not table.contains(suits, sgs.Sanguosha:getCard(is):getSuit()) then
						table.insert(suits, sgs.Sanguosha:getCard(is):getSuit())
					end
				end
				if (#suits == #tag) or (red == #tag) or (black == #tag) then
					local choicelist = "cancel+puzou_losehp"
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isWounded() then
							choicelist = string.format("%s+%s", choicelist, "puzou_heal")
							break
						end
					end
					local choice = room:askForChoice(player, self:objectName(), choicelist)
					if choice == "puzou_losehp" then
						room:broadcastSkillInvoke("puzou", 1)
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							room:loseHp(p, 1)
						end
					elseif choice == "puzou_heal" then
						room:broadcastSkillInvoke("puzou", 2)
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(p, recover)
						end
					end
				end
			end
		end
	end
}
--威仪
htms_weiyi = sgs.CreateTriggerSkill {
	name = "htms_weiyi",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local num = damage.damage
		if damage.from then
			local choice = room:askForChoice(player, self:objectName(), "htms_weiyi:qp+htms_weiyi:sh+cancel", data)
			if choice == "htms_weiyi:qp" then
				room:broadcastSkillInvoke("htms_weiyi", math.random(1, 2))
				if player:getMark("@wysh") ~= 0 then
					local num = damage.damage + 1
					player:loseAllMarks("@wysh")
					player:loseAllMarks("@wyqp")
					room:askForDiscard(damage.from, self:objectName(), num, num, false, true)
				end
				if player:getMark("@wysh") == 0 then
					room:askForDiscard(damage.from, self:objectName(), num, num, false, true)
				end
				player:loseAllMarks("@wysh")
				player:loseAllMarks("@wyqp")
				player:gainMark("@wyqp")
			elseif choice == "htms_weiyi:sh" then
				room:broadcastSkillInvoke("htms_weiyi", math.random(1, 2))
				if player:getMark("@wyqp") == 0 then
					room:damage(sgs.DamageStruct(self:objectName(), player, damage.from, (num - 1)))
				end
				if player:getMark("@wyqp") ~= 0 then
					player:loseAllMarks("@wysh")
					player:loseAllMarks("@wyqp")
					room:damage(sgs.DamageStruct(self:objectName(), player, damage.from, (num)))
				end
				player:loseAllMarks("@wysh")
				player:loseAllMarks("@wyqp")
				player:gainMark("@wysh")
			end
		end
	end,

}

--名门
mingmendiaCard = sgs.CreateSkillCard {
	name = "mingmendiaCard",
	target_fixed = false,
	will_throw = false,
	skill_name = "mingmendia",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName() and (not to_select:isAllNude())
	end,
	on_use = function(self, room, source, targets)
		local id = room:askForCardChosen(source, targets[1], "he", "mingmendia")
		if targets[2] then
			local ida = room:askForCardChosen(source, targets[2], "he", "mingmendia")
			room:obtainCard(source, ida, false)
		end
		room:obtainCard(source, id, false)
		local card = room:askForCard(source, "..!", "@mingmendiaa:" .. targets[1]:objectName(), sgs.QVariant(),
			sgs.Card_MethodNone)
		targets[1]:obtainCard(card)
		room:showCard(targets[1], card:getEffectiveId())
		if targets[2] then
			local carda = room:askForCard(source, "..!", "@mingmendib:" .. targets[2]:objectName(), sgs.QVariant(),
				sgs.Card_MethodNone)
			targets[2]:obtainCard(carda)
			room:showCard(targets[2], carda:getEffectiveId())
			if card:getNumber() == carda:getNumber() then
				room:recover(source, sgs.RecoverStruct(source))
			end
			if card:getSuit() ~= carda:getSuit() then
				room:loseHp(player)
			end
		end
	end
}

mingmendiaVS = sgs.CreateZeroCardViewAsSkill {
	name = "mingmendia",
	view_as = function(self, cards)
		return mingmendiaCard:clone()
	end,

	enabled_at_play = function(self, player)
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@mingmendia"
	end
}

mingmendia = sgs.CreateTriggerSkill {
	name = "mingmendia",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = mingmendiaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:askForUseCard(player, "@@mingmendia", "@mingmendia")
		end
	end

}
yishibuff = sgs.CreateTriggerSkill {
	name = "yishibuff",
	global = true,
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:clearPlayerCardLimitation(p, true)
				end
			end
			if data:toPhaseChange().to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@yishi", 0)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:clearPlayerCardLimitation(p, true)
				end
			end
		elseif event == sgs.EventPhaseStart then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p and p:isAlive() and p:getPhase() == sgs.Player_Start and p:getTag("yishi"):toPlayer() then
					p:removeTag("yishi")
					room:setPlayerMark(p, "@yishi", 1)
				end
			end
		end
	end

}
--挑拨
tiaoboCard = sgs.CreateSkillCard {
	name = "luatiaobo",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "luatiaobo", self)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if success then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if targets[1]:canSlash(p, slash, false) then players:append(p) end
			end
			if players:length() > 0 then
				local to = room:askForPlayerChosen(source, players, self:objectName(), "luatiaobo", false, true)
				room:setCardFlag(slash, "seija")
				room:useCard(sgs.CardUseStruct(slash, targets[1], to))
			end
		elseif targets[1]:canSlash(source, slash, false) then
			local choice = room:askForChoice(targets[1], "luatiaobo", "yes+no")
			if choice == "yes" then
				room:setCardFlag(slash, "seija")
				room:useCard(sgs.CardUseStruct(slash, targets[1], source))
			end
		end
	end
}
luatiaobo = sgs.CreateViewAsSkill {
	name = "luatiaobo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local daheCard = tiaoboCard:clone()
			daheCard:addSubcard(cards[1])
			return daheCard
		end
	end,
	enabled_at_play = function(self, player)
		if not player:hasUsed("#luatiaobo") then
			return not player:isKongcheng()
		end
		return false
	end
}
--逆转
luanizhuan = sgs.CreateTriggerSkill {
	name = "luanizhuan",
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.from
			and use.to:contains(player) and player:canDiscard(player, "he") and room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(1)
			if player:getHandcardNum() > use.from:getHandcardNum() then
				use.to = sgs.SPlayerList()
				data:setValue(use)
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				if not use.from:isProhibited(player, duel)
					and not use.from:isCardLimited(duel, sgs.Card_MethodUse) then
					room:setCardFlag(duel, "seija")
					room:useCard(sgs.CardUseStruct(duel, use.from, player))
				end
			end
		end
	end
}
--眼光
yanguangCard = sgs.CreateSkillCard {
	name = "luanyanguang",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("luanyanguang")
		slash:deleteLater()
		return (#targets < 1) and slash:targetFilter(targets_list, to_select, sgs.Self) and
		sgs.Self:canSlash(to_select, false)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:loseHp(effect.from)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("luanyanguang")
		effect.from:getRoom():useCard(sgs.CardUseStruct(slash, effect.from, effect.to))
	end
}

luanyanguang = sgs.CreateZeroCardViewAsSkill {
	name = "luanyanguang",
	view_as = function()
		local suiyuecard = yanguangCard:clone()
		suiyuecard:setSkillName("luanyanguang")
		return suiyuecard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#luanyanguang")) and player:getHp() > 0
	end
}
--辘首
lualushou = sgs.CreateTriggerSkill {
	name = "lualushou",
	events = { sgs.PreCardUsed, sgs.TargetConfirmed, sgs.Damage, sgs.PreDamageDone },
	on_trigger = function(self, event, player, data)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local room = player:getRoom()
			if use.from:objectName() == player:objectName() and (use.card:isKindOf("Slash")) and use.from:hasSkill("lualushou")
				and room:askForCard(player, "TrickCard", "lualushouB", data, sgs.Card_MethodDiscard) then
				player:drawCards(1)
				--if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
				local available_targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
					if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
						available_targets:append(p)
					end
				end
				local extra = nil
				local Carddata2 = sgs.QVariant() -- ai用
				Carddata2:setValue(use.card)
				extra = room:askForPlayerChosen(player, available_targets, "lualushou", "lualushou", true, true)
				if extra then
					use.to:append(extra)
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
				return false
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from then return false end
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local room = player:getRoom()
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			if room:askForCard(player, "EquipCard", "lualushouC", data, sgs.Card_MethodDiscard) then room:setPlayerFlag(
				player, "lualushou") end
			if room:askForCard(player, "BasicCard", "lualushouA", data, sgs.Card_MethodDiscard) and not use.to:isEmpty() then
				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					jink_table[index] = 0
					index = index + 1
				end
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		end
	end
}
lualushou2 = sgs.CreateTriggerSkill {
	name = "#lualushou",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.DamageDone },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.DamageDone) and damage.from and damage.from:hasSkill("lualushou") and damage.from:isAlive() then
			local weiyan = damage.from
			weiyan:setTag("invokeLuaKuanggu", sgs.QVariant(weiyan:hasFlag("lualushou")))
		elseif (event == sgs.Damage) and player:hasSkill("lualushou") and player:isAlive() then
			local invoke = player:getTag("invokeLuaKuanggu"):toBool()
			player:setTag("invokeLuaKuanggu", sgs.QVariant(false))
			if invoke and player:isWounded() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = damage.damage
				room:recover(player, recover)
			end
		end
		return false
	end
}
--花葬
huazang = sgs.CreateTriggerSkill {
	name = "huazang",
	events = { sgs.TargetConfirmed, sgs.CardFinished, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirmed then
			if use.card:isKindOf("Slash") then
				if player:objectName() ~= use.from:objectName() then return false end
				if player:askForSkillInvoke(self:objectName(), data) then
					local slash = use.card
					for _, p in sgs.qlist(use.to) do
						p:turnOver()
						p:drawCards(p:getLostHp())
						local mark = string.format("%s%s", self:objectName(), slash:toString())
						local count = p:getMark(mark) + 1
						room:setPlayerMark(p, mark, count)
					end
				end
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			local slash = damage.card
			if damage.card and damage.card:isKindOf("Slash") then
				local mark = string.format("%s%s", self:objectName(), slash:toString())
				if damage.to:getMark(mark) > 0 then
					damage.to:turnOver()
					local count = damage.to:getMark(mark) - 1
					room:setPlayerMark(damage.to, mark, count)
				end
			end
			if event == sgs.CardFinished then
				if use.card:isKindOf("Slash") then
					local players = room:getAllPlayers()
					for _, p in sgs.qlist(players) do
						local mark = string.format("%s%s", self:objectName(), use.card:toString())
						room:setPlayerMark(p, mark, 0)
					end
				end
			end
		end
	end
}
--直斥
zchizeCard = sgs.CreateSkillCard {
	name = "zchizeCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng() and not sgs.Self:isKongcheng()) and
		to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local success = source:pindian(target, "zchize", self)
		if success then
			if target:getEquips():length() > 0 or target:getJudgingArea():length() > 0 then
				local card_id = room:askForCardChosen(source, target, "ej", "zchize")
				room:throwCard(card_id, target, source)
			end
		else
			room:setPlayerFlag(source, "zchize")
			room:throwEvent(sgs.TurnBroken)
		end
	end
}
zchize = sgs.CreateViewAsSkill {
	name = "zchize",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local zhichiCard = zchizeCard:clone()
			zhichiCard:addSubcard(cards[1])
			return zhichiCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zchizeCard")
	end
}
--高岭
gaoling = sgs.CreateTriggerSkill {
	name = "gaoling",
	events = { sgs.CardEffected },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.to:objectName() == effect.from:objectName() then return false end
		if effect.card:isNDTrick() then
			if effect.to:hasSkill(self:objectName()) and effect.from and effect.to:getHandcardNum() >= effect.from:getHandcardNum() and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke("gaoling", math.random(1, 2))
				return true
			end
		end
		return false
	end,

}
--回档
huidang = sgs.CreateTriggerSkill {
	name = "huidang",
	events = { sgs.GameOverJudge, sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameOverJudge then
			local subaru = data:toDeath().who
			if subaru:hasSkill(self:objectName()) and subaru == player then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getEquips():length() > 0 then
						local id = room:askForCardChosen(p, p, "e", self:objectName())
						room:throwCard(id, p, p)
					end
				end
			end
			if subaru:isAlive() then return true end
		end
		if event == sgs.CardsMoveOneTime then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getEquips():length() > 0 then
					return false
				end
			end
			local subaru
			for _, p in sgs.qlist(room:getPlayers()) do
				if p:hasSkill(self:objectName()) and p:isDead() then
					subaru = p
				end
			end
			if subaru and player:isAlive() then
				room:broadcastSkillInvoke(self:objectName())
				for _, p in sgs.qlist(room:getPlayers()) do
					if p:isDead() then
						room:revivePlayer(p)
					end
					if p:getRole() == "lord" then
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getGeneral():getMaxHp() + 1))
						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getGeneral():getMaxHp() + 1))
					else
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getGeneral():getMaxHp()))
						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getGeneral():getMaxHp()))
					end
					for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
						if skill:getFrequency() == sgs.Skill_Wake then
							room:setPlayerMark(p, skill, 0)
							room:setPlayerMark(p, "@waked", 0)
						end
					end
					for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
						if not p:hasSkill(skill:objectName()) then room:acquireSkill(p, skill:objectName()) end
						if skill:getFrequency() == sgs.Skill_Limited then
							if p:getMark(skill:getLimitMark()) == 0 then p:gainMark(skill:getLimitMark()) end
						end
					end
					
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--拯救
function getZhengjiuDest(player)
	local room = player:getRoom()
	local name = room:getTag(player:objectName() .. "zhengjiu"):toString()
	local dest
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:objectName() == name then dest = p end
	end
	return dest
end

zhengjiu = sgs.CreateTriggerSkill {
	name = "zhengjiu",
	events = { sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.CardFinished },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return false end
			local dest = getZhengjiuDest(player)
			if dest then
				room:setPlayerMark(dest, "&zhengjiu+to+#" .. player:objectName(), 0)
			end
			room:setTag(player:objectName() .. "zhengjiu", sgs.QVariant())
			if player:hasSkill(self:objectName()) and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				room:setTag(player:objectName() .. "zhengjiu", sgs.QVariant(dest:objectName()))
				local players = sgs.SPlayerList()
				players:append(dest)
				players:append(player)
				room:setPlayerMark(dest, "&zhengjiu+to+#" .. player:objectName(), 1, players)
			end
		end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:isAlive() and (use.card:isKindOf("Slash") or use.card:inherits("SingleTargetTrick")) then
				local dest = getZhengjiuDest(player)
				if dest and use.to:contains(dest) and player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName(), math.random(2, 3))
					room:setPlayerFlag(player, "zhengjiu_active")
					room:setTag(player:objectName() .. "zhengjiuhp", sgs.QVariant(dest:getHp()))
					local ids = room:getNCards(3)
					room:fillAG(ids, player)
					local id = room:askForAG(player, ids, false, self:objectName())
					ids:removeOne(id)
					room:obtainCard(dest, id, false)
					if not use.card:isKindOf("AmazingGrace") then room:clearAG(player) end
					room:askForGuanxing(player, ids, sgs.Room_GuanxingUpOnly)
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("zhengjiu_active") then
					room:setPlayerFlag(p, "-zhengjiu_active")
					local n = room:getTag(p:objectName() .. "zhengjiuhp"):toInt()
					local dest = getZhengjiuDest(p)
					room:setTag(p:objectName() .. "zhengjiuhp", sgs.QVariant())
					if dest and dest:getHp() < n then
						room:loseHp(p)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--魔力外放
molwfcard = sgs.CreateSkillCard {
	name = "molwf",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() == sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		source:gainMark("@mol")
		room:setPlayerFlag(source, "moli")
		room:addPlayerMark(source, "&molwf-Clear")
		if source:getMark("@mol") >= 5 then
			source:loseAllMarks("@mol")
			if source:getMark("@shisheng") == 0 then
				-- source:gainMark("@shisheng")
				room:addPlayerMark(source, "@shisheng")
			end
		end
	end,

}
molwf = sgs.CreateViewAsSkill {
	name = "molwf",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return end
		local vs_card = molwfcard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#molwf")
	end,
}
molisf = sgs.CreateTriggerSkill {
	name = "#molisf",
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local reason = damage.card
		if reason and reason:isKindOf("Slash") and player:hasFlag("moli") then
			local msg = sgs.LogMessage()
			msg.type = "#molw"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = damage.damage
			msg.arg2 = damage.damage + 1
			room:sendLog(msg)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
}
extension:insertRelatedSkills("molwf", "#molisf")
--誓胜
html_shishengCard = sgs.CreateSkillCard {
	name = "html_shishengCard",
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		--source:loseAllMarks("@shisheng")
		room:setPlayerMark(source, "@shisheng", 0)
		room:addPlayerMark(targets[1], "shishengsw", 1)
		room:damage(sgs.DamageStruct("html_shisheng", source, targets[1], 1, sgs.DamageStruct_Normal))
		targets[1]:setMark("shishengsw", 0)
	end,
}
html_shishengVS = sgs.CreateZeroCardViewAsSkill {
	name = "html_shisheng",
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		return html_shishengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@shisheng") >= 1
	end
}
html_shishengsw = sgs.CreateTriggerSkill {
	name = "#html_shishengsw",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:getMark("shishengsw") == 1 then
			for _, hc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if death.damage and death.damage.from and death.damage.from:objectName() == hc:objectName() then
					for _, p in sgs.qlist(room:getOtherPlayers(hc)) do
						room:damage(sgs.DamageStruct("hezibz", player, p, 1, sgs.DamageStruct_Normal))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getMark("shishengsw") == 1
	end
}
html_shisheng = sgs.CreateTriggerSkill {
	name = "html_shisheng",
	frequency = sgs.Skill_Limited,
	view_as_skill = html_shishengVS,
	limit_mark = "@shisheng",
	on_trigger = function()
	end
}
--邀战
ujyaozhanCard = sgs.CreateSkillCard {
	name = "ujyaozhanCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			if string.find(effect.to:getGeneralName(), "Kirito") or string.find(effect.to:getGeneral2Name(), "Kirito") then
				room:broadcastSkillInvoke("ujyaozhan", 6)
			elseif string.find(effect.to:getGeneralName(), "jsyasina") or string.find(effect.to:getGeneral2Name(), "jsyasina") or string.find(effect.to:getGeneralName(), "yasina") or string.find(effect.to:getGeneral2Name(), "yasina") then
				room:broadcastSkillInvoke("ujyaozhan", math.random(4, 5))
			else
				room:broadcastSkillInvoke("ujyaozhan", math.random(1, 3))
			end
			room:setPlayerMark(effect.from, "ujyaozhan", 1)
			room:setPlayerMark(effect.to, "ujyaozhan", 1)
			room:setPlayerMark(effect.to, "ujyaozhan" .. effect.from:objectName(), 1)
			room:setPlayerMark(effect.to, "&ujyaozhan+to+#" .. effect.from:objectName(), 1)
			room:setFixedDistance(effect.from, effect.to, 1)
			room:setFixedDistance(effect.to, effect.from, 1)
			use_slash = room:askForUseSlashTo(effect.to, effect.from, "@ujyaozhan")
		end
	end
}
ujyaozhan = sgs.CreateViewAsSkill {
	name = "ujyaozhan",
	n = 0,
	view_as = function()
		return ujyaozhanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ujyaozhanCard")
	end
}
ujyaozhanex = sgs.CreateTriggerSkill {
	name = "#ujyaozhanex",
	frequency = sgs.Skill_Compulsory,
	events = sgs.EventPhaseStart,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("ujyaozhan") > 0 then
			room:removePlayerMark(player, "ujyaozhan", 1)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("ujyaozhan") > 0 and p:getMark("ujyaozhan" .. player:objectName()) > 0 then
					room:removeFixedDistance(p, player, 1)
					room:removeFixedDistance(player, p, 1)
					player:loseAllMarks("ujyaozhan")
					p:loseAllMarks("ujyaozhan")
					room:setPlayerMark(p, "ujyaozhan" .. player:objectName(), 0)
					room:setPlayerMark(p, "&ujyaozhan+to+#" .. player:objectName(), 0)
				end
			end
		end
		if player:getPhase() == sgs.Player_Start then
			player:loseAllMarks("ujlianjig")
		end
	end
}

--连击
ujlianji = sgs.CreateTriggerSkill {
	name = "ujlianji",
	events = { sgs.CardFinished },
	priority = 5,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			--player:gainMark("@shengyong")
			room:broadcastSkillInvoke("ujlianji", math.random(1, 2))
			local card = room:askForUseCard(player, "Slash", "@ujlianji")
			if not card then return false end
		end
	end
}
ujlianjig = sgs.CreateTriggerSkill {
	name = "ujlianjig",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") and player:getPhase() ~= sgs.Player_Play or player:getMark("ujlianjig") > 0 then return false end
			room:broadcastSkillInvoke("ujlianji", math.random(2, 4))
			--local card = room:askForUseCard(player, "TrickCard+^Nullification,BasicCard+^Jink,EquipCard|.|.|hand", "@ujlianjig")		
			--if not card then return false end	
			local pattern = "|.|.|.|."
			for _, cd in sgs.qlist(player:getHandcards()) do
				if cd:isKindOf("EquipCard") and not player:isLocked(cd) then
					if cd:isAvailable(player) then
						pattern = "EquipCard," .. pattern
						break
					end
				end
			end
			for _, cd in sgs.qlist(player:getHandcards()) do
				if cd:isKindOf("Analeptic") and not player:isLocked(cd) then
					local card = sgs.Sanguosha:cloneCard("Analeptic", cd:getSuit(), cd:getNumber())
					if card:isAvailable(player) then
						pattern = "Analeptic," .. pattern
						break
					end
				end
			end
			for _, cd in sgs.qlist(player:getHandcards()) do
				if cd:isKindOf("Slash") and not player:isLocked(cd) then
					local card = sgs.Sanguosha:cloneCard("Slash", cd:getSuit(), cd:getNumber())
					if card:isAvailable(player) then
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if (not sgs.Sanguosha:isProhibited(player, p, cd)) and player:canSlash(p, card, true) then
								pattern = "Slash," .. pattern
								break
							end
						end
					end
					break
				end
			end
			for _, cd in sgs.qlist(player:getHandcards()) do
				if cd:isKindOf("Peach") and not player:isLocked(cd) then
					if cd:isAvailable(player) then
						pattern = "Peach," .. pattern
						break
					end
				end
			end
			for _, cd in sgs.qlist(player:getHandcards()) do
				if cd:isKindOf("TrickCard") and not player:isLocked(cd) then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not sgs.Sanguosha:isProhibited(player, p, cd) then
							pattern = "TrickCard+^Nullification," .. pattern
							break
						end
					end
					break
				end
			end

			local card = room:askForUseCard(player, pattern, "@jibanxuanze", -1)
			if card then
				room:setPlayerMark(player, "ujlianjig", 1)
			end
		end
	end
}
--终式
ujzhongshiRecord = sgs.CreateTriggerSkill {
	name = "#ujzhongshiRecord",
	events = { sgs.PreCardUsed, sgs.CardResponded, sgs.Damage },
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("ujzhongshi") > 0 then return end
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and player:hasSkill("ujzhongshi") then
				if card:isKindOf("Slash") then
					player:gainMark("@shengyong")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage and player:hasSkill("ujzhongshi") then
				player:gainMark("@shengyong")
			end
		end
		return false
	end
}
ujzhongshi = sgs.CreateTriggerSkill {
	name = "ujzhongshi",
	frequency = sgs.Skill_Wake,
	events = { sgs.MarkChanged },
	waked_skills = "smsy",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if (mark.name == "@shengyong") and (mark.gain > 0) then
				if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
					room:broadcastSkillInvoke("ujlianji", math.random(1, 3))
					room:handleAcquireDetachSkills(player, "ujlianjig")
					room:handleAcquireDetachSkills(player, "-ujlianji|smsy")
					room:setPlayerMark(player, self:objectName(), 1)
				end
			end
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("@shengyong") >= 11 then return true end
		return false
	end
}

--扶危
Sdorica_FuWei = sgs.CreateTriggerSkill {
	name = "Sdorica_FuWei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		if (player:getPhase() ~= sgs.Player_Judge) then return false end
		local Angelias = room:findPlayersBySkillName(self:objectName())
		for _, Angelia in sgs.qlist(Angelias) do
			if Angelia:getCardCount(true) >= 1 and (player:getJudgingArea():length() > 0 or (player:getHandcardNum() < Angelia:getHandcardNum())) then
				local _data = sgs.QVariant()
				room:broadcastSkillInvoke("Sdorica_FuWei", math.random(1, 4))
				_data:setValue(player)
				--if room:askForSkillInvoke(tianfeng, self:objectName(), _data) then
				local choices = {}
				table.insert(choices, "put_on_drawcards")
				if Angelia:canDiscard(Angelia, "he") and player:getCardCount(true, true) > 0 then table.insert(choices,
						"fwdiscard&put") end
				table.insert(choices, "cancel")
				choice = room:askForChoice(Angelia, self:objectName(), table.concat(choices, "+"), _data)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, Angelia:objectName(), nil,
					self:objectName(), nil)
				if choice == "fwdiscard&put" then
					if room:askForDiscard(Angelia, self:objectName(), 1, 1, true, true) then
						local card = sgs.Sanguosha:getCard(room:askForCardChosen(Angelia, player, "hej",
							self:objectName()))
						if card then
							room:moveCardTo(card, player, nil, sgs.Player_DrawPile, reason, true)
						end
					end
				elseif choice == "put_on_drawcards" then
					local card = room:askForCard(Angelia, ".", "@Sdorica_FuWei", data, sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, Angelia, nil, sgs.Player_DrawPile, reason, true)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--密令
Sdorica_MiLingCard = sgs.CreateSkillCard {
	name = "Sdorica_MiLingCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	feasible = function(self, targets)
		return #targets == 1
	end,
	filter = function(self, targets, to_select)
		return #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if effect.to:canSlash(p, nil, false) then
				targets:append(p)
			end
		end
		local use_slash = room:askForUseSlashTo(effect.to, targets, "@Sdorica_MiLing")
		if not use_slash then
			effect.to:gainMark("@Immunity")
			room:setPlayerMark(effect.to, "&Sdorica_MiLing+to+#" .. effect.from:objectName(), 1)
			room:setPlayerMark(effect.to, "Sdorica_MiLing+to+#" .. effect.from:objectName(), 1)
		end
		if effect.to ~= effect.from then
			effect.to:gainMark("Sdorica_MiLing")
			room:addPlayerMark(effect.to, "&Sdorica_MiLing+maxcard+to+#" .. effect.from:objectName() .. "-SelfClear")
		end
	end
}

Sdorica_MiLing = sgs.CreateZeroCardViewAsSkill {
	name = "Sdorica_MiLing",
	view_as = function()
		return Sdorica_MiLingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#Sdorica_MiLingCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}
Sdorica_MiLing_PreventDamage = sgs.CreateTriggerSkill {
	name = "#Sdorica_MiLing_PreventDamage",
	events = { sgs.TargetSpecifying, sgs.TargetConfirming, sgs.CardEffected, sgs.EventPhaseEnd }, --{sgs.DamageInflicted, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Analeptic") and not effect.card:isKindOf("EquipCard") then
				player:loseAllMarks("@Immunity")
				for _, p in sgs.qlist(room:findPlayersBySkillName("Sdorica_MiLing")) do
					room:setPlayerMark(player, "&Sdorica_MiLing+to+#" .. p:objectName(), 0)
					room:setPlayerMark(player, "Sdorica_MiLing+to+#" .. p:objectName(), 0)
				end
				return true
			end
		else
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and not use.card:isKindOf("Analeptic") and not use.card:isKindOf("EquipCard") then
				player:loseAllMarks("@Immunity")
				use.to = sgs.SPlayerList()
				data:setValue(use)
				for _, p in sgs.qlist(room:findPlayersBySkillName("Sdorica_MiLing")) do
					room:setPlayerMark(player, "&Sdorica_MiLing+to+#" .. p:objectName(), 0)
					room:setPlayerMark(player, "Sdorica_MiLing+to+#" .. p:objectName(), 0)
				end
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			player:loseAllMarks("Sdorica_MiLing")
		end
		return false
		--return true
	end,
	can_trigger = function(self, target)
		return target and target:getMark("@Immunity") > 0
	end
}
Sdorica_MiLing_card = sgs.CreateMaxCardsSkill {
	name = "#Sdorica_MiLing_card",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getMark("Sdorica_MiLing")
		else
			return 0
		end
	end
}
--虚空
voidcard = sgs.CreateSkillCard {
	name = "void",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and not to_select:isNude() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local id = room:askForCardChosen(source, target, "he", self:objectName(), true)
		room:obtainCard(source, id)
		room:broadcastSkillInvoke("void", math.random(1, 2))
		room:setCardTip(id, "void-Clear")
		room:setPlayerMark(target, "&void+to+#" .. source:objectName(), 1)
		target:drawCards(1)
		local names = room:getTag(source:objectName() .. "voidtarget"):toString():split("+")
		table.insert(names, target:objectName())
		local list = room:getTag(source:objectName() .. "voidid"):toString():split("+")
		table.insert(list, string.format("%d", id))
		room:setTag(source:objectName() .. "voidtarget", sgs.QVariant(table.concat(names, "+")))
		room:setTag(source:objectName() .. "voidid", sgs.QVariant(table.concat(list, "+")))
		room:setPlayerMark(source, "voidused", source:getMark("voidused") + 1)
		room:setTag(source:objectName() .. "voidbeused" .. target:objectName(), sgs.QVariant(true))
		room:setPlayerMark(source, "&void-Clear", math.max(source:getMark("voidcanuse") - source:getMark("voidused"), 0))
	end,
}

voidvs = sgs.CreateZeroCardViewAsSkill {
	name = "void",
	view_as = function(self)
		return voidcard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("voidcanuse") - player:getMark("voidused") >= 0
	end
}

void = sgs.CreateTriggerSkill {
	name = "void",
	events = { sgs.EventPhaseEnd, sgs.EventPhaseStart },
	view_as_skill = voidvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				room:setPlayerMark(player, "voidcanuse", 0)
				local idlist = room:getTag(player:objectName() .. "voidid"):toString():split("+")
				local names = room:getTag(player:objectName() .. "voidtarget"):toString():split("+")

				for i = 1, #idlist, 1 do
					local target
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:objectName() == names[i] then target = p end
					end
					local list = sgs.IntList()
					for _, h in sgs.qlist(player:handCards()) do
						list:append(h)
					end
					for _, e in sgs.qlist(player:getEquips()) do
						list:append(e:getEffectiveId())
					end
					if target and list:contains(idlist[i]) then
						room:obtainCard(target, idlist[i])
					elseif target and not list:contains(idlist[i]) then
						room:loseHp(target)
					end
				end

				room:setTag(player:objectName() .. "voidtarget", sgs.QVariant())
				room:setTag(player:objectName() .. "voidid", sgs.QVariant())
			elseif player:getPhase() == sgs.Player_Play then
				room:setPlayerMark(player, "voidused", 0)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				room:setPlayerMark(player, "&void-Clear",
					math.max(player:getMark("voidcanuse") - player:getMark("voidused"), 0))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--王国
wangguo = sgs.CreateTriggerSkill {
	name = "wangguo",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if room:getTag(player:objectName() .. "voidbeused" .. p:objectName()):toBool() then
					room:broadcastSkillInvoke("wangguo", math.random(1, 2))
					local choice = room:askForChoice(p, self:objectName(), "oumashu_lose+oumashu_recover", data)
					if choice == "oumashu_recover" then
						local re = sgs.RecoverStruct()
						re.who = p
						room:recover(player, re, true)
						room:setPlayerMark(player, "voidcanuse", player:getMark("voidcanuse") + 1)
						sendLog("#void_recover", room, p, nil, nil, player)
					else
						room:loseHp(player)
						room:setPlayerMark(player, "voidused", player:getMark("voidused") + 1)
						room:setTag(player:objectName() .. "voidbeused" .. p:objectName(), sgs.QVariant())
						room:setPlayerMark(p, "&void+to+#" .. player:objectName(), 0)
						sendLog("#void_lose", room, p, nil, nil, player)
					end
				end
			end
			room:setPlayerMark(player, "&void-Clear",
				math.max(player:getMark("voidcanuse") - player:getMark("voidused"), 0))
		end
	end,
}
--零式驱动
lsqd = sgs.CreateTriggerSkill {
	name = "lsqd",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "lsqd:qp+lsqd:kd")
			if choice == "lsqd:qp" then
				if player:canDiscard(player, "h") and room:askForCard(player, ".|.|.|hand", "@lsqd", data, self:objectName()) then
					local list = sgs.IntList()
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
							list:append(id)
						end
					end
					if list:length() == 0 then return false end
					room:fillAG(list, player)
					local id = room:askForAG(player, list, false, "sandun")
					room:clearAG(player)
					room:obtainCard(player, id, true)
					local use = sgs.CardUseStruct()
					use.card = sgs.Sanguosha:getCard(id)
					use.from = player
					use.to:append(player)
					room:useCard(use)
				end
			elseif choice == "lsqd:kd" then
				if player:hasEquip() then
					player:drawCards(1)
					local card = sgs.Sanguosha:getCard(room:askForCardChosen(player, player, "e", self:objectName()))
					if card then
						room:moveCardTo(card, player, nil, sgs.Player_DrawPile,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), nil,
								self:objectName(), nil), true)
					end
				end
			end
		end
	end,
}
--天使重构
tscg = sgs.CreateTriggerSkill {
	name = "tscg",
	frequency = sgs.Skill_Wake,
	events = { sgs.Death },
	waked_skills = "wzgz",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death and player:getMark(self:objectName()) == 0 then
			if room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) then
				local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "tscg-invoke",
					true, true)
				if not s then return false end
				room:damage(sgs.DamageStruct(self:objectName(), player, s, 1, sgs.DamageStruct_Normal))
				if player:getGeneralName() == "banya" then
					room:changeHero(player, "banyali", false, false, false, false)
				elseif player:getGeneral2Name() == "banya" then
					room:changeHero(player, "banyali", false, false, true, false)
				end
				--room:setPlayerProperty(player, "general", sgs.QVariant("banyali"))
				room:handleAcquireDetachSkills(player, "wzgz")
				room:addPlayerMark(player, self:objectName())
			end
		end
	end,
}
--武装构造
wzgzcard = sgs.CreateSkillCard {
	name = "wzgzcard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasEquip()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local card_id = room:askForCardChosen(effect.from, effect.to, "e", self:objectName())
		room:obtainCard(effect.from, card_id)
		if not sgs.Sanguosha:getCard(card_id):isKindOf("Weapon") and not effect.from:isKongcheng() then
			room:askForDiscard(effect.from, self:objectName(), 1, 1, false, false)
		end
	end
}
wzgz = sgs.CreateViewAsSkill {
	name = "wzgz",
	n = 0,
	view_as = function()
		return wzgzcard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#wzgzcard")
	end,
}
--天才魔法师
tcmfs = sgs.CreateTriggerSkill {
	name = "tcmfs",
	events = { sgs.GameStart, sgs.DamageCaused },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:gainMark("@tcmfs")
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("TrickCard") and damage.card:isRed() and player:getMark("@tcmfs") == 1 then
				room:setTag("tcmfs", data)
				if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@fashiyongchang") then
					damage.damage = damage.damage + 1
					sendLog("#zyfashi-zs", room, player, damage.damage, nil, damage.to)
					data:setValue(damage)
				end
				room:removeTag("tcmfs")
			end
		end
	end,
}

--爆裂魔法
blmf = sgs.CreateOneCardViewAsSkill {
	name = "blmf",
	filter_pattern = "BasicCard|.|.|.",
	view_as = function(self, first)
		local ncard = sgs.Sanguosha:cloneCard("fire_attack", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName(self:objectName())
		return ncard
	end,
}
blmfex = sgs.CreateTriggerSkill {
	name = "#blmfex",
	events = { sgs.PreCardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == "blmf" then
			room:broadcastSkillInvoke("blmf", 4)
			return true
		end
	end
}
blmfxx = sgs.CreateTriggerSkill {
	name = "#blmfxx",
	events = { sgs.DamageCaused, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "blmf" then
				damage.damage = damage.damage + 1
				sendLog("#blmf-zs", room, player, damage.damage, nil, damage.to)
				data:setValue(damage)
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "blmf" then
				room:broadcastSkillInvoke("blmf", math.random(1, 3))
				room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
			end
		end
	end
}
extension:insertRelatedSkills("blmf", "#blmfxx")
extension:insertRelatedSkills("blmf", "#blmfex")
--莫止
htms_mozhicard = sgs.CreateSkillCard {
	name = "htms_mozhi",
	target_fixed = true,
	will_throw = true,
	can_recast = true,
	on_use = function(self, room, source, targets)
		local ids = self:getSubcards()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName())
		reason.m_skillName = self:objectName()
		room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		room:broadcastSkillInvoke("@recast")
		source:drawCards(ids:length())
		room:setPlayerMark(source, "&htms_mozhi", source:getMark("&htms_mozhi") + 1)
	end
}

htms_mozhi = sgs.CreateViewAsSkill {
	name = "htms_mozhi",
	n = 998,
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getMark("&htms_mozhi") + 1 and #selected < sgs.Self:getHp() then
			return not to_select:isAvailable(sgs.Self)
		end
	end,
	view_as = function(self, cards)
		if #cards < sgs.Self:getMark("&htms_mozhi") + 1 then
			return nil
		else
			local vs_card = htms_mozhicard:clone()
			for _, card in ipairs(cards) do
				vs_card:addSubcard(card)
			end
			return vs_card
		end
	end
}
htms_mozhixx = sgs.CreateTriggerSkill {
	name = "#htms_mozhixx",
	events = { sgs.EventPhaseEnd, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			player:loseAllMarks("&htms_mozhi")
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				room:broadcastSkillInvoke("htms_mozhi", 4)
			end
		end
	end
}

htms_mozhidis = sgs.CreateDistanceSkill {
	name = "#htms_mozhidis",
	correct_func = function(self, from, to)
		if from:hasSkill("htms_mozhi") then
			return -from:getMark("&htms_mozhi")
		end
	end
}
extension:insertRelatedSkills("htms_mozhi", "#htms_mozhidis")
extension:insertRelatedSkills("htms_mozhi", "#htms_mozhixx")
--依伴
yibanCard = sgs.CreateSkillCard {
	name = "yiban",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "yibanz")
		room:setPlayerFlag(targets[1], "yibanx")
		targets[1]:obtainCard(self, false)
	end,
}

yibanvs = sgs.CreateViewAsSkill {
	name = "yiban",
	n = 999,
	view_filter = function(self, selected, to_select)
		return #selected < 999
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = yibanCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	response_pattern = "@@yiban",
}
yiban = sgs.CreateTriggerSkill {
	name = "yiban",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.CardFinished },
	view_as_skill = yibanvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "@@yiban", "yiban_card")
			end
		end

		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeSkill then return end
			if player:getPhase() == sgs.Player_Play and player:hasFlag("yibanz") and (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) then
				for _, targets in sgs.qlist(room:getAlivePlayers()) do
					if targets:hasFlag("yibanx") then
						local choice = room:askForChoice(targets, self:objectName(), "yiban:cp+yiban:gp")
						if choice == "yiban:cp" then
							--local card = room:askForUseCard(targets, "TrickCard+^Nullification,BasicCard+^Jink,EquipCard|.|.|hand", "@jibanxuanze")
							--if not card then return false end	
							local pattern = "|.|.|.|."
							for _, cd in sgs.qlist(targets:getHandcards()) do
								if cd:isKindOf("EquipCard") and not targets:isLocked(cd) then
									if cd:isAvailable(targets) then
										pattern = "EquipCard," .. pattern
										break
									end
								end
							end
							for _, cd in sgs.qlist(targets:getHandcards()) do
								if cd:isKindOf("Analeptic") and not targets:isLocked(cd) then
									local card = sgs.Sanguosha:cloneCard("Analeptic", cd:getSuit(), cd:getNumber())
									if card:isAvailable(targets) then
										pattern = "Analeptic," .. pattern
										break
									end
								end
							end
							for _, cd in sgs.qlist(targets:getHandcards()) do
								if cd:isKindOf("Slash") and not targets:isLocked(cd) then
									local card = sgs.Sanguosha:cloneCard("Slash", cd:getSuit(), cd:getNumber())
									if card:isAvailable(targets) then
										for _, p in sgs.qlist(room:getOtherPlayers(targets)) do
											if (not sgs.Sanguosha:isProhibited(targets, p, cd)) and targets:canSlash(p, card, true) then
												pattern = "Slash," .. pattern
												break
											end
										end
									end
									break
								end
							end
							for _, cd in sgs.qlist(targets:getHandcards()) do
								if cd:isKindOf("Peach") and not targets:isLocked(cd) then
									if cd:isAvailable(targets) then
										pattern = "Peach," .. pattern
										break
									end
								end
							end
							for _, cd in sgs.qlist(targets:getHandcards()) do
								if cd:isKindOf("TrickCard") and not targets:isLocked(cd) then
									for _, p in sgs.qlist(room:getOtherPlayers(targets)) do
										if not sgs.Sanguosha:isProhibited(targets, p, cd) then
											pattern = "TrickCard+^Nullification," .. pattern
											break
										end
									end
									break
								end
							end

							local card = room:askForUseCard(targets, pattern, "@jibanxuanze", -1)
						elseif choice == "yiban:gp" then
							if targets:isNude() then return false end
							local card_id = room:askForCardChosen(targets, targets, "he", self:objectName())
							local card = sgs.Sanguosha:getCard(card_id)
							room:obtainCard(player, card)
						end
					end
				end
			end
		end
		return false
	end
}
--破灭回避
pomiehb = sgs.CreateTriggerSkill {
	name = "pomiehb",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local n = room:getAlivePlayers():first():getHandcardNum()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				n = math.min(n, p:getHandcardNum())
			end
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() == n then
					targets:append(p)
				end
			end
			local to = room:askForPlayerChosen(player, targets, self:objectName(), "pomie_card", true, true)
			if to then
				to:drawCards(1)
				if to:objectName() ~= player:objectName() then
					player:drawCards(1)
					room:broadcastSkillInvoke("pomiehb", math.random(4, 6))
				else
					room:broadcastSkillInvoke("pomiehb", math.random(1, 3))
				end
			end
		end
	end
}
--逐梦一步
zhumyb = sgs.CreateTriggerSkill {
	name = "zhumyb",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished and (not player:hasFlag("zhumyb1")) then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeSkill then return end
			if player:getPhase() ~= sgs.Player_Play then return end
			if player:getMark("mengyb") ~= 0 then
				if use.card:getNumber() > player:getMark("mengyb") then
					player:drawCards(1)
				elseif use.card:getNumber() < player:getMark("mengyb") then
					room:setPlayerMark(player, "mengyb", 0)
					room:setPlayerFlag(player, "zhumyb1")
					room:loseHp(player, 1)
				end
			end
			room:setPlayerMark(player, "&zhumyb-Clear", use.card:getNumber())
			room:setPlayerMark(player, "mengyb", 0)
			local num = use.card:getNumber()
			room:addPlayerMark(player, "mengyb", num)
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			room:setPlayerMark(player, "mengyb", 0)
			room:setPlayerFlag(player, "-zhumyb1")
		end
	end
}
--同好
tonghh = sgs.CreateTriggerSkill {
	name = "tonghh",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				local jnmb = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					jnmb:append(p)
				end
				local s = room:askForPlayerChosen(player, jnmb, self:objectName(), "tonghh-invoke")
				s:gainMark("@tonghao")
				player:gainMark("@tonghao")
			end
		end
		if event == sgs.Damaged and (player:getMark("@tonghao") == 1) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@tonghao") ~= 0 then
					p:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
--收获
luashouhuo2 = sgs.CreateMaxCardsSkill {
	name = "#luashouhuo2",
	fixed_func = function(self, target)
		if target:hasFlag("luashouhuo") then
			return 1
		end
	end
}
luashouhuo = sgs.CreateTriggerSkill {
	name = "luashouhuo",
	events = { sgs.EventPhaseStart, sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				local Eternitys = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if not p:hasSkill("luaouxiang") then
						Eternitys:append(p)
					end
				end
				local to = room:askForPlayerChosen(player, Eternitys, "luashouhuo", "@luashouhuo", true, true)
				if to and to:getHandcardNum() <= to:getMaxCards() then
					to:drawCards(to:getMaxCards() - to:getHandcardNum(), self:objectName())
					room:setPlayerFlag(player, "luashouhuo")
					room:setPlayerMark(player, "&luashouhuo-Clear", 1)
					return false
				end
			end
		else
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag("luashouhuo") then
				draw.num = draw.num - 1
				data:setValue(draw)
			end
		end
	end
}



--红芋
luahongyu_list = {}
luahongyu = sgs.CreateTriggerSkill {
	name = "luahongyu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			luahongyu_list = {}
			local move = data:toMoveOneTime()
			if not move.from then return false end
			for _, id in sgs.qlist(move.card_ids) do
				if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					table.insert(luahongyu_list, id)
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			local ids_A = sgs.IntList()
			local jiyi = luahongyu_list
			local fengshou_l = {}
			for _, id in pairs(luahongyu_list) do
				if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
					return false
				end
				table.insert(fengshou_l, tostring(id))
				if room:getCardPlace(id) == sgs.Player_DiscardPile then ids_A:append(id) end
			end


			local players = room:getAlivePlayers()
			if #luahongyu_list > 0 and #luahongyu_list <= players:length() then
				room:setTag("lfengshou", sgs.QVariant(table.concat(fengshou_l, "|")))
				local ij = 1
				while not players:isEmpty() do
					if ij <= 2 then
						room:setPlayerFlag(player, "fengshouA")
					else
						room:setPlayerFlag(player, "-fengshouA")
					end
					local target = room:askForPlayerChosen(player, players, self:objectName(), "luahongyu2", false, true)
					players:removeOne(target)
					if target then
						room:fillAG(ids_A)
						room:setPlayerFlag(target, "fengshouT")
						local card_id = room:askForAG(player, ids_A, false, self:objectName())
						ids_A:removeOne(card_id)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcard(card_id)
						dummy:deleteLater()
						room:obtainCard(target, dummy, false)
						room:clearAG()
						room:setPlayerFlag(target, "-fengshouT")
						if ids_A:isEmpty() then break end
					else
						break
					end
					ij = ij + 1
				end
				room:removeTag("lfengshou")
				local canRe = true
				for _, id in pairs(jiyi) do
					if not sgs.Sanguosha:getCard(id):isRed() then
						canRe = false
					end
				end
				if canRe and #jiyi > 0 then room:recover(player, sgs.RecoverStruct(player)) end
			end
		end
		return false
	end
}
--粉红恶魔
pinkdevil = sgs.CreateTriggerSkill {
	name = "pinkdevil",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetSpecified, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			room:addPlayerMark(player, "chongp", 1)
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local num = (player:getMark("chongp") + player:getMark("chongqp"))
			if num > 0 then
				if not player:askForSkillInvoke(self:objectName(), data) then return false end
				player:setMark("chongp", 0)
				player:setMark("chongqp", 0)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:deleteLater()
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not player:isProhibited(p, slash) and player:canSlash(p, slash, false) then
						targets:append(p)
					end
				end
				if targets:length() == 0 then return false end
				local victim = room:askForPlayerChosen(player, targets, "pinkdevil", "pinkdevilx", true, true)
				room:broadcastSkillInvoke("pinkdevil", math.random(1, 2))
				if not victim then return false end
				slash:setSkillName(self:objectName())
				slash:deleteLater()
				room:useCard(sgs.CardUseStruct(slash, player, victim))
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if player:getHandcardNum() <= player:getMaxCards() then
				room:addPlayerMark(player, "chongqp", 1)
			end
		end
		if player:getPhase() ~= sgs.Player_Play then return end
		if event == sgs.TargetSpecified and use.card:isKindOf("Slash") then
			player:setMark("chongp", 0)
		end
	end
}
--狂化
khztbuff = sgs.CreateTriggerSkill {
	name = "khztbuff",
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.by_user then return false end
		local reason = damage.card
		if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) and (player:getLostHp() > 0) and (player:getEquips():length() > 0) then
			local msg = sgs.LogMessage()
			msg.type = "#khztbuff"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = damage.damage
			msg.arg2 = damage.damage + 1
			room:sendLog(msg)
			room:broadcastSkillInvoke("khztbuff", math.random(1, 2))
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
}
--余烬
embers = sgs.CreateTriggerSkill {
	name = "embers",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.Death },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death or event == sgs.GameStart then
			for _, v2 in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local death = data:toDeath()
				local a = 0
				local b = 0
				local c = 0
				if death.who ~= v2 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if (p:getRole() == "lord" or p:getRole() == "loyalist") then
							a = a + 1
						elseif (p:getRole() == "rebel") then
							b = b + 1
						end
					end
					if (v2:getRole() == "lord" or v2:getRole() == "loyalist") then
						if a > b then
							room:broadcastSkillInvoke("embers", math.random(1, 2))
							room:handleAcquireDetachSkills(v2, "gxzhiliao", true)
						elseif b > a then
							room:broadcastSkillInvoke("embers", math.random(3, 4))
							room:handleAcquireDetachSkills(v2, "shenpan", true)
						end
					elseif v2:getRole() == "rebel" then
						if a > b then
							room:broadcastSkillInvoke("embers", math.random(3, 4))
							room:handleAcquireDetachSkills(v2, "shenpan", true)
						elseif b > a then
							room:broadcastSkillInvoke("embers", math.random(1, 2))
							room:handleAcquireDetachSkills(v2, "gxzhiliao", true)
						end
					elseif v2:getRole() == "renegade" then
						room:broadcastSkillInvoke("embers", math.random(3, 4))
						room:handleAcquireDetachSkills(v2, "shenpan", true)
					end
				end
			end
		end
	end
}
embersex = sgs.CreateTriggerSkill {
	name = "#embersex",
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:broadcastSkillInvoke("embers", 5)
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			room:broadcastSkillInvoke("embers", 6)
		end
	end,

}
--高效治疗
gxzhiliao = sgs.CreateTriggerSkill {
	name = "gxzhiliao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			--if not player:askForSkillInvoke(self:objectName(),data) then return false end
			room:broadcastSkillInvoke("gxzhiliao", 1)
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "gxzhiliao-invoke", true,
				true)
			if not s then return false end
			room:addPlayerMark(s, "gxzhiliao", 1)
			room:addPlayerMark(s, "&gxzhiliao+to+#" .. player:objectName(), 1)
		end
	end
}
gxzhiliaoex = sgs.CreateTriggerSkill {
	name = "#gxzhiliaoex",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if player:getMark("gxzhiliao") ~= 0 then
				player:setMark("gxzhiliao", 0)
				player:loseMark("@hurt")
				room:broadcastSkillInvoke("gxzhiliao", math.random(2, 3))
				local recover = sgs.RecoverStruct(player, nil, 1)
				room:recover(player, recover)
				for _, v2 in sgs.qlist(room:findPlayersBySkillName("gxzhiliao")) do
					if player:getMark("&gxzhiliao+to+#" .. v2:objectName()) > 0 then
						room:setPlayerMark(player, "&gxzhiliao+to+#" .. v2:objectName(), 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--审判
shenpan = sgs.CreateTriggerSkill {
	name = "shenpan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			player:gainMark("@hurt")
			local n = 0
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				n = math.max(n, p:getHp())
			end
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() == n then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local s = room:askForPlayerChosen(player, targets, self:objectName(), "shenpan-invoke", true, true)
			if not s then return false end
			room:broadcastSkillInvoke("shenpan", math.random(1, 2))
			room:damage(sgs.DamageStruct(self:objectName(), player, s, 1, sgs.DamageStruct_Normal))
		end
	end,
}
--莫得感情的杀手
local lierenxj = { "slash", "jink", "peach" }
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(lierenxj, 2, "thunder_slash")
	table.insert(lierenxj, 2, "fire_slash")
	table.insert(lierenxj, 4, "analeptic")
end

wugshashou = sgs.CreateTriggerSkill {
	name = "wugshashou",
	events = { sgs.Damage },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if damage.to:isAlive() then
			local suit = judge.card:getSuit()
			if suit == sgs.Card_Spade then
				room:loseMaxHp(damage.to)
			elseif suit == sgs.Card_Heart then
				room:loseHp(damage.to)
			end
		end
		return false
	end,
}
--耐心的猎人
nxlieren = sgs.CreateTriggerSkill {
	name = "nxlieren",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local choice = room:askForChoice(player, self:objectName(), table.concat(lierenxj, "+"))
					room:addPlayerMark(player, choice, 1)
					local players = sgs.SPlayerList()
					players:append(player)
					room:addPlayerMark(player, "&nxlieren+" .. choice, 1, players)
					return true
				end
			end
			if player:getPhase() == sgs.Player_Start then
				--player:setMark(lierenxj, 0)	
				for _, card in ipairs(lierenxj) do
					player:setMark(card, 0)
				end
				for _, m in sgs.list(player:getMarkNames()) do
					if m:startsWith("&nxlieren+") then
						room:setPlayerMark(player, m, 0)
					end
				end
			end
		end
	end,

}
nxlieren_ex = sgs.CreateTriggerSkill {
	name = "#nxlieren_ex",
	events = { sgs.CardUsed, sgs.CardResponded },
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		for _, f in sgs.qlist(room:findPlayersBySkillName("nxlieren")) do
			local card_star = data:toCardResponse().m_card
			local dest = sgs.QVariant()
			dest:setValue(player)
			if event == sgs.CardUsed then
				if f:getMark(use.card:objectName()) == 1 and f:askForSkillInvoke("nxlieren_damage", dest) then
					f:setMark(use.card:objectName(), 0)
					for _, m in sgs.list(f:getMarkNames()) do
						if m:startsWith("&nxlieren+" .. use.card:objectName()) then
							room:setPlayerMark(f, m, 0)
						end
					end
					room:sendCompulsoryTriggerLog(f, "nxlieren", true)
					room:damage(sgs.DamageStruct(self:objectName(), f, player, 1, sgs.DamageStruct_Normal))
				end
			end
			if event == sgs.CardResponded and f:getMark(card_star:objectName()) == 1 and f:askForSkillInvoke("nxlieren_damage", dest) then
				f:setMark(card_star:objectName(), 0)
				room:sendCompulsoryTriggerLog(f, "nxlieren", true)
				room:damage(sgs.DamageStruct(self:objectName(), f, player, 1, sgs.DamageStruct_Normal))
			end
		end
	end
}
--系步
--[[xibu = sgs.CreateTriggerSkill{
	name = "xibu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		
		if  event == sgs.CardFinished then
		local use = data:toCardUse()	
		if  use.card:isKindOf("SkillCard") then return end	
		if  use.card:isKindOf("Nullification") or use.card:isKindOf("EquipCard") or use.card:isKindOf("Collateral") or 	(use.card:objectName() == "indulgence") or (use.card:objectName() == "supply_shortage" ) or (use.card:objectName() == "lightning") or (use.card:objectName() == "shuugakulyukou" ) then return end					
		if player:getPile("bu_bu"):length() < 6 and   not use.card:isVirtualCard() then		
			player:addToPile("bu_bu", use.card)
		end
		end
		if  event == sgs.CardResponded then
		local card_star = data:toCardResponse().m_card	
		if card_star:isKindOf("SkillCard") or card_star:isKindOf("Nullification") or card_star:isKindOf("Collateral") then return end
		if player:getPile("bu_bu"):length() < 6 then
		local card = damage.card
		if card then
			local ids = sgs.IntList()
			if card:isVirtualCard() then
				ids = card:getSubcards()
			else
				ids:append(card:getEffectiveId())
			end
			if ids:length() > 0 then
				local all_place_table = true
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
					end
				end
				if all_place_table then
					table.insert(choices, "obtain")
				end
			end
		end
			if    not card_star:isVirtualCard() then		
				player:addToPile("bu_bu", card_star)
			end
		end
		end	
	end,
}]]


xibu = sgs.CreateTriggerSkill {
	name = "xibu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished, sgs.CardResponded },
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play and (event == sgs.CardFinished or event == sgs.CardResponded) then
			local card
			if event == sgs.CardFinished then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and (player:getPile("bu_bu"):length() < 6) then
				if card then
					local ids = sgs.IntList()
					if card:isVirtualCard() then
						ids = card:getSubcards()
					else
						ids:append(card:getEffectiveId())
					end
					if ids:length() > 0 then
						local all_place_table = true
						for _, id in sgs.qlist(ids) do
							if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
								all_place_table = false
								break
							end
						end
						if all_place_table then
							player:addToPile("bu_bu", card)
						end
					end
				end
			end
		end
	end
}

--大论
dalunb_xx = sgs.CreateSkillCard {
	name = "dalunb",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			card:addSubcard(self:getSubcards():first())
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and
				not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetsFeasible(plist, sgs.Self)
	end,

	on_use = function(self, room, source, targets)
		local bu = source:getPile("bu_bu")
		local lunwen = sgs.IntList()
		for _, s in sgs.qlist(bu) do
			if not sgs.Sanguosha:getCard(s):isKindOf("Jink") and s ~= self:getSubcards():first() then
				lunwen:append(s)
			end
		end
		room:fillAG(lunwen, source)
		local card_id = room:askForAG(source, lunwen, false, self:objectName())
		room:throwCard(card_id, source)
		room:clearAG()
		local ac = sgs.Sanguosha:getCard(card_id):objectName()
		local slash = sgs.Sanguosha:cloneCard(ac, sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		local target = sgs.SPlayerList()
		for _, px in ipairs(targets) do
			target:append(px)
			if self:getUserString() == "archery_attack" or self:getUserString() == "savage_assault" then
				for _, p in sgs.ipairs(room:getOtherPlayers(player)) do
					target:append(p)
				end
			end
		end
		if target:length() ~= 0 then
			room:useCard(sgs.CardUseStruct(slash, source, target))
		elseif self:getUserString() == "god_salvation" or self:getUserString() == "amazing_grace" or self:getUserString() == "bunkasai" then
			room:useCard(sgs.CardUseStruct(slash, source, room:getAlivePlayers()))
		elseif self:getUserString() == "archery_attack" or self:getUserString() == "savage_assault" then
			room:useCard(sgs.CardUseStruct(slash, source, room:getOtherPlayers(source)))
		end
	end
}




dalunb_select = sgs.CreateSkillCard {
	name = "dalunb_select",
	will_throw = true,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "dalun", 1)
		room:askForUseCard(source, "@@dalunb!", "@dalunb")
		room:setPlayerMark(source, "dalun", 0)
		return false
	end
}

dalunb = sgs.CreateViewAsSkill {
	name = "dalunb",
	n = 1,
	expand_pile = "bu_bu",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and string.startsWith(pattern, "@@dalunb") then
			if (sgs.Self:getSlashCount() > 0 and not sgs.Self:canSlashWithoutCrossbow()) then
				return sgs.Self:getPile("bu_bu"):contains(to_select:getEffectiveId()) and to_select:isAvailable(sgs.Self)
			else
				return sgs.Self:getPile("bu_bu"):contains(to_select:getEffectiveId()) and to_select:isAvailable(sgs.Self)
			end
		else
			return sgs.Self:getPile("bu_bu"):contains(to_select:getEffectiveId()) and to_select:isAvailable(sgs.Self)
		end
	end,
	view_as = function(self, cards)
		if sgs.Self:getMark("dalun") == 1 then
			if #cards == 1 then
				local slash = dalunb_xx:clone()
				slash:addSubcard(cards[1]:getId())
				slash:setSkillName(cards[1]:objectName())
				slash:setUserString(cards[1]:objectName())
				return slash
			end
		else
			if #cards == 1 then
				local acard = dalunb_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		end
	end,
	enabled_at_play = function(self, player)
		local can_invoke = false
		if not player:getPile("bu_bu"):isEmpty() then
			for _, id in sgs.qlist(player:getPile("bu_bu")) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isAvailable(player) then
					local list = player:getAliveSiblings()
					list:append(player)
					for _, p in sgs.qlist(list) do
						if card:targetFixed() or card:targetFilter(sgs.PlayerList(), p, player) then
							if not player:isProhibited(p, card) then
								can_invoke = true
								break
							end
						end
					end
				end
			end
			return player:getPile("bu_bu"):length() >= 3 and can_invoke
		else
			return false
		end
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@dalunb")
	end
}
--布局
zhanshubuju = sgs.CreateTriggerSkill {
	name = "zhanshubuju",
	events = { sgs.CardAsked },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return end
		local diban = room:findPlayersBySkillName(self:objectName())
		room:setPlayerFlag(player, "zhanshubuju_Target")
		for _, llx in sgs.qlist(diban) do
			if llx:getMark("dibanx") == 0 and room:askForSkillInvoke(llx, self:objectName(), data) then
				room:setPlayerFlag(player, "-zhanshubuju_Target")
				local num = 9 - room:alivePlayerCount()
				local list = sgs.IntList()
				for _, id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("Jink") and list:length() ~= num then
						list:append(id)
					end
				end
				if list:length() ~= num then
					local msg = sgs.LogMessage()
					msg.type = "#bujushibai"
					room:sendLog(msg)
					return false
				end
				for _, cd in sgs.qlist(list) do
					if list:length() ~= 0 then
						room:throwCard(sgs.Sanguosha:getCard(cd), nil, nil)
					end
				end
				room:addPlayerMark(llx, "dibanx", 1)
				room:addPlayerMark(llx, "&zhanshubuju-Clear", 1)
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				jink:setSkillName(self:objectName())
				room:provide(jink)
				return true
			end
		end
		room:setPlayerFlag(player, "-zhanshubuju_Target")
	end,
	can_trigger = function(self, target)
		return target
	end
}

zhanshubuju_ex = sgs.CreateTriggerSkill {
	name = "#zhanshubuju_ex",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local diban = room:findPlayersBySkillName(self:objectName())
			for _, llx in sgs.qlist(diban) do
				llx:setMark("dibanx", 0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--炸场
zhachangCard = sgs.CreateSkillCard {
	name = "zhachang",
	will_throw = true,
	target_fixed = false,
	feasible = function(self, targets)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local list = sgs.IntList()
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("Jink") and list:length() ~= 1 then
				list:append(id)
			end
		end
		if list:length() == 0 then
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				p:throwAllCards()
			end
		elseif list:length() ~= 0 then
			for _, cd in sgs.qlist(list) do
				if list:length() ~= 0 then
					room:throwCard(sgs.Sanguosha:getCard(cd), nil, nil)
				end
			end
		end
		return false
	end,
}
zhachang = sgs.CreateViewAsSkill {
	n = 1,
	name = "zhachang",
	view_filter = function(self, selected, to_select)
		return #selected < 1 and to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local vs_card = zhachangCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,

}
--洪水
hongshui = sgs.CreateTriggerSkill {
	name = "hongshui",
	frequency = sgs.Skill_Limited,
	limit_mark = "@hshui",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play then
			if player:getMark("@hshui") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:removePlayerMark(player, "@hshui")
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						p:throwAllCards()
					end
				end
			end
		end
	end
}
--祝福
zhufuCard = sgs.CreateSkillCard {
	name = "zhufu",
	target_fixed = true,
	feasible = function(self, targets)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@zfu")
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:hasEquip() then
				local recover = sgs.RecoverStruct(source, nil, 1)
				room:recover(p, recover)
				p:drawCards(1)
			end
		end
		return false
	end,
}

zhufuvs = sgs.CreateZeroCardViewAsSkill {
	name = "zhufu",
	view_as = function(self, cards)
		return zhufuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@zfu") >= 1
	end
}
zhufu = sgs.CreateTriggerSkill {
	name = "zhufu",
	frequency = sgs.Skill_Limited,
	view_as_skill = zhufuvs,
	limit_mark = "@zfu",
	on_trigger = function()
	end
}
--复活
afuhuo = sgs.CreateTriggerSkill {
	name = "afuhuo",
	frequency = sgs.Skill_Limited,
	limit_mark = "@fuhuo",
	events = { sgs.Dying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			local dying = data:toDying()
			local victim = dying.who
			local a = 0
			if player:getMark("@fuhuo") > 0 and room:askForSkillInvoke(player, "afuhuo", data) then
				room:removePlayerMark(player, "@fuhuo")
				local flags = { "fuhuo_e", "fuhuo_h", "fuhuo_j" }
				if not victim:canDiscard(victim, "h") then
					table.removeOne(flags, "fuhuo_h")
				end
				if not victim:canDiscard(victim, "e") then
					table.removeOne(flags, "fuhuo_e")
				end
				if not victim:canDiscard(victim, "j") then
					table.removeOne(flags, "fuhuo_j")
				end
				if #flags == 0 then
					room:recover(victim, sgs.RecoverStruct(victim, nil, 3 - victim:getHp()))
					victim:drawCards(3 - victim:getHandcardNum(), self:objectName())
					return
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(flags, "+"), sgs.QVariant())
				if choice == "fuhuo_h" then
					victim:throwAllHandCards()
				elseif choice == "fuhuo_j" then
					for _, cd in sgs.qlist(victim:getJudgingArea()) do
						if victim:getJudgingArea():length() ~= 0 then
							room:throwCard(cd, nil, nil)
						end
					end
				elseif choice == "fuhuo_e" then
					victim:throwAllEquips()
				end
				if victim:getJudgingArea():isEmpty() then
					a = a + 1
				end
				if victim:isKongcheng() then
					a = a + 1
				end
				if not victim:hasEquip() then
					a = a + 1
				end
				room:recover(victim, sgs.RecoverStruct(victim, nil, a - victim:getHp()))
				victim:drawCards(a - victim:getHandcardNum(), self:objectName())
				a = 0
			end
		end
	end,

}
--童话
tonghua = sgs.CreateTriggerSkill {
	name = "tonghua",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, "tonghua", data) then
			draw.num = draw.num - 1
			data:setValue(draw)
			local ids = room:getNCards(3)
			room:fillAG(ids)
			for _, id in sgs.qlist(ids) do
				if sgs.Sanguosha:getCard(id):isRed() and ids:length() ~= 0 then
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
						"@tonghuagp:::" .. sgs.Sanguosha:getCard(id):objectName(), true, true)
					if s then
						room:obtainCard(s, id, false)
					end
				elseif sgs.Sanguosha:getCard(id):isBlack() and ids:length() ~= 0 then
					room:throwCard(sgs.Sanguosha:getCard(id), nil, nil)
				end
			end
			if ids:length() == 0 then
				room:clearAG()
				return false
			end
			room:clearAG()
		end
	end
}
--灵波
lingbo = sgs.CreateTriggerSkill {
	name = "lingbo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeSkill then return end
			if player:getMark("lingbob-Clear") == 0 and use.from:objectName() == player:objectName() then
				if use.card:getSuit() == sgs.Card_Heart then --and room:askForSkillInvoke(zhenbu, "lingbo", data) then
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@lingbo_to",
						true, true)
					if not s then return false end
					room:recover(s, sgs.RecoverStruct(player, nil, 1))
					room:addPlayerMark(player, "lingbob-Clear", 1)
					room:addPlayerMark(player, "&lingbo-Clear", 1)
				end
			end
		end
	end,
}
--超改造
chaogz = sgs.CreateTriggerSkill {
	name = "chaogz",
	events = { sgs.BuryVictim },
	frequency = sgs.Skill_Compulsory,
	priority = -2,
	can_trigger = function(target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local room = player:getRoom()
		if death.damage and death.damage.from and death.damage.from:hasSkill(self:objectName()) then
			room:setPlayerMark(death.damage.from, "chaogz", 1)
			room:setPlayerMark(death.damage.from, "&chaogz", 1)
		end
		return false
	end,
}
chaogzmax = sgs.CreateMaxCardsSkill {
	name = "#chaogzmax",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		end
		return 0
	end
}
chaogz_cishu = sgs.CreateTargetModSkill {
	name = "#chaogz_cishu",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end

}
chaogz_ex = sgs.CreateTriggerSkill {
	name = "#chaogz_ex",
	events = { sgs.DrawNCards, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards and player:getMark("chaogz") == 1 then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num + 2
			data:setValue(draw)
		end
		if event == sgs.DamageCaused and player:getMark("chaogz") == 1 then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				damage.damage = damage.damage + 1
				sendLog("#chaogz-increase", room, player, damage.damage, nil, damage.to)
				data:setValue(damage)
				return false
			end
		end
	end
}
extension:insertRelatedSkills("chaogz", "#chaogzmax")
extension:insertRelatedSkills("chaogz", "#chaogz_cishu")
extension:insertRelatedSkills("chaogz", "#chaogz_ex")
--圣枪
shengqiang = sgs.CreateTriggerSkill {
	name = "shengqiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified, sgs.DamageCaused, sgs.CardOffset },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
				local a = use.from:getMark("shengqiang")
				room:addPlayerMark(player, "shengqiang", a + 1)
				room:addPlayerMark(player, "&shengqiang", a + 1)
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local x = use.from:getMark("shengqiang")
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = x
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.card and damage.card:isKindOf("Slash") then
				room:setPlayerMark(player, "shengqiang", 0)
				room:setPlayerMark(player, "&shengqiang", 0)
			end
		end
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") then
				local b = player:getMark("shengqiangcs")
				room:addPlayerMark(player, "shengqiangcs", b + 1)
			end
		end
	end
}
shengqiang_cishu = sgs.CreateTargetModSkill {
	name = "#shengqiang_cishu",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMark("shengqiangcs") ~= 0 then
			return player:getMark("shengqiangcs")
		end
	end

}
shengqiang_range = sgs.CreateAttackRangeSkill {
	name = "#shengqiang_range",
	extra_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMark("shengqiangcs") ~= 0 then return player:getMark(
			"shengqiangcs") end
	end,
}
extension:insertRelatedSkills("shengqiang", "#shengqiang_cishu")
extension:insertRelatedSkills("shengqiang", "#shengqiang_range")
--炮击
paojixjCard = sgs.CreateSkillCard {
	name = "paojixj",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < self:getSubcards():length()
	end,
	feasible = function(self, targets)
		return #targets <= self:getSubcards():length() and #targets > 0
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@xjpaoj")
		for _, card_id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(card_id):isKindOf("EquipCard") then
				room:addPlayerMark(source, "paojixj", 1)
			end
		end
		for _, target in ipairs(targets) do
			local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, target))
			if source:getMark("paojixj") ~= 0 then
				local xslash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
				xslash:setSkillName(self:objectName())
				room:useCard(sgs.CardUseStruct(xslash, source, target))
			end
		end
	end
}

paojixjvs = sgs.CreateViewAsSkill {
	name = "paojixj",
	n = 4,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			return selected[1]:getSuit() ~= to_select:getSuit()
		elseif #selected == 2 then
			return selected[1]:getSuit() ~= to_select:getSuit() and selected[2]:getSuit() ~= to_select:getSuit() and
			selected[1]:getSuit() ~= selected[2]:getSuit()
		elseif #selected == 3 then
			return selected[1]:getSuit() ~= to_select:getSuit() and selected[2]:getSuit() ~= to_select:getSuit() and
			selected[1]:getSuit() ~= selected[2]:getSuit() and selected[3]:getSuit() ~= to_select:getSuit() and
			selected[1]:getSuit() ~= selected[3]:getSuit() and selected[2]:getSuit() ~= selected[3]:getSuit()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = paojixjCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@xjpaoj") >= 1
	end
}
paojixj = sgs.CreateTriggerSkill {
	name = "paojixj",
	frequency = sgs.Skill_Limited,
	view_as_skill = paojixjvs,
	limit_mark = "@xjpaoj",
	on_trigger = function()
	end
}
--盗窃精通
dqjt = sgs.CreateTriggerSkill {
	name = "dqjt",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isNude() then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			invoked = player:askForSkillInvoke(self:objectName(), data)
			if invoked then
				room:setPlayerFlag(player, "dqjt")
				local s = room:askForPlayerChosen(player, targets, self:objectName(), "@dqjtp", true, true)
				room:setPlayerFlag(player, "-dqjt")
				if s then
					local id = room:askForCardChosen(player, s, "he", self:objectName())
					room:obtainCard(player, id, false)
					local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
						"@dqjtx:::" .. sgs.Sanguosha:getCard(id):objectName(), true, true)
					if to then
						room:obtainCard(to, id, false)
					end
				end
				player:skip(sgs.Player_Play)
			end
		end
		if change.to == sgs.Player_Draw then
			local invoked = false
			if player:isSkipped(sgs.Player_Draw) then return false end
			invoked = player:askForSkillInvoke(self:objectName(), data)
			if invoked then
				room:setPlayerFlag(player, "dqjt")
				local s = room:askForPlayerChosen(player, targets, self:objectName(), "@dqjtp", true, true)
				room:setPlayerFlag(player, "-dqjt")
				if s then
					local id = room:askForCardChosen(player, s, "he", self:objectName())
					room:obtainCard(player, id, false)
					local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
						"@dqjtx:::" .. sgs.Sanguosha:getCard(id):objectName(), true, true)
					if to then
						room:obtainCard(to, id, false)
					end
				end
				player:skip(sgs.Player_Draw)
			end
		end
		return false
	end
}
--连携
lianxie = sgs.CreateTriggerSkill {
	name = "lianxie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() then
				if use.card:getTypeId() == sgs.Card_TypeSkill then return end
				if use.card:isKindOf("Slash") then
					room:setPlayerMark(player, "lianxie", 0)
				elseif (not use.card:isKindOf("BasicCard")) and player:getMark("lianxie") == 0 and room:askForSkillInvoke(player, "lianxie", data) then
					room:addPlayerMark(player, "lianxie", 1)
				end
			end
		end
	end
}
lianxie_cishu = sgs.CreateTargetModSkill {
	name = "#lianxie_cishu",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMark("lianxie") ~= 0 then
			return 999
		end
	end

}
--换装
huanzhaung = sgs.CreateTriggerSkill {
	name = "huanzhaung",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeSkill then return end
			if use.card:isKindOf("BasicCard") and not player:isNude() and room:askForSkillInvoke(player, "huanzhaung", data) then
				local card_id = room:askForCardChosen(player, player, "he", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				if card then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(),
						self:objectName(), "")
					local id = card:getId()
					local moves = sgs.CardsMoveList()
					local move = sgs.CardsMoveStruct(id, nil, sgs.Player_DiscardPile, reason)
					moves:append(move)
					room:moveCardsAtomic(moves, true)
					player:drawCards(1)
				end
			end
		end
	end
}
--新生
xinshengllCard = sgs.CreateSkillCard {
	name = "xinshengll",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:getSeat() ~= sgs.Self:getSeat() and not to_select:isKongcheng()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local data = sgs.QVariant()
		data:setValue(source)
		if room:askForSkillInvoke(target, self:objectName(), data) then
			local card_list = target:getCards("h")
			local playerlist = room:getAlivePlayers()
			local can_use = false
			local disabled_list = sgs.IntList()
			for _, card in sgs.qlist(card_list) do
				if card:targetFixed() and card:isAvailable(target) then
					can_use = true
				elseif card:targetFixed() then
					disabled_list:append(card:getId())
				else
					local enabled = false
					for _, player in sgs.qlist(playerlist) do
						if card:targetFilter(sgs.PlayerList(), player, target) and not target:isProhibited(player, card) then
							enabled = true
							can_use = true
							break
						end
					end
					if not enabled then disabled_list:append(card:getId()) end
				end
			end
			--sendLog("#geass",room,source,nil,nil,target)
			if not can_use then
				room:showAllCards(target, source)
				return false
			else
				room:showAllCards(target, source)
				local card_ids = sgs.IntList()
				for _, card in sgs.qlist(card_list) do
					card_ids:append(card:getId())
				end
				room:fillAG(card_ids, source, disabled_list)
				room:setPlayerMark(targets[1], "geass_touse", 1)
				local card_id = room:askForAG(source, card_ids, true, "xinshengll")
				room:setPlayerMark(targets[1], "geass_touse", 0)
				room:clearAG(source)
				if card_id == -1 then return false end
				if sgs.Sanguosha:getCard(card_id):isAvailable(targets[1]) then
					room:askForUseCard(targets[1], "" .. card_id, "@xinshengll")
				end
			end
		end
	end,
}

xinshengll = sgs.CreateViewAsSkill {
	name = "xinshengll",
	n = 0,
	view_as = function(self, cards)
		return xinshengllCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#xinshengll")
	end,
}
--破局
llpj = sgs.CreateTriggerSkill {
	name = "llpj",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd, sgs.EventPhaseStart },
	view_as_skill = empaiduivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName(), data) then
			room:setPlayerMark(player, "&llpj", 1)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:setPlayerCardLimitation(p, "use", "Jink", false)
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:setPlayerMark(player, "&llpj", 0)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:removePlayerCardLimitation(p, "use", "Jink")
			end
		end
	end

}
--社交
shejiaofukaCard = sgs.CreateSkillCard {
	name = "shejiaofuka",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:getMark("shejiao") >= 1
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		targets[1]:obtainCard(self, false)
	end,
}

shejiaofuka = sgs.CreateViewAsSkill {
	name = "shejiaofuka",
	n = 999,
	view_filter = function(self, selected, to_select)
		return #selected < 999
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs_card = shejiaofukaCard:clone()
		for _, card in ipairs(cards) do
			vs_card:addSubcard(card)
		end
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	response_pattern = "@@shejiaofuka",
}
shejiaoCard = sgs.CreateSkillCard {
	name = "shejiao",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:isMale() then
			return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
		else
			return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
		end
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if target:isMale() then
			room:addPlayerMark(source, "shejiao", 1)
			room:askForUseCard(target, "@@shejiaofuka", "shejiaofuka_card")
			source:setMark("shejiao", 0)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(target, recover)
		elseif target:isFemale() then
			local dest = sgs.QVariant()
			dest:setValue(target)
			local choice = room:askForChoice(source, self:objectName(), "shejiao_hf+shejiao_sq", dest)
			if choice == "shejiao_hf" then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(source, recover)
				room:recover(target, recover)
				source:gainMark("@hurt")
			else
				room:loseHp(source)
				room:loseHp(target)
				source:loseMark("@hurt")
			end
		end
	end
}

shejiao = sgs.CreateViewAsSkill {
	name = "shejiao",
	n = 0,
	view_as = function(self, cards)
		return shejiaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shejiao")
	end,
}
--决胜大衣
jsdy = sgs.CreateTriggerSkill {
	name = "jsdy",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasEquip() then
				for _, target in sgs.qlist(room:getAlivePlayers()) do
					if target:distanceTo(player) ~= 1 then continue end
					for _, p in sgs.qlist(use.to) do
						if p:isFemale() then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
							local x = 0
							for i = 0, use.to:length() - 1, 1 do
								if jink_list[i + 1] == 1 then
									jink_list[i + 1] = x
								end
							end
							local jink_data = sgs.QVariant()
							jink_data:setValue(Table2IntList(jink_list))
							player:setTag("Jink_" .. use.card:toString(), jink_data)
						end
					end
				end
			end
		end
	end
}
--婉弦
wanxian = sgs.CreateTriggerSkill {
	name = "wanxian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@wanxian", true, true)
			if s then
				local xx = player:getEquips():length()
				local mb = s:getEquips():length()
				if mb < xx then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(s, recover)
				elseif mb == xx then
					s:drawCards(damage.damage)
				elseif mb > xx then
					room:loseHp(s, 1)
				end
			end
		end
	end,
}
--连弹
liantan = sgs.CreateTriggerSkill {
	name = "liantan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd, sgs.CardFinished },
	view_as_skill = liantanvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local id = room:drawCard()
				local card = sgs.Sanguosha:getCard(id)
				room:moveCardTo(card, nil, sgs.Player_PlaceTable, true)
				if player:getMark("jibenc") == 1 and player:getMark("jinnc") == 1 and player:getMark("zhuangbeic") == 1 then
					player:setMark("jibenc", 0)
					player:setMark("jinnc", 0)
					player:setMark("zhuangbeic", 0)
					return
				end
				local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@liantan",
					true, true)
				if s then
					if player:getMark("jibenc") == 1 and player:getMark("jinnc") == 0 and player:getMark("zhuangbeic") == 0 then
						if not card:isKindOf("BasicCard") then
							local choice = room:askForChoice(s, self:objectName(), "liantan_yp+liantan_hd")
							if choice == "liantan_yp" then
								if card:isKindOf("EquipCard") then
									local ss = room:askForUseCard(s, "EquipCard|.|.|hand", "@liantansyc")
									if ss then end
									s:obtainCard(card)
								else
									local ss = room:askForUseCard(s, "TrickCard+^Nullification|.|.|hand", "@liantansyc")
									if ss then end
									s:obtainCard(card)
								end
							else
								player:obtainCard(card)
							end
						end
					elseif player:getMark("jibenc") == 0 and player:getMark("jinnc") == 1 and player:getMark("zhuangbeic") == 0 then
						if not card:isKindOf("TrickCard") then
							local choice = room:askForChoice(s, self:objectName(), "liantan_yp+liantan_hd")
							if choice == "liantan_yp" then
								if card:isKindOf("EquipCard") then
									local ss = room:askForUseCard(s, "EquipCard|.|.|hand", "@liantansyc")
									if ss then end
									s:obtainCard(card)
								else
									local ss = room:askForUseCard(s, "BasicCard+^Jink|.|.|hand", "@liantansyc")
									if ss then end
									s:obtainCard(card)
								end
							else
								player:obtainCard(card)
							end
						end
					elseif player:getMark("jibenc") == 0 and player:getMark("jinnc") == 0 and player:getMark("zhuangbeic") == 1 then
						if not card:isKindOf("EquipCard") then
							local choice = room:askForChoice(s, self:objectName(), "liantan_yp+liantan_hd")
							if choice == "liantan_yp" then
								if card:isKindOf("TrickCard") then
									local ss = room:askForUseCard(s, "TrickCard+^Nullification|.|.|hand", "@liantansyc")
									if ss then end
									s:obtainCard(card)
								else
									local ss = room:askForUseCard(s, "BasicCard+^Jink|.|.|hand", "@liantansyc")
									if ss then end
									s:obtainCard(card)
								end
							else
								player:obtainCard(card)
							end
						end
					elseif player:getMark("jibenc") == 0 and player:getMark("jinnc") == 0 and player:getMark("zhuangbeic") == 0 then
						local choice = room:askForChoice(s, self:objectName(), "liantan_yp+liantan_hd")
						if choice == "liantan_yp" then
							local ss = room:askForUseCard(s,
								"TrickCard+^Nullification,BasicCard+^Jink,EquipCard|.|.|hand|.|.|hand", "@liantansyc")
							if ss then end
							s:obtainCard(card)
						else
							player:obtainCard(card)
						end
					end
					player:setMark("jibenc", 0)
					player:setMark("jinnc", 0)
					player:setMark("zhuangbeic", 0)
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeSkill then return end
			if player:getPhase() == sgs.Player_Play then
				if use.card:isKindOf("BasicCard") then
					room:addPlayerMark(player, "jibenc", 1)
				elseif use.card:isKindOf("TrickCard") then
					room:addPlayerMark(player, "jinnc", 1)
				elseif use.card:isKindOf("EquipCard") then
					room:addPlayerMark(player, "zhuangbeic", 1)
				end
			end
		end
		return false
	end
}
--焰愈
s_yanyu = sgs.CreateTriggerSkill {
	name = "s_yanyu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			if damage.nature == sgs.DamageStruct_Fire then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				local x = math.max(math.max(player:getHandcardNum(), 2), player:getHp())
				if x > player:getHp() then
					local recover = sgs.RecoverStruct()
					recover.recover = x - player:getHp()
					recover.who = player
					room:recover(player, recover)
				end
				if player:canDiscard(player, "h") then
					room:askForDiscard(player, self:objectName(), 1, 1, false, false, "s_yanyu-invoke")
				end
			else
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = player
				damage.damage = 1
				damage.nature = sgs.DamageStruct_Fire
				room:damage(damage)
			end
		end
		return false
	end
}
--炎魔降临
s_yanmojianglinCard = sgs.CreateSkillCard {
	name = "s_yanmojianglin",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local players = room:getOtherPlayers(source)
		local max_distance = 0
		local min_distance = 999
		for _, q in sgs.qlist(players) do
			max_distance = math.max(max_distance, source:distanceTo(q))
			min_distance = math.min(min_distance, source:distanceTo(q))
		end
		for _, p in sgs.qlist(players) do
			if p:isAlive() then
				if source:distanceTo(p) == max_distance then
					room:setPlayerMark(source, "yanmomax_turn", 1)
					room:cardEffect(self, source, p)
				end
			end
		end
		for _, p in sgs.qlist(players) do
			if p:isAlive() then
				if source:distanceTo(p) == min_distance then
					room:cardEffect(self, source, p)
				end
			end
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local source = effect.from
		local choicelist = "s_yanmojianglin_damage"
		if source:getMark("yanmomax_turn") > 0 then
			choicelist = string.format("%s+%s", choicelist, "s_yanmojianglin_skipplay")
			room:setPlayerMark(source, "yanmomax_turn", 0)
		else
			if effect.to:canDiscard(effect.to, "h") then
				choicelist = string.format("%s+%s", choicelist, "s_yanmojianglin_throwcard")
			end
		end
		local choice = room:askForChoice(effect.to, self:objectName(), choicelist)
		if choice == "s_yanmojianglin_throwcard" then
			effect.to:throwAllHandCards()
		elseif choice == "s_yanmojianglin_skipplay" then
			room:setPlayerFlag(effect.to, "s_yanmojianglin_skipplay")
		elseif choice == "s_yanmojianglin_damage" then
			local damage = sgs.DamageStruct()
			damage.to = effect.to
			damage.damage = 1
			room:damage(damage)
		end
	end
}
s_yanmojianglinVS = sgs.CreateViewAsSkill {
	name = "s_yanmojianglin",
	n = 0,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = s_yanmojianglinCard:clone()
			card:addSubcards(sgs.Self:getHandcards())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s_yanmojianglin") and player:getHandcardNum() >= 3
	end
}
s_yanmojianglin = sgs.CreateTriggerSkill {
	name = "s_yanmojianglin",
	events = { sgs.EventPhaseChanging },
	view_as_skill = s_yanmojianglinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play and player:isAlive() and player:hasFlag("s_yanmojianglin_skipplay") and not player:isSkipped(sgs.Player_Play) then
			player:skip(sgs.Player_Play)
			room:setPlayerFlag(player, "-s_yanmojianglin_skipplay")
			local log = sgs.LogMessage()
			log.type = "#s_yanmojianglin_skipplay"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--连结
s_lianjieCard = sgs.CreateSkillCard {
	name = "s_lianjie",
	will_throw = true,
	filter = function(self, targets, to_select)
		return not to_select:hasSkill("s_lianjie") and #targets == 0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.to:drawCards(1)
		room:handleAcquireDetachSkills(effect.to, "s_lianjie")
	end
}
s_lianjie = sgs.CreateViewAsSkill {
	name = "s_lianjie",
	n = 0,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s_lianjie")
	end,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return s_lianjieCard:clone()
		end
	end
}
--破裂
s_polieCard = sgs.CreateSkillCard {
	name = "s_polie",
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:hasSkill("s_lianjie")
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			if target:hasSkill("s_lianjie") then
				room:handleAcquireDetachSkills(target, "-s_lianjie")
			end
		end
		if #targets > 0 then
			local tos = sgs.SPlayerList()
			for _, target in ipairs(targets) do
				if source:canDiscard(target, "he") then
					tos:append(target)
				end
			end
			if not tos:isEmpty() then
				local prompt = string.format("s_polie_dis:%s", #targets)
				local dest = room:askForPlayerChosen(source, tos, "s_polie", prompt, false, true)
				room:setPlayerFlag(dest, "s_polie_InTempMoving")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
				local card_ids = sgs.IntList()
				local original_places = sgs.IntList()
				for i = 0, #targets - 1, 1 do
					if dest:isNude() then break end
					card_ids:append(room:askForCardChosen(source, dest, "he", self:objectName(), false,
						sgs.Card_MethodNone))
					original_places:append(room:getCardPlace(card_ids:at(i)))
					dummy:addSubcard(card_ids:at(i))
					dest:addToPile("#s_polie", card_ids:at(i), false)
				end
				for i = 0, dummy:subcardsLength() - 1, 1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), dest, original_places:at(i), false)
				end
				room:setPlayerFlag(dest, "-s_polie_InTempMoving")
				if dummy:subcardsLength() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, source:objectName(), "s_polie",
						"")
					room:throwCard(dummy, reason, dest, source)
				end
			end
		end
	end
}
s_polieVS = sgs.CreateViewAsSkill {
	name = "s_polie",
	n = 0,
	enabled_at_play = function(self, player)
		local can_invoke = false
		for _, p in sgs.qlist(player:getSiblings()) do
			if p:hasSkill("s_lianjie") then
				can_invoke = true
				break
			end
		end
		return can_invoke or player:hasSkill("s_lianjie")
	end,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return s_polieCard:clone()
		end
	end
}
s_polie = sgs.CreateTriggerSkill {
	name = "s_polie",
	events = { sgs.CardsMoveOneTime },
	view_as_skill = s_polieVS,
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local room = player:getRoom()
		if move.from and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
			if move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.reason.m_skillName == self:objectName() then
				if move.from:isNude() then
					local target
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:objectName() == move.from:objectName() then
							target = p
						end
					end
					local log = sgs.LogMessage()
					log.type = "#s_polie_damage"
					log.from = player
					log.to:append(target)
					log.arg = self:objectName()
					room:sendLog(log)
					local damage = sgs.DamageStruct()
					damage.to = target
					damage.from = player
					damage.damage = 1
					room:damage(damage)
				end
			end
		end
		return false
	end
}


s_polie_InTempMoving = sgs.CreateTriggerSkill {
	name = "#s_polie_InTempMoving",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("s_polie_InTempMoving") then
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--睡眠
s_shuimian = sgs.CreateProhibitSkill {
	name = "s_shuimian",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("s_shuimian") and (card:isKindOf("Indulgence"))
	end
}
s_shuimian_tr = sgs.CreateTriggerSkill {
	name = "#s_shuimian_tr",
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Judge then return false end
			local card = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0)
			card:deleteLater()
			local on_effect = room:cardEffect(card, nil, player)
			-- if not (on_effect) then
			-- 	card:onNullified(player)
			-- end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_Play and player:isSkipped(sgs.Player_Play) then
				room:setPlayerMark(player, "s_shuimian_skipped", 1)
			end
			if change.from and change.from == sgs.Player_Play then
				if player:getMark("s_shuimian_skipped") > 0 then
					room:setPlayerMark(player, "s_shuimian_skipped", 0)
					local choicelist = "s_shuimian_skipdiscard"
					if player:isWounded() then
						choicelist = string.format("%s+%s", choicelist, "s_shuimian_recover")
					end
					local choice = room:askForChoice(player, "s_shuimian", choicelist)
					if choice == "s_shuimian_recover" then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					else
						player:skip(sgs.Player_Discard)
					end
				end
			end
		end
	end
}
--借宿
s_jieshu = sgs.CreateTriggerSkill {
	name = "s_jieshu",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish then return false end
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not (p:isKongcheng() or player:isKongcheng()) or not p:hasSkill("s_fudao") then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "s_jieshu-invoke", true, true)
			if target then
				local choicelist = "cancel"
				if not target:hasSkill("s_fudao") then
					choicelist = string.format("%s+%s", choicelist, "s_jieshu_skill")
				end
				if not player:isKongcheng() and not target:isKongcheng() then
					choicelist = string.format("%s+%s", choicelist, "s_jieshu_pindian")
				end
				local dest = sgs.QVariant()
				dest:setValue(target)
				local choice = room:askForChoice(player, self:objectName(), choicelist, dest)
				if choice == "s_jieshu_skill" then
					room:handleAcquireDetachSkills(target, "s_fudao")
				elseif choice == "s_jieshu_pindian" then
					local success = player:pindian(target, "s_jieshu", nil)
					if success then
						player:drawCards(2)
						player:setPhase(sgs.Player_Play)
						room:broadcastProperty(player, "phase")
						local thread = room:getThread()
						if not thread:trigger(sgs.EventPhaseStart, room, player) then
							thread:trigger(sgs.EventPhaseProceeding, room, player)
						end
						thread:trigger(sgs.EventPhaseEnd, room, player)
						player:setPhase(sgs.Player_Finish)
						room:broadcastProperty(player, "phase")
					else
						room:handleAcquireDetachSkills(target, "s_fudao")
					end
				end
			end
		end
	end
}
--辅导
s_fudaoCard = sgs.CreateSkillCard {
	name = "s_fudao",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, selected, to_select)
		return (#selected == 0) and
		(string.find(to_select:getGeneralName(), "htms_bifang") or string.find(to_select:getGeneral2Name(), "htms_bifang"))
	end,
	on_use = function(self, room, source, targets)
		local choicelist = "s_fudao_play"
		if source:canDiscard(targets[1], "he") then
			choicelist = string.format("%s+%s", choicelist, "s_fudao_discard")
		end
		local dest = sgs.QVariant()
		dest:setValue(targets[1])
		local choice = room:askForChoice(source, "s_fudao", choicelist, dest)
		if choice == "s_fudao_discard" then
			local to_throw = room:askForCardChosen(source, targets[1], "he", self:objectName(), false,
				sgs.Card_MethodDiscard)
			room:throwCard(sgs.Sanguosha:getCard(to_throw), targets[1], source)
		else
			local target = sgs.QVariant()
			target:setValue(targets[1])
			room:setTag("s_fudao_play", target)
		end
	end
}
s_fudaoVS = sgs.CreateViewAsSkill {
	name = "s_fudao",
	n = 0,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return s_fudaoCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		local can_invoke = false
		for _, p in sgs.qlist(player:getSiblings()) do
			if string.find(p:getGeneralName(), "htms_bifang") or string.find(p:getGeneral2Name(), "htms_bifang") then --
				can_invoke = true
				break
			end
		end
		return can_invoke
	end
}
s_fudao = sgs.CreateTriggerSkill {
	name = "s_fudao",
	events = { sgs.EventPhaseChanging },
	view_as_skill = s_fudaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play and room:getTag("s_fudao_play") then
				local target = room:getTag("s_fudao_play"):toPlayer()
				room:removeTag("s_fudao_play")
				if target and target:isAlive() then
					local phase = sgs.PhaseList()
					phase:append(sgs.Player_Play)
					target:play(phase)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--抖M
s_douM = sgs.CreateTriggerSkill {
	name = "s_douM",
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:getMark(self:objectName() .. "-Clear") == 0 and move.from and move.from:isAlive() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and ((move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE
					and move.reason.m_playerId ~= move.reason.m_targetId)
				or (move.to and move.to:objectName() ~= move.from:objectName() and move.to_place == sgs.Player_PlaceHand
					and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE
					and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP)) then
			local invoke = room:askForSkillInvoke(player, self:objectName(), data)
			if invoke then
				room:addPlayerMark(player, self:objectName() .. "-Clear")
				room:addPlayerMark(player, "&" .. self:objectName() .. "-Clear")
				room:drawCards(player, 2, "s_douM")
				if (move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and move.reason.m_playerId ~= move.reason.m_targetId) then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:objectName() == move.reason.m_playerId then
							if p:canDiscard(player, "he") then
								local to_throw = room:askForCardChosen(p, player, "he", self:objectName(), false,
									sgs.Card_MethodDiscard)
								room:throwCard(sgs.Sanguosha:getCard(to_throw), player, p)
							end
							break
						end
					end
				end
				if (move.to and move.to:objectName() ~= move.from:objectName() and move.to_place == sgs.Player_PlaceHand
						and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE
						and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP) then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:objectName() == move.to:objectName() then
							if not player:isNude() then
								local card_id = room:askForCardChosen(p, player, "he", self:objectName())
								local card = sgs.Sanguosha:getCard(card_id)
								p:obtainCard(card)
							end
							break
						end
					end
				end
			end
		end
	end
}
--十字骑士
s_shiziqishi = sgs.CreateTriggerSkill {
	name = "s_shiziqishi",
	events = { sgs.DamageCaused, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused or event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and
				(damage.from:objectName() == player:objectName() or damage.to:objectName() == player:objectName()) and player:getMark(self:objectName() .. "_lun") == 0 then
				room:addPlayerMark(player, self:objectName() .. "_lun")
				room:addPlayerMark(player, "&" .. self:objectName() .. "_lun")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				if damage.to:canDiscard(damage.to, "he") then
					room:askForDiscard(damage.to, self:objectName(), 1, 1, false, true, "s_shiziqishi-invoke")
				end
				return true
			end
		end
	end,
}
--空移
s_kongyiCard = sgs.CreateSkillCard {
	name = "s_kongyi",
	will_throw = false,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	handling_method = sgs.Card_MethodNone,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local log = sgs.LogMessage()
		log.type = "#s_kongyi_num"
		log.from = effect.from
		log.arg = self:subcardsLength()
		room:sendLog(log)
		local choicelist = "s_kongyi_damage"
		local tos = sgs.SPlayerList()
		local list = room:getAlivePlayers()
		if (effect.to:getJudgingArea():length() > 0) or not effect.to:getEquips():isEmpty() then
			local can_invoke = true
			for _, trick in sgs.qlist(effect.to:getJudgingArea()) do
				for _, p in sgs.qlist(list) do
					if not effect.from:isProhibited(p, trick) and not p:containsTrick(trick:objectName()) then
						choicelist = string.format("%s+%s", choicelist, "s_kongyi_movefield")
						can_invoke = false
						break
					end
				end
			end
			if can_invoke then
				for _, equip in sgs.qlist(effect.to:getEquips()) do
					for _, p in sgs.qlist(list) do
						if (equip:isKindOf("Weapon") and not p:getWeapon()) or (equip:isKindOf("Armor") and not p:getArmor()) or
							(equip:isKindOf("DefensiveHorse") and not p:getDefensiveHorse()) or (equip:isKindOf("OffensiveHorse") and not p:getOffensiveHorse()) or (equip:isKindOf("Treasure") and not p:hasEquipArea(4)) then
							choicelist = string.format("%s+%s", choicelist, "s_kongyi_movefield")
							break
						end
					end
				end
			end
		end
		if effect.to:getHandcardNum() >= self:subcardsLength() then
			choicelist = string.format("%s+%s", choicelist, "s_kongyi_handcard")
			room:setPlayerMark(effect.to, "s_kongyi_num", self:subcardsLength())
		end
		local dest = sgs.QVariant()
		dest:setValue(effect.from)
		local choice = room:askForChoice(effect.to, self:objectName(), choicelist, dest)
		room:setPlayerMark(effect.to, "s_kongyi_num", 0)
		if choice == "s_kongyi_damage" then
			local damage = sgs.DamageStruct()
			damage.to = effect.to
			damage.damage = 1
			room:damage(damage)
			effect.to:obtainCard(self)
		elseif choice == "s_kongyi_handcard" then
			room:setPlayerFlag(effect.to, "s_kongyi_InTempMoving")
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local card_ids = sgs.IntList()
			local original_places = sgs.IntList()
			for i = 0, self:subcardsLength() - 1, 1 do
				if effect.to:isKongcheng() then break end
				card_ids:append(room:askForCardChosen(effect.from, effect.to, "h", self:objectName(), false,
					sgs.Card_MethodNone))
				original_places:append(room:getCardPlace(card_ids:at(i)))
				dummy:addSubcard(card_ids:at(i))
				effect.to:addToPile("#s_kongyi", card_ids:at(i), false)
			end
			for i = 0, dummy:subcardsLength() - 1, 1 do
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), effect.to, original_places:at(i), false)
			end
			room:setPlayerFlag(effect.to, "-s_kongyi_InTempMoving")
			effect.from:obtainCard(dummy)
			local dest = room:askForPlayerChosen(effect.from, room:getAlivePlayers(), self:objectName(),
				"s_kongyi-invoke", true, true)
			if dest then
				dest:obtainCard(dummy)
			end
		elseif choice == "s_kongyi_movefield" then
			local list = room:getAlivePlayers()
			if (effect.to:getJudgingArea():length() > 0) or not effect.to:getEquips():isEmpty() then
				local card_id = room:askForCardChosen(effect.from, effect.to, "ej", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local i = -1
				if place == sgs.Player_PlaceEquip then
					if card:isKindOf("Weapon") then
						i = 1
					end
					if card:isKindOf("Armor") then
						i = 2
					end
					if card:isKindOf("DefensiveHorse") then
						i = 3
					end
					if card:isKindOf("OffensiveHorse") then
						i = 4
					end
					if card:isKindOf("Treasure") then
						i = 5
					end
				end
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _, p in sgs.qlist(list) do
					if i ~= -1 then
						if i == 1 then
							if not p:getWeapon() then
								tos:append(p)
							end
						end
						if i == 2 then
							if not p:getArmor() then
								tos:append(p)
							end
						end
						if i == 3 then
							if not p:getDefensiveHorse() then
								tos:append(p)
							end
						end
						if i == 4 then
							if not p:getOffensiveHorse() then
								tos:append(p)
							end
						end
						if i == 5 then
							if not p:getTreasure() then
								tos:append(p)
							end
						end
					else
						if not effect.from:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
							tos:append(p)
						end
					end
				end
				if tos:isEmpty() then return false end
				local dest = sgs.QVariant()
				dest:setValue(effcet.to)
				room:setTag("s_kongyiTarget", dest)
				local to = room:askForPlayerChosen(effect.from, tos,
					string.format("s_kongyi_getfield:%s", card:objectName()))
				room:removeTag("s_kongyiTarget")
				if to then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, effect.from:objectName(),
						self:objectName(), "")
					room:moveCardTo(card, from, to, place, reason)
				end
			end
		end
	end
}
s_kongyi = sgs.CreateViewAsSkill {
	name = "s_kongyi",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = s_kongyiCard:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s_kongyi")
	end
}
s_kongyi_InTempMoving = sgs.CreateTriggerSkill {
	name = "#s_kongyi_InTempMoving",
	events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("s_kongyi_InTempMoving") then
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--跃迁
s_yueqian = sgs.CreateTriggerSkill {
	name = "s_yueqian",
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if (player:getJudgingArea():length() > 0) or not player:getEquips():isEmpty() and player:askForSkillInvoke(self:objectName(), data) then
				local card_id = room:askForCardChosen(player, player, "ej", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local i = -1
				if place == sgs.Player_PlaceEquip then
					if card:isKindOf("Weapon") then
						i = 1
					end
					if card:isKindOf("Armor") then
						i = 2
					end
					if card:isKindOf("DefensiveHorse") then
						i = 3
					end
					if card:isKindOf("OffensiveHorse") then
						i = 4
					end
					if card:isKindOf("Treasure") then
						i = 5
					end
				end
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _, p in sgs.qlist(list) do
					if i ~= -1 then
						if i == 1 then
							if not p:getWeapon() then
								tos:append(p)
							end
						end
						if i == 2 then
							if not p:getArmor() then
								tos:append(p)
							end
						end
						if i == 3 then
							if not p:getDefensiveHorse() then
								tos:append(p)
							end
						end
						if i == 4 then
							if not p:getOffensiveHorse() then
								tos:append(p)
							end
						end
						if i == 5 then
							if not p:getTreasure() then
								tos:append(p)
							end
						end
					else
						if not effect.from:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
							tos:append(p)
						end
					end
				end
				if tos:isEmpty() then return false end
				local to = room:askForPlayerChosen(player, tos, string.format("#s_yueqian:%s", card:objectName()))
				if to then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(),
						self:objectName(), "")
					room:moveCardTo(card, from, to, place, reason)
					return true
				end
			end
		end
	end,
}
--新人类
function generateAllCardObjectNameTablePatterns()
	local patterns = {}
	for i = 0, 10000 do
		local card = sgs.Sanguosha:getEngineCard(i)
		if card == nil then break end
		if (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and not table.contains(patterns, card:objectName()) then
			table.insert(patterns, card:objectName())
		end
	end
	return patterns
end

function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end

local pos = 0
s_newtype_select = sgs.CreateSkillCard {
	name = "s_newtype",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		local dest = room:getCurrent()
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(dest) and (card:isKindOf("BasicCard") or card:isNDTrick()) then
					table.insert(choices, card:objectName())
				end
			end
		end
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "s_newtype", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				poi:deleteLater()
				local log = sgs.LogMessage()
				log.type = "#s_newtype_choice"
				log.from = source
				log.to:append(dest)
				log.arg = pattern
				room:sendLog(log)
				room:setPlayerProperty(source, "s_newtype", sgs.QVariant(poi:toString()))
				room:addPlayerMark(dest, "&s_newtype+" .. pattern .. "+to+#" .. source:objectName() .. "-Clear")
				room:addPlayerMark(dest, "s_newtype" .. source:objectName() .. "-Clear")
				pos = getPos(patterns, pattern)
				room:setPlayerMark(source, "s_newtypepos", pos)
			end
		end
	end
}
s_newtypeVS = sgs.CreateViewAsSkill {
	name = "s_newtype",
	n = 0,
	view_as = function(self, cards)
		local acard = s_newtype_select:clone()
		return acard
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@s_newtype")
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
s_newtype = sgs.CreateTriggerSkill
	{
		name = "s_newtype",
		view_as_skill = s_newtypeVS,
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded },
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:hasSkill("s_newtypeOther") then
						room:attachSkillToPlayer(p, "s_newtypeOther")
					end
				end
			elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:detachSkillFromPlayer(p, "s_newtypeOther", true)
				end
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Play then
					for _, amuro in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						local target = sgs.QVariant()
						target:setValue(player)
						if (amuro and amuro:objectName() ~= player:objectName()) and amuro:getMark(self:objectName() .. "_lun") == 0 and room:askForSkillInvoke(amuro, self:objectName(), target) then
							room:setPlayerMark(amuro, self:objectName() .. "_lun", 1)
							room:setPlayerMark(amuro, "&" .. self:objectName() .. "_lun", 1)
							room:setPlayerFlag(player, "s_newtype")
							player:drawCards(2)
							room:askForUseCard(amuro, "@@s_newtype", "@s_newtype")
							room:setPlayerMark(player, "s_newtype-Clear", 1)
						end
					end
				end
				if player:getPhase() == sgs.Player_Finish then
					if player:getMark("s_newtype-Clear") > 0 then
						room:removePlayerMark(player, "s_newtype-Clear")
						for _, amuro in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if player:getMark("s_newtype" .. amuro:objectName() .. "-Clear") > 0 then
								local card = amuro:property("s_newtype"):toString()
								local prompt = string.format("@s_newtypeOther:%s", card)
								room:askForUseCard(player, "@@s_newtypeOther", prompt)
							end
							room:setPlayerProperty(amuro, "s_newtype", sgs.QVariant(""))
						end
					end
				end
			elseif player:getPhase() == sgs.Player_Play and (event == sgs.CardUsed or event == sgs.CardResponded) and player:hasFlag("s_newtype") then
				local card
				if event == sgs.CardUsed then
					card = data:toCardUse().card
				else
					local response = data:toCardResponse()
					if response.m_isUse then
						card = response.m_card
					end
				end
				local patterns = generateAllCardObjectNameTablePatterns()


				if card and card:getHandlingMethod() == sgs.Card_MethodUse and player:getMark("s_newtype-Clear") > 0 then
					room:removePlayerMark(player, "s_newtype-Clear")
					if player:getMark("s_newtype-Clear") == 0 then
						for _, amuro in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if player:getMark("s_newtype" .. amuro:objectName() .. "-Clear") > 0 then
								local pattern = patterns[amuro:getMark("s_newtypepos")]
								if card:objectName() ~= pattern then
									local log = sgs.LogMessage()
									log.type = "#s_newtype_limit"
									log.from = amuro
									log.to:append(player)
									log.arg = card:objectName()
									log.arg2 = pattern
									room:sendLog(log)
									room:setPlayerCardLimitation(player, "use", ".", true)
								end
							end
						end
					end
				end
			end
			return false
		end,
		can_trigger = function(self, target)
			return target
		end,
	}

s_newtypeOtherCard = sgs.CreateSkillCard {
	name = "s_newtypeOther",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and
				not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+") then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(user, "s_newtypeOther", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:setSkillName("s_newtype")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+") then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(card_use.from, "s_newtype", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("s_newtype")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card) then
				available = false
				break
			end
		end
		if not available then return nil end
		return use_card
	end
}
s_newtypeOther = sgs.CreateViewAsSkill {
	name = "s_newtypeOther&",
	n = 0,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "slash" then
			pattern = "slash+thunder_slash+fire_slash"
		end
		local acard = s_newtypeOtherCard:clone()
		if pattern and (sgs.Sanguosha:getCurrentCardUsePattern() == "@@s_newtypeOther") then
			pattern = patterns[sgs.Self:getMark("s_newtypepos")]
		end
		if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
			pattern = "analeptic"
		end
		acard:setUserString(pattern)
		return acard
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s_newtypeOther"
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}


--技能暗将
hidden_player:addSkill(zyjianshu)
hidden_player:addSkill(zyfashi)
hidden_player:addSkill(zymushi)
hidden_player:addSkill(zymushijl)
hidden_player:addSkill(zycike)
hidden_player:addSkill(zycike_InTempMoving)
hidden_player:addSkill(zydadun)
hidden_player:addSkill(guichan)
hidden_player:addSkill(smsy)
hidden_player:addSkill(shilianEX)
hidden_player:addSkill(duanzui)
hidden_player:addSkill(fuzou_filter)
hidden_player:addSkill(tisheng)
hidden_player:addSkill(weixiaojn)
hidden_player:addSkill(duancaiex)
hidden_player:addSkill(ujlianjig)
hidden_player:addSkill(wzgz)
hidden_player:addSkill(gxzhiliao)
hidden_player:addSkill(shenpan)
hidden_player:addSkill(shejiaofuka)
hidden_player:addSkill(s_fudao)
hidden_player:addSkill(s_newtypeOther)
--技能添加
--赤瞳
chitong:addSkill(zhuisha)
chitong:addSkill(zhuisha_mod)
chitong:addSkill(htms_zangsong)
chitong:addSkill(zangsongTargetMod)
extension:insertRelatedSkills("htms_zangsong", "#zangsongTargetMod")
-- chitong:addSkill(ansha)
--海格力斯
--haigls:addSkill(shilian)
haigls:addSkill(shilianEX)
--haigls:addSkill(zzsl)
--haigls:addSkill(zzsl_count)
--haigls:addSkill(shilian_usingjudge)
--缠流子
chanlz:addSkill(xianxsy_cishu)
chanlz:addSkill(xianxuefeiteng)
chanlz:addSkill(xianxsy_range)
chanlz:addSkill(xianxsy_target)
chanlz:addSkill(xianxsy_spmax)
--c8
aer:addSkill(newfengwangVS)
aer:addSkill(wangzheEX)
aer:addSkill(wangzhe)
--桐人
Kirito:addSkill(doubleslash)
Kirito:addSkill(doubleslashMod)
Kirito:addSkill(betacheater)
Kirito:addRelateSkill("htms_rishi")
--立华奏
--TachibanaKanade:addSkill(howling)
TachibanaKanade:addSkill(handsonic)
--四糸乃
Yoshino:addSkill(defencefield)
Yoshino:addSkill(frozenpuppet)
Yoshino:addSkill(frozenpuppetPS)
--初音未来
chuyin:addSkill(chuszy)
chuyin:addSkill(htms_xiaoshi)
--夜刀神十香
ydssx:addSkill(mie)
ydssx:addSkill(Luazuihou)
ydssx:addSkill(Luabei1)
ydssx:addSkill(Luabei2)
ydssx:addSkill(Luazuihouturn)
--加贺
jiahe:addSkill(Luajianzai)
jiahe:addSkill(Luajianzai_keep)
--炮姐
paoj:addSkill(leij)
paoj:addSkill(leijEx)
paoj:addSkill(diancp)
--夕立
xili_gai:addSkill(Luaemeng)
--xili_gai:addSkill(kuangquan)
--川内
chuannei:addSkill(Luayezhan)
chuannei:addSkill(LuayezhanBuff)
--黑雪姬
heixueji:addSkill(jiasugaobai)
heixueji:addSkill(juedoujiasu)
heixueji:addSkill(jiasuduijue)
--本多二代
bended:addSkill(qingtq)
bended:addSkill(qingtq_keep)
bended:addSkill(qingtq_keep_keep)
bended:addSkill(xiangy)
--鹿目圆香
lumuyuanxiang:addSkill(jiujideqiyuan)
lumuyuanxiang:addSkill(fazededizao)
--桂木桂马
guimgm:addSkill(gonglzs)
guimgm:addSkill(shens)
--诱宵美九
youxmj:addSkill(pojgj)
youxmj:addSkill(hunq)
--吹雪
chuixue:addSkill(Luamuguan)
chuixue:addSkill(LuamuguanVS)
chuixue:addSkill(LuamuguanBuff)
--杏子
sakurakyouko:addSkill(soulfire)
sakurakyouko:addSkill(jfxl)
--夏娜
xiana:addSkill(zhenhongslash)
xiana:addSkill(tprs)
xiana:addRelateSkill("duanzui")

--爱尔奎特
aierkuite:addSkill(meihuomoyan)
--七罪
qizui:addSkill(kaleidoscope)
qizui:addSkill(haniel)
--秋濑或
qiulaihuo:addSkill(guancha)
qiulaihuo:addSkill(jiyi)
--赤城
chicheng:addSkill(Luayihang)
chicheng:addSkill(Luachicheng)
chicheng:addSkill(Luayihangpai)
--聂普迪努
--niepdl:addSkill(zhujuexz)
niepdl:addSkill(lianjiqudong)
niepdl:addSkill(moyu)
--晓美焰
xiaomeiyan:addSkill(pocdsf)
xiaomeiyan:addSkill(lunhui1)
xiaomeiyan:addSkill(lunhui)
--德丽莎
Theresa:addSkill(lolita)
Theresa:addSkill(judas)
--逆回十六夜
nihuisly:addSkill(yuandian)
nihuisly:addSkill(moxing)
--雪风
xuefeng:addSkill(xiangrui)
--上条当麻
dangma:addSkill(wnlz)
dangma:addSkill(hxss)
dangma:addSkill(hxssxx)
dangma:addSkill(hxss_mod)
--亚丝娜
yasina:addSkill(Luachuyi)
yasina:addSkill(Lualianji)
--伊卡洛斯
yikls:addSkill(kznw)
--鲁鲁修
lulux:addSkill(geass)
--结衣
jieyi:addSkill(znai)
jieyi:addSkill(znaiex)
jieyi:addSkill(changedfate)
--坂井悠二
youer:addSkill(lsmz)
--youer:addSkill(bhjz)
youer:addSkill(tmsp_more_slash)
youer:addSkill(tmsp)
extension:insertRelatedSkills("tmsp", "#tmsp")
--吉尔伽美什
jejms:addSkill(wangzbk)
jejms:addSkill(bings)
jejms:addSkill(guailj)
--奴良陆生
nlls:addSkill(zhou)
nlls:addSkill(ye)
--优纪
youj:addSkill(dafan)
youj:addSkill(juej)
--卡卡罗特
kklt:addSkill(jiewq)
kklt:addSkill(saiya)
--悟空
--swk:addSkill(gbg)
--swk:addSkill(zizai)
--间崎鸣
jianqm:addSkill(bczzr)
jianqm:addSkill(bczzrClear)
jianqm:addSkill(bczzrProhibit)
jianqm:addSkill(mozy)
jianqm:addSkill(mozybuff)
jianqm:addSkill(mozyProhibit)
--两仪式
liangys:addSkill(qsas)
liangys:addSkill(zsmy)
--绯村剑心
feicunjianxin:addSkill(nirendao)
feicunjianxin:addSkill(nidaoren)
feicunjianxin:addSkill(nidaorenDis)
feicunjianxin:addSkill(badaozhai)
--波风水门
bfsm:addSkill(feils)
bfsm:addSkill(jssg)
--羽入
yuru:addSkill(kuixin)
--言和
yanhe:addSkill(jiushu)
yanhe:addSkill(xieheng)
--美树沙耶香
mssyx:addSkill(tjdzf)
mssyx:addSkill(qrdag)
--我妻由乃
woqiyounai:addSkill(fenmao)
woqiyounai:addRelateSkill("changgui")
woqiyounai:addRelateSkill("heihua")
gasaiyuno:addSkill(changgui)
gasaiyuno:addSkill(heihua)
--古手梨花
gushoulihua:addSkill(samsara)
gushoulihua:addSkill(samsaraGive)
extension:insertRelatedSkills("samsara", "#samsara-give")
gushoulihua:addSkill(zuihoudefanji)
--欧根亲王
ougenqinwang:addSkill(zhanxianfanyu)
ougenqinwang:addSkill(businiao)
--高文
gaowen:addSkill(jixieshenchain)
gaowen:addSkill(jixieshen)
--革命机
gemingji:addSkill(jixieshenslash)
gemingji:addSkill(jixieshen)
--拂晓
fuxiao:addSkill(jixieshendefense)
fuxiao:addSkill(jixieshen)
--斯洛卡伊
siluokayi:addSkill(jixieshen)
siluokayi:addRelateSkill("jixieshendefense")
siluokayi:addRelateSkill("jixieshenslash")
siluokayi:addRelateSkill("jixieshenchain")
--時雨
shigure:addSkill(loyal_inu)
shigure:addSkill(DSTP)
shigure:addSkill(kikann)
--黑岩射手
BlackRockShooter:addSkill(guangzijupao)
BlackRockShooter:addRelateSkill("jueduiyazhi")
BlackRockShooter:addSkill(lanyuhua)
BlackRockShooter:addSkill(lanyuhuaAtR)
BlackRockShooter:addSkill(lanyuhuaSla)
--BlackRockShooter:addSkill(lanyuhuaMxC)
BlackRockShooter:addSkill(kuanghua)
extension:insertRelatedSkills("lanyuhua", "#lanyuhuaAtR")
extension:insertRelatedSkills("lanyuhua", "#lanyuhuaSla")
--extension:insertRelatedSkills("lanyuhua", "#lanyuhuaMxC")
--千代田
qiandaitian:addSkill(jinhua)
qiandaitian:addSkill(wuduan)
--武藏
htms_wuzang:addSkill(Luayumian)
htms_wuzang:addSkill(Luayanhu)
--津島善子
ts_yoshiko:addSkill(xinsuo)
ts_yoshiko:addSkill(yohane)
ts_yoshiko:addSkill(fengfu)
ts_yoshiko:addSkill(mingchuan)
--曜
you:addSkill(fanyi)
you:addSkill(jihang)
--ruby
extension:insertRelatedSkills("jiaoxing", "#jiaoxing")
ruby:addSkill(jiaoxing)
ruby:addSkill(jiaoxingUse)
ruby:addSkill(anni)
--小鸟游六花
extension:insertRelatedSkills("xieyan", "#xieyan_tri")
tk_rikka:addSkill(sandun)
tk_rikka:addSkill(xieyan)
tk_rikka:addSkill(xieyan_tri)
--片冈优希
kataokayuuki:addSkill(chibing)
kataokayuuki:addSkill(sugong)
kataokayuuki:addSkill(sugongst)
extension:insertRelatedSkills("sugong", "#sugongst")
--松浦果南
kanan:addSkill(fuqian)
kanan:addSkill(huanggui)
--小原鞠莉
oh_mari:addSkill(htms_wanlan)
oh_mari:addSkill(tianqu)
--樱内梨子
riko:addSkill(haiyin)
riko:addSkill(fuzou)
--剑术赤瞳
Akame:addSkill(zangsong)
Akame:addSkill(jianwushu)
--瓦沙克
washake:addSkill(huoliquankai)
washake:addSkill(juexingmoshen)
--贝卡斯
beikasi:addSkill(jichengzhe)
beikasi:addSkill(jichengzhe1)
extension:insertRelatedSkills("jichengzhe", "#jichengzhe1")
beikasi:addSkill(Cjiyongbing)
--赫萝
heluo:addSkill(wujinzhishu)
heluo:addSkill(chunrijilu)
--天江衣
amaekoromo:addSkill(haite)
amaekoromo:addSkill(yueying)
amaekoromo:addSkill(yueyingMaxCard)
extension:insertRelatedSkills("yueying", "#yueying")
--晓美焰（弓）
homura:addSkill(hmrleiji)
homura:addSkill(jiyidiejia)
--五更琉璃
gokoururi:addSkill(dushe)
gokoururi:addSkill(myjl)
gokoururi:addSkill(myjlFilter)
gokoururi:addSkill(zuzhou)
extension:insertRelatedSkills("myjl", "#myjl-filter")
--由乃
yuno:addSkill(zhiyujz_jx)
yuno:addSkill(xys_ex)
yuno:addSkill(xiangyangshi)
yuno:addSkill(jzxymianyi)
--由乃.经验ver
yuno_jy:addSkill(zhiyujz)
yuno_jy:addSkill(leijijingyan)
yuno_jy:addSkill(leijijyb)
--由乃.圣诞ver
yuno_cm:addSkill(zhiyujz_jz)
yuno_cm:addSkill(jzxymianyi)
yuno_cm:addSkill(shengdanny)
--朝田诗乃
shinai:addSkill(jujiman)
shinai:addSkill(yinbiman)
shinai:addSkill(suoersiman)
--黑泽黛雅
penguin:addSkill(yushicp)
penguin:addSkill(mingduan)
--诺瓦露
Noire:addSkill(wushitexing)
Noire:addSkill(wstxbuff)
Noire:addSkill(meipengyou)
--剑速亚丝娜
jsyasina:addSkill(shanyao)
jsyasina:addSkill(jiansu)
--基德
jide:addSkill(yugao)
--jide:addSkill(yugaoks)
--jide:addSkill(yugaobp)
jide:addSkill(guaidao)
--阎魔爱
yanmoai:addSkill(weituo)
yanmoai:addSkill(liufang)
yanmoai:addSkill(yuanhuo)
yanmoai:addSkill(yuanhuo_ex)
extension:insertRelatedSkills("yuanhuo", "#yuanhuo_ex")
--国木田花丸
huawan:addSkill(zhengdao)
huawan:addSkill(zhengdaobuff)
huawan:addSkill(zhengdaozb)
huawan:addSkill(zhihoujb)
huawan:addSkill(zhihouz)
extension:insertRelatedSkills("zhengdao", "#zhengdaozb")
extension:insertRelatedSkills("zhengdao", "#zhengdaobuff")
extension:insertRelatedSkills("zhihouz", "#zhihoujb")
--机枪射手
jiqiangms:addSkill(jiqiangs)
jiqiangms:addSkill(lanyushanbi)
--沉默射手
chenmosheshou:addSkill(jibanhy)
chenmosheshou:addSkill(chenmohy)
--妮可
nike:addSkill(nvzidao)
nike:addSkill(chuanxiao)
--雷姬
Reki:addSkill(yijizho)
Reki:addSkill(htms_fengyu)
Reki:addSkill(htms_fengyu_ex)
extension:insertRelatedSkills("htms_fengyu", "#htms_fengyu_ex")
--巴麻美
bamameicd:addSkill(duandai)
bamameicd:addSkill(duandai_targetmod)
bamameicd:addSkill(duandai_range)
--阿虚
axu:addSkill(tucao)
axu:addSkill(tucaoxx)
axu:addSkill(tucaoex)
--豪瑟
haose:addSkill(wangwei)
haose:addSkill(wangquan)
--邪神圆
xieshenyuan:addSkill(qidao)
xieshenyuan:addSkill(qiyuan)
xieshenyuan:addSkill(qiyuan_cardMAX)
--苏我屠自古
toziko:addSkill(LuaLeishi)
--toziko:addSkill(LuaLeishi2)
toziko:addSkill(Luayuanxing)
toziko:addSkill(Luayuanling)
toziko:addSkill(Luayuanling2)
toziko:addSkill(Luashenyi)
toziko:addSkill(Luashenyi2)
toziko:addSkill(LuashenyiDo)
--灵梦
sp_reimu:addSkill(luakuaiqing)
sp_reimu:addSkill(luakuaiqing2)
sp_reimu:addSkill(luajiejie)
--朱鹭子
tokiko:addSkill(luajieao)
tokiko:addSkill(luajinlun)
tokiko:addSkill(luajinlunGive)
extension:insertRelatedSkills("luajinlun", "#luajinlunGive")
--夕立改二
poige:addSkill(empaiduiex)
poige:addSkill(empaidui)
poige:addSkill(yftuji)
poige:addSkill(yftujiGive)
extension:insertRelatedSkills("empaidui", "#empaiduiex")
extension:insertRelatedSkills("yftuji", "#yftujiGive")
--勇太
Togashi:addSkill(zhongerhx)
--贞德
fdzhende:addSkill(hanrenzd)
fdzhende:addSkill(bingfengzd)
fdzhende:addSkill(hanrenzdMaxCard)
--金木研
jinmuyan:addSkill(hezibz)
jinmuyan:addSkill(shayiqr)
--丽塔
b3lita:addSkill(duancai)
b3lita:addSkill(midie)
--千歌
jika:addSkill(tongzhouqg)
jika:addSkill(qgjiesi)
--治疗真姬
zlmaki:addSkill(zjyizhen)
zlmaki:addSkill(zjmoshuxif)
--洛神真姬
lsmaki:addSkill(zjruoshi)
lsmaki:addSkill(zjaojiaol)
--千金真姬
qjmaki:addSkill(qianjinzj)
qjmaki:addSkill(bieniu)
qjmaki:addSkill(puzou)
--威仪黛雅
wypenguin:addSkill(htms_weiyi)
wypenguin:addSkill(mingmendia)
--鬼人正邪
--seija:addSkill(luatiaobo)
--seija:addSkill(luanizhuan)
--赤蛮奇
sekibanki:addSkill(lualushou)
sekibanki:addSkill(lualushou2)
--sekibanki:addSkill(luanyanguang)
--风见幽香
fengjianyouxiang:addSkill(huazang)
--雪乃
xuenai:addSkill(zchize)
xuenai:addSkill(gaoling)
--菜月昴
subaru:addSkill(huidang)
subaru:addSkill(zhengjiu)
--黑C
heic8:addSkill(molwf)
heic8:addSkill(molisf)
heic8:addSkill(html_shisheng)
heic8:addSkill(html_shishengsw)
--连击优纪
youji:addSkill(ujyaozhan)
youji:addSkill(ujyaozhanex)
extension:insertRelatedSkills("ujyaozhan", "#ujyaozhanex")
youji:addSkill(ujlianji)
youji:addSkill(ujzhongshi)
youji:addSkill(ujzhongshiRecord)
extension:insertRelatedSkills("ujzhongshi", "#ujzhongshiRecord")
--安洁莉亚
Sdorica_Angelia:addSkill(Sdorica_FuWei)
extension:insertRelatedSkills("Sdorica_MiLing", "#Sdorica_MiLing_PreventDamage")
extension:insertRelatedSkills("Sdorica_MiLing", "#Sdorica_MiLing_card")
Sdorica_Angelia:addSkill(Sdorica_MiLing)
Sdorica_Angelia:addSkill(Sdorica_MiLing_card)
Sdorica_Angelia:addSkill(Sdorica_MiLing_PreventDamage)
--樱满集
oumashu:addSkill(void)
oumashu:addSkill(wangguo)
--板鸭
banya:addSkill(lsqd)
banya:addSkill(tscg)
banyali:addSkill(tscg)
banyali:addSkill(lsqd)
--慧慧
Megumin:addSkill(tcmfs)
Megumin:addSkill(blmf)
Megumin:addSkill(blmfxx)
Megumin:addSkill(blmfex)
--奥尔加
Orga:addSkill(htms_mozhi)
Orga:addSkill(htms_mozhidis)
Orga:addSkill(htms_mozhixx)
--卡塔琳娜
ktln:addSkill(yiban)
ktln:addSkill(pomiehb)
--上原步梦
ayumu:addSkill(zhumyb)
ayumu:addSkill(tonghh)
--秋穰子
minoriko:addSkill(luashouhuo2)
minoriko:addSkill(luashouhuo)
extension:insertRelatedSkills("luashouhuo", "#luashouhuo2")
minoriko:addSkill(luahongyu)
--莲
LLENN:addSkill(pinkdevil)
LLENN:addSkill(khztbuff)
--格尼薇儿
v2:addSkill(embers)
v2:addSkill(embersex)
v2:addSkill(gxzhiliaoex)
--迪妮莎
dns:addSkill(wugshashou)
dns:addSkill(nxlieren)
dns:addSkill(nxlieren_ex)
extension:insertRelatedSkills("nxlieren", "#nxlieren_ex")
--步梦
-- bumeng:addSkill(xibu)
-- bumeng:addSkill(dalunb)
--ZERO
zeroll:addSkill(zhanshubuju)
zeroll:addSkill(zhanshubuju_ex)
extension:insertRelatedSkills("zhanshubuju", "#zhanshubuju_ex")
zeroll:addSkill(zhachang)
--阿库娅
akuya:addSkill(hongshui)
akuya:addSkill(zhufu)
akuya:addSkill(afuhuo)
--姬宫真步
jgzb:addSkill(tonghua)
jgzb:addSkill(lingbo)
--伍德
wude:addSkill(chaogz)
wude:addSkill(chaogzmax)
wude:addSkill(chaogz_cishu)
wude:addSkill(chaogz_ex)
--圣麻美
shengmm:addSkill(shengqiang)
shengmm:addSkill(shengqiang_range)
shengmm:addSkill(shengqiang_cishu)
shengmm:addSkill(paojixj)
--佐藤和真
hezhen:addSkill(dqjt)
--圣剑桐人
sjtongren:addSkill(lianxie_cishu)
sjtongren:addSkill(lianxie)
extension:insertRelatedSkills("lianxie", "#lianxie_cishu")
sjtongren:addSkill(huanzhaung)
--LL
xsll:addSkill(xinshengll)
xsll:addSkill(llpj)
--橘纯一
jcy:addSkill(shejiao)
jcy:addSkill(jsdy)
--婉弦梨子
rkk:addSkill(wanxian)
rkk:addSkill(liantan)
--五河琴里
whql:addSkill(s_yanyu)
whql:addSkill(s_yanmojianglin)
--凯留
kailiu:addSkill(s_lianjie)
kailiu:addSkill(s_polie)
kailiu:addSkill(s_polie_InTempMoving)
extension:insertRelatedSkills("s_polie", "#s_polie_InTempMoving")
--睡眠彼方
htms_bifang:addSkill(s_shuimian)
htms_bifang:addSkill(s_shuimian_tr)
htms_bifang:addSkill(s_jieshu)
--达克尼斯
dkns:addSkill(s_douM)
dkns:addSkill(s_shiziqishi)
--白井黑子
bjhz:addSkill(s_kongyi)
bjhz:addSkill(s_kongyi_InTempMoving)
extension:insertRelatedSkills("s_kongyi", "#s_kongyi_InTempMoving")
bjhz:addSkill(s_yueqian)
--阿姆罗·雷
luozi:addSkill(s_newtype)
--全局技能添加
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("zhou_count") then skills:append(zhou_count) end
if not sgs.Sanguosha:getSkill("mie_EX") then skills:append(mie_EX) end
if not sgs.Sanguosha:getSkill("feils2") then skills:append(feils2) end
--if not sgs.Sanguosha:getSkill("changgui") then skills:append(changgui) end
--if not sgs.Sanguosha:getSkill("heihua") then skills:append(heihua) end
if not sgs.Sanguosha:getSkill("slash_defence") then skills:append(slash_defence) end
if not sgs.Sanguosha:getSkill("loyal_inu_damage") then skills:append(loyal_inu_damage) end
if not sgs.Sanguosha:getSkill("jueduiyazhi") then skills:append(jueduiyazhi) end
if not sgs.Sanguosha:getSkill("fzndz_skip") then skills:append(fzndz_skip) end
if not sgs.Sanguosha:getSkill("qrdag_ex") then skills:append(qrdagEx) end
--if not sgs.Sanguosha:getSkill("hxss_i") then skills:append(hxss_i) end
if not sgs.Sanguosha:getSkill("#hxss_Clear") then skills:append(hxss_Clear) end
if not sgs.Sanguosha:getSkill("yohaneFakeMove") then skills:append(yohaneFakeMove) end
if not sgs.Sanguosha:getSkill("fanyiAttackRange") then skills:append(fanyiAttackRange) end
if not sgs.Sanguosha:getSkill("fanyiMaxCards") then skills:append(fanyiMaxCards) end
if not sgs.Sanguosha:getSkill("fanyiTargetMod") then skills:append(fanyiTargetMod) end
if not sgs.Sanguosha:getSkill("fanyiGlobalUse") then skills:append(fanyiGlobalUse) end
if not sgs.Sanguosha:getSkill("fanyiDrawNCard") then skills:append(fanyiDrawNCard) end
if not sgs.Sanguosha:getSkill("JihangGlobalClear") then skills:append(JihangGlobalClear) end
if not sgs.Sanguosha:getSkill("fuzou_clear") then skills:append(fuzou_clear) end
if not sgs.Sanguosha:getSkill("yishibuff") then skills:append(yishibuff) end
if not sgs.Sanguosha:getSkill("zyfashijl") then skills:append(zyfashijl) end
if not sgs.Sanguosha:getSkill("jibanvs") then skills:append(jibanvs) end
if not sgs.Sanguosha:getSkill("zhiyexuanze") then skills:append(zhiyexuanze) end

sgs.LoadTranslationTable {
	["htms_teio"] = "东海帝王",
    ["#htms_teio"] = "",
    ["~htms_teio"] = "我已经没法那样跑了呢。",
    ["illustrator:htms_teio"] = "Mirage/ミラージュ(90845736)",
    ["designer:htms_teio"] = "网瘾少年",
    ["htms_diwu"] = "帝舞",
    [":htms_diwu"] = "转换技，出牌阶段限三次，当你使用牌时，你可以从 阳：牌堆顶；阴：牌堆底 观看3-X张牌，若存在与你使用牌类别相同的牌，获得其中一张并弃置其余牌，否则按原位置放回牌堆。",
	[":htms_diwu1"] = "转换技，出牌阶段限三次，当你使用牌时，你可以从 阳：牌堆顶；<font color=\"#01A5AF\"><s>阴：牌堆底</s></font> 观看 %arg1 张牌，若存在与你使用牌类别相同的牌，获得其中一张并弃置其余牌，否则按原位置放回牌堆。",
	[":htms_diwu2"] = "转换技，出牌阶段限三次，当你使用牌时，你可以从<font color=\"#01A5AF\"><s> 阳：牌堆顶；</s></font>阴：牌堆底 观看 %arg1 张牌，若存在与你使用牌类别相同的牌，获得其中一张并弃置其余牌，否则按原位置放回牌堆。",
	["$htms_diwu1"] = "输了哭了也不要怪我，我可是最强的马娘。",
	["$htms_diwu2"] = "目标是成为和会长一样，不败的三冠马娘。",

    ["@htms_nisheng"] = "逆胜：你可以弃置至多 %src 张牌对等量名其他角色造成伤害",
    ["htms_nisheng"] = "逆胜",
    [":htms_nisheng"] = "出牌阶段结束时，你可以弃置至多X张牌并选择等量名其他角色，你依次对这些角色造成1点伤害并弃置其一张牌。结算完成后，若有角色未因此法弃置牌，你回复1点体力。",
    [":htms_nisheng1"] = "出牌阶段结束时，你可以弃置至多 %arg1 张牌并选择等量名其他角色，你依次对这些角色造成1点伤害并弃置其一张牌。结算完成后，若有角色未因此法弃置牌，你回复1点体力。",
	["$htms_nisheng1"] = "我气馁了好多次，无论那时，还是那时，比任何人都灰心丧气。",
	["$htms_nisheng2"] = "比任何人都不甘心的就是我，比任何人都想赢的就是我，绝对不要退让，绝对 绝对，绝对就是我！",

    ["htms_sanqi"] = "三起",
    [":htms_sanqi"] = "当你于濒死状态失救时，你可以选择一种未以此法选择的类别，将体力回复至X点，本局你不能使用或打出该类别的牌。 （X为你已选择类别数且至少为1）",
	["$htms_sanqi1"] = "我发现一件事，没能实现三冠，但我没输。(帝王)我还能成为不败的马娘，对吧。",
	["$htms_sanqi2"] = "既然你说到这个份上了，也不是不能和你比，小心输了哭鼻子哦。",
	["$htms_sanqi3"] = "即使如此我也要赢，只要期待着奇迹发生而努力，就一定能成功。",

	["htms_chtholly"] = "珂朵莉",
    ["#htms_chtholly"] = "",
    ["~htms_chtholly"] = "此刻的我，无论他人如何言说，都一定是世上最幸福的女孩。",
    ["illustrator:htms_chtholly"] = "祓筱(64391112)",
    ["designer:htms_chtholly"] = "FlameHaze",
	["htms_mo"] = "魔",
	["htms_ranxin"] = "燃心",
	[":htms_ranxin"] = "<font color='green'><b>每回合限3次，</b></font>你使用一张红色牌时，若你“魔”小于3，你可以将牌堆顶一张牌作为“魔”置于人物牌上。锁定技，你有“魔”时，使用杀额定次数+1，你的杀造成伤害时弃置一张“魔”并摸一张牌。",
	["$htms_ranxin1"] = "我要回去...约好了的....约好了的...",
	["$htms_ranxin2"] = "吵死了，我一定要回去啊！",
	["htms_chiyi"] = "斥忆",
	[":htms_chiyi"] = "锁定技，结束阶段结束时，你弃置所有“魔”，若弃置“魔”数不大于2，你失去一点体力，摸2张牌；若弃置“魔”数不小于3，你减一点体力上限，摸3张牌，并弃置一张手牌。",
	["$htms_chiyi1"] = "奇怪...我是...谁来着的?",
	["$htms_chiyi2"] = "想不起来 但是应该...有什么重要的...",
	["htms_chtholly_dead$"] = "image=image/animate/htms_chtholly.png",

	["htms_kaminogi"] = "神乃木庄龙",
    ["#htms_kaminogi"] = "",
    ["~htms_kaminogi"] = "男子汉只有在一切都结束的时候才能流眼泪。",
    ["illustrator:htms_kaminogi"] = "",
    ["designer:htms_kaminogi"] = "石激",
	["htms_coffee"] = "咖啡",
	[":htms_coffee"] = "锁定技，黑桃牌对你无效；当你成为梅花牌的目标后，摸一张牌。",
	["$htms_coffee1"] = "更胜深夜的暗黑，更胜地狱的滚烫与苦涩的咖啡。",
	["$htms_coffee2"] = "这杯比地狱更苦涩黑暗的咖啡，正配得上你将要说的话。",
	["@htms_lunbian"] = "论辩：你可以弃置任意张牌，令 %src 无效",
	["htms_lunbian"] = "论辩",
	[":htms_lunbian"] = "<img src=\"image/mark/@objection.png\">一名角色成为伤害类牌的目标后，你可以弃置任意张牌，若其中包含与使用的牌颜色相同的牌和类别相同的牌，令此牌无效。",
	["$htms_lunbian"] = "異議あり",
	["htms_beihai"] = "被害",
	[":htms_beihai"] = "觉醒技，当你进入濒死状态时，你减一点体力上限，回复体力至2点，并获得技能“戈多”。",
	["$htms_beihai1"] = "深爱的女人竟然被人杀害了。",
	["$htms_beihai2"] = "憎恨的她也被宣判了死刑。",
	["#htms_godotfilter"] = "戈多",
	["htms_godot"] = "戈多",
	[":htms_godot"] = "锁定技，你区域内、你的判定、指定你为目标的红桃/方块牌均视为黑桃/梅花牌。出牌阶段开始时，你对一名其他角色造成1点伤害并令其获得“咖啡”直到你的下回合开始。）",
	["$htms_godot"] = "我必需与你一战，所以才从地狱回到了这里。",
}
htms_teio  = sgs.General(extension, "htms_teio", "htms_lin", 3, false)   --东海帝王

htms_diwu = sgs.CreateTriggerSkill{
    name = "htms_diwu",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.CardUsed},
	change_skill = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and player:getMark("htms_diwu-PlayClear") < 3 and player:getPhase() == sgs.Player_Play then
				local x = math.max(1, player:getMark("htms_sanqi"))
				if 3-x <= 0 then return false end
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:addPlayerMark(player, "htms_diwu-PlayClear")
					local n = player:getChangeSkillState(self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(player,self)
					local cards = room:getNCards(3-x, false, n==1)
					if n<2 then
						player:setSkillDescriptionSwap("htms_diwu","%arg1", 3-x)
						room:setChangeSkillState(player,self:objectName(),2)
					else
						player:setSkillDescriptionSwap("htms_diwu","%arg1", 3-x)
						room:setChangeSkillState(player,self:objectName(),1)
					end
					local log = sgs.LogMessage()
					if n<2 then
						log.type = "$ViewDrawPile"
					else
						log.type = "$ViewEndDrawPile"
					end
					log.from = player
					log.card_str = table.concat(sgs.QList2Table(cards), "+")
					room:sendLog(log, player)
					
					local obtain = sgs.IntList()
					local throw = sgs.IntList()
					for _, id in sgs.qlist(cards) do
						if sgs.Sanguosha:getCard(id):getTypeId() == use.card:getTypeId() then
							obtain:append(id)
						else
							throw:append(id)
						end
					end
					
					if obtain:isEmpty() then
						if n<2 then
							room:returnToTopDrawPile(cards)
						else
							room:returnToEndDrawPile(cards)
						end
					else
						room:fillAG(cards, player, throw)
						local id = room:askForAG(player,obtain,false,"htms_diwu")
						room:clearAG(player)
						cards:removeOne(id)
						room:obtainCard(player, id, true)
						for _, id in sgs.qlist(cards) do
							room:throwCard(id, nil)
						end
					end
				end
            end
        end
        return false
    end
}
htms_nishengCard = sgs.CreateSkillCard{
    name = "htms_nishengCard",
    mute = true,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local x = self:subcardsLength()
		if #targets < x then 
			return to_select:objectName() ~= player:objectName()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets == self:subcardsLength()
	end,
    on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("htms_nisheng")
		local recover = false
		for _,p in sgs.list(targets)do
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = p
			room:damage(damage)
			if source:canDiscard(p, "he") then
				local id = room:askForCardChosen(source, p, "he", "htms_nisheng")
				room:throwCard(id, p, source)
			else
				recover = true
			end
		end
		if recover then
			room:recover(source, sgs.RecoverStruct(source))
		end
    end
}
htms_nishengVS = sgs.CreateViewAsSkill{
    name = "htms_nisheng",
    n = 3,
    response_pattern = "@@htms_nisheng",
    view_filter = function(self, selected, to_select)
		local x = math.max(1, sgs.Self:getMark("htms_sanqi"))
		return #selected < x
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
		local x = math.max(1, sgs.Self:getMark("htms_sanqi"))
        if #cards <= x then
            local dis_card = htms_nishengCard:clone()
            for _,card in pairs(cards) do
                dis_card:addSubcard(card)
            end
            dis_card:setSkillName("htms_nisheng")
            return dis_card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}
htms_nisheng = sgs.CreateTriggerSkill{
    name = "htms_nisheng",
    events = {sgs.EventPhaseEnd},
    view_as_skill = htms_nishengVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if (event == sgs.EventPhaseEnd) then
            if player:getPhase() == sgs.Player_Play then
                if player:canDiscard(player, "he") then
                   room:askForUseCard(player, "@@htms_nisheng", "@htms_nisheng:"..math.max(1, player:getMark("htms_sanqi")))
                end
            end
        end
        return false
    end
}
htms_sanqi_limit = sgs.CreateCardLimitSkill{
	name = "#htms_sanqi_limit",
	limit_list = function(self, player)
		return "use,response"
	end,
	limit_pattern = function(self, player, card)
		if player:hasSkill("htms_sanqi") then
			local ss = player:property("htms_sanqi"):toString()
			if ss~="" and string.find(ss,card:getType()) then return "."..ss end
		end
		return ""
	end
}
htms_sanqi = sgs.CreateTriggerSkill{
    name = "htms_sanqi",
    events = {sgs.AskForPeachesDone},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if (event == sgs.AskForPeachesDone) then
			if player:getHp() <= 0 then
				local ss = player:property("htms_sanqi"):toString():split(",")
				local choicelist = {"basic","trick", "equip"}
				for _, choice in ipairs(ss) do
					if table.contains(choicelist,choice) then
						table.removeOne(choicelist, choice)
					end
				end
				if #choicelist <= 0 then return end
				local x =3-#choicelist
				table.insert(choicelist, "cancel")
				local choice = room:askForChoice(player, self:objectName(),table.concat(choicelist, "+"))
				if choice ~= "cancel" then
					room:broadcastSkillInvoke(self:objectName())
					if choice == "equip" then
						room:setPlayerCardLimitation(player, "use,response", "EquipCard|.|.|hand", false)
					end
					room:addPlayerMark(player, "htms_sanqi")
					table.insert(ss, choice)
					room:setPlayerProperty(player,"htms_sanqi",sgs.QVariant(table.concat(ss,",")))
					for _, m in sgs.list(player:getMarkNames()) do
						if m:startsWith("&htms_sanqi+:+") then
							room:setPlayerMark(player,m,0)
						end
					end
					room:setPlayerMark(player,"&htms_sanqi+:+"..table.concat(ss,"+"),1)

					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = player:getMark("htms_sanqi") - player:getHp()
					room:recover(player, recover)
					player:setSkillDescriptionSwap("htms_nisheng","%arg1", player:getMark("htms_sanqi"))
					room:changeTranslation(player, "htms_nisheng", 1)
				end
			end
        end
        return false
    end
}

htms_teio:addSkill(htms_diwu)
htms_teio:addSkill(htms_nisheng)
htms_teio:addSkill(htms_sanqi)
htms_teio:addSkill(htms_sanqi_limit)
extension:insertRelatedSkills("htms_sanqi", "#htms_sanqi_limit")

htms_chtholly  = sgs.General(extension, "htms_chtholly", "htms_feng", 4, false)   --珂朵莉

htms_ranxin_buff = sgs.CreateTargetModSkill { --红桃无视距离
	name = "#htms_ranxin_buff",
	residue_func = function(self, player, card)
		if player:hasSkill("htms_ranxin") and not player:getPile("htms_mo"):isEmpty() then
			return 1
		end
	end,
}
htms_ranxin = sgs.CreateTriggerSkill{
	name = "htms_ranxin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:getPile("htms_mo"):isEmpty() then return end
			if damage.card and damage.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:fillAG(player:getPile("htms_mo"), player)
				local card_id = room:askForAG(player, player:getPile("htms_mo"), false, self:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "htms_ranxin",	"");
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
				room:clearAG()
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1, self:objectName())
			end
		else
			local card
			local invoke = true
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				else
					invoke = false
				end
			end
			if card and not card:isKindOf("SkillCard") then
				if card:isRed() and player:getMark("htms_ranxin-Clear") < 3 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:addPlayerMark(player, "htms_ranxin-Clear")
						room:broadcastSkillInvoke(self:objectName())
						local id = room:drawCard()
						player:addToPile("htms_mo", id)
					end
				end
			end
		end
		return false
	end
}
htms_chiyi = sgs.CreateTriggerSkill {
	name = "htms_chiyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local x = player:getPile("htms_mo"):length()
			if not player:getPile("htms_mo"):isEmpty() then
				player:clearOnePrivatePile("htms_mo")
			end
			if x <= 2 then
				room:loseHp(player)
				player:drawCards(2)
			elseif x >= 3 then
				room:loseMaxHp(player)
				player:drawCards(3)
				room:askForDiscard(player, self:objectName(), 1, 1, false)
			end
		end
	end
}
htms_chtholly_dead = sgs.CreateTriggerSkill {
	name = "#htms_chtholly_dead",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameOverJudge },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameOverJudge then
			local death = data:toDeath()
			if death.who and death.who:getGeneralName() == "htms_chtholly" then
				local wore = math.random(1, 5)
				if wore == 1 then
					room:doLightbox("htms_chtholly_dead$", 4444)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end,
}


htms_chtholly:addSkill(htms_ranxin_buff)
htms_chtholly:addSkill(htms_ranxin)
extension:insertRelatedSkills("htms_ranxin", "#htms_ranxin_buff")
htms_chtholly:addSkill(htms_chiyi)
htms_chtholly:addSkill(htms_chtholly_dead)

htms_kaminogi  = sgs.General(extension, "htms_kaminogi", "htms_shan", 4, true) 

htms_coffee = sgs.CreateTriggerSkill{
	name = "htms_coffee",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected, sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data,room)
    	if event==sgs.CardEffected	then
    		local effect = data:toCardEffect()
			if effect.card:getSuit() == sgs.Card_Spade and not effect.card:isKindOf("SkillCard")	then
                room:sendCompulsoryTriggerLog(player,"htms_coffee",true)
				effect.nullified = true
				data:setValue(effect)
				room:broadcastSkillInvoke(self:objectName())
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to and use.to:contains(player) and use.card:getSuit() == sgs.Card_Club then
				room:sendCompulsoryTriggerLog(player,"htms_coffee",true)
				player:drawCards(1, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
htms_lunbian = sgs.CreateTriggerSkill{
	name = "htms_lunbian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data,room)
    	if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to and use.card:isDamageCard() then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:canDiscard(p, "he") and p:hasSkill(self:objectName()) then
						room:setTag("htms_lunbian", data)
						local discard = room:askForDiscard(p, self:objectName(), 999, 1, true, true, "@htms_lunbian:"..use.card:objectName())
						room:removeTag("htms_lunbian")
						if discard then
							local color = false
							local type = false
							for _,id in sgs.qlist(discard:getSubcards())do
								local card = sgs.Sanguosha:getCard(id)
								if card:sameColorWith(use.card) then
									color = true
								end
								if card:getType() == use.card:getType() then
									type = true
								end
							end
							if color and type then
								room:setEmotion(p, "objection")
								room:broadcastSkillInvoke(self:objectName())
								local nullified_list = use.nullified_list
								table.insert(nullified_list, "_ALL_TARGETS")
								use.nullified_list = nullified_list
								data:setValue(use)
							end
						end
					end
				end
			end
		end
		return false
	end
}

htms_beihai = sgs.CreateTriggerSkill {
	name = "htms_beihai",
	frequency = sgs.Skill_Wake,
	events = { sgs.Dying },
	waked_skills = "htms_godot",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:hasSkill(self:objectName()) and source:getMark(self:objectName()) == 0 then
			room:addPlayerMark(source, self:objectName())
			room:loseMaxHp(source)
			local recover = sgs.RecoverStruct()
			recover.who = source
			recover.recover = 2 - source:getHp()
			room:recover(source, recover)
			room:handleAcquireDetachSkills(player, "htms_godot")
		end
	end
}
htms_godotfilter = sgs.CreateFilterSkill{
	name = "#htms_godotfilter",
	view_filter = function(self, card)
		return card:getSuit() == sgs.Card_Diamond or card:getSuit()== sgs.Card_Heart
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		if card:getSuit() == sgs.Card_Diamond then
			new_card:setSuit(sgs.Card_Club)
		else
			new_card:setSuit(sgs.Card_Spade)
		end
		new_card:setModified(true)
		return new_card
	end
}

htms_godot = sgs.CreateTriggerSkill{
	name = "htms_godot",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				if target then
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = target
					room:damage(damage)
					room:broadcastSkillInvoke(self:objectName())
					room:acquireNextTurnSkills(target, self:objectName(), "htms_coffee")
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local splayers = room:findPlayersBySkillName("htms_godot")
			for _,splayer in sgs.qlist(splayers) do
				if use.to:contains(splayer)  then
					if use.card:getSuit() == sgs.Card_Heart then
						local new_card = sgs.Sanguosha:getWrappedCard(use.card:getId())
						new_card:setSkillName("htms_godot")
						new_card:setSuit(sgs.Card_Spade)
						new_card:setModified(true)
						use.card = new_card
					elseif use.card:getSuit() == sgs.Card_Diamond then
						local new_card = sgs.Sanguosha:getWrappedCard(use.card:getId())
						new_card:setSkillName("htms_godot")
						new_card:setSuit(sgs.Card_Club)
						new_card:setModified(true)
						use.card = new_card
					end
					data:setValue(use)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

htms_kaminogi:addSkill(htms_coffee)
htms_kaminogi:addSkill(htms_lunbian)
htms_kaminogi:addSkill(htms_beihai)
-- htms_kaminogi:addSkill(htms_godot)
-- htms_kaminogi:addSkill(htms_godotfilter)
if not sgs.Sanguosha:getSkill("htms_godot") then skills:append(htms_godot) end
if not sgs.Sanguosha:getSkill("#htms_godotfilter") then skills:append(htms_godotfilter) end
extension:insertRelatedSkills("htms_godot", "#htms_godotfilter")















sgs.Sanguosha:addSkills(skills)

