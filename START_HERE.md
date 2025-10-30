# 🚀 START HERE: BOLT-LMM MRI Analysis

**Quick start guide for running the complete BOLT-LMM analysis pipeline**

---

## What This Analysis Does

- **4 MRI phenotypes**: FA, MD, MO, OD (diffusion MRI metrics)
- **3 population stratifications**: EUR_MM, EUR_Male, EUR_Female
- **1 covariate model**: Day_NoPCs (age, sex, array)
- **Total**: 12 GWAS analyses

---

## Prerequisites ✅

Before starting, verify these files exist on the HPC:

```bash
# Navigate to analysis directory
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/BOLT-LMM_SI-MRI

# Check prerequisites
ls -lh ../geno/ukb_genoHM3/ukb_genoHM3_bed.bed           # Genotypes (should exist)
ls -lh ../geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt    # Model SNPs (should exist)
ls -lh ../pheno/MRIrun2.tsv.gz          # Phenotypes (should exist)
ls -lh ../sqc/sqc.20220316.tsv.gz                        # Covariates (should exist)
ls -lh ../sqc/population.20220316/EUR_MM.keep           # Keep files (should exist)
```

If any files are missing, they need to be created first (see main README.md).

---

## Complete Workflow (3 Steps)

### Step 1: Filter to Populations

**Purpose**: Create population-specific phenotype and covariate files

**Command** (⭐ recommended - more robust):
```bash
# Python script (filters all 3 populations at once)
python3 filter_populations.py
```

**Alternative** (bash scripts - run each separately):
```bash
bash filter_to_EUR_MM.sh
bash filter_to_EUR_Male.sh
bash filter_to_EUR_Female.sh
```

**What it does**:
- Filters phenotypes and covariates for EUR_MM, EUR_Male, EUR_Female
- Creates 6 files total: 3 phenotype files + 3 covariate files
- Takes ~5-15 minutes total
- Ensures FID/IID headers for BOLT compatibility
- **Note**: Run directly (not sbatch) - matches working repo

**Expected output**:
```
MRIrun2.EUR_MM.tsv.gz      (~XX MB)
MRIrun2.EUR_Male.tsv.gz    (~XX MB)
MRIrun2.EUR_Female.tsv.gz  (~XX MB)
sqc.EUR_MM.tsv.gz          (~XXX MB)
sqc.EUR_Male.tsv.gz        (~XXX MB)
sqc.EUR_Female.tsv.gz      (~XXX MB)
```

**Verify all files created**:
```bash
ls -lh *.EUR*.tsv.gz | wc -l
# Should show: 6
```

---

### Step 2: Test Run

**Purpose**: Validate pipeline on one phenotype-population combo

**Command**:
```bash
sbatch 0b_test_run.sbatch.sh
```

**What it does**:
- Runs BOLT-LMM for FA phenotype with EUR_MM population
- Analyzes full genome (~1.3M variants)
- Verifies all files and configurations are correct
- Takes ~1-2 hours

**Expected output**:
```
results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.stats.gz  (~1-5GB)
results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.log.gz    (~100KB)
```

**Monitor**:
```bash
tail -f 0b_test.out
# Look for: "🎉 TEST PASSED!"
```

**⚠️ CRITICAL**: Do NOT proceed to Step 3 if test fails!

**Troubleshooting test failures**:
```bash
# Check error log
cat 0b_test.err

# Check BOLT-LMM log if it exists
zcat results/Day_NoPCs/EUR_MM/bolt_FA.Day_NoPCs.log.gz | less

# Common issues:
# - Filtered files not created (run Step 1)
# - Model SNPs file missing (check prerequisites)
# - Memory issues (increase --mem in sbatch header)
```

---

### Step 3: Full Analysis

**Purpose**: Run all 12 phenotype-population combinations

**Command**:
```bash
sbatch 1_run_bolt_lmm.sbatch.sh
```

**What it does**:
- Submits 12 jobs (SLURM array tasks 1-12)
- Each job: one phenotype × one population
- All jobs run in parallel (if resources available)
- Takes ~2 hours total wall-clock time

**Job mapping**:
```
Task 1-3:   FA × [EUR_MM, EUR_Male, EUR_Female]
Task 4-6:   MD × [EUR_MM, EUR_Male, EUR_Female]
Task 7-9:   MO × [EUR_MM, EUR_Male, EUR_Female]
Task 10-12: OD × [EUR_MM, EUR_Male, EUR_Female]
```

**Monitor progress**:
```bash
# Check job status
squeue -u mabdel03

# Check specific job output (replace X with task number)
tail -f 1_X.out

# Check all outputs at once
tail -f 1_*.out

# Count completed jobs
ls -1 results/Day_NoPCs/*/bolt_*.stats.gz | wc -l
# Should eventually be: 12 (4 phenotypes × 3 populations)
```

**Expected output** (24 files total):
```
results/
└── Day_NoPCs/
    ├── EUR_MM/
    │   ├── bolt_FA.Day_NoPCs.stats.gz
    │   ├── bolt_FA.Day_NoPCs.log.gz
    │   ├── bolt_MD.Day_NoPCs.stats.gz
    │   ├── bolt_MD.Day_NoPCs.log.gz
    │   ├── bolt_MO.Day_NoPCs.stats.gz
    │   ├── bolt_MO.Day_NoPCs.log.gz
    │   ├── bolt_OD.Day_NoPCs.stats.gz
    │   └── bolt_OD.Day_NoPCs.log.gz
    ├── EUR_Male/
    │   └── [same 8 files]
    └── EUR_Female/
        └── [same 8 files]
```

