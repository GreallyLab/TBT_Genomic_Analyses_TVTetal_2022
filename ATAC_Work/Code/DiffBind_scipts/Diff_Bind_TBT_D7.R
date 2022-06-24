#Begin code:

setwd("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/BAM_work")

library(DiffBind)
library(GenomicAlignments)
library(rtracklayer)
#Blacklist from encode(https://www.encodeproject.org/files/ENCFF356LFX/) sites here:
blkList <- import.bed("/gs/gsfs0/users/taythomp/Greally/References/Blacklists/kundaje_hg38blacklist_ENCFF356LFX.bed.gz")
#read in metadata csv
samples_TBT_D7 = read.csv("./DiffBind_ATAC_metadata_TBT_D7.csv")

#Create diffbind object from diffbind metadata csv
DB_object_TBT_D7 <- dba(sampleSheet="./DiffBind_ATAC_metadata_TBT_D7.csv",minOverlap = 2, config = data.frame(AnalysisMethod=DBA_DESEQ2,th=0.05,
DataType=DBA_DATA_GRANGES, RunParallel=TRUE,
minQCth=15,
bCorPlot=FALSE, reportInit="DBA",
bUsePval=FALSE, design=TRUE,
doBlacklist=TRUE, doGreylist=TRUE))

#Create counts
DB_object_TBT_D7 <- dba.count(DB_object_TBT_D7)

#look at DBA
info_TBT_D7 <- dba.show(DB_object_TBT_D7)
libsizes_TBT_D7 <- cbind(LibReads=info_TBT_D7$Reads, FRiP=info_TBT_D7$FRiP, PeakReads=round(info_TBT_D7$Reads * info_TBT_D7$FRiP))
rownames(libsizes_TBT_D7) <- info_TBT_D7$ID
libsizes_TBT_D7

#Save Robjects
save(list= c("info_TBT_D7", "samples_TBT_D7","libsizes_TBT_D7"), file = "./Diff_bind_objs_TBT_D7.RData")

#Normalize the samples
DB_object_TBT_D7 <- dba.normalize(DB_object_TBT_D7)

#Contrast
DB_object_TBT_D7 <- dba.contrast(DB_object_TBT_D7,categories=DBA_TREATMENT)

#perform differential analysis
DB_object_TBT_D7 <- dba.analyze(DB_object_TBT_D7, , method=DBA_ALL_METHODS)
save(DB_object_TBT_D7, file="./DB_object_TBT_D7.Rdata")

#show the contrast results
contrasts_DB_object_TBT_D7 <- dba.show(DB_object_TBT_D7, bContrasts = TRUE)
save(contrasts_DB_object_TBT_D7, file="./contrasts_DB_object_TBT_D7.Rdata")

#Contrast by day(FACTOR)
DB_object_TBT_D7_factor <- dba.contrast(DB_object_TBT_D7,categories=DBA_FACTOR)
DB_object_TBT_D7_factor
​
# perform differential analysis
DB_object_TBT_D7_factor <- dba.analyze(DB_object_TBT_D7_factor, method=DBA_ALL_METHODS)
save(DB_object_TBT_D7_factor, file="./DB_object_TBT_D7_factor_contrast.Rdata")

#show the contrast results
contrasts_DB_object_TBT_D7_factor <- dba.show(DB_object_TBT_D7_factor, bContrasts = TRUE)
save(contrasts_DB_object_TBT_D7_factor, file="./contrasts_DB_object_TBT_D7_factor.Rdata")
