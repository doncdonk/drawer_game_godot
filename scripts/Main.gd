# Main.gd
# メインシーンの全UI制御
extends Control

# ── ノード参照 ──────────────────────────────
@onready var label_round      := $VBox/MarginContainer/VBoxInner/TopBar/LabelRound
@onready var label_value      := $VBox/MarginContainer/VBoxInner/TopBar/LabelValue
@onready var label_items      := $VBox/MarginContainer/VBoxInner/TopBar/LabelItems

@onready var stash_amount     := $VBox/MarginContainer/VBoxInner/StashBar/StashHBox/StashAmount
@onready var stash_cost_label := $VBox/MarginContainer/VBoxInner/StashBar/StashHBox/StashCostLabel

@onready var bonus_panel      := $VBox/MarginContainer/VBoxInner/BonusPanel
@onready var bonus_label      := $VBox/MarginContainer/VBoxInner/BonusPanel/BonusVBox/BonusHBox/BonusVBox2/BonusLabel
@onready var bonus_icon: Control  = $VBox/MarginContainer/VBoxInner/BonusPanel/BonusVBox/BonusHBox/BonusIcon
@onready var bonus_mult       := $VBox/MarginContainer/VBoxInner/BonusPanel/BonusVBox/BonusHBox/BonusVBox2/BonusMult

@onready var drawers_container := $VBox/MarginContainer/VBoxInner/DrawersContainer

@onready var ult_peek_btn     := $VBox/MarginContainer/VBoxInner/UltButtons/PeekButton
@onready var ult_reset_btn    := $VBox/MarginContainer/VBoxInner/UltButtons/ResetButton
@onready var next_btn         := $VBox/MarginContainer/VBoxInner/ActionButtons/NextButton
@onready var restart_btn      := $VBox/MarginContainer/VBoxInner/ActionButtons/RestartButton

@onready var loot_panel       := $VBox/MarginContainer/VBoxInner/LootPanel
@onready var loot_title       := $VBox/MarginContainer/VBoxInner/LootPanel/LootVBox/LootTitle
@onready var loot_list        := $VBox/MarginContainer/VBoxInner/LootPanel/LootVBox/LootList

@onready var inventory_panel  := $VBox/MarginContainer/VBoxInner/InventoryPanel
@onready var inventory_list   := $VBox/MarginContainer/VBoxInner/InventoryPanel/InventoryVBox/InventoryList

@onready var result_panel     := $VBox/MarginContainer/VBoxInner/ResultPanel
@onready var result_rank      := $VBox/MarginContainer/VBoxInner/ResultPanel/ResultVBox/ResultRank
@onready var result_score     := $VBox/MarginContainer/VBoxInner/ResultPanel/ResultVBox/ResultScore
@onready var ranking_list     := $VBox/MarginContainer/VBoxInner/ResultPanel/ResultVBox/RankingList

@onready var peek_overlay     := $PeekOverlay
@onready var peek_index_label := $PeekOverlay/Panel/PanelVBox/IndexLabel
@onready var peek_icon_label: Control = $PeekOverlay/Panel/PanelVBox/IconLabel
@onready var peek_name_label  := $PeekOverlay/Panel/PanelVBox/NameLabel
@onready var peek_rarity_label:= $PeekOverlay/Panel/PanelVBox/RarityLabel
@onready var peek_close_btn   := $PeekOverlay/Panel/PanelVBox/CloseButton

@onready var sfx_drawer       := $SFXDrawer
@onready var sfx_legendary    := $SFXLegendary

# ── アイテム図鑑 ────────────────────────────
@onready var item_list_btn      := $VBox/MarginContainer/VBoxInner/ButtonRow/ItemListButton
@onready var item_list_overlay  := $ItemListOverlay
@onready var item_list_title    := $ItemListOverlay/Panel/VBox/HeaderRow/TitleLabel
@onready var item_list_close    := $ItemListOverlay/Panel/VBox/HeaderRow/CloseButton
@onready var item_grid          := $ItemListOverlay/Panel/VBox/ScrollContainer/ItemGrid
@onready var filter_all         := $ItemListOverlay/Panel/VBox/FilterRow/FilterAll
@onready var filter_common      := $ItemListOverlay/Panel/VBox/FilterRow/FilterCommon
@onready var filter_uncommon    := $ItemListOverlay/Panel/VBox/FilterRow/FilterUncommon
@onready var filter_rare        := $ItemListOverlay/Panel/VBox/FilterRow/FilterRare
@onready var filter_epic        := $ItemListOverlay/Panel/VBox/FilterRow/FilterEpic
@onready var filter_legendary   := $ItemListOverlay/Panel/VBox/FilterRow/FilterLegendary

