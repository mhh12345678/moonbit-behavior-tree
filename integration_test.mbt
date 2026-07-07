// ============================================================
// Extended integration tests for new modules:
//   - Blackboard: snapshot/restore, has, remove, size
//   - EventBus: emit/consume, InterruptNode
//   - Scheduler: add, tick, pause, restart
//   - Decorators: retry, until_success, timeout
//   - RandomSelector: basic non-determinism
// ============================================================

test "blackboard snapshot and restore" {
  let bb = Blackboard::new()
  bb.set_int("hp", 100)
  bb.snapshot()
  bb.set_int("hp", 50)
  assert_eq(bb.get_int("hp").unwrap_or(0), 50)
  bb.restore()
  assert_eq(bb.get_int("hp").unwrap_or(0), 100)
}

test "blackboard has and remove" {
  let bb = Blackboard::new()
  bb.set_bool("flag", true)
  assert_true(bb.has("flag"))
  bb.remove("flag")
  assert_true(!(bb.has("flag")))
}

test "blackboard size and clear" {
  let bb = Blackboard::new()
  bb.set_int("a", 1)
  bb.set_int("b", 2)
  assert_eq(bb.size(), 2)
  bb.clear()
  assert_eq(bb.size(), 0)
}

test "retry_node retries on failure then succeeds" {
  let bb = Blackboard::new()
  let attempts = Ref::new(0)
  let child = action_node(fn(_) {
    attempts.set(attempts.get() + 1)
    if attempts.get() < 3 {
      Status::BTFailure
    } else {
      Status::BTSuccess
    }
  })
  let node = retry_node(child, 5)
  // Tick 1: fail (attempt 1), retry => Running
  let r1 = node.tick(bb)
  assert_true(r1 == Status::BTRunning)
  // Tick 2: fail (attempt 2), retry => Running
  let r2 = node.tick(bb)
  assert_true(r2 == Status::BTRunning)
  // Tick 3: success (attempt 3) => Success
  let r3 = node.tick(bb)
  assert_true(r3 == Status::BTSuccess)
}

test "retry_node exhausts all retries and returns Failure" {
  let bb = Blackboard::new()
  let node = retry_node(action_node(fn(_) { Status::BTFailure }), 2)
  // Tick 1: fail attempt 1 => Running (still retrying)
  let r1 = node.tick(bb)
  assert_true(r1 == Status::BTRunning)
  // Tick 2: fail attempt 2 => Failure (exhausted)
  let r2 = node.tick(bb)
  assert_true(r2 == Status::BTFailure)
}

test "until_success_node runs until child succeeds" {
  let bb = Blackboard::new()
  let count = Ref::new(0)
  let child = action_node(fn(_) {
    count.set(count.get() + 1)
    if count.get() < 3 {
      Status::BTFailure
    } else {
      Status::BTSuccess
    }
  })
  let node = until_success_node(child)
  // Ticks 1 and 2 return Running
  let r1 = node.tick(bb)
  let r2 = node.tick(bb)
  assert_true(r1 == Status::BTRunning)
  assert_true(r2 == Status::BTRunning)
  // Tick 3: child returns Success => node returns Success
  let r3 = node.tick(bb)
  assert_true(r3 == Status::BTSuccess)
}

test "timeout_node fails child after max_ticks" {
  let bb = Blackboard::new()
  let node = timeout_node(action_node(fn(_) { Status::BTRunning }), 3)
  // Ticks 1-3 should return Running
  let r1 = node.tick(bb)
  let r2 = node.tick(bb)
  let r3 = node.tick(bb)
  assert_true(r1 == Status::BTRunning)
  assert_true(r2 == Status::BTRunning)
  assert_true(r3 == Status::BTRunning)
  // Tick 4: timeout reached => Failure
  let r4 = node.tick(bb)
  assert_true(r4 == Status::BTFailure)
}

test "event_bus emit, consume and interrupt_node" {
  let bb = Blackboard::new()
  let bus = EventBus::new()
  let normal_count = Ref::new(0)
  let interrupt_count = Ref::new(0)

  let normal = action_node(fn(_) {
    normal_count.set(normal_count.get() + 1)
    Status::BTSuccess
  })
  let handler = action_node(fn(_) {
    interrupt_count.set(interrupt_count.get() + 1)
    Status::BTSuccess
  })
  let node = interrupt_node(bus, "alarm", normal, handler)

  // Tick 1: no event => normal runs
  let _ = node.tick(bb)
  assert_eq(normal_count.get(), 1)
  assert_eq(interrupt_count.get(), 0)

  // Emit event and tick 2: interrupt fires
  bus.emit("alarm")
  let _ = node.tick(bb)
  assert_eq(normal_count.get(), 1)
  assert_eq(interrupt_count.get(), 1)

  // Tick 3: event consumed => normal runs again
  let _ = node.tick(bb)
  assert_eq(normal_count.get(), 2)
}

test "condition_guard_node aborts child when predicate fails" {
  let bb = Blackboard::new()
  bb.set_bool("active", true)
  let child_count = Ref::new(0)
  let child = action_node(fn(_) {
    child_count.set(child_count.get() + 1)
    Status::BTRunning
  })
  let node = condition_guard_node(
    fn(b) { b.get_bool("active").unwrap_or(false) },
    child,
  )

  // Tick 1: predicate true => child runs
  let r1 = node.tick(bb)
  assert_true(r1 == Status::BTRunning)
  assert_eq(child_count.get(), 1)

  // Disable condition, tick 2: predicate false => Failure, child not ticked
  bb.set_bool("active", false)
  let r2 = node.tick(bb)
  assert_true(r2 == Status::BTFailure)
  assert_eq(child_count.get(), 1) // child was NOT called again
}

test "scheduler ticks multiple trees independently" {
  let sched = Scheduler::new()
  let bb1 = Blackboard::new()
  let bb2 = Blackboard::new()
  let count1 = Ref::new(0)
  let count2 = Ref::new(0)

  let tree1 = action_node(fn(_) { count1.set(count1.get() + 1); Status::BTSuccess })
  let tree2 = action_node(fn(_) { count2.set(count2.get() + 1); Status::BTSuccess })

  sched.add(SchedulerEntry::new("agent1", tree1, bb1))
  sched.add(SchedulerEntry::new("agent2", tree2, bb2))

  let results = sched.tick()
  assert_eq(results.length(), 2)
  assert_eq(count1.get(), 1)
  assert_eq(count2.get(), 1)
}

test "scheduler pause stops a tree from ticking" {
  let sched = Scheduler::new()
  let bb = Blackboard::new()
  let count = Ref::new(0)
  let tree = action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess })
  sched.add(SchedulerEntry::new("npc", tree, bb))

  sched.pause("npc")
  let _ = sched.tick()
  assert_eq(count.get(), 0) // paused, so not ticked

  sched.restart("npc")
  let _ = sched.tick()
  assert_eq(count.get(), 1) // resumed, ticked once
}

test "random_selector_node returns Success when any child succeeds" {
  let bb = Blackboard::new()
  let seed = Ref::new(42)
  let node = random_selector_node(
    [
      action_node(fn(_) { Status::BTFailure }),
      action_node(fn(_) { Status::BTSuccess }),
      action_node(fn(_) { Status::BTFailure }),
    ],
    seed,
  )
  // At least one child can succeed => eventually returns Success or Running
  // Since the order is shuffled, we call tick once and check it's Success or Running
  let r = node.tick(bb)
  assert_true(r == Status::BTSuccess || r == Status::BTRunning)
}
