# VFX Sprite Generation Guide (Consolidated)

Battle effect sprites — projectiles, impact overlays, buff auras, and summons. Consolidated from 27 down to **12 sprite sheets** by merging similar effects and relying on palette swapping in code.

---

## How To Use This Guide

### Workflow per VFX
1. **Generate the sprite sheet** using the prompt below (no reference image needed)
2. **Run `clean_frames.py`** on the sheet to split into `frame_0.png` through `frame_8.png`
3. **Place frames** in the correct folder under `assets/sprites/battle/frames/vfx/`

### Important notes
- All prompts produce a **3x3 grid sprite sheet** (9 frames)
- VFX sprites are **overlays** composited on top of characters during combat
- Magenta `#FF00FF` background for chroma keying
- Many effects are generated in **neutral white/silver** and tinted per-element via shader at runtime — this is how 12 sheets cover 27+ use cases

### Palette swap strategy
Several sheets below are generated in white/neutral tones. At runtime, a color tint shader recolors them:
- Fire: orange-red `(1.0, 0.4, 0.1)`
- Ice: cyan-blue `(0.3, 0.8, 1.0)`
- Lightning: yellow-white `(1.0, 0.95, 0.4)`
- Water: blue-teal `(0.2, 0.6, 1.0)`
- Lava: deep orange `(1.0, 0.3, 0.0)`
- Dark: violet-purple `(0.6, 0.1, 0.9)`
- Physical: white (no tint)
- Heal: green `(0.3, 1.0, 0.5)`
- Debuff: sickly purple-green `(0.6, 0.2, 0.8)`

### Folder structure
```
assets/sprites/battle/frames/vfx/{folder_name}/frame_0.png through frame_8.png
```

---

## The 12 Sheets

### 1. Slash Arc — `vfx/slash_arc/`
**Covers:** All basic attacks, Goblin Slash, Goblin Double Strike, Heavy Slash, Whirlwind, Ground Slam impact. Tinted white for physical, golden for heavy (scale up + golden tint), violet for Dark Knight.

```
Sprite sheet of a pixel art SLASH ARC visual effect, NO CHARACTER just the
slash effect itself, a bright clean WHITE crescent slash arc with a
blazing white core and fading trail, designed to be color-tinted at
runtime, 3x3 grid, solid magenta #FF00FF background, sequence, frame by
frame slash animation - frame 1 tiny bright point of light where blade
begins its arc, frame 2 short bright slash line begins extending, frame 3
slash arc grows into a sharp thick crescent shape pure white with bright
core, frame 4 full crescent slash arc at maximum size bright and sharp
small sparks at edges, frame 5 peak brightness with energy sparks and
small debris flying off the arc, frame 6 arc begins fading from the
starting end trailing off, frame 7 arc mostly faded only the tip remains
bright scattered sparks, frame 8 faint afterimage ghost of the arc, frame 9
fully dissipated empty frame, square aspect ratio, each cell identical size
with borders or lines separating each cell NO gaps NO padding, retro SNES
16-bit pixel art, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING,
transparent-friendly design on magenta background.
```

### 2. Magic Orb Projectile — `vfx/proj_orb/`
**Covers:** Fireball (fire tint), Lava Burst (lava tint, scale up). A round energy projectile traveling right. Tinted per element.

```
Sprite sheet of a pixel art MAGIC ORB PROJECTILE visual effect, NO
CHARACTER just the orb itself, a bright clean WHITE glowing energy sphere
with a blazing white-hot core and trailing energy particles, designed to be
color-tinted at runtime, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame projectile travel animation - frame 1 small
energy ignites forming into a bright sphere, frame 2 orb grows rounder
energy licking outward from surface, frame 3 orb fully formed bright
white with blazing core streaking to the RIGHT, frame 4 orb in flight
trailing bright energy particles behind it, frame 5 orb at full speed
energy streaming backward intense glow, frame 6 energy flickers and
shifts shape while traveling, frame 7 orb burns brighter approaching
impact, frame 8 orb begins expanding on contact energy spreading outward,
frame 9 orb explodes into scattered sparks and energy wisps, square aspect
ratio, each cell identical size with borders or lines separating each cell
NO gaps NO padding, retro SNES 16-bit pixel art, SHARP CRISP PIXEL EDGES
NO ANTI-ALIASING, transparent-friendly design on magenta background.
```

### 3. Sharp Projectile — `vfx/proj_shard/`
**Covers:** Ice Lance (ice tint), Thunder Pulse (lightning tint, more jagged). A pointed crystalline shard projectile. Tinted per element.

