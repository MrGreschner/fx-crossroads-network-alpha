extends Node2D
## Diagnostics change slowly; retain their draw commands between updates.
var game:Node2D
var elapsed=1.0
var rebuilds=0
var lines:Array=[]
var width=0.0
var height=0.0
func _ready()->void:z_index=5
func sync(delta:float)->void:
 visible=game.started and not game.media.clean_view and not game.media.capturing and not (game.session_menu!=null and game.session_menu.page in ["main","clear","options"])
 if not visible:return
 elapsed+=delta
 if elapsed<.25 and is_equal_approx(width,game.VIEW.x) and is_equal_approx(height,game.VIEW.y):return
 elapsed=0;width=game.VIEW.x;height=game.VIEW.y
 var profile:Dictionary=game.perf_latest.get("client_profile",{})
 lines=["Update p95 %.1f ms • draw commands p95 %.1f ms • F8: download performance report" % [profile.get("client_process",{}).get("p95_ms",0),profile.get("draw_commands",{}).get("p95_ms",0)],
 "T4.17 • server %s • RTT %d ms • sim %.2f ms • snapshot %.2f ms • input queue %d • authority %.0f Hz" % [game.server_build,game.metrics.rtt_ms,game.metrics.tick_ms,game.server_snapshot_ms,game.history.size(),game.server_hz],
 "T4.17 • remote buffer %d ms • buffer holds %d • FPS %d • F6 graphics: %s" % [maxf(0,game.world_view.latest_time-game.world_view.render_time)*1000,game.world_view.underruns,Engine.get_frames_per_second(),("Auto %d%%" % roundi(game.render_budget.scale_for(true)*100)) if game.balanced_graphics else "Full"]]
 if game.recovery_active:lines[0]="CONNECTION DELAY • waiting for fresh server state; controls paused during recovery"
 rebuilds+=1;queue_redraw()
func _draw()->void:
 var font=preload("res://assets/fonts/CrossroadsUI.ttf")
 draw_rect(Rect2(174,height-82,minf(width-180,1040),25),Color(0,.08,.12,.85))
 for n in lines.size():draw_string(font,Vector2(180,height-63+21*n),lines[n],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE if n==0 else Color("#a8ddf0"))
