# RulesBuilder.gd
# ゲームルール画面のテキストを動的生成するオートロード。
# 仕様変更時はこのファイルだけを編集すればよい。
# 数値はすべて GameState / GameData の定数を参照し、ハードコードしない。
extends Node

# ─────────────────────────────────────────
func build() -> String:
	return (
		_section_stash()
		+ _section_basic()
		+ _section_bonus()
		+ _section_ult()
		+ _section_drawer_events()
		+ _section_slot()
		+ _section_rarity()
		+ _section_rank()
	)

# ─── スタッシュシステム ───────────────────
func _section_stash() -> String:
	var cost  := _fmt(GameState.PLAY_COST)
	var init  := _fmt(GameState.INITIAL_STASH)
	return (
		"[b][color=#ffd700]💰 スタッシュシステム[/color][/b]\n"
		+ "・初期所持金：¥%s\n" % init
		+ "・1探索のコスト：¥%s\n" % cost
		+ "・探索終了後、獲得アイテムの合計金額がスタッシュに加算されます\n"
		+ "・スタッシュが¥%s を下回った時点で" % cost
		+ "[color=#ff4444]破産・ゲーム終了[/color]となります\n\n"
	)

# ─── 基本ルール ──────────────────────────
func _section_basic() -> String:
	var per_run := GameState.MAX_ROUNDS * GameState.DRAWERS_PER_ROUND
	return (
		"[b][color=#ffd700]🎮 基本ルール[/color][/b]\n"
		+ "・全%dラウンド制（1探索 = %dラウンド）\n" % [GameState.MAX_ROUNDS, GameState.MAX_ROUNDS]
		+ "・各ラウンドに%dつの引き出しが登場\n" % GameState.TOTAL_DRAWERS
		+ "・その中から%dつを選んで開ける（計%dアイテム獲得）\n\n" % [GameState.DRAWERS_PER_ROUND, per_run]
	)

# ─── ボーナスイベント ────────────────────
func _section_bonus() -> String:
	# 発生確率をパーセント表示
	var chance_pct := int(GameState.BONUS_EVENT_CHANCE * 100)

	# 倍率テーブルから各倍率の個別確率を計算
	var table: Array = GameState.BONUS_MULTIPLIER_TABLE
	var lines := ""
	var prev_thresh := 0.0
	for entry: Dictionary in table:
		var thresh := float(entry["threshold"])
		var pct    := int(round((thresh - prev_thresh) * 100))
		var icon   := _mult_icon(int(entry["mult"]))
		lines += "　%s %d倍：%d%%\n" % [icon, entry["mult"], pct]
		prev_thresh = thresh

	return (
		"[b][color=#ffd700]⭐ ボーナスイベント[/color][/b]\n"
		+ "・%d%%の確率でボーナスイベントが発生\n" % chance_pct
		+ "・対象アイテムを引くと価値が倍増！\n"
		+ lines + "\n"
	)

func _mult_icon(mult: int) -> String:
	match mult:
		2: return "🟡"
		3: return "🟠"
		4: return "🔴"
		5: return "💥"
		_: return "⭐"

# ─── ウルト能力 ──────────────────────────
func _section_ult() -> String:
	return (
		"[b][color=#ffd700]🔮 ウルト能力"
		+ "（各ラウンド1回・引き出しを開ける前のみ使用可）[/color][/b]\n"
		+ "・[b]中身を見る🔍[/b]：引き出しを1つランダムで覗き見できる\n"
		+ "・[b]リセット🔄[/b]：全引き出しの中身をシャッフルし直す\n\n"
	)

# ─── 引き出しトラップイベント ────────────────
func _section_drawer_events() -> String:
	var events: Array = GameState.DRAWER_EVENTS
	if events.is_empty():
		return ""

	var lines := ""
	for event: Dictionary in events:
		var pct    := int(round(float(event["chance"]) * 100))
		var icon   : String = event.get("icon", "⚠️")
		var title  : String = event.get("title", "")
		var msg    : String = event.get("message", "")
		var effect : String = event.get("effect", "none")
		var val    : int    = int(event.get("effect_value", 0))

		var effect_str := ""
		match effect:
			"stash_damage": effect_str = "スタッシュ－¥%s" % _fmt(val)
			"none":         effect_str = "演出のみ"

		lines += "・%s [b]%s[/b]（%d%%）\n" % [icon, title, pct]
		lines += "　\"%s\" → %s\n" % [msg, effect_str]

	return (
		"[b][color=#ffd700]⚠️ 引き出しトラップ[/color][/b]\n"
		+ "引き出しを開けるたびに発動確率を抽選します。\n"
		+ lines + "\n"
	)