```
Sprite sheet of a pixel art SHARP CRYSTAL SHARD PROJECTILE visual effect,
NO CHARACTER just the shard itself, a pointed angular WHITE crystal spear
with a bright core and trailing particle fragments, designed to be
color-tinted at runtime, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame shard travel animation - frame 1 angular
fragments form and coalesce into a sharp point, frame 2 shard elongates
into a jagged lance shape, frame 3 shard fully formed bright white pointed
crystal streaking to the RIGHT, frame 4 shard in flight trailing small
crystal fragments and energy mist behind it, frame 5 shard at full speed
fragment trail streaming backward sharp and deadly, frame 6 surface glints
and sparkles as it spins slightly, frame 7 shard glows brighter
approaching impact, frame 8 shard strikes and begins shattering into
angular fragments, frame 9 fragments scatter outward in all directions
mist dissipating, square aspect ratio, each cell identical size with
borders or lines separating each cell NO gaps NO padding, retro SNES
16-bit pixel art, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING,
transparent-friendly design on magenta background.
```

### 4. Wave / AOE Sweep — `vfx/wave_sweep/`
**Covers:** Tidal Wave (water tint), Inferno (fire tint), Earthquake screen effect. A wide horizontal energy wave. Tinted per element.

```
Sprite sheet of a pixel art ENERGY WAVE SWEEP visual effect, NO CHARACTER
just the wave itself, a wide tall WHITE crashing energy wave with bright
foam-like crest and scattered particles, wide enough to cover multiple
character positions, designed to be color-tinted at runtime, 3x3 grid,
solid magenta #FF00FF background, sequence, frame by frame wave crash
animation - frame 1 energy rises from below small ripples forming across
a wide area, frame 2 wave builds height surging upward bright white,
frame 3 wave curls at the top forming a cresting shape bright particles
appearing, frame 4 massive wave at full height about to crash forward
particles spraying, frame 5 WAVE CRASHES forward toward the RIGHT energy
exploding outward, frame 6 energy rushes across flooding forward particles
and spray everywhere, frame 7 wave spreads thin energy splashing in all
directions, frame 8 energy recedes leaving scattered particles and mist,
frame 9 last particles fall and settle to nothing, square aspect ratio,
each cell identical size with borders or lines separating each cell NO gaps
NO padding, retro SNES 16-bit pixel art, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING, transparent-friendly design on magenta background.
```

### 5. Ground Eruption — `vfx/eruption/`
**Covers:** Lava Burst (lava tint), Earthquake ground crack (amber tint), Boulder Toss impact. Erupts upward from below. Tinted per element.

```
Sprite sheet of a pixel art GROUND ERUPTION visual effect, NO CHARACTER
just the eruption effect, a violent upward burst of WHITE energy and debris
exploding from cracks in the ground, chunks of material flying upward,
designed to be color-tinted at runtime, 3x3 grid, solid magenta #FF00FF
background, sequence, frame by frame eruption animation - frame 1 cracks
appear on the ground with bright glow seeping through, frame 2 cracks
widen bright energy visible beneath glowing brighter, frame 3 small spurts
begin popping upward steam and particles rising, frame 4 ERUPTION massive
column of energy explodes UPWARD from below blazing bright white core,
frame 5 peak eruption energy at maximum height chunks of debris flying
outward in all directions, frame 6 energy fountain spraying debris
everywhere, frame 7 eruption subsiding energy falls back downward, frame 8
last debris chunks falling glow dimming, frame 9 steam and embers settling
ground still glowing faintly, square aspect ratio, each cell identical size
with borders or lines separating each cell NO gaps NO padding, retro SNES
16-bit pixel art, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING,
transparent-friendly design on magenta background.
```

### 6. Impact Burst — `vfx/impact_burst/`
**Covers:** ALL hit impacts across every element. A circular burst overlay played on the target at moment of contact. Tinted per element: white for physical, orange for fire, cyan for ice, yellow for lightning, blue for water, violet for dark.

```
Sprite sheet of a pixel art IMPACT BURST visual effect, NO CHARACTER just
the burst effect, a bright WHITE circular starburst explosion expanding
outward from a blazing center point with radiating rays and small debris
fragments, designed to be color-tinted at runtime, 3x3 grid, solid magenta
#FF00FF background, sequence, frame by frame impact animation - frame 1
intense bright white flash at point of impact small and sharp, frame 2
starburst rays shoot outward from center in all directions with small
fragments, frame 3 burst expands to full size bright radiating ring with
debris, frame 4 maximum size starburst 6-8 pointed rays secondary
fragments flying, frame 5 peak brightness rays at full reach energy
crackling, frame 6 burst begins retracting inward rays shortening edges
dimming, frame 7 rays gone scattered fragments and sparks still drifting,
frame 8 last fragments fading, frame 9 fully dissipated empty frame,
square aspect ratio, each cell identical size with borders or lines
separating each cell NO gaps NO padding, retro SNES 16-bit pixel art,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING, transparent-friendly design on
magenta background.
```

