extends RefCounted
static func ordinary(uid:int,difficulty:int=1,level:int=1)->int:
 var tier=clampi((maxi(1,level)-1)/20+maxi(0,difficulty-1),0,2)
 return clampi(3+mini(2,tier)+posmod(uid,2),3,5)
static func amount(e:Dictionary,difficulty:int=1,level:int=1)->int:
 if bool(e.get("phase_minion",false)) or (e.get("summoned",false) is bool and e.get("summoned",false)) or bool(e.get("converted",false)):return 0
 return 40 if bool(e.get("boss",false)) else ordinary(int(e.get("uid",0)),difficulty,level)
