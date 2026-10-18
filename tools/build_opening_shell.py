"""Build the self-contained browser opening from real game art and code-native SVG."""
from pathlib import Path
import base64,math,re
root=Path(__file__).resolve().parents[1]
def data(path):
 p=root/path;mime='font/ttf' if p.suffix=='.ttf' else 'image/svg+xml' if p.suffix=='.svg' else 'image/png'
 return 'data:'+mime+';base64,'+base64.b64encode(p.read_bytes()).decode()
def img(path,x,y,w,h,cls=''):
 return f'<image class="{cls}" href="{data(path)}" x="{x}" y="{y}" width="{w}" height="{h}"/>'
def actor(id,sprite,x,y,w,h,attack=False):
 text=f'<g id="{id}">'+img(f'assets/{sprite}_walk1.png',x,y,w,h,'pose first')+img(f'assets/{sprite}_walk2.png',x,y,w,h,'pose second')
 if attack:text+=img(f'assets/{sprite}_attack.png',x,y,w,h,'pose attack')
 return text+'</g>'
def crew_symbol():
 guard=(root/'assets/guard_melee.svg').read_text();body=re.search(r'<svg[^>]*>(.*)</svg>',guard).group(1)
 # The game's ram guard becomes a miner/mason; omit the weapon while on building duty.
 body=body.replace('<path d="M38 15h4v24h-4z" fill="#e9e4cc"/>','').replace('<path d="M35 34h10v4H35z" fill="#e9b768"/>','')
 miner=body.replace('#66a8c9','#ae8956').replace('#293f61','#6c563c').replace('#b9c7cf','#d2a45e')
 miner+='<rect x="22" y="7" width="7" height="6" fill="#f5d789"/><rect x="24" y="8" width="3" height="3" fill="#fff2b6"/>'
 return '<symbol id="ram-guard" viewBox="0 0 48 56">'+body+'</symbol><symbol id="ram-miner" viewBox="0 0 48 56">'+miner+'</symbol>'
# Alternating pillar courses, then balanced arch stones, then the final keystone.
blocks=[]
for level in range(5):
 for side in range(2):
  x=484 if side==0 else 742;y=500-level*42
  blocks.append(f'<g class="arch-stone"><rect x="{x}" y="{y}" width="54" height="40" rx="3" fill="url(#stone)" stroke="#16252d" stroke-width="3"/><path d="M{x+5} {y+5}h44M{x+5} {y+5}v26" fill="none" stroke="#a1b5ad" opacity=".5" stroke-width="2"/><path d="M{x+7} {y+34}h40" stroke="#283b42" stroke-width="3"/></g>')
for n in [0,8,1,7,2,6,3,5,4]:
 a=math.pi-n*math.pi/9;b=math.pi-(n+1)*math.pi/9
 pts=[(640+rad*math.cos(t),330-rad*math.sin(t)) for rad,t in [(156,a),(156,b),(100,b),(100,a)]]
 path='M'+'L'.join(f'{x:.2f} {y:.2f}' for x,y in pts)+'Z'
 blocks.append(f'<g class="arch-stone"><path d="{path}" fill="url(#keystone)" stroke="#16252d" stroke-width="3"/><path d="M{pts[0][0]:.2f} {pts[0][1]:.2f}L{pts[1][0]:.2f} {pts[1][1]:.2f}" stroke="#b8c8b6" stroke-width="3" opacity=".7"/></g>')
