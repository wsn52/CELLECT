from snakemake.utils import min_version

import os
import re

min_version("5.4")



_ILLEGAL_ID_PATTERN = r"\s|__|/"

########################################################################################
################################### FUNCTIONS ##########################################
########################################################################################

def check_safe_id(list_of_strings):
	"""
	Returns False if any string in list_of_strings contains the patterns defined in _ILLEGAL_ID_PATTERN.
	"""
	for val in list_of_strings:
		if re.search(_ILLEGAL_ID_PATTERN, val):
			return False
	return True

	# for val in list_of_strings:
	# 	if any(val in ILLEGAL for ILLEGAL in _ILLEGAL_ID_PATTERN):
	# 		return False
	# return True
	

def check_conditional_and_heritability_inputs(dict_dataset_annotations, annotations_dict):
	"""
	dict_dataset_annotations: keys are dataset ids, values are list of 'selected' annotations to perform analysis on (e.g. conditional or h2)
	Checks:
		1. check that dict_dataset_annotations['id'] matches SPECIFICITY_INPUT id's
		2. check that dict_dataset_annotations['annotations'] exists in annotations
	Returns False if does not pass checks, otherwise True
	"""
	for key in dict_dataset_annotations:
		if not key in annotations_dict:
			raise Exception("[dataset id = {}] used for conditional or heritability analysis but the id was not found in the SPECIFICITY_INPUT. Check your config file".format(key))
		# if not all(dict_dataset_annotations[key] in annotations_dict[key]):
		for annotation in dict_dataset_annotations[key]:
			if annotation not in annotations_dict[key]:
				raise Exception("[annotation={}] in [dataset id = {}] in conditional or heritability analysis was not found in the annotations of the SPECIFICITY_INPUT. Check your config file".format(annotation, key))




def get_annots(specificity_input_dict):
	"""
	Pulls all the annotations from each specificity matrix file and saves them into a dictionary.
	"""
	# Snakemake rules need to know the output files before the rule executes - this function gets the names
	# of annotations because the "COMBINED_ANNOT" files are split into "{annotation name}" files
	annots_dict = {}
	for key, dictionary in specificity_input_dict.items():
		with open(dictionary['path']) as f:
			annotations = f.readline().strip().split(',')
			# if annotations[0] =='gene': # Checks if there is a name for the index or not - currently only works if index name is 'gene', needs to be more robust
			# 	annotations = annotations[1:]
			annots_dict[key] = annotations[1:] # key is dataset name | [1:] skip first column because it the the 'gene' column
	return(annots_dict)


def make_prefix__annotations(prefix, annotations):
	"""
	Makes a list containing the prefix appended to each annotation in the multigeneset file.
	"""
	# This function should possibly be moved into make_cts_file_snake.py - I can't remember
	# why I decided to put it here
	pa_list = []
	for annot in annotations:
		pa_list.append(prefix+'__'+annot)
	return(pa_list)

def build_dict_from_id_filepath_key_value_pairs(list_of_dicts):
	'''
	Each dict in the list in MUST contain the keys 'id' and 'path'.
	path will be converted to absolute paths.
	Takes the list of dictionaries and makes it into a new dictionary where the keys are the id values from each dictionary and the values are each dictionary
	e.g. [{"id":"a", "value": 1}, {"id":"b","value":2}] ->
	{"a":{"id":"a", "value": 1}, "b":{"id":"b","value":2}}
	'''
	out_dict = {}
	for d in list_of_dicts:
		d['path'] = os.path.abspath(d['path'])
		out_dict[d['id']] = d 
	return(out_dict)

def build_dict_of_dataset_selected_annotations(list_of_dicts):
	"""
	list_of_dicts: list of dicts. Each dict in the list in MUST contain the keys 'id' and 'annotations'.
		list_of_dicts[0]['id']: string
		list_of_dicts[0]['annotations']: list
	returns dict[<id>] = [annotations]
	"""
	dataset_annots_dict = {}
	for d in list_of_dicts:
		dataset_annots_dict[d['id']] = d['annotations']
	return(dataset_annots_dict)

