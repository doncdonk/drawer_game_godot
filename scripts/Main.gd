# Main.gd
# メインシーンの全UI制御
extends Control

const JunkBoxGridScene := preload("res://scripts/JunkBoxGrid.gd")
const NikitaGridScene  := preload("res://scripts/NikitaGrid.gd")
const CardNodeScene    := preload("res://scripts/CardNode.gd")

# ── ノード参照 ──────────────────────────────
@onready var label_round      := $VBox/MarginContainer/VBoxInner/TopBar/LabelRound
@onready var label_value      := $VBox/MarginContainer/VBoxInner/TopBar/LabelValue
@onready var label_items      := $VBox/MarginContainer/VBoxInner/TopBar/LabelItems

@onready var stash_amount     := $VBox/MarginContainer/VBoxInner/StashBar/StashHBox/StashAmount
@onready var stash_cost_label := $VBox/MarginContainer/VBoxInner/StashBar/StashHBox/StashCostLabel
@onready var label_play_count := $VBox/MarginContainer/VBoxInner/StashBar/StashHBox/LabelPlayCount

@onready var bonus_panel      := $VBox/MarginContainer/VBoxInner/BonusPanel
@onready var bonus_label      := $VBox/MarginContainer/VBoxInner/BonusPanel/BonusVBox/BonusHBox/BonusVBox2/BonusLabel
@onready var bonus_icon: Control  = $VBox/MarginContainer/VBoxInner/BonusPanel/BonusVBox/BonusHBox/BonusIcon
@onready var bonus_mult       := $VBox/MarginContainer/VBoxInner/BonusPanel/BonusVBox/BonusHBox/BonusVBox2/BonusMult

@onready var drawers_container := $VBox/MarginContainer/VBoxInner/DrawersContainer

@onready var ult_peek_btn     := $VBox/MarginContainer/VBoxInner/UltButtons/PeekButton
@onready var ult_reset_btn    := $VBox/MarginContainer/VBoxInner/UltButtons/ResetButton
@onready var next_btn         := $VBox/MarginContainer/VBoxInner/ActionButtons/NextButton
@onready var slot_btn         := $VBox/MarginContainer/VBoxInner/ActionButtons/SlotButton
@onready var bj_btn           := $VBox/MarginContainer/VBoxInner/ActionButtons/BJButton
@onready var poker_btn        := $VBox/MarginContainer/VBoxInner/ActionButtons/PokerButton
@onready var restart_btn      := $VBox/MarginContainer/VBoxInner/ActionButtons/RestartButton

# ── ブラックジャックオーバーレイ ──────────
@onready var bj_overlay         := $BJOverlay
@onready var bj_close_btn       := $BJOverlay/Panel/VBox/HeaderRow/BJCloseBtn
@onready var bj_dealer_card_row := $BJOverlay/Panel/VBox/DealerArea/DealerCardRow
@onready var bj_player_card_row := $BJOverlay/Panel/VBox/PlayerArea/PlayerCardRow
@onready var bj_dealer_score    := $BJOverlay/Panel/VBox/DealerArea/DealerScoreLabel
@onready var bj_player_score    := $BJOverlay/Panel/VBox/PlayerArea/PlayerScoreLabel
@onready var bj_result_area     := $BJOverlay/Panel/VBox/ResultArea
@onready var bj_result_lbl      := $BJOverlay/Panel/VBox/ResultArea/ResultLabel
@onready var bj_payout_lbl      := $BJOverlay/Panel/VBox/ResultArea/PayoutLabel
@onready var bj_hit_btn         := $BJOverlay/Panel/VBox/ActionRow/HitButton
@onready var bj_stand_btn       := $BJOverlay/Panel/VBox/ActionRow/StandButton
@onready var bj_again_btn       := $BJOverlay/Panel/VBox/ActionRow/PlayAgainButton
@onready var bj_status_lbl      := $BJOverlay/Panel/VBox/BJStatusLabel
@onready var bj_stash_lbl       := $BJOverlay/Panel/VBox/HeaderRow/BJStashLabel

# ── ポーカーオーバーレイ ──────────────────
@onready var poker_overlay        := $PokerOverlay
@onready var poker_close_btn      := $PokerOverlay/Panel/VBox/HeaderRow/PokerCloseBtn
@onready var poker_pot_lbl        := $PokerOverlay/Panel/VBox/HeaderRow/TitleVBox/PokerPotLabel
@onready var poker_dealer_row     := $PokerOverlay/Panel/VBox/DealerArea/DealerCardRow
@onready var poker_player_row     := $PokerOverlay/Panel/VBox/PlayerArea/PlayerCardRow
@onready var poker_dealer_rank    := $PokerOverlay/Panel/VBox/DealerArea/DealerRankLabel
@onready var poker_player_rank    := $PokerOverlay/Panel/VBox/PlayerArea/PlayerRankLabel
@onready var poker_draw_hint      := $PokerOverlay/Panel/VBox/PlayerArea/DrawHintLabel
@onready var poker_result_area    := $PokerOverlay/Panel/VBox/ResultArea
@onready var poker_result_lbl     := $PokerOverlay/Panel/VBox/ResultArea/PokerResultLabel
@onready var poker_payout_lbl     := $PokerOverlay/Panel/VBox/ResultArea/PokerPayoutLabel
@onready var poker_check_btn      := $PokerOverlay/Panel/VBox/ActionRow/CheckButton
@onready var poker_raise_btn      := $PokerOverlay/Panel/VBox/ActionRow/RaiseButton
@onready var poker_fold_btn       := $PokerOverlay/Panel/VBox/ActionRow/FoldButton
@onready var poker_draw_btn       := $PokerOverlay/Panel/VBox/ActionRow/DrawButton
@onready var poker_again_btn      := $PokerOverlay/Panel/VBox/ActionRow/PlayAgainButton
@onready var poker_status_lbl     := $PokerOverlay/Panel/VBox/PokerStatusLabel
@onready var poker_stash_lbl      := $PokerOverlay/Panel/VBox/HeaderRow/PokerStashLabel

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
@onready var sfx_explosion    := $SFXExplosion
@onready var sfx_slot_win     := $SFXSlotWin
@onready var sfx_slot_reel    := $SFXSlotReel

