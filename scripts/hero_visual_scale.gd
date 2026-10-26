extends RefCounted
## Visual correction only. Never feed these factors into reach, collision or damage.
## All poses use the same factor; original transparent gutters and small effects remain intact.
## Anchor is the six-pose atlas foot baseline (74/80), not the canvas bottom.
const WORLD_FACTOR=1.10
# Additional corrections for the four visibly undersized heroes.
const SIZE_ADJUSTMENTS={"stormscribe":1.10,"sunflower":1.10,"snowman":1.10,"aurel":1.20,"little_menace":0.534375}
const PORTRAIT_FACTORS={"medic":1.09375,"navigator":1.186441,"wanderlight":1.09375,"ripplejaw":1.277778,"hearthwarden":1.162281,"snail":1.206897,"kite":1.09375,"tidewright":1.186441,"cantor":1.272727,"shuttle":1.1875,"regent":1.09375,"apiary":1.071429,"mantis":1.108871,"recess":1.108871,"votary":1.144068,"teacher":1.104167,"lumen":1.09127,"briar":1.09375,"hollow_rider":1.074219,"hazel_hex":1.09375,"echo_dancer":1.035156,"little_menace":0.70625,"hearth_herald":1.09375}
const FACTORS={"sunflower":1.2653,"snowman":1.1786,"drum":1.9231,"harbor":1.5429,"magnet":1.5484,"pippa":1.4595,"spindle":1.2381,"patch":1.4118,"bracken":1.3023,"aurel":1.3023,"rune_duelist":1.2364,"garrick":1.36,"nera":1.193,"twisterspell":1.0303,"baseball":1.1724,"dawnblade":1.283,"stormscribe":1.193,"bailiff":1.3469,"tempo":1.0625,"quill":1.1923,"cindervane":1.2917,"tova":1.082,"dunecook":1.1186,"dustmarshal":1.1333,"wick":1.2,"cobbleclaw":1.4857,"goalie":1.3077,"golfer":1.0476,"soccer":1.3529,"welder":1.193,"velvetwing":1.1923,"gopher":1.0943,"nullweaver":1.193,"kage":1.0968,"agent":1.0625,"thistlebond":1.2444,"chronicle":1.193,"ferryman":1.1525,"mosaic":1,"vesper":1.0794,"morrow":1.0462,"teapot":1.1739,"rook":1.0625,"beaver":1.1111,"iris":1.0462,"robot":1.0462,"cloudloom":1.1333,"cairnheart":1.1228,"caelum":1.0794,"dustdevil":0.9524,"merrymask":1.0462,"medic":1.145833,"navigator":1.200565,"wanderlight":1.132812,"ripplejaw":1.277778,"hearthwarden":1.162281,"snail":1.241685,"kite":1.193182,"tidewright":1.25,"cantor":1.27451,"shuttle":1.395349,"regent":1.230469,"apiary":1.071429,"mantis":1.108871,"recess":1.108871,"votary":1.144068,"teacher":1.104167,"lumen":1.09127,"briar":1.171875,"hollow_rider":1.074219,"hazel_hex":1.210938,"echo_dancer":1.035156,"little_menace":1.171875,"hearth_herald":1.191406}
static func portrait_factor(sprite:String)->float:return float(PORTRAIT_FACTORS.get(sprite,FACTORS.get(sprite,1.0)))
static func factor(sprite:String)->float:return WORLD_FACTOR*float(SIZE_ADJUSTMENTS.get(sprite,1.0))*float(FACTORS.get(sprite,1.0))
static func apply(sprite:String,rect:Rect2)->Rect2:
 var amount:=factor(sprite)
 var growth:=rect.size*(amount-1.0)
 return Rect2(rect.position-growth*Vector2(.5,.925),rect.size*amount)
