# 素材库扩充规划

本文档用于记录后续计划引入的第三方素材库候选、授权检查字段和导入目录规范。候选素材不等于已授权素材；只有完成授权核验并记录到 `ASSET_CREDITS.md` 后，才能进入正式资源目录。

## 筛选标准

1. 素材必须适合 top-down 视角，或能够裁剪成 top-down 使用。
2. 像素风格尽量接近当前项目：暗色实验室、低饱和金属、少量高亮警戒色。
3. 优先 16x16、24x24、32x32，或可以用 nearest-neighbor 无模糊缩放到项目尺寸。
4. 优先 CC0、MIT、自定义可商用授权。
5. CC-BY 可以使用，但必须记录作者署名、来源链接和许可证版本。
6. 授权不清楚的素材不得导入正式目录，只能放在本地待确认区或记录为候选。
7. 付费素材不得提交原始 zip；只有确认允许随项目再分发时，才可以提交解压后的运行资源。
8. 不允许导入禁止商业使用的素材。
9. 不允许导入禁止修改的素材，除非只作为未修改引用且明确允许游戏内使用。
10. 不允许把来源不明的 AI 生成素材作为最终资产导入项目。

## 授权检查模板

| 字段 | 填写要求 |
| --- | --- |
| 素材名称 | 使用素材包原始名称，不使用自造简称替代。 |
| 来源平台 | Kenney / OpenGameArt / itch.io / Game-icons.net / GitHub / 其他。 |
| 作者 | 页面标注作者或仓库作者；未知时写“待确认”。 |
| 适合章节 | 第四章、第五章、通用 UI、敌人、特效等。 |
| 素材类型 | tileset、角色、敌人、道具、UI、VFX、音效等。 |
| 像素尺寸 | 原始尺寸，例如 16x16、32x32、混合尺寸。 |
| 授权类型 | CC0、MIT、Apache-2.0、CC-BY 4.0、自定义授权、授权待确认。 |
| 是否可商用 | 是 / 否 / 待确认。 |
| 是否需要署名 | 是 / 否 / 待确认。 |
| 是否允许修改 | 是 / 否 / 待确认。 |
| 是否允许再分发 | 是 / 否 / 待确认。 |
| 是否已导入 | 是 / 否。 |
| 导入目录 | 计划或实际目录，例如 `tiny_wizard/assets/third_party/factory_candidates/`。 |
| 备注 | 购买页面、license 文件、风险、风格匹配度、处理要求。 |

## 当前已导入素材库

| 素材名称 | 来源平台 | 作者 | 适合章节 | 素材类型 | 像素尺寸 | 授权类型 | 是否可商用 | 是否需要署名 | 是否允许修改 | 是否允许再分发 | 是否已导入 | 导入目录 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Top Down Laboratory Tileset - Pixel Art 32x32 | 本地 zip / 购买页待确认 | Void Arts | 第二章、第三章、通用实验室 | 地板、墙体、门、边框、物件 | 32x32 | 授权待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 是 | `tiny_wizard/assets/third_party/void_lab_tileset/` | zip 内未发现 license 文件；公开发布前必须回查购买或下载页面。 |
| Mars Colony - Greenhouse Module | 本地 zip / 购买页待确认 | Maru | 第二章生态温室 | 温室结构、水培槽、植物培养区 | 原始疑似 16x16，项目内有 32x32 放大版 | 授权待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 是 | `tiny_wizard/assets/third_party/mars_greenhouse/` | zip 内未发现 license 文件；`tilesets_32x32.png` 使用 nearest-neighbor 生成。 |
| Land of Pixels Laboratory Tileset | itch.io / 本地 zip | marceles | 第二章、第三章、生化细节 | 培养管、液体、终端、管道、特效 | 16x16、32x32、48x48；项目优先 32x32 | 自定义授权 | 是 | 未要求，建议署名 | 是 | 不允许转售素材包 | 是 | `tiny_wizard/assets/third_party/land_of_pixels_lab/` | `LICENSE.txt` 明确允许商业使用和修改，但不可转售素材包。 |
| Sci-Fi Facility Asset Pack | itch.io / 本地 zip | Murphy's Dad | 第三章、第四章、第五章补充设备 | 控制台、按钮、电脑、箱子、设施物件 | 混合 spritesheet | CC0 | 是 | 否，署名可选 | 是 | 是 | 是 | `tiny_wizard/assets/third_party/sci_fi_facility/` | `README.txt` 写明 CC0，署名 Murphy's Dad 可选。 |
| Warped Top-Down Tech Lab / Top Down Lab files | itch.io / 本地 zip | Luis Zuno / Ansimuz | 第三章低温封存区 | 实验室地板、墙体、走廊、科技底板 | 未统一标注，按 tileset 使用 | 自定义公开授权 | 是 | 否，署名可选 | 是 | 是 | 是 | `tiny_wizard/assets/third_party/warped_top_down_lab/` | `public-license.txt` 允许个人/商业使用、修改和再分发。 |
| Giant Mech Factory Pixel Art Tileset Pack | itch.io / 本地购买包 | Cute SCKR | 第四章外骨骼兵器工厂 | 机械臂、装配线、工业设备、机甲支架、工厂控制台 | 混合像素 spritesheet | 购买授权；禁止素材包再分发 | 是 | 未强制，建议署名 | 是 | 原始素材不得作为素材包再分发 | 是 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/` | 用户已提供购买证明；当前用于私有开发仓库。公开源码前需确认解压 PNG 是否可分发。 |
| Cyberpunk / Sci-Fi Interior 16x16 Tileset | itch.io / 本地购买包 | BeezeeBox | 第五章数据中枢 | 服务器机柜、控制台、数据终端、科技室内物件 | 16x16 | 购买授权；禁止素材包再分发 | 是 | 未强制，建议署名 | 是 | 原始素材不得作为素材包再分发 | 是 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/` | 用户已提供购买证明；当前用于私有开发仓库。公开源码前需确认解压 PNG 是否可分发。 |

