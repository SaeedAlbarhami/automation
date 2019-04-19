FROM openjdk:8-jdk-slim
WORKDIR /home/automation
ARG REVISION
COPY target/automation-${REVISION}.jar app.jar
ENTRYPOINT ["java","-jar","app.jar"]
