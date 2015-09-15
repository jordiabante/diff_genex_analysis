#!/usr/bin/env bash
set -x 
../tophat2.sh -t 2 -o out -- reference/tophat2PE_test_ref2.fa \
    reads/reads_R1.fastq.gz \
    reads/reads_R2.fastq.gz
