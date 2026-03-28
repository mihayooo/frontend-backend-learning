# 第29节：Jenkins CI/CD 端到端验证

> 目标：完整验证 Jenkins CI/CD 流水线，从代码提交到应用部署的全流程测试。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 20-30 分钟 |
| 前置条件 | 已完成第10-12节 Jenkins 配置 |
| 涉及技术 | 端到端测试、API验证 |

---

## 1. 验证前准备

### 1.1 检查服务状态

确保所有服务都已启动：

```bash
# 查看所有容器状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**预期输出**：
```
NAMES             STATUS                   PORTS
mall-tiny-app     Up ...                   0.0.0.0:8080->8080/tcp
jenkins           Up ...                   0.0.0.0:9090->8080/tcp, 0.0.0.0:50000->50000/tcp
gitea             Up ...                   0.0.0.0:3000->3000/tcp, 0.0.0.0:2222->22/tcp
mall-admin-web    Up ...                   0.0.0.0:80->80/tcp
mall-tiny-redis   Up ... (healthy)         0.0.0.0:6380->6379/tcp
mall-tiny-mysql   Up ... (healthy)         0.0.0.0:3307->3306/tcp
```

### 1.2 访问各服务

| 服务 | URL | 预期结果 |
|------|-----|----------|
| Jenkins | http://localhost:9090 | Jenkins 首页 |
| Gitea | http://localhost:3000 | Gitea 首页 |
| 前端 | http://localhost | 登录页面 |
| 后端 API | http://localhost:8080/swagger-ui/ | Swagger 文档 |

---

## 2. 端到端测试流程

### 2.1 流程图

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  1.修改 │ --> │  2.提交 │ --> │  3.触发 │ --> │  4.构建 │ --> │  5.验证 │
│   代码  │     │   推送  │     │   构建  │     │   部署  │     │   结果  │
└─────────┘     └─────────┘     └─────────┘     └─────────┘     └─────────┘
     │               │               │               │               │
     ▼               ▼               ▼               ▼               ▼
 修改Java文件    git push      Jenkins自动    5阶段完成      API测试通过
                到Gitea       触发Pipeline   状态SUCCESS
```

### 2.2 测试步骤

#### 步骤1：修改代码

```bash
# 进入 mall-tiny 目录
cd mall-tiny

# 创建一个简单的修改（例如在Controller中添加日志）
# 编辑 src/main/java/com/macro/mall/tiny/controller/PmsBrandController.java
```

在 `PmsBrandController.java` 中添加一行日志：

```java
@RestController
@RequestMapping("/brand")
public class PmsBrandController {
    
    private static final Logger LOGGER = LoggerFactory.getLogger(PmsBrandController.class);
    
    @RequestMapping(value = "/listAll", method = RequestMethod.GET)
    @ResponseBody
    public CommonResult<List<PmsBrand>> getBrandList() {
        // 添加这行日志用于验证部署
        LOGGER.info("=== CI/CD Test: Brand list requested at {} ===", new Date());
        return CommonResult.success(brandService.listAllBrand());
    }
}
```

#### 步骤2：提交并推送代码

```bash
# 添加修改
git add .

# 提交
git commit -m "test: CI/CD pipeline verification - add test log"

# 推送到 Gitea
git push gitea master
```

**预期输出**：
```
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 8 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (5/5), 456 bytes | 456.00 KiB/s, done.
Total 5 (delta 4), reused 0 (delta 0)
To http://localhost:3000/gitadmin/mall-tiny.git
   a1b2c3d..e4f5g6h  master -> master
```

#### 步骤3：观察 Jenkins 构建

访问 http://localhost:9090/job/mall-tiny-pipeline/

**预期行为**：
1. 代码推送后，Jenkins 自动检测到变更
2. Pipeline 开始执行（页面显示"正在执行#X"）
3. 依次经过 5 个阶段：
   - Checkout（蓝色）
   - Build（蓝色）
   - Docker Build（蓝色）
   - Deploy（蓝色）
   - Health Check（蓝色）

