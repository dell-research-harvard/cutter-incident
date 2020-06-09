clear all
cd "C:\Users\Oren_PC\Dropbox\BLISS\raw_data"

*-------- Prepare LOC data for merging -------*
import delimited ca_newspaper_data.csv, varnames(1) clear
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

***Check which state has the most unmerged obs
keep if _merge==1
keep city state title_normal
tab state
compress
