#!/usr/bin/env python3
import sys
vocab = {}
with open(sys.argv[1], encoding="utf-8") as fin:
    for line in fin:
        for token in line.strip().split():
            if token not in vocab:
                vocab[token] = 1
                print(token)
