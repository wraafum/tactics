extends Node2D

const GRID_SIZE := Vector2i(8, 8)
const TILE_SIZE := 64
const PLAYER_TEAM := "player"
const ENEMY_TEAM := "enemy"
const DIRECTIONS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
const UNIT_SCENE := preload("res://scenes/Unit.tscn")

const CLASS_DEFS := {
    "Soldier": {
        "max_hp": 34,
        "move": 4,
        "attack_range": 1,
        "attack_power": 10,
    },
    "Archer": {
        "max_hp": 26,
        "move": 4,
        "attack_range": 3,
        "attack_power": 8,
    },
    "Mage": {
        "max_hp": 22,
        "move": 3,
        "attack_range": 2,
        "attack_power": 12,
    },
}

@onready var board: Board = $Board
@onready var units_root: Node = $Units
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var units: Array = []
var current_team: String = PLAYER_TEAM
var selected_unit: Unit
var available_moves: Array = []
var available_attacks: Array = []
var battle_over: bool = false
var state: String = "await_unit"

var end_turn_button: Button
var skip_attack_button: Button
var status_label: Label
var info_label: Label

func _ready() -> void:
    board.setup(GRID_SIZE, TILE_SIZE)
    board.position = Vector2(64, 64)
    setup_ui()
    spawn_initial_units()
    start_player_turn()

func setup_ui() -> void:
    end_turn_button = Button.new()
    end_turn_button.text = "End Turn"
    end_turn_button.position = Vector2(16, 16)
    end_turn_button.pressed.connect(_on_end_turn_pressed)
    canvas_layer.add_child(end_turn_button)

    skip_attack_button = Button.new()
    skip_attack_button.text = "Skip Attack"
    skip_attack_button.position = Vector2(16, 60)
    skip_attack_button.visible = false
    skip_attack_button.pressed.connect(_on_skip_attack_pressed)
    canvas_layer.add_child(skip_attack_button)

    status_label = Label.new()
    status_label.position = Vector2(200, 16)
    status_label.text = "Player Turn"
    canvas_layer.add_child(status_label)

    info_label = Label.new()
    info_label.position = Vector2(16, 110)
    info_label.text = "Click a unit, select a tile to move, then choose an enemy to attack."
    canvas_layer.add_child(info_label)

func spawn_initial_units() -> void:
    spawn_unit("Soldier", PLAYER_TEAM, Vector2i(1, 6), "Soldier")
    spawn_unit("Archer", PLAYER_TEAM, Vector2i(2, 6), "Archer")
    spawn_unit("Mage", PLAYER_TEAM, Vector2i(1, 5), "Mage")

    spawn_unit("Soldier", ENEMY_TEAM, Vector2i(6, 1), "Enemy Soldier")
    spawn_unit("Archer", ENEMY_TEAM, Vector2i(5, 1), "Enemy Archer")
    spawn_unit("Mage", ENEMY_TEAM, Vector2i(6, 2), "Enemy Mage")

func spawn_unit(class_name: String, team: String, position: Vector2i, display_name: String) -> void:
    var unit: Unit = UNIT_SCENE.instantiate()
    units_root.add_child(unit)
    unit.initialize(class_name, CLASS_DEFS[class_name], team, display_name, board)
    unit.set_grid_position(position)
    units.append(unit)

func start_player_turn() -> void:
    if battle_over:
        return
    current_team = PLAYER_TEAM
    reset_team_actions(PLAYER_TEAM)
    state = "await_unit"
    selected_unit = null
    available_moves.clear()
    available_attacks.clear()
    board.clear_highlights()
    end_turn_button.disabled = false
    status_label.text = "Player Turn"
    skip_attack_button.visible = false

func start_enemy_turn() -> void:
    if battle_over:
        return
    current_team = ENEMY_TEAM
    reset_team_actions(ENEMY_TEAM)
    state = "enemy_turn"
    selected_unit = null
    available_moves.clear()
    available_attacks.clear()
    board.clear_highlights()
    end_turn_button.disabled = true
    status_label.text = "Enemy Turn"
    skip_attack_button.visible = false
    _run_ai_turn()

