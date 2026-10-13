extends Control
## A separate small, walkable classroom map. No combat or profile progression.
const UI=preload("res://scripts/studio_ui.gd")
var guide=Vector2(190,215)
var board=Vector2(710,215)
var assignments:Node
var hud:PanelContainer
var studio:Node
var player=Vector2(450,450)
var teacher=Vector2(450,215)
var stations=[Vector2(190,215),Vector2(710,215),Vector2(190,325),Vector2(710,325),Vector2(190,435),Vector2(710,435)]
var station_names=["STUDIO","ASSIGNMENTS","PROJECT IDEAS","PROGRESS","COMING SOON","COMING SOON"]
var progress_data:Dictionary={}
var progress_clock=2.0
var progress_values:Dictionary={}
var module_codes:Array=[]
var progress_panel:PanelContainer
var touch_move=Vector2.ZERO
var speech:PanelContainer
var clock=0.0
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
var ram:Texture2D=preload("res://assets/ram_idle.png")
func setup(owner:Node)->void:
 studio=owner;refresh_progress();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 hud=PanelContainer.new();hud.size=Vector2(860,105);add_child(hud);UI.apply(hud);hud.add_theme_stylebox_override("panel",UI.box("#102c38","#355b68",12,14));UI.enter(hud)
 var header=VBoxContainer.new();hud.add_child(header)
 var title=Label.new();title.text="CROSSROADS ACADEMY";title.add_theme_font_size_override("font_size",25);title.add_theme_color_override("font_color",Color("#edcf91"));header.add_child(title)
 var top=HBoxContainer.new();header.add_child(top)
 studio.button(top,"Talk to the teacher",talk);UI.accent(studio.button(top,"Assignments",open_assignments));studio.button(top,"Project ideas",open_project_briefs);studio.button(top,"Open Studio",func():studio.show_hub();queue_free());studio.button(top,"Return to town",func():studio.close();queue_free())
 var directions=HBoxContainer.new();directions.name="TouchDirections";directions.position=Vector2(24,560);UI.apply(directions);add_child(directions)
 for pair in [["←",Vector2.LEFT],["↑",Vector2.UP],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var b=Button.new();b.text=pair[0];b.custom_minimum_size=Vector2(50,44);directions.add_child(b);b.button_down.connect(func():touch_move=pair[1]);b.button_up.connect(func():touch_move=Vector2.ZERO)
func talk()->void:
 if is_instance_valid(speech):speech.queue_free()
 speech=PanelContainer.new();speech.size=Vector2(690,500);add_child(speech);studio.skin(speech)
 var col=VBoxContainer.new();speech.add_child(col);studio.label(col,"A CLASSROOM FOR CREATORS",24)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=280;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 var notes=VBoxContainer.new();notes.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(notes);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 studio.label(notes,"Welcome, creator. Your next idea could become part of this world.",19)
 for pair in [["IMAGINE & BUILD","Hero Workshop combines roles, artwork, abilities and mastery alternatives."],["CODE & ANIMATE","Ability Lab connects code, values and animation to a live replay. Behaviour Lab teaches decisions and flight. Enemy Lab lets you battle the opponent you build. Saved abilities appear in the Workshop’s Custom list."],["TEST & SHARE","Make a prediction, collect evidence, then explain your next change. Download a project to share one hero; your profile ZIP backs up your work."],["FIND YOUR NEXT PROJECT","The assignment board has briefs for playtesting, characters, behaviour, realms, video and audio. A bigger damage number is not automatically a better idea!"]]:
  var card=UI.card(notes,pair[0]);studio.label(card,pair[1],17)
 UI.enter(speech)
 studio.button(col,"Open Crossroads Studio",func():studio.show_hub();queue_free());studio.button(col,"Keep exploring classroom",func():speech.queue_free())
func open_assignments()->void:
 if preload("res://scripts/education_access.gd").student():studio.game.legacy.learning_open()
 elif preload("res://scripts/education_access.gd").teacher():load("res://scripts/education_guide.gd").open(studio.game.legacy)
 else:open_project_briefs()
func open_project_briefs()->void:
 if is_instance_valid(assignments):return
 var entries:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://content/studio/assignments.json"))
 assignments=UI.lesson(self,"CLASSROOM ASSIGNMENT BOARD","Pick a project. Build something useful. Show your evidence.",entries)
func _process(delta:float)->void:
 clock+=delta
 var buttons=get_node_or_null("TouchDirections")
 if buttons!=null:buttons.position=Vector2(16,get_viewport().get_visible_rect().size.y-58)
 if is_instance_valid(progress_panel):
  var v=get_viewport().get_visible_rect().size;var f=minf(1,minf((v.x-24)/720,(v.y-24)/480));progress_panel.scale=Vector2.ONE*f;progress_panel.position=(v-progress_panel.size*f)*.5
 var screen=get_viewport().get_visible_rect().size;hud.size=Vector2(860,105);var fit=minf(1,(screen.x-32)/hud.size.x);hud.scale=Vector2.ONE*fit;hud.position=Vector2((screen.x-hud.size.x*fit)*.5,12)
 if studio.game.menu=="workshop" and not is_instance_valid(speech) and not is_instance_valid(assignments) and not is_instance_valid(progress_panel):
  var direction=touch_move+Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
  var candidate=(player+direction.normalized()*170*delta).clamp(Vector2(75,130),Vector2(825,525));var blocked=false
  for spot in stations:
   if Rect2(spot-Vector2(67,34),Vector2(134,54)).grow(12).has_point(candidate):blocked=true
  if not blocked:player=candidate
  if player.y>510 and absf(player.x-450)<48:
   studio.close();queue_free();return
  if Input.is_action_just_pressed("interact"):
   if player.distance_to(teacher)<75:talk()
   else:
    for i in stations.size():
     if player.distance_to(stations[i]+Vector2(0,44))<70:activate(i);break
 progress_clock+=delta
 if progress_clock>2:
  progress_clock=0;refresh_progress()
 if is_instance_valid(speech):
  var view=get_viewport().get_visible_rect().size;var scale_factor=minf(1,minf((view.x-24)/690,(view.y-24)/500));speech.size=Vector2(690,500);scale_factor=minf(1,minf((view.x-24)/speech.size.x,(view.y-24)/speech.size.y));speech.scale=Vector2.ONE*scale_factor;speech.position=(view-speech.size*scale_factor)*.5
 queue_redraw()
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("#071b24"))
 var factor=minf(size.x/900,size.y/560);var offset=(size-Vector2(900,560)*factor)*.5;draw_set_transform(offset,0,Vector2.ONE*factor)
 draw_rect(Rect2(60,115,780,395),Color("#907354"));draw_rect(Rect2(60,115,780,395),Color("#e4c792"),5)
 for x in range(60,840,30):draw_line(Vector2(x,115),Vector2(x,510),Color(.1,.05,.01,.12),1)
 draw_rect(Rect2(310,125,280,60),Color("#204c43"));draw_rect(Rect2(310,125,280,60),Color("#c4af7c"),false,5)
 draw_string(font,Vector2(345,148),"IMAGINE • TEST • IMPROVE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f3e4c5"))
 for i in stations.size():station(i)
 draw_rect(Rect2(315,265,270,160),Color(.19,.36,.40,.4));draw_rect(Rect2(315,265,270,160),Color(.70,.66,.45,.5),false,3)
 draw_texture_rect(ram,Rect2(teacher-Vector2(26,45),Vector2(52,64)),false)
 draw_rect(Rect2(teacher+Vector2(-17,-4),Vector2(34,15)),Color("#344f6b"));draw_string(font,teacher+Vector2(-20,35),"Mr. G",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f5d79a"))
 draw_texture_rect(ram,Rect2(player-Vector2(24,44+sin(clock*6)*1.5),Vector2(48,64)),false)
 draw_rect(Rect2(410,492,80,18),Color("#244957"));draw_string(font,Vector2(405,537),"Entrance",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e6d09f"))
 if player.distance_to(teacher)<75:draw_string(font,Vector2(335,257),"E • Talk to teacher",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe8a8"))
 else:
  for i in stations.size():
   if player.distance_to(stations[i]+Vector2(0,44))<70:draw_string(font,Vector2(280,548),"E • "+station_names[i].capitalize(),HORIZONTAL_ALIGNMENT_CENTER,340,17,Color("#ffe8a8"));break

func activate(i:int)->void:
 match i:
  0:studio.show_hub();queue_free()
  1:open_assignments()
  2:open_project_briefs()
  3:open_progress()
  _:studio.game.message="This workstation is being prepared for a future Studio expansion.";studio.game.message_time=4;talk_soon()
func talk_soon()->void:
 if is_instance_valid(assignments):return
 assignments=UI.lesson(self,"COMING SOON","More ways to create are on the way.",[{"title":"Future workstation","body":"This station is reserved for a future Crossroads learning tool. Try the Studio, assignments or project ideas today."}])
func progress(code:String)->float:return float(progress_values.get(code,0))
func refresh_progress()->void:
 var S=preload("res://scripts/learning_store.gd");progress_data=S.load_data();progress_values.clear();var catalog=S.catalog();module_codes=catalog.keys()
 for code in catalog:
  var w=S.work(progress_data,code);var points=0.0;var total=0.0;var ready=S.readiness(progress_data,code,w)
  for o in catalog[code].outcomes:
   if o.get("observation",false):continue
   for id in o.stages:
    total+=1
    if w.entries.any(func(entry):return entry.stage==id and not entry.text.strip_edges().is_empty()):points+=1
   for kind in o.get("assets",[]):
    total+=1
    if not kind in ready[o.id].missing:points+=1
  progress_values[code]=points/maxf(1,total)
func open_progress()->void:
 if is_instance_valid(progress_panel):return
 refresh_progress()
 progress_panel=PanelContainer.new();progress_panel.size=Vector2(720,480);add_child(progress_panel);UI.apply(progress_panel)
 var col=VBoxContainer.new();progress_panel.add_child(col);studio.label(col,"YOUR MODULE PROGRESS",25)
 studio.label(col,"Practical work + short responses fill these gauges. A filled bar is ready for teacher review, not an awarded credit.",16)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=300;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 var S=preload("res://scripts/learning_store.gd")
 for code in S.catalog():
  if S.catalog()[code].get("archived",false):continue
  studio.label(list,code+" • "+S.catalog()[code].name,16)
  var bar=ProgressBar.new();bar.value=progress(code)*100;bar.custom_minimum_size.y=22;list.add_child(bar)
 studio.button(col,"Open Education Guide",func():progress_panel.queue_free();load("res://scripts/education_guide.gd").open(studio.game.legacy))
 studio.button(col,"Back to classroom",func():progress_panel.queue_free())
 var v=get_viewport().get_visible_rect().size;var fit=minf(1,minf((v.x-24)/720,(v.y-24)/480));progress_panel.scale=Vector2.ONE*fit;progress_panel.position=(v-progress_panel.size*fit)*.5
func station(i:int)->void:
 var p:Vector2=stations[i];var color=Color("#87cad0") if i<4 else Color("#b6ad92")
 draw_rect(Rect2(p-Vector2(68,33),Vector2(136,59)),Color("#3e4d50"));draw_rect(Rect2(p-Vector2(65,30),Vector2(130,50)),Color("#a98c66"));draw_line(p+Vector2(-65,22),p+Vector2(65,22),Color("#e7c99b"),3)
 for side in [-1,1]:draw_rect(Rect2(p+Vector2(side*55-4,25),Vector2(8,12)),Color("#4a4140"))
 draw_rect(Rect2(p-Vector2(50,65),Vector2(100,49)),Color("#263f4a"));draw_rect(Rect2(p-Vector2(46,61),Vector2(92,41)),Color("#416775"));draw_rect(Rect2(p-Vector2(50,65),Vector2(100,49)),color,false,2)
 if i==3:
  var codes=module_codes
  for n in 3:
   var x=p+Vector2(-36,-53+n*10);draw_rect(Rect2(x,Vector2(72,6)),Color("#243e4a"));draw_rect(Rect2(x,Vector2(72*progress(str(codes[n])),6)),Color("#86d4b0"))
 elif i<3:
  for n in 3:draw_line(p+Vector2(-32,-51+n*10),p+Vector2(25-n*7,-51+n*10),color,3)
 else:
  draw_arc(p+Vector2(0,-40),13,PI,TAU,16,color,3);draw_rect(Rect2(p+Vector2(-17,-42),Vector2(34,23)),color)
 draw_string(font,p+Vector2(-80,52),station_names[i],HORIZONTAL_ALIGNMENT_CENTER,160,14,Color("#fff0c2"))
 if player.distance_to(p+Vector2(0,44))<70:draw_rect(Rect2(p+Vector2(-53,27),Vector2(106,38)),Color(.5,.8,.83,.16));draw_rect(Rect2(p+Vector2(-53,27),Vector2(106,38)),color,false,1)
