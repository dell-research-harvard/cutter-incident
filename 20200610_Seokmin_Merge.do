//06/16/20
ssc install distinct
ssc install egenmore

**** STEP 1: IMPORTT THE FILES  ****
 
/*
import delimited "/Users/seokminoh/Downloads/ca_newspaper_data.csv"
save  "/Users/seokminoh/Desktop/Dell/ca_newspaper_data.dta", replace

//import the using file 
import delimited "/Users/seokminoh/Desktop/Dell/na_papers_50_72.csv", varnames(1) encoding(ISO-8859-9) clear 
save "/Users/seokminoh/Desktop/Dell/na_papers_50_72.dta", replace
*/
//create a copy of the variable

*** STEP 2: FORMAT THE SMALLER FILE ***

//convert the city and state variables to lower case
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

//apply a similar method for the paper variable
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
save  "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72_Final.dta",replace

*** STEP 3: FORMAT THE BIGGER FILE ***
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data.dta", replace

gen paper_proper = lower(title_normal)
gen city_proper = lower(city)
gen state_proper = lower(state)

save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final.dta", replace

//recognize that some of the states and cities variables have multiple cities and states, so we will seperate them out

use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final.dta", replace

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
save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final_V2.dta", replace
 
// now apply a similar process for alternative titles
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final_V2.dta", replace
set more off

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

//create a unique identifier
gen id2 = _n

save "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final_V2.dta", replace

*** STEP 4: RESHAPE THE DATA SUCH THAT YOU ACCOUNT FOR 3 ALTERNATIVE TITLES, CITIES, AND STATES ***

****
use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final_V2.dta", replace

rename state_proper state_p
rename city_proper city_p


forvalues i =6/22{
drop state_proper`i'
drop city_proper`i'
drop paper_proper`i'
}


//create a long file that is short enough 
reshape long state_proper city_proper paper_proper, i(id2) j(instance)
duplicates tag id2 paper_proper state_proper city_proper, gen(dup4)

//no need if the necessary variables are empty so drop them
drop if paper_proper == "" & city_proper == "" & state_proper == ""
save "/Users/seokminoh/Desktop/Dell_2/ca_long_1_5_Final.dta", replace

*** STEP 5: FIRST MERGE - merge where each alternative title has a different state ***

use  "/Users/seokminoh/Desktop/Dell_2/ca_long_1_5_Final.dta", replace
merge m:1 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72_Final.dta"
//duplicates tag id2 paper_proper state_proper city_proper, gen(dup5)
//drop if dup5 > 0
rename _merge _mergeAppend1_5
save "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_Final.dta", replace

//keep only the 546 that did not match
use  "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_Final.dta", replace
keep if _merge == 2 
save "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_Final.dta", replace

*** STEP 6: SECOND MERGE - merge where each alternative title has the same state name ***

use "/Users/seokminoh/Desktop/Dell_2/ca_newspaper_data_Final_V2.dta", replace

rename state_proper state_p
rename city_proper city_p

forvalues i =2/22{
replace state_proper`i' = state_proper1 
replace city_proper`i' = city_proper1 
}

//I noticed that there were barely any alternative names beyond 5
forvalues i =6/22{
drop state_proper`i'
drop city_proper`i'
drop paper_proper`i'
}

reshape long state_proper city_proper paper_proper, i(id2) j(instance)
//drop the repetitive variables that do not have a paper name assocaited with them
drop if paper_proper == "" 
save "/Users/seokminoh/Desktop/Dell_2/Merge_1_5_cs_same_Final", replace


use  "/Users/seokminoh/Desktop/Dell_2/Merge_1_5_cs_same_Final", replace

merge m:1 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/Merge_2_Append_1_5_Final"

//this now results in 500 mismatches
save "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_cs_same_Final",replace
//duplicates tag id2 paper_proper state_proper city_proper, gen(dup6)
//drop if dup6 > 0
//save "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_cs_same_Final",replace
keep if _merge == 2 
rename _merge _merge1_3_cs_same
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_1_5_cs_same_Final",replace

use "/Users/seokminoh/Desktop/Dell_2/To_Append_1_5_cs_same_Final",replace
drop if _merge == 2 
rename _merge _merge1_3_cs_same
save "/Users/seokminoh/Desktop/Dell_2/master_1_5_cs_same_Final",replace


*** STEP 7: SECOND MERGE - merge where each alternative title has the same state name and using data does not have the city name attached to it in the front ***

//get rid of city names in front of the paper
use "/Users/seokminoh/Desktop/Dell_2/To_Merge_1_5_cs_same_Final",replace

gen city_properx = lower(city)
replace city_properx = subinstr(city, "-","" , .)
gen cityinpaper = strpos(paper_proper,city_properx)

replace paper_proper = subinstr(paper_proper,city_properx, "", 1) if cityinpaper == 1
duplicates tag paper_proper state_proper city_proper, gen(dupcity)

replace paper_proper = city+paper_proper if dupcity>0 & cityinpaper > 0

save "/Users/seokminoh/Desktop/Dell_2/Merge_nocity",replace

