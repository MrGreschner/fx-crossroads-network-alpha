extends RefCounted
const DOOR=Vector2(2800,655)
const BUILDING=Rect2(2680,355,240,230)
var clock:=0.0
var panel:CanvasLayer
var phase:=0.0
var playing:=false
var hits:=0
var attempts:=0
var owner_game:Node
var status:Label
var meter:Control
const CHIME_LEVELS=[
 {"name":"First Note","count":1,"speed":.62,"window":.10},
 {"name":"Twin Bells","count":2,"speed":.65,"window":.08},
 {"name":"Quick Duet","count":2,"speed":.77,"window":.065},
 {"name":"Threefold Echo","count":3,"speed":.72,"window":.06},
 {"name":"Silver Cascade","count":3,"speed":.85,"window":.05},
 {"name":"Midnight Carillon","count":3,"speed":.96,"window":.04}]
var challenge:=0
var note:=0
var best:Dictionary={}
var ring_button:Button
var next_button:Button
var bell_audio:AudioStreamPlayer
var level_picker:OptionButton
func target_phase(index:int)->float:
 return .5 if int(CHIME_LEVELS[challenge].count)==1 else .32+index*.23
func restart()->void:
 phase=0;hits=0;attempts=0;note=0;playing=true
 if is_instance_valid(level_picker):level_picker.select(challenge)
 if is_instance_valid(next_button):next_button.disabled=true
 update_chime_status()
func update_chime_status()->void:
 if not is_instance_valid(status):return
 var total:int=int(CHIME_LEVELS[challenge].count)*5
 var need:int=int(ceil(total*.8))
 if playing:status.text="Pattern %d / 5   •   Chime %d / %d   •   Clear %d / %d" % [attempts+1,note+1,int(CHIME_LEVELS[challenge].count),hits,total]
 else:
  best[challenge]=maxi(int(best.get(challenge,0)),hits)
  status.text=("Challenge cleared!" if hits>=need else "Keep practicing!")+"   %d / %d clear notes (need %d)." % [hits,total,need]
  next_button.disabled=hits<need or challenge>=CHIME_LEVELS.size()-1
 ring_button.disabled=not playing or note>=int(CHIME_LEVELS[challenge].count)
func next_pattern()->void:
 attempts+=1;phase=0;note=0
 if attempts>=5:playing=false
 update_chime_status()
func step(delta:float)->void:
 clock+=delta
 if is_instance_valid(panel) and owner_game.menu!="chimehouse":
  playing=false
  if is_instance_valid(bell_audio):bell_audio.stop()
  panel.queue_free();panel=null;return
 if playing:
  phase+=delta*float(CHIME_LEVELS[challenge].speed)
  while note<int(CHIME_LEVELS[challenge].count) and phase>target_phase(note)+float(CHIME_LEVELS[challenge].window):note+=1;update_chime_status()
  if phase>=1:next_pattern()
 if is_instance_valid(meter):meter.queue_redraw()
func blocked(point:Vector2)->bool:return BUILDING.has_point(point)
func interact(game:Node)->bool:
 if game.position_in_world.distance_to(DOOR)>90:return false
 game.hint="E • Chimehouse: try the bell-timing challenge"
 if Input.is_action_just_pressed("interact"):open(game)
 return true
func strike()->void:
 if not playing or note>=int(CHIME_LEVELS[challenge].count):return
 if absf(phase-target_phase(note))<=float(CHIME_LEVELS[challenge].window):
  hits+=1
  if is_instance_valid(bell_audio):bell_audio.pitch_scale=pow(1.12246,note);bell_audio.play()
 note+=1;update_chime_status()
