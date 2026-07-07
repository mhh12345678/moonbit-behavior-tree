// Action Node
pub fn action_node(action : (Blackboard) -> Status) -> Node {
  Node::new(action, fn() {})
}

// Condition Node
pub fn condition_node(cond : (Blackboard) -> Bool) -> Node {
  let tick = fn(bb) {
    if cond(bb) {
      Status::BTSuccess
    } else {
      Status::BTFailure
    }
  }
  Node::new(tick, fn() {})
}