# ── スロットオーバーレイ ──────────────────────
@onready var slot_overlay     := $SlotOverlay
@onready var slot_result_lbl  := $SlotOverlay/Panel/VBox/ResultLabel
@onready var slot_loot_preview: RichTextLabel = $SlotOverlay/Panel/VBox/LootPreview
@onready var slot_spin_btn    := $SlotOverlay/Panel/VBox/SpinButton
@onready var slot_close_btn   := $SlotOverlay/Panel/VBox/CloseButton
# リール上中下ラベル [reel_idx][0=top,1=mid,2=bot]
var _reel_labels: Array = []
var _slot_reel_looping := false   # リール回転音ループ制御

# ── トラップイベントオーバーレイ ───────────────
@onready var event_overlay    := $DrawerEventOverlay
@onready var event_icon       := $DrawerEventOverlay/Panel/VBox/EventIcon
@onready var event_title      := $DrawerEventOverlay/Panel/VBox/EventTitle
@onready var event_message    := $DrawerEventOverlay/Panel/VBox/EventMessage
@onready var event_effect     := $DrawerEventOverlay/Panel/VBox/EventEffect
@onready var event_close_btn  := $DrawerEventOverlay/Panel/VBox/CloseButton

# ── ジャンクボックスオーバーレイ ──────────────
@onready var junkbox_overlay    := $JunkBoxOverlay
@onready var junkbox_grid_node  := $JunkBoxOverlay/Panel/VBox/ContentHBox/GridContainer
@onready var junkbox_close_btn  := $JunkBoxOverlay/Panel/VBox/HeaderRow/CloseButton
@onready var junkbox_info_lbl   := $JunkBoxOverlay/Panel/VBox/InfoLabel
@onready var junkbox_btn        := $VBox/MarginContainer/VBoxInner/ButtonRow/JunkBoxButton
@onready var nikita_task_btn    := $VBox/MarginContainer/VBoxInner/ButtonRow/NikitaTaskButton
@onready var nikita_grid_node   := $JunkBoxOverlay/Panel/VBox/ContentHBox/NikitaPane/NikitaGridContainer
@onready var nikita_sell_btn    := $JunkBoxOverlay/Panel/VBox/ContentHBox/NikitaPane/SellButton
var _junkbox_grid               = null
var _nikita_grid                = null
var _nikita_selected_entry: Dictionary = {}

# ── ニキータタスクオーバーレイ ─────────────
@onready var nikita_task_overlay  := $NikitaTaskOverlay
@onready var nikita_task_list     := $NikitaTaskOverlay/Panel/VBox/TaskScroll/TaskList
@onready var nikita_task_close    := $NikitaTaskOverlay/Panel/VBox/HeaderRow/CloseButton
@onready var nikita_task_result   := $NikitaTaskOverlay/Panel/VBox/ResultLabel
@onready var task_confirm_dialog  := $NikitaTaskOverlay/Panel/VBox/ConfirmDialog
@onready var task_confirm_label   := $NikitaTaskOverlay/Panel/VBox/ConfirmDialog/ConfirmVBox/ConfirmLabel
@onready var task_confirm_yes     := $NikitaTaskOverlay/Panel/VBox/ConfirmDialog/ConfirmVBox/ConfirmBtnRow/YesButton
@onready var task_confirm_no      := $NikitaTaskOverlay/Panel/VBox/ConfirmDialog/ConfirmVBox/ConfirmBtnRow/NoButton

# ── 設定オーバーレイ ──────────────────────
@onready var settings_overlay     := $SettingsOverlay
@onready var settings_close_btn   := $SettingsOverlay/Panel/VBox/HeaderRow/CloseButton
@onready var se_slider            := $SettingsOverlay/Panel/VBox/SERow/SESlider
@onready var se_value_lbl         := $SettingsOverlay/Panel/VBox/SERow/SEValueLabel

