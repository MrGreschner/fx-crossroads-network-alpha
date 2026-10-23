extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const G=preload("res://scripts/garden_ui.gd")
class Award extends Control:
 var id=""
 func _draw()->void:
  draw_set_transform(size*.5,0,Vector2.ONE*.55)
  preload("res://scripts/ranked_cosmetic_art.gd").draw_icon(self,Vector2.ZERO,.65,id)
class Portrait extends Control:
 var texture:Texture2D
 func _draw()->void:
  if texture!=null:draw_texture_rect(texture,Rect2(Vector2.ZERO,size),false)
  else:
   var center=size*.5;draw_circle(center+Vector2(0,-9),7,Color("#6b858f"));draw_style_box(UI.box("#3e5b66","#6b858f",7,0),Rect2(center+Vector2(-12,0),Vector2(24,19)));draw_string(UI.FONT,center+Vector2(-4,11),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#d0dfe4"))
static func portrait(parent:Node,l:Node,id:String)->Control:
 var art=Portrait.new();art.name="RecordHeroPortrait";art.custom_minimum_size=Vector2(42,48);art.mouse_filter=Control.MOUSE_FILTER_PASS
 var spec:Dictionary=l.game.characters.get(id,{})
 var sprite=str(spec.get("sprite",id));art.texture=l.game.art.get(sprite+"_idle",l.game.art.get(sprite+"_0"));art.tooltip_text=str(spec.get("name","Hero not recorded • older result"));art.set_meta("record_hero",id);parent.add_child(art);return art
static func label(parent:Node,text:String,font_size:int,color:Color=Color("#edf4f6"))->Label:
 var n=Label.new();n.text=text;n.add_theme_font_size_override("font_size",font_size);n.add_theme_color_override("font_color",color);n.size_flags_horizontal=Control.SIZE_EXPAND_FILL;n.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;n.clip_text=true;n.tooltip_text=text;parent.add_child(n);return n
static func columns(parent:Node)->Array:
 var flow=HFlowContainer.new();flow.name="TopTenColumns";flow.add_theme_constant_override("h_separation",18);flow.add_theme_constant_override("v_separation",6);parent.add_child(flow)
 var cols=[]
 for side in 2:
  var col=VBoxContainer.new();col.name="Ranks1To5" if side==0 else "Ranks6To10";col.custom_minimum_size.x=280;col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",5);flow.add_child(col);cols.append(col)
 return cols
static func rank_row(parent:Node,rank:int)->HBoxContainer:
 var panel=PanelContainer.new();panel.name="RankRow"+str(rank);panel.custom_minimum_size.y=68;panel.add_theme_stylebox_override("panel",UI.box("#16343f" if rank<=5 else "#122e38","#355561",5,6));parent.add_child(panel)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",9);panel.add_child(row)
 var number=Label.new();number.text="%02d" % rank;number.custom_minimum_size.x=28;number.add_theme_font_size_override("font_size",17);number.add_theme_color_override("font_color",Color("#e8cb90") if rank<=5 else Color("#90adb8"));row.add_child(number);return row
static func hero_leaders(parent:Node,l:Node,rows:Array)->void:
 var cols=columns(parent)
 for i in 10:
  var row=rank_row(cols[i/5],i+1)
  if i>=rows.size():label(row,"Server update needed" if not l.community.snapshot.is_empty() and not l.community.compatible(l.community.snapshot) else "No record yet",16,Color("#7e9ca8"));continue
  var record:Dictionary=rows[i];var id=str(record.get("id",""));portrait(row,l,id)
  var detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(detail)
  label(detail,str(l.game.characters.get(id,{}).get("name",id)),19)
  label(detail,String.num(float(record.get("value",0)),0)+" total damage",15,Color("#b5d1d8"))
static func damage_leaders(parent:Node,rows:Array,award:String,empty_text:String="No named record yet")->void:
 var cols=columns(parent)
 for i in 10:
  var row=rank_row(cols[i/5],i+1)
  if i>=rows.size():label(row,empty_text,16,Color("#7e9ca8"));continue
  var record:Dictionary=rows[i];var detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(detail)
  var heading=HBoxContainer.new();detail.add_child(heading);label(heading,str(record.get("username","")),19)
  if i<5:
   var icon=Award.new();icon.name="TopFiveAward";icon.id=award;icon.custom_minimum_size=Vector2(32,32);icon.tooltip_text="Eternal Constellation • top 5 all-time damage" if award=="rank_all_damage" else "Vanguard Comets • top 5 weekly damage";icon.set_meta("award",award);heading.add_child(icon)
  label(detail,String.num(float(record.get("value",0)),0)+" damage",15,Color("#b5d1d8"))
static func run_row(parent:Node,l:Node,record:Dictionary,title:String,result:String)->void:
 var line=HBoxContainer.new();line.name="RunRecord";line.add_theme_constant_override("separation",10);line.custom_minimum_size.y=58;parent.add_child(line)
 var party=record.get("party",[])
 if party is Array and party.size()>1:
  var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(text);label(text,title+" • "+result,18)
  for member in party:
   var row=HBoxContainer.new();text.add_child(row);portrait(row,l,str(member.get("hero","")))
   var details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details)
   label(details,str(member.get("name","Player")),17);G.label(details,str(l.game.characters.get(str(member.get("hero","")),{}).get("name","Hero not recorded")),14)
  return
 var hero=str(record.get("hero",""));portrait(line,l,hero)
 var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(text)
 label(text,title+" • "+str(record.get("username","")),18)
 var hero_name=str(l.game.characters.get(hero,{}).get("name","Hero not recorded"))
 var description=G.label(text,result+"  •  "+hero_name,15);description.modulate=Color("#b9d3dc")
 if str(record.get("record_route",""))=="coop":G.label(text,"Partner not recorded in this older result",13)
