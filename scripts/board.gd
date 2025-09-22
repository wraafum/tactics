extends Node2D
class_name Board

var grid_width: int = 8
var grid_height: int = 8
var tile_size: int = 64

var selected_tile: Vector2i = Vector2i(-1, -1)
var move_tiles: Array = []
var attack_tiles: Array = []

var background_color_dark := Color(0.1, 0.12, 0.18)
var background_color_light := Color(0.14, 0.16, 0.22)
var move_color := Color(0.1, 0.6, 1.0, 0.35)
var attack_color := Color(1.0, 0.2, 0.2, 0.35)
var selection_outline := Color(1.0, 0.9, 0.2, 0.9)

func setup(size: Vector2i, new_tile_size: int) -> void:
    grid_width = size.x
    grid_height = size.y
    tile_size = new_tile_size
    update()

func clear_highlights() -> void:
    selected_tile = Vector2i(-1, -1)
    move_tiles.clear()
    attack_tiles.clear()
    update()

func set_highlights(selected: Vector2i, moves: Array, attacks: Array) -> void:
    selected_tile = selected
    move_tiles = moves.duplicate()
    attack_tiles = attacks.duplicate()
    update()

func _draw() -> void:
    for x in range(grid_width):
        for y in range(grid_height):
            var tile_position := Vector2(x * tile_size, y * tile_size)
            var color := background_color_dark if ((x + y) % 2 == 0) else background_color_light
            draw_rect(Rect2(tile_position, Vector2(tile_size, tile_size)), color)

    for tile in move_tiles:
        if is_inside(tile):
            var rect := Rect2(Vector2(tile.x * tile_size, tile.y * tile_size), Vector2(tile_size, tile_size))
            draw_rect(rect, move_color)

    for tile in attack_tiles:
        if is_inside(tile):
            var rect := Rect2(Vector2(tile.x * tile_size, tile.y * tile_size), Vector2(tile_size, tile_size))
            draw_rect(rect, attack_color)

    if selected_tile != Vector2i(-1, -1) and is_inside(selected_tile):
        var rect := Rect2(Vector2(selected_tile.x * tile_size, selected_tile.y * tile_size), Vector2(tile_size, tile_size))
        draw_rect(rect, Color(0, 0, 0, 0), false, 3.0, selection_outline)

func map_to_world(tile: Vector2i) -> Vector2:
    return Vector2(tile.x * tile_size + tile_size * 0.5, tile.y * tile_size + tile_size * 0.5)

func world_to_map(point: Vector2) -> Vector2i:
    var local_point := to_local(point)
    var x := int(floor(local_point.x / tile_size))
    var y := int(floor(local_point.y / tile_size))
    return Vector2i(x, y)

func is_inside(tile: Vector2i) -> bool:
    return tile.x >= 0 and tile.y >= 0 and tile.x < grid_width and tile.y < grid_height
