extends RefCounted
## A single encounter bar, shared by solo and network combat HUDs.
static func bosses(g:Node)->Array:
 var multi=g.has_method("_attack_request");var foes:Array=g.opponents if multi else g.enemies
 var player:Vector2=g.local_pos if multi else g.position_in_world
 return foes.filter(func(e):return bool(e.get("boss",false)) and float(e.get("hp",0))>0 and (e.pos as Vector2).distance_to(player)<1500)
static func draw_on(g:Node2D)->void:
 var list=bosses(g)
 if list.is_empty():return
 var hp=0.0;var maximum=0.0
 for e in list:hp+=float(e.hp);maximum+=float(e.max_hp)
 var region:Dictionary=g.regions.get(g.realm_id,{}) if g.has_method("_attack_request") else g.region
 var defs:Dictionary=g.enemy_defs if g.has_method("_attack_request") else g.enemy_types
 var title=str(defs.get(str(list[0].type),{}).get("name",str(region.get("name","Realm"))+" Guardian"))
 if str(list[0].type) in ["boss","fragment"]:title="Quarry Guardians" if str(region.get("id",""))=="quarry" else "Plague Director" if str(region.get("id",""))=="zombie" else "Grove Rootwarden"
 if list.size()>1:title+=" ×"+str(list.size())
 var has_objectives=g.adventure.cinder.active or g.adventure.immersive.active or g.adventure.school.active or g.adventure.tech.active or g.adventure.foundry.active or g.adventure.quests.active or g.adventure.expansion.active or g.adventure.city.active or g.adventure.hollow.active or g.mode=="defense"
 var width=minf(520,g.VIEW.x*.46);var p=Vector2((g.VIEW.x-width)*.5,190 if has_objectives else 112)
 g.draw_style_box(style(),Rect2(p-Vector2(8,22),Vector2(width+16,54)))
 g.draw_string(ThemeDB.fallback_font,p+Vector2(0,-4),title,HORIZONTAL_ALIGNMENT_CENTER,width,16,Color("#f7d996"))
 g.draw_rect(Rect2(p+Vector2(0,3),Vector2(width,15)),Color("#302833"))
 g.draw_rect(Rect2(p+Vector2(0,3),Vector2(width*clampf(hp/maxf(1,maximum),0,1),15)),Color("#c96a73"))
 g.draw_string(ThemeDB.fallback_font,p+Vector2(0,16),"%d / %d HP" % [ceili(hp),ceili(maximum)],HORIZONTAL_ALIGNMENT_CENTER,width,12,Color.WHITE)
static func style()->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(.04,.09,.14,.94);s.border_color=Color("#c8a363");s.set_border_width_all(1);s.set_corner_radius_all(5);return s
