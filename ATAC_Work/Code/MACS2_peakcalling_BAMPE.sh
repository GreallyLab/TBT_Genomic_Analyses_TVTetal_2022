#$ -S /bin/bash
#$ -cwd
#$ -N Peakcall_Paired_end_calling
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for s in A*shifted_chr_noNeg.bed;
do
SampleName="$(echo ${s} | cut -d '_' -f1)"
DIR='/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/'

out="$DIR${SampleName}"
echo $s
echo $out

qsub -S /bin/bash -N ${SampleName}_Call_Peaks_BAMPE -cwd -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -l h_vmem=20G -j y -pe smp 4 << EOF
module load MACS2/2.1.0/python.2.7.8
#Jason's method
#macs2 callpeak --nomodel -t ${s} -n $out --nolambda -g 3e9 --keep-dup 'all' --slocal 10000 --call-summits
macs2 callpeak --nomodel --shift -100 --extsize 200 -t ${s} -n ${out}_peaks -f BAMPE -g 3e9 -q 0.01 --keep-dup all --call-summits --slocal 10000 -B --SPMR
EOF
done
