//06/16/20
cd /Users/seokminoh/Desktop/Dell_2/
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



*** STEP 8: RECLINK - fuzzy merge using the titles we are given without the city name in front and requiring state and city to match***

//get the using data ready 
use "/Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink", clear
//rename city city_using
//rename state state_using
//replace paper_proper = paper_proper if cityinpaper > 0
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

keep city_proper state_proper paper_proper number cityinpaper
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
rename cityinpaper cityinpaperMaster
save "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", replace

use /Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink2, clear
//you now have around 125 additional matches (check _merge = 3)  
reclink paper_proper state_proper city_proper  using "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", idmaster(number) idusing(id3) gen(match_score)  _merge(_merge_Reclink) minscore(.99)
save "/Users/seokminoh/Desktop/Dell_2/reclink_Leander2", replace

*** 8.1 manually check and analyze the matches to see if they were legitimate.
*** NOTE: Suppose I saw a repetition of either ca or na files, I only included the ones that were identitical as matched. If not, I left them as unmatched for now and will change them later. 
use "/Users/seokminoh/Desktop/Dell_2/reclink_Leander2", replace
keep if _merge_Reclink == 3 

gen unmatched = 0

//create a crosswalk now. The way you do this is going to be by inspecting by looking at the names of the paper, city, and state, and seeing if they are reasonable. 
//check the "notes" variable
keep lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title city state unmatched

//this file was later renamed as Reclink_V1
export excel using "Reclink_Leander.xlsx", firstrow(variables) replace 

//create a file of the unmatched observations 
import excel "/Users/seokminoh/Desktop/Dell_2/Reclink_V1.xlsx", sheet("Sheet1") firstrow clear
save Reclink_V1_Initial, replace

//get rid of duplicates
use Reclink_V1_Initial, clear
duplicates tag  lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title city state unmatched, gen(dup_rec_initial)

bysort lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title city state unmatched: gen dup_rec_initial2 = _n
//since they are duplicates by literally every single variable, it should be fine to drop 
drop if dup_rec_initial2 > 1


save "/Users/seokminoh/Desktop/Dell_2/Reclink_V1_Initial", replace

use "/Users/seokminoh/Desktop/Dell_2/reclink_Leander2", replace
merge m:1 lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper   using Reclink_V1_Initial
save "/Users/seokminoh/Desktop/Dell_2/Reclink_Initial_Merged", replace
drop if unmatched == 0
//File of unmatched
//also refer to excel sheet for notes and have it all somewhere.
bysort number: gen dup_reclinkMergeInitial = _n
drop if dup_reclinkMergeInitial> 1
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_Initial", replace

//File to Append
use "/Users/seokminoh/Desktop/Dell_2/Reclink_Initial_Merged", replace
keep if unmatched == 0
save "/Users/seokminoh/Desktop/Dell_2/To_Append_Reclink_Initial_Merged", replace

*** STEP 9 - Reclink Part 2. Here I will add the city name in front of the smaller file if the city name for those that were never in the front. Then, I will fuzzy merge. If they look reasonably the same, I consider them to be same. 

//first get the small file ready 
use "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_Initial", replace
rename _merge mergeReclinkInitial
drop cityinpaper
merge 1:1 number using "/Users/seokminoh/Desktop/Dell_2/Merge_nocity_for_reclink2"
keep if _merge == 3
keep city_proper state_proper paper_proper cityinpaper notes* number
replace paper_proper = city_proper + paper_proper if cityinpaper == 0
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_with_cityname", replace

//now merge
use  "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_with_cityname", replace
reclink paper_proper state_proper city_proper  using "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", idmaster(number) idusing(id3) gen(match_score)  _merge(_merge_Reclink_cityname) minscore(.99)

save "/Users/seokminoh/Desktop/Dell_2/Merged_Reclink_with_cityname", replace
gen unmatched = 0
keep if _merge_Reclink_cityname == 3


//create a crosswalk now. The way you do this is going to be by inspecting by looking at the names of the paper, city, and state, and seeing if they are reasonable. 
//check the "notes" variable
keep lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title  cityinpaper unmatched

