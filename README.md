#PowerShellを使ったクッキーを使用するWebページの操作
ぶっちゃけ、ニコニコ動画から動画を取得するツール。

##使い方
ダウンロードしたい動画番号を指定して、出力先ディレクトリに出力します。  
 出力ファイル名は、<動画番号>.mp4 となります。  
  
`PS > get-nicovideo.ps1 -u <UserID> -p <Password> -o <Output Directory> -movie_no <Movie No>[,<Movie No>...]`
* -u : ニコニコ動画のユーザID  
* -p : ニコニコ動画のユーザIDに対応するパスワード  
* -o : ダウンロードの出力先ディレクトリ  
* -movie_no : ダウンロードしたい動画番号。カンマで区切ることで複数指定可能  


##技術的覚書
###関数
 `function <関数名> (引数[, 引数]) {`  
 `    処理`  
 `}`

 return で戻り値を返せる。  
 引数は$Argsで配列として受け取ることも可。  
 参照渡しの引数は、引数の前に[ref] をつける。空白が必要みたい。  
 `function func($a, [ref] $b) {  
 	$a = 1;	#呼び出し元の変数の値は変わらない  
 	$b.value = 2;	#呼び出し元の変数の値は2に変わる  
 }`
  
 関数呼び出しで引数をカンマで区切ると、配列になるという罠。  
 呼び出しの時は、<関数名> 引数 引数 という形にする。括弧で括らず、引数を空白で区切るようにする。  
 `func $a ([ref] $b)`  


###変数
 $変数名 という形式。  
 ${変数名}という形式も使える。たとえば、文字列中に変数を埋め込むときに変数名を明示するときに使う。  
  
###特殊変数
 以下のものがある。内容は見ての通り。  
 $null  
 $true  
 $false  
 $Args  
  
 あと、$Matches がある。「正規表現によるマッチング判定」を参照のこと。  
  
###定数
`set-variable -name <変数名> -value <値> -option constant`
文字リテラルは、""か''で括る。変数も展開される。変数の後にも文字列が来るときは{}で変数名を括らないと、別の変数として見られてしまう。  


###配列
 $<変数名>[<配列番号>]  
 定数は@()、 @{}  
 @(1,2,3,4) とか @(1...4)とか。  
  
###連想配列
 $<変数名>{"キー"}  
  
###コンソールに出力するとき
`[Console]::WriteLine("出力メッセージ")`
  
###出力書式子は、.net Fameworkと同じ。
 {0} とか。  
 -fを使う。  
`PS C:\Users\kotat_000> "{3:HH:mm:ss},{3:hh:mm:ss},{1}, {0:x}, [{2,5}]" -F 2000,"bbb","ccc",(Get-Date)  
22:39:39,10:39:39,bbb, 7d0, [  ccc]`
  
もちろん、結果を変数に入れることもできる。  
`PS C:\Users\kotat_000> $a="{3:HH:mm:ss},{3:hh:mm:ss},{1}, {0:x}, [{2,5}]" -F 2000,"bbb","ccc",(Get-Date)  
PS C:\Users\kotat_000> $a  
22:42:27,10:42:27,bbb, 7d0, [  ccc]`
  
  
###正規表現によるマッチング判定
 `<対象文字列(変数もOK)> -match <正規表現>`
 戻り値は真偽値($true/$false)  
 パーレン()で括ったところは、$Matches 配列に格納される。  
`	if( "abcdef" -match "ab(.+)" ) {  
		$result1 = $Matches[0]  
		$result2 = $Matches[1]  
		[Console]::WriteLine("${result1},${result2}")  
	}`  
→結果は、abcdef,cdef となる。  
  正規表現のマッチングは if文の条件式で実行しなくていいけど、変数に入れないとTrueとか出ちゃうよ。  
  
`PS C:\Users\kotat_000> "abcdef" -match "ab(.+)"  
True`
  
  
###正規表現による文字列置換
 `<対象文字列(変数もOK)> -replace <正規表現>,<置換文字>  
 <対象文字列(変数もOK)> -creplace <正規表現>,<置換文字>`
 戻り値は、置換した結果の文字列。  
 前者は、大文字小文字を区別しない。後者は、大文字小文字を区別する。  
  
`PS C:\Users\kotat_000> "abcdefABCDEF" -replace "cdef","cb"  
abcbABcb`

`PS C:\Users\kotat_000> "abcdefABCDEF" -creplace "cdef","cb"  
abcbABCDEF`
  
