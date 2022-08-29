FROM maven:3.8.6-jdk-11 as builder

ARG connector

COPY ./vance /build/vance
COPY ./cdk-java /build/cdk-java

WORKDIR /build/vance/connectors/${connector}

RUN apt-get -qq update
RUN apt-get -qq install libatomic1
RUN mvn clean package
RUN ls -alh target/*jar-with-dependencies.jar | awk '{system("cp " $9 " /build/executable.jar") }'

FROM openjdk:11

ARG connector
ARG version

COPY --from=builder /build/executable.jar /vance/${connector}/${version}.jar

ENV CONNECTOR=${connector}
ENV CONNECTOR_VERSION=${version}
ENV CONNECTOR_HOME=/vance
ENV CONNECTOR_CONFIG=/vance/config/config.yml
ENV CONNECTOR_SECRET=/vance/secret/secert.yml
ENV CONNECTOR_SECRET_ENABLE=false

RUN echo '#!/bin/sh' >> /vance/run.sh
RUN echo 'java -jar /vance/${CONNECTOR}/${CONNECTOR_VERSION}.jar' >> /vance/run.sh
RUN chmod a+x /vance/run.sh

ENTRYPOINT ["/vance/run.sh"]
