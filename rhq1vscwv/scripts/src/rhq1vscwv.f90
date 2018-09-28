! stratify RH (%) or Q1 (K/day) with 1-mm-wide bins of the column water vapor (CWV; mm or kg/ m^2)
! ECMWF GRIB_API is required decode GRIB data
! ifort **.f90 -I$GRIB_API/include -L$GRIB_API/lib -lgrib_api_f90
! contact: Weiwei Li (weiweili@ucar.edu). The code is also contributed by Zhuo Wang (zhuowang@illinois.edu)

include 'grib_api_decode.f' ! subroutine to decode GRIB data
include 'ngrd.f'

program main

integer, parameter:: y1=beg_y, y2=end_y, m1=beg_m, m2=end_m, h1=00, h2=00
integer, parameter:: nlon=num_x, nlat=num_y
integer, parameter:: nbs=num_bs
real, parameter:: lon0=xx0, lat0=yy0, igrd=grdd
real, dimension(nbs):: sb,nb,wb,eb
!tropical belt around the globe (in degree)
data sb/YY1/
data nb/YY2/
data wb/XX1/
data eb/XX2/
integer lat1,lat2,lon1,lon2,nlat2

integer, parameter:: nz1=num_selz1, nz2=num_selz2
integer, dimension(nz1):: alev1
data alev1/sellevs1/
integer, dimension(nz2):: alev2
data alev2/sellevs2/

integer, parameter:: nfcst=num_fcst
integer, dimension(nfcst):: fcst
data fcst/selfcst/

character*200 year*4, mon*2, day*2, hour*2, lead*3
character*10, parameter:: shortnm0='vnameinput',shortnm1='vnamecwv',shortnm2='vnamelmsk'
! stratify bins for CWV
integer, parameter:: nbin=nbb
real, parameter:: pwmax=cwv1,pwmin=cwv0,step=(pwmax-pwmin)/real(nbin-1)

real,parameter:: dmiss=-9.99e+08
real, dimension(nlon,nlat):: ldmask,pw
real, dimension(nlon,nlat,nz1):: var
real, dimension(nz1,nbin):: var_sum, var_str, nn_sum
real, dimension(nbin):: nn_sum_str

character*200:: inpath,filein,filename,fileout,inpath_q1,filein_q1
integer i, j, k, cc, ifcst, iy, im, id, ih, d1, d2, dd, ibs


BS: DO ibs=1, nbs ! loop basins

    ! convert lat/lon to grid
    lon1=ngrd(wb(ibs),lon0,igrd)
    lon2=ngrd(eb(ibs),lon0,igrd)
    lat1=ngrd(sb(ibs),lat0,igrd)
    lat2=ngrd(nb(ibs),lat0,igrd)
    nlat2=lat2-lat1+1
    !print*,lon1,lon2,lat1,lat2,nlat2



FC: DO ifcst=1,nfcst

    ! initialize arrays
    var_sum(:,:)=0.0
    nn_sum(:,:)=0.

    write(lead,'(i3)')fcst(ifcst)
    if(fcst(ifcst)==0)then
        lead='000'
    else if(fcst(ifcst)<100)then
        lead(1:1)='0'
    endif
    !print*,lead

    ! set output files
    fileout='homedir/vnameinput.vs.vnamecwv_PDF.f'//lead//'.gdat'
    open(88,file=fileout,form='unformatted', access='direct', &
            recl=nz1*nbin,status='unknown',convert='little_endian')


YR: DO iy=y1,y2
    dd=0
    write(year,'(i4)')iy


    ! uncomment if using all days in a calendar year
    !if( ((mod(iy,4).eq.0.and.mod(iy,100).ne.0).or.mod(iy,400).eq.0)) then
    !    dall=366
    !else
    !    dall=365
    !endif

    if (shortnm0 .eq. 'Q1')then
        ! open Q1 file (normal binary)
        inpath_q1='homedir/Q1Q2/output/'
        filein_q1=trim(vnameinput)//'_'//year//'_f'//lead//'.gdat'
        !print*,filein_q1
        open(66,file=trim(inpath_q1)//trim(filein_q1),access='direct',&
                recl=nlon*nlat*nz1,form='unformatted',status='old',&
                convert='little_endian')
    endif


        MN:     DO im=m1,m2
            write(mon,'(i2)')im
            if(im<10) mon(1:1)='0'

            if (im==2) then
            if(((mod(iy,4).eq.0.and.mod(iy,100).ne.0).or.mod(iy,400).eq.0)) then
                d2=29
            else
                d2=28
            endif
            endif

            if (im==4 .or. im==6 .or. im==9 .or. im==11) then
                d2=30
            else if (im==1 .or. im==3 .or. im==5 .or. im==7 .or.&
                     im==8 .or.im==10 .or. im==12) then
                d2=31
            endif
            
            if (im.ne.m1)then
                d1=1
            else
                d1=(fcst(nfcst)-fcst(ifcst))/24.+1
            endif

            if (im.eq.m2) d2=d2-fcst(ifcst)/24.


            DY:        DO id=d1,d2
                write(day,'(i2)')id
                if(id<10) day(1:1)='0'

                HH:           DO ih=h1,h2,6
                    write(hour,'(i2)')ih
                    if(ih<10) hour(1:1)='0'

                filename='../../fv3retro/'//year//mon//day//'00/gfs.'&
                        //year//mon//day//'/00/gfs.t00z.pgrb2.1p00.f'//lead
                filein=filename
                !print*,filein,d1,d2,d2-d1+1
                ! shortnames are pwat and lsm for 
                ! precipitable water and land mask, respectively
                ! grib_dump filenmae for detailed info 
                if(shortnm.ne.'Q1')then
                    call grib_api_decode(filein,shortnm0,nlon,nlat,nz1,alev1,&
                            fcst(ifcst),var)
                endif
                call grib_api_decode(filein,shortnm1,nlon,nlat,nz2,alev2,&
                        fcst(ifcst),pw)

                if (dd==0)then
                    call grib_api_decode(filein,shortnm2,nlon,nlat,nz2,alev2,&
                            fcst(ifcst),ldmask)
                endif

                if(shortnm.eq.'Q1')then
                    ! read in Q1
                    read (66,rec=d1+dd) var
                endif
                dd=dd+1
                !print*,maxval(pw),minval(pw)
                !print*,maxval(ldmask),minval(ldmask)


                do k=1,nz1
                    do j=lat1,lat2
                    do i=lon1,lon2
                        if ( ldmask(i,j).le.1 &
                        .and. var(i,j,k) .ne. dmiss &
                        .and. pw(i,j) .ge. pwmin )then
                            cc=int((pw(i,j)-pwmin)/step)+1
                            if(cc>nbin)then
                                    !print*,pw(i,j)
                                    cc=nbin
                            endif
                            var_sum(k,cc)=var_sum(k,cc)+var(i,j,k)
                            nn_sum(k,cc)=nn_sum(k,cc)+1
                        endif

                    enddo
                    enddo
                enddo




                ENDDO HH
            ENDDO DY
        ENDDO MN


ENDDO YR

!print*,dd
!print*,tmax

!-------PDF normalization-----
!print*,nn_sum(1,:),nn_sum(2,:)
do k=1,nz1
    do cc=1,nbin
        var_str(k,cc)=var_sum(k,cc)/nn_sum(k,cc)
    enddo
enddo
print*,maxval(var_str),minval(var_str)

! output
write(88,rec=1) var_str

print*,'done',lead


ENDDO FC
ENDDO BS
END