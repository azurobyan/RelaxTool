#!/bin/bash
path_in="/var/lib/relaxtool/input"
path_out="/var/lib/relaxtool/output"
scripts_path="/usr/local/share/approximator/scripts/"
file=$path_in/data_approximator.txt;
resultPath=$path_out/report_compare.txt;
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
    max=$(awk '{a=$2} END {print a}' $file);
    min=$(awk 'BEGIN {flg=1} flg==1 {print $2; flg=0}' $file);
    echo "max: "$max
    echo "min: "$min
    awk -v min=$min -v max=$max 'BEGIN {print "RESPONSE:", (max-min)/(min+0.001);}' >> $resultPath;
fi 
min=$(awk -v opt=0 -f $scripts_path/MaxMinSearch.awk $file);
awk -v m=$min '{print $1,$2-m;}' $file > /tmp/data_norm.txt
cat /tmp/data_norm.txt >  $file;
max=$(awk -v opt=1 -f $scripts_path/MaxMinSearch.awk $file);
awk -v M=$max '{print $1, $2/M;}' $file > /tmp/data_norm.txt
cat /tmp/data_norm.txt >  $file;

rm /tmp/data_norm.txt;
