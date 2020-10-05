#!/bin/bash -l
#SBATCH -A marine-cpu        # -A specifies the account
#SBATCH -n 1                 # -n specifies the number of tasks (cores) (-N would be for number of yesdes) 
#SBATCH --exclusive          # exclusive use of node - hoggy but OK
#SBATCH -q debug             # -q specifies the queue; debug has a 30 min limit, but the default walltime is only 5min, to change, see below:
#SBATCH -t 30                # -t specifies walltime in minutes; if in debug, cannot be more than 30


# This is a tiny little package that compares two sets of (exp1 and exp2) for a chosen variable, domain, season
# The data is expected to be in /scratch3/NCEPDEV/marine/noscrub/Lydia.B.Stefanova/Models/$exp/1p00/dailymean/          
    
    hardcopy=no           # yes | no

    #exp1=ufs_p4
    #exp2=P4p0_uncoupled_GFS
    #exp2=P4p0_uncoupled_GSL

    exp1=ufs_b31

    exp1=ufs_p4
    exp2=ufs_p5

    #exp1=ufs_b1
    #exp2=ufs_b2


    #exp2=ufs_p4_pre                                                          
    #exp2=heratest
    
    whereexp=$noscrub/Models/


# The script is  prepared to handle variables on the list below 
    oknames=(land tmpsfc tmp2m t2min t2max ulwrftoa dlwrf dswrf ulwrf uswrf prate pwat icetk icec cloudbdry cloudlow cloudmid cloudhi snow weasd snod lhtfl shtfl pres u10 v10 uflx vflx soilm02m sfcr)

    #for varname in prate ulwrftoa cloudbdry cloudmid cloudlow cloudhi ; do
    # for varname in pwat prec soilm02m sfcr ; do
     for varname in icec icetk; do

    # for varname in shtfl lhtfl ; do
    #for varname in tmp2m tmpsfc prate pwat soilm02m sfcr ulwrftoa ulwrf uswrf dlwrf dswrf cloudbdry cloudlow cloudmid cloudhi shtfl lhtfl ; do
    #for varname in pres dlwrf dswrf ulwrf uswrf cloudbdry cloudlow cloudmid cloudhi shtfl lhtfl; do
       # for varname in dswrf uswrf ulwrftoa cloudlow cloudmid cloudhi ; do 
        case "${oknames[@]}" in 
                *"$varname"*)  ;; 
                *)
             echo "Exiting. To continue, please correct: unknown variable ---> $varname <---"
             exit
        esac
       for domain in NH ; do
            for season in JJA  ; do
                echo "Attempting $domain $season $varname "
                bash  map_compare_noobs_polar.sh varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2 d1=20 d2=34 whereexp=$whereexp
            done
        done
        for domain in Global  ; do    
            for season in JJA ; do
                echo "Attempting $domain $season $varname "
                bash  map_compare_noobs.sh varModel=$varname domain=$domain hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2 d1=0 d2=0 whereexp=$whereexp
            done
        done
    done

