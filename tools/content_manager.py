"""Validate installed content and optionally install one student ZIP.

Usage: python tools/content_manager.py --check
       python tools/content_manager.py --refresh
       python tools/content_manager.py --install student_submission.zip

Student ZIP entries use content/items/<id>.json, content/enemies/<id>.json,
content/characters/<id>.json, content/regions/<id>.json, and four named
poses in assets/ for new sprite submissions. Legacy two-frame art also works.
"""
import argparse
import json
import re
import shutil
import tempfile
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
KINDS = ("characters", "items", "enemies", "regions")
ID = re.compile(r"^[a-z][a-z0-9_]{1,31}$")
EFFECTS = {"heal", "invulnerable", "bonus_damage", "bonus_speed", "lifesteal", "shockwave", "haste", "armor", "block_boost", "bonus_health", "reflect", "cooldown", "bounty", "thorns", "revive"}
PASSIVES = {"heal_on_kill", "quick_primary", "life_steal", "guard", "quick_secondary"}
BEHAVIOURS = {"chase", "ranged", "burst_ranged", "summoner", "homing", "dual_ranged", "charger"}
ATTACK_STYLES = {"projectile", "melee", "punch", "scratch", "slash", "kick", "charge", "spin", "chain", "target_aoe", "block", "homing", "trap", "heal_wave"}
SPECIAL_STYLES = {"stomp", "beam", "stealth", "summon", "target_aoe", "block", "ice_wall", "trap", "heal_wave"}


def validate_scene(root, identifier, data, catalog):
    path = root / 'scenes' / 'realms' / f'{identifier}.tscn'
    require(data.get('scene') == f'res://scenes/realms/{identifier}.tscn', f'{identifier}: scene path must match its id')
    require(path.is_file(), f'{identifier}: missing visual realm scene')
    source = path.read_text(encoding='utf-8')
    require(len(source) < 900_000, f'{identifier}: scene too large')
    require(not re.search(r'Color\s*\(\s*["\']#', source), f'{identifier}: scene colors must use numeric Color(r, g, b, a) values')
    require(not re.search(r'(?m)^\s*(?:script\s*=|\[sub_resource|\[connection|\[editable)', source), f'{identifier}: submitted scene cannot contain scripts or embedded resources')
    paths = re.findall(r'\[ext_resource[^\n]*path="([^"]+)"[^\n]*\]', source)
    require(all(p.startswith('res://assets/') and p.endswith('.png') and (root / p[6:]).is_file() for p in paths), f'{identifier}: scenes may reference installed PNG assets only')
    nodes = {}
    current = None
    for line in source.splitlines():
        match = re.match(r'^\[node name="([^"]+)" type="([^"]+)" parent="([^"]+)"[^\]]*\]', line)
        if match:
            name, kind, parent = match.groups()
            require(kind in ('Node2D', 'Sprite2D', 'Polygon2D'), f'{identifier}: unsupported node type {kind}')
            current = (parent, name)
            nodes.setdefault(current, {})
        elif line.startswith('[node '):
            current = ('', 'root')
        elif line.startswith('['):
            current = None
        elif current is not None:
            if '=' in line:
                key, value = line.split('=', 1)
                nodes[current][key.strip()] = value.strip()
    for name in ('Spawn', 'ReturnGate', 'Merchant', 'Boss'):
        require(('Points', name) in nodes, f'{identifier}: Points/{name} marker required')
    for name in ('GroundPaint', 'Enemies', 'Obstacles', 'Points'):
        require(('.', name) in nodes, f'{identifier}: {name} container required')
    width, height = data['size']
    for (parent, name), props in nodes.items():
        if parent in ('Points', 'Enemies', 'Obstacles'):
            match = re.fullmatch(r'Vector2\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)', props.get('position', ''))
            require(match is not None, f'{identifier}: {name} needs a position')
            point([float(match[1]), float(match[2])], width, height, identifier + ' ' + name)
        if parent == 'Enemies':
            enemy_id = props.get('metadata/enemy_id', '').strip('"')
            require(enemy_id in catalog['enemies'], f'{identifier}: {name} has unknown enemy_id {enemy_id}')
        if parent == 'Obstacles':
            require(ID.fullmatch(props.get('metadata/kind', '').strip('"')) is not None, f'{identifier}: invalid obstacle kind')
            number(float(props.get('metadata/radius', '43.0')), 10, 90, identifier + ' obstacle radius')
        if parent == 'GroundPaint' and props.get('metadata/tile'):
            require(props.get('metadata/tile', '').strip('"') in ('grass', 'forest', 'ash', 'path', 'ice', 'space', 'quarantine'), f'{identifier}: unsupported ground tile')
    total = sum(parent == 'Enemies' for parent, name in nodes)
    require(total >= data['xp_per_level'] * 9, f'{identifier}: needs at least {data["xp_per_level"] * 9} enemy markers for level 10')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def number(value, low, high, label):
    require(type(value) in (int, float) and low <= value <= high, f"{label} must be between {low} and {high}")


