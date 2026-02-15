# PokerManager.gd
# 5カードドローポーカーのゲームロジック。
extends Node

const BET       := 50000   # 参加費
const RAISE_AMT := 25000   # ベット/レイズ額
const SUITS  := ["♠", "♥", "♦", "♣"]
const RANKS  := ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
const SUIT_COLORS := {"♠": false, "♥": true, "♦": true, "♣": false}

enum Phase { IDLE, BET1, DRAW, BET2, SHOWDOWN }
var phase := Phase.IDLE

var deck:          Array = []
var player_hand:   Array = []   # [{rank,suit}] x5
var dealer_hand:   Array = []
var selected_idx:  Array = []   # プレイヤーが捨てるカードのインデックス

# ベット管理
var pot         := 0      # 総ポット
var player_bet  := 0      # プレイヤーの掛け金累計
var dealer_bet  := 0      # ディーラーの掛け金累計
var cur_bet     := 0      # 現在のベット水準

# 結果
var player_rank_name := ""
var dealer_rank_name := ""
var result := ""   # "win" / "lose" / "push"
var payout := 0

# ── ゲーム開始 ────────────────────────────
func start_game() -> void:
	deck         = _build_shuffled_deck()
	player_hand  = []
	dealer_hand  = []
	selected_idx = []
	pot          = BET * 2   # 双方アンティ
	player_bet   = BET
	dealer_bet   = BET
	cur_bet      = BET
	result       = ""
	payout       = 0
	player_rank_name = ""
	dealer_rank_name = ""

	for _i in 5:
		player_hand.append(_draw())
	for _i in 5:
		dealer_hand.append(_draw())

	phase = Phase.BET1

# ── フェーズ1ベット ──────────────────────
# check: そのまま次へ
func bet1_check() -> void:
	if phase != Phase.BET1: return
	# ディーラーも必ずチェック（シンプル化）
	phase = Phase.DRAW

func bet1_raise() -> bool:
	if phase != Phase.BET1: return false
	# プレイヤーがレイズ→ディーラーは必ずコール
	pot         += RAISE_AMT * 2
	player_bet  += RAISE_AMT
	dealer_bet  += RAISE_AMT
	cur_bet     += RAISE_AMT
	phase        = Phase.DRAW
	return true   # コール成功

# ── カード交換（DRAW） ────────────────────
func toggle_discard(idx: int) -> void:
	if phase != Phase.DRAW: return
	if idx in selected_idx:
		selected_idx.erase(idx)
	else:
		selected_idx.append(idx)

func execute_draw() -> void:
	if phase != Phase.DRAW: return
	# プレイヤーのカード交換
	for idx: int in selected_idx:
		player_hand[idx] = _draw()
	selected_idx = []

	# ディーラーのカード交換（簡易AI：役がなければ最大3枚交換）
	_dealer_draw_ai()

	phase = Phase.BET2

func _dealer_draw_ai() -> void:
	var score: int = int(_hand_rank(dealer_hand)["rank"])
	# ハイカード以下なら3枚交換、ワンペアなら3枚、ツーペアなら1枚、それ以上はスタンド
	var discard_count := 0
	match score:
		0: discard_count = 3   # ハイカード
		1: discard_count = 3   # ワンペア
		2: discard_count = 1   # ツーペア
		_: discard_count = 0   # スリーオブアカインド以上

	if discard_count > 0:
		# 低いカードから捨てる
		var sorted_indices: Array = [0, 1, 2, 3, 4]
		sorted_indices.sort_custom(func(a: int, b: int) -> bool: return _rank_num(dealer_hand[a]["rank"]) < _rank_num(dealer_hand[b]["rank"]))
		for i in discard_count:
			dealer_hand[sorted_indices[i]] = _draw()

# ── フェーズ2ベット ──────────────────────
func bet2_check() -> void:
	if phase != Phase.BET2: return
	phase = Phase.SHOWDOWN
	_resolve()

func bet2_raise() -> bool:
	if phase != Phase.BET2: return false
	pot        += RAISE_AMT * 2
	player_bet += RAISE_AMT
	dealer_bet += RAISE_AMT
	phase       = Phase.SHOWDOWN
	_resolve()
	return true

func bet2_fold() -> void:
	if phase != Phase.BET2: return
	result  = "lose"
	payout  = 0
	player_rank_name = "フォールド"
	dealer_rank_name = ""
	phase   = Phase.SHOWDOWN

# ── ショーダウン判定 ──────────────────────
func _resolve() -> void:
	var pr := _hand_rank(player_hand)
	var dr := _hand_rank(dealer_hand)
	player_rank_name = pr["name"]
	dealer_rank_name = dr["name"]

	var cmp: int = _compare_hands(pr, dr)
	if cmp > 0:
		result = "win"
		payout = pot
	elif cmp < 0:
		result = "lose"
		payout = 0
	else:
		result = "push"
		payout = player_bet   # 自分の掛け金だけ返却

