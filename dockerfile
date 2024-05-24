FROM openjdk:8-jdk-alpine

WORKDIR /app

COPY target/spring-petclinic-2.4.2.war /app/app.war

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.war"]