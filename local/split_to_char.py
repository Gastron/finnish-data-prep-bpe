#!/usr/bin/env python3 

def split_to_chars(line):
    return " <w> ".join(" ".join(word) for word in line.strip().split())

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    args = parser.parse_args()
    with open(args.file, encoding='utf-8') as fin:
        for line in fin:
            print(split_to_chars(line))
