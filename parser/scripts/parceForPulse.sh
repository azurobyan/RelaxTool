output_csv="/var/lib/relaxtool/output/$output_csv";
maxStr=$(awk -F ';'  '/T_/ {a=NF} END {print a}' $output_csv);
xDataStr=$(awk -F ';' 'BEGIN {i=1} /T_/ {printf i","; i++}' $output_csv);
echo "[";
for((num=2; num<=$maxStr;num++)) do
	awk -v num=$num -F ';' 'BEGIN {
	    print "\t{"
	}
	/Materials/{
	    print "\t\t\"Title\": \""$num"_channel-"num-1"\","; 
	    print "\t\t\"Data\": {"; 
	    printf "\t\t\t\"xData\": [PLACEHOLDER],\n\t\t\t\"yData\": ["
	}  
	/T_/{
	    printf $num","
	} 
	END {
	    printf "]\n"; 
	    print "\t\t\t}"; 
	    printf "\t}"}' $output_csv | 
	    sed 's/N\/A/-1/g' | 
	    sed "s/PLACEHOLDER/$xDataStr/g" | 
	    sed 's/,]/]/g'
        awk 'BEGIN {printf ",\n"}'
done

	awk -v num=$maxStr -F ';' 'BEGIN {
	    print "\t{"
	}
	/Materials/{
	    print "\t\t\"Title\": \""$num"_channel-"num-1"\","; 
	    print "\t\t\"Data\": {"; 
	    printf "\t\t\t\"xData\": [PLACEHOLDER],\n\t\t\t\"yData\": ["
	}  
	/T_/{
	    printf $num","
	} 
	END {
	    printf "]\n"; 
	    print "\t\t\t}"; 
	    printf "\t}"}' $output_csv | 
	    sed 's/N\/A/-1/g' | 
	    sed "s/PLACEHOLDER/$xDataStr/g" | 
	    sed 's/,]/]/g'
        awk 'BEGIN {print "\n]"}'
