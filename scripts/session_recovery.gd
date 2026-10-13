extends CanvasLayer
## Recover live sessions, never replay a start packet or invent a host checkpoint.
const GRACE:=45.0
const STALE:=4.0
var game:Node
var token:=""
var frozen:=false
var host_paused:=false
var resync_local:=false
var seen:Dictionary={}
var gaps:Dictionary={}
var attempts:Dictionary={}
var epochs:Dictionary={}
var socket_elapsed:=0.0
var socket_retry:=0.0
var connecting_time:=0.0
var socket_attempt:=0
var pulse:=0.0
var failed:=false
var overlay:PanelContainer
var heading:Label
var detail:Label
var retry_button:Button
var solo_button:Button
var back_button:Button
func setup(owner:Node)->void:
 game=owner;layer=60
 overlay=PanelContainer.new();overlay.position=Vector2(250,245);overlay.size=Vector2(780,245);overlay.visible=false;add_child(overlay)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#142b36");skin.border_color=Color("#ddba78");skin.set_border_width_all(2);skin.set_corner_radius_all(12);skin.content_margin_left=24;skin.content_margin_right=24;skin.content_margin_top=20;skin.content_margin_bottom=20;overlay.add_theme_stylebox_override("panel",skin)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",14);overlay.add_child(col)
 heading=Label.new();heading.add_theme_font_size_override("font_size",27);col.add_child(heading)
 detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.x=730;detail.add_theme_font_size_override("font_size",19);col.add_child(detail)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);col.add_child(row)
 retry_button=add_button(row,"Try reconnecting",retry)
 solo_button=add_button(row,"Restart solo",restart_solo)
 back_button=add_button(row,"Back to town",func():game._town())
func add_button(parent:Node,label:String,action:Callable)->Button:
 var b:=Button.new();b.text=label;b.custom_minimum_size=Vector2(200,46);b.pressed.connect(action);game.presentation.style_button(b);parent.add_child(b);return b
func reset()->void:
 token="";frozen=false;host_paused=false;failed=false;seen.clear();gaps.clear();attempts.clear();epochs.clear();socket_elapsed=0;socket_retry=0;socket_attempt=0;connecting_time=0;resync_local=false
 if is_instance_valid(overlay):overlay.visible=false
func remember(data:Dictionary)->void:
 token=str(data.get("resume_token",token));socket_elapsed=0;socket_retry=0;socket_attempt=0
func incoming(id:String)->void:
 seen[id]=now()
func now()->float:return Time.get_ticks_msec()/1000.0
func packet(id:String,data:Dictionary)->bool:
 incoming(id)
 match str(data.get("type","")):
  "link_heartbeat":return true
  "session_pause":
   if game.role=="guest" and id==game.host_id:host_paused=bool(data.get("paused",false))
   return true
 return false
func server(data:Dictionary)->bool:
 match str(data.get("type","")):
  "hosted","joined":remember(data)
  "resumed":
   if str(data.get("id",""))!=game.my_id:lost_host("The old room could not be recovered.");return true
   remember(data);game.roster.assign(data.get("roster",[]));game.bots.sync_lobby();game.status_label.text="Room connection restored."
   for member in game.roster:
    var id:String=str(member.get("id",""))
    if not game.bots.is_bot(id) and id!=game.my_id and not game._link_open(id):repair(id)
   return true
  "peer_resumed":
   var id:String=str(data.get("id",""))
   if game.role=="host" and not game._link_open(id):repair(id)
   return true
  "peer_reconnecting":game.status_label.text="A player is reconnecting to the room service."
  "room_closed":
   token=""
   return false
  "peer_left":
   var id:String=str(data.get("id",""))
   if game.started and game.role=="host" and game.mode=="arena" and not game._link_open(id):game.end_match("Arena interrupted • no winner recorded");return false
   if gaps.has(id):gaps[id]=GRACE
  "error":
   if str(data.get("message","")).begins_with("Resume expired."):
    token="";socket_elapsed=GRACE
 return false
func drop_link(id:String)->void:
 if game.links.has(id):
  game._close_link(id)
func repair(id:String)->void:
 if game.socket==null or game.socket.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 if game.role=="host":
  epochs[id]=int(epochs.get(id,0))+1;drop_link(id);game._create_link(id,true)
 elif id==game.host_id:game._send_signal(id,{"kind":"repair"})
func signal_for(id:String,value:Dictionary)->bool:
 if str(value.get("kind",""))=="repair":
  if game.role=="host" and (not game._link_open(id) or now()-float(seen.get(id,0))>=STALE):repair(id)
  return true
 var epoch:int=int(value.get("epoch",0));var current:int=int(epochs.get(id,0))
 if epoch<current:return true
 if game.role=="guest" and id==game.host_id and epoch>current:
  epochs[id]=epoch;drop_link(id);game._create_link(id,false);resync_local=true
 return false
