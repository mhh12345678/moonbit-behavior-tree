# MoonBit Behavior Tree (moonbit-behavior-tree) 项目申报书

## 一、基本信息
- **项目名称**：MoonBit Behavior Tree（moonbit-behavior-tree）
- **项目标识**：`mhh12345678/behavior_tree`
- **参赛者**：mhh12345678
- **GitHub 仓库**：https://github.com/mhh12345678/moonbit-behavior-tree
- **Gitlink 仓库**：https://gitlink.org.cn/mhhmhh/moonbit
- **项目方向**：游戏引擎组件 / 智能体 AI 决策框架 / 可复用基础库
- **是否为移植项目**：否（原创设计，参考业界通用 Behavior Tree 规范）

## 二、项目简介
本项目是纯 MoonBit 编写的、轻量且零外部依赖的行为树决策引擎库。为游戏 NPC 行为和智能体（Agent）决策编排提供高性能、跨平台（wasm-gc / js / native）的决策基础设施。覆盖黑板系统、完整节点模型、事件驱动中断、多树并发调度器与 Trace 调试工具。

## 三、核心功能
1. **状态模型**：`BTSuccess`、`BTFailure`、`BTRunning`，支持跨帧异步动作。
2. **复合节点**：`Sequence`（顺序/AND）、`Selector`（选择/OR）、`Parallel`（并行，SuccessAll/SuccessOne 策略）、`RandomSelector`（随机选择）。
3. **修饰节点**：`Inverter`、`Succeeder`、`Repeater`、`Limiter`、`Retry`（重试N次）、`UntilSuccess`、`UntilFailure`、`Timeout`（超时降级）。
4. **黑板系统**：多类型键值存储，支持 `snapshot/restore` 沙盒隔离，`has/remove/size/clear`。
5. **事件驱动**：`EventBus` + `InterruptNode`，支持外部事件中断正在运行的子树；`ConditionGuardNode` 提供反应式前置条件守卫。
6. **多树调度器**：`Scheduler` 管理多棵行为树，支持优先级排序、独立黑板、暂停/恢复。
7. **流畅构建**：链式 Builder 声明式 API，代码结构自解释。
8. **调试追踪**：`trace_node` 包装任意节点，实时打印 Tick 执行路径。

## 四、交付计划
- ✅ 核心节点模型（Sequence/Selector/Parallel）与黑板系统；
- ✅ 修饰器（8 种）与 Builder 流式 API；
- ✅ 事件总线与中断节点、条件守卫节点；
- ✅ 多树 Scheduler 调度器；
- ✅ 单元测试 21 例（全部通过），守卫 NPC 仿真演示；
- ✅ GitHub Actions CI（wasm-gc / js / native 全平台）；
- 🔄 发布至 mooncakes.io（待验收阶段完成）。
