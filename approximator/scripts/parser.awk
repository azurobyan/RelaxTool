
BEGIN {
    #pulseNum=2;
    ImpulsFlg=1;
    numOfImpuls=0;
}  
/water/&&ImpulsFlg==1 {
    numOfImpuls++;
    ImpulsFlg=0;
} 
/air/&&ImpulsFlg==0 {
    ImpulsFlg=1;
} 

numOfImpuls==pulseNum&&!ImpulsFlg {
    for(i=7;i<NF;i++){ 
        printf $i",";
    } 
    print " "
}
