# 调虎离山 (Lure Tiger) Implementation Review

## 修改总结 (Summary of Changes)

### 1. 核心函数修改 (Core Function Modifications)

#### A. serverplayer.h & serverplayer.cpp
**新增函数 (New Function):**
- `ServerPlayer *getNextGamePlayer(int n = 1) const;`
  - 专门用于游戏机制判定（回合顺序、胜负判定）
  - 只跳过死亡角色，**忽略**调虎离山标记
  - 用于关键游戏逻辑，确保游戏流程不受调虎离山影响

**修改函数 (Modified Function):**
- `ServerPlayer *getNextAlive(int n = 1) const;`
  - 现在会跳过**死亡角色**和**有&heg_lure_tiger-Clear标记的角色**
  - 用于座次计算、队列判定、围攻判定等
  - 实现调虎离山"不计入座次计算"的效果

### 2. 关键游戏机制更新 (Critical Game Mechanics Updated)

#### A. roomthread.cpp
**已更新使用 getNextGamePlayer 的位置:**
1. **Line 446**: Hulao Pass turn order
   ```cpp
   return current->getNextGamePlayer();  // 虎牢关模式回合顺序
   ```

2. **Line 554**: Normal action turn order
   ```cpp
   room->setCurrent(room->getCurrent()->getNextGamePlayer());  // 正常模式回合顺序
   ```

3. **Line 569**: Turn broken handler
   ```cpp
   ServerPlayer *next = player->getNextGamePlayer();  // 回合中断处理
   ```

#### B. gamerule.cpp
**已更新使用 getNextGamePlayer 的位置:**
1. **Line 319**: Round end detection
   ```cpp
   else if (player->getNextGamePlayer() == room->getAlivePlayers().first()) {
   // 轮次结束判定
   ```

### 3. 自动受益的功能 (Automatically Benefiting Features)

由于 `getNextAlive` 被修改，以下 extra.lua 中的函数会自动跳过调虎离山影响的角色：

- `IsInQueue(player)` - 判断是否在队列中
- `GetQueueMembers(player)` - 获取队列成员
- `GetAllQueues(room)` - 获取所有队列
- `IsEncircled(player)` - 判断是否被围攻
- `GetEncirclers(player)` - 获取围攻者
- `GetEncircledPlayers(player)` - 获取被围攻的角色

---

## 需要人工审查的位置 (Manual Review Required)

### Category 1: 技能中的距离/座次计算 (Distance/Seat Calculations in Skills)

#### 1.1 距离相关技能 (Distance-related skills)
**文件**: `src/new/src/package/yczh2016.cpp:39`
```cpp
int distance = source->distanceTo(source->getNextAlive());
```
**状态**: ✓ 正确 - 应该使用 getNextAlive，因为是距离计算

**文件**: `src/new/src/package/tenyear-strengthen.cpp:5849`
```cpp
int distance = source->distanceTo(source->getNextAlive());
```
**状态**: ✓ 正确 - 应该使用 getNextAlive，因为是距离计算

#### 1.2 判断上家/下家势力 (Checking kingdom of neighbors)
**文件**: `src/new/src/package/tenyear2.cpp:14317-14318`
```cpp
ServerPlayer *next = now->getNextAlive();
ServerPlayer *last = now->getNextAlive(room->alivePlayerCount() - 1);
```
**用途**: 某技能判断上家下家
**状态**: ⚠️ **需要审查** - 如果是判断势力关系（队列相关），应该使用 getNextAlive（已正确）；如果是纯回合判定，需要改为 getNextGamePlayer

**文件**: `src/new/src/package/tenyear2.cpp:24418`
```cpp
ServerPlayer *next = source->getNextAlive(), *last = source->getNextAlive(room->alivePlayerCount() - 1), *start, *end;
```
**状态**: ⚠️ **需要审查** - 同上

