# JunkBoxGrid.gd
# ジャンクボックスのグリッドUIを描画し、ドラッグ&ドロップを処理する。
extends Control

signal item_selected(entry: Dictionary)      # クリックで選択
signal item_deselected
signal send_to_nikita(entry: Dictionary)     # ニキータグリッドへ送る
signal pending_placed(item: Dictionary)      # 未格納→グリッドに配置
signal pending_returned(item: Dictionary)    # グリッド→未格納に戻す
signal layout_changed

const CELL_SIZE   := 52
const CELL_MARGIN := 2
const GRID_OFFSET_X := 4
const GRID_OFFSET_Y := 4

var mode := "junkbox"   # "junkbox" or "stash_phase"

var _pending_items: Array = []
var _selected_entry: Dictionary = {}   # 現在選択中のエントリ

# ── ドラッグ状態 ──────────────────────────
var _drag_entry: Dictionary        = {}
var _drag_pending_item: Dictionary = {}
var _drag_offset: Vector2          = Vector2.ZERO
var _drag_pos: Vector2             = Vector2.ZERO
var _is_dragging := false
var _drag_threshold := 6.0   # この距離以上動いたらドラッグ開始
var _press_pos: Vector2            = Vector2.ZERO
var _press_entry: Dictionary       = {}
var _press_pending: Dictionary     = {}
var _pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	JunkBox.item_placed.connect(func(_e): queue_redraw())
	JunkBox.item_removed.connect(func(_e): queue_redraw())
	JunkBox.item_sold.connect(func(_e, _p): queue_redraw())

func set_pending_items(items: Array) -> void:
	_pending_items = items.duplicate()
	queue_redraw()

func get_pending_items() -> Array:
	return _pending_items.duplicate()

func clear_selection() -> void:
	_selected_entry = {}
	queue_redraw()

# ── 描画 ──────────────────────────────────
func _draw() -> void:
	_draw_grid_bg()
	_draw_placed_items()
	if _is_dragging:
		_draw_drag_ghost()

func _draw_grid_bg() -> void:
	for r in JunkBox.ROWS:
		for c in JunkBox.COLS:
			var rect := _cell_rect(r, c)
			draw_rect(rect, Color(0.15, 0.18, 0.25, 0.9), true)
			draw_rect(rect, Color(0.35, 0.45, 0.6, 0.5), false, 1.0)

func _draw_placed_items() -> void:
	for entry: Dictionary in JunkBox.entries:
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

		var is_selected: bool = (entry == _selected_entry)
		var alpha: float = 0.35 if (_is_dragging and _drag_entry == entry) else 1.0

		var rarity: String = item.get("rarity", "common")
		var bg_col: Color  = GameData.RARITY_BG_COLORS.get(rarity, Color(0.2, 0.22, 0.3, 0.8))
		var bd_col: Color  = GameData.RARITY_COLORS.get(rarity, Color.GRAY)
		bg_col.a *= alpha
		bd_col.a *= alpha

		draw_rect(item_rect, bg_col, true)

		# 選択中は明るいボーダー
		if is_selected:
			draw_rect(item_rect, Color(1, 0.9, 0.2, 0.9), false, 3.0)
		else:
			draw_rect(item_rect, bd_col, false, 2.0)

		var icon: String = item.get("icon", "?")
		var font := ThemeDB.fallback_font
		var font_size := 28 if (w == 1 and h == 1) else 36
		var text_size := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos  := item_rect.get_center() - text_size / 2 + Vector2(0, text_size.y * 0.35)
		draw_string(font, text_pos, icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			Color(1, 1, 1, alpha))

func _draw_drag_ghost() -> void:
	var item: Dictionary = {}
	var w := 1
	var h := 1
	if not _drag_entry.is_empty():
		item = _drag_entry["item"]
		w = int(_drag_entry["w"])
		h = int(_drag_entry["h"])
	elif not _drag_pending_item.is_empty():
		item = _drag_pending_item
	if item.is_empty():
		return

	var pw := w * CELL_SIZE + (w - 1) * CELL_MARGIN
	var ph := h * CELL_SIZE + (h - 1) * CELL_MARGIN
	var ghost_rect := Rect2(_drag_pos - _drag_offset, Vector2(pw, ph))

	var cell := _pos_to_cell(ghost_rect.position + Vector2(pw, ph) / 2)
	var exclude: Dictionary = _drag_entry if not _drag_entry.is_empty() else {}
	if cell.x >= 0 and JunkBox.can_place(cell.y, cell.x, w, h, exclude):
		var snap_rect := Rect2(
			GRID_OFFSET_X + cell.x * (CELL_SIZE + CELL_MARGIN),
			GRID_OFFSET_Y + cell.y * (CELL_SIZE + CELL_MARGIN),
			pw, ph)
		draw_rect(snap_rect, Color(0.3, 1.0, 0.5, 0.25), true)
		draw_rect(snap_rect, Color(0.3, 1.0, 0.5, 0.7), false, 2.0)

	var rarity: String = item.get("rarity", "common")
	var bg_col: Color = GameData.RARITY_BG_COLORS.get(rarity, Color(0.2, 0.22, 0.3, 0.8))
	bg_col.a = 0.75
	draw_rect(ghost_rect, bg_col, true)
	draw_rect(ghost_rect, Color(1, 1, 1, 0.5), false, 2.0)

	var icon: String = item.get("icon", "?")
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	var text_pos  := ghost_rect.get_center() - text_size / 2 + Vector2(0, text_size.y * 0.35)
	draw_string(font, text_pos, icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1, 0.85))

