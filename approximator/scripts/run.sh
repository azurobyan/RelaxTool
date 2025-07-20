#!/bin/bash

CONFIG_FILE="/etc/approximator/config.json"
REPORT_PATH=$(jq '.evaluation.report_file' $CONFIG_FILE | tr -d '"')
echo $REPORT_PATH
debug=false;

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --config FILE    Load parameters from JSON config"
    echo "  -n NUM               Number of exponents"
    echo "  -f FILE              Input data file"
    echo "  -m METHOD            Optimization method (nm/lm)"
    echo "  --plot-type TYPE     Visualization type (plot/bar/scatter/all)"
    echo "  --eval               Enable model evaluation"
    echo "  --save               Save visualization plot"
    echo "  -h, --help           Show this help"
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config) CONFIG_FILE="$2"; shift 2 ;;
            -n) export N_EXP="$2"; shift 2 ;;
            -f) export DATA_FILE="$2"; shift 2 ;;
            -m) export METHOD="$2"; shift 2 ;;
            --plot-type) export PLOT_TYPE="$2"; shift 2 ;;
            --eval) export EVAL=1; shift ;;
            --save) export SAVE=1; shift ;;
            -h|--help) show_help ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

run_python() {
    local args=()
    [[ -n $CONFIG_FILE ]] && args+=("-c" "$CONFIG_FILE")
    [[ -n $N_EXP ]] && args+=("-n" "$N_EXP")
    [[ -n $DATA_FILE ]] && args+=("-f" "$DATA_FILE")
    [[ -n $METHOD ]] && args+=("-m" "$METHOD")
    [[ -n $PLOT_TYPE ]] && args+=("--plot-type" "$PLOT_TYPE")
    [[ -n $EVAL ]] && args+=("--eval")
    [[ -n $SAVE ]] && args+=("--save")
    
    approximator_visualize "${args[@]}"
}

# Main
parse_arguments "$@"
run_python 
sed -n '/RESULTS_START/,/RESULTS_END/p' /tmp/exp_fit_temp.txt | grep -v 'RESULT' | awk 'BEGIN {print "Model exp"} NF==1 {print "a_0 = "$1} NF!=1 {print "a_"NR-1" = "$1, "\tb_"NR-1 "= "$2}'>> $REPORT_PATH 
    if ($debug); then
        cat $REPORT_PATH 
    fi  
rm /tmp/exp_fit_temp.txt
