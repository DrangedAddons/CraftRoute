# CraftRoute changelog

## 0.85.8

- The in-game icon is now 64x64 and sharpened, upscaled from the 32x32 original, so it's less blurry on the CraftRoute tab.

## 0.85.7

- New CraftRoute icon, a purple repair hammer. It replaces 0.85.6's book everywhere: the profession window's CraftRoute tab, the minimap button, the in-game AddOns list, and the DrangedAddons manager.

## 0.85.6

- New CraftRoute icon, a profession book with a blue gem. It shows on the profession window's CraftRoute tab, the minimap button, the in-game AddOns list, and the DrangedAddons manager. The addon ships it as icon.tga, so it doesn't depend on the client having that game icon.

## 0.85.5

- Mining: the **mine, or smelt bought ore** choice is now shown like the crafting professions' choices, as **Choose one** with a row per option. **Smelt bought ore** shows the ore it needs and what it costs. Picked, its smelting steps are normal route craft steps, opening the craft panel. The zone choices stay dropdowns.

## 0.85.4

- Mining for Skyborne: the **Learn Mining** step names the quest giver, **Dalia the Collector** in Thendal Village, and lists her under Where with a map pin (from Questie). The two nearest trainers stay listed with her.
- It also gets an optional tick, **Optional: quest Harvesting Windstones done**. It ticks once you've finished the quest. The step itself still only needs Mining learned, so learning from a trainer completes it too.

## 0.85.3

- Mining for Skyborne: the usual **Learn Mining** step is back, with the nearest trainers to pin. It also offers the Harvesting Windstones quest on Zephras Isle as another way to learn it. Since 0.85.1 the quest had replaced the trainer step, but any Mining trainer teaches it too.

## 0.85.2

- Fix: Skyborne characters now see **Learn Mining from Harvesting Windstones**. The race check only read the race's display name ("High Order Skyborne"), not its race id ("Skyborne"), so it never matched.

## 0.85.1

- Mining for Skyborne: the first step is now **Learn Mining from Harvesting Windstones**. Take the quest in Thendal Village and pick Mining for Dummies as your reward. The step names the island's trainers (Halavuul Cragwind in Valanaar, Messana Crestwind in Shen'dar Village) and ticks off once Mining is learned. Other races keep the usual Learn Apprentice Mining step.
- Guide steps can now be limited to one race, the same way they can be limited to a faction.

## 0.85.0

- Mining now follows wow-professions.com's new **Forever** Mining guide, replacing the Classic stand-in.
  - **1-120: Mine, or Smelt bought ore.** A new choice at the top. Mine (the default) keeps the zone choices. Smelt bought ore plans Smelt Copper x130, Smelt Tin x70, Smelt Bronze x70 and Smelt Silver x40 to reach 120, with the ore in the route's materials. After smelting, the 65-125 zone pick starts at 120.
  - **New zones:** Teldrassil and Zephras Isle for 1-65. Wetlands, Silverpine Forest, Westfall and Stonetalon Mountains join 65-125.
  - **Zone steps:** each carries the Forever guide's notes (fast cave respawns, where the nearest forge is, which caves to skip at low level) and the veins to mine with their skill.
  - From 125, the guide follows the Classic routes until its author revises them.
- Route choices that depend on another choice now only show when they apply. Mining's 1-65 zones hide when you pick Smelt.

## 0.84.4

- Fix: with the profession window open, the CraftRoute key now closes it on the first press, whatever tab or page is showing. On the Professions summary page it used to load a profession first and switch to CraftRoute's tab, so it took three presses to close. The next press reopens the profession and view you were last on.

## 0.84.3

- CraftRoute keybind: with nothing learned, it opens Blizzard's professions frame. With a profession learned, including only Herbalism, Skinning, or Fishing, it opens CraftRoute's tab on that profession's guide. It no longer opens the `/cr` window. Press it again to close.

## 0.84.2

- README updated. The EfficiencyChanges.md notes file is removed. No changes in game.

## 0.84.1

- Fix: the "Binding header CRAFTROUTE was attempted to be loaded more than once" error on login or reload. The new Materials window binding declared the CraftRoute key binding header a second time.

## 0.84.0

- New key binding: **Materials window** opens and closes the Materials window. Set it in Settings > Key bindings, under the Profession tab key: click the button, then press a key, or right-click to clear it. It's also under Options > Keybindings > AddOns > CraftRoute. It has no default key.

## 0.83.3

- Loot feed: a material you have enough of now reads **complete** instead of enough, such as **142/98 - complete**.

## 0.83.2

- Loot feed: once you have enough of a material, its line shows your real count in green with **enough**, such as **142/98 - enough**. Before, it was capped at the amount needed (98/98), which looked like you'd only just reached it.

## 0.83.1

- Fix: the **Herbs to pick** and **Veins to mine** lists from 0.83.0 now show on the step's card. The route plan wasn't passing them through.

## 0.83.0

- Mining and Herbalism: a zone step's card lists the herbs or veins that band is after, under **Herbs to pick** or **Veins to mine**, just above Mark as done. Each one shows the skill it needs, in green when you can gather it now and red when you can't yet. For example, Teldrassil lists Peacebloom 1, Silverleaf 1 and Earthroot 15.

## 0.82.3

- Herbalism guide: the grey advice rows between bands are gone. Which herbs to look for in each band is now in every zone's step.
- Every Herbalism step has a short title, such as **Pick herbs in The Barrens**, instead of a sentence lifted from its text.

## 0.82.2

- Mining guide: the grey advice rows between bands, which couldn't be clicked, are gone. Their advice (Silver and Gold to smelt, and when Truesilver, Small Thorium and Rich Thorium open up) is now in each zone's step, so it shows in the step's details whichever zone you pick.

## 0.82.1

- Mining guide: every step has a short title instead of a sentence lifted from its text.
  - Each zone step is titled **Mine in <zone>**.
  - Each band opens with a step like **Iron and Gold; smelt Gold at 155**.
  - 175-245 gets an opening step too, **Mithril, then Truesilver at 230**.

## 0.82.0

- In the Craft view's recipe panel, a reagent you're short of and can make yourself has a small **+** at the bottom right of its icon. Click the reagent to show how to make it underneath:
  - First a line like **Make 3 with Leatherworking**, with its button (Make, Smelt, Open, Combine or Split).
  - Then what that takes, with Buy and Vendor buttons where you're short. Each of those can open the same way.
  - Click the reagent again to close it. The panel looks the same as before until you open one.

## 0.81.8

- A reagent you can make yourself, with any profession you've learned, no longer gets a **Vendor** button. Crafting it beats tracking down the odd vendor that stocks it, and the vendor filters treat it the same way. A vendor that has it open still shows **Buy**.
- Limited-stock vendors are no longer remembered as places that sell an item.

## 0.81.7

- In the Craft view's recipe layout, the skill colour bar has its own line under the recipe name, and the station line (such as Tanning Rack required) sits under the bar. Both line up with the name and no longer overlap.
- Clicking back into **Search recipes** selects the text that's there, so typing replaces the old search.
- The **Favorites** and **Recipes** headings in the recipe list take up less space.

## 0.81.6

- In the Craft (List) view, the tooltips for your crafts now open to the right of the hovered row, hanging down from its top, like the recipe list's. Before, they covered the recipe list.

## 0.81.5

- The Craft view's recipe rows no longer show the **+** / **-** marker. Clicking a row still opens it in place, and the star moves into the marker's spot.

## 0.81.4

- The Route view's step, reagent and task tooltips now hang down beside the row too, like the Craft view's. If one would run off the bottom of the screen, it opens upward as before.

## 0.81.3

- The **Craft** button now switches the Craft view's layout, and the separate Recipe / List button is gone. From Route, Craft opens the layout you last used. Clicking Craft again while on it switches between **Craft** (the recipe layout) and **Craft (List)**. The button shows which layout you're on, and the choice is kept per character.

## 0.81.2

- In the Craft view, a recipe's tooltip now hangs down beside the row. Its top lines up with the row's top, instead of the tooltip sitting above the row. If it would run off the bottom of the screen, it goes back to opening upward.

## 0.81.1

- The Craft view's **Recipe** / **List** button moved to the top left of the right column, level with Materials. The search box has its full width back.

## 0.81.0

- The Craft view has a second layout. The **Recipe** button, left of the search box, switches to it, and **List** switches back. The choice is kept per character.
  - The recipe list stays on the left, with search, Filter and sorting.
  - Starred recipes move to a **Favorites** heading at the top of the list.
  - Clicking a recipe shows it in the right column, as on the Route view: its icon and name, whether you know it and where to learn it (with map pins), the station it needs, reagents with Buy and Vendor, cost and profit, Shopping List, Count alts, and the Create buttons.
- The List layout is unchanged: your crafts on the right, with the shopping list and amounts.

## 0.80.0

- **Anvil required** and **Forge required** pin more of them: The Great Forge and Great Anvil in Ironforge, the Thunder Bluff Forge, Heated Forges, Stone and Foundry Anvils, Grimand's Anvil, and Dredan's Forge.
- **Black Anvil**, **Black Forge**, and **Icebellow Anvil required** can now be clicked to pin them.
- A camp structure (Master Forge, Molten Foundry, Alchemy Lab, Tanning Rack, and the others built from Camping blueprints) is never pinned. Hovering its red words says it's a camp structure instead.

## 0.79.6

- **Cooking Fire required** also pins more fires and cooking stations: Dwarven Brazier, Crude Brazier, Dwarven Fire, Warm Fire, Raging and Roaring Bonfires, Firepits, Cooking Brazier, Cooking Table, Table Cooker, and the meat racks and smokers. This covers Ironforge, Durotar, Loch Modan, and the Stormwind taverns. The player-made Basic Campfire is still not pinned.

## 0.79.5

- **Anvil required**, **Forge required**, and **Cooking Fire required** on the Route tab pin the nearest one when you click the words. Questie provides the locations. The line stays red until you are standing at one, and a green line does not pin. Alchemy Lab and the other camp stations still show, and are not clickable.

## 0.79.4

- A reagent's **Vendor** button pins the nearest vendor for that item. Questie provides the locations (listed under Recommended addons); WaypointUI names the pin when it's installed. Standing at a vendor that sells it still turns the button into **Buy**.

## 0.79.3

- The reload prompt is only set up when the game's popup table is there (no error loading without it).

## 0.79.2

- Fixed: pressing **Escape** brought up "CraftRoute has been blocked from an action only available to the Blizzard UI" (and SpellStopCasting / SpellStopTargeting messages in chat) since 0.79.1 - the reload prompt's setup touched the game's popup table in a way that tainted it.

## 0.79.1

- Choosing a new window look asks whether to reload the UI now (some of the look only takes hold after a reload) - Reload now, or Later.
- The settings window has a **Close** button at the bottom.

## 0.79.0

- Gathering professions (Mining, Herbalism, Skinning, and Fishing's own guide) on the profession window tab: a choice of zones is **one dropdown line** - the band and your pick, e.g. "1-65: Durotar" - instead of "Choose one" and a row per zone; open it to pick another. (Picking a zone costs nothing either way, so there's nothing to compare. Crafting professions and the Cooking + Fishing guide keep their option rows with costs.)

## 0.78.14

- **Fishing, Cooking + Fishing (and Fishing + Cooking) and Cooking guides**: every step has a short title ("Artisan Fishing: Nat Pagle's quest", "Dustwallow Marsh: fish to 255", "Fish in Feralas"...) - in the route list and as the step's heading - with the full instructions below it and the objectives as the details, instead of the same block of text three times.

## 0.78.13

- Profession window tab: a step's details (the to-do steps) stop above the crafting buttons' row, as Blizzard's page does - that row is kept clear, and the details scroll within the space above it.

## 0.78.12

- Step details (to-do steps on the profession window tab and in the main window) stay inside their area: the Pin buttons, the places and Mark as done no longer run off the bottom of the page - they scroll with the rest. The reagents list (with its Shopping List button and Count alts tick) is kept to its area the same way.

## 0.78.11

