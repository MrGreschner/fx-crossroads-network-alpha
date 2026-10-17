extends RefCounted
## Objective panels sit below the actual combat header, not the town header.
static func objective_top(canvas:Node,arcade:bool=false)->float:
 if arcade:return 162.0
 var top=188.0
 if canvas.get("waylight")!=null and not canvas.waylight.special() and (not canvas.waylight.combat.items().is_empty() or canvas.waylight.progress.state().fair):top+=30
 return top
