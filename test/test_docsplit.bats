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
  # Create temp directory
  # omit the -p parameter to create a temporal directory in the default location
  TEST_DIR=$(mktemp -d -p "$DIR")
  touch "$TEST_DIR/existing_file.pdf"
}

function teardown() {
  # Delete stuff in test/output
  rm -Rf "$TEST_DIR"
  # a=1
}

@test "Parameter tests" {
  usage_string='Usage: docsplit.sh [options] input.pdf output'
  # script should fail if called without paramters
  run docsplit.sh
  [[ $status -eq 1 ]]
  assert_output --partial "$usage_string"
  # script should not fail if called with help
  run docsplit.sh -h
  [[ $status -eq 0 ]]
  assert_output --partial "$usage_string"
  run docsplit.sh --help
  [[ $status -eq 0 ]]
  assert_output --partial "$usage_string"
  # version should be printed
  run docsplit.sh --version
  [[ $status -eq 0 ]]
  assert_output "docsplit 0.1"
  # require two parameters
  run docsplit.sh a
  [[ $status -eq 1 ]]
  run docsplit.sh a b c
  [[ $status -eq 1 ]]
}

@test "Check file requirements" {
  touch "$TEST_DIR/file1.pdf"
  [ -e "$TEST_DIR/file1.pdf" ]
  touch "$TEST_DIR/file2.pdf"
  [ -e "$TEST_DIR/file2.pdf" ]
  run docsplit.sh "$TEST_DIR/non_existing_file.pdf" "$TEST_DIR/file"
  assert_output --partial 'The first parameter has to be a pdf that exists!'
  [ "$status" -eq 1 ] # script should not fail if called with help
  run docsplit.sh "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_output --partial 'No files with a name like'
  assert_output --partial 'file1.pdf'
  assert_output --partial 'file2.pdf'
  [ "$status" -eq 1 ] # script should not fail if called with help
}

@test "Check noop output" {
  run docsplit.sh --noop "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  [ "$status" -eq 0 ]
  assert_line --regexp 'gs_command -dFirstPage=1 -dLastPage=1.*file.00123.pdf'
  assert_line --regexp 'gs_command -dFirstPage=2 -dLastPage=3.*file.00124.pdf'
  assert_line --regexp 'gs_command -dFirstPage=4 -sOutput.*file.00125.pdf'
}

@test 'Check PDF splitting' {
  run docsplit.sh "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  [ "$status" -eq 0 ]
  [ -e "$TEST_DIR/file.00123.pdf" ]
  [ -e "$TEST_DIR/file.00124.pdf" ]
  [ -e "$TEST_DIR/file.00125.pdf" ]
}

