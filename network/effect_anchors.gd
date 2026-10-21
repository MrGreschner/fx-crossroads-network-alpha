extends RefCounted
## Explicit attachment policy. Unlisted records retain their authored world point.
const ATTACHED={
 "root":["attached_ring"],
 "mantis":["parry","scissor_feint"],
 "v110":["jabs","saber","charge"],
 "v112":["oar","light","tap","kindle","march"],
 "halloween":["cleave","flight"],
 "v79":["magma_breath","windlass_swing","back_volcano"],
 "v78":["gopher_claw"],
 "v75":["hammer_arc"],
 "robot":["jab"],
 "v48":["tail_slap"],
 "ninja":["cut","cut_first","cut_second"]
}
static func attached(module:String,kind:String)->bool:
 return kind in ATTACHED.get(module,[]) or module=="ninja" and kind.begins_with("cut")
static func position(game:Node,module:String,record:Dictionary,fallback:Vector2)->Vector2:
 var kind=str(record.get("kind",record.get("style","")))
 if not attached(module,kind) or not game.has_method("melee_visual_position"):return fallback
 return game.melee_visual_position(str(record.get("owner","")),fallback)
