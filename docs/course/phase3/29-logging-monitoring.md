# 第29节 日志收集与监控告警

## 学习目标

- 掌握日志框架配置（Logback/Log4j2）
- 学习日志分级与归档策略
- 了解 ELK 日志收集系统
- 掌握 Spring Boot Actuator 监控
- 实现告警通知配置

## 1. 日志框架配置

### 1.1 Logback 配置

Spring Boot 默认使用 Logback，创建 `mall-tiny/src/main/resources/logback-spring.xml`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!-- 属性配置 -->
    <property name="LOG_PATH" value="${LOG_PATH:-./logs}"/>
    <property name="APP_NAME" value="mall-tiny"/>
    <property name="LOG_PATTERN" 
              value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n"/>

    <!-- 控制台输出 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>${LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
    </appender>

    <!-- 信息日志文件 -->
    <appender name="INFO_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_PATH}/${APP_NAME}-info.log</file>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>INFO</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
        <encoder>
            <pattern>${LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/archive/${APP_NAME}-info-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxHistory>30</maxHistory>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>100MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
            <totalSizeCap>10GB</totalSizeCap>
        </rollingPolicy>
    </appender>

    <!-- 错误日志文件 -->
    <appender name="ERROR_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_PATH}/${APP_NAME}-error.log</file>
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>ERROR</level>
        </filter>
        <encoder>
            <pattern>${LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/archive/${APP_NAME}-error-%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>90</maxHistory>
        </rollingPolicy>
    </appender>

    <!-- API 访问日志 -->
    <appender name="API_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_PATH}/${APP_NAME}-api.log</file>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} | %msg%n</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/archive/${APP_NAME}-api-%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
    </appender>

    <!-- 异步追加器 -->
    <appender name="ASYNC_INFO" class="ch.qos.logback.classic.AsyncAppender">
        <queueSize>512</queueSize>
        <discardingThreshold>0</discardingThreshold>
        <appender-ref ref="INFO_FILE"/>
    </appender>

    <appender name="ASYNC_ERROR" class="ch.qos.logback.classic.AsyncAppender">
        <queueSize>512</queueSize>
        <appender-ref ref="ERROR_FILE"/>
    </appender>

    <!-- 日志级别配置 -->
    <logger name="com.macro.mall.tiny" level="INFO"/>
    <logger name="org.springframework" level="WARN"/>
    <logger name="org.mybatis" level="WARN"/>
    
    <!-- API 访问日志 -->
    <logger name="API_LOGGER" level="INFO" additivity="false">
        <appender-ref ref="API_FILE"/>
    </logger>

    <!-- 根日志配置 -->
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="ASYNC_INFO"/>
        <appender-ref ref="ASYNC_ERROR"/>
    </root>
</configuration>
```

### 1.2 日志脱敏处理

创建日志脱敏工具类：

```java
@Component
public class SensitiveDataConverter extends MessageConverter {
    
    // 手机号正则
    private static final Pattern MOBILE_PATTERN = Pattern.compile("(1[3-9]\\d)\\d{4}(\\d{4})");
    // 身份证号正则
    private static final Pattern ID_CARD_PATTERN = Pattern.compile("(\\d{6})\\d{8}(\\d{4})");
    // 邮箱正则
    private static final Pattern EMAIL_PATTERN = Pattern.compile("(\\w{2})\\w+(@\\w+)");
    
    @Override
    public String convert(ILoggingEvent event) {
        String message = super.convert(event);
        if (message == null) {
            return null;
        }
        return desensitize(message);
    }
    
    private String desensitize(String message) {
        // 手机号脱敏: 138****8888
        message = MOBILE_PATTERN.matcher(message)
                .replaceAll("$1****$2");
        
        // 身份证号脱敏: 123456********1234
        message = ID_CARD_PATTERN.matcher(message)
                .replaceAll("$1********$2");
        
        // 邮箱脱敏: ab****@domain.com
        message = EMAIL_PATTERN.matcher(message)
                .replaceAll("$1****$2");
        
        return message;
    }
}
```

## 2. API 访问日志记录

### 2.1 拦截器实现

```java
@Component
@Slf4j
public class ApiAccessLogInterceptor implements HandlerInterceptor {
    
    private static final Logger API_LOGGER = LoggerFactory.getLogger("API_LOGGER");
    
    @Override
    public boolean preHandle(HttpServletRequest request, 
                            HttpServletResponse response, 
                            Object handler) {
        request.setAttribute("startTime", System.currentTimeMillis());
        return true;
    }
    
    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler, Exception ex) {
        Long startTime = (Long) request.getAttribute("startTime");
        long duration = System.currentTimeMillis() - startTime;
        
        String clientIp = getClientIp(request);
        String method = request.getMethod();
        String uri = request.getRequestURI();
        int status = response.getStatus();
        String userAgent = request.getHeader("User-Agent");
        
        // 记录访问日志
        API_LOGGER.info("{} | {} | {} | {} | {}ms | {}",
                clientIp, method, uri, status, duration, userAgent);
        
        // 慢请求告警（超过1秒）
        if (duration > 1000) {
            log.warn("Slow request detected: {} {} took {}ms", method, uri, duration);
        }
    }
    
    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty()) {
            ip = request.getRemoteAddr();
        }
        return ip.split(",")[0].trim();
    }
}
```

### 2.2 注册拦截器

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Autowired
    private ApiAccessLogInterceptor apiAccessLogInterceptor;
    
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(apiAccessLogInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns("/actuator/**", "/swagger-ui/**", "/v3/api-docs/**");
    }
}
```

