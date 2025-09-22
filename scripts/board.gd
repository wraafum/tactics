extends Node2D
class_name Board

var grid_width: int = 8
var grid_height: int = 8
var tile_size: int = 64

var selected_tile: Vector2i = Vector2i(-1, -1)
var move_tiles: Array = []
var attack_tiles: Array = []
var enemy_range_tiles: Array = []

var background_color_dark := Color(0.1, 0.12, 0.18)
var background_color_light := Color(0.14, 0.16, 0.22)
var move_color := Color(0.1, 0.6, 1.0, 0.35)
var attack_color := Color(1.0, 0.2, 0.2, 0.35)
var enemy_range_color := Color(0.75, 0.3, 1.0, 0.25)
var selection_outline := Color(1.0, 0.9, 0.2, 0.9)

var tile_texture_dark: Texture2D
var tile_texture_light: Texture2D

func setup(size: Vector2i, new_tile_size: int) -> void:
    grid_width = size.x
    grid_height = size.y
    tile_size = new_tile_size
    _generate_tile_textures()
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

func set_enemy_range_tiles(tiles: Array) -> void:
    enemy_range_tiles = tiles.duplicate()
    update()

func _draw() -> void:
    for x in range(grid_width):
        for y in range(grid_height):
            var tile_position := Vector2(x * tile_size, y * tile_size)
            var rect := Rect2(tile_position, Vector2(tile_size, tile_size))
            var texture := tile_texture_dark if ((x + y) % 2 == 0) else tile_texture_light
            if texture:
                draw_texture_rect(texture, rect, false)
            else:
                var color := background_color_dark if ((x + y) % 2 == 0) else background_color_light
                draw_rect(rect, color)

    for tile in enemy_range_tiles:
        if is_inside(tile):
            var rect := Rect2(Vector2(tile.x * tile_size, tile.y * tile_size), Vector2(tile_size, tile_size))
            draw_rect(rect, enemy_range_color)

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

func _generate_tile_textures() -> void:
    tile_texture_dark = _create_tile_texture(background_color_dark)
    tile_texture_light = _create_tile_texture(background_color_light)

func _create_tile_texture(base_color: Color) -> Texture2D:
    if tile_size <= 0:
        return null
    var image := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
    image.lock()
    var border_thickness := max(int(tile_size / 16), 2)
    var accent_step := max(int(tile_size / 8), 4)
    var accent_color := base_color.lightened(0.08)
    var border_color := base_color.darkened(0.25)
    for x in range(tile_size):
        for y in range(tile_size):
            var color := base_color
            if x < border_thickness or y < border_thickness or x >= tile_size - border_thickness or y >= tile_size - border_thickness:
                color = border_color
            elif int(x / accent_step + y / accent_step) % 2 == 0:
                color = accent_color
            image.set_pixel(x, y, color)
    image.unlock()
    return ImageTexture.create_from_image(image)
