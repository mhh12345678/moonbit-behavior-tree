// ============================================================
// Node: Core Status Types, Ref Cell, Node Interface,
//       and Composite Node Constructors
//
// Status represents the outcome of a single node tick:
//   BTSuccess  - the node completed its goal successfully
//   BTFailure  - the node failed to achieve its goal
//   BTRunning  - the node is still working (multi-tick action)
//
// Node is the fundamental unit: it holds two closures:
//   tick_fn  - called each frame to advance the node
//   reset_fn - called to restore the node to its initial state
//
// Composite nodes combine multiple child nodes:
//   Sequence  - succeed only when ALL children succeed (AND)
//   Selector  - succeed when ANY child succeeds (OR)
//   Parallel  - tick ALL children simultaneously
// ============================================================

pub(all) enum Status {
  BTSuccess
  BTFailure
  BTRunning
} derive(Eq)

/// to_string returns a human-readable representation of the Status.
pub fn Status::to_string(self : Status) -> String {
  match self {
    Status::BTSuccess => "Success"
    Status::BTFailure => "Failure"
    Status::BTRunning => "Running"
  }
}

// ============================================================
// Ref: A mutable reference cell (workaround for MoonBit closures)
// ============================================================

pub struct Ref[T] {
  mut val : T
}

/// Create a new Ref holding the given value.
pub fn[T] Ref::new(val : T) -> Ref[T] {
  { val: val }
}

/// Get the current value.
pub fn[T] Ref::get(self : Ref[T]) -> T {
  self.val
}

/// Set the value.
pub fn[T] Ref::set(self : Ref[T], val : T) -> Unit {
  self.val = val
}

// ============================================================
// Node: The fundamental behavior tree unit
// ============================================================

pub struct Node {
  tick_fn  : (Blackboard) -> Status
  reset_fn : () -> Unit
}

/// Node::new creates a node from tick and reset closures.
pub fn Node::new(tick_fn : (Blackboard) -> Status, reset_fn : () -> Unit) -> Node {
  { tick_fn, reset_fn }
}

/// tick executes the node for one frame and returns its Status.
pub fn Node::tick(self : Node, bb : Blackboard) -> Status {
  (self.tick_fn)(bb)
}

/// reset restores the node to its initial state.
pub fn Node::reset(self : Node) -> Unit {
  (self.reset_fn)()
}

// ============================================================
// Sequence Node (AND Gate)
//
// Ticks children left-to-right. Returns:
//   - BTRunning if any child is Running (remembers position)
//   - BTFailure on the first child that Fails (resets all)
//   - BTSuccess when all children Succeed
// ============================================================

/// sequence_node creates a Sequence composite node.
pub fn sequence_node(children : Array[Node]) -> Node {
  let running_child : Ref[Int] = Ref::new(0)
  let tick = fn(bb) {
    let mut i = running_child.get()
    while i < children.length() {
      let child = children[i]
      let status = child.tick(bb)
      match status {
        Status::BTRunning => {
          running_child.set(i)
          return Status::BTRunning
        }
        Status::BTFailure => {
          for c in children {
            c.reset()
          }
          running_child.set(0)
          return Status::BTFailure
        }
        Status::BTSuccess => {
          i = i + 1
        }
      }
    }
    running_child.set(0)
    Status::BTSuccess
  }
  let reset = fn() {
    running_child.set(0)
    for c in children {
      c.reset()
    }
  }
  Node::new(tick, reset)
}

// ============================================================
// Selector Node (OR Gate)
//
// Ticks children left-to-right. Returns:
//   - BTRunning if any child is Running (remembers position)
//   - BTSuccess on the first child that Succeeds (resets all)
//   - BTFailure when all children Fail
// ============================================================

