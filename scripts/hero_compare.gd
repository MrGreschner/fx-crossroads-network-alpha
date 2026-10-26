extends RefCounted
var game:Node
var box:HBoxContainer
var picks:Array=[]
var choices:Array[String]=[]
func open(owner:Node)->void:
 game=owner;game.presentation.window("COMPARE HEROES","hero_compare")
 game.presentation.label(game.presentation.content,"Compare official and local custom builds. Attack budgets are estimates; field testing still matters.",16)
 choices.assign(game.characters.keys())
 var row=HBoxContainer.new();game.presentation.content.add_child(row)
 for side in 2:
  var select=OptionButton.new();select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;select.custom_minimum_size.y=44;row.add_child(select)
  for id in choices:select.add_item(str(game.characters[id].name)+(" • custom" if id.begins_with("custom_") else ""))
  select.select(maxi(0,choices.find(game.selected_character)) if side==0 else mini(1,choices.size()-1));select.item_selected.connect(func(_i:int):render());picks.append(select)
 box=HBoxContainer.new();box.add_theme_constant_override("separation",18);game.presentation.content.add_child(box);render()
func render()->void:
 for child in box.get_children():box.remove_child(child);child.queue_free()
 for side in 2:
  var id=choices[picks[side].selected];var h:Dictionary=game.characters[id];var panel=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#183945","#587986",12,16));box.add_child(panel)
  var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(col)
  var art=TextureRect.new();art.custom_minimum_size=Vector2(64,72);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture=game.art.get(str(h.get("sprite",id))+"_idle",game.art.get(id+"_idle"));col.add_child(art)
  game.presentation.label(col,str(h.name),23)
  preload("res://scripts/hero_stat_bars.gd").add_to(col,h)
  if h.has("studio_project"):game.presentation.label(col,"Checked custom budget" if preload("res://scripts/studio_balance.gd").hero_checked(h.studio_project) else "Experimental custom • private games",16)
  for slot in ["primary","secondary","special"]:
   var a:Dictionary=h.get(slot,{})
   game.presentation.label(col,slot.capitalize()+" • "+str(a.get("name","Unknown")),19)
   game.presentation.label(col,str(a.get("style","melee")).replace("_"," ").capitalize()+" • damage "+str(a.get("damage",0))+" • cooldown "+str(a.get("cooldown",0))+"s\nReach "+str(a.get("range",0))+" • area "+str(a.get("radius",0))+" • heal "+str(a.get("heal",0)),15)
  for slot in ["primary","secondary","special"]:
   var a:Dictionary=h.get(slot,{})
   if float(a.get("charge",0))>0:game.presentation.label(col,slot.capitalize()+" charge • "+str(a.charge)+"s",14)
  game.presentation.label(col,"Passive • "+str(h.get("passive","None")),16)
  if h.has("studio_project"):
   for t in h.studio_project.techniques:game.presentation.label(col,"Mastery: "+str(t.name)+" → "+str(t.slot),15)
  else:
   for key in ["technique","final_technique"]:game.presentation.label(col,"Mastery • "+str(h.get("mastery",{}).get(key,{}).get("name","See Mastery journal")),15)
