# 基础镜像：JRE 17 与 Jenkins 编译环境（JDK 17）保持一致
# eclipse-temurin 是 openjdk 的官方替代品
FROM eclipse-temurin:17-jre

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 将jar包复制到容器中
ADD ./target/mall-tiny-1.0.0-SNAPSHOT.jar /mall-tiny-1.0.0-SNAPSHOT.jar

# 声明服务运行在8080端口
EXPOSE 8080

# 启动参数：设置JVM内存，容器友好模式
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "/mall-tiny-1.0.0-SNAPSHOT.jar"]

LABEL maintainer="macrozheng" \
      description="mall-tiny spring boot application"
