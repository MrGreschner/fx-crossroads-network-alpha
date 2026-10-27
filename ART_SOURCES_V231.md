# V231 visual sources

Built-in ImageGen generated the selected AI/guard/troop/Tollbreaker artwork. Exact prompts: tools/unit231_prompts.json. Selected original sheets: assets/unit231/*_source.png. Runtime: assets/unit231/units.png (33 designs / 132 poses, one 320×2640 cached atlas). Source crop/registration and visual-size metadata: assets/unit231/manifest231.json. Original references were existing project art. Full painted sheets are excluded from runtime packing.

Source IDs: AI 2c20486c-979c-47f5-8ed7-6cf398538b52; guards ae678e6b-364c-4c1d-962e-a73cbe7cc099; Wildwood 0914c5dc-0ede-4d56-a180-0b985d1d529a and 4b6cff6b-066e-42e0-b628-ea1c7c0c8ca3; Ironhollow e2ceb472-77eb-4a74-aa17-d6ee1db56c28 and 9bec1659-768e-4fc3-b52f-439c57008cf4; corrected deer archer 2fa61fa1-d3c7-49c2-a4de-d7566bfea93a; Tollbreaker 41fc07af-50e6-4a34-b99a-6c20345d4cf8.

The AI sheet's eighth draft row is not used; dedicated guard artwork is used instead. The original Wildwood deer archer row is replaced with the shield-free corrected sheet. Lumen's four frames are consistently mirrored during atlas preparation to retain the original staff side, never mirrored according to movement direction.

The new ImageGen intro-walk draft was rejected after inspection because it still repeated the forward foot and changed Bramble's facing. Final cinematic frames reuse the existing V223 artwork with a cached two-limb cutout rig. Only existing lower-limb patches transform between steps; upper body/head pixels remain identical. See tools/cinematic_gait231.py and assets/cinematic231/rig.json. The same final PNGs are copied to native and browser film assets. No limb generation or image manipulation runs each game frame.
