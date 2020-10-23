# Time-stamp: <Wed 2020-06-10 15:00 svarrette>
################################################################################
# [/etc/]profile.d/slurm.sh - Various Slurm helper functions and aliases to
# .                           use on the UL HPC Platform (https://hpc.uni.lu)
#
# Copyright (c) 2020 UL HPC Team <hpc-team@uni.lu>
#
# Usage:       source path/to/slurm.sh
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
# Default formats
export SQUEUE_FORMAT="%.10i %.9P %.10q %.8j %.20u %.4D %.5C %.2t %.12M %.12L %.8Q %R"

### Most useful format field for squeue (see man squeue)
#   --format      --Format
# | Short (-o) | Long (-O)    | Description                                        |
# |------------|--------------|----------------------------------------------------|
# | %i         | JobID        | Job ID                                             |
# | %j         | Name         | Job or job step name.                              |
# | %R         | ReasonList   | For pending jobs: the reason a job is waiting      |
# | %t         | StateCompact | Job state in compact form.                         |
# | %P         | Partition    | Partition                                          |
# | %q         | QOS          | Quality of service associated with the job.        |
# | %u         | UserID       | User name for a job or job step.                   |
# | %D         | NumNodes     | Number of nodes allocated to the job               |
# | %C         | NumCPUs      | Number of CPUs (cores)                             |
# | %A         | NumTasks     | Number of tasks                                    |
# |            | NTPerNode    | The number of task per node                        |
# | %l         | TimeLimit    | Time limit of the job: days-hours:minutes:seconds  |
# | %M         | TimeUsed     | Time used by the job:  days-hours:minutes:seconds  |
# | %L         | TimeLeft     | Time left for the job: days-hours:minutes:seconds. |


## SLURM helpers

## scontrol helpers
alias ssj='scontrol show job'


## [srun] job helpers
sjoin(){
    if [[ -z $1 ]]; then
        echo "Job ID not given."
        echo "Usage: sjoin <jobid> [iris-XXX]"
    else
        JOBID=$1
        [[ -n $2 ]] && NODE="-w $2"
        srun --jobid $JOBID $NODE --pty bash -i
    fi
}
# Stats on past job
slist(){
    if [[ -z $1 ]]; then
        echo "Job ID not given."
        echo "Usage: slist <jobid> [-X] [...]"
    else
        JOBID=$1
        shift
        cmd="sacct -j $JOBID --format User,JobID,Jobname%30,partition,state,time,elapsed,MaxRss,MaxVMSize,nnodes,ncpus,nodelist,AveCPU,ConsumedEnergyRaw $*"
        echo "# ${cmd}"
        ${cmd}
        echo "#"
        echo "# seff $JOBID"
        echo "#"
        seff $JOBID
    fi
}
alias sjobstats=slist

function si {
    local options="$*"
    cmd="srun -p interactive --qos debug -C batch $options --pty bash"
    echo "# ${cmd}"
    $cmd
}
function si-gpu {
    local options="$*"
    if [[ $options != *"-G"* ]]; then 
        echo '# /!\ WARNING: append -G 1 to really reserve a GPU'
        options="${options} -G 1"
    fi 
    cmd="srun -p interactive --qos debug -C gpu $options --pty bash"
    echo "# ${cmd}"
    $cmd
}
function si-bigmem {
    local options="$*"
    cmd="srun -p interactive --qos debug -C bigmem $options --pty bash"
    echo "# ${cmd}"
    $cmd
}

