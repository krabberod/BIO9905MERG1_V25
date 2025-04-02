#### Load libraries ####
library("tidyverse")
library("dada2")
library("phyloseq")
library("Biostrings")
library("kableExtra")
library("readxl")


#### Prepare Directories ####
# The fastq files are in this zip-file:
# https://www.dropbox.com/scl/fo/5oot50jnb6q8t80kglwv0/ACH3NKw48KKj7Hmd9k8ZZoU?rlkey=fbtdgip22c5ev3qd08cnl4h2h&dl=0
# Download and unzip in your dada2 working directory.
# The samples should be in a subfolder simply called "fastq"
# Check your current working directory:
getwd()

# If you want to set a new working directory:
# setwd("~/path_to_my_directory/DADA2_pipeline")


# Define the name of directories to use.
# These will be created in your current working directory
fastq_dir <- "fastq"  # fastq directory with the samples that will be used
database_dir <- "databases/"  # folder with the PR2 database https://github.com/vaulot/metabarcodes_tutorials/tree/master/databases
filtered_dir <- "fastq_filtered/"  # for the fastq-files after filtering
qual_dir <- "qual_pdf/"  # quality scores plots
dada2_dir <- "dada2_results/"  # dada2 results
blast_dir <- "blast/"  # blast2 results

# Create the directories
dir.create(filtered_dir)
dir.create(qual_dir)
dir.create(dada2_dir)
dir.create(blast_dir)
dir.create(database_dir)

#### Examine fastq files ####
# get a list of all fastq files in the fastq" directory and separate R1 and R2
fns <- sort(list.files(fastq_dir, full.names = T))
fns <- fns[str_detect(basename(fns), ".fastq.gz")]
fns_R1 <- fns[str_detect(basename(fns), "R1")]
fns_R2 <- fns[str_detect(basename(fns), "R2")]

# Extract sample names, assuming filenames have format: 18S_SAMPLENAME_XXX.fastq.gz
sample.names <- str_split(basename(fns_R1), pattern = "_", simplify = TRUE)
sample.names <- sample.names[, 2]

#### Prepare data: Make a dataframe with the number of sequences in each file ####
# Empty files (i.e files without sequences) will be removed
df <- data.frame()
for (i in seq_along(fns_R1)) {
  # skip empty files
  if (file.info(fns_R1[i])$size == 0) {
    warning(paste("Empty file skipped:", fns_R1[i]))
    next
  }
  # use the Biostrings function fastq.geometry
  geom <- fastq.geometry(fns_R1[i])
  # extract number of sequences and file name
  df_one_row <- data.frame(n_seq = geom[1], file_name = basename(fns_R1[i]))
  df <- bind_rows(df, df_one_row)
}

View(df)

# knitr::kable(df) # to make html table.
View(df)

# If you want to write the table to your working directory remove the hashtag and use:
write.table(df, file = 'n_seq.txt', sep='\t', row.names = FALSE, na='',quote=FALSE)

# plot the histogram with number of sequences
# The plot for the example data looks kind of uninformative, why?
ggplot(df, aes(x = n_seq)) +
  geom_histogram(alpha = 0.5, position = "identity", binwidth = 15000)
hist(df$n_seq, breaks = 10)

# Maybe a boxplot is better for these data: 
ggplot(df, aes(x = "", y = n_seq)) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(alpha = 0.5) 


#### Plot Quality for each fastq file ####
for (i in 1:length(fns)) {

  # Use dada2 function to plot quality
  p1 <- plotQualityProfile(fns[i])

  # Only plot on screen for first 2 files
  if (i <= 2) {
    print(p1)
  }

  # save the file as a pdf file
  p1_file <- paste0(qual_dir, basename(fns[i]), ".qual.pdf")

  ggsave(plot = p1, filename = p1_file, device = "pdf", width = 15, height = 15,
         scale = 1, units = "cm")
}


####
# Prepare the outputnames for filtered reads:
filt_R1 <- str_c(filtered_dir, sample.names, "_R1_filt.fastq")
filt_R2 <- str_c(filtered_dir, sample.names, "_R2_filt.fastq")



#### DADA2 ####
# If your setup allows running multiple threads set multithread = TRUE
# Mac OS: multithread = TRUE
# Windows: does not work for older versions of R (<4.0)
# Can take a couple of minutes:

out <- filterAndTrim(fns_R1, filt_R1, fns_R2, filt_R2, truncLen = c(250, 200),
                     # trimLeft = c(primer_length_fwd, primer_length_rev), # IF primers are left in the reads
                     maxN = 0, maxEE = c(2, 2), truncQ = 2, rm.phix = TRUE,
                     compress = FALSE, multithread = FALSE)