### 7. Parry Spark — `vfx/parry_spark/`
**Covers:** Every successful parry. Distinct from impact burst — sharper, more metallic, faster. NOT tinted (always white-silver).

```
Sprite sheet of a pixel art PARRY SPARK visual effect, NO CHARACTER just
the spark, a sharp bright white-silver metallic clash spark with angular
starburst rays and tiny metal fragments, very fast and punchy snappy
timing, 3x3 grid, solid magenta #FF00FF background, sequence, frame by
frame parry spark animation - frame 1 empty frame before contact, frame 2
empty frame building anticipation, frame 3 SUDDEN bright white-silver
angular starburst flash like two swords clashing sharp pointed rays,
frame 4 starburst at maximum brightness angular metallic star with small
silver sparks shooting outward, frame 5 tiny metal fragments flying in all
directions starburst still bright, frame 6 starburst rapidly shrinks and
vanishes sparks still flying, frame 7 scattered sparks slowing and fading,
frame 8 last tiny sparks winking out, frame 9 fully dissipated empty
frame, square aspect ratio, each cell identical size with borders or lines
separating each cell NO gaps NO padding, retro SNES 16-bit pixel art,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING, transparent-friendly design on
magenta background.
```

### 8. Heal Shimmer — `vfx/heal_shimmer/`
**Covers:** Potion, Phoenix heal, Phoenix Rise revive, Ether (blue tint). Rising sparkle particles through a character-sized space. Green by default, blue tint for AP restore.

```
Sprite sheet of a pixel art HEALING SHIMMER visual effect, NO CHARACTER
just the sparkle particles, bright WHITE rising sparkle particles and soft
vertical light pillars flowing upward through an empty character-sized
space, warm and restorative feeling, designed to be color-tinted at
runtime, 3x3 grid, solid magenta #FF00FF background, sequence, frame by
frame heal animation - frame 1 small sparkle points appear at the bottom
of the frame, frame 2 sparkles begin rising upward more appearing below
them, frame 3 sparkles flowing upward steadily bright white with soft glow,
frame 4 gentle vertical light pillars form among the rising sparkles,
frame 5 peak intensity many sparkles rising light pillars at brightest
warm glow, frame 6 upper sparkles reach the top and pop into tiny
starbursts, frame 7 sparkle density reducing light pillars fading, frame 8
last few sparkles drifting upward, frame 9 final sparkles pop and fade,
square aspect ratio, each cell identical size with borders or lines
separating each cell NO gaps NO padding, retro SNES 16-bit pixel art,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING, transparent-friendly design on
magenta background.
```

### 9. Buff Aura (Looping) — `vfx/aura_buff/`
**Covers:** ALL buff and debuff auras. Speed buff (green tint, upward flow), defense buff (amber tint), defense debuff (purple-green tint, downward flow — flip vertically in code), taunt (red tint). One looping particle ring, direction and color set in code.

```
Sprite sheet of a pixel art BUFF AURA visual effect, NO CHARACTER just the
aura overlay, bright WHITE upward-flowing energy wisps and small glowing
particles orbiting and rising through an empty character-sized space,
designed to be color-tinted at runtime, 3x3 grid, solid magenta #FF00FF
background, sequence, frame by frame LOOPING aura animation designed so
frame 9 flows seamlessly back into frame 1 - frame 1 energy wisps rise
upward around empty center space small glowing particles orbiting, frame 2
wisps flow upward gently particles shift clockwise in orbit, frame 3
energy at steady intensity wisps rising particles continuing orbit, frame 4
wisps shift position rotating around the center subtle pulse brighter,
frame 5 new wisps appear at bottom as top ones fade creating continuous
upward flow, frame 6 glow pulses slightly brighter particles at new
orbital positions, frame 7 wisps continue flowing pattern shifted for
seamless loop, frame 8 particles and wisps cycle back toward starting
positions, frame 9 nearly identical to frame 1 for smooth loop transition,
square aspect ratio, each cell identical size with borders or lines
separating each cell NO gaps NO padding, retro SNES 16-bit pixel art,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING, transparent-friendly design on
magenta background.
```

