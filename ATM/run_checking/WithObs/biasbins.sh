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
            mstart)     mstart=${VALUE} ;;               # first month to consider
            mend)       mend=${VALUE} ;;                 # last month to consider
            mstep)      mstep=${VALUE} ;;                # interval between months to consider
            mask)       mask=${VALUE} ;;             # oceanonly/landonly/none
            *)
    esac
done

case "$domain" in 
    "Global") latS="-90"; latN="90" ;  lonW="0" ; lonE="360" ;;
    "Nino3.4") latS="-5"; latN="5" ;  lonW="190" ; lonE="240" ;;
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
          cmin=-5.; cmax=5.
       fi
       if [ "$varModel" == "t2min" ] ; then
          ncvarModel="TMIN_2maboveground"; multModel=1.; offsetModel=0.; units="deg K"
          nameObs="t2min_CPC";  varObs="tmin"; ncvarObs="tmin"; multObs=1.; offsetObs=273.15
          cmin=-5.; cmax=5.
       fi
       if [ "$varModel" == "tmpsfc" ] ; then
          ncvarModel="TMP_surface"; multModel=1.; offsetModel=0.; units="deg K"
          nameObs="sst_OSTIA";  varObs="sst_OSTIA"; ncvarObs="analysed_sst"; multObs=1.; offsetObs=0.
          cmin=-1.; cmax=1.
       fi
       if [ "$varModel" == "prate" ] ; then
          ncvarModel="PRATE_surface"; multModel=86400.; offsetModel=0.; units="mm/day"
          nameObs="pcp_CPC_Global";  varObs="rain"; ncvarObs="rain"; multObs=0.1; offsetObs=0.
          #nameObs="pcp_TRMM";  varObs="pcp-TRMM"; ncvarObs="precipitation"; multObs=1; offsetObs=0.
          cmin=-5.; cmax=5.
       fi
       if [ "$varModel" == "ulwrftoa" ] ; then
          ncvarModel="ULWRF_topofatmosphere"; multModel=1.; offsetModel=0.; units="W/m^2"
          nameObs="olr_HRIS"; varObs="ulwrftoa"; ncvarObs="olr"; multObs=1.; offsetObs=0.; units="W/m^2"
          cmin=-40.; cmax=40.
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

       for (( yyyy=$ystart; yyyy<=$yend; yyyy+=1 ))  ; do
       for (( mm1=$mstart; mm1<=$mend; mm1+=$mstep )) ; do
       for dd1 in {1..15..14} ; do
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
   d1=0; d2=34                                        # from day=d1 to day=d1 (counter starting at 0)
   d1p1="$(($d1+1))"                                  # day1 (counter starting at 1)
   d2p1="$(($d2+1))"                                  # day2 (counter starting at 1)

###################################################################################################
#                                            Create ncl script
###################################################################################################

nclscript="biasbins_${season}.ncl"                         # Name for the NCL script to be created


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

  wks                          = gsn_open_wks(wks_type,"bias.${varModel}.${nameModelA}.${nameModelB}.${season}.${truelength}IC.$domain.$mask")

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

  mask_add=addfile("$whereexp/$nameModelB/1p00/dailymean/20120101/land.${nameModelB}.20120101.dailymean.1p00.nc", "r")
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

;---Specify dimensions of lat/lon as specified in $domain

  lat_0 = ${nameModelA}_lat_0(0,{${latS}:${latN}})
  lon_0 = ${nameModelA}_lon_0(0,{${lonW}:${lonE}})
  nlon=dimsizes(lon_0)
  nlat=dimsizes(lat_0)
  dimsObs=getvardims(${nameObs}_fld)
  dimsModel=getvardims(${nameModelA}_fld)



; DEFINE PANEL PROPERTIES


    panelopts                   = True
    panelopts@gsnPanelRowSpec   = True
    panelopts@gsnPanelYWhiteSpacePercent = 5
    panelopts@gsnPanelXWhiteSpacePercent = 5

    title = "$domain $season $varModel vs $nameObs"

    panelopts@gsnPanelMainString = title    ; set main title
    panelopts@gsnPanelLabelBar  = True


