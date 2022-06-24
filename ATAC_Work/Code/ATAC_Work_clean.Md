BBE####################Downloading_Data#####################
I am running this download from the Bulk_Experiements folder under Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/
```bash
qsub -S /bin/bash -cwd -j y -N Download_data -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -q highmem.q -l h_vmem=20G << EOF
wget -r -c ftp://X202SC21053476-Z01-F001:dzhmxhdg@usftp21.novogene.com:21/
EOF
```
### raw data will be kept in the usftp21.novogene.com:21 folder
############## Setting up folders/data ##############
# Directories
All directories are under the Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ folder where I will be working except for the Work and logs folder where all of my code and logs will be kept will be kept tha tis under Greally/MSC/
  1. MSC/Work
  2. MSC/logs
  3. raw_data_copy
  4. BAMs
  5. SAMs
  6. Quality_Reports
    7. Below the Quality_Reports I will add a FASTQC and MultiQC folders

# Copy data from protected raw area to manipulation area
##### Check download completion with md5sum
```
#Samples came with a "MD5.txt" file that I can use to check I will first need to concatinate them which I did manually since, then I made a complete MD5.tst file that is in the raw_data_copy folder

#Now copying on the local node to the raw data cop folder. I will also double check the size once I move them, running from usftp21.novogne.com/raw_data

qsub -S /bin/bash -cwd -j y -N cp_data -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -q highmem.q -l h_vmem=20G << EOF
cp CT5/*.gz -t ../../raw_data_copy/
cp CT6/*.gz -t ../../raw_data_copy/
cp D*/*.gz -t ../../raw_data_copy/
cp E*/*.gz -t ../../raw_data_copy/
EOF

md5sum -c MD5.txt

#on an interactive node I am running md5sum -c MD.txt to check the sums of all the transfered files.
```
############## Quality_Checking ################
I am going to run Multi QC on the raw data before I trim the data and before any alignment.
## Sequence Quality Check
Double check the download worked correctly and was not interrupted or altered.

script run in raw_data_copy folder:
```bash
qsub -S /bin/bash -cwd -j y -N MD5sumcheck -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -pe smp 8 -l h_vmem=16G << EOF
md5sum -c MD5.txt
EOF
```

#### Fast QC
Running FastQC before trimming to look at the data and comparing it to the output from the company:
shell script is called FastQC_Pretrim.sh
I ran the script from the raw_data_copy so I put the hard path to the shell script so I could keep -cwd as the working directory
```bash

bash /gs/gsfs0/users/taythomp/Greally/MSC/Work/FastQC_Pretrim.sh
#!/bin/bash
#$ -cwd
#$ -j y
#$ -N fastQC
#$ -pe smp 4
#$ -l h_vmem=15G
#$ -S /bin/bash

for f in *.fq.gz
do
fileName=`basename ${f/.fq.gz/}`
module load FastQC/0.11.4/java.1.8.0_20

qsub -S /bin/bash -N ${fileName}_fastqc -cwd -l h_vmem=15G -pe smp 4 -j y << EOF
module load FastQC/0.11.4/java.1.8.0_20
fastqc ${fileName}.fastq.gz

EOF
done
```
#### Multi QC
```bash
qsub -S /bin/bash -N Pre_trim_MultiQC -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -pe smp 8 -j y << EOF
module load python/3.7.3/gcc.4.4.7
multiqc -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/multiqc_data/ -n Pretrim_MQC /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/Pretrimmed_fastQC
EOF
```

Making a quick script to output the filenames without 1 or 2 so that I can use it for the pairing process
```bash
ls | cut -d "_" -f1,2,3,4 | awk '{print $0".fq.gz"}' | uniq > ../file_list.txt
```
################Trimming Data ######################
## Trim_Galore
Trim Galore[https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/]! is a wrapper script to automate quality and adapter trimming as well as quality control. This tool was created to make use of the Cutadapt adapter trimming tool and FastQC for the quality control once the trimming process is complete.

For ATAC-seq the adapters should be removed for accurate read alignment. There are several adapter removal tools like:
  1. Trim galore(wrapper of cutadapt)
  2. cutadapt
  3. AdapterRemoval v2
  4. Skewer
  5. trimmomatic
We will be using the program Trim galore[https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/] cause we use if for other protocols as well and it is one of the standards for this type of analysis, but the process is very simple.
code run through raw_data_copy. Should output data to trimmed data folders
```bash
sh /gs/gsfs0/users/taythomp/Greally/MSC/Work/ATAC_trim.sh
```
```bash

#$ -S /bin/bash
#$ -cwd
#$ -N Trimming
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=25G

#echo ${SGE_TASK_ID}
for f in *_1.fq.gz
do
ID=`basename ${f/_1.fq.gz/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}

module load FastQC/0.11.4/java.1.8.0_20
module load trim_galore/0.6.5
module load cutadapt/2.5/python.3.7.3

qsub -S /bin/bash -N ${ID}_trim -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load trim_galore/0.6.5
module load cutadapt/2.5/python.3.7.3
echo ${ID}
trim_galore --fastqc --paired ${ID}_1.fq.gz ${ID}_2.fq.gz --output /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/trimmed_data/

EOF
done
```
#### Trim galore Note:
Trim galore version 0.6.5 thought that cutadapt version 2.8 was older than a version 1 so I had to go back to version 2.5. There maybe updates to both trim_galore and cutadapt that account for this and may be better.
I ran trimgalore and it looks really nice but it wasn't able to autodetect the adapter sequence. I will think about retrimming with the exact adapter sequence. This will require me to create a file that has the adapters in the same order as the samples. Luckily the sequencing documentation for Novogene requires this. I will create a data frame with the names of each sample and the 5' and 3' adapters. This will take a minute to create so since the auto trimmed data looks good, I will continue through the pipeline for now with the autotrimmed data and then reassess.
I retrimmed the data using unique adapter sequences instead of the autodetection tool in the ATAC_trim_uniqueadapter.sh file under
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N Trimming
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=25G

#echo ${SGE_TASK_ID}
for ((f=1;f<=50;f++));
do
  ID=$(head -n $f /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)
  a1=$(head -n $f /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_i5_adapter.txt | tail -n 1)
  a2=$(head -n $f /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_i7_adapter.txt | tail -n 1)
  echo ${ID} ${a1} ${a2}
  #module load FastQC/0.11.4/java.1.8.0_20
  #module load trim_galore/0.6.5
  #module load cutadapt/2.5/python.3.7.3

qsub -S /bin/bash -N ${ID}_uniquetrim -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load trim_galore/0.6.5
module load cutadapt/2.5/python.3.7.3
echo ${ID} ${a1} ${a2}

trim_galore --adapter ${a1} --adapter2 ${a2} --paired ${ID}_1.fq.gz ${ID}_2.fq.gz --output /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/trimmed_data/unique_trim/

EOF
done
```
## Post Trim QC
Also Trimgalore was unable to run fastqc for the samples because I put the trimmed sample in thier own folder. So I will use the FastQC_Pretrim file from the trimmed_data folder to check the samples.
#### Fast QC
```bash
sh /gs/gsfs0/users/taythomp/Greally/MSC/Work/ATAC_Work/FastQC_Posttrim.sh
```
#### Multi QC

```bash
qsub -S /bin/bash -N Post_stnandard_trim_MultiQC -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -pe smp 8 -j y << EOF
module load python/3.7.3/gcc.4.4.7
multiqc -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/multiqc_data/ -n Posttrim_MQC_standard /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/Post_trim_fastqc /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/trimmed_data/standard_trim
EOF
```
Unique trim QC
```bash
qsub -S /bin/bash -N Post_unique_trim_MultiQC -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -pe smp 8 -j y << EOF
module load python/3.7.3/gcc.4.4.7
multiqc -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/multiqc_data/ -n Posttrim_MQC_unique /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/Post_trim_fastqc/unique_trim /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/trimmed_data/unique_trim
EOF
```



################################################
##############                 ###############
##############    Alignment    ###############
################################################
The main tools used for alignment are BWA and Bowtie2. I will be using BWA. For ATAC-seq it has been noted that the soft-clip strategy workd well for both aligners to allow the overhang of bases on both ends of the read to help improve the percent unique reads that map. For a quality purposes we want unique mapping rate >80% to classify our results as successful. and a minimum of ~ 50M reads for open chromatin detection and differntial analysis. If we wanted to perform quality TF footprinting 200M reads would be needed.


# Alignment
### BWA
As mentioned above I will be using BWA for my alignment. The greally lab has a common indexes folder on the HPC. I will be using the hg38_1000g folder which is the Human genome 38 from the 1000 genomes project. For the reference sequence i will use the Homo_sapiens_assembly38.fasta file.

The alignment file will be run from the trimmed data folder

```bash
sh /gs/gsfs0/users/taythomp/Greally/MSC/Work/ATAC_trim_uniqueadapter.sh
```
#### Alignment.sh script
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N BWA_Align
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=25G

