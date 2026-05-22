# Étape 1 : compilation Maven
FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /app

COPY pom.xml .
RUN mvn -q -B dependency:go-offline

COPY src ./src
RUN mvn -q -B -DskipTests package

# Étape 2 : image d'exécution légère
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN apk add --no-cache su-exec \
    && addgroup -S spring && adduser -S spring -G spring

COPY --from=build /app/target/clubbackend-0.0.1-SNAPSHOT.jar app.jar
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8084

ENTRYPOINT ["/docker-entrypoint.sh"]
