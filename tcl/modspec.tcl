##########################################################################

# MODSPEC.TCL, module specification procedures
# Copyright (C) 2016-2022 Xavier Delaruelle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##########################################################################

# Define procedure to get how many parts between passed name and mod are equal
# Adapt procedure code whether icase is enabled or disabled
proc defineModStartNbProc {icase} {
   set procname modStartNbProc
   if {$icase} {
      append procname Icase
   }
   # define proc if not done yet or if it was defined for another context
   if {[info procs modStartNb] eq {} || $::g_modStartNb_proc ne $procname} {
      if {[info exists ::g_modStartNb_proc]} {
         # remove existing debug trace if any
         trace remove execution modStartNb enter reportTraceExecEnter
         rename ::modStartNb ::$::g_modStartNb_proc
      }
      rename ::$procname ::modStartNb
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution modStartNb enter reportTraceExecEnter
      }
      set ::g_modStartNb_proc $procname
   }
}

# alternative definitions of modStartNb proc
proc modStartNbProc {mod name} {
   # first compare against name's parent chunk by chunk
   set modname [getModuleNameFromVersSpec $name]
   if {$modname eq {.}} {
      set i 0
      set imax 0
   } else {
      set namesplit [split $modname /]
      set modsplit [split $mod /]
      set imax [tcl::mathfunc::min [llength $namesplit] [llength $modsplit]]
      for {set i 0} {$i < $imax} {incr i} {
         if {![string equal [lindex $modsplit $i] [lindex $namesplit $i]]} {
            break
         }
      }
   }
   # if name's parent matches check if full name also matches
   if {$i == $imax && [modEq $name $mod eqstart]} {
      incr i
   }
   return $i
}
proc modStartNbProcIcase {mod name} {
   set modname [getModuleNameFromVersSpec $name]
   if {$modname eq {.}} {
      set i 0
      set imax 0
   } else {
      set namesplit [split $modname /]
      set modsplit [split $mod /]
      set imax [if {[llength $namesplit] < [llength $modsplit]} {llength\
         $namesplit} {llength $modsplit}]
      for {set i 0} {$i < $imax} {incr i} {
         if {![string equal -nocase [lindex $modsplit $i] [lindex $namesplit\
            $i]]} {
            break
         }
      }
   }
   if {$i == $imax && [modEq $name $mod eqstart]} {
      incr i
   }
   return $i
}

# Define procedure to compare module names set as array keys against pattern.
# Adapt procedure code whether implicit_default is enabled or disabled
proc defineGetEqArrayKeyProc {icase extdfl impdfl} {
   set procname getEqArrayKeyProc
   if {$impdfl} {
      append procname Impdfl
   }

   # define proc if not done yet or if it was defined for another context
   if {[info procs getEqArrayKey] eq {} || $::g_getEqArrayKey_proc ne\
      $procname} {
      if {[info exists ::g_getEqArrayKey_proc]} {
         # remove existing debug trace if any
         trace remove execution getEqArrayKey enter reportTraceExecEnter
         rename ::getEqArrayKey ::$::g_getEqArrayKey_proc
      }
      rename ::$procname ::getEqArrayKey
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution getEqArrayKey enter reportTraceExecEnter
      }
      set ::g_getEqArrayKey_proc $procname
   }

   # also define modEq which is called by getEqArrayKey
   defineModEqProc $icase $extdfl
}

# alternative definitions of getEqArrayKey proc
proc getEqArrayKeyProcImpdfl {arrname name} {
   set icase [isIcase]
   upvar $arrname arr

   # extract single module specified if any
   lassign [getModuleVersSpec $name] mod modname
   # check name eventual icase match
   set mod [getArrayKey arr [string trimright $mod /] $icase]

   if {$mod ne {} && [info exists arr($mod)]} {
      set match $mod
   } else {
      set mlist {}
      foreach elt [array names arr] {
         if {[modEq $name $elt]} {
            lappend mlist $elt
         }
      }
      if {[llength $mlist] == 1} {
         set match [lindex $mlist 0]
      # in case multiple modules match query, check directory default and
      # return it if it is part of match list, elsewhere return highest result
      } elseif {[llength $mlist] > 1} {
         # get corresponding icase parent directory
         set pname [getArrayKey arr $modname $icase]
         if {[info exists arr($pname)]} {
            set dfl $pname/[lindex $arr($pname) 1]
         }
         # resolve symbolic version entries
         foreach elt $mlist {
            if {[lindex $arr($elt) 0] eq {version}} {
               lappend mrlist [lindex $arr($elt) 1]
            } else {
               lappend mrlist $elt
            }
         }
         if {[info exists dfl] && $dfl in $mrlist} {
            set match $dfl
         } else {
            set match [lindex [lsort -dictionary $mrlist] end]
         }
      }
   }
   if {[info exists match]} {
      reportDebug "key '$match' in array '$arrname' matches '$name'"
      set name $match
   }
   return $name
}
proc getEqArrayKeyProc {arrname name} {
   set icase [isIcase]
   upvar $arrname arr

   lassign [getModuleVersSpec $name] mod modname cmpspec versspec modnamere\
      modescglob modroot variantlist modnvspec
   # check name eventual icase match
   set mod [getArrayKey arr [string trimright $mod /] $icase]

   if {$mod ne {} && [info exists arr($mod)]} {
      set match $mod
   } else {
      set mlist {}
      foreach elt [array names arr] {
         if {[modEq $name $elt]} {
            lappend mlist $elt
         }
      }
      # must have a default part of result even if only one result
      if {[llength $mlist] >= 1} {
         # get corresponding icase parent directory
         set pname [getArrayKey arr $modname $icase]
         if {[info exists arr($pname)]} {
            set dfl $pname/[lindex $arr($pname) 1]
         }
         # resolve symbolic version entries
         foreach elt $mlist {
            if {[lindex $arr($elt) 0] eq {version}} {
               lappend mrlist [lindex $arr($elt) 1]
            } else {
               lappend mrlist $elt
            }
         }
         if {[info exists dfl] && $dfl in $mrlist} {
            set match $dfl
         } else {
            # raise error as no default part of result
            upvar retlist retlist
            set retlist [list {} $modnvspec $name none "No default version\
               defined for '$name'"]
         }
      }
   }
   if {[info exists match]} {
      reportDebug "key '$match' in array '$arrname' matches '$name'"
      set name $match
   }
   return $name
}

