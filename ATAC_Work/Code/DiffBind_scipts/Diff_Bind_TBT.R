#Begin code:

setwd("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/BAM_work")

library(DiffBind)
library(GenomicAlignments)
library(rtracklayer)
#Blacklist from encode(https://www.encodeproject.org/files/ENCFF356LFX/) sites here:
blkList <- import.bed("/gs/gsfs0/users/taythomp/Greally/References/Blacklists/kundaje_hg38blacklist_ENCFF356LFX.bed.gz")
#read in metadata csv
samples_TBT = read.csv("./DiffBind_ATAC_metadata_TBT.csv")

#Create diffbind object from diffbind metadata csv
DB_object_TBT <- dba(sampleSheet="./DiffBind_ATAC_metadata_TBT.csv",minOverlap = 2, config = data.frame(AnalysisMethod=DBA_DESEQ2,th=0.05,
DataType=DBA_DATA_GRANGES, RunParallel=TRUE,
minQCth=15,
bCorPlot=FALSE, reportInit="DBA",
bUsePval=FALSE, design=TRUE,
doBlacklist=TRUE, doGreylist=TRUE))

#Create counts
DB_object_TBT <- dba.count(DB_object_TBT)

#look at DBA
info_TBT <- dba.show(DB_object_TBT)
libsizes_TBT <- cbind(LibReads=info_TBT$Reads, FRiP=info_TBT$FRiP, PeakReads=round(info_TBT$Reads * info_TBT$FRiP))
rownames(libsizes_TBT) <- info_TBT$ID
libsizes_TBT

#Save Robjects
save(list= c("info_TBT", "samples_TBT"), file = "./Diff_bind_objs_TBT.RData")

#Normalize the samples
DB_object_TBT <- dba.normalize(DB_object_TBT)

#Contrast
DB_object_TBT <- dba.contrast(DB_object_TBT,categories=DBA_TREATMENT)

# perform differential analysis
DB_object_TBT <- dba.analyze(DB_object_TBT, method=DBA_DESEQ2)
save(DB_object_TBT, file="./DB_object_TBT.RData")

#show the contrast results
contrasts_DB_object_TBT <- dba.show(DB_object_TBT, bContrasts = TRUE)
save(contrasts_DB_object_TBT, file="./contrasts_DB_object_TBT.RData")

#Contrast by day(FACTOR)
DB_object_TBT_factor <- dba.contrast(DB_object_TBT,categories=DBA_FACTOR)
DB_object_TBT_factor
​
# perform differential analysis
DB_object_TBT_factor <- dba.analyze(DB_object_TBT_factor, method=DBA_DESEQ2)
save(DB_object_TBT_factor, file="./DB_object_TBT_factor_contrast.RData")

#show the contrast results
contrasts_DB_object_TBT_factor <- dba.show(DB_object_TBT_factor, bContrasts = TRUE)
save(contrasts_DB_object_TBT_factor, file="./contrasts_DB_object_TBT_factor.RData")
