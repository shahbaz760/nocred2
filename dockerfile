# Step 1: Use Node.js image to build the Angular app
FROM node:22 AS build


# Step 2: Set the working directory inside the container
WORKDIR /app

# Step 3: Copy the package.json and package-lock.json
COPY package*.json ./

RUN export NODE_OPTIONS=--openssl-legacy-provider

# Step 4: Install the dependencies
RUN npm install --legacy-peer-deps

# Step 5: Copy the Angular app source code
COPY . .

# Step 6: Build the Angular app for production
RUN npm run build

# Step 7: Use Nginx to serve the app
FROM nginx:alpine

# Step 8: Copy the built Angular app from the build stage to Nginx's html folder
COPY --from=build /app/dist/FirstProject /usr/share/nginx/html

# Step 9: Expose port 80
EXPOSE 80

# Step 10: Start Nginx to serve the app
CMD ["nginx", "-g", "daemon off;"]

