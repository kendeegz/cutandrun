#!/bin/bash

while getopts d: options
do
case "$options"
in
d) A=${OPTARG};;
esac
done

directory=${A:-None}

if [ "$directory" == None ]
    then echo " "
         echo " "
         echo " "
         read directory
         echo " "
         echo " Your answer: $directory"
         echo " "
fi

for file in "$directory"/*.gz
do
    gunzip "$file"

    newfile = "${file::3}"

    bed_file="${directory}/annotations.bed"

    gff2bed < "$newfile" > "$bed_file"

    cut -f8 "$newfile" > fields.txt

    firstline=0

    declare -a ants

    while IFS= read -r line;
    do
        add=0
        count=0

        for item in "${ants[@]}"
        do
            if [ "$item" == "$line" ]
                then add=$(($add + 1))
            fi
            count=$(($count + 1))
        done

        if [ $add -eq $count ]
            then if [ $firstline -eq 0 ]
                     then ants+=("${line}")
                          echo "added $line"
                          firstline=$(($firstline + 1))
                          count=0
                          add=0
                     elif [ $add -gt 0 ]
                          then ants+=("${line}")
                          echo "added $line"
                          count=0
                          add=0
                 fi
        fi

    done <fields.txt

    annot_dir="${directory}/annotation_types"

    mkdir "$annot_dir"

    for item in "${ants[@]}"
    do

        filename="${annot_dir}/annotation_${item}.bed"

        awk '{ if($8 == $item) }' "$bed_file" > "$filename"

    done
done