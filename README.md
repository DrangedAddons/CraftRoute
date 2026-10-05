# CraftRoute

A profession leveling planner for **World of Warcraft: Forever**.

Pick a profession and a goal, and CraftRoute shows the steps from your current skill, what to buy or gather, and what it costs:
- **Leveling routes** from the wow-professions.com Forever guides: Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring, Cooking, Fishing, First Aid, and Fishing + Cooking together. Where a guide offers alternatives ("do one of these"), you choose which one counts.
- **Target recipes:** tick gear you want to make (e.g. the Wisdom's Leather set) and it's added to the plan at the skill where you can craft it.
- **Materials:** have/need across bags, bank, mail and, optionally, your alts (via Syndicator). Items made earlier in the route are passed on to later steps.
- **Prices:** AH and vendor prices from Auctionator, the total cost of what's missing, and a one-click Auctionator shopping list.
- **Tooltips:** hover any material to see which steps need it, for every profession you've learned.
- **Your faction only:** you only see your own faction's trainers, vendors and zones.

Type `/cr` (or `/craftroute`) to open it.

Optional: [Auctionator](https://www.curseforge.com/wow/addons/auctionator) for prices, and [Syndicator](https://www.curseforge.com/wow/addons/syndicator) for bank, mail and alt counts.

Route data is based on beta guides and will be updated after launch. Mining, Herbalism and Skinning will be added once Forever guides exist for them. See `CHANGELOG.md` for history and `tools/` for how the recipe data is built.
