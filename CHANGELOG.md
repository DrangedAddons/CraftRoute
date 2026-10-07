# CraftRoute changelog

## 0.15.0

- Craft tab: component chains open all the way down. Inside an opened reagent, any component you can make yourself has its own +, opening the next level a step further in - e.g. Medium Leather, then the Light Leather it's made from, then the Ruined Leather Scraps for that (up to 8 levels: enough for Forceful Rugged Armor Kit <- Rugged Armor Kit <- Rugged <- Thick <- Heavy <- Medium <- Light <- scraps). Each level says what it's making, what's needed to cover the shortfall above it after what you have, and has its own Make button (work bottom-up; the game needs a click per batch). Each section is titled ("Make Light Leather from:").

## 0.14.1

- Fixed: Split / Combine for essences did nothing - the item use was put on the release of the click, but the game acts on press-down (the default "cast on key down" setting). It now follows that setting.

## 0.14.0

- Craft tab: enchanting essences can be split and combined right from the reagent box, like making Medium Leather from Light. Open a short essence's line (+) and click Split (1 greater into 3 lesser) or Combine (3 lesser into 1 greater); each click does one, and the line shows how many you can do now and how many you're short. (A secure button does the item use, as only a real click may use an item.)

## 0.13.6

- Enchants (and other recipes that make no item) show their spell icon, as in the profession window, instead of a question mark - on the Craft tab, route lists and the recipe picker.

## 0.13.5

