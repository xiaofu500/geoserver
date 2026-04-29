---
name: cesiumjs-skills
description: CesiumJS 3D 地球可视化开发技能。涵盖 Camera、Entities、Models、Interactions、Imagery、Terrain、Time Properties 等核心概念。当任务涉及 Cesium 地图开发、3D 模型显示、相机控制、鼠标交互、实体管理、粒子效果时使用此技能。
location: .kiro/skills/cesiumjs-skills-main
---

# CesiumJS 技能

参考 `.kiro/skills/cesiumjs-skills-main/` 中的完整技能文档。

## 核心概念

- **Viewer**: Cesium 地图容器，管理所有场景元素
- **Entity**: 高层 API，用于创建点、线、面、模型等
- **Camera**: 相机控制，飞转、定位、视角切换
- **ScreenSpaceEventHandler**: 鼠标/触摸事件处理

## 常用操作

```typescript
import { Viewer } from "cesium";
import { ScreenSpaceEventHandler, ScreenSpaceEventType } from "cesium";

// 创建 Viewer
const viewer = new Viewer("cesiumContainer");

// 飞转到位置
viewer.camera.flyTo({
  destination: Cartesian3.fromDegrees(lon, lat, height),
  orientation: {
    heading: Cesium.Math.toRadians(0),
    pitch: Cesium.Math.toRadians(-45),
    roll: 0,
  },
});

// 添加 Entity
viewer.entities.add({
  id: "marker-1",
  position: Cartesian3.fromDegrees(116.4, 39.9, 0),
  point: {
    pixelSize: 10,
    color: Color.RED,
  },
});

// 鼠标事件
const handler = new ScreenSpaceEventHandler(viewer.scene.canvas);
handler.setInputAction((movement) => {
  const picked = viewer.scene.pick(movement.position);
}, ScreenSpaceEventType.LEFT_CLICK);
```
