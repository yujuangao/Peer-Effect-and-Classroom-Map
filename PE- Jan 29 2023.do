
	*******************************
	*  NAME: Peer Effect					
	*  GOAL: distance as peer effect  IV																	
	*  AUTHOR: Gao yujuan
	*  DATE:  Apr 29 2021
	*******************************

	/**************outline*************
	First stage regression-reg pe and IV
	*gen var of whether bestfirend with each other (match) 
	*gen var of distance (d1 d2)
	*gen control var 
	*gen variance of score
	*result table
	*************************************/

	clear
	set more off,permanently
	capture log close
	set scrollbufsize 100000
	set matsize 11000
	
	/*
	global workingdir "/Users/gaoyujuan/Desktop/paper/pe/peer effect/1-result/2021-0427/working"
	global workingdatadir "/Users/gaoyujuan/Desktop/paper/pe/peer effect/1-result/2021-0427/working data"
	global savedir "/Users/gaoyujuan/Desktop/paper/pe/peer effect/1-result/2021-0427/save"
	global finaldir "/Users/gaoyujuan/Desktop/paper/pe/peer effect/0-sample-201712-201804/final"
	
	*/
	
	global workingdir "/Users/gaoyujuan/Desktop/paper/pe/peer effect/revision"
	
	capture log close

	cd "$workingdir"
	
	/**************************************************
					global
	**************************************************/

	global student stu_bs_age stu_bs_gender  stu_bs_boarding
	global family stu_bs_familymember m_educ f_educ asset
	global student_m stu_bs_gender_m  stu_bs_boarding_m
	global family_m stu_bs_familymember_m m_educ_m f_educ_m asset_m
	global student_a score_bs_a stu_bs_gender_a  stu_bs_boarding_a
	global family_a stu_bs_familymember_a m_educ_a f_educ_a asset_a
	global tea_c stu_bs_grade5 stu_bs_grade6 tea_age tea_gender tea_educ tea_workyear
	
	global outcomes_mid1 anxiety self_concept intrinsic_motiv instrument_motiv stu_fun_puzzle stu_mathlike distraction interruption ability 
	global outcomes_mid2 study_time_r study_mathtime_std
	global outcomes_mid3 cooperation stu_group
	
	foreach v in bs fn{
	global outcomes_mid1_`v' anxiety_`v' self_concept_`v' intrinsic_motiv_`v' instrument_motiv_`v' stu_fun_puzzle_`v' stu_mathlike_`v' distraction_`v' interruption_`v' ability_`v'
	global outcomes_mid2_`v' study_time_r_`v' study_mathtime_std_`v'
	global outcomes_mid3_`v' cooperation_`v' stu_group_`v'
	}
		
	*************************************************


 /******************result**********************/
/*
	use "$finaldir/model.dta",clear
	
	/************************************
	table1:sample description 
	************************************/
	
	bysort classid: gen N1=_N
	bysort classid: gen n1=_n
	count if n1==1

	 asdoc sum $student $family stu_bs_grade4 $tea_c N1 friend_num d1_ave_f d2_ave_f  score_bs_m_ave iv_1 iv_2 ///
	 score_bs $outcomes_mid1_bs study_time_r_bs cooperation_bs ///
	 score_fn $outcomes_mid1_fn $outcomes_mid2_fn $outcomes_mid3_fn $outcomes_mid4_fn ///
	 , stat(mean sd max min) replace label dec(3) ///
	 save($workingdir/apr28_table1.doc) title(Table 1. Descriptive statistics) ///
	 add(Data Sources: Source: Author's survey)
	
	use "$finaldir/model_long_all.dta",replace
	
	/**************************************************
			   table 2: distance and study relationship 
	***************************************************/
	
	global tea_a tea_age tea_gender tea_educ tea_workyear
	
	eststo clear
	
	qui:logit f_match d1 $student_a $family_a $tea_a i.countyid,cluster(classid)
		 est sto d1
		eststo:estpost margins,dydx(d1) 
		
	logit f_match d2 $student_a $family_a $tea_a i.countyid,cluster(classid)
		 est sto d2
	eststo:estpost margins,dydx(d2)
	
	outreg2 [d1 d2] using "$workingdir/apr28_table2.xls", ///
	excel dec(3) replace label nocons keep (d1 d2) title ("Table 2. Estimation of study relationship between two students") addstat(Pseudo R-squared, `e(r2_p)') 
	
	use "$finaldir/model.dta",clear
	
	/*******************************************
			   table3: ols and iv
	********************************************/
	
	use "$finaldir/model.dta",clear

	eststo clear
	
	qui:reg score_fn score_bs_m_ave score_bs  $student $family  $tea_c i.countyid,cluster(classid)
		est sto score_bs_m_ave
	ivregress 2sls score_fn (score_bs_m_ave=iv_1) i.countyid score_bs  $student $family $tea_c  ,cluster(classid) first
		est sto iv_1
		estat firststage
	qui:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c ,cluster(classid) first
		est sto iv_2
		estat firststage
	
	outreg2 [score_bs_m_ave iv_1 iv_2 ] using "$workingdir/apr28_table 3.xls", ///
	excel dec(3) replace label nocons adjr2 keep (score_bs_m_ave score_bs) title ("Table 3. Effect of study group average score on student academic performance (Instrumental variable)") 


	
	/*****************************************
		table4: ranking in study group 
	******************************************/
	use "$finaldir/model.dta",clear

	eststo clear
	
	qui: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if score_d1==0, cluster(classid) first
		est sto reg1
	qui: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if score_d1==1, cluster(classid) first
		est sto reg2
	qui: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if score_d1==2, cluster(classid) first
		est sto reg3
		
	outreg2 [reg1 reg2 reg3] using "$workingdir/apr28_table 4.xls", ///
	excel dec(3) label nocons adjr2 replace keep (score_bs_m_ave score_bs) title ("Table 4.Effect of study group average score on student academic performance—by student baseline score ranking within study group (instrumental variables estimates)") 
	
	/****************************************************
			   tableA1: ranking in class 
	*****************************************************/
	use "$finaldir/model.dta",clear

	bysort classid: egen score_rank=rank(score_bs),track
	bysort classid: egen score_rank_max=max(score_rank)
	gen score_mid_d=0 if score_rank<=1/3*(score_rank_max)
		replace score_mid_d=1 if score_rank>1/3*(score_rank_max) & score_rank<=2/3*(score_rank_max)
		replace score_mid_d=2 if score_rank>2/3*(score_rank_max)
	
	eststo clear
	
	qui: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if score_mid_d==0, cluster(classid) first
		est sto reg1
	qui: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if score_mid_d==1, cluster(classid) first
		est sto reg2
	qui: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if score_mid_d==2, cluster(classid) first
		est sto reg3
		
	outreg2 [reg1 reg2 reg3] using "$workingdir/apr28_tableA1.xls", ///
	excel dec(3) label nocons adjr2 replace keep (score_bs_m_ave score_bs) title ("Table A1.Effect of study group average score on student academic performance—by student baseline score ranking within class (instrumental variables estimates)") 
	*/
	***********************************
	*midoutcomes*
	***********************************
	use "$finaldir/model.dta",clear

	
	gen study_mathtime_std_bs=study_time_r_bs
	gen stu_group_bs=cooperation_bs

*endline
local i = 1

	foreach var in $outcomes_mid1 $outcomes_mid2 $outcomes_mid3 {
	
	eststo clear
		
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c , cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c if score_d1==0, cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c if score_d1==1, cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c if score_d1==2, cluster(classid)
		
		if `i'==1{
		
	esttab using "$workingdir/Feb262023_table5.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs ///
	title ("`var'") mtitles("All samples" "Student in bottom tercile" "Student in middle tercile" "Student in top tercile")
		}
	
	if `i'>1 & `i'<13{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs nomtitles nonumbers ///
	title ("`var'") 
		}
	
	else{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitles nonumbers ///
	title ("`var'") 
		}
	local i = `i' + 1
	}
	
	*baseline
	
local i = 1

	foreach var in $outcomes_mid1 $outcomes_mid2 $outcomes_mid3 {
	
	eststo clear
		
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c , cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c if score_d1==0, cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c if score_d1==1, cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c if score_d1==2, cluster(classid)
		
		if `i'==1{
		
	esttab using "$workingdir/Feb262023_table5.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs ///
	title ("`var'") mtitles("All samples" "Student in bottom tercile" "Student in middle tercile" "Student in top tercile")
		}
	
	if `i'>1 & `i'<13{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs nomtitles nonumbers ///
	title ("`var'") 
		}
	
	else{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitles nonumbers ///
	title ("`var'") 
		}
	local i = `i' + 1
	}
	
	**************************************************
					*rank change*
	**************************************************
	/*
	tab score_d1_fn score_d1 ,  column  lrchi2 
	
		score_d1_fn              score_d1
	          0          1	2	Total
				
	0        473        265	137	875 
	51.64      25.24	13.84	29.60 
				
	1        300        462	311	1,073 
	32.75      44.00	31.41	36.30 
				
	2        143        323	542	1,008 
	15.61      30.76	54.75	34.10 
				
	Total        916      1,050	990	2,956 
	100.00     100.00	100.00	100.00 

	likelihood	ratio chi2(4) = 482.9092	Pr = 0.000
*/

	**************************************************
				*进步/退步同学比较
	**************************************************
	use "$finaldir/model.dta",clear

	/*
	gen g=0 if score_d1<score_d1_fn
		replace g=1 if score_d1==score_d1_fn
		replace g=2 if score_d1>score_d1_fn
	
	*endline	
	
	local i = 1

	foreach var in $outcomes_mid1 $outcomes_mid2 $outcomes_mid3 {
	
	eststo clear
		
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs  score_bs $student $family $tea_c if g==0, cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs  score_bs $student $family $tea_c if g==1, cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs  score_bs $student $family $tea_c if g==2, cluster(classid)
		
	if `i'==1{
		
	esttab using "$workingdir/may7_table6a.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs ///
	title ("`var'") nonumbers mtitles("improvement" "no change" "fall behind")
		}
	
	if `i'>1 & `i'<13{
	esttab using "$workingdir/may7_table6a.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs nomtitles nonumbers ///
	title ("`var'") 
		}
	
	else{
	esttab using "$workingdir/may7_table6a.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitles nonumbers ///
	title ("`var'") 
		}
	local i = `i' + 1
	}
	
	*baseline
	
	local i = 1

	foreach var in $outcomes_mid1 $outcomes_mid2 $outcomes_mid3 {
	
	eststo clear
		
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if g==0, cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if g==1, cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if g==2, cluster(classid)
		
	if `i'==1{
		
	esttab using "$workingdir/may7_table7a.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs ///
	title ("`var'") nonumbers mtitles("improvement" "no change" "fall behind" )
		}
	
	if `i'>1 & `i'<13{
	esttab using "$workingdir/may7_table7a.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs nomtitles nonumbers ///
	title ("`var'") 
		}
	
	else{
	esttab using "$workingdir/may7_table7a.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitles nonumbers ///
	title ("`var'") 
		}
	local i = `i' + 1
	}

,*/

	/**************************************************
				robustness check 
	*************************************************/
	
	/********************************************
	       questions about seat arrangement
	********************************************/
	/*
	use "/Users/gaoyujuan/Desktop/PE/peer effect/1-result/18-1215-difference/dta/all-original.dta",clear
	keep stu_bs_id stu_fn_60 stu_fn_61 stu_fn_61a stu_fn_62 stu_fn_62a stu_fn_63 stu_fn_63a 

	save "$workingdatadir/seat arrangment.dta",replace
	
	use "$finaldir/model.dta",clear
	sort stu_bs_id
	merge n:n stu_bs_id  using "$workingdatadir/seat arrangment.dta"
	drop if _merge==2
	bysort classid:gen n4=_n
	
	*****TA2:whether they can change seat according to their own idea*********

	*按学生统计
	tab stu_fn_63,m
	list stu_fn_63a if stu_fn_63==3
	replace stu_fn_63=1 if stu_fn_63a=="建议"|stu_fn_63a=="见议"|stu_fn_63a=="见意"
	replace stu_fn_63=. if stu_fn_63==3|stu_fn_63==.o
	recode stu_fn_63 (2=0)
	label define yesno 1"Yes" 0"No"
	label values stu_fn_63 yesno
	label var stu_fn_63 "Choose seat"
	asdoc tab stu_fn_63, replace label dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A2: Can students choose seats by their own?) ///
	add(Data Sources: Based on the students’ responses)
	
	*******Table6A:drop if students can choose their own seats*********
	
	eststo clear
	
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_1) i.countyid score_bs $student $family $tea_c if stu_fn_63==0,cluster(classid) first	 
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if stu_fn_63==0,cluster(classid) first
		 
	esttab using "$workingdir/apr28_table6.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes mtitle ("Instrumental Variable (direct distance)" "Instrumental Variable (step distance)") title ("Table 6. Robustness analysis Panel A: Excluding students who can choose their own seats)")

	*********************indictor of seat arrangement******************
	
	*按学生统计
	
	foreach i in 0 1 2 3 4 5{
	gen stu_fn_62_`i'=.
	replace stu_fn_62_`i'=0 if regexm(stu_fn_62,"`i'")==0
	replace stu_fn_62_`i'=1 if regexm(stu_fn_62,"`i'")==1
	}
	
	label var stu_fn_62_0 "Never"
	label var stu_fn_62_1 "Height"
	label var stu_fn_62_2 "Vision"
	label var stu_fn_62_3 "Score"
	label var stu_fn_62_4 "Student character"
	label var stu_fn_62_5 "Other"
	
	foreach i in 0 1 2 3 4 5{
	label values stu_fn_62_`i' yesno
	}
	
	*******************TA3:indicator****************************
	
	asdoc tab stu_fn_62_1 , append dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A3: Indicators for arrange seats throughout the semester (Multiple choice questions?)
	asdoc tab stu_fn_62_2 , append dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A3: Indicators for arrange seats throughout the semester (Multiple choice questions?)
	asdoc tab stu_fn_62_3 , append dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A3: Indicators for arrange seats throughout the semester (Multiple choice questions?)
	asdoc tab stu_fn_62_4 , append dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A3: Indicators for arrange seats throughout the semester (Multiple choice questions?)
	asdoc tab stu_fn_62_5 , append dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A3: Indicators for arrange seats throughout the semester (Multiple choice questions?) ///
	add(Data Sources: Based on the students’ responses)

	******* T6B:drop if seat is arranged by score/personality*****************
	
	
	eststo clear
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_1) i.countyid  score_bs  $student $family $tea_c if stu_fn_62_3==0 & stu_fn_62_4==0,cluster(classid) first
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family  $tea_c if stu_fn_62_3==0 & stu_fn_62_4==0 ,cluster(classid) first
	esttab using "$workingdir/apr28_table6.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitle title ("Panel B: Excluding students whose seats arranged based on academic performance") 
	
	/*****************************************************
				change seat
	******************************************************/

	*****how how change seat***********
	tab stu_fn_60,m
	destring  stu_fn_60,replace
	bysort classid:egen mode_60=mode(stu_fn_60), maxmode
	label var mode_60 "how change seat"
	label define mode_60 0 "Never" 1"1 week" 2"2 weeks" 3"3 weeks" 4"4 weeks" 5"> 4 weeks"
	label values mode_60 mode_60
	*****how to change seat*********************
	tab stu_fn_61,m
	tab stu_fn_61a,m
	replace stu_fn_61=6 if stu_fn_61a=="随机安排"
	bysort classid:egen mode_61=mode(stu_fn_61), maxmode
	br classid stu_fn_61 stu_fn_61a if mode_61==4
	replace mode_61=3 if classid=="130651"|classid=="160941"|classid=="120561"
	replace mode_61=5 if classid=="161841"
	label var mode_61 "how to change seat"
	label define mode_61 0 "Never" 1"Row" 2"Column" 3"Row and Column" 4"other" 5."Group" 6"Random"
	label values mode_61 mode_61

	*不换座位****************
	gen mode_6=0
	replace mode_6=1 if (mode_61==0 | mode_60==0) 
	tab mode_6 if n4==1
	
	/****************************************************
	          T6C-T6D
	****************************************************/
	
	*******************TA4: how often change****************************

	replace mode_60=0 if mode_6==1
	tab mode_60 if n4==1
	asdoc tab mode_60 if n4==1, append label dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A4: How often did the class change seats throughout the semester) ///
	add(Data Sources: Based on the mode of the students’ responses.)
	
	*******************TA5: how to change****************************
	replace mode_61=0 if mode_6==1
	tab mode_61 if n4==1,m
	asdoc tab mode_61 if n4==1, append label dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A5: How did a class change seat throughout the semester) ///
	add(Data Sources: Based on the mode of the students’ responses.)
	
	*******TA6: how long change seat*******
	tab mode_60 if n4==1 
	tab mode_61 if n4==1
	gen week=. 
	replace week=1 if mode_60==1
	replace week=2 if mode_60==2
	replace week=3 if mode_60==3
	replace week=4 if mode_60==4|mode_60==5
	
	gen time=week*a1_max if mode_61==1 |(mode_61==3 & a1_max<a2_max) 
	replace time=week*a2_max if mode_61==2|(mode_61==3 & a1_max>=a2_max) 
	
	tab time if n4==1
	sum time if n4==1
	asdoc tab time if n4==1, append label dec(3) ///
	save($workingdir/apr28_tablea2-6.doc) title(Table A6: How long did the nearby students separate between each other throughout the semester) ///
	add(Data Sources: Based on the mode of the students’ responses; there are 23 classes of students who didn't change seats last semester and 3 classes have no answer.)
	
	
******* T9:keep if time>16*****************

	eststo clear
	
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_1 ) i.countyid score_bs $student $family $tea_c if time>18,cluster(classid) first
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_2 ) i.countyid score_bs $student $family $tea_c if time>18,cluster(classid) first
	
	esttab using "$workingdir/apr28_table6.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nomtitle title ("Panel C: Excluding classes if nearby students could separate with each other during the semester ") 

	 count if time >18 & n4==1
	 


	/************************************************
			  gen comprehensive 
	************************************************/
	
	*gen friend id
	  
	use "$finaldir/model_long_all.dta",clear
	keep stu_bs_id class_mate_id
	bysort stu_bs_id :gen n=_n
	reshape wide class_mate_id, i(stu_bs_id) j(n)
	save "$workingdatadir/6_1.friend_wide.dta",replace

	use "$finaldir/model_long_all.dta",clear
	keep stu_bs_id class_mate_id*
	merge n:1 stu_bs_id using "$workingdatadir/6_1.friend_wide.dta"
	drop _merge
	rename class_mate_id* friend_id*
	rename friend_id class_mate_id
	tostring stu_bs_id,replace
	gen class_mate_id_id=class_mate_id+"_"+stu_bs_id
	duplicates tag class_mate_id_id, gen (dup)
	drop if dup==1
	reshape long friend_id, i(class_mate_id_id) j(n)
	order class_mate_id_id, before (friend_id)
	drop class_mate_id_id
	sort stu_bs_id class_mate_id
	drop if friend_id==""
	drop if class_mate_id==friend_id
	save "$workingdatadir/6_2.friend_friend.dta",replace

	use "$finaldir/model_long_all.dta", clear
	bysort stu_bs_id:gen n=_n
	keep if n==1
	keep stu_bs_id stu_bs_bestfriend1-stu_bs_bestfriend10 score_bs
	rename stu_bs_bestfriend* stu_bs_bestfriend*_m
	rename stu_bs_id class_mate_id
	merge n:n class_mate_id using "$workingdatadir/6_2.friend_friend.dta"
	drop if _merge==1 //未被提名
	drop _merge
	order class_mate_id friend_id  stu_bs_bestfriend*_m ,after (stu_bs_id )

	*whether friend is also friend 
	destring class_mate_id friend_id,replace
	destring stu_bs_bestfriend*_m,replace

	gen s_match_1=0 
	replace s_match_1=1 if friend_id==stu_bs_bestfriend1_m|friend_id==stu_bs_bestfriend2_m|friend_id==stu_bs_bestfriend3_m|friend_id==stu_bs_bestfriend4_m|friend_id==stu_bs_bestfriend5_m| ///
						   friend_id==stu_bs_bestfriend6_m|friend_id==stu_bs_bestfriend7_m|friend_id==stu_bs_bestfriend8_m|friend_id==stu_bs_bestfriend9_m|friend_id==stu_bs_bestfriend10_m
						   
	bysort stu_bs_id:egen match=total(s_match_1) //单向提名
	bysort stu_bs_id:gen N=_N
	gen conhension=match/N 
	keep stu_bs_id conhension 
	bysort stu_bs_id:gen n=_n
	keep if n==1 

	save "$workingdatadir/conhension.dta",replace
	
	
	/**************************************************
    2sls-Heterogeneity analysis for math-arrange policy
	*************************************************/

	use "$finaldir/model.dta",clear
	capture drop _merge
	merge n:n stu_bs_id using "$workingdatadir/conhension.dta" 
	drop _merge
	save "$workingdatadir/result_forhet.dta",replace
	
	use "$workingdatadir/result_forhet.dta",replace
	
	foreach var of varlist stu_bs_age asset tea_age tea_workyear conhension friend_num score_bs_m_sd{
	xtile `var'_d=`var'
	recode `var'_d (1=0)(2=1)
	bysort `var'_d: tab `var'
	}
	
	*neerby
	gen nf_r_d=0 if neer_f_t==0
		replace nf_r_d=1 if neer_f_t>0
	
	*position
	tab a1,m
	bysort classid:egen max_a1=max(a1) if a1!=.
	gen row_a1=0 if a1<=max_a1/3
		replace row_a1=1 if a1>max_a1/3 & a1<=(max_a1/3)*2
		replace row_a1=2 if a1>(max_a1/3)*2 & a1<=max_a1
	gen row_a1_frt_mid=0 if row_a1==0
		replace row_a1_frt_mid=1 if row_a1==1
	gen row_a1_frt_bk=0 if row_a1==0
		replace row_a1_frt_bk=1 if row_a1==2	
	gen row_a1_mid_bk=0 if row_a1==1
		replace row_a1_mid_bk=1 if row_a1==2
	
	global stu_t stu_bs_age_d stu_bs_grade stu_bs_gender female_t_d stu_bs_boarding edu_d asset_d tea_age_d tea_gender tea_educ tea_workyear_d
	global position_t nf_r_d 
	global grop_structure_t conhension_d friend_num_d score_bs_m_sd_d
	
	global stu_t_out stu_bs_age_d0 stu_bs_age_d1 stu_bs_gender0 stu_bs_gender1  female_t_d0 female_t_d1 stu_bs_boarding0 stu_bs_boarding1 ///
		   edu_d0 edu_d1 asset_d0 asset_d1 ///
		   tea_age_d0 tea_age_d1 tea_gender0 tea_gender1 tea_educ0 tea_educ1 tea_workyear_d0 tea_workyear_d1
	global position_t_out nf_r_d0 nf_r_d1
	global grop_structure_out conhension_d0 conhension_d1 friend_num_d0 friend_num_d1 score_bs_m_sd_d0 score_bs_m_sd_d1
	
	/*********************************************
		table 7A group structure
	*********************************************/
	
	eststo clear
	
	foreach var in score_bs_m_sd_d conhension_d {
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if `var'==0, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if `var'==1, cluster(classid)
	}

