# NikitaGrid.gd
# ニキータへの売却ゾーン（5×5マス）。
# JunkBox.entries とは独立した独自リストを管理する。
extends Control

signal items_changed(items: Array)   # 格納アイテムが変化したとき

const ROWS         := 5
const COLS         := 5
const CELL_SIZE    := 46
const CELL_MARGIN  := 2
const GRID_OFFSET_X := 4
const GRID_OFFSET_Y := 4

# 格納中アイテム: {item: Dict, row: int, col: int, w: int, h: int}
var entries: Array = []

# ── ドラッグ状態 ──────────────────────────
var _drag_entry: Dictionary = {}
var _drag_offset: Vector2   = Vector2.ZERO
var _drag_pos: Vector2      = Vector2.ZERO
var _is_dragging := false
var _drag_threshold := 6.0
var _press_pos: Vector2     = Vector2.ZERO
var _press_entry: Dictionary = {}
var _pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

# ── 外部からアイテムを追加 ────────────────
# 空きセルに自動配置。成功したら true
func add_item(item: Dictionary) -> bool:
	var cell := _find_free_cell(1, 1)
	if cell.x < 0:
		return false
	entries.append({"item": item, "row": cell.y, "col": cell.x, "w": 1, "h": 1})
	items_changed.emit(_get_items())
	queue_redraw()
	return true

# ── 全アイテム取得 ────────────────────────
func get_items() -> Array:
	return _get_items()

func _get_items() -> Array:
	var result: Array = []
	for e: Dictionary in entries:
		result.append(e["item"])
	return result

func clear() -> void:
	entries = []
	items_changed.emit([])
	queue_redraw()

# ── 描画 ──────────────────────────────────
func _draw() -> void:
	_draw_bg()
	_draw_items()
	if _is_dragging:
		_draw_ghost()

func _draw_bg() -> void:
	for r in ROWS:
		for c in COLS:
			var rect := _cell_rect(r, c)
			draw_rect(rect, Color(0.25, 0.18, 0.12, 0.9), true)
			draw_rect(rect, Color(0.65, 0.45, 0.2, 0.5), false, 1.0)

func _draw_items() -> void:
	for entry: Dictionary in entries:
		var r: int = int(entry["row"])
		var c: int = int(entry["col"])
		var w: int = int(entry["w"])
		var h: int = int(entry["h"])
		var item: Dictionary = entry["item"]

		var x := GRID_OFFSET_X + c * (CELL_SIZE + CELL_MARGIN)
		var y := GRID_OFFSET_Y + r * (CELL_SIZE + CELL_MARGIN)
		var pw := w * CELL_SIZE + (w - 1) * CELL_MARGIN
		var ph := h * CELL_SIZE + (h - 1) * CELL_MARGIN
		var item_rect := Rect2(x, y, pw, ph)

		var alpha: float = 0.3 if (_is_dragging and _drag_entry == entry) else 1.0
		var rarity: String = item.get("rarity", "common")
		var bg_col: Color = GameData.RARITY_BG_COLORS.get(rarity, Color(0.3, 0.2, 0.1, 0.8))
		var bd_col: Color = GameData.RARITY_COLORS.get(rarity, Color(0.8, 0.6, 0.2))
		bg_col.a *= alpha
		bd_col.a *= alpha

		draw_rect(item_rect, bg_col, true)
		draw_rect(item_rect, bd_col, false, 2.0)

		var icon: String = item.get("icon", "?")
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		var text_pos  := item_rect.get_center() - text_size / 2 + Vector2(0, text_size.y * 0.35)
		draw_string(font, text_pos, icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, alpha))

