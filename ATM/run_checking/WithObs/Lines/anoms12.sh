#!/bin/bash -l
#SBATCH -A marine-cpu        # -A specifies the account
#SBATCH -n 1                 # -n specifies the number of tasks (cores) (-N would be for number of nodes) 
#SBATCH --exclusive          # exclusive use of node - hoggy but OK
#SBATCH -q batch             # -q specifies the queue; debug has a 30 min limit, but the default walltime is only 5min, to change, see below:
#SBATCH -t 120               # -t specifies walltime in minutes; if in debug, cannot be more than 30

# (proper RMSe calculation version)
# Creates and runs ncl script with given specifications for paths, names, and preferences
#
# The result is a four-panel plot with time series of a) area mean, b) area mean bias, c) raw RMS, d) bias-corrected RMS


module load ncl

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)
    case "$KEY" in
            whereexp)   whereexp=${VALUE} ;;             # path to models
            whereobs)   whereobs=${VALUE} ;;             # path to OBS
            hardcopy)   hardcopy=${VALUE} ;;             # yes/no hardcopy
            domain)     domain=${VALUE} ;;               # choice of preset domains
            varModel)   varModel=${VALUE} ;;             # model variable name
            season)     season=${VALUE} ;;               # choice of DJF, MAM, JJA, SON
            nameModelA) nameModelA=${VALUE} ;;           # name of first experiment
            nameModelB) nameModelB=${VALUE} ;;           # name of second experiment
            ystart)     ystart=${VALUE} ;;               # first year to consider
            yend)       yend=${VALUE} ;;                 # last year to consider
            ystep)      ystep=${VALUE} ;;                 # last year to consider
            mstart)     mstart=${VALUE} ;;               # first month to consider
            mend)       mend=${VALUE} ;;                 # last month to consider
            mstep)      mstep=${VALUE} ;;                # interval between months to consider
            dstart)     dstart=${VALUE} ;;               # first month to consider
            dend)       dend=${VALUE} ;;                 # last month to consider
            dstep)      dstep=${VALUE} ;;                # interval between months to consider
            mask)       mask=${VALUE} ;;             # oceanonly/landonly/none
            *)
    esac
done

case "$domain" in 
    "Global") latS="-90"; latN="90" ;  lonW="0" ; lonE="360" ;;
    "Nino34") latS="-5"; latN="5" ;  lonW="190" ; lonE="240" ;;
    "GlobalTropics") latS="-30"; latN="30" ;  lonW="0" ; lonE="360" ;;
    "Global20") latS="-20"; latN="20" ;  lonW="0" ; lonE="360" ;;
    "Global50") latS="-50"; latN="50" ;  lonW="0" ; lonE="360" ;;
    "Global60") latS="-60"; latN="90" ;  lonW="0" ; lonE="360" ;;
    "CONUS") latS="25"; latN="60" ;  lonW="210" ; lonE="300" ;;
    "NAM") latS="0"; latN="90" ;  lonW="180" ; lonE="360" ;;
    "IndoChina") latS="-20"; latN="40" ;  lonW="30" ; lonE="150" ;;
    "NP") latS="50"; latN="90" ;  lonW="0" ; lonE="360" ;;
    "SP") latS="-90"; latN="-50" ;  lonW="0" ; lonE="360" ;;
    "DatelineEq") latS="-1"; latN="1" ;  lonW="179" ; lonE="181" ;;
    *)
