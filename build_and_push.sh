#!/bin/bash
curl -OL https://downloads.datastax.com/dsbulk/dsbulk-1.6.0.tar.gz

tar -xvf dsbulk-1.6.0.tar.gz

mv ./dsbulk*.0 dsbulk

docker build --tag phact/dynamodb-json-to-json ./
docker push phact/dynamodb-json-to-json:latest
