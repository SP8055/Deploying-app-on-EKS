FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /build

# Copy pom and source
COPY pom.xml .
COPY src ./src

# Build the WAR
RUN mvn clean package -DskipTests

# ================== Runtime Stage ==================
FROM tomcat:9.0-jdk17-temurin

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy as ROOT (easiest - accessible at http://IP:9000/)
COPY --from=build /build/target/petshop.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