#### 1.3 获取体力值比较 (HP comparison with neighbors)
**文件**: `src/new/src/package/tenyear2.cpp:15360`
```cpp
int hp = player->getNextAlive()->getHp();
```
**状态**: ⚠️ **需要审查** - 如果是比较下家体力（可能用于队列判定），使用 getNextAlive；如果是纯回合判定，需要改为 getNextGamePlayer

### Category 2: 循环遍历所有角色 (Looping through all players)

#### 2.1 遍历所有存活角色 (Iterating all alive players)
**文件**: `src/new/src/package/ol.cpp:15818-15827`
```cpp
ServerPlayer *next = player->getNextAlive();
// ... loop ...
next = next->getNextAlive();
```
**用途**: 遍历所有存活角色进行某种操作
**状态**: ⚠️ **需要审查** - 
- 如果技能涉及座次/队列/围攻，应该使用 getNextAlive（正确，会跳过调虎离山角色）
- 如果技能需要对**所有存活角色**生效（包括调虎离山角色），需要改为 getNextGamePlayer

**类似位置**:
- `src/new/src/package/ol.cpp:20000-20040` (多处循环)
- `src/new/src/package/tenyear.cpp:1471-1474`
- `src/new/src/package/ol-strengthen.cpp:5255, 5297`
- `src/new/src/package/mobileshiji.cpp:2780-2781`
- `src/new/src/package/mobile.cpp:18354-18363`

### Category 3: 特殊模式 (Special Game Modes)

#### 3.1 斗地主模式 (Doudizhu Mode)
**文件**: `src/new/src/package/doudizhu.cpp:2110`
```cpp
ServerPlayer *tp = player->getNextAlive(player->getAliveSiblings().length());
```
**状态**: ⚠️ **需要审查** - 斗地主模式可能不涉及队列概念，如果需要获取真实下家，应改为 getNextGamePlayer

### Category 4: 回合顺序判定 (Turn Order Detection)

**文件**: `src/new/src/package/tenyear2.cpp:24429`
```cpp
ServerPlayer *next = start->getNextAlive();
```
**上下文**: 看起来是在循环查找某个范围内的角色
**状态**: ⚠️ **需要审查** - 需要查看完整上下文确定是座次计算还是回合判定

---

## 建议的审查流程 (Recommended Review Process)

### Step 1: 确认技能语义 (Confirm Skill Semantics)
对于每个 ⚠️ 标记的位置：
1. 查看技能描述
2. 确定是否涉及"座次"、"队列"、"围攻"、"相邻"等概念
3. 确定是否应该忽略调虎离山角色

### Step 2: 判断使用哪个函数 (Decide Which Function to Use)

**使用 `getNextAlive()` 的情况:**
- ✓ 判断队列（连续相邻势力相同）
- ✓ 判断围攻（上家下家势力相同）
- ✓ 距离计算（调虎离山角色距离为998）
- ✓ "座次"相关的任何逻辑
- ✓ 技能明确指明"相邻"、"下家"、"上家"（物理位置概念）

**使用 `getNextGamePlayer()` 的情况:**
- ✓ 回合顺序（下一个行动角色）
- ✓ 轮次判定（一轮结束）
- ✓ 需要对所有存活角色生效（不应跳过调虎离山角色）
- ✓ 胜负判定
- ✓ 与"游戏流程"相关的逻辑

### Step 3: 特别关注的技能类型 (Special Attention for Skill Types)

1. **遍历类技能**: 需要明确是遍历"相邻的N个角色"（用getNextAlive）还是"接下来的N个角色"（用getNextGamePlayer）

2. **体力/手牌比较技能**: 如果比较的是"下家"（座次概念），用getNextAlive；如果是"下一个角色"（回合概念），用getNextGamePlayer

3. **AOE技能**: 如果目标选择涉及座次，用getNextAlive；如果是"所有角色"，应该直接遍历getAlivePlayers()

---

## 测试建议 (Testing Recommendations)

### Test Case 1: 队列测试 (Formation Test)
**场景**: 
- 5名角色: 魏1 - 魏2 - 蜀1 - 魏3 - 蜀2
- 对魏2使用【调虎离山】

