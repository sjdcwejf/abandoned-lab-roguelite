# Asset Credits

## v0.1.98 第四/第五章付费素材导入｜先凯

本节记录 2026-07-03 由项目所有者提供购买证明并导入的两套付费素材。当前仓库为私有开发用途；未来如果仓库公开或分发源码包，需要再次确认是否允许公开再分发解压后的 PNG 运行素材。原始 `.zip` / `.rar` 不进入仓库。

| 素材名称 | 作者 | 来源 | 许可证 | 使用位置 | 是否需要署名 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| Cyberpunk / Sci-Fi Interior 16x16 Tileset | BeezeeBox | itch.io；用户已提供本地购买包 `Cyberpunk_Interiors_16x16_V-1.zip` 和购买证明 | 购买授权：可用于个人/商业游戏，可修改；禁止转售、再分发或公开分享原始素材文件；包内未附 standalone license | 第五章“数据中枢”：服务器机柜、控制台、数据终端、黑匣子档案库室内物件 | 页面未强制署名，建议保留作者名 | 项目目录：`tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/`。公开仓库前需确认解压 PNG 是否允许随源码分发。 |
| Giant Mech Factory Pixel Art Tileset Pack | Cute SCKR | itch.io；用户已提供本地购买包 `Robot_Factory_Tileset_Pack.rar` 和购买证明 | 购买授权：可用于个人/商业游戏，可修改；禁止转售、再分发或公开分享原始素材文件；包内未附 standalone license | 第四章“外骨骼兵器工厂”：机械臂、装配线、工业设备、机甲支架、工厂控制台 | 页面未强制署名，建议保留作者名 | 项目目录：`tiny_wizard/assets/third_party/robot_factory_tileset_pack/`。公开仓库前需确认解压 PNG 是否允许随源码分发。 |

## v0.1.86 素材授权审计｜先凯

本节记录当前已经导入项目的 5 个第三方素材库。后续新增素材时，必须同时更新本文档和 `ASSET_IMPORT_PLAN.md`。授权不明确的素材不得被写成“已确认可商用”，也不得提交原始付费 zip。

| 素材名称 | 作者 | 来源 | 许可证 | 使用位置 | 是否需要署名 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| Top Down Laboratory Tileset - Pixel Art 32x32 | Void Arts | 用户已提供本地 zip：`Lab tileset.zip` | 授权待确认（项目内未发现 license 文件） | 第二章、第三章实验室地板、墙体、门、边框和基础房间结构 | 待确认 | 公开仓库发布或继续分发前，必须回查购买页或下载页授权。 |
| Mars Colony - Greenhouse Module | Maru | 用户已提供本地 zip：`Mars greenhouse tilesets.zip` | 授权待确认（项目内未发现 license 文件） | 第二章生态温室玻璃墙、水培槽、植物培养区和温室设备 | 待确认 | 项目内已有 nearest-neighbor 放大的 32x32 版本；授权仍需用户确认。 |
| Land of Pixels Laboratory Tileset | marceles | 用户已提供本地 zip：`tiles_laboratory_LandOfPixels.zip` | 自定义授权：允许商业使用和修改，不允许转售素材包 | 第二章、第三章培养管、绿色液体、终端、管道、实验设备和特效 | 未强制要求，建议署名 | 以素材包内 `LICENSE.txt` 和 `README.txt` 为准。 |
| Sci-Fi Facility Asset Pack | Murphy's Dad | 用户已提供本地 zip：`sci-fi-facility-asset-pack.zip` | CC0 | 第三章、第四章、第五章控制台、按钮、电脑、箱子和科幻设施补充物件 | 否，署名可选 | `README.txt` 写明 CC0，署名 Murphy's Dad 可选。 |
| Warped Top-Down Tech Lab / Top Down Lab files | Luis Zuno / Ansimuz | 用户已提供本地 zip：`top_down_lab_files.zip` | 自定义公开授权：允许个人/商业使用、修改和再分发，署名可选 | 第三章低温封存区实验室地板、墙体、走廊和科技底板 | 否，署名可选 | 以 `public-license.txt` 为准，建议保留作者署名。 |

本次 v0.1.86 没有导入新的运行期素材，没有移动或重命名现有资源路径，只补充素材扩充规划、授权检查字段和第三方素材目录规范。

## Canonical Third-Party Asset Library

The following local asset packs were provided by the project owner and organized under `tiny_wizard/assets/third_party/` on 2026-06-29. The original zip files remain outside the repository and should not be committed unless their licenses explicitly allow redistribution.

