#Begin code:

setwd("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/BAM_work")

library(DiffBind)
library(GenomicAlignments)
library(rtracklayer)
#Blacklist from encode(https://www.encodeproject.org/files/ENCFF356LFX/) sites here:
blkList <- import.bed("/gs/gsfs0/users/taythomp/Greally/References/Blacklists/kundaje_hg38blacklist_ENCFF356LFX.bed.gz")
#read in metadata csv
samples_ROSI_D14 = read.csv("./DiffBind_ATAC_metadata_ROSI_D14.csv")

#Create diffbind object from diffbind metadata csv
DB_object_ROSI_D14 <- dba(sampleSheet="./DiffBind_ATAC_metadata_ROSI_D14.csv",minOverlap = 2, config = data.frame(AnalysisMethod=DBA_DESEQ2,th=0.05,
DataType=DBA_DATA_GRANGES, RunParallel=TRUE,
minQCth=15,
bCorPlot=FALSE, reportInit="DBA",
bUsePval=FALSE, design=TRUE,
doBlacklist=TRUE, doGreylist=TRUE))

#Create counts
DB_object_ROSI_D14 <- dba.count(DB_object_ROSI_D14)

#look at DBA
info_ROSI_D14 <- dba.show(DB_object_ROSI_D14)
libsizes_ROSI_D14 <- cbind(LibReads=info_ROSI_D14$Reads, FRiP=info_ROSI_D14$FRiP, PeakReads=round(info_ROSI_D14$Reads * info_ROSI_D14$FRiP))
rownames(libsizes_ROSI_D14) <- info_ROSI_D14$ID
libsizes_ROSI_D14

#Save Robjects
save(list= c("info_ROSI_D14", "samples_ROSI_D14","libsizes_ROSI_D14"), file = "./Diff_bind_objs_ROSI_D14.RData")

#Normalize the samples
DB_object_ROSI_D14 <- dba.normalize(DB_object_ROSI_D14)

#Contrast
DB_object_ROSI_D14 <- dba.contrast(DB_object_ROSI_D14,categories=DBA_TREATMENT)

#perform differential analysis
DB_object_ROSI_D14 <- dba.analyze(DB_object_ROSI_D14, , method=DBA_ALL_METHODS)
save(DB_object_ROSI_D14, file="./DB_object_ROSI_D14.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_D14 <- dba.show(DB_object_ROSI_D14, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_D14, file="./contrasts_DB_object_ROSI_D14.Rdata")

#Contrast by day(FACTOR)
#DB_object_ROSI_D14_factor <- dba.contrast(DB_object_ROSI_D14,categories=DBA_FACTOR)
#DB_object_ROSI_D14_factor
​
# perform differential analysis
DB_object_ROSI_D14_factor <- dba.analyze(DB_object_ROSI_D14_factor, method=DBA_ALL_METHODS)
save(DB_object_ROSI_D14_factor, file="./DB_object_ROSI_D14_factor_contrast.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_D14_factor <- dba.show(DB_object_ROSI_D14_factor, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_D14_factor, file="./contrasts_DB_object_ROSI_D14_factor.Rdata")