esttab using "$workingdir/apr28_table7.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes title ("Table7. Heterogeneous analysis Panel A: Study group structure") mtitles("Low diversity" "High diversity" "Low cohesiveness" "High cohesiveness")
 
	/*********************************************
		table7B nf_r_d 
	*********************************************/
	eststo clear
	
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if nf_r_d==0, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if nf_r_d==1, cluster(classid)

esttab using "$workingdir/apr28_table7.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes title ("Panel B: Number of peers in student nearby groups")  mtitles("No peers in student nearby groups" "At least one of peers in student nearby groups")

	/*********************************************
		table 7C D gender Female rate
	*********************************************/
	
	global student stu_bs_age stu_bs_boarding
	
	eststo clear
	
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if stu_bs_gender==0, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if stu_bs_gender==1, cluster(classid)

	esttab using "$workingdir/apr28_table7.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes title ("Panel C: Gender")  mtitles("Female" "Male")

	*female in male vs female group 
	
	gen female_t_d_female=female_t_d
	replace female_t_d_female=. if stu_bs_gender==1
	gen female_t_d_male=female_t_d
	replace female_t_d_male=. if stu_bs_gender==0
	
	eststo clear
	
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if female_t_d==0, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if female_t_d==1, cluster(classid)

	foreach i in 1 0 {
	foreach x in 0 1 {
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if stu_bs_gender==`i' & female_t_d==`x', cluster(classid)
	}
	}
	
	esttab using "$workingdir/apr28_table7.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes title ("Panel D: Female rate") mtitles("Low female rate" "High female rate" "Low female rate" "High female rate" "Low female rate" "High female rate")

	/*********************************************
		table7E F *row ranking and row
	*********************************************/
	global student stu_bs_age stu_bs_gender  stu_bs_boarding
	
	eststo clear
	
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if row_a1==0, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if row_a1==1, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if row_a1==2, cluster(classid)
	
	esttab using "$workingdir/apr28_table7.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes title ("Panel E: Position") mtitles("Front" "Middle" "Back")

	*ranking and row
	
	eststo clear

	foreach i in 0 1 2{
	foreach x in 0 1 2{
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2 ) i.countyid score_bs $student $family $tea_c if row_a1==`x' & score_d1==`i' , cluster(classid)
	}
	}
	esttab using "$workingdir/apr28_table7.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps title ("Panel F: Position across different ranking subgroups") mtitles("Front" "Middle" "Back" "Front" "Middle" "Back" "Front" "Middle" "Back") 

		
	
	/*****************************************************
					Appendix
	******************************************************/
	
	/****************************************************
			   tableA7: seat is random
	*****************************************************/

	use "$finaldir/model_long_all.dta",replace
	
	destring stu_bs_id,replace
	
	bysort stu_bs_id: gen n=_n
	
	xtset stu_bs_id n

	global student_a score_bs_a stu_bs_gender_a  stu_bs_boarding_a
	global family_a  m_educ_a f_educ_a`i' asset_a
	
	xtile d1_d=d1, n(2)
	xtile d2_d=d2, n(2)
	recode d1_d d2_d (1=0)(2=1)


	eststo clear
	
	qui:xtreg d1 $student_a $family_a i.n, fe cluster(classid)
	est sto reg1
	qui:xtreg d1_d $student_a $family_a i.n, fe cluster(classid)
	est sto reg2
	qui:xtreg d2 $student_a $family_a i.n, fe cluster(classid)
	est sto reg3
	qui:xtreg d2_d $student_a $family_a i.n, fe cluster(classid)
	est sto reg4
	
	outreg2 [reg1 reg2 reg3 reg4] using "$workingdir/apr28_tablea7.xls", ///
	excel dec(3) keep ($student_a $family_a) label replace title ("Table A7. seat is random")	
	,
	

	/*****************************************************
		  table A8:teast between friends and no-friends
	*****************************************************/
	 
	
	eststo clear
	foreach var of varlist $student_a $family_a {
	qui:xtreg f_match d1 `var' , fe cluster(classid)
	est sto `var'
	}

	outreg2 [$student_a $family_a] using "$workingdir/apr28_tablea8.xls", ///
	excel dec(3) label replace keep ($student_a $family_a) title ("Table A8. balance test between friends and no-friends") 	
*/
/*
	*********************************************
				*期末还是好朋友*
	*********************************************
	use "/Users/gaoyujuan/Desktop/PE/peer effect/1-result/18-1215-difference/dta/all-original.dta",clear
	keep stu_bs_id classid
	bysort classid:gen n=_n
	reshape wide stu_bs_id, i(classid) j(n)
	save "$workingdatadir/2_1.classidlist.dta",replace

	use "$finaldir/model.dta",clear
	merge n:n classid using "$workingdatadir/2_1.classidlist.dta"
	keep if _merge==3
	keep stu_bs_id* 
	rename stu_bs_id id
	reshape long stu_bs_id, i(id) j(j)
	rename stu_bs_id class_mate_id
	rename id stu_bs_id
	drop j
	drop if class_mate_id==""
	sort stu_bs_id class_mate_id
	save "$workingdatadir/2_2.class_mate_id",replace

	use "/Users/gaoyujuan/Desktop/PE/peer effect/1-result/18-1215-difference/dta/all-original.dta",clear
	keep stu_bs_id classid stu_fn_bestfriend1 stu_fn_bestfriend2 stu_fn_bestfriend3 stu_fn_bestfriend4 stu_fn_bestfriend5 stu_fn_bestfriend6 stu_fn_bestfriend7 stu_fn_bestfriend8 stu_fn_bestfriend9 stu_fn_bestfriend10
	foreach i of numlist 1/10{
	tostring stu_fn_bestfriend`i',replace
	replace stu_fn_bestfriend`i'=classid+stu_fn_bestfriend`i' if stu_fn_bestfriend`i'!=""
	}
	drop classid
	save "$workingdatadir/friend.dta",replace
	
	use "$finaldir/model.dta",clear
	merge n:n stu_bs_id using "$workingdatadir/2_2.class_mate_id"
	keep if _merge==3
	drop _merge
	merge n:n stu_bs_id using "$workingdatadir/friend.dta"
	keep if _merge==3
	drop _merge
	drop if stu_bs_id==class_mate_id
	order class_mate_id,after (stu_bs_id)
	save "$workingdatadir/4.final.dta",replace

	
	/*****************************************************
					gen friend in baseline survey
	*****************************************************/

	gen f_match_fn=0
		replace f_match_fn=1 if class_mate_id==stu_fn_bestfriend1|class_mate_id==stu_fn_bestfriend2|class_mate_id==stu_fn_bestfriend3|class_mate_id==stu_fn_bestfriend4|class_mate_id==stu_fn_bestfriend5| ///
						 class_mate_id==stu_fn_bestfriend6|class_mate_id==stu_fn_bestfriend7|class_mate_id==stu_fn_bestfriend8|class_mate_id==stu_fn_bestfriend9|class_mate_id==stu_fn_bestfriend10			 					 
	
	
	tab f_match f_match_fn
	keep if f_match_fn==1
	bysort stu_bs_id: gen n3=_n
	keep if n3==1 // 1,678
	
	eststo clear
	
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_1 ) i.countyid score_bs $student $family $tea_c ,cluster(classid) first
	qui eststo: ivregress 2sls score_fn (score_bs_m_ave=iv_2 ) i.countyid score_bs $student $family $tea_c ,cluster(classid) first
	
	esttab using "$workingdir/may28_table5_panelD.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nomtitle title ("Panel D: Excluding students if students are not study partners at end of semester ") 
	
	*/
	
	/***************************
	 1-异质性：boarding vs non-boarding student
	 ***************************/
	 use "/Users/gaoyujuan/Desktop/paper/pe/peer effect/0-sample-201712-201804/final/model.dta",clear
	 ,
	 eststo clear
	
	foreach var in score_bs_m_sd_d conhension_d {
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if stu_bs_boarding==0, cluster(classid)
	qui eststo:ivregress 2sls score_fn (score_bs_m_ave=iv_2) i.countyid score_bs $student $family $tea_c if stu_bs_boarding==1, cluster(classid)
	}

