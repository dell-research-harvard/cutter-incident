clear all
cd "C:\Users\Oren_PC\Dropbox\BLISS\raw_data"
*----------- 1. merge on title_normal -----------*
*-------- Prepare LOC data for merging -------*
import delimited ca_newspaper_data.csv, varnames(1) clear

*** Gen copies of city, state and title_normal
rename state original_state
g state = original_state
rename city original_city
g city = original_city
rename title_normal original_title_normal
g title_normal = original_title_normal

*** get rid of "- , ' /"
recast str300 city state title_normal 
replace title_normal = subinstr(title_normal, "-", " ",.)
replace title_normal = subinstr(title_normal, ",", "",.)
replace title_normal = subinstr(title_normal, "'", "",.)
replace title_normal = subinstr(title_normal, "/", "",.)

*** Get rid of duplicates in state names
split state, p("]")
split state1, p(",")
replace state = state11 + "]"
drop state1*
*** Get rid of duplicates in city names
split city, p("]")
split city1, p(",")
replace city = city11 + "]"
drop city1*
keep city state title_normal
save ca_newspaper_data.dta, replace

*-------- Clean na_papers_50_72 and merge -------*
clear all
import delimited na_papers_50_72.csv, varnames(1) clear
*** generate a unique identifier and keep 1118 - 2235
gen id = _n
keep if id > 1117 
drop id
*-------- Generate formatted variables -------*

*** Paper titles
g formatted_paper = paper
*** Remove dashes and dots 
replace formatted_paper = subinstr(formatted_paper, "-", " ",.)
*** Add a dot to match ca_newspaper_data
replace formatted_paper = formatted_paper + "."

*** State Names
g formatted_state = proper(state)
replace formatted_state = subinstr(formatted_state, "-", " ",.)

replace formatted_state = "['" + formatted_state + "']"

*** City Names
g formatted_city = proper(city)
*** Remove dashes and dots and add "['']"
replace formatted_city = subinstr(formatted_city, "-", " ",.)
replace formatted_city = "['" + formatted_city + "']"

*--------- Rename variables for merging --------*
rename state old_state
rename city old_city
rename paper old_paper
rename formatted_state state
rename formatted_city city
rename formatted_paper title_normal

*** merge by city, state and title
merge 1:m city state title_normal using ca_newspaper_data.dta

*** Save unmatched in a seperate file
keep if _merge==1
keep city state title_normal
save unmatched_by_titlenormal.dta, replace

*----------- 2. merge on alt_title -----------*

clear all
cd "C:\Users\Oren_PC\Dropbox\BLISS\raw_data"

*-------- Prepare LOC data for merging on alt_title-------*
import delimited ca_newspaper_data.csv, varnames(1) clear

*** Gen copies of city, state and alt_title
rename state original_state
g state = original_state
rename city original_city
g city = original_city

*** get rid of "- , ' /"
recast str600 city state alt_title
split alt_title, p(",")
replace alt_title = alt_title1 
replace alt_title = subinstr(alt_title, "-", " ",.)
replace alt_title = subinstr(alt_title, ",", "",.)
replace alt_title = subinstr(alt_title, "'", "",.)
replace alt_title = subinstr(alt_title, "[", "",.)
replace alt_title = subinstr(alt_title, "]", "",.)
replace alt_title = strtrim(alt_title)

replace alt_title = lower(alt_title)
*** Get rid of duplicates in state names
split state, p("]")
split state1, p(",")
replace state = state11 + "]"
drop state1*
*** Get rid of duplicates in city names
split city, p("]")
split city1, p(",")
replace city = city11 + "]"
drop city1*

save ca_newspaper_for_alt_title.dta, replace

*-------- Clean unmatched_by_titlenormal.dta and merge -------*
clear all
use unmatched_by_titlenormal.dta, clear
replace title_normal = subinstr(title_normal, ".", "",.)

rename title_normal alt_title

*** merge by city, state and title
merge 1:m city state alt_title using ca_newspaper_for_alt_title.dta

*** Save unmatched in a seperate file
keep if _merge==1
keep city state alt_title
save unmatched_by_alt&normal.dta, replace

*----------- 3. merge on alt_title without the first word which is usually a city name-----------*
clear all
use unmatched_by_alt&normal.dta, clear

split alt_title, p(" ")
replace alt_title = alt_title2
forvalues i = 3/10 {
replace alt_title = alt_title + " " + alt_title`i'
}
replace alt_title = strtrim(alt_title)

*-------- Add first word back to duplicates -------*

sort city state alt_title
quietly by city state alt_title:  gen dup = cond(_N==1,0,_n)
replace alt_title = alt_title + " " + alt_title if dup!=0
drop dup 
sort city state alt_title
quietly by city state alt_title:  gen dup = cond(_N==1,0,_n)
//////////// come back to this, should not delete
drop if dup!=0

*** merge by city, state and title
merge 1:m city state alt_title using ca_newspaper_for_alt_title.dta
