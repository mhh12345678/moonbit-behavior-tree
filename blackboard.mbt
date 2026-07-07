// ============================================================
// Blackboard: Shared Context for Behavior Tree Nodes
//
// The Blackboard provides a key-value store that all nodes in
// a behavior tree share. It decouples the decision logic (nodes)
// from the world state, allowing nodes to query and modify
// shared state without direct references to each other.
//
// Supported value types: Bool, Int, Double, String
// Advanced: snapshot/restore for sandboxed subtree execution.
// ============================================================

pub(all) enum Value {
  Bool(Bool)
  Int(Int)
  Double(Double)
  Str(String)
}

/// Blackboard is a shared key-value context for all BT nodes.
pub struct Blackboard {
  data : Map[String, Value]
  // A stack of snapshots for nested sandbox scopes
  snapshots : Array[Map[String, Value]]
}

/// Create a new empty Blackboard.
pub fn Blackboard::new() -> Blackboard {
  { data: Map([]), snapshots: [] }
}

/// Store a Bool under the given key.
pub fn Blackboard::set_bool(self : Blackboard, key : String, val : Bool) -> Unit {
  self.data.set(key, Value::Bool(val))
}

/// Retrieve a Bool stored under the given key. Returns None if missing or wrong type.
pub fn Blackboard::get_bool(self : Blackboard, key : String) -> Option[Bool] {
  match self.data.get(key) {
    Some(Value::Bool(b)) => Some(b)
    _ => None
  }
}

/// Store an Int under the given key.
pub fn Blackboard::set_int(self : Blackboard, key : String, val : Int) -> Unit {
  self.data.set(key, Value::Int(val))
}

/// Retrieve an Int stored under the given key. Returns None if missing or wrong type.
pub fn Blackboard::get_int(self : Blackboard, key : String) -> Option[Int] {
  match self.data.get(key) {
    Some(Value::Int(i)) => Some(i)
    _ => None
  }
}

/// Store a Double under the given key.
pub fn Blackboard::set_double(self : Blackboard, key : String, val : Double) -> Unit {
  self.data.set(key, Value::Double(val))
}

/// Retrieve a Double stored under the given key. Returns None if missing or wrong type.
pub fn Blackboard::get_double(self : Blackboard, key : String) -> Option[Double] {
  match self.data.get(key) {
    Some(Value::Double(d)) => Some(d)
    _ => None
  }
}

/// Store a String under the given key.
pub fn Blackboard::set_string(self : Blackboard, key : String, val : String) -> Unit {
  self.data.set(key, Value::Str(val))
}

/// Retrieve a String stored under the given key. Returns None if missing or wrong type.
pub fn Blackboard::get_string(self : Blackboard, key : String) -> Option[String] {
  match self.data.get(key) {
    Some(Value::Str(s)) => Some(s)
    _ => None
  }
}

/// Remove a key from the blackboard. No-op if the key does not exist.
pub fn Blackboard::remove(self : Blackboard, key : String) -> Unit {
  self.data.remove(key)
}

/// Check whether the given key exists on the blackboard.
pub fn Blackboard::has(self : Blackboard, key : String) -> Bool {
  self.data.contains(key)
}

/// Take a snapshot of the current data. Subsequent changes can be rolled back
/// via `restore()`. Snapshots are stacked, so multiple nested saves are safe.
pub fn Blackboard::snapshot(self : Blackboard) -> Unit {
  // Deep-copy the current map into the snapshot stack
  let copy : Map[String, Value] = Map([])
  self.data.each(fn(k, v) { copy.set(k, v) })
  self.snapshots.push(copy)
}

/// Roll back to the most recent snapshot taken with `snapshot()`.
/// If no snapshot exists, this is a no-op.
pub fn Blackboard::restore(self : Blackboard) -> Unit {
  match self.snapshots.pop() {
    None => ()
    Some(saved) => {
      // Clear current data and refill from saved snapshot
      self.data.each(fn(k, _) { self.data.remove(k) })
      saved.each(fn(k, v) { self.data.set(k, v) })
    }
  }
}

/// Discard the most recent snapshot without restoring it.
pub fn Blackboard::discard_snapshot(self : Blackboard) -> Unit {
  let _ = self.snapshots.pop()
}

/// Returns the number of keys currently stored on the blackboard.
pub fn Blackboard::size(self : Blackboard) -> Int {
  let count = Ref::new(0)
  self.data.each(fn(_k, _v) { count.set(count.get() + 1) })
  count.get()
}

/// Clear all keys from the blackboard. Snapshots are not affected.
pub fn Blackboard::clear(self : Blackboard) -> Unit {
  let keys : Array[String] = []
  self.data.each(fn(k, _) { keys.push(k) })
  for k in keys {
    self.data.remove(k)
  }
}
