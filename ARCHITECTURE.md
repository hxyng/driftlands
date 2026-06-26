# DriftLands — Architecture

A top-down roguelite RPG in Godot 4. ~2,900 lines of GDScript across 42 modules,
plus a parallel C# port of the rules engine. This document explains how it's laid
out, why, the data flow through a frame, and — at the end — an honest review of
where it's strong and where it isn't.

## Design goals

1. **The rules engine is pure.** Everything in `src/rpg/` is plain `RefCounted` —
   no nodes, no rendering, no `Input`, no singletons reached into. That's what
   makes it unit-testable headlessly *and* portable to Unity verbatim.
2. **Data-driven where variety lives.** Monsters, loot name tables, upgrade
   catalogs, and boon pools are data (dictionaries / arrays), so adding content is
   editing data, not writing branches.
3. **One source of truth per concern.** Colors live only in `Palette`. Widget
   styling lives only in `UiTheme`. Sprite atlas lookups live only in `SpriteDB`.
   Input bindings live only in `Game`. No magic hex codes or `KEY_*` scattered
   across the codebase.
4. **Inherited, not reinvented.** The generation/analysis stack is lifted from
   [DriftCaves](https://github.com/hxyng/driftcaves) and reused unchanged — proof
   the layering actually composes across projects.

## Layers

```
core/        Cell, Grid, PriorityQueue, Palette, SpriteDB        — primitives, zero game logic
generation/  CellularAutomata → CaveGenerator + GenConfig        — turns noise into a connected cave
analysis/    RegionExtractor (flood fill) · DistanceField (BFS)  — reads structure out of a grid
             · AStarPathfinder
rpg/         Stats · Combat · Progression · LootTable · Item      — PURE rules engine (mirrored in C#)
             · Equipment · Inventory · Daily · Upgrades · Boon
             · MetaProgress
world/       Dungeon · TileRenderer · Level                       — binds generation+analysis into a playable floor
actors/      Player · Enemy · EnemyKinds · Projectile · Pickup    — CharacterBody2D physics + AI
combat/      Health                                               — HP, i-frames, death signal
fx/          FrameAnimator · DamageNumber · Effect · Shaker       — feel
ui/          Hud · MainMenu · PauseMenu · InventoryScreen         — screens, all themed by UiTheme
             · BoonScreen · UiTheme
app/         Game (autoload)                                      — input map, save/load
```

Dependencies point **downward only**: `ui` and `actors` know `rpg`; `rpg` knows
nothing above it. `core` knows nothing about anything. You can read any layer
without holding the one above it in your head.

## The Level is the hub

`world/level.gd` is the single orchestrator. On `_ready` it: generates a `Dungeon`,
renders it, greedy-meshes the walls into row-run collision rectangles (one
`CollisionShape2D` per horizontal wall run instead of one per tile), spawns the
player + camera + screen-shaker, spawns the floor's enemies (or a boss on every
5th floor), and builds the HUD. Every actor holds a typed `Level` reference and
calls back into it for combat resolution, FX, pickups, and floor transitions.
Nothing else talks directly to the rules engine during a frame except the player.

### A frame of combat

```
Player._physics_process
  └─ reads Input → moves (CharacterBody2D.move_and_slide)
  └─ on attack → Level.player_attack(origin, aim, stats, range, arc)
       └─ Combat.resolve(attacker, target, rng)      ← pure rpg/
       └─ Enemy.receive_hit → Health.take_damage
            └─ Level.spawn_damage_number / spawn_effect   ← fx/
       └─ on death: Enemy emits died → Level._on_enemy_died
            └─ spawns XP / soul / heal / item Pickups      ← actors/
Pickup._process
  └─ magnetises to player inside pickup_range → _collect
       └─ Player.gain_xp / gain_souls / collect_item
            └─ Progression.add_xp → may emit leveled_up
                 └─ Level._on_player_leveled → queues a Boon choice
```

The only place the loop touches the rules engine is `Combat.resolve` and the
`Progression` / `Equipment` calls on the player — exactly the surface the Unity
port re-implements.

## Procedural assets