# Check a module name does match query at expected depth level when indepth
# search is disabled. Define procedure on the fly to adapt its
# code to indepth configuration option and querydepth and test mode params.
proc defineDoesModMatchAtDepthProc {indepth querydepth test} {
   set procprops $indepth:$querydepth:$test

   # define proc if not done yet or if it was defined for another context
   if {[info procs doesModMatchAtDepth] eq {} ||\
      $::g_doesModMatchAtDepth_procprops ne $procprops} {
      if {[info exists ::g_doesModMatchAtDepth_procprops]} {
         # remove existing debug trace if any
         trace remove execution doesModMatchAtDepth enter reportTraceExecEnter
         rename ::doesModMatchAtDepth {}
      }
      set ::g_doesModMatchAtDepth_procprops $procprops

      # define optimized procedure
      if {$indepth} {
         set atdepth {$mod}
      } else {
         set atdepth "\[join \[lrange \[split \$mod /\] 0 $querydepth\] /\]"
      }
      proc doesModMatchAtDepth {mod} "return \[modEqStatic $atdepth $test *\]"
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution doesModMatchAtDepth enter reportTraceExecEnter
      }
   }
}

# Define procedure to check module version equals pattern. Adapt procedure
# code whether icase and extended_default are enabled or disabled
proc defineModVersCmpProc {icase extdfl} {
   set procname modVersCmpProc
   if {$icase} {
      append procname Icase
   }
   if {$extdfl} {
      append procname Extdfl
   }

   # define proc if not done yet or if it was defined for another context
   if {[info procs modVersCmp] eq {} || $::g_modVersCmp_proc ne $procname} {
      if {[info exists ::g_modVersCmp_proc]} {
         # remove existing debug trace if any
         trace remove execution modVersCmp enter reportTraceExecEnter
         rename ::modVersCmp ::$::g_modVersCmp_proc
      }
      rename ::$procname ::modVersCmp
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution modVersCmp enter reportTraceExecEnter
      }
      set ::g_modVersCmp_proc $procname
   }
}

# alternative definitions of modVersCmp proc
proc modVersCmpProc {cmpspec versspec modvers test {psuf {}}} {
   set ret 0
   switch -- $cmpspec {
      in {
         # check each verspec in list until match
         foreach inspec $versspec {
            lassign $inspec incmp invers
            if {[set ret [modVersCmp $incmp $invers $modvers $test $psuf]]} {
               break
            }
         }
      }
      eq {
         append versspec $psuf
         if {$test eq {eqstart}} {
            set ret [string equal -length [string length $versspec/]\
               $versspec/ $modvers/]
         } else {
            set ret [string $test $versspec $modvers]
         }
      }
      ge {
         # as we work here on a version range: psuf suffix is ignored, checks
         # are always extended_default-enabled (as 1.2 includes 1.2.12 for
         # instance) and equal, eqstart and match tests are equivalent
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $versspec] != -1 || [string match $versspec.* $modvers])}]
      }
      le {
         # 'ge' comment also applies here
         set ret [expr {[isVersion $modvers] && ([versioncmp $versspec\
            $modvers] != -1 || [string match $versspec.* $modvers])}]
      }
      be {
         # 'ge' comment also applies here
         lassign $versspec lovers hivers
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $lovers] != -1 || [string match $lovers.* $modvers]) &&\
            ([versioncmp $hivers $modvers] != -1 || [string match\
            $hivers.* $modvers])}]
      }
   }
   return $ret
}
proc modVersCmpProcIcase {cmpspec versspec modvers test {psuf {}}} {
   set ret 0
   switch -- $cmpspec {
      in {
         foreach inspec $versspec {
            lassign $inspec incmp invers
            if {[set ret [modVersCmp $incmp $invers $modvers $test $psuf]]} {
               break
            }
         }
      }
      eq {
         append versspec $psuf
         if {$test eq {eqstart}} {
            set ret [string equal -nocase -length [string length $versspec/]\
               $versspec/ $modvers/]
         } else {
            set ret [string $test -nocase $versspec $modvers]
         }
      }
      ge {
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $versspec] != -1 || [string match -nocase $versspec.* $modvers])}]
      }
      le {
         set ret [expr {[isVersion $modvers] && ([versioncmp $versspec\
            $modvers] != -1 || [string match -nocase $versspec.* $modvers])}]
      }
      be {
         lassign $versspec lovers hivers
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $lovers] != -1 || [string match $lovers.* $modvers]) &&\
            ([versioncmp $hivers $modvers] != -1 || [string match -nocase\
            $hivers.* $modvers])}]
      }
   }
   return $ret
}
proc modVersCmpProcExtdfl {cmpspec versspec modvers test {psuf {}}} {
   set ret 0
   switch -- $cmpspec {
      in {
         foreach inspec $versspec {
            lassign $inspec incmp invers
            if {[set ret [modVersCmp $incmp $invers $modvers $test $psuf]]} {
               break
            }
         }
      }
      eq {
         append versspec $psuf
         if {$test eq {eqstart}} {
            set ret [string equal -length [string length $versspec/]\
               $versspec/ $modvers/]
         } else {
            set ret [string $test $versspec $modvers]
         }
         if {!$ret && [string match $versspec.* $modvers]} {
            set ret 1
         }
      }
      ge {
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $versspec] != -1 || [string match $versspec.* $modvers])}]
      }
      le {
         set ret [expr {[isVersion $modvers] && ([versioncmp $versspec\
            $modvers] != -1 || [string match $versspec.* $modvers])}]
      }
      be {
         lassign $versspec lovers hivers
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $lovers] != -1 || [string match $lovers.* $modvers]) &&\
            ([versioncmp $hivers $modvers] != -1 || [string match\
            $hivers.* $modvers])}]
      }
   }
   return $ret
}
proc modVersCmpProcIcaseExtdfl {cmpspec versspec modvers test {psuf {}}} {
   set ret 0
   switch -- $cmpspec {
      in {
         foreach inspec $versspec {
            lassign $inspec incmp invers
            if {[set ret [modVersCmp $incmp $invers $modvers $test $psuf]]} {
               break
            }
         }
      }
      eq {
         append versspec $psuf
         if {$test eq {eqstart}} {
            set ret [string equal -nocase -length [string length $versspec/]\
               $versspec/ $modvers/]
         } else {
            set ret [string $test -nocase $versspec $modvers]
         }
         if {!$ret && [string match -nocase $versspec.* $modvers]} {
            set ret 1
         }
      }
      ge {
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $versspec] != -1 || [string match -nocase $versspec.* $modvers])}]
      }
      le {
         set ret [expr {[isVersion $modvers] && ([versioncmp $versspec\
            $modvers] != -1 || [string match -nocase $versspec.* $modvers])}]
      }
      be {
         lassign $versspec lovers hivers
         set ret [expr {[isVersion $modvers] && ([versioncmp $modvers\
            $lovers] != -1 || [string match $lovers.* $modvers]) &&\
            ([versioncmp $hivers $modvers] != -1 || [string match -nocase\
            $hivers.* $modvers])}]
      }
   }
   return $ret
}

