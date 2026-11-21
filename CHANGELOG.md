# Changelog

All notable changes to BuyEmAll Continued are documented in this file. The original BuyEmAll's release notes follow under [Upstream history](#upstream-history).

## [Unreleased]

### Added
- Loads on World of Warcraft: Forever as well as retail: the TOC now lists Interface 16001 and drops the stale 120000 and 120001 values ([#31](https://github.com/Tharavol/BuyEmAllContinued/issues/31)).

### Fixed
- **The Stack button no longer lowers the amount** ([#28](https://github.com/Tharavol/BuyEmAllContinued/issues/28)). With a partial stack in your bags, typing an amount past the room left in that stack and clicking Stack could take the amount down. It now always goes up to the next amount that fills a stack.

### Internal
- The repository now includes tests that run the addon against stand-in WoW APIs, with no game client ([#16](https://github.com/Tharavol/BuyEmAllContinued/issues/16)). They aren't part of the release archive.
- Every push and pull request now runs luacheck, the tests and a packager dry run ([#14](https://github.com/Tharavol/BuyEmAllContinued/issues/14)).
- Internal cleanup with no intended change in behavior ([#11](https://github.com/Tharavol/BuyEmAllContinued/issues/11)): addon state is declared in one place, the `BUYEMALL_MAX`, `BUYEMALL_STACK` and `BEAFrame` globals are gone, and dead code and outdated comments are removed.
- New issues offer a bug report form, asking for the Lua error, game and addon versions, the vendor and item, and other merchant or bag addons, and a feature request form ([#20](https://github.com/Tharavol/BuyEmAllContinued/issues/20)).
- A daily workflow updates the TOC `## Interface` line when the client moves to a new build, and `vX.Y.Z-alpha.N` / `-beta.N` tags publish a GitHub prerelease for testing before a stable release ([#15](https://github.com/Tharavol/BuyEmAllContinued/issues/15)). The CI, release and prerelease workflows share one archive layout check.
- The daily TOC Interface check tracks both the retail and WoW Forever versions, so its bump doesn't rewrite the Interface line to retail only ([#32](https://github.com/Tharavol/BuyEmAllContinued/issues/32)).
- Each GitHub release's notes are now that version's section of this changelog rather than the whole file ([#17](https://github.com/Tharavol/BuyEmAllContinued/issues/17)). A stable tag without a section fails before anything is published.
- The upstream release notes from `Changelog.txt` are now part of this file, under Upstream history, and `Changelog.txt` is gone ([#18](https://github.com/Tharavol/BuyEmAllContinued/issues/18)).

## [4.1.6] - 2026-11-01

### Fixed
- **Large purchases now stop when you leave the vendor** ([#2](https://github.com/Tharavol/BuyEmAllContinued/issues/2)). A purchase bigger than one stack is bought one stack every half second, and closing the vendor didn't stop it, so opening another vendor within a few seconds could spend the rest of the run on whatever item sat in the same position there. The run now stops when the vendor closes, and before each stack it checks the vendor is still selling the same item, waiting a few seconds if the game hasn't loaded that item's data yet ([#24](https://github.com/Tharavol/BuyEmAllContinued/issues/24)). If a run stops early, chat says how many weren't bought.
- **BuyEmAll now loads on game languages it has no translation for** ([#3](https://github.com/Tharavol/BuyEmAllContinued/issues/3)), such as Italian, instead of failing with "attempt to index local 'L' (a nil value)". It uses English there. Translated languages also fall back to English for any text not yet translated, such as the new purchase-stopped message.
- **Items priced in two currencies no longer show a stray "0" as a third cost** ([#4](https://github.com/Tharavol/BuyEmAllContinued/issues/4)).
- **Bundles bought with currencies no longer go past what fits in your bags** ([#5](https://github.com/Tharavol/BuyEmAllContinued/issues/5), [#23](https://github.com/Tharavol/BuyEmAllContinued/issues/23)). Items sold in bundles for currencies (say, 5 per purchase) are bought in whole bundles, and an amount in between was always rounded up, even when the extra bundle wouldn't fit. The most you can choose is now the number of whole bundles that fit, so the Max button matches what gets bought, and the window doesn't open if not even one bundle fits.
- **`/buyemall confirm` now stays off after a reload or relog** ([#22](https://github.com/Tharavol/BuyEmAllContinued/issues/22)). Turning off the large-purchase confirmation only lasted until the next login, when it came back on.
- **Arrow keys can no longer take the amount out of range** ([#6](https://github.com/Tharavol/BuyEmAllContinued/issues/6)). Pressing them could take it to 0 or below, or past the maximum. They now stop at the same limits as the on-screen arrows.
- **"You can fit" and the Max button now count the reagent bag for crafting reagents** ([#8](https://github.com/Tharavol/BuyEmAllContinued/issues/8)). Its free space was left out, so both came in too low when buying reagents.
- **Shift-clicking no longer risks a Lua error with a profession bag equipped, or on vendor entries without an item link** ([#9](https://github.com/Tharavol/BuyEmAllContinued/issues/9)). The profession bag check used a global function Blizzard has deprecated, and the Azerite check was given an empty link.
- **Unique items are now recognised in every game language, including "Unique (N)" items** ([#7](https://github.com/Tharavol/BuyEmAllContinued/issues/7)). The check only matched the English word "Unique", so other languages weren't limited, and items with a higher limit were missed. The most you can choose is now what's left of the limit. Items you can't afford no longer count as buyable just because they're unique.
- **Two small limit fixes** ([#10](https://github.com/Tharavol/BuyEmAllContinued/issues/10)). The "Vendor has" tooltip line now shows a stock of exactly 1, and right-clicking Stack on an item sold in bundles now stops at one bundle instead of going down to 1.

### Known gaps
These parts were only checked with stand-in WoW APIs, not in the game, because a suitable client, vendor item or bag wasn't available. Please report anything that misbehaves.
- Game languages other than English: the fallback to English ([#3](https://github.com/Tharavol/BuyEmAllContinued/issues/3)) and unique-item recognition ([#7](https://github.com/Tharavol/BuyEmAllContinued/issues/7)).
- Items priced in other currencies: the stray "0" cost ([#4](https://github.com/Tharavol/BuyEmAllContinued/issues/4)), the bundle limits ([#5](https://github.com/Tharavol/BuyEmAllContinued/issues/5), [#23](https://github.com/Tharavol/BuyEmAllContinued/issues/23)), and the arrow-key and Stack limits on bundles ([#6](https://github.com/Tharavol/BuyEmAllContinued/issues/6), [#10](https://github.com/Tharavol/BuyEmAllContinued/issues/10)).
- Waiting for item data during a large purchase ([#24](https://github.com/Tharavol/BuyEmAllContinued/issues/24)), and buying a unique item through the window ([#7](https://github.com/Tharavol/BuyEmAllContinued/issues/7)).
- Shift-clicking with a profession bag equipped or on a vendor entry without an item link ([#9](https://github.com/Tharavol/BuyEmAllContinued/issues/9)), and the "Vendor has" line at a stock of exactly 1 ([#10](https://github.com/Tharavol/BuyEmAllContinued/issues/10)).

Two questions about how the game handles bundles are still open and scheduled for 4.1.7: what vendor stock counts on a bundled item ([#26](https://github.com/Tharavol/BuyEmAllContinued/issues/26)), and what happens when a large purchase sends a partial bundle ([#27](https://github.com/Tharavol/BuyEmAllContinued/issues/27)).

## [4.1.5] - 2026-10-14

### Fixed
- **Shift-clicking an item at a vendor no longer throws a Lua error on WoW 12.1.5** ([#1](https://github.com/Tharavol/BuyEmAllContinued/issues/1)). 12.1.5 no longer provides the global item functions BuyEmAll used to measure free bag space, so every shift-click failed with "attempt to call a nil value". They are replaced with their `C_Item` equivalents. Buying items priced in other items, which used the same functions, is fixed too.
- If the game hasn't loaded an item's data yet, shift-click now does nothing that time instead of erroring. Clicking again works once the data has loaded.

### Changed
- **Now maintained as BuyEmAll Continued.** The AddOns list shows the new name; the folder, `/buyemall` command and saved settings are unchanged, so existing installs upgrade in place. See [ATTRIBUTION.md](ATTRIBUTION.md).
- The repository now includes the MIT license text, credits, and this changelog.

### Internal
- The TOC adds interface 120105 (12.1.5) and no longer carries the upstream CurseForge, WoWInterface and Wago project IDs, which belong to the original listings.
- Releases are built by the BigWigs packager from version tags.

## [4.1.4] - 2026-01-24

Last upstream release (CurseForge project 2590), imported unmodified as the first commit of this repository. Its TOC reads 4.1.3.

## Upstream history

Release notes of the original BuyEmAll up to v4.1.0, in their original wording, from the `Changelog.txt` it shipped with. Versions 4.1.1 to 4.1.4 have no published notes. Issue numbers here refer to the upstream tracker, which is no longer reachable.

### v4.1.0

- Restore modification of the shift-click frame, hopefully restoring compatibility with most addons

### v4.0.5

- Fix error that would pop up when the vendor window was reopened after being moved by BlizzMove.

### v4.0.4

- The BuyEmAll frame can now be moved with BlizzMove

### v4.0.3

- Support for Scrap added
- Support added for addon tabs added to MerchantFrame through the SecureTabs-2.0 library
- Prepare support for Krowi's Extended Vendor UI (KEVU). KEVU needs an update as well. BuyEmAll 4.0.3+ and KEVU 8.4+ will be be able to work together.

### v4.0.2

- Remove forgotten print statement from code

### v4.0.1

- Fix lua error that occurs when another addon changes MERCHANT_ITEMS_PER_PAGE
- Added compatibility with SellJunk
- Suppress ArkInventory warning about HookOpenAllBags:BuyEmAllFrame not existing

### v4.0.0

- BuyEmAll is now compatible with The War Within (11.0.2).
- The addon has been rewritten to no longer manipulate the existing Blizzard merchant frame, but now has its own merchant frame using code from the original.
  This frame looks exactly the same as blizzard's frame, and works the same,
  but the code has been changed in a few places to show the BuyEmAll bulk buying frame rather than blizzard's own "stack buying frame".
  All taint errors in the Dragonflight versions of the addon should be gone thanks to this rewrite.

### v3.5.17

- Update to patch 10.1

### v3.5.16

- Fix error that occured when not all bag slots were equipped with bags

### v3.5.15

- Update french localisation file (thanks to KarlitosVII on GitHub)

### v3.5.14

- Fix detection of partial stacks
- Fix detection of Unique items, which should bypass the BuyEmAll dialog entirely

### v3.5.13

- Support for WoW Dragonflight 10.0.2

### v3.5.12

- Support for WoW Dragonflight 10.0.0
- Fix code for calculating free bag space, as bag IDs have changed in Dragonflight

### v3.5.11

- bump toc file to 9.2.5

### v3.5.10

- Addon toc has been updated to WoW 9.1.0
- Fixed error that would occur when trying to purchase items that are completely free but would normally cost currency to purchase (fixing a bug that probably only happens on tournament and beta realms, where items are sometimes available for free, but blizzard does not or forgets to remove the associated currency cost info from the item)

### v3.5.9

- Fixed bug that caused an error when buying a currency with another currency.

### v3.5.8

- BuyEmAll now supports Shadowlands
- BuyEmAll now uses the new CurrencyInfo API introduced in Shadowlands
- Fixed a small issue where the calculated amount of buyable items was wrong when buying a currency with another currency.

### v3.5.7

- Internal optimalisation for recognizing unique items
- optimized code throughout the addon for better performance and a smaller footprint

### v3.5.6

- Addon ownership has transferred from Shinisuryu to Jordy141
- When buying currencies, the exchange is now done in one go instead of one item at a time, greatly speeding up transaction time (issue #22)
- When purchasing an item that can only be bought in stacks, BuyEmAll now rounds the purchase amount up to the next multiple of the stack size the item is sold in, rather than to the nearest multiple.
  This ensures you always get the amount you entered or more, and never less.
- BuyEmAll now recognizes unique items and forces their max purchase amount to 1, skipping amount selection altogether.
- Fixed potential issue with affordability calculation for items that require more than 3 alternate currencies to purchase (for future-proofing)

### v3.5.5

- [KyrosKrane via GitHub] Bug fix for Tempered Seal of Fate and similar currencies sold for gold.

### v3.5.4

- TOC update.

### v3.5.3

- Slight fix of said minor fix without breaking functionality.

### v3.5.2

- Minor fix for previewing azerite gear in vendors.

### v3.5.1

- TOC bump for now.

### v3.5.0

- Haven't found anything to be broken, TOC bump.

### v3.4.4

- Quick TOC bump.

### v3.4.3

- Tiny fix for purchasing currencies with a set maximum, missed that detail.

### v3.4.2

- Fixed buying currencies and some other non-item things with gold.
- Added some checks to ensure things are handled in the right function.

### v3.4.1

- Fixed purchases with gold because I missed a function return change.

### v3.4.0

- Formatted parts for easier readablity, for me at least.
- Rewrote the alternate currency handler to be more adaptive.
- Thanks to a recent (7.2.5) change, removed my clunky alternate currency ID function.
- Added an auto rounding function to work better with buying a vendor stack for one item. (e.g., Blood of Sargeras)
- A note on the auto rounding, the number you see in the frame will be rounded to the nearest multiple of the purchasable item when bought.

### v3.3.6

- Quick TOC update.

### v3.3.5

- Super tiny and quick change to hopefully fix some syncing issues with sites.

### v3.3.4

- Forgot to completely remove old reagent bank search, my bad!

### v3.3.3

- Fixed alternate currency bank searching, turns out I did it both bad and wrong.
- Prevented the purchase amount going over the maximum when typing in manually.

### v3.3.2

- Quick TOC bump.

### v3.3.1

- Re-added Mogu Rune of Fate to the alternate currency list, was removed by mistake.
- Added Seal of Tempered Fate to the alternate currency list.

### v3.3.0

- Alternate currency list cleaned and updated to include Legion.

### v3.2.9

- Nothing seems broken, TOC bump.

### v3.2.8

- *Might* have somehow not added Mogu runes in the last version. If I didn't, I'm an idiot. But added now.
- Reworked the purchase loop. Now there's a ~0.5 second delay in between purchases, should prevent any "Item is busy" issues.

### v3.2.7

- Added Mogu runes support. Now should fix purchasing currencies with currencies.

### v3.2.6

- Fixed purchasing currencies with currencies. Hopefully at least.
- Minor adjustments, tiny bit of prep for a possible future improvement.

### v3.2.5

- Updated TOC.

### v3.2.4

- Added in reagent bank support.
- Did some reformatting and adjusting of the code, mostly for looks.
- Updated TOC.

### v3.2.3

- Fixed an issue where there was a chance of the number of items to purchase going below 1 into negative numbers.
- Changed how the price is calculated for alternate currency items to be correct.

### v3.2.2

- Super derp on my part, turns out there was a problem with how the addon passed arguments to regular functions, fixed that.
- Minor adjustments to follow Blizzard's 1/nil/0 -> true/false changes.
- Added new WoD currencies.
- Turns out I was super wrong on handling saved variables, so no one's preferences about the confirm window were saved. Sorry, I fixed it now!
- In case I missed anything, please let me know.

### v3.2.1

- Thought there was a problem, guess it was just a bug on Blizzard's end.
- Made some minor adjustments to sort out off textures.

### v3.2.0

- Haven't found any problems, so just TOC update.

### v3.1.8

- TOC bump, added new currency.

### v3.1.7

- Updated alternate currency support.

### v3.1.6

- No known issues, TOC bump.

### v3.1.5

- No known issues, TOC bump.

### v3.1.4

- Added Russian translations thanks to OUGHT, with alternates from Amshaegar due to slight differences.
- Updated TOC.
- Added changelog in case anyone was curious, and so the lists online don't get too large.

### v3.1.3

- Added all known currencies/tokens to the handler, for new and a few old vendors.

### v3.1.2

- AddonLoader support.
- Taint fixes.
- Updated German translations thanks to Lysandro.
- Login errors coming from translations should be fixed, rewrote how translations are done.

### v3.1.1

- Fixed the Blackfallow Ink issue.
- Added in Motes of Darkness and Essences of Corrupted Deathwing into the currency translator.
- Added Portuguese translations thanks to Phanx.

### v3.1.0

- Finally finished for the most part, might be a few things I missed, as always, let me know in the comments.
- Wrote a new currency handler, should auto adjust between gold and other currencies.
- Fixed the free space calculation when identifying what bags the item goes into, should be more accurate now.
- Fixed the free space calculation skipping the backpack.

### v3.0.9

- Reversed the recent change I made, dunno when I'll be able to get alt currencies working, much harder than I expected. x.x

### v3.0.8

- Did a tiny bit of clean up in the code and added a work around for some items.
- Bumped TOC.

### v3.0.7

- Bumped TOC, assuming no errors since I can't check right now.

### v3.0.6

- Fixed the error that would occur from shift-clicking the Honor/Justice points vendor conversion, now shows a confirm dialog.
- Fixed another error that could have been happening, dealing with un-rounded money amounts.

### v3.0.5

- Added spanish translations thanks to jsr1976.

### v3.0.4

- Temp fix for some item/bag sorting issues.
- Adjustments to the slash command.
- Updated Chinese and Taiwan translations thanks to networm.

### v3.0.3

- Silly error.

### v3.0.2

- More cataclysm adjustments.

### v3.0.1

- Cataclysm cleanup/changes.

### v3.0

- Cataclysm fixes.

### v2.9.2

- When the chat editbox is open/active, shift-clicking will properly link an item.
- New slash command: "/buyemall toggleconfirm" to toggle the large purchase confirmation window. Option saved per character.

### v2.9.1

- Right-clicking the stack button now decreases the current purchase by one stack.

### v2.9.0

- Fix for printscreen problem.

### v2.8.9

- Quick fix for chatframe error.

### v2.8.8

- No reported issues, TOC bump.

### v2.8.7

- No reported issues, TOC bump.

### v2.8.6

- Replaced the rewritten code with an edited version of Cog's original space calculation code, works as it did in 2.8.4, with better support for profession bags/items.

### v2.8.5

- Rewrote bag space calculation.

### v2.8.4

- Fixed bug with confirmation dialog.

### v2.8.3

- Added more localizations for zhCN and zhTW, thanks to q09q09

### v2.8.2

- Updated for 3.0.2.

### v2.8.1

- Updated for WotLK Beta.

### v2.8

- Cost of Stack or Max purchase now shown in the button’s tooltip instead of changing the money display.
- No longer displays “loaded” message.
- Separated localization files for more flexibility.

### v2.6.3

- Fixed ammo pouch bug.

### v2.6.2

- Added workaround for ammo pouch bug.

### v2.6.1

- Added Korean localization thanks to sayclub.

### v2.6

- Updated for WoW 2.0

### v2.5

- Fixed a bug where the amount you could afford was shown as the amount you could fit and vise versa.
- Stack button now works a bit more intuitively for items which come in preset stacks.
- De-aced.

### v2.2

- Changed behavior of Stack button (see Features).
- Improved efficiency in certain areas.

### v2.1.2

- Fixed a bug that caused an error for people with enchanting or herbalism bags
- Updated Ace2 libs

### v2.1.1

- Updated TOC for patch 1.12
- Updated Ace2 libraries

### v2.1

- Slightly rearranged the buttons to have a bit more space in between.
- Clicking on the Max and Stack buttons will now change the amount in the box instead of immediately bringing up the confirmation window.
- Stack button will now be disabled for items whose stack size is the same as their purchase unit (ammunition, for instance).

### v2.0

- Stack button will now be disabled for items that do not stack.
- Ace2ified. Functionality is the same except for the above change, but behind the scenes it's a whole new beast.

### v1.12.1

- Disabled display of the "Vendor has" line of the Max tooltip if there is no limit.
- Changed coloring of tooltip text.
- French translation courtesy of Layrajha.
- Chinese translation thanks to q09q09.

### v1.12

- Stack and Max buttons display a confirmation regardless of purchase size to alleviate accidental clicks.
- The BuyEmAll frame will not hide until you accept the confirmation or if there is no confirmation.
- Fixed a bug where you could attempt to buy an item a vendor no longer has.
- German translation courtesy of JokerGermany.
- Changed the text on Max and Stack tooltips.
- Corrected a few typos in this readme.

### v1.11.1

- Remembered to turn off debugging mode. :P
- Changed the way the window is rendered such that I don't have to include a texture file.

### v1.11

- Changed cost display for better visual integration with WoW.
- Removed display of maximum purchase from the frame.
- Added "Max" button.
- Max and Stack buttons update the cost display when you mouse over them.
- Added tooltips to the Stack and Max buttons.
- The Stack button is disabled if you cannot buy a stack.

### v1.10

- Added display of total purchase cost.
- Added "Stack" button.
- The confirmation box no longer appears when filling an ammo pouch.
- Fixed bug where default stack for ammo could be more than you could afford.
- Added a line break in the confirmation window to make it easier to read.

### v1.9

- Free space calculation now takes into account special bag types.
- Added quick-fill feature for ammo pouches/quivers.

### v1.8

- The Stack Split frame now shows you the maximum amount you will be able to purchase.
- For preset stack items, the left and right arrows increase or decrease to multiples of the preset - stack size.

### v1.5

- Added support for items that come in preset stacks and items that don't stack at all.
- Limited the maximum you can attempt to buy as described above.

### v1.0

- Initial Release
