extends Control
## Drawn lobby scenery and animated, host-authoritative party placements.
var game:Node
var clock:=0.0
var moving:Dictionary={}
var dragging:=false
var kick_buttons:Dictionary={}
var skins:Dictionary={}
func sync_kicks()->void:
 var ids:Dictionary={}
 for member in members():ids[str(member.get("id",""))]=true
 for id in kick_buttons.keys():
  if not ids.has(id):kick_buttons[id].queue_free();kick_buttons.erase(id);moving.erase(id)
 for index in members().size():
  var id:=str(members()[index].get("id",""))
  if id in [game.my_id,"preview"] or id.begins_with("bot:"):continue
  if not kick_buttons.has(id):
   var b:=Button.new();b.text="Kick";b.size=Vector2(44,24);b.add_theme_font_size_override("font_size",12);b.tooltip_text="Remove this player and free their seat";b.pressed.connect(game._kick_member.bind(id));add_child(b);kick_buttons[id]=b
  var b:Button=kick_buttons[id]
  b.position=position_for(id,index)+Vector2(25,-35)
  b.visible=game.role=="host" and not game.started and game.results_reason.is_empty()

const SILVER=Rect2(358,286,282,214)
const CENTRE=Rect2(651,286,282,214)
const BLUE=Rect2(944,286,300,214)
func _ready()->void:
 size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_CLICK;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func team_mode()->bool:return game.mode=="battlegrounds" or game.mode=="arena" and game.rule_picker.selected==1
func _process(delta:float)->void:
 sync_kicks()
 if game.started:return
 clock+=delta;queue_redraw()
 if team_mode() and not game.spectating() and game.results_reason.is_empty() and not get_viewport().gui_get_focus_owner() is LineEdit:
  if Input.is_action_just_pressed("move_left"):game._choose_team(0)
  elif Input.is_action_just_pressed("move_right"):game._choose_team(1)
func zone_at(point:Vector2)->int:
 if SILVER.has_point(point):return 0
 if BLUE.has_point(point):return 1
 return -1
func pick(point:Vector2)->void:
 if not team_mode() or not game.results_reason.is_empty():return
 if SILVER.has_point(point) or BLUE.has_point(point) or CENTRE.has_point(point):game._choose_team(zone_at(point))
func _gui_input(event:InputEvent)->void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:dragging=true
  else:dragging=false;pick(event.position)
 elif event is InputEventScreenTouch:
  if event.pressed:dragging=true
  else:dragging=false;pick(event.position)
 elif event is InputEventMouseMotion:
  if dragging:pick(event.position)
  else:
   tooltip_text="Tap a team area to choose a side." if team_mode() else ""
   for n in members().size():
    var member:Dictionary=members()[n];var id:=str(member.get("id",""))
    if Rect2(position_for(id,n)-Vector2(35,85),Vector2(70,150)).has_point(event.position):tooltip_text=str(member.get("name","Player"))+" • "+str(game.characters.get(str(game.hero_ids.get(id,game.selected_hero)),{}).get("name","Connecting…"))
 elif event is InputEventScreenDrag and dragging:pick(event.position)
func box(rect:Rect2,fill:Color,border:Color,width:int=1)->void:
 var key:=str(fill)+str(border)+str(width)
 if not skins.has(key):
  var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(12);skins[key]=style
 draw_style_box(skins[key],rect)
func words(point:Vector2,value:String,font_size:int=18,tint:Color=Color("#dce7df"),width:float=-1)->void:draw_string(ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,tint)
func centre(point:Vector2,value:String,font_size:int,tint:Color,width:float)->void:draw_string(ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,tint)
func members()->Array:
 if not game.roster.is_empty():return game.fighters()
 var preview:Array=[]
 if not (game.spectator_supported() and game.spectator_host):preview.append({"id":"preview","name":game.name_field.text if not game.name_field.text.is_empty() else "You"})
 if game.mode=="arena" and game.bots!=null:
  for n in game.bot_count:preview.append({"id":"bot:"+str(n),"name":game.bots.NAMES[n]+" [AI]"})
 return preview
func side_of(id:String)->int:
 if id=="preview":return game.chosen_team
 return int(game.teams.get(id,-1))
func position_for(id:String,index:int)->Vector2:
 if not team_mode():return Vector2(470+(index%4)*218,363+int(index/4)*87)
 var side:int=side_of(id);var slot:=0
 for member in members():
  var other:=str(member.get("id",""))
  if other==id:break
  if side_of(other)==side:slot+=1
 var base:=430 if side==0 else 1018 if side==1 else 719
 return Vector2(686+(slot%4)*66,363+int(slot/4)*87) if side==-1 else Vector2(base+(slot%2)*125,363+int(slot/2)*87)
