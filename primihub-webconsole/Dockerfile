FROM node:16.14-slim as builder

RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list \
  && sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list \
  && sed -i '/stretch-updates/d' /etc/apt/sources.list \
  && apt update \
  && apt install -y python3 make gcc g++

WORKDIR /opt

ADD . ./

RUN npm install -g npm@8.15.1 \
  && npm install --legacy-peer-deps \
  && npm install --save-dev cache-loader --legacy-peer-deps \
  && npm run build:prod

FROM nginx:1.20

COPY --from=builder /opt/dist/ /usr/local/nginx/html/
COPY --from=builder /opt/default.conf /etc/nginx/conf.d/default.conf