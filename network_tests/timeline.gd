extends SceneTree
var failures=0
func check(ok:bool,note:String)->void:
 if not ok:failures+=1;push_error(note)
func _initialize()->void:
 var Motion=preload("res://network/motion_view.gd")
 var Shots=preload("res://network/projectile_view.gd")
 # Two views of a close chase: both clients predict their own position now.
 # Snapshots are 150ms behind those inputs. The leader is only 20px ahead;
 # the previous 75ms remote delay could reverse the visible chase order.
 var a=Motion.new();var b=Motion.new();var speed=245.0;var ahead=.15
 for tick in 12:
  var now=tick*.05;var server_x=600+speed*now
  a.receive("leader",Vector2(server_x+20,500),Vector2(speed,0),now,ahead)
  b.receive("follower",Vector2(server_x,500),Vector2(speed,0),now,ahead)
  for frame in 3:
   var elapsed=frame/60.0;var own=server_x+speed*(ahead+elapsed)
   check(absf(a.sample("leader",Vector2.ZERO,now+elapsed).x-own-20)<.01,"Follower sees leader ahead")
   check(absf(own+20-b.sample("follower",Vector2.ZERO,now+elapsed).x-20)<.01,"Leader sees follower behind")
 # Projectiles and actors with equal velocity share the same presentation lead.
 var shots=Shots.new();shots.presentation_ahead=ahead
 shots.receive([{"net_id":1,"owner":"remote","pos":[620,500],"velocity":[speed,0]}],0)
 var actor=Motion.new();actor.receive("remote",Vector2(600,500),Vector2(speed,0),0,ahead)
 check(absf(shots.samples(.03)[0].pos.x-actor.sample("remote",Vector2.ZERO,.03).x-20)<.01,"Remote projectile and actor use identical clock")
 # Delayed confirmations over repeated snapshots must not reverse a projectile.
 var local=Shots.new();local.local_owner="a";local.presentation_ahead=.15
 local.preview("a",3,Vector2(600,500),Vector2(480,0),"#ffffff",0)
 local.receive([{"net_id":2,"owner":"a","action_seq":3,"pos":[610,500],"velocity":[480,0]}],.25)
 var previous=local.samples(.25)[0].pos.x
 for frame in range(1,31):
  var now=.25+frame/60.0
  if frame%3==0:local.receive([{"net_id":2,"owner":"a","action_seq":3,"pos":[610+480*(now-.25),500],"velocity":[480,0]}],now)
  var point=local.samples(now)[0].pos.x
  check(point>=previous-.001,"Confirmed projectile cannot step backward")
  previous=point
 actor.receive("remote",Vector2(640,500),Vector2.ZERO,.1,ahead)
 check(actor.sample("remote",Vector2.ZERO,.2).distance_to(Vector2(640,500))<.01,"Stopped actor settles at authority position")
 actor.receive("remote",Vector2(1600,500),Vector2.ZERO,.3,ahead)
 check(actor.sample("remote",Vector2.ZERO,.3)==Vector2(1600,500),"Teleport does not slide across map")
 var held=actor.sample("remote",Vector2.ZERO,1)
 check(held==actor.sample("remote",Vector2.ZERO,5),"Stale connection stops extrapolating")
 print("TIMELINE CHECKS ",failures," failures");quit(failures)
