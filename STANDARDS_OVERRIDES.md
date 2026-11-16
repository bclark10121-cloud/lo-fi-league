# Lo-Fi League: standards overrides

Standards: `GAME_STANDARDS.md` (rule ids start with G) and `ENGINEERING_STANDARDS.md` (rule ids start with E) in the private repo `bclark10121-cloud/game-standards`. This repo holds no copies.
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: BC in the chat, then this file, then the standards.

Last reviewed: v0.2.3 (2026-11-15). First engineering audit on 2026-11-14. v0.2.2 ships G1.9, G7.8, E6.7, G5.8 and kit 1.5.0.
Checked against: game-standards version 2026-11-15 (commit b2c2865). Shared kit 1.5.0 (`common.lock`).

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1 | Calm games. No combat. No way to lose. A reset never costs anything | A soccer match against the computer with a final score. A match ends in a win, a draw or a loss. Tackles win the ball. No injuries and no cards. Restart match costs nothing | Sports game. BC, 2026-11-14: these rules do not apply to sports games or where they clearly do not make sense | Never, unless BC changes the kind of game | 2026-11-14 |
| 2 | G4.4 | Records and achievements are personal bests only. No leaderboards, no opponents | One computer opponent per match. A win, draw and loss record saved on the device. No leaderboards | Sports game. BC, 2026-11-14: these rules do not apply to sports games or where they clearly do not make sense | Never, unless BC changes the kind of game | 2026-11-14 |
| 3 | G7.1 | A headless test driver proves the main route is drivable with 0 resets | A headless test bot plays 6 full matches and a full league season. Every match must finish and print its result | A soccer match has no route to drive. BC, 2026-11-14: these rules do not apply to sports games or where they clearly do not make sense | G7.6 comes into force. The bot then counts as a rule met | 2026-11-14 |
| 5 | E4.1 | The default is GodotPhysics3D. Avoid Jolt on browser builds. A game that uses no physics engine records an override | No physics engine is used. Players and the ball move with plain maths in `main.gd`. `project.godot` keeps Godot's default engine, which runs nothing | Simple maths gives arcade control and the same result on every device | The game adds physics bodies | Proposed |

A Proposed row is not in force. The standard applies until BC agrees.

## Open items (rule applies, work not finished)

Game standards:

- G5.2: the sprint bar and the shot power meter sit on screen with the scoreboard. They are counted as status readouts. BC to confirm.
- G6.6: players, ball, posts and crossbar collide by plain maths. The nets do not catch the ball. A goal ends the play at the line.

Engineering standards (from the first audit, 2026-11-14):

- E1.2: most declarations are typed. 7 variables and about 26 plain `Array` values are not typed (`Array[...]`).
- E1.3: the HUD redraws the touch pad every frame, even when it is hidden. The attract match runs behind the title card on purpose.
- E1.5: play checks use `distance_to()` in 22 places. None use `distance_squared_to()`.
- E2.3: each player model makes its own control ring material when a match starts. Colors share one cached material.
- E2.5: one shadow-casting light, orthogonal. The directional shadow atlas is not capped at 2048.
- E3.1: triangles are low (players are boxes and spheres). Draw calls not measured. Estimate: about 300 with 14 players, which is at the limit.
- E3.2: the 12 ad boards and 16 skyline blocks are separate meshes. They should be one `MultiMeshInstance3D` each.
- E3.3: the pitch, crowd, window and ball textures are made in code at load. They have mipmaps but no VRAM compression.
- E3.4: no `visibility_range_end` on scenery, `mesh_lod_threshold` not raised and no `VisibleOnScreenEnabler3D` on players.
- E4.6: VRAM not measured.
- E5.2: `scaling_3d_scale` not set and no 60 fps cap on mobile.
- E5.3: the HUD does not read `DisplayServer.get_display_safe_area()`. Not checked with a notch.
- E5.4: keyboard movement reads raw keys, not input actions. Touch, gamepad and keyboard all work. Touch controls hide on key or gamepad input from v0.2.1. Touch targets are 48 px or more.
- E6.3: short sounds are mono `.ogg` at 32 kHz, not `.wav`. The tackle sound is stereo 44.1 kHz. Music is `.ogg` at about 104 kbps.

## Rules met

Checked on 2026-11-14 by reading the files and by running the checks named below.

Game standards:

