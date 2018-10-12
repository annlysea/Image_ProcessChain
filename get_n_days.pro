; Convert data into yearly data

pro get_n_days,date1,date2,n_days

; Make sure that we have meters per year
year1 = fix(strmid(date1,0,4))
month1 = fix(strmid(date1,4,2))
day1 = fix(strmid(date1,6,2))
year2 = fix(strmid(date2,0,4))
month2 = fix(strmid(date2,4,2))
day2 = fix(strmid(date2,6,2))
n_days = julday(month2,day2,year2) - julday(month1,day1,year1)

end