func _run_ai_turn() -> void:
    await get_tree().create_timer(0.35).timeout
    for unit: Unit in get_units_for_team(ENEMY_TEAM):
        if battle_over:
            return
        if not unit.is_alive():
            continue
        ai_take_turn(unit)
        unit.has_acted = true
        await get_tree().create_timer(0.35).timeout
    if not battle_over:
        start_player_turn()

func ai_take_turn(unit: Unit) -> void:
    var attack_targets := get_attack_targets(unit)
    if attack_targets.is_empty():
        var move_tiles := get_reachable_tiles(unit)
        var target_tile := pick_ai_move_tile(unit, move_tiles)
        if target_tile != unit.grid_position and target_tile != Vector2i(-1, -1):
            move_unit(unit, target_tile)
        attack_targets = get_attack_targets(unit)
    if not attack_targets.is_empty():
        var target := pick_ai_attack_target(attack_targets)
        attack_unit(unit, target)

func pick_ai_move_tile(unit: Unit, move_tiles: Array) -> Vector2i:
    var best_tile := unit.grid_position
    var best_distance := 9999
    var player_units := get_units_for_team(PLAYER_TEAM)
    for tile in move_tiles:
        if tile == unit.grid_position:
            continue
        var occupied := get_unit_at(tile)
        if occupied and occupied != unit:
            continue
        var distance := get_distance_to_closest_enemy(tile, player_units)
        if distance < best_distance:
            best_distance = distance
            best_tile = tile
    return best_tile

func pick_ai_attack_target(targets: Array) -> Unit:
    var chosen: Unit = targets[0]
    var lowest_hp := chosen.hp
    for unit: Unit in targets:
        if unit.hp < lowest_hp:
            chosen = unit
            lowest_hp = unit.hp
    return chosen

func get_distance_to_closest_enemy(origin: Vector2i, enemies: Array) -> int:
    var best := 9999
    for enemy: Unit in enemies:
        var distance := abs(enemy.grid_position.x - origin.x) + abs(enemy.grid_position.y - origin.y)
        if distance < best:
            best = distance
    return best

func reset_team_actions(team: String) -> void:
    for unit: Unit in get_units_for_team(team):
        unit.has_acted = false

func get_units_for_team(team: String) -> Array:
    var filtered: Array = []
    for unit: Unit in units:
        if unit.team == team and unit.is_alive():
            filtered.append(unit)
    return filtered

func get_active_units(team: String) -> Array:
    var result: Array = []
    for unit: Unit in get_units_for_team(team):
        if not unit.has_acted:
            result.append(unit)
    return result

func _unhandled_input(event: InputEvent) -> void:
    if battle_over or current_team != PLAYER_TEAM:
        return
    if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return
    var mouse_event := event as InputEventMouseButton
    var tile := board.world_to_map(mouse_event.position)
    if not board.is_inside(tile):
        return
    match state:
        "await_unit":
            _handle_select_unit(tile)
        "await_move":
            _handle_move_selection(tile)
        "await_attack":
            _handle_attack_selection(tile)

func _handle_select_unit(tile: Vector2i) -> void:
    var unit := get_unit_at(tile)
    if unit and unit.team == PLAYER_TEAM and not unit.has_acted:
        selected_unit = unit
        available_moves = get_reachable_tiles(unit)
        var targets := get_attack_targets(unit)
        available_attacks = []
        for target: Unit in targets:
            available_attacks.append(target.grid_position)
        board.set_highlights(selected_unit.grid_position, available_moves, available_attacks)
        state = "await_move"

func _handle_move_selection(tile: Vector2i) -> void:
    if not selected_unit:
        return
    if tile == selected_unit.grid_position:
        _prepare_attack_phase()
        return
    if not available_moves.has(tile):
        return
    if get_unit_at(tile):
        return
    move_unit(selected_unit, tile)
    _prepare_attack_phase()

func _prepare_attack_phase() -> void:
    if not selected_unit:
        return
    var targets := get_attack_targets(selected_unit)
    available_attacks.clear()
    for target: Unit in targets:
        available_attacks.append(target.grid_position)
    board.set_highlights(selected_unit.grid_position, [], available_attacks)
    if available_attacks.is_empty():
        finish_unit_action()
    else:
        state = "await_attack"
        skip_attack_button.visible = true

