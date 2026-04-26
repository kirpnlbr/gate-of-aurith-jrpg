extends Node2D

const TILE_SIZE := 48
const MOVE_DURATION := 0.15
const SPRITE_TARGET_HEIGHT := 40.0
const BOB_AMOUNT := 3.0
const BOB_SPEED := 14.0
const WALK_FPS := 8.0
const FOLLOW_GAP := 1  # tiles between each party member

const DIR_UP    := Vector2i(0, -1)
const DIR_DOWN  := Vector2i(0, 1)
const DIR_LEFT  := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)

var overworld_node: Node2D = null
var frozen := false

# Party train
var _members: Array = []  # Array[Dictionary], ordered front-to-back
var _party_chars: Array = ["mage", "sage", "gustave"]

# Expose leader grid_pos for overworld.gd compatibility
var grid_pos: Vector2i:
	get: return _members[0].grid_pos if _members.size() > 0 else Vector2i.ZERO

func init(overworld: Node2D, start_pos: Vector2i) -> void:
	overworld_node = overworld

	# Spawn party in train formation: leader at start, followers behind
	var spawn_positions: Array[Vector2i] = [start_pos]
	var used: Array[Vector2i] = [start_pos]
	for i in range(1, _party_chars.size()):
		var placed := false
		# Try directions: up, left, right, down
		for offset in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			var candidate: Vector2i = spawn_positions[i - 1] + offset
			if overworld_node.is_walkable(candidate.x, candidate.y) and candidate not in used:
				spawn_positions.append(candidate)
				used.append(candidate)
				placed = true
				break
		if not placed:
			spawn_positions.append(spawn_positions[i - 1])
	for i in range(_party_chars.size()):
		var m := _create_member(_party_chars[i], spawn_positions[i])
		_members.append(m)

	# Set camera position to leader immediately
	position = grid_to_world(start_pos)
	_update_z_order()

func _create_member(character: String, gp: Vector2i) -> Dictionary:
	var node := Node2D.new()
	node.position = grid_to_world(gp)
	overworld_node.add_child(node)

	var spr := Sprite2D.new()
	node.add_child(spr)

	var idle := {}
	var walk := {}
	_load_character_sprites(character, idle, walk)

	var m := {
		"character": character,
		"node": node,
		"sprite": spr,
		"grid_pos": gp,
		"facing": "down",
		"is_moving": false,
		"move_from": Vector2.ZERO,
		"move_to": Vector2.ZERO,
		"move_t": 0.0,
		"bob_time": 0.0,
		"frame_time": 0.0,
		"walk_frame": 0,
		"idle_frames": idle,
		"walk_frames": walk,
	}
	_apply_facing(m)
	return m

func _load_character_sprites(character: String, idle: Dictionary, walk: Dictionary) -> void:
	var base := "res://assets/sprites/overworld/%s/%s_" % [character, character]
	for dir in ["up", "down", "right"]:
		var idle_tex := load(base + "%s_idle.png" % dir) as Texture2D
		if idle_tex == null:
			push_warning("OverworldPlayer: missing %s%s_idle.png" % [base, dir])
		idle[dir] = idle_tex

		var frames: Array[Texture2D] = []
		for i in range(3):
			var tex := load(base + "%s_%d.png" % [dir, i]) as Texture2D
			frames.append(tex if tex != null else idle_tex)
		walk[dir] = frames

func _sprite_dir(facing: String) -> String:
	return "right" if facing == "left" else facing

func _apply_facing(m: Dictionary) -> void:
	var sdir := _sprite_dir(m.facing)
	m.sprite.flip_h = (m.facing == "left")
	var tex: Texture2D = m.idle_frames.get(sdir)
	if tex:
		m.sprite.texture = tex
		var s := SPRITE_TARGET_HEIGHT / float(tex.get_height())
		m.sprite.scale = Vector2(s, s)

func _apply_walk_frame(m: Dictionary) -> void:
	var sdir := _sprite_dir(m.facing)
	var frames: Array = m.walk_frames.get(sdir, [])
	if frames.is_empty():
		return
	var tex: Texture2D = frames[m.walk_frame % frames.size()]
	if tex:
		m.sprite.texture = tex

func _dir_to_facing(dir: Vector2i) -> String:
	if dir.y < 0: return "up"
	if dir.y > 0: return "down"
	if dir.x < 0: return "left"
	return "right"

