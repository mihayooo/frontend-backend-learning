#!/usr/bin/env groovy
/**
 * Jenkins 初始化脚本 (Groovy)
 * 路径: jenkins/init.groovy.d/init.groovy
 * 
 * 放入 jenkins_home/init.groovy.d/ 目录后，Jenkins 启动时自动执行
 * 用途：跳过安装向导、创建管理员账户
 */
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// ===== 1. 创建管理员用户 =====
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin123')  // 用户名/密码，生产环境请修改
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println "=== Jenkins 管理员账户已创建: admin / admin123 ==="
