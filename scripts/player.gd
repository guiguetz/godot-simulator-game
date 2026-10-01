@tool
class_name Player
extends CharacterBody2D

## Movimentacao top-down estilo Stardew Valley + uso de ferramentas.
## Andar/correr (Shift) configuravel no menu de pausa (Esc > Opcoes).
## A hotbar/inventario definem a ferramenta/máquina selecionada. Veja
## scripts/inventory.gd, scripts/hud.gd e scripts/world.gd (use_tool).

const WALK_SPEED := 70.0
const RUN_SPEED := 130.0
const RUN_ANIM_SPEED := 1.6
const TOOL_TIME := 0.35
const STEP_INTERVAL := 0.34
const FACING_NAMES := ["down", "up", "left", "right"]
const TILE_SIZE := 16.0
## Meia-caixa maxima do teste de andabilidade: fica logo abaixo de meio tile
## para nao invadir o tile vizinho e travar o player em quinas (issue #4).
const MAX_FEET_HALF := TILE_SIZE * 0.5 - 0.5

@export var sprite_frames: SpriteFrames
@export var placeholder_texture: Texture2D
@export var world_bounds: Rect2 = Rect2()

var walkable_check: Callable = Callable()

@export_range(0.0, 16.0, 0.5) var collision_padding: float = 2.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing: String = "down"
var _busy: float = 0.0
var _step_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_apply_skin_frames()
	_play("idle")


func _apply_skin_frames() -> void:
	var idx := GameSettings.skin
	if idx >= 0 and idx < GameData.SKIN_FRAMES.size():
		_sprite.sprite_frames = GameData.SKIN_FRAMES[idx]
	elif sprite_frames != null:
		_sprite.sprite_frames = sprite_frames
	else:
		_sprite.sprite_frames = _build_placeholder_frames()


## Troca a skin do personagem (menu de pausa > Aparencia).
func apply_skin(index: int) -> void:
	if index < 0 or index >= GameData.SKIN_FRAMES.size():
		return
	GameSettings.set_skin(index)
	_sprite.sprite_frames = GameData.SKIN_FRAMES[index]
	_play("idle")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _ui_mode_active():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _busy > 0.0:
		_busy -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_clamp_bounds()
		if _busy <= 0.0:
			_update_animation(Vector2.ZERO, false)
		return

	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if direction.length() > 1.0:
		direction = direction.normalized()

	var running := GameSettings.is_running(Input.is_action_pressed("run"))
	var speed := RUN_SPEED if running else WALK_SPEED
	velocity = direction * speed
	_block_unwalkable(delta)
	move_and_slide()
	_clamp_bounds()
	_update_animation(direction, running)
	_footsteps(delta, direction)

	if Input.is_action_just_pressed("action"):
		_use_selected()


func _clamp_bounds() -> void:
	if world_bounds.size != Vector2.ZERO:
		global_position = global_position.clamp(world_bounds.position, world_bounds.end)


func _footsteps(delta: float, direction: Vector2) -> void:
	if direction.length_squared() > 0.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = STEP_INTERVAL
			AudioManager.play_sfx("step", -8.0)
	else:
		_step_timer = 0.0


## True quando um modo de UI (pesca/decoracao) controla a entrada.
func _ui_mode_active() -> bool:
	var fishing := get_tree().get_first_node_in_group("fishing")
	if fishing != null and fishing.active:
		return true
	var decor := get_tree().get_first_node_in_group("decor")
	if decor != null and decor.active:
		return true
	return false


# --- Ferramentas -----------------------------------------------------------

func _use_selected() -> void:
	var entry := Inventory.current_entry()
	if entry.is_empty():
		return
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	var cell := facing_cell()
	if entry.get("kind", "tool") == "machine":
		world.place_machine(entry["id"], cell)
		return
	var tool: int = entry["id"]
	if tool == Enums.Tool.FISH:
		var fishing := get_tree().get_first_node_in_group("fishing")
		if fishing != null and not fishing.active and world.can_fish(cell):
			_play("fish")
			_busy = TOOL_TIME
			fishing.start(GameData.roll_fish())
			return
	_play(_tool_anim(tool))
	_busy = TOOL_TIME
	world.use_tool(tool, Inventory.selected_seed, cell)


