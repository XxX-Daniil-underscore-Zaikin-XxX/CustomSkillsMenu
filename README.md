# Custom Skills Menu

This is a slight rework of [Osmosis Wrench](https://www.nexusmods.com/skyrimspecialedition/users/2801784)'s [Custom Skills Menu](https://www.nexusmods.com/skyrimspecialedition/mods/62423?tab=description) to make it compatible with Custom Skills Framework 3.1.

> [!IMPORTANT]
> The [original mod](https://www.nexusmods.com/skyrimspecialedition/mods/62423) is hard requirement! Please support [Osmosis Wrench](https://www.nexusmods.com/skyrimspecialedition/users/2801784) too - this mod wouldn't be here if not for their hard work.

## Basics

The Custom Skills Menu adds a fifth option to the tween menu next to Skills. Clicking this option will bring you to a list of Custom Skill groups, and you can select any of these to bring up the corresponding skill tree.

Alternatively, you can set a key in the MCM which will open the Custom Skills without the tween menu.

It should all work out-of-the-box - the Custom Skills Menu reads the Custom Skills Framework v3 `.json` files and automatically generates the necessary data.

## Configuration

You may find that the generated data is generic and poorly formatted. For now, you can fix this yourself.

The generated data can be found in `interface\MetaSkillsMenu\MSMData.json`, and you can edit the `Name` and `Description` as suits you. You may also want to change the `icon_loc` - this should be a path to a `.dds` file that'll serve as the icon.

Some Custom Skills are, for one reason or another, intentionally inaccessible through normal gameplay. Using the Custom Skills Menu for these skills, then, may bypass some requirements and make for a worse experience.

You can fix this my hiding the errant skills. Simply edit `interface\MetaSkillsMenu\MSMHidden.json` and set the skill set's `hidden` to `1`.

## Requirements

To use this mod, you will need the following:

- The original Custom Skills Menu
- PapyrusUtil
- SkyUI
- SKSE
- JContainers
- ConsoleUtilSSE
- MCM-Helper
- CustomSkills
- PO3's Papyrus Extender