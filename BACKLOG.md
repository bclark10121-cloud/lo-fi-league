# Lo-Fi League: backlog

Updated 2026-11-16 for v0.3.2. BC decides the order.

## Done

- Reviewed the game standards, the Keeper of the Hollow overrides and the reference team editor. Name check for "Lo-Fi League".
- Plan written: `PLAN.md`.
- Adopted the shared game standards of 2026-11-14 and wrote `STANDARDS_OVERRIDES.md`. Since v0.2.1 the standards are read from `game-standards` and this repo holds no copies.
- v0.1.0: 7 a side exhibition match against the computer. Two 3-minute halves.
- Six fictional clubs with home and away kits. The away kit shows when colors clash.
- Four formations as data: 2-3-1, 3-2-1, 2-2-2 and 1-3-2.
- Pass, shoot with a power meter, sprint, tackle and switch player.
- Goals, kickoffs, throw-ins, corners and goal kicks. Posts and crossbar bounce the ball back.
- Computer keepers that position, dive and claim the ball.
- Practice mode: no clock, a keeper only.
- Four CC0 lo-fi tracks from Patch.gg that play in turn. Crowd, whistle, kick and cheer sounds.
- Win, draw and loss record saved on the device.
- Keyboard, controller and touch. Menu button at the top right with Sound and Music toggles.
- Side camera that follows the ball across the pitch. Sunset stadium with a skyline.
- Deeper greens on the pitch (BC, 2026-11-14).
- Public repo `bclark10121-cloud/lo-fi-league` created and the game page turned on (BC, 2026-11-14).
- v0.1.1: APK signed with the real key `wandervalley.jks` (BC, 2026-11-14). Version code 2.
- v0.2.0: League mode (idea 1). 8 clubs, 7 matchday round robin, standings table, simulated other matches, season saved on the device, champions and best finish at season end.
- v0.2.0: two new clubs, Lamplight Wanderers and Window Seat Albion.
- v0.2.0: mode screen (Exhibition, League, Practice) and a Back button on the club screen.
- v0.2.0: test gate adds league rules checks, a full bot season and a league walk in the browser test.
- Pillars confirmed by BC (2026-11-14).
- v0.2.1: season saves at once in the browser and on Android (E6.4, E6.5). Records no longer reset on reload. Touch controls hide on key or gamepad input (E5.4). Version code 4.
- v0.2.1: moved to one source. Standards read from `game-standards`, shared kit 1.1.0 pulled, key from `game-signing`, version line under the buttons on the game page (G1.8, Tiny Titans layout).
- End-to-end test of the live game page: two full seasons, reloads, practice, exhibition and phone-size screens (`tests/e2e_test.py`).
- v0.2.2: play with only an Xbox controller (G5.8, BC 2026-11-15). A chooses and B goes back in every menu, View and Menu toggle the Menu, Xbox button names, connect steps on the game page, pretend controller test (`tests/pad_test.py`). Version code 5.
- v0.2.2: shared kit 1.5.0. Saves keep a backup and never load a newer save (E6.7). Test hooks only with `?test` (G7.8). Secrets check in the test gate (G1.9). Game Shelf link in the footer (G1.10).
- v0.2.3 comfort release (BC, 2026-11-15: "use your best judgement on what qol features to add next"). Ideas 30 (bigger text on phones, Text in the Menu), 34 (Quit check in a league match), 35 (remember the last mode and club) and 36 (goal scorers and minutes at full time). Also: the match pauses itself when the game loses focus, and the Menu row wraps instead of running under Close. New `tests/qol_test.py`. Version code 6.

