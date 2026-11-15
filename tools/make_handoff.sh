#!/bin/bash
# Builds the game standards handoff zip from this repo (G2.5, G9). Run from the repo root: tools/make_handoff.sh [output folder]
# Holds both standards files, this game's override file, the templates, the reusable code and this game's rules for reference.
# Never include a signing key or password. Never edit a standards file here: the master lives in the standards repo (G0.10).
set -e
OUT="${1:-..}"
S=$(mktemp -d)
D="$S/Game_Standards_handoff"
mkdir -p "$D/templates/godot" "$D/templates/game-page" "$D/reusable" "$D/games/lo-fi-league"
cp handoff/GAME_STANDARDS.md "$D/"
if [ -f handoff/ENGINEERING_STANDARDS.md ]; then cp handoff/ENGINEERING_STANDARDS.md "$D/"; else echo "note: handoff/ENGINEERING_STANDARDS.md not in this repo yet"; fi
cp -r handoff/templates/. "$D/templates/" 2>/dev/null || true
cp project.godot export_presets.cfg .gitignore "$D/templates/godot/"
cp docs/index.html "$D/templates/game-page/index.html"
cp scripts/hud.gd "$D/reusable/hud_soccer.gd"
cp tests/web_test.py "$D/reusable/web_test_states.py"
cp tools/make_sfx.py "$D/reusable/make_sfx_stadium.py"
cp tools/patch_assets.py tools/make_handoff.sh "$D/reusable/"
cp CLAUDE.md STANDARDS_OVERRIDES.md BACKLOG.md README.md CREDITS.md data/teams.json data/formations.json "$D/games/lo-fi-league/"
cp docs/release-notes/*.md "$D/games/lo-fi-league/" 2>/dev/null || true
cp -r handoff/games/. "$D/games/" 2>/dev/null || true
(cd "$S" && zip -qr handoff.zip Game_Standards_handoff)
cp "$S/handoff.zip" "$OUT/Game_Standards_handoff.zip"
echo "built $OUT/Game_Standards_handoff.zip"
