# AI失误系统使用说明

## 概述

AI失误系统让AI玩家偶尔做出不完美的决策，使其表现更像真人玩家，增加游戏的趣味性和真实感。

## 安全保护机制

### 1. 真人玩家保护（单机模式）
- 当AI玩家与真人玩家同队时，**不会对真人玩家犯错**
- 保障单机玩家的游戏体验
- 自动检测真人玩家并排除在失误目标之外

### 2. 关键局势保护
系统会在以下情况下**禁用所有失误**：
- 主公HP ≤ 1时
- AI自身HP ≤ 1时
- 场上存活玩家 ≤ 3人时

### 3. 核心技能保护
以下核心技能永远不会被跳过：
- `guanxing`（观星）- 核心控制技能
- `jizhi`（集智）- 核心过牌技能
- `qingnang`（青囊）- 核心治疗技能
- `jijiu`（急救）- 核心救人技能
- `rende`（仁德）- 核心辅助技能
- `zhiheng`（制衡）- 核心过牌技能

## 功能特点

### 1. 失误类型

系统支持多种失误类型：

#### 已启用的失误（影响较小）
- **选错目标** (`WRONG_TARGET`) - AI选择了次优目标
- **跳过技能** (`SKIP_SKILL`) - 未发动应该发动的技能（不包括核心技能）
- **错误使用技能** (`WRONG_SKILL`) - 发动了不该发动的技能
- **弃错牌** (`DISCARD_GOOD_CARD`) - 弃掉好牌或保留坏牌
- **错失斩杀** (`MISS_LETHAL`) - 有机会斩杀但没有（仅记录）
- **出牌顺序错误** (`WRONG_ORDER`) - 出牌时机不对
- **过度防守** (`OVER_DEFEND`) - 不必要的防守

#### 已禁用的失误（太关键）
- ~~**救人失误** (`WRONG_SAVE`)~~ - 已删除，影响游戏平衡
- ~~**无懈失误** (`WRONG_NULL`)~~ - 已删除，影响游戏平衡

### 2. 动态失误率

失误率会随游戏进程动态调整：

```lua
-- 基础配置
sgs.ai_mistake_config = {
    enabled = true,           -- 启用/禁用失误系统
    base_rate = 0.05,        -- 基础失误率 5%
    turncount_factor = 0.005, -- 回合因子
    max_rate = 0.15,         -- 最大失误率 15%
    min_rate = 0.02,         -- 最小失误率 2%
}
```

**失误率计算公式：**
```
失误率 = base_rate - (回合数 × turncount_factor)
```

随着游戏进行，AI会越来越"熟练"，失误率降低。

### 3. 难度设置

支持4个难度等级：

```lua
-- 简单模式 - 20%失误率
setAIMistakeDifficulty("easy")

-- 普通模式 - 5%失误率
setAIMistakeDifficulty("normal")

-- 困难模式 - 2%失误率
setAIMistakeDifficulty("hard")

-- 专家模式 - 0%失误率（完美AI）
setAIMistakeDifficulty("expert")
```

## 使用方法

### 基本配置

在游戏开始前设置：

```lua
-- 启用失误系统
sgs.ai_mistake_config.enabled = true

-- 设置难度为普通
setAIMistakeDifficulty("normal")
```

### 在AI逻辑中集成

系统已经集成到以下关键决策点：

1. **技能发动** (`askForSkillInvoke`)
   - AI可能跳过应该发动的技能（不包括核心技能）
   - 极少概率错误发动不该发动的技能

2. **弃牌阶段** (`askForDiscard`)
   - 可能弃掉好牌
   - 保留应该弃的牌

3. **目标选择** (`findPlayerToDamage`)
   - 选择次优目标（但不会选择同队真人玩家）
   - 自动在伤害目标选择时触发

4. **斩杀检测** (`activate`)

### 添加新的失误点

在你的AI代码中添加失误判断：

```lua
-- 示例：选择目标时
function SmartAI:selectTarget(targets)
    local best_target = self:findBestTarget(targets)
    
    -- 添加失误可能（会自动过滤同队真人玩家）
    if self.chooseSuboptimalTarget then
        best_target = self:chooseSuboptimalTarget(
            best_target, 
            targets, 
            "skill_name"
        )
    end
    
    return best_target
end
```

