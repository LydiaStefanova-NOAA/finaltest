#!/bin/bash 
#SBATCH --ntasks=1 -p service 
#SBATCH -t 4:00:00 
#SBATCH -A marine-cpu
#SBATCH -J b31-getfiles

module load hpss

    # Start/end delimiters for cases to get

        ystart=2013; yend=2013;  ystep=1
        mstart=2;    mend=12;    mstep=6
        dstart=1;    dend=1;    dstep=14

    # Name and location of experiment output on HPSS

        exp_new=ufs_p4
        #hpss_root=/NCEPDEV/emc-climate/5year/Jiande.Wang/WCOSS/scratch/preUFSp4/c384/  # upload data from here
        hpss_root=/NCEPDEV/emc-climate/5year/Jiande.Wang/WCOSS/benchmark4.0/c384/
        upload_root=/scratch1/NCEPDEV/stmp2/Lydia.B.Stefanova/fromHPSS/                # store uploaded data here

#===================================================================================================================
for exp in $exp_new ; do
    upload_location=${upload_root}/${exp}
    for (( yyyy=$ystart; yyyy<=$yend; yyyy+=$ystep )) ; do
    for (( mm1=$mstart; mm1<=$mend; mm1+=$mstep )) ; do
    for (( dd1=$dstart; dd1<=$dend; dd1+=$dstep )) ; do
        mm=$(printf "%02d" $mm1)
        dd=$(printf "%02d" $dd1)
        tag=$yyyy$mm${dd}00
        if [ ! -f ${upload_location}/$tag/gfs.$yyyy$mm$dd/00/gfs.t00z.flux.1p00.f840 ] ; then 
           hpss_location=${hpss_root}/$tag
           atmflux1p00=gfs_flux_1p00.tar
           echo "Working on $tag for $exp"
           mkdir -p ${upload_location}/$tag
           cd ${upload_location}/$tag
           htar -xvf ${hpss_location}/$atmflux1p00
        else
           echo "$exp $tag  already uploaded" 
        fi
    done
    done
    done
done
