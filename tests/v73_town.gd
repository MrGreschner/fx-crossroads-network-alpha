extends SceneTree
var failures:=0
func check(ok:bool,text:String)->void:
 if not ok:failures+=1;print("FAIL ",text)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 check(game.region_size()==Vector2(2700,1900),"expanded town bounds")
 for place in game.town_places:
  check(game.can_stand_at(place.pos),"walkable interaction "+str(place.menu))
 for id in game.legacy.PROJECTS:game.legacy.data.town[id]=true
 # Flood the actual collision map, including completed project buildings.
 var seen:Dictionary={};var queue:Array[Vector2i]=[Vector2i(22,16)];seen[queue[0]]=true
 var head:int=0
 while head<queue.size():
  var cell:Vector2i=queue[head];head+=1
  for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
   var next:Vector2i=cell+offset
   if next.x<1 or next.y<1 or next.x>66 or next.y>46 or seen.has(next):continue
   if game.can_stand_at(Vector2(next)*40):seen[next]=true;queue.append(next)
 for place in game.town_places:
  var reachable:=false
  for cell in seen:
   if (Vector2(cell)*40).distance_to(place.pos)<60:reachable=true;break
  check(reachable,"connected approach "+str(place.menu))
 check(game.can_stand_at(game.town_polish.DOOR),"chimehouse entrance")
 check(not game.can_stand_at(Vector2(2450,450)),"chimehouse solid building")
 for id in ["fellowship","relay"]:game.legacy.data.town[id]=true
 var pavilion:Rect2=game.legacy.card_building_rect("fellowship")
 check(not pavilion.intersects(Rect2(1450,850,200,180)),"pavilion separated from training")
 check(not game.legacy.card_building_rect("relay").intersects(Rect2(325,980,250,240)),"workshop separated from arena")
 game.town_polish.open(game);await process_frame
 for n in 5:
  game.town_polish.phase=.5;game.town_polish.strike();game.town_polish.next_pattern()
 check(game.town_polish.hits==5 and not game.town_polish.playing and game.town_polish.attempts==5,"five bell end")
 game.menu="";game.town_polish.step(.1);await process_frame;check(not is_instance_valid(game.town_polish.panel),"close cleanup")
 print("v73 town failures: ",failures);game.queue_free();await process_frame;quit(failures)
