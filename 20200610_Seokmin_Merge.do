//06/29/20
cd /Users/seokminoh/Desktop/Dell_3/
ssc install distinct
ssc install egenmore

**** STEP 1: IMPORT THE FILES  ****
 

import delimited ca_newspaper_data.csv, clear
save  ca_newspaper_data.dta, replace

//import the using file 
import delimited na_papers_50_72.csv, varnames(1) encoding(ISO-8859-9) clear 
save na_papers_50_72.dta, replace

//create a copy of the variable

*** STEP 2: FORMAT THE SMALLER FILE ***

//convert the city and state variables to lower case
use "na_papers_50_72.dta", clear
gen state_proper = lower(state)
gen city_proper = lower(city)
//this gets rid of all the hyphens
replace city_proper = subinstr(city_proper, "-"," " , .)

//make it similar in format to the ca newspaper data
replace state_proper =  state_proper 
replace city_proper = city_proper 

//get rid of blank spaces for later merge
replace state_proper = subinstr(state_proper," ","",.)
replace city_proper = subinstr(city_proper," ","",.)

//apply a similar method for the paper variable
gen paper_proper = paper 

//get rid of all the hyphens
replace paper_proper = subinstr(paper_proper, "-","" , .)
replace paper_proper = subinstr(paper_proper," ","",.)
replace paper_proper = lower(paper_proper)

gen number = _n
keep if number < 1118

//check if there are any duplicates
bysort paper_proper city_proper state_proper: gen duplicates_using = _n
save  "na_papers_50_72_prem.dta", replace

//Since the duplicates ones were identitical (check all the lemar ones), just drop them
drop if duplicates_using > 1 

save  "na_papers_50_72_Final.dta", replace

*** STEP 3: FORMAT THE BIGGER FILE ***
use "ca_newspaper_data.dta", replace

gen paper_proper = lower(title_normal)
gen city_proper = lower(city)
gen state_proper = lower(state)

//recognize that some of the states and cities variables have multiple cities and states. So, split them. However, we want to make sure that we do not have unnecessary punctuations

//first format such that 
replace state_proper = subinstr(state_proper," ","",.)
replace state_proper = subinstr(state_proper , "(", "", .)
replace state_proper = subinstr(state_proper , ")", "", .)
replace state_proper = subinstr(state_proper , "'", "", .)
replace state_proper = subinstr(state_proper , "[", "", .)
replace state_proper = subinstr(state_proper , "]", "", .)
replace state_proper = strtrim(state_proper)

replace city_proper = subinstr(city_proper," ","",.)
replace city_proper = subinstr(city_proper , "(", "", .)
replace city_proper = subinstr(city_proper , ")", "", .)
replace city_proper = subinstr(city_proper , "'", "", .)
replace city_proper = subinstr(city_proper , "[", "", .)
replace city_proper = subinstr(city_proper , "]", "", .)
replace city_proper = strtrim(city_proper)

//then split the variables correspondingly 
split state_proper, p(",") g(state_proper)
split city_proper, p(",") g(city_proper) 


save "ca_newspaper_data_Final.dta", replace
 
// now apply a similar process for alternative titles
use "ca_newspaper_data_Final.dta", replace
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

rename state_proper state_beforeReshape
rename city_proper city_beforeReshape

