#Begin code:

setwd("/gs/gsfs0/users/taythomp/Greally/MSC/Bulk_Experiments/Bulk_ATAC_062021/R_data/BAM_work")

library(DiffBind)
library(GenomicAlignments)
library(rtracklayer)
#Blacklist from encode(https://www.encodeproject.org/files/ENCFF356LFX/) sites here:
blkList <- import.bed("/gs/gsfs0/users/taythomp/Greally/References/Blacklists/kundaje_hg38blacklist_ENCFF356LFX.bed.gz")
#read in metadata csv
samples_ROSI = read.csv("./DiffBind_ATAC_metadata_ROSI.csv")

#Create diffbind object from diffbind metadata csv
DB_object_ROSI <- dba(sampleSheet="./DiffBind_ATAC_metadata_ROSI.csv",minOverlap = 2, config = data.frame(AnalysisMethod=DBA_DESEQ2,th=0.05,
DataType=DBA_DATA_GRANGES, RunParallel=TRUE,
minQCth=15,
bCorPlot=FALSE, reportInit="DBA",
bUsePval=FALSE, design=TRUE,
doBlacklist=TRUE, doGreylist=TRUE))

#Create counts
DB_object_ROSI <- dba.count(DB_object_ROSI)

#look at DBA
info_ROSI <- dba.show(DB_object_ROSI)
libsizes_ROSI <- cbind(LibReads=info_ROSI$Reads, FRiP=info_ROSI$FRiP, PeakReads=round(info_ROSI$Reads * info_ROSI$FRiP))
rownames(libsizes_ROSI) <- info_ROSI$ID
libsizes_ROSI

#Save Robjects
save(list= c("info_ROSI", "samples_ROSI"), file = "./Diff_bind_objs_ROSI.RData")

#Normalize the samples
DB_object_ROSI <- dba.normalize(DB_object_ROSI)

#Contrast
DB_object_ROSI <- dba.contrast(DB_object_ROSI,categories=DBA_TREATMENT)

#perform differential analysis
DB_object_ROSI <- dba.analyze(DB_object_ROSI, , method=DBA_ALL_METHODS)
save(DB_object_ROSI, file="./DB_object_ROSI.Rdata")

#show the contrast results
contrasts_DB_object_ROSI <- dba.show(DB_object_ROSI, bContrasts = TRUE)
save(contrasts_DB_object_ROSI, file="./contrasts_DB_object_ROSI.Rdata")

#Contrast by day(FACTOR)
DB_object_ROSI_factor <- dba.contrast(DB_object_ROSI,categories=DBA_FACTOR)
DB_object_ROSI_factor
​
# perform differential analysis
DB_object_ROSI_factor <- dba.analyze(DB_object_ROSI_factor, method=DBA_ALL_METHODS)
save(DB_object_ROSI_factor, file="./DB_object_ROSI_factor_contrast.Rdata")

#show the contrast results
contrasts_DB_object_ROSI_factor <- dba.show(DB_object_ROSI_factor, bContrasts = TRUE)
save(contrasts_DB_object_ROSI_factor, file="./contrasts_DB_object_ROSI_factor.Rdata")
