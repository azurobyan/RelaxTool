/Materials/ {
    max=NF;
    for(i=2;i<=NF;i++){
        a[i]=0;
        n[i]=0
    }
} 
/T_/{
    calculateFlg=1
    for(i=2;i<=NF;i++){
        if($i!~/N\/A/){
            a[i]+=$i; 
            n[i]+=1
        }
    }
} 

!/T_/&&(calculateFlg==1) {
    calculateFlg=0
    printf "Mean"
    for(i=2;i<=max;i++){
        if(n[i]!=0){
            printf ";"a[i]/n[i] 
        } 
        else{
            printf ";N/A"
        }
    }
    print ""
}

{print $0}
