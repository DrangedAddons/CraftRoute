# CraftRoute data tools

`build_recipes.py` regenerates `Data/<Profession>Recipes.lua`. Run it from this `tools` folder.

Inputs:
- `sources/endgametools_<prof>.html`: https://endgametools.com/en/wow-forever/professions/<prof>. Provides reagents, yellow/green/grey thresholds, stats, categories and crafted item IDs.
- `sources/ahledger_<prof>.html`: https://ahledger.com/wow-forever/professions/<prof>. Provides learn (orange) skill and yields. There is no First Aid page, so leave that argument off for it.
- The TrainerSpells addon's `data/forever` folder. Provides recipe sources and each vendor's faction. Its skill keys are stale Classic Era values for some recipes, so they're only a last resort.

The saved pages in `sources/` are not committed; they're third-party pages. To refresh the data after a Forever patch, download the two pages for each profession into `sources/` and run, e.g.:

```
python build_recipes.py sources/endgametools_leatherworking.html "<AddOns>/TrainerSpells/data/forever" Leatherworking ../Data/LeatherworkingRecipes.lua sources/ahledger_leatherworking.html
```

Every profession is built the same way: Leatherworking, Blacksmithing, Tailoring, Alchemy, Enchanting, Engineering, Cooking and First Aid. Use the profession name as shown in-game, e.g. `"First Aid"`; the TrainerSpells file name drops the space. The script fills a few gaps in the sources itself through its `OVERRIDES` table, such as Mithril Headed Trout's item ID.

The routes (`Data/<Profession>Route.lua`) are entered by hand from the wow-professions.com Forever guides, `https://www.wow-professions.com/forever/<prof>-leveling-guide`. As of Oct 2026, Leatherworking, Blacksmithing and Tailoring stop at 225, and most 225-300 sections are the guides' untested Classic routes.
