extends SceneTree
var failures=0
func check(ok:bool,note:String)->void:
 if not ok:failures+=1;push_error(note)
func packet(tick:int,x:float,shots:Array=[])->Dictionary:return {"server_tick":tick,"players":{"a":{"pos":[x,500]}},"render_shots":shots}
func _initialize()->void:
 var World=preload("res://network/world_view.gd")
 var w=World.new()
 # Uneven arrivals do not reset the playback clock or predict a remote turn.
 w.receive(packet(0,0));w.receive(packet(3,12));w.receive(packet(6,24))
 w.render_time=.025
 check(absf(w.player("a",Vector2.ZERO).x-6)<.001,"Position interpolates on server ticks")
 w.receive(packet(9,12));w.render_time=.125
 check(absf(w.player("a",Vector2.ZERO).x-18)<.001,"Reversal follows actual endpoints without overshoot")
 var before=w.render_time;w.advance(.0167)
 check(w.render_time>=before and w.render_time<=w.latest_time,"Clock is monotonic and bounded")
 w.receive(packet(6,-1000));check(w.last_tick==9,"Stale snapshot cannot move world backward")
 # A new seed is visible at its launch, before the next packet's advanced position.
 var seed={"net_id":1,"owner":"remote","pos":[650,500],"velocity":[480,0],"born":.1,"custom":true,"art":{"style":"pellet","radius":12,"stats":{}}}
 var v=World.new();v.receive(packet(6,600));v.receive(packet(9,610,[seed]));v.render_time=.1
 check(v.shots().size()==1 and absf(v.shots()[0].draw_pos.x-626)<.001,"Remote seed reconstructs launch near caster")
 v.render_time=.09;check(v.shots().is_empty(),"Projectile cannot exist before launch")
 v.receive(packet(12,620,[]));v.render_time=.2;check(v.shots().is_empty(),"Projectile disappearance follows same clock")
 var now=v.render_time;v.advance(10);check(v.render_time<=v.latest_time,"Long stall holds last known world")
 print("BUFFERED WORLD ",failures," failures");quit(failures)
