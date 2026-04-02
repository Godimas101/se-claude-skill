# SBC Production & Research — Space Engineers

Blueprints, production tabs, and progression locks. For SBC rules and shared field references, see [SBC_RULES.md](SBC_RULES.md).

> For block/item templates and the block type reference: see [SBC_BLOCKS.md](SBC_BLOCKS.md).
> For LCD registration, localization, loot, and prefabs: see [SBC_MISC.md](SBC_MISC.md).

---

## Blueprint (Crafting Recipe)

> ⚠️ Do not use `{` or `}` in `<DisplayName>` — escape them as `{{` and `}}` or the game throws a FormatException.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Blueprints>
    <Blueprint>
      <Id Type="MyObjectBuilder_BlueprintDefinition" Subtype="MY_RECIPE" />
      <DisplayName>My Recipe Name</DisplayName>
      <Icon>Textures\GUI\Icons\component\MY_COMPONENT.dds</Icon>
      <Prerequisites>
        <Item Amount="10" TypeId="Ore" SubtypeId="Iron" />
        <Item Amount="2" TypeId="Ore" SubtypeId="Nickel" />
      </Prerequisites>
      <Result Amount="1" TypeId="Component" SubtypeId="MY_COMPONENT" />
      <BaseProductionTimeInSeconds>5</BaseProductionTimeInSeconds>
    </Blueprint>
  </Blueprints>
</Definitions>
```

---

## BlueprintClassEntries — Non-destructive Recipe Adding

Add items to production tabs without overriding any block definitions. **Additive** — safe to use alongside other mods.

### Add a new item to an existing production tab

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClassEntries>
    <Entry Class="LargeBlocks" BlueprintSubtypeId="MY_RECIPE_SUBTYPE" />
  </BlueprintClassEntries>
</Definitions>
```

### Remove an item from a production tab

Self-closing `/>` tags cannot have children — use full open/close tags:

```xml
<BlueprintClassEntries>
  <Entry Class="SmallBlocks" BlueprintSubtypeId="SomeBlock">
    <Enabled>false</Enabled>
  </Entry>
</BlueprintClassEntries>
```

> Find the class name by checking `<BlueprintClasses>` on the target production block in `Content\Data\CubeBlocks\CubeBlocks_Production.sbc`.
> Blocks auto-generate blueprints using `TypeId/SubtypeId` — no manual blueprint needed for block recipes.

---

## BlueprintClass Definition (New Production Tab)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/BlueprintClasses -->

Creates a new tab in a production block's UI. You must also link a production block to this class via its SBC definition, and add blueprint entries to populate it.

**The three-layer system:**
1. `BlueprintClass` — defines the tab (icon, name, hover text)
2. `BlueprintClassEntries` — links blueprints to a class (additive, safe for mods)
3. `Blueprint` — defines what goes in → what comes out

### New BlueprintClass (production tab)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClasses>
    <Class>
      <Id>
        <TypeId>BlueprintClassDefinition</TypeId>
        <SubtypeId>MyMod_CustomTab</SubtypeId>
      </Id>
      <DisplayName>My Custom Tab</DisplayName>
      <Description>Hover text shown on the tab</Description>
      <!-- All icon fields are optional but recommended -->
      <Icon>Textures\\GUI\\Icons\\SomeFile.dds</Icon>
      <HighlightIcon>Textures\\GUI\\Icons\\SomeFile.dds</HighlightIcon>
      <FocusIcon>Textures\\GUI\\Icons\\SomeFile_Focused.dds</FocusIcon>
      <InputConstraintIcon>Textures\\GUI\\Icons\\filter_ore.dds</InputConstraintIcon>
      <OutputConstraintIcon>Textures\\GUI\\Icons\\FilterComponent.dds</OutputConstraintIcon>
    </Class>
  </BlueprintClasses>
</Definitions>
```

### Add blueprint to existing class (preferred mod approach)

`BlueprintClassEntries` is **additive** — multiple mods can safely use it without conflicts.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClassEntries>
    <!-- Add to an existing class by name -->
    <Entry Class="SimpleComponents" BlueprintSubtypeId="MY_RECIPE_SUBTYPE" />
    <!-- Block auto-generates a blueprint using TypeId/SubtypeId format -->
    <Entry Class="LargeBlocks" BlueprintSubtypeId="CubeBlock/MY_BLOCK_SUBTYPE" />
    <!-- Null subtype blocks use (null) after the slash -->
    <Entry Class="LargeBlocks" BlueprintSubtypeId="JumpDrive/(null)" />
  </BlueprintClassEntries>
</Definitions>
```

