# Tank Tracks Framework & API

**Workshop ID:** 3208995513
**Author:** Digi (THDigi)
**Config reference (Gist):** [TankTracks.ini full reference](https://gist.github.com/THDigi/d9d41e35a97fd9b55a3e9d3a7e0a8d72)
**C# API example (Gist):** [Session component example](https://gist.github.com/THDigi/d515209c9dce1d0bee1deb86235a654a)

Tank Tracks is a pure framework mod — it does nothing on its own. It provides the runtime engine for animated tank tracks, handling segment rendering, terrain-hugging raycasts, 1:1 movement animation, multiplayer sync, blueprint saving/restoring, and destruction effects.

> **Key insight:** Most Tank Tracks child mods require **no C# at all**. Visual track mods (adding track designs to wheel/suspension blocks) just need a `.mwm` track segment model and a `Data/TankTracks.ini` config file. The C# API is only needed for scripted tools that programmatically place or remove tracks at runtime.

> **Note:** The Tank Tracks framework mod was removed from public Workshop view as of 2025. If you have it installed locally it still works, but new players may have difficulty finding it.

---

## Two Types of Child Mods

| Type | What It Does | Needs C#? |
|------|--------------|-----------|
| **Content mod** | Adds track designs over wheel/suspension blocks | No — INI + model only |
| **Scripted tool** | Programmatically places/removes tracks at runtime | Yes — uses C# API |

The vast majority of track mods are content mods. The C# API exists for tools like the [Tank Tracks Builder](https://steamcommunity.com/workshop/filedetails?id=3209005014).

---

## Content Mod Structure

```
MyTrackMod/
├── Data/
│   └── TankTracks.ini          ← Config file (required — exact filename)
└── Models/
    └── Tracks/
        └── MySegment.mwm       ← Track segment model (1 m width standard)
```

The framework scans all loaded mods for `TankTracks.ini` at startup. The file must be at `Data\TankTracks.ini` exactly.

---

## TankTracks.ini Format

The INI dialect used by Tank Tracks is not standard Windows INI — comments must start at the beginning of the line with `;`, and whitespace around `=` is trimmed.

```ini
; Track Design — groups tracks for UI display
[Design:MyTrackDesign]
DisplayName = My Tank Tracks
Icon = MyTrackIconMaterial

; Track definition — describes how segments are laid out
[Track:MyTrack]
Design = MyTrackDesign
SegmentModel = Models\Tracks\MySegment.mwm
SegmentPivotDistance = 0.5
SegmentScale = 1,1,1
SegmentOffset = 0,0,0
SegmentFlip = false
GroundCollide = true
ReplaceWheelModel = Models\Tracks\MyWheelReplacement.mwm
DestroyParticle = MyExplosionParticle
DestroySound = MyExplosionSound

; Block-to-track mapping
[Blocks]
MotorSuspension/SmallSuspension1x1 = MyTrack
MotorSuspension/LargeSuspension3x3 = MyTrack
```

---

## [Design:Name] Section

Defines a named track design group for the in-game UI.

| Key | Type | Description |
|-----|------|-------------|
| `DisplayName` | string | Name shown in-game when selecting the track design |
| `Icon` | string | TransparentMaterial SubtypeId used as the design icon |

---

## [Track:Name] Section

Defines a complete track configuration.

| Key | Required | Description |
|-----|----------|-------------|
| `Design` | **Yes** | Which Design group this track belongs to |
| `SegmentModel` | **Yes** | Path to `.mwm` model for one track segment. 1 m width is the standard. |
| `SegmentConstruction` | No | Model shown during block construction phase |
| `SegmentPivotDistance` | No | Distance between segment pivot points |
| `SegmentScale` | No | `X,Y,Z` scale of each segment. Default: `1,1,1` |
| `SegmentOffset` | No | `X,Y,Z` offset: horizontal outward, vertical outward, forward. Default: `0,0,0` |
| `SegmentFlip` | No | `true` rotates the model 180° on the up axis |
| `GroundCollide` | No | `true` enables terrain-hugging via raycasts (default: `true`) |
| `AllowOnRotors` | No | `true` allows tracks on static rollers/rotors |
| `RotatePart` | No | Subpart name to rotate with track movement, or `*` for whole block |
| `ReplaceWheelModel` | No | Model path that replaces the wheel's visual when tracks are placed |
| `ReplaceWheelModelConstruction` | No | Construction-phase version of `ReplaceWheelModel` |
| `DestroyParticle` | No | Particle SubtypeId on track destruction |
| `DestroyParticleScale` | No | Scale multiplier for the destruction particle |
| `DestroySound` | No | Sound SubtypeId on track destruction |
| `Inherit` | No | Copy all values from another Track ID (deep inheritance supported) |
| `Merge` | No | `true` — partially override another mod's track instead of replacing it |

---

## [Blocks] Section

Maps block SubtypeIds to track IDs. Supported block types: `MotorSuspension`, `CubeBlock` (static rollers), `Wheel`.

```ini
[Blocks]
MotorSuspension/SmallSuspension1x1 = MyTrack
MotorSuspension/LargeSuspension3x3 = MyTrack, MySecondTrack   ; Multiple tracks per block
CubeBlock/MyStaticRollerBlock = MyTrack
```

---

## [WheelOverride:Type/Subtype] Section

Adjusts wheel geometry for fit calculations when the default values don't align correctly.

```ini
[WheelOverride:Wheel/MyWheelSubtype]
Width = 1.2
OutOffset = 0.1
Radius = 0.6
```

---

## [FileInclude] Section

Include another `.ini` file for modular organization:

```ini
[FileInclude:TankTracks_Heavy.ini]
[FileInclude:TankTracks_Light.ini]
```

Only works from the main `TankTracks.ini` — included files cannot chain-include further files.

---

## Developer Console Command

`/tanktracks reload` — Reloads all `TankTracks.ini` files from all active mods and respawns all tracks. Works in offline worlds only. Useful during development without restarting the game.

---

## C# API (Scripted Tools Only)

For scripted tools that need to place or remove tracks programmatically, copy the `Data\Scripts\TankTracks\API\` folder from the framework mod into your mod and wire up a session component.

> The C# API is intentionally minimal. For anything beyond basic init/track queries, reference the [Tank Tracks Builder source](https://steamcommunity.com/workshop/filedetails?id=3209005014) or request functionality from Digi.

```csharp
using Digi.TankTracks.API;
using Digi.TankTracks.API.Client;

[MySessionComponentDescriptor(MyUpdateOrder.NoUpdate)]
public class MyTrackToolSession : MySessionComponentBase
{
    TankTracksAPI TankTracksAPI;

    // Create in constructor — not LoadData()
    public MyTrackToolSession()
    {
        TankTracksAPI = new TankTracksAPI(OnAPIReady);
    }

    void OnAPIReady()
    {
        // API is live — safe to call methods here
        // Or check TankTracksAPI.Initialized before calling methods elsewhere
    }

    protected override void UnloadData()
    {
        TankTracksAPI?.UnloadData();
    }
}
```

**Critical API rule:** Create `TankTracksAPI` in the **constructor**, not in `LoadData()`. Unlike most SE patterns, this must happen at construction time.

---

## Finding Examples

Check the user's **MOD_CATALOGUE.md** for all mods with category **Tank Tracks** — these are the child mods they have installed. Use them as local reference examples when building track configs or scripted tools.

Any mod with a `Data\TankTracks.ini` file is a Tank Tracks content mod. Any mod with `TankTracksAPI.cs` in its scripts is using the C# API.

The **Tank Tracks Builder** (ID `3209005014`, by Digi) is the canonical reference implementation for the C# API — if the user has it installed, read it.

Full config reference: [Digi's TankTracks.ini Gist](https://gist.github.com/THDigi/d9d41e35a97fd9b55a3e9d3a7e0a8d72)