# ── 役判定 ────────────────────────────────
# rank: 0=HighCard 1=OnePair 2=TwoPair 3=ThreeOfAKind 4=Straight
#       5=Flush 6=FullHouse 7=FourOfAKind 8=StraightFlush 9=RoyalFlush
func _hand_rank(hand: Array) -> Dictionary:
	var nums:    Array = hand.map(func(c: Dictionary) -> int: return _rank_num(c["rank"]))
	var suits_h: Array = hand.map(func(c: Dictionary) -> String: return c["suit"])
	nums.sort()
	nums.reverse()

	var is_flush:    bool = suits_h.count(suits_h[0]) == 5
	var is_straight: bool = _is_straight(nums)
	var counts: Dictionary = _count_ranks(nums)
	var freq:   Array      = counts.values()
	freq.sort()
	freq.reverse()

	# ロイヤルフラッシュ
	if is_flush and is_straight and nums[0] == 14:
		return {"rank": 9, "name": "ロイヤルフラッシュ", "tiebreak": nums}
	# ストレートフラッシュ
	if is_flush and is_straight:
		return {"rank": 8, "name": "ストレートフラッシュ", "tiebreak": nums}
	# フォーカード
	if freq[0] == 4:
		return {"rank": 7, "name": "フォー・オブ・ア・カインド", "tiebreak": _sort_by_freq(counts)}
	# フルハウス
	if freq[0] == 3 and freq[1] == 2:
		return {"rank": 6, "name": "フルハウス", "tiebreak": _sort_by_freq(counts)}
	# フラッシュ
	if is_flush:
		return {"rank": 5, "name": "フラッシュ", "tiebreak": nums}
	# ストレート
	if is_straight:
		return {"rank": 4, "name": "ストレート", "tiebreak": nums}
	# スリーカード
	if freq[0] == 3:
		return {"rank": 3, "name": "スリー・オブ・ア・カインド", "tiebreak": _sort_by_freq(counts)}
	# ツーペア
	if freq[0] == 2 and freq[1] == 2:
		return {"rank": 2, "name": "ツーペア", "tiebreak": _sort_by_freq(counts)}
	# ワンペア
	if freq[0] == 2:
		return {"rank": 1, "name": "ワンペア", "tiebreak": _sort_by_freq(counts)}
	# ハイカード
	return {"rank": 0, "name": "ハイカード", "tiebreak": nums}

func _compare_hands(a: Dictionary, b: Dictionary) -> int:
	if a["rank"] != b["rank"]:
		return 1 if a["rank"] > b["rank"] else -1
	var ta: Array = a["tiebreak"]
	var tb: Array = b["tiebreak"]
	for i in min(ta.size(), tb.size()):
		if ta[i] != tb[i]:
			return 1 if ta[i] > tb[i] else -1
	return 0

func _is_straight(sorted_nums: Array) -> bool:
	# A-2-3-4-5 ローストレート対応
	var low_straight := [14, 5, 4, 3, 2]
	if sorted_nums == low_straight:
		return true
	for i in 4:
		if sorted_nums[i] - sorted_nums[i+1] != 1:
			return false
	return true

func _count_ranks(nums: Array) -> Dictionary:
	var d: Dictionary = {}
	for n: int in nums:
		d[n] = d.get(n, 0) + 1
	return d

func _sort_by_freq(counts: Dictionary) -> Array:
	var pairs := []
	for k in counts:
		pairs.append([k, counts[k]])
	pairs.sort_custom(func(a,b): return a[1] > b[1] or (a[1] == b[1] and a[0] > b[0]))
	var result_arr: Array = []
	for p in pairs:
		for _i in p[1]:
			result_arr.append(p[0])
	return result_arr

func _rank_num(rank: String) -> int:
	match rank:
		"A": return 14
		"K": return 13
		"Q": return 12
		"J": return 11
		_:   return int(rank)

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

# ── 配当計算 ──────────────────────────────
# 勝利時: ポット全額獲得
func payout_label() -> String:
	match result:
		"win":
			var profit := payout - player_bet
			return "+¥%s（%s）" % [_fmt(profit), player_rank_name]
		"push":
			return "±¥0（引き分け）"
		"lose":
			var loss := player_bet
			return "-¥%s" % _fmt(loss)
	return ""

func result_label() -> String:
	match result:
		"win":  return "🏆 勝利！"
		"push": return "🤝 引き分け"
		"lose": return "💀 負け…"
	return ""

# ── ユーティリティ ─────────────────────────
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
