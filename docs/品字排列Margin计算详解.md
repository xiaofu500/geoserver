# GeoTools 中品字排列问题深入分析

## 一、问题描述

### 用户配置
| 图层 | 符号大小(Size) | Margin | 网格间距 |
|------|---------------|--------|---------|
| 第一层 | 6 | `12 0 0 12` | 18 |
| 第二层 | 6 | `0 24 24 0` | 30 |

### 期望效果
两层符号交错分布，形成品字形状：
```
        ●       ← 第二层
    ●       ●   ← 第一层
        ●       ← 第二层
    ●       ●   ← 第一层
```

---

## 二、核心原理：graphic-margin 与网格计算

### 2.1 符号定位机制

GeoTools 渲染器中，符号的放置遵循以下公式：

```
符号放置位置 = 网格坐标 × 网格间距 + 符号中心偏移
```

**符号中心偏移量 = Size / 2 = 6 / 2 = 3**

### 2.2 网格间距计算

```
网格间距 = Size + margin
```

| 图层 | 计算公式 | 网格间距 |
|------|---------|---------|
| 第一层 | 6 + 12 | **18** |
| 第二层 | 6 + 0 (右) / 6 + 24 (左) | **30** |

### 2.3 符号实际像素位置

```
第一层符号位置 = 网格索引 × 18 + 3
  = {3, 21, 39, 57, 75, 93, 111, ...}

第二层符号位置 = 网格索引 × 30 + 3
  = {3, 33, 63, 93, 123, ...}
```

---

## 三、为什么品字排列无法严格对齐？

### 3.1 问题本质：网格间距不同

```
第一层网格间距: 18
第二层网格间距: 30

问题：18 和 30 的最小公倍数是 90
     在 x=3, 93, 183... 处才会对齐
     但垂直方向永远无法对齐！
```

### 3.2 图示分析

```
X轴坐标:    0    3    6    9   12   15   18   21   24   27   30   33   36   39   42   45   48   51   54   57   60   63   66   69   72   75   78   81   84   87   90   93
           |....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|

第一层:     ●               ●               ●               ●               ●               ●               ●               ●
(间距18)    |←  18 →|←  18 →|←  18 →|←  18 →|←  18 →|←  18 →|←  18 →|←  18 →|←  18 →|
           3              21              39              57              75              93             111             129

第二层:     ●                       ●                       ●                       ●                       ●
(间距30)    |←    30    →|←    30    →|←    30    →|←    30    →|←    30    →|
           3              33              63              93             123             153

对齐点:     ↑                                               ↑                           ↑
           x=3                                            x=93                       x=183
```

### 3.3 品字排列的本质要求

**品字排列需要：**
1. 两层网格间距相等
2. 第二层相对于第一层偏移半个网格间距

```
第一层位置:  n × 间距 + 偏移1
第二层位置:  m × 间距 + 偏移2

品字要求: 偏移2 = 偏移1 + 间距/2
```

---

## 四、解决方案

### 4.1 方案一：统一网格间距 + 半偏移

**关键公式：**
```
第二层 Margin[左] = 间距/2
第二层 Margin[右] = -间距/2
第二层 Margin[上] = 间距/2
第二层 Margin[下] = -间距/2
```

**参数计算：**
```
目标间距: 18 (与第一层相同)
偏移量:   18/2 = 9

第二层 Margin = "9 -9 -9 9"
```

**验证：**
```
第一层: 位置 {3, 21, 39, 57, 75, 93...}
第二层: 位置 {12, 30, 48, 66, 84, 102...}

第二层 - 第一层 = 9 ✓ (始终偏移半个网格)
```

### 4.2 方案二：调整第一层间距

如果第二层需要更大的间距，可以调整第一层的间距：

```
间距 = 30 (与第二层相同)

第一层 Margin[左] = 30/2 = 15
第一层 Margin[右] = 0 (保持)
第一层 Margin[上] = 30/2 = 15
第一层 Margin[下] = 0 (保持)

第一层 Margin = "15 0 0 15"
```

