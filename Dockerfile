# Stage 1: Build the application
# Use an official Maven image with Eclipse Temurin JDK 17 on Alpine Linux as a build stage.
# Alpine is chosen for its small size.
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build

LABEL maintainer="your-email@example.com"
LABEL description="Build stage for the Java e-commerce application - Spring Boot 3.1.0, Java 17"

# Set the working directory in the container
WORKDIR /app

# Copy the Maven project file.
# Copying pom.xml first allows Docker to cache the dependency download layer
# if pom.xml hasn't changed, speeding up subsequent builds.
COPY pom.xml .

# Download project dependencies.
# Using dependency:go-offline to download all dependencies to be cached.
# -B runs in batch mode (no interactive prompts)
RUN mvn -B dependency:go-offline

# Copy the rest of the source code
# Ensure that .dockerignore is set up correctly to exclude unnecessary files (e.g., .git, target, IDE files)
COPY src ./src

# Build the application and create the JAR file.
# -DskipTests skips running tests during the build to speed it up.
# The application JAR will be created in /app/target/ecommerce-app-1.0-SNAPSHOT.jar (based on pom.xml)
RUN mvn -B clean package -DskipTests

# Stage 2: Create the runtime image
# Use an official Eclipse Temurin JRE 17 image on Alpine Linux for the runtime stage.
# This image is lightweight as it only contains the Java Runtime Environment.
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="your-email@example.com"
LABEL description="Runtime stage for the Java e-commerce application - Spring Boot 3.1.0, Java 17"

# Set the working directory
WORKDIR /app

# Create a non-root user and group for security purposes
# Using -S for system user/group, -D to not assign a password, -G to assign to group
RUN addgroup -S appgroup && adduser -S -D -G appgroup appuser

# Copy the built JAR file from the 'build' stage to the current stage.
# The JAR name is derived from <artifactId>-<version>.jar as defined in pom.xml
COPY --from=build /app/target/ecommerce-app-1.0-SNAPSHOT.jar app.jar

# Change ownership of the app directory and JAR file to the non-root user
# This is important for security and file permissions.
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose the port the application runs on (8080 as per application.properties)
EXPOSE 8080

# Command to run the application when the container starts.
# exec form is preferred for ENTRYPOINT.
# Consider adding JVM options for memory management if needed, e.g., -Xmx512m
ENTRYPOINT ["java", "-jar", "app.jar"]
