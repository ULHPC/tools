# Time-stamp: <Wed 2020-06-10 14:13 svarrette>
################################################################################
# Adaptation of the PS1 bash prompt to display information in teh
# current job running.

if [[ -n $SLURM_JOB_ID ]]; then
    job_info="(${SLURM_JOB_ID} ${SLURM_JOB_NUM_NODES}N/${SLURM_NTASKS}T/${SLURM_JOB_CPUS_PER_NODE}CN)"
fi
if [ -n "$PS1" ]; then
    export PS1='$? [\u@\h \W]${job_info}$ '
fi