esac

       mask=$mask
       if [ "$varModel" == "t2max" ] ; then
          ncvarModel="TMAX_2maboveground"; multModel=1.; offsetModel=0.; units="deg K"
          nameObs="t2max_CPC";  varObs="tmax"; ncvarObs="tmax"; multObs=1.; offsetObs=273.15
       fi
       if [ "$varModel" == "tmp2m" ] ; then
          ncvarModel="TMP_2maboveground"; multModel=1.; offsetModel=0.; units="deg K"
          nameObs="era5";  varObs="t2m"; ncvarObs="TMP_2maboveground"; multObs=1.; offsetObs=0.
       fi
       if [ "$varModel" == "t2m_fromminmax" ] ; then
          ncvarModel="t2m_fromminmax"; multModel=1.; offsetModel=0.; units="deg K";mask="landonly"
          nameObs="t2m_from_minmax_CPC";  varObs="t2m_CPC"; ncvarObs="t2m"; multObs=1.; offsetObs=273.15
       fi
       if [ "$varModel" == "t2min" ] ; then
          ncvarModel="TMIN_2maboveground"; multModel=1.; offsetModel=0.; units="deg K"
          nameObs="t2min_CPC";  varObs="tmin"; ncvarObs="tmin"; multObs=1.; offsetObs=273.15
       fi
       if [ "$varModel" == "tmpsfc" ] ; then
          ncvarModel="TMP_surface"; multModel=1.; offsetModel=0.; units="deg K"
          nameObs="sst_OSTIA";  varObs="sst_OSTIA"; ncvarObs="analysed_sst"; multObs=1.; offsetObs=0.
       fi
       if [ "$varModel" == "prate" ] ; then
          ncvarModel="PRATE_surface"; multModel=86400.; offsetModel=0.; units="mm/day"
          nameObs="pcp_CPC_Global";  varObs="rain"; ncvarObs="rain"; multObs=0.1; offsetObs=0.
          nameObs="pcp_TRMM";  varObs="pcp-TRMM"; ncvarObs="precipitation"; multObs=1; offsetObs=0.
       fi
       if [ "$varModel" == "ulwrftoa" ] ; then
          ncvarModel="ULWRF_topofatmosphere"; multModel=1.; offsetModel=0.; units="W/m^2"
          nameObs="olr_HRIS"; varObs="ulwrftoa"; ncvarObs="olr"; multObs=1.; offsetObs=0.; units="W/m^2"
       fi

# Names for the anomaly arrays
       nameModelBA=${nameModelB}_minus_${nameModelA}
       nameModelA0=${nameModelA}_minus_${nameObs}
       nameModelB0=${nameModelB}_minus_${nameObs}
 
# Clean up file listings from last time
    
       if [ -f ${varModel}-${nameModelA}-list.txt ] ; then rm ${varModel}-${nameModelA}-list.txt ; fi
       if [ -f ${varModel}-${nameModelB}-list.txt ] ; then rm ${varModel}-${nameModelB}-list.txt ; fi
       if [ -f ${varModel}-${nameObs}-list.txt ] ; then rm ${varModel}-${nameObs}-list.txt ; fi

