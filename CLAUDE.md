# Lo-Fi League: project rules

Lo-Fi League is Brian's laid-back 7 a side soccer game. Godot 4.6, Android and browser. This repo is public.
## Standards (G0.10, G10)

- Read `GAME_STANDARDS.md` (rule ids start with G) and `ENGINEERING_STANDARDS.md` (rule ids start with E) first. Both live only in the private repo `bclark10121-cloud/game-standards`. Clone it to `../game-standards`, outside this repo. This repo holds no copies.
- Overrides, open items and the standards version this game was checked against live in `STANDARDS_OVERRIDES.md`. Order of authority: Brian in the chat, then `STANDARDS_OVERRIDES.md`, then the standards.
- The shared kit is pulled into `addons/bc_common/`, `tools/common/` and `tests/common/` with `bash ../game-standards/common/sync_common.sh ../game-standards .`. `common.lock` names the version. Never edit those files here. Propose kit changes to Brian.
- Never edit a standards file. Propose the change to Brian. The master changes first.

## Pillars (never break these)

Confirmed by Brian 2026-11-14 (G4.2).

1. Pick up and play. Move, pass, shoot, tackle. A match takes about 6 minutes.
2. Laid-back mood. Lo-fi music, soft colors, friendly tackles, no injuries, no red cards.
3. Soccer rules people know: goals, throw-ins, corners, goal kicks, kickoffs and halves.
4. Original everything. Fictional clubs, our own formations, art and names. Nothing from Pixel Cup Soccer or any other game.

This game has an opponent and a final score. Override rows for G4.1 and G4.4 in `STANDARDS_OVERRIDES.md` (agreed 2026-11-14: these rules do not apply to sports games).

## Rules

- This repo is public. Never commit a signing key, keystore or password. Never write a password in a build file, a doc or a reply (G1.9). The key and its settings live in the private repo `game-signing`, cloned to `../game-signing`.
- Pitch units are yards. The pitch runs along X. Goal lines sit at x = -30 and x = +30. Sidelines sit at z = -20 and z = +20.
- Side 0 (the player) always attacks +X, the right of the screen. The camera sits on the +Z sideline. Teams do not switch ends.
- Players and the ball move with plain maths, not physics bodies. `main.gd` sets `want` and each player eases toward it.
- Pitch lines are painted into one ground texture (G6.5). Never lay a thin layer on the grass.
- Clubs live in `data/teams.json` and formations in `data/formations.json`. New clubs need no code. `tools/make_teams.py` wrote the eight clubs.
- The league lives in `data/league.json` (clubs, points, simulated goals). `scripts/league.gd` holds the schedule, table and simulated matches as plain data.
- A season is saved under `league` in the save file. Quitting a league match never records it.
- Save file is `user://lofi_league.json`, format `v: 1`, written with the shared `addons/bc_common/save_store.gd`. Only add fields, each with a safe default. The kit keeps the last good save as `lofi_league.json.bak`, clamps the counters to `store.limits` and never loads a save with a higher `v` (E6.7). Delete a save only with `store.erase()`. v0.2.0 added `league`, `seasons`, `titles` and `best_finish`. v0.2.3 added `last_mode` and `text` (-1 automatic, 0 Normal, 1 Large).
- The browser test state comes from the shared `addons/bc_common/test_bridge.gd` as `window.lofi` and `window.lofi_cmd`.
- Xbox controller (G5.8): `main.gd` calls `InputSetup.add_controller_ui()` at startup so A chooses the focused menu button. B goes back on the modes, club picker and league screens and closes the Menu. In play B shoots or tackles. View and Menu both toggle the Menu. Player-facing text uses Xbox button names.
- Every outside asset goes in `CREDITS.md` with its licence. Music comes from the Patch.gg library (G8.1).

## Test gate

The browser tests take minutes each here: this workspace draws the game in software at 1 or 2 frames a second.