def point(value, width, height, label):
    require(isinstance(value, list) and len(value) == 2, f"{label} must be [x, y]")
    number(value[0], 0, width, label + " x")
    number(value[1], 0, height, label + " y")


def validate(root):
    catalog = {}
    for kind in KINDS:
        folder = root / "content" / kind
        catalog[kind] = {}
        for path in sorted(folder.glob("*.json")):
            if kind == "regions" and path.stem == "town":
                continue
            data = json.loads(path.read_text(encoding="utf-8"))
            require(isinstance(data, dict), f"{path}: expected JSON object")
            identifier = data.get("id")
            require(isinstance(identifier, str) and ID.fullmatch(identifier), f"{path}: invalid id")
            require(path.stem == identifier, f"{path}: filename must match id")
            require(isinstance(data.get("name"), str) and data["name"].strip(), f"{path}: name required")
            catalog[kind][identifier] = data
    require("ram" in catalog["characters"], "ram character is required for Trial")
    require("grove" in catalog["regions"], "grove region is required for Trial")
    for identifier, data in catalog["characters"].items():
        number(data.get("max_health"), 30, 300, identifier + " max_health")
        number(data.get("speed"), 100, 400, identifier + " speed")
        number(data.get("run_cost", 0), 0, 100, identifier + " run_cost")
        require(data.get("passive_effect") in PASSIVES, f"{identifier}: unsupported passive_effect")
        if data.get("passive_effect") == "life_steal":
            number(data.get("passive_amount"), 0.01, 0.2, identifier + " passive_amount")
        for ability in ("primary", "secondary", "special"):
            stats = data.get(ability)
            require(isinstance(stats, dict), f"{identifier}: {ability} missing")
            require(stats.get("style") in (SPECIAL_STYLES if ability == "special" else ATTACK_STYLES),
                    f"{identifier}: unsupported {ability} style")
            number(stats.get("damage"), 1, 150, identifier + " " + ability + " damage")
            number(stats.get("cooldown"), 0.1, 30, identifier + " " + ability + " cooldown")
            number(stats.get("radius", stats.get("range")) if ability == "special" else stats.get("range"), 40, 700, identifier + " " + ability + " range")
            if ability != "special":
                number(stats.get("speed"), 50, 1200, identifier + " " + ability + " speed")
            if ability == "special" and stats["style"] == "stealth":
                number(stats.get("duration"), 0.5, 10, identifier + " stealth duration")
                number(stats.get("heal"), 1, 100, identifier + " stealth heal")
            if stats['style'] in ('melee', 'punch', 'scratch', 'slash', 'kick'):
                number(stats.get('arc_degrees', 105), 20, 180, identifier + ' melee arc_degrees')
                require(stats.get('visual', 'swing') in ('swing','scratch','bounce','punch','kick','slash'), f'{identifier}: unsupported melee visual')
            if stats['style'] == 'chain':
                number(stats.get('jumps'), 1, 5, identifier + ' chain jumps')
                require(type(stats['jumps']) is int, f'{identifier}: jumps must be whole number')
                number(stats.get('jump_range'), 70, 500, identifier + ' jump_range')
            if stats['style'] == 'target_aoe':
                number(stats.get('blast_radius'), 40, 250, identifier + ' blast_radius')
            if stats['style'] == 'block':
                number(stats.get('duration'), 0.5, 8, identifier + ' block duration')
                number(stats.get('reduction'), 0.1, 0.95, identifier + ' block reduction')
            if stats['style'] == 'summon':
                number(stats.get('duration'), 1, 25, identifier + ' summon duration')
                number(stats.get('count'), 1, 3, identifier + ' summon count')
                require(type(stats['count']) is int, f'{identifier}: summon count must be whole number')
                number(stats.get('minion_speed'), 100, 500, identifier + ' minion_speed')
                sprite = stats.get('minion_sprite')
                require(isinstance(sprite, str) and ID.fullmatch(sprite) and (root / 'assets' / (sprite + '.png')).is_file(), f'{identifier}: missing approved minion sprite')
        check_sprite(root, data.get("sprite"), identifier)
    for identifier, data in catalog["items"].items():
        require(data.get("effect") in EFFECTS, f"{identifier}: unsupported item effect")
        number(data.get("cost"), 1, 250, identifier + " cost")
        number(data.get("amount"), 1, 100, identifier + " amount")
        if data['effect'] in ('shockwave', 'haste'):
            number(data.get('radius') if data['effect'] == 'shockwave' else data.get('duration'), 1 if data['effect'] == 'haste' else 60, 250 if data['effect'] == 'shockwave' else 10, identifier + ' radius/duration')
        require(isinstance(data.get("description"), str), f"{identifier}: description required")
    for identifier, data in catalog["enemies"].items():
        require(data.get("behaviour") in BEHAVIOURS, f"{identifier}: unsupported behaviour")
        for key, high in (("health", 500), ("speed", 250), ("damage", 100), ("aggro_range", 1000)):
            number(data.get(key), 1, high, identifier + " " + key)
        check_sprite(root, data.get("sprite"), identifier)
        if data.get("behaviour") in ("ranged", "burst_ranged", "homing", "dual_ranged"):
            number(data.get("shot_speed"), 100, 800, identifier + " shot_speed")
            number(data.get("shot_cooldown"), 0.8, 10, identifier + " shot_cooldown")
        if data.get("behaviour") == "summoner":
            require(data.get('summon_type') in catalog['enemies'], f'{identifier}: unknown summoned enemy')
            number(data.get('summon_cooldown'), 1, 20, identifier + ' summon_cooldown')
            number(data.get('max_summons'), 1, 4, identifier + ' max_summons')
            require(type(data['max_summons']) is int, f'{identifier}: max_summons must be whole number')
    for identifier, data in catalog["regions"].items():
        size = data.get("size")
        require(isinstance(size, list) and len(size) == 2, f"{identifier}: size must be [width, height]")
        number(size[0], 1280, 12000, identifier + " width")
        number(size[1], 720, 5000, identifier + " height")
        if "boss_split" in data:
            require(type(data["boss_split"]) is bool, f"{identifier}: boss_split must be true or false")
        require(data.get("boss_secondary", "stomp") in ("stomp", "fireball", "sunburst", "frostburst", "seekerstorm", "sporeburst"),
                f"{identifier}: unsupported boss_secondary")
        if 'boss_sprite' in data:
            require(isinstance(data['boss_sprite'], str) and ID.fullmatch(data['boss_sprite']) and (root / 'assets' / (data['boss_sprite'] + '.png')).is_file(), f'{identifier}: missing boss_sprite')
        require(data.get("terrain", "forest") in ("grass", "forest", "ash", "ice", "space", "quarantine"), f"{identifier}: unsupported terrain")
        level_interval = data.get("xp_per_level", 2)
        number(level_interval, 2, 20, identifier + " xp_per_level")
        require(type(level_interval) is int, f"{identifier}: xp_per_level must be a whole number")
        validate_scene(root, identifier, data, catalog)
        number(data.get("boss_health", 350), 100, 2000, identifier + " boss_health")
    result = {kind: list(catalog[kind]) for kind in KINDS}
    result['characters'] = ['ram'] + [character for character in result['characters'] if character != 'ram']
    result["items"] = [item for item in ("potion", "shield", "hammer") if item in catalog["items"]] + [item for item in result["items"] if item not in ("potion", "shield", "hammer")]
    return result


