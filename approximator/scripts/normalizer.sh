#!/bin/bash
file="/Users/azsurobyan/Documents/GasSensing/CalculateExp/v2/data.txt"
resultPath="./results/report.txt"
CalculateResponse=false;

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -r                   Calculate Response"
    echo "  -h, --help           Show this help"
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r) CalculateResponse=true  ; shift ;;
            -h|--help) show_help ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

parse_arguments "$@"
if ($CalculateResponse); then 
    max=$(awk '{a=$2} END {print a}' $file) #(awk -v opt=0 -f MaxMinSearch.awk $file);
    min=$(awk 'BEGIN {flg=1} flg==1 {print $2; flg=0}' $file) #(awk -v opt=1 -f MaxMinSearch.awk $file);
    echo "max: "$max
    echo "min: "$min
    awk -v min=$min -v max=$max 'BEGIN {print "RESPONSE:", (max-min)/(min+0.001);}' >> results/report_compare.txt;
fi 
min=$(awk -v opt=0 -f MaxMinSearch.awk $file);
awk -v m=$min '{print $1,$2-m;}' $file > data_norm.txt
cat data_norm.txt >  $file;
max=$(awk -v opt=1 -f MaxMinSearch.awk $file);
awk -v M=$max '{print $1, $2/M;}' $file > data_norm.txt
cat data_norm.txt >  $file;

rm data_norm.txt;
