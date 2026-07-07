pub enum Value {
  Bool(Bool)
  Int(Int)
  Double(Double)
  String(String)
}

pub struct Blackboard {
  data : Map[String, Value]
}

pub fn Blackboard::new() -> Blackboard {
  { data: Map([]) }
}

pub fn Blackboard::set_bool(self : Blackboard, key : String, val : Bool) -> Unit {
  self.data.set(key, Value::Bool(val))
}

pub fn Blackboard::get_bool(self : Blackboard, key : String) -> Option[Bool] {
  match self.data.get(key) {
    Some(Value::Bool(b)) => Some(b)
    _ => None
  }
}

pub fn Blackboard::set_int(self : Blackboard, key : String, val : Int) -> Unit {
  self.data.set(key, Value::Int(val))
}

pub fn Blackboard::get_int(self : Blackboard, key : String) -> Option[Int] {
  match self.data.get(key) {
    Some(Value::Int(i)) => Some(i)
    _ => None
  }
}

pub fn Blackboard::set_double(self : Blackboard, key : String, val : Double) -> Unit {
  self.data.set(key, Value::Double(val))
}

pub fn Blackboard::get_double(self : Blackboard, key : String) -> Option[Double] {
  match self.data.get(key) {
    Some(Value::Double(d)) => Some(d)
    _ => None
  }
}

pub fn Blackboard::set_string(self : Blackboard, key : String, val : String) -> Unit {
  self.data.set(key, Value::String(val))
}

pub fn Blackboard::get_string(self : Blackboard, key : String) -> Option[String] {
  match self.data.get(key) {
    Some(Value::String(s)) => Some(s)
    _ => None
  }
}
