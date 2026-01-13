# Annotation Pipeline <a name="top"/> for Bioconductor Version 3.23

The goal of the code in this ~~package~~ repository is to build the db0, OrgDb, PFAM, GO, 
and TxDb packages. As of Bioconductor 3.5 we no longer build KEGG, ChipDb, 
probe or cdf packages. BSGenome, SNPlocs, and XtraSNPlocs packages are built 
by Herve. 

The build system is based on a set of bash and R scripts, in various 
different directories that are called by the top-level `master.sh` script 
which calls sub-scripts. The following document goes through the steps of 
running the pipeline in more detail.

### Table of Contents
+ [Pipeline prep](#pipelineprep)
+ [Update R](#updater)
+ [Download data](#downloaddata)
+ [Parse data](#parsedata)
+ [Build data](#builddata)
+ [Additonal scripts](#additionalscripts)
+ [Build db0 packages](#builddb0pkgs)
+ [Build OrgDb, PFAM.db, and GO.db packages](#buildmanypkgs)
+ [Build TxDb packages](#buildtxdbpkgs)
+ [Where do they belong?](#where)
+ [Clean up](#cleanup)
+ [Troubleshooting](#troubleshooting)

## Pipeline prep <a name="pipelineprep"/>

The first step of the pipeline is to log onto the `generateAnnotationsV2` EC2 
instance as `ubuntu`. Downloading the data and generating the annotation 
packages will take up over 100GB of disk space on the instance. Be sure to 
have this amount of space otherwise the process will fail. It never hurts to do 
a pull of the repo to be sure everything is up to date before running the 
pipeline.

```sh
git pull
``` 

**TODO:** Decide on a minimum amount of required space for the scripts to run.

The clean up step should have been performed at the end of the pipeline 
during the last release, but if it was not here are a couple ways to 
potentially clean up the instance:

* Remove old files from the `db/` directory and only save the
`metadata.sqlite` and the `map_counts.sqlite` files (under version
control in case they get deleted). **Do not remove any files from
`db/` once the parsing has started.** Products sent there are either
needed in a subsequent step or may be the final product.  * Remove
older data downloads from each folder, there should only be one
version present. It is suggested to keep the previous version for
comparison/ testing.

[Back to top](#top)

## Update R <a name="updater"/>

In order for the packages to be built for the next Bioconductor release, the 
R version on `ubuntu` may have to be updated. This should be done as `root` 
and the packages will be installed as `ubuntu`. There is a README.md file 
(`home/ubuntu/downloads/README.md`) with basic instructions on how to do this 
but the following will provide some additional details.

**1. Download the correct version of R**

For the Spring release, download R-devel. For the Fall release
download the latest patched release version.

```sh
wget https://cran.r-project.org/src/base/R-4/<correct R-version>
```

**2. Extract the tar file**

```sh
tar zxf <correct R-version>
```

**3. Change into the directory and make**

```sh
cd <correct R-version>
sudo ./configure --enable-R-shlib 
make
```
R is run directly from this directory, so no need to do `make
install`, or to point to a prefix dir.

**4. Clean up  the installations**

Previous versions of R can be deleted, but it may be advantageous to
keep the one from the last build.

**5. Set up proper path**

Since we run R from the build dir, open `.bashrc` and adjust the path
to point to the current version of R, as well as the library
dir. Mostly this means edit the location of the R install location,
which points to the R build dir. Note that in the past we used aliases
to point to R, but when running R from within a bash script the
aliases are ignored and the site-wide R installation is used instead.

```sh
export PATH=/home/ubuntu/R-devel/bin:$PATH
```
The `.bashrc` now points to `R_LIBS_USER` as well, so it might no
longer be necessary to have that included in the alias for `R`.

**6. Install packages**

Run the following commands to install the packages that are needed for this 
pipeline to work properly.

```r
chooseCRANmirror()
install.packages("BiocManager")
```
We always build using Bioc-devel. If building in Spring using R-devel,
do

```r
library(BiocManager)
BiocManager::install(ask = FALSE)
```
for the Fall build it's slightly different

```r
library(BiocManager)
BiocManager::install(version = "devel", ask = FALSE)
```
**7. Clone and modify AnnotationDbi or AnnotationForge**

There is always the possibility that either AnnotationForge or
AnnotationDbi will need to be modified in order to successfully build
the annotations. In which case they can be cloned on the AWS instance
and modified there (but the AWS user doesn't have developer rights at
git.bioconductor.org) or the modifications can be made on a separate
computer that does have developer access, and then just cloned using
`git clone
https://git.bioconductor.org/packages/AnnotationForge`. Regardless,
any changes made to either package should be propagated back to the
master branch. If there are significant changes that need to be made,
first fork into your own github repo, then clone on AWS, then make a
new branch, do all the changes there, and once they are finalized and
the package will build and check the fork can be merged back into
master and propagated back to the master branch on
git@git.bioconductor.org. 

[Back to top](#top)

## Download data <a name="downloaddata"/>

Now that the instance is cleaned up (`BioconductorAnnotationPipline/` - 141G) 
and the R version is updated it is time to start downloading the data 
needed to create the packages. This can be done by running the command:

```sh
sh src_download.sh
```

There are data-specific directories that contain their own specific
`script/download.sh` scripts. These data-specific scripts are called
by the 'master' `src_download.sh` script. While the script can be run
as a whole, a better idea is to run one data type at a time. In other
words, it is possible to just run the `master.sh` script, or to run
`src_downoad.sh`, but that does not usually work well, because the
script runs for a while and then errors out, and then you must figure
out where the error occurred in order to fix it. This is tedious and
boring and unnecessary.

A smarter idea is to inspect the `src_download.sh` script, and run
each step by hand, which is essentially cd'ing to each subdirectory
(e.g., ~/BioconductorAnnotationPipeline/ensembl/script) and then doing
`./download.sh`. When the inevitable error occurs you know which
step failed and can then start to debug. Most of the download scripts
assume something about the source of the data, such as the directory
structure of an ftp resource, and if the provider has made any changes
the script will no longer work correctly, and it is then a matter of
figuring out what has changed in order to get the script to work.

Most of the data directories include an `env.sh` script that queries
the resource to infer if any changes have been made to the data. If
not, the download will normally not occur. However, this is also a
frailty in the system because the `env.sh` script assumes that there
are files on the resource that can be queried to infer changes. If
this is no longer the case, this script will fail as well.

This `env.sh` script is also used to infer the date the data were
generated, but is not always accurate. As an example, for UCSC the
timestamp of the directory from which the data were retrieved was used
to infer if the data had changed. However, there are hundreds of files
in that directory and we only download four, so it is unlikely that a
change in the directory timestamp tells us anything about changes in a
small subset of the files. A better idea might be to simply report
**when** the data were download rather than inferring the age of
individual files. Since the `env.sh` script for UCSC did not check the
file timestamp, we were downloading the same files repeatedly,
thinking they had been updated. As of 2024-Sept, we now use rsync to
download the files from UCSC, which will only download files that
change. We do not try to infer the timestamp on these files, but
instead simply report the date we ran the download script instead.

Using rsync in this case is a consequence of UCSC redirecting the URI
that we previously used to infer the timestamp. Previously we could
use cURL to get the timestamps for all the species-level data
directories, but now that URI redirects to an interactive page (e.g.,
we used cURL to go to hgdownload.cse.ucsc.edu/goldenPath and get the
directory timestamps, but now that redirects to an interactive HTML
page so it no longer works).

For everything but UCSC, the date in `env.sh` is incremented, and a
new directory for the downloaded files is created (e.g.,
~/BioconductorAnnotationPipeline/annnosrc/ensembl/ will have several
date directories containing data). Unless/until we convert to using
rsync to get data, all but the previous download dir should be
deleted. It is nice to have the previous download in case you need to
compare what you got last time to what you got this time. For UCSC,
there are individual species subdirs, and in each of them there is
just one called `current` from which rsync is called. The obvious
downside of using rsync is that we will replace any changed file and
will not have the files from last time to compare to.

**Data-specific directories:**
* go
	+ ftp://ftp.geneontology.org/pub/go/godatabase/archive/latest-lite/
	+ Appears to be current, now updated weekly.
	+ Check `GOSOURCEDATE` in `go/script/env.sh`.
* unigene
	+ unigene is now defunct. As of Bioconductor 3.13 it isn't used
	+ However, the directory still exists, but you can ignore it
	+ Last downloads are from 2013. 
* gene
	+ ftp://ftp.ncbi.nlm.nih.gov/gene/DATA
	+ Updated daily.
	+ Used to create organism specific sqlite data. We only keep 
	gene2accession and gene2unigene mapping data extracted from both Entrez Gene 
	and UniGene used to generate the probe to Entrez Gene mapping for individual 
	chips.
	+ Check `EGSOURCEDATE` in `gene/script/env.sh`.
	+ As of Bioconductor 3.13 we also download orthology data to
	make the Orthology.eg.db package.
* goext
	+ http://www.geneontology.org/external2go
	+ Maps GO to external classification systems (other vocabularies).
	+ Check `GOEXTSOURCEDATE` in `goext/script/env.sh`.
* ucsc
	+ ftp://hgdownload.cse.ucsc.edu/goldenPath/
	+ Source code ranges from 2010-present because genome update occur at 
	different times.
	+ Check `GPSOURCEDATE_*` for each of the organisms in 
	`ucsc/script/env.sh`.
	+ Manually update `BUILD_*` with the most current build for each of 
	the organisms in `ucsc/script/env.sh`.
* yeast
	+ http://downloads.yeastgenome.org/
	+ Check `YGSOURCEDATE` in `yeast/script/env.sh`.
* ensembl
	+ ftp://ftp.ensembl.org/pub/current_fasta
	+ Download fasta cdna and pep files.
	+ Check `ENSOURCEDATE` in `ensembl/script/env.sh`.
* plasmoDB
	+ http://plasmodb.org/common/downloads/release-28/Pfalciparum3D7/txt/
	+ We are using release 28 (March 2016) and the most current version 
	is 31 (March 2017). We use version 28 because that is the last time the 
	PlasmoDB-28_Pfalciparum3D7Gene.txt file was provided and that's what the code 
	is set up to parse. 
	+ **TODO:** Don't see a clear replacement - the information might be 
	available in another file in the directory but it will take some investigation.
	+ Check `PLASMOSOURCEDATE` in `plasmoDB/script/env.sh`.
	+ The plan as of Bioconductor 3.13 is to deprecate and then
	defunct the plasmo data, but that may take some investigation
	because some of the ChipDb packages may have those data as well?
* pfam
	+ ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release
	+ Protein families represented by multiple sequence alignments.
	+ Check `PFAMSOURCEDATE` in `pfam/script/env.sh`.
* inparanoid
	+ This has been superceded by the Orthology.eg.db package, and
	won't build or supply these packages after Bioc 3.13
	+ The scripts in this directory update flybase which is still active.
	+ ftp://ftp.flybase.net/releases/current/precomputed_files/genes/
	+ Check `FBSOURCEDATE` in `inparanoid/script/env.sh`.
	+ Manually update `FILE` in `inparanoid/script/env.sh`.
* tair
	+ The FTP site contains old data; we now rely on their HTTPS site
	for data. Unfortunately it's not easily queryable to get the
	relevant files, so this part is by hand.
	+ In the env.sh script there are a bunch of URLs to
	arabidopsis.org. To check these and find updated files, go to
	https://www.arabidopsis.org/, then click on the 'Download' link at
	the top.
	+ Using the URLs in the env.sh file (e.g.,
	www.arabidopsis.org/download_files/Genes/TAIR10_genome_release),
	click on the relevant links in the Download drop-down until you
	get to the correct folder and see if there are new data available.
	+ So for the previous example, it would be Downloads, then Genes,
	which opens up an ftp-like page. Choose the most recent TAIR
	release (currently TAIR10_genome_release) and look for the
	TAIR10_functional_descriptions file. If it's changed, update in
	the env.sh. Rinse and repeat for all the URLs in the env.sh file.
	+ Check `TAIRSOURCEDATE` in `tair/script/env.sh` to ensure it's current
* KEGG
	+ KEGG data are no longer available for download.
	+ **TODO:** Look into replacing it with `KEGGREST` package.
	+ Probably a better idea is to just query the KeGG REST API
 	directly, as there are still MAP tables in the OrgDb packages.
	+ Should be doable for Bioc 3.14

When the `src_download.sh` script is done running, confirm that the new data 
has been downloaded by checking for the date-specific directory. If no new 
data was downloaded and it should have been, check the 
[Troubleshooting](#troubleshooting) section of this README file for further 
instructions.

For the Bioconductor 3.10 release, the `go`, `gene`, `ucsc`, and `ensembl` 
directories had new data downloaded to them. After running the 
`src_download.sh` script was run, 5G of information was added to the pipeline 
(`BioconductorAnnotationPipeline/` - 146G).

[Back to top](#top)

## Parse data <a name="parsedata"/>

The next step in the pipeline is to run the parse scripts. This can be done by 
running the command:

```sh
sh src_parse.sh
```

The `src_parse.sh` script calls data-specific `getsrc.sh` scripts which calls 
data-specific `srcdb.sql` (or `srcdb_*` if there are many organisms). This step 
will either

* parse the download data,
* create databases to be used in the build step (e.g. `ensembl.sqlite`), or
* produce the final database product (e.g. `PFAM.sqlite`). 

As with the download step, it is much easier/better to simply inspect
the `src_parse.sh` script and then run each step by hand (which is
mostly cd'ing into each directory and then running
`./getsrc.sh`). There are inevitably some changes to the files that
will cause one or more scripts to break, and it is much easier to
debug when you know exactly what script failed. The scripts can be run
in any order, but for tracking progress it is much easier to simply
follow the order in `src_parse.sh` and check them off as they are
accomplished.

The parsing step adds a lot of data to `BioconductorAnnotationPipeline/`. For 
the Bioconductor 3.10 release, the parse step increased the data by 49G 
(`BioconductorAnnotationPipeline/` - 195G).

[Back to top](#top)

## Build data <a name="builddata"/>

After parsing the data it's time to build the data. To build the data the 
following command is run:

```sh
src_build.sh
```

Again, it is better to simply run each step separately. **Do note that
the order matters for this step!** Some of the scripts rely on data
generated by previous scripts and if you get out of order they will
fail.

As with the previous steps, this is mostly cd'ing into the 'scripts'
dir in each subdirectory and running `./getdb.sh`. In the right
order. This mostly runs sqlite3 using a set of .sql files, although
some data are parsed using R scripts. There can be errors with both
(due to changes in the expected format of the files that are read into
a SQLite DB or connection errors when R is downloading data, etc).


The products from the build step are the `chipsrc*.sqlite` and 
`chipmapsrc*.sqlite` databases in `db/`.

**TODO:** I think more comments could be added to track the progress along the 
way.

Refer to the [Troubleshooting](#troubleshooting) section of this README file for 
advice if the build step goes awry.

The build step will add about 66G of data to the pipeline. For the Bioconductor 
3.10 release, at the end of the building step the 
`BioconductorAnnotationPipeline/` was up to 261G.

[Back to top](#top)

## Additional scripts <a name="additionalscripts"/>

There are 2 additional scripts that need to be run after the data is built. The 
first script is run by:

```sh
sh copyLatest.sh
```

This script inserts database schema version in the GO, PFAM, KEGG and YEAST 
databases. The next script, which is found in `map_counts/scripts/`:

```sh
sh getdb.sh
```

is used to check the quality of the intermediate sql databases. This script 
counts tables in a subset of the `chipsrc` databases. These numbers are then 
recorded in the existing `map_counts.sqlite` file. The data is compared to 
numbers from the last release. There is a warning that is issued for 
discrepancies >10%. Remember `map_counts.sqlite` is under version control so 
there are records of data loss/gain over the releases. If
`map_counts.sqlite` is inadvertently deleted, it will be re-generated
using the map_counts data from the existing installed db0, GO.db, and
KEGG.db packages.

There is an additional test that can be run in the same directory:

```r
R --slave < testDbs.R
```

which will go through each of the tables in
each of the sqlite files in the db/ subdirectory, looking for any rows
that have empty ('') values for all columns except for the primary key
column. If any are found, it will print out the sqlite file name and
the table name. 

At this point all code changes should be committed to git. No data files should be 
added. The ubuntu user doesn't have access to the GitHub repo, so
pushing commits is a roundabout process. Here's the high level
version. *This assumes that you are a contributor on the Bioconductor
GitHub repo. If not ask Lori Shepherd - Kern to add you.*

+ Fork [the
Github](Githttps://github.com/Bioconductor/BioconductorAnnotationPipeline)
to your own personal GitHub repo.
+ Generate a [classic authentication
token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
for your repo. On the page where it asks what level of control, click
the first checkbox, for full repo control. The default lifetime for
the token is 30 days, which could be set to something much
shorter. Copy the token for the next step.
+ On AWS, add your personal repo using `git remote add temp https://<token
goes here>@github.com/<your user
name>/BioconductorAnnotationPipeline.git`
+ Push to your repo `git push temp master`
+ On your local repo (that has access to both the Bioconductor and
your forked version of the repo), pull the commit that you just sent
to your fork.
+ On that same local repo, push the changes up to the Bioconductor
repo.
+ You could then also do `git remote rm temp` on AWS

[Back to top](#top)

## Build db0 packages <a name="builddb0pkgs"/>

Now that all the data is built, it is time to start building the
annotation packages that will be part of the Bioconductor release.
The first set of packages that should be built are the db0 packages,
e.g., `human.db0`, `mouse.db0`.

**1. Make edits to makeDbZeros.R**

There are two variables in the R script that should be updated. The `outDir` 
should be set to a valid date for when the script is being run. This will 
become the name of the directory that will house the db0 packages being created. 
The `version` should be a valid version depending on what the Bioconductor 
release will be, e.g., for the October 2019 Bioconductor 3.10 release `version` 
was set to "3.10.0". This will become the version for all the db0 packages.
 
**2. Run makeDbZeros.R**

```sh
R --slave < makeDbZeros.R
```

This script creates the db0 packages by calling 
`AnnotationForge::sqlForge_wrapBaseDBPkgs.R`. 

**3. Build, check, and install db0 packages**

Each of the db0 packages in `BioconductorAnnotationPipeline/newPipe/XXXXXXXX_DB0s/`
need to be built and checked using `R CMD build` and `R CMD check`. 

If all the packages build and check without error then the packages should be 
installed using `R CMD INSTALL`. 

The only things that need to be kept in the db0 package directory is the tarball 
files created by `R CMD build`. The repos and the check logs can all be deleted.


[Back to top](#top)

## Build OrgDb, PFAM.db, and GO.db packages <a name="buildmanypkgs"/>

In order for the OrgDb, PFAM.db, and GO.db packages to get built the db0 
packages must be built first. If the db0 packages have not been built yet, please 
refer to the [Build db0 packages](#builddb0pkgs) section above.

**1. Update version of packages**

All the code needed to build these packages is located in the
installed AnnotationForge package, in
~/R-libraries/AnnotationForge/extdata/GentlemanLab/ANNDBPKG-INDEX.TXT. This
file has old incorrect version numbers, as well as incorrect
directories. It's a pain to fix this by hand, so there is a bash
script in the `newPkgs` subdirectory called `fixAnnoFile.sh` that will
do this for you. Just call that script, with a new version. Something
like

```sh

fixAnnoFile.sh 3.12.0

```
which was correct for Bioc 3.12. This will fix the portion of that
file that we still use (the majority is intended for ChipDb packages).

**1. Run makeTerminalDBPkgs.R**

This is an Rscript that expects to get the correct values passed
in as arguments. There are three arguments; what type of package to
generate (OrgDb or TxDb), the directory to put the data (just the
date, in yyyymmdd format, like 20200920), and the version (like 3.12.0)

```r
Rscript makeTerminalDBPkgs.R OrgDb 20200920 3.12.0
```

Which will build all the `OrgDb` packages in the 20200920_OrgDbs
directory, with 3.12.0 as the version.

Because we removed UniGene and added Gene type data to the OrgDb and
ChipDb packages in 3.13, we had to rebuild all the ChipDb packages to
reflect those changes. There are three scripts called getAnnos.R,
getUpdatedAnnotations.R, and makeTranscriptPkgs.R that can be used to
do that, if necessary. For the older set of Affy arrays (everything
before the Gene ST and Exon ST arrays), there is functionality in
AnnotationForge to parse the Affy CSV annotation file, and getAnnos.R
simply downloads all those files using the AffyCompatible package and
then builds. Remember to update the hard-coded version number and
build dir in that script.

For the newer arrays the annotation CSV files are too complicated for
the parser that exists in AnnotationForge. And it's probably not worth
adding a parser for those files, given that we usually just increment
the version rather than re-building each release. Anyway,
getUpdatedAnnotations.R will download all the newer Affy array CSV
files, and then makeTranscriptPkgs.R will parse and build. The version
is hard-coded and has to be changed. The script just builds the
packages wherever they were downloaded, so after building/checking,
move those tar.gz files in with the other ChipDb packages so they can
all be uploaded to malbec1.

**2. Build, check, and install the new packages**

`R CMD build`, `R CMD check`, and `R CMD INSTALL` the new `GO.db` package before 
building and checking the OrgDbs. Continue building, checking, and installing 
for all of the OrgDbs and PFAM.db.

**3. Spot check**

Open an R session and load a newly created OrgDb object, e.g., `org.Hs.eg.db`, to 
ensure that all resources are up-to-date. Specifically, check the GO and ENSEMBL 
download dates in the metadata of the object. These should be more recent than 
the last release. 

```r
> library(org.Hs.eg.db)
> org.Hs.eg.db
OrgDb object:
| DBSCHEMAVERSION: 2.1
| Db type: OrgDb
| Supporting package: AnnotationDbi
| DBSCHEMA: HUMAN_DB
| ORGANISM: Homo sapiens
| SPECIES: Human
| EGSOURCEDATE: 2019-Jul10
| EGSOURCENAME: Entrez Gene
| EGSOURCEURL: ftp://ftp.ncbi.nlm.nih.gov/gene/DATA
| CENTRALID: EG
| TAXID: 9606
| GOSOURCENAME: Gene Ontology
| GOSOURCEURL: ftp://ftp.geneontology.org/pub/go/godatabase/archive/latest-lite/
| GOSOURCEDATE: 2019-Jul10
| GOEGSOURCEDATE: 2019-Jul10
| GOEGSOURCENAME: Entrez Gene
| GOEGSOURCEURL: ftp://ftp.ncbi.nlm.nih.gov/gene/DATA
| KEGGSOURCENAME: KEGG GENOME
| KEGGSOURCEURL: ftp://ftp.genome.jp/pub/kegg/genomes
| KEGGSOURCEDATE: 2011-Mar15
| GPSOURCENAME: UCSC Genome Bioinformatics (Homo sapiens)
| GPSOURCEURL:
| GPSOURCEDATE: 2019-Sep3
| ENSOURCEDATE: 2019-Jun24
| ENSOURCENAME: Ensembl
| ENSOURCEURL: ftp://ftp.ensembl.org/pub/current_fasta
| UPSOURCENAME: Uniprot
| UPSOURCEURL: http://www.UniProt.org/
| UPSOURCEDATE: Mon Oct 21 14:24:25 2019

Please see: help('select') for usage information
```
Much like the db0 packages, the only products that need to remain in the OrgDb 
directory are the tarball files from `R CMD build`. Everything else can be 
removed.

[Back to top](#top)

## Build TxDb packages <a name="buildtxdbpkgs"/>

**1. Identify which tracks should be updated**

Information should be compared between what is currently available on
[Bioconductor](https://www.bioconductor.org/packages/release/BiocViews.html#___TxDb)
devel and what is currently available on the [UCSC Genome
Browser](https://genome.ucsc.edu/cgi-bin/hgGateway). For example, for
the package `TxDb.Hsapiens.UCSC.hg38.knownGene`, go to the
[hgTables](https://genome.ucsc.edu/cgi-bin/hgTables) page on the UCSC
Genome Browser. Select Mammal for clade, Human for genome, and
Dec.2013 (GRCh38/hg38) for the assembly. Then choose Genes and gene
Predictions for group, and (usually) the first choice for track. As of
2024, that would be GENCODE V44. Then click the 'data format
description' button.  At the top of the next webpage, check the 'Date
last updated'. If this date is newer than the last release then this
package needs to be updated. This should be repeated for all of the
packages available on Bioconductor.

It is also important to identify tracks that may not be available yet on 
Bioconductor because these may be new packages that can be added. 

**NOTE:** If any of the new tracks that aren't available yet on Bioconductor are 
have NCBI Ref Seq data, then let Herve know so he can edit the code in 
`GenomicFeatures`.

**2. Edit makeTerminalDBPkgs.R**

After figuring out which `TxDb` packages need to be updated, edit
makeTerminalDBPkgs.R under the `TxDb` section, updating the
`speciesList` vector and the corresponding `tableList` vector to
include all the species that need to be updated, and the tables from
which to get the data.

**3. Run makeTerminalDBPkgs.R**

Run the portion of `makeTerminalDBPkgs.R` that generates the TxDb packages.

```sh
Rscript makeTerminalDBPkgs.R TxDb 20200920 3.12.0
```

Which will generate the `TxDb` packages and put them in 20200920_TxDbs.

**4. Build, check, and install TxDb packages**

Run `R CMD build`, `R CMD check`, and `R CMD INSTALL` for all of the newly 
created TxDb packages. Load a few of the packages in an R session and check the 
dates to be sure that the appropriately dated packages are being used.

Like the other packages that were created the only files that need to remain in 
the TxDb directory are the tarball files from `R CMD build`, everything else 
can be deleted. 

[Back to top](#top)

## Where do they belong? <a name="where"/>

The tarball files for all the db0, OrgDb, PFAM.db, GO.db, and TxDb packages 
created from `R CMD build` need to get on the linux builder for the release. The 
following example shows how to do this for the 3.10 release of Bioconductor.

**1. Log onto the builder**

For the 3.10 release, the builder is `malbec1` so log onto this user as 
`biocadmin`. This will change between `malbec1` and `malbec2` from release to 
release, edit accordingly. Then change into the `sandbox` directory.

```sh
ssh biocadmin@malbec1.bioconductor.org

cd sandbox
```

**2. Copy the tarball files over**

The files from the EC2 instance need to get copied over to `malbec1:sandbox/`. 
The public IP for the EC2 instance will change each time it is stopped and 
restarted, edit accordingly.

```sh
scp -r ubuntu@18.209.179.34:/home/ubuntu/BioconductorAnnotationPipeline/newPipe/20191011_DB0s/ .
```

This should be repeated for the OrgDb and TxDb directories that were created in 
the previous steps.

**3. Check file sizes**

It is good practice to be sure files were copied over correctly. This can be 
done by using `cksum` of a file on the instance and comparing it to the `cksum`
of the same file on `malbec1:sandbox/`. For example,

```sh
# on EC2 instance
cd newPipe/20191011_DB0s/
cksum human.db0_3.10.0.tar.gz

# on malbec1:sandbox/
cksum human.db0_3.10.0.tar.gz
```

The two numbers produced from cksum should be the same. This mean that all of 
the information was copied over from the instance to the builder.

**4. Copy the files to contrib/**

Once it is clear all the information has been copied over correctly then the 
files can be copied over to their final destination.

```sh
# on malbec1:sandbox/
cd 20191011_DB0s
scp -r . /home/biocadmin/PACKAGES/3.10/data/annotation/src/contrib
```

**5. Check file sizes again**

Repeat `cksum` on the files, comparing between the `malbec1:sandbox/` copy and 
the `/home/biocadmin/PACKAGES/3.10/data/annotation/src/contrib/` copy.

**6. Remove old versions**

For the new annotation packages, there should be older versions already present 
on the builder. These old versions should be removed. Be sure to only remove 
versions that are getting replaced because once they are removed they can't be 
recovered again.

**7. Run crontab job**

The final step is to run a crontab job on the builder, but isn't part of this 
pipeline. For further instructions on how to accomplish this step please see the 
**NAME OF FILE** at https://github.com/Bioconductor/BBS/tree/master/Doc.

Once the crontab job has completed, the landing pages have been updated on devel 
(which will become release), and the VIEWS have been updated than announce the 
new annotation packages are available.

[Back to top](#top)

## Clean up <a name="cleanup"/>

All data has been created and all packages have been built, it's time to clean 
up! Run through each section of this pipeline and remove any unnecessary copies 
of data. Below is a list of areas that can be cleaned before stopping the EC2 
instance.

* `BioconductorAnnotationPipeline/annosrc/`
	+ `db/` -  everything besides the `metadatasrc.sqlite` file
	+ `ensembl/` - any outdated data
	+ `gene/` - any outdated data
	+ `go/` - any outdated data
	+ `goext/` - any outdated data
	+ `inparanoid/` - any outdated data
	+ `pfam/` - any outdated data
	+ `plasmoDB/` - any outdated data
	+ `tair/` - any outdated data
	+ `ucsc/` - any outdated data
	+ `unigene/` - any outdated data
	+ `yeast/` - any outdated data

* `BioconductorAnnotationPipeline/newPipe/`
	+ any outdated `XXXXXXXX_DB0s/`
	+ any outdated `XXXXXXXX_OrgDbs/`
	+ any outdated `XXXXXXXX_TxDbs/`
* `malbec1:sandbox/` (or `malbec2:sandbox/` depending on release)
	+ any outdated `XXXXXXXX_DB0s/`
	+ any outdated `XXXXXXXX_OrgDbs/`
	+ any outdated `XXXXXXXX_TxDbs/`

[Back to top](#top)

## Troubleshooting <a name="troubleshooting"/>

This section will help to explain some areas of trouble while running the 
pipeline. Some issues might have happened by chance and therefore weren't 
documented here. Troubleshooting will continue to be updated as persistent 
issues arise.

### Downloading data

**1. Connectivity issues**

Since the download step accesses online resources, there are possiblities for 
connectivity issues. The only solution for this is to try to rerun the download 
script. For example, when running the download script for 'ucsc' there was an 
error due to a connectivity issue. The first step in the script is to test if 
the directory is present, if not it creates the directory and downloads the 
data. If the directory is already present nothing is downloaded. When the 'ucsc' 
script errored out, it was trying to access data for 'human'. The directory 
'2019-Jun6' was created and no data was downloaded because of a connectivity 
issue. When trying to rerun the script, it is assumed the data was already 
downloaded since the directory is present. To avoid missed data, the created 
directory should be removed and the `GPSOURCEDATE` in `script/env.sh` should be 
set to back to the last release date. 

[Back to top](#top)
