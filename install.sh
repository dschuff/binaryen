#!/bin/sh

apt-get update
apt-get install -y git cmake ninja-build python3
git submodule update --init
