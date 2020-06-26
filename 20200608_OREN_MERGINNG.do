clear all
cd "C:\Users\Oren_PC\Dropbox\BLISS\raw_data"

*-------- Part 1:  Cleaning the LOC & NA files for merging -------*
import delimited ca_newspaper_data.csv, varnames(1) clear

*** Gen copies of city, state and title_normal
rename state original_state
g state = original_state
rename city original_city
g city = strproper(original_city)
rename title_normal original_title_normal
g title_normal = original_title_normal
rename alt_title original_alt_title
g alt_title = original_alt_title

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
* replace missing to empty strings
replace city="" if city == "[]"

*** Clean title_normal
replace title_normal = subinstr(title_normal, "-", " ",.)
replace title_normal = subinstr(title_normal, ",", "",.)
replace title_normal = subinstr(title_normal, "'", "",.)
replace title_normal = subinstr(title_normal, "/", "",.)
replace title_normal = subinstr(title_normal, ".", "",.)

*** Get the first alternative title 
split alt_title, p(",")
replace alt_title = alt_title1 
drop alt_title1*
* clean
replace alt_title = subinstr(alt_title, "-", " ",.)
replace alt_title = subinstr(alt_title, ",", "",.)
replace alt_title = subinstr(alt_title, "'", "",.)
replace alt_title = subinstr(alt_title, "[", "",.)
replace alt_title = subinstr(alt_title, "]", "",.)
replace alt_title = strtrim(alt_title)
replace alt_title = lower(alt_title)

*** Gen city+title_normal for fuzzy merging 
g city_and_titlenormal = city
<<<<<<< HEAD

replace city_and_titlenormal = subinstr(city_and_titlenormal, "['", "",.)
replace city_and_titlenormal = subinstr(city_and_titlenormal, "']", "",.)
=======
* Extract city name
replace city_and_titlenormal = subinstr(city_and_titlenormal, "['", "",.)
replace city_and_titlenormal = subinstr(city_and_titlenormal, "']", "",.)
* Add title_normal
>>>>>>> Oren's_first_branch
replace city_and_titlenormal = city_and_titlenormal + " " + title_normal

*** Gen city+alt_title for fuzzy merging 
g city_and_alttitle = city
replace city_and_alttitle = subinstr(city_and_alttitle, "['", "",.)
replace city_and_alttitle = subinstr(city_and_alttitle, "']", "",.)
replace city_and_alttitle = city_and_alttitle + " " + alt_title

*** Gen id for fuzzy merging
gen id_loc = _n

*** Recast to enable later merging
recast str300 title_normal alt_title
format %24s state city title_normal alt_title city_and_alttitle city_and_titlenormal
save ca_newspaper_data.dta, replace

<<<<<<< HEAD

*----------- 1. merge on title_normal -----------*

=======
*------- Clean na_papers_50_72 -------*
>>>>>>> Oren's_first_branch
clear all
import delimited na_papers_50_72.csv, varnames(1) clear

*** generate a unique identifier 
g id_na = _n
<<<<<<< HEAD
*** keep 1118 - 2235 obs.
keep if id_na > 1117 
=======
>>>>>>> Oren's_first_branch

*** Generate formatted variables

*** Papers' titles
g formatted_paper = paper
replace formatted_paper = subinstr(formatted_paper, "-", " ",.)

*** State Names
g formatted_state = proper(state)
replace formatted_state = subinstr(formatted_state, "-", " ",.)
* Add [''] to match ca_newspaper_data
replace formatted_state = "['" + formatted_state + "']"

*** City Names
g formatted_city = proper(city)
replace formatted_city = subinstr(formatted_city, "-", " ",.)
replace formatted_city = "['" + formatted_city + "']"

*** Rename variables for merging
rename state original_na_state
rename city original_na_city
rename paper original_na_paper
rename formatted_state state
rename formatted_city city
rename formatted_paper title_normal

save na_papers_cleaned.dta, replace

*-------------------Part 2:  Direct Merge ----------------*

*----------- Step 1 - merge on title_normal -----------*
use na_papers_cleaned.dta, clear
*** keep 1118 - 2235 obs.
keep if id_na > 1117 

*** merge by city, state and title_normal
merge 1:m city state title_normal using ca_newspaper_data.dta

*** Save matched
preserve
keep if _merge==3
drop _merge
* mark that this merge belongs to step 1
g step = 1
save merged.dta, replace
restore
*** Save unmatched in a seperate file
keep if _merge==1
<<<<<<< HEAD
keep city state title_normal id_na
=======
keep city state title_normal id_na  original_na_paper
<<<<<<< HEAD
>>>>>>> Oren's_first_branch
save unmatched_by_titlenormal.dta, replace
=======
save unmatched_step_1.dta, replace
>>>>>>> Oren's_first_branch

*------------ Step 2 - Merge on title_normal without first word in na_papers_50_72 -----------*

clear all
use unmatched_step_1.dta, clear

*** Creat a copy of title_normal for step 4
g title_normal_copy = title_normal

