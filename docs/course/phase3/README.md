# 第三阶段：部署运维与生产优化

## 阶段目标

通过本阶段的学习，掌握以下技能：
- 生产环境的配置与优化
- CI/CD 自动化部署流程
- Docker 生产环境部署
- 日志收集与监控告警
- 系统性能优化

## 课程大纲

### 第26节：生产环境配置与优化
- Spring Boot 生产环境配置
- 数据库连接池优化
- JVM 参数调优
- 静态资源优化
- Nginx 反向代理配置

### 第27节：GitHub Actions CI/CD自动化部署
- GitHub Actions 工作流配置
- 自动化测试与构建
- Docker 镜像自动构建与推送
- 自动化部署到服务器
- 部署通知与回滚

### 第28节：Docker Compose生产环境部署
- 生产环境 Docker 配置
- 多服务编排与管理
- 数据持久化与备份
- 环境变量管理
- SSL/HTTPS 配置

### 第29节：日志收集与监控告警
- 日志框架配置（Logback/Log4j2）
- 日志分级与归档
- ELK 日志收集系统
- 应用监控（Spring Boot Actuator）
- 告警通知配置

### 第30节：项目总结与后续学习路线
- 项目架构回顾
- 性能优化总结
- 安全最佳实践
- 扩展功能建议
- 后续学习路线

## 技术要点

### 生产环境 checklist
1. **安全配置**：关闭调试模式、配置HTTPS、设置安全头
2. **性能优化**：数据库连接池、缓存策略、静态资源CDN
3. **监控告警**：应用监控、日志收集、异常告警
4. **备份策略**：数据库备份、配置文件备份
5. **容灾方案**：多实例部署、负载均衡

### 核心技能
| 技能 | 应用场景 |
|:---|:---|
| GitHub Actions | 自动化构建与部署 |
| Docker Compose | 多服务编排管理 |
| Nginx | 反向代理、负载均衡 |
| ELK Stack | 日志收集与分析 |
| Prometheus/Grafana | 应用监控与告警 |

## 预期成果

完成第三阶段后，你将拥有一个生产就绪的电商系统：
- ✅ 生产环境优化配置
- ✅ 自动化 CI/CD 流程
- ✅ Docker 生产部署方案
- ✅ 日志监控与告警系统
- ✅ 完整的运维文档

## 参考资源

- [Spring Boot 生产环境配置](https://docs.spring.io/spring-boot/docs/current/reference/html/deployment.html)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker Compose 官方文档](https://docs.docker.com/compose/)
- [Nginx 配置指南](https://nginx.org/en/docs/)