proc modVariantCmp {pvrlist modvrlist {missmeandfl 0}} {
   set ret 1
   if {$missmeandfl} {
      foreach {modvrname modvrval modvrisdfl} $modvrlist {
         set modvrarr($modvrname) $modvrval
         set modvrisdflarr($modvrname) $modvrisdfl
      }
   } else {
      array set modvrarr $modvrlist
   }
   foreach pvr $pvrlist {
      set pvrarr([lindex $pvr 0]) [lindex $pvr 1]
   }

   # no match if a specified variant is not found among module variants or if
   # the value differs
   foreach vrname [array names pvrarr] {
      if {![info exists modvrarr($vrname)] || $pvrarr($vrname) ne\
         $modvrarr($vrname)} {
         set ret 0
         break
      }
   }

   # if an unset variant on pattern means variant default value pattern and
   # mod are not equal if variant unset on pattern and non-default value is
   # set for variant on mod
   if {$missmeandfl} {
      foreach vrname [array names modvrisdflarr] {
         if {!$modvrisdflarr($vrname) && ![info exists pvrarr($vrname)]} {
            set ret 0
            break
         }
      }
   }

   return $ret
}

# Setup a hardwire version of modEq procedure called modEqStatic. This
# optimized procedure already knows the module pattern to compare to, whose
# specification has already been resolved at procedure definition time, which
# saves lot of processing time.
# modEqStatic does not compare against loaded modules so it has no need to
# compare variants set on module specification
proc defineModEqStaticProc {icase extdfl modspec} {
   set procprops $icase:$extdfl:$modspec

   # define proc if not done yet or if it was defined for another context
   if {[info procs modEqStatic] eq {} || $::g_modEqStatic_procprops ne\
      $procprops} {
      if {[info exists ::g_modEqStatic_procprops]} {
         # remove existing debug trace if any
         trace remove execution modEqStatic enter reportTraceExecEnter
         rename ::modEqStatic {}
      } else {
         # also define modVersCmp which is called by modEqStatic
         defineModVersCmpProc $icase $extdfl
      }
      set ::g_modEqStatic_procprops $procprops

      # define optimized procedure
      lassign [getModuleVersSpec $modspec] pmod pmodname cmpspec versspec\
         pmodnamere pmodescglob
      # trim dup trailing / char and adapt pmod suffix if it starts with /
      if {[string index $pmod end] eq {/}} {
         set pmod [string trimright $pmod /]/
         set endwslash 1
      } else {
         set endwslash 0
      }
      set nocasearg [expr {$icase ? {-nocase } : {}}]
      set pmodnameslen [string length $pmodname/]
      if {$pmod ne {} || $modspec eq {}} {
         set procbody "
            set pmod {$pmod}
            if {\$psuf ne {}} {
               if {$endwslash && \[string index \$psuf 0\] eq {/}} {
                  append pmod \[string range \$psuf 1 end\]
               } else {
                  append pmod \$psuf
               }
            }
            if {\$test eq {eqstart}} {
               set ret \[string equal $nocasearg-length \[string length\
                  \$pmod/\] \$pmod/ \$mod/\]
            } else {
               if {\$test eq {matchin}} {
                  set test match
                  set pmod *\$pmod
               }
               set ret \[string \$test $nocasearg\$pmod \$mod\]
            }"
         if {$extdfl} {
            append procbody "
               if {!\$ret && \[string first / \$pmod\] != -1} {
                  if {\$test eq {match}} {
                     set pmodextdfl \$pmod.*
                  } else {
                     set pmodextdfl {$pmodescglob.*}
                  }
                  set ret \[string match $nocasearg\$pmodextdfl \$mod\]
               }"
         }
      } else {
         set procbody "
            set pmodname {$pmodname}
            set pmodnamere {$pmodnamere}
            if {\$test eq {matchin}} {
               set test match
               if {\$pmodnamere ne {}} {
                  set pmodnamere .*\$pmodnamere
               } else {
                  set pmodnamere {.*$pmodname}
               }
            }
            if {(\$pmodnamere ne {} && \$test eq {match} && \[regexp\
               $nocasearg (^\$pmodnamere)/ \$mod/ rematch pmodname\]) ||\
               \[string equal $nocasearg -length $pmodnameslen {$pmodname/}\
               \$mod/\]} {
               set modvers \[string range \$mod \[string length \$pmodname/\]\
                  end\]
               set ret \[modVersCmp {$cmpspec} {$versspec} \$modvers \$test\
                  \$psuf\]
            } else {
               set ret 0
            }"
      }
      append procbody "
         return \$ret"
      proc modEqStatic {mod {test equal} {psuf {}}} $procbody
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution modEqStatic enter reportTraceExecEnter
      }
   }
}

# Define procedure to check module name equals pattern. Adapt procedure
# code whether icase and extended_default are enabled or disabled
proc defineModEqProc {icase extdfl {loadedmod 0}} {
   set procname modEqProc
   if {$icase} {
      append procname Icase
   }
   if {$extdfl} {
      append procname Extdfl
   }

   # define proc if not done yet or if it was defined for another context
   if {[info procs modEq] eq {} || $::g_modEq_proc ne $procname} {
      if {[info exists ::g_modEq_proc]} {
         # remove existing debug trace if any
         trace remove execution modEq enter reportTraceExecEnter
         rename ::modEq ::$::g_modEq_proc
      }
      rename ::$procname ::modEq
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution modEq enter reportTraceExecEnter
      }
      set ::g_modEq_proc $procname
   }

   # also define modVersCmp which is called by modEq
   defineModVersCmpProc $icase $extdfl

   # comparing against loaded modules requires to know their alternative names
   if {$loadedmod} {
      cacheCurrentModules
   }
}

