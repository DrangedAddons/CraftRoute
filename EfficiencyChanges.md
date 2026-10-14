# Efficiency changes

These edits cut repeated work during login, plan builds, and UI refresh. The profession set, both windows, the virtualized lists, the 0.25s `CR.NotifyChanged` throttle, and the debug slash commands are unchanged. Shipped as 0.50.9, on top of 0.50.8's condensed skill-up colours tooltip. `Data/*Recipes.lua` was not edited.

## What each refresh used to do

`CR.NotifyChanged` waits 0.25s, then drops the plan cache and the location cache and refreshes `/cr`, the profession-frame view, the tracker, and the loot feed. Anything that called it in a loop rebuilt that whole chain.

A plan build walks the route, prices reagents, fills skill gaps, and clips guide forks. The profession-frame Craft view then asked the client about every recipe again. The same task, the same trainer list, and the same font walk ran on every paint.

## 1. Item info no longer rebuilds the plan

`GET_ITEM_INFO_RECEIVED` was on the event list in `Core.lua`. `CR.ItemName` called `GetItemInfo` first. On a cache miss the client queues a load. When the load finished, the event fired, `CR.NotifyChanged` ran, the plan was thrown away, and the next build called `GetItemInfo` for the next missing item. One plan could schedule dozens of full rebuilds.

The event is gone from `Core.lua`. `LootFeed.lua` still listens for it, because the loot toast needs the item once the client has it.

`CR.ItemName` (`Planner.lua`) now resolves in this order:

1. `CR.itemNames`, filled once as each recipe file calls `CR.RegisterRecipes`
2. `CR.extraNames` (route files and a few quest items)
3. `GetItemInfo`, and only when `C_Item.IsItemDataCachedByID` says the client already has the item
4. `"item:" .. id`

`CR.RegisterRecipes` copies each file's name table into that profession and, the first time an item id appears, into `CR.itemNames`. Later professions do not overwrite a name already stored. The per-profession `prof.names` tables stay, and the planner still checks those first.

`CR.FactionText` keeps its result for the session, keyed by faction plus the original string. Strings with no `{` return immediately. An empty result is cached too.

`Pricing.lua` remembers `CR.GetUnitPrice` and `CR.GetAuctionPrice` for 5 seconds, including misses. One plan build and the Craft view's profit sort share those answers. `CR.InvalidatePrices` wipes both caches. Nothing calls it from `CR.NotifyChanged`, so a bag update does not throw the prices away. A price can be about 5 seconds old.

The profession-frame profit sort (`SellValue` in `Compact.lua`) also skips `GetItemInfo` when `IsItemDataCachedByID` says the item is not cached. That sort walks every recipe of the profession. A cache miss there used to queue the same load storm.

What changes for a player:

- Reagent names stay the English strings from the data files even when the client has a localized name cached. That is the point of the name tables.
- An icon can stay a question mark until the next bag or skill refresh. An item-info event no longer repaints the UI.

## 2. The plan is built for the goal on screen

`CR.GetPlans` used to build the plan to the current goal and, whenever that goal was below the route cap, build the whole route again for the tooltip line "to complete the route". Tooltips are the only reader of that second plan.

`CR.FullPlan(entry)` builds it on the first read and stores it on the entry until `CR.InvalidatePlan`. If there is no route, or the goal is already the route cap, `entry.full` is the same table as `entry.plan`. `Tooltip.lua` calls `CR.FullPlan` before `AddProfessionLines`, and that function reads `entry.full`, so the "to complete" line still appears. The first tooltip that needs it pays for the second build. Later tooltips and every window refresh do not.

`AutoSteps` (`Planner.lua`) used to walk every recipe at every skill point in a gap, and parse the source line each time. It now collects the recipes that can still give a point somewhere in the gap (an item, learned before the gap ends, still yellow somewhere in the gap, and obtainable), then the per-skill loop only checks that short list. Obtainable means `src == "Trainer"`, or the character already knows the spell, or the source is a vendor of this faction. The vendor check is `VendorOK`: source starts with `"Sold by"`, `CR.FactionText` strips the other faction, and the result still matches `"^Sold by %S"`. The answer is stored on `r._vendorOK`. `CR.ApplyTrainerSpells` clears that flag when it rewrites a source line. A nil source is treated as not a vendor.