for f in *_1.fq.gz
do
ID=`basename ${f/_1.fq.gz/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}

qsub -S /bin/bash -N ${ID}_BWA_Align -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0
bwa index /gs/gsfs0/users/greally-lab/indexes/hg38_1000g/Homo_sapiens_assembly38.fasta

bwa mem -M -t 4 /gs/gsfs0/users/greally-lab/indexes/hg38_1000g/Homo_sapiens_assembly38.fasta ${ID}_val_1.fq.gz ${ID}_val_2.fq.gz > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/SAMs/${ID}.sam

EOF
done
```
RUnning a test first from the standard trimmed Data
```bash
sh /gs/gsfs0/users/taythomp/Greally/MSC/Work/ATAC_Work/Alignment.sh
```
### Samtool manipulation
In order to check the aligned sequences I have to convert SAMs to BAMs.
### Convert SAMs to BAMs
Script name SamtoBam.sh

script to run : sh /gs/gsfs0/users/taythomp/Greally/MSC/Work/ATAC_Work/SamtoBam.sh
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N SAMtoBAM
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  *_standardtrim.sam
do
ID=`basename ${f/_standardtrim.sam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_SAMtoBAM -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools view -@ 4 -b gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/SAMs/Standard_trimmed/${ID}_standardtrim.sam > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/${ID}_standardtrim.paired.bam
EOF
done
```
### Sort BAMs
```bash
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
qsub -S /bin/bash -N ${ID}_SortBAM -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools sort -@ 4 -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/${ID}_standardtrim.paired.sorted.bam /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/${ID}_standardtrim.paired.bam
EOF
done

```
### index BAMs
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N Index_bam
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  *_standardtrim.paired.sorted.bam
do
ID=`basename ${f/_standardtrim.paired.sorted.bam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_IndexBAM -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools index /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.sorted.bam
EOF
done
```
### flagstat
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N flagstatBAM
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  *_standardtrim.paired.sorted.bam
do
ID=`basename ${f/_standardtrim.paired.sorted.bam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_flagstat -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools flagstat /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.sorted.bam
EOF
done
```


## Unique Mapping
There are multiple reads to filter out. Mitochondrial reads will need to be filtered out, unless the Omni-ATACseq protocol was used at the bench. Percentage of mt-DNA can be useful to indicate library quality, so after alignment, be sure to remove mitochondrial reads.


## Select only uniquely mapped reads and sort
samtools view -bq 1 -F 4 Sams/${SampleName}.sam | samtools sort -@ 9 - Bams/${SampleName}_UMap
echo "${f1%.sam}_UMap.bam" >> Flagstats/${SampleName}_flagstat.txt
samtools flagstat Bams/${SampleName}_UMap.bam >> Flagstats/${SampleName}_flagstat.txt
samtools index Bams/${SampleName}_UMap.bam

Unique_map.sh
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N Unique
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  E*_standardtrim.paired.sorted.bam
do
ID=`basename ${f/_standardtrim.paired.sorted.bam/}`


#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_unique -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools view -bq -F4 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.sorted.bam >/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam

##### This is a better unique mapping and cleaning script that also removes reads that have poor mapping quality. I did not run this one this time, but it might be better to remove poorly mapped reads here instead of later on during the ATACseqQC R script. Previous work did not from this lab did not remove low quality reads here, but some ATAC-seq pipelines do.
#bam output desired with MAPQ > 20(q20) and any unmapped reads(F4)
#samtools view -b -q 20 -F4 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.sorted.bam > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam##########

samtools sort -@ 9 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam

echo "${ID}_standardtrim.paired.Umap.bam" >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt

samtools flagstat /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_tri/${ID}_flagstat.txt

samtools index /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam
EOF
done
```
NOTE: NEED TO rerun the flagstat and index lines for the A files.
UniqueQC.sh below.
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N UniqueQC
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  A*_standardtrim.paired.sorted.bam
do
ID=`basename ${f/_standardtrim.paired.sorted.bam/}`


#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_uniqueqc -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

samtools flagstat /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_tri/${ID}_flagstat.txt

samtools index /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam
EOF
done

```


## Remove Mitochondrial Reads
It is important to remove mitochondrial unless like mentioned before you are performing Omni-ATAC.
### I am skipping this because the samples were isolated usint the OMNI protocol.
```bash
#Get a list of the reads that are not from mitochondiral chromosomes
samtools view Bams/${ID}_UMap.bam | awk '\$3~"chrM"{print \$1}' | uniq > ${ID}.read.list
#Remove the MT reads
java -jar $(which FilterSamReads.jar) I=Bams/${ID}_UMap.bam O=Bams/${ID}_UMap_noMT.bam READ_LIST_FILE=${ID}.read.list FILTER=excludeReadList
samtools index Bams/${f1%.sam}_UMap_rmChrM.bam
echo "${ID}_UMap_noMT.bam" >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt
samtools flagstat Bams/${ID}_UMap_noMT.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt
```
## Remove duplicates
PCR duplicates are exact copies of DNA fragments arising during the PCR amplification and are artifacts of the library preparation so they can interfere with biological signal of interests. They are removed during the analysis as seen below. The program used here is part of Picard's MarkDuplicates. Not sure about the MAX seeunce for disk reads. Picard says that this is an obsolete command

picard/sam/markduplicates/

```bash
#$ -S /bin/bash
#$ -cwd
#$ -N Dedup
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in  B*_standardtrim.paired.Umap.bam
do
ID=`basename ${f/_standardtrim.paired.Umap.bam/}`

#ID=$(head -n ${SGE_TASK_ID} /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/file_list.txt | tail -n 1)

echo ${ID}
qsub -S /bin/bash -N ${ID}_dedup -cwd -l h_vmem=20G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 6 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

#java -jar $(which picard.jar) MarkDuplicates INPUT=/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.bam OUTPUT=/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/${ID}_standardtrim.paired.Umap.mkdup.bam METRICS_FILE=/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/Picard_metrics/${ID}_standardtrim.paired.UMap.mkdup_metrics.txt REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=SILENT CREATE_INDEX=false PROGRAM_RECORD_ID=MarkDuplicates PROGRAM_GROUP_NAME=MarkDuplicates ASSUME_SORTED=true MAX_SEQUENCES_FOR_DISK_READ_ENDS_MAP=50000

#echo "${ID}_standardtrim.paired.Umap.mkdup.bam" >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt

#samtools flagstat Bams/${ID}_standardtrim.paired.Umap.mkdup.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/standard_trim/${ID}_flagstat.txt
#samtools index Bams/${ID}_standardtrim.paired.Umap.mkdup.bam
EOF
done
```

After marking PCR duplicates with picard tools, we also remove duplicates with samtools that have the same start and end. Both of these are in the same Dedup_bam.sh file. So just comment out the second half until you run the first half and then the oposite. Note the samrools dedup takes a while beacuse each sort takes a little bit of time.

