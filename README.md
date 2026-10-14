# BuyEmAll Continued

A World of Warcraft addon that replaces the vendor's shift-click purchase box, making it easy to buy large amounts of an item at once — more than one stack per purchase, with the total cost shown before you buy.

This is a continuation of [BuyEmAll](https://www.curseforge.com/wow/addons/buyemall), whose upstream source and issue tracker are no longer reachable. The shipped folder, slash command and saved settings are still `BuyEmAll` — see [ATTRIBUTION.md](ATTRIBUTION.md) for the history.

## Features

- **Buy more than a stack at once** — shift-click an item at a vendor, type how many you want (say, 80 Silk Thread), and BuyEmAll splits it into as many purchases as needed.
- **See the cost first** — a money display under the amount box updates as you type, showing what the purchase will cost. Items bought with other currencies show those currencies instead.
- **Stack and Max buttons** — **Stack** fills your current partial stack first, then adds a full stack per click (right-click removes one). **Max** enters as much as you can buy.
- **Sensible limits** — the amount is capped by free bag space (counting partial stacks, and specialty bags only for items that fit them), what you can afford, the vendor's remaining stock, and uniqueness. Hover the Max button for the breakdown.
- **Large-purchase confirmation** — buying more than a stack asks you to confirm first. Toggle it with `/buyemall confirm`.

If you can only buy one of an item, shift-click behaves like a normal click. If you can't buy any, it does nothing.

## Installation

1. Download the latest release zip from the [Releases](https://github.com/Tharavol/BuyEmAllContinued/releases) page.
2. Extract the `BuyEmAll` folder into `World of Warcraft/_retail_/Interface/AddOns/`, replacing any existing `BuyEmAll` folder.
3. Restart or reload the game client.

Upgrading from the original BuyEmAll needs no other steps: the folder and settings are the same.

## Usage

1. Open a vendor.
2. Shift-click the item you want.
3. Type an amount, or use **Stack** / **Max**.
4. Click **Okay**, and confirm if asked.

### Slash commands

| Command | Effect |
| --- | --- |
| `/buyemall` | Show usage |
| `/buyemall confirm` | Turn the large-purchase confirmation on or off |

## Reporting issues

Please report bugs and requests on the [issue tracker](https://github.com/Tharavol/BuyEmAllContinued/issues). Include the full Lua error text (with BugSack/BugGrabber if you use them), the vendor and the item.

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Upstream history before this continuation is in [Changelog.txt](Changelog.txt).

## Credits

Originally created by Cogwheel, later maintained by Shinisuryu, Jordy141 and kaelon. See [ATTRIBUTION.md](ATTRIBUTION.md) for full credits and contributor history.

## License

BuyEmAll Continued is licensed under the **MIT License**, matching the license declared on the original addon's [CurseForge page](https://www.curseforge.com/wow/addons/buyemall). The full license text is in [LICENSE](LICENSE).