# ── ルール ────────────────────────────────
@onready var rules_btn          := $VBox/MarginContainer/VBoxInner/ButtonRow/RulesButton
@onready var rules_overlay      := $RulesOverlay
@onready var rules_close_btn    := $RulesOverlay/Panel/VBox/HeaderRow/CloseButton
@onready var rules_text         := $RulesOverlay/Panel/VBox/ScrollContainer/RulesText

var _current_filter := "all"

# ── ライフサイクル ─────────────────────────
func _ready() -> void:
	GameState.round_started.connect(_on_round_started)
	GameState.drawer_opened.connect(_on_drawer_opened)
	GameState.round_ended.connect(_on_round_ended)
	GameState.play_finished.connect(_on_play_finished)
	GameState.bonus_event.connect(_on_bonus_event)

	next_btn.pressed.connect(_on_next_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	ult_peek_btn.pressed.connect(_on_peek_pressed)
	ult_reset_btn.pressed.connect(_on_reset_pressed)
	peek_close_btn.pressed.connect(func(): peek_overlay.hide())

	# アイテム図鑑
	item_list_btn.pressed.connect(_on_item_list_open)
	item_list_close.pressed.connect(func(): item_list_overlay.hide())
	filter_all.pressed.connect(func(): _set_filter("all"))
	filter_common.pressed.connect(func(): _set_filter("common"))
	filter_uncommon.pressed.connect(func(): _set_filter("uncommon"))
	filter_rare.pressed.connect(func(): _set_filter("rare"))
	filter_epic.pressed.connect(func(): _set_filter("epic"))
	filter_legendary.pressed.connect(func(): _set_filter("legendary"))

	# ルール
	rules_btn.pressed.connect(func(): rules_overlay.show())
	rules_close_btn.pressed.connect(func(): rules_overlay.hide())

	# コスト表示をコードから動的設定（PLAY_COSTの一元管理）
	stash_cost_label.text = "（1探索 ¥%s）" % _fmt(GameState.PLAY_COST)

	# ルールテキストも動的生成（数値はすべてGameState定数から参照）
	rules_text.text = _build_rules_text()

	_start_session()

# ── セッション開始（初回・破産後）─────────────
func _start_session() -> void:
	result_panel.hide()
	peek_overlay.hide()
	next_btn.hide()
	restart_btn.hide()
	loot_panel.show()
	inventory_panel.show()
	GameState.init_session()
	_build_drawers()
	_refresh_ui()

# ── 次の探索開始 ─────────────────────────
func _start_play() -> void:
	result_panel.hide()
	peek_overlay.hide()
	next_btn.hide()
	restart_btn.hide()
	loot_panel.show()
	inventory_panel.show()
	GameState.init_play()
	_build_drawers()
	_refresh_ui()

# ── 引き出し生成 ───────────────────────────
var _drawer_texture: Texture2D = null

func _load_drawer_texture() -> void:
	_drawer_texture = DrawerTexture.get_texture()

func _build_drawers() -> void:
	if _drawer_texture == null:
		_load_drawer_texture()

	for child in drawers_container.get_children():
		drawers_container.remove_child(child)
		child.free()

	for i in GameState.TOTAL_DRAWERS:
		# TextureButton をベースに作る
		var tbtn := TextureButton.new()
		tbtn.name = "Drawer%d" % i
		tbtn.custom_minimum_size = Vector2(160, 90)
		tbtn.ignore_texture_size = true
		tbtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		if _drawer_texture:
			tbtn.texture_normal = _drawer_texture

		# 番号ラベルをオーバーレイ
		var num_lbl := Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.add_theme_font_size_override("font_size", 22)
		num_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		num_lbl.set_anchors_preset(Control.PRESET_CENTER)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tbtn.add_child(num_lbl)

		tbtn.pressed.connect(func(idx = i): _on_drawer_clicked(idx))
		drawers_container.add_child(tbtn)

func _apply_drawer_opened(index: int, item: Dictionary) -> void:
	var tbtn := drawers_container.get_node_or_null("Drawer%d" % index) as TextureButton
	if not tbtn:
		return

	tbtn.disabled = true
	tbtn.modulate = Color(0.55, 0.55, 0.6)

	# 番号ラベルを削除してアイテム表示に差し替え
	for c in tbtn.get_children():
		tbtn.remove_child(c)
		c.free()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_node := _make_icon_node(item, 28)
	icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_lbl := Label.new()
	name_lbl.text = _shorten(item["name"])
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	var rarity_col: Color = GameData.RARITY_COLORS.get(item["rarity"], Color.WHITE)
	name_lbl.add_theme_color_override("font_color", rarity_col)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	vbox.add_child(icon_node)
	vbox.add_child(name_lbl)
	tbtn.add_child(vbox)

# ── UI更新 ─────────────────────────────────
func _refresh_ui() -> void:
	label_round.text = "ラウンド: %d / %d" % [GameState.current_round, GameState.MAX_ROUNDS]
	label_value.text = "今回獲得: ¥%s" % _fmt(GameState.total_value)
	label_items.text = "アイテム: %d個" % GameState.inventory.size()
	_update_stash_display()
	_update_ult_buttons()
	_refresh_inventory()

func _update_stash_display() -> void:
	stash_amount.text = "¥%s" % _fmt(GameState.stash)
	if GameState.stash < GameState.PLAY_COST * 2:
		stash_amount.add_theme_color_override("font_color", Color("#ff6b6b"))
	elif GameState.stash < GameState.PLAY_COST * 3:
		stash_amount.add_theme_color_override("font_color", Color("#ffaa44"))
	else:
		stash_amount.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5, 1))