## 第四章：外骨骼兵器工厂素材缺口

| 素材名称 | 来源平台 | 作者 | 适合章节 | 素材类型 | 像素尺寸 | 授权类型 | 是否可商用 | 是否需要署名 | 是否允许修改 | 是否允许再分发 | 是否已导入 | 导入目录 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 待选：机械臂与装配线 tileset | itch.io / OpenGameArt / GitHub | 待确认 | 第四章 | 机械臂、传送带、工业设备 | 优先 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/factory_candidates/` | 第一优先级；决定第四章房间辨识度。 |
| 待选：工业金属地板与警戒线 | Kenney / itch.io / OpenGameArt | 待确认 | 第四章 | 地板、墙体、警戒条、重型门 | 16x16 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/factory_candidates/` | 可与现有实验室地板混合，避免全章仍像普通实验室。 |
| 待选：武器架与机甲仓库物件 | itch.io / OpenGameArt | 待确认 | 第四章 | 武器架、机甲仓、弹药箱、维修台 | 优先 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/factory_candidates/` | 武器路线章节的核心视觉符号。 |
| 待选：无人机与自动炮台 | itch.io / OpenGameArt / GitHub | 待确认 | 第四章 | 敌人、炮台、飞行器 | 24x24 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/enemy_candidates/` | 后续不重写敌人系统时可先作为占位 sprite。 |
| 待选：外骨骼清理兵 | itch.io / OpenGameArt | 待确认 | 第四章 | 敌人角色、精英怪 | 32x32 或 48x48 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/enemy_candidates/` | 中优先级；先满足炮台和装配线。 |
| 待选：重装清理机 Boss 占位图 | itch.io / OpenGameArt | 待确认 | 第四章 | Boss sprite、机械装甲 | 64x64 以上 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/enemy_candidates/` | 需要风格统一，不使用写实或高精度插画。 |
| 待选：爆炸与电火花特效 | OpenGameArt / itch.io | 待确认 | 第四章、通用 VFX | 爆炸、电火花、电弧、烟雾 | 32x32 spritesheet | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/vfx_candidates/` | 适合武器词条、工厂陷阱和 Boss 预警。 |
| 待选：工厂 UI 图标 | Game-icons.net / Kenney | 待确认 | 第四章、通用 UI | 工厂、武器、刷新、弹药图标 | SVG 或 16x16/32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | Game-icons.net 常需署名，导入前逐项记录。 |

## 第五章：数据中枢素材缺口

| 素材名称 | 来源平台 | 作者 | 适合章节 | 素材类型 | 像素尺寸 | 授权类型 | 是否可商用 | 是否需要署名 | 是否允许修改 | 是否允许再分发 | 是否已导入 | 导入目录 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 待选：服务器机柜 tileset | itch.io / OpenGameArt | 待确认 | 第五章 | 服务器机柜、机房地板、机架 | 优先 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/data_core_candidates/` | 第一优先级；替换当前程序化数据中枢覆盖层。 |
| 待选：数据线与通讯终端 | itch.io / OpenGameArt / GitHub | 待确认 | 第五章 | 数据线、终端、通讯塔控制台 | 16x16 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/data_core_candidates/` | 用于通讯塔控制室事件目标。 |
| 待选：卫星控制台与黑匣子档案库 | itch.io / OpenGameArt | 待确认 | 第五章 | 控制台、黑匣子、档案柜、警报灯 | 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/data_core_candidates/` | 支撑主线真相和档案阅读玩法。 |
| 待选：数据屏幕与扫描线特效 | OpenGameArt / itch.io | 待确认 | 第五章、通用 VFX | 屏幕、扫描线、电子噪声 | 32x32 spritesheet | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/vfx_candidates/` | 可先服务档案终端和清理协议AI预警。 |
| 待选：清理协议 AI 占位图 | itch.io / OpenGameArt | 待确认 | 第五章 | Boss 核心、AI 核心、无人系统 | 64x64 以上 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/enemy_candidates/` | 只作为占位视觉，不开发完整 Boss 时也需要辨识度。 |
| 待选：电子故障特效 | OpenGameArt / itch.io | 待确认 | 第五章、通用 VFX | 电流、闪烁、故障粒子、火花 | 16x16 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/vfx_candidates/` | 可复用到武器词条“源质充能”。 |
| 待选：档案与隐藏线索图标 | Game-icons.net / Kenney | 待确认 | 第五章、通用 UI | 档案、钥匙、线索、黑匣子图标 | SVG 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | Game-icons.net 候选必须记录署名。 |

## 通用 UI / 系统素材缺口

| 素材名称 | 来源平台 | 作者 | 适合章节 | 素材类型 | 像素尺寸 | 授权类型 | 是否可商用 | 是否需要署名 | 是否允许修改 | 是否允许再分发 | 是否已导入 | 导入目录 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 待选：遗物图标组 | Game-icons.net / itch.io / Kenney | 待确认 | 通用 UI、遗物路线 | 图标 | SVG 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | 需要覆盖防御、速度、感染、能量、召回等标签。 |
| 待选：武器词条图标组 | Game-icons.net / Kenney | 待确认 | 通用 UI、武器路线 | 图标 | SVG 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | 稳定、速射、扩容、精准、源质充能等。 |
| 待选：章节与地图房间图标 | Kenney / Game-icons.net | 待确认 | 小地图、章节 UI | 图标 | 16x16 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | 替代小地图中文单字标记的中长期方案。 |
| 待选：任务提示与档案阅读图标 | Kenney / Game-icons.net | 待确认 | 通用 UI、任务系统 | 图标 | 16x16 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | 用于房间目标、终端、隐藏线索反馈。 |
| 待选：商店与刷新装备图标 | Kenney / Game-icons.net | 待确认 | 渡鸦商店、武器房 | 图标 | 16x16 或 32x32 | 待确认 | 待确认 | 待确认 | 待确认 | 待确认 | 否 | `tiny_wizard/assets/third_party/ui_icon_candidates/` | 优先级高，直接提升商店可读性。 |

## 候选来源记录

| 来源 | 用途倾向 | 授权注意事项 |
| --- | --- | --- |
| Kenney | 通用 UI、占位图标、基础 tileset、简单 VFX | Kenney 常见为 CC0，但必须逐个素材包记录具体页面和许可证。 |
| OpenGameArt | VFX、敌人、像素道具、特殊 tileset | 每个素材包许可证不同，必须逐项检查；禁止导入授权不清楚或非商用素材。 |
| itch.io | 主章节 tileset、敌人、Boss、UI 套装 | 每个作者授权不同，必须检查页面、压缩包内 license 和是否允许再分发。 |
| Game-icons.net | UI 图标、任务图标、状态图标 | 通常需要署名，导入前必须记录作者和许可证；需要转成项目统一尺寸。 |

## 导入流程

1. 在 `ASSET_IMPORT_PLAN.md` 中新增候选条目，保持“是否已导入”为“否”。
2. 下载或购买素材后，先放在本地 `_incoming_assets/`，不要提交原始 zip。
3. 解压检查 license、README、购买页授权和是否允许商业使用。
4. 授权不明确时，只保留计划记录，不导入正式资源目录。
5. 授权确认后，按用途导入 `tiny_wizard/assets/third_party/<category>/` 或章节专属目录。
6. 同步更新 `ASSET_CREDITS.md`，记录作者、来源、许可证、使用位置和署名要求。
7. 如需缩放，使用 nearest-neighbor；保留处理脚本或处理说明。
8. 运行 Godot headless，确认没有资源路径错误。
