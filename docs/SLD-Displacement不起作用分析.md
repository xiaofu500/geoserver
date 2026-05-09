# GeoServer SLD 品字形交错填充实现方案

## 一、问题分析

### 你的期望效果
```
第一行：  ● ● ● ●  (正常排列，行间距 2x)
第二行：    ● ● ● ●  (向右偏移 0.5 格，向下偏移 1 格)
```

### 原始 SLD 问题
```xml
<se:PolygonSymbolizer>
  <se:Fill>
    <se:GraphicFill>
      <se:Graphic>
        <se:ExternalGraphic>
          <se:OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23e4ffbd"/>
          <se:Format>image/svg+xml</se:Format>
        </se:ExternalGraphic>
        <se:Size>16</se:Size>
      </se:Graphic>
    </se:GraphicFill>
  </se:Fill>
  <se:Displacement>  <!-- ❌ GeoServer 渲染器未实现此功能 -->
    <se:DisplacementX>11</se:DisplacementX>
    <se:DisplacementY>22</se:DisplacementY>
  </se:Displacement>
  <se:VendorOption name="graphic-margin">6 6</se:VendorOption>
</se:PolygonSymbolizer>
```

### Displacement 不起作用的原因

| 问题 | 说明 |
|------|------|
| **se:Displacement** | SE 1.1 规范支持，但 GeoServer **渲染器未实现** |
| **PolygonSymbolizer 级别** | 不支持 Displacement 属性 |
| **Graphic 级别** | SLD 1.0.0 标准中 Graphic 没有 Displacement 属性 |

---

## 二、可行的替代方案

### 方案一：使用 Geometry 转换函数偏移 + 多层叠加（推荐）

原理：
1. 第一层：正常渲染
2. 第二层：通过 `offset` 函数偏移几何坐标

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.1.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:se="http://www.opengis.net/se"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>ceshi</se:Name>
    <UserStyle>
      <se:Name>ceshi_style</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:Name>Base Fill</se:Name>
          <!-- 基础半透明填充 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#e4ffbd</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
            </se:Fill>
          </se:PolygonSymbolizer>
        </se:Rule>
        
        <se:Rule>
          <se:Name>Pattern Row 1</se:Name>
          <!-- 第一层：正常排列 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23e4ffbd"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>16</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:VendorOption name="graphic-margin">16 16</se:VendorOption>
          </se:PolygonSymbolizer>
        </se:Rule>
        
        <se:Rule>
          <se:Name>Pattern Row 2 - Offset</se:Name>
          <!-- 第二层：向右偏移 8px，向下偏移 16px -->
          <se:PolygonSymbolizer>
            <se:Geometry>
              <ogc:Function name="offset">
                <ogc:PropertyName>geom</ogc:PropertyName>
                <ogc:Literal>8</ogc:Literal>
                <ogc:Literal>16</ogc:Literal>
              </ogc:Function>
            </se:Geometry>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23e4ffbd"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>16</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:VendorOption name="graphic-margin">16 16</se:VendorOption>
          </se:PolygonSymbolizer>
        </se:Rule>
        
        <se:Rule>
          <se:Name>Border</se:Name>
          <!-- 边框 -->
          <se:LineSymbolizer>
            <se:Stroke>
              <se:SvgParameter name="stroke">#ffbe5d</se:SvgParameter>
              <se:SvgParameter name="stroke-width">1</se:SvgParameter>
            </se:Stroke>
          </se:LineSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