---

## Quick Command Summary

```bash
# Navigate to directory
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/BOLT-LMM_SI-MRI

# Step 1: Filter populations (~5-15 min total)
python3 filter_populations.py   # ⭐ Recommended (more robust)

# Verify 6 files created
ls -lh *.EUR*.tsv.gz | wc -l  # Should show: 6

# Step 2: Test run (~1-2 hours)
sbatch 0b_test_run.sbatch.sh

# Step 3: Full analysis (~2 hours, only if test passes)
sbatch 1_run_bolt_lmm.sbatch.sh

# Monitor
squeue -u mabdel03
tail -f 1_*.out
```

---

## Verification After Completion

### Check all jobs completed successfully

```bash
# Should have 12 stats files
ls -1 results/Day_NoPCs/*/bolt_*.stats.gz | wc -l

# Check for any failed jobs
grep -l "FAILED" 1_*.out

# Check file sizes (should be 100MB-5GB each)
ls -lh results/Day_NoPCs/*/bolt_*.stats.gz
```

### Quick QC for each result

```bash
# For each phenotype-population combo
for pop in EUR_MM EUR_Male EUR_Female; do
    for pheno in FA MD MO OD; do
        echo "=== ${pheno} - ${pop} ==="
        
        # Sample size
        zcat results/Day_NoPCs/${pop}/bolt_${pheno}.Day_NoPCs.log.gz | \
            grep "Analyzing" | head -1
        
        # Heritability
        zcat results/Day_NoPCs/${pop}/bolt_${pheno}.Day_NoPCs.log.gz | \
            grep "h2:" | head -1
        
        # Number of variants
        n_var=$(zcat results/Day_NoPCs/${pop}/bolt_${pheno}.Day_NoPCs.stats.gz | \
            tail -n +2 | wc -l)
        echo "Variants: ${n_var}"
        
        # Genome-wide significant hits
        n_sig=$(zcat results/Day_NoPCs/${pop}/bolt_${pheno}.Day_NoPCs.stats.gz | \
            awk 'NR>1 && $NF < 5e-8' | wc -l)
        echo "GWS hits (p<5e-8): ${n_sig}"
        
        echo ""
    done
done
```

### Expected QC metrics

- **Sample sizes**: 
  - EUR_MM: ~426,000
  - EUR_Male: ~200,000
  - EUR_Female: ~226,000
- **Variants**: ~1.3 million (autosomal)
- **Heritability**: 10-40% for brain traits (varies by phenotype)
- **λ_GC**: 1.00-1.05 (well-calibrated)

---

## Troubleshooting

### Job fails immediately

**Check**:
```bash
cat 1_X.err  # Replace X with task number
```

**Common causes**:
1. Filtered files missing → Run Step 1 again
2. Model SNPs missing → Check prerequisites
3. Conda environment issues → Verify bolt_lmm env exists

### Job runs but produces no output

**Check**:
```bash
# Look for BOLT-LMM errors
cat 1_X.out | grep -i "error"

# Check if output directory was created
ls -ld results/Day_NoPCs/EUR_MM/
```

### High memory usage / Out of memory

**Solution**: Increase memory in batch script
```bash
# Edit 1_run_bolt_lmm.sbatch.sh
# Change: #SBATCH --mem=150G
# To:     #SBATCH --mem=200G
```

### Test passes but full analysis fails

**Check**: Are filtered files for all 3 populations created?
```bash
ls -lh MRIrun2.*.tsv.gz sqc.*.tsv.gz
# Should see 6 files total
```

---

## What to Do After Analysis Completes

1. **Quality Control**: Check λ_GC, heritability, sample sizes (see verification above)

2. **Visualization**: Create Manhattan and QQ plots for each phenotype

3. **Sex-specific effects**: Compare male vs female results to identify sex-specific loci

4. **Heritability estimation**: Run LD Score Regression

5. **Comparison**: Compare to published brain imaging GWAS (ENIGMA consortium)

6. **Meta-analysis**: Combine male and female results if appropriate

See main README.md for detailed downstream analysis instructions.

---

## File Descriptions

| File | Purpose | When to Run |
|------|---------|-------------|
| `0a_filter_populations.sbatch.sh` | Filter to 3 populations | First (one-time) |
| `0b_test_run.sbatch.sh` | Validate pipeline | Second (after filtering) |
| `1_run_bolt_lmm.sbatch.sh` | Run all 12 analyses | Third (after test passes) |
| `run_single_phenotype.sh` | Core BOLT-LMM logic | Called by other scripts |
| `filter_to_population.sh` | Population filtering | Called by 0a script |
| `paths.sh` | Configuration | Sourced automatically |

---

## Timeline

| Step | Time | Wait? |
|------|------|-------|
| 0a: Filter populations | 5-10 min | Yes - must complete before test |
| 0b: Test run | 1-2 hours | Yes - must pass before full run |
| 1: Full analysis | 2 hours | No - can check later |
| **Total** | **~3-4 hours** | |

---

## Support

- **Full documentation**: See `README.md`
- **BOLT-LMM manual**: https://alkesgroup.broadinstitute.org/BOLT-LMM/
- **Issues**: Check SLURM logs (`*.out` and `*.err` files)

---

**Ready to start?** Run Step 1: `sbatch 0a_filter_populations.sbatch.sh`

*Last Updated: October 30, 2025*

