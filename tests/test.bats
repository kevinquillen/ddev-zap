setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-zap
  mkdir -p $TESTDIR
  export PROJNAME=test-zap
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

health_checks() {
  ddev restart >/dev/null
  # ZAP with WebSwing takes a while to start up
  sleep 30
  # Check that the ZAP container is running
  docker ps | grep "ddev-${PROJNAME}-zap"
  # Check that the WebSwing interface is accessible
  curl -sf "http://127.0.0.1:8080/zap/" || curl -sf "https://${PROJNAME}.ddev.site:8443/zap/"
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart >/dev/null
  health_checks
}

# Release tests are only run when the RELEASE_TAG environment variable is set
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get ${RELEASE_TAG} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${RELEASE_TAG}
  ddev restart >/dev/null
  health_checks
}
