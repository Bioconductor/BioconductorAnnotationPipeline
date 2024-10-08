## db0 packages must be generated and installed before creating OrgDb, ChipDb, etc.
.libPaths("~/R-libraries")
library(AnnotationForge)
outDir = "./20240923_DB0s"
if (!file.exists(outDir)) 
    dir.create(outDir)

## Create db0s:
version <- "3.20.0"
dbPath = "/home/ubuntu/BioconductorAnnotationPipeline/annosrc/db/"
wrapBaseDBPackages(dbPath=dbPath, destDir=outDir, version=version)
