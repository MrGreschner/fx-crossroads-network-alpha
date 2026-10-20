extends RefCounted
const P=preload("res://scripts/workshop_project.gd")
const POSES=["idle","walk1","walk2","attack"]
static func coverage(encoded:String)->float:
 if encoded.is_empty():return 0
 var image=Image.new()
 if image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))!=OK:return 0
 var filled=0
 for y in image.get_height():
  for x in image.get_width():
   if image.get_pixel(x,y).a>=.5:filled+=1
 return float(filled)/maxi(1,image.get_width()*image.get_height())
static func art_issue(p:Dictionary,complete:bool=false)->String:
 for pose in POSES:
  if not p.hero.art.has(pose):
   if complete:return "Add the "+pose+" artwork before submitting."
   continue
  if coverage(str(p.hero.art[pose]))<.3:return pose.capitalize()+" artwork needs at least 30% filled pixels (at least half opacity)."
 for id in p.hero.get("alternate_forms",{}):
  if coverage(str(p.hero.alternate_forms[id].get("image","")))<.3:return "Alternate form "+str(id)+" needs at least 30% filled pixels too."
 return ""
static func issue(p:Dictionary)->String:
 var error=P.validate(p)
 if not error.is_empty():return error
 if not p.get("forced_balance",false):return "Turn Forced Balance on before submitting."
 if not preload("res://scripts/studio_balance.gd").hero_checked(p):return "This build exceeds Forced Balance budgets. Re-enable Forced Balance and save."
 if str(p.hero.lore).strip_edges().length()<30:return "Write at least 30 characters of hero lore."
 if str(p.hero.species).strip_edges().is_empty():return "Describe the hero’s species or object."
 if str(p.concept).strip_edges().length()<20:return "Describe your hero’s play style (at least 20 characters)."
 for kind in P.KINDS:
  if str(p.hero[kind].name).strip_edges() in ["New ability",""]:return "Name your "+kind+" ability."
 for t in p.techniques:
  if str(t.name).strip_edges().is_empty():return "Name both mastery alternatives."
 return art_issue(p,true)
