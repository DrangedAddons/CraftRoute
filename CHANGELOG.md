# CraftRoute changelog

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
