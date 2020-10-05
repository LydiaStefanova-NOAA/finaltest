'reinit'
year=2011
lastyear=2012
lastmonth=13
pass=1
t1=21
t2=30

while (year < lastyear)
  month=1
  if (year=2011) 
     month=4
  endif
  if (year=2018)
     lastmonth=4
  endif
  while (month < lastmonth ) 
      mm=month
      if (month<10 )
          mm='0'month
      endif
      day=01
      while (day < 16 ) 

        'sdfopen /scratch2/NCEPDEV/climate/Lydia.B.Stefanova/ReferenceData//sst_OSTIA/1p00/dailymean/sst_OSTIA.day.mean.'year''mm''day'.1p00.nc'
        'sdfopen /scratch2/NCEPDEV/climate/Lydia.B.Stefanova/Models/ufs_b31/1p00/dailymean/'year''mm''day'/tmpsfc.ufs_b31.'year''mm''day'.dailymean.1p00.nc'
        'sdfopen /scratch2/NCEPDEV/climate/Lydia.B.Stefanova/Models/ufs_b33/1p00/dailymean/'year''mm''day'/tmpsfc.ufs_b33.'year''mm''day'.dailymean.1p00.nc'
        'sdfopen /scratch2/NCEPDEV/climate/Lydia.B.Stefanova/Models/ufs_b31/1p00/dailymean/'year''mm''day'/land.ufs_b31.'year''mm''day'.dailymean.1p00.nc'
        'sdfopen /scratch2/NCEPDEV/climate/Lydia.B.Stefanova/Models/ufs_b33/1p00/dailymean/'year''mm''day'/land.ufs_b33.'year''mm''day'.dailymean.1p00.nc'
        
         if (pass = 1) 
            'set dfile 1'
            'define obs=ave(analysed_sst.1,t='t1',t='t2')'
            'set dfile 2'
            'define mod31=maskout(ave(tmp_surface.2,t='t1',t='t2'),-land_surface.4)'
            'define mod33=maskout(ave(tmp_surface.3,t='t1',t='t2'),-land_surface.5)'
         else
            'set dfile 1'
            'define obs=obs+ave(analysed_sst.1,t='t1',t='t2')'
            'set dfile 2'
            'define mod31=mod31+maskout(ave(tmp_surface.2,t='t1',t='t2'),-land_surface.4)'
            'define mod33=mod33+maskout(ave(tmp_surface.3,t='t1',t='t2'),-land_surface.5)'

         endif

        'close 5'
        'close 4'
        'close 3'
        'close 2'
        'close 1'

        day = day + 14
        pass = pass + 1
      endwhile
      month=month+1
  endwhile
year=year+1
endwhile
say pass
        'sdfopen /scratch2/NCEPDEV/climate/Lydia.B.Stefanova/Models/ufs_b33/1p00/dailymean/20120101/land.ufs_b33.20120101.dailymean.1p00.nc'
'set lat -50 50 '
pass=pass-1
lat=20
while (lat<90) 
'd aave(mod31-obs,lon=0,lon=360,lat=-'lat',lat='lat')/'pass
say lat' 'result
'd aave(mod33-obs,lon=0,lon=360,lat=-'lat',lat='lat')/'pass
say lat' 'result
'd aave(mod33-mod31,lon=0,lon=360,lat=-'lat',lat='lat')/'pass
say lat' 'result
lat=lat+10
endwhile
