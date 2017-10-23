# csv_fix
Quick and dirty solution to fix broken line csv files using PowerShell

## What is it

A PowerShell script (not even a CmdLet yet) that will create a fixed version of csv or any other text files that has broken lines.

For example:
If we have a line broken into three separate lines like below:
```
field1,field2,fi
eld3,fie
ld4,field5,field6
```

This script is able to spot it and append the later two lines to the first line.
```
field1,field2,field3,field4,field5,field6
```

## What it is not
It is not a CmdLet that accepts arguments and stuff, I wrote this just in case I need to fix some csv files really quickly. I might wrap it into a nice CmdLet afterwards.

## What does it not fix
A csv file with non-full text qualifiers, for example:
```
field1,field2,field3,"some field with, well, some comma in it", field5,field6
```

## How to use
* Replace the value in `$path` variable with the file you want to fix.
* `$Header_Sep` is for header delimiter **IMPORTANT: The script runs on the assumption that the header is not broken**
* `$Data_Sep` is for the delimiter in the actual data lines.
* Script will automatically create a file with `_fixed` suffix with the fixed file, or an additional file with `_abnormal` suffix. If it finds a line with delimiters more than expected.

## Limitations
In addition to the "what does it not fix" section, the script can't fix a broken line like this:
```
field1,field2,field3,fied5,fie
ld6
```
Since only the last field is broken.
The next commit will fix this issue.
