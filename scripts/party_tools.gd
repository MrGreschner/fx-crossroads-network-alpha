extends CanvasLayer
var game:Node
var browser:WebSocketPeer
var request_timer=0.0
var browser_elapsed=0.0
var rows:VBoxContainer
var message:Label
var selected_code=""
var join_button:Button
var invite_button:Button
var request_panel:PanelContainer
var requests:Dictionary={}
var waiting=false
var auto_solo=false
var solo_wait=0.0
var late_pending:Dictionary={}
func setup(owner:Node)->void:
 game=owner;layer=43
 invite_button=Button.new();invite_button.position=Vector2(820,8);invite_button.size=Vector2(220,44);invite_button.visible=false;invite_button.text="Invite friend";game.presentation.style_button(invite_button);invite_button.pressed.connect(invite);add_child(invite_button)
func change_hero(index:int)->void:
 if game.started:return
 var id=str(game.hero_picker.get_item_metadata(index))
 if not game.characters.has(id):return
 if id.begins_with("custom_") and not game.custom_party.allowed(game.custom_party.project_for(id)):game.status_label.text="Customs are off, or this public build needs Forced Balance.";return
 game.selected_hero=id;game.preferred_hero=id;game.get_tree().root.set_meta("fx_hero",id);game.session_hero_sent=false
 if not game.my_id.is_empty():game.hero_ids[game.my_id]=id;game.lobby_heroes[game.my_id]=id;game.lobby_builds[game.my_id]=game.legacy.payload(id);game.health[game.my_id]=game._max_hp(game.my_id)
 game._send_lobby_state()
 game._send_ws({"type":"custom_status","custom":id.begins_with("custom_"),"balanced":preload("res://scripts/studio_balance.gd").hero_checked(game.custom_party.project_for(id)) if id.begins_with("custom_") else true})
func browse()->void:
 if not game.role.is_empty():return
 game.presentation.window("PUBLIC ROOMS • WAITING TO START","rooms")
 game.presentation.label(game.presentation.content,"Choose a hosted room. Private rooms and running matches are not listed.",18)
 var actions=HBoxContainer.new();game.presentation.content.add_child(actions)
 game.presentation.button(actions,"Refresh rooms",refresh)
 join_button=game.presentation.button(actions,"Join selected room",join_selected);join_button.disabled=true
 message=game.presentation.label(game.presentation.content,"Looking for public rooms…",17)
 rows=VBoxContainer.new();rows.add_theme_constant_override("separation",10);game.presentation.content.add_child(rows);selected_code="";refresh()
func refresh()->void:
 if browser!=null:browser.close()
 browser=WebSocketPeer.new();browser_elapsed=0;request_timer=0
 if browser.connect_to_url(game.ROOM_SERVICE_URL)!=OK:message.text="Room service unavailable. You can still use a friend's code."
func show_rooms(data:Dictionary)->void:
 if not is_instance_valid(rows):return
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 var previous=selected_code;selected_code="";join_button.disabled=true
 var entries:Array=data.get("rooms",[]);message.text="No public rooms are waiting. Host a public room to start a party." if entries.is_empty() else str(entries.size())+" public rooms waiting • updates every 5 seconds"
 for entry in entries:
  var title:String=str(entry.host)+" • "+str(entry.mode).capitalize()+" • "+str(entry.players)+"/"+str(entry.get("seats",4))
  if str(entry.mode)=="coop":title+=" • "+str(game.regions.get(str(entry.realm),{}).get("name",entry.realm))
  if str(entry.mode)=="battlegrounds":title+=" • "+str(entry.get("bg_team_size",4))+"v"+str(entry.get("bg_team_size",4))+" • "+str(game.battlegrounds.MAPS.get(str(entry.get("bg_map","woodland")),"Front"))
  if str(entry.mode)=="arena":title+=" • "+str(entry.rule).to_upper()+" • "+str(game.arena_world.MAPS.get(str(entry.get("arena_map","crossroads")),"Arena"))+" • "+("Lv1" if bool(entry.get("opening",false)) else "Lv10")
  if str(entry.mode) in ["arena","defense"]:title+=" • AI "+str(entry.get("ai_difficulty","medium")).capitalize()
  if entry.get("allow_custom",false):title+=" • Custom builds allowed"
  var code=str(entry.code)
  if code==previous:selected_code=code;join_button.disabled=false
  var b=game.presentation.button(rows,title,func():selected_code=code;join_button.disabled=false;message.text="Selected "+title)
  b.alignment=HORIZONTAL_ALIGNMENT_LEFT
func join_selected()->void:
 if selected_code.is_empty() or not game.role.is_empty():return
 var code=selected_code;game.presentation.close();game.code_field.text=code;game._join()