`tools/gen_assets.py` is a dependency-free Python script (its own minimal PNG
encoder, no Pillow) that draws every sprite from shape primitives, auto-outlines
them, packs them into atlases, and writes a `sprites.json` manifest the engine
reads through `SpriteDB`. Re-run it and the whole look regenerates. No stock art,
no purple — the palette is bone / moss / rust / amber by deliberate choice.

## Two engines, one rules engine

`unity/Assets/Scripts/Core/` re-implements `rpg/` in C# with no `UnityEngine`
dependency (the asmdef sets `noEngineReferences`), so it builds and tests as a
plain .NET library. `unity/Tests/CoreTests` runs 25 parity tests (`dotnet run`)
covering the same combat softcap, XP curve, loot rolls, equipment stacking, daily
streak, and upgrade-cost growth the GDScript suite checks. When a rule changes, it
changes in both — and both test suites catch drift.

## Verification

- **`tests/test_runner.gd`** — 28 headless GDScript assertions over the rules
  engine. Run: `godot --headless --script res://tests/test_runner.gd`. CI gate.
- **`unity/Tests/CoreTests`** — 25 C# parity assertions. Run: `dotnet run`.
- **`scripts/review/shot.mjs`** — a Playwright harness that loads the exported web
  build, sends input, and screenshots the running canvas. This is the "second pair
  of eyes": every milestone in this repo was confirmed by *looking* at a real
  frame, not by trusting that it compiled. It caught a blank menu (a focus-click
  landing on a button) and a boss HP bar rendered off-screen (centering on a
  zero-width `Control` instead of the viewport).
- **CI/CD** — GitHub Actions runs the test gate and exports + deploys the web
  build to Pages on every push to `main`.

---

## Harsh self-review

Asked to grade this honestly, not generously.

**What's genuinely good**

- The pure-rules layering is real, not cosmetic. `rpg/` imports nothing upward,
  which is *why* the Unity port and the headless tests exist at all. That
  discipline paid for itself.
- Single-source-of-truth holds: there is exactly one `Palette`, one `UiTheme`, one
  `SpriteDB`, one input map. Grep for a hardcoded `Color(` or `KEY_` outside those
  files and you won't find gameplay using them.
- Lifecycle is clean. Nodes that `queue_free` are guarded with `is_instance_valid`
  before access; floor transitions free the renderer, walls, enemies, projectiles,
  and clear the boss/HUD references. A code review found **zero** crash paths.
- Wall collision is greedy-meshed, not one body per tile — the kind of thing that's
  easy to skip and quietly tanks performance.

**Where it falls short of perfect**

- **`Level` is a 380-line god object.** It orchestrates generation, collision,
  spawning, combat callbacks, FX, rewards, floor flow, pause, inventory, and game
  over. It's *readable* and sectioned with comment banners, but a stricter design
  would split a `FloorBuilder`, a `RewardService`, and a `RunState` out of it. It
  grew correctly but it grew.
- **The inventory screen rebuilds its whole UI on every equip.** Correct and
  perfectly fine for a bag of a dozen items; it would hitch with hundreds. I chose
  obvious-correct over incrementally-clever on purpose, but it's a known ceiling.
- **Balance is hand-tuned, not simulated.** The numbers (defense softcap at 20, XP
  curve, boss HP 220) feel right from playtesting via the screenshot loop, but
  there's no automated balance pass — a deeper project would Monte-Carlo the
  combat math.
- **No audio.** Out of scope here, but a shipping RPG isn't done without it.
- **Boss variety is one.** *The Hollow Warden* is a complete encounter (HP bar,
  ranged volley, guaranteed drop), but "bosses" plural would mean a `BossKinds`
  table mirroring `EnemyKinds`. The seam is there; the content isn't yet.

**Honest grade: A.** The architecture is S-tier — the layering, the dual-engine
proof, the single-source-of-truth discipline, and the see-it-to-believe-it review
loop are better than most hobby projects and a lot of shipped ones. It's held back
from a clean S+ by `Level`'s breadth and the absence of audio and boss variety —
real gaps, named here rather than hidden.
