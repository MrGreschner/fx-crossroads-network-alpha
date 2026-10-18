extends RefCounted
## One policy for the lobby, local simulation, and server admission.
static func allows_ai(mode:String)->bool:return mode in ["arena","battlegrounds","defense"]
static func teamed(g:Node)->bool:return g.mode=="battlegrounds" or g.mode=="arena" and g.arena_party_rule=="teams"
static func side_limit(g:Node)->int:return g.bg_team_size if g.mode=="battlegrounds" else g.arena_team_size
static func side_name(side:int)->String:return "BLUE TEAM" if side==0 else "RED TEAM"
static func colour(side:int)->Color:return Color("#6cbdf2") if side==0 else Color("#f28b87")
static func preview(g:Node)->Array:
 if g.net_ready:return g.roster
 var members:Array=[{"id":"preview","hero":g.selected_hero,"name":g.net_name.text,"team":g.local_lobby_team}]
 if allows_ai(g.mode):
  for n in g.bot_plan.size():
   var b=g.bot_plan[n];var i=g.bots.IDS.find(str(b.hero))
   members.append({"id":"bot:"+str(n),"hero":b.hero,"name":g.bots.NAMES[i]+" [AI]","team":b.team})
 return members
