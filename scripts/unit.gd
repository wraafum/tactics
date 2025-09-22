extends Node2D
class_name Unit

var class_name: String = "Soldier"
var team: String = "player"
var unit_name: String = "Unit"
var max_hp: int = 20
var hp: int = 20
var move_range: int = 3
var attack_range: int = 1
var attack_power: int = 6
var has_acted: bool = false
var grid_position: Vector2i = Vector2i.ZERO
var board: Board

@onready var body: ColorRect = $Body
@onready var label: Label = $Label

const CLASS_COLORS := {
    "Soldier": Color(0.35, 0.65, 0.35),
    "Archer": Color(0.7, 0.55, 0.25),
    "Mage": Color(0.6, 0.35, 0.75),
}

const TEAM_TINTS := {
    "player": Color(0.25, 0.45, 0.95),
    "enemy": Color(0.95, 0.35, 0.35),
}

func _ready() -> void:
    update_visual()

func initialize(new_class: String, class_data: Dictionary, new_team: String, display_name: String, board_ref: Board) -> void:
    class_name = new_class
    team = new_team
    unit_name = display_name
    board = board_ref
    max_hp = class_data.get("max_hp", 20)
    hp = max_hp
    move_range = class_data.get("move", 3)
    attack_range = class_data.get("attack_range", 1)
    attack_power = class_data.get("attack_power", 6)
    has_acted = false
    update_visual()

func set_grid_position(tile: Vector2i) -> void:
    grid_position = tile
    if board:
        position = board.map_to_world(tile)

func update_visual() -> void:
    if not body or not label:
        return
    var base_color := CLASS_COLORS.get(class_name, Color(0.8, 0.8, 0.8))
    var team_tint := TEAM_TINTS.get(team, Color(1, 1, 1))
    body.color = base_color.lerp(team_tint, 0.35)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.text = "%s\nHP: %d" % [unit_name, hp]

func take_damage(amount: int) -> void:
    hp = max(hp - amount, 0)
    update_visual()

func is_alive() -> bool:
    return hp > 0
