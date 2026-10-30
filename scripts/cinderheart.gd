extends Node
## Authored castle, hazards and encounter progression shared by solo and authoritative co-op.
const TYPES=["cinder_page","crucible_scuttler","furnace_sentinel","ashglass_alchemist","coalwing_gargoyle","brandbound_chain","kiln_slug","cinderbell_wisp","gatebreaker_korr","glass_matron","pyrewing_bellkeeper","castellan_varr","calderax"]
var adventure:Node
var active=false
var data:Dictionary={}
var initialized=false
var stage=0
var boss_live=false
var reveal=0.0
var done=false
var claimed=false
var clock=0.0
var hazards:Array=[]
var last_heat:Dictionary={}
var safe_points:Dictionary={}
var last_points:Dictionary={}
var last_risk:Dictionary={}
var routes:Dictionary={}
var grid:AStarGrid2D
func v(p:Array)->Vector2:return Vector2(float(p[0]),float(p[1]))
func a(p:Vector2)->Array:return [p.x,p.y]
func rect(p:Array)->Rect2:return Rect2(p[0],p[1],p[2],p[3])
func definitions()->Dictionary:return adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
func setup(id:String)->void:
 active=id=="cinderheart";initialized=false;stage=0;boss_live=false;reveal=0;done=false;claimed=false;clock=0;data={};hazards.clear();routes.clear();last_heat.clear();safe_points.clear();last_points.clear();last_risk.clear();grid=null
 if not active:return
 data=JSON.parse_string(FileAccess.get_file_as_string("res://content/campaigns/cinderheart.json"))
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,141,97);grid.cell_size=Vector2(64,64);grid.offset=Vector2(32,32);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 preload("res://scripts/navigation_cache.gd").populate(grid,"cinderheart_v37",JSON.stringify(data),func(point):return not floor_at(point) or danger(point)==1)
 for cell_x in grid.region.size.x:
  for cell_y in grid.region.size.y:
   var cell=Vector2i(cell_x,cell_y)
   if not grid.is_point_solid(cell):grid.set_point_weight_scale(cell,7 if danger(grid.get_point_position(cell))==2 else 2.5 if danger(grid.get_point_position(cell))==3 else 1)

func floor_at(point:Vector2)->bool:
 for solid in data.get("solids",[]):
  if rect(solid).grow(16).has_point(point):return false
 for room in data.get("rooms",[]):
  if rect(room.rect).grow(-16).has_point(point):return true
 return false
func can_stand(point:Vector2)->bool:
 if not floor_at(point):return false
 for gate in data.get("gates",[]):
  if stage<int(gate.opens) and rect(gate.rect).grow(12).has_point(point):return false
 return true
func danger(point:Vector2)->int:
 # 0 safe, 1 deep river/fall, 2 shallow burning pool, 3 radiant heat.
 for bridge in data.get("bridges",[]):
  if rect(bridge).has_point(point):return 0
 var heat=false
 for river in data.get("rivers",[]):
  if rect(river).has_point(point):return 1
  if rect(river).grow(85).has_point(point):heat=true
 for pool in data.get("pools",[]):
  if rect(pool).has_point(point):return 2
  if rect(pool).grow(85).has_point(point):heat=true
 return 3 if heat else 0
func advance(origin:Vector2,aim:Vector2,distance:float)->Vector2:
 var result=origin
 for n in maxi(1,ceili(distance/10)):
  var next=origin+aim.normalized()*minf(distance,(n+1)*10)
  if not can_stand(next) or danger(next)==1:break
  result=next
 return result
func spawn(kind:String,point:Vector2,sector:int,boss:bool=false,hp:float=-1)->Dictionary:
 adventure.spawn(kind,point,float(definitions()[kind].health) if hp<0 else hp,boss)
 var enemy:Dictionary=adventure.foes()[-1];enemy.cinder_sector=sector;enemy.cinder_timer=1.2;enemy.cinder_turn=0;enemy.cinder_pose=0.0;enemy.sprite=kind;enemy.hit_radius=76.0 if kind=="calderax" else 43.0 if boss else 24.0
 return enemy
