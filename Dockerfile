FROM node:18.8-alpine as base

FROM base as builder

WORKDIR /home/node/app

COPY package*.json ./

COPY . .
RUN yarn install
RUN yarn build

FROM base as runtime

# Installiere MongoDB
RUN apk add --no-cache mongodb

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
