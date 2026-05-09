# GeoServer SLD 上传后数值变化问题分析

## 一、问题现象

用户通过 REST API 上传 SLD 1.1 版本后，在 GeoServer 样式编辑器中显示的 SLD 发生了数值变化：

| 参数 | 上传值 | 显示值 | 变化比例 |
|------|--------|--------|----------|
| Size | 7.9 | 25 | ~3.16倍 |
| margin | 12 | 20 | ~1.67倍 |
| margin | 16.95 16.95 -1 -1 | 34.5 34.5 -2 -2 | ~2.03倍 |

## 二、问题根源

### 2.1 GeoServer 只支持 SLD 1.0 存储

从 `SLDHandler.java` 第 112-114 行：

```java
@Override
public boolean supportsEncoding(Version version) {
    return version == null || VERSION_10.equals(version);  // 只支持 1.0 编码！
}
```

**GeoServer 只能将样式保存为 SLD 1.0 版本**。当上传 SLD 1.1 版本时，GeoServer 必须进行版本转换。

### 2.2 SLD 保存流程

```
┌─────────────────────────────────────────────────────────────────┐
│  REST API 上传 SLD 1.1                                           │
│          ↓                                                        │
│  StyleController.stylePut()                                      │
│          ↓                                                        │
│  SLDHandler.parse() 解析 SLD 1.1                                   │
│          ↓                                                        │
│  SLD 1.1 对象模型 (SE 标准)                                        │
│          ↓                                                        │
│  writeStyle() 方法判断条件                                         │
│          ↓                                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 条件满足时：resourcePool.writeStyle() 使用 SLDTransformer   │    │
│  │ 将 SLD 1.1 转换为 SLD 1.0                                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│          ↓                                                        │
│  存储为 SLD 1.0 文件 (.sld)                                       │
│          ↓                                                        │
│  样式编辑器读取时，再次转换回可显示格式                              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 关键代码位置

**文件**: `src/restconfig/src/main/java/org/geoserver/rest/catalog/StyleController.java`

```java
// 第 429 行：解析上传的 SLD
StyledLayerDescriptor sld = handler.parse(content, version, null, entityResolver);

// 第 430 行：写入样式
writeStyle(false, info, sld, rawData, handler, version);

// 第 476-509 行：writeStyle 方法
private void writeStyle(...) {
    // 关键判断：是否使用 SLDTransformer 格式化
    if (!raw 
            && handler instanceof SLDHandler
            && sld.getStyledLayers().length <= 1
            && SLDHandler.VERSION_10.equals(version)) {
        // 使用 SLDTransformer 序列化和格式化
        resourcePool.writeStyle(info, style, true);  // ← 这里可能发生数值转换
    } else {
        // 直接写入原始内容
        writeStyleRaw(info, rawData);
    }
}
```

## 三、数值变化原因分析

### 3.1 可能的原因

**原因 1：单位转换**
- GeoTools 在解析 SVG 外部图形时，可能使用屏幕 DPI 进行单位转换
- 如果 SVG 中的尺寸使用 mm 或其他单位，可能会被转换为像素

**原因 2：GeoTools SLDTransformer 行为**
- `SLDTransformer` 在序列化时可能对数值进行规范化
- 数值可能被四舍五入或重新计算

**原因 3：SVG 尺寸计算**
- GeoTools 解析 SVG 时会读取 `viewBox`、`width`、`height` 属性
- 然后根据这些值计算最终显示尺寸

### 3.2 比例关系分析

| 参数 | 上传值 | 显示值 | 比例 |
|------|--------|--------|------|
| Size | 7.9 | 25 | 3.16 |
| margin | 12 | 20 | 1.67 |
| margin | 16.95 | 34.5 | 2.03 |

**注意**：不同参数的变化比例不同，说明这不是简单的线性缩放，而是涉及多个因素：

1. **SVG 外部图形的解析**：GeoTools 使用 Apache Batik 解析 SVG
2. **尺寸的默认处理**：可能涉及 SVG 的 `viewBox` 和 `naturalSize`
3. **VendorOption 的处理**：margin 参数可能被独立处理

## 四、解决方案

### 4.1 方案一：使用 raw 参数上传

通过 REST API 上传时，使用 `raw=true` 参数可以避免 GeoServer 对 SLD 进行解析和转换：

```bash
curl -X PUT -H "Content-Type: application/vnd.ogc.se+xml" \
  "http://localhost:8080/geoserver/rest/styles/mystyle?raw=true" \
  --data-binary @mystyle.sld
```

这样 GeoServer 会直接保存原始 SLD 内容，不会进行版本转换。

### 4.2 方案二：先上传为 SLD 1.0

在上传前将 SLD 1.1 转换为 SLD 1.0 版本，确保格式一致性。

### 4.3 方案三：检查 SVG 外部图形

如果问题与 SVG 解析有关，检查 SVG 文件的 `viewBox` 和尺寸属性：

```xml
<!-- 明确指定 viewBox 和尺寸 -->
<svg xmlns="http://www.w3.org/2000/svg" 
     viewBox="0 0 16 16" 
     width="16" 
     height="16">
  <!-- 符号内容 -->
</svg>
```

### 4.4 方案四：直接编辑数据库或文件

GeoServer 将 SLD 文件存储在数据目录中：

```
<GEOSERVER_DATA_DIR>/styles/<stylename>.sld
```

可以：
1. 通过 FTP/SSH 直接编辑 SLD 文件
2. 使用数据库管理工具直接修改样式内容

## 五、相关源码文件

| 文件 | 作用 |
|------|------|
| `src/main/src/main/java/org/geoserver/catalog/SLDHandler.java` | SLD 解析和编码 |
| `src/restconfig/src/main/java/org/geoserver/rest/catalog/StyleController.java` | REST API 样式上传 |
| `src/main/src/main/java/org/geoserver/catalog/ResourcePool.java` | 样式文件读写 |
| `src/web/wms/src/main/java/org/geoserver/wms/web/data/StyleEditPage.java` | Web UI 样式编辑 |

## 六、验证方法

1. **检查存储的文件**：查看 `<GEOSERVER_DATA_DIR>/styles/` 目录下的实际文件内容
2. **检查 REST API 返回**：使用 GET 请求获取样式内容，对比上传内容
3. **使用 curl 测试**：

```bash
# 上传时使用 raw 参数
curl -X PUT -H "Content-Type: application/vnd.ogc.se+xml" \
  "http://localhost:8080/geoserver/rest/styles/test_style?raw=true" \
  --data-binary @test.sld

# 获取样式内容
curl -X GET "http://localhost:8080/geoserver/rest/styles/test_style"
```

## 七、结论

GeoServer 在保存 SLD 1.1 样式时会进行版本转换，这个过程中 GeoTools 的 `SLDTransformer` 可能会对数值进行处理，导致最终的 SLD 文件与原始上传文件存在差异。

**推荐解决方案**：使用 `raw=true` 参数上传 SLD，避免 GeoServer 进行解析和转换。