func initialize()->void:
 if initialized:return
 initialized=true
 for entry in data.spawns:spawn(str(entry.type),v(entry.pos),int(entry.sector))
 adventure.announce("Cinderheart Citadel • Heat scorches nearby. Pools ignite. Deep rivers kill instantly: use the stone bridges.")
func remaining(sector:int)->int:
 var count=0
 for enemy in adventure.foes():
  if int(enemy.get("cinder_sector",-1))==sector and not bool(enemy.boss):count+=1
 return count
func spawn_boss()->void:
 if stage>=data.bodies.size() or boss_live or done:return
 var boss:Dictionary=data.bodies[stage];spawn(str(boss.type),v(boss.pos),stage,true,float(boss.hp));boss_live=true
 adventure.announce(str(boss.name)+(" • THE TRUE HEART AWAKENS" if stage==4 else " • WARDEN" if stage<3 else " • THE CASTELLAN"))
func on_defeat(enemy:Dictionary)->bool:
 if not active or str(enemy.get("type","")) not in TYPES:return false
 routes.erase(int(enemy.uid))
 for n in range(hazards.size()-1,-1,-1):
  if int(hazards[n].uid)==int(enemy.uid):hazards.remove_at(n)
 if not enemy.boss:return false
 if str(enemy.type)!=str(data.bodies[mini(stage,4)].type):return true
 boss_live=false;stage+=1
 if stage==4:
  reveal=4.5;hazards.clear();adventure.announce("CASTELLAN DEFEATED • The citadel is free… Why is the throne still beating?")
 elif stage>=5:
  done=true;hazards.clear()
  if not adventure.arcade:adventure.game.boss_spawned=true;adventure.game.boss_defeated=true
  adventure.announce("CALDERAX EXTINGUISHED • Cinderheart Citadel cleared. Use the cooled throne portal: E / Interact.")
 else:adventure.announce("Warden defeated • Castle seal %d / 3 broken. The next bridge is open." % stage)
 return true
func interact(id:String)->bool:
 if not active or not done or claimed or not adventure.alive(id):return false
 if (adventure.points()[id] as Vector2).distance_to(v(data.exit))>150:return false
 claimed=true
 if adventure.arcade:adventure.game.end_match("Cinderheart Citadel cleared • Calderax extinguished")
 else:adventure.game.finish_run(true)
 return true
func nearest(point:Vector2)->String:
 var chosen="";var distance=INF
 for id in adventure.points():
  if not adventure.alive(str(id)):continue
  var d=point.distance_to(adventure.points()[id])
  if d<distance:chosen=str(id);distance=d
 return chosen
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 var origin:Vector2=enemy.pos
 if adventure.combat.path_clear(origin,target):
  var clear=true
  for n in 12:
   if danger(origin.lerp(target,n/11.0))==1:clear=false
  if clear:return adventure.combat.ranged_direction(enemy,target) if ranged else (target-origin).normalized()
 var key=int(enemy.uid);var entry:Dictionary=routes.get(key,{})
 if clock>float(entry.get("until",0)):
  var start=Vector2i(floori(origin.x/64),floori(origin.y/64));var finish=Vector2i(floori(target.x/64),floori(target.y/64));var path=PackedVector2Array()
  if grid.is_in_boundsv(start) and grid.is_in_boundsv(finish) and not grid.is_point_solid(start) and not grid.is_point_solid(finish):path=grid.get_point_path(start,finish)
  entry={"path":path,"until":clock+.8};routes[key]=entry
 for waypoint in entry.get("path",[]):
  if origin.distance_to(waypoint)>32:return (waypoint-origin).normalized()
 return Vector2.ZERO
func hurt(id:String,amount:float,style:String,source:String="")->void:
 if not adventure.alive(id):return
 var cause=preload("res://scripts/defeat_credit.gd").hazard(style) if source.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(adventure.game,source,style)
 adventure.hit_player(id,amount,source,cause)
