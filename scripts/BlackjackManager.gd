# BlackjackManager.gd
# ブラックジャックのゲームロジック。UIを持たない純粋なロジック層。
extends Node

const BET := 50000

# ── カード定義 ────────────────────────────
const SUITS  := ["♠", "♥", "♦", "♣"]
const RANKS  := ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
const SUIT_COLORS := {"♠": false, "♥": true, "♦": true, "♣": false}  # true=red

# ゲーム状態
enum State { IDLE, PLAYER_TURN, DEALER_TURN, RESULT }
var state := State.IDLE

var deck: Array         = []
var player_hand: Array  = []   # [{rank, suit}]
var dealer_hand: Array  = []
var dealer_revealed := false   # ディーラーの裏カードを公開したか

var result := ""   # "win" / "lose" / "push" / "blackjack"
var payout := 0    # 実際に受け取る額（bet分含む）

# ── ゲーム開始 ────────────────────────────
func start_game() -> void:
	deck         = _build_shuffled_deck()
	player_hand  = []
	dealer_hand  = []
	dealer_revealed = false
	result       = ""
	payout       = 0
	state        = State.PLAYER_TURN

	# 2枚ずつ配る（交互に）
	player_hand.append(_draw())
	dealer_hand.append(_draw())
	player_hand.append(_draw())
	dealer_hand.append(_draw())

	# プレイヤーがブラックジャックなら即結果へ
	if _is_blackjack(player_hand):
		_resolve()

# ── プレイヤーアクション ─────────────────
func hit() -> void:
	if state != State.PLAYER_TURN:
		return
	player_hand.append(_draw())
	if _best_score(player_hand) >= 22:
		_resolve()   # バースト

func stand() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.DEALER_TURN
	dealer_revealed = true
	_dealer_draw()
	_resolve()

# ── ディーラードロー ─────────────────────
func _dealer_draw() -> void:
	# ディーラーは17以上でスタンド
	while _best_score(dealer_hand) < 17:
		dealer_hand.append(_draw())

# ── 勝敗判定 ──────────────────────────────
func _resolve() -> void:
	dealer_revealed = true
	state           = State.RESULT
	var p_score := _best_score(player_hand)
	var d_score := _best_score(dealer_hand)
	var p_bj    := _is_blackjack(player_hand)
	var d_bj    := _is_blackjack(dealer_hand)

	if p_score >= 22:
		result = "lose"
		payout = 0
	elif p_bj and d_bj:
		result = "push"
		payout = BET           # 掛け金返却
	elif p_bj:
		result = "blackjack"
		payout = BET + int(BET * 1.5)   # 1.5倍配当（元本含め2.5倍受取）
	elif d_bj:
		result = "lose"
		payout = 0
	elif d_score >= 22:
		result = "win"
		payout = BET * 2
	elif p_score > d_score:
		result = "win"
		payout = BET * 2
	elif p_score == d_score:
		result = "push"
		payout = BET
	else:
		result = "lose"
		payout = 0

# ── スコア計算 ────────────────────────────
func _best_score(hand: Array) -> int:
	var total := 0
	var aces  := 0
	for card: Dictionary in hand:
		var v := _rank_value(card["rank"])
		if v == 11:
			aces += 1
		total += v
	while total > 21 and aces > 0:
		total -= 10
		aces  -= 1
	return total

func _rank_value(rank: String) -> int:
	match rank:
		"A":         return 11
		"J","Q","K": return 10
		_:           return int(rank)

func _is_blackjack(hand: Array) -> bool:
	if hand.size() != 2:
		return false
	return _best_score(hand) == 21

# ── デッキ ────────────────────────────────
func _build_shuffled_deck() -> Array:
	var d: Array = []
	for suit in SUITS:
		for rank in RANKS:
			d.append({"rank": rank, "suit": suit})
	d.shuffle()
	return d

func _draw() -> Dictionary:
	if deck.is_empty():
		deck = _build_shuffled_deck()
	return deck.pop_back()

# ── ユーティリティ ─────────────────────────
func score_display(hand: Array) -> String:
	var s := _best_score(hand)
	return "%d" % s

func result_label() -> String:
	match result:
		"blackjack": return "🎉 ブラックジャック！"
		"win":        return "✅ 勝利！"
		"push":       return "🤝 引き分け（プッシュ）"
		"lose":       return "💀 負け…"
	return ""

func payout_label() -> String:
	match result:
		"blackjack": return "+¥%s（1.5倍配当）" % _fmt(payout - BET)
		"win":        return "+¥%s" % _fmt(payout - BET)
		"push":       return "±¥0（掛け金返却）"
		"lose":       return "-¥%s" % _fmt(BET)
	return ""

func _fmt(n: int) -> String:
	var s := str(abs(n))
	var r := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		if c > 0 and c % 3 == 0:
			r = "," + r
		r = s[i] + r
		c += 1
	return r
