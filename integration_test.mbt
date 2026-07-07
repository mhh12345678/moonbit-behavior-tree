// Additional integration tests verifying cross-node edge cases

test "sequence node resets on re-entry after failure" {
  let bb = Blackboard::new()
  let count = Ref::new(0)

  // step1 always succeed, step2 fails on attempt 1, succeeds after
  let step2_attempts = Ref::new(0)
  let seq = sequence_node([
    action_node(fn(_) { count.set(count.get() + 1); Status::BTSuccess }),
    action_node(fn(_) {
      step2_attempts.set(step2_attempts.get() + 1)
      if step2_attempts.get() == 1 {
        Status::BTFailure
      } else {
        Status::BTSuccess
      }
    }),
  ])

  // First run: seq fails when step2 returns Failure
  let r1 = seq.tick(bb)
  assert_true(r1 == Status::BTFailure)
  // step1 ran once on tick1
  assert_eq(count.get(), 1)

  // Second run: seq restarts from step1 (because reset on fail)
  let r2 = seq.tick(bb)
  assert_true(r2 == Status::BTSuccess)
  // step1 ran again on tick2
  assert_eq(count.get(), 2)
}

test "parallel SuccessAll returns Failure on any child failure" {
  let bb = Blackboard::new()
  let node = parallel_node(
    [
      action_node(fn(_) { Status::BTSuccess }),
      action_node(fn(_) { Status::BTFailure }),
    ],
    ParallelPolicy::SuccessAll,
  )

  let r = node.tick(bb)
  assert_true(r == Status::BTFailure)
}

test "parallel SuccessOne returns Success on any child success" {
  let bb = Blackboard::new()
  let node = parallel_node(
    [
      action_node(fn(_) { Status::BTFailure }),
      action_node(fn(_) { Status::BTSuccess }),
    ],
    ParallelPolicy::SuccessOne,
  )

  let r = node.tick(bb)
  assert_true(r == Status::BTSuccess)
}

test "repeater resets counter on failure" {
  let bb = Blackboard::new()
  let count = Ref::new(0)
  let child = action_node(fn(_) {
    count.set(count.get() + 1)
    if count.get() == 2 {
      Status::BTFailure
    } else {
      Status::BTSuccess
    }
  })

  let rep = repeater_node(child, 5)
  // Tick 1: child succeeds (count=1)
  let r1 = rep.tick(bb)
  assert_true(r1 == Status::BTRunning)
  // Tick 2: child fails (count=2), repeater returns Failure and resets
  let r2 = rep.tick(bb)
  assert_true(r2 == Status::BTFailure)
}

test "condition node returns Failure when predicate is false" {
  let bb = Blackboard::new()
  bb.set_int("val", 10)
  let cond = condition_node(fn(bb) { bb.get_int("val").unwrap_or(0) > 50 })

  let r = cond.tick(bb)
  assert_true(r == Status::BTFailure)
}

test "builder with inverter wraps last action" {
  let bb = Blackboard::new()
  let tree = Builder::new()
    .inverter()
      .condition(fn(_bb) { false }) // Failure
      .end()
    .build()

  // inverter(Failure) => Success
  let r = tree.tick(bb)
  assert_true(r == Status::BTSuccess)
}

test "nested sequence within selector" {
  let bb = Blackboard::new()
  bb.set_bool("flag", false)

  let tree = Builder::new()
    .selector()
      .sequence()
        .condition(fn(bb) { bb.get_bool("flag").unwrap_or(false) })
        .action(fn(_) { Status::BTSuccess })
        .end()
      .action(fn(_) { Status::BTSuccess }) // fallback
      .end()
    .build()

  // flag is false => sequence fails => fallback action runs => Success
  let r = tree.tick(bb)
  assert_true(r == Status::BTSuccess)
}
