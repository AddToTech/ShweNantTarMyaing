# backend/Dockerfile
FROM node:20-alpine AS base

WORKDIR /app

# Install dependencies needed for native modules (if any)
RUN apk add --no-cache libc6-compat

COPY package*.json ./

# Install production dependencies
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Create uploads directory and ensure permissions
RUN mkdir -p uploads/products && chmod -R 755 uploads

# Default port
ENV PORT=5001
ENV NODE_ENV=production

EXPOSE 5001

CMD ["node", "src/server.js"]

