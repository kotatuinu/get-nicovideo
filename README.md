# PowerShellを使ったクッキーを使用するWebページの操作
ぶっちゃけ、ニコニコ動画から動画を取得するツール。  
#### ■履歴  
* 2014/05/16 ：初版
* 2015/08/09 ：過去投稿動画を取得できるように変更。動画の種別により出力ファイルの拡張子を変えるように修正。
* 2015/08/23 ：動画番号をパイプラインで入力可能とした。マイリストに登録されている動画番号を取得するスクリプトを追加。  

## 使い方  
● ニコニコ動画 動画ファイルダウンローダー  
ダウンロードしたい動画番号を指定して、出力先ディレクトリに出力します。  
出力ファイルの拡張子は、動画ファイルの先頭3バイトを参照して以下のようにします。  
　CWS ： <動画番号>.swf  
　FLV ： <動画番号>.flv  
　上記以外 ： <動画番号>.mp4

`
PS > ./get-nicovideo.ps1 -userid <UserID> -password <Password> -output_path <Output Directory> -movie_no <Movie No>[,<Movie No>...]`
* -userid : ニコニコ動画のユーザID  
* -password : ニコニコ動画のユーザIDに対応するパスワード  
* -output_path : ダウンロードの出力先ディレクトリ  
* -movie_no : ダウンロードしたい動画番号。カンマで区切ることで複数指定可能。パイプラインで渡すことも可能。  
※：パラメータ名（-useridや-passwordなど）は省略可能。その場合は引数を置く順番を守ること。

● ニコニコ動画 マイリスト 動画番号取得ツール  
ニコニコ動画のマイリスト番号（"http://www.nicovideo.jp/mylist/<マイリスト番号>"）を指定することで、そのマイリストに登録されている動画番号をリストで取得します。  
`PS > .\get-nicomylist.ps1 -mylist <動画番号>`
* -mylist : 登録されている動画番号を取得したいマイリスト番号。カンマで区切ることで複数指定可能。パイプラインで渡すことも可能。  
※：パラメータ名（-mylist）は省略可能。


２つのツールを組み合わせて、マイリストの動画をダウンロードできます。複数のマイリストを指定することも可能。  
`PS > .\get-nicomylist.ps1 <動画番号> | .\get-nicovideo.ps1 -user <UserID> -password <Password> -output_path <出力ディレクトリ>`
`PS > <動画番号1>,<動画番号2> | .\get-nicomylist.ps1 | .\get-nicovideo.ps1 -user <UserID> -password <Password> -output_path <出力ディレクトリ>`


## 技術的覚書
### 関数
 `function <関数名> (引数[, 引数]) {  
     処理  
 }`

 return で戻り値を返せる。(実は標準出力が戻り値になってしまうのだが)  
 引数は$Argsで配列として受け取ることも可。  
 参照渡しの引数は、引数の前に[ref] をつける。空白が必要みたい。  

 ```
 function func($a, [ref] $b) {  
 	$a = 1;	#呼び出し元の変数の値は変わらない  
 	$b.value = 2;	#呼び出し元の変数の値は2に変わる  
 }
```

 関数呼び出しで引数をカンマで区切ると、配列になるという罠。  
 呼び出しの時は、<関数名> 引数 引数 という形にする。括弧で括らず、引数を空白で区切るようにする。  
 `func $a ([ref] $b)`  

コマンドレットやスクリプトファイルで引数の型を設定したい場合は、以下のようにする。スクリプトファイルではファイルの先頭に置く必要がある。  
```
[CmdletBinding()]
param(
	[Parameter(Mandatory=$True,Position=1,HelpMessage="NiconicoVideo UserName.")]
	[String]$userid,

	[Parameter(Mandatory=$True,Position=2,HelpMessage="NiconicoVideo Password.")]
	[String]$password,

	[Parameter(Mandatory=$True,Position=3,HelpMessage="OutputDirectory.")]
	[String]$output_path,

	[Parameter(ValueFromPipeline=$True,Mandatory=$True,Position=4,HelpMessage="Download niconicoVideo MovieNo List.")]
	[String[]]$movie_no
)
```  
引数を格納する変数の名前がオプション名になる。  
引数を格納する変数の前にデータ型を指定できる。配列も指定可。  
Parameter()で設定できる属性  
* Mandatory ：必須項目指定。$Trueのとき、引数の指定が必要。
* Position  ：引数の位置指定。
* ValueFromPipeLine ：パイプで値を渡すこと可能。※：cmdletもしくはスクリプトファイルのprocessブロックで使用可能。  
* HelpMessage ：引数のヘルプ。なのだが、引数を入れ忘れると入力を要求され、そこで!?を入力すると表示される。（Usageを表示してコマンド終了にできないものか。）  
引数についての詳細は以下を参照のこと。  
https://technet.microsoft.com/library/dd347600.aspx

