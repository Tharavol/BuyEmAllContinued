# Changelog

All notable changes to BuyEmAll Continued are documented in this file. Upstream history up to v4.1.0 is in [Changelog.txt](Changelog.txt).

## [Unreleased]

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
