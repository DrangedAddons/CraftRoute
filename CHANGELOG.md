# CraftRoute changelog

## 0.10.0 (in testing on the `themes` branch)
- With EllesmereUI installed, a "Look:" picker in the title bar matches CraftRoute to one of EllesmereUI's styles:
  - **EllesmereUI Style:** flat dark panel, thin border, your EllesmereUI accent colour (headings and the active tab's underline) and EllesmereUI's font.
  - **WoW Forever:** Blizzard's frame art, which the Forever client draws in bronze.
  - **Blizzard Style:** retail's frame art.
  - **Classic WoW UI:** the vanilla dialog border over the rock background.
  - **Match EllesmereUI:** follows whichever style EllesmereUI is using.
  - **CraftRoute default:** the original look. This is the default, so nothing changes until you pick something.
- The look is saved account-wide and applies instantly, with no reload. If a style's art can't be drawn on this client, the window falls back to the default look and says so in chat.
- Without EllesmereUI, nothing changes and no picker is shown.

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
