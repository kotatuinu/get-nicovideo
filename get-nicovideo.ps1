[CmdletBinding()]
param(
	[Parameter(Mandatory=$True,Position=1,HelpMessage="NiconicoVideo UserName.")]
	[String]$userid,

	[Parameter(Mandatory=$True,Position=2,HelpMessage="NiconicoVideo Password.")]
	[String]$password,

	[Parameter(Mandatory=$True,Position=3,HelpMessage="OutputDirectory.")]
	[String]$output_path,

	[Parameter(ValueFromPipeline=$True,Mandatory=$False,Position=4,HelpMessage="Download niconicoVideo MovieNo List.")]
	[String[]]$movie_no
)

[void][reflection.assembly]::LoadWithPartialName("System.Web")

# pileline からの入力も動画番号として扱う
if( $null -ne $input ) {
	$movie_no = @($input) + $movie_no
}

function Usage {
	$Usages | ForEach-Object { $_ }
}

# WebPage取得(GET)
function GetWebPage($url, [ref]$cc) {
#[Console]::WriteLine("GetWebPage url=[${url}]")
	$webReq = [System.Net.WebRequest]::Create($url)
	$webReq.Method = "GET"
	$webReq.CookieContainer = $cc.Value

	$webRes = $webReq.GetResponse()
	$resStream = $webRes.GetResponseStream()

	$srmReader = New-Object System.IO.StreamReader($resStream, $encode)
	$result = $srmReader.ReadToEnd()
	$srmReader.Close()
	$resStream.Close()

	return $result
}

# Web File取得(GET)
function GetWebFile($url, $putputFile, [ref]$cc) {
#[Console]::WriteLine("GetWebFile url=[${url}] putputFile=[${putputFile}]")

	try {
		$webReq = [System.Net.WebRequest]::Create($url)
		$webReq.Method = "GET"
		$webReq.CookieContainer = $cc.Value

		$webRes = $webReq.GetResponse()
		$resStream = $webRes.GetResponseStream()

		$fileStream = New-Object System.IO.FileStream($putputFile, [System.IO.FileMode]::Create)

		[byte[]] $buf = New-Object byte[] 1024
		do {
			$read_size = $resStream.Read( $buf, 0, $buf.Length )
			$fileStream.Write($buf, 0, $read_size)
		} while( $read_size -gt 0 )

		#即時に閉じたいため、finallyとは別に実行
		$fileStream.Close()
		$fileStream = $null
		$resStream.Close()
		$resStream = $null

	} catch {
		return $false
	} finally {
		if( $fileStream -ne $null) { $fileStream.Close() }
		if( $resStream -ne $null)  { $resStream.Close() }
	}

	return $true
}

# WebPage取得(POST)
function PostWebPage($url, $postData, [ref] $cc) {
#[Console]::WriteLine("PostWebPage : url=${url}, data = ${postData}")

	$webReq = [System.Net.WebRequest]::Create($url)
	if( $webReq -eq $null ) {
		exit
	}
	$byteData = $encode.GetBytes($postData)
	$dataLen = $encode.GetByteCount($postData)

	$webReq.Method = "POST"
	$webReq.ContentType = "application/x-www-form-urlencoded"
	$webReq.ContentLength = $dataLen
	$webReq.CookieContainer = $cc.Value

	$resStream = $webReq.GetRequestStream()
	$resStream.Write($byteData, 0, $dataLen)
	$resStream.Close()

	$webRes = $webReq.GetResponse()
	$resStream = $webRes.GetResponseStream()

	$srmReader = New-Object System.IO.StreamReader($resStream, $encode)
	$result = $srmReader.ReadToEnd()
	#[Console]::WriteLine( $result )

	$srmReader.Close()
	$resStream.Close()

	return $result
}

# ログイン
function Login-NicoVideo($uid, $pwd, [ref] $cc) {
	$postDataList = @{
		"next_url" = "";
		"show_button_facebook" = "0";
		"show_button_twitter" = "0";
		"nolinks" = "0";
		"_use_valid_error_code" = "0";
		"mail_tel" = $uid;
		"password" = $pwd;
	}

	$postData = ""
	foreach ( $key in $postDataList.Keys ) {
		if($postData -ne "") {
			$postData += "&"
		}
		$value = [System.Web.HttpUtility]::UrlEncode($postDataList[${key}])
		$postData += "${key}=${value}"
	}

	$result = PostWebPage ${NICOVIDEO_URL_CONNECT} $postData $cc

	if($result -match '<(span|h2)>ログイン</(span|h2)>') {
		#LOGIN FAILED
		#[console]::WriteLine("$result")
		return $FALSE
	}

	return $TRUE
}

# 動画ページ
function Get-NicoMoviePage($movie_no, [ref]$cc) {

	$url = ${NICOVIDEO_URL_MOVIEPAGE} -F ${movie_no}
	return GetWebPage $url $cc
}


# 動画情報ページ
function Get-NicoMovieInfo($url_format, $movie_no, [ref]$cc) {

	$url = ${url_format} -F ${movie_no}
	return GetWebPage $url $cc
}


#動画番号から動画情報（XML）を取得
function Get-NicoAPI_MovieInfo($movie_no) {

	$wc = New-Object System.Net.WebClient
	$wc.Encoding=$encode

	$url = ${NICOVIDEO_API} -F ${movie_no}

#$xmlData = $wc.DownloadString($url)
#[Console]::WriteLine( "movie_no=${movie_no}, URL=${url}, result=${xmlData}" )
	return [xml]$wc.DownloadString($url)
}