func _handle_attack_selection(tile: Vector2i) -> void:
    if not selected_unit:
        return
    if not available_attacks.has(tile):
        return
    var target := get_unit_at(tile)
    if target and target.team == ENEMY_TEAM:
        attack_unit(selected_unit, target)
        finish_unit_action()

func finish_unit_action() -> void:
    if selected_unit:
        selected_unit.has_acted = true
    selected_unit = null
    state = "await_unit"
    available_moves.clear()
    available_attacks.clear()
    skip_attack_button.visible = false
    board.clear_highlights()
    check_turn_completion()

func move_unit(unit: Unit, tile: Vector2i) -> void:
    unit.set_grid_position(tile)

func get_unit_at(tile: Vector2i) -> Unit:
    for unit: Unit in units:
        if unit.is_alive() and unit.grid_position == tile:
            return unit
    return null

func get_reachable_tiles(unit: Unit) -> Array:
    var result: Array = []
    var visited := {}
    var queue: Array = []
    queue.append({"pos": unit.grid_position, "dist": 0})
    visited[unit.grid_position] = 0
    while not queue.is_empty():
        var current = queue.pop_front()
        var pos: Vector2i = current["pos"]
        var dist: int = current["dist"]
        if dist > unit.move_range:
            continue
        result.append(pos)
        for direction in DIRECTIONS:
            var next := pos + direction
            if not board.is_inside(next):
                continue
            if visited.has(next) and visited[next] <= dist + 1:
                continue
            var occupant := get_unit_at(next)
            if occupant and occupant != unit:
                continue
            visited[next] = dist + 1
            queue.append({"pos": next, "dist": dist + 1})
    return result

func get_attack_targets(unit: Unit) -> Array:
    var targets: Array = []
    for tile in get_attack_tiles(unit):
        var occupant := get_unit_at(tile)
        if occupant and occupant.team != unit.team:
            targets.append(occupant)
    return targets

func get_attack_tiles(unit: Unit) -> Array:
    var tiles: Array = []
    var max_range := unit.attack_range
    for dx in range(-max_range, max_range + 1):
        for dy in range(-max_range, max_range + 1):
            var distance := abs(dx) + abs(dy)
            if distance == 0 or distance > max_range:
                continue
            var tile := unit.grid_position + Vector2i(dx, dy)
            if board.is_inside(tile):
                tiles.append(tile)
    return tiles

func attack_unit(attacker: Unit, target: Unit) -> void:
    target.take_damage(attacker.attack_power)
    if not target.is_alive():
        remove_unit(target)
    check_battle_over()

func remove_unit(unit: Unit) -> void:
    if selected_unit == unit:
        selected_unit = null
    units.erase(unit)
    unit.queue_free()

func check_battle_over() -> void:
    if battle_over:
        return
    var player_units := get_units_for_team(PLAYER_TEAM)
    var enemy_units := get_units_for_team(ENEMY_TEAM)
    if player_units.is_empty():
        end_battle("Enemy")
    elif enemy_units.is_empty():
        end_battle("Player")

func end_battle(winner: String) -> void:
    battle_over = true
    board.clear_highlights()
    end_turn_button.disabled = true
    skip_attack_button.visible = false
    status_label.text = "%s Wins!" % winner

func check_turn_completion() -> void:
    if battle_over:
        return
    var remaining := get_active_units(current_team)
    if remaining.is_empty():
        if current_team == PLAYER_TEAM:
            start_enemy_turn()
        else:
            start_player_turn()

func _on_end_turn_pressed() -> void:
    if battle_over or current_team != PLAYER_TEAM:
        return
    for unit: Unit in get_units_for_team(PLAYER_TEAM):
        unit.has_acted = true
    selected_unit = null
    board.clear_highlights()
    state = "await_unit"
    skip_attack_button.visible = false
    check_turn_completion()

func _on_skip_attack_pressed() -> void:
    if battle_over or current_team != PLAYER_TEAM:
        return
    finish_unit_action()
