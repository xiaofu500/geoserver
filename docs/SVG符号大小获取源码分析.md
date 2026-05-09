# GeoTools SVG 符号大小获取源码分析

## 概述

GeoServer 中 SVG 符号的大小获取逻辑主要在 **GeoTools** 库的 `org.geotools.renderer.style.svg` 包中实现，核心类包括：
- `SVGGraphicFactory` - SVG 图形工厂
- `RenderableSVG` - SVG 渲染对象（包含尺寸信息）
- `RenderableSVGCache` - SVG 缓存管理

---

## 1. SVGGraphicFactory 源码分析

### 1.1 类结构

```
SVGGraphicFactory
├── Factory 接口
├── ExternalGraphicFactory 接口
└── GraphicCache 接口
```

### 1.2 支持的格式

```java
private static final Set<String> FORMATS = 
    Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
        "image/svg", 
        "image/svg xml",   // 历史兼容
        "image/svg+xml"    // 标准格式
    )));
```

### 1.3 核心方法 - getIcon()

```java
public Icon getIcon(Feature feature, Expression url, 
                    String format, int size) {
    
    // 1. 从 URL 获取参数
    String urlStr = url.evaluate(feature, String.class);
    Map<String, String> params = getParametersFromUrl(urlStr);
    
    // 2. 获取 RenderableSVG 对象（可能使用缓存）
    RenderableSVG svg = glyphCache.getRenderableSVG(
        feature, url, format);
    
    // 3. 创建 SVGIcon
    return new SVGIcon(svg, size);
}
```

---

## 2. SVGIcon 内部类 - 尺寸计算

### 2.1 尺寸计算逻辑

```java
static class SVGIcon implements Icon {
    private int width;
    private int height;
    
    public SVGIcon(RenderableSVG svg, int size) {
        // 获取 SVG 的原始边界
        Rectangle2D bounds = svg.bounds;
        
        double targetWidth = bounds.getWidth();
        double targetHeight = bounds.getHeight();
        
        if (size > 0) {
            // 计算宽高比
            double shapeAspectRatio = 
                bounds.getHeight() > 0 && bounds.getWidth() > 0 
                    ? bounds.getWidth() / bounds.getHeight() 
                    : 1.0;
            
            // 应用 Size 参数进行缩放
            targetWidth = shapeAspectRatio * size;
            targetHeight = size;
        }
        
        this.width = (int) Math.round(targetWidth);
        this.height = (int) Math.round(targetHeight);
    }
    
    public void paintIcon(Component c, Graphics g, int x, int y) {
        // 绘制 SVG
        svg.paintIcon(g, x, y, width, height);
    }
}
```

### 2.2 尺寸确定规则

| SLD Size 参数 | 行为 | 计算方式 |
|-------------|------|---------|
| **> 0 (如 6)** | 使用指定尺寸 | 按宽高比缩放至指定高度 |
| **≤ 0** | 使用自然尺寸 | 使用 SVG 原始尺寸（bounds） |

---

## 3. RenderableSVG 类结构（推测）

基于代码分析，`RenderableSVG` 类应包含以下属性和方法：

```java
public class RenderableSVG {
    // SVG 文档
    SVGDocument document;
    
    // SVG 边界（关键属性）
    Rectangle2D bounds;
    
    // 样式信息
    Map<String, String> styles;
    
    // 绘制方法
    public abstract void paintIcon(Graphics g, int x, int y, 
                                   int width, int height);
}
```

### 3.1 bounds 属性来源

`bounds` 的计算逻辑应遵循以下优先级：

```
┌─────────────────────────────────────────────┐
│  1. SVG width/height 属性                   │
│  2. SVG viewBox 属性                        │
│  3. SVG 内部元素边界（fallback）             │
│  4. 默认 16x16（SLD 规范默认值）             │
└─────────────────────────────────────────────┘
```

---

## 4. SVG 解析流程

### 4.1 toRenderableSVG() 方法

```java
protected RenderableSVG toRenderableSVG(String svgfile, URL svgUrl) 
    throws SAXException, IOException {
    
    // 1. 获取 XML 解析器
    String parser = XMLResourceDescriptor.getXMLParserClassName();
    SAXSVGDocumentFactory f = new SAXSVGDocumentFactory(parser);
    
    // 2. 使用 Apache Batik 解析 SVG
    Document doc = f.createDocument(svgUri);
    
    // 3. 替换 SVG 参数（如有）
    replaceParameters(doc.getDocumentElement(), parameters);
    
    // 4. 返回 RenderableSVG 实现
    return new RenderableSVGImpl(doc, svgfile);
}
```