stars=''.join(f'<circle cx="{45+(n*149)%1190}" cy="{25+(n*67)%220}" r="{.7+(n%3)*.3}" fill="#d0e3dd" opacity="{.16+(n%5)*.08}"/>' for n in range(36))
runes=''.join(f'<path d="M{491 if side==0 else 756} {510-level*42}h18m-9 -7v14" fill="none" stroke="#c9debd" stroke-width="2" opacity=".6"/>' for side in range(2) for level in range(4))
css='''html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#071720;color:#efe5c9;font-family:system-ui,sans-serif}#canvas{display:block;width:100%;height:100%;outline:none}#loading{position:fixed;inset:0;z-index:100;overflow:hidden;background:#071720;transition:opacity .24s linear}#loading.done{opacity:0;pointer-events:none}.stage{position:absolute;inset:0;transition:opacity .5s ease}.scene{width:100%;height:100%;display:block}#cinematic{opacity:0;pointer-events:none;background:#0b2636}.display{font-family:CrossroadsDisplay,Georgia,serif}.pixel{image-rendering:pixelated}.pose.second,.pose.attack{opacity:0}.arch-stone{opacity:0}#load-status{font:24px CrossroadsDisplay,Georgia,serif;fill:#e9d5a2}#load-detail{font:13px system-ui,sans-serif;fill:#92bdbb;letter-spacing:.6px}.work-title{font-size:47px;letter-spacing:3px;fill:#eddbb1}.work-subtitle{font:13px system-ui,sans-serif;letter-spacing:4px;fill:#7daeb3}.intro-title{font:94px CrossroadsDisplay,Georgia,serif;fill:url(#title-gold);letter-spacing:3px}.intro-subtitle{font:27px system-ui,sans-serif;letter-spacing:7px;fill:#e7c780}.intro-tag{font:14px system-ui,sans-serif;letter-spacing:2px;fill:#b4d7d0}.night .sun-disc{fill:#d0e5f4}.night #sun-rays{display:none}.moon-cut{display:none}.night .moon-cut{display:block}.night .sun-glow{fill:#abcce5}.orbit{animation:orbit 7s linear infinite;transform-origin:640px 373px}.breath{animation:breath 2.4s ease-in-out infinite}.sparkle{animation:breath 2.7s ease-in-out infinite}.water-ripple{animation:ripple 3.2s ease-out infinite;transform-box:fill-box;transform-origin:center}@keyframes orbit{to{transform:rotate(360deg)}}@keyframes breath{50%{opacity:.35}}@keyframes ripple{0%{opacity:.4;transform:scaleX(.7)}100%{opacity:0;transform:scaleX(1.6)}}#error{position:absolute;left:12%;right:12%;bottom:9%;font-size:13px;text-align:center;color:#ffd7bd;overflow-wrap:anywhere}#retry{display:none;position:absolute;left:50%;bottom:3%;transform:translateX(-50%);padding:11px 22px;background:#173b45;color:#f4dfaf;border:1px solid #8bb6b6;border-radius:7px;font:16px system-ui}#loading.failed #load-status,#loading.failed #load-detail{visibility:hidden}#loading.failed .stage{transition:none}@media(prefers-reduced-motion:reduce){.orbit,.breath,.sparkle,.water-ripple{animation:none}.stage,#loading{transition:none}}'''
commondefs='''<linearGradient id="stone" x2=".8" y2="1"><stop stop-color="#8a9d9a"/><stop offset=".45" stop-color="#526b73"/><stop offset="1" stop-color="#314b57"/></linearGradient><linearGradient id="keystone" x2=".4" y2="1"><stop stop-color="#9caaa0"/><stop offset=".4" stop-color="#607a7e"/><stop offset="1" stop-color="#354e5c"/></linearGradient><linearGradient id="work-sky" x2="0" y2="1"><stop stop-color="#06151f"/><stop offset="1" stop-color="#22464b"/></linearGradient><radialGradient id="amber"><stop stop-color="#ffc06b" stop-opacity=".3"/><stop offset="1" stop-color="#ffc06b" stop-opacity="0"/></radialGradient><radialGradient id="aqua"><stop stop-color="#9df9e0" stop-opacity=".6"/><stop offset=".4" stop-color="#65e6dd" stop-opacity=".2"/><stop offset="1" stop-color="#65e6dd" stop-opacity="0"/></radialGradient><radialGradient id="portal-fill"><stop stop-color="#d4ffe6"/><stop offset=".25" stop-color="#71decf"/><stop offset=".67" stop-color="#297c9f"/><stop offset="1" stop-color="#132e5a"/></radialGradient><clipPath id="portal-clip"><path d="M540 540V330A100 100 0 0 1 740 330V540Z"/></clipPath>'''
work=f'''<div id="worksite" class="stage"><svg class="scene" viewBox="0 0 1280 720" preserveAspectRatio="xMidYMid meet" aria-hidden="true"><defs>{commondefs}{crew_symbol()}</defs>
<rect width="1280" height="720" fill="url(#work-sky)"/>{stars}
<path d="M0 395L100 328 171 358 260 262 355 346 415 314 485 367 540 319 622 386 710 331 792 345 884 260 977 331 1050 301 1165 362 1280 314V720H0Z" fill="#102b34"/>
<path d="M0 438Q160 357 315 430T640 412T960 407T1280 423V720H0Z" fill="#17353a"/>
<path d="M0 532Q160 472 330 529T640 535T990 517T1280 535V720H0Z" fill="#10272e"/>
<ellipse cx="640" cy="565" rx="403" ry="95" fill="#152f35"/><path d="M484 565L795 565 984 720H288Z" fill="#284449" opacity=".5"/>
<g stroke="#537071" stroke-width="2" opacity=".35"><path d="M466 593H826M420 633H881M357 683H947M563 565L515 720M641 565V720M719 565L771 720"/></g>
<text class="display work-title" x="640" y="78" text-anchor="middle">CROSSROADS</text><text class="work-subtitle" x="640" y="105" text-anchor="middle">REALMS BEYOND</text><path d="M465 122H610M670 122H815" stroke="#d7bd80" opacity=".5"/>
<ellipse cx="640" cy="552" rx="187" ry="21" fill="#020b12" opacity=".5"/>
<path d="M540 540V330A100 100 0 0 1 740 330V540Z" fill="#071820"/>
<ellipse id="boot-light" cx="640" cy="395" rx="257" ry="266" fill="url(#aqua)" opacity="0"/>
<g id="portal-aperture"><g id="portal-energy" clip-path="url(#portal-clip)" opacity="0"><rect x="535" y="225" width="210" height="320" fill="url(#portal-fill)"/>
<g id="portal-flow" fill="none" stroke="#c1ffe6" stroke-width="3" opacity=".45"><ellipse cx="640" cy="379" rx="82" ry="126"/><path d="M593 292C759 258 715 484 595 458C511 439 584 338 687 353C746 364 674 430 621 407C584 389 630 362 652 377"/></g>
<path d="M640 252L645 367 697 386 647 397 640 512 633 398 581 385 633 372Z" fill="#deffe9" opacity=".38"/></g></g>
<g clip-path="url(#portal-clip)"><g id="boot-arcs" fill="none" stroke="#69dacc" stroke-width="4" stroke-linecap="round" opacity="0"><ellipse cx="640" cy="373" rx="79" ry="117" stroke-dasharray="54 160 75 99"/><ellipse cx="640" cy="373" rx="60" ry="92" stroke-dasharray="33 240" stroke-width="2"/></g><path id="boot-seam" d="M640 278L634 333 646 366 637 409 642 493" stroke="#99f4d8" stroke-width="2" fill="none" opacity="0"/></g>
<g id="scaffold" stroke="#695c48" stroke-width="8" fill="none"><path d="M451 545V211M474 545V193M806 545V192M839 545V215M439 262H483M796 261H852M439 413H483M796 414H852"/><path d="M452 519L474 456 452 393 474 330 452 267M807 516L838 452 807 389 838 326 807 263" stroke-width="3"/><path d="M458 187H838" stroke="#998165" stroke-width="9"/></g>
<g id="keystone-rope" stroke="#b5a17a" stroke-width="2" fill="none"><path d="M640 128V203M640 128H804V460"/><circle cx="804" cy="185" r="11" fill="#2a3636" stroke="#ab946b"/><g id="pulley-wheel"><path d="M794 185H814M804 175V195"/></g></g>
{''.join(blocks)}<g id="foundation-rune">{runes}</g>
<path id="portal-rim" d="M541 538V330A99 99 0 0 1 739 330V538" fill="none" stroke="#9cf1d8" stroke-width="3" opacity="0"/>
<g fill="#71817c" stroke="#273c43" stroke-width="2"><path d="M276 540l32 -14 27 15 -12 17h-49zM300 526l22 -19 23 13 -10 23zM893 548l18 -23 34 8 15 21zM921 527l16 -20 27 14 -20 13z"/></g>
<ellipse cx="330" cy="507" rx="120" ry="125" fill="url(#amber)"/><ellipse cx="936" cy="474" rx="135" ry="155" fill="url(#amber)"/>
<g stroke="#56483b" stroke-width="6"><path d="M275 548V425M946 548V397"/></g><g fill="#f5ce7c" stroke="#ba975e" stroke-width="3"><rect x="264" y="418" width="22" height="31" rx="3"/><rect x="935" y="390" width="22" height="31" rx="3"/></g>
<g class="crew pixel"><use href="#ram-miner" x="299" y="455" width="72" height="84"/><g id="miner-tool"><path d="M339 497l-27 -31" stroke="#9e7951" stroke-width="5"/><path d="M298 473q11 -16 29 -17" fill="none" stroke="#a7bbc1" stroke-width="5"/></g></g>
<g id="mining-dust" fill="#b3a487" opacity="0"><circle cx="306" cy="526" r="3"/><circle cx="318" cy="521" r="2"/><circle cx="300" cy="518" r="1.5"/></g>
<g class="crew pixel">{actor('hauler','ram',381,459,77,88)}<path d="M394 519h52l-3 21h-46Z" fill="#705d43" stroke="#372f2c" stroke-width="3"/><path d="M402 518v-17h31l7 17" fill="url(#stone)" stroke="#263c43" stroke-width="3"/><g id="cart-wheel-a" stroke="#ab8f65" stroke-width="2"><circle cx="389" cy="548" r="9" fill="#202f32"/><path d="M380 548h18m-9 -9v18"/></g><g id="cart-wheel-b" stroke="#ab8f65" stroke-width="2"><circle cx="436" cy="548" r="9" fill="#202f32"/><path d="M427 548h18m-9 -9v18"/></g></g>
<path d="M787 505H866M795 505V544M855 505V544" stroke="#79654a" stroke-width="6"/><g class="crew pixel"><use href="#ram-miner" x="791" y="424" width="69" height="81"/><g id="mason-tool"><path d="M821 454l-27 -17" stroke="#b48f63" stroke-width="5"/><path d="M785 433l14 -8 10 14 -14 8Z" fill="#91a3a7" stroke="#32474f" stroke-width="2"/></g></g>
<g class="crew pixel"><use href="#ram-guard" x="891" y="461" width="72" height="84"/><path d="M901 504l-39 -37" stroke="#b9a27a" stroke-width="3"/></g>
<g class="crew pixel">{actor('foreman','ram',222,487,55,63)}<path d="M236 513h28v17h-28Z" fill="#43656d"/><path d="M239 516l20 4 -3 9 -18 -3Z" fill="#b9c3a7"/></g>
<rect x="479" y="539" width="322" height="14" rx="3" fill="url(#stone)" stroke="#1b323b" stroke-width="3"/>
<g class="breath"><circle cx="640" cy="588" r="3" fill="#8be9d6"/></g><text id="load-status" x="640" y="627" text-anchor="middle">Laying the foundations…</text><text id="load-detail" x="640" y="655" text-anchor="middle">Preparing your adventure</text>
<rect id="opening-wash" width="1280" height="720" fill="#c4f5dd" opacity="0"/>
</svg></div>'''
intro=f'''<div id="cinematic" class="stage" aria-hidden="true"><svg class="scene" viewBox="0 0 1280 720" preserveAspectRatio="xMidYMid meet" aria-hidden="true"><defs>
<linearGradient id="intro-sky" x2="0" y2="1"><stop stop-color="#0d293b"/><stop offset=".6" stop-color="#377079"/><stop offset="1" stop-color="#9ab5a0"/></linearGradient><radialGradient id="intro-light"><stop stop-color="#fbd994"/><stop offset=".5" stop-color="#d9ae78" stop-opacity=".55"/><stop offset="1" stop-color="#e1b978" stop-opacity="0"/></radialGradient><linearGradient id="title-gold" x2="0" y2="1"><stop stop-color="#fff0c9"/><stop offset=".38" stop-color="#eedaac"/><stop offset=".5" stop-color="#f9edca"/><stop offset=".8" stop-color="#d5b574"/><stop offset="1" stop-color="#ae8954"/></linearGradient><linearGradient id="water" x2="0" y2="1"><stop stop-color="#397d82"/><stop offset="1" stop-color="#0a2e40"/></linearGradient><radialGradient id="intro-vignette"><stop offset=".35" stop-color="#071923" stop-opacity="0"/><stop offset="1" stop-color="#04111c" stop-opacity=".8"/></radialGradient>
</defs><rect width="1280" height="720" fill="url(#intro-sky)"/><ellipse id="intro-warmth" cx="640" cy="365" rx="850" ry="590" fill="url(#intro-light)" opacity="0"/><rect id="intro-cool" width="1280" height="720" fill="#102b4a" opacity=".5"/>
<g opacity=".55">{stars}</g>
<g id="sunbeams" fill="#ffe8b0" opacity="0"><path d="M0 0L-190 720H-30ZM0 0L50 720H245ZM0 0L-520 720H-320ZM0 0L335 720H570Z"/></g>
<g id="sun" transform="translate(110 360)"><circle class="sun-glow" r="130" fill="#fbd37c" opacity=".025"/><circle class="sun-glow" r="91" fill="#fbd37c" opacity=".04"/><circle class="sun-glow" r="61" fill="#fbd37c" opacity=".07"/><circle class="sun-glow" r="38" fill="#fbd37c" opacity=".14"/><circle class="sun-disc" r="24" fill="#ffe1a2"/><circle class="moon-cut" cx="9" cy="-7" r="21" fill="#17354a"/><g id="sun-rays" stroke="#ffdb91" stroke-width="2">{''.join(f'<path d="M{math.cos(n*math.pi/6)*31:.2f} {math.sin(n*math.pi/6)*31:.2f}L{math.cos(n*math.pi/6)*39:.2f} {math.sin(n*math.pi/6)*39:.2f}"/>' for n in range(12))}</g></g>
<path d="M0 418L95 314 176 370 250 262 338 350 394 299 502 402 590 339 700 398 788 312 868 366 977 262 1074 352 1150 309 1280 395V720H0Z" fill="#24474f" opacity=".7"/>
<path d="M0 482Q159 392 316 461T640 452T960 452T1280 472V720H0Z" fill="#244b50"/>
<path d="M0 546Q145 451 300 521T640 508T968 521T1280 530V720H0Z" fill="#1a3d43"/>
<g fill="#16373e" opacity=".85">{''.join(f'<path d="M{x} 578v-98m-27 62l27 -54 27 54m-21 -26l21 -55 21 55" stroke="#173940" stroke-width="7"/>' for x in [53,121,196,1084,1151,1224])}</g>
<path d="M0 635Q170 591 335 627T640 625T973 627T1280 623V720H0Z" fill="url(#water)"/>
<g id="intro-reflection" stroke="#e5dba9" stroke-width="2" opacity=".2"><path d="M510 655H770M548 667H732M580 680H700M608 693H672"/></g>
<path d="M321 560L388 531 882 531 959 560 930 591 348 591Z" fill="#315257" stroke="#658482" stroke-width="2"/><path d="M348 591L930 591 915 602H367Z" fill="#17343c"/><path d="M394 541H866M500 543l-15 38M640 543v38M780 543l15 38" stroke="#7c9990" opacity=".3"/>
<g id="intro-emblem" transform="translate(640 240)"><circle r="37" fill="#12313f" opacity=".7"/><circle r="33" fill="none" stroke="#c8b077" stroke-width="1.5"/><path d="M0 -28L13 0 0 28 -13 0Z" fill="#e3ce92"/><path d="M0 -27A27 27 0 1 1 -22 17" fill="none" stroke="#91d6cd" stroke-width="3"/><path d="M-70 0H-44M44 0H70" stroke="#d1b979" stroke-width="2"/></g>
<g id="title-block"><text id="intro-title" class="intro-title" x="640" y="365" text-anchor="middle">CROSSROADS</text><text id="intro-title-glint" class="intro-title" x="640" y="365" text-anchor="middle" fill="#fff8df" opacity="0">CROSSROADS</text><text class="intro-subtitle" x="640" y="407" text-anchor="middle">REALMS BEYOND</text><path d="M340 428H611M669 428H940" stroke="#e3c17d" stroke-width="1.5" opacity=".8"/><path d="M640 422l6 6 -6 6 -6 -6Z" fill="#c4ba82"/><text class="intro-tag" x="640" y="460" text-anchor="middle">FIND YOUR PATH. CREATE WHAT’S NEXT.</text></g>
<g class="pixel"><ellipse cx="600" cy="576" rx="34" ry="7" fill="#08202b" opacity=".5"/><ellipse cx="718" cy="576" rx="32" ry="7" fill="#08202b" opacity=".5"/>{actor('ram-actor','ram',558,480,84,96,True)}{actor('foe-actor','bramble',680,488,76,86)}<g id="impact" stroke="#ffe09c" stroke-width="3" opacity="0"><path d="M700 512l14 -12M711 531l17 2M692 547l7 14M687 507l-2 -14"/></g></g>
<image id="intro-fish" href="{data('assets/fishing/sunspot_koi.svg')}" data-night="{data('assets/fishing/reedlight_minnow.svg')}" x="601" y="633" width="78" height="44"/><g id="fish-splash" fill="none" stroke="#a1dfd4" opacity="0"><path d="M802 660q-12 -23 -21 -13M810 660q8 -28 19 -16M818 664q14 -9 20 -4" stroke-width="2"/></g><ellipse class="water-ripple" cx="457" cy="661" rx="23" ry="3" fill="none" stroke="#9bd4ca"/><ellipse class="water-ripple" cx="812" cy="662" rx="25" ry="3" fill="none" stroke="#9bd4ca"/>
<g class="sparkle" fill="#e8dbb1" opacity=".5"><circle cx="315" cy="480" r="1.5"/><circle cx="970" cy="494" r="1.8"/><circle cx="350" cy="602" r="1.2"/><circle cx="931" cy="597" r="1.3"/></g>
<rect width="1280" height="720" fill="url(#intro-vignette)" pointer-events="none"/><text x="640" y="701" text-anchor="middle" style="font:11px system-ui;letter-spacing:2px;fill:#8cafac">A LIVING TOWN • WATERS TO DISCOVER</text><rect id="intro-veil" width="1280" height="720" fill="#071720" opacity="0"/>
</svg></div>'''
# Keep portrait letterboxing clean: long rays and scenery stop at the scene bounds.
for stage_name in ['work','intro']:
 scene=work if stage_name=='work' else intro
 clip=f'<clipPath id="{stage_name}-frame"><rect width="1280" height="720"/></clipPath>'
 scene=scene.replace('</defs>',clip+'</defs><g clip-path="url(#'+stage_name+'-frame)">',1).replace('</svg></div>','</g></svg></div>')
 if stage_name=='work':work=scene
 else:intro=scene
