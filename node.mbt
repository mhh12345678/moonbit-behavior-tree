pub(all) enum Status {
  BTSuccess
  BTFailure
  BTRunning
} derive(Eq)

pub fn Status::to_string(self : Status) -> String {
  match self {
    Status::BTSuccess => "Success"
    Status::BTFailure => "Failure"
    Status::BTRunning => "Running"
  }
}

pub struct Ref[T] {
  mut val : T
}

pub fn[T] Ref::new(val : T) -> Ref[T] {
  { val: val }
}

pub fn[T] Ref::get(self : Ref[T]) -> T {
  self.val
}

pub fn[T] Ref::set(self : Ref[T], val : T) -> Unit {
  self.val = val
}

pub struct Node {
  tick_fn : (Blackboard) -> Status
  reset_fn : () -> Unit
}

pub fn Node::new(tick_fn : (Blackboard) -> Status, reset_fn : () -> Unit) -> Node {
  { tick_fn, reset_fn }
}

pub fn Node::tick(self : Node, bb : Blackboard) -> Status {
  (self.tick_fn)(bb)
}

pub fn Node::reset(self : Node) -> Unit {
  (self.reset_fn)()
}

// Sequence Node
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

// Selector Node
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