`ForkEvents` clipped the same guide step once per option and again while collecting materials. It now clips each step that has `st.when` and passes `FactionOK` a single time, and the three loops read that table. A step that does not apply is stored as `false`, which the old code treated the same as a missing clip. The loops only read the clip.

## 3. Refresh does less work per craft

### One scan of the open profession

`CR.LiveRecipeInfo(profName, spell)` in `Core.lua` calls `GetAllRecipeIDs` / `GetRecipeInfo` once per profession per refresh, and only when `CR.TradeSkillOpenFor` says that profession's window is the one open. `CR.NotifyChanged` bumps the token first (`CR.BumpLiveRecipes`), so a bag change starts a fresh scan on the next query. `numAvailable` goes stale if bags change without a notify. Bag events already notify.

`CR.RecipeLearned` and `CR.CraftsReady` live next to that scan.

- Learned is the live `info.learned` when the window answered. Otherwise it is true if a previous scan saved the spell, and nil when nobody has said. Nil means unknown. The Craft view already treated nil as unknown and false as "the window says you have not learned it".
- Craftable is live `numAvailable` when that field is a number, including 0. Otherwise it is bag math: `CR.GetItemCount(id, false)` divided by the reagent count. A count below 1 is treated as 1. This does not call `CR.BagsAndElsewhere`, which asks Syndicator about the bank and alts.

`RecipeState` in `UICraft.lua` uses that scan, then `CR.CraftsReady` if the window had no count. The profession-frame Craft view calls the same two functions. It used to call `GetRecipeInfo` once per recipe per filter pass. `RecipeSlot` remembers the gear slot on `r._slot`, because the destination list asked twice per recipe and the slot does not change.

The task list keeps its own `RecipeLearned` (`Tasks.lua`). It uses the same live scan, then the saved known-table. If that table has entries and this spell is absent, it returns false, so a "learn this recipe" row still appears. If the table is empty, it returns nil, and the row stays hidden until a scan exists. That nil-versus-false split is what the learn-task is built on. The shared `CR.RecipeLearned` stays nil in the unknown case, which is what the craft buttons want (`~= false` still allows a create when the window has not answered).

### Tasks are reused, and NPC lookups stop walking TrainerSpells

`CR.StepTask` was called twice per refresh for the same step (the route list and the action list). The task is stored on the step (`st._task` / `st._taskNil` / `st._taskProf`). `CR.BuildPlan` makes new step tables, and `CR.NotifyChanged` invalidates the plan, so bag counts and skill checks are redone when the plan is. A second caller in the same refresh gets the same task object.

That means a quest-log change does not rewrite a task that is already on the current plan. `QuestInLog` caches a readable yes/no per title until `QUEST_LOG_UPDATE`, and does not cache a nil when the log cannot be read. The displayed task still updates on the next plan rebuild (the next bag, skill, or profession event). `QUEST_LOG_UPDATE` is noisy, and it does not itself rebuild the plan.

`Trainers(prof, rank)` is cached for the session. The "supply vendor stands next to the trainer" path used to append `" (prof trainer)"` onto the cached NPC's name. It now copies the fields into a new place, so the trainer list stays the trainer's own name.

`Nearest` is cached by the place list, the player's map, a position bucket of about 5% (`floor(x * 20)`), and the max count. The same trainer list on every row was converting map coordinates every time. The nearest trainer can stay put until the player crosses into the next bucket or the plan rebuilds. The cache key uses a side table of list ids, so the place lists themselves are not tagged.

`CR.ApplyTrainerSpells` already walked vendor `sourceLocations` and trainer costs at `PLAYER_LOGIN`. It now keeps three maps while it does that:

- `CR.tsVendors[prof][spell]` — vendor places `{name, uiMapID, x, y, faction}`
- `CR.tsCost[prof][spell]` — trainer copper cost
- `CR.npcIndex[name]` — vendor NPCs, deduped by map and half a coordinate

`Tasks.lua` `RecipeVendors` and `TrainerCost` read those maps. `TrainerCost` prefers `r.cost`, which `Apply` already wrote onto the recipe. If `ApplyTrainerSpells` has not run, both functions fall back to the old walk. `Index()` uses `CR.npcIndex` when the vendor map exists, and does not walk `sourceLocations` again. It still adds profession trainers from `TrainerSpellsProfessionTrainers` and the three guide NPCs in `EXTRA_NPCS` (Old Man Heming, Shandrina, Nat Pagle). `NpcsInText` is unchanged and still handles names that appear only in guide prose.

### Fonts

`CR.ApplyThemeFonts` walked every font string under the window on every refresh. `Theme.lua` now stamps `crFontKey` and `crFontEpoch` on the root and returns when both match. `CR.NoteThemeFonts(obj)` bumps the epoch and styles that widget immediately (a `FontString` or `EditBox` directly, anything else by walking its children).

Call sites, only where the widget is created:

- `UI.lua` list rows, and dropdown buttons (those menus are parented to `UIParent`, so the window walk never sees them)
- `Compact.lua` list rows, the lazy `crSub` / `crSub2` lines, the quantity `EditBox`, the quantity button's text, the Create buttons, material rows, and enchant flyout rows
- `Tracker.lua` rows, only the first time that row index is created

The shared frame metatable is not hooked. Rows that already exist are not noted again on paint. The reagent rows and expand rows in `UICraft.lua` are created once when the panel is built, before the first theme walk, so they are left alone. The refresh functions still call `CR.ApplyThemeFonts`. After the first paint that call returns immediately until a new widget bumps the epoch, and then one walk covers the tree.

### OnUpdate

The profession-frame schematic frame ran every frame: batch bar, "is a Blizzard page showing", and `SyncEnchantSecure`. `SyncEnchantSecure` calls `GetLeft` / `GetBottom`, which forces layout. That work now runs on a 0.1s tick. The button label, "anvil required" text, and `SyncOpenProfession` stay on the 0.4s tick they already had. The enchant flyout's OnUpdate still runs every frame, and only while the flyout is shown.

`UICraft.lua` secure covers are parented to `UIParent`. A hidden frame still receives `OnUpdate`. After the Craft tab had been opened once, those covers followed their targets for the rest of the session, including while `/cr` was hidden. `TrackCover` is set only while the cover is shown, and cleared in `SyncSecureButtons` when the cover hides and in `CR.HideSecureEnchantButtons`. In combat the updater returns without touching secure state. `SyncSecureButtons` still places the cover before showing it, and still refuses to run during combat lockdown.

`ResolveTarget` scanned worn and bag gear twice (`CR.EnchantCandidates`). It scans once. The profession-frame enchant resolver already scanned once.

## 4. One craft path

`CR.CraftSpell(spell, count, profName)` is in `UICraft.lua`, next to the local `Craft()` the Craft tab already used. The profession-frame view deleted its copies of learned / craftable / craft and calls `CR.RecipeLearned`, `CR.CraftsReady`, and `CR.CraftSpell`. `Compact.lua` loads after `UICraft.lua`, so the function exists.

`CR.CraftSpell`:

- refuses in combat
- floors the count at 1
- if that profession's window is not open, calls `CR.OpenTradeSkill` and returns before `CR.StartCraftBatch` (opening the window is a secure click)
- finds the recipe on that profession, then on any profession
- calls `Craft()`, which starts the batch and uses `C_TradeSkillUI.CraftRecipe`, with the classic `DoTradeSkill` fallback the profession-frame view did not have
- if the spell is not in the recipe data, still hands it to the client the same way

The profession-frame `Create` / `Create All` buttons, the schematic Create button, and the component "make this reagent" button go through that function.