*** Get rid of first word
split title_normal, p(" ")
replace title_normal = title_normal2
forvalues i = 3/10 {
replace title_normal = title_normal + " " + title_normal`i'
}

* Get rid of white spaces
replace title_normal = strtrim(title_normal)

*** Add first word back to duplicates
sort city state title_normal
quietly by city state title_normal:  gen dup = cond(_N==1,0,_n)
replace title_normal = title_normal1 + " " + title_normal if dup!=0
drop dup 
sort city state title_normal
quietly by city state title_normal:  gen dup = cond(_N==1,0,_n)
///////////////////////// come back to this, should not delete //////////////////////
drop if dup!=0

*** merge by city, state and title
merge 1:m city state title_normal using ca_newspaper_data.dta

*** Save matched
preserve
keep if _merge==3
drop _merge
* mark step 2
g step = 2
append using merged.dta
save merged.dta, replace
restore
*** Save unmatched in the seperate file
keep if _merge==1
<<<<<<< HEAD
keep city state title_normal title_normal_copy id_na
=======
keep city state title_normal title_normal_copy id_na  original_na_paper
<<<<<<< HEAD
>>>>>>> Oren's_first_branch
save unmatched_by_titlenormal.dta, replace
=======
save unmatched_step_2.dta, replace
>>>>>>> Oren's_first_branch

*----------- Step 3 - merge on alt_title without the first word which is usually a city name-----------*

clear all
use unmatched_step_2.dta, clear

** Rename for merging
rename title_normal alt_title

*** merge by city, state and title
merge 1:m city state alt_title using ca_newspaper_data.dta

*** Save matched
preserve
keep if _merge==3 & ! missing(alt_title)
drop _merge
* mark step 3
g step = 3
append using merged.dta
save merged.dta, replace
restore

*** Save unmatched in a seperate file
keep if _merge==1
<<<<<<< HEAD
keep city state title_normal_copy id_na
=======
keep city state title_normal_copy id_na  original_na_paper
<<<<<<< HEAD
>>>>>>> Oren's_first_branch
save unmatched_by_alt&normal.dta, replace
=======
save unmatched_step_3.dta, replace
>>>>>>> Oren's_first_branch

*----------- Step 4 - merge on alt_title -----------*
clear all
use unmatched_step_3.dta, clear

** Rename full title for merging
rename  title_normal_copy alt_title

*** merge by city, state and title
merge 1:m city state alt_title using ca_newspaper_data.dta

*** Save matched 
preserve
keep if _merge==3
drop _merge
* mark step 4
g step = 4
append using merged.dta
save merged.dta, replace
restore
*** Save unmatched in a seperate file
keep if _merge==1
<<<<<<< HEAD
keep city state alt_title id_na
=======
keep city state alt_title id_na  original_na_paper
<<<<<<< HEAD
>>>>>>> Oren's_first_branch
save unmatched_by_alt&normal.dta, replace
=======
save unmatched_step_4.dta, replace
>>>>>>> Oren's_first_branch

*----------Part 3: Fuzzy Merges---------*

*------------ Step 5 - Fuzzy merge on title_normal, required perfect match on city & state and min score of 0.99
clear all
use unmatched_step_4.dta, clear

gen id2 = _n
rename alt_title title_normal
<<<<<<< HEAD
replace title_normal = title_normal + "."
=======

>>>>>>> Oren's_first_branch
reclink city state title_normal using ca_newspaper_data.dta , idmaster(id2) idusing(id_loc) gen(matching) required(city state)  minscore(.99)
format %24s state city title_normal 
sort id2 matching
* Load manual-merge checkings
preserve
clear
import excel Fuzzy_merged_obs.xlsx, sheet("step_5") firstrow clear
keep id_na
save wrong_matches.dta, replace
restore
* Unmatch wrong matches
drop _merge
merge m:1 id_na using wrong_matches.dta
<<<<<<< HEAD
* Keep unmatched and wrong matches
keep if matching==. | _merge == 3
keep state city title_normal id_na
save unmatched_first_fuzzy.dta, replace

*------------ 6. Fuzzy merge on city_and_titlenormal, required perfect match on state and min score of 0.97
=======

*** Save matched
preserve
*drop wrong matches
drop if _merge==3
drop _merge
keep if ! missing(matching)
* mark step 5
g step = 5
append using merged.dta
save merged.dta, replace
restore
* Keep unmatched and wrong matches
keep if matching==. | _merge == 3
keep state city title_normal id_na original_na_paper
save unmatched_step_5.dta, replace

*------------ Step 6 - Fuzzy merge on city_and_titlenormal, required perfect match on state and min score of 0.97
>>>>>>> Oren's_first_branch
clear all
use unmatched_step_5.dta, clear

gen id2 = _n
rename title_normal city_and_titlenormal
reclink state city_and_titlenormal using ca_newspaper_data.dta , idmaster(id2) idusing(id_loc) gen(matching) required(state)  minscore(.97)
format %24s state city city_and_titlenormal 
sort id2 matching
* Load manual-merge checkings
preserve
clear
import excel Fuzzy_merged_obs.xlsx, sheet("step_6") firstrow clear
keep id_na
save wrong_matches.dta, replace
restore
* Unmatch wrong matches
drop _merge
merge m:1 id_na using wrong_matches.dta
<<<<<<< HEAD
* Keep unmatched and wrong matches
keep if matching==. | _merge == 3
keep state city city_and_titlenormal id_na
save unmatched_second_fuzzy.dta, replace


*------------ 7. Fuzzy merge on alt_title, required perfect match on state and min score of 0.99
=======

*** Save matched
preserve
*drop wrong matches
drop if _merge==3
drop _merge
keep if ! missing(matching)
* mark step 6
g step = 6
append using merged.dta
save merged.dta, replace
restore
* Keep unmatched and wrong matches
keep if matching==. | _merge == 3
keep state city city_and_titlenormal id_na original_na_paper
save unmatched_step_6.dta, replace


*------------ Step 7 - Fuzzy merge on alt_title, required perfect match on state and min score of 0.99
>>>>>>> Oren's_first_branch
clear all
use unmatched_step_6.dta, clear

gen id2 = _n
rename city_and_titlenormal alt_title 
<<<<<<< HEAD
** Remove dots since alt_title in ca_newspaper doesn't have dots
replace alt_title = subinstr(alt_title, ".", "",.)
=======
>>>>>>> Oren's_first_branch

reclink city state alt_title using ca_newspaper_data.dta , idmaster(id2) idusing(id_loc) gen(matching) required(state)  minscore(.99)
format %24s state city alt_title 
sort id2 matching
* Load manual-merge checkings
preserve
clear
import excel Fuzzy_merged_obs.xlsx, sheet("step_7") firstrow clear
keep id_na
save wrong_matches.dta, replace
restore
* Unmatch wrong matches
drop _merge
merge m:1 id_na using wrong_matches.dta
<<<<<<< HEAD
* Keep unmatched and wrong matches
keep if matching==. | _merge == 3
keep state city alt_title id_na
save unmatched_third_fuzzy.dta, replace

egen x = group(id_na)
sum x 


//end of cleaned do.file
*------------ 8. droped since resulted in 1 match ------Fuzzy merge on city_and_alt_title, required perfect match on city & state and min score of 0.985
clear all
use unmatched_third_fuzzy.dta, clear
=======

*** Save matched
preserve
*drop wrong matches
drop if _merge==3
drop _merge
keep if ! missing(matching)
* mark step 7
g step = 7
append using merged.dta
save merged.dta, replace
restore

* Keep unmatched and wrong matches
keep if matching==. | _merge == 3
keep state city alt_title id_na original_na_paper
save unmatched_step_7.dta, replace

*--------------- Part 4: Manual Merges---------*

// Here I exported unmatched_step_7 and checked manually. The file manual_crosswalk.csv has all the observations from unmatched_step_7 //

***----------8. Load manual-mergeing of unmatched obs-------------
clear all
* Load manual-merge checkings
import delimited manual_crosswalk.csv, encoding(UTF-8) clear
keep id_na sn title_na school notes
save manual_crosswalk.dta, replace
use manual_crosswalk.dta, clear
rename sn id
merge m:1 id using ca_newspaper_data.dta

*** Save matched
preserve
keep if _merge==3
drop _merge
* mark step 8
g step = 8
rename title_na original_na_paper
append using merged.dta
save merged.dta, replace
restore

*** Save unmatched in a seperate file
keep if _merge==1
keep city state id_na title_na school notes
save unmatched_final.dta, replace
 

>>>>>>> Oren's_first_branch

<<<<<<< HEAD
gen id2 = _n
rename alt_title city_and_alttitle 
** Remove dots since alt_title in ca_newspaper doesn't have dots
replace city_and_alttitle = subinstr(city_and_alttitle, ".", "",.)

<<<<<<< HEAD
reclink state city_and_alttitle using ca_newspaper_data.dta , idmaster(id2) idusing(id_loc) gen(matching) required(state)  minscore(.985)
format %24s state city city_and_alttitle 
* Keep unmatched
keep if matching==.
keep state city city_and_alttitle id_na
save unmatched_forth_fuzzy.dta, replace

*-----------
egen x = group(id_na)
sum x 
=======

>>>>>>> Oren's_first_branch

// draft ------ trying fuzzy on city_and_titlenormal directly after step 1
clear all
use unmatched_by_titlenormal.dta, clear
rename title_normal city_and_titlenormal

gen id2 = _n
reclink city state city_and_titlenormal using ca_newspaper_data.dta , idmaster(id2) idusing(id_loc) gen(matching) required(city state)  minscore(.99)
format %24s state city title_normal 
sort id2 matching
=======
*--------------------clean merged --------------
*** regular merge
use merged.dta, clear
keep city state original_city original_state original_title_normal original_alt_title id_na id id_loc frequency note  original_na_paper title_normal start_year end_year step
format %24s state city title_normal 
sort id_na
quietly by id_na:  gen dup = cond(_N==1,0,_n)
save merged.dta , replace


>>>>>>> Oren's_first_branch
