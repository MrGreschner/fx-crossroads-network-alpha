extends SceneTree
const ICONS=preload("res://scripts/ui_reward_icons.gd")
var checks=0
var failures=0
func check(ok:bool,title:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",title)
 if not ok:failures+=1
func inspect(node:Node,kinds:Array)->void:
 if node is TextureRect and node.has_meta("reward_icon"):
  kinds.append(str(node.get_meta("reward_icon")));check(node.texture!=null and node.texture.get_width()==32,"reward row has real artwork")
 if node is Label:check(not node.text.contains("★"),"label uses no unsupported star glyph")
 for child in node.get_children():inspect(child,kinds)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 for kind in ["star","trophy","building"]:
  var image=ICONS.texture(kind);check(image!=null and image.get_width()==32,"standalone "+kind+" artwork loads")
  check(ICONS.texture(kind)==image,"artwork reused from cache")
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 8:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.close();g.session_menu.resume();g.menu="";g.legacy.data=g.legacy.defaults();g.legacy.mine.setup(g.legacy)
 g.start_run(false,"grove");g.set_process(false);g.run_time=307;g.result_text="NEW PERSONAL BEST!"
 var record=g.legacy.record("ram");record.damage=11000;record.clears=3;record.realms=["grove","quarry"]
 g.legacy.data.tasks.damage=6000;g.legacy.data.tasks.realms=["grove","quarry","ice"]
 g.legacy.mine.state().wallet.gold=100;g.legacy.mine.state().wallet.ore=100
 g.presentation.results(true);var kinds=[];inspect(g.presentation.content,kinds)
 check("trophy" in kinds and "star" in kinds and "building" in kinds,"victory best / mastery / building rewards each use an icon")
 g.presentation.close();g.presentation.last_result="";g.last_defeat={};g.presentation.results(false)
 kinds=[];inspect(g.presentation.content,kinds);check(g.presentation.page=="results","defeat screen also opens")
 g.presentation.close();g.queue_free();current_scene=null
 for n in 4:await process_frame
 print("V151 ",checks," checks / ",failures," failures");quit(1 if failures else 0)
