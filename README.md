# Lo-Fi League

Laid-back 7 a side soccer. Pass, shoot and take it easy. Built in Godot 4.6 for Android and the browser.

Game page (play in the browser or download the Android APK): https://bclark10121-cloud.github.io/lo-fi-league/

## Status

v0.2.3: bigger text on phones, auto pause and goal scorers at full time. Play with only an Xbox controller. League mode with a 7 matchday season and a table, exhibition matches against the computer, eight fictional clubs, four formations, throw-ins, corners, goal kicks and a Practice mode.

## Standards

- The standards live in the private repo `bclark10121-cloud/game-standards` (one source). This repo holds no copies.
- `STANDARDS_OVERRIDES.md`: where this game does something else, open items, rules met, rules not in use and the standards version it was checked against.
- `common.lock`: the version of the shared kit pulled into `addons/bc_common/`, `tools/common/` and `tests/common/`. Never edit those files here.
- `CLAUDE.md`: this game's pillars and rules.

## Layout

- `project.godot`, `main.tscn`: the Godot project. Compatibility renderer.
- `scripts/main.gd`: the pitch, the rules, the computer players, the camera, the test bot and the rules check.
- `scripts/player.gd`: one player, built from simple shapes and animated in code.
- `scripts/league.gd`: the league schedule, table and simulated matches.
- `scripts/hud.gd`: scoreboard, Menu button, shot meter, mode and club screens, league table, panels and touch controls.
- `data/teams.json`, `data/formations.json`, `data/league.json`: clubs, formations and the league. New content needs no code.
- `audio/`: lo-fi music and a tackle sound from Patch.gg (see `CREDITS.md`) and stadium sounds made by `tools/common/make_sfx.py`.
- `addons/bc_common/`, `tools/common/`, `tests/common/`: the shared kit from `game-standards` (save store, test bridge, signing, handoff zip, Patch.gg fetcher, sound maker, browser test helpers).
- `tests/web_test.py`: browser check with screenshots.
- `tests/e2e_test.py`: end-to-end check of the game page and two league seasons.
- `docs/`: the GitHub Pages site. Game page at the root, the game in `docs/play/`, APKs in `docs/downloads/`.
- `BACKLOG.md`: the backlog. `PLAN.md`: the first plan.

## Build and test

    godot --headless --path . --import
    godot --headless --path . -- --bot --rules                # rules check, must print: RULES done, 0 failed
    godot --headless --path . -- --bot --games=6 --verbose    # the computer plays both sides and prints each match
    godot --headless --path . -- --bot --season               # plays a full league season, must print: SEASON done
    godot --headless --path . --export-release Web
    python3 tests/web_test.py <web folder> <shots folder>     # must print: errors []
    bash tools/common/sync_common.sh --check .                # must print: COMMON check ok
    GODOT=godot bash tools/common/sign_android.sh ../LoFiLeague-v<version>.apk   # needs ../game-signing
    python3 tests/e2e_test.py <game page url> <shots folder>  # must print: errors []
