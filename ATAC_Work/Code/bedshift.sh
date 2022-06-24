#$ -S /bin/bash
#$ -cwd
#$ -N Bed_shift
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

#for f in  AO4*_standardtrim.paired.Umap.dedup.bam
#do
#ID=`basename ${f/_standardtrim.paired.Umap.dedup.bam/}`
#echo ${ID}
#SampleName="$(echo ${ID} | cut -d '-' -f1)"
#echo ${SampleName}
#qsub -S /bin/bash -N ${SampleName}_Shift -cwd -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -l h_vmem=32G -j y -pe smp 2 << EOF

#module load picard-tools/2.3.0/java.1.8.0_20
#module load picard/2.17.1/java.1.8.0_20
#module load samtools/1.9/gcc.7.1.0
#module load MACS2/2.1.0/python.2.7.8
#module load bedtools2/2.28.0/gcc.7.1.0

#samtools view -h -f 0x0040 -b /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${f} > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read1/${f%.bam}_read1.bam

#bedtools bamtobed -i /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read1/${f%.bam}_read1.bam > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${SampleName}.bed

#awk 'BEGIN {OFS = "\t"} ; {if (\$6 == "+") print \$1, \$2 + 4, \$3 + 4, \$4, \$5, \$6; else print \$1, \$2 - 5, \$3 - 5, \$4, \$5, \$6}' /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${SampleName}.bed > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${SampleName}_shifted.bed
#EOF
#done

############Rpeating for the second read in the pair so we can compare peak aclling between the 2 reads

for f in  *_standardtrim.paired.Umap.dedup.bam
do
ID=`basename ${f/_standardtrim.paired.Umap.dedup.bam/}`
echo ${ID}
SampleName="$(echo ${ID} | cut -d '-' -f1)"
echo ${SampleName}
qsub -S /bin/bash -N ${SampleName}_Shift -cwd -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -l h_vmem=16G -j y -pe smp 2 << EOF

module load picard-tools/2.3.0/java.1.8.0_20
module load picard/2.17.1/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0
module load MACS2/2.1.0/python.2.7.8
module load bedtools2/2.28.0/gcc.7.1.0

samtools view -h -f 0x0080 -@ 2 -b /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${f} > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read2/${f%.bam}_read2.bam

bedtools bamtobed -i /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read2/${f%.bam}_read2.bam > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read2_beds/${SampleName}_read2.bed

awk 'BEGIN {OFS = "\t"} ; {if (\$6 == "+") print \$1, \$2 + 4, \$3 + 4, \$4, \$5, \$6; else print \$1, \$2 - 5, \$3 - 5, \$4, \$5, \$6}' /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read2_beds/${SampleName}_read2.bed > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read2_beds/${SampleName}_read2_shifted.bed
EOF
done
