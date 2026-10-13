extends SceneTree
const Mine=preload("res://scripts/idle_mine.gd")
const Forge=preload("res://scripts/mine_foundry.gd")
const Market=preload("res://scripts/commerce.gd")
var failures=0
var checks=0
class Owner extends Node:
 var data={"teacher":false}
 var mine:RefCounted
 func save()->void:pass
func check(ok:bool,note:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",note)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var o=Owner.new();root.add_child(o);o.mine=Mine.new();var m=o.mine;m.time_for_test=1000000;m.setup(o)
 check(Mine.valid(m.state()),"new foundry state validates")
 var old=m.state().duplicate(true);old.erase("foundry");check(Mine.valid(old),"pre-foundry mine profile stays valid")
 o.data.mine=old;m.setup(o);check(m.state().has("foundry"),"old mine gains foundry without reset")
 m.commission();m.state().levels.depot=25
 m.time_for_test+=60;m.advance();check(Forge.state(m).lifetime.copper==0,"locked metal produces nothing")
 m.state().shafts.append({"depth":2,"crew":1});m.state().levels.smelter=1;m.state().last=m.now()
 var flow=m.rates().flow;m.time_for_test+=60;m.advance()
 check(is_equal_approx(float(Forge.state(m).stored.copper),60*flow*.12),"copper starts at shaft two with flow-limited production")
 check(Forge.state(m).stored.iron==0,"iron still locked before shaft four")
 m.collect();check(Forge.state(m).stored.copper==0 and Forge.state(m).wallet.copper>0,"depot transfers metal once")
 var f=Forge.state(m);f.wallet.copper=60;var geology=preload("res://scripts/mine_geology.gd").state(m);geology.wallet.coal=20
 check(Forge.forge(m,"copper",5),"batch consumes copper and coal")
 check(f.wallet.copper==30 and geology.wallet.coal==15,"recipe costs exact")
 check(not Forge.forge(m,"copper",1) and not m.refine(),"one furnace cannot run overlapping orders")
 var copied=JSON.parse_string(JSON.stringify(m.state()));check(Mine.valid(copied),"active furnace survives JSON profile validation")
 var finish=f.job.end;m.time_for_test=finish;m.advance();check(f.bars.copper==5 and f.forged.copper==5 and f.job.is_empty(),"offline furnace completion grants exact bars")
 m.advance();check(f.bars.copper==5,"furnace cannot pay twice")
 check(Forge.forge(m,"copper",1) and Forge.cancel_forge(m),"unfinished batch can be cancelled")
 check(f.wallet.copper==30 and geology.wallet.coal==15,"cancel refunds only consumed inputs")
 check(not Forge.cancel_forge(m),"cannot duplicate batch refund")
 check(not Forge.forge(m,"starsteel",1) and not Forge.forge(m,"copper",11),"depth and batch cap enforced")
 m.state().shafts.append({"depth":3,"crew":1});m.state().shafts.append({"depth":4,"crew":1});m.state().levels.vent=10;m.state().levels.pump=10;m.state().lifetime.ore=10000;m.state().wallet={"gold":100000.0,"ore":100000.0,"gems":1000.0}
 check(m.material_cost()=={"iron":1},"next shaft requires a newly available metal bar")
 check(not m.excavate(),"large gold and ore reserve cannot bypass iron requirement")
 o.data.card={"descent_best":5};f.bars.iron=4;check(m.excavate() and f.bars.iron==3,"construction consumes bar and holds refund escrow")
 var before=float(m.state().job.end)-m.now()
 check(Forge.reinforce(m) and is_equal_approx(float(m.state().job.end)-m.now(),before*.65),"reinforcement shortens remaining time by thirty-five percent")
 check(not Forge.reinforce(m),"reinforcement limited to once per build")
 check(Mine.valid(JSON.parse_string(JSON.stringify(m.state()))),"reinforced construction is portable")
 m.cancel_build();check(f.bars.iron==4 and f.reserved.is_empty() and not f.reinforced,"cancel construction refunds all reserved bars")
 m.excavate();m.time_for_test=m.state().job.end;m.advance();check(m.depth()==5 and f.reserved.is_empty(),"completed construction consumes bars and clears escrow")
 var market=Market.new();market.time_for_test=m.now();market.setup(o)
 check(Market.valid(market.state()),"expanded market validates")
 m.state().levels.smelter=0;check(m.material_cost("smelter").is_empty(),"existing deep mine can build its first furnace without bars");m.state().levels.smelter=1
 var old_market=market.state().duplicate(true)
 for d in Market.PRODUCTS:
  if d.has("bar"):old_market.inventory.erase(d.id)
 old_market.cash=321;old_market.inventory.ore.units=7
 check(Market.valid(old_market),"six-product market save remains valid")
 o.data.commerce=old_market;market.setup(o);check(market.state().cash==321 and market.state().inventory.ore.units==7 and market.state().inventory.size()==12,"new goods added while original business preserved")
 f.bars.copper=5;var ore=m.state().wallet.ore
 check(market.stock(6,5) and f.bars.copper==0 and market.state().inventory.copper_bar.units==5,"market consumes forged bars into stock")
 check(m.state().wallet.ore==ore,"bar goods do not consume generic ore twice")
 var baseline=JSON.stringify(o.data);check(not market.stock(6,1) and baseline==JSON.stringify(o.data),"insufficient bar order is atomic")
 market.state().product=6;check(market.settle_day() and market.state().revenue>0,"forged metal can sell through normal marketing simulation")
 check(Market.valid(JSON.parse_string(JSON.stringify(market.state()))),"bar sales report roundtrip")
 for id in Forge.METALS:check(Forge.icon(id)!=null and Forge.icon(id,true)!=null,"ore and ingot art: "+id)
 var bad=m.state().duplicate(true);bad.foundry.bars.iron=-1;check(not Mine.valid(bad),"negative bar stock rejected")
 bad=m.state().duplicate(true);bad.foundry.wallet.copper=INF;check(not Mine.valid(bad),"nonfinite metal rejected")
 bad=m.state().duplicate(true);bad.foundry.job={"metal":"copper","count":100,"start":m.now(),"end":m.now()+10,"seconds":10};check(not Mine.valid(bad),"oversized furnace import rejected")
 root.set_meta("fx_dev_match",true);var saved=JSON.stringify(o.data);check(not Forge.forge(m,"copper",1) and not market.stock(6,1) and JSON.stringify(o.data)==saved,"Playtest protects both economies");root.remove_meta("fx_dev_match")
 o.queue_free();await process_frame;print("V144 FOUNDRY CHECKS: ",checks,"; FAILURES: ",failures);quit(1 if failures else 0)