# alternative definitions of modEq proc
proc modEqProc {pattern mod {test equal} {trspec 1} {ismodlo 0} {vrcmp 0}\
   {modvrlist 0} {psuf {}}} {
   # extract specified module name from name and version spec
   if {$trspec} {
      lassign [getModuleVersSpec $pattern] pmod pmodname cmpspec versspec\
         pmodnamere pmodescglob pmodroot pvrlist
   } else {
      set pmod $pattern
   }
   # trim dup trailing / char and adapt pmod suffix if it starts with /
   if {[string index $pmod end] eq {/}} {
      set pmod [string trimright $pmod /]/
      set endwslash 1
   } else {
      set endwslash 0
   }
   # get alternative names if mod is loading(1) or loaded(2)
   set altlist [switch -- $ismodlo {
      4 {getAllModuleResolvedName $mod 0 {} 1}
      3 {getLoadedAltAndSimplifiedName $mod}
      2 {getLoadedAltname $mod}
      1 {getAllModuleResolvedName $mod}
      0 {list}}]
   # fetch variant definition from spec if not loaded/loading
   if {$vrcmp && $ismodlo == 0} {
      set modvrlist [getVariantList $mod 0 0 1]
      set mod [getModuleNameAndVersFromVersSpec $mod]
   }
   # specified module can be translated in a simple mod name/vers or is empty
   if {$pmod ne {} || $pattern eq {}} {
      if {$psuf ne {}} {
         if {$endwslash && [string index $psuf 0] eq {/}} {
            append pmod [string range $psuf 1 end]
         } else {
            append pmod $psuf
         }
      }
      if {$test eq {eqstart}} {
         set ret [string equal -length [string length $pmod/] $pmod/ $mod/]
         # apply comparison to alternative names if any and no match for mod
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string equal -length [string length $pmod/]\
                  $pmod/ $alt/]]} {
                  break
               }
            }
         }
      } else {
         # contains test
         if {$test eq {matchin}} {
            set test match
            set pmod *$pmod
         } elseif {$test eq {eqspec}} {
            set test equal
         }
         set ret [string $test $pmod $mod]
         # apply comparison to alternative names if any and no match for mod
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string $test $pmod $alt]]} {
                  break
               }
            }
         }
      }
   } elseif {$test eq {eqspec}} {
      # test equality against all version described in spec (list or range
      # boundaries), trspec is considered enabled and psuf empty
      foreach pmod [getAllModulesFromVersSpec $pattern] {
         if {[set ret [string equal $pmod $mod]]} {
            break
         }
      }
   } else {
      # contains test
      if {$test eq {matchin}} {
         set test match
         if {$pmodnamere ne {}} {
            set pmodnamere .*$pmodnamere
         } else {
            set pmodnamere .*$pmodname
         }
      }
      # for more complex specification, first check if module name matches
      # use a regexp test if module name contains wildcard characters
      if {($pmodnamere ne {} && $test eq {match} && [regexp (^$pmodnamere)/\
         $mod/ rematch pmodname]) || [string equal -length [string length\
         $pmodname/] $pmodname/ $mod/]} {
         # then compare versions
         set modvers [string range $mod [string length $pmodname/] end]
         set ret [modVersCmp $cmpspec $versspec $modvers $test $psuf]
      } else {
         set ret 0
      }
      # apply comparison to alternative names if any and no match for mod
      if {!$ret && [llength $altlist] > 0} {
         foreach alt $altlist {
            if {($pmodnamere ne {} && $test eq {match} && [regexp\
               (^$pmodnamere)/ $alt/ rematch pmodname]) || [string equal\
               -length [string length $pmodname/] $pmodname/ $alt/]} {
               # then compare versions
               set modvers [string range $alt [string length $pmodname/] end]
               if {[set ret [modVersCmp $cmpspec $versspec $modvers $test\
                  $psuf]]} {
                  break
               }
            }
         }
      }
   }
   # check if variant specified matches those of selected loaded/ing module
   if {$ret && $vrcmp && $ismodlo != 3 && [llength $pvrlist] > 0} {
      if {$modvrlist eq {0}} {
         set modvrlist [getVariantList $mod]
      }
      set ret [modVariantCmp $pvrlist $modvrlist]
   # when comparing collection content, variant mis means variant default val
   } elseif {$ret && $vrcmp && $ismodlo == 3} {
      set ret [modVariantCmp $pvrlist [getVariantList $mod 3] 1]
   }
   return $ret
}
proc modEqProcIcase {pattern mod {test equal} {trspec 1} {ismodlo 0} {vrcmp\
   0} {modvrlist 0} {psuf {}}} {
   if {$trspec} {
      lassign [getModuleVersSpec $pattern] pmod pmodname cmpspec versspec\
         pmodnamere pmodescglob pmodroot pvrlist
   } else {
      set pmod $pattern
   }
   if {[string index $pmod end] eq {/}} {
      set pmod [string trimright $pmod /]/
      set endwslash 1
   } else {
      set endwslash 0
   }
   set altlist [switch -- $ismodlo {
      4 {getAllModuleResolvedName $mod 0 {} 1}
      3 {getLoadedAltAndSimplifiedName $mod}
      2 {getLoadedAltname $mod}
      1 {getAllModuleResolvedName $mod}
      0 {list}}]
   if {$vrcmp && $ismodlo == 0} {
      set modvrlist [getVariantList $mod 0 0 1]
      set mod [getModuleNameAndVersFromVersSpec $mod]
   }
   if {$pmod ne {} || $pattern eq {}} {
      if {$psuf ne {}} {
         if {$endwslash && [string index $psuf 0] eq {/}} {
            append pmod [string range $psuf 1 end]
         } else {
            append pmod $psuf
         }
      }
      if {$test eq {eqstart}} {
         set ret [string equal -nocase -length [string length $pmod/] $pmod/\
            $mod/]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string equal -nocase -length [string length\
                  $pmod/] $pmod/ $alt/]]} {
                  break
               }
            }
         }
      } else {
         # contains test
         if {$test eq {matchin}} {
            set test match
            set pmod *$pmod
         } elseif {$test eq {eqspec}} {
            set test equal
         }
         set ret [string $test -nocase $pmod $mod]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string $test -nocase $pmod $alt]]} {
                  break
               }
            }
         }
      }
   } elseif {$test eq {eqspec}} {
      # test equality against all version described in spec (list or range
      # boundaries), trspec is considered enabled and psuf empty
      foreach pmod [getAllModulesFromVersSpec $pattern] {
         if {[set ret [string equal -nocase $pmod $mod]]} {
            break
         }
      }
   } else {
      # contains test
      if {$test eq {matchin}} {
         set test match
         if {$pmodnamere ne {}} {
            set pmodnamere .*$pmodnamere
         } else {
            set pmodnamere .*$pmodname
         }
      }
      # for more complex specification, first check if module name matches
      # use a regexp test if module name contains wildcard characters
      if {($pmodnamere ne {} && $test eq {match} && [regexp -nocase\
         (^$pmodnamere)/ $mod/ rematch pmodname]) || [string equal -nocase\
         -length [string length $pmodname/] $pmodname/ $mod/]} {
         # then compare versions
         set modvers [string range $mod [string length $pmodname/] end]
         set ret [modVersCmp $cmpspec $versspec $modvers $test $psuf]
      } else {
         set ret 0
      }
      if {!$ret && [llength $altlist] > 0} {
         foreach alt $altlist {
            if {($pmodnamere ne {} && $test eq {match} && [regexp -nocase\
               (^$pmodnamere)/ $alt/ rematch pmodname]) || [string equal\
               -nocase -length [string length $pmodname/] $pmodname/ $alt/]} {
               # then compare versions
               set modvers [string range $alt [string length $pmodname/] end]
               if {[set ret [modVersCmp $cmpspec $versspec $modvers $test\
                  $psuf]]} {
                  break
               }
            }
         }
      }
   }
   if {$ret && $vrcmp && $ismodlo != 3 && [llength $pvrlist] > 0} {
      if {$modvrlist eq {0}} {
         set modvrlist [getVariantList $mod]
      }
      set ret [modVariantCmp $pvrlist $modvrlist]
   } elseif {$ret && $vrcmp && $ismodlo == 3} {
      set ret [modVariantCmp $pvrlist [getVariantList $mod 3] 1]
   }
   return $ret
}
proc modEqProcExtdfl {pattern mod {test equal} {trspec 1} {ismodlo 0} {vrcmp\
   0} {modvrlist 0} {psuf {}}} {
   if {$trspec} {
      lassign [getModuleVersSpec $pattern] pmod pmodname cmpspec versspec\
         pmodnamere pmodescglob pmodroot pvrlist
   } else {
      set pmod $pattern
   }
   if {[string index $pmod end] eq {/}} {
      set pmod [string trimright $pmod /]/
      set endwslash 1
   } else {
      set endwslash 0
   }
   set altlist [switch -- $ismodlo {
      4 {getAllModuleResolvedName $mod 0 {} 1}
      3 {getLoadedAltAndSimplifiedName $mod}
      2 {getLoadedAltname $mod}
      1 {getAllModuleResolvedName $mod}
      0 {list}}]
   if {$vrcmp && $ismodlo == 0} {
      set modvrlist [getVariantList $mod 0 0 1]
      set mod [getModuleNameAndVersFromVersSpec $mod]
   }
   if {$pmod ne {} || $pattern eq {}} {
      if {$psuf ne {}} {
         if {$endwslash && [string index $psuf 0] eq {/}} {
            append pmod [string range $psuf 1 end]
         } else {
            append pmod $psuf
         }
      }
      if {$test eq {eqstart}} {
         set ret [string equal -length [string length $pmod/] $pmod/ $mod/]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string equal -length [string length $pmod/]\
                  $pmod/ $alt/]]} {
                  break
               }
            }
         }
      } else {
         # contains test
         if {$test eq {matchin}} {
            set test match
            set pmod *$pmod
         } elseif {$test eq {eqspec}} {
            set test equal
            set eqspec 1
         }
         set ret [string $test $pmod $mod]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string $test $pmod $alt]]} {
                  break
               }
            }
         }
      }
      # try the extended default match if not root module and not eqspec test
      if {![info exists eqspec] && !$ret && [string first / $pmod] != -1} {
         if {$test eq {match}} {
            set pmodextdfl $pmod.*
         } else {
            set pmodextdfl $pmodescglob.*
         }
         set ret [string match $pmodextdfl $mod]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string match $pmodextdfl $alt]]} {
                  break
               }
            }
         }
      }
   } elseif {$test eq {eqspec}} {
      # test equality against all version described in spec (list or range
      # boundaries), trspec is considered enabled and psuf empty
      foreach pmod [getAllModulesFromVersSpec $pattern] {
         if {[set ret [string equal $pmod $mod]]} {
            break
         }
      }
   } else {
      # contains test
      if {$test eq {matchin}} {
         set test match
         if {$pmodnamere ne {}} {
            set pmodnamere .*$pmodnamere
         } else {
            set pmodnamere .*$pmodname
         }
      }
      # for more complex specification, first check if module name matches
      # use a regexp test if module name contains wildcard characters
      if {($pmodnamere ne {} && $test eq {match} && [regexp (^$pmodnamere)/\
         $mod/ rematch pmodname]) || [string equal -length [string length\
         $pmodname/] $pmodname/ $mod/]} {
         # then compare versions
         set modvers [string range $mod [string length $pmodname/] end]
         set ret [modVersCmp $cmpspec $versspec $modvers $test $psuf]
      } else {
         set ret 0
      }
      if {!$ret && [llength $altlist] > 0} {
         foreach alt $altlist {
            if {($pmodnamere ne {} && $test eq {match} && [regexp\
               (^$pmodnamere)/ $alt/ rematch pmodname]) || [string equal\
               -length [string length $pmodname/] $pmodname/ $alt/]} {
               # then compare versions
               set modvers [string range $alt [string length $pmodname/] end]
               if {[set ret [modVersCmp $cmpspec $versspec $modvers $test\
                  $psuf]]} {
                  break
               }
            }
         }
      }
   }
   if {$ret && $vrcmp && $ismodlo != 3 && [llength $pvrlist] > 0} {
      if {$modvrlist eq {0}} {
         set modvrlist [getVariantList $mod]
      }
      set ret [modVariantCmp $pvrlist $modvrlist]
   } elseif {$ret && $vrcmp && $ismodlo == 3} {
      set ret [modVariantCmp $pvrlist [getVariantList $mod 3] 1]
   }
   return $ret
}
proc modEqProcIcaseExtdfl {pattern mod {test equal} {trspec 1} {ismodlo 0}\
   {vrcmp 0} {modvrlist 0} {psuf {}}} {
   if {$trspec} {
      lassign [getModuleVersSpec $pattern] pmod pmodname cmpspec versspec\
         pmodnamere pmodescglob pmodroot pvrlist
   } else {
      set pmod $pattern
   }
   if {[string index $pmod end] eq {/}} {
      set pmod [string trimright $pmod /]/
      set endwslash 1
   } else {
      set endwslash 0
   }
   set altlist [switch -- $ismodlo {
      4 {getAllModuleResolvedName $mod 0 {} 1}
      3 {getLoadedAltAndSimplifiedName $mod}
      2 {getLoadedAltname $mod}
      1 {getAllModuleResolvedName $mod}
      0 {list}}]
   if {$vrcmp && $ismodlo == 0} {
      set modvrlist [getVariantList $mod 0 0 1]
      set mod [getModuleNameAndVersFromVersSpec $mod]
   }
   if {$pmod ne {} || $pattern eq {}} {
      if {$psuf ne {}} {
         if {$endwslash && [string index $psuf 0] eq {/}} {
            append pmod [string range $psuf 1 end]
         } else {
            append pmod $psuf
         }
      }
      if {$test eq {eqstart}} {
         set ret [string equal -nocase -length [string length $pmod/] $pmod/\
            $mod/]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string equal -nocase -length [string length\
                  $pmod/] $pmod/ $alt/]]} {
                  break
               }
            }
         }
      } else {
         # contains test
         if {$test eq {matchin}} {
            set test match
            set pmod *$pmod
         } elseif {$test eq {eqspec}} {
            set test equal
            set eqspec 1
         }
         set ret [string $test -nocase $pmod $mod]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string $test -nocase $pmod $alt]]} {
                  break
               }
            }
         }
      }
      # try the extended default match if not root module and not eqspec test
      if {![info exists eqspec] && !$ret && [string first / $pmod] != -1} {
         if {$test eq {match}} {
            set pmodextdfl $pmod.*
         } else {
            set pmodextdfl $pmodescglob.*
         }
         set ret [string match -nocase $pmodextdfl $mod]
         if {!$ret && [llength $altlist] > 0} {
            foreach alt $altlist {
               if {[set ret [string match -nocase $pmodextdfl $alt]]} {
                  break
               }
            }
         }
      }
   } elseif {$test eq {eqspec}} {
      # test equality against all version described in spec (list or range
      # boundaries), trspec is considered enabled and psuf empty
      foreach pmod [getAllModulesFromVersSpec $pattern] {
         if {[set ret [string equal -nocase $pmod $mod]]} {
            break
         }
      }
   } else {
      # contains test
      if {$test eq {matchin}} {
         set test match
         if {$pmodnamere ne {}} {
            set pmodnamere .*$pmodnamere
         } else {
            set pmodnamere .*$pmodname
         }
      }
      # for more complex specification, first check if module name matches
      # use a regexp test if module name contains wildcard characters
      if {($pmodnamere ne {} && $test eq {match} && [regexp -nocase\
         (^$pmodnamere)/ $mod/ rematch pmodname]) || [string equal -nocase\
         -length [string length $pmodname/] $pmodname/ $mod/]} {
         # then compare versions
         set modvers [string range $mod [string length $pmodname/] end]
         set ret [modVersCmp $cmpspec $versspec $modvers $test $psuf]
      } else {
         set ret 0
      }
      if {!$ret && [llength $altlist] > 0} {
         foreach alt $altlist {
            if {($pmodnamere ne {} && $test eq {match} && [regexp -nocase\
               (^$pmodnamere)/ $alt/ rematch pmodname]) || [string equal\
               -nocase -length [string length $pmodname/] $pmodname/ $alt/]} {
               # then compare versions
               set modvers [string range $alt [string length $pmodname/] end]
               if {[set ret [modVersCmp $cmpspec $versspec $modvers $test\
                  $psuf]]} {
                  break
               }
            }
         }
      }
   }
   if {$ret && $vrcmp && $ismodlo != 3 && [llength $pvrlist] > 0} {
      if {$modvrlist eq {0}} {
         set modvrlist [getVariantList $mod]
      }
      set ret [modVariantCmp $pvrlist $modvrlist]
   } elseif {$ret && $vrcmp && $ismodlo == 3} {
      set ret [modVariantCmp $pvrlist [getVariantList $mod 3] 1]
   }
   return $ret
}

