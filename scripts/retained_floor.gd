extends Node2D
var source:Node
var floor:Dictionary
var background:=false
var water_frame:=-1
var water_camera:=Vector2i(-999,-999)
func _ready()->void:z_index=-2 if background else -1
func _process(_delta:float)->void:
 var game:Node=source.adventure.game
 visible=source.active and (game.started and (not game.spectating() or source.data.id=="silverfall") if source.adventure.arcade else game.mode=="run") and game.session_menu.page not in ["main","clear","options"]
 position=-game.camera
 if visible and background and (source.data.id in ["silverfall","lantern_marsh"] or not source.data.lake.is_empty()):
  var tick=int(source.clock*20) if source.data.id=="silverfall" else int(Time.get_ticks_msec())
  var cell=Vector2i(floori(game.camera.x/128),floori(game.camera.y/128))
  if tick!=water_frame or cell!=water_camera:water_frame=tick;water_camera=cell;queue_redraw()
 if visible and not background:visible=source.visible(source.floor_bounds(floor),game.camera)
func _draw()->void:
 if background:source.draw_water(self,Vector2.ZERO)
 else:source.draw_floor(self,floor,true)