# Create file listings from which to read matching dates for model and obs data

       LENGTH=0   # Total length of each file listing

       for (( yyyy=$ystart; yyyy<=$yend; yyyy+=$ystep ))  ; do
       for (( mm1=$mstart; mm1<=$mend; mm1+=$mstep )) ; do
       for (( dd1=$dstart; dd1<=$dend; dd1+=$dstep )) ; do
           mm=$(printf "%02d" $mm1)
           dd=$(printf "%02d" $dd1)
           tag=$yyyy$mm${dd}
           if [ -f $whereexp/$nameModelA/1p00/dailymean/${tag}/${varModel}.${nameModelA}.${tag}.dailymean.1p00.nc ] ; then
              if [ -f $whereexp/$nameModelB/1p00/dailymean/${tag}/${varModel}.${nameModelB}.${tag}.dailymean.1p00.nc ] ; then
                  pathObs="$whereobs/$nameObs/1p00/dailymean"
                  if [ "$nameObs" == "pcp_TRMM" ] ;  then
                      pathObs="$whereobs/$nameObs/1p00"
                  fi
                  #echo "yes" $pathObs/${varObs}.day.mean.${tag}.1p00.nc

                  if [ -f $pathObs/${varObs}.day.mean.${tag}.1p00.nc ] ; then
                   
                   
                  case "${season}" in
                      *"DJF"*)
                          if [ $mm1 -ge 12 ] || [ $mm1 -le 2 ] ; then
                             for nameModel in $nameModelA $nameModelB ; do
                                 pathModel="$whereexp/$nameModel/1p00/dailymean"
                                 ls -d -1 $pathModel/${tag}/${varModel}.${nameModel}.${tag}.dailymean.1p00.nc >> ${varModel}-${nameModel}-list.txt
                             done
	                         ls -d -1 $pathObs/${varObs}.day.mean.${tag}.1p00.nc >> ${varModel}-${nameObs}-list.txt
                                 LENGTH="$(($LENGTH+1))"                       
                          fi
                      ;;
                      *"MAM"*)
                          if [ $mm1 -ge 3 ] && [ $mm1 -le 5 ] ; then
                             for nameModel in $nameModelA $nameModelB ; do
                                 pathModel="$whereexp/$nameModel/1p00/dailymean"
                                 ls -d -1 $pathModel/${tag}/${varModel}.${nameModel}.${tag}.dailymean.1p00.nc >> ${varModel}-${nameModel}-list.txt
                             done
	                         ls -d -1 $pathObs/${varObs}.day.mean.${tag}.1p00.nc >> ${varModel}-${nameObs}-list.txt
                                 LENGTH="$(($LENGTH+1))"                      
                          fi
                      ;;
                      *"JJA"*)
                          if [ $mm1 -ge 6 ] && [ $mm1 -le 8 ] ; then
                             for nameModel in $nameModelA $nameModelB ; do
                                 pathModel="$whereexp/$nameModel/1p00/dailymean"
                                 ls -d -1 $pathModel/${tag}/${varModel}.${nameModel}.${tag}.dailymean.1p00.nc >> ${varModel}-${nameModel}-list.txt
                             done
	                         ls -d -1 $pathObs/${varObs}.day.mean.${tag}.1p00.nc >> ${varModel}-${nameObs}-list.txt
                                 LENGTH="$(($LENGTH+1))"                     
                          fi
                      ;;
                      *"SON"*)
                          if [ $mm1 -ge 9 ] && [ $mm1 -le 11 ] ; then
                             for nameModel in $nameModelA $nameModelB ; do
                                 pathModel="$whereexp/$nameModel/1p00/dailymean"
                                 ls -d -1 $pathModel/${tag}/${varModel}.${nameModel}.${tag}.dailymean.1p00.nc >> ${varModel}-${nameModel}-list.txt
                             done
	                         ls -d -1 $pathObs/${varObs}.day.mean.${tag}.1p00.nc >> ${varModel}-${nameObs}-list.txt
                                 LENGTH="$(($LENGTH+1))"                   
                          fi
                      ;;
                      *"AllAvailable"*)
                             for nameModel in $nameModelA $nameModelB ; do
                                 pathModel="$whereexp/$nameModel/1p00/dailymean"
                                 ls -d -1 $pathModel/${tag}/${varModel}.${nameModel}.${tag}.dailymean.1p00.nc >> ${varModel}-${nameModel}-list.txt
                             done
	                         ls -d -1 $pathObs/${varObs}.day.mean.${tag}.1p00.nc >> ${varModel}-${nameObs}-list.txt
                                 LENGTH="$(($LENGTH+1))"                  
                      ;;
                 esac

              fi
           fi
           fi
       done
       done
       done

   echo "A total of $LENGTH ICs are being processed"
   truelength=$LENGTH

# The if below takes care of the situation where there is a single IC by listing it twice (so that it can still be read with "addfiles")
   if [ $LENGTH -eq 1 ] ; then
                             for nameModel in $nameModelA $nameModelB ; do
                              cat ${varModel}-${nameModel}-list.txt ${varModel}-${nameModel}-list.txt > tmp.txt
                              mv tmp.txt ${varModel}-${nameModel}-list.txt
                             done
                              cat ${varModel}-${nameObs}-list.txt ${varModel}-${nameObs}-list.txt > tmp.txt
                              mv tmp.txt ${varModel}-${nameObs}-list.txt
                                 LENGTH="$(($LENGTH+1))"                       # How many ICs are considered
   fi
#

   echo "A total of $truelength ICs are being processed"

   LENGTHm1="$(($LENGTH-1))"                          # Needed for counters starting at 0
   s1=0; s2=$LENGTHm1                                 # Glom together all ICs
   d1=0; d2=28                                        # from day=d1 to day=d1 (counter starting at 0)
   d1p1="$(($d1+1))"                                  # day1 (counter starting at 1)
   d2p1="$(($d2+1))"                                  # day2 (counter starting at 1)

###################################################################################################
#                                            Create ncl script
###################################################################################################

nclscript="linermse12_${season}.ncl"                         # Name for the NCL script to be created

