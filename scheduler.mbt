// ============================================================
// Scheduler: Multi-Tree Concurrent Behavior Tree Scheduler
//
// The Scheduler manages a list of named behavior tree roots
// and ticks them in priority order each frame. This allows
// multiple independent AI agents (NPCs) to share a single
// tick loop while maintaining isolated Blackboard contexts.
//
// Features:
//   - Add/remove named trees at runtime
//   - Priority-ordered tick (lower index = higher priority)
//   - Per-tree Blackboard isolation
//   - Pause / resume individual trees
//   - Collect per-tree tick results
// ============================================================

/// Entry wraps a behavior tree with its dedicated blackboard and runtime state.
pub struct SchedulerEntry {
  name    : String
  root    : Node
  bb      : Blackboard
  paused  : Ref[Bool]
}

/// SchedulerEntry::new creates an entry for the given tree root.
pub fn SchedulerEntry::new(name : String, root : Node, bb : Blackboard) -> SchedulerEntry {
  { name, root, bb, paused: Ref::new(false) }
}

/// TickResult records the outcome of a single tree tick in the scheduler.
pub struct TickResult {
  name   : String
  status : Status
}

/// Scheduler drives multiple named behavior trees in priority order.
pub struct Scheduler {
  entries : Array[SchedulerEntry]
}

/// Create a new empty Scheduler.
pub fn Scheduler::new() -> Scheduler {
  { entries: [] }
}

/// Add a behavior tree to the scheduler.
/// Trees are ticked in the order they are added.
pub fn Scheduler::add(self : Scheduler, entry : SchedulerEntry) -> Unit {
  self.entries.push(entry)
}

/// Remove a behavior tree by name.
pub fn Scheduler::remove(self : Scheduler, name : String) -> Unit {
  let mut i = 0
  while i < self.entries.length() {
    if self.entries[i].name == name {
      let _ = self.entries.remove(i)
      break
    }
    i = i + 1
  }
}

/// Pause a named tree so it is skipped during tick.
pub fn Scheduler::pause(self : Scheduler, name : String) -> Unit {
  for entry in self.entries {
    if entry.name == name {
      entry.paused.set(true)
      break
    }
  }
}

/// Resume a paused tree.
pub fn Scheduler::restart(self : Scheduler, name : String) -> Unit {
  for entry in self.entries {
    if entry.name == name {
      entry.paused.set(false)
      break
    }
  }
}

/// Reset all trees managed by this scheduler.
pub fn Scheduler::reset_all(self : Scheduler) -> Unit {
  for entry in self.entries {
    entry.root.reset()
  }
}

/// Tick all non-paused trees once and return per-tree results.
pub fn Scheduler::tick(self : Scheduler) -> Array[TickResult] {
  let results : Array[TickResult] = []
  for entry in self.entries {
    if !(entry.paused.get()) {
      let status = entry.root.tick(entry.bb)
      results.push({ name: entry.name, status })
    }
  }
  results
}

/// Returns the number of entries registered in the scheduler.
pub fn Scheduler::size(self : Scheduler) -> Int {
  self.entries.length()
}

/// Returns true if a tree with the given name exists in the scheduler.
pub fn Scheduler::has(self : Scheduler, name : String) -> Bool {
  let found = Ref::new(false)
  for entry in self.entries {
    if entry.name == name {
      found.set(true)
    }
  }
  found.get()
}
