NR==1 {
    min=$2;
    max=$2;
}

$2>max {
    max=$2;
}
$2<min {
    min=$2;
}
END {
    if(opt==1){
        print max;
    }else if(opt==0){
        print min;
    }
}
