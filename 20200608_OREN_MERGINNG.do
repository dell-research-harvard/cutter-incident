clear all
cd "C:\Users\Oren_PC\Dropbox\BLISS\raw_data"

*--------- Part 1:  Cleaning the LOC & NA files for merging -------*
do 20200705_OREN_CLEANING.do
*----------Part 2:  Direct Merge ----------------*

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
keep city state title_normal id_na  original_na_paper original_na_city original_na_state
save unmatched_step_1.dta, replace

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
replace title_normal = title_normal_copy if dup > 0
drop dup 
sort city state title_normal
quietly by city state title_normal:  gen dup = cond(_N==1,0,_n)
replace title_normal = title_normal_copy if dup > 0
drop dup 

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
keep city state title_normal title_normal_copy id_na  original_na_paper original_na_city original_na_state
save unmatched_step_2.dta, replace

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
keep if _merge==1 | (_merge==3 & missing(alt_title))
*** delete duplicates that were created because of missing alt_title
sort id_na
quietly by id_na:  gen dup = cond(_N==1,0,_n)
drop if dup>1

keep city state title_normal_copy id_na  original_na_paper original_na_city original_na_state
save unmatched_step_3.dta, replace

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
keep city state alt_title id_na  original_na_paper original_na_city original_na_state
save unmatched_step_4.dta, replace

*----------Part 3: Fuzzy Merges---------*

*------------ Step 5 - Fuzzy merge on title_normal, required perfect match on city & state and min score of 0.99
clear all
use unmatched_step_4.dta, clear

gen id2 = _n
rename alt_title title_normal

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
*** delete duplicates that were created because of a wrong_match
sort id_na
quietly by id_na:  gen dup = cond(_N==1,0,_n)
drop if dup>1

keep state city title_normal id_na original_na_paper original_na_city original_na_state
save unmatched_step_5.dta, replace

*------------ Step 6 - Fuzzy merge on city_and_titlenormal, required perfect match on state and min score of 0.97
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
keep state city city_and_titlenormal id_na original_na_paper original_na_city original_na_state
save unmatched_step_6.dta, replace


*------------ Step 7 - Fuzzy merge on alt_title, required perfect match on state and min score of 0.99
clear all
use unmatched_step_6.dta, clear

gen id2 = _n
rename city_and_titlenormal alt_title 

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
keep state city alt_title id_na original_na_paper original_na_city original_na_state
save unmatched_step_7.dta, replace

*--------------- Part 4: Manual Merges---------*

// Here I exported unmatched_step_7 and checked manually. The file manual_crosswalk.csv has all the observations from unmatched_step_7 //

***----------8. Load manual-mergeing of unmatched obs-------------
clear all
* Load manual-merge checkings
import excel Fuzzy_merged_obs.xlsx, sheet("step_8") firstrow clear

keep id_na id school RA_notes 
merge 1:1 id_na using na_papers_cleaned.dta
keep if _merge==3
keep id_na id school RA_notes original_na_city original_na_state original_na_paper

merge m:1 id using ca_newspaper_data.dta

*** Save matched
preserve
keep if _merge==3
drop _merge school
* mark step 8
g step = 8
append using merged.dta
save merged.dta, replace
restore

*** Save unmatched in a seperate file
keep if _merge==1
keep id_na  school RA_notes original_na_city original_na_state
g merged = 0
save unmatched_final.dta, replace
 
*-------------  Part 5: Collapsing --------------*

*** Clean merged observations
use merged.dta, clear
g merged = 1
keep city state original_city original_state original_title_normal original_alt_title id_na id id_loc frequency note  original_na_paper  original_na_city original_na_state title_normal start_year end_year step county place_of_publication
format %24s state city title_normal 
sort id_na
save merged.dta , replace

*** Collapsing
sort id_na, stable
* loc_all_ids
by id_na : gen loc_all_ids = id[1]
by id_na : replace loc_all_ids = loc_all_ids[_n-1] + ", " + id if _n > 1
by id_na : replace loc_all_ids = loc_all_ids[_N]
* loc_all_states
by id_na : gen loc_all_states = original_state[1]
by id_na : replace loc_all_states = loc_all_states[_n-1] + ", " + original_state if _n > 1
by id_na : replace loc_all_states = loc_all_states[_N]
* loc_all_cities
by id_na : gen loc_all_cities = original_city[1]
by id_na : replace loc_all_cities = loc_all_cities[_n-1] + ", " + original_city if _n > 1
by id_na : replace loc_all_cities = loc_all_cities[_N]
* loc_all_counties
by id_na : gen loc_all_counties = county[1]
by id_na : replace loc_all_counties = loc_all_counties[_n-1] + ", " + county if _n > 1
by id_na : replace loc_all_counties = loc_all_counties[_N]
* loc_all_titles
by id_na : gen loc_all_titles = original_title_normal[1]
by id_na : replace loc_all_titles = loc_all_titles[_n-1] + ", " + original_title_normal if _n > 1
by id_na : replace loc_all_titles = loc_all_titles[_N]
* loc_all_start_years
tostring start_year end_year, replace
by id_na : gen loc_all_start_years = start_year[1]
by id_na : replace loc_all_start_years = loc_all_start_years[_n-1] + ", " + start_year if _n > 1
by id_na : replace loc_all_start_years = loc_all_start_years[_N]
* loc_all_end_years
by id_na : gen loc_all_end_years = end_year[1]
by id_na : replace loc_all_end_years = loc_all_end_years[_n-1] + ", " + end_year if _n > 1
by id_na : replace loc_all_end_years = loc_all_end_years[_N]

* Keep relevants
keep id_na original_na_paper loc_all_cities loc_all_counties loc_all_ids loc_all_states loc_all_end_years loc_all_start_years original_na_city original_na_state loc_all_titles
format %24s loc_all_cities loc_all_counties loc_all_ids loc_all_states 

* collapse
quietly by id_na:  gen dup = cond(_N==1,0,_n)
drop if dup>1

* create single_county_namee
split loc_all_counties, p("]")
split loc_all_counties1, p(",")
g single_county_namee = loc_all_counties11 + "]"
drop loc_all_counties1*
drop loc_all_counties2* loc_all_counties3* loc_all_counties4* loc_all_counties5* loc_all_counties6* loc_all_counties7* loc_all_counties8*

g merged=1

* append unmatched
append using unmatched_final.dta
distinct id_na
format %24s RA_notes
sort id_na

save collapsed_data.dta, replace



