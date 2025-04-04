FROM ubuntu:noble


RUN \
  apt-get update && \
    apt-get install -y build-essential cmake python3 curl nodejs ninja-build git python3-pip

# Add source for nodejs,
# see https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
# RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
# RUN apt-get install nodejs



COPY . /test
WORKDIR /test

RUN git submodule update --init
RUN pip3 install --break-system-packages -r requirements-dev.txt

RUN ./scripts/gen-s-parser.py | diff src/gen-s-parser.inc -

#RUN rm -f CMakeCache.txt
RUN mkdir out/
RUN cmake -G Ninja -S . -B out
RUN cmake --build out --config Release
RUN cmake --install out