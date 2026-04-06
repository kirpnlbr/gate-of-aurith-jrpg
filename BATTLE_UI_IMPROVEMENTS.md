# Battle UI Improvements

Remaining issues from the UI audit, prioritized. Items 1-4 (HUD redesign, sprite overlap, menu reposition, turn indicator), 5 (turn order bar), 8 (enemy HP bars), and 9-12 (responsive layout, menu overlap, parry indicator, enemy off-screen) are done.

## P0 — High Priority

### 3. Reposition the action menu
The action menu sits at `(16, 260)` which overlaps the second party member's sprite. Move it to a fixed position that doesn't collide — e.g. anchor it to the bottom-left above the action text box, or shift it left of the sprites with a clear gap.
- File: `scripts/ui/action_menu.gd` (line 20: `position = Vector2(16, 260)`)
- Also affects: `scripts/ui/skill_menu.gd` (line 15), `scripts/ui/item_menu.gd` (line 14) — both at `(190, 260)`

### 4. Add active turn indicator on sprites
There's no visual cue on the sprites showing whose turn it is. Add a highlight, bounce, glow, or arrow on the active character's sprite so the player can tell at a glance.
- File: `scripts/battle/battle_manager.gd` — add indicator logic in `_enter_state(PLAYER_SELECT)` and clear it on turn end

## P1 — Medium Priority

### 5. Style the turn order bar
`[Mage] > Sage > Gustave > Goblin > Goblin` is plain text at `(16, 8)`. Replace with colored names, small portrait icons, or styled boxes. Highlight the active character.
- File: `scripts/battle/battle_manager.gd` — `turn_order_label` at line 417

### 6. Add visual grouping / background to party sprites area
The left side (party sprites) has no visual container. A subtle dark panel behind the party area would separate it from the battlefield and make the layout feel more intentional.
- File: `scripts/battle/battle_manager.gd` — `_build_battle_scene()`

### 7. Style the action text box
The bottom description box is a plain rectangle with a basic border. Add a styled panel (rounded corners, subtle gradient or border glow) to match the status panel aesthetic.
- File: `scripts/ui/action_text_box.gd`

### 8. Enemy HP bar polish
- The red HP bar with red-orange trail is hard to distinguish. Consider a darker/gray background with a brighter red fill.
- The "40/40" text overlaps the enemy name when HP numbers are long.
- File: `scripts/battle/battle_manager.gd` — enemy HP bar section (lines ~340-400)

## P2 — Low Priority (Polish)

### 9. Responsive layout
All positions are hardcoded to 960x540. The background is literally `Vector2(960, 540)`. Consider reading viewport size and computing positions relative to it.
- File: `scripts/battle/battle_manager.gd` — all const positions at lines 72-84

### 10. Skill/Item menu overlap
Both menus are at `(190, 260)` and render over the sprite area. They should appear in a cleaner location — perhaps replacing the action menu position or sliding in from the side.
- Files: `scripts/ui/skill_menu.gd`, `scripts/ui/item_menu.gd`

### 11. Parry indicator positioning
The shrinking ring and prompt label use hardcoded offsets relative to the target. These could drift off-screen for edge-positioned targets.
- File: `scripts/ui/parry_indicator.gd`

### 12. Third enemy can be off-screen
With 3 enemies at Y positions 200, 300, 400 and sprites ~80px tall, the third enemy's HP bar/name can extend past the 540px viewport bottom.
- File: `scripts/battle/battle_manager.gd` — `ENEMY_Y_START`, `ENEMY_SPACING`
