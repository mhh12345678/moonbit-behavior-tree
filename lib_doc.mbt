///|
/// The entry point for the moonbit-behavior-tree library.
/// This package exports all public types and functions.
///
/// # Overview
/// `behavior_tree` provides a composable behavior tree engine for game AI and agents.
///
/// # Key Types
/// - `Blackboard` - Shared context for decision state
/// - `Node` - Tree node with tick/reset lifecycle
/// - `Status` - Execution state: BTSuccess | BTFailure | BTRunning
/// - `Builder` - Fluent API for tree construction
///
/// # Quick Example
/// ```moonbit
/// let bb = Blackboard::new()
/// bb.set_bool("active", true)
/// let tree = Builder::new()
///   .sequence()
///     .condition(fn(bb) { bb.get_bool("active").unwrap_or(false) })
///     .action(fn(_) { println("Running!"); BTSuccess })
///     .end()
///   .build()
/// let _ = tree.tick(bb)
/// ```
