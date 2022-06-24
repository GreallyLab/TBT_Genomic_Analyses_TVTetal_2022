#!/bin/bash
#$ -cwd
#$ -j y
#$ -N FastQC_Posttrim_unique
#$ -pe smp 4
#$ -l h_vmem=15G
#$ -S /bin/bash

for f in *.fq.gz
do
fileName=`basename ${f/.fq.gz/}`
module load FastQC/0.11.4/java.1.8.0_20

qsub -S /bin/bash -N ${fileName}_fastqc -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -pe smp 4 -j y << EOF
module load FastQC/0.11.4/java.1.8.0_20
fastqc -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/Post_trim_fastqc/unique_trim/ ${fileName}.fq.gz
EOF
done
