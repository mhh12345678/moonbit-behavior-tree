// Helper function to create a sequence node from a variable argument list.
// This wraps the sequence_node constructor for improved ergonomics.
pub fn make_sequence(children : Array[Node]) -> Node {
  sequence_node(children)
}

// Helper function to create a selector node from an array of children.
pub fn make_selector(children : Array[Node]) -> Node {
  selector_node(children)
}

// Helper function to create a parallel node with SuccessAll policy.
pub fn make_parallel_all(children : Array[Node]) -> Node {
  parallel_node(children, ParallelPolicy::SuccessAll)
}

// Helper function to create a parallel node with SuccessOne policy.
pub fn make_parallel_one(children : Array[Node]) -> Node {
  parallel_node(children, ParallelPolicy::SuccessOne)
}

// create_always_success creates a leaf node that always succeeds.
pub fn create_always_success() -> Node {
  action_node(fn(_) { Status::BTSuccess })
}

// create_always_failure creates a leaf node that always fails.
pub fn create_always_failure() -> Node {
  action_node(fn(_) { Status::BTFailure })
}

// create_always_running creates a leaf node that always returns Running.
pub fn create_always_running() -> Node {
  action_node(fn(_) { Status::BTRunning })
}