# analyze module version specified within module specification
proc parseModuleVersionSpecifier {modspec} {
   set invalidversspec 0
   set invalidversrange 0
   set islist [expr {[string first , $modspec] != -1}]
   set isrange [expr {[string first : $modspec] != -1}]
   # no deep version specification allowed
   if {[string first / $modspec] != -1} {
      set invalidversspec 1
   # ',' separates multiple versions
   } elseif {$islist} {
      set cmpspec in
      set inspeclist [split $modspec ,]
      # empty element in list is erroneous
      set invalidversspec [expr {[lsearch -exact $inspeclist {}] != -1}]
      if {!$invalidversspec} {
         # recursive call to check each element in list (can be range, etc)
         foreach inspec $inspeclist {
            lappend versspec [parseModuleVersionSpecifier $inspec]
         }
      }
   # ':' separates range elements
   } elseif {$isrange} {
      set versspec [split $modspec :]
      set lovers [lindex $versspec 0]
      set hivers [lindex $versspec 1]
      if {[llength $versspec] != 2 || ($lovers eq {} && $hivers eq {})} {
         set invalidversspec 1
      } elseif {($lovers ne {} && ![isVersion $lovers]) || ($hivers ne {} &&\
         ![isVersion $hivers])} {
         set invalidversrange 1
      # greater or equal
      } elseif {$hivers eq {}} {
         set cmpspec ge
         set versspec $lovers
      # lower or equal
      } elseif {$lovers eq {}} {
         set cmpspec le
         set versspec $hivers
      # between or equal
      } elseif {[versioncmp $lovers $hivers] == 1} {
         set invalidversrange 1
      } else {
         set cmpspec be
      }
   } else {
      set cmpspec eq
      set versspec $modspec
   }
   if {$invalidversspec} {
      knerror "Invalid version specifier '$modspec'"
   }
   if {$invalidversrange} {
      knerror "Invalid version range '$modspec'"
   }
   return [list $cmpspec $versspec]
}

