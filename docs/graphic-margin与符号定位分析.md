# GeoServer Polygon 填充中 graphic-margin 与符号定位分析

## 一、概述

本文档分析 GeoServer 中 `<se:VendorOption name="graphic-margin">` 的实现原理，以及 Polygon 填充中 SVG 符号的定位机制。

---

## 二、graphic-margin 参数格式

### 2.1 参数语法

```xml
<se:VendorOption name="graphic-margin">top right bottom left</se:VendorOption>
```

### 2.2 参数取值方式

| 格式 | 示例 | 说明 |
|------|------|------|
| **单一值** | `8` | 所有边距统一为 8 像素 |
| **两个值** | `8 16` | 上下为 8，左右为 16 |
| **三个值** | `8 16 8` | 上为 8，右左为 16，下为 8 |
| **四个值** | `8 16 8 16` | 按上、右、下、左顺序指定 |

### 2.3 你代码中的使用

```typescript
// 品字排列：第一层符号（正常排列）
<se:VendorOption name="graphic-margin">12</se:VendorOption>

// 品字排列：第二层符号（偏移排列）
// margin: 上=26, 右=26, 下=26, 左=-2
<se:VendorOption name="graphic-margin">26 26 -2 -2</se:VendorOption>
```

---

## 三、符号定位中心计算

### 3.1 符号定位机制

在 GeoServer/GeoTools 的渲染系统中，符号的定位遵循以下规则：

#### 符号坐标计算公式

```
符号位置 = 网格坐标 + 符号大小/2 + margin偏移

其中：
- 网格坐标：符号在重复填充网格中的位置
- 符号大小/2：符号中心点相对于左上角的偏移
- margin偏移：graphic-margin 指定的边距
```

### 3.2 符号定位流程

```
┌─────────────────────────────────────────────────────────────┐
│                    填充渲染流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 计算符号网格                                              │
│     ┌───┬───┬───┬───┐                                      │
│     │ ● │ ● │ ● │ ● │  符号按 Size + Margin 排列成网格        │
│     ├───┼───┼───┼───┤                                      │
│     │ ● │ ● │ ● │ ● │                                      │
│     └───┴───┴───┴───┘                                      │
│                                                             │
│  2. 应用符号中心定位                                          │
│     ┌───┬───┬───┬───┐                                      │
│     │   │ ● │   │   │  符号中心位于网格交点                   │
│     ├───┼─●─┼───┼─●─┤  ● = 符号中心点                        │
│     │   │   │   │   │                                      │
│     └───┴───┴───┴───┘                                      │
│                                                             │
│  3. 应用 graphic-margin 偏移                                  │
│     ┌───┬───┬───┬───┐                                      │
│     │ ● │   │ ● │   │  margin="12 12 0 0"                   │
│     ├───╲─┼───┼─╱───┤  向右上偏移 12px                        │
│     │   │   │   │   │                                      │
│     └───┴───┴───┴───┘                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 符号尺寸与间距关系

```
┌─────────────────────────────────────────────────────────────┐
│                  符号排列示意图                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    ←── Size ──→                                              │
│    ┌─────────┐                                              │
│    │  符号   │ ←── 符号尺寸 = 6px                            │
│    └─────────┘                                              │
│         │                                                   │
│         │ ←── Margin = 12px                                 │
│         ↓                                                   │
│    ┌─────────┐                                              │
│    │    ●    │ ←── 符号中心点                                │
│    └─────────┘                                              │
│                                                             │
│  网格间距 = Size + Margin = 6 + 12 = 18px                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 四、不同图层的坐标起点

### 4.1 图层坐标系统

GeoServer 中每个 PolygonSymbolizer 层都有独立的坐标系统：

| 层级 | 坐标起点 | 说明 |
|------|----------|------|
| **第一层** | (0, 0) | 左上角为原点 |
| **第二层** | (margin-left, margin-top) | 应用 margin 偏移后的位置 |

### 4.2 多层叠加原理

```xml
<!-- 第一层：正常排列，起点在 (0, 0) -->
<se:PolygonSymbolizer>
  <se:Fill>
    <se:GraphicFill>
      <se:Graphic>
        <se:Size>6</se:Size>
      </se:Graphic>
    </se:GraphicFill>
  </se:Fill>
  <se:VendorOption name="graphic-margin">12</se:VendorOption>
</se:PolygonSymbolizer>

<!-- 第二层：偏移排列，起点在 (margin-left, margin-top) -->
<se:PolygonSymbolizer>
  <se:Fill>
    <se:GraphicFill>
      <se:Graphic>
        <se:Size>6</se:Size>
      </se:Graphic>
    </se:GraphicFill>
  </se:Fill>
  <se:VendorOption name="graphic-margin">26 26 -2 -2</se:VendorOption>
</se:PolygonSymbolizer>
```

