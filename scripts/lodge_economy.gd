extends RefCounted
const C=preload("res://scripts/lodge_catalog.gd")
var legacy:Node
var clock_override=-1.0
func setup(owner:Node)->void:legacy=owner;state()
func now()->float:return clock_override if clock_override>=0 else Time.get_unix_time_from_system()
func state()->Dictionary:
 if not C.valid(legacy.data.get("lodges",{})):legacy.data.lodges={}
 if not legacy.data.has("lodges") or legacy.data.lodges.is_empty():legacy.data.lodges={"ingredients":{"sunleaf":2,"mooncap":1},"potions":{},"jobs":[],"brew":{},"seeds":[],"tier":1,"crew":2,"medals":{},"weekly":{},"gathered":0,"brewed":0}
 if bool(legacy.data.get("teacher",false)):
  legacy.data.lodges.tier=3;legacy.data.lodges.crew=3
  for id in C.INGREDIENTS:legacy.data.lodges.ingredients[id]=maxi(99,int(legacy.data.lodges.ingredients.get(id,0)))
  for id in C.RECIPES:legacy.data.lodges.potions[id]=maxi(9,int(legacy.data.lodges.potions.get(id,0)))
 return legacy.data.lodges
func save()->void:legacy.save()
func dispatch(route:String)->String:
 if route not in C.ROUTES:return "Unknown route."
 var s=state()
 if s.jobs.size()>=clampi(int(s.get("crew",2)),2,3):return "All crews are out. Claim a returning crew first."
 var r:Dictionary=C.ROUTES[route];var finds:Dictionary=r.finds.duplicate();var seed=str(r.seed) if randf()<float(r.chance) else ""
 s.jobs.append({"route":route,"start":now(),"end":now()+float(r.seconds),"finds":finds,"seed":seed});save();return "Crew sent to "+str(r.name)+". Return in "+str(int(r.seconds)/60)+" minutes."
func claim(index:int)->String:
 var s=state()
 if index<0 or index>=s.jobs.size():return "That crew has already returned."
 var job:Dictionary=s.jobs[index]
 if now()<float(job.end):return "The crew is still gathering."
 s.jobs.remove_at(index)
 legacy.gardening.find_seed("gather")
 var lines=[]
 for id in job.finds:s.ingredients[id]=mini(100000,int(s.ingredients.get(id,0))+int(job.finds[id]));s.gathered=int(s.get("gathered",0))+int(job.finds[id]);lines.append(str(job.finds[id])+" "+str(C.INGREDIENTS[id].name))
 var seed=str(job.get("seed",""))
 if not seed.is_empty():
  if seed not in s.seeds:s.seeds.append(seed);legacy.gardening.grant(seed);lines.append("Rare seed found! Visit the Seed House.")
  else:lines.append("An extra seed became 1 Sunleaf.");s.ingredients.sunleaf=mini(100000,int(s.ingredients.get("sunleaf",0))+1)
 save();return "Gathered: "+", ".join(lines)
func can_pay(needs:Dictionary)->bool:
 for id in needs:if int(state().ingredients.get(id,0))<int(needs[id]):return false
 return true
func pay(needs:Dictionary)->void:
 for id in needs:state().ingredients[id]=int(state().ingredients.get(id,0))-int(needs[id])
func fish_ingredient(recipe:Dictionary)->int:
 if not recipe.has("fish"):return -2
 var fishing=legacy.fishing_records.state()
 for n in fishing.kept.size():
  var catch:Dictionary=fishing.kept[n]
  if str(catch.species)==str(recipe.fish) and not preload("res://scripts/fishing_catalog.gd").is_trophy(catch) and str(catch.id)!=str(fishing.favorite) and str(catch.id) not in fishing.display:return n
 return -1
func can_brew(recipe:Dictionary)->bool:return can_pay(recipe.needs) and fish_ingredient(recipe)!=-1
func brew(id:String)->String:
 if id not in C.RECIPES:return "Unknown recipe."
 var s=state();var r:Dictionary=C.RECIPES[id]
 if not s.brew.is_empty():return "Collect the current batch first."
 if int(s.tier)<int(r.tier):return "Upgrade the apothecary for this recipe."
 if not can_pay(r.needs):return "Send gathering crews for the missing ingredients."
 var fish_index=fish_ingredient(r)
 if fish_index==-1:return "Keep an ordinary "+str(preload("res://scripts/fishing_catalog.gd").fish().get(str(r.get("fish","")),{}).get("name","fish"))+" first. Trophies, favourites and displayed fish are protected."
 if int(s.potions.get(id,0))>=99:return "You already have 99 bottles of this potion."
 if fish_index>=0:
  var fish_state=legacy.fishing_records.state();fish_state.stored_ids.erase(str(fish_state.kept[fish_index].id));fish_state.kept.remove_at(fish_index)
 pay(r.needs);s.brew={"id":id,"start":now(),"end":now()+float(r.seconds)};save();return "Brewing "+str(r.name)+"."
func claim_brew()->String:
 var s=state()
 if s.brew.is_empty() or now()<float(s.brew.get("end",0)):return "This batch is not ready."
 var id=str(s.brew.id);s.potions[id]=mini(99,int(s.potions.get(id,0))+1);s.brew={};s.brewed=int(s.get("brewed",0))+1;save();return str(C.RECIPES[id].name)+" bottled! Pack it below."
func pack(game:Node,id:String)->String:
 var s=state()
 if int(s.potions.get(id,0))<=0:return "Brew a bottle first."
 if not preload("res://scripts/supply_slots.gd").can_add(game.loadout,id,game.items):return "Your consumable slot is full. Unpack it at the Supply Vendor first."
 s.potions[id]-=1;game.loadout.append(id);preload("res://scripts/prepared_supply.gd").set_ready(id,0);save();game.save_profile();return "Packed "+str(C.RECIPES[id].name)+" in your separate consumable slot. Key 4 or click the bottle during combat."
func upgrade()->String:
 var s=state()
 if int(s.tier)>=3:return "Apothecary fully upgraded."
 var needs={"willow":4,"sunleaf":3} if int(s.tier)==1 else {"mooncap":6,"firefly":4,"petal":4}
 if not can_pay(needs):return "Gather the upgrade ingredients shown below."
 pay(needs);s.tier+=1;save();return "Apothecary upgraded. New recipes available!"
func medal(key:String,tier:int,weekly_key:String="")->void:
 if preload("res://scripts/profile_store.gd").progression_blocked():return
 legacy.weekly.advance("challenge",1)
 var s=state();s.medals[key]=maxi(int(s.medals.get(key,0)),clampi(tier,1,3))
 if not weekly_key.is_empty():
  if not s.weekly.has(C.week()):s.weekly={C.week():[]}
  if weekly_key not in s.weekly[C.week()]:s.weekly[C.week()].append(weekly_key)
 save()
func medal_total()->int:
 var total=0
 for value in state().medals.values():total+=int(value)
 return total
func weekly_earned()->bool:return state().weekly.get(C.week(),[]).size()>=3
