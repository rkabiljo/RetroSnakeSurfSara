# RetroSnakeSurfSara

This is a SnakeMake pipeline based on RetroSeq https://github.com/tk2/RetroSeq,  a tool for discovery of transposable element variants.
The pipeline runs RetroSeq configured to seach for HERV-K insertions, filters RetroSeq predictions and verifies the insertions by assembling the regions around each insertion and running the assembled contigs through RepeatMasker.

<div align="center">
    <img src="DAG_SurfSaraRetroSnake.jpg" width="400px"</img> 
</div>


# Basic Setup
open config.yaml file and update all directories: e.g. CRAM or BAM file path; output directory path; RepeatMasker path; 


## Reference genome
If you already have a reference genome (and it is indexed), update the path to it in config.yaml
If you do not, run the script downloadHG19.sh in order to install it and index it.
```
bash downloadHG19.sh PATH_TO_DIR_TO_PLACE_REFERENCE_GENOME
```
update the path to the newly added and indexed human genome in config.yaml

``

# Installing Dependencies

## RepeatMasker
https://github.com/rmhubley/RepeatMasker
RepeatMasker is needed for the verification step.  Without it you can still run RetroSeq and filter the insertions.

Important:
After the installation of RepeatMasker, update the installation path in the config.yaml file.

## Running the pipeline 
Once the paths in config.yaml point to CRAM/BAM path, path to the reference genome and the output path - you can run the pipeline on the provided sample.bam in order to predict insertions, filter them and split them in known and novel.

If the SAMPLES variable in Snakefile is updated to contain a list of samples, you can run it like this, for cores use the number of samples that can be run in parallel:

```
snakemake --use-conda --use-envmodules --cores 20
```

or to run on a single file:

```
snakemake --use-conda --use-envmodules --cores 1 <MY_OUTPUT_DIRECTORY>{/filter/sample.bed,/confirmed/sample.retroseqHitsConfirmed.bed}
```

