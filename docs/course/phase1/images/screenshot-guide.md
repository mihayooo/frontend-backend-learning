# 截图指南

本文档说明课程中所有截图的内容要求和截取步骤。

---

## 第一节：JDK 与 Maven 安装

### 01-jdk-install-01.png - JDK安装向导
**内容**：JDK安装向导界面（.msi安装包）
**截取步骤**：
1. 运行 JDK 安装程序
2. 在安装向导界面按 `Win + Shift + S` 截图
3. 保存为 `01-jdk-install-01.png`

### 01-jdk-install-02.png - 环境变量设置入口
**内容**：系统属性 → 高级 → 环境变量
**截取步骤**：
1. 右键"此电脑" → 属性 → 高级系统设置
2. 点击"环境变量"按钮
3. 截图整个窗口

### 01-jdk-install-03.png - 新建JAVA_HOME变量
**内容**：新建系统变量对话框，变量名JAVA_HOME
**截取步骤**：
1. 在环境变量窗口点击"新建"
2. 输入变量名和变量值
3. 截图对话框

### 01-jdk-install-04.png - 编辑Path变量
**内容**：编辑环境变量窗口，显示%JAVA_HOME%\bin
**截取步骤**：
1. 选中 Path 变量，点击"编辑"
2. 显示已添加的 Java 路径
3. 截图

### 01-jdk-install-05.png - 验证JDK安装
**内容**：CMD窗口显示 `java -version` 命令输出
**截取步骤**：
1. 打开 CMD
2. 输入 `java -version`
3. 截图显示版本信息的界面

### 01-maven-install-01.png - 验证Maven安装
**内容**：CMD窗口显示 `mvn -version` 命令输出
**截取步骤**：
1. 打开 CMD
2. 输入 `mvn -version`
3. 截图显示 Maven 版本信息的界面

### 01-maven-mirror-01.png - 阿里云镜像配置
**内容**：settings.xml文件中mirror配置部分
**截取步骤**：
1. 用 IDEA 或记事本打开 `conf/settings.xml`
2. 定位到 mirrors 部分
3. 截图显示阿里云镜像配置

---

## 第二节：IDEA安装与配置

### 02-idea-install-01.png - IDEA安装选项
**内容**：IDEA安装向导，显示安装选项勾选
**截取步骤**：
1. 运行 IDEA 安装程序
2. 在安装选项界面截图

### 02-idea-config-01.png - 编码格式设置
**内容**：Settings → Editor → File Encodings
**截取步骤**：
1. 打开 IDEA，进入 Settings (Ctrl+Alt+S)
2. 搜索 "File Encodings"
3. 截图显示 UTF-8 配置

### 02-idea-config-02.png - Maven配置
**内容**：Settings → Build → Build Tools → Maven
**截取步骤**：
1. 进入 Settings → Maven
2. 显示 Maven home path 配置
3. 截图

### 02-idea-config-03.png - JDK配置
**内容**：Project Structure → SDKs
**截取步骤**：
1. 按 Ctrl+Alt+Shift+S 打开 Project Structure
2. 选择 SDKs
3. 截图显示已配置的 JDK

### 02-idea-plugin-01.png - Lombok插件安装
**内容**：Settings → Plugins，显示Lombok插件
**截取步骤**：
1. 进入 Settings → Plugins
2. 搜索 "Lombok"
3. 截图显示已安装的 Lombok 插件

---

## 第三节：MySQL安装与配置

### 03-mysql-install-01.png - MySQL安装向导
**内容**：MySQL Installer，选择Server only
**截取步骤**：
1. 运行 MySQL Installer
2. 在选择安装类型界面截图

### 03-mysql-config-01.png - root密码设置
**内容**：MySQL安装过程中的密码设置界面
**截取步骤**：
1. 在安装过程中到达密码设置步骤
2. 截图显示密码输入框

### 03-mysql-cmd-01.png - MySQL登录验证
**内容**：CMD窗口登录MySQL
**截取步骤**：
1. 打开 CMD
2. 输入 `mysql -u root -p`
3. 登录成功后截图

### 03-mysql-cmd-02.png - 查看数据库表
**内容**：MySQL命令行显示SHOW TABLES结果
**截取步骤**：
1. 登录 MySQL
2. 执行 `USE mall_tiny; SHOW TABLES;`
3. 截图显示9张表

---

## 第四节：Redis安装与配置

### 04-redis-cmd-01.png - Redis验证
**内容**：CMD窗口显示redis-cli ping结果
**截取步骤**：
1. 打开 CMD
2. 输入 `redis-cli ping`
3. 截图显示 PONG 响应

---

## 第五节：后端项目启动

### 05-project-structure.png - 项目结构
**内容**：IDEA项目视图显示mall-tiny目录结构
**截取步骤**：
1. 在 IDEA 中打开 mall-tiny 项目
2. 展开项目目录树
3. 截图显示完整结构

### 05-db-config.png - 数据库配置
**内容**：application-dev.yml配置文件
**截取步骤**：
1. 在 IDEA 中打开 `application-dev.yml`
2. 定位到 datasource 配置部分
3. 截图

### 05-start-success.png - 项目启动成功
**内容**：IDEA控制台显示启动成功日志
**截取步骤**：
1. 运行 MallTinyApplication
2. 等待启动完成
3. 截图显示 "Started MallTinyApplication" 日志

### 05-swagger-ui.png - Swagger文档界面
**内容**：浏览器打开Swagger UI页面
**截取步骤**：
1. 启动项目后访问 http://localhost:8080/swagger-ui/
2. 截图显示 Swagger 界面

### 05-swagger-login.png - Swagger登录测试
**内容**：Swagger中测试登录接口
**截取步骤**：
1. 在 Swagger 中找到 /admin/login 接口
2. 点击 Try it out，填入参数
3. 点击 Execute 后截图显示响应结果

---

## 第六节：前端项目部署

### 06-frontend-login.png - 前端登录页面
**内容**：mall-admin-web登录界面
**截取步骤**：
1. 启动前端项目
2. 访问 http://localhost:8090
3. 截图显示登录页面

### 06-frontend-dashboard.png - 后台首页
**内容**：登录后的后台管理界面
**截取步骤**：
1. 使用 admin/macro123 登录
2. 截图显示后台首页

---

## 截图规格要求

- **格式**：PNG
- **分辨率**：建议 1920x1080 或更高
- **文件大小**：单张不超过 500KB
- **命名**：严格按照本文档中的文件名

## 截图工具推荐

- **Windows**：Win + Shift + S (自带截图工具)
- **Snipaste**：免费，支持贴图和标注
- **ShareX**：开源，功能强大
