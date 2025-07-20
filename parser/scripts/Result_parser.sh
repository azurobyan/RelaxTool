#!/bin/bash
begin_path=$(pwd);
solver_path="/usr/local/bin/brent_solver";
config_file="config.json"
config_chip=./chip$(jq -r '.chip_number' config.json | sed 's/\#/_/g').cfg 
input_csv="input.csv"
output_csv="output.csv"
path=$1;
max_Pulse=$(ls $path | awk -F '#' 'BEGIN {b=0} b<$2 {b=$2} END {print b}');


rm tempRes.txt;
for (( i=1; i<=$max_Pulse; i++ )) do
    echo "Pulse " $i >> tempRes.txt;
    input_path=$path/pulse\#$i/report_compare.txt 
    output_path=$path/report_time.csv ;
    numOfChannel=$(awk '/Channel Number:/ {b=$3}  END {print b}' $input_path)
    if [[ i -eq 1 ]]; then 
        awk -v numOfChannel=$numOfChannel -f pTitle.awk $config_chip | sed 's/PARAM/Time_/g;s/SCL/,s/g;s/Time_/Time/'  > tempTime.csv
        awk -v numOfChannel=$numOfChannel -f pTitle.awk $config_chip | sed 's/PARAM/R/g;s/SCL//g'       > tempR.csv
        awk -v numOfChannel=$numOfChannel -f pTitle.awk $config_chip | sed 's/PARAM/S/g;s/SCL//g'       > tempS.csv
    fi
    for (( i1=1; i1<=$numOfChannel; i1++ )) do
        awk -v num=$i1 -f parser.awk $input_path > $solver_path/coeff_tmp.txt;
        strR=$(awk -v num=$i1 -f parserR.awk $input_path);
        strS=$(awk -v num=$i1 -f parserS.awk $input_path);
        cd $solver_path;
        strRoot=$(./brent_solver) 
        cd $begin_path;
        echo -e  $strRoot"\t"$strR"\t"$strS >> tempRes.txt 
    done
done

awk '/Pulse/ {printf  "\n" $1"#"$2";"} !/Pulse/ {printf 450*$2";"}' tempRes.txt >> tempTime.csv
sed 's/;$//g' tempTime.csv > $input_csv;
./parse_advanced_config.sh;
cp $output_csv $path/Time_report.csv

awk '/Pulse/ {printf  "\n" $1"#"$2";"} !/Pulse/ {printf $4";"}'  tempRes.txt >>  tempR.csv;          #| sed "s/pulse/pulse#$i/g" >> $output_path ;
sed 's/;$//g' tempR.csv > $input_csv;
./parse_advanced_config.sh;
cp $output_csv $path/R_report.csv

awk '/Pulse/ {printf  "\n" $1"#"$2";"} !/Pulse/ {printf $6";"}'  tempRes.txt >>  tempS.csv;          #| sed "s/pulse/pulse#$i/g" >> $output_path ;
sed 's/;$//g' tempS.csv > $input_csv;
./parse_advanced_config.sh;
cp $output_csv $path/S_report.csv

###Calculate Time
StartDataString=$(awk -F  ';' '(/Pulse/||/Purge/)&&/#1;/ {print NR}' tempTime.csv);
EndDataString=$(awk -F  ';' '(/Pulse/||/Purge/) {a=NR}END {print a}' tempTime.csv);
    awk -F ';' -v  NumberString=1  'NR==NumberString{print $0}' tempTime.csv | sed 's/;$//g' > $input_csv;
for ((i=2;i<$StartDataString;i++)) do 
    awk -F ';' -v  NumberString=$i 'NR==NumberString{print $0}' tempTime.csv | sed 's/;$//g' >> $input_csv;
done

for ((i=$StartDataString;i<=$EndDataString;i++)) do 
    awk -F ';' -v NumberString=$i 'NR==NumberString{print $0}' tempR.csv     | sed 's/Pulse/R_Pulse/g' | sed 's/;$//g' >> $input_csv;
    awk -F ';' -v NumberString=$i 'NR==NumberString{print $0}' tempTime.csv  | sed 's/Pulse/T_Pulse/g' | sed 's/;$//g' >> $input_csv;
done
./parse_advanced_config.sh;
awk -F ';' -f parser_plot.awk output.csv | sed 's/N\/A/-1/g' | sed 's/,]/]/g' |  sed 's/Pulse/Pulse_Time/g' > ./plotter/plot_data.json 
cd plotter
sed  '/xlabel/ s/TEMPLATE/Channel Number/g; /ylabel/ s/TEMPLATE/Time, s/g' config_template.json > config.json;
python3 plotter.py config.json
cd ..
cp -r ./plotter/saved_data  $path
rm ./plotter/saved_data/*.png
cp $output_csv $path/Time_avr_report.csv
./parceForPulse.sh  | sed 's/channel/Time_Channel/g' > ./plotter/plot_data.json 
cd plotter
sed  '/xlabel/ s/TEMPLATE/Pulse Number/g; /ylabel/ s/TEMPLATE/Time, s/g' config_template.json > config.json;
python3 plotter.py config.json
cd ..
cp -r ./plotter/saved_data  $path
rm ./plotter/saved_data/*.png
awk -F ';' -f CalculateAverPerChannel.awk $output_csv > $path/Time_avr_report.csv






###Calculate S
StartDataString=$(awk -F  ';' '(/Pulse/||/Purge/)&&/#1;/ {print NR}' tempS.csv);
EndDataString=$(awk -F  ';' '(/Pulse/||/Purge/) {a=NR}END {print a}' tempS.csv);
    awk -F ';' -v  NumberString=1  'NR==NumberString{print $0}' tempS.csv | sed 's/;$//g' > $input_csv;
for ((i=2;i<$StartDataString;i++)) do 
    awk -F ';' -v  NumberString=$i 'NR==NumberString{print $0}' tempS.csv | sed 's/;$//g' >> $input_csv;
done

for ((i=$StartDataString;i<=$EndDataString;i++)) do 
    awk -F ';' -v NumberString=$i 'NR==NumberString{print $0}' tempR.csv | sed 's/Pulse/R_Pulse/g' | sed 's/;$//g' >> $input_csv;
    awk -F ';' -v NumberString=$i 'NR==NumberString{print $0}' tempS.csv | sed 's/Pulse/T_Pulse/g' | sed 's/;$//g' >> $input_csv;
done
./parse_advanced_config.sh;
awk -F ';' -f parser_plot.awk output.csv | sed 's/N\/A/-1/g' | sed 's/,]/]/g' > ./plotter/plot_data.json 
cd plotter
sed  '/xlabel/ s/TEMPLATE/Channel Number/g; /ylabel/ s/TEMPLATE/S/g' config_template.json > config.json;
python3 plotter.py config.json
cd ..
cp -r ./plotter/saved_data  $path
rm ./plotter/saved_data/*.png
cp $output_csv $path/S_avr_report.csv
./parceForPulse.sh | sed 's/channel/S_Channel/g' > ./plotter/plot_data.json 
cd plotter
sed  '/xlabel/ s/TEMPLATE/Pulse Number/g; /ylabel/ s/TEMPLATE/S/g' config_template.json > config.json;
python3 plotter.py config.json
cd ..
cp -r ./plotter/saved_data  $path
rm ./plotter/saved_data/*.png
#rm tempTime.csv tempR.csv tempS.csv;
awk -F ';' -f CalculateAverPerChannel.awk $output_csv > $path/S_avr_report.csv