# ── 格納フェーズオーバーレイ ──────────────────
@onready var stash_phase_overlay  := $StashPhaseOverlay
@onready var stash_acquired_list  := $StashPhaseOverlay/Panel/VBox/MainHBox/LeftPane/AcquiredScroll/AcquiredList
@onready var stash_grid_node      := $StashPhaseOverlay/Panel/VBox/MainHBox/RightPane/GridContainer
@onready var stash_sell_preview   := $StashPhaseOverlay/Panel/VBox/SellPreview
@onready var stash_confirm_btn    := $StashPhaseOverlay/Panel/VBox/ConfirmButton
var _stash_phase_grid             = null   # JunkBoxGrid instance
var _stash_pending_items: Array   = []

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
	GameState.drawer_event.connect(_on_drawer_event)
	GameState.round_ended.connect(_on_round_ended)
	GameState.play_finished.connect(_on_play_finished)
	GameState.stash_phase_started.connect(_on_stash_phase_started)
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

	# トラップイベントオーバーレイ
	event_close_btn.pressed.connect(func(): event_overlay.hide())

	# スロット
	slot_btn.pressed.connect(_on_slot_btn_pressed)
	bj_btn.pressed.connect(_on_bj_btn_pressed)
	bj_close_btn.pressed.connect(_on_bj_close)
	bj_hit_btn.pressed.connect(_on_bj_hit)
	bj_stand_btn.pressed.connect(_on_bj_stand)
	bj_again_btn.pressed.connect(_on_bj_play_again)
	poker_btn.pressed.connect(_on_poker_btn_pressed)
	poker_close_btn.pressed.connect(_on_poker_close)
	poker_check_btn.pressed.connect(_on_poker_check)
	poker_raise_btn.pressed.connect(_on_poker_raise)
	poker_fold_btn.pressed.connect(_on_poker_fold)
	poker_draw_btn.pressed.connect(_on_poker_draw)
	poker_again_btn.pressed.connect(_on_poker_play_again)
	slot_spin_btn.pressed.connect(_on_slot_spin)
	slot_close_btn.pressed.connect(_on_slot_close)
	# リール回転音：再生終了時に自動ループ（_slot_reel_loopingフラグで制御）
	sfx_slot_reel.finished.connect(_on_slot_reel_finished)

	# コスト表示をコードから動的設定（PLAY_COSTの一元管理）
	stash_cost_label.text = "（1探索 ¥%s）" % _fmt(GameState.PLAY_COST)

	# ルールテキストを RulesBuilder から動的生成
	rules_text.text = RulesBuilder.build()

	# ジャンクボックスグリッド（常設）
	_junkbox_grid = JunkBoxGridScene.new()
	_junkbox_grid.mode = "junkbox"
	junkbox_grid_node.add_child(_junkbox_grid)
	_junkbox_grid.custom_minimum_size = _junkbox_grid.get_required_size()
	junkbox_btn.pressed.connect(_on_junkbox_btn_pressed)
	junkbox_close_btn.pressed.connect(_on_junkbox_close)
	nikita_sell_btn.pressed.connect(_on_nikita_sell)
	nikita_task_btn.pressed.connect(_on_nikita_task_btn_pressed)
	nikita_task_close.pressed.connect(func(): nikita_task_overlay.hide())
	task_confirm_no.pressed.connect(_on_discard_cancel)
	TaskManager.task_completed.connect(_on_task_completed)
	TaskManager.tasks_updated.connect(_on_tasks_updated)

	# 設定
	var settings_btn := $VBox/MarginContainer/VBoxInner/ButtonRow/SettingsButton
	settings_btn.pressed.connect(_on_settings_btn_pressed)
	settings_close_btn.pressed.connect(func(): settings_overlay.hide())
	se_slider.value_changed.connect(_on_se_volume_changed)
	# 保存済み音量を復元
	var saved_vol: float = ProjectSettings.get_setting("audio/se_volume", 1.0) if false else 1.0
	se_slider.value = saved_vol

	# ニキータグリッド
	_nikita_grid = NikitaGridScene.new()
	nikita_grid_node.add_child(_nikita_grid)
	_nikita_grid.custom_minimum_size = _nikita_grid.get_required_size()

	# 格納フェーズグリッド
	_stash_phase_grid = JunkBoxGridScene.new()
	_stash_phase_grid.mode = "stash_phase"
	stash_grid_node.add_child(_stash_phase_grid)
	_stash_phase_grid.custom_minimum_size = _stash_phase_grid.get_required_size()
	stash_confirm_btn.pressed.connect(_on_stash_confirm)

	# add_child 後に _ready() が走るのを待ってからシグナル接続
	await get_tree().process_frame
	_junkbox_grid.connect("item_selected",   _on_junkbox_item_selected)
	_junkbox_grid.connect("item_deselected", _on_junkbox_item_deselected)
	_junkbox_grid.connect("layout_changed",  _refresh_junkbox_info)
	_junkbox_grid.connect("send_to_nikita",  _on_send_to_nikita)
	_nikita_grid.connect("items_changed",    _on_nikita_items_changed)
	_stash_phase_grid.connect("pending_placed",   _on_stash_pending_placed)
	_stash_phase_grid.connect("pending_returned", _on_stash_pending_returned)
	_stash_phase_grid.connect("layout_changed",   _refresh_stash_sell_preview)
	task_confirm_yes.pressed.connect(_on_discard_confirmed)

	# スロット リールラベルをコードで収集
	for r in 3:
		_reel_labels.append([
			get_node("SlotOverlay/Panel/VBox/ReelRow/Reel%d/ReelVBox%d/ReelTop%d" % [r, r, r]),
			get_node("SlotOverlay/Panel/VBox/ReelRow/Reel%d/ReelVBox%d/ReelMid%d" % [r, r, r]),
			get_node("SlotOverlay/Panel/VBox/ReelRow/Reel%d/ReelVBox%d/ReelBot%d" % [r, r, r]),
		])

	_start_session()

# ── セッション開始（初回・破産後）─────────────
func _start_session() -> void:
	result_panel.hide()
	peek_overlay.hide()
	next_btn.hide()
	slot_btn.hide()
	bj_btn.hide()
	poker_btn.hide()
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
	slot_btn.hide()
	bj_btn.hide()
	poker_btn.hide()
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
	var text := "💰 ¥%s" % _fmt(GameState.stash)
	stash_amount.text = "¥%s" % _fmt(GameState.stash)
	if GameState.stash < GameState.PLAY_COST * 2:
		stash_amount.add_theme_color_override("font_color", Color("#ff6b6b"))
	elif GameState.stash < GameState.PLAY_COST * 3:
		stash_amount.add_theme_color_override("font_color", Color("#ffaa44"))
	else:
		stash_amount.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5, 1))
	label_play_count.text = "探索回数: %d回" % GameState.play_count
	# BJ・Pokerオーバーレイのスタッシュ表示も更新
	bj_stash_lbl.text    = text
	poker_stash_lbl.text = text

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

# ── 引き出しトラップイベント ──────────────────
func _on_drawer_event(event: Dictionary) -> void:
	# 効果音再生（イベントIDで分岐、将来的に他イベントも追加しやすい構造）
	match event.get("id", ""):
		"explosion":
			if sfx_explosion and sfx_explosion.stream:
				sfx_explosion.play()

	event_icon.text    = event.get("icon", "⚠️")
	event_title.text   = event.get("title", "イベント発生！")
	event_message.text = event.get("message", "")

	# 効果テキスト
	match event.get("effect", "none"):
		"stash_damage":
			var dmg: int = int(event.get("applied_value", 0))
			event_effect.text = "－ ¥%s" % _fmt(dmg)
			event_effect.add_theme_color_override("font_color", Color("#ff4444"))
		_:
			event_effect.text = ""

	_update_stash_display()
	# アイテム行にトラップフラグが書き込まれたので再描画
	_refresh_loot()
	_refresh_inventory()
	event_overlay.show()

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
		TaskManager.on_explore_success()
		GameState.finish_play()

# ── 次のラウンド ───────────────────────────
func _on_next_pressed() -> void:
	next_btn.hide()
	GameState.next_round()

