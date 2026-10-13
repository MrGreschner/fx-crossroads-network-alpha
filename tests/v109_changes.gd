extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false)
 a.role="host";a.mode="arena";a.started=true;a.start_countdown=0;a._add_player("mage",0);a._add_player("foe",1);a._add_player("ally",2);a.pvp_rule="teams";a.teams={"mage":0,"foe":1,"ally":0}
 a.positions={"mage":Vector2(700,500),"foe":Vector2(750,500),"ally":Vector2(750,500)};a.hero_ids.mage="twisterspell";a.levels.mage=10;a.adventure.setup("");a.field_obstacles.clear();a._rebuild_grid()
 var c=a.adventure.combat;var t=c.twister;var primary:Dictionary=a.characters.twisterspell.primary
 t.holding("mage",true,Vector2.RIGHT);t.cast("mage",primary,Vector2.RIGHT,3);t.step(.05);t.holding("mage",false,Vector2.RIGHT)
 check(t.effects.size()==1 and float(t.effects[0].radius)<40 and not bool(t.effects[0].pull),"tap casts a small funnel")
 t.reset();t.holding("mage",true,Vector2.RIGHT);t.cast("mage",primary,Vector2.RIGHT,3)
 for n in 17:t.holding("mage",true,Vector2.RIGHT);t.step(.1)
 check(t.charges.has("mage") and t.effects.is_empty(),"full charge waits for release")
 t.holding("mage",false,Vector2.RIGHT)
 check(is_equal_approx(float(t.effects[0].radius),float(primary.radius)*1.7) and t.effects[0].pull and is_equal_approx(float(t.effects[0].damage),7.2),"full charge grows damage/radius and adds pull")
 var before:int=a.health.foe;var friendly:int=a.health.ally;t.step(.01)
 check(a.health.foe<before and a.health.ally==friendly and c.effect_time("p:foe","slow")>0,"funnels damage and slow enemies, never allies")
 for n in 7:
  t.holding("mage",true,Vector2.RIGHT);t.cast("mage",primary,Vector2.RIGHT,3);t.holding("mage",false,Vector2.RIGHT)
 check(t.effects.filter(func(e):return e.kind=="funnel").size()==4,"four-funnel owner cap")
 var snap:Dictionary=t.snapshot().duplicate(true);t.reset();t.receive(snap);check(t.effects.size()==4,"network snapshot round-trip preserves funnels")
 t.reset();a.role="guest";t.cast("mage",primary,Vector2.RIGHT,3);check(t.charges.is_empty() and t.effects.is_empty(),"guests cannot create authoritative weather");a.role="host"
 t.cast("mage",a.characters.twisterspell.secondary,Vector2.RIGHT,7);check(c.speed_factor("p:mage")>1,"tornado form increases controllable movement")
 t.reset();t.cast("mage",a.characters.twisterspell.special,Vector2.RIGHT,16);check(c.speed_factor("p:mage")==0,"hail channel immobilises caster")
 t.step(2.01);check(t.effects.any(func(e):return e.kind=="storm"),"channel becomes hailstorm")
 t.step(.1);check(t.effects.any(func(e):return e.kind=="ice"),"hail has warned delayed landings")
 a.started=false;t.step(.1);check(t.effects.is_empty(),"weather cleared outside active gameplay")
 check(a.characters.has("twisterspell"),"new mage loaded in multiplayer")
 for player in a.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 a.queue_free();await process_frame
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 check(g.characters.size()>=75,"all 75 playable heroes loaded")
 check(g.town_v109.blocked(Vector2(2000,990)) and not g.town_v109.blocked(g.town_v109.TOWER),"tower solid with accessible entrance")
 check(g.can_stand_at(g.town_v109.TOWER),"tower approach is walkable in actual town")
 check(g.can_stand_at(g.town_v109.BARRACKS),"barracks approach is walkable in actual town")
 check(g.town_v109.blocked(Vector2(1300,1330)) and not g.town_v109.blocked(g.town_v109.BARRACKS),"barracks solid with accessible entrance")
 check(not g.legacy.card_building_rect("relay").intersects(Rect2(408,1320,274,170)),"workshop no longer overlaps post office")
 g.position_in_world=g.town_v109.TOWER
 var event:=InputEventAction.new();event.action="interact";event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();g.town_v109.interact(g);Input.action_release("interact");await process_frame
 check(g.menu=="arcane_tower" and g.town_services.panel.visible,"spell tower opens native interaction UI")
 g.town_services.close();g.selected_character="twisterspell";g.start_training()
 var weather=g.adventure.combat.twister
 g.adventure.combat.v56.holding("solo",true,Vector2.RIGHT);g.fire("primary")
 check(weather.charges.has("solo"),"normal solo primary starts a held charge")
 weather.charges.solo.age=1.6;g.adventure.combat.v56.holding("solo",false,Vector2.RIGHT)
 check(weather.effects.size()==1 and weather.effects[0].pull,"normal shared release casts the charged funnel")
 g.enter_region("town");check(weather.effects.is_empty() and weather.charges.is_empty(),"return to town clears charge and weather")
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame;print("v109 changes failures: ",failures);quit(1 if failures else 0)
