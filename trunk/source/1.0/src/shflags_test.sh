#! /bin/sh
# vim:et:ft=sh:sts=2:sw=2
#
# Copyright 2008 Kate Ward. All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
#
# Author: kate.ward@forestent.com (Kate Ward)
#
# shFlags unit test wrapper

MY_NAME=`basename $0`
MY_PATH=`dirname $0`

SHELLS='/bin/sh /bin/bash /bin/dash /bin/ksh /bin/pdksh /bin/zsh'
TESTS=''
for test in shflags_test_[a-z]*.sh; do
  TESTS="${TESTS} ${test}"
done

# load test helpers
. ./shflags_test_helpers

usage()
{
  echo "usage: ${MY_NAME} [-e key=val ...] [-s shell(s)] [-t test(s)]"
}

# process command line flags
while getopts 'e:hs:t:' opt; do
  case ${opt} in
    e)
      key=`expr "${OPTARG}" : '\([^=]*\)='`
      val=`expr "${OPTARG}" : '[^=]*=\(.*\)'`
      if [ -z "${key}" -o -z "${val}" ]; then
        usage
        exit 1
      fi
      eval "${key}='${val}'"
      export ${key}
      env="${env:+${env} }${key}"
      ;;
    h) usage; exit 0 ;;
    s) shells=${OPTARG} ;;
    t) tests=${OPTARG} ;;
    *) usage; exit 1 ;;
  esac
done
shift `expr ${OPTIND} - 1`

# fill shells and/or tests
shells=${shells:-${SHELLS}}
tests=${tests:-${TESTS}}

# error checking
if [ -z "${tests}" ]; then
  th_error 'no tests found to run; exiting'
  exit 1
fi

cat <<EOF
#------------------------------------------------------------------------------
# System data
#

# test run info
shells="${shells}"
tests="${tests}"
EOF
for key in ${env}; do
  eval "echo \"${key}=\$${key}\""
done
echo

# output system data
echo "# system info"
echo "$ date"
date

echo "$ uname -mprsv"
uname -mprsv

#
# run tests
#

for shell in ${shells}; do
  echo

  # check for existance of shell
  if [ ! -x ${shell} ]; then
    th_warn "unable to run tests with the ${shell} shell"
    continue
  fi

  cat <<EOF

#------------------------------------------------------------------------------
# Running the test suite with ${shell}
#
EOF

  shell_name=`basename ${shell}`
  shell_opts=''
  case ${shell_name} in
    bash) echo; ${shell} --version; ;;
    dash) ;;
    ksh)
      version=`${shell} --version exit 2>&1`
      exitVal=$?
      if [ ${exitVal} -eq 2 ]; then
        echo
        echo "${version}"
      fi
      ;;
    pdksh) ;;
    zsh)
      shell_opts='-o shwordsplit --'
      echo
      ${shell} --version
      ;;
  esac

  # execute the tests
  for suite in ${tests}; do
    suiteName=`expr "${suite}" : 'gflags_test_\(.*\).sh'`
    echo
    echo "--- Executing the '${suiteName}' test suite ---" >&2
    ( exec ${shell} ${shell_opts} ./${suite}; )
  done
done