| Source package | Author | Local project path | Original zip | Usage | License / usage status |
| --- | --- | --- | --- | --- | --- |
| Top Down Laboratory Tileset - Pixel Art 32x32 | Void Arts | `tiny_wizard/assets/third_party/void_lab_tileset/` | `Lab tileset.zip` | Laboratory floors, walls, doors, borders and base room structure for Chapter 2 and Chapter 3. | No standalone license file was found in the zip. Marked as requiring user confirmation from the purchase/download page before public redistribution. |
| Mars Colony - Greenhouse Module | Maru | `tiny_wizard/assets/third_party/mars_greenhouse/` | `Mars greenhouse tilesets.zip` | Chapter 2 greenhouse glass modules, hydroponic trays, plant culture props and greenhouse equipment. | No standalone license file was found in the zip. Marked as requiring user confirmation from the purchase/download page before public redistribution. |
| Sci-Fi Facility Asset Pack | Murphy's Dad | `tiny_wizard/assets/third_party/sci_fi_facility/` | `sci-fi-facility-asset-pack.zip` | Chapter 3 facility consoles, buttons, computers, crates, portals and sci-fi props. | Included README states CC0; credit is appreciated but not required. |
| Land of Pixels Laboratory Tileset | marceles | `tiny_wizard/assets/third_party/land_of_pixels_lab/` | `tiles_laboratory_LandOfPixels.zip` | Chapter 2 and Chapter 3 bio-lab details, tubes, green liquids, terminals, pipes, devices and effects. | Included LICENSE allows modification and commercial use. Resale of the asset pack is not allowed. |
| Warped Top-Down Tech Lab / Top Down Lab files | Luis Zuno / Ansimuz | `tiny_wizard/assets/third_party/warped_top_down_lab/` | `top_down_lab_files.zip` | Chapter 3 cryogenic lab floor, walls, corridors and supplemental tech-lab tiles. | Included `public-license.txt` allows personal/commercial use, modification and redistribution; credit is appreciated but not required. |

### Canonical Asset Config Files

| Config | Purpose |
| --- | --- |
| `tiny_wizard/assets/rooms/chapter2_greenhouse/greenhouse_assets.json` | Chapter 2 greenhouse material manifest for base tiles, greenhouse props, hazard tiles and bio-lab details. |
| `tiny_wizard/assets/rooms/chapter3_cryogenic/cryogenic_assets.json` | Chapter 3 cryogenic material manifest for lab base tiles, sci-fi props and containment details. |
| `tiny_wizard/assets/tilesets/chapter2_greenhouse/tileset_manifest.json` | Chapter 2 tileset index. |
| `tiny_wizard/assets/tilesets/chapter3_cryogenic/tileset_manifest.json` | Chapter 3 tileset index. |

## Imported In This Update

The following greenhouse assets are original project assets generated by `tools/generate_greenhouse_assets.py`.
They do not embed third-party pixels or downloaded artwork.

| Asset | Usage | License status |
| --- | --- | --- |
| `tiny_wizard/assets/art/greenhouse/greenhouse_floor_overlay.png` | Chapter 2 floor damage, spores, cracks, stains | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/culture_pod.png` | Intact greenhouse culture pod prop | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/broken_culture_pod.png` | Broken culture pod prop | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/vine_clump.png` | Vine barrier and infected wall mass | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/bio_liquid_pool.png` | Green contamination pool / hazard visual | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/pipe_debris.png` | Broken pipe and cable debris | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/glass_shards.png` | Broken glass debris | Project-owned original asset |
| `tiny_wizard/assets/art/greenhouse/wall_vines.png` | Wall and corner vine overlay | Project-owned original asset |

## Chapter 2 Greenhouse Local Tileset Pass

These assets were generated by `tools/build_greenhouse_room_art.py` from local asset packages manually provided by the project owner. No additional network download was used in this pass.