#### STEP 2. Learn Errors
# It took 9 min on an windows 11 i7-9700 CPU @ 3.00GHz, 16Gb Ram (pr. err_profile)
# Too 8.5 min for a MacBook Pro Early 2015 (pr. err_profile)
# The error profile takes about 2 min on an MacBook Pro M2 16Gb Ram

# The defualt error funciton assumes Illumina data (HiSeq, MiSeq, NextSeq But *NOT* NovaSeq). 

err_R1 <- learnErrors(filt_R1, multithread = TRUE, errorEstimationFunction = loessErrfun)
plotErrors(err_R1, nominalQ = TRUE)
ggsave("error_model_FWD.pdf")
saveRDS(err_R1, "err_R1.rds")

err_R2 <- learnErrors(filt_R2, multithread = TRUE, errorEstimationFunction = loessErrfun)
plotErrors(err_R2, nominalQ = TRUE)
ggsave("error_model_REV.pdf")
saveRDS(err_R1, "err_R2.rds")


### FOR NOVASEQ
# For NovaSeq Illumina is using binned quality scores which means that the
# original error function in dada2 does not work properly. 
# See https://github.com/ErnakovichLab/dada2_ernakovichlab
# See https://github.com/benjjneb/dada2/issues/1307



# For PacBio CCS/HiFI you should use a different errorEstimationFunction
# err1 <- learnErrors(filts1, errorEstimationFunction = PacBioErrfun, BAND_SIZE=32, multithread=TRUE)


#### STEP 3. Dereplicate the reads ####
derep_R1 <- derepFastq(filt_R1, verbose = TRUE)
derep_R2 <- derepFastq(filt_R2, verbose = TRUE)


# Name the derep-class objects by the sample names
names(derep_R1) <- sample.names
names(derep_R2) <- sample.names


#### STEP 4. DADA2 main inference
####  Sequence-variant inference algorithm on the dereplicated data ####
# If your computer can run multiple threads set multithread = TRUE
# It took 16s on MacBook Pro 2023 M2
# It took 2.5 min for each dada on an windows 11 i7-9700 CPU @ 3.00GHz, 16Gb Ram

dada_R1 <- dada(derep_R1, err = err_R1, multithread = TRUE, pool = FALSE)
dada_R2 <- dada(derep_R2, err = err_R2, multithread = TRUE, pool = FALSE)

# Viewing the first entry in each of the dada objects
dada_R1[[1]]
dada_R2[[1]]

#### STEP 5. Merge Sequences
mergers <- mergePairs(dada_R1, derep_R1, dada_R2, derep_R2, verbose = TRUE)
head(mergers[[1]])

#### STEP 6. Merge  ####
seqtab <- makeSequenceTable(mergers)
dim(seqtab)
# Make a transposed version of seqtab to make it similar to data in mothur
t_seqtab <- t(seqtab) # the function t() is a simple transposing of the matrix
table(nchar(getSequences(seqtab)))
plot(table(nchar(getSequences(seqtab)))) #simple plot of length distribution


#### STEP 7. Remove chimeras ####
# Chimeric sequences are identified if they can be exactly reconstructed by 
# a left-segment and a right-segment from two more abundant “parent” sequences
# Takes 12s on M2
# Takes 1 Min on i7
seqtab.nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = FALSE,
                                    verbose = TRUE)
saveRDS(seqtab.nochim, "seqtab.nochim.rds")
# Get some stats:
# Compute % of non chimeras
paste0("% of non chimeras : ", sum(seqtab.nochim)/sum(seqtab) * 100)
paste0("total number of sequences : ", sum(seqtab.nochim))

# What are chimeras, and why do we remove them? How is it done in Dada2?

#### Track number of reads at each step
getN <- function(x) sum(getUniques(x)) # example of a function in R

track <- cbind(out, sapply(dada_R1, getN), sapply(mergers, getN), rowSums(seqtab),
               rowSums(seqtab.nochim))

colnames(track) <- c("input", "filtered", "denoised", "merged", "tabled", "nonchim")
rownames(track) <- sample.names

#View the output
track

#### Transforming and saving the ASV sequences
seqtab.nochim_trans <- as.data.frame(t(seqtab.nochim)) %>% rownames_to_column(var = "sequence") %>%
  rowid_to_column(var = "ASVNumber") %>% mutate(ASVNumber = sprintf("ASV_%05d",
                                                                    ASVNumber)) %>% mutate(sequence = str_replace_all(sequence, "(-|\\.)", ""))

