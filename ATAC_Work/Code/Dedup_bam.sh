#$ -S /bin/bash
#$ -cwd
#$ -N Dedup
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y


### Picard duplicate removal Step 1
#for f in  *_standardtrim.paired.Umap.bam
#do
#ID=`basename ${f/_standardtrim.paired.Umap.bam/}`
#module load picard-tools/2.3.0/java.1.8.0_20
#echo ${ID}

#qsub -S /bin/bash -N ${ID}_dedup -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 4 -j y << EOF
#module load picard-tools/2.3.0/java.1.8.0_20
#module load picard/2.17.1/java.1.8.0_20
#module load samtools/1.9/gcc.7.1.0

#java -jar $(which picard.jar) MarkDuplicates INPUT=/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam OUTPUT=/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.mkdup.bam METRICS_FILE=/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/Picard_metrics/${ID}_standardtrim.paired.UMap.mkdup_metrics.txt REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=SILENT CREATE_INDEX=false PROGRAM_RECORD_ID=MarkDuplicates PROGRAM_GROUP_NAME=MarkDuplicates ASSUME_SORTED=true MAX_SEQUENCES_FOR_DISK_READ_ENDS_MAP=50000

#echo "${ID}_standardtrim.paired.Umap.mkdup.bam" >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt

#samtools flagstat Bams/${ID}_standardtrim.paired.Umap.mkdup.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt
#samtools index Bams/${ID}_standardtrim.paired.Umap.mkdup.bam
#EOF


### Beginning Samtools duplicate removal Removal part 2


for f in  AO4*_standardtrim.paired.Umap.mkdup.bam
do
ID=`basename ${f/_standardtrim.paired.Umap.mkdup.bam/}`
module load picard-tools/2.3.0/java.1.8.0_20
echo ${ID}

qsub -S /bin/bash -N ${ID}_rmdup -cwd -l h_vmem=12G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load picard/2.17.1/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

#samtools sort -@ 8 -n /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.bam -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.namesort.bam

#samtools fixmate -@ 8 -m /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.namesort.bam /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.bam

samtools sort -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.bam -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.sort.bam

samtools markdup -r -s -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.sort.bam /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.dedup.bam

echo "${ID}_standardtrim.paired.Umap.dedup.bam" >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/${ID}_flagstat.txt

samtools flagstat -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.dedup.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/${ID}_flagstat.txt

samtools index -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.dedup.bam

EOF

done