**预期输出**：
```
Started by an SCM change
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/mall-tiny-pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] git
...git clone 输出...
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build)
...Maven 编译输出...
[INFO] BUILD SUCCESS
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Docker Build)
...Docker 构建输出...
Successfully built a1b2c3d4e5f6
Successfully tagged mall-tiny:2
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Deploy)
...部署输出...
✅ Deploy OK: mall-tiny-app started
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Health Check)
Health check 1/20 -> HTTP 000
Health check 2/20 -> HTTP 000
...
Health check 8/20 -> HTTP 200
✅ Health: {"status":"UP"}
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Declarative: Post Actions)
[Pipeline] echo
🎉 BUILD #2 SUCCESS!
[Pipeline] echo
Swagger: http://localhost:8080/swagger-ui/
[Pipeline] echo
Login: admin / macro123
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

#### 步骤4：验证应用部署

**4.1 检查容器状态**

```bash
docker ps --filter name=mall-tiny-app --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**预期输出**：
```
NAMES           STATUS          PORTS
mall-tiny-app   Up 2 minutes    0.0.0.0:8080->8080/tcp
```

**4.2 健康检查**

```bash
curl -s http://localhost:8080/actuator/health | jq
```

**预期输出**：
```json
{
  "status": "UP"
}
```

**4.3 登录接口测试**

```bash
# 获取 JWT Token
curl -s -X POST http://localhost:8080/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"macro123"}' | jq
```

**预期输出**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "token": "eyJhbGciOiJIUzUxMiJ9...",
    "tokenHead": "Bearer "
  }
}
```

**4.4 品牌列表接口测试**

```bash
# 使用获取到的 token 访问品牌列表
curl -s -X GET http://localhost:8080/brand/listAll \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" | jq
```

**预期输出**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "name": "万和",
      "firstLetter": "W",
      ...
    }
  ]
}
```

**4.5 查看日志验证修改**

```bash
# 查看应用日志，确认我们添加的日志输出
docker logs mall-tiny-app --tail 50 | grep "CI/CD Test"
```

**预期输出**：
```
2026-03-29 06:30:15.123  INFO 1 --- [nio-8080-exec-1] c.m.m.t.c.PmsBrandController             : === CI/CD Test: Brand list requested at Sun Mar 29 06:30:15 CST 2026 ===
```

---

## 3. 前端联调验证

### 3.1 登录前端页面

1. 访问 http://localhost
2. 输入账号：`admin`
3. 输入密码：`macro123`
4. 点击登录

**预期结果**：成功进入管理后台首页

### 3.2 测试品牌管理功能

1. 点击左侧菜单"商品" → "品牌管理"
2. 页面显示品牌列表
3. 点击"添加品牌"，填写信息并保存
4. 新品牌成功添加到列表

---

## 4. 完整验证清单

### 4.1 服务状态检查

| 检查项 | 命令/操作 | 预期结果 |
|--------|-----------|----------|
| Jenkins 运行中 | `docker ps` | jenkins Up |
| Gitea 运行中 | `docker ps` | gitea Up |
| 应用运行中 | `docker ps` | mall-tiny-app Up |
| MySQL 运行中 | `docker ps` | mall-tiny-mysql Up (healthy) |
| Redis 运行中 | `docker ps` | mall-tiny-redis Up (healthy) |
| 前端运行中 | `docker ps` | mall-admin-web Up |

### 4.2 网络连通性检查

| 检查项 | 命令 | 预期结果 |
|--------|------|----------|
| Jenkins → Gitea | `docker exec jenkins ping gitea` | 正常响应 |
| 应用 → MySQL | `docker exec mall-tiny-app ping mall-tiny-mysql` | 正常响应 |
| 应用 → Redis | `docker exec mall-tiny-app ping mall-tiny-redis` | 正常响应 |

