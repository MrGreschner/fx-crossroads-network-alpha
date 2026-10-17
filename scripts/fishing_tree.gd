extends Control
## Interactive, code-drawn mastery tree; scroll/zoom is handled by the workshop.
const P=preload("res://scripts/fishing_progress.gd")
const CANVAS=Vector2(1160,880)
const FONT=preload("res://scripts/studio_ui.gd").FONT
signal selected(id:String)
var progress:RefCounted
var points:Dictionary={}
func setup(p:RefCounted)->void:
 progress=p;custom_minimum_size=CANVAS;size=custom_minimum_size
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 for b in P.BRANCHES.size():
  var branch=P.BRANCHES[b];var x=145+b*290
  var positions=[Vector2(x,198),Vector2(x-70,374),Vector2(x+70,374),Vector2(x,550),Vector2(x,726)]
  for n in 5:
   var id=str(branch.nodes[n]);var at:Vector2=positions[n];points[id]=at
   var hit=Button.new();hit.name=id;hit.flat=true;hit.position=at-Vector2(66,36);hit.size=Vector2(132,140);hit.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
   hit.tooltip_text=str(P.TALENTS[id].name)+"\n"+str(P.TALENTS[id].text)+"\n"+("Learned" if progress.has(id) else progress.learn_reason(id) if not progress.learn_reason(id).is_empty() else "Available • 1 point")
   hit.add_theme_stylebox_override("normal",StyleBoxEmpty.new());hit.add_theme_stylebox_override("hover",StyleBoxEmpty.new());hit.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
   add_child(hit);hit.pressed.connect(func():selected.emit(id))
 queue_redraw()
func caption(at:Vector2,text:String,width:float,font_size:int,color:Color)->void:
 draw_string(FONT,at,text,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,color)
func card_rect(p:Vector2)->Rect2:return Rect2(p-Vector2(66,36),Vector2(132,140))
func _draw()->void:
 if progress==null:return
 draw_style_box(backdrop(),Rect2(Vector2.ZERO,CANVAS))
 var root=Vector2(CANVAS.x*.5,39)
 # All connections are drawn first and stop at the card edges.
 for branch in P.BRANCHES:
  var colour=Color(branch.color);var first:Vector2=points[branch.nodes[0]]
  draw_polyline(PackedVector2Array([root+Vector2(0,30),Vector2(root.x,106),Vector2(first.x,106),first-Vector2(0,36)]),colour.darkened(.35),2,true)
  for id in branch.nodes:
   var p:Vector2=points[id];var spec=P.TALENTS[id]
   for parent in spec.requires:
    if spec.slot==4 and P.TALENTS[parent].slot!=3:continue
    var from:Vector2=points[parent]+Vector2(0,104);var to=p-Vector2(0,36)
    draw_polyline(PackedVector2Array([from,Vector2(from.x,(from.y+to.y)*.5),Vector2(to.x,(from.y+to.y)*.5),to]),colour if progress.has(id) else colour.darkened(.55),3,true)
 draw_circle(root,26,Color("#274c56"));draw_arc(root,26,0,TAU,40,Color("#efce84"),2,true);icon(root,3,Color("#efce84"))
 draw_rect(Rect2(Vector2(root.x-125,72),Vector2(250,25)),Color("#0c2633"))
 caption(Vector2(root.x-125,91),"ANGLER'S ROOTS",250,18,Color("#e9d5a6"))
 for branch in P.BRANCHES:
  var colour=Color(branch.color);var first:Vector2=points[branch.nodes[0]]
  draw_style_box(preload("res://scripts/studio_ui.gd").box("#183641",branch.color,6,4),Rect2(Vector2(first.x-125,120),Vector2(250,30)))
  caption(Vector2(first.x-120,142),str(branch.name).to_upper(),240,18,colour)
  for id in branch.nodes:
   var p:Vector2=points[id];var spec=P.TALENTS[id];var learned=progress.has(id);var available=progress.learn_reason(id).is_empty()
   var skin=preload("res://scripts/studio_ui.gd").box("#1c403f" if learned else "#142e3a","#e7cb86" if learned else branch.color if available else "#3d5663",10,4)
   draw_style_box(skin,card_rect(p))
   draw_circle(p,27,Color("#3f655a") if learned else colour.darkened(.67) if available else Color("#1a3541"))
   draw_arc(p,28,0,TAU,36,Color("#ffdf8f") if learned else colour if available else Color("#506470"),3 if learned else 2,true)
   icon(p,(0 if branch.id=="rod" else 2 if branch.id=="net" else 5 if branch.id=="basket" else 3) if int(spec.slot)==0 else int(spec.slot),Color("#ffe2a0") if learned else colour if available else Color("#82979f"))
   if learned:draw_circle(p+Vector2(21,-22),7,Color("#ffdc83"))
   var words=str(spec.name).split(" ");var line1="";var line2=""
   for word in words:
    if FONT.get_string_size(line1+(" " if not line1.is_empty() else "")+word,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x<=124 and line2.is_empty():line1+=(" " if not line1.is_empty() else "")+word
    else:line2+=(" " if not line2.is_empty() else "")+word
   caption(p+Vector2(-63,49),line1,126,17,Color("#fff0cf") if learned else Color("#d6e3e2"))
   if not line2.is_empty():caption(p+Vector2(-63,69),line2,126,17,Color("#d6e3e2"))
   caption(p+Vector2(-62,94),"LEARNED" if learned else "Lv %d • 1 point" % int(spec.level),124,14,colour if learned or available else Color("#91a3af"))
 caption(Vector2(120,861),"Choose a fork to reach the next node. Learn both forks to claim a branch crown.",920,16,Color("#adbec2"))
func backdrop()->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color("#0c2633");s.border_color=Color("#43616b");s.set_border_width_all(1);s.set_corner_radius_all(15);return s
func icon(p:Vector2,kind:int,c:Color)->void:
 match kind:
  0:
   draw_line(p+Vector2(0,-15),p+Vector2(0,5),c,3,true);draw_arc(p+Vector2(-6,5),6,0,PI,15,c,3,true);draw_line(p+Vector2(-12,5),p+Vector2(-12,-1),c,3,true)
  1:
   draw_line(p+Vector2(-13,11),p+Vector2(10,-12),c,3,true);draw_line(p+Vector2(0,-11),p+Vector2(10,-12),c,3,true);draw_line(p+Vector2(10,-12),p+Vector2(9,-2),c,3,true)
  2:
   draw_arc(p,14,0,TAU,28,c,2,true)
   for n in [-7,0,7]:draw_line(p+Vector2(n,-11),p+Vector2(n,11),c,1,true);draw_line(p+Vector2(-11,n),p+Vector2(11,n),c,1,true)
  3:
   draw_arc(p,14,.25,PI-.25,20,c,2,true);draw_arc(p,14,PI+.25,TAU-.25,20,c,2,true);draw_circle(p,5,c)
  5:
   draw_rect(Rect2(p+Vector2(-13,-5),Vector2(26,17)),c,false,2)
   draw_arc(p+Vector2(0,-5),9,PI,TAU,18,c,2,true)
   for n in [-6,0,6]:draw_line(p+Vector2(n,-4),p+Vector2(n,11),c,1,true)
  4:
   var poly=PackedVector2Array()
   for n in 10:poly.append(p+Vector2.from_angle(-PI/2+n*PI/5)*(16 if n%2==0 else 7))
   draw_colored_polygon(poly,c)
