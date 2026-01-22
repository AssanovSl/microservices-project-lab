FROM openjdk:8u212-jdk-alpine AS build

WORKDIR /app

COPY pom.xml mvnw ./
COPY .mvn/ .mvn/
RUN ./mvnw dependency:go-offline -B

COPY src/ src/
RUN ./mvnw package -DskipTests 

FROM openjdk:8u212-jre-alpine AS start

# Установить в образ bash для корректной работы wait-for-it.sh
RUN apk add --no-cache bash

WORKDIR /service

COPY --from=build /app/target/*.jar loyalty-service.jar
COPY wait-for-it.sh ./

RUN chmod +x wait-for-it.sh

CMD ["./wait-for-it.sh", "postgres:5432", "--",\
     "./wait-for-it.sh", "rabbitmq:5672", "--", \
     "sh", "-c", "java $JAVA_OPTS -jar loyalty-service.jar"]