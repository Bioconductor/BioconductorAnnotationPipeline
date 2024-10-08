#!/bin/sh
set -e

## Download and parse the idmapping file first
## switched this from
# url=https://ftp.expasy.org/databases/uniprot/current_release/knowledgebase/idmapping/idmapping_selected.tab.gz
## because expasy appears to be super slow. cURL might be slow as well, so might need to switch to wget in future if
## it keeps being that way

url=https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/idmapping_selected.tab.gz
curl --fail --disable-epsv -O $url

zcat idmapping_selected.tab.gz |
    awk -F'\t' 'BEGIN{
    	       val[9615]
	       val[9823]
	       val[7165]
	       val[8355]
	       val[9544]
	       val[9598]
	       }
	       $13 in val' OFS='\t' - | gzip > tmp.gz

mv tmp.gz idmapping_selected.tab.gz

R --slave < ./byPassBlast2GoAndInsteadUseUniProt.R

