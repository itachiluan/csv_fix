$path = "C:\Users\itachiluan\Documents\Scripting\PowerShell\test.txt"

$Header_Sep = '","'
$Data_Sep = '","'

# Get the Separator count
$Header_Reader = [System.IO.File]::OpenText($path)
$Header = $Header_Reader.ReadLine()
$Header_Reader.Close()
$header_sep_count = [regex]::Matches($Header,$Header_Sep).count
Write-Host "Judging by the header, the file should have $($header_sep_count+1) fields....."

$fileItem = Get-Item $path
$out_path = "$($fileItem.DirectoryName)\$($fileItem.BaseName)_fixed$($fileItem.Extension)"
$err_out_path = "$($fileItem.DirectoryName)\$($fileItem.BaseName)_Abnormal$($fileItem.Extension)"
New-Item $out_path -ItemType file -Force
New-Item $err_out_path -ItemType file -Force
$fixed_writer = [System.IO.File]::AppendText($out_path)
$abnormal_writer = [System.IO.File]::AppendText($err_out_path)

# find unmatched
$broken_line_count = 0
$abnormal_line_count = 0
$line_count = 1
$lines = [System.IO.File]::ReadLines($Path)
$has_broken = $false
$stage_line = ""
$stage_ok = $false
foreach ($l in $lines) {
    $cur_sep_count = [regex]::Matches($l, $Data_Sep).count

    if ($cur_sep_count -eq $header_sep_count) {
        # line might not be broken.
        if ($has_broken) {
            # if there is previously broken line, write the line to the file here.
            if ($stage_ok) {
                $fixed_writer.writeline($stage_line)
            } else {
                Write-Warning "The previous fix did not have expected proceeding lines, will be written to error file."
                $abnormal_writer.WriteLine($stage_line)
            }
            $has_broken = $false
            $stage_line = ""
        }
        # also write down the current line.
        $fixed_writer.WriteLine($l)
    } elseif ($cur_sep_count -lt $header_sep_count) {
        # line is broken
        if ( -not $has_broken) {
            # first part of the broken line.
            Write-Host "line $line_count is the first part of a broken line." -ForegroundColor Cyan
            $stage_ok = $false
            $stage_line = $l
            $has_broken = $true
            $broken_line_count++
        } else {
            # the rest part of the broken line, or another broken line.
            $newline = "$stage_line$l"
            $new_sep_count = [regex]::Matches($newline, $Data_Sep).count
                
            if ($stage_ok) {
                # could be another broken line.
                if ($new_sep_count -eq $header_sep_count) {
                    # test for a corner case: last field is left to the next line.
                    Write-Host "line $line_count will be appended." -ForegroundColor Cyan
                    $stage_line = "$stage_line$l"
                    # the rest will be taken care of when iterating to the next line.
                } else {
                    # should be another broken line.
                    $fixed_writer.writeline($stage_line) # write current staged line.

                    Write-Host "line $line_count is the first part of a broken line." -ForegroundColor Cyan
                    $stage_ok = $false
                    $stage_line = $l
                    $has_broken = $true
                    $broken_line_count++
                }
            } else {
                if ($new_sep_count -le $header_sep_count) {
                    # appending lines seems to be correct.
                    Write-Host "line $line_count will be appended." -ForegroundColor Cyan
                    $stage_line = "$stage_line$l"
                    if ($new_sep_count -eq $header_sep_count) {
                        # seems to have all the fields added.
                        $stage_ok = $true
                    }
                } else {
                    # there are more fields? ... previous line could be very broken...
                    Write-Warning "The previous fix did not have expected proceeding lines, will be written to error file."
                    $abnormal_writer.WriteLine($stage_line)
                    $abnormal_line_count++

                    # current line could be another broken line.
                    Write-Host "line $line_count is the first part of a broken line." -ForegroundColor Cyan
                    $stage_ok = $false
                    $stage_line = $l
                    $has_broken = $true
                    $broken_line_count++
                }
            }
        }
    } else {
        # line has excessive separator.
        Write-Warning "Line $line_count has more delimiter than the header, is written into the error file."
        $abnormal_writer.writeline($l)
        $abnormal_line_count++
    }
    $line_count++
    
    if ($line_count % 50000 -eq 0) {
        Write-Host "processed $line_count lines."
    }
}
$fixed_writer.Close()
$abnormal_writer.Close()
Write-Host "Sequence completed, processed $line_count lines, there are $broken_line_count lines broken."
if ($abnormal_line_count -gt 0) {
    Write-Host "There are also $abnormal_line_count lines that has more fields, examine in the _abnormal file."
} else {
    Remove-Item $err_out_path -Force
}
