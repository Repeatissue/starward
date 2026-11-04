# STARWARD: The Long Haul to Earth 2

[![Test & Build](https://github.com/Repeatissue/starward/actions/workflows/build.yml/badge.svg)](https://github.com/Repeatissue/starward/actions/workflows/build.yml)

**▶ Play in your browser: https://repeatissue.github.io/starward/** (desktop or phone)

A journey-survival roguelite built in **Godot 4.7** (GDScript). Design doc: [GAME_DESIGN_AND_PLAN.md](GAME_DESIGN_AND_PLAN.md).

Every push to `main` runs the balance sim and smoke test, exports Web/Windows/Linux builds (downloadable from each run on the Actions tab), and redeploys the browser version.

## Running it
1. Open Godot 4.7 → **Import** → choose this folder's `project.godot`.
2. Press **F5** (Run Project).

Headless balance simulator and smoke test (auto-plays 300 runs, then builds every screen):
```
godot --headless --path . res://tools/balance_sim.tscn
```

## Layout
```
core/            Simulation (no UI). These are autoloads, available everywhere by name.
  RNG.gd           Seeded randomness; every gameplay roll goes through here
  Data.gd          Loads JSON content from data/
  GameState.gd     The run: resources, crew, route, flags, save/load dict
  TravelSim.gd     Daily tick: movement, drain, health, arrivals
  EventEngine.gd   Picks events, checks requirements, applies effects
  SaveManager.gd   user://savegame.json
  Platform.gd      Steam / iOS wrapper (stubs until Phase 4/5)
data/            All content. Edit these to change the game, no code needed.
  items.json, backgrounds.json, sectors.json, events/*.json
ui/              UIKit (theme + widgets), BaseScreen, EventPopup
scenes/          Main.tscn + screens/ (menu, new run, outfitter, travel, report)
tools/           balance_sim (headless bot runs)
```
The UI is built in code (see `ui/UIKit.gd`), with 48px minimum touch targets so it ports to iOS.

## Writing events
Add an entry to `data/events/travel_events.json` (random, rolled during travel) or `node_events.json` (fired by a node's `"event"` id in `sectors.json`).

```json
{
  "id": "unique_id",
  "trigger": "travel",           // or "node"
  "sector": [1, 2],              // optional; omit for any sector
  "weight": 8,                   // relative chance
  "once": true,                  // default true; false = can repeat
  "requires": { "flag": "x" },   // optional, for the whole event
  "title": "...", "text": "...",
  "choices": [
    { "text": "...", "requires": { "role": "Medic", "resources": { "parts": 1 } },
      "effects": { "power": -5 }, "result": "..." },
    { "text": "...", "outcomes": [
        { "weight": 6, "effects": {}, "result": "Good" },
        { "weight": 4, "effects": { "hull": -20 }, "result": "Bad" } ] }
  ]
}
```
**Requirements:** `role`, `resources` (minimums), `flag`, `not_flag`.
**Effects:** any resource (`fuel food oxygen power hull parts credits`), `colonists`, `crew_health`, `crew_morale`, `injure_random`, `kill_random`, `set_flag`, `add_crew` `{name, role, trait}`, `days` (time passes without moving).
Always include at least one choice with no requirements. The balance sim reports an error if it finds an event with none.
