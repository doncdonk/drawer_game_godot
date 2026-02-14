# JunkBox.gd
# ジャンクボックスのデータ管理オートロード。
# グリッド: ROWS行 × COLS列。将来の複数マスアイテムに対応した占有方式。
extends Node

signal item_placed(entry: Dictionary)
signal item_removed(entry: Dictionary)
signal item_sold(entry: Dictionary, price: int)

# ── 定数 ──────────────────────────────────
const ROWS     := 3
const COLS     := 10
const SAVE_PATH := "user://junkbox.json"

# ニキータ売却倍率（1.0 = item value と同額）
const NIKITA_RATE := 1.0

# ── グリッドデータ ─────────────────────────
# entries: Array of {
#   "item": Dictionary,   # GameData 由来のアイテム辞書
#   "row":  int,
#   "col":  int,
#   "w":    int,          # 占有幅（現状は常に1）
#   "h":    int,          # 占有高さ（現状は常に1）
# }
var entries: Array = []

# ── 初期化 ────────────────────────────────
func _ready() -> void:
	load_data()

# ── 配置可否チェック ──────────────────────
func can_place(row: int, col: int, w: int, h: int, exclude_entry: Dictionary = {}) -> bool:
	if row < 0 or col < 0 or row + h > ROWS or col + w > COLS:
		return false
	for entry: Dictionary in entries:
		if not exclude_entry.is_empty() and entry == exclude_entry:
			continue
		var er: int = entry["row"]
		var ec: int = entry["col"]
		var ew: int = entry["w"]
		var eh: int = entry["h"]
		# 矩形の重なり判定
		if row < er + eh and row + h > er and col < ec + ew and col + w > ec:
			return false
	return true

# ── アイテム配置 ──────────────────────────
# 成功したら entry を返す、失敗したら空 Dict
func place_item(item: Dictionary, row: int, col: int, w: int = 1, h: int = 1) -> Dictionary:
	if not can_place(row, col, w, h):
		return {}
	var entry := {"item": item, "row": row, "col": col, "w": w, "h": h}
	entries.append(entry)
	item_placed.emit(entry)
	save_data()
	return entry

# ── アイテム移動 ──────────────────────────
func move_item(entry: Dictionary, new_row: int, new_col: int) -> bool:
	if not entries.has(entry):
		return false
	if not can_place(new_row, new_col, entry["w"], entry["h"], entry):
		return false
	entry["row"] = new_row
	entry["col"] = new_col
	save_data()
	return true

# ── アイテム取り出し ──────────────────────
func remove_item(entry: Dictionary) -> Dictionary:
	if not entries.has(entry):
		return {}
	entries.erase(entry)
	item_removed.emit(entry)
	save_data()
	return entry

# ── ニキータへ売却 ────────────────────────
func sell_to_nikita(entry: Dictionary) -> int:
	if not entries.has(entry):
		return 0
	var price: int = int(round(float(entry["item"]["value"]) * NIKITA_RATE))
	entries.erase(entry)
	GameState.stash += price
	item_sold.emit(entry, price)
	save_data()
	return price

# ── 空きマス検索 ──────────────────────────
# w×h サイズが入る最初の空きセル [row, col] を返す（なければ [-1, -1]）
func find_free_cell(w: int = 1, h: int = 1) -> Array:
	for r in ROWS:
		for c in COLS:
			if can_place(r, c, w, h):
				return [r, c]
	return [-1, -1]

# ── 指定セルにあるエントリ取得 ────────────
func get_entry_at(row: int, col: int) -> Dictionary:
	for entry: Dictionary in entries:
		var er: int = entry["row"]
		var ec: int = entry["col"]
		var ew: int = entry["w"]
		var eh: int = entry["h"]
		if row >= er and row < er + eh and col >= ec and col < ec + ew:
			return entry
	return {}

# ── 空きマス数 ────────────────────────────
func free_cells() -> int:
	var used := 0
	for entry: Dictionary in entries:
		used += entry["w"] * entry["h"]
	return ROWS * COLS - used

# ── セーブ / ロード ───────────────────────
func save_data() -> void:
	var data: Array = []
	for entry: Dictionary in entries:
		data.append({
			"item": entry["item"],
			"row":  entry["row"],
			"col":  entry["col"],
			"w":    entry["w"],
			"h":    entry["h"],
		})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	entries = []
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for d: Dictionary in parsed:
			entries.append({
				"item": d["item"],
				"row":  int(d["row"]),
				"col":  int(d["col"]),
				"w":    int(d.get("w", 1)),
				"h":    int(d.get("h", 1)),
			})

func reset() -> void:
	entries = []
	save_data()