One behavior change on the fallback path: when the profession window is not supplying `numAvailable`, "how many can I make" is bags only. The old profession-frame helper added bank and alts through `CR.BagsAndElsewhere`. With the profession window open, which is the normal state of that view, both versions used `numAvailable`. Shopping-list totals still use `CR.HaveCount` / locations, so bank and alts remain visible there.

## 5. The recipe files, and `build_recipes.py`

`Data/*Recipes.lua` is generated by `CraftRoute-tools/build_recipes.py`, which is not accessible by this review process. Each file calls `CR.RegisterRecipes(prof, recipes, names)`. The header says not to edit them by hand. This change set does not. The next generate would overwrite a hand edit, and the runtime name lookup in section 1 already depends on the tables the generator emits today.

### What the files actually weigh

Nine recipe files, 772,433 bytes. The split line `}, {` is where the recipe table ends and the item-id-to-name table begins.

| File | Bytes | Lines | Split line | Lines after the split | Recipe-section bytes | Name-section bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| LeatherworkingRecipes.lua | 186,697 | 1,139 | 517 | 622 | 164,751 | 21,836 |
| BlacksmithingRecipes.lua | 164,020 | 976 | 446 | 530 | 145,378 | 17,883 |
| TailoringRecipes.lua | 144,947 | 931 | 422 | 509 | 128,510 | 16,330 |
| EngineeringRecipes.lua | 85,812 | 603 | 252 | 351 | 73,884 | 11,562 |
| AlchemyRecipes.lua | 56,851 | 435 | 187 | 248 | 48,284 | 8,521 |
| CookingRecipes.lua | 47,205 | 360 | 130 | 230 | 40,102 | 7,089 |
| EnchantingRecipes.lua | 72,600 | 384 | 227 | 157 | 67,612 | 4,951 |
| FirstAidRecipes.lua | 9,403 | 106 | 37 | 69 | 7,266 | 2,135 |
| MiningRecipes.lua | 4,898 | 58 | 22 | 36 | 3,872 | 979 |
| Total | 772,433 | | | | 679,659 | 91,286 |

Counting lines makes the files look like they are mostly names. In eight of the nine, the name table has more lines than the recipe table. Enchanting is the exception (157 name lines after a split at 227), because enchants have no output item and fewer reagents. Those name lines are short (`[2589] = "Linen Cloth",`). The recipe lines are long. By bytes the name tables are 91KB, 12% of the 772KB.

### The case for changing the generator

The name table exists so a reagent has an English name before `GetItemInfo` has cached the item. Section 1 now depends on that. `CR.itemNames` is already one map, first profession to mention an id wins, and `CR.ItemName` reads it before the client. The generator still emits nine copies, and login parses all nine into that one map.

Measured from the name tables:

- 2,743 name assignments
- 2,285 distinct item ids
- 238 ids appear in more than one profession (cloth, bars, vials, thread, dyes, leather)
- the repeated lines are about 12.7KB

A shared name table emitted once by `build_recipes.py` keeps the "name before the client cache" behavior and deletes the 91KB of per-profession copies, leaving one copy of those 2,285 names. The per-profession `prof.names` lookup can stay as a view over that shared table, or `CR.ItemName` can be the only reader. Either way the data file shrinks by the duplicate tables, on the order of 40KB once a single copy remains, and `RegisterRecipes` stops walking the same linen cloth nine times. That is a real saving and it matches the runtime that just landed. It is the smaller of the generator wins. A name-table merge will not cut the addon in half. The line count suggested it would. The bytes do not.

The larger slice inside the recipe records is `src`.

- 2,195 `src` fields
- 68,228 bytes of source text
- 237 distinct strings, 19,418 bytes of distinct text
- about 48.8KB is the same paragraph repeated on many recipes
- 426 of the fields are the single word `Trainer`

