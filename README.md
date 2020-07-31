# file_implant
not tar, but archive some files and extract this.

## インストール

特になし。実行権限つけたければどうぞ、ぐらい

## 使い方

### コマンドラインから
```
usage:
  usage1: #{File.basename(__FILE__)} -a INPUT_FILE1 [INPUT_FILE2 ...] OUTPUT_FILE
  usage2: #{File.basename(__FILE__)} -d INPUT_FILE OUTPUT_DIR
```

### Rubyクラスとして
```rby
fi = FileImplant.new
fi.assemble([INPUT_FILE, ...], OUTPUT_FILE)
fi.disassemble(IMPLANTED_FILE, OUTPUT_DIR)
```

## 目的
複数のファイルを結合、分解する
* そもそもの目的はインプラントjpegの分解
  * Tarじゃダメ（jpegに偽装できない
  * jpegはでかいので、前から仕様に沿って分割は非効率
    * 末尾からさかのぼったほうが楽（なはず

* 元ファイルに識別用のフッタを付与する
  * ファイルA + フッタA
  * ファイルB + フッタB
  * ファイルC + フッタC
  * 末尾
* フッタ
  * 特殊文字に挟まれているテキストデータ
    * FOOTER_SPLITER_PREで始まる
    * FOOTER_SPLITER_POSTで終わる
    * 挟まれてる内容は「パラメータ名=値&パラ...」
    * 値はURLエンコードする
    * 下記のパラメータが含まれる
      * size: [必須]ファイルサイズ：数値
      * name: [任意]ファイル名：UTF-8文字列
        * ⇒あれば使う、なければ適当に作る
      * mime: [任意]mime-type：ASCII文字
        * ⇒使う予定なし、今後使うかも？→実装してない
* 末尾
  * UUDDLRLRBA

## その他

* バイナリ扱う参考サイト
  * [Rubyで画像ファイルの種別を判定](https://morizyun.github.io/ruby/tips-image-type-check-png-jpeg-gif.html)
* WindowsだとDisassembleが上手くいかない
  * stdoutに出力した\nが\r\nになってる？
    * どうする？
      1. Windowsは対応外にしちゃう
      2. stdout経由やめる←採用

## 調査の記録

### JPEGの仕様
* [JPEGファイルの構造](https://hp.vector.co.jp/authors/VA032610/JPEGFormat/StructureOfJPEG.htm)
  * [EＯＩ (0xFFD9)　エンドマーカ](https://hp.vector.co.jp/authors/VA032610/JPEGFormat/marker/EOI.htm)
* EOI（EndOfImage）以降のデータは無視される
  * ⇒好きなデータを埋め込める
    * サムネイルとかもここに入れるっぽい？
  * ⇒「インプラントJPEG」と呼ぶらしい
    * [JPEG Directシリーズがサポートする画像ファイル形式](http://hp.vector.co.jp/authors/VA007786/file.html)
       * [JPEG Direct Annex](http://hp.vector.co.jp/authors/VA007786/jda.html)で操作できる？⇒windowsのツール

### 結合と画像の抽出
* [JPEGにファイルを隠させない方法](http://blog.livedoor.jp/dankogai/archives/50661794.html)
  * 結合はコマンド一発
  * jpeg部分のみ抽出
    * 埋め込んだファイルの抽出には触れられていない
