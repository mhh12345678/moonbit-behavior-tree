# MoonBit Behavior Tree

[![CI](https://github.com/mhh12345678/moonbit-behavior-tree/actions/workflows/ci.yml/badge.svg)](https://github.com/mhh12345678/moonbit-behavior-tree/actions/workflows/ci.yml)

一个使用纯 MoonBit 编写的、轻量、高性能且零外部依赖的**行为树（Behavior Tree）决策引擎库**。适用于游戏 NPC AI 控制、智能体（Agent）的任务流程决策与复杂业务编排。

## 特性

- **零外部依赖**：仅依赖 MoonBit 标准库，适用于 WebAssembly (`wasm-gc`)、JavaScript 以及 Native 平台。
- **黑板系统（Blackboard）**：内置共享上下文，解耦节点决策状态与执行行为，支持 `Bool`、`Int`、`Double`、`String` 多类型。
- **完整节点模型**：
  - **组合节点 (Composites)**：`Sequence`（顺序）、`Selector`（选择）、`Parallel`（并行，支持 `SuccessAll`/`SuccessOne` 策略）。
  - **修饰节点 (Decorators)**：`Inverter`（逆变）、`Succeeder`（始终成功）、`Repeater`（重复N次）、`Limiter`（执行频率限制）。
  - **叶子节点 (Leaves)**：`Action`（动作，支持跨帧 `Running` 状态）、`Condition`（条件判定）。
- **流式 Builder 接口**：支持链式声明式 API，树结构自解释，极易维护。
- **调试追踪（Trace）**：`.trace("name")` 一键为任意节点挂载打印钩子，实时追踪 Tick 执行路径。

## 快速开始

### 1. 声明依赖

在你的 MoonBit 项目 `moon.mod` 中添加本库：

```
import {
  "mhh12345678/behavior_tree" @bt,
}
```

或使用命令行安装：

```bash
moon add mhh12345678/behavior_tree
```

### 2. 基础使用示例

```moonbit
// 1. 创建共享黑板并初始化状态
let bb = @bt.Blackboard::new()
bb.set_int("health", 45)
bb.set_bool("enemy_in_sight", true)

// 2. 使用 Builder 链式定义行为树
let tree = @bt.Builder::new()
  .selector()
    // 条件1：血量低则逃跑
    .sequence()
      .condition(fn(bb) { bb.get_int("health").unwrap_or(100) < 50 })
      .action(fn(_) { println("Low health! Fleeing..."); @bt.BTSuccess })
      .end()
    // 条件2：发现敌人则攻击
    .sequence()
      .condition(fn(bb) { bb.get_bool("enemy_in_sight").unwrap_or(false) })
      .action(fn(_) { println("Enemy spotted! Attacking..."); @bt.BTSuccess })
      .end()
    // 默认行为：巡逻
    .action(fn(_) { println("Patrolling..."); @bt.BTSuccess })
    .end()
  .build()

// 3. 执行单次决策 Tick
let status = tree.tick(bb)
println("Result: \{status.to_string()}")
```

## 项目结构

```
.
├── blackboard.mbt          # 黑板共享上下文
├── node.mbt                # Status 枚举、Node 结构、Sequence/Selector/Parallel
├── decorator.mbt           # Inverter / Succeeder / Repeater / Limiter 修饰器
├── leaf.mbt                # Action / Condition 叶子节点
├── builder.mbt             # 链式流式 Builder API
├── parser.mbt              # 调试 Trace 节点包装器
├── behavior_tree_wbtest.mbt # 白盒单元测试 (9 cases)
├── cmd/main/main.mbt       # 守卫 NPC AI 仿真演示
└── .github/workflows/ci.yml # CI 自动化检查与测试
```

## 运行与测试

```bash
# 类型检查（全平台）
moon check --target all

# 执行测试（9个用例，全部通过）
moon test --target all

# 运行 NPC AI 仿真演示
moon run cmd/main
```

## 示例输出

运行 `moon run cmd/main`，你将看到守卫 NPC 在"巡逻 → 追击 → 攻击 → 负伤逃跑"全流程中的 Tick 决策追踪：

```
=== MoonBit Behavior Tree Guard AI Simulation ===

--- Tick 1: Patrol mode (no enemy in sight) ---
-> Tick: Patrol Action
AI ACTION: Patrol waypoint 1
<- Patrol Action Result: Success

--- Tick 3: Enemy spotted at distance 8.0 ---
-> Tick: Combat Branch
AI ACTION: Chasing enemy... distance is now 5
<- Combat Branch Result: Running

--- Tick 7: Guard gets damaged (HP = 20), flees ---
-> Tick: Flee Branch
AI ACTION: Low health! Fleeing...
<- Flee Branch Result: Success
```

## 许可证

本项目采用 [Apache-2.0](LICENSE) 开源许可证。

---

## 参考资料

- 行为树规范：[Behavior Trees in AI](https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control))
- MoonBit 文档：[https://docs.moonbitlang.com](https://docs.moonbitlang.com)
- mooncakes.io 包注册表：[https://mooncakes.io](https://mooncakes.io)
