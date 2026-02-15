# TaskManager.gd
# ニキータタスクシステムの管理オートロード。
# タスクは常時2件表示。完了で1件補充。破産でリセット。
extends Node

signal task_completed(task: Dictionary, reward: int)
signal tasks_updated

const SAVE_PATH    := "user://tasks.json"
const MAX_ACTIVE   := 2   # 同時表示件数

# ── タスク種別定義 ──────────────────────────
# type:
#   "deliver_icon"   : 特定アイコン(🚬🥫など)のアイテムをN個納品
#   "deliver_name"   : 特定名称のアイテムをN個納品
#   "deliver_rarity" : 特定レアリティのアイテムをN個納品
#   "explore_count"  : 破産せずN回探索成功
#   "slot_spin"      : スロットをN回回す
# source: "fixed"=固定テンプレ / "random"=都度ランダム生成
# difficulty: "easy" / "normal" / "hard"

const TASK_TEMPLATES: Array = [
	# ── easy ──
	{"type": "deliver_icon",  "icon": "🚬", "label": "タバコ",     "count": 2, "difficulty": "easy",   "reward": [8000,  15000]},
	{"type": "deliver_icon",  "icon": "🥫", "label": "缶詰",       "count": 2, "difficulty": "easy",   "reward": [7000,  12000]},
	{"type": "deliver_icon",  "icon": "🩹", "label": "包帯",       "count": 1, "difficulty": "easy",   "reward": [5000,  10000]},
	{"type": "deliver_icon",  "icon": "🔥", "label": "ライター",   "count": 1, "difficulty": "easy",   "reward": [5000,   8000]},
	{"type": "deliver_icon",  "icon": "🔦", "label": "懐中電灯",   "count": 1, "difficulty": "easy",   "reward": [6000,  10000]},
	{"type": "deliver_rarity","rarity": "common",   "label": "コモン",   "count": 3, "difficulty": "easy",   "reward": [6000,  12000]},
	{"type": "explore_count", "count": 1, "difficulty": "easy",   "reward": [5000,  10000]},
	{"type": "deliver_icon",  "icon": "📰", "label": "古新聞",     "count": 2, "difficulty": "easy",   "reward": [4000,   8000]},
	{"type": "deliver_icon",  "icon": "🔌", "label": "電源ケーブル","count": 1,"difficulty": "easy",   "reward": [5000,   9000]},
	{"type": "deliver_icon",  "icon": "🧤", "label": "軍手",       "count": 2, "difficulty": "easy",   "reward": [4000,   7000]},
	# ── normal ──
	{"type": "deliver_icon",  "icon": "🚬", "label": "タバコ",     "count": 3, "difficulty": "normal", "reward": [30000,  60000]},
	{"type": "deliver_icon",  "icon": "🥫", "label": "缶詰",       "count": 3, "difficulty": "normal", "reward": [28000,  55000]},
	{"type": "deliver_rarity","rarity": "uncommon", "label": "アンコモン","count": 2,"difficulty": "normal","reward": [35000, 65000]},
	{"type": "deliver_rarity","rarity": "rare",     "label": "レア",      "count": 1,"difficulty": "normal","reward": [40000, 70000]},
	{"type": "explore_count", "count": 3, "difficulty": "normal", "reward": [30000,  60000]},
	{"type": "slot_spin",     "count": 1, "difficulty": "normal", "reward": [35000,  70000]},
	{"type": "deliver_name",  "name": "古びたVHS",  "count": 1, "difficulty": "normal", "reward": [30000, 55000]},
	{"type": "deliver_rarity","rarity": "uncommon", "label": "アンコモン","count": 3,"difficulty": "normal","reward": [45000, 75000]},
	{"type": "deliver_icon",  "icon": "🔋", "label": "電池パック", "count": 2, "difficulty": "normal", "reward": [32000,  60000]},
	{"type": "explore_count", "count": 5, "difficulty": "normal", "reward": [50000,  80000]},
	# ── hard ──
	{"type": "deliver_rarity","rarity": "rare",     "label": "レア",      "count": 2,"difficulty": "hard","reward": [100000, 180000]},
	{"type": "deliver_rarity","rarity": "epic",     "label": "エピック",  "count": 1,"difficulty": "hard","reward": [120000, 220000]},
	{"type": "deliver_name",  "name": "ピンクのVHS","count": 1, "difficulty": "hard",   "reward": [150000, 250000]},
	{"type": "deliver_rarity","rarity": "legendary","label": "レジェンダリー","count": 1,"difficulty": "hard","reward": [200000, 300000]},
	{"type": "explore_count", "count": 10,"difficulty": "hard",  "reward": [100000, 200000]},
	{"type": "slot_spin",     "count": 3, "difficulty": "hard",   "reward": [120000, 220000]},
	{"type": "deliver_rarity","rarity": "epic",     "label": "エピック",  "count": 2,"difficulty": "hard","reward": [180000, 280000]},
	{"type": "deliver_name",  "name": "実験用医薬品","count": 1,"difficulty": "hard",   "reward": [180000, 300000]},
]

