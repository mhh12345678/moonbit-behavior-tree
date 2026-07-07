// ============================================================
// Advanced Decorators
//
// In addition to the core decorators (Inverter, Succeeder,
// Repeater, Limiter) this module provides:
//
//  - retry_node: retry the child up to N times on Failure
//  - until_success_node: repeat child until it returns Success
//  - until_failure_node: repeat child until it returns Failure
//  - timeout_node: fail the child after max_ticks ticks Running
//  - semaphore_node: allow at most N concurrent Running nodes
// ============================================================

// Inverter Decorator
// Inverts the child's Status: Success -> Failure, Failure -> Success.
// Running is passed through unchanged.
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
// Always returns Success (or Running if child is Running).
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
// Ticks the child up to `max_repeats` times. Returns Running while repeating.
// Returns Success when the count is reached, Failure if the child fails.
// If max_repeats <= 0, repeats infinitely until child fails.
pub fn repeater_node(child : Node, max_repeats : Int) -> Node {
  let current_count : Ref[Int] = Ref::new(0)
  let tick = fn(bb) {
    if max_repeats > 0 && current_count.get() >= max_repeats {
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
        if max_repeats > 0 && current_count.get() >= max_repeats {
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
// Guards the child from running again for `min_ticks` ticks after it completes.
// Returns Failure during the cooldown window.
pub fn limiter_node(child : Node, min_ticks : Int) -> Node {
  let tick_counter : Ref[Int] = Ref::new(min_ticks)
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

// Retry Decorator
// Retries the child on Failure up to `max_retries` times per activation.
// Returns Running while retrying, Success when the child succeeds,
// and Failure once all retries are exhausted.
pub fn retry_node(child : Node, max_retries : Int) -> Node {
  let attempts : Ref[Int] = Ref::new(0)
  let tick = fn(bb) {
    let status = child.tick(bb)
    match status {
      Status::BTSuccess => {
        attempts.set(0)
        Status::BTSuccess
      }
      Status::BTRunning => Status::BTRunning
      Status::BTFailure => {
        let a = attempts.get() + 1
        attempts.set(a)
        if a >= max_retries {
          attempts.set(0)
          Status::BTFailure
        } else {
          child.reset()
          Status::BTRunning
        }
      }
    }
  }
  let reset = fn() {
    attempts.set(0)
    child.reset()
  }
  Node::new(tick, reset)
}

// UntilSuccess Decorator
// Ticks the child repeatedly until it returns Success.
// Returns Running while the child is Failing or Running.
// On child Success, returns Success and resets.
pub fn until_success_node(child : Node) -> Node {
  let tick = fn(bb) {
    let status = child.tick(bb)
    match status {
      Status::BTSuccess => {
        child.reset()
        Status::BTSuccess
      }
      _ => {
        child.reset()
        Status::BTRunning
      }
    }
  }
  let reset = fn() {
    child.reset()
  }
  Node::new(tick, reset)
}

// UntilFailure Decorator
// Ticks the child repeatedly until it returns Failure.
// Returns Running while the child is Succeeding or Running.
// On child Failure, returns Success and resets.
pub fn until_failure_node(child : Node) -> Node {
  let tick = fn(bb) {
    let status = child.tick(bb)
    match status {
      Status::BTFailure => {
        child.reset()
        Status::BTSuccess
      }
      _ => {
        child.reset()
        Status::BTRunning
      }
    }
  }
  let reset = fn() {
    child.reset()
  }
  Node::new(tick, reset)
}

// Timeout Decorator
// Ticks the child normally but fails it if it remains Running
// for more than `max_ticks` consecutive ticks.
pub fn timeout_node(child : Node, max_ticks : Int) -> Node {
  let elapsed : Ref[Int] = Ref::new(0)
  let tick = fn(bb) {
    if elapsed.get() >= max_ticks {
      elapsed.set(0)
      child.reset()
      return Status::BTFailure
    }
    let status = child.tick(bb)
    match status {
      Status::BTRunning => {
        elapsed.set(elapsed.get() + 1)
        Status::BTRunning
      }
      other => {
        elapsed.set(0)
        other
      }
    }
  }
  let reset = fn() {
    elapsed.set(0)
    child.reset()
  }
  Node::new(tick, reset)
}
