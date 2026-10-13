extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var stable=get_root().get_node("FXStability")
 stable.school_mode=true;stable.apply_mode()
 check(Engine.max_fps==30 and root.content_scale_mode==Window.CONTENT_SCALE_MODE_VIEWPORT,"school mode reduces FPS and render resolution")
 var cues:Array=[]
 for n in 300:cues.append(n)
 stable.trim(cues,80);check(cues.size()==80 and cues.front()==220,"cosmetic cap retains newest cues")
 stable.school_mode=false;stable.trim(cues,20);check(cues.size()==60,"normal mode uses larger budget")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host.legacy.set_process(false);host._set_mode("defense");host._solo();host._spawn_wave(1)
 host.effects.clear();host.sent_effects.clear();host.damage_labels.clear()
 for n in 400:host._emit_effect({"pos":Vector2(100,100),"radius":20,"time":.4,"color":"#fff"})
 stable.school_mode=true;stable.trim(host.effects,80);stable.trim(host.sent_effects,128)
 check(host.effects.size()==80 and host.sent_effects.size()==128,"local and network cosmetics bounded")
 check(host.started and not host.opponents.is_empty(),"cosmetic trimming keeps gameplay enemies")
 check(host._defer_state({"type":"state","active":true},600000) and not host._defer_state({"type":"state","active":false},600000) and not host._defer_state({"type":"attack"},600000),"queue backpressure skips only replaceable active snapshots")
 check(not host._has_open_link(),"solo requires no network snapshot")
 stable.capture();var report:Variant=JSON.parse_string(stable.report());check(report is Dictionary and report.version=="v77" and report.samples.size()>0,"diagnostic report parses")
 host.sent_effects.append({"pos":Vector2.ZERO});host._start_match();check(host.sent_effects.is_empty(),"restarting match clears unsent cosmetic events")
 var preset:=ConfigFile.new();check(preset.load("res://export_presets.cfg")==OK,"export presets parse")
 check(preset.get_value("preset.1","platform")=="Windows Desktop","Windows export configured")
 check("*.gdextension" in str(preset.get_value("preset.0","exclude_filter")),"Web excludes native extension")
 for voice in host.journey.voices:voice.stop()
 host.queue_free();await create_timer(.2).timeout;print("V72 stability: ",failures," failures");quit(1 if failures else 0)
