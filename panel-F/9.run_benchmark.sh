#!/bin/bash
#SBATCH --job-name=gedi_benchmark
#SBATCH --cpus-per-task=48
#SBATCH --mem=200G         
#SBATCH --time=12:00:00   
#SBATCH --output=/home/arsham79/projects/rrg-hsn/arsham79/gedi-pm-package/Benchmark/logs/benchmark_%A_%a.log
#SBATCH --account=def-hsn
#SBATCH --array=0-6

module load r/4.4.0
module load python

SCRIPT="panel-F/9.run_benchmark.R"

 Args=(
       "1-1-1000000"
       "2-1-1000000"
       "2-2-1000000"
       "2-4-1000000"
       "2-8-1000000"
       "2-16-1000000"
       "2-32-1000000"
       
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
# psrecord --plot ${SAVENAME}.png --log ${SAVENAME}.txt --interval 1 --include-children  -- ${WRAPPER_SCRIPT}
psrecord --log ${SAVENAME}.txt --interval 1 --include-children  -- ${WRAPPER_SCRIPT}

# Clean up
rm ${WRAPPER_SCRIPT}



