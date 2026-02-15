# CardNode.gd
# トランプ1枚を描画するControlノード。
extends Control

var card: Dictionary = {}   # {rank, suit} or {} for face-down
var face_down := false
var selected  := false   # ポーカーDRAW選択状態

const W := 72
const H := 100
const CORNER_R := 7.0

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(c: Dictionary, down := false) -> void:
	card      = c
	face_down = down
	selected  = false
	queue_redraw()

func reveal() -> void:
	face_down = false
	queue_redraw()

func set_selected(s: bool) -> void:
	selected = s
	queue_redraw()

func _draw() -> void:
	var rect  := Rect2(0, 0, W, H)
	var font  := ThemeDB.fallback_font
	var font_sz_rank := 20
	var font_sz_suit := 14

	if face_down:
		# 裏面：濃い青のパターン
		draw_rect(rect, Color(0.12, 0.22, 0.55, 1.0), true, -1, true)
		draw_rect(Rect2(4, 4, W - 8, H - 8), Color(0.18, 0.32, 0.70, 1.0), false, 1.5, true)
		# ハッチング柄
		for i in range(8, H - 8, 10):
			draw_line(Vector2(4, i), Vector2(W - 4, i), Color(0.25, 0.42, 0.80, 0.4), 1)
		for i in range(8, W - 8, 10):
			draw_line(Vector2(i, 4), Vector2(i, H - 4), Color(0.25, 0.42, 0.80, 0.4), 1)
		draw_rect(rect, Color(0.08, 0.15, 0.40, 1.0), false, 2.0, true)
		return

	if card.is_empty():
		return

	var is_red: bool = BlackjackManager.SUIT_COLORS.get(card["suit"], false)
	var face_col := Color(1, 1, 1)
	var text_col := Color(0.88, 0.12, 0.12) if is_red else Color(0.08, 0.08, 0.08)

	# 白カード背景
	draw_rect(rect, face_col, true, -1, true)
	draw_rect(rect, Color(0.75, 0.75, 0.78), false, 1.5, true)

	# 左上ランク+スート
	var rank_str: String = card["rank"]
	var suit_str: String = card["suit"]

	var r_size := font.get_string_size(rank_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz_rank)
	draw_string(font, Vector2(5, 5 + r_size.y * 0.85), rank_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz_rank, text_col)
	var s_size := font.get_string_size(suit_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz_suit)
	draw_string(font, Vector2(5, 5 + r_size.y + s_size.y * 0.9), suit_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz_suit, text_col)

	# 中央の大きいスート
	var big_sz := 34
	var big_size := font.get_string_size(suit_str, HORIZONTAL_ALIGNMENT_LEFT, -1, big_sz)
	var cx := (W - big_size.x) / 2
	var cy := (H - big_size.y) / 2 + big_size.y * 0.85
	draw_string(font, Vector2(cx, cy), suit_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, big_sz, text_col)

	# 右下（逆さ）ランク+スート
	var rank_size2 := font.get_string_size(rank_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz_rank)
	draw_string(font, Vector2(W - 5 - rank_size2.x, H - 5), rank_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz_rank, text_col)

	# 選択中：赤い半透明オーバーレイ+枠
	if selected:
		draw_rect(rect, Color(1, 0.1, 0.1, 0.35), true, -1, true)
		draw_rect(rect, Color(1, 0.1, 0.1, 0.9), false, 3.0, true)
		var discard_font_size := 16
		var label := "捨"
		var lsize := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, discard_font_size)
		draw_string(font, Vector2((W - lsize.x)/2, (H + lsize.y)/2),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, discard_font_size, Color(1, 0.2, 0.2, 1))
