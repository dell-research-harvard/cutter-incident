//06/08/2020
ssc install distinct
//first import the master file 
/*
import delimited "/Users/seokminoh/Downloads/ca_newspaper_data.csv"
save  "/Users/seokminoh/Desktop/Dell/ca_newspaper_data.dta", replace

//import the using file 
import delimited "/Users/seokminoh/Desktop/Dell/na_papers_50_72.csv", varnames(1) encoding(ISO-8859-9) clear 
save "/Users/seokminoh/Desktop/Dell/na_papers_50_72.dta", replace
*/
//create a copy of the variable
//convert the city and state variables such that only the first letters are capitalized
use "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta", clear
gen state_proper = proper(state)
gen city_proper = proper(city)
replace city_proper = subinstr(city_proper, "-"," " , .)

//make it similar in format to the ca newspaper data
replace state_proper = "['" + state_proper + "']"
replace city_proper = "['" + city_proper + "']"

//get rid of blank spaces for later merge
replace state_proper = subinstr(state_proper," ","",.)
replace city_proper = subinstr(city_proper," ","",.)

//try to apply a similar method for the paper variable
gen paper_proper = paper 
//get rid of all the hyphens
replace paper_proper = subinstr(paper_proper, "-"," " , .)
replace paper_proper =  paper_proper + "."

//check if the paper names are unique, which it is 
distinct paper_proper
gen number = _n
keep if number < 1118
save "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V2",replace

//create consistent variable names 
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta", replace

gen paper_proper = title_normal
gen city_proper = city
gen state_proper = state

save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V2", replace

//recognize that some of the states and cities variables have multiple cities and states, so we will seperate them out

use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V2", replace

//first just get rid of all the blank spaces because there are blank spaces between objects within the []
replace state_proper = subinstr(state_proper," ","",.)
replace city_proper = subinstr(city_proper," ","",.)

replace state_proper = subinstr(state_proper," ","",.)
replace city_proper = subinstr(city_proper," ","",.)

split state_proper, p(",") g(state_proper) 
split city_proper, p(",") g(city_proper) 
replace state_proper1 =  state_proper1 + "]" if missing(state_proper2) ==0
replace city_proper1 =  city_proper1 + "]" if missing(state_proper2) ==0

//make the format consistent
forvalues i = 2/22 { 
replace state_proper`i' =  "[" + state_proper`i'  if missing(state_proper`i') == 0 & strpos(state_proper`i' ,"]") != 0
replace city_proper`i' =  "[" + city_proper`i' if missing(city_proper`i' ) == 0 & strpos(city_proper`i' ,"]") != 0

replace state_proper`i' =  "[" + state_proper`i'+  "]" if missing(state_proper`i') == 0 & strpos(state_proper`i' ,"]") == 0
replace city_proper`i' =  "[" + city_proper`i' + "]" if missing(city_proper`i' ) == 0 & strpos(city_proper`i' ,"]") == 0

}
save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V3", replace
 
//now you want to drop the duplicate ones. Use an efficient way of making reshape run faster.

// this part needs more work 
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V3", replace
set more off

//rename state_proper state_p
//rename  city_proper city_p 

rename state_proper state_proper2
rename city_proper city_proper1
gen id2 = _n

forvalues i =10/22{
drop state_proper`i'
drop city_proper`i'
}
//create a long file that is short enough (709 unmatched)
reshape long state_proper city_proper, i(id2) j(instance)
save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_long_1_9", replace
merge m:1 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V2"

save "/Users/seokminoh/Desktop/Dell_2/Merged_reshaped_1_10",replace
keep if _merge == 3 
save "/Users/seokminoh/Desktop/Dell_2/Merged_reshaped_1_10_for_append"

//Now specifically look at the ones that still did not match
use "/Users/seokminoh/Desktop/Dell_2/Merged_reshaped_1_10",replace
rename  
