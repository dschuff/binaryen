FROM ubuntu:noble


RUN \
  apt-get update && \
    apt-get install -y build-essential cmake python3 curl ninja-build git python3-pip

# Download and install nvm:
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
# Download and install Node.js:
RUN nvm install 23


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