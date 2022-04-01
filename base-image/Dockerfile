FROM ubuntu:20.04

ENV ETC_PROFILE="/etc/profile"
ENV BASHRC="/root/.bashrc"
ENV JOURNAL_LOGS="/var/log/journal"

# Env necessary for the individual child container setup
ENV SELF_HOME=/self/home
ENV SELF_CONTAINER=${SELF_HOME}/container
ENV BUILD_SCRIPT=${SELF_CONTAINER}/deployment.sh
ENV FLUTTERROOT="/usr/lib/flutter"
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/go
ENV GOBIN=/usr/local/go/bin
ENV RUSTFLAGS="-Ctarget-feature=+aes,+ssse3"
ENV PATH="${PATH}:${FLUTTERROOT}/bin:${FLUTTERROOT}/bin/cache/dart-sdk/bin:${GOROOT}:${GOPATH}:${GOBIN}:/root/.cargo/bin:/root/go/bin"

RUN mkdir -p ${SELF_HOME} ${SELF_CONTAINER} ${GOPATH}/src ${GOPATH}/bin

ADD ./container ${SELF_CONTAINER}

RUN chmod -v +x ${BUILD_SCRIPT}

ARG DEBIAN_FRONTEND=noninteractive
RUN LC_ALL=C ${BUILD_SCRIPT}
RUN rm -rfv /var/lib/apt/lists/*

ENTRYPOINT [ "bash", "-c" ]