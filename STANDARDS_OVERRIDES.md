# Lo-Fi League: standards overrides

Standards: `handoff/GAME_STANDARDS.md` (rule ids start with G) and `handoff/ENGINEERING_STANDARDS.md` (rule ids start with E).
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: Brian in the chat, then this file, then the standards.

Last reviewed: v0.1.1 (2026-11-14).

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1 | Calm games. No combat. No way to lose. A reset never costs anything | A soccer match against the computer with a final score. A match ends in a win, a draw or a loss. Tackles win the ball. No injuries and no cards. Restart match costs nothing | Sports game. Brian, 2026-11-14: these rules do not apply to sports games or where they clearly do not make sense | Never, unless Brian changes the kind of game | 2026-11-14 |
| 2 | G4.4 | Records and achievements are personal bests only. No leaderboards, no opponents | One computer opponent per match. A win, draw and loss record saved on the device. No leaderboards | Sports game. Brian, 2026-11-14: these rules do not apply to sports games or where they clearly do not make sense | Never, unless Brian changes the kind of game | 2026-11-14 |
| 3 | G7.1 | A headless test driver proves the main route is drivable with 0 resets | A headless test bot plays 6 full matches. Every match must finish and print its result, then print `BOT done` | A soccer match has no route to drive. Brian, 2026-11-14: these rules do not apply to sports games or where they clearly do not make sense | G7.6 comes into force. The bot then counts as a rule met | 2026-11-14 |

A Proposed row is not in force. The standard applies until Brian agrees.

## Open items (rule applies, work not finished)

- G4.2: pillars are written in `CLAUDE.md` as Proposed. Brian has not confirmed them.
- G5.2: the sprint bar and the shot power meter sit on screen with the scoreboard. They are counted as status readouts. Brian to confirm.
- G5.3: touch layout checked in headless Chrome only (drag on the left half, three buttons on the right). The pad shows after the first touch. E5.4 has not been checked.
- G5.6: the save file `user://lofi_league.json` (`v: 1`) loads each field with a safe default. Not checked against E6.4 and E6.5.
- G6.1: `project.godot` sets sensor landscape and 1280 x 720. It also sets the Compatibility renderer, stretch `canvas_items`, aspect `expand` and Jolt from the old template. E2.1, E5.1 and E4.1 have not been checked. The game uses no physics bodies.
- G6.6: players, ball, posts and crossbar collide by plain maths. The nets do not catch the ball. A goal ends the play at the line.
- Engineering standards: `handoff/ENGINEERING_STANDARDS.md` has not arrived. No E rule has been checked. This repo has no E overrides.

## Rules met

Checked on 2026-11-14 by reading the files and by running the checks named below.

- G0.3: this file, at the repo root, in the appendix format.
- G1.1: public repo `bclark10121-cloud/lo-fi-league`, created 2026-11-14.
- G1.3: game page `docs/index.html`, served from `main` `/docs`.
- G1.4: the game page has the description, Play in your browser, the APK download, three screenshots, what kind of game it is, things to do, controls, install steps, a feedback list and links to release notes, backlog and source.
- G1.5: browser build in `docs/play/`, APK in `docs/downloads/`, release notes in `docs/release-notes/`.
- G1.6, G2.1, G2.2: game page https://bclark10121-cloud.github.io/lo-fi-league/ and repo https://github.com/bclark10121-cloud/lo-fi-league given to Brian.
- G1.2: no key, keystore or password in the folder. `.gitignore` blocks `*.jks` and `*.keystore`. The test key lives outside the repo.
- G2.3: `LoFiLeague-v0.1.1.apk` built, arm64, package `com.brianclark.lofileague`, version code 2.
- G2.4: `BACKLOG.md` updated for v0.1.0.
- G2.5: `tools/make_handoff.sh` builds the handoff zip with `GAME_STANDARDS.md`, this file, the templates and the reusable code.
- G2.6: release notes with a test checklist in `docs/release-notes/v0.1.1.md`. Game page has the version line, what is new and the APK link.
- G4.6: `BACKLOG.md` has Done, Now, Asked for by Brian, Ideas to choose from (numbered), Later, Not planned and Decisions.
- G5.1: Menu button at the top right opens Resume, How to play, Sound, Music, Restart match and Quit to title in a row. It reads Close while open. Esc toggles it (headless Chrome). Controller Back is wired, not tested on a controller.
- G5.4, G5.5: title card shows the name, version line, one line on the game, keyboard, controller and touch controls and a Start button.
- G6.2: Web (no threads) and Android (arm64) export presets. Version code raised to 2 for v0.1.1.
- G6.3: v0.1.1 is signed with `wandervalley.jks`. The signature SHA-256 starts with `5db69ffb`.
- G6.4: the pitch, goals, stands, skyline and players are built in code.
- G6.5: pitch lines are painted into one ground texture. The outer ground sits 0.6 yards below the pitch. The control ring is a raised mesh.
- G7.3: `tests/web_test.py` loads the web build in headless Chrome and prints `errors []`. Screenshots viewed.
- G7.4: the live game page, the play link and the APK link were checked after the push.
- G7.5: stated in the v0.1.0 release notes and the report to Brian.
- G8.1: four CC0 lo-fi tracks by Holizna, found through Patch.gg.
- G8.3: `CREDITS.md` lists every outside asset with its source and licence.
- G8.4: six fictional clubs, original player names, kits and formations. Nothing from the reference game is in the repo.

Proposed rules this game already follows (not in force, listed for Brian):

- G4.8: review, name check, plan and backlog came before the build.
- G4.9: clubs and formations are data in `data/teams.json` and `data/formations.json`.
- G6.7: the signing key was fetched only after Brian said so in the chat (2026-11-14). It lives outside the repo.
- G7.6: `--bot --games=6` plays six full matches and prints each result. `--bot --rules` checks every restart. The browser test reads `window.lofi` instead of guessing wait times.

## Not in use in this game

- G4.3 and G7.2: things to find. A soccer match has no finds, counter or journal. Confirmed by Brian 2026-11-14 (does not apply to sports games).
- G4.5: no seasonal theme.
- G5.7: the game shows no speed or distance.
- G4.7, G6.8 and G6.9: retired rules.

## How to add an override

1. Flag the conflict to Brian with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to Brian.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask Brian to make it a standard. Then end the override.

## Ended overrides

| # | Rule | This game did | Ended | Why |
|---|---|---|---|---|
| 4 | G6.3 | v0.1.0 was signed with a throwaway test key. The row stayed Proposed and was never in force | 2026-11-14 | Brian said in the chat to fetch `wandervalley.jks` from `keeper-of-the-hollow-source`. v0.1.1 uses the real key |
