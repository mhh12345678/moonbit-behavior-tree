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
