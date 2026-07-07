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

// Repeater Decorator
pub fn repeater_node(child : Node, max_repeats : Int) -> Node {
  let current_count : Ref[Int] = Ref::new(0)
  let tick = fn(bb) {
    if max_repeats >= 0 && current_count.get() >= max_repeats {
      current_count.set(0)
      return Status::BTSuccess
    }
    let status = child.tick(bb)
    match status {
      Status::BTRunning => Status::BTRunning
      Status::BTFailure => {
        current_count.set(0)
        Status::BTFailure
      }
      Status::BTSuccess => {
        current_count.set(current_count.get() + 1)
        if max_repeats >= 0 && current_count.get() >= max_repeats {
          current_count.set(0)
          Status::BTSuccess
        } else {
          Status::BTRunning
        }
      }
    }
  }
  let reset = fn() {
    current_count.set(0)
    child.reset()
  }
  Node::new(tick, reset)
}

// Limiter Decorator
pub fn limiter_node(child : Node, min_ticks : Int) -> Node {
  let tick_counter : Ref[Int] = Ref::new(min_ticks) // Initialize with min_ticks so it runs on first tick
  let tick = fn(bb) {
    let current = tick_counter.get()
    if current < min_ticks {
      tick_counter.set(current + 1)
      return Status::BTFailure
    }
    let status = child.tick(bb)
    match status {
      Status::BTSuccess | Status::BTFailure => tick_counter.set(0)
      Status::BTRunning => ()
    }
    status
  }
  let reset = fn() {
    tick_counter.set(min_ticks)
    child.reset()
  }
  Node::new(tick, reset)
}
