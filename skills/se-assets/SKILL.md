---
name: se-assets
description: "Use for Space Engineers asset creation: 3D models (Blender + SEUT addon, FBX → MwmBuilder → .mwm), texture channel packing (DX11 layout: _cm/_ng/_add/_alphamask), Havok collision meshes, material Technique values (MESH, DECAL, GLASS, HOLO, SHIELD…), LCD textures (PNG → texconv → .dds), and audio (WAV → xWMAEncode.exe → .xwm). Concrete triggers: making a custom block model, packing textures for a mod, setting up collisions, converting audio for the game. SKIP for: SBC-only content that reuses vanilla art (use se-sbc), C# code or scripts (use se-csharp / se-tss / se-pb-scripts), framework integrations without art work (use se-frameworks)."
---

# SE Assets — model, texture, and audio pipeline

Space Engineers uses custom asset formats. Don't follow tutorials pre-2019 for textures — the DX11 channel layout changed.

## Read first

**[references/pipeline.md](references/pipeline.md)** — full pipeline: Blender + SEUT modeling, texture packing details, Havok collisions, material properties, MWM export, LCD texture requirements, audio encoding.

## Quick reference

**Models:** `FBX → MwmBuilder → .mwm`. Tool at `[ModSDK]\Tools\VRageEditor\`. Build stage models use `_BS1`/`_BS2`/`_BS3` suffixes.

**Textures — DX11 channel packing:**

| Suffix | Channels | Contents |
|--------|----------|----------|
| `_cm.dds` | RGB=Color, A=Metalness | Diffuse + metal mask |
| `_ng.dds` | RGB=Normal, A=Glossiness | Normal + gloss mask |
| `_add.dds` | R=AO, G=Emissive, A=Paintability | AO + emissive + paint |
| `_alphamask.dds` | A only | Transparency cutout for GLASS/DECAL |

Format: `BC7_UNORM_SRGB` (color) / `BC7_UNORM` (normals) via `texconv`.

**Technique values** (`<Technique>` in material definition):

| Value | Use |
|-------|-----|
| `MESH` | Standard opaque (default) |
| `DECAL` / `DECAL_NOPREMULT` / `DECAL_CUTOUT` | Decal overlays |
| `ALPHA_MASKED` | Opacity from alphamask |
| `FOLIAGE` | Semi-transparent with shadow transparency |
| `GLASS` | Transparent + refraction — needs `TransparentMaterials.sbc` entry |
| `HOLO` | Emissive glass — needs `TransparentMaterials.sbc` entry |
| `SHIELD` | Animated glass — **may crash on certain blocks** |

**LCD textures:** `PNG → texconv BC7_UNORM_SRGB → .dds`. Alpha is inverse emissivity; use `-sepalpha` for mipmaps.

**Audio:** `WAV → xWMAEncode.exe → .xwm`. Encoder at `[ModSDK]\Tools\xWMAEncode.exe` (bundled, no separate download).

## Tools

- **Blender 4.0+** with the [SEUT addon](https://spaceengineers.wiki.gg/wiki/Modding/Tools/Space_Engineers_Utilities) — the modeling entry point.
- **VRageEditor** — bundled with the ModSDK, used for MWM export and animations.
- **texconv** — Microsoft DirectX texture converter, for DDS creation.
- **xWMAEncode.exe** — bundled with the ModSDK, for audio.