### 10. Sage Summon — Winged Spirit — `vfx/summon_winged/`
**Covers:** Phoenix (golden-orange tint), Thunderbird (yellow-electric tint), Griffin (green tint). All three are winged spirit apparitions — same silhouette works, color distinguishes them.

```
Sprite sheet of a pixel art WINGED SPIRIT APPARITION visual effect, NO
CHARACTER just the spirit, a glowing bright WHITE ethereal bird-like spirit
silhouette with large spreading wings, semi-transparent and ghostly,
radiating energy outward, designed to be color-tinted at runtime, 3x3 grid,
solid magenta #FF00FF background, sequence, frame by frame manifestation
animation - frame 1 faint white light gathers wisps of energy forming
behind and above center, frame 2 light coalesces into a vague winged shape
glowing, frame 3 winged spirit silhouette becomes visible wings beginning
to spread outward, frame 4 spirit fully manifested wings spread wide
majestic ethereal bird radiating bright energy, frame 5 peak brightness
spirit blazes wings at full span trailing energy feathers, frame 6 spirit
releases a pulse of energy outward from its wings a bright expanding ring,
frame 7 spirit begins fading becoming more transparent wings folding,
frame 8 faint ghostly outline remaining wisps drifting, frame 9 fully
faded last particles dissipate, square aspect ratio, each cell identical
size with borders or lines separating each cell NO gaps NO padding, retro
SNES 16-bit pixel art, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING,
transparent-friendly design on magenta background.
```

### 11. Sage Summon — Serpentine Spirit — `vfx/summon_serpent/`
**Covers:** Leviathan (blue-teal tint), Basilisk (purple-green tint). Both are serpentine/coiling creatures — same silhouette, color distinguishes them.

```
Sprite sheet of a pixel art SERPENTINE SPIRIT APPARITION visual effect, NO
CHARACTER just the spirit, a glowing bright WHITE ethereal coiling serpent
silhouette with a fierce head and long sinuous body, semi-transparent and
ghostly, radiating energy, designed to be color-tinted at runtime, 3x3
grid, solid magenta #FF00FF background, sequence, frame by frame
manifestation animation - frame 1 white energy swirls upward from below
coiling motion, frame 2 energy coalesces into a sinuous serpentine shape,
frame 3 serpent silhouette visible long coiling body with fierce head and
open jaws glowing bright, frame 4 serpent fully manifested coiled body
rearing up head lunging forward radiating energy, frame 5 peak brightness
serpent surges forward energy blast fires from its jaws toward the LEFT,
frame 6 energy beam or pulse extends from serpent toward the target,
frame 7 serpent begins dissolving back into energy wisps, frame 8 faint
serpentine outline remaining wisps flowing, frame 9 fully dissipated wisps
settle, square aspect ratio, each cell identical size with borders or lines
separating each cell NO gaps NO padding, retro SNES 16-bit pixel art,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING, transparent-friendly design on
magenta background.
```

### 12. Sage Summon — Beast Spirit — `vfx/summon_beast/`
**Covers:** Golem (amber-brown tint). The golem is too distinct from winged/serpentine to merge, but this sheet also works for any future quadruped/beast summons.

```
Sprite sheet of a pixel art BEAST SPIRIT APPARITION visual effect, NO
CHARACTER just the spirit, a glowing bright WHITE ethereal massive stocky
humanoid-beast silhouette with thick limbs and wide shoulders, semi-
transparent and ghostly, radiating protective energy, designed to be
color-tinted at runtime, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame manifestation animation - frame 1 white energy
rumbles upward from below heavy particles rising, frame 2 particles
coalesce into a massive stocky humanoid shape, frame 3 beast silhouette
visible bulky body with glowing eyes wide powerful stance, frame 4 beast
fully manifested arms raised in a powerful protective stance radiating
energy, frame 5 peak brightness beast slams fists or arms together sending
a shockwave ring of energy outward, frame 6 protective energy dome or ring
expands outward from the beast, frame 7 beast dissolving back into heavy
energy fragments, frame 8 faint bulky outline remaining dust and particles
floating, frame 9 particles settle fully dissipated, square aspect ratio,
each cell identical size with borders or lines separating each cell NO gaps
NO padding, retro SNES 16-bit pixel art, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING, transparent-friendly design on magenta background.
```

---

## Code-to-VFX Mapping

