# GameState.gd
# ゲームロジック全体を管理するシングルトン
extends Node

# --- シグナル ---
signal round_started(round_num: int)
signal drawer_opened(index: int, item: Dictionary)
signal round_ended(items: Array)
signal play_finished(earned: int, stash: int)
signal bankrupt()
signal bonus_event(bonus_item: Dictionary)

# --- 定数 ---
const MAX_ROUNDS        := 3
const DRAWERS_PER_ROUND := 2
const TOTAL_DRAWERS     := 5
const INITIAL_STASH     := 10000
const PLAY_COST         := 7000

# --- スタッシュ ---
var stash := INITIAL_STASH

# --- 1探索内の状態 ---
var current_round := 1
var total_value   := 0
var inventory: Array           = []
var opened_drawers: Array      = []
var current_round_items: Array = []
var drawer_contents: Array     = []
var bonus_item: Dictionary     = {}
var ult_used := false

const SAVE_PATH := "user://rankings.json"

# ─────────────────────────────────────────
func init_session() -> void:
	stash = INITIAL_STASH
	init_play()

func init_play() -> void:
	stash -= PLAY_COST
	current_round       = 1
	total_value         = 0
	inventory           = []
	opened_drawers      = []
	current_round_items = []
	drawer_contents     = []
	bonus_item          = {}
	ult_used            = false
	_setup_round()

func _setup_round() -> void:
	opened_drawers      = []
	current_round_items = []
	bonus_item          = {}
	ult_used            = false

	drawer_contents = []
	for i in TOTAL_DRAWERS:
		drawer_contents.append(GameData.get_random_item())

	if randf() < 0.40:
		var all: Array = GameData.get_all_items()
		var picked: Dictionary = all[randi() % all.size()].duplicate()
		var roll := randf()
		var multiplier := 2
		if   roll < 0.50: multiplier = 2
		elif roll < 0.80: multiplier = 3
		elif roll < 0.95: multiplier = 4
		else:             multiplier = 5
		picked["multiplier"] = multiplier
		bonus_item = picked
		bonus_event.emit(bonus_item)

	round_started.emit(current_round)

# ─────────────────────────────────────────
func open_drawer(index: int) -> void:
	if index in opened_drawers:
		return
	if current_round_items.size() >= DRAWERS_PER_ROUND:
		return

	opened_drawers.append(index)

	var item: Dictionary = drawer_contents[index].duplicate()
	var bonus_multiplier := 1
	var had_bonus := false

	if not bonus_item.is_empty() and item["name"] == bonus_item["name"]:
		bonus_multiplier     = bonus_item.get("multiplier", 2)
		item["value"]        = item["value"] * bonus_multiplier
		had_bonus            = true

	item["had_bonus"]        = had_bonus
	item["bonus_multiplier"] = bonus_multiplier
	item["original_value"]   = drawer_contents[index]["value"]

	inventory.append(item)
	current_round_items.append(item)
	total_value += item["value"]

	drawer_opened.emit(index, item)

	if current_round_items.size() >= DRAWERS_PER_ROUND:
		round_ended.emit(current_round_items)

# ─────────────────────────────────────────
func next_round() -> void:
	current_round += 1
	_setup_round()

func finish_play() -> void:
	stash += total_value
	save_score(stash)
	play_finished.emit(total_value, stash)

func can_continue() -> bool:
	return stash >= PLAY_COST

# ─────────────────────────────────────────
func use_peek() -> Dictionary:
	if ult_used or current_round_items.size() > 0:
		return {}
	ult_used = true
	var unopened: Array = []
	for i in TOTAL_DRAWERS:
		if not i in opened_drawers:
			unopened.append(i)
	if unopened.is_empty():
		return {}
	var idx: int = unopened[randi() % unopened.size()]
	return {"index": idx, "item": drawer_contents[idx]}

func use_reset() -> void:
	if ult_used or current_round_items.size() > 0:
		return
	ult_used = true
	drawer_contents = []
	for i in TOTAL_DRAWERS:
		drawer_contents.append(GameData.get_random_item())

# ─────────────────────────────────────────
func save_score(score: int) -> void:
	var rankings: Array = load_rankings()
	rankings.append({"score": score, "date": Time.get_datetime_string_from_system()})
	rankings.sort_custom(func(a, b): return a["score"] > b["score"])
	if rankings.size() > 10:
		rankings = rankings.slice(0, 10)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(rankings))
		file.close()

func load_rankings() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return []
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result is Array:
		return result
	return []

func get_rank_label(stash_value: int) -> String:
	if   stash_value >= 200000: return "S級サバイバー！🏆"
	elif stash_value >= 100000: return "A級スカベンジャー！⭐"
	elif stash_value >= 50000:  return "B級コレクター！"
	elif stash_value >= 20000:  return "C級探索者"
	else:                       return "D級初心者"
