extends RefCounted
## Pure trigger rules shared by solo and authoritative co-op. No profile writes.
const IDS=["reed_oath","undertow_mark","tideheart","stormfolio","clockwork_drive","secondhand_guard","astral_echo","gravity_anchor","eventide_seed"]
static func damage(s:Dictionary,v:Dictionary,ratio:float)->float:
 var mult=1.0
 if ratio>.8:mult*=1+float(v.clockwork_drive)/100
 if float(s.timers.get("tide_charge",0))>0:mult*=1+float(v.tideheart)/100;s.timers.tide_charge=0.0
 return mult
static func incoming(s:Dictionary,v:Dictionary,amount:float)->float:
 if amount<=0:return amount
 var ready=float(s.timers.get("secondhand_rest",0))<=0;s.timers.secondhand_rest=8.0
 return amount*(1-float(v.secondhand_guard)/100) if ready else amount
static func event(kind:String,s:Dictionary,v:Dictionary,hero:String)->Array:
 var out=[]
 if kind=="dodge":
  if float(v.reed_oath)>0 and float(s.timers.get("reed_oath",0))<=0:
   s.timers.reed_oath=10.0;out.append({"kind":"shield","value":v.reed_oath,"duration":4.0})
   if hero=="ferryman":out.append({"kind":"heal","value":3})
  if float(v.gravity_anchor)>0 and float(s.timers.get("gravity_anchor",0))<=0:s.timers.gravity_anchor=10.0;s.timers.gravity_charge=4.0
 elif kind=="food":
  if float(v.tideheart)>0 and float(s.timers.get("tideheart",0))<=0:s.timers.tideheart=10.0;s.timers.tide_charge=4.0
 elif kind=="kill":
  if float(v.eventide_seed)>0 and float(s.timers.get("eventide_seed",0))<=0:s.timers.eventide_seed=12.0;out.append({"kind":"heal","value":v.eventide_seed})
 elif kind=="hit":
  s.extra_hits=int(s.get("extra_hits",0))+1
  if float(v.undertow_mark)>0 and float(s.timers.get("undertow_mark",0))<=0:s.timers.undertow_mark=7.0;out.append({"kind":"slow","value":.25,"duration":v.undertow_mark})
  if float(s.timers.get("gravity_charge",0))>0:s.timers.gravity_charge=0.0;out.append({"kind":"slow","value":.4,"duration":v.gravity_anchor})
  if float(v.stormfolio)>0 and int(s.extra_hits)>=6 and float(s.timers.get("stormfolio",0))<=0:
   s.extra_hits=0;s.timers.stormfolio=6.0;out.append({"kind":"echo","value":v.stormfolio,"chain":hero=="stormscribe"})
  if float(v.astral_echo)>0 and float(s.timers.get("astral_echo",0))<=0:s.timers.astral_echo=10.0;out.append({"kind":"echo","value":v.astral_echo,"chain":false})
 return out