#### Extract the sequences and export them in a fasta file:
df <- seqtab.nochim_trans
seq_out <- Biostrings::DNAStringSet(df$sequence)
names(seq_out) <- df$ASVNumber
seq_out

Biostrings::writeXStringSet(seq_out, str_c(dada2_dir, "ASV_no_taxonomy.fasta"),
                            compress = FALSE, width = 20000)
#### STEP 8. Assigning taxonomy
# The PR2 database can be found here:
# https://pr2-database.org/
# The PR2 database has pre-formatted files suitable for dada2  for both 18S and 16S
#
# This step depends on the kind of taxonomic assignment that will be used later
# The PR2 database is a curated quality database for protists, with 8 taxonomic ranks
# Version 5.1.0 was released March 2025
url <- "https://github.com/pr2database/pr2database/releases/download/v5.1.0/pr2_version_5.1.0_SSU_dada2.fasta.gz"
download.file(url, "databases/pr2_version_5.1.0_SSU_dada2.fasta.gz")
pr2_file <- paste0("databases/pr2_version_5.1.0_SSU_dada2.fasta.gz")

# The newest version of pr2 has 9 taxonomic ranks:
PR2_tax_levels <- c("Domain", "Supergroup", "Division", "Subdivision", 
  "Class", "Order", "Family", "Genus", "Species", "Accession")

# OBS! The next step takes a long time, and it requires quite a lot of memory. It might take hours, depending on the computer.
# And it might not run at all. 
# So we will not execute it here! I usually run this on a Computing cluster.  
# taxa <- assignTaxonomy(seqtab.nochim, refFasta = pr2_file, taxLevels = PR2_tax_levels,
#                      minBoot = 50, outputBootstraps = TRUE, verbose = TRUE, multithread = TRUE)

# Instead I have prepared the object on github.
# In R it is possible sot save objects, or the full workspace.
# Single objects can be saved to a file with the saveRDS() function
# Example:
# saveRDS(taxa, str_c(dada2_dir, "taxa.rds"))
# it can be downloaded from github directly: 
taxa <- readRDS(gzcon(url("https://github.com/krabberod/BIO9905MERG1_V25/raw/main/Dada2_Pipeline/taxa.rds")))
taxa_df <- as_tibble(taxa)
taxa_df$ASVNumber <- names(seq_out)
taxa_df <- taxa_df %>% relocate(ASVNumber, .before = everything())

# Optionally, save the results to a CSV
write.csv(taxa_df, "dada2_results/taxonomic_assignments_with_bootstrap.csv", row.names = FALSE)

#### Appending taxonomy and boot to the sequence table ####
seqtab.nochim_trans <- full_join(taxa_df,seqtab.nochim_trans)

#Check at the Kingdom-level for
unique(seqtab.nochim_trans$tax.Domain)
unique(seqtab.nochim_trans$tax.Supergroup)
table(seqtab.nochim_trans$tax.Division)

#### Filter for 18S ####
# Define a minimum bootstrap value for filtering
# Think before applying the cut-off! What is the benefits of removing
# OTUs with low support? What are the drawbacks?

bootstrap_min <- 80
# Remove ASVs with annotation below the bootstrap value
seqtab.nochim_18S <- seqtab.nochim_trans %>% dplyr::filter(boot.Supergroup >= bootstrap_min)
# Equivalent code in base R
seqtab.nochim_18S <- seqtab.nochim_trans[which(table_with_taxonomy$boot.Supergroup>80),]

unique(seqtab.nochim_18S$tax.Division)
sort(unique(seqtab.nochim_18S$tax.Family))

# Example for removing Metazoans: 
seqtab.nochim_18S_noMetazoa <- seqtab.nochim_18S[which(seqtab.nochim_18S$tax.Division!="Metazoa"),]
# What are those with low support? 
seqtab.nochim_18S_lowsupport<- seqtab.nochim_trans %>% dplyr::filter(boot.Supergroup <= bootstrap_min)


write_tsv(seqtab.nochim_18S, str_c(dada2_dir, "ASV_table.tsv"))
write_tsv(seqtab.nochim_18S_noMetazoa, str_c(dada2_dir, "ASV_table_noMetazoa.tsv"))
write_tsv(seqtab.nochim_18S_lowsupport, str_c(dada2_dir, "ASV_table_lowsupport.tsv"))

####  Write FASTA file for BLAST or similar analysis ####
# Blasting is an alternative to RDP classifier:

df <- seqtab.nochim_trans
seq_out <- Biostrings::DNAStringSet(df$sequence)

names(seq_out) <- str_c(df$ASVNumber, df$tax.Domain, df$tax.Supergroup, df$tax.Division, df$tax.Subdivision, df$tax.Class,
                        df$tax.Order, df$tax.Family, df$tax.Genus, df$tax.Species, sep = "|")

