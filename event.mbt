// ============================================================
// Event: Interrupt / Event-Driven Subtree for Behavior Trees
//
// EventBus allows nodes to emit named events and register
// handlers that fire when events are received. Combined with
// the InterruptNode, this enables reactive, event-driven
// behavior trees where an external condition can abort the
// currently running subtree and switch to an interrupt handler.
// ============================================================

/// EventBus holds a set of pending events and registered handlers.
pub struct EventBus {
  pending   : Map[String, Bool]
  handlers  : Map[String, (Blackboard) -> Status]
}

/// Create a new EventBus.
pub fn EventBus::new() -> EventBus {
  { pending: Map([]), handlers: Map([]) }
}

/// Raise a named event so it will be consumed on the next tick.
pub fn EventBus::emit(self : EventBus, name : String) -> Unit {
  self.pending.set(name, true)
}

/// Register a handler closure for a named event.
/// When the event fires and the InterruptNode is ticked, this handler runs.
pub fn EventBus::on(self : EventBus, name : String, handler : (Blackboard) -> Status) -> Unit {
  self.handlers.set(name, handler)
}

/// Check if a named event is currently pending.
pub fn EventBus::has_event(self : EventBus, name : String) -> Bool {
  self.pending.get(name).unwrap_or(false)
}

/// Consume (clear) a named event after it has been handled.
pub fn EventBus::consume(self : EventBus, name : String) -> Unit {
  self.pending.remove(name)
}

/// Clear all pending events.
pub fn EventBus::clear_all(self : EventBus) -> Unit {
  let keys : Array[String] = []
  self.pending.each(fn(k, _) { keys.push(k) })
  for k in keys {
    self.pending.remove(k)
  }
}

// ============================================================
// InterruptNode
//
// An InterruptNode monitors a named event on the provided EventBus.
// On each tick:
//   - If the named event is pending, the interrupt handler fires
//     (and the child subtree is reset), then the event is consumed.
//   - Otherwise, the child subtree ticks normally.
// This allows external triggers (e.g. "enemy_spotted") to
// preempt an ongoing behavior.
// ============================================================

/// interrupt_node creates a node that monitors a named event.
/// When the event is raised, `interrupt_handler` runs instead of `child`.
pub fn interrupt_node(
  bus              : EventBus,
  event_name       : String,
  child            : Node,
  interrupt_handler: Node,
) -> Node {
  let tick = fn(bb) {
    if bus.has_event(event_name) {
      bus.consume(event_name)
      child.reset()
      interrupt_handler.tick(bb)
    } else {
      child.tick(bb)
    }
  }
  let reset = fn() {
    child.reset()
    interrupt_handler.reset()
  }
  Node::new(tick, reset)
}

// ============================================================
// ConditionGuard
//
// A ConditionGuard monitors a predicate on every tick. If the
// predicate turns false while the child is Running, it aborts
// the child (reset) and returns Failure immediately. This is
// the reactive variant of Condition, suitable for precondition
// checks that must hold throughout a long-running action.
// ============================================================

/// condition_guard_node creates a reactive guard wrapper.
/// It ticks `child` only while `predicate(bb)` is true.
/// If the predicate fails mid-execution, the child is reset and Failure is returned.
pub fn condition_guard_node(
  predicate : (Blackboard) -> Bool,
  child     : Node,
) -> Node {
  let tick = fn(bb) {
    if predicate(bb) {
      child.tick(bb)
    } else {
      child.reset()
      Status::BTFailure
    }
  }
  let reset = fn() {
    child.reset()
  }
  Node::new(tick, reset)
}
