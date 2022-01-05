FROM adoptopenjdk/openjdk11:jdk-11.0.9.1_1


RUN apt-get update
RUN apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs




COPY server.js ./
COPY package.json ./
COPY dsbulk /dsbulk
COPY run.sh ./
RUN npm install
ENTRYPOINT [ "./run.sh" ]
