FROM jenkins/jenkins:lts-jdk17

USER root

# 安装 Maven 3.9.9
RUN curl -fL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.tar.gz \
    -o /tmp/maven.tgz \
    && tar -xzf /tmp/maven.tgz -C /opt/ \
    && ln -sf /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn \
    && rm /tmp/maven.tgz

# 安装 Docker CLI（静态二进制，不需要 Docker daemon）
RUN curl -fL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz \
    -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /tmp/ \
    && cp /tmp/docker/docker /usr/local/bin/docker \
    && chmod +x /usr/local/bin/docker \
    && rm -rf /tmp/docker.tgz /tmp/docker

# 验证安装
RUN mvn --version && docker --version

USER jenkins