### Physical Attacks
| Skill/Attack | Sheet | Tint | Notes |
|---|---|---|---|
| All basic attacks | `slash_arc` | white | Default size |
| Goblin Slash / Double Strike | `slash_arc` | white | Default size |
| Gustave Heavy Slash | `slash_arc` | golden | Scale 1.3x |
| Gustave Whirlwind | `slash_arc` | golden | Scale 1.5x, play twice |
| Golem Ground Slam | `eruption` | amber | + `slash_arc` golden for wind-up |
| Golem Boulder Toss | `proj_orb` | amber-brown | + `impact_burst` amber |
| Golem Earthquake | `eruption` | amber | Play twice, screen shake |

### Mage Skills
| Skill | Projectile Sheet | Impact Sheet | Tint |
|---|---|---|---|
| Fireball | `proj_orb` | `impact_burst` | fire (orange-red) |
| Inferno | `wave_sweep` | `impact_burst` | fire (orange-red) |
| Thunder Pulse | `proj_shard` | `impact_burst` | lightning (yellow) |
| Ice Lance | `proj_shard` | `impact_burst` | ice (cyan) |
| Tidal Wave | `wave_sweep` | `impact_burst` | water (blue-teal) |
| Lava Burst | `eruption` | `impact_burst` | lava (deep orange) |

### Sage Skills
| Skill | Summon Sheet | Impact Sheet | Tint |
|---|---|---|---|
| Phoenix Heal | `summon_winged` | `heal_shimmer` | golden-orange / green |
| Phoenix Rise | `summon_winged` | `heal_shimmer` | golden-orange / green |
| Leviathan | `summon_serpent` | `impact_burst` | blue-teal |
| Thunderbird | `summon_winged` | `impact_burst` | yellow-electric |
| Griffin (SPD buff) | `summon_winged` | `aura_buff` | green |
| Golem (DEF buff) | `summon_beast` | `aura_buff` | amber-brown |
| Basilisk (DEF debuff) | `summon_serpent` | `aura_buff` | purple-green (flip V) |

### Gustave Skills
| Skill | Sheet | Tint | Notes |
|---|---|---|---|
| Heavy Slash | `slash_arc` | golden | Scale 1.3x |
| Whirlwind | `slash_arc` | golden | Scale 1.5x |
| Taunt | `aura_buff` | red-crimson | Looping for duration |

### Dark Knight Attacks
| Attack | Slash Sheet | Impact Sheet | Tint |
|---|---|---|---|
| Blade Combo (5 hits) | `slash_arc` | `impact_burst` | violet-purple |
| Delayed Thrust | `slash_arc` | `impact_burst` | violet-purple |
| Dark Cleave (team) | `slash_arc` | `impact_burst` | violet-purple |
| Shadow Rend (3 hits) | `slash_arc` | `impact_burst` | violet-purple |
| Abyssal Onslaught | `slash_arc` | `impact_burst` | violet-purple |

### Universal
| Event | Sheet | Tint |
|---|---|---|
| Successful parry | `parry_spark` | none (white-silver) |
| Potion | `heal_shimmer` | green |
| Ether | `heal_shimmer` | blue |
| Revive Crystal | `heal_shimmer` | green (brighter) |

---

## Summary

| # | Sheet | Folder | Reuse Count |
|---|---|---|---|
| 1 | Slash Arc | `vfx/slash_arc/` | ~15 (every physical hit) |
| 2 | Magic Orb Projectile | `vfx/proj_orb/` | 3 (fireball, lava, boulder) |
| 3 | Sharp Projectile | `vfx/proj_shard/` | 2 (ice lance, thunder) |
| 4 | Wave Sweep | `vfx/wave_sweep/` | 2 (tidal wave, inferno) |
| 5 | Ground Eruption | `vfx/eruption/` | 3 (lava burst, earthquake, ground slam) |
| 6 | Impact Burst | `vfx/impact_burst/` | ~20 (every hit in the game) |
| 7 | Parry Spark | `vfx/parry_spark/` | every parry |
| 8 | Heal Shimmer | `vfx/heal_shimmer/` | 4 (potion, ether, phoenix heal/revive) |
| 9 | Buff Aura | `vfx/aura_buff/` | 4 (speed, defense, debuff, taunt) |
| 10 | Winged Spirit | `vfx/summon_winged/` | 3 (phoenix, thunderbird, griffin) |
| 11 | Serpentine Spirit | `vfx/summon_serpent/` | 2 (leviathan, basilisk) |
| 12 | Beast Spirit | `vfx/summon_beast/` | 1 (golem) |

**12 sheets. 12 prompts. Full coverage of all 32+ skills and attacks.**

---

## Post-Processing

Same pipeline as character sprites:

```bash
python3 clean_frames.py <sheet_path> <output_folder> --grid 3x3
```

If magenta backgrounds remain, `hit_flash.gdshader` handles removal at runtime.