# ── 1探索終了 ────────────────────────────
func _on_play_finished(earned: int, new_stash: int, trap_damage: int) -> void:
	result_panel.show()
	loot_panel.hide()
	bonus_panel.hide()
	_update_stash_display()

	var can_continue: bool = GameState.can_continue()

	# 収益サマリーを構築（トラップ損失がある場合は明示）
	var summary := "今回の獲得: ¥%s" % _fmt(earned)
	if trap_damage > 0:
		summary += "　⚠️ トラップ損失: －¥%s" % _fmt(trap_damage)
	summary += "　→　スタッシュ: ¥%s" % _fmt(new_stash)

	if can_continue:
		result_rank.text  = "✅ 探索終了"
		result_rank.add_theme_color_override("font_color", Color("#44ff88"))
		result_score.text = summary
		restart_btn.text = "▶ 次の探索へ（¥%s）" % _fmt(GameState.PLAY_COST)
	else:
		result_rank.text  = "💀 破産！ゲーム終了"
		result_rank.add_theme_color_override("font_color", Color("#ff4444"))
		result_score.text = summary + "\n（¥%s 不足）" % _fmt(GameState.PLAY_COST - new_stash)
		restart_btn.text  = "🔄 最初から探索"

	_build_ranking_list(new_stash)
	restart_btn.show()
	# スタッシュが SLOT_COST 以上あるときだけスロットボタンを表示
	slot_btn.visible = can_continue and GameState.stash >= GameState.SLOT_COST
	bj_btn.visible = can_continue and GameState.stash >= BlackjackManager.BET
	poker_btn.visible = can_continue and GameState.stash >= PokerManager.BET

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
		TaskManager.reset()
		JunkBox.reset()
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
	var had_trap: bool  = item.get("had_trap", false)
	var had_bonus: bool = item.get("had_bonus", false)

	# 背景色: トラップ > ボーナス > レアリティ
	if had_trap:
		sb.bg_color = Color(0.55, 0.08, 0.08, 0.35)
		sb.border_color = Color("#ff3333")
	elif had_bonus:
		sb.bg_color = Color(1.0, 0.596, 0.0, 0.18)
		sb.border_color = GameData.RARITY_COLORS.get(rarity, Color.GRAY)
	else:
		sb.bg_color = GameData.RARITY_BG_COLORS.get(rarity, Color(0.15, 0.15, 0.2, 0.5))
		sb.border_color = GameData.RARITY_COLORS.get(rarity, Color.GRAY)
	sb.border_width_left = 3
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var icon_node := _make_icon_node(item, 32)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))

	var detail_lbl := Label.new()
	var rarity_name: String = GameData.RARITY_NAMES.get(rarity, rarity)
	var val_text: String = "¥%s  [%s]" % [_fmt(item["value"]), rarity_name]
	if had_bonus:
		val_text += "  ⭐%d倍ボーナス！" % item.get("bonus_multiplier", 2)
	detail_lbl.text = val_text
	detail_lbl.add_theme_font_size_override("font_size", 11)
	detail_lbl.add_theme_color_override("font_color",
		Color("#ff9800") if had_bonus
		else GameData.RARITY_COLORS.get(rarity, Color.WHITE))

	vbox.add_child(name_lbl)
	vbox.add_child(detail_lbl)

	# トラップ表示行
	if had_trap:
		var trap_event: Dictionary = item.get("trap_event", {})
		var trap_icon   : String = trap_event.get("icon", "💥")
		var trap_msg    : String = trap_event.get("message", "トラップ発動")
		var effect      : String = trap_event.get("effect", "none")
		var applied     : int    = int(trap_event.get("applied_value", 0))

		var trap_lbl := Label.new()
		var trap_text := "%s %s" % [trap_icon, trap_msg]
		if effect == "stash_damage" and applied > 0:
			trap_text += "  (－¥%s)" % _fmt(applied)
		trap_lbl.text = trap_text
		trap_lbl.add_theme_font_size_override("font_size", 11)
		trap_lbl.add_theme_color_override("font_color", Color("#ff6666"))
		vbox.add_child(trap_lbl)

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

# ── スロットマシン ──────────────────────────
func _on_slot_btn_pressed() -> void:
	# リールをリセットして開く
	for r in 3:
		var labels: Array = _reel_labels[r]
		for lbl: Label in labels:
			lbl.text = "？"
	slot_result_lbl.text = ""
	slot_loot_preview.text = ""
	_update_slot_spin_btn()
	slot_overlay.show()

func _update_slot_spin_btn() -> void:
	var can_spin: bool = GameState.stash >= GameState.SLOT_COST
	slot_spin_btn.disabled = not can_spin
	slot_spin_btn.text = "🎲 スピン！（¥%s）" % _fmt(GameState.SLOT_COST) if can_spin \
		else "残高不足（¥%s 必要）" % _fmt(GameState.SLOT_COST)

