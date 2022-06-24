#Begin code:

setwd("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/BAM_work")

library(DiffBind)
library(GenomicAlignments)
library(rtracklayer)
#Blacklist from encode(https://www.encodeproject.org/files/ENCFF356LFX/) sites here:
blkList <- import.bed("/gs/gsfs0/users/taythomp/Greally/References/Blacklists/kundaje_hg38blacklist_ENCFF356LFX.bed.gz")
#read in metadata csv
samples_ROSI_D3 = read.csv("./DiffBind_ATAC_metadata_ROSI_D3.csv")

#Create diffbind object from diffbind metadata csv
DB_object_ROSI_D3 <- dba(sampleSheet="./DiffBind_ATAC_metadata_ROSI_D3.csv",minOverlap = 2, config = data.frame(AnalysisMethod=DBA_DESEQ2,th=0.05,
DataType=DBA_DATA_GRANGES, RunParallel=TRUE,
minQCth=15,
bCorPlot=FALSE, reportInit="DBA",
bUsePval=FALSE, design=TRUE,
doBlacklist=TRUE, doGreylist=TRUE))

#Create counts
DB_object_ROSI_D3 <- dba.count(DB_object_ROSI_D3)

#look at DBA
info_ROSI_D3 <- dba.show(DB_object_ROSI_D3)
libsizes_ROSI_D3 <- cbind(LibReads=info_ROSI_D3$Reads, FRiP=info_ROSI_D3$FRiP, PeakReads=round(info_ROSI_D3$Reads * info_ROSI_D3$FRiP))
rownames(libsizes_ROSI_D3) <- info_ROSI_D3$ID
libsizes_ROSI_D3

#Save Robjects
save(list= c("info_ROSI_D3", "samples_ROSI_D3","libsizes_ROSI_D3"), file = "./Diff_bind_objs_ROSI_D3.RData")

#Normalize the samples
DB_object_ROSI_D3 <- dba.normalize(DB_object_ROSI_D3)

#Contrast
DB_object_ROSI_D3 <- dba.contrast(DB_object_ROSI_D3,categories=DBA_TREATMENT)

#perform differential analysis
DB_object_ROSI_D3 <- dba.analyze(DB_object_ROSI_D3, , method=DBA_ALL_METHODS)
save(DB_object_ROSI_D3, file="./DB_object_ROSI_D3.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_D3 <- dba.show(DB_object_ROSI_D3, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_D3, file="./contrasts_DB_object_ROSI_D3.Rdata")

#Contrast by day(FACTOR)
DB_object_ROSI_D3_factor <- dba.contrast(DB_object_ROSI_D3,categories=DBA_FACTOR)
DB_object_ROSI_D3_factor
​
# perform differential analysis
DB_object_ROSI_D3_factor <- dba.analyze(DB_object_ROSI_D3_factor, method=DBA_ALL_METHODS)
save(DB_object_ROSI_D3_factor, file="./DB_object_ROSI_D3_factor_contrast.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_D3_factor <- dba.show(DB_object_ROSI_D3_factor, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_D3_factor, file="./contrasts_DB_object_ROSI_D3_factor.Rdata")
