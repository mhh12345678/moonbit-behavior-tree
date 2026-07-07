// Inverter Decorator
pub fn inverter_node(child : Node) -> Node {
  let tick = fn(bb) {
    let status = child.tick(bb)
    match status {
      Status::BTSuccess => Status::BTFailure
      Status::BTFailure => Status::BTSuccess
      Status::BTRunning => Status::BTRunning
    }
  }
  let reset = fn() {
    child.reset()
  }
  Node::new(tick, reset)
}

// Succeeder Decorator
pub fn succeeder_node(child : Node) -> Node {
  let tick = fn(bb) {
    let status = child.tick(bb)
    match status {
      Status::BTRunning => Status::BTRunning
      _ => Status::BTSuccess
    }
  }
  let reset = fn() {
    child.reset()
  }
  Node::new(tick, reset)
}
