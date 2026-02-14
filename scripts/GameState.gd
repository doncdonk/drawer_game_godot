# GameState.gd
# ゲームロジック全体を管理するシングルトン
extends Node

# --- シグナル ---
signal round_started(round_num: int)
signal drawer_opened(index: int, item: Dictionary)
signal drawer_event(event: Dictionary)
signal round_ended(items: Array)
signal play_finished(earned: int, stash: int, trap_damage: int)
signal stash_phase_started(items: Array)   # 格納フェーズ開始
signal bankrupt()
signal bonus_event(bonus_item: Dictionary)

# --- 定数 ---
const MAX_ROUNDS        := 3
const DRAWERS_PER_ROUND := 2
const TOTAL_DRAWERS     := 5
const INITIAL_STASH     := 10000
const PLAY_COST         := 10000

# --- ボーナスイベント ---
const BONUS_EVENT_CHANCE := 0.40   # 発生確率
# 倍率テーブル: [倍率, その倍率になる累積確率の上限]
const BONUS_MULTIPLIER_TABLE := [
	{"mult": 2, "threshold": 0.50},
	{"mult": 3, "threshold": 0.80},
	{"mult": 4, "threshold": 0.95},
	{"mult": 5, "threshold": 1.00},
]

# --- ランク基準: [閾値, ラベル] 降順 ---
const RANK_TABLE := [
	{"threshold": 200000, "label": "S級サバイバー！🏆"},
	{"threshold": 100000, "label": "A級スカベンジャー！⭐"},
	{"threshold":  50000, "label": "B級コレクター！"},
	{"threshold":  20000, "label": "C級探索者"},
	{"threshold":       0, "label": "D級初心者"},
]

# --- 引き出しトラップイベント ---
# 今後イベントを増やす場合はここにエントリを追加するだけでよい。
# effect の種類:
#   "stash_damage"  : stash から effect_value を減算（下限0）
#   "none"          : 演出のみ（現状影響なし）
const DRAWER_EVENTS: Array = [
	{
		"id":          "explosion",
		"icon":        "💥",
		"title":       "トラップ発動！",
		"message":     "引き出しにトラップがあった",
		"effect":      "stash_damage",
		"effect_value": 50000,
		"chance":      0.02,   # 2% per drawer open
	},
]

# --- スロットマシン ---
const SLOT_COST := 50000

# シンボル定義: icon=表示文字, weight=出現重み, multiplier=揃い倍率
# item_key: "" なら現金払い出しのみ、設定するとアイテムも獲得
const SLOT_SYMBOLS: Array = [
	{"icon": "7",   "weight": 1,  "multiplier": 20, "item_key": ""},        # ジャックポット（現金のみ）
	{"icon": "💎",  "weight": 2,  "multiplier": 10, "item_key": "legendary"},# レジェンダリーランダム
	{"icon": "🔫",  "weight": 4,  "multiplier": 5,  "item_key": "epic"},    # エピックランダム
	{"icon": "💰",  "weight": 8,  "multiplier": 3,  "item_key": "rare"},    # レアランダム
	{"icon": "⭐",  "weight": 15, "multiplier": 2,  "item_key": "uncommon"},# アンコモンランダム
	{"icon": "🎯",  "weight": 25, "multiplier": 1,  "item_key": "common"},  # コモンランダム（元返し）
]

# --- スタッシュ ---
var stash := INITIAL_STASH

# --- セッション通算 ---
var play_count := 0   # 探索成功回数（破産リセットでゼロに戻る）

# --- 1探索内の状態 ---
var current_round := 1
var total_value   := 0
var trap_damage_total := 0
var inventory: Array           = []
var opened_drawers: Array      = []
var current_round_items: Array = []
var drawer_contents: Array     = []
var bonus_item: Dictionary     = {}
var ult_used := false

const SAVE_PATH := "user://rankings.json"

# ─────────────────────────────────────────
func init_session() -> void:
	stash      = INITIAL_STASH
	play_count = 0
	init_play()

func init_play() -> void:
	stash -= PLAY_COST
	current_round       = 1
	total_value         = 0
	trap_damage_total   = 0
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

	if randf() < BONUS_EVENT_CHANCE:
		var all: Array = GameData.get_all_items()
		var picked: Dictionary = all[randi() % all.size()].duplicate()
		var roll := randf()
		var multiplier := BONUS_MULTIPLIER_TABLE[0]["mult"]
		for entry in BONUS_MULTIPLIER_TABLE:
			if roll < float(entry["threshold"]):
				multiplier = entry["mult"]
				break
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

	# トラップイベント抽選（最後に追加されたアイテムに紐付け）
	_roll_drawer_event(item)

	if current_round_items.size() >= DRAWERS_PER_ROUND:
		round_ended.emit(current_round_items)

# ─────────────────────────────────────────
func _roll_drawer_event(triggered_item: Dictionary) -> void:
	for event: Dictionary in DRAWER_EVENTS:
		if randf() < float(event["chance"]):
			var result: Dictionary = event.duplicate()
			# 効果を実際に適用
			match event["effect"]:
				"stash_damage":
					var dmg: int = int(event["effect_value"])
					var actual_dmg: int = min(dmg, stash)  # 実際に減算される額（0未満にしない）
					stash = max(0, stash - dmg)
					trap_damage_total += actual_dmg
					result["applied_value"] = actual_dmg
				"none":
					result["applied_value"] = 0
			# トリガーとなったアイテムにフラグを書き込む
			triggered_item["had_trap"]   = true
			triggered_item["trap_event"] = result
			drawer_event.emit(result)
			return   # 1回の開封につき最大1イベント

# ─────────────────────────────────────────
func next_round() -> void:
	current_round += 1
	_setup_round()

func finish_play() -> void:
	# 探索終了 → 格納フェーズへ
	stash_phase_started.emit(inventory.duplicate())

# 格納フェーズ確定：未格納アイテムを売却してから結果画面へ
func commit_stash_phase(sold_items: Array) -> void:
	var sell_total := 0
	for item: Dictionary in sold_items:
		sell_total += int(item["value"])
	stash += total_value + sell_total
	play_count += 1
	save_score(stash)
	play_finished.emit(total_value + sell_total, stash, trap_damage_total)

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
	for entry in RANK_TABLE:
		if stash_value >= int(entry["threshold"]):
			return entry["label"]
	return RANK_TABLE[RANK_TABLE.size() - 1]["label"]