## 游戏内效果

### 对话反馈

当AI失误时会说出对应的话：

```lua
-- 失误时的对话
sgs.ai_chat.self_mistake = {
    "我大意了",
    "失误了",
    "手滑了",
    "不好意思",
    "算错了",
    "我的锅"
}

-- 对手看到AI失误时的嘲讽
sgs.ai_chat.enemy_mistake = {
    "对面送了",
    "失误了吧",
    "谢谢老板",
    "送的好",
    "这波不亏",
    "笑死"
}
```

### 实际案例

**案例1：技能跳过**
```
AI手握关键技能但失误未发动
AI: "我大意了"
对手: "笑死"
```

**案例2：弃牌失误**
```
弃牌阶段AI弃掉了桃而留下了基本杀
AI: "手滑了"
队友: "队友在干嘛"
```

## 统计与调试

### 查看失误统计

```lua
-- 打印失误统计
printAIMistakeStats()

-- 输出示例：
-- === AI失误统计 ===
-- wrong_target: 3次
-- skip_skill: 5次
-- discard_good: 2次
-- 总计: 10次失误
-- 当前失误率: 4.50%
```

### 获取失误数据

```lua
-- 获取统计数据
local stats = getAIMistakeStats()
for mistake_type, count in pairs(stats) do
    print(mistake_type, count)
end

-- 清空日志
clearAIMistakeLog()
```

### 调试模式

开启调试模式查看详细日志：

```lua
_G.AI_DEBUG_MODE = true
```

失误发生时会在控制台输出：
```
[AI失误] 张飞 (player1) - 类型:skip_skill 原因:paoxiao
[AI失误] 诸葛亮 (player2) - 类型:wrong_null 原因:Duel
```

## 平衡建议

### 推荐配置

**休闲娱乐模式：**
```lua
sgs.ai_mistake_config.base_rate = 0.10  -- 10%失误率
```

**竞技模式：**discard_good 原因:random_discard
```lua
sgs.ai_mistake_config.base_rate = 0.03  -- 3%失误率
```

**新手教学模式：**
```lua
sgs.ai_mistake_config.base_rate = 0.20  -- 20%失误率
```

### 特定技能调整

对某些关键技能降低失误率：

```lua
-- 在askForSkillInvoke中
if skill_name == "zhuge_guanxing" then
    -- 观星这种核心技能降低失误概率
    if shouldMakeMistake(0.01) then  -- 只有1%
        return self:mistakeSkipSkill(skill_name, invoke)
    end
end
```

## 注意事项

1. **失误率不宜过高**
   - 超过15%会让AI显得太蠢
   - 建议保持在2-10%之间

2. **关键决策保护**
   - 已禁用救人、无懈等关键决策的失误
   - 主公濒死、游戏胜负关键时刻自动禁用失误

3. **真人玩家保护**
   - AI不会对同队真人玩家犯错
   - 保障单机玩家游戏体验

4. **性能影响**
   - 失误日志会占用内存
   - 定期清理或限制日志大小

## 扩展功能

### 自定义失误类型

```lua
-- 添加新的失误类型
sgs.ai_mistake_type.CUSTOM_MISTAKE = "custom"

-- 使用
logAIMistake(player, sgs.ai_mistake_type.CUSTOM_MISTAKE, "描述")
```

### 失误概率修正

根据玩家状态调整失误率：

```lua
function getAIMistakeRate()
    local rate = sgs.ai_mistake_config.base_rate
    
    -- 血量越低，越谨慎（失误率降低）
    if self.player:getHp() <= 1 then
        rate = rate * 0.5
    end
    
    -- 手牌越多，越容易失误（选择困难）
    if self.player:getHandcardNum() > 5 then
        rate = rate * 1.2
    end
    
    return rate
end
```

## 总结

AI失误系统通过在关键决策点引入可控的随机性，让AI表现更加人性化。合理配置失误率可以：

- ✅ 增加游戏趣味性
- ✅ 降低AI无敌感
- ✅ 提供更真实的对战体验
- ✅ 让新手玩家有更多获胜机会

记住：**好的AI不是从不失误，而是失误得恰到好处！**
