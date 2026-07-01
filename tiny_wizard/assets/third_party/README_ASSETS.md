# Third-Party Asset Index

This folder stores manually provided local art packs that can be used by chapter-specific room art and tileset manifests. Do not commit the original zip files unless the asset license explicitly allows redistribution.

| Asset pack | Project directory | Original zip | Primary use | Chapter 2 | Chapter 3 | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Top Down Laboratory Tileset - Pixel Art 32x32 by Void Arts | `tiny_wizard/assets/third_party/void_lab_tileset/` | `Lab tileset.zip` | Dark lab floors, walls, borders, doors and base room structure | Yes | Yes | Zip contains no standalone license file. Confirm purchase/download page authorization before publishing the repository. |
| Mars Colony - Greenhouse Module by Maru | `tiny_wizard/assets/third_party/mars_greenhouse/` | `Mars greenhouse tilesets.zip` | Greenhouse glass modules, hydroponic trays, plant culture areas and greenhouse decoration | Yes | No | Original appears to be 16 px based. `tilesets_32x32.png` is generated with nearest-neighbor scaling for 32 px workflows. Zip contains no standalone license file. |
| Sci-Fi Facility Asset Pack | `tiny_wizard/assets/third_party/sci_fi_facility/` | `sci-fi-facility-asset-pack.zip` | Consoles, buttons, doors, computer screens, crates, facility devices and optional placeholders | Optional | Yes | README states CC0; credit to Murphy's Dad is appreciated but not required. |
| Land of Pixels Laboratory Tileset by marceles | `tiny_wizard/assets/third_party/land_of_pixels_lab/` | `tiles_laboratory_LandOfPixels.zip` | Bio-lab details, tubes, green liquids, terminals, pipes, equipment and effects | Yes | Yes | Only `32px/`, `README.txt` and `LICENSE.txt` are imported. License allows commercial use and modification, but not resale. |
| Warped Top-Down Tech Lab / Top Down Lab files by Luis Zuno / Ansimuz | `tiny_wizard/assets/third_party/warped_top_down_lab/` | `top_down_lab_files.zip` | Cryogenic lab floors, walls, corridors and supplemental tech-lab base tiles | No | Yes | Imported `Tileset.png` and `public-license.txt`; previews, Aseprite source and macOS metadata are skipped. |

## Chapter Manifests

- Chapter 2 greenhouse material config: `tiny_wizard/assets/rooms/chapter2_greenhouse/greenhouse_assets.json`
- Chapter 3 cryogenic material config: `tiny_wizard/assets/rooms/chapter3_cryogenic/cryogenic_assets.json`
- Chapter 2 tileset manifest: `tiny_wizard/assets/tilesets/chapter2_greenhouse/tileset_manifest.json`
- Chapter 3 tileset manifest: `tiny_wizard/assets/tilesets/chapter3_cryogenic/tileset_manifest.json`

## Import Rules

- Ignore `__MACOSX/`, `.DS_Store` and `._*` files.
- Do not use preview images as runtime art unless a future design task explicitly chooses them.
- Prefer 32x32 tile workflows. If a 16x16 source is scaled, use nearest-neighbor scaling only.
- Record every external asset in the root `ASSET_CREDITS.md` file in the same update that imports it.