## 3. Spring Boot Actuator 监控

### 3.1 添加依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### 3.2 Actuator 配置

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus,env,loggers,threaddump,heapdump
      base-path: /actuator
  endpoint:
    health:
      show-details: when_authorized
      show-components: always
    metrics:
      enabled: true
    prometheus:
      enabled: true
  metrics:
    tags:
      application: ${spring.application.name}
    export:
      prometheus:
        enabled: true
  info:
    env:
      enabled: true
    java:
      enabled: true
    os:
      enabled: true
```

### 3.3 自定义健康检查

```java
@Component
public class DatabaseHealthIndicator implements HealthIndicator {
    
    @Autowired
    private DataSource dataSource;
    
    @Override
    public Health health() {
        try (Connection conn = dataSource.getConnection()) {
            if (conn.isValid(1)) {
                return Health.up()
                        .withDetail("database", "MySQL")
                        .withDetail("status", "Connected")
                        .build();
            }
        } catch (SQLException e) {
            return Health.down()
                    .withDetail("database", "MySQL")
                    .withDetail("error", e.getMessage())
                    .build();
        }
        return Health.down().build();
    }
}

@Component
public class RedisHealthIndicator implements HealthIndicator {
    
    @Autowired
    private StringRedisTemplate redisTemplate;
    
    @Override
    public Health health() {
        try {
            redisTemplate.opsForValue().get("health_check");
            return Health.up()
                    .withDetail("redis", "Connected")
                    .build();
        } catch (Exception e) {
            return Health.down()
                    .withDetail("redis", "Disconnected")
                    .withDetail("error", e.getMessage())
                    .build();
        }
    }
}
```

### 3.4 自定义指标

```java
@Component
public class BusinessMetrics {
    
    private final Counter orderCounter;
    private final Timer orderProcessTimer;
    private final Gauge activeUsers;
    
    private AtomicInteger activeUserCount = new AtomicInteger(0);
    
    public BusinessMetrics(MeterRegistry registry) {
        // 订单计数器
        this.orderCounter = Counter.builder("business.orders.created")
                .description("Total number of orders created")
                .register(registry);
        
        // 订单处理时间
        this.orderProcessTimer = Timer.builder("business.orders.process.time")
                .description("Order processing time")
                .register(registry);
        
        // 活跃用户 gauge
        this.activeUsers = Gauge.builder("business.users.active")
                .description("Number of active users")
                .register(registry, activeUserCount, AtomicInteger::get);
    }
    
    public void incrementOrderCount() {
        orderCounter.increment();
    }
    
    public void recordOrderProcessTime(long millis) {
        orderProcessTimer.record(millis, TimeUnit.MILLISECONDS);
    }
    
    public void setActiveUsers(int count) {
        activeUserCount.set(count);
    }
}
```

## 4. ELK 日志收集系统

### 4.1 Filebeat 配置

创建 `production/filebeat/filebeat.yml`：

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /logs/mall-tiny-info.log
    - /logs/mall-tiny-error.log
    - /logs/mall-tiny-api.log
  fields:
    service: mall-tiny
    environment: production
  fields_under_root: true
  multiline.pattern: '^\d{4}-\d{2}-\d{2}'
  multiline.negate: true
  multiline.match: after

- type: log
  enabled: true
  paths:
    - /logs/nginx/access.log
  fields:
    service: nginx
    log_type: access
  fields_under_root: true

output.elasticsearch:
  hosts: ["${ELASTICSEARCH_HOSTS:elasticsearch:9200}"]
  username: "${ELASTICSEARCH_USERNAME:}"
  password: "${ELASTICSEARCH_PASSWORD:}"
  index: "mall-logs-%{+yyyy.MM.dd}"

# 输出到 Logstash（可选）
# output.logstash:
#   hosts: ["logstash:5044"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
```

### 4.2 Docker Compose 集成 ELK

```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: mall-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - ./data/elasticsearch:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - mall-network

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: mall-logstash
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    environment:
      - "LS_JAVA_OPTS=-Xms256m -Xmx256m"
    ports:
      - "5044:5044"
    networks:
      - mall-network
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: mall-kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    networks:
      - mall-network
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    container_name: mall-filebeat
    user: root
    volumes:
      - ./logs:/logs:ro
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
    networks:
      - mall-network
    depends_on:
      - logstash
```

## 5. 告警通知

### 5.1 钉钉告警