func river_fall(id:String)->void:
 if not adventure.alive(id):return
 var game=adventure.game;var cause=preload("res://scripts/defeat_credit.gd").hazard("Deep lava river • fatal fall")
 if not adventure.arcade:
  game.damage_taken+=maxf(0,game.health);game.health=0;game.last_defeat=cause;game.finish_run(false)
 else:
  game.health[id]=0;game.defeat_causes[id]=cause;game.respawn_at[id]=9223372036854775807
  # Co-op revives happen on the bank, never inside the fatal river.
  if safe_points.has(id):game.positions[id]=v(safe_points[id]);last_points[id]=safe_points[id]
  if game.positions.size()>1:game.downed[id]={"left":25.0,"progress":0.0,"rescuer":""}
  var living=false
  for player in game.health:
   if int(game.health[player])>0:living=true
  if not living:game.end_match("Party defeated • the lava claimed the expedition")
func environmental(delta:float)->void:
 for id in adventure.points():
  if not adventure.alive(str(id)):continue
  var point:Vector2=adventure.points()[id];var risk=danger(point);var last=v(last_points.get(id,a(point)));last_points[id]=a(point)
  # Sample the movement segment so a fast dash cannot tunnel across a river.
  var crossed=false;var span=point.distance_to(last)
  if span<1000:
   for n in maxi(1,ceili(span/18)):
    if danger(last.lerp(point,(n+1.0)/maxi(1,ceili(span/18))))==1:crossed=true;break
  if risk==1 or crossed:river_fall(str(id));continue
  if risk==0:safe_points[id]=a(point)
  if risk==2 and int(last_risk.get(id,0))!=2:adventure.combat.apply_status("p:"+str(id),"burn",4,"enemy",4,preload("res://scripts/defeat_credit.gd").hazard("Lava ignition"))
  last_risk[id]=risk
  if clock<float(last_heat.get(id,0)):continue
  last_heat[id]=clock+1.0
  if risk==2:
   hurt(str(id),7,"Shallow lava pool")
   if adventure.alive(str(id)):adventure.combat.apply_status("p:"+str(id),"burn",4,"enemy",4,preload("res://scripts/defeat_credit.gd").hazard("Lava ignition"))
  elif risk==3:hurt(str(id),4,"Radiant lava heat")
func hazard(enemy:Dictionary,point:Vector2,end:Vector2,style:String,radius:float,damage:float,warn:float,life:float=.32)->void:
 if hazards.size()>=64:return
 hazards.append({"uid":int(enemy.uid),"pos":a(point),"end":a(end),"style":style,"radius":radius,"damage":damage,"warn":warn,"total":warn,"life":life,"hits":[],"tick":0.0})