//this file was later renamed as Reclink_V1
export excel using "Reclink_V1.xlsx", sheet(Reclink_with_cityname) firstrow(variables) sheetreplace 

//now import this new file 
import excel Reclink_V1.xlsx, sheet("Reclink_with_cityname") firstrow clear
save Reclink_with_cityname, replace

//get rid of duplicates
use Reclink_with_cityname, clear
duplicates tag  lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title  unmatched, gen(dup_rec_cityname)

bysort number paper_proper city_proper   unmatched: gen dup_rec_cityname2 = _n
//since they are duplicates by literally every single variable, it should be fine to drop 
drop if dup_rec_cityname2 > 1
tostring multiple_merge_na, replace
rename unmatched unmatched_cityname
drop cityinpaper
save  "/Users/seokminoh/Desktop/Dell_2/Reclink_with_cityname", replace

use "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_Initial", clear
rename _merge mergeReclinkInitial
merge 1:m  number   using Reclink_with_cityname
save "/Users/seokminoh/Desktop/Dell_2/Reclink_cityname_Merged", replace
drop if unmatched_cityname == 0
//File of unmatched

//also refer to excel sheet for notes and have it all somewhere.
//new tomerge file 
bysort number: gen dup_reclinkMergecityname = _n
drop if dup_reclinkMergecityname> 1
rename _merge _mergecitynamesome
save  "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_cityname", replace

//File to Append
use "/Users/seokminoh/Desktop/Dell_2/Reclink_cityname_Merged", replace
keep if unmatched_cityname == 0
save "/Users/seokminoh/Desktop/Dell_2/To_Append_Reclink_cityname_Merged", replace

*** STEP 10: Try fuzzy merge again but with a lower minimum score. Also, now, make sure it is the same name as the original file. 

//first get the small file ready by making the paper name same as the original file
use  "/Users/seokminoh/Desktop/Dell_2/na_papers_50_72_Final.dta",replace
rename city_proper cityoriginalmerge
rename state_proper stateoriginalmerge
rename paper_proper usethispapername
save   "/Users/seokminoh/Desktop/Dell_2/Getting_small_file_origname.dta",replace
merge 1:1 number using  "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_cityname"
keep if _merge == 3 
rename paper_proper paper_nameold
rename usethispapername paper_proper 
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_originalpapername", replace

//reclink with match score of .95
use "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_originalpapername", clear
keep city_proper state_proper paper_proper cityinpaper notes* number
reclink paper_proper state_proper city_proper  using "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", idmaster(number) idusing(id3) gen(match_score_citynameog)  minscore(.95)
save  "/Users/seokminoh/Desktop/Dell_2/Merged_reclink_originalpapername", replace
gen unmatched_origpaper = 0
keep if _merge == 3

//create a crosswalk now. The way you do this is going to be by inspecting by looking at the names of the paper, city, and state, and seeing if they are reasonable. 
//check the "notes" variable
keep lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title  cityinpaper unmatched_origpaper 

//this file was later renamed as Reclink_V1
export excel using "Reclink_V1.xlsx", sheet(Reclink_with_originalpaper) firstrow(variables) sheetreplace 

//now import this new file 
import excel Reclink_V1.xlsx, sheet("Reclink_with_originalpaper") firstrow clear
save Reclink_with_originalpaper, replace

//get rid of duplicates
use Reclink_with_originalpaper, clear
//duplicates tag  lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title  unmatched, gen(dup_rec_original)

bysort number : gen dup_rec_original2 = _n
//since they are duplicates by literally every single variable, it should be fine to drop 
drop if dup_rec_original2 > 1
tostring multiple_merge_na, replace
rename paper_proper paper_orig
rename city_proper city_orig
rename state_proper state_orig
save  "/Users/seokminoh/Desktop/Dell_2/Reclink_with_originalpaper", replace

use "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_cityname", clear
//rename _merge mergeReclinkcity
merge 1:m  number  using Reclink_with_originalpaper
save "/Users/seokminoh/Desktop/Dell_2/Reclink_cityorig_Merged", replace
drop if unmatched_orig == 0
//File of unmatched

