#!/bin/bash -l
#SBATCH -A fv3-cpu        # -A specifies the account
#SBATCH -n 1                 # -n specifies the number of tasks (cores) (-N would be for number of nodes) 
#SBATCH --exclusive          # exclusive use of node - hoggy but OK
#SBATCH -q debug             # -q specifies the queue; debug has a 30 min limit, but the default walltime is only 5min, to change, see below:
#SBATCH -t 30                # -t specifies walltime in minutes; if in debug, cannot be more than 30
#
#
# This is a tiny little package that compares two sets of (exp1 and exp2) for a chosen variable, domain, season
# top directory with preprocessed files 

    whereexp=$noscrub/Models
    whereobs=$noscrub/ReferenceData
    
    hardcopy=yes                        # yes | no

    ystart=2011; yend=2018

    mstart=1; mend=12; mstep=1

    exp1=ufs_b3
    exp2=ufs_b31

    domain=GlobalTropics                   # Global | Global50 | GlobalTropics | Nino3.4 | NAM | CONUS 
    domain=Global20
    domain=NP
    season=AllAvailable               # DJF | MAM | JJA | SON | AllAvailable 
    #season=DJF
    

# The scripts are prepared to handle variables on the list below 
    oknames=(land tmpsfc tmp2m t2min t2max ulwrftoa dlwrf dswrf ulwrf uswrf prate pwat icetk icec cloudbdry cloudlow cloudmid cloudhi snow weasd snod lhtfl shtfl pres u10 v10 uflx vflx )

    #for varname in tmpsfc prate ulwrftoa t2min t2max; do

 for season in $season ; do
     bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=prate domain=CONUS hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=landonly
     #bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=t2min domain=CONUS hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=landonly
     #bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=t2max domain=CONUS hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=landonly
     #bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=ulwrftoa domain=NP hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=none
     #bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=ulwrftoa domain=SP hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=none
     #bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=ulwrftoa domain=Global20 hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=none

     #bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=prate domain=Global20 hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=none


     bash biasbins.sh whereexp=$whereexp whereobs=$whereobs varModel=tmpsfc domain=Global20 hardcopy=$hardcopy season=$season nameModelA=$exp1 nameModelB=$exp2  ystart=$ystart yend=$yend mstart=$mstart mend=$mend mstep=$mstep mask=oceanonly
 done

