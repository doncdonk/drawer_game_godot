# SlotMachine.gd
# スロットマシンのロジック専用オートロード。
# 賞金テーブル・シンボルは GameState.SLOT_SYMBOLS で一元管理。
extends Node

signal spin_finished(results: Array, payout: int, loot: Array)

# ── リール列生成 ─────────────────────────
# 各シンボルをweight分追加してシャッフルした循環リストを返す
func build_reel_strip() -> Array:
	var strip: Array = []
	for sym: Dictionary in GameState.SLOT_SYMBOLS:
		for _i in int(sym["weight"]):
			strip.append(sym)
	strip.shuffle()
	return strip

# ── リールウィンドウ取得 ──────────────────
# strip の stop_idx を中段として上下 pad 個を含む配列を返す（演出用）
func get_reel_window(strip: Array, stop_idx: int, pad: int) -> Array:
	var size := strip.size()
	var window: Array = []
	for i in range(-pad, pad + 1):
		window.append(strip[(stop_idx + i + size * 10) % size])
	return window

# ── 1回のスピン処理 ──────────────────────
func spin() -> Dictionary:
	if GameState.stash < GameState.SLOT_COST:
		return {"ok": false, "reason": "残高不足"}

	GameState.stash -= GameState.SLOT_COST

	var results: Array = []
	for _i in 3:
		results.append(_pick_symbol())

	var payout := _calc_payout(results)
	GameState.stash += payout

	# 各リールのシンボルからアイテムを生成してインベントリへ追加
	var loot: Array = []
	for sym: Dictionary in results:
		var item: Dictionary = _make_loot_item(sym)
		loot.append(item)
		if not item.is_empty():
			GameState.inventory.append(item)

	spin_finished.emit(results, payout, loot)
	return {"ok": true, "results": results, "payout": payout, "loot": loot}

# ── シンボル抽選（重み付きランダム）────────
func _pick_symbol() -> Dictionary:
	var total := 0
	for sym: Dictionary in GameState.SLOT_SYMBOLS:
		total += int(sym["weight"])
	var roll := randi() % total
	var acc  := 0
	for sym: Dictionary in GameState.SLOT_SYMBOLS:
		acc += int(sym["weight"])
		if roll < acc:
			return sym
	return GameState.SLOT_SYMBOLS[GameState.SLOT_SYMBOLS.size() - 1]

# ── アイテム生成 ─────────────────────────
func _make_loot_item(sym: Dictionary) -> Dictionary:
	var key: String = sym.get("item_key", "")
	if key.is_empty() or not GameData.ITEMS.has(key):
		return {}
	var pool: Array = GameData.ITEMS[key]
	if pool.is_empty():
		return {}
	var base: Dictionary = pool[randi() % pool.size()].duplicate()
	base["rarity"]          = key
	base["had_bonus"]       = false
	base["bonus_multiplier"]= 1
	base["original_value"]  = int(base["value"])
	base["had_trap"]        = false
	base["from_slot"]       = true
	return base

# ── 払い出し計算 ─────────────────────────
func _calc_payout(results: Array) -> int:
	if results.size() < 3:
		return 0
	var r0: Dictionary = results[0]
	var r1: Dictionary = results[1]
	var r2: Dictionary = results[2]
	if r0["icon"] == r1["icon"] and r1["icon"] == r2["icon"]:
		return GameState.SLOT_COST * int(r0["multiplier"])
	return 0
