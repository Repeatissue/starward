# STARWARD: The Long Haul to Earth 2
*(working title)*

> A journey-survival game about getting a fragile colony ship across 40 light-years of hostile space to a new home, Earth 2. You manage supplies, keep the crew alive and make hard calls at every waypoint. Inspired by the **journey-management genre** that Oregon Trail started, with modern roguelite structure.

- **Platforms:** Steam (Windows / macOS / Linux / Steam Deck) first, **iOS** second
- **Engine:** Godot 4 (GDScript)
- **Target length:** 45–90 minutes per run, with high replayability
- **Price target:** $9.99–$14.99 on Steam, $4.99 premium on iOS (no ads, no IAP)

---

## 1. Research summary

### 1.1 The genre, and what competitors already do
| Game | What it does | What we learn |
|---|---|---|
| **Oregon Trail** (genre origin) | Travel, buy supplies at forts, set pace and rations, random hardships, the party dies one by one | The core loop works: **resource pressure + random events + a clear destination** |
| **Orion Trail** (Schell Games, 2015) | A comedic "Oregon Trail in space" with text events and stat-based choices | Already exists, so **we must not be a parody clone.** Its own developer cited FTL's text events and difficulty as an influence |
| **FTL: Faster Than Light** | Node-map travel, text events, permadeath, short runs | High stakes make every run feel like it matters. Node maps give players agency over the route |
| **Expedition Oregon** | Space resource-management sim | Mixed reviews (very few). A pure spreadsheet sim isn't enough; it needs **characters and story** |
| **The Oregon Trail (2021)** | A roguelite with unlocks that carry over between runs | Carry-over progress keeps players coming back after a failed run |

**Positioning:** Orion Trail is the comedy take and FTL is the combat take. **STARWARD is the *emotional, character-driven* take.** You care about your crew and your sleeping colonists, and arrival on Earth 2 feels earned. The tone is grounded sci-fi with moments of warmth and dark humour, not parody.

### 1.2 Engine choice: Godot 4
| Option | Pros | Cons |
|---|---|---|
| **Godot 4** ✅ | Free, no royalties, open source. Exports to Win/Mac/Linux/iOS from one project. Excellent 2D/UI tooling. **GodotSteam** plugin gives the full Steamworks API (achievements, cloud saves) | iOS export **requires a Mac + Xcode**. C# iOS export is still experimental, so **use GDScript** |
| Unity | Mature mobile pipeline, huge asset store | Heavier engine, licensing/pricing history makes it riskier for a solo dev |
| Web (Phaser/TS) + Capacitor/Electron | Fast UI iteration | Steam and iOS wrapping adds friction, so it feels less like a "real" game |

**Decision:** Godot 4, GDScript, 2D. The game is mostly UI, maps and illustrated events, which is exactly where Godot is strong.

### 1.3 Costs and store requirements
| Item | Cost | Notes |
|---|---|---|
| Steam Direct fee | **$100 per game** | Recoupable after the game earns $1,000. There is a waiting period after paying before you can release (verify the current rules in Steamworks docs) |
| Steam "Coming Soon" page | free | Put it up **as early as possible** to collect wishlists; wishlists drive launch visibility |
| Apple Developer Program | **$99 / year** | Required for App Store distribution (verify on developer.apple.com) |
| A Mac (for iOS builds) | $0–600 | A used Apple-silicon Mac mini, a borrowed Mac or a cloud Mac service. **Not needed until Phase 5** |
| Art / music / SFX | $0–2,000 | Can start with free CC0 assets (Kenney.nl, OpenGameArt) and commission key art later |

