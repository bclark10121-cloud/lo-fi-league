#!/usr/bin/env python3
# Xbox controller check in the browser (G5.8, E5.4): a pretend Xbox controller (shared kit) plays from the title card
# through the menus into a match with no keyboard and no touch. The left stick moves the player, touch controls hide
# when the controller is used, View and Menu both open and close the Menu, and A picks the focused button.
# usage: pad_test.py [web build folder] [shots folder]
import asyncio, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))
from webkit import Run, serve   # shared kit (G10)
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/lofi-out/web"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/lofi-out/shots_pad"
TITLE, TEAMS, RESTART, LIVE, GOAL, HALFTIME, OVER = range(7)
MODES, LEAGUE = 20, 21

async def main():
    with serve(OUT, 8794) as base:
        async with Run("lofi", SHOTS) as r:
            await r.use_pad()
            await r.open(base + "index.html?test")
            await r.wait_phase([TITLE], 90); await r.page.wait_for_timeout(2500); await r.shot("p1_title")
            await r.pad("A"); s = await r.wait_phase([MODES], 20)
            r.check(s.get("phase") == MODES, "A on the title card opens the game modes")
            await r.pad("B"); s = await r.wait_phase([TITLE], 20)
            r.check(s.get("phase") == TITLE, "B on the game modes goes back to the title card")
            await r.pad("A"); s = await r.wait_phase([MODES], 20)
            await r.pad("A"); s = await r.wait_phase([TEAMS], 20)
            r.check(s.get("phase") == TEAMS, "A picks Exhibition and opens the club picker"); await r.shot("p2_clubs")
            await r.pad("A"); s = await r.wait_phase([RESTART, LIVE], 30)
            r.check(s.get("phase") in (RESTART, LIVE), "A picks a club and starts the match")
            s = await r.wait_for(lambda s: s["phase"] == LIVE and s["ctrl"], 30, "match is live")
            # touch controls show on a touch, then hide when the controller is used (E5.4)
            cdp = await r.touch_drag(200, 500, 260, 500, 600); await r.touch_end(cdp); await r.page.wait_for_timeout(800)
            s = await r.state(); r.check(bool(s.get("touch")), "touch controls show after a touch")
            s = await r.wait_for(lambda s: s["phase"] == LIVE and s["ctrl"], 30, "live play with a controlled player")
            x0 = s["ctrl"][0] if s.get("ctrl") else 0.0
            await r.pad_stick(1.0, 0.0, 2500); s = await r.state(); await r.shot("p3_stick")
            x1 = s["ctrl"][0] if s.get("ctrl") else -99.0
            r.check(x1 > x0 + 1.0, "the left stick moves the player (x %.1f -> %.1f)" % (x0, x1))
            r.check(not s.get("touch"), "touch controls hide when the controller is used")
            # View and Menu both toggle the Menu. A picks the focused button (Resume)
            await r.pad("VIEW"); s = await r.state(); await r.shot("p4_menu_view")
            r.check(s.get("menu") is True and s.get("paused") is True, "View opens the Menu and pauses")
            await r.pad("VIEW"); s = await r.state()
            r.check(s.get("menu") is False, "View closes the Menu")
            await r.pad("MENU"); s = await r.state()
            r.check(s.get("menu") is True, "Menu opens the Menu")
            # a focused button fires when A is let go, so wait for the result rather than read it at once
            await r.pad("A"); s = await r.wait_for(lambda s: s["menu"] is False, 10, "Resume closes the Menu")
            r.check(s.get("menu") is False and not s.get("paused"), "A picks Resume in the Menu")
            await r.pad("VIEW"); await r.pad("B"); s = await r.wait_for(lambda s: s["menu"] is False, 10, "B closes the Menu")
            r.check(s.get("menu") is False, "B closes the Menu")
            # full time: A picks the focused button
            await r.cmd("end_match"); s = await r.wait_phase([OVER], 40); await r.page.wait_for_timeout(900); await r.shot("p5_full_time")
            await r.pad("A"); s = await r.wait_for(lambda s: s["phase"] != OVER, 20, "A on the full time card")
            r.check(s.get("phase") != OVER, "A picks the focused button at full time (phase %s)" % s.get("phase"))
            await r.shot("p6_after")
    print(r.report())

asyncio.run(main())