- G0.3: this file, at the repo root, in the appendix format, with the Checked against line.
- G0.10: no copies of the standards in this repo. `handoff/` was removed on 2026-11-14. The standards are read from `game-standards`.
- G0.12: checked against game-standards commit ee33b2f for v0.2.1, then against commits e4688a1, 0ea73bd, 416fd8c and b2c2865 on 2026-11-15.
- G1.1: public repo `bclark10121-cloud/lo-fi-league`, created 2026-11-14.
- G1.2: no key, keystore or password in the repo. `.gitignore` blocks `*.jks` and `*.keystore`.
- G1.3: game page `docs/index.html`, served from `main` `/docs`.
- G1.4: the game page has the description, Play in your browser, the APK download, three screenshots, what kind of game it is, things to do, controls, install steps, a feedback list and links to release notes, backlog and source.
- G1.5: browser build in `docs/play/`, APK in `docs/downloads/`, release notes in `docs/release-notes/`.
- G1.6, G2.1, G2.2: game page https://bclark10121-cloud.github.io/lo-fi-league/ and repo https://github.com/bclark10121-cloud/lo-fi-league given to BC.
- G1.7: one public repo. No private repo for this game. The key comes from `game-signing` at build time and lives in a folder outside the repo.
- G1.10: the game page footer links to The Game Shelf at https://bclark10121-cloud.github.io/. Lo-Fi League has its card there. The card reads its version from the version line.
- G1.11: no person's name on the game page (done 2026-11-15 in commit 0332d0a). The repo description was not checked from here.
- G2.7: each release puts a fresh 960 x 540 screenshot on the Game Shelf card in the same push (v0.2.2 and v0.2.3). The card text did not change. The card shows the version from the version line.
- G1.9: no key, keystore, password or token in the repo. `bash tools/common/check_secrets.sh` is in the test gate and prints `SECRETS check ok`. `.gitignore` blocks `signing.properties` and `game-signing/`. The game reads the key from a fresh copy of `game-signing` (new password from 2026-11-15).
- G1.8: the line under the buttons reads exactly `Version 0.2.3. Release notes · Backlog · Source on GitHub`. It matches the title card and the APK name (shared page check).
- G2.3: `LoFiLeague-v0.2.3.apk` built, arm64, package `com.brianclark.lofileague`, version code 6.
- G2.4: `BACKLOG.md` updated for v0.2.3.
- G2.5: `tools/common/make_handoff.sh ../game-standards` builds the handoff zip from `game-standards` plus this game's files.
- G2.6: the game page has the version line and the APK link. `docs/release-notes/v0.2.3.md` says what is new and has a test checklist.
- G4.2: four pillars in `CLAUDE.md`, confirmed by BC 2026-11-14.
- G4.6: `BACKLOG.md` has Done, Now, Asked for by BC, Ideas to choose from (numbered), Later, Not planned and Decisions.
- G5.1: Menu button at the top right opens Resume, How to play, Sound, Music, Restart match and Quit to title in a row. It reads Close while open. Esc toggles it (headless Chrome). Controller Back is wired, not tested on a controller. From v0.2.3 the row wraps onto a second line when it is too wide, which happens only with Large text on a desktop-size screen. On phones it stays one row.
- G5.3: drag on the left half to move, three buttons on the right. Shows and hides as E5.4 says (end-to-end test).
- G5.8: `InputSetup.add_controller_ui()` from kit 1.5.0. A chooses, B goes back, View and Menu toggle the Menu. The title card, How to play and the game page use Xbox button names. The game page has the Play with an Xbox controller section. `tests/pad_test.py` plays with a pretend Xbox controller and prints `errors []`. Not tried with a real controller.
- G5.4, G5.5: title card shows the name, version line, one line on the game, keyboard, controller and touch controls and a Start button.
- G5.6: the save file `user://lofi_league.json` (`v: 1`) is read and written by the shared `save_store.gd`. Each field loads with a safe default. Number fields stay numbers across a reload (rules check on disk, end-to-end reload check). This fixed a v0.2.0 bug where wins, draws, losses, seasons, titles and best finish reset on reload.
- G6.1: sensor landscape, 1280 x 720 base. Renderer and stretch as E2.1 and E5.1 say. Physics engine as override row 5 says.
- G6.2: Web (no threads) and Android (arm64) export presets. Version code raised to 6 for v0.2.3.
- G6.3: v0.2.3 is signed with `wandervalley.jks` from `game-signing`. The signature SHA-256 starts with `5db69ffb`.
- G6.4: the pitch, goals, stands, skyline and players are built in code. Repeated scenery is open item E3.2.
- G6.5: pitch lines are painted into one ground texture. The outer ground sits 0.6 yards below the pitch. The control ring is a raised mesh.
- G7.3: `tests/web_test.py` and `tests/e2e_test.py` load the web build in headless Chrome and print `errors []`. Screenshots viewed. Both use the shared `tests/common/webkit.py`.
- G7.4: the live game page, every link and the version line were checked after the push with the shared `tests/common/page_check.py`.
- G7.5: stated in the release notes and the report to BC.
- G7.8: test state and commands come only from the shared `test_bridge.gd` (kit 1.3.0) with the whole-word `?test` flag. The only other test switches are command line flags (`--bot`, `--rules`, `--games`, `--season`). The Android build takes no test commands. Headless bots never write the player's save (`store.disabled`). Shipped in v0.2.2.
- G8.1: four CC0 lo-fi tracks by Holizna, found through Patch.gg.
- G8.3: `CREDITS.md` lists every outside asset with its source and licence.
- G8.4: eight fictional clubs, original player names, kits and formations. Nothing from the reference game is in the repo.
- G10.1, G10.2: shared kit 1.5.0 pulled (1.1.0 at v0.2.1) into `addons/bc_common/`, `tools/common/` and `tests/common/`. `common.lock` names the version and commit. This game's own copies of the handoff script, Patch.gg fetcher and sound maker were removed.
- G10.3: `bash tools/common/sync_common.sh --check .` is in the test gate and prints `COMMON check ok: 1.5.0 b2c2865`.
- G10.4: the v0.2.3 release notes name kit 1.5.0.
- G10.5: the shared save store and test bridge came from this game. No other proposals yet.

