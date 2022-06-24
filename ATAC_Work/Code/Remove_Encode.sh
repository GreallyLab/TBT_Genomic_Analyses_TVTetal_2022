#$ -S /bin/bash
#$ -cwd
#$ -N Remove_ENCODE
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y


for s in *_peaks_peaks.narrowPeak;
#for s in gm83_UMap_noMT_mkdup.bam;
do
PREFIX="$(echo ${s} | cut -d '_' -f1)"
#DIR='../Peaks_shift/'
#out="$DIR${SampleName}"
BLACKLIST='/gs/gsfs0/users/taythomp/Greally/References/Blacklists/hg38.blacklist.bed'
echo $s
echo ${PREFIX}

PEAK="${PREFIX}_peaks_peaks.narrowPeak"
FILTERED_PEAK="/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/${PREFIX}.narrowPeak.read1.filt.gz"


echo ${PEAK}
echo ${FILTERED_PEAK}

module load bedtools2/2.28.0/gcc.7.1.0

bedtools intersect -v -a ${PEAK} -b ${BLACKLIST} \
  | awk 'BEGIN{OFS="\t"} {if ($5>1000) $5=1000; print $0}' \
  | grep -P 'chr[0-9XY]+(?!_)' | gzip -nc > ${FILTERED_PEAK}
done
