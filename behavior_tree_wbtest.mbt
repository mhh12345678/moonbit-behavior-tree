// Whitebox tests run within the package scope.

test "blackboard get and set" {
  let bb = Blackboard::new()
  bb.set_bool("b", true)
  bb.set_int("i", 42)
  bb.set_double("d", 3.14)
  bb.set_string("s", "hello")

  assert_true(bb.get_bool("b").unwrap())
  assert_eq(bb.get_int("i").unwrap(), 42)
  assert_eq(bb.get_double("d").unwrap(), 3.14)
  assert_eq(bb.get_string("s").unwrap(), "hello")
}

test "sequence node ticks children in order and returns Success" {
  let bb = Blackboard::new()
  let count = Ref::new(0)

  let node = sequence_node([
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
  ])

  let res = node.tick(bb)
  assert_true(res == Status::BTSuccess)
  assert_eq(count.get(), 2)
}

test "sequence node fails early on Failure" {
  let bb = Blackboard::new()
  let count = Ref::new(0)

  let node = sequence_node([
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
    action_node(fn(_) { count.set(count.get() + 1); Status::BTFailure }),
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
  ])

  let res = node.tick(bb)
  assert_true(res == Status::BTFailure)
  assert_eq(count.get(), 2)
}

test "sequence node maintains running state across ticks" {
  let bb = Blackboard::new()
  let tick_count = Ref::new(0)

  let step1 = action_node(fn(_) { Status::BTSuccess })
  let step2 = action_node(fn(_) {
    tick_count.set(tick_count.get() + 1)
    if tick_count.get() == 1 {
      Status::BTRunning
    } else {
      Status::BTSuccess
    }
  })
  let step3 = action_node(fn(_) { Status::BTSuccess })

  let seq = sequence_node([step1, step2, step3])

  // First tick: step1 succeeds, step2 returns Running, seq returns Running
  let r1 = seq.tick(bb)
  assert_true(r1 == Status::BTRunning)
  assert_eq(tick_count.get(), 1)

  // Second tick: should resume from step2, step2 succeeds, step3 succeeds, seq returns Success
  let r2 = seq.tick(bb)
  assert_true(r2 == Status::BTSuccess)
  assert_eq(tick_count.get(), 2)
}

test "selector node returns Success when one child succeeds" {
  let bb = Blackboard::new()
  let count = Ref::new(0)

  let node = selector_node([
    action_node(fn(_) { count.set(count.get() + 1); Status::BTFailure }),
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
  ])

  let res = node.tick(bb)
  assert_true(res == Status::BTSuccess)
  assert_eq(count.get(), 2)
}

test "inverter decorator inverts child result" {
  let bb = Blackboard::new()
  let child_success = action_node(fn(_) { Status::BTSuccess })
  let child_failure = action_node(fn(_) { Status::BTFailure })

  let inv_success = inverter_node(child_success)
  let inv_failure = inverter_node(child_failure)

  assert_true(inv_success.tick(bb) == Status::BTFailure)
  assert_true(inv_failure.tick(bb) == Status::BTSuccess)
}

test "succeeder decorator always succeeds" {
  let bb = Blackboard::new()
  let child_failure = action_node(fn(_) { Status::BTFailure })
  let suc = succeeder_node(child_failure)

  assert_true(suc.tick(bb) == Status::BTSuccess)
}

test "repeater decorator repeats execution" {
  let bb = Blackboard::new()
  let count = Ref::new(0)
  let child = action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess })
  let rep = repeater_node(child, 3)

  let r1 = rep.tick(bb)
  assert_true(r1 == Status::BTRunning)
  assert_eq(count.get(), 1)

  let r2 = rep.tick(bb)
  assert_true(r2 == Status::BTRunning)
  assert_eq(count.get(), 2)

  let r3 = rep.tick(bb)
  assert_true(r3 == Status::BTSuccess)
  assert_eq(count.get(), 3)
}

test "builder fluid API constructs correct tree" {
  let bb = Blackboard::new()
  bb.set_bool("alert", true)

  let tree = Builder::new()
    .selector()
      .sequence()
        .condition(fn(bb) { bb.get_bool("alert").unwrap_or(false) })
        .action(fn(_) { Status::BTSuccess })
        .end()
      .action(fn(_) { Status::BTFailure })
      .end()
    .build()

  let res = tree.tick(bb)
  assert_true(res == Status::BTSuccess)
}