Engineering standards:

- E1.1: Godot 4 syntax only. No string-based `connect()`.
- E1.4: no `get_node()`, `$Path` or `find_child()` inside `_process`. Node references are cached in variables.
- E2.1: `gl_compatibility` on both targets. No Forward+ features.
- E2.2: no particles of any kind.
- E2.4: opaque geometry everywhere except the four see-through goal nets.
- E4.5: nothing is made or freed during play. Players are built once when a match starts.
- E5.1: stretch `canvas_items`, aspect `expand`.
- E6.1: browser export has threads off. Audio playback type is Godot's web default, Sample.
- E6.2: music and crowd start only after the first press of Start.
- E6.4: from v0.2.1 the shared `save_store.gd` writes the save. The browser calls `JavaScriptBridge.force_fs_sync()`. Android writes a temp file and renames it. The end-to-end test proves a reload after a match keeps it once the save reaches browser storage. In headless Chrome that takes up to about 45 seconds because it draws 1 or 2 frames a second. On a real device it takes about half a second (measured by frame rate, not on a device).
- E6.5: from v0.2.1 the game saves on `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_WM_CLOSE_REQUEST`.
- E6.7: saves are read and written only by the kit's `save_store.gd` 1.4.0. Known keys and kinds only, counters clamped by `store.limits`, a 1 MB cap, a version guard and a `.bak` copy. The game has no backup codes and no delete-save button. The rules check deletes its own test file with `erase()`. `save_store_check.gd` prints `SAVESTORE check ok`. Shipped in v0.2.2.
- E6.6: `quit_on_go_back = false`. The Android back button opens and closes the Menu.

Proposed rules this game already follows (not in force, listed for BC):

- G4.8: review, name check, plan and backlog came before the build.
- G4.9: clubs, formations and the league are data in `data/teams.json`, `data/formations.json` and `data/league.json`.
- G6.7: the signing key was fetched only after BC said so in the chat (2026-11-14). It now comes from `game-signing` and lives outside the repo.
- G7.6: `--bot --games=6` plays six full matches and prints each result. `--bot --rules` checks every restart and the league schedule, table, simulated scores and save file. `--bot --season` plays a full season. The browser tests read `window.lofi` instead of guessing wait times.
- G7.9: the test gate in `CLAUDE.md` is split into every release and Android production release only. The two-season end-to-end test runs only for a Google Play release or when BC asks.
- G7.7: the engineering release checklist was ticked for v0.2.3 and this file was reviewed.
- E5.5: the game caps the frame step and takes up to three smaller steps per frame.

## Not in use in this game

- G4.3 and G7.2: things to find. A soccer match has no finds, counter or journal. Confirmed by BC 2026-11-14 (does not apply to sports games).
- G4.5: no seasonal theme.
- G5.7: the game shows no speed or distance.
- G4.7, G6.8 and G6.9: retired rules.
- E4.2 and E4.3: no physics bodies or colliders (override row 5). Motion is stepped in `_process` every drawn frame, so it stays smooth on 90 and 120 Hz screens.
- E4.4: no navigation.
- E3.4 `VisibleOnScreenEnabler3D` and E4.6 `.glb` keyframe compression: no imported models or animation players. Player animation is a few lines of code.

## How to add an override

1. Flag the conflict to BC with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to BC.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask BC to make it a standard. Then end the override.

## Ended overrides

| # | Rule | This game did | Ended | Why |
|---|---|---|---|---|
| 4 | G6.3 | v0.1.0 was signed with a throwaway test key. The row stayed Proposed and was never in force | 2026-11-14 | BC said in the chat to fetch `wandervalley.jks`. v0.1.1 and later use the real key, now from `game-signing` |
