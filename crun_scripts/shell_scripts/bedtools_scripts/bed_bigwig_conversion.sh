#!/bin/bash

#Use GETOPTS command to get the optional arguments from the user.
while getopts b:g:t: option
do
case "${option}"
in
b) A=${OPTARG};;
g) B=${OPTARG};;
t) D=${OPTARG};;
esac
done

# Use the default syntax to assign values to all variables the user does not
# input into the script.

bedgraph=${A:-None}
genome=${B:-None}
temp_files=${D:-None}

echo "==================================================================================== "
echo " "
echo " "
echo " Covnerting bedgraph files into BigWig files, which are used for plotting histograms."
echo " Original code can be found at https://gist.github.com/taoliu/2469050"
echo " "
echo " "
echo "==================================================================================== "

# If a bedgraph file (or directory) is not given, ask the user to direct
# the program to a bedgraph file/directory. If the user is converting multiple
# bedgraph files, then direct the program to the directory containing folders,
# each with bedgraph files for a specific experiment/sequencing set.
if [ "$bedgraph" == None ]
    then echo " Please input the path to the folder containing"
         echo " the sorted bedgraph file to be converted."
         echo "---------------------OR------------------------ "
         echo " If you wish to convert multiple bedgraph files,"
         echo " then input the path to folders containing the bedgraph files."
         echo " "
         echo " The option for analyzing multiple bedgraph files "
         echo " is intended for a directory containing folders, where each"
         echo " folder contains all results from an individual sequencing"
         echo " experiment. For an example of such a directory, refer to the"
         echo " cut_run_pipeline/multi_test directory."
         echo " "
         read bedgraph
         echo " "
         echo " Your answer: $bedgraph"
         echo " "
fi

# If the user did not give a threshold value for the minimum number of
# continuous bases required for a peak to be evaluated
if [ "$genome" == None ]
    # Then ask the user to provide that minimum threshold value.
    then echo " Please input the filepath to the genome file used for reference"
         echo " "
         echo " NOTE: If you have run the cut_run_pipeline_v1.sh, this file"
         echo " will be located in the folder containing all FASTA files used"
         echo " to make the bowtie2 index. For an example of this folder, see"
         echo " cut_run_pipeline/drosophila_genome"
         echo " "
         echo " (FORMAT: path/to/file.genome)"
         read genome
         echo " "
         echo " Your answer: $genome"
         echo " "
fi

# If the user did not provide a temporary file folder
if [ $temp_files == None ]
    # Then inform them of the temporary file folder creation
    # in the folder(s) with bedgraph files
    then if [ "${multi_align,,}" == yes ]
            then echo " A temporary file folder will be created at the "
                 echo " following locations:"
                 echo " "
                 for fold in "$bedgraph"/*
                 do
                     echo " ${fold}/temp_files"
                     mkdir "${bedgraph}/temp_files"
                 done
            else echo " A temporary file folder will be created at the "
                 echo " following location:"
                 echo " "
                 echo " ${bedgraph}/temp_files"

                 mkdir "${bedgraph}/temp_files"
         fi
fi


# First, loop over all of the folders in the given
# file directory
for fold in "$bedgraph"/*
    do
    # Second, loop over the bedgraph file within each folder.
    # If the cut_run_pipeline_v1.sh was used, then,
    # there are two .bg files in each folder: peaks and raw.
    for bg_file in "$fold"/*.bg
    do
        # This little loop splits the BAM file string
        # by a period, saves this as an array, then
        # loops over the items in the array. The first
        # item in the array is the filepath and the
        # name of the BAM file, and we use this to
        # to make all temporary files used during peak
        # calling.
        IFS="."
        read -ra ADDR <<< "$bg_file"
        count=0
        for path in "${ADDR[@]}"
        do
            if [ $count -eq 0 ]
                then bw_out="${path}.bw"
                     temp1="${path}_clip_step1.bg.clip"
                     temp2="${path}_sort_step2.bg.sort.clip"
                     count=$(($count + 1))
            fi
        done
        # Get the directory path to the BAM file
#        directory=$(dirname "$bam_file")
        # Make the string for the temporary file directory
#        temp_files="${directory}/temp_files"
        # Make the string for the name of the settings text file
#        settings="${directory}/peak_call_settings.txt"

        echo "==========================BEGIN================================"
        echo " "
        echo " "
        echo " "
        echo " bedtools slop -i ${bg_file} -g ${genome} -b 0 | bedClip stdin ${genome} ${temp1} "
        echo " "

        bedtools slop -i "${bg_file}" -g "${genome}" -b 0 | bedClip stdin "${genome}" "${temp1}"

        echo " "
        echo " "
        echo " "
        echo "==========================END=================================="

        echo "==========================BEGIN================================"
        echo " "
        echo " "
        echo " "
        echo " LC_COLLATE=C sort -k1,1 -k2,2n ${temp1}>${temp2}"
        echo " "

        LC_COLLATE=C sort -k1,1 -k2,2n "${temp1}">"${temp2}"

        echo " "
        echo " "
        echo " "
        echo "==========================END=================================="

        echo "==========================BEGIN================================"
        echo " "
        echo " "
        echo " "
        echo " bedGraphToBigWig ${temp2} ${genome} ${bw_out}"
        echo " "

        bedGraphToBigWig "${temp2}" "${genome}" "${bw_out}"

        echo " "
        echo " "
        echo " "
        echo "==========================END=================================="

        mv "${temp1}" "${temp2}" "${fold}/temp_files"

    done
done

echo "==============================================================="
echo " "
echo " "
echo " "
echo " Bedgraph conversion to BigWig format completed :) "
echo " Plotting is your next step"
echo " "
echo " "
echo " "
echo "==============================================================="