## squeue helpers
function sq() {
    local user=${1:-$(whoami)}
    cmd="squeue -u ${user}"
    echo "# ${cmd}"
    $cmd
}
largejobs(){
    echo -ne "=> List running jobs using more than 28 cores (slurm CPUs)\n"
    date +%F-%T
    squeue -h -o '%i,%C' -t R | awk -F , '{if ($2>28) {print $1}}' | paste -sd ',' | xargs squeue -j
}
longjobs(){
    echo -ne "=> List jobs running/expected to run for more than 5 days\n"
    date +%F-%T
    squeue -h -o '%i,%l' | cut -d '-' -f 1 | grep -v ':' | awk -F , '{if ($2>5) {print $1}}' | paste -sd ',' | xargs squeue -o "$SQUEUE_FORMAT,%L" -j
}
userjobs(){
    local user=${1:-$(whoami)}
    if [ $user == "-h" ]; then
        echo "Usage: userjobs <login> (Default: $(whoami))"
        echo " => detail job details for user '${user}'"
        return
    fi
    local squeue_cmd="squeue -u $user -O JOBID -h"
    local check_empty_squeue="$(eval $squeue_cmd)"
    if [ -z "$check_empty_squeue" ]; then
        echo "No job scheduled for user '${user}'"
        return
    fi
    cmd="$squeue_cmd | xargs -n1 scontrol show job"
    echo "# ${cmd}"
    eval $cmd
}

## sinfo helpers
alias nodelist='sinfo -e -o "%15N %5D %6X %5Y %8Z %5c %8m  %20f %20G"'
alias allocnodes='sinfo -h -t mix,alloc -o %N'
alias idlenodes='sinfo -h -t idle -o %N'
alias deadnodes='sinfo -d'
alias sissues='sinfo -R -o "%45E %19H %6t %N"'

## Utilization Report
gpuload() {
    #gpumax=$(sinfo -h -N -p gpu -o %G | cut -d : -f3 | paste -sd + | bc)
    gpumax=96
    gpuused=$(squeue -h -t R -p gpu -o "%b*%D" | grep gpu | cut -d , -f 1 | cut -d : -f 2 | sed 's/gpu/1/g'  | paste -sd '+' |bc)
    [ -z "${gpuused}" ] && gpuused=0
    gpuusage=$(echo "$gpuused*100/$gpumax" | bc -l)
    printf "GPU: %s/%s (%2.1f%%)\n" "$gpuused" "$gpumax" "$gpuusage"
}

# Overview of the Slurm partition load
pload() {
    local no_header=""
    local partition=""
    while [ -n "$1" ]; do
        case $1 in
            -a | --all) partition="batch gpu bigmem";;
            -h | --no-header) no_header=$1;;
            i  | int*) partition="interactive";;
            b  | bat*) partition="batch";;
            g  | gpu*) partition="gpu";;
            m  | big*) partition="bigmem";;
            *) echo "Unknown partition '$1'"; return;;
        esac
        shift
    done
    if [[ -z "$partition" ]]; then
        echo "Usage: pload [-a] [--no-header] <partition>"
        echo " => Show current load of the slurm partition <partition>, eventually without header"
        echo "    <partition> shortcuts: i=interactive b=batch g=gpu m=bigmem"
        echo -e " Options:\n   -a: show all partition"
        return
    fi
    [ -z "$no_header" ] && \
        printf "%12s %8s %9s %9s %12s\n" "Partition" "CPU Max" "CPU Used" "CPU Free" "Usage[%]"
    for p in $partition; do
        if [ "$p" == "interactive" ]; then 
            cpumax="$(sacctmgr show qos where name=debug format=GrpTRES -n -P)"
            cpuused=$(squeue --qos debug --format %C -h | paste -sd+ | bc)
            cpufree='n/a'
            usageratio='n/a'
            printf "%12s %8s %9s %9s %10s%%\n" "($p)" "$cpumax" "$cpuused" "$cpufree" "$usageratio"
    
        else 
            # allocated/idle/other/total
            usage=$(sinfo -h -p $p --format=%C)
            cpumax=$(echo $usage | cut -d '/' -f 4)
            # include other (draining, down)
            cpuused=$(( $(echo $usage | cut -d '/' -f 1) + $(echo $usage | cut -d '/' -f 3) ))
            #cpuused=$(echo $usage | cut -d '/' -f 1)
            cpufree=$(echo $usage | cut -d '/' -f 2)
            usageratio=$(echo "$cpuused*100/$cpumax" | bc -l)
            [ "$p" == "gpu" ] && gpustats=$(gpuload) || gpustats=""
            #jobs=$(squeue -p $p -t R,PD -h -o "(%t)" | sort -r | uniq -c | xargs echo | sed 's/) /),/')
            printf "%12s %8s %9s %9s %10.1f%% %s\n" "$p" "$cpumax" "$cpuused" "$cpufree" "$usageratio" "$gpustats"
        fi 
    done
}
listpartitionjobs(){
    local partition=${1:-batch}
    if [[ -z $1 ]]; then
        echo "Usage: listpartitionjobs <partition>"
        echo " => list jobs (and current load) of the slurm partition <partition>"
        return
    fi
    echo -ne "=> current load on partition '$partition'\n"
    pload $partition
    echo -ne "\n=> Job(s) status\n"
    squeue -p $partition -h -o "%t,%r"  | sort -r | uniq -c
}
alias joblistinteractive='listpartitionjobs interactive'
alias joblistbatch='listpartitionjobs batch'
alias joblistgpu='listpartitionjobs gpu'
alias joblistbig='listpartitionjobs bigmem'

