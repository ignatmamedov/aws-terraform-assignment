# ------------------ Stage 1: Build with Node ------------------
FROM node:18-alpine AS build

WORKDIR /app

# Copy only package files first to leverage caching
COPY package*.json ./
RUN npm install
ARG VITE_BACKEND_URL

ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
# Copy the rest of your frontend code
COPY . .

# Build your production assets (for example, using Vite)
# Adjust the command if you're using "build" or "prod" in your package scripts
RUN npm run build

# ------------------ Stage 2: Serve with Nginx ------------------
FROM nginx:alpine

# Copy built frontend assets from 'build' stage to Nginx root
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80 (inside container). We'll map host port 5173 in docker-compose.
EXPOSE 80

# Run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
