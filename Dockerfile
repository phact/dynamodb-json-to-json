FROM adoptopenjdk/openjdk11:jdk-11.0.9.1_1


RUN apt-get update
RUN apt-get install -y curl unzip
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install


COPY server.js ./
COPY package.json ./
COPY dsbulk /dsbulk
COPY run.sh ./
RUN npm install
ENTRYPOINT [ "./run.sh" ]
