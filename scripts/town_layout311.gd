extends RefCounted

const ATLAS_BOARD := Vector2(318,794)
const STARLACE := Vector2(521,810)
const RECORDS := Vector2(1035,538)
const WEST_FOUNTAIN := Vector2(-1030,985)
const DESCENT_SHIFT := Vector2(-52,0)
const DESCENT_ENTRY := Vector2(-1080,1200) + DESCENT_SHIFT
const DESCENT_COURT := Rect2(Vector2(-1175,1195) + DESCENT_SHIFT,Vector2(245,130))
const BATTLE_PAD := Rect2(650,-450,500,420)
const BATTLE_ENTRY := Vector2(900,-250)
const SUPPLY_DISPLAYS := [Vector2(1205,625),Vector2(1425,625)]
const MUSTER_WALLS := [
 Rect2(675,-437,450,45),
 Rect2(653,-394,23,325),
 Rect2(1124,-394,23,325),
 Rect2(676,-62,163,26),
 Rect2(961,-62,163,26)
]
