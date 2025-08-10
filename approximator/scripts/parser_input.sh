#!/bin/bash

output_path="/var/lib/relaxtool/output"
scripts_path="/usr/local/share/approximator/scripts/"
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -i, --input FILE        Input file: *.srs"
    echo "  -o, --output DIRECTORY  Output directory"
    echo "  -d,                     DEBUG Mode"
    echo "  -h, --help              Show this help"
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input) file_path="$2"; shift 2 ;;
	    -o|--output)  result_path="$2"; shift 2 ;;
	    -d) debug=true; shift 1 ;;
            -h|--help) show_help ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

debug=false;
parse_arguments "$@";
for (( set=1;set<=1;set++ )) do
	maxnum=$(awk -f $scripts_path/calculateNumOfImpuls.awk $file_path);
	for (( var=1;var<=$maxnum;var++ )) do 
	    rm $output_path/*
	    sed 's/R /R_/g' $file_path | awk -v pulseNum=$var -f $scripts_path/parser.awk > /tmp/approximator_tmp.txt;
	    if ($debug); then
		    $scripts_path/calculate.sh -n -s -r -d  | tee  /tmp/calculate.log;
	    else
		    $scripts_path/calculate.sh -n -s -r >> /tmp/calculate.log;
	    fi

	    mkdir $result_path/pulse#$var
	    cp  $output_path/* $result_path/pulse#$var
	    echo $var"/"$maxnum
	done
done
