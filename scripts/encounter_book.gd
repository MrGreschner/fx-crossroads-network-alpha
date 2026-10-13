extends RefCounted
var tick:=0.0
func step(combat:Node,delta:float)->void:
 tick+=delta
 if tick<.4:return
 tick=0
 var a=combat.adventure
 if not a.arcade or a.game.mode!="coop" or not a.game.started:return
 var g=a.game;var id:=str(g.realm_id);var viewer:=str(g.my_id)
 if not a.alive(viewer):return
 var book:Dictionary=g.legacy.data.get("encounters",{});var found:Array=book.get(id,[]);var changed:=false
 for foe in a.foes():
  if float(foe.get("hp",0))<=0 or combat.owner_pos(viewer).distance_to(foe.pos)>600 or not combat.path_clear(combat.owner_pos(viewer),foe.pos):continue
  var kind:=str(foe.get("type",""))
  if kind in ["boss","fragment"]:
   var boss:=str(g.regions.get(id,{}).get("boss_sprite","bramble_boss"));kind=boss if g.enemy_defs.has(boss) else "boss:"+boss
  if kind.is_empty() or kind in found:continue
  found.append(kind);changed=true
 if changed:book[id]=found;g.legacy.data.encounters=book;g.legacy.save()
