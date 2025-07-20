BEGIN {
    FS = ";"
    OFS = ";"
    header_printed = 0
    decimal_precision = 3
}

/^Materials/ {
    # Инициализация структур данных
    delete material_cols
    delete material_list
    material_count = 0
    
    # Обработка столбцов материалов
    for (col=2; col<=NF; col++) {
        material = $col
        if (!(material in material_cols)) {
            material_count++
            material_list[material_count] = material
        }
        # Добавляем номер столбца к материалу
        material_cols[material] = material_cols[material] ? material_cols[material] "," col : col
    }
    print $0
    next
}

(/^S/||/^Time/||/^R/)&&!/^R_/ {
    if (!header_printed) {
        print_header()
        header_printed = 1
    }
    print $0
    next
}
/^(R_Pulse|R_Purge)#[0-9]+/ {
    for(ri=2;ri<=NF;ri++){
        R_val[ri]=$ri;
    }
    R_operation = $1
    split(R_operation, R_op_parts, /_/)
    operation = R_op_parts[2]
    split(operation, op_parts, /#/)
    op_type = op_parts[1]
    op_number = op_parts[2] + 0
    op_key = op_type "#" op_number
    R_flg[op_key][material] = ""
    # Обработка данных для каждого материала
    for (mi=1; mi<=material_count; mi++) {
        material = material_list[mi]
        split(material_cols[material], cols, ",")
        
        sum_val = 0
        sum_sq = 0
        n = 0
        
        # Сбор данных из всех столбцов материала
        for (ci=1; ci<=length(cols); ci++) {
            col = cols[ci]
            value = $col
            
            if (value > 0.75) {
                R_flg[op_key][material] = R_flg[op_key][material]"Flg_1_Value_"col"_"
            } else{
                R_flg[op_key][material] = R_flg[op_key][material]"Flg_0_Value_"col"_"
            }
        }
        
    }
}

/^(T_Pulse|T_Purge)#[0-9]+/ {
    if (!header_printed) {
        print_header()
        header_printed = 1
    }
    
    # Печать исходной строки
    printf $1";"
    for(ri=2;ri<NF;ri++){
       if (R_val[ri]>=0.75){
            printf $ri";"
       }
        else {
            printf "N/A;"
        } 
    }
    if (R_val[NF]>=0.75){
        print $NF
    }
    else {
        print "N/A"
    } 
    
    # Парсинг операции
    T_operation = $1
    split(T_operation, T_op_parts, /_/)
    operation = T_op_parts[2]
    split(operation, op_parts, /#/)
    op_type = op_parts[1]
    op_number = op_parts[2] + 0
    op_key = op_type "#" op_number
    
    # Обработка данных для каждого материала
    for (mi=1; mi<=material_count; mi++) {
        material = material_list[mi]
        split(material_cols[material], cols, ",")
        
        sum_val = 0
        sum_sq = 0
        n = 0
        split(R_flg[op_key][material],sum_flg,/_/)
        # Сбор данных из всех столбцов материала
        for (ci=1; ci<=length(cols); ci++) {
            col = cols[ci]
            value = $col
            for(si=0;si<length(sum_flg)/4;si++){
                if (sum_flg[4+4*si]==col){
                    isntreject=sum_flg[2+4*si];
                }
            }
            gsub(/,/, ".", value)
            
            if (value ~ /^-?[0-9.]+$/) {
                if (isntreject==1){
	                num = value + 0
	                sum_val += num
	                sum_sq += num^2
	                n++
                }
            }
        }
        
        # Сохранение результатов
        if (n > 0) {
            avg = sum_val / n
            variance = (sum_sq - sum_val^2/n) / n
            stddev = sqrt(variance)
            result[op_key][material] = sprintf("%.*f ± %.*f", 
                decimal_precision, avg, 
                decimal_precision, stddev)
        } else {
            result[op_key][material] = "N/A"
        }
    }
}


/^(Pulse|Purge)#[0-9]+/ {
    if (!header_printed) {
        print_header()
        header_printed = 1
    }
    
    # Печать исходной строки
    print $0
    
    # Парсинг операции
    operation = $1
    split(operation, op_parts, /#/)
    op_type = op_parts[1]
    op_number = op_parts[2] + 0
    op_key = op_type "#" op_number
    
    # Обработка данных для каждого материала
    for (mi=1; mi<=material_count; mi++) {
        material = material_list[mi]
        split(material_cols[material], cols, ",")
        
        sum_val = 0
        sum_sq = 0
        n = 0
        
        # Сбор данных из всех столбцов материала
        for (ci=1; ci<=length(cols); ci++) {
            col = cols[ci]
            value = $col
            gsub(/,/, ".", value)
            
            if (value ~ /^-?[0-9.]+$/) {
                num = value + 0
                sum_val += num
                sum_sq += num^2
                n++
            }
        }
        
        # Сохранение результатов
        if (n > 0) {
            avg = sum_val / n
            variance = (sum_sq - sum_val^2/n) / n
            stddev = sqrt(variance)
            result[op_key][material] = sprintf("%.*f ± %.*f", 
                decimal_precision, avg, 
                decimal_precision, stddev)
        } else {
            result[op_key][material] = "N/A"
        }
    }
    next
}

!(/^(R_Pulse|R_Purge)#[0-9]+/||/^(T_Pulse|T_Purge)#[0-9]+/){
    # Печать остальных строк
    print $0
}


END {
    # Генерация сводной таблицы
    print ""
    print "AVERAGE_TIME_PER_MATERIAL;"
    header = ";;"
    for (mi=1; mi<=material_count; mi++) {
        header = header material_list[mi] ";"
    }
    print header
    
    # Сбор и сортировка операций
    delete operations
    for (op_key in result) {
        if (!(op_key in operations)) {
            split(op_key, parts, /#/)
            operations[op_key] = parts[1] "#" parts[2]
        }
    }
    
    # Сортировка операций
    n = asorti(operations, sorted_ops, "custom_sort")
    
    # Вывод результатов
    for (i=1; i<=n; i++) {
        op_key = sorted_ops[i]
        line = ";" op_key ";"
        for (mi=1; mi<=material_count; mi++) {
            material = material_list[mi]
            line = line result[op_key][material] ";"
        }
        print line
    }
}

function print_header() {
    print "Chip Number;Analyte;Date;Temperature;Humidity"
    print chip ";" analyte ";" date ";" temp ";" humidity
}

function custom_sort(i1, v1, i2, v2) {
    split(i1, a, /#/)
    split(i2, b, /#/)
    if (a[1] != b[1]) return (a[1] == "Pulse") ? -1 : 1
    return (a[2]+0) - (b[2]+0)
}