//also refer to excel sheet for notes and have it all somewhere.
//new tomerge file 
bysort number: gen dup_reclinkMergeorigcity = _n
drop if dup_reclinkMergeorigcity> 1
rename _merge _mergeorigcity
save  "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_origcity", replace

//File to Append
use "/Users/seokminoh/Desktop/Dell_2/Reclink_with_originalpaper", replace
keep if unmatched_origpaper == 0
save "/Users/seokminoh/Desktop/Dell_2/To_Append_Reclink_cityname_Merged", replace

*** STEP 11: Fuzzy merge one last time, where I merge with citynames in front of all and merge on state and paper name rather than city as well. Require states to be the same.

//first get the small file ready by making the paper name same as the original file
use   "/Users/seokminoh/Desktop/Dell_2/Getting_small_file_origname.dta",replace
merge 1:1 number using  "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_origcity"
keep if _merge == 3 
rename paper_proper paper_nameold
rename usethispapername paper_proper 
drop cityinpaper 
gen cityinpaper = strpos(paper_proper,city_proper)
replace paper_proper = city_proper +paper_proper if cityinpaper == 0 & city_proper !="" & paper_proper != ""
save "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_og_for_Master", replace

//Make the masterfile also have city name in front of all of papers for those that do not have city names in the paper at all  
use "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_2", clear
gen cityinpaper = strpos(paper_proper,city_proper)
gen paper_properx = city_proper +paper_proper if cityinpaper == 0 & city_proper !="" & paper_proper != ""
rename paper_proper paper_proper_old
rename paper_properx paper_proper
rename city_proper cityUsing_Master
save "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_citynameinfront", replace

//now reclink with relatively low min score
use "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_og_for_Master", clear
keep city_proper state_proper paper_proper cityinpaper notes* number
reclink paper_proper state_proper  using "/Users/seokminoh/Desktop/Dell_2/Master_for_reclink_citynameinfront", idmaster(number) idusing(id3) gen(match_score_citynameog)  minscore(.95) req(state_proper)
save  "/Users/seokminoh/Desktop/Dell_2/Merged_reclink_master_cityinfront", replace
gen unmatched_Mastercityname = 0
keep if _merge == 3

//this file was later renamed as Reclink_V1
keep lccn number paper_proper city_proper state_proper Upaper_proper cityUsing_Master Ustate_proper alt_title  cityinpaper unmatched_Mastercityname 
export excel using "Reclink_V1.xlsx", sheet(Reclink_with_mastercityname) firstrow(variables) sheetreplace 

//now import this new file 
import excel Reclink_V1.xlsx, sheet("Reclink_with_mastercityname") firstrow clear
drop if number ==.
save Reclink_with_mastercityname, replace

//get rid of duplicates
use Reclink_with_mastercityname, clear
//duplicates tag  lccn number paper_proper city_proper state_proper Upaper_proper Ucity_proper Ustate_proper alt_title  unmatched, gen(dup_rec_original)

bysort number : gen dup_rec_og_citymaster = _n
//since they are duplicates by literally every single variable, it should be fine to drop 
drop if dup_rec_og_citymaster > 1
tostring multiple_merge_na, replace
rename paper_proper paper_masterwithcity
rename city_proper city_masterwithcity
rename state_proper state_masterwithcity
save  "/Users/seokminoh/Desktop/Dell_2/Reclink_with_Mastercityname", replace

use "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_origcity", clear
//rename _merge mergeReclinkcity
merge 1:m  number  using Reclink_with_Mastercityname
save "/Users/seokminoh/Desktop/Dell_2/Merged_Reclink_with_mastercityname", replace
drop if unmatched_Mastercityname == 0
//File of unmatched

//also refer to excel sheet for notes and have it all somewhere.
//new tomerge file 
bysort number: gen dup_reclinkMasterwithcityname = _n
drop if dup_reclinkMasterwithcityname> 1
rename _merge _mergemasterwithcityname
save  "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_mastercityname", replace

//File to Append
use "/Users/seokminoh/Desktop/Dell_2/Merged_Reclink_with_mastercityname", replace
keep if unmatched_Mastercityname == 0
save "/Users/seokminoh/Desktop/Dell_2/To_Append_Reclink_cityname_Merged", replace
