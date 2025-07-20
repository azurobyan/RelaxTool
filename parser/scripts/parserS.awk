
/Channel Number/&&num==$3 {calculateFlg=1; }
/Channel Number/&&num!=$3 {calculateFlg=0}
/RES/&&calculateFlg==1 {print $0}
