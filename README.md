# COSOPT Assembly Line

The COSOPT Assembly Line does the following:

- Converts expression data into COSOPT input files
- Runs COSOPT
- Converts COSOPT output into a more user-friendly format


## COSOPT Requires Wine or Windows

Although [COSOPT was written by Marty Straume](http://www.ncbi.nlm.nih.gov/pubmed/15063650) to run on Microsoft Windows, it can be run on OS X, Linux, etc. using [Wine](https://wiki.winehq.org/Main_Page). To install Wine on OS X, I recommend [David Baumgold's Wine installation tutorial](http://www.davidbaumgold.com/tutorials/wine-mac/).


## Input File Format

The input file for COSOPT Assembly Line should be tab-delimited and have gene expression counts organized as in the [sample input file](sample-run/counts.tsv).


## How To Run COSOPT Assembly Line

To get the COSOPT Assembly Line up and running, set the parameters and run the following code on the command line.

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

*Note: COSOPT is not the fastest program; on my laptop, it took me nearly 6 hours to analyze data from 42,128 genes with 23 timepoints in triplicate.*


## Custom Period Length Parameters

By default, `cosopt-formatter.pl` looks for rhythmic gene expression with periods from 20 to 28 hours at 0.1 hour increments. These parameters can be customized. For example, the following would be used to identify for genes with periods from 22 to 26 hours at 0.5 hour increments:

```sh
perl cosopt-formatter.pl --period_min 22 --period_max 26 --period_inc 0.5 -o $OUT_DIR $COUNT_FILE_IN
```
