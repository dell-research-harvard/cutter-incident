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
use "/Users/seokminoh/Desktop/Dell/na_papers_50_72.dta", clear
gen state_proper = proper(state)
gen city_proper = proper(city)
replace city_proper = subinstr(city_proper, "-"," " , .)

//make it similar in format to the ca newspaper data
replace state_proper = "['" + state_proper + "']"
replace city_proper = "['" + city_proper + "']"

//try to apply a similar method for the paper variable
gen paper_proper = paper 
//get rid of all the hyphens
replace paper_proper = subinstr(paper_proper, "-"," " , .)
replace paper_proper =  paper_proper + "."

//check if the paper names are unique, which it is 
distinct paper_proper
gen number = _n
keep if number < 1118
save "/Users/seokminoh/Desktop/Dell/na_papers_50_72.dta_V2",replace

//create consistent variable names 
use "/Users/seokminoh/Desktop/Dell/ca_newspaper_data.dta", replace

gen paper_proper = title_normal
gen city_proper = city
gen state_proper = state

save "/Users/seokminoh/Desktop/Dell/ca_newspaper_data.dta_V2", replace

//merge the files and see where you have inconsistencies - 723 matched
use "/Users/seokminoh/Desktop/Dell/ca_newspaper_data.dta_V2", clear 
merge m:1 paper_proper city_proper state_proper using  "/Users/seokminoh/Desktop/Dell/na_papers_50_72.dta_V2"

//view the ones that did not merge
sort paper_proper city_proper state_proper
gen 
br paper_proper city_proper state_proper if _merge == 2 
