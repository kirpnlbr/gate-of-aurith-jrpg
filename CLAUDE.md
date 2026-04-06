# Gate of Aurith - JRPG

## Project Overview
Turn-based dungeon crawler JRPG built in Godot 4.6 (GDScript). Features parry-based combat, elemental system, 3 playable characters, grid-based exploration.

## How to Run
Open in Godot 4.6 and run `main.tscn`. No build step required.

## Project Structure
```
scripts/
  main.gd              - Game state machine (title/overworld/battle transitions)
  party_state.gd        - Party data singleton (characters, items, XP/leveling)
  battle/
    battle_manager.gd   - Battle state machine and scene construction
    battle_effects.gd   - Combat juice (shake, hit stop, damage numbers, flash, knockback)
    parry_system.gd     - Multi-hit parry phase with animation
    turn_order.gd       - Speed-based turn calculation
    damage_calculator.gd - Physical/magical/heal damage formulas
    battle_ai.gd        - Enemy target selection (respects taunt)
  overworld/
    overworld.gd        - Dungeon generation, encounters, map rendering
    overworld_player.gd  - Grid-based player movement
    encounter_zone.gd    - Encounter zone data class
  data/
    character_data.gd    - CharacterData Resource class
    skill_data.gd        - SkillData Resource class
    item_data.gd         - ItemData Resource class
    enemy_data.gd        - EnemyData Resource class
    attack_pattern.gd    - AttackPattern Resource class
    element_chart.gd     - Elemental multiplier lookups
  ui/
    action_menu.gd       - Battle action selection (Attack/Skill/Item/Defend/Stance)
    skill_menu.gd        - Skill selection with AP cost display
    item_menu.gd         - Item selection with quantity display
    target_selector.gd   - Target selection with arrow indicator
    parry_indicator.gd   - Shrinking ring parry timing UI
    action_text_box.gd   - Battle text display panel
scenes/
  main.tscn, battle.tscn, overworld.tscn
assets/sprites/battle/frames/  - Frame-based animations (frame_0.png, frame_1.png, ...)
```

## Architecture Notes
- All UI is currently built procedurally in code (not in .tscn files)
- Battle entities (party/enemies) are Dictionaries with "data", "current_hp", "sprite", "animations", "buffs" keys
- Animations are folder-based: each animation is a folder of frame_N.png files, loaded and cached at battle start
- Signals used for UI→logic decoupling (action_selected, skill_selected, target_selected, parry_input_received)
- State machines: GameState enum in main.gd, BattleState enum in battle_manager.gd, ParryState enum in parry_system.gd

## Conventions
- GDScript 4.x with type hints where possible
- Private methods/vars prefixed with underscore
- Data classes extend Resource, logic classes extend Node2D or RefCounted
- Sprite paths point to folders (e.g. "res://assets/sprites/battle/frames/mage_idle")
- Enemy definitions are currently inline in overworld.gd (planned: extract to .tres resources)

## Key Design Decisions
- Parry/dodge is the core combat differentiator — every enemy attack has a parry window
- Gustave has stance switching (greatsword/greatshield) affecting ATK/DEF/parry bonuses
- Party fully heals after each victory to prevent resource starvation across the dungeon
- Frame cache prevents redundant disk loads during battle
- BattleEffects system handles all combat juice (screen shake, hit stop, damage numbers, knockback, death anims)
- hit_flash.gdshader combines magenta artifact removal + white flash on hit (each sprite gets its own material instance)
- Sprite scaling normalized per-frame via target_height stored in entity dicts

## Input Bindings
- Movement: WASD / Arrow keys
- Confirm: Enter / Space
- Cancel: Escape / X
- Parry: Z (during parry window only)
- Dodge: X / Right trigger (during parry window only)