func _update_ult_buttons() -> void:
	var can_use: bool = not GameState.ult_used and GameState.current_round_items.size() == 0
	ult_peek_btn.disabled = not can_use
	ult_reset_btn.disabled = not can_use

# ── ラウンド開始シグナル ───────────────────
func _on_round_started(_round: int) -> void:
	_build_drawers()
	_refresh_ui()
	next_btn.hide()
	restart_btn.hide()

	if not GameState.bonus_item.is_empty():
		pass  # bonus_eventシグナルで処理済み
	else:
		bonus_panel.hide()
		loot_title.text = "このラウンドの獲得アイテム (0/%d)" % GameState.DRAWERS_PER_ROUND
		_clear_loot_list()

# ── ボーナスイベント ───────────────────────
func _on_bonus_event(bitem: Dictionary) -> void:
	bonus_panel.show()

	# アイコンを差し替え（缶詰・タバコはテクスチャ、他は絵文字）
	for c in bonus_icon.get_children():
		bonus_icon.remove_child(c)
		c.free()
	var icon_node := _make_icon_node(bitem, 40)
	icon_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	bonus_icon.add_child(icon_node)

	bonus_label.text = "⭐ ボーナス対象: %s" % bitem["name"]
	bonus_mult.text = "%d倍！" % bitem.get("multiplier", 2)
	bonus_mult.add_theme_color_override("font_color", Color("#ffd700"))
	loot_title.text = "引き出しを選択してください..."
	_clear_loot_list()

# ── 引き出しクリック ───────────────────────
func _on_drawer_clicked(index: int) -> void:
	GameState.open_drawer(index)

func _on_drawer_opened(index: int, item: Dictionary) -> void:
	# SE再生
	if sfx_drawer and sfx_drawer.stream:
		sfx_drawer.play()
	if item["rarity"] == "legendary" and sfx_legendary and sfx_legendary.stream:
		await get_tree().create_timer(0.3).timeout
		sfx_legendary.play()

	# 引き出しを開封済みに更新
	_apply_drawer_opened(index, item)

	_refresh_loot()
	_refresh_ui()

# ── ラウンド終了 ───────────────────────────
func _on_round_ended(_items: Array) -> void:
	# 未開封引き出しを全部無効化
	for child in drawers_container.get_children():
		var tbtn := child as TextureButton
		if tbtn and not tbtn.disabled:
			tbtn.disabled = true
			tbtn.modulate = Color(0.45, 0.45, 0.5)

	_refresh_ui()

	await get_tree().create_timer(0.8).timeout

	if GameState.current_round < GameState.MAX_ROUNDS:
		next_btn.show()
	else:
		GameState.finish_play()

# ── 次のラウンド ───────────────────────────
func _on_next_pressed() -> void:
	next_btn.hide()
	GameState.next_round()

