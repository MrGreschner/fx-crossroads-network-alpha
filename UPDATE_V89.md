# FX Crossroads v89

Includes the previous release and 67 immediately playable heroes. Existing hero IDs and profile data remain compatible; roster numbers are now stored separately from display order so reordering does not change a favourite hero's number. No deployment has been performed.

## Clearer play and selection

The hero hall shows lore, stats, four colour-coded normal ability cards and then both mastery choices. Harbor Bell (62) follows Backbeat; Clockwork Apiarist (64) follows Morrow Shepherd, outside the first nine. Search still accepts their original numbers.

Lumen darts land for at most 1.5 seconds, fade and remain able to damage or heal on contact before disappearing. Harbor's buoy now uses a floating life ring and rope; Velvet's traffic order uses directional arrows and a stop marker. Velvet Bailiff walks at 180 rather than 210.

Damage reduction has a pulsing grey dot and percentage above the hero. The value includes active defensive effects, armour and relevant mastery tuning; immunity displays 100%. Menu is at the lower right during play and in the lobby header. Sound is inside Menu so it no longer covers the battlefield HUD. A large central countdown is yellow for five/four, red for three/two/one. Arena Play Solo is enabled; choose one, two or three practice bots. Solo automatically supplies one bot if none was selected. Practice does not award PvP records or trophies; damage still counts toward mastery.

## 66 — Tempo Monk

A twelve-second ring tracks alternating melee and ranged stances. Melee primary is Bullet Punch (22 damage); Triple Kick leaps between up to three different enemies, 14 damage and 0.7-second stun each. Ranged primary throws a 16-damage dagger; secondary channels a narrow two-second flame stream with burn.

Venom Discipline overrides the normal cycle for twelve seconds with poison jabs and a radial dart spin. Heavy Discipline mastery raises primary damage 25% but lengthens its cooldown 35%. Shadow Discipline final mastery replaces the poison stance: primary dashes through enemies; secondary grants brief immunity and six healing over 1.5 seconds. Its cooldown is longer. Temporary stance expiry resumes normal alternation. Normal level requirements still apply.

## 67 — Quill Prowler

A porcupine with rhythmic crouch-and-spring movement, unchanged average travel speed. Briar Claw is close melee (24); Springthorn is a collision-safe lunge (22); Bramble Stampede is a longer single-hit-per-enemy rush (42). Successful claw/lunge grants 10% protection for one second.

Living Quills mastery replaces primary with bounded melee companions: at most three, 40 HP, twelve seconds, eight damage per 1.1 seconds. Quillpack Rally final mastery replaces the stampede with summoning and aimed pack positioning, plus a brief ward. Existing companions do not get free healing or a lifetime refresh. Equip both to make a summoner build.

Both heroes have four matching pixel poses, descriptions, filters, mastery titles, two alternatives and normal progression. A mastery selection bug was also fixed: authored replacement attacks now actually replace their original attack before tuning is applied.

## Food, gardens and town services

Eight new purchasable foods join the four existing foods. Four extra foods are final-tier garden rewards. Food remains one auto-consumed slot; buying or harvesting cannot fill an occupied slot. Cleansing/healing conditions and prices are shown in the food UI.

The Seed House now has native buttons, four family tabs, crop cards, lock explanations, current crop status and a harvest action. There are sixteen distinct crops. Each family unlocks tiers at zero, one, three and six harvests in that family. One cleared adventure ripens the planted crop. Progress, crop and packed food persist in portable profiles. Existing pear crops migrate without losing their harvest.

The Squirrel Post replaces the Student Creators town interaction. Animated squirrels carry boxes. Ship packed food for six gold or open the existing profile import/export services. A visible garden bed reflects planted crops.

## Shared leaderboard

No global ranked leaderboard was added. A downloadable game or browser cannot safely update a shared local file across unrelated players. A common hosted storage/API service would be required. Existing local profile trophies and live match leaders remain available.

## Release

Deploy included room service 23, then export fresh game builds. Read DEPLOY_V89.md for exact settings and RELEASE_CHECKS_V89.md for testing limits.
