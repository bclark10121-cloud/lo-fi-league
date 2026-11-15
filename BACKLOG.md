# Lo-Fi League: backlog

Updated 2026-11-14 for v0.2.0. Brian decides the order.

## Done

- Reviewed the game standards, the Keeper of the Hollow overrides and the reference team editor. Name check for "Lo-Fi League".
- Plan written: `PLAN.md`.
- Adopted the shared game standards of 2026-11-14 (`handoff/GAME_STANDARDS.md`) and wrote `STANDARDS_OVERRIDES.md`.
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
- Deeper greens on the pitch (Brian, 2026-11-14).
- Public repo `bclark10121-cloud/lo-fi-league` created and the game page turned on (Brian, 2026-11-14).
- v0.1.1: APK signed with the real key `wandervalley.jks` (Brian, 2026-11-14). Version code 2.
- v0.2.0: League mode (idea 1). 8 clubs, 7 matchday round robin, standings table, simulated other matches, season saved on the device, champions and best finish at season end.
- v0.2.0: two new clubs, Lamplight Wanderers and Window Seat Albion.
- v0.2.0: mode screen (Exhibition, League, Practice) and a Back button on the club screen.
- v0.2.0: test gate adds league rules checks, a full bot season and a league walk in the browser test.
- Pillars confirmed by Brian (2026-11-14).

## Now

- Brian plays v0.2.0 and reports how the league and the matches feel.

## Asked for by Brian, not built yet

Nothing open.

## Ideas to choose from (Brian picks by number)

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
15. Difficulty levels and match length setting.
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

## Later

- Google Play release.
- Online play.

## Not planned

- Real league, club, country or player names.
- Any art, text or numbers copied from Pixel Cup Soccer or another game.
- Injuries and red cards (they break pillar 2).

## Decisions from Brian

- 2026-11-14: Name is Lo-Fi League. Soccer. Godot.
- 2026-11-14: 7 a side. Low-poly 3D with a side camera. "Lo-fi" means music and mood. First build is exhibition only.
- 2026-11-14: Use best judgment for the first MVP. Brian tests and gives feedback.
- 2026-11-14: Deeper greens on the pitch.
- 2026-11-14: v0.2.0 scope is League mode only. Pillars confirmed as written.
- 2026-11-14: Create the repo in the browser and push the game.
- 2026-11-14: Fetch `wandervalley.jks` from `keeper-of-the-hollow-source` and sign with it.
- 2026-11-14: G4.1, G4.4, G7.1 and things to find (G4.3, G7.2) do not apply to sports games or where they clearly do not make sense. Override rows 1 to 3 agreed.

## Judgment calls made in v0.2.0 (Brian to confirm or change)

1. Single round robin: 7 matchdays, so a season takes about 45 minutes of play.
2. Other matches are simulated from each club's average player ratings, not played by the match engine.
3. Ties in the table are split by goal difference, then goals scored, then club name.
4. Two new clubs were added to reach 8. Their players are new and fictional.
5. Quitting a league match never records it. Restart match replays the same fixture.
6. Start over needs two presses. New season appears only when a season is over.
7. Your club always attacks to the right. Home and away change nothing yet (idea 26).
8. Best finish and titles are personal records only. No leaderboards.

## Judgment calls made in v0.1.0 (Brian to confirm or change)

1. Fictional clubs replace the real countries and clubs in the reference. The reference zip stays out of the repo.
2. "Things to find" (G4.3 and G7.2) is listed under Not in use in `STANDARDS_OVERRIDES.md`. Confirmed by Brian.
3. Two 3-minute halves. Teams do not switch ends.
4. No offside, fouls or cards.
5. Pass goes to the teammate nearest the direction you aim. Control follows the ball.
6. Throw-ins and corners: you stand still and choose a short pass (Space) or a long ball (F).
7. Keepers are always computer controlled.
8. The kit clash check swaps the computer club to its away kit.
9. v0.1.1 keeps the same game as v0.1.0. Only the version and the signature changed.
10. The first push holds the full game, the v0.1.0 build and the APK, and the standards files with the four override rows still Proposed.