### 4.3 坐标偏移计算

```
┌─────────────────────────────────────────────────────────────┐
│                 多层符号坐标偏移示意图                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  第一层 (margin=12):                                        │
│  ┌───┬───┬───┐                                              │
│  │ ● │ ● │ ● │  起点: (0, 0)                                │
│  └───┴───┴───┘                                              │
│                                                             │
│  第二层 (margin=26 26 -2 -2):                                │
│  ┌───┬───┬───┐                                              │
│  │   │ ● │   │  起点: (-2, 26)                               │
│  ├───╲─●─╱───┤  - 左偏移 2px，向上偏移 26px                  │
│  │   │   │   │                                              │
│  └───┴───┴───┘                                              │
│                                                             │
│  叠加效果:                                                  │
│  ┌───┬───┬───┐                                              │
│  │ ● │ ● │ ● │ ← 第一层                                     │
│  ├─╲─┼─●─┼─╱─┤                                              │
│  │   │ ● │   │ ← 第二层（交错在第一层间隙中）                  │
│  └───┴───┴───┘                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 五、品字排列实现原理

### 5.1 排列公式

根据你代码中的注释和实现：

```typescript
// 符号大小: 6, 间距: 12

// 第一层 margin = 间距 = 12
const baseMargin = symbolSpacing  // 12

// 第二层计算：
// - 上/下 margin = 间距×2 + 间距/6 = 26
// - 左/右 margin = -符号大小/3 = -2
const topRightMargin = radius + Math.round(symbolSpacing / 12)  // 26
const bottomLeftMagin = -Math.round(symbolSpacing / 12)  // -2
```

### 5.2 公式推导

```
┌─────────────────────────────────────────────────────────────┐
│                   品字排列公式推导                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  设：                                                        │
│    S = 符号大小 = 6                                        │
│    G = 网格间距 = 符号大小 + 间距 = S + spacing              │
│                                                             │
│  第一层（正常行）：                                          │
│    margin = spacing = 12                                    │
│    符号中心位置: n×G + S/2                                  │
│                                                             │
│  第二层（交错行）：                                          │
│    为了与第一行形成品字交错，需要：                            │
│    - 垂直偏移: 1个完整间距 + 部分偏移                        │
│    - 水平偏移: 半个符号大小                                  │
│                                                             │
│    margin-top = G + spacing/6 = 12 + 12/6 = 14?              │
│    （实际使用 26 = 2×spacing + spacing/6）                   │
│                                                             │
│    margin-left = -S/3 = -6/3 = -2                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 实际效果

```
┌─────────────────────────────────────────────────────────────┐
│                     品字排列效果                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  第一层: ●   ●   ●   ●   ●                                 │
│              ↓ (垂直偏移)                                    │
│              ↓                                              │
│  第二层:    ●   ●   ●   ●   ●                              │
│         ←→                                                   │
│      (水平偏移)                                              │
│                                                             │
│  ● = 符号中心点                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 六、SVG 符号渲染位置计算

### 6.1 SVG 符号定位流程

```
┌─────────────────────────────────────────────────────────────┐
│              SVG 符号渲染位置计算流程                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 读取 SVG 文件                                             │
│     ↓                                                        │
│  2. 获取 SVG 原始尺寸                                         │
│     ↓                                                        │
│  3. 应用 <Size> 参数缩放                                      │
│     ↓                                                        │
│  4. 应用 <AnchorPoint> 定位中心（默认 0.5, 0.5）              │
│     ↓                                                        │
│  5. 应用 <Displacement> 额外偏移（可选）                      │
│     ↓                                                        │
│  6. 应用 <Rotation> 旋转（可选）                             │
│     ↓                                                        │
│  7. 放置到网格指定位置                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 SVG 中心点计算

```javascript
// SVG 符号放置位置计算
function calculateSymbolPosition(gridX, gridY, symbolSize, margin) {
    // 网格起点
    const gridStartX = margin.left;   // 左边距
    const gridStartY = margin.top;    // 上边距
    
    // 网格间距
    const gridSpacing = symbolSize + margin.left + margin.right;
    
    // 符号中心在网格中的位置
    const centerX = gridStartX + gridX * gridSpacing + symbolSize / 2;
    const centerY = gridStartY + gridY * gridSpacing + symbolSize / 2;
    
    return { x: centerX, y: centerY };
}
```

### 6.3 SVG 符号边界框

