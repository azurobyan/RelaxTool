#!/bin/bash

# Автокомпиляция
if [[ "$1" == "-c" ]]; then
    echo "Compiling..."
    g++  brent_solver.cpp -std=c++17 -o brent_solver -O3 -I/usr/local/include
    exit 0
fi

# Обработка аргументов
PARAMS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            PARAMS+=("--config" "$2")
            shift 2
            ;;
        --a)
            PARAMS+=("--a" "$2")
            shift 2
            ;;
        --b)
            PARAMS+=("--b" "$2")
            shift 2
            ;;
        --tol)
            PARAMS+=("--tol" "$2")
            shift 2
            ;;
        --max_iter)
            PARAMS+=("--max_iter" "$2")
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Проверка файла коэффициентов
if [ ! -f "coeff_tmp.txt" ]; then
    echo "File coeff_tmp.txt not found!" >&2
    exit 1
fi

# Проверка исполняемого файла
if [ ! -f "./brent_solver" ]; then
    echo "Executable not found. Run with -c to compile." >&2
    exit 1
fi

# Запуск
./brent_solver "${ARGS[@]}"