### 4.3 API 功能检查

| 检查项 | 命令 | 预期结果 |
|--------|------|----------|
| 健康检查 | `curl /actuator/health` | `{"status":"UP"}` |
| 登录接口 | `curl -X POST /admin/login` | 返回 token |
| 品牌列表 | `curl /brand/listAll` | 返回品牌数据 |
| Swagger UI | 浏览器访问 /swagger-ui/ | 显示 API 文档 |

### 4.4 Pipeline 检查

| 检查项 | 操作 | 预期结果 |
|--------|------|----------|
| 自动触发 | git push 后 | Pipeline 自动开始 |
| Checkout | 查看日志 | 成功拉取代码 |
| Build | 查看日志 | Maven BUILD SUCCESS |
| Docker Build | 查看日志 | Successfully tagged |
| Deploy | 查看日志 | Deploy OK |
| Health Check | 查看日志 | HTTP 200, status UP |
| 最终状态 | 查看页面 | SUCCESS（绿色） |

---

## 5. 自动化验证脚本

创建验证脚本 `jenkins/verify-deployment.sh`：

```bash
#!/bin/bash

set -e

echo "=========================================="
echo "Jenkins CI/CD 部署验证脚本"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查服务状态
echo -e "\n[1/5] 检查容器状态..."
if docker ps | grep -q "mall-tiny-app"; then
    echo -e "${GREEN}✓${NC} mall-tiny-app 运行中"
else
    echo -e "${RED}✗${NC} mall-tiny-app 未运行"
    exit 1
fi

# 健康检查
echo -e "\n[2/5] 健康检查..."
HEALTH=$(curl -s http://localhost:8080/actuator/health | grep -o '"status":"UP"' || echo "FAIL")
if [ "$HEALTH" = '"status":"UP"' ]; then
    echo -e "${GREEN}✓${NC} 健康检查通过"
else
    echo -e "${RED}✗${NC} 健康检查失败"
    exit 1
fi

# 登录测试
echo -e "\n[3/5] 登录接口测试..."
LOGIN_RESP=$(curl -s -X POST http://localhost:8080/admin/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"macro123"}')

if echo "$LOGIN_RESP" | grep -q '"code":200'; then
    echo -e "${GREEN}✓${NC} 登录接口正常"
    TOKEN=$(echo "$LOGIN_RESP" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "  Token: ${TOKEN:0:20}..."
else
    echo -e "${RED}✗${NC} 登录接口失败"
    echo "  响应: $LOGIN_RESP"
    exit 1
fi

# 品牌列表测试
echo -e "\n[4/5] 品牌列表接口测试..."
BRAND_RESP=$(curl -s -X GET http://localhost:8080/brand/listAll \
    -H "Authorization: Bearer $TOKEN")

if echo "$BRAND_RESP" | grep -q '"code":200'; then
    echo -e "${GREEN}✓${NC} 品牌列表接口正常"
else
    echo -e "${RED}✗${NC} 品牌列表接口失败"
    exit 1
fi

# 前端访问测试
echo -e "\n[5/5] 前端页面测试..."
FRONT_RESP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

if [ "$FRONT_RESP" = "200" ]; then
    echo -e "${GREEN}✓${NC} 前端页面可访问"
else
    echo -e "${RED}✗${NC} 前端页面访问失败 (HTTP $FRONT_RESP)"
    exit 1
fi

echo -e "\n=========================================="
echo -e "${GREEN}所有验证通过！CI/CD 流水线运行正常。${NC}"
echo "=========================================="
echo ""
echo "访问地址："
echo "  - Jenkins: http://localhost:9090"
echo "  - Gitea:   http://localhost:3000"
echo "  - 前端:    http://localhost"
echo "  - API文档: http://localhost:8080/swagger-ui/"
echo ""
echo "登录账号：admin / macro123"
```

**使用方法**：