func bolts(enemy:Dictionary,target:Vector2,count:int=3,spread:float=.22)->void:
 var aim:Vector2=(target-enemy.pos).normalized()
 for n in count:
  adventure.combat.launch_projectile("enemy",enemy.pos+aim*32,aim.rotated((n-(count-1)*.5)*spread),{"name":"Citadel ember","range":720,"speed":285 if not enemy.boss else 310,"color":"#ff994d","projectile_radius":10,"burn_duration":2,"burn_damage":2,"cinder_visual":str(enemy.type),"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,"e:"+str(enemy.uid),"Cinder bolt")},12 if not enemy.boss else 17)
func skill(enemy:Dictionary,target:Vector2)->void:
 var kind=str(enemy.type);var origin:Vector2=enemy.pos;var aim=(target-origin).normalized();var turn=int(enemy.cinder_turn);enemy.cinder_turn=turn+1;enemy.cinder_pose=clock+.7
 match kind:
  "cinder_page":bolts(enemy,target,3,.30)
  "crucible_scuttler":hazard(enemy,origin,advance(origin,aim,330),"dash",31,17,.85,.65)
  "furnace_sentinel":hazard(enemy,origin,origin+aim*180,"cleave",64,21,.9)
  "ashglass_alchemist":hazard(enemy,target,target,"puddle",68,8,1.05,3.2)
  "coalwing_gargoyle":hazard(enemy,target,target,"meteor",83,22,1.15)
  "brandbound_chain":hazard(enemy,origin,origin+aim*430,"chain",19,14,.9)
  "kiln_slug":
   for n in 3:hazard(enemy,origin+aim.rotated((n-1)*.35)*120,origin,"puddle",48,6,.85+n*.15,2.1)
  "cinderbell_wisp":hazard(enemy,origin,origin,"ring",170,13,1.0)
  "gatebreaker_korr":
   if turn%2==0:hazard(enemy,origin,target,"quake",210,24,1.1)
   else:hazard(enemy,origin,advance(origin,aim,390),"dash",48,26,1.0,.7)
  "glass_matron":
   if turn%2==0:
    for n in 3:hazard(enemy,target+Vector2((n-1)*140,0),target,"meteor",65,21,1.05+n*.25)
   else:
    for offset in [Vector2(350,0),Vector2(0,350)]:hazard(enemy,origin-offset,origin+offset,"beam",23,23,1.15,.4)
  "pyrewing_bellkeeper":
   if turn%2==0:bolts(enemy,target,7,.24)
   else:hazard(enemy,origin,target,"ring",240,23,1.2)
  "castellan_varr":
   if turn%3==0:bolts(enemy,target,5,.21)
   else:hazard(enemy,origin,origin+aim*280,"cleave",90,28,.95)
  "calderax":
   var enraged=float(enemy.hp)<float(enemy.max_hp)*.5
   if turn%3==0:
    for n in (5 if enraged else 3):hazard(enemy,target+Vector2.from_angle(n*2.4)*float(n*62),target,"meteor",86,26,1.1+n*.18)
   elif turn%3==1:
    for angle in [-.60,.60]:hazard(enemy,origin,origin+aim.rotated(angle)*620,"beam",34,30,1.1,.5)
   else:hazard(enemy,origin,target,"ring",310,27,1.25)
func step_hazards(delta:float)->void:
 for n in range(hazards.size()-1,-1,-1):
  var h:Dictionary=hazards[n];h.warn-=delta
  if float(h.warn)>0:continue
  var origin=v(h.pos);var end=v(h.end);var style=str(h.style)
  if style=="dash":
   var foe:Dictionary={}
   for enemy in adventure.foes():
    if int(enemy.uid)==int(h.uid):foe=enemy;break
   if foe.is_empty():hazards.remove_at(n);continue
   origin=foe.pos;var move=advance(origin,end-origin,minf(origin.distance_to(end),520*delta));foe.pos=move;end=move
  h.tick-=delta
  for id in adventure.points():
   if not adventure.alive(str(id)) or (str(id) in h.hits and style!="puddle"):continue
   if style=="puddle" and float(h.tick)>0:continue
   var point:Vector2=adventure.points()[id];var diff=point-origin;var inside=diff.length()<=float(h.radius)
   if style in ["beam","chain","dash"]:inside=Geometry2D.get_closest_point_to_segment(point,origin,end).distance_to(point)<=float(h.radius)+14
   elif style=="cleave":inside=diff.length()<origin.distance_to(end) and (diff.length()<1 or diff.normalized().dot((end-origin).normalized())>.55)
   elif style=="ring":
    # Annular shockwave and a broad directional gap leave two clear dodges.
    var gap=(end-origin).normalized().rotated(PI/2);inside=diff.length()>float(h.radius)*.55 and diff.length()<float(h.radius) and (diff.length()<1 or diff.normalized().dot(gap)<.78)
   if inside and adventure.combat.path_clear(origin,point):
    h.hits.append(str(id));hurt(str(id),float(h.damage),"Citadel "+style,"e:"+str(h.uid))
    if not active:return
    if style=="chain" and adventure.alive(str(id)):adventure.combat.apply_status("p:"+str(id),"slow",2,"enemy",.55)
  if float(h.tick)<=0:h.tick=.8
  h.life-=delta
  if float(h.life)<=0:hazards.remove_at(n)
func step(delta:float)->void:
 if not active or not adventure.authoritative():return
 if not adventure.arcade and adventure.game.menu!="":return
 clock+=delta;initialize();environmental(delta)
 if not active or (not adventure.arcade and adventure.game.health<=0):return
 if adventure.arcade and not adventure.game.started:return
 if reveal>0:
  reveal=maxf(0,reveal-delta)
  if reveal<=0:spawn_boss()
 elif not done and not boss_live and remaining(mini(stage,3))==0:
  var close=false
  for id in adventure.points():
   if adventure.alive(str(id)) and (adventure.points()[id] as Vector2).distance_to(v(data.bodies[mini(stage,4)].pos))<850:close=true
  if close:spawn_boss()
 step_hazards(delta)
 for enemy in adventure.foes().duplicate():
  if str(enemy.type) not in TYPES or int(enemy.get("cinder_sector",0))>stage or bool(enemy.get("converted",false)):continue
  var id=nearest(enemy.pos)
  if id.is_empty():continue
  var target:Vector2=adventure.combat.fern.redirect(enemy,adventure.points()[id]);var distance:float=(enemy.pos as Vector2).distance_to(target)
  if distance>(1300 if enemy.boss else 760):continue
  if adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
  var busy=false
  for h in hazards:
   if int(h.uid)==int(enemy.uid) and float(h.warn)>0:busy=true;break
  if not busy:
   var ranged=str(enemy.type) in ["cinder_page","ashglass_alchemist","cinderbell_wisp","glass_matron","pyrewing_bellkeeper"]
   var heading=direction(enemy,target,ranged);var distance_step=float(definitions()[enemy.type].speed)*delta*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))
   enemy.pos=advance(enemy.pos,heading,distance_step)
  enemy.cinder_timer=float(enemy.get("cinder_timer",1))-delta
  if float(enemy.cinder_timer)<=0 and not busy and adventure.combat.path_clear(enemy.pos,target):
   enemy.cinder_timer=(1.65 if enemy.type=="calderax" and float(enemy.hp)<float(enemy.max_hp)*.5 else 2.5 if enemy.boss else 3.1)
   skill(enemy,target)