cat << EOF > $nclscript

  if isStrSubset("$hardcopy","yes") then
     wks_type                     = "png"
     wks_type@wkWidth             = 3000
     wks_type@wkHeight            = 3000
  else
     wks_type                     = "x11"
     wks_type@wkWidth             = 1200
     wks_type@wkHeight            = 800
  end if 

  wks                          = gsn_open_wks(wks_type,"rmse.${varModel}.${nameModelA}.${nameModelB}.${season}.${ystart}-${yend}.${truelength}IC.$domain.$mask")

  latStart=${latS}
  latEnd=${latN}
  lonStart=${lonW}
  lonEnd=${lonE}

  if isStrSubset("$domain","Global") then
     lonStart=30
     lonEnd=390
  end if

  
  ${nameModelA}_list=systemfunc ("if [ -f  ${varModel}-${nameModelA}-list.txt ] ; then awk  '{print} NR==${LENGTH}{exit}' ${varModel}-${nameModelA}-list.txt } ; fi") 
  ${nameModelB}_list=systemfunc ("if [ -f  ${varModel}-${nameModelB}-list.txt ] ; then awk  '{print} NR==${LENGTH}{exit}' ${varModel}-${nameModelB}-list.txt } ; fi") 
  ${nameObs}_list=systemfunc ("awk  '{print} NR==${LENGTH}{exit}' ${varModel}-${nameObs}-list.txt }") 

  ${nameModelA}_add = addfiles (${nameModelA}_list, "r")   ; note the "s" of addfile
  ${nameModelB}_add = addfiles (${nameModelB}_list, "r")   
  ${nameObs}_add = addfiles (${nameObs}_list, "r")   

;---Use the landmask in ${nameModelA} to define land or ocean
;   Note that 1 is land, 0 is ocean, 2 is ice-covered ocean
;   variable "masker" is set to fill value over land

  mask_add=addfile("$whereexp/$nameModelB/1p00/dailymean/20130401/land.${nameModelB}.20130401.dailymean.1p00.nc", "r")
  masker=mask_add->LAND_surface(0,:,:)
  masker=where(masker.ne.1,masker,masker@_FillValue)   


;---Read variables in "join" mode 

  ListSetType (${nameModelA}_add, "join") 
  ListSetType (${nameModelB}_add, "join") 
  ListSetType (${nameObs}_add, "join") 
   

  ${nameModelA}_lat_0=${nameModelA}_add[:]->latitude
  ${nameModelA}_lon_0=${nameModelA}_add[:]->longitude

  ${nameModelA}_fld = ${nameModelA}_add[:]->${ncvarModel}
  ${nameModelB}_fld = ${nameModelB}_add[:]->${ncvarModel}

;---Special provision for OSTIA which is written in short format

  if isStrSubset("$nameObs","sst_OSTIA") then
     ${nameObs}_fld = short2flt(${nameObs}_add[:]->${ncvarObs})
  else

;---Special provision for TRMM which has a different ordering of dimensions

     if isStrSubset("$nameObs","TRMM") then
  
       ${nameObs}_fld_toflip = ${nameObs}_add[:]->${ncvarObs}
       ${nameObs}_fld = ${nameObs}_fld_toflip(ncl_join|:,time|:,lat|:,lon|:)
     else

;---No special provision for other OBS

     ${nameObs}_fld = ${nameObs}_add[:]->${ncvarObs}
     end if 
  end if

;--- Provision for one of the models being a shorter run 

  dimsA=dimsizes(${nameModelA}_fld)
  dimsB=dimsizes(${nameModelB}_fld)
  dimsTA=dimsA(1)
  dimsTB=dimsB(1)
  if (dimsTA.lt.dimsTB) then
     dimsT=dimsTA
     else
       dimsT=dimsTB
  end if
  print(dimsT)
  ${nameModelA}_fld := ${nameModelA}_fld(:,0:dimsT-1,:,:) 
  ${nameModelB}_fld := ${nameModelB}_fld(:,0:dimsT-1,:,:) 
  ${nameObs}_fld := ${nameObs}_fld(:,0:dimsT-1,:,:)

;---Adjust scaling and offset  

  ${nameModelA}_fld=${nameModelA}_fld*${multModel} + 1.*($offsetModel)
  ${nameModelB}_fld=${nameModelB}_fld*${multModel} + 1.*($offsetModel)
  ${nameObs}_fld=${nameObs}_fld*${multObs} + 1.*($offsetObs)

