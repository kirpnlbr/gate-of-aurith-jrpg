# Enemy & Missing Party Sprite Generation Guide

Complete sprite plan for all enemies and the missing Gustave shield idle, aligned with the code in `overworld.gd`. Each prompt is ready to paste into your AI image generator with the appropriate reference image attached.

---

## How To Use This Guide

### Workflow per enemy
1. **Generate the base/idle sprite FIRST** using the idle prompt (no reference image needed, or use an existing game sprite as style reference)
2. **For every attack sprite sheet**, attach the idle sprite you just generated as the reference image
3. **Run `clean_frames.py`** on each generated sheet to split into `frame_0.png` through `frame_8.png`
4. **Place frames** in the correct folder under `assets/sprites/battle/frames/`

### Important notes
- All prompts produce a **3x3 grid sprite sheet** (9 frames)
- **Enemies face LEFT** (toward the party). **Party characters face RIGHT**.
- The procedural wind-up/lunge system works WITHOUT attack sprites — they add polish on top
- Frame sizes don't need to match between animations — the game normalizes them automatically

### Folder structure
```
assets/sprites/battle/frames/{folder_name}/frame_0.png through frame_8.png
```

---

## Priority Order

1. Enemy idles (goblin, wraith, golem, dark knight) — fallback colored rectangles look bad
2. Gustave shield idle — needed for stance switching
3. Boss attacks — the showpiece
4. Golem attacks — mid-game
5. Wraith attacks — feint readability
6. Goblin attacks — lowest priority

---

## 1. GOBLIN

**Character**: Small green-skinned goblin, hunched posture, pointy ears, tattered brown leather armor, crude short sword in right hand, mean squinty eyes, snaggle-toothed grin. Faces LEFT.

### 1a. Goblin Idle — `goblin_idle/`

```
Sprite sheet of a tiny chibi pixel art green-skinned goblin with pointy ears,
tattered brown leather armor, crude short sword in right hand, hunched
aggressive posture, facing LEFT side profile, 3x3 grid, solid magenta
#FF00FF background, sequence, frame by frame idle animation - frame 1
neutral standing facing left, frame 2 shifts weight side to side, frame 3
sword bobs slightly, frame 4 ears twitch, frame 5 slight bounce on feet,
frame 6 eyes dart around suspiciously, frame 7 sword glints, frame 8
settling back, frame 9 back to neutral, square aspect ratio, each cell
identical size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel
art bold dark outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING.
```

### 1b. Goblin Slash — `goblin_slash/`
**Attach goblin idle as reference image.**
Single hit, long wind-up.

```
Sprite sheet of the EXACT goblin character from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame SLASH attack animation - frame 1 neutral stance
gripping sword, frame 2 sword arm pulls back behind body, frame 3 body
coils weight shifts to back foot winding up, frame 4 sword raised high
behind head peak wind-up pose, frame 5 STRIKE sword swings forward fast
slash arc, frame 6 sword extended fully forward slash impact pose, frame 7
follow-through sword past center body leaning, frame 8 recovering pulling
sword back to side, frame 9 returning to neutral idle stance, square aspect
ratio, each cell identical size with borders or lines separating each cell NO gaps NO padding, retro SNES
16-bit chibi pixel art bold dark outlines, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING. Replicate the character design proportions colors and style
of the attached reference image exactly.
```

### 1c. Goblin Double Strike — `goblin_double_strike/`
**Attach goblin idle as reference image.**
2 quick hits.

```
Sprite sheet of the EXACT goblin character from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame DOUBLE SLASH attack animation - frame 1 sword
pulls back winding up, frame 2 body coils forward aggressively, frame 3
FIRST SLASH swings sword horizontally from right to left, frame 4 sword
extended impact pose, frame 5 immediately pulls sword back high overhead
for second strike, frame 6 body twists with momentum, frame 7 SECOND SLASH
diagonal downward swing, frame 8 sword extended down at angle impact pose,
frame 9 recovering to neutral idle stance, square aspect ratio, each cell
identical size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel
art bold dark outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate
the character design proportions colors and style of the attached reference
image exactly.
```

---

## 2. WRAITH

**Character**: Floating spectral wraith, translucent purple-blue ghostly form, tattered dark cloak billowing, glowing cyan/white hollow eyes, no visible legs (wispy spectral trail below), elongated clawed hands, eerie and menacing. Faces LEFT.

### 2a. Wraith Idle — `wraith_idle/`

