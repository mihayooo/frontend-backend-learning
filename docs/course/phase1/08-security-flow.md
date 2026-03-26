# 第八节：Spring Security 认证流程解析

> **学习目标**：理解 mall-tiny 的认证授权机制，掌握 JWT 的使用

---

## 8.1 本节概述

mall-tiny 使用 **Spring Security + JWT** 实现认证授权：
- **Spring Security**：安全框架，处理认证和授权
- **JWT（JSON Web Token）**：无状态的令牌机制

本节将解析整个认证流程。

**预计学习时间**：30 分钟

---

## 8.2 认证流程概览

```
┌──────────┐    登录请求     ┌──────────────┐
│   用户    │ ─────────────▶ │  UmsAdmin    │
│          │  username/     │  Controller  │
│          │  password      └──────┬───────┘
└──────────┘                         │
                                     ▼
                            ┌─────────────────┐
                            │  验证用户名密码   │
                            │  生成 JWT Token │
                            └────────┬────────┘
                                     │
◀────────────────────────────────────┘
         返回 Token

后续请求：
┌──────────┐   携带Token    ┌──────────────┐
│   用户    │ ─────────────▶ │  JwtAuth     │
│          │  Authorization │  TokenFilter │
│          │  Bearer xxx    └──────┬───────┘
└──────────┘                         │
                                     ▼
                            ┌─────────────────┐
                            │  验证Token有效性 │
                            │  设置用户上下文  │
                            └────────┬────────┘
                                     │
◀────────────────────────────────────┘
         返回请求结果
```

---

## 8.3 核心组件

### 8.3.1 JWT 工具类

`JwtTokenUtil.java` - 负责 Token 的生成和解析：

```java
@Component
public class JwtTokenUtil {
    
    // 生成 Token
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        claims.put(CLAIM_KEY_USERNAME, userDetails.getUsername());
        claims.put(CLAIM_KEY_CREATED, new Date());
        return generateToken(claims);
    }
    
    // 从 Token 获取用户名
    public String getUserNameFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims.getSubject();
    }
    
    // 验证 Token 是否有效
    public boolean validateToken(String token, UserDetails userDetails) {
        String username = getUserNameFromToken(token);
        return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }
}
```

### 8.3.2 认证过滤器

`JwtAuthenticationTokenFilter.java` - 拦截请求并验证 Token：

```java
public class JwtAuthenticationTokenFilter extends OncePerRequestFilter {
    
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        // 1. 从请求头获取 Token
        String authHeader = request.getHeader(this.tokenHeader);
        
        // 2. 验证 Token 格式
        if (authHeader != null && authHeader.startsWith(this.tokenHead)) {
            String authToken = authHeader.substring(this.tokenHead.length());
            
            // 3. 从 Token 获取用户名
            String username = jwtTokenUtil.getUserNameFromToken(authToken);
            
            // 4. 验证并设置安全上下文
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);
                
                if (jwtTokenUtil.validateToken(authToken, userDetails)) {
                    // 设置认证信息
                    UsernamePasswordAuthenticationToken authentication = 
                        new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        }
        
        chain.doFilter(request, response);
    }
}
```

---

## 8.4 登录流程详解

### 8.4.1 登录接口

`UmsAdminController.java`：

```java
@ApiOperation(value = "登录以后返回token")
@RequestMapping(value = "/login", method = RequestMethod.POST)
@ResponseBody
public CommonResult login(@RequestBody UmsAdminLoginParam loginParam) {
    // 调用 Service 进行认证
    String token = adminService.login(loginParam.getUsername(), loginParam.getPassword());
    
    if (token == null) {
        return CommonResult.validateFailed("用户名或密码错误");
    }
    
    // 返回 Token
    Map<String, String> tokenMap = new HashMap<>();
    tokenMap.put("token", token);
    tokenMap.put("tokenHead", tokenHead);
    return CommonResult.success(tokenMap);
}
```

### 8.4.2 认证实现

`UmsAdminServiceImpl.java`：

```java
@Override
public String login(String username, String password) {
    // 1. 创建认证 Token
    UsernamePasswordAuthenticationToken authenticationToken = 
        new UsernamePasswordAuthenticationToken(username, password);
    
    try {
        // 2. 调用 AuthenticationManager 进行认证
        Authentication authentication = 
            authenticationManager.authenticate(authenticationToken);
        
        // 3. 认证成功，生成 JWT Token
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        return jwtTokenUtil.generateToken(userDetails);
        
    } catch (BadCredentialsException e) {
        // 认证失败
        return null;
    }
}
```

---

## 8.5 Token 使用方式

### 8.5.1 登录获取 Token

```bash
POST http://localhost:8080/admin/login
Content-Type: application/json

{
  "username": "admin",
  "password": "macro123"
}
```

响应：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenHead": "Bearer "
  }
}
```

### 8.5.2 后续请求携带 Token

```bash
GET http://localhost:8080/admin/info
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

---

## 8.6 本节小结

✅ 理解了 Spring Security + JWT 的认证流程  
✅ 了解了 Token 的生成和验证机制  
✅ 掌握了如何在请求中使用 Token

---

## 8.7 第一阶段完结

至此，第一阶段（mall-tiny 快速上手）全部完成！

**已掌握内容**：
- 开发环境搭建（JDK、Maven、IDEA）
- 数据库环境（MySQL、Redis）
- 项目启动（后端 + 前端）
- 代码生成器使用
- 认证流程理解

**下一阶段预告**：
- 商品模块开发
- 订单模块开发
- 缓存优化
- 搜索功能
- 部署运维

---

## 参考资源

- [Spring Security 官方文档](https://spring.io/projects/spring-security)
- [JWT 官方文档](https://jwt.io/introduction)