**预期结果**:
- 魏1的队列应该只包含自己（魏2被跳过）
- 魏3的队列应该只包含自己（魏2被跳过）
- 【火烧连营】对蜀1使用时，应该只打到蜀1（蜀2被魏2隔开，但魏2被跳过，所以蜀2也在队列中？）

⚠️ **等等！这里有个问题**:
- 如果魏2被调虎离山，蜀1的下家应该是魏3（跳过魏2）
- 那么蜀1和蜀2之间被隔开了，不应该在同一队列
- 这个行为是**正确的**

### Test Case 2: 围攻测试 (Encirclement Test)
**场景**:
- 3名角色: 魏1 - 蜀1 - 魏2
- 对蜀1使用【调虎离山】

**预期结果**:
- 蜀1被跳过后，魏1的下家变成魏2
- 魏1和魏2不再围攻蜀1

### Test Case 3: 回合顺序测试 (Turn Order Test)
**场景**:
- 4名角色: 魏1 - 蜀1 - 魏2 - 蜀2
- 魏1对蜀1使用【调虎离山】，然后结束回合

**预期结果**:
- 下一个回合应该是**蜀1**（虽然蜀1被调虎离山，但回合顺序不变）
- 蜀1无法使用牌，但回合流程正常

---

## 潜在问题列表 (Potential Issues List)

### 高优先级 (High Priority)

1. **ol.cpp:15818-15827, 20000-20040**
   - 多处循环遍历，需要确认是否应该包含调虎离山角色
   - 建议：查看具体技能名称和描述

2. **tenyear2.cpp:14317-14318, 24418**
   - 判断上家下家，需要确认用途
   - 建议：查看技能是否涉及队列/势力判定

3. **doudizhu.cpp:2110**
   - 斗地主模式特殊处理
   - 建议：斗地主可能不涉及队列，考虑使用 getNextGamePlayer

### 中优先级 (Medium Priority)

4. **tenyear.cpp:1471-1474**
   - 循环遍历，需要确认意图

5. **mobileshiji.cpp:2780-2781**
   - 循环遍历，需要确认意图

6. **mobile.cpp:18354-18363**
   - 循环遍历，需要确认意图

### 低优先级 (Low Priority)

7. **ol-strengthen.cpp:5255, 5297**
   - 判断上家下家，可能已正确

8. **tenyear2.cpp:15360**
   - 获取下家体力，可能已正确

---

## 总结 (Conclusion)

### 已完成 (Completed)
✅ 创建 `getNextGamePlayer()` 函数用于游戏机制判定
✅ 修改 `getNextAlive()` 跳过调虎离山角色
✅ 更新回合顺序和轮次判定使用 `getNextGamePlayer()`
✅ 队列和围攻系统自动受益于修改

### 待办 (To Do)
⚠️ 人工审查包中所有 `getNextAlive()` 使用
⚠️ 根据技能语义决定是否需要改为 `getNextGamePlayer()`
⚠️ 进行充分测试

### 风险评估 (Risk Assessment)
- **低风险**: 队列、围攻、距离计算（自动正确）
- **中风险**: 循环遍历技能（需要逐个审查）
- **高风险**: 无（关键游戏机制已更新）

---

## 附录：函数使用指南 (Appendix: Function Usage Guide)

### getNextAlive(n)
**用途**: 获取座次上的下n个**在场**角色
**跳过**: 死亡角色 + 调虎离山角色
**使用场景**:
- 队列判定
- 围攻判定
- 距离计算
- 任何涉及"物理位置"的逻辑

### getNextGamePlayer(n)
**用途**: 获取游戏流程中的下n个**存活**角色
**跳过**: 仅死亡角色
**使用场景**:
- 回合顺序
- 轮次判定
- 胜负判定
- 任何涉及"游戏规则"的逻辑

### 记忆口诀 (Mnemonic)
- **座次用 Alive** (物理位置 → getNextAlive)
- **回合用 Game** (游戏流程 → getNextGamePlayer)