########################################################################################
################################### VARIABLES ##########################################
########################################################################################

configfile: 'config-ldsc.yml'

# Where all CELLECT-LDSC output will be saved
BASE_WORKING_DIR = os.path.abspath(config['BASE_OUTPUT_DIR'])

PRECOMP_DIR = os.path.join(BASE_WORKING_DIR, 'pre-computation') # Where most files are made
OUTPUT_DIR = os.path.join(BASE_WORKING_DIR, 'out') # Where only the final cell-type results are saved

WINDOWSIZE_KB = config['LDSC_VAR']['WINDOW_SIZE_KB']
SNP_WINDOWS = config['LDSC_VAR']['WINDOW_LD_BASED']


SPECIFICITY_INPUT = build_dict_from_id_filepath_key_value_pairs(config['SPECIFICITY_INPUT'])
GWAS_SUMSTATS = build_dict_from_id_filepath_key_value_pairs(config['GWAS_SUMSTATS'])

# Output file prefixes
RUN_PREFIXES = list(SPECIFICITY_INPUT.keys())

# Reads the first line of each specificity matrix and saves the annotations
# as lists where the key is the assigned run prefix
ANNOTATIONS_DICT = get_annots(SPECIFICITY_INPUT)


### Conditional
CONDITIONAL_INPUT = build_dict_of_dataset_selected_annotations(config['CONDITIONAL_INPUT'])
RUN_PREFIXES_COND = list(CONDITIONAL_INPUT.keys()) # NB: this can be a subset of the RUN_PREFIXES

### Heritability
HERITABILITY_INPUT = build_dict_of_dataset_selected_annotations(config['HERITABILITY_INPUT'])
RUN_PREFIXES_H2 = list(HERITABILITY_INPUT.keys()) # NB: this can be a subset of the RUN_PREFIXES


########################################################################################
################################### CONSTANTS ##########################################
########################################################################################

DATA_DIR = os.path.abspath(config['LDSC_CONST']['DATA_DIR'])
LDSC_DIR = os.path.abspath(config['LDSC_CONST']['LDSC_DIR'])

BFILE_PATH = os.path.join(DATA_DIR,"1000G_EUR_Phase3_plink/1000G.EUR.QC")
PRINT_SNPS_FILE = os.path.join(DATA_DIR,"print_snps.txt")
GENE_COORD_FILE =os.path.join(DATA_DIR,'gene_annotation.hsapiens_all_genes.GRCh37.ens_v91.LDSC_fmt.txt')
LD_SCORE_WEIGHTS = os.path.join(DATA_DIR,"1000G_Phase3_weights_hm3_no_MHC/weights.hm3_noMHC.")
LDSC_BASELINE = os.path.join(DATA_DIR,"baseline_v1.1_thin_annot/baseline.")
SNPSNAP_FILE = os.path.join(DATA_DIR,"ld0.5_collection.tab.gz")

LDSC_SCRIPT = os.path.join(LDSC_DIR,'ldsc.py')

# These environment variables control how many cores numpy can use
# Setting to 1 allows snakemakme to use 1 core per active rule i.e. snakemake core usage = actual core usage
os.environ["MKL_NUM_THREADS"] = str(config['LDSC_CONST']['NUMPY_CORES'])
os.environ["NUMEXPR_NUM_THREADS"] = str(config['LDSC_CONST']['NUMPY_CORES'])
os.environ["OMP_NUM_THREADS"] = str(config['LDSC_CONST']['NUMPY_CORES'])

CHROMOSOMES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] 
# OBS: this workflow supports computing LDSC scores for the chromosomes specified in this list. 
# 	   but due to the LDSC software (_N_CHR variable) the LDSC regression have to be run on all chromosomes to work.
# 	   hence the rule 'run_gwas' will fail if not running on all chromosomes.



