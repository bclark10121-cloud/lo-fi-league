#!/usr/bin/env python3
# Writes data/teams.json: 6 fictional clubs with kits, a team style and 7 players each. Edit the JSON by hand after this, or change the lists here and run again.
import json, os, random
random.seed(14)
CLUBS = [
 ("tapedeck", "Tape Deck Rovers", "TDR", "2-3-1", ("e07a5f", "f4f1de", "3d405b", "e07a5f"), ("f4f1de", "e07a5f", "e07a5f", "f4f1de"), (60, 50, 50, 50)),
 ("vinyl", "Midnight Vinyl FC", "MVF", "2-2-2", ("2b2d42", "ef8fa3", "2b2d42", "ef8fa3"), ("ef8fa3", "2b2d42", "f4f1de", "2b2d42"), (45, 65, 45, 60)),
 ("rainy", "Rainy Window United", "RWU", "3-2-1", ("7fb7be", "f4f1de", "f4f1de", "7fb7be"), ("355070", "7fb7be", "355070", "f4f1de"), (65, 40, 65, 40)),
 ("static", "Sunday Static", "SUN", "1-3-2", ("f2cc8f", "6d597a", "6d597a", "f2cc8f"), ("6d597a", "f2cc8f", "f2cc8f", "6d597a"), (50, 60, 40, 65)),
 ("cassette", "Cassette City", "CAS", "2-3-1", ("b5838d", "ffe5d9", "ffe5d9", "b5838d"), ("ffe5d9", "b5838d", "b5838d", "ffe5d9"), (55, 55, 55, 50)),
 ("slowfade", "Slow Fade Athletic", "SFA", "2-2-2", ("81b29a", "264653", "264653", "81b29a"), ("264653", "81b29a", "81b29a", "264653"), (70, 45, 50, 45)),
]
KEEPER = [("9c89b8", "f4f1de", "9c89b8", "9c89b8"), ("f6bd60", "3d405b", "f6bd60", "f6bd60")]
NAMES = "Milo Remy Theo Kai Jonah Ezra Luca Nico Omar Felix Arlo Dante Hugo Idris Jude Koji Levi Mateo Noel Otis Pablo Quinn Rafa Soren Tariq Uri Vik Wes Yusuf Zane Anders Bram Cyrus Dev Emil Finn Gus Hari Ivo Jai Kofi Lars".split()
SKIN = ["f2c49c", "e3b08a", "c98f67", "a86f4b", "7a4f33", "5a3a26"]
HAIR = ["2b2118", "4a3524", "7a5230", "c9a25a", "1b1b1f", "8c3b2a", "d8d2c4"]
POS = ["GK", "DF", "DF", "MF", "MF", "MF", "FW"]
NUMS = [1, 2, 4, 6, 8, 10, 9]
def kit(k): return {"shirt": k[0], "trim": k[1], "shorts": k[2], "socks": k[3]}
def r(base): return max(30, min(80, int(random.gauss(base, 7))))
out = []; n = 0
for i, (cid, name, abbr, form, home, away, style) in enumerate(CLUBS):
    ps = []
    for j in range(7):
        pos = POS[j]
        b = {"GK": (45, 50, 35, 45, 60), "DF": (50, 50, 40, 62, 50), "MF": (52, 60, 50, 50, 56), "FW": (58, 50, 62, 40, 55)}[pos]
        ps.append({"name": NAMES[n], "num": NUMS[j], "pos": pos, "speed": r(b[0]), "pass": r(b[1]), "shot": r(b[2]), "tackle": r(b[3]), "control": r(b[4]), "skin": random.choice(SKIN), "hair": random.choice(HAIR)}); n += 1
    out.append({"id": cid, "name": name, "abbr": abbr, "formation": form, "home": kit(home), "away": kit(away), "keeper": kit(KEEPER[i % 2]),
                "style": {"pass": style[0], "shoot": style[1], "tackle": style[2], "run": style[3]}, "players": ps})
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "teams.json")
with open(p, "w") as f:
    f.write("[\n")
    for i, t in enumerate(out):
        ps = t.pop("players")
        head = json.dumps(t)[:-1]
        f.write("  " + head + ', "players": [\n')
        f.write(",\n".join("    " + json.dumps(x) for x in ps))
        f.write("\n  ]}" + ("," if i < len(out) - 1 else "") + "\n")
    f.write("]\n")
print("wrote", p)