Biostrings::writeXStringSet(seq_out, str_c(blast_dir, "OTU.fasta"), compress = FALSE,
                            width = 20000)


#### Make Phyloseq Object ####
samdf <- data.frame(sample_name = sample.names)
rownames(samdf) <- sample.names
otu_df <- as.data.frame(seqtab.nochim_18S)

rownames(otu_df) <- seqtab.nochim_18S$ASVNumber


OTU <- otu_df %>% select_if(is.numeric) %>%
  select(-contains("boot.")) %>% as.matrix() %>% otu_table(taxa_are_rows = TRUE)

TAX <- seqtab.nochim_18S %>% select(tax.Domain:tax.Species) %>%
  as.matrix() %>% tax_table()
rownames(TAX) <- seqtab.nochim_18S$ASVNumber

ps_dada2 <- phyloseq(OTU, sample_data(samdf), TAX)
colnames(tax_table(ps_dada2)) <- gsub("^tax\\.", "", colnames(tax_table(ps_dada2)))

### Saving and loading data ####
# You can save selected objects:
saveRDS(ps_dada2, str_c(dada2_dir, "phyloseq.rds"))
# ps_dada2<-readRDS(str_c(dada2_dir, "phyloseq.rds"))

# Or save the entire workspace:
# save.image("dada2.RData")

# Which can be loaded with:
# Can be loaded with
# load("dada2.RData"")


### HERE ENDS THE DADA 2 Pipeline ####
### THE FOLLOWING ARE SOME EXAMPLES###
# In the following you will get some examples from the library phyloseq
# See the content of the object: 
ps_dada2
rank_names(ps_dada2)
otu_table(ps_dada2)

### Bar graphs ####
# Phyloseq contains wrappers for plotting functions
plot_bar(ps_dada2)
plot_bar(ps_dada2, fill = "Supergroup")
plot_bar(ps_dada2, fill = "Division")

# Make it a bit better with
plot_bar(ps_dada2, fill = "Division")+
  geom_bar(aes(color=Division, fill=Division), stat="identity", position="stack")


### Subsetting taxa ####
SAR <- subset_taxa(ps_dada2,  Division %in% c("Alveolata","Stramenopiles","Rhizaria"))

plot_bar(SAR, fill = "Division") +
  geom_bar(aes(color=Division, fill=Division), stat="identity", position="stack")


### Plot only teh Rhizarian orders 
Rhizaria <- subset_taxa(ps_dada2, Division %in% c("Rhizaria"))

plot_bar(Rhizaria, x="Order", fill = "Order") +
  geom_bar(aes(color=Order, fill=Order), stat="identity", position="stack") +
  theme(legend.position="none", axis.text.x = element_text(angle = 45, hjust = 1))


### Calculate relative abundance  ####
ps_dada2_rel <- transform_sample_counts(ps_dada2, function(x) x / sum(x))
plot_bar(ps_dada2_rel, fill = "Division") +
  geom_bar(aes(color = Division, fill = Division), stat = "identity", position = "stack") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

### Normalization using median sequencing depth ####
total <- median(sample_sums(ps_dada2))
standf <- function(x, t=total) round(t * (x / sum(x)))
ps_dada2_trans <- transform_sample_counts(ps_dada2, standf)
plot_bar(ps_dada2_trans, fill = "Division")+
  geom_bar(aes(color=Division, fill=Division), stat="identity", position="stack")


# For example one can only take OTUs that represent at least 5% of reads in at least one sample.
ps_dada2_rel_abund <- filter_taxa(ps_dada2_rel, function(x) any(x > 0.05), prune = TRUE)

plot_bar(ps_dada2_rel_abund, fill = "Division")+
  geom_bar(aes(color=Division, fill=Division), stat="identity", position="stack")

# Phyloseq has inbuilt functions to plot heatmaps
plot_heatmap(ps_dada2_rel_abund, method = "MDS", distance = "bray", #
             taxa.label = "Genus", taxa.order = "Genus",
             trans=NULL, low="beige", high="red", na.value="beige")

# ordination of samples:
ps_dada2_rel.ord <- ordinate(ps_dada2_rel, "DCA", "bray")
plot_ordination(ps_dada2_rel, ps_dada2_rel.ord, type="samples")
plot_ordination(ps_dada2_rel, ps_dada2_rel.ord, type="taxa", color="Supergroup",
                title="OTUs")

#### Microbiome ####
# Another package with many interesting functions is Microbiome. It is an extension to phyloseq
# https://microbiome.github.io/tutorials/