```java
@Component
@Slf4j
public class DingTalkAlertService {
    
    @Value("${alert.dingtalk.webhook:}")
    private String webhookUrl;
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    public void sendAlert(String title, String content, AlertLevel level) {
        if (webhookUrl.isEmpty()) {
            return;
        }
        
        Map<String, Object> message = new HashMap<>();
        message.put("msgtype", "markdown");
        
        Map<String, String> markdown = new HashMap<>();
        markdown.put("title", title);
        markdown.put("text", buildMarkdownContent(title, content, level));
        message.put("markdown", markdown);
        
        try {
            restTemplate.postForObject(webhookUrl, message, String.class);
        } catch (Exception e) {
            log.error("Failed to send DingTalk alert", e);
        }
    }
    
    private String buildMarkdownContent(String title, String content, AlertLevel level) {
        String emoji = switch (level) {
            case CRITICAL -> "🔴";
            case WARNING -> "🟡";
            case INFO -> "🟢";
        };
        
        return String.format("""
                ### %s %s
                
                **时间**: %s
                **级别**: %s
                **内容**: %s
                """, 
                emoji, title, 
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")),
                level, content);
    }
    
    public enum AlertLevel {
        CRITICAL, WARNING, INFO
    }
}
```

### 5.2 异常告警切面

```java
@Aspect
@Component
@Slf4j
public class ExceptionAlertAspect {
    
    @Autowired
    private DingTalkAlertService alertService;
    
    @AfterThrowing(pointcut = "execution(* com.macro.mall.tiny.controller.*.*(..))", 
                   throwing = "ex")
    public void handleException(JoinPoint joinPoint, Exception ex) {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        
        String content = String.format("%s.%s() 发生异常: %s", 
                className, methodName, ex.getMessage());
        
        alertService.sendAlert("系统异常告警", content, 
                DingTalkAlertService.AlertLevel.CRITICAL);
    }
}
```

### 5.3 健康检查告警

```java
@Component
public class HealthCheckAlert {
    
    @Autowired
    private DingTalkAlertService alertService;
    
    private final Map<String, Boolean> lastHealthStatus = new ConcurrentHashMap<>();
    
    @Scheduled(fixedRate = 60000) // 每分钟检查
    public void checkHealth() {
        checkDatabaseHealth();
        checkRedisHealth();
        checkDiskSpace();
    }
    
    private void checkDiskSpace() {
        File root = new File("/");
        long usableSpace = root.getUsableSpace();
        long totalSpace = root.getTotalSpace();
        double usagePercent = (1 - (double) usableSpace / totalSpace) * 100;
        
        if (usagePercent > 90) {
            alertService.sendAlert("磁盘空间告警",
                    String.format("磁盘使用率超过90%%: %.2f%%", usagePercent),
                    DingTalkAlertService.AlertLevel.CRITICAL);
        } else if (usagePercent > 80) {
            alertService.sendAlert("磁盘空间警告",
                    String.format("磁盘使用率超过80%%: %.2f%%", usagePercent),
                    DingTalkAlertService.AlertLevel.WARNING);
        }
    }
}
```

## 6. 监控大盘配置

### 6.1 Prometheus 配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'mall-tiny'
    metrics_path: '/admin/actuator/prometheus'
    static_configs:
      - targets: ['app:8080']
    
  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']
    
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
    
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```

### 6.2 Grafana 仪表盘

创建 `grafana/dashboards/mall-tiny-dashboard.json`：

```json
{
  "dashboard": {
    "title": "Mall Tiny 监控大盘",
    "panels": [
      {
        "title": "JVM 内存使用",
        "type": "stat",
        "targets": [{
          "expr": "jvm_memory_used_bytes{area=\"heap\"}"
        }]
      },
      {
        "title": "HTTP 请求速率",
        "type": "graph",
        "targets": [{
          "expr": "rate(http_server_requests_seconds_count[5m])"
        }]
      },
      {
        "title": "订单创建数量",
        "type": "stat",
        "targets": [{
          "expr": "business_orders_created_total"
        }]
      },
      {
        "title": "数据库连接池",
        "type": "graph",
        "targets": [{
          "expr": "hikaricp_connections_active"
        }]
      }
    ]
  }
}
```

## 7. 日志分析查询示例

### 7.1 Kibana 常用查询

```
# 查询错误日志
level: ERROR

# 查询特定用户的操作
message: "userId: 12345"

# 查询慢请求
duration:>1000

# 查询特定接口
uri:"/admin/order/list"

# 组合查询
level:ERROR AND uri:"/admin/order/*"
```

## 小结

本节我们学习了：

1. **日志框架配置** - Logback 配置、日志分级、异步追加
2. **日志脱敏** - 敏感信息过滤、正则匹配
3. **API 访问日志** - 拦截器实现、慢请求检测
4. **Actuator 监控** - 健康检查、自定义指标
5. **ELK 日志收集** - Filebeat、Elasticsearch、Kibana
6. **告警通知** - 钉钉告警、异常监控、健康检查

下一节我们将进行项目总结与后续学习路线规划。
