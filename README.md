# BOLT-LMM GWAS Analysis: MRI Phenotypes

**BOLT-LMM analysis for 4 MRI-related phenotypes across 3 population stratifications**

---

## Overview

This analysis performs genome-wide association studies (GWAS) for brain MRI phenotypes using BOLT-LMM v2.5 with mixed linear models. The analysis is stratified by sex to detect sex-specific genetic effects.

### Phenotypes (4 total)

| Phenotype | Description |
|-----------|-------------|
| **FA** | Fractional Anisotropy - measure of white matter tract integrity |
| **MD** | Mean Diffusivity - measure of water diffusion in brain tissue |
| **MO** | Mode of Anisotropy - measure of anisotropy shape |
| **OD** | Orientation Dispersion - measure of fiber orientation complexity |

### Population Stratifications (3 total)

| Population | Description | Expected N |
|------------|-------------|------------|
| **EUR_MM** | European ancestry (includes related individuals) | ~426,000 |
| **EUR_Male** | European ancestry males only | ~200,000 |
| **EUR_Female** | European ancestry females only | ~226,000 |

### Covariate Model

**Day_NoPCs** (Primary model without principal components):
- Age (quantitative)
- Sex (categorical) - except in sex-stratified analyses
- Genotyping array (categorical)
- Population structure controlled via genetic relationship matrix (GRM)

**Note**: No principal components are included because:
1. GRM captures population structure
2. Reduces degrees of freedom for better power
3. Consistent with Day et al. (2018) primary analysis model

---

## Analysis Configuration

### Total Jobs

```
4 phenotypes × 3 populations × 1 covariate set = 12 jobs
```

### Job Mapping (SLURM array tasks 1-12)

| Task | Phenotype | Population |
|------|-----------|------------|
| 1-3 | FA | EUR_MM, EUR_Male, EUR_Female |
| 4-6 | MD | EUR_MM, EUR_Male, EUR_Female |
| 7-9 | MO | EUR_MM, EUR_Male, EUR_Female |
| 10-12 | OD | EUR_MM, EUR_Male, EUR_Female |

---

## Quick Start

### Prerequisites

On the HPC, ensure:
- [x] Genotype files converted to BED format (`ukb_genoHM3_bed.*`)
- [x] Model SNPs prepared (`ukb_genoHM3_modelSNPs.txt`)
- [x] Population keep files exist in `sqc/population.20220316/`
- [x] Phenotype file: `pheno/loneliness_NoMR/MRIrun2.tsv.gz`
- [x] Covariate file: `sqc/sqc.20220316.tsv.gz`

### Step 1: Filter to Populations

```bash
# On HPC, in this directory
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/BOLT-LMM_SI-MRI

# Submit batch job to filter phenotype and covariate files for all 3 populations
sbatch 0a_filter_populations.sbatch.sh

# Monitor
tail -f 0a_filter.out

# This creates:
# - MRIrun2.EUR_MM.tsv.gz
# - MRIrun2.EUR_Male.tsv.gz
# - MRIrun2.EUR_Female.tsv.gz
# - sqc.EUR_MM.tsv.gz
# - sqc.EUR_Male.tsv.gz
# - sqc.EUR_Female.tsv.gz
```

### Step 2: Test Run

```bash
# Test with one phenotype and population
sbatch 0b_test_run.sbatch.sh

# Monitor
tail -f 0b_test.out

# Check for "TEST PASSED" message
# Review output: results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.stats.gz
```

### Step 3: Full Analysis

```bash
# If test passes, submit all 12 jobs
sbatch 1_run_bolt_lmm.sbatch.sh

# Monitor progress
squeue -u mabdel03

# Check individual job outputs
tail -f 1_*.out
```

---

## Output Structure

```
BOLT-LMM_SI-MRI/
├── results/
│   └── Day_NoPCs/
│       ├── EUR_MM/
│       │   ├── bolt_FA.Day_NoPCs.stats.gz
│       │   ├── bolt_FA.Day_NoPCs.log.gz
│       │   ├── bolt_MD.Day_NoPCs.stats.gz
│       │   ├── bolt_MD.Day_NoPCs.log.gz
│       │   ├── bolt_MO.Day_NoPCs.stats.gz
│       │   ├── bolt_MO.Day_NoPCs.log.gz
│       │   ├── bolt_OD.Day_NoPCs.stats.gz
│       │   └── bolt_OD.Day_NoPCs.log.gz
│       ├── EUR_Male/
│       │   └── [same 8 files]
│       └── EUR_Female/
│           └── [same 8 files]
├── MRIrun2.EUR_MM.tsv.gz
├── MRIrun2.EUR_Male.tsv.gz
├── MRIrun2.EUR_Female.tsv.gz
├── sqc.EUR_MM.tsv.gz
├── sqc.EUR_Male.tsv.gz
└── sqc.EUR_Female.tsv.gz
```

---

## Expected Runtime

Per job (150GB RAM, 100 CPUs):
- Sample size: ~200K-426K individuals
- Variants: ~1.3M autosomal (HapMap3)
- Expected time: **1-2 hours per job**

Total wall-clock time (if run concurrently): **~2 hours**

---

## Quality Control

### From Log Files

For each phenotype-population combination, check:

```bash
# Sample size
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.log.gz | grep "Analyzing"

# Heritability estimate
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.log.gz | grep "h2:"

# Genomic inflation
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.log.gz | grep -i "lambda\|inflation"

# Warnings
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.log.gz | grep -i "warning"
```

**Expected QC metrics:**
- λ_GC: 1.00-1.05 (well-calibrated)
- h²: > 0 and reasonable for brain traits (typically 10-40%)
- Sample size: matches expected for population

