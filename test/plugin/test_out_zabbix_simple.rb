require 'helper'
require 'fluent/test/driver/output'

module Mock
  class ::Fluent::Plugin::ZabbixSimpleOutput
    def self.mock!
      include MockZabbixSimpleOutput
      alias_method :old_create_zbx_sender, :create_zbx_sender
      alias_method :create_zbx_sender, :mock_create_zbx_sender
    end
    def self.unmock!
      return unless method_defined? :mock_say
      alias_method :say, :old_say
    end
  end

  class MockZbxSender
    @@data = []
    def send_data(key, value, opts)
      @@data.push([key, value, opts])
    end
    def connect
    end
    def disconnect
    end
    def configured?()
      true
    end
    def self.data
      @@data
    end
    def self.clearData
      @@data = []
    end
  end

  module MockZabbixSimpleOutput
    def mock_create_zbx_sender
      MockZbxSender.new
    end
  end
end

class ZabbixOutputSimpleTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    zabbix_server  127.0.0.1
    host           clienthost
    map_key1        x1 y1
    map_key2        x2 y2
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ZabbixSimpleOutput).configure(conf)
  end

  def test_emit001
    ::Mock::MockZbxSender.clearData
    Fluent::Plugin::ZabbixSimpleOutput.mock!
    d = create_driver
    d.run(default_tag: 'test') do
      d.feed({"x1" => "test value of x1"})
    end
    Fluent::Plugin::ZabbixSimpleOutput.unmock!

    assert_equal(1, ::Mock::MockZbxSender.data.size)
    assert_equal("y1", ::Mock::MockZbxSender.data[0][0])
    assert_equal("test value of x1", ::Mock::MockZbxSender.data[0][1])
    assert_equal("clienthost", ::Mock::MockZbxSender.data[0][2][:host])
    assert_block do
      ::Mock::MockZbxSender.data[0][2][:ts] > 0
    end
    ::Mock::MockZbxSender.clearData
  end

  def test_emit002
    ::Mock::MockZbxSender.clearData

    Fluent::Plugin::ZabbixSimpleOutput.mock!
    d = create_driver
    d.run(default_tag: 'test') do
      d.feed({"x3" => "test value of x3"})
    end
    Fluent::Plugin::ZabbixSimpleOutput.unmock!

    assert_equal(0, ::Mock::MockZbxSender.data.size)

    ::Mock::MockZbxSender.clearData
  end

  def test_emit003
    ::Mock::MockZbxSender.clearData

    Fluent::Plugin::ZabbixSimpleOutput.mock!
    d = create_driver %{
      zabbix_server  127.0.0.1
      map_key1       input_([^_]+)_count httpd.count[\\1]
    }
    d.run(default_tag: 'test') do
      d.feed({"input_unmatched_count" => 10, "input_unmatched_rate" => 0.431, "input_unmatched_percentage" => 0.73})
      d.feed({"input_status2xx_count" => 1884540035, "input_status2xx_rate" => 2041995578.0 / 730602602.0, "input_status2xx_percentage" => 422483907.0 / 426370718.0})
    end
    Fluent::Plugin::ZabbixSimpleOutput.unmock!

    assert_equal(2, ::Mock::MockZbxSender.data.size)
    assert_equal("httpd.count[unmatched]", ::Mock::MockZbxSender.data[0][0])
    assert_equal("10", ::Mock::MockZbxSender.data[0][1])
    assert_equal("httpd.count[status2xx]", ::Mock::MockZbxSender.data[1][0])
    assert_equal("1884540035", ::Mock::MockZbxSender.data[1][1])

    ::Mock::MockZbxSender.clearData
  end

  def test_configure001
    d = create_driver
    assert_equal("127.0.0.1", d.instance.zabbix_server)
    assert_equal(10051, d.instance.port)
    assert_equal("clienthost", d.instance.host)
    assert_equal(20, d.instance.key_size)
    assert_equal(2, d.instance.map_keys.size)

    assert_equal(1, d.instance.map_keys[0][0])
    assert_equal("/x1/", d.instance.map_keys[0][1].inspect)
    assert_equal("y1", d.instance.map_keys[0][2])
    assert_equal(2, d.instance.map_keys[1][0])
    assert_equal("/x2/", d.instance.map_keys[1][1].inspect)
    assert_equal("y2", d.instance.map_keys[1][2])

    assert_equal(1, d.instance.map_keys[0].id)
    assert_equal("/x1/", d.instance.map_keys[0].pattern.inspect)
    assert_equal("y1", d.instance.map_keys[0].replace)
    assert_equal(2, d.instance.map_keys[1].id)
    assert_equal("/x2/", d.instance.map_keys[1].pattern.inspect)
    assert_equal("y2", d.instance.map_keys[1].replace)
  end

  def test_configure002
    assert_raise Fluent::ConfigError do
      d = create_driver %[
        host clienthost
      ]
    end
  end

  def test_configure003
    assert_raise Fluent::ConfigError do
      d = create_driver %[
        zabbix_server  127.0.0.1
        host clienthost
      ]
    end
  end

  def test_configure004
    d = create_driver %[
        zabbix_server  127.0.0.1
        port 490478390,
        host clienthost
        map_key3 x1 y1
    ]

    assert_equal("127.0.0.1", d.instance.zabbix_server)
    assert_equal(490478390, d.instance.port)
    assert_equal("clienthost", d.instance.host)
    assert_equal(20, d.instance.key_size)
    assert_equal(1, d.instance.map_keys.size)
    assert_equal(3, d.instance.map_keys[0][0])
    assert_equal("/x1/", d.instance.map_keys[0][1].inspect)
    assert_equal("y1", d.instance.map_keys[0][2])
    assert_equal(3, d.instance.map_keys[0].id)
    assert_equal("/x1/", d.instance.map_keys[0].pattern.inspect)
    assert_equal("y1", d.instance.map_keys[0].replace)
  end

  def test_map_key
    d = create_driver

    assert_equal("http.statusCount[2xx]",
      d.instance.map_key("input_status2xx_count", /^.+_status(...)_count$/,
        'http.statusCount[\1]'))
    assert_equal("http.statusCount[2xx]",
      d.instance.map_key("input_status2xx_count",
         Regexp.new('^.+_status(...)_count$'),
        'http.statusCount[\1]'))
    assert_nil(
      d.instance.map_key("input_status2xx_rate",
         Regexp.new('^.+_status(...)_count$'),
        'http.statusCount[\1]'))
  end
end
