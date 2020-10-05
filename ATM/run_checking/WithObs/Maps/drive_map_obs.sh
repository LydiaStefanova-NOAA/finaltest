#!/bin/bash -l
#SBATCH -A marine-cpu        # -A specifies the account
#SBATCH -n 1                 # -n specifies the number of tasks (cores) (-N would be for number of nodes) 
#SBATCH --exclusive          # exclusive use of node - hoggy but OK
#SBATCH -q debug             # -q specifies the queue; debug has a 30 min limit, but the default walltime is only 5min, to change, see below:
#SBATCH -t 30                # -t specifies walltime in minutes; if in debug, cannot be more than 30

    # Start/end delimiters for initial conditions

        ystart=2011; yend=2018;  ystep=1
        mstart=1;    mend=12;    mstep=3
        dstart=1;    dend=15;     dstep=14

    # Name and location of experiment and obs (data as 35-day time series in netcdf)

        obs_root=/scratch2/NCEPDEV/climate/Lydia.B.Stefanova/ReferenceData/    # Location of OBS: changing it is not recommended
        exp_root=/scratch2/NCEPDEV/climate/Lydia.B.Stefanova/Models/           # Location of models 
        whereexp=$exp_root
        whereobs=$obs_root

        exp_old=P4p0_uncoupled_GFS
        exp_new=P4p0_uncoupled_GSL


        exp_old=ufs_b31
        #exp_old=ufs_p4
        exp_new=ufs_p5

        res=1p00

    # Other specitications


        nplots=1      #valid choices are 9 or 3  
        mapscript=map_compare_obs.sh    
        hardcopy=yes       # Valid choices are yes no      
        domain=GlobalTropics       # Valid choices see [case "$domain" list] in mapping script
        domain=Global       # Valid choices see [case "$domain" list] in mapping script
                            # NB: keep in mind that verifying obs for tmpsfc (OSTIA SST) are not valid for ice-covered areas because tmpsfc there is not sst
        
        declare -a varlist=("ulwrftoa" "tmp2m" "tmpsfc" "prate" "t2min" "t2max"  )     # Valid choices for comparison with OBS are "tmpsfc" "prate" "ulwrftoa" "tmp2m" "t2min" "t2max" 
        declare -a seasonlist=( "MAM" "JJA" "DJF" "MAM" "SON" "AllAvailable")     # Valid choices are "DJF" "MAM" "JJA" "SON" "AllAvailable"
#        declare -a seasonlist=(  "AllAvailable")     # Valid choices are "DJF" "MAM" "JJA" "SON" "AllAvailable"
        declare -a varlist=("tmp2m" "ulwrftoa" "tmpsfc" "prate")

        declare -a seasonlist=(  "JJA" "AllAvailable")     # Valid choices are "DJF" "MAM" "JJA" "SON" "AllAvailable"
        declare -a varlist=("tmpsfc" )


        for season in ${seasonlist[@]} ; do
        for varname in ${varlist[@]}; do

            echo "using $mapscript $day1 to $day2 for $varname"
            bash $mapscript whereexp=$whereexp  whereobs=$whereobs varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp_old nameModelB=$exp_new ystart=$ystart yend=$yend ystep=$ystep  mstart=$mstart mend=$mend mstep=$mstep dstart=$dstart dend=$dend dstep=$dstep d1=0 d2=0  nplots=$nplots
            bash $mapscript whereexp=$whereexp  whereobs=$whereobs varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp_old nameModelB=$exp_new ystart=$ystart yend=$yend ystep=$ystep  mstart=$mstart mend=$mend mstep=$mstep dstart=$dstart dend=$dend dstep=$dstep d1=0 d2=6  nplots=$nplots
            bash $mapscript whereexp=$whereexp  whereobs=$whereobs varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp_old nameModelB=$exp_new ystart=$ystart yend=$yend ystep=$ystep  mstart=$mstart mend=$mend mstep=$mstep dstart=$dstart dend=$dend dstep=$dstep d1=7 d2=13  nplots=$nplots
            bash $mapscript whereexp=$whereexp  whereobs=$whereobs varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp_old nameModelB=$exp_new ystart=$ystart yend=$yend ystep=$ystep  mstart=$mstart mend=$mend mstep=$mstep dstart=$dstart dend=$dend dstep=$dstep d1=14 d2=20  nplots=$nplots
            bash $mapscript whereexp=$whereexp  whereobs=$whereobs varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp_old nameModelB=$exp_new ystart=$ystart yend=$yend ystep=$ystep  mstart=$mstart mend=$mend mstep=$mstep dstart=$dstart dend=$dend dstep=$dstep d1=13 d2=27  nplots=$nplots

done
done

