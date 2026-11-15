extends RefCounted
# Lo-Fi League season: schedule, results, table and simulated matches. Pure data, no nodes.
# A season lives in the save file under "league":
#   {v, season, club, seed, fixtures: [round: [[home id, away id], ...]], results: [round: [[home, away, home goals, away goals], ...]], md}
# md is the next matchday to play, counted from 0. The season is over when md equals the number of rounds.

static func new_season(clubs: Array, club: String, season: int, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = seed_v
	var ids: Array = clubs.duplicate()
	for i in range(ids.size() - 1, 0, -1):   # shuffle so each season has its own order
		var j := rng.randi_range(0, i)
		var t = ids[i]; ids[i] = ids[j]; ids[j] = t
	var n := ids.size()
	var rounds := []
	var rot: Array = ids.duplicate()
	for r in n - 1:
		var games := []
		for k in n / 2:
			var a = rot[k]; var b = rot[n - 1 - k]
			if (r + k) % 2 == 1: games.append([b, a])
			else: games.append([a, b])
		rounds.append(games)
		var last = rot.pop_back(); rot.insert(1, last)   # circle method: keep the first, turn the rest
	return {"v": 1, "season": season, "club": club, "seed": seed_v, "fixtures": rounds, "results": [], "md": 0}

static func rounds(lg: Dictionary) -> int:
	return (lg.get("fixtures", []) as Array).size()

static func is_over(lg: Dictionary) -> bool:
	return not lg.is_empty() and int(lg.md) >= rounds(lg)

static func user_fixture(lg: Dictionary) -> Array:
	if lg.is_empty() or is_over(lg): return []
	for f in lg.fixtures[int(lg.md)]:
		if f[0] == lg.club or f[1] == lg.club: return f
	return []

static func strength(team: Dictionary) -> float:
	var s := 0.0
	for p in team.players:
		s += (float(p.speed) + float(p["pass"]) + float(p.shot) + float(p.tackle) + float(p.control)) / 5.0
	return s / maxf(1.0, float(team.players.size()))

static func _poisson(rng: RandomNumberGenerator, lam: float) -> int:
	var l := exp(-lam); var k := 0; var p := 1.0
	while true:
		p *= rng.randf()
		if p <= l: break
		k += 1
	return mini(k, 9)

static func sim_score(rng: RandomNumberGenerator, a: Dictionary, b: Dictionary, base: float) -> Array:
	var d := (strength(a) - strength(b)) / 18.0
	return [_poisson(rng, base * exp(d)), _poisson(rng, base * exp(-d))]

# Records one matchday. user_goals is [goals for the player's club, goals against] or [] to simulate every match.
static func play_round(lg: Dictionary, user_goals: Array, by_id: Dictionary, base: float) -> Array:
	var md := int(lg.md)
	var rng := RandomNumberGenerator.new(); rng.seed = int(lg.seed) + 7919 * (md + 1)
	var out := []
	for f in lg.fixtures[md]:
		var r: Array
		if not user_goals.is_empty() and f[0] == lg.club: r = [f[0], f[1], user_goals[0], user_goals[1]]
		elif not user_goals.is_empty() and f[1] == lg.club: r = [f[0], f[1], user_goals[1], user_goals[0]]
		else:
			var g := sim_score(rng, by_id[f[0]], by_id[f[1]], base)
			r = [f[0], f[1], g[0], g[1]]
		out.append(r)
	lg.results.append(out); lg.md = md + 1
	return out

static func table(lg: Dictionary, clubs: Array, by_id: Dictionary, win_pts: int, draw_pts: int) -> Array:
	var rows := {}
	for c in clubs: rows[c] = {"id": c, "name": str(by_id[c].name), "p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "gd": 0, "pts": 0}
	for rnd in lg.get("results", []):
		for r in rnd:
			var a: Dictionary = rows[r[0]]; var b: Dictionary = rows[r[1]]
			var ga := int(r[2]); var gb := int(r[3])
			a.p += 1; b.p += 1; a.gf += ga; a.ga += gb; b.gf += gb; b.ga += ga
			if ga > gb:
				a.w += 1; b.l += 1; a.pts += win_pts
			elif ga < gb:
				b.w += 1; a.l += 1; b.pts += win_pts
			else:
				a.d += 1; b.d += 1; a.pts += draw_pts; b.pts += draw_pts
	var out := rows.values()
	for r in out: r.gd = r.gf - r.ga
	out.sort_custom(func(x, y):
		if x.pts != y.pts: return x.pts > y.pts
		if x.gd != y.gd: return x.gd > y.gd
		if x.gf != y.gf: return x.gf > y.gf
		return x.name < y.name)
	return out

static func position(rows: Array, club: String) -> int:
	for i in rows.size():
		if rows[i].id == club: return i + 1
	return 0

static func ordinal(n: int) -> String:
	var suf := "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suf = "st"
			2: suf = "nd"
			3: suf = "rd"
	return "%d%s" % [n, suf]
