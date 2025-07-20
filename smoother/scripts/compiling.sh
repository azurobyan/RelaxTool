#!/bin/bash
CPP_BIN="./smoother"
CPP_SRC="smoother.cpp"
EIGEN_PATH="/usr/include/eigen3" 
compile_cpp() {
    echo "Compiling C++ code..."
    g++ -std=c++17 -O3 -I"$EIGEN_PATH" "$CPP_SRC" -o "$CPP_BIN" || exit 1
}

show_help() {
    echo "Usage: $0 [-n NUM] [-f FILE] [-m METHOD] [-c] [-h]"
    echo "  -c        Compile C++ code before running"
    echo "  -h        Show this help"
    exit 0
}

n=1
method="$DEFAULT_METHOD"
compile=0
data_file="data.txt"

while getopts "n:f:m:ch" opt; do
    case $opt in
        c) compile=1 ;;
        h) show_help ;;
        *) exit 1 ;;
    esac
done

if ! command -v g++ &>/dev/null; then
    echo "Error: g++ not found!"
    exit 1
fi

if [ $compile -eq 1 ] || [ ! -f "$CPP_BIN" ]; then
    compile_cpp
fi

