#!/bin/bash
#SBATCH --job-name=gedi_benchmark
#SBATCH --cpus-per-task=48
#SBATCH --mem=80G         
#SBATCH --time=06:00:00   
#SBATCH --output=/home/arsham79/projects/rrg-hsn/arsham79/gedi-pm-package/Benchmark/logs/benchmark_%A_%a.log
#SBATCH --account=def-hsn
#SBATCH --array=0-13

module load r/4.4.0
module load python

SCRIPT="panel-C-and-E/3.run_benchmark.R"

 Args=(
       "1-1-50000"
       "2-1-50000"
       "2-2-50000"
       "2-4-50000"
       "2-8-50000"
       "2-16-50000"
       "2-32-50000"
       "1-1-100000"
       "2-1-100000"
       "2-2-100000"
       "2-4-100000"
       "2-8-100000"
       "2-16-100000"
       "2-32-100000"
       
 )

Arg=${Args[$SLURM_ARRAY_TASK_ID]}

# Parse the argument
METHOD=$(echo $Arg | awk -F'-' '{print $1}')
THREADS=$(echo $Arg | awk -F'-' '{print $2}')
NUMBER_OF_CELLS=$(echo $Arg | awk -F'-' '{print $3}')
SAVENAME=${METHOD}-${THREADS}-${NUMBER_OF_CELLS}

# Create temporary wrapper script
WRAPPER_SCRIPT="/tmp/run_gedi_${SLURM_ARRAY_TASK_ID}.sh"
cat > ${WRAPPER_SCRIPT} << EOF
#!/bin/bash
Rscript ${SCRIPT} ${METHOD} ${THREADS} ${NUMBER_OF_CELLS}
EOF
chmod +x ${WRAPPER_SCRIPT}

# --include-children
# Run the wrapper script
psrecord --log ${SAVENAME}.txt --interval 1 --include-children  -- ${WRAPPER_SCRIPT}

# Clean up
rm ${WRAPPER_SCRIPT}