func objective()->String:
 if done:return "THE HEART IS COLD • E at the throne portal to claim your clear"
 if reveal>0:return "CASTELLAN DEFEATED… Something beneath the throne is waking"
 if stage<3:return "Seal %d / 3 • %d defenders remain • defeat %s" % [stage+1,remaining(stage),str(data.bodies[stage].name)]
 return "Defeat "+str(data.bodies[mini(stage,4)].name)
func snapshot()->Dictionary:return {"claimed":claimed,"initialized":initialized,"stage":stage,"boss_live":boss_live,"reveal":reveal,"done":done,"clock":clock,"hazards":hazards,"last_heat":last_heat,"safe_points":safe_points,"last_points":last_points}
func receive(p:Dictionary)->void:
 claimed=bool(p.get("claimed",false));initialized=bool(p.get("initialized",false));stage=int(p.get("stage",0));boss_live=bool(p.get("boss_live",false));reveal=float(p.get("reveal",0));done=bool(p.get("done",false));clock=float(p.get("clock",0));hazards=p.get("hazards",[]);last_heat=p.get("last_heat",{});safe_points=p.get("safe_points",{});last_points=p.get("last_points",{})
func body_size(kind:String)->Vector2:
 if kind=="calderax":return Vector2(220,224)
 if kind=="glass_matron":return Vector2(145,166)
 if kind in TYPES.slice(8):return Vector2(132,154)
 if kind=="kiln_slug":return Vector2(88,64)
 if kind=="brandbound_chain":return Vector2(73,90)
 return Vector2(66,78)
