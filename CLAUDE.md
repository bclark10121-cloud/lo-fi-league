# Lo-Fi League: project rules

Lo-Fi League is Brian Clark's laid-back 7 a side soccer game. Godot 4.6, Android and browser. This repo is public.
Read `handoff/GAME_STANDARDS.md` first (rule ids start with G). Engineering rules go in `handoff/ENGINEERING_STANDARDS.md` (rule ids start with E) once Brian sends it.
Overrides and open items for this game live in `STANDARDS_OVERRIDES.md`. Order of authority: Brian in the chat, then `STANDARDS_OVERRIDES.md`, then the standards files.
Never edit a standards file for this game. Propose the change to Brian.

## Pillars (never break these)

Proposed 2026-11-14. Brian to confirm (G4.2).

1. Pick up and play. Move, pass, shoot, tackle. A match takes about 6 minutes.
2. Laid-back mood. Lo-fi music, soft colors, friendly tackles, no injuries, no red cards.
3. Soccer rules people know: goals, throw-ins, corners, goal kicks, kickoffs and halves.
4. Original everything. Fictional clubs, our own formations, art and names. Nothing from Pixel Cup Soccer or any other game.

This game has an opponent and a final score. That needs override rows for G4.1 and G4.4 (Proposed in `STANDARDS_OVERRIDES.md`).

## Rules

- This repo is public. Never commit a signing key, keystore or password.
- Pitch units are yards. The pitch runs along X. Goal lines sit at x = -30 and x = +30. Sidelines sit at z = -20 and z = +20.
- Side 0 (the player) always attacks +X, the right of the screen. The camera sits on the +Z sideline. Teams do not switch ends.
- Players and the ball move with plain maths, not physics bodies. `main.gd` sets `want` and each player eases toward it.
- Pitch lines are painted into one ground texture (G6.5). Never lay a thin layer on the grass.
- Clubs live in `data/teams.json` and formations in `data/formations.json`. New clubs need no code. `tools/make_teams.py` wrote the first six.
- Save file is `user://lofi_league.json`, format `v: 1`. Only add fields, each with a safe default.
- Every outside asset goes in `CREDITS.md` with its licence. Music comes from the Patch.gg library (G8.1).

## Test gate

- `godot --headless --path . -- --bot --rules` must print `RULES done, 0 failed`.
- `godot --headless --path . -- --bot --games=6` must finish every match and print `BOT done`. Typical scores sit between 0 and 7 a side.
- `python3 tests/web_test.py <web folder> <shots folder>` must print `errors []`. View the screenshots.

## Deliver every time (every release)

1. Game page link: https://bclark10121-cloud.github.io/lo-fi-league/ (give Brian this link, not the direct play link)
2. GitHub repo link: https://github.com/bclark10121-cloud/lo-fi-league
3. The APK, named `LoFiLeague-v<version>.apk`, in `docs/downloads/` and sent to Brian as a file. Package id `com.brianclark.lofileague`. Raise `version/code` by one on every build.
4. The backlog: `BACKLOG.md`, updated, linked and sent as a file.
5. The game standards handoff zip, rebuilt with `tools/make_handoff.sh` and sent as a file.
6. `docs/index.html` updated and `docs/release-notes/v<version>.md` added with a test checklist. The browser build goes in `docs/play/`.

## Open item: Android signing

v0.1.0 is signed with a throwaway test key (Proposed override row 4). Brian's key `wandervalley.jks` lives in a private repo. Ask Brian before using it. Testers must uninstall a test-key build first.

## Reporting to Brian

Lead with the links and files. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
