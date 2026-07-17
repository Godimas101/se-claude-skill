# Animation Engine

**Workshop ID:** 2880317963
**Author:** Math0424
**GitHub:** [Math0424/AnimationEngine](https://github.com/Math0424/AnimationEngine)
**Wiki (current reference):** [GitHub Wiki](https://github.com/Math0424/AnimationEngine/wiki)

Animation Engine is a scripting framework that lets you add animated behaviors to Space Engineers blocks using a purpose-built domain-specific language called **BSL (Block Scripting Language)**. It handles subpart movement, emissive color/intensity, particle emitters, dynamic lights, and sound — all driven by game events and live game data — without requiring C# session components.

> **Key insight:** Animation Engine child mods contain no C# code. All animation logic lives in `.bsl` script files. The framework discovers these files automatically from the `Data/Animation/` folder and interprets them at runtime. No SBC modifications are required beyond your block definition.

**Note on BSL versions:** V1 is documented in the old Steam guide (outdated). **V2 is the current version** — use the GitHub wiki, not the Steam guide. V3 is in active development but not yet released.

---

## How Animation Engine Child Mods Are Structured

```
MyAnimatedMod/
├── Data/
│   └── Animation/
│       ├── main.info                    ← Lists script names (one per line)
│       ├── MyBlockScript.bsl            ← Animation script for one block type
│       └── AnotherBlock.bsl             ← Animation script for another
└── metadata.mod
```

### main.info Format

The `main.info` coordinator file maps script names to the engine. One line per script:

```
Animation MyBlockScript
Animation AnotherBlock
```

Each name must exactly match the corresponding `.bsl` filename (without extension). Alternatively, a single-script mod can just use `Main.bsl` directly in the folder.

---

## BSL Script Structure

Every `.bsl` script has four parts: headers, object declarations, functions, and actions.

```bsl
# ── 1. Headers (required) ────────────────────────────────────────────────────
@BlockID "MyBlockSubtypeId"    # Must match CubeBlocks SBC SubtypeId
@Version 2
@Author YourName
# @Weaponcore [gunId]          # Optional: WeaponCore integration

# ── 2. Object declarations ────────────────────────────────────────────────────
using mySubpart  as Subpart("SubpartName")           # Named model subpart
using myBarrel   as Subpart("BarrelSubpart") parent mySubpart  # Child subpart
using myButton   as Button("ButtonSubpart", "DummyName")
using myGlow     as Emissive("EmissiveMaterialID")
using myFX       as Emitter("ParticleDummyName")
using myLight    as Light("LightDummyName", 5.0, false, 1.0, 1.0)

# ── 3. Variables ──────────────────────────────────────────────────────────────
var isActive = false
var speed    = 0.0

# ── 4. Functions ──────────────────────────────────────────────────────────────
func OpenDoors() {
    leftDoor.translate([-1, 0, 0], 30, OutCubic)
    rightDoor.translate([1, 0, 0], 30, OutCubic)
}

# ── 5. Actions (event handlers) ───────────────────────────────────────────────
action block() {
    working() {
        # Called when block transitions to working state
        OpenDoors()
    }
    notworking() {
        leftDoor.reset()
        rightDoor.reset()
    }
}
```

---

## Object Types

| Declaration | Constructor | Purpose |
|-------------|-------------|---------|
| `Subpart` | `subpart("Name")` | Model subpart (moving geometry) |
| `Subpart` (child) | `subpart("Name") parent parentVar` | Subpart in a hierarchy |
| `Button` | `button("SubpartName", "DummyName")` | Interactable button |
| `Emissive` | `emissive("MaterialID")` | Glowing/emissive material |
| `Emitter` | `emitter("DummyName")` | Particle or sound emitter |
| `Light` | `light("DummyName", radius, flare, falloff, intensity)` | Dynamic light source |

---

## Action Groups (Event Handlers)

Actions are the top-level entry points triggered by game events.

| Action | Events |
|--------|--------|
| `block()` | `create()`, `built()`, `working()`, `workingloop()`, `notworking()` |
| `cockpit()` | `enter()`, `exit()` |
| `door()` | `open()`, `close()`, etc. |
| `landinggear()` | `lock()`, `unlock()`, etc. |
| `button()` | `pressedon()`, `pressedoff()`, `pressed()`, `switchedon()`, `switchedoff()`, `switched()` |
| `inventory()` | Inventory change events |
| `power()` | Power state change events |
| `production()` | `startproducing()`, `stopproducing()` |
| `distance()` | Player proximity events |
| `shiptool()` | `activated(bIsActive)` — welder/grinder/drill activation |
| `weaponcore()` | `reloading()`, `firing()`, `tracking()`, `overheated()`, `turnon()`, `turnoff()`, `burstreload()`, `homing()`, `targetaligned()`, `targetranged()` |
| `toolcore()` | `functional()`, `powered()`, `enabled()`, `activated()`, `click()`, `firing()`, `hit()`, `rayhit()` |

---

## Subpart Methods

```bsl
# Movement — all take optional lerp type as last arg (see Lerps section)
mySubpart.translate([x, y, z], durationTicks, LerpType)
mySubpart.rotate([x, y, z], angleDegrees, durationTicks, LerpType)
mySubpart.spin([x, y, z], speed, durationTicks)
mySubpart.scale([x, y, z], durationTicks, LerpType)
mySubpart.vibrate([x, y, z], amplitude, durationTicks)

# Visibility
mySubpart.setVisible(true)
mySubpart.setVisible(false)

# Reset to original transform
mySubpart.reset()

# Chainable dot notation
mySubpart.translate([0, 1, 0], 20, Linear).rotate([0, 1, 0], 90, 30, OutCubic)
```

---

## Emitter Methods

```bsl
myFX.playParticle("ParticleSubtypeId", scale, duration)
myFX.stopParticle()
myFX.playSound("SoundCueName")
myFX.stopSound()
```

---

## Emissive Methods

```bsl
myGlow.setColor([r, g, b], durationTicks, LerpType)
myGlow.setIntensity(value, durationTicks, LerpType)
```

---

## Script Libraries

### `Block.*` — Block data
```bsl
var thrust = Block.CurrentThrustPercent()   # Returns 0.0–1.0
```

### `Grid.*` — Environment data
```bsl
var density = Grid.AtmosphericDensity()     # 0.0–1.0
var altitude = Grid.Altitude()              # Meters
var speed    = Grid.Speed()                 # m/s
var gravity  = Grid.Gravity()               # m/s²
```

### `api.*` — Runtime control
```bsl
api.startLoop("FuncName", intervalTicks, repeatCount)  # -1 = infinite repeat
api.delay(ticks)                                        # Stagger execution
api.log(value)                                          # Debug output to log
api.assert(a, b)                                        # Assert a == b
```

### `math.*` — Math utilities
```bsl
math.sin(x)
math.cos(x)
math.floor(x)
math.ceiling(x)
math.round(x)
math.and(a, b)   # Bitwise AND
math.or(a, b)    # Bitwise OR
math.xor(a, b)   # Bitwise XOR
```

---

## Lerp (Easing) Types

The last parameter of transform calls. All standard easing functions are supported:

```
Instant   Linear
InBack    OutBack    InOutBack
InBounce  OutBounce  InOutBounce
InElastic OutElastic InOutElastic
InSine    OutSine    InOutSine
InQuad    OutQuad    InOutQuad
InCubic   OutCubic   InOutCubic
InQuart   OutQuart   InOutQuart
InQuint   OutQuint   InOutQuint
InExpo    OutExpo    InOutExpo
InCirc    OutCirc    InOutCirc
```

Visual reference: [easings.net](https://easings.net/)

---

## Language Features

```bsl
# Variables
var myFloat = 1.0
var myBool  = false

# Arithmetic
var result = myFloat + 2.0 * 3.0

# Comparison
if (myFloat == 1.0) { }
if (myFloat != 0.0 && myBool == false) { }

# if / else if / else
if (thrust > 0.8) {
    myGlow.setIntensity(1.0, 5, Linear)
} else if (thrust > 0.4) {
    myGlow.setIntensity(0.5, 5, Linear)
} else {
    myGlow.setIntensity(0.1, 5, Linear)
}

# While loop
while (myBool == true) {
    mySubpart.rotate([0, 1, 0], 10, 6, Instant)
}

# Return
func CheckState() {
    if (isActive == false) { return }
    mySubpart.spin([0, 1, 0], 1.0, 60)
}

# Comments
# This is a comment
```

**Timing:** All duration/interval values are in game ticks. `60 ticks = 1 second`.

---

## Real-World Example (Aryx Mega Welder)

Workshop ID `3325231237` — plays a torch particle when the welder is active:

**`Data/Animation/main.info`:**
```
Animation Aryx_Shiptool_MegaWelder
```

**`Data/Animation/Aryx_Shiptool_MegaWelder.bsl`:**
```bsl
@BlockID "Aryx_Shiptool_MegaWelder"
@Version 2
@Author AryxCami

using welder_particle as Emitter("particles1")

var bIsActive  = false
var bIsWelding = false

func StartBeam() {
    if (bIsActive == false) {
        welder_particle.playParticle("Aryx_ShipTool_MegaWelderTorch", 1, 1)
    }
    bIsActive = true
}

func StopBeam() {
    welder_particle.stopParticle()
    bIsActive = false
}

action Shiptool() {
    activated(bIsWelding) {
        if (bIsWelding == true) { StartBeam() }
        if (bIsWelding == false) { StopBeam() }
    }
}
```

---

## Critical Rules

1. **`@BlockID` must match CubeBlocks SBC SubtypeId** — This is how the engine finds which block to animate. Mismatched IDs = silent failure; no error.

2. **`@Version 2` is required** — Always include this header. V1 syntax is different and the V1 Steam guide is outdated.

3. **Subpart names must exist in the `.mwm` model** — If a `Subpart("Name")` references a name that doesn't exist in the model, it silently fails. Verify subpart hierarchy in VRageEditor.

4. **Parent hierarchy must match model hierarchy** — When using `parent`, the chain must mirror the actual node hierarchy in the model.

5. **Timing is always ticks** — All duration, delay, and loop interval values are integers in game ticks. 60 ticks = 1 second.

6. **No SBC changes required** — The framework discovers `.bsl` files from `Data/Animation/` at load time. You don't need to register anything in SBC beyond your block definition.

7. **WeaponCore integration** — To animate a WeaponCore weapon, add `@Weaponcore [gunId]` to the script header and use the `weaponcore()` action group.

---

## Finding Examples

Check the user's **MOD_CATALOGUE.md** for all mods with category **Animation Engine** — these are the child mods they have installed. Use them as local reference examples when writing BSL scripts.

Any mod with `Data/Animation/*.bsl` files is an Animation Engine child mod.

Full documentation: [GitHub Wiki](https://github.com/Math0424/AnimationEngine/wiki) — especially [Scripting Language Basics](https://github.com/Math0424/AnimationEngine/wiki/Scripting-Language-Basics) and the [V2 Lexicon](https://github.com/Math0424/AnimationEngine/wiki/V2-Lexicon).

---

## References

### External
- [Workshop Page](https://steamcommunity.com/sharedfiles/filedetails?id=2880317963)
- [GitHub Repository](https://github.com/Math0424/AnimationEngine)
- [GitHub Wiki](https://github.com/Math0424/AnimationEngine/wiki)
- [Scripting Language Basics](https://github.com/Math0424/AnimationEngine/wiki/Scripting-Language-Basics)
- [V2 Lexicon](https://github.com/Math0424/AnimationEngine/wiki/V2-Lexicon)
- [easings.net](https://easings.net/) — easing/lerp type visual reference
- Aryx Mega Welder (real-world BSL example) — Workshop ID `3325231237`

### Internal
- [../ASSETS.md](../ASSETS.md) — subpart setup in MWM models; particle and sound dummies
- [../sbc/SBC_BLOCKS.md](../sbc/SBC_BLOCKS.md) — block definition; `<SubtypeId>` must match `@BlockID`
- [WEAPONCORE.md](WEAPONCORE.md) — WeaponCore integration via `@Weaponcore` and `weaponcore()` actions

### Local

Search the user's `MOD_CATALOGUE.md` for entries in the **Animation Engine** category. Any listed mod is a locally installed Animation Engine child mod and is valid reference material.

**Workshop IDs — check MOD_CATALOGUE for local paths:**
| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| 2880317963 | Animation Engine | Framework Mod | Framework source |
| 3325231237 | Aryx Mega Welder | Animation Engine | Real-world BSL example |
