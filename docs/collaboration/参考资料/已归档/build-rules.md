# 构建规则文档

## 概述

本文档定义了 SpacewareConops 项目的构建规则和最佳实践，确保构建过程的一致性、效率和可靠性。

## 核心构建原则

### 1. Turbo 增量构建

项目采用 **Turbo 增量构建** 作为核心构建策略，充分利用缓存机制提高构建效率。

#### 1.1 增量构建优势

- **缓存复用**: 未修改的包不会重新构建，直接使用缓存结果
- **并行构建**: 多个独立包可以并行构建，提高构建速度
- **依赖感知**: 自动识别包之间的依赖关系，按正确顺序构建
- **智能跳过**: 跳过不需要重新构建的包，节省时间

#### 1.2 Turbo 配置

项目根目录的 `turbo.json` 定义了构建配置：

```json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    }
  }
}
```

### 2. 构建命令规范

#### 2.1 基础构建命令

```bash
# 全量构建（使用 Turbo 缓存）
pnpm build

# 强制全量构建（清除缓存）
pnpm build:all:force

# 增量构建（推荐）
pnpm build:all
```

#### 2.2 分层构建命令

**核心包构建**:

```bash
# 构建核心依赖包
pnpm build:core

# 构建所有 packages
pnpm build:packages

# 增量构建 packages
pnpm build:packages:incremental
```

**应用构建**:

```bash
# 构建所有远程应用
pnpm build:apps

# 增量构建应用
pnpm build:apps:incremental

# 安全模式构建（降低并发）
pnpm build:apps:safe
```

**单包构建**:

```bash
# 构建指定包
pnpm --filter <package-name> build

# 示例：构建 stores 包
pnpm --filter @spaceware/stores build

# 示例：构建对象浏览器应用
pnpm --filter concept-object-browser build
```

#### 2.3 特殊构建命令

```bash
# 监听模式（开发时使用）
pnpm build:watch

# 清理后构建
pnpm build:clean

# 顺序构建（避免并发问题）
pnpm build:all:sequential

# 仅构建 packages
pnpm build:all:packages-only

# 仅构建 apps
pnpm build:all:apps-only
```

### 3. 构建验证流程

#### 3.1 修改代码后的构建验证

每次修改代码后，必须按以下流程验证：

1. **确定影响范围**: 识别修改影响的包或应用
2. **执行构建命令**: 运行对应的构建命令
3. **检查构建输出**: 确认构建成功，无错误和警告
4. **验证产物**: 检查 `dist` 目录是否正确生成
5. **记录结果**: 在文档中记录构建结果

#### 3.2 构建验证示例

**场景 1: 修改了 `@spaceware/stores` 包**

```bash
# 1. 构建该包
pnpm --filter @spaceware/stores build

# 2. 检查输出
# ✅ 构建成功
# ✅ dist 目录已生成
# ✅ 类型声明文件已生成

# 3. 构建依赖该包的其他包（如果需要）
pnpm build:packages:incremental
```

**场景 2: 修改了远程应用 `concept-object-browser`**

```bash
# 1. 构建该应用
pnpm --filter concept-object-browser build

# 2. 检查输出
# ✅ 构建成功
# ✅ dist 目录已生成
# ✅ index.js 和 style.css 已生成

# 3. 如果修改了依赖的包，先构建依赖包
pnpm --filter @spaceware/components-story build
pnpm --filter concept-object-browser build
```

**场景 3: 修改了多个包**

```bash
# 使用增量构建，Turbo 会自动处理依赖关系
pnpm build:all

# 或者使用 Turbo 的 filter 功能
turbo run build --filter='@spaceware/stores' --filter='concept-object-browser'
```

### 4. 构建失败处理

#### 4.1 常见构建错误

**类型错误**:

```bash
# 错误示例
error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'

# 处理步骤
1. 检查类型定义是否正确
2. 修复类型错误
3. 重新构建验证
```

**依赖错误**:

```bash
# 错误示例
error: Cannot find module '@spaceware/stores'

# 处理步骤
1. 检查依赖是否已安装: pnpm install
2. 检查依赖包是否已构建: pnpm --filter @spaceware/stores build
3. 重新构建当前包
```

**缓存问题**:

```bash
# 错误示例
构建输出不符合预期，可能是缓存问题

# 处理步骤
1. 清理 Turbo 缓存: pnpm turbo:cache-clean
2. 清理包的 dist 目录: rimraf packages/*/dist apps/*/dist
3. 重新全量构建: pnpm build:all:force
```

#### 4.2 构建失败记录模板

```markdown
## 构建失败记录

**时间**: 2026-01-14 10:30:00
**包名**: @spaceware/stores
**构建命令**: pnpm --filter @spaceware/stores build

**错误信息**:
```

error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'

```

**原因分析**:
类型定义不匹配，传入了字符串类型但期望数字类型

**解决方案**:
修改参数类型或进行类型转换

**验证结果**:
✅ 修复后构建成功
```

### 5. 构建优化策略

#### 5.1 利用 Turbo 缓存