```
Sprite sheet of a tiny chibi pixel art floating wraith spirit, translucent
purple-blue ghostly body, tattered dark cloak billowing, glowing cyan hollow
eyes, elongated clawed hands reaching forward, wispy spectral trail below
instead of legs, facing LEFT side profile, 3x3 grid, solid magenta #FF00FF
background, sequence, frame by frame idle floating animation - frame 1
neutral hovering in place, frame 2 bobs up slightly, frame 3 cloak billows
and ripples, frame 4 eyes pulse brighter cyan glow, frame 5 drifts down
gently, frame 6 cloak settles, frame 7 ghostly wisps swirl around body,
frame 8 eyes dim slightly, frame 9 back to neutral hover position, square
aspect ratio, each cell identical size with borders or lines separating each cell NO gaps NO padding, retro
SNES 16-bit chibi pixel art bold dark outlines, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING.
```

### 2b. Wraith Spectral Claw — `wraith_spectral_claw/`
**Attach wraith idle as reference image.**
3 rapid claw swipes.

```
Sprite sheet of the EXACT wraith character from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame TRIPLE CLAW SWIPE attack animation - frame 1 claws
pull back ghostly energy gathers around hands, frame 2 lunges forward FIRST
CLAW SWIPE right hand slashing with spectral trails, frame 3 claw extended
ghostly energy trailing, frame 4 pulls back quickly resetting, frame 5
SECOND CLAW SWIPE left hand slashing, frame 6 both claws pull back
gathering more energy, frame 7 ghostly energy surges brightly, frame 8
THIRD CLAW SWIPE both hands together massive combined slash, frame 9 claws
extended forward ghostly energy dissipating, square aspect ratio, each cell
identical size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel
art bold dark outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate
the character design proportions colors and style of the attached reference
image exactly.
```

### 2c. Wraith Delayed Haunt — `wraith_delayed_haunt/`
**Attach wraith idle as reference image.**
1 FEINT (fake-out) then 1 real heavy hit.

```
Sprite sheet of the EXACT wraith character from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame FEINT then HAUNT attack animation - frame 1 wraith
surges forward aggressively as if about to strike (FAKE-OUT), frame 2
suddenly stops and pulls back retreating deceptively, frame 3 hovers
ominously still gathering dark purple energy around claws, frame 4 dark
energy swirls intensify growing larger, frame 5 body coils back further
building immense power, frame 6 eyes blaze bright cyan, frame 7 dark energy
peaks maximum intensity, frame 8 LUNGES forward with massive spectral
strike claws extended, frame 9 claws through target position ghostly energy
exploding outward, square aspect ratio, each cell identical size NO gaps NO
borders NO padding, retro SNES 16-bit chibi pixel art bold dark outlines,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate the character design
proportions colors and style of the attached reference image exactly.
```

---

## 3. STONE GOLEM

**Character**: Large bulky stone golem made of gray-brown rough-hewn rocks, moss patches on shoulders, glowing amber/orange eyes in a crude carved face, massive stone fists, cracked textures, slow and heavy. Faces LEFT. Larger than other enemies (1.3x scale).

### 3a. Golem Idle — `golem_idle/`

```
Sprite sheet of a chibi pixel art large bulky stone golem made of rough
gray-brown rocks, moss patches on shoulders and head, glowing amber-orange
eyes in a crude carved face, massive stone fists hanging at sides, cracked
rocky texture across body, very wide and stocky proportions, facing LEFT
side profile, 3x3 grid, solid magenta #FF00FF background, sequence, frame
by frame idle standing animation - frame 1 standing heavy and still,
frame 2 slight sway of massive body, frame 3 rocks shift and crack subtly,
frame 4 eyes glow brighter amber, frame 5 settles weight with a small
crunch, frame 6 moss sways gently, frame 7 tiny pebbles crumble from
shoulder, frame 8 eyes dim slightly, frame 9 back to neutral heavy stance,
square aspect ratio, each cell identical size with borders or lines separating each cell NO gaps NO padding,
retro SNES 16-bit chibi pixel art bold dark outlines, SHARP CRISP PIXEL
EDGES NO ANTI-ALIASING.
```

### 3b. Golem Ground Slam — `golem_ground_slam/`
**Attach golem idle as reference image.**
Single massive hit with long dramatic wind-up.

