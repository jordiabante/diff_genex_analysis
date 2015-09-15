#!/usr/bin/env bash
# ------------------------------------------------------------------------------
##The MIT License (MIT)
##
##Copyright (c) 2015 Jordi Abante
##
##Permission is hereby granted, free of charge, to any person obtaining a copy
##of this software and associated documentation files (the "Software"), to deal
##in the Software without restriction, including without limitation the rights
##to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##copies of the Software, and to permit persons to whom the Software is
##furnished to do so, subject to the following conditions:
##
##The above copyright notice and this permission notice shall be included in all
##copies or substantial portions of the Software.
##
##THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##SOFTWARE.
# ------------------------------------------------------------------------------
shopt -s extglob

abspath_script="$(readlink -f -e "$0")"
script_absdir="$(dirname "$abspath_script")"
script_name="$(basename "$0" .sh)"

# Find perl scripts
perl_script="${script_absdir}/perl/${script_name}.pl"

if [ $# -eq 0 ]
    then
        cat "$script_absdir/${script_name}_help.txt"
        exit 1
fi

TEMP=$(getopt -o hd:t:b: -l help,outdir:,threads:,bandwidth: -n "$script_name.sh" -- "$@")

if [ $? -ne 0 ] 
then
  echo "Terminating..." >&2
  exit -1
fi

eval set -- "$TEMP"

# Defaults
outdir="$PWD"
threads=2

# Options
while true
do
  case "$1" in
    -h|--help)
      cat "$script_absdir"/${script_name}_help.txt
      exit
      ;;  
    -d|--outdir)
      outdir="$2"
      shift 2
      ;;  
    -t|--threads)
      threads="$2"
      shift 2
      ;;  
    --) 
      shift
      break
      ;;  
    *)  
      echo "$script_name.sh:Internal error!"
      exit -1
      ;;  
  esac
done

# Start time
start_time="$(date +"%s")"

## I/O files
# Inputs
reference="$1"
read1="$2"
read2="$3"

# Reference
indexes_path="$BOWTIE2_INDEXES"
reference_path="$(readlink -f "$reference")"
reference_basename="$(basename "$reference")"
reference_prefix="${reference_basename%%.*}"
bowtie2_index="${indexes_path}/${reference_prefix}"

# Less common prefix
lcp="$(less_common_prefix.sh "$read1" "$read2")"
prefix="${lcp%_[rR]*}"

# Temp file
temp="${outdir}/${prefix}.tmp"

# Output
out_prefix="${outdir}/${prefix}"

# Output directory
mkdir -p "$outdir"

## Index generation and alignment
# Generate bowtie indexes
if [ ! -f "${bowtie2_index}.1.bt2" ];
then
    echo "$($date): Building bowtie indexes ..."
    bowtie2-build -fq "$reference_path" "$bowtie2_index" &>>1
else
    echo "$(date): Indexes for bowtie2 found in ${indexes_path}..."
fi

# Run tophat2
echo -e "$(date): Running tophat2 ..."
tophat2 -p "$threads" -o "$out_prefix" --tmp-dir "$temp" "$bowtie2_index" "$read1" "$read2"

# Time elapsed
end_time="$(date +"%s")"
echo "Time elapsed: $(( $end_time - $start_time )) s"

