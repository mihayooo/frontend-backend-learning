# 第二节：开发环境搭建（下）- IDEA 安装与配置

> **学习目标**：安装并配置 IntelliJ IDEA，为 Spring Boot 项目开发做好准备

---

## 2.1 本节概述

IDEA（IntelliJ IDEA）是目前最流行的 Java IDE，以其强大的代码提示、智能重构和丰富的插件生态著称。

本节将完成：
- IDEA Community 版本下载与安装
- 常用配置（编码、Maven、字体等）
- 必备插件安装
- 第一个 Java 项目验证

**预计学习时间**：25 分钟

---

## 2.2 下载与安装 IDEA

### 2.2.1 版本选择

IDEA 有两个版本：
- **Community（社区版）**：免费，功能足够日常开发
- **Ultimate（旗舰版）**：付费，支持更多框架（如 Spring、Java EE）

**本教程使用 Community 版本**，完全满足 mall-tiny 项目开发需求。

> 💡 **学生福利**：如果你是学生，可以申请免费的教育版（Ultimate 功能）。
> 申请地址：https://www.jetbrains.com/community/education/

### 2.2.2 下载 IDEA

**官方下载地址**：https://www.jetbrains.com/idea/download/

1. 访问下载页面
2. 选择 **IntelliJ IDEA Community Edition**
3. 下载 Windows 版本（`.exe` 安装包）

### 2.2.3 安装 IDEA

**Windows 安装步骤**：

1. 双击下载的 `.exe` 文件
2. 按照向导提示完成安装
3. **安装选项建议**：
   - ✅ 64-bit launcher（64 位启动器）
   - ✅ Add "Open Folder as Project"（右键菜单添加"以项目打开"）
   - ✅ Add to PATH（添加到环境变量）
   - ✅ .java、.groovy、.kt（关联文件类型）

4. **建议安装路径**：`C:\Program Files\JetBrains\IntelliJ IDEA Community Edition`

---

## 2.3 初始配置

首次启动 IDEA 时，会弹出配置向导：

### 2.3.1 导入设置

选择 **Do not import settings**（不导入设置），因为我们这是全新安装。

### 2.3.2 选择主题

根据个人喜好选择：
- **Darcula**：深色主题（推荐，护眼）
- **Light**：浅色主题

### 2.3.3 插件选择

暂时跳过，我们稍后手动安装需要的插件。

---

## 2.4 必要配置

安装完成后，我们需要进行一些必要的配置。

### 2.4.1 打开设置界面

点击菜单：**File → Settings**（或者按 `Ctrl + Alt + S`）

### 2.4.2 配置编码格式

统一使用 UTF-8 编码，避免中文乱码问题：

1. 搜索 **File Encodings**
2. 设置以下选项：
   - Global Encoding: **UTF-8**
   - Project Encoding: **UTF-8**
   - Default encoding for properties files: **UTF-8**
   - ✅ Transparent native-to-ascii conversion

### 2.4.3 配置 Maven

确保 IDEA 使用我们刚才安装的 Maven：

1. 搜索 **Maven**
2. 配置以下选项：
   - Maven home path: `C:/apache-maven-3.9.x`（你的 Maven 安装路径）
   - User settings file: `C:/apache-maven-3.9.x/conf/settings.xml`
   - Local repository: 自动识别或使用自定义路径

### 2.4.4 配置 JDK

1. 搜索 **Project Structure**（或者按 `Ctrl + Alt + Shift + S`）
2. 点击 **SDKs** → **+** → **Add JDK**
3. 选择 JDK 安装路径：`C:\Program Files\Eclipse Adoptium\jdk-8uXXX-hotspot`

### 2.4.5 配置字体和外观（可选）

1. 搜索 **Font**
2. 推荐设置：
   - Font: JetBrains Mono 或 Consolas
   - Size: 14-16（根据个人视力调整）
   - Line spacing: 1.2

---

## 2.5 安装必备插件

### 2.5.1 打开插件市场

点击菜单：**File → Settings → Plugins**

### 2.5.2 推荐插件列表

| 插件名称 | 功能说明 | 是否必需 |
|---------|---------|---------|
| **Chinese (Simplified) Language Pack** | 中文语言包 | 可选 |
| **Lombok** | 支持 Lombok 注解 | ✅ 必需 |
| **Maven Helper** | Maven 依赖分析工具 | 推荐 |
| **Rainbow Brackets** | 彩虹括号，增强代码可读性 | 可选 |
| **Key Promoter X** | 快捷键提示 | 推荐 |
| **.env files support** | 支持 .env 文件 | 可选 |

### 2.5.3 安装 Lombok 插件（重要）

mall-tiny 项目使用了 Lombok 简化代码，必须安装此插件：

1. 在插件市场搜索 **Lombok**
2. 点击 **Install**
3. 重启 IDEA

---

## 2.6 验证环境

创建一个简单的 Java 项目，验证环境是否正常。

### 2.6.1 创建新项目

1. 点击 **New Project**
2. 选择 **Maven Archetype**
3. Archetype 选择：`org.apache.maven.archetypes:maven-archetype-quickstart`
4. 填写项目信息：
   - Name: `hello-java`
   - Location: 选择你的工作目录
   - GroupId: `com.example`
   - ArtifactId: `hello-java`

### 2.6.2 编写测试代码

修改 `src/main/java/com/example/App.java`：

```java
package com.example;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello, mall-tiny!");
        System.out.println("Java 版本: " + System.getProperty("java.version"));
    }
}
```

### 2.6.3 运行项目

1. 右键点击 `App.java`
2. 选择 **Run 'App.main()'**
3. 查看控制台输出：
   ```
   Hello, mall-tiny!
   Java 版本: 1.8.0_392
   ```

如果能正常输出，说明 IDEA 配置成功！

---

## 2.7 本节小结

完成本节学习后，你应该已经：

✅ 安装了 IntelliJ IDEA Community 版本  
✅ 配置了编码格式（UTF-8）  
✅ 配置了 Maven 和 JDK  
✅ 安装了 Lombok 等必备插件  
✅ 成功运行了第一个 Java 项目  

---

## 2.8 下节预告

**第三节：数据库环境搭建 - MySQL 安装与配置**

我们将安装 MySQL 数据库，导入 mall-tiny 的数据库脚本，包括：
- MySQL 8.0 安装
- 数据库创建与用户配置
- mall_tiny.sql 脚本导入详解

---

## 参考资源

- [IntelliJ IDEA 官方文档](https://www.jetbrains.com/help/idea/)
- [IDEA 快捷键大全](https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf)
- [Lombok 官方文档](https://projectlombok.org/)
