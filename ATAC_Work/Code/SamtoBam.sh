#$ -S /bin/bash
#$ -cwd
#$ -N SAMtoBAM
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in *_standardtrim.sam
do
ID=`basename /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/SAMs/Standard_trimmed/${f/_standardtrim.sam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_SAMtoBAM -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools view -@ 8 -b /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/SAMs/Standard_trimmed/${ID}_standardtrim.sam > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/${ID}_standardtrim.paired.bam
EOF
done