func _on_slot_spin() -> void:
	slot_spin_btn.disabled = true
	slot_result_lbl.text   = ""
	slot_loot_preview.text = ""

	# 結果を事前取得（演出はこの後）
	var spin_result: Dictionary = SlotMachine.spin()
	if not spin_result["ok"]:
		slot_result_lbl.text = "残高が足りません"
		_update_slot_spin_btn()
		return

	var results: Array = spin_result["results"]
	var payout:  int   = spin_result["payout"]
	var loot:    Array = spin_result["loot"]
	var is_win:  bool  = payout > 0

	# 各リールのストリップを生成（演出用）
	var strips: Array = []
	for r in 3:
		strips.append(SlotMachine.build_reel_strip())

	# 結果シンボルのストリップ内インデックスを確定
	var stop_indices: Array = []
	for r in 3:
		var strip: Array = strips[r]
		var target_icon: String = results[r]["icon"]
		# strip内で一致するインデックスを探す（なければ末尾）
		var found := strip.size() - 1
		for i in strip.size():
			if strip[i]["icon"] == target_icon:
				found = i
				break
		stop_indices.append(found)

	# リールアニメーション：順番に止まる
	# 回転音をループ再生（finished シグナルで繰り返す）
	if sfx_slot_reel and sfx_slot_reel.stream:
		_slot_reel_looping = true
		sfx_slot_reel.play()

	for r in 3:
		var strip: Array   = strips[r]
		var stop:  int     = stop_indices[r]
		var labels: Array  = _reel_labels[r]
		var spin_ticks := 18 + r * 8  # リールごとに少し長く
		var cur_pos := randi() % strip.size()

		for tick in spin_ticks:
			# 減速カーブ：後半ほど遅く
			var speed: float = 0.03 if tick < spin_ticks - 6 else 0.06 + (tick - (spin_ticks - 6)) * 0.02
			var size  := strip.size()
			labels[0].text = strip[(cur_pos - 1 + size) % size]["icon"]
			labels[1].text = strip[cur_pos]["icon"]
			labels[2].text = strip[(cur_pos + 1) % size]["icon"]
			cur_pos = (cur_pos + 1) % size
			await get_tree().create_timer(speed).timeout

		# 最終停止：中段が結果シンボル
		var sz := strip.size()
		labels[0].text = strip[(stop - 1 + sz) % sz]["icon"]
		labels[1].text = strip[stop]["icon"]
		labels[2].text = strip[(stop + 1) % sz]["icon"]
		await get_tree().create_timer(0.2).timeout

	# 全リール停止後に回転音を止める
	_slot_reel_looping = false
	if sfx_slot_reel and sfx_slot_reel.playing:
		sfx_slot_reel.stop()

	_update_stash_display()
	TaskManager.on_slot_spin()
	# スロット獲得アイテムを格納フェーズ待ちリストに追加（GameState.inventoryからは除外）
	for item: Dictionary in loot:
		if not item.is_empty():
			GameState.inventory.erase(item)
			_slot_pending_loot.append(item)
	_refresh_inventory()

	# アイテム獲得プレビュー（スロット由来のアイテム名を表示）
	var loot_texts: Array = []
	for item: Dictionary in loot:
		if not item.is_empty():
			var rarity: String = item.get("rarity", "common")
			var color:  String = GameData.RARITY_COLORS.get(rarity, Color.WHITE).to_html(false)
			loot_texts.append("[color=#%s]%s %s (¥%s)[/color]" % [
				color, item.get("icon", ""), item["name"], _fmt(int(item["value"]))
			])
	if not loot_texts.is_empty():
		slot_loot_preview.parse_bbcode("📦 獲得アイテム: " + "  ".join(loot_texts))

	# 当選・落選メッセージ
	if is_win:
		var mult: int = results[0].get("multiplier", 1)
		slot_result_lbl.text = "🎉 当たり！  ¥%s 獲得！（%d倍）" % [_fmt(payout), mult]
		slot_result_lbl.add_theme_color_override("font_color", Color("#ffd700"))
		if sfx_slot_win and sfx_slot_win.stream:
			sfx_slot_win.play()
	else:
		slot_result_lbl.text = "ハズレ…"
		slot_result_lbl.add_theme_color_override("font_color", Color("#aaaaaa"))

	_update_slot_spin_btn()

var _slot_pending_loot: Array = []   # スロット獲得アイテム（格納フェーズ待ち）

func _on_slot_reel_finished() -> void:
	if _slot_reel_looping and sfx_slot_reel and sfx_slot_reel.stream:
		sfx_slot_reel.play()

func _on_slot_close() -> void:
	_slot_reel_looping = false
	if sfx_slot_reel and sfx_slot_reel.playing:
		sfx_slot_reel.stop()
	slot_overlay.hide()
	slot_btn.visible = GameState.stash >= GameState.SLOT_COST
	bj_btn.visible = GameState.stash >= BlackjackManager.BET
	poker_btn.visible = GameState.stash >= PokerManager.BET
	_update_stash_display()
	# スロットで獲得したアイテムがあれば格納フェーズへ
	if not _slot_pending_loot.is_empty():
		var items := _slot_pending_loot.duplicate()
		_slot_pending_loot = []
		_open_stash_phase(items)

# ── ジャンクボックス（探索前整理モード）────────
func _on_junkbox_btn_pressed() -> void:
	_refresh_junkbox_info()
	junkbox_overlay.show()

func _on_junkbox_close() -> void:
	# ニキータグリッドにアイテムが残っていたらジャンクボックスに戻す
	if _nikita_grid:
		for item: Dictionary in _nikita_grid.get_items():
			var cell := JunkBox.find_free_cell(1, 1)
			if cell[0] >= 0:
				JunkBox.place_item(item, cell[0], cell[1])
		_nikita_grid.clear()
	_nikita_selected_entry = {}
	if _junkbox_grid and _junkbox_grid.has_method("clear_selection"):
		_junkbox_grid.clear_selection()
	nikita_sell_btn.disabled = true
	junkbox_overlay.hide()

func _on_junkbox_item_selected(_entry: Dictionary) -> void:
	pass   # 選択UIはニキータグリッドへのドロップに移行したため不使用

func _on_junkbox_item_deselected() -> void:
	pass

func _on_nikita_items_changed(items: Array) -> void:
	nikita_sell_btn.disabled = items.is_empty()
	var total := 0
	for item: Dictionary in items:
		total += int(item["value"])
	if items.is_empty():
		junkbox_info_lbl.text = _get_junkbox_usage_text()
	else:
		junkbox_info_lbl.text = "売却予定: %d個  合計 ¥%s" % [items.size(), _fmt(total)]

func _on_junkbox_item_sold(_entry: Dictionary, _price: int) -> void:
	pass   # NikitaGrid経由に移行

func _on_nikita_sell() -> void:
	if not _nikita_grid:
		return
	var items: Array = _nikita_grid.get_items()
	if items.is_empty():
		return
	var total := 0
	var names: Array = []
	for item: Dictionary in items:
		var price: int = int(item["value"])
		GameState.stash += price
		total += price
		names.append(item.get("icon","") + item["name"])
	_nikita_grid.clear()
	nikita_sell_btn.disabled = true
	_update_stash_display()
	junkbox_info_lbl.text = "💰 売却完了: %s → ¥%s" % ["、".join(names), _fmt(total)]
	_refresh_junkbox_info.call_deferred()

# ── ニキータタスク ─────────────────────────
func _on_nikita_task_btn_pressed() -> void:
	_build_task_list()
	nikita_task_result.text = ""
	nikita_task_overlay.show()

func _on_task_completed(task: Dictionary, reward: int) -> void:
	_update_stash_display()
	nikita_task_result.text = "✅ タスク完了！  報酬 ¥%s を受領しました 🎉" % _fmt(reward)
	_build_task_list()

func _on_tasks_updated() -> void:
	if nikita_task_overlay.visible:
		_build_task_list()

func _build_task_list() -> void:
	for c in nikita_task_list.get_children():
		c.queue_free()
	for task: Dictionary in TaskManager.active_tasks:
		var card := _make_task_card(task)
		nikita_task_list.add_child(card)

