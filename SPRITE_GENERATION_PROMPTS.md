# Sprite Generation Prompts for Nano Banana MCP

## Style Reference

All sprites must match the existing Gate of Aurith mage character:
- **Style**: Chibi/cute 16-bit pixel art, SNES-era quality
- **Look**: Bold dark outlines, saturated colors, expressive despite small size
- **Background**: Solid magenta #FF00FF (chroma key, removed later in Godot)
- **Size**: Individual sprites are 364x360px (the mage originals)
- **Anti-aliasing**: NONE — hard pixel edges only

Use `mage_down_idle.png` from the existing project as **input_image_path_1** (style reference) for EVERY prompt below.

**Reference image path**: `res://assets/sprites/mage/mage_down_idle.png`
(Use the absolute path on your system when calling Nano Banana)

---

## Output Directory

All generated sprites go to:
```
/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/
```

---

## PARTY SPRITES

### 1. Mage — Battle Idle

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of a young female mage, front-facing idle battle stance, wearing purple-blue pointed wizard hat, dark blue-purple flowing robes with lighter blue trim, holding a wooden staff with glowing blue crystal orb on top in left hand, right hand relaxed at side, short brown hair visible under hat, simple cute face with small dot eyes, small character about 48 pixels tall in a 64x64 frame, retro SNES RPG style matching the reference image exactly, standing on nothing, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, each pixel is a solid color with hard edges, bold dark outlines around character, centered composition, no text, no shadows on background, no ground",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/mage_idle.png",
  "model_tier": "pro"
}'
```

### 2. Mage — Attack (Casting Spell)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of the same young female mage from reference image, in a spell-casting attack pose, staff raised high above head with glowing blue-white magic energy swirling around the crystal orb, left arm extended forward channeling magic, bright blue-cyan magic particles and sparkles emanating from outstretched hand, wearing purple-blue pointed wizard hat and dark blue-purple flowing robes, short brown hair, dynamic casting pose leaning slightly forward, same art style as reference image, retro SNES RPG style, small character about 48 pixels tall in a 64x64 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, each pixel is a solid color with hard edges, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/mage_attack.png",
  "model_tier": "pro"
}'
```

### 3. Mage — Skill (Elemental Burst)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of the same young female mage from reference image, performing a powerful elemental spell, both arms raised wide with massive magical energy circle glowing beneath and around her, staff floating beside her surrounded by fire and lightning energy, wearing purple-blue pointed wizard hat and dark blue-purple robes, eyes glowing with magical power, multiple colored elemental particles swirling around (red fire, blue ice, yellow lightning), dramatic power-up pose, same art style as reference image, retro SNES RPG style, small character about 48 pixels tall in a 72x72 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/mage_skill.png",
  "model_tier": "pro"
}'
```

### 4. Gustave — Battle Idle (Greatsword)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of a stocky muscular male knight named Gustave, front-facing idle battle stance, wearing crimson red plate armor with gold trim and gold belt buckle, large metallic shoulder pauldrons, short messy brown hair with a cocky confident smirk on his face, holding a COMICALLY OVERSIZED greatsword resting on his right shoulder (sword is nearly as tall as him), the sword blade is silver-white metal, armored red boots, same chibi pixel art style as the mage in reference image, retro SNES RPG style, small character about 48 pixels tall in a 64x64 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, each pixel is a solid color with hard edges, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/gustave_idle.png",
  "model_tier": "pro"
}'
```

### 5. Gustave — Attack (Greatsword Slash)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of the same stocky knight Gustave from a fighting game, mid-swing attack pose slashing his COMICALLY OVERSIZED greatsword diagonally downward from right to left, sword trail slash effect in white-yellow arc, wearing crimson red plate armor with gold trim, both hands gripping the massive sword handle, dynamic aggressive forward-leaning action pose, short brown hair, determined battle expression, same chibi pixel art style as reference mage, retro SNES RPG style, small character about 48 pixels tall in a 72x72 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/gustave_attack.png",
  "model_tier": "pro"
}'
```

### 6. Gustave — Skill (Greatshield Taunt)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of the same stocky knight Gustave, now in a defensive stance holding a COMICALLY OVERSIZED greatshield in front of his body with his left arm, the shield is crimson red with a golden cross emblem in the center, golden glow aura emanating from the shield edges, right fist clenched and raised in a taunting gesture, wearing crimson red plate armor, cocky grin on face, protective defensive pose, same chibi pixel art style as reference mage, retro SNES RPG style, small character about 48 pixels tall in a 72x72 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/gustave_skill.png",
  "model_tier": "pro"
}'
```

### 7. Sage — Battle Idle

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of a young scholarly character named Sage, front-facing idle battle stance, wearing emerald green wizard robes with lighter green trim and a high collar, NO hat (unlike the mage), messy sandy blonde hair, round glasses on face giving a nerdy bookish look, holding an open ancient leather-bound tome/spellbook in both hands at chest level, the book has glowing green-white pages, same chibi pixel art style as the mage in reference image, retro SNES RPG style, small character about 48 pixels tall in a 64x64 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, each pixel is a solid color with hard edges, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/sage_idle.png",
  "model_tier": "pro"
}'
```

### 8. Sage — Attack (Manifestation Summon)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of the same scholarly Sage character, in a summoning attack pose, book held open in left hand with pages glowing bright green, right arm extended forward commanding a glowing green translucent energy creature manifestation (a small phoenix-like bird shape made of pure green-white energy) appearing from the book and flying toward the right side, wearing emerald green robes, glasses, sandy blonde hair, focused determined expression, same chibi pixel art style as reference mage, retro SNES RPG style, small character about 48 pixels tall in a 72x72 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/sage_attack.png",
  "model_tier": "pro"
}'
```

