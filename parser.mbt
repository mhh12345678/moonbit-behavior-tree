// Trace Node Wrapper for debugging BT execution
pub fn trace_node(name : String, child : Node) -> Node {
  let tick = fn(bb) {
    println("-> Tick: \{name}")
    let status = child.tick(bb)
    println("<- \{name} Result: \{status.to_string()}")
    status
  }
  let reset = fn() {
    println("[Reset] Node: \{name}")
    child.reset()
  }
  Node::new(tick, reset)
}

// Chainable trace method for builder
pub fn Builder::trace(self : Builder, name : String) -> Builder {
  if self.stack.length() > 0 {
    let (_, children) = self.stack[self.stack.length() - 1]
    if children.length() > 0 {
      let idx = children.length() - 1
      children[idx] = trace_node(name, children[idx])
    }
  } else {
    match self.root {
      Some(node) => self.root = Some(trace_node(name, node))
      None => ()
    }
  }
  self
}
