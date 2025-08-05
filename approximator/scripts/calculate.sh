#!/bin/bash


path_in="/var/lib/relaxtool/input"
path_out="/var/lib/relaxtool/output"
file_path="/tmp/approximator_tmp.txt"
numOfChannel=$(awk -F ',' 'NR==1  {print NF}' $file_path)
scripts_path="/usr/local/share/approximator/scripts/"

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
if ($debug); then echo "debug on" ; fi
for ((i=1;i<=$numOfChannel;i++)) do 
        num=$i;
        exp_num=1;
        best_num=$exp_num;
        awk -v channel=$i 'BEGIN {print "Channel Number:", channel;}' >>  $path_out/report_compare.txt; 

        if ($smoothMode); then
		awk '{print $2}' $path_in/data_approximator.txt > $path_in/data_smoother.txt;
	        smoother;
	        smoother_plotter;
	        cp $path_out/smoother_plot.png $path_out/smooth_Resist$i.png
	        awk '{print 0.045*NR,$1}' $path_out/data_smoother.txt > $path_in/data_approximator.txt ;
    	fi 

        if ($normMode); then 
	        if ($CalculateResponse); then 
			awk -F ',' -v number=$num  '{print 0.045*NR,$number}'  $file_path > $path_in/data_approximator.txt;
	                $scripts_path/normalizer.sh -r;
	        else
	                awk -F ',' -v number=$num  '{print 0.045*NR,$number}'  $file_path > $path_in/data_approximator.txt;
	                $scripts_path/normalizer.sh;
	        fi
	else
	        awk -F ',' -v number=$num  '{print 0.045*NR,$number}'  $file_path > $path_in/data_approximator.txt;
    	fi 

	if ($smoothMode); then 
		awk '{print $2}' $path_in/data_approximator.txt > $path_in/data_smoother.txt;
	        smoother;
	        smoother_plotter;
	        cp $path_out/smoother_plot.png $path_out/smooth$i.png
	        awk '{print 0.045*NR,$1}' $path_out/data_smoother.txt > $path_in/data_approximator.txt ;
	fi 

	if ($debug); then awk 'BEGIN {print "\n\n\nstart "}'; fi
    
	$scripts_path/run.sh -n $exp_num; 
	minR=$(awk '/R/ {print (1-$2^2)^2}' $path_out/report.txt);

	if ($debug); then echo "R is: ${minR}"; awk 'BEGIN {print "end"}'; fi

	exp_num=$(( $exp_num+1 ));

	while (( $exp_num <= 3 )); do

	        if ($debug); then awk 'BEGIN {print "\n\n\nstart "}'; echo $exp_num; fi

		$scripts_path/run.sh -n $exp_num; 
        
	        if ($debug); then awk '/R/ {print "R is:", (1-$2^2)^2}' $path_out/report.txt; echo $minR; fi

                if [[ $(awk -v MIN=$minR '/R/&&(1-$2^2)^2<MIN {print "true"}' $path_out/report.txt) ]]; then

                        best_num=$exp_num;
                        minR=$(awk '/R/ {print (1-$2^2)^2}' $path_out/report.txt); 

            		if ($debug); then echo "best num is: ${best_num}"; echo "minR is: ${minR}"; fi

                fi 
                exp_num=$(( $exp_num+1 ));
        	if ($debug); then awk 'BEGIN {print "end"}'; fi

        done 

    	if ($debug); then awk 'BEGIN {print "\n\n\nstart "}'; echo "best num is: ${best_num}"; fi  

        $scripts_path/run.sh -n $best_num;
    	cat $path_out/report.txt >> $path_out/report_compare.txt; 
    	cp $path_out/plot.png $path_out/$i.png

    	if ($debug); then awk 'BEGIN {print "end"}'; fi
done
