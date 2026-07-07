# MoonBit Behavior Tree (moonbit-behavior-tree)

一个使用纯 MoonBit 编写的、轻量、高性能且零外部依赖的行为树决策引擎库。适用于游戏 NPC AI 控制、智能体（Agent）的任务流程决策与复杂业务编排。

## 特性

*   **零外部依赖**：仅依赖 MoonBit 标准库，体积小巧，跨平台，适用于 WebAssembly (wasm-gc), JavaScript 以及 Native 平台。
*   **黑板系统**：内置 Blackboard 共享上下文，解耦节点决策状态与执行行为。
*   **完整节点模型**：
    *   **组合节点 (Composites)**：`Sequence`（顺序）、`Selector`（选择）、`Parallel`（并行）。
    *   **修饰节点 (Decorators)**：`Inverter`（逆变）、`Succeeder`（始终成功）、`Repeater`（重复）、`Limiter`（执行频率限制）。
    *   **叶子节点 (Leaves)**：`Action`（动作，支持 `Running` 状态）、`Condition`（条件）。
*   **流式 Builder 接口**：支持链式、流式 API 构建树，结构清晰直观。
*   **调试追踪 (Trace)**：提供运行轨迹追踪记录，极大降低 AI 行为调试复杂度。

## 快速开始

### 1. 声明依赖

在你的 MoonBit 项目 `moon.mod.json` (或 `moon.mod`) 中添加本项目：

```json
{
  "deps": {
    "username/behavior_tree": "0.1.0"
  }
}
```

### 2. 基础使用示例

```moonbit
// 1. 创建共享黑板并初始化状态
let blackboard = @behavior_tree.Blackboard::new()
blackboard.set_int("health", 45)
blackboard.set_bool("enemy_in_sight", true)

// 2. 使用 Builder 链式定义行为树
let bt = @behavior_tree.Builder::new()
  .selector()
    // 条件1：血量低则逃跑
    .sequence()
      .condition(fn(bb) { bb.get_int("health").unwrap_or(100) < 50 })
      .action(fn(bb) { 
        println("Health low! Fleeing...")
        @behavior_tree.Status::Success 
      })
      .end()
    // 条件2：发现敌人则攻击
    .sequence()
      .condition(fn(bb) { bb.get_bool("enemy_in_sight").unwrap_or(false) })
      .action(fn(bb) {
        println("Enemy spotted! Attacking...")
        @behavior_tree.Status::Success
      })
      .end()
    // 默认行为：巡逻
    .action(fn(_bb) {
      println("Patrolling...")
      @behavior_tree.Status::Success
    })
    .end()
  .build()

// 3. 执行单次决策 Tick
let status = bt.tick(blackboard)
println("Execution status: \{status}")
```

## 运行与测试

进入项目根目录：

*   **运行类型检查**：
    ```bash
    moon check --target all
    ```
*   **执行测试用例**：
    ```bash
    moon test --target all
    ```
*   **运行 NPC AI 示例程序**：
    ```bash
    moon run cmd/main
    ```

## 许可证

本项目采用 [Apache-2.0](LICENSE) 开源许可证。
