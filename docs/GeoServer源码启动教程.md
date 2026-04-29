# GeoServer 3.0.0-SNAPSHOT 源码启动教程

## 一、环境要求

| 工具 | 最低版本 | 推荐版本 | 说明 |
|------|----------|----------|------|
| JDK | 17+ | 17 | GeoServer 3.x 要求 JDK 17 及以上 |
| Maven | 3.6+ | 3.9.x | 构建工具 |
| Git | 2.x | 最新 | 获取源码（可选） |

---

## 二、环境准备

### 2.1 安装 JDK 17

下载并安装 [Eclipse Temurin JDK 17](https://adoptium.net/)，安装后配置环境变量：

```
JAVA_HOME = C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot
Path 中添加 %JAVA_HOME%\bin
```

验证：

```bash
java -version
# openjdk version "17.0.x"
```

### 2.2 安装 Maven

1. 从 [Maven 官网](https://maven.apache.org/download.cgi) 下载二进制包（如 `apache-maven-3.9.15-bin.zip`）
2. 解压到无中文无空格的目录，如 `C:\java\apache-maven-3.9.15`
3. 配置环境变量：

```
MAVEN_HOME = C:\java\apache-maven-3.9.15
Path 中添加 %MAVEN_HOME%\bin
```

4. 验证：

```bash
mvn -version
# Apache Maven 3.9.x
```

> **可选**：配置 Maven 阿里云镜像加速，编辑 `%MAVEN_HOME%\conf\settings.xml`，在 `<mirrors>` 节点下添加：
> ```xml
> <mirror>
>   <id>aliyun</id>
>   <mirrorOf>central</mirrorOf>
>   <url>https://maven.aliyun.com/repository/central</url>
> </mirror>
> ```

---

## 三、获取源码

```bash
git clone https://github.com/geoserver/geoserver.git
cd geoserver
# 主分支为 main，对应 3.0.0-SNAPSHOT
# 也可切换到稳定分支，如：git checkout 2.24.x
```

---

## 四、编译源码

### 4.1 完整编译

在 `src` 目录下执行 Maven 编译：

```bash
cd src
mvn clean install -DskipTests -T 4
```

| 参数 | 说明 |
|------|------|
| `-DskipTests` | 编译测试代码但不运行测试（Jetty 启动需要测试类） |
| `-T 4` | 4 线程并行编译，加快速度 |

> ⚠️ **注意**：
> - 首次编译需下载大量依赖，耗时约 10-30 分钟
> - **不要使用** `-Dmaven.test.skip=true`，该参数会跳过测试代码的编译，导致后续 Jetty 启动失败（缺少 `gs-main-tests.jar` 等依赖）
> - 在 PowerShell 中执行时，`-D` 参数需要用引号包裹：`mvn clean install "-DskipTests" -T 4`

### 4.2 编译结果验证

编译成功后会看到：

```
[INFO] Reactor Summary for GeoServer 3.0.0-SNAPSHOT:
[INFO] GeoServer .......................................... SUCCESS
[INFO] Core Platform Module ............................... SUCCESS
[INFO] ...（所有模块）
[INFO] GeoServer Web Application .......................... SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

---

## 五、启动 GeoServer

提供两种启动方式，任选其一。

### 方式一：命令行 Jetty 启动（推荐快速验证）

```bash
cd src/web/app
mvn jetty:run
```

启动成功后控制台会显示：

```
[INFO] Started ServerConnector@xxx:{HTTP/1.1}{0.0.0.0:8080}
[INFO] Started o.e.j.e.e.WebAppContext@xxx{/geoserver,...}
GeoServer startup complete in Xs
```

**自定义端口**：

```bash
mvn jetty:run "-Djetty.port=9090"
```

**指定数据目录**：

```bash
mvn jetty:run "-DGEOSERVER_DATA_DIR=/path/to/data"
```

**停止服务**：在控制台按 `Ctrl + C`

### 方式二：IDEA 中启动 Start 类（推荐开发调试）

1. 用 IntelliJ IDEA 打开 `src/pom.xml`，选择 **Open as Project**
2. 等待 Maven 依赖同步完成（右下角可查看进度）
3. 配置项目 SDK：`File → Project Structure → Project SDK` 选择 JDK 17
4. 启用注解处理器：`File → Settings → Build, Execution, Deployment → Compiler → Annotation Processors`，勾选 **Enable annotation processing**
5. 定位启动类：在项目结构中找到 `src/web/app/src/test/java/org/geoserver/web/Start.java`
6. 右键 `Start.java` → **Run 'Start.main()'**
7. 如果报错，修改运行配置：
   - **Working directory**：`src/web/app`（相对于项目根目录）
   - **Use classpath of module**：`gs-web-app`
   - **Environment variables**（可选）：`GEOSERVER_DATA_DIR=../../data`
8. 启动成功后控制台显示：`GeoServer startup complete in Xs`

> 💡 **提示**：在 IDEA 的 Run Configuration 中，如果遇到 "Command line is too long" 错误，点击 **Shorten command line** 选项，选择 `JAR manifest` 或 `classpath file` 方式。

---

## 六、访问 GeoServer

启动成功后，在浏览器中访问：

| 项目 | 地址 |
|------|------|
| Web 管理界面 | http://localhost:8080/geoserver |
| 默认用户名 | `admin` |
| 默认密码 | `geoserver` |

---

## 七、常见问题排查

### 7.1 编译失败：`Unknown lifecycle phase ".test.skip=true"`

**原因**：PowerShell 将 `-Dmaven.test.skip=true` 中的 `.test.skip=true` 错误解析为独立参数。

**解决**：用引号包裹参数：

```powershell
mvn clean install "-DskipTests" -T 4
```

### 7.2 Jetty 启动失败：`Could not find artifact org.geoserver:gs-main:jar:tests:3.0.0-SNAPSHOT`

**原因**：使用了 `-Dmaven.test.skip=true` 跳过了测试代码编译，而 Jetty 配置了 `<useTestScope>true</useTestScope>`，需要测试类。

**解决**：改用 `-DskipTests`（仅跳过测试执行，仍会编译测试代码）：

```bash
mvn clean install "-DskipTests" -T 4
```

### 7.3 编译报错：`无法找到符号类 ASTAxisId` 等

**原因**：部分注解处理器生成的代码未正确编译。

**解决**：

```bash
mvn clean install "-DskipTests" -T 4
```

或在 IDEA 中：`Build → Rebuild Project`

### 7.4 端口 8080 被占用

**解决**：指定其他端口启动：

```bash
mvn jetty:run "-Djetty.port=9090"
```

或在 IDEA 的 Start 类运行配置中添加 VM options：

```
-Djetty.port=9090
```

### 7.5 Error Prone 编译错误

**解决**：在 IDEA 的 Maven 工具窗口中，取消勾选 `errorprone` Profile，然后重新加载 Maven 项目。

### 7.6 IDEA 中 "Command line is too long"

**解决**：在 Run Configuration 中，点击 **Shorten command line**，选择 `JAR manifest`。

---

## 八、项目结构说明

```
geoserver-main/
├── src/                          # 源码根目录
│   ├── pom.xml                   # 父 POM（在此目录执行编译）
│   ├── main/                     # 核心模块
│   ├── platform/                 # 平台模块
│   ├── ows/                      # OWS 通用模块
│   ├── wms-core/                 # WMS 核心模块
│   ├── wfs-core/                 # WFS 核心模块
│   ├── wcs/                      # WCS 模块
│   ├── gwc/                      # GeoWebCache 缓存模块
│   ├── security/                 # 安全模块
│   ├── rest/                     # REST API 模块
│   ├── restconfig/               # REST 配置模块
│   ├── extension/                # 扩展模块
│   ├── community/                # 社区模块
│   ├── theme/                    # 主题模块
│   ├── web/                      # Web 界面模块
│   │   ├── core/                 # 核心 UI
│   │   ├── app/                  # ★ Web 应用模块（启动入口）
│   │   │   └── src/test/java/org/geoserver/web/Start.java
│   │   │                         # ★ Jetty 启动类
│   │   └── ...
│   └── ...
├── data/                         # GeoServer 数据目录
│   ├── global.xml                # 全局配置
│   ├── logging.xml               # 日志配置
│   └── ...
├── build/                        # 构建脚本
└── doc/                          # 文档
```

---

## 九、扩展模块启用

GeoServer 的部分功能以 Maven Profile 形式提供，可在编译时启用。

### 9.1 查看可用 Profile

在 `src/web/app/pom.xml` 中查看 `<profiles>` 节点，常见的有：

| Profile | 说明 |
|---------|------|
| `wps` | Web Processing Service |
| `css` | CSS 样式扩展 |
| `imagemosaic-jdbc` | JDBC 影像镶嵌 |
| `feature-pregeneralized` | 预简化要素 |
| `mysql` | MySQL 数据存储 |
| `oracle` | Oracle 数据存储 |
| `sqlserver` | SQL Server 数据存储 |
| `db2` | DB2 数据存储 |
| `gpx` | GPX 数据格式 |
| ... | 更多见 pom.xml |

### 9.2 启用方式

**命令行**：

```bash
mvn clean install "-DskipTests" -T 4 -P wps,css,mysql
```

**IDEA**：在 Maven 工具窗口中勾选对应的 Profile → Reload All Maven Projects → Rebuild Project → Run 'Start'
