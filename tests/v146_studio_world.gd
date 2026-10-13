extends SceneTree
const W=preload("res://scripts/studio_world_project.gd")
const P=preload("res://scripts/workshop_project.gd")
const L=preload("res://scripts/studio_library.gd")
const S=preload("res://scripts/learning_store.gd")
var checks=0
var failures=0
func check(ok:bool,message:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 for name in W.OBJECTS:check(W.validate_object(W.object(name)).is_empty(),"premade portable object "+name)
 for index in 5:
  var r=W.example(index);check(W.validate_realm(r).is_empty(),"example realm valid "+str(index));check(W.checks(r).is_empty(),"example route connected "+str(index))
 var r=W.realm();r.grid[1*int(r.width)+1]=4;check(not W.checks(r).is_empty(),"blocked spawn rejected");r=W.realm()
 for y in r.height:r.grid[y*int(r.width)+12]=4
 check(not W.checks(r).is_empty(),"disconnected route rejected")
 var bad=r.duplicate(true);bad.grid[0]=999;check(not W.validate_realm(bad).is_empty(),"unknown tile import rejected");bad=r.duplicate(true);bad.width=W.MAX_SIDE+1;check(not W.validate_realm(bad).is_empty(),"oversized grid import rejected")
 r=W.realm();r.tiles[2].block_shots=false;r.grid[int(r.width)+6]=2
 check(W.blocked(r,Vector2(260,60)) and not W.blocked(r,Vector2(260,60),true),"movement / projectile collision separated")
 var prop=W.object("Tower");prop.block_move=true;prop.block_shots=true;r.objects[prop.id]=prop;r.placements=[{"kind":"object","id":prop.id,"cell":[4,4]}]
 check(W.blocked(r,Vector2(180,180)) and W.blocked(r,Vector2(180,180),true),"object footprint collision")
 check(L.add_world("object",prop).is_empty() and L.add_world("realm",r).is_empty(),"local object / realm finalization")
 check(L.load_data().objects.has(prop.id) and L.load_data().realms.has(r.id),"new projects immediately available locally")
 var hero=P.fresh();hero.hero.art.idle=W.art("Bookshelf");hero.hero.alternate_forms={"open":{"name":"Open book","image":W.art("Bookshelf")}};hero.hero.secondary.form_id="open";hero.hero.secondary.form_duration=2
 check(P.validate(hero).is_empty(),"alternate-form portable hero validates");bad=hero.duplicate(true);bad.hero.secondary.form_id="missing";check(not P.validate(bad).is_empty(),"dangling alternate form rejected")
 var arena=load("res://scripts/workshop_arena.gd").new();root.add_child(arena);arena.begin(hero,[],"Cluster");arena.cast("secondary");check(arena.active_form=="open" and arena.form_texture()!=null,"casting switches custom artwork");arena.tick(2.1);check(arena.active_form.is_empty(),"alternate form returns to default on expiry");arena.queue_free()
 var modules=S.catalog()
 for code in ["DES2035","COM2035","COM3035"]:check(modules.has(code) and not modules[code].draft,"curriculum module "+code)
 var d=S.fresh();d.enabled=true;var a={"kind":"hero","value":hero,"title":"Hero","time":S.stamp(),"origin":"Test","hash":S.fingerprint(hero)};d.artifacts[a.hash]=a;var work={"entries":[],"refs":[a.hash]};d.work.DES1030=work
 check(S.valid(d),"portfolio supports practical hero artifact");check(S.readiness(d,"DES1030",work)["2"].ready,"tool-use outcome needs artwork, no essay")
 work.refs=[];check(not S.readiness(d,"DES1030",work)["2"].ready,"tool-use outcome still requires actual artwork")
 a={"kind":"object","value":prop,"title":"Tower","time":S.stamp(),"origin":"Test","hash":S.fingerprint(prop)};d.artifacts[a.hash]=a;check(S.valid_artifact(a),"object evidence frozen and validated")
 a={"kind":"realm","value":r,"title":"Realm","time":S.stamp(),"origin":"Test","hash":S.fingerprint(r)};d.artifacts[a.hash]=a;check(S.valid_artifact(a),"realm evidence frozen and validated")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 8:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume();g.menu="";g.hero_workshop.open();g.hero_workshop.project=hero
 for is_realm in [false,true]:
  var page=load("res://scripts/studio_world_lab.gd").new();g.hero_workshop.add_child(page);page.setup(g.hero_workshop,is_realm)
  for n in 4:await process_frame
  check(root.get_visible_rect().encloses(page.panel.get_global_rect()),"new lab fits viewport "+str(is_realm))
  root.size=Vector2i(896,414)
  for n in 8:await process_frame
  check(root.get_visible_rect().encloses(page.panel.get_global_rect()),"new lab fits phone landscape "+str(is_realm))
  root.size=Vector2i(1280,720)
  for n in 8:await process_frame
  page.finalize()
  if is_realm:
   check(is_instance_valid(page.test_layer),"finalize realm starts live test")
   root.size=Vector2i(896,414)
   for n in 4:await process_frame
   check(root.get_visible_rect().encloses(page.test_arena.get_global_rect()),"full realm playtest fits phone landscape")
   root.size=Vector2i(1280,720);page.test_layer.queue_free()
  else:check(page.finalized,"object finalizes to library")
  page.queue_free();await process_frame
 var page=load("res://scripts/studio_world_lab.gd").new();g.hero_workshop.add_child(page);page.setup(g.hero_workshop,true);var enemy=page.basic_enemy("bramble")
 check(preload("res://scripts/studio_enemy_project.gd").validate(enemy).is_empty(),"Grove preset imports as battle enemy")
 r=JSON.parse_string(JSON.stringify(W.realm()));r.enemies[enemy.id]=enemy;r.placements=[{"kind":"enemy","id":enemy.id,"cell":[7,7]}];var test=load("res://scripts/studio_realm_test.gd").new();root.add_child(test);test.setup(r,hero);check(test.actors.size()==1,"placed enemy has live decision / attack runtime")
 for n in 20:test.tick(.02)
 check(test.time>0 and test.health>0,"realm test advances without profile progress")
 var summoned={"pos":test.player+Vector2(40,0),"hp":40.0,"max_hp":40.0,"life":4.0,"timer":2.0,"ability":preload("res://scripts/workshop_project.gd").attack("summon")};test.actors[0].runtime.minions.append(summoned);test.tick(.02)
 check(test.foes.has(summoned),"enemy summons are attackable realm targets")
 var hit=preload("res://scripts/workshop_project.gd").attack("melee");hit.damage=50;test.hurt(test.foes.find(summoned),hit)
 check(summoned.hp<=0,"realm summon can be defeated")
 test.queue_free();page.queue_free()
 var editor=load("res://scripts/studio_raster_editor.gd").new();g.hero_workshop.add_child(editor);editor.setup(g.hero_workshop,prop)
 editor.canvas.selection=Rect2i(4,4,8,8);editor.effect("Gradient");editor.effect("Mask");check(editor.value.layers[0].has("mask") and editor.canvas.mask_image!=null,"non-destructive alpha mask retains source layer");check("Gradient" in editor.value.operations and "Mask" in editor.value.operations,"raster source records real edits");editor.finish();check(W.validate_object(editor.value).is_empty(),"raster layers / export portable validation")
 var pack=S.fresh();pack.enabled=true;var pack_work={"entries":[],"refs":[]}
 for n in 4:
  var obj=W.object("Pack "+str(n));obj.layers=[{"name":"Base","image":obj.image,"visible":true},{"name":"Light","image":obj.image,"visible":true}];obj.settings.filename="pack-"+str(n)+".png";obj.settings.dimensions=[32,40];obj.operations=["Tool: Select","Gradient","Mask","Create custom brush","Stamp custom brush","Tone"]
  var item={"kind":"object","value":obj,"title":obj.name,"time":S.stamp(),"origin":"Test","hash":S.fingerprint(obj),"order":n+2};pack.artifacts[item.hash]=item;pack_work.refs.append(item.hash)
  if n==0:
   var prior=obj.duplicate(true);prior.operations=[];var old_item=item.duplicate(true);old_item.value=prior;old_item.hash=S.fingerprint(prior);pack.artifacts[old_item.hash]=old_item;pack_work.refs.append(old_item.hash)
 check(S.practical_evidence(pack,pack_work,"raster_pack"),"Raster 1 uses three original layered props and practical tool evidence")
 check(S.practical_evidence(pack,pack_work,"advanced_raster_pack"),"Raster 2 uses four props, brush, correction and before/after snapshots")
 var realm_item={"kind":"realm","value":r,"title":"Realm","time":S.stamp(),"origin":"Test","hash":S.fingerprint(r),"order":9};pack.artifacts[realm_item.hash]=realm_item;pack_work.refs.append(realm_item.hash)
 pack_work.entries=[{"stage":"vision","text":"Mood and routes first","time":S.stamp(),"order":1}]
 check(S.readiness(pack,"DES2035",pack_work)["1"].ready,"realm vision recorded before prop and map production")
 pack_work.entries[0].order=10;check(not S.readiness(pack,"DES2035",pack_work)["1"].ready,"late vision remains flagged for teacher review")
 var bundle=g.legacy.bundle();check(g.legacy.validate(bundle),"extended library valid in full player profile")
 var zip="user://v146-profile.zip";check(preload("res://scripts/studio_bundle.gd").make(bundle,zip)==OK,"profile ZIP includes world projects")
 var read=preload("res://scripts/studio_bundle.gd").read(zip);check(read.error.is_empty() and read.payload.studio.objects.size()>0 and read.payload.studio.realms.size()>0,"ZIP restores objects / realms without manual re-import")
 print("V146 ",checks," checks / ",failures," failures");quit(1 if failures else 0)
