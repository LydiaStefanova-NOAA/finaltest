
  function smallmean(fullfield)
  begin
    smallfield=dim_avg_n_Wrap(fullfield(0:6,2:2,{-90:90},{0:360}),(/0,1/))
    print(dimsizes(smallfield))
    return (smallfield)
  end


