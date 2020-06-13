//06/08/2020
ssc install distinct
ssc install egenmore
//first import the master file 
/*
import delimited "/Users/seokminoh/Downloads/ca_newspaper_data.csv"
save  "/Users/seokminoh/Desktop/Dell/ca_newspaper_data.dta", replace

//import the using file 
import delimited "/Users/seokminoh/Desktop/Dell/na_papers_50_72.csv", varnames(1) encoding(ISO-8859-9) clear 
save "/Users/seokminoh/Desktop/Dell/na_papers_50_72.dta", replace
*/
//create a copy of the variable
use "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta", clear
gen state_proper = lower(state)
gen city_proper = lower(city)
//this gets rid of all the hyphens
replace city_proper = subinstr(city_proper, "-"," " , .)


//get rid of blank spaces for later merge
replace state_proper = subinstr(state_proper," ","",.)
replace city_proper = subinstr(city_proper," ","",.)

//try to apply a similar method for the paper variable
gen paper_proper = paper 
//get rid of all the hyphens
replace paper_proper = subinstr(paper_proper, "-","" , .)
replace paper_proper = subinstr(paper_proper," ","",.)
replace paper_proper = lower(paper_proper)

//check if the paper names are unique, which it is 
distinct paper_proper city_proper state_proper
gen number = _n
keep if number < 1118

//
save "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V1",replace

//convert the city and state variables such that only the first letters are capitalized
use "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta", clear
gen state_proper = lower(state)
gen city_proper = lower(city)
//this gets rid of all the hyphens
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
replace paper_proper = subinstr(paper_proper, "-","" , .)
replace paper_proper = subinstr(paper_proper," ","",.)
replace paper_proper = lower(paper_proper)

//check if the paper names are unique, which it is 
distinct paper_proper city_proper state_proper
gen number = _n
keep if number < 1118

//manually change two things because they are distinct but become same under the lower case and getting rid of - function
duplicates tag paper_proper state_proper city_proper, gen(dup)
//IMPORTANT I am renaming le-mars back to le-mars and then manually adding that later
replace paper_proper = "le-mars-semi-weekly-sentinel" if paper ==  "lemars-semi-weekly-sentinel"
replace paper_proper = "le-mars-sentinel" if paper == "le-mars-sentinel" 
replace paper_proper = "le-mars-globe-post" if paper =="le-mars-globe-post"
replace paper_proper = "le-mars-daily-sentinel" if paper == "le-mars-daily-sentinel"
//
save "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V2",replace

//create consistent variable names 
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta", replace

gen paper_proper = lower(title_normal)
gen city_proper = lower(city)
gen state_proper = lower(state)

save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V2", replace

//recognize that some of the states and cities variables have multiple cities and states, so we will seperate them out

use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V2", replace

//first just get rid of all the blank spaces because there are blank spaces between objects within the []
replace state_proper = subinstr(state_proper," ","",.)
replace city_proper = subinstr(city_proper," ","",.)

//then split the variables correspondingly 
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
rename paper_proper title_proper
replace title_proper = subinstr(title_proper," ","",.)
replace title_proper = subinstr(title_proper, "-","" , .)
replace title_proper = subinstr(title_proper, ".","" , .)

replace alt_title = subinstr(alt_title," ","",.)
replace alt_title = subinstr(alt_title, "-","" , .)
replace alt_title = "" if alt_title == "[]"

//start splitting the alternative titles 
split alt_title, p(",") g(paper_proper) 

forvalues i = 1/21{
replace paper_proper`i' = subinstr(paper_proper`i',"'","",.)
replace paper_proper`i' = subinstr(paper_proper`i',"[","",.)
replace paper_proper`i' = subinstr(paper_proper`i',"]","",.)
}

forvalues i = 1/21{
replace paper_proper`i' = lower(paper_proper`i')
}

local j
forvalues i = 21(-1)1{
local j = `i'+1
rename paper_proper`i' paper_proper`j'
}

rename title_proper paper_proper1
save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V4", replace

//create a unique identifier
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V4", replace
gen id2 = _n
save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V4", replace

//1-5
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V4", replace

rename state_proper state_p
rename city_proper city_p

forvalues i =6/22{
drop state_proper`i'
drop city_proper`i'
drop paper_proper`i'
}



//create a long file that is short enough (546 unmatched)
reshape long state_proper city_proper paper_proper, i(id2) j(instance)
save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_long_1_5", replace
use  "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_long_1_5", replace
merge m:1 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V2"
duplicates tag id2 paper_proper state_proper city_proper, gen(dup3)
drop if dup3 > 0
save "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5", replace

//keep only the 546 that did not match
use  "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5", replace
keep if _merge == 2 
rename _merge _mergeAppend1_5
save "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5", replace

//redo with this time nonempty state and city variables
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V4", replace

rename state_proper state_p
rename city_proper city_p

forvalues i =2/22{
replace state_proper`i' = state_proper1
replace city_proper`i' = city_proper1
}

//I noticed that there were barely any alternative names beyond 3 
forvalues i =6/22{
drop state_proper`i'
drop city_proper`i'
drop paper_proper`i'
}