```
Sprite sheet of the EXACT stone golem from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame GROUND SLAM attack animation - frame 1 slowly
raises both massive stone fists, frame 2 fists rising higher body leans
back, frame 3 fists at peak height above head cracks glowing with amber
energy, frame 4 brief pause at apex glowing cracks intensify building
power, frame 5 SLAMS BOTH FISTS DOWN with full crushing force, frame 6
fists hit ground massive impact shockwave debris flying, frame 7 ground
cracks spreading outward stone fragments in air, frame 8 dust and debris
settling, frame 9 slowly rising back up to standing stance, square aspect
ratio, each cell identical size with borders or lines separating each cell NO gaps NO padding, retro SNES
16-bit chibi pixel art bold dark outlines, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING. Replicate the character design proportions colors and style
of the attached reference image exactly.
```

### 3c. Golem Boulder Toss — `golem_boulder_toss/`
**Attach golem idle as reference image.**
Single hit, medium speed.

```
Sprite sheet of the EXACT stone golem from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame BOULDER TOSS attack animation - frame 1 reaches
down to the ground with one hand, frame 2 grips and tears a large chunk of
rock from the ground, frame 3 lifts boulder overhead with one hand, frame 4
body twists winding up to throw, frame 5 THROWS boulder forward toward the
left with great force, frame 6 boulder released mid-air trailing rock
debris, frame 7 throwing arm fully extended follow-through pose, frame 8
arm lowering slowly, frame 9 returning to neutral idle stance, square
aspect ratio, each cell identical size with borders or lines separating each cell NO gaps NO padding, retro
SNES 16-bit chibi pixel art bold dark outlines, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING. Replicate the character design proportions colors and style
of the attached reference image exactly.
```

### 3d. Golem Earthquake (Team Attack) — `golem_earthquake/`
**Attach golem idle as reference image.**
2 hits targeting random party members. Massive area attack.

```
Sprite sheet of the EXACT stone golem from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame EARTHQUAKE team attack animation - frame 1 body
glows as cracks widen with amber energy building, frame 2 raises right fist
high overhead body leans back, frame 3 pauses at apex building seismic
energy in fist, frame 4 FIRST SLAM right fist crashes into ground massive
shockwave ripples outward, frame 5 ground erupts rocks and debris fly
upward, frame 6 quickly raises left fist overhead while ground still
shaking, frame 7 SECOND SLAM even harder both fists pound the ground,
frame 8 ground exploding with debris and dust cloud everywhere, frame 9
slowly rising from crouch dust and pebbles settling around, square aspect
ratio, each cell identical size with borders or lines separating each cell NO gaps NO padding, retro SNES
16-bit chibi pixel art bold dark outlines, SHARP CRISP PIXEL EDGES NO
ANTI-ALIASING. Replicate the character design proportions colors and style
of the attached reference image exactly.
```

---

## 4. DARK KNIGHT (BOSS)

**Character**: Tall imposing dark knight in jet-black full plate armor with glowing dark purple/violet trim and accents, closed full-face helmet with narrow glowing red eye slit, massive two-handed black greatsword with purple-dark energy aura, tattered dark cape flowing behind. Faces LEFT. Boss-sized (1.5x scale).

### 4a. Dark Knight Idle — `dark_knight_idle/`

```
Sprite sheet of a chibi pixel art imposing dark knight in jet-black full
plate armor with glowing dark purple trim and accents, closed full-face
helmet with narrow glowing red eye slit, massive black greatsword with dark
purple energy aura held in right hand resting on shoulder, tattered dark
cape flowing behind, menacing powerful stance, facing LEFT side profile,
3x3 grid, solid magenta #FF00FF background, sequence, frame by frame idle
animation - frame 1 standing menacing and still, frame 2 cape billows in
unseen wind, frame 3 sword energy pulses with dark purple glow, frame 4
red eye slit glows brighter, frame 5 slight weight shift forward
threateningly, frame 6 dark energy wisps drift around sword blade, frame 7
cape settles, frame 8 subtle threatening lean forward, frame 9 back to
neutral menacing stance, square aspect ratio, each cell identical size NO
gaps NO borders NO padding, retro SNES 16-bit chibi pixel art bold dark
outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING.
```

### 4b. Dark Knight Blade Combo — `dark_knight_blade_combo/`
**Attach dark knight idle as reference image.**
5-hit combo with a FEINT on hit 3. Two slashes, a fake-out that stops, then two more real slashes ending in a big finisher.

```
Sprite sheet of the EXACT dark knight from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame 5-HIT BLADE COMBO with MID-COMBO FEINT animation -
frame 1 sword swings horizontally FIRST SLASH dark energy trail, frame 2
quick recovery pulls sword back, frame 3 SECOND SLASH diagonal upward
swing, frame 4 sword raised high as if to strike again BUT STOPS mid-swing
this is a FEINT fake-out deceptive pause, frame 5 holds menacing position
then lowers sword back deceptively, frame 6 suddenly sword pulls back low
for real strike, frame 7 FOURTH SLASH quick aggressive horizontal cut,
frame 8 body coils back deeply for massive final blow dark energy surging,
frame 9 FIFTH SLASH enormous overhead cleave with dark purple energy trail
exploding on impact, square aspect ratio, each cell identical size NO gaps
NO borders NO padding, retro SNES 16-bit chibi pixel art bold dark outlines,
SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate the character design
proportions colors and style of the attached reference image exactly.
```