# Define procedure to parse modulefile specification passed as argument
# Adapt procedure code whether advanced_version_spec is enabled or disabled
proc defineParseModuleSpecificationProc {advverspec} {
   set procname parseModuleSpecificationProc
   if {$advverspec} {
      append procname AdvVersSpec
      # resolved configured variant shortcut
      getConf variant_shortcut
   }
   # define proc if not done yet or if it was defined for another context
   if {[info procs parseModuleSpecification] eq {} ||\
      $::g_parseModuleSpecification_proc ne $procname} {
      if {[info exists ::g_parseModuleSpecification_proc]} {
         # remove existing debug trace if any
         trace remove execution parseModuleSpecification enter\
            reportTraceExecEnter
         rename ::parseModuleSpecification\
            ::$::g_parseModuleSpecification_proc
      }
      rename ::$procname ::parseModuleSpecification
      # set debug trace if verbosity is set to debug2 or higher
      if {[isVerbosityLevel debug2]} {
         trace add execution parseModuleSpecification enter\
            reportTraceExecEnter
      }
      set ::g_parseModuleSpecification_proc $procname
   }
}

# when advanced_version_spec option is enabled, parse argument list to set in
# a global context version specification of modules passed as argument.
# specification may vary whether it comes from the ml or another command.
proc parseModuleSpecificationProc {mlspec args} {
   # skip arg parse if proc was already call with same arg set by an upper
   # proc. check all args to ensure current arglist does not deviate from
   # what was previously parsed
   foreach arg $args {
      if {![info exists ::g_moduleVersSpec($arg)]} {
         set need_parse 1
         break
      }
   }
   if {![info exists need_parse]} {
      return $args
   }

   set unarglist [list]
   set arglist [list]

   foreach arg $args {
      if {$mlspec && [string index $arg 0] eq {-}} {
         set modname [string range $arg 1 end]
         set mlunload 1
      } else {
         set modname $arg
         set mlunload 0
      }
      # keep arg enclosed if composed of several words
      if {[string first { } $modname] != -1} {
         set modarg "{$modname}"
      } else {
         set modarg $modname
      }
      # record spec, especially needed if arg is enclosed
      setModuleVersSpec $modarg $modname eq {} {} {}
      # append to unload list if ml spec and - prefix used
      if {$mlunload} {
         lappend unarglist $modarg
      } else {
         lappend arglist $modarg
      }
   }

   if {$mlspec} {
      return [list $unarglist $arglist]
   } else {
      return $arglist
   }

}
proc parseModuleSpecificationProcAdvVersSpec {mlspec args} {
   foreach arg $args {
      if {![info exists ::g_moduleVersSpec($arg)]} {
         set need_parse 1
         break
      }
   }
   if {![info exists need_parse]} {
      return $args
   }

   set mlunload 0
   set nextmlunload 0
   set arglist [list]
   set unarglist [list]
   set vrlist [list]
   set vridx -1
   foreach arg $args {
      # set each specification element as separate word but preserve space
      # character in each arg
      set previ 0
      set curarglist {}
      for {set i 1} {$i < [string length $arg]} {incr i} {
         set c [string index $arg $i]
         switch -- $c {
            @ - ~ {
               lappend curarglist [string range $arg $previ [expr {$i - 1}]]
               set previ $i
            }
            + {
               # allow one or more '+' char at end of module name if not
               # followed by non-special character (@, ~ or /)
               set nexti [expr {$i + 1}]
               if {$nexti < [string length $arg]} {
                  switch -- [string index $arg $nexti] {
                     @ - + - ~ - / {}
                     default {
                        lappend curarglist [string range $arg $previ [expr\
                           {$i - 1}]]
                        set previ $i
                     }
                  }
               }
            }
            default {
               # check if a variant shortcut matches
               if {[info exists ::g_shortcutVariant($c)]} {
                  lappend curarglist [string range $arg $previ [expr {$i - 1}]]
                  set previ $i
               }
            }
         }
      }
      lappend curarglist [string range $arg $previ [expr {$i - 1}]]

      # parse each specification element
      foreach curarg $curarglist {
         set vrisbool 0
         set c [string index $curarg 0]
         switch -- $c {
            @ {
               set modspec [string range $curarg 1 end]
               lassign [parseModuleVersionSpecifier $modspec] cmpspec versspec
               continue
            }
            + {
               set curarg [string range $curarg 1 end]
               append curarg =1
               set vrisbool 1
            }
            - {
               set curarg [string range $curarg 1 end]
               if {$mlspec} {
                  set nextmlunload 1
               } else {
                  append curarg =0
                  set vrisbool 1
               }
            }
            ~ {
               set curarg [string range $curarg 1 end]
               append curarg =0
               set vrisbool 1
            }
            default {
               # translate shortcut in variant name in arg
               if {[info exists ::g_shortcutVariant($c)]} {
                  set curarg [string replace $curarg 0 0\
                     $::g_shortcutVariant($c)=]
               }
            }
         }

         switch -glob -- $curarg {
            *=* {
               # extract valued-variant spec
               set vrsepidx [string first = $curarg]
               set vrname [string range $curarg 0 [expr {$vrsepidx - 1}]]
               set vrvalue [string range $curarg [expr {$vrsepidx + 1}] end]

               if {$vrname eq {}} {
                  knerror "No variant name defined in argument '$curarg'"
               }
               # check no other = character is found in argument
               if {[string last = $curarg] != $vrsepidx} {
                  knerror "Invalid variant specification '$arg'"
               }
               # replace previous value for variant if already set
               if {[info exists vrnamearr($vrname)]} {
                  lreplace $vrlist $vrnamearr($vrname) $vrnamearr($vrname)
               } else {
                  incr vridx
               }
               # translate boolean vrvalue in canonical boolean
               if {!$vrisbool && [string is boolean -strict $vrvalue] &&\
                  ![string is integer -strict $vrvalue]} {
                  set vrisbool 1
                  set vrvalue [string is true -strict $vrvalue]
               }
               # save variant name and value
               set vrnamearr($vrname) $vridx
               lappend vrlist [list $vrname $vrvalue $vrisbool]
            }
            default {
               # save previous mod version spec and transformed arg if any
               if {[info exists modarglist]} {
                  set modarg [join $modarglist]
                  if {![info exists cmpspec]} {
                     set cmpspec eq
                     set versspec {}
                  }
                  if {[info exists modname] && ($modname ne {} || $modspec\
                     eq {})} {
                     setModuleVersSpec $modarg $modname $cmpspec $versspec\
                        $modspec $vrlist
                     # rework args to have 1 str element for whole mod spec
                     # append to unload list if ml spec and - prefix used
                     if {$mlunload} {
                        lappend unarglist $modarg
                     } else {
                        lappend arglist $modarg
                     }
                  } else {
                     knerror "No module name defined in argument '$modarg'"
                  }
                  unset modarglist
                  set vrlist [list]
                  array unset vrnamearr
                  set vridx -1
                  unset cmpspec versspec
               }
               set mlunload $nextmlunload
               set nextmlunload 0
               set modname $curarg
               set modspec {}
            }
         }
      }

      # keep arg enclosed if composed of several words
      if {[string first { } $arg] != -1} {
         lappend modarglist "{$arg}"
      } else {
         lappend modarglist $arg
      }
   }
   # transform last args
   set modarg [join $modarglist]
   if {[info exists modname] && ($modname ne {} || $modspec eq {})} {
      if {![info exists cmpspec]} {
         set cmpspec eq
         set versspec {}
      }
      setModuleVersSpec $modarg $modname $cmpspec $versspec $modspec $vrlist
      # rework args to have 1 string element for whole module spec
      # append to unload list if ml spec and - prefix used
      if {$mlunload || $nextmlunload} {
         lappend unarglist $modarg
      } else {
         lappend arglist $modarg
      }
   } else {
      knerror "No module name defined in argument '$modarg'"
   }

   if {$mlspec} {
      return [list $unarglist $arglist]
   } else {
      return $arglist
   }
}

