extends RefCounted
## Local aquarium takings: settle the OLD exhibition before any display changes.
const C=preload("res://scripts/fishing_catalog.gd")
const STORE=preload("res://scripts/profile_store.gd")
const BASE={"Common":0,"Uncommon":1,"Rare":3,"Very rare":6,"Legendary":12,"Mystical":18,"Fabled":28}
const OFFLINE_SECONDS=86400
const CAP=10000
const UNIT=3600
var records:RefCounted
var test_now=-1
func now()->int:return test_now if test_now>=0 else int(Time.get_unix_time_from_system())
func migrate(s:Dictionary)->void:
 if not s.has("aquarium"):s.aquarium={"version":1,"last":now(),"units":0,"collected":0}
func state()->Dictionary:return records.state().aquarium
func allowed()->bool:
 return records.legacy!=null and not bool(records.legacy.data.get("teacher",false)) and not records.legacy.recovery_required and not STORE.progression_blocked()
static func rate(catch:Dictionary)->int:
 var species=str(catch.get("species",""))
 if not C.fish().has(species):return 0
 var kg=float(catch.get("kg",0))
 if not is_finite(kg) or kg<=0:return 0
 var size=clampf(kg/maxf(.001,C.mean_kg(species)),0.0,3.5)
 var rarity=int(BASE.get(str(C.fish()[species].rarity),0))
 # Small rare specimens still attract visitors; normal common specimens do not.
 return int(floor(rarity*clampf(size,.5,2.0)+maxf(0,size-1.25)*4))+(8 if C.is_trophy(catch) else 0)
func hourly()->int:
 var s=records.state();var total=0;var used:Array=[]
 for id in s.display:
  if str(id).is_empty() or id in used:continue
  used.append(id)
  total+=rate(records.specimen(str(id)))
 return total
func advance()->void:
 var s=state();var end=now();var start=int(s.last)
 if end<=start:return
 s.last=end
 if not allowed():return
 var seconds=mini(end-start,OFFLINE_SECONDS)
 s.units=mini(CAP*UNIT,int(s.units)+seconds*hourly())
func ready()->int:return int(int(state().units)/UNIT)
func collect()->String:
 if not allowed():return "Aquarium earnings are available on your normal profile."
 var game=records.legacy.game
 if game.mode!="town" or not is_instance_valid(game.fishing.room):return "Collect visitor takings inside Ripple & Reel."
 advance()
 var amount=ready()
 if amount<=0:return "No whole Glimmers to collect yet. Add rare or trophy catches and let visitors arrive."
 if not records.legacy.glimmers.credit(amount):return "Your Glimmer wallet is full. Your aquarium takings are safe."
 var paid=int(records.legacy.glimmers.last_credit)
 state().units-=amount*UNIT;state().collected+=amount
 records.save()
 return "Collected %d Glimmers from aquarium visitors!" % paid
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()!=4 or not (v.get("version") is int or v.get("version") is float) or v.get("version")!=1:return false
 for key in ["last","units","collected"]:
  var n=v.get(key)
  if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=floorf(float(n)) or n<0:return false
  if float(n)>{"last":4102444800,"units":CAP*UNIT,"collected":1e15}[key]:return false
 return true
