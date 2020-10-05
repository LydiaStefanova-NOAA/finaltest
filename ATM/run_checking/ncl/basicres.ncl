  res                        = True
  res@gsnDraw                = False              ; don't draw
  res@gsnFrame               = False              ; don't advance frame
  res@cnFillOn               = True               ; turns on the color
  res@mpFillOn               = False              ; turns off continent gray
  res@cnLinesOn              = False              ; turn off contour lines
  res@cnFillMode             = "RasterFill"


  res@mpGridAndLimbOn        = True
  res@mpShapeMode            = "FreeAspect"
  res@vpWidthF               = 0.8
  res@vpHeightF              = 0.4
  res@mpGridLineDashPattern  = 5                  ; lat/lon lines dashed
  res@mpGridLatSpacingF      = 30
  res@mpGridLonSpacingF      = 30
  res@mpGridLineColor        = "Gray30"

  res@mpCenterLonF           = (lonStart+lonEnd)/2
  res@mpMinLatF              = latStart
  res@mpMaxLatF              = latEnd
  res@mpMinLonF              = lonStart
  res@mpMaxLonF              = lonEnd
  res@cnLevelSelectionMode   = "ManualLevels"
  res@mpGeophysicalLineThicknessF=0.3


