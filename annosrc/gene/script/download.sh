#!/bin/sh
set -e
. ./env.sh

BASE_URL=$EGSOURCEURL
PARENT_URL=$EGSOURCEURL/..
LATEST_DATE=`curl --fail -IL $EGSOURCE_DATE_URL | grep "Last-Modified" | awk '{print $5 "-" $4 $3}'`

if [ -z "$LATEST_DATE" ]; then
       echo "download.sh: latest date from $BASEURL not found"
       exit 1
fi

if [ "$LATEST_DATE" != "$EGSOURCEDATE" ]; then
	echo "update crossreferences from $EGSOURCENAME to other databases from $EGSOURCEDATE to $LATEST_DATE"
        sed -i -e "s/ EGSOURCEDATE=.*$/ EGSOURCEDATE=$LATEST_DATE/g" env.sh
	mkdir ../$LATEST_DATE
	cd ../$LATEST_DATE
	curl --fail --disable-epsv -O $BASE_URL/gene2go.gz
	curl --fail --disable-epsv -O $BASE_URL/gene2pubmed.gz
	curl --fail --disable-epsv -O $BASE_URL/gene2refseq.gz
	curl --fail --disable-epsv -O $BASE_URL/gene2accession.gz
	# FIXME
	# UniGene is dead now, so gene2unigene doesn't exist
	# just copy from previous download for now
	## maybe this should just go away
	## It's gone now
	## cp ../$EGSOURCEDATE/gene2unigene .
	#curl --fail --disable-epsv -O $BASE_URL/gene2unigene
	curl --fail --disable-epsv -O $BASE_URL/mim2gene_medgen
	curl --fail --disable-epsv -O $BASE_URL/gene_info.gz
	curl --fail --disable-epsv -O $BASE_URL/gene_refseq_uniprotkb_collab.gz
	# get orthologs for orthology mapping package
	curl --fail --disable-epsv -O $BASE_URL/gene_orthologs.gz
	curl --fail --disable-epsv -O $BASE_URL/../../pub/taxonomy/new_taxdump/new_taxdump.tar.gz
	cd ../script
	#sh getsrc.sh
else
	echo "the latest crossreferences from $EGSOURCENAME to other databases are still $EGSOURCEDATE"
fi
