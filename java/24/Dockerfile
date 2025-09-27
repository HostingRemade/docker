FROM eclipse-temurin:24-jdk-noble

LABEL author="Daniel" maintainer="danielchu096@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/hostingremade/docker"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update -y \
 && apt-get install -y --no-install-recommends \
      curl ca-certificates fontconfig libfreetype6 libstdc++6 lsof tzdata iproute2 locales-all \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && useradd -m -d /home/container -s /bin/bash -u 1000 container

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

WORKDIR /home/container
ENV USER=container HOME=/home/container

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
