# MoonBit Behavior Tree (moonbit-behavior-tree) 项目申报书

## 一、基本信息
- **项目名称**：MoonBit Behavior Tree (简称 moonbit-bt)
- **项目标识**：`mhh12345678/behavior_tree`
- **仓库地址**：[GitHub](https://github.com/mhh12345678/moonbit-behavior-tree), [Gitlink](https://gitlink.org.cn/mhhmhh/moonbit)
- **项目方向**：游戏引擎组件 / 智能体 AI / 可复用基础库
- **参考/原创**：原创。参考业界通用 BT 规范，结合 MoonBit 类型系统实现。

## 二、项目简介
本项目是纯 MoonBit 编写的、轻量且零外部依赖的行为树决策引擎库。为游戏 NPC 行为和智能体（Agent）决策编排提供高性能、跨平台（wasm-gc, js, native）的决策基础设施。它具备黑板系统、流式 Builder API 与可视化 Trace 调试工具。

## 三、核心功能
1. **状态模型**：`BTSuccess`（成功）、`BTFailure`（失败）、`BTRunning`（运行中），支持跨帧异步动作。
2. **节点类型**：
   - *组合节点*：`Sequence`（顺序）、`Selector`（选择）、`Parallel`（并行）。
   - *修饰节点*：`Inverter`（逆变）、`Succeeder`（总是成功）、`Repeater`（重复）、`Limiter`（频控）。
   - *叶子节点*：`Action`（执行动作）、`Condition`（条件判定）。
3. **上下文共享**：`Blackboard` 黑板系统，支持多类型安全存取。
4. **流畅构建**：链式 Builder 声明式构建行为树，代码自解释。
5. **调试追踪**：Tree Ticker Trace 打印节点 Tick 执行路径，大幅提升调试效率。

## 四、交付计划与路线图
- **第一阶段**：完成 `node.mbt` 与 `blackboard.mbt`，实现基础的组合节点逻辑。
- **第二阶段**：实现各类 `decorator.mbt` 修饰器节点与 `builder.mbt` 链式调用。
- **第三阶段**：引入 `parser.mbt` Trace 功能，编写守卫 NPC 仿真演示程序（`cmd/main`）。
- **第四阶段**：完成 check 与 test 覆盖率（9 个单元测试），发布至 mooncakes.io。