- v0.3.0 standards catch-up (Release 4, BC 2026-11-15: "ok move forward"). Source moved to the private `game-studio` and the public repo became a page repo (G1.7). Kit 1.9.1 Settings with Music and Sound levels, Full screen, Frame rate, Rumble, Opponent, Controls, Text size and Reset settings (G5.11, G5.13). Five save slots with `Slot <number>` on the title card (G5.12). Opponent Easy, Normal or Hard (G4.12, idea 15 in part). Tester tools behind the code (G5.9, G5.10). Title card controls for the device in use (G5.14). Pause when the controller drops (G5.15). Menu row Resume, Settings, How to play, Restart match, Title (G5.16). Second press on Restart match and Start over (G5.17). Rumble on goals and tackles (idea 42 in part). New icon (G6.10). Privacy page (G6.13). GitHub Releases and the newest two APKs (G2.10, G1.12). Version code 7.
- v0.3.1 (2026-11-16), sound fix (BC 2026-11-16: no music in the browser). The Music and Sfx buses come from `default_bus_layout.tres` instead of `AudioServer.add_bus()` at runtime, which left every sound silent in the browser build. New `tests/audio_test.py` measures the page's real sound output. Version code 8.
- v0.3.2 (2026-11-16), browser crash fix (BC 2026-11-16: "memory access out of bounds" on startup in the Retroid Pocket Flip 2 browser). The Sfx bus in `default_bus_layout.tres` had no send. Godot 4.6's `set_bus_layout()` looks each send up before the bus exists, so an empty send read past the end of the bus list at random. Sfx now sends to Master, which also routes the sound effects in the browser. `tests/audio_test.py` fails on a bus with no send. Engine moved to Godot 4.6.3. Version code 9.

## Now

- BC opens v0.3.2 in the Retroid Pocket Flip 2 browser a few times. It must reach the title card every time.
- BC plays v0.3.0 on his phone and with an Xbox controller: Settings, the five save slots, the Opponent choice and the Tester tools.
- BC picks the next release from the ideas below. Game features wait until he opens development again (`PLAN.md` at the root of `game-studio`).

## Asked for by BC, not built yet

1. Suno music, first in line (BC, 2026-11-16, waits on G8.7). Replace the four Holizna tracks, which The Scenic Route plays too, with lo-fi tracks made for this game: a menu track and three match tracks. Fits idea 21, the lo-fi radio.

## Ideas to choose from (BC picks by number)

1. Done in v0.2.0: League mode.
2. Four divisions with promotion and relegation.
3. Knockout cup with extra time and penalty shootouts.
4. Group stage then knockout cup.
5. Team editor: name, kits and player ratings.
6. Player editor: head, hair, skin and shirt number.
7. More formations (12 or more) and a formation picker before kickoff.
8. Team style sliders: pass, shoot, tackle and run.
9. Special player skills such as a curved shot or a quick turn.
10. Offside, with a toggle.
11. Fouls, free kicks and penalties.
12. Yellow cards. No red cards.
13. Substitutions and stamina.
14. Lob pass, through ball and header.
15. Match length setting. Difficulty is done in v0.3.0 (Opponent in Settings).
16. Weather and night matches.
17. Several stadiums.
18. Two players on one device.
19. Spectate mode (computer against computer).
20. Goal replay.
21. A lo-fi radio: pick the track from the Menu.
22. Women's clubs.
23. Career mode: start in the lowest division with a small club.
24. Throw-ins taken with the hands, with a throw animation.
25. Teams switch ends at half time.
26. Home and away in the league: the home club picks its kit and its crowd cheers louder.
27. Double round robin: 14 matchdays, every club home and away.
28. League history: past seasons' champions and your finishes.
29. Simulate a matchday instead of playing it.

Quality of life (from the 2026-11-14 end-to-end run)

30. Done in v0.2.3: bigger text on phones.
31. Camera zoom setting: Near, Normal and Far. Closer by default on phones, where the players look small.
32. An arrow at the screen edge when the ball is off screen. The name of the player you control shows for a second after a switch.
33. Pass aim line: a short arrow shows who gets the ball before you pass.
34. Done in v0.2.3: Quit check in a league match.
35. Done in v0.2.3: remember the last mode and club.
36. Done in v0.2.3: goal scorers and minutes at full time.
37. Now playing: the track name shows for 3 seconds when a track starts. Next track in the Menu.
38. Solid panels behind the table and menus, so the match behind them does not show through.
39. Fixtures screen: the whole season's fixtures and results, from the table screen.
40. Club screen: tap a club in the table to see its players and ratings.
41. Touch: left-handed layout and a button size setting.
42. Rumble on a keeper save. Goals and tackles rumble from v0.3.0.
43. First-match hints: one line at the bottom suggests the next useful action. Turns off after three matches.

New features