########################################################################################
############################# Pre-check of inputs #######################################
########################################################################################

if not os.access(BASE_WORKING_DIR, os.W_OK):
	raise IOError("BASE_WORKING_DIR is not writable.")

if not (config['ANALYSIS_MODE']['prioritization'] or config['ANALYSIS_MODE']['conditional'] or config['ANALYSIS_MODE']['heritability']):
	raise Exception("At least one ANALYSIS_MODE must be true.")

### Check names/ids
if not check_safe_id(list(GWAS_SUMSTATS.keys())):
	raise Exception("Illegal charecters in GWAS SUMSTATS id's. Illegal charecters=[{}]".format(_ILLEGAL_ID_PATTERN))
if not check_safe_id(list(SPECIFICITY_INPUT.keys())):
	raise Exception("Illegal charecters in SPECIFICITY_INPUT id's. Illegal charecters=[{}]".format(_ILLEGAL_ID_PATTERN))
for key in ANNOTATIONS_DICT:
	if not check_safe_id(ANNOTATIONS_DICT[key]):
		raise Exception("Illegal charecters in SPECIFICITY_INPUT={} annotation names. Illegal charecters=[{}]".format(key, _ILLEGAL_ID_PATTERN))


if config['ANALYSIS_MODE']['conditional']: 
	check_conditional_and_heritability_inputs(CONDITIONAL_INPUT, ANNOTATIONS_DICT)

if config['ANALYSIS_MODE']['heritability']: 
	check_conditional_and_heritability_inputs(RUN_PREFIXES_H2, ANNOTATIONS_DICT)

########################################################################################
################################### Target files ##########################################
########################################################################################


list_target_files = []

if config['ANALYSIS_MODE']['prioritization']: 
	tmp = expand("{OUTPUT_DIR}/prioritization/{run_prefix}__{gwas}.cell_type_results.txt",
				run_prefix = RUN_PREFIXES,
				OUTPUT_DIR = OUTPUT_DIR,
				gwas = list(GWAS_SUMSTATS.keys()))
	list_target_files.extend(tmp)


if config['ANALYSIS_MODE']['conditional']: 
	for prefix in RUN_PREFIXES_COND:
		tmp = expand("{OUTPUT_DIR}/conditional/{run_prefix}__{gwas}__CONDITIONAL__{annotation_cond}.cell_type_results.txt",
									run_prefix = prefix,
									OUTPUT_DIR = OUTPUT_DIR,
									gwas = list(GWAS_SUMSTATS.keys()),
									annotation_cond = CONDITIONAL_INPUT[prefix])
		list_target_files.extend(tmp)

if config['ANALYSIS_MODE']['heritability']: 
	raise Exception("Not implemented yet")



########################################################################################
################################### PIPELINE ##########################################
########################################################################################




rule all: 
	'''
	Defines the final target files to be generated.
	'''
	input:
		list_target_files

rule make_multigenesets:
	'''
	Makes a specificity input multigeneset and an all genes background multigeneset from each specificty input matrix.
	'''
	input:
		lambda wildcards: SPECIFICITY_INPUT[wildcards.run_prefix]['path']
	output:
		"{PRECOMP_DIR}/multi_genesets/multi_geneset.{run_prefix}.txt",
		"{PRECOMP_DIR}/multi_genesets/all_genes.multi_geneset.{run_prefix}.txt"
	conda:
		"envs/cellectpy3.yml"
	params:
		out_dir = "{PRECOMP_DIR}/multi_genesets",
		specificity_matrix_file = lambda wildcards: SPECIFICITY_INPUT[wildcards.run_prefix]['path'],
		specificity_matrix_name = "{run_prefix}"
	script:
		"scripts/make_multigenesets_snake.py"

###################################### CREATE ANNOTATIONS ######################################

