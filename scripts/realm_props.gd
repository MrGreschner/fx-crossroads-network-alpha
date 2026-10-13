extends Node2D
## Static Moonveil festival decorations; independent of enemies and collision geometry.
var game:Node
var arcade:=false
var entries:Array=[]
func setup(owner:Node,multi:bool)->void:
 game=owner;arcade=multi;z_index=-1
 var decorations:Array=game.world_decorations if arcade else game.decorations
 for prop in decorations:entries.append([prop.texture,Rect2(prop.pos-prop.size*.5,prop.size)])
 # Solo uses the key 'pos' too; original arrays remain authoritative for collisions.
 queue_redraw()
func _process(_delta:float)->void:
 visible=(game.started and game.realm_id=="moonveil" and not game.spectating() if arcade else game.mode=="run" and game.region_id=="moonveil") and game.session_menu.page not in ["main","clear","options"]
 position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor()
func _draw()->void:
 for entry in entries:draw_texture_rect(entry[0],entry[1],false)
