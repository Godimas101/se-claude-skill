# Key paths

Absolute-path reference — use these when directing the user to a file, verifying they have the right dir mounted, or locating a tool.

## Path variables

- `[Steam]` — the user's Steam library root, typically `C:\Program Files (x86)\Steam\` or `D:\SteamLibrary\` (depends on install)
- `[SE]` — `[Steam]\steamapps\common\SpaceEngineers`
- `[ModSDK]` — `[Steam]\steamapps\common\SpaceEngineersModSDK`
- `%AppData%` — `C:\Users\[Username]\AppData\Roaming` on Windows

## Where things live

| What | Where |
|------|-------|
| Game API DLLs + XML docs | `[ModSDK]\Bin64_Profile\` |
| Vanilla block/item SBCs (107 files) | `[SE]\Content\Data\` |
| CubeBlock definitions (27 category files) | `[SE]\Content\Data\CubeBlocks\` |
| Audio definitions | `[SE]\Content\Data\Audio.sbc` |
| Planet generator (with a mod example inline!) | `[SE]\Content\Data\PlanetGeneratorDefinitions.sbc` |
| DLC definitions | `[SE]\Content\Data\Game\DLCs.sbc` |
| ModSDK tools | `[ModSDK]\Tools\` |
| xWMAEncode (audio) | `[ModSDK]\Tools\xWMAEncode.exe` |
| VRageEditor (model/anim tools) | `[ModSDK]\Tools\VRageEditor\` |
| Subscribed workshop mods | `[Steam]\steamapps\workshop\content\244850\` |
| Game log (latest) | `%AppData%\Roaming\SpaceEngineers\SpaceEngineers_YYYYMMDD_HHMMSSms.log` |
| Crash dumps | `%AppData%\Roaming\SpaceEngineers\Crashes\` |
| Save games | `%AppData%\Roaming\SpaceEngineers\Saves\` |
| Locally developed mods (not Workshop) | `%AppData%\Roaming\SpaceEngineers\Mods\` |
| Per-mod runtime storage | `%AppData%\Roaming\SpaceEngineers\Storage\[modId]\` |

## Framework Workshop IDs (common ones)

| Workshop ID | Framework |
|-------------|-----------|
| `3017795356` | Mod Adjuster |
| `1521905890` | MES (Modular Encounters System) |
| `2596208372` | AI Enabled |

WeaponCore, Animation Engine, Scope Framework, Tank Tracks, Vanilla+ IDs vary by version — check the mod catalogue or the Workshop page directly.