```

**原理说明**：
- `graphic-margin` 控制图案间距（上下左右各 16px）
- `offset` 函数偏移几何坐标，实现第二层向右 8px、向下 16px 的偏移

---

### 方案二：使用 SLD 1.0 格式 + CSS 参数

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.0.0"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink">
  <NamedLayer>
    <Name>ceshi</Name>
    <UserStyle>
      <Name>ceshi_style</Name>
      <FeatureTypeStyle>
        <Rule>
          <Name>Base Fill</Name>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#e4ffbd</CssParameter>
              <CssParameter name="fill-opacity">0.7</CssParameter>
            </Fill>
          </PolygonSymbolizer>
        </Rule>
        
        <Rule>
          <Name>Pattern Row 1</Name>
          <PolygonSymbolizer>
            <Fill>
              <GraphicFill>
                <Graphic>
                  <ExternalGraphic>
                    <OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23e4ffbd"/>
                    <Format>image/svg+xml</Format>
                  </ExternalGraphic>
                  <Size>16</Size>
                </Graphic>
              </GraphicFill>
            </Fill>
            <VendorOption name="graphic-margin">16 16</VendorOption>
          </PolygonSymbolizer>
        </Rule>
        
        <Rule>
          <Name>Pattern Row 2 - Offset</Name>
          <PolygonSymbolizer>
            <Geometry>
              <ogc:Function name="offset">
                <ogc:PropertyName>geom</ogc:PropertyName>
                <ogc:Literal>8</ogc:Literal>
                <ogc:Literal>16</ogc:Literal>
              </ogc:Function>
            </Geometry>
            <Fill>
              <GraphicFill>
                <Graphic>
                  <ExternalGraphic>
                    <OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23e4ffbd"/>
                    <Format>image/svg+xml</Format>
                  </ExternalGraphic>
                  <Size>16</Size>
                </Graphic>
              </GraphicFill>
            </Fill>
            <VendorOption name="graphic-margin">16 16</VendorOption>
          </PolygonSymbolizer>
        </Rule>
        
        <Rule>
          <Name>Border</Name>
          <LineSymbolizer>
            <Stroke>
              <CssParameter name="stroke">#ffbe5d</CssParameter>
              <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
```

---

### 方案三：创建专用的交错 SVG 图案

修改 `test.svg` 文件本身，在图案中包含交错排列：

```svg
<!-- staggered_pattern.svg - 包含品字形排列 -->
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="48" viewBox="0 0 32 48">
  <!-- 第一行 -->
  <circle cx="8" cy="8" r="6" fill="#e4ffbd"/>
  <circle cx="24" cy="8" r="6" fill="#e4ffbd"/>
  <!-- 第二行（向下偏移16px，向右偏移8px） -->
  <circle cx="16" cy="24" r="6" fill="#e4ffbd"/>
  <circle cx="32" cy="24" r="6" fill="#e4ffbd"/>
  <!-- 第三行 -->
  <circle cx="8" cy="40" r="6" fill="#e4ffbd"/>
  <circle cx="24" cy="40" r="6" fill="#e4ffbd"/>
</svg>
```

然后简化 SLD：
```xml
<se:PolygonSymbolizer>
  <se:Fill>
    <se:GraphicFill>
      <se:Graphic>
        <se:ExternalGraphic>
          <se:OnlineResource xlink:type="simple" xlink:href="staggered_pattern.svg"/>
          <se:Format>image/svg+xml</se:Format>
        </se:ExternalGraphic>
        <se:Size>32</se:Size>
      </se:Graphic>
    </se:GraphicFill>
  </se:Fill>
</se:PolygonSymbolizer>
```

---

## 三、参数调整说明

### 行间距和列间距控制

| 期望效果 | graphic-margin | offset 参数 |
|---------|----------------|-------------|
| 行间距 2x，列间距 1x | `16 8` | X=4, Y=16 |
| 行间距 1x，列间距 2x | `8 16` | X=16, Y=8 |
| 行间距 2x，列间距 2x | `16 16` | X=8, Y=16 |

### 偏移计算公式

```
graphic-margin: 上右下左 (单位：像素)

offset 的 X 值 = 图案宽度 / 2 * (列间距倍数 - 1)
offset 的 Y 值 = 图案高度 / 列间距倍数

示例（图案尺寸 16x16）：
- 期望：行间距 2x，列间距 1x
- graphic-margin: "16 8" (上下 16，左右 8)
- offset: X=8 (16/2*1), Y=16 (16/1)
```

---

## 四、注意事项

1. **GeoServer 版本**：确保使用的是较新版本（2.17+），以获得完整的 VendorOption 支持

2. **Geometry 函数支持**：`offset` 函数可能需要启用 WFS 表达式功能

3. **SVG 缓存**：修改 SVG 后可能需要清除 GeoServer 缓存

4. **性能考虑**：多层叠加会影响渲染性能，建议在大比例尺下使用

5. **测试建议**：先在小区域测试，调整参数后再应用到整个图层

---

## 五、验证方法

在 GeoServer 的 Layer Preview 中查看效果，调整参数直到达到期望的品字形排列。
