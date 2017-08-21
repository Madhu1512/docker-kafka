FROM anapsix/alpine-java

# Update image and install base packages
RUN apk update && \
    apk add --no-cache bash ca-certificates curl tar python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache && \
    rm -rf /var/cache/apk/*

# The Scala 2.11 build is currently recommended by the project.
ENV KAFKA_VERSION=0.11.0.0 KAFKA_SCALA_VERSION=2.11 KAFKA_JMX_PORT=7203
ENV KAFKA_RELEASE_ARCHIVE kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}.tgz
ENV APACHE_REPO=http://www.us.apache.org/dist/kafka

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

RUN mkdir /kafka /data /logs

# Install Kafka to /kafka
RUN curl -sS -k ${APACHE_REPO}/${KAFKA_VERSION}/${KAFKA_RELEASE_ARCHIVE} | gunzip -c - | tar -xf - -C /tmp && \
    mv /tmp/kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}/* /kafka/ && \
    rm -rf /tmp/kafka_* /tmp/requirements.txt

COPY config/server.properties.template /kafka/config
COPY start.sh /kafka/start.sh
COPY start.py /kafka/start.py

# Set up a user to run Kafka
RUN addgroup -g 10003 kafka && \
    adduser -g "kafka user" -D -h /kafka -G kafka -s /sbin/nologin -u 10003 kafka && \
    chown -R kafka:kafka /kafka /data /logs && \
    chmod +x /kafka/start.py /kafka/start.sh


USER kafka
ENV PATH /kafka/bin:$PATH
WORKDIR /kafka

# broker, jmx
EXPOSE 9092 ${KAFKA_JMX_PORT}
VOLUME [ "/data", "/logs" ]

CMD ["/kafka/start.sh"]