# ── 入力処理 ──────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_press_pos = mb.position
			_pressed = true
			var cell := _pos_to_cell(mb.position)
			if cell.x >= 0:
				_press_entry   = JunkBox.get_entry_at(cell.y, cell.x)
				_press_pending = {}
			else:
				_press_entry   = {}
				_press_pending = {}
		elif not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _is_dragging:
				_on_left_release(mb.position)
			else:
				# ドラッグなし → クリック選択
				_on_click_select(mb.position)
			_pressed = false

	elif event is InputEventMouseMotion:
		if _pressed and not _is_dragging:
			var dist: float = (event.position - _press_pos).length()
			if dist >= _drag_threshold:
				# ドラッグ開始
				if not _press_entry.is_empty():
					_start_drag_entry(_press_entry, _press_pos)
				elif not _press_pending.is_empty():
					start_drag_pending(_press_pending, _press_pos)
		if _is_dragging:
			_drag_pos = event.position
			queue_redraw()

func _on_click_select(pos: Vector2) -> void:
	var cell := _pos_to_cell(pos)
	if cell.x < 0:
		_selected_entry = {}
		item_deselected.emit()
		queue_redraw()
		return
	var entry := JunkBox.get_entry_at(cell.y, cell.x)
	if entry.is_empty():
		_selected_entry = {}
		item_deselected.emit()
	else:
		if _selected_entry == entry:
			# 同じアイテムを再クリック → 選択解除
			_selected_entry = {}
			item_deselected.emit()
		else:
			_selected_entry = entry
			item_selected.emit(entry)
	queue_redraw()

func _start_drag_entry(entry: Dictionary, from_pos: Vector2) -> void:
	_drag_entry        = entry
	_drag_pending_item = {}
	var item_x: int = GRID_OFFSET_X + int(entry["col"]) * (CELL_SIZE + CELL_MARGIN)
	var item_y: int = GRID_OFFSET_Y + int(entry["row"]) * (CELL_SIZE + CELL_MARGIN)
	_drag_offset = from_pos - Vector2(item_x, item_y)
	_drag_pos    = from_pos
	_is_dragging = true
	_selected_entry = {}
	queue_redraw()

func _on_left_release(pos: Vector2) -> void:
	if not _is_dragging:
		return
	_is_dragging = false

	var pw := 1
	var ph := 1
	if not _drag_entry.is_empty():
		pw = int(_drag_entry["w"])
		ph = int(_drag_entry["h"])

	var drop_center := _drag_pos - _drag_offset + Vector2(pw * (CELL_SIZE + CELL_MARGIN), ph * (CELL_SIZE + CELL_MARGIN)) / 2
	var cell        := _pos_to_cell(drop_center)
	var in_grid     := cell.x >= 0

	if not _drag_entry.is_empty():
		if in_grid:
			JunkBox.move_item(_drag_entry, cell.y, cell.x)
		else:
			if mode == "junkbox":
				# グリッド外へのドロップ → ニキータへ送る
				send_to_nikita.emit(_drag_entry)
			elif mode == "stash_phase":
				var removed := JunkBox.remove_item(_drag_entry)
				if not removed.is_empty():
					_pending_items.append(removed["item"])
					pending_returned.emit(removed["item"])
		_drag_entry = {}

	elif not _drag_pending_item.is_empty():
		if in_grid:
			var placed := JunkBox.place_item(_drag_pending_item, cell.y, cell.x)
			if not placed.is_empty():
				_pending_items.erase(_drag_pending_item)
				pending_placed.emit(_drag_pending_item)
		_drag_pending_item = {}

	layout_changed.emit()
	queue_redraw()

func start_drag_pending(item: Dictionary, grab_pos: Vector2) -> void:
	_drag_entry        = {}
	_drag_pending_item = item
	_drag_offset       = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	_drag_pos          = grab_pos
	_is_dragging       = true
	queue_redraw()

# ── ユーティリティ ────────────────────────
func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		GRID_OFFSET_X + col * (CELL_SIZE + CELL_MARGIN),
		GRID_OFFSET_Y + row * (CELL_SIZE + CELL_MARGIN),
		CELL_SIZE, CELL_SIZE)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	var cx := int((pos.x - GRID_OFFSET_X) / (CELL_SIZE + CELL_MARGIN))
	var cy := int((pos.y - GRID_OFFSET_Y) / (CELL_SIZE + CELL_MARGIN))
	if cx < 0 or cx >= JunkBox.COLS or cy < 0 or cy >= JunkBox.ROWS:
		return Vector2i(-1, -1)
	return Vector2i(cx, cy)

func get_required_size() -> Vector2:
	var w := GRID_OFFSET_X * 2 + JunkBox.COLS * (CELL_SIZE + CELL_MARGIN)
	var h := GRID_OFFSET_Y * 2 + JunkBox.ROWS * (CELL_SIZE + CELL_MARGIN)
	return Vector2(w, h)