### 4c. Dark Knight Delayed Thrust — `dark_knight_delayed_thrust/`
**Attach dark knight idle as reference image.**
2 FEINTS (fake lunges) then 1 massive real thrust (highest single-hit damage in the game).

```
Sprite sheet of the EXACT dark knight from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame DOUBLE FEINT into MASSIVE THRUST attack animation -
frame 1 lunges forward slightly with sword as if about to strike FIRST
FEINT, frame 2 pulls back immediately it was a fake, frame 3 thrusts sword
forward again SECOND FEINT, frame 4 pulls back again deceptively, frame 5
stands still sword held low ominous pause dark purple energy gathering
around blade, frame 6 dark energy intensifies purple glow building,
frame 7 body coils back deeply sword pulled far behind charging with dark
power, frame 8 MASSIVE THRUST lunges forward full extension dark energy
EXPLODING from blade, frame 9 sword fully extended through target position
dark energy dissipating in wake, square aspect ratio, each cell identical
size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel art bold
dark outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate the
character design proportions colors and style of the attached reference
image exactly.
```

### 4d. Dark Knight Dark Cleave (Team Attack) — `dark_knight_dark_cleave/`
**Attach dark knight idle as reference image.**
3 sweeping hits targeting random party members.

```
Sprite sheet of the EXACT dark knight from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame DARK CLEAVE team-wide attack animation - frame 1
sword raised high above head dark energy gathering around blade, frame 2
dark energy swirls intensify purple-black aura growing, frame 3 FIRST
CLEAVE wide horizontal sweep to the left dark energy arc trailing sword,
frame 4 sword momentum carries through to far side, frame 5 reverses grip
pulls sword back for return swing, frame 6 SECOND CLEAVE reverse sweep
from left to right dark energy wave, frame 7 dark energy everywhere
crackling, frame 8 spins entire body around and THIRD CLEAVE massive
downward slam dark energy explosion on impact, frame 9 dark energy waves
dissipating outward sword planted in ground, square aspect ratio, each cell
identical size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel
art bold dark outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate
the character design proportions colors and style of the attached reference
image exactly.
```

### 4e. Dark Knight Shadow Rend — `dark_knight_shadow_rend/`
**Attach dark knight idle as reference image.**
3 fast hits, single target, tight timing. Quick aggressive slashing with shadow afterimages.

```
Sprite sheet of the EXACT dark knight from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame SHADOW REND rapid attack animation - frame 1
dark shadow energy surrounds knight body begins to blur with afterimage,
frame 2 dashes forward FIRST REND claw-like shadow slash with dark trails,
frame 3 shadow trails lingering from first hit, frame 4 instantly
repositions with dark teleport-like movement, frame 5 SECOND REND upward
shadow slash diagonal cut, frame 6 shadow energy peaks swirling around
body, frame 7 spins with shadow afterimage trailing behind, frame 8 THIRD
REND massive X-shaped shadow cross slash both directions, frame 9 standing
still in dissipating shadow wisps, square aspect ratio, each cell identical
size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel art bold
dark outlines, SHARP CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate the
character design proportions colors and style of the attached reference
image exactly.
```

### 4f. Dark Knight Abyssal Onslaught (Team Attack) — `dark_knight_onslaught/`
**Attach dark knight idle as reference image.**
1 FEINT then 4 real hits targeting random party members. Most dangerous attack in the game.

```
Sprite sheet of the EXACT dark knight from the attached reference image
facing LEFT side profile, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame ABYSSAL ONSLAUGHT team attack animation - frame 1
raises sword high dark abyss energy swirling threatens to strike but HOLDS
this is a FEINT, frame 2 dark portal-like energy gathers around knight
building power, frame 3 FIRST STRIKE dashes and slashes releasing dark
energy wave, frame 4 instantly teleport-repositions with dark afterimage
left behind, frame 5 SECOND STRIKE slash from new angle dark energy
trailing, frame 6 another dark afterimage reposition teleport blur,
frame 7 THIRD STRIKE spinning slash with dark energy rings expanding
outward, frame 8 dark energy reaches absolute peak everything glowing,
frame 9 FOURTH STRIKE massive final overhead slam dark energy ERUPTION
explosion, square aspect ratio, each cell identical size NO gaps NO borders
NO padding, retro SNES 16-bit chibi pixel art bold dark outlines, SHARP
CRISP PIXEL EDGES NO ANTI-ALIASING. Replicate the character design
proportions colors and style of the attached reference image exactly.
```

