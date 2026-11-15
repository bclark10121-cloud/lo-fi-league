#!/usr/bin/env python3
# Browser check: the page loads with no errors, the title shows, a league season starts, one league match is played
# to full time and recorded, then an exhibition match: the player dribbles, passes, shoots and puts the ball out for
# a throw-in, the menu opens and touch controls appear. Last, a reload proves the season saved on the device.
# window.lofi_cmd runs one menu action in ?test mode only (end_match ends the match).
# The game reports its state to the page (?test) as window.lofi, so the test waits for each state instead of guessing times (G7.6).
# usage: web_test.py [web build folder] [shots folder]
import asyncio, sys, subprocess, time, os
from playwright.async_api import async_playwright
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/lofi-out/web"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/lofi-out/shots"
os.makedirs(SHOTS, exist_ok=True)
errs = []; notes = []
TITLE, TEAMS, RESTART, LIVE, GOAL, HALFTIME, OVER = range(7)
MODES, LEAGUE = 20, 21

async def main():
    srv = subprocess.Popen([sys.executable, "-m", "http.server", "8793", "--bind", "127.0.0.1"], cwd=OUT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); time.sleep(1)
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(executable_path="/usr/bin/google-chrome", args=["--no-sandbox", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--autoplay-policy=no-user-gesture-required"])
            ctx = await b.new_context(viewport={"width": 1280, "height": 720}, has_touch=True)
            pg = await ctx.new_page()
            pg.on("pageerror", lambda e: errs.append("page: " + str(e)))
            pg.on("console", lambda m: errs.append("console: " + m.text) if m.type == "error" else None)
            await pg.goto("http://127.0.0.1:8793/index.html?test")
            async def st(): return await pg.evaluate("window.lofi || null")
            async def wait_phase(phases, secs=40):
                t = time.time()
                while time.time() - t < secs:
                    s = await st()
                    if s and s["phase"] in phases: return s
                    await pg.wait_for_timeout(120)
                errs.append("timeout waiting for %s, got %s" % (phases, await st())); return await st()
            async def wait_for(fn, secs, what):
                t = time.time()
                while time.time() - t < secs:
                    s = await st()
                    if s and fn(s): return s
                    await pg.wait_for_timeout(120)
                notes.append("did not see: " + what); return await st()
            async def shot(n): await pg.screenshot(path=SHOTS + "/" + n + ".png")
            async def key(k, wait=400): await pg.keyboard.press(k); await pg.wait_for_timeout(wait)
            await wait_phase([TITLE], 90); await pg.wait_for_timeout(2500); await shot("01_title")
            async def cmd(c, wait=500): await pg.evaluate("window.lofi_cmd = '%s'" % c); await pg.wait_for_timeout(wait)
            await key("Enter"); await wait_phase([MODES]); await pg.wait_for_timeout(700); await shot("02_modes")
            # league: start a season, play matchday 1 to full time, back to the table
            await key("ArrowDown", 300); await key("Enter"); await wait_phase([TEAMS]); await pg.wait_for_timeout(700); await shot("03_league_clubs")
            await key("Enter"); s = await wait_phase([LEAGUE]); await pg.wait_for_timeout(900); await shot("04_league_table")
            notes.append("season started club=%s md=%s" % (s["league_club"], s["league_md"]))
            await key("Enter"); s = await wait_phase([LIVE], 40); notes.append("league match mode=%s" % s["mode"]); await pg.wait_for_timeout(1200); await shot("05_league_match")
            await cmd("end_match"); s = await wait_phase([OVER], 40); await pg.wait_for_timeout(900); await shot("06_league_full_time")
            notes.append("after matchday md=%s results=%s" % (s["league_md"], s["league_results"]))
            if s["league_md"] != 1 or s["league_results"] != 1: errs.append("league match was not recorded: %s" % s)
            await key("Enter"); await wait_phase([LEAGUE]); await pg.wait_for_timeout(900); await shot("07_league_after")
            # exhibition
            await cmd("league_back"); await wait_phase([MODES])
            await key("Enter"); await wait_phase([TEAMS]); await pg.wait_for_timeout(700); await shot("08_clubs")
            await key("Enter"); await wait_phase([RESTART, LIVE]); await pg.wait_for_timeout(500); await shot("09_kickoff")
            s = await wait_for(lambda s: s["phase"] == LIVE and s["mine"], 20, "player has the ball at kickoff")
            # dribble forward
            x0 = s["ctrl"][0] if s and s["ctrl"] else 0
            await pg.keyboard.down("d"); await pg.wait_for_timeout(1500); await shot("10_dribble")
            s = await st(); notes.append("dribble moved x %.1f -> %.1f" % (x0, s["ctrl"][0] if s["ctrl"] else -99))
            await pg.keyboard.up("d")
            # pass
            if s["mine"]:
                await key("Space", 600); s2 = await st(); notes.append("after pass carrier=%s mine=%s" % (s2["carrier"], s2["mine"])); await shot("11_pass")
            # get the ball again and shoot
            await pg.keyboard.down("d"); await pg.keyboard.down("Shift")
            s = await wait_for(lambda s: s["phase"] == LIVE and s["mine"] and s["ball"][0] > 6, 25, "player carrying the ball in the other half")
            await pg.keyboard.up("Shift")
            sh0 = s["shots"][0]
            await pg.keyboard.down("f"); await pg.wait_for_timeout(450); await shot("12_shot_meter"); await pg.keyboard.up("f"); await pg.wait_for_timeout(350); await shot("13_shot")
            await pg.keyboard.up("d")
            s = await st(); notes.append("shots %d -> %d" % (sh0, s["shots"][0]))
            await pg.wait_for_timeout(2500); await shot("14_after_shot")
            # defend: switch and tackle keys must not error
            await key("Space", 300); await key("f", 300)
            # put the ball out over the far sideline for a throw-in
            for i in range(4):
                s = await wait_for(lambda s: s["phase"] == LIVE and s["mine"], 30, "player has the ball again")
                if not (s and s["mine"]): break
                await pg.keyboard.down("w")
                s = await wait_for(lambda s: s["counts"]["throw"] > 0 or not s["mine"], 12, "ball out or lost")
                await pg.keyboard.up("w")
                if s and s["counts"]["throw"] > 0: break
            s = await st(); notes.append("counts %s score %s" % (s["counts"], s["score"])); await pg.wait_for_timeout(600); await shot("15_throw_in")
            await key("Escape", 700); s = await st(); notes.append("menu=%s paused=%s" % (s["menu"], s["paused"])); await shot("16_menu")
            await key("Escape", 400)
            cdp = await ctx.new_cdp_session(pg)
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": 200, "y": 500, "id": 1}]})
            await pg.wait_for_timeout(300)
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": 250, "y": 470, "id": 1}]})
            await pg.wait_for_timeout(1200); s = await st(); notes.append("touch=%s" % s["touch"]); await shot("17_touch")
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
            # the season must survive a reload
            await pg.goto("http://127.0.0.1:8793/index.html?test"); s = await wait_phase([TITLE], 90)
            notes.append("after reload md=%s club=%s" % (s["league_md"], s["league_club"]))
            if s["league_md"] != 1: errs.append("season did not survive a reload: %s" % s)
            await key("Enter"); await wait_phase([MODES]); await pg.wait_for_timeout(700); await shot("18_modes_after_reload")
            await b.close()
    finally:
        srv.kill()
    print("notes", notes); print("errors", errs)
asyncio.run(main())
