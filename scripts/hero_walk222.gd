extends RefCounted
## Two cached neutral walk poses, rigged from the existing idle atlas.
## Only lower legs change. Equipment, tails, head and torso never flip or bob.
const RIGS={
 "hazel_hex":[Rect2i(27,64,12,10),Rect2i(42,64,12,10)],
 "hearth_herald":[Rect2i(27,63,12,11),Rect2i(44,63,12,11)],
 "medic":[Rect2i(28,63,12,11),Rect2i(43,63,12,11)],
 "ferryman":[Rect2i(28,65,12,9),Rect2i(43,65,12,9)],
 "vesper":[Rect2i(31,64,10,10),Rect2i(42,64,10,10)],
 "beaver":[Rect2i(25,64,14,10),Rect2i(42,64,14,10)],
 "elara":[Rect2i(28,63,11,11),Rect2i(42,63,11,11)],
 "aurel":[Rect2i(27,65,12,9),Rect2i(43,65,12,9)],
 "rook":[Rect2i(25,62,14,12),Rect2i(43,62,14,12)],
 "iris":[Rect2i(28,62,11,12),Rect2i(44,62,11,12)],
 "cairnheart":[Rect2i(26,65,13,9),Rect2i(43,65,13,9)],
 "caelum":[Rect2i(28,62,12,12),Rect2i(43,62,12,12)],
 "velvetwing":[Rect2i(35,67,5,7),Rect2i(41,67,5,7)],
 "kage":[Rect2i(27,65,12,9),Rect2i(43,65,12,9)],
 "hearthwarden":[Rect2i(25,63,14,11),Rect2i(43,63,14,11)],
 "cantor":[Rect2i(29,65,10,9),Rect2i(43,65,12,9)],
 "votary":[Rect2i(26,64,13,10),Rect2i(43,64,13,10)],
 "lumen":[Rect2i(29,63,11,11),Rect2i(42,63,11,11)],
 "mosaic":[Rect2i(27,64,13,10),Rect2i(44,64,13,10)],
 "little_menace":[Rect2i(29,66,11,8),Rect2i(43,66,11,8)],
 "quill":[Rect2i(27,65,12,9),Rect2i(43,65,12,9)]
}
static func make_frame(hero:String,idle:Texture2D,index:int)->Texture2D:
 var source:Image=idle.get_image();var result:Image=source.duplicate()
 var legs:Array=RIGS[hero]
 for leg in legs:result.fill_rect(leg,Color.TRANSPARENT)
 for side in 2:
  var rect:Rect2i=legs[side];var patch:Image=source.get_region(rect)
  var delta:int=0 if side==(0 if index==1 else 1) else -3
  patch.resize(rect.size.x,rect.size.y+delta,Image.INTERPOLATE_NEAREST)
  result.blit_rect(patch,Rect2i(Vector2i.ZERO,patch.get_size()),rect.position)
 return ImageTexture.create_from_image(result)