esttab using "$workingdir/Jan31_tabler1.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes mtitles("Non-boarding student" "Boarding student" )


/*****************************************************
		  2- test between neighbor and non-neighbor
	*****************************************************/
	 
	use "/Users/gaoyujuan/Desktop/paper/pe/peer effect/0-sample-201712-201804/final/model_long.dta",replace 
	gen near =0
		replace near=1 if d1==1
	
	eststo clear
	foreach var of varlist $student_a $family_a score_fn_a{
	bysort near: egen `var'_mean=mean(`var')
	}
	global student_a_mean score_bs_a_mean stu_bs_gender_a_mean  stu_bs_boarding_a_mean
	global family_a_mean stu_bs_familymember_a_mean m_educ_a_mean f_educ_a_mean asset_a_mean

	keep stu_bs_id near $student_a_mean $family_a_mean score_fn_a_mean
	bysort stu_bs_id:gen n=_n
	keep if n==1
	drop n
	save "$workingdir/near.dta",replace
	

	use "/Users/gaoyujuan/Desktop/paper/pe/peer effect/0-sample-201712-201804/final/model.dta",clear
	merge n:n stu_bs_id using "$workingdir/near.dta"
	

	eststo clear
	foreach var of varlist  $student_a_mean $family_a_mean score_fn_a_mean {
	qui:reg near `var' , cluster(classid)
	est sto `var'
	}

	
	outreg2 [$student_a_mean $family_a_mean score_fn_a_mean] using "$workingdir/Jan29_tabler2.xls", ///
	excel dec(3) label replace keep ($student_a_mean $family_a_mean score_fn_a_mean) title ("Table r2. balance test between nearby and non-nearby student") 	

	/*****************************************************
		  3- compare grade between front and back student
	*****************************************************/
 	use "/Users/gaoyujuan/Desktop/paper/pe/peer effect/0-sample-201712-201804/final/model.dta",clear
	bysort classid:egen max_a1=max(a1) if a1!=.
	gen row_a1=0 if a1<=max_a1/3
		replace row_a1=1 if a1>max_a1/3 & a1<=(max_a1/3)*2
		replace row_a1=2 if a1>(max_a1/3)*2 & a1<=max_a1
	gen row_a1_frt_mid=0 if row_a1==0
		replace row_a1_frt_mid=1 if row_a1==1
	gen row_a1_frt_bk=0 if row_a1==0
		replace row_a1_frt_bk=1 if row_a1==2	
	gen row_a1_mid_bk=0 if row_a1==1
		replace row_a1_mid_bk=1 if row_a1==2
		
	eststo clear
	
	qui: reg score_bs i.row_a1 $student $family, cluster(classid)
	est sto r3
	
	outreg2 [r3] using "$workingdir/Jan29_tabler3.xls", ///
	excel dec(3) label replace keep (i.row_a1 $student $family) title ("Table r3. row and grade") 	
	
	***********************************
	*midoutcomes*
	***********************************
 	use "/Users/gaoyujuan/Desktop/paper/pe/peer effect/0-sample-201712-201804/final/model.dta",clear

	gen study_mathtime_std_bs=study_time_r_bs
	gen stu_group_bs=cooperation_bs

	global student stu_bs_age stu_bs_gender  stu_bs_boarding
	global family stu_bs_familymember m_educ f_educ asset
	global student_m stu_bs_gender_m  stu_bs_boarding_m
	global family_m stu_bs_familymember_m m_educ_m f_educ_m asset_m
	global student_a score_bs_a stu_bs_gender_a  stu_bs_boarding_a
	global family_a stu_bs_familymember_a m_educ_a f_educ_a asset_a
	global tea_c stu_bs_grade5 stu_bs_grade6 tea_age tea_gender tea_educ tea_workyear
	
	global outcomes_mid1 anxiety self_concept intrinsic_motiv instrument_motiv stu_fun_puzzle stu_mathlike distraction interruption ability 
	global outcomes_mid2 study_time_r study_mathtime_std
	global outcomes_mid3 cooperation stu_group
	
	foreach v in bs fn{
	global outcomes_mid1_`v' anxiety_`v' self_concept_`v' intrinsic_motiv_`v' instrument_motiv_`v' stu_fun_puzzle_`v' stu_mathlike_`v' distraction_`v' interruption_`v' ability_`v'
	global outcomes_mid2_`v' study_time_r_`v' study_mathtime_std_`v'
	global outcomes_mid3_`v' cooperation_`v' stu_group_`v'
	}

/*
*endline
local i = 1

	foreach var in $outcomes_mid1 $outcomes_mid2 $outcomes_mid3 {
	
	eststo clear
		
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c , cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c if score_d1==0, cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c if score_d1==1, cluster(classid)
		qui eststo:ivregress 2sls `var'_fn (score_bs_m_ave=iv_2) i.countyid `var'_bs score_bs $student $family $tea_c if score_d1==2, cluster(classid)
		
		if `i'==1{
		
	esttab using "$workingdir/Feb262023_table5.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs ///
	title ("`var'") mtitles("All samples" "Student in bottom tercile" "Student in middle tercile" "Student in top tercile")
		}
	
	if `i'>1 & `i'<13{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs nomtitles nonumbers ///
	title ("`var'") 
		}
	
	else{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitles nonumbers ///
	title ("`var'") 
		}
	local i = `i' + 1
	}
	*/
	*MHT
	rename score_bs_m_ave i

	rwolf $outcomes_mid1_fn $outcomes_mid2_fn $outcomes_mid3_fn, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	rwolf $outcomes_mid1_fn $outcomes_mid2_fn $outcomes_mid3_fn if score_d1==0, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	rwolf $outcomes_mid1_fn $outcomes_mid2_fn $outcomes_mid3_fn if score_d1==1, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	rwolf $outcomes_mid1_fn $outcomes_mid2_fn $outcomes_mid3_fn if score_d1==2, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)

	*baseline
	/*
local i = 1

	foreach var in $outcomes_mid1 $outcomes_mid2 $outcomes_mid3 {
	
	eststo clear
		
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c , cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c if score_d1==0, cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c if score_d1==1, cluster(classid)
		qui eststo:ivregress 2sls `var'_bs (score_bs_m_ave=iv_2) i.countyid $student $family $tea_c if score_d1==2, cluster(classid)
		
		if `i'==1{
		
	esttab using "$workingdir/Feb262023_table5.csv", replace label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs ///
	title ("`var'") mtitles("All samples" "Student in bottom tercile" "Student in middle tercile" "Student in top tercile")
		}
	
	if `i'>1 & `i'<13{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes noobs nomtitles nonumbers ///
	title ("`var'") 
		}
	
	else{
	esttab using "$workingdir/Feb262023_table5.csv", append label star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) keep(score_bs_m_ave) ar2 nogaps nonotes nomtitles nonumbers ///
	title ("`var'") 
		}
	local i = `i' + 1
	}
	*/
	
	*MHT
	rename score_bs_m_ave i

	rwolf $outcomes_mid1_bs $outcomes_mid2_bs $outcomes_mid3_bs, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	rwolf $outcomes_mid1_bs $outcomes_mid2_bs $outcomes_mid3_bs if score_d1==0, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	rwolf $outcomes_mid1_bs $outcomes_mid2_bs $outcomes_mid3_bs if score_d1==1, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	rwolf $outcomes_mid1_bs $outcomes_mid2_bs $outcomes_mid3_bs if score_d1==2, indepvar(i) controls(i.countyid score_bs $student $family $tea_c) method(ivregress) iv(iv_2) vce(cluster classid)
	
	**************************************************
					*rank change*
	**************************************************
	/*
	tab score_d1_fn score_d1 ,  column  lrchi2 
	
		score_d1_fn              score_d1
	          0          1	2	Total
				
	0        473        265	137	875 
	51.64      25.24	13.84	29.60 
				
	1        300        462	311	1,073 
	32.75      44.00	31.41	36.30 
				
	2        143        323	542	1,008 
	15.61      30.76	54.75	34.10 
				
	Total        916      1,050	990	2,956 
	100.00     100.00	100.00	100.00 

	likelihood	ratio chi2(4) = 482.9092	Pr = 0.000
*/

	