# Attribution

## Original Authors

**BuyEmAll** was originally created by **Cogwheel** and later maintained by **Shinisuryu**, both listed as former authors on the addon's [CurseForge project](https://www.curseforge.com/wow/addons/buyemall) (project 2590). The most recent upstream releases (through v4.1.4, January 2026) were published by **kaelon**, the CurseForge project owner, with **Jordy141** named as the author in the addon's TOC metadata.

## Maintainers / Contributors

- **Cogwheel** — original author and creator of BuyEmAll.
- **Shinisuryu** — former author and maintainer.
- **Jordy141** — author credited in the TOC metadata of the upstream releases, including the 4.x versions.
- **kaelon** — CurseForge project owner and publisher of the 4.x releases.
- **KarlitosVII** — French localisation update (credited in upstream v3.5.15).
- The translators of the bundled `localisation/` files, credited through the [CurseForge localisation project](https://legacy.curseforge.com/wow/addons/buyemall/localization).
- **Tharavol** — maintainer of BuyEmAll Continued: WoW 12.x compatibility fixes and ongoing maintenance.
- **Claude** — AI coding assistant used during development to diagnose retail API changes and implement fixes.

## License

The original BuyEmAll is published on CurseForge under the **MIT License**. The upstream archive itself did not include a license file, so this repository adds the standard MIT text, naming the original authors alongside the continuation — see [LICENSE](LICENSE).

## Notes

BuyEmAll Continued starts from the last upstream release, v4.1.4 (CurseForge, 2026-01-24). The upstream source repository (`git.kaelon.dev/kaelon/WoW-BuyEmAll`) and the project's issue tracker were unreachable when this fork started, so the import was taken from the [curseforge-mirror/buyemall](https://github.com/curseforge-mirror/buyemall) archive of the CurseForge file. The first commit in this repository is that release, unmodified.

The display name (the `## Title` shown in the client's AddOns list) is **BuyEmAll Continued**. Nothing else about the addon's identity changed: the shipped folder, the `/buyemall` slash command and the `BEAConfirmToggle` saved variable are all still `BuyEmAll`, so an existing install upgrades in place.

### Related projects

- [EricaPomme/BuyEmAll](https://github.com/EricaPomme/BuyEmAll) — a separate community fork of the same upstream code (v5.0.0, August 2026), also updated for the 12.x API changes. BuyEmAll Continued is developed independently of it.

If you are one of the original authors and would like this attribution corrected, expanded, or removed, please open an issue.