func _make_task_card(task: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	var diff: String = task.get("difficulty", "normal")
	var diff_color := Color("#44aa44") if diff == "easy" else (Color("#ccaa00") if diff == "normal" else Color("#cc3333"))
	sb.bg_color     = Color(diff_color.r, diff_color.g, diff_color.b, 0.12)
	sb.border_color = diff_color
	sb.border_width_left   = 4
	sb.border_width_right  = 0
	sb.border_width_top    = 0
	sb.border_width_bottom = 0
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)

	var diff_lbl := Label.new()
	diff_lbl.text = TaskManager.difficulty_label(task)
	diff_lbl.add_theme_font_size_override("font_size", 11)

	var desc_lbl := Label.new()
	desc_lbl.text = TaskManager.describe(task)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var reward_lbl := Label.new()
	reward_lbl.text = "報酬: ¥%s" % _fmt(int(task["reward"]))
	reward_lbl.add_theme_font_size_override("font_size", 12)
	reward_lbl.add_theme_color_override("font_color", Color("#ffd700"))

	info_vbox.add_child(diff_lbl)
	info_vbox.add_child(desc_lbl)
	info_vbox.add_child(reward_lbl)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 4)

	# 納品タスクのみ「納品する」ボタン
	var is_deliver: bool = task["type"] in ["deliver_icon", "deliver_name", "deliver_rarity"]
	if is_deliver:
		var deliver_btn := Button.new()
		deliver_btn.text = "📦 納品する"
		deliver_btn.add_theme_font_size_override("font_size", 12)
		deliver_btn.add_theme_color_override("font_color", Color("#44ff88"))
		var t := task
		deliver_btn.pressed.connect(func(): _on_deliver_pressed(t))
		btn_vbox.add_child(deliver_btn)

	# 破棄ボタン（全タスク共通）
	var discard_btn := Button.new()
	var cost: int = TaskManager.get_discard_cost(task)
	discard_btn.text = "🗑 破棄 (¥%s)" % _fmt(cost)
	discard_btn.add_theme_font_size_override("font_size", 11)
	discard_btn.add_theme_color_override("font_color", Color("#ff6666"))
	var t2 := task
	discard_btn.pressed.connect(func(): _on_discard_pressed(t2))
	btn_vbox.add_child(discard_btn)

	hbox.add_child(info_vbox)
	hbox.add_child(btn_vbox)
	panel.add_child(hbox)
	return panel

func _on_deliver_pressed(task: Dictionary) -> void:
	var missing: Array = TaskManager.try_deliver(task)
	if missing.is_empty():
		pass
	else:
		nikita_task_result.text = "⚠️ 不足: %s があと %d 個必要です" % [missing[0], missing.size()]

# ── タスク破棄 ────────────────────────────
var _pending_discard_task: Dictionary = {}

func _on_discard_pressed(task: Dictionary) -> void:
	_pending_discard_task = task
	var cost: int = TaskManager.get_discard_cost(task)
	task_confirm_label.text = (
		"このタスクを破棄しますか？\n\n"
		+ "「%s」\n\n" % TaskManager.describe(task)
		+ "[color=#ff6666]破棄コスト: ¥%s[/color]\n" % _fmt(cost)
		+ "（スタッシュから差し引かれます）"
	)
	# リッチテキスト対応に切り替え
	task_confirm_label.text = (
		"このタスクを破棄しますか？\n"
		+ "「%s」\n" % TaskManager.describe(task)
		+ "破棄コスト: ¥%s（スタッシュから差し引かれます）" % _fmt(cost)
	)
	task_confirm_dialog.show()

func _on_discard_confirmed() -> void:
	task_confirm_dialog.hide()
	if _pending_discard_task.is_empty():
		return
	var ok: bool = TaskManager.discard_task(_pending_discard_task)
	_pending_discard_task = {}
	if ok:
		nikita_task_result.text = "🗑 タスクを破棄しました"
		_update_stash_display()
	else:
		nikita_task_result.text = "⚠️ スタッシュが不足しています"

func _on_discard_cancel() -> void:
	task_confirm_dialog.hide()
	_pending_discard_task = {}

# ── 設定 ─────────────────────────────────
func _on_settings_btn_pressed() -> void:
	settings_overlay.show()

func _on_se_volume_changed(value: float) -> void:
	se_value_lbl.text = "%d%%" % int(value * 100)
	# Godot の AudioServer バス "Master" の音量を dB に変換して設定
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	# 0のときミュート
	AudioServer.set_bus_mute(0, value <= 0.0)

func _refresh_junkbox_info() -> void:
	junkbox_info_lbl.text = _get_junkbox_usage_text()

func _get_junkbox_usage_text() -> String:
	var free := JunkBox.free_cells()
	var used := JunkBox.ROWS * JunkBox.COLS - free
	return "使用: %d / %d マス  ｜  空き: %d マス" % [used, JunkBox.ROWS * JunkBox.COLS, free]

# JunkBoxGrid → send_to_nikita シグナル受信
func _on_send_to_nikita(entry: Dictionary) -> void:
	var item: Dictionary = entry["item"]
	if _nikita_grid and _nikita_grid.add_item(item):
		JunkBox.remove_item(entry)
		if _junkbox_grid:
			_junkbox_grid.queue_redraw()
	else:
		# ニキータグリッドが満杯 → アイテムはジャンクボックスに残る
		junkbox_info_lbl.text = "⚠️ ニキータの売却ボックスが満杯です"

# ── 格納フェーズ共通オープン ──────────────────
func _open_stash_phase(items: Array) -> void:
	_stash_pending_items = items.duplicate()
	_stash_phase_grid.set_pending_items(_stash_pending_items)
	_build_acquired_list()
	_refresh_stash_sell_preview()
	stash_phase_overlay.show()

# ── 格納フェーズ ─────────────────────────────
func _on_stash_phase_started(acquired_items: Array) -> void:
	_open_stash_phase(acquired_items)

func _build_acquired_list() -> void:
	for c in stash_acquired_list.get_children():
		c.queue_free()

	for item: Dictionary in _stash_pending_items:
		var row := _make_stash_item_row(item)
		stash_acquired_list.add_child(row)

