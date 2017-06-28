#
# Fluent::ZabbixSimpleOutput
#
# Copyright (C) 2013 NAKANO Hideo
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'zabbix'
require 'socket'
require 'fluent/plugin/output'

class Fluent::Plugin::ZabbixSimpleOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('zabbix_simple', self)

  helpers :compat_parameters

  DEFAULT_BUFFER_TYPE = "memory"

  attr_reader :zabbix_server, :port, :host, :key_size, :map_keys

  config_param :zabbix_server, :string
  config_param :port, :integer,            :default => 10051
  config_param :host, :string,             :default => Socket.gethostname
  config_param :key_size, :integer,        :default => 20

  config_section :buffer do
    config_set_default :@type, DEFAULT_BUFFER_TYPE
  end

  KeyMap = Struct.new(:id, :pattern, :replace)

  def configure(conf)
    compat_parameters_convert(conf, :buffer)
    super

    if @zabbix_server.nil?
      raise Fluent::ConfigError, "missing zabbix_server"
    end

    @map_keys = []
    (0..@key_size).each do |i|
      next unless conf["map_key#{i}"]
      pattern,replace = conf["map_key#{i}"].split(' ', 2)
      @map_keys.push(KeyMap.new(i, Regexp.new(pattern), replace))
    end

    if @map_keys.nil? or @map_keys.size == 0
      raise Fluent::ConfigError, "missing map_key[0..]"
    end
  end

  def start
    super
  end

  def shutdown
    super
  end

  def create_zbx_sender
    Zabbix::Sender.new(:host => @zabbix_server, :port => @port)
  end

  def send(zbx_sender, name, value, time)
    begin
      log.debug { "name: #{name}, value: #{value}, time: #{time}" }

      opts = { :host => @host, :ts => time }
      status = zbx_sender.send_data(name, value.to_s, opts)

    rescue IOError, EOFError, SystemCallError
      # server didn't respond
      log.warn "Zabbix::Sender.send_data raises exception: #{$!.class}, '#{$!.message}'"
      status = false
    end
    unless status
      log.warn "failed to send to zabbix_server `#{@zabbix_server}(port:`#{@port}`), host:#{@host} '#{name}': #{value}"
    end
  end

  def format(tag, time, record)
    [time, record].to_msgpack
  end

  def formatted_to_msgpack_binary?
    true
  end

  def write(chunk)
    zbx_sender = nil
    begin
      log.trace { "connecting to zabbix server `#{@zabbix_server}(port:`#{@port}`)" }
      zbx_sender = create_zbx_sender
      zbx_sender.connect
      log.trace "done connected to zabbix server"
    rescue
      log.warn "could not connect to zabbix server `#{@zabbix_server}(port:`#{@port})`, exception: #{$!.class}, '#{$!.message}'"
    end

    if zbx_sender
      chunk.msgpack_each do |time, record|
        record.each do |key,value|
          @map_keys.each do |map|
            zbx_key = map_key(key, map.pattern, map.replace)
            next unless zbx_key
            send(zbx_sender, zbx_key, value, time)
          end
        end
      end
      zbx_sender.disconnect
    end
  end

  def map_key(key, pattern, replace)
    unless pattern =~ key
      nil
    else
      key.sub(pattern, replace)
    end
  end
end
