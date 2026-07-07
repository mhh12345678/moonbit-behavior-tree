# MoonBit Behavior Tree

[![CI](https://github.com/mhh12345678/moonbit-behavior-tree/actions/workflows/ci.yml/badge.svg)](https://github.com/mhh12345678/moonbit-behavior-tree/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

一个使用纯 MoonBit 编写的、轻量、高性能且零外部依赖的**行为树（Behavior Tree）决策引擎库**。

适用于游戏 NPC AI 控制、智能体（Agent）的任务流程决策与复杂业务编排，支持 WebAssembly (`wasm-gc`)、JavaScript 以及 Native 全平台。

## 特性

| 模块 | 说明 |
|------|------|
| **Blackboard** | 共享键值上下文，支持 `snapshot/restore` 沙盒、`has/remove/size/clear` |
| **Sequence** | 顺序节点（AND 门），支持跨帧 Running 状态恢复 |
| **Selector** | 选择节点（OR 门），支持跨帧 Running 状态恢复 |
| **Parallel** | 并行节点，`SuccessAll`/`SuccessOne` 策略可配置 |
| **RandomSelector** | 随机顺序选择（LCG 伪随机），适合非确定性 AI |
| **Inverter** | 逆变修饰器（取反 Success/Failure） |
| **Succeeder** | 始终成功修饰器 |
| **Repeater** | 重复N次修饰器 |
| **Limiter** | 执行频率限制修饰器 |
| **Retry** | 失败重试修饰器（最多N次） |
| **UntilSuccess** | 持续重试直到成功 |
| **UntilFailure** | 持续重试直到失败 |
| **Timeout** | 超时降级修饰器（超过N帧强制Failure） |
| **Action / Condition** | 叶子节点，Action 支持 Running 跨帧状态 |
| **EventBus** | 事件总线，支持 emit/consume/clear |
| **InterruptNode** | 事件中断节点，外部事件抢占正在运行的子树 |
| **ConditionGuardNode** | 反应式前置条件守卫，持续监控断言 |
| **Scheduler** | 多树并发调度器，per-tree 独立黑板，支持暂停/恢复 |
| **Builder** | 链式声明式 API，结构自解释，极易维护 |
| **TraceNode** | 调试追踪包装器，实时打印 Tick 执行路径 |

## 安装

### 方法一：moon add（推荐）

```bash
moon add mhh12345678/behavior_tree
```

### 方法二：手动添加依赖

在 `moon.mod` 中声明：

```
import {
  "mhh12345678/behavior_tree" @bt,
}
```

## 快速开始

```moonbit
// 1. 创建共享黑板
let bb = @bt.Blackboard::new()
bb.set_int("health", 45)
bb.set_bool("enemy_in_sight", true)

// 2. 使用 Builder 声明式构建行为树
let tree = @bt.Builder::new()
  .selector()
    // 血量低时逃跑（优先级最高）
    .sequence()
      .condition(fn(bb) { bb.get_int("health").unwrap_or(100) < 50 })
      .action(fn(_) { println("Low health! Fleeing..."); @bt.BTSuccess })
      .end()
    // 发现敌人则追击
    .sequence()
      .condition(fn(bb) { bb.get_bool("enemy_in_sight").unwrap_or(false) })
      .action(fn(_) { println("Enemy spotted! Chasing..."); @bt.BTSuccess })
      .end()
    // 默认巡逻
    .action(fn(_) { println("Patrolling..."); @bt.BTSuccess })
    .end()
  .build()

// 3. 执行单次 Tick
let status = tree.tick(bb)
println("Result: \{status.to_string()}")
// 输出: Low health! Fleeing...
// 输出: Result: Success
```

## 高级用法

### 事件中断（InterruptNode）

```moonbit
let bus = @bt.EventBus::new()
let tree = @bt.interrupt_node(bus, "enemy_spotted", patrol_tree, attack_tree)

// 在任意时刻发出事件，下一次 tick 会切换到 attack_tree
bus.emit("enemy_spotted")
let _ = tree.tick(bb)
```

### 多 NPC 并发调度（Scheduler）

```moonbit
let sched = @bt.Scheduler::new()
sched.add(@bt.SchedulerEntry::new("guard1", guard_tree, @bt.Blackboard::new()))
sched.add(@bt.SchedulerEntry::new("guard2", patrol_tree, @bt.Blackboard::new()))

// 单次帧调用，所有 NPC 同时 tick
let results = sched.tick()
for r in results {
  println("\{r.name}: \{r.status.to_string()}")
}
```

### 黑板快照沙盒

```moonbit
bb.set_int("hp", 100)
bb.snapshot()         // 保存当前状态
bb.set_int("hp", 0)   // 模拟伤害
// 测试沙盒内的行为...
bb.restore()          // 回滚到快照
// bb.get_int("hp") == Some(100)
```

## 项目结构

```
.
├── blackboard.mbt          # 黑板上下文（snapshot/restore）
├── node.mbt                # Status / Ref / Node / Sequence / Selector / Parallel / RandomSelector
├── decorator.mbt           # 8 种修饰器节点
├── leaf.mbt                # Action / Condition 叶子节点
├── builder.mbt             # 链式 Builder API
├── parser.mbt              # Trace 调试节点包装器
├── event.mbt               # EventBus / InterruptNode / ConditionGuardNode
├── scheduler.mbt           # 多树 Scheduler 调度器
├── helpers.mbt             # 便捷工厂函数
├── behavior_tree_wbtest.mbt # 核心单元测试（9 cases）
├── integration_test.mbt    # 集成测试（12 cases，含新模块）
├── lib_doc.mbt             # 库文档快速入门示例
├── cmd/main/main.mbt       # 守卫 NPC AI 仿真演示
└── .github/workflows/ci.yml # CI：wasm-gc / js / native 全平台
```

## 运行与测试

```bash
# 类型检查（全平台）
moon check --target all

# 执行 21 个测试用例（全部通过）
moon test --target all

# 运行守卫 NPC AI 仿真演示
moon run cmd/main
```

### 示例输出

```
=== MoonBit Behavior Tree Guard AI Simulation ===

--- Tick 1: Patrol mode ---
-> Tick: Patrol Action
AI ACTION: Patrol waypoint 1
<- Patrol Action Result: Success

--- Tick 3: Enemy spotted at distance 8.0 ---
-> Tick: Combat Branch
AI ACTION: Chasing enemy... distance 5
<- Combat Branch Result: Running

--- Tick 7: Guard HP=20, flees ---
-> Tick: Flee Branch
AI ACTION: Low health! Fleeing...
<- Flee Branch Result: Success
```

## 许可证

本项目采用 [Apache-2.0](LICENSE) 开源许可证。

---

## 参考资料

- Behavior Trees in AI：https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control)
- MoonBit 文档：https://docs.moonbitlang.com
- mooncakes.io：https://mooncakes.io
