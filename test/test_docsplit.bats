# Run the tests in this file by calling this from the repositories root:
# test/bats/bin/bats test/test_docsplit.bats
# More documentation about bats can be found here:
# https://bats-core.readthedocs.io/en/stable/
# Or a little bit more hands-on:
# https://opensource.com/article/19/2/testing-bash-bats
# To comment out a test, you can add this as first line in the test:
# skip "skipmessage"

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
  # Clean up
  rm -Rf "$TEST_DIR"
}

@test "Parameter tests" {
  usage_string='Usage: docsplit.sh [options] input.pdf output'
  # script should fail if called without paramters
  run docsplit.sh
  assert_failure
  assert_output --partial "$usage_string"
  # script should not fail if called with help
  run docsplit.sh -h
  assert_success
  assert_output --partial "$usage_string"
  run docsplit.sh --help
  assert_success
  assert_output --partial "$usage_string"
  # bad parameter should be reported
  run docsplit.sh -h --xyz
  assert_failure
  assert_output --partial "unrecognized option '--xyz'"
  # version should be printed
  run docsplit.sh --version
  assert_success
  assert_output "docsplit 0.1"
  # require two parameters
  run docsplit.sh a
  assert_failure
  run docsplit.sh a b c
  assert_failure
}

@test "Check file requirements" {
  touch "$TEST_DIR/file1.pdf"
  [ -e "$TEST_DIR/file1.pdf" ]
  touch "$TEST_DIR/file2.pdf"
  [ -e "$TEST_DIR/file2.pdf" ]
  run docsplit.sh "$TEST_DIR/non_existing_file.pdf" "$TEST_DIR/file"
  assert_output --partial 'The first parameter has to be a pdf that exists!'
  assert_failure # script should not fail if called with help
  run docsplit.sh "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_output --partial 'No files with a name like'
  assert_output --partial 'file1.pdf'
  assert_output --partial 'file2.pdf'
  assert_failure # script should not fail if called with help
}

@test "Check noop output" {
  run docsplit.sh --noop "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_line --regexp 'gs_command -dFirstPage=1 -dLastPage=1.*file.00123.pdf'
  assert_line --regexp 'gs_command -dFirstPage=2 -dLastPage=3.*file.00124.pdf'
  assert_line --regexp 'gs_command -dFirstPage=4 -sOutput.*file.00125.pdf'
}

@test 'Check PDF splitting' {
  run docsplit.sh "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  [ -e "$TEST_DIR/file.00123.pdf" ]
  [ -e "$TEST_DIR/file.00124.pdf" ]
  [ -e "$TEST_DIR/file.00125.pdf" ]
}

@test 'Check whitespace filenames' {
  run cp "$DIR/data/Simple.pdf" "$TEST_DIR/whitespace file.pdf"
  assert_success
  [ -e "$TEST_DIR/whitespace file.pdf" ]
  run docsplit.sh "$TEST_DIR/whitespace file.pdf" "$TEST_DIR/file out"
  assert_success
  [ -e "$TEST_DIR/file out.00123.pdf" ]
  [ -e "$TEST_DIR/file out.00124.pdf" ]
  [ -e "$TEST_DIR/file out.00125.pdf" ]
}

@test 'Check intermediate output' {
  run docsplit.sh --pages "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_output '1:123,2:124,4:125'
}

@test 'Check command line regex' {
  # To try regexes:
  # pdfgrep -no -P "$regex" data/Simple.pdf
  run docsplit.sh --pages --regex '(?<=[^0-9]00)[0-9]{3}(?=[^0-9])' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_output '1:123,2:124,4:125'
  run docsplit.sh --pages --regex '00123' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_output '1:00123'
  run docsplit.sh --pages --regex 'Text on' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_output '1:Text on,2:Text on,3:Text on,4:Text on'
  run docsplit.sh --pages --regex '(?<=Text on)' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_output '1:,2:,3:,4:'
}

@test 'Check page input' {
  run docsplit.sh --noop --pages="1:1,2:2,3:4" "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  run docsplit.sh --noop --pages="1:1,2:2,3:2" "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_failure
  assert_line --partial "file.00002.pdf' (from page 3)"
  run docsplit.sh --noop --pages="1:1,1:2,3:3" "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_failure
  assert_line --partial "page '1' would result in two different output files."
  run docsplit.sh --noop --pages="1:1,2:2,2:3" "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_failure
  assert_line --partial "page '2' would result in two different output files."
}

@test 'Check execution from page input' {
  run docsplit.sh --pages="1:1,2:2,3:4" "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  [ -e "$TEST_DIR/file.00001.pdf" ]
  [ -e "$TEST_DIR/file.00002.pdf" ]
  [ ! -e "$TEST_DIR/file.00003.pdf" ]
  [ -e "$TEST_DIR/file.00004.pdf" ]
}

@test 'Check omitting of divider pages' {
  run docsplit.sh --noop --dividers --page="1:doc1,3:doc2" "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_line --partial "-dFirstPage=2 -dLastPage=2"
  assert_line --partial "-dFirstPage=4 -sOutputFile"
}

@test 'Check auto-increment' {
  run docsplit.sh --noop --autoincrement --regex '(?<=Text on)' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_line --partial "file.00001.pdf"
  assert_line --partial "file.00002.pdf"
  assert_line --partial "file.00003.pdf"
  assert_line --partial "file.00004.pdf"
  run docsplit.sh --noop --autoincrement=100 --regex '(?<=Text on)' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_success
  assert_line --partial "file.00100.pdf"
  assert_line --partial "file.00101.pdf"
  assert_line --partial "file.00102.pdf"
  assert_line --partial "file.00103.pdf"
  run docsplit.sh --noop --autoincrement=100 --regex '(?<=(First|Third))' "$DIR/data/Simple.pdf" "$TEST_DIR/file"
  assert_line --partial "file.00100.pdf"
  assert_line --partial "file.00101.pdf"
}