# ── 1探索終了 ────────────────────────────
func _on_play_finished(earned: int, new_stash: int) -> void:
	result_panel.show()
	loot_panel.hide()
	bonus_panel.hide()
	_update_stash_display()

	var can_continue: bool = GameState.can_continue()

	if can_continue:
		result_rank.text  = "✅ 探索終了"
		result_rank.add_theme_color_override("font_color", Color("#44ff88"))
		result_score.text = "今回の獲得: ¥%s　→　スタッシュ: ¥%s" % [
			_fmt(earned), _fmt(new_stash)]
		restart_btn.text = "▶ 次の探索へ（¥%s）" % _fmt(GameState.PLAY_COST)
	else:
		result_rank.text  = "💀 破産！ゲーム終了"
		result_rank.add_theme_color_override("font_color", Color("#ff4444"))
		result_score.text = "スタッシュ残高: ¥%s（¥%s 不足）" % [
			_fmt(new_stash), _fmt(GameState.PLAY_COST - new_stash)]
		restart_btn.text  = "🔄 最初から探索"

	_build_ranking_list(new_stash)
	restart_btn.show()

func _build_ranking_list(current_stash: int) -> void:
	for c in ranking_list.get_children():
		ranking_list.remove_child(c)
		c.free()

	var rankings: Array = GameState.load_rankings()
	var medals: Array = ["🥇", "🥈", "🥉"]

	for i in rankings.size():
		var entry: Dictionary = rankings[i]
		var row := HBoxContainer.new()

		var medal_lbl := Label.new()
		medal_lbl.text = medals[i] if i < 3 else "#%d" % (i + 1)
		medal_lbl.custom_minimum_size.x = 40

		var score_lbl := Label.new()
		score_lbl.text = "¥%s" % _fmt(int(entry["score"]))
		if int(entry["score"]) == current_stash:
			score_lbl.add_theme_color_override("font_color", Color("#ffd700"))

		var date_lbl := Label.new()
		date_lbl.text = "  %s" % entry.get("date", "")
		date_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		row.add_child(medal_lbl)
		row.add_child(score_lbl)
		row.add_child(date_lbl)
		ranking_list.add_child(row)

# ── リスタート／次の探索 ──────────────────
func _on_restart_pressed() -> void:
	restart_btn.hide()
	if GameState.can_continue():
		_start_play()
	else:
		_start_session()

# ── ウルト: 中身を見る ──────────────────────
func _on_peek_pressed() -> void:
	var result: Dictionary = GameState.use_peek()
	if result.is_empty():
		return
	var idx: int = result["index"]
	var item: Dictionary = result["item"]
	peek_index_label.text  = "引き出し %d の中身" % (idx + 1)
	for c in peek_icon_label.get_children():
		peek_icon_label.remove_child(c)
		c.free()
	var icon_node := _make_icon_node(item, 56)
	icon_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	peek_icon_label.add_child(icon_node)
	peek_name_label.text   = item["name"]
	peek_rarity_label.text = GameData.RARITY_NAMES.get(item["rarity"], "")
	peek_rarity_label.add_theme_color_override(
		"font_color", GameData.RARITY_COLORS.get(item["rarity"], Color.WHITE))
	peek_overlay.show()
	_update_ult_buttons()

# ── ウルト: リセット ───────────────────────
func _on_reset_pressed() -> void:
	GameState.use_reset()
	_build_drawers()
	_update_ult_buttons()

# ── Loot表示 ───────────────────────────────
func _refresh_loot() -> void:
	_clear_loot_list()
	var items: Array = GameState.current_round_items
	loot_title.text = "🎉 このラウンドの獲得アイテム (%d/%d)" % [
		items.size(), GameState.DRAWERS_PER_ROUND]

	if not GameState.bonus_item.is_empty():
		var bname: String = GameState.bonus_item["name"]
		var bmult: int = GameState.bonus_item.get("multiplier", 2)
		loot_title.text += "\n⭐ボーナス対象(%d倍): %s" % [bmult, bname]

	for item in items:
		var row := _make_item_row(item)
		loot_list.add_child(row)

func _clear_loot_list() -> void:
	for c in loot_list.get_children():
		loot_list.remove_child(c)
		c.free()

# ── Inventory表示 ──────────────────────────
func _refresh_inventory() -> void:
	for c in inventory_list.get_children():
		inventory_list.remove_child(c)
		c.free()
	for item in GameState.inventory:
		var row := _make_item_row(item)
		inventory_list.add_child(row)