def check_sprite(root, prefix, label):
    require(isinstance(prefix, str) and ID.fullmatch(prefix), f"{label}: invalid sprite name")
    four = [root / "assets" / f"{prefix}_{pose}.png" for pose in ("idle", "walk1", "walk2", "attack")]
    two = [root / "assets" / f"{prefix}_{frame}.png" for frame in (0, 1)]
    require(all(path.is_file() for path in four) or all(path.is_file() for path in two),
            f"{label}: provide idle/walk1/walk2/attack PNGs (or both legacy 0/1 PNGs)")
    for path in (four if all(path.is_file() for path in four) else two):
        require(path.is_file(), f"{label}: missing {path.name}")
        with Image.open(path) as image:
            require(image.format == "PNG" and 8 <= image.width <= 128 and 8 <= image.height <= 128,
                    f"{label}: sprite must be PNG, 8-128 pixels per dimension")


def write_manifest(root, catalog):
    path = root / "content" / "manifest.json"
    path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")


def install(root, archive):
    with tempfile.TemporaryDirectory(prefix="crossroads_content_") as temp:
        staging = Path(temp) / "project"
        shutil.copytree(root / "content", staging / "content")
        shutil.copytree(root / "assets", staging / "assets")
        shutil.copytree(root / 'scenes' / 'realms', staging / 'scenes' / 'realms')
        changes = []
        with zipfile.ZipFile(archive) as zf:
            files = [entry for entry in zf.infolist() if not entry.is_dir()]
            require(files and len(files) <= 40, "ZIP must contain 1-40 files")
            require(sum(entry.file_size for entry in files) <= 5_000_000, "ZIP exceeds 5 MB uncompressed")
            seen = set()
            for entry in files:
                rel = Path(entry.filename)
                require(rel not in seen, f"Duplicate ZIP entry: {entry.filename}")
                seen.add(rel)
                require(not entry.filename.startswith("/") and ".." not in rel.parts and "\\" not in entry.filename,
                        "ZIP has unsafe path")
                require(((entry.external_attr >> 16) & 0o170000) != 0o120000, "ZIP symlinks are not allowed")
                valid_json = len(rel.parts) == 3 and rel.parts[:2] in [("content", kind) for kind in KINDS] and rel.suffix == ".json"
                valid_art = len(rel.parts) == 2 and rel.parts[0] == "assets" and rel.suffix == ".png"
                valid_scene = len(rel.parts) == 3 and rel.parts[:2] == ('scenes', 'realms') and rel.suffix == '.tscn'
                require(valid_json or valid_art or valid_scene, f"Unsupported ZIP entry: {entry.filename}")
                require(ID.fullmatch(rel.stem) or (valid_art and ID.fullmatch(rel.stem.rsplit("_", 1)[0]) and rel.stem.endswith(("_0", "_1"))),
                        f"Bad filename: {entry.filename}")
                require(not (root / rel).exists(), f"Already exists: {entry.filename}; use a new id")
                target = staging / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(zf.read(entry))
                changes.append(rel)
        require(any(rel.suffix == ".json" for rel in changes), "Submission needs at least one JSON definition")
        catalog = validate(staging)
        for rel in changes:
            target = root / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(staging / rel, target)
        write_manifest(root, catalog)
        print("Installed", len(changes), "files; registry updated. Playtest before publishing.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--check", action="store_true")
    action.add_argument("--refresh", action="store_true")
    action.add_argument("--install", type=Path, metavar="STUDENT.zip")
    args = parser.parse_args()
    try:
        if args.install:
            install(ROOT, args.install)
        else:
            catalog = validate(ROOT)
            if args.check:
                existing = json.loads((ROOT / "content" / "manifest.json").read_text(encoding="utf-8"))
                require(existing == catalog, "Manifest is stale; run --refresh")
                print("Valid content:", {key: len(value) for key, value in catalog.items()})
            else:
                write_manifest(ROOT, catalog)
                print("Registry updated:", {key: len(value) for key, value in catalog.items()})
    except (ValueError, OSError, zipfile.BadZipFile, json.JSONDecodeError) as error:
        parser.exit(1, f"Content check failed: {error}\n")


if __name__ == "__main__":
    main()