### 9. Sage — Skill (Grand Manifestation)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG battle sprite of the same scholarly Sage character, performing a grand manifestation summon, book floating open above his head surrounded by swirling green magical energy, both arms raised channeling power, a LARGE glowing green translucent energy creature (phoenix/dragon shape) forming above him taking up the top half of the frame, the manifestation is made of bright green-white luminous energy with glowing eyes, wearing emerald green robes, glasses glinting with reflected green light, dramatic power pose, same chibi pixel art style as reference mage, retro SNES RPG style, character about 48 pixels tall in an 80x80 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/sage_skill.png",
  "model_tier": "pro"
}'
```

---

## ENEMY SPRITES

### 10. Goblin

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG enemy battle sprite of a small green-skinned goblin, front-facing battle stance, short and scrappy with pointy ears sticking out sideways, yellow beady eyes with a mischievous evil grin showing small fangs, wearing tattered brown leather vest and brown loincloth, holding a small rusty dagger in right hand, bare green feet, hunched forward aggressive posture, same chibi pixel art style as the mage in reference image, retro SNES RPG enemy style, small character about 36 pixels tall in a 48x48 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, each pixel is a solid color with hard edges, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/goblin.png",
  "model_tier": "pro"
}'
```

### 11. Wraith

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG enemy battle sprite of a ghostly wraith/specter, front-facing hovering pose, hooded dark purple-violet ethereal cloak that fades and wisps away at the bottom instead of legs giving a floating ghostly appearance, two bright glowing red eyes visible inside the dark hood, spectral claw-like hands extending from the cloak sleeves made of translucent purple energy, eerie purple-violet glow aura around the entire figure, no visible face except the glowing red eyes, menacing supernatural presence, same chibi pixel art style as the mage in reference image, retro SNES RPG enemy style, character about 48 pixels tall in a 56x64 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/wraith.png",
  "model_tier": "pro"
}'
```

### 12. Stone Golem

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG enemy battle sprite of a massive stone golem, front-facing battle stance, body made entirely of rough gray-brown rock and stone blocks, very wide and bulky proportions (wider than tall), small head on top of huge stone shoulders, glowing orange-red eyes like magma cracks, visible stone cracks and fissures across body with darker lines, massive rock fists at the sides, sturdy thick stone legs, moss or lichen patches on shoulders, imposing heavy powerful stance, same chibi pixel art style as the mage in reference image but LARGER, retro SNES RPG enemy style, character about 56 pixels tall in a 64x64 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/golem.png",
  "model_tier": "pro"
}'
```

### 13. Dark Knight (Boss)

```
mcpl call nanobanana generate_image '{
  "prompt": "16-bit chibi pixel art RPG boss enemy battle sprite of an imposing Dark Knight, front-facing menacing battle stance, wearing full dark gunmetal-black plate armor with sharp angular edges and spikes on shoulder pauldrons, closed full-face helmet with narrow glowing crimson red visor slit for eyes, a tattered dark red-black cape flowing behind, holding a large dark sword with a faint red glow along the blade edge in right hand point downward, the armor has a red glowing emblem on the chest plate, overall dark and threatening but still in cute chibi proportions, same chibi pixel art style as the mage in reference image but LARGER and more menacing, retro SNES RPG boss style, character about 64 pixels tall in a 72x80 frame, isolated on solid magenta background #FF00FF, SHARP CRISP PIXEL EDGES WITH ABSOLUTELY NO ANTI-ALIASING NO SMOOTHING NO BLENDING, bold dark outlines, centered, no text, no shadows on background",
  "input_image_path_1": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png",
  "output_path": "/Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle/boss_dark_knight.png",
  "model_tier": "pro"
}'
```

---

## OVERWORLD PLAYER SPRITE

### 14. Mage Overworld (Front-facing for dungeon)

You can reuse the existing mage sprites from `gate-of-aurith/assets/sprites/mage/` for the overworld. Just copy them:

```bash
cp /Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith/assets/sprites/mage/mage_down_idle.png \
   /Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/mage/mage_down_idle.png
```

Or generate a fresh one if you want a different overworld look.

---

## POST-GENERATION: Removing Magenta Background

After generating all sprites, remove the magenta chroma key in Godot. The game already has chroma key removal code in the existing mage.gd. Alternatively, use ImageMagick:

```bash
cd /Users/kodimagadia/Documents/gate-of-aurith-JRPG/gate-of-aurith-jrpg/assets/sprites/battle

for f in *.png; do
  magick "$f" -fuzz 20% -transparent "#FF00FF" "${f%.png}_clean.png"
  mv "${f%.png}_clean.png" "$f"
  echo "Processed: $f"
done
```

---

## WORKFLOW

1. Run prompts 1-3 (Mage) → verify each one matches the style
2. Run prompts 4-6 (Gustave) → use the approved Mage idle as style reference
3. Run prompts 7-9 (Sage) → same reference
4. Run prompts 10-13 (Enemies) → same reference
5. Run magenta removal on all files
6. Reopen Godot project to reimport

## TIPS FOR ITERATION

- If a sprite doesn't match the style, add more emphasis: "EXACTLY matching the chibi pixel art style, proportions, and outline thickness of the reference image"
- If too much anti-aliasing, add: "absolutely NO smooth edges, NO gradient blending, every single pixel must be a distinct solid color block"
- If character is too big/small, adjust the "about XX pixels tall in a YYxY frame" numbers
- If colors are wrong, be more specific: "purple-blue hex #4640A0 robes" etc.
- Generate idle poses first, get them approved, then use those as additional reference images for attack/skill poses
