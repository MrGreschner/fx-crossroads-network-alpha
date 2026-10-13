extends SceneTree
var failures=0
func check(value:bool,label:String)->void:
 if not value:failures+=1;push_error(label)
 else:print("PASS • "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume()
 var c=g.legacy.cosmetics
 check(c.week_key("2026-10-10")=="2026-10-04","Saturday belongs to previous Sunday")
 check(c.week_key("2026-10-11")=="2026-10-11","Sunday begins new week")
 c.date_for_test="2026-10-10";c.refresh();c.state().damage=0;c.add_damage(10000);check(c.tier()==1,"10k tier")
 c.add_damage(10000);check(c.tier()==2,"20k tier");c.add_damage(10000);check(c.tier()==3,"30k tier")
 c.select("weekly_3");check(c.effect()=="weekly_3","equipped weekly reward")
 var research=root.get_node("FXResearch");research.begin();c.add_damage(100);check(c.state().damage==30000,"Playtest cannot earn damage");check(research.report().contains("Playtest Mode"),"Playtest evidence renamed");research.active=false;research.hide()
 g.legacy.data.teacher=true;c.add_damage(100);check(c.state().damage==30000,"Game Dev cannot earn damage");g.legacy.data.teacher=false
 c.date_for_test="2026-10-11";c.refresh();check(c.tier()==0 and c.effect()=="","weekly expiry")
 check(not c.easter_unlocked(),"Easter Egg starts locked")
 g.legacy.card.state().badges=preload("res://scripts/profile_card.gd").BADGES.keys()
 check(c.easter_unlocked(),"all four expert badges unlock Easter Egg")
 c.select("easter");c.date_for_test="2026-10-18";c.refresh();check(c.effect()=="easter","Easter Egg persists after weekly reset")
 check(c.valid(c.state()),"cosmetics profile validates");check(not c.valid({"damage":-1}),"invalid cosmetics rejected")
 c.open_picker();check(g.menu=="cosmetics","picker blocks combat inputs");c.close_picker()
 var w=g.hero_workshop
 w.open();w.hub.hide();w.panel.show()
 var partner=root.get_node("FXStudioPartner");partner.workshop=w
 var examples=preload("res://scripts/studio_examples.gd")
 for kind in ["hero","ability","enemy","behavior"]:
  var value=examples.random_example(kind);var envelope={"kind":kind,"value":value}
  check(partner.valid(envelope),kind+" shared schema validates");partner.apply_shared(envelope)
  var current=partner.capture();check(current.get("kind")==kind,kind+" round trip preserves lab")
  check(current.get("value",{}).get("name",current.get("value",{}).get("hero",{}).get("name",""))==value.get("name",value.get("hero",{}).get("name","")),kind+" round trip preserves name")
 partner.apply_shared({"kind":"hero","value":{"bad":true}});check(partner.shared.kind=="behavior","invalid partner draft leaves valid draft intact")
 w.close();print("V132 CHECKS • failures: ",failures);quit(failures)
