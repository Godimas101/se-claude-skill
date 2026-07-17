# Workspace checks

Run through these before any SE modding work. Missing paths reduce what Claude can help with — not blockers, but callouts.

## 1. SE Game Directory

Look for a directory containing `Content/Data/` with `.sbc` files (e.g. `CubeBlocks`, `Components.sbc`).

- ✅ Found → vanilla SBC definitions are available as ground truth.
- ❌ Not found → ask the user:
  > "I don't see the Space Engineers game directory in your workspace. Please add `[Steam]\steamapps\common\SpaceEngineers\` as an additional working directory in VS Code. This gives me access to vanilla block definitions."

## 2. ModSDK Directory

Look for a directory containing `Bin64_Profile/` with `.dll` and `.xml` files (e.g. `Sandbox.Game.xml`).

- ✅ Found → full C# API documentation available.
- ❌ Not found → ask the user:
  > "I don't see the Space Engineers ModSDK in your workspace. Please add `[Steam]\steamapps\common\SpaceEngineersModSDK\` as an additional working directory. Install it free via Steam → Library → Tools → 'Space Engineers - Mod SDK'. This gives me access to the full C# API documentation."

## 3. AppData Directory

Look for a directory containing `SpaceEngineers.log` and a `Crashes/` folder. Standard path: `C:\Users\[Username]\AppData\Roaming\SpaceEngineers\`.

- ✅ Found → crash logs and game logs available. When the user reports a bug, check these first.
- ❌ Not found → ask the user:
  > "I don't see your Space Engineers AppData folder in your workspace. Add `%AppData%\Roaming\SpaceEngineers\` as a working directory — this gives me access to crash logs and the game log when you need to debug issues."

## 4. Workshop Mod Directory

Look for `[Steam]\steamapps\workshop\content\244850\` — recognizable as a directory containing 10+ numbered subfolders (each is a Workshop ID).

- ✅ Found with `MOD_CATALOGUE.md` at its root → read the catalogue. Check the `Catalogued:` date; if >30 days old, offer to refresh.
- ✅ Found without `MOD_CATALOGUE.md` → offer to build one:
  > "I can see your workshop mod directory but there's no MOD_CATALOGUE.md yet. Would you like me to build one? It indexes all your subscribed mods so I can reference them when helping you."
- ❌ Not found → ask the user:
  > "I don't see your Steam Workshop mod directory in your workspace. Please add `[Steam]\steamapps\workshop\content\244850\` as an additional working directory in VS Code. This is required before I can build or read a mod catalogue."

**Do not attempt to create or reference a MOD_CATALOGUE.md until the workshop directory is in the workspace.**

## Not all four are required

- Only doing PB scripts? You can skip the mod directory entirely.
- Not debugging crashes? AppData is nice but not essential.
- Working from decompiled code and don't need vanilla ground truth? Skip the SE game dir.

Match effort to what the user actually needs.
