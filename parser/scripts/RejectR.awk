/Material/ {
    for(i=2;i<=NF;i++){
        material[$i]=material[$i]" "i;
    }
} 
$1=="Pulse#"Pulse {
    printf "R_"$1"\t";
    for(i in material){
        split(material[i],chan," ");
        for(i1 in chan){
            if($chan[i1]>0.85){
               flgR[chan[i1]]=1; 
               printf chan[i1]"_"flgR[chan[i1]]" "; 
            }
            else {
               flgR[chan[i1]]=0; 
               printf chan[i1]"_"flgR[chan[i1]]" "; 
            }
        }
    } 
    print ""
}

END {
    for(i in flgR){
        print i,flgR[i];
    }
}