//the result is now 329 mismatches. 
use "/Users/seokminoh/Desktop/Dell_2/master_1_5_cs_same_Final",replace
merge m:1 paper_proper city_proper state_proper using  "/Users/seokminoh/Desktop/Dell_2/Merge_nocity"
save  "/Users/seokminoh/Desktop/Dell_2/ToAppend_nocity", replace
drop if _merge == 2 
rename _merge _unmatchedBeforeReclink

//this is the new masterfile that I will be using to merge onto 
save  "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink", replace

//new using file is needed for the mismatches
use  "/Users/seokminoh/Desktop/Dell_2/ToAppend_nocity", replace
keep if _merge == 2 
save  "/Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink", replace



*** STEP 8: RECLINK - fuzzy merge using the titles we are given with the cityout name in front and requiring state and city to match***

//get the using data ready 
use "/Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink", clear
rename city city_using
rename state state_using
replace paper_proper = city_using + paper_proper if cityinpaper > 0
rename _merge _unmatchedBeforeReclink

//make format consistent
//replace state_proper = substr(state_proper, 3, .)
replace state_proper = subinstr(state_proper , "(", "", .)
replace state_proper = subinstr(state_proper , ")", "", .)
replace state_proper = subinstr(state_proper , "[", "", .)
replace state_proper = subinstr(state_proper , "]", "", .)
replace state_proper = subinstr(state_proper , "'", "", .)

//replace city_proper = substr(city_proper, 3, .)
replace city_proper = subinstr(city_proper , "(", "", .)
replace city_proper = subinstr(city_proper , ")", "", .)
replace city_proper = subinstr(city_proper , "[", "", .)
replace city_proper = subinstr(city_proper , "]", "", .)
replace city_proper = subinstr(city_proper , "'", "", .)

keep city_proper state_proper paper_proper
save "/Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink2", replace

//reformat the master file such that it is compatible for reclink
use "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink", replace
gen id3 = _n
drop if paper_proper == ""

//get rid of () and [] in you variables or else reclink does not work
//replace state_proper = substr(state_proper, 3, .)
replace state_proper = subinstr(state_proper , "(", "", .)
replace state_proper = subinstr(state_proper , ")", "", .)
replace state_proper = subinstr(state_proper , "'", "", .)
replace state_proper = subinstr(state_proper , "[", "", .)
replace state_proper = subinstr(state_proper , "]", "", .)
replace state_proper = strtrim(state_proper)

//replace city_proper = substr(city_proper, 3, .)
replace city_proper = subinstr(city_proper , "(", "", .)
replace city_proper = subinstr(city_proper , ")", "", .)
replace city_proper = subinstr(city_proper , "'", "", .)
replace city_proper = subinstr(city_proper , "[", "", .)
replace city_proper = subinstr(city_proper , "]", "", .)
replace city_proper = strtrim(city_proper)

replace paper_proper = subinstr(paper_proper , "(", "", .)
replace paper_proper = subinstr(paper_proper , ")", "", .)
replace paper_proper = subinstr(paper_proper , "[", "", .)
replace paper_proper = subinstr(paper_proper , "]", "", .)
replace paper_proper = subinstr(paper_proper , "'", "", .)
replace paper_proper = strtrim(paper_proper)

replace paper_proper = subinstr(paper_proper , char(34), "", .)


save "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", replace
replace state_proper = subinstr(state_proper , "[", "", .)
replace state_proper = subinstr(state_proper , "]", "", .)
save "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", replace


use "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", clear

use /Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink, clear
gen number = _n
save /Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink, replace

use "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", clear

use /Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink, clear
//you now have around 100 less mismatches - need checking 
reclink paper_proper state_proper city_proper  using "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", idmaster(number) idusing(id3) gen(match_score)  _merge(_merge) minscore(.99)
save "/Users/seokminoh/Desktop/Dell_2/reclink_Leander", replace

//this was with minscore of .6 only one did not match
save "/Users/seokminoh/Desktop/Dell_2/reclink_Initial", replace


save "/Users/seokminoh/Desktop/Dell_2/reclink_withOren", replace


use "/Users/seokminoh/Desktop/Dell_2/Reclink_Merged_Step8", replace
keep if paper == ""
rename _merge _mergeReclinkInitial
save "/Users/seokminoh/Desktop/Dell_2/Reclink_unmatched_Step8", replace

//get rid of the 39 unique ones that did match
//also, this was checked manually and it seems that these are fine. 
use "/Users/seokminoh/Desktop/Dell_2/Reclink_Merged_Step8", replace
duplicates tag  number, gen(duprec1)
keep if paper != "" & duprec1 >0 & _unmatchedBeforeReclink != 3
remame _merge _mergeReclinkInitial
save "/Users/seokminoh/Desktop/Dell_2/Reclink_Step8_Merged_unique", replace


*** STEP 9: Manual Coding - I will now manually seek to figure out which ones in na file corresponds with the ones in ca file ***

//since I was unable to get a matching score (for some reason?) and the above code does not tell me what was in the using data, I will manuallly have to merge again with the previous data
use "/Users/seokminoh/Desktop/Dell_2/Reclink_unmatched_Step8", replace
merge 1:1 id3 paper_proper city_proper state_proper using "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2"

//now sort them by paper_proper state_proper city_proper 

