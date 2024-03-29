#!/bin/sh
#set -e

## Copy select dbs to newPipe/ and insert schema version.

BASEVERSION=2.1

COPYFROM=/home/ubuntu/BioconductorAnnotationPipeline/annosrc/db/
COPYTO=/home/ubuntu/BioconductorAnnotationPipeline/newPkgs/sanctionedSqlite

cp ${COPYFROM}GO.sqlite ${COPYTO}
cp ${COPYFROM}PFAM.sqlite ${COPYTO}
cp ${COPYFROM}KEGG.sqlite ${COPYTO}
cp ${COPYFROM}YEAST.sqlite ${COPYTO}
cp ${COPYFROM}Orthology.eg.sqlite ${COPYTO}

cd ${COPYTO}

## Remove org.*.sqlite files to avoid UNIQUE contstraint error.
rm org.*

for file in `ls *.sqlite`
do
 echo "INSERT INTO metadata VALUES('DBSCHEMAVERSION', '$BASEVERSION');" > temp_metadata.sql
 sqlite3 -bail $file < temp_metadata.sql
 rm -f temp_metadata.sql
done