## Celula alvo na direcao que o player esta olhando.
func facing_cell() -> Vector2i:
	var cell := Vector2i(
		int(floor(global_position.x / 16.0)),
		int(floor(global_position.y / 16.0))
	)
	return cell + _facing_vector()


func _facing_vector() -> Vector2i:
	match _facing:
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
		"up":
			return Vector2i.UP
		_:
			return Vector2i.DOWN


func _tool_anim(tool: int) -> String:
	match tool:
		Enums.Tool.HOE:
			return "hoe"
		Enums.Tool.WATER:
			return "water"
		Enums.Tool.AXE:
			return "axe"
		Enums.Tool.SWORD:
			return "sword"
		Enums.Tool.FISH:
			return "fish"
		_:
			return "seed"


# --- Movimento / andabilidade ----------------------------------------------

func _block_unwalkable(delta: float) -> void:
	if not walkable_check.is_valid() or velocity == Vector2.ZERO:
		return
	var step := velocity * delta
	if _area_walkable(global_position + step):
		return
	if _area_walkable(global_position + Vector2(step.x, 0.0)):
		velocity.y = 0.0
	elif _area_walkable(global_position + Vector2(0.0, step.y)):
		velocity.x = 0.0
	else:
		velocity = Vector2.ZERO


func _area_walkable(center: Vector2) -> bool:
	var feet_center := center + Vector2(0.0, -3.0)
	var half := Vector2(5.0, 3.0) + Vector2(collision_padding, collision_padding)
	half.x = minf(half.x, MAX_FEET_HALF)
	half.y = minf(half.y, MAX_FEET_HALF)
	return (
		walkable_check.call(feet_center + Vector2(-half.x, -half.y))
		and walkable_check.call(feet_center + Vector2(half.x, -half.y))
		and walkable_check.call(feet_center + Vector2(-half.x, half.y))
		and walkable_check.call(feet_center + Vector2(half.x, half.y))
	)


# --- Animacao --------------------------------------------------------------

func _update_animation(direction: Vector2, running: bool) -> void:
	if direction.length_squared() > 0.0:
		_facing = _direction_name(direction)
		_sprite.speed_scale = RUN_ANIM_SPEED if running else 1.0
		_play("walk")
	else:
		_sprite.speed_scale = 1.0
		_play("idle")


func _play(anim: String) -> void:
	var full := "%s_%s" % [anim, _facing]
	if _sprite.animation != full:
		_sprite.play(full)


func _direction_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"


# --- Placeholder -----------------------------------------------------------
# Usado apenas se nenhum SpriteFrames for fornecido. Folha 4x4 (4 direcoes x
# 4 frames) de 16x24, linhas: baixo, cima, esquerda, direita.

func _build_placeholder_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var texture := placeholder_texture
	if texture == null:
		texture = load("res://assets/sprites/player_placeholder.png")

	var frame_size := Vector2i(16, 24)
	for row in range(FACING_NAMES.size()):
		var dir: String = FACING_NAMES[row]

		frames.add_animation("idle_%s" % dir)
		frames.set_animation_speed("idle_%s" % dir, 1.0)
		frames.set_animation_loop("idle_%s" % dir, false)
		frames.add_frame("idle_%s" % dir, _atlas_frame(texture, 1, row, frame_size))

		frames.add_animation("walk_%s" % dir)
		frames.set_animation_speed("walk_%s" % dir, 8.0)
		frames.set_animation_loop("walk_%s" % dir, true)
		for col in range(4):
			frames.add_frame("walk_%s" % dir, _atlas_frame(texture, col, row, frame_size))

	return frames


func _atlas_frame(texture: Texture2D, col: int, row: int, frame_size: Vector2i) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = texture
	at.region = Rect2(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
	return at