- Enchant target: Forever calls the replace prompt REPLACE_TRADESKILL_ENCHANT, which CraftRoute was skipping (it only knew Classic's REPLACE_ENCHANT); it's now recognised and answered.
- Enchant target: the replace-enchant prompt should now actually be answered. A mouse click reaches the secure cover twice (down and up) and the /click was being put on the half the game doesn't run. Now whichever half runs carries it, and a prompt that pops up while the button is still held is answered on release, in the same click.

## 0.13.4

- Fixed: the window came up blank (0.13.3). The game won't let a secure button be anchored to an addon frame, so building the Craft tab failed; the enchant covers are now placed by screen position and follow the window.
- If a tab fails to build, the others still work, and CraftRoute errors now show in the game's error window (scriptErrors / BugSack) with their stack, not only as a chat line.

## 0.13.3

- Enchant target: the "replace the existing enchant?" prompt is answered the way the classic enchanting macro does it, with a /click on the prompt's Yes button. The game ignored the addon pressing it directly. The target slot and the Enchant button are covered by secure buttons that do the /click as part of your click: if the prompt appears straight away, the same click answers it; if it appears a moment later, your next click answers it instead of casting again. The covers are hidden in combat.
- /cr popup lists any dialogs that are showing, to help track down a prompt that isn't being answered.

## 0.13.2

- Enchant target: the "replace the existing enchant?" prompt is now answered inside your click, which is the only time the game accepts the answer (0.13.1 answered it a frame later, so the prompt stayed up). If the game asks a moment after the cast instead, the status line says "Click Enchant (or the target) to replace the enchant" and your next click confirms it rather than casting again. Enchanting outside CraftRoute still asks as normal; binding prompts are never answered for you.

## 0.13.1

- The window shows the addon version (e.g. v0.13.0) in the top right, beside the close button.
- Enchant target: the "replace the existing enchant?" question is answered Yes by pressing the dialog's own Accept button (falling back to answering it directly), whether the client raises it by event or as a dialog. Only for a cast you just started from the Craft tab - one answer per click; binding questions are never answered for you.

## 0.13.0

- Craft tab: make components right from the reagent box. A reagent you're short of and can make yourself gets a small + (or click its line): the line opens up underneath to show what it's made from (e.g. 23/4 Light Leather under Medium Leather) and a "Make 5" button that starts crafting it straight away. Nothing else moves off screen. Works for Medium/Heavy/Thick Leather, Bolts of Cloth, Handfuls of Bolts and other same-profession parts; for enchanting essences it tells you to right-click them in your bags to combine or split.
- Craft tab, Enchanting: an "Enchant target" slot above the cast bar for item enchants (Enchant Bracer / Boots / Gloves / Chest / Cloak / Shield / Weapon / 2H Weapon / Off-Hand / Necklace - ...). Hover it to pick from gear the enchant fits: what you're wearing or what's in your bags (never the bank or alts). Unbound items are included; enchanting one binds it, and the game still asks you about that. Bag items and unenchanted ones are listed first. Click the slot (or Enchant) to cast it on the target; the game's "replace the existing enchant?" question is answered for you, so each click is one enchant until the step is done. Right-click clears the target.
- Fixed: hovering the enchant target slot spammed Lua errors and the pick list wouldn't close (Forever has no MouseIsOver).
- Enchant target: the pick list stays open while you move over to it and along it; it closes about half a second after the mouse leaves both.
- Craft tab: reagent boxes no longer spill over the rest of the tab. The current recipe's and the previews' boxes stop just above the cast bar (following the window size) and scroll - mouse wheel or drag the slim bar - when a recipe has more reagents than fit. They also show up to 8 reagents now (some recipes need 7 or 8; only 6 showed before).
- Craft tab follows your goal: it used to run the route on to 300 whatever goal you'd picked; now it stops where the Plan tab does. A Goal dropdown next to "Route" is the same setting as the Plan tab's, so changing either changes both (with the custom skill box when "Custom skill" is picked). Reaching the goal says so and points you at the dropdown.
- Craft tab: "Show unlearned" tickbox under the profession picker, the same setting as the Plan tab's "Show professions I haven't learned". Unlearned professions are greyed out in the list.
- Prices everywhere (Plan materials, the Craft tab list and cost bar, the buy box) use the gold / silver / copper coin icons like vendors do, leaving out empty units: 13s 50c instead of 0g 13s 50c.
- Craft tab: the right-hand column is split. The route keeps the top two thirds; the bottom third shows the plan's materials in compact form (have / need and cost, as on the Plan tab), with a small bar under it showing the cost of everything still missing. It follows the window size.
- Craft tab: buy reagents from the vendor you're talking to. With a merchant window open, any reagent of the current recipe that vendor sells (for gold) and you're short of gets a "Buy" button. It opens a small buy box: Buy 1, Buy needed (what this step still needs in your bags), or any amount with the arrows (starts at 1, so a stray click only buys one). Shows the price each, what "Buy needed" costs (just above the button), and the custom total. Purchases are capped by the vendor's stock and your gold; items sold in bundles buy whole bundles.
- Special crafting stations are flagged in red: "Tanning Rack required" above the recipe on the Craft tab, under the Up next / After that previews, and in recipe tooltips. Covers Tanning Rack, Sewing Machine, Spinning Wheel, Loom, Master Forge, Anarchist's Workbench, Iron Oven, Fermenter, Alchemy Lab, Arcane Forge, Black Anvil/Forge, Icebellow Anvil and Moonwell. Everyday Anvil / Forge / Cooking Fire and carried tools aren't flagged.
- Craft tab: one colour rule for the current recipe and the Up next / After that previews. Green = everything for the whole step is in your bags; yellow = not the whole step, but at least one craft (counting bank / mail / alts - the "Fetch from bank/alts" line says what to fetch); red = not even one craft anywhere. "Crafts ready" follows it too. Counts show the whole step.

## 0.12.1
- Craft tab: "Crafts ready: 1/16" in the reagent box shows how many of the step your bags can make right now (green all, yellow some, red none).
- Craft tab: reagent counts now cover the whole step, not a single craft. For 16 Hillman's Leather Gloves you'll see 42/224 Medium Leather and 4/64 Fine Thread, in green, yellow or red as before. The previews show their whole step too.
- Craft tab: a crafting cast bar above the status line. It shows the recipe's icon, a filling bar with a spark, and "Crafting <recipe> · N left" when the game reports how many are queued. It flashes green when a craft finishes and red if it's interrupted, and sits dimmed ("Not crafting") between crafts. Only profession casts are shown.

## 0.12.0
- New **Craft** tab, now the first tab. It shows what to craft right now, and the window reopens on whichever tab you used last.
  - **Top:** a profession switcher, the skill bar ("Leatherworking 141/225"), and under it a step progress bar for the current guide step. For example, "Step 140-155 · 14 points to go · ~16 crafts left". It fills as you skill up.
  - **Recipe row:** the recipe to craft now (big icon, name, and how many points each craft gives), with "Up next" and "After that" beside it at a smaller scale. Their reagent boxes are level.
  - **Skill-up colour band** under the recipe name: the recipe's orange, yellow, green and grey ranges, with a marker at your skill.
  - **Reagents:** the count is everything you have, against what one craft needs. **Green** means it's in your bags, ready to craft. **Yellow** means you have enough but some is in your bank, mailbox or on an alt. **Red** means you don't have enough even counting everywhere: 5 on you plus 5 in the bank of 14 shows red 10/14. Hover a reagent to see exactly where it is.
  - **For the whole step:** what to fetch from the bank or alts, then what you still need to buy, with the cost.
  - **Browse:** ‹ › arrows look ahead through the route without losing your place.
  - **Bottom:** Create All [N], a count box, and Create (Stop while crafting several).
  - **Route column** on the right: the upcoming steps (crafts, extra crafts, targets, training, instructions). The current craft is tinted and the one you're viewing is highlighted. Click a craft to view it.
- The profession window opens by itself when you go to the Craft tab or switch profession there. The game only allows crafting with it open. If you close it, it stays closed until you come back to the tab, and an Open button remains as a fallback.
- Follows the whole route even past your goal.
- The window is now at least 1060 x 620, to fit the Craft tab. It recentres its contents when resized.

## 0.11.0
- Guide alternatives are now shown as what you'd craft instead of material sources. For example: "A: 20x Cured Heavy Hide, 16x Hillman's Leather Gloves, 10x Barbaric Shoulders, 10x Guardian Gloves" or "B: 21x Hillman's Leather Gloves, 15x Barbaric Leggings, 10x Barbaric Harness".
  - The guide's name for each path and its cost sit in a small grey line underneath.
  - Switch options and the Materials panel shows how the requirements change.
  - Hover an option for its full craft list and what it needs.
- Options with nothing to craft, such as fishing spots, still show the place and what you catch there.

## 0.10.0
- With EllesmereUI installed, a "Look:" picker in the title bar matches CraftRoute to one of EllesmereUI's styles:
  - **EllesmereUI Style:** flat dark panel, thin border, your EllesmereUI accent colour (headings and the active tab's underline) and EllesmereUI's font.
  - **WoW Forever:** Blizzard's frame art, which the Forever client draws in bronze.
  - **Blizzard Style:** retail's frame art.
  - **Classic WoW UI:** the vanilla dialog border over the rock background.
  - **Match EllesmereUI:** follows whichever style EllesmereUI is using.
  - **CraftRoute default:** the original look. This is the default, so nothing changes until you pick something.
- The look is saved account-wide and applies instantly, with no reload. If a style's art can't be drawn on this client, the window falls back to the default look and says so in chat.
- Without EllesmereUI, nothing changes and no picker is shown.
- The Look tooltip opens to the right of the dropdown and closes when you click it, so it never covers the menu.

## 0.9.0
- Routes updated to match the wow-professions.com Forever guides as of 6 Oct 2026. The guide author reworked several of them:
  - **Leatherworking**: rewritten to the new guide.
    - 1-30: Light Leather from scraps, or Light Armor Kits from bought Light Leather.
    - 30-55: Cured Light Hide (keep 24 for later).
    - Journeyman is now one route: Embossed Gloves → Medium Leather → Cured Medium Hide → Fine Leather Belts → Light Leather Pants → Dark Leather Belts → Heavy Leather.
    - Expert: Cured Heavy Hide or without Heavy Hide to 175, then Guardian Gloves 175-195 and Nightscape Headband 195-210.
    - Nightscape Pants 210-225, taught only by the Artisan trainers.
  - **Blacksmithing**: Bronze Shortswords 125-140, then Bronze Warhammers 140-150. Green Iron Bracers now cover 150-175.
  - **Tailoring**: Woolen Capes now cover 80-95; the Gray Woolen Shirt step is gone.
  - **Alchemy**: Mana Potions 165-195, then Nature Protection Potions 195-230. The 195-215 choice is gone.
  - **Enchanting**: Lesser Wizard Oil for 201-220, replacing Bracer - Strength.
  - Engineering, First Aid, Cooking, Fishing and Fishing + Cooking haven't changed.
- With no prices loaded, totals match each guide's updated shopping list.

## 0.8.2
- Steps you're partway through now scale by recipe difficulty, not just the skill points left. The last yellow points of a step take more crafts than its first orange ones. Example: Leatherworking at 30 on the bought-Light-Leather path now plans 21 Light Armor Kits for 30-45, not 18.
- A "choose ONE" block is hidden once every option you have left comes down to the same thing. Example: at Leatherworking 30+, both 1-45 paths are just "Light Armor Kits until 45".

## 0.8.1
- Guide alternatives are much easier to read:
  - Each option sits on its own tinted panel: green when chosen, dark gold when not, with a matching accent bar on the left and a divider between options.
  - A radio marker sits next to the option name.
  - A "Choose" button on the right turns into "✓ Selected" for the option in use. You can click the button or anywhere on the option.
  - The materials and cost summary now sits on its own line(s) under the option name.
- The heading reads "Guide alternatives - choose ONE:".

## 0.8.0
- Smelting: if this character has Mining, bars a plan needs can now come from ore you already have.
  - It uses the bars you have first, then smelts only as many as your ore covers (bags, bank, mail, and alts if that option is on). Whatever's still short is listed to buy as bars.
  - Smelted bars appear as "+N" on the bar's material row, and as a "+ Nx Smelt Copper from your ore - for ..." line above the step that uses them. The ore shows as a material, marked as used up.
  - Works through chains: Bronze from Copper and Tin Ore, Steel from Iron Bars plus Coal. Mining skill is respected - you only smelt what you can.
  - Applies to every profession that uses bars (Blacksmithing, Engineering, ...).
- Mining smelting recipes added (Data/MiningRecipes.lua). Mining itself still has no leveling route until a Forever guide exists.

## 0.7.1
- Item tooltips now cover every profession this character has learned, not just the one selected on the Plan tab. The selected profession is included too, marked "(not learned)" if you don't have it. When more than one profession needs an item, each gets its own heading. Cooking and Fishing's combined guide only appears once.

## 0.7.0
- Every row in the Steps list now word-wraps, including crafts with notes, alternative options, extra crafts and targets. Nothing is cut off any more. Colours carry across line breaks.
- The window is resizable: drag the grip in the bottom-right corner. Its size and position are remembered.
  - Steps take about 56% of the width and Materials the rest. Steps re-wrap to the new width.
  - Material names use all the space left of the count and cost columns.
  - On the Recipes tab, the recipe name column grows with the window.
  - Lists show more rows when the window is taller.

## 0.6.3
- New "Show professions I haven't learned" tickbox next to the Steps heading. It's per character and ticked by default. Untick it to list only this character's professions in the profession picker. The profession you're viewing stays in the list, and if this character hasn't learned any profession yet, everything is listed.

## 0.6.2
- Goals are named after the profession ranks instead of "tiers". The goal list now has:
  - "My rank: Journeyman (150)"
  - "My level's highest rank: Expert (225)"
  - each rank by name: Apprentice (75), Journeyman (150), Expert (225), Artisan (300)
  - End of guide
  - Custom skill
- "Max (300)" became "Artisan (300)". A saved Max goal switches over automatically.

## 0.6.1
- New goal option, "Highest tier for my level": the top skill your character level lets you train. At level 30 on the beta it stops at 225 (Artisan needs level 35); on live it reaches 300 once you're high enough, with nothing beta-specific coded in. The goal line says which tier your level is blocking.
- "Current tier cap" still means the cap of the tier you're in (75 for a profession you haven't learned). "Max (300)" shows the whole route with no level limit.

## 0.6.0
- New professions, each following its wow-professions Forever guide with a recipe database for the Recipes tab:
  - **Alchemy** (182 recipes), 1-300. Choices at 1-10 (Peacebloom or Silverleaf elixir), 130-165 (Fire Oil and Fire Power, or Lesser Mana Potions), 195-215 (Elixir of Defense or Nature Protection Potion) and 275-290 (three recipes).
  - **Enchanting** (222 recipes), 1-300. Choices at 20-70 and for the 70-150 Lesser Magic Essence or Strange Dust path. Shows the faction's only Expert trainer and the Annora (Uldaman) Artisan steps.
  - **Engineering** (247 recipes), 1-300. Choices at 100-105, 125-135 and 175-194. Powders, bolts, tubes and frames carry over to the bombs, dynamite and sheep that use them.
  - **Tailoring** (417 recipes), 1-225, with auto-filled steps after that. Choices at 100-125 and 140-150. Any bolts you're short of are added as extra crafts.
  - **First Aid** (32 recipes, including the healing potions that moved from Alchemy in Forever), 1-300. Choices for 1-75 (bandages or Minor Healing Potions) and 210-225. Expert is a book bought from the faction's vendor; Artisan is the Triage quest.
- With no prices loaded, material totals match each guide's shopping list.
- Parts the guides mark as untested on beta (most of 225-300) are labelled in the step notes.
- Build script: profession names with spaces (First Aid) now find their TrainerSpells files.

## 0.5.0
- New profession: Blacksmithing. It works like Leatherworking, following the wow-professions Forever guide 1-225, with auto-filled steps after that. The guide's alternatives are "do ONE of these" blocks: Copper Belt or Silver Rod, Solid Grinding Stones or Golden Scale Bracers, Mithril Gauntlet or Shoulder, and Steel Plate Helm alone or with Mithril Spurs. With no prices loaded, the materials add up to exactly the guide's shopping list. The Blacksmith Hammer is listed as a material. 441-recipe database for the Recipes tab.
- Mining isn't included yet: wow-professions has no Forever Mining guide so far.
- Fishing "fish in one of these places" bands are now pick-one blocks: starting zone (1-75), capital or nearby zone (75-150), Expert zone (150-225) and Artisan zone (225-300).
- Fishing + Cooking: the Horde 75-130 capital (Thunder Bluff, Undercity or Orgrimmar) is now a choice too. Undercity yields fewer fish, since a third of the catch there is junk. Starting-zone and capital options show what you'll catch there.
- Fishing + Cooking: every fishing step now says which fish it catches and which cooking step needs them, e.g. "Catches Raw Mithril Head Trout for Cooking 175-225".
- Faction filtering: instruction text, notes, trainer locations, option labels and recipe sources only show your faction's NPCs, zones and quests. Recipe sources use TrainerSpells' per-vendor faction data. Auto-picked steps after the guide ends skip patterns only the other faction can buy.
- A band's general instruction now appears above its pick-one block, and instructions come before crafts that start at the same skill.

## 0.4.0
- New professions: Cooking and Fishing.
- The Plan tab now has a profession picker. It lists every supported profession with your skill, putting the ones this character has first. Until you pick one, it opens on a profession you actually have.
- Cooking and Fishing have a second picker: on their own, or the combined Fishing + Cooking guide.
- Cooking only: each skill band is a "make about N of ONE of these" choice, as in the guide. Recipes for the other faction are hidden. Training, the Expert Cookbook and the Artisan quest appear where they apply, and the quest's items count as materials.
- Fishing only: each band is an instruction to fish in a given place. Lures and the pole count as materials. Journeyman training, the Expert book and the Nat Pagle quest appear as training steps.
- Fishing + Cooking: the combined guide is followed in order across both skills. Each step is tagged Fish or Cook and disappears once that skill passes it. You pick your starting zone once, and Horde and Alliance get their own steps. Fish the guide says you'll catch cover the cooking steps, so the materials list only shows fish you'll be short of. Where the guide says "cook all of them", the number of cooks is estimated from the recipe's skill colours (shown as ~N).
- Long instructions wrap across several rows. Hover one to see the full text, what to buy and the expected catch.
- Cooking recipe database (125 recipes) added for the Recipes tab.
- Training steps now appear where you can first train, not at the tier cap.

## 0.3.0
- Bank, mail and alts: CraftRoute now reads Syndicator, which is installed with Baganator and tracks every character's bags, bank, mail and equipped items. EllesmereUI only stores alts' gold, not their items.
- Hover a row in the Materials list to see where you have that item, e.g. "Grove (you): 3 bags, 40 bank, 5 mail" and "Confucius: 10 bags, 60 bank".
- "Have" now counts this character's bags, bank and mail. A new "Count items on alts as owned" checkbox (per character, off by default) adds your alts' stock.
- Without Syndicator, "have" falls back to this character's bags and bank only.

## 0.2.0
- The guide's alternative paths now appear inside the Steps list as "do ONE of these" blocks. Each block shows both options with their main materials and AH cost.
- Click an option to choose it. Only the chosen option's steps (marked with a green bar) count towards the materials list and the total cost. Until you choose, the guide's first option is used.
- Removed the row of route dropdowns above the lists, so the lists are taller.

## 0.1.1
- Fixed: the addon failed to load in the Forever client, so `/cr` and tooltips did nothing. Forever uses retail-style APIs and is missing some Classic events, and registering an event the client doesn't have is an error. Events are now checked with `C_EventUtils.IsEventValid` before registering.
- Skill detection now uses `GetProfessions`/`GetProfessionInfo`, falling back to `C_SkillInfo` and then the Classic skill-line API.
- Known recipes are read with `C_TradeSkillUI` when the client has it.
- Item functions now use `C_Item` (GetItemInfo, GetItemCount, icons).
- The dropdowns and scrolling lists are now built by the addon itself instead of using Classic-only templates.
- Errors are now printed to chat as "CraftRoute error: ...", since script errors are hidden by default.

## 0.1.0
- First version for the WoW Forever beta client (Interface 16001). Leatherworking only.
- Plan tab: the guide's leveling steps from your current skill to a goal you choose (next target recipe, current tier cap, 225, 300 or a custom number). Steps you're partway through are scaled down. It also tells you when to train the next tier and warns if your character level is too low.
- Route choices from the guide: scraps or bought Light Leather, Medium Hide or not, Heavy Hide or not, and Thick or Heavy Leather for 175-200.
- Skill ranges the guide doesn't cover yet (225-300) are filled automatically with the cheapest trainer or vendor-pattern recipe. These steps are marked as not from the guide.
- Target recipes: tick recipes in the Recipes tab (shift-click to want more than one). They're crafted as soon as your skill allows, and recipes you already own are skipped.
- Materials list: what you have against what you need. Intermediates made earlier in the route (belts, cured hides, Heavy Leather) are passed on to later steps. If you're short on a craftable intermediate, extra crafts are added for it.
- Auctionator: vendor or AH price for each material, the total cost to buy what's missing, and a button that builds an Auctionator shopping list.
- Item tooltips list every step and target that needs the item, with have/need counts for your goal and for the full route.