if SNP_WINDOWS == True: # Only use SNPs in LD with genes. 

	rule join_snpsnap_bims:
		'''
		Joins SNPsnap file with genes to input BIM file for all chromosomes
		'''
		input:
			"{bfile_path}.CHR_1_22.bim".format(bfile_path = BFILE_PATH),
			"{SNPSNAP_FILE}".format(SNPSNAP_FILE = SNPSNAP_FILE)
		output:
			expand("{{PRECOMP_DIR}}/SNPsnap/SNPs_with_genes.{bfile_prefix}.{chromosome}.txt",
					bfile_prefix = os.path.basename(BFILE_PATH),
					chromosome = CHROMOSOMES) # we don't delete this 'tmp file' because it can be reused for other runs?
		conda:
			"envs/cellectpy3.yml"
		params:
			out_dir = "{PRECOMP_DIR}/SNPsnap",
			chromosomes = CHROMOSOMES,
			snpsnap_file = SNPSNAP_FILE,
			bfile = BFILE_PATH
		script:
			"scripts/join_SNPsnap_and_bim_snake.py"

	rule make_snpsnap_annot:
		'''
		Make the annotation files for input to LDSC from multigeneset files using SNPsnap, LD-based windows
		'''
		input:
			"{PRECOMP_DIR}/multi_genesets/multi_geneset.{run_prefix}.txt",
			"{{PRECOMP_DIR}}/SNPsnap/SNPs_with_genes.{bfile_prefix}.{{chromosome}}.txt".format(bfile_prefix = os.path.basename(BFILE_PATH))
		output:
			"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.annot.gz" # *TEMP FILE*
		conda:
			"envs/cellectpy3.yml"
		params:
			chromosome = "{chromosome}",
			run_prefix = "{run_prefix}",
			precomp_dir = "{PRECOMP_DIR}",
			all_genes = False,
			bfile = BFILE_PATH
		script:
			"scripts/generate_SNPsnap_windows_snake.py"

	rule make_snpsnap_annot_all_genes:
		'''
		Make the annotation files for input to LDSC from multigeneset files using SNPsnap, LD-based windows
		'''
		input:
			"{PRECOMP_DIR}/multi_genesets/all_genes.multi_geneset.{run_prefix}.txt",		
			expand("{{PRECOMP_DIR}}/SNPsnap/SNPs_with_genes.{bfile_prefix}.{chromosome}.txt",
					bfile_prefix = os.path.basename(BFILE_PATH),
					chromosome = CHROMOSOMES)
		output:
			"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.annot.gz" # *TEMP FILE*
		conda:
			"envs/cellectpy3.yml"
		params:
			chromosome = "{chromosome}",
			run_prefix = "{run_prefix}",
			precomp_dir = "{PRECOMP_DIR}",
			all_genes = True,
			bfile = BFILE_PATH
		script:
			"scripts/generate_SNPsnap_windows_snake.py"

