* Use Leander's Method/Code to collapse the data*

use "collapsed_final.dta", clear
gen merged = 1
keep state_na city_na state_loc city_loc paper title county lccn alt_title start_year end_year notes* place_of_publication diff number merged

* formatting of county variables
format title %50s
format county %50s

rename title loc_paper_title
gen  loc_paper_county = county
rename place_ loc_paper_place
rename county county_list 

replace loc_paper_county = subinstr(loc_paper_county, "[", "", .)
replace loc_paper_county = subinstr(loc_paper_county, "]", "", .)
replace loc_paper_county = subinstr(loc_paper_county, "'", "", .)

* there are many counties for one newspaper, take the most likely one
rename loc_paper_county county_temp
split county_temp, parse(",") gen(county_temp_ind)
rename county_temp_ind1 loc_paper_county
****************** SEOKMIN, HERE YOU SEE ALL COUNTIES ******************
drop county_temp_ind* county_temp
replace loc_paper_county = "" if loc_paper_county == "None"

* drop duplicates to get back to original data
duplicates drop number loc_paper_county, force

*group by number and see where you have more than one county per paper
duplicates tag number, gen(countyPlus)
bysort number: gen countyAdditional = _n

replace loc_paper_county = "Chickasaw" if number == 780
drop if countyAdditional == 2 
drop diff
save seokmin.dta, replace
*append the unmerged file
use "unmerged_Append_Final",clear
gen merged = 0
keep state_na city_na state_loc city_loc paper title county lccn alt_title start_year end_year notes* place_of_publication  number school_paper merged
append using seokmin.dta
drop countyAdditional countyPlus

save   seokmin_Final.dta, replace