```
┌─────────────────────────────────────────────────────────────┐
│                 SVG 符号边界框计算                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SVG 符号边界框 = Size × 缩放比例                            │
│                                                             │
│  例如：                                                       │
│    SVG 原始尺寸: 100×100px                                   │
│    Size 参数: 6                                              │
│    缩放比例: 6/100 = 0.06                                    │
│    最终尺寸: 6×6px                                           │
│                                                             │
│  ┌───────────┐                                              │
│  │    ┌─┐    │  外框 = 边界框                                │
│  │    │●│    │  ● = 符号中心点 (anchor)                       │
│  │    └─┘    │  内框 = 实际绘制区域                            │
│  └───────────┘                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 七、完整示例 SLD

### 7.1 品字排列完整 SLD

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0" 
  xmlns="http://www.opengis.net/sld" 
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:se="http://www.opengis.net/se"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  
  <NamedLayer>
    <se:Name>quincunx_pattern</se:Name>
    <se:UserStyle>
      <se:Name>quincunx_pattern</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <!-- 1. Polygon 背景填充 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#f0f0f0</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
            </se:Fill>
            <se:Stroke>
              <se:SvgParameter name="stroke">#666666</se:SvgParameter>
              <se:SvgParameter name="stroke-width">1</se:SvgParameter>
            </se:Stroke>
          </se:PolygonSymbolizer>
          
          <!-- 2. 品字排列：第一层符号（正常行） -->
          <!-- margin: 上右下左 = 12 12 12 12 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="test.svg"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>6</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:VendorOption name="graphic-margin">12</se:VendorOption>
          </se:PolygonSymbolizer>
          
          <!-- 3. 品字排列：第二层符号（交错行） -->
          <!-- margin: 上=26, 右=26, 下=26, 左=-2 -->
          <!-- 上下增大以实现垂直偏移，左右负值实现水平交错 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="test.svg"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>6</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:VendorOption name="graphic-margin">26 26 -2 -2</se:VendorOption>
          </se:PolygonSymbolizer>
          
        </se:Rule>
      </se:FeatureTypeStyle>
    </se:UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
```

### 7.2 棋盘格排列（另一种交错方案）

```xml
<!-- 棋盘格排列：第一层（左上角偏移） -->
<se:PolygonSymbolizer>
  <se:Fill>
    <se:GraphicFill>
      <se:Graphic>
        <se:Mark>
          <se:WellKnownName>square</se:WellKnownName>
          <se:Fill>
            <se:SvgParameter name="fill">#000000</se:SvgParameter>
          </se:Fill>
        </se:Mark>
        <se:Size>8</se:Size>
      </se:Graphic>
    </se:GraphicFill>
  </se:Fill>
  <se:VendorOption name="graphic-margin">16 16 0 0</se:VendorOption>
</se:PolygonSymbolizer>

<!-- 棋盘格排列：第二层（右下角偏移） -->
<se:PolygonSymbolizer>
  <se:Fill>
    <se:GraphicFill>
      <se:Graphic>
        <se:Mark>
          <se:WellKnownName>square</se:WellKnownName>
          <se:Fill>
            <se:SvgParameter name="fill">#000000</se:SvgParameter>
          </se:Fill>
        </se:Mark>
        <se:Size>8</se:Size>
      </se:Graphic>
    </se:GraphicFill>
  </se:Fill>
  <se:VendorOption name="graphic-margin">0 0 16 16</se:VendorOption>
</se:PolygonSymbolizer>
```

---

## 八、关键参数总结

### 8.1 graphic-margin 参数表

| 参数 | 说明 | 取值范围 | 默认值 |
|------|------|----------|--------|
| top | 上边距 | 整数（像素） | 0 |
| right | 右边距 | 整数（像素） | 0 |
| bottom | 下边距 | 整数（像素） | 0 |
| left | 左边距 | 整数（像素），可为负数 | 0 |

### 8.2 常用组合

| 效果 | graphic-margin 值 |
|------|------------------|
| 正常排列 | `间距` |
| 向右上偏移 | `间距 间距 0 0` |
| 向左下偏移 | `0 0 间距 间距` |
| 品字偏移 | `26 26 -2 -2` |

### 8.3 符号尺寸与间距比例

| 比例关系 | 说明 |
|----------|------|
| `1:1` | 符号间距等于符号大小 |
| `1:2` | 符号间距是符号大小的2倍 |
| `1:3` | 符号间距是符号大小的3倍 |

---

## 九、注意事项

### 9.1 渲染限制

1. **性能影响**：过多的符号层会增加渲染时间
2. **透明度叠加**：多层符号透明度会叠加
3. **坐标精度**：负数 margin 可能导致符号被裁剪

### 9.2 调试建议

1. 先用单层测试，确认基础排列正确
2. 再添加第二层，检查叠加效果
3. 使用浏览器开发者工具检查网络请求中的 SVG 是否正确加载

### 9.3 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 符号排列不整齐 | margin 值不准确 | 重新计算间距比例 |
| 符号被裁剪 | margin 为负数导致超出边界 | 减小负数值或增大面要素范围 |
| 符号位置偏移 | 不同层使用不同的 Size 值 | 统一所有层的 Size 参数 |