44. Season stats: top scorers in the league and your club's leading scorer.
45. Personal goals in a small journal: win by 3, keep a clean sheet, score a hat-trick, finish a season unbeaten. Personal bests only.
46. Rain matches with a soft rain sound and a wet-pitch look (builds on idea 16).
47. Night matches under the floodlights, with a moon over the skyline (builds on idea 16).
48. A calm text commentary line at the bottom of the screen. Can be turned off.
49. Photo mode: pause, move the camera and save a picture.
50. Penalty shootout as its own mode (from idea 3).
51. Player growth: players improve a little after each season.
52. Daily challenge: a set-piece puzzle, such as score from this corner in 3 tries.
53. More pitches: rooftop, beach and park (builds on idea 17).

Engineering

54. Clear the engineering open items in `STANDARDS_OVERRIDES.md`: typed arrays, squared distances, one MultiMesh for the boards and the skyline, safe areas, 3D render scale and a 60 fps cap on phones, input actions for keys, the shadow atlas size and `.wav` short sounds.

## Unfinished standards items (2026-11-15)

From the Open items in `STANDARDS_OVERRIDES.md`, plus what has not been tried on a real device. Each line comes off when it is done. BC picks when.

- G5.2: BC to confirm the sprint bar and the shot power meter count as status readouts.
- G6.6: the nets do not catch the ball. A goal ends the play at the line.
- E1.2: 7 variables and about 26 plain `Array` values are not typed.
- E1.3: the HUD redraws the touch pad every frame, even when it is hidden.
- E1.5: 22 play checks use `distance_to()` in place of squared distances.
- E2.3: each player model makes its own control ring material.
- E2.5: the directional shadow atlas is not capped at 2048.
- E3.1: draw calls not measured (estimate about 300 with 14 players).
- E3.2: the 12 ad boards and 16 skyline blocks should be one `MultiMeshInstance3D` each.
- E3.3: the pitch, crowd, window and ball textures have no VRAM compression.
- E3.4: no `visibility_range_end` on scenery and `mesh_lod_threshold` not raised.
- E4.6: VRAM not measured.
- E5.2: `scaling_3d_scale` not set and no 60 fps cap on mobile.
- E5.3: the HUD does not read the display safe area. Not checked with a notch.
- E5.4: keyboard movement reads raw keys, not input actions.
- E6.3: short sounds are `.ogg`, not `.wav`. The tackle sound is stereo 44.1 kHz.
- Real device check: a phone, the Retroid, an Xbox controller and sound. v0.3.0 ran only headless and in a headless browser.

## Later

- Online play.

## Not planned

- Real league, club, country or player names.
- Any art, text or numbers copied from Pixel Cup Soccer or another game.
- Injuries and red cards (they break pillar 2).

## Decisions from BC

- 2026-11-16: fix the browser crash. Upgrade to Godot 4.6.3. After the real cause turned up (the Sfx bus had no send), release only the two games with the gap: Lo-Fi League and The Scenic Route.
- 2026-11-15, 10:07 PM: there is no Google Play store and no end-to-end testing in this project. Every Proposed override row agreed, row 5 included. Old commits of the public repo keep their history (`DECISIONS.md` items 21 to 23).
- 2026-11-15: "ok move forward". Lo-Fi League is next in Release 4, the standards catch-up.
- 2026-11-14: Name is Lo-Fi League. Soccer. Godot.
- 2026-11-14: 7 a side. Low-poly 3D with a side camera. "Lo-fi" means music and mood. First build is exhibition only.
- 2026-11-14: Use best judgment for the first MVP. BC tests and gives feedback.
- 2026-11-14: Deeper greens on the pitch.
- 2026-11-14: v0.2.0 scope is League mode only. Pillars confirmed as written.
- 2026-11-14: Run an end-to-end test and add QoL and feature ideas to the backlog.
- 2026-11-14: One public repo per game plus one private repo for the key (`game-signing`). One source for the standards and a shared kit in `game-standards`. Version line under the buttons on every game page: `Version <version>. Release notes · Backlog · Source on GitHub`, with no description.
- 2026-11-14: Create the repo in the browser and push the game.
- 2026-11-14: Fetch `wandervalley.jks` from `keeper-of-the-hollow-source` and sign with it.
- 2026-11-14: G4.1, G4.4, G7.1 and things to find (G4.3, G7.2) do not apply to sports games or where they clearly do not make sense. Override rows 1 to 3 agreed.

## Judgment calls made in v0.3.2 (BC to confirm or change)

