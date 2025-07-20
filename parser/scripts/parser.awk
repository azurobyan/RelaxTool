function abs(x){
    return sqrt(x^2);
}
# оценка вклада экспонент
function w_exp(a,b){
    sum=0;
    for (i in b) {
        sum+=abs(a[i]*exp(-1/b[i])-a[i]);
        max_exp=i;
    }
    for (i in b){
        a_w[i]=(a[i]*exp(-1/b[i])-a[i])/sum;
        if(abs(a_w[i])*100<50){
            b[i]=1000000;
        }
    }
}
function exp_sum(x,a,b){
    sum=a[0];
    for(i in b){
        sum+=a[i]*exp(-x/b[i]);
    }
    return sum;
}
function Time_Search(a,b,p){
    repeat=1;
    time=0;
    epsilon=0.01;
    for(i in b){
    }
    lvl=exp_sum(100,a,b)-exp_sum(0,a,b);
    lvl*=p;
    lvl+=exp_sum(0,a,b);
    x_0=0;
    print a[0]-lvl;
    for(i in b){
        print a[i], b[i];
    }
}

/Channel Number/&&num==$3 {calculateFlg=1; }
/Channel Number/&&num!=$3 {calculateFlg=0}
/a_0/&&calculateFlg==1 {a_0=$3;}
/a_1/&&calculateFlg==1 {a_1=$3; b_1=$5; num_exp=1}
/a_2/&&calculateFlg==1 {a_2=$3; b_2=$5; num_exp++}
/a_3/&&calculateFlg==1 {a_3=$3; b_3=$5; num_exp++}
/a_4/&&calculateFlg==1 {a_4=$3; b_4=$5; num_exp++}
/a_5/&&calculateFlg==1 {a_5=$3; b_5=$5; num_exp++}
/a_6/&&calculateFlg==1 {a_6=$3; b_6=$5; num_exp++}

END { 
    a[0]=a_0;
    if (num_exp>=1){a[1]=a_1;b[1]=b_1}
    if (num_exp>=2){a[2]=a_2;b[2]=b_2}
    if (num_exp>=3){a[3]=a_3;b[3]=b_3}
    if (num_exp>=4){a[4]=a_4;b[4]=b_4}
    if (num_exp>=5){a[5]=a_5;b[5]=b_5}
    if (num_exp>=6){a[6]=a_6;b[6]=b_6}
    w_exp(a,b);
    Time_Search(a,b,0.6321);
}
#   
#   
#   
#   
#   
#   