else: # Use SNPs in a fixed window size around genes

	for prefix in RUN_PREFIXES:
	# Need to use a loop to generate this rule and not wildcards because the output depends
	# on the run prefix used 
	# https://stackoverflow.com/questions/48993241/varying-known-number-of-outputs-in-snakemake
		ANNOTATIONS = ANNOTATIONS_DICT[prefix]
		rule: # format_and_map_genes
			'''
			Read the multigeneset file, parse and make bed files for each annotation geneset
			'''
			input:
				"{{PRECOMP_DIR}}/multi_genesets/multi_geneset.{prefix}.txt".format(prefix=prefix)
			output:
				expand("{{PRECOMP_DIR}}/{{prefix}}/bed/{{prefix}}.{annotation}.bed",annotation = ANNOTATIONS) # *TEMP FILE*
			conda:
				"envs/cellectpy3.yml"
			params:
				run_prefix = prefix,
				windowsize_kb =  WINDOWSIZE_KB,
				bed_out_dir = "{{PRECOMP_DIR}}/{prefix}/bed".format(prefix=prefix),
				gene_coords = GENE_COORD_FILE
			script:
				"scripts/format_and_map_snake.py"

	rule format_and_map_all_genes:
		'''
		Works exactly the same way as format_and_map_genes, 
		but this version was a workaround to overcome
		the awkward wildcards and to make snakemake 
		run the same rule twice - on our dataset of interest (fx tabula muris)
		and on the (control) all_genes_in_dataset
		'''
		input:
			"{PRECOMP_DIR}/multi_genesets/all_genes.multi_geneset.{run_prefix}.txt"
		output:
			"{PRECOMP_DIR}/control.all_genes_in_dataset/bed/{run_prefix}.all_genes_in_dataset.bed"  
		conda:
			"envs/cellectpy3.yml"
		params:
			run_prefix = "{run_prefix}",
			windowsize_kb =  WINDOWSIZE_KB,
			bed_out_dir =  "{PRECOMP_DIR}/control.all_genes_in_dataset/bed",
			gene_coords = GENE_COORD_FILE
		script:
			"scripts/format_and_map_snake.py"

	rule make_annot:
		'''
		Make the annotation files used to generate LD scores from multigeneset files
		'''
		input:
			lambda wildcards: expand("{{PRECOMP_DIR}}/{{run_prefix}}/bed/{{run_prefix}}.{annotation}.bed",
					annotation = ANNOTATIONS_DICT[wildcards.run_prefix]),
			expand("{bfile_path}.{chromosome}.bim",
					bfile_path = BFILE_PATH,
					chromosome = CHROMOSOMES)
		output:
			"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.annot.gz" # *TEMP FILE*
		conda:
			"envs/cellectpy3.yml"
		params:
			run_prefix = "{run_prefix}",
			chromosome = "{chromosome}",
			out_dir = "{PRECOMP_DIR}/{run_prefix}",
			bfile = BFILE_PATH,
			all_genes = False,
			annotations = lambda wildcards: ANNOTATIONS_DICT[wildcards.run_prefix]
		script:
			"scripts/make_annot_from_geneset_all_chr_snake.py"

	rule make_annot_all_genes:
		'''
		Make the annotation files used to generate LD scores for all genes from the all genes multigeneset files
		'''
		input: 
			"{PRECOMP_DIR}/control.all_genes_in_dataset/bed/{{run_prefix}}.all_genes_in_dataset.bed".format(PRECOMP_DIR = PRECOMP_DIR), # PRECOMP_DIR should work with just wildcard but doesn't ??
			expand("{bfile_prefix}.{chromosome}.bim",
					bfile_prefix = BFILE_PATH,
					chromosome = CHROMOSOMES)
		output:
			"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.annot.gz" # not temp because used in regrssion
		conda:
			"envs/cellectpy3.yml"
		params:
			run_prefix = "{run_prefix}",
			all_genes = True,
			chromosome = "{chromosome}",
			out_dir = PRECOMP_DIR + "/control.all_genes_in_dataset",
			annotations = ["all_genes_in_dataset"],
			bfile = BFILE_PATH
		script:
			"scripts/make_annot_from_geneset_all_chr_snake.py"


###################################### COMPUTE LDSC SCORES ######################################

rule compute_LD_scores: 
	'''
	Compute the LD scores prior to running LD score regression
	'''
	input:
		"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.annot.gz"
	output:
		"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.l2.ldscore.gz",  # *TEMP FILE*
		"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.l2.M", # *TEMP FILE*
		"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.l2.M_5_50", # *TEMP FILE*
		"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.log" # *TEMP FILE*
	wildcard_constraints:
		chromosome="\d+" # chromosome must be only a number, not sure if redundant (also have placed it in this rule arbitrarily)
	params:
		chromosome = '{chromosome}',
		run_prefix = '{run_prefix}'
	conda: # Need python 2 for LDSC
		"envs/cellectpy27.yml"
	shell: 
		"{LDSC_SCRIPT} --l2 --bfile {BFILE_PATH}.{params.chromosome} --ld-wind-cm 1 \
		--annot {PRECOMP_DIR}/{params.run_prefix}/{params.run_prefix}.COMBINED_ANNOT.{params.chromosome}.annot.gz \
		--thin-annot --out {PRECOMP_DIR}/{params.run_prefix}/{params.run_prefix}.COMBINED_ANNOT.{params.chromosome} \
		--print-snps {PRINT_SNPS_FILE}"

