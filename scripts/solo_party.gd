extends RefCounted
## Device-owned solo simulation reuses the official combat and army systems.
static func begin(g:Node)->void:
 if not g.get_tree().root.has_meta("fx_solo_party"):return
 var plan:Dictionary=g.get_tree().root.get_meta("fx_solo_party");g.get_tree().root.remove_meta("fx_solo_party")
 g._set_mode(str(plan.mode));g.selected_hero=str(plan.hero);g.preferred_hero=g.selected_hero;g.bg_map=str(plan.get("bg_map","woodland"));g.bg_team_size=int(plan.get("bg_size",3));g.arena_map=str(plan.get("arena_map","sand"))
 for n in g.realm_picker.item_count:
  if str(g.realm_picker.get_item_metadata(n))==str(plan.get("realm","grove")):g.realm_picker.select(n)
 g.bot_plan=preload("res://scripts/arena_bots.gd").clean_plan(plan.get("bots",[]));g.bot_count=g.bot_plan.size();g.ai_difficulty=str(plan.get("difficulty","medium"))
 if not preload("res://network/party_rules.gd").allows_ai(g.mode):g.bot_plan=[];g.bot_count=0
 if g.mode=="arena" and g.bot_plan.is_empty():g.bot_plan=[{"hero":"npc_sable","team":1}];g.bot_count=1
 g._reset_connection();g.role="host";g.my_id="solo";g.host_id="solo";g.spectator_host=false;g.roster.assign([{"id":"solo","name":"You"}]);g._add_player("solo",0);g.teams.solo=int(plan.get("team",0))
 var teamed=g.mode=="battlegrounds" or g.mode=="arena" and str(plan.get("rule","ffa"))=="teams"
 g.rule_picker.select(1 if teamed else 0);g.pvp_rule="teams" if teamed else "ffa"
 g.bots.sync_lobby();g._start_match();g.control.hide()
 if g.mode=="arena" and g.arena_map=="crossroads":g.arena_world.test_enemies()
 if g.mode not in ["arena","battlegrounds"]:
  for id in g.teams:g.teams[id]=0
