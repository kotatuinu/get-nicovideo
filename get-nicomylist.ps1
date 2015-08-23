[CmdletBinding()]
param(
	[Parameter( ValueFromPipeline=$True, Mandatory=$True, Position=1 )]
	[String[]]$mylist
)
$ErrorActionPreference = "Stop"

# pileline からの入力も動画番号として扱う
if( $null -ne $input ) {
	$mylist = @($input) + $mylist
}


function Usage {
	$Usages | ForEach-Object { $_ }
}

&{
	begin {
		set-variable -name NICOVIDEO_MYLIST -value "http://www.nicovideo.jp/mylist/{0}" -option constant

		# Usage
		$Usages = @(
			"Get the video number that is registered in the NicoNicoDouga of My List."
			" Usage : $MyInvocation.MyCommand.Name -mylist <mylist no>[,<mylist No>...]";
			"  OPTIONS"
			"  -mylist : Set My List of number. Input of the pipeline is also OK.";
		)

		$encode = [Text.Encoding]::GetEncoding("utf-8")
		$regex = ([regex]"""watch_id"":""(.+)""")
	}
	process {
		$porcessed_list = @()
		foreach($ml in $mylist) {
			#すでに処理したマイリストは処理しない
			if( $porcessed_list -contains $ml ) {
				continue
			}
			$porcessed_list += $ml

			$url = $NICOVIDEO_MYLIST -F ${ml}
			try {
				Invoke-WebRequest $url | %{ $_.Content -split "," } | %{ $regex.Matches($_) } | %{ Write-Output $_.Groups[1].Value }
			} catch {
				Write-Output "ERROR : get mylist failed. ${url}"
			}
		}
	}
	end {}
}