func draw_lava(c:Node2D,cam:Vector2,bounds:Rect2,deep:bool)->void:
 for halo in [85,55,25]:c.draw_rect(Rect2(bounds.position-cam-Vector2.ONE*halo,bounds.size+Vector2.ONE*halo*2),Color(1,.31,.07,.035))
 var screen=Rect2(bounds.position-cam,bounds.size)
 c.draw_rect(screen,Color('#512c38') if deep else Color('#af492f'));c.draw_rect(screen.grow(-8),Color('#e77630'));c.draw_rect(screen.grow(-18),Color('#f7a43e'))
 var clipped=bounds.intersection(Rect2(cam,c.VIEW).grow(50))
 for x in range(floori(clipped.position.x/46)*46,ceili(clipped.end.x),46):
  for y in range(floori(clipped.position.y/46)*46,ceili(clipped.end.y),46):
   var p=Vector2(x+23,y+23)
   if not bounds.grow(-24).has_point(p):continue
   var t=clock*1.6+x*.01+y*.02
   c.draw_arc(p-cam,10+sin(t)*3,.2,4.0,10,Color('#ffe49a',.6),2,true)
   if deep and (x/46+y/46)%3==0:c.draw_line(p-cam-Vector2(17,3),p-cam+Vector2(12,sin(t)*9),Color('#8e3d30'),7,true)
 c.draw_rect(screen,Color('#342d3a'),false,7)
 c.draw_string(ThemeDB.fallback_font,screen.position+Vector2(12,22),"DEEP LAVA • FATAL" if deep else "SHALLOW LAVA • BURNS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color('#ffe3a1'))
func draw_world(c:Node2D,cam:Vector2)->void:
 if not active:return
 var view=Rect2(cam,c.VIEW).grow(180)
 c.draw_rect(Rect2(-cam,v(data.size)),Color('#1d1a29'))
 for room in data.rooms:
  var box=rect(room.rect)
  if not view.intersects(box):continue
  c.draw_rect(Rect2(box.position-cam-Vector2(14,14),box.size+Vector2(28,28)),Color('#79616a'))
  c.draw_rect(Rect2(box.position-cam,box.size),Color('#3d3546'))
  var clip=box.intersection(view)
  for x in range(floori(clip.position.x/80)*80,ceili(clip.end.x),80):
   for y in range(floori(clip.position.y/80)*80,ceili(clip.end.y),80):
    var tile=box.intersection(Rect2(x,y,78,78));c.draw_rect(Rect2(tile.position-cam,tile.size),Color('#4b414e') if (x/80+y/80)%2 else Color('#514450'))
    if (x/80*3+y/80)%11==0:c.draw_line(Vector2(x+17,y+15)-cam,Vector2(x+52,y+56)-cam,Color('#69525a'),2)
  c.draw_rect(Rect2(box.position-cam+Vector2(20,20),box.size-Vector2(40,40)),Color('#88665b'),false,3)
  if box.size.x>1000:
   c.draw_string(ThemeDB.fallback_font,box.position+Vector2(80,62)-cam,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color('#d8b789'))
   for x in range(int(box.position.x)+80,int(box.end.x)-40,240):
    var q=Vector2(x,box.position.y+18)-cam
    c.draw_rect(Rect2(q-Vector2(22,12),Vector2(44,58)),Color('#292737'));c.draw_rect(Rect2(q-Vector2(17,7),Vector2(34,40)),Color('#96777b'))
    c.draw_circle(q+Vector2(0,22),7,Color('#f6ad55'));c.draw_circle(q+Vector2(0,22),22,Color(1,.6,.2,.08))
 for pool in data.pools:
  if view.intersects(rect(pool).grow(90)):draw_lava(c,cam,rect(pool),false)
 for river in data.rivers:
  if view.intersects(rect(river).grow(90)):draw_lava(c,cam,rect(river),true)
 for bridge in data.bridges:
  var box=rect(bridge)
  if not view.intersects(box):continue
  c.draw_rect(Rect2(box.position-cam,box.size),Color('#8f7a77'));c.draw_rect(Rect2(box.position-cam+Vector2(9,9),box.size-Vector2(18,18)),Color('#58515e'))
  for x in range(int(box.position.x)+18,int(box.end.x),40):c.draw_line(Vector2(x,box.position.y+14)-cam,Vector2(x,box.end.y-14)-cam,Color('#9d8780'),2)
  c.draw_rect(Rect2(box.position-cam,box.size),Color('#d0ab80'),false,5)
 for fall in data.falls:
  var box=rect(fall)
  if not view.intersects(box):continue
  c.draw_rect(Rect2(box.position-cam,box.size),Color('#a94c35'))
  for j in 7:
   var x=box.position.x+8+j*(box.size.x-16)/7;var y=box.position.y+fposmod(clock*125+j*37,box.size.y)
   c.draw_line(Vector2(x,box.position.y)-cam,Vector2(x,box.end.y)-cam,Color('#ec843c'),5)
   c.draw_line(Vector2(x,y)-cam,Vector2(x,minf(y+34,box.end.y))-cam,Color('#ffcf73'),4)
  c.draw_arc(box.get_center()+Vector2(0,box.size.y*.5)-cam,box.size.x*.55,PI,TAU,22,Color('#ffb25f'),5)
 for solid in data.get("solids",[]):
  var box=rect(solid)
  if not view.intersects(box):continue
  c.draw_rect(Rect2(box.position-cam+Vector2(5,10),box.size),Color('#272633'));c.draw_rect(Rect2(box.position-cam,box.size),Color('#846b69'));c.draw_rect(Rect2(box.position-cam,box.size),Color('#b79b80'),false,4)
  for j in 5:
   var q=box.position+Vector2(27+j*55,box.size.y*.5)-cam
   c.draw_line(q-Vector2(0,18),q+Vector2(0,13),Color('#bcb5ab'),5);c.draw_circle(q+Vector2(0,13),10,Color('#9bb5af'));c.draw_circle(q+Vector2(0,15),7,Color('#d99158') if j%2 else Color('#b5a17b'))
 for gate in data.gates:
  if stage>=int(gate.opens):continue
  var box=rect(gate.rect);var q=box.get_center()-cam
  c.draw_rect(Rect2(box.position-cam,box.size),Color('#614b55'));c.draw_rect(Rect2(box.position-cam,box.size),Color('#d79c63'),false,4)
  c.draw_circle(q,34,Color('#352e40'));c.draw_arc(q,27,0,TAU,24,Color('#e6ac62'),3);c.draw_string(ThemeDB.fallback_font,q+Vector2(-8,8),str(int(gate.opens)),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color('#ffd185'))
 # The ornate throne conceals the living caldera until the false victory.
 var throne=Vector2(7240,2540)-cam
 c.draw_rect(Rect2(throne-Vector2(130,190),Vector2(260,225)),Color('#6f535e'));c.draw_rect(Rect2(throne-Vector2(100,150),Vector2(200,130)),Color('#342d40'));c.draw_arc(throne-Vector2(0,80),92,PI,TAU,32,Color('#b89577'),12)
 if reveal>0:
  c.draw_circle(throne,80+(4.5-reveal)*35,Color(1,.45,.1,.12));c.draw_arc(throne,80+(4.5-reveal)*35,0,TAU,48,Color('#f6bb6d'),5)
 if done:
  var p=v(data.exit)-cam;preload("res://scripts/realm_portals258.gd").draw_at(c,adventure.game,v(data.exit),cam);c.draw_string(ThemeDB.fallback_font,p+Vector2(-85,76),"COOLED THRONE • E",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color('#b9eee7'))
func guidance(c:Node2D,cam:Vector2)->void:
 var id:String=str(adventure.game.my_id) if adventure.arcade else "solo"
 if not adventure.points().has(id) or not adventure.alive(id):return
 var origin:Vector2=adventure.points()[id];var target=v(data.exit) if done else v(data.bodies[mini(stage,4)].pos);var text="Return portal" if done else str(data.bodies[mini(stage,4)].name)
 var nearest_distance=INF
 if not boss_live and remaining(mini(stage,3))>0:
  for enemy in adventure.foes():
   if int(enemy.get("cinder_sector",-1))!=mini(stage,3) or bool(enemy.boss):continue
   var distance:float=origin.distance_squared_to(enemy.pos)
   if distance<nearest_distance:target=enemy.pos;nearest_distance=distance;text="Remaining defender"
 var entry:Dictionary=routes.get("guide",{})
 if clock>float(entry.get("until",-1)) or target.distance_to(v(entry.get("target",[0,0])))>140:
  var from=Vector2i(floori(origin.x/64),floori(origin.y/64));var to=Vector2i(floori(target.x/64),floori(target.y/64));var path=PackedVector2Array()
  if grid!=null and grid.is_in_boundsv(from) and grid.is_in_boundsv(to) and not grid.is_point_solid(from) and not grid.is_point_solid(to):path=grid.get_point_path(from,to)
  entry={"until":clock+.8,"path":path,"target":a(target)};routes["guide"]=entry
 var path:PackedVector2Array=entry.get("path",PackedVector2Array());var count=0
 for at in path:
  if origin.distance_to(at)<90:continue
  if origin.distance_to(at)>650 or count>=5:break
  if count%2==0:
   var direction=(at-origin).normalized();var side=direction.orthogonal();var point=at-cam
   c.draw_polyline(PackedVector2Array([point-direction*11+side*8,point+direction*4,point-direction*11-side*8]),Color("#f6d98c"),3,true)
  count+=1
 var direction=(target-origin).normalized();var at=origin-cam+direction*86
 c.draw_colored_polygon(PackedVector2Array([at+direction*13,at-direction*8+direction.orthogonal()*7,at-direction*8-direction.orthogonal()*7]),Color("#f6d98c"))
 c.draw_string(ThemeDB.fallback_font,origin-cam+Vector2(-145,66),text+" • "+str(int(origin.distance_to(target)))+" away",HORIZONTAL_ALIGNMENT_CENTER,290,14,Color("#f5dfaa"))
func draw_on(c:Node2D,cam:Vector2)->void:
 if active:guidance(c,cam)
 if not active:return
 var view=Rect2(cam,c.VIEW).grow(200)
 for h in hazards:
  var point=v(h.pos)-cam;var end=v(h.end)-cam;var warn=float(h.warn)>0;var style=str(h.style);var radius=float(h.radius)
  if not view.has_point(v(h.pos)) and not view.has_point(v(h.end)):continue
  if warn:
   if style in ["beam","chain","dash"]:preload("res://scripts/combat_cues.gd").corridor(c,point,end,radius)
   else:preload("res://scripts/combat_cues.gd").danger(c,point,radius if style!="cleave" else point.distance_to(end),float(h.warn),float(h.total))
   continue
  if style in ["beam","chain","dash"]:
   c.draw_line(point,end,Color(1,.46,.14,.25),radius*2,true);c.draw_line(point,end,Color('#ffcf76'),6,true)
   if style=="chain":
    for n in 12:c.draw_arc(point.lerp(end,n/11.0),7,0,TAU,8,Color('#e9bf8a'),3,true)
  elif style=="cleave":
   var angle=(end-point).angle();c.draw_arc(point,point.distance_to(end)*.8,angle-1,angle+1,28,Color('#ffd18c'),12,true)
  elif style=="ring":
   var angle=(end-point).angle()+PI/2;c.draw_arc(point,radius*.78,angle+.7,angle+TAU-.7,40,Color('#ffd077'),9,true)
  else:
   c.draw_circle(point,radius,Color(1,.4,.06,.25));c.draw_arc(point,radius,0,TAU,32,Color('#ffb45d'),5,true)
   for n in 7:
    var q=point+Vector2.from_angle(n*2.4)*radius*.55;c.draw_line(q+Vector2(0,12),q-Vector2(0,15+sin(clock*9+n)*7),Color('#ffda81'),5,true)
func draw_hud(c:Node2D)->void:
 if not active:return
 var top=preload("res://scripts/hud_layout.gd").objective_top(c,adventure.arcade);var width=minf(940,c.VIEW.x-48)
 c.draw_rect(Rect2(24,top,width,63),Color(.12,.08,.13,.94))
 c.draw_string(ThemeDB.fallback_font,Vector2(36,top+23),objective(),HORIZONTAL_ALIGNMENT_LEFT,width-24,16,Color('#f0d294'))
 c.draw_string(ThemeDB.fallback_font,Vector2(36,top+46),"HEAT: damage nearby • POOLS: burn • DEEP RIVERS: fatal • Stone bridges are safe",HORIZONTAL_ALIGNMENT_LEFT,width-24,13,Color('#dcae91'))
