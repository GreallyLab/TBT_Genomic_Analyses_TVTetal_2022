#$ -S /bin/bash
#$ -cwd
#$ -N SortBAM
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  *_standardtrim.paired.bam
do
ID=`basename ${f/_standardtrim.paired.bam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_SortBAM -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools sort -@ 8 -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.sorted.bam /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/${ID}_standardtrim.paired.bam
EOF
done
