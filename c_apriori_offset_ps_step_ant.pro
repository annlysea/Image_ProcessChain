pro c_apriori_offset_ps_step_ant,id1,id2,rgspac,line_spac,verbose=verbose

geo=load_geo_param(gc=id1+'.DEM_gc_par')

if (~exist(rgspac)) then rgspac = 25
if (~exist(line_spac)) then line_spac = rgspac

posting0=geo.posting
geo.posting=geo.posting*rgspac
geo.xposting=geo.xposting*rgspac
geo.yposting=geo.yposting*line_spac
geo.npix=geo.npix/rgspac
geo.nrec=geo.nrec/line_spac

;Modif ER 10/20/2017
;a=geocode_im('/u/baku-z0/eric/DATA_SERVER/ANTARCTICA/VEL/ANT_450m/vel_10Jan2013_450m.ian_ronne.larsenb2000.sav',geoloc=geo,/sav)
;a=geocode_im('/u/pennell-z0/eric/ANTARCTICA/MOSAIC/450m/2014-07-01_2015-06-31/AllSensors/vel_final_2014_2015.sav',geoloca=geo,/sav)

vx = geocode_im('/u/pennell-z0/eric/ANTARCTICA/MOSAIC/450m/EVERYTHING/vMAR2017/vel_nsidc.CF16.nc',nc="VX",geoloc=geo)
vy = geocode_im('/u/pennell-z0/eric/ANTARCTICA/MOSAIC/450m/EVERYTHING/vMAR2017/vel_nsidc.CF16.nc',nc="VY",geoloc=geo)
a = complex(vx, vy)

p1=load_isp_param(id1+'.par')
p2=load_isp_param(id2+'.par')

date1 = DATE2MJD( long(p1.date[0]), long(p1.date[1]), long(p1.date[2]))
date2 = DATE2MJD( long(p2.date[0]), long(p2.date[1]), long(p2.date[2]))

if keyword_set(verbose) then begin
    print,"date1:",date1
    print,"date2:",date2
endif

laps = float(date2-date1)

a=a/365.25*laps/posting0 ;; convert m/yr in offset

w=where(finite(float(a)) eq 0 or float(a) eq 0,cnt)

if cnt ne 0 then a[w]=complex(!values.f_nan,!values.f_nan)

a=complex(smooth(float(a),3,/nan),smooth(imaginary(a),3,/nan))

w=where(finite(float(a)) eq 0 or float(a) eq 0,cnt)
if cnt ne 0 then a[w]=complex(0.,0.)

openw,1,id1+'-'+id2+'.off_apriori.off',/swap_if_little_endian
writeu,1,complex(float(a),-imaginary(a))
close,1

poff=load_off_param()
poff.nrec=geo.nrec
poff.npix=geo.npix
poff.rgsp=rgspac
poff.azsp=line_spac

write_off_param,id1+'-'+id2+'.off_apriori.par',poff
file_link, id1+"-"+id2+".off_apriori.par", id1+"_sobel-"+id2+"_sobel.off_apriori.par"
file_link, id1+"-"+id2+".off_apriori.off", id1+"_sobel-"+id2+"_sobel.off_apriori.off"

end
