extends RefCounted
const B=preload("res://scripts/arena_bots.gd")
const R=preload("res://network/party_rules.gd")
static func group(parent:Node,title:String,colour:Color)->VBoxContainer:
 var frame=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(frame)
 var skin=StyleBoxFlat.new();skin.bg_color=Color(colour,.07);skin.border_color=colour;skin.set_border_width_all(1);skin.set_corner_radius_all(7);skin.set_content_margin_all(10);frame.add_theme_stylebox_override("panel",skin)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",8);frame.add_child(col)
 var label=Label.new();label.text=title;label.modulate=colour;col.add_child(label);return col
static func picker(parent:Node,g:Node,id:String)->OptionButton:
 var portrait=TextureRect.new();portrait.custom_minimum_size=Vector2(40,44);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(portrait)
 var hero=OptionButton.new();hero.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(hero)
 for i in B.IDS.size():hero.add_item(B.NAMES[i]+" • "+B.ROLES[i])
 hero.select(maxi(0,B.IDS.find(id)));portrait.texture=g.art.get(B.IDS[hero.selected]+"_idle")
 hero.item_selected.connect(func(i:int):portrait.texture=g.art.get(B.IDS[i]+"_idle"));return hero
static func open(g:Node)->void:
 if g.net_ready and not g.net_host:g.net_status.text="The host chooses AI seats.";return
 if not R.allows_ai(g.mode):g.net_status.text="AI allies are available in Gate Defence, team Arena and Battlegrounds.";return
 var gate=g.mode=="defense";var team_mode=R.teamed(g);var own=g.local_lobby_team
 g.presentation.window("GATE DEFENCE • ALLIES & ENEMY RIVALS" if gate else "CHOOSE YOUR AI HEROES","ai_roster")
 var col=g.presentation.content
 var members=R.preview(g);var humans=members.filter(func(m):return not str(m.id).begins_with("bot:"))
 var help="Choose friendly defenders on the left and enemy rivals on the right. One rival per defender; rivals arrive at wave 3." if gate else "Choose a hero, then choose ALLY or ENEMY relative to your team. AI Arena matches are practice." if team_mode else "FREE FOR ALL • Every AI below is an enemy. No allies in this match."
 g.presentation.label(col,help,15)
 var notice=g.presentation.label(col,"",15);notice.modulate=Color("#ffd58e")
 var area=HBoxContainer.new();area.add_theme_constant_override("separation",14);col.add_child(area)
 var allies=group(area,"YOUR ALLIES • DEFEND THE GATE" if gate else "AI HEROES • ENABLE THE SEATS YOU WANT",R.colour(0) if gate else Color("#86bbc4"))
 var controls=[];var rival_controls=[];var rival_rows=[]
 for n in (3 if gate else 7):
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",6);allies.add_child(row)
  var enabled=CheckButton.new();enabled.text=("Ally " if gate else "Use ")+str(n+1);enabled.name="AISeat_"+str(n);row.add_child(enabled);enabled.button_pressed=n<g.bot_plan.size()
  var hero=picker(row,g,str(g.bot_plan[n].hero) if n<g.bot_plan.size() else B.IDS[n]);hero.name="AIHero_"+str(n)
  var side=OptionButton.new();row.add_child(side);side.name="AISide_"+str(n)
  for i in 2:side.add_item(("ALLY • " if i==own else "ENEMY • ")+R.side_name(i),i)
  side.select(int(g.bot_plan[n].team) if n<g.bot_plan.size() else 1-own);side.visible=team_mode
  side.modulate=R.colour(side.selected);side.item_selected.connect(func(i:int):side.modulate=R.colour(i))
  controls.append([enabled,hero,side])
 if gate:
  var enemies=group(area,"ENEMY RIVALS • ATTACK THE GATE",R.colour(1))
  for n in 4:
   var row=HBoxContainer.new();row.add_theme_constant_override("separation",6);enemies.add_child(row);rival_rows.append(row)
   var label=Label.new();label.text="Rival "+str(n+1);row.add_child(label)
   var hero=picker(row,g,str(g.gate_rival_plan[n]));hero.name="GateRival_"+str(n);rival_controls.append(hero)
  var summary=g.presentation.label(enemies,"",14)
  var sync=func():
   var count=mini(4,humans.size()+controls.filter(func(v):return v[0].button_pressed).size())
   summary.text="%d defenders = %d enemy rivals.\nDimmed slots activate when you add defenders." % [count,count]
   for n in 4:rival_rows[n].modulate=Color.WHITE if n<count else Color(1,1,1,.4);rival_controls[n].disabled=n>=count
  for entry in controls:entry[0].toggled.connect(func(_v:bool):sync.call())
  sync.call()
 var difficulty=OptionButton.new();col.add_child(difficulty)
 for title in ["AI difficulty: Easy","AI difficulty: Medium","AI difficulty: Hard"]:difficulty.add_item(title)
 difficulty.select(["easy","medium","hard"].find(g.ai_difficulty))
 var shell=col.get_parent().get_parent();var close=shell.get_child(shell.get_child_count()-1);shell.remove_child(close)
 var footer=HBoxContainer.new();shell.add_child(footer);footer.add_child(close)
 var apply=g.presentation.button(footer,"Save AI choices",func():
  var plan=[]
  for entry in controls:
   if entry[0].button_pressed:plan.append({"hero":B.IDS[entry[1].selected],"team":entry[2].selected if team_mode else 0 if gate else 1})
  var seats=R.side_limit(g)*2 if team_mode else g.capacity.get_selected_id()
  if plan.size()+humans.size()>seats:notice.text="Not enough seats. Remove an ally or choose a larger room.";return
  if team_mode:
   for team in 2:
    if humans.filter(func(m):return int(m.get("team",0))==team).size()+plan.filter(func(m):return int(m.team)==team).size()>R.side_limit(g):notice.text=R.side_name(team)+" is full. Choose the other team for an AI.";return
  var rivals=g.gate_rival_plan.duplicate()
  if gate:
   rivals=[]
   var count=mini(4,humans.size()+plan.size())
   for n in count:
    var id=B.IDS[rival_controls[n].selected]
    if id in rivals:notice.text="Choose a different hero for each active enemy rival.";return
    rivals.append(id)
   for n in range(count,4):
    var id=B.IDS[rival_controls[n].selected]
    if id in rivals:id=B.IDS.filter(func(v):return v not in rivals)[0]
    rivals.append(id)
  g.ai_difficulty=["easy","medium","hard"][difficulty.selected];g.presentation.close()
  if g.net_ready:g.send_net({"type":"ai_party","bots":plan,"rivals":rivals,"difficulty":g.ai_difficulty})
  else:g.bot_plan=plan;g.gate_rival_plan=rivals;g.net_status.text="AI choices saved • %d allies, %d rivals." % [plan.size(),mini(4,humans.size()+plan.size())] if gate else "AI choices saved.";g._sync_network_mode_controls())
 apply.name="SaveAIChoices"
