extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host.legacy.set_process(false);host.legacy.data=host.legacy.defaults();host.role="host";host.my_id="a";host.host_id="a";host._set_mode("arena");host.rule_picker.select(1)
 host.roster.assign([{"id":"a","name":"Alice"},{"id":"b","name":"Bob"},{"id":"c","name":"Cat"},{"id":"d","name":"Dan"}])
 for n in 4:host._add_player(str(host.roster[n].id),n)
 check(host.teams.values()==[-1,-1,-1,-1],"players start in centre")
 host.party_lobby.pick(Vector2(400,300));check(host.teams.a==0,"tap Silver moves local hero")
 host._packet("b",{"type":"team","team":0});host._packet("c",{"type":"team","team":0});check(host.teams.b==0 and host.teams.c==-1,"team capacity is enforced by host")
 host._packet("c",{"type":"team","team":1});host._packet("d",{"type":"team","team":1});check(host._teams_ready(),"balanced four-player party is ready")
 host._packet("d",{"type":"team","team":-1});check(not host._teams_ready(),"unassigned player blocks 2v2 readiness")
 host._packet("d",{"type":"team","team":1})
 host._packet("b",{"type":"hero","hero":"book","build":{},"random_builds":{},"food":""});check(host.hero_ids.b=="book","guest selected hero enters lineup")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest.legacy.set_process(false);guest.role="guest";guest.my_id="b";guest.host_id="a";guest._set_mode("arena")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._lobby_packet()));guest._packet("a",packet)
 check(guest.roster.size()==4 and guest.hero_ids.b=="book" and int(guest.teams.b)==0 and guest.rule_picker.selected==1,"host lobby synchronizes heroes, roster and teams")
 var prior:int=guest.teams.b;guest._packet("c",{"type":"lobby","players":[],"rule":0});check(guest.teams.b==prior and guest.roster.size()==4,"nonhost cannot override lobby")
 check(host.party_lobby.position_for("a",0).x<640 and host.party_lobby.position_for("c",2).x>944,"team placements match visual sides")
 host.started=true;host._packet("b",{"type":"team","team":1});check(host.teams.b==0,"teams locked during match")
 host.started=false
 var legacy=host.legacy
 for n in 9:legacy.clear_adventure("ram","grove")
 check(legacy.realm_clears("grove")==9 and not legacy.realm_mastered("grove"),"nine clears do not master realm")
 legacy.clear_adventure("book","grove");check(legacy.realm_mastered("grove") and legacy.realm_clears("grove")==10,"ten clears across heroes master realm")
 legacy.clear_adventure("ram","defense");check(legacy.realm_clears("defense")==0,"survival milestones do not count as realms")
 legacy.data.teacher=true;legacy.clear_adventure("ram","grove");check(legacy.realm_clears("grove")==10,"teacher mode does not earn stars")
 legacy.data.teacher=false;check(legacy.validate(legacy.bundle()),"realm counts export validates")
 var bad:Dictionary=legacy.bundle();bad.progress.realm_counts.grove=-1;check(not legacy.validate(bad),"negative realm count import rejected")
 legacy.data.erase("realm_counts");check(legacy.realm_clears("grove")==0,"older profiles remain readable")
 legacy.clear_adventure("ram","grove");check(legacy.realm_clears("grove")==1,"old profile starts accurate realm counter")
 for game in [host,guest]:
  for voice in game.journey.voices:voice.stop()
  game.queue_free()
 await create_timer(.2).timeout;print("V71 party lobby: ",failures," failures");quit(1 if failures else 0)