Dedup_bam.sh:
```bash
for f in  AO4*_standardtrim.paired.Umap.mkdup.bam
do
ID=`basename ${f/_standardtrim.paired.Umap.mkdup.bam/}`
module load picard-tools/2.3.0/java.1.8.0_20
echo ${ID}

qsub -S /bin/bash -N ${ID}_rmdup -cwd -l h_vmem=12G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/ -pe smp 8 -j y << EOF
module load picard-tools/2.3.0/java.1.8.0_20
module load picard/2.17.1/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0

#Create name sorted bam
samtools sort -@ 8 -n /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.bam -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.namesort.bam

#Run fixmate to call markduplicates
samtools fixmate -@ 8 -m /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.namesort.bam /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.bam

#Position sort the fixmate called bams
samtools sort -@ 8 -n /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.bam -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.sort.bam

#Remove Duplicates using samtools markdups
samtools markdup -r -s -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.mkdup.fixmate.sort.bam /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.dedup.bam

##QC work to add the flagstat metrics to a standard output
echo "${ID}_standardtrim.paired.Umap.dedup.bam" >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/${ID}_flagstat.txt

#Run the flagstat QC metrics
samtools flagstat -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.dedup.bam >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat/${ID}_flagstat.txt

##Finally index the dedupped files.
samtools index -@ 8 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${ID}_standardtrim.paired.Umap.dedup.bam

EOF

done

####Below is Andrew's method for samtools dedup. rmdup is an obsolete program in samtools
#samtools sort Bams/${ID}_UMap_noMT_mkdup.bam -o Bams/${ID}_UMap_noMT_mkdup_sort.bam
#samtools rmdup Bams/${ID}_UMap_noMT_mkdup_sort.bam Bams/${ID}_UMap_noMT_mkdup_sort_rmdup
#mv Bams/${ID}_UMap_noMT_mkdup_sort_rmdup Bams/${ID}_UMap_noMT_mkdup_sort_rmdup.bam
#echo "${ID}_UMap_noMT_mkdup_sort_rmdup.bam" >> Flagstats/${ID}_flagstat.txt
#samtools flagstat Bams/${ID}_UMap_noMT_mkdup_sort_rmdup.bam >> Flagstats/${ID}_flagstat.txt
#samtools index Bams/${ID}_UMap_noMT_mkdup_sort_rmdup.bam
```
## Remove ENCODE sequence bias areas
The ENCODE blacklist, which we will now be refering to as the sequencing bias area is a set of regions in the human, mouse, etc. genome that have been marked as having errors, being highly unstructured or are just always high signal areas in sequencing experiments, this notmally due to the sequence itself being an are where certain things can bind, cut or overall are just common areas for technical artifacts in sequencing. The ENCODE[https://www.nature.com/articles/nature11247] project was designed to make an encyclopedia of DNA elements and in doing so people bbegan to notice there were areas of the genomic code that seemed enriched regaurdless of the experiment. This is how a gourp at Duke began making the ENCODE bias area[], which has since been updated from hg19 to hg38[https://www.nature.com/articles/s41598-019-45839-z], feel free to read more about this topic as it is important to understand why these regions are being removed. And you can download the bias area from these attached links: hg19[https://personal.broadinstitute.org/anshul/projects/encode/rawdata/blacklists/hg19-blacklist-README.pdf], hg38[https://www.encodeproject.org/annotations/ENCSR636HFF/]
```bash

#$ -S /bin/bash
#$ -cwd
#$ -N Remove_ENCODE
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y


for s in *_paired_dedup_merged.bam
#for s in gm83_UMap_noMT_mkdup.bam;
do
PREFIX="$(echo ${s} | cut -d '.' -f1)"
#DIR='../Peaks_shift/'
#out="$DIR${SampleName}"
BLACKLIST='/gs/gsfs0/users/taythomp/Greally/References/Blacklists/hg38.blacklist.bed'
echo $s
echo ${PREFIX}
#Define the output files.
PEAK="${PREFIX}_peaks_peaks.narrowPeak"
FILTERED_PEAK="/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read1/merged_reads/${PREFIX}.narrowPeak.read1.filt.gz"

echo ${PEAK}
echo ${FILTERED_PEAK}
#Begin the intersect for the shitlist and the peaks.
module load bedtools2/2.28.0/gcc.7.1.0
# intersect then take any scores that are greater than 1000 and turn them into 1000(not sure why)
bedtools intersect -v -a ${s} -b ${BLACKLIST} | gzip -nc > ${FILTERED_PEAK}
done
```

Once you have your blacklist files you can use bedops[https://bedops.readthedocs.io/en/latest/] to remove overlapping regions. You can also do this using samtools.

```bash
bedops/2.4.12/gcc.4.9.2
bedops -n -1 all_peaks.bed blacklist_regions.bed > filtered_peaks.bed

##Samtools Methods

samtools sort Bams/${ID}_UMap_noMT_mkdup.bam -o Bams/${ID}_UMap_noMT_mkdup_sort.bam
samtools markdup Bams/${ID}_UMap_noMT_mkdup_sort.bam Bams/${ID}_UMap_noMT_mkdup_sort_rmdup
mv Bams/${ID}_UMap_noMT_mkdup_sort_rmdup Bams/${ID}_UMap_noMT_mkdup_sort_rmdup.bam
echo "${ID}_UMap_noMT_mkdup_sort_rmdup.bam" >> Flagstats/${ID}_flagstat.txt
samtools flagstat Bams/${ID}_UMap_noMT_mkdup_sort_rmdup.bam >> Flagstats/${ID}_flagstat.txt
samtools index Bams/${ID}_UMap_noMT_mkdup_sort_rmdup.bam
```
# Post alignment MultiQC
```bash
qsub -S /bin/bash -N Post_Alignment_MultiQC -cwd -l h_vmem=15G -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -pe smp 8 -j y << EOF
module load python/3.7.3/gcc.4.4.7

multiqc -o /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/multiqc_data/ -n Post_align_dedup /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Quality_Reports/flagstat /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/trimmed_data/
EOF
```


##########################################
######## Post alignment QC ########
##########################################
Post alignment you can still use FastQC and MultiQC but additionaly i will be using ATACseqQC[https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-018-4559-3] to check my data.The bioconductor link for ATACseqQC is here[https://bioconductor.org/packages/release/bioc/html/ATACseqQC.html]


###########################################################
################### Peak Calling #########################
###########################################################

## MACS peak Calling
MACS2 utilizes a count based method to compare to a read distribution shape of your sample to a random background. It utilizes a poison based distribution as the default. There are other peak callers that also call assuming a poison distribution, mostly HOMER[http://homer.ucsd.edu/homer/ngs/peaks.html] which was used for this publication[https://www.sciencedirect.com/science/article/pii/S1097276510003667] and SICER/epic2[https://pubmed.ncbi.nlm.nih.gov/30923821/] which has been used a lot for CHIP-seq analysis and is really good at histone identificaiton[https://academic.oup.com/bioinformatics/article/25/15/1952/212783?login=true]. Other count-based Peak callers include ZINBA[https://genomebiology.biomedcentral.com/articles/10.1186/gb-2011-12-7-r67] which assumes a zero-inflated negative binomial distribution, F-seq and PeakDEck which look at the density of kernels to estimate peaks and SPP which utilizes a sliding window and has no base assumption for count density. There are also shape based peak callers. Finally HMMRATAC[https://pubmed.ncbi.nlm.nih.gov/31199868/] is built specifically for ATAC seq it uses multiple-markov model for ina semi-supervised machine learning approach for peak calling. It stands for "a Hidden Markov ModelR for ATAC-seq" that is supposed to help outperform other peak callers when running atac samples.  For ATAC-seq most people use MACS2 as it is the caller utilized by ENCODE in their pipeline. But it is always prudent to call peaks in more than one way and alwyas look at the program that you a re using. Some of these callers are not maintained by a lab or group and may be obsolete.

For this analysis I am using MACS2 but MACS3 became available in march of 2021 and will probably be the tool need in the future. The peak calling should be the same as the manual page for MACS2 and MACS3 are the same.


#### Shift the reads for peak calling


```bash
for f in  *_standardtrim.paired.Umap.dedup.bam
do
ID=`basename ${f/_standardtrim.paired.Umap.dedup.bam/}`
echo ${ID}
SampleName="$(echo ${ID} | cut -d '-' -f1)"
qsub -S /bin/bash -N ${SampleName}_Shift -cwd -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -l h_vmem=20G -j y -pe smp 4  << EOF

module load picard-tools/2.3.0/java.1.8.0_20
module load picard/2.17.1/java.1.8.0_20
module load samtools/1.9/gcc.7.1.0
module load MACS2/2.1.0/python.2.7.8
module load bedtools2/2.28.0/gcc.7.1.0


samtools view -h -f 0x0040 -b /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${f} > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${f%.bam}_read1.bam

bedtools bamtobed -i /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/${f%.bam}_read1.bam > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/${SampleName}.bed

awk 'BEGIN {OFS = "\t"} ; {if (\$6 == "+") print \$1, \$2 + 4, \$3 + 4, \$4, \$5, \$6; else print \$1, \$2 - 5, \$3 - 5, \$4, \$5, \$6}' /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/${SampleName}.bed > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/${SampleName}_shifted.bed
EOF
done
```

###### Rep 1
#mv gm78new* Unused_beds/
#mv gm78.bed Unused_beds/
#mv gm78_shifted.bed Unused_beds/
#mv gm83new* Unused_beds/
#mv gm83.bed Unused_beds/
#mv gm83_shifted.bed Unused_beds/
#mv gm87new* Unused_beds/
#mv gm87.bed Unused_beds/
#mv gm87_shifted.bed Unused_beds/
#mv gm92new* Unused_beds/
#mv gm92.bed Unused_beds/
#mv gm92_shifted.bed Unused_beds/
#mv gm93new* Unused_beds/
#mv gm93.bed Unused_beds/
#mv gm93_shifted.bed Unused_beds/


###### Rep 2
#mv gm82new* Unused_beds/
#mv gm82.bed Unused_beds/
#mv gm82_shifted.bed Unused_beds/
#mv gm83new* Unused_beds/
#mv gm83.bed Unused_beds/
#mv gm83_shifted.bed Unused_beds/
#mv gm92new* Unused_beds/
#mv gm92.bed Unused_beds/
#mv gm92_shifted.bed Unused_beds/
#mv gm93new* Unused_beds/
#mv gm93.bed Unused_beds/
#mv gm93_shifted.bed Unused_beds/


#### Clean the bed files
Not sure if I need to do this cleaning. I need to look at the header of some of my shifted files and see what they need to look like. I checked that the line counts before and after this step are the same and they are so I may not need to do this for my data, but it runs quickly so I am trying it anyway. Awk throws errors when I qsub it so I used an interactive node for the next few lines. Also this script will take the shifted bed files and grab only the samples that have a chromosome start.

cleanbed.sh:
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N cleanbed
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y

for f in B*_shifted.bed
  do
    echo ${f}
    awk '{if ($1~"chr") print $0; else print "chr"$0}' ${f} | awk '{if ($2>0) print $0; else print $1"\t"0"\t"$3"\t"$4"\t"$5"\t"$6}' > /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${f%.bed}_chr_noNeg.bed

done
```
All output files will end with _shifted_chr_nNeg.bed from the previous command. This ends the bed manipulations the next step is to call peaks on all the samples.

## Replicates
I am going to seperate the beds into Replicates and then also create a


##############################################################
##########                                        ############
##########        Peak calling Command             ###########
##############################################################

The information about macs2 peakcall funtion are here[https://github.com/macs3-project/MACS/blob/master/docs/callpeak.md] it has all of the explainations for the options when calling peaks.

MACS2_peackcalling.sh:
```bash
for s in *shifted_chr_noNeg.bed;
do
SampleName="$(echo ${s} | cut -d '_' -f1)"
DIR='/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/'

out="$DIR${SampleName}"
echo $s
echo $out

qsub -S /bin/bash -N ${SampleName}_Call_Peaks -cwd -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -l h_vmem=20G -j y -pe smp 4 << EOF
module load MACS2/2.1.0/python.2.7.8
#Jason's method

macs2 callpeak --nomodel -t ${s} -n ${out}_peaks -f BED -g 3e9 -q 0.01 --keep-dup all --call-summits --slocal 10000 -B --SPMR
EOF
done
```

Other Example peak calling for ATA-seq:
```bash
macs2 callpeak -t {BAM or BED files} -n {NAME} --outdir {OUTDIR} -f {BAM|BED} -g hs -q 0.01 --nomodel --shift -75 --extsize 150 --keep-dup all -B --SPMR
```
The code below has more parameters for specifying the actual size of the fragments that it will keep. This is a common commmand used when calloing peaks for ATAC-seq in protocoals like these:
  1. ATAC-peak calling forum[https://github.com/macs3-project/MACS/discussions/435]
  2. ENCODE peak calling[https://www.encodeproject.org/documents/c008d7bd-5d60-4a23-a833-67c5dfab006a/@@download/attachment/ATACSeqPipeline.pdf]
  3. Harvard-ATAC-Guidelines[https://informatics.fas.harvard.edu/atac-seq-guidelines.html]
  4. Harvard-ATAC-


```bash
for s in Rep2_shifted.bed;
#for s in gm83_UMap_noMT_mkdup.bam;
do
SampleName="$(echo ${s} | cut -d '_' -f1)"
DIR='../Peaks_shift/'
#DIR2='../Peaks_PE_shift/'
out="$DIR${SampleName}"
# outPE="$DIR2${SampleName}_BAMPE"
echo $out
echo $s
qsub -S /bin/bash -N ${SampleName}_Call_Peaks -cwd -q highmem.q -l h_vmem=40G -j y << EOF
module load MACS2/2.1.0/python.2.7.8
#Jason's method
macs2 callpeak --nomodel -t ${s} -n $out --nolambda -g 3e9 --keep-dup 'all' --slocal 10000 --call-summits
EOF
done
```

###############################################
########       Peak calling QC    #############
###############################################
After calling peaks but before I can analyze differentially expressexed regions I need to do a few things. Those include:
    1. Removing ENCODE blacklist peak regions
    2. Repeat peak calling on replicates(read2 files then intersecting)
    3. OPTIONAL: Call peaks with SPP(sliding window based peak caller)
    4. OPTIONAL: Call peaks with HMMRATAC(newer tool specifically for ATAC analysis)
    5. OPTIONAL: Call peaks with Grenich[https://github.com/jsh58/Genrich] this is suggested from the Harvard-ATAC-Guidelines[https://informatics.fas.harvard.edu/atac-seq-guidelines.html]
    5. Call IDR on all pairs of replicates
    6. Get FRiP
  After All of this is done I will then use the output files for downstream analysis to do things like read out count files into DEseq2 for differetially expressed areas. Calling FriP(Fragment of Reads in Peaks) like Andrew did in the Frip section of this code. I can also pool all the replicates and then analyze the results based on each type of replicate pooling.
  Replicate pooling:
    1. By Technical replicate 1-2, 3-4, 5-6
    2. By Biological Replicate D1-6, T1-6, R1-6
# Remove ENCODE sites
###### ENCODE mappability consensus blacklist downloaded[http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeMapability/].

wgEncodeDacMapabilityConsensusExcludable.bed.gz from this website[http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeMapability/] to /home/greally-lab/indexes
Additional frequent mapping sites to remove are from the Mitr lab at Stanford from this website[http://mitra.stanford.edu/kundaje/akundaje/release/blacklists/]. This is also in  /home/greally-lab/indexes.


#### Sample code for black list removal using bedtools intersect
```bash
#Based on ENCODE script:
PEAK = "${PREFIX}.narrowPeak.gz"
FILTERED_PEAK = "${PREFIX}.narrowPeak.filt.gz"
bedtools intersect -v -a ${PEAK} -b ${BLACKLIST} \
 | awk 'BEGIN{OFS="\t"} {if ($5>1000) $5=1000; print $0}' \
 | grep -P 'chr[0-9XY]+(?!_)' | gzip -nc > ${FILTERED_PEAK}
```
This file must be run in an interactive node. The wildcard throws off the awk and grep funcitons. I am still trying to figure out how to validate that this is okay. But for now I am simply accepting it and I will use read 2 as well as a few other comparisons to determing false reads.

Remove_ENCODE.sh
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N Remove_ENCODE
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y


for s in E*_peaks_peaks.narrowPeak;
#for s in gm83_UMap_noMT_mkdup.bam;
do
PREFIX="$(echo ${s} | cut -d '_' -f1)"
#DIR='../Peaks_shift/'
#out="$DIR${SampleName}"
BLACKLIST='/gs/gsfs0/users/taythomp/Greally/References/Blacklists/hg38.blacklist.bed'
echo $s
echo ${PREFIX}
#Define the output files.
PEAK="${PREFIX}_peaks_peaks.narrowPeak"
FILTERED_PEAK="/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/${PREFIX}.narrowPeak.read1.filt.gz"

echo ${PEAK}
echo ${FILTERED_PEAK}
#Begin the intersect for the shitlist and the peaks.
module load bedtools2/2.28.0/gcc.7.1.0
# intersect then take any scores that are greater than 1000 and turn them into 1000(not sure why)
bedtools intersect -v -a ${PEAK} -b ${BLACKLIST} \
  | awk 'BEGIN{OFS="\t"} {if ($5>1000) $5=1000; print $0}' \
  | grep -P 'chr[0-9XY]+(?!_)' | gzip -nc > ${FILTERED_PEAK}
done

```

#Merging samples by day and coneistion
By merging samples by day and consition I will be able to rerun the peak calling and perform some analysis in a few different ways.
#### Checking quality of filtered reads

# Peak calling with SPP
SPP utilizes a sliding window and has no assumptions when looking for peaks accross the genome. it is still a count based peak caller, but it is a little less biased.
# Peak Calling with HMMRATAC

# Get the FRiP
All of this is done in an interactive node. This work is to check the relative fraction of reads are in peaks and the fraction of reads that are in the summits. This will tell us how good our ATAC-seq quality. In general FRiP scores correlate positively with the number of regions. To read more about FRiPs this article[https://pubmed.ncbi.nlm.nih.gov/22955991/] explains some of the QC for CHIP-seq that we can also use for ATAC-seq.

First we need to clean the peaks. and then we will create a file that will tell us the number of peaks that overlap between the cleaned narrowPeak file and the overall cleaned bed that has all of the reads.

```bash
#I have no idea what this code did to clean up my script but I ran it. I think it removes any rows that don't have numbers in teh second and third columns

for f1 in A*.narrowPeak.read1.filt;
do
  echo ${f1}
awk '!array[$2,$3]++' $f1 > ${f1%.narrowPeak.read1.filt}.read1.firstPeak.narrowPeak
done

#### Clean narrowPeak files
#This script removes peaks that done't call for
for f1 in *.read1.firstPeak.narrowPeak;
do
  echo ${f1}
awk '{if ($1~"chr") print $0; else print "chr"$0}' ${f1} > ${f1%.read1.firstPeak.narrowPeak}.read1.chr.narrowPeak
done

#I am going to remove the path from the names of my peaks in and then use the new files for my analysis.
for f1 in *.read1.chr.narrowPeak;
do
  SampleName="$(echo ${f1} | cut -d '.' -f1)"
  echo ${SampleName}
  echo ${f1}
awk -F "\t" -v OFS="\t" '{sub("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/","",$4);print}' ${f1} | awk '{printf "%s\t%d\t%d\t%2.3f\n" , $1,$2,$3,$5}' > ${SampleName}.read1.sorted.peaks.bdg
done

```


#########################
###FRIP AND FRIS SCORES
#########################
```bash
for f1 in *_peaks.narrowPeak;
do
  echo ${f1}
awk '!array[$2,$3]++' ${f1}
done
# Create Text file that has the number of Peaks callled for each file.
touch Peak_totals.txt

# example script to test awk '!array[$2,$3]++' CR5_peaks_peaks.narrowPeak

for f1 in *.read1.chr.narrowPeak
do
SampleName="$(echo ${f1} | cut -d '.' -f1)"
echo ${SampleName} >> Peak_totals.txt
echo ${f1}
wc -l ${f1} >> Peak_totals.txt
done



# I will calcularte the Fraction of reads in peaks from the FRiP.txt and the Peak_totals.txt files.


###Total reads

for f1 in *_shifted_chr_noNeg.bed
do
echo ${f1}
wc -l ${f1} >> /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/total_reads.txt
done

#create FRiP text file.
touch FriP.txt
#Load bedtools for the intersect
module load bedtools2/2.28.0/gcc.7.1.0

#Run a for loop to compare the complete cleaned and shifted bed file to the cleaned peak file.

for f1 in *.read1.chr.narrowPeak
do
SampleName="$(echo ${f1} | cut -d '.' -f1)"
echo ${SampleName} >> FriP.txt
echo ${f1}
bedtools intersect -a /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${SampleName}_*_shifted_chr_noNeg.bed -b ${f1} -u | wc -l >> FriP.txt
done


#### FRIP test
bedtools intersect -a /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/CR5_*_shifted_chr_noNeg.bed -b CR5.read1.chr.narrowPeak -u | wc -l | head -50
#### rep1
for f1 in Rep1_peaks_firstPeak_chr.narrowPeak
do
SampleName="$(echo ${f1} | cut -d '_' -f1)"
echo $SampleName >> FriP.txt
echo $f1
bedtools intersect -a ../Beds/${SampleName}_shifted.bed -b ${f1} -u | wc -l >> FriP.txt
done

# Get the FRiS
### clean up the summit files
for f1 in *_summits.bed;
do
  echo ${f1}

awk '{if ($1~"chr") print $0; else print "chr"$0}' ${f1} > ${f1%.bed}_chr.bed
done

### need to +/- 250 bp to each summit
for f1 in *_summits_chr.bed;
do
  echo ${f1}
awk '{if ($2-250 > 0) print $1"\t"$2-250"\t"$3+250"\t"$4"\t"$5; else print $1"\t0\t"$3+250"\t"$4"\t"$5}' ${f1} >${f1%.bed}_250.bed
done


# What about summits that overlap?
# for FRiS, we'll ignore
touch FRiS.txt
module load bedtools2/2.28.0/gcc.7.1.0
for f1 in *_summits_chr_250.bed
#for f1 in gm77_peaks_chr.narrowPeak;
do
SampleName="$(echo ${f1} | cut -d '_' -f1)"
echo ${SampleName} >> FRiS.txt
echo ${f1}
bedtools intersect -a /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/Beds/Read1_beds/${SampleName}_*_shifted_chr_noNeg.bed -b ${f1} -u | wc -l >> FRiS.txt
done
```

#TSS enrichment analysis
The Transcrioption Start Site(TSS) Enrichment Score is a signal to noise calculaiton. The reads around a reference set of TSSs and create an aggreagete distribution of reads centered on the TSS and extending 2 kb in either direction of the TSS. Then you nomalize this distribution by taking hte averad read depth in the 100bps at each of the ends and calclate the fold change at each position over the average read depth. The ATACSeqQC R package has this capability so I will be trying to run the amples through this to chack the Quality of my ATAC-seq work.



#IDR analysis
IDR time. The following code is based off of some things that Andrew did to get the IDR, but there are other ways that I will be looking into.

```bash
### to get IDR summits, it'll be tricky
cp Rep1_summits.bed ../../../Total_peak_analysis/
cp Rep2_summits.bed ../../../Total_peak_analysis/
### in total peak analysis
awk '{print $0"\t."}' Rep1_summits.bed > Rep1_summits_strand.bed
awk '{print $0"\t."}' Rep2_summits.bed > Rep2_summits_strand.bed

### Let's try with summit files
module load idr/2.0.2/python.3.4.1-atlas-3.11.30
python3 -c "import idr"
python3 -c "import matplotlib"
idr --samples Rep1_summits_strand.bed Rep2_summits_strand.bed --input-file-type bed --output-file replicates_summit_idr --output-file-type bed --plot

#### didn't work.. so doing it like this
#### first I'll get IDR peaks because IDR analysis will not work for summits.
### Need to call peaks without call-summit though

#for s in ../Rep1/Fastq/comb_reads/Beds/Rep1_shifted.bed;
for s in ../Replicates/FastQ/Beds/Rep2_shifted.bed;
do
SampleName="$(echo ${s} | cut -d '/' -f5 | cut -d '_' -f1)"
out="${SampleName}_rmdup"
echo $out
echo $s
done
qsub -S /bin/bash -N ${SampleName}_Call_Peaks -cwd -q highmem.q -l h_vmem=40G -j y << EOF
module load MACS2/2.1.0/python.2.7.8
#Jason's method
macs2 callpeak --nomodel -t ${s} -n $out --nolambda -g 3e9 --keep-dup 'all' --slocal 10000
EOF
done


## How consistent is the newly called non -call-summit peaks with the -call-summit peaks?

bedtools intersect -a Rep1_rmdup_peaks.narrowPeak -b ../Rep1/Fastq/comb_reads/Peaks_shift/Rep1_peaks_firstPeak.narrowPeak -wo | less
# yes, they're the exact same :)


#mv _rmdup_peaks.narrowPeak Rep2_rmdup_peaks.narrowPeak
#mv _rmdup_peaks.xls Rep2_rmdup_peaks.xls
#mv _rmdup_summits.bed Rep2_rmdup_summits.bed

module load idr/2.0.2/python.3.4.1-atlas-3.11.30
python3 -c "import idr"
python3 -c "import matplotlib"
idr --samples Rep1_rmdup_peaks.narrowPeak Rep2_rmdup_peaks.narrowPeak --input-file-type narrowPeak --output-file replicates_summit_idr --output-file-type narrowPeak --plot
awk '$5 > 540 {print $0}' replicates_summit_idr > replicates_summit_idr_05
wc -l replicates_summit_idr_05
###### 108,130 replicates_summit_idr_05

### then look at Get_summit_peak_nonspecific.R to get replicate_summit_peak_nonspecific.bed

# To get IDR summits of +/- 250 bp I will first get the 250 bp summits from the original replicate summit files where overlaps are the highest value
wc -l Rep2_summits_chr_250.bed
# 342333 Rep2_summits_chr_250.bed

bedtools merge -i Rep2_summits_chr_250.bed -c 4,5 -o collapse >  Rep2_summits_chr_250_merge.bed # 125,706

wc -l Rep2_summits_chr_250_merge.bed
# 286294 Rep2_summits_chr_250_merge.bed

## Do Rep 2 now ###
wc -l Rep1_summits_chr_250.bed
# 277,900 Rep1_summits_chr_250.bed
bedtools merge -i Rep1_summits_chr_250.bed -c 4,5 -o collapse >  Rep1_summits_chr_250_merge.bed # 125,706

wc -l Rep1_summits_chr_250_merge.bed
# 233,314 Rep1_summits_chr_250_merge.bed

## Now I need to intersect the noOver summits and intersect them with the IDR <.05 peaks

cp Rep1_summits_chr_250_noOver.bed ../../../../Total_peak_analysis/
cp Rep2_summits_chr_250_noOver.bed ../../../Total_peak_analysis/
############# ########
module load bedtools2
bedtools intersect -a Rep1_summits_chr_250_noOver.bed -b replicate_summit_peak_nonspecific.bed -u -f .5 > Rep1_summits_chr_250_noOver_idr.bed
wc -l Rep1_summits_chr_250_noOver_idr.bed
# 137,148
bedtools intersect -a Rep2_summits_chr_250_noOver.bed -b replicate_summit_peak_nonspecific.bed -u -f 0.5 > Rep2_summits_chr_250_noOver_idr.bed
wc -l Rep2_summits_chr_250_noOver_idr.bed
# 139,442

# add the summit as a column
awk '{print $0"\t"$2+250}' Rep1_summits_chr_250_noOver_idr.bed > Rep1_summits_chr_250_noOver_idr_fix.bed
awk '{print $0"\t"$2+250}' Rep2_summits_chr_250_noOver_idr.bed > Rep2_summits_chr_250_noOver_idr_fix.bed

# Now I need to merge the overlapping IDR summits
cat Rep1_summits_chr_250_noOver_idr_fix.bed Rep2_summits_chr_250_noOver_idr_fix.bed > Summit_idrPeak_chr_250_noOver.bed
bedtools sort -i Summit_idrPeak_chr_250_noOver.bed > Summit_idrPeak_chr_250_noOver_sort.bed
wc -l Summit_idrPeak_chr_250_noOver_sort.bed
# 276,590
bedtools merge -i Summit_idrPeak_chr_250_noOver_sort.bed -c 4,5,6 -o collapse > Summit_idrPeak_chr_250_noOver_sort_merge.txt

## Found the non overlapping merged summits
# accidentally doubled some peaks
wc -l Summit_idrPeak_chr_250_noOver_sort_merge_noOver.txt
# 273842 Summit_idrPeak_chr_250_noOver_sort_merge_noOver.txt
# peaks are written out for each peak

awk '!array[$2,$3]++' Summit_idrPeak_chr_250_noOver_sort_merge_noOver.txt | sort -k 1,1 -k2,2n > Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.txt
wc -l Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.txt
# 145,780

awk '{print $1"\t"$2"\t"$3"\tSummit_"NR"\t"$5"\t."}' Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.txt > Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.bed

# Had to remove .5s from the Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.bed in R
#  grep "2300853.5" Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.bed


bedtools intersect -a Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.bed -b replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed -u | wc -l
# 139,588

bedtools intersect -a Summit_idrPeak_chr_250_noOver_sort_merge_noOver_fix.bed -b replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed -u > Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack.bed

# using  Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed

# Now I can quantify these peaks!
# Rep1
for f1 in ~/17_member/ATACseq/Rep1/Fastq/comb_reads/Beds/*_shifted_chr_noNeg.bed
#for f1 in ~/17_member/ATACseq/Rep1/Fastq/comb_reads/Beds/gm77_shifted_chr_noNeg.bed
do
SampleName="$(echo ${f1} | cut -d '/' -f12 | cut -d '_' -f1)"
echo $SampleName
qsub -S /bin/bash -N Quant_summit_${SampleName} -cwd -l h_vmem=10G -j y << EOF
module load bedtools2
bedtools intersect -a ${f1} -b ~/17_member/ATACseq/Total_peak_analysis/Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed -wo | awk '{print \$10}' | cut -d '_' -f2 | sort -n | uniq -c > ${SampleName}_rep1_readPeaks
EOF
done

for f1 in ~/17_member/ATACseq/Replicates/FastQ/Beds/*_shifted_chr_noNeg.bed
#for f1 in ~/17_member/ATACseq/Replicates/FastQ/Beds/gm77_shifted_chr_noNeg.bed
do
SampleName="$(echo ${f1} | cut -d '/' -f11 | cut -d '_' -f1)"
echo $SampleName
qsub -S /bin/bash -N Quant_summit_${SampleName} -cwd -l h_vmem=10G -j y << EOF
module load bedtools2
bedtools intersect -a ${f1} -b ~/17_member/ATACseq/Total_peak_analysis/Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed -wo | awk '{print \$10}' | cut -d '_' -f2 | sort -n | uniq -c > ${SampleName}_rep2_readPeaks
EOF
done

# changing the names of some of the files for eaiser manipulation
mv gm82comb_rep2_readPeaks gm82_rep2_readPeaks
mv gm83comb_rep2_readPeaks gm83_rep2_readPeaks
mv gm92comb_rep2_readPeaks gm92_rep2_readPeaks
mv gm93comb_rep2_readPeaks gm93_rep2_readPeaks

mv gm78comb_rep1_readPeaks gm78_rep1_readPeaks
mv gm83comb_rep1_readPeaks gm83_rep1_readPeaks
mv gm92comb_rep1_readPeaks gm92_rep1_readPeaks
mv gm93comb_rep1_readPeaks gm93_rep1_readPeaks
mv gm87comb_rep1_readPeaks gm87_rep1_readPeaks

grep -e "e" Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack.bed

# For the CQN normalization, I need to have the GC content and length for each gene.
module load bedtools2
bedtools nuc -fi /home/greally-lab/indexes/hg38_GenCode_EBV_decoy/Gencode_EBV_decoy_noComments.fa -bed Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed > Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_GCContent.txt

awk '{print $4"\t"$8"\t"$15}' Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_GCContent.txt > Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_GCContent_DF.txt

awk '{print $3}' Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_GCContent_DF.txt | sort  | uniq -c
# all of the summits used are 500 bp long
```

#Performing the Quantification of the summits in R in ~/17_member/ATACseq/Quant_summit_2
#############################################################
#########                                        ############
#########         Visualizing bedgraph files     ############
#############################################################

I was able to visualize the peaks using the bed filrs. This required me to prege all of the bam files.

This is based on a really comprehensive ATAC-seq pipeline from this link[https://yiweiniu.github.io/blog/2019/03/ATAC-seq-data-analysis-from-FASTQ-to-peaks/]
Example code to convert ba, to bigwig file for visualization
First I made a merged reads directory under the BAM section in my folder.
/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/BAMs/Standard_trimmed/sorted/dedup/read1/merged_reads
Then I merged the processed BAMS based on the dated and

```bash
mkdir merged_reads
qsub -S /bin/bash -N bam_merge_CD -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
 module load samtools/1.13/gcc.4.4.7
samtools merge -@ 8 -o merged_reads/CD_paired_dedup_merged.bam CD1_CKDL210011590-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CD2_CKDL210011591-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CD4_CKDL210011592-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CD6_CKDL210011593-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF
qsub -S /bin/bash -N bam_merge_CR -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
  module load samtools/1.13/gcc.4.4.7
  samtools merge -@ 8 -o merged_reads/CR_paired_dedup_merged.bam CR1_CKDL210011598-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CR3_CKDL210011599-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CR5_CKDL210011600-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CR6_CKDL210011601-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_CT -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
  module load samtools/1.13/gcc.4.4.7
  samtools merge -@ 8 -o merged_reads/CT_paired_dedup_merged.bam CT1_CKDL210011594-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CT3_CKDL210011595-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CT5_CKDL210011596-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam CT6_CKDL210011597-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_DD -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
  module load samtools/1.13/gcc.4.4.7
  samtools merge -@ 8 -o merged_reads/DD_paired_dedup_merged.bam DD1_CKDL210011602-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DD3_CKDL210011603-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DD5_CKDL210011604-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DD6_CKDL210011605-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_DR -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
  module load samtools/1.13/gcc.4.4.7
  samtools merge -@ 8 -o merged_reads/DR_paired_dedup_merged.bam DR1_CKDL210011610-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DR3_CKDL210011611-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DR5_CKDL210011612-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DR6_CKDL210011613-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_DT -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
 module load samtools/1.13/gcc.4.4.7
 samtools merge -@ 8 -o merged_reads/DT_paired_dedup_merged.bam DT1_CKDL210011606-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DT4_CKDL210011607-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DT5_CKDL210011608-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam DT6_CKDL210011609-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_ED -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
module load samtools/1.13/gcc.4.4.7
samtools merge -@ 8 -o merged_reads/ED_paired_dedup_merged.bam ED1_CKDL210011614-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ED3_CKDL210011615-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ED5_CKDL210011616-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ED6_CKDL210011617-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_ER -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
 module load samtools/1.13/gcc.4.4.7
samtools merge -@ 8 -o merged_reads/ER_paired_dedup_merged.bam ER1_CKDL210011622-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ER4_CKDL210011623-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ER5_CKDL210011624-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF
qsub -S /bin/bash -N bam_merge_ET -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
module load samtools/1.13/gcc.4.4.7
samtools merge -@ 8 -o merged_reads/ET_paired_dedup_merged.bam ET2_CKDL210011618-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ET4_CKDL210011619-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ET5_CKDL210011620-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam ET6_CKDL210011621-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF

qsub -S /bin/bash -N bam_merge_BT -pe smp 8 -cwd -l h_vmem=24G -j y << EOF
module load samtools/1.13/gcc.4.4.7
samtools merge -@ 8 -o merged_reads/BT_paired_dedup_merged.bam BT1_CKDL210011581-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam BT2_CKDL210011582-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam BT3_CKDL210011583-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam BT5_CKDL210011584-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam BT6_CKDL210011585-1a_HC5FKDSX2_L3_standardtrim.paired.Umap.dedup_read1.bam
EOF
```

Once all of the samples were merged by date and condition I converted the merged files to bigwigs using bamCoverage.sh
sh ~/Greally/MSC/Work/ATAC_Work/bamCoverage_human.sh

```bash
#!/bin/sh
#$ -cwd
#$ -j y
#$ -N bamCoverage
#$ -pe smp 8
#$ -l h_vmem=20G
#$ -S /bin/bash

module load deeptools/3.1.0/python.2.7.8

for i in *_paired_dedup_merged.bam
do
echo ${i}
qsub -S /bin/bash -j y -N bamtobigwig_${i} -pe smp 8 -cwd -l h_vmem=24G <<EOF
module load deeptools/3.1.0/python.2.7.8

  # need to fix overlapping regonis in  blacklist
  #bamCoverage --numberOfProcessors 8 --binSize 50 --normalizeUsing BPM \
  #--blackListFileName /gs/gsfs0/users/greally-lab/Toxo_reanalysis/Ronnie/Genomes/Annotation/hg38.blacklist.bed \
  #--effectiveGenomeSize 2805636331 -of bigwig --bam $i -o $(basename -- $i).rmBlck.bw


  bamCoverage --numberOfProcessors 8 --binSize 50 --normalizeUsing BPM \
  --effectiveGenomeSize 2805636331 -of bigwig --bam ${i} -o $(basename -- ${i}).bw
EOF
done
```
This is the bamcoverage from deeptools example script
```bash

# bam to bigwig, normalize using 1x effective genome size
# effective genome size: https://deeptools.readthedocs.io/en/latest/content/feature/effectiveGenomeSize.html
#This utilizes deeptools to generate a coverage track

module load deeptools/3.1.0/python.2.7.8
bamCoverage --numberOfProcessors 8 --binSize 10 --normalizeUsing RPGC \
  --effectiveGenomeSize 3e9 --bam sample1.shifted.bam -o sample1.shifted.bw

```

bgraphtobigwig.sh
```bash
#$ -S /bin/bash
#$ -cwd
#$ -N Bed_shift
#$ -o /gs/gsfs0/users/taythomp/Greally/MSC/logs/
#$ -j y


```

##############################################################
##########                                        ############
##########   Pooling teatment vs control samples  ###########
##############################################################
##### rep1
By adding all the DMSO samples together I can call them one large call.
cat BD*_shifted_chr_noNeg.bed > BD_shifted.bed
##### rep2
These are all the TBT samples
cat BT*_shifted_chr_noNeg.bed > BT_shifted.bed
##### rep3
These are all the ROSI samples
cat BR*_shifted_chr_noNeg.bed > BR_shifted.bed

###############################################################
######                                                  #######
######                 Getting individual IDR peak      #######
###############################################################
#IDR is the Irreproducibility Discovery Rate. This is the measuere of consistency betweeen biological replicates. The definitions and quality requirements as established by ENCODE[https://www.encodeproject.org/data-standards/terms/] are below:

    - A statistical procedure that operates on the replicated peak set and compares consistency of ranks of these peaks in individual replicate/pseudoreplicate peak sets. Peaks with high rank consistency are retained. IDR can operate on peaks across a pair of true replicates resulting in a “conservative” output peak set, or across a pair of pseudoreplicates resulting in an “optimal“ output peak set. Peaks in the conservative peak set can be interpreted as high confidence peaks, representing reproducible events across true biological replicates and accounting for true biological and technical noise. Peaks in the optimal set can be interpreted as high-confidence peaks, representing reproducible events and accounting for read sampling noise. The optimal set is more sensitive, especially when one of the replicates has lower data quality than the other.
    - The self-consistency ratio measures consistency within a single dataset
    - The rescue ratio measures consistency between datasets when the replicates within a single experiment are not comparable.
    - self consistency and resuce less than 2 is a
    - self-consistency < 2 and rescue > 2 is acceptable
    - self > 2 and rescue < 2 acceptable
    - self > 2 and resuce > 2 concerning


# Now to perform the IDR analysis
#For the IDRs I have 3 samples so I need to do the IDR for 1-2, 2-3, and 13 seperately and then I will merge the IDR peaks so that at least 2 samples have shown the peak. These will become my consensus reads. Below is a table of my samples and each of their replicates. 1/2, 3/4, 5/6 are from the same well but seperate library preps.
I created Replicate "Rep" folders under the ATAC_Peaks/MACs/Read1 folder
Rep1	Rep2	Rep3	Rep4	Rep5
AO1	AO3	AO4
BD1	BD4	BD5
BR1	BR2	BR4	BR6
BT1	BT2	BT3	BT5	BT6
CD1	CD2	CD4	CD6
CR1	CR3	CR5	CR6
CT1	CT3	CT5	CT6
DD1	DD3	DD5	DD6
DR1	DR3	DR5	DR6
DT1	DT4	DT5	DT6
ED1	ED3	ED5	ED6
ER1	ER4	ER5
ET2	ET4	ET5	ET6


#Start and interactive node. Then move to the ATAC_Peak/MACs/Read1 folder.
#### Call IDRs HERE!! #######

```bash

module load idr/2.0.2/python.3.4.1-atlas-3.11.30
python3 -c "import idr"
python3 -c "import matplotlib"
idr --samples Rep3/BD*.read1.chr.narrowPeak Rep4/BD*.read1.chr.narrowPeak --input-file-type narrowPeak --output-file IDR/BD_rep34_peak_idr --output-file-type narrowPeak --plot --log-output-file IDR/BD_rep34.idr.log

idr --samples Rep3/BR*.read1.chr.narrowPeak Rep4/BR*.read1.chr.narrowPeak --input-file-type narrowPeak --output-file IDR/BR_rep34_peak_idr --output-file-type narrowPeak --plot --log-output-file IDR/BR_rep34.idr.log

idr --samples Rep3/BT*.read1.chr.narrowPeak Rep4/B*.read1.chr.narrowPeak --input-file-type narrowPeak --output-file IDR/BT_rep45_peak_idr --output-file-type narrowPeak --plot --log-output-file IDR/BT_rep45.idr.log

```
##Create giant log file to ensure that that samples have a decent IDR


### Create large narrow peaks that contain IDR peaks with at least samples that we will call consensus peaks. I may need to run unique on this

```bash
cat A_*_idr > A_IDR_peaks.narrowPeak

cat BD_*_idr > BD_IDR_peaks.narrowPeak
cat BR_*_idr > BR_IDR_peaks.narrowPeak
cat BT_*_idr > BT_IDR_peaks.narrowPeak

cat CD_*_idr > CD_IDR_peaks.narrowPeak
cat CR_*_idr > CR_IDR_peaks.narrowPeak
cat CT_*_idr > CT_IDR_peaks.narrowPeak

cat DD_*_idr > DD_IDR_peaks.narrowPeak
cat DR_*_idr > DR_IDR_peaks.narrowPeak
cat DT_*_idr > DT_IDR_peaks.narrowPeak

cat ED_*_idr > ED_IDR_peaks.narrowPeak
cat ER_*_idr > ER_IDR_peaks.narrowPeak
cat ET_*_idr > ET_IDR_peaks.narrowPeak
```

#Below is an example of a qsub method for idr calling:
``` bash
for f1 in ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/*narrowPeak
for f1 in ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/gm82_peaks.narrowPeak ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/gm87comb_peaks.narrowPeak ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/gm78comb_peaks.narrowPeak;
do
SampleName="$(echo ${f1} | cut -d '/' -f7 | cut -d '_' -f1)"
echo $SampleName
qsub -S /bin/bash -N ${SampleName}_idr -cwd -l h_vmem=20G -j y << EOF
module load idr/2.0.2/python.3.4.1-atlas-3.11.30
python3 -c "import idr"
python3 -c "import matplotlib"
idr --samples ${f1} ../../Replicates/FastQ/Peaks_Final_rmdup/${SampleName}_peaks.narrowPeak --input-file-type narrowPeak --output-file ${SampleName}_peaks_idr --output-file-type narrowPeak --plot
EOF
done
done

```

``` bash
# get number of peaks that are IDR < 0.05
for f1 in *_peak_idr
do
echo $f1 >> lowIDRPeaks.txt
awk '$5 > 540 {print $0}' $f1 | wc -l >> lowIDRPeaks.txt
done

# Make < 0.05 peak files
for f1 in *_peak_idr
do
awk '$5 > 540 {print $0}' $f1 > ${f1}_05
done

cat A_*_idr_05 > A_IDR_05_peaks.narrowPeak

cat BD_*_idr_05 > BD_IDR_05_peaks.narrowPeak
cat BR_*_idr_05 > BR_IDR_05_peaks.narrowPeak
cat BT_*_idr_05 > BT_IDR_05_peaks.narrowPeak

cat CD_*_idr_05 > CD_IDR_05_peaks.narrowPeak
cat CR_*_idr_05 > CR_IDR_05_peaks.narrowPeak
cat CT_*_idr_05 > CT_IDR_05_peaks.narrowPeak

cat DD_*_idr_05 > DD_IDR_05_peaks.narrowPeak
cat DR_*_idr_05 > DR_IDR_05_peaks.narrowPeak
cat DT_*_idr_05 > DT_IDR_05_peaks.narrowPeak

cat ED_*_idr_05 > ED_IDR_05_peaks.narrowPeak
cat ER_*_idr_05 > ER_IDR_05_peaks.narrowPeak
cat ET_*_idr_05 > ET_IDR_05_peaks.narrowPeak
```
## IDR Output Files
The output format mimics the input file type, with some additional fields.

#Creating bigwigs from teh idr outputs
sort -k1,1 -k2,2n -k3,3n -s A_IDR_05_peaks_sorted.bed > A_out.tmp.bdg
bedtools merge -i A_out.tmp.bdg -c 4 -d 0 -o max > out.bdg | sort -k1,1 -k2,2n -k3,3n -s > A_IDR_05_peaks_sorted.bdg.sorted

We provide an example for narrow peak files - note that the first 6 columns are a standard bed6, the first 10 columns are a standard narrowPeak. Also, for columns 7-10, only the score that the IDR code used for rankign will be set - the remaining two columns will be set to -1.
##Making Repliate IDR only peak files.
I am making a subsets of the Narrow peak files for each sample that I am overlapping against the IDR merged files to get just the peaks from each sample that were considered high confidence.

The individual peak files that passed th IUDR threshold are in this folder /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/Peak_files_overlappingIDR_Peaks. These are the files that I will be using for the ATAC-seq analysis as well as the concatenated firles that I used to intersec with the individual files. They are all in this folder: /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/IDR/ and I will be copying them to a dropbox folder under the Bulk_work/ ATAC_Work folder.
```bash
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
```
#Below is an example of a qsub method for idr calling:
```bash
for f1 in ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/*narrowPeak
#for f1 in ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/gm82_peaks.narrowPeak ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/gm87comb_peaks.narrowPeak ../../Rep1/Fastq/comb_reads/Peaks_Final_rmdup/gm78comb_peaks.narrowPeak;
do
SampleName="$(echo ${f1} | cut -d '/' -f7 | cut -d '_' -f1)"
echo $SampleName
qsub -S /bin/bash -N ${SampleName}_idr -cwd -l h_vmem=20G -j y << EOF
module load idr/2.0.2/python.3.4.1-atlas-3.11.30
python3 -c "import idr"
python3 -c "import matplotlib"
idr --samples ${f1} ../../Replicates/FastQ/Peaks_Final_rmdup/${SampleName}_peaks.narrowPeak --input-file-type narrowPeak --output-file ${SampleName}_peaks_idr --output-file-type narrowPeak --plot
EOF
done
done
```


Broad peak output files are the same except that they do not include the the summit columns (e.g. columns 10, 18, and 22 for samples with 2 replicates)
  1. chrom string - Name of the chromosome for common peaks
  2. chromStart int - The starting position of the feature in the chromosome or scaffold for common peaks, shifted based on offset. The first base in a chromosome is numbered 0.
  3. chromEnd int - The ending position of the feature in the chromosome or scaffold for common peaks. The chromEnd base is not included in the display of the feature.
  4. name string - Name given to a region (preferably unique) for common peaks. Use '.' if no name is assigned.
  5. score int - Contains the scaled IDR value, min(int(log2(-125IDR), 1000). e.g. peaks with an IDR of 0 have a score of 1000, idr 0.05 have a score of int(-125log2(0.05)) = 540, and idr 1.0 has a score of 0.
  6. strand [+-.] Use '.' if no strand is assigned.
  7. signalValue float - Measurement of enrichment for the region for merged peaks. When a peak list is provided this is the value from the peak list.
  8. p-value float - Merged peak p-value. When a peak list is provided this is the value from the peak list.
  9. q-value float - Merged peak q-value. When a peak list is provided this is the value from the peak list.
  10. summit int - Merged peak summit
  11. localIDR float -log10(Local IDR value)
  12. globalIDR float -log10(Global IDR value)
  13. rep1_chromStart int - The starting position of the feature in the chromosome or scaffold for common replicate 1 peaks, shifted based on offset. The first base in a chromosome is numbered 0.
  14. rep1_chromEnd int - The ending position of the feature in the chromosome or scaffold for common replicate 1 peaks. The chromEnd base is not included in the display of the feature.
  15. rep1_signalValue float - Signal measure from replicate 1. Note that this is determined by the --rank option. e.g. if --rank is set to signal.value, this corresponds to the 7th column of the narrowPeak, whereas if it is set to p.value it corresponds to the 8th column.
  16. rep1_summit int - The summit of this peak in replicate 1.
  17. [rep2 data similar to rep 1 columns]


####Create IDR bedfiles for ATACseeker analysis

I will use the chr, start, stop and signal score columns like Masako does in this link[file:///Users/homie/Downloads/Human_analysis.html#idr-peaks]

##Test script awk '{print $1,"\t",$2,"\t"$3,"\t"$7}' BD_IDR_05_peaks.narrowPeak | head
```bash
for f1 in /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/IDR/*_peaks.narrowPeak
do
  SampleName="$(echo ${f1} | cut -d '.' -f1)"
  awk '{print $1,"\t",$2,"\t"$3,"\t"$7}' ${f1} > ${SampleName}.bed
done

```
The IDR files are in a weird order so I will be sorting them by chromosome again by chromosome and position for downstream analysis.

the sort unix fundtion is faster then the bedtools sort funstion. The bedtools website says that here[https://bedtools.readthedocs.io/en/latest/content/tools/sort.html]. So since I just want to sort by chromosome and then start position. I will fun the following script to quickly and efficiently sort my files before downstream analysis because the ChipSeeker package may need that, or my samples are just not aligned or something.

```bash
for f1 in /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/IDR/*.bed
do
  SampleName="$(echo ${f1} | cut -d '.' -f1)"
  sort -k 1,1 -k2,2n ${f1} > ${SampleName}_sorted.bed
done

```

###Work in R
The next things that I had to do were to take the peaks and looked at the distance to TSSs using Chippeakanno_test.Rmd. I then used the findoverlapsofpeaks function to overlap all the D0/and D3-14 DMSO samples to compare the normal differentiation cascade. I found 63.5k unique D0 peaks, 149 D3,


Once I go the Unique peaks for the control samples I moved them back to the Diff_called_peaks folder. They all have 4 columns, chr, start, stop and signal value which is the basic requirement for a bedgraph then I simply ran the uscs bedGraphtoBigWig command like below for all of the files. Then I will visualize all the files using IGV.
```bash
#Sort bdgs just in case
for f1 in *.bdg
do
  SampleName="$(echo ${f1} | cut -d '.' -f1)"
  sort -k 1,1 -k2,2n ${f1} > ${SampleName}_sorted.bdg
done

#convert bedgraph to bigwig
for f1 in *_sorted.bdg
do
  SampleName="$(echo ${f1} | cut -d '.' -f1)"
  bedGraphToBigWig ${f1} ../hg38.chrom.sizes ${SampleName}.bw
done
module load ucsc/080613
bedGraphToBigWig BD_only_peaks.bdg ../hg38.chrom.sizes BD_only_peaks.bw
bedGraphToBigWig MSC_only_peaks.bdg ../hg38.chrom.sizes MSC_only_peaks.bw
bedGraphToBigWig CD_only_peaks.bdg ../hg38.chrom.sizes CD_only_peaks.bw
```


#Motif Discovery
The motif work I was doing in R is not working so I am tryin to run this using HOMER
Steps:

  1. First I output all of my pattern files as bed inspired txt files
  2. Run the conversion pos2bed.pl file from Homer
  3. run the findMotifsGenome.pl


```bash
module load HOMER/4.7

 findMotifsGenome.pl AP_1.bed hg38 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/Motif_Output/ -size 100 -preparsedDir ./Motif_Output
for f in *.txt
do
  echo ${f}
  SAMPLE="$(echo ${f} | cut -d '.' -f1)"
  qsub -S /bin/bash -N ${SampleName}_Call_Peaks -cwd -o /gs/gsfs0/users/taythomp/Greally/MSC/logs -l h_vmem=20G -j y -pe smp 4 << EOF
  module load HOMER/4.7
  mkdir SAMPLE
  pos2bed.pl ${f} > ${SAMPLE}.bed
  findMotifsGenome.pl ${SAMPLE}.bed hg38 /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/Motif_Output/SAMPLE/ -size 100 -p 4 -preparsedDir ./Motif_Output/
EOF
done

```

 ###Diffbind
 Seperated out the IDR files and made individual narrow peaks files for each sample that I can use for Diffbind.
 The following script is Intersect_IDR_Peaks in teh work folder.
```bash
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

```
For diffbind I need a bam or bed to use to help explain the libray size so I will make a bed from hte narrow peak files by cutting the first 6 columns because a narrowpeak file is just a bed + 4 format.

```bash
for f1 in /gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/ATAC_Peaks/MACS2/Read1/Peak_files_overlappingIDR_Peaks/*.narrowPeak
 do
   echo $f1
   cut -f 1-6 $f1 > $f1.bed
 done

 ```



# how many of them intersect replicate_summit_peak_nonspecific.bed
# first clean up the replicate summit peak
sort -k 1,1 -k2,2n replicate_summit_peak_nonspecific.bed | awk '{print $1"\t"$2"\t"$3"\tPeak_"NR"\t"$5"\t."}' > replicate_summit_peak_nonspecific_sort.bed

# Cleaning up more in the R file to get canonical chr
wc -l replicate_summit_peak_nonspecific_sort_Canon.bed
# 103691 replicate_summit_peak_nonspecific_sort_Canon.bed

module load bedtools2
bedtools intersect -a replicate_summit_peak_nonspecific_sort_Canon.bed -b /home/greally-lab/indexes/consensusBlacklist_hg38.bed -v > replicate_summit_peak_nonspecific_sort_Canon_FilMappBlack.bed

wc -l replicate_summit_peak_nonspecific_sort_Canon_FilMappBlack.bed
#103481 replicate_summit_peak_nonspecific_sort_Canon_FilMappBlack.bed

module load bedtools2
bedtools intersect -a replicate_summit_peak_nonspecific_sort_Canon_FilMappBlack.bed -b Mito_peak_blacklist.bed -v > replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed

wc -l replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed
# 103,476 replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed


for f1 in *_peaks_idr_05;
do
SAMPLE="$(echo ${f1} | cut -d '_' -f1)"
echo $SAMPLE
bedtools intersect -a ../../Total_peak_analysis/replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed -b ${f1} -wo | awk '{print $4}' | sort | uniq | awk '{print $1"\t1"}' > ${SAMPLE}_inter_master.txt
done

mv gm78comb_inter_master.txt gm78_inter_master.txt
mv gm83comb_inter_master.txt gm83_inter_master.txt
mv gm87comb_inter_master.txt gm87_inter_master.txt
mv gm92comb_inter_master.txt gm92_inter_master.txt
mv gm93comb_inter_master.txt gm93_inter_master.txt

awk '{print $4}' ../../Total_peak_analysis/replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed > Master_peak_names.txt
wc -l Master_peak_names.txt
# 103476 Master_peak_list.txt

wc -l Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack.bed
# 139588
bedtools merge -i Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack.bed | wc -l
# 139,581

bedtools merge -i Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack.bed -c 4,5 -o collapse >  Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_merge.bed
# made Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix.bed
# in R

bedtools sort -i Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix.bed > Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed
wc -l Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed
# 139588 Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed

bedtools merge -i Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed | wc -l
# 139,588

wc -l replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed
# 103,476 replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed

bedtools merge -i replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed | wc -l # 103474

# Use this to do the quantification.

# need to figure out which peaks correspond to which summits
less Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed

module load bedtools2
bedtools intersect -a Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed -b replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed -wo > Summit_Summit_peak_inter.txt
wc -l Summit_Summit_peak_inter.txt
# 139,700 Summit_Summit_peak_inter.txt
less Summit_Summit_peak_inter.txt

bedtools intersect -a Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed -b replicate_summit_peak_nonspecific_sort_Canon_FilMappMitoBlack.bed -wo | awk '{print $4}' | sort | uniq -d | wc -l

## to do the chrQTL analysis, I need to intersect the summits with the haplotype information
# pwd = ~/17_member/QTLs_2017/ATAC_summit_QTL_2
module load bedtools2
bedtools intersect -a ../../ATACseq/Total_peak_analysis/Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed -b ../haplotype_grch38_named_4intersect.txt -wo > ATAC_summit_Plat_haplo_interesect.txt

wc -l ATAC_summit_Plat_haplo_interesect.txt
#139,301 ATAC_summit_Plat_haplo_interesect.txt
# only 287 summits did not overlap a haplotype

bedtools intersect -a ../../ATACseq/Total_peak_analysis/Summit_idrPeak_chr_250_noOver_sort_merge_noOver_Canon_FilMappMitoBlack_dupfix_sort.bed -b ../haplotype_grch38_named_4intersect.txt -wa | uniq -d
# no summits overlap multiple haplotypes