### From Summary Statistics

```bash
# Count variants
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.stats.gz | wc -l
# Expected: ~1.3M

# Check for genome-wide significant hits (p < 5×10⁻⁸)
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.stats.gz | \
    awk 'NR>1 && $NF < 5e-8' | wc -l

# Preview top associations
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.stats.gz | \
    awk 'NR>1' | sort -k12,12g | head -20
```

---

## Sex-Stratified Analysis Interpretation

### Comparing Results Across Populations

**1. Identify sex-specific associations:**

```bash
# Find variants significant in males but not females (or vice versa)
# This requires formal heterogeneity testing (not shown here)
```

**2. Compare effect sizes:**

Look for variants where:
- Effect size (BETA) differs substantially between males and females
- Statistical significance differs (e.g., p<5×10⁻⁸ in one sex only)

**3. Known sex differences in brain structure:**

- Males: Larger total brain volume, more white matter
- Females: Higher white matter integrity (FA), faster maturation
- Expect some sex-specific genetic effects

### Biological Interpretation

**FA (Fractional Anisotropy):**
- Higher FA = More organized, parallel fiber structure
- Lower FA = More crossing fibers or tissue damage
- Relevant to: Cognitive function, aging, neurological disorders

**MD (Mean Diffusivity):**
- Higher MD = Greater water diffusion (less restricted)
- Lower MD = More restricted diffusion
- Relevant to: Brain maturation, edema, neurodegeneration

**MO (Mode of Anisotropy):**
- Describes shape of diffusion tensor
- Range: -1 (planar) to +1 (linear)
- Relevant to: Fiber crossing complexity

**OD (Orientation Dispersion):**
- Higher OD = More complex fiber orientations
- Lower OD = More parallel fibers
- Relevant to: Cortical microstructure, connectivity

---

## Downstream Analyses

### 1. LD Score Regression

Estimate heritability and genetic correlations:

```bash
# Heritability for each phenotype-population
for pop in EUR_MM EUR_Male EUR_Female; do
    for pheno in FA MD MO OD; do
        ldsc.py \
            --h2 results/Day_NoPCs/${pop}/bolt_${pheno}.Day_NoPCs.stats.gz \
            --ref-ld-chr eur_w_ld_chr/ \
            --w-ld-chr eur_w_ld_chr/ \
            --out ${pheno}_${pop}.h2
    done
done

# Genetic correlation between males and females
ldsc.py \
    --rg results/Day_NoPCs/EUR_Male/bolt_FA.Day_NoPCs.stats.gz,results/Day_NoPCs/EUR_Female/bolt_FA.Day_NoPCs.stats.gz \
    --ref-ld-chr eur_w_ld_chr/ \
    --w-ld-chr eur_w_ld_chr/ \
    --out FA_Male_vs_Female.rg
```

### 2. Meta-Analysis

Combine male and female results:

```bash
# Using METAL or similar tools
# Weight by sample size or inverse variance
```

### 3. Functional Annotation

```bash
# Use FUMA GWAS or similar tools
# Annotate significant loci with:
# - Gene mapping
# - eQTL overlap
# - Brain-specific enrichment
# - Pathway analysis
```

### 4. Comparison to Published GWAS

Compare results to:
- ENIGMA consortium brain imaging GWAS
- UK Biobank brain imaging studies
- Other diffusion MRI GWAS

---

## Troubleshooting

### Common Issues

**Issue: Population-filtered files not found**
```bash
# Solution: Run filter_to_population.sh for all three populations
bash filter_to_population.sh EUR_MM
bash filter_to_population.sh EUR_Male
bash filter_to_population.sh EUR_Female
```

**Issue: High λ_GC (>1.10)**
```bash
# Check: Is population filtering correct?
# Check: Are there batch effects in phenotypes?
# Consider: Adding more PCs (create Day_10PCs covariate set)
```

**Issue: Low sample size in sex-stratified analysis**
```bash
# Check: Are phenotype values mostly missing?
zcat MRIrun2.EUR_Male.tsv.gz | awk -F'\t' '{print $3}' | grep -v "NA" | wc -l

# Verify: Phenotype coverage
zcat results/Day_NoPCs/EUR_Male/bolt_FA.Day_NoPCs.log.gz | grep "Analyzing"
```

---

## File Descriptions

| File | Purpose |
|------|---------|
| `run_single_phenotype.sh` | Core BOLT-LMM execution for one phenotype-population combo |
| `1_run_bolt_lmm.sbatch.sh` | SLURM array job (12 tasks) |
| `0_test_run.sbatch.sh` | Test script for validation |
| `filter_to_population.sh` | Create population-specific phenotype/covariate files |
| `paths.sh` | Configuration for file paths and BOLT-LMM settings |

---

## Resources

- **BOLT-LMM Manual**: https://alkesgroup.broadinstitute.org/BOLT-LMM/
- **Day et al. (2018)**: Nature Communications (methodology reference)
- **ENIGMA Consortium**: http://enigma.ini.usc.edu/
- **UK Biobank**: https://biobank.ndph.ox.ac.uk/

---

## Citation

If you use this analysis pipeline, please cite:

1. **BOLT-LMM**:
   - Loh, P.-R., et al. (2015). Nature Genetics, 47(3), 284-290.
   - Loh, P.-R., et al. (2018). Nature Genetics, 50(7), 906-908.

2. **UK Biobank**:
   - Bycroft, C., et al. (2018). Nature, 562(7726), 203-209.

3. **Methodology (if applicable)**:
   - Day, F. R., et al. (2018). Nature Communications, 9(1), 2457.

---

*Analysis Directory: `/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/BOLT-LMM_SI-MRI`*

*Last Updated: October 30, 2025*