Lua interns identical literals, so those repeated paragraphs do not each become their own string at runtime. They are still tokenized while the file loads. The long ones are the vendor paragraphs. The Alexandra Bolero / Jennabink line is 1,232 characters and is stored twice. Micha Yance / Derak Nightfall is 907 characters, also twice. `CR.FactionText` already throws away the other faction's half of `{A:...}` / `{H:...}` at runtime, so the file is carrying both factions' sentences for every recipe.

`build_recipes.py` could store each vendor once (name, zone, faction) and point the recipe at that record. The addon already turns a source into a sentence for display (`FactionText`) and into a yes/no for auto-fill (`VendorOK` only checks that a vendor of this faction remains). Trainer cost and vendor coordinates now come from TrainerSpells at login (`CR.tsCost`, `CR.tsVendors`), not from these paragraphs. The paragraph is a display string the generator chose to inline. Emitting it once per vendor, or building it from the structured record, removes the repeated 49KB from the parse and keeps one copy of each unique line.

A third step is load order, and it is the one that changes login the most. WoW loads the files named in `CraftRoute.toc` and will not `dofile` another TOC file later. The route files are small and they are what fills the profession dropdown, so they stay on the main TOC. Each `*Recipes.lua` can be its own addon with `LoadOnDemand: 1`, loaded the first time `CR.GetPlans` or the recipe list touches that profession. `build_recipes.py` is the place that knows the file list and can emit the per-profession TOC stubs (or a manifest the main TOC does not embed). Until that exists, opening the game parses all 772KB, including Leatherworking, for a character who only wanted Alchemy.

Suggested order, if the generator is changed:

1. Emit one shared name table. Point `CR.RegisterRecipes` at it, or stop passing the second table and fill `CR.itemNames` from the shared file. Keep English names in the data so section 1 does not fall through to `GetItemInfo`.
2. Stop inlining a full `src` paragraph on every recipe. One record per vendor, and a short source kind (`Trainer`, vendor id, quest, world drop) on the recipe. Build the display line in the addon.
3. Emit a LoadOnDemand addon per profession for the recipe file. Leave the route files on `CraftRoute.toc`.

Doing only step 1 is still worth it, because the runtime now has a single name map and the files have not caught up. Doing only step 1 and expecting the addon to drop by half will disappoint. The line counts are in the table above so that misread is easy to see.

## Files touched

- `Core.lua` — name index, faction-text cache, live recipe scan, `RecipeLearned`, `CraftsReady`, item-info event removed from the notify path
- `Planner.lua` — names before `GetItemInfo`, lazy `CR.FullPlan`, cheaper `AutoSteps`, one clip per fork step
- `Tooltip.lua` — `CR.FullPlan` before the profession lines
- `Pricing.lua` — 5 second price caches, `CR.InvalidatePrices`
- `Theme.lua` — `CR.NoteThemeFonts`, skip a repeated font walk
- `TrainerSpellsData.lua` — `CR.tsCost`, `CR.tsVendors`, `CR.npcIndex`, clear `r._vendorOK` when a source changes
- `Tasks.lua` — task memo, trainer / nearest / quest caches, read the TrainerSpells maps, copy near-trainer places
- `UICraft.lua` — `CR.CraftSpell`, live recipe state, one enchant scan, secure OnUpdate only while the cover is shown
- `Compact.lua` — call the shared craft helpers, slot cache, sell-value guard, font notes, 0.1s / 0.4s OnUpdate
- `UI.lua`, `Tracker.lua` — font notes on new rows and dropdown buttons

## Not verified in game

No client pass. Worth a look on the Forever beta, in this order:

- Open a profession, paint the Craft view twice, and confirm learned / Create All / profit sort still match the profession window.
- Hover a reagent that is only needed to finish the route, not the current goal, and confirm the "to complete" tooltip line still shows.
- Enchant an item from `/cr` and from the profession frame, including the replace-enchant Yes click, and confirm the secure cover is gone from `UIParent` after the window closes (no invisible button tracking the screen).
- With EllesmereUI's font set, scroll a list until new rows are created and confirm those rows use the same font.
- Pick up a rank quest and confirm the task line updates on the next bag or skill refresh.
