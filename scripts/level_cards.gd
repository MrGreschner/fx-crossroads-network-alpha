extends CanvasLayer
## Consistent colour and large choices; multiplayer choices never stop the simulation.
var game:Node
var arcade:=false
var panel:PanelContainer
var body:VBoxContainer
var active_level:=0
var signature:=""
var dismissed:=""
var choices:Array=[]
var toast:Label
var toast_time:=0.0
var last_level:=0
var last_match:=""
func setup(owner:Node,multi:bool)->void:
 game=owner;arcade=multi;layer=44
 panel=PanelContainer.new();panel.visible=false;panel.size=Vector2(920,380);add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#102c35");skin.border_color=Color("#d3b981");skin.set_border_width_all(2);skin.set_corner_radius_all(12);skin.set_content_margin_all(22);panel.add_theme_stylebox_override("panel",skin)
 toast=Label.new();toast.visible=false;toast.add_theme_font_size_override("font_size",22);toast.modulate=Color("#f8d991");toast.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(toast)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",14);panel.add_child(body)
func label(value:String,size:int=22)->void:
 var l:=Label.new();l.text=value;l.custom_minimum_size.x=876;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);body.add_child(l)
func options(lv:int)->Array:
 if arcade and game.mode=="descent" and lv>10:return [["+2.5% POWER","All attacks hit harder","#98534d",KEY_1],["+18 HP","Maximum health + heal 18","#397b62",KEY_2],["−2% COOLDOWN","All abilities • maximum −20%","#377891",KEY_3]]
 if lv in [2,4,7,9]:return [["+25 HP","Maximum health + heal 25","#397b62",KEY_1],["+4 DAMAGE","Hit harder","#98534d",KEY_2],["+20 SPEED","Move faster","#377891",KEY_3]]
 if lv==8:return [["+8 PRIMARY","More primary damage","#98534d",KEY_1],["−30% COOLDOWN","Use secondary more often","#377891",KEY_2]]
 if lv==10:return [["−30% COOLDOWN","Use special more often","#76579a",KEY_1],["STRONGER PASSIVE","Improve your passive","#397b62",KEY_2]]
 return [["CONTINUE","Try your new ability","#3d786b",KEY_ENTER]]
func show_level(lv:int)->void:
 active_level=lv;panel.visible=true;game.mobile.reset_controls()
 for child in body.get_children():body.remove_child(child);child.queue_free()
 label("LEVEL "+str(lv)+"  •  "+("CHOOSE AN UPGRADE" if lv in [2,4,7,8,9,10] or lv>10 else "NEW ABILITY"),28)
 if arcade:label("The match keeps running. Choose quickly. Use J / K for early choices; 1 / 2 / 3 after level 10.",16)
 elif lv in [3,5,6]:label(game.level_award_text(),20)
 else:label("Choose one. These colours stay the same each time.",18)
 choices=options(lv);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);body.add_child(row)
 for n in choices.size():
  var choice:Array=choices[n];var b:=Button.new();b.text=str(choice[0])+"\n"+str(choice[1])+"\n"+(str(n+1) if lv>10 else "J" if n==0 else "K") if arcade else str(choice[0])+"\n"+str(choice[1])+"\n"+(str(n+1) if choices.size()>1 else "Enter")
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size=Vector2(240,150);b.add_theme_font_size_override("font_size",22);b.pressed.connect(choose.bind(int(choice[3])));row.add_child(b)
  if arcade and lv>10 and n==2 and int(game.descent.state(game.my_id).cooldown)>=10:b.disabled=true;b.text="COOLDOWN CAP REACHED\nChoose power or health"
  for state in ["normal","hover","pressed"]:
   var skin:=StyleBoxFlat.new();skin.bg_color=Color(choice[2]).lightened(.12 if state=="hover" else -.08 if state=="pressed" else 0);skin.set_corner_radius_all(10);skin.set_content_margin_all(12);b.add_theme_stylebox_override(state,skin)
func choose(key:int)->void:
 if not arcade and game.menu!="levelup":return
 if arcade:
  var value:String="primary" if key==KEY_1 else "secondary"
  if active_level>10:value=["depth_power","depth_health","depth_cooldown"][clampi(key-KEY_1,0,2)]
  if active_level==10:value="special" if key==KEY_1 else "passive"
  if game.role=="host":game._apply_choice(game.my_id,value)
  else:game._send_channel(game.host_id,{"type":"choice","value":value})
  dismissed=signature
 else:
  var event:=InputEventKey.new();event.pressed=true;event.keycode=key;game._unhandled_input(event)
 panel.visible=false;game.mobile.reset_controls()
func _process(_delta:float)->void:
 if game==null:return
 var visible_now:bool=false
 if arcade:
  var lv:int=int(game.levels.get(game.my_id,1));var branch:String=str(game.attack_branch.get(game.my_id,""));var final:String=str(game.mastery_choice.get(game.my_id,""))
  if game.started and game.match_id!=last_match:last_match=game.match_id;last_level=lv
  if game.started and lv>last_level:
   toast_time=2.5;toast.text="LEVEL "+str(lv)+"  •  "+("Secondary unlocked" if lv==3 else "Passive unlocked" if lv==5 else "Special unlocked" if lv==6 else "+25 HP restored" if lv in [2,4,7,9] else "Choose your upgrade");last_level=lv
  toast_time=maxf(0,toast_time-_delta);toast.visible=toast_time>0 and game.started and game.session_menu.page.is_empty();toast.position=Vector2((get_viewport().get_visible_rect().size.x-toast.get_minimum_size().x)*.5,115)
  var pending:int=8 if lv>=8 and branch.is_empty() else 10 if lv>=10 and final.is_empty() else 0
  if pending==0 and game.mode=="descent" and int(game.descent.pending.get(game.my_id,0))>0:pending=maxi(11,lv)
  var token:String=game.match_id+":"+str(pending)+":"+branch+":"+final+":"+str(game.descent.state(game.my_id).spent)
  visible_now=game.started and game.start_countdown<=0 and pending>0 and game.shop_open.is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and not game.spectating()
  if visible_now and token!=signature:signature=token;show_level(pending)
  visible_now=visible_now and dismissed!=token
 else:
  visible_now=game.menu=="levelup" and game.session_menu.page.is_empty()
  if visible_now and active_level!=game.level:show_level(game.level)
 panel.visible=visible_now
 if not visible_now:
  if not arcade:active_level=0
  return
 panel.size=Vector2(920,380)
 var view:=get_viewport().get_visible_rect().size;var factor:=minf(1,minf((view.x-24)/920,(view.y-24)/380));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*panel.scale)*.5

func _unhandled_input(event:InputEvent)->void:
 if arcade and panel.visible and active_level>10 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1,KEY_2,KEY_3]:
  if event.keycode==KEY_3 and int(game.descent.state(game.my_id).cooldown)>=10:return
  choose(event.keycode);get_viewport().set_input_as_handled()
