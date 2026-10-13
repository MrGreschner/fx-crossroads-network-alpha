extends SceneTree
const S=preload("res://scripts/learning_store.gd")
const E=preload("res://scripts/teacher_examples.gd")
const B=preload("res://scripts/education_business.gd")
const R=preload("res://scripts/rolling_crowns.gd")
var failures=0
func check(ok:bool,t:String)->void:
 print("PASS • " if ok else "FAIL • ",t)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 for level in 3:
  var d=E.portfolio(level)
  check(S.valid(d),"example "+str(level)+" validates as portable evidence")
  check(d.submissions.size()==2 and d.work.size()==4,"two submitted and two partial modules")
  check(d.work.CSE1110.entries.size()==1 and d.work.MAM1010.entries.size()==2,"partial examples retain the remaining short responses; production essays hidden")
  check(d.submissions[0].marks["1"].score==[35,70,92][level],"three distinct illustrative grading levels")
  var quiz=d.artifacts[d.work.COM1145.refs.back()].value
  check(preload("res://scripts/learning_auto.gd").quiz_score(quiz)==[0,3,4][level],"concept answer levels differ")
  var hero=d.artifacts[d.work.DES1020.refs[0]].value
  check(hero.hero.art.walk1==hero.hero.art.walk2 if level==0 else hero.hero.art.walk1!=hero.hero.art.walk2,"motion quality differs by example")
  var wire=JSON.parse_string(JSON.stringify(d));check(S.valid(wire),"example evidence round-trips JSON")
  var ready=S.readiness(d,"COM1145",d.work.COM1145);check(not ready["2"].ready if level==0 else ready["2"].ready,"presence check catches failed animation but is not a grade")
 check(not FileAccess.file_exists(S.PATH),"sample generation does not create student files")
 for code in B.MODULES:
  var value=B.fresh(code);B.run(value)
  check(B.valid(value),code+" exercise validates")
  var imported=JSON.parse_string(JSON.stringify(value));check(B.valid(imported),code+" result recomputes after JSON import")
  imported.results["invented"]=999;check(not B.valid(imported),"forged report rejected")
 var pilot=B.fresh("ENT1020");B.run(pilot);var normal=pilot.results.duplicate();pilot.settings.scenario=1;B.run(pilot);check(pilot.results.profit<normal.profit,"supplier cost shock reduces pilot profit")
 pilot.settings.scenario=2;B.run(pilot);check(pilot.results.sold<normal.sold,"demand shock changes sales")
 pilot.settings.cash=10;B.run(pilot);check(pilot.results.stocked==0 and not pilot.results.funded,"cash shortage prevents free stock")
 var ab=B.fresh("MAM1010");ab.settings.a=12;ab.settings.b=12;B.run(ab);check(ab.results.a==ab.results.b,"identical A/B decisions have identical outcomes")
 ab.settings.b=10;B.run(ab);check(ab.results.a.sold!=ab.results.b.sold and ab.results.a.price==12 and ab.results.b.price==10,"one-factor experiment isolates price")
 ab.settings.stock=1;B.run(ab);check(ab.results.a.stock_limited and ab.results.b.stock_limited,"stock limitation disclosed")
 var bad=B.fresh("MAM1010");bad.settings.factor=1;bad.settings.a=12;check(not B.valid(bad),"non-price choices bounded")
 for i in 8:check(R.tier_from(R.GOALS[i])==i+1,"crown tier "+str(i+1)+" threshold")
 check(R.tier_from(0)==0 and R.tier_from(999)==0,"no crown below first threshold")
 check(R.remote_tier({"crown_tier":8,"crown_damage":10})==0,"lobby recomputes reported crown tier")
 check(R.remote_tier({"crown_damage":INF})==0 and not R.valid({"version":1,"buckets":[[1,NAN]]}),"invalid crown numbers rejected")
 check(not R.valid({"version":1,"buckets":[[2,10],[1,20]]}) and not R.valid({"version":1,"buckets":[[1,10],[1,20]]}),"unordered or duplicate minute buckets rejected")
 check(not FileAccess.file_exists("user://fx_teacher_classes.json"),"examples never enter saved classes")
 print("V142 LEARNING COMPLETE • failures=",failures);quit(failures)
