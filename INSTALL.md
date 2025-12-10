# 年度回顾功能 - 快速安装指南

## 🚀 3分钟快速安装

### 步骤1: 复制核心文件（必需）

将以下文件复制到游戏目录：

```
extensions/year_review.lua  →  [游戏目录]/extensions/year_review.lua
```

### 步骤2: 配置加载（必需）

**方法A: 自动加载（推荐）**

如果游戏会自动加载 `extensions` 目录下的所有 `.lua` 文件，则无需额外配置。

**方法B: 手动加载**

在游戏的主加载文件中添加：

```lua
require "extensions.year_review"
```

或

```lua
dofile("extensions/year_review.lua")
```

### 步骤3: 验证安装（可选）

启动游戏后，在Lua控制台运行：

```lua
-- 检查技能是否加载
if sgs.Sanguosha:getSkill("year_review_game_start") then
    print("✓ 年度回顾功能已成功安装！")
else
    print("✗ 安装失败，请检查文件路径")
end
```

### 步骤4: 开始使用

玩几局游戏后，运行：

```lua
ShowYearReview("你的玩家名")
```

就可以看到你的年度回顾了！

---

## 📦 完整安装（推荐）

如果你想使用所有功能，可以复制以下所有文件：

```
必需文件:
✓ extensions/year_review.lua          (核心功能)

推荐文件:
✓ year_review_viewer.lua              (数据查看器)
✓ 年度回顾功能说明.md                 (使用文档)

可选文件:
○ year_review_test.lua                (测试示例)
○ year_review_integration.lua         (集成示例)
○ YEAR_REVIEW_README.md               (项目说明)
○ 年度回顾_项目总览.md                (总览文档)
○ year_review_data_sample.json        (示例数据)
```

---

## 🔧 常见安装问题

### 问题1: 找不到文件

**症状**: 游戏启动时提示 "cannot open file"

**解决方法**:
1. 检查文件路径是否正确
2. 确认文件名是否完全一致（区分大小写）
3. 检查文件编码是否为 UTF-8

### 问题2: 技能未加载

**症状**: 验证安装时显示 "未找到"

**解决方法**:
1. 确认游戏是否执行了加载语句
2. 检查是否有语法错误
3. 查看游戏日志文件

### 问题3: 没有数据

**症状**: ShowYearReview 返回 "没有找到数据"

**解决方法**:
1. 至少玩一局完整的游戏
2. 确认玩家名是否正确（区分大小写）
3. 检查是否生成了 year_review_data.json 文件

---

## 📝 快速测试

安装完成后，运行以下测试脚本：

```lua
-- 测试脚本
print("=== 年度回顾功能测试 ===")

-- 1. 检查核心函数
if ShowYearReview then
    print("✓ ShowYearReview 函数已加载")
else
    print("✗ ShowYearReview 函数未找到")
end

if ExportYearReviewHTML then
    print("✓ ExportYearReviewHTML 函数已加载")
else
    print("✗ ExportYearReviewHTML 函数未找到")
end

-- 2. 检查技能
local skills = {
    "year_review_game_start",
    "year_review_game_over",
    "year_review_skill",
    "year_review_card"
}

local all_ok = true
for _, skill_name in ipairs(skills) do
    if sgs.Sanguosha:getSkill(skill_name) then
        print("✓ " .. skill_name)
    else
        print("✗ " .. skill_name)
        all_ok = false
    end
end

-- 3. 输出结果
if all_ok then
    print("\n✓✓✓ 所有组件安装成功！✓✓✓")
    print("现在可以开始游戏，系统将自动记录数据")
else
    print("\n✗✗✗ 部分组件安装失败 ✗✗✗")
    print("请检查安装步骤")
end

print("======================")
```

---

## 🎮 使用示例

### 示例1: 查看本年度回顾

```lua
ShowYearReview("张三")
```

### 示例2: 查看历史年份

```lua
ShowYearReview("张三", "2023")
```

### 示例3: 导出HTML报告

```lua
ExportYearReviewHTML("张三")
-- 将在游戏目录生成 year_review_张三_2024.html
```

### 示例4: 使用数据查看器

```lua
dofile("year_review_viewer.lua")

-- 查看所有玩家
ListAllPlayers()

-- 查看排行榜
RankPlayersByYear("2024")

-- 查看年度总览
YearOverview("2024")
```

---

## 📊 数据位置

安装后，数据将保存在：

```
[游戏目录]/year_review_data.json
```

**建议**:
- 定期备份此文件
- 不要手动编辑（除非你知道在做什么）
- 数据量大时可以归档旧年份数据

---

## 💡 小贴士

1. **首次使用**: 至少玩一局完整的游戏才会有数据
2. **玩家名**: 玩家名区分大小写，确保输入正确
3. **性能**: 对游戏性能影响极小，放心使用
4. **多年份**: 支持跨年份统计，数据自动分年存储
5. **多玩家**: 支持多个玩家独立统计

---

## 🆘 需要帮助？

如果遇到问题：

1. **查看文档**: 阅读 `年度回顾功能说明.md`
2. **检查日志**: 查看游戏的错误日志
3. **验证安装**: 运行上面的测试脚本
4. **示例数据**: 参考 `year_review_data_sample.json`

---

## ✅ 安装检查清单

安装前请确认：

- [ ] 已下载所有必需文件
- [ ] 文件已放置在正确位置
- [ ] 已配置加载语句（如果需要）
- [ ] 文件编码为 UTF-8
- [ ] 游戏支持 Lua 5.1+
- [ ] 有 JSON 库支持

安装后请验证：

- [ ] 运行测试脚本无错误
- [ ] 技能已成功加载
- [ ] 玩一局后能查看数据
- [ ] 能正常导出 HTML

全部打勾即表示安装成功！

---

## 🎉 恭喜！

如果一切顺利，你现在已经成功安装了年度回顾功能！

开始游戏，享受数据统计的乐趣吧！ 🎮📊

---

**版本**: 1.0.0  
**更新日期**: 2024-12-10