;---Apply mask

  maskerbig=conform_dims(dimsizes(${nameModelA}_fld),masker,(/2,3/))
  if isStrSubset("$mask","landonly") then
    ${nameObs}_fld=where(ismissing(maskerbig),${nameObs}_fld,${nameObs}_fld@_FillValue)
    ${nameModelA}_fld=where(ismissing(maskerbig),${nameModelA}_fld,${nameModelA}_fld@_FillValue)
    ${nameModelB}_fld=where(ismissing(maskerbig),${nameModelB}_fld,${nameModelB}_fld@_FillValue)
  end if 
  if isStrSubset("$mask","oceanonly") then
    ${nameObs}_fld=where(.not.ismissing(maskerbig),${nameObs}_fld,${nameObs}_fld@_FillValue)
    ${nameModelA}_fld=where(.not.ismissing(maskerbig),${nameModelA}_fld,${nameModelA}_fld@_FillValue)
    ${nameModelB}_fld=where(.not.ismissing(maskerbig),${nameModelB}_fld,${nameModelB}_fld@_FillValue)
  end if 
  ${nameModelA}_fld=where(.not.ismissing(${nameObs}_fld),${nameModelA}_fld,${nameModelA}_fld@_FillValue)
  ${nameModelB}_fld=where(.not.ismissing(${nameObs}_fld),${nameModelB}_fld,${nameModelB}_fld@_FillValue)
  print(num(.not.ismissing(${nameModelA}_fld)))
  print(num(.not.ismissing(${nameModelB}_fld)))
  print(num(.not.ismissing(${nameObs}_fld)))

;---Specify dimensions of lat/lon as specified in $domain

  lat_0 = ${nameModelA}_lat_0(0,{${latS}:${latN}})
  lon_0 = ${nameModelA}_lon_0(0,{${lonW}:${lonE}})
  nlon=dimsizes(lon_0)
  nlat=dimsizes(lat_0)
  dimsObs=getvardims(${nameObs}_fld)
  dimsModel=getvardims(${nameModelA}_fld)

;---Limit extent according to the domain specifications

  ${nameObs}_small=${nameObs}_fld($s1:$s2,:,{${latS}:${latN}},{${lonW}:${lonE}})
  ${nameModelA}_small=${nameModelA}_fld($s1:$s2,:,{${latS}:${latN}},{${lonW}:${lonE}})
  ${nameModelB}_small=${nameModelB}_fld($s1:$s2,:,{${latS}:${latN}},{${lonW}:${lonE}})

;---Calculate mean maps

  ${nameModelA}_mean=dim_avg_n_Wrap(${nameModelA}_fld($s1:$s2,:,{${latS}:${latN}},{${lonW}:${lonE}}),(/0/))
  ${nameModelB}_mean=dim_avg_n_Wrap(${nameModelB}_fld($s1:$s2,:,{${latS}:${latN}},{${lonW}:${lonE}}),(/0/))
  ${nameObs}_mean=dim_avg_n_Wrap(${nameObs}_fld($s1:$s2,:,{${latS}:${latN}},{${lonW}:${lonE}}),(/0/))

;---Calculate anomaly maps 
  
  ${nameObs}_anom=${nameObs}_small
  ${nameModelA}_anom=${nameModelA}_small
  ${nameModelB}_anom=${nameModelB}_small

  ${nameObs}_anom=${nameObs}_small-conform_dims(dimsizes(${nameObs}_small),${nameObs}_mean, (/1,2,3/))
  ${nameModelA}_anom=${nameModelA}_small-conform_dims(dimsizes(${nameModelA}_small),${nameModelA}_mean, (/1,2,3/))
  ${nameModelB}_anom=${nameModelB}_small-conform_dims(dimsizes(${nameModelB}_small),${nameModelB}_mean, (/1,2,3/))

;---Calculate bias maps

  ${nameModelA0}_diff=${nameModelA}_mean
  ${nameModelB0}_diff=${nameModelB}_mean

  ${nameModelA0}_diff=${nameModelA}_mean-${nameObs}_mean
  ${nameModelB0}_diff=${nameModelB}_mean-${nameObs}_mean

;---Specify units

  ${nameObs}_mean@units="$units"
  ${nameModelA}_mean@units="$units"
  ${nameModelB}_mean@units="$units"
  ${nameModelA0}_diff@units="$units"
  ${nameModelB0}_diff@units="$units"

;---Define weights for area average

  rad    = 4.0*atan(1.0)/180.0
  re     = 6371220.0
  rr     = re*rad

  dlon   = abs(lon_0(2)-lon_0(1))*rr
  dx     = dlon*cos(lat_0*rad)
  dy     = new ( nlat, typeof(dx))
  dy(0)  = abs(lat_0(2)-lat_0(1))*rr
  dy(1:nlat-2)  = abs(lat_0(2:nlat-1)-lat_0(0:nlat-3))*rr*0.5   
  dy(nlat-1)    = abs(lat_0(nlat-1)-lat_0(nlat-2))*rr

  weights2   = dx*dy 

  opt=0  ; ignore missing values

