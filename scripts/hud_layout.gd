extends RefCounted
static func objective_top(canvas:Node,arcade:bool=false)->float:
 var top=100.0
 if not arcade and canvas.get("waylight")!=null and not canvas.waylight.special() and (not canvas.waylight.combat.items().is_empty() or canvas.waylight.progress.state().fair):top+=26
 return top
