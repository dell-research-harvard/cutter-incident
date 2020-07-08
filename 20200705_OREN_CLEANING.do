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
* Extract city name
replace city_and_titlenormal = subinstr(city_and_titlenormal, "['", "",.)
replace city_and_titlenormal = subinstr(city_and_titlenormal, "']", "",.)
* Add title_normal
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

*------- Clean na_papers_50_72 -------*
clear all
import delimited na_papers_50_72.csv, varnames(1) clear

*** generate a unique identifier 
g id_na = _n

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