1. Godot 4.6.3, the newest 4.6 patch, instead of 4.7. The engineering standard says Godot 4.6, so no override is needed. 4.6.3 alone does not fix the crash.
2. A patch number (v0.3.2) for the send fix and the engine change only. No other change rides along.
3. The cause comes from reading Godot's source, not from a crash on the test machine. BC's Retroid test is the real proof.

## Judgment calls made in v0.3.1 (BC to confirm or change)

1. A patch number (v0.3.1) for a sound fix only. No other change rides along.
2. The engineering rule Home by Dusk proposed (E6.8: buses come from `default_bus_layout.tres`, never `AudioServer.add_bus()` at runtime, and every release measures real page sound) stays Proposed. Not in force until BC approves it.
3. The sound test lives in this game's `tests/` for now, not in the shared kit. Moving it to the kit is a kit change for BC to approve.
4. The sound test checks one moment: the first click and Enter on the title card. It does not walk every area.

## Judgment calls made in v0.3.0 (BC to confirm or change)

1. Opponent Easy, Normal and Hard scale only the computer side's speed, tackling and shooting (0.9, 1.0 and 1.08). The simulated league matches stay the same.
2. A new player on a touch screen starts with Text size Larger, as v0.2.3 started with Large. The old Text, Sound and Music choices move to Settings.
3. Title in a league match keeps its own one-time question (`Press again to quit. It will not count`), because a quit league match is never recorded. Restart match and Start over use the kit second press.
4. Screen shake and Reduce motion stay hidden in Settings: the game has neither.
5. `tests/e2e_test.py` was removed from the source: no end-to-end runs in this project. It stays in the public repo's history.
6. The title card got its own Settings button next to `Slot <number>`, as Tiny Titans Football has.
7. Rumble buzzes strong when you score, soft when you concede and soft when your tackle wins or loses the ball.

## Judgment calls made in v0.2.1 (BC to confirm or change)

1. Fixed the two save bugs as v0.2.1 before any new feature (G3.5).
2. Removed every copy of the standards and other games' files from `handoff/`. They now come from `game-standards`.
3. Switched the save and the browser test bridge to the shared kit now. The rest of the game code is unchanged.
4. Touch controls now hide on key or gamepad input (E5.4).
5. The physics engine setting went back to Godot's default. The game uses no physics bodies (override row 5, Proposed).

## Judgment calls made in v0.2.0 (BC to confirm or change)

1. Single round robin: 7 matchdays, so a season takes about 45 minutes of play.
2. Other matches are simulated from each club's average player ratings, not played by the match engine.
3. Ties in the table are split by goal difference, then goals scored, then club name.
4. Two new clubs were added to reach 8. Their players are new and fictional.
5. Quitting a league match never records it. Restart match replays the same fixture.
6. Start over needs two presses. New season appears only when a season is over.
7. Your club always attacks to the right. Home and away change nothing yet (idea 26).
8. Best finish and titles are personal records only. No leaderboards.

## Judgment calls made in v0.1.0 (BC to confirm or change)

1. Fictional clubs replace the real countries and clubs in the reference. The reference zip stays out of the repo.
2. "Things to find" (G4.3 and G7.2) is listed under Not in use in `STANDARDS_OVERRIDES.md`. Confirmed by BC.
3. Two 3-minute halves. Teams do not switch ends.
4. No offside, fouls or cards.
5. Pass goes to the teammate nearest the direction you aim. Control follows the ball.
6. Throw-ins and corners: you stand still and choose a short pass (Space) or a long ball (F).
7. Keepers are always computer controlled.
8. The kit clash check swaps the computer club to its away kit.
9. v0.1.1 keeps the same game as v0.1.0. Only the version and the signature changed.
10. The first push holds the full game, the v0.1.0 build and the APK, and the standards files with the four override rows still Proposed.

## v0.4.0 (2026-11-17, Release 6)

- Shipped: the shared start screen (G5.21, kit 1.10.0) with this game's own painted scene (`scripts/title_art.gd`). Continue only when there is something to continue, Play opens the slot list, Settings, Quit off the web. Long key lists, tips and credits left the start screen.

### Judgment calls in v0.4.0 (BC to confirm)

1. The controls line on the start screen is cut to the main keys and buttons. How to play keeps the full list.
2. The Game Shelf card shows the new start screen in place of a play picture.
3. Play, then a slot, leads to a new How do you want to play screen. Continue goes straight there for the slot in use. B goes back to the title card.
