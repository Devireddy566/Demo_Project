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

# Copy the built JAR file from the GitHub Actions workspace (target directory) to the current stage.
# The JAR name is derived from <artifactId>-<version>.jar as defined in pom.xml
# Ensure this path matches the output of your 'mvn clean install' step in the workflow.
COPY target/ecommerce-app-1.0-SNAPSHOT.jar app.jar

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
