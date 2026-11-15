#!/usr/bin/env python3
# v0.2.3 quality of life checks in the browser (headless Chrome with a touch screen, like a phone):
#   1. Text size: Large by default on a touch screen, Text in the Menu switches it and it is saved.
#   2. Touch still moves the player with Large text.
#   3. A match pauses itself when the game loses focus.
#   4. The game remembers the last mode and club: they have the focus next time.
#   5. Quit to title in a league match needs a second press.
#   6. The full time screen lists the goal scorers with the minute.
# usage: qol_test.py [web build folder] [shots folder]
import asyncio, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))
from webkit import Run, serve   # shared kit (G10)
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/lofi-out/web"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/lofi-out/shots_qol"
TITLE, TEAMS, RESTART, LIVE, GOAL, HALFTIME, OVER = range(7)
MODES, LEAGUE = 20, 21

async def main():
    with serve(OUT, 8796) as base:
        async with Run("lofi", SHOTS, 915, 412) as r:   # a phone held sideways
            st, key, cmd, check, shot = r.state, r.key, r.cmd, r.check, r.shot
            await r.open(base + "index.html?test")
            s = await r.wait_phase([TITLE], 90); await r.page.wait_for_timeout(2500); await shot("q1_title_large")
            check(s.get("text_large") is True, "text is Large by default on a touch screen")

            # practice with the second club, then back to the title
            await key("Enter"); await r.wait_phase([MODES])
            await key("ArrowDown"); await key("ArrowDown"); await key("Enter"); await r.wait_phase([TEAMS])
            await key("ArrowRight"); s = await st(); club = s.get("focus", "").split("|")[-1]
            await key("Enter"); s = await r.wait_for(lambda s: s["phase"] == LIVE and s["ctrl"] and s["practice"], 30, "practice is live")
            check(bool(s.get("practice")), "practice started with %s" % club)

            # touch moves the player with Large text
            x0 = s["ctrl"][0]
            cdp = await r.touch_drag(150, 300, 230, 300, 2500); s = await st(); await shot("q2_touch_large"); await r.touch_end(cdp)
            check(s["ctrl"] and s["ctrl"][0] > x0 + 0.5, "a touch drag to the right moves the player with Large text (x %.1f -> %.1f)" % (x0, s["ctrl"][0] if s["ctrl"] else -99))

            # the match pauses itself when the game loses focus
            await r.page.evaluate("() => { const c = document.querySelector('canvas'); c.dispatchEvent(new Event('blur')); window.dispatchEvent(new Event('blur')); }")
            s = await r.wait_for(lambda s: s["menu"], 10, "the Menu opening after a focus loss"); await shot("q3_paused_on_blur")
            check(s.get("menu") is True and s.get("paused") is True, "losing focus opens the Menu and pauses the match")
            await r.page.evaluate("() => { const c = document.querySelector('canvas'); c.focus(); c.dispatchEvent(new Event('focus')); }")

            # Text in the Menu switches the size and saves it
            # each command lands within a frame or two, so wait for the result instead of reading it at once
            await cmd("text"); s = await r.wait_for(lambda s: s["text_large"] is False, 10, "Normal text"); await shot("q4_menu_normal_text")
            check(s.get("text_large") is False, "Text in the Menu switches to Normal")
            await cmd("text"); s = await r.wait_for(lambda s: s["text_large"] is True, 10, "Large text")
            check(s.get("text_large") is True, "Text in the Menu switches back to Large")
            await cmd("text"); await r.wait_for(lambda s: s["text_large"] is False, 10, "Normal text again")   # leave it on Normal, to check it is remembered after a reload
            await cmd("resume"); await cmd("title"); await r.wait_phase([TITLE])

            # the last mode and club have the focus
            await key("Enter"); await r.wait_phase([MODES]); await r.page.wait_for_timeout(600); s = await st()
            check(s.get("focus", "").startswith("mode_practice"), "the last mode played has the focus (%s)" % s.get("focus"))
            await key("Enter"); await r.wait_phase([TEAMS]); await r.page.wait_for_timeout(600); s = await st()
            check(s.get("focus", "").endswith("|" + club), "the last club played has the focus (%s, wanted %s)" % (s.get("focus"), club))
            await cmd("team_back"); await r.wait_phase([MODES])

            # league: one press of Quit to title only asks
            await cmd("mode_league"); s = await r.wait_phase([TEAMS, LEAGUE])
            if s["phase"] == TEAMS: await key("Enter"); s = await r.wait_phase([LEAGUE])
            await key("Enter"); s = await r.wait_for(lambda s: s["phase"] in (RESTART, LIVE) and s["mode"] == "league", 30, "league match")
            md0 = s["league_md"]
            await key("Escape"); await cmd("title"); s = await r.wait_for(lambda s: s.get("quit_armed"), 10, "the quit check"); await shot("q5_quit_check")
            check(s["phase"] in (RESTART, LIVE) and s.get("quit_armed") is True, "one press of Quit to title in a league match only asks")
            await cmd("title"); s = await r.wait_phase([TITLE])
            check(s["league_md"] == md0, "the second press quits and the match does not count")

            # exhibition: a goal, then full time lists the scorer and minute
            await key("Enter"); await r.wait_phase([MODES]); await cmd("mode_exhibition"); await r.wait_phase([TEAMS])
            await key("Enter"); s = await r.wait_for(lambda s: s["phase"] == LIVE and s["ctrl"], 30, "exhibition is live")
            await cmd("test_goal"); s = await r.wait_for(lambda s: s["goals"] >= 1, 10, "the goal")
            await r.wait_for(lambda s: s["phase"] == LIVE, 30, "play after the goal")
            await cmd("end_match"); s = await r.wait_phase([OVER], 40); await r.page.wait_for_timeout(900); await shot("q6_full_time_scorers")
            txt = s.get("over_text", "")
            check(": " in txt and "'" in txt, "full time lists the scorer and the minute (%r)" % txt.split("\n")[2:3])

            # the Normal text choice is saved
            await r.wait_saved('"text":0')
            await r.page.reload(); s = await r.wait_phase([TITLE], 90)
            check(s.get("text_large") is False, "the text size choice survives a reload")
    print(r.report())

asyncio.run(main())