| Generated asset | Room usage | Source material mix |
| --- | --- | --- |
| `tiny_wizard/assets/art/greenhouse/rooms/greenhouse_entry_room.png` | `greenhouse_entry_room` / 温室检疫入口 | Void Arts lab floor/walls + Maru greenhouse trays/plants + Land of Pixels consoles and pipe details |
| `tiny_wizard/assets/art/greenhouse/rooms/spore_contamination_room.png` | `spore_contamination_room` / 虫巢样本间 visual base | Void Arts lab floor/walls + Maru greenhouse trays/plants + Land of Pixels liquid/tube details |
| `tiny_wizard/assets/art/greenhouse/rooms/cultivation_chamber_room.png` | `cultivation_chamber_room` / 孢子培养廊 | Void Arts lab floor/walls + Maru cultivation bays + Land of Pixels consoles/tubes |
| `tiny_wizard/assets/art/greenhouse/rooms/greenhouse_reward_room.png` | `greenhouse_reward_room` / 温室样本库 | Void Arts lab floor/walls + Maru side planters + Land of Pixels terminal details |
| `tiny_wizard/assets/art/greenhouse/rooms/greenhouse_weapon_cache_room.png` | `greenhouse_weapon_cache_room` / 渡鸦温室军械缓存 | Void Arts lab floor/walls + Maru greenhouse racks/plants + Land of Pixels armory console and pipe details |
| `tiny_wizard/assets/art/greenhouse/rooms/greenhouse_boss_antechamber.png` | `greenhouse_boss_antechamber` / 渡鸦温室补给站前室 | Void Arts lab floor/walls + Maru broken culture bays + Land of Pixels tubes/consoles |
| `tiny_wizard/assets/art/greenhouse/rooms/greenhouse_boss_nursery_room.png` | `greenhouse_boss_nursery_room` / 温室守望者培育舱 | Void Arts lab floor/walls + Maru broken culture bays + Land of Pixels tubes/consoles and containment visuals |

### Local Third-Party Source Packages

| Source package | Author | Local project path | License / usage status | Notes |
| --- | --- | --- | --- | --- |
| Mars Colony – Greenhouse Module | Maru | `tiny_wizard/assets/third_party/mars_greenhouse/` | User-provided local package; no standalone license file was present in the zip. Keep purchase/download authorization with the project records before public release. | Used for greenhouse trays, plants, glass/greenhouse modules and small cultivation details. |
| Top Down Laboratory Tileset - Pixel Art 32x32 | Void Arts | `tiny_wizard/assets/third_party/void_lab_tileset/` | User-provided local package; no standalone license file was present in the zip. Keep purchase/download authorization with the project records before public release. | Used as the main dark lab floor/wall/structure basis for Chapter 2 room composites. |
| Land of pixels - Laboratory pixel art tileset Top down | marceles | `tiny_wizard/assets/third_party/land_of_pixels_lab/` | Included `LICENSE.txt`: modification and commercial use are allowed; resale of the asset pack is not allowed. | Used for tubes, consoles, screens, pipes, green liquid and lab equipment details. |

## Imported CC0-Derived Assets

These files are derived from CC0 assets and have been recolored/resized for the Chapter 2 greenhouse room art pass.

| Asset | Source | Author | License | Source page | Usage |
| --- | --- | --- | --- | --- | --- |
| `tiny_wizard/assets/art/greenhouse/cc0_vine_cluster.png` | CC0 Plant Clutter `vines.png` | ZaninDev | CC0 | https://opengameart.org/content/cc0-plant-clutter | Greenhouse vine clusters near culture bays. |
| `tiny_wizard/assets/art/greenhouse/cc0_vine_wall_clump.png` | CC0 Plant Clutter `vines.png` | ZaninDev | CC0 | https://opengameart.org/content/cc0-plant-clutter | Wall and corner vine clumps. |
| `tiny_wizard/assets/art/greenhouse/cc0_hanging_vines_strip.png` | Vines `Vines.png` | surt | CC0 | https://opengameart.org/content/vines | Hanging vines on greenhouse walls. |
| `tiny_wizard/assets/art/greenhouse/cc0_toxic_leak_patch.png` | Toxic Barrel(Drip Animation) | Skorpio | CC0 | https://opengameart.org/content/toxic-barreldrip-animation | Small green contamination leak patches near broken equipment. |

## Commercially Usable External Candidates Reviewed

These sources were checked as safe candidates for future import, but their files were not downloaded or embedded in this update.

| Source | Author | License | Download / source page | Notes |
| --- | --- | --- | --- | --- |
| Kenney Tiny Dungeon | Kenney | Creative Commons CC0 | https://kenney.nl/assets/tiny-dungeon | 16x16 dungeon tiles and props; suitable for prototyping top-down tile grids. |
| Kenney Micro Roguelike | Kenney | Creative Commons CC0 | https://kenney.nl/assets/micro-roguelike | Safe license, but too generic for the current greenhouse art direction. |

## Rejected Or Deferred Sources

- No paid itch.io packs were imported.
- No unclear-license OpenGameArt assets were imported.
- No AI-generated images were imported as final game assets.

When importing future third-party assets, keep the original license file or source URL with the asset and update this file in the same commit.