```bash
# 添加执行权限
chmod +x jenkins/verify-deployment.sh

# 运行验证
./jenkins/verify-deployment.sh
```

**预期输出**：
```
==========================================
Jenkins CI/CD 部署验证脚本
==========================================

[1/5] 检查容器状态...
✓ mall-tiny-app 运行中

[2/5] 健康检查...
✓ 健康检查通过

[3/5] 登录接口测试...
✓ 登录接口正常
  Token: eyJhbGciOiJIUzUxMiJ9...

[4/5] 品牌列表接口测试...
✓ 品牌列表接口正常

[5/5] 前端页面测试...
✓ 前端页面可访问

==========================================
所有验证通过！CI/CD 流水线运行正常。
==========================================
```

---

## 6. 故障排查速查

如果验证失败，按以下顺序排查：

### 6.1 容器未运行

```bash
# 查看所有容器
docker ps -a

# 查看失败容器日志
docker logs mall-tiny-app

# 重启服务
docker restart mall-tiny-app
```

### 6.2 健康检查失败

```bash
# 检查应用日志
docker logs mall-tiny-app --tail 100

# 常见原因：
# 1. 数据库连接失败 → 检查 MySQL 是否运行
# 2. Redis 连接失败 → 检查 Redis 是否运行
# 3. 端口冲突 → 检查 8080 是否被占用
```

### 6.3 登录失败

```bash
# 检查数据库数据
docker exec -it mall-tiny-mysql mysql -uroot -proot -e "SELECT * FROM mall_tiny.ums_admin;"

# 如果数据为空，重新导入数据
docker exec -i mall-tiny-mysql mysql -uroot -proot < mall-tiny/sql/mall_tiny.sql
```

### 6.4 Pipeline 构建失败

```bash
# 查看 Jenkins 构建日志
# 访问 http://localhost:9090/job/mall-tiny-pipeline/lastBuild/console

# 常见原因参考第12节《常见问题与解决方案》
```

---

## 7. 本节小结

### 验证完成清单

✅ 所有容器正常运行（6个服务）
✅ 网络连通性正常（容器间可通信）
✅ API 接口功能正常（健康检查、登录、品牌列表）
✅ 前端页面可正常访问
✅ Pipeline 自动触发并构建成功
✅ 代码修改正确部署到应用

### 关键验证点

| 验证项 | 状态 | 说明 |
|--------|------|------|
| 服务状态 | ✅ | 6个容器全部运行中 |
| 网络连通 | ✅ | 跨容器通信正常 |
| 健康检查 | ✅ | /actuator/health 返回 UP |
| 登录功能 | ✅ | 可获取 JWT Token |
| 业务功能 | ✅ | 品牌列表接口正常 |
| 前端访问 | ✅ | http://localhost 可访问 |
| CI/CD流程 | ✅ | push代码自动触发构建 |

### 下一步

CI/CD 环境已完全就绪，可以开始：
1. 开发新功能并体验自动化部署
2. 配置 Webhook 实现完全自动化
3. 添加更多测试阶段到 Pipeline
4. 配置钉钉/邮件通知

---

## 参考信息

### 所有服务访问地址

| 服务 | URL | 账号/密码 |
|------|-----|-----------|
| Jenkins | http://localhost:9090 | 首次安装无密码 |
| Gitea | http://localhost:3000 | gitadmin/gitadmin123 |
| 前端 | http://localhost | admin/macro123 |
| Swagger | http://localhost:8080/swagger-ui/ | - |
| Actuator | http://localhost:8080/actuator/health | - |

### 常用命令

```bash
# 查看所有服务状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 查看应用日志
docker logs -f mall-tiny-app

# 手动触发构建
curl -X POST http://localhost:9090/job/mall-tiny-pipeline/build

# 重启所有服务
docker restart jenkins gitea mall-tiny-app mall-tiny-mysql mall-tiny-redis mall-admin-web

# 一键验证
./jenkins/verify-deployment.sh
```
