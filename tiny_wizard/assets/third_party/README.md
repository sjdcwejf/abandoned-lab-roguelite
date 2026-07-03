# 第三方素材目录规范

本目录存放已经完成授权检查、允许进入项目的第三方运行素材。原始付费 zip、未确认授权素材、预览图和临时下载文件不要提交到这里。

## 当前目录

| 目录 | 用途 | 授权状态记录 |
| --- | --- | --- |
| `void_lab_tileset/` | 实验室地板、墙体、门、边框和基础房间结构 | 见根目录 `ASSET_CREDITS.md` |
| `mars_greenhouse/` | 第二章生态温室玻璃墙、水培槽、植物培养区和温室设备 | 见根目录 `ASSET_CREDITS.md` |
| `sci_fi_facility/` | 科幻设施、控制台、按钮、电脑、箱子和补充物件 | 见根目录 `ASSET_CREDITS.md` |
| `land_of_pixels_lab/` | 生化实验室细节、培养管、绿色液体、终端、管道和特效 | 见根目录 `ASSET_CREDITS.md` |
| `warped_top_down_lab/` | 第三章低温封存区实验室底板、墙体和科技走廊 | 见根目录 `ASSET_CREDITS.md` |
| `robot_factory_tileset_pack/` | 第四章外骨骼兵器工厂机械臂、装配线、工业设备和机甲支架 | 见根目录 `ASSET_CREDITS.md`；付费素材，不提交原始 rar |
| `cyberpunk_interiors_16x16/` | 第五章数据中枢服务器柜、控制台、数据终端和科技室内物件 | 见根目录 `ASSET_CREDITS.md`；付费素材，不提交原始 zip |

## 后续候选目录

以下目录用于未来扩充素材时保持分类清晰。只有授权已经确认的素材才能进入这些目录；授权待确认的素材只记录在 `ASSET_IMPORT_PLAN.md`，不要放入正式资源目录。

| 目录 | 计划用途 |
| --- | --- |
| `factory_candidates/` | 第四章外骨骼兵器工厂：机械臂、传送带、工业地板、武器架和工厂设备 |
| `data_core_candidates/` | 第五章数据中枢：服务器机柜、数据线、通讯终端、卫星控制台和黑匣子档案库 |
| `ui_icon_candidates/` | 遗物、武器词条、章节、小地图、任务、档案、商店和刷新装备图标 |
| `vfx_candidates/` | 爆炸、电火花、扫描线、电子故障、源质命中特效和通用战斗反馈 |
| `enemy_candidates/` | 无人机、自动炮台、外骨骼清理兵、Boss 占位图和章节敌人占位素材 |

## 导入规则

1. 先在根目录 `ASSET_IMPORT_PLAN.md` 记录候选素材，确认素材名称、作者、来源、像素尺寸、授权类型和是否可商用。
2. 授权未确认时，不要导入正式目录，也不要把候选素材当作运行资源使用。
3. 原始 zip 尤其是付费素材 zip 不提交到 Git。需要保留时放在本地 `_incoming_assets/`，并保持该目录被忽略。
4. 解压时清理 `__MACOSX/`、`.DS_Store`、`._*` 和纯预览图片。
5. 16x16 素材放大到 32x32 时只能使用 nearest-neighbor，不使用模糊缩放。
6. 导入运行素材时，同一提交必须更新根目录 `ASSET_CREDITS.md`，记录作者、来源、许可证、使用位置和署名要求。
7. 不移动或重命名已经被 Godot 场景、脚本或资源配置引用的目录；如果必须调整路径，需要同步修复所有引用并运行检查。

## 当前项目路径说明

项目是 Godot 项目，运行资源路径以 `res://tiny_wizard/assets/third_party/...` 为准。文档里提到的 `assets/third_party/` 规范在本项目中对应当前目录：`tiny_wizard/assets/third_party/`。
