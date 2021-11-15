FROM node:16
COPY server.js ./
COPY package.json ./
COPY dsbulk /dsbulk
COPY run.sh ./
RUN npm install
ENTRYPOINT [ "run.sh" ]
