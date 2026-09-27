FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
# package-lock.json is committed → reproducible install
RUN npm ci --omit=dev
COPY . .
ENV PORT=3000 HOST=0.0.0.0
EXPOSE 3000
CMD ["node", "src/server.js"]