# アクティブタスク: [{template fields, "progress": int, "reward": int, "id": int}]
var active_tasks: Array = []
var _next_id := 0

func _ready() -> void:
	load_data()
	if active_tasks.is_empty():
		_fill_tasks()

# 破棄コスト（報酬の何割か）
const DISCARD_COST_RATE := 0.5

# ── 進捗イベント（外部から呼ぶ）────────────
func on_explore_success() -> void:
	_progress_tasks("explore_count", 1)

func on_slot_spin() -> void:
	_progress_tasks("slot_spin", 1)

# タスク破棄：コスト = reward * DISCARD_COST_RATE（スタッシュから引く）
# 戻り値: true=破棄成功 / false=スタッシュ不足
func discard_task(task: Dictionary) -> bool:
	var cost: int = int(int(task["reward"]) * DISCARD_COST_RATE)
	if GameState.stash < cost:
		return false
	GameState.stash -= cost
	active_tasks.erase(task)
	_fill_tasks()
	save_data()
	tasks_updated.emit()
	return true

func get_discard_cost(task: Dictionary) -> int:
	return int(int(task["reward"]) * DISCARD_COST_RATE)

# 納品：タスク画面の完了ボタンから呼ぶ
# 戻り値: 不足アイテム名のリスト（空なら成功）
func try_deliver(task: Dictionary) -> Array:
	var missing: Array = []
	var needed: int    = int(task["count"])
	var matched: Array = _find_matching_items(task, needed)
	if matched.size() < needed:
		missing = _describe_missing(task, needed - matched.size())
		return missing
	# 実際にジャンクボックスから削除
	for entry in matched:
		JunkBox.remove_item(entry)
	_complete_task(task)
	return []

# ── 内部処理 ──────────────────────────────
func _progress_tasks(task_type: String, amount: int) -> void:
	var changed := false
	for task: Dictionary in active_tasks:
		if task["type"] == task_type:
			task["progress"] = int(task.get("progress", 0)) + amount
			if task["progress"] >= int(task["count"]):
				_complete_task(task)
				changed = true
				break   # 完了後は再度 active_tasks を更新するので break
	if changed:
		tasks_updated.emit()

func _complete_task(task: Dictionary) -> void:
	var reward: int = int(task["reward"])
	GameState.stash += reward
	task_completed.emit(task, reward)
	active_tasks.erase(task)
	_fill_tasks()
	save_data()
	tasks_updated.emit()

func _fill_tasks() -> void:
	var attempts := 0
	while active_tasks.size() < MAX_ACTIVE and attempts < 100:
		attempts += 1
		# 50%の確率でランダム生成タスク、50%で固定テンプレ
		var tmpl: Dictionary
		if randf() < 0.5:
			tmpl = _generate_random_task()
		else:
			tmpl = TASK_TEMPLATES[randi() % TASK_TEMPLATES.size()].duplicate()
		if tmpl.is_empty() or _is_duplicate(tmpl):
			continue
		tmpl["progress"] = 0
		tmpl["reward"]   = randi_range(int(tmpl["reward"][0]), int(tmpl["reward"][1]))
		tmpl["id"]       = _next_id
		tmpl["source"]   = tmpl.get("source", "fixed")
		_next_id        += 1
		active_tasks.append(tmpl)

# ── ランダムタスク生成 ────────────────────
func _generate_random_task() -> Dictionary:
	var roll := randf()
	# 難易度をランダム選択（easy:50% normal:35% hard:15%）
	var diff := "easy"
	if roll > 0.85:
		diff = "hard"
	elif roll > 0.50:
		diff = "normal"

	var type_roll := randf()
	var result: Dictionary = {}

	if type_roll < 0.50:
		# 納品：ランダムアイコン
		var all_items: Array = GameData.get_all_items()
		var item: Dictionary = all_items[randi() % all_items.size()]
		var rarity: String   = item.get("rarity", "common")
		var icon: String     = item.get("icon", "?")
		# 難易度に応じた個数
		var counts := {"easy": [1,2], "normal": [2,4], "hard": [3,6]}
		var range_c: Array = counts[diff]
		var count: int = randi_range(range_c[0], range_c[1])
		var rewards := _reward_range(diff)
		result = {"type": "deliver_icon", "icon": icon, "label": item["name"],
			"count": count, "difficulty": diff, "reward": rewards, "source": "random"}

	elif type_roll < 0.75:
		# 納品：レアリティ指定
		var rarities := {"easy": ["common","uncommon"], "normal": ["uncommon","rare"], "hard": ["rare","epic","legendary"]}
		var pool: Array = rarities[diff]
		var rarity: String = pool[randi() % pool.size()]
		var counts := {"easy": [2,3], "normal": [1,3], "hard": [1,2]}
		var range_c: Array = counts[diff]
		var count: int = randi_range(range_c[0], range_c[1])
		var rewards := _reward_range(diff)
		result = {"type": "deliver_rarity", "rarity": rarity,
			"label": GameData.RARITY_NAMES.get(rarity, rarity),
			"count": count, "difficulty": diff, "reward": rewards, "source": "random"}

	elif type_roll < 0.90:
		# 探索回数
		var counts := {"easy": [1,2], "normal": [3,5], "hard": [8,12]}
		var range_c: Array = counts[diff]
		var count: int = randi_range(range_c[0], range_c[1])
		var rewards := _reward_range(diff)
		result = {"type": "explore_count", "count": count,
			"difficulty": diff, "reward": rewards, "source": "random"}

	else:
		# スロット
		var counts := {"easy": [1,1], "normal": [1,2], "hard": [3,5]}
		var range_c: Array = counts[diff]
		var count: int = randi_range(range_c[0], range_c[1])
		var rewards := _reward_range(diff)
		result = {"type": "slot_spin", "count": count,
			"difficulty": diff, "reward": rewards, "source": "random"}

	return result

