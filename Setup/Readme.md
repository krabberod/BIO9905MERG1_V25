# Installation of R and R packages

We will use R (version 4.0.5 or later) and Rstudio (version 1.4.1 or later) in this course. 

Everybody should download and install R (https://www.r-project.org/), Rstudio (https://posit.co/) and the required packages before the course starts.

It is preferable that you have all packages installed before the course starts. For those of you having trouble with installing the packages, we will provide some help Monday afternoon, after the final lectter, but we will not be able to provide comprehensive IT-service though.

These are the required packages for the hands-on exercises of the course: 
```
##############################
# Core tidyverse and utilities
##############################

install.packages("tidyverse")    # Includes ggplot2, dplyr, tidyr, readr, tibble, stringr, etc.
install.packages("readxl")       # To read Excel files
install.packages("magrittr")     # Provides pipe (%>%) and other functional tools
install.packages("kableExtra")   # Formatting tables in RMarkdown and knitr

##############################
# Bioconductor packages
##############################

if (!requireNamespace("BiocManager", quietly = TRUE)) 
  install.packages("BiocManager")

BiocManager::install(c(
  "dada2",        # Denoising and ASV inference
  "phyloseq",     # Microbiome data handling and visualization
  "Biostrings",   # Efficient string manipulation for biological sequences
  "PCAtools"      # Visualization and exploration of PCA results
))

##############################
# Community ecology and multivariate analysis
##############################

install.packages("vegan")        # Community ecology analyses
install.packages("spaa")         # Species association analysis
install.packages("compositions") # Analyzing compositional data
install.packages("zCompositions")# Handling zeros in compositional data
install.packages("mixOmics")     # Multivariate methods (e.g., PLS-DA, PCA)
install.packages("ape")          # Phylogenetic and evolutionary analyses
install.packages("recluster")    # Clustering and re-clustering methods
install.packages("dendextend")   # Extending and comparing dendrograms
install.packages("corrplot")     # Visualizing correlation matrices
install.packages("RcmdrMisc")    # Miscellaneous statistical functions

##############################
# Microbiome data visualization
##############################

install.packages("metacoder")    # Taxonomic data visualization and manipulation

##############################
# Developer tools and GitHub packages
##############################

install.packages("devtools")     # Tools for developing packages and installing from GitHub
devtools::install_github("pr2database/pr2database")     # PR2 reference database tools
devtools::install_github("GuillemSalazar/EcolUtils")    # Ecological utility functions
devtools::install_github('fawda123/ggord')              # Ordination plots with ggplot2
devtools::install_github("tobiasgf/lulu")               # LULU: post-clustering curation of OTUs
```
When installing Lulu you might run into this error: 

```diff
! "Error: Failed to install 'unknown package' from GitHub:
! Line starting 'E ...' is malformed!"
```

If you get this error one possible solution is to change the locale (run these in R):
```
Sys.setlocale("LC_ALL","en_US.UTF-8")
```
or
```
Sys.setlocale("LC_ALL","English")
```

More packages, including those that have been mentioned, but not necessarily used in the hands-on sessions can be found in the script [R packages](Install_packages.R).