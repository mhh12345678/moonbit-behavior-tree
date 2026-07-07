pub enum FrameType {
  Seq
  Sel
  Par(ParallelPolicy)
  Inv
  Suc
  Rep(Int)
  Lim(Int)
}

pub struct Builder {
  stack : Array[(FrameType, Array[Node])]
  mut root : Option[Node]
}

pub fn Builder::new() -> Builder {
  { stack: [], root: None }
}

fn Builder::add_child(self : Builder, child : Node) -> Unit {
  if self.stack.length() > 0 {
    let (_, children) = self.stack[self.stack.length() - 1]
    children.push(child)
  } else {
    self.root = Some(child)
  }
}

pub fn Builder::action(self : Builder, act : (Blackboard) -> Status) -> Builder {
  self.add_child(action_node(act))
  self
}

pub fn Builder::condition(self : Builder, cond : (Blackboard) -> Bool) -> Builder {
  self.add_child(condition_node(cond))
  self
}

pub fn Builder::sequence(self : Builder) -> Builder {
  self.stack.push((FrameType::Seq, []))
  self
}

pub fn Builder::selector(self : Builder) -> Builder {
  self.stack.push((FrameType::Sel, []))
  self
}

pub fn Builder::parallel(self : Builder, policy : ParallelPolicy) -> Builder {
  self.stack.push((FrameType::Par(policy), []))
  self
}

pub fn Builder::inverter(self : Builder) -> Builder {
  self.stack.push((FrameType::Inv, []))
  self
}

pub fn Builder::succeeder(self : Builder) -> Builder {
  self.stack.push((FrameType::Suc, []))
  self
}

pub fn Builder::repeater(self : Builder, max_repeats : Int) -> Builder {
  self.stack.push((FrameType::Rep(max_repeats), []))
  self
}

pub fn Builder::limiter(self : Builder, min_ticks : Int) -> Builder {
  self.stack.push((FrameType::Lim(min_ticks), []))
  self
}

pub fn Builder::end(self : Builder) -> Builder {
  match self.stack.pop() {
    Some((frame_type, children)) => {
      let node = match frame_type {
        FrameType::Seq => sequence_node(children)
        FrameType::Sel => selector_node(children)
        FrameType::Par(policy) => parallel_node(children, policy)
        FrameType::Inv => {
          if children.length() == 0 {
            inverter_node(action_node(fn(_) { Status::BTFailure }))
          } else {
            inverter_node(children[0])
          }
        }
        FrameType::Suc => {
          if children.length() == 0 {
            succeeder_node(action_node(fn(_) { Status::BTFailure }))
          } else {
            succeeder_node(children[0])
          }
        }
        FrameType::Rep(repeats) => {
          if children.length() == 0 {
            repeater_node(action_node(fn(_) { Status::BTFailure }), repeats)
          } else {
            repeater_node(children[0], repeats)
          }
        }
        FrameType::Lim(min_ticks) => {
          if children.length() == 0 {
            limiter_node(action_node(fn(_) { Status::BTFailure }), min_ticks)
          } else {
            limiter_node(children[0], min_ticks)
          }
        }
      }
      self.add_child(node)
    }
    None => ()
  }
  self
}

pub fn Builder::build(self : Builder) -> Node {
  while self.stack.length() > 0 {
    let _ = self.end()
  }
  match self.root {
    Some(node) => node
    None => action_node(fn(_) { Status::BTFailure })
  }
}