func open(game:Node)->void:
 if is_instance_valid(panel):return
 owner_game=game
 game.menu="chimehouse";playing=false;hits=0;attempts=0;phase=0
 panel=CanvasLayer.new();panel.layer=50;game.add_child(panel)
 bell_audio=AudioStreamPlayer.new();bell_audio.stream=load("res://assets/audio/chime.wav");bell_audio.max_polyphony=3;panel.add_child(bell_audio)
 var back:=ColorRect.new();back.color=Color(.02,.07,.09,.95);back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(back)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(center)
 var box:=VBoxContainer.new();box.custom_minimum_size=Vector2(560,350);box.add_theme_constant_override("separation",20);center.add_child(box)
 var title:=Label.new();title.text="THE CHIMEHOUSE";title.add_theme_font_size_override("font_size",30);box.add_child(title)
 var select:=OptionButton.new();level_picker=select;select.custom_minimum_size.y=46
 for n in CHIME_LEVELS.size():select.add_item("%d • %s" % [n+1,CHIME_LEVELS[n].name])
 select.select(challenge);select.item_selected.connect(func(index:int):challenge=index;restart());box.add_child(select)
 var help:=Label.new();help.text="Tap once for each gold chime as the light crosses it.\nFive patterns per level. Clear 80% to advance. No CC required.";help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(help)
 status=Label.new();status.add_theme_font_size_override("font_size",18);box.add_child(status)
 meter=Control.new();meter.custom_minimum_size=Vector2(560,65);box.add_child(meter)
 meter.draw.connect(func():
  var w:float=meter.size.x
  meter.draw_rect(Rect2(0,18,w,25),Color("#364f59"))
  for n in int(CHIME_LEVELS[challenge].count):
   var target:float=target_phase(n);var width:float=float(CHIME_LEVELS[challenge].window)
   meter.draw_rect(Rect2(w*(target-width),18,w*width*2,25),Color("#567d75") if n<note else Color("#c6a668"))
   meter.draw_string(ThemeDB.fallback_font,Vector2(target*w-5,60),str(n+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ecddbd"))
  meter.draw_circle(Vector2(phase*w,30),11,Color("#b8edf0")))
 ring_button=Button.new();ring_button.text="RING CHIME";ring_button.custom_minimum_size.y=55;ring_button.pressed.connect(strike);box.add_child(ring_button)
 var actions:=HBoxContainer.new();box.add_child(actions)
 var again:=Button.new();again.text="Retry level";again.custom_minimum_size=Vector2(240,44);again.pressed.connect(restart);actions.add_child(again)
 next_button=Button.new();next_button.text="Next challenge →";next_button.custom_minimum_size=Vector2(300,44);next_button.pressed.connect(func():challenge=mini(challenge+1,CHIME_LEVELS.size()-1);select.select(challenge);restart());actions.add_child(next_button)
 restart()
 var leave:=Button.new();leave.text="Return to town";leave.pressed.connect(func():playing=false;game.menu="";bell_audio.stop();panel.queue_free();panel=null);box.add_child(leave)
func draw_on(c:Node2D,camera:Vector2,font:Font)->void:
 if not Rect2(camera,c.get_viewport_rect().size).intersects(BUILDING.grow(110)):return
 # A distinct slate-roofed bell workshop on the clinic's northeast street.
 var p:Vector2=BUILDING.position-camera
 c.draw_rect(Rect2(p+Vector2(-10,215),Vector2(260,22)),Color(0,0,0,.2))
 c.draw_rect(Rect2(p,BUILDING.size),Color("#c6baa0"))
 for row in 9:
  for col in 6:c.draw_rect(Rect2(p+Vector2(col*40+(20 if row%2 else 0),row*25),Vector2(36,22)),Color("#b6ab91"))
 c.draw_colored_polygon(PackedVector2Array([p+Vector2(-20,0),p+Vector2(120,-85),p+Vector2(260,0)]),Color("#445e70"))
 c.draw_line(p+Vector2(120,-85),p+Vector2(260,0),Color("#829399"),4)
 c.draw_rect(Rect2(p+Vector2(102,144),Vector2(40,86)),Color("#594c43"))
 for x in [35,175]:
  c.draw_rect(Rect2(p+Vector2(x,80),Vector2(35,45)),Color("#466779"))
  c.draw_line(p+Vector2(x+17,80),p+Vector2(x+17,125),Color("#d9caa1"),3)
 var bell:Vector2=p+Vector2(120,60)
 c.draw_arc(bell,24,PI,TAU,20,Color("#d8b765"),7,true)
 c.draw_line(bell+Vector2(-25,0),bell+Vector2(25,0),Color("#e9cd86"),7)
 c.draw_circle(bell+Vector2(0,8+sin(clock*2)*2),5,Color("#c99e52"))
 c.draw_string(font,p+Vector2(40,270),"CHIMEHOUSE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f4dfb2"))