func _make_stash_item_row(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.set_corner_radius_all(5)
	var rarity: String = item.get("rarity", "common")
	sb.bg_color     = GameData.RARITY_BG_COLORS.get(rarity, Color(0.15, 0.15, 0.2, 0.5))
	sb.border_color = GameData.RARITY_COLORS.get(rarity, Color.GRAY)
	sb.border_width_left = 3
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var icon_lbl := Label.new()
	icon_lbl.text = item.get("icon", "?")
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.custom_minimum_size = Vector2(32, 32)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER

	var vbox     := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 12)
	var val_lbl  := Label.new()
	val_lbl.text = "¥%s" % _fmt(int(item["value"]))
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color",
		GameData.RARITY_COLORS.get(rarity, Color.WHITE))
	vbox.add_child(name_lbl)
	vbox.add_child(val_lbl)

	# ドラッグハンドル（クリックでグリッドへの配置を試みる）
	var store_btn := Button.new()
	store_btn.text = "→格納"
	store_btn.add_theme_font_size_override("font_size", 11)
	store_btn.pressed.connect(func(): _try_auto_place(item))

	hbox.add_child(icon_lbl)
	hbox.add_child(vbox)
	hbox.add_child(store_btn)
	panel.add_child(hbox)
	return panel

func _try_auto_place(item: Dictionary) -> void:
	var cell := JunkBox.find_free_cell(1, 1)
	if cell[0] < 0:
		stash_sell_preview.text = "⚠️ ジャンクボックスが満杯です"
		return
	var placed := JunkBox.place_item(item, cell[0], cell[1])
	if not placed.is_empty():
		_stash_pending_items.erase(item)
		_stash_phase_grid.set_pending_items(_stash_pending_items)
		_refresh_stash_sell_preview()
		# queue_free済みノードの参照を避けるため次フレームで再構築
		call_deferred("_build_acquired_list")

func _on_stash_pending_placed(item: Dictionary) -> void:
	_stash_pending_items.erase(item)
	_refresh_stash_sell_preview()
	call_deferred("_build_acquired_list")

func _on_stash_pending_returned(item: Dictionary) -> void:
	_stash_pending_items.append(item)
	_refresh_stash_sell_preview()
	call_deferred("_build_acquired_list")

func _refresh_stash_sell_preview() -> void:
	if _stash_pending_items.is_empty():
		stash_sell_preview.text = "✅ 全アイテムを格納済み"
		stash_sell_preview.add_theme_color_override("font_color", Color("#44ff88"))
		return
	var total_sell := 0
	var names: Array = []
	for item: Dictionary in _stash_pending_items:
		total_sell += int(item["value"])
		names.append(item["name"])
	stash_sell_preview.text = "💰 売却予定: %s → ¥%s" % [
		"、".join(names), _fmt(total_sell)]
	stash_sell_preview.add_theme_color_override("font_color", Color("#ffaa44"))

func _on_stash_confirm() -> void:
	stash_phase_overlay.hide()
	# 未格納アイテムを売却リストとして渡す
	GameState.commit_stash_phase(_stash_pending_items.duplicate())
	_stash_pending_items = []

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

# ═══════════════════════════════════════════════
# ── ブラックジャック ────────────────────────────
# ═══════════════════════════════════════════════
func _on_bj_btn_pressed() -> void:
	if GameState.stash < BlackjackManager.BET:
		return
	GameState.stash -= BlackjackManager.BET
	_update_stash_display()
	BlackjackManager.start_game()
	_bj_refresh_ui()
	bj_overlay.show()

func _on_bj_close() -> void:
	bj_overlay.hide()

func _on_bj_hit() -> void:
	BlackjackManager.hit()
	_bj_refresh_ui()

func _on_bj_stand() -> void:
	BlackjackManager.stand()
	_bj_refresh_ui()

func _on_bj_play_again() -> void:
	if GameState.stash < BlackjackManager.BET:
		bj_status_lbl.text = "⚠️ 残高不足（¥%s 必要）" % _fmt(BlackjackManager.BET)
		return
	GameState.stash -= BlackjackManager.BET
	_update_stash_display()
	BlackjackManager.start_game()
	_bj_refresh_ui()

func _bj_refresh_ui() -> void:
	var bj := BlackjackManager
	var is_result: bool = bj.state == BlackjackManager.State.RESULT

	# カードを再構築
	_bj_build_cards(bj_dealer_card_row, bj.dealer_hand, not bj.dealer_revealed)
	_bj_build_cards(bj_player_card_row, bj.player_hand, false)

	# スコア表示
	if bj.dealer_revealed:
		bj_dealer_score.text = "スコア: %s" % bj.score_display(bj.dealer_hand)
	else:
		# 裏カードがある間は表のカードのスコアのみ
		var visible_hand := [bj.dealer_hand[0]] if bj.dealer_hand.size() > 0 else []
		bj_dealer_score.text = "スコア: %s + ？" % bj.score_display(visible_hand)

	bj_player_score.text = "スコア: %s" % bj.score_display(bj.player_hand)

	# アクションボタン
	bj_hit_btn.visible   = not is_result
	bj_stand_btn.visible = not is_result
	bj_again_btn.visible = is_result

	# 結果表示
	bj_result_area.visible = is_result
	if is_result:
		bj_result_lbl.text = bj.result_label()
		bj_payout_lbl.text = bj.payout_label()
		# 配当をスタッシュへ
		if bj.payout > 0:
			GameState.stash += bj.payout
		_update_stash_display()
		bj.payout = 0   # 二重加算防止
		# 結果色
		match bj.result:
			"blackjack":
				bj_result_lbl.add_theme_color_override("font_color", Color("#ffd700"))
			"win":
				bj_result_lbl.add_theme_color_override("font_color", Color("#44ff88"))
			"push":
				bj_result_lbl.add_theme_color_override("font_color", Color("#aaaaaa"))
			"lose":
				bj_result_lbl.add_theme_color_override("font_color", Color("#ff4444"))
		bj_status_lbl.text = "もう一度遊ぶか閉じてください"
	else:
		bj_status_lbl.text = "ヒット: カードを引く  ／  スタンド: このまま勝負"

