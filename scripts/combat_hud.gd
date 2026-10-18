extends RefCounted
## Shared combat geometry; town layout and gameplay state are independent.
static func dock(g:Node)->Rect2:
 var width=minf(900,g.VIEW.x-40)
 if g.mobile.enabled:return Rect2(300,g.VIEW.y-100,clampf(g.VIEW.x-900,340,600),90)
 return Rect2((g.VIEW.x-width)*.5,g.VIEW.y-(70 if g.mobile.enabled else 42),width,32)
static func header(g:Node2D,title:String,coins:int,hp:float,max_hp:float)->void:
 var font:Font=ThemeDB.fallback_font
 g.draw_rect(Rect2(0,0,g.VIEW.x,90),Color(.035,.085,.12,.88))
 g.draw_string(font,Vector2(24,29),title,HORIZONTAL_ALIGNMENT_LEFT,g.VIEW.x-450,19,Color("#f4e6bf"))
 var shards=int(g.legacy.data.get("waylight",{}).get("shards",0))
 g.draw_string(font,Vector2(24,53),"CC %d   •   Glimmers %d   •   Waylight Shards %d" % [coins,g.legacy.glimmers.balance(),shards],HORIZONTAL_ALIGNMENT_LEFT,g.VIEW.x-340,15,Color("#b9dbe9"))
 var r=health_rect(g.VIEW)
 g.draw_rect(r,Color("#352934"))
 g.draw_rect(Rect2(r.position,Vector2(r.size.x*clampf(hp/maxf(1,max_hp),0,1),r.size.y)),Color("#cd777c"))
 g.draw_rect(r,Color("#e8a1a6"),false,1)
 var baseline=r.position+Vector2(0,16)
 g.draw_string_outline(font,baseline,"HP %d / %d" % [int(hp),int(max_hp)],HORIZONTAL_ALIGNMENT_CENTER,r.size.x,15,2,Color("#352934"))
 g.draw_string(font,baseline,"HP %d / %d" % [int(hp),int(max_hp)],HORIZONTAL_ALIGNMENT_CENTER,r.size.x,15,Color.WHITE)
static func health_rect(view:Vector2)->Rect2:
 var width=minf(720,maxf(180,view.x-560))
 return Rect2((view.x-width)*.5,64,width,20)
static func cooldown_rect(view:Vector2,index:int)->Rect2:return Rect2(view.x-226,12+index*24,170,16)
static func cooldown(g:Node2D,index:int,label:String,fraction:float,state:String,locked:bool)->void:
 var font:Font=ThemeDB.fallback_font;var r=cooldown_rect(g.VIEW,index)
 var color=[Color("#f4d58a"),Color("#9cdef1"),Color("#d5a8f0")][index]
 g.draw_string(font,Vector2(g.VIEW.x-270,r.position.y+13),label,HORIZONTAL_ALIGNMENT_LEFT,42,13,Color("#a4abb3") if locked else Color.WHITE)
 g.draw_rect(r,Color("#293640"));g.draw_rect(Rect2(r.position,Vector2(r.size.x*clampf(fraction,0,1),r.size.y)),color)
 g.draw_string(font,Vector2(r.end.x+5,r.position.y+13),state,HORIZONTAL_ALIGNMENT_LEFT,50,12,Color("#e7e9dc"))
static func experience(g:Node2D,label:String,fraction:float)->void:
 var r=dock(g);r.position.y-=30;r.size.y=23
 g.draw_rect(r,Color(.025,.065,.11,.92))
 g.draw_rect(Rect2(r.position+Vector2(0,19),Vector2(r.size.x,4)),Color("#1c3553"))
 g.draw_rect(Rect2(r.position+Vector2(0,19),Vector2(r.size.x*clampf(fraction,0,1),4)),Color("#479cff"))
 g.draw_string(ThemeDB.fallback_font,r.position+Vector2(8,14),label,HORIZONTAL_ALIGNMENT_LEFT,r.size.x-16,13,Color("#c9e3ff"))
