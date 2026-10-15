# Changelog

All notable changes to BuyEmAll Continued are documented in this file. Upstream history up to v4.1.0 is in [Changelog.txt](Changelog.txt).

## [Unreleased]

### Fixed
- **Large purchases now stop when you leave the vendor** ([#2](https://github.com/Tharavol/BuyEmAllContinued/issues/2)). A purchase bigger than one stack is bought one stack every half second, and closing the vendor didn't stop it, so opening another vendor within a few seconds could spend the rest of the run on whatever item sat in the same position there. The run now stops when the vendor closes, and before each stack it checks the vendor is still selling the same item. If a run stops early, chat says how many weren't bought.
- **BuyEmAll now loads on game languages it has no translation for** ([#3](https://github.com/Tharavol/BuyEmAllContinued/issues/3)), such as Italian, instead of failing with "attempt to index local 'L' (a nil value)". It uses English there. Translated languages also fall back to English for any text not yet translated, such as the new purchase-stopped message.
- **Items priced in two currencies no longer show a stray "0" as a third cost** ([#4](https://github.com/Tharavol/BuyEmAllContinued/issues/4)).
- **Bundles bought with currencies no longer go past what fits in your bags** ([#5](https://github.com/Tharavol/BuyEmAllContinued/issues/5)). Items sold in bundles for currencies (say, 5 per purchase) are bought in whole bundles, and an amount in between was always rounded up, even when the extra bundle wouldn't fit. It now rounds down to a whole bundle in that case.

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
