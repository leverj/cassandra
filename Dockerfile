# vim:set ft=dockerfile:
FROM debian:jessie-backports

ENV CASSANDRA_VERSION 2.2.5
ENV CASSANDRA_CONFIG /etc/cassandra

# explicitly set user/group IDs
RUN  groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget cron \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && apt-get install -y libjna-java \
    && apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 514A2AD631A57A16DD0047EC749D6EEC0353B12C \
    && echo 'deb http://www.apache.org/dist/cassandra/debian 22x main' >> /etc/apt/sources.list.d/cassandra.list \
    && apt-get update \
    && apt-get install -y cassandra="$CASSANDRA_VERSION" \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove wget


COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
COPY snapshot /etc/cron.hourly/
RUN mkdir -p /var/lib/cassandra "$CASSANDRA_CONFIG" \
	&& chown -R cassandra:cassandra /var/lib/cassandra "$CASSANDRA_CONFIG" \
	&& chmod 777 /var/lib/cassandra "$CASSANDRA_CONFIG" \
	&& chmod +x /etc/cron.hourly/snapshot

VOLUME /var/lib/cassandra

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160
CMD ["cassandra", "-f"]