- **Settings** are a window of their own now - `/cr` and the minimap button open it (`/cr` again closes it), and it can stay open alongside the profession window (the game's Options window closed that). Move it by dragging, close it with its x or Escape. Options > AddOns > CraftRoute has a button that opens it.

## 0.78.10

- Blizzard-style dropdowns (with the WoW Forever / Blizzard Style / Classic WoW UI looks): the profession, goal and route-mode boxes line up with the Craft and Route buttons above them - left edge with Craft's, right edge with Route's, stacked ones too - and the profession box is wide enough for its longest label ("Leatherworking 300/300" with its icon), so it isn't cut short.

## 0.78.9

- The profession window tab's Blizzard-style dropdowns (0.78.8) are used only with a Blizzard look - **WoW Forever, Blizzard Style or Classic WoW UI**. With any other look (CraftRoute default, EllesmereUI Style, or no EllesmereUI) the tab has CraftRoute's own dropdowns and their layout again, as in 0.78.7. Changing the look switches them straight away.

## 0.78.8

- The Materials frame now features a brief maximize / minimize animation for enhanced readability.
- The Profession and Route selection dropdown boxes now match the Blizzard aesthetic.

## 0.78.7

- Marked for Classic Beta and Forever (`## X-DrangedAddons-Games: _classic_beta_, _forever_` in the .toc) - the DrangedAddons manager only offers it in those games.

## 0.78.6

- The CraftRoute key reopens on the right profession after switching with Blizzard's profession tabs too (it sometimes went back to your first profession): what CraftRoute's tab is on is kept every frame, and only a profession picked in the tab's own dropdown counts as the tab's own choice - a tab click just changes the window's profession, which the tab follows.

## 0.78.5

- The CraftRoute key:
  - **Opens and closes the whole profession window**, whatever tab it's on (on one of Blizzard's tabs it used to switch to CraftRoute's instead of closing).
  - **Reopens on the profession CraftRoute's tab was on** this session (e.g. Cooking) - it kept falling back to your first profession, because what the tab was on was only read as the window closed, when it had already let go of it. It's kept as you go now.

## 0.78.4

- Settings page: Escape closes the window again - the key-binding button only takes the keyboard while it's waiting for a key.

## 0.78.3

- **Count alts' materials**: ticking or unticking any of its boxes (the profession window tab, the Materials window, the trackers, Settings) shows on all of them at once.
- Settings page: no "CraftRoute window" button (that window is on /cr window); the recommended addons are laid out in three columns - name, installed or not, and what it adds (wrapped in its own column).

## 0.78.2

- The CraftRoute key opens the window again after you've closed it with the key (the third press did nothing): it reopened by the profession window's own ID, which the game doesn't open a profession by - now by the profession, through your profession list.

## 0.78.1

- **The CraftRoute key** is predictable:
  - Window closed: it opens on CraftRoute's tab, with whatever profession it was on when you last closed it this session - including a profession you'd picked in the tab's dropdown - or, the first time, your first profession.
  - Window open: it shows CraftRoute's tab, or closes the window if that's showing. It never switches profession (it used to jump to your first crafting profession when the window was on one CraftRoute plans without a window, like Skinning - so one press switched, the next closed).
- Opening on CraftRoute's tab, Blizzard's own profession tab no longer stays highlighted next to it (it lit up once the profession finished loading).

## 0.78.0

- Settings page:
  - **Set the CraftRoute key right there**: click the key button, press the key (with Shift / Ctrl / Alt if you like) - Escape cancels, right-click clears it. The same binding as in Options > Keybindings.
  - **Recommended addons**, each shown installed or not: **Auctionator** (prices, costs, profit, shopping lists), **Syndicator** with Baganator (alts' materials), **TrainerSpells** (live recipe data, trainers and vendors with map pins), **EllesmereUI** (the matching looks, loot feed counts, movers and minimap).

## 0.77.0

- **Settings**: `/cr` now opens CraftRoute's settings - a page in the game's Options, also under **Options > AddOns > CraftRoute**: buttons for the CraftRoute window and the Materials window, the global options (Count alts' materials, Show professions I haven't learned, Show minimap button, and the window look with EllesmereUI), the keybind and the commands.
- The full CraftRoute window (Plan, Recipes, Professions) moves to **`/cr window`** (or the button in Settings).
- **Minimap button**: left-click for Settings, right-click for the Materials window; drag it round the minimap. EllesmereUI's minimap gathers it with its other addon buttons. Hide it in Settings.

## 0.76.0

- Characters' **first and last names** are recorded (Forever's characters have both) - the All Materials icon tooltips show the full name ("Confuçius Say"); the names over the columns stay first names. With the full name, a character's class is also found in Syndicator by an exact full-name match. Each character records its last name the next time it logs in.

## 0.75.4

- All Materials window: a profession icon's tooltip - the profession, the character (in its class colour), and "Skill: 151 / 300" (its skill / the guide it's tracking to).

## 0.75.3

- All Materials window: a profession icon's tooltip is just whose profession and its skill ("Confuçius's Fishing Skill: 75"), shown above the window so it doesn't cover the header.

## 0.75.2

- Shopping cart window: hovering an item shows its tooltip (with CraftRoute's lines).

## 0.75.1

- Shopping cart window: the gold total sits under the cost column (a proper total), with the item count on the left - no "(+N unpriced)" (an unpriced item shows "?" in its own row). The **List name** is just above the buttons; **Create Shopping List** is centred, Cancel at the bottom right.

## 0.75.0

- **Item tooltips** follow the All Materials window: the professions on it (yours, and the other characters' you've added - named), each to the guide picked there, with what the item's needed for and have/need to that goal; with more than one, the total **together**, and the AH price's "buy" amount for all of them. Professions taken off the window aren't shown.

## 0.74.0

- **Shopping cart window**: every cart button (Buy Route, a recipe's Shopping List, the trackers' carts, the Craft view's) now opens a cart first - "This will be added to your shopping list" - with the list's name (the usual suggestion filled in; type to change it) and **everything that goes on it**: each item with a tick (untick to leave it off), its amount (change it) and what that costs, and the total. **Create List** (or Enter) makes the Auctionator list from what's ticked; Cancel (or Escape) makes nothing.

## 0.73.1

- All Materials window: no tooltip on a character's name handle.

## 0.73.0

- All Materials window: **drag a character's name** (over its columns) to move all its columns as one block - they shift a column at a time as you drag, and stay where you let go. Quick for reordering whole characters.

## 0.72.7

- All Materials window: the columns' faint class tint starts below the header row, so the header shows only its solid band (joined across a character's columns) - no column gaps showing through it.

## 0.72.6

- All Materials window: over the header, a character's neighbouring columns are one solid band of its class colour (no gap between them); the list below keeps its column gaps.

## 0.72.5

- All Materials window: the characters' names sit higher in the header band, and the guide targets a little lower under the icons.

## 0.72.4

- All Materials window: a character's class comes from CraftRoute's own record (saved when that character logs in), or from Syndicator only for exactly the same character - no more matching by first name. Characters recorded before 0.72.2 get their colour once they've logged in again.

## 0.72.3

- All Materials window:
  - Other characters' **class colours** now show: Syndicator can know a character by another name and realm than the game gives (e.g. "Confuçius Say" on "PvP"), so their class is found by first name too.
  - The **header row** (names, icons, targets) is darker, and each character's columns more strongly tinted there, so it reads as the heading.

## 0.72.2

- All Materials window: **other characters' class colours** show (their names over the columns, the column tints, the + menu). Their class wasn't being recorded; now it is, and for characters recorded before, it's taken from Syndicator - no need to log in on each again.

## 0.72.1

- All Materials window: the **+** menu stays where it opened while you tick - adding or removing columns moves the + button, but no longer the menu under your cursor.

## 0.72.0

- All Materials window, the **+** menu: **tick boxes**, and it stays open while you tick - your professions (ticked: on the window) and your other characters. Clicking a character (or hovering another, with one open) opens **its professions beside that row**, ticked when they're on the window; tick several in one go. A click anywhere else closes the menus.

## 0.71.0

- All Materials window, with another character's professions on it: every column says whose it is - **one name across a character's neighbouring columns** (not a cut-off name over each), in its **class colour** - your own columns too - and each column is faintly tinted in that class colour down the list.

## 0.70.8

- All Materials window, **Route order** follows the profession in the **first column**: its route's materials first, in the order its steps use them, then what only the next column uses, in its order, and so on. Drag another profession into the first column and the list re-sorts to its route. (Each Milestones band is ordered the same way.)

## 0.70.7

- Profession window tab: the route cost bar's cart button reads **Buy Route**.

## 0.70.6

- All Materials window: no shopping carts - the one at the bottom and the ones on the milestone lines are gone (the costs stay).

## 0.70.5

- Profession window tab: on the Materials button the text is centred and the pop-out icon sits at the button's right end.

## 0.70.4

- Profession window tab: the recipe's **Shopping List** sits just below the cost lines (To Craft / This step / Profit), and **Count alts** just below that - scrolling with the reagents when the list is long.

## 0.70.3

- Profession window tab: the top-right button reads **Materials**, with the pop-out icon after it.

## 0.70.2

- All Materials window: clicking a profession's icon opens its guide menu straight away (it used to wait a moment, to tell a click from a double-click). A double-click still opens that profession's own tracker - the menu just flashes open and shut first.

## 0.70.1

- Profession window tab: the version number sits in the top left corner, just above the Craft button.

## 0.70.0

- Profession window tab, the recipe on the right:
  - **Reagents:** sits where Blizzard's does under the recipe's icon (it was well below).
  - The recipe's **Shopping List** is to the right of "Reagents:", and **Count alts** just above it (in the Craft view, after the Shopping List).
  - The top-right button is **Material List**: it opens / closes the All Materials window (the full CraftRoute window is still /cr).
- The **route cost** bar's cart is bigger, with "List" on it. The pop-out button beside it is gone - Material List does that now.

## 0.69.0

- The materials pop-outs open the **All Materials** window now: the profession window's pop-out button, the main window's button (now **Materials**, in place of Tracker and All) and `/cr tracker` (or `/cr all`). One profession's own tracker is a double-click on its icon in All Materials.
- Every CraftRoute dropdown (the All Materials + and icon menus, the sort, the profession pickers...) closes when you click anywhere else.

## 0.68.1

- Profession window tab (issue #10): an enchant's **Optional Target** (the label and the item box) and the status line under it ("Select an item to enchant.") are in line with the details above them (Reagents:, the costs) instead of sitting at the column's edge, with a little more room between them.
## 0.68.0

- All Materials window: **add another character's profession**. The **+** menu lists your other characters (each character's professions are recorded when it logs in - log in on each once); pick one, then which of its professions - it gets its own column, its name over the icon in its class colour, planned from **that character's** skill (to its current rank's cap; click the icon to pick 75 / 150 / 225 / 300 like any other). Right-click takes it off again.
- With another character's guide on the window, **Count alts' materials** is switched on and stays on (their bags, bank and mail have to count) - every Alts tick says so, and won't untick until the column is taken off.

## 0.67.0

- **Loot feed** counts against **all your guides together** - the All Materials window's list - instead of only the profession picked in CraftRoute: a looted material shows have/need across every profession that window covers, each to the guide picked there (professions taken off it left out, vendor items as set there). Works with the window closed.

## 0.66.1

- All Materials window, Milestones: each milestone's line (1-75, 75-150, ... with its cost and cart) comes **after** its materials, closing them off.

## 0.66.0

- All Materials window:
  - The **cart** at the bottom right: an Auctionator shopping list of everything still to buy for the total.
  - The **Vendor items** tick and the **sort** sit above the Material column (no need to open Edit); the profession icons line up along the bottom of the header. Edit stays, for what comes next.
  - In **Milestones**, each milestone's line shows what reaching it still costs, and its own **cart** - a shopping list of just that milestone's missing materials.

## 0.65.2

- All Materials window:
  - Each profession's guide target is coloured by its rank: **Apprentice (75) white, Journeyman (150) green, Expert (225) blue, Artisan (300) purple**. A target you picked yourself (from the icon) gets a **gold border round the icon**; the icon's tooltip names the rank and says whether it's picked or following the route.
  - **Ctrl+scroll** scales it (and the wheel scrolls it) anywhere over the window - over the rows and headings too, not just its empty space.

## 0.65.1

- All Materials window: each profession's guide target sits under its icon (stacked), and the numbers are centred under them.

## 0.65.0

- All Materials window:
  - **Dragging a column** shows where it's going: the icon follows the cursor along the headings, and as it passes each column the columns - numbers and all - shift over to make room, its new slot marked down the list. Let go and it stays there.
  - **Every profession you've learned** has a column, secondary ones included - even with nothing to track (its guide done, or a guide with no materials, like Fishing or Skinning); those are dimmed, with "-" all the way down.
  - Under the **+** box, a column of "-": the empty slot a profession you add will fill.

## 0.64.0

