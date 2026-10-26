# V222 sprite repairs

Built-in image generation edited the existing Star Navigator, Hazel Hex and Hearth Herald sheets. Originals and normalized six-pose sprites are in assets/hero222. The prompts retained species, equipment, colours and neutral front-facing coarse pixel style; Navigator must hover with a continuous robe and no boots; Hazel and Herald use smaller heads, softer coloured contours and matte shading.

Walking corrections use scripts/hero_walk222.gd to rig only the two lower legs from each idle sprite. Each cached pose alternates the raised foot; the head, upper body, signature equipment and ground baseline remain fixed. Compatibility PNGs were baked from the same rig and imported for direct asset users. This is a two-frame step animation, not directional artwork.

Sizing factors are visual only; collision, attack reach and health do not depend on these factors.
