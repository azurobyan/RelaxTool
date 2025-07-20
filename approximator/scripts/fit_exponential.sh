#!/bin/bash

DEFAULT_METHOD="lm"
CONFIG_FILE="/etc/approximator/config.json"
REPORT_PATH=$(jq '.evaluation.report_file' $CONFIG_FILE)

show_help() {
    echo "Usage: $0 [-n NUM] [-f FILE] [-m METHOD] [-c] [-h]"
    echo "  -n NUM    Number of exponents (default: 1)"
    echo "  -f FILE   Input data file (default: /var/lib/relaxtool/input/data_approximator.txt)"
    echo "  -m METHOD Optimization method: lm (Levenberg-Marquardt) or nm (Nelder-Mead)"
    echo "  -h        Show this help"
    exit 0
}

n=1
method="$DEFAULT_METHOD"
data_file="/var/lib/relaxtool/input/data_approximator.txt"

while getopts "n:f:m:ch" opt; do
    case $opt in
        n) n="$OPTARG" ;;
        f) data_file="$OPTARG" ;;
        m) method="$OPTARG" ;;
        h) show_help ;;
        *) exit 1 ;;
    esac
done

# Проверка метода
if [[ "$method" != "lm" && "$method" != "nm" ]]; then
    echo "Invalid method. Use 'lm' or 'nm'"
    exit 1
fi


if [ ! -f "$data_file" ]; then
    echo "Data file not found: $data_file"
    exit 1
fi

awk '
BEGIN { has_x = 0 }
{
    if (NF >= 2) { print $1, $2; has_x = 1 }
    else if (NF == 1) { print NR, $1 }
}
END { exit !has_x }' "$data_file" > .tmp_data || exit 1

m=$(wc -l < .tmp_data)
x=($(awk '{print $1}' .tmp_data))
y=($(awk '{print $2}' .tmp_data))
rm .tmp_data

# Передача параметров в C++ программу
{
    echo $m
    echo "${x[@]}"
    echo "${y[@]}"
    echo $n
} | exponential_fit "$method" > /tmp/exp_fit_temp.txt
cat /tmp/exp_fit_temp.txt