#ファイルの先頭
function Get-FileType($fileName) {
	$bufSize = 3
	[byte[]] $buf = New-Object byte[] $bufSize

	try {
		$fileStream = New-Object System.IO.FileStream($fileName, [System.IO.FileMode]::Open)
		$fileStream.Read($buf, 0, ${bufSize}) | Out-Null
		$fileStream.Close()
		$fileStream = $null
	} finally {
		if( $fileStream -ne $null) { $fileStream.Close() }
	}

	$d=""
	$buf | %{ $d += [system.Text.Encoding]::GetEncoding("ASCII").getchars($_) }

	switch( $d ) {
		"CWS" { $ext="swf" }
		"FLV" { $ext="flv" }
		default { $ext="mp4" }
	}

	return $ext
}


# main
&{
	begin {

		set-variable -name NICOVIDEO_API_THUMINFO -value "http://ext.nicovideo.jp/api/getthumbinfo/" -option constant
		set-variable -name NICOVIDEO_URL_CONNECT -value "https://secure.nicovideo.jp/secure/login?site=niconico" -option constant
		set-variable -name NICOVIDEO_URL_MOVIEPAGE -value "http://www.nicovideo.jp/watch/{0}" -option constant
		set-variable -name NICOVIDEO_URL_MOVIE_INFO -value @("http://flapi.nicovideo.jp/api/getflv?v={0}", "http://www.nicovideo.jp/api/getflv/{0}?as3=1") -option constant
		set-variable -name NICOVIDEO_API -value "http://ext.nicovideo.jp/api/getthumbinfo/{0}" -option constant


		$ErrorActionPreference = "Stop"
		$encode = [Text.Encoding]::GetEncoding("utf-8")

		# Usage
		$Usages = @(
			"Get NiconicoVideo's Movie File."
			" Usage : $MyInvocation.MyCommand.Name -userid <UserID> -password <Password> -output_path <Output Directory> -movie_no <Movie No>[,<Movie No>...]";
			"  OPTIONS"
			"  -userid : NiconicoVideo UserName.";
			"  -password : NiconicoVideo Password.";
			"  -output_path : Output Directory.";
			"  -movie_no : Download NiconicoVideo MovieNo List.";
		)


		# NicoVideo Login needs Cookie. Make CookieContainer.
		$cc = New-Object System.Net.CookieContainer

		# Login
		$result = Login-NicoVideo $userid $password ([ref] ${cc})
		if( -not $result ) {
			[Console]::WriteLine("LOGIN FAILED. USER:[$userid], PASSWORD[$password]")
			exit
		}

		if( -not (Test-Path $output_path)) {
			[Console]::WriteLine("INVALID OUTPUT_PATH.[$output_path]")
			exit
		}
		$output_path = Convert-Path $output_path
		if( ($output_path.Length -gt 0) -and ($output_path[$output_path.Length-1] -ne '\') ) {
			$output_path = "${output_path}\"
		}

	}
	process {
		$porcessed_list = @()
		ForEach($mn in $movie_no) {
			#すでに処理した動画は処理しない
			if( $porcessed_list -contains $mn ) {
				continue
			}
			$porcessed_list += $mn
			[Console]::WriteLine("get movie [${mn}]")

			# Get MovieInfo(use NicoAPI:get movie info)
			$xmldata = Get-NicoAPI_MovieInfo(${mn})
			if($xmldata.nicovideo_thumb_response.status -ne "ok") {
				[Console]::WriteLine("Movie Info don't get. MAY BE DELETED MOVIE. [${mn}]")
				continue
			}

			$title = $xmldata.nicovideo_thumb_response.thumb.title -replace "[/?:*`"><|\\]", ""
			#$user_nickname = $xmldata.nicovideo_thumb_response.thumb.user_nickname
			#$year = Get-Date $xmldata.nicovideo_thumb_response.thumb.first_retrieve -Format "yyyy"
			#$id_tag = "-metadata title=`"${title}`" -metadata year=`"${year}`" -metadata creator=`"${user_nickname}`" -metadata album=`"VOCALOID`" -id3v2_version 3"


			# get MoviePage
			$movie_page = Get-NicoMoviePage ${mn} ([ref] ${cc})
			#Write-Output $movie_page

			# get MovieInfo
			foreach($moveInfURL in $NICOVIDEO_URL_MOVIE_INFO) {
				$movie_info = Get-NicoMovieInfo $moveInfURL ${mn} ([ref] ${cc})
				if($movie_info -match '&url=(.+)(&.+=|)') {

					$movie_url = $Matches[1] -replace "%2F","/" -replace "%3A",":" -replace "%3D", "=" -replace "%3F", "?"
					$tmp_file = "${output_path}${mn}.tmp"

					#movie download
					GetWebFile ${movie_url} $tmp_file ([ref] ${cc}) | %{ if(${mn} -ne $true) { return } }

					# get extend name
					if( Test-Path ${tmp_file} -PathType leaf ) {
						$ext = Get-FileType $tmp_file

						#tmp file name change to file name
						Move-Item $tmp_file "${output_path}${mn}.${ext}" -Force
						[Console]::WriteLine("GetWebFile Success.")
						break
					} else {
						# Movie Info don't get
						[Console]::WriteLine("GetWebFile failed.")
					}

				} else {
					# Movie Info don't get
					[Console]::WriteLine("FAILED get MovieInfoPage.")
				}
			}

			# wait 30sec
			Start-Sleep -s 30
		}
	}
	end {}
}