func _draw()->void:
 if game==null:return
 draw_rect(Rect2(0,0,1280,720),Color("#101e2b"))
 for x in range(0,1280,80):
  for y in range(220,720,48):draw_rect(Rect2(x+ (40 if y%96==0 else 0),y,77,45),Color("#162a34"))
 box(Rect2(18,18,1244,66),Color("#1c3540"),Color("#658077"),2)
 words(Vector2(38,58),"GATHER YOUR PARTY",28,Color("#f3dca0"))
 words(Vector2(740,43),"PLAYER NAME",12,Color("#a5bfc4"))
 box(Rect2(18,98,320,466),Color("#192e39"),Color("#4c6b70"))
 words(Vector2(36,124),"CHOOSE YOUR ADVENTURE",16,Color("#a5c6c6"))
 box(Rect2(354,98,890,162),Color("#192e39"),Color("#4c6b70"))
 words(Vector2(375,124),"MATCH SETTINGS",14,Color("#b9d2cb"))
 if game.mode=="battlegrounds":words(Vector2(377,158),"Personal barracks • Build armies • Break the enemy heart",19,Color("#efddb4"))
 elif game.mode=="coop":words(Vector2(377,155),"Choose your hero and the realm you’ll explore together.",18,Color("#efddb4"))
 elif game.mode=="defense":words(Vector2(377,158),"Three outposts. Marching guards. A rival hero. Wave-30 boss.",19,Color("#efddb4"))
 elif game.mode=="descent":words(Vector2(377,158),"100 floors • One shared lantern • Fixed guardians every five floors",19,Color("#efddb4"))
 words(Vector2(365,279),"IN PARTY",17,Color("#f2d49c"))
 words(Vector2(910,279),str(game.fighters().size())+" / "+str(game.player_limit())+" players"+(" + spectator host" if game.spectator_host and game.spectator_supported() else "") if not game.roster.is_empty() else "Practice • damage mastery only" if game.bot_count>0 else "Your hero is ready",15,Color("#a6c4c7"))
 if team_mode():
  box(SILVER,Color("#283b46"),Color("#c5d6df"),2);box(CENTRE,Color("#182c36"),Color("#455d66"));box(BLUE,Color("#193c5d"),Color("#69b4f0"),2)
  centre(Vector2(365,310),("RAM ALLIANCE" if game.mode=="battlegrounds" else "SILVER TEAM"),20,Color("#e0e8eb"),265);centre(Vector2(658,310),(("READY TO BATTLE" if game.mode=="battlegrounds" else "READY TO DUEL") if game._teams_ready() else "CHOOSE A SIDE"),17,Color("#b3c3be"),266);centre(Vector2(952,310),("IRONHOLLOW" if game.mode=="battlegrounds" else "BLUE TEAM"),20,Color("#a6d7ff"),282)
  centre(Vector2(365,496),str(side_count(0))+" / "+str(game.bg_team_size if game.mode=="battlegrounds" else mini(4,game.arena_seats/2))+" • Tap to join",15,Color("#b5cbd0"),265);centre(Vector2(658,496),"Drag your hero / Left or Right",14,Color("#9bb3b5"),266);centre(Vector2(952,496),str(side_count(1))+" / "+str(game.bg_team_size if game.mode=="battlegrounds" else mini(4,game.arena_seats/2))+" • Tap to join",15,Color("#9cc7e7"),282)
 else:
  box(Rect2(354,286,890,214),Color("#1d333e"),Color("#678278"),2)
  centre(Vector2(370,309),"BROADCAST HOST • Players take the stage below" if game.spectating() else "PRACTICE • Damage mastery only; no PvP records or trophies" if game.bot_count>0 else "Choose your hero. Get ready together.",18,Color("#b9d4c8"),852)
 for index in members().size():
  var member:Dictionary=members()[index];var id:=str(member.get("id",""));var destination:=position_for(id,index)
  var p:Vector2=moving.get(id,destination);p=p.lerp(destination,.18);moving[id]=p
  var local:bool=id==game.my_id or id=="preview";var hero:String=game.selected_hero if local else str(game.hero_ids.get(id,""));var pending:bool=not local and (hero.is_empty() or game.role=="host" and not game.lobby_heroes.has(id))
  if game.bots!=null and game.bots.is_bot(id):hero=game.bots.IDS[int(id.trim_prefix("bot:"))];pending=false
  var side:int=side_of(id);var colour:=Color("#69b4f0") if team_mode() and side==1 else Color("#c5d6df") if team_mode() and side==0 else Color("#c9b583")
  draw_circle(p+Vector2(0,-6),20,Color(0,0,0,.35));draw_arc(p+Vector2(0,-6),21,0,TAU,32,colour,2)
  var texture:Texture2D=game.art.get(hero+"_"+("walk1" if int(clock*5+index)%2==0 else "walk2"),game.art.get(hero+"_idle"))
  if pending:draw_circle(p-Vector2(0,30),17,Color("#637c85"));draw_rect(Rect2(p-Vector2(17,10),Vector2(34,24)),Color("#637c85"))
  elif texture!=null:draw_texture_rect(texture,preload("res://scripts/hero_visual_scale.gd").apply(hero,Rect2(p-Vector2(24,47),Vector2(48,56))),false)
  if not pending and not id.begins_with("bot:"):preload("res://scripts/rolling_crowns.gd").draw_on(self,p,clock,preload("res://scripts/rolling_crowns.gd").remote_tier(game.local_cosmetic() if local else game.cosmetic_for(id)))
  if not pending:
   var appearance=game.local_cosmetic() if local else game.cosmetic_for(id)
   preload("res://scripts/player_cosmetics.gd").draw_on(self,p,clock,str(appearance.get("extra_effect","")),str(appearance.get("weekly_week","")))
   preload("res://scripts/ranked_cosmetic_art.gd").draw_lobby(self,p,clock,appearance)
  var dev:bool=bool((game.local_cosmetic() if local else game.cosmetic_for(id)).get("game_dev",false))
  if not pending:preload("res://scripts/creation_badges.gd").draw_on(self,p-Vector2(0,10),clock,game.local_cosmetic() if local else game.cosmetic_for(id))
  if dev and not pending:preload("res://scripts/dev_insignia.gd").draw_on(self,p-Vector2(0,10),clock,.65)
  var width:=114.0 if team_mode() and side!=-1 else 66.0 if team_mode() else 200.0
  var label:=("DEV • " if dev else "")+str(member.get("name","Player"))+(" • YOU" if local and not team_mode() else "")
  if id==game.host_id:label+=" • Host"
  centre(p+Vector2(-width*.5,25),label,13,Color("#f5e5c4") if local else Color("#dce6e3"),width)
  if not team_mode():centre(p+Vector2(-100,42),"Connecting…" if pending else str(game.characters.get(hero,{}).get("name","")),13,Color("#a4c3c9"),200)
 if not team_mode():
  for n in range(members().size(),game.player_limit()):
   var p:=position_for("",n);draw_arc(p+Vector2(0,-6),21,0,TAU,32,Color("#4e6872"),2);centre(p+Vector2(-88,25),"Waiting for a friend",14,Color("#77979f"),176)
 if not game.results_reason.is_empty():results()
 box(Rect2(354,515,890,189),Color("#192e39"),Color("#4c6b70"))
 words(Vector2(375,541),"ROOM & INVITATIONS",14,Color("#b9d2cb"))
 if game.spectator_supported() and game.spectator_host:
  box(Rect2(32,521,292, 37),Color("#243b47"),Color("#d9c384"),2)
  words(Vector2(48,537),"BROADCAST SEAT • HOST",16,Color("#efd7a0"))

 else:
  words(Vector2(36,548),"3v3 / 4v4 • Invite your team" if game.mode=="battlegrounds" else "Friends or solo • Arena bots available",13,Color("#9dbac1"))

