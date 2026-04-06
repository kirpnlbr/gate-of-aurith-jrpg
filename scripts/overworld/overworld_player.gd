extends Node2D

const TILE_SIZE := 48
const MOVE_DURATION := 0.15
const SPRITE_TARGET_HEIGHT := 40.0
const BOB_AMOUNT := 3.0  # screen pixels of vertical bounce while walking
const BOB_SPEED := 14.0  # oscillation speed

const DIR_UP    := Vector2i(0, -1)
const DIR_DOWN  := Vector2i(0, 1)
const DIR_LEFT  := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)

var overworld_node: Node2D = null
var grid_pos := Vector2i.ZERO
var is_moving := false
var move_from := Vector2.ZERO
var move_to := Vector2.ZERO
var move_t := 0.0
var frozen := false

var sprite: Sprite2D = null
var _facing := "down"
var _idle_frames: Dictionary = {}  # "down" -> tex
var _bob_time := 0.0

func init(overworld: Node2D, start_pos: Vector2i) -> void:
	overworld_node = overworld
	grid_pos = start_pos
	position = grid_to_world(grid_pos)

	sprite = Sprite2D.new()
	add_child(sprite)

	_load_sprites()
	_set_facing()

func _load_sprites() -> void:
	var base_path := "res://assets/sprites/overworld/mage/"
	for dir in ["up", "down", "left", "right"]:
		var idle_path := base_path + "mage_%s_idle.png" % dir
		var tex := load(idle_path) as Texture2D
		if tex == null:
			push_warning("OverworldPlayer: Could not load texture: %s" % idle_path)
		_idle_frames[dir] = tex

func _set_facing() -> void:
	var tex: Texture2D = _idle_frames.get(_facing)
	if tex:
		sprite.texture = tex
		var tex_h := float(tex.get_height())
		if tex_h > 0:
			var s := SPRITE_TARGET_HEIGHT / tex_h
			sprite.scale = Vector2(s, s)

static func grid_to_world(gp: Vector2i) -> Vector2:
	return Vector2(gp.x * TILE_SIZE + TILE_SIZE * 0.5,
				   gp.y * TILE_SIZE + TILE_SIZE * 0.5)

func _process(delta: float) -> void:
	if frozen:
		return
	if is_moving:
		_tick_movement(delta)
		_bob_time += delta
		sprite.position.y = -abs(sin(_bob_time * BOB_SPEED)) * BOB_AMOUNT
	else:
		_poll_input()

func _poll_input() -> void:
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
	var target := grid_pos + dir
	if overworld_node.is_walkable(target.x, target.y):
		Sfx.play("footstep", -10.0, randf_range(0.9, 1.1))
		is_moving = true
		move_from = position
		move_to = grid_to_world(target)
		move_t = 0.0
		_bob_time = 0.0

		if dir == DIR_UP:
			_facing = "up"
		elif dir == DIR_DOWN:
			_facing = "down"
		elif dir == DIR_LEFT:
			_facing = "left"
		elif dir == DIR_RIGHT:
			_facing = "right"
		_set_facing()

func _tick_movement(delta: float) -> void:
	move_t += delta / MOVE_DURATION
	if move_t >= 1.0:
		position = move_to
		grid_pos = Vector2i(int(move_to.x) / TILE_SIZE, int(move_to.y) / TILE_SIZE)
		is_moving = false
		sprite.position.y = 0.0
		overworld_node.on_player_moved(grid_pos)
	else:
		position = move_from.lerp(move_to, move_t)
