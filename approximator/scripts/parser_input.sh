#!/bin/bash

#/Users/azsurobyan/Downloads/FullLearning/acetone_set"$set"/acetone_set"$set".srs
file_path=$1
result_path=$2

output_path="/var/lib/relaxtool/output"

scripts_path="/usr/local/share/approximator/scripts/"
for (( set=1;set<=1;set++ )) do
#file_path="../input_data/methanol_set"$set"/methanol_set"$set".srs" 
#results_path="../output_data"
#mkdir ./$results_path/$(awk -v str=$file_path 'BEGIN {split(str,arr,"/") ; print arr[3]}')
#results_path=($results_path/$(awk -v str=$file_path 'BEGIN {split(str,arr,"/") ; print arr[3]}'))
	maxnum=$(awk -f $scripts_path/calculateNumOfImpuls.awk $file_path);
    echo $maxnum	
	for (( var=1;var<=$maxnum;var++ )) do 
	    rm $output_path/*
	    sed 's/R /R_/g' $file_path | awk -v pulseNum=$var -f $scripts_path/parser.awk > /tmp/approximator_tmp.txt;
	    $scripts_path/calculate.sh -n -s -r >> /tmp/calculate.log
	    mkdir $result_path/pulse#$var
	    mkdir $result_path/pulse#$var/results
	    cp  $output_path/* $result_path/pulse#$var
	    echo $var"/"$maxnum
	done
done
