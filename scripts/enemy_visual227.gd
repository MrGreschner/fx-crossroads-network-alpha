extends RefCounted
## V229: registered/padded V220/V227/V228 frames. Canvas compensation preserves body size.
## Hollow Warlock alone has an intentional 20% visual enlargement.
## No hitbox, reach, damage, movement or physics changes. No per-frame texture work.
const FACTORS={"glass_queen":1.5489125,"honey_beetle":1.25,"seed_blossom":1.25,"amber_hornet":1.4285713,"royal_nurse":1.2585037,"yellow_bus":1.5340913,"pencil_scrapper":1.2414962,"backpack_biter":1.3333337,"paper_sprite":1.2962962,"lesson_warden":1.3888888,"recess_ringleader":1.35,"sun_sentinel":1.6477275,"sunbeam_cantor":1.45,"saffron_hopper":1.25,"frostling":1.3425925,"ice_archer":1.25,"glacier_hound":1.25,"snow_oracle":1.2797625,"cryowarden":1.3181813,"confluence_heart":1.4795912,"sluice_crab":1.32353,"coil_singer":1.25,"glass_mender":1.25,"cartographer":1.3888888,"inkfin":1.6239313,"foldwing":1.9270837,"crease_sentry":1.3068188,"flintroot":1.5700487,"burrowfang":2.0164612,"shardspitter":1.4120375,"fusehare":1.2698413,"rootwarden":1.5608462,"echo_bat":1.555555,"sap_nurse":1.25,"mirror_marquis":1.27193,"mask_duelist":1.25,"prism_acolyte":1.27193,"lunar_usher":1.25,"velvet_dancer":1.25,"moonlit_puppeteer":1.328125,"bloomtail_regent":1.3425925,"petal_ducker":1.2723213,"briar_tail":1.25,"nectar_keeper":1.25,"silk_spinner":1.25,"dewcap_guard":1.25,"hourglass_hart":1.25731,"pendulum_moth":1.3,"tick_acorn":1.27193,"gearhorn_runner":1.25,"ratchet_keeper":1.26894,"spark_scarab":1.25,"bellwork_colossus":1.27193,"hall_monitor":1.2421388,"culture_blob":1.6129038,"lunchline_leviathan":1.463415,"bramble":1.25,"archer":1.25,"lantern_moth":1.25,"imp":1.25,"warlock":1.5,"cinderling":1.25,"bramble_boss":1.25}
const SUFFIXES=["_idle","_walk1","_walk2","_attack2","_attack","_special","_0","_1","_2"]
static var key_factors:Dictionary={}
static func adjusted(key:String,rect:Rect2)->Rect2:
 var scale:float=float(key_factors.get(key,-1.0))
 if scale<0:
  var kind=key
  for suffix in SUFFIXES:
   if key.ends_with(suffix):kind=key.trim_suffix(suffix);break
  scale=float(FACTORS.get(kind,1.0));key_factors[key]=scale
 if scale==1.0:return rect
 var growth:Vector2=rect.size*(scale-1.0)
 return Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*scale)
static func mark(adventure:Node,enemy:Dictionary,duration:float=.45)->void:
 var kind=str(enemy.get("sprite",enemy.get("type","")))
 if kind=="boss" and not adventure.arcade:kind=str(adventure.game.region.get("boss_sprite",""))
 if kind in FACTORS:enemy.v143_pose=adventure.newcomers.clock+duration