---

## 5. GUSTAVE SHIELD IDLE (Party — Missing Sprite)

The only missing party sprite. Needed for Gustave's greatshield stance switch. Gustave faces RIGHT (party side).

### 5a. Gustave Shield Idle — `gustave_idle_alt/`
**Attach Gustave's greatsword idle sheet as reference image.**

```
Sprite sheet of the EXACT character from the attached reference image but
instead of holding a greatsword he is holding a MASSIVE GREATSHIELD in his
left hand, large tower shield covering most of his body with gold trim
matching his crimson red plate armor, right hand resting on top edge of
shield ready to brace, defensive ready stance, facing RIGHT side profile
view showing the right-facing direction NOT front-facing, retain every
other detail exactly including crimson red plate armor gold trim short brown
hair cocky expression, 3x3 grid, solid magenta #FF00FF background,
sequence, frame by frame idle breathing animation - frame 1 neutral
defensive stance crouched behind shield facing right, frame 2 shield shifts
slightly adjusting grip, frame 3 peers over shield edge eyes visible,
frame 4 weight adjusts feet shuffle, frame 5 shield surface glints with
reflected light, frame 6 settles deeper into defensive stance, frame 7
brief peek around shield side, frame 8 shield arm flexes gripping tighter,
frame 9 back to neutral defensive stance, square aspect ratio, each cell
identical size with borders or lines separating each cell NO gaps NO padding, retro SNES 16-bit chibi pixel
art bold dark outlines, very small character 30-35 pixels tall, SHARP CRISP
PIXEL EDGES NO ANTI-ALIASING. Replicate the character design proportions
colors and style of the attached reference image exactly but CHARACTER MUST
FACE RIGHT SIDE PROFILE and hold GREATSHIELD instead of greatsword.
```

---

## Code-to-Folder Mapping

| # | Enemy | Folder | Attack Pattern | Type |
|---|---|---|---|---|
| 1a | Goblin | `goblin_idle/` | — | Idle |
| 1b | Goblin | `goblin_slash/` | Goblin Slash | Single, 1 hit |
| 1c | Goblin | `goblin_double_strike/` | Double Strike | Single, 2 hits |
| 2a | Wraith | `wraith_idle/` | — | Idle |
| 2b | Wraith | `wraith_spectral_claw/` | Spectral Claw | Single, 3 hits |
| 2c | Wraith | `wraith_delayed_haunt/` | Delayed Haunt | Single, 1 feint + 1 hit |
| 3a | Golem | `golem_idle/` | — | Idle |
| 3b | Golem | `golem_ground_slam/` | Ground Slam | Single, 1 hit |
| 3c | Golem | `golem_boulder_toss/` | Boulder Toss | Single, 1 hit |
| 3d | Golem | `golem_earthquake/` | Earthquake | Team, 2 hits |
| 4a | Dark Knight | `dark_knight_idle/` | — | Idle (Boss) |
| 4b | Dark Knight | `dark_knight_blade_combo/` | Blade Combo | Single, 5 hits (1 feint) |
| 4c | Dark Knight | `dark_knight_delayed_thrust/` | Delayed Thrust | Single, 2 feints + 1 hit |
| 4d | Dark Knight | `dark_knight_dark_cleave/` | Dark Cleave | Team, 3 hits |
| 4e | Dark Knight | `dark_knight_shadow_rend/` | Shadow Rend | Single, 3 hits |
| 4f | Dark Knight | `dark_knight_onslaught/` | Abyssal Onslaught | Team, 1 feint + 4 hits |
| 5a | Gustave | `gustave_idle_alt/` | — | Shield stance idle |

**Total: 17 sprite sheets**

---

## Post-Processing

After generating each sprite sheet, split it into individual frames:

```bash
python3 clean_frames.py <sheet_path> <output_folder> --grid 3x3
```

This produces `frame_0.png` through `frame_8.png`. Place them in the correct folder under `assets/sprites/battle/frames/` and the game loads them automatically.

If magenta backgrounds remain, the `hit_flash.gdshader` handles removal at runtime. For pre-cleaning:

```bash
magick <file>.png -fuzz 20% -transparent "#FF00FF" <file>.png
```