### 4.2 参数替换

支持 SVG Parameters 1.0 规范：

```xml
<!-- SVG 中使用 param() 函数 -->
<rect fill="param(color) red" width="100" height="100"/>

<!-- URL 中指定参数 -->
http://example.com/icon.svg?color=%23FF0000
```

---

## 5. viewBox 解析逻辑（推测）

根据 SVG 规范和 GeoTools 实现，viewBox 解析应遵循：

### 5.1 viewBox 属性格式

```xml
<svg viewBox="minX minY width height">
```

### 5.2 尺寸计算公式

```
实际宽度 = (viewBox.width / SVG宽度) × 目标尺寸
实际高度 = (viewBox.height / SVG高度) × 目标尺寸
```

### 5.3 常见情况处理

| SVG 配置 | 宽度 | 高度 |
|---------|------|------|
| 只有 viewBox | viewBox[2] | viewBox[3] |
| 只有 width/height | width 属性 | height 属性 |
| 两者都有 | width 属性 | height 属性 |
| 都没有 | 16（默认值） | 16（默认值） |

---

## 6. 完整调用链

```
用户请求渲染
    ↓
SLD 解析器读取 <Size> 参数
    ↓
SVGGraphicFactory.getIcon(feature, url, format, size)
    ↓
RenderableSVGCache 获取/创建 RenderableSVG
    ↓
SVGIcon 构造函数计算尺寸
    ├─ size > 0: 按宽高比缩放
    └─ size ≤ 0: 使用 SVG 自然尺寸（bounds）
    ↓
paintIcon() 绘制 SVG
```

---

## 7. SLD 示例

```xml
<!-- 使用 SVG 作为多边形填充 -->
<PolygonSymbolizer>
  <Fill>
    <GraphicFill>
      <Graphic>
        <ExternalGraphic>
          <OnlineResource xlink:type="simple" 
            xlink:href="http://example.com/pattern.svg"/>
          <Format>image/svg+xml</Format>
        </ExternalGraphic>
        <!-- 符号大小：6 像素 -->
        <Size>6</Size>
        <!-- 符号间距：12 像素 -->
        <VendorOption name="graphic-margin">12</VendorOption>
      </Graphic>
    </GraphicFill>
  </Fill>
</PolygonSymbolizer>
```

---

## 8. 关键结论

### 8.1 SVG 大小获取优先级

1. **SLD `<Size>` 参数** > **SVG 原始尺寸**
2. 如果 `<Size>` 未指定或 ≤ 0，使用 SVG 的自然尺寸

### 8.2 宽高比保持

无论指定 `<Size>` 为多少，GeoTools **始终保持 SVG 的原始宽高比**。

### 8.3 默认尺寸

如果 SVG 文件没有 width、height 或 viewBox 属性，根据 SLD 规范默认为 **16×16 像素**。

### 8.4 实际像素计算

```
最终显示宽度 = (SVG原始宽度 / SVG原始高度) × 指定Size
最终显示高度 = 指定Size
```

例如：
- SVG 原始尺寸：32×16（宽高比 2:1）
- 指定 Size：6
- 实际显示：12×6

---

## 9. 参考文献

- [OGC SLD 1.1 规范](https://www.ogc.org/standards/sld)
- [GeoTools SVG 插件文档](https://docs.geotools.org/stable/userguide/library/render/svg.html)
- [SVG 1.1 viewBox 规范](https://www.w3.org/TR/SVG11/coords.html#ViewBoxAttribute)
- [SVG Parameters 1.0 规范](https://www.w3.org/TR/2009/WD-SVG-Parameters-20090407/)

---

## 10. 相关文件位置

| 文件 | GeoTools 路径 |
|------|--------------|
| SVGGraphicFactory | `modules/plugin/svg/src/main/java/org/geotools/renderer/style/svg/SVGGraphicFactory.java` |
| RenderableSVG | `modules/plugin/svg/src/main/java/org/geotools/renderer/style/svg/RenderableSVG.java` |
| RenderableSVGCache | `modules/plugin/svg/src/main/java/org/geotools/renderer/style/svg/RenderableSVGCache.java` |
| SVGIcon | SVGGraphicFactory.java 内部类 |

---

*文档生成时间：2026-05-08*
*来源：GeoTools GitHub 仓库 (https://github.com/geotools/geotools)*