# ── アイテム行生成 ─────────────────────────
func _make_item_row(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	var rarity: String = item.get("rarity", "common")
	sb.bg_color = GameData.RARITY_BG_COLORS.get(rarity, Color(0.15, 0.15, 0.2, 0.5))
	if item.get("had_bonus", false):
		sb.bg_color = Color(1.0, 0.596, 0.0, 0.18)
	sb.border_color = GameData.RARITY_COLORS.get(rarity, Color.GRAY)
	sb.border_width_left = 3
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var icon_node := _make_icon_node(item, 32)

	var vbox := VBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))

	var detail_lbl := Label.new()
	var rarity_name: String = GameData.RARITY_NAMES.get(rarity, rarity)
	var val_text: String = "¥%s  [%s]" % [_fmt(item["value"]), rarity_name]
	if item.get("had_bonus", false):
		val_text += "  ⭐%d倍ボーナス！" % item.get("bonus_multiplier", 2)
	detail_lbl.text = val_text
	detail_lbl.add_theme_font_size_override("font_size", 11)
	detail_lbl.add_theme_color_override("font_color",
		Color("#ff9800") if item.get("had_bonus", false)
		else GameData.RARITY_COLORS.get(rarity, Color.WHITE))

	vbox.add_child(name_lbl)
	vbox.add_child(detail_lbl)
	hbox.add_child(icon_node)
	hbox.add_child(vbox)
	panel.add_child(hbox)
	return panel

# ── アイテム図鑑オーバーレイ ──────────────────
func _on_item_list_open() -> void:
	_current_filter = "all"
	_update_filter_buttons()
	_build_item_grid()
	var total := GameData.get_all_items().size()
	item_list_title.text = "📋 アイテム図鑑  (全%d種)" % total
	item_list_overlay.show()

func _set_filter(rarity: String) -> void:
	_current_filter = rarity
	_update_filter_buttons()
	_build_item_grid()

func _update_filter_buttons() -> void:
	filter_all.button_pressed      = (_current_filter == "all")
	filter_common.button_pressed   = (_current_filter == "common")
	filter_uncommon.button_pressed = (_current_filter == "uncommon")
	filter_rare.button_pressed     = (_current_filter == "rare")
	filter_epic.button_pressed     = (_current_filter == "epic")
	filter_legendary.button_pressed= (_current_filter == "legendary")

func _build_item_grid() -> void:
	# 既存カードを即時削除してから再構築
	for c in item_grid.get_children():
		item_grid.remove_child(c)
		c.free()

	var rarities: Array
	if _current_filter == "all":
		rarities = ["common", "uncommon", "rare", "epic", "legendary"]
	else:
		rarities = [_current_filter]

	for rarity in rarities:
		var items: Array = GameData.ITEMS[rarity]
		for item in items:
			var card := _make_item_card(item, rarity)
			item_grid.add_child(card)

func _make_item_card(item: Dictionary, rarity: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 64)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.bg_color = GameData.RARITY_BG_COLORS.get(rarity, Color(0.15, 0.15, 0.2, 0.5))
	sb.border_color = GameData.RARITY_COLORS.get(rarity, Color.GRAY)
	sb.border_width_left   = 3
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var icon_node := _make_icon_node(item, 28)
	icon_node.custom_minimum_size.x = 28

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var detail_lbl := Label.new()
	var rarity_name: String = GameData.RARITY_NAMES.get(rarity, rarity)
	detail_lbl.text = "¥%s  [%s]" % [_fmt(item["value"]), rarity_name]
	detail_lbl.add_theme_font_size_override("font_size", 11)
	detail_lbl.add_theme_color_override("font_color",
		GameData.RARITY_COLORS.get(rarity, Color.WHITE))

	vbox.add_child(name_lbl)
	vbox.add_child(detail_lbl)
	hbox.add_child(icon_node)
	hbox.add_child(vbox)
	panel.add_child(hbox)
	return panel