proc setModuleVersSpec {modarg modname cmpspec versspec rawversspec\
   variantlist} {
   # translate @loaded version into currently loaded mod matching modname
   if {$cmpspec eq {eq} && $versspec eq {loaded}} {
      if {[set lmmod [getLoadedMatchingName $modname]] ne {}} {
         set modname [file dirname $lmmod]
         set versspec [file tail $lmmod]
         set variantlist [getVariantList $lmmod 2]
      } else {
         knerror "No loaded version found for '$modname' module"
      }
   }
   # save module root name
   set modroot [lindex [file split $modname] 0]
   # save module single designation if any and module name
   if {$versspec eq {}} {
      set mod $modname
      set modname [file dirname $modname]
   } else {
      set modname [string trimright $modname /]
      if {$cmpspec ne {eq}} {
         set mod {}
      } else {
         set mod $modname/$versspec
      }
   }
   # save a regexp-ready version of modname (apply
   # non-greedy quantifier to '*', to avoid matching final
   # '/' in string comparison
   set modnamere [string map {. \\. + \\+ * .*? ? .} $modname]
   if {$modname eq $modnamere} {
      set modnamere {}
   }
   # save a glob-special-chars escaped version of mod
   set modescglob [string map {* \\* ? \\?} $mod]

   # save module name and version specification (without variant specs)
   if {$mod eq {} && $rawversspec ne {} && $modname ne {.}} {
      set modnvspec ${modname}@${rawversspec}
   } else {
      set modnvspec $mod
   }

   reportDebug "Set module '$mod' (escglob '$modescglob'),  module name\
      '$modname' (re '$modnamere'), module root '$modroot', version cmp\
      '$cmpspec', version(s) '$versspec', variant(s) '$variantlist' and\
      module name version spec '$modnvspec' for argument '$modarg'"
   set ::g_moduleVersSpec($modarg) [list $mod $modname $cmpspec $versspec\
      $modnamere $modescglob $modroot $variantlist $modnvspec]
}

