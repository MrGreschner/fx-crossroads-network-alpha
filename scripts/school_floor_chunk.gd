extends Node2D
var background=false
var source:Node
var tiles:Array=[]
var world_bounds:Rect2
func _ready()->void:z_index=-2 if background else -1
func _process(_dt:float)->void:
 var game=source.adventure.game
 visible=source.active and (game.started and not game.spectating() if source.adventure.arcade else game.mode=="run") and game.session_menu.page not in ["main","clear","options"] and world_bounds.intersects(Rect2(game.camera,game.VIEW).grow(80))
 position=-game.camera
func _draw()->void:
 if source.region_id=="elementary":preload("res://scripts/firstbell_art256.gd").ground(self);return
 if background:draw_rect(world_bounds,Color("#304451"));return
 # Keep textured floors together, then paint markings/edges. Interleaving a
 # border after every tile would break texture batches and increase draw calls.
 for tile in tiles:
  var point=Vector2(tile.cell)*64+Vector2(32,32);var top=point-Vector2(32,32);var room:Dictionary=tile.room;var theme=str(room.theme);var texture="school_"+(theme if theme in ["wood","street","yard","carpet","sand"] else "tile")
  var tint=Color("#797a91") if theme=="stage" else Color("#a6b6c3") if theme=="roof" else Color("#dabba3") if theme=="exam" else Color.WHITE
  draw_texture_rect(source.textures[texture],Rect2(top,Vector2(64,64)),false,tint)
 for tile in tiles:
  var point=Vector2(tile.cell)*64+Vector2(32,32);var room:Dictionary=tile.room
  if str(room.theme)=="street" and absf(point.y-source.rect(room.rect).get_center().y)<32 and tile.cell.x%4<2:draw_rect(Rect2(point-Vector2(24,6),Vector2(47,7)),Color("#d3c792"))
 for tile in tiles:
  var point=Vector2(tile.cell)*64+Vector2(32,32)
  for side in tile.edges:
   draw_line(point+side*32-side.orthogonal()*32,point+side*32+side.orthogonal()*32,Color("#5d707e"),16)
   draw_line(point+side*27-side.orthogonal()*32,point+side*27+side.orthogonal()*32,Color("#aeb9ba"),3)
