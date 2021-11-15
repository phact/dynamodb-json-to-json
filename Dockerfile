FROM node:16
COPY server.js ./
COPY package.json ./
RUN npm install
ENTRYPOINT [ "npm run start" ]
