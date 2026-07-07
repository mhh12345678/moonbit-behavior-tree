fn main {
  println("=== MoonBit Behavior Tree Guard AI Simulation ===")
  let bb = @lib.Blackboard::new()
  bb.set_int("hp", 100)
  bb.set_bool("enemy_in_sight", false)
  bb.set_double("enemy_distance", 8.0)
  bb.set_int("patrol_index", 0)

  // Build the tree using the Builder API
  let guard_tree = @lib.Builder::new()
    .selector()
      // Sequence 1: Flee if low HP
      .sequence()
        .condition(fn(bb) { bb.get_int("hp").unwrap_or(100) < 30 })
        .action(fn(_) {
          println("AI ACTION: Low health! Fleeing...")
          @lib.BTSuccess
        })
        .end()
        .trace("Flee Branch")
      // Sequence 2: Combat if enemy in sight
      .sequence()
        .condition(fn(bb) { bb.get_bool("enemy_in_sight").unwrap_or(false) })
        .selector()
          // Attack if close
          .sequence()
            .condition(fn(bb) { bb.get_double("enemy_distance").unwrap_or(999.0) < 2.0 })
            .action(fn(_) {
              println("AI ACTION: Attacking enemy!")
              @lib.BTSuccess
            })
            .end()
          // Chase if far (running action)
          .action(fn(bb) {
            let dist = bb.get_double("enemy_distance").unwrap_or(10.0)
            let new_dist = dist - 3.0
            bb.set_double("enemy_distance", new_dist)
            println("AI ACTION: Chasing enemy... distance is now \{new_dist}")
            if new_dist < 2.0 {
              @lib.BTSuccess
            } else {
              @lib.BTRunning
            }
          })
          .end()
        .end()
        .trace("Combat Branch")
      // Default: Patrol
      .action(fn(bb) {
        let idx = bb.get_int("patrol_index").unwrap_or(0)
        let next_idx = (idx + 1) % 3
        bb.set_int("patrol_index", next_idx)
        println("AI ACTION: Patrol waypoint \{next_idx}")
        @lib.BTSuccess
      })
      .trace("Patrol Action")
      .end()
    .build()

  // Run the simulation ticks
  println("\n--- Tick 1: Patrol mode (no enemy in sight) ---")
  let _ = guard_tree.tick(bb)

  println("\n--- Tick 2: Patrol mode (no enemy in sight) ---")
  let _ = guard_tree.tick(bb)

  println("\n--- Tick 3: Enemy spotted at distance 8.0 ---")
  bb.set_bool("enemy_in_sight", true)
  let _ = guard_tree.tick(bb)

  println("\n--- Tick 4: Enemy still in sight (Running node resumes chase) ---")
  let _ = guard_tree.tick(bb)

  println("\n--- Tick 5: Chase completes (distance < 2.0), next tick will attack ---")
  let _ = guard_tree.tick(bb)

  println("\n--- Tick 6: Enemy is close, attacking! ---")
  let _ = guard_tree.tick(bb)

  println("\n--- Tick 7: Guard gets damaged (HP = 20), flees despite enemy in sight ---")
  bb.set_int("hp", 20)
  let _ = guard_tree.tick(bb)
}