func _draw_ghost() -> void:
	if _drag_entry.is_empty():
		return
	var item: Dictionary = _drag_entry["item"]
	var pw := CELL_SIZE
	var ph := CELL_SIZE
	var ghost_rect := Rect2(_drag_pos - _drag_offset, Vector2(pw, ph))

	var cell := _pos_to_cell(ghost_rect.get_center())
	if cell.x >= 0 and _can_place(cell.y, cell.x, 1, 1, _drag_entry):
		var snap_rect := Rect2(
			GRID_OFFSET_X + cell.x * (CELL_SIZE + CELL_MARGIN),
			GRID_OFFSET_Y + cell.y * (CELL_SIZE + CELL_MARGIN),
			CELL_SIZE, CELL_SIZE)
		draw_rect(snap_rect, Color(1.0, 0.7, 0.2, 0.25), true)
		draw_rect(snap_rect, Color(1.0, 0.7, 0.2, 0.7), false, 2.0)

	var rarity: String = item.get("rarity", "common")
	var bg_col: Color = GameData.RARITY_BG_COLORS.get(rarity, Color(0.3, 0.2, 0.1, 0.8))
	bg_col.a = 0.75
	draw_rect(ghost_rect, bg_col, true)
	draw_rect(ghost_rect, Color(1, 1, 1, 0.5), false, 2.0)
	var icon: String = item.get("icon", "?")
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	var text_pos  := ghost_rect.get_center() - text_size / 2 + Vector2(0, text_size.y * 0.35)
	draw_string(font, text_pos, icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 0.85))

# ── 入力処理 ──────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_press_pos = mb.position
			_pressed = true
			var cell := _pos_to_cell(mb.position)
			_press_entry = _get_entry_at(cell.y, cell.x) if cell.x >= 0 else {}
		elif not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _is_dragging:
				_on_release(mb.position)
			_pressed = false
	elif event is InputEventMouseMotion:
		if _pressed and not _is_dragging:
			if (event.position - _press_pos).length() >= _drag_threshold and not _press_entry.is_empty():
				_drag_entry  = _press_entry
				_drag_offset = _press_pos - Vector2(
					GRID_OFFSET_X + int(_press_entry["col"]) * (CELL_SIZE + CELL_MARGIN),
					GRID_OFFSET_Y + int(_press_entry["row"]) * (CELL_SIZE + CELL_MARGIN))
				_drag_pos    = event.position
				_is_dragging = true
		if _is_dragging:
			_drag_pos = event.position
			queue_redraw()

func _on_release(pos: Vector2) -> void:
	_is_dragging = false
	if _drag_entry.is_empty():
		return
	var drop_cell := _pos_to_cell(pos)
	if drop_cell.x >= 0 and _can_place(drop_cell.y, drop_cell.x, 1, 1, _drag_entry):
		_drag_entry["row"] = drop_cell.y
		_drag_entry["col"] = drop_cell.x
	_drag_entry = {}
	items_changed.emit(_get_items())
	queue_redraw()

# ── ユーティリティ ────────────────────────
func _can_place(row: int, col: int, w: int, h: int, exclude: Dictionary = {}) -> bool:
	if row < 0 or col < 0 or row + h > ROWS or col + w > COLS:
		return false
	for entry: Dictionary in entries:
		if entry == exclude:
			continue
		var er: int = int(entry["row"])
		var ec: int = int(entry["col"])
		var ew: int = int(entry["w"])
		var eh: int = int(entry["h"])
		if row < er + eh and row + h > er and col < ec + ew and col + w > ec:
			return false
	return true

func _find_free_cell(w: int, h: int) -> Vector2i:
	for r in ROWS:
		for c in COLS:
			if _can_place(r, c, w, h):
				return Vector2i(c, r)
	return Vector2i(-1, -1)

func _get_entry_at(row: int, col: int) -> Dictionary:
	for entry: Dictionary in entries:
		var er: int = int(entry["row"])
		var ec: int = int(entry["col"])
		var ew: int = int(entry["w"])
		var eh: int = int(entry["h"])
		if row >= er and row < er + eh and col >= ec and col < ec + ew:
			return entry
	return {}

func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		GRID_OFFSET_X + col * (CELL_SIZE + CELL_MARGIN),
		GRID_OFFSET_Y + row * (CELL_SIZE + CELL_MARGIN),
		CELL_SIZE, CELL_SIZE)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	var cx := int((pos.x - GRID_OFFSET_X) / (CELL_SIZE + CELL_MARGIN))
	var cy := int((pos.y - GRID_OFFSET_Y) / (CELL_SIZE + CELL_MARGIN))
	if cx < 0 or cx >= COLS or cy < 0 or cy >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(cx, cy)

func get_required_size() -> Vector2:
	return Vector2(
		GRID_OFFSET_X * 2 + COLS * (CELL_SIZE + CELL_MARGIN),
		GRID_OFFSET_Y * 2 + ROWS * (CELL_SIZE + CELL_MARGIN))
