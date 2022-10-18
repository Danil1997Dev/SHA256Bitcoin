set_global_assignment -entity "cv_pll" -library "lib_cv_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "cv_pll" -library "lib_cv_pll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "cv_pll" -library "lib_cv_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_cv_pll" -name SPD_FILE [file join $::quartus(sip_path) "cv_pll.spd"]

set_global_assignment -library "lib_cv_pll" -name MISC_FILE [file join $::quartus(sip_path) "cv_pll_sim/cv_pll.vo"]
