#!/bin/bash

#/Users/azsurobyan/Downloads/FullLearning/acetone_set"$set"/acetone_set"$set".srs
for (( set=1;set<=1;set++ )) do
	file_path="../input_data/methanol_set"$set"/methanol_set"$set".srs" 
	results_path="../output_data"
	mkdir ./$results_path/$(awk -v str=$file_path 'BEGIN {split(str,arr,"/") ; print arr[3]}')
	results_path=($results_path/$(awk -v str=$file_path 'BEGIN {split(str,arr,"/") ; print arr[3]}'))
	maxnum=$(awk -f calculateNumOfImpuls.awk $file_path);
    echo $maxnum	
	for (( var=1;var<=$maxnum;var++ )) do 
	    rm ./results/report_compare.txt;
	    rm ./results/*[0-9].png 
	    sed 's/R /R_/g' $file_path | awk -v pulseNum=$var -f parser.awk > /tmp/approximator_tmp.txt;
	    ./calculate.sh -n -s -r
	    mkdir $result_path/pulse#$var
	    cp -r ./results/ $results_path/pulse#$var
	done
done