func online_solo()->void:
 if game.mode=="arena":game._solo();return
 if game.mode not in ["defense","descent"]:return
 auto_solo=true;solo_wait=0;var command:Dictionary=game._room_command("host");command.public=false;game._connect(command);game.status_label.text="Preparing a private solo room so a friend can join later…"
func invite()->void:
 game.presentation.window("INVITE A FRIEND","invite")
 game.presentation.label(game.presentation.content,"Room code: "+game.room_code,32)
 game.presentation.label(game.presentation.content,"Ask your friend to open Gather Your Party, enter this code and press Join / Request. Approve their request here. They start at level 1.",20)
 game.presentation.label(game.presentation.content,"Requests expire after 30 seconds. Late joins are available in Defence and Descent. Arena rosters are locked while fighting.",18)
func accept(id:String,value:bool)->void:
 game._send_ws({"type":"join_reply","id":id,"accept":value});requests.erase(id);draw_requests()
func draw_requests()->void:
 if is_instance_valid(request_panel):remove_child(request_panel);request_panel.queue_free()
 if requests.is_empty():return
 request_panel=PanelContainer.new();request_panel.position=Vector2(game.VIEW.x-380,165);request_panel.custom_minimum_size=Vector2(360,100);add_child(request_panel)
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#16343d");skin.content_margin_left=14;skin.content_margin_right=14;skin.content_margin_top=12;skin.content_margin_bottom=12;request_panel.add_theme_stylebox_override("panel",skin)
 var col=VBoxContainer.new();request_panel.add_child(col)
 for id in requests:
  game.presentation.label(col,str(requests[id].name)+" wants to join (Lv1)",17)
  var row=HBoxContainer.new();col.add_child(row);game.presentation.button(row,"Accept",accept.bind(str(id),true));game.presentation.button(row,"Decline",accept.bind(str(id),false))
func server(data:Dictionary)->bool:
 match str(data.get("type","")):
  "join_requested":
   if game.role=="host" and game.started and game.mode in ["defense","descent"] and not (game.get("continuation")!=null and game.continuation.active):requests[str(data.id)]={"name":str(data.name),"time":30.0};draw_requests()
   else:game._send_ws({"type":"join_reply","id":str(data.id),"accept":false})
   return true
  "join_pending":waiting=true;game.status_label.text=str(data.message);return true
  "joined":waiting=false
  "hosted":
   if auto_solo:solo_wait=0
  "error":
   if auto_solo:auto_solo=false;game._solo();game.status_label.text="Offline solo • inviting is unavailable. Return to the lobby to retry online.";return true
 return false
func _process(delta:float)->void:
 if game==null:return
 invite_button.visible=not (game.get("continuation")!=null and game.continuation.active) and game.started and game.mode in ["defense","descent"] and not game.room_code.is_empty() and game.presentation.page.is_empty()
 invite_button.text="Invite • "+game.room_code
 if is_instance_valid(request_panel):request_panel.position.x=game.VIEW.x-380
 for id in late_pending.keys():
  late_pending[id]=float(late_pending[id])-delta
  if float(late_pending[id])<=0:late_pending.erase(id);game._send_ws({"type":"remove_peer","id":id})
 for id in requests.keys():
  requests[id].time-=delta
  if float(requests[id].time)<=0:requests.erase(id);draw_requests()
 if auto_solo:
  solo_wait+=delta
  game.status_label.text="Connecting private room • offline solo starts in %ds" % maxi(0,ceili(8-solo_wait))
  if solo_wait>=8:auto_solo=false;game._solo();game.status_label.text="Offline solo • room service did not respond."
 if game.presentation.page!="rooms":
  if browser!=null:browser.close();browser=null
  return
 if browser==null:return
 browser.poll();browser_elapsed+=delta
 if browser.get_ready_state()==WebSocketPeer.STATE_OPEN:
  request_timer-=delta
  if request_timer<=0:request_timer=5;browser.send_text(JSON.stringify({"type":"list_rooms","version":32}))
  while browser.get_available_packet_count()>0:
   var data:Variant=JSON.parse_string(browser.get_packet().get_string_from_utf8())
   if data is Dictionary:
    if str(data.get("type",""))=="room_list":show_rooms(data)
    elif str(data.get("type",""))=="error":message.text="Room service: "+str(data.get("message","Unavailable"))+" • use service version 28."
    elif str(data.get("type",""))=="server_info" and int(data.get("version",0))<28:message.text="Update the room service to version 28 to browse rooms."
 elif browser_elapsed>8 and is_instance_valid(message):message.text="Could not reach the room service. Refresh to retry, or join by code."

func reset_requests()->void:
 waiting=false;requests.clear();late_pending.clear()
 if is_instance_valid(request_panel):remove_child(request_panel);request_panel.queue_free()

func _exit_tree()->void:
 if browser!=null:browser.close()