func lost_host(reason:String)->void:
 if not game.started:
  game.status_label.text=reason+" Host or join another room.";game._reset_connection();return
 failed=true;frozen=true;host_paused=false;heading.text="CONNECTION INTERRUPTED";detail.text=reason+" Your saved profile is safe. Restarting solo begins a new adventure; it does not restore this battle.";show_overlay()
func retry()->void:
 failed=false;gaps.clear();socket_elapsed=0;socket_retry=0;socket_attempt=0;seen[game.host_id]=now()-STALE
 for member in game.roster:
  var id:String=str(member.get("id",""))
  if not game.bots.is_bot(id) and id!=game.my_id:attempts[id]=0;repair(id)
func restart_solo()->void:
 if game.mode=="arena":return
 if game.mode=="coop":
  game.get_tree().root.set_meta("fx_retry_realm",game.realm_id);game._town()
 else:
  game.started=false;game.results_reason="";game.presentation.close();game._solo()
func show_overlay()->void:
 overlay.visible=true;solo_button.visible=game.mode!="arena";retry_button.visible=not token.is_empty() or game._has_open_link()
 game.mobile.reset_controls()
func step(delta:float)->void:
 if is_instance_valid(overlay):overlay.position=(get_viewport().get_visible_rect().size-Vector2(780,245))*.5
 if game==null or game.role.is_empty() or game.my_id=="solo":frozen=false;overlay.visible=false;return
 var stamp:=now()
 # The signaling service can resume while direct gameplay is still healthy.
 var socket_state:int=WebSocketPeer.STATE_CLOSED if game.socket==null else game.socket.get_ready_state()
 if socket_state!=WebSocketPeer.STATE_OPEN:socket_elapsed+=delta
 if socket_state==WebSocketPeer.STATE_CONNECTING:
  connecting_time+=delta
  if connecting_time>=8:game.socket.close();game.socket=null;connecting_time=0
 if socket_state==WebSocketPeer.STATE_CLOSED:
  socket_retry-=delta
  if not token.is_empty() and socket_elapsed<GRACE and socket_retry<=0:
   socket_attempt+=1;socket_retry=minf(8.0,pow(2,mini(socket_attempt,3)));connecting_time=0
   game.pending_command={"type":"resume","token":token};game.socket=WebSocketPeer.new();game.last_socket_state=WebSocketPeer.STATE_CLOSED;game.socket.connect_to_url(game.ROOM_SERVICE_URL)
 var previous:=frozen
 var missing:=false
 for member in game.roster:
  var id:String=str(member.get("id",""))
  if game.bots.is_bot(id) or id==game.my_id or game.role=="guest" and id!=game.host_id:continue
  if game._link_open(id) and not seen.has(id):seen[id]=stamp
  var stale:bool=seen.has(id) and stamp-float(seen[id])>=STALE
  if seen.has(id) and (not game._link_open(id) or stale):
   gaps[id]=float(gaps.get(id,0))+delta;missing=true;attempts[id]=float(attempts.get(id,0))-delta
   if float(attempts[id])<=0:attempts[id]=6.0;repair(id)
   if float(gaps[id])>=GRACE:
    if game.role=="guest":lost_host("The host did not return. A closed or crashed host cannot resume this match.")
    elif game.mode=="arena":
     game.end_match("Arena interrupted • no winner recorded");gaps.clear();failed=false;missing=false;break
    else:
     game.adventure.combat.classics.holding(id,false);game.adventure.combat.v56.holding(id,false,Vector2.RIGHT)
     game.positions.erase(id);game.health.erase(id);game.downed.erase(id);drop_link(id)
     for n in range(game.roster.size()-1,-1,-1):
      if str(game.roster[n].get("id",""))==id:game.roster.remove_at(n)
     game._send_ws({"type":"remove_peer","id":id});gaps.erase(id);seen.erase(id);missing=not gaps.is_empty()
  else:
   if gaps.has(id) and game.role=="guest":resync_local=true
   gaps.erase(id)
 # Hosts pause their simulation; guests wait for a fresh authoritative snapshot.
 frozen=failed or game.started and (missing or host_paused)
 pulse-=delta
 if pulse<=0:
  pulse=1.0
  for id in game.links.keys():
   game._send_channel(str(id),{"type":"link_heartbeat"})
   if game.role=="host":game._send_channel(str(id),{"type":"session_pause","paused":frozen})
 if previous and not frozen and game.role=="host":
  var state:Dictionary=game._snapshot()
  for id in game.links.keys():game._send_channel(str(id),{"type":"session_pause","paused":false});var config:Dictionary=game.match_config();config.type="resume_start";game._send_channel(str(id),config);game._send_channel(str(id),state)
 if frozen and not failed:
  heading.text="RECONNECTING • battle paused"
  var longest:=0.0
  for seconds in gaps.values():longest=maxf(longest,float(seconds))
  detail.text="Waiting for the host." if game.role=="guest" and host_paused and not missing else "Trying to restore the connection • %d seconds remaining.\nKeep this tab open. You can return to town at any time." % maxi(0,int(GRACE-longest))
  show_overlay()
 elif not failed:overlay.visible=false
