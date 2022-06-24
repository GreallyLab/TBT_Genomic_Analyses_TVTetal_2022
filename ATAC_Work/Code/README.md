# ATAC_Work
This is where I have been keeping my code as I work through the analysis of my Bulk ATACseq. The Major script to follow is ATAC_Work.Md it is the Markdown that will take you from the dowloading of my data through the complete analysis. 

# I need to go through and add what files I used for which parts of this 

1. Download data
2. Preprocessing Quality checking
    - Check raw reads(FASTQC)
    - Make interactive summary reprot as HTML(MultiQC)
    - Trim adapter sequences(Optional) -Cutadapt/Trimgalore
3. Alignment to reference genome(BWA-mem/Bowtie2)
4. Convert and sort aligned sams
5. Filter reads:
    - Remove organelle derived reads(Samtools)
    - Mark/remove Duplicates(Samtools/Picard)
    - Remove Mapping artifacts
      * Remove fragments <38bp and >2kb
      * Remove unmapped reads
      * remove poor quality reads(MAPQ<20)
6. Post-Alignment QC
    - Use ATAC-seq QC R workflow to look at the quality of your results. 
8. Call Peaks
