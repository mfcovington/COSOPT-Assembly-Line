# COSOPT Assembly Line

```sh
OUT_DIR=          # Path to the output directory
COUNT_FILE_IN=    # Path to the tab-delimited counts file to be used for input
COSOPT_OUT_FILE=  # Output path and filename (will be tab-delimted)
BIN_DIR=          # Path to 'COSOPT-Assembly-Line/bin/'

$BIN_DIR/cosopt-formatter.pl -o $OUT_DIR $COUNT_FILE_IN
cd $OUT_DIR
wine cmd /c doit.bat > cosopt.log 2> cosopt.err
$BIN_DIR/cosopt-deformatter.pl session.op4 $COSOPT_OUT_FILE
```
