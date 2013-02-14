= fluent-plugin-zabbix-simple

== Component

=== ZabbixSimpleOutput

fluent が生成する JSON キーを変換し、Zabbix server へ送信します。

* 変換するキーは複数個定義でき、個数に制限はありません。

* 変換するキーには正規表現を使うことができ、正規表現を使った置換もできます。

== Install

コマンド `gem install` を実行します。

    $ sudo gem install fluent-plugin-zabbix-simple

td-agent は専用の Ruby 処理系を持っています。
td-agent をインストールしている場合、td-agent 付属の gem コマンドを用いてインストールしなければならないかもしれません。

    $ sudo /usr/lib64/fluent/ruby/bin/gem isntall fluent-plugin-zabbix-simple

== Configuration

=== Zabbix Server 設定

あらかじめ Zabbix server で次のようなアイテムを定義しておきます:

    Key: httpd.status[2xx]
    Type: Zabbix trapper
    Type of information: Numeric(unsigned)

    Key: httpd.status[3xx]
    Type: Zabbix trapper
    Type of information: Numeric(unsigned)

こつは：

* `Type` を `Zabbix trapper` にしなければなりません。

* `Type of information` は適切な型を選択してください。

=== Plugin 設定&テスト

Plugin をテストするため次のようなファイルを作成します。

    <source>
      type forward
    </source>
    <match httpd.access.status_count>
      type zabbix_simple
      zabbix_server 192.168.0.1
      map_key1 httpd.access_(...)_count httpd.status[\1]
    </match>

このファイルを fluentd.conf として保存し、fluentd を実行してみましょう。

    $ fluentd -c ./fluent.conf -vv

もし td-agent をインストールしているなら、代わりに次のコマンドを実行します。

    $ /usr/sbin/td-agent -c ./fluent.conf -vv

別のターミナルを開き、fluentd サーバに、メッセージを送ってみます。

    $ echo '{"httpd.access_2xx_count":321}' | fluent-cat httpd.access.status_count

30 秒程度待って、Zabbix Server に 321 が記録されていることを確認します。

== Too Many Keys

既定では、キーは 20 番まで検索します。
もし 20 個以上のキーを指定する場合、key_size を指定しなければなりません。

    <match httpd.access.status_count>
      type zabbix_simple
      zabbix_server 192.168.0.1
      key_size 25
      map_key1  pattern1  replace1
      map_key2  pattern2  replace2
      map_key3  pattern3  replace3
      map_key4  pattern4  replace4
      map_key5  pattern5  replace5
      map_key6  pattern6  replace6
      map_key7  pattern7  replace7
      map_key8  pattern8  replace8
      map_key9  pattern9  replace9
      map_key10 pattern10 replace10
      map_key11 pattern11 replace11
      map_key12 pattern12 replace12
      map_key13 pattern13 replace13
      map_key14 pattern14 replace14
      map_key15 pattern15 replace15
      map_key16 pattern16 replace16
      map_key17 pattern17 replace17
      map_key18 pattern18 replace18
      map_key19 pattern19 replace19
      map_key20 pattern20 replace20
      map_key21 pattern21 replace21
      map_key22 pattern22 replace22
      map_key23 pattern23 replace23
      map_key24 pattern24 replace24
      map_key25 pattern25 replace25
    </match>

== Specification of `map_key`

* `map_key0` も使用できます。

* 0 番目の map_key から順にマッチするかどうかを調べ、最初にマッチした map_key を使い、
  残りの map_key にマッチするものがあったとしても使用されません。

* `map_key01` などのように 0 を数値の左に詰めてはいけません。

== TODO

- patches welcome!

== Copyright

Copyright:: Copyright (c) 2013- NAKANO Hideo
License::   Apache License, Version 2.0
