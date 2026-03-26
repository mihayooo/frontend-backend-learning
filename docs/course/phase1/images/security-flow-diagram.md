# Spring Security + JWT 认证流程图

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        用户登录认证流程                                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝

┌──────────┐                                          ┌──────────────────────┐
│   用户    │                                          │    mall-tiny 后端     │
│  (浏览器) │                                          │    (Spring Boot)     │
└────┬─────┘                                          └──────────┬───────────┘
     │                                                           │
     │  ① 登录请求                                                │
     │  POST /admin/login                                         │
     │  {                                                         │
     │    "username": "admin",                                    │
     │    "password": "macro123"                                  │
     │  }                                                         │
     │ ─────────────────────────────────────────────────────────►│
     │                                                           │
     │                                                           ▼
     │                                              ┌──────────────────────┐
     │                                              │  UmsAdminController  │
     │                                              │  @PostMapping("/     │
     │                                              │      login")         │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  UmsAdminService     │
     │                                              │  .login()            │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  Authentication      │
     │                                              │  Manager             │
     │                                              │  .authenticate()     │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  UserDetailsService  │
     │                                              │  .loadUserByUsername │
     │                                              │  查询数据库验证用户    │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                              ② 验证成功                  │
     │                              生成 JWT Token              ▼
     │                                              ┌──────────────────────┐
     │                                              │  JwtTokenUtil        │
     │                                              │  .generateToken()    │
     │                                              │                      │
     │                                              │  Header: {           │
     │                                              │    "alg": "HS256"    │
     │                                              │  }                   │
     │                                              │  Payload: {          │
     │                                              │    "sub": "admin",   │
     │                                              │    "iat": 1234567890 │
     │                                              │  }                   │
     │                                              │  Signature: xxx      │
     │                                              └──────────┬───────────┘
     │                                                         │
     │  ③ 返回 Token                                            │
     │  {                                                       │
     │    "code": 200,                                          │
     │    "data": {                                             │
     │      "token": "eyJhbG...",                               │
     │      "tokenHead": "Bearer "                              │
     │    }                                                     │
     │  }                                                       │
     │ ◄────────────────────────────────────────────────────────│
     │                                                           │
     │                                                           │
     ════════════════════════════════════════════════════════════
     │                                                           │
     │  ④ 后续请求（携带Token）                                   │
     │  GET /admin/info                                         │
     │  Authorization: Bearer eyJhbG...                         │
     │ ─────────────────────────────────────────────────────────►│
     │                                                           │
     │                                                           ▼
     │                                              ┌──────────────────────┐
     │                                              │  JwtAuthentication   │
     │                                              │  TokenFilter         │
     │                                              │  (OncePerRequest     │
     │                                              │   Filter)            │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  从 Header 提取 Token │
     │                                              │  authHeader.substring │
     │                                              │  (tokenHead.length()) │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  JwtTokenUtil        │
     │                                              │  .validateToken()    │
     │                                              │  验证签名和过期时间    │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  设置安全上下文        │
     │                                              │  SecurityContextHolder │
     │                                              │  .getContext()         │
     │                                              │  .setAuthentication()  │
     │                                              └──────────┬───────────┘
     │                                                         │
     │                                                         ▼
     │                                              ┌──────────────────────┐
     │                                              │  调用目标接口          │
     │                                              │  AdminController     │
     │                                              │  .info()             │
     │                                              └──────────┬───────────┘
     │                                                         │
     │  ⑤ 返回数据                                              │
     │  {                                                       │
     │    "code": 200,                                          │
     │    "data": {                                             │
     │      "username": "admin",                                │
     │      "roles": ["管理员"]                                 │
     │    }                                                     │
     │  }                                                       │
     │ ◄────────────────────────────────────────────────────────│
     │                                                           │


╔═══════════════════════════════════════════════════════════════════════════════╗
║                        核心组件说明                                             ║
╚═══════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────────┐
│  JwtTokenUtil                                                               │
│  JWT 工具类                                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  + generateToken(UserDetails): String      // 生成 Token                     │
│  + getUserNameFromToken(String): String    // 从 Token 解析用户名             │
│  + validateToken(String, UserDetails): boolean  // 验证 Token 有效性         │
│  + isTokenExpired(String): boolean         // 检查 Token 是否过期            │
│  + refreshToken(String): String            // 刷新 Token                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  JwtAuthenticationTokenFilter                                               │
│  JWT 认证过滤器                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  继承 OncePerRequestFilter，每次请求执行一次                                  │
│                                                                             │
│  doFilterInternal():                                                        │
│    1. 从请求头获取 Authorization                                            │
│    2. 提取 Token（去掉 "Bearer " 前缀）                                       │
│    3. 解析 Token 获取用户名                                                  │
│    4. 加载 UserDetails                                                       │
│    5. 验证 Token 有效性                                                      │
│    6. 设置 SecurityContext                                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  SecurityConfig                                                             │
│  Spring Security 配置类                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  配置内容：                                                                  │
│  - 密码加密方式（BCryptPasswordEncoder）                                      │
│  - 放行接口（/admin/login, /swagger-ui/** 等）                                │
│  - 添加 JWT 过滤器                                                            │
│  - 禁用 Session（STATELESS）                                                  │
└─────────────────────────────────────────────────────────────────────────────┘


╔═══════════════════════════════════════════════════════════════════════════════╗
║                        Token 结构说明                                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝

JWT Token 由三部分组成，用点号分隔：

  Header.Payload.Signature
    │       │        │
    ▼       ▼        ▼
  eyJ...  eyJ...   Sfl...

【Header 头部】
{
  "alg": "HS256",      // 签名算法
  "typ": "JWT"         // Token 类型
}

【Payload 载荷】
{
  "sub": "admin",      // 主题（用户名）
  "iat": 1234567890,   // 签发时间
  "exp": 1234571490    // 过期时间
}

【Signature 签名】
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret                // 密钥，仅服务端知道
)


╔═══════════════════════════════════════════════════════════════════════════════╗
║                        安全配置代码示例                                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    
    @Autowired
    private JwtAuthenticationTokenFilter jwtAuthenticationTokenFilter;
    
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            // 禁用 CSRF（使用 JWT 不需要）
            .csrf().disable()
            
            // 基于 Token，不需要 Session
            .sessionManagement()
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            
            .and()
            // 配置授权规则
            .authorizeRequests()
            // 允许匿名访问的接口
            .antMatchers("/admin/login", "/register").permitAll()
            // Swagger 文档
            .antMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
            // 其他接口需要认证
            .anyRequest().authenticated();
        
        // 添加 JWT 过滤器
        http.addFilterBefore(jwtAuthenticationTokenFilter, 
                             UsernamePasswordAuthenticationFilter.class);
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```
