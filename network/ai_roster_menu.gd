extends RefCounted
const B=preload("res://scripts/arena_bots.gd")
static func open(g:Node)->void:
 if g.net_ready and not g.net_host:g.net_status.text="The host chooses AI seats.";return
 if g.mode=="coop" and g.realm_id in ["between","overcharge","attunement"]:g.net_status.text="These expeditions support solo or two human players. AI companions are available in other matches.";return
 g.presentation.window("AI ROSTER • CHOOSE ALLIES AND OPPONENTS","ai_roster")
 var col=g.presentation.content
 g.presentation.label(col,"Seven distinct kits • AI uses normal attacks, cooldowns and CC. AI Arena matches are practice; PvP records and trophies require human opponents.",16)
 var controls=[]
 var own_team=0
 for member in g.roster:
  if str(member.id)==g.my_id:own_team=int(member.get("team",0))
 for n in 7:
  var row=HBoxContainer.new();col.add_child(row)
  var enabled=CheckButton.new();enabled.text="Seat "+str(n+1);row.add_child(enabled);enabled.button_pressed=n<g.bot_plan.size()
  var hero=OptionButton.new();hero.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(hero)
  for i in B.NAMES.size():hero.add_item(B.NAMES[i]+" • "+B.ROLES[i])
  hero.select(B.IDS.find(str(g.bot_plan[n].hero)) if n<g.bot_plan.size() else n)
  var side=OptionButton.new();side.add_item(("Ally" if own_team==0 else "Opponent")+" • team 1",0);side.add_item(("Ally" if own_team==1 else "Opponent")+" • team 2",1);side.select(int(g.bot_plan[n].team) if n<g.bot_plan.size() else 1);side.visible=g.mode in ["arena","battlegrounds"];row.add_child(side)
  controls.append([enabled,hero,side])
 var difficulty=OptionButton.new();col.add_child(difficulty)
 for title in ["Easy • slower reactions","Medium • balanced","Hard • quicker reactions"]:difficulty.add_item(title)
 difficulty.select(["easy","medium","hard"].find(g.ai_difficulty))
 var shell=col.get_parent().get_parent();var close=shell.get_child(shell.get_child_count()-1);shell.remove_child(close)
 var footer=HBoxContainer.new();shell.add_child(footer);footer.add_child(close)
 g.presentation.button(footer,"Apply AI roster",func():
  var plan=[]
  for entry in controls:
   if entry[0].button_pressed:plan.append({"hero":B.IDS[entry[1].selected],"team":entry[2].selected if g.mode in ["arena","battlegrounds"] else 0})
  g.bot_plan=plan;g.ai_difficulty=["easy","medium","hard"][difficulty.selected];g.presentation.close()
  if g.net_ready:g.send_net({"type":"ai_party","bots":plan,"difficulty":g.ai_difficulty})
  else:g.net_status.text="AI roster saved • %d selected. Play solo or Host a room." % plan.size())
