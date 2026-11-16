# Lo-Fi League: plan before the build

Written 2026-11-14 for BC. G4.8 (Proposed) asks for a review, a plan and a backlog before any build.
Rule ids updated 2026-11-14 to the shared standards: G for `GAME_STANDARDS.md`, E for `ENGINEERING_STANDARDS.md`, both read from the private repo `game-standards`. Overrides and open items live in `STANDARDS_OVERRIDES.md`.

## 1. What I reviewed

| File | What it is | How I used it |
|---|---|---|
| `Game_Standards_handoff.zip` | Game standards, templates, reusable code, Tiny Titans Football and The Scenic Route docs | The rules for this game |
| `STANDARDS_OVERRIDES.md` | Keeper of the Hollow's 9 overrides | The format for overrides. None of the 9 carry over to a new game |
| `Pixel Cup Soccer - Ultimate Edition - Team Editor.zip` | A Windows team editor for a commercial soccer game, with its game data | Reference for structure only |

## 2. What the reference holds

- 356 teams in 5 categories. Each team has 18 players (11 starters and 7 on the bench), a home kit, an away kit and a goalkeeper kit.
- Each team has a style: pass, kick, tackle and run weights from 0 to 100, plus a marking count.
- Each player has 8 ratings: speed, acceleration, agility, stamina, power, accuracy, dribbling and marking. Each player also has a head type, hair, skin and eye colors, a shirt number and a list of special skills.
- 32 formations. Each one is 10 outfield spots on a 0 to 1 grid, plus a defense, midfield and forward count.
- 24 competitions in 3 shapes: round robin leagues with 8 teams and 4 divisions, knockout cups, and group stage then knockout cups.
- One recolorable player sprite sheet. Kits are made by swapping a small set of key colors.
- 49 stadiums, 10 languages and a coach.

## 3. Borrow and leave

Borrow (structure):

1. Teams, formations and competitions as data files. New content needs no code (G4.9, Proposed).
2. One player model recolored per team, with home, away and keeper kits.
3. A small set of player ratings and a team style.
4. Formations as spots on a 0 to 1 grid.
5. Divisions with round robin play, then cups.

Leave (content):

1. Every sprite, flag, stadium picture, icon and text string in the zip. None of it goes in the repo.
2. Every team and player name. The reference uses real countries and clubs. Lo-Fi League uses fictional clubs (G8.4).
3. The exact formation coordinates and rating numbers. I write our own.
4. Real competition names.

The editor zip stays out of the public repo.

## 4. Name check

- I ran two web searches on 2026-11-14. I found no game called Lo-Fi League or Lofi League.
- Closest names: "lo-fi soccer", a small free game on itch.io, and "lofi ping pong" on Steam. Different names. Low overlap.
- "Lo-fi" is a common word for a music style. Many games use it.
- Limits: this was a web search. I did not check trademark records or search inside the Play Store.

## 5. Proposed pillars (BC to confirm)

1. Pick up and play. Move, pass, shoot, tackle. A match takes about 6 minutes.
2. Laid-back mood. Lo-fi music, soft colors, friendly fouls, no injuries, no red cards.
3. Soccer rules people know: goals, throw-ins, corners, goal kicks, kickoffs and halves.
4. Original everything. Fictional clubs, our own formations, art and names.

Note for `CLAUDE.md`: this game has an opponent and a final score. G4.7 is retired, so this needs override rows for G4.1 and G4.4 in `STANDARDS_OVERRIDES.md`.

## 6. Proposed v0.1.0 (first test build)

- One exhibition match against the computer. Two 3-minute halves.
- 6 fictional clubs with home and away kits, ratings and a team style.
- 4 formations stored as data.
- Controls: move, sprint, pass, shoot with a hold-for-power meter, tackle and switch player.
- Rules: goals, kickoffs, throw-ins, corners, goal kicks. No offside and no cards in v0.1.0.
- Computer keepers on both sides.
- Practice mode: no clock, no score.
- Keyboard, controller and touch. One Menu button at the top right.
- Lo-fi music from Patch.gg. Crowd, whistle and kick sounds.
- Win, draw and loss record saved on the device.
- Title card with name, version line, one line on the game, controls and Start.

Team size and camera are open. See section 10.

## 7. Data files

- `data/teams.json`: id, name, short name, kits, team style and players with ratings.
- `data/formations.json`: 10 outfield spots on a 0 to 1 grid.
- `data/competitions.json`: added with league mode, after v0.1.0.

## 8. Build and test gate

- Godot 4.6. Compatibility renderer. 1280 x 720 landscape. Web and Android arm64.
- Package `com.brianclark.lofileague`. APK `LoFiLeague-v0.1.0.apk`. Repo `bclark10121-cloud/lo-fi-league`. Page in `docs/`.
- Pitch lines painted into one ground texture (G6.5). Players move with plain maths, as in Tiny Titans Football.
- Test bot plays 6 full matches headless and prints each score (G7.6, Proposed).
- Browser test in headless Chrome must print `errors []`. I view the screenshots.
- Reused from the handoff: HUD with Menu button and touch pads, stadium sounds, Patch.gg fetch tool, browser test, handoff script.

## 9. Where this game and the standards rub

| # | Standard | Issue | Proposed handling |
|---|---|---|---|
| 1 | G4.1 and G4.4 calm, no way to lose, no opponents | A soccer match has an opponent and a result | Proposed override rows 1 and 2 |
| 2 | G4.3 and G7.2 things to find | Soccer has no finds | Listed under Not in use in `STANDARDS_OVERRIDES.md` |
| 3 | G5.7 US units | Soccer pitches are marked in yards. No speed readout planned | Yards on the pitch. No override needed |
| 4 | G6.3 signing key | The key lives in a private repo | Proposed override row 4: a test key until BC says to use the real one |
| 5 | G1.1 public repo | I need BC's go-ahead to create and push a public repo | Ask at build time |

## 10. Open questions for BC

1. Team size: 11 a side, 7 a side or 5 a side?
2. Look and camera: low-poly 3D or 2D pixel art?
3. What does "lo-fi" mean to you for this game?
4. First build: exhibition only, or exhibition plus a short league?

## 11. Assumptions (flag any to change)

1. The editor zip is a style reference. You do not want its teams or art imported.
2. Fictional clubs, not countries.
3. Single player against the computer in v0.1.0.
4. Same repo layout, page and delivery list as Tiny Titans Football.