reshape long state_proper city_proper paper_proper, i(id2) j(instance)
save "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_cs_same", replace
use  "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_cs_same", replace

merge m:1 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5"
drop if paper_proper == ""
keep if _merge == 2 | _merge == 3
//rerun this part
save "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_cs_same",replace
keep if _merge == 2 
rename _merge _merge1_5_cs_same
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_1_5_cs_same",replace

//now try with second city or state name 
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta_V4", replace

rename state_proper state_p
rename city_proper city_p

forvalues i =1/22{
replace state_proper`i' = state_proper2
replace city_proper`i' = city_proper2
}

//I noticed that there were barely any alternative names beyond 3 
forvalues i =4/22{
drop state_proper`i'
drop city_proper`i'
drop paper_proper`i'
}

reshape long state_proper city_proper paper_proper, i(id2) j(instance)
save "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_cs_same_2", replace
merge m:1 paper_proper city_proper state_proper using  "/Users/seokminoh/Desktop/Dell_2/To_Merge_1_5_cs_same"
drop if paper_proper == ""
keep if _merge == 2 | _merge == 3
save "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_cs_same2",replace
keep if _merge == 2 
rename _merge _merge1_5_cs_same2
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_1_5_cs_same2",replace

//use for merge later
use  "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_cs_same", replace

merge m:1 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5"
drop if paper_proper == ""
//keep if _merge == 1 
save "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_for_citydrop",replace
keep if _merge == 2 
save "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72_m2.dta", replace

//use same format 

use "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72_m2.dta", clear
drop _merge*
gen city_properx = lower(city)
//get rid of "-" even if we do the reclink for now 
replace city_properx = subinstr(city, "-","" , .)


gen cityinpaper = strpos(paper_proper,city_properx)

replace paper_proper = subinstr(paper_proper,city_properx, "", 1) if cityinpaper == 1

//check if the paper names are unique, which it is 
distinct paper_proper city_proper state_proper
duplicates tag paper_proper state_proper city_proper, gen(dup6)
replace paper_proper = city+paper_proper if dup6>0 & cityinpaper > 0

save "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V2_reclink_2_formerge_nocity",replace

use "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_for_citydrop",replace
drop _merge*
merge m:1 paper_proper city_proper state_proper using  "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V2_reclink_2_formerge_nocity"

save "/Users/seokminoh/Desktop/Dell_2/for_reclink", replace

//reclink time
use "/Users/seokminoh/Desktop/Dell_2/for_reclink", replace
keep if _merge == 1 
gen id3 = _n
save "/Users/seokminoh/Desktop/Dell_2/for_reclink2", replace
use "/Users/seokminoh/Desktop/Dell_2/for_reclink2", replace
drop _merge
egen S = sieve(paper_proper), keep(alphabetic space)
rename paper_proper S1
rename S paper_proper
drop if paper_proper ==""
replace state_proper = substr(state_proper, 3, .)
replace state_proper = subinstr(state_proper, "']", "",.) 

replace city_proper = substr(city_proper, 3, .)
replace city_proper = subinstr(city_proper, "']", "",.) 
save   "/Users/seokminoh/Desktop/Dell_2/for_reclink", replace
replace state_proper = subinstr(state_proper , "(", "", .)
replace state_proper = subinstr(state_proper , ")", "", .)
replace city_proper = subinstr(city_proper , "(", "", .)
replace city_proper = subinstr(city_proper , ")", "", .)
replace state_proper = subinstr(state_proper , "[", "", .)
replace state_proper = subinstr(state_proper , "]", "", .)
replace city_proper = subinstr(city_proper , "]", "", .)
replace city_proper = subinstr(city_proper , "]", "", .)
replace state_proper = subinstr(state_proper , "", "", .)
replace state_proper = subinstr(state_proper , "", "", .)
replace city_proper = subinstr(city_proper , """, "", .)
replace city_proper = subinstr(city_proper , """, "", .)
egen S = sieve(city_proper), keep(alphabetic space)
rename  city_proper S3
rename S city_proper
reclink paper_proper state_proper city_proper using /Users/seokminoh/Desktop/Dell_2/na_papers_50_72.dta_V1, idmaster(id3) idusing(number) gen(match) minscore(.99)
save "/Users/seokminoh/Desktop/Dell_2/reclink_V1",replace