forvalues i =6/22{
drop state_proper`i'
drop city_proper`i'
drop paper_proper`i'
}

//create a unique identifier
gen id2 = _n

save "ca_newspaper_data_Final.dta", replace

*** STEP 4: RESHAPE THE DATA SUCH THAT YOU ACCOUNT FOR 5 ALTERNATIVE TITLES, CITIES, AND STATES ***

****
use "ca_newspaper_data_Final.dta", replace

//create a long file that is short enough 
reshape long state_proper city_proper paper_proper, i(id2) j(instance)

//no need if the necessary variables are empty so drop them
drop if paper_proper == "" & city_proper == "" & state_proper == ""
save "ca_long_Final.dta", replace

*** STEP 5: FIRST MERGE - merge where each alternative title has a different state ***

use  "ca_long_Final.dta", replace
merge m:1 paper_proper city_proper state_proper using "na_papers_50_72_Final.dta"
rename _merge _mergeAppend1_5
preserve 
keep if _merge == 3 
gen step = 1
save "merged.dta", replace
restore
keep if _merge == 2
//save the 542 that did not match
save "unmerged.dta", replace


*** STEP 6: SECOND MERGE - merge where each alternative title has the same state name ***

use "ca_newspaper_data_Final.dta", replace

forvalues i =2/5{
replace state_proper`i' = state_proper1 
replace city_proper`i' = city_proper1 
}

reshape long state_proper city_proper paper_proper, i(id2) j(instance)
//drop the repetitive variables that do not have a paper name assocaited with them
drop if paper_proper == "" 
gen id3 = _n
save  "ca_long_Final_SameCity", replace
merge m:1 paper_proper city_proper state_proper using "unmerged.dta"
rename _merge _mergeSameCityState
//this now results in 496 mismatches
preserve 
keep if _mergeSameCityState == 3 
gen step = 2
append using merged.dta
save "merged.dta", replace
restore
keep if _mergeSameCityState == 2
save "unmerged_second.dta", replace

*** STEP 7: THIRD MERGE - merge where each alternative title has the same state name and using data does not have the city name attached to it in the front ***

//get rid of city names in front of the paper
use "unmerged_second.dta",replace

gen city_properx = lower(city)
replace city_properx = subinstr(city, "-","" , .)
gen cityinpaper = strpos(paper_proper,city_properx)

replace paper_proper = subinstr(paper_proper,city_properx, "", 1) if cityinpaper == 1
distinct paper_proper city_proper state_proper

duplicates tag paper_proper state_proper city_proper, gen(dupcity)

replace paper_proper = city+paper_proper if dupcity>0 & cityinpaper > 0

save "unmerged_second_nocity",replace

//the result is now 325 mismatches. 
use "ca_long_Final_SameCity",replace
merge m:1 paper_proper city_proper state_proper using  "unmerged_second_nocity"
rename _merge _mergeNocity
preserve 
keep if _mergeNocity == 3 
gen step = 3
append using merged.dta
save "merged.dta", replace
restore
keep if _mergeNocity == 2
save "unmerged_third.dta", replace
*** STEP 8: RECLINK - fuzzy merge using the titles we are given without the city name in front and merging on state and city and paper name***

//get the using data ready 
use "unmerged_third.dta", clear
keep city_proper state_proper paper_proper number cityinpaper 
save "unmerged_third_reclink.dta", replace

use "unmerged_third_reclink.dta", replace
//you now have around 125 additional matches (check _merge = 3)  
reclink paper_proper state_proper city_proper  using "ca_long_Final_SameCity", idmaster(number) idusing(id3) gen(match_score)  _merge(_merge_Reclink) minscore(.99)
save "reclink_Step8", replace
keep if _merge_Reclink == 3 
save "reclink_Step8_V2", replace
//copy and paste the excel sheet 
*** 8.1 manually check and analyze the matches to see if they were legitimate. The crosswalk I made is in the folder, so I will skip that for now
*** NOTE: Suppose I saw a repetition of either ca or na files, I only included the ones that were identitical as matched. If not, I left them as unmatched for now and will change them later. The process for crosswalk is in the other file. 
//create a crosswalk now. The way you do this is going to be by inspecting by looking at the names of the paper, city, and state, and seeing if they are reasonable. 
//check the "notes" variable
import  excel Reclink_Final.xlsx, sheet("Reclink_Initial") firstrow clear
bysort lccn number paper_proper city_proper state_proper: gen duplicates_Reclink_Step8 = _n
drop if duplicates_Reclink_Step8 > 1
merge 1:m lccn number paper_proper city_proper state_proper using reclink_Step8_V2
rename _merge _mergeReclinkInitial
preserve 
keep if _mergeReclinkInitial == 3 
keep if unmatched == 0
gen step = 4
append using merged.dta
save "merged.dta", replace
restore
keep if unmatched == 0
merge m:1  number using   unmerged_third.dta
drop if _merge == 3
drop _merge
save "unmerged_fourth.dta", replace

*** STEP 9 - Reclink Part 2. Here I will add the city name in front of the smaller file if the city name for those that were never in the front. Then, I will fuzzy merge. If they look reasonably the same, I consider them to be same. 

//btw this other file is in the other folder. I will put up codes for it later. 

//first get the small file ready 
use "unmerged_fourth", replace
keep city_proper state_proper paper_proper cityinpaper notes* number
replace paper_proper = city_proper + paper_proper if cityinpaper == 0
save "unmerged_fourth_reclink", replace

//now merge (check.dta)
use  "unmerged_fourth_reclink", replace
reclink paper_proper state_proper city_proper  using "ca_long_Final_SameCity", idmaster(number) idusing(id3) gen(match_score)  _merge(_merge_Reclink_cityname) minscore(.99)
save "reclink_Step9", replace
keep if _merge_Reclink_cityname == 3
save "reclink_Step9_V2", replace
//the unmatched with respect to merge were all unmatched observations in the first place so it does not really matter. 
import  excel Reclink_Final.xlsx, sheet("Reclink_with_cityname") firstrow clear
bysort lccn number paper_proper city_proper state_proper: gen duplicates_Reclink_Step9 = _n
drop if duplicates_Reclink_Step9 > 1
merge 1:m lccn number paper_proper city_proper state_proper using reclink_Step9_V2
drop _merge
//note that this is a "cleaned version", and a little differnet from before. The mismatches were considered to not match anyways, so feel free to drop them
preserve 
keep if unmatched == 0
gen step = 5
append using merged.dta, force
save "merged.dta", replace
restore
keep if unmatched == 0
merge m:1  number using   unmerged_fourth.dta, force
drop if _merge == 3
drop _merge
save "unmerged_fifth.dta", replace

*** STEP 10: Try fuzzy merge again but with a lower minimum score. Also, now, make sure it is the same name as the original file. (next time merge this with step 9)

//first get the small file ready by making the paper name same as the original file
use  "unmerged_fifth.dta",replace
rename city_proper cityoriginalmerge
rename state_proper stateoriginalmerge
rename paper_proper usethispapername
merge 1:1 number using "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_originalpapername", force
//even though lemars daily and etc are the same, we will just keep thyem for now, to be consistent with prior ones.
drop _merge
save "unmerged_fifth_V2.dta", replace

//reclink with match score of .95
use "unmerged_fifth_V2", clear
keep city_proper state_proper paper_proper cityinpaper notes* number
reclink paper_proper state_proper city_proper  using "ca_long_Final_SameCity", idmaster(number) idusing(id3) gen(match_score_citynameog)  minscore(.95)
save  "reclink_step10", replace
keep if _merge == 3
rename _merge _mergeorigname
gen identifier = _n
save  "reclink_step10_V2", replace

//now import this new file 
import excel Reclink_Final.xlsx, sheet("Reclink_with_originalpaper") firstrow clear
gen identifier = _n
merge 1:m identifier using reclink_Step10_V2
drop _merge
drop identifier
preserve 
keep if unmatched == 0
gen step = 6
append using merged.dta
save "merged.dta", replace
restore
bysort number: egen any_matches = min(unmatched)
keep if any_matches == 0
merge m:1  number using   unmerged_fifth.dta
//just drop the lemars 
drop if _merge == 3 | _merge == 1 
bysort number: gen dup = _n
drop if dup > 1
drop _merge
drop dup 
save "unmerged_sixth.dta", replace

*** STEP 11: Fuzzy merge one last time, where I merge with citynames in front of all and merge on state and paper name rather than city as well. Require states to be the same.

//first get the small file ready by making the paper name same as the original file
use "unmerged_sixth.dta", replace
rename city_proper cityoriginalmerge
rename state_proper stateoriginalmerge
rename paper_proper usethispapername
merge 1:1 number using "/Users/seokminoh/Desktop/Dell_2/To_Merge_Reclink_originalpapername", force
keep if _merge == 3  
drop cityinpaper 
gen cityinpaper = strpos(paper_proper,city_proper)
replace paper_proper = city_proper +paper_proper if cityinpaper == 0 & city_proper !="" & paper_proper != ""
save "unmerged_sixth_V2", replace

//Make the masterfile also have city name in front of all of papers for those that do not have city names in the paper at all  
use "ca_long_Final_SameCity", clear
gen cityinpaper = strpos(paper_proper,city_proper)
gen paper_properx = city_proper +paper_proper if cityinpaper == 0 & city_proper !="" & paper_proper != ""
rename paper_proper paper_proper_old
rename paper_properx paper_proper
rename city_proper cityUsing_Master
save "ca_long_Final_SameCity_cityname", replace

//now reclink with relatively low min score
use "unmerged_sixth_V2", clear
keep city_proper state_proper paper_proper cityinpaper notes* number
reclink paper_proper state_proper  using "ca_long_Final_SameCity_cityname", idmaster(number) idusing(id3) gen(match_score_citynameog)  minscore(.95) req(state_proper)
save "reclink_Step11", replace
keep if _merge == 3
drop _merge
sort number 
gen identifier = _n
save  "reclink_Step11_V2", replace
//now import this new file 
import excel Reclink_Final.xlsx, sheet("Reclink_with_mastercityname")  firstrow clear
//because this also contains things I dropped earlier
drop if number == . 
drop if number == 537 
drop if number == 859
sort number
gen identifier = _n
merge 1:1 identifier number  using reclink_Step11_V2
drop _merge
drop identifier
preserve 
keep if unmatched == 0
gen step = 7
append using merged.dta
save "merged.dta", replace
restore
bysort number: egen any_matches = min(unmatched)
keep if any_matches == 0
drop any_matches
merge m:1  number using   unmerged_sixth.dta
drop if _merge == 3 
bysort number: gen dup = _n
drop if dup > 1
drop _merge
drop dup 
save "unmerged_seventh.dta", replace

*** STEP 12: Some Manual Process to merge the two files 
use  "unmerged_seventh", replace

gen lccn_merge = _n
tostring lccn_merge, gen(string_lccn_merge)

//elmwood park world
replace string_lccn_merge = "sn95066015" if number == 378
//hardin county times
replace string_lccn_merge = "sn85050975" if number == 716
//nampa idaho free press 
replace string_lccn_merge = "sn86091132" if number == 251
//dupage county register
replace string_lccn_merge = "sn87062376" if number == 281
//arlington heights day
replace string_lccn_merge = "sn2003060801" if number == 274
//tundra times 
replace string_lccn_merge = "sn84020664" if number == 26
//chicago austin journal (since it was published by austin news, merge it that way)
replace string_lccn_merge = "sn97062005" if number == 305
//austin journal (since it was published by austin news, merge it that way)
replace string_lccn_merge = "sn97062005" if number == 309
//fairfield county news (76) should be westport crier and herald (look at top right on dropbox) , which is sn92051328
replace string_lccn_merge = "sn92051328" if number == 169

save  "unmerged_seventh", replace

use "ca_long_Final_SameCity_cityname", clear
gen string_lccn_merge = lccn
bysort lccn: gen duplicates_master = _n
drop if duplicates_master > 1
save "ca_long_Final_SameCity_cityname_2", replace
merge 1:m string_lccn_merge using  "unmerged_seventh"
preserve 
keep if _merge == 3
drop _merge
gen step = 8
append using merged.dta
save "merged.dta", replace
restore
keep if _merge == 3
drop _merge
merge 1:1  number using   unmerged_seventh.dta
drop if _merge == 3 
drop _merge
save "unmerged_eight",replace

** STEP 13: Final Fuzzy Merge - Last merge before I start the manual process. Fuzzy Merge on the city without name in front and master with city name in front and not requiring the city to be exact with lower threshold for merge 
use  "unmerged_eight", clear
keep city_proper state_proper paper_proper notes* number
reclink paper_proper state_proper  using "ca_long_Final_SameCity_cityname", idmaster(number) idusing(id3) gen(match_score_Final)  minscore(.95) req(state_proper)
save 
use "reclink_13", replace
keep if _merge == 3 
sort number
gen identifier = _n
drop _merge
save "reclink_13_V2", replace


//note, we not have a variable found_manually that is 0 if the newspaper was unable to be found manually

import excel Reclink_Final.xlsx, sheet("Reclink_Final") firstrow clear
drop if number == 319 
sort number
gen identifier = _n
merge 1:1 identifier number using reclink_13_V2
drop _merge
drop identifier
preserve 
keep if unmatched == 0
gen step = 9
append using merged.dta
save "merged.dta", replace
restore
bysort number: egen any_matches = min(unmatched)
keep if any_matches == 0
drop any_matches
merge m:1  number using   unmerged_eight.dta
drop if _merge == 3 
bysort number: gen dup = _n
drop if dup > 1
drop _merge
drop dup 
save "unmerged_nine.dta", replace

*** STEP 14: Do everything else manually
use  "unmerged_nine.dta", clear
sort number 
//create a binary paper where it is 1 if it is a school paper and 0 otherwise (THIS IS ONLY FOR THOSE THAT WERE IN THE FINAL STAGES OF THE MERGE )
gen school_paper = 0
br number paper city_proper state_proper found_manually school_paper string_lccn_merge

*** STEP 14.1  those able to be found manually 

//advertiser 
replace string_lccn_merge = "sn94060712" if number == 412
//iowa burlington daily times 
replace string_lccn_merge = "sn84020697" if number == 613
//Arcadia Bienville Democrat 
replace string_lccn_merge = "sn88064069" if number == 591
//Rolling Meadows Herald
replace string_lccn_merge = "sn87062368" if number == 475
//Bartlett Heraldreplace
replace string_lccn_merge = "sn94054536" if number == 276
//Mokena herald
replace string_lccn_merge = "sn2003060724" if number == 431
//Elk Grove Village Herald
replace string_lccn_merge = "sn87062369" if number == 377
//Thompson rake register 
replace string_lccn_merge = "sn87057852" if number == 839
//Forest Park Review 
replace string_lccn_merge = "sn93057147" if number == 380


//Chicago heights star 
replace string_lccn_merge = "sn94060671" if number == 319
//Atlantic News telegraph 
replace string_lccn_merge = "sn85000363" if number == 627
//Oak park journal 
replace string_lccn_merge = "sn97062005" if number == 350
//Muscatine Iowa Democratic Enquirer
replace string_lccn_merge = "sn82015306" if number == 769
//News Journal
replace string_lccn_merge = "sn95066016" if number == 348
//Oxnard Ventura county advisor
replace string_lccn_merge = "sn00060273" if number == 117
//Oxnard Ventura county advisor
replace string_lccn_merge = "sn87057852" if number == 839

//van nuys news
replace string_lccn_merge = "sn95061596" if number == 155
//spelman reflections 
replace string_lccn_merge ="sn81298011" if number == 217
//spelman spotlight 
replace string_lccn_merge ="sn81304549" if number == 218
//mercer cluster 
replace string_lccn_merge ="sn91046080" if number == 232
//bartlett herald 
replace string_lccn_merge ="sn94054536" if number == 276
//chicago community publications 
replace string_lccn_merge ="sn97062005" if number == 312
//chicago galewood news
replace string_lccn_merge ="sn97062005" if number == 317
//chicago hermosa journal 
replace string_lccn_merge ="sn97062005" if number == 320
//chicago humboldt journal 
replace string_lccn_merge ="sn97062005" if number == 322
//chicago kevlyn parn journal 
replace string_lccn_merge ="sn97062005" if number == 325
//chicago mont clare galewood news 
replace string_lccn_merge ="sn97062005" if number == 326
//chicago-news-journal-world
replace string_lccn_merge ="sn97062005" if number == 327
//chicago-northwest journal
replace string_lccn_merge ="sn97062005" if number == 329
//chicago star publications 
replace string_lccn_merge ="sn83003538" if number == 336
//community publications 
replace string_lccn_merge ="sn97062005" if number == 340
//galewood news
replace string_lccn_merge ="sn97062005" if number == 342
//humboldt journal
replace string_lccn_merge ="sn97062005" if number == 344
//kelvyn park journal
replace string_lccn_merge ="sn97062005" if number == 346
//mont clare galewood news
replace string_lccn_merge ="sn97062005" if number == 347
//news-journal
replace string_lccn_merge ="sn97062005" if number == 348
//northwest journal
replace string_lccn_merge ="sn97062005" if number == 349
//oak park journal
replace string_lccn_merge ="sn97062005" if number == 340
//river forest journal
replace string_lccn_merge ="sn97062005" if number == 351
//forest park review
replace string_lccn_merge ="sn93057147" if number == 380
//homewood daily southtown news marketer 
replace string_lccn_merge = "sn83003538" if number == 399
//itasca register 
replace string_lccn_merge = "sn87062377" if number == 404
//oak park oak park journal
replace string_lccn_merge ="sn97062005" if number == 450
//river forest journal
replace string_lccn_merge ="sn97062005" if number == 472
//windfall herald 
replace string_lccn_merge ="sn89099005" if number == 563
//windfall news 
replace string_lccn_merge ="sn89099022" if number == 564
//albert city gazette 
replace string_lccn_merge ="sn87058555" if number == 576
//andreas-historical-atlas-of-des-moines-county
replace string_lccn_merge ="sn85049905" if number == 607
//chariton atlantic news telegraph
replace string_lccn_merge ="sn85000363" if number == 627
//goldfield gazette
replace string_lccn_merge ="sn88059592" if number == 634
//gowrie news
replace string_lccn_merge ="sn86060253" if number == 690
//baptismal-register-sacred-heart
replace string_lccn_merge ="sn84027330" if number == 791
//atllas-of-pocahontas-county-iowa
replace string_lccn_merge ="sn87057812" if number == 800
//prairie-city-quint-city-labor-day
replace string_lccn_merge ="sn87058141" if number == 805
//rolfe-reveille
replace string_lccn_merge ="sn87057817" if number == 816
//thompson rake register-sacred-heart
replace string_lccn_merge ="sn87057852" if number == 839
//the lansing post 
replace string_lccn_merge ="sn2001061621" if number == 996
//jackson petal paper
replace string_lccn_merge ="sn85044791" if number == 1039
//jackson petal paper
replace string_lccn_merge ="sn85044791" if number == 1046
//brookfield bossworth sentinel 
replace string_lccn_merge ="sn91061194" if number == 1054
//homewood star 
replace string_lccn_merge ="sn83003538" if number == 401

*** STEP 14.2  those unable to be found manually 
//basically missing if found, 0 if unable to be found 
replace found_manually = 0 if number == 10
replace found_manually = 0 if number == 20
replace found_manually = 0 if number == 21
replace found_manually = 0 if number == 22
replace found_manually = 0 if number == 40
replace found_manually = 0 if number == 41
replace found_manually = 0 if number == 42
replace found_manually = 0 if number == 99
replace found_manually = 0 if number == 100
replace found_manually = 0 if number == 101
replace found_manually = 0 if number == 102
replace found_manually = 0 if number == 104
replace found_manually = 0 if number == 105
replace found_manually = 0 if number == 106
replace found_manually = 0 if number == 107
replace found_manually = 0 if number == 108
replace found_manually = 0 if number == 109
replace found_manually = 0 if number == 110
replace found_manually = 0 if number == 111
replace found_manually = 0 if number == 117
replace found_manually = 0 if number == 118
replace found_manually = 0 if number == 135
replace found_manually = 0 if number == 161
replace found_manually = 0 if number == 170
replace found_manually = 0 if number == 171
replace found_manually = 0 if number == 172
replace found_manually = 0 if number == 178
replace found_manually = 0 if number == 191
replace found_manually = 0 if number == 192
replace found_manually = 0 if number == 193
replace found_manually = 0 if number == 214
replace found_manually = 0 if number == 215
replace found_manually = 0 if number == 235
replace found_manually = 0 if number == 236
replace found_manually = 0 if number == 257
replace found_manually = 0 if number == 269
replace found_manually = 0 if number == 273
replace found_manually = 0 if number == 304
replace found_manually = 0 if number == 311
replace found_manually = 0 if number == 313
replace found_manually = . if number == 325
replace found_manually = . if number == 317
replace found_manually = . if number == 329
replace found_manually = 0 if number == 330
replace found_manually = . if number == 342
replace found_manually = 0 if number == 362
replace found_manually = 0 if number == 363
replace found_manually = 0 if number == 364
replace found_manually = 0 if number == 365
replace found_manually = . if number == 377
replace found_manually = 0 if number == 410
replace found_manually = . if number == 412
replace found_manually = 0 if number == 413
replace found_manually = 0 if number == 430

replace found_manually = 0 if number == 435
replace found_manually = 0 if number == 436
replace found_manually = 0 if number == 437
replace found_manually = 0 if number == 438
replace found_manually = 0 if number == 439
replace found_manually = 0 if number == 445
replace found_manually = 0 if number == 446
replace found_manually = 0 if number == 447
replace found_manually = 0 if number == 457
replace found_manually = 0 if number == 458
replace found_manually = 0 if number == 462
replace found_manually = 0 if number == 482
replace found_manually = 0 if number == 483
replace found_manually = 0 if number == 487
replace found_manually = 0 if number == 505
replace found_manually = 0 if number == 506
replace found_manually = 0 if number == 521
replace found_manually = 0 if number == 522
replace found_manually = 0 if number == 523
replace found_manually = 0 if number == 541
replace found_manually = 0 if number == 572
replace found_manually = 0 if number == 578
replace found_manually = 0 if number == 585
replace found_manually = 0 if number == 605
replace found_manually = 0 if number == 611
replace found_manually = 0 if number == 617
replace found_manually = 0 if number == 618
replace found_manually = 0 if number == 622
replace found_manually = 0 if number == 644
replace found_manually = 0 if number == 646
replace found_manually = 0 if number == 661
replace found_manually = 0 if number == 662
replace found_manually = 0 if number == 713
replace found_manually = 0 if number == 727
replace found_manually = 0 if number == 795
replace found_manually = 0 if number == 813
replace found_manually = 0 if number == 837
replace found_manually = 0 if number == 841
replace found_manually = 0 if number == 846
replace found_manually = 0 if number == 854
replace found_manually = 0 if number == 877
replace found_manually = 0 if number == 883
replace found_manually = 0 if number == 884
replace found_manually = 0 if number == 886
replace found_manually = 0 if number == 891
replace found_manually = 0 if number == 950
replace found_manually = 0 if number == 954
replace found_manually = 0 if number == 955
replace found_manually = 0 if number == 956
replace found_manually = 0 if number == 965
replace found_manually = 0 if number == 979
replace found_manually = 0 if number == 992
replace found_manually = 0 if number == 1014
replace found_manually = 0 if number == 1020
replace found_manually = 0 if number == 1027
replace found_manually = 0 if number == 1079
replace found_manually = 0 if number == 1080
replace found_manually = 0 if number == 1100
replace found_manually = 0 if number == 1114
replace found_manually = 0 if number == 663
replace found_manually = 0 if number == 47

replace found_manually = 0 if number == 434

*** 14.3 for the ones that are school papers 
replace school_paper = 1 if number == 10 
replace school_paper = 1 if number == 20
replace school_paper = 1 if number == 21
replace school_paper = 1 if number == 22
replace school_paper = 1 if number == 99
replace school_paper = 1 if number == 100
replace school_paper = 1 if number == 101
replace school_paper = 1 if number == 102
replace school_paper = 1 if number == 104
replace school_paper = 1 if number == 105
replace school_paper = 1 if number == 106
replace school_paper = 1 if number == 107
replace school_paper = 1 if number == 108
replace school_paper = 1 if number == 109
replace school_paper = 1 if number == 110
replace school_paper = 1 if number == 111
replace school_paper = 1 if number == 135
replace school_paper = 1 if number == 170
replace school_paper = 1 if number == 171
replace school_paper = 1 if number == 172
replace school_paper = 1 if number == 214
replace school_paper = 1 if number == 215
replace school_paper = 1 if number == 217
replace school_paper = 1 if number == 218
replace school_paper = 1 if number == 232
replace school_paper = 1 if number == 257
replace school_paper = 1 if number == 313
replace school_paper = 1 if number == 435
replace school_paper = 1 if number == 436
replace school_paper = 1 if number == 437
replace school_paper = 1 if number == 438
replace school_paper = 1 if number == 439
replace school_paper = 1 if number == 505
replace school_paper = 1 if number == 506
replace school_paper = 1 if number == 521
replace school_paper = 1 if number == 522
replace school_paper = 1 if number == 523
replace school_paper = 1 if number == 605
replace school_paper = 1 if number == 617
replace school_paper = 1 if number == 618
replace school_paper = 1 if number == 661
replace school_paper = 1 if number == 795
replace school_paper = 1 if number == 883
replace school_paper = 1 if number == 886
replace school_paper = 1 if number == 954
replace school_paper = 1 if number == 955
replace school_paper = 1 if number == 956
replace school_paper = 1 if number == 965
replace school_paper = 1 if number == 992
replace school_paper = 1 if number == 1027
replace school_paper = 1 if number == 1079
replace school_paper = 1 if number == 1080
replace school_paper = 1 if number == 1110
replace school_paper = 1 if number == 434

*** 14.4: create a final way of putting all the notes together that were in the excel file as well (this is to be done later). However, for now, keep adding notes as you go
gen notes_na_final = ""
replace notes_na_final = "This is a high school newspaper" if number == 135

replace notes_na_final = "I think this is impossible to merge because in dropbox, this is an agglomeration of multiple chicago newspapers. Also arlington heights herald should be linked to sn94054540" if number == 273

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 312

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 313

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 317

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 320

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 322

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 325

replace notes_na_final = "Merge to Austin News. Check out Northwest Journal August 30 1967 folder and galewood news March 22, 1967 folder" if number == 326

replace notes_na_final = "Merge to Austin News. The headline is South Austin News" if number == 327

replace notes_na_final = "Merge to Austin News. The headline is Northwest Journal" if number == 329

replace notes_na_final = "Merge to Austin News. The headline is Northwest Journal" if number == 348

replace notes_na_final = "Merge to Austin News. It says published by austin news" if number == 350

replace notes_na_final = "Merge to Austin News. It says published by austin news" if number == 351

replace notes_na_final = "The publisher is not paddock publication but everything else seems right so merged" if number == 351

replace notes_na_final = "Does not seem like news" if number == 541

replace notes_na_final = "From 1862" if number == 572

replace notes_na_final = "The dropbox headline said The Albert City Appeal and The Marathon Republic" if number == 576

replace notes_na_final = "The dropbox headline said Burlington Hawk Eye Gazette " if number == 607

replace notes_na_final = "Does not seem like news" if number == 622

replace notes_na_final = "Seems like high school news" if number == 661

replace notes_na_final = "Dropbox headline is muscatine journal" if number == 769

replace notes_na_final = "Dropbox headline is Ottumwa Daily courier" if number == 791

replace notes_na_final = "High school news" if number == 795

replace notes_na_final = "Dropbox Headline is Pocahontas Record Democrat" if number == 800

replace notes_na_final = "Dropbox Headline is rolfe reveille" if number == 816

replace notes_na_final = "Probably not news" if number == 837

replace notes_na_final = "Probably not news" if number == 846

replace notes_na_final = "High School News" if number == 883

replace notes_na_final = "High School News" if number == 884

replace notes_na_final = "There is daily news but not just news for this" if number == 891

replace notes_na_final = "Same as Petal Paper. City is unclear in dropbox when inspecting the paper itself" if number == 1039

replace notes_na_final = "Same as Jackson Petal Paper. City is unclear in dropbox when inspecting the paper itself" if number == 1046

replace notes_na_final = "Dropbox Headline is The Brookfield Argus and the Linn County Farmer" if number == 1054

replace notes_na_final = "Dropbox Headline is The Lincoln Clarion" if number == 1079

replace notes_na_final = "Dropbox Headline is The Lincoln Clarion" if number == 1080


save  "manual", replace

use "ca_long_Final_SameCity_cityname_2", clear
merge 1:m string_lccn_merge using  "manual"
save  "Final",replace
preserve 
keep if _merge == 3
gen step = 10
append using merged.dta
save "merged.dta", replace
restore
keep if _merge == 2 
save "unmerged_final.dta", replace

//colapse the data
// lccn and numbers should be right, but I think there may be a problem with other variables, so redo that part here
use merged.dta, clear
keep lccn number notes*
merge m:1 number using "na_papers_50_72_Final.dta"
rename city city_na
rename state state_na
drop if _merge == 2
drop _merge
merge m:1 lccn using "ca_newspaper_data_Final.dta"
rename city city_loc
rename state state_loc
keep if _merge == 3
save "collapsed.dta", replace
//keep number lccn 
bysort number lccn: gen duplicates = _n
drop if duplicates > 1
duplicates tag number county, gen(dup)
sort number county 
by number (county), sort: gen diff = county[1] != county[_N] 
br number county if diff > 0
save "collapsed.dta", replace

//make the file for unmerged cleaned
use "unmerged_final.dta", replace
//do this manually because I manually merged this at the last minute
drop if number == 47
keep lccn number notes* school_paper
merge m:1 number using "na_papers_50_72_Final.dta"
rename city city_na
rename state state_na
drop if _merge == 2
drop _merge
merge m:1 lccn using "ca_newspaper_data_Final.dta"
rename city city_loc
rename state state_loc
keep if _merge == 1
drop _merge
save "unmerged_Append_Final", replace

//for the extra 3 that were dropped
//also I am going to merge phoenix el sol with sn86090862 as it seems right given time period 
//note that county for that vs sn88084220 are same 
//fix the lemar issue manually... it is a very small error in the crosswalk 
use  "na_papers_50_72_prem.dta", replace
keep if duplicates_using > 1 | number == 47 
rename city city_na
rename state state_na 
merge 1:m paper_proper city_proper state_proper using "ca_long_Final.dta"
keep if _merge == 3| _merge == 1
rename city city_loc
rename state state_loc
replace lccn = "sn86090862" if number == 47
drop _merge 
merge 1:m lccn state_proper using "ca_long_Final.dta"
keep if _merge == 3 
drop _merge 
by number: gen duplicates = _n
drop if duplicates > 1
keep state_na city_na state_loc city_loc paper title county lccn alt_title start_year end_year place_of_publication  number
save "last_changes.dta", replace

use "na_papers_50_72_prem.dta", replace
keep if  number == 734 | number == 737
rename city city_na
rename state state_na 
merge 1:m paper_proper city_proper state_proper using "ca_long_Final.dta"
keep if _merge == 3
rename city city_loc
rename state state_loc
drop _merge 
bysort number: gen duplicates = _n
drop if duplicates > 1
keep state_na city_na state_loc city_loc paper title county lccn alt_title start_year end_year place_of_publication  number
save  "last_changes_second.dta", replace


//finally get the collapsed
use "collapsed.dta", clear
replace paper = "le-mars-sentinel" if number == 735
append using last_changes
append using last_changes_second
replace notes = "I am going to merge phoenix el sol with sn86090862 as it seems right given time period. Also the county even compared to sn88084220 is the same."
save collapsed_final.dta, replace