### 1.3b Apple TV (tvOS)
- **Status (Nov 2026):** Godot has no official tvOS export yet. Official support is in progress in [godotengine/godot PR #118332](https://github.com/godotengine/godot/pull/118332) ("Apple: Add tvOS platform support"). It is an open draft, last updated 28 Oct 2026, targeting milestone 4.x. It includes a tvOS exporter and controller support through SDL.
- **Our approach:** build the game so it's ready the day that support lands. Then a tvOS build is just another export preset (still made on a Mac with Xcode, like iOS).
- **Already done in the game:**
  - Every screen works with only arrows, select and back: a Siri Remote, gamepad or keyboard. `tools/nav_test` proves this on every CI run.
  - Modals trap focus, and there's a strong focus ring.
  - Title-safe margins on TV (preview with `STARWARD_TV=1`).
  - No Quit button on Apple platforms, and no hover-only information (each setting's effect is shown in its heading).
  - Free-text fields (the seed) are hidden on TV.
- **Fallbacks if the PR is delayed:** build Godot from the PR branch (a custom export template), or ship iPhone/iPad first and add Apple TV later.

### 1.4 Design rules for iOS from day one
To make the later iOS port cheap, build these into the Steam version from the start:
1. **Everything is clickable or tappable.** No hover-only info and no keyboard-only controls.
2. **Minimum touch target ~44 pt**, with large buttons and readable fonts.
3. **Layout scales** using Godot containers and anchors, and supports 16:9, 16:10 (Steam Deck) and iPhone/iPad ratios.
4. **Save anywhere / auto-save** on every waypoint, because mobile sessions get interrupted.
5. **Controller support** (Steam Deck) maps nicely to the same focus-based UI navigation.

---

## 2. Game concept

### 2.1 Premise
Year 2291. Earth is failing. The **Long Haul Initiative** sends private colony ships toward *Earth 2*, a newly confirmed habitable world orbiting a distant star. You are the captain of one small, second-hand ship: **5 waking crew** and **a cargo hold of colonists in cryosleep.** The trip runs through a chain of relay stations, uncharted systems and dangerous regions. Not every ship makes it.

**Your score is how many people you deliver alive to Earth 2, and in what condition.**

### 2.2 Core pillars
1. **Every choice costs something.** Fuel, food, air, time or a life.
2. **People, not numbers.** Named crew with traits, relationships and last words.
3. **The journey is the story.** Each run produces a story worth telling (and worth streaming).
4. **Short sessions, long legs.** A run is about an hour, with meaningful progress between runs.

---

## 3. Core gameplay loop

```
 ┌──► PLAN at a station (buy/sell, repair, recruit, pick next route)
 │        │
 │        ▼
 │    TRAVEL a leg (set thrust + rations; days tick; resources drain)
 │        │
 │        ▼
 │    EVENTS during travel (text choices, crises, discoveries)
 │        │
 │        ▼
 │    ARRIVE at a node (station, planet, anomaly, hazard, derelict)
 │        │
 └────────┘   ...repeat until Earth 2 or total loss
```

### 3.1 Genre mechanics, reimagined for space
| Classic genre mechanic | STARWARD version |
|---|---|
| Choose an occupation (banker/farmer) | **Captain background**: Ex-Navy, Corporate Pilot, Smuggler, Scientist, Preacher. Each changes starting credits, a perk and the **score multiplier** |
| General store at departure | **Orbital Dock Outfitter**: fuel cells, food packs, O₂ scrubbers, spare parts, med-kits, drones, trade goods |
| Pace (steady/strenuous/grueling) | **Thrust setting**: Cruise / Burn / Overdrive. Faster travel burns more fuel and stresses the hull and crew |
| Rations | **Ration level**: Full / Reduced / Starvation. It affects morale and health, and you can also lower cryo-pod power to save energy at a risk to colonists |
| River crossings | **Hazard crossings**: asteroid belts, ion storms, gravity wells. Choose to navigate manually, go around (costs days), pay a pilot or slingshot (risky, saves fuel) |
| Hunting minigame | **Salvage & mining minigame**: a short arcade sequence piloting a drone through debris to grab supplies. Works with mouse, controller and touch |
| Disease & injury | **Afflictions**: radiation sickness, void fever, bone loss, injuries, *deep-space psychosis* (morale based) |
| Forts / landmarks | **Relay stations & landmarks**: trading posts, a pirate haven, a religious waystation, an abandoned colony |
| Tombstones of past players | **Derelict beacons**: ships from your *previous failed runs* show up as derelicts you can salvage, with your old crew's final log |
| Final score | **Arrival report**: colonists alive, crew alive, cargo, days taken, background multiplier, plus the "ending" for your colony |

### 3.2 Resources (keep it to 7)
| Resource | Drains from | Runs out → |
|---|---|---|
| **Fuel** | Travel (more at higher thrust) | Adrift; must send a distress signal (events) |
| **Food** | Waking crew, daily | Starvation damage, morale crash |
| **Oxygen** | Crew + damaged hull leaks | Rapid crew death |
| **Power** | Cryo bay, systems, shields | Cryo pods start failing (colonists die) |
| **Hull** | Hazards, combat, overdrive | Ship destroyed (run over) |
| **Spare Parts** | Repairs | Can't fix breakdowns |
| **Credits** | Trading | Can't buy at stations |

### 3.3 Crew
- **5 crew members**, each with a **name, role, 1–2 traits and health/morale.**
- **Roles:** Pilot, Engineer, Medic, Scientist, Security. Each role unlocks event options (e.g., *[Engineer] Reroute the plasma conduit*).
- **Traits:** Brave, Coward, Optimist, Claustrophobic, Veteran, Gambler, and others. Traits colour events and dialogue.
- **Death is permanent.** Losing your only Medic matters. You can wake a colonist to replace crew, but they are untrained and leave an empty pod.

### 3.4 The route (node map)
- The trip is about **25–35 nodes** across **4 sectors**:
  1. **Sol Departure Zone**: safe, a tutorial in disguise
  2. **The Kuiper Frontier**: pirates, smugglers, the last cheap fuel
  3. **The Deep Dark**: long empty legs, anomalies, psychological events
  4. **The Approach**: Earth 2's system, with alien phenomena and a final hazard
- A branching map (like FTL) lets you choose **safe but long** or **short but dangerous** routes.
- **Seeded runs**, so players can share seeds. This is great for streamers and community challenges.

**As built (Phase 2):** each run generates a seeded map from `data/sectors.json`. Every sector is a few columns of 2-3 stops, joined at fixed hub stations (Ceres Relay, Nix Haven, Lantern Waystation) and ending at Earth 2. At each stop you pick from 2-3 next stops in a "Chart your course" panel. Each option shows its type, how many days away it is, a one-line summary, whether your supplies will be low on arrival, and where it leads. Hazards are shortcuts (3-4 days), stations are detours (5-7 days) where you can trade, derelicts offer salvage, and quiet space is a safe, steady leg. The choice takes a few seconds to read, but planning a route around fuel, food and the next station is the main skill in the game.

### 3.5 Events
- A data-driven event system (JSON or Godot Resources) so events are **easy to write in bulk.**
- **Target at launch: 150+ events.** Each has 2–4 choices, with role and trait gated options.
- Event types: discovery, crisis, trade, moral dilemma, crew drama, cryo-bay malfunction, distress call, alien phenomenon.
- **Event chains** play out across multiple nodes (e.g., a stowaway is found → becomes crew → betrays you or saves you).

### 3.6 Meta-progression (between runs)
- **Initiative Rank** goes up with each run's score and unlocks new captain backgrounds, ship hulls, starting perks and event pools.
- **Ship hulls:** *Mule* (balanced), *Ark-lite* (more cryo pods, slow), *Courier* (fast, tiny cargo), *Salvager* (better minigame).
- **Codex:** collects discovered anomalies, alien life and lore.
- Keep it **light**. A first-time player can still win; unlocks add variety, not raw power.

### 3.7 Difficulty (tuned to feel like the original trail games: hard)
The original Oregon Trail was hard because of steady pressure, not big set-pieces: disease (decided by pace and rations), broken wagon parts, prices that climbed at every fort, and never quite enough money. STARWARD uses the same levers:
- **Illness** is the steady killer. Every crew member has a small daily chance to fall sick. The odds rise with poor rations, hard thrust, low morale and poor health. Sick crew lose health every day until they recover, which happens faster with a Medic and Full rations.
- **Breakdowns** need spare parts. With no parts (or no Engineer) you lose days, and days cost supplies.
- **Prices rise** 25% per sector away from home.
- **Money is tight.** No captain can buy everything, so the Outfitter is a real decision.
- **Morale wears down** on the long voyage regardless of rations.

All the knobs are constants at the top of `core/TravelSim.gd` plus the credits in `data/backgrounds.json`. `tools/balance_sim` plays 200 runs per captain with two bots: one that picks choices at random and one that weighs them. The gap between the two shows how much decisions matter. Current tuning:

| Captain | Thinking bot wins | Random bot wins |
|---|---|---|
| Corporate Pilot (Easy) | ~79% | ~33% |
| Ex-Navy Officer (Medium) | ~60% | ~19% |
| Reformed Smuggler (Hard) | ~35% | ~6% |

(With the branching star map, route planning is now a big part of skill, so the gap between thoughtful and careless play is wide.)

Hazard, derelict and waypoint stops draw a random event from a pool each run (seeded), so no two journeys meet the same hazards. Travel pauses with a warning whenever fuel, food, oxygen or power drops below 3 days. Every gamble shows a hint of its risk.

Human players will do better than the thinking bot once they learn the game, but a careless run should usually fail.

### 3.8 Endings
Arrival triggers a colony epilogue based on who survived. Example: *"With no Scientist, the colony misidentified the native flora… the first winter was hard."* That gives **5–10 epilogue variants** to chase.

---

## 4. Art, audio, tone
- **Visual style:** 2D illustrated, *retro-futurist*, a limited colour palette (deep blues, amber terminal glow). Event screens use a single illustration with text, the way a book page would, which is cheap to produce and good-looking.
- **UI aesthetic:** the ship's computer terminal, with CRT scanlines (optional toggle for accessibility).
- **Audio:** ambient synth score, ship hums and alarm cues. Each sector has its own music layer.
- **Writing tone:** grounded and human, with dark humour. Think "what if the people on the trail could talk back."

---

## 5. Technical architecture (Godot 4)

```
res://
├── core/
│   ├── GameState.gd        # Autoload: resources, crew, day, seed, current node
│   ├── SaveManager.gd      # JSON saves; Steam Cloud on PC, iCloud later on iOS
│   ├── EventEngine.gd      # Loads event data, checks conditions, applies outcomes
│   ├── TravelSim.gd        # Daily tick: drain, afflictions, random event rolls
│   ├── RNG.gd              # Seeded RNG (deterministic runs)
│   └── Platform.gd         # Wrapper: Steam / iOS / none (achievements, cloud)
├── data/
│   ├── events/*.json       # All events (writer-friendly)
│   ├── items.json
│   ├── backgrounds.json
│   └── sectors.json
├── scenes/
│   ├── MainMenu.tscn
│   ├── Outfitter.tscn      # Shop
│   ├── StarMap.tscn        # Node map
│   ├── Travel.tscn         # Travel screen / ship view
│   ├── EventPopup.tscn
│   ├── SalvageMinigame.tscn
│   └── ArrivalReport.tscn
└── addons/godotsteam/      # Steamworks integration (PC only)
```

**Key principles**
- **Logic is separate from UI.** The simulation (`GameState`, `TravelSim`, `EventEngine`) has no UI code, so it is testable and portable.
- **Data-driven content.** You can add events without touching code.
- **A platform abstraction layer.** All Steam calls go through `Platform.gd`, so iOS builds simply swap the backend (Game Center for achievements).
- **Deterministic seeds.** The same seed gives the same map and event rolls, for sharing and debugging.
- **Testing:** use **GUT** (Godot Unit Test) for the simulation math, plus a "headless auto-play" script that runs 1,000 random runs to check balance (win rate, average day of death, most common cause of death).

---

## 6. Development plan

Rough timeline for a **solo developer working part-time (~10–15 hrs/week)**. Halve it if you're full-time.

### Phase 0: Pre-production (Weeks 1–2)
- [ ] Install Godot 4 (latest stable), set up a Git repo + GitHub (private)
- [ ] **Paper prototype**: play the loop with dice and a spreadsheet for 3 runs to check the resource math is tense
- [ ] Finalise the name. Check Steam/App Store for conflicts and that a domain/social handles are free
- [ ] Write a 1-page pitch + list of 30 event ideas

### Phase 1: Core prototype, "ugly but playable" (Weeks 3–8)
- [ ] `GameState` + resources + daily travel tick
- [ ] Outfitter shop (buy supplies before departure)
- [ ] Linear route of ~10 nodes (no branching yet)
- [ ] Event engine + 20 placeholder events
- [ ] Crew with health and death
- [ ] Win (arrive) / lose (all dead / hull destroyed) screens
- **Milestone:** a full run start-to-finish with placeholder boxes and text. **Is it fun yet? If not, iterate here before going further.**

### Phase 2: Systems depth (Weeks 9–16)
- [ ] Branching star map with 4 sectors + seeded generation
- [ ] Thrust & ration settings, afflictions, morale
- [ ] Crew roles + traits gating event choices
- [ ] Hazard crossings
- [ ] Salvage minigame (v1)
- [ ] Save/load + auto-save
- [ ] Headless balance simulator
- **Milestone:** "vertical slice" covering Sector 1–2 with real systems, ~50 events

### Phase 3: Content & identity (Weeks 17–28)
- [ ] Art direction locked: UI theme, 30+ event illustrations (commission or create)
- [ ] Music + SFX pass
- [ ] All 4 sectors, **150+ events**, event chains
- [ ] Captain backgrounds, ship hulls, meta-progression, codex
- [ ] Derelict beacons from previous runs
- [ ] Arrival epilogues
- **Steam store page goes live as "Coming Soon" here** (pay the $100, capsule art, trailer v1, screenshots) and starts collecting wishlists

### Phase 4: Steam release prep (Weeks 29–36)
- [ ] GodotSteam integration: achievements, Steam Cloud saves, rich presence
- [ ] Controller support + **Steam Deck verification** pass (font sizes, 1280×800)
- [ ] Settings: resolution, volume, text speed, colourblind-safe palette, scanline toggle
- [ ] Playtesting: friends → Discord community → Steam Playtest
- [ ] **Steam Next Fest demo** (Sector 1 only), a big wishlist driver
- [ ] Trailer v2, press kit, contact streamers/YouTubers (this genre streams well because chat can vote on choices)
- [ ] **Launch on Steam** 🚀

### Phase 5: iOS port (Weeks 37–46, post-launch)
- [ ] Get Mac access + Apple Developer account ($99/yr)
- [ ] Godot iOS export → Xcode → test on device via TestFlight
- [ ] Touch polish: safe areas (notch), haptics, portrait vs landscape decision
- [ ] Swap `Platform.gd` backend: Game Center achievements, iCloud saves
- [ ] App Store assets: screenshots for required device sizes, privacy "nutrition label" (aim for "Data Not Collected")
- [ ] Submit for App Review → **launch on iOS**

### Phase 6: Post-launch
- [ ] Bug fixes + balance patches from player data
- [ ] Free content update (new sector or new hull) to bring players back
- [ ] Possible **Twitch chat integration mode** (chat votes on event choices), a strong streamer hook
- [ ] Possible Android port (Godot exports there too)
- [ ] Possible **GBA "demake"** as a separate project (see below)

### GBA port (optional, post-launch)
Godot can't export to the Game Boy Advance, so a GBA version would be a **separate rewrite**, not a port. It is very doable, because STARWARD is menus, text and numbers:
- **Toolchain:** [Butano](https://github.com/GValiente/butano) (a modern C++ GBA engine on devkitARM) is the friendliest option. libtonc in C is the low-level alternative.
- **Reuse:** the `data/*.json` content can be converted to C++ tables with a build script, so the events and balance numbers stay identical. The game logic (`core/`) is small enough to port by hand.
- **Constraints:** a 240×160 screen (short event text, small pixel fonts), D-pad plus A/B/L/R/Start, 256 KB work RAM, and SRAM/flash saves.
- **Distribution:** a free or paid ROM on itch.io (runs on emulators and flash carts), and optionally a physical cartridge run through a homebrew publisher. It can't be sold on Steam or iOS as a GBA ROM.
- **When:** after the Steam version's content is locked, so you aren't maintaining two codebases while the design is still changing.

---

## 7. Risks & mitigations
| Risk | Mitigation |
|---|---|
| "It's just Orion Trail again" | A distinct serious/emotional tone, cryo-colonist stakes, a node map, derelicts from past runs, epilogues. Never use the "Oregon Trail" name or assets in marketing; describe it as a "journey-survival roguelite" |
| Too much writing for one person | Data-driven events, an event template, reusable outcome types. Consider a hired writer for a batch of events |
| Balance is too easy or too hard | Headless simulator + telemetry-free local stats + playtests. Target a **~30–40% win rate** for new players on the default difficulty |
| Scope creep | Phase 1 must be fun before adding anything. The feature list is frozen at Phase 3 |
| iOS export pain (Xcode/signing) | Keep plugins minimal, test an empty iOS export early (once you have Mac access), use GDScript only |
| Discoverability on Steam | Coming Soon page early, Next Fest demo, streamer outreach, seeds for community challenges |

---

## 8. Immediate next steps (this week)
1. Install **Godot 4** (latest stable) and do one tutorial ("Your first 2D game") to learn the editor.
2. Make a **spreadsheet prototype** of the resources and daily drain, and "play" 3 runs by hand.
3. Write **10 sample events** in the format below to find the game's voice.
4. Pick a final title.

### Sample event format
```json
{
  "id": "frozen_stowaway",
  "sector": [1, 2],
  "weight": 10,
  "title": "Something in Cargo Bay 3",
  "text": "The Engineer reports a heat signature behind the water tanks. It's a teenage girl, half-frozen, clutching a stolen ration bar.",
  "choices": [
    { "text": "Give her a bunk. One more mouth.", "effects": { "add_crew": "stowaway_mira", "food": -10 } },
    { "text": "Put her in an empty cryo pod.", "requires": { "role": "Medic" }, "effects": { "colonists": 1 } },
    { "text": "Leave her at the next station.", "effects": { "flag": "abandoned_mira", "morale": -5 } }
  ]
}
```

---

## Sources
- [Godot docs: Exporting for iOS](https://docs.godotengine.org/en/4.0/tutorials/export/exporting_for_ios.html) · [C# iOS note (4.2+ docs mirror)](https://godot-ja.readthedocs.io/ja/stable/tutorials/export/exporting_for_ios.html) · [Godot forum: iOS](https://forum.godotengine.org/tag/ios)
- [GodotSteam (GitHub)](https://github.com/GodotSteam/GodotSteam) · [Godot 4.5 on Steam (SteamDB)](https://steamdb.info/patchnotes/19990499)
- [Steamworks: App Fee](https://partner.steamgames.com/doc/gettingstarted/appfee) · [Steam Direct](https://partner.steamgames.com/steamdirect)
- [Apple Developer fee overview (third party)](https://magora-systems.com/apple-developer-fee/) · [App Store fees 2026](https://blog.funnelfox.com/apple-app-store-fees-2026-eu-dma/)
- [Orion Trail dev interview (TechRaptor)](https://techraptor.net/gaming/interview/indie-interview-dave-bennett-orion-trail) · [Orion Trail on Steam](https://store.steampowered.com/app/381260) · [Expedition Oregon on Steam](https://store.steampowered.com/app/947580)
- [FTL review (PopMatters)](https://www.popmatters.com/163610-ftl-faster-than-light-2495812388.html) · [The Oregon Trail 2021 review (Gamereactor)](https://www.gamereactor.eu/the-oregon-trail-1222383/)