```bash
# 查看缓存状态
pnpm turbo:cache-status

# 优化缓存
pnpm turbo:cache-optimize

# 清理缓存（仅在必要时）
pnpm turbo:cache-clean
```

#### 5.2 并发控制

```bash
# 默认并发（8个）
pnpm build

# 降低并发（避免资源占用过高）
pnpm build:apps:safe  # 并发数: 2

# 顺序构建（避免并发问题）
pnpm build:all:sequential
```

#### 5.3 选择性构建

```bash
# 只构建修改的包及其依赖
turbo run build --filter='[HEAD^1]'

# 构建指定范围
turbo run build --filter='./packages/*'
turbo run build --filter='./apps/*'
```

### 6. 构建最佳实践

#### 6.1 开发阶段

1. **首次构建**: 使用 `pnpm build:all` 构建所有包
2. **增量开发**: 只构建修改的包 `pnpm --filter <package> build`
3. **监听模式**: 开发时使用 `pnpm build:watch` 自动构建
4. **快速验证**: 使用 `pnpm build:packages:incremental` 快速验证

#### 6.2 提交前检查

```bash
# 1. 构建所有修改的包
pnpm build:all

# 2. 运行类型检查
pnpm type-check

# 3. 运行代码检查
pnpm lint

# 4. 运行格式检查
pnpm format:check
```

#### 6.3 CI/CD 构建

```bash
# 清理环境
pnpm clean

# 安装依赖
pnpm install --frozen-lockfile

# 全量构建
pnpm build:all:force

# 运行测试
pnpm test
```

### 7. 构建性能监控

#### 7.1 构建时间分析

```bash
# 查看构建统计
pnpm build:status

# Turbo 干运行（查看执行计划）
pnpm turbo:dry-run

# 启动时统计
pnpm start:stats
```

#### 7.2 构建产物分析

```bash
# 分析构建产物大小
# 查看 dist 目录大小
du -sh packages/*/dist apps/*/dist

# 使用 rollup-plugin-visualizer 分析包大小
# 构建后会生成 stats.html 文件
```

### 8. 一键启动构建

项目提供了一键构建启动脚本，自动完成环境检查、依赖安装、构建和启动：

```bash
# 一键启动（推荐）
pnpm start

# 查看帮助
pnpm start:help

# 查看统计信息
pnpm start:stats
```

**一键启动流程**:

1. ✅ 检查环境（Node.js、pnpm 版本）
2. ✅ 清理构建缓存
3. ✅ 安装依赖
4. ✅ 增量构建所有包
5. ✅ 启动开发服务器

## 构建规则检查清单

每次构建前检查：

- [ ] 确认修改的包或应用
- [ ] 选择合适的构建命令
- [ ] 检查依赖包是否已构建
- [ ] 执行构建命令
- [ ] 验证构建输出
- [ ] 检查 dist 目录
- [ ] 记录构建结果
- [ ] 处理构建错误（如有）

每次构建后检查：

- [ ] 构建成功无错误
- [ ] 类型检查通过
- [ ] 产物文件完整
- [ ] 依赖包版本正确
- [ ] 文档已更新

## 附录

### A. 常用构建命令速查

| 场景       | 命令                        | 说明                    |
| ---------- | --------------------------- | ----------------------- |
| 首次构建   | `pnpm build:all`            | 全量构建所有包          |
| 增量构建   | `pnpm build`                | 使用 Turbo 缓存增量构建 |
| 单包构建   | `pnpm --filter <pkg> build` | 构建指定包              |
| 核心包构建 | `pnpm build:core`           | 构建核心依赖包          |
| 应用构建   | `pnpm build:apps`           | 构建所有远程应用        |
| 清理构建   | `pnpm build:clean`          | 清理后重新构建          |
| 强制构建   | `pnpm build:all:force`      | 忽略缓存强制构建        |
| 监听构建   | `pnpm build:watch`          | 监听文件变化自动构建    |
| 一键启动   | `pnpm start`                | 自动构建并启动          |

### B. Turbo 缓存机制

Turbo 通过以下方式判断是否需要重新构建：

1. **输入哈希**: 计算源文件、依赖、配置的哈希值
2. **缓存查找**: 在 `.turbo` 目录查找匹配的缓存
3. **缓存命中**: 直接使用缓存结果，跳过构建
4. **缓存未命中**: 执行构建，保存结果到缓存

**缓存位置**: `.turbo/cache/`

**缓存策略**:

- 本地缓存: 存储在项目 `.turbo` 目录
- 远程缓存: 可配置远程缓存服务器（可选）

### C. 构建依赖关系

```
核心包 (packages/typesdeclaration, config-deamon, event-bus, stores, api)
  ↓
组件包 (packages/components-story, icons, world, etc.)
  ↓
业务包 (packages/scenario, spaceworld, etc.)
  ↓
远程应用 (apps/*)
  ↓
主项目 (projects/combat-concepts_management)
```

构建时应遵循依赖顺序，Turbo 会自动处理。

---

**文档版本**: v1.0  
**创建时间**: 2026-01-14  
**更新时间**: 2026-01-14  
**适用项目**: SpacewareConops v3.0.1  
**维护者**: 开发团队
