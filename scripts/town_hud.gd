extends RefCounted
static func height(g:Node)->float:return 120.0 if g.VIEW.x<1100 else 106.0
static func draw_on(g:Node2D)->void:
 preload("res://scripts/weather_badge.gd").draw_on(g,g.town_life.calendar.weather())
 var font=g.font;var size=13
 var date=g.town_life.calendar.label()
 var hero="Hero: "+str(g.characters.get(g.selected_character,{}).get("name",g.selected_character))
 var left=date+"   •   "+hero
 var money="CC: %d   •   Glimmers: %d   •   Waylight Shards: %d   •   %s" % [g.gold,g.legacy.glimmers.balance(),g.waylight.progress.state().shards,preload("res://scripts/education_access.gd").role_label()]
 var narrow=g.VIEW.x<1100;var y=113.0 if narrow else 95.0
 g.draw_string(font,Vector2(24,95),left,HORIZONTAL_ALIGNMENT_LEFT,g.VIEW.x-170,size,Color("#ffe0a0"))
 var minimum=24.0 if narrow else 40+font.get_string_size(left,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 var maximum=g.VIEW.x-150
 var available=maxf(80,maximum-minimum)
 # Protect the right-hand runs label even with a long balance or selected hero name.
 var money_size=size
 while money_size>10 and font.get_string_size(money,HORIZONTAL_ALIGNMENT_LEFT,-1,money_size).x>available:money_size-=1
 var width=minf(available,font.get_string_size(money,HORIZONTAL_ALIGNMENT_LEFT,-1,money_size).x)
 var x=clampf((g.VIEW.x-width)*.5,minimum,maxf(minimum,maximum-width))
 g.draw_string(font,Vector2(x,y),money,HORIZONTAL_ALIGNMENT_LEFT,available,money_size,Color("#eed8a3"))
 g.draw_string(font,Vector2(g.VIEW.x-132,y),"Runs: %d" % int(g.profile.get("runs",0)),HORIZONTAL_ALIGNMENT_LEFT,112,13,Color("#c1cecb"))

static func session_name(g:Node)->String:
 var account=g.get_node_or_null("/root/FXAccount")
 return str(account.user.get("username","Guest")) if account!=null and not account.token.is_empty() else "Guest"
static func heading(g:Node)->String:return "CROSSROADS: REALMS BEYOND  |  "+session_name(g)
static func draw_heading(g:Node2D)->void:
 var account=g.get_node_or_null("/root/FXAccount");var teacher=account!=null and not account.token.is_empty() and str(account.user.get("role",""))=="teacher"
 if teacher and g.VIEW.x<850:return
 var available=maxf(180,g.VIEW.x-575-36-(150 if teacher else 0));var text=heading(g);var font=g.font;var pixels=25
 while pixels>17 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>available:pixels-=1
 if font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x<=available:
  g.draw_string(font,Vector2(24,32),text,HORIZONTAL_ALIGNMENT_LEFT,available,pixels,Color.WHITE)
 else:
  var title="CROSSROADS: REALMS BEYOND";var title_size=14
  while title_size>10 and font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>available:title_size-=1
  g.draw_string(font,Vector2(24,19),title,HORIZONTAL_ALIGNMENT_LEFT,available,title_size,Color.WHITE)
  g.draw_string(font,Vector2(24,36),"|  "+session_name(g),HORIZONTAL_ALIGNMENT_LEFT,available,14,Color("#9de0db"))