- All Materials window:
  - Sorting has three orders: **Route order** (one list, by where the routes first use each material - as it first was), **Milestones** (the split by rank band: 1-75, 75-150, 150-225, 225-300) and **A-Z**.
  - The Vendor items tick and the sort are behind an **Edit** button on the title bar (Done hides them again), like the trackers.

## 0.63.0

- All Materials window - the profession icons along the top:
  - **Right-click** one to take that profession off the window.
  - **Drag** one to move its column; the order is kept.
  - **Double-click** one to open that profession's own tracker.
  - (A single click still picks the guide it tracks.)
  - The **+** box after the icons puts back a profession you took off.

## 0.62.0

- All Materials window, more like the trackers:
  - **Size**: the gear opens Width (the names), Scale and Height (shorter scrolls), with Reset; drag the corner grip for the height; Ctrl+scroll still scales.
  - **Alts** tick at the bottom (the same setting as everywhere).
  - **Vendor items** tick - unticked leaves out what vendors sell.
  - **Sort**: Route order or A-Z. In **route order** the list is split by rank band - **1-75, 75-150, 150-225, 225-300** - each band holding what the routes use in it, in the order they're used; what you have counts towards the earliest bands first.
  - **Pick each profession's guide**: click a profession's icon to track its route's own goal or a guide **to 75, 150, 225 or 300** - its column then shows the materials for that. The goal it tracks to is shown beside the icon (gold when picked here).

## 0.61.0

