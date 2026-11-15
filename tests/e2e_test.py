#!/usr/bin/env python3
# End-to-end test of a Lo-Fi League game page and browser build (G7.3, G7.4). Uses the shared kit in tests/common.
# 1. Game page: shared page check (links, screenshots, version line under the name, APK and release notes links).
# 2. League: start a season, Restart match and Quit to title never record, play all 7 matchdays,
#    season end, New season, Start over (one press does nothing, two presses start over),
#    a reload right after a match keeps the season and the records.
# 3. Practice: one keeper, the clock stays at 0.  Exhibition: full time, Play again, never touches the league.
# 4. Menu: How to play, Sound and Music.  Phone-size screens at 915 x 412. Touch controls hide on a key press (E5.4).
# Matches are ended with the ?test-only action end_match, so this does not test match feel.
# usage: e2e_test.py [game page url] [shots folder]
import asyncio, os, sys, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))
from webkit import Run
from page_check import check_page
PAGE = sys.argv[1] if len(sys.argv) > 1 else "https://bclark10121-cloud.github.io/lo-fi-league/"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/lofi-e2e"
TITLE, TEAMS, RESTART, LIVE, GOAL, HALFTIME, OVER = range(7)
MODES, LEAGUE = 20, 21

async def main():
    page_checks, page_errs = await check_page(PAGE, SHOTS)
    async with Run("lofi", SHOTS) as r:
        r.checks += page_checks; r.errs += page_errs
        st, wait_phase, shot, key, cmd, check = r.state, r.wait_phase, r.shot, r.key, r.cmd, r.check
        pg = r.page; ctx = r.ctx
        play = PAGE + "play/index.html?test"
        await r.open(play)
        async def to_league_from_title():
            await key("Enter"); await wait_phase([MODES]); await key("ArrowDown"); await key("Enter")
            return await wait_phase([LEAGUE, TEAMS])
        t0 = time.time()
        await wait_phase([TITLE], 120); await pg.wait_for_timeout(1500); await shot("01_title")
        r.notes.append("load to title %.1fs" % (time.time() - t0))
        s = await to_league_from_title()
        check(s["phase"] == TEAMS and s["league_md"] == -1, "a fresh device has no season and goes to the club picker")
        await key("ArrowDown"); await key("Enter"); s = await wait_phase([LEAGUE])
        check(s["league_club"] == "rainy" and s["league_md"] == 0, "season 1 starts with Rainy Window United at matchday 1 (club %s md %s)" % (s["league_club"], s["league_md"]))
        await pg.wait_for_timeout(700); await shot("02_season1_start")
        # Restart match and Quit to title never record
        await key("Enter"); s = await wait_phase([LIVE])
        check(s["mode"] == "league", "Play matchday 1 starts a league match")
        await cmd("restart"); s = await wait_phase([LIVE]); await pg.wait_for_timeout(500); s = await st()
        check(s["mode"] == "league" and s["league_md"] == 0, "Restart match keeps the same fixture and records nothing")
        await cmd("title"); s = await wait_phase([TITLE])
        check(s["league_md"] == 0 and s["league_results"] == 0, "Quit to title during a league match records nothing")
        s = await to_league_from_title()
        check(s["phase"] == LEAGUE, "the League button goes straight back to the table mid-season")
        # all 7 matchdays
        for md in range(1, 8):
            await key("Enter"); await wait_phase([LIVE])
            if md == 3:
                await cmd("help", 700); await shot("03_help"); await cmd("help_close")
                await cmd("sound"); await cmd("music"); await cmd("sound"); await cmd("music")
            await cmd("end_match", 300); s = await wait_phase([OVER])
            check(s["league_md"] == md and s["league_results"] == md, "matchday %d recorded (md %s, results %s)" % (md, s["league_md"], s["league_results"]))
            if md in (1, 7): await pg.wait_for_timeout(700); await shot("04_full_time_md%d" % md)
            await key("Enter"); s = await wait_phase([LEAGUE])
            if md == 7: await pg.wait_for_timeout(900); await shot("05_season_over")
        check(s["league_md"] == 7, "season 1 is over after 7 matchdays")
        # New season
        await key("Enter"); s = await wait_phase([TEAMS])
        check(s["phase"] == TEAMS, "New season opens the club picker")
        await key("Enter"); s = await wait_phase([LEAGUE])
        check(s["league_md"] == 0 and s["league_results"] == 0 and s["league_club"] == "tapedeck", "season 2 starts at matchday 1 with Tape Deck Rovers")
        # Start over: one press does nothing, two presses start over
        await key("Enter"); await wait_phase([LIVE]); await cmd("end_match", 300); await wait_phase([OVER]); await key("Enter"); s = await wait_phase([LEAGUE])
        check(s["league_md"] == 1, "season 2 matchday 1 recorded")
        await key("ArrowRight"); await key("Enter", 600); s = await st(); await shot("06_start_over_armed")
        check(s["phase"] == LEAGUE and s["league_md"] == 1, "one press of Start over changes nothing")
        await key("Enter", 600); s = await wait_phase([TEAMS])
        check(s["league_md"] == -1, "a second press of Start over clears the season and opens the club picker")
        await key("ArrowRight"); await key("Enter"); s = await wait_phase([LEAGUE])
        check(s["league_club"] == "vinyl" and s["league_md"] == 0, "a fresh season starts with Midnight Vinyl FC")
        await key("Enter"); await wait_phase([LIVE]); await cmd("end_match", 300); await wait_phase([OVER]); await key("Enter"); await wait_phase([LEAGUE])
        # reload keeps the season. Wait until the save reaches browser storage first: headless Chrome draws 1 or 2
        # frames a second and Godot syncs over many frames (about half a second on a real device)
        took = await r.wait_saved(['"club":"vinyl"', '"md":1,', '"seasons":1'])
        r.notes.append("save reached browser storage in %.0fs" % took)
        await pg.goto(play); s = await wait_phase([TITLE], 120)
        check(s["league_md"] == 1 and s["league_club"] == "vinyl", "a reload right after a match keeps the season (md %s club %s)" % (s["league_md"], s["league_club"]))
        check(s["seasons"] == 1 and s["best_finish"] > 0, "a reload keeps the records: seasons %s, best finish %s" % (s["seasons"], s["best_finish"]))
        # ---------- 3. practice and exhibition ----------
        await key("Enter"); await wait_phase([MODES]); await pg.wait_for_timeout(500); await shot("07_modes")
        await key("ArrowDown"); await key("ArrowDown"); await key("Enter"); await wait_phase([TEAMS]); await key("Enter")
        s = await wait_phase([LIVE]); await pg.wait_for_timeout(3000); s = await st(); await shot("08_practice")
        check(s["practice"] and s["mode"] == "practice" and s["clock"] == 0, "practice runs with no clock (clock %s)" % s["clock"])
        await cmd("title"); await wait_phase([TITLE]); await key("Enter"); await wait_phase([MODES]); await key("Enter"); await wait_phase([TEAMS]); await key("Enter")
        s = await wait_phase([LIVE]); await pg.keyboard.down("d"); await pg.wait_for_timeout(1500); await pg.keyboard.up("d"); await shot("09_exhibition")
        await cmd("end_match", 300); s = await wait_phase([OVER]); await pg.wait_for_timeout(700); await shot("10_exhibition_full_time")
        check(s["mode"] == "exhibition" and s["league_md"] == 1, "an exhibition match never touches the league (md %s)" % s["league_md"])
        await key("Enter"); s = await wait_phase([LIVE])
        check(s["mode"] == "exhibition", "Play again starts another exhibition match")
        await cmd("title"); await wait_phase([TITLE])
        # ---------- 4. phone-size screens ----------
        await pg.set_viewport_size({"width": 915, "height": 412}); await pg.wait_for_timeout(1200); await shot("11_phone_title")
        s = await to_league_from_title(); await pg.wait_for_timeout(900); await shot("12_phone_table")
        await key("Enter"); await wait_phase([LIVE]); await pg.wait_for_timeout(2000); await shot("13_phone_match")
        cdp = await r.touch_drag(150, 300, 190, 280)
        await shot("14_phone_touch"); await r.touch_end(cdp)
        s = await st(); shown = s["touch"]
        await key("d", 400); s = await st()
        check(shown and not s["touch"], "touch controls show on a touch and hide on a key press (E5.4)")
        await cmd("title"); await wait_phase([TITLE])
        r.notes.append("total %.0fs" % (time.time() - t0))
    print(r.report())
asyncio.run(main())