## Reports
qload() {
    local no_header=""
    local qos_list=""
    local show_all=""
    while [ -n "$1" ]; do
        case $1 in
            -a | --all) show_all=$1; qos_list="interactive qos-batch dedicated industry long gpu bigmem";;
            -h | --no-header) no_header=$1;;
            *) qos_list=$*; break;;
        esac
        shift
    done
    if [[ -z "$qos_list" ]]; then
        echo "Usage: qload [-a] [--no-header] <qos>"
        echo " => Show current load of the slurm QOS <qos>, eventually without header"
        echo "    <qos> shortcuts: i=interactive b=batch l=long g=gpu m=bigmem"
        echo -e " Options:\n   -a: show all qos"
        return
    fi
    partitionlimits=$(sinfo -h --format=%P,%C | grep -v admin)
    [ -z "$no_header" ] && \
        printf "%12s %16s %8s %9s %9s %12s %12s\n" "Partition" "QOS" "CPU Max" "CPU Used" "CPU Free" "Usage[%]" " "
    for pattern in $qos_list; do
        #echo "==> pattern '$pattern'"
        use_partition_stats=""
        case $pattern in
            qos-interactive | i | int*) partition="interactive"; qos="qos-${partition}"; q=$qos; use_partition_stats=$pattern;;
            qos-batch)                  partition="batch";       qos="qos-${partition}"; q=$qos;;
            qos-long        | l | lon*) partition="long";        qos="qos-${partition}"; q=$qos; use_partition_stats=$pattern;;
            qos-gpu         | g | gpu*) partition="gpu";         qos="qos-${partition}"; q=$qos; use_partition_stats=$pattern;;
            qos-bigmem      | m | big*) partition="bigmem";      qos="qos-${partition}"; q=$qos; use_partition_stats=$pattern;;
            qos-batch-001)              partition="batch";       qos="${pattern}";       q=$qos;;
            qos-batch-00*)              partition="batch";       qos="(industry)";       q=$pattern;;
            d | ded*)                   partition="batch";       qos="(dedicated)";      q="qos-batch-001,qos-covid";;
            ind*)                       partition="batch";       qos="(industry)";       q="qos-batch-002,qos-batch-003";;
            b | bat*)                   partition="batch";       qos="qos-batch-*";      q="qos-batch,qos-batch-001,qos-covid,qos-batch-002,qos-batch-003"; use_partition_stats=$pattern;;
            qos-covid | cov*)           partition="batch";       qos="qos-covid";        q=$qos;;
            *) echo "Unknown pattern '$pattern'"; return;;
        esac
        qoscpumax=$(sacctmgr -n -P list qos format=grptres where name="$q" | sed '/|$/d;s/cpu=//g' | paste -sd '+' | bc)
        [ -z "$qoscpumax" ]  && qoscpumax=$(echo  "$partitionlimits" | grep $partition | awk -F '/' '{ print $4 }')
        if [ -n "${use_partition_stats}" ]; then # aggregate partition stats
            qoscpualloc=$(echo "$partitionlimits" | grep $partition | cut -d ',' -f 2 | awk -F '/' '{ print $1 }')
            qoscpuother=$(echo "$partitionlimits" | grep $partition | awk -F '/' '{ print $3 }')
        else
            qoscpualloc=$(squeue -h --qos "$q" -t R -o %C | paste -sd '+' | bc)
            [ -z "$qoscpualloc" ] && qoscpualloc=0
            qoscpuother=0
            [ "$qos" == 'qos-batch' ] && qoscpuother=$(echo "$partitionlimits" | grep $partition | awk -F '/' '{ print $3 }')
        fi
        [ "$qoscpuother" -gt "0" ] && comment="(*) $qoscpuother CPU unavailable" || comment=""
        qoscpuused=$(echo "$qoscpualloc+$qoscpuother" | bc)
        qoscpufree=$(echo "$qoscpumax-$qoscpuused"    | bc)
        [ "${qoscpumax}" == "0" ] && qosusage=0 || qosusage=$(echo "$qoscpuused*100/$qoscpumax" | bc -l)
        [ "$partition" == "gpu" ] && gpustats=$(gpuload) || gpustats="" # "$(echo "$partitionlimits" | grep $partition) (A/I/O/T) $qoscpualloc+$qoscpuother"
        printf "%12s %16s %8s %9s %9s %10.1f%% %12s\n" "$partition" "$qos" "$qoscpumax" "$qoscpuused" "$qoscpufree" "$qosusage" "$gpustats $comment"
    done
    printf "%29s -------- --------- --------- -----------\n" " "
    if [ -n "$show_all" ]; then
        #total=$(sinfo -h --format=%C)
        totalmax=$(echo  "$partitionlimits" | awk -F '/' '{ print $4 }' | paste -sd '+' | bc)
        totalused=$(echo "$partitionlimits" | cut -d ',' -f 2 | awk -F '/' '{ print $1+$3 }' | paste -sd '+' | bc)
        totalfree=$(echo  "$totalmax-$totalused" | bc)
        totalusage=$(echo "$totalused*100/$totalmax" | bc -l)
        printf "%29s %8s %9s %9s %9.1f%%\n" "TOTAL:" "$totalmax" "$totalused" "$totalfree" "$totalusage"
    fi
}
alias irisqosusage='qload -a'
alias qosusageinteractive='qload i'
alias qosusagebatch='qload b'
alias qosusagelong='qload l'
alias qosusagebigmem='qload m'
alias qosusagegpu='qload g'

