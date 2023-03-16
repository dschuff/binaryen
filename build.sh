#!/bin/bash

python3 ./scripts/gen-s-parser.py
cmake -G Ninja .
ninja