# ─── レアリティ ──────────────────────────
func _section_rarity() -> String:
	var total_items := GameData.get_all_items().size()

	# 合計ウェイトを計算して各レアリティの確率を動的算出
	var total_weight := 0
	for w in GameData.RARITY_WEIGHTS.values():
		total_weight += w

	# レアリティ定義: [key, 表示名, 色]
	var defs := [
		["common",    "コモン",       "#7a8a99"],
		["uncommon",  "アンコモン",   "#4db87a"],
		["rare",      "レア",         "#4a9eff"],
		["epic",      "エピック",     "#b06aff"],
		["legendary", "レジェンダリー","#ffc844"],
	]

	var lines := ""
	for def: Array in defs:
		var key     : String = def[0]
		var label   : String = def[1]
		var color   : String = def[2]
		var weight  : int    = GameData.RARITY_WEIGHTS.get(key, 0)
		var pct     : int    = int(round(float(weight) / float(total_weight) * 100))
		var range_v          = _value_range(key)
		lines += "・[color=%s]%s[/color]（%d%%）：¥%s〜%s\n" % [
			color, label, pct, _fmt(range_v[0]), _fmt(range_v[1])
		]

	return (
		"[b][color=#ffd700]💎 レアリティ（全%d種）[/color][/b]\n" % total_items
		+ lines + "\n"
	)

# ─── スロットマシン ──────────────────────
func _section_slot() -> String:
	var cost := _fmt(GameState.SLOT_COST)

	# シンボルテーブルから確率・倍率・アイテムを動的生成
	var total_weight := 0
	for sym: Dictionary in GameState.SLOT_SYMBOLS:
		total_weight += int(sym["weight"])

	var lines := ""
	for sym: Dictionary in GameState.SLOT_SYMBOLS:
		var w       : int    = int(sym["weight"])
		var icon    : String = sym["icon"]
		var mult    : int    = int(sym["multiplier"])
		var item_key: String = sym.get("item_key", "")
		# 1リールの出現率
		var pct_one : float  = float(w) / float(total_weight) * 100.0
		# 3リール揃う確率
		var pct_3   : float  = pct_one * pct_one * pct_one / 10000.0
		var payout  : int    = GameState.SLOT_COST * mult

		var item_str: String = "現金のみ" if item_key.is_empty() \
			else GameData.RARITY_NAMES.get(item_key, item_key) + "アイテム1個"

		lines += "・%s  %d倍（¥%s）/ %s  [揃い確率 %.2f%%]\n" % [
			icon, mult, _fmt(payout), item_str, pct_3
		]

	return (
		"[b][color=#ffd700]🎰 スロットマシン[/color][/b]\n"
		+ "・探索終了後、「次の探索へ」が選べるタイミングで挑戦できます\n"
		+ "・1回のプレイコスト：¥%s\n" % cost
		+ "・3リールが全て同じシンボルで揃うと現金を獲得\n"
		+ "・揃い不問で、停止した各リールのシンボルに対応するアイテムを獲得\n"
		+ "・\"7\" 揃いのみアイテムなし（現金払い出し専用）\n\n"
		+ "[b]シンボル一覧（倍率 / 獲得アイテム / 揃い確率）:[/b]\n"
		+ lines + "\n"
	)

# ─── ランキング評価 ──────────────────────
func _section_rank() -> String:
	# GameState.RANK_TABLE から動的生成（最後のD級は「それ以下」と表記）
	var table: Array = GameState.RANK_TABLE
	var lines := ""
	for i in table.size():
		var entry: Dictionary = table[i]
		var threshold := int(entry["threshold"])
		var label     : String = entry["label"]
		if threshold > 0:
			lines += "・%s：¥%s以上\n" % [label, _fmt(threshold)]
		else:
			lines += "・%s：それ以下\n" % label

	return (
		"[b][color=#ffd700]🏆 ランキング評価（スタッシュ残高）[/color][/b]\n"
		+ lines
	)

# ─── ユーティリティ ──────────────────────
func _value_range(rarity: String) -> Array:
	var vals: Array = []
	for item in GameData.ITEMS[rarity]:
		vals.append(int(item["value"]))
	vals.sort()
	return [vals[0], vals[vals.size() - 1]]

func _fmt(n: int) -> String:
	var s      := str(n)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
