extends SceneTree
var failures:=0
func check(value:bool,title:String)->void:
 if not value:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func tidy(g:Node)->void:
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close()
 g.profile.tutorial_seen=true;g.profile.runs=40;g.journey.data.skipped=true
 g.session_menu.open("main");g.session_menu.resume()
 check(g.presentation.page=="starter","saved veteran is offered tutorial on fresh launch")
 g.presentation.skip_intro();g.session_menu.open("main");g.session_menu.resume()
 check(g.presentation.page!="starter","not offered again on same process launch")
 root.remove_meta("fx_tutorial_offered");g.session_menu.open("main");g.session_menu.resume()
 check(g.presentation.page=="starter","new launch meta offers again regardless of skip history")
 g.presentation.close();g.menu=""
 root.remove_meta("fx_tutorial_offered");g.session_menu.open("main");g.session_menu.resume(false)
 check(not root.has_meta("fx_tutorial_offered"),"profile-action resume cannot silently consume tutorial offer")
 g.presentation._process(0.01);check(g.presentation.page=="starter","tutorial offered after returning from profile actions")
 g.presentation.close();g.menu=""
 var dev:Node=root.get_node("FXDevSession");dev.begin();var tools:Node=dev.tools
 g.health=20;g.cooldowns.primary=5
 tools.toggle();check(g.menu=="dev_desk","desk blocks player combat input")
 check(tools.experiment("health") and g.health==g.max_health(),"solo health experiment works")
 check(g.menu.is_empty(),"closing desk restores prior input state")
 check(tools.experiment("cooldowns") and g.cooldowns.primary==0,"solo cooldown reset works")
 tools.toggle();tools.caption.text="Testing melee counters";tools.present();check(tools.banner.visible and "Testing melee counters" in tools.banner.text and not tools.opened,"presentation caption does not hold combat input")
 check(tools.experiment("training") and g.level==10 and g.practice,"training shortcut offers level10 testing")
 var normal_data:Dictionary=g.legacy.data.duplicate(true)
 check(preload("res://scripts/profile_store.gd").testing(),"dev save protection remains active")
 check(g.legacy.data==normal_data,"desk actions do not alter profile progression")
 tools.close_desk();await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.party_tools.set_process(false);a.role="host";a.mode="arena";a.my_id="host";a.host_id="host";a.roster.assign([{"id":"host","name":"Student"},{"id":"guest","name":"Friend"}]);a._add_player("host",0);a._add_player("guest",1)
 a.player_cosmetics.guest={"game_dev":true,"title":"GAME DEV","colour":"ffffff"}
 check(a.local_cosmetic().game_dev,"host test status is explicit")
 var lobby:Dictionary=a._lobby_packet();check(lobby.players[0].cosmetic.game_dev and lobby.players[1].cosmetic.game_dev,"lobby distributes both host and guest markers")
 var snapshot:Dictionary=a._snapshot();check(snapshot.players.host.cosmetic.game_dev and snapshot.players.guest.cosmetic.game_dev,"game snapshot retains both markers")
 check(not tools.experiment("health"),"multiplayer cannot use solo restore tools")
 dev.active=false;dev.overlay.hide();check(not a.local_cosmetic().game_dev,"marker clears when dev ends")
 a._receive_lobby(lobby);check(a.player_cosmetics.guest.game_dev,"remote lobby receives marker")
 a._drop_member("guest");check(not a.player_cosmetics.has("guest"),"departed players leave no stale dev marker")
 dev.tools.close_desk();await tidy(a);print("v115 failures: ",failures);quit(1 if failures else 0)
