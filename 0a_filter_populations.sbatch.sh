#!/bin/bash
#SBATCH --job-name=filter_mri_pops
#SBATCH --partition=kellis
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH --time=0:30:00
#SBATCH --output=0a_filter.out
#SBATCH --error=0a_filter.err
#SBATCH --mail-user=mabdel03@mit.edu
#SBATCH --mail-type=BEGIN,END,FAIL

set -beEo pipefail

# Filter phenotype and covariate files for all three populations
# This must be run before BOLT-LMM analysis

echo "========================================"
echo "Filter Phenotype & Covariate Files"
echo "All 3 Populations"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "========================================"
echo ""

SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/BOLT-LMM_SI-MRI"
cd ${SRCDIR}

# Filter for each population
for keep_set in EUR_MM EUR_Male EUR_Female; do
    echo "========================================"
    echo "Filtering for: ${keep_set}"
    echo "========================================"
    bash filter_to_population.sh ${keep_set}
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Filtering failed for ${keep_set}" >&2
        exit 1
    fi
    echo ""
done

echo "========================================"
echo "✅ ALL POPULATION FILTERING COMPLETED"
echo "========================================"
echo ""
echo "Files created:"
ls -lh ${SRCDIR}/MRIrun2.*.tsv.gz
ls -lh ${SRCDIR}/sqc.*.tsv.gz
echo ""
echo "Next steps:"
echo "1. Test: sbatch 0b_test_run.sbatch.sh"
echo "2. If test passes: sbatch 1_run_bolt_lmm.sbatch.sh"
echo ""
echo "End time: $(date)"

