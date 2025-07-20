BEGIN {
    print "[";
    start_flg=1;
}
/Materials/ {
    for(i=2;i<=NF;i++){
        mat[$i]=mat[$i]","i
    }
} 
/T_Pulse#/ {
    op=$1;
    split(op,num,/#/);
    for(i in mat) {
        if (start_flg==1){
            print "\t{";
            start_flg=0;
        } else {
            print "\t},"
            print "\t{";
        }
        
        print "\t\t\"Title\": \""i"_Pulse-"num[2]"\",";
        print "\t\t\"Data\": {"
        split( mat[i],chn,/,/); 
        printf "\t\t\t\"xData\": ["
        for(i1  in chn) {
            if (i1!=1){
                printf chn[i1]-1",";
            }
        }
        print "],"
        printf "\t\t\t\"yData\": ["
        for(i1  in chn) {
            if (i1!=1){
                printf $chn[i1]",";
            }
        } 
        print "]"
        print "\t\t\t}"
    }
}
END {
    print "\t}";
    print "]";
}
