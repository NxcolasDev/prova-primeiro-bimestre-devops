# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

# Stage 2: Runner
FROM node:20-alpine
WORKDIR /app
RUN addgroup -S nodejs && adduser -S expressuser -G nodejs
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY src/ ./src/
USER expressuser
EXPOSE 3000
CMD ["node", "src/index.js"]