rule compute_LD_scores_all_genes: 
	'''
	Compute the LD scores prior to running LD score regression
	'''
	input:
		"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.annot.gz"
	output:
		"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.l2.ldscore.gz",
		"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.l2.M",
		"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.l2.M_5_50",
		"{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix}.{chromosome}.log"
	wildcard_constraints:
		chromosome="\d+" # chromosome must be only a number, not sure if redundant (also have placed it in this rule arbitrarily)
	params:
		chromosome = '{chromosome}',
		run_prefix = '{run_prefix}'
	conda: # Need python 2 for LDSC
		"envs/cellectpy27.yml"
	shell: 
		"{LDSC_SCRIPT} --l2 --bfile {BFILE_PATH}.{params.chromosome} --ld-wind-cm 1 \
		--annot {PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{params.run_prefix}.{params.chromosome}.annot.gz \
		--thin-annot --out {PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{params.run_prefix}.{params.chromosome} \
		 --print-snps {PRINT_SNPS_FILE}"


for prefix in RUN_PREFIXES:
# Need to use a loop to generate this rule and not wildcards because the output depends on the run prefix used 
# https://stackoverflow.com/questions/48993241/varying-known-number-of-outputs-in-snakemake
	ANNOTATIONS = ANNOTATIONS_DICT[prefix]
	rule: # split_LD_scores 
		'''
		Splits the files made during the compute LD scores step by annotation
		'''
		input:
			"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.l2.ldscore.gz",
			"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.l2.M",
			"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.l2.M_5_50",
			"{PRECOMP_DIR}/{run_prefix}/{run_prefix}.COMBINED_ANNOT.{chromosome}.log"
		output:
			expand("{{PRECOMP_DIR}}/{{run_prefix}}/per_annotation/{{run_prefix}}__{annotation}.{{chromosome}}.l2.ldscore.gz", annotation=ANNOTATIONS)
		conda:
			"envs/cellectpy3.yml"
		params:
			chromosome = '{chromosome}',
			run_prefix = '{run_prefix}',
			out_dir = "{PRECOMP_DIR}/{run_prefix}"
		script:
			"scripts/split_ldscores_snake.py"

###################################### PRIORITIZATION + CONDITIONAL ######################################

rule make_cts_file:
	'''
	Makes the cell-type specific file for LDSC cts option
	'''
	input:
		lambda wildcards : expand("{{PRECOMP_DIR}}/{{run_prefix}}/per_annotation/{{run_prefix}}__{annotation}.{chromosome}.l2.ldscore.gz",
									annotation=ANNOTATIONS_DICT[wildcards.run_prefix],
									chromosome=CHROMOSOMES)
	output:
		"{PRECOMP_DIR}/{run_prefix}.ldcts.txt"
	conda:
		"envs/cellectpy3.yml"
	params:
		chromosome = CHROMOSOMES,
		prefix__annotations = lambda wildcards: make_prefix__annotations(wildcards.run_prefix, ANNOTATIONS_DICT[wildcards.run_prefix])
	script:
		"scripts/make_cts_file_snake.py"

