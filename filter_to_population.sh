#!/bin/bash
set -beEo pipefail

# Filter phenotype and covariate files to specific population
# This is simpler than using --remove in BOLT-LMM

if [ $# -ne 1 ]; then
    echo "Usage: $0 <keep_set>" >&2
    echo "Example: $0 EUR_MM" >&2
    echo "Example: $0 EUR_Male" >&2
    echo "Example: $0 EUR_Female" >&2
    exit 1
fi

keep_set=$1

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/BOLT-LMM_SI-MRI"

echo "========================================"
echo "Filter Phenotype & Covariate Files"
echo "Population: ${keep_set}"
echo "========================================"
echo ""

# Input files
keep_file="${ukb21942_d}/sqc/population.20220316/${keep_set}.keep"
pheno_file="${ukb21942_d}/pheno/loneliness_NoMR/MRIrun2.tsv.gz"
covar_file="${ukb21942_d}/sqc/sqc.20220316.tsv.gz"

# Output files (in analysis directory for easy access)
pheno_pop="${SRCDIR}/MRIrun2.${keep_set}.tsv.gz"
covar_pop="${SRCDIR}/sqc.${keep_set}.tsv.gz"

echo "Input files:"
echo "  Population keep file: ${keep_file}"
echo "  Phenotypes: ${pheno_file}"
echo "  Covariates: ${covar_file}"
echo ""
echo "Output files:"
echo "  Filtered phenotypes: ${pheno_pop}"
echo "  Filtered covariates: ${covar_pop}"
echo ""

# Check if keep file exists
if [ ! -f "${keep_file}" ]; then
    echo "ERROR: Keep file not found: ${keep_file}" >&2
    exit 1
fi

# Count samples in keep file
n_keep=$(wc -l < "${keep_file}")
echo "${keep_set} samples to keep: ${n_keep}"
echo ""

# Create temporary ID lookup file (just IIDs from keep file)
awk '{print $2}' "${keep_file}" > /tmp/${keep_set}_iids.txt
n_ids=$(wc -l < /tmp/${keep_set}_iids.txt)
echo "  IDs to match: ${n_ids}"

# Filter phenotype file
echo "Filtering phenotype file..."
{
    # Extract and write header
    zcat "${pheno_file}" | head -1
    
    # Extract data rows and filter using grep
    zcat "${pheno_file}" | tail -n +2 | grep -F -f /tmp/${keep_set}_iids.txt
    
} | gzip > "${pheno_pop}"

n_pheno_out=$(zcat "${pheno_pop}" | tail -n +2 | wc -l)
echo "✓ Filtered phenotype file created"
echo "  Input samples: $(zcat "${pheno_file}" | tail -n +2 | wc -l)"
echo "  Output samples: ${n_pheno_out}"
echo ""

# Filter covariate file
echo "Filtering covariate file..."
{
    # Header
    zcat "${covar_file}" | head -1
    
    # Data rows filtered to population
    zcat "${covar_file}" | tail -n +2 | grep -F -f /tmp/${keep_set}_iids.txt
    
} | gzip > "${covar_pop}"

n_covar_out=$(zcat "${covar_pop}" | tail -n +2 | wc -l)
echo "✓ Filtered covariate file created"
echo "  Input samples: $(zcat "${covar_file}" | tail -n +2 | wc -l)"
echo "  Output samples: ${n_covar_out}"
echo ""

# Clean up
rm -f /tmp/${keep_set}_iids.txt

echo ""
echo "========================================"
echo "Filtering Complete for ${keep_set}!"
echo "========================================"
echo ""
echo "Summary:"
echo "  ${keep_set} samples requested: ${n_keep}"
echo "  Phenotype file output: ${n_pheno_out}"
echo "  Covariate file output: ${n_covar_out}"
echo ""

if [ ${n_pheno_out} -ne ${n_keep} ]; then
    echo "⚠️  WARNING: Phenotype sample count doesn't match keep file count"
    echo "   This is normal if some samples have missing phenotype data"
fi

if [ ${n_covar_out} -ne ${n_keep} ]; then
    echo "⚠️  WARNING: Covariate sample count doesn't match keep file count"
    echo "   This is normal if some samples have missing covariate data"
fi

echo ""
echo "Next steps:"
echo "1. Repeat for other populations:"
echo "   bash filter_to_population.sh EUR_Male"
echo "   bash filter_to_population.sh EUR_Female"
echo "2. Run test: sbatch 0b_test_run.sbatch.sh"
echo "3. If test passes: sbatch 1_run_bolt_lmm.sbatch.sh"

