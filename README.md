# CELLECT

**CELL**-type **E**xpression-specific integration for **C**omplex **T**raits (**CELLECT**) is a computational toolkit for  identifing likely etiologic cell-types underlying complex traits. CELLECT leverages existing genetic prioritization models to integrate single-cell transcriptomic and human genetic data when identifing likely etiologic cell-types. 

<!--- v1
![fig-integration](https://user-images.githubusercontent.com/5487016/62281981-0cb33d00-b44f-11e9-8c0b-24aaa2b7d286.png)
--->

<p align="center">
    <img src="https://user-images.githubusercontent.com/5487016/72677599-80e5a980-3a9e-11ea-95c4-ac645cb364a4.png" width="600"/>
</p>




## How does CELLECT work?

CELLECT quantifies the association between common polygenetic GWAS signal (heritability) and cell-type expression specificity (ES) of genes using established genetic prioritization models such as LDSC (Hilary Kiyo Finucane et al., 2015) and MAGMA covariate analysis (Skene et al., 2018). The output of CELLECT is a list of prioritized etiologic cell-types for a given human complex disease or trait.

![fig-CELLECT-regression](https://user-images.githubusercontent.com/5487016/72679543-919f1b00-3ab0-11ea-8d1d-f756fe46a4a0.png)

CELLECT takes as input GWAS data and cell-type expression specificity estimates. In order to compute robust estimates of ES, we developed the computational method called **CELLEX** (**CELL**-type **EX**pression-specificity). CELLEX is built on the observation that different ES metrics provide complementary cell-type expression specific profiles. Our method incorporates a ‘wisdom of the crowd’ approach by integrating multiple ES metrics to obtain improved robustness and a more expressive ES measure that captures multiple aspects of expression specificity.  CELLEX can be found [here](https://github.com/perslab/CELLEX).

<p align="center">
    <img src="https://user-images.githubusercontent.com/5487016/72679609-299d0480-3ab1-11ea-8b05-5c1678ec270a.png" width="600"/>
</p>



*Figure legend: conceptual illustration of CELLECT and CELLEX. The bottom layer shows a disease or trait with multiple genetic components (G1-G4). CELLECT integrates disease heritability estimates with cell-type expression specificity to identify the etiologic cell-types (T1 and T4) underlying the genetic components (G1 and G4). CELLEX estimates expression specificity from single-cell transcriptomic data.*

## Update log

We have implemented CELLECT-LDSC that uses [LDSC](https://github.com/bulik/ldsc) for genetic prioritization. We expect to release CELLECT-MAGMA, CELLECT-RolyPoly and CELLECT-DEPICT in the future. See the [CHANGELOG](https://github.com/perslab/CELLECT/blob/master/CHANGELOG.md) for details.

## Installation

**Step 1: Install git lfs**  
We use [`git lfs`](https://git-lfs.github.com/) to store the [CELLECT data files](https://github.com/perslab/CELLECT/data) on github. To download the files you need to have `git lfs` setup before you clone the repository.
On OSX: `brew install git-lfs; git lfs install` or Ubuntu:`sudo apt-get install git-lfs; git lfs install`. For other operating systems, follow [this guide](https://github.com/git-lfs/git-lfs/wiki/Installation).

**Step 2: Clone CELLECT repository**  
```
git clone --recurse-submodules https://github.com/perslab/CELLECT.git
```
The `--recurse-submodules` is needed to clone the [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) 'ldsc' ([pascaltimshel/ldsc](https://github.com/pascaltimshel/ldsc)), which is a modfied version of the original ldsc repository.
(Cloning the repo might take few minutes as the CELLECT data files (> 1-3 GB) will be downloaded. To skip downloading the data files, use `GIT_LFS_SKIP_SMUDGE=1 git clone --recurse-submodules https://github.com/perslab/CELLECT.git` instead.)

**Step 3: Install Snakemake via conda**  

CELLECT uses the workflow management software [**Snakemake**](https://snakemake.readthedocs.io/en/stable/). To make things easier for you, CELLECT snakemake workflow utilises **conda environments** to avoid any issues with software dependencies and versioning. CELLECT snakemake workflow will automatically install all necessary dependencies. All you need to do is to [install miniconda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) (if conda is not already present on your system) and then install snakemake:
   
```bash
conda install -c bioconda -c conda-forge snakemake=5.4.5
```

## Updating CELLECT

To get the lastest version of CELLECT, update the github repo:

```bash
git pull
```

## Getting started with CELLECT-LDSC

An example configuration file is provided, but requires additional downloads and pre-processing. In order to run the example, please follow the [CELLECT LDSC Tutorial](https://github.com/perslab/CELLECT/wiki/CELLECT-LDSC-Tutorial).


1. **Modify the `config-ldsc.yml` file**: specify the input GWAS summary stats and CELLEX cell-type expression specificity. These must be in the correct format - see tutorial for example.

2. **Run CELLECT-LDSC workflow**:

```bash
snakemake --use-conda -j -s cellect-ldsc.snakefile --configfile config-ldsc.yml
```
We recommend running with `-j` as it will use all available cores. Specifying `-j 4` will use up to 4 cores. 

3. **Inspect the output**:

```head CELLECT-LDSC-EXAMPLE/results/prioritization.csv```
gives you cell-type prioritization results:
```
gwas,specificity_id,annotation,beta,beta_se,pvalue
BMI_Yengo2018,tabula_muris-test,Brain_Non-Myeloid.Bergmann_glial_cell,9.231153572792368e-09,4.019151323331188e-09,0.010815326414746898
BMI_Yengo2018,tabula_muris-test,Bladder.bladder_cell,-5.004712418748802e-10,3.2673818983229307e-09,0.5608686595651585
BMI_Yengo2018,tabula_muris-test,Brain_Myeloid.microglial_cell,-2.6351066098370078e-09,3.5627583125482456e-09,0.7702363432351039
BMI_Yengo2018,tabula_muris-test,Brain_Myeloid.macrophage,-4.20188757005791e-09,5.126292004971455e-09,0.7937989730524113
BMI_Yengo2018,tabula_muris-test,Bladder.bladder_urothelial_cell,-9.444074983296222e-09,3.099358846619276e-09,0.9988447189868584
EA3_Lee2018,tabula_muris-test,Brain_Non-Myeloid.Bergmann_glial_cell,8.49739420095679e-09,1.911986590915025e-09,4.409437303659968e-06
EA3_Lee2018,tabula_muris-test,Brain_Myeloid.macrophage,2.214934890235212e-09,2.716854415111798e-09,0.20746257567581028
EA3_Lee2018,tabula_muris-test,Brain_Myeloid.microglial_cell,-6.441126119804287e-10,1.753163408008973e-09,0.6433397441548794
EA3_Lee2018,tabula_muris-test,Bladder.bladder_urothelial_cell,-4.589906843053639e-09,1.6159150917314255e-09,0.9977474194521412
EA3_Lee2018,tabula_muris-test,Bladder.bladder_cell,-4.421016110716137e-09,1.3525251453635627e-09,0.9994598102836466
```

## CELLECT-LDSC Example: 

See our [**github wiki**](https://github.com/perslab/CELLECT/wiki).

## Documentation

Please see our [**github wiki**](https://github.com/perslab/CELLECT/wiki) for additional documentation.

## Acknowledgements

We gratefully acknowledge the developers of the genetic prioritization tools used in  CELLECT: [LDSC](https://github.com/bulik/ldsc) and [MAGMA](http://ctglab.nl/software/magma). In particular, Christiaan de Leeuw and Steven Gazal for their generous support. 


## Authors

- Pascal Nordgren Timshel (University of Copenhagen)
- Tobi Alegbe (University of Copenhagen)
- Ben Nielsen (University of Copenhagen)

## Contact

Please create an issue on the github repo if you encounter any problems using CELLECT. 
Alternatively, you may write an email to timshel(at)sund.ku.dk

## Reference
If you find CELLECT useful for your research, please consider citing the paper:  
**[Timshel (bioRxiv, 2020): _Mapping heritability of obesity by cell types_](https://www.biorxiv.org/content/10.1101/2020.01.27.920033v1)**

