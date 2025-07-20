#!/bin/bash
file_path="./tmp/approximator_tmp.txt"
numOfChannel=$(awk -F ',' 'NR==1  {print NF}' $file_path)

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -n                   Normalize"
    echo "  -s                   smooth"
    echo "  -d                   Debug"
    echo "  -r                   Calculate Response"
    echo "  -h, --help           Show this help"
    exit 0
}

debug=false;
normMode=false;
smoothMode=false;
CalculateResponse=false;
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n) normMode=true; shift ;;
            -s) smoothMode=true; shift ;;
            -d) debug=true  ; shift ;;
            -r) CalculateResponse=true  ; shift ;;
            -h|--help) show_help ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

parse_arguments "$@"
if ($debug); then 
    echo "debug on"
fi
for ((i=1;i<=$numOfChannel;i++)) do 
        num=$i;
        exp_num=1;
        best_num=$exp_num;
        awk -v channel=$i 'BEGIN {print "Channel Number:", channel;}' >>  results/report_compare.txt; 
        if ($smoothMode); then 
            awk '{print $2}' data.txt > ../smooth/data.txt;
        cd ../smooth/;
        ./smoother;
        
        python3 plotter.py config.json;
        cp plot.png ../v2/results/smooth_Resist$i.png
        awk '{print 0.045*NR,$1}' smoothed_data.txt > ../v2/data.txt ;
        cd ../v2;
        #awk '{for(i=2;i<=NF;i+=2){printf $i"   "}}'  data.txt
    fi 
        if ($normMode); then 
        if ($CalculateResponse); then 
                    awk -F ',' -v number=$num  '{print 0.045*NR,$number}'  $file_path > data.txt;
                    ./normalizer.sh -r;
        else
                    awk -F ',' -v number=$num  '{print 0.045*NR,$number}'  $file_path > data.txt;
                    ./normalizer.sh;
        fi
        else 
            awk -F ',' -v number=$num  '{print 0.045*NR,$number}'  $file_path > data.txt;
    fi 
        if ($smoothMode); then 
            awk '{print $2}' data.txt > ../smooth/data.txt;
        cd ../smooth/;
        ./smoother;
        
        python3 plotter.py config.json;
        cp plot.png ../v2/results/smooth$i.png
        awk '{print 0.045*NR,$1}' smoothed_data.txt > ../v2/data.txt ;
        cd ../v2;
    fi 
    if ($debug); then awk 'BEGIN {print "\n\n\nstart "}'; fi
        sed  s"/\"n_exponents\": ./\"n_exponents\": $exp_num/g"  config_template.json > config.json;
        ./run.sh;
        minR=$(awk '/R/ {print (1-$2^2)^2}' results/report.txt);
    if ($debug); then echo "R is: ${minR}"; awk 'BEGIN {print "end"}'; fi
        exp_num=$(( $exp_num+1 ));
        while (( $exp_num <= 3 )); do
        if ($debug); then
            awk 'BEGIN {print "\n\n\nstart "}';
                    echo $exp_num;
        fi
                sed  s"/\"n_exponents\": ./\"n_exponents\": $exp_num/g"  config_template.json > config.json;
                ./run.sh;
        
        if ($debug); then
            awk '/R/ {print "R is:", (1-$2^2)^2}' results/report.txt;
            echo $minR
        fi
                if [[ $(awk -v MIN=$minR '/R/&&(1-$2^2)^2<MIN {print "true"}' results/report.txt) ]]; then
                        best_num=$exp_num;
                        minR=$(awk '/R/ {print (1-$2^2)^2}' results/report.txt); 
            if ($debug); then
                echo "best num is: ${best_num}";
                echo "minR is: ${minR}";
            fi
                fi 
                exp_num=$(( $exp_num+1 ));
        if ($debug); then
            awk 'BEGIN {print "end"}';
        fi
        done 
        sed  s"/\"n_exponents\": ./\"n_exponents\": $best_num/g"  config_template.json > config.json;
    if ($debug); then
        awk 'BEGIN {print "\n\n\nstart "}';
        echo "best num is: ${best_num}";
    fi  
        ./run.sh;
    cat  results/report.txt >> results/report_compare.txt; 
    cp results/plot.png results/$i.png
    if ($debug); then
        awk 'BEGIN {print "end"}';
    fi
done
