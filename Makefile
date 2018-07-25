SHELL:=/bin/bash
NXF_VER:=0.30.0
EP:=

# ~~~~~ SETUP PIPELINE ~~~~~ #
./nextflow:
	if [ "$$( module > /dev/null 2>&1; echo $$?)" -eq 0 ]; then module unload java && module load java/1.8 ; fi ; \
	export NXF_VER="$(NXF_VER)" && \
	printf ">>> Installing Nextflow in the local directory" && \
	curl -fsSL get.nextflow.io | bash

install: ./nextflow

input:
	unzip input.zip

variant_paths.txt: input
	find input -mindepth 2 -type f -name "*data.tsv" > variant_paths.txt
find: variant_paths.txt


# ~~~~~ RUN ~~~~~ #
run: install find
	if [ "$$( module > /dev/null 2>&1; echo $$?)" -eq 0 ]; then module unload java && module load java/1.8 ; fi ; \
	./nextflow run main.nf -resume



# ~~~~~ CLEANUP ~~~~~ #
clean-traces:
	rm -f trace*.txt.*

clean-logs:
	rm -f .nextflow.log.*

clean-reports:
	rm -f *.html.*

clean-flowcharts:
	rm -f *.dot.*

clean-output:
	[ -d output ] && mv output oldoutput && rm -rf oldoutput &

clean-work:
	[ -d work ] && mv work oldwork && rm -rf oldwork &

# deletes files from previous runs of the pipeline, keeps current results
clean: clean-logs clean-traces clean-reports clean-flowcharts

# deletes all pipeline output in current directory
clean-all: clean clean-output clean-work
	rm -rf input
	rm -f variant_paths.txt
	[ -d .nextflow ] && mv .nextflow .nextflowold && rm -rf .nextflowold &
	rm -f .nextflow.log
	rm -f *.png
	rm -f trace*.txt*
	rm -f *.html*