- `bash tools/common/sync_common.sh --check .` must print `COMMON check ok` (G10.3).
- `bash tools/common/check_secrets.sh` must print `SECRETS check ok` (G1.9). No key, keystore, password or token in the repo.
- `godot --headless --path . -s res://tests/common/save_store_check.gd` must print `SAVESTORE check ok` (E6.7).
- Test hooks stay off for players (G7.8). `window.lofi` and `window.lofi_cmd` work only with the whole-word `?test` flag (kit 1.3.0). Every browser test opens `index.html?test`.
- `godot --headless --path . -- --bot --rules` must print `RULES done, 0 failed`.
- `godot --headless --path . -- --bot --games=6` must finish every match and print `BOT done`. Typical scores sit between 0 and 7 a side.
- `godot --headless --path . -- --bot --season` must play a full league season through the real league path and print `SEASON done`.
- `python3 tests/pad_test.py <web folder> <shots folder>` must print `errors []` (G5.8). A pretend Xbox controller plays from the title card into a match and through the Menu with no keyboard or touch.
- `python3 tests/qol_test.py <web folder> <shots folder>` must print `errors []`. On a 915 x 412 touch screen it checks Large text by default, Text in the Menu, touch with Large text, the pause on focus loss, the remembered mode and club, the Quit check in a league match and the scorers at full time. View the screenshots.
- `python3 tests/web_test.py <web folder> <shots folder>` must print `errors []`. View the screenshots. In `?test` mode the page reports `window.lofi` and runs one menu action from `window.lofi_cmd`.
- `python3 tests/common/page_check.py https://bclark10121-cloud.github.io/lo-fi-league/` after every push must print `errors []`.

Test what changed (G7.9, Brian 2026-11-15). Every release runs the quick checks above: kit, secrets, save store, rules, bot matches and the bot season. It also runs the browser tests for the parts it changed and the page check after the push. `web_test.py` covers one league match, a reload, an exhibition, touch and the Menu. `pad_test.py` covers the controller. `qol_test.py` covers the comfort features. Say in the report which ran and which were skipped.

Android production release only (Google Play), or when Brian asks:

- `python3 tests/e2e_test.py <game page url> <shots folder>` must print `errors []`. It plays two league seasons, reloads, plays practice and exhibition and checks phone-size screens. Run it on a local copy of `docs/` before the push and on the live page after.

## Deliver every time (every release)

1. Game page link: https://bclark10121-cloud.github.io/lo-fi-league/ (give Brian this link, not the direct play link)
2. GitHub repo link: https://github.com/bclark10121-cloud/lo-fi-league
3. The APK, named `LoFiLeague-v<version>.apk`, in `docs/downloads/` and sent to Brian as a file. Package id `com.brianclark.lofileague`. Raise `version/code` by one on every build.
4. The backlog: `BACKLOG.md`, updated, linked and sent as a file.
5. The game standards handoff zip, built with `tools/common/make_handoff.sh ../game-standards` and sent as a file.
6. `docs/index.html` updated: the line under the buttons reads exactly `Version <version>. Release notes · Backlog · Source on GitHub` (G1.8). `docs/release-notes/v<version>.md` added with a test checklist and the kit version (G10.4). The browser build goes in `docs/play/`.
7. The dashboard card refreshed in `bclark10121-cloud.github.io` in the same push: replace `images/lo-fi-league.jpg` with a fresh 960 x 540 screenshot of the new build, and update the card's name, tag line, description or link in `index.html` whenever they changed (G2.7). Change only this game's card. The version fills itself in from the version line. After the push, check the card shows the new version. Give Brian the dashboard link: https://bclark10121-cloud.github.io/

## Android signing

Sign every APK with Brian's key `wandervalley.jks` (G6.3). The signature SHA-256 starts with `5db69ffb`.
The key and its settings live in the private repo `bclark10121-cloud/game-signing` (G1.2, G1.7). Clone it to `../game-signing`, outside this repo.
Build with `bash tools/common/sign_android.sh <apk path>`. It exports, signs and fails unless the signature is right. Never commit the key or its passwords here.
v0.1.0 was signed with a throwaway test key. Testers uninstall v0.1.0 once before installing v0.1.1 or later.

## Reporting to Brian

Lead with the links and files. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