スクリプトファイルでパイプラインで渡される値を使用するには、以下の理由から引数定義のValueFromPipeLineで設定する方法は使用できない。$inputを使用するべし。  
* 引数定義ValueFromPipeLine=$true で設定した変数は、functionで定義されたとき(cmdlet)取得できる。
または、スクリプトファイルでは、processブロック内で取得できる。processブロック内でないとき、パイプラインで渡された最後の値しか取得できない。
* スクリプトファイルにbegin,process,endブロックを記述すると、functionが定義できない。べたで書けと？  
  begin,process,endブロックを&{}で括ればfunctionを定義できる。でもprocessブロック内であってもパイプラインで渡された値は最後しか取得できない。
* 結局、$inputをスクリプトの先頭でコピーする方法が安定と思われる。なぜコピーするかというと、スクリプト中でパイプを使用すると$inputの内容が破棄されるため。  

### 変数
 $変数名 という形式。  
 ${変数名}という形式も使える。たとえば、文字列中に変数を埋め込むときに変数名を明示するときに使う。  

### 特殊変数
 以下のものがある。内容は見ての通り。  
 $null  
 $true  
 $false  
 $Args  

 あと、$Matches がある。「正規表現によるマッチング判定」を参照のこと。  

### 定数
`set-variable -name <変数名> -value <値> -option constant`  
文字リテラルは、""か''で括る。変数も展開される。変数の後にも文字列が来るときは{}で変数名を括らないと、別の変数として見られてしまう。  
なお、配列も設定可能。


### 配列
`` $<変数名>[<配列番号>]``  
 定数は@()、 @{}  
 @(1,2,3,4) とか @(1..4)とか。  

### 連想配列
`` $<変数名>{"キー"}  ``

### コンソールに出力するとき
`[Console]::WriteLine("出力メッセージ")`
`Write-Out("出力メッセージ")`

### 出力書式子は、.net Fameworkと同じ。
 {0} とか、-fを使う。  

```
PS C:\Users\kotat_000> "{3:HH:mm:ss},{3:hh:mm:ss},{1}, {0:x}, [{2,5}]" -F 2000,"bbb","ccc",(Get-Date)  
22:39:39,10:39:39,bbb, 7d0, [  ccc]
```

もちろん、結果を変数に入れることもできる。  

```
PS C:\Users\kotat_000> $a="{3:HH:mm:ss},{3:hh:mm:ss},{1}, {0:x}, [{2,5}]" -F 2000,"bbb","ccc",(Get-Date)  
PS C:\Users\kotat_000> $a  
22:42:27,10:42:27,bbb, 7d0, [  ccc]
```

### 正規表現によるマッチング判定
 `<対象文字列(変数もOK)> -match <正規表現>`  
 戻り値は真偽値($true/$false)  
 パーレン()で括ったところは、$Matches 配列に格納される。  

```
	if( "abcdef" -match "ab(.+)" ) {  
		$result1 = $Matches[0]  
		$result2 = $Matches[1]  
		[Console]::WriteLine("${result1},${result2}")  
	}  
```

→結果は、abcdef,cdef となる。  
  正規表現のマッチングは if文の条件式で実行しなくていいけど、変数に入れないとTrueとか出ちゃうよ。  

```
PS C:\Users\kotat_000> "abcdef" -match "ab(.+)"  
True  
```

### 正規表現による文字列置換
`` <対象文字列(変数もOK)> -replace <正規表現>,<置換文字>``  
`` <対象文字列(変数もOK)> -creplace <正規表現>,<置換文字>``  
 戻り値は、置換した結果の文字列。  
 前者は、大文字小文字を区別しない。後者は、大文字小文字を区別する。  

```
PS C:\Users\kotat_000> "abcdefABCDEF" -replace "cdef","cb"  
abcbABcb  
PS C:\Users\kotat_000> "abcdefABCDEF" -creplace "cdef","cb"  
abcbABCDEF
```