/// selector_node creates a Selector composite node.
pub fn selector_node(children : Array[Node]) -> Node {
  let running_child : Ref[Int] = Ref::new(0)
  let tick = fn(bb) {
    let mut i = running_child.get()
    while i < children.length() {
      let child = children[i]
      let status = child.tick(bb)
      match status {
        Status::BTRunning => {
          running_child.set(i)
          return Status::BTRunning
        }
        Status::BTSuccess => {
          for c in children {
            c.reset()
          }
          running_child.set(0)
          return Status::BTSuccess
        }
        Status::BTFailure => {
          i = i + 1
        }
      }
    }
    running_child.set(0)
    Status::BTFailure
  }
  let reset = fn() {
    running_child.set(0)
    for c in children {
      c.reset()
    }
  }
  Node::new(tick, reset)
}

// ============================================================
// Random Selector Node
//
// Like a Selector but shuffles children before each full scan.
// Useful for non-deterministic AI behavior (e.g., patrol routes).
// Uses a simple LCG pseudo-random generator seeded externally.
// ============================================================

/// random_selector_node creates a non-deterministic Selector.
/// `seed` is a mutable seed Ref for the internal LCG.
pub fn random_selector_node(children : Array[Node], seed : Ref[Int]) -> Node {
  let order : Ref[Array[Int]] = Ref::new([])
  let initialized : Ref[Bool] = Ref::new(false)

  // LCG: next = (a * x + c) mod m  (Numerical Recipes parameters)
  let lcg_next = fn(s : Int) -> Int {
    (s * 1664525 + 1013904223) % 2147483647
  }

  let shuffle = fn(arr : Array[Int]) -> Unit {
    let n = arr.length()
    let mut i = n - 1
    while i > 0 {
      let s = lcg_next(seed.get())
      seed.set(s)
      let j = ((s % (i + 1)) + (i + 1)) % (i + 1)
      let tmp = arr[i]
      arr[i] = arr[j]
      arr[j] = tmp
      i = i - 1
    }
  }

  let tick = fn(bb) {
    if !(initialized.get()) {
      let indices : Array[Int] = []
      let mut k = 0
      while k < children.length() {
        indices.push(k)
        k = k + 1
      }
      shuffle(indices)
      order.set(indices)
      initialized.set(true)
    }
    let ord = order.get()
    let mut idx = 0
    while idx < ord.length() {
      let child = children[ord[idx]]
      let status = child.tick(bb)
      match status {
        Status::BTSuccess => {
          for c in children {
            c.reset()
          }
          initialized.set(false)
          return Status::BTSuccess
        }
        Status::BTRunning => return Status::BTRunning
        Status::BTFailure => idx = idx + 1
      }
    }
    initialized.set(false)
    Status::BTFailure
  }
  let reset = fn() {
    initialized.set(false)
    for c in children {
      c.reset()
    }
  }
  Node::new(tick, reset)
}

pub(all) enum ParallelPolicy {
  SuccessAll
  SuccessOne
} derive(Eq)

// ============================================================
// Parallel Node
//
// Ticks ALL children on every tick (no short-circuiting).
// Policy controls when the Parallel returns Success/Failure:
//   SuccessAll: succeed only when all children succeed; fail on any failure
//   SuccessOne: succeed when any child succeeds; fail when all fail
// ============================================================

/// parallel_node creates a Parallel composite node.
pub fn parallel_node(children : Array[Node], policy : ParallelPolicy) -> Node {
  let tick = fn(bb) {
    let mut success_count = 0
    let mut failure_count = 0
    let mut running_count = 0
    for child in children {
      let status = child.tick(bb)
      match status {
        Status::BTSuccess => success_count = success_count + 1
        Status::BTFailure => failure_count = failure_count + 1
        Status::BTRunning => running_count = running_count + 1
      }
    }
    let _ = running_count
    match policy {
      ParallelPolicy::SuccessAll => {
        if failure_count > 0 {
          Status::BTFailure
        } else if success_count == children.length() {
          Status::BTSuccess
        } else {
          Status::BTRunning
        }
      }
      ParallelPolicy::SuccessOne => {
        if success_count > 0 {
          Status::BTSuccess
        } else if failure_count == children.length() {
          Status::BTFailure
        } else {
          Status::BTRunning
        }
      }
    }
  }
  let reset = fn() {
    for c in children {
      c.reset()
    }
  }
  Node::new(tick, reset)
}
