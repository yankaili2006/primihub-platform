FROM maven:3.8.6-openjdk-8 as build

WORKDIR /opt

# Aliyun Maven mirror
COPY settings.xml /tmp/settings.xml

ADD . /opt/

RUN --mount=type=cache,target=/root/.m2/repository \
  ARCH=`arch | sed s/arm64/aarch_64/ | sed s/aarch64/aarch_64/ | sed s/amd64/x86_64/` \
  && cd primihub-sdk \
  && mvn -s /tmp/settings.xml -T 1C clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=linux-${ARCH}
RUN --mount=type=cache,target=/root/.m2/repository \
  cd primihub-service \
  && mvn -s /tmp/settings.xml -T 1C clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true \
  && rm -f /tmp/settings.xml

FROM amazoncorretto:8

ENV DEBIAN_FRONTEND=noninteractive

RUN yum install -y tzdata \
  && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

COPY --from=build /opt/primihub-service/application/target/*-SNAPSHOT.jar /applications/application.jar
COPY --from=build /opt/primihub-service/gateway/target/*-SNAPSHOT.jar /applications/gateway.jar

ENTRYPOINT ["/bin/sh","-c","java -jar -Dfile.encoding=UTF-8 -Dspring.profiles.active=dev /applications/application.jar --server.port=8080"]
