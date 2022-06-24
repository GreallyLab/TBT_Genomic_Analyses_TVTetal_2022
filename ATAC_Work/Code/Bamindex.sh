#$ -S /bin/bash
#$ -cwd
#$ -N Index_bam
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  *_standardtrim.paired.Umap.dedup_read1.bam
do
ID=`basename ${f/_standardtrim.paired.Umap.dedup_read1.bam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_IndexBAM -cwd -l h_vmem=8G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/  -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools index /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read1/${ID}_standardtrim.paired.Umap.dedup_read1.bam
EOF
done