func results()->void:
 box(Rect2(354,286,890,214),Color("#142631"),Color("#d7bf82"),2)
 words(Vector2(375,274),game.results_reason,20,Color("#f0d69e"),840)
 for n in 5:words(Vector2(616+n*120,302),["DAMAGE","HEAL","REVIVES","DEFENCE","UPGRADES"][n],13,Color("#9cbfc2"))
 var row:=0
 for member in game.fighters():
  var id:=str(member.get("id",""));var stats:Dictionary=game.contributions.get(id,{});var y:=329+row*18
  words(Vector2(375,y),str(member.get("name","Player")),16,Color.WHITE,220)
  for n in 5:words(Vector2(616+n*120,y),str(int(stats.get(["damage","healing","revives","defence","upgrades"][n],0))),16,Color("#e8d9b1"))
  row+=1
 if not game.spectating():words(Vector2(375,483),game.legacy.result_line(str(game.hero_ids.get(game.my_id,game.selected_hero))),12,Color("#e8d9b1"),835)
 words(Vector2(375,486),"Host can Start again. Show Party to change sides. Back to Town to see your card.",14,Color("#9ebdbf"),835)

func side_count(side:int)->int:
 var count:=0
 for member in members():
  if side_of(str(member.get("id","")))==side:count+=1
 return count

func _get_tooltip(point:Vector2)->String:
 if game==null:return ""
 var R=preload("res://scripts/rolling_crowns.gd")
 for i in members().size():
  var member:Dictionary=members()[i];var id=str(member.get("id",""));var p:Vector2=moving.get(id,position_for(id,i))
  if point.distance_to(p-Vector2(0,22))>45:continue
  var local=id==game.my_id or id=="preview";var cosmetic:Dictionary=game.local_cosmetic() if local else game.cosmetic_for(id);var rank=R.remote_tier(cosmetic)
  if rank>0:return R.rank_name(rank)+" • worn crown\n"+str(int(cosmetic.get("crown_damage",0)))+" damage in the last 7 days\nActive: "+R.rank_name(R.remote_active_tier(cosmetic))
 return ""
