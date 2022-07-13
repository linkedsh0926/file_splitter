#!/bin/bash


show_usage() {
    echo "Usage: $0"
    echo "          -f <target_file>"
    echo "          [-c <split_count> | -s <split_size>] (Either)"
    echo "          -o <output_prefix> (Optional)"
}

while getopts "f:c:s:o:h" opt; do
    case $opt in
    f)
        target_file="$OPTARG"
        ;;
    c)
        split_count="$OPTARG"
        ;;
    s)
        split_size="$OPTARG"
        ;;
    o)
        output_prefix="$OPTARG"
        ;;
    h)
        show_usage
	exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument."
        exit 1
        ;;
    ?)
        echo "Invalid option: -$OPTARG"
        ;;

    esac
done

[ -z "${target_file}" ] && echo "Please specify a file path to split." && show_usage && exit 1
[ ! -z "${split_count}" -a ! -z "${split_size}" ] && echo "Please specify the number or size of split files, not both." && show_usage && exit 1
[ -z "${split_count}" -a -z "${split_size}" ] && echo "Please specify the number or size of split files." && show_usage && exit 1
[ -d "${target_file}" ] && echo "The given path is a directory. This tool only supports file splitting." && exit 1
[ ! -f "${target_file}" ] && echo "Target file does not exist." && exit 1
[ ! -z "${split_count}" -a -z "$(echo ${split_count} | grep -wE '[0-9]+')" ] && echo "The number of file splits must be a number, but ${split_count} is not a number." && exit 1
[ ! -z "${split_size}" -a -z "$(echo ${split_size} | grep -wE '[0-9]+')" ] && echo "The file split size must be a number, but ${split_size} is not a number." && exit 1
[ -z "${output_prefix}" ] && output_prefix="${target_file}_split_"

file_size=$(du -b ${target_file} | awk '{print $1}')
[ ${file_size} -lt 1024 ] && echo "The size of ${target_file} is less than 1KB. Do you really need to split this file?" && exit 1

[ ! -z "${split_count}" ] && split_size=$(echo | awk '{print int(('${file_size}' + '${split_count}' - 1) / '${split_count}')}')
[ ! -z "${split_size}" ] && split_count=$(echo | awk '{print int(('${file_size}' + '${split_size}' - 1) / '${split_size}')}')

echo "split_count=${split_count} split_size=${split_size}"

for i in $(seq 0 $(expr $split_count - 1)); do
    block_size=1024
    skipcount=$(expr $i \* ${split_size} / ${block_size})
    dd if=${target_file} bs=1024 count=`expr ${split_size} / ${block_size}` skip=$skipcount of=${output_prefix}$i || {
        echo "Some went wrong. Please check the error message above."
        exit 1
    }
done

echo "All done!"

