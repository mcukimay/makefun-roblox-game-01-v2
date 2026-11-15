# Milo's Mole Dig — a Roblox obby for make.fun roblox-game-01

Milo the mole is trapped at the bottom of a mine. Climb 24 stages of
platforms, beams, lava, moving platforms, crumbling blocks, spinning bars and
jump pads to reach the sunlight — and the gold pad at the top.

## How to play

- **Move**: WASD / arrow keys. **Jump**: Space.
- **Green pads** are checkpoints — touch one and you respawn there when you die.
- **Gold coins** spin in the air; touch them to collect. They come back after 45 seconds.
- **Red lava** and **red spinning bars** kill you. So does falling off the tower.
- **Cyan pads** launch you high. **Purple platforms** glide back and forth — ride them across gaps.
- **Brown blocks** crumble half a second after you step on them. Don't linger.
- Reach the **gold pad at the top** to stop your timer. Your best time is saved.
- **PLAY AGAIN** on the win screen restarts the climb from stage 0.

The HUD (top right) shows your stage, coins, live timer and best time.
The leaderboard (leaderstats) tracks Stage, Coins and Deaths.

## Top-times leaderboard

A board in the lobby — on the deck behind the spawn, past the intro sign —
shows the 10 fastest escapes. Finishing with a new personal best writes your
time to the `MiloTopTimes_v1` OrderedDataStore (stored negated, so the
fastest run ranks first); the board refreshes every 60 seconds, after every
win, and when a player joins. Player names are resolved through
`Players:GetNameFromUserIdAsync` and cached. If DataStores are unavailable
(e.g. a Studio playtest with API access off) the board shows a placeholder
and the game plays on.

## Structure

- `default.project.json` — Rojo project: DataModel, lighting, baseplate, `src/server` under ServerScriptService, `src/client` under StarterPlayerScripts.
- `src/server/TowerData.luau` — the tower's shape: 24 stages, heights, spiral positions, colour themes. The single source of truth for layout.
- `src/server/TowerBuilder.luau` — builds every part from TowerData and returns a report (coins, killers, movers, spinners, crumblers, jump pads, win pad).
- `src/server/ObstacleRunner.luau` — animates: TweenService movers, one Heartbeat loop for coin spins and spinner bars, event-driven crumbling blocks.
- `src/server/GameServer.luau` — the rules and the only holder of player state: checkpoints, coins, timer, win/lose, leaderstats, DataStore best time (pcall-guarded), RemoteEvents.
- `src/server/Leaderboards.luau` — lobby top-times board: OrderedDataStore `MiloTopTimes_v1`, pcall-guarded reads/writes, refresh every 60s / on win / on join.
- `src/server/Main.server.luau` — entry point: build, animate, start.
- `src/client/Hud.client.luau` — stage / coins / timer / best HUD, toasts, win screen, play-again.
- `src/client/Effects.client.luau` — client-only feedback bursts (coin pickup, win confetti).
- `main.ts` — hands the entry in: copies game.rbxl, src/, screenshots/, PLAY.json to /output and writes dossier.json.
- `vendor/makefun-roblox.ts` — the kit's library, unchanged.

## Build

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Still needed from the user (Roblox Studio, Windows)

Studio does not run on the Linux build box, so these steps are still open:

1. Open this folder in Roblox Studio (Rojo plugin or `rojo serve`, or open `game.rbxl` directly).
2. Play-test: spawn, climb a few stages, die on lava, check the checkpoint respawn, grab a coin, reach the top.
3. Take 3–4 screenshots **while the game is running**: the start area (Milo statue + sign), mid-climb (a mover or spinner stage), and the win platform. Save them as `screenshots/1-start.png`, `2-play.png`, `3-end.png` (first by name is the cover; each ≤ 256 KiB, long side ≤ 1280, short side ≥ 480).
4. Publish as a **Public** experience from an account created before the bounty opened (2026-11-15 12:00Z).
5. Fill in `PLAY.json` with the real ids: `{"url": "https://www.roblox.com/games/<placeId>", "place_id": <placeId>, "universe_id": <universeId>}` — universe_id is the number after `experiences/` on the Creator Dashboard (or `game.GameId` in Studio).
6. Send the screenshots + ids back so the entry can be bundled and submitted before entries close (2026-11-15 18:00Z / 2026-11-16 01:00 WIB).
