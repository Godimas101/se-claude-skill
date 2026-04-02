# C# Project Setup — Space Engineers Compiled Mods

Project structure, tooling, and decompiler reference for Space Engineers compiled mods. For runtime scripting patterns (session components, block queries, save/sync), see [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md).

---

## Project Setup Requirements

### Target Framework and Language Version

```xml
<TargetFramework>net48</TargetFramework>   <!-- .NET Framework 4.8 — do NOT use net6/net8 -->
<Platforms>x64</Platforms>                 <!-- Must be x64, NOT AnyCPU -->
<LangVersion>6</LangVersion>               <!-- C# 6 — do NOT use newer features -->
```

SE runs on .NET Framework 4.8. Using `net6` or `net8` will produce a DLL the game cannot load. C# 7+ features (pattern matching, tuples, etc.) will cause compile errors.

### MDK2 — The Standard Project Setup Tool

All compiled SE mods should use **MDK2** (Malware's Development Kit 2):
- **MDK Hub** (GUI): download from https://github.com/malforge/mdk2/releases — manages templates, builds, and output paths
- **Templates:** `dotnet new mdk2mod` (mods) or `dotnet new mdk2pbscript` (PB scripts)
- **NuGet packages** (add to `.csproj`):
  - `Mal.Mdk2.ModAnalyzers` — whitelist analyzer, flags disallowed API calls at edit time
  - `Mal.Mdk2.References` — SE DLL references without hardcoded paths

```xml
<ItemGroup>
  <PackageReference Include="Mal.Mdk2.ModAnalyzers" Version="*" />
  <PackageReference Include="Mal.Mdk2.References" Version="*" />
</ItemGroup>
```

**Do NOT put `.csproj` inside `Data\Scripts\`** — this causes whitelist analyzer conflicts. Keep it at the mod root or in a sibling folder.

---

## Mod Script Folder Structure

Scripts must live in exactly **one named folder** directly under `Scripts/`:

```
YourMod/
└── Data/
    └── Scripts/
        └── YourModName/       ← required — one folder, named after your mod
            ├── YourScript.cs
            └── AnotherFile.cs
```

- `Scripts/` directly containing `.cs` files (no subfolder) will **not** compile
- **Only one folder** should exist directly inside `Scripts/` — multiple sibling folders compile as separate assemblies with no cross-visibility, causing silent breakage
- Nested subfolders inside `YourModName/` are fine for organization
- **Folder name should match your mod name** — the game uses it to identify your mod's storage folder in `%AppData%\SpaceEngineers\Storage\`

### Profiler Injection Warning

The game injects a mod profiler into **every compiled method**, including property accessors (except auto-properties). This has a real performance cost on hot paths:

```csharp
// ❌ Profiler injected on every access — costly in tight loops
public float SomeValue { get { return _value; } }

// ✅ Auto-property — profiler NOT injected
public float SomeValue { get; private set; }

// ✅ Field access — no injection overhead
private float _someValue;
```

In tight loops called at Update1/Update10 rates, prefer direct field access or auto-properties over manual getters.

---

## Key Namespaces

```csharp
using Sandbox.Common.ObjectBuilders;
using Sandbox.Game.EntityComponents;
using Sandbox.ModAPI;
using Sandbox.ModAPI.Ingame;         // For IMyTerminalBlock, IMyBatteryBlock, etc.
using SpaceEngineers.Game.ModAPI;    // For game-specific block types
using VRage.Game;
using VRage.Game.Components;
using VRage.Game.GUI.TextPanel;      // For IMyTextSurface, MySpriteDrawFrame
using VRage.Game.ModAPI;
using VRage.ModAPI;
using VRageMath;
```

### Namespace Ambiguity — CRITICAL

Several types exist in **both** `Sandbox.ModAPI` and `Sandbox.ModAPI.Ingame` (e.g. `IMyTerminalBlock`, `IMyBatteryBlock`). Adding a bare `using Sandbox.ModAPI.Ingame;` in a compiled session component or text surface script causes **ambiguous reference errors** at compile time.

**Rule: never `using` any namespace with "Ingame" in the name.**

```csharp
// ❌ Causes ambiguous reference compile errors in compiled mods
using Sandbox.ModAPI.Ingame;

// ✅ Use an alias for the specific Ingame type you need
using IMyGridTerminalSystem = Sandbox.ModAPI.Ingame.IMyGridTerminalSystem;

// ✅ Or fully qualify — verbose but unambiguous
Sandbox.ModAPI.Ingame.IMyGridTerminalSystem gts = ...;
```

The `Sandbox.ModAPI` version is correct for compiled session components and text surface scripts. Only PB scripts should use `Sandbox.ModAPI.Ingame` types directly.

---

## Canonical MDK2 Project File (.csproj)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Convert_old_projects_to_new_SDK -->

The full canonical `.csproj` for a compiled mod using MDK2. The `.csproj` and `.sln` must live at the **mod root** (not inside `Data\Scripts\`):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <Platforms>x64</Platforms>
    <LangVersion>6</LangVersion>
    <!-- Suppress auto-generated attributes that can conflict with SE's loader -->
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <GenerateNeutralResourcesLanguageAttribute>false</GenerateNeutralResourcesLanguageAttribute>
    <GenerateTargetFrameworkAttribute>false</GenerateTargetFrameworkAttribute>
  </PropertyGroup>

  <ItemGroup>
    <!-- Whitelist analyzer: flags disallowed API calls at edit time (red squiggles) -->
    <PackageReference Include="Mal.Mdk2.ModAnalyzers" Version="*" />
    <!-- Auto-detects SE install and provides DLL references without hardcoded paths -->
    <PackageReference Include="Mal.Mdk2.References" Version="*" />
    <!-- Packages the mod output into the correct workshop folder structure on build -->
    <PackageReference Include="Mal.Mdk2.ModPackager" Version="*" />
  </ItemGroup>
</Project>
```

**Migration from old SDK:**
1. Close your IDE
2. Move `.csproj` and `.sln` to the mod root directory
3. Delete `bin\`, `obj\`, `.vs\`, `.ruleset`, and `.user` files
4. Replace `.csproj` contents with the template above
5. Reopen solution — Visual Studio will restore NuGet packages automatically
6. Right-click any folders you don't want compiled → "Exclude from project"

**Three packages, three roles:**
- `ModAnalyzers` — static analysis only; runs at edit time
- `References` — provides SE DLL references; no hardcoded paths needed
- `ModPackager` — copies output to workshop folder on build (optional but recommended)

---

## Debugging with dnSpy

<!-- Source: https://spaceengineers.wiki.gg/wiki/Scripting/Debugging_with_dnSpy -->

### Attaching to a Running Game

1. Launch Space Engineers normally
2. Open dnSpy (64-bit .NET Framework version from https://github.com/0xd4d/dnSpy/releases)
3. `Debug → Attach to process (Ctrl+Alt+P)` → select `SpaceEngineers.exe`
4. If the process isn't listed, run dnSpy as administrator

### Catching Exceptions Automatically

Enable via `Debug → Windows → Exception settings (Ctrl+Alt+E)`:
- Search "null" → enable `NullReferenceException` (most common mod crash)
- Add `VRage.Compiler.ScriptOutOfRangeException` for script complexity errors

Trigger the error in-game — dnSpy pauses at the throw site. Then:
- `Debug → Windows → Locals (Alt+4)` — inspect variable values at the crash point
- `Debug → Windows → Call Stack (Ctrl+Alt+C)` — trace the full call chain

### Breakpoint Workaround for In-Memory Compiled Scripts

Mod scripts compiled at runtime generate new modules each time — normal breakpoints don't survive recompile. Use this pattern during development only:

```csharp
// Forces a debugger break at this exact location when dnSpy is attached.
// ⚠️ DEBUGGING ONLY — remove before release. Never ship empty catch blocks.
try { throw new InvalidOperationException("debug break point"); }
catch (Exception) { }
```

### Launching the Game Directly from dnSpy (Full Variable Inspection)

This disables JIT optimizations so local variables aren't elided:
1. Ensure `steam_appid.txt` exists in `Bin64\` with content: `244850`
2. In dnSpy: `F5` → Debug engine: `.NET Framework`
3. Browse to `SpaceEngineers.exe` in `Bin64\`
4. Optional launch args: `-skipintro -nosplash`

Note: Game runs noticeably slower when launched this way — use only for deep debugging sessions.

### Inspecting Game Code (Decompiler Mode)

```
File → Open → navigate to SpaceEngineers\Bin64\
Select all .dll and .exe files
Edit → Search Assemblies (Ctrl+Shift+K)
```

Right-click any type/method → **Analyze** to see where it's called, implemented, or assigned. Use this to discover what interfaces a block type implements, what overrides exist, or how Keen wires up their own components.

---

## Exploring Game Code — Decompiler Strategies

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Exploring_Game_Code -->

### Setup

Use **ILSpy** (faster, simpler) or **dnSpy** (more features). Both support full decompilation of non-obfuscated SE assemblies.

1. Launch decompiler → `File → Open List` (creates a persistent assembly list)
2. Navigate to `SpaceEngineers\Bin64\` and open all DLLs
3. Remove `.XmlSerializers.dll` files to reduce noise in search results

### Search Strategies

| Decompiler | Search command |
|-----------|---------------|
| ILSpy | `View → Search` |
| dnSpy | `Edit → Search Assemblies (Ctrl+Shift+K)` |

Search by partial class name, method name, or property name. Example: searching `safezone` finds both `MySafeZone` (entity) and `MySafeZoneBlock` (block implementation).

### Navigating the Code Graph

- **Forward:** Click any method name to jump to its implementation
- **Backward:** Right-click → **Analyze** → shows all callers, implementors, and assignments as a tree

**Limitation:** Analyzing an interface method implementation via the class won't show interface-level callers — analyze the interface method directly instead.

### Naming Conventions to Know

```
MyObjectBuilder_*   — Serializable data classes. Used for SBC definitions, save data,
                      network packets, and blueprints. The "builder" is the data container;
                      the runtime object is typically a separate class.

*Definition         — SBC definition data, deserialized from .sbc files into
                      MyDefinitionManager at load time. Read-only at runtime.
```

### Finding Enum Values

`const` fields and `enum` values can't be analyzed (compiler inlines them). Workaround:

```
ILSpy: File → Save code
dnSpy: File → Export to project
```

Then use Notepad++ find-in-files or WinMerge to search across the exported source.

### Verifying API Whitelist Access

Before calling any game method in a mod, confirm it's on the whitelist:
- Open the method in the decompiler
- Check it has `[ModAPI]` attribute or is in a whitelisted namespace
- Use MDK2's analyzer — it flags disallowed calls at edit time with a red squiggle

---

## References

### External
- [github.com/malforge/mdk2](https://github.com/malforge/mdk2) — MDK2: project templates, NuGet packages, build tools
- [github.com/dnSpy/dnSpy](https://github.com/dnSpy/dnSpy) — debugger/decompiler for SE mod development
- [github.com/icsharpcode/ILSpy](https://github.com/icsharpcode/ILSpy) — ILSpy: lighter-weight decompiler alternative to dnSpy
- [spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting](https://spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting) — official C# mod scripting reference

### Internal
- [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md) — runtime patterns: session components, block queries, config, save/sync
- [TSS_PATTERNS.md](TSS_PATTERNS.md) — Text Surface Script drawing, scrolling, subgrid caching
- [PB_SCRIPTS.md](PB_SCRIPTS.md) — Programmable Block scripting (sandboxed; different from compiled mods)
- [../GETTING_STARTED.md](../GETTING_STARTED.md) — beginner onboarding: mod types, VS Code setup, uploading

### Local
- ModSDK API DLLs (with XML docs): `[Steam]\steamapps\common\SpaceEngineersModSDK\`
