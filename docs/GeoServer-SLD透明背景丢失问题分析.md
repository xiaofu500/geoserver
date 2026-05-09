# GeoServer SLD 背景透明变不透明问题分析

## 问题描述

上传的 SLD 1.1 中设置了透明背景：
```xml
<se:Fill>
    <se:SvgParameter name="fill">#e4ffbd</se:SvgParameter>
    <se:SvgParameter name="fill-opacity">0</se:SvgParameter>
</se:Fill>
<se:Stroke>
    <se:SvgParameter name="stroke">#ffbe5d</se:SvgParameter>
</se:Stroke>
```

解析后变成：
```xml
<sld:PolygonSymbolizer>
    <sld:Stroke/>  <!-- Fill 完全丢失，Stroke 变空 -->
</sld:PolygonSymbolizer>
```

## 根本原因

### 1. SLD 1.1 → SLD 1.0 版本转换

**`SLDHandler.java` 第 258-268 行：**
```java
void encode10(StyledLayerDescriptor sld, boolean pretty, OutputStream output) throws IOException {
    SLDTransformer tx = new SLDTransformer();  // GeoTools 库中的类
    if (pretty) {
        tx.setIndentation(2);
    }
    try {
        tx.transform(sld, output);  // 总是输出 SLD 1.0 格式
    } catch (TransformerException e) {
        throw (IOException) new IOException("Error writing style").initCause(e);
    }
}
```

### 2. 保存流程

```
上传 SLD 1.1 (se: 命名空间)
    ↓
GeoTools SLDParser 解析
    ↓
转换为内部 Style 对象
    ↓
Styles.sld(style) 包装为 SLD
    ↓
SLDHandler.encode() 调用 SLDTransformer
    ↓
输出 SLD 1.0 (sld: 命名空间)  ← 关键转换点
    ↓
Fill 的 fill-opacity 属性丢失
```

### 3. FeatureInfoStylePreprocessor 干扰

**`FeatureInfoStylePreprocessor.java` 第 91-102 行：**
```java
@Override
public void visit(PolygonSymbolizer poly) {
    super.visit(poly);
    PolygonSymbolizer copy = (PolygonSymbolizer) pages.peek();
    Fill fill = copy.getFill();
    if (fill == null || isStaticTransparentFill(fill)) {
        copy.setFill(sb.createFill());  // 创建不透明黑色填充
    }
    // ...
}

private boolean isStaticTransparentFill(Fill fill) {
    if (fill.getOpacity() instanceof Literal) {
        Double staticOpacity = fill.getOpacity().evaluate(null, Double.class);
        if (staticOpacity == null || staticOpacity == 0) {
            return true;  // fill-opacity=0 被识别为透明并替换
        }
    }
    return false;
}
```

这个预处理器在**要素查询**时使用，会将透明填充替换为不透明填充，但不应该影响样式保存。

## 解决方案

### 方案 1：使用 raw=true 参数上传

```bash
curl -X PUT -H "Content-Type: application/vnd.ogc.se+xml" \
  "http://localhost:8080/geoserver/rest/styles/mystyle?raw=true" \
  --data-binary @mystyle.sld
```

这样 GeoServer 会直接保存原始 SLD 内容，不经过解析和转换。

### 方案 2：使用 SLD 1.0 格式

直接使用 SLD 1.0 格式上传，避免版本转换：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc">
  <NamedLayer>
    <Name>zhjc_xb</Name>
    <UserStyle>
      <Name>zhjc_xb_style</Name>
      <FeatureTypeStyle>
        <Rule>
          <Name>Polygon Fill</Name>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#e4ffbd</CssParameter>
              <CssParameter name="fill-opacity">0</CssParameter>
            </Fill>
            <Stroke>
              <CssParameter name="stroke">#ffbe5d</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
          <!-- 品字排列：第一层符号 -->
          <PolygonSymbolizer>
            <Fill>
              <GraphicFill>
                <Graphic>
                  <ExternalGraphic>
                    <OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23228B22&amp;fill-opacity=1&amp;outline=%23000000&amp;outline-opacity=1"/>
                    <Format>image/svg+xml</Format>
                  </ExternalGraphic>
                  <Size>7.9</Size>
                </Graphic>
              </GraphicFill>
            </Fill>
            <VendorOption name="graphic-margin">12</VendorOption>
          </PolygonSymbolizer>
          <!-- 品字排列：第二层符号 -->
          <PolygonSymbolizer>
            <Fill>
              <GraphicFill>
                <Graphic>
                  <ExternalGraphic>
                    <OnlineResource xlink:type="simple" xlink:href="test.svg?fill=%23228B22&amp;fill-opacity=1&amp;outline=%23000000&amp;outline-opacity=1"/>
                    <Format>image/svg+xml</Format>
                  </ExternalGraphic>
                  <Size>7.9</Size>
                </Graphic>
              </GraphicFill>
            </Fill>
            <VendorOption name="graphic-margin">16.95 16.95 -1 -1</VendorOption>
          </PolygonSymbolizer>
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

### 方案 3：使用 CSS 格式上传

```bash
curl -X PUT -H "Content-Type: application/vnd.ogc.se+css" \
  "http://localhost:8080/geoserver/rest/styles/mystyle?raw=true" \
  --data-binary @mystyle.css
```

CSS 格式示例：
```css
* {
  fill: #e4ffbd;
  fill-opacity: 0;
  stroke: #ffbe5d;
}
[subtype='graphic-fill'] {
  fill: url(#myIcon);
}
```

## 总结

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Fill 丢失 | SLD 1.1 → 1.0 转换时 SLDTransformer 处理问题 | 使用 raw=true 或 SLD 1.0 格式 |
| fill-opacity 丢失 | 同上，GeoTools 库转换问题 | 同上 |
| 数值变化 (7.9→25) | SLDTransformer 单位转换 | 使用 raw=true |
| 数值变化 (12→20) | SLDTransformer margin 规范化 | 使用 raw=true |

**核心问题**：GeoServer 通过 API 保存样式时，会先解析 SLD，再通过 `SLDTransformer` 输出。这个转换过程在 GeoTools 库中实现，会导致：
1. SLD 1.1 转换为 SLD 1.0
2. 某些属性丢失或数值变化
3. SVG ExternalGraphic 的尺寸被重新计算
