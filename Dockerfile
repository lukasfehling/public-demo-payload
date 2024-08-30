FROM node:18.8-alpine as base

FROM base as builder

WORKDIR /home/node/app

COPY package*.json ./

COPY . .
RUN yarn install
RUN yarn build

FROM base as runtime

# Installiere MongoDB von den offiziellen Repositories
RUN apk add --no-cache --update \
    && apk add --no-cache bash \
    && apk add --no-cache curl \
    && curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-5.0.6.tgz \
    && tar -zxvf mongodb-linux-x86_64-5.0.6.tgz \
    && mv mongodb-linux-x86_64-5.0.6 /usr/local/mongodb \
    && rm mongodb-linux-x86_64-5.0.6.tgz

# Setze MongoDB als globalen Befehl
ENV PATH="/usr/local/mongodb/bin:${PATH}"

# Setze Umgebungsvariablen
ENV MONGO_INITDB_ROOT_USERNAME=root
ENV MONGO_INITDB_ROOT_PASSWORD=example
ENV DATABASE_URI=mongodb://localhost:27017/payload-demo
ENV PAYLOAD_SECRET=supersecret
ENV NODE_ENV=production

ENV NODE_ENV=production
ENV PAYLOAD_CONFIG_PATH=dist/payload.config.js

WORKDIR /home/node/app
COPY package*.json  ./

RUN yarn install --production
COPY --from=builder /home/node/app/dist ./dist
COPY --from=builder /home/node/app/build ./build

EXPOSE 3000

CMD mongod --bind_ip 0.0.0.0 --logpath /var/log/mongod.log --dbpath /data/db --fork && node dist/server.js
