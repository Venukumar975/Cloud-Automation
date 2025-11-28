FROM node:20-slim

WORKDIR /
COPY package*.json ./
RUN npm install --only=production
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]