rule prioritize_annotations:
	'''
	Run LDSC in CTS mode with the provided list of GWAS
	'''
	input:
		expand("{PRECOMP_DIR}/{{run_prefix}}.ldcts.txt", PRECOMP_DIR=PRECOMP_DIR),
		lambda wildcards: GWAS_SUMSTATS[wildcards.gwas]['path'],
		expand("{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{{run_prefix}}.{chromosome}.l2.ldscore.gz", 
			PRECOMP_DIR=PRECOMP_DIR,
			chromosome=CHROMOSOMES)
	output:
		"{OUTPUT_DIR}/prioritization/{run_prefix}__{gwas}.cell_type_results.txt"
	params:
		gwas = '{gwas}',
		gwas_path = lambda wildcards: GWAS_SUMSTATS[wildcards.gwas]['path'],
		run_prefix = '{run_prefix}',
		file_out_prefix = '{OUTPUT_DIR}/prioritization/{run_prefix}__{gwas}',
		ldsc_all_genes_ref_ld_chr_name = ',{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{{run_prefix}}.'.format(PRECOMP_DIR=PRECOMP_DIR)
	conda: # Need python 2 for LDSC
		"envs/cellectpy27.yml"
	shell: 
		"{LDSC_SCRIPT} --h2-cts {params.gwas_path} \
		--ref-ld-chr {LDSC_BASELINE}{params.ldsc_all_genes_ref_ld_chr_name} \
		--w-ld-chr {LD_SCORE_WEIGHTS} \
		--ref-ld-chr-cts {PRECOMP_DIR}/{params.run_prefix}.ldcts.txt \
		--out {params.file_out_prefix}"


### Conditional
for run_prefix_cond in RUN_PREFIXES_COND:
	for annot_cond in CONDITIONAL_INPUT[run_prefix_cond]:
	# Need to loop over each annot bc shell() uses whole list of annots as input rather than iterate over each annot
		rule: # run_gwas_conditional:
			'''
			Run LDSC with a list of provided GWAS sum stats but now conditioned on a set of annotations
			''' 
			input:
				expand("{PRECOMP_DIR}/{run_prefix_cond}.ldcts.txt", PRECOMP_DIR=PRECOMP_DIR, run_prefix_cond = run_prefix_cond),
				lambda wildcards: GWAS_SUMSTATS[wildcards.gwas]['path'],
				expand("{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix_cond}.{chromosome}.l2.ldscore.gz", 
					PRECOMP_DIR=PRECOMP_DIR,
					run_prefix_cond = run_prefix_cond,
					chromosome=CHROMOSOMES)
			output:
				expand("{{OUTPUT_DIR}}/conditional/{run_prefix_cond}__{{gwas}}__CONDITIONAL__{annotation_cond}.cell_type_results.txt", 
					  run_prefix_cond = run_prefix_cond,
					  annotation_cond = annot_cond)
			params:
				gwas = '{gwas}',
				gwas_path = lambda wildcards: GWAS_SUMSTATS[wildcards.gwas]['path'],
				run_prefix_cond = run_prefix_cond,
				file_out_prefix = '{{OUTPUT_DIR}}/conditional/{run_prefix_cond}__{{gwas}}__CONDITIONAL__{annotation_cond}'.format(
											run_prefix_cond = run_prefix_cond,
											annotation_cond = annot_cond),
				ldsc_all_genes_ref_ld_chr_name = expand(",{PRECOMP_DIR}/control.all_genes_in_dataset/all_genes_in_{run_prefix_cond}.", 
														PRECOMP_DIR=PRECOMP_DIR, 
														run_prefix_cond = run_prefix_cond), 
				cond_ref_ld_chr_name = ",{PRECOMP_DIR}/{run_prefix_cond}/per_annotation/{run_prefix_cond}__{annotation_cond}".format(
												PRECOMP_DIR = PRECOMP_DIR, 
												run_prefix_cond = run_prefix_cond, 
												annotation_cond = annot_cond),
			conda: # Need python 2 for LDSC
				"envs/cellectpy27.yml"
			shell: 
				"{LDSC_SCRIPT} --h2-cts {params.gwas_path} \
				--ref-ld-chr {LDSC_BASELINE}{params.ldsc_all_genes_ref_ld_chr_name}{params.cond_ref_ld_chr_name}. \
				--w-ld-chr {LD_SCORE_WEIGHTS} \
				--ref-ld-chr-cts {PRECOMP_DIR}/{params.run_prefix_cond}.ldcts.txt \
				--out {params.file_out_prefix}"
