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

@onready var sprite: Sprite2D = $Sprite
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

var _texture_cache := {}

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
    if not sprite or not label:
        return
    var base_color := CLASS_COLORS.get(class_name, Color(0.8, 0.8, 0.8))
    var team_tint := TEAM_TINTS.get(team, Color(1, 1, 1))
    var final_color := base_color.lerp(team_tint, 0.35)
    var tile_pixels := _get_tile_visual_size()
    sprite.texture = _get_placeholder_texture(tile_pixels, final_color)
    sprite.scale = Vector2.ONE
    sprite.position = Vector2.ZERO
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.text = "%s\nHP: %d" % [unit_name, hp]
    var label_width := float(tile_pixels)
    label.custom_minimum_size = Vector2(label_width, 36)
    label.position = Vector2(-label_width * 0.5, tile_pixels * 0.35)

func take_damage(amount: int) -> void:
    hp = max(hp - amount, 0)
    update_visual()

func is_alive() -> bool:
    return hp > 0

func _get_tile_visual_size() -> int:
    var size := 56
    if board and board.tile_size > 0:
        size = max(board.tile_size - 8, 32)
    return size

func _get_placeholder_texture(size: int, fill_color: Color) -> Texture2D:
    var key := "%d_%s" % [size, fill_color.to_html(false)]
    if _texture_cache.has(key):
        return _texture_cache[key]
    var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
    image.lock()
    var outline := max(int(size * 0.08), 2)
    var accent := max(int(size * 0.12), 3)
    var edge_color := fill_color.darkened(0.3)
    var accent_color := fill_color.lightened(0.18)
    for x in range(size):
        for y in range(size):
            var color := fill_color
            if x < outline or y < outline or x >= size - outline or y >= size - outline:
                color = edge_color
            elif abs(x - size / 2) <= accent and abs(y - size / 2) <= 1:
                color = accent_color
            elif abs(y - size / 2) <= accent and abs(x - size / 2) <= 1:
                color = accent_color
            image.set_pixel(x, y, color)
    image.unlock()
    var texture := ImageTexture.create_from_image(image)
    texture.set_path("")
    _texture_cache[key] = texture
    return texture
