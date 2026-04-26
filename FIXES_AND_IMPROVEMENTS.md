# Fixes & Improvements

This document tracks rubric-aligned issues and the fixes applied. All code-side items are now complete; the only remaining task is presentation-side.

---

## ✅ Completed

### Damage variance
Widened RNG from ±10% to ±20% on `calculate_physical`, `calculate_magical`, and `calculate_enemy_damage` (`damage_calculator.gd`). Secures RNG 10%.

### Heal variance
Added ±10% variance to `calculate_heal` (`damage_calculator.gd`). Narrower than damage so heals still feel reliable, but consistent with the rest of the system.

### Enemy commands — diverse effects (Enemies 20%)
Implemented enemy defend behavior in `battle_ai.gd`. Each enemy turn has a 25% chance of choosing `defend` instead of an attack pattern (won't defend two turns in a row). `_execute_enemy_defend` in `battle_manager.gd` sets `defending = true`, plays the defend animation, and reads `defending` in `_get_effective_def`/`_get_effective_mdef` for ×1.5 DEF/MDEF that round. Each enemy has at least 2 commands with different effects (attack patterns + defend).

### Party defend — animations + mechanics
- Sliced 4 defend sheets (`mage_defend`, `sage_defend`, `gustave_defend`, `gustave_defend_alt`) into per-frame folders via `split_party_defend_sprites.py` + `clean_frames.py`.
- Added `sprite_defend`, `sprite_defend_alt`, `defend_hold_frame`, `defend_hold_frame_alt` to `CharacterData`. Wired in `party_state.gd`.
- `battle_manager.gd._execute_defend()` plays the intro animation up to the hold frame, leaves the sprite there for the round. `_play_animation_to_frame` helper added. Idle cycling skips defending characters. `_swap_to_idle_sprite` is called when `defending` is cleared at round start.
- Hold frames: Mage 5 (full shield), Sage 6 (manifested barrier), Gustave greatsword 5 (raised guard), Gustave greatshield 7 (settled brace).
- Gustave automatically picks `defend_alt` + alt hold frame when in greatshield stance.

### Defending blocks parry/dodge
`parry_system.gd` — when target is defending, the parry indicator ring is suppressed (visual feedback), and any parry/dodge input is silently redirected to "miss". Hit always lands but with the ×1.5 DEF reduction. Multiplier in `_calculate_hit_damage` aligned to ×1.5 (was ×2.0) so all damage paths agree.

### Mage idle sprite — beardless frame
Removed `mage_idle/frame_6.png` (stray frame with no beard / different staff orb), shifted 7→6 and 8→7. Idle now has 8 consistent bearded frames.

### Empty resource folders
Deleted `resources/` and all 5 empty subfolders (`attack_patterns/`, `skills/`, `items/`, `characters/`, `enemies/`). All data lives inline in `party_state.gd` and `overworld.gd`. Project tree no longer shows empty directories.

---

## ✅ Verified — no patch needed

### Loss state transition (Battle Handler 30%)
`main.gd._on_battle_finished` handles `result == "defeat"`: stops BGM, sets `GameState.GAME_OVER`, calls `_show_game_over()`. The screen renders a red GAME OVER label and "Press ENTER to return to title" prompt. `_unhandled_input` catches confirm, resets `party_state`, returns to title. Full loop works — no silent freeze.

### Battle log narration (UI 10%)
All 12 enemy attack patterns in `overworld.gd` use `{attacker}` / `{target}` placeholders correctly substituted in `parry_system.start_phase`. Single-target attacks name both ("Goblin slashes at Mage!"); AoE attacks name attacker ("Stone Golem shakes the earth beneath the party!"). The dynamic AoE per-target builder in `_execute_aoe_attack` substitutes the enemy name. Enemy defend narrates with the enemy name. Every action is narrated with attacker (and target where applicable).

### Stance action menu scoping
`action_menu.gd` shows `[Attack, Skill, Item, Defend]` uniformly for all characters — there is no Stance button to gate. Stance Switch is a SKILL on Gustave's skill list (`party_state._create_gustave_skills`), so it only appears in the skill submenu when Gustave is the active character. Mage and Sage never see it.

---

## 📋 Remaining — presentation only

### Declare combat type (required by spec)
The spec says "Please specify which type of turn-based combat you are making." This needs to be stated in the 5-minute presentation, not code:

> *"Speed-Based Turn-Based — turn order is recalculated each round from each character's Speed stat in `turn_order.gd`."*

Also describe the unique mechanic for the 10% Unique Mechanic grade:

> *"Parry/dodge timing windows on every enemy attack — Z to parry (no damage + counterattack if all hits parried + 1 AP), X to dodge (no damage). Plus Gustave's stance switching — Greatsword for damage output, Greatshield for survivability with a 15% larger parry window."*
