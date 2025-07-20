BEGIN {
    i=0;
} 
{
    mat[i]=$2;
    i++
} 
END {
    print ""
    printf "PARAM;"
    for(i=0;i<numOfChannel;i++){
        printf "PARAM#"i+1"SCL;"
    }
    print ""
    for(i=0;i<=numOfChannel;i++){
        printf mat[i]";"
    }
} 
