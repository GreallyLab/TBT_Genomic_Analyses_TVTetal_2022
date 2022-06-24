#$ -S /bin/bash
#$ -cwd
#$ -N bed_merge
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y


for s in ED*.read1.chr.narrowPeak;
do
PREFIX="$(echo ${s} | cut -d '.' -f1)"
echo $s
echo ${PREFIX}


IDR="/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/IDR/ED_IDR_05_peaks.narrowPeak"
IDR_PEAK="${PREFIX}.IDR05"

# -u allow me to look at only the unique call in a that overlaps with a call in B. I neeed ot double check if there are multiple calls with the same start in a some way, or I can just leave it alone for now.  The -u option will do exactly this: if an one or more overlaps exists, the A feature is reported. Otherwise, nothing is reported.


echo ${IDR_PEAK}
echo ${IDR}
qsub -S /bin/bash -N ${PREFIX}_Intersect_sample_IDR -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
module load bedtools2/2.28.0/gcc.7.1.0

bedtools intersect -a ${s} -b ${IDR} -u \
|sort -k1,1 -k2,2n -k3,3n -s > Peak_files_overlappingIDR_Peaks/${IDR_PEAK}.sorted.narrowPeak
EOF
done
