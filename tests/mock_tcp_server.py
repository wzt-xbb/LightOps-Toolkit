#!/usr/bin/env python3

import argparse
import socket


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=18080)
    args = parser.parse_args()

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((args.host, args.port))
        server.listen(5)
        print(f"Mock TCP server listening on {args.host}:{args.port}")

        while True:
            conn, addr = server.accept()
            with conn:
                print(f"connection from {addr}")


if __name__ == "__main__":
    main()