- New **All Materials** window: every material your professions' routes still need, in one list - the materials down the left, a column per profession you've learned whose route uses materials (what that route needs of it; hover a column's icon for the profession and its route), and the **total** on the right: what you have against what they need together (green once you have enough). Still-short items first. The cost of what's left to buy is at the bottom. Open it with the main window's **All** button (beside Tracker) or `/cr all`; move it by any free space, scroll the list, Ctrl+scroll to scale. It remembers its place and comes back after a reload if it was open. Items hidden in a profession's own tracker are left out of that profession's column. The per-profession trackers are unchanged.

## 0.60.0

- Profession pickers (the profession window tab and the main window) look like TrainerSpells': **Your Professions** - each with its icon, a radio button and your skill (e.g. 219/225) - then **Other Professions**, greyed out, A to Z (when "Show professions I haven't learned" is on). The box shows the picked profession's icon, name and skill. Picking one still opens its profession window.

## 0.59.0

- **Skinning route** reworked from the Classic guide, by zone: 1-75 Durotar / Dun Morogh, 75-115 The Barrens / Loch Modan, 115-155 The Barrens / Wetlands, 155-205 Thousand Needles / Arathi Highlands, 205-300 Feralas (Un'Goro Crater at the end). Training is part of the route now - Journeyman at 50, Expert at 125, Artisan at 205, each naming the guide's trainer for your faction (Thuwd, Dranh, Kulleg Stonehorn / Balthus Stoneflayer) - along with buying the Skinning Knife.
- Route steps that aren't crafts (gathering, training, buying): each has a short **title** and its details below it - no longer the same block of text twice.
- A gathering step's **progress bar** fills over the guide's whole step (e.g. 60 of 1-75) - it used to start at your current skill, so it never filled.

## 0.58.4

- Profession window tab: no more **dark box** sticking out past the window's right edge, behind the side tabs. Opening the window straight onto CraftRoute's tab (the CraftRoute key) copied Blizzard's page background in the very moment the window appeared, before Blizzard had sized its page - its recipe panel's border was read too big (and before a skin had faded it), and stayed that way. Each copied texture now follows the Blizzard texture it copies as the page settles, it's copied again shortly after opening (picking up a skin's fade), and nothing reaching outside the tab is copied. The crafting buttons' places are re-read at the same moments.

## 0.58.3

- The profession bar at the top of the profession window stays on Blizzard's own bar. It no longer picks up the bar texture from EllesmereUI's Resource & Cast Bars. The colour bar under a recipe still does.

## 0.58.2

- Profession window coming up **empty** (titled "Professions", no profession loaded - it could happen right after a reload): clicking the CraftRoute tab, or pressing CraftRoute's key, now loads your first primary profession that has a crafting window (else your second, else Cooking, else First Aid) and stays on CraftRoute's tab. The "Open <profession>" button and "Open the profession to craft." no longer show in that state.

## 0.58.1

- Materials trackers: snapping one above or below another (or anywhere near the middle of the screen) attaches it properly - it no longer jumps back to where you let go, off to the side and at its old width. A tracker's place is now always kept as its top-left corner (WoW had left it on the screen's CENTER point, a spot EllesmereUI re-applies whenever the window changes size - as it does when it takes on the width of the one it's snapped to), and EllesmereUI hands those resizes back to CraftRoute to place.

## 0.58.0

- Materials trackers keep their places through reloads, logins and zone changes - free ones where you left them, snapped groups still snapped and in place. The cause: EllesmereUI re-applies every registered frame's stored position at login, on zone changes and when action bars lay out, which pulled snapped trackers off their group onto old spots. CraftRoute now places its trackers itself (EllesmereUI leaves them be), keeps every tracker's saved spot up to date (after each drag and at logout), and WoW's own layout cache no longer stores them.
- A tracker snapped above or below another is always that one's **width**.
- Trackers can be dragged by any free space on the window, not just the title bar.

## 0.57.0

- Materials trackers snap to **any side** of another tracker: left or right (tops level), above or below (left edges level). Dragging a snapped group, whichever of its trackers ends up at an edge snaps there - the rest stay snapped around it. The profession window's right edge still docks.

## 0.56.2

- Materials trackers: snapped trackers stay snapped after a reload. They come back one by one, and one coming back before the tracker it's snapped to was left at an old position - now they're all put back on each other once they're all up.

## 0.56.1

- Materials trackers: the unsnap lock is visible now (its icon wasn't in this client's art, so it drew nothing). It uses a lock icon the client has, or draws a small one.

## 0.56.0

- Materials trackers: a snapped tracker shows a small **lock** in its bottom-left corner (left of the cost). Click it to unsnap that tracker from the ones it's connected to - it stays where it is as its own window; any snapped onto it come free where they are too (still carrying the ones snapped to them). A tracker docked to the profession window stays docked.

## 0.55.1

- Shopping lists always list a recipe's **own** materials: a step's Shopping List for Hillman's Leather Gloves asks for the Medium Leather it's missing - not the Light Leather and scraps that leather could be made from. What earlier route steps make for it (a component crafted in a previous step) is still counted as covered and not bought.

## 0.55.0

- Profession window tab: the crafting buttons - **Create All**, the amount box with its **arrows**, and **Create** - sit exactly where Blizzard's own do on its recipes page, at the same sizes. Their places are read from Blizzard's page as the tab opens (and remembered, for when it opens over another page). The Shopping List button and the status line ("Not enough reagents...") sit just above them.

## 0.54.2

- Profession window tab: with a skin that shades Blizzard's panels (EllesmereUI's dark fills behind the recipe list and the recipe panel), that shading is now copied onto the tab too - so the "crease" between the columns (the gap between the two shaded panels) shows as it does on Blizzard's page. The skill bar's own fill is no longer copied (the tab borrows Blizzard's bar).

## 0.54.1

- Profession window tab: Blizzard's panel borders are now copied onto the tab with its background - including the subtle "crease" between the two columns (the recipe list's and recipe panel's border edges, thin strips the copy used to skip as too small).

## 0.54.0

- Materials trackers (and the Craft view's materials panel) always draw **above** the profession window, side tabs included - docked or free.
- Closing a tracker with its **x** resets it: next time the pop-out opens it, it's docked to the profession window again.
- **Snapping**: drop a tracker by the profession window's right edge and it docks there again; drop it by another tracker's right edge and it snaps to that one, tops level. Snapped trackers are a group - dragging any of them moves them all, and Ctrl+scrolling one scales them all. A group docked to the window closes with it (and keeps its snapping for next time). Closing one with its x leaves any snapped to it where they are, as free windows.
- Profession window tab: the line between the two columns is gone when Blizzard's page background is copied onto the tab - Blizzard's page has no such line (its recipe list border and recipe panel art part the columns), so the art does it here too.

## 0.53.3

- Route view: the right panel's messages ("Goal reached (225). Raise it in the route dropdown.", "Click a step...") no longer sit on top of the version and Open CraftRoute button - they start below that row, where a recipe's own details start.

## 0.53.2

- Materials tracker from the Route view's pop-out: opens **docked** to the right edge of the profession window (over its side tabs), and closes with the window - like the Craft view's materials panel. Drag it by its title (or move it in EllesmereUI's unlock mode) to undock it: from then on it's a free window for that profession - it keeps its place, stays open when the window closes, and comes back after a reload, and the pop-out opens it there. The main window's Tracker button and `/cr tracker` still open the free window.

## 0.53.1

- The route goal picker (Route view, Plan tab) only offers the ranks - Apprentice (75), Journeyman (150), Expert (225), Artisan (300) - and Custom. "Next target recipe", "My rank", "My level's highest rank" and "End of guide" are gone; if one of those was chosen, the route now plans to your current rank and the picker shows that rank.

## 0.53.0

- Profession window tab: the skill bar **is Blizzard's own** now. Blizzard's bar lives on its crafting page, which the CraftRoute tab hides - so while the tab is open the bar is moved onto it (same spot on screen) and given back when the tab closes. Its art (full width, revealed up to your skill), intro animation, unfilled colour, tip highlight and any EllesmereUI skin are simply Blizzard's - no squeezed animation, no flash of another texture when it ends. CraftRoute's own bar only shows when Blizzard's is showing a different profession than the tab.

## 0.52.1

- Skill bar art: when it settles it now shows the intro's **last frame** (where Blizzard's bar stops), not the whole animation sheet squeezed into the bar.
- Skill bar art for every profession: CraftRoute notes Blizzard's art whenever its bar changes it (even with the CraftRoute tab in front), and works out a profession it hasn't seen yet from one it has - the same art with that profession's name in it, if the game has it. Before, only professions whose Blizzard page you'd looked at got their art.
- The skill bar sits exactly where Blizzard's does: its frame, background, fill, text and arrow are placed on Blizzard's bar's own position and size, read when the tab opens, so nothing moves when you flick between the two.

## 0.52.0

- Profession window tab: the skill bar wears **Blizzard's own skill-bar art for each profession**. Whenever Blizzard's bar shows a profession, CraftRoute notes the texture on its fill - and, if it has one, the animated intro that plays before it settles - and keeps them per profession. CraftRoute's bar then shows that art, filled to your skill, and plays the same intro each time the tab opens or you switch profession. A profession whose Blizzard bar hasn't been seen yet keeps the previous look (EllesmereUI bar texture or the profession colour) until it has. `/cr rankbar` lists what's been captured.

## 0.51.0

- Profession window tab: it now has **Blizzard's own page background** - the large background and border art of Blizzard's crafting page (header, recipe list and recipe panels) is copied onto the tab in the same place, with the same art, crop, colour and transparency (so an EllesmereUI skin of that page carries over). It's picked up each time the tab opens and when you switch profession. CraftRoute's own plain header band only shows if nothing could be copied. `/cr bg` lists what was copied.

## 0.50.17

- Profession window tab: the header now lines up with Blizzard's own page - the line under it is 9 px higher and the skill bar about 4 px higher, measured against Blizzard's - so nothing jumps when you flick between the two. Everything below the header moved up with it.

## 0.50.16

- Route view: the selected step's blue box now takes in its opened rows (its reagents) as well as its title row - the step and its details read as one, as in the Craft view.

## 0.50.15

- Route view: a step to do keeps its orange title when it's the selected step too (it turned white, and the current step is usually selected).

## 0.50.14

- Route view: steps to do (not crafts) no longer start with "To do:" - their title is orange instead, which says the same and leaves more room for it. "Done:" and "At N:" steps are unchanged.

## 0.50.13

- Route view: the to-do steps ("To do:", "Done:", "At N:") get the same layout - the title has the whole line, and the skill it's at goes just under it. A title that still doesn't fit gets a point smaller rather than truncated.

## 0.50.12

- Route view: each step's craft count and skill range ("12x  30-55") moved from beside the recipe name to just under it, so the name has the whole line and isn't cut off. A name that still doesn't fit gets a point smaller rather than truncated.

## 0.50.11

- Yes Chris, this was necessary.

## 0.50.10

- Skill-up colours: the number beside "you:" uses the colour of the band your skill is in for that recipe (orange, yellow, green, grey, or red when you cannot learn it yet).
- The recipe colour bar, and the profession bar at the top of the profession window, use the bar texture from EllesmereUI's Resource & Cast Bars when one is set. The profession's colour stays. With none set, the recipe colour bar stays flat and the profession bar stays as it was. Yes Chris, this was necessary.

## 0.50.9

- The route planner and both profession windows do less repeated work while they are open. Item names, prices, trainer lists, and whether a recipe is ready are remembered between refreshes instead of looked up again every time. The screens are the same.

## 0.50.8

- Skill-up colours tooltip (the colour band under a recipe) condensed, as suggested in GitHub issue #9: the four thresholds in their colours - "30 - 50 - 60 - 70" - with "you: 85" on the right, instead of "30 learn · 50 yellow · 60 green · 70 grey · you: 85".

## 0.50.7

- Materials panel: a **Show vendor items** tickbox under its title - untick it to hide what vendors sell (thread, dyes, flux) from both views. Remembered.

## 0.50.6

- Craft view, "Your crafts": each recipe's "costs" and "profit" lines are for the amount set beside it (they were for one), and change as you type the amount.

## 0.50.5

- Craft view: on the shopping line the materials pop-out is now at the far right, the cart to its left.
- Craft view: the left column keeps its bottom bar (empty there) so both columns line up, as in the Route view.

## 0.50.4

- Materials panel: always starts closed - it shuts when the profession window closes and doesn't reopen by itself.
- Craft view: one amount per recipe - the amount you set beside a recipe in your list is also its opened details' amount ("Cost to make N", "Profit for N") and its Create box's; the details update as you type it, and changing the Create box updates your list's amount too.

## 0.50.3

- Materials panel: opens right against the profession window's edge, over its side tabs (close it to get back to them).

## 0.50.2

- Materials panel: a small **<** button at its top left tucks it back in. The pop-out button beside the cart still opens / closes it as before.

## 0.50.1

- Shopping lists: making one now asks you to **name it**, with a suggested name filled in and selected - what it's for, the amount, and the time ("CraftRoute: Heavy Leather x5 (14:32)", "CraftRoute: Leatherworking crafts, 3 recipes (14:35)", "CraftRoute: Leatherworking route 141-150 (14:40)"). Enter (or Create) makes it; type over it for your own name; Escape (or Cancel) makes nothing.
- The list CraftRoute made before for the same thing (that recipe, that profession's crafts, its route, its tracker) is removed when you make a new one, so they don't pile up - unless you gave it your own name, then it stays.

## 0.50.0

- Craft view, "Your crafts" amounts - rebuilt: each row shows its amount as a small button; clicking it opens one editor over it, empty (the old amount shows faintly), so the first key you press is the first digit. Enter or clicking away keeps it, Escape goes back. The editor isn't part of the list's rows any more - before, every list refresh hid and re-showed the box you were typing in, which lost your typing (only the top row's amount stuck).
- Cost and the shopping list for your crafts use the recipes' own materials - Light Leather is priced and listed as Light Leather, not broken down into the scraps it's made from.
- **Materials panel**: a pop-out button beside the cart opens a panel along the profession window's right side with everything the ticked recipes need at their amounts - **Total** (all together) or **By recipe** (each recipe's materials times its amount) - have / need, updated as you change ticks and amounts. Mouse wheel scrolls it.
- The Craft view's left column no longer has the "Make each once" gold bar (its list reaches the bottom); the shopping line on the right has the same height and gaps from the border as the Route view's cost bar.

## 0.49.9

- Craft view: the amounts you type beside your crafts are really kept now. 0.49.7 only saved them when the game flagged the change as typed by you - which this client doesn't do - so nothing was ever saved. They're now saved on every change while you're in the box, and again on Enter or clicking away.

## 0.49.8

- Craft view, "Your crafts": the rows are a little taller, with the profit on its own line under "costs ..." instead of squeezed beside it.
- The amount boxes: clicking in one now really selects what's there, so you can just type (the click used to undo the selection).

## 0.49.7

- Craft view, the amount boxes beside your crafts:
  - Clicking in one selects what's there, so what you type replaces it (it used to add to the "1" already there).
  - The amount is kept as you type (no need to press Enter), stays 1 until you set one, and is remembered after that. Left empty, the box goes back to its amount.
  - Each box always saves to its own recipe - a refresh while you were typing could move the amount to another one.
  - No tooltip on them any more.
- The Cost / Profit line under your crafts updates as you type an amount and as you tick / untick recipes.

## 0.49.6

- Craft view, "Your crafts": under each name it now says "costs ..." (was "makes for ...") followed by its profit per craft ("profit +.." green, or red for a loss).

## 0.49.5

- Craft view: the shopping line reads "N selected  Cost ..  Profit ..  [cart]" - cost on the left, profit beside the cart.

## 0.49.4

- Craft view: shopping amounts start at 1 for a recipe you haven't set, and remember the last amount you entered (0.49.3 reset them every time the window opened - undone).

## 0.49.3

- Craft view: the shopping amounts beside your crafts start at 1 each time you open the profession window (the ticks are kept).

## 0.49.2

- Craft view: the shopping line under "Your crafts" shows **Cost** (what buying what the ticked recipes still need costs, at their amounts, less what you have - vendor or AH prices, "+N unpriced" for any without one) and **Profit** (their profit per craft, as the recipe details show it, times the amounts) beside the cart: "N selected  Profit +..  Cost ..  [cart]".

## 0.49.1

- Craft view: a recipe ticked for the shopping list is highlighted with the blue selection box (it doesn't open).

## 0.49.0

- Craft view: **a shopping list from your crafts**. Each recipe in "Your crafts" has a tickbox on its left and a quantity box beside its star; a tickbox by the "Your crafts" header selects all / none. Along the bottom, "Generate shopping list for the N selected" with the cart makes one Auctionator list of everything the ticked recipes need at the amounts you set - less what you have, counted once across them all (two recipes sharing a reagent don't both use the same stock). Parts you can make yourself are bought as what they're made from; vendor items are left off. Selections and amounts are kept per profession, per character.
- The single-recipe shopping lists use the same counting.

## 0.48.0

- Materials trackers are **per profession**: each profession gets its own pop-out window, with its own position, width, height, scale, collapsed state, sort and hidden items - and several can be open at once. The Tracker button and `/cr tracker` open the one for the profession CraftRoute is on; the pop-out on the profession window's tab opens that tab's. Each has its own mover in EllesmereUI's unlock mode ("CraftRoute Tracker: <profession>"). New ones open a little offset so they don't sit on top of each other. Your existing tracker's settings carry over to the profession it was showing.

## 0.47.0

- Loot progress is now part of **EllesmereUI's loot feed** (Forever Essentials) instead of a feed of its own: the row EllesmereUI shows for an item your route needs gets "have/need" on its own second line, in whatever font, size and colour that feed's style uses - Bar, Box, Toast, and Icon Tray (on its name callout). Rows that already use that line (item level, "Quest Item") are left alone. It reads EllesmereUI's own loot-feed hooks (`EllesmereUI._LootFeed`), so it moves, sizes and themes with that feed; nothing of EllesmereUI's is changed and no row is added. Counts are the profession picked in CraftRoute: what you have (bags, bank, mail, alts if ticked) plus what the route makes on the way, as the item tooltip counts it. Needs EllesmereUI's loot feed turned on (with items shown).
- Removed CraftRoute's standalone loot feed, its "Loot feed" settings button and the `/cr feed` commands.

## 0.46.10

- Materials tracker: the Sort dropdown (Route order / A-Z) moved out of the gear panel to its own place in Edit, beside the Vendor button.

## 0.46.9

- Materials tracker: a **Sort** dropdown in its gear panel - Route order (by the step that first uses each material; the default) or Alphabetical. Either way still-needed materials stay on top. Kept per character.

## 0.46.8

- Materials tracker: materials are listed in **route order** - by the step that first uses them (as a reagent, or something a step has you buy, like the hammer) - so the list follows your progress. Still-needed ones stay on top, ones you have enough of below.

## 0.46.7

- Materials tracker: an **Alts** tickbox on its bottom line, beside the cart - the same "Count alts' materials" setting as on the Plan tab and the profession window tab (ticking it here changes it everywhere). It shows without Auctionator too.

## 0.46.6

- Materials tracker: the bottom is one compact line - **Cost** of what you still need to buy of the materials it shows (vendor or AH prices; "+N unpriced" for any without a price; hidden items and the route's own crafts left out), and the small shopping-cart button beside it.

## 0.46.5

- Materials tracker: a **Vendor** button in Edit (beside All and None) unticks every item vendors sell - thread, dyes, flux - so the list keeps to what you gather or buy on the AH. Click it again to tick them back.

## 0.46.4

- Materials tracker: it's never taller than its list (a taller height stops after the last line) or wider than it needs to show every name and count in full - by default it's exactly that size. Set smaller, it still scrolls / narrows.
- Materials tracker: a **Shopping list** button along the bottom (with Auctionator) - an Auctionator list of what you still need of the materials it shows; hidden ones, and things the route makes itself, are left out.

## 0.46.3

- Materials tracker: **Ctrl + mouse wheel** over it scales it up / down. The Scale slider works properly now - its panel scaled along with the tracker, so the slider moved under the mouse while you dragged it.
- Tracker and loot feed: changing the scale no longer shifts them across the screen - the tracker keeps its top-left corner, the loot feed its bottom-left.

## 0.46.2

- Materials tracker: you can make it **shorter** - drag its corner grip up / down as well as sideways, or use the new Height slider under the gear. Shorter than the list, it scrolls (mouse wheel, with a thin scrollbar on the right). The gear's Reset fits it to the list again. EllesmereUI's unlock mode can set its height too.

## 0.46.1

- Materials tracker: **All** and **None** buttons in Edit - show every material, or hide them all and tick the ones you want.

## 0.46.0

- Materials tracker: **resizable and scalable** - drag the grip in its bottom-right corner to make it wider or narrower (its height follows the list), or open the gear on its title bar for Width and Scale sliders and a Reset. EllesmereUI's unlock mode can resize its width too. Kept per character.
- Profession window tab: a **pop-out** button (a page with an arrow) on the Route cost bar, beside the gold and the shopping-list cart, opens the tracker for that profession - click again to close it.

## 0.45.0

- **Materials tracker**: a small window you can pin anywhere on screen, open whether or not CraftRoute or its tab is - the materials left on your route (the profession picked in CraftRoute), each with what you have of what the route needs, still-needed ones first (yellow), done ones green and greyed below. Things the route makes on the way say "+N make".
  - **Edit** ticks / unticks which items it shows (click anywhere on a line); hidden ones are hidden only here, per profession. **-** collapses it to its title, **x** closes it.
  - Drag it by its title, or move it in EllesmereUI's unlock mode ("CraftRoute Materials Tracker"). It updates as you loot, bank and craft, and comes back after a reload if it was open.
  - Open it with the **Tracker** button at the top of the main window, or `/cr tracker`. Kept per character.

## 0.44.0

- Loot feed matches **EllesmereUI's loot feed look** (Forever Essentials): its style - Bar (accent bar on a fading background), Box (solid with a border) or Toast (the gold-framed plate); Icon Tray has no room for text, so rows draw as Box then - plus its background colour and opacity, border size and colour, quality-coloured bars / borders, font and text size (the count a little larger), and how long rows stay up. Your width, height and scale still apply. "Match EllesmereUI's loot feed look" in the Loot feed panel turns it off for CraftRoute's own look; on by default when EllesmereUI is loaded.

## 0.43.0

- Loot feed settings: a **Loot feed** button at the top right of the main CraftRoute window opens a small panel - show it or not, put the count in EllesmereUI's loot feed instead, and sliders for the rows' **width**, **height** and the feed's **scale** (mouse wheel works on them too), plus Test, Move and Reset (size and place back to default). Kept per character. In EllesmereUI's unlock mode "CraftRoute Loot Progress" can now be resized as well as moved.

## 0.42.3

- Loot feed: bigger rows on one line - icon, the item, and on the right in a larger font just what you have now of what the route needs ("61/100", green once you have enough). The count before the loot isn't shown any more (on EllesmereUI's rows too, with /cr feed ellesmere).

## 0.42.2

- Loot feed: CraftRoute's own loot-progress rows are back on for every loot the route needs (move them in EllesmereUI's unlock mode - "CraftRoute Loot Progress" - or with `/cr feed move`). Writing the count into EllesmereUI's own loot-feed rows is now optional: `/cr feed ellesmere` switches to that (and back).

## 0.42.1

- CraftRoute's own loot-progress row (the fallback when EllesmereUI's feed isn't showing the item) can now be moved in **EllesmereUI's unlock mode** - it's listed as "CraftRoute Loot Progress", like EllesmereUI's own frames. `/cr feed move` still works without EllesmereUI.

## 0.42.0

- Loot progress now goes into **EllesmereUI's loot feed**: with its feed on, the second line of its own row for the item reads "Route  60/100 > 61/100" (green "done" once you have enough) - no separate feed to place; it moves with EllesmereUI's own feed settings. CraftRoute's own row is only the fallback - when EllesmereUI's feed is off, doesn't show that item (e.g. its quality filter), or uses its Icon Tray style (tiles with no second line). `/cr feed move` places that fallback row.

## 0.41.4

- Loot feed: Shift+drag any row to move the feed (the position is kept per character). `/cr feed move` still shows a bar to drag it by when no row is up.

## 0.41.3

- Loot feed: fixed the rows never appearing ("LootFeed.lua:226: attempt to call a nil value") - 0.41.1's wait-for-the-bags check used a game function Forever doesn't have.

## 0.41.2

- Loot feed: `/cr feed why` says in chat, for every loot line, whether it got a row and why not - e.g. "Silk Cloth x1 - no row: the Leatherworking route doesn't need it (its plan runs to skill 150)", or a line it didn't recognise. `/cr feed why` again stops it.

## 0.41.1

- Loot feed: the count could be one behind (3 Light Leather showing as 2) - it read CraftRoute's item count before that had caught up with the loot. It now waits until the item is in your bags and counts it fresh.

## 0.41.0

- Loot progress feed: when you loot (or craft) something your route needs, a short row slides in for a few seconds - icon, name and **60/100 > 61/100** (green "done" once you have enough). Items the route doesn't need don't show, so it sits beside EllesmereUI's loot feed (or chat) instead of repeating it. Looting more of the same while its row is up updates that row. Hover a row to keep it and see the item. Counts are the route's own: what it needs in total, and what you have the way its materials list counts it (bags, bank, mail, alts if "Count alts" is on).
  - `/cr feed` turns it on / off, `/cr feed move` lets you drag it (again to save), `/cr feed test` shows a sample, `/cr feed reset` puts it back beside EllesmereUI's feed. Kept per character; on by default.

## 0.40.0

- New routes for the gathering professions: **Mining**, **Herbalism** and **Skinning** (1-300). They follow wow-professions.com's Classic guides as stand-ins until Forever guides exist - gathering barely differs.
  - Each band lists the zones to farm for your faction; where there's more than one, pick the one you like (Choose one). Every zone step has a "reach skill N" objective and progress bar; the training ranks (Journeyman, Expert, Artisan) come up as steps with trainer pins, like the other professions.
  - Mining: buy a Mining Pick first (it only has to be in your bags); notes on smelting Silver from 75 and Gold from 155, and Rich Thorium from 275. Skinning: buy a Skinning Knife first; one path per faction. Herbalism: which herbs each band has and the skill some of them need.
  - Herbalism and Skinning have no crafting window, so (like Fishing) their route is in the main window; Mining's also shows in the Smelting window's CraftRoute tab.
  - "Check for guide updates" now watches these three guides too.

## 0.39.2

- The Professions tab (crafting window) now always selects on the first click. It could take two: right after the keybind opened the window, CraftRoute was still bringing its own view back for a couple of seconds and undid the click; and when Blizzard thought its Professions page was already selected (CraftRoute's view had only covered it) it ignored the click. A click on any of Blizzard's tabs now ends that "bring CraftRoute back" spell, and a Professions tab click shows Blizzard's Professions page outright.

## 0.39.1

- The profession pickers (0.39.0) now go where you asked: the **Professions page of the crafting window** (its Professions tab - "First Profession", "Second Profession", Cooking / Fishing / First Aid), not only the separate Professions book. The sections are found by their headers, and only taken over while Blizzard's "Visit a trainer..." text shows in them.
- Clicking Blizzard's Professions tab from CraftRoute's tab now shows Blizzard's Professions page - it used to put the (empty) recipes page up instead.

## 0.39.0

- The game's Professions book (K): each section you haven't learned yet shows CraftRoute's picker instead of Blizzard's "Visit a trainer..." text.
  - **First / Second Profession:** a big icon - click it for a grid of every primary profession (crafting and gathering), click the one you want. Its name and what it does show beside the icon, and on the right the three nearest trainers for your faction with **Pin** buttons for a map waypoint. Your pick is remembered per character. A profession you've learned, or picked for the other section, is greyed out.
  - **Cooking / Fishing / First Aid:** the nearest trainers for that one, with Pin buttons.
  - Once a section is learned it's Blizzard's own again.

## 0.38.2

- Fixed the Professions tab doing nothing when clicked (and the keybind landing on Plan instead): the tab failed to build in game, so the window fell back to Plan.

## 0.38.1

- The profession picker is now a **Professions** tab in the main CraftRoute window (next to Plan and Recipes): every primary and secondary profession, what each does, and Pin buttons for the nearest trainers. It's always there, for picking up a second profession too.
- Keybind (Shift+K) with no crafting profession to open (nothing learned, or only gathering): opens the main window on the Professions tab; press it again to close. With a crafting profession it opens the crafting tab as always.
- Removed 0.38.0's CraftRoute page in the game's Professions window - the keybind no longer goes there.

## 0.38.0

- No profession learned yet: the keybind (Shift+K) now opens the game's Professions window (the one K opens - empty until you learn something) on a CraftRoute tab, with the profession picker in it - every primary and secondary profession, what each does, and Pin buttons for the nearest trainers. Opening that window yourself shows it too, with CraftRoute's tab on its right edge (click to hide / show it). Pressing the keybind again closes it. Once you've learned a profession the Professions window is Blizzard's own again and the keybind opens the crafting tab as before.

## 0.37.3

- Keybind: reads your professions fresh on every press. It only opens CraftRoute's main window (the start page) when the character has no profession at all; a character with only professions that have no crafting window (e.g. Herbalism, Skinning) gets a chat line saying so instead. The start page also counts gathering professions as "learned", so it no longer shows for a gatherer.

## 0.37.2

- Craft view: the X beside Filter also puts the sort back to Level (it's clickable whenever a filter or a profit sort is on).

## 0.37.1

- Craft view: while the recipe list is sorted by profit, each recipe shows its profit per craft beside its level (and "Not Learned") - green, red for a loss, or "no price".

## 0.37.0

- New start page for characters with no profession yet: CraftRoute (/cr or the keybind) opens on a "Pick a profession" page listing every profession - crafting, gathering and the three secondary ones - with a line on what each does and what it pairs with. Pick one to see the three nearest trainers for your faction who teach it, with their zone and distance and a **Pin** button for a map waypoint (named in WaypointUI). Professions CraftRoute has a route for get a "Show me the leveling route" button that opens their plan. Trainer locations come from TrainerSpells; without it the page says to ask a city guard. Once you've learned a profession CraftRoute opens as before.
- The keybind (Shift+K) now opens CraftRoute's main window when the character has no crafting profession, instead of only printing a message.

## 0.36.0

- Craft view: an opened recipe shows its **profit** under "Cost to make" - what the crafts sell for on the AH (less the 5% AH cut) minus their materials, in green (or red for a loss). It scales with the amount box like the cost. Items never seen on the AH use what a vendor pays ("(vendor)"); "(cost incomplete)" means some materials have no price yet. Enchants have no item, so no profit line. Needs Auctionator.
- Craft view filter: a new **Sort >** side list - Level (default), Profit: high to low, Profit: low to high. Recipes with no price go to the end. It's kept per profession and per character, isn't counted as a filter, and the X leaves it alone. The Sort row says which order is on.
- Craft view (GitHub issue #7): the enchant "Optional Target" box could appear over the wrong rows (overlapping the reagents or the next recipes) after opening and closing recipes. It now always sits in the opened enchant's own row, and is hidden anywhere else.
- Craft view: a running batch's "3/10" count sits after the last button instead of on top of the shopping cart.

## 0.35.2

- Blacksmithing route updated to the latest wow-professions.com guide: 185-215 is now 36x Mithril Plate Pants (432 Mithril Bar - no more Heavy Mithril Gauntlet / Shoulder choice, so no Mageweave or Heavy Leather), then 215-225 is 21x Steel Plate Helm (was 37 from 200), or 10x Mithril Spurs if you have the world-drop plans. The 40 Solid Grinding Stones at 175 are now "21 for the helms at 215", and the Golden Scale Bracers option is for stopping at 215.

## 0.35.1

- Craft view (both columns): opening a recipe no longer scrolls it to the top - its row stays exactly where it was and the details expand down below it; scroll down to see the rest. Closing one (or opening another while one above is open) keeps the clicked row in place too.

## 0.35.0

- Route view: a little cart button at the right end of the Route cost bar makes the route's Auctionator shopping list - the same list as the main window's "Auctionator shopping list" button, without opening the main window.
- Route view: each "Choose one" option shows what its materials cost to buy, on the right of its row (as the main window does). Its tooltip repeats the cost and says how many of its materials have no price yet ("+N unpriced").
- Craft view: an opened recipe has an **Add to route** button (on its Learned / Not Learned line) - it becomes a target on the Route, like ticking it in the main window's Recipes tab. Click again (**Remove from route**) to take it off. Guides followed strictly in order (Fishing + Cooking) don't take targets, so the button is greyed there.
- Craft view: a small **X** beside Filter clears every filter for this profession in one click (greyed when none are on).

## 0.34.13

- Craft view filter: each profession has its own filter now (it used to apply one filter to every profession), and each profession's ticks are remembered per character across reloads and logins.

## 0.34.12

- Craft view recipe list: the **Not Learned** marker is dimmed to match the dimmed name.

## 0.34.11

- Craft view recipe list: recipes you haven't learned are dimmed again (their rarity colour, darker), as well as saying **Not Learned** beside the level.

## 0.34.10

- Craft view: the marker beside the level reads **Not Learned** (not "Unlearned"), and the filter, tooltips and recipe details use the same "Not Learned" wording.

## 0.34.9

- Craft view recipe list: only unlearned recipes are marked (**Unlearned** in red beside the level); learned ones just show their level.

## 0.34.8

- Craft view recipe list: under each name, beside its level, it now says **Learned** (green) or **Unlearned** (red). Names are always their full rarity colour - unlearned ones are no longer shown in a dimmer shade.

## 0.34.7

- Craft view stars: hovering one makes it glow (an empty star also brightens), and clicking it presses in like a normal button. No tooltip on the star any more.

## 0.34.6

- Craft view filter: clicking anywhere on an option's line (its name too, not just the tick box) toggles it - in the main list and the Quality / Slot side lists.

## 0.34.5

- Craft view filter: a click anywhere else really does close it now. The check used a game function Forever doesn't have, so it failed silently on every click; it now asks the frames themselves whether the mouse is over them.

## 0.34.4

- Craft view filter: closing it with a click elsewhere now actually works - it listens for the game's "mouse pressed" event instead of watching the mouse buttons, which didn't catch the click.

## 0.34.3

- Craft view filter: clicking anywhere outside the filter list (and its Quality / Slot side list) closes it - no need to click the Filter button again.

## 0.34.2

- The shopping cart picture is on every shopping list button now: the Route view's "Shopping List" and the main window's "Auctionator shopping list" too, not just the Craft view.

## 0.34.1

- Craft / Route: the view you pick now sticks when you change profession (and is remembered per character), instead of each profession having its own. Until you pick one, it still opens on Route below max skill and Craft at max.

## 0.34.0

- Craft view filter: two new sub-lists under the tickboxes - **Quality >** (Common, Uncommon, Rare, ... in their colours) and **Slot >** (Head, Shoulder, Chest, Wrist, One-Hand, Bag, ... in character-sheet order; enchants count as the slot they enchant; anything not worn is Other). Hover or click one to open its list. Each only offers what this profession actually makes. Ticking several in one list shows any of them; the lists and tickboxes narrow each other. The Filter button counts everything ticked, and each sub-list shows how many of its own are on.

## 0.33.6

- Craft view: the Shopping list button always has the cart picture - with "Shopping list" beside it when there's room, just the cart when there isn't.

## 0.33.5

- Craft view: safer sizing for the Shopping list button (guards the width check so a missing size can never break the crafting row).

## 0.33.4

- Craft view: the Shopping list button only turns into the cart icon when the row is short of room (e.g. the narrower left column); otherwise it says "Shopping list". For enchants it sits right after Create.

## 0.33.3

- Enchant target slot: no tooltip on hover any more - it covered the list of items to pick from. Hovering just opens the list.

## 0.33.2

- Craft view: the "Shopping list" button is now a small cart icon, so the crafting row fits inside the recipe's box. Hover it to see what it does.

## 0.33.1

- Hovering the Enchant / Create button or the enchant target slot (and Split / Combine, Open, and the profession picks) lights the button up again and shows it pressed while you click. Those buttons have a click-through cover on top of them (so the click can enchant or answer the replace prompt), and the cover was only passing on the tooltip, not the glow.

## 0.33.0

- Craft view: clicking a recipe in the left list opens it right there - the same details and controls as your list (where to get it, reagents with Buy, the enchant target, Create / Create All, Shopping list) - so you can craft a one-off straight from the filtered list. It no longer adds it to your list: the star does that. One recipe is open at a time, in either column.
- Craft view: the filter is tickboxes - Has materials, Has skill-ups, Learned, Not learned. Nothing ticked shows every recipe; each one ticked narrows the list (Learned and Not learned together show both). The button shows how many are on.

## 0.32.1

- Enchanting through the trade window: one click enchants the other player's item - the enchant is cast and their "Will not be traded" slot is clicked for you in the same click. It used to leave you holding the targeting hand to click the slot yourself.

## 0.32.0

- Enchanting through the trade window: while a trade is open, the enchant target box (everywhere it appears) offers only the item in the trade window's "Will not be traded" slot - the other player's item you're enchanting for them - and picks it for you; your own bags and worn gear aren't offered. Clicking enchants it there (the enchant is cast, then their trade slot is targeted, as clicking it by hand does). When the trade closes, the box goes back to your own gear.

## 0.31.8

- Profession-window view: the mouse wheel scrolls the column the cursor is over, anywhere in it - the right-hand list (Craft view) included. Its rows used to scroll the left list, so only the thin scroll bar worked.

## 0.31.7

- Craft view: an opened enchant (one that goes on gear) has the enchant target slot in its panel - the same one as the Route view: pick gear you're wearing or carrying (or drop an item on it), click it to enchant, right-click to clear, and "replace the existing enchant?" is answered for you. Create still casts it (with Blizzard's "click an item" if you'd rather); Create All is hidden for enchants, which go one at a time. The slot goes back to the Route view's panel when you switch.

## 0.31.6

- Craft view: an opened recipe's details are enclosed - one panel joined to its row, with a faint fill, the selection colour down the left and a line under the crafting row - so it's clear where they end and the next recipe begins.

## 0.31.5

- Craft view: no more "+" after costs. When some of a recipe's reagents have no price yet (not seen on the AH), its "Cost to make" line says so in orange - "(+2 unpriced)" - as the cost bar does; the total covers the priced ones.

## 0.31.4

- Craft view: an opened recipe's source wraps in full - a long "Sold by ..." list goes over as many lines as it needs instead of being cut off - and its cost to make has its own line just above the Create / Shopping list row. The info line at the top is just learned or not, and the level.

## 0.31.3

- Craft view: an opened recipe's info line fits both - the cost takes only the width it needs, so "Not learned  learn at 300" isn't cut to "learn...".

## 0.31.2

- Craft view: an opened recipe's cost shows in full (it was cut off part-way through the coin icon, showing "|T..."); tooltips of rows in your list open to the left, so a long "Sold by ..." stays over the window instead of running off the right side.
- The small "+" after an amount (some prices unknown) has a gap so the coin icon isn't drawn over it.

## 0.31.1

- Craft view: no more overlapping in your list. Each recipe shows what it costs to make (and how many you can make now) on a line under its name, so the name and the star have their room; an opened recipe's info line has its learned / level / source on the left and the cost on the right; the crafting row's buttons no longer have text under them.
- Recipe tooltips for enchants (and anything else that makes no item) show what it actually does - the spell's own tooltip, e.g. "Permanently enchant a weapon to..." - above CraftRoute's lines.

## 0.31.0

- The new view is called Craft, and the buttons read Craft | Route.
- Craft view: opening one of your recipes shows its details right under it, in the list - learned or not with the cost to make, where to get it with map pins, its reagents (Buy / Vendor, make the parts), and a crafting row: quantity, Create, Create All, Shopping list, and how far a batch has got. Your list fills the right column.
- Craft view: the recipe list (left) has no expand marker - a click there adds the recipe to your list or takes it off - and shows just the level under each name.

## 0.30.5

- Destinations: the recipe list shows the skill a recipe is learned at under its name ("Learn at 275", plus "not learned" if you don't know it) instead of to the right of it.
- Destinations: recipe names aren't cut short with "..." any more - each gets the row's full width, and a name that's still too long (Enchanting's especially) is shown a little smaller instead.

## 0.30.4

- Destinations: every recipe row has the same + / - expand marker as the route's steps (+ to open, - when open), with the star beside it, and the tooltip says what a click does.
- Destinations: an even tighter recipe panel - a small icon without the ring, learned / where to get it right under it, slimmer reagent rows. Crafting, Buy / Vendor and the shopping list are all still there.

## 0.30.3

- Destinations: nothing's opened until you click a recipe - click it again to close it. With none open, your destinations list gets the whole right column. Starring a recipe adds it without opening it.
- Destinations: a more compact recipe panel - the icon tucked into the corner, learned / where to get it right under it, the reagents straight after (in slimmer rows), then crafting and the shopping list as before. The route's panel is unchanged.

## 0.30.2

- Destinations: recipe names are coloured by the crafted item's rarity (white, green, blue, purple...), on both sides; a recipe you don't know yet is the same colour, dimmed.

## 0.30.1

- Profession-window view: the lists' scroll bars (route, recipes, destinations) move the right way - down as you scroll down, at the top when you're at the top. They were upside down.

## 0.30.0

- Destinations - a second view in the profession window's CraftRoute tab, for after the route. Route / Destinations buttons sit above the profession picker; a profession at its true max (300) opens on Destinations, everything below that stays on Route, and you can switch either way.
  - Left: every recipe of the profession, with a search box and a filter (all / learned / not learned). Recipes you don't know are greyed. The star adds a recipe to your destinations (and removes it).
  - Right: your destinations (saved per character and profession), each with what one costs to make and how many you can make now; under them, the recipe you clicked - learned or not, and if not where it comes from (trainer with price, vendor, quest or drop) with map pins, then its reagents with Buy / Vendor, Create / Create All with the progress bar, and the shopping list button for its materials.
  - The bar at the bottom shows what making each destination once would cost.

## 0.29.0

- The main window's Craft tab is hidden - the CraftRoute tab in the profession window does everything it did, and more. The main window now has Plan and Recipes, and opens on Plan. Nothing the profession tab uses is removed: the Craft tab's file stays loaded for its shared parts (buy box, component maker, enchant target, merchant scanning), only the tab isn't built. (It can be brought back with one setting in UI.lua, CR.SHOW_CRAFT_TAB.)

## 0.28.14

- With EllesmereUI loaded, CraftRoute uses the font you've chosen in EllesmereUI (its global font, outline and shadow) - in the main window and the profession-window view, on every CraftRoute look. It used to force EllesmereUI's default Expressway font, and only on the EllesmereUI Style look. Each text keeps its own size; a font change in EllesmereUI is picked up on /reload; without EllesmereUI the original fonts are kept. (Contributed fix, integrated with a check so the frequently refreshed profession view only changes fonts that need it.)

## 0.28.13

- Profession-window view: time left for a crafting batch, just above its progress bar - "About 1m 23s left (37 to go)" - from the cast time of your crafts and what's left of the batch, counting down as you go.

## 0.28.12

- Starting a step no longer pulls an earlier "make and keep these" step back in front of it. E.g. with the 45 Bolts of Woolen Cloth made, the Woolen Cape step said go - but the first cape used a bolt, you held fewer than 45, and the bolt step jumped back in. An earlier step's count now only holds you until you've started a step that uses its items (skill past that step's start, or crafted some of it); after that you're spending them, and any real shortfall is made just before the step that needs it, as the route lists it.

## 0.28.11

- The Auctionator shopping list no longer includes things the route makes itself - e.g. Bolts of Woolen Cloth for a tailor: the list has the Wool Cloth to make them from. (The whole-route list counted them as missing; the materials list already showed them as crafted.)
- A step's shopping list (profession window) buys what a component you make is made from, not the component: for Double-stitched Woolen Shoulders, the wool for the bolts you're short of.
- The materials list (Plan tab, Craft tab) is split: what to buy first, then "You'll make" - bolts, cured hides and other things the route crafts itself, with how many ("make 276").

## 0.28.10

- The early stop only happens when it's certain the craft about to go finishes the step: the last craft of a count-based step, or the final point while the recipe is still orange (orange always gives a point) - no extra craft. When it's a guess (yellow / green, one point to go), the queue keeps going and stops on the skill-up instead - at most one extra craft, rather than stopping before every craft that might be the last.

## 0.28.9

- The step-done stop no longer lets one extra craft through. The game starts the next craft the moment one finishes, before the skill-up arrives, so stopping on the skill-up was one craft late. Now the queue is ended as the step's last craft starts: exactly the last one on a count-based step; on a level-based step, the craft that can give the final point - if it does, the step's done with nothing wasted, and if it doesn't (yellow / green) CraftRoute says "No skill point on that ... - press Create to carry on". Steps whose items are kept for later steps still keep going until enough are made.

## 0.28.8

- A batch started from CraftRoute stops by itself once its step is done - skill reached (and, for a step whose items are kept for later steps, enough made) - so an estimate on the high side doesn't make you over-craft and waste materials. The progress bar says "Step done - stopped at 12/50" and a chat line says so. Crafts started from Blizzard's own buttons aren't touched.

## 0.28.7

- Profession-window view: the skill colour bar only shows for recipes you can craft now (not for future steps marked "too soon"), and always fits the row - narrower when the line's text is long, hidden if there's no room. It could run off the window's edge.

## 0.28.6

- Profession-window view: a compact skill-up colour bar next to the recipe's step and count, in place of the coloured word - orange, yellow, green and grey, with a white marker at your skill (the Craft tab's band, small). Hover it for the exact skill points. A recipe you can't learn yet still says "too soon".

## 0.28.5

- The quantity box follows the step's count as it changes (e.g. when a step switches to "repeat: ~4 more"), not only when you switch recipe or while crafting - it could be left showing an old number (6 against a step of 4). A number you type yourself stays until the recipe changes.

## 0.28.4

- While a batch you started is crafting, the quantity box counts down with what the step still needs (50, 49, 48...), on the Craft tab and in the profession window. Typing in the box stops it updating until you're done.

## 0.28.3

- A guide step's objective is its count: 50 Mithril Headed Trout goes 50/50, 49/49, 48/48... with each craft - skill point or not - so the reagents stay matched (green) all the way through.
- Made the guide's count but not at the step's skill yet? The step stays: "Repeat this step: the guide's 50 are done, but you're at 218 - about 9 more to reach 225", with the materials (and shopping list) for those extra crafts, estimated from the recipe's skill colours. Reach the skill first and the step's done.
- Already part-way through a step when you update: the count picks up from where your skill says you are.

## 0.28.2

- A guide step's craft count goes down with every craft. It used to be re-estimated from your skill and always rounded up, so e.g. 50 Mithril Headed Trout stayed at 50 after the first craft while your fish went to 49 - and the reagent turned yellow. Now the estimate rounds properly, and each craft of the step's recipe you make while in its range (from CraftRoute or Blizzard's window) counts too - so a craft that gave no skill point still brings the count down with the reagents it used.

## 0.28.1

- A reagent you're short of that vendors sell (Hot Spices, Fine Thread, flux...) shows a "Vendor" button next to its count - a reminder it's not on the Auctionator shopping list. Talk to a vendor that has it and it turns into the usual Buy button. In the profession window (recipe and route list) and on the Craft tab. CraftRoute knows an item is a vendor item once you've seen it on a merchant (remembered for all characters) or from Auctionator's vendor prices.

## 0.28.0

- Recipe facts come live from TrainerSpells: at login CraftRoute reads each recipe's learn skill, trainer cost and who sells it (vendors by faction, quests) from TrainerSpells, by recipe. When TrainerSpells updates - a trainer teaches something new, a recipe moves to another vendor, a skill changes - CraftRoute follows straight away, with no CraftRoute update. Its built-in recipe data is the fallback for recipes TrainerSpells doesn't list, or when it isn't installed.
- /cr data: how many recipes came from TrainerSpells, and how many differ from the built-in values.

## 0.27.7

- Fixed a Lua error opening the profession window with TrainerSpells installed ("Cannot anchor to a region dependent on it"). Both addons put a tab down the window's side under the lowest tab they find, so each could end up placed under the other. CraftRoute's tab now goes only under Blizzard's tabs, and TrainerSpells' tabs stack under it.

## 0.27.6

- Profession-window view: "Choose one" blocks with more than two options show only the one you've chosen, with a "+ Show N more options" row to open the rest (and "- Hide the other options" to close them). Blocks of two show both as before.
- Profession-window view: CraftRoute's version number next to the Open CraftRoute button.

## 0.27.5

- Cooking's campfire step names who actually sells Flint and Tinder, from the guide - e.g. Erika Tate next to the trainer in Stormwind (Stephen Ryback is only the trainer) - with map pins to them. It used to pin the Cooking trainers.
- The Blacksmith Hammer steps (Blacksmithing, Engineering) name the guide's hammer vendors too, e.g. Sumi in Orgrimmar and Kaita Deepforge in Stormwind, with pins.
- When a step's vendor has no known position, its pins fall back to the nearest trainer, now labelled as such ("Stephen Ryback (Cooking trainer)") - the vendor stands next to them.

## 0.27.4

- Steps with two objectives - reach the skill, and make the guide's count of something later steps use (e.g. 130-140: 20 Cured Heavy Hide) - now check both, against the step's own count. Past the step's range with too few, it stays the current step: "Finish this step: 11 more Cured Heavy Hide - 20 for later steps (you have 9)". Still in range, its crafts cover the count even if the skill would come sooner. (0.27.0-0.27.3 used the total all later steps need instead, and could ask for far more than the step does - 37 here.) Any further amount later steps need is still made just before them, as the guide has it.

## 0.27.3

- Fixed the same step showing several times (e.g. three "Cured Heavy Hide 130-140" lines - 26x, 10x and 1x) when a step you'd passed was short of items for more than one later step. It's now one step with the total - "Finish this step: 37 more to keep for Barbaric Shoulders and Guardian Gloves".

## 0.27.2

- Profession-window view: "Count alts" moved down to just above the Shopping List button.

## 0.27.1

- Crafting stations always read "Anvil required" (for example) - just green while you're at it and red when you're not.

## 0.27.0

- A step whose crafts are kept for a later step isn't done until you've made them. Reach its skill with too few (e.g. 40 of the 60 Rough Blasting Powder kept for the bombs) and it stays the current step - "Finish this step: 20 more to keep for ..." - instead of the shortfall turning up again just before the later step. While you're still in the step's range, its count already covers what the later step needs.
- Crafting station requirements are back for the everyday stations too: Anvil, Forge and Cooking Fire (as well as Tanning Rack, Sewing Machine, Loom and the rest). Each turns green as you stand at it, the way Blizzard's own "Requires" line does - read from the game while the profession window is open (red otherwise).
- Crafting progress: a batch started from CraftRoute (Create All, Create, a typed amount) shows "Crafting Minor Mana Oil 3/50" with a bar that fills over the whole batch - on the Craft tab's cast bar, and at the bottom of the recipe page in the profession window. It says "Made 50/50" (or "Stopped at 12/50" if interrupted) for a few seconds after.

## 0.26.0

- "Count alts' materials" tickbox on the Craft tab and the profession-window tab (next to Open CraftRoute), as well as the Plan tab - one setting, per character, kept in sync. Unticked (the default), only this character's bags, bank and mail count; ticked, materials on your alts (via Syndicator) count too.
- The setting now applies everywhere: reagent colours, have/need counts, "can make" and component counts on the Craft tab and in the profession window, and task-step checks. Before, only the Plan tab's materials list followed it, and the other views always counted alts.

## 0.25.5

- The keybind always opens the profession window on CraftRoute's tab, never the main CraftRoute window. If the profession picked in CraftRoute has no crafting window (Fishing) or isn't learned on this character, it opens the nearest one that has: Cooking for Fishing, otherwise your first crafting profession. The while-dead fallback to the Craft tab from 0.25.4 is gone (the game doesn't switch to crafting pages while dead - a known client issue).

## 0.25.4

- Keybind while dead: the game doesn't open profession windows while you're dead or a ghost, so the key opens CraftRoute's Craft tab instead (same route, reagents and tasks), and closes it again on the next press.

## 0.25.3

- Profession-window view really stays on CraftRoute's tab after crafting. It only leaves on your click - one of Blizzard's tabs, a TrainerSpells tab, CraftRoute's own tab - or when the window closes. If Blizzard's page (or TrainerSpells' frame) comes up any other way it's hidden again straight away, and if anything else hides the view it comes straight back.
- /cr trace: reports in chat whatever brings Blizzard's page up or hides the view, and where from - type it, craft, and send the lines if the tab still switches.

## 0.25.2

- Profession-window view stays on CraftRoute's tab after crafting. When a craft (single or Create All) finished, Blizzard's window refreshed and brought its own recipes page back, and the view took that as you choosing Blizzard's tab. Now only a click on one of Blizzard's tabs leaves CraftRoute's tab; anything else that brings Blizzard's page back is hidden again.

## 0.25.1

- Keybind works while you're dead: it opens the profession window directly from the key press (as other addons' profession buttons do) instead of casting the profession, which the game refuses while dead.
- It's listed as "CraftRoute Profession Tab" in the Keybindings menu (the old name was cut off). A key set on the 0.25.0 binding moves over automatically.

## 0.25.0

- Keybind: Shift+K opens the profession picked in CraftRoute straight onto CraftRoute's tab in the profession window. With the window already open it switches to CraftRoute's tab, and pressing it there closes the window. For Fishing (no profession window) or a profession this character hasn't learned, it opens the main CraftRoute window. Change the key under Options > Keybindings > AddOns > CraftRoute. Doesn't open a profession in combat (the game doesn't allow it).

## 0.24.1

- Blacksmithing follows the guide's update (Oct 10): 150-165 is now 19 Bronze Warhammers, then 15 Green Iron Bracers for 165-175 (was 30 Green Iron Bracers for 150-175). Green Iron Bracers can't be learned before 165, which the guide now matches. Strong Flux for the Bronze Warhammers comes from the Blacksmithing Supply vendor in any capital.
- tools/check_guides.py works with wow-professions.com's redesigned pages (compares from the guide's intro line, ignores invisible characters in ranges, prints emoji on Windows).

## 0.24.0

- Recipe learn skills now come from the TrainerSpells addon's Forever data - what the trainer asks for (GitHub issue #5). They used to come from ahledger.com, whose "skill" is mostly the recipe's yellow point minus 40, an estimate: Enchant Boots - Lesser Agility said 140 where the trainer wants 160. About 360 recipes across Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking and Tailoring change; ahledger now only fills recipes TrainerSpells doesn't list. (While Forever is in beta, a few guide steps may now start before the recipe's listed skill - the data follows TrainerSpells as its developers update it.)
- Profession-window view: a recipe's reagents are never cut off. All of them show, with the cost lines under them, in an area that scrolls (mouse wheel, slim bar on the right) when there are more than fit. The "+N more on the list" line is gone.

## 0.23.4

- Profession-window view (GitHub issues #1, #3, #4):
  - The recipe's reagent list shows every reagent that fits instead of stopping at 3 with "+1 more on the list" - it now measures the room between the "Reagents:" label and the Shopping List button.
  - Reagent rows and their Buy buttons stay inside the right column.
  - Create All sets the quantity box to the number it queued.

## 0.23.3

- Profession-window view: task cards start below the Open CraftRoute button, so the step's label and title no longer run under it.

## 0.23.2

- Task cards scroll when there's more than fits (long guide text, many objectives): mouse wheel, with a slim bar on the right showing where you are. In both the Craft tab and the profession-window view; a new step starts at the top.

## 0.23.1

- Nat Pagle, Angler Extreme: each quest fish on the card has its own Pin button for where to catch it - Feralas Ahi at Verdantis River (Feralas), Misty Reed Mahi Mahi at Misty Reed Strand (Swamp of Sorrows), Sar'theris Striker at Sar'theris Strand (Desolace), Savage Coast Blue Sailfin on the Savage Coast (Stranglethorn Vale). With WaypointUI the waypoint is named after the fish.
- Task cards show up to 16 objectives (the Gadgetzan step has 11).

## 0.23.0

- Rank steps stop at the right moment. A book, quest or trainer rank whose skill you haven't reached yet no longer blocks the route. You keep fishing or crafting, and the route stops on it the moment your skill gets there: e.g. it stops mid-way through cooking catfish at Cooking 125 to read the Expert Cookbook, then carries on.
- If there's something to buy for it first (the Expert Cookbook, the Alterac Swiss in Shadowprey Village), the route stops for just that now ("GET READY"), then the step waits for your skill.
- Waiting steps show in the profession-window list as "At 125: ..." and on their card as "AT COOKING 125".
- More objectives on task steps:
  - Fishing + Cooking starting zones: "Fishing learned".
  - Mystral Lake (Alliance): "Bought Expert Cookbook" (ticked once read).
  - Nat Pagle, Angler Extreme: the four quest fish, in both Fishing guides.
  - Cooking's Artisan rank: the three Gikkix recipes.
  - First Aid's Expert rank: Manual: Heavy Silk Bandage and Manual: Mageweave Bandage.
- Rank and book steps show quest items as handed in once the rank is learned, and the book's price is only counted until it's read.

## 0.22.6

- More objectives on task steps, each with a tick or a cross:
  - Fishing + Cooking: the recipes each starting-zone and capital step tells you to buy (Brilliant Smallfish, Slitherskin Mackerel, Longjaw Mud Snapper, Bristle Whisker Catfish), Booty Bay's Mithril Head Trout and Filet of Redgill from Kelsey Yance, and the 20 Alterac Swiss on the Stormwind and Desolace steps.
  - Booty Bay's Expert Fishing step also shows the skill 125 and level 20 it needs.
  - Cooking: Flint and Tinder for the campfire, with the nearest Cooking trainers pinned (the vendor is next to them).
  - Enchanting: the Copper Rod and Mote of Magic for your first Runed Copper Rod, with the nearest Enchanting trainers pinned.
- Flint and Tinder counts as crafting equipment (only on you).
- Items a step checks that a later craft already uses aren't added to the materials list a second time.

## 0.22.5

- Task steps check the recipes a guide step tells you to buy: Fishing + Cooking's Gadgetzan step ticks off Spotted Yellowtail, Nightfin Soup and Poached Sunscale Salmon from Gikkix as you learn them, and the Feralas step Baked Salmon.
- Artisan quest steps (Clamlette Surprise, Nat Pagle, Angler Extreme, Triage) show whether the quest is in your quest log, and "done" once the Artisan rank it rewards is learned.
- The combined guide's Artisan quest steps also show the skill and level the quest needs.

## 0.22.4

- Map pins carry the NPC's name with WaypointUI installed ("Therum Deepforge" instead of "Map Pin"). Without it, the plain Blizzard pin as before.

## 0.22.3

- Crafting equipment only counts when it's on the character doing the crafting (bags or equipped): Blacksmith Hammer, Mining Pick, Skinning Knife, fishing poles, Arclight Spanner, Gyromatic Micro-Adjustor, the Runed enchanting rods and the Philosopher's Stone. One in your bank or on an alt no longer counts as owned in the materials list, the route cost, reagent colours or task steps. Materials still count your bank, mail and (with the setting on) alts as before.

## 0.22.2

- Shopping steps (Blacksmith Hammer, baubles, nightcrawlers) only count what's in your bags now. A hammer in your bank or on an alt used to tick the step off before you'd bought one, so it never stopped.
- Engineering and Blacksmithing: the "Buy a Blacksmith Hammer" step lists the nearest trainers with Pin buttons; the supply vendor stands next to them.
- Profession-window view: finished task steps stay clickable ("Done: ..." in grey), so you can still look up where something was. A step you ticked by hand has a "Not done yet" button to put it back on the route.
- Shopping steps are labelled SHOPPING on the card.

## 0.22.1

- Fishing + Cooking: the "Learn Journeyman / Expert / Artisan" steps now list the nearest trainers with Pin buttons (as the Fishing-only guide does), plus the skill and level they need, and are labelled as training / book / quest.
- Profession-window view: a task step no longer shows the last recipe's "Not enough reagents" line under the card.

## 0.22.0

- Task steps: the route now stops at the steps that aren't crafts - training the next rank, buying and reading a book (Expert Fishing / Cooking / First Aid), the Artisan quests, buying supplies (baubles, nightcrawlers), learning a recipe before its craft, and fishing to a skill. Both the Craft tab and the profession-window view show a task card in the recipe's place: what to do, a checklist, the nearest NPCs with a **Pin** button each (a Blizzard map pin, tracked on screen), the cost, and skill progress for fishing steps.
- The game ticks tasks off by itself where it can tell (rank learned, max skill raised, book or supplies in your bags, recipe learned, skill reached); **Mark as done** is the fallback for anything it can't. `/cr tasks reset` undoes the manual ticks for the current profession.
- NPC locations come from the TrainerSpells addon when it's installed (profession trainers and recipe vendors, filtered to your faction, nearest first), plus Old Man Heming, Shandrina and Nat Pagle for the guide steps.
- "Learn this recipe" tasks appear once CraftRoute knows what you've learned (open the profession once); trainer recipes show the training cost.
- Tips with nothing to do and nobody to visit stay plain notes in the route list.
- Fishing+Cooking: the Expert steps now say which book to buy.

## 0.21.5

- /cr probe lists every frame of the profession window under the mouse (outside CraftRoute): where it hangs, its size and textures - to identify the stray boxes over the recipe icon, which /cr view showed aren't CraftRoute's.

## 0.21.4

- /cr view reports what the profession-window view and Blizzard's window are showing (which page is up, whether the view thinks it should be open, and every piece of its recipe icon) - to track down the stray boxes over the recipe icon.

## 0.21.3

- Profession-window view: it now closes whenever one of Blizzard's own pages is showing. After the latest client update, going to one of Blizzard's tabs no longer closed it, so it stayed up - mostly empty - over Blizzard's page, which is where the stray boxes over Blizzard's recipe icon came from.

## 0.21.2

- Profession-window view: fixed stray square boxes over the recipe icon (and their hover highlight) after the latest WoW Forever update. The icon is now drawn by CraftRoute itself - round, masked, with its ring and tooltip - instead of from a Blizzard button template whose new square slot pieces showed through.

## 0.21.1

- Profession-window view: the route cost bar no longer has a tooltip (it got in the way; the cost speaks for itself).

## 0.21.0

- Profession-window view: a route cost bar at the bottom of the route column - "Route cost" with what buying everything the rest of the route still needs would cost (Auctionator prices, vendor price for vendor items), and an orange "(+N unpriced)" note when some items have no price yet. Hover for details. Styled like the main window's cost bar; the list ends just above it.

## 0.20.1

- Profession-window view, "choose ONE" options: a compact version of the main window's style - a tinted panel (green when chosen, dark gold when not) with brighter caps at both ends, a radio button, and a tick on the chosen option in place of the Choose / Selected button. Light text with a shadow for contrast on either tint; the tooltip says which is chosen.
- The step you're looking at gets its own, unmistakable highlight: a cool blue selection (soft fill, thin outline, bright bar on the left) instead of the gold glow that looked like the options.

## 0.20.0

- Profession-window view: a "Shopping List" button above Create makes an Auctionator shopping list for just the current step - what its crafts need that you don't have anywhere (bags, bank, mail, alts), named "CraftRoute: <recipe>". Vendor-sold reagents are left off (buy those from a vendor). Shown when Auctionator is installed; styled with the selected look.

## 0.19.12

- Tooltips never stretch across the screen: long text wraps (guide-step and training notes in the profession-window view - the Artisan Cooking note was one long line - and the "choose ONE" option tooltips in both windows), and two-column lines that can't wrap ("Needed for ..." on item tooltips, the crafts listed on Plan options) cut long labels short with "...". Every tooltip in the addon was checked.

## 0.19.11

- Skill bars take the profession's own colour, in both windows: Alchemy green, Blacksmithing forge orange, Enchanting violet, Engineering brass, Leatherworking tan, Tailoring rose, Mining steel, Cooking orange, First Aid red, Fishing blue.
- Profession-window view: the skill bar's text is centred on the dark track rather than on the whole frame (the track sits high in the frame art, so the text looked low).

## 0.19.10

- Profession-window skill bar: back to the plain gold fill (the attempt at Blizzard's styled art is dropped), and the fill now covers exactly the frame's dark track - 4 px in from the top and sides, stopping above the frame's lower bevel - so it no longer spills below it.

## 0.19.9

- Profession-window skill bar: the fill sits inside the frame's dark track again (0.19.8 sized it from Blizzard's fill piece, which is drawn the frame's full height, so it came out taller than the track), and it draws the exact region of the texture sheet Blizzard's fill shows, instead of the whole sheet. /cr rankbar now also reports each piece's texture coordinates and the textures inside sub-frames.

## 0.19.8

- Profession-window view, skill bar: the fill now spans the whole track - it was sized for a shorter track, so it stopped short and left black where it should have filled (and never quite reached the end at full skill).
- The fill uses Blizzard's own textured, profession-styled bar art (read from its recipe page's bar, cropped to your skill rather than squashed), with its bright flare at the end, unless the look is EllesmereUI Style, which keeps a flat bar in its accent colour. Falls back to a gold bar if the art can't be found. /cr rankbar lists what Blizzard's bar is made of, to help match it if a client differs.

## 0.19.7

- Profession-window view: laid out to match Blizzard's own recipe page, so flicking between the two barely moves anything. A header band with the skill bar centred at the same height and width; the pickers on the line where Blizzard's search box is; the route list starting where its recipe list does, in a column of the same width; the recipe icon, name and "Reagents:" where its schematic has them, with reagent icons the same size; Create All at the panel's left edge and a wider Create at the right, with the count between.

## 0.19.6

- Profession-window view: the profession box shows just the profession's name (its skill is on the bar above; the list still shows it), with room for the whole name. The goal box shows a short label too ("Expert (225)" rather than "My level's highest rank: Expert (225)"; the list keeps the full wording) - in the main window as well.
- Dropdown lists are as wide as their longest entry, so no text runs past the edge (both windows).
- The profession-window view follows the selected look: its buttons (Create, Make, Buy, Open...) are flat in EllesmereUI Style and Blizzard-styled otherwise, and its text uses EllesmereUI's font in that style. Buttons made after the look was applied are styled straight away.

## 0.19.5

- Profession-window view: the profession and goal pickers moved to the left column, above the route list (side by side; the custom skill box beside them when "Custom skill" is picked, and the route mode on a line of its own for Cooking / Fishing). An "Open CraftRoute" / "Close CraftRoute" button above the recipe, at the right edge, opens and closes the main window.

## 0.19.4

- Profession-window view: no more flash of Blizzard's recipes page when switching profession from the CraftRoute view. The view now stays open through the switch, and the page Blizzard shows as the new profession loads is hidden again in the same frame, before it's drawn. (The half-second retries from 0.19.3 remain only as a backup.)

## 0.19.3

- Profession-window view: switching profession from its dropdown (or its Open buttons) now keeps you on the CraftRoute view. The profession still opens so you can craft, but Blizzard's window flips back to its own recipes page as it loads - CraftRoute now puts its view back once the new profession has loaded. Opening a profession any other way behaves as before.

## 0.19.2

- Fixed: "Interface action failed because of an AddOn" when switching profession. The game only lets a real click open a profession window (OpenTradeSkill is protected), so CraftRoute no longer tries to open one by itself. Instead, picking a learned profession from a CraftRoute profession dropdown (Craft tab and profession-window view) casts it as part of your click, like /cast Cooking, which opens its window; and every Open button (Craft tab, opened component sections, profession-window view) does the same. Mining opens Smelting; Fishing has no crafting window, so it's just selected.
- The Craft tab no longer tries to open the profession window when you open /cr - use its Open button (one click).

## 0.19.1

- When the game blocks something CraftRoute tried ("Interface action failed because of an AddOn"), CraftRoute now says in chat exactly which function was refused and whether it was forbidden outright or blocked (e.g. in combat), so it can be fixed.

## 0.19.0

- Profession-window view: components and vendor buying, like the Craft tab. In the route list, a reagent you can make gets a + that opens what it's made from, a level further in each time (Medium -> Light -> scraps, bars -> ore, essences), each with a Make N / Smelt N / Split / Combine button (or Open, to switch to the profession that makes it). With a vendor open, reagents it sells get a Buy button, in the list and in the recipe panel. Clicking a reagent in the recipe panel opens its chain in the list.
- Picking a profession from a CraftRoute dropdown now opens that profession's window even when the game doesn't report its skill line (it used to say "Open Leatherworking from your spellbook").
- The buy box is shared by both views (one box, shown over whichever window opened it).

## 0.18.0

- New: a CraftRoute tab in Blizzard's profession window (Compact.lua, contributed by a friend of the project). It opens a compact CraftRoute view inside the profession book: the route down the left (expand a step to see its reagents, pick "choose ONE" options), the selected recipe with reagents, costs and Create / Create All on the right, and the enchant target for enchants. Profession, goal and route mode are the same settings as /cr, so the two stay in sync. It sits alongside TrainerSpells' tab if you use it.
- Its reagent counts and colours follow the Craft tab's rule; its enchant covers hide when combat starts.

## 0.17.3

Routes checked against the wow-professions.com guides as of 9 Oct 2026:
- Engineering: keep all 6 Mithril Tubes at 195-200 if you might pick Gnomish Engineering; a new step at 200 explains the Gnomish / Goblin specialization (Engineering 200, level 30); the route is now marked untested only past 225 (was from 200), as in the guide.
- Every other guide only gained a link to its trainers page - no route changes.

## 0.17.2

- README rewritten: a fresh feature summary of what CraftRoute does.

## 0.17.1

Routes updated to the wow-professions.com guides as of 8 Oct 2026:
- Leatherworking: Cured Heavy Hide path makes 20 Hillman's Leather Gloves at 140-155 (was 16). Without Heavy Hide: 30 Hillman's Leather Gloves for 130-155, 17 Barbaric Leggings for 155-170 and 5 Barbaric Harness for 170-175 (was 21 for 130-150, 15 for 150-165, 10 for 165-175).
- Enchanting: 151-165 is now 16 Minor Mana Oil (Soul Dust, Maple Seed, Leaded Vial) instead of Enchant Bracer - Lesser Strength; buy Formula: Minor Mana Oil with the 2H Weapon formula at 110. 165-185 notes the guide's beta tip to keep making Boots - Lesser Agility until 200 while Vision Dust is expensive.
- Notes: the "turns yellow at..." remarks the guides dropped are gone from the step notes too (Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring, First Aid).
- Totals checked against the guides' shopping lists. Cooking, Fishing and Fishing + Cooking hadn't changed.
- tools/guides.txt lists the guides and tools/check_guides.py checks them all for changes.

## 0.17.0

- Craft tab: components can come from any crafting profession your character has, not just the current one. A blacksmith with Leatherworking gets a + on Thick Leather for Heavy Mithril Boots ("Make Thick Leather (Leatherworking) from:"), chaining down to Heavy / Medium / Light; an engineer with Tailoring makes their Bolts of Cloth; an enchanter with Blacksmithing makes their rods; a tailor with Alchemy makes their dyes; Enchanted Leather, Sulfuric Acid, Sandpaper, Iron Buckles and so on likewise. Mining only ever offers smelting bars. The current profession's own recipe is used first; with several, one you have the skill for. Professions you haven't learned are never offered. Crafting it needs that profession's window open - the section's Open button switches to it.

## 0.16.1

- Route: smelting is no longer added as its own step ("+ 10x Smelt Copper"). The guides don't send you smelting; they just need the bars. The route shows the items to craft, your ore still counts towards the bars in the materials, and you smelt from the bar's + on the Craft tab when you're short. (The Craft tab also stops saying you haven't learned Smelt Copper - it was treating it as a Blacksmithing recipe.)

## 0.16.0

- Craft tab: bars are components too if you have Mining. A bar you're short of (Copper, Bronze, Iron...) gets a + that opens "Smelt Copper Bar from:" with the ore, how many you're short, and a Smelt N button - like making Medium Leather from Light. It chains too (Bronze Bar opens to Copper and Tin Bars, which open to their ore). Smelting needs the Mining (Smelting) window open rather than Blacksmithing's, so the section offers to open it; switch back to Blacksmithing for the craft itself. Characters without Mining don't get the option.

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