; DEFINE BARCHART PROPERTIES (AC FOR WEEKS 1-5) 

       gsn_define_colormap(wks,"CBR_coldhot")
       cmap = read_colormap_file("CBR_coldhot")
       if isStrSubset("$varModel","prate") then
          gsn_define_colormap(wks,"CBR_drywet")
          cmap := read_colormap_file("CBR_drywet")
       end if
       if isStrSubset("$varModel","ul") then
          gsn_define_colormap(wks,"sunshine_diff_12lev")
          cmap := read_colormap_file("sunshine_diff_12lev")
          cmap:=cmap(1:12,:)
       end if


      cmin=1.0*$cmin
      cmax=1.0*$cmax
      cdel                         = (cmax-cmin)/20.
      tmp=dim_avg_n_Wrap(${nameModelA}_fld($s1:$s2,1:2,{${latS}:${latN}},{${lonW}:${lonE}}),(/0,1/))
      n_obs=num(.not.ismissing(tmp))
      print(n_obs)
      print(nlat + " " + nlon + " " + n_obs)


    histopts                                          = True
    histopts@gsnHistogramBarColors       = cmap
    histopts@gsnHistogramComputePercentagesNoMissing  = True
    histopts@gsnHistogramMinMaxBinsOn                 = True                                     ; do count data outside of bounds


    histopts@gsnDraw                                  = False                                    ; don't draw
    histopts@gsnFrame                                 = False                                    ; don't advance frame

   histopts@gsnHistogramBinIntervals                 = fspan(cmin+cdel,cmax-cdel,10)            ; define histogram bins

    histopts@tiXAxisOn                                = False                                    ; no X axis title
    histopts@tiYAxisOn                                = False                                    ; no Y axis title
    histopts@trYMaxF                                  = (1.*n_obs)                              ; Y axis scale

    histopts@gsnHistogramCompare        = True

    ;histopts@vpXF                                     = 0.15                                     ; X position of plot
    ;histopts@vpYF                                     = 0.3                                      ; Y position of plot
    ;histopts@vpWidthF                                 = 0.88                                     ; width of plot
    ;histopts@vpHeightF                                = 0.4                                      ; height of plot

  histopts@gsFillScaleF   = 2 
  histopts@gsnHistogramBarWidthPercent=50.
  histopts@gsEdgeThicknessF=4.



     nPanels                     = 5
     hist                        = new(nPanels,graphic)

    do week=1,5 
       d1=(week-1)*7
       d2=d1+6
  
;---Calculate mean maps

  ${nameModelA}_mean=dim_avg_n_Wrap(${nameModelA}_fld($s1:$s2,d1:d2,{${latS}:${latN}},{${lonW}:${lonE}}),(/0,1/))
  ${nameModelB}_mean=dim_avg_n_Wrap(${nameModelB}_fld($s1:$s2,d1:d2,{${latS}:${latN}},{${lonW}:${lonE}}),(/0,1/))
  ${nameObs}_mean=dim_avg_n_Wrap(${nameObs}_fld($s1:$s2,d1:d2,{${latS}:${latN}},{${lonW}:${lonE}}),(/0,1/))

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

;---Prepare bias for histograms

       bias1d=new((/2,dimsizes(ndtooned(${nameModelA0}_diff))/),float)
       bias1d(0,:)      = ndtooned(${nameModelA0}_diff)
       bias1d(1,:)      = ndtooned(${nameModelB0}_diff)

       hist(week-1)            = gsn_histogram(wks,bias1d,histopts)
       txres=True
       text=gsn_add_text(wks,hist(week-1),week,0.1, 0.45*n_obs,txres)

 end do

; THIS IS WHERE THE HISTOGRAMS ARE ACTUALLY DRAWN


 panelopts@gsnPanelMainString =  title
 gsn_panel(wks,hist,(/2,2,2/),panelopts)


EOF

ncl biasbins_${season}.ncl



