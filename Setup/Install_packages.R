# BIO9905MERG1_V23
# Please make sure that you have the required R packages installed.
# You can get a list of the package already installed on your computer s by executing

installed.packages()

# in R alternatively you can just run the installation for each package
# to make sure that you have the latest version.
# Run these installation commands line-by-line in R (or Rstudio)
# and answer yes if you are asked to update any previously installed packages:

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
# If you run into problems when running the above line try to install one package
# at the time. i.e.: 
# if (!requireNamespace("BiocManager", quietly = TRUE)) 
#   install.packages("BiocManager")
#   BiocManager::install("dada2")

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
# This package might cause a problem. Here are some possible solutions:
# https://thecoatlessprofessor.com/programming/cpp/r-compiler-tools-for-rcpp-on-macos/
# https://stackoverflow.com/questions/37776377/error-when-installing-an-r-package-from-github-could-not-find-build-tools-neces

# Network packages as example
# library(devtools)
# install_github("zdk123/SpiecEasi")
# BiocManager::install("SpiecEasi") # Network construction
# install.packages("wTO") 	# Newtork analysis
# install.packages("igraph")	# Network analysis
# 

