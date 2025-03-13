# Step 1: Build the Angular app
FROM node:20 AS build-stage

# Set the working directory
WORKDIR /app

# Copy the package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the Angular application code
COPY . .

# Build the Angular app in production mode
RUN npm install --legacy-peer-deps

# Step 2: Serve the app using NGINX
FROM nginx:alpine AS production-stage

# Copy the build output from the build-stage
COPY --from=build-stage /app/dist/your-app-name /usr/share/nginx/html

# Expose port 80 to be accessible from the host
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]