### Remove a blueprint from a class

Self-closing `<Entry />` cannot have children — use full open/close tags:

```xml
<BlueprintClassEntries>
  <Entry Class="SimpleComponents" BlueprintSubtypeId="MedicalComponent">
    <Enabled>false</Enabled>
  </Entry>
</BlueprintClassEntries>
```

### Blueprint definition (recipe)

```xml
<Blueprints>
  <Blueprint>
    <Id Type="MyObjectBuilder_BlueprintDefinition" Subtype="MY_RECIPE_SUBTYPE" />
    <DisplayName>My Recipe Name</DisplayName>
    <Icon>Textures\\GUI\\Icons\\component\\MyComponent.dds</Icon>
    <Prerequisites>
      <Item Amount="10" TypeId="Ore" SubtypeId="Iron" />
      <Item Amount="2"  TypeId="Ore" SubtypeId="Nickel" />
    </Prerequisites>
    <Results>
      <Item Amount="1" TypeId="Component" SubtypeId="MY_COMPONENT" />
    </Results>
    <BaseProductionTimeInSeconds>5</BaseProductionTimeInSeconds>
    <!-- IsPrimary=true means this recipe is used for disassembly reverse lookup -->
    <IsPrimary>false</IsPrimary>
  </Blueprint>
</Blueprints>
```

### Gotchas

- **Do NOT copy block SBC files** just to add blueprints — use `BlueprintClassEntries` only.
- **Same item in Prerequisites and Results** — crashes if that item's `<MinimalPricePerUnit>` equals `-1`.
- **Handitem definitions are not valid physical items** in blueprints — use `PhysicalItem` TypeIds.
- **Find the class name** for a production block in `Content\Data\CubeBlocks\CubeBlocks_Production.sbc` — look for `<BlueprintClasses>` on the block definition.

---

## Progression / Research Lock

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Progression -->

Locks blocks behind research. Players must build a "trigger" block to unlock a group; any member of the group unlocks it.

### Lock a block behind a research group

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ResearchBlocks>
    <!-- The block that gets locked -->
    <ResearchBlock xsi:type="ResearchBlock">
      <Id Type="CubeBlock" Subtype="MY_BLOCK_SUBTYPE" />
      <UnlockedByGroups>
        <!-- Must build any block in this group to unlock -->
        <GroupSubtype>MY_RESEARCH_GROUP</GroupSubtype>
      </UnlockedByGroups>
    </ResearchBlock>
  </ResearchBlocks>

  <ResearchGroups>
    <!-- The group — building ANY member unlocks it -->
    <ResearchGroup xsi:type="ResearchGroup">
      <Id Type="MyObjectBuilder_ResearchGroupDefinition" Subtype="MY_RESEARCH_GROUP" />
      <Members>
        <BlockId Type="CubeBlock" Subtype="TRIGGER_BLOCK_SUBTYPE" />
        <!-- Add more trigger blocks here if desired -->
      </Members>
    </ResearchGroup>
  </ResearchGroups>
</Definitions>
```

### Gotchas

- **`MyObjectBuilder_` prefix is optional** in `<Id Type>` and `<BlockId Type>` — both forms accepted.
- **Any member unlocks the group** — you cannot require ALL members, only ANY one.
- Both `<ResearchBlocks>` and `<ResearchGroups>` can be in the same `.sbc` file.
- The `xsi:type="ResearchBlock"` and `xsi:type="ResearchGroup"` are short forms (no `MyObjectBuilder_` prefix needed here).

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/SBC](https://spaceengineers.wiki.gg/wiki/Modding/Reference/SBC) — official SBC modding reference

### Internal
- [SBC_RULES.md](SBC_RULES.md) — universal SBC rules, override/additive behavior
- [SBC_BLOCKS.md](SBC_BLOCKS.md) — block definitions; SubtypeId must match the blueprint's result item

### Local
- Vanilla blueprint SBCs: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\Blueprints\`
- Vanilla production definitions: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\` (`Assembler.sbc`, `Refinery.sbc`, etc.)
