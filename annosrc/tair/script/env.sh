#!/bin/sh
set -e
# These are all direct links to HTML resources. The FTP equivalents seem old, and
# trying to figure out how to automatically get these URLs seems... difficult. For now
# just update the TAIRSOURCEDATE to today's date after checking by hand to see if the links still match what's
# on arabidopsis.org

# We can't just use the current day if we run the scripts that rely on this script on different days
# so we check the most recent dir in ../ that starts with a number, and if it's less than a week old,
# we just use that.
CURDIR=`ls -dt ../* | awk -e '$1 ~ /..\/[0-9]+/ {print $1}' | head -n 1`
CDATE=`date -r $CURDIR +%s`
NOW=`date +%s`
DAYDIFF=$(((NOW - CDATE)/86400))

if [ "$DAYDIFF" -gt  7 ]; then
    export TAIRSOURCEDATE=`date +%Y-%b%d`
else
    export TAIRSOURCEDATE=`echo $CURDIR | sed 's/\.\.\///'`
fi

export TAIRSOURCENAME="Tair"
export TAIRSOURCEURL="https://www.arabidopsis.org/"

export TAIRGOURL="https://www.arabidopsis.org/download_files/GO_and_PO_Annotations/Gene_Ontology_Annotations/ATH_GO_GOSLIM.txt"
export TAIRGOURLNAME="ATH_GO_GOSLIM.txt"

export TAIRGENEURL="https://www.arabidopsis.org/download_files/Genes/TAIR10_genome_release/TAIR10_functional_descriptions"
export TAIRGENEURLNAME="TAIR10_functional_descriptions"

export TAIRSYMBOLURL="https://www.arabidopsis.org/download_files/Public_Data_Releases/TAIR_Data_20190630/gene_aliases_20190630.txt.gz"
export TAIRSYMBOLURLNAME="gene_aliases_20190630.txt.gz"

export TAIRPATHURL="ftp://ftp.plantcyc.org/Pathways/Data_dumps/PMN14_January2020/pathways/Ara_pathways.20200125"
export TAIRPATHURLNAME="Ara_pathways.20200125"

export TAIRPMIDURL="https://www.arabidopsis.org/download_files/Public_Data_Releases/TAIR_Data_20190630/Locus_Published_20190630.txt.gz"
export TAIRPMIDURLNAME="Locus_Published_20190630.txt.gz"

export TAIRCHRURL="https://www.arabidopsis.org/download_files/Maps/seqviewer_data/sv_gene.data"
export TAIRCHRURLNAME="sv_gene.data"

export TAIRATHURL="https://www.arabidopsis.org/download_files/Microarrays/Affymetrix/affy_ATH1_array_elements-2010-12-20.txt"
export TAIRATHURLNAME="affy_ATH1_array_elements-2010-12-20.txt"

export TAIRAGURL="https://www.arabidopsis.org/download_files/Microarrays/Affymetrix/affy_AG_array_elements-2010-12-20.txt"
export TAIRAGURLNAME="affy_AG_array_elements-2010-12-20.txt"

export TAIRGFF="https://www.arabidopsis.org/download_files/Genes/TAIR10_genome_release/TAIR10_gff3/TAIR10_GFF3_genes.gff"
export TAIRGFFURLNAME="TAIR10_GFF3_genes.gff"