### 4.3 完整 SLD 示例

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0" 
    xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd" 
    xmlns="http://www.opengis.net/sld" 
    xmlns:ogc="http://www.opengis.net/ogc" 
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  
  <NamedLayer>
    <Name>品字排列示例</Name>
    <UserStyle>
      <Title>品字排列符号</Title>
      <FeatureTypeStyle>
        
        <!-- 第一层：基础符号 -->
        <Rule>
          <Name>layer1</Name>
          <PolygonSymbolizer>
            <Geometry>
              <ogc:PropertyName>geometry</ogc:PropertyName>
            </Geometry>
            <Fill>
              <GraphicFill>
                <Graphic>
                  <Mark>
                    <WellKnownName>circle</WellKnownName>
                    <Fill>
                      <CssParameter name="fill">#FF0000</CssParameter>
                    </Fill>
                  </Mark>
                  <Size>6</Size>
                  <VendorOption name="graphic-margin">12 0 0 12</VendorOption>
                </Graphic>
              </GraphicFill>
            </Fill>
          </PolygonSymbolizer>
        </Rule>
        
        <!-- 第二层：品字偏移符号 (修正后) -->
        <Rule>
          <Name>layer2</Name>
          <PolygonSymbolizer>
            <Geometry>
              <ogc:PropertyName>geometry</ogc:PropertyName>
            </Geometry>
            <Fill>
              <GraphicFill>
                <Graphic>
                  <Mark>
                    <WellKnownName>circle</WellKnownName>
                    <Fill>
                      <CssParameter name="fill">#0000FF</CssParameter>
                    </Fill>
                  </Mark>
                  <Size>6</Size>
                  <!-- 修正后的 margin：偏移半个网格间距 -->
                  <VendorOption name="graphic-margin">9 -9 -9 9</VendorOption>
                </Graphic>
              </GraphicFill>
            </Fill>
          </PolygonSymbolizer>
        </Rule>
        
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
```

---

## 五、计算工具函数

### 5.1 计算品字排列的 Margin

```python
def calculate_staggered_margin(size1, margin1, size2, target_margin2=None):
    """
    计算品字排列的第二层 margin
    
    参数:
        size1: 第一层符号大小
        margin1: 第一层 margin (上右下左)
        size2: 第二层符号大小
        target_margin2: 可选，指定第二层的目标 margin
    
    返回:
        修正后的第二层 margin
    """
    # 计算第一层网格间距
    spacing1 = size1 + margin1[3]  # 左边距
    
    # 第二层偏移量 = 间距的一半
    offset = spacing1 / 2
    
    if target_margin2 is None:
        # 自动计算：使第二层间距与第一层相同
        # margin = [上, 右, 下, 左]
        # = [offset, -offset, -offset, offset]
        return [offset, -offset, -offset, offset]
    else:
        # 用户指定了目标 margin，计算需要的偏移
        return target_margin2


# 示例计算
size1 = 6
margin1 = 12  # 第一层 margin[左] = 12
size2 = 6

spacing1 = size1 + margin1  # 18
offset = spacing1 / 2       # 9

# 第二层 margin
margin2 = [offset, -offset, -offset, offset]  # [9, -9, -9, 9]
```

### 5.2 验证函数

```python
def verify_staggered_alignment(size, margin1, margin2):
    """
    验证品字排列是否对齐
    
    返回:
        对齐的像素位置列表
    """
    spacing1 = size + margin1
    spacing2 = size + margin2
    
    # 计算符号中心位置
    center = size / 2
    
    positions1 = []
    positions2 = []
    
    for i in range(10):
        positions1.append(i * spacing1 + center)
        positions2.append(i * spacing2 + center)
    
    # 检查对齐点
    alignment_points = []
    for p1 in positions1:
        for p2 in positions2:
            if abs(p1 - p2) < 0.01:  # 浮点数精度
                alignment_points.append(p1)
    
    return positions1, positions2, alignment_points


# 验证原始配置
p1, p2, align = verify_staggered_alignment(6, 12, 0)
print(f"第一层位置: {p1}")
print(f"第二层位置: {p2}")
print(f"对齐点: {align}")  # 期望: [3, 93, 183...]

# 验证修正后配置
p1, p2, align = verify_staggered_alignment(6, 12, 9)
print(f"第一层位置: {p1}")
print(f"第二层位置: {p2}")
print(f"对齐点: {align}")  # 期望: 每隔一个位置对齐
```

---

## 六、关键结论

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 品字无法对齐 | 两层网格间距不同 (18 vs 30) | 统一间距 |
| 偏移不正确 | margin 偏移方向与网格不对齐 | 使用半间距偏移 |
| 垂直方向错位 | 水平对齐但垂直方向偏移 | 上下左右同时偏移 |

**核心原则：**
1. **间距相等**：品字排列要求两层使用相同的网格间距
2. **半格偏移**：第二层偏移量 = 间距 / 2
3. **四向对称**：上下左右 margin 遵循 `[+d, -d, -d, +d]` 格式

---

## 七、快速参考表

| 第一层 Size | 第一层 Margin | 期望间距 | 第二层 Margin (品字) |
|------------|--------------|---------|---------------------|
| 6 | 12 | 18 | `9 -9 -9 9` |
| 8 | 16 | 24 | `12 -12 -12 12` |
| 10 | 20 | 30 | `15 -15 -15 15` |
| 12 | 24 | 36 | `18 -18 -18 18` |
