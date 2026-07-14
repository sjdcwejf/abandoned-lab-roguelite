# 全章节专属门素材引用表

本文件记录 `v0.3.8 - 全章节专属门系统整理｜先凯` 使用的真实素材库来源。  
所有门主体、锁门主体、Boss 门主体和封闭墙主体均来自项目内已导入素材 atlas；程序化层只用于低亮状态、霜边、源质侵蚀等辅助效果。

## v0.3.9 门体返工说明

- 侧向门不再直接拉伸横向门素材，而是旋转素材库门体后嵌入墙体，避免第三章左门变形。
- 门主体按素材原始比例统一缩放；`portal_spritesheet.png` 以 6 帧 `AnimatedSprite2D` 状态灯动画接入真实门体。
- 第三章事件锁门使用 `chapter3_cryo_door_event_locked` + `Rect2(0, 96, 176, 96)` 的完整冷库门主体，锁定状态由琥珀状态灯和锁条表现。
- 未连接方向只绘制 sealed wall：连续墙板、非对称设备面板、管线和封存墙结构；不绘制完整门洞、门缝、门灯或门槛。
- 所有门和 sealed wall 仍使用本表列出的真实素材库 atlas；程序化矩形仅作为轨道、阴影、状态灯、霜边和管线辅助。


## 第一章：标准实验室气密门

| 资源名 | 用途 | 素材路径 | Atlas 区域 |
|---|---|---|---|
| `chapter1_lab_door_normal` | 普通门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 96, 176, 96)` |
| `chapter1_lab_door_combat_locked` | 战斗锁定门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 224, 176, 96)` |
| `chapter1_lab_door_event_locked` | 事件锁定门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(352, 256, 96, 64)` |
| `chapter1_lab_door_supply` | 补给门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 96, 176, 96)` |
| `chapter1_lab_door_boss` | Boss 门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 224, 176, 96)` |
| `chapter1_lab_sealed_wall` | 未连接方向封闭墙 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesWalls.png` | `Rect2(0, 0, 128, 128)` |

## 第二章：生态温室隔离门

| 资源名 | 用途 | 素材路径 | Atlas 区域 |
|---|---|---|---|
| `chapter2_greenhouse_door_normal` | 普通门 | `tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png` | `Rect2(384, 32, 128, 128)` |
| `chapter2_greenhouse_door_combat_locked` | 战斗锁定门 | `tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png` | `Rect2(512, 32, 96, 128)` |
| `chapter2_greenhouse_door_event_locked` | 事件锁定门 | `tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png` | `Rect2(512, 32, 96, 128)` |
| `chapter2_greenhouse_door_supply` | 补给门 | `tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png` | `Rect2(384, 32, 128, 128)` |
| `chapter2_greenhouse_door_boss` | Boss 门 | `tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png` | `Rect2(512, 32, 96, 128)` |
| `chapter2_greenhouse_sealed_wall` | 未连接方向封闭墙 | `tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png` | `Rect2(640, 32, 128, 128)` |

## 第三章：低温封存隔热门

| 资源名 | 用途 | 素材路径 | Atlas 区域 |
|---|---|---|---|
| `chapter3_cryo_door_normal` | 普通门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 96, 176, 96)` |
| `chapter3_cryo_door_combat_locked` | 战斗锁定门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 224, 176, 96)` |
| `chapter3_cryo_door_event_locked` | 事件锁定门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(352, 256, 96, 64)` |
| `chapter3_cryo_door_supply` | 补给门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 96, 176, 96)` |
| `chapter3_cryo_door_boss` | Boss 门 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png` | `Rect2(0, 224, 176, 96)` |
| `chapter3_cryo_sealed_wall` | 未连接方向封闭墙 | `tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesWalls.png` | `Rect2(256, 96, 96, 96)` |

## 第四章：外骨骼工厂重型闸门

| 资源名 | 用途 | 素材路径 | Atlas 区域 |
|---|---|---|---|
| `chapter4_factory_door_normal` | 普通门 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png` | `Rect2(544, 384, 128, 112)` |
| `chapter4_factory_door_combat_locked` | 战斗锁定门 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png` | `Rect2(288, 352, 160, 128)` |
| `chapter4_factory_door_event_locked` | 事件锁定门 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png` | `Rect2(544, 384, 128, 112)` |
| `chapter4_factory_door_supply` | 补给门 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png` | `Rect2(96, 448, 128, 96)` |
| `chapter4_factory_door_boss` | Boss 门 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png` | `Rect2(288, 352, 160, 128)` |
| `chapter4_factory_sealed_wall` | 未连接方向封闭墙 | `tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png` | `Rect2(384, 0, 224, 160)` |

## 第五章：数据中枢高权限电子门

| 资源名 | 用途 | 素材路径 | Atlas 区域 |
|---|---|---|---|
| `chapter5_data_door_normal` | 普通门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(0, 0, 16, 64)` |
| `chapter5_data_door_combat_locked` | 战斗锁定门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(32, 0, 16, 64)` |
| `chapter5_data_door_event_locked` | 事件锁定门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(16, 0, 16, 64)` |
| `chapter5_data_door_supply` | 补给门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(0, 0, 16, 64)` |
| `chapter5_data_door_boss` | Boss 门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(32, 0, 16, 64)` |
| `chapter5_data_sealed_wall` | 未连接方向封闭墙 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_Walls.png` | `Rect2(0, 0, 64, 64)` |

## 最终章：母巢侵蚀核心门

| 资源名 | 用途 | 素材路径 | Atlas 区域 |
|---|---|---|---|
| `final_hive_door_normal` | 普通门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(48, 0, 16, 64)` |
| `final_hive_door_combat_locked` | 战斗锁定门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(32, 0, 16, 64)` |
| `final_hive_door_event_locked` | 事件锁定门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(16, 0, 16, 64)` |
| `final_hive_door_supply` | 补给门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(0, 0, 16, 64)` |
| `final_hive_door_boss` | Boss 门 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png` | `Rect2(32, 0, 16, 64)` |
| `final_hive_sealed_wall` | 未连接方向封闭墙 | `tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_Walls.png` | `Rect2(0, 0, 64, 64)` |

## 状态灯素材

所有章节门的状态灯使用：

| 用途 | 素材路径 | Atlas 区域 |
|---|---|---|
| 门状态灯、锁条辅助纹理 | `tiny_wizard/assets/third_party/sci_fi_facility/portal_spritesheet.png` | `Rect2(0, 0, 16, 16)` |