;---Calculate area means of the raw fields

  ${nameModelA}_aave=wgt_areaave_Wrap(${nameModelA}_mean, weights2,1.0, opt)
  ${nameModelB}_aave=wgt_areaave_Wrap(${nameModelB}_mean, weights2,1.0, opt)
  ${nameObs}_aave=wgt_areaave_Wrap(${nameObs}_mean, weights2,1.0, opt)

;---Calculate area means of the anomaly fields

  ${nameModelA0}_aave=wgt_areaave_Wrap(${nameModelA0}_diff, weights2,1.0, opt)
  ${nameModelB0}_aave=wgt_areaave_Wrap(${nameModelB0}_diff, weights2,1.0, opt)

;---Calculate raw RMSE 

  ${nameObs}_reorder=${nameObs}_small( \$dimsObs(1)\$ | :,  \$dimsObs(0)\$ | :, \$dimsObs(2)\$ | : , \$dimsObs(3)\$ | :)
  ${nameModelA}_reorder=${nameModelA}_small( \$dimsModel(1)\$ | :,  \$dimsModel(0)\$ | :, \$dimsModel(2)\$ | : , \$dimsModel(3)\$ | :)
  ${nameModelB}_reorder=${nameModelB}_small( \$dimsModel(1)\$ | :,  \$dimsModel(0)\$ | :, \$dimsModel(2)\$ | : , \$dimsModel(3)\$ | :)

  ${nameModelA}_rmse=wgt_volrmse(${nameObs}_reorder, ${nameModelA}_reorder, 1.0,weights2,1.0, opt)
  ${nameModelB}_rmse=wgt_volrmse(${nameObs}_reorder, ${nameModelB}_reorder, 1.0,weights2,1.0, opt)
 
         
;---Calculate bias-corrected RMSE

  ${nameObs}_anomreorder=${nameObs}_anom( \$dimsObs(1)\$ | :,  \$dimsObs(0)\$ | :, \$dimsObs(2)\$ | : , \$dimsObs(3)\$ | :)
  ${nameModelA}_anomreorder=${nameModelA}_anom( \$dimsModel(1)\$ | :,  \$dimsModel(0)\$ | :, \$dimsModel(2)\$ | : , \$dimsModel(3)\$ | :)
  ${nameModelB}_anomreorder=${nameModelB}_anom( \$dimsModel(1)\$ | :,  \$dimsModel(0)\$ | :, \$dimsModel(2)\$ | : , \$dimsModel(3)\$ | :)

  ${nameModelA}_anomrmse=wgt_volrmse(${nameObs}_anomreorder, ${nameModelA}_anomreorder, 1.0,weights2,1.0, opt)
  ${nameModelB}_anomrmse=wgt_volrmse(${nameObs}_anomreorder, ${nameModelB}_anomreorder, 1.0,weights2,1.0, opt)
   