font=data('assets/fonts/CrossroadsDisplay.ttf');icon=data('assets/crossroads_emblem.svg')
html=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"><title>Crossroads: Realms Beyond • v180 preview</title><style>@font-face{{font-family:CrossroadsDisplay;src:url('{font}')}}{css}</style>$GODOT_HEAD_INCLUDE<link rel="icon" href="{icon}"></head><body><canvas id="canvas" tabindex="0">Your browser needs WebGL 2 to run Crossroads: Realms Beyond.</canvas><div id="loading" role="progressbar" aria-label="Building the Crossroads portal; loading game" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" data-phase="building">{work}{intro}<div id="error" role="alert"></div><button id="retry" type="button" onclick="location.reload()">Try loading again</button></div><script>{(root/'web/opening.js').read_text()}</script><script src="index.js" onerror="window.fxSunLoading.error('The game engine could not be downloaded. Please try again.')"></script><script>(()=>{{try{{const GODOT_CONFIG=$GODOT_CONFIG;const engine=new Engine(GODOT_CONFIG);window.fxSunLoading.engineGate.then(()=>engine.startGame({{onProgress(current,total){{window.fxSunLoading.progress(current,total);}}}})).then(()=>window.fxSunLoading.started()).catch(error=>{{window.fxSunLoading.error(error);console.error(error);}});}}catch(error){{window.fxSunLoading.error(error);}}}})();</script></body></html>'''
(root/'web/town_shell.html').write_text(html)
print('Opening shell built:',len(html),'bytes')