proc getModuleVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      return $::g_moduleVersSpec($modarg)
   } else {
      return [list $modarg [file dirname $modarg] {} {} {} [string map {* \\*\
         ? \\?} $modarg] [lindex [file split $modarg] 0] {} $modarg]
   }
}

# get module name from module name and version spec if parsed
proc getModuleNameFromVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      lassign $::g_moduleVersSpec($modarg) mod modname
   } else {
      set modname [file dirname $modarg]
   }
   return $modname
}

# get module root name from module name and version spec if parsed
proc getModuleRootFromVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      set modroot [lindex $::g_moduleVersSpec($modarg) 6]
   } else {
      set modroot [lindex [file split $modarg] 0]
   }
   return $modroot
}

# translate module name version spec to return all modules mentioned
proc getAllModulesFromVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      lassign $::g_moduleVersSpec($modarg) mod modname cmpspec versspec
      if {$mod eq {} && $cmpspec eq {in}} {
         # loop around each spec in list
         foreach inspec $versspec {
            lassign $inspec incmp invers
            foreach vers $invers {
               lappend modlist $modname/$vers
            }
         }
      } elseif {$mod eq {} && $cmpspec ne {eq}} {
         foreach vers $versspec {
            lappend modlist $modname/$vers
         }
      } else {
         # add empty mod specification if cmpspec is 'eq'
         lappend modlist $mod
      }
   } else {
      lappend modlist $modarg
   }

   return $modlist
}

# translate module name version spec to return one module mentioned
proc getOneModuleFromVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      lassign $::g_moduleVersSpec($modarg) mod modname cmpspec versspec
      if {$mod eq {} && $cmpspec eq {in}} {
         set inspec [lindex $versspec 0]
         lassign $inspec incmp invers
         set mod $modname/[lindex $invers 0]
      } elseif {$mod eq {} && $cmpspec ne {eq}} {
         set mod $modname/[lindex $versspec 0]
      }
   } else {
      set mod $modarg
   }

   return $mod
}

# translate module name version spec to return the list of variant mentioned
proc getVariantListFromVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      set variantlist [lindex $::g_moduleVersSpec($modarg) 7]
   } else {
      set variantlist {}
   }
   return $variantlist
}

# get module name and version from version spec if parsed
proc getModuleNameAndVersFromVersSpec {modarg} {
   if {[info exists ::g_moduleVersSpec($modarg)]} {
      set modnvspec [lindex $::g_moduleVersSpec($modarg) 8]
   } else {
      set modnvspec $modarg
   }
   return $modnvspec
}

# ;;; Local Variables: ***
# ;;; mode:tcl ***
# ;;; End: ***
# vim:set tabstop=3 shiftwidth=3 expandtab autoindent:
