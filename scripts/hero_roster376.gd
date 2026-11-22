extends RefCounted
## One visual language for the list, portrait grid and detail pane.
const LOCKED=0
const READY=1
const OWNED=2
const DORMANT=3
const U=preload("res://scripts/hero_unlocks371.gd")
static var muted_portraits:Dictionary={}
static func state(g:Node,id:String)->int:
 if not bool(g.characters.get(id,{}).get("event_active",true)):return DORMANT
 if U.owned(g.legacy,id):return OWNED
 var j=load("res://scripts/hero_journeys373.gd")
 if j.catalog().has(id):return READY if j.eligible(g.legacy,id) else LOCKED
 if U.ready(g.legacy,id) or id=="teacher":return READY
 return LOCKED
static func can_test(g:Node,id:String)->bool:
 return g.characters.has(id) and bool(g.characters[id].get("event_active",true)) and U.owned(g.legacy,id)
static func colour(value:int)->Color:
 return Color("#efd08b") if value==READY else Color("#8ed0bf") if value==OWNED else Color("#86969e")
static func description(g:Node,id:String)->String:
 match state(g,id):
  READY:return "MISSION READY • "+U.hint(g,id)
  OWNED:return "UNLOCKED • Ready to play and train"
  DORMANT:return "EVENT INACTIVE • Returns when this event is active"
 return "LOCKED • "+U.hint(g,id)
static func portrait(g:Node,id:String)->Texture2D:
 var base:Texture2D=preload("res://scripts/hero_portrait.gd").texture(g,id)
 if base==null or state(g,id) in [OWNED,READY]:return base
 var key=base.get_instance_id()
 if not muted_portraits.has(key):
  var image=base.get_image()
  if image==null:return base
  image=image.duplicate();image.convert(Image.FORMAT_RGBA8);image.adjust_bcs(.82,.86,.13)
  if muted_portraits.size()>256:muted_portraits.clear()
  muted_portraits[key]=ImageTexture.create_from_image(image)
 return muted_portraits[key]
static func style(control:Button,value:int,selected:bool=false)->void:
 var fill="#18363d" if value==OWNED else "#3c3727" if value==READY else "#19292e"
 var edge="#466970" if value==OWNED else "#d2b16d" if value==READY else "#34444a"
 var ink=Color("#e4ede8") if value==OWNED else Color("#f2d99c") if value==READY else Color("#96a5aa")
 for kind in ["normal","hover","pressed","disabled","focus"]:
  var box=StyleBoxFlat.new();box.bg_color=Color(fill).lightened(.06 if kind in ["hover","pressed"] else 0)
  box.border_color=Color("#8ed4d0") if selected else Color(edge);box.set_border_width_all(3 if selected else 2 if value==READY else 1);box.set_corner_radius_all(6)
  box.content_margin_left=10;box.content_margin_right=30;box.content_margin_top=6;box.content_margin_bottom=6
  if value==READY:box.border_width_left=5
  control.add_theme_stylebox_override(kind,box)
 for kind in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:control.add_theme_color_override(kind,ink)
 control.modulate=Color.WHITE
 var badge=control.get_node_or_null("OwnershipBadge")
 if badge==null:
  badge=Badge.new();badge.name="OwnershipBadge";badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;control.add_child(badge);badge.set_anchors_preset(Control.PRESET_TOP_RIGHT);badge.offset_left=-25;badge.offset_right=-5;badge.offset_top=8;badge.offset_bottom=28
 badge.value=value;badge.queue_redraw()
 control.set_meta("hero_access_state",value)
class Badge extends Control:
 var value:int=0
 func _draw()->void:
  var tint=Color("#efd08b") if value==1 else Color("#8ed0bf") if value==2 else Color("#86969e")
  if value==2:
   draw_circle(Vector2(10,10),9,Color(.2,.43,.39,.5));draw_polyline(PackedVector2Array([Vector2(4,10),Vector2(8,14),Vector2(16,5)]),tint,2,true)
  elif value==1:
   var points=PackedVector2Array([Vector2(10,0),Vector2(19,10),Vector2(10,20),Vector2(1,10)]);draw_colored_polygon(points,Color("#6e5a31"));points.append(points[0]);draw_polyline(points,tint,1.5,true)
   draw_line(Vector2(10,5),Vector2(10,11),tint,2);draw_circle(Vector2(10,15),1,tint)
  else:
   draw_arc(Vector2(10,8),5,PI,TAU,12,tint,2,true);draw_style_box(lock_box(),Rect2(3,8,14,11));draw_line(Vector2(10,11),Vector2(10,15),Color("#263b41"),2)
 func lock_box()->StyleBoxFlat:
  var box=StyleBoxFlat.new();box.bg_color=Color("#86969e");box.set_corner_radius_all(2);return box
static func legend(parent:Node)->void:
 var line=HBoxContainer.new();line.add_theme_constant_override("separation",18);parent.add_child(line)
 for item in [[OWNED,"Unlocked"],[READY,"Mission ready"],[LOCKED,"Locked"]]:
  var group=HBoxContainer.new();group.add_theme_constant_override("separation",5);line.add_child(group)
  var badge=Badge.new();badge.value=item[0];badge.custom_minimum_size=Vector2(20,20);badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;group.add_child(badge)
  var text=Label.new();text.text=item[1];text.add_theme_font_size_override("font_size",13);text.modulate=colour(item[0]);group.add_child(text)