# ── アイコンノード生成（缶詰・タバコはテクスチャ、他は絵文字）────
# ── アイコンノード生成（item辞書を直接受け取る）────
# tex_key があればIconTexturesのテクスチャ、なければ絵文字
func _make_icon_node(item: Dictionary, size: int) -> Control:
	var tex_key: String = item.get("tex_key", "")
	if tex_key != "":
		var tex: ImageTexture = IconTextures.get_texture(tex_key)
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(size, size)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			return tr
	# フォールバック: 絵文字ラベル
	var lbl := Label.new()
	lbl.text = item.get("icon", "?")
	lbl.add_theme_font_size_override("font_size", size - 10)
	lbl.custom_minimum_size = Vector2(size, size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

# ── ユーティリティ ─────────────────────────
func _fmt(n: int) -> String:
	# 3桁カンマ区切り
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func _shorten(s: String) -> String:
	if s.length() > 8:
		return s.substr(0, 7) + "…"
	return s

# ── ルールテキスト動的生成 ──────────────────
# 数値はすべて GameState / GameData の定数から参照。
# PLAY_COST などを変更するだけで自動的に反映される。
func _build_rules_text() -> String:
	var cost  := _fmt(GameState.PLAY_COST)
	var init  := _fmt(GameState.INITIAL_STASH)
	var total_items := GameData.get_all_items().size()
	var per_run := GameState.MAX_ROUNDS * GameState.DRAWERS_PER_ROUND

	# レアリティごとの価値レンジを GameData.ITEMS から動的計算
	var ranges: Dictionary = {}
	for rarity in ["common", "uncommon", "rare", "epic", "legendary"]:
		var vals: Array = []
		for item in GameData.ITEMS[rarity]:
			vals.append(item["value"])
		vals.sort()
		ranges[rarity] = [vals[0], vals[vals.size() - 1]]

	return (
		"[b][color=#ffd700]💰 スタッシュシステム[/color][/b]\n"
		+ "・初期所持金：¥%s\n" % init
		+ "・1探索のコスト：¥%s\n" % cost
		+ "・探索終了後、獲得アイテムの合計金額がスタッシュに加算されます\n"
		+ "・スタッシュが¥%s を下回った時点で[color=#ff4444]破産・ゲーム終了[/color]となります\n" % cost
		+ "\n"
		+ "[b][color=#ffd700]🎮 基本ルール[/color][/b]\n"
		+ "・全%dラウンド制（1探索 = %dラウンド）\n" % [GameState.MAX_ROUNDS, GameState.MAX_ROUNDS]
		+ "・各ラウンドに%dつの引き出しが登場\n" % GameState.TOTAL_DRAWERS
		+ "・その中から%dつを選んで開ける（計%d アイテム獲得）\n" % [GameState.DRAWERS_PER_ROUND, per_run]
		+ "\n"
		+ "[b][color=#ffd700]⭐ ボーナスイベント[/color][/b]\n"
		+ "・40%の確率でボーナスイベントが発生\n"
		+ "・対象アイテムを引くと価値が倍増！\n"
		+ "　🟡 2倍：50%　🟠 3倍：30%　🔴 4倍：15%　💥 5倍：5%\n"
		+ "\n"
		+ "[b][color=#ffd700]🔮 ウルト能力（各ラウンド1回・引き出しを開ける前のみ使用可）[/color][/b]\n"
		+ "・[b]中身を見る🔍[/b]：引き出しを1つランダムで覗き見できる\n"
		+ "・[b]リセット🔄[/b]：全引き出しの中身をシャッフルし直す\n"
		+ "\n"
		+ "[b][color=#ffd700]💎 レアリティ（全%d種）[/color][/b]\n" % total_items
		+ "・[color=#7a8a99]コモン[/color]（50%%）：¥%s〜%s\n" % [_fmt(ranges["common"][0]),    _fmt(ranges["common"][1])]
		+ "・[color=#4db87a]アンコモン[/color]（30%%）：¥%s〜%s\n" % [_fmt(ranges["uncommon"][0]), _fmt(ranges["uncommon"][1])]
		+ "・[color=#4a9eff]レア[/color]（15%%）：¥%s〜%s\n" % [_fmt(ranges["rare"][0]),      _fmt(ranges["rare"][1])]
		+ "・[color=#b06aff]エピック[/color]（4%%）：¥%s〜%s\n" % [_fmt(ranges["epic"][0]),     _fmt(ranges["epic"][1])]
		+ "・[color=#ffc844]レジェンダリー[/color]（1%%）：¥%s〜%s\n" % [_fmt(ranges["legendary"][0]), _fmt(ranges["legendary"][1])]
		+ "\n"
		+ "[b][color=#ffd700]🏆 ランキング評価（スタッシュ残高）[/color][/b]\n"
		+ "・S級：¥200,000以上　・A級：¥100,000以上\n"
		+ "・B級：¥50,000以上　・C級：¥20,000以上　・D級：それ以下"
	)
