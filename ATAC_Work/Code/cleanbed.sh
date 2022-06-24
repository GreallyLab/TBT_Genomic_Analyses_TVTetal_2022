#$ -S /bin/bash
#$ -cwd
#$ -N shiftbed
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in AO4*_shifted.bed
  do
    echo ${f}
    awk '{if ($1~"chr") print $0; else print "chr"$0}' ${f} | awk '{if ($2>0) print $0; else print $1"\t"0"\t"$3"\t"$4"\t"$5"\t"$6}' > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${f%.bed}_chr_noNeg.bed

done
