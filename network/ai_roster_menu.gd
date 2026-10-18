extends RefCounted
const B=preload("res://scripts/arena_bots.gd")
const R=preload("res://network/party_rules.gd")
static func open(g:Node)->void:
 if g.net_ready and not g.net_host:g.net_status.text="The host chooses AI seats.";return
 if not R.allows_ai(g.mode):g.net_status.text="This adventure is solo or human co-op. AI allies are available in Gate Defence, team Arena and Battlegrounds.";return
 g.presentation.window("AI ROSTER • CHOOSE HEROES & TEAMS","ai_roster")
 var col=g.presentation.content
 g.presentation.label(col,"AI Arena matches are practice. In FFA every bot is an opponent. Team assignments appear with portraits in the lobby.",16)
 var notice=g.presentation.label(col,"",15)
 var controls=[]
 var members=R.preview(g)
 for n in 7:
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);col.add_child(row)
  var portrait=TextureRect.new();portrait.custom_minimum_size=Vector2(44,48);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(portrait)
  var enabled=CheckButton.new();enabled.text="Seat "+str(n+1);row.add_child(enabled);enabled.button_pressed=n<g.bot_plan.size()
  var hero=OptionButton.new();hero.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(hero)
  for i in B.NAMES.size():hero.add_item(B.NAMES[i]+" • "+B.ROLES[i])
  hero.select(B.IDS.find(str(g.bot_plan[n].hero)) if n<g.bot_plan.size() else n)
  portrait.texture=g.art.get(B.IDS[hero.selected]+"_idle")
  hero.item_selected.connect(func(i:int):portrait.texture=g.art.get(B.IDS[i]+"_idle"))
  var side=OptionButton.new();side.add_item(R.side_name(0),0);side.add_item(R.side_name(1),1);side.select(int(g.bot_plan[n].team) if n<g.bot_plan.size() else 1);side.visible=R.teamed(g);row.add_child(side)
  side.modulate=R.colour(side.selected);side.item_selected.connect(func(i:int):side.modulate=R.colour(i))
  controls.append([enabled,hero,side])
 var difficulty=OptionButton.new();col.add_child(difficulty)
 for title in ["Easy • slower reactions","Medium • balanced","Hard • quicker reactions"]:difficulty.add_item(title)
 difficulty.select(["easy","medium","hard"].find(g.ai_difficulty))
 var shell=col.get_parent().get_parent();var close=shell.get_child(shell.get_child_count()-1);shell.remove_child(close)
 var footer=HBoxContainer.new();shell.add_child(footer);footer.add_child(close)
 g.presentation.button(footer,"Apply AI roster",func():
  var plan=[]
  for entry in controls:
   if entry[0].button_pressed:plan.append({"hero":B.IDS[entry[1].selected],"team":entry[2].selected if R.teamed(g) else 0 if g.mode=="defense" else 1})
  var humans=members.filter(func(m):return not str(m.id).begins_with("bot:"))
  var seats=R.side_limit(g)*2 if R.teamed(g) else g.capacity.get_selected_id()
  if plan.size()+humans.size()>seats:notice.text="AI uses player seats. Remove an AI or choose a larger match.";return
  if R.teamed(g):
   for team in 2:
    if humans.filter(func(m):return int(m.get("team",0))==team).size()+plan.filter(func(m):return int(m.team)==team).size()>R.side_limit(g):notice.text=R.side_name(team)+" is full. Move an AI to the other team.";return
  g.ai_difficulty=["easy","medium","hard"][difficulty.selected];g.presentation.close()
  if g.net_ready:g.send_net({"type":"ai_party","bots":plan,"difficulty":g.ai_difficulty})
  else:g.bot_plan=plan;g.net_status.text="AI roster saved • %d selected. Play solo or Host a room." % plan.size();g._sync_network_mode_controls())