irisstat(){
    sinfo -h --format=%C | awk -F '/' '{printf "Utilization: %.2f%%\n", $1/$4*100}'
    qload -a
    echo "Drained nodes: $(sinfo -h -t drain -o '%D')"
    printf "%0.s-" {1..50} ; printf "\n"
    printf "Jobs status: \n"
    squeue -h -o "%t,%r" | sort | uniq -c | sort -r
}


## sacctmgr helpers
acct(){
    if [[ -z $1 ]]; then
        echo "Usage: acct <login|account>"
        echo " => get user/account holder"
        return
    fi
    cmd1="sacctmgr show user where name=\"${1}\" format=user,account%20,DefaultAccount,qos%95 withassoc" # if user (parent is account holder)
    cmd2="sacctmgr show account where name=\"${1}\" format=Org,qos%95"         # if account holder (parent is organization/department)
    echo "# ${cmd1}"
    $cmd1
    echo "# ${cmd2}"
    $cmd2
}
sassoc() {
    local user=${1:-$(whoami)}
    cmd="sacctmgr show association where users=$user format=cluster,account%20,user,share,qos%90,maxjobs,maxsubmit,maxtres,"
    echo "# ${cmd}"
    $cmd
}
sqos() {
    if [[ -n "$1" ]]; then
        local filter="where name=$1"
    fi 
    cmd="sacctmgr show qos ${filter} format=\"name%20,preempt,priority,GrpTRES,MaxTresPerJob,MaxJobsPerUser,MaxWall,flags\""
    echo "# ${cmd}"
    $cmd
}
alias showqos=sqos

## Sprio helpers
alias sp='sprio'
alias spl='sprio -l'