func _reward_range(diff: String) -> Array:
	match diff:
		"easy":   return [5000,  20000]
		"normal": return [30000, 80000]
		"hard":   return [100000, 300000]
	return [5000, 20000]

func _is_duplicate(tmpl: Dictionary) -> bool:
	for t: Dictionary in active_tasks:
		if t["type"] != tmpl["type"]:
			continue
		match tmpl["type"]:
			"deliver_icon":
				if t.get("icon") == tmpl.get("icon") and t.get("count") == tmpl.get("count"):
					return true
			"deliver_name":
				if t.get("name") == tmpl.get("name"):
					return true
			"deliver_rarity":
				if t.get("rarity") == tmpl.get("rarity") and t.get("count") == tmpl.get("count"):
					return true
			"explore_count", "slot_spin":
				if t.get("count") == tmpl.get("count"):
					return true
	return false

func _find_matching_items(task: Dictionary, needed: int) -> Array:
	var result: Array = []
	for entry: Dictionary in JunkBox.entries:
		if result.size() >= needed:
			break
		var item: Dictionary = entry["item"]
		if _item_matches_task(item, task):
			result.append(entry)
	return result

func _item_matches_task(item: Dictionary, task: Dictionary) -> bool:
	match task["type"]:
		"deliver_icon":
			return item.get("icon", "") == task.get("icon", "")
		"deliver_name":
			return item.get("name", "") == task.get("name", "")
		"deliver_rarity":
			return item.get("rarity", "") == task.get("rarity", "")
	return false

func _describe_missing(task: Dictionary, shortage: int) -> Array:
	var label := ""
	match task["type"]:
		"deliver_icon":   label = task.get("label", task.get("icon", "?"))
		"deliver_name":   label = task.get("name", "?")
		"deliver_rarity": label = GameData.RARITY_NAMES.get(task.get("rarity",""), "?")
	var result: Array = []
	for i in shortage:
		result.append(label)
	return result

# ── タスク説明文生成 ────────────────────────
static func describe(task: Dictionary) -> String:
	var prog: int  = int(task.get("progress", 0))
	var count: int = int(task["count"])
	match task["type"]:
		"deliver_icon":
			var label: String = task.get("label", task.get("icon", "?"))
			return "%s %s を %d個 納品する [%d/%d]" % [task.get("icon",""), label, count, prog, count]
		"deliver_name":
			return "「%s」を %d個 納品する [%d/%d]" % [task.get("name","?"), count, prog, count]
		"deliver_rarity":
			var rl: String = GameData.RARITY_NAMES.get(task.get("rarity",""), "?")
			return "%s アイテムを %d個 納品する [%d/%d]" % [rl, count, prog, count]
		"explore_count":
			return "探索を %d回 成功させる [%d/%d]" % [count, prog, count]
		"slot_spin":
			return "スロットを %d回 回す [%d/%d]" % [count, prog, count]
	return "不明なタスク"

static func difficulty_label(task: Dictionary) -> String:
	match task.get("difficulty", "normal"):
		"easy":   return "🟢 簡単"
		"normal": return "🟡 普通"
		"hard":   return "🔴 困難"
	return ""

# ── セーブ / ロード ───────────────────────
func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"tasks": active_tasks, "next_id": _next_id}))

func load_data() -> void:
	active_tasks = []
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		active_tasks = parsed.get("tasks", [])
		_next_id     = int(parsed.get("next_id", 0))

func reset() -> void:
	active_tasks = []
	_next_id     = 0
	_fill_tasks()
	save_data()
	tasks_updated.emit()
