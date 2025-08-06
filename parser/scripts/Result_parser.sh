#!/bin/bash
path=$1;





scripts_path="/usr/local/share/approximator/scripts/";
solver_path="/usr/local/bin/brent_solver";
configs_path="/etc/parser/";
config_file=$configs_path/"config_parser.json";
input_path="/var/lib/relaxtool/input/";
output_path="/var/lib/relaxtool/output/";
input_csv="/var/lib/relaxtool/input/input.csv";
output_csv="/var/lib/relaxtool/output/output.csv";

config_chip=$configs_path/chip$( \
	jq -r '.chip_number'\ 
	$config_file | 
	sed 's/\#/_/g').cfg;

max_Pulse=$( \ 
	ls $path 
	| awk -F '#' \
		'BEGIN {b=0} 
		b<$2 {b=$2} 
		END {print b}');


rm /tmp/tempRes.txt;
for (( i=1; i<=$max_Pulse; i++ )) do
    echo "Pulse " $i >> /tmp/tempRes.txt;
    input_path=$path/pulse\#$i/report_compare.txt;
    output_path=$path/report_time.csv;
    numOfChannel=$(awk '/Channel Number:/ {b=$3}  END {print b}' $input_path)
    if [[ i -eq 1 ]]; then 
	    awk	-v numOfChannel=$numOfChannel \
		-f $scripts_path/pTitle.awk \
		$config_chip | 
		sed '	    s/PARAM/Time_/g;
			    s/SCL/,s/g;
			    s/Time_/Time/
			    '  > /tmp/tempTime.csv;

	    awk -v numOfChannel=$numOfChannel \
		-f $scripts_path/pTitle.awk\ 
		 $config_chip | 
		 sed '	     s/PARAM/R/g;
			     s/SCL//g
			     ' > /tmp/tempR.csv;
	    awk -v numOfChannel=$numOfChannel \
		-f $scripts_path/pTitle.awk \
		$config_chip | 
		sed '	    s/PARAM/S/g;
			    s/SCL//g
			    ' > /tmp/tempS.csv;
    fi

    for (( i1=1; i1<=$numOfChannel; i1++ )) do
	    awk -v num=$i1 \
		-f $scripts_path/parser.awk \
		$input_path > $solver_path/coeff_tmp.txt;

        strR=$(awk -v num=$i1 \
		   -f $scripts_path/parserR.awk 
	            $input_path);
        strS=$(awk -v num=$i1 \
		   -f $scripts_path/parserS.awk 
	            $input_path);
        strRoot=$(brent_solver); 

        echo -e  $strRoot"\t"$strR"\t"$strS >> /tmp/tempRes.txt ;
    done
done

awk '	/Pulse/ {printf  "\n" $1"#"$2";"} 
	!/Pulse/ {printf 450*$2";"}' \  
	/tmp/tempRes.txt >> /tmp/tempTime.csv;

sed 's/;$//g' /tmp/tempTime.csv > $input_csv;
$scripts_path/parse_advanced_config.sh;
cp $output_csv $path/Time_report.csv;


awk '	/Pulse/ {printf  "\n" $1"#"$2";"} 
	!/Pulse/ {printf $4";"}' \
	       	/tmp/tempRes.txt >>  /tmp/tempR.csv;

sed 's/;$//g' /tmp/tempR.csv > $input_csv;
$scripts_path/parse_advanced_config.sh;
cp $output_csv $path/R_report.csv


awk '	/Pulse/ {printf  "\n" $1"#"$2";"}
	!/Pulse/ {printf $6";"}' \
	       	/tmp/tempRes.txt >>  /tmp/tempS.csv;  

sed 's/;$//g' /tmp/tempS.csv > $input_csv;
$scripts_path/parse_advanced_config.sh;
cp $output_csv $path/S_report.csv

###Calculate Time
StartDataString=$(awk -F  ';' \
	'(/Pulse/||/Purge/)&&/#1;/ {print NR}' /tmp/tempTime.csv);
EndDataString=$(awk -F  ';' \
	'(/Pulse/||/Purge/) {a=NR}END {print a}' /tmp/tempTime.csv);

	awk -F ';' -v \
	       	NumberString=1 \
	       	'NR==NumberString{print $0}' /tmp/tempTime.csv | 
		sed 's/;$//g' > $input_csv;
for ((i=2;i<$StartDataString;i++)) do 
	awk -F ';' -v \
	       	NumberString=$i \
		'NR==NumberString{print $0}' /tmp/tempTime.csv | 
		sed 's/;$//g' >> $input_csv;
done

for ((i=$StartDataString;i<=$EndDataString;i++)) do 
    awk -F ';' \
	    -v NumberString=$i \
	    'NR==NumberString{print $0}' /tmp/tempR.csv | 
	    sed 's/Pulse/R_Pulse/g' | 
	    sed 's/;$//g' >> $input_csv;
    awk -F ';' \
	    -v NumberString=$i \
	    'NR==NumberString{print $0}' /tmp/tempTime.csv  | 
	    sed 's/Pulse/T_Pulse/g' | 
	    sed 's/;$//g' >> $input_csv;
done
$scripts_path/parse_advanced_config.sh;
awk -F ';' \
	-f $scripts_path/parser_plot.awk \
	$output_csv | 
	sed 's/N\/A/-1/g' | 
	sed 's/,]/]/g' |  
	sed 's/Pulse/Pulse_Time/g' > $input_path/plot_data.json 

parser_plotter  $configs_path/config.json

cp -r /tmp/saved_data  $path
rm /tmp/saved_data/*.png
cp $output_csv $path/Time_avr_report.csv

$scripts_path/parceForPulse.sh  | 
	sed 's/channel/Time_Channel/g' > $input_path/plot_data.json 

parser_plotter  $configs_path/config.json
cp -r /tmp/saved_data  $path
rm /tmp/saved_data/*.png

awk -F ';' \
	-f CalculateAverPerChannel.awk \
	$output_csv > $path/Time_avr_report.csv


###Calculate S
StartDataString=$(awk -F  ';' \
	'(/Pulse/||/Purge/)&&/#1;/ {print NR}' \ 
	/tmp/tempS.csv);

EndDataString=$(awk -F 	';' \ 
	'(/Pulse/||/Purge/) {a=NR}
	END {print a}' \
	/tmp/tempS.csv);

awk -F ';' \
	-v  NumberString=1  \
	'NR==NumberString{print $0}'\
       	/tmp/tempS.csv | 
	sed 's/;$//g' > $input_csv;

for ((i=2;i<$StartDataString;i++)) do 
	awk -F ';' \
		-v  NumberString=$i \
		'NR==NumberString{print $0}'\ 
		/tmp/tempS.csv | 
		sed 's/;$//g' >> $input_csv;
done

for ((i=$StartDataString;i<=$EndDataString;i++)) do 
	awk -F ';' \
		-v NumberString=$i \
		'NR==NumberString{print $0}' \
		/tmp/tempR.csv | 
		sed 's/Pulse/R_Pulse/g' | 
		sed 's/;$//g' >> $input_csv;
			
	awk -F ';' \
		-v NumberString=$i \
		'NR==NumberString{print $0}' \
		/tmp/tempS.csv | 
		sed 's/Pulse/T_Pulse/g' | 
		sed 's/;$//g' >> $input_csv;
done

$scripts_path/parse_advanced_config.sh;
awk -F ';' \
	-f $scripts_path/parser_plot.awk \
	$output_csv | 
	sed 's/N\/A/-1/g' | 
	sed 's/,]/]/g' > $input_path/plot_data.json 

parser_plotter  $configs_path/config.json
cp -r /tmp/saved_data  $path
rm /tmp/saved_data/*.png
cp $output_csv $path/S_avr_report.csv

$scripts_path/parceForPulse.sh | 
	sed 's/channel/S_Channel/g' > $input_path/plot_data.json 

parser_plotter $configs_path/config.json
cp -r /tmp/saved_data  $path
rm /tmp/saved_data/*.png

awk -F ';' \
	-f $scripts_path/CalculateAverPerChannel.awk \
	$output_csv > $path/S_avr_report.csv
