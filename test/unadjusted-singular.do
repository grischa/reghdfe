noi cscript "reghdfe: ols with absorb(_n)" adofile reghdfe
* this means everything is absorbed by the FEs

* Dataset
	sysuse auto
	gen i = _n

	local included_e ///
		scalar: N rmse tss rss mss r2 df_r df_m /// r2_a F ll ll_0
		matrix: trim_b trim_V ///
		macros: wexp wtype

	local included_e2 ///
		scalar: N rmse tss rss r2 df_r df_m r2_a ll ll_0 r2_a /// F (mss df_m is reported as 0.00 by areg; see bugreport enail)
		macros: wexp wtype

	local included_e3 ///
		scalar: N rmse tss rss r2 df_r df_m r2_a ll ll_0 r2_a F ///  F (mss df_m is reported as 0.00 by areg; see bugreport enail)
		macros: wexp wtype


* [TEST] All of Y of X absorbed

	local lhs price
	local rhs weight length
	local absvars i
	fvunab tmp : `rhs'
	local K : list sizeof tmp
	
	* 1. Run benchmark
	areg `lhs' `rhs', absorb(`absvars')
	trim_cons
	local bench_df_a = e(df_a)
	storedresults save benchmark e()
	
	* 2. Run reghdfe
	reghdfe `lhs' `rhs', absorb(`absvars') keepsingletons verbose(-1)
	notrim
	storedresults compare benchmark e(), tol(1e-12) include(`included_e')
	assert `bench_df_a'==e(df_a)-1
	assert e(r2_a)==.
	assert e(F)==.
	assert e(ll)==.
	assert e(ll_0)==.

	* Done!

	storedresults drop benchmark


* [TEST] All of Xs absorbed

	local lhs price
	local rhs 32.turn 43.turn 51.turn
	local absvars turn
	fvunab tmp : `rhs'
	local K : list sizeof tmp
	
	* 1. Run benchmark
	areg `lhs' `rhs', absorb(`absvars')
	matrix list e(b)
	matrix list e(V)
	trim_cons
	local bench_df_a = e(df_a)
	storedresults save benchmark e()
	
	* 2. Run reghdfe
	reghdfe `lhs' `rhs', absorb(`absvars') keepsingletons verbose(-1)
	notrim
	storedresults compare benchmark e(), tol(1e-12) include(`included_e2')
	assert e(df_m)==0
	assert `bench_df_a'==e(df_a)-1
	assert e(F)==.
	assert e(ll)==e(ll_0)
	assert e(ll)<.


* [TEST] Some X absorbed

	local lhs price
	local rhs 32.turn gear 51.turn
	local absvars turn
	fvunab tmp : `rhs'
	local K : list sizeof tmp
	
	* 1. Run benchmark
	di "areg `lhs' `rhs', absorb(`absvars')"
	areg `lhs' `rhs', absorb(`absvars')
	assert _b[32.turn]==0
	assert _b[51.turn]==0
	loc b = _b[gear_ratio]
	loc se = _se[gear_ratio]
	local bench_df_a = e(df_a)
	storedresults save benchmark e()
	
	* 2. Run reghdfe
	reghdfe `lhs' `rhs', absorb(`absvars') keepsingletons verbose(-1)
	assert e(df_m)==1
	cap assert _b[32.turn]==0
	assert c(rc)==111 // not found; excluded before st_data()
	assert _b[51.turn]==0
	assert reldif(`b', _b[gear_ratio]) < 1e-8
	assert reldif(`se',  _se[gear_ratio]) < 1e-8
	storedresults compare benchmark e(), tol(1e-12) include(`included_e3')
	assert `bench_df_a'==e(df_a)-1

	* Done!

	storedresults drop benchmark


exit
