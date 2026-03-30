extends Node2D

const TILE_SIZE := 48
const MOVE_DURATION := 0.15

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

func init(overworld: Node2D, start_pos: Vector2i) -> void:
	overworld_node = overworld
	grid_pos = start_pos
	position = grid_to_world(grid_pos)
	# Create placeholder sprite (blue rectangle)
	sprite = Sprite2D.new()
	var img := Image.create(32, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.5, 1.0))
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

static func grid_to_world(gp: Vector2i) -> Vector2:
	return Vector2(gp.x * TILE_SIZE + TILE_SIZE * 0.5,
				   gp.y * TILE_SIZE + TILE_SIZE * 0.5)

func _process(delta: float) -> void:
	if frozen:
		return
	if is_moving:
		_tick_movement(delta)
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
		is_moving = true
		move_from = position
		move_to = grid_to_world(target)
		move_t = 0.0

func _tick_movement(delta: float) -> void:
	move_t += delta / MOVE_DURATION
	if move_t >= 1.0:
		position = move_to
		grid_pos = Vector2i(int(move_to.x) / TILE_SIZE, int(move_to.y) / TILE_SIZE)
		is_moving = false
		overworld_node.on_player_moved(grid_pos)
	else:
		position = move_from.lerp(move_to, move_t)