func _bj_build_cards(row: HBoxContainer, hand: Array, hide_second: bool) -> void:
	# 既存カードをクリア
	for c in row.get_children():
		c.queue_free()
	# カードを追加
	for i in hand.size():
		var card_node := CardNodeScene.new()
		var is_down: bool = (hide_second and i == 1)
		row.add_child(card_node)
		if is_down:
			card_node.setup({}, true)
		else:
			card_node.setup(hand[i], false)

# ═══════════════════════════════════════════════
# ── ポーカー ────────────────────────────────────
# ═══════════════════════════════════════════════
func _on_poker_btn_pressed() -> void:
	if GameState.stash < PokerManager.BET:
		return
	GameState.stash -= PokerManager.BET
	_update_stash_display()
	PokerManager.start_game()
	_poker_refresh_ui()
	poker_overlay.show()

func _on_poker_close() -> void:
	poker_overlay.hide()

func _on_poker_check() -> void:
	var pm := PokerManager
	if pm.phase == PokerManager.Phase.BET1:
		pm.bet1_check()
	elif pm.phase == PokerManager.Phase.BET2:
		pm.bet2_check()
	_poker_refresh_ui()

func _on_poker_raise() -> void:
	var pm := PokerManager
	if GameState.stash < PokerManager.RAISE_AMT:
		poker_status_lbl.text = "⚠️ 残高不足でレイズできません"
		return
	GameState.stash -= PokerManager.RAISE_AMT
	_update_stash_display()
	if pm.phase == PokerManager.Phase.BET1:
		pm.bet1_raise()
	elif pm.phase == PokerManager.Phase.BET2:
		pm.bet2_raise()
	_poker_refresh_ui()

func _on_poker_fold() -> void:
	PokerManager.bet2_fold()
	_poker_refresh_ui()

func _on_poker_draw() -> void:
	PokerManager.execute_draw()
	_poker_refresh_ui()

func _on_poker_play_again() -> void:
	if GameState.stash < PokerManager.BET:
		poker_status_lbl.text = "⚠️ 残高不足（¥%s 必要）" % _fmt(PokerManager.BET)
		return
	GameState.stash -= PokerManager.BET
	_update_stash_display()
	PokerManager.start_game()
	_poker_refresh_ui()

func _poker_refresh_ui() -> void:
	var pm      := PokerManager
	var phase   := pm.phase
	var is_show: bool = phase == PokerManager.Phase.SHOWDOWN

	# ポット表示
	poker_pot_lbl.text = "ポット: ¥%s" % _fmt(pm.pot)

	# ディーラー手札：ショーダウン前は全て伏せ
	_poker_build_cards(poker_dealer_row, pm.dealer_hand, not is_show, -1)
	poker_dealer_rank.text = pm.dealer_rank_name if is_show else "（伏せ中）"

	# プレイヤー手札：常に表向き、DRAWフェーズは選択ハイライト
	var draw_mode: bool = phase == PokerManager.Phase.DRAW
	_poker_build_cards(poker_player_row, pm.player_hand, false, -1 if not draw_mode else 0)
	poker_player_rank.text = pm.player_rank_name if is_show else ""

	# ドローフェーズのヒント
	if draw_mode:
		var sel := pm.selected_idx
		poker_draw_hint.text = "捨てるカードをクリックして選択（選択済%d枚）→「カードを交換」" % sel.size()
	else:
		poker_draw_hint.text = ""

	# アクションボタン切り替え
	var in_bet1: bool = phase == PokerManager.Phase.BET1
	var in_bet2: bool = phase == PokerManager.Phase.BET2
	poker_check_btn.visible  = in_bet1 or in_bet2
	poker_raise_btn.visible  = in_bet1 or in_bet2
	poker_fold_btn.visible   = in_bet2
	poker_draw_btn.visible   = draw_mode
	poker_again_btn.visible  = is_show

	# ラベル調整
	if in_bet1:
		poker_check_btn.text = "✔ チェック（そのまま）"
		poker_raise_btn.text = "↑ レイズ（+¥%s）" % _fmt(PokerManager.RAISE_AMT)
	elif in_bet2:
		poker_check_btn.text = "✔ チェック / コール"
		poker_raise_btn.text = "↑ レイズ（+¥%s）" % _fmt(PokerManager.RAISE_AMT)

	# 結果
	poker_result_area.visible = is_show
	if is_show:
		poker_result_lbl.text  = pm.result_label()
		poker_payout_lbl.text  = pm.payout_label()
		if pm.payout > 0:
			GameState.stash += pm.payout
			_update_stash_display()
		pm.payout = 0   # 二重加算防止
		match pm.result:
			"win":
				poker_result_lbl.add_theme_color_override("font_color", Color("#44ff88"))
			"push":
				poker_result_lbl.add_theme_color_override("font_color", Color("#aaaaaa"))
			"lose":
				poker_result_lbl.add_theme_color_override("font_color", Color("#ff4444"))
		poker_status_lbl.text = "ディーラー: %s　あなた: %s" % [pm.dealer_rank_name, pm.player_rank_name]
	else:
		_poker_set_phase_status(phase)

func _poker_set_phase_status(phase: int) -> void:
	match phase:
		PokerManager.Phase.BET1:
			poker_status_lbl.text = "【1回目のベット】 チェックかレイズを選んでください"
		PokerManager.Phase.DRAW:
			poker_status_lbl.text = "【カード交換】 捨てるカードを選んで「カードを交換」を押してください（0枚でもOK）"
		PokerManager.Phase.BET2:
			poker_status_lbl.text = "【2回目のベット】 チェック・レイズ・フォールドを選んでください"

func _poker_build_cards(row: HBoxContainer, hand: Array, all_down: bool, _draw_mode_flag: int) -> void:
	# 既存カードノードを削除
	for c in row.get_children():
		c.queue_free()

	var pm := PokerManager
	var draw_mode: bool = pm.phase == PokerManager.Phase.DRAW and not all_down

	for i in hand.size():
		var card_node := CardNodeScene.new()
		row.add_child(card_node)
		if all_down:
			card_node.setup({}, true)
		else:
			card_node.setup(hand[i], false)

		# DRAWフェーズ：選択済みカードに赤枠+暗転、クリックで選択トグル
		if draw_mode:
			var is_sel: bool = i in pm.selected_idx
			card_node.set_selected(is_sel)
			var idx := i
			card_node.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					PokerManager.toggle_discard(idx)
					_poker_refresh_ui()
			)
