FROM ubuntu:jammy


RUN \
  apt-get update && \
    apt-get install -y build-essential cmake python3 curl nodejs ninja-build git

# Add source for nodejs,
# see https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
# RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
# RUN apt-get install nodejs

RUN git submodule update --init

COPY . /test
WORKDIR /test

RUN ./scripts/gen-s-parser.py | diff src/gen-s-parser.inc -

RUN rm -f CMakeCache.txt
RUN cmake -G Ninja .
RUN ninja