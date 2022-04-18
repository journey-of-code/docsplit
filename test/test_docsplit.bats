# Run the tests in this file by calling this from the repositories root:
# test/bats/bin/bats test/test_docsplit.bats
# More documentation about bats can be found here:
# https://bats-core.readthedocs.io/en/stable/

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # make executables in src/ visible to PATH
  PATH="$DIR/../:$PATH"
}

@test "Without parameters usage info is printed" {
  run docsplit.sh
  [ "$status" -eq 0 ]
  assert_output --partial 'Usage: docsplit.sh input.pdf output'
  assert_output --partial 'Splits one large pdf into pieces.'
}
