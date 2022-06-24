#Begin code:

setwd("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/BAM_work")

library(DiffBind)
library(GenomicAlignments)
library(rtracklayer)
#Blacklist from encode(https://www.encodeproject.org/files/ENCFF356LFX/) sites here:
blkList <- import.bed("/gs/gsfs0/users/taythomp/Greally/References/Blacklists/kundaje_hg38blacklist_ENCFF356LFX.bed.gz")
#read in metadata csv
samples_ROSI_D10 = read.csv("./DiffBind_ATAC_metadata_ROSI_D10.csv")

#Create diffbind object from diffbind metadata csv
DB_object_ROSI_D10 <- dba(sampleSheet="./DiffBind_ATAC_metadata_ROSI_D10.csv",minOverlap = 2, config = data.frame(AnalysisMethod=DBA_DESEQ2,th=0.05,
DataType=DBA_DATA_GRANGES, RunParallel=TRUE,
minQCth=15,
bCorPlot=FALSE, reportInit="DBA",
bUsePval=FALSE, design=TRUE,
doBlacklist=TRUE, doGreylist=TRUE))

#Create counts
DB_object_ROSI_D10 <- dba.count(DB_object_ROSI_D10)

#look at DBA
info_ROSI_D10 <- dba.show(DB_object_ROSI_D10)
libsizes_ROSI_D10 <- cbind(LibReads=info_ROSI_D10$Reads, FRiP=info_ROSI_D10$FRiP, PeakReads=round(info_ROSI_D10$Reads * info_ROSI_D10$FRiP))
rownames(libsizes_ROSI_D10) <- info_ROSI_D10$ID
libsizes_ROSI_D10

#Save Robjects
save(list= c("info_ROSI_D10", "samples_ROSI_D10","libsizes_ROSI_D10"), file = "./Diff_bind_objs_ROSI_D10.RData")

#Normalize the samples
DB_object_ROSI_D10 <- dba.normalize(DB_object_ROSI_D10)

#Contrast
DB_object_ROSI_D10 <- dba.contrast(DB_object_ROSI_D10,categories=DBA_TREATMENT)

#perform differential analysis
DB_object_ROSI_D10 <- dba.analyze(DB_object_ROSI_D10, , method=DBA_ALL_METHODS)
save(DB_object_ROSI_D10, file="./DB_object_ROSI_D10.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_D10 <- dba.show(DB_object_ROSI_D10, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_D10, file="./contrasts_DB_object_ROSI_D10.Rdata")

#Contrast by day(FACTOR)
DB_object_ROSI_D10_factor <- dba.contrast(DB_object_ROSI_D10,categories=DBA_FACTOR)
DB_object_ROSI_D10_factor
​
# perform differential analysis
DB_object_ROSI_D10_factor <- dba.analyze(DB_object_ROSI_D10_factor, method=DBA_ALL_METHODS)
save(DB_object_ROSI_D10_factor, file="./DB_object_ROSI_D10_factor_contrast.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_D10_factor <- dba.show(DB_object_ROSI_D10_factor, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_D10_factor, file="./contrasts_DB_object_ROSI_D10_factor.Rdata")
