extends CanvasLayer
## Read-only match leaderboard; visible while dead/downed, never persistent trophy data.
var game:Node
var panel:PanelContainer
var body:VBoxContainer
var sort_by:="damage"
var refresh_in:=0.0
var heading:Label
var leaders:Label
var grid:GridContainer
var cause_box:VBoxContainer
var cause_token=""
var manual:=false
var toggle:Button
func setup(owner:Node)->void:
 game=owner;layer=43;panel=PanelContainer.new();panel.visible=false;panel.size=Vector2(660,420);add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color(.045,.11,.15,.94);skin.border_color=Color("#bda978");skin.set_border_width_all(2);skin.set_corner_radius_all(10);skin.set_content_margin_all(16);panel.add_theme_stylebox_override("panel",skin)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",7);panel.add_child(body)
 heading=label(body,"",20);heading.modulate=Color("#f0d194")
 leaders=label(body,"",14)
 cause_box=VBoxContainer.new();body.add_child(cause_box)
 var controls:=HBoxContainer.new();body.add_child(controls)
 for key in ["damage","kills"]:
  var b:=Button.new();b.text="Sort: "+key.capitalize();b.custom_minimum_size=Vector2(145,32);b.pressed.connect(func():sort_by=key;refresh_in=0);controls.add_child(b)
 grid=GridContainer.new();grid.columns=5;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",5);body.add_child(grid)
 label(body,"All kills include creatures; hero KOs count opposing heroes only.",13)
 var close:=Button.new();close.text="Close leaderboard";close.custom_minimum_size.y=36;close.pressed.connect(func():manual=false;panel.hide());body.add_child(close)
 toggle=Button.new();toggle.text="Leaderboard";toggle.size=Vector2(150,44);toggle.pressed.connect(func():manual=not manual;refresh_in=0);add_child(toggle)
 preload("res://scripts/top_button_style.gd").apply(toggle)
func rows()->Array:
 var list:Array=[]
 for member in game.fighters():
  var id:=str(member.id);var rec:Dictionary=game.arena_records.get(id,{});list.append({"id":id,"name":str(member.get("name","Player")),"damage":int(game.contributions.get(id,{}).get("damage",0)),"kills":int(game.kills.get(id,0)),"hero_kills":int(rec.get("kills",0)),"deaths":int(rec.get("deaths",0))})
 list.sort_custom(func(a,b):return int(a[sort_by])>int(b[sort_by]) if int(a[sort_by])!=int(b[sort_by]) else int(a.hero_kills)>int(b.hero_kills) if int(a.hero_kills)!=int(b.hero_kills) else str(a.name)<str(b.name))
 return list
func label(parent:Node,value:String,size:int=16)->Label:
 var l:=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func refresh()->void:
 var credit:Dictionary=game.defeat_causes.get(game.my_id,{}) if int(game.health.get(game.my_id,1))<=0 else {}
 var token:=JSON.stringify(credit)
 if token!=cause_token:
  cause_token=token
  for child in cause_box.get_children():cause_box.remove_child(child);child.queue_free()
  preload("res://scripts/defeat_credit.gd").card(cause_box,game,credit)
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 var until:int=int(game.respawn_at.get(game.my_id,9223372036854775807));var waiting:="Awaiting revive" if until>Time.get_ticks_msec()+60000 else "Respawn in %.1fs" % maxf(0,(until-Time.get_ticks_msec())/1000.0)
 if game.adventure.combat.v90.pending_rebirth(game.my_id):waiting="Ash Rebirth in %.1fs" % maxf(0,float(game.adventure.combat.v90.rebirth[game.my_id].left))
 heading.text=waiting+"  •  LIVE MATCH LEADERS" if int(game.health.get(game.my_id,1))<=0 and not game.spectating() else "LIVE MATCH LEADERS"
 var data:=rows();var damage_leader:="—";var kills_leader:="—";var max_damage:=-1;var max_kills:=-1
 for row in data:
  if int(row.damage)>max_damage:max_damage=row.damage;damage_leader=str(row.name).left(16)
  if int(row.kills)>max_kills:max_kills=row.kills;kills_leader=str(row.name).left(16)
 leaders.text="Damage: "+damage_leader+"  •  Kills: "+kills_leader
 for cell in [["PLAYER",230],["DAMAGE",90],["ALL KILLS",78],["HERO KOs",82],["DEATHS",64]]:label(grid,cell[0],13).custom_minimum_size.x=cell[1]
 for index in data.size():
  var row:Dictionary=data[index];var tint:=Color("#f6d597") if str(row.id)==game.my_id else Color("#d9e9eb")
  label(grid,str(index+1)+". "+str(row.name).left(21),15).modulate=tint
  for key in ["damage","kills","hero_kills","deaths"]:label(grid,str(row[key]),15).modulate=tint
func _process(delta:float)->void:
 if game==null:return
 var available:bool=game.started and game.mode=="arena" and game.results_reason.is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and game.shop_open.is_empty()
 toggle.visible=available;toggle.position=Vector2(get_viewport().get_visible_rect().size.x-170,get_viewport().get_visible_rect().size.y-140) if game.spectating() else Vector2(20,get_viewport().get_visible_rect().size.y-54)
 if not game.started:manual=false
 var show:bool=game.started and (manual and available or not game.spectating() and int(game.health.get(game.my_id,1))<=0) and game.results_reason.is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty()
 panel.visible=show
 if not show:refresh_in=0;return
 refresh_in-=delta
 if refresh_in<=0:refresh();refresh_in=.25
 panel.size=Vector2(660,maxf(420,body.get_combined_minimum_size().y+32))
 var view:=get_viewport().get_visible_rect().size;var factor:=minf(1,minf((view.x-24)/660,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*panel.scale)*.5
