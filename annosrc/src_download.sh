#!/bin/sh
set -e

SRC_BASE=`pwd`

## download source data and parse them into sqlite db files
## no dependencies between data sources, i.e. 
## scripts can be executed in any order

echo "downloading go"
cd $SRC_BASE/go/script; sh download.sh
echo "finished downloading go"

# As of Spring 2021 we no longer use UniGene
# echo "downloading unigene"
# cd $SRC_BASE/unigene/script; sh download.sh  
# echo "finished downloading unigene"

echo "downloading gene"
cd $SRC_BASE/gene/script; sh download.sh
echo "finished downloading gene"

### NOTE: There has been a timeout when downloading data, do by hand
#echo "downloading goext"
#cd $SRC_BASE/goext/script; sh download.sh
#echo "finished downloading goext"

### NOTE: Update genome build versions in env.sh to most current.
echo "downloading ucsc"
cd $SRC_BASE/ucsc/script; sh download.sh 
echo "finished downloading ucsc"

echo "downloading yeast"
cd $SRC_BASE/yeast/script; sh download.sh
echo "finished downloading yeast"

echo "downloading ensembl"
cd $SRC_BASE/ensembl/script; sh download.sh
echo "finished downloading ensembl"

echo "downloading plasmoDB"
cd $SRC_BASE/plasmoDB/script; sh download.sh
echo "finished downloading plasmoDB"

echo "downloading pfam"
cd $SRC_BASE/pfam/script; sh download.sh
echo "finished downloading pfam"

## NOTE: Only downloads the new flybase, not inparanoid.
echo "downloading flybase"
cd $SRC_BASE/inparanoid/script; sh download.sh
echo "finished downloading flybase"

## NOTE: this is updated by hand - compare URLS in ./tair/script/env.sh
## with what is on the various web pages to make sure it points to the newest
## data, and then run the download.sh script
echo "downloading tair"
cd $SRC_BASE/tair/script; sh download.sh
echo "finished downloading tair"

#cd $SRC_BASE
#CURR_DATE=`date|awk '{print $6 "-" $2 $3}'`
##cat */*/env.sh|grep export > env_${CURR_DATE}.sh
