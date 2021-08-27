FROM ubuntu:bionic

RUN \
  apt-get update && \
    apt-get install -y build-essential cmake python3 curl nodejs

# Add source for nodejs,
# see https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
# RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
# RUN apt-get install nodejs

COPY . /test
WORKDIR /test

RUN ./check.py --only-prepare

RUN rm CMakeCache.txt
RUN cmake .
RUN make -j2