func _update_z_order() -> void:
	for m in _members:
		m.node.z_index = m.grid_pos.y

static func grid_to_world(gp: Vector2i) -> Vector2:
	return Vector2(gp.x * TILE_SIZE + TILE_SIZE * 0.5,
				   gp.y * TILE_SIZE + TILE_SIZE * 0.5)

func _process(delta: float) -> void:
	if frozen:
		return

	var any_moving := false
	for m in _members:
		if m.is_moving:
			any_moving = true
			_tick_member(m, delta)

	if not any_moving:
		_poll_input()

	# Keep camera node (self) at leader's visual position
	if _members.size() > 0:
		position = _members[0].node.position

func _poll_input() -> void:
	if Input.is_action_just_pressed("cycle_party"):
		_cycle_party()
		return

	var dir := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):
		dir = DIR_UP
	elif Input.is_action_pressed("move_down"):
		dir = DIR_DOWN
	elif Input.is_action_pressed("move_left"):
		dir = DIR_LEFT
	elif Input.is_action_pressed("move_right"):
		dir = DIR_RIGHT

	if dir != Vector2i.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2i) -> void:
	var leader: Dictionary = _members[0]
	var target: Vector2i = leader.grid_pos + dir
	if not overworld_node.is_walkable(target.x, target.y):
		# Still face the direction even if blocked
		leader.facing = _dir_to_facing(dir)
		_apply_facing(leader)
		return

	# Block leader from walking into a follower's tile
	for i in range(1, _members.size()):
		if _members[i].grid_pos == target:
			leader.facing = _dir_to_facing(dir)
			_apply_facing(leader)
			return

	Sfx.play("footstep", -10.0, randf_range(0.9, 1.1))

	# Collect old positions before any movement starts
	var old_pos: Array[Vector2i] = []
	for m in _members:
		old_pos.append(m.grid_pos)

	# Move leader
	_begin_move(leader, target, _dir_to_facing(dir))

	# Each follower moves to the previous member's old position
	for i in range(1, _members.size()):
		var target_pos: Vector2i = old_pos[i - 1]
		if _members[i].grid_pos != target_pos:
			var fdir: Vector2i = target_pos - _members[i].grid_pos
			_begin_move(_members[i], target_pos, _dir_to_facing(fdir))

	_update_z_order()

func _begin_move(m: Dictionary, target: Vector2i, facing: String) -> void:
	m.is_moving = true
	m.move_from = m.node.position
	m.move_to = grid_to_world(target)
	m.move_t = 0.0
	m.bob_time = 0.0
	m.frame_time = 0.0
	m.walk_frame = 0
	m.grid_pos = target
	m.facing = facing
	_apply_facing(m)  # update scale + flip for new direction

func _tick_member(m: Dictionary, delta: float) -> void:
	m.move_t += delta / MOVE_DURATION

	# Bob
	m.bob_time += delta
	m.sprite.position.y = -abs(sin(m.bob_time * BOB_SPEED)) * BOB_AMOUNT

	# Walk frame cycling
	m.frame_time += delta
	if m.frame_time >= 1.0 / WALK_FPS:
		m.frame_time = 0.0
		m.walk_frame = (m.walk_frame + 1) % 3
		_apply_walk_frame(m)

	if m.move_t >= 1.0:
		m.node.position = m.move_to
		m.is_moving = false
		m.sprite.position.y = 0.0
		m.walk_frame = 0
		_apply_facing(m)

		# Trigger overworld events only for leader
		if m == _members[0]:
			overworld_node.on_player_moved(m.grid_pos)
	else:
		m.node.position = m.move_from.lerp(m.move_to, m.move_t)

func _cycle_party() -> void:
	# Save current positions and facings
	var positions: Array[Vector2i] = []
	var facings: Array[String] = []
	for m in _members:
		positions.append(m.grid_pos)
		facings.append(m.facing)

	# Rotate: front goes to back
	var first: Dictionary = _members.pop_front()
	_members.append(first)

	# Reassign positions so the new leader is in front
	for i in range(_members.size()):
		_members[i].grid_pos = positions[i]
		_members[i].node.position = grid_to_world(positions[i])
		_members[i].facing = facings[i]
		_apply_facing(_members[i])

	_update_z_order()