;---Set ploting specifications

  res                     = True
  res@gsnDraw             = False                          ; don't draw
  res@gsnFrame            = False                          ; don't advance frame
  res@xyLineThicknesses = (/10.0, 10.0,  10.0/)          ; make second line thicker
  res@xyLineColors      = (/"red", "blue", "black"/)          ; change line color
  res@xyLineColors      = (/"blue", "orange", "black"/)          ; change line color
  res@xyExplicitLegendLabels = (/"${nameModelA}", "${nameModelB}", "${nameObs}"/)
 ; res@tiMainString      = "$domain, $season,  $truelength ICs, $mask"       ; add title
  res@gsnYRefLine = 0
  res@gsnXRefLine = (/7,14,21,28,35/)

  res@pmLegendDisplayMode    = "Always"              ; turn on legend
  res@pmLegendSide           = "Right"                 ; Change location of 
 
  res@pmLegendWidthF         = 0.08                  ; Change width and
  res@lgLabelFontHeightF     = .02                   ; change font height
  res@lgPerimOn              = False                 ; no box around

  res0=res
  res1=res
  res2=res

  if (isStrSubset("{$varModel}","Atmpsfc")) then
    res0@trYMinF  = 299  
    res0@trYMaxF  = 300 
    res1@trYMinF  = -0.15 
    res1@trYMaxF  = 0.15
    res2@trYMinF  = 0  
    res2@trYMaxF  = 1 
  end if 
  if (isStrSubset("{$varModel}","At2min")) then
    if (isStrSubset("{$season}", "AJJA")) then
       res0@trYMinF  = 291
       res0@trYMaxF  = 294
       res1@trYMinF  = -1.5 
       res1@trYMaxF  = 1.5
       res2@trYMinF  = 1  
       res2@trYMaxF  = 5 
    else 
       res0@trYMinF  = 288  
       res0@trYMaxF  = 291
       res1@trYMinF  = -1.5 
       res1@trYMaxF  = 1.5
       res2@trYMinF  = 1  
       res2@trYMaxF  = 5 
    end if
  end if
  if (isStrSubset("{$varModel}","At2max")) then
    if (isStrSubset("{$season}", "AJJA")) then
      res0@trYMinF  = 302  
      res0@trYMaxF  = 305 
      res1@trYMinF  = -1.5 
      res1@trYMaxF  = 1.5
      res2@trYMinF  = 1  
      res2@trYMaxF  = 5 
    else
      res0@trYMinF  = 302-2  
      res0@trYMaxF  = 305-2
      res1@trYMinF  = -1.5 
      res1@trYMaxF  = 1.5
      res2@trYMinF  = 1  
      res2@trYMaxF  = 5 
    end if
  end if
  if (isStrSubset("{$varModel}","Aprate")) then
    res0@trYMinF  = 1.
    res0@trYMaxF  = 4.4 
    res1@trYMinF  = -1.5  
    res1@trYMaxF  = 1.5
    res2@trYMinF  = 0  
    res2@trYMaxF  = 15 
  end if
  if (isStrSubset("{$varModel}","Atoa")) then
    res0@trYMinF  = 250  
    res0@trYMaxF  = 275 
    res1@trYMinF  = 0 
    res1@trYMaxF  = 15
    res2@trYMinF  = 15  
    res2@trYMaxF  = 40 
  end if


  plot=new(4,graphic)  

  data0=new((/3,dimsizes(${nameModelA}_aave&time)/),float)
  data0(0,:)=${nameModelA}_aave
  data0(1,:)=${nameModelB}_aave
  data0(2,:)=${nameObs}_aave
  data0@long_name="Area mean, " + "$units"
  data0@units="$units"
  plot(0)=gsn_csm_xy(wks,ispan(1,dimsT,1),data0(:,0:dimsT-1),res0)

  data1=new((/3,dimsizes(${nameModelA}_aave&time)/),float)
  data1(0,:)=${nameModelA0}_aave
  data1(1,:)=${nameModelB0}_aave
  data1@long_name="Area mean Bias, " + "$units"
  data1@units="$units"
  plot(1)=gsn_csm_xy(wks,ispan(1,dimsT,1),data1(:,0:dimsT-1),res1)

  data2=new((/3,dimsizes(${nameModelA}_aave&time)/),float)
  data2(0,:)=${nameModelA}_rmse
  data2(1,:)=${nameModelB}_rmse
  data2@long_name="Raw RMSE, " + "$units"
  data2@units="$units"
  plot(2)=gsn_csm_xy(wks,ispan(1,dimsT,1),data2(:,0:dimsT-1),res2)

  data3=new((/3,dimsizes(${nameModelA}_aave&time)/),float)
  data3(0,:)=${nameModelA}_anomrmse
  data3(1,:)=${nameModelB}_anomrmse
  data3@long_name="Bias-corrected RMSE, "  + "$units"
  data3@units="$units"
  plot(3)=gsn_csm_xy(wks,ispan(1,dimsT,1),data3(:,0:dimsT-1),res2)

  panelopts                   = True
  panelopts@gsnPanelMainString = "$domain, $mask, ${varModel}, $season, ${ystart}-${yend}, $truelength ICs"

  panelopts@amJust   = "TopLeft"
  panelopts@gsnOrientation    = "landscape"
  panelopts@gsnPanelLabelBar  = False
  panelopts@gsnPanelRowSpec   = True
  panelopts@gsnMaximize       = True                          ; maximize plot in frame
  panelopts@gsnBoxMargin      = 0
  panelopts@gsnPanelYWhiteSpacePercent = 0
  panelopts@gsnPanelXWhiteSpacePercent = 5
  panelopts@amJust   = "TopLeft"
  gsn_panel(wks,plot,(/2,2/),panelopts)


EOF

ncl linermse12_${season}.ncl



