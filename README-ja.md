# fluent-plugin-zabbix-simple

[![Build Status](https://travis-ci.org/fluent-plugins-nursery/fluent-plugin-zabbix-simple.svg?branch=master)](https://travis-ci.org/fluent-plugins-nursery/fluent-plugin-zabbix-simple)

## 概要

**fluent-plugin-zabbix-simple** は、[fluentd](http://fluentd.org/ "fluentd") output plugin で、[Zabbix](http://www.zabbix.com/ "Zabbix") Server に値を送ることができます。

fluentd は、ログを JSON として収集します。
fluent-plugin-zabbix-simple は、**fluentdのJSONキー** を **Zabbixキー** に変換し、_Zabbix キー_ とその値を Zabbix Server に送ります。

* 変換するキーは複数個定義でき、個数に制限はありません。

* **key-pattern** と **key-replacement** の両方に正規表現を使うことができます。

  * **key-pattern**(単に **pattern** と呼ぶ)は、_fluentdのJSONキー_ と照合されるキーです。

  * **key-replacement**(単に **replacement** と呼ぶ)は、_pattern_ と _fluentdのJSONキー_ との照合に成功した場合、Zabbix Server に送信されるキーです。

## インストール方法

コマンド `gem install` を実行します。

    $ sudo gem install fluent-plugin-zabbix-simple

td-agent は専用の Ruby 処理系を持っています。
td-agent をインストールしている場合、td-agent 付属の gem コマンドを用いてインストールしなければならないかもしれません。

    $ sudo /usr/lib64/fluent/ruby/bin/gem isntall fluent-plugin-zabbix-simple

## 確認

### Zabbix Server 設定

あらかじめ Zabbix Server で次のようなアイテムを定義しておきます:

    Key: httpd.status[2xx]
    Type: Zabbix trapper
    Type of information: Numeric(unsigned)

    Key: httpd.status[3xx]
    Type: Zabbix trapper
    Type of information: Numeric(unsigned)

こつは：

* `Type` を `Zabbix trapper` にしなければなりません。

* `Type of information` は適切な型を選択してください。

### Plugin 設定&テスト

fluent-plugin-zabbix-simple をテストするため次のようなファイルを作成します。

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

## 設定

name | type | description
-----|------|------
type | string | plugin の type を指定します。fluent-plugin-zabbix-simple は、"zabbix_simple" を指定します。
zabbix_server | string | Zabbix Server の IP address か hostname を指定します。
port | integer | Zabbix Server が使用するポート番号を指定します(既定値は 10051)。
host | string | Zabbix Server にデータを送信しようとしているホスト名です(既定値は `Socket.gethostname`)。
key_size | integer | map_key のサイズ(既定値は 20)。
map_key[n] | string | スペースで分割された _pattern_ と _replacement。 0 番目の map_key として `map_key0` を使用することができます。


## 多くのキーを使う

既定では、20 番目のキーまで検索します。
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

## 照合の詳細

fluent-plugin-zabbix-simple は、`map_key0` から照合を開始し、最初に照合に成功したキーを使用し、残りは無視します。

## Legal Notification

### Copyright
Copyright (c) 2013 NAKANO Hideo

### License
Apache License, Version 2.0
